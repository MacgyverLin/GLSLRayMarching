// hack to prevent loop unrolling
#define UZERO uint(min(0, iFrame))

#ifndef saturate
#define saturate(X) clamp(X, 0.0, 1.0)
#endif

#define PI 3.14159265359

// [0..1] float to byte
uint f2b(float value) { return uint(saturate(value) * 255.0) & 0xFFu; }
// byte to [0..1] float
float b2f(uint value) { return float(value & 0xFFu) * (1.0 / 255.0); }

// 128-bit gbuffer
//
// albedo r (8), albedo g (8), albedo b (8), unused (8)
// normal x (8), normal y (8), normal z (8), age (8)
// depth (16), variance (16)
// radiance (32)
//
struct GBuffer {
  vec3 albedo;
  float radiance;
  vec3 normal;
  float depth;
  float variance;
  float age;
};

// Pack the GBuffer struct into a vec4.
vec4 packGBuffer(GBuffer gbuf) {
  uvec4 p;
  p.x = f2b(gbuf.albedo.r) | f2b(gbuf.albedo.g) << 8 | f2b(gbuf.albedo.b) << 16;
  vec3 normal = (gbuf.normal + 1.0) * 0.5;
  p.y = f2b(normal.x) | f2b(normal.y) << 8 | f2b(normal.z) << 16 |
        f2b(gbuf.age) << 24;
  p.z = packHalf2x16(vec2(gbuf.depth, gbuf.variance));
  p.w = floatBitsToUint(gbuf.radiance);
  return uintBitsToFloat(p);
}

// Unpack the GBuffer struct from a vec4.
GBuffer unpackGBuffer(vec4 packed1) {
  uvec4 p = floatBitsToUint(packed1);

  GBuffer gbuf;
  gbuf.albedo.r = b2f(p.x);
  gbuf.albedo.g = b2f(p.x >> 8);
  gbuf.albedo.b = b2f(p.x >> 16);
  gbuf.normal.x = b2f(p.y);
  gbuf.normal.y = b2f(p.y >> 8);
  gbuf.normal.z = b2f(p.y >> 16);
  gbuf.normal = normalize(gbuf.normal * 2.0 - 1.0);
  gbuf.age = b2f(p.y >> 24);
  vec2 tmp = unpackHalf2x16(p.z);
  gbuf.depth = tmp.x;
  gbuf.variance = tmp.y;
  gbuf.radiance = uintBitsToFloat(p.w);
  return gbuf;
}

// Sample a gbuffer texture.
GBuffer sampleGBuffer(sampler2D tex, ivec2 uv) {
  return unpackGBuffer(texelFetch(tex, uv, 0));
}

// Creates a 4x4 rotation matrix given an axis and and an angle.
mat4 rotationMatrix(vec3 axis, float angle) {
  axis = normalize(axis);
  float s = sin(angle);
  float c = cos(angle);
  float oc = 1.0 - c;

  return mat4(
      oc * axis.x * axis.x + c, oc * axis.x * axis.y - axis.z * s,
      oc * axis.z * axis.x + axis.y * s, 0.0, oc * axis.x * axis.y + axis.z * s,
      oc * axis.y * axis.y + c, oc * axis.y * axis.z - axis.x * s, 0.0,
      oc * axis.z * axis.x - axis.y * s, oc * axis.y * axis.z + axis.x * s,
      oc * axis.z * axis.z + c, 0.0, 0.0, 0.0, 0.0, 1.0);
}

// Camera parameters.
struct CameraData {
  vec3 position;
  vec2 pitchYaw;
  vec2 prevMouse;
};

// Pack the CameraData struct into a vec4.
vec4 packCameraData(CameraData camera) {
  uvec4 packed1;
  packed1.x = packHalf2x16(camera.position.xy);
  packed1.y = packHalf2x16(vec2(camera.position.z));
  packed1.z = packHalf2x16(camera.pitchYaw);
  packed1.w = packHalf2x16(camera.prevMouse);
  return uintBitsToFloat(packed1);
}

