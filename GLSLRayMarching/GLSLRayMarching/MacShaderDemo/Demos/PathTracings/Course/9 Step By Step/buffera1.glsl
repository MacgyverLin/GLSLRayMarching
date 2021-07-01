////////////////////////////////////////////////////////////////////////////////////////
// Constants
#define PI 3.14159265359
#define EPSILON 1e-4
#define RAY_EPSILON 1e-3
#define SUB_SAMPLES 1
#define MAX_DEPTH 64

// Scene Description
#define NUM_SPHERES 4
#define NUM_PLANES 6

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
	float radius;	
	vec3 pos;		
	
    Material mat;	
};
    
struct Plane 
{
    vec3 pos;		
    vec3 normal;	

    Material mat;	
};

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
// Scene
Sphere spheres[NUM_SPHERES] = 
{
    Sphere(16.5, vec3(27.0,  16.5, 47.0), Material(SPEC  , vec3(1.00, 1.00, 1.00), vec3(0.00, 0.00, 0.00), 0.0)),
    Sphere(16.5, vec3(73.0,  16.5, 78.0), Material(REFR  , vec3(0.75, 1.00, 0.75), vec3(0.00, 0.00, 0.00), 1.5)),
    Sphere(600., vec3(50.0, 689.3, 50.0), Material(DIFF  , vec3(0.00, 0.00, 0.00), vec3(4.00, 4.00, 4.00), 0.0)),
    Sphere(16.5, vec3(80.0,  56.5, 37.0), Material(GLOSSY, vec3(0.00, 0.70, 0.70), vec3(0.00, 0.00, 0.00), 1.5))
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

vec3 cosWeightedSampleHemisphere(vec3 n) 
{
    float u1 = rand(), u2 = rand();
    float r = sqrt(u1);
    float theta = 2. * PI * u2;
    
    float x = r * cos(theta);
    float y = r * sin(theta);
    float z = sqrt(max(0., 1. - u1));
    
    vec3 a = n;
    vec3 b;
    
    if (abs(a.x) <= abs(a.y) && abs(a.x) <= abs(a.z))
		a.x = 1.0;
	else if (abs(a.y) <= abs(a.x) && abs(a.y) <= abs(a.z))
		a.y = 1.0;
	else
		a.z = 1.0;
        
    a = normalize(cross(n, a));
    b = normalize(cross(n, a));
    
    return normalize(a * x + b * y + n * z);
}

vec3 background(vec3 dir) 
{
    return mix(vec3(0.), vec3(.9), .5 + .5 * dot(dir, vec3(0., 1., 0.)));
    //return texture(iChannel1, dir).rgb;
}

float intersectSphere(Ray r, Sphere s) 
{
    vec3 op = s.pos - r.origin;
    float b = dot(op, r.dir);
    
    float delta = b * b - dot(op, op) + s.radius * s.radius;
	if (delta < 0.)
        return 0.; 		        
    else
        delta = sqrt(delta);
    
    float t;
    if ((t = b - delta) > EPSILON)
        return t;
    else if ((t = b + delta) > EPSILON)
        return t;
    else
        return 0.;
}

float intersectPlane(Ray r, Plane p) 
{
    float t = dot(p.pos - r.origin, p.normal) / dot(r.dir, p.normal);

    return mix(0., t, float(t > EPSILON));
}

int intersect(Ray ray, out float t, out vec3 normal, out Material mat) 
{
	int id = -1;
	t = 1e5;
	for (int i = 0; i < NUM_SPHERES; i++) 
    {
		float d = intersectSphere(ray,  spheres[i]);
		if (d != 0. && d<t) 
        { 
            id = i; 
            t = d; 
         	normal = normalize(ray.origin + ray.dir * t - spheres[i].pos);
            mat = spheres[i].mat;
        }
	}
    
    for (int i = 0; i < NUM_PLANES; i++) 
    {
        float d = intersectPlane(ray, planes[i]);
        if (d != 0. && d < t) 
        {
            id = i;
            t = d;
            normal = planes[i].normal;
            mat = planes[i].mat;
        }
    }
	return id;
}

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

vec3 trace(Ray ray) 
{
    vec3 radiance = vec3(0.0);
    vec3 reflectance = vec3(1.0);
    for (int depth = 0; depth < MAX_DEPTH; depth++) 
    {
        float t;
        vec3 n;
        Material mat;

        int id = intersect(ray, t, n, mat);
        
        if (id < 0) 
        {
            radiance += reflectance * background(ray.dir);
            break;
        }
        
        radiance += reflectance * mat.emission;
        
        vec3 color = mat.albedo;
        float p = max(color.x, max(color.y, color.z));
        // Russain roulette
        if (rand() < p)
            color /= p;
        else
            break;
        
        vec3 nl = n * sign(-dot(n, ray.dir));
        ray.origin += ray.dir * t;
		
        if (mat.refl == DIFF)
        {				
            ray.dir = cosWeightedSampleHemisphere(nl);
            reflectance *= color;
        } 
        else if (mat.refl == SPEC)
        {
            ray.dir = reflect(ray.dir, n);
            reflectance *= color;
        } 
        else if (mat.refl == GLOSSY)
        {	                      
            vec3 dir1 = cosWeightedSampleHemisphere(nl);
            vec3 dir2 = reflect(ray.dir, n);
            float rougnhess = 0.5;
            ray.dir = rougnhess * dir1 + (1.0-rougnhess) * dir2;
            reflectance *= color;            
        } 
        else
        {
            float ior = mat.ior;
            float into = float(dot(n, nl) > 0.);
            float ddn = dot(nl, ray.dir);
            float nnt = mix(ior, 1. / ior, into);
            vec3 rdir = reflect(ray.dir, n);
            float cos2t = 1. - nnt * nnt * (1. - ddn * ddn);
            if (cos2t > 0.)
            {
                vec3 tdir = normalize(ray.dir * nnt - nl * (ddn * nnt + sqrt(cos2t)));
                
                float R0 = (ior-1.) * (ior-1.) / ((ior+1.) * (ior+1.));
				float c = 1. - mix(dot(tdir, n), -ddn, into);	// 1 - cosθ
				float Re = R0 + (1. - R0) * c * c * c * c * c;
                
                float P = .25 + .5 * Re;
                float RP = Re / P, TP = (1. - Re) / (1. - P);
                
                // Russain roulette
                if (rand() < P)
                {				
                    reflectance *= RP;
                    ray.dir = rdir;
                } 
                else
                { 				        
                    reflectance *= color * TP; 
                    ray.dir = tdir; 
                }
            } 
            else
            {
                ray.dir = rdir;
            }
        }
        
        ray.origin += ray.dir * RAY_EPSILON;
    }
    return radiance;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord ) 
{
    rand_seek(fragCoord);
    
    vec3 color = vec3(0.);
    for (int x = 0; x < SUB_SAMPLES; x++) 
    {
        for (int y = 0; y < SUB_SAMPLES; y++) 
        {
        	// Tent Filter
            float r1 = 2.0 * rand();
            float r2 = 2.0 * rand();
            //float dx = mix(sqrt(r1) - 1.0, 1.0 - sqrt(2.0 - r1), float(r1 > 1.0));
            //float dy = mix(sqrt(r2) - 1.0, 1.0 - sqrt(2.0 - r2), float(r2 > 1.0));
            float dx = rand() - 0.5;
            float dy = rand() - 0.5;
            vec2 jitter = vec2(dx, dy);

            vec2 subuv = (fragCoord.xy + jitter) / iResolution.xy;

            Ray camRay = generateRay(subuv);

            color += trace(camRay);
        }
    }

    color /= float(SUB_SAMPLES * SUB_SAMPLES);
    
    vec2 uv = fragCoord.xy / iResolution.xy;
    
	color += texture(iChannel0, uv).rgb * float(iFrame);
    
	fragColor = vec4(color / float(iFrame + 1), 1.);
}