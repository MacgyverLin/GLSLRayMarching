// "Tux Family Trip" by dr2 - 2022
// License: Creative Commons Attribution-NonCommercial-ShareAlike 4.0

/*
  No. 14 in "Penguin" series; others are listed in "Antarctic Flag" (sdlSRl).
*/

#define AA  0   // (= 0/1) optional antialiasing

#if 0
#define VAR_ZERO min (iFrame, 0)
#else
#define VAR_ZERO 0
#endif

float PrSphDf (vec3 p, float r);
float PrCylDf (vec3 p, float r, float h);
float PrCapsDf (vec3 p, float r, float h);
float PrEllipsDf (vec3 p, vec3 r);
float SmoothMin (float a, float b, float r);
float SmoothBump (float lo, float hi, float w, float x);
mat3 StdVuMat (float el, float az);
vec2 Rot2D (vec2 q, float a);
vec2 Rot2Cs (vec2 q, vec2 cs);
float Fbm1 (float p);
float Fbm2 (vec2 p);
vec3 VaryNf (vec3 p, vec3 n, float f);

#define N_WLK 4

struct Leg {
  vec2 cs1, cs2, cs3;
};
struct Walker {
  Leg leg[2];
  vec3 wPos;
  vec2 csHead, csBod;
  float szFac, hHip, lLeg, tPhs;
};
Walker wlk[N_WLK];

vec3 sunDir, qHit, wPos;
float tCur, dstFar, spd, fAng;
int idObj;
const int idLeg = 1, idFoot = 2, idBod = 3, idHead = 4, idBk = 5, idEye = 6, idFlp = 7;
bool isSh;
const float pi = 3.1415927;

#define CosSin(x) (sin ((x) + vec2 (0.5 * pi, 0.)))

#define DMINQ(id) if (d < dMin) { dMin = d;  idObj = id;  qHit = q; }

void SetWlkConf ()
{  // (based on "Walkers")
  float sDir, t, tH, tt, tV, limT, fUp, limEx, a1, a2, fh;
  tH = 0.01;
  tV = 0.3;
  limT = 0.5;
  limEx = 0.95;
  fUp = 1.;
  for (int j = 0; j < N_WLK; j ++) {
    wlk[j].szFac = 1. - 0.4 * float (j) / float (N_WLK);
    wlk[j].lLeg = 0.9;
    wlk[j].hHip = limEx * 4. * wlk[j].lLeg * cos (atan (limT));
    wlk[j].tPhs = mod (tCur * spd / (wlk[j].szFac * wlk[j].hHip * limT * (2./3.)), 4.);
    for (int k = 0; k < 2; k ++) {
      t = mod (wlk[j].tPhs + float (2 * k), 4.);
      if (t > 1.) {
        sDir = -1.;
        t = (t - 1.) / 3.;
      } else sDir = 1.;
      tt = 0.5 - abs (t - 0.5);
      a1 = atan (limT * (((tt < tH) ? tt * tt / tH : 2. * tt - tH) / (1. - tH) - 1.)) *
         sign (0.5 - t) * sDir;
      fh = wlk[j].hHip;
      if (sDir > 0.) fh -= fUp * smoothstep (0., tV, tt);
      a2 = - acos (fh / (4. * wlk[j].lLeg * cos (a1)));
      wlk[j].leg[k].cs1 = CosSin (-0.5 * pi + a1 + a2);
      wlk[j].leg[k].cs2 = CosSin (-2. * a2);
      wlk[j].leg[k].cs3 = CosSin (0.5 * pi - a1 + a2);
    }
    wlk[j].csBod = CosSin (0.05 * pi * sin (0.5 * pi * wlk[j].tPhs + pi));
    wlk[j].csHead = CosSin (0.2 * pi * (2. * SmoothBump (0.25, 0.75, 0.25,
       mod (0.4 * tCur / wlk[j].szFac, 1.)) - 1.));
    wlk[j].wPos = wPos - vec3 (0., 0., 8. * float (j));
  }
}

