////////////////////////////////////////////////////////////////////////////////////////
// Constants
#define PI 3.14159265359
#define HALF_PI (PI * 0.5)
#define TWO_PI (PI * 2.0)
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

const vec2 acc_start_coord       = vec2(0, 0);
const vec2 metallic_coord        = vec2(1, 0);
const vec2 camerapos_coord       = vec2(2, 0);
const vec2 params_coord          = vec2(3, 0);

int getStartFrame()
{
    return int(texture(iChannel0, (acc_start_coord + vec2(0.5, 0.5)) / iResolution.xy).r);
}

float getMetallic()
{
    if(iFrame==0)
        return 0.5;
    else
        return texture(iChannel0, (metallic_coord + vec2(0.5, 0.5)) / iResolution.xy).r;
}

float getRoughness()
{
    if(iFrame==0)
        return 0.5;
    else
        return texture(iChannel0, (metallic_coord + vec2(0.5, 0.5)) / iResolution.xy).g;
}

float getNormalMapEnabled()
{
    return texture(iChannel0, (metallic_coord + vec2(0.5, 0.5)) / iResolution.xy).b;
}

float getIor()
{
    return texture(iChannel0, (params_coord + vec2(0.5, 0.5)) / iResolution.xy).r;
}

vec3 getViewDir()
{
    //return vec3(0.0, 0.0, -90.4);

    vec2 p = iMouse.xy / iResolution.xy;

    float phi = (2.0 * (p.x - 0.5) - 0.25) * 2 * 3.14;
    float theta = (2.0 * (p.y - 0.5)) * (3.14 / 2.0) * 0.6;

    return vec3(cos(theta)*cos(phi), sin(theta), cos(theta)*sin(phi));
}

vec3 getCameraPos()
{
    if(iFrame==0)
        return vec3(0.0, 0.0, 142.0);
    else
        return texture(iChannel0, (camerapos_coord + vec2(0.5, 0.5)) / iResolution.xy).rgb;
}

#define KEY_DOWN(key)   (texture(iChannel2, vec2((float(int(key)+1) + 0.5)/256, (0.0 + 0.5)/3)).r == 0)
#define KEY_CLICK(key)  (texture(iChannel2, vec2((float(int(key)+1) + 0.5)/256, (1.0 + 0.5)/3)).r == 0)
#define KEY_TOGGLE(key) (texture(iChannel2, vec2((float(int(key)+1) + 0.5)/256, (2.0 + 0.5)/3)).r == 0)

bool needRedraw()
{
    return iMouse.z > 0.0 || 
        KEY_DOWN('r') || KEY_DOWN('f') || 
        KEY_DOWN('t') || KEY_DOWN('g') || 
        KEY_DOWN('n') || 
        KEY_DOWN('w') || KEY_DOWN('s') ||
        KEY_DOWN('a') || KEY_DOWN('d');
}

