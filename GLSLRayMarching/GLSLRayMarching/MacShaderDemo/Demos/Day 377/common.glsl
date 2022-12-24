bool hit = false;
#define exposure 1.3
#define groundOffs vec3(0,1.3,0)

// Terrain
#define marchSteps 200
//#define marchEps  (mix(0.001,0.06,smoothstep(1.,0.,exp(-t*0.3) - 2.)))
#define marchEps  (mix(0.005,0.26,smoothstep(0.,1.,t*0.1 - 2.)))
#define distScale 0.8 

// Moutains 

#define marchStMountains 20.
#define marchEpsMount  0.4


// Clouds

#define cloudsLowerLimit 7.
#define cloudsHigherLimit 14.

#define cloudSteps 60.
#define volumetricDithAmt .05

// Wind
#define windSteps 10.
// Atmosphere
#define sunCol vec3(1,0.9,0.6)*1.
#define planetSz 2984.
#define atmoSz (planetSz/63.)


#define ambianceScale 0.4

#define itersAtmo 14.
#define itersOptic 14.
const float redLightLen = 740.;
const float greenLightLen = 550.;
const float blueLightLen = 450.;

const float transStrength = 0.02;

float densFalloff = 1.9;


#define sss(a) clamp(map(p + sunDir*a).x/a,0., 1.)
#define ao(a) clamp(map(p + (n*0.8 + sunDir)*a).x/a,0., 1.)

#define pi acos(-1.)

#define tau (2.*pi)
#define rot(a) mat2(cos(a),-sin(a),sin(a),cos(a))
#define pmod(p,a) mod(p - 0.*a,a) - 0.5*a
float valueNoise(vec3 p, float pw);
vec3 acesFilm(const vec3 x);
vec2 dmin(vec2 a, float b, float cmp){return a.x < b ? a : vec2(b,cmp);}
float turbulentNoise(vec3 p);
vec2 sphIntersect( in vec3 ro, in vec3 rd, in vec3 ce, float ra );
float atmosphericDensity( vec3 p);
float opticalDepth(vec3 p, vec3 rd, float len);
vec3 getAtmosphere(vec3 ro, vec3 rd, float t, out float opticalDepthView, vec3 sunPos);
mat3 getRd(vec3 ro, vec3 lookAt);
vec3 getRdSpherical(vec3 ro, inout vec2 uv);
vec3 hash3(vec3 p);
float r21(vec2 p);
float plaIntersect( in vec3 ro, in vec3 rd, in vec4 p );

vec3 acesFilm(const vec3 x) {
    const float a = 2.51;
    const float b = 0.03;
    const float c = 2.43;
    const float d = 0.59;
    const float e = 0.14;
    return clamp((x * (a * x + b)) / (x * (c * x + d ) + e), 0.0, 1.0);
}

/*
float r24(vec2 p){
    return texture(iChannel0,)[ int(mod(p.x))];
}*/

 

mat3 getOrthogonalBasis(vec3 direction){
    direction = normalize(direction);
    vec3 right = normalize(cross(vec3(0,1,0),direction));
    vec3 up = normalize(cross(direction, right));
    return mat3(right,up,direction);
}

float cyclicNoiseClouds(vec3 p, bool turbulent){
    float noise = 0.;
    
    float amp = 0.6;
    const float gain = 0.6;
    const float lacunarity = 1.8;
    const int octaves = 6;
    
    const float warp = 0.26;    
    float warpTrk = 1.2;
    const float warpTrkGain = 1.1;
    
    vec3 seed = vec3(-1.4,-2.,0.5);
    mat3 rotMatrix = getOrthogonalBasis(seed);
    
    for(int i = 0; i < octaves; i++){
        
        p += sin(p.zxy*warpTrk - 2.*warpTrk)*warp; 
        noise += sin(dot(cos(p), sin(p.zxy  )))*amp;
    
        p *= rotMatrix;
        p *= lacunarity;
        
        warpTrk *= warpTrkGain;
        amp *= gain;
    }
    
    if(turbulent){
        return max(-0. - (noise)*0.6,0.);
    
    }{
        return (noise*0.25 + 0.5);

    }
}


float cyclicNoiseTerrain(vec3 p, bool turbulent){
    float noise = 0.;
    
    float amp = 1.;
    const float gain = 0.6;
    const float lacunarity = 1.4;
    const int octaves = 4;
    
    const float warp = 0.4;    
    float warpTrk = 1. ;
    const float warpTrkGain = 1.2;
    
    vec3 seed = vec3(-1,-2.,0.5);
    mat3 rotMatrix = getOrthogonalBasis(seed);
    
    for(int i = 0; i < octaves; i++){
        
        p += sin(p.zxy*warpTrk - 2.*warpTrk)*warp; 
        noise += sin(dot(cos(p), sin(p.zxy )))*amp;
    
        p *= rotMatrix;
        p *= lacunarity;
        
        warpTrk *= warpTrkGain;
        amp *= gain;
    }
    
    if(turbulent){
        return 1. - abs(noise)*0.5;
    
    }{
        return (noise*0.25 + 0.5);

    }
}

