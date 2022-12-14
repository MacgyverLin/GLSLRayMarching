// "Misty Terraces" by dr2 - 2021
// License: Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License

float SmoothBump (float lo, float hi, float w, float x);
mat3 StdVuMat (float el, float az);
vec2 Rot2D (vec2 q, float a);
float BumpFbm3 (vec3 p);
float Hashfv3 (vec3 p);
vec2 Noisev2v4 (vec4 p);
float Fbm2 (vec2 p);
vec3 VaryNf (vec3 p, vec3 n, float f);

#define VAR_ZERO min (iFrame, 0)

#define AA  0   // (= 0/1) optional antialiasing

mat3 flyerMat[3], flMat;
vec3 flyerPos[3], qHit, flPos, trkA, trkF, sunDir, noiseDisp;
float tCur, dstFar, grhtMax, fogAmp, fogTop;
int idObj;
const float pi = 3.14159;

#define DMINQ(id) if (d < dMin) { dMin = d;  idObj = id;  qHit = q; }

float GrndHtS (vec2 p)
{
  p = vec2 (p.x + p.y, p.x - p.y) / sqrt(2.);
  return grhtMax * Fbm2 (0.1 * p);
}

float GrndHt (vec2 p)
{
  float h, hh, nf, nl;
  p = vec2 (p.x + p.y, p.x - p.y) / sqrt(2.);
  nf = 0.5;
  p = (floor (nf * p) +  smoothstep (0.2, 1., mod (nf * p, 1.))) / nf;
  hh = Fbm2 (0.1 * p);
  nl = 32.;
  h = grhtMax * (floor (nl * hh) + smoothstep (0.4, 0.6, mod (nl * hh, 1.))) / nl + 0.05 * hh;
  return h;
}

