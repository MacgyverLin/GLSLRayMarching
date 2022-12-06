// "Train Ride" by dr2 - 2014
// License: Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License

// Borrows ideas and techniques published on Shadertoy.
// Thanks everyone for a great learning resource!!

const vec4 cHashA4 = vec4 (0., 1., 57., 58.);
const vec3 cHashA3 = vec3 (1., 57., 113.);
const float cHashM = 43758.54;

float Hashfv2 (vec2 p)
{
  return fract (sin (dot (p, cHashA3.xy)) * cHashM);
}

vec4 Hashv4f (float p)
{
  return fract (sin (p + cHashA4) * cHashM);
}

float Noisefv2 (vec2 p)
{
  vec2 i = floor (p);
  vec2 f = fract (p);
  f = f * f * (3. - 2. * f);
  vec4 t = Hashv4f (dot (i, cHashA3.xy));
  return mix (mix (t.x, t.y, f.x), mix (t.z, t.w, f.x), f.y);
}

float Noisefv3 (vec3 p)
{
  vec3 i = floor (p);
  vec3 f = fract (p);
  f = f * f * (3. - 2. * f);
  float q = dot (i, cHashA3);
  vec4 t1 = Hashv4f (q);
  vec4 t2 = Hashv4f (q + cHashA3.z);
  return mix (mix (mix (t1.x, t1.y, f.x), mix (t1.z, t1.w, f.x), f.y),
     mix (mix (t2.x, t2.y, f.x), mix (t2.z, t2.w, f.x), f.y), f.z);
}

vec3 Noisev3v2 (vec2 p)
{
  vec2 i = floor (p);
  vec2 f = fract (p);
  vec2 ff = f * f;
  vec2 u = ff * (3. - 2. * f);
  vec2 uu = 30. * ff * (ff - 2. * f + 1.);
  vec4 h = Hashv4f (dot (i, cHashA3.xy));
  return vec3 (h.x + (h.y - h.x) * u.x + (h.z - h.x) * u.y +
     (h.x - h.y - h.z + h.w) * u.x * u.y, uu * (vec2 (h.y - h.x, h.z - h.x) +
     (h.x - h.y - h.z + h.w) * u.yx));
}

float SmoothMin (float a, float b, float r)
{
  float h = clamp (0.5 + 0.5 * (b - a) / r, 0., 1.);
  return mix (b, a, h) - r * h * (1. - h);
}

vec3 RgbToHsv (vec3 c)
{
  vec4 p = mix (vec4 (c.bg, vec2 (-1., 2./3.)), vec4 (c.gb, vec2 (0., -1./3.)),
     step (c.b, c.g));
  vec4 q = mix (vec4 (p.xyw, c.r), vec4 (c.r, p.yzx), step (p.x, c.r));
  float d = q.x - min (q.w, q.y);
  const float e = 1.e-10;
  return vec3 (abs (q.z + (q.w - q.y) / (6. * d + e)), d / (q.x + e), q.x);
}

vec3 HsvToRgb (vec3 c)
{
  vec3 p = abs (fract (c.xxx + vec3 (1., 2./3., 1./3.)) * 6. - 3.);
  return c.z * mix (vec3 (1.), clamp (p - 1., 0., 1.), c.y);
}

vec3 BrickSurfCol (vec2 p) {
  vec2 q = p * (1. / 20.);
  vec2 i = floor (q);
  if (2. * floor (i.y / 2.) != i.y) {
    q.x += 0.5;
    i = floor (q);
  }
  q = smoothstep (0.015, 0.025, abs (fract (q + 0.5) - 0.5));
  return (1. + Noisefv2 (10. * p)) * (0.3 + 0.7 * q.x * q.y) *
     (0.3 + 0.2 * sin (2. * Hashfv2 (i) + vec3 (1., 1.2, 1.4)));
}

vec3 BrickCol (vec3 p, vec3 n)
{
  n = abs (n);
  p *= 150.;
  return BrickSurfCol (p.zy) * n.x + BrickSurfCol (p.xz) * n.y +
     BrickSurfCol (p.xy) * n.z;
}

