// Rendering Engine Demo
// Copyright Frank Force 2022
// https://frankforce.com

// This demo includes 50 objects with a directional, ambient, and point light.
// Each object also has it's own material properties.

// global settings
const int maxRaycastIterations = 100;
const int maxReflectionIterations = 50;
const int maxShadowIterations = 80;
const bool enableShadows = true;
const bool enableAmbientOcclusion = true;
const bool enableAmbientLights = true;
const bool enableDirectionalLights = true;
const bool enablePointLights = false;
const bool enableReflections = true;
const bool enableSpecular = true;
const bool enableMaterials = true;

// forward declarations for generated code
vec3 getColor(vec3 startPosition, vec3 direction);
vec2 sceneDistance(vec3 pos);

// helper functions
mat3 getRotationMatrix(vec3 direction)
{
	vec3 f = direction;
	vec3 r = normalize(cross(vec3(0,1,0), f));
	vec3 u = -cross(r,f);
    return mat3(r, u, f);
}
vec2 rotate(vec2 v, float angle)
{ 
    return v*cos(angle) + vec2(-v.y,v)*sin(angle); 
}
vec3 hash3( vec3 p )
{
	p = vec3( dot(p,vec3(127.1,311.7, 74.7)),
			  dot(p,vec3(269.5,183.3,246.1)),
			  dot(p,vec3(113.5,271.9,124.6)));
	return fract(sin(p)*3e4);
}

vec3 noise3(vec3 p)
{
    const vec2 o = vec2(1, 0);
    vec3 i = vec3(floor(p));
    vec3 f = smoothstep(0., 1., fract(p));
    return mix(
        mix
        (
            mix(hash3(i),       hash3(i+o.xyy), f.x), 
            mix(hash3(i+o.yyx), hash3(i+o.xyx), f.x), 
            f.z
        ),
        mix
        (
            mix(hash3(i+o.yxy), hash3(i+o.xxy), f.x), 
            mix(hash3(i+o.yxx), hash3(i+o.xxx), f.x),
            f.z
        ),
        f.y
    );
}

vec3 fractalNoise3(vec3 p)
{ return .52*noise3(p) + .28*noise3(p*2.) + .13*noise3(p*4.) + .07*noise3(p*8.); }
float noise(vec3 p) { return noise3(p).x; }
float fractalNoise(vec3 p) { return fractalNoise3(p).x; }

void mainImage(out vec4 fragColor, vec2 fragCoord)
{
    // input
    vec2 mouse = iMouse.xy / iResolution.xy;
    
    // camera
    float time = .2* iTime;
    float cameraDistance = 90.;
    vec3 cameraDirection = normalize(vec3(1.0,0,0));
    cameraDirection.xy = rotate(cameraDirection.xy, mouse.y > 0. ? -1.4*(1.-mouse.y) : .3*cos(.1*iTime)-.5);
    vec3 lookAtPosition = vec3( 0, mouse.x*15., 0);
    cameraDirection.xz = rotate(cameraDirection.xz, iMouse.z > 0. ? -8.*mouse.x : .1*iTime);
    vec3 cameraPosition = lookAtPosition - cameraDistance * cameraDirection;
    float cameraZoom = 3.;
    
    // render the pixel
    vec2 uv = (2. * fragCoord - iResolution.xy) / iResolution.y;
    mat3 cameraTransform = getRotationMatrix(cameraDirection);
    vec3 direction = cameraTransform * normalize(vec3(uv, cameraZoom));
    fragColor = vec4(getColor(cameraPosition, direction), 1);
}