float PengDf (vec3 p, float dMin, Walker wk)
{  // (based on "Tux the Penguin")
  vec3 pp, q, qq, fSize;
  float d, legRad;
  p.y -= wk.hHip;
  if (! isSh) d = PrSphDf (p, 7.);
  if (isSh || d < dMin) {
    legRad = 0.12;
    pp = p;
    p.xy = Rot2Cs (p.xy, wk.csBod);
    p.y -= 0.9;
    p.xz = - p.xz;
    q = p;
    d = PrEllipsDf (q.xzy, vec3 (2.6, 2.4, 2.8));
    DMINQ (idBod);
    q = p;
    q.xz = Rot2Cs (q.xz, wk.csHead);
    qq = q;
    q.y -= 3.;
    d = PrEllipsDf (q.xzy, vec3 (1.6, 1.2, 2.6));
    q.x = abs (q.x);
    q -= vec3 (0.6, 1., -0.8);
    d = max (d, - PrCylDf (q, 0.3, 0.5));
    DMINQ (idHead);
    q = qq;
    q.x = abs (q.x);
    q -= vec3 (0.6, 4., -0.8);
    d = PrSphDf (q, 0.3);
    DMINQ (idEye);
    q = qq;
    q.yz -= vec2 (3., -1.2);
    d = max (PrEllipsDf (q, vec3 (0.8, 0.4, 1.2)), 0.01 - abs (q.y));
    DMINQ (idBk);
    q = p;
    q.x = abs (q.x);
    q -= vec3 (2.2, 0.6, -0.4);
    q.yz = Rot2D (q.yz, -0.25 * pi);
    q.xy = Rot2D (q.xy, fAng) - vec2 (0.2, -0.8);
    d = PrEllipsDf (q.xzy, vec3 (0.2, 0.5, 1.8));
    DMINQ (idFlp);
    for (int k = 0; k < 2; k ++) {
      p = pp;
      p.x += 1. * sign (float (k) - 0.5);
      p.y -= -0.2;
      q = p.yxz;
      q.xz = Rot2Cs (q.xz, wk.leg[k].cs1);
      q.z -= wk.lLeg;
      d = PrCapsDf (q, legRad, wk.lLeg);
      DMINQ (idLeg);
      q.z -= wk.lLeg;
      q.xz = Rot2Cs (q.xz, wk.leg[k].cs2);
      q.z -= wk.lLeg;
      d = PrCapsDf (q, legRad, wk.lLeg);
      DMINQ (idLeg);
      q.z -= wk.lLeg + 0.1;
      q.xy = q.yx;
      q.yz = Rot2Cs (q.yz, wk.leg[k].cs3);
      q.z = - q.z;
      q.xz = Rot2D (q.xz, 0.05 * pi * sign (float (k) - 0.5)) + vec2 (0., 0.8);
      fSize = vec3 (0.3, 0.13, 1.);
      d = min (PrEllipsDf (vec3 (Rot2D (vec2 (q.x, q.z - 0.8), -0.15 * pi) +
         vec2 (0., 0.8), q.y).xzy, fSize),
         PrEllipsDf (vec3 (Rot2D (vec2 (q.x, q.z - 0.8), 0.15 * pi) +
         vec2 (0., 0.8), q.y).xzy, fSize));
      d = SmoothMin (d, PrEllipsDf (q, fSize), 0.05);
      DMINQ (idFoot);
    }
  } else dMin = min (dMin, d);
  return dMin;
}

float ObjDf (vec3 p)
{
  vec3 q;
  float dMin, d;
  dMin = dstFar;
  for (int j = VAR_ZERO; j < N_WLK; j ++) {
    q = p - wlk[j].wPos;
    d = wlk[j].szFac * PengDf (q / wlk[j].szFac, dMin / wlk[j].szFac, wlk[j]);
    dMin = min (d, dMin);
  }
  return dMin;
}

