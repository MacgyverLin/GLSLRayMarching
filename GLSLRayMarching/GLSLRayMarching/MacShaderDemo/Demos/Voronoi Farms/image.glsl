// "Voronoi Farms" by dr2 - 2022
// License: Creative Commons Attribution-NonCommercial-ShareAlike 4.0

/*
  Note how the patterns and buildings are aligned relative to
  the ground slope; mousing may be needed fo find bird.

  No. 52 in "Voronoi" series - listed at end
*/

#define AA  0   // (= 0/1) optional antialiasing

#if 0
#define VAR_ZERO min (iFrame, 0)
#else
#define VAR_ZERO 0
#endif

float PrRoundBox2Df (vec2 p, vec2 b, float r);
float PrSphDf (vec3 p, float r);
float PrCapsDf (vec3 p, float r, float h);
float PrConCapsDf (vec3 p, vec2 cs, float r, float h);
vec2 PixToHex (vec2 p);
vec2 HexToPix (vec2 h);
mat3 StdVuMat (float el, float az);
vec2 Rot2D (vec2 q, float a);
vec2 Rot2Cs (vec2 q, vec2 cs);
float Minv2 (vec2 p);
float Maxv2 (vec2 p);
float SmoothMin (float a, float b, float r);
vec3 HsvToRgb (vec3 c);
float Hashfv2 (vec2 p);
vec2 Hashv2v2 (vec2 p);
float Noisefv2 (vec2 p);
float Noisefv3 (vec3 p);
float Fbm2 (vec2 p);
vec3 VaryNf (vec3 p, vec3 n, float f);

struct VVec {
  vec2 d;
  float r;
};
VVec vVec[7];

mat3 flyerMat;
vec4 vVal;
vec3 flyerPos, sunDir, qHit, trkAx, trkFx, trkAy, trkFy;
vec2 gVec[7], hVec[7], ipp, csCen;
float tCur, dstFar, gScale, szFacFl, fGrnd, wngAng, bkAng;
int idObj;
const int nwSeg = 5;
const int idGrnd = 1, idWall = 2, idHut = 3, idTree = 4, idLeaf = 5, idBdy = 6, idTail = 7, 
   idEye = 8, idBk = 9, idWing = 10, idWTip = idWing + nwSeg - 1;
const float pi = 3.1415927, sqrt3 = 1.7320508;

#define DMIN(id) if (d < dMin) { dMin = d;  idObj = id; }
#define DMINQ(id) if (d < dMin) { dMin = d;  idObj = id;  qHit = q; }

