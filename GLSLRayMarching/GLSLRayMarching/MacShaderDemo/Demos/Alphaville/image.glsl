// "Alphaville" by dr2 - 2017
// License: Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License

#define txFnt iChannel0

float Hashff (float p);
float Hashfv2 (vec2 p);
float Noisefv2 (vec2 p);
float Fbm2 (vec2 p);
float IFbm1 (float p);
vec3 VaryNf (vec3 p, vec3 n, float f);
float PrOBoxDf (vec3 p, vec3 b);
float PrCylDf (vec3 p, float r, float h);
float SmoothMin (float a, float b, float r);
float SmoothBump (float lo, float hi, float w, float x);
vec2 Rot2D (vec2 q, float a);
vec3 HsvToRgb (vec3 c);

mat3 vuMat;
vec3 vuPos, qHit, sunDir;
vec2 iqBlk, cTimeV, qnTex;
float dstFar, tCur, qcCar, cDir, flrHt;
int idObj;
const float pi = 3.14159;
const int idBldg = 1, idBldgRf = 2, idRoad = 3, idSWalk = 4, idCarWhl = 5,
   idCarBdy = 6, idTrLight = 7;

float TrLightDf (vec3 p, float dMin)
{
  vec3 q;
  float d;
  q = p;
  q.xz = abs (fract (q.xz) - vec2 (0.5)) - vec2 (0.345);
  q.y -= 0.023;
  d = PrCylDf (q.xzy, 0.002, 0.02);
  if (d < dMin) { dMin = d;  idObj = idTrLight;  qHit = q; }
  return dMin;
}

float FontTexDf (vec2 p, int ic)
{
  vec3 tx;
  float d;
  tx = texture (txFnt, mod ((vec2 (mod (float (ic), 16.),
     15. - floor (float (ic) / 16.)) + p) * (1. / 16.), 1.)).gba - 0.5;
  qnTex = vec2 (tx.r, - tx.g);
  d = tx.b + 1. / 256.;
  return d;
}

float BldgDf (vec3 p, float dMin)
{
  vec3 q;
  vec2 ip;
  float d, df, bHt, bHtFac;
  ip = floor (p.xz);
  bHtFac = 0.01 + 0.99 * SmoothBump (0.15, 0.85, 0.1, 
     mod (0.03 * tCur + 0.2 * length (floor ((ip + 8.) / 16.)), 1.));
  d = p.y;
  if (d < dMin) { dMin = d;  idObj = idRoad;  qHit = p;  iqBlk = ip; }
  q = p;
  q.xz = fract (q.xz) - vec2 (0.5);
  bHt = (0.5 * Hashfv2 (13. * ip) + 0.05) * (1. + 0.15 / flrHt) + 0.1;
  bHt = (floor (bHt * bHtFac / flrHt) + 0.2) * flrHt;
  q.y -= 0.0015;
  d = PrOBoxDf (q, vec3 (0.35, 0.0015, 0.35));
  if (d < dMin) { dMin = d;  idObj = idSWalk;  qHit = p; }
  q.y -= 0.0015;
  q.y -= bHt - 0.2 * flrHt - 0.001;
  int ic = int (Hashfv2 (17. * floor (p.xz)) * 26.);
  if (ic == 16) ++ ic;
  df = FontTexDf (fract (p.xz), 0x41 + ic);
  d = max (df, abs (q.y) - bHt);
  if (d < dMin) {
    dMin = d;
    idObj = (d == df) ? idBldg : idBldgRf;
    qHit = q;
    iqBlk = ip;
  }
  if (bHtFac > 0.1) dMin = TrLightDf (p, dMin);
  return dMin;
}

vec4 CarPos (vec3 p)
{
  vec3 q;
  float vDir, cCar;
  if (cDir == 0. && abs (fract (p.z) - 0.5) > 0.35 ||
     cDir == 1. && abs (fract (p.x) - 0.5) < 0.35) {
    p.xz = vec2 (- p.z, p.x);
    vDir = 0.;
  } else {
    vDir = 1.;
  }
  q = p;
  q.y -= -0.003;
  q.z += 3. * floor (q.x);
  q.x = fract (q.x) - 0.5;
  q.z *= 2. * step (0., q.x) - 1.;
  q.z -= cTimeV.x + ((cDir == vDir) ? vDir + cTimeV.y : 1.);
  cCar = floor (20. * q.z);
  q.z = fract (q.z) - 0.5;
  q.x = abs (q.x) - 0.395 - 0.06 * step (0.7, Hashff (11. * cCar)) -
     0.03 * Hashff (13. * cCar);
  return vec4 (q, cCar);
}

