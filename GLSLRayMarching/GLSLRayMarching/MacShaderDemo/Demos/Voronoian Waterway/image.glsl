// "Voronoian Waterway" by dr2 - 2017
// License: Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License

// Balloon flight in Voronoia.

float PrSphDf (vec3 p, float s);
float PrCylDf (vec3 p, float r, float h);
vec2 Hashv2v2 (vec2 p);
float Noisefv2 (vec2 p);
float Noisefv3 (vec3 p);
float Fbm2 (vec2 p);
vec3 VaryNf (vec3 p, vec3 n, float f);
vec2 Rot2D (vec2 q, float a);
vec3 HsvToRgb (vec3 c);

#define N_BAL 5

mat3 vuMat;
vec3 balPos[N_BAL], qHit, qHitFlm, vuPos, sunDir;
float balRad, flmCylRad, flmCylLen, tCur, dstFar;
int idObj, idGrp;
bool balFlm[N_BAL], balFlmCur;
const float pi = 3.14159;

float VorDist (vec2 p)
{
  vec3 dv;
  vec2 ip, fp, g, b;
  ip = floor (p);
  fp = fract (p);
  dv = vec3 (8.);
  b.x = 0.;
  for (float gy = -1.; gy <= 1.; gy ++) {
    for (float gx = -1.; gx <= 1.; gx ++) {
      g = vec2 (gx, gy);
      dv.z = length (g + 0.9 * Hashv2v2 (ip + g) - fp);
      b.y = step (dv.z, dv.y) * (dv.z - dv.y);
      dv.xy += b + step (dv.z, dv.x) * (dv.zx - dv.xy - b);
    }
  }
  return dv.y - dv.x;
}

float GrndHt (vec2 p)
{
  float s;
  s = Noisefv2 (0.7 * p.yx);
  p += 0.2 * sin (2. * pi * s) +
     0.1 * sin (2. * pi * Noisefv2 (2. * p.xy));
  return 5. * smoothstep (0.05, 0.6 + 0.2 * s, VorDist (0.07 * p));
}