// distance shapes
float distancePlane(vec3 p, vec3 n) { return dot(p, n); }
float distanceSphere(vec3 p, float r) { return length(p) - r; }
float distanceBox(vec3 p, vec3 s, float e)
{
    vec3 d = abs(p) - s + e;
    return min(max(d.x, max(d.y, d.z)), 0.) + length(max(d, 0.)) - e;
}
float distanceTorus(vec3 p, vec2 s)
{ return length(vec2(length(p.xz) - s.x, p.y)) - s.y; }
float distanceCylinder(vec3 p, vec2 s, float e)
{
    vec2 d = abs(vec2(length(p.xz), p.y)) - s + e;
    return min(max(d.x, d.y), 0.) + length(max(d, 0.)) - e;
}
float distanceCone(vec3 p, float a, float h)
{
    return max(cos(a)*length(p.xz) + sin(a)*(p.y-h), -h-p.y);
}
float distanceEllipsoid(vec3 p, vec3 s)
{
    float k0 = length(p / s);
    float k1 = length(p / (s * s));
    return k0 * (k0 - 1.) / k1;
}
float distanceBoxFrame(vec3 p, vec3 s, float f)
{     
    vec3 a = abs(p) - s;
    vec3 b = abs(a + f) - f;
    return min(min(
        length(max(vec3(a.x,b.y,b.z),0.)) + min(max(a.x,max(b.y,b.z)),0.),
        length(max(vec3(b.x,a.y,b.z),0.)) + min(max(b.x,max(a.y,b.z)),0.)),
        length(max(vec3(b.x,b.y,a.z),0.)) + min(max(b.x,max(b.y,a.z)),0.));
}

// combine operators
vec2 combineUnion(vec2 d1, vec2 d2)     { return d1.x  < d2.x ? d1 : d2; }
vec2 combineSubtract(vec2 d1, vec2 d2)  { return -d1.x > d2.x ? d1 : d2; }
vec2 combineIntersect(vec2 d1, vec2 d2) { return d1.x  > d2.x ? d1 : d2; }

vec2 raycast(vec3 position, vec3 direction, bool isReflection)
{
    // cast the ray
    const float range = 1e3;
    const float minRange = .1;
    const float accuracy = .001;
    float total = minRange;
    float nearestDistance = 1e9;
    vec2 nearestResult = vec2(1e4);
    for (int i = (isReflection ? maxReflectionIterations : maxRaycastIterations); accuracy < nearestDistance && --i > 0;)
    {
        vec2 distanceResult = sceneDistance(position + total * direction);
        total += distanceResult.x;
        if (distanceResult.x * nearestResult.x * nearestResult.x < nearestDistance * total * total)
        {
            // fix flickering pixel around edges
            nearestDistance = distanceResult.x;
            nearestResult = vec2(total, distanceResult.y);
        }
        if (total > range)
            return vec2(range, -1);
    }
    
    return nearestResult;
}

float getShadow(vec3 position, vec3 direction, float softness, float range)
{
    if (!enableShadows)
        return 1.;

    // cast the shadow
    const float minRange = .1;
    const float accuracy = .001;
    float distanceLast = 1e9;
    softness = max(softness, .001);
    
    float shadow = 1.;
    float total = minRange;
    for (int i = 0; accuracy < shadow && ++i < maxShadowIterations;)
    {
        // get estimated shadow distance
        float distance = sceneDistance(position + total * direction).x;
        float x = distance * distance / (2. * distanceLast);
        float y = distance * distance - x * x;
        if (y > 0. && total - x > accuracy)
            shadow = min(shadow, sqrt(y) / (total - x) / softness);

        // update distance
        distanceLast = distance;
        total += distance;
        if (total > range)
            return smoothstep(0., 1., shadow);
    }
    return 0.;
}

vec3 getNormal(vec3 position)
{
    const float accuracy = .0001;
    const vec2 e = vec2(1,-1) * accuracy;
    return normalize( 
        e.xyy*sceneDistance(position + e.xyy).x + 
        e.yyx*sceneDistance(position + e.yyx).x + 
        e.yxy*sceneDistance(position + e.yxy).x + 
        e.xxx*sceneDistance(position + e.xxx).x );
}

float getAmbientOcclusion(vec3 position, vec3 normal)
{
    if (!enableAmbientOcclusion)
        return 1.;

    // cast the ambient occusion
    const float strength = .2;
    const float scale = .2;
    const int stepCount = 5;
	float occlusion = 0.;
    for (int i = 0; ++i < stepCount;)
    {
        float d = scale * float(i);
        float distance = sceneDistance(position + d * normal).x;
        occlusion += max((d - distance) / d, 0.); 
    }
    return max(1. - occlusion * strength, 0.);
}

vec3 getAmbientLight(vec3 lightColor, vec3 position, vec3 direction, vec3 normal, vec3 diffuseColor, vec3 specularColor, float specularPower)
{
    if (!enableAmbientLights)
        return vec3(0);

    return lightColor * diffuseColor;
}

