#define FLT_MAX 1000000000.0
#define EPSILON 0.001
#define SLOPE_EPSILON 0.008
#define SAMPLES 64
#define BOUNCES 4
#define COSINE_SAMPLING 1

#define MAT_WHITE           0
#define MAT_LIGHT           1
#define MAT_PIXEL           2
#define MAT_NOISE           3
#define MAT_STRIPES         4
#define MAT_ROUGH           5
#define MAT_WET             6
#define MAT_PULSE           7
#define MAT_MIRROR          8


////////////////////////////////////////////////////////////////////////////////
// Simplex Noise
////////////////////////////////////////////////////////////////////////////////

float randFancy(vec2 co)
{
    highp float a = 12.9898;
    highp float b = 78.233;
    highp float c = 43758.5453;
    highp float dt= dot(co.xy ,vec2(a,b));
    highp float sn= mod(dt,3.14);
    return fract(sin(sn) * c);
}

float rand3D(in vec3 co)
{
    return fract(sin(dot(co.xyz ,vec3(12.9898,78.233,144.7272))) * 43758.5453);
}

vec4 permute(vec4 x){return mod(((x*34.0)+1.0)*x, 289.0);}
vec4 taylorInvSqrt(vec4 r){return 1.79284291400159 - 0.85373472095314 * r;}
vec3 fade(vec3 t) {return t*t*t*(t*(t*6.0-15.0)+10.0);}
vec4 fade(vec4 t) {return t*t*t*(t*(t*6.0-15.0)+10.0);}

//	Simplex 3D Noise
//	by Ian McEwan, Ashima Arts
//
float snoise(in vec3 v)
{
  const vec2  C = vec2(1.0/6.0, 1.0/3.0) ;
  const vec4  D = vec4(0.0, 0.5, 1.0, 2.0);

// First corner
  vec3 i  = floor(v + dot(v, C.yyy) );
  vec3 x0 =   v - i + dot(i, C.xxx) ;

// Other corners
  vec3 g = step(x0.yzx, x0.xyz);
  vec3 l = 1.0 - g;
  vec3 i1 = min( g.xyz, l.zxy );
  vec3 i2 = max( g.xyz, l.zxy );

  //  x0 = x0 - 0. + 0.0 * C
  vec3 x1 = x0 - i1 + 1.0 * C.xxx;
  vec3 x2 = x0 - i2 + 2.0 * C.xxx;
  vec3 x3 = x0 - 1. + 3.0 * C.xxx;

// Permutations
  i = mod(i, 289.0 );
  vec4 p = permute( permute( permute(
             i.z + vec4(0.0, i1.z, i2.z, 1.0 ))
           + i.y + vec4(0.0, i1.y, i2.y, 1.0 ))
           + i.x + vec4(0.0, i1.x, i2.x, 1.0 ));

// Gradients
// ( N*N points uniformly over a square, mapped onto an octahedron.)
  float n_ = 1.0/7.0; // N=7
  vec3  ns = n_ * D.wyz - D.xzx;

  vec4 j = p - 49.0 * floor(p * ns.z *ns.z);  //  mod(p,N*N)

  vec4 x_ = floor(j * ns.z);
  vec4 y_ = floor(j - 7.0 * x_ );    // mod(j,N)

  vec4 x = x_ *ns.x + ns.yyyy;
  vec4 y = y_ *ns.x + ns.yyyy;
  vec4 h = 1.0 - abs(x) - abs(y);

  vec4 b0 = vec4( x.xy, y.xy );
  vec4 b1 = vec4( x.zw, y.zw );

  vec4 s0 = floor(b0)*2.0 + 1.0;
  vec4 s1 = floor(b1)*2.0 + 1.0;
  vec4 sh = -step(h, vec4(0.0));

  vec4 a0 = b0.xzyw + s0.xzyw*sh.xxyy ;
  vec4 a1 = b1.xzyw + s1.xzyw*sh.zzww ;

  vec3 p0 = vec3(a0.xy,h.x);
  vec3 p1 = vec3(a0.zw,h.y);
  vec3 p2 = vec3(a1.xy,h.z);
  vec3 p3 = vec3(a1.zw,h.w);

//Normalise gradients
  vec4 norm = taylorInvSqrt(vec4(dot(p0,p0), dot(p1,p1), dot(p2, p2), dot(p3,p3)));
  p0 *= norm.x;
  p1 *= norm.y;
  p2 *= norm.z;
  p3 *= norm.w;

// Mix final noise value
  vec4 m = max(0.6 - vec4(dot(x0,x0), dot(x1,x1), dot(x2,x2), dot(x3,x3)), 0.0);
  m = m * m;
  return 42.0 * dot( m*m, vec4( dot(p0,x0), dot(p1,x1),
                                dot(p2,x2), dot(p3,x3) ) );
}
//	Simplex 4D Noise
//	by Ian McEwan, Ashima Arts
//
float permute(float x){return floor(mod(((x*34.0)+1.0)*x, 289.0));}
float taylorInvSqrt(float r){return 1.79284291400159 - 0.85373472095314 * r;}

