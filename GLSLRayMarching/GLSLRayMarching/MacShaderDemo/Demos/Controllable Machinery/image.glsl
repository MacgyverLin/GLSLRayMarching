// "Controllable Machinery" by dr2 - 2022
// License: Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License

// (Extension of "Machinery"; control widget in world space - as in "Maze Ball Solved 2")

#define AA    0  // (= 0/1) optional antialiasing

#if 0
#define VAR_ZERO min (iFrame, 0)
#else
#define VAR_ZERO 0
#endif

float PrBoxDf (vec3 p, vec3 b);
float PrRoundBoxDf (vec3 p, vec3 b, float r);
float PrCylDf (vec3 p, float r, float h);
float PrRoundCylDf (vec3 p, float r, float rt, float h);
float PrCaps2Df (vec2 p, float r, float h);
float Minv3 (vec3 p);
float Maxv3 (vec3 p);
float Minv2 (vec2 p);
float Maxv2 (vec2 p);
float SmoothMax (float a, float b, float r);
float SmoothBump (float lo, float hi, float w, float x);
vec2 Rot2D (vec2 q, float a);
mat3 StdVuMat (float el, float az);
vec3 HsvToRgb (vec3 c);
vec4 Loadv4 (int idVar);

vec4 wgObj;
vec3 ltDir, vnBlk;
vec2 qBlk;
float dstFar, tCur, tMov, angRot, bEdge, tCyc, cnPos, hitBlk;
int idObj;
const int idGr = 1, idPln = 2, idConv = 3, idSup = 4, idAx = 5, idBas = 6,
   idWhl = 7, idSpl = 8, idCon = 9, idBlk = 10;
const float pi = 3.1415927;
const float nBlk = 13.;

#define DMIN(id) if (d < dMin) { dMin = d;  idObj = id; }

float GearWlDf (vec3 p, float rad, float wlThk, float tWid, float nt, float aRot, 
   bool bev, float dMin)
{
  vec3 q;
  float d, s;
  q = p;
  d = max (length (q.xy) - rad, abs (q.z) - wlThk);
  if (d < dMin) {
    q.xy = Rot2D (q.xy, aRot);
    q.xy = Rot2D (q.xy, floor (nt * atan (q.y, - q.x) / (2. * pi) + 0.5) * 2. * pi / nt);
    if (bev) q.xy *= 1.2 - 0.2 * q.z / wlThk;
    s = q.x - 2. * clamp (1.5 * tWid + 0.5 * q.x * step (0., q.x) - abs (q.y), 0., tWid);
    d = max (d, - rad - 0.95 * s);
  }
  return min (dMin, d);
}

vec4 BPos (float t)
{
  vec3 p;
  float a;
  t = mod (t, tCyc);
  if (t < 5.) {
    a = 0.;
    p = vec3 (-1.018 + 2.118 * t / 5., bEdge, 0.);
  } else if (t < 10.) {
    a = 0.5 * pi * (t - 5.) / 5.;
    p = vec3 (1.1, bEdge + 1. * sin (a), 1. - 1. * cos (a));
  } else if ( t < 15.) {
    a = 0.5 * pi;
    p = vec3 (1.1 - 2.118 * (t - 10.) / 5., 1. + bEdge, 1.);
  } else if (t < 17.5) {
    a = 0.5 * pi;
    p = vec3 (-1.018, 1. + bEdge, 1. - 1. * (t - 15.) / 2.5);
  } else {
    t -= 17.5;
    a = -0.5 * pi * t;
    p = vec3 (-1.018, 1. + bEdge - t * t, 0.);
  }
  return vec4 (p, a);
}