float PrBoxDf (vec3 p, vec3 b)
{
  vec3 d = abs (p) - b;
  return min (max (d.x, max (d.y, d.z)), 0.) + length (max (d, 0.));
}

float PrOBoxDf (vec3 p, vec3 b)
{
  return length (max (abs (p) - b, 0.));
}

float PrCylDf (vec3 p, vec2 b)
{
  return max (length (p.xz) - b.x, abs (p.y) - b.y);
}

mat3 trainMat[5], trMat;
vec3 trainPos[5], trPos, qTrWin, sunDir, sunCol, moonDir, moonCol;
vec2 trkOffset;
float tCur, dirTrWin;
int idObj;
bool isNight;
const float dstFar = 250.;

vec3 TrackPath (float t)
{
  float y = 0.01 + sin (0.021 * t) * sin (1. + 0.023 * t);
  return vec3 (15. * sin (0.035 * t) * sin (0.012 * t) * cos (0.01 * t) +
     11. * sin (0.0032 * t) + 100. * trkOffset.x, 2. * y * y, t);
}

float GrndHt (vec2 p, int hiRes)
{
  const vec2 vRot = vec2 (1.4624, 1.6721);
  vec2 q = p * 0.06;
  float w = 0.75 * Noisefv2 (0.25 * q) + 0.15;
  w *= 36. * w;
  vec2 vyz = vec2 (0.);
  float ht = 0.;
  for (int j = 0; j < 10; j ++) {
    vec3 v = Noisev3v2 (q);
    vyz += v.yz;
    ht += w * v.x / (1. + dot (vyz, vyz));
    if (j == 4) {
      ht += 50. * pow (Noisefv2 (0.003 * q), 4.) - 1.;
      if (hiRes == 0) break;
    }
    w *= -0.37;      
    q *= mat2 (vRot.x, vRot.y, - vRot.y, vRot.x);
  }
  vec3 pt = TrackPath (p.y);
  pt.y += 0.07 * Noisefv2 (0.0001 * p) + 0.04 * Noisefv2 (2.1 * p) +
     0.03 * Noisefv2 (2.3 * p.yx);
  float g = smoothstep (4., 35., abs (p.x - pt.x));
  return SmoothMin (ht, pt.y * (1. - g) + ht * g, 0.5);
}

vec3 GrndNf (vec3 p, float d)
{
  float ht = GrndHt (p.xz, 1);
  vec2 e = vec2 (max (0.01, 0.00001 * d * d), 0.);
  return normalize (vec3 (ht - GrndHt (p.xz + e.xy, 1), e.x,
     ht - GrndHt (p.xz + e.yx, 1)));
}