vec4 grad4(float j, vec4 ip){
  const vec4 ones = vec4(1.0, 1.0, 1.0, -1.0);
  vec4 p,s;

  p.xyz = floor( fract (vec3(j) * ip.xyz) * 7.0) * ip.z - 1.0;
  p.w = 1.5 - dot(abs(p.xyz), ones.xyz);
  s = vec4(lessThan(p, vec4(0.0)));
  p.xyz = p.xyz + (s.xyz*2.0 - 1.0) * s.www;

  return p;
}

struct Intersection
{
    float distance;
    int objectID;
};

struct Ray
{
    vec3 origin;
    vec3 direction;
};

struct Material
{
    vec3 color;
    float emmisive;
    float roughness;
};

struct Sphere
{
    vec3 origin;
    float radius;
    int material;    
};

struct Box
{
    vec3 origin;
    vec3 extent;
    int material;    
};

struct Camera
{
    vec3 origin;
	vec3 lowerLeftCorner;
	vec3 horizontal;
	vec3 vertical;
};

// From Lighthouse
uint WangHash(inout uint s)
{
    s = (s ^ uint(61)) ^ (s >> 16);
    s *= uint(9);
    s = s ^ (s >> 4);
    s *= uint(0x27d4eb2d);
    s = s ^ (s >> 15);
    return s;
}

uint RandomInt(inout uint s)
{
    s ^= s << 13;
    s ^= s >> 17;
    s ^= s << 5;
    return s;
}

float RandomFloat(inout uint s)
{
    //return float(RandomInt(s)) * 2.3283064365387e-10;    
    return fract(float(RandomInt(s)) / 3141.592653);
}

vec3 RandomVec3(inout uint s)
{
    vec3 v = vec3(
        (RandomFloat(s) - 0.5f) * 2.0,
        (RandomFloat(s) - 0.5f) * 2.0,
        (RandomFloat(s) - 0.5f) * 2.0);
    return v;
}

vec3 RandomUnitSphere(inout uint s)
{
    vec3 v = vec3(1.0);
    for(int i = 0; i < 16; i++)
	{
        v = RandomVec3(s);
        if(length(v) <= 1.0)
            break;
	}    
    //return v;
    return normalize(v);
}

#define SPHERE_COUNT 11
const Sphere spheres[SPHERE_COUNT] = Sphere[SPHERE_COUNT](
	  Sphere(vec3(0.0, 2.0, 0.0), 2.0, MAT_STRIPES)                     // Big middle
	, Sphere(vec3(3.0, 1.0, 0.0), 1.0, MAT_ROUGH)            
    , Sphere(vec3(0.0, 0.5, 2.6), 0.5, MAT_PULSE)                       
    , Sphere(vec3(0.0, 1.0, -4.0), 1.0, MAT_MIRROR)
    , Sphere(vec3(-3.0, 0.7, 0.0), 0.7, MAT_WHITE)
    , Sphere(vec3(0.0, -10000.0, 0.0), 10000.0, MAT_WET)              // Bottom
    , Sphere(vec3(0.0, 10009.0, 0.0), 10000.0, MAT_WHITE)               // Top
    , Sphere(vec3(10009.0, 0.0, 0.0), 10000.0, MAT_PIXEL)               // Side
    , Sphere(vec3(-10009.0, 0.0, 0.0), 10000.0, MAT_NOISE)              // Side
    , Sphere(vec3(0.0, 0.0, 10009.0), 10000.0, MAT_WHITE)               // Side
    , Sphere(vec3(0.0, 0.0, -10009.0), 10000.0, MAT_WHITE)              // Side    
);

const vec3 background = vec3(1.0f, 0.96, 0.92);

const uint k = 1103515245U;  // GLIB C
vec3 hash( uvec3 x )
{
    x = ((x>>8U)^x.yzx)*k;
    x = ((x>>8U)^x.yzx)*k;
    x = ((x>>8U)^x.yzx)*k;
    return vec3(x)*(1.0/float(0xffffffffU));
}

float hash(float seed)
{
    return fract(sin(seed)*43758.5453 );
}

