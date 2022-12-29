// "Snake Run" by dr2 - 2017
// License: Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License

float SmoothMax (float a, float b, float r);
vec2 Rot2D (vec2 q, float a);
mat3 QtToRMat (vec4 q);
vec3 HsvToRgb (vec3 c);
float Noisefv2 (vec2 p);
float Fbm2 (vec2 p);
vec3 VaryNf (vec3 p, vec3 n, float f);
vec4 Loadv4 (int idVar);

const int nChain = 3, lenChain = 50, nBall = nChain * lenChain;
vec3 vnBall, sunDir;
float tCur, dstFar;
int idBall;
const float pi = 3.14159;

float GrndHt (vec2 p)
{
  p *= 0.02;
  return 16. * Fbm2 (p) + 2. * SmoothMax (Fbm2 (8. * Rot2D (p, 0.25 * pi)) - 0.5, 0., 0.1);
}

float GrndRay (vec3 ro, vec3 rd)
{
  vec3 p;
  float dHit, h, s, sLo, sHi;
  s = 0.;
  sLo = 0.;
  dHit = dstFar;
  for (int j = 0; j < 200; j ++) {
    p = ro + s * rd;
    h = p.y - GrndHt (p.xz);
    if (h < 0.) break;
    sLo = s;
    s += max (0.5, 0.5 * h);
    if (s > dstFar) break;
  }
  if (h < 0.) {
    sHi = s;
    for (int j = 0; j < 5; j ++) {
      s = 0.5 * (sLo + sHi);
      p = ro + s * rd;
      if (p.y > GrndHt (p.xz)) sLo = s;
      else sHi = s;
    }
    dHit = 0.5 * (sLo + sHi);
  }
  return dHit;
}

vec3 GrndNf (vec3 p)
{
  const vec2 e = vec2 (0.01, 0.);
  return normalize (vec3 (GrndHt (p.xz) - vec2 (GrndHt (p.xz + e.xy), GrndHt (p.xz + e.yx)), e.x).xzy);
}

float GrndSShadow (vec3 ro, vec3 rd)
{
  vec3 p;
  float sh, d, h;
  sh = 1.;
  d = 0.1;
  for (int j = 0; j < 16; j ++) {
    p = ro + rd * d;
    h = p.y - GrndHt (p.xz);
    sh = min (sh, smoothstep (0., 0.05 * d, h));
    d += max (0.2, 0.1 * d);
    if (sh < 0.05) break;
  }
  return sh;
}

float BallHit (vec3 ro, vec3 rd)
{
  vec4 p;
  vec3 u;
  float b, d, w, dMin, rad;
  dMin = dstFar;
  for (int n = 0; n < nBall; n ++) {
    p = Loadv4 (4 * n);
    u = ro - p.xyz;
    rad = 0.45 * p.w;
    b = dot (rd, u);
    w = b * b - dot (u, u) + rad * rad;
    if (w >= 0.) {
      d = - b - sqrt (w);
      if (d > 0. && d < dMin) {
        dMin = d;
        vnBall = (u + d * rd) / rad;
        idBall = n;
      }
    }
  }
  return dMin;
}

float BallHitSh (vec3 ro, vec3 rd, float rng)
{
  vec4 p;
  vec3 rs, u;
  float b, d, w, dMin, rad;
  dMin = dstFar;
  for (int n = 0; n < nBall; n ++) {
    p = Loadv4 (4 * n);
    u = ro - p.xyz;
    rad = 0.45 * p.w;
    b = dot (rd, u);
    w = b * b - dot (u, u) + rad * rad;
    if (w >= 0.) {
      d = - b - sqrt (w);
      if (d > 0. && d < dMin) dMin = d;
    }
  }
  return smoothstep (0., rng, dMin);
}

float BallChqr (int idBall, vec3 vnBall)
{
  vec3 u;
  vec2 a;
  u = vnBall * QtToRMat (Loadv4 (4 * idBall + 2));
  a = mod (floor (8. * vec2 (atan (u.x, u.y), asin (u.z)) / pi), 2.) - 0.5;
  return 0.5 + 0.5 * step (0., sign (a.x) * sign (a.y));
}

