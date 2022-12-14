/**
    License: Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License
    
    Polygon Landsacpes
    9/13/21 @byt3_m3chanic
    
    Putting stuff on the ground and making it look half 
    way natural is hard, beginning experiments with it.
    
    need better noise functions...
    
    Rock shape/object from @gaz https://twitter.com/gaziya5/status/1436924535463309318

*/

#define R   iResolution
#define M   iMouse
#define T   iTime
#define PI  3.14159265359
#define PI2 6.28318530718

#define MAX_DIST    65.
#define MIN_DIST    .0005

mat2 rot(float a) { return mat2(cos(a),sin(a),-sin(a),cos(a)); }

float hash21(vec2 p) {
    // @Dave_Hoskins - Hash without sine
    // but it's HEAVY compile time / sadly and it looks better..
    // so using other low cost hash for now..
    
	//vec3 p3  = fract(vec3(p.xyx) * .1031);
    //p3 += dot(p3, p3.yzx + 33.33);
    //return fract((p3.x + p3.y) * p3.z);
    return fract(sin(dot(p,vec2(23.86,48.32)))*4374.432); 
}

float noise (in vec2 uv) {
    // @morgan3d https://www.shadertoy.com/view/4dS3Wd
    vec2 i = floor(uv);
    vec2 f = fract(uv);
    float a = hash21(i);
    float b = hash21(i + vec2(1., 0.));
    float c = hash21(i + vec2(0., 1.));
    float d = hash21(i + vec2(1., 1.));
    vec2 u = f;// * f * (3.-2.*f);  @Shane's tip for polygonized look..
    return mix(a, b, u.x) + (c - a)* u.y * (1. - u.x) + (d - b)* u.x * u.y;
}

//generate terrain using above noise algorithm
float fbm( vec2 p, float freq ) {	
	float h = -1.5;
	float w = 2.50;
	float m = 0.25;
	for (float i = 0.; i < freq; i++) {
		h += w * noise((p * m));
		w *= 0.5; m *= 2.0;
	}
	return h;
}

float gaz( vec3 p, float s) {
    float e = abs(p.x+p.y)+abs(p.y+p.z)+abs(p.z+p.x)+abs(p.x-p.y)+abs(p.y-p.z)+abs(p.z-p.x)-s;
    return e/3.5;
}

float zag(vec3 p, float s) {
    p = abs(p)-s;
    if (p.x < p.z) p.xz = p.zx;
    if (p.y < p.z) p.yz = p.zy;
    if (p.x < p.y) p.xy = p.yx;
    return dot(p,normalize(vec3(s*.42,s,0)));
}

float box(vec3 p, vec3 b ) {
    vec3 q = abs(p) - b;
    return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}

//http://mercury.sexy/hg_sdf/
const float angle = 2.*PI/6.;
const float hfang = angle*.5;
void mpolar(inout vec2 p) {
    float a = atan(p.y, p.x) + hfang;
    float c = floor(a/angle);
    a = mod(a,angle) - hfang;
    p = vec2(cos(a), sin(a))*length(p);
} 

//globals
vec3 hitPoint,hit;
vec2 gid,sid;
float mvt = 0.,snh,gnh;
mat2 turn,wts;

const float sz = .325;
const float hf = sz*.5;
const float db = sz *2.;
const float detail = 4.;
const float pwr = 1.75;

vec2 map(vec3 p) {
	vec2 res = vec2(1e5,0.);
    p.y+=4.;
    p.x+=mvt;
    float ter = fbm(p.xz*sz,detail)*pwr;
    float d2 = p.y - ter;
    
    if(d2<res.x) {
       res = vec2(d2,2.);
       hit=p;
       gnh=ter;
    }

    vec2 id = floor(p.xz*sz) + .5;    
    vec2 r = p.xz - id/sz;
    vec3 q = vec3(r.x,p.y,r.y);
    float hs = hash21(id);
    float xtr = fbm(id,detail)*pwr;
    vec3 qq=q-vec3(0,xtr+.2,0);

    mat2 htn = rot(-hs*PI2);
    qq.yz*= htn;
    qq.xz*= htn;

    float df = gaz(qq,4.5*hs*hs);
    if(df<res.x && hs>.5 && xtr>1.75) {
        res=vec2(df,3.);
        hit=p;
        gnh=xtr;
        gid=id;
    }
    
    float zz = 1.25;
    vec2 fid = floor(p.xz*zz) + .5;    
    vec2 fr = p.xz - fid/zz;
    vec3 fq = vec3(fr.x,p.y,fr.y);
    
    hs = hash21(fid);
    qq=fq-vec3(0,ter+.001,0);

    mpolar(qq.xz);      
    float adjust = sin(qq.x*12.);
    float flwr= box(qq,vec3(.3,smoothstep(.01,.35,.035*adjust),.035*adjust));
    if(flwr<res.x && hs<.1 ) {
        res=vec2(flwr,4.);
        hit=qq;
        gnh=ter;
        gid=fid;
    }

    float cells = 8.;
    vec3 qz = p-vec3(mvt,7.25,0);
    qz.xz*=turn;
    // Polar Repetion 
    // @Shane showed me this in one of my first
    // shaders!
    float a = atan(qz.z, qz.x);
    float ia = floor(a/6.2831853*cells);
    ia = (ia + .5)/cells*6.2831853;

    float ws = -mod(ia,.0);
    float cy = sin( ws*4. + (T * .25) * PI) * 1.5;
    qz.y +=cy;

    qz.xz *= rot(ia);
    qz.x -= 6.5;
  
    wts = rot(ws+T);
    qz.zy*=wts;
    qz.xz*=wts;

    float dx = zag(qz,.25);
    if(dx<res.x) {
        res=vec2(dx,5.);
        hit=qz;
        gnh=ws;
    }
    
    return res;
}

