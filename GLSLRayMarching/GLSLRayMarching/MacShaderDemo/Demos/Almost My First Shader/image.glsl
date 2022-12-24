// "Almost My First Shader" by dr2 - 2019
// License: Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License

/*
  We all know that Shadertoy is a great resource for learning shader programming. 
  Before my first contribution nearly five years ago I found many examples by the 
  Shadertoy pioneers that were helpful in learning what could be done and how to 
  do it. The second of the two shaders below is one of my initial attempts, but
  because much of it is a cut-and-paste job based on their work I never bothered
  to publish it. Since the visuals are not bad (ignoring artifacts) I have now
  rewritten it in the usual style, and this is the first of the shaders here.
*/

#if 1   // shader version (1/0)

// The new version

vec2 Rot2D (vec2 q, float a);
float SmoothMin (float a, float b, float r);
float Noisefv2 (vec2 p);
float Fbm2 (vec2 p);

mat3 carMat;
vec3 carPos, sunDir;
float dstFar, szFac, carRoll, fanAng;
int idObj;
bool isRefl;
const int idRd = 1, idGrnd = 2, idTun = 3, idCar = 4;
const float pi = 3.14159;

vec3 TrackPath (float t)
{
  return vec3 (1.5 * cos (cos (0.2 * t) + 0.16 * t) * cos (0.1 * t),
     2. * sin (0.11 * t) + 0.8 * cos (cos (0.07 * t) + 0.11 * t) * cos (0.03 * t), t);
}

float CarDf (vec3 p)
{
  float d;
  p = carMat * (p - carPos) / szFac;
  p.y -= -26.;
  p.xy = Rot2D (p.xy, carRoll);
  d = max (length (max (vec3 (abs (p.x) - 3.5,
     length (vec2 (p.y + 12., p.z)) - 20., - (p.y - 1.6)), 0.)) - 0.5, p.z - 12.);
  p.yz -= vec2 (2.2, -3.9);
  p.xz = abs (p.xz) - vec2 (7.2, 10.6);
  d = min (SmoothMin (d, length (vec2 (max (abs (p.z) - 2.4, 0.), length (p.xy) - 2.8)) - 0.2, 3.),
     (length (vec3 (p.xy, 0.35 * p.z)) - 0.8));
  return d * szFac;
}

#define DMIN(id) if (d < dMin) { dMin = d;  idObj = id; }

float ObjDf (vec3 p)
{
  vec3 q, r;
  float dMin, d;
  dMin = dstFar;
  q = p;
  q.xy -= TrackPath (q.z).xy;
  d = max (q.y + 1., abs (q.x) - 0.75);
  DMIN (idRd);
  d = mix (q.y + 1.1, q.y - 36. * Fbm2 (0.03 * q.xz) + 12., smoothstep (3., 30., abs (q.x)));
  DMIN (idGrnd);
  r = q;
  r.z = mod (r.z + 25., 50.) - 25.;
  d = max (abs (r.y - 1. + 0.4 * r.x * r.x) - 0.1, abs (r.z) - 10.);
  r.y += 0.7;
  r.z = mod (r.z, 2.5) - 1.25;
  d = max (d, 0.6 - length (r.yz));
  DMIN (idTun);
  if (! isRefl) {
    d = CarDf (p);
    DMIN (idCar);
  }
  return 0.7 * dMin;
}

float ObjRay (vec3 ro, vec3 rd)
{
  float dHit, d;
  dHit = 0.;
  for (int j = 0; j < 350; j ++) {
    d = ObjDf (ro + dHit * rd);
    if (d < 0.0002 || dHit > dstFar) break;
    dHit += d;
  }
  return dHit;
}

vec3 ObjNf (vec3 p)
{
  vec4 v;
  vec2 e = vec2 (0.001, -0.001);
  v = vec4 (- ObjDf (p + e.xxx), ObjDf (p + e.xyy), ObjDf (p + e.yxy), ObjDf (p + e.yyx));
  return normalize (2. * v.yzw - dot (v, vec4 (1.)));
}

