// "Forkscape" by dr2 - 2021
// License: Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License

#if 0
#define VAR_ZERO min (iFrame, 0)
#else
#define VAR_ZERO 0
#endif

float PrRoundBoxDf (vec3 p, vec3 b, float r);
float PrRoundBox2Df (vec2 p, vec2 b, float r);
float PrCylDf (vec3 p, float r, float h);
float PrCaps2Df (vec2 p, float r, float h);
vec2 PixToHex (vec2 p);
vec2 HexToPix (vec2 h);
float Minv3 (vec3 p);
float SmoothMin (float a, float b, float r);
float SmoothMax (float a, float b, float r);
mat3 StdVuMat (float el, float az);
vec2 Rot2D (vec2 q, float a);
vec4 Hashv4v2 (vec2 p);
float Noisefv2 (vec2 p);
float Fbm2 (vec2 p);
vec3 VaryNf (vec3 p, vec3 n, float f);

struct GrParm {
  float gFac, hFac, fWav, aWav;
};
GrParm gr;

struct Arc {
  vec2 cs;
  float chDist, rad, ang;
};
Arc arcc[3];

struct GrStat {
  vec3 rPos;
  float sAng, fSize;
  Arc arc;
};
GrStat gst;

vec4 dateCur;
vec3 sunDir, qHit;
vec2 gId;
float tCur, dstFar, hgSize;
int idObj;
const float pi = 3.1415927, sqrt3 = 1.732051;

#define DMINQ(id) if (d < dMin) { dMin = d;  idObj = id;  qHit = q; }

