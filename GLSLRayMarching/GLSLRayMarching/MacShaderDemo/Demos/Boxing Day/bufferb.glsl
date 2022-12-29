// "Boxing Day" by dr2 - 2017
// License: Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License

vec4 QtMul (vec4 q1, vec4 q2);
mat3 QtToRMat (vec4 q);
vec4 RMatToQt (mat3 m);
vec4 EulToQt (vec3 e);
mat3 LpStepMat (vec3 a);
float Hashff (float p);
float Noisefv2 (vec2 p);
vec4 Loadv4 (int idVar);
void Savev4 (int idVar, vec4 val, inout vec4 fCol, vec2 fCoord);

const int nBlock = 64, nSiteBk = 27;
const vec3 blkSph = vec3 (3.), blkGap = vec3 (0.4);
const float pi = 3.14159;
const float txRow = 128.;
vec3 rLead;
float todCur;

float GrndHt (vec2 p)
{
  mat2 fqRot;
  vec2 q;
  float h, a;
  fqRot = 2. * mat2 (0.6, -0.8, 0.8, 0.6);
  q = 0.03 * p;
  h = 0.;
  a = 10.;
  for (int j = 0; j < 5; j ++) {
    h += a * Noisefv2 (q);
    a *= 0.5;
    q *= fqRot;
  }
  return h;
}

vec3 GrndNf (vec3 p)
{
  const vec2 e = vec2 (0.01, 0.);
  return normalize (vec3 (GrndHt (p.xz) - vec2 (GrndHt (p.xz + e.xy), GrndHt (p.xz + e.yx)), e.x).xzy);
}

vec3 RSite (int sId)
{
  float sIdf;
  sIdf = float (sId);
  return blkGap * (floor (vec3 (mod (sIdf, blkSph.x),
     mod (sIdf, blkSph.x * blkSph.y) / blkSph.x,
     sIdf / (blkSph.x * blkSph.y))) - 0.5 * (blkSph - 1.));
}

vec3 FcFun (vec3 dr, float rSep, vec3 dv)
{
  vec3 f;
  float vRel, fo, drv;
  const float fOvlap = 1000., fricN = 1., fricT = 1., fricS = 2.;
  fo = fOvlap * (1. / rSep - 1.);
  drv = dot (dr, dv) / (rSep * rSep);
  dv -= drv * dr;
  vRel = length (dv);
  fo = max (fo - fricN * drv, 0.);
  f = fo * dr;
  if (vRel > 0.001) f -= min (fricT, fricS * abs (fo) * rSep / vRel) * dv;
  return f;
}

void Step (int mId, out vec3 rm, out vec3 vm, out vec4 qm, out vec3 wm)
{
  mat3 mRot, mRotN;
  vec3 rmN, vmN, wmN, dr, dv, rts, rtsN, rms, vms, fc, am, wam, dSp;
  float farSep, rSep, grav, fDamp, fAttr, dt;
  const vec2 e = vec2 (0.1, 0.);
  grav = 5.;
  fDamp = 0.1;
  fAttr = 0.1;
  dt = 0.01;
  rm = Loadv4 (4 * mId).xyz;
  vm = Loadv4 (4 * mId + 1).xyz;
  qm = Loadv4 (4 * mId + 2);
  wm = Loadv4 (4 * mId + 3).xyz;
  mRot = QtToRMat (qm);
  farSep = length (blkGap * (blkSph - 1.)) + 1.;
  am = vec3 (0.);
  wam = vec3 (0.);
  for (int n = 0; n < nBlock; n ++) {
    rmN = Loadv4 (4 * n).xyz;
    if (n != mId && length (rm - rmN) < farSep) {
      vmN = Loadv4 (4 * n + 1).xyz;
      mRotN = QtToRMat (Loadv4 (4 * n + 2));
      wmN = Loadv4 (4 * n + 3).xyz;
      for (int j = 0; j < nSiteBk; j ++) {
        rts = mRot * RSite (j);
        rms = rm + rts;
        vms = vm + cross (wm, rts);
        dv = vms - vmN;
        fc = vec3 (0.);
        for (int jN = 0; jN < nSiteBk; jN ++) {
          rtsN = mRotN * RSite (jN);
          dr = rms - (rmN + rtsN);
          rSep = length (dr);
          if (rSep < 1.) fc += FcFun (dr, rSep, dv - cross (wmN, rtsN));
        }
        am += fc;
        wam += cross (rts, fc);
      }
    }
  }
  for (int j = 0; j < nSiteBk; j ++) {
    rts = mRot * RSite (j);
    dr = rm + rts;
    dr.xz = -0.55 * GrndNf (dr).xz;
    dr.y += 0.55 - GrndHt (rm.xz - dr.xz);
    rSep = length (dr);
    if (rSep < 1.) {
      fc = FcFun (dr, rSep, vm + cross (wm, rts));
      am += fc;
      wam += cross (rts, fc);
    }
  }
  am -= fDamp * vm;
  am.y -= grav;
  am += fAttr * (rLead - rm);
  dSp = blkGap * blkSph;
  wam = mRot * (wam * mRot / (0.25 * (vec3 (dot (dSp, dSp)) - dSp * dSp) + 1.));
  vm += dt * am;
  rm += dt * vm;
  wm += dt * wam;
  qm = normalize (QtMul (RMatToQt (LpStepMat (0.5 * dt * wm)), qm));
}

