// "Paternoster" by dr2 - 2018
// License: Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License

float PrBoxDf (vec3 p, vec3 b);
float PrBox2Df (vec2 p, vec2 b);
float PrSphDf (vec3 p, float r);
float PrCylDf (vec3 p, float r, float h);
float PrRoundCylDf (vec3 p, float r, float rt, float h);
float SmoothBump (float lo, float hi, float w, float x);
vec2 Rot2D (vec2 q, float a);
vec3 HsvToRgb (vec3 c);
float Hashff (float p);
float Noisefv2 (vec2 p);
float Fbm2 (vec2 p);
vec3 VaryNf (vec3 p, vec3 n, float f);

float dstFar, tCur, flHt, spd, rAngA;
int idObj;
const int idFlCl = 1, idFrm = 2, idPat = 3, idLt = 4, idWl = 5, idRob = 6, idEye = 7;
const float pi = 3.14159;

#define DMIN(id) if (d < dMin) { dMin = d;  idObj = id; }

float RobDf (vec3 p, float dMin, float szFac)
{
  vec3 q;
  float d;
  p /= szFac;
  dMin /= szFac;
  p.xz = - p.xz;
  q = p;  q.y -= 2.3;
  d = max (PrSphDf (q, 0.85), - q.y - 0.2);
  q = p;  q.y -= 1.55;
  d = min (d, PrRoundCylDf (q.xzy, 0.9, 0.28, 0.7));
  q = p;  q.x = abs (q.x) - 0.3;  q.y -= 3.1;
  q.xy = Rot2D (q.xy, 0.2 * pi);
  q.y -= 0.25;
  d = min (d, PrRoundCylDf (q.xzy, 0.06, 0.04, 0.3));
  q = p;  q.x = abs (q.x) - 1.05;  q.y -= 2.1;
  q.yz = Rot2D (q.yz, rAngA);
  q.y -= -0.5;
  d = min (d, PrRoundCylDf (q.xzy, 0.2, 0.15, 0.6));
  q = p;  q.x = abs (q.x) - 0.4;  q.y -= 0.475;
  d = min (d, PrRoundCylDf (q.xzy, 0.25, 0.15, 0.55));
  DMIN (idRob);
  q = p;  q.x = abs (q.x) - 0.4;  q.yz -= vec2 (2.7, 0.7);
  d = PrSphDf (q, 0.15);
  DMIN (idEye);
  dMin *= szFac;
  return dMin;
}

float ObjDf (vec3 p)
{
  vec3 q, qq;
  float dMin, d, sy;
  dMin = dstFar;
  sy = p.y - sign (p.x) * (spd + 32. * flHt) + flHt;
  q = p;  q.y = mod (q.y - 0.2, 2. * flHt) - flHt;
  d = PrBoxDf (q, vec3 (20., 0.3, 5.));
  q.x = abs (q.x) - 0.8;
  d = max (d, - PrBox2Df (q.xz, vec2 (0.41, 0.51)));
  DMIN (idFlCl);
  q = p;  q.z = abs (q.z) - 5.;
  d = max (abs (q.z) - 0.1, 0.);
  DMIN (idWl);
  qq = p;  qq.y = mod (qq.y + flHt, 2. * flHt) - flHt;
  q = qq;  q.x = abs (abs (q.x) - 0.8) - 0.44;  q.z -= -0.5;
  d = PrCylDf (q.xzy, 0.04, flHt);
  DMIN (idFrm);
  q = qq;  q.x = abs (q.x) - 0.8;  q.yz -= vec2 (1.1, -0.5);
  d = max (PrCylDf (q.yzx, 0.04, 0.42), q.z);
  DMIN (idFrm);
  q = qq;  q.x = abs (q.x) - 0.8;  q.y -= 1.3;
  d = PrBoxDf (q - vec3 (0., 0., -0.51), vec3 (0.42, 0.2, 0.01));
  DMIN (idFrm);
  q = qq;  q.x = mod (q.x, 2.) - 1.;  q.y -= 1.4;  q.z = abs (q.z) - 2.;
  d = PrCylDf (q.xzy, 0.2, 0.05);
  DMIN (idLt);
  q = qq;
  d = PrBoxDf (q, vec3 (2., flHt, 0.5));
  qq = p;  qq.x = abs (qq.x) - 0.8;  qq.y = mod (sy, 2. * flHt) - flHt;
  q = qq;
  d = max (d, - PrBoxDf (q + vec3 (0., 0., 0.02), vec3 (0.4, 1., 0.5)));
  DMIN (idPat);
  q = qq;  q.y -= 0.97;
  d = PrCylDf (q.xzy, 0.15, 0.03);
  DMIN (idLt);
  if (Hashff (77.7 * floor (sy / (2. * flHt))) > 0.2) {
    q = qq;  q.y -= -0.97;
    dMin = RobDf (q, dMin, 0.15 + 0.15 * Hashff (37.7 * floor (sy / (2. * flHt))));
  }
  dMin = max (dMin, max (abs (p.y) - 3. * flHt, abs (p.x) - 20.));
  return dMin;
}