// Unpack the CameraData struct from a vec4.
CameraData unpackCameraData(vec4 packed1) {
  uvec4 p = floatBitsToUint(packed1);

  CameraData camera;
  camera.position.xy = unpackHalf2x16(p.x);
  camera.position.z = unpackHalf2x16(p.y).x;
  camera.pitchYaw = unpackHalf2x16(p.z);
  camera.prevMouse = unpackHalf2x16(p.w);
  return camera;
}

// Returns the inverse view matrix for a camera.
mat4 getInvViewMatrix(CameraData camera) {
  mat4 pitch = rotationMatrix(vec3(1.0, 0.0, 0.0), camera.pitchYaw.x);
  mat4 yaw = rotationMatrix(vec3(0.0, 1.0, 0.0), camera.pitchYaw.y);
  mat4 translate = mat4(1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0,
                        0.0, camera.position, 1.0);

  return yaw * pitch * translate;
}

// Returns the view matrix for a camera.
mat4 getViewMatrix(CameraData camera) {
  mat4 pitch = rotationMatrix(vec3(1.0, 0.0, 0.0), -camera.pitchYaw.x);
  mat4 yaw = rotationMatrix(vec3(0.0, 1.0, 0.0), -camera.pitchYaw.y);
  mat4 translate = mat4(1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0,
                        0.0, -camera.position, 1.0);

  return pitch * yaw * translate;
}

// Returns a perspective projection matrix.
mat4 getProjMatrix(float fov, vec2 size, float near, float far) {
  float fn = far + near;
  float f_n = far - near;
  float r = size.x / size.y;
  float t = -1.0 / tan(radians(fov) * 0.5);

  return mat4(t / r, 0.0, 0.0, 0.0, 0.0, t, 0.0, 0.0, 0.0, 0.0, fn / f_n, 1.0,
              0.0, 0.0, (2.0 * far * near) / f_n, 0.0);
}

// Calculates the ray direction in view space for a pixel given the camera's
// field of view and the screen size in pixels.
vec3 rayDirection(float fov, vec2 size, vec2 fragCoord) {
  vec2 xy = fragCoord - size * 0.5;
  float z = size.y / tan(radians(fov) * 0.5);
  return normalize(vec3(xy, -z));
}

// Projects a world-space position to screen-space given camera view and
// projection matrices.
vec3 project2Screen(const mat4 view, const mat4 proj, vec3 v) {
  vec4 p = proj * (view * vec4(v, 1.0));
  p /= p.w;
  p.xy += 0.5;
  p.z *= 2.0;
  p.z -= 1.0;
  return p.xyz;
}

// Normal-weighting function (4.4.1)
float normalWeight(vec3 normal0, vec3 normal1) {
  const float exponent = 64.0;
  return pow(max(0.0, dot(normal0, normal1)), exponent);
}

// Depth-weighting function (4.4.2)
float depthWeight(float depth0, float depth1, vec2 grad, vec2 offset) {
  // paper uses eps = 0.005 for a normalized depth buffer
  // ours is not but 0.1 seems to work fine
  const float eps = 0.1;
  return exp((-abs(depth0 - depth1)) / (abs(dot(grad, offset)) + eps));
}

// Luminance-weighting function (4.4.3)
float luminanceWeight(float lum0, float lum1, float variance) {
  const float strictness = 4.0;
  const float eps = 0.01;
  return exp((-abs(lum0 - lum1)) / (strictness * variance + eps));
}

// 3x3 kernel from "Progressive Spatiotemporal Variance-Guided Filtering"
// different kernels could potentially give better results
const float psvgfKernel[] =
    float[](0.0625, 0.125, 0.0625, 0.125, 0.25, 0.125, 0.0625, 0.125, 0.0625);

float psvgfWeight(GBuffer g, GBuffer s, vec2 dgrad, ivec2 offset,
                  int stepSize) {
  // calculate the normal, depth and luminance weights
  float nw = normalWeight(g.normal, s.normal);
  float dw = depthWeight(g.depth, s.depth, dgrad, vec2(offset));
  float lw = luminanceWeight(g.radiance, s.radiance, g.variance);

  // combine them with the kernel value
  return saturate(nw * dw * lw) *
         psvgfKernel[(offset.x / stepSize + 1) + (offset.y / stepSize + 1) * 3];
}

