////////////////////////////////////////////////////////////////////////////////////////
// 2) Constants
#define PI 3.14159265359
#define EPSILON 1e-4
#define RAY_EPSILON 1e-3
#define SUB_SAMPLES 1
#define MAX_DEPTH 64

////////////////////////////////////////////////////////////////////////////////////////
// Util functions
// 4) Random function
float seed = 0.0;
float rand() 
{ 
    return fract(sin(seed++)*43758.5453123); 
}

void rand_seek(in vec2 fragCoord)
{
    seed = iTime + iResolution.y * fragCoord.x / iResolution.x + fragCoord.y / iResolution.y;
}

////////////////////////////////////////////////////////////////////////////////////////
// 5) Data structure
struct Ray 
{ 
    vec3 origin;
    vec3 dir;
};

// Material Types
#define DIFF 0
#define SPEC 1
#define REFR 2
#define GLOSSY 3
struct Material 
{
    int refl;	    
    vec3 albedo;	
    vec3 emission;
    float ior;		
};
    
struct Sphere 
{
	vec3 pos;
	float radius;
    Material mat;	
};

struct Plane 
{
    vec3 pos;
    vec3 normal;
    Material mat;
};

////////////////////////////////////////////////////////////////////////////////////////
// 6 Scene Description
#define NUM_SPHERES 4
#define NUM_PLANES 6

Sphere spheres[NUM_SPHERES] = 
{
    Sphere(vec3(50.0, 689.3, 50.0), 600.0, Material(DIFF  , vec3(0.00, 0.00, 0.00), vec3(4.00, 4.00, 4.00), 0.0)),
    Sphere(vec3(27.0,  16.5, 47.0),  16.5, Material(SPEC  , vec3(1.00, 1.00, 1.00), vec3(0.00, 0.00, 0.00), 0.0)),
    Sphere(vec3(73.0,  16.5, 78.0),  16.5, Material(REFR  , vec3(0.75, 1.00, 0.75), vec3(0.00, 0.00, 0.00), 1.5)),    
    Sphere(vec3(80.0,  56.5, 37.0),  16.5, Material(GLOSSY, vec3(0.00, 0.70, 0.70), vec3(0.00, 0.00, 0.00), 1.5))
};

Plane planes[NUM_PLANES] =
{
    Plane(vec3( 0.00,  0.00,   0.00), vec3( 0.00,  1.00,  0.00), Material(DIFF, vec3(0.75, 0.75, 0.75), vec3(0.0, 0.0, 0.0), 0.0)),
    Plane(vec3(-7.00,  0.00,   0.00), vec3( 1.00,  0.00,  0.00), Material(DIFF, vec3(0.75, 0.25, 0.25), vec3(0.0, 0.0, 0.0), 0.0)),
    Plane(vec3( 0.00,  0.00,   0.00), vec3( 0.00,  0.00, -1.00), Material(DIFF, vec3(0.75, 0.75, 0.75), vec3(0.0, 0.0, 0.0), 0.0)),
    Plane(vec3(107.00, 0.00,   0.00), vec3(-1.00,  0.00,  0.00), Material(DIFF, vec3(0.25, 0.25, 0.75), vec3(0.0, 0.0, 0.0), 0.0)),
    Plane(vec3( 0.00,  0.00, 180.00), vec3( 0.00,  0.00,  1.00), Material(DIFF, vec3(0.00, 0.00, 0.00), vec3(0.0, 0.0, 0.0), 0.0)),
    Plane(vec3( 0.00, 90.00,   0.00), vec3( 0.00, -1.00,  0.00), Material(DIFF, vec3(0.75, 0.75, 0.75), vec3(0.0, 0.0, 0.0), 0.0))
};

Ray generateRay(vec2 uv) 
{
    vec2 p = uv * 2.0 - 1.0;
    
    vec3 cameraPosition = vec3(50.0, 40.8, 172.0);
    vec3 cameraTarget = vec3(50.0, 40.0, 81.6);
    float near = 1.947;

	vec3 cameraZ = normalize(cameraTarget - cameraPosition);
	vec3 rightHandSide = vec3(1.0, 0.0, 0.0);
	vec3 cameraY = normalize(cross(rightHandSide, cameraZ)); 
    vec3 cameraX = cross(cameraZ, cameraY);
    
    float aspectRatio = iResolution.x / iResolution.y;
    return Ray(cameraPosition, normalize(p.x * aspectRatio * cameraX + p.y * cameraY + cameraZ * near));
}

struct HitRecord
{ 
    float t;             // t for ray
    vec3 normal;         // contact normal
    vec3 position;       // contact pos
    Material material;
    int id;
};

bool intersect(Ray ray, out HitRecord hit) 
{
	int id = -1;
	hit.t = 1e5;

	return true;
}

vec3 traceWorld(Ray ray) 
{
    vec3 radiance = vec3(0.0);
    vec3 reflectance = vec3(1.0);

    for (int depth = 0; depth < MAX_DEPTH; depth++) 
    {
        HitRecord hitrec;
        bool hit = intersect(ray, hitrec);
        
        ray.origin += ray.dir * RAY_EPSILON;
    }

    return radiance;
}

////////////////////////////////////////////////////////////////////////////////////////
// 1) main function
void mainImage( out vec4 fragColor, in vec2 fragCoord ) 
{
	// 4) Random function
	rand_seek(fragCoord);

    // init color to zero
    vec3 color = vec3(0.);

    
    {
        // screen coordinate
        vec2 uv = fragCoord.xy / iResolution.xy;

        // Ray Generation
        Ray camRay = generateRay(uv);

        // Trace the World
        color += traceWorld(camRay);
    }

	vec2 uv = fragCoord.xy / iResolution.xy;
	fragColor = vec4(color, 1.0);
}