// "Complex Tunnels" by dr2 - 2016
// License: Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License

#define txBuf iChannel0
#define txSize iChannelResolution[0].xy

const float pi = 3.14159;

const float txRow = 64.;

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

// Set = 1 in BOTH shaders for more fun. WARNING: browser crashes reported
#define LONG_TRACK 0
//#define LONG_TRACK 1

#if LONG_TRACK
#define N_ENG 5
#define TRK_LEN 24
#else
#define N_ENG 3
#define TRK_LEN 12
#endif

vec4 pCar[N_ENG];
vec3 drP;
vec2 rP;
float ti[TRK_LEN + 1], tCur, tCyc, rgHSize, tC, aP;

#define SLIN(k,d) ti[k + 1] = ti[k] + d
#define SCRV(k) ti[k + 1] = ti[k] + tC

void TrSetup ()
{
  tC = 0.25 * pi;
  ti[0] = 0.;
#if LONG_TRACK
  SCRV(0);  SLIN(1, 4.);  SCRV(2);  SLIN(3, 1.);  SCRV(4);  SLIN(5, 1.);  SCRV(6);
  SLIN(7, 2.);  SCRV(8);  SLIN(9, 1.);  SCRV(10);  SLIN(11, 1.);  SCRV(12);
  SLIN(13, 4.);  SCRV(14);  SLIN(15, 1.);  SCRV(16);  SLIN(17, 1.);  SCRV(18);
  SLIN(19, 2.);  SCRV(20);  SLIN(21, 1.);  SCRV(22);  SLIN(23, 1.);
#else
  SCRV(0);   SLIN(1, 1.);  SCRV(2);  SLIN(3, 4.);  SCRV(4);  SLIN(5, 2.);
  SCRV(6);  SLIN(7, 2.);  SCRV(8);  SLIN(9, 4.);  SCRV(10);  SLIN(11, 1.);
#endif
  tCyc = ti[TRK_LEN];
  rgHSize = 3.;
}

#if LONG_TRACK

void TPath1 (float t)
{
  if (t < ti[6]) {
    if (t < ti[1]) {
      rP = vec2 (0., 0.);  drP = vec3 (1., 1., 0.5 * tC + 0.25 * (t - ti[0]));
    } else if (t < ti[2]) {
      rP = vec2 (1., 0.5);  drP.x = (t - ti[1]);
    } else if (t < ti[3]) {
      rP = vec2 (5., 0.);  drP = vec3 (0., 1., 0.75 * tC + 0.25 * (t - ti[2]));
    } else if (t < ti[4]) {
      rP = vec2 (5.5, 1.);  drP.y = (t - ti[3]);
    } else if (t < ti[5]) {
      rP = vec2 (5., 2.);  drP.z = 0. * tC + 0.25 * (t - ti[4]);
    } else {
      rP = vec2 (5., 2.5);  drP.x = - (t - ti[5]);
    }
  } else {
    if (t < ti[7]) {
      rP = vec2 (4., 2.);  drP = vec3 (0., 1., 0.75 * tC - 0.25 * (t - ti[6]));
    } else if (t < ti[8]) {
      rP = vec2 (3.5, 3.);  drP.y = (t - ti[7]);
    } else if (t < ti[9]) {
      rP = vec2 (3., 5.);  drP = vec3 (1., 0., 0.5 * tC - 0.25 * (t - ti[8]));
    } else if (t < ti[10]) {
      rP = vec2 (4., 5.5);  drP.x = (t - ti[9]);
    } else if (t < ti[11]) {
      rP = vec2 (5., 5.);  drP.z = 0.25 * tC - 0.25 * (t - ti[10]);
    } else {
      rP = vec2 (5.5, 5.);  drP.y = - (t - ti[11]);
    }
  }
}

