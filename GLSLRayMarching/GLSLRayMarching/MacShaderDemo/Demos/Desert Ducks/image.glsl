// "Desert Ducks" by dr2 - 2020
// License: Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License

#define AA  0  // (= 0/1) optional antialiasing

float PrSphDf (vec3 p, float r);
float PrCylDf (vec3 p, float r, float h);
float PrEllipsDf (vec3 p, vec3 r);
float PrEllCylDf (vec3 p, vec2 r, float h);
float SmoothMin (float a, float b, float r);
float Minv3 (vec3 p);
mat3 StdVuMat (float el, float az);
vec2 Rot2D (vec2 q, float a);
vec2 Rot2Cs (vec2 q, vec2 cs);
vec2 PixToHex (vec2 p);
vec2 HexToPix (vec2 h);
float Hashfv2 (vec2 p);
float Noisefv2 (vec2 p);
float Fbm2 (vec2 p);
vec3 VaryNf (vec3 p, vec3 n, float f);

#define VAR_ZERO min (iFrame, 0)

struct GrParm {
  float gFac, hFac, fWav, aWav;
};
GrParm gr;

vec4 dateCur;
vec3 sunDir, rPos;
vec2 gId;
float tCur, tCurD, dstFar, hgSize, sclFac, sAng;
int idObj;
const int idPil = 1, idBdy = 2, idBk = 3, idEye = 4;
bool isOcc, isSh;
const float pi = 3.14159, sqrt3 = 1.732051;

#define DMIN(id) if (d < dMin) { dMin = d;  idObj = id; }

float GrndHt (vec2 p)
{
  mat2 qRot;
  vec2 q;
  float f, wAmp;
  qRot = mat2 (0.8, -0.6, 0.6, 0.8) * gr.fWav;
  q = gr.gFac * p;
  wAmp = 4. * gr.hFac;
  f = 0.;
  for (int j = 0; j < 4; j ++) {
    f += wAmp * Noisefv2 (q);
    wAmp *= gr.aWav;
    q *= qRot;
  }
  return f;
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
    h = p.y - GrndHt (p.xz);
    if (h < 0.) break;
    sLo = s;
    s += max (0.5, 0.8 * h);
  }
  if (h < 0.) {
    sHi = s;
    for (int j = VAR_ZERO; j < 5; j ++) {
      s = 0.5 * (sLo + sHi);
      p = ro + s * rd;
      if (p.y > GrndHt (p.xz)) sLo = s;
      else sHi = s;
    }
    dHit = 0.5 * (sLo + sHi);
  }
  return dHit;
}

vec3 GrndNf (vec3 p)
{
  vec2 e = vec2 (0.01, 0.);
  return normalize (vec3 (GrndHt (p.xz) - vec2 (GrndHt (p.xz + e.xy),
     GrndHt (p.xz + e.yx)), e.x).xzy);
}

void SetGrdConf ()
{
  float h;
  rPos.xz = 0.5 * hgSize * sin (2. * pi * Hashfv2 (17.1 * gId + 0.3) + vec2 (0.5 * pi, 0.));
  rPos.y = GrndHt (HexToPix (gId * hgSize) + rPos.xz);
  h = Hashfv2 (19.1 * gId + 0.3);
  isOcc = (h > 0.2);
  sclFac = 2.5;
  sAng = 0.15 * (h - 0.6) * tCurD;
}

