// "Garage" by dr2 - 2016
// License: Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License

const float pi = 3.14159;
const vec4 cHashA4 = vec4 (0., 1., 57., 58.);
const vec3 cHashA3 = vec3 (1., 57., 113.);
const float cHashM = 43758.54;

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

float Fbmn (vec3 p, vec3 n)
{
  vec3 s = vec3 (0.);
  float a = 1.;
  for (int i = 0; i < 5; i ++) {
    s += a * vec3 (Noisefv2 (p.yz), Noisefv2 (p.zx), Noisefv2 (p.xy));
    a *= 0.5;
    p *= 2.;
  }
  return dot (s, abs (n));
}

vec3 VaryNf (vec3 p, vec3 n, float f)
{
  vec3 e = vec3 (0.2, 0., 0.);
  float s = Fbmn (p, n);
  vec3 g = vec3 (Fbmn (p + e.xyy, n) - s,
     Fbmn (p + e.yxy, n) - s, Fbmn (p + e.yyx, n) - s);
  return normalize (n + f * (g - n * dot (n, g)));
}

float PrBoxDf (vec3 p, vec3 b)
{
  vec3 d = abs (p) - b;
  return min (max (d.x, max (d.y, d.z)), 0.) + length (max (d, 0.));
}

float PrRoundBoxDf (vec3 p, vec3 b, float r)
{
  return length (max (abs (p) - b, 0.)) - r;
}

float PrBox2Df (vec2 p, vec2 b)
{
  vec2 d = abs (p) - b;
  return min (max (d.x, d.y), 0.) + length (max (d, 0.));
}

float PrCylDf (vec3 p, float r, float h)
{
  return max (length (p.xy) - r, abs (p.z) - h);
}

vec2 Rot2D (vec2 q, float a)
{
  return q * cos (a) * vec2 (1., 1.) + q.yx * sin (a) * vec2 (-1., 1.);
}

float SmoothMin (float a, float b, float r)
{
  float h = clamp (0.5 + 0.5 * (b - a) / r, 0., 1.);
  return mix (b, a, h) - r * h * (1. - h);
}

float SmoothBump (float lo, float hi, float w, float x)
{
  return (1. - smoothstep (hi - w, hi + w, x)) * smoothstep (lo - w, lo + w, x);
}

#define NCAR 6

mat3 carMat[NCAR + 1], oMat;
vec3 carPos[NCAR + 1], oPos, qHit;
float ti[6], tPer, ts, tCur, qFy, fLen, spDist, spRad, trWid, dstFar;
int carCv[NCAR], oCv, idObj, idObjGrp;
bool tracking, refMir, smSurf;

void TrackSetup ()
{
  float r, dtc;
  fLen = 3.5;
  trWid = 0.12;
  spRad = 0.7;
  spDist = 0.82 * fLen;
  r = spRad / spDist;
  ts = length (vec2 (2. * pi * r, 1. / spDist));
  dtc = (0.5 * pi - 2.) * r;
  ti[0] = 0.;
  ti[1] = ti[0] + ts + 2. + dtc;
  ti[2] = ti[1] + ts + 2. + dtc;
  ti[3] = ti[2] + ts + 4. + 2. * dtc;
  ti[4] = ti[3] + ts + 4. + 3. * dtc;
  ti[5] = ti[4] + ts + 4. + 3. * dtc;
  tPer =  ti[5] + ts + 4. + 2. * dtc;
}

