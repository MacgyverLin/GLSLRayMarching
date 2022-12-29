// "Book of the Woods" by dr2 - 2018
// License: Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License

float PrBoxDf (vec3 p, vec3 b);
float PrSphDf (vec3 p, float r);
float PrCylDf (vec3 p, float r, float h);
float SmootherStep (float a, float b, float x);
float SmoothMin (float a, float b, float r);
float SmoothBump (float lo, float hi, float w, float x);
float Maxv3 (vec3 p);
vec2 Rot2D (vec2 q, float a);
vec2 Rot2Cs (vec2 q, vec2 cs);
vec2 PixToHex (vec2 p);
vec2 HexToPix (vec2 h);
vec3 HexGrid (vec2 p);
void HexVorInit ();
vec4 HexVor (vec2 p);
vec3 HsvToRgb (vec3 c);
float Hashfv2 (vec2 p);
vec2 Hashv2v2 (vec2 p);
float Noisefv2 (vec2 p);
float Noisefv3 (vec3 p);
float Fbm2 (vec2 p);
vec3 VaryNf (vec3 p, vec3 n, float f);

#define DMIN(id) if (d < dMin) { dMin = d;  idObj = id; }
#define DMINQ(id) if (d < dMin) { dMin = d;  idObj = id;  qHit = q; }

vec3 sunDir, vuPos, qHit;
vec2 gId, trOff, imgSize;
float  dstFar, tCur, tCyc, tScene, tBgn, scAng, szFac, trSym, grHt, trRot, snowFac;
int idObj;
const int idTrnk = 1, idLv = 2, idRk = 3, idScnL = 4, idScnR = 5, idHng = 6;
const float pi = 3.14159, sqrt3 = 1.7320508;

vec2 TrackPathS (float t)
{
  return vec2 (dot (vec3 (1.9, 2.9, 4.3), sin (vec3 (0.23, 0.17, 0.13) * t)), t);
}

vec2 TrackPath (float t)
{
  return TrackPathS (t) + vec2 (dot (vec2 (0.07, 0.08), sin (vec2 (2.5, 3.3) * t)), 0.);
}

float GrndHt (vec2 p)
{
  float h, w;
  h = 0.35 + 0.17 * (sin (dot (p, vec2 (1., 1.4))) + sin (dot (p, vec2 (-1.2, 0.8))));
  w = abs (p.x - TrackPath (p.y).x) * (1.1 + 0.3 * sin (0.5 * p.y));
  h = h * SmootherStep (0.75, 1.5, w) - 0.05 * (1. - w * w / 0.64) * step (w, 0.8);
  return h;
}

float GrndRay (vec3 ro, vec3 rd)
{
  vec3 p;
  float dHit, h, s, sLo, sHi;
  s = 0.;
  sLo = 0.;
  dHit = dstFar;
  for (int j = 0; j < 150; j ++) {
    p = ro + s * rd;
    h = p.y - GrndHt (p.xz);
    if (h < 0.) break;
    sLo = s;
    s += max (0.02 * s, 0.3 * h);
    if (s > dstFar) break;
  }
  if (h < 0.) {
    sHi = s;
    for (int j = 0; j < 9; j ++) {
      s = 0.5 * (sLo + sHi);
      p = ro + s * rd;
      h = step (0., p.y - GrndHt (p.xz));
      sLo += h * (s - sLo);
      sHi += (1. - h) * (s - sHi);
    }
    dHit = sHi;
  }
  return dHit;
}

vec3 GrndNf (vec3 p)
{
  vec2 e;
  e = vec2 (0.01, 0.);
  return normalize (vec3 (GrndHt (p.xz) - vec2 (GrndHt (p.xz + e.xy), GrndHt (p.xz + e.yx)), e.x).xzy);
}