float GearDf (vec3 p)
{
  vec3 q;
  float dMin, wlThk, tWid, nt, rad, gRat;
  dMin = dstFar / 0.3;
  gRat = 2.;
  rad = 0.3;
  wlThk = rad / 7.;
  tWid = rad / 10.;
  nt = 20.;
  q = p - vec3 (-1.05, -0.21, 1.3);
  dMin = GearWlDf (- q, rad, wlThk, tWid, nt, angRot * gRat, true, dMin);
  dMin = GearWlDf ((q - vec3 (0.85 * rad, 0., 0.85 * rad)).yzx,
     rad, wlThk, tWid, nt, angRot * gRat + pi / nt, true, dMin);
  rad = 0.43;
  wlThk = rad / 15.;
  tWid = rad / 16.;
  nt = 32.;
  q = p -vec3 (0.1, 0., 1.);
  dMin = GearWlDf ((q - vec3 (0., bEdge, 0.)).yzx, rad, wlThk, tWid, nt,
     - angRot - 0.3 * pi / nt, false, dMin);
  dMin = GearWlDf (- (q - vec3 (0., -0.21, 0.555)).zyx, rad / gRat, wlThk, tWid,
     nt / gRat, - angRot * gRat, false, dMin);
  rad = 0.32;
  wlThk = rad / 15.;
  tWid = rad / 12.;
  nt = 24.;
  q = p - vec3 (-1.05, -0.21, 0.6);
  dMin = GearWlDf ((q - vec3 (0., 0., 0.1)), rad, wlThk, tWid, nt,
     angRot * gRat + pi / nt, false, dMin);
  dMin = GearWlDf ((q - vec3 (0., -0.47, 0.1)), rad / gRat, wlThk, tWid, nt / gRat,
     - angRot * gRat * gRat, false, dMin);
  dMin = GearWlDf ((q - vec3 (0., -0.47, -0.1)), rad, wlThk, tWid, nt,
     - angRot * gRat * gRat - pi / nt, false, dMin);
  dMin = GearWlDf ((q - vec3 (0., 0., -0.1)), rad / gRat, wlThk, tWid, nt / gRat,
     angRot * gRat * gRat * gRat, false, dMin);
  return dMin * 0.3;
}

float ObjDf (vec3 p)
{
  vec4 a4;
  vec3 q, bPos;
  float dMin, d, r, a;
  dMin = dstFar;
  q = p - vec3 (1.13 + bEdge, bEdge, 1.);
  r = length (q.yz);
  q.yz = Rot2D (q.yz, - angRot);
  a = (r > 0.) ? atan (q.z, - q.y) / (2. * pi) : 0.;
  q.yz = Rot2D (q.yz, 2. * pi * (floor (8. * a + 0.5)) / 8.);
  q.z = abs (q.z);
  d = SmoothMax (min (min (abs (r - 1.01) - 0.1, r - 0.3),
     max (r - 1., dot (q.yz, vec2 (sin (0.8 * 2. * pi / 32.),
     cos (0.8 * 2. * pi / 32.))))), abs (q.x) - 0.02, 0.01);
  DMIN (idWhl);
  d = min (PrBoxDf (p - vec3 (0., 0.98, 1.), vec3 (1.12, 0.02, 0.1)),
     PrBoxDf (p - vec3 (-1.018, 0.98, 0.5), vec3 (0.1, 0.02, 0.5 - bEdge)));
  DMIN (idPln);
  d = SmoothMax (abs (PrCaps2Df ((p - vec3 (-0.05, -0.21, 0.)).yx, 0.2, 1.)) - 0.01,
    abs (p.z) - 0.1, 0.02);
  DMIN (idConv);
  q = p - vec3 (-0.05, -0.21, 0.);
  q.x = abs (q.x) - 1.;
  d = PrRoundCylDf (q, 0.18, 0.01, 0.11);
  DMIN (idSpl);
  q = p - vec3 (0.65, -0.14, 1.);
  q.x = abs (q.x) - 0.3;
  d = PrRoundBoxDf (q, vec3 (0.01, 1.08, 0.06), 0.02);
  q = p - vec3 (-0.05, -0.68, 0.);
  q.xz = abs (q.xz) - vec2 (1., 0.2);
  d = min (d, PrRoundBoxDf (q, vec3 (0.04, 0.55, 0.01), 0.02));
  q = p - vec3 (-1.05, -0.14, 1.);
  d = min (d, PrRoundBoxDf (q, vec3 (0.04, 1.08, 0.01), 0.02));
  q = p - vec3 (-1.05, -0.68, 0.6);
  q.z = abs (q.z) - 0.2;
  d = min (d, PrRoundBoxDf (q, vec3 (0.04, 0.55, 0.01), 0.02));
  q = p - vec3 (-0.33, -0.68, 1.555);
  q.x = abs (q.x) - 0.3;
  d = min (d, PrRoundBoxDf (q, vec3 (0.01, 0.55, 0.04), 0.02));
  DMIN (idSup);
  q = p - vec3 (0.65, bEdge, 1.);
  d = PrCylDf (q.yzx, 0.04, 0.62);
  q = p - vec3 (-0.36, -0.21, 1.555);
  d = min (d, PrCylDf (q.yzx, 0.03, 0.51));
  q = p - vec3 (-0.05, -0.21, 0.);
  q.x -= 1.;
  d = min (d, PrCylDf (q, 0.03, 0.27));
  q.xz -= vec2 (-2., 0.14);
  d = min (d, PrCylDf (q, 0.03, 0.4));
  q.z -= 0.87;
  d = min (d, PrCylDf (q, 0.03, 0.36));
  q = p - vec3 (-1.05, -0.68, 0.6);
  d = min (d, PrCylDf (q, 0.03, 0.25));
  DMIN (idAx);
  q = p - vec3 (0., -1.2, 0.9);
  d = PrRoundBoxDf (q, vec3 (1.7, 0.03, 1.5), 0.02);
  DMIN (idBas);
  q = p - wgObj.xyz;
  d = PrRoundCylDf (q.xzy, wgObj.w, 0.02, 0.02);
  DMIN (idCon);
  return dMin;
}

