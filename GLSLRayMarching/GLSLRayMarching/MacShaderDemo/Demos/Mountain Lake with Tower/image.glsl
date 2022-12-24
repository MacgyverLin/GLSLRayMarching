// "Mountain Lake with Tower" by dr2 - 2021
// License: Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License

float PrCapsDf (vec3 p, float r, float h);
float SmoothBump (float lo, float hi, float w, float x);
mat3 StdVuMat (float el, float az);
mat3 DirVuMat (vec3 vd);
vec2 Rot2D (vec2 q, float a);
vec2 Rot2Cs (vec2 q, vec2 cs);
float Noisefv2 (vec2 p);
vec2 Noisev2v4 (vec4 p);
float Fbm2 (vec2 p);
vec3 VaryNf (vec3 p, vec3 n, float f);

vec4 szFlr;
vec3 sunDir;
float dstFar, tCur, grndScl, twrScl, flSpc, nFlr, twrRad, bSizeV, cIdV, vShift;
int idObj;
const int idFlr = 1, idStr = 2, idRl = 3, idStn = 4, idCln = 5;
const float pi = 3.1415927, sqrt2 = 1.41421;

#define VAR_ZERO min (iFrame, 0)

#define DMIN(id) if (d < dMin) { dMin = d;  idObj = id; }

float GrndDf (vec3 p)
{
  vec3 q;
  float d, h, a, r, s, f;
  q = p / grndScl;
  r = length (q.xz);
  d = p.y;
  if (r > 0.) {
    a = atan (q.z, - q.x) / (2. * pi) + 0.5;
    s = sqrt (r) / (2. * pi);
    f = 22.;
    h = 6. * s * mix (Fbm2 (f * vec2 (s, a + 1.)), Fbm2 (f * vec2 (s, a)), a);
    d = max (r - 20., q.y - (h * smoothstep (1.4, 2.6, r) - 0.5 * (1. - smoothstep (0.5, 1.4, r)) - 0.01));
  }
  return grndScl * d;
}

float GrndRay (vec3 ro, vec3 rd)
{
  vec3 p;
  float dHit, h, s, sLo, sHi;
  s = 0.;
  sLo = 0.;
  dHit = dstFar;
  for (int j = VAR_ZERO; j < 120; j ++) {
    p = ro + s * rd;
    h = GrndDf (p);
    if (h < 0.) break;
    sLo = s;
    s += max (0.001, h);
    if (s > dstFar) break;
  }
  if (h < 0.) {
    sHi = s;
    for (int j = VAR_ZERO; j < 10; j ++) {
      s = 0.5 * (sLo + sHi);
      p = ro + s * rd;
      if (GrndDf (p) > 0.) sLo = s;
      else sHi = s;
    }
    dHit = 0.5 * (sLo + sHi);
  }
  return dHit;
}

vec3 GrndNf (vec3 p)
{
  vec4 v;
  vec2 e;
  e = vec2 (0.001, -0.001);
  for (int j = VAR_ZERO; j < 4; j ++) {
    v[j] = GrndDf (p + ((j < 2) ? ((j == 0) ? e.xxx : e.xyy) : ((j == 2) ? e.yxy : e.yyx)));
  }
  v.x = - v.x;
  return normalize (2. * v.yzw - dot (v, vec4 (1.)));
}

