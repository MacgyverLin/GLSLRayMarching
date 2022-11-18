// "Backlit Lighthouse" by dr2 - 2017
// License: Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License

float PrBox2Df (vec2 p, vec2 b);
float PrCylDf (vec3 p, float r, float h);
float PrCylAnDf (vec3 p, float r, float w, float h);
void HexVorInit ();
vec4 HexVor (vec2 p);
float SmoothMin (float a, float b, float r);
float SmoothMax (float a, float b, float r);
float SmoothBump (float lo, float hi, float w, float x);
vec2 Rot2D (vec2 q, float a);
float Hashfv2 (vec2 p);
vec2 Hashv2v2 (vec2 p);
float Noisefv2 (vec2 p);
float Noisefv3 (vec3 p);
float Fbm1 (float p);
float Fbm2 (vec2 p);
float Fbm3 (vec3 p);
float Fbm3s (vec3 p);
vec3 VaryNf (vec3 p, vec3 n, float f);

vec3 sunDir, qHit, dispCloud;
float dstFar, tCur, tWav, bmAng, bmHt, twBase, twRad;
int idObj;
const int idTwr = 1, idWfrm = 2, idTtop = 3, idFlr = 4, idLmp = 5, idBm = 6, idGrnd = 7;
const float pi = 3.14159;

#define TOWER_DIAM  (twRad - (0.05 + 0.25 * (step (q.y, - twBase))) * (q.y + twBase))

float ObjDf (vec3 p)
{
  vec4 vc;
  vec3 q;
  float dMin, d, a, r, h, db, dw, ww;
  dMin = dstFar;
  q = p;  q.y -= twBase + 4.;
  r = TOWER_DIAM;
  d = PrCylAnDf (q.xzy, r, 0.2, 8.);
  dw = PrCylAnDf (q.xzy, r + 0.1, 0.3, 8.);
  db = 6. - abs (q.y - 2.);
  a = (length (q.xz) > 0.) ? atan (q.z, - q.x) : 0.;
  q.xz = Rot2D (q.xz, 2. * pi * (floor (5. * a / (2. * pi) + 0.5) / 5.));
  q.y = mod (q.y + 1.2, 3.) - 1.5;
  ww = 0.5;
  d = 0.9 * max (d, - max (min (PrBox2Df (q.zy, vec2 (ww)), length (vec2 (q.z, q.y - ww)) - ww), - db));
  if (d < dMin) { dMin = d;  idObj = idTwr; }
  dw = 0.9 * max (dw, max (- db, max (min (PrBox2Df (q.zy, vec2 (ww + 0.05)),
     length (vec2 (q.z, q.y - ww - 0.05)) - ww - 0.05), - min (PrBox2Df (q.zy, vec2 (ww - 0.05)),
     length (vec2 (q.z, q.y - ww + 0.05)) - ww + 0.05))));
  if (dw < dMin) { dMin = dw;  idObj = idWfrm; }
  q.y = mod (p.y - 5.5, 3.) - 1.5;
  d = max (PrCylDf (q.xzy, twRad - 0.4, 0.05), - db);
  if (d < dMin) { dMin = d;  idObj = idFlr; }
  q = p;  q.y -= bmHt;
  d = PrCylAnDf (q.xzy, twRad - 0.5, 0.2, 1.);
  q.xz = Rot2D (q.xz, 2. * pi * (floor (20. * a / (2. * pi) + 0.5) / 20.));
  d = max (d, - PrBox2Df (q.zy, vec2 (0.3, 0.75)));
  q = p;  q.y = abs (q.y - bmHt) - 1.1;
  d = min (d, PrCylDf (q.xzy, twRad + 0.1, 0.1));
  if (d < dMin) { dMin = d;  idObj = idTtop; }
  q = p;  q.y -= bmHt;
  q.xz = Rot2D (q.xz, bmAng);
  d = PrCylAnDf (q, 0.8, 0.03, 0.21);
  if (d < dMin) { dMin = d;  idObj = idLmp; }
  d = PrCylDf (q, 0.77, 0.2);
  if (d < dMin) { dMin = d;  idObj = idBm; }
  if (PrCylDf ((p + vec3 (0., -2., 0.)).xzy, 10., 2.) < dMin) {
    vc = HexVor (0.5 * p.xz);
    h = 1.5 * max (SmoothMin (0.6, SmoothMax (0., vc.x, 0.6), 0.3) *
       (1. + vc.w) * (1. - dot (vc.yz, vc.yz)), 0.) + 3.;
    d = 0.5 * (p.y - h * (1. - 0.01 * dot (p.xz, p.xz)));
    if (d < dMin) { dMin = d;  idObj = idGrnd; }
  }
  return dMin;
}

