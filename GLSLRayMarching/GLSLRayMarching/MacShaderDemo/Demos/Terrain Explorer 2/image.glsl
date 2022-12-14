// "Terrain Explorer 2" by dr2 - 2021
// License: Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License

/*
  Updated to include water and reflection.
  
  Control panel appears when yellow ring (or a hidden control) clicked; panel fades
  automatically; use mouse to look around.

  Height functions based on the following (1-3 have additional spatial modulation):
    1) Basic fBm.
    2) Modified fBm in 'Elevated' by iq.
    3) Inverted waves simplified from 'Seascape' by TDM.
    4) Weird forms from 'Sirenian Dawn' by nimitz.

  Sliders (from top):
    Overall height scale.
    Lacunarity - rate of fBm length scale change per iteration.
    Persistence - rate of fBm amplitude change per iteration.
    Variable spatial modulation (height functions 1 & 2), or feature sharpness (3 & 4).
    Water height.
    Flight speed.

  Buttons (from left):
    Height function choice (= 1-4).
    Distance marching accuracy and range (may affect update rate) (= 1-3). 
    Shadows (= 1 off) and sun elevation (= 2-3).
    Terrain reflection (= 1 off, = 2 on).

  There is no end to the functionality that can be added...
  
  (Based on "Terrain Explorer", with water from "Scrolling Terrain", and other mods)
*/

#if 1
#define VAR_ZERO min (iFrame, 0)
#else
#define VAR_ZERO 0
#endif

float ShowInt (vec2 q, vec2 cBox, float mxChar, float val);
float Minv2 (vec2 p);
float Maxv2 (vec2 p);
vec2 Rot2D (vec2 q, float a);
mat3 StdVuMat (float el, float az);
float Noisefv2 (vec2 p);
vec3 Noisev3v2 (vec2 p);
float Fbm2 (vec2 p);
vec3 VaryNf (vec3 p, vec3 n, float f);
vec4 Loadv4 (int idVar);

vec3 sunDir;
float tCur, dstFar, htWat, hFac, fWav, aWav, smFac, stepFac;
int grType, qType, shType, refType, stepLim;
const float pi = 3.1415927;

float GrndHt1 (vec2 p)
{
  vec2 q;
  float f, wAmp;
  mat2 qRot = mat2 (0.8, -0.6, 0.6, 0.8);
  q = 0.1 * p;
  f = 0.;
  wAmp = 1.;
  for (int j = 0; j < 5; j ++) {
    f += wAmp * Noisefv2 (q);
    wAmp *= aWav;
    q *= fWav * qRot;
  }
  return min (5. * Noisefv2 (0.033 * smFac * p) + 0.5, 4.) * f;
}

float GrndHt2 (vec2 p)
{
  vec3 v;
  vec2 q, t;
  float wAmp, f;
  mat2 qRot = mat2 (0.8, -0.6, 0.6, 0.8);
  q = 0.1 * p;
  wAmp = 1.;
  t = vec2 (0.);
  f = 0.;
  for (int j = 0; j < 4; j ++) {
    v = Noisev3v2 (q);
    t += v.yz;
    f += wAmp * v.x / (1. + dot (t, t));
    wAmp *= aWav;      
    q *= fWav * qRot;
  }
  return min (5. * Noisefv2 (0.033 * smFac * p) + 0.5, 4.) * f;
}

float GrndHt3 (vec2 p)
{
  vec2 q, t, ta, v;
  float wAmp, pRough, f;
  mat2 qRot = mat2 (0.8, -0.6, 0.6, 0.8);
  q = 0.1 * p;
  wAmp = 0.3;
  pRough = 1.;
  f = 0.;
  for (int j = 0; j < 3; j ++) {
    t = q + 2. * Noisefv2 (q) - 1.;
    ta = abs (sin (t));
    v = (1. - ta) * (ta + sqrt (1. - ta * ta));
    v = pow (1. - v, vec2 (pRough));
    f += (v.x + v.y) * wAmp;
    q *= fWav * qRot;
    wAmp *= aWav;
    pRough = smFac * pRough + 0.2;
  }
  return min (7. * Noisefv2 (0.033 * p) + 0.5, 5.) * f;
}

