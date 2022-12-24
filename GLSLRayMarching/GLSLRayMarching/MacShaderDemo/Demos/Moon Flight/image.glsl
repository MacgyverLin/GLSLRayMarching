// "Moon Flight" by dr2 - 2019
// License: Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License

#define AA    0  // optional antialiasing

float PrCylDf (vec3 p, float r, float h);
float PrCapsDf (vec3 p, float r, float h);
float PrCapsAnDf (vec3 p, float r, float w, float h);
vec2 PixToHex (vec2 p);
vec2 HexToPix (vec2 h);
vec3 HexGrid (vec2 p);
float Minv3 (vec3 p);
float Maxv3 (vec3 p);
vec2 Rot2D (vec2 q, float a);
vec2 Hashv2v2 (vec2 p);
float Fbm2 (vec2 p);
float Fbm3 (vec3 p);
vec3 VaryNf (vec3 p, vec3 n, float f);

mat3 flMat;
vec3 sunDir, flPos, crMid, qHit;
vec2 gId, scrMid;
float dstFar, tCur, crFac, hgSize, rScrn;
int idObj;
bool isOcc;
const int idGrnd = 1, idRkt = 2, idEng = 3, idCage = 4, idScrn = 5;
const float pi = 3.14159, sqrt3 = 1.7320508;

#define DMIN(id) if (d < dMin) { dMin = d;  idObj = id; }
#define DMINQ(id) if (d < dMin) { dMin = d;  idObj = id;  qHit = q; }

float ObjCDf (vec3 p)
{
  vec3 q;
  float dMin, d, r;
  dMin = dstFar;
  d = p.y - 0.8;
  if (d < 0.1) {
    q = p;
    d = q.y - 0.5 * Fbm2 (0.3 * q.xz);
    if (crFac > 0.) {
      q.xz -= crMid.xz;
      r = length (q.xz) / crFac;
      d -= crFac * (0.03 * (1. - smoothstep (0.9, 1., r)) -
         0.3 * (1. - smoothstep (0.5, 0.9, r)));
    }
    DMIN (idGrnd);
    if (isOcc) {
      q = p - crMid;
      d = PrCapsDf (q.xzy, 0.1, 0.14);
      DMIN (idRkt);
      q.xz = abs (q.xz) - 0.08;
      q.y -= -0.08;
      d = PrCapsDf (q.xzy, 0.03, 0.06);
      DMIN (idEng);
    }
  } else dMin = d;
  return dMin;
}

void SetGrndConf ()
{
  vec2 fRand;
  float crFrac;
  crFrac = 0.6;
  fRand = Hashv2v2 (gId * vec2 (37.3, 43.1) + 27.1);
  if (fRand.x < crFrac) crFac = 0.;
  else {
    fRand.x = (fRand.x - crFrac) / (1. - crFrac);
    crFac = hgSize * 0.5 * sqrt3 * (0.55 - 0.4 * clamp (2.2 * (fRand.x - 0.5), -1., 1.));
    crMid.xz = HexToPix (gId * hgSize) + hgSize * max (0., 0.5 * sqrt3 - crFac) * fRand.x *
       sin (2. * pi * fRand.y + vec2 (0.5 * pi, 0.));
    crMid.y = 0.5 * Fbm2 (0.3 * crMid.xz) - 0.3 * crFac + 0.15;
  }
  isOcc = (crFac > 0.5 && fRand.y > 0.8);
}

