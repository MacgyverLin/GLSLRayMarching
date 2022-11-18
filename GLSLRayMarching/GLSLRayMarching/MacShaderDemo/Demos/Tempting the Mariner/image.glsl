// "Tempting the Mariner" by dr2 - 2017
// License: Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License

float PrBoxDf (vec3 p, vec3 b);
float PrBox2Df (vec2 p, vec2 b);
float PrCapsDf (vec3 p, float r, float h);
float PrEVCapsDf (vec3 p, vec4 u, float r);
float PrEECapsDf (vec3 p, vec3 v1, vec3 v2, float r);
float PrCylDf (vec3 p, float r, float h);
float PrSphDf (vec3 p, float r);
float PrFlatCylDf (vec3 p, float rhi, float rlo, float h);
float PrTorusDf (vec3 p, float ri, float rc);
float SmoothMin (float a, float b, float r);
float SmoothBump (float lo, float hi, float w, float x);
vec2 Rot2D (vec2 q, float a);
float Noisefv2 (vec2 p);
float Fbm2 (vec2 p);

mat3 birdMat[2], bdMat;
vec4 vum[4], vur[5];
vec3 vim[4], vir[5];
vec3 birdPos[2], bdPos, fltBox, shipConf, bDeck, qHit, sunDir, cloudDisp;
float tCur, dstFar, szFac, shipRot, birdVel, birdLen, legAng, htWat;
int idObj, idObjGrp;
bool isRefl;
const int idHull = 1, idRud = 2, idStruc = 3, idMast = 4, idSparT = 5, idSparL = 6, idSailT = 7,
   idSailA = 8, idSailF = 9, idFlag = 10, idRig = 11,
   idWing = 21, idBdy = 22, idEye = 23, idBk = 24, idLeg = 25;
const float pi = 3.14159;

float WaveHt (vec2 p)
{
  mat2 qRot = mat2 (0.8, -0.6, 0.6, 0.8);
  vec4 t4, v4;
  vec2 q, t, tw;
  float wFreq, wAmp, h;
  q = 0.5 * p + vec2 (0., tCur);
  h = 0.2 * sin (q.y) + 0.15 * sin (dot (q, vec2 (0.1, 1.2))) +
     0.1 * sin (dot (q, vec2 (-0.2, 1.4)));
  h *= 0.3 * (1. - smoothstep (0.8 * dstFar, dstFar, length (p)));
  q = p;
  wFreq = 0.5;
  wAmp = 0.05;
  tw = 0.5 * tCur * vec2 (1., -1.);
  for (int j = 0; j < 4; j ++) {
    q *= qRot;
    t4 = q.xyxy * wFreq + tw.xxyy;
    t = vec2 (Noisefv2 (t4.xy), Noisefv2 (t4.zw));
    t4 += 2. * t.xxyy - 1.;
    v4 = (1. - abs (sin (t4))) * (abs (sin (t4)) + abs (cos (t4)));
    t = 1. - sqrt (v4.xz * v4.yw);
    t *= t;
    h += wAmp * dot (t, t);
    wFreq *= 2.;
    wAmp *= 0.5;
  }
  return h;
}

vec3 WaveNf (vec2 p, float d)
{
  vec2 e = vec2 (max (0.01, 0.001 * d * d), 0.);
  return normalize (vec3 (WaveHt (p) - vec2 (WaveHt (p + e.xy), WaveHt (p + e.yx)), e.x).xzy);
}

vec3 SkyCol (vec3 ro, vec3 rd)
{
  vec3 col, skyCol, p;
  float ds, fd, att, attSum, d, sd;
  p = ro + rd * (200. - ro.y) / rd.y;
  ds = 0.1 * sqrt (length (ro - p));
  fd = 0.001 / (smoothstep (0., 10., ds) + 0.1);
  p.xz *= fd;
  p.xz -= cloudDisp.xz;
  p *= 3.;
  att = Fbm2 (p.xz);
  attSum = att;
  fd *= 3.;
  d = fd;
  ds *= fd;
  for (int j = 0; j < 4; j ++) {
    attSum += Fbm2 (p.xz + d * sunDir.xz);
    d += ds;
  }
  sd = clamp (dot (sunDir, rd), 0., 1.);
  skyCol = mix (vec3 (0.7, 1., 1.), vec3 (1., 0.4, 0.1), 0.25 + 0.75 * sd);
  col = mix (vec3 (0.5, 0.75, 1.), skyCol, exp (-2. * (3. - sd) * max (rd.y - 0.1, 0.))) +
     0.3 * (vec3 (1., 0.4, 0.2) * pow (sd, 256.) + vec3 (1., 0.8, 0.7) * pow (sd, 1024.));
  attSum = 1. - smoothstep (1., 9., attSum);
  col = mix (vec3 (0.4, 0., 0.2), mix (col, vec3 (0.2),
     att * (0.001 + 0.999 * smoothstep (0.001, 0.004, rd.y))), attSum) +
     vec3 (1., 0.4, 0.) * pow (attSum * att, 4.) * (pow (sd, 8.) + 0.5);
  return col;
}

