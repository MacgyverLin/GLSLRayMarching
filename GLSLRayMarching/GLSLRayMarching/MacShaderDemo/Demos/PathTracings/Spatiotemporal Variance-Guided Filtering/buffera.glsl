
const float MOUSE_SENSITIVITY = 0.15; // mouse sensitivity
const uint NUM_SAMPLES = 16u; // number of traced paths per pixel per frame
const uint MAX_BOUNCES = 2u;  // max number of bounces per path

// Ray-sphere intersection.
float intersectRaySphere(vec3 ro, vec3 rd, vec3 sp, float rsq) {
  vec3 n = ro - sp;
  float a = dot(rd, rd);
  float b = 2.0 * dot(rd, n);
  float c = dot(n, n) - rsq;
  float d = b * b - 4.0 * a * c;
  return d < 0.0 ? -1.0 : (-b - sqrt(d)) / 2.0 * a;
}

// Ray-plane intersection.
float intersectRayPlane(vec3 ro, vec3 rd, vec3 n, vec3 p) {
  const float eps = 0.0001;
  float denom = dot(rd, n);
  return abs(denom) < eps ? -1.0 : dot(p - ro, n) / denom;
}

// Ray-triangle intersection.
// https://en.wikipedia.org/wiki/M%C3%B6ller%E2%80%93Trumbore_intersection_algorithm
float intersectRayTri(vec3 ro, vec3 rd, vec3 v0, vec3 v1, vec3 v2) {
  const float eps = 0.0000001;

  vec3 e1 = v1 - v0;
  vec3 e2 = v2 - v0;
  vec3 h = cross(rd, e2);
  float a = dot(e1, h);
  if (a > -eps && a < eps) {
    return -1.0;
  }

  float f = 1.0 / a;
  vec3 s = ro - v0;
  float u = f * dot(s, h);
  if (u < 0.0 || u > 1.0) {
    return -1.0;
  }

  vec3 q = cross(s, e1);
  float v = f * dot(rd, q);
  if (v < 0.0 || u + v > 1.0) {
    return -1.0;
  }

  float t = f * dot(e2, q);
  if (t < eps) {
    return -1.0;
  }

  return t;
}

// Efficient PRNG.
// https://developer.nvidia.com/gpugems/gpugems3/part-vi-gpu-computing/chapter-37-efficient-random-number-generation-and-application

uvec4 rngState;

uint tausStep(uint z, uint S1, uint S2, uint S3, uint M) {
  uint b = ((z << S1) ^ z) >> S2;
  return ((z & M) << S3) ^ b;
}

uint lcgStep(uint z, uint A, uint C) { return A * z + C; }

// Returns a random number [0..1].
float random() {
  const float c = 2.3283064365387e-10;
  rngState.x = tausStep(rngState.x, 13u, 19u, 12u, 4294967294u);
  rngState.y = tausStep(rngState.y, 2u, 25u, 4u, 4294967288u);
  rngState.z = tausStep(rngState.z, 3u, 11u, 17u, 4294967280u);
  rngState.w = lcgStep(rngState.w, 1664525u, 1013904223u);
  return saturate(c * float(rngState.x ^ rngState.y ^ rngState.z ^ rngState.w));
}

float hash(vec2 p) {
  return fract(1e4 * sin(17.0 * p.x + p.y * 0.1) *
               (0.1 + abs(sin(p.y * 13.0 + p.x))));
}

// Seeds the random number generator.
void seedRng(vec4 seed) {
  seed.x = hash(seed.xy);
  seed.y = hash(seed.yz);
  seed.z = hash(seed.zw);
  seed.w = hash(seed.wx);

  rngState = floatBitsToUint(seed);
  rngState ^= (rngState << 13);
  rngState ^= (rngState >> 17);
  rngState ^= (rngState << 5);
}

// Branchless construction of an orthonormal basis.
// https://graphics.pixar.com/library/OrthonormalB/paper.pdf
void orthonormalBasis(const vec3 n, out vec3 b1, out vec3 b2) {
  float s = n.z >= 0.0 ? 1.0 : -1.0;
  float a = -1.0 / (s + n.z);
  float b = n.x * n.y * a;
  b1 = vec3(1.0 + s * n.x * n.x * a, s * b, -s * n.x);
  b2 = vec3(b, s + n.y * n.y * a, -n.y);
}

// Returns a random cosine-weighted unit vector on a hemisphere centered around
// n.
vec3 unitVectorOnHemisphere(vec3 n) {
  float r = random();
  float angle = random() * (2.0 * PI);
  float sr = sqrt(r);
  vec2 p = vec2(sr * cos(angle), sr * sin(angle));
  vec3 ph = vec3(p.xy, sqrt(1.0 - dot(p, p)));

  vec3 b1, b2;
  orthonormalBasis(n, b1, b2);
  return b1 * ph.x + b2 * ph.y + n * ph.z;
}