float ObjRay (vec3 ro, vec3 rd)
{
  float dHit, d;
  dHit = 0.;
  for (int j = 0; j < 120; j ++) {
    d = ObjDf (ro + dHit * rd);
    dHit += d;
    if (d < 0.0005 || dHit > dstFar) break;
  }
  return dHit;
}

vec3 ObjNf (vec3 p)
{
  vec4 v;
  vec2 e = vec2 (0.0005, -0.0005);
  v = vec4 (ObjDf (p + e.xxx), ObjDf (p + e.xyy), ObjDf (p + e.yxy), ObjDf (p + e.yyx));
  return normalize (vec3 (v.x - v.y - v.z - v.w) + 2. * v.yzw);
}

float TransObjDf (vec3 p)
{
  vec3 q;
  float dMin, d;
  dMin = dstFar;
  q = p;  q.y -= 8.;
  d = PrCylDf (q.xzy, TOWER_DIAM, 8.);
  q.y -= 9.;
  d = min (d, PrCylDf (q.xzy, twRad - 0.5, 1.));
  dMin = min (dMin, d);
  return dMin;
}

float TransObjRay (vec3 ro, vec3 rd)
{
  float dHit, d;
  dHit = 0.;
  for (int j = 0; j < 60; j ++) {
    d = TransObjDf (ro + dHit * rd);
    dHit += d;
    if (d < 0.0005 || dHit > dstFar) break;
  }
  return dHit;
}

vec3 TransObjNf (vec3 p)
{
  vec4 v;
  vec2 e = vec2 (0.0005, -0.0005);
  v = vec4 (TransObjDf (p + e.xxx), TransObjDf (p + e.xyy), TransObjDf (p + e.yxy), TransObjDf (p + e.yyx));
  return normalize (vec3 (v.x - v.y - v.z - v.w) + 2. * v.yzw);
}

float WaveHt (vec2 p)
{
  mat2 qRot = mat2 (0.8, -0.6, 0.6, 0.8);
  vec4 t4, v4;
  vec2 q, t, tw;
  float wFreq, wAmp, h;
  q = 0.5 * p + vec2 (0., tCur);
  h = 0.6 * sin (dot (q, vec2 (-0.05, 1.))) + 0.45 * sin (dot (q, vec2 (0.1, 1.2))) +
     0.3 * sin (dot (q, vec2 (-0.2, 1.4)));
  q = p;
  wFreq = 1.;
  wAmp = 1.;
  tw = tWav * vec2 (1., -1.);
  for (int j = 0; j < 3; j ++) {
    q *= qRot;
    t4 = q.xyxy * wFreq + tw.xxyy;
    t = vec2 (Noisefv2 (t4.xy), Noisefv2 (t4.zw));
    t4 += 2. * t.xxyy - 1.;
    v4 = (1. - abs (sin (t4))) * (abs (sin (t4)) + abs (cos (t4)));
    t = 1. - sqrt (v4.xz * v4.yw);
    t *= t;
    t *= t;
    h += wAmp * dot (t, t);
    wFreq *= 2.;
    wAmp *= 0.5;
  }
  return h;
}

vec3 WaveNf (vec3 p, float d)
{
  vec3 vn;
  vec2 e;
  e = vec2 (max (0.01, 0.005 * d * d), 0.);
  p *= 0.5;
  vn.xz = 0.5 * (WaveHt (p.xz) - vec2 (WaveHt (p.xz + e.xy),  WaveHt (p.xz + e.yx)));
  vn.y = e.x;
  return normalize (vn);
}