#define DMINQ(id) if (d < dMin) { dMin = d;  idObj = id;  qHit = q; }

float ShipHullDf (vec3 p, float dMin)
{
  vec3 q;
  float d, fy, fz, gz;
  q = p;
  d = abs (p.z) - 4.5;
  q.z = mod (q.z + 1.4, 2.8) - 1.4;
  q.yz -= vec2 (-3.4, -0.4);
  d = max (d, PrBoxDf (q, vec3 (0.3, 0.1, 0.5)));
  DMINQ (idStruc);
  q = p;
  q.x = abs (q.x);
  q.yz -= vec2 (-3.8, 0.5);
  fz = q.z / 5. + 0.3;
  fz *= fz;
  fy = 1. - smoothstep (-1.3, -0.1, q.y);
  gz = smoothstep (2., 5., q.z);
  bDeck = vec3 ((1. - 0.45 * fz * fz) * (1.1 - 0.5 * fy * fy) *
     (1. - 0.5 * smoothstep (-5., -2., q.y) * smoothstep (2., 5., q.z)),
     0.78 - 0.8 * gz * gz - 0.2 * (1. - smoothstep (-5.2, -4., q.z)), 5. * (1. + 0. * 0.02 * q.y));
  d = min (PrBoxDf (vec3 (q.x, q.y + bDeck.y - 0.6, q.z), bDeck),
     max (PrBoxDf (q - vec3 (0., 0.72, -4.6), vec3 (bDeck.x, 0.12, 0.4)),
     - PrBox2Df (vec2 (abs (q.x) - 0.4, q.y - 0.65), vec2 (0.2, 0.08))));
  d = max (d, - PrBoxDf (vec3 (q.x, q.y - 0.58 - 0.1 * fz, q.z), vec3 (bDeck.x - 0.07, 0.3, bDeck.z - 0.1)));
  q = p;
  d = max (d, - max (PrBox2Df (vec2 (q.y + 3.35, mod (q.z + 0.25, 0.5) - 0.25), vec2 (0.08, 0.1)),
     abs (q.z + 0.5) - 3.75));
  DMINQ (idHull);
  q = p;
  d = PrBoxDf (q + vec3 (0., 4.4, 4.05), vec3 (0.03, 0.35, 0.5));
  DMINQ (idRud);
  return dMin;
}

float ShipMastDf (vec3 p, float dMin)
{
  vec3 q, qq;
  float d, fy, fz, s, rSpar, yLim, zLim;
  rSpar = 0.05;
  fy = 1. - 0.07 * p.y;
  fz = 1. - 0.14 * step (1., abs (p.z));
  zLim = abs (p.z) - 4.5;
  q = p;
  d = zLim;
  q.z = mod (q.z + 1.4, 2.8) - 1.2;
  d = max (d, PrCapsDf ((q - vec3 (0., 3.7 * (fz - 1.), 0.)).xzy, 0.1 * fy, 3.7 * fz));
  DMINQ (idMast);
  q = p;
  yLim = abs (q.y - 0.2 * fz) - 3. * fz;
  qq = q;
  qq.y = mod (qq.y - 3.3 * (fz - 1.), 2. * fz) - fz;
  qq.z = mod (qq.z + 1.4, 2.8) - 1.4 + 0.1 * fz;
  d = max (max (min (d, PrCylDf (vec3 (qq - vec3 (0., 0.05 * fy * fz, 0.1 * fz - 0.23)).xzy,
     0.15 * fy, 0.11 * fy * fz)), yLim), zLim);
  DMINQ (idMast);
  d = max (max (PrCapsDf (qq.yzx, 0.05, 1.23 * fy * fz), yLim), zLim);
  DMINQ (idSparT);
  q = p;
  d = min (d, min (PrEVCapsDf (q - vim[0], vum[0], rSpar), PrEVCapsDf (q - vim[1], vum[1], rSpar)));
  d = min (d, min (PrEVCapsDf (q - vim[2], vum[2], rSpar), PrEVCapsDf (q - vim[3], vum[3], rSpar)));
  DMINQ (idSparL);
  return dMin;
}