struct Sphere {
  vec3 position;
  float radius;
  vec4 color; // rgb - albedo, a - emissive
};

struct Tri {
  vec3 v0;
  vec3 v1;
  vec3 v2;
  vec4 color;
};

const vec4 white = vec4(1.0, 1.0, 1.0, 0.0);
const vec4 red = vec4(0.9, 0.15, 0.15, 0.0);
const vec4 green = vec4(0.15, 0.8, 0.05, 0.0);
const vec4 blue = vec4(0.15, 0.3, 0.95, 0.0);
const vec4 pink = vec4(0.95, 0.71, 0.75, 0.0);
const vec4 orange = vec4(0.95, 0.85, 0.05, 0.0);

const Tri[] sceneTris = Tri[](
    Tri(vec3(55.28, 0, 0), vec3(0, 0, 0), vec3(0, 0, 55.92), white),
    Tri(vec3(55.28, 0, 0), vec3(0., 0, 55.92), vec3(54.96, 0, 55.92), white),
    Tri(vec3(54.96, 0, 55.92), vec3(0., 0, 55.92), vec3(0, 54.88, 55.92),
        white),
    Tri(vec3(54.96, 0, 55.92), vec3(0, 54.88, 55.92), vec3(55.60, 54.88, 55.92),
        white),
    Tri(vec3(55.28, 0, 0), vec3(54.96, 0, 55.92), vec3(55.60, 54.88, 55.92),
        red),
    Tri(vec3(55.28, 0, 0), vec3(55.60, 54.88, 55.92), vec3(55.60, 54.88, 0),
        red),
    Tri(vec3(0, 0, 55.92), vec3(0, 0, 0), vec3(0, 54.88, 0), green),
    Tri(vec3(0, 0, 55.92), vec3(0, 54.88, 0), vec3(0, 54.88, 55.92), green),
    Tri(vec3(55.60, 54.88, 0), vec3(55.60, 54.88, 55.92), vec3(0, 54.88, 55.92),
        white),
    Tri(vec3(55.60, 54.88, 0), vec3(0, 54.88, 55.92), vec3(0, 54.88, 0),
        white));

const Sphere[] sceneSpheres =
    Sphere[](Sphere(vec3(42.0, 40.0, 30.5), 7.5, // red ball
                    red),
             Sphere(vec3(5.6, 15.0, 20.0), 5.5, // orange ball
                    orange),
             Sphere(vec3(40.0, 6.0, 35.0), 6.0, // pink ball
                    pink),
             Sphere(vec3(12.0, 32.0, 45.0), 5.5, // green ball
                    green),
             Sphere(vec3(22.0, 8.0, 25.0), 5.5, // blue ball
                    blue),
             Sphere(vec3(35.0, 22.0, 30.0), 8.0, // white ball 1
                    vec4(1.0, 1.0, 1.0, 3.5)),
             Sphere(vec3(15.0, 40.0, 50.0), 4.0, // white ball 2
                    vec4(1.0, 1.0, 1.0, 2.5)));

// Traces a ray (ro, rd) through the scene and returns the hit distance, normal
// and color.
float traceSceneRay(vec3 ro, vec3 rd, out vec3 normal, out vec4 color) {
  const vec3 up = vec3(0.0, 1.0, 0.0);

  float minT = 1e10;
  color = vec4(1.0, 1.0, 1.0, 0.0);

  for (int i = 0; i < sceneSpheres.length(); i++) {
    Sphere sphere = sceneSpheres[i];
    vec3 p = sphere.position;
    float r2 = sphere.radius * sphere.radius;
    float t = intersectRaySphere(ro, rd, p, r2);
    if (t > 0.0 && t < minT) {
      normal = (ro + rd * t) - p;
      color = sphere.color;
      minT = t;
    }
  }

  for (int i = 0; i < sceneTris.length(); i++) {
    Tri tri = sceneTris[i];
    float t = intersectRayTri(ro, rd, tri.v0, tri.v1, tri.v2);
    if (t > 0.0 && t < minT) {
      normal = normalize(cross(tri.v1 - tri.v0, tri.v2 - tri.v0));
      color = tri.color;
      minT = t;
    }
  }

  return minT;
}

