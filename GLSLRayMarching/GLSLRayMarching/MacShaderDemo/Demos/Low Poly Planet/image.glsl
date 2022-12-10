/**
* Many of the utility functions for noise, intersections, etc. are from Morgan McGuire's
* tiny planet (https://www.shadertoy.com/view/lt3XDM). Also borrowed his code for input handling.
*
* Also used a variant of IQ's 3d Voronoi Noise (https://www.shadertoy.com/view/ldl3Dl) for the
* biome mapping and heavily utilized this amazing noise function
* by @kuvlar: https://www.shadertoy.com/view/ldGSzc
*/

const float pi	= 3.1415926535;
const float inf	= 1.0 / 1e-10;
const float deg2rad	= pi / 180.0;
const float epsilon = .0001;
const int numMarches = 150;
const bool autoRotate = true;

float square(float x) { return x * x; }
float infIfNegative(float x) { return (x >= 0.0) ? x : inf; }
bool intersectSphere(vec3 C, float r, vec3 rayOrigin, vec3 direction, inout float nearDistance, inout float farDistance) { vec3 P = rayOrigin; vec3 w = direction; vec3 v = P - C; float b = 2.0 * dot(w, v); float c = dot(v, v) - square(r); float d = square(b) - 4.0 * c; if (d < 0.0) { return false; } float dsqrt = sqrt(d); float t0 = infIfNegative((-b - dsqrt) * 0.5); float t1 = infIfNegative((-b + dsqrt) * 0.5); nearDistance = min(t0, t1); farDistance  = max(t0, t1); return (nearDistance < inf); }
float hash(float n) { return fract(sin(n) * 1e4); }
float hash(vec2 p) { return fract(1e4 * sin(17.0 * p.x + p.y * 0.1) * (0.1 + abs(sin(p.y * 13.0 + p.x)))); }
float noise(float x) { float i = floor(x); float f = fract(x); float u = f * f * (3.0 - 2.0 * f); return mix(hash(i), hash(i + 1.0), u); }
float noise(vec2 x) { vec2 i = floor(x); vec2 f = fract(x); float a = hash(i); float b = hash(i + vec2(1.0, 0.0)); float c = hash(i + vec2(0.0, 1.0)); float d = hash(i + vec2(1.0, 1.0)); vec2 u = f * f * (3.0 - 2.0 * f); return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y; }
float noise(vec3 x) { const vec3 step = vec3(110, 241, 171); vec3 i = floor(x); vec3 f = fract(x); float n = dot(i, step); vec3 u = f * f * (3.0 - 2.0 * f); return mix(mix(mix( hash(n + dot(step, vec3(0, 0, 0))), hash(n + dot(step, vec3(1, 0, 0))), u.x), mix( hash(n + dot(step, vec3(0, 1, 0))), hash(n + dot(step, vec3(1, 1, 0))), u.x), u.y), mix(mix( hash(n + dot(step, vec3(0, 0, 1))), hash(n + dot(step, vec3(1, 0, 1))), u.x), mix( hash(n + dot(step, vec3(0, 1, 1))), hash(n + dot(step, vec3(1, 1, 1))), u.x), u.y), u.z); }

#define DEFINE_FBM(name, OCTAVES) float name(vec3 x) { float v = 0.0; float a = 0.5; vec3 shift = vec3(100); for (int i = 0; i < OCTAVES; ++i) { v += a * noise(x); x = x * 2.0 + shift; a *= 0.5; } return v; }
DEFINE_FBM(fbm1, 1)
DEFINE_FBM(fbm3, 3)
DEFINE_FBM(fbm5, 5)
DEFINE_FBM(fbm6, 6)
    
const float fov = 20. * deg2rad;
const vec3 planetCenter = vec3(0.);
const float planetRadius = 1.;
const vec3 light = vec3(0., 1., 3.);
const float cellDiffThreshold = .1;

mat3 planetRotation;

vec3 hash( vec3 x )
{
	x = vec3( dot(x,vec3(127.1,311.7, 74.7)),
			  dot(x,vec3(269.5,183.3,246.1)),
			  dot(x,vec3(113.5,271.9,124.6)));

	return fract(sin(x)*43754.5453123);
}

