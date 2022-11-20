// Created by EvilRyu
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

// 2018 shadertoy competition entry.
//
// 75 seconds for the whole animation
// 

#define PI 3.1415926535


float hash11(float a)
{
    return fract(sin(a)*10403.9);
}


float hash21(vec2 uv)
{
    float f=uv.x + uv.y * 37.0;
    return fract(sin(f)*104003.9);
}


vec2 hash22(vec2 uv)
{
    float f=uv.x + uv.y * 37.0;
    return fract(cos(f)*vec2(10003.579, 37049.7));
}


vec2 hash12(float f)
{
    return fract(cos(f)*vec2(10003.579, 37049.7));
}


float hash31(vec3 p)
{ 
    return fract(sin(dot(p, vec3(127.1, 311.7, 74.7)))*43758.5453); 
}


float noise(vec2 x)
{
    vec2 p=floor(x);
    vec2 f=fract(x);
    f=f*f*(3.0-2.0*f);
    float n=p.x + p.y*57.0;
    return mix(mix(hash11(n+0.0), hash11(n+1.0),f.x),
               mix(hash11(n+57.0), hash11(n+58.0),f.x),f.y);
}
const mat2 m=mat2(0.8,0.6,-0.6,0.8);


float fbm(vec2 p)
{
    float f=0.0;
    f+=0.50000*noise(p); p=m*p*2.02;
    f+=0.25000*noise(p); p=m*p*2.03;
    f+=0.12500*noise(p); p=m*p*2.01;
    f+=0.06250*noise(p); p=m*p*2.04;
    f+=0.03125*noise(p);
    return f/0.984375;
}


float smin(float a, float b, float k)
{
    float h=clamp(0.5 + 0.5*(b-a)/k, 0.0, 1.0);
    return mix(b, a, h) - k*h*(1.0-h);
}


float smax(float a, float b, float k)
{
    return smin(a, b, -k);
}


vec3 rot_x(vec3 p, float t)
{
    float co=cos(t);
    float si=sin(t);
    p.yz=mat2(co,-si,si,co)*p.yz;
    return p;
}

vec3 rot_y(vec3 p, float t)
{
    float co = cos(t);
    float si = sin(t);
    p.xz = mat2(co,-si,si,co)*p.xz;
    return p;
}

vec3 rot_z(vec3 p, float t)
{
    float co=cos(t);
    float si=sin(t);
    p.xy=mat2(co,-si,si,co)*p.xy;
    return p;
}


float mixp(float f0, float f1, float a)
{
    return mix(f0, f1, a*a*(3.0-2.0*a));
}


float sphere(vec3 p,float r)
{
    return length(p)-r;
}


float ellipsoid(vec3 p, vec3 c, vec3 r)
{
    p-=c;
    float d=length(p/r)-.5;
    return d*min(r.x,min(r.y,r.z));
}


float box(vec3 p, vec3 r)
{
  vec3 d=abs(p) - r;
  return min(max(d.x, max(d.y, d.z)), 0.0) + length(max(d, 0.0));
}


float rbox(vec3 p, vec3 b, float r)
{
  return length(max(abs(p)-b,0.0))-r;
}


vec2 line2(vec3 a, vec3 b, vec3 p, float ll)
{
    vec3 pa=p-a;
    vec3 ba=b-a;
    float h=clamp(dot(pa,ba)*ll, 0.0, 1.0);
    
    return vec2(length(pa-ba*h), h);
}


vec2 line(vec3 pos, in vec3 a, in vec3 b)
{
    vec3 pa=pos-a;
    vec3 ba=b-a;
   
    float h=clamp(dot(pa,ba)/dot(ba,ba), 0.0, 1.0);
    
    return vec2(length(pa-h*ba), h);
}


vec3 solve(vec3 p, float l1, float l2, vec3 dir)
{
    vec3 q=p*(0.5 + 0.5*(l1*l1-l2*l2)/dot(p,p));
    
    float s=l1*l1 - dot(q,q);
    s=max(s, 0.0);
    q += sqrt(s)*normalize(cross(p,dir));
    
    return q;

}


vec3 solve(vec3 a, vec3 b, float l1, float l2, vec3 dir)
{
    return a + solve(b-a, l1, l2, dir);
}


vec4 texcube(sampler2D sam, vec3 p, vec3 n)
{
    vec4 p1=texture(sam, p.xy);
    vec4 p2=texture(sam, p.xz);
    vec4 p3=texture(sam, p.yz);
    return p1*abs(n.z)+p2*abs(n.y)+p3*abs(n.x);
}


float bump(vec3 p, vec3 n)
{
    return dot(texcube(iChannel0, 0.25*p, n).xyz, vec3(0.299, 0.587, 0.114)); 
}