float ShipSailDf (vec3 p, float dMin)
{
  vec3 q, qq, w;
  float d, fy, fz;
  fy = 1. - 0.07 * p.y;
  fz = 1. - 0.14 * step (1., abs (p.z));
  q = p;
  qq = q;
  qq.y = mod (qq.y - 3.1 * (fz - 1.), 2. * fz) - fz;
  qq.z = mod (qq.z + 1.4, 2.8) - 1.4 + 0.2 * (fz - abs (qq.y)) * (fz - abs (qq.y)) - 0.1 * fz;
  d = max (max (max (PrBoxDf (qq, vec3 ((1.2 - 0.07 * q.y) * fz, fz, 0.01)),
     min (qq.y, 1.5 * fy * fz - length (vec2 (qq.x, qq.y + 0.9 * fy * fz)))),
     abs (q.y - 3. * (fz - 1.)) - 2.95 * fz), - PrBox2Df (qq.yz, vec2 (0.01 * fz)));
  d = max (d, abs (p.z) - 4.5);
  DMINQ (idSailT);
  q = p;
  q.z -= -3.8;  q.y -= -1.75 - 0.2 * q.z;
  d = PrBoxDf (q, vec3 (0.01, 0.9 - 0.2 * q.z, 0.6));
  DMINQ (idSailA);
  q = p;
  q.yz -= vec2 (-1., 4.5);
  w = vec3 (1., q.yz);
  d = max (max (max (abs (q.x) - 0.01, - dot (w, vec3 (2.3, 1., -0.35))),
     - dot (w, vec3 (0.68, -0.74, -1.))), - dot (w, vec3 (0.41, 0.4, 1.)));
  DMINQ (idSailF);
  q = p;
  q.yz -= vec2 (3.4, 0.18);
  d = PrBoxDf (q, vec3 (0.01, 0.2, 0.3));
  DMINQ (idFlag);
  return dMin;
}

float ShipRigDf (vec3 p, float dMin)
{
  vec3 q;
  float rRig, d, fz, gz, s;
  rRig = 0.02;
  fz = 1. - 0.14 * step (1., abs (p.z));
  q = p;
  d = abs (p.z) - 4.5;
  gz = (q.z - 0.5) / 5. + 0.3;
  gz *= gz;
  gz = 1.05 * (1. - 0.45 * gz * gz);
  q.x = abs (q.x);
  q.z = mod (q.z + 1.4, 2.8) - 1.4;
  d = max (d, min (PrEECapsDf (q, vec3 (1.05 * gz, -3.25, -0.5), vec3 (1.4 * fz, -2.95, -0.05), 0.7 * rRig),
     PrEECapsDf (vec3 (q.xy, abs (q.z + 0.2) - 0.01 * (0.3 - 2. * q.y)), vec3 (gz, -3.2, 0.),
     vec3 (0.05, -0.9 + 2. * (fz - 1.), 0.), rRig)));
  q = p;
  d = min (d, PrEVCapsDf (q - vir[0], vur[0], 0.8 * rRig));
  d = min (min (d, min (PrEVCapsDf (q - vir[1], vur[1], rRig),
     PrEVCapsDf (q - vir[2], vur[2], rRig))), PrEVCapsDf (q - vir[3], vur[3], rRig));
  q.x = abs (q.x);
  d = min (d, PrEVCapsDf (q - vir[4], vur[4], rRig));
  s = step (1.8, q.y) - step (q.y, -0.2);
  d = min (min (d, min (PrEECapsDf (q, vec3 (0.95, 0.4, 2.7) + vec3 (-0.1, 1.7, 0.) * s,
     vec3 (0.05, 1.1, -0.15) + vec3 (0., 2., 0.) * s, rRig),
     PrEECapsDf (q, vec3 (1.05, 1., -0.1) + vec3 (-0.1, 2., 0.) * s,
     vec3 (0.05, 0.5, -2.95) + vec3 (0., 1.7, 0.) * s, rRig))),
     PrEECapsDf (q, vec3 (0.95, 0.4, -2.9) + vec3 (-0.1, 1.7, 0.) * s,
     vec3 (0.05, 0.9, -0.25) + vec3 (0., 2., 0.) * s, rRig));
  DMINQ (idRig);
  return dMin;
}

