// Created by EvilRyu
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.


float hash11(float p)
{
	vec2 p2 = fract(vec2(p * 5.3983, p * 5.4427));
    p2 += dot(p2.yx, p2.xy + vec2(21.5351, 14.3137));
	return fract(p2.x * p2.y * 95.4337);
}

float hash13(vec3 p)
{
    p=fract(p*vec3(5.3983,5.4472,6.9371));
    p+=dot(p.yzx,p.xyz+vec3(21.5351,14.3137,15.3219));
    return fract(p.x*p.y*p.z*95.4337);
}

float sphere(vec3 p, float r)
{
    return length(p)-r;
}

float line(vec3 p, float h, float r)
{
  p.y-=clamp(p.y, 0.0, h);
  return length(p)-r;
}

void basis(vec3 n, out vec3 b1, out vec3 b2) 
{
    if(n.y<-0.999999) 
    {
        b1=vec3(0,0,-1);
        b2=vec3(-1,0,0);
    } 
    else 
    {
    	float a=1./(1.+n.y);
    	float b=-n.x*n.z*a;
    	b1=vec3(1.-n.x*n.x*a,-n.x,b);
    	b2=vec3(b,-n.z,1.-n.z*n.z*a);
    }
}

void rot2d(inout vec2 p, float t)
{
    float ct=cos(t),st=sin(t);
    vec2 q=p;
	p.x=ct*q.x+st*q.y;
    p.y=-st*q.x+ct*q.y;
}

float smin(float a, float b, float k)
{
    float h=clamp(0.5+0.5*(b-a)/k, 0.0, 1.0);
    return mix(b,a,h)-k*h*(1.0-h);
}

float smax(float a, float b, float k)
{
    return smin(a,b,-k);
}

const float PI=3.14159265359;
const float PHI=1.61803398875;

// iq's inverse spherical fibonnacci: https://www.shadertoy.com/view/lllXz4
vec4 invsf(vec3 p, float n)
{
    float m=1.-1./n;
    float phi=min(atan(p.y,p.x),PI);
    float k=max(2.,floor(log(n*PI*sqrt(5.)*
                             (1.-p.z*p.z))/log(PHI+1.)));
    float Fk=pow(PHI,k)/sqrt(5.);
    vec2  F=vec2(round(Fk), round(Fk*PHI));
    vec2 ka=2.*F/n;
    vec2 kb=2.*PI*(fract((F+1.)*PHI)-(PHI-1.));    
    mat2 iB=mat2(ka.y,-ka.x, 
                    kb.y,-kb.x)/(ka.y*kb.x-ka.x*kb.y);
    
    vec2 c=floor(iB*vec2(phi, p.z-m));
    float d=0.;
    vec4 res=vec4(0);
    for(int s=0; s<4; s++) 
    {
        vec2 uv=vec2(s&1,s>>1);
        float i=dot(F,uv+c); 
        float phi=2.*PI*fract(i*PHI);
        float ct=m-2.*i/n; //costheta
        float st=sqrt(1.-ct*ct); //sintheta
        
        vec3 q=vec3(cos(phi)*st, 
                    sin(phi)*st, 
                    ct);
        float d1=dot(p,q);
        if(d1>d) 
        {
            d=d1;
            res=vec4(q,d);
        }
    }
    return res;
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
    return dot(texcube(iChannel1, 0.25*p, n).xyz, vec3(0.299, 0.587, 0.114)); 
}

vec3 bump_mapping(vec3 p, vec3 n, float weight)
{
    vec2 e = vec2(2./iResolution.y, 0); 
    vec3 g=vec3(bump(p-e.xyy, n)-bump(p+e.xyy, n),
                bump(p-e.yxy, n)-bump(p+e.yxy, n),
                bump(p-e.yyx, n)-bump(p+e.yyx, n))/(e.x*2.);  
    g=(g-n*dot(g,n));
    return normalize(n+g*weight);
}


int id=0;

vec4 get_corona_params(vec3 p)
{
    vec3 r,f;
    vec4 fibo=invsf(normalize(p),100.);
    vec3 q=p-fibo.xyz;
    vec3 n=normalize(fibo.xyz);
    basis(n,r,f);
    q=vec3(dot(r,q),dot(n,q),dot(f,q));
    // bending
    rot2d(q.xy,(hash13(fibo.xyz)*2.-1.)*q.y*.45);
    return vec4(q,0.1+0.088*hash13(fibo.xyz+vec3(13.399,71.137,151.11)));
}

vec3 movement(vec3 p)
{
    float t=mod(iTime,1.5)/1.5;
    p*=1.-0.02*clamp(sin(6.*t)*exp(-t*4.),-2.,2.);
	rot2d(p.xz, iTime*0.05);
    rot2d(p.xy,iTime*0.02);
	return p;
}

float map(vec3 p)
{
    p=mod(p-vec3(4.),8.)-4.;
   	p=movement(p);
    float d0=sphere(p*vec3(.9,1.,.98),1.)-0.1*texcube(iChannel0, p*.8, normalize(p)).x;
    vec4 q=get_corona_params(p);

    float d1=line(q.xyz,q.w*3.,0.07);
    
    if(d0>d1)id=1;
    
    d0=smin(d0,d1,0.1);
    
    d1=sphere(q.xyz-vec3((q.w*2.-.2)*0.2,q.w*3.+0.05,0.),0.05+q.w*0.4);
    d0=smin(d0,d1,0.2);
    
    d1=line(q.xyz-vec3(0,q.w*3.,0.), q.w*3., 0.02+0.07*q.y);
    d0=smax(d0,-d1,0.12);
        
    return d0*.55;
}

