// Author: Denis Leitner
// Title: Procedurally generated landscape in fragment shader
// Master Thesis 
// VUT FIT Brno, 2022

// License: Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License

//#define LOW_QUALITY

// ============= Performance/quality tweaking parameters =================== 

#ifndef LOW_QUALITY
// default quality

    // terrain rendering
    #define MAX_RENDERING_DISTANCE 150.0e3
    #define MAX_MARCHING_STEPS 400
    #define MAX_MARCHING_STEPS_SHADOW 100
    
    // texturing
    #define TEXTURE_LOW_QUALITY 0
    #define TEXTURE_FILTERING 0
    #define FILTERING_SAMPLES 4
    
    // atmosphere rendering
    #define ATMOS_STEPS 64
    #define ATMOS_LIGHT_STEPS 16
    
    // cloud rendering
    #define CLOUD_STEPS 64
    #define CLOUD_LIGHT_STEPS 6
    
#else
// low quality - no clouds

    // terrain rendering
    #define MAX_RENDERING_DISTANCE 75.0e3
    #define MAX_MARCHING_STEPS 300
    #define MAX_MARCHING_STEPS_SHADOW 80
    
    // texturing
    #define TEXTURE_LOW_QUALITY 1
    #define TEXTURE_FILTERING 0
    #define FILTERING_SAMPLES 4
    
    // atmosphere rendering
    #define ATMOS_STEPS 24
    #define ATMOS_LIGHT_STEPS 8
    
    // cloud rendering
    #define CLOUD_STEPS 0
    #define CLOUD_LIGHT_STEPS 0
#endif

// ========================================================================== 



// ====================== Cloud params ===================================

#define CLOUDS_SCALE 0.1e-3
#define CLOUDS_HEIGHT 8000.0
#define CLOUDS_SPEED vec3(0.25, 0.037, 0.0)*0.5
#define CLOUDS_THICKNESS 3500.0
#define CLOUD_SMOOTHNESS 0.65
#define CLOUD_COVERAGE 0.5
#define DENSITY 1.0
#define ABSORPTION 5.e-5
#define SCATTERING 7.e-4
#define SUN_INTENSITY_CLOUDS 20.0
#define AMBIENT_LIGHT_STRENGTH_CLOUDS 5.0


// energy conservative scattering integration based on https://www.shadertoy.com/view/XlBSRz
// bool (0 | 1)
#define IMPROVED_INTEGRATION 1

// randomly offsets starting position of the ray to eliminate banding artefacts
// bool (0 | 1)
#define RANDOM_RAY_OFFSET 1

// Clouds phase function params
#define FORWARD_SCATTERING_G 0.8
#define BACKWARD_SCATTERING_G 0.5
#define INTERPOLATION 0.5

// ========================================================================


// ====================== Terrain params ==================================

// === Ridged fractal ===
#define SCALE 0.075e-3
#define TERRAIN_OFFSET vec2(12.5e3, 37.1e3)
#define TERRAIN_AMPLITUDE 4.4e3 
#define SMOOTHNESS 1.3
#define SMOOTH_RIDGES 1

// === Hybrid fractal ===
/*#define SCALE 0.1e-3
#define TERRAIN_OFFSET vec2(12.5e3, 37.1e3)
#define TERRAIN_AMPLITUDE 2.3e3
#define SMOOTHNESS 0.25*/

#define OCTAVES 10
#define OCTAVES_SHADOW 7
#define OCTAVES_NORMAL 12

// ========================================================================


// bool (0 | 1)
#define MOVING_CAM 1
#define CAM_HEIGHT 2300.0
#define CAM_SPEED  1200.0

#define CAM_ANGLE_Y radians(-15.0)
#define CAM_ANGLE_X radians(90.0)

const vec3 CamDir = normalize( vec3(sin(CAM_ANGLE_X)*cos(CAM_ANGLE_Y), 
                                   sin(CAM_ANGLE_Y),
                                   cos(CAM_ANGLE_X)*cos(CAM_ANGLE_Y) ));

// =================== Sun position in the sky =============================

#define SUN_ANGLE_Y radians(25.0)
#define SUN_ANGLE_X radians(-145.0)

// ========================================================================


const float SunIntensityGround = 1.5; // 1.5 - (0.7*CLOUD_COVERAGE);
const vec3 Light = normalize( vec3(sin(SUN_ANGLE_X)*cos(SUN_ANGLE_Y), 
                                   sin(SUN_ANGLE_Y),
                                   cos(SUN_ANGLE_X)*cos(SUN_ANGLE_Y) ));

// rendering consts
#define MIN_DIST 0.001
#define SHADOW_SOFTNESS 32.0 

#define FAR_PLANE (MAX_RENDERING_DISTANCE)
#define NEAR_PLANE 1.0

#define PI 3.14159
#define PI2 6.28318531
#define FLT_MAX 3.402823466e+38

// Trick by Inigo Quilez to prevent loop unrolling
// decreases compilation time and might increases performance on some GPUs
// see comment section in https://www.shadertoy.com/view/4ttSWf
#define ZERO (min(iFrame,0))

vec3 camPosition;
vec2 pixelCoord;

struct Sphere
{
	vec3 center;
	float radius;
};

struct Ray
{
	vec3 origin;
	vec3 dir;
};

struct Atmosphere
{
    float planetRadius;
    float atmosphereRadius;
    vec3 scatteringR;
    vec3 scatteringM;
    
    // atmosphere thickness if atmosphere was uniform density 
    float Hr;  // for Rayleigh scattering
    float Hm;  // for Mie scattering
};

// Rayleigh scattering coefficients 
// for rgb wavelengths at sea level [m^(-1)]
const vec3 scatteringR = vec3(5.5e-6, 13.5e-6, 33.1e-6); 

// Mie scattering coefficients 
// for rgb wavelengths at sea level [m^(-1)]
const vec3 scatteringM = vec3(21e-6);

// Mie extinction coefficients
// for rgb wavelengths at sea level [km^(-1)]
const vec3 extinctionM = scatteringM*1.1;

// scale height values for Rayleigh and Mie scattering
const float Hr = 8e3;
const float Hm = 1.2e3;