float BdBodyDf (vec3 p, float dMin)
{
  vec3 q;
  float bkLen, d, a, wr, tr, u;
  bkLen = 0.15 * birdLen;
  q = p;
  wr = q.z / birdLen;
  if (wr > 0.5) {
    u = (wr - 0.5) / 0.5;
    tr = 0.17 - 0.11 * u * u;
  } else {
    u = clamp ((wr - 0.5) / 1.5, -1., 1.);
    u *= u;
    tr = 0.17 - u * (0.34 - 0.18 * u); 
  }
  d = PrCapsDf (q, tr * birdLen, birdLen);
  DMINQ (idObjGrp + idBdy);
  q = p;
  q.x = abs (q.x);
  wr = (wr + 1.) * (wr + 1.);
  q -= birdLen * vec3 (0.3 * wr, 0.1 * wr, -1.2);
  d = PrCylDf (q, 0.009 * birdLen, 0.2 * birdLen);
  DMINQ (idObjGrp + idBdy);
  q = p;
  q.x = abs (q.x);
  q -= birdLen * vec3 (0.08, 0.05, 0.9);
  d = PrSphDf (q, 0.04 * birdLen);
  DMINQ (idObjGrp + idEye);
  q = p;  q -= birdLen * vec3 (0., -0.015, 1.15);
  wr = clamp (0.5 - 0.3 * q.z / bkLen, 0., 1.);
  d = PrFlatCylDf (q, 0.25 * wr * bkLen, 0.25 * wr * bkLen, bkLen);
  DMINQ (idObjGrp + idBk);
  return dMin;
}

float BdWingDf (vec3 p, float dMin)
{
  vec3 q, qh;
  float wngFreq, wSegLen, wChord, wSpar, fTap, tFac, d, dd, a, wr, wf;
  wngFreq = 6.;
  wSegLen = 0.15 * birdLen;
  wChord = 0.3 * birdLen;
  wSpar = 0.03 * birdLen;
  fTap = 8.;
  tFac = (1. - 1. / fTap);
  q = p - vec3 (0., 0., 0.3 * birdLen);
  q.x = abs (q.x) - 0.1 * birdLen;
  wf = 1.;
  a = -0.1 + 0.2 * sin (wngFreq * tCur);
  d = dMin;
  qh = q;
  for (int k = 0; k < 5; k ++) {
    q.xy = Rot2D (q.xy, a);
    q.x -= wSegLen;
    wr = wf * (1. - 0.5 * q.x / (fTap * wSegLen));
    dd = PrFlatCylDf (q.zyx, wr * wChord, wr * wSpar, wSegLen);
    if (k < 4) {
      q.x -= wSegLen;
      dd = min (dd, PrCapsDf (q, wr * wSpar, wr * wChord));
    } else {
      q.x += wSegLen;
      dd = max (dd, PrCylDf (q.xzy, wr * wChord, wSpar));
      dd = min (dd, max (PrTorusDf (q.xzy, 0.98 * wr * wSpar, wr * wChord), - q.x));
    }
    if (dd < d) { d = dd;  qh = q; }
    a *= 1.03;
    wf *= tFac;
  }
  q = qh;
  DMINQ (idObjGrp + idWing);
  return dMin;
}

float BdFootDf (vec3 p, float dMin)
{
  vec3 q;
  float lgLen, ftLen, d;
  lgLen = 0.1 * birdLen;
  ftLen = 0.5 * lgLen;
  q = p;
  q.x = abs (q.x);
  q -= birdLen * vec3 (0.1, -0.12, 0.6);
  q.yz = Rot2D (q.yz, legAng);
  q.xz = Rot2D (q.xz, -0.05 * pi);
  q.z += lgLen;
  d = PrCylDf (q, 0.15 * lgLen, lgLen);
  DMINQ (idObjGrp + idLeg);
  q.z += lgLen;
  q.xy = Rot2D (q.xy, 0.5 * pi);
  q.xy = Rot2D (q.xy, floor (3. * atan (q.y, - q.x) / (2. * pi) + 0.5) * (2. * pi / 3.));
  q.xz = Rot2D (q.xz, - pi + 0.4 * legAng);
  q.z -= ftLen;
  d = PrCapsDf (q, 0.2 * ftLen, ftLen);
  DMINQ (idObjGrp + idLeg);
  return dMin;
}

