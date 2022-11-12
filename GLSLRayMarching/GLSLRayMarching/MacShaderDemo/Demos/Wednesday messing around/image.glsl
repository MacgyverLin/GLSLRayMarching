// CC0: Wednesday messing around
// Tinkered a bit with an earlier shader
// Thought while similar it turned out distinct enough to share

#define COLORBURN
#define SKYDOME
#define PERIOD        10.0

#define PI            3.141592654
#define ROT(a)        mat2(cos(a), sin(a), -sin(a), cos(a))

const int   bars     = 7;
const mat2  trans    = ROT(PI/9.0);
const float twist    = 1.0;
const float dist     = 0.5;
const float rounding = 0.125;

const float raymarchFactor = 0.8;

#define TAU         (2.0*PI)
#define TIME        iTime
#define RESOLUTION  iResolution

#define MAX_RAY_LENGTH  15.0
#define MAX_RAY_MARCHES 70
#define TOLERANCE       0.001
#define NORM_OFF        0.005

int g_hit     = 0;
int g_period  = 0;

// License: WTFPL, author: sam hocevar, found: https://stackoverflow.com/a/17897228/418488
const vec4 hsv2rgb_K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
vec3 hsv2rgb(vec3 c) {
  vec3 p = abs(fract(c.xxx + hsv2rgb_K.xyz) * 6.0 - hsv2rgb_K.www);
  return c.z * mix(hsv2rgb_K.xxx, clamp(p - hsv2rgb_K.xxx, 0.0, 1.0), c.y);
}
// License: WTFPL, author: sam hocevar, found: https://stackoverflow.com/a/17897228/418488
//  Macro version of above to enable compile-time constants
#define HSV2RGB(c)  (c.z * mix(hsv2rgb_K.xxx, clamp(abs(fract(c.xxx + hsv2rgb_K.xyz) * 6.0 - hsv2rgb_K.www) - hsv2rgb_K.xxx, 0.0, 1.0), c.y))

vec3 band_color(float ny) {
  vec3 hsv = vec3(0.0);
  float ramp = 1.0/abs(ny);
  if (abs(ny) < 4.0) {
    hsv = vec3(0.0, 0.0, 0.);
  } else if (ny > 0.0) {
    hsv = vec3(0.88, 2.5*ramp,0.8);
  } else {
    hsv = vec3(0.53, 4.0*ramp, 0.8);
  }

  return hsv2rgb(hsv);
}

// License: MIT, author: Inigo Quilez, found: https://iquilezles.org/www/articles/distfunctions2d/distfunctions2d.htm
float box(vec2 p, vec2 b, vec4 r) {
  r.xy = (p.x>0.0)?r.xy : r.zw;
  r.x  = (p.y>0.0)?r.x  : r.y;
  vec2 q = abs(p)-b+r.x;
  return min(max(q.x,q.y),0.0) + length(max(q,0.0)) - r.x;
}

float fadeIn(float x) {
  return mix(-0.1, 1.0, smoothstep(-0.9, -0.5, -cos(-0.1*x+TAU*TIME/PERIOD)));
}

float df_bars1(vec3 p) {
  p.y += dist*sin(0.5*p.x+0.5*p.z+TIME);
  vec2 bp = p.zy;
  
  float d = 1E6;

  float bs = 0.25*fadeIn(p.x);
  vec2 bsz = vec2(bs);
  vec4 brd = vec4(bs*rounding);

  for (int i = 0; i < bars; ++i) {
    float ii = float(i);
    vec2 pp = bp;
    float a = -TIME+0.5*ii;
    float b = ii+p.x-2.0*TIME;
    pp.y += sin(a);
    mat2 rot = ROT(-PI/4.0*cos(a+twist*b));
    pp.x -= bsz.x*sqrt(2.0)*ii; 
    pp *= rot;
    float dd = box(pp, bsz, brd);
    if (dd < d) {
      g_hit = i;
      d = dd;
    }
  }
  
  return d; 
}

float df_bars2(vec3 p) {
  p.y += 0.5*dist*sin(-0.9*p.x+TIME);
  vec2 p2 = p.yz;
  p2 *= ROT(TIME+p.x);  
  vec2 s2 = sign(p2);
  p2 = abs(p2);
  p2 -= 0.3;
  g_hit = 3+int(s2.y+2.0*s2.x)-1;
  float bs = 0.25*fadeIn(p.x);
  vec2 bsz = vec2(bs);
  vec4 brd = vec4(bs*rounding);
  return length(p2)-bs;
}

float df_bars3(vec3 p) {
  const float r = 0.25;
  p.y += 0.5*dist*sin(-0.9*p.x+TIME);
  mat2 rot = ROT(TIME+p.x);
  vec2 p2 = p.yz;
  vec2 s2 = vec2(0.0);

  p2 *= rot;
  s2 += 2.0*sign(p2);
  p2 = abs(p2);
  p2 -= 2.0*r;

  p2 *= rot;
  s2 += 1.0*sign(p2);
  p2 = abs(p2);
  p2 -= 1.0*r;

  g_hit = 3+int(s2.y+2.0*s2.x)-1;

  float bs = (0.9*r)*fadeIn(p.x);
  vec2 bsz = vec2(bs);
  vec4 brd = vec4(bs*rounding);
  float d0 = length(p2)-bs;
  float d1 = box(p2, bsz, brd);
  float d = d0;
  return d;
}