#define PLANET_RADIUS 6360e3
#define ATMOSPHERE_RADIUS 6420e3

// Credit: https://jcgt.org/published/0009/03/02/
// hash function for generating 32-bit unsigned integers
uint hashPCGu(uint x)
{
    uint state = x * 747796405u + 2891336453u;
    uint word = ((state >> ((state >> 28u) + 4u)) ^ state) * 277803737u;
    return (word >> 22u) ^ word;
}

#define UINT_MAX float(0xffffffffu)

float hashPCG(vec2 x)
{
    x += 3250000.;
    x = abs(x);
    uvec2 p = uvec2(floor(x));
    return float(hashPCGu(149u*p.x ^ 233u*p.y)) / UINT_MAX;
    //return float(hashPCGu(p.x + hashPCGu(p.y))) / UINT_MAX;
}

// Generates 2D vector for gradient noise
vec2 gradientPCG(vec2 x)
{
    //x += 3250000.;
    x = abs(x);
    uvec2 p = uvec2(floor(x));
    
#if 1
    float valX = float(hashPCGu(149u*p.x ^ 233u*p.y));
    float valY = float(hashPCGu(97u*p.x ^ 193u*p.y));
#else    
    float valX = float(hashPCGu(p.x + hashPCGu(p.y)));
    float valY = float(hashPCGu(97u*p.x + hashPCGu(193u*p.y)));
#endif

    return normalize((vec2(valX, valY)/UINT_MAX)*2.-1.);
}

float hashPCG(vec3 x)
{
    x += 3250000.;
    x = abs(x);
    uvec3 p = uvec3(floor(x));
    return float(hashPCGu(149u*p.x ^ 233u*p.y ^ 157u*p.z)) / UINT_MAX;
}


// Credit: https://www.shadertoy.com/view/4dXBRH
// Returns value and a derivative of a value noise for given point
vec3 vnoised(vec2 p)
{
    vec2 i = floor( p );
    vec2 f = fract( p );

    // quintic interpolation
    vec2 u = f*f*f*(f*(f*6.0-15.0)+10.0);
    vec2 du = 30.0*f*f*(f*(f-2.0)+1.0); 
    
    float va = hashPCG( i + vec2(0.0,0.0) );
    float vb = hashPCG( i + vec2(1.0,0.0) );
    float vc = hashPCG( i + vec2(0.0,1.0) );
    float vd = hashPCG( i + vec2(1.0,1.0) );

    float k0 = va;
    float k1 = vb - va;
    float k2 = vc - va;
    float k4 = va - vb - vc + vd;

    return vec3( va+(vb-va)*u.x+(vc-va)*u.y+(va-vb-vc+vd)*u.x*u.y, // value
                 du*(u.yx*(va-vb-vc+vd) + vec2(vb,vc) - va) );     // derivative  
}

// Credit: https://www.shadertoy.com/view/4dXBRH
// Returns value noise in range <0; 1> for given point
float vnoise(vec2 p)
{
    vec2 i = floor( p );
    vec2 f = fract( p );

    // quintic interpolation
    vec2 u = f*f*f*(f*(f*6.0-15.0)+10.0);
    
    float va = hashPCG( i + vec2(0.0,0.0) );
    float vb = hashPCG( i + vec2(1.0,0.0) );
    float vc = hashPCG( i + vec2(0.0,1.0) );
    float vd = hashPCG( i + vec2(1.0,1.0) );
    
    float k0 = va;
    float k1 = vb - va;
    float k2 = vc - va;
    float k4 = va - vb - vc + vd;

    return (va+(vb-va)*u.x+(vc-va)*u.y+(va-vb-vc+vd)*u.x*u.y);
}

// Credit: https://www.shadertoy.com/view/4dXBRH
// Returns value noise in range <-1; 1> for given point
float vnoise2(vec2 p)
{
    vec2 i = floor( p );
    vec2 f = fract( p );

    // quintic interpolation
    vec2 u = f*f*f*(f*(f*6.0-15.0)+10.0);

    float va = hashPCG( i + vec2(0.0,0.0) )*2.0 - 1.0;
    float vb = hashPCG( i + vec2(1.0,0.0) )*2.0 - 1.0;
    float vc = hashPCG( i + vec2(0.0,1.0) )*2.0 - 1.0;
    float vd = hashPCG( i + vec2(1.0,1.0) )*2.0 - 1.0;
    
    float k0 = va;
    float k1 = vb - va;
    float k2 = vc - va;
    float k4 = va - vb - vc + vd;

    return (va+(vb-va)*u.x+(vc-va)*u.y+(va-vb-vc+vd)*u.x*u.y);
}

// Credit: https://goeden.tistory.com/131
vec2 random(vec2 st){
    float x = fract(sin(dot(st*25., vec2(17.34,50.13)))*84239.523);
    float y = fract(cos(dot(st*25., vec2(28.13,39.49)))*94820.475);
  
    return vec2(x, y) *2. -1.; // range -1 ~ 1
}

// Credit: https://goeden.tistory.com/131
float gnoise(vec2 st)
{
    vec2 i = floor(st);
    vec2 f = fract(st);
    
    vec2 v1 = i;
    vec2 v2 = i + vec2(1., 0.);
    vec2 v3 = i + vec2(0., 1.);
    vec2 v4 = i + vec2(1., 1.);
    
#if 0
    vec2 r1 = random(v1);
    vec2 r2 = random(v2);
    vec2 r3 = random(v3);
    vec2 r4 = random(v4);
#else
    vec2 r1 = gradientPCG(v1);
    vec2 r2 = gradientPCG(v2);
    vec2 r3 = gradientPCG(v3);
    vec2 r4 = gradientPCG(v4);
#endif
    // f = smoothstep(0., 1., f);
    f = f*f*f*(f*(f*6.-15.)+10.);
    
    float d1 = dot(r1, st-v1);
    float d2 = dot(r2, st-v2);
    float d3 = dot(r3, st-v3);
    float d4 = dot(r4, st-v4);
    
    float bot = mix(d1, d2, f.x);
    float top = mix(d3, d4, f.x);
    float ret = mix(bot, top, f.y);
    
    return ret; // range -1 ~ 1
}