float ObjDf (vec3 p)
{
  vec3 q;
  float dMin;
  dMin = dstFar;
  q = p;
  q.xz = Rot2D (q.xz, shipRot);
  q.y -= shipConf.x + 6.6 * szFac;
  q /= szFac;
  dMin = dstFar / szFac;
  dMin = ShipHullDf (q, dMin);
  dMin = ShipMastDf (q, dMin);
  dMin = ShipSailDf (q, dMin);
  if (! isRefl) dMin = ShipRigDf (q, dMin);
  dMin *= 0.7 * szFac;
  dMin = max (dMin, - p.y + htWat);
  idObjGrp = 1 * 256;
  q = birdMat[0] * (p - birdPos[0]);
  dMin /= 0.9;
  dMin = BdBodyDf (q, dMin);
  dMin = BdWingDf (q, dMin);
  dMin = BdFootDf (q, dMin);
  idObjGrp = 2 * 256;
  q = birdMat[1] * (p - birdPos[1]);
  dMin = BdBodyDf (q, dMin);
  dMin = BdWingDf (q, dMin);
  dMin = BdFootDf (q, dMin);
  return 0.9 * dMin;
}

float ObjRay (vec3 ro, vec3 rd)
{
  float dHit, d;
  dHit = 0.;
  for (int j = 0; j < 150; j ++) {
    d = ObjDf (ro + rd * dHit);
    dHit += d;
    if (d < 0.0005 || dHit > dstFar) break;
  }
  return dHit;
}

vec3 ObjNf (vec3 p)
{
  vec4 v;
  vec2 e = vec2 (0.0005, -0.0005);
  v = vec4 (ObjDf (p + e.xxx), ObjDf (p + e.xyy), ObjDf (p + e.yxy), ObjDf (p + e.yyx));
  return normalize (vec3 (v.x - v.y - v.z - v.w) + 2. * v.yzw);
}

vec4 ShipCol ()
{
  vec4 col4;
  vec2 cg;
  if (idObj == idHull) {
    if (abs (qHit.x) < bDeck.x - 0.08 && qHit.y > -3.6 && qHit.z > - bDeck.z + 0.62) {
      col4 = vec4 (0.5, 0.3, 0., 0.1) * (0.5 + 0.5 * SmoothBump (0.05, 0.95, 0.02, mod (8. * qHit.x, 1.)));
    } else if (qHit.y > -4.) {
      col4 = vec4 (0.7, 0.5, 0.1, 0.1);
      if (abs (qHit.z - 4.) < 0.25 && abs (qHit.y + 3.55) < 0.05) col4 *= 1.2;
      else if (qHit.z < -4. && abs (qHit.x) < 0.84 && abs (qHit.y + 3.62) < 0.125) {
        cg = step (0.1, abs (fract (vec2 (6. * qHit.x, 8. * (qHit.y + 3.62)) + 0.5) - 0.5));
        if (cg.x * cg.y == 1.) col4 = vec4 (0.8, 0.8, 0.2, -1.);
        else col4 *= 0.8;
      } else {
        col4 *= 0.7 + 0.3 * SmoothBump (0.05, 0.95, 0.02, mod (8. * qHit.y, 1.));
      } 
    } else if (qHit.y > -4.05) {
      col4 = vec4 (0.8, 0.8, 0.8, 0.1);
    } else {
      col4 = vec4 (0.3, 0.2, 0.1, 0.);
    }
  } else if (idObj == idRud) {
    col4 = vec4 (0.5, 0.3, 0., 0.);
  } else if (idObj == idStruc) {
    col4 = vec4 (0.4, 0.3, 0.1, 0.1);
    if (max (abs (qHit.x), abs (qHit.z + 0.22)) < 0.2) {
      cg = step (0.1, abs (fract (vec2 (10. * vec2 (qHit.x, qHit.z + 0.22)) + 0.5) - 0.5));
      if (cg.x * cg.y == 1.) col4 = vec4 (0.8, 0.8, 0.2, -1.);
    }
  } else if (idObj == idSailT) {
    qHit.x *= (1. + 0.07 * qHit.y) * (1. + 0.14 * step (1., abs (qHit.z)));
    col4 = vec4 (1., 1., 1., 0.) * (0.7 + 0.3 * SmoothBump (0.05, 0.95, 0.02, mod (4. * qHit.x, 1.)));
    if (abs (qHit.z) < 0.2 && abs (abs (length (qHit.xy - vec2 (0., 0.3)) - 0.35) - 0.15) < 0.07)
       col4 *= vec4 (1., 0.2, 0.2, 1.);
  } else if (idObj == idSailA) {
    col4 = vec4 (1., 1., 1., 0.) * (0.7 + 0.3 * SmoothBump (0.05, 0.95, 0.02, mod (5. * qHit.z, 1.)));
  } else if (idObj == idSailF) {
    col4 = vec4 (1., 1., 1., 0.) * (0.7 + 0.3 * SmoothBump (0.05, 0.95, 0.02,
       mod (2.95 * qHit.y + 4. * qHit.z - 0.5, 1.)));
  } else if (idObj == idFlag) {
    col4 = vec4 (1., 1., 0.5, 0.1);
    if (abs (abs (length (qHit.yz) - 0.1) - 0.04) < 0.02) col4 *= vec4 (1., 0.2, 0.2, 1.);
  } else if (idObj == idMast) {
    col4 = vec4 (0.7, 0.4, 0., 0.1);
    if (length (qHit.xz) < 0.16 * (1. - 0.07 * qHit.y))
       col4 *= 0.6 + 0.4 * SmoothBump (0.03, 0.97, 0.01, mod (2. * qHit.y / (1. + 0.14 * step (1., abs (qHit.z))), 1.));
    if (qHit.y > 3.65) col4 = vec4 (1., 0., 0., -1.);
  } else if (idObj == idSparT) {
    qHit.x *= (1. + 0.07 * qHit.y) * (1. + 0.14 * step (1., abs (qHit.z)));
    col4 = vec4 (0.7, 0.4, 0., 0.1) *  (0.6 + 0.4 * SmoothBump (0.08, 0.92, 0.01, mod (4. * qHit.x, 1.)));
  } else if (idObj == idSparL) {
    col4 = vec4 (0.7, 0.4, 0., 0.1);
    if (qHit.z > 6.65) col4 = vec4 (1., 1., 0.3, -1.);
  } else if (idObj == idRig) {
    col4 = vec4 (0.2, 0.15, 0.1, 0.);
  }
  return col4;
}