float GrndRay (vec3 ro, vec3 rd)
{
  vec3 p;
  float dHit, h, s, sLo, sHi;
  s = 0.;
  sLo = 0.;
  dHit = dstFar;
  for (int j = 0; j < 200; j ++) {
    p = ro + s * rd;
    h = p.y - GrndHt (p.xz);
    if (h < 0.) break;
    sLo = s;
    s += max (0.2, 0.4 * h);
    if (s > dstFar) break;
  }
  if (h < 0.) {
    sHi = s;
    for (int j = 0; j < 5; j ++) {
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
  float h;
  h = GrndHt (p.xz);
  vec2 e = vec2 (0.01, 0.);
  return normalize (vec3 (h - GrndHt (p.xz + e.xy), e.x,
     h - GrndHt (p.xz + e.yx)));
}

float FlmDf (vec3 p)
{
  vec3 q;
  float d, dMin;
  dMin = dstFar;
  for (int k = 0; k < N_BAL; k ++) {
    if (balFlm[k]) {
      q = p - (balPos[k] - vec3 (0., 0.8 * balRad, 0.));
      d = PrCylDf (q.xzy, flmCylRad + 0.3 * q.y / flmCylLen, flmCylLen);
      d = max (d, - q.y - 0.5 * flmCylLen);
      if (d < dMin) { dMin = d;  qHitFlm = q; }
    }
  }
  return dMin;
}

float FlmRay (vec3 ro, vec3 rd)
{
  float dHit, d;
  dHit = 0.;
  for (int j = 0; j < 100; j ++) {
    d = FlmDf (ro + dHit * rd);
    dHit += d;
    if (d < 0.001 || dHit > dstFar) break;
  }
  if (d >= 0.001) dHit = dstFar;
  return dHit;
}

float BalDf (vec3 p, float dMin)
{
  vec3 q;
  float d;
  q = p;
  d = max (PrSphDf (q, balRad), - PrSphDf (q, 0.98 * balRad));
  q.y -= - balRad;
  d = max (d, - PrCylDf (q.xzy, 0.3 * balRad, 0.1 * balRad));
  if (d < dMin) { dMin = d;  idObj = 1;  qHit = p;}
  q = p;
  q.y -= -1.42 * balRad;
  d = PrCylDf (q.xzy, 0.05 * balRad, 0.13 * balRad);
  q.y -= 0.02 * balRad;
  d = max (d, - PrCylDf (q.xzy, 0.03 * balRad, 0.13 * balRad));
  if (d < dMin) { dMin = d;  idObj = 2;  qHit = p;}
  q = p;
  q.y -= -1.5 * balRad;
  d = PrCylDf (q.xzy, 0.2 * balRad, 0.07 * balRad);
  q.y -= 0.02 * balRad;
  d = max (d, - PrCylDf (q.xzy, 0.18 * balRad, 0.07 * balRad));
  if (d < dMin) { dMin = d;  idObj = 3;  qHit = p;}
  q = p;
  q.xz = abs (q.xz) - 0.25 * balRad;
  q.y -= -1.15 * balRad;
  q.yz = Rot2D (q.yz, -0.35);
  q.xy = Rot2D (q.xy, 0.35);
  d = PrCylDf (q.xzy, 0.005 * balRad, 0.35 * balRad);
  if (d < dMin) { dMin = d;  idObj = 4;  qHit = p;}
  return dMin;
}

float ObjDf (vec3 p)
{
  float dMin, d;
  dMin = dstFar;
  for (int k = 0; k < N_BAL; k ++) {
    d = BalDf (p - balPos[k], dMin);
    if (d < dMin) { dMin = d;  idGrp = k;  balFlmCur = balFlm[k]; }
  }
  return dMin;
}

float ObjRay (vec3 ro, vec3 rd)
{
  float dHit, d;
  dHit = 0.;
  for (int j = 0; j < 100; j ++) {
    d = ObjDf (ro + dHit * rd);
    dHit += d;
    if (d < 0.001 || dHit > dstFar) break;
  }
  return dHit;
}

vec3 ObjNf (vec3 p)
{
  vec4 v;
  vec3 e = vec3 (0.001, -0.001, 0.);
  v = vec4 (ObjDf (p + e.xxx), ObjDf (p + e.xyy),
     ObjDf (p + e.yxy), ObjDf (p + e.yyx));
  return normalize (vec3 (v.x - v.y - v.z - v.w) + 2. * v.yzw);
}

vec3 SkyBg (vec3 rd)
{
  return vec3 (0.2, 0.3, 0.5) + 0.1 * pow (1. - max (rd.y, 0.), 4.);
}

vec3 SkyCol (vec3 ro, vec3 rd)
{
  vec3 col;
  float sd, f;
  ro.x += 0.5 * tCur;
  f = Fbm2 (0.05 * (rd.xz * (100. - ro.y) / rd.y + ro.xz));
  sd = pow (max (dot (rd, sunDir), 0.), 64.);
  col = SkyBg (rd) + (0.35 * sd + 0.65 * min (pow (sd, 4.), 0.3)) *
     vec3 (1., 1., 0.3);
  return mix (col, vec3 (0.85), clamp (f * rd.y + 0.1, 0., 1.));
}

vec3 FlmCol (vec3 p, vec3 rd)
{
  vec3 q, qq;
  float a, f, dr;
  a = 0.;
  p.y -= - flmCylLen;
  dr = 0.05 / flmCylRad;
  for (int j = 0; j < 20; j ++) {
    p += dr * rd;
    q = 15. * p / flmCylLen;
    q.y -= 40. * tCur;
    qq.y = Noisefv3 (q + 0.1 * vec3 (sin (tCur)));
    qq.x = Noisefv3 (q + vec3 (qq.y));
    qq.z = Noisefv3 (q + vec3 (qq.x));
    q = p + 0.25 * (1. - 3. * p.y / flmCylLen) * (qq - 0.5);
    f = 0.45 * q.y - 2.5 * length (q.xz);
    f = clamp (sign (f) * f * f, 0., 1.) * (3. - 0.9 * q.y);
    a += f;
  }
  return clamp (a * vec3 (1., 0.5, 0.3), 0., 1.);
}

vec3 ShowScene (vec3 ro, vec3 rd)
{
  vec3 vn, col, colFlm;
  float dstObj, dstFlm, dstGrnd, f, a;
  bool inSun, inFlm;
  dstGrnd = GrndRay (ro, rd);
  dstFlm = FlmRay (ro, rd);
  dstObj = ObjRay (ro, rd);
  inSun = true;
  inFlm = false;
  if (dstObj < min (dstGrnd, dstFar)) {
    ro += rd * dstObj;
    vn = ObjNf (ro);
    if (idObj == 1) {
      col = HsvToRgb (vec3 (float (idGrp) / float (N_BAL), 0.9, 0.8));
      inFlm = balFlmCur;
      if (length (qHit) < 0.99 * balRad) {
        col *= 0.2;
        if (inFlm) col += 0.1 * vec3 (1., 0.5, 0.);
        inSun = false;
      } else {
        if (length (qHit) > 0.99 * balRad) {
          a = atan (qHit.x, qHit.z) / (2. * pi) + 0.5;
          vn.xz = Rot2D (vn.xz, 0.1 * pi * sin (pi * (0.5 - mod (24. * a, 1.))));
        }
      }
    } else if (idObj == 2) {
       a = atan (qHit.x, qHit.z) / (2. * pi) + 0.5;
       vn.xz = Rot2D (vn.xz, 0.1 * pi * sin (pi * (0.5 - mod (12. * a, 1.))));
      col = vec3 (0.6);
    } else if (idObj == 3) {
      a = atan (qHit.x, qHit.z) / (2. * pi) + 0.5;
      vn.xz = Rot2D (vn.xz, 0.1 * pi * sin (pi * (0.5 - mod (32. * a, 1.))));
      col = vec3 (0.6, 0.3, 0.);
    } else if (idObj == 4) {
      col = vec3 (0.3);
    }
    if (inSun) col = col * (0.2 +
       0.2 * max (dot (vn, - normalize (vec3 (sunDir.x, 0., sunDir.z))), 0.) +
       0.6 * max (dot (vn, sunDir), 0.)) +
       0.1 * pow (max (0., dot (sunDir, reflect (rd, vn))), 64.);
  } else if (dstGrnd < dstFar) {
    ro += dstGrnd * rd;
    if (ro.y > 0.1) {
      vn = VaryNf (1.3 * ro, GrndNf (ro), 5.);
      f = clamp (0.7 * Noisefv2 (ro.xz) - 0.3, 0., 1.);
      col = mix (mix (vec3 (0.4, 0.3, 0.), vec3 (0.5, 0.4, 0.1), f),
         mix (vec3 (0.3, 0.7, 0.3), vec3 (0.5, 0.6, 0.1), f),
         (0.1 + 0.9 * smoothstep (0.1, 0.2, ro.y)) *
         clamp (1.2 * vn.y - 0.2, 0.2, 1.)) *
         (0.3 + 0.7 * max (0., max (dot (vn, sunDir), 0.))) +
         0.1 * pow (max (0., dot (sunDir, reflect (rd, vn))), 64.);
    } else {
      vn = VaryNf (5.1 * ro, vec3 (0., 1., 0.), 0.2);
      rd = reflect (rd, vn);
      col = mix (vec3 (0.15, 0.2, 0.15), vec3 (0.1, 0.1, 0.2), Fbm2 (ro.xz));
      col = mix (col, 0.8 * SkyCol (ro, rd), smoothstep (0.8, 0.95,
          1. - pow (dot (rd, vn), 3.)));
    }
    col = mix (col, SkyBg (rd), max (pow (dstGrnd / dstFar, 4.) - 0.1, 0.));
  } else col = SkyCol (ro, rd);
  if (dstFlm < min (min (dstGrnd, dstObj), dstFar)) {
    colFlm = FlmCol (qHitFlm, rd);
    col = mix (col, colFlm, 0.6 * length (colFlm));
  }
  if (inFlm) col = mix (col, vec3 (1., 0.5, 0.),
     0.3 * pow (clamp (dot (normalize (qHit), - rd), 0., 1.), 4.));
  return pow (clamp (col, 0., 1.), vec3 (0.8));
}

vec3 TrackPath (float t)
{
  return vec3 (30. * sin (0.35 * t) * sin (0.12 * t) * cos (0.1 * t) +
     26. * sin (0.032 * t), 1. + 3. * sin (0.21 * t) * sin (1. + 0.23 * t),
     10. * t);
}

void VuPM (float t)
{
  vec3 fpF, fpB, vel, acc, va, ort, cr, sr;
  float dt;
  dt = 1.;
  vuPos = TrackPath (t);
  fpF = TrackPath (t + dt);
  fpB = TrackPath (t - dt);
  vel = (fpF - fpB) / (2. * dt);
  vel.y = 0.;
  acc = (fpF - 2. * vuPos + fpB) / (dt * dt);
  acc.y = 0.;
  va = cross (acc, vel) / length (vel);
  ort = vec3 (0.2, atan (vel.z, vel.x) - 0.5 * pi, 0.02 * length (va) * sign (va.y));
  cr = cos (ort);
  sr = sin (ort);
  vuMat = mat3 (cr.z, - sr.z, 0., sr.z, cr.z, 0., 0., 0., 1.) *
     mat3 (1., 0., 0., 0., cr.x, - sr.x, 0., sr.x, cr.x) *
     mat3 (cr.y, 0., - sr.y, 0., 1., 0., sr.y, 0., cr.y);
}

void mainImage (out vec4 fragColor, in vec2 fragCoord)
{
  mat3 vuMat2;
  vec4 mPtr;
  vec3 ro, rd;
  vec2 canvas, uv, ori, ca, sa;
  float az, el, s, a;
  canvas = iResolution.xy;
  uv = 2. * fragCoord.xy / canvas - 1.;
  uv.x *= canvas.x / canvas.y;
  tCur = iTime;
  mPtr = iMouse;
  mPtr.xy = mPtr.xy / canvas - 0.5;
  sunDir = normalize (vec3 (1., 0.5, 0.5));
  dstFar = 200.;
  balRad = 2.;
  for (int k = 0; k < N_BAL; k ++) {
    s = float (k - 1) / float (N_BAL);
    balPos[k] = TrackPath (0.5 * tCur + 3. + 7. * s);
    a = 2. * pi * fract (0.037 * tCur + s);
    balPos[k].y = 6.5 * balRad + 2. * balRad * sin (a);
    balFlm[k] = (a > pi);
  }
  el = 0.;
  az = 0.;
  if (mPtr.z > 0.) {
    el = clamp (el - 1.3 * pi * mPtr.y, - 0.49 * pi, 0.49 * pi);
    az = clamp (az - 1.8 * pi * mPtr.x, - pi, pi);
  }
  ori = vec2 (el, az);
  ca = cos (ori);
  sa = sin (ori);
  vuMat2 = mat3 (1., 0., 0., 0., ca.x, - sa.x, 0., sa.x, ca.x) *
     mat3 (ca.y, 0., - sa.y, 0., 1., 0., sa.y, 0., ca.y);
  VuPM (0.5 * tCur);
  ro = vuPos;
  ro.y += 6.5 * balRad + 2. * balRad * sin (2. * pi * fract (0.07 * tCur));
  rd = normalize (vec3 (uv, 2.))* vuMat2 * vuMat;
  flmCylRad = 0.4;
  flmCylLen = 2.;
  fragColor = vec4 (ShowScene (ro, rd), 1.);
}

float PrSphDf (vec3 p, float s)
{
  return length (p) - s;
}

float PrCylDf (vec3 p, float r, float h)
{
  return max (length (p.xy) - r, abs (p.z) - h);
}

vec2 Rot2D (vec2 q, float a)
{
  return q * cos (a) + q.yx * sin (a) * vec2 (-1., 1.);
}

vec3 HsvToRgb (vec3 c)
{
  vec3 p = abs (fract (c.xxx + vec3 (1., 2./3., 1./3.)) * 6. - 3.);
  return c.z * mix (vec3 (1.), clamp (p - 1., 0., 1.), c.y);
}

const vec4 cHashA4 = vec4 (0., 1., 57., 58.);
const vec3 cHashA3 = vec3 (1., 57., 113.);
const float cHashM = 43758.54;

vec4 Hashv4f (float p)
{
  return fract (sin (p + cHashA4) * cHashM);
}

vec2 Hashv2v2 (vec2 p)
{
  const vec2 cHashVA2 = vec2 (37.1, 61.7);
  const vec2 e = vec2 (1., 0.);
  return fract (sin (vec2 (dot (p + e.yy, cHashVA2),
     dot (p + e.xy, cHashVA2))) * cHashM);
}

vec4 Hashv4v3 (vec3 p)
{
  const vec3 cHashVA3 = vec3 (37.1, 61.7, 12.4);
  const vec3 e = vec3 (1., 0., 0.);
  return fract (sin (vec4 (dot (p + e.yyy, cHashVA3), dot (p + e.xyy, cHashVA3),
     dot (p + e.yxy, cHashVA3), dot (p + e.xxy, cHashVA3))) * cHashM);
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
  vec4 t1, t2;
  vec3 ip, fp;
  float q;
  ip = floor (p);
  fp = fract (p);
  fp = fp * fp * (3. - 2. * fp);
  q = dot (ip, cHashA3);
  t1 = Hashv4f (q);
  t2 = Hashv4f (q + cHashA3.z);
  return mix (mix (mix (t1.x, t1.y, fp.x), mix (t1.z, t1.w, fp.x), fp.y),
              mix (mix (t2.x, t2.y, fp.x), mix (t2.z, t2.w, fp.x), fp.y), fp.z);
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

float Fbmn (vec3 p, vec3 n)
{
  vec3 s;
  float a;
  s = vec3 (0.);
  a = 1.;
  for (int i = 0; i < 5; i ++) {
    s += a * vec3 (Noisefv2 (p.yz), Noisefv2 (p.zx), Noisefv2 (p.xy));
    a *= 0.5;
    p *= 2.;
  }
  return dot (s, abs (n)) * (1. / 1.9375);
}

vec3 VaryNf (vec3 p, vec3 n, float f)
{
  vec3 g;
  float s;
  const vec3 e = vec3 (0.1, 0., 0.);
  s = Fbmn (p, n);
  g = vec3 (Fbmn (p + e.xyy, n) - s, Fbmn (p + e.yxy, n) - s,
     Fbmn (p + e.yyx, n) - s);
  return normalize (n + f * (g - n * dot (n, g)));
}