float DuckDf (vec3 p, float dMin)
{
  vec3 q;
  vec2 cs, r;
  float d, h, s;
  dMin /= sclFac;
  p /= sclFac;
  cs = sin (0.3 + vec2 (0.5 * pi, 0.));
  h = 0.5;
  r = vec2 (0.2, 0.3 + 0.05 * clamp (p.z, -2., 2.));
  s = (length (p.xz / r) - 1.) * min (r.x, r.y);
  d = min (max (s, abs (p.y) - h), length (vec2 (s, p.y)) - h);
  DMIN (idBdy);
  q = p;
  q.x = abs (q.x);
  q -= vec3 (0.5, 0.3, 0.6);
  q.yz = Rot2Cs (q.yz, cs);
  q.xy = Rot2Cs (q.xy, vec2 (cs.x, - cs.y));
  q.xz = Rot2Cs (q.xz, vec2 (cs.x, - cs.y));
  r = vec2 (0.3, 0.5 + 0.08 * clamp (q.z, -2., 2.));
  h = 0.07;
  s = (length (q.yz / r) - 1.) * min (r.x, r.y);
  d = SmoothMin (min (max (s, abs (q.x) - h), length (vec2 (s, q.x)) - h), dMin, 0.05);
  DMIN (idBdy);
  d = SmoothMin (PrEllipsDf (p - vec3 (0., 0.75, -0.4), vec3 (0.4, 0.35, 0.5)), dMin, 0.1);
  DMIN (idBdy);
  q = p - vec3 (0., 0.65, -0.9);
  q.zy = Rot2Cs (q.zy, vec2 (cs.x, - cs.y));
  h = 0.15;
  r = vec2 (0.15, 0.04) * (1. - 0.1 * min (2., max (0., 1. - q.z / h)));
  d = PrEllCylDf (q, r, h);
  q.z -= -0.9 * h;
  d = SmoothMin (max (d, - PrEllCylDf (q, r - 0.02, 0.5 * h)), dMin, 0.01);
  DMIN (idBk);
  q = p;
  q.x = abs (q.x);
  d = PrSphDf (q - vec3 (0.26, 0.825, -0.6), 0.11);
  DMIN (idEye);
  return 0.9 * sclFac * dMin;
}

float ObjDf (vec3 p)
{
  vec3 q;
  float dMin, d;
  dMin = dstFar;
  if (isOcc) {
    p.xz -= HexToPix (gId * hgSize);
    p -= rPos;
    q = p;
    q.y -= -1.5;
    d = PrCylDf (q.xzy, 0.4, 3.);
    DMIN (idPil);
    q.y -= 3.8;
    if (! isSh) d = PrSphDf (q, 3.8);
    if (isSh || d < 0.1) {
      q.xz = Rot2D (q.xz, sAng);
      dMin = DuckDf (q, dMin);
    } else dMin = min (dMin, d);
  }
  return dMin;
}

float ObjRay (vec3 ro, vec3 rd)
{
  vec3 vri, vf, hv, p;
  vec2 edN[3], pM, gIdP;
  float dHit, d, s, eps;
  if (rd.x == 0.) rd.x = 0.0001;
  if (rd.y == 0.) rd.y = 0.0001;
  if (rd.z == 0.) rd.z = 0.0001;
  eps = 0.0005;
  edN[0] = vec2 (1., 0.);
  edN[1] = 0.5 * vec2 (1., sqrt3);
  edN[2] = 0.5 * vec2 (1., - sqrt3);
  for (int k = 0; k < 3; k ++) edN[k] *= sign (dot (edN[k], rd.xz));
  vri = hgSize / vec3 (dot (rd.xz, edN[0]), dot (rd.xz, edN[1]), dot (rd.xz, edN[2]));
  vf = 0.5 * sqrt3 - vec3 (dot (ro.xz, edN[0]), dot (ro.xz, edN[1]), dot (ro.xz, edN[2])) / hgSize;
  pM = HexToPix (PixToHex (ro.xz / hgSize));
  hv = (vf + vec3 (dot (pM, edN[0]), dot (pM, edN[1]), dot (pM, edN[2]))) * vri;
  s = Minv3 (hv);
  gIdP = vec2 (-999.);
  dHit = 0.;
  for (int j = VAR_ZERO; j < 120; j ++) {
    p = ro + dHit * rd;
    gId = PixToHex (p.xz / hgSize);
    if (gId != gIdP) {
      gIdP = gId;
      SetGrdConf ();
    }
    d = ObjDf (p);
    if (dHit + d < s) dHit += d;
    else {
      dHit = s + eps;
      pM += sqrt3 * ((s == hv.x) ? edN[0] : ((s == hv.y) ? edN[1] : edN[2]));
      hv = (vf + vec3 (dot (pM, edN[0]), dot (pM, edN[1]), dot (pM, edN[2]))) * vri;
      s = Minv3 (hv);
    }
    if (d < eps || dHit > dstFar || p.y < 0.) break;
  }
  if (d >= eps) dHit = dstFar;
  return dHit;
}