vec3 getDirectionalLight(vec3 lightDirection, vec3 lightColor, float lightSoftness, bool castShadow, vec3 position, vec3 direction, vec3 normal, vec3 diffuseColor, vec3 specularColor, float specularPower)
{
    float diffuseDot = dot(lightDirection, normal);
    if (diffuseDot < 0. || !enableDirectionalLights)
        return vec3(0);

    // apply shadow and shading
    float shadowAmount = castShadow ? getShadow(position, lightDirection, lightSoftness, 1e3) : 1.;
    vec3 diffuse = (diffuseDot * shadowAmount) * lightColor * diffuseColor;
    if (!enableSpecular || specularPower == 0.)
        return diffuse;

    // apply specular
    vec3 reflectDirection = reflect(direction, normal);
    float specularDot = pow(max(dot(lightDirection, reflectDirection), 0.), 1. + specularPower);
    vec3 specular = (specularDot * shadowAmount) * lightColor * specularColor;
    return diffuse + specular;
}


vec3 getPointLight(vec3 lightPosition, vec3 lightColor, float lightStrength, float lightSoftness, bool castShadow, vec3 position, vec3 direction, vec3 normal, vec3 diffuseColor, vec3 specularColor, float specularPower)
{
    // get direction to light
    vec3 delta = lightPosition - position;
    float distance = length(delta);
    vec3 lightDirection = delta / distance;

    // check if no shadow
    float diffuseDot = dot(lightDirection, normal);
    if (diffuseDot < 0. || !enableDirectionalLights)
        return vec3(0);

    // apply shadow and shading
    float shadowAmount = castShadow ? getShadow(position, lightDirection, lightSoftness, distance) : 0.;
    vec3 diffuse = (diffuseDot * shadowAmount) * lightColor * diffuseColor;
    float falloff = min(lightStrength * lightStrength / distance / distance, 1.);
    if (!enableSpecular || specularPower == 0.)
        return diffuse * falloff;

    // apply specular
    vec3 reflectDirection = reflect(direction, normal);
    float specularDot = pow(max(dot(lightDirection, reflectDirection), 0.), 1. + specularPower);
    vec3 specular = (specularDot * shadowAmount) * lightColor * specularColor;
    return (diffuse + specular) * falloff;
}
  
