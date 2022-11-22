//#define MORE_PRESICE_IMAGE

// Constants ----------
#define PI 3.14159265358979
#define P2 6.28318530717959

const int   MAX_TRACE_STEP = 90;
const float MAX_TRACE_DIST = 40.;
const float NO_HIT_DIST    = 100.;
const float TRACE_PRECISION = .001;
const float FUDGE_FACTOR = .9;
const vec3  GAMMA = vec3(1./2.2);

const float GI_LENGTH = 1.6;
const float GI_STRENGTH = 1.;
const float AO_STRENGTH = .4;
const int   SHADOW_MAX_TRACE_STEP = 4;
const float SHADOW_MAX_TRACE_DIST = 10.;
const float SHADOW_MIN_MARCHING = .4;
const float SHADOW_SHARPNESS = 1.;
const float CAUSTIC_STRENGTH = 1.6;
const float CAUSTIC_SHARPNESS = 4.;


// Structures ----------
struct Surface {
  float d;              // distance
  vec3  kd, tc, rl, rr; // diffusion, transparent-color, reflectance, refractance
};
Surface near(Surface s,Surface t) {if(s.d<t.d)return s;return t;}

struct Ray {
  vec3  org, dir, col; // origin, direction, color
  float len, stp, rr, sgn; // length, marching step, refractance, sign of distance function
};
Ray ray(vec3 o, vec3 d) { return Ray(o,d,vec3(1),0.,0.,1.,1.); }
Ray ray(vec3 o, vec3 d, vec3 c, float rr, float s) { return Ray(o,d,c,0.,0.,rr,s); }
vec3 _pos(Ray r) {return r.org+r.dir*r.len;}

struct Hit {
  vec3 pos,nml; // position, normal
  Ray ray;      // ray
  Surface srf;  // surface
  bool isTransparent;
  bool isReflect;
};
Hit nohit(Ray r) { return Hit(vec3(0), vec3(0), r, Surface(NO_HIT_DIST, vec3(1), vec3(0), vec3(0), vec3(0)), false, false); }

struct Camera {
  vec3 pos, tgt;  // position, target
  float rol, fcs; // roll, focal length
};
mat3 _mat3(Camera c) {
  vec3 w = normalize(c.pos-c.tgt);
  vec3 u = normalize(cross(w,vec3(sin(c.rol),cos(c.rol),0)));
  return mat3(u,normalize(cross(u,w)),w);
}

struct AABB { vec3 bmin, bmax;};
struct DLight { vec3 dir, col; };
vec3 _lit(vec3 n, DLight l){return clamp((dot(n, l.dir)+1.)*.5,0.,1.)*l.col;}


// Grobal valiables ----------
const float bpm = 144.;
const DLight dif1 = DLight(normalize(vec3(2,3,1)), vec3(2.69,2.67,2.61));
const DLight dif2 = DLight(normalize(vec3(3,3,0)), vec3(4.79,4.77,4.71));
const DLight dif3 = DLight(normalize(vec3(1,3,2)), vec3(6.89,6.87,6.81));
const DLight amb = DLight(vec3(0,-1,0), vec3(.7,1,2));
float phase;


// Utilities ----------
vec3  _rgb(vec3 hsv) { return normalize(((clamp(abs(fract(hsv.x+vec3(0,2,1)/3.)*2.-1.)*3.-1.,0.,1.)-1.)*hsv.y+1.)*hsv.z); }
mat3  _smat(vec2 a) { float x=cos(a.y),y=cos(a.x),z=sin(a.y),w=sin(a.x); return mat3(y,w*z,-w*x,0,x,z,w,-y*z,y*x); }
mat3  _pmat(vec3 a) {
  float sx=sin(a.x),sy=sin(a.y),sz=sin(a.z),cx=cos(a.x),cy=cos(a.y),cz=cos(a.z);
  return mat3(cz*cy,sz*cy,-sy,-sz*cx+cz*sy*sx,cz*cx+sz*sy*sx,cy*sx,sz*sx+cz*sy*cx,-cz*sx+sz*sy*cx,cy*cx);
}
float _checker(vec2 uv, vec2 csize) { return mod(floor(uv.x/csize.x)+floor(uv.y/csize.y),2.); }
float len2(vec3 v) { return dot(v,v); }
float smin(float a, float b, float k) { return -log(exp(-k*a)+exp(-k*b))/k; }
float smax(float a, float b, float k) { return log(exp(k*a)+exp(k*b))/k; }
float vmin(vec3 v) { return min(v.x, min(v.y, v.z)); }
float vmax(vec3 v) { return max(v.x, max(v.y, v.z)); }
vec2  cycl(float t, vec2 f, vec2 r) { return vec2(cos(t*f.x)*r.x+cos(t*f.y)*r.y,sin(t*f.x)*r.x+sin(t*f.y)*r.y); }
vec3  fresnel(vec3 f0, float dp) { return f0+(1.-f0)*pow(1.-abs(dp),5.); }
float rr2rl(float rr) { float v=(rr-1.)/(rr+1.); return v*v; }
float rand(vec2 co){ return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453); }