void Init (int mId, out vec3 rm, out vec3 vm, out vec4 qm, out vec3 wm)
{
  float mIdf, nbEdge;
  mIdf = float (mId);
  nbEdge = floor (sqrt (float (nBlock)) + 0.1);
  rm.xz = 4. * (floor (vec2 (mod (mIdf, nbEdge), mIdf / nbEdge)) -
     0.5 * (nbEdge - 1.)) + 64. * Hashff (todCur);
  rm.y = GrndHt (rm.xz) + 0.5 * blkSph.y + 3.;
  vm = 2. * normalize (vec3 (Hashff (mIdf + todCur), Hashff (mIdf + todCur + 0.3),
     Hashff (mIdf + todCur + 0.6)) - 0.5);
  qm = EulToQt (normalize (vec3 (Hashff (mIdf), Hashff (mIdf + 0.3), Hashff (mIdf + 0.6))));
  wm = vec3 (0.);
}

void mainImage (out vec4 fragColor, in vec2 fragCoord)
{
  vec4 stDat, p, qm;
  vec3 rm, vm, wm, rMid;
  vec2 iFrag;
  float nStep;
  int mId, pxId, kp;
  bool doInit;
  iFrag = floor (fragCoord);
  pxId = int (iFrag.x + txRow * iFrag.y);
  if (iFrag.x >= txRow || pxId >= 4 * nBlock + 2) discard;
  todCur = iDate.w;
  mId = (pxId < 4 * nBlock) ? pxId / 4 : -1;
  if (iFrame <= 5) {
    doInit = true;
  } else {
    doInit = false;
    stDat = Loadv4 (4 * nBlock);
    nStep = stDat.w;
    ++ nStep;
    rLead = Loadv4 (4 * nBlock + 1).xyz;
    rLead += vec3 (0., 0., 0.05);
    rLead.y = GrndHt (rLead.xz) + 0.1;
    if (mId >= 0) Step (mId, rm, vm, qm, wm);
  }
  if (doInit) {
    nStep = 0.;
    if (mId >= 0) Init (mId, rm, vm, qm, wm);
  }
  if (pxId == 4 * nBlock) {
    rMid = vec3 (0.);
    for (int n = 0; n < nBlock; n ++) rMid += Loadv4 (4 * n).xyz;
    rMid /= float (nBlock);
  }
  if (pxId < 4 * nBlock) {
    kp = 4 * mId;
    if      (pxId == kp + 0) p = vec4 (rm, 0.);
    else if (pxId == kp + 1) p = vec4 (vm, 0.);
    else if (pxId == kp + 2) p = qm;
    else if (pxId == kp + 3) p = vec4 (wm, 0.);
    stDat = p;
  } else {
    kp = 4 * nBlock;
    if      (pxId == kp + 0) stDat = vec4 (rMid, nStep);
    else if (pxId == kp + 1) stDat = vec4 (rLead, 0.);
  }
  Savev4 (pxId, stDat, fragColor, fragCoord);
}