vec4 GrndCol (vec3 p, vec3 n)
{
  const vec3 gCol1 = vec3 (0.6, 0.7, 0.7), gCol2 = vec3 (0.2, 0.1, 0.1),
     gCol3 = vec3 (0.4, 0.3, 0.3), gCol4 = vec3 (0.1, 0.2, 0.1),
     gCol5 = vec3 (0.7, 0.7, 0.8), gCol6 = vec3 (0.05, 0.3, 0.03),
     gCol7 = vec3 (0.02, 0.1, 0.02), gCol8 = vec3 (0.1, 0.08, 0.);
  vec2 q = p.xz;
  float f, d;
  float cSpec = 0.;
  f = 0.5 * (clamp (Noisefv2 (0.1 * q), 0., 1.) +
      0.8 * Noisefv2 (0.2 * q + 2.1 * n.xy + 2.2 * n.yz));
  vec3 col = f * mix (f * gCol1 + gCol2, f * gCol3 + gCol4, 0.65 * f);
  if (n.y < 0.5) {
    f = 0.4 * (Noisefv2 (0.4 * q + vec2 (0., 0.57 * p.y)) +
       0.5 * Noisefv2 (6. * q));
    d = 4. * (0.5 - n.y);
    col = mix (col, vec3 (f), clamp (d * d, 0.1, 1.));
    cSpec += 0.1;
  }
  if (p.y > 22.) {
    if (n.y > 0.25) {
      f = clamp (0.07 * (p.y - 22. - Noisefv2 (0.2 * q) * 15.), 0., 1.);
      col = mix (col, gCol5, f);
      cSpec += f;
    }
  } else {
    if (n.y > 0.45) {
      vec3 c = (n.y - 0.3) * (gCol6 * vec3 (Noisefv2 (0.4 * q),
         Noisefv2 (0.34 * q), Noisefv2 (0.38 * q)) + gCol7);
      col = mix (col, c, smoothstep (0.45, 0.65, n.y) *
         (1. - smoothstep (15., 22., p.y - 1.5 + 1.5 * Noisefv2 (0.2 * q))));
    }
    if (p.y < 0.65 && n.y > 0.4) {
      d = n.y - 0.4;
      col = mix (col, d * d + gCol8, 2. * clamp ((0.65 - p.y -
         0.35 * (Noisefv2 (0.4 * q) + 0.5 * Noisefv2 (0.8 * q) +
         0.25 * Noisefv2 (1.6 * q))), 0., 0.3));
      cSpec += 0.1;
    }
  }
  return vec4 (col, cSpec);
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
    h = p.y - GrndHt (p.xz, 0);
    if (h < 0.) break;
    sLo = s;
    s += max (0.15, 0.4 * h) + 0.008 * s;
    if (s > dstFar) break;
  }
  if (h < 0.) {
    sHi = s;
    for (int j = 0; j < 10; j ++) {
      s = 0.5 * (sLo + sHi);
      p = ro + s * rd;
      h = step (0., p.y - GrndHt (p.xz, 0));
      sLo += h * (s - sLo);
      sHi += (1. - h) * (s - sHi);
    }
    dHit = sHi;
  }
  return dHit;
}

float WaterHt (vec3 p)
{
  p *= 0.06;
  float ht = 0.;
  const float wb = 1.414;
  float w = 0.1 * wb;
  for (int j = 0; j < 7; j ++) {
    w *= 0.5;
    p = wb * vec3 (p.y + p.z, p.z - p.y, 2. * p.x);
    ht += w * abs (Noisefv3 (p) - 0.5);
  }
  return ht;
}

vec3 WaterNf (vec3 p, float d)
{
  float ht = WaterHt (p);
  vec2 e = vec2 (max (0.01, 0.001 * d * d), 0.);
  return normalize (vec3 (ht - WaterHt (p + e.xyy), e.x, ht - WaterHt (p + e.yyx)));
}

vec3 SkyBg (vec3 rd)
{
  const vec3 sbCol1 = vec3 (0.05, 0.05, 0.15), sbCol2 = vec3 (0.2, 0.25, 0.5);
  vec3 col;
  if (isNight) col = 0.3 * clamp (sbCol1 - 0.12 * rd.y * rd.y, 0., 1.);
  else col = sbCol2 + 0.2 * sunCol * pow (1. - max (rd.y, 0.), 5.);
  return col;
}

vec3 SkyCol (vec3 ro, vec3 rd)
{
  const vec3 sCol1 = vec3 (0.06, 0.04, 0.02), sCol2 = vec3 (0.03, 0.03, 0.06),
     mBrite = vec3 (-0.5, -0.4, 0.77);
  const float skyHt = 150.;
  vec3 col;
  float cloudFac;
  if (rd.y > 0.) {
    ro.x += 0.5 * tCur;
    vec2 p = 0.02 * (rd.xz * (skyHt - ro.y) / rd.y + ro.xz);
    float w = 0.8;
    float f = 0.;
    for (int j = 0; j < 4; j ++) {
      f += w * Noisefv2 (p);
      w *= 0.5;
      p *= 2.;
    }
    cloudFac = clamp (5. * (f - 0.4) * rd.y - 0.1, 0., 1.);
  } else cloudFac = 0.;
  if (isNight) {
    vec3 bgCol = SkyBg (rd) + sCol1 * pow (clamp (dot (rd, moonDir), 0., 1.), 30.);
    col = bgCol;
    const float moonRad = 0.04;
    vec3 vn;
    bool mHit = false;
    float bs = - dot (rd, moonDir);
    float cs = dot (moonDir, moonDir) - moonRad * moonRad;
    float ts = bs * bs - cs;
    if (ts > 0.) {
      ts = - bs - sqrt (ts);
      if (ts > 0.) {
        vn = normalize ((ts * rd - moonDir) / moonRad);
        mHit = true;
      }
    }
    if (mHit) {
      col += 1.4 * moonCol * clamp (dot (mBrite, vn) *
         (0.3 + Noisefv3 (5. * vn)), 0., 1.);
    } else {
      vec3 st = (rd + vec3 (1.));
      for (int j = 0; j < 10; j ++) {
        st = 11. * abs (st) / dot (st, st) - 3.;
      }
      col += min (1., 1.5e-6 * pow (min (16., length (st)), 4.5));
    }
    col = mix (col, sCol2, cloudFac) + bgCol;
  } else {
    float s = max (dot (rd, sunDir), 0.);
    col = SkyBg (rd) + sunCol * (0.35 * pow (s, 6.) +
       0.65 * min (pow (s, 256.), 0.3));
    col = mix (col, vec3 (0.55), cloudFac);
  }
  return col;
}