vec2 sceneDistance(vec3 pos)
{
    vec2 d = vec2(1e9);
    d = combineUnion(d, vec2(distanceCylinder(pos - vec3(0.000, -1000.000, 0.000), vec2(60.000, 1000.000), 0.500), 2.0));
    d = combineUnion(d, vec2(distanceSphere(pos - vec3(-13.540, 12.892, 19.252), 12.892), 4.0));
    d = combineUnion(d, vec2(distanceBox(pos - vec3(18.851, 8.314, 38.089), vec3(6.659, 8.314, 3.726), 0.386), 5.0));
    d = combineUnion(d, vec2(distanceBox(pos - vec3(17.882, 20.367, 41.127), vec3(4.654, 3.739, 3.632), 0.219), 6.0));
    d = combineUnion(d, vec2(distanceBox(pos - vec3(16.394, 28.057, 40.398), vec3(3.602, 3.951, 3.345), 0.089), 7.0));
    d = combineUnion(d, vec2(distanceSphere(pos - vec3(16.210, 35.142, 40.576), 3.133), 8.0));
    d = combineUnion(d, vec2(distanceCylinder(pos - vec3(-3.255, 6.169, -18.397), vec2(8.266, 6.169), 0.075), 9.0));
    d = combineUnion(d, vec2(distanceBox(pos - vec3(-2.598, 14.133, -16.809), vec3(3.482, 1.794, 3.139), 0.240), 10.0));
    d = combineUnion(d, vec2(distanceCylinder(pos - vec3(-3.073, 17.880, -15.599), vec2(2.520, 1.953), 0.429), 11.0));
    d = combineUnion(d, vec2(distanceCylinder(pos - vec3(-38.595, 13.197, 6.349), vec2(13.335, 13.197), 0.092), 12.0));
    d = combineUnion(d, vec2(distanceSphere(pos - vec3(-43.065, 36.220, 9.768), 9.826), 13.0));
    d = combineUnion(d, vec2(distanceBox(pos - vec3(-17.205, 3.289, 35.662), vec3(2.773, 3.289, 2.429), 0.406), 14.0));
    d = combineUnion(d, vec2(distanceCylinder(pos - vec3(-22.925, 2.917, -37.059), vec2(8.609, 2.917), 0.459), 15.0));
    d = combineUnion(d, vec2(distanceBox(pos - vec3(-21.462, 6.865, -36.547), vec3(2.490, 1.031, 2.106), 0.240), 16.0));
    d = combineUnion(d, vec2(distanceBox(pos - vec3(35.402, 8.886, -8.586), vec3(9.928, 8.886, 7.947), 0.331), 17.0));
    d = combineUnion(d, vec2(distanceBox(pos - vec3(40.063, 22.214, -8.062), vec3(6.625, 4.442, 4.006), 0.291), 18.0));
    d = combineUnion(d, vec2(distanceSphere(pos - vec3(42.883, 32.812, -9.959), 6.157), 19.0));
    d = combineUnion(d, vec2(distanceBox(pos - vec3(-46.209, 2.265, -11.847), vec3(4.518, 2.265, 3.010), 0.361), 20.0));
    d = combineUnion(d, vec2(distanceCylinder(pos - vec3(-47.907, 8.906, -13.685), vec2(4.793, 4.375), 0.287), 21.0));
    d = combineUnion(d, vec2(distanceCylinder(pos - vec3(-46.990, 15.833, -12.723), vec2(3.161, 2.552), 0.468), 22.0));
    d = combineUnion(d, vec2(distanceCylinder(pos - vec3(-47.374, 19.613, -11.907), vec2(2.503, 1.229), 0.473), 23.0));
    d = combineUnion(d, vec2(distanceBox(pos - vec3(19.362, 2.470, 22.410), vec3(4.434, 2.470, 3.604), 0.259), 24.0));
    d = combineUnion(d, vec2(distanceCylinder(pos - vec3(19.933, 6.815, 24.091), vec2(3.368, 1.875), 0.083), 25.0));
    d = combineUnion(d, vec2(distanceBox(pos - vec3(18.109, 4.656, -19.523), vec3(4.540, 4.656, 2.479), 0.452), 26.0));
    d = combineUnion(d, vec2(distanceCylinder(pos - vec3(17.198, 11.481, -20.542), vec2(3.046, 2.170), 0.163), 27.0));
    d = combineUnion(d, vec2(distanceBox(pos - vec3(16.676, 15.425, -20.478), vec3(1.553, 1.775, 0.944), 0.134), 28.0));
    d = combineUnion(d, vec2(distanceSphere(pos - vec3(7.089, 3.652, 11.667), 3.652), 29.0));
    d = combineUnion(d, vec2(distanceCylinder(pos - vec3(-1.834, 3.296, -33.286), vec2(6.690, 3.296), 0.310), 30.0));
    d = combineUnion(d, vec2(distanceBox(pos - vec3(-1.413, 9.996, -31.936), vec3(2.900, 3.404, 1.569), 0.038), 31.0));
    d = combineUnion(d, vec2(distanceBox(pos - vec3(-0.728, 15.338, -31.453), vec3(1.614, 1.938, 1.375), 0.366), 32.0));
    d = combineUnion(d, vec2(distanceBox(pos - vec3(23.881, 5.455, 10.980), vec3(4.257, 5.455, 2.912), 0.288), 33.0));
    d = combineUnion(d, vec2(distanceBox(pos - vec3(22.026, 12.867, 12.222), vec3(2.925, 1.957, 1.659), 0.446), 34.0));
    d = combineUnion(d, vec2(distanceCylinder(pos - vec3(23.385, 16.025, 11.778), vec2(2.990, 1.201), 0.389), 35.0));
    d = combineUnion(d, vec2(distanceBox(pos - vec3(-39.781, 2.677, -23.828), vec3(5.096, 2.677, 4.992), 0.190), 36.0));
    d = combineUnion(d, vec2(distanceCylinder(pos - vec3(-42.046, 6.750, -23.565), vec2(5.475, 1.396), 0.248), 37.0));
    d = combineUnion(d, vec2(distanceCylinder(pos - vec3(-43.120, 9.321, -22.479), vec2(3.227, 1.175), 0.117), 38.0));
    d = combineUnion(d, vec2(distanceBox(pos - vec3(19.231, 13.261, -40.233), vec3(9.857, 13.261, 9.260), 0.156), 39.0));
    d = combineUnion(d, vec2(distanceSphere(pos - vec3(16.304, 33.630, -39.547), 7.108), 40.0));
    d = combineUnion(d, vec2(distanceCylinder(pos - vec3(-26.274, 4.950, -17.369), vec2(7.764, 4.950), 0.326), 41.0));
    d = combineUnion(d, vec2(distanceBox(pos - vec3(-24.204, 13.253, -16.541), vec3(3.231, 3.352, 3.185), 0.118), 42.0));
    d = combineUnion(d, vec2(distanceBox(pos - vec3(-22.675, 19.087, -17.076), vec3(2.187, 2.481, 1.451), 0.265), 43.0));
    d = combineUnion(d, vec2(distanceBox(pos - vec3(-0.072, 3.678, 30.631), vec3(3.351, 3.678, 3.193), 0.365), 44.0));
    d = combineUnion(d, vec2(distanceBox(pos - vec3(-0.741, 8.767, 30.176), vec3(1.885, 1.411, 1.491), 0.100), 45.0));
    d = combineUnion(d, vec2(distanceBox(pos - vec3(18.215, 1.585, 5.102), vec3(1.516, 1.585, 1.157), 0.203), 46.0));
    d = combineUnion(d, vec2(distanceCylinder(pos - vec3(-12.592, 1.660, -28.562), vec2(4.769, 1.660), 0.133), 47.0));
    d = combineUnion(d, vec2(distanceBox(pos - vec3(-12.053, 4.085, -29.204), vec3(1.579, 0.765, 1.437), 0.384), 48.0));
    d = combineUnion(d, vec2(distanceCylinder(pos - vec3(31.493, 5.707, 26.149), vec2(6.424, 5.707), 0.072), 49.0));
    d = combineUnion(d, vec2(distanceSphere(pos - vec3(31.900, 15.385, 26.955), 3.972), 50.0));
    d = combineUnion(d, vec2(distanceCylinder(pos - vec3(-13.148, 4.810, 46.174), vec2(7.347, 4.810), 0.217), 51.0));
    d = combineUnion(d, vec2(distanceBox(pos - vec3(-12.103, 12.677, 43.934), vec3(4.148, 3.057, 3.720), 0.231), 52.0));
    d = combineUnion(d, vec2(distanceBox(pos - vec3(-12.010, 17.556, 43.241), vec3(2.888, 1.822, 1.682), 0.175), 53.0));
    d = combineUnion(d, vec2(distanceCylinder(pos - vec3(-11.185, 20.167, 43.793), vec2(2.198, 0.788), 0.285), 54.0));
    return d;
}