vec3 cosineDirection( in float seed, in vec3 nor)
{
    // compute basis from normal
    // see http://orbit.dtu.dk/fedora/objects/orbit:113874/datastreams/file_75b66578-222e-4c7d-abdf-f7e255100209/content
    // (link provided by nimitz)
    vec3 tc = vec3( 1.0+nor.z-nor.xy*nor.xy, -nor.x*nor.y)/(1.0+nor.z);
    vec3 uu = vec3( tc.x, tc.z, -nor.x );
    vec3 vv = vec3( tc.z, tc.y, -nor.y );
    
    float u = hash( 78.233 + seed);
    float v = hash( 10.873 + seed);
    float a = 6.283185 * v;

    return  sqrt(u)*(cos(a)*uu + sin(a)*vv) + sqrt(1.0-u)*nor;
}

float sphereTest(in Ray ray, in Sphere sphere)
{
    float t = -1.0;
	vec3 rc = ray.origin - sphere.origin;
	float c = dot(rc, rc) - (sphere.radius * sphere.radius);
	float b = dot(ray.direction, rc);
	float d = b*b - c;
    if(d > 0.0)
    {
	    t = -b - sqrt(abs(d));
        return t;
	    float st = step(0.0, min(t,d));
    } else  
    {
        return -1.0;
    }
}

Intersection intersect(in Ray ray)
{
    float minD = FLT_MAX;
    Intersection intersection;
    for(int i = 0; i < SPHERE_COUNT; i++)
    {
        Sphere s = spheres[i];
        float t = sphereTest(ray, s);
        if(t > 0.0 && t < minD)
        {
            minD = t;
            intersection.distance = t;
            intersection.objectID = i;
        }
    }
    return intersection;
}

vec3 getNormal(in vec3 position, in int objectID)
{
    Sphere s = spheres[objectID];
    return normalize(position - s.origin);
}

Material getMaterial(in vec3 position, in int objectID)
{
    int mat = spheres[objectID].material;
    switch(mat)
    {
        case MAT_WHITE :
        {
            return Material(vec3(1.0, 1.0, 1.0), 0.0, 1.0);
        }
        case MAT_LIGHT :
        {
            return Material(vec3(1.0, 1.0, 1.0), 1.0, 1.0);
        }
        case MAT_PIXEL :
          {
            if(rand3D(round(position + vec3(iTime * 6.0, 0.0, 0.0))) > 0.70)
                return Material(vec3(1.20, 1.0, 1.0), 1.0, 1.0);
            else
                return Material(vec3(1.0, 1.0, 1.0), 0.0, 0.05);
        }                
        case MAT_NOISE : 
        {
            //if(abs(snoise(position + vec3(iTime * 1.0, 0.0, 0.0))) < 0.01)
            //if(rand3D(round(position * 5.0 + vec3(iTime * 6.0, 0.0, 0.0))) > 0.70)
            if(sin((position.y - position.z + iTime * 2.9) * 4.0) < 0.0)
                return Material(vec3(1.20, 1.0, 1.0), 1.0, 1.0);
            else
                return Material(vec3(1.0, 1.0, 1.0), 0.0, 0.85);
        }
        case MAT_STRIPES :
        {
            if(sin((position.y + position.z + iTime * 0.9) * 12.0) < 0.0)
                return Material(vec3(1.20, 1.0, 1.0), 1.0, 1.0);
            else
                return Material(vec3(1.0, 1.0, 1.0), 0.0, 1.0);
        }
        case MAT_ROUGH :
        {
            return Material(vec3(1.0, 1.0, 1.0), 0.0, 0.5);
        }
        case MAT_WET :
        {
            float noiz = abs(pow(snoise(position), 2.0));
            return Material(vec3(1.0, 1.0, 1.0), 0.0, noiz);            
        }
        case MAT_PULSE :
        {
            float v = pow(max(sin(iTime * 10.9), 0.0), 3.0);
            return Material(vec3(v, v, v), 2.0, 1.0);            
        }
        case MAT_MIRROR :
        {
            return Material(vec3(1.0, 1.0, 1.0), 0.0, 0.0);
        }
            break;
    }
}

vec3 getBackground(in vec3 direction)
{
    return vec3(0.9, 0.85, 1.0);
}

Camera MakeCamera(  in vec3 origin,
                    in vec3 lookAt,
                    in vec3 up,
	                float fov,
	                float aspect)
{
    Camera camera;
    vec3 u, v, w;
	float theta = radians(fov);
	float halfHeight = tan(theta * 0.5f);
	float halfWidth = aspect * halfHeight;
	w = normalize(origin - lookAt);
	u = normalize(cross(normalize(up), w));
	v = normalize(cross(w, u));
    camera.origin = origin;
	camera.lowerLeftCorner =  origin - halfWidth * u - halfHeight * v - w;
	camera.horizontal = 2.0f * halfWidth * u;
	camera.vertical = 2.0f * halfHeight * v;
    return camera;
}

