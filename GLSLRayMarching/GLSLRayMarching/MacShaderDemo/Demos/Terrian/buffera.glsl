// Created by evilryu
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

// Just another practice of terrian
// Inspired by:
// iq's Rainforest: https://www.shadertoy.com/view/4ttSWf
// Shane's Dry Rocky Gorge: https://www.shadertoy.com/view/lslfRN

#define PI 3.14159265
//#define AA

vec2 hash2(vec2 p) 
{
    const vec2 k = vec2(0.3183099, 0.3678794);
    p = p*k + k.yx;
    return fract( 16.0 * k*fract( p.x*p.y*(p.x+p.y)) );
}

vec2 hash2(float n) 
{ 
    return fract(sin(vec2(n,n+1.0))*vec2(43758.5453123,22578.1459123)); 
}

float hash1(vec2 p)
{
    p  = 50.0*fract( p*0.3183099 );
    return fract( p.x*p.y*(p.x+p.y) );
}

float noise(vec2 x)
{
    vec2 p = floor(x);
    vec2 w = fract(x);
    vec2 u = w*w*w*(w*(w*6.0-15.0)+10.0);
    
    float a = hash1(p+vec2(0,0));
    float b = hash1(p+vec2(1,0));
    float c = hash1(p+vec2(0,1));
    float d = hash1(p+vec2(1,1));
    
    return -1.0+2.0*(a + (b-a)*u.x + (c-a)*u.y + (a - b - c + d)*u.x*u.y);
}

const mat2 m2 = mat2(  0.80,  0.60,
                      -0.60,  0.80 );

float cloud(vec2 x)
{
    float f = 2.;
    float s = 0.5;
    float a = 0.0;
    float b = 0.5;
    for(int i=0; i<3+min(0,iFrame); i++)
    {
        float n = noise(x);
        a += b*n;
        b *= s;
        x = f*m2*x;
    }
	return a;
}

float terrian(vec2 p)
{    
    p*=0.0045;
    float f = 2.;
    float s = 0.5;
    float a = 0.0;
    float b = 0.5;
    for(int i=0; i<9+min(0,iFrame); i++)
    {
        float n = noise(p);
        a += b*n;
        b *= s;
        p = f*m2*p;
    }
	
    a=smoothstep(-0.5,0.7,a);
    
    return a*300.;
}


vec3 terrian_normal(vec2 pos, float t)
{   
    vec2 e = vec2(0.001*t,0.0);
	return normalize(vec3(terrian(pos-e.xy)-terrian(pos+e.xy),
                           2.0*e.x,
                           terrian(pos-e.yx)-terrian(pos+e.yx)));
}

// log-bisection tracing from Nimitz: https://www.shadertoy.com/view/4sSXz
float march_terrian(vec3 ro, vec3 rd, float tmin, float tmax)
{
    float t = tmin;
    vec3 p=ro+t*rd;
    float d=p.y-terrian(p.xz);

    float sgn=sign(d);
    float told=t;
    bool bisect=false;
        
    for (int i=0;i<256+min(0,iFrame);i++)
    {
        if(abs(d)<0.002*t || t>tmax) break;            
       	if(sign(d)!=sgn)
        {
            bisect=true;
            break;
        }
        
        told=t;
        if(d>1.)t+=d*0.4;
        else t+=log(abs(d)+1.1)*1.;
        p=ro+t*rd;
       	d=p.y-terrian(p.xz);
    }
    
    if(bisect)
    {
        float m = 0.;
        p=ro+told*rd;
        sgn=sign(p.y-terrian(p.xz));
        for(int i=0; i<6; i++)
        { 
            m=(told+t)*.5;
            p=ro+rd*m;
            d=p.y-terrian(p.xz);
            if(abs(d)<0.002*t)break;
            d*sgn<0. ? t=m : told=m;
        }
        t=(told+t)*.5;
    }
    return t;
}


float water(vec2 p)
{
    p*=0.05;
	float f = 2.;
    float s = 0.4;
    float a = 0.0;
    float b = 0.5;
    for(int i=0; i<5+min(0,iFrame); i++)
    {
        float n = noise(vec2(p.x+10.,p.y-iTime*2.));
        a += b*n;
        b *= s;
        p = f*m2*p;
    }
	return 3.*a;
}

vec3 water_normal(vec2 pos, float t) 
{
	vec2 e=vec2(1e-7*t*t*t,0.0);
    return normalize(vec3(water(pos-e.xy)-water(pos+e.xy),
                          2.0*e.x,
                          water(pos-e.yx)-water(pos+e.yx)));
}