float ObjRay (vec3 ro, vec3 rd)
{
  float dHit, d;
  dHit = 0.;
  for (int j = VAR_ZERO; j < 150; j ++) {
    d = ObjDf (ro + dHit * rd);
    dHit += d;
    if (d < 0.0005 || dHit > dstFar) break;
  }
  return dHit;
}

float GearRay (vec3 ro, vec3 rd)
{
  float dHit, d;
  dHit = 0.;
  for (int j = VAR_ZERO; j < 250; j ++) {
    d = GearDf (ro + dHit * rd);
    dHit += d;
    if (d < 0.0005 || dHit > dstFar) break;
  }
  return dHit;
}

vec3 GearNf (vec3 p)
{
  vec4 v;
  vec2 e;
  e = vec2 (0.0005, -0.0005);
  for (int j = VAR_ZERO; j < 4; j ++) {
    v[j] = GearDf (p + ((j < 2) ? ((j == 0) ? e.xxx : e.xyy) : ((j == 2) ? e.yxy : e.yyx)));
  }
  v.x = - v.x;
  return normalize (2. * v.yzw - dot (v, vec4 (1.)));
}

vec3 ObjNf (vec3 p)
{
  vec4 v;
  vec2 e;
  e = vec2 (0.0005, -0.0005);
  for (int j = VAR_ZERO; j < 4; j ++) {
    v[j] = ObjDf (p + ((j < 2) ? ((j == 0) ? e.xxx : e.xyy) : ((j == 2) ? e.yxy : e.yyx)));
  }
  v.x = - v.x;
  return normalize (2. * v.yzw - dot (v, vec4 (1.)));
}