vec3 BgCol (vec3 ro, vec3 rd)
{
  vec3 col;
  rd.y = abs (rd.y);
  ro.xz += 2. * tCur;
  col = vec3 (0.1, 0.2, 0.4) + 0.1 * (1. - max (rd.y, 0.)) +
     0.1 * pow (max (dot (rd, sunDir), 0.), 16.);
  col = mix (col, vec3 (0.8), clamp (0.2 + Fbm2 (0.05 *
     (ro.xz + rd.xz * (100. - ro.y) / max (rd.y, 0.001))) * rd.y, 0., 1.));
  return col;
}

vec3 ShowScene (vec3 ro, vec3 rd)
{
  vec3 col, vn, bgCol;
  float dstBall, dstGrnd, sh, f, c, spec;
  bgCol = BgCol (ro, rd);
  dstBall = BallHit (ro, rd);
  dstGrnd = GrndRay (ro, rd);
  if (min (dstBall, dstGrnd) < dstFar) {
    if (dstBall < dstGrnd) {
      ro += rd * dstBall;
      vn = vnBall;
      c = 0.9 * mod (float (idBall) / float (lenChain), 1.);
      f = float (idBall / lenChain);
      col = HsvToRgb (vec3 (c, 1. - 0.4 * abs (f - 1.), 0.7 + 0.15 * f)) * BallChqr (idBall, vnBall);
      sh = 1.;
      spec = 0.2;
    } else {
      ro += rd * dstGrnd;
      vn = GrndNf (ro);
      f = 1. - clamp (0.5 * pow (vn.y, 4.) + Fbm2 (0.5 * ro.xz) - 0.5, 0., 1.);
      vn = VaryNf (4. * ro, vn, 8. * f * f);
      col = mix (vec3 (0.7, 0.6, 0.2), vec3 (0.4, 0.4, 0.4), f) *
         (1. - 0.2 * Noisefv2 (64. * ro.xz));
      sh = GrndSShadow (ro, sunDir);
      spec = 0.;
    }
    sh = 0.6 + 0.4 * min (sh, BallHitSh (ro + 0.01 * sunDir, sunDir, 30.));
    col = col * (0.2 + 0.8 * sh * max (dot (vn, sunDir), 0.) +
       0.1 * max (- dot (vn.xz, normalize (sunDir.xz)), 0.)) +
       spec * sh * pow (max (dot (normalize (sunDir - rd), vn), 0.), 32.);
    col = mix (col, bgCol, clamp (4. * min (dstBall, dstGrnd) / dstFar - 3., 0., 1.));
  } else col = bgCol;
  return clamp (col, 0., 1.);
}

void mainImage (out vec4 fragColor, in vec2 fragCoord)
{
  mat3 vuMat;
  vec4 mPtr;
  vec3 col, rd, ro, vd, pVu;
  vec2 canvas, uv;
  float az, el;
  canvas = iResolution.xy;
  uv = 2. * fragCoord.xy / canvas - 1.;
  uv.x *= canvas.x / canvas.y;
  tCur = iTime;
  mPtr = iMouse;
  mPtr.xy = mPtr.xy / canvas - 0.5;
  az = -0.03 * pi * tCur;
  el = pi * 0.1 * sin (0.021 * pi * tCur);
  if (mPtr.z > 0.) {
    az += 2. * pi * mPtr.x;
    el += 0.5 * pi * mPtr.y;
  }
  el = clamp (el, 0.02 * pi, 0.4 * pi);
  pVu = Loadv4 (4 * lenChain).xyz;
  ro = pVu + 50. * vec3 (cos (el) * cos (az), sin (el), cos (el) * sin (az));
  ro.y = max (ro.y, GrndHt (ro.xz) + 10.);
  vd = normalize (pVu - ro);
  vuMat = mat3 (vec3 (vd.z, 0., - vd.x) / sqrt (1. - vd.y * vd.y),
     vec3 (- vd.y * vd.x, 1. - vd.y * vd.y, - vd.y * vd.z) / sqrt (1. - vd.y * vd.y), vd);
  rd = vuMat * normalize (vec3 (uv, 3.));
  dstFar = 150.;
  sunDir = normalize (vec3 (1., 2., -1.));
  col = ShowScene (ro, rd);
  fragColor = vec4 (col, 1.);
}