vec3 TrackPath (float t)
{
  vec3 p;
  vec2 sn;
  float tm, tsi, tc, a, r, mr, dtc, av, c1, c2;
  const float c025 = 0.25, c05 = 0.5, c075 = 0.75;
  bool axFlip;
  int pType;
  r = spRad / spDist;
  mr = 1. - r;
  tsi = 1. / ts;
  tc = c05 * pi * r;
  av = c025 / tc;
  dtc = (c05 * pi - 2.) * r;
  t = mod (t, tPer);
  p = vec3 (0.);
  axFlip = false;
  pType = 0;
  sn = vec2 (1.);
  if (t < ti[3]) {
    if (t < ti[1] + ts) {
      if (t < ti[0] + ts) {
        pType = 4;  tm = t - ti[0];
        p.xzy = vec3 (0., - mr, tm * tsi);  a = tm * tsi + c075;
      } else if (t < ti[1]) {
        pType = 2;  tm = t - (ti[0] + ts);
        p.y = 1.;  a = c075;
      } else {
        pType = 4;  tm = t - ti[1];
        p.xzy = vec3 (mr, 0., 1. + tm * tsi);  a = tm * tsi;
      }
    } else {
      if (t < ti[2]) {
        pType = 2;  tm = t - (ti[1] + ts);
        p.y = 2.;  a = 0.;
        axFlip = true;
        sn.x = -1.;
      } else if (t < ti[2] + ts) {
        pType = 4;  tm = t - ti[2];
        p.xzy = vec3 (0., mr, 2. + tm * tsi);  a = tm * tsi + c025;
      } else {
        pType = 1;  tm = t - (ti[2] + ts);
        p.y = 3.;  a = c025;
      }
    }
  } else {
    if (t < ti[4] + ts) {
      if (t < ti[3] + ts) {
        pType = 4;  tm = t - ti[3];
        p.xzy = vec3 (0., - mr, 3. - tm * tsi);  a = tm * tsi + c075;
      } else if (t < ti[4]) {
        pType = 3;  tm = t - (ti[3] + ts);
        p.y = 2.;  a = c075;
      } else {
        pType = 4;  tm = t - ti[4];
        p.xzy = vec3 (- mr, 0., 2. - tm * tsi);  a = tm * tsi + c05;
      }
    } else {
      if (t < ti[5]) {
        pType = 3;  tm = t - (ti[4] + ts);
        p.y = 1.;  a = c05;
        axFlip = true;
        sn.y = -1.;
      } else if (t < ti[5] + ts) {
        pType = 4;  tm = t - ti[5];
        p.xzy = vec3 (0., mr, 1. - tm * tsi);  a = tm * tsi + c025;
      } else {
        pType = 1;  tm = t - (ti[5] + ts);
        p.y = 0.;  a = c025;
      }
    }
  }
  if (pType == 1) {
    if (tm < mr) p.xz = vec2 (- tm, 1.);
    else if (tm < mr + tc) {
      p.xz = vec2 (-1., 1.);  a += (tm - mr) * av;
      pType = 5;
    } else if (tm < 3. * mr + tc) p.xz = vec2 (-1., - tm + 2. * mr + tc);
    else if (tm < 3. * mr + 2. * tc) {
      p.xz = vec2 (-1., -1.);  a += (tm - (3. * mr + tc)) * av + c025;
      pType = 5;
    } else p.xz = vec2 (tm - (4. * mr + 2. * tc), -1.);
  } else if (pType == 2) {
    if (tm < mr) p.xz = vec2 (tm, -1.);
    else if (tm < mr + tc) {
      p.xz = vec2 (1., -1.);  a += (tm - mr) * av;
      pType = 5;
    } else p.xz = vec2 (1., tm - (2. * mr + tc));
    p.xz = axFlip ? p.zx : p.xz;
  } else if (pType == 3) {
    c1 = 2. - 3. * r + tc;
    c2 = 3.5 - 5. * r + 2. * tc;
    if (tm < c05 - r) p.xz = vec2 (tm, -1.);
    else if (tm < c05 - r + tc) {
      p.xz = vec2 (c05, -1.);  a += (tm - (c05 - r)) * av;
      pType = 5;
    } else if (tm < c1) p.xz = vec2 (c025 + r, tm - (1.5 - 2. * r + tc));
    else if (tm < c1 + tc) {
      p.xz = vec2 (c05, c05);  a += (tm - c1) * av + c025;
      pType = 5;
    } else if (tm < c2) p.xz = vec2 (- (tm - (c1 + tc)) + c025, c05);
    else if (tm < c2 + tc) {
      p.xz = vec2 (-1., c05);  a += (tm - c2) * av + c05;
      pType = 5;
    } else p.xz = vec2 (-1., c025 - (tm - (c2 + tc)));
    p.xz = axFlip ? p.zx : p.xz;
  }
  p.xz *= sn;
  oCv = 0;
  if (pType == 5) p.xz -= r * sign (p.xz);
  if (pType == 4 || pType == 5) {
    a *= 2. * pi;
    p.xz += r * vec2 (cos (a), sin (a));
    oCv = 1;
  }
  p.xz *= spDist;
  p.y += 0.1;
  return p;
}