float cyclicNoiseRocks(vec3 p, bool turbulent){
    float noise = 0.;
    
    float amp = 1.;
    const float gain = 0.3;
    const float lacunarity = 2.5;
    const int octaves = 3;
    
    const float warp = 0.4;    
    float warpTrk = 1. ;
    const float warpTrkGain = 1.2;
    
    vec3 seed = vec3(-5,-2.,0.5);
    mat3 rotMatrix = getOrthogonalBasis(seed);
    
    for(int i = 0; i < octaves; i++){
        
        p += sin(p.zxy*warpTrk - 2.*warpTrk)*warp; 
        noise += sin(dot(cos(p), sin(p.zxy )))*amp;
    
        p *= rotMatrix;
        p *= lacunarity;
        
        warpTrk *= warpTrkGain;
        amp *= gain;
    }
    
    if(turbulent){
        return 1. - abs(noise)*0.5;
    
    }{
        return (noise*0.25 + 0.5);

    }
}


float cyclicNoiseWind(vec3 p, bool turbulent){
    float noise = 0.;
    
    float amp = 1.;
    const float gain = 0.3;
    const float lacunarity = 2.5;
    const int octaves = 3;
    
    const float warp = 0.4;    
    float warpTrk = 1. ;
    const float warpTrkGain = 1.2;
    
    vec3 seed = vec3(-5,-2.,0.5);
    mat3 rotMatrix = getOrthogonalBasis(seed);
    
    for(int i = 0; i < octaves; i++){
        
        p += sin(p.zxy*warpTrk - 2.*warpTrk)*warp; 
        noise += sin(dot(cos(p), sin(p.zxy )))*amp;
    
        p *= rotMatrix;
        p *= lacunarity;
        
        warpTrk *= warpTrkGain;
        amp *= gain;
    }
    
    if(turbulent){
        return 1. - abs(noise)*0.5;
    
    }{
        return (noise*0.25 + 0.5);

    }
}


float cyclicNoiseGrass(vec3 p, bool turbulent){
    float noise = 0.;
    
    float amp = 1.;
    const float gain = 0.3;
    const float lacunarity = 2.5;
    const int octaves = 2;
    
    const float warp = 0.9;    
    float warpTrk = 1. ;
    const float warpTrkGain = 1.2;
    
    vec3 seed = vec3(-5,-2.,0.5);
    mat3 rotMatrix = getOrthogonalBasis(seed);
    
    for(int i = 0; i < octaves; i++){
        
        p += sin(p.zxy*warpTrk - 2.*warpTrk)*warp; 
        noise += sin(dot(cos(p), sin(p.zxy )))*amp;
    
        p *= rotMatrix;
        p *= lacunarity;
        
        warpTrk *= warpTrkGain;
        amp *= gain;
    }
    
    if(turbulent){
        return 1. - abs(noise)*0.5;
    
    }{
        return (noise*0.25 + 0.5);

    }
}


/*
float valueNoiseCheap(in vec3 p,float pw)
{
    vec3 ip = floor(p);
    vec3 fp = fract(p);
	fp = fp*fp*(3.0-2.0*fp);
	vec2 tap = (ip.xy+vec2(37.0,17.0)*ip.z) + fp.xy;
	vec2 rz = textureLod( iChannel0, (tap+0.5)/256.0, 0.0 ).yx;
	return mix( rz.x, rz.y, fp.z );
}*/


float valueNoise(vec3 p, float pw){
    
	vec3 s = vec3(1., 25, 75);
	
	vec3 ip = floor(p); // Unique unit cell ID.
    vec4 h = vec4(0., s.yz, s.y + s.z) + dot(ip, s);
    
	p -= ip; // Cell's fractional component.
	
    // A bit of cubic smoothing, to give the noise that rounded look.
    if(pw == 1.){
        p = p*p*(3. - 2.*p); 
    } else {
    
    	p = p*p*(p*(p * 6. - 15.) + 10.);
    }
    
    //p = smoothstep(0.,1.,p);
    // Smoother version of the above. Weirdly, the extra calculations can sometimes
    // create a surface that's easier to hone in on, and can actually speed things up.
    // Having said that, I'm sticking with the simpler version above.
	//p = p*p*(p*(p * 6. - 15.) + 10.);
    h = mix(fract(sin(h)*43758.5453), fract(sin(h + s.x)*43758.5453), p.x);
	
    // Interpolating along Y.
    h.xy = mix(h.xz, h.yw, p.y);
    
    // Interpolating along Z, and returning the 3D noise value.
    return mix(h.x, h.y, p.z); // Range: [0, 1].
	
}

