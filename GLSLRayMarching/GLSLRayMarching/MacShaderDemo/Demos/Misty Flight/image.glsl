// "Misty Flight" by dr2 - 2020
// License: Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License

float PrRoundBoxDf (vec3 p, vec3 b, float r);
mat3 StdVuMat (float el, float az);
vec2 Rot2D (vec2 q, float a);
vec2 Rot2Cs (vec2 q, vec2 cs);
float Hashfv3 (vec3 p);
float Noisefv2 (vec2 p);
float Fbm2 (vec2 p);
vec3 VaryNf (vec3 p, vec3 n, float f);

#define VAR_ZERO min (iFrame, 0)

mat3 flyerMat[2], flMat;
vec3 qHit, flyerPos[2], flPos, trkA, trkF, sunDir, noiseDisp;
float dstFar, tCur, fogFac;
int idObj;
bool loRes;
const float pi = 3.14159;

#define DMINQ(id) if (d < dMin) { dMin = d;  idObj = id;  qHit = q; }

float GrndHt (vec2 p)
{
  mat2 qRot;
  vec2 q;
  float f, a, s;
  q = 0.1 * p;
  qRot = 2. * mat2 (0.8, -0.6, 0.6, 0.8);
  a = 1.;
  f = 0.;
  s = 0.;
  for (int j = 0; j < 6; j ++) {
    f += a * Noisefv2 (q);
    s += a;
    a *= 0.5;
    q *= qRot;
    if (loRes && j == 3) break;
  }
  return 8. * f / s;
}

