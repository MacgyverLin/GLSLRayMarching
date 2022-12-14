// "Silverall"
// 2021
// by Awayko Wakee
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

#define antialias

#define MAX_STEPS 100
#define MAX_DIST 50.
#define SURF_DIST .001

// Antialias. Change from 1 to 2 or more AT YOUR OWN RISK! It may CRASH your browser while compiling!
// from https://www.shadertoy.com/view/XdVSRV
const float aawidth = 0.8;
const int aasamples = 1;

mat2 Rot(float a) {
    float s=sin(a), c=cos(a);
    return mat2(c, -s, s, c);
}

// https://iquilezles.org/articles/distfunctions
float sdSphere( vec3 p, float s ){
  return length(p)-s;
}
// https://iquilezles.org/articles/distfunctions
float opSmoothUnion( float d1, float d2, float k ) {
    float h = clamp( 0.5 + 0.5*(d2-d1)/k, 0.0, 1.0 );
    return mix( d2, d1, h ) - k*h*(1.0-h); }
// https://iquilezles.org/articles/distfunctions
float opSmoothSubtraction( float d1, float d2, float k ) {
    float h = clamp( 0.5 - 0.5*(d2+d1)/k, 0.0, 1.0 );
    return mix( d2, -d1, h ) + k*h*(1.0-h); }
// https://iquilezles.org/articles/distfunctions
float opSmoothIntersection( float d1, float d2, float k ) {
    float h = clamp( 0.5 - 0.5*(d2-d1)/k, 0.0, 1.0 );
    return mix( d2, d1, h ) + k*h*(1.0-h); }
// https://iquilezles.org/articles/fbmsdf
float sph( vec3 i, vec3 f, vec3 c )
{
    // random radius at grid vertex i+c (please replace this hash by
    // something better if you plan to use this for a real application)
    vec3  p = 17.0*fract( (i+c)*0.3183099+vec3(0.11,0.17,0.13) );
    float w = fract( p.x*p.y*p.z*(p.x+p.y+p.z) );
    float r = 0.7*w*w;
    // distance to sphere at grid vertex i+c
    return length(f-c) - r; 
}
// https://iquilezles.org/articles/smin
float smin( float a, float b, float k )
{
    float h = max(k-abs(a-b),0.0);
    return min(a, b) - h*h*0.25/k;
}
// https://iquilezles.org/articles/smin
float smax( float a, float b, float k )
{
    float h = max(k-abs(a-b),0.0);
    return max(a, b) + h*h*0.25/k;
}
// https://iquilezles.org/articles/fbmsdf
float sdBase( in vec3 p )
{
    vec3 i = floor(p);
    vec3 f = fract(p);
    return min(min(min(sph(i,f,vec3(0,0,0)),
                       sph(i,f,vec3(0,0,1))),
                   min(sph(i,f,vec3(0,1,0)),
                       sph(i,f,vec3(0,1,1)))),
               min(min(sph(i,f,vec3(1,0,0)),
                       sph(i,f,vec3(1,0,1))),
                   min(sph(i,f,vec3(1,1,0)),
                       sph(i,f,vec3(1,1,1)))));
}
// https://iquilezles.org/articles/fbmsdf
float sdFbm( vec3 p, float d )
{
   float s = 1.;
   for( int i=0; i<4; i++ )
   {
       // evaluate new octave
       float n = s*sdBase(p);
	
       // add
       n = smax(n,d-0.1*s,0.4*s);
       d = smin(n,d      ,0.4*s);
	
       // prepare next octave
       p = mat3( 0.00, 1.60, 1.20,
                -1.60, 0.72,-0.96,
                -1.20,-0.96, 1.28 )*p;
       s = 0.5*s;
   }
   return d;
}

// MAP
float map(vec3 p) {
    
    float t = iTime;
    vec3 pGrnd = p;
    vec3 pCam = p;

    p.xy *= Rot(p.z*sin(iTime*.1)*.01);
    p.xz *= Rot(sin(iTime*.05)*.5);
    p.z -= iTime*.2;
    p.y += sin(iTime*.23);

    // PLANE
    p += vec3(0,-2,0);
    float plane = dot(p, normalize(vec3(0,1,0)));
    plane -= sin(p.x*.71+iTime*.63) + sin(p.x*.26+iTime*.27) +
             cos(p.z*.33+iTime*.19) + sin(p.z*.31+iTime*.11);
    plane -= smoothstep(-3.,3.,sin(1.2*p.x)+sin(1.23*p.y)+cos(1.13*p.z));
    
    // GYROID
    //thanks to https://www.shadertoy.com/user/BigWIngs
    //for the great gyroid tutorial https://www.youtube.com/watch?v=-adHIyjIYgk&t=1518s
    
    float bias = 1.8;
    float thickness = 0.3; 
    float scale = 2.;
    p *= scale;
    
    float g = abs(dot(sin(p*.39),cos(p.zxy*.63))-bias)/scale-thickness;   
    
    // combining cutting PLANE and GYROID
    float d = opSmoothIntersection(plane, g, .3);

    // substracting SPHERE around camera
    float r = .5;
    float camSph = sdSphere(pCam-vec3(0,0,3), r);
    camSph -= smoothstep(-1.3,1.3,sin(.5*p.x)+sin(.8*p.y)+cos(.23*p.z));   
    d = opSmoothSubtraction( -d, -camSph, .9);
    
    // adding NOISE to the GYROID surface
    d = sdFbm(p, d);
    
    // GROUND
    pGrnd.y += 4.5;
    float ground = dot(pGrnd+vec3(0,1,0), normalize(vec3(0,1,0)));
    ground -= sin(pGrnd.x*.23+iTime*.2)*.45 + cos(pGrnd.z*.31+iTime*.3)*.8;

    d = opSmoothUnion(d, ground, 0.5);
    
    return d;
}