float df_bars4(vec3 p) {
  p.y += 0.5*dist*sin(-0.9*p.x+TIME);
  vec2 p2 = p.yz;
  p2 *= ROT(TIME+p.x);  
  vec2 s2 = sign(p2);
  p2 = abs(p2);
  p2 -= 0.3;
  g_hit = 3+int(s2.y+2.0*s2.x)-1;

  float bs = 0.25*fadeIn(p.x);

  vec2 bsz = vec2(bs);
  vec4 brd = vec4(bs*rounding);
  return box(p2, bsz, brd);
}

float df(vec3 p) {
  p.xy *= trans;
  switch(g_period) {
  case 0:
    return df_bars1(p);
  case 1:
    return df_bars2(p);
  case 2:
    return df_bars3(p);
  case 3:
    return df_bars4(p);
  default:
    return length(p) - 0.5;
  }
}

float rayMarch(vec3 ro, vec3 rd, float ti) {
  float t = ti;
  int i = 0;
  vec2 dti = vec2(1e10,0.0);
  for (i = 0; i < MAX_RAY_MARCHES; i++) {
    float d = df(ro + rd*t);
    if (d < TOLERANCE || t > MAX_RAY_LENGTH) break;
    if (d<dti.x) { dti=vec2(d,t); }
    t += raymarchFactor*d;
  }
  if(i==MAX_RAY_MARCHES) { t=dti.y; }
  return t;
}

vec3 normal(vec3 pos) {
  vec2  eps = vec2(NORM_OFF,0.0);
  vec3 nor;
  nor.x = df(pos+eps.xyy) - df(pos-eps.xyy);
  nor.y = df(pos+eps.yxy) - df(pos-eps.yxy);
  nor.z = df(pos+eps.yyx) - df(pos-eps.yyx);
  return normalize(nor);
}

const vec3 lightPos = vec3(2.0, 3.0, -5.0); 
const vec3 lightCol = vec3(HSV2RGB(vec3(0.53, 0.5, 1.0)));
const vec3 overCol  = vec3(HSV2RGB(vec3(0.88, 0.25, 0.8)));

vec3 skyColor(vec3 ro, vec3 rd) {
  vec3  ld    = normalize(lightPos - ro);
  float dif   = max(dot(ld, rd), 0.0);

  vec3  col   = vec3(0.0);

  if ((rd.y > abs(rd.x)*1.0) && (rd.y > abs(rd.z*0.25))) { 
    col = 2.0*overCol*rd.y;
  }
  float rb = length(max(abs(rd.xz/max(0.0,rd.y))-vec2(0.9, 4.0),0.0))-0.1;

  col += overCol*pow(clamp(1.0 - rb*0.5, 0.0, 1.0), 6.0);
  col += lightCol*pow(dif, 8.0);
  col += 4.0*lightCol*pow(dif, 40.0);
  return col;
}

vec3 effect(vec2 p) {
  vec3 ro = vec3(0.0, 0.0, -5.0);
  vec3 la = vec3(0.0, 0.0, 0.0);
  vec3 ww = normalize(la-ro);
  vec3 uu = normalize(cross(vec3(0.0,1.0,0.0), ww ));
  vec3 vv = normalize(cross(ww,uu));
  const float fov = 3.0;
  vec3 rd = normalize(-p.x*uu + p.y*vv + fov*ww );

  g_hit = -1;
  float t = rayMarch(ro, rd, 3.0);
  int hit = g_hit;
  
  vec3 col = vec3(1.0);
  vec3 bcol = band_color(-4.0*float(hit-(bars-1)/2));
  bcol *= bcol;
  if (t < MAX_RAY_LENGTH) {
    vec3 p = ro + rd*t;
    vec3 n = normal(p);
    vec3 r = reflect(rd, n);
    vec3 ld= normalize(lightPos-p);
  
    float dif = max(dot(ld, n), 0.0);
    col = bcol*mix(0.5, 1.0, dif);
#ifdef SKYDOME    
    vec3 rs= skyColor(p, r);
    float fre = 1.0+dot(rd, n);
    fre *= fre;
    float rf  = mix(0.05, 1.0, fre);
    col += rf*rs;
    // Just some fine-tuning, don't judge me
    col += smoothstep(0.5, 1.0, fre)*max(n.y, 0.0);
#else   
    float spe = pow(max(dot(ld, r), 0.0), 30.0);
    col += spe;
#endif    
  }
  
  return col;
}


void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
  vec2 q = fragCoord/RESOLUTION.xy;
  vec2 p  = -1. + 2. * q;
  p.x     *= RESOLUTION.x/RESOLUTION.y;
  g_period = int(mod(1.0+floor(TIME/PERIOD), 4.0));

  vec3 col  = effect(p);
#if defined(COLORBURN)  
  col -= vec3(0.2, 0.3, 0.2);
#endif  
  col = clamp(col, 0.0, 1.0);
  col = sqrt(col);
  fragColor = vec4(col, 1.0);
}