float GrndHt4 (vec2 p)
{
  vec3 v;
  vec2 q, t;
  float wAmp, b, f, waFac;
  mat2 qRot = mat2 (0.8, -0.6, 0.6, 0.8);
  q = 0.1 * p;
  wAmp = 1.;
  t = vec2 (0.);
  f = 0.;
  waFac = 1.;
  for (int j = 0; j < 4; j ++) {
    v = Noisev3v2 (q);
    t += pow (abs (v.yz), vec2 (5. - 0.5 * float (j))) - smoothstep (0., 1., v.yz);
    f += wAmp * v.x / (1. + dot (t, t));
    wAmp *= - aWav * waFac;
    q *= fWav * qRot;
    waFac *= smFac;
  }
  b = 0.5 * (0.5 + clamp (f, -0.5, 1.5));
  return 3. * f / (b * b * (3. - 2. * b) + 0.5) + 2.;
}

float GrndDf (vec3 p)
{
  return p.y - hFac * ((grType <= 2) ? ((grType == 1) ? GrndHt1 (p.xz) : GrndHt2 (p.xz)) :
     ((grType == 3) ? GrndHt3 (p.xz) : GrndHt4 (p.xz)));
}

float GrndRay (vec3 ro, vec3 rd)
{
  float dHit, h, s, sLo, sHi;
  s = 0.;
  sLo = 0.;
  dHit = dstFar;
  for (int j = VAR_ZERO; j < 300; j ++) {
    h = GrndDf (ro + s * rd);
    if (h < 0.) break;
    sLo = s;
    s += stepFac * (max (0.4, 0.6 * h) + 0.008 * s);
    if (s > dstFar || j == stepLim) break;
  }
  if (h < 0.) {
    sHi = s;
    for (int j = VAR_ZERO; j < 5; j ++) {
      s = 0.5 * (sLo + sHi);
      if (GrndDf (ro + s * rd) > 0.) sLo = s;
      else sHi = s;
    }
    dHit = sHi;
  }
  return dHit;
}

float GrndDfN (vec3 p)
{
  return GrndDf (p) - 0.8 * Fbm2 (0.5 * p.xz);
}

vec3 GrndNf (vec3 p)
{
  vec4 v;
  vec2 e;
  e = vec2 (0.01, -0.01);
  for (int j = VAR_ZERO; j < 4; j ++) {
    v[j] = GrndDfN (p + ((j < 2) ? ((j == 0) ? e.xxx : e.xyy) : ((j == 2) ? e.yxy : e.yyx)));
  }
  v.x = - v.x;
  return normalize (2. * v.yzw - dot (v, vec4 (1.)));
}

float GrndSShadow (vec3 p, vec3 vs)
{
  vec3 q;
  float sh, d;
  sh = 1.;
  d = 0.4;
  for (int j = VAR_ZERO; j < 25; j ++) {
    q = p + vs * d; 
    sh = min (sh, smoothstep (0., 0.02 * d, GrndDf (q)));
    d += max (0.4, 0.1 * d);
    if (sh < 0.05) break;
  }
  return 0.5 + 0.5 * sh;
}

vec3 SkyBg (vec3 rd)
{
  return vec3 (0.2, 0.3, 0.55) + 0.25 * pow (1. - max (rd.y, 0.), 8.);
}

vec3 SkyCol (vec3 ro, vec3 rd)
{
  float f;
  ro.xz += 1.5 * tCur;
  f = Fbm2 (0.1 * (ro + rd * (50. - ro.y) / rd.y).xz);
  return mix (SkyBg (rd) + 0.35 * pow (max (dot (rd, sunDir), 0.), 16.),
     vec3 (0.85), clamp (1.6 * f * rd.y + 0.1, 0., 1.));
}

