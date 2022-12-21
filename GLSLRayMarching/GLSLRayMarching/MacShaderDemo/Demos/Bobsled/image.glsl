// "Bobsled" by dr2 - 2015
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
  return dot (s, abs (n));
}

vec3 VaryNf (vec3 p, vec3 n, float f)
{
  vec3 g;
  float s;
  vec3 e = vec3 (0.1, 0., 0.);
  s = Fbmn (p, n);
  g = vec3 (Fbmn (p + e.xyy, n) - s,
     Fbmn (p + e.yxy, n) - s, Fbmn (p + e.yyx, n) - s);
  return normalize (n + f * (g - n * dot (n, g)));
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

float PrCapsDf (vec3 p, float r, float h)
{
  return length (p - vec3 (0., 0., h * clamp (p.z / h, -1., 1.))) - r;
}

float PrTorusDf (vec3 p, float ri, float rc)
{
  return length (vec2 (length (p.xy) - rc, p.z)) - ri;
}

int idObj;
mat3 oMat, objMat[2];
vec3 oPos, objPos[2], qHit, sunDir;
float tCur;
const float dstFar = 200.;

vec3 SkyCol (vec3 ro, vec3 rd)
{
  vec3 col;
  vec2 p;
  float cloudFac, w, f, s;
  if (rd.y > 0.) {
    ro.x += 2. * tCur;
    p = 0.02 * (rd.xz * (100. - ro.y) / rd.y + ro.xz);
    w = 0.8;
    f = 0.;
    for (int j = 0; j < 4; j ++) {
      f += w * Noisefv2 (p);
      w *= 0.5;
      p *= 2.;
    }
    cloudFac = clamp (3. * f * rd.y - 0.1, 0., 1.);
  } else cloudFac = 0.;
  s = max (dot (rd, sunDir), 0.);
  col = vec3 (0.1, 0.2, 0.5) + 0.25 * pow (1. - max (rd.y, 0.), 8.) +
     (0.35 * pow (s, 6.) + 0.65 * min (pow (s, 256.), 0.3));
  return mix (col, vec3 (1.), cloudFac);
}

vec3 TrackPath (float z)
{
  return vec3 (11. * cos (0.045 * z) * cos (0.032 * z) * cos (0.015 * z),
     0.5 * cos (0.017 * z) * cos (0.03 * z), z);
}

float GrndDf (vec3 p)
{
  vec2 q;
  float h, a, w;
  q = 0.05 * p.xz;
  a = 2.;
  h = 0.;
  for (int j = 0; j < 3; j ++) {
    h += a * Noisefv2 (q);
    a *= 1.2;
    q *= 2.;
  }
  w = p.x - TrackPath (p.z).x;
  h = SmoothMin (h, 0.1 * w * w - 0.5, 0.5);
  q = 0.1 * p.xz;
  a = 1.;
  for (int j = 0; j < 5; j ++) {
    h += a * Noisefv2 (q);
    a *= 0.5;
    q *= 2.;
  }
  return p.y - h;
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
    h = GrndDf (p);
    if (h < 0.) break;
    sLo = s;
    s += 0.2 * h + 0.007 * s;
    if (s > dstFar) break;
  }
  if (h < 0.) {
    sHi = s;
    for (int j = 0; j < 6; j ++) {
      s = 0.5 * (sLo + sHi);
      p = ro + s * rd;
      h = step (0., GrndDf (p));
      sLo += h * (s - sLo);
      sHi += (1. - h) * (s - sHi);
    }
    dHit = sHi;
  }
  return dHit;
}

vec3 GrndNf (vec3 p, float d)
{
  vec2 e;
  float h;
  h = GrndDf (p);
  e = vec2 (max (0.01, 0.00001 * d * d), 0.);
  return normalize (vec3 (GrndDf (p + e.xyy) - h, GrndDf (p + e.yxy) - h,
     GrndDf (p + e.yyx) - h));
}