float ObjRay (vec3 ro, vec3 rd)
{
  float dHit, d;
  dHit = 0.;
  for (int j = 0; j < 150; j ++) {
    d = ObjDf (ro + rd * dHit);
    if (d < 0.0005 || dHit > dstFar) break;
    dHit += d;
  }
  return dHit;
}

vec3 ObjNf (vec3 p)
{
  vec4 v;
  vec2 e = vec2 (0.0001, -0.0001);
  v = vec4 (ObjDf (p + e.xxx), ObjDf (p + e.xyy), ObjDf (p + e.yxy), ObjDf (p + e.yyx));
  return normalize (vec3 (v.x - v.y - v.z - v.w) + 2. * v.yzw);
}

float ObjAO (vec3 ro, vec3 rd)
{
  float ao, d;
  ao = 0.;
  for (int j = 0; j < 8; j ++) {
    d = 0.1 + float (j) / 16.;
    ao += max (0., d - 3. * ObjDf (ro + d * rd));
  }
  return 0.7 + 0.3 * clamp (1. - 0.2 * ao, 0., 1.);
}

vec3 ShStagGrid (vec2 p, vec2 g)
{
  vec2 q, sq, ss;
  q = p * g;
  if (2. * floor (0.5 * floor (q.y)) != floor (q.y)) q.x += 0.5;
  sq = smoothstep (0.03, 0.06, abs (fract (q + 0.5) - 0.5));
  q = fract (q) - 0.5;
  ss = 0.2 * smoothstep (0.35, 0.5, abs (q.xy)) * sign (q.xy);
  if (abs (q.x) < abs (q.y)) ss.x = 0.;
  else ss.y = 0.;
  return vec3 (ss.x, 0.8 + 0.2 * sq.x * sq.y, ss.y);
}