float castRay(vec3 ro, vec3 rd) {
	
    float dO=0.;
    for(int i=0; i<MAX_STEPS; i++) {
    	vec3 p = ro + rd*dO;
        
        float dS = map(p);
        if(dS<SURF_DIST) break;
        
        dO += dS;
        if(abs(dO)>MAX_DIST) break;
    }
    if(abs(dO)>MAX_DIST) dO=-1.;
    
    return dO;
}

vec3 calcNormal(vec3 p) {
	float d = map(p);
    vec2 e = vec2(.0001, 0);
    
    vec3 n = d - vec3(
            map(p-e.xyy),
            map(p-e.yxy),
            map(p-e.yyx));
    
    return normalize(n);
}

vec3 GetRayDir(vec2 uv, vec3 p, vec3 l, float z) {
    vec3 f = normalize(l-p),
        r = normalize(cross(vec3(0,1,0), f)),
        u = cross(f,r),
        c = f*z,
        i = c + uv.x*r + uv.y*u,
        d = normalize(i);
    return d;
}

float calcAO( in vec3 p, in vec3 n){
	float occ = 0.0;
    float sca = 1.0;
    for( int i=min(iFrame,0); i<5; i++ )
    {
        float h = 0.01 + 0.12*float(i)/4.0;
        float d = map(p+h*n);
        occ += (h-d)*sca;
        sca *= 0.95;
    }
    return clamp( 1.0 - 3.0*occ, 0.0, 1.0 );
}

vec4 render(vec2 fragCoord){
    vec2 uv = (fragCoord-.5*iResolution.xy)/iResolution.y;
	vec2 m = iMouse.xy/iResolution.xy;

    // CAMERA
    vec3 ro = vec3(0, 0, 3);
    vec3 lookAt = vec3(cos(iTime*.1)*10.,sin(iTime*.2)*1.5-1.,0);//
    vec3 rd = GetRayDir(uv, ro, lookAt, .8);
    
    // SKY
    vec3 col = texture(iChannel0, rd).rgb;
    col = mix( col, vec3(0.2, 0.2, .2), exp(-4.0*max(rd.y,0.)) );
    
    // RAYMARCHING
    float d = castRay(ro, rd);
    
    if(d > 0.0) {
        vec3 p = ro + rd * d;
        vec3 n = calcNormal(p);
        vec3 r = reflect(rd, n);

        // REFLECTION
        vec3 ref = texture(iChannel0, r).rgb;
        
        // LIGHTING
        vec3  lDir = normalize(vec3(-.1,.4,.3));
        float dif = clamp(dot(n, lDir),0.,1.);
        float sunSha = step(castRay(p+n*0.01, lDir),0.);
        float skyDif = clamp(.5+.5*dot(n, vec3(0,1,0)),0.,1.);
        
        col *= ref;
        col *= 20. * dif * sunSha;
        col *= calcAO(p,n);
        col += ref * vec3(.7) * skyDif;        
    }

    // FOG
    col = mix( col, vec3(.2), 1.-exp( -0.0001*d*d*d ) );
    
    // COMPRESS        
    col = 1.35*col/(1.0+col);   
        
    // GAMMA
    col = pow( col, vec3(0.4545) );    
    
    // OUTPUT
    return vec4(col, 1.);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
// ANTIALIASING from https://www.shadertoy.com/view/XdVSRV
    #ifdef antialias
    vec4 vs = vec4(0.);
    for (int j=0;j<aasamples ;j++)
    {
       float oy = float(j)*aawidth/max(float(aasamples-1), 1.);
       for (int i=0;i<aasamples ;i++)
       {
          float ox = float(i)*aawidth/max(float(aasamples-1), 1.);
          vs+= render(fragCoord + vec2(ox, oy));
       }
    }
    vec2 uv = fragCoord.xy / iResolution.xy;
    fragColor = vs/vec4(aasamples*aasamples);
    #else
    fragColor = render(fragCoord);
    #endif
    
   
}