float ObjDfWd (vec3 p)
{
  vec3 q, qq;
  float dMin, d, ht;
  dMin = dstFar;
  p.xz -= HexToPix (gId) + trOff;
  if (szFac > 0.) {
    dMin /= szFac;
    p.xz = Rot2D (p.xz, trRot);
    p.y -= grHt - 0.1;
    p /= szFac;
    ht = 2.2;
    q = p;
    q.y -= ht;
    d = PrCylDf (q.xzy, 0.12 - 0.03 * q.y / ht, ht);
    qq = p;
    qq.xz = Rot2D (qq.xz, 2. * pi * (floor (trSym * atan (qq.z, - qq.x) / (2. * pi) +
       0.5) / trSym));
    q = qq;
    q.xy = Rot2D (q.xy - vec2 (-0.2, 0.3), -0.3 * pi);
    d = SmoothMin (d, PrCylDf (q.yzx, 0.09 + 0.02 * q.x / 0.6, 0.6), 0.2);
    q = qq;
    q.xy = Rot2D (q.xy - vec2 (-0.2, 1.2 * ht), 0.3 * pi);
    d = SmoothMin (d, PrCylDf (q.yzx, 0.05 + 0.02 * q.x / 0.5, 0.5), 0.1);
    DMIN (idTrnk);
    q = p;
    q.y -= 2. * ht;
    d = PrSphDf (q, 1.);
    q.y -= 1.;
    d = SmoothMin (d, PrSphDf (q, 0.5), 0.5);
    q.xz = qq.xz;
    q.xy -= vec2 (-0.3, -2.);
    d = SmoothMin (d, PrSphDf (q, 0.6), 0.3);
    DMIN (idLv);
    dMin *= szFac;
  } else  if (szFac < 0.) {
    q = p;
    d = PrSphDf (q, - szFac * 0.15);
    DMIN (idRk);
  }
  return dMin;
}

void SetTrParms ()
{
  vec2 g, w;
  float s;
  szFac = 0.3 + 0.4 * Hashfv2 (17. * gId + 99.);
  trSym = floor (3. + 2.9 * Hashfv2 (19. * gId + 99.));
  w = Hashv2v2 (33. * gId);
  g = HexToPix (gId);
  s = abs (g.x - TrackPath (g.y).x);
  if (s < 0.5) {
    trOff = 0.25 * sqrt3 * w.x * vec2 (cos (2. * pi * w.y), sin (2. * pi * w.y));
    szFac *= -1.;
  } else if (s < 2.) {
    szFac = 0.;
  } else {
    trOff = max (0., 0.5 * sqrt3 - szFac) * w.x * vec2 (cos (2. * pi * w.y), sin (2. * pi * w.y));
    trRot = 0.6 * pi * (Hashfv2 (23. * gId + 99.) - 0.5);
    grHt = GrndHt (g + trOff);
  }
}

float ObjRayWd (vec3 ro, vec3 rd)
{
  vec3 vri, vf, hv, p;
  vec2 edN[3], pM, gIdP;
  float dHit, d, s;
  edN[0] = vec2 (1., 0.);
  edN[1] = 0.5 * vec2 (1., sqrt3);
  edN[2] = 0.5 * vec2 (1., - sqrt3);
  for (int k = 0; k < 3; k ++) edN[k] *= sign (dot (edN[k], rd.xz));
  vri = 1. / vec3 (dot (rd.xz, edN[0]), dot (rd.xz, edN[1]), dot (rd.xz, edN[2]));
  vf = 0.5 * sqrt3 - vec3 (dot (ro.xz, edN[0]), dot (ro.xz, edN[1]),
     dot (ro.xz, edN[2]));
  pM = HexToPix (PixToHex (ro.xz));
  gIdP = vec2 (-99.);
  dHit = 0.;
  for (int j = 0; j < 200; j ++) {
    hv = (vf + vec3 (dot (pM, edN[0]), dot (pM, edN[1]), dot (pM, edN[2]))) * vri;
    s = min (hv.x, min (hv.y, hv.z));
    p = ro + dHit * rd;
    gId = PixToHex (p.xz);
    if (gId.x != gIdP.x || gId.y != gIdP.y) {
      gIdP = gId;
      SetTrParms ();
    }
    d = ObjDfWd (p);
    if (dHit + d < s) {
      dHit += d;
    } else {
      dHit = s + 0.002;
      pM += sqrt3 * ((s == hv.x) ? edN[0] : ((s == hv.y) ? edN[1] : edN[2]));
    }
    if (d < 0.0005 || dHit > dstFar || p.y < 0. || p.y > 10.) break;
  }
  if (d >= 0.0005) dHit = dstFar;
  return dHit;
}