vec3 bump_mapping(vec3 p, vec3 n, float weight)
{
    vec2 e=vec2(2./iResolution.y, 0); 
    vec3 g=vec3(bump(p-e.xyy, n)-bump(p+e.xyy, n),
                bump(p-e.yxy, n)-bump(p+e.yxy, n),
                bump(p-e.yyx, n)-bump(p+e.yyx, n))/(e.x*2.);  
    g=(g-n*dot(g,n));
    return normalize(n+g*weight);
}

struct Spider
{
    vec3 pos;
    vec3 forward;
    vec3 knees[6];
    vec3 feet[6];
};

    
Spider spider;

#define MAT_AB 0.0
#define MAT_LEGS 1.0
#define MAT_BODY 2.0
#define MAT_EYES 3.0
#define MAT_SPIDER_EYEHOLE 4.
#define MAT_OTHERS 5.0

#define BREATH (0.08*sin(4.*iTime))
#define BREATH_FREQ 4.0
#define SPIDER_EYEPOS vec3(0.,2.75,0.45)

vec3 get_spider_coord(vec3 p)
{
    vec3 u=vec3(1.0,0.0,0.0);
    vec3 v=normalize(cross(spider.forward,u));

    return vec3(p.x, dot(v,p), dot(spider.forward,p));
}

// from spider coord
vec3 get_world_coord(vec3 p)
{
    vec3 u=vec3(1.,0.,0.);
    vec3 v=normalize(cross(spider.forward,u));
    vec3 f=spider.forward;
    return vec3(u*p.x+v*p.y+f*p.z);
}

vec2 body(vec3 q)
{    
    float matid=MAT_BODY;
    // body
    float d0=rbox(q+vec3(0.,-1.3,-0.4),vec3(0.02+0.3*sin(q.y-.2),0.8,0.02+0.1*sin(q.y*1.5-1.2)),0.1);
    
    // breast
    vec3 q1=rot_x(q,0.6);
    q1.x=abs(q1.x)-.3;
    q1.y+=0.06*sin(BREATH_FREQ*iTime-2.);
    float d1=ellipsoid(q1,vec3(0.,1.8,-0.4),vec3(.4,.3,.5));
    if(d1<d0)matid=MAT_BODY;
    d0=smin(d0,d1,0.3);
    
    // neck
    d1=line(q,vec3(0.,2.1,0.4),vec3(0.,2.4,0.4)).x-.1;
    if(d1<d0)matid=MAT_BODY;
    d0=smin(d0,d1,0.2);
    
    // head
    d1=ellipsoid(q,vec3(0.,2.7,.4),vec3(0.4,0.55,0.4));
    if(d1<d0)matid=MAT_BODY;
    d0=smin(d0,d1,0.05);
    
    // abs
    q1=q+vec3(0.,-.75,-.55);
    q1.xy=vec2(abs(q1.x)-0.1,abs(q1.y)-0.19);
    d1=ellipsoid(q1, vec3(0.), vec3(0.05,0.08,0.07));
    if(d1<d0)matid=MAT_LEGS;
    d0=smin(d0,d1,0.2);
  

    // arms
    q1=vec3(abs(q.x)-.4,q.y+0.02*sin(BREATH_FREQ*iTime-1.),q.z);
    vec2 hh=line(q1,vec3(0.,2.1,0.4), vec3(.7,1.5,0.));
    d1=hh.x-mix(0.14,0.02,hh.y) + 0.05*sin(6.2831*hh.y);
    if(d1<d0)matid=MAT_BODY;
    d0=smin(d0, d1, 0.15);
    
    hh=line(q1,vec3(.7,1.5,0.), vec3(1.5,1.,0.9));
    d1=hh.x-mix(0.06,0.02,hh.y) + 0.01*cos(2.0*6.2831*hh.y);
    if(d1<d0)matid=MAT_LEGS;
    d0=smin(d0, d1,0.1);
    
    q1=vec3(abs(q.x)-.02,abs(q.y-2.7)-.1,q.z);
    hh=line(q1,vec3(0.,0.,0.3), vec3(0.5,.3,-.5));
    d1=hh.x-mix(0.06,0.02,hh.y) + 0.01*cos(2.0*6.2831*hh.y);
    if(d1<d0)matid=MAT_BODY;
    d0=smin(d0, d1,0.3);
    
    // nipples
    /*q1=q;q1.x=abs(q1.x)-0.42;q1.yz+=0.04*sin(2.*iTime-2.);
    float d11=sphere(q1-vec3(0.,1.65,0.84),0.04);
    if(d11<d0){d0=d11;matid=MAT_LEGS;}*/
    return vec2(d0,matid);
}