vec3 CloudCol (vec3 ro, vec3 rd)
{
  vec3 p, q, clCol, col, colS;
  float fCloud, cloudLo, cloudRngI, atFac, colSum, attSum, s, att, a, sd, ds;
  const int nLay = 60;
  cloudLo = 300.;  cloudRngI = 1./300.;  atFac = 0.015;
  fCloud = 0.7;
  colS = mix (vec3 (0.7, 0.75, 1.), vec3 (0.4, 0.38, 0.38), 1. - max (rd.y, 0.));
  col = colS;
  if (rd.y > 0.) {
    fCloud = clamp (fCloud, 0., 1.);
    p = ro + dispCloud;
    p.xz += (cloudLo - p.y) * rd.xz / rd.y;
    p.y = cloudLo;
    ds = 1. / (cloudRngI * rd.y * (2. - rd.y) * float (nLay));
    colSum = 0.;
    attSum = 0.;
    s = 0.;  
    att = 0.;
    for (int j = 0; j < nLay; j ++) {
      q = p + s * rd;
      att += atFac * max (fCloud - Fbm3 (vec3 (3., 4., 3.) * 0.003 * q), 0.);
      a = (1. - attSum) * att;
      colSum += a * (q.y - cloudLo) * cloudRngI;
      attSum += a;
      s += ds;
      if (attSum > 0.95) break;
    }
    sd = max (dot (rd, sunDir), 0.);
    colSum += min ((1. - attSum) * pow (sd, 3.), 1.);
    clCol = vec3 (0.9, 0.9, 1.) * (1.3 * colSum + 0.1);
    col = clamp (mix (colS + vec3 (0.4) * (pow (sd, 8.) + 0.5 * pow (sd, 512.)), clCol, attSum), 0., 1.);
    col = mix (col, colS, pow (1. - rd.y, 32.));
  }
  return col;
}

float CloudDens (vec3 ro, vec3 rd)
{
  vec3 p, q;
  float fCloud, cloudLo, cloudRngI, atFac,  attSum, s, att, a, ds;
  const int nLay = 60;
  cloudLo = 300.;  cloudRngI = 1./300.;  atFac = 0.018;
  fCloud = 0.7;
  if (rd.y > 0.) {
    fCloud = clamp (fCloud, 0., 1.);
    p = ro + dispCloud;
    p.xz += (cloudLo - p.y) * rd.xz / rd.y;
    p.y = cloudLo;
    ds = 1. / (cloudRngI * rd.y * (2. - rd.y) * float (nLay));
    attSum = 0.;
    s = 0.;  
    att = 0.;
    for (int j = 0; j < nLay; j += 6) {
      q = p + s * rd;
      att += atFac * max (fCloud - Fbm3s (vec3 (3., 4., 3.) * 0.003 * q), 0.);
      a = (1. - attSum) * att;
      attSum += a;
      s += ds;
      if (attSum > 0.95) break;
    }
  } else attSum = 0.;
  return clamp (1. - attSum, 0., 1.);
}

float GRayDens (vec3 ro, vec3 rd)
{
  vec3 p, q;
  float d, s, ds, sd, gDens;
  sd = 0.1 * smoothstep (0.6, 0.8, dot (rd, sunDir));
  gDens = 0.;
  if (sd > 0.) {
    p = ro + 100. * rd / max (rd.y, 0.05);
    ds = 5. / max (rd.y, 0.05);
    s = 0.;
    for (int j = 0; j < 16; j ++) {
      q = p + s * rd;
      gDens += sd * (1. - gDens) * smoothstep (0.8, 1., CloudDens (q, sunDir));
      s += ds;
      if (q.y > 400. || gDens > 0.95) break;
    }
  }
  return gDens;
}

vec3 BgCol (vec3 ro, vec3 rd)
{
  vec3 col;
  float a, g;
  g = 1.2 * GRayDens (ro, rd);
  a = atan (rd.x, - rd.z);
  if (rd.y < 0.02 * Fbm1 (32. * a) + 0.005) col = mix (vec3 (0.25, 0.25, 0.27),
     vec3 (0.3, 0.3, 0.33), 0.5 + 0.5 * dot (normalize (rd.xz), - normalize (sunDir.xz))) *
     (1. - 0.3 * Fbm2 (128. * vec2 (a, rd.y))) + vec3 (0.3, 0.2, 0.1) * g;
  else col = CloudCol (ro, rd) + vec3 (1., 0.8, 0.6) * g;
  return col;
}