// Credit: https://www.shadertoy.com/view/XdXGW8
vec2 grad( ivec2 z ) 
{
    // 2D to 1D
    int n = z.x+z.y*11111;

    // Hugo Elias hash
    n = (n<<13)^n;
    n = (n*(n*n*15731+789221)+1376312589)>>16;

    // Perlin style vectors
    n &= 7;
    vec2 gr = vec2(n&1,n>>1)*2.0-1.0;
    return ( n>=6 ) ? vec2(0.0,gr.x) : 
           ( n>=4 ) ? vec2(gr.x,0.0) :
                              gr;                          
}

// Credit: https://www.shadertoy.com/view/XdXGW8
float gnoise1( in vec2 p )
{
    ivec2 i = ivec2(floor( p ));
    vec2 f =  fract( p );
	
	vec2 u = f*f*(3.0-2.0*f);
    //vec2 u = f*f*f*(f*(f*6.-15.)+10.);


    return mix( mix( dot( grad( i+ivec2(0,0) ), f-vec2(0.0,0.0) ), 
                     dot( grad( i+ivec2(1,0) ), f-vec2(1.0,0.0) ), u.x),
                mix( dot( grad( i+ivec2(0,1) ), f-vec2(0.0,1.0) ), 
                     dot( grad( i+ivec2(1,1) ), f-vec2(1.0,1.0) ), u.x), u.y);
}

// Value noise with 3D input
// Credit: https://www.shadertoy.com/view/4sfGzS
float vnoise3(vec3 x)
{
    vec3 i = floor(x);
    vec3 f = fract(x);
    f = f*f*(3.0-2.0*f);
	
    return mix(mix(mix( hashPCG(i+vec3(0,0,0)), 
                        hashPCG(i+vec3(1,0,0)),f.x),
                   mix( hashPCG(i+vec3(0,1,0)), 
                        hashPCG(i+vec3(1,1,0)),f.x),f.y),
               mix(mix( hashPCG(i+vec3(0,0,1)), 
                        hashPCG(i+vec3(1,0,1)),f.x),
                   mix( hashPCG(i+vec3(0,1,1)), 
                        hashPCG(i+vec3(1,1,1)),f.x),f.y),f.z);
}

// Computes fractional Brownian motion
float fbm(vec2 p, int numOctaves, float H)
{
    float G = exp2(-H);
    float f = 1.0;
    float a = 1.0;
    float t = 0.0;
    
    for( int i=0; i<numOctaves; i++ )
    {
        float n = vnoise(f*p);
        t += a*n;
        f *= 2.0;
        a *= G;
    }
    return t;
}

float fbmRock(vec3 p, int numOctaves, float H)
{
    float f = 1.0;
    float a = 0.5;
    float t = 0.0;
    
    for( int i=ZERO; i<numOctaves; i++ )
    {
        float n = (-1.0 + 2.0*vnoise3(f*p));
        //n *= n;
        t += a*n;
        f *= 2.;
        a = pow(f, -H);
    }
    return 0.5+0.5*t;
}

// high quality rock texture
vec3 rockTexture(vec3 p)
{
    const vec3 colRock = vec3(0.14, 0.1, 0.08);
    
    vec3 q = 0.5*vec3( fbmRock( p + vec3(0.0,0.0,0.0), 6, 0.5 ),
                       fbmRock( p + vec3(7.3,11.37,17.91), 6, 0.5 ),
                       fbmRock( p + vec3(5.2,1.3,3.7), 6, 0.5 ) );
    
    float rock = fbmRock(p + 4.0*q, 6, 0.5);
    
    vec3 col = 2.0*colRock*rock;
    col = mix(col, vec3(0.15, 0.15, 0.15), dot(q.x,q.x));
    col = mix(col, vec3(0.02, 0.02, 0.02), q.y*q.y);
    //col = mix(col, vec3(0.3, 0.2, 0.2), 0.25*dot(q, q));
    
    return col;
}

// fast rock texture
vec3 rockTextureLow(vec3 p)
{
    const vec3 colRock = vec3(0.14, 0.1, 0.08);
    const int octaves = 7;
    const float smoothness = 0.5;
    float rock = fbmRock( p + vec3(0.0,0.0,0.0), octaves, smoothness);
    
    return rock*colRock;
}

float fbm2(vec2 p, int numOctaves, float H)
{
    float G = exp2(-H);
    float f = 1.0;
    float a = 1.0;
    float t = 0.0;
    
    for( int i=0; i<numOctaves; i++ )
    {
        float n = vnoise2(f*p);
        t += a*n;
        f *= 2.0;
        a *= G;
    }
    return t;
}

float fbmCloud(vec3 p)
{
    p = CLOUDS_SCALE*p + iTime*CLOUDS_SPEED+vec3(camPosition.x, 0.0, camPosition.z)*CLOUDS_SCALE;
    float G = exp2(-CLOUD_SMOOTHNESS);
    float f = 1.0;
    float a = 0.5;
    float t = 0.0;
    
    for( int i=ZERO; i<6; i++ )
    {
        float n = vnoise3(f*p);
        t += a*n;
        f *= 2.5789f;
        a *= G;
    }
    
    //t = clamp(1.0*t, 0.0, 1.0);
    
    t *= 0.6;
    
    float cov = 0.6 - 0.35*CLOUD_COVERAGE;
    
    t *= smoothstep (cov, cov+0.05, t);
    //t = clamp(t, 0.0, 1.0);
    
    return t*DENSITY;
}

float hybridFractal(vec2 p, int numOctaves)
{
    const float H = SMOOTHNESS;
    const float G = exp2(-H);
    float f = 2.0;       // frequency of noise
    float a = G;         // amplitude of noise
    float t = 0.0;       // accumulated noise
    
    float n = vnoise(p);
    t += n;
    
    float weight = n;
        
    for( int i=1; i<numOctaves; i++ )
    {
        weight = clamp(weight, 0.0, 1.0);
        n = vnoise(f*p);
        t += weight*a*n;
        
        f *= 2.0;        // doubling the frequency
        a *= G;
        weight *= n;
    }
    return t;
}