float ObjCRay (vec3 ro, vec3 rd)
{
  vec3 vri, vf, hv, p;
  vec2 edN[3], pM, gIdP;
  float dHit, d, s, eps;
  eps = 0.0005;
  edN[0] = vec2 (1., 0.);
  edN[1] = 0.5 * vec2 (1., sqrt3);
  edN[2] = 0.5 * vec2 (1., - sqrt3);
  for (int k = 0; k < 3; k ++) edN[k] *= sign (dot (edN[k], rd.xz));
  vri = hgSize / vec3 (dot (rd.xz, edN[0]), dot (rd.xz, edN[1]), dot (rd.xz, edN[2]));
  vf = 0.5 * sqrt3 - vec3 (dot (ro.xz, edN[0]), dot (ro.xz, edN[1]),
     dot (ro.xz, edN[2])) / hgSize;
  pM = HexToPix (PixToHex (ro.xz / hgSize));
  gIdP = vec2 (-99.);
  dHit = 0.;
  for (int j = 0; j < 350; j ++) {
    hv = (vf + vec3 (dot (pM, edN[0]), dot (pM, edN[1]), dot (pM, edN[2]))) * vri;
    s = Minv3 (hv);
    p = ro + dHit * rd;
    gId = PixToHex (p.xz / hgSize);
    if (gId.x != gIdP.x || gId.y != gIdP.y) {
      gIdP = gId;
      SetGrndConf ();
    }
    d = ObjCDf (p);
    if (dHit + d < s) {
      dHit += d;
    } else {
      dHit = s + eps;
      pM += sqrt3 * ((s == hv.x) ? edN[0] : ((s == hv.y) ? edN[1] : edN[2]));
    }
    if (d < eps || dHit > dstFar) break;
  }
  if (d >= eps) dHit = dstFar;
  return dHit;
}

vec3 ObjCNf (vec3 p)
{
  vec4 v;
  vec2 e = vec2 (0.001, -0.001);
  v = vec4 (- ObjCDf (p + e.xxx), ObjCDf (p + e.xyy), ObjCDf (p + e.yxy), ObjCDf (p + e.yyx));
  return normalize (2. * v.yzw - dot (v, vec4 (1.)));
}

float ObjCSShadow (vec3 ro, vec3 rd)
{
  vec3 p;
  vec2 gIdP;
  float sh, d, h;
  sh = 1.;
  d = 0.05;
  gIdP = vec2 (-99.);
  for (int j = 0; j < 30; j ++) {
    p = ro + d * rd;
    gId = PixToHex (p.xz / hgSize);
    if (gId.x != gIdP.x || gId.y != gIdP.y) {
      gIdP = gId;
      SetGrndConf ();
    }
    h = ObjCDf (p);
    sh = min (sh, smoothstep (0., 0.05 * d, h));
    d += h;
    if (sh < 0.05) break;
  }
  return 0.5 + 0.5 * sh;
}

float ObjDf (vec3 p)
{
  vec3 q;
  float dMin, d, len, rad, s, b;
  dMin = dstFar;
  len = 1.;
  rad = 1.;
  p = flMat * (p - flPos);
  q = p;
  q.yz -= vec2 (-0.1 * rad, 0.3 * len);
  b = length (q.xy);
  s = (q.z > len) ? 16. * (atan (q.z - len, b) / (2. * pi) + 0.5) : 2. * q.z / len;
  s = min (abs (fract (s) - 0.5), abs (fract (12. * atan (q.y, - q.x) / (2. * pi)) - 0.5));
  d = 0.7 * max (max (PrCapsAnDf (q, rad, 0.01 * (1.5 - clamp (20. * s, 0.5, 1.75)), len),
     -1.25 * len - 0.03 - q.z), 0.2 * rad - b);
  DMINQ (idCage);
  q = p;
  q.yz -= vec2 (-0.14, 0.5);
  scrMid = q.xy;
  q.xy = Rot2D (q.xy, pi / 4.);
  q.xy -= 1.02 * rScrn * sign (q.xy);
  d = PrCylDf (q, rScrn, 0.003);
  DMINQ (idScrn);
  return dMin;
}

float ObjRay (vec3 ro, vec3 rd)
{
  vec3 p;
  float dHit, d;
  dHit = 0.;
  for (int j = 0; j < 80; j ++) {
    d = ObjDf (ro + dHit * rd);
    if (d < 0.0005 || dHit > dstFar) break;
    dHit += d;
  }
  return dHit;
}

vec3 ObjNf (vec3 p)
{
  vec4 v;
  vec2 e;
  e = vec2 (0.001, -0.001);
  v = vec4 (- ObjDf (p + e.xxx), ObjDf (p + e.xyy), ObjDf (p + e.yxy), ObjDf (p + e.yyx));
  return normalize (2. * v.yzw - dot (v, vec4 (1.)));
}