vec3 ShStagGrid (vec2 p, vec2 g)
{
  vec2 q, sq, ss;
  q = p * g;
  if (2. * floor (0.5 * floor (q.y)) != floor (q.y)) q.x += 0.5;
  sq = smoothstep (0.05, 0.1, abs (fract (q + 0.5) - 0.5));
  q = fract (q) - 0.5;
  ss = 0.3 * smoothstep (0.3, 0.5, abs (q.xy)) * sign (q.xy);
  if (abs (q.x) < abs (q.y)) ss.x = 0.;
  else ss.y = 0.;
  return vec3 (ss.x, 0.8 + 0.2 * sq.x * sq.y, ss.y);
}

vec3 ShowScene (vec3 ro, vec3 rd)
{
  vec4 vc;
  vec3 vn, col, roo, rdo, vno, rob, rdb, rg;
  float dstObj, dstWat, dstTransObj, a;
  bool watRefl, winRefl, isBm;
  HexVorInit ();
  bmHt = 17.;
  twBase = 4.;
  twRad = 3.;
  tWav = 0.2 * tCur;
  dispCloud = tCur * vec3 (-15., 0., 5.);
  bmAng = tCur;
  winRefl = false;
  watRefl = false;
  isBm = false;
  rob = ro;
  rdb = rd;
  dstObj = ObjRay (ro, rd);
  dstWat = (rd.y < 0.) ? - ro.y / rd.y : dstFar;
  dstTransObj = TransObjRay (ro, rd);
  if (dstWat < min (dstObj, dstFar)) {
    watRefl = true;
    ro += dstWat * rd;
    vn = WaveNf (ro, dstWat);
    rd = reflect (rd, vn);
    ro += 0.01 * rd;
    dstObj = ObjRay (ro, rd);
  }
  if (dstTransObj < min (dstFar, dstObj)) {
    ro += rd * dstTransObj;
    roo = ro;
    rdo = rd;
    vno = TransObjNf (ro);
    winRefl = true;
    dstObj = ObjRay (ro, rd);
  }
  if (dstObj < dstFar) {
    ro += rd * dstObj;
    vn = ObjNf (ro);
    if (idObj == idTwr) {
      a = atan (ro.z, - ro.x) / (2. * pi);
      if (ro.y > twBase) {
        if (dot (normalize (ro.xz), vn.xz) > 0.9) {
          col = vec3 (0.9, 0.7, 0.5);
          col *= 0.5 + 0.5 * Fbm2 (vec2 (32. * a, 4. * ro.y));
          rg = ShStagGrid (vec2 (a, ro.y + 0.05), vec2 (30., 3.));
          col *= rg.y;
          if (rg.x == 0.) {
            vn.y += rg.z;
            vn.xz *= sqrt (1. - vn.y * vn.y);
          } else vn.xz = Rot2D (vn.xz, - rg.x);
        } else col = vec3 (0.4, 0.3, 0.2);
        vn = VaryNf (50. * ro, vn, 1.);
      } else {
        col = vec3 (1., 0.8, 0.2);
        col *= 0.7 * (0.5 + 0.5 * Fbm2 (vec2 (64. * a, 4. * ro.y)));
        vn = VaryNf (10. * ro, vn, 5.);
      }
    } else if (idObj == idGrnd) {
      vc = HexVor (ro.xz);
      vn = VaryNf (2. * ro, vn, 5.);
      col = 0.7 * mix (vec3 (1., 0.7, 0.2), vec3 (0.9, 0.8, 0.5),
         0.5 * Noisefv3 (8. * (1. + vc.w) * ro) + 0.5 * vc.w) * (0.7 + 0.3 * smoothstep (0., 0.4, ro.y));
    } else if (idObj == idFlr) {
      col = vec3 (0.5, 0.6, 0.3);
    } else if (idObj == idWfrm) {
      col = vec3 (0.6, 0.5, 0.4);
      vn = VaryNf (50. * ro, vn, 1.);
    } else if (idObj == idTtop) {
      col = vec3 (0.8, 0.7, 0.6);
      vn = VaryNf (50. * ro, vn, 1.);
    } else if (idObj == idLmp) {
      col = vec3 (0.5, 0.5, 0.6);
    } else if (idObj == idBm) {
      isBm = true;
      col = 1.2 * vec3 (1., 1., 0.9) * abs (dot (rd, vn));
    }
    if (! isBm) {
      col = col * (0.1 + 0.05 * max (dot (- normalize (sunDir.xz), normalize (vn.xz)), 0.) +
         0.8 * max (dot (sunDir, vn), 0.)) + 0.05 * pow (max (dot (normalize (sunDir - rd), vn), 0.), 64.);
      if (winRefl) col = mix (col, BgCol (roo, reflect (rdo, vno)), smoothstep (0.5, 0.95,
            1. - pow (abs (dot (- rdo, vno)), 5.)));
    }
  } else if (rd.y < 0.) {
    watRefl = true;
    dstWat = - ro.y / rd.y;
    ro += dstWat * rd;
    col = BgCol (ro, reflect (rd, WaveNf (ro, dstWat)));
  } else {
    col = BgCol (ro, rd);
  }
  if (watRefl) {
    col = mix (mix (vec3 (0.01, 0.01, 0.), vec3 (0., 0.05, 0.05),
       smoothstep (0.4, 0.6, Fbm2 (0.5 * ro.xz))), 0.5 * col, 1. - pow (abs (rd.y), 4.));
  }
  return clamp (col, 0., 1.);
}