vec3 ShowScene (vec3 ro, vec3 rd)
{
  vec3 col, colW, vn, vnw, rdo;
  float dstGrnd, dstWat, f, spec, sh;
  bool isRefl;
  dstGrnd = GrndRay (ro, rd);
  isRefl = false;
  rdo = rd;
  dstWat = (rd.y < 0.) ? - (ro.y - htWat) / rd.y : dstFar;
  if (dstWat < min (dstGrnd, dstFar)) {
    ro += dstWat * rd;
    vnw = vec3 (0., 1., 0.);
    vnw = VaryNf (2. * ro + vec3 (0.1, 0., 0.05) * tCur, vnw, 0.1 * (1. -
       smoothstep (0.1, 0.4, dstWat / dstFar)));
    rd = reflect (rd, vnw);
    ro += 0.01 * rd;
    dstGrnd = (refType > 1) ? GrndRay (ro, rd) : dstFar;
    isRefl = true;
    col = mix (vec3 (0.1, 0.3, 0.4), vec3 (0.1, 0.25, 0.5),
       smoothstep (0.4, 0.6, Fbm2 (0.25 * ro.xz))) *
       (0.3 + 0.7 * (max (vnw.y, 0.) + 0.1 * pow (max (dot (sunDir, rd), 0.), 32.)));
    col = mix (col, SkyCol (ro, rd), 0.2 + 0.8 * pow (1. - abs (dot (rdo, vnw)), 2.));
    colW = col;
  } 
  if (dstGrnd < dstFar) {
    ro += dstGrnd * rd;
    vn = GrndNf (ro);
    f = 0.2 + 0.8 * smoothstep (0.35, 0.551, Fbm2 (1.7 * ro.xz));
    col = mix (mix (vec3 (0.2, 0.35, 0.1), vec3 (0.1, 0.3, 0.15), f),
       mix (vec3 (0.3, 0.25, 0.2), vec3 (0.35, 0.3, 0.3), f),
       smoothstep (1., 3., ro.y));
    col = mix (vec3 (0.4, 0.3, 0.2), col, smoothstep (0.2, 0.6, abs (vn.y)));
    col = mix (col, vec3 (0.75, 0.7, 0.7), smoothstep (5., 8., ro.y - 0.5 * htWat));
    col = mix (col, vec3 (0.9), smoothstep (7., 9., ro.y - 0.5 * htWat) *
       smoothstep (0., 0.5, abs (vn.y)));
    spec = mix (0.1, 0.5, smoothstep (8., 9., ro.y - 0.5 * htWat));
    sh = (shType > 1) ? GrndSShadow (ro, sunDir) : 1.;
    col *= 0.2 + 0.1 * vn.y + 0.8 * sh * max (0., max (dot (vn, sunDir), 0.)) +
       spec * step (0.95, sh) * sh * pow (max (dot (sunDir, reflect (rd, vn)), 0.), 32.);
    f = dstGrnd / dstFar;
    f *= f;
    col = mix (col, SkyBg (rd), clamp (f * f, 0., 1.));
    if (isRefl) col = mix (col, colW, pow (1. - abs (dot (rdo, vnw)), 5.));
  } else if (! isRefl) col = SkyCol (ro, rd);
  return clamp (col, 0., 1.);
}