float BlkHit (vec3 ro, vec3 rd)
{
  vec4 a4;
  vec3 rm, rdm, u, v, tm, tp;
  float dMin, dn, df;
  dMin = dstFar;
  for (float k = float (VAR_ZERO); k < nBlk; k ++) {
    a4 = BPos (tMov + tCyc * k / nBlk);
    rm = ro - a4.xyz;
    rdm = rd;
    rm.zy = Rot2D (rm.zy, a4.w);
    rdm.zy = Rot2D (rdm.zy, a4.w);
    v = rm / rdm;
    tp = bEdge / abs (rdm) - v;
    tm = - tp - 2. * v;
    dn = Maxv3 (tm);
    df = Minv3 (tp);
    if (df > 0. && dn < min (df, dMin)) {
      dMin = dn;
      hitBlk = k;
      vnBlk = - sign (rdm) * step (tm.zxy, tm) * step (tm.yzx, tm);
      u = (v + dn) * rdm;
      qBlk = vec2 (dot (u.zxy, vnBlk), dot (u.yzx, vnBlk));
      vnBlk.zy = Rot2D (vnBlk.zy, - a4.w);
    }
  }
  return dMin;
}

float BlkHitSh (vec3 ro, vec3 rd, float rng)
{
  vec4 a4;
  vec3 rm, rdm, v, tm, tp;
  float dMin, dn, df;
  dMin = dstFar;
  for (float k = float (VAR_ZERO); k < nBlk; k ++) {
    a4 = BPos (tMov + tCyc * k / nBlk);
    rm = ro - a4.xyz;
    rdm = rd;
    rm.zy = Rot2D (rm.zy, a4.w);
    rdm.zy = Rot2D (rdm.zy, a4.w);
    v = rm / rdm;
    tp = bEdge / abs (rdm) - v;
    tm = - tp - 2. * v;
    dn = Maxv3 (tm);
    df = Minv3 (tp);
    if (df > 0. && dn < min (df, dMin)) dMin = dn;
  }
  return smoothstep (0., rng, dMin);
}

float ObjSShadow (vec3 ro, vec3 rd)
{
  float sh, d, h;
  sh = 1.;
  d = 0.02;
  for (int j = VAR_ZERO; j < 30; j ++) {
    h = ObjDf (ro + rd * d);
    sh = min (sh, smoothstep (0., 0.05 * d, h));
    d += h;
    if (sh < 0.05) break;
  }
  return sh;
}

float GearSShadow (vec3 ro, vec3 rd)
{
  float sh, d, h;
  sh = 1.;
  d = 0.02;
  for (int j = VAR_ZERO; j < 30; j ++) {
    h = GearDf (ro + rd * d);
    sh = min (sh, smoothstep (0., 0.05 * d, h));
    d += h;
    if (sh < 0.05) break;
  }
  return sh;
}