float ObjDf (vec3 p)
{
  vec3 q;
  float dMin, d, stSpc, xLim1, xLim2, bRad, r, a, x;
  bool topFlr, botFlr;
  dMin = dstFar / twrScl;
  p /= twrScl;
  r = length (p.xz) - twrRad;
  d = r - 20.;
  if (d < 1.) {
    a = 2. * pi * ((floor (6. * atan (p.x, - p.z) / (2. * pi)) + 0.5) / 6.);
    stSpc = 6.;
    xLim1 = abs (dot (p.xz, sin (a + vec2 (0.5 * pi, 0.)))) - 22.;
    xLim2 = xLim1 + 16.;
    bRad = 0.5;
    topFlr = (cIdV == 2. * nFlr - 1.);
    botFlr = (cIdV == 0.);
    if (topFlr) {
      d = length (max (abs (vec2 (p.y + 0.5 * szFlr.w, r + szFlr.z + stSpc)) - vec2 (0.5 * szFlr.w, szFlr.z), 0.));
      DMIN (idFlr);
      d = max (length (vec2 (p.y + 0.4, abs (r + szFlr.z + stSpc - 0.5)) - (szFlr.z - 0.1)) - bRad, - xLim2);
      DMIN (idRl);
    }
    d = max (length (max (abs (vec2 ((topFlr ? - p.y : abs (p.y)) - flSpc,
       r - 0.4 * (szFlr.z + stSpc))) - vec2 (szFlr.w, 1.4 * (szFlr.z + stSpc)), 0.)), - xLim1);
    DMIN (idFlr);
    d = max (length (max (abs (vec2 (p.y + szFlr.w, r)) - vec2 (szFlr.w, 2. * szFlr.z + stSpc + 0.5), 0.)), xLim2);
    DMIN (idFlr);
    p.zx = Rot2D (p.zx, a);
    p.z = abs (p.z) - twrRad;
    x = abs (p.x) - szFlr.x;
    for (float sz = -1.; sz <= 1.; sz += 2.) {
      if (! topFlr || sz < 0.) {
        q.x = x;
        q.yz = p.yz - sz * vec2 (szFlr.y - szFlr.w, - (szFlr.z + stSpc));
        d = abs (q.y) - (szFlr.y - szFlr.w - 0.005);
        q.xy = vec2 (q.x + sz * q.y, - sz * q.x + q.y) / sqrt2;
        d = max (max (max (q.y - 0.5 * sqrt2 - abs (0.5 * sqrt2 - mod (q.x, sqrt2)), abs (q.z) - szFlr.z), -1. - q.y), d);
        DMIN (idStr);
      }
    }
    d = max (length (vec2 (p.y + flSpc - 4., abs (r - szFlr.z) - (2. * szFlr.z + stSpc - 0.8))) - bRad, - xLim1);
    DMIN (idRl);
    d = max (length (vec2 (p.y - 3.5, abs (r - 0.4) - (2. * szFlr.z + stSpc - 0.1))) - bRad, xLim2);
    DMIN (idRl);
    q = vec3 (x - 4., p.y + 0.5 * flSpc, abs (p.z - (szFlr.z + stSpc)) - szFlr.z);
    d = max (length (vec2 ((q.x + q.y) / sqrt2, q.z)) - bRad, abs (x) - 8.);
    DMIN (idRl);
    q.xz = vec2 (x + 4., abs (p.z + szFlr.z + stSpc) - szFlr.z);
    if (! botFlr) {
      d = max (length (vec2 ((q.x - (p.y + 1.5 * flSpc)) / sqrt2, q.z)) - bRad, abs (x) - 8.);
      DMIN (idRl);
    }
    if (! topFlr) {
      d = max (length (vec2 ((q.x - (p.y - 0.5 * flSpc)) / sqrt2, q.z)) - bRad, abs (x) - 8.);
      DMIN (idRl);
    }
    x = abs (p.x);
    q.x = x - 22.;
    d = min (length (vec2 (q.x, p.y + flSpc - 4.)), length (vec2 (x - 6., p.y - 3.5))) - bRad;
    d = max (d, max (abs (p.z) - (2. * szFlr.z + stSpc), szFlr.z - abs (abs (p.z) - (szFlr.z + stSpc))));
    DMIN (idRl);
    q.yz = vec2 (p.y + flSpc - 2.5, abs (abs (p.z) - (szFlr.z + stSpc)) - szFlr.z);
    d = PrCapsDf (q.xzy, 0.7, 2.);
    DMIN (idStn);
    if (! topFlr) {
      d = length (vec2 (q.x, p.z)) - 0.8;
      DMIN (idCln);
    }
    d = PrCapsDf (vec3 (x - 6., p.y - 2.5, q.z).xzy, 0.7, 2.);
    DMIN (idStn);
    dMin *= 0.7;
  } else dMin = d;
  return twrScl * dMin;
}