float hybridFractal1(vec2 p, int numOctaves)
{
    const float H = SMOOTHNESS;
    const float G = exp2(-H);
    float f = 1.0;       // frequency of noise
    float a = pow(f, -H);         // amplitude of noise
    float t = 0.0;       // accumulated noise
    
    // add first octave
    t = a * vnoise(p);
    float weight = t;
    
    for( int i=1; i<numOctaves; i++ )
    {
        weight = min(weight, 1.0);
        
        f *= 2.0;        // doubling the frequency
        a = pow(f, -H); 
        
        float n = a * vnoise(f*p);
        t += weight*n;
        weight *= n;
    }
    return t;
}

float hybridFractal2(vec2 p, int numOctaves)
{
    const float H = SMOOTHNESS;
    const float offset = 0.7;
    float f = 1.0;          // frequency of noise
    float a = pow(f, -H);   // amplitude of noise
    float result = 0.0;     // accumulated noise
    
    // add first octave
    result = a * ( gnoise(p) + offset );
    float weight = result;
    
    for( int i=1; i<numOctaves; i++ )
    {
        weight = min(weight, 1.0);
        
        f *= 2.0;        // doubling the frequency
        a = pow(f, -H); 
        
        float n = a * ( gnoise(f*p) + offset );
        result += weight*n;
        weight *= n;
    }
    return result;
}

float ridgedFractal(vec2 p, int numOctaves)
{
    const float offset = 1.0;
    const float gain = 2.1;
    float f = 1.0;       // frequency of the noise
    float a = 1.0;       // amplitude of noise
    float result = 0.0;  // accumulated noise
    
    // add first octave
    float signal = abs(gnoise(p));
    
    const float smoothingEdge0 = -0.005;
    const float smoothingEdge1 = 0.015;
    
    #if SMOOTH_RIDGES
        // smooth out sharp ridges
        signal *= smoothstep(smoothingEdge0, smoothingEdge1, signal);
    #endif
    signal = offset - signal;
    signal *= signal;
    
    result = signal * a;
    
    float weight = 1.0;
    
    for( int i=1; i<numOctaves; i++ )
    {
        weight = signal * gain;
        weight = clamp(weight, 0.0, 1.0);
        
        f *= 2.03;
        a = pow(f, -SMOOTHNESS); 
        
        signal = abs(gnoise(f*p));
        
        #if SMOOTH_RIDGES
            // smooth out sharp ridges
            signal *= smoothstep(smoothingEdge0, smoothingEdge1, signal);
        #endif
        
        signal = offset - signal;
        signal *= signal;
            
        signal *= weight;
        result += signal * a;
    }
    return result;
}

// finds intersection of the ray with the sphere from outside the sphere
float intersectRaySphereOutside(Ray ray, Sphere sphere)
{
	vec3 oc = ray.origin - sphere.center;
	float a = dot(ray.dir, ray.dir);
	float b = dot(oc, ray.dir);
	float c = dot(oc, oc) - sphere.radius*sphere.radius;
	float discriminant = b*b - a*c;
	if (discriminant < 0.0)
	{
		// no intersection
		return -1.0;
	}
	else
	{
		float t = (-b - sqrt(b*b - a*c)) / a;
		if (t > NEAR_PLANE)
			return t;
		else
			return -1.0;
	}
}

// finds intersection of the ray with the sphere from inside the sphere
float intersectRaySphereInside(Ray ray, Sphere sphere)
{
	vec3 oc = ray.origin - sphere.center;
	float a = dot(ray.dir, ray.dir);
	float b = dot(oc, ray.dir);
	float c = dot(oc, oc) - sphere.radius*sphere.radius;
	float discriminant = b*b - a*c;
	if (discriminant < 0.0)
	{
		// no intersection
		return -1.0;
	}
	else
	{
		float t = (-b + sqrt(b*b - a*c)) / a;
		if (t > NEAR_PLANE)
			return t;
		else
			return -1.0;
	}
}

vec3 rayPointAtParameter(Ray r, float t)
{
	return (r.origin + r.dir*t);
}

float sphereSDF(vec3 center, float radius, vec3 point)
{
	return length(point - center) - radius;
}

float terrainMap(vec2 point, int octaves)
{
    point += camPosition.xz*SCALE;

    //return hybridFractal2(vec2(point), octaves);
    return ridgedFractal(vec2(point), octaves)-0.6;
}

float sceneSDF(vec3 point, bool shadow)
{
    float h = terrainMap( (point.xz+TERRAIN_OFFSET)*SCALE, (shadow ? OCTAVES_SHADOW : OCTAVES) );
    h *= TERRAIN_AMPLITUDE;

	float dist = sphereSDF(vec3(0.0), PLANET_RADIUS+h, point);
    //float dist = point.y - radius;  // flat planet

    return dist;
}

vec3 estimateNormal(vec3 p, float epsilon, bool shading) {
	vec3 n;
    p.xz += TERRAIN_OFFSET;
    p.xz *= SCALE;
    epsilon *= SCALE;
    //epsilon = MinDist*0.5;
    int numOctaves = shading ? OCTAVES_NORMAL : OCTAVES;
	n = vec3( terrainMap(vec2(p.x-epsilon, p.z), numOctaves) - terrainMap(vec2(p.x+epsilon, p.z), numOctaves), 
              2.0f*epsilon,
              terrainMap(vec2(p.x,p.z-epsilon), numOctaves) - terrainMap(vec2(p.x,p.z+epsilon), numOctaves) );
              
	return normalize(n);
}

float softShadow(vec3 point, float epsilon, int steps)
{
	Ray r;
	r.dir = Light;
	//r.origin = point + r.dir*TERRAIN_AMPLITUDE*0.1;
	r.origin = point;

	float res = 1.0;
    
	float depth = epsilon;
    
	for (int i = 0; i < steps; i++) 
	{
		vec3 samplePoint = rayPointAtParameter(r, depth);
		float dist = sceneSDF(samplePoint, true);
		if (dist < epsilon) 
		{
			// Point is in full shadow
			return 0.0;
		}
		res = min(res, SHADOW_SOFTNESS*dist/depth);

		// Move along the shadow ray
		depth += clamp(dist, 1.0+depth*0.1, 50.0);
        //depth += clamp(dist, epsilon, 50.0);

        if (res < 0.01)
        {
            break;
        }
	}
	return clamp(res, 0.0, 1.0);
}