void materialInfo(float material, vec3 position, vec3 direction, out vec3 diffuse, out vec3 specular, out float specularPower, out float reflectivity, out float roughness)
{
    diffuse = specular = vec3(1);
    specularPower = reflectivity = roughness = 0.;

    if (material < 2.5) // material 2
    {
    diffuse = vec3(1.000, 1.000, 1.000);
    specular = vec3(1.000, 1.000, 1.000);
    specularPower = 1.000;
    roughness = 0.05;
    }
    else if (material < 4.5) // material 4
    {
    diffuse = vec3(0.784, 0.360, 0.336);
    specular = vec3(0.353, 0.888, 0.722);
    specularPower = 39.771;
    reflectivity = 0.681;
    }
    else if (material < 5.5) // material 5
    {
    diffuse = vec3(0.289, 0.230, 0.508);
    specular = vec3(0.883, 0.458, 0.742);
    specularPower = 45.595;
    }
    else if (material < 6.5) // material 6
    {
    diffuse = vec3(0.512, 0.241, 0.690);
    specular = vec3(0.900, 0.490, 0.617);
    specularPower = 19.602;
    roughness = 0.016;
    }
    else if (material < 7.5) // material 7
    {
    diffuse = vec3(0.353, 0.312, 0.690);
    specular = vec3(0.105, 0.928, 0.086);
    specularPower = 74.871;
    }
    else if (material < 8.5) // material 8
    {
    diffuse = vec3(0.234, 0.989, 0.190);
    specular = vec3(0.847, 0.334, 0.527);
    specularPower = 75.620;
    roughness = 0.029;
    }
    else if (material < 9.5) // material 9
    {
    diffuse = vec3(0.998, 0.926, 0.450);
    specular = vec3(0.357, 0.067, 0.678);
    specularPower = 95.442;
    reflectivity = 0.821;
    }
    else if (material < 10.5) // material 10
    {
    diffuse = vec3(0.791, 0.488, 0.286);
    specular = vec3(0.755, 0.820, 0.892);
    specularPower = 4.661;
    }
    else if (material < 11.5) // material 11
    {
    diffuse = vec3(0.434, 0.759, 0.554);
    specular = vec3(0.241, 0.091, 0.586);
    specularPower = 98.599;
    roughness = 0.002;
    }
    else if (material < 12.5) // material 12
    {
    diffuse = vec3(0.854, 0.481, 0.360);
    specular = vec3(0.140, 0.168, 0.463);
    specularPower = 98.449;
    }
    else if (material < 13.5) // material 13
    {
    diffuse = vec3(0.070, 0.661, 0.679);
    }
    else if (material < 14.5) // material 14
    {
    diffuse = vec3(0.152, 0.271, 0.929);
    specular = vec3(0.327, 0.330, 0.535);
    specularPower = 91.917;
    roughness = 0.019;
    }
    else if (material < 15.5) // material 15
    {
    diffuse = vec3(0.977, 0.586, 0.540);
    specular = vec3(0.520, 0.130, 0.246);
    specularPower = 26.322;
    reflectivity = 0.675;
    roughness = 0.015;
    }
    else if (material < 16.5) // material 16
    {
    diffuse = vec3(0.375, 0.108, 0.489);
    specular = vec3(0.510, 0.774, 0.636);
    specularPower = 7.429;
    roughness = 0.051;
    }
    else if (material < 17.5) // material 17
    {
    diffuse = vec3(0.693, 0.182, 0.022);
    specular = vec3(0.892, 0.701, 0.384);
    specularPower = 26.940;
    }
    else if (material < 18.5) // material 18
    {
    diffuse = vec3(0.718, 0.087, 0.459);
    specular = vec3(0.372, 0.466, 0.383);
    specularPower = 10.635;
    }
    else if (material < 19.5) // material 19
    {
    diffuse = vec3(0.568, 0.273, 0.838);
    specular = vec3(0.648, 0.787, 0.862);
    specularPower = 51.580;
    }
    else if (material < 20.5) // material 20
    {
    diffuse = vec3(0.251, 0.114, 0.278);
    specular = vec3(0.189, 0.706, 0.972);
    specularPower = 36.591;
    roughness = 0.028;
    }
    else if (material < 21.5) // material 21
    {
    diffuse = vec3(0.171, 0.516, 0.162);
    specular = vec3(0.043, 0.475, 0.842);
    specularPower = 33.898;
    roughness = 0.017;
    }
    else if (material < 22.5) // material 22
    {
    diffuse = vec3(0.525, 0.696, 0.018);
    specular = vec3(0.480, 0.829, 0.299);
    specularPower = 22.185;
    }
    else if (material < 23.5) // material 23
    {
    diffuse = vec3(0.583, 0.467, 0.632);
    }
    else if (material < 24.5) // material 24
    {
    diffuse = vec3(0.809, 0.354, 0.092);
    specular = vec3(0.015, 0.442, 0.470);
    specularPower = 97.282;
    reflectivity = 0.725;
    }
    else if (material < 25.5) // material 25
    {
    diffuse = vec3(0.448, 0.844, 0.164);
    specular = vec3(0.310, 0.444, 0.857);
    specularPower = 26.815;
    roughness = 0.009;
    }
    else if (material < 26.5) // material 26
    {
    diffuse = vec3(0.929, 0.742, 0.232);
    specular = vec3(0.354, 0.704, 0.438);
    specularPower = 84.774;
    roughness = 0.036;
    }
    else if (material < 27.5) // material 27
    {
    diffuse = vec3(0.076, 0.316, 0.805);
    specular = vec3(0.153, 0.397, 0.834);
    specularPower = 36.428;
    roughness = 0.085;
    }
    else if (material < 28.5) // material 28
    {
    diffuse = vec3(0.864, 0.760, 0.806);
    specular = vec3(0.188, 0.136, 0.656);
    specularPower = 4.874;
    roughness = 0.036;
    }
    else if (material < 29.5) // material 29
    {
    diffuse = vec3(0.273, 0.654, 0.008);
    roughness = 0.084;
    }
    else if (material < 30.5) // material 30
    {
    diffuse = vec3(0.909, 0.607, 0.947);
    }
    else if (material < 31.5) // material 31
    {
    diffuse = vec3(0.075, 0.956, 0.499);
    }
    else if (material < 32.5) // material 32
    {
    diffuse = vec3(0.439, 0.567, 0.563);
    specular = vec3(0.073, 0.921, 0.264);
    specularPower = 30.362;
    roughness = 0.014;
    }
    else if (material < 33.5) // material 33
    {
    diffuse = vec3(0.162, 0.754, 0.990);
    specular = vec3(0.658, 0.605, 0.129);
    specularPower = 62.460;
    roughness = 0.094;
    }
    else if (material < 34.5) // material 34
    {
    diffuse = vec3(0.379, 0.533, 0.819);
    specular = vec3(0.649, 0.213, 0.743);
    specularPower = 31.169;
    reflectivity = 0.532;
    }
    else if (material < 35.5) // material 35
    {
    diffuse = vec3(0.914, 0.138, 0.424);
    specular = vec3(0.281, 0.382, 0.448);
    specularPower = 4.027;
    roughness = 0.073;
    }
    else if (material < 36.5) // material 36
    {
    diffuse = vec3(0.268, 0.767, 0.540);
    specular = vec3(0.501, 0.834, 0.476);
    specularPower = 76.760;
    roughness = 0.072;
    }
    else if (material < 37.5) // material 37
    {
    diffuse = vec3(0.928, 0.412, 0.801);
    specular = vec3(0.393, 0.951, 0.654);
    specularPower = 80.531;
    }
    else if (material < 38.5) // material 38
    {
    diffuse = vec3(0.854, 0.438, 0.621);
    specular = vec3(0.231, 0.925, 0.649);
    specularPower = 70.086;
    }
    else if (material < 39.5) // material 39
    {
    diffuse = vec3(0.003, 0.059, 0.403);
    specular = vec3(0.564, 0.403, 0.036);
    specularPower = 43.922;
    roughness = 0.091;
    }
    else if (material < 40.5) // material 40
    {
    diffuse = vec3(0.719, 0.031, 0.394);
    specular = vec3(0.434, 0.225, 0.648);
    specularPower = 54.438;
    }
    else if (material < 41.5) // material 41
    {
    diffuse = vec3(0.918, 0.749, 0.086);
    reflectivity = 0.885;
    }
    else if (material < 42.5) // material 42
    {
    diffuse = vec3(0.446, 0.046, 0.299);
    specular = vec3(0.614, 0.660, 0.473);
    specularPower = 35.002;
    roughness = 0.028;
    }
    else if (material < 43.5) // material 43
    {
    diffuse = vec3(0.023, 0.844, 0.016);
    specular = vec3(0.934, 0.684, 0.609);
    specularPower = 80.289;
    roughness = 0.059;
    }
    else if (material < 44.5) // material 44
    {
    diffuse = vec3(0.902, 0.318, 0.891);
    specular = vec3(0.265, 0.905, 0.560);
    specularPower = 5.755;
    roughness = 0.036;
    }
    else if (material < 45.5) // material 45
    {
    diffuse = vec3(0.417, 0.817, 0.315);
    specular = vec3(0.987, 0.795, 0.493);
    specularPower = 17.932;
    roughness = 0.059;
    }
    else if (material < 46.5) // material 46
    {
    diffuse = vec3(0.075, 0.141, 0.217);
    specular = vec3(0.338, 0.645, 0.064);
    specularPower = 35.961;
    }
    else if (material < 47.5) // material 47
    {
    diffuse = vec3(0.792, 0.576, 0.395);
    specular = vec3(0.564, 0.051, 0.415);
    specularPower = 18.434;
    }
    else if (material < 48.5) // material 48
    {
    diffuse = vec3(0.212, 0.218, 0.372);
    specular = vec3(0.879, 0.226, 0.839);
    specularPower = 52.305;
    roughness = 0.014;
    }
    else if (material < 49.5) // material 49
    {
    diffuse = vec3(0.360, 0.323, 0.044);
    specular = vec3(0.311, 0.822, 0.700);
    specularPower = 26.318;
    }
    else if (material < 50.5) // material 50
    {
    diffuse = vec3(0.914, 0.962, 0.956);
    specular = vec3(0.458, 0.366, 0.248);
    specularPower = 54.191;
    roughness = 0.077;
    }
    else if (material < 51.5) // material 51
    {
    diffuse = vec3(0.826, 0.757, 0.594);
    specular = vec3(0.686, 0.451, 0.832);
    specularPower = 27.426;
    }
    else if (material < 52.5) // material 52
    {
    diffuse = vec3(0.491, 0.521, 0.667);
    }
    else if (material < 53.5) // material 53
    {
    diffuse = vec3(0.076, 0.614, 0.060);
    specular = vec3(0.050, 0.920, 0.011);
    specularPower = 89.439;
    roughness = 0.028;
    }
    else if (material < 54.5) // material 54
    {
    diffuse = vec3(0.855, 0.766, 0.029);
    specular = vec3(0.042, 0.678, 0.674);
    specularPower = 7.370;
    roughness = 0.091;
    }
}