// Intersect functions ----------
vec2 hitAABB(Ray r, AABB b) { 
  vec3 t1=(b.bmin-r.org)/r.dir, t2=(b.bmax-r.org)/r.dir;
  return vec2(vmax(min(t1, t2)), vmin(max(t1, t2)));
}

float ifPln(Ray r, vec3 n, float d) {
  float v = -dot(r.dir, n), l;
  if (abs(v)<TRACE_PRECISION) return NO_HIT_DIST;
  return (0.<(l=dot(r.org-n*d, n)/v))?l:NO_HIT_DIST;
}

float ifSph(Ray r, vec3 c, float s) {
  vec3 A=r.org-c;
  float B=dot(A,r.dir),D=B*B+s*s-dot(A,A), l;
  if (D<0.) return NO_HIT_DIST;
  return (0.<(l=-B-sqrt(D)))?l:NO_HIT_DIST;
}

float ifBox(Ray r, vec3 b) {
  vec2 v=hitAABB(r,AABB(-b,b));
  return (0.<=v.y&&v.x<=v.y)?v.x:NO_HIT_DIST;
}

float ifTri(Ray r, vec3 v0, vec3 v1, vec3 v2) {
  vec3 a=v1-v0,b=v2-v0,t=r.org-v0,p=cross(r.dir,b),q=cross(t,a);
  float det=dot(a,p);
  if (abs(det)<TRACE_PRECISION) return NO_HIT_DIST;
  vec3 uvt=vec3(dot(p,t),dot(q,r.dir),dot(q,b))/det;
  return (0.<=uvt.x&&0.<=uvt.y&&uvt.x+uvt.y<=1.)?uvt.z:NO_HIT_DIST;
}


// Distance Functions ----------
float dfPln(vec3 p, vec3 n, float d) { return dot(p,n) + d; }
float dfBox(vec3 p, vec3 b, float r) { return length(max(abs(p)-b,0.))-r;}
float dfHex(vec3 p, vec2 h, float r) { vec3 q=abs(p); q.x=max(q.x*0.866025+q.z*0.5,q.z); return length(max(q.xy-h.xy,0.))-r; }
vec3 repXZ(vec3 p, vec2 r){ vec2 hr=r*.5; return vec3(mod(p.x+hr.x, r.x)-hr.x, p.y, mod(p.z+hr.y, r.y)-hr.y); }

const vec4 ddp = vec4(-.8506508,.8506508,.5257311,0);
float dfDdc(vec3 p, float r) {
  float dp0=abs(dot(p,ddp.wyz)),dp1=abs(dot(p,ddp.wxz)),dp2=abs(dot(p,ddp.zwy)),
        dp3=abs(dot(p,ddp.zwx)),dp4=abs(dot(p,ddp.yzw)),dp5=abs(dot(p,ddp.xzw));
  return max(vmax(vec3(dp0,dp1,dp2)),vmax(vec3(dp3,dp4,dp5)))-r;
}
float dfDdcr(vec3 p, float r, float e) {
  float dp0=abs(dot(p,ddp.wyz)),dp1=abs(dot(p,ddp.wxz)),dp2=abs(dot(p,ddp.zwy)),
        dp3=abs(dot(p,ddp.zwx)),dp4=abs(dot(p,ddp.yzw)),dp5=abs(dot(p,ddp.xzw));
  return log(exp(dp0*e)+exp(dp1*e)+exp(dp2*e)+exp(dp3*e)+exp(dp4*e)+exp(dp5*e))/e-r;
}