vec3 StarPat (vec3 rd, float scl)
{
  vec3 tm, qn, u;
  vec2 q;
  float f;
  tm = -1. / max (abs (rd), 0.0001);
  qn = - sign (rd) * step (tm.zxy, tm) * step (tm.yzx, tm);
  u = Maxv3 (tm) * rd;
  q = atan (vec2 (dot (u.zxy, qn), dot (u.yzx, qn)), vec2 (1.)) / pi;
  f = 0.57 * (Fbm2 (11. * dot (0.5 * (qn + 1.), vec3 (1., 2., 4.)) + 131.13 * scl * q) +
      Fbm2 (13. * dot (0.5 * (qn + 1.), vec3 (1., 2., 4.)) + 171.13 * scl * q.yx));
  return 4. * vec3 (1., 1., 0.8) * pow (f, 16.);
}

vec3 ErCol (vec3 rd)
{
  vec3 erDir, col, vn;
  float erRad, bs, ts;
  erDir = normalize (vec3 (0.02, -0.04, 1.));
  erRad = 0.017;
  col = vec3 (0.);
  bs = dot (rd, erDir);
  ts = bs * bs - 1. + erRad * erRad;
  if (ts > 0.) {
    ts = bs - sqrt (ts);
    if (ts > 0.) {
      vn = normalize ((ts * rd - erDir) / erRad);
      col = mix (vec3 (0.3, 0.4, 0.8), vec3 (1., 1., 0.95),
         smoothstep (0.2, 0.8, Fbm2 (6. * vn.xy + 7.1))) * (0.5 + 0.5 * max (- dot (vn, rd), 0.));
    }
  }
  return col;
}

vec3 ShowScene (vec3 ro, vec3 rd)
{
  vec4 col4;
  vec3 col, vn;
  vec2 vf, g;
  float dstObj, nDotS, sh, s;
  int idObjS;
  bool isScrn, showBg;
  rScrn = 0.03;
  isScrn = false;
  showBg = true;
  dstObj = ObjRay (ro, rd);
  if (dstObj < dstFar) {
    ro += dstObj * rd;
    vn = ObjNf (ro);
    if (idObj == idCage) {
      col = mix (vec3 (0.45, 0.5, 0.5), vec3 (0.5, 0.5, 0.6), smoothstep (0.4, 0.6,
         Fbm3 (64. * qHit)));
      vn = VaryNf (128. * qHit, vn, 0.2);
    } else if (idObj == idScrn) {
      if (length (qHit.xy) < 0.95 * rScrn) {
        ro = flPos;
        qHit.xy = Rot2D (qHit.xy, - pi / 4.);
        rd = normalize (vec3 (qHit.xy, - rScrn)).xzy;
        if (abs (scrMid.y) > abs (scrMid.x)) rd.yz = Rot2D (rd.yz, -0.25 * pi * sign (scrMid.y));
        else rd.xy = Rot2D (rd.xy, 0.25 * pi * sign (scrMid.x));
        isScrn = true;
      } else {
        col = vec3 (0.6, 0.5, 0.5) * (0.7 + 0.3 * sin (256. * atan (qHit.y, qHit.x)));
      }
    }
    if (! isScrn) {
      nDotS = max (dot (vn, sunDir), 0.);
      nDotS *= nDotS;
      col = col * (0.2 + 0.1 * abs (vn.y) + 0.6 * nDotS * nDotS) +
         0.2 * pow (max (dot (normalize (sunDir - rd), vn), 0.), 32.);
      showBg = false;
    }
  }
  if (dstObj >= dstFar || isScrn) {
    dstObj = (rd.y < 0.) ? ObjCRay (ro, rd) : dstFar;
    if (dstObj < dstFar) {
      ro += dstObj * rd;
      vn = ObjCNf (ro);
      idObjS = idObj;
      if (idObj == idGrnd) {
        col4 = vec4 (0.7, 0.6, 0.4, 0.01) * (0.7 + 0.3 * Fbm2 (0.2 * ro.zx));
        if (crFac > 0.) {
          g = ro.xz - crMid.xz;
          s = smoothstep (0.5, 0.9, length (g) / crFac);
          col4 = mix (col4, vec4 (0.6, 0.5, 0.3, 0.01) * (0.7 + 0.3 * sin (64. * atan (g.y, g.x)) *
             (0.6 + 0.4 * sin (32. * pi * ro.y)) * s), 1. - s);
          vf = vec2 (4., 2. + s);
        } else vf = vec2 (4., 3.);
        vf.y *= 1. - smoothstep (0.2, 0.6, dstObj / dstFar);
        if (vf.y > 0.) vn = VaryNf (vf.x * ro, vn, vf.y);
        sh = ObjCSShadow (ro, sunDir);
        col = col4.rgb * (0.2 + 0.1 * max (vn.y, 0.) +
           0.7 * sh * max (dot (vn, sunDir), 0.)) + col4.a * smoothstep (0.8, 1., sh) *
           pow (max (dot (normalize (sunDir - rd), vn), 0.), 32.);
      } else {
        if (idObj == idRkt) {
          g = Rot2D (ro.xz - crMid.xz, pi / 8.);
          col4 = mix (vec4 (0.5, 0.5, 1., 0.2), vec4 (1., 1., 1., 0.2),
             smoothstep (0.45, 0.55, mod (4. * (((length (g) > 0.) ? atan (g.y, g.x) : 0.) /
             (2. * pi) + 0.5), 1.)));
        } else if (idObj == idEng) {
          col4 = vec4 (1., 0.7, 0.4, 0.2);
        }
        col = col4.rgb * (0.2 + 0.8 * max (dot (vn, sunDir), 0.)) + col4.a * 
           pow (max (dot (normalize (sunDir - rd), vn), 0.), 32.);
      }
      col *= 1. - smoothstep (0.8, 0.95, dstObj / dstFar);
      if (isScrn) col *= (dstObj < dstFar && (idObjS == idRkt || idObjS == idEng)) ?
         vec3 (1.3, 0.3, 0.3) : vec3 (0.4, 0.9, 0.7);
      showBg = false;
    } else {
      col = vec3 (0.);
      if (! isScrn) col += ErCol (rd);
    }
  }
  if (showBg || idObj == idGrnd && length (col) < 0.03) col += StarPat (rd, 8.);
  return clamp (col, 0., 1.);
}

