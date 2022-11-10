// "Controllable Hexapod 2" by dr2 - 2021
// License: Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License

float Hashff (float p);
vec2 Rot2Cs (vec2 q, vec2 cs);
vec4 Loadv4 (int idVar);
void Savev4 (int idVar, vec4 val, inout vec4 fCol, vec2 fCoord);

vec3 footPos[6], bdyPos;
float tCur, bdyRad, bdyHt, footSpeedV, footDir, stepCount, stepLim, 
   wkPhase, wkChange, walking, walkDir, turnDir, turnDirN;
const float txRow = 128.;
const float pi = 3.14159;

void Step ()
{
  vec2 b, c;
  float stepLimM, walkSpeed, turnSpeed, u, mm;
  stepLimM = 64.;
  walkSpeed = 0.8 / stepLimM;
  turnSpeed = 0.5 * walkSpeed;
  if (stepCount == 0.) {
    if (wkChange != 0. && (wkPhase == 0. || wkPhase == 2.)) {
      ++ wkPhase;
      wkChange = 0.;
    }
    if (wkPhase == 2. && turnDir != turnDirN) {
      ++ wkPhase;
      wkChange = 1.;
    }
    if (wkPhase == 1. || wkPhase == 4.) walking = 1. - walking;
    stepLim = stepLimM;
    if (wkPhase == 1. || wkPhase == 3.) stepLim *= 0.5;
    else if (wkPhase == 0. || wkPhase == 4.) stepLim = 0.;
    if (stepLim > 0.) {
      footSpeedV = 0.6 * bdyHt / (stepLim * 0.5);
      if (wkPhase == 1. || wkPhase == 3.) footSpeedV *= 0.5;
    }
    if (wkPhase == 1.) {
      turnDir = turnDirN;
      footDir = 1.;
    } else footDir = - footDir;
    if (wkPhase == 4.) {
      wkPhase = 0.;
      turnDir = 0.;
    }
    if (wkPhase == 1. || wkPhase == 3.) ++ wkPhase;
    stepCount = stepLim;
  }
  if (walking == 0. && turnDir == 0.) {
    bdyPos.y = max (0.97 * bdyPos.y, 0.6 * bdyHt);
    for (int m = 0; m < 6; m ++) footPos[m].y = - bdyPos.y;
  } else if (bdyPos.y != bdyHt) {
    bdyPos.y = min (1.1 * bdyPos.y, bdyHt);
    for (int m = 0; m < 6; m ++) footPos[m].y = - bdyPos.y;
  }  
  if (stepLim > 0.) {
    -- stepCount;
    if (turnDir == 0.) {
      bdyPos.xz += walkSpeed * sin (walkDir + vec2 (0.5 * pi, 0.));
    } else {
      walkDir = mod (walkDir + turnSpeed * turnDir, 2. * pi);
      c = sin (turnSpeed * turnDir + vec2 (0.5 * pi, 0.));
    }
    for (int m = 0; m < 6; m ++) {
      mm = float (m);
      u = footDir * (2. * mod (mm, 2.) - 1.);
      if (u > 0.) footPos[m].y += footSpeedV * sign (stepLim * 0.5 - 0.5 - stepCount);
      if (turnDir == 0.) {
        footPos[m].x += u * walkSpeed;
      } else {
        b = bdyRad * sin (pi * (2. * mm + 1.) / 6. + vec2 (0.5 * pi, 0.));
        footPos[m].xz = Rot2Cs (footPos[m].xz + b, vec2 (c.x, u * c.y)) - b;
      }      
    }
  }
}

void Init ()
{
  float footDist;
  bdyRad = 0.8;
  bdyHt = 0.6;
  bdyPos = vec3 (0., bdyHt, 0.);
  footDist = 1.1;
  for (int m = 0; m < 6; m ++) {
    footPos[m].xz = footDist * sin (pi * (2. * float (m) + 1.) / 6. + vec2 (0.5 * pi, 0.));
    footPos[m].y = - bdyPos.y;
  }
  footSpeedV = 0.;
  footDir = 0.;
  stepCount = 0.;
  stepLim = 0.;
  wkPhase = 0.;
  wkChange = 0.;
  walking = 0.;
  walkDir = - 0.5 * pi;
  turnDir = 0.;
  turnDirN = 0.;
}

void SetMode (int m)
{
  if (m == 0) {
    turnDirN = 0.;
    if (walking == 0.) wkChange = 1.;
  } else if (m == 1) {
    turnDirN = 0.;
    if (walking != 0.) wkChange = 1.;
  } else if (m == 2) {
    turnDirN = 1.;
    if (turnDir != turnDirN && walking == 0.) wkChange = 1.;
  } else if (m == 3) {
    turnDirN = -1.;
    if (turnDir != turnDirN && walking == 0.) wkChange = 1.;
  }
}