float CarDf (vec3 p, float dMin)
{
  vec4 q4;
  vec3 q;
  float d, bf;
  q4 = CarPos (p);
  q = q4.xyz;
  bf = PrOBoxDf (q + vec3 (0., 0., -0.1), vec3 (0.015, 0.05, 0.2));
  q.z = mod (q.z, 0.05) - 0.025;
  d = SmoothMin (PrOBoxDf (q + vec3 (0., -0.008, 0.), vec3 (0.007, 0.002, 0.015)),
     PrOBoxDf (q + vec3 (0., -0.015, 0.003), vec3 (0.0035, 0.0003, 0.005)), 0.02);
  d = max (d, bf);
  if (d < dMin) { dMin = d;  idObj = idCarBdy;  qHit = q;  qcCar = q4.w; }
  q.xz = abs (q.xz) - vec2 (0.0085, 0.01);
  q.y -= 0.006;
  d = max (PrCylDf (q.yzx, 0.003, 0.0012), bf);
  if (d < dMin) { dMin = d;  idObj = idCarWhl;  qHit = q; }
  return 0.7 * dMin;
}

float ObjDf (vec3 p)
{
  float dMin;
  dMin = dstFar;
  dMin = BldgDf (p, dMin);
  dMin = CarDf (p, dMin);
  return dMin;
}

float ObjRay (vec3 ro, vec3 rd)
{
  vec3 p;
  vec2 srd, dda, h;
  float dHit, d;
  srd = 1. - 2. * step (0., rd.xz);
  dda = - srd / (rd.xz + 0.0001);
  dHit = 0.;
  for (int j = 0; j < 240; j ++) {
    p = ro + dHit * rd;
    h = fract (dda * fract (srd * p.xz));
    d = ObjDf (p);
    dHit += min (d, 0.02 + max (0., min (h.x, h.y)));
    if (d < 0.0002 || dHit > dstFar) break;
  }
  return dHit;
}

vec3 ObjNf (vec3 p)
{
  vec4 v;
  const vec3 e = vec3 (0.0001, -0.0001, 0.);
  v = vec4 (ObjDf (p + e.xxx), ObjDf (p + e.xyy),
     ObjDf (p + e.yxy), ObjDf (p + e.yyx));
  return normalize (vec3 (v.x - v.y - v.z - v.w) + 2. * v.yzw);
}

float ObjSShadow (vec3 ro, vec3 rd)
{
  float sh, d, h;
  sh = 1.;
  d = 0.02;
  for (int j = 0; j < 40; j ++) {
    h = BldgDf (ro + rd * d, dstFar);
    sh = min (sh, smoothstep (0., 1., 20. * h / d));
    d += min (0.05, 3. * h);
    if (h < 0.001) break;
  }
  return max (sh, 0.);
}

vec3 BgCol (vec3 ro, vec3 rd)
{
  vec3 col, skyCol, sunCol, p;
  float ds, fd, att, attSum, d, sd;
  rd.y = (rd.y + 0.1) / 1.1;
  rd = normalize (rd);
  if (rd.y >= 0.) {
    p = rd * (200. - ro.y) / max (rd.y, 0.0001);
    ds = 0.1 * sqrt (length (p));
    p += ro;
    fd = 0.002 / (smoothstep (0., 10., ds) + 0.1);
    p.xz *= fd;
    p.xz += 0.1 * tCur;
    att = Fbm2 (p.xz);
    attSum = att;
    d = fd;
    ds *= fd;
    for (int j = 0; j < 4; j ++) {
      attSum += Fbm2 (p.xz + d * sunDir.xz);
      d += ds;
    }
    attSum *= 0.3;
    att *= 0.3;
    sd = clamp (dot (sunDir, rd), 0., 1.);
    skyCol = mix (vec3 (0.7, 1., 1.), vec3 (1., 0.4, 0.1), 0.25 + 0.75 * sd);
    sunCol = vec3 (1., 0.8, 0.7) * pow (sd, 1024.) +
       vec3 (1., 0.4, 0.2) * pow (sd, 256.);
    col = mix (vec3 (0.5, 0.75, 1.), skyCol, exp (-2. * (3. - sd) *
       max (rd.y - 0.1, 0.))) + 0.3 * sunCol;
    attSum = 1. - smoothstep (1., 9., attSum);
    col = mix (vec3 (0.4, 0., 0.2), mix (col, vec3 (0.3, 0.3, 0.3), att), attSum) +
       vec3 (1., 0.4, 0.) * pow (attSum * att, 3.) * (pow (sd, 10.) + 0.5);
  } else col = vec3 (0.6);
  return col;
}

