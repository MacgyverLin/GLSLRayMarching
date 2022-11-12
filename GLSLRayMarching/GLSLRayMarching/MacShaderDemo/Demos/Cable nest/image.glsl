// License CC0: Cable nest
//  Result after a few hours programming sunday afternoon
#define TOLERANCE       0.0001
#define NORMTOL         0.00125
#define MAX_RAY_LENGTH  20.0
#define MAX_RAY_MARCHES 90
#define TIME            iTime
#define RESOLUTION      iResolution
#define ROT(a)          mat2(cos(a), sin(a), -sin(a), cos(a))
#define PI              3.141592654
#define TAU             (2.0*PI)

// https://stackoverflow.com/a/17897228/418488
const vec4 hsv2rgb_K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
vec3 hsv2rgb(vec3 c) {
  vec3 p = abs(fract(c.xxx + hsv2rgb_K.xyz) * 6.0 - hsv2rgb_K.www);
  return c.z * mix(hsv2rgb_K.xxx, clamp(p - hsv2rgb_K.xxx, 0.0, 1.0), c.y);
}
#define HSV2RGB(c)  (c.z * mix(hsv2rgb_K.xxx, clamp(abs(fract(c.xxx + hsv2rgb_K.xyz) * 6.0 - hsv2rgb_K.www) - hsv2rgb_K.xxx, 0.0, 1.0), c.y))

#define PATHA vec2(0.1147, 0.2093)
#define PATHB vec2(13.0, 3.0)

const float cam_amp = 1.0;

vec4 g_state = vec4(0.0);

float tanh_approx(float x) {
//  return tanh(x);
  float x2 = x*x;
  return clamp(x*(27.0 + x2)/(27.0+9.0*x2), -1.0, 1.0);
}

// https://iquilezles.org/articles/spherefunctions
float sphered(vec3 ro, vec3 rd, vec4 sph, float dbuffer) {
    float ndbuffer = dbuffer/sph.w;
    vec3  rc = (ro - sph.xyz)/sph.w;
  
    float b = dot(rd,rc);
    float c = dot(rc,rc) - 1.0;
    float h = b*b - c;
    if( h<0.0 ) return 0.0;
    h = sqrt( h );
    float t1 = -b - h;
    float t2 = -b + h;

    if( t2<0.0 || t1>ndbuffer ) return 0.0;
    t1 = max( t1, 0.0 );
    t2 = min( t2, ndbuffer );

    float i1 = -(c*t1 + b*t1*t1 + t1*t1*t1/3.0);
    float i2 = -(c*t2 + b*t2*t2 + t2*t2*t2/3.0);
    return (i2-i1)*(3.0/4.0);
}

float hash(float co) {
  return fract(sin(co*12.9898) * 13758.5453);
}

vec3 cam_path(float z) {
  return vec3(cam_amp*sin(z*PATHA)*PATHB, z);
}

vec3 dcam_path(float z) {
  return vec3(cam_amp*PATHA*PATHB*cos(PATHA*z), 1.0);
}

vec3 ddcam_path(float z) {
  return cam_amp*vec3(cam_amp*-PATHA*PATHA*PATHB*sin(PATHA*z), 0.0);
}

float df(vec3 p3, out vec4 state) {
  float cylr = 0.2;
  vec2 p = p3.xy;
  float t = p3.z;
  
  const float ss = 1.5;
  mat2 pp = ss*ROT(1.0+0.5*p3.z);

  p *= ROT(-0.2*TIME);
  float s = 1.0;
  
  float d = 1E6;
  float tt = 0.0;
  for (int i = 0; i < 3; ++i) {
    tt += sqrt(2.0)*float(1+i);
    p *= pp;
    vec2 sp = sign(p);
    p = abs(p);
    tt += dot(sp, vec2(0.25, 0.5))*s;
    p -= 1.35*s;
    s *= 1.0/ss;
    
    float dd = (length(p-vec2(0.0))-cylr)*s;
    if (dd < d) {
      d = dd;
      state = vec4(p, t, hash(tt+123.4));
    }
    
  }
  
  return d;
}

float df(vec3 p) {
  // Found this world warping technique somewhere but forgot which shader :(
  vec3 cam = cam_path(p.z);
  vec3 dcam = normalize(dcam_path(p.z));
  p.xy -= cam.xy;
  p -= dcam*dot(vec3(p.xy, 0), dcam)*0.5*vec3(1,1,-1);
  vec4 state;
  float d = df(p, state);
  
  g_state = state;
  
  return d; 
} 

float rayMarch(in vec3 ro, in vec3 rd, out int iter) {
  float t = 0.0;
  int i = 0;
  for (i = 0; i < MAX_RAY_MARCHES; i++) {
    float distance = df(ro + rd*t);
    if (distance < TOLERANCE || t > MAX_RAY_LENGTH) break;
    t += distance;
  }
  iter = i;
  return t;
}