float legs(in vec3 p, in vec3 mvv, in vec3 muu)
{
    float d0=100.;
    for(int i=0; i<min(0,iFrame)+6; i++)
    {
        float s=-sign(float(i)-2.5);
        float h=mod(float(i), 3.0)/3.0;
        
        vec3 bas=spider.pos - 0.8*mvv*(1.0-h) + muu*s*0.8*(1.-h) + spider.forward*.8*(h-0.33) ;

        vec3 n1=spider.knees[i];
        vec2 hh=line2(bas, n1, p, 1./(2.5*2.5));
        d0=smin(d0, hh.x-mix(0.15,0.1,hh.y) + 0.05*sin(6.2831*hh.y), 0.1);
        hh=line2(n1, spider.feet[i], p, 1./((2.+(1.-h))*(2.+(1.-h))));
        d0=smin(d0, hh.x-mix(0.08,0.02,hh.y) + 0.01*cos(2.0*6.2831*hh.y),0.1);
    }
    return d0;
}

vec2 dspider(in vec3 p)
{
    p*=0.14;
    vec3 q=p - spider.pos;
    
    if(dot(q,q)>72.0) return vec2(32.0);
    
    vec3 muu=vec3(1.0,0.0,0.0);
    vec3 mvv=normalize(cross(spider.forward,muu));
    q=vec3(q.x, dot(mvv,q), dot(spider.forward,q));    
    q.y+=BREATH;    
    float matid=MAT_LEGS;
       
    float d0=100.;
    
    d0=legs(p,mvv,muu);
    
    // ab
    vec3 q1=rot_x(q,-0.7);
    float d1=ellipsoid(q1, vec3(0.), vec3(1.5,1.5,2.));
    if(d1<d0)matid=MAT_AB;
    d0=smin(d0,d1,0.2);
    //ab
    float ab=(0.5 + 0.5*cos(4.0*pow(0.5-0.5*q.z,2.0)))*(0.5+0.5*q.z);
    d1=ellipsoid(q, vec3(0.,-0.6,-1.6),vec3(2.3,2.3,4.))- 0.1*ab;
    d1+=0.03*sin(10.*q.z);    
    if(d1<d0)matid=MAT_AB;
    d0=smin(d0,d1,0.2);
    
    vec2 res=body(q);
    if(res.x<d0)matid=res.y;
    d0=smin(d0,res.x,0.2);
    
    // eyes
    d1=ellipsoid(q,vec3(0.,2.84,0.65),vec3(0.19,0.55,0.3));
    if(-d1>d0){d0=-d1;matid=MAT_SPIDER_EYEHOLE;}
    
    d1=sphere(q-SPIDER_EYEPOS, 0.15);
    if(d1<d0){d0=d1;matid=MAT_EYES;}

    return vec2(d0/.14, matid);
}


#define MAT_HAND 0.
#define MAT_LAND 1.
#define MAT_EYE 2.
#define MAT_EYEHOLE 3.


#define EYEPOS vec3(0.3,3.4,0.2)
float eyeball(vec3 p)
{
    float d0=sphere(p-EYEPOS, 1.);
    return d0;
}