vec3 ObjNfWd (vec3 p)
{
  vec4 v;
  vec2 e = vec2 (0.0005, -0.0005);
  v = vec4 (ObjDfWd (p + e.xxx), ObjDfWd (p + e.xyy), ObjDfWd (p + e.yxy), ObjDfWd (p + e.yyx));
  return normalize (vec3 (v.x - v.y - v.z - v.w) + 2. * v.yzw);
}

float ObjSShadow (vec3 ro, vec3 rd)
{
  vec3 p;
  vec2 gIdP;
  float sh, d, h;
  sh = 1.;
  gIdP = vec2 (-99.);
  d = 0.01;
  for (int j = 0; j < 30; j ++) {
    p = ro + rd * d;
    gId = PixToHex (p.xz);
    if (gId.x != gIdP.x || gId.y != gIdP.y) {
      gIdP = gId;
      SetTrParms ();
    }
    h = ObjDfWd (p);
    sh = min (sh, smoothstep (0., 0.1 * d, h));
    d += clamp (h, 0.05, 0.5);
    if (sh < 0.05) break;
  }
  return 0.3 + 0.7 * sh;
}

vec3 SkyCol (vec3 rd)
{
  return mix (vec3 (0.1, 0.2, 0.4) + 0.2 * pow (1. - rd.y, 8.) +
     0.35 * pow (max (dot (rd, sunDir), 0.), 6.), vec3 (1.), clamp (0.1 + 0.8 * rd.y *
     Fbm2 (5. * rd.xz / max (rd.y, 0.001)), 0., 1.));
}

float WaterHt (vec2 p)
{
  mat2 qRot = mat2 (0.8, -0.6, 0.6, 0.8);
  vec4 t4, v4;
  vec2 t;
  float wFreq, wAmp, ht, tWav;
  tWav = 0.5 * tScene;
  wFreq = 1.;
  wAmp = 1.;
  ht = 0.;
  for (int j = 0; j < 3; j ++) {
    p *= qRot;
    t = tWav * vec2 (1., -1.);
    t4 = (p.xyxy + t.xxyy) * wFreq;
    t = vec2 (Noisefv2 (t4.xy), Noisefv2 (t4.zw));
    t4 += 2. * t.xxyy - 1.;
    v4 = (1. - abs (sin (t4))) * (abs (sin (t4)) + abs (cos (t4)));
    ht += wAmp * dot (pow (1. - sqrt (v4.xz * v4.yw), vec2 (8.)), vec2 (1.));
    wFreq *= 2.;
    wAmp *= 0.5;
  }
  return ht;
}

vec3 WaterNf (vec3 p)
{
  vec3 vn;
  vec2 e = vec2 (0.05, 0.);
  vn.xz = 0.002 * (WaterHt (p.xz) - vec2 (WaterHt (p.xz + e.xy), WaterHt (p.xz + e.yx)));
  vn.y = e.x;
  return normalize (vn);
}