Ray MakeRay(in Camera camera,float s, float t)
{
    vec3 direction = camera.lowerLeftCorner + s * camera.horizontal + (1.0f -  t) * camera.vertical - camera.origin;
    direction = normalize(direction);
	return Ray(camera.origin, direction);
}

vec3 lightDirection()
{
    float x = sin(0.5 * 5.0);
    float y = 1.0;
    float z = cos(0.5 * 5.0) - 3.0;
    return normalize(vec3(x, y, z));
}

float sphereTest(   vec3 ray,
                    vec3 dir,
                    vec3 center,
                    float radius,
                    out vec3 normal,
                    out float t)
{
	vec3 rc = ray-center;
	float c = dot(rc, rc) - (radius*radius);
	float b = dot(dir, rc);
	float d = b*b - c;
	t = -b - sqrt(abs(d));
	float st = step(0.0, min(t,d));
    vec3 pos = ray + dir * t;
    normal = pos - center;
    normal = normalize(normal);
    return mix(-1.0, t, st);
}

vec3 applyLighting(in vec3 position, in vec3 normal, int objectID)
{
    return vec3(0.0);
    vec3 light = normalize(vec3(1.0, 1.0, 1.0));
    return vec3(max(dot(normal, light), 0.0));
}

vec3 getBRDFRay(in vec3 position, in vec3 normal, in vec3 incident, int objectID, inout uint seed)
{    
    vec3 ref = reflect(incident, normal);
    Sphere sphere = spheres[objectID];
    Material material = getMaterial(position, objectID);
    vec3 offset = mix(ref, normal, material.roughness);
    //return normalize(RandomUnitSphere(seed) * material.roughness + offset);
    return normalize(RandomUnitSphere(seed) * material.roughness + ref);
}

vec3 GetHemisphereVector(in vec3 normal, inout uint seed)
{
    vec3 r = RandomUnitSphere(seed);
    if(dot(normal, r) < 0.0)
        return -r;
    return r;
}

// create light paths iteratively
vec3 rendererCalculateColor(Ray ray, in int bounces, uint seed)
{
    vec3 accumulator = vec3(0.0);  // accumulator - should get brighter
    vec3 mask = vec3(1.0);  // mask - should get darker

    for( int i = 0; i < bounces; i++)
    {
        // intersect scene
        Intersection intersection = intersect(ray);
        
        // if nothing found, return background color or break
        if(intersection.distance <= 0.0) 
            break;
        
        // get position and normal at the intersection point
        vec3 pos = ray.origin + ray.direction * intersection.distance;
        vec3 normal = getNormal(pos, intersection.objectID);
        
        // get color for the surface
        Material material = getMaterial(pos, intersection.objectID);

        // compute direct lighting
        vec3 emmisive = material.emmisive * material.color;

        // prepare ray for indirect lighting gathering        
#ifdef COSINE_SAMPLING
        vec3 dir = getBRDFRay(pos, normal, ray.direction, intersection.objectID, seed);        
#else   
        vec3 dir = GetHemisphereVector(normal, seed);     
#endif
        ray.direction = dir;
        float ND = max(dot(ray.direction, normal), 0.0);
        ray.origin = pos + normal * (1.0 - pow(ND, 2.0)) * SLOPE_EPSILON;

        // surface * lighting
#ifdef COSINE_SAMPLING
        mask *= material.color;
#else   
        mask *= material.color * ND * (3.14 / 2.0);             
#endif

        accumulator += mask * emmisive;
    }

    return accumulator;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord)
{
    float x = fragCoord.x;
    float y = fragCoord.y;
    float width = iResolution.x;
    float height = iResolution.y;
    
    float cx = sin(iTime * 1.0) * 10.0;
    float cy = 1.0;
    float cz = cos(iTime * 1.0) * 10.0; 

    Camera camera = MakeCamera(
        vec3(cx, cy, cz),
        vec3(0.0, 2.0, 0.0),
        vec3(0.0, 0.1, 0.0),
        60.0, 1.6);

    vec3 sa = hash( uvec3(x, y, iTime * 60.0) );
    uint seed = (uint(x) + uint(y) * uint(width)) ^ uint(iTime * 10000000.0);
    seed = WangHash(seed);

    vec3 color = vec3(0.0);
    for( int i = 0; i < SAMPLES; i++)
    {
        float xs = x + RandomFloat(seed) + 0.5;
        float ys = y + RandomFloat(seed) + 0.5;
        Ray ray = MakeRay(camera, xs / width, 1.0 - (ys / height));
        color += rendererCalculateColor(ray, BOUNCES, seed);
        seed += uint(hash(float(i)) * 100.0);
    }
    color /= float(SAMPLES);

    fragColor = vec4(pow(color, vec3(0.45)), 1.0);
}