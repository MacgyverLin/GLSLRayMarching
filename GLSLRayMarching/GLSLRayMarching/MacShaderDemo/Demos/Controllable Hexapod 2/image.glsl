// "Controllable Hexapod 2" by dr2 - 2021
// License: Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License

float PrRoundBoxDf (vec3 p, vec3 b, float r);
float PrSphDf (vec3 p, float r);
float PrCylDf (vec3 p, float r, float h);
float PrRoundCylDf (vec3 p, float r, float rt, float h);
float PrTorusDf (vec3 p, float ri, float rc);
float SmoothMin (float a, float b, float r);
float SmoothMax (float a, float b, float r);
float SmoothBump (float lo, float hi, float w, float x);
mat3 StdVuMat (float el, float az);
vec2 Rot2D (vec2 q, float a);
vec3 HsvToRgb (vec3 c);
float Hashfv2 (vec2 p);
float Noisefv2 (vec2 p);
float Fbm2 (vec2 p);
vec4 Loadv4 (int idVar);

#define VAR_ZERO min (iFrame, 0)

vec3 footPos[6], legAng[6], bdyPos, ltPos[3], ltCol[3], qHit;
vec2 hipPos[6], kneePos[6];
float tCur, dstFar, bdyRad, legLen, walkDir, hdAng;
int idObj;
bool doSh;
const int idLeg = 1, idPiv = 2, idFoot = 3, idBod = 4, idAx = 5, idNek = 6, idRad = 7, idLmp = 8,
   idHead = 9, idEye = 10, idAnt = 11;
const float pi = 3.14159;

#define DMINQ(id) if (d < dMin) { dMin = d;  idObj = id;  qHit = q; }

void BugGeom ()
{
  float dr, dxz, dy, ll;
  ll = 4. * legLen * legLen;
  for (int m = VAR_ZERO; m < 6; m ++) {
    dr = length (footPos[m].xz);
    hipPos[m] = bdyRad * vec2 (sin (pi * float (2 * m + 1) / 6. + vec2 (0.5 * pi, 0.)));
    legAng[m].x = - atan (footPos[m].z, footPos[m].x);
    dxz = 0.5 * dr + bdyPos.y * sqrt (ll / dot (footPos[m], footPos[m]) - 0.25);
    dy = sqrt (ll - dxz * dxz);
    kneePos[m] = vec2 (dxz, dy);
    legAng[m].y = atan (dxz, dy);
    legAng[m].z = atan (dr - dxz, - sqrt (ll - (dr - dxz) * (dr - dxz)));
  }
}