vec3 ShowSceneWd (vec3 ro, vec3 rd)
{
  vec4 vc;
  vec3 col, c1, c2, rbCol, fCol, wCol, snCol, vn, vnw, rog, rdo;
  vec2 vf;
  float dstObj, dstGrnd, dstWat, sh, spec, s, h1, h2, glit;
  bool isRefl, isSky;
  isRefl = false;
  isSky = false;
  spec = 0.;
  HexVorInit ();
  dstGrnd = GrndRay (ro, rd);
  dstObj = ObjRayWd (ro, rd);
  dstWat = (rd.y < 0.) ? - ro.y / rd.y : dstFar;
  rdo = rd;
  rog = ro + dstGrnd * rd;
  if (dstWat < min (min (dstGrnd, dstObj), dstFar)) {
    ro += dstWat * rd;
    vnw = WaterNf (8. * ro);
    rd = reflect (rd, vnw);
    ro += 0.01 * rd;
    dstGrnd = GrndRay (ro, rd);
    dstObj = ObjRayWd (ro, rd);
    isRefl = true;
  }
  vf = vec2 (0.);
  if (min (dstGrnd, dstObj) < dstFar) {
    snCol = vec3 (0.9, 0.9, 0.95);
    if (dstObj < dstGrnd) {
      ro += dstObj * rd;
      vn = ObjNfWd (ro);
      gId = PixToHex (ro.xz);
      h1 = Hashfv2 (gId * vec2 (17., 27.) + 0.5);
      h2 = Hashfv2 (gId * vec2 (19., 29.) + 0.5);
      if (idObj == idTrnk) {
        fCol = HsvToRgb (vec3 (0.1 * h1, 0.5, 0.4 - 0.2 * h2));
        wCol = mix (snCol, mix (fCol, snCol, smoothstep (0.01, 0.2, vn.y)),
           smoothstep (0.1 * szFac, 0.3 * szFac, ro.y - GrndHt (HexToPix (gId))));
        vf = vec2 (32., 2.);
      } else if (idObj == idLv) {
        fCol = HsvToRgb (vec3 (0.2 + 0.2 * h1, 0.7, 0.8 - 0.4 * h2)) *
           (1. - 0.2 * Noisefv3 (64. * ro));
        spec = 0.1;
        wCol = mix (0.6 * fCol, snCol, 0.2 + 0.8 * smoothstep (-0.8, -0.6, vn.y));
        vf = vec2 (16., mix (4., 16., 1. - snowFac));
      } else if (idObj == idRk) {
        fCol = mix (vec3 (0.4, 0.3, 0.3), vec3 (0.3, 0.4, 0.5), Fbm2 (16. * ro.xz));
        spec = 0.1;
        wCol = mix (fCol, snCol, 0.2 + 0.8 * smoothstep (0.1, 0.3, vn.y));
        vf = vec2 (8., 8.);
      }
    } else if (dstGrnd < dstFar) {
      ro += dstGrnd * rd;
      gId = PixToHex (ro.xz);
      SetTrParms ();
      vn = GrndNf (ro);
      vf = vec2 (8., 4.);
      if (snowFac < 1.) {
        c1 = mix (vec3 (0.1, 0.2, 0.15), vec3 (0.2, 0.4, 0.2),
           smoothstep (0.3, 0.5, Fbm2 (8. * ro.xz)));
        if (szFac > 0.) c1 = mix (vec3 (0.15, 0.05, 0.1), c1, 0.2 + 0.8 *
           smoothstep (0.4 * szFac, 0.7 * szFac, length (ro.xz - HexToPix (gId) - trOff)));
        c1 *= (1. - 0.2 * Noisefv2 (128. * ro.xz));
        c2 = vec3 (0.3, 0.3, 0.35) * (1. - 0.2 * Noisefv2 (256. * ro.zy));
        fCol = mix (c2, mix (c2, c1, smoothstep (0.4, 0.7, vn.y)),
           smoothstep (0., 0.005 * Noisefv2 (128. * ro.xz), ro.y));
      } else fCol = vec3 (0.);
      wCol = vec3 (0.8, 0.8, 0.85);
    }
    col = mix (fCol, wCol, snowFac);
    if (vf.x > 0.) vn = VaryNf (vf.x * ro, vn, vf.y);
    sh = ObjSShadow (ro, sunDir);
    col = col * (0.1 + 0.1 * max (dot (normalize (- sunDir.xz), vn.xz), 0.) +
       0.1 * max (vn.y, 0.) + 0.8 * sh * max (dot (vn, sunDir), 0.)) +
       sh * spec * pow (max (dot (normalize (sunDir - rd), vn), 0.), 64.);
    if (snowFac > 0. && dstGrnd < dstObj) {
      glit = 64. * step (0.01, max (0., dot (vn, sunDir))) *
         pow (max (0., dot (sunDir, reflect (rd, vn))), 16.) *
         pow (1. - 0.6 * abs (dot (normalize (sunDir - rd), VaryNf (512. * ro, vn, 8.))), 8.);
      col += vec3 (1., 1., 0.8) * smoothstep (0.6, 0.9, snowFac) * step (0.5, sh) * glit;
    }
  } else {
    col = SkyCol (rd);
    isSky = true;
  }
  if (isRefl) {
    vc = HexVor (128. * rog.xz);
    vn = normalize (vec3 (-0.7 * vc.yz, 1.).xzy);
    s = mod (10. * vc.w, 1.);
    sh = ObjSShadow (rog, sunDir);
    rbCol = HsvToRgb (vec3 (0.1 + 0.3 * step (2. * s, 1.) + 0.1 * mod (5. * s, 1.),
       0.2 + 0.2 * mod (17. * s, 1.), 0.2 + 0.2 * mod (12. * s, 1.))) *
       (0.5 + 0.3 * smoothstep (0., 0.2, vc.x)) * (1. - 0.2 * Noisefv2 (128. * rog.xz));
    rbCol = rbCol * (0.2 + 0.1 * max (vn.y, 0.) + 0.7 * sh * max (dot (vn, sunDir), 0.)) +
       sh * 0.1 * pow (max (dot (normalize (sunDir - rdo), vn), 0.), 64.);
    col = mix (rbCol, 0.95 * col, 1. - 0.9 * pow (dot (- rdo, vnw), 2.));
    if (isSky) col = mix (col, 1.5 * vec3 (1., 1., 0.9), sh *
       pow (max (0., dot (sunDir, reflect (rdo, vnw))), 2048.));
  }
  return clamp (col, 0., 1.);
}