float CarDf (vec3 p, float dMin)
{
  vec3 q;
  float d;
  q = p;
  d = SmoothMin (PrRoundBoxDf (q + vec3 (0., -0.08, 0.),
     vec3 (0.06, 0.01, 0.15), 0.02), PrRoundBoxDf (q + vec3 (0., -0.13, 0.02),
     vec3 (0.035, 0.005, 0.07), 0.02), 0.06);
  if (d < dMin) { dMin = d;  idObj = idObjGrp + 1;  qHit = q; }
  q.xz = abs (q.xz) - vec2 (0.07, 0.1);
  q.y -= 0.055;
  d = PrCylDf (q.yzx, 0.03, 0.012);
  if (d < dMin) { dMin = d;  idObj = idObjGrp + 2;  qHit = q; }
  return dMin;
}

float ObjDf (vec3 p)
{
  vec3 q;
  float dMin, d, dr, fy, sn34, sn4, flThk, htWl, wThk;
  bool is24;
  flThk = 0.03;
  htWl = 0.02;
  wThk = 0.03;
  dMin = dstFar;
  fy = floor (p.y) + 1.;
  is24 = (fy == 2. || fy == 4.);
  sn34 = ((fy == 3. || fy == 4.) ? -1. : 1.);
  sn4 = ((fy == 4.) ? -1. : 1.);
  if (fy >= 1. && fy <= 3.) {
    q = p;
    q.xz = is24 ? q.zx : q.xz;
    q.z = abs (q.z) - spDist + spRad;
    q.xz = vec2 (- q.z, q.x * sn34);
    q.y -= atan (q.z, - q.x) / (2. * pi) + fy;
    dr = length (q.xz) - spRad;
    d = max (max (PrBox2Df (vec2 (dr, q.y), vec2 (trWid + wThk, htWl)),
       - PrBox2Df (vec2 (dr, q.y - htWl), vec2 (trWid, htWl))), q.z);
    q.y += 1.;
    d = min (d, max (max (PrBox2Df (vec2 (dr, q.y), vec2 (trWid + wThk, htWl)),
       - PrBox2Df (vec2 (dr, q.y - htWl), vec2 (trWid, htWl))), - q.z));
    if (d < dMin) { dMin = d;  idObj = 1;  qHit = q; }
  }
  if (fy >= 0. && fy <= 3.) {
    q = p;
    q.y -= fy - flThk;
    d = PrBoxDf (q, vec3 (fLen, flThk, fLen));
    if (fy >= 1.) {
      q.xz = is24 ? q.xz : q.zx;
      q.x = abs (q.x) - spDist + 0.5 * spRad;
      q.z += 0.65 * spRad * sn34;
      d = max (d, - PrBox2Df (q.xz, spRad * vec2 (0.9, 0.65)));
    }  
    if (d < dMin) { dMin = d;  idObj = 2;  qFy = fy;  qHit = p; }
  }
  if (fy >= 2. && fy <= 4.) {
    q = p;
    q.y -= fy - 1. + 2. * flThk;
    q.xz = is24 ? q.zx : q.xz;
    q.x = abs (q.x) - spDist + 0.5 * spRad;
    q.z += 0.65 * spRad * sn4;
    d = PrBoxDf (q, spRad * vec3 (0.9, 0., 0.65) + flThk * vec3 (2.));
    d = max (d, - min (PrBox2Df (q.xz, spRad * vec2 (0.9, 0.65)),
       PrBox2Df (q.xz - spRad * vec2 (0.5, 0.6 * sn4),
       spRad * vec2 (0.3, 0.2))));
    if (d < dMin) { dMin = d;  idObj = 3; }
  }
  if (fy >= 1. && fy <= 4.) {
    q = p;
    q.y -= fy - 1. + 2. * flThk;
    d = max (PrBoxDf (q, vec3 (fLen, 2. * flThk, fLen)),
       - PrBox2Df (q.xz, vec2 (fLen - flThk)));
    if (d < dMin) { dMin = d;  idObj = 4; }
  }
  q = p;
  q.y -= 1.5;
  q.xz = Rot2D (q.xz, 0.25 * pi);
  q.xz = abs (q.xz) - (spDist - spRad) / sqrt (2.);
  d = PrCylDf (q.xzy, 3. * flThk, 1.49);
  if (d < dMin) { dMin = d;  idObj = 5; }
  q = p;
  q.y -= 1.5;
  q.xz = abs (q.xz) - 0.95 * fLen;
  d = PrCylDf (q.xzy, 3. * flThk, 1.49);
  if (d < dMin) { dMin = d;  idObj = 6; }
  q = p;
  q.y -= 1.9;
  d = max (PrBoxDf (q, vec3 (0.2 * fLen, 1.9, 0.2 * fLen)),
     - PrBox2Df (q.xz, vec2 (0.2 * fLen - wThk)));
  if (fy >= 1. && fy <= 4.) {
    q = p;
    q.y -= fy - 0.7;
    d = max (d, - min (PrBox2Df (q.xy, vec2 (0.05 * fLen, 0.3)),
       PrBox2Df (q.zy, vec2 (0.05 * fLen, 0.3))));
  }
  if (d < dMin) { dMin = d;  idObj = 7;  qHit = q; }
  idObjGrp = 0;
  for (int nc = 0; nc < NCAR; nc ++) {
    q = p - carPos[nc];
    d = PrBoxDf (q, vec3 (0.2));
    idObjGrp += 256;
    if (d < dMin) dMin = CarDf (carMat[nc] * q, dMin);
  }
  return dMin;
}