float ObjDf (vec3 p)
{  // (from "Painted Bird")
  vec3 q;
  float wSeg, wChord, wSpar, fTap, bkLen, dMin, d, a, wr, wf, ws, ww;
  wSeg = 0.15;
  wChord = 0.3;
  wSpar = 0.02;
  fTap = 8.;
  bkLen = 0.2;
  dMin = dstFar / szFacFl;
  p = flyerMat * (p - flyerPos) / szFacFl;
  q = p;
  q.z -= 0.5;
  q.x = abs (q.x) - 0.1;
  a = wngAng;
  wf = 1.;
  ws = 0.02 * wChord;
  for (int k = 0; k < nwSeg; k ++) {
    q.xy = Rot2D (q.xy, a);
    q.x -= wSeg;
    wr = wf * (1. - 0.5 * q.x / (fTap * wSeg));
    ww = ws - 0.01 * (q.z / wChord) * (q.z / wChord);
    q.z += 0.4 * wr * wChord;
    if (k < nwSeg - 1) {
      d = length (max (abs (vec3 (q.xz, q.y - 0.5 * ww).xzy) - vec3 (wSeg, ww, wr * wChord),
         0.)) - wr * wSpar;
      q.x -= wSeg;
      DMINQ (idWing + k);
    } else {
      q.x += wSeg;
      d = max (length (abs (max (vec2 (length (q.xz) - wr * wChord,
         abs (q.y - 0.5 * ww) - ww), 0.))) - wr * wSpar, - q.x);
      DMINQ (idWTip);
    }
    q.z -= 0.4 * wr * wChord;
    a *= 1.03;
    wf *= (1. - 1. / fTap);
    ws *= 0.8 * (1. - 1. / fTap);
  }
  q = p;
  wr = q.z - 0.5;
  if (wr > 0.) {
    wr = 0.17 - 0.44 * wr * wr;
  } else {
    wr = clamp (0.667 * wr, -1., 1.);
    wr *= wr;
    wr = 0.17 - wr * (0.34 - 0.18 * wr); 
  }
  d = PrCapsDf (q, wr, 1.);
  DMINQ (idBdy);
  q = p;
  q.x = abs (q.x);
  wr = (q.z + 1.) * (q.z + 1.);
  q -= vec3 (0.3 * wr, 0.1 * wr, -1.2);
  d = PrCapsDf (q, 0.009, 0.2);
  DMINQ (idTail);
  q = p;
  q.x = abs (q.x);
  q -= vec3 (0.07, 0.05, 0.9);
  d = PrSphDf (q, 0.04);
  DMINQ (idEye);
  q = p;
  q -= vec3 (0., -0.015, 1.15);
  q.yz = Rot2D (vec2 (abs (q.y), q.z + 0.8 * bkLen), bkAng);
  q.z -= 0.8 * bkLen;
  wr = clamp (0.4 - 0.3 * q.z / bkLen, 0., 1.);
  d = max (abs (length (max (abs (q) - vec3 (0., 0.25 * wr * bkLen, bkLen), 0.)) -
     0.25 * wr * bkLen) - 0.002, - q.y);
  DMINQ (idBk);
  return 0.8 * szFacFl * dMin;
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
  vec2 e = vec2 (0.001, -0.001);
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
  for (int j = VAR_ZERO; j < 24; j ++) {
    h = ObjDf (ro + d * rd);
    sh = min (sh, smoothstep (0., 0.01 * d, h));
    d += h;
    if (sh < 0.05) break;
  }
  return 0.6 + 0.4 * sh;
}

vec4 ObjCol ()
{
  vec3 col, c1, c2, c3;
  float a, r, s, t, sx, spec;
  spec = 0.2;
  c1 = vec3 (0.9, 0.8, 0.8);
  c2 = vec3 (0.3, 0.3, 0.8);
  c3 = vec3 (0.1, 0.3, 0.1);
  if (idObj == idEye) {
    col = vec3 (0., 0., 1.);
    spec = -1.;
  } else if (idObj == idBdy || idObj == idTail) {
    a = atan (abs (qHit.x), qHit.y) / pi;
    col = mix (c3, mix (c1, c2, smoothstep (0.5, 0.7, a)), smoothstep (0.1, 0.3, a));
    if (idObj == idBdy && qHit.z > 0. && length (max (abs (vec2 (qHit.x, qHit.y + 0.017)) -
       vec2 (0., 0.035), 0.)) < 0.025) col = vec3 (1., 0.7, 0.2);
  } else if (idObj == idBk) {
    col = vec3 (0.9, 0.4, 0.1);
  } else if (idObj >= idWing && idObj <= idWTip) {
    col = (qHit.y > -0.006) ? c3 : c2;
    t = 0.3 * float (idObj - idWing);
    sx = 6.66 * qHit.x - 0.52;
    if (idObj < idWTip || idObj == idWTip && qHit.x < 0.075) col = mix (col, c1, smoothstep (0.,
       0.01, qHit.z - 0.54 * (abs (cos (pi * sx)) - 0.5) * (1. - 0.4 * t)));
    r = (length (qHit.xz) - 0.165);
    a = atan (qHit.z, - qHit.x) / (2. * pi) + 0.5;
    t = 0.11 * (qHit.x + t) - 0.29;
    s = (idObj < idWTip) ? step (0., qHit.z + t) * (1. - smoothstep (0.1, 0.2, fract (8. * sx))) :
       step (0.021, r) * smoothstep (0.8, 0.9, fract (64. * a));
    col *= 1. - 0.2 * s;
    s = (idObj == idWTip) ? smoothstep (0., 0.005, r) * (1. - smoothstep (0.3, 0.4, fract (32. * a))) :
       (1. - smoothstep (0.01, 0.016, qHit.z - t)) * smoothstep (0.6, 0.7, fract (4. * sx));
    col = mix (col, c1, s);
  }
  return vec4 (col, spec);
}

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