vec3 hash3(vec3 p) {
	p = vec3(dot(p, vec3(127.1, 311.7, 74.7)),
			dot(p, vec3(269.5, 183.3, 246.1)),
			dot(p, vec3(113.5, 271.9, 124.6)));

	return -1.0 + 2.0 * fract(sin(p) * 43758.5453123);
}

float r21(vec2 p)
{
	vec3 p3  = fract(vec3(p.xyx) * .1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}
vec2 r23(vec3 p3)
{
	p3 = fract(p3 * vec3(.1031, .1030, .0973));
    p3 += dot(p3, p3.yzx+33.33);
    return fract((p3.xx+p3.yz)*p3.zy);
}
float turbulentNoise(vec3 p, bool md) {
	p += 8.;
    vec3 i = floor(p);
	vec3 f = fract(p);

	vec3 u = f * f * (3.0 - 2.0 * f);

    //f = u;
	float n0 = dot(hash3(i + vec3(0.0, 0.0, 0.0)), f - vec3(0.0, 0.0, 0.0));
	float n1 = dot(hash3(i + vec3(1.0, 0.0, 0.0)), f - vec3(1.0, 0.0, 0.0));
	float n2 = dot(hash3(i + vec3(0.0, 1.0, 0.0)), f - vec3(0.0, 1.0, 0.0));
	float n3 = dot(hash3(i + vec3(1.0, 1.0, 0.0)), f - vec3(1.0, 1.0, 0.0));
	float n4 = dot(hash3(i + vec3(0.0, 0.0, 1.0)), f - vec3(0.0, 0.0, 1.0));
	float n5 = dot(hash3(i + vec3(1.0, 0.0, 1.0)), f - vec3(1.0, 0.0, 1.0));
	float n6 = dot(hash3(i + vec3(0.0, 1.0, 1.0)), f - vec3(0.0, 1.0, 1.0));
	float n7 = dot(hash3(i + vec3(1.0, 1.0, 1.0)), f - vec3(1.0, 1.0, 1.0));

	float ix0 = mix(n0, n1, u.x);
	float ix1 = mix(n2, n3, u.x);
	float ix2 = mix(n4, n5, u.x);
	float ix3 = mix(n6, n7, u.x);

	float ret = mix(mix(ix0, ix1, u.y), mix(ix2, ix3, u.y), u.z) * 0.5 + 0.5;
	ret = ret * 1.;
    
    //ret = 1.- ret;
    //ret = abs(ret);
    if (md)
        ret = mix(ret,smoothstep(0.3,1.,ret*0.8),0.6);
    return ret;
}



vec2 sphIntersect( in vec3 ro, in vec3 rd, in vec3 ce, float ra )
{
    vec3 oc = ro - ce;
    float b = dot( oc, rd );
    float c = dot( oc, oc ) - ra*ra;
    float h = b*b - c;
    if( h<0.0 ) return vec2(-1.0); // no intersection
    h = sqrt( h );
    //return -b+h;
    //return max(max(-b-h,0.),max(-b+h,0.));
    return vec2( -b-h, -b+h );
}
float plaIntersect( in vec3 ro, in vec3 rd, in vec4 p )
{
    return -(dot(ro,p.xyz)+p.w)/dot(rd,p.xyz);
}


float atmosphericDensity( vec3 p){
    float fact = (p.y - planetSz )/atmoSz;
    fact = max(fact, 0.0001);
    return exp(-fact*densFalloff)*pow(max(1. - fact,0.),0.04);//*pow(smoothstep(0.95,0.84,fact),1.);
}

float opticalDepth(vec3 p, vec3 rd, float len){
    float stSz = len / (itersOptic-1.);
    float depth = 0.;
    for(float opticIdx = 0.; opticIdx < itersOptic; opticIdx++ ){
        depth += atmosphericDensity(p) * stSz;
        p += rd*stSz;
     }
    return depth;
}


vec3 scatteringCoefficients = transStrength*vec3(
    pow(400./redLightLen,4.),
    pow(400./greenLightLen,4.),
    pow(400./blueLightLen,4.)
);
vec3 getAtmosphere(vec3 ro, vec3 rd, float t, out float opticalDepthView, vec3 sunPos){
    vec3 accumAtmo = vec3(0);
    float atmoMarchLen = 0.;
    
    vec3 offs = vec3(0,planetSz ,0);
    vec3 p = ro;
    sunPos += offs;
    
    p += offs*1.;
    
    
    float lenViewDirToEndOfAtmosphere = sphIntersect( p, rd, vec3(0), planetSz + atmoSz ).y;
    
    if(hit){
        atmoMarchLen = mix(t,lenViewDirToEndOfAtmosphere,smoothstep(0.,1.,t/50. - 1.));
    } else {
        atmoMarchLen = lenViewDirToEndOfAtmosphere;
    }
    float stepSz = atmoMarchLen/(itersAtmo - 1.);
    

    for(float atmoIdx = 0.; atmoIdx < itersAtmo ; atmoIdx++ ){
        vec3 dirToSun = normalize(sunPos - p);
        float lenSunDirToEndOfAtmosphere = sphIntersect( p, dirToSun, vec3(0), planetSz + atmoSz ).y;
        lenViewDirToEndOfAtmosphere = sphIntersect( p, -rd, vec3(0), planetSz + atmoSz ).y;
        
        float opticalDepthSun = opticalDepth(p, dirToSun, lenSunDirToEndOfAtmosphere);
        opticalDepthView = opticalDepth(p, -rd, stepSz*atmoIdx);
        
        float localDens = atmosphericDensity(p);
        

        vec3 transmittance = exp(-(opticalDepthSun + opticalDepthView) * scatteringCoefficients);        
        accumAtmo += transmittance * localDens * scatteringCoefficients * stepSz;
        
        p += rd * stepSz;
    }
    
    return accumAtmo;
}

mat3 getRd(vec3 ro, vec3 lookAt){
    vec3 dir = normalize(lookAt - ro);
    vec3 right = normalize(cross(vec3(0,1,0),dir));
    vec3 up = normalize(cross(dir,right));
    
    return mat3(right,up,dir); 
}


// Tri-Planar blending function. Based on an old Nvidia tutorial.
vec3 tex3D( sampler2D tex, in vec3 p, in vec3 n ){
  
    n = max((abs(n) - 0.2)*7., 0.001); // max(abs(n), 0.001), etc.
    n /= (n.x + n.y + n.z );  
    
	return (texture(tex, p.yz)*n.x + texture(tex, p.zx)*n.y + texture(tex, p.xy)*n.z).xyz;
}

vec3 getRdSpherical(inout vec2 uv){
    
    // polar coords
    uv = vec2(atan(uv.y,uv.x),length(uv));
    
    vec2 ouv = uv;
    uv += 0.5;
    uv.y *= pi;
    
    
    // parametrized sphere
    vec3 offs = vec3(cos(uv.y)*cos(uv.x),sin(uv.y),cos(uv.y)*sin(uv.x));
    
    // insert camera rotations here
    offs.yz *= rot(-(1.)*pi);
    
    //vec3 lookAt = ro + offs;
    //vec3 v = normalize(lookAt - ro);
    vec3 v = offs;
    //uv = ouv;
    //uv.x = v.x;
    //uv.y = v.y;
    
    return v;
}

float sdVerticalCapsule( vec3 p, float h, float r )
{
  p.y -= clamp( p.y, 0.0, h );
  return length( p ) - r;
}
float sdRoundCone( vec3 p, float r1, float r2, float h )
{
  vec2 q = vec2( length(p.xz), p.y );
    
  float b = (r1-r2)/h;
  float a = sqrt(1.0-b*b);
  float k = dot(q,vec2(-b,a));
    
  if( k < 0.0 ) return length(q) - r1;
  if( k > a*h ) return length(q-vec2(0.0,h)) - r2;
        
  return dot(q, vec2(a,b) ) - r1;
}

float opSmoothUnion( float d1, float d2, float k ) {
    float h = clamp( 0.5 + 0.5*(d2-d1)/k, 0.0, 1.0 );
    return mix( d2, d1, h ) - k*h*(1.0-h); }

float opSmoothSubtraction( float d1, float d2, float k ) {
    float h = clamp( 0.5 - 0.5*(d2+d1)/k, 0.0, 1.0 );
    return mix( d2, -d1, h ) + k*h*(1.0-h); }

float opSmoothIntersection( float d1, float d2, float k ) {
    float h = clamp( 0.5 - 0.5*(d2-d1)/k, 0.0, 1.0 );
    return mix( d2, d1, h ) + k*h*(1.0-h); }

vec3 opRepLim( in vec3 p, in float c, in vec3 l )
{
    vec3 q = p-c*clamp(round(p/c),-l,l);
    return q;
}