vec3 ObjNf (vec3 p)
{
  vec3 e = vec3 (0.0001, -0.0001, 0.);
  vec4 v = vec4 (ObjDf (p + e.xxx), ObjDf (p + e.xyy),
     ObjDf (p + e.yxy), ObjDf (p + e.yyx));
  return normalize (vec3 (v.x - v.y - v.z - v.w) + 2. * vec3 (v.y, v.z, v.w));
}

float ObjRay (vec3 ro, vec3 rd)
{
  vec3 p;
  float d, dHit, srd, dda;
  dHit = 0.;
  srd = - sign (rd.y);
  dda = - srd / (rd.y + 0.00001);
  for (int j = 0; j < 200; j ++) {
    p = ro + dHit * rd;
    d = ObjDf (p);
    dHit += min (d, 0.01 + max (0., fract (dda * fract (srd * p.y))));
    if (d < 0.001 || dHit > dstFar) break;
  }
  return dHit;
}

vec4 FloorCol (vec3 vn)
{
  vec3 col;
  vec2 u, uu;
  float spec, wFac, f, ff;
  bool nrTrail;
  col = vec3 (0.4);
  spec = 0.1;
  smSurf = false;
  u = qHit.xz;
  if (idObj == 1) {
    f = abs (length (u) - spRad) / trWid;
    if (vn.y > 0. && f < 0.95) {
      col = mix (vec3 (0.1), vec3 (1., 1., 0.),
         SmoothBump (-0.05, 0.1, 0.05, abs (f) - 0.85));
      spec = 0.3;
      smSurf = true;
    } else if (vn.y < -0.8) {
      col = mix (col, vec3 (0.3, 0.3, 1.),
         smoothstep (0., 0.02, abs (f) - 0.93));
    } else {
      col = vec3 (0.7, 0.6, 0.4);
    }
  } else if (idObj == 2) {
    wFac = 1.;
    if (vn.y > 0.999) {
      uu = mod (u + 0.25, 0.5);
      f = 1. - (1. - SmoothBump (0.24, 0.26, 0.01, uu.x)) *
         ( 1. - SmoothBump (0.24, 0.26, 0.01, uu.y));
      col = mix (col, vec3 (0.5, 0.5, 0.8), f);
      if (qFy == 0. || qFy == 3.) nrTrail = (u.x < 0.);
      else {
        if (qFy == 1.) u.y *= -1.;
        if (u.x > 0. || u.y > 0.) {
          if (u.x > 0. && u.y > 0. && length (u.xy) > 0.6 * fLen) nrTrail = true;
          else {
            u.xy += 0.25 * spDist;
            wFac = 0.75;
            nrTrail = true;
          }
        }
      }
      if (nrTrail) {
        f = (pow (length (pow (abs (u), vec2 (5.))), 0.2) -
           0.82 * wFac * fLen) / trWid;
        if (abs (f) < 0.98) {
          uu = mod (u + 0.4, 0.8) - 0.4;
          ff = (1. - SmoothBump (- 0.1, 0.1, 0.02, uu.x)) *
             (1. - SmoothBump (- 0.1, 0.1, 0.02, uu.y));
          col = mix (vec3 (0.1), vec3 (1., 1., 0.),
             ff * SmoothBump (-0.05, 0.1, 0.05, abs (f) - 0.85));
          spec = 0.3;
          smSurf = true;
        }
      }
    } else if (qFy > 0. && vn.y < -0.999) {
      uu = mod (u + 0.1, 0.35) - 0.1;
      f = 1. - (1. - SmoothBump (-0.006, 0.006, 0.002, uu.x)) *
         (1. - SmoothBump (-0.006, 0.006, 0.002, uu.y));
      col = mix (col, vec3 (0.5), f);
      uu = mod (u, 0.35) - 0.175;
      if (length (uu) < 0.03) {
        col = vec3 (1., 0.7, 0.2);
        spec = -1.;
      }
    } else if (abs (vn.y) < 0.01) col = vec3 (0.45, 0.45, 0.4);
  }
  return vec4 (col, spec);
}