void mainImage (out vec4 fragColor, in vec2 fragCoord)
{
  mat3 vuMat;
  vec4 mPtr;
  vec3 ro, rd;
  vec2 canvas, uv, ori, ca, sa;
  float el, az, zmFac;
  canvas = iResolution.xy;
  uv = 2. * fragCoord.xy / canvas - 1.;
  uv.x *= canvas.x / canvas.y;
  tCur = iTime;
  mPtr = iMouse;
  mPtr.xy = mPtr.xy / canvas - 0.5;
  dstFar = 100.;
  az = 0.;
  el = 0.;
  if (mPtr.z > 0.) {
    az += 3. * pi * mPtr.x;
    el += 0.5 * pi * mPtr.y;
  } else {
    az = 2. * pi * (2. * mod (floor (0.01 * tCur), 2.) - 1.) *
       SmoothBump (0.25, 0.75, 0.1, mod (0.01 * tCur, 1.));
  }
  el = clamp (el, -0.2 * pi, -0.01 * pi);
  ori = vec2 (el, az);
  ca = cos (ori);
  sa = sin (ori);
  vuMat = mat3 (ca.y, 0., - sa.y, 0., 1., 0., sa.y, 0., ca.y) *
          mat3 (1., 0., 0., 0., ca.x, - sa.x, 0., sa.x, ca.x);
  zmFac = 4.5 - 0.8 * cos (2. * az);
  rd = vuMat * normalize (vec3 (uv, zmFac));
  ro = vuMat * vec3 (0., 8., -70.);
  sunDir = normalize (vec3 (0.1, 0.5, 1.));
  fragColor = vec4 (ShowScene (ro, rd), 1.);
}

float PrBox2Df (vec2 p, vec2 b)
{
  vec2 d;
  d = abs (p) - b;
  return min (max (d.x, d.y), 0.) + length (max (d, 0.));
}

float PrCylDf (vec3 p, float r, float h)
{
  return max (length (p.xy) - r, abs (p.z) - h);
}

float PrCylAnDf (vec3 p, float r, float w, float h)
{
  return max (abs (length (p.xy) - r) - w, abs (p.z) - h);
}

vec2 gVec[7], hVec[7];
#define SQRT3 1.7320508

vec2 PixToHex (vec2 p)
{
  vec3 c, r, dr;
  c.xz = vec2 ((1./SQRT3) * p.x - (1./3.) * p.y, (2./3.) * p.y);
  c.y = - c.x - c.z;
  r = floor (c + 0.5);
  dr = abs (r - c);
  r -= step (dr.yzx, dr) * step (dr.zxy, dr) * dot (r, vec3 (1.));
  return r.xz;
}

