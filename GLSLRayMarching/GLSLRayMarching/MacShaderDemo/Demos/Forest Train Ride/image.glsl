// "Forest Train Ride" by dr2 - 2022
// License: Creative Commons Attribution-NonCommercial-ShareAlike 4.0

/* See "Truchet's Train" for more info. */

#define AA  0   // (= 0/1) optional antialiasing

#if 0
#define VAR_ZERO min (iFrame, 0)
#else
#define VAR_ZERO 0
#endif

float PrRoundBoxDf (vec3 p, vec3 b, float r);
float PrRoundBox2Df (vec2 p, vec2 b, float r);
float PrSphDf (vec3 p, float r);
float PrCylDf (vec3 p, float r, float h);
float PrConCapsDf (vec3 p, vec2 cs, float r, float h);
vec2 PixToHex (vec2 p);
vec2 HexToPix (vec2 h);
float HexEdgeDist (vec2 p);
float Minv2 (vec2 p);
float Maxv2 (vec2 p);
float Minv3 (vec3 p);
float Maxv3 (vec3 p);
float SmoothMin (float a, float b, float r);
float SmoothMax (float a, float b, float r);
float SmoothBump (float lo, float hi, float w, float x);
mat3 StdVuMat (float el, float az);
vec2 Rot2D (vec2 q, float a);
vec2 Rot2Cs (vec2 q, vec2 cs);
float Hashfv2 (vec2 p);
vec2 Hashv2v2 (vec2 p);
float Noisefv2 (vec2 p);
float Fbm2 (vec2 p);
float Fbm3 (vec3 p);
vec3 VaryNf (vec3 p, vec3 n, float f);

#define PLEN 17
#define N_CAR 4

vec4 cPath[PLEN], carPos[N_CAR], snowCol;
vec3 qHit, sunDir, tOff;
vec2 cIdB, cIdS, cMidB, cMidS, wlBase;
float dstFar, tCur, angRFac, hgSizeB, hgSizeS, tEnd[PLEN + 1], tLen, trVel, cDir, cType,
   trSzFac, viaWid, viaHt, watHt, csOcc;
int idObj;
bool trees, snow;
const int idGrnd = 1, idWat = 2, idVia = 3, idRail = 4, idFenc = 5, idTrnk = 6, idLvs = 7,
   idPost = 8, idCar = 9, idCon = 10, idWhl = 11, idFLamp = 12, idBLamp = 13;
const float pi = 3.1415927, sqrt3 = 1.7320508;

#define DMIN(id) if (d < dMin) { dMin = d;  idObj = id; }
#define DMINQ(id) if (d < dMin) { dMin = d;  idObj = id;  qHit = q; }

float Ddot (vec2 p)
{
  return dot (p, p);
}

vec3 TruchSDist (vec2 p)
{ // (from "Truchet's Train", with signed distance)
  vec2 pc, pc1, pc2, dp;
  float d, d1, d2, cxy, rc, ac, s, ss;
  bool ct;
  ct = (cType == 2. || cType == 4.);
  if (ct) {
    pc1 = - vec2 (0., cDir);
    pc2 = vec2 (sqrt3/2. * sign (p.x), 0.5 * cDir);
    d1 = Ddot (p - pc1);
    d2 = Ddot (p - pc2);
    d = min (d1, d2);
    pc = (d == d1) ? pc1 : pc2;
    rc = 0.5;
    d = abs (sqrt (d) - rc);
  } else {
    if (cDir != 0.) p = 0.5 * vec2 (p.x - cDir * sqrt3 * p.y, cDir * sqrt3 * p.x + p.y);
    pc1 = vec2 (sqrt3/2. * sign (p.x), 0.);
    pc2 = vec2 (sqrt3 * sign (p.x), 0.);
    d1 = sqrt (Ddot (p - pc1));
    d2 = abs (sqrt (Ddot (p - pc2)) - 1.5);
    d = min (d1, d2);
    pc = (d == d1) ? pc1 : pc2;
    rc = (d == d1) ? 0.: 1.5;
  }
  dp = p - pc;
  cxy = cIdB.x - cIdB.y;
  s = (ct && cxy < 0. || ! ct && abs (cxy - 2.) == 1.) ? -1. : 1.;
  ac = (0.5 - atan (dp.y, - dp.x) / (2. * pi)) * s;
  if (! ct && abs (cxy - 2.) <= 1.) ac += 1./6.;
  ss = sign (length (dp) - rc);
  return vec3 (d * ss, rc * ss * s, ac);
}

bool OnTrk (vec2 w)
{
  vec2 wp, wm;
  float cxy;
  bool cyo, offTrk;
  cxy = cIdB.x - cIdB.y;
  cyo = (mod (cIdB.y, 2.) == 1.);
  wm = Rot2Cs (w, sin (- pi / 3. + vec2 (0.5 * pi, 0.))) - vec2 (0., 0.3);
  wp = Rot2Cs (w, sin (pi / 3. + vec2 (0.5 * pi, 0.)));
  offTrk = (cxy == -2. && wm.y > 0. ||
     ! cyo && (cxy == -3. && w.y > -0.3 || cxy == -2. || cxy == -1. && wm.y > 0. ||
     cxy == 1. && wm.y < 0. || (cxy == 2. || cxy == 3.) && w.x < 0. || cxy == 4. || cxy == 5.) ||
     cyo && (cxy == -3. || cxy == 0. && wp.x > 0. || (cxy == 1. || cxy == 2.) && w.x > 0. || 
     cxy == 3. || cxy == 4. && wm.x < 0. || cxy == 5. && wm.y < 0.));
     return ! offTrk;
}

