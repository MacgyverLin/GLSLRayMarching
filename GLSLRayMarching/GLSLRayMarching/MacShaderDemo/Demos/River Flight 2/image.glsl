// "River Flight 2" by dr2 - 2018
// License: Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License

#define AA  0   // optional antialiasing

float PrCylDf (vec3 p, float r, float h);
float PrCapsDf (vec3 p, float r, float h);
float PrConeDf (vec3 p, vec3 b);
float Maxv3 (vec3 p);
float SmoothMin (float a, float b, float r);
float SmoothBump (float lo, float hi, float w, float x);
vec2 Rot2D (vec2 q, float a);
vec2 PixToHex (vec2 p);
vec2 HexToPix (vec2 h);
void HexVorInit ();
vec4 HexVor (vec2 p);
float Hashfv2 (vec2 p);
vec2 Hashv2v2 (vec2 p);
float Noisefv2 (vec2 p);
float Fbm2 (vec2 p);
float Fbm3 (vec3 p);
vec3 VaryNf (vec3 p, vec3 n, float f);
vec4 Loadv4 (vec2 vId);

mat3 flMat;
vec3 flPos, flVd, enPos, qHit, qHitTr, sunDir, trkA, trkF;
float dstFar, tCur, szFac, wSpan, flVel;
int idObj;
const float pi = 3.14159, sqrt3 = 1.73205;

#define DMINQ(id) if (d < dMin) { dMin = d;  idObj = id;  qHit = q; }

float WingDf (vec3 p, float span, float sRad, float trans, float thck, float tapr)
{
  float s, dz;
  s = abs (p.x - trans);
  dz = s / span;
  return max (length (abs (p.yz) + vec2 (sRad + tapr * dz * dz * dz, 0.)) - thck, s - span);
}

float ObjDf (vec3 p)
{
  vec3 q;
  float dMin, fusLen, wSweep, taPos, d, wr, ws, cLen;
  fusLen = (11./13.) * wSpan;
  wSweep = 0.11;
  taPos = (12.5/13.) * wSpan;
  p = flMat * (p - flPos);
  dMin = dstFar / szFac;
  p /= szFac;
  q = p;
  wr = q.z / fusLen;
  d = PrCapsDf (q - fusLen * vec3 (0., 0.045 + 0.08 * wr, 0.),
     0.11 * fusLen, 0.46 * fusLen);
  DMINQ (1);
  d = PrCapsDf (q - fusLen * vec3 (0., 0., -0.32),
     (0.15 - 0.07 * wr * wr) * fusLen, fusLen);
  if (d < dMin + 0.1) {
    dMin = SmoothMin (dMin, d, 0.1);  idObj = 2;  qHit = q;
  }
  ws = wSweep * abs (p.x) / wSpan;
  q = p + vec3 (0., 0.054 * fusLen - 6. * ws, 0.12 * fusLen + 12. * ws);
  d = WingDf (q, wSpan, 13.7, 0., 14., 0.3);
  if (d < dMin + 0.2) {
    dMin = SmoothMin (dMin, d, 0.2);  idObj = 3;  qHit = q;
  }
  q = p + vec3 (0., -0.1 - 6. * ws, taPos + 12. * ws);
  d = WingDf (q, 0.37 * wSpan, 6.8, 0., 7., 0.3);
  DMINQ (4);
  ws = wSweep * abs (p.y) / wSpan;
  q = p.yxz + vec3 (0.5, 0., taPos + 12. * ws);
  d = WingDf (q, 0.16 * wSpan, 6.8, 2.2, 7., 0.3);
  DMINQ (5);
  q = p;
  q.x = abs (q.x);
  cLen = 3.5;
  wr = q.z / cLen;
  d = max (PrCylDf (q - enPos, (0.2  - 0.07 * wr * wr) * cLen, cLen),
     - PrCylDf (q - enPos, 0.04 * cLen, 1.02 * cLen));
  DMINQ (6);
  d = PrConeDf (q - enPos - vec3 (0., 0., 4.2), vec3 (0.8, 0.6, 0.7));
  DMINQ (7);
  return 0.8 * dMin * szFac;
}