vec4 QtMul (vec4 q1, vec4 q2)
{
  return vec4 (
       q1.w * q2.x - q1.z * q2.y + q1.y * q2.z + q1.x * q2.w,
       q1.z * q2.x + q1.w * q2.y - q1.x * q2.z + q1.y * q2.w,
     - q1.y * q2.x + q1.x * q2.y + q1.w * q2.z + q1.z * q2.w,
     - q1.x * q2.x - q1.y * q2.y - q1.z * q2.z + q1.w * q2.w);
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

vec4 RMatToQt (mat3 m)
{
  vec4 q;
  const float tol = 1e-6;
  q.w = 0.5 * sqrt (max (1. + m[0][0] + m[1][1] + m[2][2], 0.));
  if (abs (q.w) > tol) q.xyz =
     vec3 (m[1][2] - m[2][1], m[2][0] - m[0][2], m[0][1] - m[1][0]) / (4. * q.w);
  else {
    q.x = sqrt (max (0.5 * (1. + m[0][0]), 0.));
    if (abs (q.x) > tol) q.yz = vec2 (m[0][1], m[0][2]) / q.x;
    else {
      q.y = sqrt (max (0.5 * (1. + m[1][1]), 0.));
      if (abs (q.y) > tol) q.z = m[1][2] / q.y;
      else q.z = 1.;
    }
  }
  return normalize (q);
}

vec4 EulToQt (vec3 e)
{
  float a1, a2, a3, c1, s1;
  a1 = 0.5 * e.y;  a2 = 0.5 * (e.x - e.z);  a3 = 0.5 * (e.x + e.z);
  s1 = sin (a1);  c1 = cos (a1);
  return normalize (vec4 (s1 * cos (a2), s1 * sin (a2), c1 * sin (a3),
     c1 * cos (a3)));
}

mat3 LpStepMat (vec3 a)
{
  mat3 m1, m2;
  vec3 t, c, s;
  float b1, b2;
  t = 0.25 * a * a;
  c = (1. - t) / (1. + t);
  s = a / (1. + t);
  m1[0][0] = c.y * c.z;  m2[0][0] = c.y * c.z;
  b1 = s.x * s.y * c.z;  b2 = c.x * s.z;
  m1[0][1] = b1 + b2;  m2[1][0] = b1 - b2;
  b1 = c.x * s.y * c.z;  b2 = s.x * s.z;
  m1[0][2] = - b1 + b2;  m2[2][0] = b1 + b2;
  b1 = c.y * s.z;
  m1[1][0] = - b1;  m2[0][1] = b1;  
  b1 = s.x * s.y * s.z;  b2 = c.x * c.z;
  m1[1][1] = - b1 + b2;  m2[1][1] = b1 + b2; 
  b1 = c.x * s.y * s.z;  b2 = s.x * c.z;
  m1[1][2] = b1 + b2;  m2[2][1] = b1 - b2;
  m1[2][0] = s.y;  m2[0][2] = - s.y;
  b1 = s.x * c.y;
  m1[2][1] = - b1;  m2[1][2] = b1;
  b1 = c.x * c.y;
  m1[2][2] = b1;  m2[2][2] = b1;
  return m1 * m2;
}

const float cHashM = 43758.54;

float Hashff (float p)
{
  return fract (sin (p) * cHashM);
}

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

#define txBuf iChannel0
#define txSize iChannelResolution[0].xy

vec4 Loadv4 (int idVar)
{
  float fi;
  fi = float (idVar);
  return texture (txBuf, (vec2 (mod (fi, txRow), floor (fi / txRow)) + 0.5) /
     txSize);
}

void Savev4 (int idVar, vec4 val, inout vec4 fCol, vec2 fCoord)
{
  vec2 d;
  float fi;
  fi = float (idVar);
  d = abs (fCoord - vec2 (mod (fi, txRow), floor (fi / txRow)) - 0.5);
  if (max (d.x, d.y) < 0.5) fCol = val;
}