vec4 ShowWg (vec2 uv, vec2 canvas, vec4 parmV1, vec4 parmV2, vec4 parmV3)
{
  vec4 wgBx[10];
  vec3 col, cc;
  vec2 ut, ust;
  float vW[10], asp, s;
  cc = vec3 (1., 0., 0.);
  asp = canvas.x / canvas.y;
  for (int k = 0; k < 6; k ++)
     wgBx[k] = vec4 (0.36 * asp, 0.25 - 0.06 * float (k), 0.12 * asp, 0.018);
  for (int k = 6; k < 10; k ++)
     wgBx[k] = vec4 ((0.29 + 0.05 * float (k - 6)) * asp, -0.25, 0.024, 0.024);
  vW[0] = parmV1.x;  vW[1] = parmV1.y;  vW[2] = parmV1.z;  vW[3] = parmV1.w;
  vW[4] = parmV2.x;  vW[5] = parmV2.y;
  vW[6] = parmV3.x;  vW[7] = parmV3.y;  vW[8] = parmV3.z;  vW[9] = parmV3.w;
  col = vec3 (0.);
  for (int k = 0; k < 6; k ++) {
    ut = 0.5 * uv - wgBx[k].xy;
    ust = abs (ut) - wgBx[k].zw;
    if (Maxv2 (ust) < 0.) col = cc.xxx * ((Minv2 (abs (ust)) * canvas.y < 2.) ? 0.3 :
       ((0.6 + 0.4 * smoothstep (0., 5., abs (mod (10. * ut.x / (2. * wgBx[k].z) + 0.5, 1.) -
       0.5) * canvas.y - 20.)) * 0.6));
    if (Maxv2 (ust) * canvas.y < 25.) {
      ut.x -= (vW[k] - 0.5) * 2. * wgBx[k].z;
      s = ShowInt (ut - vec2 (0.018, -0.01), 0.022 * vec2 (asp, 1.), 2.,
         clamp (floor (100. * vW[k]), 0., 99.));
      if (s > 0.) col = (k < 4) ? cc.yxy : ((k == 4) ? cc.yxx : cc.xyx);
      ut = abs (ut) * vec2 (1., 1.2);
      if (Maxv2 (abs (ut)) < 0.025 && Maxv2 (ut) > 0.02) col = cc.xxy;
    }
  }
  for (int k = 6; k < 10; k ++) {
    ut = 0.5 * uv - wgBx[k].xy;
    ust = abs (ut) - wgBx[k].zw;
    if (Maxv2 (ust) < 0.) {
      col = cc.xxx * ((Minv2 (abs (ust)) * canvas.y < 2.) ? 0.3 : 0.6);
      s = ShowInt (ut - vec2 (0.01, -0.01), 0.022 * vec2 (asp, 1.), 2., vW[k]);
      if (s > 0.) col = (k == 6) ? cc.yxy : ((k == 7) ? cc : ((k == 8) ? cc.yyx : cc.xxy));
    }
  }
  return vec4 (col, step (0.001, length (col)));
}

vec3 TrkPos (float t)
{
  return vec3 (20. * sin (0.07 * t) * sin (0.022 * t) * cos (0.018 * t) +
     13. * sin (0.0061 * t), 0., t);
}

void FlyerPM (float t, out vec3 flPos, out mat3 flMat)
{
  vec3 vel, acc, va, flVd, fpF, fpB;
  vec2 cs;
  float oRl, dt, vm;
  dt = 0.2;
  flPos = TrkPos (t);
  fpF = TrkPos (t + dt);
  fpB = TrkPos (t - dt);
  vel = (fpF - fpB) / (2. * dt);
  acc = (fpF - 2. * flPos + fpB) / (dt * dt);
  vm = length (vel);
  va = cross (acc, vel) / max (vm, 0.001);
  flVd = (vm > 0.) ? vel / vm : vec3 (0.);
  oRl = 2. * length (va) * sign (va.y);
  oRl = smoothstep (0.02, 0.05, abs (oRl)) * oRl;
  cs = sin (oRl + vec2 (0.5 * pi, 0.));
  flMat = mat3 (cs.x, - cs.y, 0., cs.y, cs.x, 0., 0., 0., 1.) *
     mat3 (flVd.z, 0., flVd.x, 0., 1., 0., - flVd.x, 0., flVd.z);
}