vec3 ObjNf (vec3 p)
{
  vec4 v;
  vec2 e;
  e = vec2 (0.001, -0.001);
  for (int j = VAR_ZERO; j < 4; j ++) {
    v[j] = ObjDf (p + ((j < 2) ? ((j == 0) ? e.xxx : e.xyy) : ((j == 2) ? e.yxy : e.yyx)));
  }
  v.x = - v.x;
  return normalize (2. * v.yzw - dot (v, vec4 (1.)));
}

float ObjSShadow (vec3 ro, vec3 rd)
{
  vec3 p;
  vec2 gIdP;
  float sh, d, h;
  sh = 1.;
  gIdP = vec2 (-999.);
  d = 0.03;
  for (int j = VAR_ZERO; j < 24; j ++) {
    p = ro + d * rd;
    gId = PixToHex (p.xz / hgSize);
    if (gId != gIdP) {
      gIdP = gId;
      SetGrdConf ();
    }
    h = ObjDf (p);
    sh = min (sh, smoothstep (0., 0.05 * d, h));
    d += h;
    if (h < 0.005) break;
  }
  return 0.6 + 0.4 * sh;
}

float RippleHt (vec2 p)
{
  vec2 q;
  float s1, s2;
  q = Rot2D (p, -0.02 * pi);
  s1 = abs (sin (4. * pi * abs (q.y + 1.5 * Fbm2 (0.7 * q))));
  s1 = (1. - s1) * (s1 + sqrt (1. - s1 * s1));
  q = Rot2D (p, 0.01 * pi);
  s2 = abs (sin (3.1 * pi * abs (q.y + 1.9 * Fbm2 (0.5 * q))));
  s2 = (1. - s2) * (s2 + sqrt (1. - s2 * s2));
  return mix (s1, s2, 0.1 + 0.8 * smoothstep (0.3, 0.7, Fbm2 (2. * p)));
}

vec4 RippleNorm (vec2 p, vec3 vn, float f)
{
  vec2 e;
  float h;
  h = RippleHt (p);
  e = vec2 (0.002, 0.);
  vn.xy = Rot2D (vn.xy, f * (RippleHt (p + e) - h));
  vn.zy = Rot2D (vn.zy, f * (RippleHt (p + e.yx) - h));
  return vec4 (vn, h);
}

vec3 SkyBg (vec3 rd)
{
  return mix (vec3 (0.2, 0.3, 0.7), vec3 (0.45, 0.45, 0.5), pow (1. - max (rd.y, 0.), 8.));
}

vec3 SkyCol (vec3 ro, vec3 rd)
{
  float sd, f;
  ro.x -= tCur;
  sd = max (dot (rd, sunDir), 0.);
  f = Fbm2 (0.05 * (ro + rd * (100. - ro.y) / (rd.y + 0.0001)).xz);
  return mix (SkyBg (rd) + vec3 (1., 1., 0.9) * (0.3 * pow (sd, 32.) + 0.2 * pow (sd, 512.)),
     vec3 (1., 1., 0.95) * (1. - 0.1 * smoothstep (0.8, 0.95, f)), clamp (0.9 * f * rd.y, 0., 1.));
}