// normal
vec3 normal(vec3 p, float t) {
    float e = MIN_DIST*t;
    vec2 h = vec2(1.0,-1.0)*0.5773;
    return normalize( 
        h.xyy*map( p + h.xyy*e ).x + 
        h.yyx*map( p + h.yyx*e ).x + 
        h.yxy*map( p + h.yxy*e ).x + 
        h.xxx*map( p + h.xxx*e ).x );
}

vec3 vor3D(in vec3 p, in vec3 n ){
    n = max(abs(n), MIN_DIST);
    n /= dot(n, vec3(1));
	float tx = hash21(floor(p.xy));
    float ty = hash21(floor(p.zx));
    float tz = hash21(floor(p.yz));
    return vec3(tx*tx, ty*ty, tz*tz)*n;
}

vec3 glintz( vec3 lcol, vec3 pos, vec3 n, vec3 rd, vec3 lpos, float fresnel) {
    vec3 mate = vec3(0);
    vec3 h = normalize(lpos-rd);
    float nh = abs(dot(n,h)), nl = dot(n,lpos);
    vec3 light = lcol*max(.0,nl)*1.5;
    vec3 coord = pos*1.5, coord2 = coord;

    vec3 ww = fwidth(pos);
    vec3 glints=vec3(0);
    vec3 tcoord;
    float pw,q,anisotropy;
 
    //build layers
    for(int i = 0; i < 2;i++) {

        if( i==0 ) {
            anisotropy=.55;
            pw=R.x*.20;
            tcoord=coord;
        } else {
            anisotropy=.62;
            pw=R.x*.10;
            tcoord=coord2;
        }
        
        vec3 aniso = vec3(vor3D(tcoord.zyx*pw,n).yy, vor3D(tcoord.xyz*vec3(pw,-pw,-pw),n).y)*1.0-.5;
        if(i==0) {
            aniso -= n*dot(aniso,n);
            aniso /= min(1.,length(aniso));
        }

        float ah = abs(dot(h,aniso));
 
        if( i==0 ) {
            q = exp2((1.15-anisotropy)*2.5);
            nh = pow( nh, q*4.);
            nh *= pow( 1.-ah*anisotropy, 10.);
        } else {
            q = exp2((.1-anisotropy)*3.5);
            nh = pow( nh, q*.4);
            nh *= pow( 1.-ah*anisotropy, 150.);
        }     

        glints += (lcol*nh*exp2(((i==0?1.25:1.)-anisotropy)*1.3))*smoothstep(.0,.5,nl);
    }
    return  mix(light*vec3(0.3), vec3(.05), fresnel) + glints + lcol * .3;
}

// compact sky based on 
// @Shane https://www.shadertoy.com/view/WdtBzn
vec3 ACESFilm(in vec3 x) { return clamp((x*(.6275*x+.015))/(x*(.6075*x+.295)+.14),0.,1.); }

vec3 getSky(vec3 ro, vec3 rd, vec3 ld, float ison) { 
    rd.y+=.2;
    rd.z *= .95 - length(rd.xy)*.5;
    rd = normalize(rd);

    vec3 Rayleigh = vec3(1), Mie = vec3(1); 
    // rayleigh / mie
    vec3 betaR = vec3(5.8e-2, 1.35e-1, 3.31e-1), betaM = vec3(4e-2); 
    float zAng = max(2e-6, rd.y);
    // scatter - Klassen's model.
    vec3 extinction = exp(-(betaR*1. + betaM*1.)/zAng);	
    vec3 col = 2.*(1. - extinction);
    // dist clouds
    float t = (1e5 - ro.y - .15)/(rd.y + .45);
    vec2 uv = (ro + t*rd).xz;
	if(t>0.&&ison>0.) {
        col = mix(col, vec3(3), smoothstep(1.,.475,  fbm(5.*uv/1e5,5.))*
                                smoothstep(.15, .85, rd.y*.5 + .5)*.4);  
    }

    return clamp(ACESFilm(col), 0., 1.);
} 