void mainImage (out vec4 fragColor, in vec2 fragCoord)
{
  vec4 wgBx[4], mPtr, mPtrP, stDat, w1, w2;
  vec2 canvas, iFrag;
  float asp, el, az, autMode, tChMode;
  int pxId, wgSel, wgReg, im;
  bool doInit;
  iFrag = floor (fragCoord);
  pxId = int (iFrag.x + txRow * iFrag.y);
  if (iFrag.x >= txRow || pxId >= 12) discard;
  canvas = iResolution.xy;
  tCur = iTime;
  mPtr = iMouse;
  mPtr.xy = mPtr.xy / canvas - 0.5;
  wgReg = -2;
  doInit = false;
  autMode = 1.;
  tChMode = tCur;
  if (iFrame <= 5) {
    mPtrP = mPtr;
    az = 0.;
    el = 0.;
    wgSel = -1;
    doInit = true;
  } else {
    for (int k = 0; k < 6; k ++) {
      stDat = Loadv4 (k);
      footPos[k] = stDat.xyz;
    }
    stDat = Loadv4 (6);
    bdyPos = stDat.xyz;
    walkDir = stDat.w;
    stDat = Loadv4 (7);
    walking = stDat.x;
    footDir = stDat.y;
    turnDir = stDat.z;
    turnDirN = stDat.w;
    stDat = Loadv4 (8);
    stepCount = stDat.x;
    stepLim = stDat.y;
    wkPhase = stDat.z;
    wkChange = stDat.w;
    stDat = Loadv4 (9);
    footSpeedV = stDat.x;
    bdyRad = stDat.y;
    bdyHt = stDat.z;
    tChMode = stDat.w;
    stDat = Loadv4 (10);
    az = stDat.x;
    el = stDat.y;
    wgSel = int (stDat.z);
    autMode = stDat.w;
    mPtrP = Loadv4 (11);
  }
  asp = canvas.x / canvas.y;
  if (mPtr.z > 0.) {
    w1 = vec4 (0.42 * asp, -0.35, 0.025, 0.);
    w2 = vec4 (0.06, 0., 0., 0.);
    wgBx[0] = w1 + w2.yxzw;
    wgBx[1] = w1 - w2.yxzw;
    wgBx[2] = w1 - w2;
    wgBx[3] = w1 + w2;
    for (int k = 0; k < 4; k ++) {
      if (length (mPtr.xy * vec2 (asp, 1.) - wgBx[k].xy) < wgBx[k].z) wgReg = k;
    }
    if (mPtrP.z <= 0.) wgSel = wgReg;
  } else {
    wgSel = -1;
    wgReg = -2;
    az = 0.02 * pi * tCur;
    el = -0.15 * pi + 0.07 * pi * sin (0.033 * pi * tCur);
  }
  if (wgSel < 0) {
    if (mPtr.z > 0.) {   
      az = 2. * pi * mPtr.x;
      el = -0.1 * pi + pi * mPtr.y;
      el = clamp (el, -0.4 * pi, -0.01 * pi);
    }
  } else if (mPtrP.z <= 0.) {
    autMode = 0.;
    tChMode = tCur + 10.;
    SetMode (wgSel);
  }
  if (tCur > tChMode) autMode = 1.;
  if (autMode != 0. && tCur > tChMode) {
    tChMode = tCur + 2.;
    im = int (100. * Hashff (17. * tChMode));
    tChMode += 3. * Hashff (23. * tChMode);
    if (im < 60) im = 0;
    else if (im < 75) im = 2;
    else if (im < 90) im = 3;
    else im = 1;
    SetMode (im);
  }
  if (doInit) Init ();
  else Step ();
  if (pxId < 6) {
    for (int k = 0; k < 6; k ++) {
      if (pxId == k) stDat = vec4 (footPos[k], 0.);
    }
  }
  else if (pxId == 6) stDat = vec4 (bdyPos, walkDir);
  else if (pxId == 7) stDat = vec4 (walking, footDir, turnDir, turnDirN);
  else if (pxId == 8) stDat = vec4 (stepCount, stepLim, wkPhase, wkChange);
  else if (pxId == 9) stDat = vec4 (footSpeedV, bdyRad, bdyHt, tChMode);
  else if (pxId == 10) stDat = vec4 (az, el, float (wgSel), autMode);
  else if (pxId == 11) stDat = mPtr;
  Savev4 (pxId, stDat, fragColor, fragCoord);
}

vec2 Rot2Cs (vec2 q, vec2 cs)
{
  return vec2 (dot (q, vec2 (cs.x, - cs.y)), dot (q.yx, cs));
}

const float cHashM = 43758.54;

float Hashff (float p)
{
  return fract (sin (p) * cHashM);
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