vec2 HexToPix (vec2 h)
{
  return vec2 (SQRT3 * (h.x + 0.5 * h.y), (3./2.) * h.y);
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

vec4 HexVor (vec2 p)
{
  vec4 sd, udm;
  vec2 ip, fp, d, u;
  float amp, a;
  amp = 0.7;
  ip = PixToHex (p);
  fp = p - HexToPix (ip);
  sd = vec4 (4.);
  udm = vec4 (4.);
  for (int k = 0; k < 7; k ++) {
    u = Hashv2v2 (ip + gVec[k]);
    a = 2. * pi * (u.y - 0.5);
    d = hVec[k] + amp * (0.4 + 0.6 * u.x) * vec2 (cos (a), sin (a)) - fp;
    sd.w = dot (d, d);
    if (sd.w < sd.x) {
      sd = sd.wxyw;
      udm = vec4 (d, u);
    } else sd = (sd.w < sd.y) ? sd.xwyw : ((sd.w < sd.z) ? sd.xyww : sd);
  }
  sd.xyz = sqrt (sd.xyz);
  return vec4 (SmoothMin (sd.y, sd.z, 0.3) - sd.x, udm.xy, Hashfv2 (udm.zw));
}

float SmoothMin (float a, float b, float r)
{
  float h;
  h = clamp (0.5 + 0.5 * (b - a) / r, 0., 1.);
  return mix (b, a, h) - r * h * (1. - h);
}

float SmoothMax (float a, float b, float r)
{
  return - SmoothMin (- a, - b, r);
}

float SmoothBump (float lo, float hi, float w, float x)
{
  return (1. - smoothstep (hi - w, hi + w, x)) * smoothstep (lo - w, lo + w, x);
}

vec2 Rot2D (vec2 q, float a)
{
  return q * cos (a) + q.yx * sin (a) * vec2 (-1., 1.);
}

const float cHashM = 43758.54;

float Hashfv2 (vec2 p)
{
  return fract (sin (dot (p, vec2 (37., 39.))) * cHashM);
}

vec2 Hashv2f (float p)
{
  return fract (sin (p + vec2 (0., 1.)) * cHashM);
}

vec2 Hashv2v2 (vec2 p)
{
  vec2 cHashVA2 = vec2 (37., 39.);
  return fract (sin (vec2 (dot (p, cHashVA2), dot (p + vec2 (1., 0.), cHashVA2))) * cHashM);
}

vec4 Hashv4v3 (vec3 p)
{
  vec3 cHashVA3 = vec3 (37., 39., 41.);
  vec2 e = vec2 (1., 0.);
  return fract (sin (vec4 (dot (p + e.yyy, cHashVA3), dot (p + e.xyy, cHashVA3),
     dot (p + e.yxy, cHashVA3), dot (p + e.xxy, cHashVA3))) * cHashM);
}

float Noiseff (float p)
{
  vec2 t;
  float ip, fp;
  ip = floor (p);
  fp = fract (p);
  fp = fp * fp * (3. - 2. * fp);
  t = Hashv2f (ip);
  return mix (t.x, t.y, fp);
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

float Fbm1 (float p)
{
  float f, a;
  f = 0.;
  a = 1.;
  for (int i = 0; i < 5; i ++) {
    f += a * Noiseff (p);
    a *= 0.5;
    p *= 2.;
  }
  return f * (1. / 1.9375);
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

float Fbm3 (vec3 p)
{
  float f, a;
  f = 0.;
  a = 1.;
  for (int i = 0; i < 5; i ++) {
    f += a * Noisefv3 (p);
    a *= 0.5;
    p *= 2.;
  }
  return f * (1. / 1.9375);
}

float Fbm3s (vec3 p)
{
  float f, a;
  f = 0.;
  a = 1.;
  for (int i = 0; i < 3; i ++) {
    f += a * Noisefv3 (p);
    a *= 0.5;
    p *= 2.;
  }
  return f * (1. / 1.75);
}

float Fbmn (vec3 p, vec3 n)
{
  vec3 s;
  float a;
  s = vec3 (0.);  
  a = 1.;
  for (int i = 0; i < 4; i ++) {
    s += a * vec3 (Noisefv2 (p.yz), Noisefv2 (p.zx), Noisefv2 (p.xy));
    a *= 0.5;  
    p *= 2.;
  }
  return dot (s, abs (n));
}

vec3 VaryNf (vec3 p, vec3 n, float f)
{
  vec3 g;
  vec2 e = vec2 (0.1, 0.);
  g = vec3 (Fbmn (p + e.xyy, n), Fbmn (p + e.yxy, n), Fbmn (p + e.yyx, n)) - Fbmn (p, n);
  return normalize (n + f * (g - n * dot (n, g)));
}
