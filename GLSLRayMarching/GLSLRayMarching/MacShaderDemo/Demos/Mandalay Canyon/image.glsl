// "Mandalay Canyon" by dr2 - 2020
// License: Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License

// Traverse a fractal landscape with smooth transitions to avoid aliasing (mouseable).

// More info in "Mandalay Fractal" (https://www.shadertoy.com/view/wstXD8)

#define VAR_ZERO min (iFrame, 0)

vec3 HsvToRgb (vec3 c);
float Minv3 (vec3 p);
mat3 StdVuMat (float el, float az);
vec2 Rot2D (vec2 q, float a);

vec3 ltDir, pFold;
float dstFar, mScale, tDisc;
const float pi = 3.14159;

const float itMax = 12.;

float PPFoldD (vec3 p)
{
  vec3 s;
  p.y = max (p.y, p.z);
  s = vec3 (p.x, max (abs (p.x - pFold.x) - pFold.x, p.y - 4. * pFold.x),
     max (p.x - 2. * pFold.x - pFold.y, p.y - pFold.z));
  return Minv3 (s);
}

vec3 PPFold (vec3 p)
{
  return vec3 (PPFoldD (p), PPFoldD (p.yzx), PPFoldD (p.zxy));
}

float ObjDf (vec3 p)
{
  vec4 p4;
  float pp;
  p.xz = mod (p.xz + 1., 2.) - 1.;
  p4 = vec4 (p, 1.);
  for (float j = 0.; j < itMax; j ++) {
    p4.xyz = 2. * clamp (p4.xyz, -1., 1.) - p4.xyz;
    p4.xyz = - sign (p4.xyz) * PPFold (abs (p4.xyz));
    pp = dot (p4.xyz, p4.xyz);
    p4 = mScale * p4 / clamp (pp, 0.25, 1.) + vec4 (p, 1.);
  }
  return length (p4.xyz) / p4.w;
}

float ObjCf (vec3 p)
{
  vec4 p4;
  float pp, ppMin, cn;
  p.xz = mod (p.xz + 1., 2.) - 1.;
  p4 = vec4 (p, 1.);
  cn = 0.;
  ppMin = 1.;
  for (float j = 0.; j < itMax; j ++) {
    p4.xyz = 2. * clamp (p4.xyz, -1., 1.) - p4.xyz;
    p4.xyz = - sign (p4.xyz) * PPFold (abs (p4.xyz));
    pp = dot (p4.xyz, p4.xyz);
    p4 = mScale * p4 / clamp (pp, 0.25, 1.) + vec4 (p, 1.);
    if (pp < ppMin) {
      cn = j;
      ppMin = pp;
    }
  }
  return cn;
}

float ObjRay (vec3 ro, vec3 rd)
{
  float dHit, h, s, sLo, sHi, eps;
  eps = 0.0005;
  s = 0.;
  sLo = 0.;
  dHit = dstFar;
  for (int j = VAR_ZERO; j < 160; j ++) {
    h = ObjDf (ro + s * rd);
    if (h < eps || s > dstFar) {
      sHi = s;
      break;
    }
    sLo = s;
    s += h;
  }
  if (h < eps) {
    for (int j = VAR_ZERO; j < 5; j ++) {
      s = 0.5 * (sLo + sHi);
      if (ObjDf (ro + s * rd) > eps) sLo = s;
      else sHi = s;
    }
    dHit = sHi;
  }
  return dHit;
}

vec3 ObjNf (vec3 p)
{
  vec4 v;
  vec2 e;
  e = vec2 (0.0001, -0.0001);
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
    h = ObjDf (ro + rd * d);
    sh = min (sh, smoothstep (0., 0.05 * d, h));
    d += clamp (h, 0.01, 0.1);
    if (sh < 0.05) break;
  }
  return 0.4 + 0.6 * sh;
}

float ObjAO (vec3 ro, vec3 rd)
{
  float ao, d;
  ao = 0.;
  for (float j = float (VAR_ZERO) + 1.; j < 4.; j ++) {
    d = 0.02 * j;
    ao += max (0., d - ObjDf (ro + d * rd));
  }
  return 0.4 + 0.6 * clamp (1. - 5. * ao, 0., 1.);
}

vec3 ShowScene (vec3 ro, vec3 rd)
{
  vec3 col, vn;
  float dstObj, sh, ao;
  pFold = HsvToRgb (vec3 (0., 0.2, 1.));
  mScale = 3.;
  dstObj = ObjRay (ro, rd);
  if (dstObj < dstFar) {
    ro += dstObj * rd;
    vn = ObjNf (ro);
    ao = ObjAO (ro, vn);
    sh = min (ObjSShadow (ro, ltDir), ao);
    col = HsvToRgb (vec3 (mod (0.02 * tDisc + 0.06 * ObjCf (ro), 1.), 0.5, 1.));
    col = col * (0.2 * ao + 0.8 * sh * max (dot (vn, ltDir), 0.)) +
       0.4 * step (0.95, sh) * pow (max (0., dot (ltDir, reflect (rd, vn))), 4.);
  } else col = vec3 (0.4, 0.4, 0.5);
  return pow (clamp (col, 0., 1.), vec3 (0.9));
}

void mainImage (out vec4 fragColor, in vec2 fragCoord)
{
  vec4 mPtr, dateCur;
  vec3 ro, rd, col[2];
  vec2 canvas, uv;
  float tCur, tStep, el, az, zmFac;
  canvas = iResolution.xy;
  uv = 2. * fragCoord.xy / canvas - 1.;
  uv.x *= canvas.x / canvas.y;
  tCur = iTime;
  dateCur = iDate;
  mPtr = iMouse;
  mPtr.xy = mPtr.xy / canvas - 0.5;
  zmFac = 1.2;
  tCur = mod (tCur, 2400.) + 30. * floor (dateCur.w / 7200.) + 11.1;
  dstFar = 10.;
  ltDir = normalize (vec3 (0.3, 1.5, -1.));
  tStep = 2.;
  if (mPtr.z > 0.) {
    az = 0.;
    el = -0.05 * pi;
    az += 2. * pi * mPtr.x;
    el += 0.3 * pi * mPtr.y;
    el = clamp (el, -0.49 * pi, 0.1 * pi);
  }
  for (int k = VAR_ZERO; k <= 1; k ++) {
    tDisc = tStep * (float (k) + floor (tCur / tStep));
    if (mPtr.z <= 0.) {
      az = 0.;
      el = -0.05 * pi;
      az += 0.1 * pi * cos (0.013 * 2. * pi * tDisc);
      el += 0.06 * pi * cos (0.01 * 2. * pi * tDisc);
    }
    rd = StdVuMat (el, az) * normalize (vec3 (uv, zmFac));
    ro = vec3 (1., 4.1, 0.07 * tDisc);
    col[k] = ShowScene (ro, rd);
  }
  fragColor = vec4 (mix (col[0], col[1], smoothstep (0.1, 0.9, fract (tCur / tStep))), 1.);
}

vec3 HsvToRgb (vec3 c)
{
  return c.z * mix (vec3 (1.), clamp (abs (fract (c.xxx + vec3 (1., 2./3., 1./3.)) * 6. - 3.) - 1., 0., 1.), c.y);
}

float Minv3 (vec3 p)
{
  return min (p.x, min (p.y, p.z));
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