vec4 ObjCol (vec3 ro, vec3 rd, vec3 vn)
{
  vec3 col;
  vec2 g, b;
  float wFac, f, ff, spec;
  wFac = 1.;
  col = vec3 (0.);
  spec = 0.;
  if (idObj == idBldg || idObj == idBldgRf) {
    col = HsvToRgb (vec3 (0.7 * Hashfv2 (19. * iqBlk), 0.2,
       0.4 + 0.2 * Hashfv2 (21. * iqBlk)));
    if (idObj == idBldg) {
      f = mod (qHit.y / flrHt - 0.2, 1.) - 0.5;
      wFac = 1. - (step (0., f) - 0.5) * step (abs (abs (f) - 0.24), 0.02) -
         0.801 * step (abs (f), 0.22);
      if (wFac < 0.2) {
        f = 1.5 * dot (qHit.xz, normalize (vn.zx));
        wFac = min (0.2 + 0.8 * floor (fract (f / flrHt + 0.25) *
           (1. + Hashfv2 (51. * iqBlk))), 1.);
      }
      col *= wFac;
      if (wFac > 0.5) col *= (0.8 + 0.2 * Noisefv2 (512. * vec2 (qHit.x + qHit.z, qHit.y)));
      spec = 0.3;
    } else {
      g = step (0.05, fract (qHit.xz * 70.));
      col *= mix (0.8, 1., g.x * g.y);
    }
  } else if (idObj == idSWalk) {
    g = step (0.05, fract (qHit.xz * 35.));
    col = vec3 (0.2) * mix (0.7, 1., g.x * g.y);
  } else if (idObj == idTrLight) {
    f = 2. * (atan (qHit.z, qHit.x) / pi + 1.) + 0.5;
    ff = floor (f);
    if (abs (qHit.y - 0.014) < 0.004 && abs (f - ff) > 0.3) {
      col = mix (vec3 (0., 1., 0.), vec3 (1., 0., 0.),
         (mod (ff, 2.) == 0.) ? cDir : 1. - cDir);
      spec = -2.;
    } else {
      col = vec3 (0.4, 0.2, 0.1);
      spec = 0.5;
    }
  } else if (idObj == idCarBdy) {
    col = HsvToRgb (vec3 (Hashff (qcCar * 37.), 0.9,
       0.4 + 0.6 * vec3 (Hashff (qcCar * 47.))));
    f = abs (qHit.z + 0.003);
    wFac = max (max (step (0.001, f - 0.005) * step (0.001, abs (qHit.x) - 0.0055),
       step (f, 0.001)), step (0.0015, abs (qHit.y - 0.0145)));
    col *= wFac;
    spec = 0.5;
    if (abs (qHit.z) > 0.015) {
      g = vec2 (qHit.x, 3. * (qHit.y - 0.008));
      if (qHit.z > 0. && dot (g, g) < 3.6e-5) col *= 0.3;
      g = vec2 (abs (qHit.x) - 0.005, qHit.y - 0.008);
      f = dot (g, g);
      if (qHit.z > 0. && f < 2.2e-6) {
        col = vec3 (1., 1., 0.3);
        spec = -2.;
      } else if (qHit.z < 0. && f < 1.1e-6) {
        col = vec3 (1., 0., 0.);
        spec = -2.;
      }
    }
  } else if (idObj == idCarWhl) {
    if (length (qHit.yz) < 0.0015) {
      col = vec3 (0.7);
      spec = 0.8;
    } else {
      col = vec3 (0.03);
    } 
  } else if (idObj == idRoad) {
    g = abs (fract (qHit.xz) - 0.5);
    if (g.x < g.y) g = g.yx;
    col = mix (vec3 (0.05), vec3 (0.08), step (g.x, 0.355));
    f = ((step (abs (g.x - 0.495), 0.002) + step (abs (g.x - 0.365), 0.002)) +
       step (abs (g.x - 0.44), 0.0015) * step (fract (g.y * 18. + 0.25), 0.7)) *
       step (g.y, 0.29);
    col = mix (col, vec3 (0.5, 0.4, 0.1), f);
    f = step (0.6, fract (g.x * 30. + 0.25)) * step (0.36, g.x) *
       step (abs (g.y - 0.32), 0.02);
    col = mix (col, vec3 (0.6), f);
    b = CarPos (ro).xz;
    g = abs (b + vec2 (0., -0.1)) - vec2 (0.015, 0.2);
    b.y = mod (b.y, 0.05) - 0.025;
    b = abs (b) * vec2 (1.55, 1.);
    if (max (g.x, g.y) < 0. && max (b.x, b.y) < 0.016) col *= 0.6;
  }
  if (wFac < 0.5) {
    rd = reflect (rd, vn);
    g = Rot2D (rd.xz, 5.1 * atan (20. + iqBlk.y, 20. + iqBlk.x));
    f = step (1., 0.5 * ro.y + 3. * rd.y -
       0.1 * floor (5. * IFbm1 (0.4 * atan (g.y, g.x) + pi) + 0.05));
    if (f == 1.) col = 0.8 * BgCol (ro, rd);
    else col = vec3 (0.1, 0.05, 0.);
    spec = -1.;
  }
  return vec4 (col, spec);
}