void mainImage (out vec4 fragColor, in vec2 fragCoord)
{
  mat3 flMat, vuMat;
  vec4 stDat, mPtr, wgBxC, parmV1, parmV2, parmV3, c4;
  vec3 ro, rd, col;
  vec2 canvas, uv, hSum;
  float el, az, zmFac, asp, dt, tCurM, mvTot, h;
  int wgSel, noInt;
  canvas = iResolution.xy;
  uv = 2. * fragCoord.xy / canvas - 1.;
  uv.x *= canvas.x / canvas.y;
  asp = canvas.x / canvas.y;
  parmV1 = Loadv4 (0);
  hFac = 1. + parmV1.x;
  fWav = 1.5 + 0.7 * parmV1.y;
  aWav = 0.1 + 0.5 * parmV1.z;
  smFac = 0.3 + 0.7 * parmV1.w;
  parmV2 = Loadv4 (1);
  htWat = 8. * parmV2.x;
  parmV3 = Loadv4 (2);
  grType = int (parmV3.x);
  qType = int (parmV3.y);
  shType = int (parmV3.z);
  refType = int (parmV3.w);
  stDat = Loadv4 (3);
  el = stDat.x;
  az = stDat.y;
  tCur = stDat.z;
  tCurM = stDat.w;
  stDat = Loadv4 (4);
  mvTot = stDat.x;
  noInt = int (stDat.y);
  stDat = Loadv4 (5);
  mPtr = vec4 (stDat.xyz, 0.);
  wgSel = int (stDat.w);
  if (qType == 1) {
    dstFar = 170.;
    stepLim = 100;
    stepFac = 1.;
  } else if (qType == 2) {
    dstFar = 220.;
    stepLim = 200;
    stepFac = 0.5;
  } else if (qType >= 3) {
    dstFar = 300.;
    stepLim = 300;
    stepFac = 0.33;
  }
  if (shType == 1) sunDir = normalize (vec3 (1., 2., -1.));
  else if (shType == 2) sunDir = normalize (vec3 (1., 1.5, -1.));
  else if (shType == 3) sunDir = normalize (vec3 (1., 1., -1.));
  FlyerPM (mvTot, ro, flMat);
  hSum = vec2 (0.);
  dt = 0.3;
  for (float k = -2.; k < 8.; k ++)
     hSum += vec2 (GrndDf (vec3 (TrkPos (mvTot + k * dt).xz, 0.).xzy), 1.);
  ro.y = max (4. * hFac - hSum.x / hSum.y, htWat + 6.);
  vuMat = StdVuMat (el, az);
  zmFac = 2.5;
  rd = vuMat * normalize (vec3 (2. * tan (0.5 * atan (uv.x / (asp * zmFac))) * asp * zmFac,
     uv.y, zmFac));
  rd = (vuMat * normalize (vec3 (uv, zmFac))) * flMat;
  col = (abs (uv.y) < 0.9) ? ShowScene (ro, rd) : vec3 (0.1);
  if (noInt > 0 || tCur - tCurM < 10.) {
    c4 = ShowWg (uv, canvas, parmV1, parmV2, parmV3);
    c4 = vec4 (mix (col, c4.rgb, c4.a),
       ((noInt > 0) ? 0.3 : 0.2 + 0.8 * smoothstep (9., 10., tCur - tCurM)));
  } else {
    wgBxC = vec4 (0.47 * asp, -0.4, 0.022, 0.);
    c4 = vec4 (0.7, 0.7, 0., 0.3 + 0.7 * smoothstep (1., 2.,
       abs (length (0.5 * uv - wgBxC.xy) - wgBxC.z) * canvas.y));
  }
  col = mix (c4.rgb, col, c4.a);
  if (mPtr.z > 0. && wgSel < 0) {
    if (Maxv2 (abs (uv)) < 0.05 && Minv2 (abs (uv)) < 0.005)
       col = mix (col, vec3 (1., 1., 0.1), 0.5);
  }
  fragColor = vec4 (col, 1.);
}

float DigSeg (vec2 q)
{
  q = 1. - smoothstep (vec2 (0.), vec2 (0.04, 0.07), abs (q) - vec2 (0.13, 0.5));
  return q.x * q.y;
}

