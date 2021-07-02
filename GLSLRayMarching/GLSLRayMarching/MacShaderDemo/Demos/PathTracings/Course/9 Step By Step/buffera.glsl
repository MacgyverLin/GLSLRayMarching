////////////////////////////////////////////////////////////////////////////////////////
// Constants
#define PI 3.14159265359
#define EPSILON 1e-4
#define RAY_EPSILON 1e-3
#define SUB_SAMPLES 1
#define MAX_DEPTH 64

////////////////////////////////////////////////////////////////////////////////////////
// Util functions
float seed = 0.;
float rand() 
{ 
    return fract(sin(seed++)*43758.5453123); 
}

void rand_seek(in vec2 fragCoord)
{
    seed = iTime + iResolution.y * fragCoord.x / iResolution.x + fragCoord.y / iResolution.y;
}

////////////////////////////////////////////////////////////////////////////////////////
// Data structure
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
    
    int mat;	
};
    
struct Plane 
{
    vec3 pos;		
    vec3 normal;	

    int mat;	
};

////////////////////////////////////////////////////////////////////////////////////////
// Scene Description
#define NUM_SPHERES 4
#define NUM_PLANES 6
#define NUM_MATERIALS 10

const Material materials[NUM_MATERIALS] =
{
    Material(SPEC   , vec3(1.00, 1.00, 1.00), vec3(0.00, 0.00, 0.00), 0.0),
    Material(REFR   , vec3(0.75, 1.00, 0.75), vec3(0.00, 0.00, 0.00), 1.5),
    Material(DIFF   , vec3(0.00, 0.00, 0.00), vec3(4.00, 4.00, 4.00), 0.0),
    Material(GLOSSY , vec3(0.00, 0.70, 0.70), vec3(0.00, 0.00, 0.00), 1.5),

    Material(DIFF   , vec3(0.75, 0.75, 0.75), vec3(0.00, 0.00, 0.00), 0.0),
    Material(DIFF   , vec3(0.75, 0.25, 0.25), vec3(0.00, 0.00, 0.00), 0.0),
    Material(DIFF   , vec3(0.75, 0.75, 0.75), vec3(0.00, 0.00, 0.00), 0.0),
    Material(DIFF   , vec3(0.25, 0.25, 0.75), vec3(0.00, 0.00, 0.00), 0.0),
    Material(DIFF   , vec3(0.00, 0.00, 0.00), vec3(0.00, 0.00, 0.00), 0.0),
    Material(DIFF   , vec3(0.75, 0.75, 0.75), vec3(0.00, 0.00, 0.00), 0.0)
};

const Sphere spheres[NUM_SPHERES] = 
{
    Sphere(vec3(27.0,  16.5, 47.0), 16.5, 0),
    Sphere(vec3(73.0,  16.5, 78.0), 16.5, 1),
    Sphere(vec3(50.0, 689.3, 50.0), 600., 2),
    Sphere(vec3(80.0,  56.5, 37.0), 16.5, 3)
};

const Plane planes[NUM_PLANES] =
{
    Plane(vec3( 0.00,  0.00,   0.00), vec3( 0.00,  1.00,  0.00), 4),
    Plane(vec3(-7.00,  0.00,   0.00), vec3( 1.00,  0.00,  0.00), 5),
    Plane(vec3( 0.00,  0.00,   0.00), vec3( 0.00,  0.00, -1.00), 6),
    Plane(vec3(107.00, 0.00,   0.00), vec3(-1.00,  0.00,  0.00), 7),
    Plane(vec3( 0.00,  0.00, 180.00), vec3( 0.00,  0.00,  1.00), 8),
    Plane(vec3( 0.00, 90.00,   0.00), vec3( 0.00, -1.00,  0.00), 9)
};

void mainImage( out vec4 fragColor, in vec2 fragCoord ) 
{
    rand_seek(fragCoord);

    fragColor = vec4(rand(), rand(), rand() , 1.0);
}