vec3 ShowScene (vec3 ro, vec3 rd)
{
  vec4 objCol;
  vec3 col, vn;
  float dstHit, sh;
  int idObjT;
  dstHit = ObjRay (ro, rd);
  if (dstHit < dstFar) {
    ro += rd * dstHit;
    idObjT = idObj;
    if (idObj == idBldg) vn = normalize (vec3 (qnTex.x, 0.00001, qnTex.y));
    else vn = ObjNf (ro);
    idObj = idObjT;
    objCol = ObjCol (ro, rd, vn);
    col = objCol.rgb;
    if (objCol.a >= 0.) {
      if (idObj == idRoad) vn = VaryNf (500. * qHit, vn, 2.);
      else if (idObj == idBldg || idObj == idBldgRf)
         vn = VaryNf (500. * qHit, vn, 0.5);
      sh = 0.2 + 0.8 * ObjSShadow (ro, sunDir);
      col = col * (0.2 + 0.1 * max (dot (vn, sunDir * vec3 (-1., 1., -1.)), 0.) +
         0.8 * sh * max (dot (vn, sunDir), 0.) +
         sh * objCol.a * pow (max (0., dot (sunDir, reflect (rd, vn))), 128.));
      col *= vec3 (1., 0.8, 0.6);
    } else if (objCol.a == -1.) {
      if (idObj == idBldg || idObj == idBldgRf) col *= 0.6;
    }
    col = mix (col, BgCol (ro, rd), smoothstep (0.4, 1., dstHit / dstFar));
  } else col = BgCol (ro, rd);
  return pow (clamp (col, 0., 1.), vec3 (0.6));
}

vec3 TrackPath (float t)
{
  vec3 p;
  float pLen, s, cCount;
  pLen = 2.;
  t *= 10.;
  p.y = 0.2 + 1.7 * SmoothBump (0.2, 0.8, 0.1, mod (0.08 * t, 1.));
  s = mod (t, 11.);
  if (s < 7.) p.xz = (s < 4.) ? vec2 (0., s) : vec2 (s - 4., 4.);
  else p.xz = (s < 9.) ? vec2 (3., 11. - s) : vec2 (12. - s, 2.);
  cCount = floor (t / 11.);
  if (mod (cCount, 2.) == 0.) p.x *= -1.;
  else p.x -= 1.;
  p.z += 2. * cCount;
  p.xz *= pLen;
  return p;
}

vec4 FlyPR (float s)
{
  vec3 fpF, fpB, vd;
  float ds;
  ds = 0.02;
  fpF = TrackPath (s + ds);
  fpB = TrackPath (s - ds);
  vd = fpF - fpB;
  return vec4 (0.5 * (fpF + fpB), - (atan (vd.z, vd.x) - 0.5 * pi));
}