#define DSG(q) k = kk;  kk = k / 2;  if (kk * 2 != k) d += DigSeg (q)

float ShowDig (vec2 q, int iv)
{
  vec2 vp, vm, vo;
  float d;
  int k, kk;
  vp = vec2 (0.5, 0.5);
  vm = vec2 (-0.5, 0.5);
  vo = vp - vm;
  if (iv == -1) k = 8;
  else if (iv < 2) k = (iv == 0) ? 119 : 36;
  else if (iv < 4) k = (iv == 2) ? 93 : 109;
  else if (iv < 6) k = (iv == 4) ? 46 : 107;
  else if (iv < 8) k = (iv == 6) ? 122 : 37;
  else             k = (iv == 8) ? 127 : 47;
  q = (q - 0.5) * vec2 (1.8, 2.3);
  d = 0.;
  kk = k;
  DSG (q.yx - vo);  DSG (q.xy - vp);  DSG (q.xy - vm);  DSG (q.yx);
  DSG (q.xy + vm);  DSG (q.xy + vp);  DSG (q.yx + vo);
  return d;
}

float ShowInt (vec2 q, vec2 cBox, float mxChar, float val)
{
  float nDig, idChar, s, sgn, v;
  q = vec2 (- q.x, q.y) / cBox;
  s = 0.;
  if (Minv2 (q) >= 0. && Maxv2 (q) < 1.) {
    q.x *= mxChar;
    sgn = sign (val);
    val = abs (val);
    nDig = (val > 0.) ? floor (max (log2 (val) / log2 (10.), 0.) + 0.001) + 1. : 1.;
    idChar = mxChar - 1. - floor (q.x);
    q.x = fract (q.x);
    v = val / pow (10., mxChar - idChar - 1.);
    if (idChar == mxChar - nDig - 1. && sgn < 0.) s = ShowDig (q, -1);
    if (idChar >= mxChar - nDig) s = ShowDig (q, int (mod (floor (v), 10.)));
  }
  return s;
}

float Minv2 (vec2 p)
{
  return min (p.x, p.y);
}

float Maxv2 (vec2 p)
{
  return max (p.x, p.y);
}

vec2 Rot2D (vec2 q, float a)
{
  vec2 cs;
  cs = sin (a + vec2 (0.5 * pi, 0.));
  return vec2 (dot (q, vec2 (cs.x, - cs.y)), dot (q.yx, cs));
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

const float cHashM = 43758.54;

vec2 Hashv2v2 (vec2 p)
{
  vec2 cHashVA2 = vec2 (37., 39.);
  return fract (sin (dot (p, cHashVA2) + vec2 (0., cHashVA2.x)) * cHashM);
}

vec4 Hashv4f (float p)
{
  return fract (sin (p + vec4 (0., 1., 57., 58.)) * cHashM);
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
  for (int j = 0; j < 5; j ++) {
    f += a * Noisefv2 (p);
    a *= 0.5;
    p *= 2.;
  }
  return f * (1. / 1.9375);
}

vec3 Noisev3v2 (vec2 p)
{
  vec4 h;
  vec3 g;
  vec2 ip, fp, ffp;
  ip = floor (p);
  fp = fract (p);
  ffp = fp * fp * (3. - 2. * fp);
  h = Hashv4f (dot (ip, vec2 (1., 57.)));
  g = vec3 (h.y - h.x, h.z - h.x, h.x - h.y - h.z + h.w);
  return vec3 (h.x + dot (g.xy, ffp) + g.z * ffp.x * ffp.y,
     30. * fp * fp * (fp * fp - 2. * fp + 1.) * (g.xy + g.z * ffp.yx));
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

#define txBuf iChannel0
#define txSize iChannelResolution[0].xy

const float txRow = 32.;

vec4 Loadv4 (int idVar)
{
  float fi;
  fi = float (idVar);
  return texture (txBuf, (vec2 (mod (fi, txRow), floor (fi / txRow)) + 0.5) / txSize);
}