vec3 outputColor(vec3 color, in vec2 fragCoord)
{
    if(all(equal(floor(fragCoord.xy).xy, acc_start_coord)))
    {
	    if(needRedraw())
            return vec3(iFrame);    // save Start Frame in pixel
        else 
            return vec3(getStartFrame()); // return Start Frame in pixel
    }
    else if(all(equal(floor(fragCoord.xy).xy, camerapos_coord)))
    {
        vec3 cameraPos = getCameraPos();

	    if(KEY_DOWN('w'))
        {
            cameraPos += getViewDir();
        }
	    else if(KEY_DOWN('s'))
        {
            cameraPos -= getViewDir();
        }

        return cameraPos;
    }
    else if(all(equal(floor(fragCoord.xy).xy, metallic_coord)))
    {
        float metallic = getMetallic();
	    if(KEY_DOWN('r'))
        {
            metallic += 0.001;
            if(metallic > 1.0)
                metallic = 1.0;
        }
	    else if(KEY_DOWN('f'))
        {
            metallic -= 0.001;
            if(metallic < 0.0)
                metallic = 0.0;
        }

        float roughness = getRoughness();
	    if(KEY_DOWN('t'))
        {
            roughness += 0.01;
            if(roughness > 1.0)
                roughness = 1.0;
        }
	    else if(KEY_DOWN('g'))
        {
            roughness -= 0.01;
            if(roughness < 0.0)
                roughness = 0.0;
        }

        float normalMapEnabled = getNormalMapEnabled();
	    if(KEY_CLICK('n'))
        {
            normalMapEnabled = 1.0 - normalMapEnabled;
        }
        
        return vec3(metallic, roughness, normalMapEnabled);
    }
    else if(all(equal(floor(fragCoord.xy).xy, params_coord)))
    {
        float metallic = getMetallic();
	    if(KEY_DOWN('r'))
        {
            metallic += 0.001;
            if(metallic > 1.0)
                metallic = 1.0;
        }
	    else if(KEY_DOWN('f'))
        {
            metallic -= 0.001;
            if(metallic < 0.0)
                metallic = 0.0;
        }

        float roughness = getRoughness();
	    if(KEY_DOWN('t'))
        {
            roughness += 0.01;
            if(roughness > 1.0)
                roughness = 1.0;
        }
	    else if(KEY_DOWN('g'))
        {
            roughness -= 0.01;
            if(roughness < 0.0)
                roughness = 0.0;
        }

        float normalMapEnabled = getNormalMapEnabled();
	    if(KEY_CLICK('n'))
        {
            normalMapEnabled = 1.0 - normalMapEnabled;
        }
        
        return vec3(metallic, roughness, normalMapEnabled);
    }
    else
    {
        int frame = iFrame - getStartFrame();
        
        vec3 oldcolor = texture(iChannel0, fragCoord.xy / iResolution.xy).rgb;
        
        color = oldcolor * float(frame) / float(frame + 1) + color / float(frame + 1);

        return color;
    }
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
#define TRANS 2
#define GLOSSY 3
struct Material 
{
    int refl;
    int albedoTexture;
    vec3 albedo;
    int emissionTexture;
    vec3 emission;
    float ior;

    int normalTexture;
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
    vec3 right;
    vec3 up;
    vec2 uvScale;

    int mat;
};

////////////////////////////////////////////////////////////////////////////////////////
// Scene Description
#define NUM_SPHERES 4
#define NUM_PLANES 6
#define NUM_MATERIALS 10

const Material materials[NUM_MATERIALS] =
{
    Material(DIFF  , -1, vec3(0.00, 0.00, 0.00), -1, vec3(4.00, 4.00, 4.00), 0.0, -1),
    Material(SPEC  ,  0, vec3(1.00, 1.00, 1.00), -1, vec3(0.00, 0.00, 0.00), 0.0,  0),
    Material(TRANS , -1, vec3(1.00, 1.00, 1.00), -1, vec3(0.00, 0.00, 0.00), 1.5,  2),
    Material(GLOSSY,  1, vec3(0.75, 1.00, 0.75), -1, vec3(0.00, 0.00, 0.00), 0.0,  1),

    Material(DIFF  ,  0, vec3(0.75, 0.75, 0.75), -1, vec3(0.00, 0.00, 0.00), 0.0,  0),
    Material(DIFF  ,  1, vec3(0.75, 0.25, 0.25), -1, vec3(0.00, 0.00, 0.00), 0.0,  1),
    Material(DIFF  ,  2, vec3(0.75, 0.75, 0.75), -1, vec3(0.00, 0.00, 0.00), 0.0,  2),
    Material(DIFF  ,  3, vec3(0.25, 0.25, 0.75), -1, vec3(0.00, 0.00, 0.00), 0.0,  3),
    Material(DIFF  ,  0, vec3(0.25, 0.25, 0.25), -1, vec3(0.00, 0.00, 0.00), 0.0,  0),
    Material(DIFF  ,  1, vec3(0.75, 0.75, 0.75), -1, vec3(0.00, 0.00, 0.00), 0.0,  1)
};

float light_intensity = 1.0;
const Sphere spheres[NUM_SPHERES] = 
{
    Sphere(vec3(50.0 - 50, 600 + (68 + (69.95-68)*(1-light_intensity)), 50.0-50.0), 600.0, 0),
    Sphere(vec3(27.0 - 50,  16.5-50.0, 50.0-50.0),  16.5, 1),
    Sphere(vec3(73.0 - 50,  16.5-50.0, 50.0-50.0),  16.5, 2),
    Sphere(vec3(80.0 - 50,  56.5-50.0, 50.0-50.0),  16.5, 3)
};

const Plane planes[NUM_PLANES] =
{
    Plane(vec3(-70.00, -70.0, -50.0), vec3( 0.00,  1.00, 0.00), vec3( 0.00, 0.00, 1.00), vec2(140.0, 140.0), 4),
    Plane(vec3( 70.00, -70.0, -50.0), vec3( 0.00, -1.00, 0.00), vec3( 0.00, 0.00, 1.00), vec2(140.0, 140.0), 5),

    Plane(vec3(-70.00, -70.0, -50.0), vec3( 1.00,  0.00, 0.00), vec3( 0.00, 1.00, 0.00), vec2(140.0, 140.0), 6),
    Plane(vec3(-70.00, -70.0, 150.0), vec3(-1.00,  0.00, 0.00), vec3( 0.00, 1.00, 0.00), vec2(140.0, 140.0), 7),

    Plane(vec3(-70.00, -70.0, -50.0), vec3( 1.00,  0.00, 0.00), vec3( 0.00, 0.00, 1.00), vec2(140.0, 140.0), 8),
    Plane(vec3(-70.00,  70.0, -50.0), vec3(-1.00,  0.00, 0.00), vec3( 0.00, 0.00, 1.00), vec2(140.0, 140.0), 9)
};

////////////////////////////////////////////////////////////////////////////////////////
Ray generateRay(vec2 uv) 
{
    vec2 p = uv * 2.0 - 1.0;
    
    vec3 cameraPosition = getCameraPos();
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
    vec3 tangent;
    vec3 binormal;
    int mat;
    vec2 texcoord;
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

vec3 getPlaneNormal(Plane p) 
{
    return normalize(cross(p.right, p.up));
}

float intersectPlane(Ray r, Plane p) 
{
    vec3 normal = getPlaneNormal(p);

    float t = dot(p.pos - r.origin, normal) / dot(r.dir, normal);

    return mix(0., t, float(t > EPSILON));
}

void convertSpherePositionToUV(in Sphere sphere, in vec3 position, in vec3 normal, out vec2 texcoord, out vec3 tangent, out vec3 binormal)
{
    vec3 p = normalize(position - sphere.pos);
    
    texcoord = vec2( (atan(p.x, p.z) + (3.14)) / (2 * 3.14), (asin(p.y) + (3.14 / 2.0)) / (3.14) );

    ///////////////////////////////////////////////////////////
    // because for a sphere
    // x = sin(theta) * cos(phi)
    // y = cos(theta)
    // z = sin(theta) * sin(phi)
    
    // where
    // phi = u * (TWO_PI)
    // theta = v * PI

    // so
    // x = sin(v * PI) * cos(u * TWO_PI)
    // y = cos(v * PI)
    // z = sin(v * PI) * sin(u * TWO_PI)

    ///////////////////////////////////////////////////////////
    // Tangent
    // dx/du = d( sin(v * PI) * cos(u * TWO_PI) ) / du
    // dy/du = d( cos(v * PI) ) / du
    // dz/du = d( sin(v * PI) * sin(u * TWO_PI) ) / du

    // dx/du = -sin(v * PI) * sin(u * TWO_PI)
    // dy/du = 0;
    // dz/du = sin(v * PI * cos(u * TWO_PI)

    tangent.x = -sin(texcoord.y * PI) * sin(texcoord.x * TWO_PI);
    tangent.y = 0.0;
    tangent.z = sin(texcoord.y * PI) * cos(texcoord.x * TWO_PI);
    tangent = normalize(tangent);

    ///////////////////////////////////////////////////////////
    // Binormal
    // dx/dv = d( sin(v * PI) * cos(u * TWO_PI) ) / dv
    // dy/dv = d( cos(v * PI) ) / dv
    // dz/dv = d( sin(v * PI) * sin(u * TWO_PI) ) / dv

    // dx/dv = cos(u * TWO_PI) * cos(v * PI)
    // dy/dv = -sin(v * PI)
    // dz/dv = sin(u * TWO_PI) * cos(v * PI)

    binormal.x = cos(texcoord.x * TWO_PI) * cos(texcoord.y * PI);
    binormal.y = -sin(texcoord.y * PI);
    binormal.z = sin(texcoord.x * TWO_PI) * cos(texcoord.y * PI);
    binormal = normalize(binormal);
}

void convertPlanePositionToUV(in Plane plane, in vec3 position, in vec3 normal, out vec2 texcoord, out vec3 tangent, out vec3 binormal)
{
    vec3 diff = position - plane.pos;
    
    texcoord = vec2( dot(diff, plane.right) / plane.uvScale.x, dot(diff, plane.up) / plane.uvScale.y );

    ///////////////////////////////////////////////////////////
    // Tangent
    // p = N.x - d

    // tangent
    tangent = plane.right;
    binormal = plane.up;
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
            convertSpherePositionToUV(spheres[i], hitRecord.position, hitRecord.normal, 
                                        hitRecord.texcoord, hitRecord.tangent, hitRecord.binormal);

            hitRecord.mat = spheres[i].mat;
        }
	}

    for (int i = 0; i < NUM_PLANES; i++) 
    {
        float intersect_t = intersectPlane(ray, planes[i]);
        if (intersect_t != 0. && intersect_t < hitRecord.t) 
        {
            hitRecord.id = i; 
            hitRecord.t = intersect_t;
            hitRecord.position = ray.origin + ray.dir * hitRecord.t;
            hitRecord.normal = getPlaneNormal(planes[i]);
            convertPlanePositionToUV(planes[i], hitRecord.position, hitRecord.normal, 
                                        hitRecord.texcoord, hitRecord.tangent, hitRecord.binormal);

            hitRecord.mat = planes[i].mat;
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
    float u1 = rand();
    float u2 = rand();
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

vec3 getTexelFromAtlas(int textureID, int row, vec2 texcoord)
{
    vec2 offset = vec2( (textureID % 4) * 0.25, row * 0.25);

    return texture(iChannel3, offset + texcoord * 0.25).rgb;
}

vec3 getAlbedoTexture(int textureID, vec2 texcoord)
{
    return getTexelFromAtlas(textureID, 3, texcoord);
}

vec3 getEmissionTexture(int textureID, vec2 texcoord)
{
    return getTexelFromAtlas(textureID, 2, texcoord);
}

vec3 getNormalTexture(int textureID, vec2 texcoord)
{
    return getTexelFromAtlas(textureID, 0, texcoord);
}

vec3 getAlbedo(in Material mat, vec2 texcoord)
{
    if(mat.albedoTexture==-1)
        return mat.albedo;
    else
        return getAlbedoTexture(mat.albedoTexture, texcoord);
}

vec3 getEmission(in Material mat, vec2 texcoord)
{
    if(mat.emissionTexture==-1)
        return mat.emission;
    else
        return getEmissionTexture(mat.emissionTexture, texcoord) * mat.emission;
}

vec3 getNormal(in Material mat, mat3 tbn, vec2 texcoord)
{
    if(mat.normalTexture!=-1 && getNormalMapEnabled()==1)
    {
        return tbn * (2.0 * getNormalTexture(mat.normalTexture, texcoord) - 1.0);
    }
    else
    {
        return tbn[2];
    }
}

bool material_diffuse(in Material mat, in HitRecord hitRecord, inout vec3 dir, inout vec3 reflectance)
{
    // russian roulette
    vec3 albedo = getAlbedo(mat, hitRecord.texcoord);
    float p = max(albedo.x, max(albedo.y, albedo.z));
    if (rand() < p)
        albedo /= p;
    else
        return false;




    mat3 tbn =
    mat3
    (
        hitRecord.tangent,
        hitRecord.binormal,
        hitRecord.normal
    );
    vec3 normal = getNormal(mat, tbn, hitRecord.texcoord);
    vec3 nl = normal * sign( -dot(normal, dir) );       // normal from the incident side

    dir = cosWeightedSampleHemisphere(nl);
    reflectance *= albedo;

    return true;
}



bool material_specular(in Material mat, in HitRecord hitRecord, inout vec3 dir, inout vec3 reflectance)
{
    // russian roulette
    vec3 albedo = getAlbedo(mat, hitRecord.texcoord);
    float p = max(albedo.x, max(albedo.y, albedo.z));
    if (rand() < p)
        albedo /= p;
    else
        return false;



    mat3 tbn =
    mat3
    (
        hitRecord.tangent,
        hitRecord.binormal,
        hitRecord.normal
    );
    vec3 normal = getNormal(mat, tbn, hitRecord.texcoord);
    vec3 nl = normal * sign(-dot(normal, dir));         // normal from the incident side
    
    dir = reflect(dir, nl);
    reflectance *= albedo;

    return true;
}

bool material_glossy(in Material mat, in HitRecord hitRecord, inout vec3 dir, inout vec3 reflectance)
{
    // russian roulette
    vec3 albedo = getAlbedo(mat, hitRecord.texcoord);
    float p = max(albedo.x, max(albedo.y, albedo.z));
    if (rand() < p)
        albedo /= p;
    else
        return false;

    mat3 tbn =
    mat3
    (
        hitRecord.tangent,
        hitRecord.binormal,
        hitRecord.normal
    );
    vec3 normal = getNormal(mat, tbn, hitRecord.texcoord);
    vec3 nl = normal * sign(-dot(normal, dir));         // normal from the incident side
    
    vec3 dir1 = cosWeightedSampleHemisphere(nl);
    vec3 dir2 = reflect(dir, nl);
    
    float roughness = getRoughness();
    dir = normalize(roughness * dir1 + (1.0 - roughness) * dir2);

    reflectance *= albedo;

    return true;
}

bool material_transprent(in Material mat, in HitRecord hitRecord, inout vec3 dir, inout vec3 reflectance)
{
    // russian roulette
    vec3 albedo = getAlbedo(mat, hitRecord.texcoord);
    float p = max(albedo.x, max(albedo.y, albedo.z));
    if (rand() < p)
        albedo /= p;
    else
        return false;

    
    mat3 tbn =
    mat3
    (
        hitRecord.tangent,
        hitRecord.binormal,
        hitRecord.normal
    );
    vec3 normal = getNormal(mat, tbn, hitRecord.texcoord);
    vec3 nl = normal * sign(-dot(normal, dir));         // normal from the incident side

    float ior = mat.ior;

    // if normal is same as incident normal, ray travel from outside => into = 1
    float into = float(dot(normal, nl) > 0.); 
                                                        
    float ddn = dot(nl, dir);
    float nnt = mix(ior, 1. / ior, into);
    vec3 rdir = reflect(dir, normal);
    float cos2t = 1. - nnt * nnt * (1. - ddn * ddn);
    if (cos2t > 0.)
    {
        vec3 tdir = normalize(dir * nnt - nl * (ddn * nnt + sqrt(cos2t)));
        
        float R0 = (ior-1.) * (ior-1.) / ((ior+1.) * (ior+1.));
    	float c = 1. - mix(dot(tdir, normal), -ddn, into);	// 1 - cos¦È
    	float Re = R0 + (1. - R0) * c * c * c * c * c;
        
        float P = .25 + .5 * Re;
        float RP = Re / P;
        float TP = (1. - Re) / (1. - P);
        
        // Russain roulette
        if (rand() < P)
        {				
            reflectance *= RP;
            dir = rdir;  // reflect
        } 
        else
        { 				        
            reflectance *= albedo * TP; 
            dir = tdir; // refract
        }
    } 
    else
    {
        dir = rdir; // reflect
    }

    return true;
}

bool material_scatter(in Material mat, in HitRecord hitRecord, inout vec3 dir, inout vec3 reflectance)
{
    if (mat.refl == DIFF)
    {
        return material_diffuse(mat, hitRecord, dir, reflectance);
    } 
    else if (mat.refl == SPEC)
    {
        return material_specular(mat, hitRecord, dir, reflectance);
    } 
    else if (mat.refl == GLOSSY)
    {
        return material_glossy(mat, hitRecord, dir, reflectance);
    }
    else// if (mat.refl == TRANS)
    {
        return material_transprent(mat, hitRecord, dir, reflectance);
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
            Material mat = materials[hitRecord.mat];

            // add emission
            radiance += reflectance * getEmission(mat, hitRecord.texcoord);

            // move ray origin to hit point
            ray.origin = hitRecord.position;

            // material -> ray.dir, reflectance
            if(!material_scatter(mat, hitRecord, ray.dir, reflectance))
                break;

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

void mainImage( out vec4 fragColor, in vec2 fragCoord ) 
{
    rand_seek(fragCoord);

    vec3 color = vec3(0);

    for (int x = 0; x < SUB_SAMPLES; x++) 
    {
        for (int y = 0; y < SUB_SAMPLES; y++) 
        {
            float du = rand() - 0.5;
            float dv = rand() - 0.5;
            vec2 uv = (fragCoord.xy + vec2(du, dv)) / iResolution.xy;
            
            Ray camRay = generateRay(uv);
        
            color += traceWorld(camRay);
        }
    }
    
    color /= float(SUB_SAMPLES * SUB_SAMPLES);

    // blend with previous frame
    // alpha = N / (N+1) 
    // Cresult = Cn-1 * alpha + Cn * (1 - alpha)
    fragColor = vec4(outputColor(color, fragCoord), 1);
}