vec3 ShowScene (vec3 ro, vec3 rd)
{
  vec4 col4;
  vec3 col, vn, ltDir, ltPos[3], rg;
  vec2 vf;
  float dstObj, spec, wdPos, s, h, dfSum, spSum, at, ao;
  ltPos[0] = vec3 (1.5, 1., -2.);
  ltPos[1] = vec3 (-1.5, 1., -2.);
  ltPos[2] = vec3 (0., 1., 2.);
  flHt = 1.5;
  spd = 0.3 * tCur;
  rAngA = 2. * pi * (0.5 - abs (mod (0.3 * tCur, 1.) - 0.5));
  dstObj = ObjRay (ro, rd);
  if (dstObj < dstFar && idObj == idPat) {
    vec3 ror;
    ror = ro + dstObj * rd;
    vn = ObjNf (ror);
    if (vn.z < 0. && abs (abs (ror.x) - 0.8) < 0.3 && 
       abs (mod (ror.y - sign (ror.x) * spd + flHt, 2. * flHt) - flHt - 0.2) < 0.6) {
      ro = ror;
      rd = reflect (rd, vn);
      ro += 0.01 * rd;
      dstObj = ObjRay (ro, rd);
    }
  }
  if (dstObj < dstFar) {
    ro += dstObj * rd;
    vn = ObjNf (ro);
    vf = vec2 (0.);
    if (idObj == idFlCl) {
      if (abs (vn.y) < 0.001) col4 = vec4 (0.2, 0.2, 0.2, 0.);
      else if (abs (ro.z + 0.5) < 0.1 && vn.y > 0.001 && abs (abs (ro.x) - 0.8) < 0.4)
         col4 = vec4 (0.8, 0.8, 0.85, -1.);
      else {
        s = length (vec2 (mod (ro.x, 2.) - 1., abs (ro.z) - 2.));
        if (vn.y > 0.001) col4 = mix (vec4 (0.3, 0.2, 0.1, -1.), vec4 (0.27, 0.15, 0., -1.),
           smoothstep (0.4, 0.5, Fbm2 (vec2 (2., 16.) * ro.xz))) * (1. - 0.2 *
           SmoothBump (0.03, 0.07, 0.01, mod (2. * ro.z, 1.))) * (1. - 0.2 * smoothstep (0.4, 1., s));
        else col4 = vec4 (0.3, 0.3, 0.25, -1.) * (1. - 0.1 * smoothstep (0.4, 0.9, s));
      }
    } else if (idObj == idWl) {
      s = mod (ro.x + 2., 4.) - 2.;
      if (abs (s) < 0.4 && ro.y < 0.8) {
        if (abs (s) < 0.35 && abs (ro.y - 0.4) < 0.15) col4 = vec4 (0.8, 0.6, 0.2, -1.) *
           (1. - 0.1 * SmoothBump (0.3, 0.7, 0.1, mod (32. * length (vec2 (0.5 * s, ro.y - 0.4)), 1.)));
        else if (length (vec2 (s, ro.y) - vec2 (0.28, -0.2)) < 0.06) col4 = vec4 (0.3, 0.1, 0., 0.1);
        else col4 = vec4 (0.4, 0.2, 0., 0.1);
      } else if (ro.z < 0. && (step (abs (abs (abs (ro.x) - 1.2) - 0.1), 0.03) *
         step (abs (ro.y - 0.3), 0.2) > 0. || abs (length (vec2 (abs (ro.x) - 1.2, ro.y - 0.3)) -
         0.35) < 0.03)) {
        col4 = vec4 (1., 0.4, 0., 0.2);
      } else {
        col4 = vec4 (0.5, 0.6, 0.4, 0.2);
        rg = ShStagGrid (ro.xy, (3./1.2) * vec2 (1., 2.));
        col4 *= rg.y;
        rg.xz *= sign (vn.z);
        if (rg.x == 0.) vn.zy = Rot2D (vn.zy, rg.z);
        else vn.zx = Rot2D (vn.zx, rg.x);
      }
    } else if (idObj == idFrm) {
      if (vn.z < 0. && abs (abs (ro.x) - 0.8) < 0.4 &&
         abs (mod (ro.y + flHt, 2. * flHt) - flHt) > 1.13) {
        col4 = vec4 (0.8, 0.8, 0.9, 0.3);
        vn.yz = Rot2D (vn.yz, -0.1 * pi * (1. + sin (2. * pi * mod (32. * ro.y, 1.))));
      } else {
        col4 = vec4 (0.5, 0.3, 0., 0.3);
      }
    } else if (idObj == idPat) {
      wdPos = -99.;
      s = mod (ro.y - sign (ro.x) * spd + flHt, 2. * flHt) - flHt;
      h = 17.1 * Hashff (33.3 * floor ((ro.y - sign (ro.x) *
         (spd + 32. * flHt) + flHt) / (2. * flHt)));
      if (abs (abs (ro.x) - 0.8) > 0.4 || ro.z > 0.5) {
        if (abs (ro.y) < 0.01) {
          col4 = vec4 (0.8, 0.8, 0.8, 0.3);
          if (vn.z < 0.) vn.yz = Rot2D (vn.yz, 0.1 * pi * (1. + sin (8. * pi * ro.y)));
        } else if (ro.y > 0.) {
          col4 = vec4 (0.7, 0.5, 0.2, 0.1);
          if (step (abs (abs (ro.x) - 0.04), 0.02) * step (abs (ro.y - 0.7), 0.1) > 0. ||
             abs (length (vec2 (ro.x, ro.y - 0.7)) - 0.15) < 0.02) col4 *= 0.5;
          else vf = vec2 (32, 0.5);
        } else {
          col4 = vec4 (0.2, 0.4, 0.3, 0.1) * (1. - 0.1 * Noisefv2 (64. * ((abs (vn.x) > 0.1) ?
             ro.yz : ro.yx)));
        }
      } else if (abs (vn.y) > 0.9) {
        if (vn.y > 0.) {
          col4 = vec4 (0., 0.3, 0., 0.);
          vf = vec2 (64., 0.5);
        } else {
          col4 = vec4 (0.7, 0.7, 0.75, -1.) * (1. - 0.2 * smoothstep (0.2, 0.4,
             length (vec2 (abs (ro.x) - 0.8, ro.z))));
        }
      } else if (abs (vn.x) > 0.01) {
        wdPos = ro.z;
      } else if (ro.z < 0.) {
        if (abs (s) > flHt - 0.46) {
          col4 = vec4 (0.6, 0.3, 0.2, 0.1);
          vn.xz = Rot2D (vn.xz, 0.1 * pi * (1. + sin (2. * pi * mod (32. * ro.x, 1.))));
        } else col4 = mix (vec4 (1., 0., 0., 0.1), vec4 (0.1, 0., 0., 0.1),
           step (0.6, mod (16. * (abs (ro.x) - 0.8), 1.)));
      } else if (ro.z < 0.5) {
        wdPos = ro.x;
      }
      if (wdPos != -99.) col4 = mix (vec4 (0.4, 0.1, 0., 0.1), vec4 (0.3, 0.1, 0., 0.1),
         smoothstep (0.4, 0.5, Fbm2 (h + 2. * vec2 (16., 4.) * vec2 (wdPos, s))));
    } else if (idObj == idLt) {
      col4 = vec4 (0.9, 0.9, 0.5, -2.);
    } else if (idObj == idRob) {
      col4 = vec4 (HsvToRgb (vec3 (Hashff (33.3 * floor ((ro.y - sign (ro.x) *
         (spd + 32. * flHt) + flHt) / (2. * flHt))), 0.8, 0.8)), 0.2);
    } else if (idObj == idEye) {
      col4 = mix (vec4 (0., 1., 0., -2.), vec4 (0.7, 0., 0.3, -2.),
         smoothstep (0.9, 0.95, - dot (vn, rd)));
    }
    if (vf.x > 0.) vn = VaryNf (vf.x * ro, vn, vf.y);
    col = col4.rgb;
    if (col4.a >= 0.) {
      ao = ObjAO (ro, vn);
      dfSum = 0.;
      spSum = 0.;
      for (int k = 0; k < 3; k ++) {
        ltDir = normalize (ltPos[k]);
        at = smoothstep (0.3, 0.5, dot (normalize (ltPos[k] - ro), ltDir));
        dfSum += at * max (dot (vn, ltDir), 0.);
        spSum += at * pow (max (dot (normalize (ltDir - rd), vn), 0.), 64.);
      }
      col = ao * (col * (0.1 + 0.4 * dfSum) + col4.a * step (dot (vn, rd), -0.05) * spSum);
    } else if (col4.a == -2.) col *= 0.7 - 0.3 * dot (vn, rd);
  } else col = vec3 (0.1);
  return clamp (col, 0., 1.);
}