float ObjDf (vec3 p)
{
  vec3 q;
  float dMin, d, dz;
  dMin = dstFar;
  dz = imgSize.x * sin (scAng);
  q = p;  q.z -= dz;
  q.xz = Rot2D (q.xz, scAng);
  q.xz -= vec2 (imgSize.x + 0.1, 0.05);
  d = max (PrBoxDf (q, vec3 (imgSize + 0.09, 0.05)), - PrBoxDf (q + vec3 (0., 0., 0.02), vec3 (imgSize + 0.02, 0.04)));
  DMINQ (idScnR);
  q = p;  q.z -= dz;
  q.xz = Rot2D (q.xz, - scAng);
  q.xz -= vec2 (- imgSize.x - 0.1, 0.05);
  d = max (PrBoxDf (q, vec3 (imgSize + 0.09, 0.05)), - PrBoxDf (q + vec3 (0., 0., 0.02), vec3 (imgSize + 0.02, 0.04)));
  DMINQ (idScnL);
  q = p;  q.z -= dz;
  d = PrCylDf (q.xzy, 0.05, imgSize.y + 0.1);
  DMINQ (idHng);
  return dMin;
}

float ObjRay (vec3 ro, vec3 rd)
{
  float dHit, d;
  dHit = 0.;
  for (int j = 0; j < 150; j ++) {
    d = ObjDf (ro + rd * dHit);
    if (d < 0.0005 || dHit > dstFar) break;
    dHit += d;
  }
  return dHit;
}

vec3 ObjNf (vec3 p)
{
  vec4 v;
  vec2 e = vec2 (0.0001, -0.0001);
  v = vec4 (ObjDf (p + e.xxx), ObjDf (p + e.xyy), ObjDf (p + e.yxy), ObjDf (p + e.yyx));
  return normalize (vec3 (v.x - v.y - v.z - v.w) + 2. * v.yzw);
}