// Traces multiple paths for a primary ray and returns the blended result.
GBuffer tracePrimaryRay(vec3 ro, vec3 rd) {
  GBuffer gbuf;

  vec3 normal0;
  vec4 color;
  // get the depth, normal and color for this ray
  float depth = traceSceneRay(ro, rd, normal0, color);
  normal0 = normalize(normal0);

  float emissive = color.a;

  // fill the gbuffer with the material data
  gbuf.albedo = color.rgb;
  gbuf.depth = depth;
  gbuf.normal = normal0;

  // move the ray to the hit point
  ro += rd * depth;
  // slightly displace by the normal to prevent self-intersection
  ro += normal0 * 0.00001;

  vec3 ro0 = ro;

  // radiance sum for this pixel
  float radiance = 0.0;

  // radiance squared sum for this pixel
  // used later on for variance estimation
  float radiance2 = 0.0;

  for (uint q = UZERO; q < NUM_SAMPLES; q++) {
    // get a random direction on the hemisphere around the normal
    ro = ro0;
    rd = unitVectorOnHemisphere(normal0);

    // radiance sum for the current path
    float r = 0.0;

    // keep bouncing and gathering light
    for (uint i = UZERO; i < MAX_BOUNCES; i++) {
      vec3 normal;
      depth = traceSceneRay(ro, rd, normal, color);
      if (depth > 100.0) {
        break;
      }

      // gather whatever we hit
      r += color.a;

      // calculate the ray for the next bounce
      normal = normalize(normal);
      ro += rd * depth;
      ro += normal * 0.00001;
      rd = unitVectorOnHemisphere(normal);
    }

    // add to the total radiance
    radiance += r;
    radiance2 += r * r;
  }

  radiance /= float(NUM_SAMPLES);
  radiance2 /= float(NUM_SAMPLES);

  // variance = sum(x^2) - sum(x)^2
  gbuf.variance = radiance2 - radiance * radiance;
  gbuf.radiance = radiance + emissive;

  return gbuf;
}

#define KEY_A 65
#define KEY_D 68
#define KEY_S 83
#define KEY_W 87
#define KEY_LEFT 37
#define KEY_UP 38
#define KEY_RIGHT 39
#define KEY_DOWN 40

bool isKeyDown(int key) {
  return texelFetch(iChannel1, ivec2(key, 0), 0).x != 0.0;
}

// Updates the camera according to user inputs.
void updateCamera(inout CameraData camera, mat4 cameraMatrix) {
  if (iFrame == 0) {
    camera.position = vec3(27.8, 27.3, -100.0);
    camera.pitchYaw = vec2(0.0, PI);
    camera.prevMouse = iMouse.xy;
  }

  vec3 camFwd = (cameraMatrix * vec4(0.0, 0.0, -1.0, 0.0)).xyz;
  vec3 camRight = (cameraMatrix * vec4(1.0, 0.0, 0.0, 0.0)).xyz;
  float moveSpeed = 16.0 * iTimeDelta;

  if (isKeyDown(KEY_W) || isKeyDown(KEY_UP)) {
    camera.position += camFwd * moveSpeed;
  }
  if (isKeyDown(KEY_S) || isKeyDown(KEY_DOWN)) {
    camera.position -= camFwd * moveSpeed;
  }
  if (isKeyDown(KEY_A) || isKeyDown(KEY_LEFT)) {
    camera.position -= camRight * moveSpeed;
  }
  if (isKeyDown(KEY_D) || isKeyDown(KEY_RIGHT)) {
    camera.position += camRight * moveSpeed;
  }

  vec2 mouseDelta = iMouse.xy - camera.prevMouse;
  mouseDelta = clamp(mouseDelta, -7.0, 7.0);
  mouseDelta.x *= -1.0;
  camera.pitchYaw -= mouseDelta.yx * iTimeDelta * MOUSE_SENSITIVITY;
  camera.pitchYaw.x = clamp(camera.pitchYaw.x, -PI, PI);
  camera.prevMouse = iMouse.xy;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
  // seed the rng
  seedRng(vec4(fragCoord.xy, iFrame, iTime));

  // fetch the camera data
  vec4 cameraDataRaw = texelFetch(iChannel0, ivec2(0, 0), 0);
  CameraData camera = unpackCameraData(cameraDataRaw);
  mat4 cameraMatrix = getInvViewMatrix(camera);

  if (uint(fragCoord.x) == 0u && uint(fragCoord.y) == 0u) {
    // update the camera and store the updated data
    updateCamera(camera, cameraMatrix);
    fragColor = packCameraData(camera);
    return;
  } else if (uint(fragCoord.x) == 1u && uint(fragCoord.y) == 0u) {
    // store previous frame's camera (used later on)
    fragColor = cameraDataRaw;
    return;
  }

  // get the camera ray for this pixel
  vec3 ro = camera.position;
  vec3 rd = rayDirection(55.0, iResolution.xy, fragCoord);
  rd = (cameraMatrix * vec4(rd, 0.0)).xyz;

  // trace the ray
  GBuffer gbuf = tracePrimaryRay(ro, rd);

  // store the result
  fragColor = packGBuffer(gbuf);
}