vec3 GrndCol (vec3 ro, vec3 rd, float dstGrnd)
{
  vec4 vn4;
  vec3 col, vn;
  float dFac, f, sh;
  dFac = 1. - smoothstep (0.15, 0.35, dstGrnd / dstFar);
  ro += dstGrnd * rd;
  vn = GrndNf (ro);
  col = mix (vec3 (0.65, 0.45, 0.1), vec3 (0.95, 0.7, 0.4), smoothstep (1., 3., ro.y));
  col *= 1. - 0.3 * dFac * Fbm2 (128. * ro.xz);
  if (dFac > 0.) {
    if (vn.y > 0.3) {
      f = smoothstep (0.5, 2., ro.y) * smoothstep (0.3, 0.8, vn.y) * dFac;
      vn4 = RippleNorm (ro.xz, vn, 4. * f);
      vn = vn4.xyz;
      col *= mix (1., 0.95 + 0.05 * smoothstep (0.1, 0.3, vn4.w), f);
    }
    gId = PixToHex (ro.xz / hgSize);
    SetGrdConf ();
    if (isOcc) col *= 0.8 + 0.2 * smoothstep (0.4, 0.7, length (ro.xz -
       HexToPix (gId * hgSize) - rPos.xz));
  }
  isSh = true;
  sh = min (ObjSShadow (ro + 0.01 * vn, sunDir),
     1. - 0.6 * smoothstep (0.4, 0.7, Fbm2 (0.03 * ro.xz - tCur * vec2 (0.15, 0.))));
  col *= (0.2 + 0.1 * vn.y + 0.7 * sh * max (0., dot (vn, sunDir))) * (0.7 + 0.3 * dFac);
  col = mix (col, SkyBg (rd), pow (dstGrnd / dstFar, 4.));
  return col;
}

vec3 ObjCol (vec3 ro, vec3 rd, float dstObj)
{
  vec3 col, vn;
  float dFac;
  dFac = 1. - smoothstep (0.15, 0.35, dstObj / dstFar);
  ro += dstObj * rd;
  vn = ObjNf (ro);
  if (idObj != idEye) {
    if (idObj == idPil) {
      col = vec3 (0.7, 0.5, 0.);
      vn = VaryNf (16. * ro, vn, 2. * dFac);
    } else col = vec3 (0.5, 0.6, 0.9);
    col = col * (0.2 + 0.1 * max (0., - vn.y) + 0.8 * max (0., dot (vn, sunDir))) +
       0.1 * pow (max (0., dot (sunDir, reflect (rd, vn))), 32.);
  } else {
    col = vec3 (0., 0.8, 0.) * max (0.2, - dot (vn, rd));
  }
  col *= 0.7 + 0.3 * dFac;
  col = mix (col, SkyBg (rd), pow (dstObj / dstFar, 4.));
  return col;
}

vec3 ShowScene (vec3 ro, vec3 rd)
{
  vec3 col, vn;
  float dstGrnd, dstObj, dstObjO;
  bool isRef;
  const int maxRef = 3;
  isSh = false;
  isRef = false;
  for (int k = VAR_ZERO; k <= maxRef; k ++) {
    dstObj = ObjRay (ro, rd);
    dstGrnd = GrndRay (ro, rd);
    if (k == 0) dstObjO = dstObj;
    if (k < maxRef && dstObj < min (dstGrnd, dstFar) && (idObj == idBdy || idObj == idBk)) {
      isRef = true;
      ro += dstObj * rd;
      vn = ObjNf (ro);
      rd = reflect (rd, vn);
      ro += 0.01 * rd;
    } else break;
  }
  if (min (dstObj, dstGrnd) < dstFar) {
    col = (dstObj < dstGrnd) ? ObjCol (ro, rd, dstObj) : GrndCol (ro, rd, dstGrnd);
    if (isRef) col = mix (col, SkyBg (rd), pow (dstObjO / dstFar, 8.));
  } else col = SkyCol (ro, rd);
  return clamp (col, 0., 1.);
}

mat3 EvalOri (vec3 v, vec3 a)
{
  vec3 w;
  vec2 cs;
  v = normalize (v);
  cs = sin (clamp (1. * (v.z * a.x - v.x * a.z), -0.1 * pi, 0.1 * pi) + vec2 (0.5 * pi, 0.));
  w = normalize (vec3 (v.z, 0., - v.x));
  return mat3 (w, cross (v, w), v) * mat3 (cs.x, - cs.y, 0., cs.y, cs.x, 0., 0., 0., 1.);
}