void SetPath ()
{
  float ts, tl;
  ts = 1.;
  tl = 1.5;
  cPath[ 0] = vec4 (0., 0., -1./6., tl);
  cPath[ 1] = vec4 (1., 0., 1./3., - ts);
  cPath[ 2] = vec4 (0., 1., 5./6., tl);
  cPath[ 3] = vec4 (-1., 1., -1./3., ts);
  cPath[ 4] = vec4 (-1., 2., 1., ts);
  cPath[ 5] = vec4 (0., 1., - 1./6., tl);
  cPath[ 6] = vec4 (1., 1., 1./6., tl);
  cPath[ 7] = vec4 (1., 2., 1., ts);
  cPath[ 8] = vec4 (2., 1., 1./2., - tl);
  cPath[ 9] = vec4 (2., 0., -1./2., tl);
  cPath[10] = vec4 (3., -1., -1./6., tl);
  cPath[11] = vec4 (4., -1., 1./3., - ts);
  cPath[12] = vec4 (3., 0., -1./2., - tl);
  cPath[13] = vec4 (3., 1., 1./2., tl);
  cPath[14] = vec4 (2., 2., 5./6., tl);
  cPath[15] = vec4 (1., 2., -1./3., ts);
  cPath[16] = vec4 (1., 3., 1., ts);
  tEnd[0] = 0.;
  for (int k = 0; k < PLEN; k ++) tEnd[k + 1] = tEnd[k] + abs (cPath[k].w);
  tLen = tEnd[PLEN];
}

vec2 EvalPPos (float t)
{
  vec4 cp;
  vec2 tp, vd;
  float tt, r, a, dc;
  t /= 3.;
  tp = floor (t / tLen) * vec2 (2.);
  t = mod (t, tLen);
  for (int k = 0; k < PLEN; k ++) {
    if (t >= tEnd[k] && t < tEnd[k + 1]) {
      cp = cPath[k];
      tt = 2. * (t - tEnd[k]) / (tEnd[k + 1] - tEnd[k]) - 1.;
      break;
    }
  }
  tp += cp.xy;
  if (abs (cp.w) == 1.5) {
    r = 1.5;
    dc = sqrt3;
    a = pi / 6.;
    tt *= sign (cp.w);
  } else {
    r = 0.5;
    dc = 1.;
    a = - sign (cp.w) * pi / 3.;
  }
  vd = vec2 (-1., 1.) * sin (pi * cp.z + vec2 (0., 0.5 * pi));
  return (HexToPix (tp) + dc * vd - r * Rot2Cs (vd, sin (tt * a + vec2 (0.5 * pi, 0.)))) * hgSizeB;
}

float CarDf (vec3 p, float dMin, float dir)
{  // (from "Alpine Express")
  vec3 q, qq;
  float d, s, ds;
  q = p;
  qq = q;
  s = 0.25;
  if (q.z * dir > 0.5) {
    ds = -0.25 * (q.z * dir - 0.5);
    s += ds;
    qq.y -= ds;
  }
  d = 0.9 * PrRoundBoxDf (qq, vec3 (0.3, s, 1.55), 0.4);
  DMINQ (idCar);
  q = p;
  q.xz = abs (q.xz);
  q.z = abs (q.z - wlBase.y);
  q -= vec3 (wlBase.x, -0.6, 0.2);
  d = PrCylDf (q.yzx, 0.15, 0.08);
  DMINQ (idWhl);
  q = p;
  q.z = (dir == 0.) ? abs (q.z) - 1.8 : q.z + 1.8 * dir;
  d = PrCylDf (q.xzy, 0.3, 0.5);
  DMINQ (idCon);
  if (dir > 0.) {
    q = p;
    q.yz -= vec2 (-0.25, 1.9);
    d = PrCylDf (q, 0.1, 0.1);
    DMINQ (idFLamp);
  } else if (dir < 0.) {
    q = p;
    q.x = abs (q.x) - 0.2;
    q.yz -= vec2 (-0.25, -1.9);
    d = PrCylDf (q, 0.08, 0.1);
    DMINQ (idBLamp);
  }
  return dMin;
}

float ObjDf (vec3 p)
{
  vec3 q;
  float dMin;
  dMin = dstFar / trSzFac;
  for (int k = VAR_ZERO; k < N_CAR; k ++) {
    q = (p - carPos[k].xyz) / trSzFac;
    q.xz = Rot2Cs (q.xz, sin (carPos[k].w + vec2 (0.5 * pi, 0.)));
    dMin = CarDf (q, dMin, (k > 0) ? ((k < N_CAR - 1) ? 0. : -1.) : 1.);
  }
  return dMin * trSzFac;
}