vec4 BirdCol (vec3 n)
{
  vec4 col4;
  vec3 nn;
  float gw, w;
  int ig, id;
  ig = idObj / 256;
  id = idObj - 256 * ig;
  if (id == idWing) {
    gw = 0.15 * birdLen;
    w = mod (qHit.x, gw);
    w = SmoothBump (0.15 * gw, 0.65 * gw, 0.1 * gw, w);
    col4 = vec4 (mix (vec3 (0.05), vec3 (1.), w), 0.1);
  } else if (id == idEye) {
    col4 = vec4 (0., 0.6, 0., 1.);
  } else if (id == idBdy) {
    if (ig == 1) nn = birdMat[0] * n;
    else nn = birdMat[1] * n;
    col4 = vec4 (mix (mix (vec3 (1.), vec3 (0.1), smoothstep (0.5, 1., nn.y)), vec3 (1.),
       1. - smoothstep (-1., -0.7, nn.y)), 0.1);
  } else if (id == idBk) {
    col4 = vec4 (1., 1., 0., 0.1);
  } else if (id == idLeg) {
    col4 = vec4 ((0.5 + 0.4 * sin (100. * qHit.z)) * vec3 (0.6, 0.4, 0.), 0.1);
  }
  return col4;
}

void EvalShipConf ()
{
  vec3 vd;
  shipConf = vec3 (-4. * szFac, 0., 0.);
  shipRot = 0.25 * pi * cos (0.02 * pi * tCur);
  vim[0] = vec3 (0., -3.5, 4.3);   vd = vec3 (0., -2.6, 6.7) - vim[0];   vum[0] = vec4 (normalize (vd), length (vd));
  vim[1] = vec3 (0., -4., 4.1);    vd = vec3 (0., -2.9, 6.) - vim[1];    vum[1] = vec4 (normalize (vd), length (vd));
  vim[2] = vec3 (0., -1.2, -3.);   vd = vec3 (0., -0.5, -4.5) - vim[2];  vum[2] = vec4 (normalize (vd), length (vd));
  vim[3] = vec3 (0., -2.7, -3.);   vd = vec3 (0., -2.7, -4.5) - vim[3];  vum[3] = vec4 (normalize (vd), length (vd));
  vir[0] = vec3 (0., -3., -4.45);  vd = vec3 (0., -2.7, -4.5) - vir[0];  vur[0] = vec4 (normalize (vd), length (vd));
  vir[1] = vec3 (0., 2.45, 2.65);  vd = vec3 (0., -2.7, 6.5) - vir[1];   vur[1] = vec4 (normalize (vd), length (vd));
  vir[2] = vec3 (0., 2.5, 2.65);   vd = vec3 (0., -3.2, 4.9) - vir[2];   vur[2] = vec4 (normalize (vd), length (vd));
  vir[3] = vec3 (0., 2.6, -3.);    vd = vec3 (0., -0.5, -4.5) - vir[3];  vur[3] = vec4 (normalize (vd), length (vd));
  vir[4] = vec3 (0.65, -3.5, 3.5); vd = vec3 (0.05, -2.7, 6.4) - vir[4]; vur[4] = vec4 (normalize (vd), length (vd));
}