void SetVorp (vec2 ip)
{
  vec2 u;
  ipp = ip;
  for (int k = VAR_ZERO; k < 7; k ++) {
    u = Hashv2v2 (ip + gVec[k]);
    vVec[k].d = hVec[k] + 0.5 * (0.4 + 0.6 * u.x) * sin (2. * pi * (u.y - 0.5) +
       vec2 (0.5 * pi, 0.));
    vVec[k].r = Hashfv2 (u);
  }
}

vec4 HexVor (vec2 fp)
{
  vec4 sd;
  vec2 d, dm;
  float r;
  sd = vec4 (4.);
  dm = vec2 (4.);
  for (int k = VAR_ZERO; k < 7; k ++) {
    d = vVec[k].d - fp;
    sd.w = dot (d, d);
    if (sd.w < sd.x) {
      sd = sd.wxyw;
      dm = d;
      r = vVec[k].r;
    } else sd = (sd.w < sd.y) ? sd.xwyw : ((sd.w < sd.z) ? sd.xyww : sd);
  }
  sd.xyz = sqrt (sd.xyz);
  return vec4 (SmoothMin (sd.y, sd.z, 0.05) - sd.x, dm, r);
}

float GrndHt (vec2 p)
{
  float f, a, aSum;
  p *= 0.01;
  f = 0.;
  a = 1.;
  aSum = 0.;
  for (int j = 0; j < 3; j ++) {
    f += a * Noisefv2 (p);
    aSum += a;
    a *= 0.4;
    p *= 2.5;
  }
  return 40. * f / aSum;
}

float VObjDf (vec3 p)
{
  vec3 q;
  vec2 u, pCen, pp, ip;
  float dMin, d, db, h;
  dMin = dstFar;
  pp = p.xz / gScale;
  ip = PixToHex (pp);
  if (ipp != ip) SetVorp (ip);
  vVal = HexVor (pp - HexToPix (ip));
  pCen = (pp + vVal.yz) * gScale;
  h = GrndHt (pCen);
  u = vec2 (GrndHt (pCen + vec2 (0., 0.1)), GrndHt (pCen + vec2 (0.1, 0.))) - h;
  csCen = sin (atan (u.y, u.x) + vec2 (0.5 * pi, 0.));
  q = p;
  q.y -= GrndHt (p.xz);
  d = q.y;
  DMIN (idGrnd);
  d = length (max (abs (vec2 (abs (vVal.x - 0.1), abs (q.y - 0.15))) -
     vec2 (0., 0.15), 0.)) - 0.03;
  DMIN (idWall);
  q = p;
  q -= vec3 (pCen, h).xzy;
  q.xz = Rot2Cs (q.xz, csCen);
  d = max (PrRoundBox2Df (q.xz, vec2 (0.4, 0.2), 0.05), dot (vec2 (q.y, - abs (q.z)),
     sin (-0.25 * pi + vec2 (0.5 * pi, 0.))) - 0.5);
  DMINQ (idHut);
  q.xz -= vec2 (sign (vVal.w - 0.5), 0.7);
  d = max (length (q.xz) - 0.07, q.y - 1.);
  DMINQ (idTree);
  d = PrConCapsDf ((q - vec3 (0., 1., 0.)).xzy, sin (0.08 * pi + vec2 (0.5 * pi, 0.)), 0.17, 0.3);
  DMINQ (idLeaf);
  return 0.8 * dMin;
}