float ObjSShadow (vec3 ro, vec3 rd)
{
  float sh, d, h;
  sh = 1.;
  d = 0.1;
  for (int j = 0; j < 40; j ++) {
    h = ObjDf (ro + d * rd);
    sh = min (sh, smoothstep (0., 0.05 * d, h));
    d += h;
    if (sh < 0.05) break;
  }
  return 0.5 + 0.5 * sh;
}

float FanDf (vec3 p)
{
  float d;
  p = carMat * (p - carPos) / szFac;
  p.y -= -26.;
  p.xy = Rot2D (p.xy, carRoll);
  p.yz -= vec2 (2.2, -3.9);
  p.xz = abs (p.xz) - vec2 (7.2, 10.6);
  p.xy = Rot2D (p.xy, fanAng);
  d = max (max (min (abs (p.x), abs (p.y)) * 0.15 - 0.05,
     abs (p.z) - 2.), length (p.xy) - 2.8);
  return d * szFac;
}

float FanRay (vec3 ro, vec3 rd)
{
  float dHit, d;
  dHit = 0.;
  for (int j = 0; j < 60; j ++) {
    d = FanDf (ro + dHit * rd);
    if (d < 0.0005 || dHit > dstFar) break;
    dHit += d;
  }
  return dHit;
}

vec3 ObjCol (vec3 p, vec3 rd, vec3 vn)
{
  vec3 q, col, m;
  float c, f, sh, spec;
  q = p - vec3 (TrackPath (p.z).xy, 0.);
  spec = 0.;
  if (idObj == idRd) {
    c = max (0., 1. - 5. * abs (0.4 - abs (q.x))) * step (0.5, cos (32. * pi * q.z / 50.));
    col = vec3 (0.5) + 2. * pow (c, 8.) * vec3 (1., 0.8, 0.);
  } else if (idObj == idGrnd) {
    f = 0.55 * (clamp (Noisefv2 (p.xz * 0.1), 0., 1.) +
       Noisefv2 (p.xz * 0.2 + vn.yz * 1.08) * 0.85);
    m = mix (vec3 (0.63 * f + 0.2, 0.7 * f + 0.1, 0.7 * f + 0.1),
       vec3 (f * 0.43 + 0.1, f * 0.3 + 0.2, f * 0.35 + 0.1), f * 0.65);
    col = m * (f * m + vec3 (0.36, 0.30, 0.28));
    if (vn.y < 0.5) {
      c = (0.5 - vn.y) * 4.;
      c = clamp (c * c, 0.1, 1.);
      f = Noisefv2 (vec2 (p.x * 0.2, p.z * 0.2 + p.y * 0.3)) +
         Noisefv2 (vec2 (p.x * 4.5, p.z * 4.5)) * 0.5;
      col = mix (col, vec3 (0.4 * f), c);
    }
    if (p.y < 5. && vn.y > 0.65) {
      m = vec3 (Noisefv2 (p.xz * 7.) * 0.4 + 0.1, Noisefv2 (p.xz * 11.) * 0.6 + 0.3, 0.);
      m *= (vn.y - 0.55) * 0.85;
      col = mix (col, m, clamp ((vn.y - 0.65) * (5. - p.y) * 0.13, 0., 1.));
    }
    if (p.y > 5. && vn.y > 0.2) {
      col = mix (col, 1.3 * vec3 (0.95, 0.95, 1.),
         clamp ((p.y - 5. - Noisefv2 (p.xz * 1.2)) * 0.2, 0., 1.));
      spec = 0.1;
    }
  } else if (idObj == idTun) {
    col = vec3 (0.8, 0., 0.);
    if (abs (q.x) < 0.6 && vn.y < 0.) col += pow (max (0., 1.5 - 2.5 * abs (q.x)) *
       step (0., cos (64. * pi * q.z / 50.)), 8.) * vec3 (0.8, 0.4, 0.7);
  } else if (idObj == idCar) {
    q = carMat * (p - carPos) / szFac;
    q.y -= -26.;
    q.xy = Rot2D (q.xy, carRoll);
    q.xz = abs (q.xz);
    col = ((abs (q.y - 6.5) < 1. - q.z * 0.1 && q.z < 3.5 ||
       length (max (abs (vec2 (q.x - q.z * 0.03, q.z - 5.)) -
       vec2 (1.5 + q.z * 0.03, 4.), 0.)) < 1.) ? 0.4 : 1.) * vec3 (0.2, 0.6, 1.);
    spec = 0.5;
  }
  sh = ObjSShadow (p, sunDir);
  return col * (0.2 + sh * 0.8 * max (0., dot (sunDir, vn))) +
     spec * step (0.95, sh) * pow (max (0., dot (rd, reflect (sunDir, vn))), 32.);
}