float TrainDf (vec3 p, float dHit, float dir)
{
  const float eRad = 0.25;
  vec3 q;
  float d;
  q = p;
  if (dir == 0.) {
    q.y -= 0.15;
    d = length (max (abs (q) - vec3 (0.42, 0.25, 0.95), 0.)) - eRad;
  } else {
    q.yz += vec2 (2.6, 0.7 * dir);
    d = length (vec4 (max (abs (q.x) - 0.45, 0.), max (2.5 - q.y, 0.),
       max (- q.z * dir, 0.),
       max (length (q.yz + vec2 (0., - 0.2 * dir)) - 3., 0.))) - eRad;
  }
  if (d < dHit) {
    dHit = d;  idObj = 21;
    if (dir == 0.) q.y -= 0.1;
    else q.y -= 2.85;
    qTrWin = abs (q);
    dirTrWin = dir;
  }
  q = vec3 (p.y + 0.32, abs (p.x) - 0.46, p.z + 0.4);
  vec2 ww = vec2 (0.12 - sign (q.y) * 0.02, 0.04);
  d = min (PrCylDf (q, ww), PrCylDf (q - vec3 (0., 0., 1.), ww));
  if (d < dHit) {
    dHit = d;  idObj = 22;
  }
  if (dir != 0.) {
    q = p;
    if (dir > 0.) {
      q.x = abs (q.x) - 0.2;
      q.yz += vec2 (0.2, -1.6);
      d = PrCylDf (q.xzy, vec2 (0.05, 0.1));
      if (d < dHit) {
        dHit = d;  idObj = 23;
      }
    } else {
      q.yz += vec2 (0.15, 1.6);
      d = PrCylDf (q.xzy, vec2 (0.07, 0.1));
      if (d < dHit) {
        dHit = d;  idObj = 24;
      }
    }
  }
  return dHit;
}

float RailDf (vec3 p, float dHit)
{
  vec2 w = vec2 (abs (p.x) - 0.5, p.y + 0.57);
  float d = min (length (max (abs (w - vec2 (0., 0.14)) - vec2 (0.02), 0.)),
     SmoothMin (length (max (abs (w - vec2 (0., 0.08)) - vec2 (0.01, 0.08), 0.)),
     length (max (abs (w - vec2 (0., -0.02)) - vec2 (0.04), 0.)), 0.06));
  if (d < dHit) {
    dHit = d;  idObj = 10;
  }
  vec3 q = vec3 (p.x, p.y + 0.7, mod (p.z, 2.4) - 1.2);
  d = PrOBoxDf (q, vec3 (0.75, 0.03, 0.15));
  if (d < dHit) {
    dHit = d;  idObj = 11;
  }
  return dHit;
}

float BridgeDf (vec3 p, float dHit, float hg)
{
  vec3 q = p;
  float d = max (abs (q.x) - 0.85, q.y + 0.68);
  q.y += 4.5;
  q.z = mod (q.z + 1.3, 2.6) - 1.3;
  d = max (max (d, - max (length (q.yz +
     vec2 (4. * clamp (q.y / 4., -0.5, 0.5), 0.)) - 5.5, abs (q.z) - 0.9)), - hg);
  if (d < dHit) {
    dHit = d;  idObj = 12;
  }
  return dHit;
}