float GrndRay (vec3 ro, vec3 rd)
{
  vec3 p;
  float dHit, h, s, sLo, sHi;
  s = 0.;
  sLo = 0.;
  dHit = dstFar;
  for (int j = VAR_ZERO; j < 120; j ++) {
    p = ro + s * rd;
    h = p.y - GrndHt (p.xz);
    if (h < 0.) break;
    sLo = s;
    s += max (0.2, 0.8 * h);
  }
  if (h < 0.) {
    sHi = s;
    for (int j = VAR_ZERO; j < 5; j ++) {
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
  vec2 e = vec2 (0.01, 0.);
  return normalize (vec3 (GrndHt (p.xz) - vec2 (GrndHt (p.xz + e.xy),
     GrndHt (p.xz + e.yx)), e.x).xzy);
}

float ObjDf (vec3 p)
{
  vec3 q;
  float dMin, d, szFac;
  szFac = 0.25;
  dMin = dstFar / szFac;
  for (int k = VAR_ZERO; k < 2; k ++) {
    q = flyerMat[k] * (p - flyerPos[k]) / szFac;
    q.xy = Rot2Cs (vec2 (abs (q.x) + 0.2, q.y), sin (- pi / 6. + vec2 (0.5 * pi, 0.)));
    d = max (PrRoundBoxDf (vec3 (Rot2Cs (q.xz, sin (- pi / 6. + vec2 (0.5 * pi, 0.))),
       q.y).xzy, vec3 (0.8, 0., 1.), 0.015), -0.8 - q.z);
    DMINQ (1 + k);
  }
  return szFac * dMin;
}

float ObjRay (vec3 ro, vec3 rd)
{
  float dHit, d;
  dHit = 0.;
  for (int j = VAR_ZERO; j < 120; j ++) {
    d = ObjDf (ro + dHit * rd);
    dHit += d;
    if (d < 0.001 || dHit > dstFar) break;
  }
  return dHit;
}

vec3 ObjNf (vec3 p)
{
  vec4 v;
  vec2 e;
  e = vec2 (0.001, -0.001);
  for (int j = VAR_ZERO; j < 4; j ++) {
    v[j] = ObjDf (p + ((j < 2) ? ((j == 0) ? e.xxx : e.xyy) : ((j == 2) ? e.yxy : e.yyx)));
  }
  v.x = - v.x;
  return normalize (2. * v.yzw - dot (v, vec4 (1.)));
}

float FrAbsf (float p)
{
  return abs (fract (p) - 0.5);
}

vec3 FrAbsv3 (vec3 p)
{
  return abs (fract (p) - 0.5);
}

float TriNoise3d (vec3 p)
{   // adapted from nimitz's "Oblivion"
  vec3 q;
  float a, f;
  a = 1.;
  f = 0.;
  q = p;
  for (int j = 0; j < 4; j ++) {
    p += FrAbsv3 (q + FrAbsv3 (q).yzx);
    p *= 1.2;
    f += a * (FrAbsf (p.x + FrAbsf (p.y + FrAbsf (p.z))));
    q = 2. * q + 0.2;
    a *= 0.7;
  }
  return f;
}

float FogDens (vec3 p)
{
  return 0.3 * fogFac * TriNoise3d (0.1 * (p + noiseDisp)) * (1. - smoothstep (8., 15., p.y));
}

vec3 FogCol (vec3 col, vec3 ro, vec3 rd, float dHit)
{  // adapted from "Sailing Home"
  float s, ds, f, fn;
  s = 2.;
  ds = 0.5;
  fn = FogDens (ro + s * rd);
  for (int j = VAR_ZERO; j < 20; j ++) {
    s += ds;
    f = fn;
    fn = FogDens (ro + (s + 0.5 * ds * Hashfv3 (16. * rd)) * rd);
    col = mix (col, vec3 (0.9, 0.9, 0.85) * (1. - clamp (f - fn, 0., 1.)),
       min (f * smoothstep (0.9 * s, 2. * s, dHit), 1.));
    if (s > dHit) break;
  }
  return col;
}

vec3 ShowScene (vec3 ro, vec3 rd)
{
  vec3 col, vn, roo, skyCol;
  float dstGrnd, dstObj;
  noiseDisp = 0.02 * tCur * vec3 (-1., 0., 1.) + 0.5 * sin (vec3 (0.2, 0.1, 0.3) * pi * tCur);
  fogFac = 0.2 + 0.8 * smoothstep (0.1, 0.4, 0.5 - abs (mod (0.05 * tCur, 1.) - 0.5));
  roo = ro;
  dstGrnd = GrndRay (ro, rd);
  dstObj = ObjRay (ro, rd);
  skyCol = vec3 (0.5, 0.6, 0.9) - rd.y * 0.2 * vec3 (1., 0.5, 1.) +
     0.2 * vec3 (1., 0.6, 0.1) * pow (clamp (dot (sunDir, rd), 0., 1.), 32.);
  if (min (dstObj, dstGrnd) < dstFar) {
    if (dstObj < dstGrnd) {
      ro += dstObj * rd;
      col = mix (((idObj == 1) ? vec3 (1., 0., 0.) : vec3 (0., 0., 1.)), vec3 (1.),
         step (0.02, abs (abs (qHit.x) - 0.65)));
      col = mix (col, vec3 (1., 1., 0.), step (0.8, qHit.z));
      vn = ObjNf (ro);
      col = col * (0.2 + 0.2 * max (- dot (vn, sunDir), 0.) + 0.8 * max (dot (vn, sunDir), 0.)) +
         0.2 * pow (max (dot (normalize (sunDir - rd), vn), 0.), 32.);
    } else if (dstGrnd < dstFar) {
      ro += dstGrnd * rd;
      vn = GrndNf (ro);
      vn = VaryNf (16. * ro, vn, 1.);
      col = mix (vec3 (0.5, 0.8, 0.4), vec3 (0.6, 0.6, 0.65), smoothstep (2., 6., ro.y)) *
         (0.7 + 0.3 * Fbm2 (2. * ro.xz));
      col *= 0.4 + 0.6 * max (dot (vn, sunDir), 0.);
    }
    col = mix (vec3 (0.5, 0.6, 0.9), col,
       exp (- 2. * clamp (5. * (min (dstGrnd, dstObj) / dstFar - 0.8), 0., 1.)));
  } else col = skyCol;
  col = FogCol (col, roo, rd, min (dstGrnd, dstObj));
  return col;
}

vec3 TrkPath (float t)
{
  return vec3 (dot (trkA, sin (trkF * t)), 0., t);
}

vec3 TrkVel (float t)
{
  return vec3 (dot (trkF * trkA, cos (trkF * t)), 0., 1.);
}

vec3 TrkAcc (float t)
{
  return vec3 (dot (trkF * trkF * trkA, - sin (trkF * t)), 0., 0.);
}

void FlyerPM (float t)
{
  vec3 vel, va, flVd;
  vec2 cs;
  float oRl;
  flPos = TrkPath (t);
  vel = TrkVel (t);
  va = cross (TrkAcc (t), vel) / length (vel);
  flVd = normalize (vel);
  oRl = 2. * length (va) * sign (va.y);
  cs = sin (oRl + vec2 (0.5 * pi, 0.));
  flMat = mat3 (cs.x, - cs.y, 0., cs.y, cs.x, 0., 0., 0., 1.) *
     mat3 (flVd.z, 0., flVd.x, 0., 1., 0., - flVd.x, 0., flVd.z);
}

void mainImage (out vec4 fragColor, in vec2 fragCoord)
{
  mat3 vuMat;
  vec4 mPtr;
  vec3 ro, rd, col;
  vec2 canvas, uv;
  float el, az, zmFac, flyVel, vDir, hSum, t;
  canvas = iResolution.xy;
  uv = 2. * fragCoord.xy / canvas - 1.;
  uv.x *= canvas.x / canvas.y;
  tCur = iTime;
  mPtr = iMouse;
  mPtr.xy = mPtr.xy / canvas - 0.5;
  az = 0.;
  el = -0.05 * pi;
  if (mPtr.z > 0.) {
    az += 2. * pi * mPtr.x;
    el += 0.45 * pi * mPtr.y;
  }
  flyVel = 1.;
  trkA = vec3 (1.9, 2.9, 4.3);
  trkF = vec3 (0.23, 0.17, 0.13);
  vDir = sign (0.5 * pi - abs (az));
  loRes = true;
  for (int k = VAR_ZERO; k < 2; k ++) {
    t = flyVel * tCur + vDir * (2. + 3. * float (k));
    FlyerPM (t);
    flyerMat[k] = flMat;
    flyerPos[k] = flPos;
    hSum = 0.;
    for (float j = 0.; j < 5.; j ++) hSum += GrndHt (TrkPath (t + 0.5 * vDir * (j - 1.)).xz);
    flyerPos[k].y = 6. + hSum / 5.;
  }
  t = flyVel * tCur;
  FlyerPM (t);
  ro = flPos;
  hSum = 0.;
  for (float j = 0.; j < 5.; j ++) hSum += GrndHt (TrkPath (t + 0.5 * (j - 1.)).xz);
  ro.y = 6. + hSum / 5.;
  loRes = false;
  vuMat = StdVuMat (el, az);
  zmFac = 3.;
  dstFar = 100.;
  sunDir = normalize (vec3 (1., 1.5, -1.));
  rd = vuMat * (normalize (vec3 (uv, zmFac)) * flMat);
  col = ShowScene (ro, rd);
  fragColor = vec4 (col, 1.);
}

float PrRoundBoxDf (vec3 p, vec3 b, float r)
{
  return length (max (abs (p) - b, 0.)) - r;
}

mat3 StdVuMat (float el, float az)
{
  vec2 ori, ca, sa;
  ori = vec2 (el, az);
  ca = cos (ori);
  sa = sin (ori);
  return mat3 (ca.y, 0., - sa.y, 0., 1., 0., sa.y, 0., ca.y) *
         mat3 (1., 0., 0., 0., ca.x, - sa.x, 0., sa.x, ca.x);
}

vec2 Rot2D (vec2 q, float a)
{
  vec2 cs;
  cs = sin (a + vec2 (0.5 * pi, 0.));
  return vec2 (dot (q, vec2 (cs.x, - cs.y)), dot (q.yx, cs));
}

vec2 Rot2Cs (vec2 q, vec2 cs)
{
  return vec2 (dot (q, vec2 (cs.x, - cs.y)), dot (q.yx, cs));
}

const float cHashM = 43758.54;

float Hashfv3 (vec3 p)
{
  return fract (sin (dot (p, vec3 (37., 39., 41.))) * cHashM);
}

vec2 Hashv2v2 (vec2 p)
{
  vec2 cHashVA2 = vec2 (37., 39.);
  return fract (sin (dot (p, cHashVA2) + vec2 (0., cHashVA2.x)) * cHashM);
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
  for (int j = 0; j < 5; j ++) {
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
  for (int j = 0; j < 5; j ++) {
    s += a * vec3 (Noisefv2 (p.yz), Noisefv2 (p.zx), Noisefv2 (p.xy));
    a *= 0.5;
    p *= 2.;
  }
  return dot (s, abs (n));
}

vec3 VaryNf (vec3 p, vec3 n, float f)
{
  vec3 g;
  vec2 e = vec2 (0.1, 0.);
  g = vec3 (Fbmn (p + e.xyy, n), Fbmn (p + e.yxy, n), Fbmn (p + e.yyx, n)) - Fbmn (p, n);
  return normalize (n + f * (g - n * dot (n, g)));
}