float cubeTexture(vec3 p)
{
    vec3 a = fract(p);
    
    float x = smoothstep(0.05, 0.1,  a.x);
    float y = smoothstep(0.05, 0.1,  a.y);
    float z = smoothstep(0.05, 0.1,  a.z);
    
    return z*x;
    return x*y*z;
    
}

vec3 getTerrainTexture(vec3 point, vec3 N, float pointHeight)
{
    vec3 color = vec3(0.0);
    
    const vec3 colSnow = vec3(0.95, 0.95, 1.0);
    const vec3 colGround = vec3(0.05, 0.2, 0.02);
    
    vec3 coordRock = (point)*SCALE*295.*1.0;
    coordRock.xz *= 0.1;
    coordRock.y *= 0.3;    // 0.8
    
    #if TEXTURE_LOW_QUALITY
        coordRock *= 2.;
        vec3 colRock = rockTextureLow(coordRock);
    #else
        vec3 colRock = rockTexture(coordRock);
    #endif
    
    
    float rand = fbm(point.xz*SCALE*75.7, 7, 0.5);
    //float snow = smoothstep(0.15*rand, 0.5, N.y);
    float snow = smoothstep(0.15*rand, 0.5, N.y);
    
    //float rock = 1.0-smoothstep(1800., 2000.0, height);
    
    color = mix(colRock, colSnow, snow);
    
    return color;
}

// Credit: https://www.iquilezles.org/www/articles/filtering/filtering.htm
// Returns filtered texture
vec3 getTerrainTextureFiltered(vec3 coord, vec3 ddx, vec3 ddy, vec3 N, float height)
{
    vec3 diffX = ddx-coord;
    vec3 diffY = ddy-coord;
    
    const float detail = 4.0;
    
    int sx = 1 + int(clamp( detail*length(diffX), 0.0, float(FILTERING_SAMPLES-1) ));
    int sy = 1 + int(clamp( detail*length(diffY), 0.0, float(FILTERING_SAMPLES-1) ));

	vec3 no = vec3(0.0);

    for( int j=ZERO; j<FILTERING_SAMPLES; j++ )
        for( int i=ZERO; i<FILTERING_SAMPLES; i++ )
        {
            if( j<sy && i<sx )
            {
                vec2 st = vec2(float(i), float(j)) / vec2(float(sx),float(sy));
                no += getTerrainTexture(coord + st.x*(diffX) + st.y*(diffY), N, height);
            }
        }

	return no / float(sx*sy);
}


// Three light setup: direct sunlight, ambient skylight and indirect sunlight
// Based on https://iquilezles.org/articles/outdoorslighting
// Returns shaded color of the terrain
vec3 shade(vec3 point, vec3 N, vec3 color, vec3 lightColor, float epsilon)
{      
    //float shadow = softShadow(point+Light*SCALE*0.01, MinDist, MaxMarchingStepsShadow);
    float shadow = softShadow(point+N*0.01, MIN_DIST, MAX_MARCHING_STEPS_SHADOW);
    
    // direct light from sun
    float sun = clamp(dot(Light, N), 0.0, 1.0);
    
    // ambient light from sky
    float sky = clamp(0.5 + 0.5*N.y, 0.0, 1.0);
    
    // approximation of indirect sunlight
    float indirect = clamp(dot(N, normalize(Light*vec3(-1.0,0.0,-1.0)) ), 0.0, 1.0);
    
    // compute overall light
    vec3 light = sun*SunIntensityGround*lightColor*shadow;
    //light += sky*ambientLight;
    light += sky*vec3(0.16,0.20,0.28);
    
    light += indirect*0.2*lightColor;
    
    return light*color;
}

// Returns density gradient for clouds
// Density is lower in bottom and top parts of the clouds
float cloudHeightGradient(float height)
{
    const float edge = 0.35*CLOUDS_THICKNESS;
    return smoothstep(0.0, edge, height-CLOUDS_HEIGHT)*
           smoothstep(0.0, edge, CLOUDS_HEIGHT+CLOUDS_THICKNESS-height);
}

float cloudTransmittance(Ray r, Atmosphere planetAtmos)
{
    const float extinction = ABSORPTION + SCATTERING;
    Sphere clouds = Sphere(vec3(0., 0., 0.), planetAtmos.planetRadius+CLOUDS_HEIGHT);
    float transmittance = 1.0;
    
    float tMin = intersectRaySphereInside(r, clouds);
    clouds.radius += CLOUDS_THICKNESS;
    float tMax = intersectRaySphereInside(r, clouds);
    
    float dist = tMax - tMin;
    float stepLength = dist / 3.0;
    float tCurrent = tMin;
            
    for (int i = 0; i < 3; i++)
    {
        vec3 samplePosition = rayPointAtParameter(r, tCurrent);
            
        float density = fbmCloud(samplePosition);
           
        /*if (density <= 0.001)
        {
            return 0.0;
        }*/
        
        float height = length(samplePosition) - planetAtmos.planetRadius;
        density *= cloudHeightGradient(height);
        
        float extinctionCoeff = max(0.000000001, density*extinction);
            
        transmittance *= exp(-extinctionCoeff*stepLength);
        tCurrent += stepLength;
    }
    
    return transmittance;
}