float VObjRay (vec3 ro, vec3 rd)
{
  vec3 p;
  float dHit, d;
  dHit = 0.;
  for (int j = VAR_ZERO; j < 160; j ++) {
    p = ro + dHit * rd;
    d = VObjDf (p);
    if (d < 0.001 || dHit > dstFar) break;
    dHit += d;
  }
  return dHit;
}

vec3 VObjNf (vec3 p)
{
  vec4 v;
  vec2 e;
  e = vec2 (0.001, -0.001);
  for (int j = VAR_ZERO; j < 4; j ++) {
    v[j] = VObjDf (p + ((j < 2) ? ((j == 0) ? e.xxx : e.xyy) : ((j == 2) ? e.yxy : e.yyx)));
  }
  v.x = - v.x;
  return normalize (2. * v.yzw - dot (v, vec4 (1.)));
}

float VObjSShadow (vec3 ro, vec3 rd)
{
  float sh, d, h;
  sh = 1.;
  d = 0.02;
  for (int j = VAR_ZERO; j < 24; j ++) {
    h = VObjDf (ro + d * rd);
    sh = min (sh, smoothstep (0., 0.01 * d, h));
    d += h;
    if (sh < 0.05) break;
  }
  return 0.6 + 0.4 * sh;
}

vec3 SkyCol (vec3 rd)
{
  rd.y = abs (rd.y);
  return mix (vec3 (0.3, 0.35, 0.7), vec3 (0.8, 0.8, 0.8),
     clamp (2. * (Fbm2 (2. * rd.xz / rd.y + 0.1 * tCur) - 0.1) * rd.y, 0., 1.));
}