float ObjRay (vec3 ro, vec3 rd)
{
  vec3 p;
  float dHit, d, eps, sy;
  eps = 0.0005;
  dHit = eps;
  if (rd.y == 0.) rd.y = 0.001;
  for (int j = VAR_ZERO; j < 220; j ++) {
    p = ro + dHit * rd;
    p.y -= vShift;
    cIdV = floor (p.y / bSizeV);
    sy = (bSizeV * (cIdV + step (0., rd.y)) - p.y) / rd.y;
    d = abs (sy) + eps;
    if (cIdV >= 0. && cIdV < 2. * nFlr) {
      p.y -= bSizeV * (cIdV + 0.5);
      d = min (ObjDf (p), d);
    }
    dHit += d;
    if (d < eps || dHit > dstFar) break;
  }
  if (d >= eps) dHit = dstFar;
  return dHit;
}

vec3 ObjNf (vec3 p)
{
  vec4 v;
  vec2 e;
  e = vec2 (0.001, -0.001);
  p.y -= vShift;
  cIdV = floor (p.y / bSizeV);
  p.y -= bSizeV * (cIdV + 0.5);
  for (int j = VAR_ZERO; j < 4; j ++) {
    v[j] = ObjDf (p + ((j < 2) ? ((j == 0) ? e.xxx : e.xyy) : ((j == 2) ? e.yxy : e.yyx)));
  }
  v.x = - v.x;
  return normalize (2. * v.yzw - dot (v, vec4 (1.)));
}

vec3 SkyCol (vec3 ro, vec3 rd)
{
  vec3 col, clCol;
  vec2 q;
  float f, fd, ff;
  q = 0.005 * (ro.xz + 5. * tCur * vec2 (0.5, 2.) + ((200. - ro.y) / rd.y) * rd.xz);
  ff = Fbm2 (q);
  f = smoothstep (0.1, 0.8, ff);
  fd = smoothstep (0.1, 0.8, Fbm2 (q + 0.01 * sunDir.xz)) - f;
  clCol = (0.8 + 0.5 * ff) * (vec3 (0.7) - 0.7 * vec3 (0.3, 0.3, 0.2) * sign (fd) * smoothstep (0., 0.05, abs (fd)));
  fd = smoothstep (0.01, 0.1, rd.y);
  col = mix (mix (vec3 (0.8, 0.8, 0.75), vec3 (0.4, 0.5, 0.8), 0.3 + 0.7 * fd), clCol, 0.1 + 0.9 * f * fd);
  return col;
}

float WaveHt (vec2 p)
{
  mat2 qRot;
  vec4 t4, v4;
  vec2 q, w;
  float wFreq, wAmp, tWav, ht, s;
  qRot = mat2 (0.8, -0.6, 0.6, 0.8);
  tWav = 0.5 * tCur;
  wFreq = 1.;
  wAmp = 1.;
  s = length (p);
  ht = 0.3 * (1. + sin (4. * s - 4. * tCur));
  q = 0.3 * p;
  for (int j = VAR_ZERO; j < 3; j ++) {
    q *= qRot;
    t4 = (q.xyxy + (tWav * vec2 (1., -1.)).xxyy) * wFreq;
    t4 += 2. * Noisev2v4 (t4).xxyy - 1.;
    v4 = (1. - abs (sin (t4))) * (abs (sin (t4)) + abs (cos (t4)));
    w = 1. - sqrt (v4.xz * v4.yw);
    w *= w;
    w *= w;
    w *= w;
    ht += wAmp * (w.x + w.y);
    wFreq *= 2.;
    wAmp *= 0.5;
  }
  return 0.3 * ht / (1. + 0.02 * s);
}

vec3 WaveNf (vec3 p, float d)
{
  vec3 vn;
  vec2 e;
  e = vec2 (max (0.01, 0.001 * d * d), 0.);
  return normalize (vec3 (WaveHt (p.xz) - vec2 (WaveHt (p.xz + e.xy), WaveHt (p.xz + e.yx)), e.x).xzy);
}