vec3 SkyCol (vec3 rd)
{
  float sd;
  rd.y = abs (rd.y);
  sd = max (0., dot (rd, sunDir));
  return mix (vec3 (0.3, 0.35, 0.7), vec3 (0.8, 0.8, 0.8),
     clamp (2. * (Fbm2 (2. * rd.xz / rd.y) - 0.1) * rd.y, 0., 1.)) + (pow (sd, 64.) * 0.15 +
     pow (sd, 256.) * 0.15) * vec3 (1., 0.8, 0.5);
}

vec3 ShowScene (vec3 ro, vec3 rd)
{
  vec3 col, colR, vn;
  float dstObj, dstFan, dstObjT;
  int idObjT;
  dstFan = FanRay (ro, rd);
  isRefl = false;
  dstObj = ObjRay (ro, rd);
  if (dstObj < dstFar) {
    ro += dstObj * rd;
    vn = ObjNf (ro);
    idObjT = idObj;
    dstObjT = dstObj;
    col = ObjCol (ro, rd, vn);
  } else {
    col = SkyCol (rd);
  }
  if (dstObj < dstFar && idObjT == 4) {
    rd = reflect (rd, vn);
    ro += 0.01 * rd;
    isRefl = true;
    dstObj = ObjRay (ro, rd);
    if (dstObj < dstFar) {
      ro += dstObj * rd;
      vn = ObjNf (ro);
      colR = ObjCol (ro, rd, vn);
    } else {
      colR = SkyCol (rd);
    }
    col = mix (col, colR, 0.2);
  }
  if (dstFan < min (dstObjT, dstFar)) col += mix (col, vec3 (1., 0.5, 0.2), 0.5);
  return pow (clamp (col, 0., 1.), vec3 (0.8));
}

#define AA  0

void mainImage (out vec4 fragColor, in vec2 fragCoord)
{
  mat3 vuMat;
  vec3 ro, rd, vd, col, dir, u;
  vec2 canvas, uv;
  float tCur, spd, sr;
  canvas = iResolution.xy;
  uv = 2. * fragCoord.xy / canvas - 1.;
  uv.x *= canvas.x / canvas.y;
  tCur = iTime;
  szFac = 0.025;
  spd = 8.;
  fanAng = mod (20. * tCur, 2. * pi);
  carPos = TrackPath (spd * tCur);
  dir = normalize ((TrackPath (spd * tCur + 1.) - carPos));
  u = normalize (vec3 (dir.z, 0., - dir.x));
  carMat = mat3 (u, cross (u, - dir), - dir);
  carRoll = dir.x * 0.8;
  carPos.xy -= vec2 (dir.x, 0.2);
  ro = TrackPath (spd * tCur - 1.7) - vec3 (1.5 * dir.x, 0.5, 0.);
  vd = normalize (carPos - ro);
  vuMat = mat3 (vec3 (vd.z, 0., - vd.x) / sqrt (1. - vd.y * vd.y),
     vec3 (- vd.y * vd.x, 1. - vd.y * vd.y, - vd.y * vd.z) / sqrt (1. - vd.y * vd.y), vd);
  dstFar = 200.;
  sunDir = normalize (vec3 (1., 1., 1.));
#if ! AA
  const float naa = 1.;
#else
  const float naa = 3.;
#endif  
  col = vec3 (0.);
  sr = 2. * mod (dot (mod (floor (0.5 * (uv + 1.) * canvas), 2.), vec2 (1.)), 2.) - 1.;
  for (float a = 0.; a < naa; a ++) {
    rd = vuMat * normalize (vec3 (uv + step (1.5, naa) * Rot2D (vec2 (0.5 / canvas.y, 0.),
       sr * (0.667 * a + 0.5) * pi), 1.5));
    col += (1. / naa) * ShowScene (ro, rd);
  }
  fragColor = vec4 (col, 1.);
}

