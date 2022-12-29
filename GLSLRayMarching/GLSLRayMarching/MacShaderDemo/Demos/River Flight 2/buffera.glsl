// "River Flight 2" by dr2 - 2018
// License: Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License

vec4 Loadv4 (vec2 vId);

const float pi = 3.14159;

#define txBuf iChannel0
#define txSize iChannelResolution[0].xy

#define N_VU 5

void mainImage (out vec4 fragColor, vec2 fragCoord)
{
  vec4 mPtr, mPtrP, stDat;
  vec2 canvas, iFrag;
  float tCur, tMouse, nStep, nVu, vuMode;
  canvas = iResolution.xy;
  tCur = iTime;
  mPtr = iMouse;
  mPtr.xy = mPtr.xy / canvas - 0.5;
  if (fragCoord.x >= 2. || fragCoord.y >= 1.) discard;
  iFrag = floor (fragCoord);
  if (iFrame > 5) {
    stDat = Loadv4 (vec2 (0., 0.));
    mPtrP.xyz = stDat.xyz;
    vuMode = stDat.w;
    stDat = Loadv4 (vec2 (1., 0.));
    tMouse = stDat.x;
  } else {
    mPtrP = mPtr;
    vuMode = -1.;
    tMouse = tCur;
  }
  nVu = float (N_VU);
  if (mPtr.z > 0.) {
    if (mPtr.y < -0.5 + (1. / (nVu + 1.))) vuMode = floor (nVu * clamp (mPtr.x + 0.5, 0., 0.99));
    tMouse = tCur;
  } else if (tCur - tMouse > 10.) vuMode = -1.;
  if (iFrag.y == 0.) {
    if (iFrag.x == 0.) fragColor = vec4 (mPtr.xyz, vuMode);
    else  if (iFrag.x == 1.) fragColor = vec4 (tMouse, 0., 0., 0.);
  }
}

vec4 Loadv4 (vec2 vId)
{
  return texture (txBuf, (vId + 0.5) / txSize);
}