vec4 CarCol ()
{
  vec3 col;
  vec2 u;
  float f, spec, br;
  int ig, id;
  bool brkLt;
  ig = idObj / 256;
  id = idObj - 256 * ig;
  if (id == 1) {
    col = vec3 (0.3, 1., 0.5);
    f = abs (qHit.z + 0.02);
    f = max (max (step (0.075, f) * step (0.045, abs (qHit.x)),
       step (f, 0.007)), step (0.017, abs (qHit.y - 0.13)));
    if (f == 0.) {
      col = vec3 (0.2, 0.1, 0.);
      spec = 0.5;
    }
    if (abs (qHit.z) > 0.15) {
      if (qHit.z > 0.) {
        if (length (vec2 (qHit.x, 3. * (qHit.y - 0.08))) < 0.03) col *= 0.3;
        u = qHit.xy;
        u.x = abs (u.x);
        u -= vec2 (0.045, 0.08);
        if (length (u) < 0.009) {
          col = vec3 (1., 1., 0.3);
          spec = -1.;
        }
      } else {
        brkLt = false;
        u = qHit.xy;
        u.y -= 0.095;
        if (abs (u.x) < 0.03 && abs (u.y) < 0.0025) brkLt = true;
        u = qHit.xy;
        u.x = abs (u.x);
        u -= vec2 (0.055, 0.08);
        if (length (u) < 0.007) brkLt = true;
        if (brkLt) {
          br = 0.;
          for (int nc = 0; nc < NCAR; nc ++) {
            if (nc == ig - 1 && carCv[nc] == 1) br = 1.;
          }
          col = vec3 (1., 0., 0.) * (0.5 + 0.5 * br);
          spec = -1.;
        }
        u.x += 0.02;
        if (length (u) < 0.007) {
          col = vec3 (1., 0., 0.);
          spec = -1.;
        }
      }
    }
  } else if (id == 2) {
    f = length (qHit.yz);
    if (f < 0.018) {
      col = (f > 0.005) ? vec3 (0.9) : vec3 (0.3);
      spec = 0.7;
    } else {
      col = vec3 (0.03);
      spec = 0.1;
    } 
  }
  return vec4 (col, spec);
}

float BrickPat (vec2 p)
{
  vec2 q, iq;
  q = 8. * p * vec2 (1., 4.);
  iq = floor (q);
  if (2. * floor (iq.y / 2.) != iq.y) q.x += 0.5;
  q = smoothstep (0.02, 0.05, abs (fract (q + 0.5) - 0.5));
  return (0.7 + 0.3 * q.x * q.y);
}