vec3 ShowScene (vec3 ro, vec3 rd)
{
  vec4 col4;
  vec3 vn, col, q;
  float dstObj, dstGear, dstBlk, sh, s, r, a, nDotL;
  int idObjT;
  bool isMet;
  tCyc = 18.5;
  bEdge = 0.08;
  isMet = false;
  angRot = 0.1 * pi * tMov;
  dstObj = ObjRay (ro, rd);
  idObjT = idObj;
  dstGear = GearRay (ro, rd);
  if (dstGear < min (dstObj, dstFar)) {
    dstObj = dstGear;
    idObj = idGr;
  } else idObj = idObjT;
  dstBlk = BlkHit (ro, rd);
  if (min (dstBlk, dstObj) < dstFar) {
    if (dstBlk < dstObj) {
      dstObj = dstBlk;
      ro += dstObj * rd;
      idObj = idBlk;
      vn = vnBlk;
      col4 = vec4 (HsvToRgb (vec3 (hitBlk / nBlk, 1., 1.)), 0.2) *
         (1. - 0.4 * step (0.8 * bEdge, Maxv2 (abs (qBlk))));
    } else {
      ro += dstObj * rd;
      vn = (idObj == idGr) ? GearNf (ro) : ObjNf (ro);
      if (idObj == idWhl) {
        col4 = vec4 (0.9, 0.7, 0.3, 0.2);
        q = ro - vec3 (1.1 + bEdge + 0.03, bEdge, 1.);
        r = length (q.yz);
        q.yz = Rot2D (q.yz, - angRot);
        a = fract (64. * atan (q.z, - q.y) / (2. * pi) + 0.5);
        if (r > 0.99) vn.yz = Rot2D (vn.yz, - sin (a - 0.5));
        if (r > 0.92) col4 *= 0.7 + 0.3 * SmoothBump (0.05, 0.95, 0.01, a);
        isMet = true;
      } else if (idObj == idGr) {
        col4 = vec4 (0.9, 0.8, 0.4, 0.2);
        isMet = true;
      } else if (idObj == idSpl) {
        col4 = vec4 (0.8, 0.8, 0.85, 0.2) * (1. - 0.4 * step (abs (ro.z), 0.1));
        isMet = true;
      } else if (idObj == idAx) {
        col4 = vec4 (0.8, 0.8, 0.85, 0.2);
        isMet = true;
      } else if (idObj == idPln) {
        col4 = (abs (vn.y) > 0.99) ? vec4 (0.5, 0.6, 0.2, 0.05) : vec4 (0.7, 0.5, 0.4, 0.1);
      } else if (idObj == idConv) {
        q = ro - vec3 (-0.05, -0.21, 0.);
        col4 = vec4 (0.8, 0.8, 0.4, 0.);
        if (sign (vn.y) != sign (q.y)) {
          if (abs (q.x) < 1. && abs (vn.y) > 0.5) col4 *= 1. - 0.1 * SmoothBump (0.45, 0.55, 0.03,
           fract (10. * (q.x - sign (q.y) * mod (tMov, 20.) * 2.1 / 5.)));
        } else col4 *= 0.8 + 0.2 * smoothstep (0., 0.01, abs (abs (q.z) - 0.07));
      } else if (idObj == idSup) {
        col4 = vec4 (0.7, 0.5, 0.4, 0.1);
        isMet = true;
      } else if (idObj == idBas) {
        q = ro;
        q.z -= 0.9;
        if (Maxv2 (abs (q.xz) - vec2 (1.65, 1.45)) > 0.) {
          col4 = vec4 (0.9, 0.9, 0.9, 0.2);
          isMet = true;
        } else {
          col4 = vec4 (0.3, 0.5, 0.4, 0.);
        }
        col4 *= (0.5 + 0.5 * step (0., Maxv2 (abs (vec2 (q.x, q.z + 1.3)) - vec2 (0.4, 0.02)))) *
           (0.7 + 0.3 * step (0., abs (PrCaps2Df (vec2 (q.z + 1.3, q.x), 0.08, 0.5)) - 0.01));
      } else if (idObj == idCon) {
        col4 = vec4 (0., 1., 1., 0.2);
        if (length (ro.xz - wgObj.xz) < 0.6 * wgObj.w)
           col4 = mix (0.8 * col4, vec4 (1., 0., 1., 0.2), step (0., sin (2. * pi * tCur)));
      }
    }
    sh = min (ObjSShadow (ro, ltDir), GearSShadow (ro, ltDir));
    sh = 0.6 + 0.4 * min (sh, BlkHitSh (ro + 0.01 * ltDir, ltDir, 6.));
    nDotL = max (dot (vn, ltDir), 0.);
    if (isMet) nDotL *= nDotL;
    col = col4.rgb * (0.1 + 0.1 * max (- dot (vn, ltDir), 0.) + 0.9 * sh * nDotL) +
       col4.a * step (0.95, sh) * sh * pow (max (0., dot (ltDir, reflect (rd, vn))), 32.);
    if (isMet) {
      rd = reflect (rd, vn);
      col = mix (col, vec3 (1.), 0.01 * step (0.1, Minv2 (fract (8. * vec2 (atan (rd.z, rd.x),
         2. * asin (rd.y)) + 0.5) - 0.5)));
    }
  } else col = vec3 (0., 0., 0.1) * (1. + 0.9 * rd.y);
  return clamp (col, 0., 1.);
}

