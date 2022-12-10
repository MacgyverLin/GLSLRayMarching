// "Complex Tunnels" by dr2 - 2016
// License: Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License

/*
  Shader tunnels come in various forms. Some are based on 2D imagery
  designed to give apparent depth. Others use 3D imagery, but the
  horizontal (and sometimes vertical) coordinates are shifted with depth
  to mimic effects such as turns. Such methods reduce computation but
  are limited in what they can do. Here the tunnels are really 3D, and
  to show what is going on the tunnel walls are partly open. Thomas the
  engine (3 or 5 of them) travels around the entire track. Speed and view can
  be controlled; the mouse helps looking around (in some views), and the
  engine being followed changes.
*/

#define txBuf iChannel0
#define txSize iChannelResolution[0].xy

const float pi = 3.14159;
const vec4 cHashA4 = vec4 (0., 1., 57., 58.);
const vec3 cHashA3 = vec3 (1., 57., 113.);
const float cHashM = 43758.54;

vec4 Hashv4f (float p)
{
  return fract (sin (p + cHashA4) * cHashM);
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

float Fbmn (vec3 p, vec3 n)
{
  vec3 s;
  float a;
  s = vec3 (0.);
  a = 1.;
  for (int i = 0; i < 5; i ++) {
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

float PrOBox2Df (vec2 p, vec2 b)
{
  return length (max (abs (p) - b, 0.));
}

float PrCylDf (vec3 p, float r, float h)
{
  return max (length (p.xy) - r, abs (p.z) - h);
}

float PrCapsDf (vec3 p, float r, float h)
{
  return length (p - vec3 (0., 0., h * clamp (p.z / h, -1., 1.))) - r;
}

float SmoothBump (float lo, float hi, float w, float x)
{
  return (1. - smoothstep (hi - w, hi + w, x)) * smoothstep (lo - w, lo + w, x);
}

vec2 Rot2D (vec2 q, float a)
{
  return q * cos (a) + q.yx * sin (a) * vec2 (-1., 1.);
}

const float txRow = 64.;

vec4 Loadv4 (int idVar)
{
  float fi;
  fi = float (idVar);
  return texture (txBuf, (vec2 (mod (fi, txRow), floor (fi / txRow)) + 0.5) /
     txSize);
}

// Set = 1 in BOTH shaders for more fun. WARNING: browser crashes reported
#define LONG_TRACK 0
//#define LONG_TRACK 1

#if LONG_TRACK
#define N_ENG 5
#else
#define N_ENG 3
#endif

// Debugging: Set = 0 (here only) to disable tunnel rendering
#define SHOW_TUN 1
//#define SHOW_TUN 0

vec4 pCar[N_ENG], pVu;
vec3 qHit, ltExDir, bgCol;
vec2 rlSize, tunSize;
float dstFar, tCur, szFac, trMov, rgHSize, trkWid, wallThk, bWid, bLen,
   dH, dR, dV, dT;
int idObj, idObjGrp, riding;

const int idEng = 1, idCabin = 2, idCoal = 3, idBase = 4, idBand = 5, idAxle = 6,
   idRoof = 7, idWheel = 8, idSpoke = 9, idCrod = 10, idFunl = 11, idFunt = 12,
   idStripe = 13, idFLamp = 14, idBLamp = 15, idCpl = 16, idGrnd = 21,
   idRail = 22, idVrt = 23, idHrz = 24, idTun = 25, idLight = 26;
const int dirNS = 0, dirEW = 1, dirSW = 2, dirNW = 3, dirSE = 4, dirNE = 5,
   dirX = 6;

void SimpSeg (vec3 q, int indx)
{
  vec3 qq;
  if (indx == dirEW) q.xz = q.zx;
  else if (indx == dirNW) q.z *= -1.;
  else if (indx == dirSE) q.x *= -1.;
  else if (indx == dirNE) q.xz *= -1.;
  qq = q;  qq.y -= tunSize.y - 0.5 * rlSize.y;
  if (indx <= dirEW) {
    q.x = abs (q.x);
  } else {
    q.xz += 0.5;  q.x = abs (length (q.xz) - 0.5);
  }
  q.xy -= vec2 (trkWid, rlSize.y);
  dR = PrOBox2Df (q.xy, rlSize);
#if SHOW_TUN
  q.xy -= vec2 (- trkWid, - rlSize.y + tunSize.y);
  dT = max (PrBox2Df (q.xy, tunSize + vec2 (0.5 * wallThk)),
     - PrBox2Df (q.xy, tunSize - vec2 (0.5 * wallThk)));
  dT = max (dT, - (abs (q.y) - 0.6 * tunSize.y));
  if (indx <= dirEW) {
    q.x -= tunSize.x;
    q.z = abs (q.z) - 0.5;
    dV = PrCylDf (q.xzy, bWid, tunSize.y);
    q.xy -= vec2 (- tunSize.x, tunSize.y - 0.5 * bWid);
    dH = PrCylDf (q.yzx, bWid, bLen);
  } else {
    q = qq;
    q.xz = q.zx;  q.x = abs (q.x) - tunSize.x;  q.z = q.z + 0.5;
    dV = PrCylDf (q.xzy, bWid, tunSize.y);
    q.xy -= vec2 (- tunSize.x, tunSize.y - 0.5 * bWid);
    dH = PrCylDf (q.yzx, bWid, bLen);
    q = qq;  q.x = abs (q.x) - tunSize.x;  q.z = q.z + 0.5;
    dV = min (dV, PrCylDf (q.xzy, bWid, tunSize.y));
    q.xy -= vec2 (- tunSize.x, tunSize.y - 0.5 * bWid);
    dH = min (dH, PrCylDf (q.yzx, bWid, bLen));
  }
#endif
}

void CrossSeg (vec3 q, int indx)
{
  vec3 qq;
  qq = q;
  q = qq;  q.y -= rlSize.y;  qq = q;
  q.x = abs (q.x) - trkWid;  q.z += 0.5;
  dR = PrOBox2Df (q.xy, rlSize);
  q = qq;  q.xz = q.zx;  q.z += 0.5;  q.x = abs (q.x) - trkWid;
  dR = min (dR, PrOBox2Df (q.xy, rlSize));
  q = qq;  q.xz = abs (q.xz) - trkWid + 1.75 * rlSize.x;
  dR = max (dR, - min (PrBox2Df (q.xz, vec2 (trkWid, 0.75 * rlSize.x)),
     PrBox2Df (q.zx, vec2 (trkWid, 0.75 * rlSize.x))));
#if SHOW_TUN
  q = qq;
  q.y -= tunSize.y - rlSize.y;
  dT = max (PrBox2Df (q.xy, tunSize + vec2 (0.5 * wallThk)),
      - PrBox2Df (q.xy, tunSize - vec2 (0.5 * wallThk)));
  q.xz = q.zx;
  dT = min (dT, max (PrBox2Df (q.xy, tunSize + vec2 (0.5 * wallThk)),
      - PrBox2Df (q.xy, tunSize - vec2 (0.5 * wallThk))));
  dT = max (dT, - PrBoxDf (q, vec3 (tunSize.x + 1.1 * wallThk,
     tunSize.y - 0.5 * wallThk, tunSize.x + 1.1 * wallThk)));
  dT = max (dT, - (abs (q.y) - 0.6 * tunSize.y));
  qq.y -= tunSize.y - rlSize.y;
  q = qq;  q.xz = abs (q.xz) - tunSize.x - wallThk;
  dV = PrCylDf (q.xzy, bWid, tunSize.y);
  q = qq;  q.xz = abs (q.xz) - vec2 (tunSize.x, 0.5);
  dV = min (dV, PrCylDf (q.xzy, bWid, tunSize.y));
  q = qq;  q.xz = q.zx;  q.xz = abs (q.xz) - vec2 (tunSize.x, 0.5);
  dV = min (dV, PrCylDf (q.xzy, bWid, tunSize.y));
  qq.y -= tunSize.y - 0.5 * bWid;
  q = qq;  q.x = abs (q.x) - 0.5;
  dH = PrCylDf (q.yxz, bWid, bLen);
  q = qq;  q.xz = q.zx;  q.x = abs (q.x) - 0.5;
  dH = min (dH, PrCylDf (q.yxz, bWid, bLen));
  q = qq;  q.xz = Rot2D (q.xz, 0.25 * pi);
  dH = min (dH, min (PrCylDf (q.yzx, bWid, 1.42 * bLen),
     PrCylDf (q.yxz, bWid, 1.42 * bLen)));
#endif
}

int GetIx (int isq)
{
  int indx;
  indx = -1;
#if LONG_TRACK
  if (isq == 1 || isq == 2 || isq == 3 || isq == 4 || isq == 13 ||
     isq == 16 || isq == 19 || isq == 22 || isq == 31 || isq == 34) indx = dirEW;
  else if (isq == 6 || isq == 11 || isq == 24 || isq == 26 || isq == 27 ||
     isq == 29) indx = dirNS;
  else if (isq == 12 || isq == 30 || isq == 33) indx = dirSE;
  else if (isq == 17 || isq == 32 || isq == 35) indx = dirSW;
  else if (isq == 0 || isq == 15 || isq == 18) indx = dirNE;
  else if (isq == 5 || isq == 14 || isq == 23) indx = dirNW;
  else if (isq == 20 || isq == 21) indx = dirX;
#else
  if (isq == 6 || isq == 8 || isq == 20 || isq == 23 || isq == 26 ||
     isq == 29) indx = dirNS;
  else if (isq == 1 || isq == 13 || isq == 15 || isq == 16 || isq == 33 ||
     isq == 34) indx = dirEW;
  else if (isq == 35) indx = dirSW;
  else if (isq == 2 || isq == 17) indx = dirNW;
  else if (isq == 12 || isq == 32) indx = dirSE;
  else if (isq == 0) indx = dirNE;
  else if (isq == 14) indx = dirX;
#endif
  return indx;
}

float TrackDf (vec3 p)
{
  vec3 q, qh;
  vec2 ip;
  float dMin, d, dUsq, sqWid;
  int indx, isq;
  bLen = tunSize.x + bWid;
  dMin = dstFar;
  ip = floor (p.xz);
  q = p;  q.xz = fract (q.xz) - vec2 (0.5);
  isq = int (2. * rgHSize * mod (ip.y + rgHSize, 2. * rgHSize) +
     mod (ip.x + rgHSize, 2. * rgHSize));
  indx = GetIx (isq);
  d = dstFar;
  if (indx >= 0 && indx <= dirX) {
    qh = q;
    q.y -= 0.5 * rlSize.y;
    if (indx < dirX) SimpSeg (q, indx);
    else CrossSeg (q, indx);
    sqWid = 0.4999;
    dUsq = max (PrOBox2Df (p.xz, vec2 (2. * sqWid * rgHSize)),
       PrBox2Df (q.xz, vec2 (sqWid)));
    dR = max (dR, dUsq);
    if (dR < dMin) { dMin = dR;  idObj = idRail; }
#if SHOW_TUN
    dT = max (dT, dUsq);
    if (dT < dMin) { dMin = dT;  idObj = idTun; }
    dV = max (dV, dUsq);
    if (dV < dMin) { dMin = dV;  idObj = idVrt; }
    dH = max (dH, dUsq);
    if (dH < dMin) { dMin = dH;  idObj = idHrz; }
    q = qh;  q.y -= 2. * tunSize.y - bWid;
    d = max (PrCylDf (q.xzy, 1.1 * bWid, 0.6 * bWid), dUsq);
    if (d < dMin) { dMin = d;  idObj = idLight; }
#endif
  }
  return dMin;
}

float TrackRay (vec3 ro, vec3 rd)
{
  vec3 p;
  vec2 srd, dda, h;
  float dHit, d;
  srd = - sign (rd.xz);
  dda = - srd / (rd.xz + 0.0001);
  dHit = max (0., PrBox2Df (ro.xz, vec2 (rgHSize)));
  for (int j = 0; j < 160; j ++) {
    p = ro + dHit * rd;
    h = fract (dda * fract (srd * p.xz));
    d = TrackDf (p);
    dHit += min (d, 0.001 + max (0., min (h.x, h.y)));
    if (d < 0.0001 || dHit > dstFar || p.y < 0.) break;
  }
  if (d > 0.0001) dHit = dstFar;
  return dHit;
}

float EngDf (vec3 p, float dMin)
{
  vec3 q;
  float d, aw, a, sx, wRad, tw;
  wRad = 0.8;
  tw = 214. * szFac * trkWid;
  q = p;
  q -= vec3 (0., -0.2, 0.5);
  d = max (PrCapsDf (q, 1., 2.), - (q.z + 1.7));
  if (d < dMin) { dMin = d;  idObj = idObjGrp + idEng; }
  q = p;  q.z = abs (q.z - 0.85);  q -= vec3 (0., -0.2, 1.8);
  d = PrCylDf (q, 1.05, 0.05);
  if (d < dMin) { dMin = d;  idObj = idObjGrp + idBand; }
  q = p;  q -= vec3 (0., -1.3, -0.25);
  d = PrBoxDf (q, vec3 (1., 0.1, 3.2));
  q = p;  q -= vec3 (0., -1.4, 3.);
  d = min (d, PrBoxDf (q, vec3 (1.1, 0.2, 0.07)));
  if (d < dMin) { dMin = d;  idObj = idObjGrp + idBase; }
  q.x = abs (q.x);  q -= vec3 (0.6, 0., 0.1);
  d = PrCylDf (q, 0.2, 0.1);
  q = p;  q -= vec3 (0., -2.4, -1.75);
  d = min (d, max (PrCylDf (q, 4., 0.65), - (q.y - 3.75)));
  if (d < dMin) { dMin = d;  idObj = idObjGrp + idRoof; }
  q = p;  q -= vec3 (0., 0.01, -1.75);
  d = max (max (PrBoxDf (q, vec3 (1., 1.4, 0.6)),
     - PrBoxDf (q - vec3 (0., 0., -0.2), vec3 (0.95, 1.3, 0.65))),
     - PrBoxDf (q - vec3 (0., 0.7, 0.), vec3 (1.1, 0.4, 0.5)));
  q.x = abs (q.x);  q -= vec3 (0.4, 1., 0.4);
  d = max (d, - PrBoxDf (q, vec3 (0.35, 0.15, 0.3)));
  if (d < dMin) { dMin = d;  idObj = idObjGrp + idCabin;  qHit = q; }
  q = p;  q -= vec3 (0., -0.5, -3.15);
  d = PrBoxDf (q, vec3 (1., 0.7, 0.3));
  if (d < dMin) { dMin = d;  idObj = idObjGrp + idCoal;  qHit = q; }
  q = p;  q -= vec3 (0., -1.4, -3.5);
  d = PrCylDf (q.xzy, 0.4, 0.03);
  if (d < dMin) { dMin = d;  idObj = idObjGrp + idCpl; }
  q = p;  q.xz = abs (q.xz);  q -= vec3 (tw - 0.12, -1.4, 1.1);
  d = PrCylDf (q.zyx, wRad, 0.1);
  aw = - trMov / (szFac * wRad);
  if (d < dMin) {
    d = min (max (min (d, PrCylDf (q.zyx - vec3 (0.,0., -0.07), wRad + 0.05, 0.03)),
       - PrCylDf (q.zyx, wRad - 0.1, 0.12)), PrCylDf (q.zyx, 0.15, 0.10));
    if (d < dMin) { dMin = d;  idObj = idObjGrp + idWheel; }
    q = p;  q.x = abs (q.x);  q -= vec3 (tw - 0.17, -1.4, 1.1 * sign (q.z));
    q.yz = q.yz * cos (aw) + q.zy * sin (aw) * vec2 (-1., 1.);  
    a = floor ((atan (q.y, q.z) + pi) * 8. / (2. * pi) + 0.5) / 8.;
    q.yz = q.yz * cos (2. * pi * a) + q.zy * sin (2. * pi * a) * vec2 (-1., 1.);
    q.z += 0.5 * wRad;
    d = PrCylDf (q, 0.05, 0.5 * wRad);
    if (d < dMin) { dMin = d;  idObj = idObjGrp + idSpoke; }
  }
  q = p;  sx = sign (q.x);  q.x = abs (q.x);
  q -= vec3 (tw + 0.08, -1.4, 0.);
  aw -= 0.5 * pi * sx; 
  q.yz -= 0.3 * vec2 (cos (aw), - sin (aw));
  d = PrCylDf (q, 0.04, 1.2);
  q.z = abs (q.z);  q -= vec3 (-0.1, 0., 1.1);
  d = min (d, PrCylDf (q.zyx, 0.06, 0.15));
  if (d < dMin) { dMin = d;  idObj = idObjGrp + idCrod; }
  q = p;  q.z = abs (q.z);  q -= vec3 (0., -1.4, 1.1);
  d = PrCylDf (q.zyx, 0.1, tw - 0.1);
  if (d < dMin) { dMin = d;  idObj = idObjGrp + idAxle; }
  q = p;  q -= vec3 (0., 1.1, 2.15);  d = PrCylDf (q.xzy, 0.3, 0.5);
  if (d < dMin) { dMin = d;  idObj = idObjGrp + idFunl; }
  q = p;  q -= vec3 (0., 1.5, 2.15);
  d = max (PrCylDf (q.xzy, 0.4, 0.15), - PrCylDf (q.xzy, 0.3, 0.2));
  q = p;  q -= vec3 (0., 0.8, 0.55);
  d = min (d, PrCapsDf (q.xzy, 0.3, 0.2));
  if (d < dMin) { dMin = d;  idObj = idObjGrp + idFunt; }
  q = p;  q.x = abs (q.x);  q -= vec3 (1., -0.2, 0.85);
  d = PrBoxDf (q, vec3 (0.05, 0.1, 1.8));
  q = p;  q.x = abs (q.x);  q -= vec3 (1., -0.2, -1.75);
  d = min (d, PrBoxDf (q, vec3 (0.05, 0.1, 0.6)));
  q = p;  q.x = abs (q.x);  q -= vec3 (1., -0.2, -3.15);
  d = min (d, PrBoxDf (q, vec3 (0.05, 0.1, 0.3)));
  if (d < dMin) { dMin = d;  idObj = idObjGrp + idStripe; }
  q = p;  q -= vec3 (0., -0.2, 3.5);
  d = PrCylDf (q, 0.2, 0.1);
  if (d < dMin) { dMin = d;  idObj = idObjGrp + idFLamp; }
  q = p;  q.x = abs (q.x) - 0.4;  q -= vec3 (0., -0.7, -3.5);
  d = PrCylDf (q, 0.15, 0.1);
  if (d < dMin) { dMin = d;  idObj = idObjGrp + idBLamp; }
  return dMin;
}

float SceneDf (vec3 p)
{
  vec3 q;
  float dMin, d, db;
  dMin = dstFar;
  db = PrOBox2Df (p.xz, vec2 (0.999 * rgHSize));
  d = max (abs (p.y + 0.001) - 0.001, db);
  if (d < dMin) { dMin = d;  idObj = idGrnd; }
  dMin /= szFac;
  for (int k = 0; k < N_ENG; k ++) {
    q = p;
    q -= pCar[k].xyz;
    q /= szFac;
    d = PrCylDf (q.xzy, 4., 2.2);
    if (d < dMin) {
      q.xz = Rot2D (q.xz, pCar[k].w);
      idObjGrp = (k + 1) * 256;
      dMin = EngDf (q, dMin);
    }
 }
  dMin *= szFac;
  return dMin;
}

float SceneRay (vec3 ro, vec3 rd)
{
  float dHit, d;
  dHit = 0.;
  for (int j = 0; j < 150; j ++) {
    d = SceneDf (ro + dHit * rd);
    dHit += d;
    if (d < 0.0001 || dHit > dstFar) break;
  }
  return dHit;
}

float ObjDf (vec3 p)
{
  float dMin;
  dMin = dstFar;
  dMin = min (dMin, TrackDf (p));
  dMin = min (dMin, SceneDf (p));
  return dMin;
}

vec3 ObjNf (vec3 p)
{
  vec4 v;
  const vec3 e = 0.0001 * vec3 (1., -1., 0.);
  v = vec4 (ObjDf (p + e.xxx), ObjDf (p + e.xyy),
     ObjDf (p + e.yxy), ObjDf (p + e.yyx));
  return normalize (vec3 (v.x - v.y - v.z - v.w) + 2. * v.yzw);
}

vec4 EngCol (vec3 vn)
{
  vec4 objCol;
  int ig, id;
  const vec4 cCol = vec4 (1., 0., 0., 1.);
  vec4 cR = cCol.xyyw, cY = cCol.xxyw, cG = cCol.yxyw, cB = cCol.yyxw,
     cCy = cCol.yxxw;
  vec4 cC[3];
  ig = idObj / 256;  id = idObj - 256 * ig;
  if      (ig == 1) { cC[0] = cG;   cC[1] = cY;   cC[2] = cB;  }
  else if (ig == 2) { cC[0] = cY;   cC[1] = cB;   cC[2] = cR;  }
  else if (ig == 3) { cC[0] = cR;   cC[1] = cCy;  cC[2] = cG;  }
  else if (ig == 4) { cC[0] = cB;   cC[1] = cR;   cC[2] = cCy; }
  else if (ig == 5) { cC[0] = cCy;  cC[1] = cG;   cC[2] = cY;  }
  if (id == idEng || id == idCabin || id == idCoal) objCol = cC[0];
  else if (id == idBase || id == idAxle)
     objCol = vec4 (0.3, 0.2, 0.2, 0.6);
  else if (id == idRoof || id == idCpl || id == idFunl && vn.y <= 0.9)
     objCol = cC[1];
  else if (id == idFunl && vn.y > 0.9) objCol = vec4 (0.03, 0.03, 0.03, 0.1);
  else if (id == idWheel || id == idSpoke) objCol = vec4 (0.6, 0.7, 0.7, 1.);
  else if (id == idCrod) objCol = cY;
  else if (id == idStripe || id == idFunt || id == idBand) objCol = cC[2];
  else if (id == idFLamp) objCol = (mod (tCur + 0.667 * float (ig), 2.) < 1.) ?
     vec4 (1., 1., 1., -1.) : vec4 (0.6, 0.6, 0.6, -1.);
  else if (id == idBLamp) objCol = vec4 (1., 0.6, 0., -1.);
  return objCol;
}

vec4 TrackCol (vec3 ro, vec3 vn)
{
  vec4 objCol;
  if (idObj == idGrnd) objCol = vec4 (bgCol, 0.);
  else if (idObj == idRail) objCol = vec4 (0.7, 0.7, 0.7, 0.8);
  else if (idObj == idVrt) objCol = vec4 (0.5, 0.3, 0., -2.);
  else if (idObj == idHrz) objCol = vec4 (0.5, 0.3, 0., -2.);
  else if (idObj == idLight) objCol = vec4 (1., 1., 0.7, -1.);
  else if (idObj == idTun) {
    if (vn.y > 0.99) objCol = vec4 (mix (vec3 (0.25, 0.25, 0.27),
       vec3 (0.32, 0.32, 0.34), smoothstep (0.6, 0.9, Fbm2 (100. * ro.xz))), -2.);
    else objCol = vec4 (0.4, 0.4, 0.45, -2.);
  }
  return objCol;
}

float ObjShDf (vec3 p)
{
  float dMin;
  dMin = dstFar;
  dMin = min (dMin, SceneDf (p));
  return dMin;
}

float ObjSShadow (vec3 ro, vec3 rd)
{
  float sh, d, h;
  sh = 1.;
  d = 0.02;
  for (int j = 0; j < 5; j ++) {
    h = ObjShDf (ro + rd * d);
    sh = min (sh, smoothstep (0., 1., 20. * h / d));
    d += min (0.05, 3. * h);
    if (h < 0.001) break;
  }
  return sh;
}

vec3 ShowScene (vec3 ro, vec3 rd)
{
  vec4 objCol;
  vec3 qHitT, col, vn, ltPos, ltDir, bmDir, vBm;
  float dstHit, d, sh, att, fs, fa, ltBm;
  int idObjT;
  dstHit = dstFar;
  d = TrackRay (ro, rd);
  if (d < dstHit) dstHit = d;
  idObjT = idObj;
  qHitT = qHit;
  d = SceneRay (ro, rd);
  if (d < dstHit) dstHit = d;
  else {
    idObj = idObjT;
    qHit = qHitT;
  }
  if (dstHit < dstFar) {
    ro += rd * dstHit;
    idObjT = idObj;
    vn = ObjNf (ro);
    idObj = idObjT;
    if (idObj < 256) objCol = TrackCol (ro, vn);
    else objCol = EngCol (vn);
    if (objCol.a == -2.) {
      objCol.a = 0.1;
      if (idObj == idTun) {
        if (vn.y > 0.99) { fs = 50.;  fa = 2.; }
        else { fs = 20.;  fa = 3.;}
      } else if (idObj == idVrt || idObj == idHrz) {
        fs = 100.;  fa = 0.5;
      }
      vn = VaryNf (fs * ro, vn, fa);
    }
    col = objCol.rgb;
#if SHOW_TUN
    if (objCol.a >= 0. && idObj != idGrnd) {
      ltPos.xz = floor (ro.xz) + vec2 (0.5);
      ltPos.y = 0.4;
      ltDir = normalize (ltPos - ro);
      att = 0.2 + 0.8 * smoothstep (0.3, 0.8, pow (abs (ltDir.y), 4.));
      sh = (riding > 0) ? (0.7 + 0.3 * ObjSShadow (ro, vec3 (0., 1., 0.))) : 1.;
      bmDir = vec3 (0., 0., -1.);
      bmDir.xz = Rot2D (bmDir.xz, pVu.w);
      vBm = pVu.xyz - ro;
      ltBm = (riding > 0) ?
         0.4 * smoothstep (0.8, 1., dot (normalize (vBm), bmDir)) *
         (0.1 + 0.9 * (max (dot (vn, bmDir), 0.))) / dot (vBm, vBm) : 0.;
      col = col * (0.2 + ltBm + 0.7 * sh * att * max (max (dot (vn, ltDir), 0.),
         0.5 * max (dot (vn, vec3 (0., 1., 0.)), 0.))) +
         objCol.a * sh * att * pow (max (0., dot (ltDir, reflect (rd, vn))), 64.);
    } else if (idObj == idLight) col *= (0.9 - 0.05 * vn.y);
    if (riding == 0 && idObj != idGrnd) col *= 0.9 +
        0.4 * max (dot (vn, ltExDir), 0.);
#else
    col = col * (0.3 + 0.7 * max (dot (vn, ltExDir), 0.))+
       objCol.a * pow (max (0., dot (ltExDir, reflect (rd, vn))), 64.);
#endif
  } else col = bgCol;
  return clamp (col, 0., 1.);
}

vec3 ShowWg (vec2 uv, vec2 canvas, vec3 col, float fvVar, int riding)
{
  vec4 wgBx[2];
  vec2 ust;
  float asp;
  asp = canvas.x / canvas.y;
  wgBx[0] = vec4 (0.47 * asp, -0.1, 0.012 * asp, 0.15);
  wgBx[1] = vec4 (0.47 * asp, -0.4, 0.022, 0.);
  ust = abs (0.5 * uv - wgBx[0].xy) - wgBx[0].zw;
  if (abs (max (ust.x, ust.y)) * canvas.y < 1.) col = vec3 (0.8);
  ust = 0.5 * uv - wgBx[0].xy;
  ust.y -= (fvVar - 0.5) * 2. * wgBx[0].w;
  if (abs (length (ust) - 0.8 * wgBx[0].z) * canvas.y < 2.)
     col = (fvVar * canvas.y > 5.) ? vec3 (0.1, 1., 0.1) : vec3 (1., 0.1, 0.1);
  if (abs (length (0.5 * uv - wgBx[1].xy) - wgBx[1].z) * canvas.y < 1.5)
     col = (riding > 0) ? vec3 (0.7, 0.7, 0.) : vec3 (0., 0., 1.);
  return col;
}

mat3 StdVuMat (float el, float az)
{
  vec2 ori, ca, sa;
  ori = vec2 (el, az);
  ca = cos (ori);
  sa = sin (ori);
  return mat3 (ca.y, 0., sa.y, 0., 1., 0., - sa.y, 0., ca.y) *
         mat3 (1., 0., 0., 0., ca.x, sa.x, 0., - sa.x, ca.x);
}

void TrSetup ()
{
  vec4 stDat;
  rgHSize = 3.;
  szFac = 0.07;
  trkWid = 0.095;
  tunSize = vec2 (3. * trkWid, 0.25);
  rlSize = vec2 (0.005, 0.01);
  wallThk = 0.01;
  bWid = 3. * wallThk;
  bLen = tunSize.x + bWid;
  stDat = Loadv4 (N_ENG + 1);
  trMov = stDat.x;
  for (int k = 0; k < N_ENG; k ++) {
    stDat = Loadv4 (k);
    pCar[k].xzw = stDat.xzw;
    pCar[k].y = 3. * rlSize.y + 0.15;
  }
}

void mainImage (out vec4 fragColor, in vec2 fragCoord)
{
  vec4 stDat, pc;
  mat3 vuMat;
  vec3 ro, rd, col, u, vd;
  vec2 canvas, uv, uvs;
  float el, az, zmFac, f, t, trVar;
  canvas = iResolution.xy;
  uv = 2. * fragCoord.xy / canvas - 1.;
  uvs = uv;
  uv.x *= canvas.x / canvas.y;
  tCur = iTime;
  dstFar = 30.;
  TrSetup ();
  stDat = Loadv4 (N_ENG + 2);
  riding = int (stDat.x);
  el = stDat.y;
  az = stDat.z;
  trVar = stDat.w;
  if (riding > 0) {
    stDat = Loadv4 (N_ENG);
    pVu = stDat;
    pVu.y = 3. * rlSize.y + 0.15;
    ro = pVu.xyz;
    vuMat = StdVuMat (clamp (0.3 * el, -0.1 * pi, 0.1 * pi), az + pVu.w);
    zmFac = 1.7;
#if SHOW_TUN
  } else if (length (uvs) < 1.5 * SmoothBump (0.2, 0.7, 0.02,
     mod (0.02 * tCur, 1.))) {
#else
  } else if (true) {
#endif
    vuMat = StdVuMat (clamp (el + 0.1 * pi, 0.01 * pi, 0.45 * pi),
       az + 0.01 * pi * tCur);
    ro = vuMat * vec3 (0., 0., -15.);
    zmFac = 8.;
  } else {
    t = floor (mod (0.07 * trMov, float (N_ENG)));
    if (t == 0.)      pc = pCar[0];
    else if (t == 1.) pc = pCar[1];
    else if (t == 2.) pc = pCar[2];
#if N_ENG == 5
    else if (t == 3.) pc = pCar[3];
    else if (t == 4.) pc = pCar[4];
#endif
    ro = vec3 (0., 0.3, -5.);
    vd = normalize (pc.xyz - ro);
    u = - vd.y * vd;
    f = 1. / sqrt (1. - vd.y * vd.y);
    vuMat = mat3 (f * vec3 (vd.z, 0., - vd.x), f * vec3 (u.x, 1. + u.y, u.z), vd);
    zmFac = 6.;
  }
  rd = vuMat * normalize (vec3 (uv, zmFac));
  ltExDir = normalize (vec3 (1., 3., -1.));
  bgCol = (riding > 0) ? vec3 (0.01, 0.01, 0.05) : vec3 (0.05, 0.05, 0.1);
  col = ShowScene (ro, rd);
  col = ShowWg (uv, canvas, col, trVar, riding);
  fragColor = vec4 (col, 1.);
}