vec3 ShowScene (vec3 ro, vec3 rd)
{
  vec4 col4;
  vec3 col, vn;
  vec2 vf;
  float dstObj, reflFac, dstWat;
  htWat = -1.5;
  cloudDisp = -0.05 * tCur * vec3 (1., 0., 1.);
  szFac = 1.;
  EvalShipConf ();
  isRefl = false;
  reflFac = 1.;
  dstObj = ObjRay (ro, rd);
  if (rd.y < 0. && dstObj >= dstFar) {
    isRefl = true;
    dstWat = - (ro.y - htWat) / rd.y;
    ro += dstWat * rd;
    rd = reflect (rd, WaveNf (ro.xz, dstWat));
    ro += 0.01 * rd;
    dstObj = ObjRay (ro, rd);
    reflFac *= 0.8;
  }
  if (dstObj < dstFar) {
    ro += rd * dstObj;
    vn = ObjNf (ro);
    col4 = (idObj <= idRig) ? ShipCol () : BirdCol (vn);
    col4.gb *= 0.7;
    col = reflFac * (col4.rgb * (0.2 + 0.8 * max (dot (vn, sunDir), 0.)) +
       col4.a * pow (max (dot (normalize (sunDir - rd), vn), 0.), 128.));
  } else {
    col = SkyCol (ro, rd);
    if (isRefl) col = reflFac * 0.7 * pow (col, vec3 (0.8));
  }
  return col;
}

vec3 BirdTrack (float t)
{
  vec3 bp, tt, fbR;
  float ti[9], rdTurn, tC, tCyc, tSeq, a, h, hd, tf, rSeg;
  rdTurn = 0.45 * min (fltBox.x, fltBox.z);
  tC = 0.5 * pi * rdTurn / birdVel;
  tt = vec3 (fltBox.x - rdTurn, length (fltBox.xy), fltBox.z - rdTurn) *
     2. / birdVel;
  tCyc = 2. * (2. * tt.z + tt.x  + 4. * tC + tt.y);
  tSeq = mod (t, tCyc);
  ti[0] = 0.;  ti[1] = ti[0] + tt.z;  ti[2] = ti[1] + tC;
  ti[3] = ti[2] + tt.x;  ti[4] = ti[3] + tC;  ti[5] = ti[4] + tt.z;
  ti[6] = ti[5] + tC;  ti[7] = ti[6] + tt.y;  ti[8] = ti[7] + tC;
  h = - fltBox.y;
  hd = 1.;
  if (tSeq > 0.5 * tCyc) { tSeq -= 0.5 * tCyc;  h = - h;  hd = - hd; }
  rSeg = -1.;
  fbR = vec3 (1.);
  fbR.xz -= vec2 (rdTurn) / fltBox.xz;
  bp.xz = fltBox.xz;
  bp.y = h;
  if (tSeq < ti[4]) {
    if (tSeq < ti[1]) {
      tf = (tSeq - ti[0]) / (ti[1] - ti[0]);
      bp.xz *= vec2 (1., fbR.z * (2. * tf - 1.));
    } else if (tSeq < ti[2]) {
      tf = (tSeq - ti[1]) / (ti[2] - ti[1]);  rSeg = 0.;
      bp.xz *= fbR.xz;
    } else if (tSeq < ti[3]) {
      tf = (tSeq - ti[2]) / (ti[3] - ti[2]);
      bp.xz *= vec2 (fbR.x * (1. - 2. * tf), 1.);
    } else {
      tf = (tSeq - ti[3]) / (ti[4] - ti[3]);  rSeg = 1.;
      bp.xz *= fbR.xz * vec2 (-1., 1.);
    }
  } else {
    if (tSeq < ti[5]) {
      tf = (tSeq - ti[4]) / (ti[5] - ti[4]);
      bp.xz *= vec2 (- 1., fbR.z * (1. - 2. * tf));
    } else if (tSeq < ti[6]) {
      tf = (tSeq - ti[5]) / (ti[6] - ti[5]);  rSeg = 2.;
      bp.xz *= - fbR.xz;
    } else if (tSeq < ti[7]) {
      tf = (tSeq - ti[6]) / (ti[7] - ti[6]);
      bp.xz *= vec2 (fbR.x * (2. * tf - 1.), - 1.);
      bp.y = h + 2. * fltBox.y * hd * tf;
    } else {
      tf = (tSeq - ti[7]) / (ti[8] - ti[7]);  rSeg = 3.;
      bp.xz *= fbR.xz * vec2 (1., -1.);
      bp.y = - h;
    }
  }
  if (rSeg >= 0.) {
    a = 0.5 * pi * (rSeg + tf);
    bp += rdTurn * vec3 (cos (a), 0., sin (a));
  }
  bp.y -= - fltBox.y - htWat;
  bp.xz = vec2 (- bp.z, bp.x);
  return bp;
}