float ObjDf (vec3 p)
{
  vec3 q;
  float d, dMin;
  dMin = dstFar;
  for (int j = 0; j < 2; j ++) {
    q = objMat[j] * (p - objPos[j]);
    d = max (PrCapsDf (q, 1.1, 2.),
       - PrCapsDf (q + vec3 (0., -0.2, 0.), 1., 1.9));
    if (d < dMin) { dMin = d;  idObj = j + 1;  qHit = p; }
  }
  q = p;
  q.x -= TrackPath (p.z).x;
  q.y -= 2.;
  q.z = mod (q.z + 20., 40.) - 20.;
  d = PrTorusDf (q, 0.4, 7.);
  if (d < dMin) { dMin = d;  idObj = 3;  qHit = p; }
  return 0.7 * dMin;
}

float ObjRay (vec3 ro, vec3 rd)
{
  float dHit, d;
  dHit = 0.;
  for (int j = 0; j < 200; j ++) {
    d = ObjDf (ro + dHit * rd);
    dHit += d;
    if (d < 0.001 || dHit > dstFar) break;
  }
  return dHit;
}

vec3 ObjNf (vec3 p)
{
  const vec3 e = vec3 (0.001, -0.001, 0.);
  vec4 v = vec4 (ObjDf (p + e.xxx), ObjDf (p + e.xyy),
     ObjDf (p + e.yxy), ObjDf (p + e.yyx));
  return normalize (vec3 (v.x - v.y - v.z - v.w) + 2. * vec3 (v.y, v.z, v.w));
}

float GrndSShadow (vec3 ro, vec3 rd)
{
  float sh, d, h;
  sh = 1.;
  d = 0.4;
  for (int j = 0; j < 20; j ++) {
    h = GrndDf (ro + rd * d);
    sh = min (sh, 30. * h / d);
    d += 0.4;
    if (h < 0.001) break;
  }
  return max (sh, 0.);
}

float ObjSShadow (vec3 ro, vec3 rd)
{
  float sh, d, h;
  sh = 1.;
  d = 0.05;
  for (int j = 0; j < 80; j ++) {
    h = ObjDf (ro + rd * d);
    sh = min (sh, 30. * h / d);
    d += 0.01 + 0.07 * d;
    if (h < 0.001) break;
  }
  return max (sh, 0.);
}

vec4 ObjCol (vec3 n)
{
  vec4 col4;
  if (idObj == 1) col4 = vec4 (1., 0.3, 0., 0.5);
  else if (idObj == 2) col4 = vec4 (0.3, 0.3, 1., 0.5);
  else if (idObj == 3) col4 = vec4 (0.3, 0.7, 0.4, 0.3);
  return col4;
}

vec3 ShowScene (vec3 ro, vec3 rd)
{
  vec4 col4;
  vec3 col, vn, vns;
  float dstGrnd, dstObj, gg, dx, dk, bk, dif, sh, spec;
  int idObjT;
  dstGrnd = GrndRay (ro, rd);
  idObj = -1;
  dstObj = ObjRay (ro, rd);
  if (idObj < 0) dstObj = dstFar;
  if (dstObj < dstGrnd) {
    ro += dstObj * rd;
    idObjT = idObj;
    vn = ObjNf (ro);
    idObj = idObjT;
    col4 = ObjCol (vn);
    sh = ObjSShadow (ro, sunDir);
    bk = max (dot (vn, - normalize (vec3 (sunDir.x, 0., sunDir.z))), 0.);
    col = col4.rgb * (0.2 + 0.1 * bk  + sh * max (dot (vn, sunDir), 0.)) +
       sh * col4.a * pow (max (0., dot (sunDir, reflect (rd, vn))), 128.);
  } else if (dstGrnd < dstFar) {
    ro += dstGrnd * rd;
    vn = GrndNf (ro, dstGrnd);
    gg = smoothstep (0.5, 0.9, vn.y);
    vn = VaryNf (5. * ro, vn, 0.5);
    vns = normalize (Noisev3v2 (50. * ro.xz) - 0.5);
    vns.y = abs (vns.y);
    spec = 0.8 * gg * pow (max (dot (sunDir, reflect (rd, vns)), 0.), 8.);
    col = vec3 (1.) * mix (1.2, 1., gg);
    dx = abs (ro.x - TrackPath (ro.z).x);
    dk = smoothstep (0., 3., dx);
    col *= 0.7 + 0.3 * (dk + (1. - dk) * Noisefv2 (vec2 (20. * dx, 0.5 * ro.z)));
    dif = max (dot (vn, sunDir), 0.);
    bk = max (0.3 + 0.7 * dot (vn, normalize (vec3 (- sunDir.x, 0.,
       - sunDir.z))), 0.);
    sh = min (GrndSShadow (ro, sunDir), ObjSShadow (ro, sunDir));
    col = col * (0.5 * bk + (0.3 + 0.7 * sh) * dif) + sh * spec * dif;
  } else col = SkyCol (ro, rd);
  return pow (clamp (col, 0., 1.), vec3 (0.7));
}