void mainImage (out vec4 fragColor, in vec2 fragCoord)
{
  vec4 mPtr, flDat;
  vec3 ro, rd, col;
  vec2 canvas, uv, ori, ca, sa;
  float el, az, cTime;
  canvas = iResolution.xy;
  uv = 2. * fragCoord.xy / canvas - 1.;
  uv.x *= canvas.x / canvas.y;
  tCur = iTime;
  mPtr = iMouse;
  mPtr.xy = mPtr.xy / canvas - 0.5;
  el = -0.02 * pi;
  az = 0.02 * pi;
  if (mPtr.z > 0.) {
    el += clamp (pi * mPtr.y, -0.4 * pi, 0.35 * pi);
    az += clamp (2. * pi * mPtr.x, - pi, pi);
  }
  flDat = FlyPR (0.015 * tCur);
  ro = flDat.xyz;
  ro.xz += 0.01;
  ori = vec2 (el, az + flDat.w);
  dstFar = 50.;
  flrHt = 0.07;
  sunDir = normalize (vec3 (1., 0.5, -1.));
  cTime = 0.15 * mod (tCur, 80.);
  cDir = mod (floor (cTime), 2.);
  cTimeV = vec2 (floor (0.5 * floor (cTime)), mod (cTime, 1.));
  ca = cos (ori);
  sa = sin (ori);
  vuMat = mat3 (ca.y, 0., - sa.y, 0., 1., 0., sa.y, 0., ca.y) *
     mat3 (1., 0., 0., 0., ca.x, - sa.x, 0., sa.x, ca.x);
  rd = vuMat * normalize (vec3 (uv, 2.));
  col = ShowScene (ro, rd);
  if (mPtr.z > 0. && max (abs (uv.x), abs (uv.y)) < 0.05 &&
     min (abs (uv.x), abs (uv.y)) < 0.003) col = mix (col, vec3 (0.1, 1., 0.1), 0.3);
  fragColor = vec4 (col, 1.);
}

const vec4 cHashA4 = vec4 (0., 1., 57., 58.);
const vec3 cHashA3 = vec3 (1., 57., 113.);
const float cHashM = 43758.54;

float Hashff (float p)
{
  return fract (sin (p) * cHashM);
}

float Hashfv2 (vec2 p)
{
  return fract (sin (dot (p, cHashA3.xy)) * cHashM);
}

vec2 Hashv2f (float p)
{
  return fract (sin (p + cHashA4.xy) * cHashM);
}

vec4 Hashv4f (float p)
{
  return fract (sin (p + cHashA4) * cHashM);
}

float Noiseff (float p)
{
  vec2 t;
  float ip, fp;
  ip = floor (p);
  fp = fract (p);
  fp = fp * fp * (3. - 2. * fp);
  t = Hashv2f (ip);
  return mix (t.x, t.y, fp);
}

float Noisefv2 (vec2 p)
{
  vec4 t;
  vec2 ip, fp;
  ip = floor (p);
  fp = fract (p);
  fp = fp * fp * (3. - 2. * fp);
  t = Hashv4f (dot (ip, cHashA3.xy));
  return mix (mix (t.x, t.y, fp.x), mix (t.z, t.w, fp.x), fp.y);
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
  return f;
}

float IFbm1 (float p)
{
  float s, a;
  p *= 5.;
  s = 0.;
  a = 10.;
  for (int j = 0; j < 4; j ++) {
    s += floor (a * Noiseff (p));
    a *= 0.5;
    p *= 2.;
  }
  return 0.1 * s;
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
  float s;
  vec3 e = vec3 (0.1, 0., 0.);
  s = Fbmn (p, n);
  g = vec3 (Fbmn (p + e.xyy, n) - s,
     Fbmn (p + e.yxy, n) - s, Fbmn (p + e.yyx, n) - s);
  return normalize (n + f * (g - n * dot (n, g)));
}

float PrOBoxDf (vec3 p, vec3 b)
{
  return length (max (abs (p) - b, 0.));
}

float PrCylDf (vec3 p, float r, float h)
{
  return max (length (p.xy) - r, abs (p.z) - h);
}

float SmoothMin (float a, float b, float r)
{
  float h = clamp (0.5 + 0.5 * (b - a) / r, 0., 1.);
  return mix (b, a, h) - r * h * (1. - h);
}

float SmoothBump (float lo, float hi, float w, float x)
{
  return (1. - smoothstep (hi - w, hi + w, x)) * smoothstep (lo - w, lo + w, x);
}

vec2 Rot2D (vec2 q, float a)
{
  return q * cos (a) * vec2 (1., 1.) + q.yx * sin (a) * vec2 (-1., 1.);
}

vec3 HsvToRgb (vec3 c)
{
  vec3 p = abs (fract (c.xxx + vec3 (1., 2./3., 1./3.)) * 6. - 3.);
  return c.z * mix (vec3 (1.), clamp (p - 1., 0., 1.), c.y);
}