/*
float dfBC (in vec3 p, float r) {
  float angleStep = P2/8.;
  float crownAngle = radians(33.0);
  float pavilionAngle = radians(41.0);
  float tableArea = 0.58;
  float starArea  = 0.5;
  float starAngle = crownAngle * 0.640;
  float bezlAngle = crownAngle;
  float ugrdAngle = crownAngle * 1.209;
  float pavlAngle = pavilionAngle;
  float lgrdAngle = pavilionAngle * 1.049;

  vec3 vHlfStep = vec3(cos(angleStep/2.), 0, sin(angleStep/2.));
  vec3 vQrtStep = vec3(cos(angleStep/4.), 0, sin(angleStep/4.));

  float a = floor(atan(p.z,p.x)/angleStep+.5)*angleStep, c=cos(a), s=sin(a);
  mat3  m = mat3(c,0,s,  0,1,0,  -s,0,c) * r;
  vec3  q = inverse(m) * p;
  q.z = abs(q.z);

  vec3 nmlBezel = vec3(sin(bezlAngle), cos(bezlAngle),0);
  float fcBezel = dot(q, nmlBezel) -  sin(bezlAngle);
 
  vec3 nmlUGird = normalize(vec3(vQrtStep.x*sin(ugrdAngle),  cos(ugrdAngle)*vQrtStep.x, vQrtStep.z*sin(ugrdAngle)));
  vec3 nmlLGird = normalize(vec3(vQrtStep.x*sin(lgrdAngle), -cos(lgrdAngle)*vQrtStep.x, vQrtStep.z*sin(lgrdAngle)));
  float fcUGird = dot(q, nmlUGird) -  dot(nmlUGird, vQrtStep*vQrtStep.x);
  float fcLGird = dot(q, nmlLGird) -  dot(nmlLGird, vQrtStep*vQrtStep.x);

  vec3 nmlStar  = vec3(sin(starAngle)*vHlfStep.x,cos(starAngle),sin(starAngle)*vHlfStep.z);
  float starDst = (1.-tableArea) * (1.-starArea) * (tan(ugrdAngle)/tan(starAngle)-1.) + 1.;
  float fcStar  = dot(q, nmlStar) -  starDst * sin(starAngle);

  vec3 nmlPMain = vec3(sin(pavlAngle), -cos(pavlAngle),0);
  float fcPMain = dot(q, nmlPMain) -  sin(pavlAngle);

  float fcTable = q.y -  (1.-tableArea) * tan(bezlAngle);
  float fcCulet = - q.y -  tan(pavlAngle) * .96;
  float fcGirdl = length(q.xz) - .975;

  return max(fcGirdl, max(fcCulet, max(fcTable, max(fcBezel, max(fcStar, max(fcUGird, max(fcPMain,fcLGird)))))));
}
//*/

//*
float dfBC(in vec3 p, float r) {
  float a = floor(atan(p.z,p.x)/(PI*.25)+.5)*PI*.25, c = cos(a), s = sin(a);
  vec3  q = vec3(c*p.x+s*p.z, p.y, abs(-c*p.z+s*p.x)) / r;
  float fcBezel = dot(q, vec3(.544639035, .8386705679, 0))           - .544639035;
  float fcUGird = dot(q, vec3(.636291199, .7609957358, .1265661887)) - .636291199;
  float fcLGird = dot(q, vec3(.675808237,-.7247156073, .1344266163)) - .675808237;
  float fcStar  = dot(q, vec3(.332894535, .9328278154, .1378894313)) - .448447409;
  float fcPMain = dot(q, vec3(.656059029,-.7547095802, 0))           - .656059029;
  float fcTable =   q.y - .2727511892;
  float fcCulet = - q.y - .8692867378 * .96;  
  float fcGirdl = length(q.xz) - .975;
  return max(fcGirdl, max(fcCulet, max(fcTable, max(fcBezel, max(fcStar, max(fcUGird, max(fcPMain,fcLGird)))))));
}
//*/

vec3 repC_XZ(vec3 p, float r, int n){
  float t=P2/float(n),atn=(atan(p.z,p.x))/t+.5;
  float a=(fract(atn)-.5)*t,l=length(p.xz);
  return vec3(cos(a)*l-r, p.y, sin(a)*l);
}

float esBounce(float t) { t=(t-1./3.5)*3.5;return min(t*t,min((t-1.5)*(t-1.5)+.75,(t-2.25)*(t-2.25)+.9375)); }