float ObjRay (vec3 ro, vec3 rd)
{
  float dHit, d;
  dHit = 0.;
  for (int j = VAR_ZERO; j < 120; j ++) {
    d = ObjDf (ro + dHit * rd);
    if (d < 0.001 || dHit > dstFar) break;
    dHit += d;
  }
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
  float sh, d, h;
  sh = 1.;
  d = 0.02;
  for (int j = VAR_ZERO; j < 30; j ++) {
    h = ObjDf (ro + d * rd);
    sh = min (sh, smoothstep (0., 0.05 * d, h));
    d += h;
    if (sh < 0.05 || d > dstFar) break;
  }
  return 0.5 + 0.5 * sh;
}

vec3 SkyBgCol (vec3 ro, vec3 rd)
{
  vec3 col, clCol, skCol;
  vec2 q;
  float f, fd, ff, sd;
  if (rd.y > -0.02 && rd.y < 0.03 * Fbm1 (16. * atan (rd.z, - rd.x))) {
    col = vec3 (0.7, 0.7, 0.75);
  } else {
    q = 0.01 * (ro.xz + 2. * tCur + ((100. - ro.y) / rd.y) * rd.xz);
    ff = Fbm2 (q);
    f = smoothstep (0.2, 0.8, ff);
    fd = smoothstep (0.2, 0.8, Fbm2 (q + 0.01 * sunDir.xz)) - f;
    clCol = (0.7 + 0.5 * ff) * (vec3 (0.7) - 0.7 * vec3 (0.3, 0.3, 0.2) * sign (fd) *
       smoothstep (0., 0.05, abs (fd)));
    sd = max (dot (rd, sunDir), 0.);
    skCol = vec3 (0.3, 0.4, 0.8) + step (0.1, sd) * vec3 (1., 1., 0.9) *
       min (0.3 * pow (sd, 64.) + 0.5 * pow (sd, 2048.), 1.);
    col = mix (skCol, clCol, 0.1 + 0.9 * f * smoothstep (0.01, 0.1, rd.y));
  }
  return col;
}

float GrndHt (vec2 p)
{
  return 0.7 * Fbm2 (0.1 * p.yx);
}

vec3 GrndNf (vec3 p)
{
  vec2 e;
  e = vec2 (0.01, 0.);
  return normalize (vec3 (GrndHt (p.xz) - vec2 (GrndHt (p.xz + e.xy),
     GrndHt (p.xz + e.yx)), e.x)).xzy;
}

vec3 ShowScene (vec3 ro, vec3 rd)
{
  vec4 col4;
  vec3 col, vn;
  float dstObj, dstGrnd, sh, nDotL;
  fAng = -0.2 * pi + 0.15 * pi * SmoothBump (0.25, 0.75, 0.1, mod (0.2 * tCur, 1.)) *
     sin (8. * pi * tCur);
  SetWlkConf ();
  isSh = false;
  dstGrnd = dstFar;
  dstObj = ObjRay (ro, rd);
  if (dstObj < dstFar) {
    ro += dstObj * rd;
    if (idObj == idBod) {
      col4 = (qHit.z > -1.3) ? vec4 (0.15, 0.15, 0.25, 0.1) :
         vec4 (0.95, 0.95, 0.95, 0.05);
    } else if (idObj == idHead) {
      col4 = (qHit.z < 0.5 && length (qHit.xy) < 0.4) ?
         vec4 (0.95, 0.95, 0.95, 0.05) : vec4 (0.15, 0.15, 0.25, 0.1);
    } else if (idObj == idBk) {
      col4 = vec4 (1., 0.8, 0.2, 0.2);
    } else if (idObj == idEye) {
      col4 = vec4 (0., 0., 0., -1.);
    } else if (idObj == idLeg) {
      col4 = vec4 (0.8, 0.8, 0.2, 0.2) * (0.8 + 0.2 * SmoothBump (0.1, 0.9, 0.05,
         fract (8. * qHit.z)));
    } else if (idObj == idFoot) {
      col4 = vec4 (0.8, 0.8, 0.1, 0.2);
    } else if (idObj == idFlp) {
      col4 = vec4 (0.15, 0.15, 0.25, 0.1);
    }
    vn = ObjNf (ro);
    nDotL = max (dot (vn, sunDir), 0.);
    nDotL *= nDotL;
  } else if (rd.y < 0.) {
    dstGrnd = - ro.y / rd.y;
    ro += dstGrnd * rd;
    col4 = mix (vec4 (1., 1., 1., 0.), vec4 (0.95, 0.95, 1., 0.),
       smoothstep (0.45, 0.55, Fbm2 (0.25 * ro.xz)));
    vn = GrndNf (ro);
    nDotL = max (dot (vn, sunDir), 0.);
  } else {
    col = SkyBgCol (ro, rd);
  }
  if (col4.a >= 0.) {
    if (dstObj < dstFar || rd.y < 0.) {
      isSh = true;
      sh = (min (dstObj, dstGrnd) < dstFar) ? ObjSShadow (ro + 0.01 * vn, sunDir) : 1.;
      col = col4.rgb * (0.2 + 0.1 * max (- dot (vn, sunDir), 0.) + 0.8 * sh * nDotL) +
         col4.a * step (0.95, sh) * pow (max (dot (sunDir, reflect (rd, vn)), 0.), 32.);
    }
    if (rd.y < 0. && dstObj >= dstFar) col = mix (col, vec3 (0.7, 0.7, 0.75),
       pow (1. + rd.y, 16.));
  } else {
    col = mix (vec3 (0., 0.3, 0.), SkyBgCol (ro, reflect (rd, vn)), 0.5);
  }
  return clamp (col, 0., 1.);
}