float PlatformDf (vec3 p, float dHit, float hg)
{
  vec3 q = vec3 (p.x, p.y, mod (p.z, 150.) - 75.);
  vec3 qq = q + vec3 (-1.9, -0.4, 0.);
  float d = min (min (PrBoxDf (vec3 (abs (q.x) - 1.7, q.y + 0.5, q.z),
     vec3 (0.7, 0.05, 5.)), max (PrBoxDf (qq, vec3 (0.1, 0.7, 2.)),
     - PrBoxDf (qq, vec3 (0.15, 0.5, 1.5)))),
     max (PrCylDf (vec3 (abs (abs (q.x) - 1.7) - 0.4, q.y + 4.5, abs (q.z) - 4.4),
     vec2 (0.13, 4.)), - hg));
  if (d < dHit) {
    dHit = d;  idObj = 13;
  }
  d = PrCylDf (q + vec3 (-1.9, -1.2, 0.), vec2 (0.1, 0.06));
  if (d < dHit) {
    dHit = d;  idObj = 14;
  }
  return dHit;
}

float ObjDf (vec3 p)
{
  float dHit = dstFar;
  dHit = TrainDf (trainMat[0] * (p - trainPos[0]), dHit, -1.);
  dHit = TrainDf (trainMat[1] * (p - trainPos[1]), dHit, 0.);
  dHit = TrainDf (trainMat[2] * (p - trainPos[2]), dHit, 0.);
  dHit = TrainDf (trainMat[3] * (p - trainPos[3]), dHit, 0.);
  dHit = TrainDf (trainMat[4] * (p - trainPos[4]), dHit, 1.);
  float hg = p.y;
  p.xy -= TrackPath (p.z).xy;
  p.y -= 0.9;
  dHit = RailDf (p, dHit);
  dHit = BridgeDf (p, dHit, hg);
  dHit = PlatformDf (p, dHit, hg);
  return dHit;
}

float ObjRay (vec3 ro, vec3 rd)
{
  const float dTol = 0.001;
  float d;
  float dHit = 0.;
  for (int j = 0; j < 180; j ++) {
    d = ObjDf (ro + dHit * rd);
    dHit += d;
    if (d < dTol || dHit > dstFar) break;
  }
  return dHit;
}

vec3 ObjNf (vec3 p)
{
  const vec3 e = vec3 (0.001, -0.001, 0.);
  float v0 = ObjDf (p + e.xxx);
  float v1 = ObjDf (p + e.xyy);
  float v2 = ObjDf (p + e.yxy);
  float v3 = ObjDf (p + e.yyx);
  return normalize (vec3 (v0 - v1 - v2 - v3) + 2. * vec3 (v1, v2, v3));
}

vec4 ObjCol (vec3 p, vec3 n)
{
  vec3 col = vec3 (0.);
  float sp;
  float dkFac = 1.;
  if (idObj >= 10 && idObj <= 19) {
    sp = 0.;
    if (idObj == 10) {
      col = vec3 (0.3);
      sp = 1.;
    } else if (idObj == 11) {
      col = vec3 (0.12, 0.08, 0.04) * (1.5 + Noisefv2 (30. * p.xz));
    } else if (idObj == 12) {
      if (n.y > 0.9) col = vec3 (0.025) * (2. + Noisefv2 (15. * p.xz));
      else col = 0.1 * BrickCol (0.5 * p, n);
      dkFac = 0.4;
    } else if (idObj == 13) {
      p.xy -= TrackPath (p.z).xy;
      col = vec3 (0.26, 0.22, 0.2) * BrickCol (0.3 * p, n);
      dkFac = 0.2;
    } else if (idObj == 14) {
      if (isNight) col = vec3 (1., 0., 0.);
      else col = vec3 (0.7, 1., 0.7);
    }
  } else if (idObj >= 21 && idObj <= 29) {
    sp = 0.7;
    if (idObj == 21) {
      col = vec3 (0.7, 0.2, 0.2);
      dkFac = 0.02;
      sp = 0.7;
    } else if (idObj == 22) {
      col = vec3 (0.7, 0.3, 0.);
      dkFac = 0.1;
    } else if (idObj == 23) {
      col = vec3 (1., 0., 0.);
    } else if (idObj == 24) {
      if (isNight) col = vec3 (1.);
      else col = vec3 (1., 1., 0.);
    }
  }
  if (isNight) col *= dkFac;
  return vec4 (col, sp);
}