vec3 ShowScene (vec3 ro, vec3 rd)
{
  vec4 col4;
  vec3 col, vn, qHitT;
  vec2 vf, u;
  float dstObj, dstObjF, sh, f, nDotL;
  int idObjT;
  wngAng = -0.03 * pi * (1. + 2. * cos (pi * tCur));
  bkAng = 0.02 * pi * (1. + sin (3. * pi * tCur));
  HexVorInit ();
  ipp = vec2 (-999.);
  vf = vec2 (0.);
  dstObjF = ObjRay (ro, rd);
  idObjT = idObj;
  qHitT = qHit;
  dstObj = VObjRay (ro, rd);
  sh = 1.;
  if (dstObj < min (dstObjF, dstFar)) {
    ro += dstObj * rd;
    vn = VObjNf (ro);
    f = smoothstep (0.2, 0.4, dstObj / dstFar);
    if (idObj == idWall) {
      col4 = vec4 (0.7, 0.7, 0.75, 0.) * mix (0.85 + 0.15 * smoothstep (0.4, 0.5,
         Noisefv3 (16. * vec3 (1., 1., 2.) * ro.xzy)), 0.9, f);
      vf = vec2 (16., 8.);
    } else if (idObj == idGrnd) {
      if (vVal.x < 0.1) {
        col4 = vec4 (1., 1., 0.5, 0.) * mix (0.7 + 0.3 * Fbm2 (32. * ro.xz), 0.75, f);
        vf = vec2 (32., 1.);
      } else {
        u = Rot2Cs (vVal.yz * gScale, csCen);
        if (min (PrRoundBox2Df (u, vec2 (0.4, 0.2) - 0.02, 0.02),
           length (u + vec2 (sign (vVal.w - 0.5), 0.7))) < 0.12) {
          col4 = vec4 (0.7, 0.7, 0.6, 0.) * (0.5 + 0.5 * Fbm2 (128. * ro.xz));
          vf = vec2 (32., 1.);
        } else {
          col4 = vec4 (HsvToRgb (vec3 (0.15 + 0.25 * vVal.w, 0.9, 1.)), 0.);
          col4 *= mix (0.85 + 0.15 * sin (fGrnd * dot (ro.zx, csCen)), 0.92,
             max (f, 1. - smoothstep (0.2, 0.3, - dot (rd, vn))));
          vf = vec2 (8., 2.);
        }
      }
    } else if (idObj == idHut) {
      col4 = vec4 (HsvToRgb (vec3 (mod (0.9 + 0.25 * vVal.w, 1.), 0.8, 1.)), 0.1);
      if (vn.y < 0.01) col4 = mix (vec4 (0.8, 0.7, 0., -1.), col4, smoothstep (0., 0.01,
         PrRoundBox2Df (vec2 (((abs (qHit.x) < 2. * abs (qHit.z)) ? abs (qHit.x) - 0.18 : qHit.z),
         qHit.y - 0.25), vec2 (0.1, 0.07), 0.01)));
      else col4.rgb = mix (col4.rgb, vec3 (1.), 0.5);
      vf = vec2 (32., 0.1);
    } else if (idObj == idTree) {
      col4 = vec4 (0.6, 0.2, 0., 0.);
      vf = vec2 (32., 0.5);
    } else if (idObj == idLeaf) {
      col4 = vec4 (HsvToRgb (vec3 (0.2 + 0.15 * (1. - vVal.w), 1., 0.8)), 0.);
      vf = vec2 (16., 4.);
    }
    sh = VObjSShadow (ro + 0.01 * vn, sunDir);
    sh = min (sh, 0.6 + 0.4 * smoothstep (0., 0.2, Fbm2 (0.04 * ro.xz - 0.05 * tCur) - 0.4));
    if (vf.x > 0.) vn = VaryNf (vf.x * ro, vn, vf.y * (1. - f));
    nDotL = max (dot (vn, sunDir), 0.);
  } else if (dstObjF < dstFar) {
    dstObj = dstObjF;
    ro += dstObj * rd;
    vn = ObjNf (ro);
    nDotL = max (dot (vn, sunDir), 0.);
    nDotL *= nDotL;
    idObj = idObjT;
    qHit = qHitT;
    col4 = ObjCol ();
    sh = ObjSShadow (ro + 0.01 * vn, sunDir);
  } else col = SkyCol (rd);
  if (dstObj < dstFar) {
    if (col4.a >= 0.) col = col4.rgb * (0.3 + 0.7 * sh * nDotL) +
       col4.a * step (0.95, sh) * sh * pow (max (dot (reflect (sunDir, vn), rd), 0.), 32.);
    else col = col4.rgb * (0.2 + 0.8 * max (- dot (rd, vn), 0.));
    col = mix (col, SkyCol (rd), smoothstep (0.8, 1., dstObj / dstFar));
  }
  return clamp (col, 0., 1.);
}

vec3 TrackPath (float t)
{
  return vec3 (dot (trkAx, sin (trkFx * t)), abs (dot (trkAy, sin (trkFy * t))), t);
}

vec3 TrackDir (float t)
{
  return vec3 (dot (trkFx * trkAx, cos (trkFx * t)), dot (trkFy * trkAy, cos (trkFy * t)), 1.);
}

vec3 TrackAcc (float t)
{
  return vec3 (dot (trkFx * trkFx * trkAx, - sin (trkFx * t)), 0., 0.);
}

void FlyerPM (float t, float vu, out vec3 flPos, out mat3 flMat)
{
  vec3 vel, va, ori, ca, sa;
  float el, az, rl;
  flPos = TrackPath (t);
  vel = TrackDir (t);
  el = (vu != 0.) ? 0. : -0.2 * sign (vu);
  el -= ((vu == 0.) ? 1. : 0.3) * asin (vel.y / length (vel));
  az = atan (vel.z, vel.x) - 0.5 * pi;
  va = cross (TrackAcc (t), vel) / length (vel);
  rl = ((vu == 0.) ? 10. : 3.) * length (va) * sign (va.y);
  if (vu < 0.) {
    el *= -1.;
    rl *= -1.;
    az += pi;
  }
  ori = vec3 (el, az, rl);
  ca = cos (ori);
  sa = sin (ori);
  flMat = mat3 (ca.z, - sa.z, 0., sa.z, ca.z, 0., 0., 0., 1.) *
          mat3 (1., 0., 0., 0., ca.x, - sa.x, 0., sa.x, ca.x) *
          mat3 (ca.y, 0., - sa.y, 0., 1., 0., sa.y, 0., ca.y);
}