void mainImage (out vec4 fragColor, in vec2 fragCoord)
{
  mat3 vuMat;
  vec4 mPtr;
  vec3 ro, rd, col;
  vec2 canvas, uv;
  float el, az, zmFac, sr;
  canvas = iResolution.xy;
  uv = 2. * fragCoord.xy / canvas - 1.;
  uv.x *= canvas.x / canvas.y;
  tCur = iTime;
  mPtr = iMouse;
  mPtr.xy = mPtr.xy / canvas - 0.5;
  spd = 3.;
  wPos = vec3 (0., 0., spd * tCur);
  az = 0.7 * pi;
  el = -0.05 * pi;
  if (mPtr.z > 0.) {
    az += 2. * pi * mPtr.x;
    el += 0.5 * pi * mPtr.y;
  } else {
    az += 0.03 * pi * tCur;
  }
  el = clamp (el, -0.3 * pi, -0.01 * pi);
  vuMat = StdVuMat (el, az);
  ro = wPos - vec3 (0., 0., 10.) + vuMat * vec3 (0., 3.5, -45.);
  zmFac = 4.;
  dstFar = 150.;
  sunDir = vuMat * normalize (vec3 (0.5, 0.7, -1.));
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

float PrSphDf (vec3 p, float r)
{
  return length (p) - r;
}

float PrCylDf (vec3 p, float r, float h)
{
  return max (length (p.xy) - r, abs (p.z) - h);
}

float PrCapsDf (vec3 p, float r, float h)
{
  return length (p - vec3 (0., 0., clamp (p.z, - h, h))) - r;
}

float PrEllipsDf (vec3 p, vec3 r)
{
  return (length (p / r) - 1.) * min (r.x, min (r.y, r.z));
}

float SmoothMin (float a, float b, float r)
{
  float h;
  h = clamp (0.5 + 0.5 * (b - a) / r, 0., 1.);
  return mix (b - h * r, a, h);
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

vec2 Hashv2f (float p)
{
  return fract (sin (p + vec2 (0., 1.)) * cHashM);
}

vec2 Hashv2v2 (vec2 p)
{
  vec2 cHashVA2 = vec2 (37., 39.);
  return fract (sin (dot (p, cHashVA2) + vec2 (0., cHashVA2.x)) * cHashM);
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

float Fbm1 (float p)
{
  float f, a;
  f = 0.;
  a = 1.;
  for (int j = 0; j < 5; j ++) {
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
  vec2 e;
  e = vec2 (0.1, 0.);
  for (int j = VAR_ZERO; j < 4; j ++)
     v[j] = Fbmn (p + ((j < 2) ? ((j == 0) ? e.xyy : e.yxy) : ((j == 2) ? e.yyx : e.yyy)), n);
  g = v.xyz - v.w;
  return normalize (n + f * (g - n * dot (n, g)));
}