void TPath2 (float t)
{
  if (t < ti[18]) {
    if (t < ti[13]) {
      rP = vec2 (5., 3.);  drP = vec3 (0., 1., 0. * tC - 0.25 * (t - ti[12]));
    } else if (t < ti[14]) {
      rP = vec2 (5., 3.5);  drP.x = - (t - ti[13]);
    } else if (t < ti[15]) {
      rP = vec2 (0., 3.);  drP = vec3 (1., 1., 0.75 * tC - 0.25 * (t - ti[14]));
    } else if (t < ti[16]) {
      rP = vec2 (0.5, 4.);  drP.y = (t - ti[15]);
    } else if (t < ti[17]) {
      rP = vec2 (0., 5.);  drP = vec3 (1., 0., 0.5 * tC - 0.25 * (t - ti[16]));
    } else {
      rP = vec2 (1., 5.5);  drP.x = (t - ti[17]);
    }
  } else {
    if (t < ti[19]) {
      rP = vec2 (2., 5.);  drP.z = 0.25 * tC - 0.25 * (t - ti[18]);
    } else if (t < ti[20]) {
      rP = vec2 (2.5, 5.);  drP.y = - (t - ti[19]);
    } else if (t < ti[21]) {
      rP = vec2 (2., 2.);  drP = vec3 (0., 1., 0. * tC - 0.25 * (t - ti[20]));
    } else if (t < ti[22]) {
      rP = vec2 (2., 2.5);  drP.x = - (t - ti[21]);
    } else if (t < ti[23]) {
      rP = vec2 (0., 2.);  drP = vec3 (1., 0., 0.25 * tC + 0.25 * (t - ti[22]));
    } else {
      rP = vec2 (0.5, 2.);  drP.y = - (t - ti[23]);
    }
  }
}

vec2 TrackPath (float t)
{
  t = mod (t, tCyc);
  drP = vec3 (0., 0., 99.);
  if (t < ti[12]) TPath1 (t);
  else TPath2 (t);
  if (drP.z != 99.) {
    drP.z *= 2. * pi / tC;
    rP += 0.5 * vec2 (cos (drP.z), sin (drP.z));
  }
  rP += drP.xy - rgHSize;
  return rP;
}

#else

vec2 TrackPath (float t)
{
  t = mod (t, tCyc);
  drP = vec3 (0., 0., 99.);
  if (t < ti[1]) {
    rP = vec2 (0., 0.);  drP = vec3 (1., 1., 0.5 * tC + 0.25 * (t - ti[0]));
  } else if (t < ti[2]) {
    rP = vec2 (1., 0.5);  drP.x = (t - ti[1]);
  } else if (t < ti[3]) {
    rP = vec2 (2., 0.);  drP = vec3 (0., 1., 0.75 * tC + 0.25 * (t - ti[2]));
  } else if (t < ti[4]) {
    rP = vec2 (2.5, 1.);  drP.y = (t - ti[3]);
  } else if (t < ti[5]) {
    rP = vec2 (2., 5.);  drP = vec3 (1., 0., 0.5 * tC - 0.25 * (t - ti[4]));
  } else if (t < ti[6]) {
    rP = vec2 (3., 5.5);  drP.x = (t - ti[5]);
  } else if (t < ti[7]) {
    rP = vec2 (5., 5.);  drP = vec3 (0., 0., 0.25 * tC - 0.25 * (t - ti[6]));
  } else if (t < ti[8]) {
    rP = vec2 (5.5, 5.);  drP.y = - (t - ti[7]);
  } else if (t < ti[9]) {
    rP = vec2 (5., 2.);  drP = vec3 (0., 1., 0. * tC - 0.25 * (t - ti[8]));
  } else if (t < ti[10]) {
    rP = vec2 (5., 2.5);  drP.x = - (t - ti[9]);
  } else if (t < ti[11]) {
    rP = vec2 (0., 2.);  drP = vec3 (1., 0., 0.25 * tC + 0.25 * (t - ti[10]));
  } else if (t < ti[12]) {
    rP = vec2 (0.5, 2.);  drP.y = - (t - ti[11]);
  }
  if (drP.z != 99.) {
    drP.z *= 2. * pi / tC;
    rP += 0.5 * vec2 (cos (drP.z), sin (drP.z));
  }
  rP += drP.xy - rgHSize;
  return rP;
}

#endif