vec3 normal(in vec3 pos) {
  vec3  eps = vec3(NORMTOL,0.0,0.0);
  vec3 nor;
  nor.x = df(pos+eps.xyy) - df(pos-eps.xyy);
  nor.y = df(pos+eps.yxy) - df(pos-eps.yxy);
  nor.z = df(pos+eps.yyx) - df(pos-eps.yyx);
  return normalize(nor);
}

float softShadow(in vec3 pos, in vec3 ld, in float ll, float mint, float k) {
  const float minShadow = 0.25;
  float res = 1.0;
  float t = mint;
  for (int i=0; i<25; ++i) {
    float distance = df(pos + ld*t);
    res = min(res, k*distance/t);
    if (ll <= t) break;
    if(res <= minShadow) break;
    t += max(mint*0.2, distance);
  }
  return clamp(res,minShadow,1.0);
}

vec3 postProcess(in vec3 col, in vec2 q)  {
  col=pow(clamp(col,0.0,1.0),vec3(1.0/2.2)); 
  col=col*0.6+0.4*col*col*(3.0-2.0*col);  // contrast
  col=mix(col, vec3(dot(col, vec3(0.33))), -0.4);  // satuation
  col*=0.5+0.5*pow(19.0*q.x*q.y*(1.0-q.x)*(1.0-q.y),0.7);  // vigneting
  return col;
}

vec3 render(vec3 ro, vec3 rd) {
  vec3 lightPos0  = cam_path(TIME-0.5);
  vec3 lightPos1  = cam_path(TIME+6.5);

  vec3 skyCol = vec3(0.0);

  int iter = 0;
  float t = rayMarch(ro, rd, iter);
  vec4 state = g_state;

  float tt = float(iter)/float(MAX_RAY_MARCHES);
  float bs = 1.0-tt*tt*tt*tt;
 
  vec3 pos = ro + t*rd;    
  
  float lsd1  = sphered(ro, rd, vec4(lightPos1, 2.5), t);
  float beat  = smoothstep(0.25, 1.0, sin(TAU*TIME*120.0/60.0));
  vec3 bcol   = mix(1.5*vec3(2.25, 0.75, 0.5), 3.5*vec3(2.0, 1.0, 0.75), beat);
  vec3 gcol   = lsd1*bcol;

  if (t >= MAX_RAY_LENGTH) {
    return skyCol+gcol;
  }
  
  vec3 nor    = normal(pos);

  float sa    = atan(state.y, state.x)+4.0*state.z*(0.5+0.5*state.w);
  float v     = 0.9*smoothstep(-0.1, 0.1, sin(4.0*sa));
  vec3 color  = hsv2rgb(vec3(0.0+123.4*state.w, 0.66, 0.75*v));
  
  vec3 lv0    = lightPos0 - pos;
  float ll20  = dot(lv0, lv0);
  float ll0   = sqrt(ll20);
  vec3 ld0    = lv0 / ll0;
  float dm0   = 8.0/ll20;
  float sha0  = softShadow(pos, ld0, ll0, 0.125, 32.0);
  float dif0  = max(dot(nor,ld0),0.0)*dm0;

  vec3 lv1    = lightPos1 - pos;
  float ll21  = dot(lv1, lv1);
  float ll1   = sqrt(ll21);
  vec3 ld1    = lv1 / ll1;
  float spe1  = pow(max(dot(reflect(ld1, nor), rd), 0.), 100.)*tanh_approx(3.0/ll21);

  vec3 col = vec3(0.0);
  col += dif0*sha0*color;
  col += spe1*bcol*bs;
  col += gcol;

  return col;
}

vec3 effect3d(vec2 p) {
  float tm = TIME;
  vec3 cam  = cam_path(tm);
  vec3 dcam = dcam_path(tm);
  vec3 ddcam= ddcam_path(tm);

  vec3 ro = cam;
  vec3 ww = normalize(dcam);
  vec3 uu = normalize(cross(vec3(0.0,1.0,0.0)+ddcam*-2.0, ww ));
  vec3 vv = normalize(cross(ww,uu));
  float rdd = (2.0+0.5*tanh_approx(length(p)));
  vec3 rd = normalize(p.x*uu + p.y*vv + rdd*ww);

  vec3 col = render(ro, rd);
  return col;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
  vec2 q=fragCoord.xy/RESOLUTION.xy; 
  vec2 p = -1.0 + 2.0*q;
  p.x *= RESOLUTION.x/RESOLUTION.y;

  vec3 col = effect3d(p);

  fragColor = vec4(postProcess(col, q),1.0);
}