vec2 hand(vec3 p)
{
    float matid=MAT_HAND;
    // palm
    float d0=rbox(p-vec3(0.,0.,0.1), vec3(0.6,1.5,0.05), 1.); //line(p, vec3(0.0,0.,0.0), vec3(0.0,1.0,0.0)).x-1.;
    vec3 q=rot_z(p,-0.1);
    float d1=rbox(q-vec3(0.,3.,0.), vec3(1.+.5*sin(12.+.55*p.y),1.7,0.01), .8+.15*sin(p.y));
    d0=smin(d0,d1,2.);
    
    // thumb
    vec2 hh=line(p,vec3(-1.5,1.,0.0), .85*vec3(-4.,3.,1.));
    d1=hh.x-.9+0.35*sin(hh.y);
    d0=smin(d0,d1,.7);
    hh=line(p,vec3(-3.5,2.6,0.9),vec3(-3.,3.4,1.8));
    d1=hh.x-.6+.2*sin(hh.y);
    d0=smin(d0,d1,.1);
    
    // center
    d1=sphere(p-vec3(0.4,3.3,2.5),1.7);
    d0=smax(d0,-d1,.7);
    
    // fingers
    hh=line(p,vec3(-1.3,4.8,-0.2),.74*vec3(-2.8,8.,-1.));
    d1=hh.x-.7+.3*sin(hh.y);
    d0=smin(d0,d1,.3);
    hh=line(p-vec3(0.4,-0.6,0.6),vec3(-2.4,6.2,-1.4),.96*vec3(-2.7,7.6,-.8));
    d1=hh.x-.5+.1*sin(hh.y);
    d0=smin(d0,d1,.1);
    hh=line(p,vec3(-2.2,6.8,0.),.95*vec3(-2.2,7.4,0.6));
    d1=hh.x-.4+.05*sin(hh.y);
    d0=smin(d0,d1,.1);
    
    hh=line(p,vec3(-0.1,4.8,-0.2),.85*vec3(-0.3,8.,-1.));
    d1=hh.x-.66+.2*sin(hh.y);
    d0=smin(d0,d1,.3);
    hh=line(p,vec3(-0.3,6.9,-1.),.98*vec3(-0.3,7.9,0.25));
    d1=hh.x-.5+.1*sin(hh.y);
    d0=smin(d0,d1,.1);
    hh=line(p,vec3(-0.3,7.6,0.4),.97*vec3(-0.3,7.7,1.));
    d1=hh.x-.4+.05*sin(hh.y);
    d0=smin(d0,d1,.1);
    
    hh=line(p,vec3(1.,4.8,-0.2),.84*vec3(1.5,8.,-1.));
    d1=hh.x-.6+.2*sin(hh.y);
    d0=smin(d0,d1,.3);
    hh=line(p,vec3(1.25,6.5,-0.9),.93*vec3(1.5,7.9,0.25));
    d1=hh.x-.48+.1*sin(hh.y);
    d0=smin(d0,d1,.1);
    hh=line(p,vec3(1.4,7.3,0.1),vec3(1.3,7.,.9));
    d1=hh.x-.4+.05*sin(hh.y);
    d0=smin(d0,d1,.1);
    
    hh=line(p,vec3(2.2,4.8,-0.2),.7*vec3(3.8,8.,-1.));
    d1=hh.x-.5+.1*sin(hh.y);
    d0=smin(d0,d1,.25);
    hh=line(p,vec3(2.73,5.6,-.8),.98*vec3(3.,6.4,0.));
    d1=hh.x-.45+.1*sin(hh.y);
    d0=smin(d0,d1,.1);
    hh=line(p,vec3(2.88,6.3,0.1),.97*vec3(2.8,6.4,.6));
    d1=hh.x-.4+.05*sin(hh.y);
    d0=smin(d0,d1,.1);
    
    
    // eye
    d1=ellipsoid(p,vec3(0.3,3.6,1.2),vec3(3.6,1.2+cos(p.x-.3),2.2));//sphere(q1, 0.055);
    if(-d1>d0){matid=MAT_EYEHOLE;} 
    d0=smax(d0,-d1,0.2);
    d1=eyeball(p);
    if(d1<d0){d0=d1;matid=MAT_EYE;}
    
   /* q=p-vec3(-0.26,7.9,1.);
    d1=box(q,vec3(.25,.05-0.03*sin(q.x*10.-8.2),.3-0.05*sin(q.x*10.-8.2)));
    d0=min(d0,d1);*/
    return vec2(d0,matid);
    
}


vec2 dead_land(vec3 p)
{    
    vec2 res=hand(p);
    float d0=res.x+.05*texture(iChannel0,p.xy*.05).x;
    float matid=res.y;
    
    float bump=textureLod(iChannel1,p.xz/16.+p.xy/80.,0.0).x;
    float d1=p.y+4.-bump+1.9*cos(p.x*0.15+1.8+cos(p.z*0.15));
    if(d1<d0){d0=d1;matid=MAT_LAND;}
    d0=smin(d0,p.y+4.-0.15*bump, 0.5);
    
    
    return vec2(d0,matid);
}

float map(vec3 p)
{
    float d=hand(p).x;
    d=min(d,dspider(p).x);
    return d;  
}

vec3 get_spider_normal(vec3 p)
{
    // inspired by tdhooper and klems - a way to prevent the compiler from inlining map() 4 times
    vec3 n = vec3(0.0);
    for( int i=0; i<4; i++ )
    {
        vec3 e = 0.5773*(2.0*vec3((((i+3)>>1)&1),((i>>1)&1),(i&1))-1.0);
        n += e*dspider(p+0.001*e).x;
    }
    return normalize(n);
}

vec3 get_dead_land_normal(vec3 p)
{
    // inspired by tdhooper and klems - a way to prevent the compiler from inlining map() 4 times
    vec3 n = vec3(0.0);
    for( int i=0; i<4; i++ )
    {
        vec3 e = 0.5773*(2.0*vec3((((i+3)>>1)&1),((i>>1)&1),(i&1))-1.0);
        n += e*dead_land(p+0.001*e).x;
    }
    return normalize(n);
}