vec3 TrackPath (float t)
{
  return t * vec3 (0.1, 0., sqrt (0.99)) + vec3 (2. * cos (0.1 * t), 0., 0.);
}

void VuPM (float t)
{
  vec3 fpF, fpB, vel, acc, va, ort, cr, sr;
  float dt;
  dt = 1.;
  flPos = TrackPath (t);
  fpF = TrackPath (t + dt);
  fpB = TrackPath (t - dt);
  vel = (fpF - fpB) / (2. * dt);
  vel.y = 0.;
  acc = (fpF - 2. * flPos + fpB) / (dt * dt);
  acc.y = 0.;
  va = cross (acc, vel) / length (vel);
  ort = vec3 (0.2, atan (vel.z, vel.x) - 0.5 * pi, 5. * length (va) * sign (va.y));
  cr = cos (ort);
  sr = sin (ort);
  flMat = mat3 (cr.z, - sr.z, 0., sr.z, cr.z, 0., 0., 0., 1.) *
     mat3 (1., 0., 0., 0., cr.x, - sr.x, 0., sr.x, cr.x) *
     mat3 (cr.y, 0., - sr.y, 0., 1., 0., sr.y, 0., cr.y);
}

void mainImage (out vec4 fragColor, in vec2 fragCoord)
{
  mat3 vuMat;
  vec4 mPtr, dateCur;
  vec3 ro, rd, col, c;
  vec2 canvas, uv, ori, ca, sa;
  float el, az, zmFac, sr;
  canvas = iResolution.xy;
  uv = 2. * fragCoord.xy / canvas - 1.;
  uv.x *= canvas.x / canvas.y;
  tCur = iTime;
  dateCur = iDate;
  mPtr = iMouse;
  mPtr.xy = mPtr.xy / canvas - 0.5;
  tCur = mod (tCur, 2400.) + 30. * floor (dateCur.w / 7200.) + 11.1;
  hgSize = 1.;
  VuPM (2. * tCur);
  az = 0.;
  el = -0.03 * pi;
  if (mPtr.z > 0.) {
    az += 1.5 * pi * mPtr.x;
    el += 1.5 * pi * mPtr.y;
    az = clamp (az, -0.5 * pi, 0.5 * pi);
    el = clamp (el, -0.4 * pi, 0.4 * pi);
  }
  ori = vec2 (el, az);
  ca = cos (ori);
  sa = sin (ori);
  vuMat = mat3 (ca.y, 0., - sa.y, 0., 1., 0., sa.y, 0., ca.y) *
     mat3 (1., 0., 0., 0., ca.x, - sa.x, 0., sa.x, ca.x);
  flPos.y += 5.;
  ro = flPos;
  dstFar = 50.;
  sunDir = normalize (vec3 (1., 0.5, -1.));
  sunDir.xz = Rot2D (sunDir.xz, 0.3 * pi * sin (0.1 * tCur));
  zmFac = 2.6;
#if ! AA
  const float naa = 1.;
#else
  const float naa = 3.;
#endif  
  if (abs (uv.y) < 0.85) {
    col = vec3 (0.);
    sr = 2. * mod (dot (mod (floor (0.5 * (uv + 1.) * canvas), 2.), vec2 (1.)), 2.) - 1.;
    for (float a = 0.; a < naa; a ++) {
      rd = normalize (vec3 (uv + step (1.5, naa) * Rot2D (vec2 (0.5 / canvas.y, 0.),
         sr * (0.667 * a + 0.5) * pi), zmFac));
      rd = vuMat * rd;
      rd = rd * flMat;
      col += (1. / naa) * ShowScene (ro, rd);
    }
  } else col = vec3 (0.05);
  fragColor = vec4 (pow (col, vec3 (0.8)), 1.);
}

