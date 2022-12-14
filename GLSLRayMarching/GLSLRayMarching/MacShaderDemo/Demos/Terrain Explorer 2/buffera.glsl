// "Terrain Explorer 2" by dr2 - 2021
// License: Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License

vec4 Loadv4 (int idVar);
void Savev4 (int idVar, vec4 val, inout vec4 fCol, vec2 fCoord);

const float pi = 3.1415927;
const float txRow = 32.;

void mainImage (out vec4 fragColor, in vec2 fragCoord)
{
  vec4 wgBx[10], wgBxC, mPtr, mPtrP, stDat, parmV1, parmV2, parmV3;
  vec2 iFrag, canvas, ust;
  float tCur, tCurP, tCurM, vW, asp, el, az, flyVel, mvTot;
  int pxId, wgSel, wgReg, kSel, grType, qType, shType, refType, noInt;
  iFrag = floor (fragCoord);
  pxId = int (iFrag.x + txRow * iFrag.y);
  if (iFrag.x >= txRow || pxId >= 6) discard;
  canvas = iResolution.xy;
  tCur = iTime;
  mPtr = iMouse;
  mPtr.xy = mPtr.xy / iResolution.xy - 0.5;
  wgSel = -1;
  wgReg = -2;
  asp = canvas.x / canvas.y;
  if (iFrame <= 5) {
    parmV1 = vec4 (0.6, 0.6, 0.8, 0.6);
    parmV2 = vec4 (0.2, 0.3, 0., 0.);
    parmV3 = vec4 (1., 2., 2., 1.);
    el = -0.05 * pi;
    az = 0.;
    mvTot = 0.;
    mPtrP = mPtr;
    tCurP = tCur;
    tCurM = tCur;
    noInt = 1;
  } else {
    parmV1 = Loadv4 (0);
    parmV2 = Loadv4 (1);
    flyVel = parmV2.y;
    parmV3 = Loadv4 (2);
    stDat = Loadv4 (3);
    el = stDat.x;
    az = stDat.y;
    tCurP = stDat.z;
    tCurM = stDat.w;
    stDat = Loadv4 (4);
    mvTot = stDat.x;
    noInt = int (stDat.y);
    mvTot += 8. * flyVel * (tCur - tCurP);
    if (mvTot > 4000.) mvTot = 0.;
    stDat = Loadv4 (5);
    mPtrP = vec4 (stDat.xyz, 0.);
    wgSel = int (stDat.w);
  }
  if (mPtr.z > 0.) {
    for (int k = 0; k < 6; k ++)
       wgBx[k] = vec4 (0.36 * asp, 0.25 - 0.06 * float (k), 0.12 * asp, 0.018);
    for (int k = 6; k < 10; k ++)
       wgBx[k] = vec4 ((0.29 + 0.05 * float (k - 6)) * asp, -0.25, 0.024, 0.024);
    wgBxC = vec4 (0.47 * asp, -0.4, 0.022, 0.);
    for (int k = 0; k < 10; k ++) {
      ust = abs (mPtr.xy * vec2 (asp, 1.) - wgBx[k].xy) - wgBx[k].zw;
      if (max (ust.x, ust.y) < 0.) wgReg = k;
    }
    ust = mPtr.xy * vec2 (asp, 1.) - wgBxC.xy;
    if (length (ust) < wgBxC.z) wgReg = 10;
    if (mPtrP.z <= 0.) wgSel = wgReg;
    if (wgSel >= 0 || noInt > 0) tCurM = tCur;
    noInt = 0;
  } else {
    wgSel = -1;
    wgReg = -2;
  }
  if (wgSel < 0) {
    if (mPtr.z > 0.) {
      az = 2. * pi * mPtr.x;
      el = -0.05 * pi + 0.8 * pi * mPtr.y;
    } else {
      el = mix (el, -0.05 * pi, 0.02);
      az = mix (az, 0., 0.02);
    }
  } else {
    if (wgSel < 6) {
      for (int k = 0; k < 6; k ++) {
        if (wgSel == k) {
          kSel = k;
          vW = clamp (0.5 + 0.5 * (mPtr.x * asp - wgBx[k].x) / wgBx[k].z, 0., 0.99);
          break;
        }
      }
      if      (kSel == 0) parmV1.x = vW;
      else if (kSel == 1) parmV1.y = vW;
      else if (kSel == 2) parmV1.z = vW;
      else if (kSel == 3) parmV1.w = vW;
      else if (kSel == 4) parmV2.x = vW;
      else if (kSel == 5) parmV2.y = vW;
    } else if (mPtrP.z <= 0.) {
      if (wgSel == 6) {
        grType = int (parmV3.x);
        if (++ grType > 4) grType = 1;
        parmV3.x = float (grType);
      } else if (wgSel == 7) {
        qType = int (parmV3.y);
        if (++ qType > 3) qType = 1;
        parmV3.y = float (qType);
      } else if (wgSel == 8) {
        shType = int (parmV3.z);
        if (++ shType > 3) shType = 1;
        parmV3.z = float (shType);
      } else if (wgSel == 9) {
        refType = int (parmV3.w);
        if (++ refType > 2) refType = 1;
        parmV3.w = float (refType);
      }
    }
  }
  if      (pxId == 0) stDat = parmV1;
  else if (pxId == 1) stDat = parmV2;
  else if (pxId == 2) stDat = parmV3;
  else if (pxId == 3) stDat = vec4 (el, az, tCur, tCurM);
  else if (pxId == 4) stDat = vec4 (mvTot, float (noInt), 0., 0.);
  else if (pxId == 5) stDat = vec4 (mPtr.xyz, float (wgSel));
  Savev4 (pxId, stDat, fragColor, fragCoord);
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
  vec2 d;
  float fi;
  fi = float (idVar);
  d = abs (fCoord - vec2 (mod (fi, txRow), floor (fi / txRow)) - 0.5);
  if (max (d.x, d.y) < 0.5) fCol = val;
}