vec4 GrndCol (vec3 ro, vec3 vn)
{
  vec4 col4;
  float a;
  a = atan (ro.z, - ro.x);
  col4 = mix (vec4 (0.45, 0.4, 0.4, 0.1), vec4 (0.35, 0.3, 0.25, 0.1),
     smoothstep (0., 0.04, ro.y / grndScl + 0.005 * sin (32. * a)));
  if (ro.y > 0.) {
    col4 = mix (col4, vec4 (0.25, 0.4, 0.25, 0.), smoothstep (0.1, 0.2, 1. - vn.y));
    col4 = mix (col4, vec4 (0.6, 0.5, 0.3, 0.1), smoothstep (0.2, 0.35, 1. - vn.y));
    col4 = mix (col4, vec4 (0.65, 0.6, 0.5, 0.1), smoothstep (0.35, 0.45, 1. - vn.y));
    col4 = mix (col4, vec4 (1., 1., 1., 0.4), smoothstep (0.65, 0.95, ro.y / grndScl + 0.2 * sin (8. * a)));
  }
  return col4;
}

vec4 ObjCol (vec3 ro, vec3 vn)
{
  vec4 col4;
  if (idObj == idFlr) {
    col4 = vec4 (0.4, 0.7, 0.2, 0.1);
    if (vn.y > 0.99) col4 *= 0.8 + 0.2 * SmoothBump (0.1, 0.9, 0.05, mod (0.25 * length (ro.xz) / twrScl, 1.));
  } else if (idObj == idStr) {
    col4 = vec4 (0.3, 0.6, 0.2, 0.1);
  } else if (idObj == idRl) {
    col4 = vec4 (0.8, 0.8, 0.9, 0.2);
  } else if (idObj == idStn) {
    col4 = vec4 (0.7, 0.7, 0., 0.2);
  } else if (idObj == idCln) {
    col4 = vec4 (0.9, 0., 0., 0.2);
  }
  return col4;
}
  
vec3 ShowScene (vec3 ro, vec3 rd)
{
  vec4 col4;
  vec3 col, colR, vn, vnw, roo, rdo;
  float dstObj, dstGrnd, dstWat, wAbs;
  bSizeV = 2. * flSpc * twrScl;
  roo = ro;
  rdo = rd;
  dstWat = (rd.y < 0.) ? - ro.y / rd.y : dstFar;
  dstGrnd = GrndRay (ro, rd);
  dstObj = ObjRay (ro, rd);
  wAbs = 1.;
  if (min (dstObj, dstGrnd) < dstFar) {
    if (dstGrnd < dstObj) {
      ro += dstGrnd * rd;
      vn = GrndNf (ro);
      col4 = GrndCol (ro, vn);
      vn = VaryNf (16. * ro / grndScl, vn, 4.);
    } else {
      ro += dstObj * rd;
      vn = ObjNf (ro);
      col4 = ObjCol (ro, vn);
    }
    col = col4.rgb * (0.2 + 0.2 * max (vn.y, 0.) + 0.7 * max (dot (vn, sunDir), 0.)) +
       col4.a * pow (max (0., dot (sunDir, reflect (rd, vn))), 32.);
    if (dstWat < min (dstObj, dstGrnd)) {
      wAbs = smoothstep (0., 0.05, - ro.y / grndScl);
      col = mix (col, mix (vec3 (0.15, 0.17, 0.15), vec3 (0.12, 0.12, 0.15), smoothstep (0.3, 0.7,
         Fbm2 (0.1 * (roo.xz + dstWat * rd.xz)))), wAbs);
    }
  } else col = SkyCol (ro, rd);
  if (dstWat < min (min (dstObj, dstGrnd), dstFar)) {
    ro = roo + dstWat * rd;
    vnw = WaveNf (ro, dstWat);
    rd = reflect (rd, vnw);
    dstObj = ObjRay (ro, rd);
    dstGrnd = GrndRay (ro, rd);
    if (min (dstObj, dstGrnd) < dstFar) {
      if (dstGrnd < dstObj) {
        ro += dstGrnd * rd;
        vn = GrndNf (ro);
        col4 = GrndCol (ro, vn);
        vn = VaryNf (16. * ro / grndScl, vn, 4.);
      } else {
        ro += dstObj * rd;
        vn = ObjNf (ro);
        col4 = ObjCol (ro, vn);
      }
      colR = col4.rgb * (0.2 + 0.2 * max (vn.y, 0.) + 0.7 * max (dot (vn, sunDir), 0.));
    } else colR = SkyCol (ro, rd);
    col = mix (col, 0.95 * colR, min (wAbs, 1. - 0.9 * pow (max (- dot (rdo, vnw), 0.), 2.)));
    vnw = VaryNf (0.1 * vec3 (Rot2D (ro.xz, 0.01 * tCur), ro.y).xzy, vnw, 1.);
    col += 0.1 * pow (max (0., dot (sunDir, reflect (rdo, vnw))), 1024.);
  }
  return clamp (col, 0., 1.);
}