float PrCylDf (vec3 p, float r, float h)
{
  return max (length (p.xy) - r, abs (p.z) - h);
}

float PrCapsDf (vec3 p, float r, float h)
{
  return length (p - vec3 (0., 0., clamp (p.z, - h, h))) - r;
}

float PrCapsAnDf (vec3 p, float r, float w, float h)
{
  p.z = abs (p.z);
  return max (length (p - vec3 (0., 0., min (p.z, h + w))) - r,
     - length (p - vec3 (0., 0., min (p.z, h - w))) + r) - w;
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

vec3 HexGrid (vec2 p)
{
  vec2 q;
  p -= HexToPix (PixToHex (p));
  q = abs (p);
  return vec3 (p, 0.5 * sqrt3 - q.x + 0.5 * min (q.x - sqrt3 * q.y, 0.));
}

float Minv3 (vec3 p)
{
  return min (p.x, min (p.y, p.z));
}

float Maxv3 (vec3 p)
{
  return max (p.x, max (p.y, p.z));
}

vec2 Rot2D (vec2 q, float a)
{
  vec2 cs;
  cs = sin (a + vec2 (0.5 * pi, 0.));
  return vec2 (dot (q, vec2 (cs.x, - cs.y)), dot (q.yx, cs));
}

const float cHashM = 43758.54;

vec2 Hashv2v2 (vec2 p)
{
  vec2 cHashVA2 = vec2 (37., 39.);
  return fract (sin (vec2 (dot (p, cHashVA2), dot (p + vec2 (1., 0.), cHashVA2))) * cHashM);
}

vec4 Hashv4v3 (vec3 p)
{
  vec3 cHashVA3 = vec3 (37., 39., 41.);
  vec2 e = vec2 (1., 0.);
  return fract (sin (vec4 (dot (p + e.yyy, cHashVA3), dot (p + e.xyy, cHashVA3),
     dot (p + e.yxy, cHashVA3), dot (p + e.xxy, cHashVA3))) * cHashM);
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

float Noisefv3 (vec3 p)
{
  vec4 t;
  vec3 ip, fp;
  ip = floor (p);
  fp = fract (p);
  fp *= fp * (3. - 2. * fp);
  t = mix (Hashv4v3 (ip), Hashv4v3 (ip + vec3 (0., 0., 1.)), fp.z);
  return mix (mix (t.x, t.y, fp.x), mix (t.z, t.w, fp.x), fp.y);
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

float Fbm3 (vec3 p)
{
  float f, a;
  f = 0.;
  a = 1.;
  for (int i = 0; i < 5; i ++) {
    f += a * Noisefv3 (p);
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
  vec2 e;
  e = vec2 (0.1, 0.);
  g = vec3 (Fbmn (p + e.xyy, n), Fbmn (p + e.yxy, n), Fbmn (p + e.yyx, n)) - Fbmn (p, n);
  return normalize (n + f * (g - n * dot (n, g)));
}