// marciot's "The Mandel Grim"  
// https://www.shadertoy.com/view/4tGXWd
vec3 get_eye_material(vec2 uv, bool bloody, float iris)
{   
    float r=uv.y/iris;
    float a=uv.x*PI*2.0;
    vec2 p=vec2(r*cos(a), r*sin(a));
    vec3 col=vec3(1.);

    if(r<.7) 
    {
        col=vec3(0.9, 0.4, 0.2)*.5;

        float f=fbm(5.0*p);
        col=mix(col, vec3(0.9,0.8,0.3)*0.2, f);
        col=mix(col, vec3(0.9,0.5,0.2), 1.0-smoothstep(0.2,0.6,r));

        a += 0.05*fbm(20.0*p);
        f=smoothstep(0.3, 1.0, fbm(vec2(6.2*r, 20.0*a)));
        col=mix(col, vec3(0.), f);

        f=smoothstep(0.4, 0.9, fbm(vec2(10.0*r, 15.0*a)));
        col *= 1.0 - 0.5*f;

        f=smoothstep(0.6, 0.8, r);
        col *= 1.0 - 0.5*f;

        f=smoothstep(0.2, 0.25, r);
        col *= f;

        f=smoothstep(0.75, 0.8, r);
        col=mix(col, vec3(1.0), f);
    }
    
    if(r>.67 && bloody)
    {
        a+=0.15*fbm(10.0*p);
        float f=smoothstep(0.25, .8, fbm(vec2(0.9*r, 20.0*a)));
        col-=vec3(.0,1.0,1.0)*f;
    }

    return col;
}

vec4 get_spider_material(vec3 p, vec3 n)
{
    vec2 res=dspider(p);
    vec3 material=vec3(1.0);
    p*=0.14;
    vec3 q=get_spider_coord(p-spider.pos);

    if(res.y<MAT_LEGS)
    {
        float t=mod(q.z, 0.7); 
        material= vec3(0.01)+vec3(.3, 0.01, 0.01)*
                    pow(smoothstep(0.0, 0.1, t) * smoothstep(0.285, .28, t), 40.0);
       
        clamp(material, 0.0, 1.0);
    }
    else if(res.y<MAT_BODY)
    {
        material=vec3(0.01);
    }
    else if(res.y<MAT_EYES)
    {
        q.y+=BREATH;        
        material=mix(vec3(0.01), vec3(1.55,.7333,.6)*.75,
                     smoothstep(1.,1.75,q.y));
    }
    else if(res.y<MAT_SPIDER_EYEHOLE)
    {
        float t=mod(q.z, 0.508);

        vec3 p0=q-SPIDER_EYEPOS;
        p0.y+=BREATH;
        vec2 uv=vec2(atan(p0.y,p0.x)/(2.*PI), 
                    acos(p0.z/length(p0))/PI);
        material=get_eye_material(uv, false, 0.4);
        
    }
    else
    {
        material=texture(iChannel0, q.xy).xyz;    
        
    }
    return vec4(material,res.y);
}


vec4 get_dead_land_material(vec3 p, vec3 n)
{
    vec2 res=dead_land(p);
    vec3 material=vec3(0.);
    if(res.y<MAT_LAND)
    {
        material=vec3(1.55,.7333,.6)*.75;
    }
    else if(res.y<MAT_EYE)
    {
        material=texture(iChannel0, p.xz*0.1).xyz;
    }
    else if(res.y<MAT_EYEHOLE)
    {
    	p=rot_y(p,0.2*(floor(sin(iTime*2.+sin(iTime)+17.))*2.+1.));
        
        vec3 p0=p-EYEPOS;
        vec2 uv=vec2(atan(p0.y,p0.x)/(2.*PI), 
                    acos(p0.z/length(p0))/PI);
        material=get_eye_material(uv, true, .2);
    }
    else
    {
        material=texture(iChannel0, p.xy).xyz;
        material-=vec3(0.,.24,.2);
        material=clamp(material,0.,1.);
    }
    return vec4(material, res.y);
}

float shadow(vec3 ro, vec3 rd)
{
    float res=1.0;
    float t=0.02;
    float h;
    
    for (int i=0; i < min(0,iFrame)+8; i++)
    {
        h=map(ro + rd*t);
        res=min(6.0*h / t, res);
        t += h;
    }
    return max(res, 0.0);
}

float get_ao(vec3 p, vec3 n)
{
    float r=0.0, w=1.0, d;
    for(float i=1.; i<float(min(0,iFrame))+5.0+1.1; i++)
    {
        d=i/5.0;
        r += w*(d - dead_land(p + n*d).x);
        w *= 0.5;
    }
    return 1.0-clamp(r,0.0,1.0);
}

const vec3 moon_dir=normalize(vec3(-0.1,0.05,0.4));