void ObjPM (float t)
{
  vec3 vuF, vuB, vel, acc, va, ort, cr, sr;
  float dt;
  dt = 1.;
  oPos = TrackPath (t);
  vuF = TrackPath (t + dt);
  vuB = TrackPath (t - dt);
  vel = (vuF - vuB) / (2. * dt);
  vel.y = 0.;
  acc = (vuF - 2. * oPos + vuB) / (dt * dt);
  acc.y = 0.;
  oPos.x -= 50. * acc.x;
  va = cross (acc, vel) / length (vel);
  ort = vec3 (0., atan (vel.z, vel.x) - 0.5 * pi,
     10. * length (va) * sign (va.y));
  cr = cos (ort);
  sr = sin (ort);
  oMat = mat3 (cr.z, - sr.z, 0., sr.z, cr.z, 0., 0., 0., 1.) *
     mat3 (1., 0., 0., 0., cr.x, - sr.x, 0., sr.x, cr.x) *
     mat3 (cr.y, 0., - sr.y, 0., 1., 0., sr.y, 0., cr.y);
}

vec3 GlareCol (vec3 rd, vec3 sd, vec2 uv)
{
  vec3 col;
  if (sd.z > 0.) {
    vec3 e = vec3 (1., 0., 0.);
    col = 0.2 * pow (sd.z, 8.) *
       (1.5 * e.xyy * max (dot (normalize (rd + vec3 (0., 0.3, 0.)), sunDir), 0.) +
        e.xxy * SmoothBump (0.04, 0.07, 0.07, length (uv - sd.xy)) +
        e.xyx * SmoothBump (0.15, 0.2, 0.07, length (uv - 0.5 * sd.xy)) +
        e.yxx * SmoothBump (1., 1.2, 0.07, length (uv + sd.xy)));
  } else col = vec3 (0.);
  return col;
}

void mainImage (out vec4 fragColor, in vec2 fragCoord)
{
  vec2 canvas = iResolution.xy;
  vec2 uv = 2. * fragCoord.xy / canvas - 1.;
  uv.x *= canvas.x / canvas.y;
  tCur = iTime;
  mat3 vuMat;
  vec3 rd, ro, col;
  float objSpd, a;
  a = pi * (0.5 + 0.3 * sin (0.1 * tCur));
  sunDir = normalize (vec3 (cos (a), 0.5, sin (a)));
  objSpd = 20.;
  ObjPM (objSpd * tCur);
  vuMat = oMat;
  rd = normalize (vec3 (uv, 2.6)) * vuMat;
  ro = oPos;
  ro.y += 4.;
  ObjPM (objSpd * (tCur + 1.));
  oPos.y -= GrndDf (oPos) - 1.;
  objPos[0] = oPos;  objMat[0] = oMat;
  ObjPM (objSpd * (tCur + 2.));
  oPos.y -= GrndDf (oPos) - 1.;
  objPos[1] = oPos;  objMat[1] = oMat;
  col = ShowScene (ro, rd) + GlareCol (rd, vuMat * sunDir, 0.5 * uv);
  fragColor = vec4 (col, 1.);
}