float BugDf (vec3 p, float dMin)
{
  vec3 q, qq;
  float d, y, a;
  for (int m = VAR_ZERO; m < 6; m ++) {
    q = p;
    q.xz = Rot2D (q.xz - hipPos[m], legAng[m].x);
    q.xy = Rot2D (q.xy, legAng[m].y);
    d = PrRoundCylDf (q, 0.12, 0.02, 0.08);
    DMINQ (idPiv);
    q.y -= legLen;
    y = q.y / legLen;
    d = PrCylDf (vec3 (abs (q.xz) - 0.032 * (1. - 0.375 * y), q.y), 0.02 * (1. + 0.1 * abs (cos (16. * pi * y))), legLen);
    DMINQ (idLeg);
    q.y -= legLen;
    d = PrRoundCylDf (q, 0.05, 0.02, 0.03);
    DMINQ (idPiv);
    q.xy = Rot2D (q.xy, legAng[m].z - legAng[m].y);
    q.y -= legLen;
    y = q.y / legLen;
    d = PrCylDf (vec3 (q.x, abs (q.z) - 0.02 * (1. - 0.25 * y), q.y), 0.012 * (1. + 0.1 * abs (cos (16. * pi * y))), legLen);
    DMINQ (idLeg);
    q.y -= legLen;
    q.xy = Rot2D (q.xy, - legAng[m].z);
    q.y -= 0.04 * legLen;
    d = PrCylDf (q.xzy, 0.08, 0.04 * legLen);
    DMINQ (idFoot);
  }
  q = p;
  q.xz = Rot2D (q.xz, pi / 6.);
  qq = q;
  a = atan (q.z, - q.x) / (2. * pi);
  q.xz = Rot2D (q.xz, 2. * pi * (floor (6. * a + 0.5) / 6.));
  q.x -= - bdyRad + 0.1;
  d = PrRoundCylDf (q.xzy, 0.13, 0.02, 0.15);
  DMINQ (idAx);
  q = qq;
  q.xz = Rot2D (q.xz, 2. * pi * (floor (18. * a + 0.5) / 18.));
  q.x -= - bdyRad;
  d = PrRoundCylDf (q.yzx, 0.025, 0.01, 0.03);
  q = vec3 (q.yz, a).xzy;
  DMINQ (idLmp);
  q = p;
  d = min (PrTorusDf (vec3 (q.xz, abs (q.y) - 0.06), 0.015, bdyRad - 0.016),
      length (vec2 (q.y - 0.2, abs (abs (q.z) - 0.36) - 0.16)) - 0.012);
  d = SmoothMax (PrRoundCylDf (q.xzy, bdyRad - 0.12, 0.1, 0.1), - d, 0.01);
  d = max (d, - PrSphDf (vec3 (mod (q.x + 0.06, 0.12) - 0.06, q.y - 0.2, abs (q.z) - 0.36), 0.025));
  DMINQ (idBod);
  q = p;
  q.xy -= vec2 (-0.7 * bdyRad, 0.2);
  d = PrCylDf (q.xzy, 0.05, 0.08);
  DMINQ (idRad);
  q.y -= 0.22;
  q.xz = Rot2D (q.xz, 2. * tCur);
  d = PrTorusDf (q, 0.02, 0.15);
  DMINQ (idRad);
  q = p;
  q.xy -= vec2 (0.7 * bdyRad, 0.25);
  d = PrCylDf (q.xzy, 0.12, 0.08);
  DMINQ (idNek);
  q.y -= 0.24;
  q.xz = Rot2D (q.xz, hdAng);
  d = PrRoundBoxDf (q, vec3 (0.3, 0.2, 0.27) - 0.1, 0.1);
  d = max (d, - PrCylDf (vec3 (q.x - 0.3, q.y + 0.07, q.z).xzy, 0.1, 0.02));
  d = max (d, - min (PrSphDf (vec3 (q.x, abs (q.yz)) - vec3 (-0.3, 0.05, 0.1), 0.03),
     PrSphDf (vec3 (q.x, abs (q.yz)) - vec3 (-0.15, 0.05, 0.27), 0.03)));
  DMINQ (idHead);
  qq = q;
  q.z = abs (q.z);
  q -= vec3 (0.15, 0.25, 0.15);
  q.yz = Rot2D (q.yz, -0.1 * pi);
  q.xy = Rot2D (q.xy, 0.05 * pi);
  d = min (PrCylDf (q.xzy, 0.02, 0.25), PrRoundCylDf (vec3 (q.xz, q.y - 0.26), 0.06, 0.01, 0.01));
  DMINQ (idAnt);
  q = qq;
  q.xy -= vec2 (0.1, 0.08);
  d = PrRoundCylDf (q.xzy, 0.3, 0.02, 0.04);
  DMINQ (idEye);
  return 0.95 * dMin;
}

float ObjDf (vec3 p)
{
  vec3 q;
  float dMin, d;
  dMin = dstFar;
  q = p;
  q -= bdyPos;
  if (! doSh) d = PrCylDf (q.xzy, bdyRad + 1.6, 1.1);
  if (doSh || d < 0.1) {
    q.xz = Rot2D (q.xz, - walkDir);
    dMin = BugDf (q, dMin);
  } else dMin = d;
  return dMin;
}

float ObjRay (vec3 ro, vec3 rd)
{
  float dHit, d;
  dHit = 0.;
  for (int j = VAR_ZERO; j < 120; j ++) {
    d = ObjDf (ro + dHit * rd);
    if (d < 0.0005 || dHit > dstFar) break;
    dHit += d;
  }
  return dHit;
}

vec3 ObjNf (vec3 p)
{
  vec4 v;
  vec2 e = vec2 (0.0002, -0.0002);
  for (int j = VAR_ZERO; j < 4; j ++) {
    v[j] = ObjDf (p + ((j < 2) ? ((j == 0) ? e.xxx : e.xyy) : ((j == 2) ? e.yxy : e.yyx)));
  }
  v.x = - v.x;
  return normalize (2. * v.yzw - dot (v, vec4 (1.)));
}

float ObjSShadow (vec3 ro, vec3 rd, float dMax)
{
  float sh, d, h;
  doSh = true;
  sh = 1.;
  d = 0.01;
  for (int j = VAR_ZERO; j < 30; j ++) {
    h = ObjDf (ro + d * rd);
    sh = min (sh, smoothstep (0., 0.05 * d, h));
    d += h;
    if (sh < 0.001 || d > dMax) break;
  }
  doSh = false;
  return 0.5 + 0.5 * sh;
}