// Sphere tracing ----------.
vec3 hmsUnit = vec3(12,60,60);
Surface map(vec3 p){
  vec3 now = mod(vec3(iDate.w)/vec3(3600,60,1),hmsUnit);
  vec3 idx = floor(mod(vec3(1.-atan(p.z,p.x)/P2)*hmsUnit-.5,hmsUnit));
  vec3 hmsFlag = clamp(now-idx,0.,1.);
  float s12 = clamp(mod(now.z/5.+6.,12.)-idx.x,0.,1.);

  vec3 hcol = _rgb(vec3(idx.x/12.,hmsFlag.x*.6,.9));
  vec3 mcol = _rgb(vec3(idx.y/60.,hmsFlag.y*.3,.9));
  float sm = mod(now.z-idx.y,60.), ism=1.-(sm-1.)/59.;
  vec2 sp = (sm<1.)?vec2(sm,esBounce(sm)):vec2((1.-cos(ism*PI))*.5,(3.+cos(ism*P2))*.25);
  vec3 spos = vec3(6.*sp.x,sp.y*2.8-3.0,0);
  vec3 ms = vec3((1.-hmsFlag.x)*((cos(s12*P2)+1.)*.45+.1),1.25-cos(s12*PI)*2.,0);

  if (iMouse.z > .5) {
    ms.xy = clamp(iMouse.yx/iResolution.yx*1.4-0.2,vec2(0),vec2(1));
    hcol = _rgb(vec3(idx.x/12.,.6,.9));
  }
  mat3 mat = _pmat(ms*PI*vec3(41./180.,2,1));
  vec3 ri = vec3(2.4,2.425,2.45);
  vec3 pos = vec3(2,1.0,2);
  vec3 fcl = textureLod(iChannel1,p.xz*0.1,0.).rgb*(_checker(p.xz,vec2(2.5))*.0625+.02);
  return near(
    Surface(dfBox(p-vec3(0,-.52,0), vec3(10,0,10), .5), fcl, vec3(0), vec3(.2), vec3(0)), 
    near(
      Surface(dfBC(repC_XZ(p,7.2,12)*mat+vec3(0,-.86,0), 1.0), vec3(0), hcol, vec3(rr2rl(ri.x)), ri),
      Surface(dfDdc(repC_XZ(p,9.5,60)+spos, 0.2), vec3(0), mcol, vec3(rr2rl(ri.x)), ri)
    )
//    Surface(dfBC(repC_XZ(p,8.,12)*m+vec3(5.,-.86,0), 1.0), col*.1, vec3(0), vec3(.9), ri)
  );
}

vec3 calcNormal(in vec3 p){
  vec3 v=vec3(.001,0,map(p).d);
  return normalize(vec3(map(p+v.xyy).d-v.z,map(p+v.yxy).d-v.z,map(p+v.yyx).d-v.z));
}


// Lighting ----------
vec4 cs(in vec3 pos, in vec3 dir) {
  vec4 col=vec4(0,0,0,1);
  float len=SHADOW_MIN_MARCHING;
  for( int i=0; i<SHADOW_MAX_TRACE_STEP; i++ ) {
    Surface s = map(pos + dir*len);
    col.a   = min(col.a, SHADOW_SHARPNESS*s.d/len);
    col.rgb = s.tc;
    len += max(s.d, SHADOW_MIN_MARCHING);
    if (s.d<TRACE_PRECISION || len>SHADOW_MAX_TRACE_DIST) break;
  }
  col.a = clamp(col.a, 0., 1.);
  col.rgb = pow((1.-col.a), CAUSTIC_SHARPNESS) * col.rgb * CAUSTIC_STRENGTH;
  return col;
}

vec4 gi(in vec3 pos, in vec3 nml) {
  vec4 col = vec4(0);
  for (int i=0; i<4; i++) {
    float hr = .01 + float(i) * GI_LENGTH / 4.;
    Surface s = map(nml * hr + pos);
    col += vec4(s.kd, 1.) * (hr - s.d);
  }
  col.rgb *= GI_STRENGTH / GI_LENGTH;
  col.w = clamp(1.-col.w * AO_STRENGTH / GI_LENGTH, 0., 1.);
  return col;
}

vec3 lighting(in Hit h) {
  if (h.ray.len > MAX_TRACE_DIST) return pow(textureLod(iChannel0, -h.ray.dir, 0.).rgb,vec3(0.4))*.25;
  vec4 fgi = gi(h.pos, h.nml);    // Fake Global Illumination
  vec4 fcs1 = cs(h.pos, dif1.dir);  // Fake Caustic Shadow
  vec4 fcs2 = cs(h.pos, dif2.dir);  // Fake Caustic Shadow
  vec4 fcs3 = cs(h.pos, dif3.dir);  // Fake Caustic Shadow
  //   lin = ([Ambient]        + [Diffuse]        * [SS] + [CAUSTICS]) * [AO] + [GI]
  vec3 lin = (_lit(h.nml, amb)
              + _lit(h.nml, dif1) * fcs1.w + fcs1.rgb
              + _lit(h.nml, dif2) * fcs2.w + fcs2.rgb
              + _lit(h.nml, dif3) * fcs3.w + fcs3.rgb) * fgi.w + fgi.rgb;
  return  h.srf.kd * lin;
}