vec4 ObjCol (vec3 ro, vec3 vn)
{
  vec4 objCol;
  vec3 q;
  float f;
  objCol.a = 0.1;
  if (idObj == 1 || idObj == 2) {
    objCol = FloorCol (vn);
  } else if (idObj == 3) {
    f = (max (abs (vn.x), abs (vn.z)) > abs (vn.y)) ?
       BrickPat ((abs (vn.x) >  abs (vn.z) ? ro.zy : ro.xy)) : 1.;
    objCol.rgb = f * vec3 (0.5, 0.4, 0.3);
  } else if (idObj == 4) {
    f = (dot (vn.xz, ro.xz) < 0.) ?
       BrickPat ((abs (vn.x) >  abs (vn.z) ? ro.zy : ro.xy)) : 1.;
    objCol.rgb = f * vec3 (0.7, 0.6, 0.4);
  } else if (idObj == 5) {
    f = smoothstep (0.1, 0.15, abs (mod (10. * ro.y, 1.)));
    objCol.rgb = mix (vec3 (0., 0., 1.), vec3 (0.7, 0.6, 0.4), f);
  } else if (idObj == 6) {
    f = smoothstep (0.1, 0.15, abs (mod (10. * ro.y, 1.)));
    objCol.rgb = (0.7 + 0.3 * f) * vec3 (0.7, 0.6, 0.4);
  } else if (idObj == 7) {
    q = abs (vn.x) > abs (vn.z) ? qHit.zyx : qHit;
    if (dot (vn.xz, ro.xz) > 0. && length (q.xy - vec2 (0., 0.35)) < 0.02) {
      objCol.rgb = vec3 (1., 0.2, 0.2);
      objCol.a = -1.;
    } else objCol.rgb = BrickPat (q.xy) * vec3 (0.7, 0.6, 0.4);
  } else if (idObj > 256) {
    objCol = CarCol ();
  }
  return objCol;
}

vec3 ShowScene (vec3 ro, vec3 rd)
{
  vec4 objCol;
  vec3 ltPos, ltAx, ltDir, col, vn, rds;
  float dstHit, diff, ltDiff, ltSpec, d, atten, f;
  int idObjT;
  dstHit = ObjRay (ro, rd);
  if (dstHit < dstFar) {
    ro += rd * dstHit;
    idObjT = idObj;
    vn = ObjNf (ro);
    idObj = idObjT;
    objCol = ObjCol (ro, vn);
    if ((idObj == 1 || idObj == 2) && ! smSurf || idObj >= 3 && idObj <= 7)
       vn = VaryNf (100. * ro, vn, 0.2);
    if (objCol.a >= 0.) {
      ltDiff = 0.;
      ltSpec = 0.;
      for (int nc = 0; nc < NCAR + 1; nc ++) {
        if (tracking || nc < NCAR) {
          ltPos = carPos [nc];
          ltAx = vec3 (0., 0., 1.) * carMat[nc];
          ltPos += 0.2 * ltAx;
          ltPos.y += 0.05;
          ltDir = ltPos - ro;
	  ltDir.y += 0.05;
          atten = 1. - smoothstep (0.85, 0.95, abs (ltAx.y));
	  if (nc < NCAR) atten *= 1. - smoothstep (0.05, 0.1, ltDir.y);
          d = max (length (ltDir), 0.3);
          ltDir = normalize (ltDir);
          f = max (dot (ltAx, - ltDir), 0.);
          atten *= f * f / pow (d, 2.);
          diff = max (dot (ltDir, vn), 0.);
          ltDiff += atten * diff;
          ltSpec += step (0., diff) *
             atten * pow (max (dot (reflect (ltDir, vn), rd), 0.), 32.);
         }
      }
      ltDiff = min (0.4 * ltDiff, 1.) +
         0.2 * max (dot (vec3 (0., 0., 1.), vn), 0.);
      col = objCol.rgb * (0.1 + ltDiff + objCol.a * min (0.3 * ltSpec, 1.));
      if (! tracking) col *= 1.5;
    } else col = objCol.rgb;
  } else {
    col = vec3 (0., 0., 0.07);
    f = step (0., (rd.y + 0.3) / 1.3);
    rds = (rd + vec3 (1., 0.7, 0.3));
    for (int j = 0; j < 14; j ++) rds = 11. * abs (rds) / dot (rds, rds) - 3.;
    col += min (1., 1.5e-6 * pow (min (16., length (rds)), 5.)) *
       f * f * vec3 (0.65, 0.65, 0.6);
  }
  return clamp (col, 0., 1.);
}