vec3 ShowWg (vec2 uv, vec2 canvas, vec3 col, int wgSel)
{
  vec4 wgBx[4], w1, w2;
  vec2 s;
  float asp, d, w;
  bool isCol;
  asp = canvas.x / canvas.y;
  w1 = vec4 (0.42 * asp, -0.35, 0.025, 0.);
  w2 = vec4 (0.06, 0., 0., 0.);
  wgBx[0] = w1 + w2.yxzw;
  wgBx[1] = w1 - w2.yxzw;
  wgBx[2] = w1 - w2;
  wgBx[3] = w1 + w2;
  for (int k = 0; k < 4; k ++) {
    s = 0.5 * uv - wgBx[k].xy;
    w = (length (s) - wgBx[k].z) * canvas.y;
    isCol = false;
    if (w < 1.5) {
      isCol = (abs (w) < 1.5);
      if (! isCol) {
        if (k == 0) d = max (abs (s.x) + s.y, -2. * s.y);
        else if (k == 1) d = max (abs (s.x), abs (s.y));
        else if (k == 2) d = max (abs (s.y) - s.x, 2. * s.x);
        else if (k == 3) d = max (abs (s.y) + s.x, -2. * s.x);
        isCol = (d < 0.4 * wgBx[k].z);
      }
    }
    if (isCol) col = mix (col, (k == wgSel) ? vec3 (1.) : vec3 (0.3), 0.7);
  }
  return col;
}

vec4 ObjCol ()
{
  vec4 col4, col4B, col4H;
  float s;
  s = length (qHit.xz);
  col4B = vec4 (0.95, 0.95, 1., 0.2);
  col4H = vec4 (0.9, 0.95, 0.9, 0.2);
  if (idObj == idLeg) col4 = vec4 (1., 0.8, 0.8, 0.2);
  else if (idObj == idPiv) col4 = col4B * (0.5 + 0.5 * smoothstep (0., 0.01, length (qHit.xy) - 0.03));
  else if (idObj == idAx) col4 =  col4B * (0.5 + 0.5 * smoothstep (0., 0.01, s - 0.08));
  else if (idObj == idBod) col4 = col4B;
  else if (idObj == idHead) col4 = mix (col4H, vec4 (1., 0., 0., -1.), step (abs (qHit.y + 0.07), 0.02) *
     step (0., qHit.x) * step (abs (qHit.z), 0.1));
  else if (idObj == idAnt) col4 = mix (col4B * (0.6 + 0.4 * SmoothBump (0.1, 0.9, 0.05, mod (32. * qHit.y, 1.))),
     vec4 (1., 1., 0., -1.), step (0.26, qHit.y) * step (s, 0.05) * step (-0.5, sin (8. * pi * tCur)));
  else if (idObj == idEye) col4 = mix (col4H, vec4 (0., 0., 1., -1.), step (-0.12, qHit.x) *
     step (cos (16. * atan (qHit.z, qHit.x)), 0.7) * step (abs (qHit.y), 0.03));
  else if (idObj == idFoot) col4 = 0.8 * col4B * (0.5 + 0.5 * smoothstep (0., 0.01, s - 0.04));
  else if (idObj == idNek) col4 = col4H;
  else if (idObj == idRad) col4 = 0.9 * col4B;
  else if (idObj == idLmp) col4 = mix (col4B, vec4 (HsvToRgb (vec3 (mod (qHit.y + 0.3 * tCur, 1.), 0.8, 1.)), -1.),
     step (s, 0.03));
  return col4;
}

#define REFLECT 0 // optional reflection

vec3 ShowScene (vec3 ro, vec3 rd)
{
  vec4 col4;
  vec3 col, vn, roo, ltDir, ltAx, c;
  float dstObj, nDotL, sh, att, ltDst;
  BugGeom ();
  doSh = false;
  dstObj = ObjRay (ro, rd);
#if REFLECT
  if (dstObj >= dstFar && rd.y < 0.) {
    roo = ro;
    ro += (- ro.y / rd.y) * rd;
    if (length (max (abs (mod (ro.xz + 0.5, 1.) - 0.5) - 0.4, 0.)) < 0.05) {
      rd = reflect (rd, vec3 (0., 1., 0.));
      ro += 0.01 * rd;
      dstObj = ObjRay (ro, rd);
    } else ro = roo;
  }
#endif
  if (dstObj < dstFar) {
    ro += dstObj * rd;
    vn = ObjNf (ro);
    col4 = ObjCol ();
  } else if (rd.y < 0.) {
    dstObj = - ro.y / rd.y;
    ro += dstObj * rd;
    vn = vec3 (0., 1., 0.);
    col4 = vec4 (0.7, 0.7, 0.7, 0.) * (1. - 0.1 * Noisefv2 (256. * ro.xz)) * (1. - 0.2 * Fbm2 (4. * ro.xz));
    col4.rgb = mix (col4.rgb, vec3 (0.5), smoothstep (0.05, 0.08,
       length (max (abs (mod (ro.xz + 0.5, 1.) - 0.5) - 0.4, 0.))));
  }
  if (dstObj < dstFar) {
    if (col4.a >= 0.) {
      col = vec3 (0.);
      for (int k = VAR_ZERO; k < 3; k ++) {
        ltDir = ltPos[k] - ro;
        ltDst = length (ltDir);
        ltDir /= ltDst;
        ltAx = normalize (ltPos[k] - vec3 (bdyPos.xz, 0.).xzy);
        att = smoothstep (0., 0.01, dot (ltDir, ltAx) - 0.985);
        sh = (dstObj < dstFar) ? ObjSShadow (ro + 0.01 * vn, ltDir, ltDst) : 1.;
        nDotL = max (dot (vn, ltDir), 0.);
        if (col4.a > 0.) nDotL *= nDotL * nDotL;
        c = att * ltCol[k] * (col4.rgb * (0.15 + 0.85 * sh * nDotL) +
           col4.a * step (0.95, sh) * sh * pow (max (dot (normalize (ltDir - rd), vn), 0.), 32.));
        col += pow (c, vec3 (2.));
      }
      col = pow (col, 1. / vec3 (2.));
    } else col = col4.rgb * (0.2 + 0.8 * max (0., - dot (vn, rd)));
  } else col = vec3 (0.);
  return clamp (col, 0., 1.);
}