float intersect_water(vec3 ro, vec3 rd)
{
    float t=2000.;
    if(rd.y <-0.01)
    {
      	float t0=-(ro.y-20.)/rd.y;
      	t=min(t,t0);
    }
    return t;
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

float terrian_shadow(vec3 ro, vec3 rd, vec2 fragCoord)
{
    float res=1.0;
    float t=.5+0.5*hash1(fragCoord);

    float h;    
    for(int i=0;i<20+min(0,iFrame);i++)
    {
        vec3 p=ro+t*rd;
        h=p.y-terrian(p.xz);
        res=min(16.0*h/t, res);
        t+=clamp(h,1.+.1*t,30.);
        if(res<0.001*t)
            break;
    }
    return clamp(res, 0., 1.);
}     


vec3 sun_dir=normalize(vec3(-1., 1.5,-.6));
vec3 sun_col=2.*vec3(1.);

vec3 terrian_material(vec3 pos, vec3 n)
{
    float tree_pdf=smoothstep(0.,.5,n.y);
    tree_pdf*=1.-smoothstep(20.,50.,pos.y);
    vec3 mate=pow(texcube(iChannel1, pos*0.008, n).xyz,vec3(3.));
    mate=mix(mate, .05*vec3(.7, 1., .2), tree_pdf);
    tree_pdf=smoothstep(0.2,.3,n.y)*smoothstep(50.,200.,pos.y);
    mate=mix(mate, .08*vec3(.5, 1., .2), tree_pdf);
	return mate;
}

vec3 render_terrian(vec3 ro, vec3 rd, float t, vec2 fragCoord)
{
    vec3 pos=ro+t*rd;
    vec3 n=terrian_normal(pos.xz, t);

    vec3 sky=vec3(0.2,0.7,1.);
    
    vec3 mate=terrian_material(pos, n);
    n=bump_mapping(pos*.1,n,0.15);
    float sha=terrian_shadow(pos+.5*n, sun_dir, fragCoord);
    float dif=max(0.,dot(n,sun_dir));
    float bac=max(0.,dot(n,-sun_dir));
    float amb=max(0.,dot(n,vec3(0,1,0)));
    vec3 Lo=6.0*dif*sun_col*sha;
    Lo+=0.5*bac*sun_col;
    Lo+=3.5*amb*sky;
   	Lo*=smoothstep(-1.,10.,pos.y);
    return Lo*mate*0.2;        
}


vec3 render_water(vec3 ro, vec3 rd, float t, float t1, vec2 fragCoord, vec3 sky)
{
    vec3 pos=ro+t*rd;
    vec3 n=water_normal(pos.xz, t);

    vec3 mate=vec3(.8,.9,1.)*0.5;

    float sha=terrian_shadow(pos+.1*n, sun_dir, fragCoord);
    float dif=max(0.,dot(n,sun_dir));
    float amb=max(0.,dot(n,vec3(0,1,0)));
    float fre=clamp(1.0+dot(rd,n), .0, 1.); 
    vec3 refl=reflect(rd,n);
    vec3 refr=refract(rd,n,1./1.33);
    float spe=max(0.0, pow(clamp(dot(sun_dir, refl), 0.0, 1.0), 5.0));

    vec3 Lo=4.0*dif*sun_col*sha;
    Lo+=1.*amb*sky;
    Lo+=2.5*pow(fre,8.)*vec3(1.);
    Lo+=2.5*spe*vec3(1.);
	vec3 col=Lo*mate*0.2;
    
    float t_terrian=march_terrian(pos+1.*n, refl, 0.5, 500.);
    vec3 reflcol=sky*.5;
    
    float falloff=0.;
    
    if(t_terrian<500.) 
    {
        falloff=1.-smoothstep(0.5,500.,t_terrian);
        reflcol=.4*falloff*falloff*render_terrian(pos+1.*n, refl, t_terrian, fragCoord);
    }

    vec3 refrcol=render_terrian(ro, rd, t1, fragCoord);
    
    falloff=1.-smoothstep(0.5,500.,t1-t);
    col=mix(col,refrcol,falloff*falloff);
      
    col=mix(col, reflcol, fre);   
    return col;
}

// sky from iq's rainforest  https://www.shadertoy.com/view/4ttSWf
vec3 render_sky(vec3 ro, vec3 rd)
{
    // darker on top of the head
    vec3 col=0.9*vec3(0.4,0.65,1.0)-rd.y*vec3(0.4,0.36,0.4);

    float t=(1000.0-ro.y)/rd.y;
    if(t>0.0)
    {
        vec2 uv=(ro+t*rd).xz-vec2(4710.,235.);
        float cl=cloud(uv*0.0015);
        float dl=smoothstep(-0.2,0.6,cl);
        col=mix(col, vec3(1.0), 0.6*dl);
    }
    
	// sun glare    
    float sun=clamp(dot(sun_dir,rd), 0.0, 1.0);
    col+=0.6*vec3(1.0,0.6,0.3)*pow(sun, 32.0);
    
	return col;
}

vec3 scene(vec3 ro, vec3 rd, vec2 fragCoord, out float t)
{
    vec3 bg=vec3(.6,.8,1.1);
    vec3 col=render_sky(ro, rd);
    float t0=intersect_water(ro,rd);
    float t1=march_terrian(ro, rd, 50., 2000.);
    t=min(t0,t1);
    
  	if(t>=2000.) return col;
        
    if(t1<t0)
    {
        col=render_terrian(ro, rd, t1, fragCoord);  
    }
    else
    {
        col=render_water(ro, rd, t0, t1, fragCoord, col);
    }
    
    float sun=clamp(dot(sun_dir,rd), 0.0, 1.0);
    col+=0.25*vec3(1.0,0.4,0.2)*pow(sun, 4.0);
    col=mix(col,bg, 1.0-exp(-1.5e-7*t*t) );
    
    return col;
}


vec3 tonemap(vec3 x) 
{
    const float a = 2.51;
    const float b = 0.03;
    const float c = 2.43;
    const float d = 0.59;
    const float e = 0.14;
    return (x * (a * x + b)) / (x * (c * x + d) + e);
}

mat3 camera(vec3 ro, vec3 ta)
{
    vec3 f=normalize(ta-ro);
    vec3 r=normalize(cross(f,vec3(0,1,0)));
    vec3 u=normalize(cross(r,f));
    return mat3(r,u,f);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 q=fragCoord.xy/iResolution.xy;
    vec2 p=q*2.-1.;
    p.x*=iResolution.x/iResolution.y;
    vec3 ro=vec3(0.,100.,-iTime*100.);
    vec3 ta=ro+vec3(0,-0.1,-1.);
        
   	mat3 cam=camera(ro, ta); 
    vec3 rd=normalize(cam*vec3(p.xy,PI/2.));
    vec3 col=vec3(0.6,0.8,1.1);

    float t=0.;
    
    col=scene(ro,rd,fragCoord.xy, t);
    
    col=tonemap(col);
    col=pow(clamp(col,0.0,1.0),vec3(0.45)); 
    col=pow(col,vec3(0.85,1.,0.95));
    
 #ifdef AA 
	// temporal AA from iq's Rainforest: https://www.shadertoy.com/view/4ttSWf
    vec2 o=hash2(float(iFrame))-0.5;

    mat4 old_cam=mat4(textureLod(iChannel0,vec2(0.5,0.5)/iResolution.xy, 0.0),
                      textureLod(iChannel0,vec2(1.5,0.5)/iResolution.xy, 0.0),
                      textureLod(iChannel0,vec2(2.5,0.5)/iResolution.xy, 0.0),
                      0.0, 0.0, 0.0, 1.0 );
    
    // world space
    vec4 wpos=vec4(ro + rd*t,1.0);
    // camera space
    vec3 cpos=(wpos*old_cam).xyz; // note inverse multiply
    // ndc space
    vec2 npos=PI/2. * cpos.xy / cpos.z;
    // screen space
    vec2 spos=0.5 + 0.5*npos*vec2(iResolution.y/iResolution.x,1.0);
    // undo dither
    spos-=o/iResolution.xy;
	// raster space
    vec2 rpos=spos * iResolution.xy;
    
    if(rpos.y<1.0 && rpos.x<3.0)
    {
    }
	else
    {
        vec3 ocol=textureLod(iChannel0, spos, 0.0).xyz;
    	if(iFrame==0) ocol=col;
        col=mix(ocol, col, 0.4);
    }

    //----------------------------------
                           
	if( fragCoord.y<1.0 && fragCoord.x<3.0 )
    {
        if(abs(fragCoord.x-2.5)<0.5) 
            fragColor=vec4(cam[2], -dot(cam[2],ro));
        if(abs(fragCoord.x-1.5)<0.5) 
            fragColor=vec4(cam[1], -dot(cam[1],ro));
        if(abs(fragCoord.x-0.5)<0.5) 
            fragColor=vec4(cam[0], -dot(cam[0],ro));
    }
    else
#endif
    {
        fragColor.xyz=col;;
    }
}