#define N_WIN  2

void mainImage (out vec4 fragColor, in vec2 fragCoord)
{
  mat3 vuMat, vuOrMat;
  vec4 mPtr, dateCur;
  vec3 ro, rd, col, vd;
  vec2 canvas, uv, uvv, mMid[N_WIN], ut[N_WIN], mSize, msw;
  float az, el, asp, zmFac, vel, sr, dir;
  int vuId, regId;
  canvas = iResolution.xy;
  uv = 2. * fragCoord.xy / canvas - 1.;
  uv.x *= canvas.x / canvas.y;
  tCur = iTime;
  dateCur = iDate;
  mPtr = iMouse;
  mPtr.xy = mPtr.xy / canvas - 0.5;
  tCur = mod (tCur, 600.);// + 1.1 * floor (dateCur.w / 3600.);
  asp = canvas.x / canvas.y;
  mSize = (1./4.5) * vec2 (asp, 1.);
  mMid[0] = (1. - mSize.y) * vec2 (- asp, -1.);
  mMid[1] = (1. - mSize.y) * vec2 (asp, -1.);
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
  fGrnd = (vuId == 0) ? 32. : 12.;
  if (regId > 0 && (vuId == 0 || vuId == regId)) vuId = regId - vuId;
  szFacFl = 0.3;
  gScale = 4.;
  trkAx = 8. * vec3 (1.9, 2.9, 4.3);
  trkFx = 0.15 * vec3 (0.23, 0.17, 0.13);
  trkAy = 0.2 * vec3 (1.7, 3.7, 0.);
  trkFy = 0.1 * vec3 (0.21, 0.15, 0.);
  vel = 1.5;
  FlyerPM (vel * tCur, 0., flyerPos, flyerMat);
  flyerPos.y += 10. + GrndHt (flyerPos.xz);
  dir = (vuId == 0) ? 1. : -1.;
  FlyerPM (vel * tCur - 2. * dir, dir, ro, vuOrMat);
  ro.y += 10. + GrndHt (ro.xz);
  if (vuId != 2) {
    az = 0.;
    el = -0.1 * pi;
    if (mPtr.z > 0. && vuId == regId) {
      az += 2. * pi * msw.x;
      el += 0.5 * pi * msw.y;
    }
    el = clamp (el, -0.4 * pi, 0.4 * pi);
    zmFac = 3.;
  } else {
    vd = flyerPos - ro;
    az = 0.5 * pi + atan (- vd.z, vd.x);
    el = asin (vd.y / length (vd));
    zmFac = 4.;
    if (mPtr.z > 0. && vuId == regId) {
      az += 0.2 * pi * msw.x;
      el += 0.2 * pi * msw.y;
    }
  }
  vuMat = StdVuMat (el, az);
  sunDir = normalize (vec3 (0., 2., -1.));
  sunDir.xz = Rot2D (sunDir.xz, 0.3 * pi * sin (2. * pi * 0.01 * tCur));
  if (dir < 0.) sunDir.xz *= -1.;
  dstFar = 40. * gScale;
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
    rd = normalize (vec3 (2. * tan (0.5 * atan (uvv.x / asp)) * asp, uvv.y, 1.));
    rd = vuMat * rd;
    if (vuId != 2) rd = rd * vuOrMat;
    col += (1. / naa) * ShowScene (ro, rd);
  }
  for (int k = 0; k < N_WIN; k ++) {
    if (Maxv2 (ut[k]) < 0. && Minv2 (abs (ut[k])) * canvas.y < 3.) col = vec3 (0.8, 0.3, 0.3);
  }
  fragColor = vec4 (col, 1.);
}