vec3 ShowImg (vec2 w, float phs, bool isCov)
{
  mat3 vuMat;
  vec3 ro, rd, vuPos, col;
  vec2 ori, ca, sa, vd;
  float az, el, vel, a, tt;
  vel = 0.7;
  tScene = tCur + phs * tCyc;
  if (isCov) tScene = tBgn;
  snowFac = SmoothBump (0.25, 0.75, 0.05, mod (0.5 * tScene / tCyc, 1.));
  vuPos.xz = TrackPathS (vel * tScene);
  vuPos.y = 0.6;
  ro = vuPos;
  vd = TrackPathS (vel * (tScene + 0.2)) - vuPos.xz;
  az = atan (vd.x, vd.y);
  el = 0.;
  a = 0.45 * pi * SmoothBump (0.3, 0.7, 0.1, 0.1 * mod (tScene, 0.25 * tCyc));
  tt = mod (tScene / tCyc, 1.);
  if (tt < 0.25) az += a;
  else if (tt < 0.5) az -= a;
  else if (tt < 0.75) el = -0.4 * a;
  ori = vec2 (el, az);
  ca = cos (ori);
  sa = sin (ori);
  vuMat = mat3 (ca.y, 0., - sa.y, 0., 1., 0., sa.y, 0., ca.y) *
          mat3 (1., 0., 0., 0., ca.x, - sa.x, 0., sa.x, ca.x);
  rd = vuMat * normalize (vec3 (w, 1.6));
  sunDir = normalize (vec3 (1., 1.5, 0.3));
  col = ShowSceneWd (ro, rd);
  if (isCov) col = pow (vec3 (1., 1., 0.5) * Maxv3 (col), vec3 (0.9));
  else col = pow (col, vec3 (0.6));
  return col;
}

vec3 ShowScene (vec3 ro, vec3 rd)
{
  vec3 col, vn, sunDirB;
  vec2 w;
  float dstObj, spec;
  bool isImg, isCov;
  sunDirB = sunDir;
  dstObj = ObjRay (ro, rd);
  if (dstObj < dstFar) {
    isImg = false;
    ro += dstObj * rd;
    vn = ObjNf (ro);
    if (idObj == idScnL || idObj == idScnR) {
      if (abs (qHit.x) < imgSize.x && abs (qHit.y) < imgSize.y && vn.z < 0.) {
        isImg = true;
        isCov = false;
        w = qHit.xy / imgSize.x;
      } else if (idObj == idScnL && abs (qHit.x) < 0.5 * imgSize.x && abs (qHit.y) < 0.5 * imgSize.y) {
        isImg = true;
        isCov = true;
        w = qHit.xy / (0.5 * imgSize.x);
      } else {
        col = vec3 (0.4, 0.2, 0.1) * ((abs (qHit.x) < imgSize.x + 0.08 && 
           abs (qHit.y) < imgSize.y + 0.08) ? 1. - 0.5 * Fbm2 (16. * qHit.xy) : 0.7);
        spec = 0.1;
      }
      if (isImg) col = ShowImg (w, ((idObj == idScnL) ? 3. : 0.), isCov);
    } else if (idObj == idHng) {
      col = vec3 (0.6, 0.6, 0.) * (0.1 + 0.9 * SmoothBump (0.03, 0.97, 0.01, mod (8. * qHit.y + 0.5, 1.)));
      spec = 0.3;
    }
    if (! isImg) col = col * (0.3 + 0.7 * max (dot (vn, sunDirB), 0.)) +
       spec * pow (max (dot (sunDirB, reflect (rd, vn)), 0.), 32.);
    else if (isCov) col += 0.3 * pow (max (dot (sunDirB, reflect (rd, vn)), 0.), 32.);
  } else {
    col = vec3 (0.3, 0.3, 0.35) * (0.2 + 0.2 * (rd.y + 1.) * (rd.y + 1.));
  }
  return clamp (col, 0., 1.);
}