void mainImage (out vec4 fragColor, in vec2 fragCoord)
{
  mat3 vuMat;
  vec4 mPtr;
  vec3 ro, rd, vd;
  vec2 canvas, uv;
  float az;
  canvas = iResolution.xy;
  uv = 2. * fragCoord.xy / canvas - 1.;
  uv.x *= canvas.x / canvas.y;
  tCur = iTime;
  mPtr = iMouse;
  mPtr.xy = mPtr.xy / canvas - 0.5;
  az = -0.5 * pi;
  if (mPtr.z > 0.) az -= 0.4 * pi * mPtr.x;
  az = clamp (az + 0.5 * pi, - 0.15 * pi, 0.15 * pi) - 0.5 * pi;
  ro = vec3 (4.8 * cos (az), 0.4, 4.8 * sin (az));
  vd = normalize (vec3 (0., 0.2, 0.) - ro);
  ro.x += 0.8 * SmoothBump (0.25, 0.75, 0.1, mod (0.1 * tCur, 1.)) *
     (2. *  floor (mod (0.1 * tCur, 2.)) - 1.);
  vuMat = mat3 (vec3 (vd.z, 0., - vd.x) / sqrt (1. - vd.y * vd.y),
     vec3 (- vd.y * vd.x, 1. - vd.y * vd.y, - vd.y * vd.z) / sqrt (1. - vd.y * vd.y), vd);
  rd = vuMat * normalize (vec3 (uv, 2.7));
  dstFar = 30.;
  fragColor = vec4 (ShowScene (ro, rd), 1.);
}

float PrBoxDf (vec3 p, vec3 b)
{
  vec3 d;
  d = abs (p) - b;
  return min (max (d.x, max (d.y, d.z)), 0.) + length (max (d, 0.));
}

float PrBox2Df (vec2 p, vec2 b)
{
  vec2 d;
  d = abs (p) - b;
  return min (max (d.x, d.y), 0.) + length (max (d, 0.));
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
  float dxy, dz;
  dxy = length (p.xy) - r;
  dz = abs (p.z) - h;
  return min (min (max (dxy + rt, dz), max (dxy, dz + rt)), length (vec2 (dxy, dz) + rt) - rt);
}

float SmoothBump (float lo, float hi, float w, float x)
{
  return (1. - smoothstep (hi - w, hi + w, x)) * smoothstep (lo - w, lo + w, x);
}

vec2 Rot2D (vec2 q, float a)
{
  return q * cos (a) + q.yx * sin (a) * vec2 (-1., 1.);
}

vec3 HsvToRgb (vec3 c)
{
  vec3 p;
  p = abs (fract (c.xxx + vec3 (1., 2./3., 1./3.)) * 6. - 3.);
  return c.z * mix (vec3 (1.), clamp (p - 1., 0., 1.), c.y);
}

const float cHashM = 43758.54;

float Hashff (float p)
{
  return fract (sin (p) * cHashM);
}

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
