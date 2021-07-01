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
// 4) Data structure
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
// 1) main function
void mainImage( out vec4 fragColor, in vec2 fragCoord ) 
{
	// 4) Random function
	rand_seek(fragCoord);

	// 3) Test Color Output
	vec2 uv = fragCoord.xy / iResolution.xy;
	fragColor = vec4(uv * vec2(rand(), rand()), 0.0, 1.0);
}