float ObjRay (vec3 ro, vec3 rd)
{
  float dHit, d;
  dHit = 0.;
  for (int j = 0; j < 180; j ++) {
    d = ObjDf (ro + dHit * rd);
    dHit += d;
    if (d < 0.0005 || dHit > dstFar) break;
  }
  if (d >= 0.0005) dHit = dstFar;
  return dHit;
}

float TransObjDf (vec3 p)
{
  vec3 q;
  float dMin, d;
  p = flMat * (p - flPos);
  dMin = dstFar / szFac;
  p /= szFac;
  q = p;
  q.x = abs (q.x);
  q -= enPos;
  d = PrCylDf (q - vec3 (0., 0., 3.65), 1.9, 0.05);
  if (d < dMin) {
    dMin = d;
    qHitTr = q;
  }
  return dMin * szFac;
}

float TransObjRay (vec3 ro, vec3 rd)
{
  float dHit, d;
  dHit = 0.;
  for (int j = 0; j < 100; j ++) {
    d = TransObjDf (ro + dHit * rd);
    dHit += d;
    if (d < 0.0005 || dHit > dstFar) break;
  }
  return dHit;
}

vec3 ObjNf (vec3 p)
{
  vec4 v;
  vec2 e = vec2 (0.0001, -0.0001);
  v = vec4 (ObjDf (p + e.xxx), ObjDf (p + e.xyy), ObjDf (p + e.yxy), ObjDf (p + e.yyx));
  return normalize (vec3 (v.x - v.y - v.z - v.w) + 2. * v.yzw);
}

float ObjSShadow (vec3 ro, vec3 rd)
{
  float sh, d, h;
  sh = 1.;
  d = 0.07 * szFac;
  for (int j = 0; j < 24; j ++) {
    h = ObjDf (ro + rd * d);
    sh = min (sh, smoothstep (0., 0.05 * d, h));
    d += 0.07 * szFac;
    if (sh < 0.05) break;
  }
  return 0.3 + 0.7 * sh;
}

vec3 TrackPath (float t)
{
  return vec3 (dot (trkA, sin (trkF * t)), 3.3 + 0.8 * sin (0.05 * t), t);
}

vec3 TrackDir (float t)
{
  return vec3 (dot (trkF * trkA, cos (trkF * t)), 0., 1.);
}

vec3 TrackAcc (float t)
{
  return vec3 (dot (trkF * trkF * trkA, - sin (trkF * t)), 0., 0.);
}