vec3 lighting_spider(vec3 ro, vec3 rd, vec3 pos, vec3 nor)
{
    vec3 l0dir=moon_dir;
    vec3 l0col=vec3(1.);
    vec4 ma=get_spider_material(pos, nor);
    
    if(ma.w<MAT_BODY)
    	nor=bump_mapping(pos, nor, 0.03);
    
    float diff=4.0*max(0.,dot(l0dir,nor));
    float back=0.5*max(0.,dot(-l0dir,nor));
    float sky=max(0.,dot(vec3(0,1,0),nor));
    float boun=0.5*max(0.,dot(vec3(0,-1,0),nor));
    float spec=max(0.0, pow(clamp(dot(l0dir, reflect(rd, nor)), 0.0, 1.0), 64.0));
    
    vec3 col=((l0col*diff+l0col*back)+
              3.*vec3(0.0,0.05,0.1)*sky+
              3.*vec3(0.0,0.05,0.1)*boun)+vec3(1.)*spec;

    col*=ma.xyz*0.2;
    
    col+=(ma.w<MAT_BODY?1.0:0.)*spec;
    return col;
}


float density_hand(vec3 p, float ms, vec3 n) 
{
    return hand(p+n*ms).x/ms;
}


vec3 lighting_dead_land(vec3 ro, vec3 rd, vec3 pos, vec3 nor)
{
    vec3 l0dir=moon_dir;
    vec3 l0col=vec3(1.);
    
    vec4 ma=get_dead_land_material(pos, nor);
    //nor=bump_mapping(pos, nor, 0.03);
    
    float shad=shadow(pos+0.1*nor,l0dir);
    float ao=get_ao(pos,nor);
    float diff=4.0*max(0.,dot(l0dir,nor));
    float back=0.2*max(0.,dot(-l0dir,nor));
    float sky=max(0.,dot(vec3(0,1,0),nor));
    float boun=0.5*max(0.,dot(vec3(0,-1,0),nor));
    float spec=max(0.0, pow(clamp(dot(l0dir, reflect(rd, nor)), 0.0, 1.0), 16.0));
    float sca=1.-density_hand(pos,1.,nor);

    
    vec3 col=((l0col*diff+l0col*back)*shad*ao*ao+
              3.*vec3(0.0,0.05,0.1)*sky+
              3.*vec3(0.0,0.05,0.1)*boun);
    if(ma.w<MAT_EYEHOLE)
        col+=spec;
    if(ma.w<MAT_LAND)
        col+=.7*vec3(0.3,0.1,0.1)*sca;
    col*=ma.xyz;
    col*=0.2;

    return col;
}


vec4 scene_spider(vec3 ro, vec3 rd)
{    
    float t=0.1;
    for(int i=0;i<min(0,iFrame)+128;++i)    
    {
        float d=dspider(ro+rd*t).x;
        if(d<0.005||t>100.0)
            break;
        
        t+=d;
    }
        
    
    vec3 col=vec3(1.);
    if(t<100.)
    {
        vec3 pos=ro+t*rd;
        vec3 nor=get_spider_normal(pos);
        col=lighting_spider(ro,rd,pos,nor);
    }
    return vec4(col,t);
}


vec4 scene_dead_land(vec3 ro, vec3 rd)
{
    float t=0.1;
    for(int i=0;i<min(0,iFrame)+128;++i)    
    {
        float d=dead_land(ro+rd*t).x;
        if(d<0.005||t>100.0)
            break;
        
        t+=d;
    }
            
    vec3 col=vec3(0.);

    
    if(t<100.)
    {
        vec3 pos=ro+t*rd;
        vec3 nor=get_dead_land_normal(pos);
        col=lighting_dead_land(ro,rd,pos,nor);
    }
    col=mix(col,vec3(0.0,0.05,0.1)*.7, 1.0-exp(-0.00025*t*t));
    
    return vec4(col,t);
}


float terrain(vec2 p) 
{
    float w=0.;
    float s=1.;
    p.x*=20.;
    w+=sin(p.x*.3521)*4.;
    for (int i=0; i<min(0,iFrame)+5; i++) 
    {
        p.x*=1.53562;
        p.x+=7.56248;
        w+=sin(p.x)*s;      
        s*=.5;
    }
    w=w*.5+.5;
    return step(0.,p.y-w*.02+.07);
}

vec3 render_terrian(vec3 ro, vec3 rd, vec3 col)
{
    col=mix(col,vec3(0.0,0.05,0.1)*0.7, 1.-terrain(rd.xy));
    return col;
}

// Shane's "3D cellular tiling"
// https://www.shadertoy.com/view/ld3Szs
float tri3(in vec3 p)
{
    p=cos(p*2.+(cos(p.yzx)+1.+iTime*4.)*1.57);
    return dot(p, vec3(0.1666))+0.5;
}

float triangle_noise(vec3 p)
{
    const mat3 m=mat3(0.25, -0.866, 0.433, 
                        0.9665, 0.25, -0.2455127, 
                        -0.058, 0.433, 0.899519)*1.5;
  
    float res=0.;

    float t=tri3(p*PI);
    p+=(t-iTime*0.25);
    p=m*p;
    res+=t;
    
    t=tri3(p*PI); 
    p+=(t-iTime*0.25)*0.7071;
    p=m*p;
    res+=t*0.7071;

    t=tri3(p*PI);
    res+=t*0.5;
     
    return res/2.2071;
}