vec3 getColor(vec3 startPosition, vec3 direction)
{
    vec3 passColor = vec3(1);
    vec3 finalColor = vec3(0);
    int maxReflects = 3;
    for (int reflectCount = 0; ++reflectCount <= maxReflects;)
    {
        // raycast to find hit info
        vec2 raycastResult = raycast(startPosition, direction, reflectCount > 1);
        float hitDistance = raycastResult.x;
        float hitMaterial = raycastResult.y;
        
        // get fog color
        const vec3 fogColor1 = vec3(1);
        const vec3 fogColor2 = vec3(0.05, 0.1, 0.175);
        const vec3 fogFadeDirection = vec3(0.000, 1.000, 0.000);
        float fog = dot(direction, fogFadeDirection);
        fog = (fog - (-0.300)) / (0.600 - (-0.300));
        vec3 fogColor = mix(fogColor2, fogColor1, fog);

        // stop if nothing was hit
        if (hitMaterial < 0.)
        {
            finalColor += fogColor * passColor;
            break;
        }
        
        // material info
        vec3 position = startPosition + hitDistance * direction;
        vec3 diffuse, specular;
        float specularPower, reflectivity, roughness;
        if (enableMaterials)
            materialInfo(hitMaterial, position, direction, diffuse, specular, specularPower, reflectivity, roughness);

        // hit normal
        vec3 normal = getNormal(position);
        normal += noise3(position * 20.) * roughness;
        normal = normalize(normal);

        // lighting
        vec3 color = vec3(0);
        color += getAmbientLight(vec3(0.003, 0.004, 0.005), position, direction, normal, diffuse, specular, specularPower);
        color += getDirectionalLight(vec3(0.408, 0.816, -0.408), vec3(0.703, 0.637, 0.597), 0.100, true, position, direction, normal, diffuse, specular, specularPower);
        color += getPointLight(vec3(0.000, 10.000, 0.000), vec3(0., 0.6, 0.1), 20.000, 0.100, true, position, direction, normal, diffuse, specular, specularPower);

        // ambient occlusion
        color *= getAmbientOcclusion(position, normal);
        
        // blend fog
        const float fogStart = 900.000;
        const float fogDistance = 100.000;
        float fogPercent = clamp((hitDistance - fogStart) / fogDistance, 0., 1.);
        color *= 1. - reflectivity;
        finalColor += passColor * mix(color, fogColor, fogPercent);
        
        // check if reflecting
        if (!enableReflections || reflectivity == 0.)
            break;
        
        // apply reflections
        startPosition = position;
        direction = reflect(direction, normal);
        passColor *= diffuse * reflectivity * (1. - fogPercent);
    }
    
    // gamma
    const float gamma = 0.4545;
    return pow(clamp(finalColor, 0., 1.), vec3(gamma));
}