float PrRoundBox2Df (vec2 p, vec2 b, float r)
{
  return length (max (abs (p) - b, 0.)) - r;
}

float PrSphDf (vec3 p, float r)
{
  return length (p) - r;
}

float PrCapsDf (vec3 p, float r, float h)
{
  return length (p - vec3 (0., 0., clamp (p.z, - h, h))) - r;
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

float Minv2 (vec2 p)
{
  return min (p.x, p.y);
}

float Maxv2 (vec2 p)
{
  return max (p.x, p.y);
}

float SmoothMin (float a, float b, float r)
{
  float h;
  h = clamp (0.5 + 0.5 * (b - a) / r, 0., 1.);
  return mix (b - h * r, a, h);
}

vec3 HsvToRgb (vec3 c)
{
  return c.z * mix (vec3 (1.), clamp (abs (fract (c.xxx + vec3 (1., 2./3., 1./3.)) * 6. -
     3.) - 1., 0., 1.), c.y);
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

/*
 "Voronoi" series:
   "Rainbow Cavern"                  (XsfBWM)
   "Honeycomb Voronoi"               (XsXfDX)
   "Desert Town"                     (XslBDl)
   "Smoothed Honeycomb Voronoi"      (4dsBWl)
   "Smoothed Voronoi Landscape"      (lsffWs)
   "Smoothed Voronoi Tunnel"         (4slfWl)
   "Island Flight"                   (XdBBRR)
   "Voronoi Rocks"                   (ldSBzz)
   "Voronoi Towers"                  (XdBBRh)
   "Chocolate Dominoes"              (ldBfz1)
   "Voronoi of the Week"             (lsjBz1)
   "Arctic Patrol"                   (lsBfzy)
   "Twisted Time"                    (XlsyWH)
   "White Folly"                     (ll2cDG)
   "White Folly 2"                   (ltXfzr)
   "Lightweight Lighthouse"          (XtfBz4)
   "Magic Tree 2"                    (MllBzH)
   "Succulent Forest"                (MlsBzN)
   "Voronoi Vegetation"              (XtlfRM)
   "Backlit Lighthouse"              (4lfBWB)
   "Lighthouse with Ship"            (MtSBR1)
   "Into the Woods"                  (Mddczn)
   "Rock Garden"                     (XdccWn)
   "One-Pass Voronoi"                (Xsyczh)
   "Book of the Woods"               (XsVyRw)
   "Metallic Polyhedron"             (lsGcWm)
   "Scrolling Texture Heightmap"     (MdGBWz)
   "River Flight 2"                  (4l3cz8)
   "Penguins Can't Fly"              (ltVyzh)
   "One-Pass Voronoi with Spirals"   (tsfXDl)
   "Voronoi Comparison"              (WsSXzz)
   "Varying Mesh"                    (tlfXWH)
   "Riding the Textured Tunnel"      (WdVXzD)
   "Dynamic Space Rocks"             (WsGSzt)
   "Planet Reboot"                   (wldGD8)
   "Caged Kryptonite"                (3ltSDn)
   "Cave Dolphins"                   (wdSyRD)
   "Big Momavirus"                   (Wd2yzm)
   "Channeling Marbles"              (wtfcRr)
   "Gliders Over Voropolis"          (WdKcz1)
   "Balls In Motion"                 (WdGBRG)
   "Wobbly Blob 2"                   (tsGfzV)
   "Floppy Column"                   (wtccR4)
   "Soup Can Dynamics"               (3tKyRt)
   "Dolphin Orb"                     (sdBXRD)
   "Channeling Slime"                (NdSSR3)
   "Flaming Asteroids"               (NtSGzt)
   "Mesh Dome"                       (ssKXRt)
   "Melange"                         (slKXD3)
   "Voronoi Farms"                   (cdjSz1)
*/