float get_mist(in vec3 ro, in vec3 rd, in vec3 lp, in float t){

    float mist=0.;
    ro+=rd*t/8.;
    
    for (int i=0; i<min(0,iFrame)+4; i++)
    {
        mist+=triangle_noise(ro/4.)*(1.-float(i)*.2);
        ro+=rd*t/4.;
    }
    return clamp(mist/2.+hash31(ro)*0.1-0.05, 0., 1.);
}

vec3 render_sky(vec3 ro, vec3 rd)
{
    vec3 sky=vec3(0.0,0.05,0.1);
   
    vec3 clouds=vec3(0.0);
    float s=.3;
    for (int i=0; i < min(0,iFrame)+3; ++i) 
    {
        clouds+=smoothstep(0.5,0.2,fbm(s*rd.xz/(rd.y+2./iResolution.x)+s*iTime*0.5));
        s *= 1.5;
    }
    
    vec3 col=sky + .35*clouds*max(0.0, rd.y);
    vec3 moon_col=pow(vec3(0.659,0.765,0.878),vec3(1.2));
    col+=moon_col*smoothstep(0.3,0.36,pow(max(dot(moon_dir, rd), 0.0), 32.0));
    vec2 moon_pos=rd.xy/rd.z - moon_dir.xy/moon_dir.z;
    col=mix(col, moon_col*fbm(10.*moon_pos-2.), max(0.,rd.z)*smoothstep(0.37, 0.1, length(moon_pos)));
    
    return col;
}

vec3 tonemap(vec3 x) 
{
    const float a=2.51;
    const float b=0.03;
    const float c=2.43;
    const float d=0.59;
    const float e=0.14;
    return (x * (a * x + b)) / (x * (c * x + d) + e);
}

// time slot of each scene
#define SCENE_1 5.  // moon
#define SCENE_2 10. // mist
#define SCENE_3 33. // spider passes
#define SCENE_4 45. // eye of the hand
#define SCENE_5 65. // spider alone

void get_camera(out vec3 ro, out vec3 ta)
{
    // center: x_rot=-1.5, y_rot=0.01;
    float x_rot=-1.3, y_rot=0.01;
    
    if(iTime<SCENE_3 || iTime>SCENE_5)
    {
        x_rot=-1.3, y_rot=0.05;
        ro=vec3(0.,4.,0.)+vec3(cos(y_rot)*cos(x_rot),sin(y_rot),cos(y_rot)*sin(x_rot))*20.35;
        ta=vec3(0.0,1.,0.);
    }
    else if(iTime<SCENE_4)
    {
        x_rot=-1.3+2.8*smoothstep(SCENE_3, SCENE_3+5., iTime), y_rot=0.05;
        ro=vec3(0.,4.0,-1.5*smoothstep(SCENE_3, SCENE_4, iTime))+vec3(cos(y_rot)*cos(x_rot),sin(y_rot),cos(y_rot)*sin(x_rot))*20.35;
        ta=vec3(0.0,1.,0.);
    }
    else if(iTime<SCENE_5)
    {
        x_rot=1.4;y_rot=0.3;
        ro=spider.pos+vec3(10.,25.,40.);//+vec3(cos(y_rot)*cos(x_rot),sin(y_rot),cos(y_rot)*sin(x_rot))*45.;
        ta=spider.pos+vec3(-10.,15.,0.);
    }
    
    // shake
    ro+=0.04*sin(2.0*iTime*vec3(1.1,1.2,1.3)+vec3(3.0,0.0,1.0));
    ta+=0.04*sin(2.0*iTime*vec3(1.7,1.5,1.6)+vec3(1.0,2.0,1.0));
    
}

vec3 spider_path(vec3 offset, float time)
{
    return offset+vec3(0., 0., .4*time);
}


// iq's "Insect" : https://www.shadertoy.com/view/Mss3zM
void move_legs(vec3 offset, float time)
{
    for(int i=0; i<min(0,iFrame)+6; i++)
    {
        // side
        float s=-sign(float(i)-2.5);
        // pair
        float h=mod(float(i), 3.0)/3.0;

        float z=.5*time + 4.*h + 0.25*s;
        float iz=floor(z);
        float fz=fract(z);
        float az=clamp((fz-0.66)/0.34,0.0,1.0);

        vec3 fo=offset+vec3(s*2.5, 0.7*az*(1.0-az)-2.,
                              (iz+az+(h-0.4)*6.0)*.8);
        spider.feet[i]=fo;

        vec3 ba=spider.pos-0.8*vec3(0.,1.,0.)*(1.0-h)+vec3(1.0,0.0,0.0)*s*0.8*(1.0-h)+spider.forward*.8*(h-0.33) ;

        spider.knees[i]=solve(ba, fo, 2.5, 2.+(1.-h), s*vec3(0.0,0.0,-1.));
    }
}


