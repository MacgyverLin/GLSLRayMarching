// "Controllable Machinery" by dr2 - 2022
// License: Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License

float Maxv2 (vec2 p);
mat3 StdVuMat (float el, float az);
vec4 Loadv4 (int idVar);
void Savev4 (int idVar, vec4 val, inout vec4 fCol, vec2 fCoord);

const float pi = 3.1415927;
const float txRow = 128.;

void mainImage (out vec4 fragColor, vec2 fragCoord)
{
  mat3 vuMat;
  vec4 mPtr, stDat, wgObj;
  vec3 vCon, ro;
  vec2 canvas, iFrag, ud;
  float tCur, tMov, az, el, asp, zmFac, spd, cnPos, mPtrPz, s;
  int pxId, wgSel, wgReg;
  bool init;
  canvas = iResolution.xy;
  tCur = iTime;
  mPtr = iMouse;
  mPtr.xy = mPtr.xy / canvas - 0.5;
  iFrag = floor (fragCoord);
  pxId = int (iFrag.x + txRow * iFrag.y);
  if (pxId >= 2) discard;
  wgSel = -1;
  wgReg = -2;
  asp = canvas.x / canvas.y;
  init = (iFrame <= 2);
  if (init) {
    tMov = 0.;
    spd = 0.5;
    cnPos = 0.5;
    az = 0.;
    el = -0.12 * pi;
    mPtrPz = mPtr.z;
  } else {
    stDat = Loadv4 (0);
    tMov = stDat.x;
    cnPos = stDat.y;
    spd = stDat.z;
    tMov += 0.02 * spd;
    stDat = Loadv4 (1);
    az = stDat.x;
    el = stDat.y;
    mPtrPz = stDat.z;
    wgSel = int (stDat.w);
  }
  if (! init) {
    if (mPtr.z > 0.) {
      vuMat = StdVuMat (el, az);
      ro = vuMat * vec3 (0., 0., -8.);
      ro.z += 0.9;
      zmFac = 4.;
      vCon = vuMat * normalize (vec3 (2. * mPtr.xy * vec2 (asp, 1.), zmFac));
      wgObj = vec4 (cnPos - 0.5, -1.12, -0.4, 0.08);
      ud = (ro.xz + (- (ro.y - wgObj.y) / vCon.y) * vCon.xz);
      s = Maxv2 (abs (ud - wgObj.xz)) - wgObj.w - 0.1;
      if (s < 0. || wgSel == 0) {
        if (s < 0. && wgSel == 0) cnPos = clamp (ud.x + 0.5, 0., 1.);
        wgReg = 0;
      } else if (wgReg < 0) {
        az = 2. * pi * mPtr.x;
        el = pi * mPtr.y;
        el = clamp (el, -0.4 * pi, 0.1 * pi);
      }
      if (mPtrPz <= 0.) wgSel = wgReg;
    } else {
      wgSel = -1;
      wgReg = -2;
      az = mix (az, 0., 0.003 + 0.05 * step (abs (az), 0.15));
      el = mix (el, -0.12 * pi, 0.003 + 0.05 * step (abs (el + 0.12 * pi), 0.15));
    }
  }
  spd = 2. * cnPos;
  if      (pxId == 0) stDat = vec4 (tMov, cnPos, spd, 0.);
  else if (pxId == 1) stDat = vec4 (az, el, mPtr.z, float (wgSel));
  Savev4 (pxId, stDat, fragColor, fragCoord);
}

float Maxv2 (vec2 p)
{
  return max (p.x, p.y);
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

#define txBuf iChannel0
#define txSize iChannelResolution[0].xy

vec4 Loadv4 (int idVar)
{
  float fi;
  fi = float (idVar);
  return texture (txBuf, (vec2 (mod (fi, txRow), floor (fi / txRow)) + 0.5) / txSize);
}

void Savev4 (int idVar, vec4 val, inout vec4 fCol, vec2 fCoord)
{
  float fi;
  fi = float (idVar);
  if (Maxv2 (abs (fCoord - vec2 (mod (fi, txRow), floor (fi / txRow)) - 0.5)) < 0.5) fCol = val;
}