float GrndHt (vec2 p)
{
  mat2 qRot;
  vec2 q;
  float wAmp, h, w;
  w = smoothstep (1.5, 4.5, sqrt (abs (p.x - TrackPath (p.y).x)));
  h = -2.;
  if (w > 0.) {
    q = 0.07 * p;
    qRot = 2.2 * mat2 (0.8, -0.6, 0.6, 0.8);
    h = -0.4;
    wAmp = 15.;
    for (int j = 0; j < 4; j ++) {
      h += wAmp * Noisefv2 (q);
      wAmp *= -0.35;
      q *= qRot;
    }
  }
  h = mix (-2., h, w);
  return h;
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
    if (h < 0. || s > dstFar) break;
    sLo = s;
    s += max (0.01 * s, 0.4 * h);
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

vec3 GrndNf (vec3 p, float d)
{
  vec2 e = vec2 (max (0.01, 0.00001 * d * d), 0.);
  return normalize (vec3 (GrndHt (p.xz) - vec2 (GrndHt (p.xz + e.xy),
     GrndHt (p.xz + e.yx)), e.x).xzy);
}

vec3 FlyerCol (vec3 vn)
{
  vec3 col;
  vec2 ws;
  vec3 bCol = vec3 (0.9, 0.9, 1.), wCol = vec3 (0.9, 0.7, 0.1), uCol = vec3 (0.9, 0.4, 0.4);
  float cLine, s1, s2;
  cLine = 1.;
  if (idObj >= 3 && idObj <= 5) {
    if (idObj == 3) {
      s1 = 1.8;  s2 = 6.;
    } else if (idObj == 4) {
      s1 = 1.1;  s2 = 1.1;
    } else if (idObj == 5) {
      s1 = 1.1;  s2 = 1.2;
    }
    if (abs (qHit.x) > s2 - 0.03) cLine = 1. - 0.5 * SmoothBump (- 0.08, 0.08, 0.02, qHit.z + s1);
    if (qHit.z < - s1) cLine = 1. - 0.5 * SmoothBump (- 0.05, 0.05, 0.02, abs (qHit.x) - s2);
  }
  if (idObj == 1 || idObj == 2) {
    col = mix (uCol, bCol, 1. - smoothstep (-0.6, 0., vn.y));
    if (idObj == 2 && vn.y < 0.) col = mix (bCol, wCol, SmoothBump (0., 3., 0.1, qHit.z + 1.45));         
  } else if (idObj == 3 || idObj == 4) col = mix (bCol, wCol, SmoothBump (0., 3., 0.1, qHit.z));
  else if (idObj == 5) col = mix (bCol, wCol, SmoothBump (0., 2., 0.1, qHit.z));
  else if (idObj == 6) col = bCol;
  else if (idObj == 7) col = wCol;
  if (idObj == 1) {
    if (qHit.z > 4.5 && abs (qHit.x) > 0.07) idObj = 8;
  } else if (idObj == 2) {
    if (qHit.z > -9. && qHit.z < 3.) {
      ws = vec2 (qHit.y - 0.6, mod (1.5 - qHit.z, 1.5) - 0.75);
      if (dot (ws, ws) < 0.1) idObj = 8;
    }
  }
  if (idObj == 8) col = vec3 (0.2);
  return col * cLine;
}

vec3 SkyBg (vec3 rd)
{
  return mix (vec3 (0.2, 0.2, 0.9), vec3 (0.45, 0.45, 0.6), 1. - max (rd.y, 0.));
}

vec3 SkyCol (vec3 ro, vec3 rd)
{
  vec3 p, q, rdd;
  float fCloud, cloudLo, cloudRngI, atFac, clSum, attSum, att, a, sd;
  const float nLay = 30.;
  cloudLo = 300.;
  cloudRngI = 0.005;
  atFac = 0.04;
  fCloud = 0.5;
  rd.y = max (rd.y, 0.001);
  ro.xz += 15. * tCur;
  p = vec3 (ro.xz + (cloudLo - ro.y) * rd.xz / rd.y, cloudLo).xzy;
  rdd = rd / (cloudRngI * rd.y * (2. - rd.y) * nLay);
  clSum = 0.;
  attSum = 0.;
  att = 0.;
  for (float j = 0.; j < nLay; j ++) {
    q = p + j * rdd;
    att += atFac * max (fCloud - Fbm3 (0.005 * q), 0.);
    a = (1. - attSum) * att;
    clSum += a * (q.y - cloudLo) * cloudRngI;
    attSum += a;
    if (attSum >= 1.) break;
  }
  sd = max (dot (rd, sunDir), 0.);
  clSum = 2.5 * (clSum + 0.5 * (1. - attSum) * pow (sd, 4.)) + 0.3;
  return mix (clamp (mix (SkyBg (rd) + step (0.1, sd) * vec3 (1., 1., 0.9) * min (0.8 * pow (sd, 64.) +
     pow (sd, 2048.), 1.), vec3 (0.9, 0.9, 0.95) * clSum, attSum), 0., 1.), SkyBg (rd), pow (1. - rd.y, 16.));
}

vec3 GlareCol (vec3 rd, vec3 sd, vec2 uv)
{
  vec2 e = vec2 (1., 0.);
  return (sd.z > 0.) ? 0.05 * pow (abs (sd.z), 4.) *
     (2. * e.xyy * max (dot (normalize (rd + vec3 (0., 0.3, 0.)), sunDir), 0.) +
     e.xxy * SmoothBump (0.03, 0.05, 0.01, length (uv - 0.7 * sd.xy)) +
     e.yxx * SmoothBump (0.2, 0.23, 0.02, length (uv - 0.5 * sd.xy)) +
     e.xyx * SmoothBump (0.6, 0.65, 0.03, length (uv - 0.3 * sd.xy))) : vec3 (0.);
}

vec3 ShowScene (vec3 ro, vec3 rd)
{
  vec4 vc;
  vec3 col, colR, colG, vn, vnn;
  float dstGrnd, dstObj, dstTrObj, dstWat, sh, spec, dFac, f;
  bool isRefl;
  wSpan = 13.;
  enPos = vec3 (0.3 * wSpan, -0.2, -1.5);
  HexVorInit ();
  dstGrnd = GrndRay (ro, rd);
  dstObj = ObjRay (ro, rd);
  dstTrObj = TransObjRay (ro, rd);
  if (dstTrObj > min (dstGrnd, dstObj)) dstTrObj = dstFar;
  dstWat = (rd.y < 0.) ? - ro.y / rd.y : dstFar;
  isRefl = false;
  if (dstWat < min (dstGrnd, dstObj)) {
    ro += dstWat * rd;
    rd = reflect (rd, VaryNf (0.5 * ro + vec3 (0., 0., 0.2 * tCur), vec3 (0., 1., 0.),
       0.2 - 0.18 * smoothstep (0.1, 0.15, dstWat / dstFar)));
    ro += 0.01 * rd;
    dstGrnd = GrndRay (ro, rd);
    dstObj = ObjRay (ro, rd);
    isRefl = true;
  } else dstWat = 0.;
  if (min (dstGrnd, dstObj) < dstFar) {
    if (dstObj < dstGrnd) {
      ro += dstObj * rd;
      vn = ObjNf (ro);
      vnn = flMat * vn;
      col = FlyerCol (vnn);
      col = mix (col, SkyCol (ro, reflect (rd, vn)), ((idObj == 8) ? 0.7 :
         0.2 * smoothstep (0.1, 0.3, vnn.y)));
      sh = ObjSShadow (ro, sunDir);
      spec = 0.2;
    } else {
      ro += dstGrnd * rd;
      vnn = GrndNf (ro, dstGrnd);
      dFac = (1. - smoothstep (0.3, 0.4, dstGrnd / dstFar)) *
         (1. - smoothstep (-0.2, -0.1, dot (rd, vnn)));
      colR = vec3 (0.);
      colG = vec3 (0.);
      if (vnn.y < 0.8) {
        f = length (ro.xz);
        colR = mix (vec3 (0.4, 0.3, 0.2), vec3 (0.35, 0.3, 0.25),
           mix (0.5, smoothstep (0.2, 0.8, Fbm2 (4. * vec2 (8. * f, ro.y))), dFac));
        colR *= mix (1., 0.95 + 0.05 * Noisefv2 (64. * vec2 (f, ro.y)), dFac);
        vc = HexVor (vec2 (4. * ro.y, 6. * f));
        colR *= mix (vec3 (1.), vec3 (0.8 + 0.2 * vc.w, 1., 1.), dFac);
        colR *= mix (1., 0.95 + 0.05 * smoothstep (0.03 + 0.03 * vc.w,
           0.05 + 0.03 * vc.w, vc.x), dFac);
        vn = VaryNf (vec3 (1., 0.05, 1.) * ro, vnn, 6. * (1. - smoothstep (0.4, 0.8, vnn.y)) * dFac);
      } else {
        vn = VaryNf (ro, vnn, (0.5 + 3.5 * smoothstep (0.8, 0.82, vnn.y)) * dFac *
           (1. - smoothstep (0.8, 1., dstGrnd / 50.)));
      }
      if (vnn.y > 0.77) colG = mix (vec3 (0.2, 0.4, 0.3), vec3 (0.2, 0.5, 0.2),
         mix (0.5, smoothstep (0.1, 0.9, Fbm2 (1. * ro.xz)), dFac));
      col = mix (colR, colG, smoothstep (0.77, 0.8, vnn.y));
      col = mix (vec3 (0.1, 0.4, 0.1), col, 0.5 + 0.5 * smoothstep (0., 0.05, ro.y));
      sh = 1.;
      spec = mix (0.01, 0., smoothstep (0.75, 0.8, vnn.y));
    }
    sh = min (sh, 1. - 0.4 * smoothstep (0.4, 0.7, Fbm2 (0.1 * ro.xz - tCur * vec2 (0.15, 0.))));
    col = col * (0.1 + 0.1 * vec3 (0.8, 0.9, 1.) * (max (dot (vn.xz, - normalize (sunDir.xz)), 0.) +
       max (vn.y, 0.)) + sh * 0.8 * vec3 (1., 1., 0.9) * max (dot (vn, sunDir), 0.)) +
       sh * spec * vec3 (1., 1., 0.9) * pow (max (0., dot (sunDir, reflect (rd, vn))), 64.);
    if (isRefl) col = mix (0.9 * col, vec3 (0.5, 1., 0.5), 0.05);
    col = mix (col, SkyBg (rd), smoothstep (0.4, 1., (dstWat + min (dstGrnd, dstObj)) / dstFar));
  } else {
    col = SkyCol (ro, rd);
    if (isRefl) col = mix (0.9 * col, vec3 (0.5, 1., 0.5), 0.05);
  }
  if (dstTrObj < dstFar) col = 0.7 * col + 0.1 - 0.04 * SmoothBump (1.5, 1.7, 0.02, length (qHitTr.xy));
  return clamp (mix (col, vec3 (col.r), 0.2) * mix (1., smoothstep (0., 1., Maxv3 (col)), 0.2), 0., 1.);
}

void FlyerPM (float s)
{
  vec3 vel, va;
  vec2 cs;
  flPos = TrackPath (s);
  vel = TrackDir (s);
  va = cross (TrackAcc (s), vel) / length (vel);
  flVd = normalize (vel);
  cs = sin (15. * length (va) * sign (va.y) + vec2 (0.5 * pi, 0.));
  flMat = mat3 (cs.x, - cs.y, 0., cs.y, cs.x, 0., 0., 0., 1.) *
     mat3 (flVd.z, 0., flVd.x, 0., 1., 0., - flVd.x, 0., flVd.z);
}

#define N_VU 5

void mainImage (out vec4 fragColor, in vec2 fragCoord)
{
  mat3 vuMat;
  vec4 mPtr, dateCur, stDat;
  vec3 ro, rd, vd, col;
  vec2 mMid[N_VU], ut[N_VU], mSize, canvas, uv, uvv, ori, ca, sa;
  float el, az, asp, zmFac, vuMode, centMode, smMode, nVu, f, tCyc, sunEl, sunAz;
  canvas = iResolution.xy;
  uv = 2. * fragCoord.xy / canvas - 1.;
  uv.x *= canvas.x / canvas.y;
  tCur = iTime;
  dateCur = iDate;
  stDat = Loadv4 (vec2 (0., 0.));
  mPtr.xyz = stDat.xyz;
  vuMode = stDat.w;
  nVu = float (N_VU);
  tCur = mod (tCur, 2400.) + 30. * floor (dateCur.w / 7200.);
  tCyc = 200.;
  centMode = (vuMode >= 0.) ? vuMode : mod (floor (6. * tCur / tCyc), nVu);
  trkA = 8. * vec3 (1.9, 2.9, 4.3);
  trkF = 0.15 * vec3 (0.23, 0.17, 0.13);
  szFac = 0.15;
  asp = canvas.x / canvas.y;
  mSize = vec2 (asp / nVu, 1. / (nVu + 1.));
  for (int k = 0; k < N_VU; k ++) {
    mMid[k] = - vec2 (mSize.x / mSize.y, 1.) + vec2 (2 * (k + 1), 1) * mSize;
    ut[k] = abs (uv - mMid[k]) - mSize;
  }
  smMode = -1.;
  for (int k = 0; k < N_VU; k ++) {
    if (max (ut[k].x, ut[k].y) < 0.) {
      uv = (uv - mMid[k]) / mSize.y;
      smMode = float (k);
      break;
    }
  }
  if (smMode >= 0.) {
    vuMode = smMode;
  } else {
    vuMode = centMode;
    uv.y -= mSize.y;
  }
  flVel = 6.;
  FlyerPM (flVel * tCur);
  az = 0.;
  el = 0.;
  if (smMode == -1. && mPtr.z > 0. && mPtr.y > -0.5 + (1. / (nVu + 1.))) {
    az += 2. * pi * mPtr.x;
    el += 0.5 * pi * mPtr.y;
  }
  if (vuMode == 0. || vuMode == 1.) {
    f = floor (flVel * tCur / (0.5 * tCyc));
    ro = TrackPath ((0.5 * tCyc) * (f + 0.5));
    f = 2. * mod (f, 2.) - 1.;
    ro.xy += (vuMode == 0.) ? vec2 (flVel * f, 1.1 * GrndHt (ro.xz + vec2 (9. * f, 0.))) :
       vec2 (2. * f, 1. - ro.y);
    vd = flPos - ro;
    zmFac = 2. + 0.03 * length (vd);
  } else if (vuMode == 2. || vuMode == 3.) {
    ro = TrackPath (flVel * tCur + sign (vuMode - 2.5) * 30. *
       (1. - 0.8 * abs (sin (pi * mod (flVel * tCur / tCyc, 1.)))));
    vd = flPos - ro;
    zmFac = 2.7;
  } else if (vuMode == 4.) {
    ro = vec3 (vec2 (0., 0.7) + vec2 (0.6, 0.2) * sin (2. * pi * mod (0.05 * tCur, 1.) +
       vec2 (0.5 * pi, 0.)), -4.) * flMat + flPos;
    vd = flVd;
    zmFac = 1.5;
  }
  vd = normalize (vd);
  ori = vec2 (el + asin (vd.y), az + 0.5 * pi - atan (vd.z, vd.x));
  ca = cos (ori);
  sa = sin (ori);
  vuMat = mat3 (ca.y, 0., - sa.y, 0., 1., 0., sa.y, 0., ca.y) *
          mat3 (1., 0., 0., 0., ca.x, - sa.x, 0., sa.x, ca.x);
  sunAz = 0.01 * 2. * pi * tCur;
  sunEl = pi * (0.3 + 0.05 * sin (0.35 * sunAz));
  sunDir = vec3 (0., sin (sunEl), cos (sunEl));
  sunDir.xz = Rot2D (sunDir.xz, sunAz);
  dstFar = 250.;
  #if ! AA
  const float naa = 1.;
#else
  const float naa = 4.;
#endif  
  col = vec3 (0.);
  for (float a = 0.; a < naa; a ++) {
    uvv = uv + step (1.5, naa) * Rot2D (vec2 (0.71 / canvas.y, 0.), 0.5 * pi * (a + 0.5));
    rd = vuMat * normalize (vec3 (uvv, zmFac));
    col += (1. / naa) * (ShowScene (ro, rd) + GlareCol (rd, sunDir * vuMat, uvv));
  }
  col =  pow (clamp (col, 0., 1.), vec3 (0.7));
  for (int k = 0; k < N_VU; k ++) {
    if (max (ut[k].x, ut[k].y) < 0. && min (abs (ut[k].x), abs (ut[k].y)) * canvas.y < 2.)
       col = (float (k) == centMode) ? vec3 (0.8, 0.3, 0.3) : vec3 (0.8, 0.8, 0.5);
  }
  fragColor = vec4 (col, 1.);
}

float PrCylDf (vec3 p, float r, float h)
{
  return max (length (p.xy) - r, abs (p.z) - h);
}

float PrCapsDf (vec3 p, float r, float h)
{
  return length (p - vec3 (0., 0., clamp (p.z, - h, h))) - r;
}

float PrConeDf (vec3 p, vec3 b)
{
  return max (dot (vec2 (length (p.xy), p.z), b.xy), abs (p.z) - b.z);
}

float Maxv3 (vec3 p)
{
  return max (p.x, max (p.y, p.z));
}

float SmoothMin (float a, float b, float r)
{
  float h;
  h = clamp (0.5 + 0.5 * (b - a) / r, 0., 1.);
  return mix (b, a, h) - r * h * (1. - h);
}

float SmoothBump (float lo, float hi, float w, float x)
{
  return (1. - smoothstep (hi - w, hi + w, x)) * smoothstep (lo - w, lo + w, x);
}

vec2 Rot2D (vec2 q, float a)
{
  vec2 cs;
  cs = sin (a + vec2 (0.5 * pi, 0.));
  return vec2 (dot (q, vec2 (cs.x, - cs.y)), dot (q.yx, cs));
}

vec2 PixToHex (vec2 p)
{
  vec3 c, r, dr;
  c.xz = vec2 ((1./sqrt3) * p.x - (1./3.) * p.y, (2./3.) * p.y);
  c.y = - c.x - c.z;
  r = floor (c + 0.5);
  dr = abs (r - c);
  r -= step (dr.yzx, dr) * step (dr.zxy, dr) * dot (r, vec3 (1.));
  return r.xz;
}

vec2 HexToPix (vec2 h)
{
  return vec2 (sqrt3 * (h.x + 0.5 * h.y), (3./2.) * h.y);
}

vec2 gVec[7], hVec[7];

void HexVorInit ()
{
  vec3 e = vec3 (1., 0., -1.);
  gVec[0] = e.yy;
  gVec[1] = e.xy;
  gVec[2] = e.yx;
  gVec[3] = e.xz;
  gVec[4] = e.zy;
  gVec[5] = e.yz;
  gVec[6] = e.zx;
  for (int k = 0; k < 7; k ++) hVec[k] = HexToPix (gVec[k]);
}

vec4 HexVor (vec2 p)
{
  vec4 sd, udm;
  vec2 ip, fp, d, u;
  float amp, a;
  amp = 0.7;
  ip = PixToHex (p);
  fp = p - HexToPix (ip);
  sd = vec4 (4.);
  udm = vec4 (4.);
  for (int k = 0; k < 7; k ++) {
    u = Hashv2v2 (ip + gVec[k]);
    a = 2. * pi * (u.y - 0.5);
    d = hVec[k] + amp * (0.4 + 0.6 * u.x) * vec2 (cos (a), sin (a)) - fp;
    sd.w = dot (d, d);
    if (sd.w < sd.x) {
      sd = sd.wxyw;
      udm = vec4 (d, u);
    } else sd = (sd.w < sd.y) ? sd.xwyw : ((sd.w < sd.z) ? sd.xyww : sd);
  }
  sd.xyz = sqrt (sd.xyz);
  return vec4 (SmoothMin (sd.y, sd.z, 0.3) - sd.x, udm.xy, Hashfv2 (udm.zw));
}

const float cHashM = 43758.54;

float Hashfv2 (vec2 p)
{
  return fract (sin (dot (p, vec2 (37., 39.))) * cHashM);
}

vec2 Hashv2v2 (vec2 p)
{
  vec2 cHashVA2 = vec2 (37., 39.);
  return fract (sin (vec2 (dot (p, cHashVA2), dot (p + vec2 (1., 0.), cHashVA2))) * cHashM);
}

vec4 Hashv4v3 (vec3 p)
{
  vec3 cHashVA3 = vec3 (37., 39., 41.);
  vec2 e = vec2 (1., 0.);
  return fract (sin (vec4 (dot (p + e.yyy, cHashVA3), dot (p + e.xyy, cHashVA3),
     dot (p + e.yxy, cHashVA3), dot (p + e.xxy, cHashVA3))) * cHashM);
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

float Noisefv3 (vec3 p)
{
  vec4 t;
  vec3 ip, fp;
  ip = floor (p);
  fp = fract (p);
  fp *= fp * (3. - 2. * fp);
  t = mix (Hashv4v3 (ip), Hashv4v3 (ip + vec3 (0., 0., 1.)), fp.z);
  return mix (mix (t.x, t.y, fp.x), mix (t.z, t.w, fp.x), fp.y);
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

float Fbm3 (vec3 p)
{
  float f, a;
  f = 0.;
  a = 1.;
  for (int i = 0; i < 5; i ++) {
    f += a * Noisefv3 (p);
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
  if (f > 0.001) {
    g = vec3 (Fbmn (p + e.xyy, n), Fbmn (p + e.yxy, n), Fbmn (p + e.yyx, n)) - Fbmn (p, n);
    n += f * (g - n * dot (n, g));
    n = normalize (n);
  }
  return n;
}

#define txBuf iChannel0
#define txSize iChannelResolution[0].xy

vec4 Loadv4 (vec2 vId)
{
  return texture (txBuf, (vId + 0.5) / txSize);
}