void mainImage (out vec4 fragColor, vec2 fragCoord)
{
  mat3 vuMat;
  vec4 mPtr, dateCur;
  vec3 ro, rd, col;
  vec2 canvas, uv, uvs, ori, ca, sa;
  float el, az, a;
 canvas = iResolution.xy;
  uv = 2. * fragCoord.xy / canvas - 1.;
  uvs = uv;
  uv.x *= canvas.x / canvas.y;
  tCur = iTime;
  dateCur = iDate;
  mPtr = iMouse;
  mPtr.xy = mPtr.xy / canvas - 0.5;
  tCyc = 40.;
  tBgn = floor (floor (dateCur.w / 600.) / (2. * tCyc)) * 2. * tCyc;
  scAng = 0.5 * pi * (1. - SmoothBump (0.15, 0.85, 0.1, mod (0.03 * tCur, 1.)));
  tCur = mod (tCur, 36000.) + tBgn;
  if (canvas.x < 255.) scAng = 0.4 * pi + 0.2 * scAng;
  imgSize = vec2 (1.6, 0.9);
  el = 0.;
  az = 0.;
  if (mPtr.z > 0.) {
    az += 2. * pi * mPtr.x;
    el += pi * mPtr.y;
  }
  ro = vec3 (0., 0., -8.);
  ori = vec2 (el, az);
  ca = cos (ori);
  sa = sin (ori);
  vuMat = mat3 (ca.y, 0., - sa.y, 0., 1., 0., sa.y, 0., ca.y) *
          mat3 (1., 0., 0., 0., ca.x, - sa.x, 0., sa.x, ca.x);
  a = - scAng * smoothstep (0.2 * pi, 0.5 * pi, scAng);
  ro = vuMat * ro;
  rd = vuMat * normalize (vec3 (uv, 4. - 2. * a / pi));
  ro.xz = Rot2D (ro.xz, a);
  rd.xz = Rot2D (rd.xz, a);
  sunDir = vuMat * normalize (vec3 (-0.7, 0.3, -1.));
  sunDir.xz = Rot2D (sunDir.xz, a);
  dstFar = 80.;
  col = ShowScene (ro, rd);
  uvs *= uvs * uvs;
  col *= mix (0.8, 1., pow (1. - 0.5 * length (uvs * uvs), 4.));
  fragColor = vec4 (col, 1.);
}

float PrBoxDf (vec3 p, vec3 b)
{
  vec3 d;
  d = abs (p) - b;
  return min (max (d.x, max (d.y, d.z)), 0.) + length (max (d, 0.));
}

float PrSphDf (vec3 p, float r)
{
  return length (p) - r;
}

float PrCylDf (vec3 p, float r, float h)
{
  return max (length (p.xy) - r, abs (p.z) - h);
}

float SmoothMin (float a, float b, float r)
{
  float h;
  h = clamp (0.5 + 0.5 * (b - a) / r, 0., 1.);
  return mix (b, a, h) - r * h * (1. - h);
}

float SmoothBump (float lo, float hi, float w, float x)
{
  return (1. - smoothstep (hi - w, hi + w, x)) * smoothstep (lo - w, lo + w, x);
}

float SmootherStep (float a, float b, float x)
{
  x = clamp ((x - a) / (b - a), 0., 1.); 
  return ((6. * x - 15.) * x + 10.) * x * x * x;
}

float Maxv3 (vec3 p)
{
  return max (p.x, max (p.y, p.z));
}

vec2 Rot2D (vec2 q, float a)
{
  return q * cos (a) * vec2 (1., 1.) + q.yx * sin (a) * vec2 (-1., 1.);
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

vec3 HexGrid (vec2 p)
{
  vec2 q;
  p -= HexToPix (PixToHex (p));
  q = abs (p);
  return vec3 (p, 0.5 * sqrt3 - q.x + 0.5 * min (q.x - sqrt3 * q.y, 0.));
}

vec2 gVec[7], hVec[7];

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

vec3 HsvToRgb (vec3 c)
{
  vec3 p;
  p = abs (fract (c.xxx + vec3 (1., 2./3., 1./3.)) * 6. - 3.);
  return c.z * mix (vec3 (1.), clamp (p - 1., 0., 1.), c.y);
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
  vec3 g;
  vec2 e = vec2 (0.1, 0.);
  g = vec3 (Fbmn (p + e.xyy, n), Fbmn (p + e.yxy, n), Fbmn (p + e.yyx, n)) - Fbmn (p, n);
  return normalize (n + f * (g - n * dot (n, g)));
}