mat2 rotate(float a)
{
    float ca = cos(a); float sa = sin(a);
    return mat2(ca, sa, -sa, ca);
}

float rand(vec2 co)
{
    return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

float rnd(vec2 p)
{
    return abs(rand(p)) * 0.8 + 0.1;
}

float value (float x, float randx, float c)
{
    float a = min(x/randx, 1.0);
    
    float d = clamp(1.0 - (randx + c), 0.1, .9);
    float b = min(1.0, (1.0 - x) / d);
    return a + (b - 1.0);
}

float polynoise(vec2 p, float sharpness)
{
    vec2 seed = floor(p);
    vec2 rndv = vec2(rnd(seed.xy), rnd(seed.yx));
    vec2 pt = fract(p);
    float bx = value(pt.x, rndv.x, rndv.y * sharpness);
    float by = value(pt.y, rndv.y, rndv.x * sharpness);
    return min(bx, by) * (0.3 + abs(rand(seed.xy * 0.01)) * 0.7);
}

vec3 mapBiome(vec3 x )
{
    x = planetRotation * x;
    
    vec3 p = floor( x );
    vec3 f = fract( x );

	float id = 0.0;
    
    // distance to closest and second closest
    vec2 res = vec2( 100.0 );
    // biome ID for closest and second closest
    vec2 resId = vec2(-1., -1.);
    
    for( int k=-1; k<=1; k++ )
    for( int j=-1; j<=1; j++ )
    for( int i=-1; i<=1; i++ )
    {
        vec3 b = vec3(float(i), float(j), float(k));
        vec3 r = vec3( b ) - f + hash( p + b );
        float d = length(r);
        id = mod(abs(dot( p+b, vec3(1.0,57.0,113.0 ))), 3.);

        if( d < res.x )
        {
            res = vec2( d, res.x );
            resId = vec2( id, resId.x );
        }
        else if( d < res.y )
        {
            res.y = d;
            resId.y = id;
        }
    }
    
    float diff = res.y - res.x;
    
    // this is a giant hack. need a better way to blend between the voronoi regions.
    float ratio1 = min(1., pow(smoothstep(1., 3., clamp(res.y / res.x, 1., 3.)), .35) + .5);
    float ratio2 = 1. - ratio1;
        
    return vec3(resId.x == 0. ? ratio1 : resId.y == 0. ? ratio2 : 0.,
                resId.x == 1. ? ratio1 : resId.y == 1. ? ratio2 : 0.,
               	resId.x == 2. ? ratio1 : resId.y == 2. ? ratio2 : 0.);
}

float polyfbm(vec2 p, float dullness)
{
    vec2 seed = floor(p);
    mat2 r1 = rotate(2.4);
    mat2 r2 = rotate(0.4);
    mat2 r3 = rotate(-2.0);
    
    // 1st octave
    float m1 = polynoise(p * r2, dullness);
    
    m1 += polynoise ( r1 * (vec2(0.5, 0.5) + p), dullness);
    m1 += polynoise ( r3 * (vec2(0.35, 0.415) + p), dullness);
    m1 *= 0.333 * 0.75;
    
    // 2nd
    float m2 = polynoise (r3 * (p * 2.0), dullness + .1);
    m2 += polynoise (r2 * (p + vec2(0.2, 0.6)) * 2.0, dullness);
    m1 += m2 * 0.5 * 0.5;
	
    return m1 + .5;
}

float calcInitialDisplacement(vec3 p, float dullness)
{
    float x = polyfbm(p.zy, dullness);
    float y = polyfbm(p.xz, dullness);
    float z = polyfbm(p.xy, dullness);
    
    vec3 n = max((abs(p) - 0.2)*7., 0.001);
    n /= (n.x + n.y + n.z ); 
    
    return x * n.x + y * n.y + z * n.z;
}

float sceneSDF(vec3 p, out bool isWater) 
{
    vec3 biome = mapBiome(p);
    isWater = false;
    p = planetRotation * p;
    vec3 surfaceLocation = normalize(p);
    float freq = 1.5;
    float mult = 1. - biome.r * .075 + biome.b * .045;
    float dullness = .2 + biome.r * .2;
    
    float elevation = calcInitialDisplacement(p * freq, dullness) * mult;
    elevation *= planetRadius;
    
    if (elevation < .7) 
    {
        elevation = .7 - pow(.7 - elevation, .25) * fbm1(surfaceLocation * 4. + iTime / 4.) * .2;
        isWater = true;
    }
    
    return (length(p) - elevation) * .8;
}

vec3 gradient(in vec3 rp)
{
    vec2 off = vec2(0.005, 0.0);
    bool temp;
    vec3 g = vec3(sceneSDF(rp + off.xyy, temp) - sceneSDF(rp - off.xyy, temp),
                  sceneSDF(rp + off.yxy, temp) - sceneSDF(rp - off.yxy, temp),
                  sceneSDF(rp + off.yyx, temp) - sceneSDF(rp - off.yyx, temp));
    return normalize(g);
}

bool rayMarch(vec3 eye, vec3 dir, float minDistance, float maxDistance,
              out float totDist, out bool isWater)
{
    totDist = minDistance;
    vec3 pos = eye;
	for (int i = 0; i < numMarches; i++)
    {
        pos = eye + totDist * dir;
        float dist = sceneSDF(pos, isWater);
        if (dist < epsilon)
        {
            return true;
        }
        else if (dist > maxDistance)
        {
            return false;
        }
        totDist += dist * .25;
    }
    
    return false;
}

vec3 shade(vec3 pos, bool isWater)
{
    vec3 normal = gradient(pos);
    vec3 lightDir = normalize(light - pos);
    vec3 ambient = vec3(.2, 0., 0.);
    
    float diffuse = max(0., dot(normal, lightDir));
    float len = length(pos);
    
    vec3 biomeWeights = mapBiome(pos * 1.);
    vec3 col = vec3(.8, .8, .1) * biomeWeights.x
        + vec3(0., 1., 0.) * biomeWeights.y
        + vec3(.2, .2, .2) * biomeWeights.z;
    
    if (biomeWeights.z > .75 && len > .8)
    {
        col = vec3(1., 1., 1.);
    }
    
    if (isWater)
    {
    	col = vec3(0., 0.62, 1.);
    }
    
    // start off just doing plain old blinn phong
	return diffuse * col + ambient;
}

vec3 draw(vec3 eye, vec3 dir, float minDistance, float maxDistance, vec2 fragCoord, vec2 invResolution)
{
    float totDist;
    bool isWater;
    if (rayMarch(eye, dir, minDistance, maxDistance, totDist, isWater)) {
        return shade(eye + dir * totDist, isWater);
    }
    else 
    {	
        float galaxyClump = (pow(noise(fragCoord.xy * (30.0 * invResolution.x) + iTime / 2.), 3.0) * 0.5 +
            pow(noise(100.0 + fragCoord.xy * (15.0 * invResolution.x)), 5.0)) / 1.5;
        return vec3(galaxyClump * pow(hash(fragCoord.xy), 1500.0) * 80.0);
    }
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    float yaw  = -((2. * iMouse.x / iResolution.x) * 2.5 - 1.25) + (autoRotate ? -iTime * 0.035 : 0.0);
	float pitch = ((2. * iMouse.y > 0.0 ? 2. * iMouse.y : iResolution.y * 0.3) / iResolution.y) * 2.5 - 1.25;
 	planetRotation = 
    	mat3(cos(yaw), 0, -sin(yaw), 0, 1, 0, sin(yaw), 0, cos(yaw)) *
    	mat3(1, 0, 0, 0, cos(pitch), sin(pitch), 0, -sin(pitch), cos(pitch));
    
    vec2 uv = fragCoord / iResolution.xy;

    vec3 eye = vec3(0., 0., 6.);
    vec3 dir = normalize(vec3(fragCoord.xy - iResolution.xy / 2., -iResolution.y / (2. * tan(fov / 2.))));
    
    // get the near and far plane for the raymarch to reduce operations
    float minDistance, maxDistance;
    intersectSphere(planetCenter, planetRadius, eye, dir, minDistance, maxDistance);
    
    fragColor.rgb = draw(eye, dir, minDistance, maxDistance, fragCoord, 1. / iResolution.xy);
}