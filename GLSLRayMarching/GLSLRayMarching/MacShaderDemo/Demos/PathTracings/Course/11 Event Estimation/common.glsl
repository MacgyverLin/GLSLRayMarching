//BRDF model comes from https://google.github.io/filament/Filament.html

#define DegToRad 0.01745329252
#define INFINITY 1e10
#define EPSILON 0.0001

#define PI 3.14159265359
#define INV_PI 0.31830988618
#define SQRT2_2 0.70710678118

#define DEFAULT_REFLECTANCE 0.04

/////////////////////////////////////////
//             Structures              //
/////////////////////////////////////////

struct Camera
{
    vec3 position;
    vec3 target;
    vec3 upVec;
    float fovy;
};

struct Ray
{
    vec3 origin;
    vec3 direction;
};

struct Sphere
{
    int materialID;

    vec3 center;
    float radius;
};

struct Quad
{
    int materialID;

    vec3 p;
    vec3 w;
    vec3 l;
};

struct Intersection
{
    vec3 position;
    vec3 normal;
};

struct Material
{
    int materialType;
    vec3 baseColor;
    float roughness;
    float metallic;
};

/////////////////////////////////////////
//            Ray Tracing              //
/////////////////////////////////////////

//Random functions
float seed;
float GetRandom() { return fract(sin(seed++) * 43758.5453123); }
float hash12(vec2 p)
{
    vec3 p3 = fract(vec3(p.xyx) * .1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

Ray InitRay(Camera camera, vec2 fragCoord, vec2 resolution)
{
    vec3 forward = normalize(camera.target - camera.position);
    vec3 right = normalize(cross(camera.upVec, forward));
    vec3 up = cross(forward, right);

    float randomA = GetRandom();
    float randomB = GetRandom();
    vec2 realFragCoord = fragCoord + vec2(randomA, randomB) - 0.5;
    realFragCoord = realFragCoord * 2.0 - resolution.xy;

    vec2 uv = tan(camera.fovy * DegToRad * 0.5) * (realFragCoord / resolution.yy);
    vec3 rayDir = normalize(right * uv.x + up * uv.y + forward);

    return Ray(camera.position, rayDir);
}

bool SolveQuadratic(float a, float b, float c, out float x0, out float x1)
{
    float discriminant = b * b - 4.0 * a * c;
    if (discriminant < 0.0) { return false; }

    float rootDisc = sqrt(discriminant);
    float q = (b > 0.0) ? -0.5 * (b + rootDisc) : -0.5 * (b - rootDisc);
    float temp0 = q / a;
    float temp1 = c / q;
    if (temp1 > temp0)
    {
        x0 = temp0;
        x1 = temp1;
    }
    else
    {
        x0 = temp1;
        x1 = temp0;
    }
    return true;
}

bool RayQuadIntersect(Ray ray, Quad quad, out float t, out Intersection intersection)
{
    vec3 edge1 = quad.w;
    vec3 edge2 = quad.l;
    vec3 h = cross(ray.direction, edge2);
    float a = dot(edge1, h);
    if (abs(a) < EPSILON) { return false; }

    float f = 1.0 / a;
    vec3 s = ray.origin - quad.p;
    float u = f * dot(s, h);
    //I modified this a little bit to ensure there could be an intersection near edges.
    //original:
    //if(u < 0.0 || u > 1.0) {return false;}
    if (u < -EPSILON || u > 1.0 + EPSILON) { return false; }

    vec3 q = cross(s, edge1);
    float v = f * dot(ray.direction, q);
    //origin:
    //if(v < 0.0 || v > 1.0) {return false;}
    if (v < -EPSILON || v > 1.0 + EPSILON) { return false; }

    t = f * dot(edge2, q);
    if (t < EPSILON) { return false; }

    intersection.position = ray.origin + t * ray.direction;
    intersection.normal = normalize(cross(edge1, edge2));
    return true;
}

bool RaySphereIntersect(Ray ray, Sphere sphere, out float t, out Intersection intersection)
{
    bool hasIntersection = false;

    float t0, t1;
    vec3 l = ray.origin - sphere.center;
    float a = dot(ray.direction, ray.direction);
    float b = 2.0 * dot(ray.direction, l);
    float c = dot(l, l) - sphere.radius * sphere.radius;
    if (!SolveQuadratic(a, b, c, t0, t1)) { return false; }

    if (t1 > 0.0)
    {
        t = t1;
        hasIntersection = true;
    }

    if (t0 > 0.0)
    {
        t = t0;
        hasIntersection = true;
    }

    intersection.position = ray.origin + t * ray.direction;
    intersection.normal = normalize(intersection.position - sphere.center);
    return hasIntersection;
}

bool LightRay(Quad light, Intersection intersection, int j, int k, float ratio, out Ray lightRay, out vec3 rayTarget)
{
    float randomA = GetRandom();
    float randomB = GetRandom();
    rayTarget = light.p + light.w * (float(j) + randomA) * ratio + light.l * (float(k) + randomB) * ratio;
    vec3 lightNormal = cross(light.w, light.l);
    lightRay.direction = normalize(rayTarget - intersection.position);
    lightRay.origin = intersection.position + lightRay.direction * 0.01;

    bool hasLight = (dot(lightRay.direction, lightNormal) < 0.0);
    return hasLight;
}

/////////////////////////////////////////
//              Sampling               //
/////////////////////////////////////////

vec3 SampleHemiSphere()
{
    float theta = acos(GetRandom());
    float phi = 2.0 * PI * GetRandom();
    float sinTheta = sin(theta);

    return vec3(cos(phi) * sinTheta, sin(phi) * sinTheta, cos(theta));
}

vec3 SampleHemiSphereGGX(float roughness)
{
    float randomA = GetRandom();
    float randomB = GetRandom();

    float theta = acos(sqrt((1.0 - randomA) / ((roughness * roughness - 1.0) * randomA + 1.0)));
    float phi = 2.0 * PI * randomB;
    float sinTheta = sin(theta);

    return vec3(cos(phi) * sinTheta, sin(phi) * sinTheta, cos(theta));
}

Ray GetRandomRay(vec3 lastRayDir, vec3 position, vec3 normal)
{
    Ray ray;

    vec3 s = SampleHemiSphere();
    s.z = abs(s.z);

    vec3 w = normal;
    vec3 u, v;
    if (abs(dot(normal, vec3(0.0, 1.0, 0.0))) <= SQRT2_2)
    {
        u = normalize(cross(vec3(0.0, 1.0, 0.0), w));
        v = cross(w, u);
    }
    else
    {
        v = normalize(cross(w, vec3(1.0, 0.0, 0.0)));
        u = cross(v, w);
    }
    ray.direction = s.x * u + s.y * v + s.z * w;
    ray.origin = position + ray.direction * 0.001;

    return ray;
}

Ray GetRandomRay_GGX(vec3 lastRayDir, vec3 position, vec3 normal, float roughness, float t)
{
    Ray ray;

    float randomValue = GetRandom();

    vec3 w = normal;
    vec3 s, u, v;

    if (randomValue < t)
    {
        //Sample specular, half vector.
        s = SampleHemiSphereGGX(roughness);
    }
    else
    {
        //Sample diffuse, sample vector;
        s = SampleHemiSphere();
    }

    s.z = abs(s.z);

    if (abs(dot(normal, vec3(0.0, 1.0, 0.0))) <= SQRT2_2)
    {
        u = normalize(cross(vec3(0.0, 1.0, 0.0), w));
        v = cross(w, u);
    }
    else
    {
        v = normalize(cross(w, vec3(1.0, 0.0, 0.0)));
        u = cross(v, w);
    }

    if (randomValue < t)
    {
        vec3 halfVec = s.x * u + s.y * v + s.z * w;
        ray.direction = reflect(lastRayDir, halfVec);
    }
    else
    {
        ray.direction = s.x * u + s.y * v + s.z * w;
    }

    ray.origin = position + ray.direction * 0.001;

    return ray;
}

Ray GetRandomRay_NEE(Quad light, vec3 position, vec3 normal, out float dist)
{
    float randomA = GetRandom();
    float randomB = GetRandom();
    vec3 lightTarget = light.p + light.w * randomA + light.l * randomB;

    vec3 lightOrigin = position + 0.001 * normal;
    vec3 lightDirection = normalize(lightTarget - lightOrigin);

    Ray lightRay = Ray(lightOrigin, lightDirection);
    dist = length(lightTarget - lightRay.origin);
    return lightRay;
}

/////////////////////////////////////////
//                BRDF                 //
/////////////////////////////////////////

// Bruce Walter et al. 2007. Microfacet Models for Refraction through Rough Surfaces. Proceedings of the Eurographics Symposium on Rendering.
float D_GGX(float NoH, float roughness) {
    float a = NoH * roughness;
    float k = roughness / (1.0 - NoH * NoH + a * a);
    return k * k * INV_PI;
}

// Eric Heitz. 2014. Understanding the Masking-Shadowing Function in Microfacet-Based BRDFs. Journal of Computer Graphics Techniques, 3 (2).
float V_SmithGGXCorrelated(float NoV, float NoL, float roughness) {
    float a2 = roughness * roughness;
    float GGXV = NoL * sqrt(NoV * NoV * (1.0 - a2) + a2);
    float GGXL = NoV * sqrt(NoL * NoL * (1.0 - a2) + a2);
    return 0.5 / (GGXV + GGXL);
}

// Christophe Schlick. 1994. An Inexpensive BRDF Model for Physically-Based Rendering. Computer Graphics Forum, 13 (3), 233¨C246.
float F_Schlick(float LoH, float f0, float f90) {
    return f0 + (f90 - f0) * pow(1.0 - LoH, 5.0);
}

vec3 F_Schlick(float LoH, vec3 f0, vec3 f90) {
    return f0 + (f90 - f0) * pow(1.0 - LoH, 5.0);
}

vec3 F_Schlick(float LoH, vec3 f0) {
    return f0 + (vec3(1.0) - f0) * pow(1.0 - LoH, 5.0);
}

vec3 F0(vec3 baseColor, float metallic) {
    return DEFAULT_REFLECTANCE * (1.0 - metallic) + baseColor * metallic;
}

// Specular BRDF
vec3 Fr(float NoV, float NoL, float NoH, float LoH, float roughness, vec3 f0) {
    float D = D_GGX(NoH, roughness);
    vec3 F = F_Schlick(LoH, f0);
    float V = V_SmithGGXCorrelated(NoV, NoL, roughness);
    return D * F * V;
}

float Fd_Lambert() {
    return INV_PI;
}

// Diffuse BRDF
// Brent Burley. 2012. Physically Based Shading at Disney. Physically Based Shading in Film and Game Production, ACM SIGGRAPH 2012 Courses.
float Fd_Burley(float NoV, float NoL, float LoH, float roughness) {
    float f90 = 0.5 + 2.0 * roughness * LoH * LoH;
    float lightScatter = F_Schlick(NoL, 1.0, f90);
    float viewScatter = F_Schlick(NoV, 1.0, f90);
    return lightScatter * viewScatter * INV_PI;
}

vec3 EvaluateBRDF(vec3 wi, vec3 wo, Material material, vec3 normal)
{
    vec3 h = normalize(wi + wo);
    float NdotV = abs(dot(normal, wo)) + 1e-5;
    float NdotL = max(dot(normal, wi), 0.0);
    float NdotH = max(dot(normal, h), 0.0);
    float LdotH = max(dot(wi, h), 0.0);

    float roughness = material.roughness * material.roughness;
    vec3 f0 = F0(material.baseColor, material.metallic);
    vec3 diffuse = material.baseColor * (1.0 - material.metallic);

    vec3 fr = Fr(NdotV, NdotL, NdotH, LdotH, roughness, f0);
    vec3 fd = Fd_Burley(NdotV, NdotL, LdotH, roughness) * diffuse;

    return (fr + fd) * NdotL;
}

vec3 EvaluateBRDF(vec3 wi, vec3 wo, Quad light, float dist, Material material, vec3 normal)
{
    vec3 h = normalize(wi + wo);
    float NdotV = abs(dot(normal, wo)) + 1e-5;
    float NdotL = max(dot(normal, wi), 0.0);
    float NdotH = max(dot(normal, h), 0.0);
    float LdotH = max(dot(wi, h), 0.0);

    float roughness = material.roughness * material.roughness;
    vec3 f0 = F0(material.baseColor, material.metallic);
    vec3 diffuse = material.baseColor * (1.0 - material.metallic);

    vec3 fr = Fr(NdotV, NdotL, NdotH, LdotH, roughness, f0);
    vec3 fd = Fd_Burley(NdotV, NdotL, LdotH, roughness) * diffuse;

    vec3 lightNormal = cross(light.w, light.l);
    float area = length(lightNormal);
    lightNormal = normalize(lightNormal);
    float G = dot(-wi, lightNormal) * NdotL / (dist * dist);
    G = max(G, 0.0);

    return (fr + fd) * G * area;
}

/////////////////////////////////////////
//               PDFs                  //
/////////////////////////////////////////

float PDF_Lambert(vec3 wi, vec3 normal) {
    return INV_PI * max(dot(normal, wi), 0.0);
}

float PDF_GGX(vec3 wi, vec3 wo, vec3 normal, float roughness)
{
    vec3 h = normalize(wi + wo);
    float NdotH = max(dot(normal, h), 0.0);

    return D_GGX(NdotH, roughness) * NdotH / (4.0 * max(dot(wo, h), 0.001));
}

float PDF_Quad(Quad light, Ray ray)
{
    float t;
    Intersection intersection;

    bool hasIntersect = RayQuadIntersect(ray, light, t, intersection);
    if (hasIntersect)
    {
        vec3 lightNormal = cross(light.w, light.l);
        float area = length(lightNormal);
        lightNormal = normalize(lightNormal);

        return t * t / (area * abs(dot(lightNormal, -ray.direction)));
    }
    else
    {
        return 0.0;
    }
}