void mainImage (out vec4 fragColor, in vec2 fragCoord)
{
  vec4 wgBx[2], pCar[5], pVu, stDat, mPtr, mPtrP;
  vec2 iFrag, canvas, ust, vo;
  float el, az, asp, tCurP, trVar, trSpd, trMov, t;
  int pxId, wgSel, wgReg, riding;
  iFrag = floor (fragCoord);
  pxId = int (iFrag.x + txRow * iFrag.y);
  if (iFrag.x >= txRow || pxId >= N_ENG + 4) discard;
  canvas = iResolution.xy;
  tCur = iTime;
  mPtr = iMouse;
  mPtr.xy = mPtr.xy / canvas - 0.5;
  riding = 1;
  trMov = 0.;
  trVar = 0.3;
  el = 0.;
  az = 0.;
  wgSel = -1;
  wgReg = -2;
  if (iFrame <= 5) {
    mPtrP = mPtr;
  } else {
    stDat = Loadv4 (N_ENG + 1);
    trMov = stDat.x;
    trSpd = stDat.y;
    tCurP = stDat.z;
    stDat = Loadv4 (N_ENG + 2);
    riding = int (stDat.x);
    el = stDat.y;
    az = stDat.z;
    trVar = stDat.w;
    stDat = Loadv4 (N_ENG + 3);
    mPtrP = vec4 (stDat.xyz, 0.);
    wgSel = int (stDat.w);
  }
  asp = canvas.x / canvas.y;
  if (mPtr.z > 0.) {
    wgBx[0] = vec4 (0.47 * asp, -0.1, 0.012 * asp, 0.15);
    wgBx[1] = vec4 (0.47 * asp, -0.4, 0.022, 0.);
    ust = abs (mPtr.xy * vec2 (asp, 1.) - wgBx[0].xy) - wgBx[0].zw;
    if (max (ust.x, ust.y) < 0.) wgReg = 0;
    if (length (mPtr.xy * vec2 (asp, 1.) - wgBx[1].xy) < wgBx[1].z) wgReg = 1;
    if (mPtrP.z <= 0.) wgSel = wgReg;
  } else {
    wgSel = -1;
    wgReg = -2;
  }
  if (wgSel < 0) {
    if (mPtr.z > 0.) {
      az = - 2. * pi * mPtr.x;
      el = - pi * mPtr.y;
    }
  } else {
    if (wgSel == 0) {
      trVar = clamp (0.5 + 0.5 * (mPtr.y - wgBx[0].y) / wgBx[0].w, 0., 1.);
    } else if (wgSel == 1) {
      if (mPtrP.z <= 0.) {
        riding = 1 - riding;
        el = 0.;
        az = 0.;
      }
    }
  }
  trSpd = 1. * trVar;
  if (trSpd < 0.01) trSpd = 0.;
  TrSetup ();
  trMov += trSpd * (tCur - tCurP);
  for (int k = 0; k < N_ENG; k ++) {
    t = trMov - float (k) * tCyc / float (N_ENG);
    pCar[k].xz = TrackPath (t);
    pCar[k].y = 0.;
    vo = TrackPath (t + 0.01) - pCar[k].xz;
    pCar[k].w = atan (vo.x, vo.y);
  }
  if (riding > 0) {
    t = floor (mod (0.07 * trMov, float (N_ENG)));
#if LONG_TRACK
    t += 0.17;
#else
    t += 0.27;
#endif
    t = trMov - t * tCyc / float (N_ENG);
    pVu.xz = TrackPath (t);
    pVu.y = 0.;
    vo = TrackPath (t + 0.01) - pVu.xz;
    pVu.w = - atan (vo.x, vo.y);
  } else pVu = vec4 (0.);
  tCurP = tCur;
  for (int k = 0; k < N_ENG; k ++) {
    if (pxId == k) stDat = pCar[k];
  }
  if (pxId == N_ENG) stDat = pVu;
  else if (pxId == N_ENG + 1) stDat = vec4 (trMov, trSpd, tCurP, 0.);
  else if (pxId == N_ENG + 2) stDat = vec4 (float (riding), el, az, trVar);
  else if (pxId == N_ENG + 3) stDat = vec4 (mPtr.xyz, float (wgSel));
  Savev4 (pxId, stDat, fragColor, fragCoord);
}