void BirdPM (float t)
{
  vec3 bpF, bpB, vel, acc, va, ort, cr, sr;
  float dt, vy, el;
  dt = 1.;
  bdPos = BirdTrack (t);
  bpF = BirdTrack (t + dt);
  bpB = BirdTrack (t - dt);
  vel = (bpF - bpB) / (2. * dt);
  vy = vel.y;
  vel.y = 0.;
  acc = (bpF - 2. * bdPos + bpB) / (dt * dt);
  acc.y = 0.;
  va = cross (acc, vel) / length (vel);
  vel.y = vy;
  el = - 0.7 * asin (vel.y / length (vel));
  ort = vec3 (el, atan (vel.z, vel.x) - 0.5 * pi, 0.2 * length (va) * sign (va.y));
  cr = cos (ort);
  sr = sin (ort);
  bdMat = mat3 (cr.z, - sr.z, 0., sr.z, cr.z, 0., 0., 0., 1.) *
          mat3 (1., 0., 0., 0., cr.x, - sr.x, 0., sr.x, cr.x) *
          mat3 (cr.y, 0., - sr.y, 0., 1., 0., sr.y, 0., cr.y);
  legAng = pi * clamp (0.4 + 1.5 * el, 0.12, 0.8);
}

void mainImage (out vec4 fragColor, vec2 fragCoord)
{
  vec3 ro, rd;
  vec2 canvas, uv;
  canvas = iResolution.xy;
  uv = 2. * fragCoord.xy / canvas - 1.;
  uv.x *= canvas.x / canvas.y;
  tCur = iTime;
  birdLen = 0.5;
  birdVel = 5.;
  fltBox = vec3 (12., 4., 12.);
  BirdPM (tCur);
  birdMat[0] = bdMat;
  birdPos[0] = bdPos;
  BirdPM (tCur + 10.);
  birdMat[1] = bdMat;
  birdPos[1] = bdPos;
  ro = vec3 (0., 3., -30.);
  rd = normalize (vec3 (uv, 2.5));
  sunDir = normalize (vec3 (0., 0.05, 1.));
  dstFar = 100.;
  fragColor = vec4 (ShowScene (ro, rd), 1.);
}

float PrBoxDf (vec3 p, vec3 b)
{
  vec3 d;
  d = abs (p) - b;
  return min (max (d.x, max (d.y, d.z)), 0.) + length (max (d, 0.));
}

float PrBox2Df (vec2 p, vec2 b)
{
  vec2 d;
  d = abs (p) - b;
  return min (max (d.x, d.y), 0.) + length (max (d, 0.));
}

float PrCapsDf (vec3 p, float r, float h)
{
  return length (p - vec3 (0., 0., clamp (p.z, - h, h))) - r;
}

float PrEVCapsDf (vec3 p, vec4 u, float r)
{
  return length (p - clamp (dot (p, u.xyz), 0., u.w) * u.xyz) - r;
}

float PrEECapsDf (vec3 p, vec3 v1, vec3 v2, float r)
{
  return PrEVCapsDf (p - v1, vec4 (normalize (v2 - v1), length (v2 - v1)), r);
}

float PrSphDf (vec3 p, float r)
{
  return length (p) - r;
}

float PrCylDf (vec3 p, float r, float h)
{
  return max (length (p.xy) - r, abs (p.z) - h);
}

float PrFlatCylDf (vec3 p, float rhi, float rlo, float h)
{
  return max (length (p.xy - vec2 (rhi * clamp (p.x / rhi, -1., 1.), 0.)) - rlo, abs (p.z) - h);
}

float PrTorusDf (vec3 p, float ri, float rc)
{
  return length (vec2 (length (p.xy) - rc, p.z)) - ri;
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
  return q * cos (a) * vec2 (1., 1.) + q.yx * sin (a) * vec2 (-1., 1.);
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