vec2 Rot2D (vec2 q, float a)
{
  vec2 cs;
  cs = sin (a + vec2 (0.5 * pi, 0.));
  return vec2 (dot (q, vec2 (cs.x, - cs.y)), dot (q.yx, cs));
}

float SmoothMin (float a, float b, float r)
{
  float h;
  h = clamp (0.5 + 0.5 * (b - a) / r, 0., 1.);
  return mix (b, a, h) - r * h * (1. - h);
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

#else

// The ancient version

const float pi = 3.14159;

vec4 Hashv4f (float p) {
  return fract (sin (vec4 (p + 0., p + 1., p + 57., p + 58.)) * 43758.5453);
}

float Noisefv2 (vec2 s) {
  vec2 p = floor (s);
  vec2 f = fract (s);
  f = f * f * (3. - 2. * f);
  vec4 t = Hashv4f (p.x + 57. * p.y);
  return mix (mix (t.x, t.y, f.x), mix (t.z, t.w, f.x), f.y);
}

float Fbm2 (vec2 p) {
  const mat2 mr = mat2 (0.6, -0.8, 0.8, 0.6);
  float f = 0.;
  float a = 1.;
  float am = 0.5;
  float ap = 2.;
  for (int i = 0; i < 5; i ++) {
    f += a * Noisefv2 (p);
    p *= mr * ap;
    a *= am;
  }
  return f;
}

vec3 colSky (vec3 rd) {
  vec3 col;
  if (rd.y < 0.) rd.y *= -1.;
  vec2 xy = 1. * rd.xz / rd.y;
  float w = 0.65;
  float f = 0.;
  for (int i = 0; i < 4; i ++) {
    f += Noisefv2 (xy) * w;
    w *= 0.5;
    xy *= 2.3;
  }
  col = mix (vec3 (0.3, 0.35, 0.7), vec3 (0.8, 0.8, 0.8),
     clamp (2. * (f - 0.2) * rd.y, 0., 1.));
  return col;
}

vec3 carPos;
mat3 carMat;
mat2 carRoll;
float fanDist;
int isRefl;
bool carOnly = false;
bool needFan;
vec3 lightDir;
mat2 spinMat;

float SmoothMin (float a, float b, float k)
{
  float h = clamp (.5 + .5 * (b - a) / k, 0., 1.);
  return mix (b, a, h) - k * h * (1. - h);
}

vec3 path (float t)
{
  t *= 0.6;
  float x = cos (cos (t * 0.36) + t * 0.28) * cos (t * 0.13) * 1.5;
  float y = sin (t * 0.17) * 2. + cos (cos (t * 0.12) + t * 0.19) *
     cos (t * 0.051) * 0.8;
  return vec3 (x, y, t / 0.6);
}

float DfTunnel (vec3 p)
{
  p.z = mod (p.z, 50.) - 25.;
  float d = max (abs (p.y - 1. + 0.4 * p.x * p.x) - 0.1, abs (p.z) - 10.);
  p.z = mod (p.z, 2.5) - 1.25;
  p.y += 0.7;
  d = max (d, - (length (p.yz) - 0.6));
  return d;
}

float DfCar (vec3 p)
{
  p *= 40.;
  float d = max (length (max (vec3 (abs (p.x) - 3.5,
     length (vec2 (p.y + 12., p.z)) - 20., - (p.y - 1.6)), 0.)) - 0.5, p.z - 12.);
  vec3 q = p + vec3 (0., -2.2, 3.9);
  q.xz = abs (q.xz) - vec2 (7.2, 10.6);
  d = SmoothMin (d,
     length (vec2 (max (abs (q.z) - 2.4, 0.), length (q.xy) - 2.8)) - 0.2, 3.);
  d = min (d, (length (vec3 (q.xy, 0.35 * q.z)) - 0.8));
  return d / 40.;
}

float DfFan (vec3 p)
{
  p *= 40.;
  vec3 q = p + vec3 (0., -2.2, 3.9);
  q.xz = abs (q.xz) - vec2 (7.2, 10.6);
  q.xy *= spinMat;
  float df = max (max (min (abs (q.x), abs (q.y)) * 0.15 - 0.05,
     abs (q.z) - 2.), length (q.xy) - 2.8);
  df = min (df, (length (q) - 0.5) * 0.07);
  return min (fanDist, df / 40.);
}

float colCar (vec3 p)
{
  p *= 40.;
  p.xz = abs (p.xz);
  return (abs (p.y - 6.5) < 1. - p.z * 0.1 && p.z < 3.5 ||
     length (max (abs (vec2 (p.x - p.z * 0.03, p.z - 5.)) -
     vec2 (1.5 + p.z * 0.03, 4.), 0.)) < 1.) ? 0.4 : 1.;
}

int hitObj, hitObjP;

float de (vec3 p)
{
  float d, dd;
  float gd = p.y + 12. - 20. * Fbm2 (0.04 * p.xz);
  hitObj = 0;
  vec3 q = p;
  if (! carOnly) q.xy -= path (q.z).xy;
  d = q.y + 1.;
  if (! carOnly) {
    d = max (d, abs (q.x) - 0.75);
    hitObj = 1;
    float b = smoothstep (3., 25., abs (q.x));
    dd = (q.y + 1.1) * (1. - b) + gd * b;
    if (dd < d) {
      d = dd;
      hitObj = 2;
    }
    dd = DfTunnel (q);
    if (dd < d) {
      d = dd;
      hitObj = 3;
    }
  }
  if (isRefl == 0) {
    q = p;
    if (! carOnly) {
      q -= carPos;
      q = carMat * q;
      q.y += 0.7;
      q.xy *= carRoll;
    }
    dd = DfCar (q);
    if (needFan) fanDist = DfFan (q);
    if (dd < 0.001) hitObj = 4;
    d = min (d, dd);
  }
  return d;
}

vec3 evalNorm (vec3 p)
{
  const vec3 e = 0.001 * vec3 (1., -1., 0.);
  float v0 = de (p + e.xxx);
  float v1 = de (p + e.xyy);
  float v2 = de (p + e.yyx);
  float v3 = de (p + e.yxy);
  return normalize (vec3 (v0) + vec3 (v1 - v3 - v2, v3 - v1 - v2, v2 - v3 - v1));
}

float shadow (vec3 pos, vec3 sdir)
{
  float sh = 1.0;
  float totdist = 0.004 * 10.;
  float d;
  for (int steps = 0; steps < 40; steps++) {
    vec3 p = pos + totdist * sdir;
    d = de (p);
    sh = min (sh, 10. * max (0.0, d) / totdist);
    sh *= sign (max (0., d - 0.004));
    totdist += max (0.02, d);
    if (totdist > 35. || d < 0.004) break;
  }
  return clamp (sh, 0., 1.0);
}

#define AMBIENT_COLOR vec3(.7,.85,1.)

vec3 shade (vec3 p, vec3 dir, vec3 n)
{
  vec3 col = vec3 (0.);
  if (hitObjP == 1) col = vec3 (0.5, 0.5, 0.5);
  else if (hitObjP == 2) {
    float f = 0.55 * (clamp (Noisefv2 (p.xz * 0.1), 0., 1.) +
        Noisefv2 (p.xz * 0.2 + n.yz * 1.08) * 0.85);
    vec3 m = mix (vec3 (0.63 * f + 0.2, 0.7 * f + 0.1, 0.7 * f + 0.1),
	    vec3 (f * 0.43 + 0.1, f * 0.3 + 0.2, f * 0.35 + 0.1), f * 0.65);
    col = m * (f * m + vec3 (0.36, 0.30, 0.28));
    if (n.y < 0.5) {
      float c = (0.5 - n.y) * 4.;
      c = clamp (c * c, 0.1, 1.);
      f = Noisefv2 (vec2 (p.x * 0.2, p.z * 0.2 + p.y * 0.3)) +
          Noisefv2 (vec2 (p.x * 4.5, p.z * 4.5)) * 0.5;
      col = mix (col, vec3 (0.4 * f), c);
    }
    if (p.y < 5. && n.y > 0.65) {
      m = vec3 (Noisefv2 (p.xz * 7.) * 0.4 + 0.1,
		Noisefv2 (p.xz * 11.) * 0.6 + 0.3, 0.);
      m *= (n.y - 0.55) * 0.85;
      col = mix (col, m, clamp ((n.y - 0.65) * 1.3 * (5. - p.y) * 0.1, 0., 1.));
    }
    if (p.y > 5. && n.y > 0.2) {
      float snow = clamp ((p.y - 5. - Noisefv2 (p.xz * 1.2) * 1.) * 0.2, 0., 1.);
      col = mix (col, vec3 (0.7, 0.7, 0.8), snow);
    }
  }
  else if (hitObjP == 3) col = vec3 (0.8, 0., 0.);
  vec3 q = p;
  if (! carOnly) q -= vec3 (path (p.z).xy, 0.);
  if (hitObjP == 1) {
    float c = max (0., 0.2 - abs (0.4 - abs (q.x))) * 5. * abs (sin (q.z * 1.));
    c *= c;
    c *= c;
    col += c * c * vec3(1.,.6,.25) * 2.4;
  }
  if (hitObjP == 3) {
    if (abs (q.x) < 0.6 && n.y < 0.) {
      float c = max (0., 0.3 - 0.5 * abs (q.x)) * 5. * abs (sin (q.z * 2.));
      c *= c;
      c *= c;
      col += c * c * vec3(.8,.4,.7);
    }
  }
  q = p;
  if (! carOnly) {
    q -= carPos;
    q = carMat * q;
    q.y += 0.7;
    q.xy *= carRoll;
  }
  if (DfCar (q) < 0.001) {
    col = colCar (q) * vec3 (1., 0.6, 0.3);
  }
  float diff, spec;
  float sh = shadow (p, lightDir);
  diff = max (0., dot (lightDir, n)) * 1.3;
  float amb = (0.4 + 0.6 * max (0., dot (dir, - n))) * 0.6;
  spec = pow (max (0., dot (dir, reflect (lightDir, n))), 20.) * 0.4;
  return col * (amb * AMBIENT_COLOR + sh * (diff + spec) * vec3(1.,.85,.6));
}

void mainImage (out vec4 fragColor, in vec2 fragCoord)
{
  vec4 mPtr;
  vec2 canvas, uv;
  float tCur;
  canvas = iResolution.xy;
  uv = 2. * fragCoord.xy / canvas - 1.;
  uv.x *= canvas.x / canvas.y;
  tCur = iTime;
  mPtr = iMouse;
  mPtr.xy = mPtr.xy / canvas - 0.5;
  bool riding = true;
  if (carOnly) riding = false;
  lightDir = normalize (vec3 (-0.7, 0.7, 0.7));
  fanDist = 250.;
  float t = mod (tCur, 500.) * 8.;
  spinMat = mat2 (cos (t * 2.), - sin (t * 2.), sin (t * 2.), cos (t * 2.));
  vec3 ro, rd, col;
  if (riding) {
    vec3 trkCar, dirCar, fwc, rtc;
    trkCar = path (t);
    dirCar = normalize ((path (t + 1.) - trkCar));
    fwc = normalize (- dirCar);
    rtc = normalize (cross (fwc, vec3 (0., 1., 0.)));
    carMat = mat3 (rtc, cross (rtc, fwc), fwc);
    float a = - dirCar.x * 0.8;
    carRoll = mat2 (cos (a), sin (a), -sin (a), cos (a));
    carPos = vec3 (trkCar.xy - vec2 (dirCar.x, 0.2), t);
    ro = path (t - 0.6) + vec3 (- dirCar.x * 2., -0.5, -0.6);
    vec3 fw = normalize (carPos - ro);
    vec3 rt = normalize (cross (fw, vec3 (0., 1., 0.)));
    rd = mat3 (rt, cross (rt, fw), fw) * normalize (vec3 (uv, 1.2));
  } else {
    float az, el;
    el = 0.4;
    az = 1.;
    if (mPtr.z > 0.) {
      el -= 0.3 * pi * mPtr.y;
      az += 2. * pi * mPtr.x;
    }
    float cEl = cos (el);
    float sEl = sin (el);
    float cAz = cos (az);
    float sAz = sin (az);
    rd = normalize (vec3 (uv, 6.));
    rd = vec3 (rd.x, rd.y * cEl - rd.z * sEl, rd.z * cEl + rd.y * sEl);
    rd = vec3 (rd.x * cAz + rd.z * sAz, rd.y, rd.z * cAz - rd.x * sAz); 
    ro = - 4. * vec3 (cEl * sAz, - sEl, cEl * cAz);
  }
  float d;
  vec3 carHitPt;
  vec3 carHitN;
  vec3 rdo = rd;
  isRefl = 0;
  float dist = 0.;
  for (int i = 0; i < 200; i ++) {
    needFan = true;
    d = de (ro + dist * rd);
    needFan = false;
    dist += d;
    if (d < 0.001) {
      if (hitObj == 4 && isRefl == 0) {
        ro += dist * rd;
        carHitN = evalNorm (ro);
        carHitPt = ro;
        rd = reflect (rd, carHitN);
        dist = 0.01;
        isRefl = 1;
      } else break;
    } else {
      if (dist > 100.) break;
    }
  }
  hitObjP = hitObj;
  if (d < 0.5) {
    ro += dist * rd;
    col = shade (ro, rd, evalNorm (ro));
  } else {
    float ldDot = max (0., dot (normalize (rd), lightDir));
    col = colSky (rd) +
      (pow (ldDot, 50.) * 0.15 + pow (ldDot, 200.) * 0.15) * vec3(1.,.8,.5);
  }
  if (isRefl == 1) col = shade (carHitPt, rdo, carHitN) + col * 0.3;
  fanDist *= 100.;
  if (fanDist < 0.4) {
    float mFan = 1. / (1. + fanDist * fanDist * 10.);
    col += vec3 (0.2, 0.3, 0.4) * mFan * (mFan + 0.5);
  }
  col = pow (abs (clamp (col, vec3 (0.), vec3 (1.))), vec3 (1.1)) * 0.9;
  col = mix (vec3 (length (col)), col, 0.85);
  fragColor = vec4 (col, 1.);
}

#endif
