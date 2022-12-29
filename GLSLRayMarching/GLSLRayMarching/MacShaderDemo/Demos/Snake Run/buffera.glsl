// "Snake Run" by dr2 - 2017
// License: Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License

vec4 QtMul (vec4 q1, vec4 q2);
vec4 RMatToQt (mat3 m);
mat3 LpStepMat (vec3 a);
float SmoothMax (float a, float b, float r);
vec2 Rot2D (vec2 q, float a);
float Hashff (float p);
float Fbm2 (vec2 p);
vec4 Loadv4 (int idVar);
void Savev4 (int idVar, vec4 val, inout vec4 fCol, vec2 fCoord);

const int nChain = 3, lenChain = 50, nBall = nChain * lenChain;
vec3 rLead;
float todCur;
const float pi = 3.14159;
const float txRow = 128.;

float GrndHt (vec2 p)
{
  p *= 0.02;
  return 16. * Fbm2 (p) + 2. * SmoothMax (Fbm2 (8. * Rot2D (p, 0.25 * pi)) - 0.5, 0., 0.1);
}

vec3 GrndNf (vec3 p)
{
  const vec2 e = vec2 (0.01, 0.);
  return normalize (vec3 (GrndHt (p.xz) - vec2 (GrndHt (p.xz + e.xy), GrndHt (p.xz + e.yx)), e.x).xzy);
}

void Step (int mId, out vec3 rm, out vec3 vm, out vec4 qm, out vec3 wm, out float sz)
{
  vec4 p;
  vec3 rmN, vmN, wmN, dr, dv, drw, am, wam;
  float fOvlap, fricN, fricT, fricS, fricSW, fDamp, fAttr, grav, rSep, szN, szAv,
     fc, ft, ms, drv, dt, fnh;
  const float nLev = 6.;
  fOvlap = 1000.;
  fricN = 10.;
  fricS = 0.1;
  fricSW = 1.;
  fricT = 0.5;
  fAttr = 5.;
  fDamp = 0.1;
  grav = 20.;
  p = Loadv4 (4 * mId);
  rm = p.xyz;
  sz = p.w;
  vm = Loadv4 (4 * mId + 1).xyz;
  qm = Loadv4 (4 * mId + 2);
  wm = Loadv4 (4 * mId + 3).xyz;
  ms = sz * sz * sz;
  am = vec3 (0.);
  wam = vec3 (0.);
  for (int n = 0; n < nBall; n ++) {
    p = Loadv4 (4 * n);
    rmN = p.xyz;
    szN = p.w;
    dr = rm - rmN;
    rSep = length (dr);
    szAv = 0.5 * (sz + szN);
    if (n != mId && rSep < szAv) {
      fc = fOvlap * (szAv / rSep - 1.);
      vmN = Loadv4 (4 * n + 1).xyz;
      wmN = Loadv4 (4 * n + 3).xyz;
      dv = vm - vmN;
      drv = dot (dr, dv) / (rSep * rSep);
      fc = max (fc - fricN * drv, 0.);
      am += fc * dr;
      dv -= drv * dr + cross ((sz * wm + szN * wmN) / (sz + szN), dr);
      ft = min (fricT, fricS * abs (fc) * rSep / max (0.001, length (dv)));
      am -= ft * dv;
      wam += (ft / rSep) * cross (dr, dv);
    }
    if ((n == mId + 1 || n == mId - 1) && n / lenChain == mId / lenChain) am -= 20. * fAttr * dr;
  }
  szAv = 0.5 * (sz + 1.);
  dr.xz = -0.55 * GrndNf (rm).xz;
  dr.y = rm.y + 0.55 - GrndHt (rm.xz - dr.xz);
  rSep = length (dr);
  if (rSep < szAv) {
    fc = fOvlap * (szAv / rSep - 1.);
    dv = vm;
    drv = dot (dr, dv) / (rSep * rSep);
    fc = max (fc - fricN * drv, 0.);
    am += fc * dr;
    dv -= drv * dr + sz * cross (wm, dr);
    ft = min (fricT, fricSW * abs (fc) * rSep / max (0.001, length (dv)));
    am -= ft * dv;
    wam += (ft / rSep) * cross (dr, dv);
  }
  if (lenChain * (mId / lenChain) == mId) am += fAttr * (rLead - rm);
  am.y -= grav * ms;
  am -= fDamp * vec3 (1., 5., 1.) * vm;
  dt = 0.01;
  vm += dt * am / ms;
  rm += dt * vm;
  wm += dt * wam / (0.1 * ms * sz);
  qm = normalize (QtMul (RMatToQt (LpStepMat (0.5 * dt * wm)), qm));
}

void Init (int mId, out vec3 rm, out vec3 vm, out vec4 qm, out vec3 wm, out float sz)
{
  float mIdf, lenChainf;
  mIdf = float (mId);
  lenChainf = float (lenChain);
  rm.xz = vec2 (4. * floor (mIdf / lenChainf), 0.9 * mod (mIdf, lenChainf)) + 256. * Hashff (todCur);
  rm.y = GrndHt (rm.xz) + 1.5;
  vm = vec3 (0., -0.1, 0.);
  qm = vec4 (0., 0., 0., 1.);
  wm = vec3 (0.);
  sz = 1. - 0.2 * mod (mIdf  / lenChainf, 1.);
}

void mainImage (out vec4 fragColor, in vec2 fragCoord)
{
  vec4 stDat, p, qm;
  vec3 rm, vm, wm, rLeadS;
  vec2 iFrag;
  float sz, nStep;
  int mId, pxId, kp;
  bool doInit;
  iFrag = floor (fragCoord);
  pxId = int (iFrag.x + txRow * iFrag.y);
  if (iFrag.x >= txRow || pxId >= 4 * nBall + 1) discard;
  todCur = iDate.w;
  mId = (pxId < 4 * nBall) ? pxId / 4 : -1;
  if (iFrame <= 5) {
    doInit = true;
  } else {
    doInit = false;
    stDat = Loadv4 (4 * nBall);
    nStep = stDat.w;
    ++ nStep;
    rLeadS = stDat.xyz;
    rLeadS.z += -0.05;
    if (mId >= 0) {
      rLead = rLeadS;
      rLead.x += 4. * float (mId / lenChain);
      rLead.y += GrndHt (rLead.xz);
      Step (mId, rm, vm, qm, wm, sz);
    }
  }
  if (doInit) {
    nStep = 0.;
    if (mId >= 0) Init (mId, rm, vm, qm, wm, sz);
    if (pxId == 4 * nBall) {
      rLeadS.xz = vec2 (256. * Hashff (todCur));
      rLeadS.y = 1.5;
    }
  }
  if (pxId < 4 * nBall) {
    kp = 4 * mId;
    if      (pxId == kp + 0) p = vec4 (rm, sz);
    else if (pxId == kp + 1) p = vec4 (vm, 0.);
    else if (pxId == kp + 2) p = qm;
    else if (pxId == kp + 3) p = vec4 (wm, 0.);
    stDat = p;
  } else {
    kp = 4 * nBall;
    if (pxId == kp + 0) stDat = vec4 (rLeadS, nStep);
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

float SmoothMax (float a, float b, float r)
{
  float h;
  h = clamp (0.5 - 0.5 * (b - a) / r, 0., 1.);
  return r * h * (1. - h) - mix (b, a, h);
}

vec2 Rot2D (vec2 q, float a)
{
  return q * cos (a) + q.yx * sin (a) * vec2 (-1., 1.);
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