void TrainCarPM (float t)
{
  vec3 vp, vd, ve, vf;
  trPos = TrackPath (tCur + t);
  vp = TrackPath (tCur + t + 0.1) - trPos;
  vd = - normalize (vec3 (vp.x, 0., vp.z));
  ve = normalize (vec3 (0., vp.yz));
  trPos.y += 0.9;
  trMat = mat3 (vec3 (1., 0., 0.), vec3 (0., ve.z, - ve.y), ve) *
      mat3 (vec3 (- vd.z, 0., vd.x), vec3 (0., 1., 0.), vd);
}

vec3 ShowScene (vec3 ro, vec3 rd, vec2 vDir)
{
  const float eps = 0.01;
  vec4 col4;
  vec3 col, vn;
  float f;
  vec3 roo = ro;
  float dstHit = dstFar;
  float dstGrnd = GrndRay (ro, rd);
  idObj = 0;
  float dstObj = ObjRay (ro, rd);
  int idObjT = idObj;
  float refFac = 1.;
  if (dstGrnd < dstObj && ro.y + dstGrnd * rd.y < 0.) {
    float dw = - ro.y / rd.y;
    ro += dw * rd;
    rd = reflect (rd, WaterNf (ro, dw));
    ro += eps * rd;
    dstGrnd = GrndRay (ro, rd);
    idObj = 0;
    dstObj = ObjRay (ro, rd);
    idObjT = idObj;
    refFac *= 0.6;
  }
  bool isLit = true;
  bool isGrnd = false;
  if (dstObj < dstGrnd) {
    if (idObjT == 21 && (qTrWin.y < 0.2 &&
       (qTrWin.x < 0.45 || qTrWin.x > 0.65) || dirTrWin == 0. &&
       qTrWin.x < 0.3 && qTrWin.z < 0.7)) idObjT = 20;
    ro += dstObj * rd;
    vn = ObjNf (ro);
    if (idObjT == 20) {
      rd = reflect (rd, vn);
      ro += eps * rd;
      dstGrnd = GrndRay (ro, rd);
      if (dstGrnd < dstFar) {
        ro += dstGrnd * rd;
        dstHit = dstGrnd;
        refFac *= 0.4;
        isGrnd = true;
      } else {
        col = refFac * SkyCol (ro, rd);
        isLit = false;
      }
    } else {
      col4 = ObjCol (ro, vn);
      col = refFac * col4.xyz;
      if (! isNight) {
        col *=  sunCol * (0.3 + (max (0., dot (sunDir, vn)) +
           col4.w * pow (max (dot (rd, reflect (sunDir, vn)), 0.), 20.)));
      } else {
        if (idObjT == 21) col *= moonCol * (0.6 +
           col4.w * pow (max (dot (rd, reflect (moonDir, vn)), 0.), 40.));
      }
      dstHit = dstObj;
      isLit = ! (idObjT == 14 || (idObjT >= 20 && idObjT <= 29));
    }
  } else {
    vec3 rp = ro + dstGrnd * rd;
    if (refFac < 1.) dstHit = length (rp - roo);
    else dstHit = dstGrnd;
    if (dstHit < dstFar) {
      ro = rp;
      isGrnd = true;
    } else {
      col = refFac * SkyCol (ro, rd);
      isLit = false;
    }
  }
  if (isGrnd) {
    vn = GrndNf (ro, dstHit);
    col4 = GrndCol (ro, vn);
    col = col4.xyz * refFac;
    if (! isNight) {
      f = dot (sunDir, vn);
      col = sunCol * mix (col * (max (f, 0.) + 0.1), vec3 (refFac),
         step (f, 0.) * col4.w * pow (max (dot (reflect (sunDir, vn), rd), 0.), 3.));
    }
  }
  if (dstHit < dstFar) {
    f = dstHit / dstFar;
    col = mix (col, refFac * SkyBg (rd), clamp (1.03 * f * f, 0., 1.));
  }
  col = sqrt (clamp (col, 0., 1.));
  if (isNight && isLit) {
    vec3 vLight = ro - trainPos[0];
    vLight.z -= 2.2;
    float dstLightI = 1. / length (vLight);
    vLight *= dstLightI;
    f = dot (vLight.xz, vDir);
    if (dstLightI > 0.02 && f > 0.4) {
      col *= (0.1 + pow (f, 8.)) * min (1., 100. * dstLightI * dstLightI);
    } else {
      col = RgbToHsv (col);
      col.y = 0.1;
      col.z *= col.z;
      col.z *= 0.3 * col.z;
      col = HsvToRgb (col);
    }
  }
  return clamp (col, 0., 1.);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
  vec2 uv = 2. * fragCoord.xy / iResolution.xy - 1.;
  vec2 uvs = uv;
  uv.x *= iResolution.x / iResolution.y;
  trkOffset = vec2 (0.);
  float zmFac = 1.8;
  tCur = 15. * iTime + 100. * trkOffset.y;
  sunDir = normalize (vec3 (0.4, 0.5, 0.5));
  moonDir = normalize (vec3 (0.3, 0.25, 0.5));
  sunCol = vec3 (1., 0.9, 0.8);
  moonCol = vec3 (1., 0.9, 0.5);
  float dt = 0.3;
  isNight = mod (floor (tCur / 1000.), 2.) != 0.;
  float trStart = 12.;
  float trGap = 2.2;
  float tz;
  tz = tCur + trStart - 2. * trGap;
  vec2 vDir = normalize ((TrackPath (tz + dt).xz -
     TrackPath (tz - dt).xz) / (2. * dt));
  float dGap = sqrt (1. - vDir.x * vDir.x);
  TrainCarPM (trStart);
  trainPos[0] = trPos;  trainMat[0] = trMat;
  TrainCarPM (trStart - trGap * dGap);
  trainPos[1] = trPos;  trainMat[1] = trMat;
  TrainCarPM (trStart - (2. * trGap + 0.25) * dGap);
  trainPos[2] = trPos;  trainMat[2] = trMat;
  TrainCarPM (trStart - (3. * trGap + 0.5) * dGap);
  trainPos[3] = trPos;  trainMat[3] = trMat;
  TrainCarPM (trStart - (4. * trGap + 0.5) * dGap);
  trainPos[4] = trPos;  trainMat[4] = trMat;
  bool fixCam = mod (floor (tCur / 500.), 2.) == 0.;
  mat3 scMat;
  vec3 ro, rd, vd;
  if (fixCam) {
    tz = ceil (tCur / 100.) * 100.;
    ro = TrackPath (tz - 40.);
    float dx = 2. * mod (tz / 100., 2.) - 1.;
    ro.x += 13. * dx;
    float gh = GrndHt (ro.xz, 0);
    ro.xy += vec2 (-3. * dx, 3. + 0.1 * gh * gh);
    vd = normalize (TrackPath (tCur + 8.) - ro);
    vec3 u = - vd.y * vd;
    float f = 1. / sqrt (1. - vd.y * vd.y);
    scMat = mat3 (f * vec3 (vd.z, 0., - vd.x), f * vec3 (u.x, 1. + u.y, u.z), vd);
  } else {
    tz = tCur + trStart - 6. * trGap * dGap;
    ro = TrackPath (tz);
    ro.y += 4.;
    vd = TrackPath (tz + dt) - TrackPath (tz - dt);
    vd.y = 0.;
    vd = normalize (vd);
    scMat = mat3 (vd.z, 0., - vd.x, 0., 1., 0., vd);
  }
  rd = scMat * normalize (vec3 (uv, zmFac));
  vec3 col = ShowScene (ro, rd, vDir);
  uvs *= uvs * uvs;
  col = mix (vec3 (0.7), col, pow (max (0., 0.95 - length (uvs * uvs * uvs)), 0.3));
  fragColor = vec4 (col, 1.);
}
