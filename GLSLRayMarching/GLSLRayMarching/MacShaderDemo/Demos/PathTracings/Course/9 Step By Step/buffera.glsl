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
    Material(DIFF   , vec3(0.00, 0.70, 0.70), vec3(0.00, 0.00, 0.00), 1.5),

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

////////////////////////////////////////////////////////////////////////////////////////
vec3 getViewDir()
{
    //return vec3(0.0, 0.0, -90.4);

    vec2 p = iMouse.xy / iResolution.xy;

    float phi = (2.0 * (p.x - 0.5)) * 3.14;
    float theta = (2.0 * (p.y - 0.5)) * (3.14 / 2.0) * 0.6;

    return vec3(cos(theta)*cos(phi), sin(theta), cos(theta)*sin(phi));
}


Ray generateRay(vec2 uv) 
{
    vec2 p = uv * 2.0 - 1.0;
    
    vec3 cameraPosition = vec3(50.0, 40.8, 172.0);
    vec3 cameraTarget = cameraPosition + getViewDir();
    float near = 1.947;

	vec3 cameraZ = normalize(cameraTarget - cameraPosition);
	vec3 up = vec3(0.0, 1.0, 0.0);
	vec3 cameraX = normalize(cross(cameraZ, up)); 
    vec3 cameraY = cross(cameraX, cameraZ);
    
    float aspectRatio = iResolution.x / iResolution.y;
    return Ray(cameraPosition, normalize(p.x * aspectRatio * cameraX + p.y * cameraY + cameraZ * near));
}

struct HitRecord
{
    int id;
    float t;
    vec3 position;
    vec3 normal;    
    int mat;
};

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

bool intersect(Ray ray, out HitRecord hitRecord) 
{
	hitRecord.id = -1;
	hitRecord.t = 1e5;

	for (int i = 0; i < NUM_SPHERES; i++) 
    {
		float intersect_t = intersectSphere(ray, spheres[i]);
		if (intersect_t != 0. && intersect_t < hitRecord.t) 
        { 
            hitRecord.id = i; 
            hitRecord.t = intersect_t;
            hitRecord.position = ray.origin + ray.dir * hitRecord.t;
         	hitRecord.normal = normalize(hitRecord.position - spheres[i].pos);
            hitRecord.mat = spheres[i].mat;
        }
	}

	return hitRecord.id != -1;
}

vec3 cubeMap(vec3 dir)
{
    dir = normalize(dir);

    vec2 uv;
    uv.x = (atan(dir.x, dir.z) + (3.14)) / (2 * 3.14);
    uv.y = (asin(dir.y) + (3.14 / 2.0)) / (3.14);
    return texture(iChannel1, uv).rgb;
}

vec3 background(vec3 dir) 
{
    //return mix(vec3(0.), vec3(.9), .5 + .5 * dot(dir, vec3(0., 1., 0.)));
    //return texture(iChannel1, dir).rgb;

    return cubeMap(dir);
}


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

vec3 randomHemisphereDir(vec3 nl)
{
    float u1 = rand(), u2 = rand();
    float r = sqrt(u1);
    float theta = 2. * PI * u2;
    
    float x = r * cos(theta);
    float y = r * sin(theta);
    float z = sqrt(max(0., 1. - u1));

    return vec3(x, y, z);
}

void material_brdf(in HitRecord hitRecord, inout vec3 dir, inout vec3 reflectance)
{
    // get material
    Material mat = materials[hitRecord.mat];

    vec3 color = mat.albedo;

    vec3 nl = hitRecord.normal * sign(-dot(hitRecord.normal, dir));
    
    // hit shader
    if (mat.refl == DIFF)
    {
        dir = randomHemisphereDir(nl);
        reflectance *= color;
    } 
    else if (mat.refl == SPEC)
    {
        dir = reflect(dir, hitRecord.normal);
        reflectance *= color;
    } 
    else
    {
    }
}

vec3 traceWorld(Ray ray) 
{
    vec3 radiance = vec3(0.0);
    vec3 reflectance = vec3(1.0);

    for (int depth = 0; depth < MAX_DEPTH; depth++) 
    {
        HitRecord hitRecord;
        
        if(intersect(ray, hitRecord))
        {
            // get material
            Material mat = materials[hitRecord.mat];

            // add emission
            radiance += reflectance * mat.emission;

            // get albedo
            vec3 color = mat.albedo;

            // move ray origin to hit point
            ray.origin = hitRecord.position;

            material_scatter(hitRecord, ray.dir, reflectance);

            ray.origin += ray.dir * RAY_EPSILON;
        }
        else
        {
            // miss shader
            radiance += reflectance * background(ray.dir);
            break;
        }
    }

    return radiance;
}

const vec2 acc_start_uv = vec2(0.0);
vec3 outputColor(vec3 color, in vec2 fragCoord)
{
    vec2 coord = floor(fragCoord.xy);
    if(all(equal(coord.xy, acc_start_uv)))
    {
	    if(iMouse.z > 0.0)
            return vec3(iFrame); // save Start Frame in pixel
        else 
            return texture(iChannel0, (acc_start_uv + vec2(0.5, 0.5)) / iResolution.xy).rgb; // return Start Frame in pixel
    }
    else
    {
        int frame = iFrame - int(texture(iChannel0, (acc_start_uv + vec2(0.5, 0.5)) / iResolution.xy).x);
        
        vec3 oldcolor = texture(iChannel0, fragCoord.xy / iResolution.xy).rgb;
        
        color = oldcolor * float(frame) / float(frame + 1) + color / float(frame + 1);

        return color;
    }
}

void mainImage( out vec4 fragColor, in vec2 fragCoord ) 
{
    rand_seek(fragCoord);

    vec3 color = vec3(0);
    {
        vec2 uv = (fragCoord.xy) / iResolution.xy;
        
        Ray camRay = generateRay(uv);
        
        color += traceWorld(camRay);
    }

    // blend with previous frame
    // alpha = N / (N+1) 
    // Cresult = Cn-1 * alpha + Cn * (1 - alpha)
    fragColor = vec4(outputColor(color, fragCoord), 1);
}