void mainImage (out vec4 fragColor, in vec2 fragCoord)
{
  mat3 vuMat;
  vec4 stDat;
  vec3 ro, rd, col;
  vec2 canvas, uv;
  float el, az, zmFac, sr;
  canvas = iResolution.xy;
  uv = 2. * fragCoord.xy / canvas - 1.;
  uv.x *= canvas.x / canvas.y;
  tCur = iTime;
  dstFar = 30.;
  stDat = Loadv4 (0);
  tMov = stDat.x;
  cnPos = stDat.y;
  wgObj = vec4 (cnPos - 0.5, -1.12, -0.4, 0.08);
  stDat = Loadv4 (1);
  az = stDat.x;
  el = stDat.y;
  vuMat = StdVuMat (el, az);
  zmFac = 4.;
  ro = vuMat * vec3 (0., 0., -8.);
  ro.z += 0.9;
  rd = vuMat * normalize (vec3 (uv, zmFac));
  ltDir = vuMat * normalize (vec3 (-0.5, 1., -1.));
#if ! AA
  const float naa = 1.;
#else
  const float naa = 3.;
#endif  
  col = vec3 (0.);
  sr = 2. * mod (dot (mod (floor (0.5 * (uv + 1.) * canvas), 2.), vec2 (1.)), 2.) - 1.;
  for (float a = float (VAR_ZERO); a < naa; a ++) {
    rd = vuMat * normalize (vec3 (uv + step (1.5, naa) * Rot2D (vec2 (0.5 / canvas.y, 0.),
       sr * (0.667 * a + 0.5) * pi), zmFac));
    col += (1. / naa) * ShowScene (ro, rd);
  }
  fragColor = vec4 (col, 1.);
}

float PrBoxDf (vec3 p, vec3 b)
{
  vec3 d;
  d = abs (p) - b;
  return min (max (d.x, max (d.y, d.z)), 0.) + length (max (d, 0.));
}

float PrRoundBoxDf (vec3 p, vec3 b, float r)
{
  return length (max (abs (p) - b, 0.)) - r;
}

float PrCylDf (vec3 p, float r, float h)
{
  return max (length (p.xy) - r, abs (p.z) - h);
}

float PrRoundCylDf (vec3 p, float r, float rt, float h)
{
  return length (max (vec2 (length (p.xy) - r, abs (p.z) - h), 0.)) - rt;
}

float PrCaps2Df (vec2 p, float r, float h)
{
  return length (p - vec2 (0., clamp (p.y, - h, h))) - r;
}

float Minv3 (vec3 p)
{
  return min (p.x, min (p.y, p.z));
}

float Maxv3 (vec3 p)
{
  return max (p.x, max (p.y, p.z));
}

float Minv2 (vec2 p)
{
  return min (p.x, p.y);
}

float Maxv2 (vec2 p)
{
  return max (p.x, p.y);
}

float SmoothMin (float a, float b, float r)
{
  float h;
  h = clamp (0.5 + 0.5 * (b - a) / r, 0., 1.);
  return mix (b - h * r, a, h);
}

float SmoothMax (float a, float b, float r)
{
  return - SmoothMin (- a, - b, r);
}

float SmoothBump (float lo, float hi, float w, float x)
{
  return (1. - smoothstep (hi - w, hi + w, x)) * smoothstep (lo - w, lo + w, x);
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

vec2 Rot2D (vec2 q, float a)
{
  vec2 cs;
  cs = sin (a + vec2 (0.5 * pi, 0.));
  return vec2 (dot (q, vec2 (cs.x, - cs.y)), dot (q.yx, cs));
}

vec3 HsvToRgb (vec3 c)
{
  return c.z * mix (vec3 (1.), clamp (abs (fract (c.xxx + vec3 (1., 2./3., 1./3.)) * 6. - 3.) - 1., 0., 1.), c.y);
}

#define txBuf iChannel0
#define txSize iChannelResolution[0].xy

const float txRow = 128.;

vec4 Loadv4 (int idVar)
{
  float fi;
  fi = float (idVar);
  return texture (txBuf, (vec2 (mod (fi, txRow), floor (fi / txRow)) + 0.5) / txSize);
}