float GrndHt (vec2 p)
{ // (from "Desert Reflections 2")
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

float GrndHtN (vec2 p)
{
  return GrndHt (p) + 0.04 * Fbm2 (8. * p.yx);
}

vec3 GrndNf (vec3 p)
{
  vec2 e;
  e = vec2 (0.01, 0.);
  return normalize (vec3 (GrndHtN (p.xz) - vec2 (GrndHtN (p.xz + e.xy),
     GrndHtN (p.xz + e.yx)), e.x)).xzy;
}

void SetGrdConf ()
{
  vec4 h;
  vec2 p;
  int j;
  p = HexToPix (gId * hgSize);
  h = Hashv4v2 (17.1 * gId + 0.3);
  gst.rPos.xz = 0.2 * hgSize * sin (2. * pi * h.x + vec2 (0.5 * pi, 0.));
  gst.rPos.y = GrndHt (HexToPix (gId * hgSize) + gst.rPos.xz);
  gst.sAng = 0.1 * (h.z - 0.5) * tCur;
  j = int (mod (2. * gId + gId.yx, 3.));
  if (j == 0) gst.arc = arcc[0];
  else if (j == 1) gst.arc = arcc[1];
  else gst.arc = arcc[2];
  gst.fSize = 0.8 + 0.2 * h.w;
  if (abs (p.x) < 0.5 * sqrt3 * hgSize || h.y < 0.2) gst.fSize = 0.;
}

#define F(x) (sin (x) / x - b)

float SecSolve (float b)
{  // (from "Bucking Bronco")
  vec3 t;
  vec2 f;
  float x;
  if (b < 0.95) {
    t.yz = vec2 (0.7, 1.2);
    f = vec2 (F(t.y), F(t.z));
    for (int nIt = 0; nIt < 4; nIt ++) {
      t.x = (t.z * f.x - t.y * f.y) / (f.x - f.y);
      t.zy = t.yx;
      f = vec2 (F(t.x), f.x);
    }
    x = t.x;
  } else if (b < 1.) {
    x = sqrt (10. * (1. - sqrt (1. - 1.2 * (1. - b))));
  } else {
    x = 0.;
  }
  return x;
}

void ArcConf ()
{
  float segRot, chLen;
  for (int k = 0; k < 3; k ++) {
    segRot = 0.99 * pi * (0.5 + 0.5 * sin ((1. + 0.1 * float (k)) * 0.5 * tCur));
    chLen = length (vec2 (2. * sin (0.5 * segRot), 1.));
    arcc[k].ang = max (1e-4, SecSolve (chLen / sqrt(5.)));
    arcc[k].chDist = chLen / tan (arcc[k].ang);
    arcc[k].rad = sqrt (arcc[k].chDist * arcc[k].chDist + chLen * chLen);
    arcc[k].cs = sin (- arcc[k].ang + vec2 (0.5 * pi, 0.));
  }
}

float ObjDf (vec3 p)
{
  vec3 q;
  float dMin, d, rr, sk, bLen[2];
  dMin = dstFar;
  if (gst.fSize > 0.) {
    p.xz -= HexToPix (gId * hgSize);
    p -= gst.rPos;
    q = p;
    q.y -= -1.;
    d = PrCylDf (q.xzy, 0.5, 2.);
    DMINQ (1);
    p.y -= 1.;
    dMin /= gst.fSize;
    p /= gst.fSize;
    bLen[0] = 1.;
    bLen[1] = 1.;
    rr = gst.arc.rad * gst.arc.cs.y;
    p.y -= 1.;
    p.xz = Rot2D (p.xz, gst.sAng);
    p.xy = vec2 (- p.y, p.x) - vec2 (1.5 * rr - bLen[1], gst.arc.chDist - gst.arc.rad);
    for (int k = 0; k < 2; k ++) {
      sk = sign (float (k) - 0.5);
      q = p;
      q.y *= - sk;
      q.xy -= vec2 (rr * (sk - 0.5), - gst.arc.chDist);
      d = max (max (PrRoundBox2Df (vec2 (length (q.xy) - gst.arc.rad, abs (q.z) - 0.27),
         vec2 (0., 0.18), 0.07), dot (vec2 (abs (q.x), q.y), gst.arc.cs)), - sk * q.x);
      DMINQ (2);
      q.xy -= vec2 (- bLen[k] * sk, gst.arc.rad);
      d = PrRoundBoxDf (vec3 (q.xy, abs (q.z) - 0.27), vec3 (bLen[k], 0., 0.18), 0.07);
      if (k == 1) d = SmoothMax (SmoothMin (d, PrRoundBoxDf (q - vec3 (-0.1 * bLen[1], 0., 0.),
         vec3 (0.9 * bLen[1], 0.05, 0.5), 0.05), 0.1), - max (PrCaps2Df (vec2 (mod (q.z + 0.15, 0.3) -
         0.15, q.x + 0.5), 0.08, 1.), abs (q.z) - 0.5), 0.03);
      else d = SmoothMin (d, PrRoundBoxDf (q - vec3 (0.1 * bLen[0], 0., 0.),
         vec3 (0.9 * bLen[0], 0.05, 0.6), 0.1), 0.1);
      DMINQ (2);
    }
    dMin *= gst.fSize;
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
  eps = 0.01;
  edN[0] = vec2 (1., 0.);
  edN[1] = 0.5 * vec2 (1., sqrt3);
  edN[2] = 0.5 * vec2 (1., - sqrt3);
  for (int k = 0; k < 3; k ++) edN[k] *= sign (dot (edN[k], rd.xz));
  vri = hgSize / vec3 (dot (rd.xz, edN[0]), dot (rd.xz, edN[1]), dot (rd.xz, edN[2]));
  vf = 0.5 * sqrt3 - vec3 (dot (ro.xz, edN[0]), dot (ro.xz, edN[1]),
     dot (ro.xz, edN[2])) / hgSize;
  pM = HexToPix (PixToHex (ro.xz / hgSize));
  gIdP = vec2 (-999.);
  dHit = eps;
  for (int j = VAR_ZERO; j < 120; j ++) {
    hv = (vf + vec3 (dot (pM, edN[0]), dot (pM, edN[1]), dot (pM, edN[2]))) * vri;
    s = Minv3 (hv);
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

vec3 SkyBg (vec3 rd)
{
  rd.y = abs (rd.y);
  return mix (vec3 (0.2, 0.3, 0.7), vec3 (0.4, 0.4, 0.7), pow (1. - max (rd.y, 0.), 8.));
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

vec3 ShowScene (vec3 ro, vec3 rd)
{
  vec3 col, vn;
  float dstGrnd, dstObj, dFac, dMin, f, sh;
  bool isRef;
  ArcConf ();
  dstObj = ObjRay (ro, rd);
  dstGrnd = GrndRay (ro, rd);
  isRef = false;
  if (dstObj < min (dstGrnd, dstFar) && idObj == 2) {
    isRef = true;
    ro += dstObj * rd;
    gId = PixToHex (ro.xz / hgSize);
    vn = ObjNf (ro);
    rd = reflect (rd, vn);
    ro += 0.01 * rd;
    dstObj = ObjRay (ro, rd);
    dstGrnd = GrndRay (ro, rd);
  }
  dMin = min (dstObj, dstGrnd);
  if (dMin < dstFar) {
    dFac = 1. - smoothstep (0.35, 0.5, dMin / dstFar);
    ro += dMin * rd;
    if (dstObj < dstGrnd) {
      vn = ObjNf (ro);
      if (idObj == 1) {
        vn = VaryNf (8. * qHit, vn, 4. * dFac);
        col = vec3 (0.8);
      } else if (idObj == 2) {
        col = vec3 (0.8, 0.8, 1.);
      }
      col *= 0.7 + 0.3 * dFac;
    } else {
      vn = GrndNf (ro);
      col = 0.9 * mix (vec3 (0.7, 0.9, 0.5), vec3 (0.8, 1., 0.5), smoothstep (3., 4., ro.y)) *
         (1. - 0.3 * dFac * Fbm2 (2. * ro.xz));
      if (dFac > 0.) {
        gId = PixToHex (ro.xz / hgSize);
        SetGrdConf ();
        if (gst.fSize > 0.) col *= 0.8 + 0.2 * smoothstep (0.5, 0.8, length (ro.xz -
           HexToPix (gId * hgSize) - gst.rPos.xz));
      }
    }
    sh = 1. - 0.5 * smoothstep (0.3, 0.7, Fbm2 (0.03 * ro.xz - tCur * vec2 (0.15, 0.)));
    col *= 0.2 + 0.1 * max (0., vn.y) + 0.7 * sh * max (0., dot (vn, sunDir));
    if (isRef) col = vec3 (1., 0.9, 0.8) * mix (col, vec3 (1.), 0.1);
    col = mix (col, SkyBg (rd), pow (dMin / dstFar, 4.));
  } else if (rd.y < 0.) {
    col = SkyBg (rd);
  } else col = SkyCol (ro, rd);
  return clamp (col, 0., 1.);
}

void mainImage (out vec4 fragColor, in vec2 fragCoord)
{
  mat3 vuMat;
  vec4 mPtr, dateCur;
  vec3 ro, rd, col;
  vec2 canvas, uv;
  float el, az, t, hSum;
  canvas = iResolution.xy;
  uv = 2. * fragCoord.xy / canvas - 1.;
  uv.x *= canvas.x / canvas.y;
  tCur = iTime;
  dateCur = iDate;
  mPtr = iMouse;
  mPtr.xy = mPtr.xy / canvas - 0.5;
  tCur = mod (tCur + 10., 2400.) + 30. * floor (dateCur.w / 7200.);
  az = 0.;
  el = -0.01 * pi;
  if (mPtr.z > 0.) {
    az += 2. * pi * mPtr.x;
    el += pi * mPtr.y;
  } else {
    az += 0.2 * pi * sin (0.03 * pi * tCur);
  }
  hgSize = 8.;
  gr.gFac = 0.1;
  gr.hFac = 1.3;
  gr.fWav = 1.9;
  gr.aWav = 0.45;
  dstFar = 150.;
  vuMat = StdVuMat (el, az);
  t = 3. * tCur;
  hSum = 0.;
  for (float k = 0.; k < 5.; k ++) hSum += GrndHt (vec2 (0., t + 0.7 * (k - 1.)));
  ro = vec3 (0.1, 4. * gr.hFac + hSum / 5., t);
  sunDir = normalize (vec3 (-1., 1., -1.));
  rd = vuMat * normalize (vec3 (uv, 3.));
  col = ShowScene (ro, rd);
  fragColor = vec4 (col, 1.);
}

float PrCylDf (vec3 p, float r, float h)
{
  return max (length (p.xy) - r, abs (p.z) - h);
}

float PrRoundBoxDf (vec3 p, vec3 b, float r)
{
  return length (max (abs (p) - b, 0.)) - r;
}

float PrRoundBox2Df (vec2 p, vec2 b, float r)
{
  return length (max (abs (p) - b, 0.)) - r;
}

float PrCaps2Df (vec2 p, float r, float h)
{
  return length (p - vec2 (0., clamp (p.y, - h, h))) - r;
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

float Minv3 (vec3 p)
{
  return min (p.x, min (p.y, p.z));
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

vec4 Hashv4v2 (vec2 p)
{
  vec2 cHashVA2 = vec2 (37., 39);
  return fract (sin (dot (p, cHashVA2) + vec4 (0., cHashVA2.xy, cHashVA2.x + cHashVA2.y)) * cHashM);
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
  vec4 v;
  vec3 g;
  vec2 e = vec2 (0.1, 0.);
  for (int j = VAR_ZERO; j < 4; j ++)
     v[j] = Fbmn (p + ((j < 2) ? ((j == 0) ? e.xyy : e.yxy) : ((j == 2) ? e.yyx : e.yyy)), n);
  g = v.xyz - v.w;
  return normalize (n + f * (g - n * dot (n, g)));
}