vec3 sky = vec3(0);

vec3 hue(float a, float b, float c) {
    return b+c*cos(PI2*a*(vec3(1.25,.5,.25)*vec3(.99,.97,.96))); 
}

vec4 render(inout vec3 ro, inout vec3 rd, inout vec3 ref, bool last, inout float d) {

    vec3 sky = getSky(ro,rd,vec3(.0,.02,1.01),1.);
    vec3 C = vec3(0);

    float  m = 0.;
    vec3 p = ro;
    for (int i = 0; i<128;i++) {
     	p = ro + rd * d;
        vec2 ray = map(p);
        if(abs(ray.x)<d*MIN_DIST || d>MAX_DIST)break;
        d += i<32 ? ray.x*.25 : ray.x*.75; 
        m = ray.y;
    }
    
    hitPoint=hit;
    sid=gid;
    snh=gnh;
    float alpha = 0.;
    
    if(d<MAX_DIST){
      	vec3 n = normal(p, d);
        
        vec3 lpos = vec3(-11.,15,18.);
        vec3 l = normalize(lpos-p);    
        float diff = clamp(dot(n,l),0.,1.);
        float shdw = 1., t = .01;

        for(int i=0; i<24; i++){
            float h = map(p + l*t).x;
            if( h<MIN_DIST ) {shdw = 0.; break;}
            shdw = min(shdw, 14.*h/t);
            t += h * .8;
            if( shdw<MIN_DIST || t>32. ) break;
        }
        diff = mix(diff,diff*shdw,.65);

        float fresnel = pow(1.0 + dot(n,rd), 2.0);
        fresnel = mix( 0.0, 0.95, fresnel );
        
        vec3 view = normalize(p - ro);
        vec3 ret = reflect(normalize(lpos), n);
        float spec = 0.5 * pow(max(dot(view, ret), 0.), 24.);

        ref=vec3(.0);
        vec3 h = vec3(.5);
        
        if(m==2.) {
            vec3 c = mix(vec3(0.647,0.573,0.192),vec3(0.082,0.459,0.145),clamp(.1+snh*.5,0.,1.));
            h = glintz(c, hitPoint*.05, n, rd, l, fresnel);
        }
        if(m==3.) {
            h = clamp(hue((snh+fresnel)*3.25,.80,.15)*.85,vec3(.1),vec3(1.));
            ref = h-fresnel;
        }
        if(m==4.) {    
            h = vec3(0.329,0.580,0.020);
            ref = h-fresnel;
        }
        if(m==5.) {    
            h = vec3(0.286+fresnel,0.576+fresnel,0.953);//hue((snh+fresnel)*3.25,.65,.35);
            ref = h-fresnel;
        }
        C += h * diff+spec;
        C = mix(vec3(0.392,0.502,0.565),C,  exp(-.000015*d*d*d));

        ro = p+n*.005;
        rd = reflect(rd,n);
       
    } else {
        C = sky;
    }
    
    C=clamp(C,vec3(.03),vec3(1.));
    return vec4(C,alpha);
}

void mainImage( out vec4 O, in vec2 F ) {
    // precal
    mvt= 280.;//+T*.733;
    turn = rot(T*.2);
    
    vec2 uv = (2.*F.xy-R.xy)/max(R.x,R.y);
    float sf = .5*sin(T*.1);
    vec3 ro = vec3(0,1.65,13.+sf);
    vec3 rd = normalize(vec3(uv,-1));

    // mouse
    float x = M.xy == vec2(0) ? .0 : .07+(M.y/R.y * .0625 - .03125) * PI;
    float y = M.xy == vec2(0) ? .0 : -(M.x/R.x * .5 - .25) * PI;
    float sx = .3*cos(T*.1);
    mat2 rx = rot(x), ry=rot(y+sx);
    ro.yz *= rx; ro.xz *= ry;
    rd.yz *= rx; rd.xz *= ry;
    
    // sky and vars
    sky = getSky(ro,rd,vec3(.0,.02,1.01),1.);
    vec3 C = vec3(0);
    vec3 ref=vec3(0);
    vec3 fill=vec3(1.);
    
    // ref loop @BigWIngs
    float d =0.;
    float a =0.;
    for(float i=0.; i<2.; i++) {
        vec4 pass = render(ro, rd, ref, i==2.-1., d);
        C += pass.rgb*fill;
        fill*=ref;
        if(i==0.)a=d;
    }

    C = mix(sky,C, exp(-.000015*a*a*a));
    C = pow(C, vec3(.4545));
    C = clamp(C,vec3(.03),vec3(1.));
    O = vec4(C,1.0);
}
// end