float ObjRay (vec3 ro, vec3 rd, float dstCut)
{
  float dHit, d, eps;
  eps = 0.001;
  dHit = 0.;
  for (int j = VAR_ZERO; j < 120; j ++) {
    d = ObjDf (ro + dHit * rd);
    if (d < eps * max (1., angRFac * dHit) || dHit > dstCut) break;
    dHit += d;
  }
  if (d >= eps * max (1., angRFac * dHit)) dHit = dstFar;
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

float ObjSShadow (vec3 ro, vec3 rd)
{
  float sh, d, h;
  sh = 1.;
  d = 0.02;
  for (int j = VAR_ZERO; j < 30; j ++) {
    h = ObjDf (ro + d * rd);
    sh = min (sh, smoothstep (0., 0.05 * d, h));
    d += max (h, 0.01);
    if (sh < 0.05 || d > dstFar) break;
  }
  return 0.5 + 0.5 * sh;
}

void BConf ()
{
  float h, cxy;
  cMidB = HexToPix (cIdB * hgSizeB);
  h = Hashfv2 (cIdB);
  if (Hashfv2 (17.11 * cIdB) > 0.4) {
    cDir = floor (3. * h) - 1.;
    cType = 3.;
  } else {
    cDir = 2. * floor (2. * h) - 1.;
    cType = 4.;
  }
  cxy = cIdB.x - cIdB.y;
  if (cxy == 0.) cType = 1.;
  else if (abs (cxy) == 1.) cType = mod (cIdB.x, 2.) + 1.;
  else if (cxy == -2. || cxy == -3. || cxy == 5.) cType = 2.;
  else if (cxy == 2. || cxy == 3. || cxy == 4.) cType = 1.;
  if (cType <= 2.) {
    if (cType == 1. && (cxy == 1. || cxy == 2. || cxy == 3.)) cDir = 0.;
    else if (cType == 1. && cxy == 4.) cDir = -1.;
    else if (cType == 2. && cxy == 5.) cDir = 1.;
    else cDir = 2. * mod (cIdB.x, 2.) - 1.;
  }
}

float GrndHt (vec2 p)
{
  float f, a, aSum;
  p *= 0.25;
  f = 0.;
  a = 1.;
  aSum = 0.;
  for (int j = 0; j < 3; j ++) {
    f += a * Noisefv2 (p);
    aSum += a;
    a *= 0.4;
    p *= 2.5;
  }
  return 2.2 * f / aSum;
}

float BObjDf (vec3 p)
{
  vec3 q, cm3;
  float dMin, d, dt, rc, ac, gHt, dh;
  bool onTrk;
  dMin = dstFar;
  if (cType > 0.) {
    q = p;
    q.xz = (q.xz - cMidB) / hgSizeB;
    dh = hgSizeB * HexEdgeDist (q.xz);
    cm3 = TruchSDist (q.xz);
    dt = hgSizeB * abs (cm3.x);
    rc = abs (cm3.y);
    ac = 18. * cm3.z;
    onTrk = (cType <= 2. && rc != 0. && OnTrk (q.xz));
    d = q.y - watHt;
    DMIN (idWat);
    gHt = GrndHt (p.xz);
    d = q.y - gHt;
    if (onTrk && gHt > viaHt - 0.1) d = min (SmoothMax (d, -0.2 - dot (vec2 (dt - viaWid,
       0.2 * gHt - q.y), sin (0.1 * pi + vec2 (0.5 * pi, 0.))), 0.1), q.y - (viaHt - 0.1));
    DMIN (idGrnd);
    if (onTrk) {
      d = max (max (abs (dt) - viaWid, q.y - viaHt), - (length (vec2 (abs (fract (9. *
         rc * ac + 0.5) - 0.5) / 3., q.y) - vec2 (0., min (q.y, viaHt - 0.3))) - 0.12));
      DMIN (idVia);
      d = PrRoundBox2Df (vec2 (dt - wlBase.x * trSzFac, q.y - viaHt - 0.01),
         vec2 (0.005, 0.01), 0.003);
      DMIN (idRail);
      d = min (length (vec2 (dt - viaWid + 0.03, q.y - viaHt - 0.12)) - 0.008,
         max (PrRoundBox2Df (vec2 (dt - viaWid + 0.03, (fract (9. * rc * ac + 0.5) -
         0.5) / 3.), vec2 (0.007, 0.001), 0.001), abs (q.y - viaHt - 0.06) - 0.06));
      DMIN (idFenc);
      if (cm3.y < 0.) {
        q = vec3 (dt - 0.23, q.y - viaHt - 0.4, dh);
        d = min (max (length (q.xz) - 0.012, q.y), PrSphDf (q, 0.03));
        DMIN (idPost);
      }
    }
  }
  return dMin;
}

float BObjRay (vec3 ro, vec3 rd, float dstCut)
{
  vec3 vri, vf, hv, p;
  vec2 edN[3], pM, cIdP;
  float dHit, d, s, eps;
  if (rd.x == 0.) rd.x = 0.0001;
  if (rd.z == 0.) rd.z = 0.0001;
  eps = 0.001;
  edN[0] = vec2 (1., 0.);
  edN[1] = 0.5 * vec2 (1., sqrt3);
  edN[2] = 0.5 * vec2 (1., - sqrt3);
  for (int k = 0; k < 3; k ++) edN[k] *= sign (dot (edN[k], rd.xz));
  vri = hgSizeB / vec3 (dot (rd.xz, edN[0]), dot (rd.xz, edN[1]), dot (rd.xz, edN[2]));
  vf = 0.5 * sqrt3 - vec3 (dot (ro.xz, edN[0]), dot (ro.xz, edN[1]),
     dot (ro.xz, edN[2])) / hgSizeB;
  pM = HexToPix (PixToHex (ro.xz / hgSizeB));
  hv = (vf + vec3 (dot (pM, edN[0]), dot (pM, edN[1]), dot (pM, edN[2]))) * vri;
  s = Minv3 (hv);
  cIdP = vec2 (-999.);
  dHit = 0.;
  for (int j = VAR_ZERO; j < 220; j ++) {
    p = ro + dHit * rd;
    cIdB = PixToHex (p.xz / hgSizeB);
    if (cIdB != cIdP) {
      cIdP = cIdB;
      BConf ();
    }
    d = BObjDf (p);
    if (dHit + d < s) {
      dHit += d;
    } else {
      dHit = s + eps;
      pM += sqrt3 * ((s == hv.x) ? edN[0] : ((s == hv.y) ? edN[1] : edN[2]));
      hv = (vf + vec3 (dot (pM, edN[0]), dot (pM, edN[1]), dot (pM, edN[2]))) * vri;
      s = Minv3 (hv);
    }
    if (d < eps * max (1., angRFac * dHit) || dHit > dstCut) break;
  }
  if (d >= eps * max (1., angRFac * dHit)) dHit = dstFar;
  return dHit;
}

vec3 BObjNf (vec3 p)
{
  vec4 v;
  vec2 e;
  e = vec2 (0.001, -0.001);
  for (int j = VAR_ZERO; j < 4; j ++) {
    v[j] = BObjDf (p + ((j < 2) ? ((j == 0) ? e.xxx : e.xyy) : ((j == 2) ? e.yxy : e.yyx)));
  }
  v.x = - v.x;
  return normalize (2. * v.yzw - dot (v, vec4 (1.)));
}

float BObjSShadow (vec3 ro, vec3 rd)
{
  vec3 p;
  vec2 cIdP;
  float sh, d, h;
  sh = 1.;
  d = 0.02;
  cIdP = vec2 (-999.);
  for (int j = VAR_ZERO; j < 30; j ++) {
    p = ro + d * rd;
    cIdB = PixToHex (p.xz / hgSizeB);
    if (cIdB != cIdP) {
      cIdP = cIdB;
      BConf ();
    }
    h = BObjDf (p);
    sh = min (sh, smoothstep (0., 0.05 * d, h));
    d += max (h, 0.01);
    if (sh < 0.05 || d > hgSizeB) break;
  }
  return 0.5 + 0.5 * sh;
}

void SConf ()
{
  vec2 r;
  cMidS = HexToPix (cIdS * hgSizeS);
  r = Hashv2v2 (73. * cIdS + 1.1);
  tOff.xz = 0.2 * sqrt3 * hgSizeS * (0.5 + 0.5 * r.x) * sin (2. * pi * r.y + vec2 (0.5 * pi, 0.));
  tOff.y = r.x + r.y;
}

void SBConf ()
{
  vec2 s, u;
  u = cMidS + tOff.xz;
  cIdB = PixToHex (u / hgSizeB);
  BConf ();
  s = (u - cMidB) / hgSizeB;
  csOcc = (hgSizeB * abs (TruchSDist (s).x) < 0.9 || GrndHt (cMidS) < watHt + 0.1) ? 0. :
     0.01 + 0.99 * Hashfv2 (17.11 * cIdS);
}

float SObjDf (vec3 p)
{
  vec3 q;
  float dMin, d, h;
  dMin = dstFar;
  if (csOcc > 0.) {
    q = p;
    q.xz = (q.xz - cMidS) / hgSizeS;
    q.xz -= tOff.xz;
    h = 0.15 + 0.15 * tOff.y;
    q.y -= h + GrndHt (cMidS);
    d = max (length (q.xz) - 0.05, q.y - h);
    DMIN (idTrnk);
    q.y -= h + 0.55;
    d = PrConCapsDf (q.xzy, sin (0.09 * pi + vec2 (0.5 * pi, 0.)), 0.18, 0.35);
    DMIN (idLvs);
  }
  return dMin;
}

float SObjRay (vec3 ro, vec3 rd, float dstCut)
{
  vec3 vri, vf, hv, p;
  vec2 edN[3], pM, cIdP;
  float dHit, d, s, eps;
  if (rd.x == 0.) rd.x = 0.0001;
  if (rd.z == 0.) rd.z = 0.0001;
  eps = 0.001;
  edN[0] = vec2 (1., 0.);
  edN[1] = 0.5 * vec2 (1., sqrt3);
  edN[2] = 0.5 * vec2 (1., - sqrt3);
  for (int k = 0; k < 3; k ++) edN[k] *= sign (dot (edN[k], rd.xz));
  vri = hgSizeS / vec3 (dot (rd.xz, edN[0]), dot (rd.xz, edN[1]), dot (rd.xz, edN[2]));
  vf = 0.5 * sqrt3 - vec3 (dot (ro.xz, edN[0]), dot (ro.xz, edN[1]),
     dot (ro.xz, edN[2])) / hgSizeS;
  pM = HexToPix (PixToHex (ro.xz / hgSizeS));
  hv = (vf + vec3 (dot (pM, edN[0]), dot (pM, edN[1]), dot (pM, edN[2]))) * vri;
  s = Minv3 (hv);
  cIdP = vec2 (-999.);
  dHit = 0.;
  for (int j = VAR_ZERO; j < 220; j ++) {
    p = ro + dHit * rd;
    cIdS = PixToHex (p.xz / hgSizeS);
    if (cIdS != cIdP) {
      cIdP = cIdS;
      SConf ();
    }
    SBConf ();
    d = SObjDf (p);
    if (dHit + d < s) {
      dHit += d;
    } else {
      dHit = s + eps;
      pM += sqrt3 * ((s == hv.x) ? edN[0] : ((s == hv.y) ? edN[1] : edN[2]));
      hv = (vf + vec3 (dot (pM, edN[0]), dot (pM, edN[1]), dot (pM, edN[2]))) * vri;
      s = Minv3 (hv);
    }
    if (d < eps * max (1., angRFac * dHit) || dHit > dstCut) break;
  }
  if (d >= eps * max (1., angRFac * dHit)) dHit = dstFar;
  return dHit;
}

vec3 SObjNf (vec3 p)
{
  vec4 v;
  vec2 e;
  e = vec2 (0.001, -0.001);
  for (int j = VAR_ZERO; j < 4; j ++) {
    v[j] = SObjDf (p + ((j < 2) ? ((j == 0) ? e.xxx : e.xyy) : ((j == 2) ? e.yxy : e.yyx)));
  }
  v.x = - v.x;
  return normalize (2. * v.yzw - dot (v, vec4 (1.)));
}

float SObjSShadow (vec3 ro, vec3 rd)
{
  vec3 p;
  vec2 cIdP;
  float sh, d, h;
  sh = 1.;
  d = 0.02;
  cIdP = vec2 (-999.);
  for (int j = VAR_ZERO; j < 30; j ++) {
    p = ro + d * rd;
    cIdS = PixToHex (p.xz / hgSizeS);
    if (cIdS != cIdP) {
      cIdP = cIdS;
      SConf ();
    }
    SBConf ();
    if (csOcc > 0.) {
      h = SObjDf (p);
      sh = min (sh, smoothstep (0., 0.1 * d, h));
      d += h;
    } else d += 0.1 * hgSizeS;
    if (sh < 0.05 || d > 2. * hgSizeS) break;
  }
  return 0.5 + 0.5 * sh;
}

vec4 CarCol ()
{
  vec4 col4;
  col4 = vec4 (0.7, 0., 0., 0.3);
  if (idObj == idCar) {
    col4 = (abs (qHit.y - 0.22) < 0.26) ? vec4 (0.3, 0.3, 0.5, 0.3) :
       ((abs (abs (qHit.y - 0.22) - 0.28) < 0.02) ? vec4 (0.4, 0.4, 0.8, 0.3) : col4);
  } else if (idObj == idCon) {
    col4 *= 0.8;
  } else if (idObj == idWhl) {
     col4 = (length (qHit.yz) < 0.07) ? vec4 (0.2, 0.2, 0.2, 0.1) :
        vec4 (0.6, 0.6, 0.6, 0.2);
  } else if (idObj == idFLamp) {
    if (qHit.z > 0.08) col4 = vec4 (1., 1., 0., -1.);
  } else if (idObj == idBLamp) {
    if (qHit.z < -0.08) col4 = vec4 (1., 0., 0., -1.);
  }
  return col4;
}

vec4 GrndViaCol (vec3 p, vec3 vn, inout vec2 vf)
{
  vec4 col4;
  vec3 cm3;
  vec2 w;
  float dt, rc, ac;
  bool onTrk;
  w = (p.xz - cMidB) / hgSizeB;
  cm3 = TruchSDist (w);
  dt = hgSizeB * abs (cm3.x);
  rc = abs (cm3.y);
  ac = 18. * abs (cm3.z);
  if (idObj == idGrnd) {
    col4 = snow ? snowCol : vec4 (0., 0.7, 0., 0.) * (0.6 + 0.4 * Fbm2 (4. * p.xz));
    onTrk = (cType <= 2. && rc != 0. && OnTrk (w));
    if (onTrk) {
      if (dt < 2.) col4 = mix ((snow ? snowCol : vec4 (0.5, 0.55, 0.5, 0.) * (0.97 +
         0.03 * sin (64. * pi * p.y))), col4, smoothstep (0.6, 0.9, vn.y));
      if (dt < viaWid + 0.05 && abs (p.y - viaHt + 0.1) < 0.01) col4 = snow ?
         snowCol : vec4 (0.5, 0.55, 0.5, 0.);
    }
    if (trees && csOcc > 0. && length ((p.xz - cMidS) / hgSizeS - tOff.xz) < 0.06) col4 *= 0.8;
    vf = vec2 (16., 1.);
  } else if (idObj == idVia) {
    col4 = (snow && p.y > viaHt - 0.01 && dt < viaWid - 0.01) ? snowCol :
       vec4 (0.6, 0.4, 0.1, 0.1);
    if (p.y > viaHt - 0.01 && dt < 0.2) {
      if (! snow) col4 = mix (col4, vec4 (0.6, 0.6, 0.5, 0.), smoothstep (0., 0.01, 0.22 - dt));
      if (dt < 0.15 && step (0.4, abs (fract (20. * rc * ac + 0.5) - 0.5)) > 0.)
         col4 = vec4 (0.5, 0.4, 0.3, 0.);
    } else col4 *= 0.8 + 0.2 * step (0.05, abs (fract (32. * p.y + 0.5) - 0.5));
    vf = vec2 (64., 1.);
  }
  return col4;
}

vec4 ObjCol (vec3 ro, vec3 vn, inout vec2 vf)
{
  vec4 col4;
  if (idObj == idGrnd || idObj == idVia) {
    col4 = GrndViaCol (ro, vn, vf);
  } else if (idObj == idWat) {
    col4 = vec4 (0.6, 0.6, 0.7, 0.);
  } else if (idObj == idTrnk) {
    col4 = vec4 (0.5, 0.3, 0.1, 0.1);
    vf = vec2 (32., 1.);
  } else if (idObj == idLvs) {
    col4 = vec4 (0.4, 0.7, 0.1, 0.) * (1.1 - 0.3 * csOcc);
    if (snow) col4 = mix (col4, snowCol, smoothstep (-0.8, -0.4, vn.y));
    else col4 = mix (col4, vec4 (0.9, 0.9, 0., 0.1), step (0.7, Fbm3 (64. * ro.xzy)));
    vf = vec2 (16., 2.);
  } else if (idObj == idFenc) {
    col4 = vec4 (0.8, 0.8, 0.9, 0.2);
  } else if (idObj == idPost) {
    col4 = (ro.y < viaHt + 0.37) ? vec4 (0.8, 0.8, 0.9, 0.2) : vec4 (1., 1., 0.4, -1.);
  } else if (idObj == idRail) {
    col4 = vec4 (0.7, 0.7, 0.75, 0.1);
  } else if (idObj >= idCar && idObj <= idBLamp) {
    col4 = CarCol ();
  }
  return col4;
}

vec3 SkyCol (vec3 rd)
{
  rd.y = abs (rd.y);
  return mix (vec3 (0.3, 0.35, 0.7), vec3 (0.8, 0.8, 0.8),
     clamp (2. * (Fbm2 (4. * rd.xz / rd.y + 0.1 * tCur) - 0.1) * rd.y, 0., 1.));
}

vec3 ShowScene (vec3 ro, vec3 rd)
{
  vec4 col4;
  vec3 col, vn, rs, rdd;
  vec2 vf;
  float dstObj, dstObjB, dstObjS, dstObjNR, dstCut, sh, reflFac;
  int idObjB, idObjS;
  bool isLit;
  reflFac = 0.;
  dstObjNR = 0.;
  snowCol = vec4 (0.9, 0.9, 0.95, 0.1);
  vf = vec2 (0.);
  for (int k = VAR_ZERO; k < 2; k ++) {
    dstCut = dstFar;
    if (trees) {
      dstObjS = SObjRay (ro, rd, dstCut);
      dstCut = min (dstCut, dstObjS);
      idObjS = idObj;
    } else dstObjS = dstFar;
    dstObjB = BObjRay (ro, rd, dstCut);
    dstCut = min (dstCut, dstObjB);
    idObjB = idObj;
    dstObj = ObjRay (ro, rd, dstCut);
    if (min (dstObjB, dstObjS) < min (dstObj, dstFar)) {
      if (dstObjB < dstObjS) {
        dstObj = dstObjB;
        idObj = idObjB;
      } else {
        dstObj = dstObjS;
        idObj = idObjS;
      }
    }
    if (k == 0 && dstObj < dstFar && idObj == idWat) {
      ro += dstObj * rd;
      rd = reflect (rd, VaryNf (4. * ro, vec3 (0., 1., 0.), 0.1));
      ro += 0.01 * rd;
      dstObjNR = dstObj;
      reflFac = 0.2;
    } else break;
  }     
  isLit = false;
  if (min (dstObjB, dstObjS) < dstObj) {
    if (dstObjB < dstObjS) {
      dstObj = dstObjB;
      idObj = idObjB;
    } else {
      dstObj = dstObjS;
      idObj = idObjS;
    }
  }
  if (dstObj < dstFar) {
    ro += dstObj * rd;
    if (dstObj == dstObjB) {
      cIdB = PixToHex (ro.xz / hgSizeB);
      BConf ();
      vn = BObjNf (ro);
    } else if (dstObj == dstObjS) {
      cIdS = PixToHex (ro.xz / hgSizeS);
      SConf ();
      SBConf ();
      vn = SObjNf (ro);
    } else {
      vn = ObjNf (ro);
    }
    col4 = ObjCol (ro, vn, vf);
    if (idObj == idCar) {
      rdd = reflect (rd, vn);
      reflFac = (abs (qHit.y - 0.22) < 0.26) ? 0.6 : 0.2;
    }
    if (col4.a >= 0.) {
      rs = ro + 0.01 * vn;
      sh = min (ObjSShadow (rs, sunDir), BObjSShadow (rs, sunDir));
      if (trees) sh = min (sh, SObjSShadow (rs, sunDir));
      if (vf.x > 0.) vn = VaryNf (vf.x * ro, vn, vf.y);
      isLit = true;
    } else {
      col = col4.rgb * (0.4 + 0.6 * max (- dot (rd, vn), 0.));
    }
  } else if (rd.y < 0.) {
    dstObj = - ro.y / rd.y;
    vn = vec3 (0., 1., 0.);
    col4 = 0.8 * vec4 (0., 0.8, 0., 0.);
    sh = 1.;
    isLit = true;
  } else {
    col = SkyCol (rd);
  }
  if (isLit) {
    col = col4.rgb * (0.3 + 0.1 * max (- dot (sunDir, vn), 0.) +
       0.7 * sh * max (dot (vn, sunDir), 0.)) +
       col4.a * step (0.95, sh) * pow (max (dot (reflect (sunDir, vn), rd), 0.), 32.);
    col = mix (col, SkyCol (rd), 1. - exp (min (0., 1. - 5. * (dstObjNR + dstObj) / dstFar)));
  }
  if (reflFac > 0.) col = mix (0.9 * col, SkyCol (rdd), reflFac);
  return clamp (col, 0., 1.);
}

#define N_WIN  3

void mainImage (out vec4 fragColor, in vec2 fragCoord)
{
  mat3 vuMat;
  vec4 mPtr;
  vec3 ro, rd, col, vd, pAv;
  vec2 canvas, uv, uvv, mMid[N_WIN], ut[N_WIN], mSize, msw, pc[3];
  float el, az, zmFac, asp, sr, cGap, t, nc;
  int vuId, regId;
  canvas = iResolution.xy;
  uv = 2. * fragCoord.xy / canvas - 1.;
  uv.x *= canvas.x / canvas.y;
  tCur = iTime;
  mPtr = iMouse;
  mPtr.xy = mPtr.xy / canvas - 0.5;
  tCur += 10.;
  asp = canvas.x / canvas.y;
  mSize = (1./5.) * vec2 (asp, 1.);
  mMid[0] = (1. - mSize.y) * vec2 (- asp, 1.);
  mMid[1] = (1. - mSize.y) * vec2 (asp, 1.);
  mMid[2] = (1. - mSize.y) * vec2 (asp, -1.);
  for (int k = 0; k < N_WIN; k ++) ut[k] = abs (uv - mMid[k]) - mSize;
  regId = -1;
  if (mPtr.z > 0.) {
    regId = 0;
    for (int k = 0; k < N_WIN; k ++) {
      msw = 2. * mPtr.xy - mMid[k] / vec2 (asp, 1.);
      if (Maxv2 (abs (msw)) < mSize.y) {
        regId = k + 1;
        msw /= 2. * mSize.y;
        break;
      }
    }
    if (regId == 0) msw = mPtr.xy;
  }
  vuId = 0;
  for (int k = 0; k < N_WIN; k ++) {
    if (Maxv2 (ut[k]) < 0.) {
      uv = (uv - mMid[k]) / mSize.y;
      vuId = k + 1;
      break;
    }
  }
  if (regId > 0 && (vuId == 0 || vuId == regId)) vuId = regId - vuId;
  hgSizeB = 16.;
  hgSizeS = 1.;
  watHt = 0.7;
  viaWid = 0.3;
  viaHt = 1.1;
  trSzFac = 0.2;
  SetPath ();
  trees = true;
  snow = (uv.x / asp > -1.+ 2. * SmoothBump (0.25, 0.75, 0.01, fract (0.02 * (tCur - 10.))));
  cGap = 0.74 * trSzFac;
  wlBase = vec2 (0.5, 0.9);
  trVel = 0.2;
  az = 0.;
  el = 0.;
  if (mPtr.z > 0. && vuId == regId) {
    az += 2. * pi * msw.x;
    el += 0.5 * pi * msw.y;
  }
  pAv = vec3 (0.);
  for (int k = VAR_ZERO; k < N_CAR; k ++) {
    t = (tCur + 30.) * trVel - float (k) * cGap;
    for (int j = VAR_ZERO; j < 3; j ++)
       pc[j] = EvalPPos (t + ((j > 0) ? sign (float (j) - 1.5) * wlBase.y * trSzFac : 0.));
    carPos[k].xz = pc[0];
    carPos[k].y = viaHt + 0.9 * trSzFac;
    pAv += carPos[k].xyz;
    vd.xy = pc[2] - pc[1];
    carPos[k].w = 0.5 * pi - atan (vd.y, vd.x);
  }
  nc = float (N_CAR);
  pAv /= nc;
  t = (tCur + 30.) * trVel;
  angRFac = 1.;
  if (vuId == 0 || vuId == 3) {
    ro.xz = EvalPPos (t - ((vuId == 0) ? nc + 2. :  -3.) * cGap);
    ro.x += 0.01;
    ro.y = viaHt + 1.;
    vd = normalize (((vuId == 0) ? carPos[N_CAR - 2].xyz : carPos[1].xyz) - ro);
    az += atan (vd.z, - vd.x) - 0.5 * pi;
    el += asin (vd.y);
    el = clamp (el, -0.2 * pi, 0.15 * pi);
    zmFac = 3.;
    dstFar = 12. * hgSizeB;
  } else if (vuId == 1) {
    ro = vec3 (0., 40., (-3. * sqrt3 + (2. / tLen) * t) * hgSizeB);
    ro.xz = Rot2D (ro.xz, - pi / 3.);
    ro.xz += 0.01;
    ro.x += 1.6 * hgSizeB;
    az += pi / 3.;
    el -= 0.15 * pi;
    el = clamp (el, -0.4 * pi, -0.1 * pi);
    zmFac = 5.;
    dstFar = 30. * hgSizeB;
  } else if (vuId == 2) {
    ro = vec3 (0., 20., (-1.5 * sqrt3 + (2. / tLen) * t) * hgSizeB);
    ro.xz = Rot2D (ro.xz, - pi / 3.);
    ro.xz += 0.01;
    ro.x -= 1.5 * hgSizeB;
    vd = normalize (pAv - ro);
    az = atan (vd.z, - vd.x) - 0.5 * pi;
    el = asin (vd.y);
    zmFac = 40.;
    angRFac = 0.1;
    dstFar = 30. * hgSizeB;
  }
  vuMat = StdVuMat (el, az);
  sunDir = normalize (vec3 (0., 1.5, -1.));
  sunDir.xz = Rot2D (sunDir.xz, - pi / 3.);
#if ! AA
  const float naa = 1.;
#else
  const float naa = 3.;
#endif  
  col = vec3 (0.);
  sr = 2. * mod (dot (mod (floor (0.5 * (uv + 1.) * canvas), 2.), vec2 (1.)), 2.) - 1.;
  for (float a = float (VAR_ZERO); a < naa; a ++) {
    uvv = (uv + step (1.5, naa) * Rot2D (vec2 (0.5 / canvas.y, 0.), sr * (0.667 * a + 0.5) *
       pi)) / zmFac;
    rd = vuMat * normalize (vec3 (2. * tan (0.5 * atan (uvv.x / asp)) * asp, uvv.y, 1.));
    col += (1. / naa) * ShowScene (ro, rd);
  }
  for (int k = 0; k < N_WIN; k ++) {
    if (Maxv2 (ut[k]) < 0. && Minv2 (abs (ut[k])) * canvas.y < 3.) col = vec3 (0.7, 0.3, 0.3);
  }
  fragColor = vec4 (col, 1.);
}

float PrRoundBoxDf (vec3 p, vec3 b, float r)
{
  return length (max (abs (p) - b, 0.)) - r;
}

float PrRoundBox2Df (vec2 p, vec2 b, float r)
{
  return length (max (abs (p) - b, 0.)) - r;
}

float PrSphDf (vec3 p, float r)
{
  return length (p) - r;
}

float PrCylDf (vec3 p, float r, float h)
{
  return max (length (p.xy) - r, abs (p.z) - h);
}

float PrConCapsDf (vec3 p, vec2 cs, float r, float h)
{
  float d;
  d = max (dot (vec2 (length (p.xy) - r, p.z), cs), abs (p.z) - h);
  h /= cs.x * cs.x;
  r /= cs.x;
  d = min (d, min (length (vec3 (p.xy, p.z + r * cs.y - h)) - r + h * cs.y,
     length (vec3 (p.xy, p.z + r * cs.y + h)) - r - h * cs.y));
  return d;
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

float HexEdgeDist (vec2 p)
{
  p = abs (p);
  return (sqrt3/2.) - p.x + 0.5 * min (p.x - sqrt3 * p.y, 0.);
}

float Minv2 (vec2 p)
{
  return min (p.x, p.y);
}

float Maxv2 (vec2 p)
{
  return max (p.x, p.y);
}

float Maxv3 (vec3 p)
{
  return max (p.x, max (p.y, p.z));
}

float Minv3 (vec3 p)
{
  return min (p.x, min (p.y, p.z));
}

float SmoothMin (float a, float b, float r)
{
  float h;
  h = clamp (0.5 + 0.5 * (b - a) / r, 0., 1.);
  return mix (b - h * r, a, h);
}

float SmoothMax (float a, float b, float r)
{
  return - SmoothMin (- a, - b, r);
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

vec2 Rot2Cs (vec2 q, vec2 cs)
{
  return vec2 (dot (q, vec2 (cs.x, - cs.y)), dot (q.yx, cs));
}

const float cHashM = 43758.54;

float Hashfv2 (vec2 p)
{
  return fract (sin (dot (p, vec2 (37., 39.))) * cHashM);
}

vec2 Hashv2v2 (vec2 p)
{
  vec2 cHashVA2 = vec2 (37., 39.);
  return fract (sin (dot (p, cHashVA2) + vec2 (0., cHashVA2.x)) * cHashM);
}

vec4 Hashv4v3 (vec3 p)
{
  vec3 cHashVA3 = vec3 (37., 39., 41.);
  return fract (sin (dot (p, cHashVA3) + vec4 (0., cHashVA3.xy, cHashVA3.x + cHashVA3.y)) * cHashM);
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
  for (int j = 0; j < 5; j ++) {
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
  vec4 v;
  vec3 g;
  vec2 e = vec2 (0.1, 0.);
  for (int j = VAR_ZERO; j < 4; j ++)
     v[j] = Fbmn (p + ((j < 2) ? ((j == 0) ? e.xyy : e.yxy) : ((j == 2) ? e.yyx : e.yyy)), n);
  g = v.xyz - v.w;
  return normalize (n + f * (g - n * dot (n, g)));
}