vec3 atmosphereScattering(Ray r, float tMin, float tMax, Atmosphere planetAtmos, out vec3 rayTransmittance)
{
    Sphere atmosphere = Sphere(vec3(0., 0., 0.), 
                                planetAtmos.atmosphereRadius);
    
    vec3 scatteringCoeffR = planetAtmos.scatteringR;
    vec3 scatteringCoeffM = planetAtmos.scatteringM;
    //int steps = STEPS;       
    //int lightSteps = LIGHT_STEPS;

    // find intersection with atmosphere
    float atmosphereIntersectionT = intersectRaySphereInside(r, atmosphere);
    
    tMax = min(tMax, atmosphereIntersectionT);
    
    float stepLength = (tMax-tMin) / float(ATMOS_STEPS);
    float halfStep = stepLength*0.5;
    
    float tCurrent = tMin;
    float mu = dot(r.dir, Light);  // cosine of an angle between light direction and view direction
    float muSquared = mu*mu;
    
    vec3 rayleighSum, mieSum = vec3(0.0);
    float opticalDepthR, opticalDepthM = 0.0;
    
    const float g = 0.76;     // determines anisotropy of mie scattering 
    const float gSquared = g*g;
    
    const float rConst = 3. / (16.*PI);
    const float mConst = 3. / (8.*PI);
    
    float phaseR = rConst * (1.+muSquared);  // Rayleigh phase function
    float phaseM = mConst * ( (1.-gSquared)*(1.+muSquared) ) / 
                   ( (2.+gSquared)*pow(1.+gSquared-2.*g*mu, 1.5) );  // Mie phase function
                   
    for (int i = 0; i < ATMOS_STEPS; i++) 
    {
        vec3 samplePosition = rayPointAtParameter(r, tCurrent+halfStep);
        float height = length(samplePosition) - planetAtmos.planetRadius;
        
        float hr = exp(-height / planetAtmos.Hr) * stepLength;
        float hm = exp(-height / planetAtmos.Hm) * stepLength; 
        opticalDepthR += hr; 
        opticalDepthM += hm; 
        
        Ray rayToLight = Ray(samplePosition, Light);
        
        float tMaxLight = intersectRaySphereInside(rayToLight, atmosphere);
        float tCurrentLight = 0.0;
        
        float stepLengthLight = tMaxLight / float(ATMOS_LIGHT_STEPS);
        float halfStepLight = stepLengthLight*0.5;
        
        float opticalDepthLightR, opticalDepthLightM = 0.0;
        
        for ( int j = 0 ; j < ATMOS_LIGHT_STEPS; ++j)
        {
            vec3 samplePositionLight = rayToLight.origin + 
                    (tCurrentLight+halfStepLight)*rayToLight.dir;
                    
            float heightLight = length(samplePositionLight) - planetAtmos.planetRadius;
            
            opticalDepthLightR += exp(-heightLight / planetAtmos.Hr) * stepLengthLight;
            opticalDepthLightM += exp(-heightLight / planetAtmos.Hm) * stepLengthLight; 
            tCurrentLight += stepLengthLight;
        }
        
        vec3 tau = scatteringCoeffR * (opticalDepthR + opticalDepthLightR) + extinctionM * (opticalDepthM + opticalDepthLightM); 
        vec3 attenuation = exp(-tau);
        rayleighSum += attenuation * hr; 
        mieSum += attenuation * hm; 
        tCurrent += stepLength;
    }
    rayTransmittance = exp(-(scatteringCoeffR*opticalDepthR + extinctionM*opticalDepthM));
    
    return (rayleighSum * scatteringCoeffR * phaseR + mieSum * scatteringCoeffM * phaseM) * 20.0; 
}

// Computes Henyey-Greenstein phase function
float henyeyGreenstein(float cosViewLight, float g)
{
    float gg = g * g;
	return (1. - gg) / (4.*PI * pow(1. + gg - 2. * g * cosViewLight, 1.5));
}

// Computes transmittance of light coming to the given point 
// through cloud layer of given atmosphere
float marchToLight(vec3 point, Atmosphere planetAtmos)
{
	Ray r = Ray(point, Light);
	
    Sphere clouds = Sphere(vec3(0., 0., 0.), 
                                planetAtmos.planetRadius+CLOUDS_HEIGHT);
                                
    // find intersections with bounding spheres of clouds
    //float tInner = intersectRaySphereOutside(r, clouds);
    clouds.radius += CLOUDS_THICKNESS;
    float tOuter = intersectRaySphereInside(r, clouds);
    
    float tMin = 0.0;
    //float tMax = min(tInner, tOuter);
    float tMax = tOuter;
    
    const int steps = CLOUD_LIGHT_STEPS;
    float stepLength = tMax / float(steps);

	float tCurrent = 0.0f;
    float transmittance = 1.0;
    const float extinction = ABSORPTION + SCATTERING;

	for (int i = 0; i < steps; i++)
    {
        vec3 samplePosition = r.origin + tCurrent*r.dir;
        float height = length(samplePosition) - planetAtmos.planetRadius;
        
        float density = fbmCloud(samplePosition)*cloudHeightGradient(height);
        
        // low density - no need to compute transmittance
        if (density <= 0.001)
        {
            tCurrent += stepLength;
            continue;
        }
        
        float extinctionCoeff = max(0.000000001, density*extinction);
        
        transmittance *= exp(-extinctionCoeff*stepLength);
        
        if (transmittance < 0.02) break;
        tCurrent += stepLength;
    }
    
	return transmittance;
}

// Returns phase function of the clouds
float phaseFunction(vec3 view, vec3 light, float forwardG, float backwardG, float a)
{
    // cosine of an angle between light direction and view direction
    float mu = dot(view, light);
    
    // 2-lobe Henyey-Greenstein phase function
    return mix(henyeyGreenstein(mu, forwardG), henyeyGreenstein(mu, -backwardG), a);
}

// Exponential integral
float Ei(float z)
{
    return 0.5772156649015328606065 + log( 1e-4 + abs(z) ) + z * 
           (1.0 + z * (0.25 + z * ( (1.0/18.0) + z * ( (1.0/96.0) + z * (1.0/600.0) ) ) ) );
}

// Credit: http://patapom.com/topics/Revision2013/Revision%202013%20-%20Real-time%20Volumetric%20Rendering%20Course%20Notes.pdf
// Computes approximation of ambient light in clouds
vec3 computeAmbientColor(float height, float extinctionCoeff, vec3 ambientColor)
{
    float distToTop = CLOUDS_HEIGHT + CLOUDS_THICKNESS - height;
    float a = -extinctionCoeff * distToTop;
    vec3 isotropicScatteringTop = ambientColor * max(0.0, exp(a) - a*Ei(a));
    
    float distToBottom = height - CLOUDS_HEIGHT;
    a = -extinctionCoeff * distToBottom;
    vec3 isotropicScatteringBottom = ambientColor * max(0.0, exp(a) - a*Ei(a));
    return AMBIENT_LIGHT_STRENGTH_CLOUDS*(isotropicScatteringTop+isotropicScatteringBottom) / (4.*PI);
}