float GrndRay (vec3 ro, vec3 rd)
{
  vec3 p;
  float dHit, h, s, sLo, sHi;
  s = 0.;
  sLo = 0.;
  dHit = dstFar;
  for (int j = VAR_ZERO; j < 160; j ++) {
    p = ro + s * rd;
    h = p.y - GrndHt (p.xz);
    if (h < 0.) break;
    sLo = s;
    s += max (0.1, 0.5 * h);
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
  vec2 e;
  e = vec2 (0.01, 0.);
  return normalize (vec3 (GrndHt (p.xz) - vec2 (GrndHt (p.xz + e.xy), GrndHt (p.xz + e.yx)), e.x).xzy);
}

float GrndSShadow (vec3 ro, vec3 rd)
{
  vec3 p;
  float sh, d, h;
  sh = 1.;
  d = 0.05;
  for (int j = VAR_ZERO; j < 30; j ++) {
    p = ro + d * rd;
    h = p.y - GrndHt (p.xz);
    sh = min (sh, smoothstep (0., 0.05 * d, h));
    d += h;
    if (sh < 0.05) break;
  }
  return 0.5 + 0.5 * sh;
}

float ObjDf (vec3 p)
{
  vec3 q, qq;
  float dMin, d, a, szFac;
  szFac = 1.3;
  a = 0.22 * pi;
  dMin = dstFar / szFac;
  for (int k = VAR_ZERO; k < 3; k ++) {
    q = flyerMat[k] * (p - flyerPos[k]) / szFac;
    q.x = abs (q.x);
    q.z += 0.25;
    qq = q;
    qq.xy = Rot2D (vec2 (abs (qq.x), qq.y), - a);
    d = abs (max (max (abs (Rot2D (vec2 (abs (Rot2D (vec2 (qq.x, qq.z - 1.1), -0.012 * pi).x), qq.y), a).y) -
       0.002, 0.), max (dot (q.xz, sin (0.15 * pi + vec2 (0.5 * pi, 0.))) - 0.5, - q.z - 0.5))) - 0.002;
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
  e = vec2 (0.0005, -0.0005);
  for (int j = VAR_ZERO; j < 4; j ++) {
    v[j] = ObjDf (p + ((j < 2) ? ((j == 0) ? e.xxx : e.xyy) : ((j == 2) ? e.yxy : e.yyx)));
  }
  v.x = - v.x;
  return normalize (2. * v.yzw - dot (v, vec4 (1.)));
}

float ObjSShadow (vec3 ro, vec3 rd)
{
  float sh, d, h;
  sh = 1.;
  d = 0.01;
  for (int j = VAR_ZERO; j < 30; j ++) {
    h = ObjDf (ro + d * rd);
    sh = min (sh, smoothstep (0., 0.05 * d, h));
    d += h;
    if (sh < 0.05) break;
  }
  return 0.5 + 0.5 * sh;
}

vec3 SkyBg (vec3 rd)
{
  return mix (vec3 (0.3, 0.4, 0.8), vec3 (0.7, 0.7, 0.8), pow (1. - max (rd.y, 0.), 8.));
}

vec3 SkyCol (vec3 ro, vec3 rd)
{
  vec3 col, skyCol, p, clCol;
  float fd, f, ff;
  if (rd.y > 0.) {
    p = 0.01 * (rd * (100. - ro.y) / max (rd.y, 0.0001) + ro + 4. * tCur);
    ff = Fbm2 (p.xz);
    f = smoothstep (0.2, 0.8, ff);
    fd = smoothstep (0.2, 0.8, Fbm2 (p.xz + 0.01 * sunDir.xz)) - f;
    clCol = (0.7 + 0.5 * ff) * (vec3 (0.8) - 0.7 * vec3 (0.3, 0.3, 0.2) * sign (fd) *
       smoothstep (0., 0.05, abs (fd)));
    fd = smoothstep (0.01, 0.1, rd.y);
    col = mix (mix (vec3 (0.7, 0.7, 0.75), vec3 (0.5, 0.6, 0.9), 0.3 + 0.7 * fd),
       clCol, 0.1 + 0.9 * f * fd) + 0.2 * vec3 (1., 1., 0.9) * pow (max (dot (rd, sunDir), 0.), 2048.);
    col = mix (col, SkyBg (rd), pow (1. - max (rd.y, 0.), 8.));
  } else col = SkyBg (rd);
  return col;
}

float FogHt (vec2 p)
{
  mat2 qRot;
  vec4 t4;
  vec2 q, t, tw;
  float a, h;
  qRot = mat2 (0.8, -0.6, 0.6, 0.8);
  q = p + vec2 (0., 0.05 * tCur);
  a = 1.;
  h = 0.;
  tw = 0.05 * tCur * vec2 (1., -1.);
  for (int j = 0; j < 5; j ++) {
    q *= 2. * qRot;
    t4 = abs (sin (2. * (q.xyxy + tw.xxyy) + 2. * Noisev2v4 (t4).xxyy - 1.));
    t4 = (1. - t4) * (t4 + sqrt (1. - t4 * t4));
    t = 1. - sqrt (t4.xz * t4.yw);
    t *= t;
    h += a * dot (t, t);
    a *= 0.5;
  }
  return fogTop - 0.5 * h;
}

float FogDens (vec3 p)
{
  return fogAmp * (0.2 + 0.8 * smoothstep (0., 1., 1. - p.y / fogTop)) *
     BumpFbm3 (0.03 * (p + noiseDisp)) * smoothstep (0., 1., FogHt (0.1 * p.xz) - p.y);
}

vec3 FogCol (vec3 col, vec3 ro, vec3 rd, float dHit)
{  // updated from "Sailing Home"
  float s, ds, f, fn;
  s = 1.;
  ds = 1.;
  fn = FogDens (ro + s * rd);
  for (int j = VAR_ZERO; j < 40; j ++) {
    s += ds;
    f = fn;
    fn = FogDens (ro + (s + 0.5 * ds * Hashfv3 (16. * rd)) * rd);
    col = mix (col, vec3 (0.9, 0.9, 0.95) * (1. - clamp (f - fn, 0., 1.)),
       min (f * (1. - smoothstep (0.3 * dHit, dHit, s)), 1.));
    if (s > dHit) break;
  }
  return col;
}

vec3 ShowScene (vec3 ro, vec3 rd)
{
  vec4 col4;
  vec3 roo, col, c, vn;
  float dstGrnd, dstObj, sh, df;
  noiseDisp = 0.02 * vec3 (-1., 0., 1.) * tCur + 0.5 * sin (vec3 (0.2, 0.1, 0.3) * pi * tCur);
  fogAmp = 0.2 + 0.8 * SmoothBump (0.25, 0.75, 0.22, mod (0.03 * tCur, 1.));
  fogTop = grhtMax + 3.;
  roo = ro;
  dstGrnd = GrndRay (ro, rd);
  dstObj = ObjRay (ro, rd);
  if (min (dstObj, dstGrnd) < dstFar) {
    if (dstObj < dstGrnd) {
      ro += dstObj * rd;
      c = vec3 (0.3, 0.3, 1.);
      col = (idObj == 1) ? c : ((idObj == 2) ? c.gbr : c.brg);
      col = mix (col, 1. - col, smoothstep (0.02, 0.04, abs (length (vec2 (qHit.xz - vec2 (0.3, -0.1))) - 0.17)) *
        (1. - smoothstep (0.95, 0.97, qHit.z)));
      vn = ObjNf (ro);
      sh = ObjSShadow (ro + 0.01 * vn, sunDir);
    } else if (dstGrnd < dstFar) {
      ro += dstGrnd * rd;
      df = dstGrnd / dstFar;
      vn = GrndNf (ro);
      vn = VaryNf ((1. + 4. * smoothstep (0.8, 0.9, vn.y)) * ro, vn, 1. - smoothstep (0.3, 0.7, df));
      col = mix (vec3 (0.8, 0.7, 0.4) * (1. - 0.15 * (1. - smoothstep (0.3, 0.7, df)) *
         smoothstep (0.4, 0.45, abs (mod (16. * ro.y, 1.) - 0.5))), vec3 (0.4, 1., 0.4), smoothstep (0.8, 0.9, vn.y));
      col *= 0.4 + 0.6 * smoothstep (0.1, 0.9, ro.y / grhtMax);
      col *= 1. - 0.3 * Fbm2 (128. * ro.xz);
      sh = GrndSShadow (ro + 0.01 * vn, sunDir);
    }
    col *= 0.2 + 0.2 * max (dot (vn, normalize (vec3 (- sunDir.xz, 0.).xzy)), 0.) +
       0.8 * sh * max (dot (vn, sunDir), 0.);
    col = mix (col, SkyBg (rd), pow (df, 8.));
  } else {
    col = SkyCol (ro, rd);
  }
  col = FogCol (col, roo, rd, min (dstGrnd, dstObj));
  return clamp (col, 0., 1.);
}

vec3 GlareCol (vec3 rd, vec3 sd, vec2 uv)
{
  vec3 col, e;
  vec2 sa, hax;
  e = vec3 (1., 0., -1.);
  hax = vec2 (0.5 * sqrt (3.), 0.5);
  uv *= 2.;
  col = vec3 (0.);
  if (sd.z > 0.) {
    sa = uv + 0.3 * sd.xy;
    col = 0.1 * pow (sd.z, 8.) * (1.5 * e.xyy * max (dot (normalize (rd + vec3 (0., 0.3, 0.)), sunDir), 0.) +
       e.xxy * (1. - smoothstep (0.11, 0.12, max (abs (sa.y), max (abs (dot (sa, hax)), abs (dot (sa, hax * e.xz)))))) +
       e.xyx * SmoothBump (0.32, 0.4, 0.04, length (uv - 0.7 * sd.xy)) +
       0.8 * e.yxx * SmoothBump (0.72, 0.8, 0.04, length (uv + sd.xy)));
  }
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

void FlyerPM (float t, int isOb)
{
  vec3 vel, va, flVd;
  vec2 cs;
  float oRl;
  flPos = TrkPath (t);
  vel = TrkVel (t);
  va = cross (TrkAcc (t), vel) / length (vel);
  flVd = normalize (vel);
  oRl = ((isOb > 0) ? 5. : 10.) * length (va) * sign (va.y);
  cs = sin (oRl + vec2 (0.5 * pi, 0.));
  flMat = mat3 (cs.x, - cs.y, 0., cs.y, cs.x, 0., 0., 0., 1.) *
     mat3 (flVd.z, 0., flVd.x, 0., 1., 0., - flVd.x, 0., flVd.z);
}

void mainImage (out vec4 fragColor, vec2 fragCoord)
{
  mat3 vuMat;
  vec4 mPtr;
  vec3 ro, rd, col;
  vec2 canvas, uv;
  float el, az, zmFac, flyVel, vDir, hSum, t, sr;
  canvas = iResolution.xy;
  uv = 2. * fragCoord.xy / canvas - 1.;
  uv.x *= canvas.x / canvas.y;
  tCur = iTime;
  mPtr = iMouse;
  mPtr.xy = mPtr.xy / canvas - 0.5;
  az = 0.;
  el = -0.07 * pi;
  if (mPtr.z > 0.) {
    az += 2. * pi * mPtr.x;
    el += pi * mPtr.y;
  }
  el = clamp (el, -0.3 * pi, 0.3 * pi);
  grhtMax = 11.;
  flyVel = 2.;
  trkA = 0.2 * vec3 (1.9, 2.9, 4.3);
  trkF = vec3 (0.23, 0.17, 0.13);
  vDir = sign (0.5 * pi - abs (az));
  for (int k = VAR_ZERO; k < 3; k ++) {
    t = flyVel * tCur + vDir * (8. + 5. * float (k));
    FlyerPM (t, 0);
    flyerMat[k] = flMat;
    flyerPos[k] = flPos;
    flyerPos[k].x += 0.5 * sin (0.1 * pi * t);
    hSum = 0.;
    for (float j = float (VAR_ZERO); j < 7.; j ++) hSum += GrndHtS (TrkPath (t + vDir * (j - 1.)).xz);
    flyerPos[k].y = grhtMax - 2. + hSum / 7.;
  }
  t = flyVel * tCur;
  FlyerPM (t, 1);
  ro = flPos;
  hSum = 0.;
  for (float j = float (VAR_ZERO); j < 7.; j ++) hSum += GrndHtS (TrkPath (t + 1.5 * vDir * (j - 1.)).xz);
  ro.y = grhtMax + hSum / 7.;
  vuMat = StdVuMat (el, az);
  sunDir = normalize (vec3 (0., 1.3, -1.));
  sunDir.xz = Rot2D (sunDir.xz, 0.6 * pi * sin (0.02 * pi * tCur));
  zmFac = 3.;
  dstFar = 120.;
#if ! AA
  const float naa = 1.;
#else
  const float naa = 3.;
#endif  
  col = vec3 (0.);
  sr = 2. * mod (dot (mod (floor (0.5 * (uv + 1.) * canvas), 2.), vec2 (1.)), 2.) - 1.;
  for (float a = 0.; a < naa; a ++) {
    rd = normalize (vec3 (uv + step (1.5, naa) * Rot2D (vec2 (0.5 / canvas.y, 0.),
       sr * (0.667 * a + 0.5) * pi), zmFac));
    rd = (vuMat * rd) * flMat;
    col += (1. / naa) * ShowScene (ro, rd);
  }
  col += GlareCol ((vuMat * normalize (vec3 (uv, zmFac))) * flMat, (flMat * sunDir) * vuMat, uv);
  fragColor = vec4 (col, 1.);
}

float SmoothBump (float lo, float hi, float w, float x)
{
  return (1. - smoothstep (hi - w, hi + w, x)) * smoothstep (lo - w, lo + w, x);
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

float PerBumpf (float p)
{
  return 0.5 * smoothstep (0., 0.5, abs (fract (p) - 0.5));
}

vec3 PerBumpv3 (vec3 p)
{
  return 0.5 * smoothstep (0., 0.5, abs (fract (p) - 0.5));
}

float BumpFbm3 (vec3 p)
{  // from "Energy Temple"
  vec3 q;
  float a, f;
  a = 1.;
  f = 0.;
  q = p;
  for (int j = 0; j < 4; j ++) {
    p += PerBumpv3 (q + PerBumpv3 (q).yzx);
    p *= 1.5;
    f += a * (PerBumpf (p.z + PerBumpf (p.x + PerBumpf (p.y))));
    q = 2. * q + 0.5;
    a *= 0.75;
  }
  return f;
}

const float cHashM = 43758.54;

float Hashfv3 (vec3 p)
{
  return fract (sin (dot (p, vec3 (37., 39., 41.))) * cHashM);
}

vec2 Hashv2v2 (vec2 p)
{
  vec2 cHashVA2 = vec2 (37., 39.);
  return fract (sin (vec2 (dot (p, cHashVA2), dot (p + vec2 (1., 0.), cHashVA2))) * cHashM);
}

vec4 Hashv4f (float p)
{
  return fract (sin (p + vec4 (0., 1., 57., 58.)) * cHashM);
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

vec2 Noisev2v4 (vec4 p)
{
  vec4 ip, fp, t1, t2;
  ip = floor (p);
  fp = fract (p);
  fp = fp * fp * (3. - 2. * fp);
  t1 = Hashv4f (dot (ip.xy, vec2 (1., 57.)));
  t2 = Hashv4f (dot (ip.zw, vec2 (1., 57.)));
  return vec2 (mix (mix (t1.x, t1.y, fp.x), mix (t1.z, t1.w, fp.x), fp.y),
               mix (mix (t2.x, t2.y, fp.z), mix (t2.z, t2.w, fp.z), fp.w));
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