#define AA  0   // optional antialiasing

void mainImage (out vec4 fragColor, in vec2 fragCoord)
{
  mat3 vuMat;
  vec4 mPtr;
  vec3 ro, rd, col;
  vec2 canvas, uv, uvv;
  float el, az, asp, zmFac, sr, t;
  canvas = iResolution.xy;
  uv = 2. * fragCoord.xy / canvas - 1.;
  uv.x *= canvas.x / canvas.y;
  tCur = iTime;
  mPtr = iMouse;
  mPtr.xy = mPtr.xy / canvas - 0.5;
  asp = canvas.x / canvas.y;
  az = 0.;
  el = 0.;
  if (mPtr.z > 0.) {
    az -= 2.5 * pi * mPtr.x;
    el -= 0.5 * pi * mPtr.y;
  } else {
    t = mod (0.005 * tCur, 2.);
    az = 2.5 * pi * (0.5 - abs ((floor (16. * t) + smoothstep (0.8, 1., mod (16. * t, 1.))) / 16. - 1.));
  }
  el = clamp (el, -0.4 * pi, 0.);
  zmFac = 3.5 + 2. * smoothstep (0.1 * pi, 0.4 * pi, - el);
  twrScl = 0.15;
  szFlr = vec4 (14., 8.5, 4., 0.5);
  flSpc = 2. * szFlr.y - szFlr.w;
  nFlr = 3.;
  t = SmoothBump (0.25, 0.75, 0.2, mod (0.03 * tCur, 1.));
  vShift = -4. * nFlr * flSpc * twrScl * t;
  twrRad = 60.;
  vuMat = StdVuMat (el, az);
  grndScl = 50.;
  ro = vuMat * vec3 (0., 0., -1.7) * grndScl;
  ro.y += 0.25 * grndScl;
  dstFar = 10. * grndScl;
  sunDir = normalize (vec3 (1., 2., 1.));
#if ! AA
  const float naa = 1.;
#else
  const float naa = 3.;
#endif  
  col = vec3 (0.);
  sr = 2. * mod (dot (mod (floor (0.5 * (uv + 1.) * canvas), 2.), vec2 (1.)), 2.) - 1.;
  for (float a = float (VAR_ZERO); a < naa; a ++) {
    uvv = (uv + step (1.5, naa) * Rot2D (vec2 (0.5 / canvas.y, 0.), sr * (0.667 * a + 0.5) * pi)) / zmFac;
    rd = vuMat * normalize (vec3 ((2. * tan (0.5 * atan (uvv.x / asp))) * asp, uvv.y, 1.));
    col += (1. / naa) * ShowScene (ro, rd);
  }
  fragColor = vec4 (col, 1.);
}

float PrCapsDf (vec3 p, float r, float h)
{
  return length (p - vec3 (0., 0., clamp (p.z, - h, h))) - r;
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

vec2 Rot2Cs (vec2 q, vec2 cs)
{
  return vec2 (dot (q, vec2 (cs.x, - cs.y)), dot (q.yx, cs));
}

const float cHashM = 43758.54;

vec2 Hashv2v2 (vec2 p)
{
  vec2 cHashVA2 = vec2 (37., 39.);
  return fract (sin (vec2 (dot (p, cHashVA2), dot (p + vec2 (1., 0.), cHashVA2))) * cHashM);
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

vec2 Noisev2v4 (vec4 p)
{
  vec4 ip, fp, t1, t2;
  ip = floor (p);
  fp = fract (p);
  fp = fp * fp * (3. - 2. * fp);
  t1 = Hashv4f (dot (ip.xy, vec2 (1., 57.)));
  t2 = Hashv4f (dot (ip.zw, vec2 (1., 57.)));
  return vec2 (mix (mix (t1.x, t1.y, fp.x), mix (t1.z, t1.w, fp.x), fp.y),
               mix (mix (t2.x, t2.y, fp.z), mix (t2.z, t2.w, fp.z), fp.w));
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