mat3 QtToRMat (vec4 q) 
{
  mat3 m;
  float a1, a2, s;
  q = normalize (q);
  s = q.w * q.w - 0.5;
  m[0][0] = q.x * q.x + s;  m[1][1] = q.y * q.y + s;  m[2][2] = q.z * q.z + s;
  a1 = q.x * q.y;  a2 = q.z * q.w;  m[0][1] = a1 + a2;  m[1][0] = a1 - a2;
  a1 = q.x * q.z;  a2 = q.y * q.w;  m[2][0] = a1 + a2;  m[0][2] = a1 - a2;
  a1 = q.y * q.z;  a2 = q.x * q.w;  m[1][2] = a1 + a2;  m[2][1] = a1 - a2;
  return 2. * m;
}

vec3 HsvToRgb (vec3 c)
{
  vec3 p;
  p = abs (fract (c.xxx + vec3 (1., 2./3., 1./3.)) * 6. - 3.);
  return c.z * mix (vec3 (1.), clamp (p - 1., 0., 1.), c.y);
}

vec2 Rot2D (vec2 q, float a)
{
  return q * cos (a) + q.yx * sin (a) * vec2 (-1., 1.);
}

float SmoothMax (float a, float b, float r)
{
  float h;
  h = clamp (0.5 - 0.5 * (b - a) / r, 0., 1.);
  return r * h * (1. - h) - mix (b, a, h);
}

const float cHashM = 43758.54;

vec2 Hashv2v2 (vec2 p)
{
  vec2 cHashVA2 = vec2 (37., 39.);
  return fract (sin (vec2 (dot (p, cHashVA2), dot (p + vec2 (1., 0.), cHashVA2))) * cHashM);
}

float Noisefv2 (vec2 p)
{
  vec2 t, ip, fp;
  ip = floor (p);  
  fp = fract (p);
  fp = fp * fp * (3. - 2. * fp);
  t = mix (Hashv2v2 (ip), Hashv2v2 (ip + vec2 (0., 1.)), fp.y);
  return mix (t.x, t.y, fp.x);
}

float Fbm2 (vec2 p)
{
  float f, a;
  f = 0.;
  a = 1.;
  for (int i = 0; i < 5; i ++) {
    f += a * Noisefv2 (p);
    a *= 0.5;
    p *= 2.;
  }
  return f * (1. / 1.9375);
}

float Fbmn (vec3 p, vec3 n)
{
  vec3 s;
  float a;
  s = vec3 (0.);
  a = 1.;
  for (int i = 0; i < 3; i ++) {
    s += a * vec3 (Noisefv2 (p.yz), Noisefv2 (p.zx), Noisefv2 (p.xy));
    a *= 0.5;
    p *= 2.;
  }
  return dot (s, abs (n));
}

vec3 VaryNf (vec3 p, vec3 n, float f)
{
  vec3 g;
  vec3 e = vec3 (0.1, 0., 0.);
  g = vec3 (Fbmn (p + e.xyy, n), Fbmn (p + e.yxy, n), Fbmn (p + e.yyx, n)) - Fbmn (p, n);
  return normalize (n + f * (g - n * dot (n, g)));
}

#define txBuf iChannel0
#define txSize iChannelResolution[0].xy

const float txRow = 128.;

vec4 Loadv4 (int idVar)
{
  float fi;
  fi = float (idVar);
  return texture (txBuf, (vec2 (mod (fi, txRow), floor (fi / txRow)) + 0.5) /
     txSize);
}