void ObjPM (float t)
{
  vec3 vuF, vuB, dv;
  vec2 ort, cr, sr;
  oPos = TrackPath (t);
  vuF = TrackPath (t + 0.05);
  vuB = TrackPath (t - 0.05);
  dv = vuF - vuB;
  ort = vec2 (- asin (dv.y / length (dv)), atan (dv.z, dv.x) - 0.5 * pi);
  cr = cos (ort);
  sr = sin (ort);
  oMat = mat3 (1., 0., 0., 0., cr.x, - sr.x, 0., sr.x, cr.x) *
     mat3 (cr.y, 0., - sr.y, 0., 1., 0., sr.y, 0., cr.y);
}

void mainImage (out vec4 fragColor, in vec2 fragCoord)
{
  vec4 mPtr;
  mat3 vuMat, vuMatT;
  vec3 col, ro, rd, vd, u, p1, p2;
  vec2 canvas, uv, ut, uvs, vf, cf, sf, mMid, mSize;
  float el, az, f, s, cd, vel, cdGap, fnc;
  canvas = iResolution.xy;
  uv = 2. * fragCoord.xy / canvas - 1.;
  uvs = uv;
  uv.x *= canvas.x / canvas.y;
  tCur = iTime;
  mPtr = iMouse;
  mPtr.xy = mPtr.xy / canvas - 0.5;
  tracking = ! (mPtr.z > 0.);
  dstFar = tracking ? 10. : 30.;
  mMid = vec2 (-1., 0.6);
  mSize = vec2 (0.6, 0.3);
  ut = abs (uv - mMid) - mSize;
  refMir = tracking && (max (ut.x, ut.y) < 0.);
  vel = 0.3;
  TrackSetup ();
  s = vel * tCur;
  cdGap = 0.4 + 0.6 * SmoothBump (0.3, 0.8, 0.2, fract (2.5 * s / tPer));
  for (int nc = 0; nc < NCAR; nc ++) {
    fnc = float (nc);
    ObjPM (s + cdGap * (floor (0.5 * fnc) + 1.) * (2. * mod (fnc, 2.) - 1.));
    carPos[nc] = oPos;
    carPos[nc].y -= 0.125;
    carMat[nc] = oMat;
    carCv[nc] = oCv;
  }
  if (tracking) {
    s += 0.1 * (SmoothBump (0.2, 0.7, 0.1, fract (7. * s / tPer)) - 0.5);
    ObjPM (s);
    carPos[NCAR] = oPos;
    carPos[NCAR].y -= 0.125;
    carMat[NCAR] = oMat;
    p1 = TrackPath (s + 0.1);
    p2 = TrackPath (s - 0.1);
    ro = 0.5 * (p1 + p2);
    vd = normalize (p1 - p2);
    if (refMir) vd *= -1.;
    u = - vd.y * vd;
    f = 1. / sqrt (1. - vd.y * vd.y);
    vuMatT = mat3 (f * vec3 (- vd.z, 0., vd.x), f * vec3 (u.x, 1. + u.y, u.z), vd);
  }
  az = 0.;
  el = refMir ? -0.1 : 0.1;
  if (mPtr.z > 0.) {
    el = el - 4. * mPtr.y;
    az = az + 10. * mPtr.x;
  }
  el = clamp (el, -0.45 * pi, 0.45 * pi);
  vf = vec2 (el, az);
  cf = cos (vf);
  sf = sin (vf);
  vuMat = mat3 (1., 0., 0., 0., cf.x, - sf.x, 0., sf.x, cf.x) *
     mat3 (cf.y, 0., sf.y, 0., 1., 0., - sf.y, 0., cf.y);
  if (tracking) {
    ro.y += 0.05;
    if (refMir) uv = (uv - mMid) / mSize.x;
    rd = vuMatT * (vuMat * normalize (vec3 (uv, (refMir ? 1.5 : 1.8))));
  } else {
    ro = vec3 (0., 2., -12.) * vuMat;
    rd = normalize (vec3 (uv, 3.)) * vuMat;
  }
  col = ShowScene (ro, rd);
  col = mix (vec3 (0.3), col, pow (max (0., 0.85 -
     length (pow (abs (uvs), vec2 (10.)))), 0.2));
  ut = abs (ut);
  if (refMir && min (ut.x, ut.y) * canvas.y < 2.) col = vec3 (0.3, 0.5, 0.2);
  fragColor = vec4 (col, 1.);
}