// Ray ----------
Ray rayScreen(in vec2 p, in Camera c) {
  return ray(c.pos, normalize(_mat3(c) * vec3(p.xy, -c.fcs)));
}

Ray rayReflect(Hit h, vec3 rl) {
  return ray(h.pos + h.nml*.01, reflect(h.ray.dir, h.nml), h.ray.col*rl, h.ray.rr, h.ray.sgn);
}

Ray rayRefract(Hit h, float rr) {
  vec3 r = refract(h.ray.dir, h.nml, h.ray.rr/rr);
  if (len2(r)<.001) return ray(h.pos+h.nml*.01, reflect(h.ray.dir, h.nml), h.ray.col, h.ray.rr, h.ray.sgn);
  return ray(h.pos - h.nml*.01, r, h.ray.col*h.srf.tc, rr, -h.ray.sgn);
}


// renderer ----------
Hit sphereTrace(in Ray r) {
  Surface s;
  for(int i=0; i<MAX_TRACE_STEP; i++) {
    s = map(_pos(r));
    s.d *= r.sgn;
    r.len += s.d * FUDGE_FACTOR;
    r.stp = float(i);
    if (s.d < TRACE_PRECISION) break;
    if (r.len > MAX_TRACE_DIST) return nohit(r);
  }
  vec3 p = _pos(r);
  float interior = .5-r.sgn*.5;
  s.rr = mix(s.rr, vec3(1), interior);
  s.tc = max(s.tc, interior);
  return Hit(p, calcNormal(p)*r.sgn, r, s, (len2(s.tc)>.001), (len2(s.rl)>.001));
}

Hit trace(in Ray r) {
  return sphereTrace(r);
}

vec3 renderDiffusion(inout Hit h) {
  if (len2(h.srf.kd) < .001) return vec3(0);
  vec3 col = lighting(h) * h.ray.col;
  h.ray.col *= 1. - h.srf.kd;
  return col;
}

vec4 render(in Ray r){
  vec3 col = vec3(0), rl, c;
  Hit h0, h1;
  float l0;

  // first trace
  h0 = trace(r);
  l0 = h0.ray.len;

  // first diffusion surface
  col += renderDiffusion(h0);

  // first reflection
  h1 = h0;
  rl = fresnel(h0.srf.rl, dot(h0.ray.dir, h0.nml));
  h0.ray.col *= 1. - rl;
  if (h1.isReflect) { 
    h1 = trace(rayReflect(h1, rl));
    col += renderDiffusion(h1);
    if (!h0.isTransparent) h0 = h1;
  }

  // repeating trace
  for (int i=4; i!=0; --i) {
    if (!h0.isReflect) break;
    if (h0.isTransparent) 
      h0 = trace(rayRefract(h0, h0.srf.rr.x));
    else 
      h0 = trace(rayReflect(h0, fresnel(h0.srf.rl, dot(h0.ray.dir, h0.nml))));
    col += renderDiffusion(h0);
  }

  // cheap trick
  c = h0.ray.col;
  if (len2(c) >= .2) col += textureLod(iChannel0, -h0.ray.dir, 0.).rgb * c * c * 3.0;

  return vec4(col, l0);
}

vec4 gamma(in vec4 i) {
  return vec4(pow(i.xyz, GAMMA), i.w);
}


// Entry point ----------
void mainImage(out vec4 fragColor, in vec2 fragCoord) {
  phase = iTime * bpm / 60. * P2;

  vec2   m = vec2(cos(phase/128.), sin(phase/128.))*20.;
  Camera c = Camera(vec3(m.x,sin(phase/32.)*4.+6.,m.y), vec3(0), 0., 1.73205081);
  Ray    r = rayScreen((fragCoord.xy * 2. - iResolution.xy) / iResolution.x, c);

  vec4 res = render(r);
  res.w = min(abs(res.w - length(c.pos)+8.)/100., 1.);

  fragColor = (res);//gamma(res);
}
