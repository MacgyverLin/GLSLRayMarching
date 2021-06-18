const float c_pi = 3.14159265359f;
const float c_twopi = 2.0f * c_pi;

const float KEY_SPACE = 32.5/256.0;

// The minimunm distance a ray must travel before we consider an intersection.
// This is to prevent a ray from intersecting a surface it just bounced off of.
const float c_minimumRayHitTime = 0.01f;

// after a hit, it moves the ray this far along the normal away from a surface.
// Helps prevent incorrect intersections when rays bounce off of objects.
const float c_rayPosNormalNudge = 0.01f;

// the farthest we look for ray hits
const float c_superFar = 10000.0f;

// camera FOV
const float c_FOVDegrees = 120.0f;


//bounce visualization array
vec3 c_colors[8] =  vec3 [8](vec3(1.f,0.f,0.f), //RED
vec3(1.f,0.5f,0.f), //ORANGE
vec3(1.f,1.f,0.f), //YELLOW
vec3(0.0f,1.f,0.f), //Green
vec3(1.f,0.f,1.f), //magenta
vec3(0.f,1.f,0.5f), //Green bluw
vec3(0.f,1.f,1.f), //cyan
vec3(0.f,0.f,1.f) //blue
);

// a multiplier for the skybox brightness
const float c_skyboxBrightnessMultiplier = 1.0f;
    
// a pixel value multiplier of light before tone mapping and sRGB
const float c_exposure = 1.0f; 

// how many renders per frame - make this larger to get around the vsync limitation, and get a better image faster.
const int c_numRendersPerFrame = 20;

// number of ray bounces allowed max
const int c_numBounces = 10;

// mouse camera control parameters
const float c_minCameraAngle = 0.01f;
const float c_maxCameraAngle = (c_pi - 0.01f);
const vec3 c_cameraAt = vec3(0.0f, 0.0f, 0.0f);
const float c_cameraDistance = 30.0f;


// 0 = no bounce visualization
// 1 = bounce visualization
#define SHOW_BOUNCE_VIS 0

vec3 LessThan(vec3 f, float value)
{
    return vec3(
        (f.x < value) ? 1.0f : 0.0f,
        (f.y < value) ? 1.0f : 0.0f,
        (f.z < value) ? 1.0f : 0.0f);
}

vec3 LinearToSRGB(vec3 rgb)
{
    rgb = clamp(rgb, 0.0f, 1.0f);
    
    return mix(
        pow(rgb, vec3(1.0f / 2.4f)) * 1.055f - 0.055f,
        rgb * 12.92f,
        LessThan(rgb, 0.0031308f)
    );
}

vec3 SRGBToLinear(vec3 rgb)
{   
    rgb = clamp(rgb, 0.0f, 1.0f);
    
    return mix(
        pow(((rgb + 0.055f) / 1.055f), vec3(2.4f)),
        rgb / 12.92f,
        LessThan(rgb, 0.04045f)
	);
}

// ACES tone mapping curve fit to go from HDR to LDR
//https://knarkowicz.wordpress.com/2016/01/06/aces-filmic-tone-mapping-curve/
vec3 ACESFilm(vec3 x)
{
    float a = 2.51f;
    float b = 0.03f;
    float c = 2.43f;
    float d = 0.59f;
    float e = 0.14f;
    return clamp((x*(a*x + b)) / (x*(c*x + d) + e), 0.0f, 1.0f);
}