void mainImage (out vec4 fragColor, in vec2 fragCoord)
{
  mat3 vuMat;
  vec4 stDat;
  vec3 ro, rd, col;
  vec2 canvas, uv;
  float el, az;
  int wgSel;
  canvas = iResolution.xy;
  uv = 2. * fragCoord.xy / canvas - 1.;
  uv.x *= canvas.x / canvas.y;
  tCur = iTime;
  hdAng = 0.2 * pi * sin (tCur);
  legLen = 0.5;
  for (int k = VAR_ZERO; k < 6; k ++) {
    stDat = Loadv4 (k);
    footPos[k] = stDat.xyz;
  }
  stDat = Loadv4 (6);
  bdyPos = stDat.xyz;
  walkDir = stDat.w;
  stDat = Loadv4 (9);
  bdyRad = stDat.y;
  stDat = Loadv4 (10);
  az = stDat.x;
  el = stDat.y;
  wgSel = int (stDat.z);
  vuMat = StdVuMat (el, az);
  rd = vuMat * normalize (vec3 (uv, 5.));
  ro = bdyPos * vec3 (1., 0., 1.) + vuMat * vec3 (0., 0.2, -10.);
  dstFar = 30.;
  for (int k = VAR_ZERO; k < 3; k ++) {
    ltPos[k] = vec3 (0., 30., 0.);
    ltPos[k].xy = Rot2D (ltPos[k].xy, 0.25 * pi * (1. + 0.2 * sin (0.05 * pi * tCur - pi * float (k) / 3.)));
    ltPos[k].xz = Rot2D (ltPos[k].xz, 0.1 * pi * tCur + pi * float (k) / 3.);
    ltPos[k].xz += bdyPos.xz;
  }
  ltCol[0] = vec3 (1., 0.5, 0.5);
  ltCol[1] = ltCol[0].gbr;
  ltCol[2] = ltCol[0].brg;
  dstFar = 30.;
  col = ShowScene (ro, rd);
  col = ShowWg (uv, canvas, col, wgSel);
  fragColor = vec4 (col, 1.);
}

float PrRoundBoxDf (vec3 p, vec3 b, float r)
{
  return length (max (abs (p) - b, 0.)) - r;
}

float PrSphDf (vec3 p, float r)
{
  return length (p) - r;
}

float PrCylDf (vec3 p, float r, float h)
{
  return max (length (p.xy) - r, abs (p.z) - h);
}

float PrRoundCylDf (vec3 p, float r, float rt, float h)
{
  return length (max (vec2 (length (p.xy) - r, abs (p.z) - h), 0.)) - rt;
}

float PrTorusDf (vec3 p, float ri, float rc)
{
  return length (vec2 (length (p.xy) - rc, p.z)) - ri;
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

vec3 HsvToRgb (vec3 c)
{
  return c.z * mix (vec3 (1.), clamp (abs (fract (c.xxx + vec3 (1., 2./3., 1./3.)) * 6. - 3.) - 1., 0., 1.), c.y);
}

const float cHashM = 43758.54;

vec2 Hashv2v2 (vec2 p)
{
  vec2 cHashVA2 = vec2 (37., 39.);
  return fract (sin (vec2 (dot (p, cHashVA2), dot (p + vec2 (1., 0.), cHashVA2))) * cHashM);
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

#define txBuf iChannel0
#define txSize iChannelResolution[0].xy

const float txRow = 128.;

vec4 Loadv4 (int idVar)
{
  float fi;
  fi = float (idVar);
  return texture (txBuf, (vec2 (mod (fi, txRow), floor (fi / txRow)) + 0.5) / txSize);
}