void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 q=fragCoord/iResolution.xy;
    vec2 p=q*2.-1.;
    p.x*=iResolution.x/iResolution.y;
   
    if (abs(p.y)>.88) {
        fragColor=vec4(0.0, 0.0, 0.0, 1.0);
        return;
    }
   
    vec3 offset=vec3(-1.8,1.5,-20.);
    
    if(iTime<SCENE_2 || iTime>SCENE_5)
    {
        spider.pos=offset;
        spider.forward=vec3(0.,0.,1.);
    }
    else if(iTime<SCENE_3)
    {
        float atime=30.+2.*(iTime-SCENE_2);
        spider.pos=spider_path(offset,atime);
        spider.forward=normalize(spider_path(offset,atime+2.)-spider.pos);
        move_legs(offset, atime);
    }
    else if(iTime<SCENE_4)
    {
        spider.pos=offset;
        spider.forward=vec3(0.,0.,1.);
    }
    else
    {
        float atime=30.+2.*(iTime-SCENE_4);
        spider.pos=spider_path(offset,atime);
        spider.forward=normalize(spider_path(offset,atime+2.)-spider.pos);
        move_legs(offset, atime);
    }
    

    vec3 ro=vec3(0.,1.,3.);
    vec3 ta=vec3(0.);
    
    // debugging camera
    //float x_rot=-iMouse.x/iResolution.x*PI*2.0;
    //float y_rot=iMouse.y/iResolution.y*3.14*0.5 + PI/2.0;
    //ro=spider.pos+vec3(0.,20.,0.)+vec3(cos(y_rot)*cos(x_rot),sin(y_rot),cos(y_rot)*sin(x_rot))*10.35;
    //ta=spider.pos+vec3(0.,20.,0.);
    //ro=vec3(0.,3.0,0.)+vec3(cos(y_rot)*cos(x_rot),sin(y_rot),cos(y_rot)*sin(x_rot))*20.35;
    //ta=vec3(0.0,1.,0.);
    
    
    get_camera(ro,ta);
    
    vec3 f=normalize(ta-ro);
    vec3 r=normalize(cross(f,vec3(0.,1.,0.)));
    vec3 u=normalize(cross(r,f));
    vec3 rd=normalize(r*p.x+u*p.y+f*2.3);
    
    vec3 sky=vec3(0.0,0.05,0.1)*1.4;
    vec3 col=render_sky(ro,rd);
    col=render_terrian(ro,rd,col);
    
    vec4 res0=scene_dead_land(ro,rd);
    
    vec4 res1=vec4(0,0,0,100);
   
    if((iTime>SCENE_2 && iTime<SCENE_4) ||
      (iTime>SCENE_4 && iTime<SCENE_5))
    {
        res1=scene_spider(ro,rd);
    }
    
    vec4 res=res0;
    if(res1.w<res0.w)
        res=res1;
    
    float t=res.w;

    if(t<100.)
    {
        col=res.xyz;
    }

    
    float mist=get_mist(ro, rd, moon_dir, t);
    if(iTime<SCENE_5)
    {
        col=mix(col, vec3(0.8,0.8,1.)*mix(1., .75, mist)*(rd.y*.25+.5),
                min(pow(t, 1.5*smoothstep(0.,10.,iTime))*.15/100., 1.));
    }
    else
    {
        col=mix(col, vec3(0.8,0.8,1.)*mix(1., .75, mist)*(rd.y*.25+.5),
                min(pow(t, 1.5-smoothstep(0.,20.,iTime-SCENE_5))*.15/100., 1.));
    }
    
    col=tonemap(col);
    col=pow(clamp(col,0.0,1.0),vec3(0.45));
    col*=0.5+0.5*pow(16.0*q.x*q.y*(1.0-q.x)*(1.0-q.y),0.7);  // vigneting
   
    fragColor=vec4(col,1.0);
    
    fragColor.xyz=mix(fragColor.xyz, vec3(0.), smoothstep(3.,0., iTime));
    
    if(iTime>SCENE_3)
    {
        fragColor.xyz=mix(fragColor.xyz, vec3(0.), smoothstep(3.,0., iTime-SCENE_3));
    }
    if(iTime>SCENE_4)
    {
        fragColor.xyz=mix(fragColor.xyz, vec3(0.), smoothstep(3.,0., iTime-SCENE_4));
    }
    if(iTime>SCENE_5)
    {
        fragColor.xyz=mix(fragColor.xyz, vec3(0.), smoothstep(4.,0., iTime-SCENE_5));
    }
}