vec3 get_normal(vec3 p)
{
    vec3 eps=vec3(0.001,0,0);
    return normalize(vec3(map(p+eps.xyz)-map(p-eps.xyz),
                     map(p+eps.yxz)-map(p-eps.yxz),
                     map(p+eps.yzx)-map(p-eps.yzx)));
}

float bisect(vec3 ro, vec3 rd, float near, float far)
{
    float mid=0.;
    vec3 p=ro+near*rd;
    float sgn=sign(map(p));
    for (int i=0; i<6; i++)
    { 
        mid=(near+far)*.5;
        p=ro+mid*rd;
        float d=map(p);
        if(abs(d)<0.001)break;
        d*sgn<0. ? far=mid : near=mid;
    }
    return (near+far)*.5;
}

#define FAR 30.0
float intersect(vec3 ro, vec3 rd)
{
    float t=0.01;
    float d=map(ro+t*rd);
	float sgn=sign(d);
    float told=0.;
	bool doBisect=false;

   	for(int i=0;i<128;++i)
    {         
        d=map(ro+t*rd);
        if (sign(d)!=sgn)
        {
            doBisect=true;
            break;
        }
        
        if(d<0.003&&t>FAR)
        	break;
        
        told=t;
        t+=d;
    }
    if (doBisect)t=bisect(ro,rd,told,t);
    return t;
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
    f+=.5*noise(p); p=m*p*2.;
    f+=.25*noise(p); p=m*p*2.;
    f+=.125*noise(p); p=m*p*2.;
    f+=.0625*noise(p); p=m*p*2.;
    f+=.03125*noise(p);
    return f/0.984375;
}

float get_ao(vec3 p, vec3 n)
{
    float r=0.0, w=1.0, d;
    for(float i=1.; i<5.0+1.1; i++)
    {
        d=i/5.0;
        r+=w*(d-map(p+n*d));
        w*=0.5;
    }
    return 1.0-clamp(r,0.0,1.0);
}

float sss(vec3 p, vec3 n, float d, float i) 
{ 
    float o,v; 
    for(o=0.;i>0.;i--) 
        o+=(i*d+map(p+n*i*d))/exp2(i); 
    return o; 
}

float shadow(vec3 ro, vec3 rd)
{
    float s = 1.0,t = 0.01,h = 1.0;
    for( int i=0; i<16; i++ )
    {
        h = map(ro + rd*t);
        s = min( s, 16.*h/t );
        if( s<0.0001 ) break;
        t += clamp( h, .01, .05 );
    }
    return clamp(s,.0,1.);
}

vec3 lighting(vec3 ro, vec3 rd, vec3 n, float t, vec3 p)
{    
    id=0;
    float d=map(p);
    vec3 ld0=normalize(vec3(1,1.2,-1.3));
    
    if(id==1)
    {
        n=bump_mapping(movement(p), n, 0.0265);
    }

    float dif=max(0.,dot(ld0,n));
    float spe=pow(max(0.,dot(rd,reflect(ld0,n))), 24.0);
    float bac=max(0.,dot(-ld0,n));
    float amb=clamp(0.3+0.7*n.y,0.0,1.0);
    float sca=sss(p,-n,.6,6.);
    float fre=clamp(1.-dot(n,-rd),0.,1.);
	float sha=shadow(p,ld0);
    vec3 mate=vec3(1.9,0.352,0.45)*.5+pow(texcube(iChannel1, 3.*movement(p), n).x,8.5)*vec3(.5);
    
    
    float ao=get_ao(p,n)*1.5;
    
    vec3 col=(4.0*dif+0.5*bac+1.*amb+5.5*fre)*mate*ao+3.5*spe*vec3(1);
    col*=sha;
  	col+=1.*mate*sca*sca;
    col*=0.2;
    col*=clamp(pow(length(p)/1.5,2.),0.,1.);
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

vec3 bg(vec2 p)
{
    vec3 col=vec3(0.05,0.25,0.05)*pow(fbm(p*4.),2.);
    col+=vec3(0.8,0.1,0.3)*pow(fbm(p*6.),15.)*80.;
    return clamp(col,0.,1.);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 q = fragCoord/iResolution.xy;
    vec2 p=q*2.0-1.;
    p.x*=iResolution.x/iResolution.y;

    vec3 ro=vec3(1,2,-6.);
    vec3 ta=vec3(0,0,0);
     // debugging camera
    float x_rot=-iMouse.x/iResolution.x*PI*2.0;
    float y_rot=iMouse.y/iResolution.y*3.14*0.5 + PI/2.0;
    if(iMouse.z>0.||iMouse.w>0.)
    	ro=vec3(0.,0,-3)+vec3(cos(y_rot)*cos(x_rot),cos(y_rot)*cos(x_rot),cos(y_rot)*sin(x_rot))*5.;
     
    vec3 f=normalize(ta-ro);
    vec3 r=normalize(cross(vec3(0,1,0),f));
    vec3 u=normalize(cross(f,r));
    
    vec3 rd=normalize(mat3(r,u,f)*vec3(p.x,p.y,2.8));
    
    vec3 col=bg(p);
    
    float t=0.01;
    t=intersect(ro,rd);
    if(t<FAR)
    {
        vec3 pos=ro+t*rd;
        vec3 n=get_normal(pos);
        col=lighting(ro, rd,n,t,pos);
    }
    float depth=clamp(0.033*t, 0.,1.);
	col=tonemap(col);
    col=pow(clamp(col,0.0,1.0),vec3(0.45));
    col*=0.5+0.5*pow(16.0*q.x*q.y*(1.0-q.x)*(1.0-q.y),0.7);  // vigneting
	fragColor=vec4(col.xyz,abs(.2-depth)*1.);
}