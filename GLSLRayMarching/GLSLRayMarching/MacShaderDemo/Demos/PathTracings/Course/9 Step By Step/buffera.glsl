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

////////////////////////////////////////////////////////////////////////////////////////
// 1) main function
void mainImage( out vec4 fragColor, in vec2 fragCoord ) 
{
	// 4) Random function
	rand_seek(fragCoord);

	// 3) Test Color Output
	vec2 uv = fragCoord.xy / iResolution.xy;
	fragColor = vec4(uv * vec2(rand(), rand()), 0.0, 1.0);
}