vec4 renderClouds(Ray r, float depth, Atmosphere planetAtmos, vec3 lightColor, vec3 ambientLight)
{
    int steps = CLOUD_STEPS;
    
    if (steps <= 0) return vec4(0.0, 0.0, 0.0, 1.0);
    
    Sphere clouds;
    float height = length(r.origin) - planetAtmos.planetRadius;
    
    // find intersections with boundaries of cloud layer
    float tMin, tMax;
    
    if ( height < (CLOUDS_HEIGHT+CLOUDS_THICKNESS) )
    {
        clouds = Sphere(vec3(0., 0., 0.), planetAtmos.planetRadius+CLOUDS_HEIGHT);
        // camera is below or inside the clouds
        
        if ( height < CLOUDS_HEIGHT )
        {
            // camera is below the clouds
            tMin = intersectRaySphereInside(r, clouds);
            clouds.radius += CLOUDS_THICKNESS;
            tMax = intersectRaySphereInside(r, clouds);
        }
        else
        {
            // camera is inside the clouds
            tMin = 0.0;
            
            float inner = intersectRaySphereOutside(r, clouds);
            clouds.radius += CLOUDS_THICKNESS;
            float outer = intersectRaySphereInside(r, clouds);
            
            if (inner < 0.0) tMax = outer;
            else if (outer < 0.0) tMax = inner;
            else tMax = min(inner, outer);
        }
    }
    else
    {
        // camera is above the clouds
        clouds = Sphere(vec3(0., 0., 0.), planetAtmos.planetRadius+CLOUDS_HEIGHT+CLOUDS_THICKNESS);
        
        tMin = intersectRaySphereOutside(r, clouds);
        
        if (tMin < 0.0) return vec4(-1.0);
        clouds.radius -= CLOUDS_THICKNESS;
        tMax = intersectRaySphereOutside(r, clouds);
    }
    
    // terrain occludes clouds
    if (depth < tMin) return vec4(-1.0);
    
    //if (tMin > FAR_PLANE) return vec4(-1.0);

    float stepLength = (tMax-tMin) / float(steps);
    //const float stepLength = 45.;
    
    float tCurrent = tMin;
    float transmittance = 1.0;
    vec3 lightAmount = vec3(0.0);
    const float extinction = ABSORPTION + SCATTERING;
    float phaseVal = phaseFunction(r.dir, Light, FORWARD_SCATTERING_G, BACKWARD_SCATTERING_G, INTERPOLATION);
    
    vec3 ambient = mix(lightColor, ambientLight, 0.3);
    
    #if RANDOM_RAY_OFFSET
        // randomly offset ray to eliminate banding artefacts
        tCurrent += stepLength * (hashPCG(pixelCoord)*2.0 - 1.0);
    #endif
    
    while (tCurrent <= tMax)
    {
        vec3 samplePosition = r.origin + tCurrent*r.dir;
        
        float density = fbmCloud(samplePosition);
        
        // low density - no need to compute lighting
        if (density <= 0.001)
        {
            tCurrent += stepLength;
            continue;
        }
        
        height = length(samplePosition) - planetAtmos.planetRadius;
        density *= cloudHeightGradient(height);
        
        float extinctionCoeff = max(0.000000001, density*extinction);
        
        // amount of light coming from sun to this point
		vec3 incomingLight = marchToLight(samplePosition, planetAtmos)*lightColor*SUN_INTENSITY_CLOUDS;
        float stepTransmittance = exp(-extinctionCoeff*stepLength);
                
        vec3 amb = computeAmbientColor(height, extinctionCoeff, ambient);
        
        // amount of light scattered toward camera
        vec3 scatteredL =  SCATTERING*density * (incomingLight*phaseVal + amb);
#if IMPROVED_INTEGRATION
        // integrate scattered light along current segment
        scatteredL = (scatteredL - scatteredL * stepTransmittance) / extinctionCoeff;
#else
        // amount of light scattered toward camera
        scatteredL *=  stepLength;
#endif       
		lightAmount += transmittance * scatteredL;
        
        transmittance *= stepTransmittance;
        
        if (transmittance < 0.02) break;
        tCurrent += stepLength;
    }
    
    //if (transmittance < 1.0)
    {
        // atmosphere scattering in front of the cloud
        vec3 rayTransmittance = vec3(0.0);
        vec3 atmosphereColor = atmosphereScattering(r, NEAR_PLANE, tMin, planetAtmos, rayTransmittance);
        lightAmount = lightAmount*rayTransmittance+atmosphereColor;
    }
    
    return vec4(lightAmount, transmittance);
}

float renderSun(float mu)
{
    float oneMuSquared = 1.0 + mu*mu;
    
    float s = 0.999;
    float sSquared = s*s;
    float phaseS = 0.1193662 * ( (1.-sSquared)*oneMuSquared ) / 
                   ( (2.+sSquared)*pow(1.+sSquared-2.*s*mu, 1.5) );
    //float phaseS = .1193662 * (1. - s2) * opmu2 / ((2. + s2) * pow(1. + s2 - 2.*s*mu, 1.5));
    return phaseS;
}

bool trace(Ray r, out float intersectionDist)
{
	float totalDist = NEAR_PLANE;
	int steps = 0;
    intersectionDist = FLT_MAX;

    //r.origin += vec3(camPosition.x, 0.0, camPosition.z);

    float dist = 0.0;

	float epsilon = MIN_DIST;
	float epsilonModified = epsilon;

	for (steps = 0; steps < MAX_MARCHING_STEPS; steps++) 
	{
		vec3 samplePoint = r.origin + totalDist * r.dir;
		dist = sceneSDF(samplePoint, false);
        
		if (dist < epsilonModified) 
		{
			// Ray is inside the terrain
                        
            // interpolation of previous and current point
            intersectionDist = totalDist;//mix(totalDist, oldTotalDist, 0.5);
            
            // intersection with terrain was found
            return true;
		}
        
        //vec3 N = estimateNormal(samplePoint, epsilonModified*0.001, false);
        
        // Move along the view ray
        totalDist += dist*0.4;
        //totalDist += dist*0.5*smoothstep(-0.2, 0.5, N.y); // slow down in steep areas
        
        if (totalDist >= FAR_PLANE) 
        {
			// there is no intersection with terrain
            return false;
		}
        
        epsilonModified = epsilon*totalDist;
	}
    
    // maximal number of ray marching steps was evaluated,
    // no intersection with terrain was found
    return false;
}