vec3 TrackPath (float t)
{
  return vec3 (10. * sin (0.07 * t) * sin (0.022 * t) * cos (0.018 * t) +
     7. * sin (0.0061 * t), 0., t);
}

void mainImage (out vec4 fragColor, in vec2 fragCoord)
{
  mat3 flMat, vuMat;
  vec4 mPtr, dateCur;
  vec3 ro, rd, col, fpF, fpB;
  vec2 canvas, uv;
  float el, az, zmFac, sunEl, sunAz, hSum, sr;
  canvas = iResolution.xy;
  uv = 2. * fragCoord.xy / canvas - 1.;
  uv.x *= canvas.x / canvas.y;
  tCur = iTime;
  dateCur = iDate;
  mPtr = iMouse;
  mPtr.xy = mPtr.xy / canvas - 0.5;
  tCur = mod (tCur + 30., 36000.) + 30. * floor (dateCur.w / 7200.);
  az = 0.;
  el = -0.1 * pi;
  if (mPtr.z > 0.) {
    az += 2. * pi * mPtr.x;
    el += pi * mPtr.y;
  }
  hgSize = 16.;
  gr.gFac = 0.1;
  gr.hFac = 1.3;
  gr.fWav = 1.9;
  gr.aWav = 0.45;
  dstFar = 150.;
  vuMat = StdVuMat (el, az);
  tCurD = 5. * (floor (tCur / 5.) + smoothstep (0.8, 0.999, mod (tCur / 5., 1.)));
  ro = TrackPath (tCurD);
  fpF = TrackPath (tCurD + 1.);
  fpB = TrackPath (tCurD - 1.);
  flMat = EvalOri ((fpF - fpB) / 2., fpF - 2. * ro + fpB);
  hSum = 0.;
  for (float k = 0.; k < 7.; k ++) hSum += GrndHt (TrackPath (tCurD + 0.5 * (k - 1.)).xz);
  ro.y = 8. * gr.hFac + hSum / 7.;
  sunAz = 0.002 * 2. * pi * tCurD;
  sunEl = pi * (0.25 + 0.1 * sin (0.35 * sunAz));
  sunDir = vec3 (cos (sunEl) * sin (sunAz + vec2 (0.5 * pi, 0.)), sin (sunEl)).xzy;
  zmFac = 2.5;
#if ! AA
  const float naa = 1.;
#else
  const float naa = 3.;
#endif  
  col = vec3 (0.);
  sr = 2. * mod (dot (mod (floor (0.5 * (uv + 1.) * canvas), 2.), vec2 (1.)), 2.) - 1.;
  for (float a = float (VAR_ZERO); a < naa; a ++) {
    rd = flMat * (vuMat * normalize (vec3 (uv + step (1.5, naa) * Rot2D (vec2 (0.5 / canvas.y, 0.),
       sr * (0.667 * a + 0.5) * pi), zmFac)));
    col += (1. / naa) * ShowScene (ro, rd);
  }
  fragColor = vec4 (col, 1.);
}

float PrSphDf (vec3 p, float r)
{
  return length (p) - r;
}

float PrCylDf (vec3 p, float r, float h)
{
  return max (length (p.xy) - r, abs (p.z) - h);
}

float PrEllipsDf (vec3 p, vec3 r)
{
  return (length (p / r) - 1.) * min (r.x, min (r.y, r.z));
}

float PrEllCylDf (vec3 p, vec2 r, float h)
{
  return max ((length (p.xy / r) - 1.) * min (r.x, r.y), abs (p.z) - h);
}

float SmoothMin (float a, float b, float r)
{
  float h;
  h = clamp (0.5 + 0.5 * (b - a) / r, 0., 1.);
  return mix (b, a, h) - r * h * (1. - h);
}

float Minv3 (vec3 p)
{
  return min (p.x, min (p.y, p.z));
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
  return fract (sin (vec2 (dot (p, cHashVA2), dot (p + vec2 (1., 0.), cHashVA2))) * cHashM);
}

float Hashfv2 (vec2 p)
{
  return fract (sin (dot (p, vec2 (37., 39.))) * cHashM);
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
