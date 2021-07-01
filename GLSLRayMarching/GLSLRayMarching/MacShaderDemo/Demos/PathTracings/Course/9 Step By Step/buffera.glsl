////////////////////////////////////////////////////////////////////////////////////////
// 2) Constants
#define PI 3.14159265359
#define EPSILON 1e-4
#define RAY_EPSILON 1e-3
#define SUB_SAMPLES 1
#define MAX_DEPTH 64

////////////////////////////////////////////////////////////////////////////////////////
// 1) main function
void mainImage( out vec4 fragColor, in vec2 fragCoord ) 
{
	// 3) Test Color Output
	vec2 uv = fragCoord.xy / iResolution.xy;
	fragColor = vec4(uv, 0.0, 1.0);
}