// The next function implements the filtering method described in the two papers
// linked below.
//
// "Progressive Spatiotemporal Variance-Guided Filtering"
// https://pdfs.semanticscholar.org/a81a/4eed7f303f7e7f3ca1914ccab66351ce662b.pdf
//
// "Edge-Avoiding À-Trous Wavelet Transform for fast Global Illumination
// Filtering" https://jo.dreggn.org/home/2010_atrous.pdf
//
GBuffer psvgf(sampler2D buf, ivec2 uv, int stepSize) {
  GBuffer g = sampleGBuffer(buf, uv);

  // depth-gradient estimation from screen-space derivatives
  vec2 dgrad = vec2(dFdx(g.depth), dFdy(g.depth));

  ivec3 d = ivec3(-1, 0, 1) * stepSize;

  vec4 s00 = texelFetch(buf, uv + d.xx, 0);
  vec4 s01 = texelFetch(buf, uv + d.xy, 0);
  vec4 s02 = texelFetch(buf, uv + d.xz, 0);
  vec4 s10 = texelFetch(buf, uv + d.yx, 0);
  vec4 s12 = texelFetch(buf, uv + d.yz, 0);
  vec4 s20 = texelFetch(buf, uv + d.zx, 0);
  vec4 s21 = texelFetch(buf, uv + d.zy, 0);
  vec4 s22 = texelFetch(buf, uv + d.zz, 0);

  // blur the variance
  float variance = 0.0;
  variance += unpackHalf2x16(floatBitsToUint(s00.z)).y * psvgfKernel[0];
  variance += unpackHalf2x16(floatBitsToUint(s01.z)).y * psvgfKernel[1];
  variance += unpackHalf2x16(floatBitsToUint(s02.z)).y * psvgfKernel[2];
  variance += unpackHalf2x16(floatBitsToUint(s10.z)).y * psvgfKernel[3];
  variance += g.variance * psvgfKernel[4];
  variance += unpackHalf2x16(floatBitsToUint(s12.z)).y * psvgfKernel[5];
  variance += unpackHalf2x16(floatBitsToUint(s20.z)).y * psvgfKernel[6];
  variance += unpackHalf2x16(floatBitsToUint(s21.z)).y * psvgfKernel[7];
  variance += unpackHalf2x16(floatBitsToUint(s22.z)).y * psvgfKernel[8];
  g.variance = variance;

  // filtered radiance
  float radiance = 0.0;

  // weights sum
  float wsum = 0.0;

  GBuffer s = unpackGBuffer(s00);
  float w = psvgfWeight(g, s, dgrad, d.xx, stepSize);
  radiance += s.radiance * w;
  wsum += w;

  s = unpackGBuffer(s01);
  w = psvgfWeight(g, s, dgrad, d.xy, stepSize);
  radiance += s.radiance * w;
  wsum += w;

  s = unpackGBuffer(s02);
  w = psvgfWeight(g, s, dgrad, d.xz, stepSize);
  radiance += s.radiance * w;
  wsum += w;

  s = unpackGBuffer(s10);
  w = psvgfWeight(g, s, dgrad, d.yx, stepSize);
  radiance += s.radiance * w;
  wsum += w;

  radiance += g.radiance * psvgfKernel[4];
  wsum += psvgfKernel[4];

  s = unpackGBuffer(s12);
  w = psvgfWeight(g, s, dgrad, d.yz, stepSize);
  radiance += s.radiance * w;
  wsum += w;

  s = unpackGBuffer(s20);
  w = psvgfWeight(g, s, dgrad, d.zx, stepSize);
  radiance += s.radiance * w;
  wsum += w;

  s = unpackGBuffer(s21);
  w = psvgfWeight(g, s, dgrad, d.zy, stepSize);
  radiance += s.radiance * w;
  wsum += w;

  s = unpackGBuffer(s22);
  w = psvgfWeight(g, s, dgrad, d.zz, stepSize);
  radiance += s.radiance * w;
  wsum += w;

  // scale total radiance by the sum of the weights
  g.radiance = radiance / wsum;

  return g;
}