mat3 camera() 
{
	vec3 cd = CamDir;          // camera direction
	vec3 cr = normalize(cross(vec3(0, 1, 0), cd)); // camera right
	vec3 cu = normalize(cross(cd, cr));            // camera up
	
	return mat3(cr, cu, -cd);
}


void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord/iResolution.xy;
    uv -= 0.5;
    uv.x *= iResolution.x / iResolution.y;
    
    float t = iTime;

    /*sunAngleY = radians(iTime*0.5-5.0);
    sunAngleX = radians(10.0);
    Light = normalize( vec3(sin(sunAngleX)*cos(sunAngleY), 
                                   sin(sunAngleY),
                                   cos(sunAngleX)*cos(sunAngleY) ));*/

    pixelCoord = fragCoord.xy;
	vec2 dimensions = iResolution.xy;

	if (pixelCoord.x > dimensions.x || pixelCoord.y > dimensions.y)
		return;
        
    const Atmosphere earthAtmos = Atmosphere(PLANET_RADIUS, ATMOSPHERE_RADIUS, scatteringR, scatteringM, Hr, Hm);    
        
    vec3 offset = vec3(0., earthAtmos.planetRadius, 0.);
    vec3 rayTransmittance = vec3(0.0);
    
#if MOVING_CAM
    camPosition = vec3(t*CAM_SPEED, CAM_HEIGHT+earthAtmos.planetRadius, 0.0);
    vec3 ro = vec3(0, camPosition.y, 0.0);
    
    float terrainH = 0.0;
    const int numSamples = 4;
    const float stepLen = 2.0*CAM_SPEED / float(numSamples);
    float s = 0.0;
    for (int i = 0; i < numSamples; i++) 
    {
        terrainH += TERRAIN_AMPLITUDE*terrainMap( (ro.xz+TERRAIN_OFFSET)*SCALE + s, 6);
        s += stepLen;
    }
    ro.y += terrainH / float(numSamples);
    camPosition.y = ro.y;
    vec3 lookAt = normalize(ro+CamDir); //vec3(100.0, -20., 52.0);
#else
    camPosition = vec3(11e3, CAM_HEIGHT+earthAtmos.planetRadius, 2e3);
    vec3 ro = vec3(0.0, camPosition.y, 0.0);
    //vec3 lookAt = ro + normalize(vec3(1.0, .5, 1.0)); //vec3(sin(0.5*t), -0.4, cos(0.5*t));
    vec3 lookAt = ro+CamDir;
#endif
    mat3 cameraMat = camera();
    vec3 rd = cameraMat * normalize(vec3(uv, -1)); // ray direction
    
	Ray r = Ray(ro, rd);
    float intersectionDist = -1.0;
    
    // get color of the light by computing atmosphere scattering in the direction of the Sun
    vec3 lightColor = vec3(1.0, 1.0, 1.0);
    vec3 tmp = atmosphereScattering(Ray(ro, Light), NEAR_PLANE, FLT_MAX, earthAtmos, rayTransmittance);
    lightColor *= rayTransmittance;
    
    // get color of the ambient light by computing atmosphere scattering in the up direction
    vec3 ambientLight = atmosphereScattering(Ray(ro, normalize(ro)), NEAR_PLANE, FLT_MAX, earthAtmos, rayTransmittance);
    //ambientColor = vec3(1.0)-exp(-ambientColor);
    ambientLight = normalize(ambientLight);
    
    // find intersection with terrain
    bool intersection = trace(r, intersectionDist);
    
    vec3 color = vec3(0.0);
    float epsilonModified = MIN_DIST * clamp(intersectionDist, NEAR_PLANE, FAR_PLANE);
    
    if (intersection)
    {
        vec3 terrainColor = vec3(0.0);
        // shade terrain
        vec3 samplePoint = r.origin + intersectionDist * r.dir;
        float sampleHeight = length(samplePoint)-earthAtmos.planetRadius;
        
        // normal vector of a given surface point
        vec3 N = estimateNormal(samplePoint, epsilonModified, true);
    
        samplePoint += vec3(camPosition.x, 0.0, camPosition.z);
        #if TEXTURE_FILTERING
            vec3 posX = samplePoint + dFdx(samplePoint);
            vec3 posY = samplePoint + dFdy(samplePoint);
            terrainColor = getTerrainTextureFiltered(samplePoint, posX, posY, N, sampleHeight);
        #else
            terrainColor = getTerrainTexture(samplePoint, N, sampleHeight);
        #endif
        samplePoint -= vec3(camPosition.x, 0.0, camPosition.z);
        
        color = shade(samplePoint, N, terrainColor, lightColor, epsilonModified);
    }
    
    // render atmospheric scattering
    rayTransmittance = vec3(0.0);
    vec3 atmosphereColor = atmosphereScattering(r, NEAR_PLANE, intersectionDist, earthAtmos, rayTransmittance);
    
    float sunAngle = dot(r.dir, Light);
    float sun = 2.0*renderSun(sunAngle); // (10000.0*smoothstep(0.9995, 1.01, sunAngle));
    vec4 clouds = renderClouds(r, intersectionDist, earthAtmos, lightColor, ambientLight);
    
    color = (intersectionDist < FAR_PLANE) ? 
                (color*rayTransmittance + atmosphereColor) :
                (atmosphereColor + clouds.a*sun*lightColor);
        
    if (clouds.a > 0.0)
        color = color*clouds.a + clouds.xyz;
    
    const float exposure = 1.0;
    const float oneOverGamma = 0.454546; // 1.0/2.2;
  
    // exposure tone mapping
    vec3 mapped = vec3(1.0) - exp(-color * exposure);
    // gamma correction 
    mapped = pow(mapped, vec3(oneOverGamma));

	color = mapped;
    
    // Output to screen
    fragColor = vec4(color,1.0);
}