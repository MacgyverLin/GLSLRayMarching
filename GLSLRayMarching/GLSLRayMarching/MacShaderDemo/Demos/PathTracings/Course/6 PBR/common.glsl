#define BIG_FLOAT 9999999.
#define SMOL_FLOAT 0.0000001
#define PI 3.1415926
#define TAU 6.2831853

// TYPES //////////////////////////////////////////////////////////////////////////////////

struct Material
{
    vec3 BaseColor; // IsMetal ? Reflectance : Albedo
	float Metalness;
    float Roughness;
    float Emissive; // Emissive strength. Set light color with BaseColor
    bool IsCheckerHack;
};
struct Sphere
{
    vec3 Center;
    float Radius;
    Material Mat;
};
struct Ray 
{
    vec3 Origin;
    vec3 Dir;
};
struct Hit 
{
    vec3 Pos; // point in space
    vec3 Normal; // normal of hit surface
    float LengthAlongRay; // length along ray of hit
   //bool IsFrontFace; // whether we hit the outside or inside of the surface
    //int MatId;
    Material Mat;
    //bool IsMetal;
    //bool BaseColor; // IsMetal ? Reflectance : Albedo
};
    
    
float length2(vec2 v) { return dot(v,v); }
float length2(vec3 v) { return dot(v,v); }
    

// RANDOM /////////////////////////////////////////////////////////////////////////////////


// --------------------------------------
// oldschool rand() from Visual Studio - https://www.shadertoy.com/view/WsXBzl
// --------------------------------------
int  seed = 1;
void srand(int s ) { seed = s; }
int  rand(void) { seed = seed*0x343fd+0x269ec3; return (seed>>16)&32767; }
float randff() { return float(rand())/32767.0; }
/* usage
    ivec2 q = ivec2(fragCoord);
    srand( hash(q.x+hash(q.y+hash(iFrame))));
*/


// 1 out, 1 in... https://www.shadertoy.com/view/4djSRW
float hash11(float seed)
{
    seed = fract(seed * .1031);
    seed *= seed + 33.33;
    seed *= seed + seed;
    return fract(seed);
}
//  1 out, 2 in...  https://www.shadertoy.com/view/4djSRW
float hash12(vec2 seed)
{
	vec3 p3  = fract(vec3(seed.xyx) * .1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}
// 2 out, 1 in... https://www.shadertoy.com/view/4djSRW
vec2 hash21(float seed)
{
	vec3 p3 = fract(vec3(seed) * vec3(.1031, .1030, .0973));
	p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.xx+p3.yz)*p3.zy);
}
//  2 out, 2 in...
vec2 hash22(vec2 p)
{
	vec3 p3 = fract(vec3(p.xyx) * vec3(.1031, .1030, .0973));
    p3 += dot(p3, p3.yzx+33.33);
    return fract((p3.xx+p3.yz)*p3.zy);
}
//  3 out, 1 in...
vec3 hash31(float p)
{
   vec3 p3 = fract(vec3(p) * vec3(.1031, .1030, .0973));
   p3 += dot(p3, p3.yzx+33.33);
   return fract((p3.xxy+p3.yzz)*p3.zyx); 
}

vec3 RandomUnitVector(float seed) 
{
    vec2 rand = hash21(seed);
    float a = rand.x*TAU;     //  0 to TAU
    float z = rand.y*2. - 1.; // -1 to 1
    float r = sqrt(1. - z*z);
    return vec3(r*cos(a), r*sin(a), z);
}

vec3 RandomInUnitSphere(float seed)
{
    vec3 hash = hash31(seed);
    
    float theta = hash.x * TAU;
    float v = hash.y;
    float r = pow(hash.z, 0.333333);
    
    float phi = acos((2.*v)-1.);
    float sinphi = sin(phi);
    
    vec3 p;
    p.x = r * sinphi * cos(theta);
    p.y = r * sinphi * sin(theta);
    p.z = r * cos(phi); 
    
    return p;
}

vec3 RandomInHemisphere(float seed, vec3 normal) 
{
    vec3 p = RandomInUnitSphere(seed);
    return (dot(p, normal) > 0.0) ? p : -p;
}

vec2 RandomInUnitCircle(float seed)
{
    // https://programming.guide/random-point-within-circle.html
    vec2 rand = hash21(seed);
    float angle = rand.x*TAU;
    float radius = sqrt(rand.y);
    return radius * vec2(cos(angle), sin(angle));
}





// PBR /////////////////////////////////////////////////////////////////////////////////////

vec3 Fresnel_Schlick(float cosTheta, vec3 F0)
{
	cosTheta = min(cosTheta,1.); // fixes issue where cosTheta is slightly > 1.0. a floating point issue that causes black pixels where the half and view dirs align
	return F0 + (1.0 - F0) * pow(1.0 - cosTheta, 5.0);
}

/*vec3 FresnelSchlickRoughness(float cosTheta, vec3 F0, float roughness)
{
	cosTheta = min(cosTheta,1.); // fixes issue where cosTheta is slightly > 1.0. a floating point issue that causes black pixels where the half and view dirs align
	vec3 factor = max(vec3(1.0 - roughness), F0); // make rough surfaces reflect less strongly on glancing angles
	return F0 + (factor - F0) * pow(1.0 - cosTheta, 5.0);
}*/
float Distribution_GGX(float NdotH, float roughness)
{
	float a = roughness*roughness; // disney found rough^2 had more realistic results
	float a2 = a*a;
	float NdotH2 = NdotH*NdotH;
	float numerator = a2;
	float denominator = NdotH2 * (a2-1.0) + 1.0;
	denominator = PI * denominator * denominator;
	return numerator / max(denominator, SMOL_FLOAT);
    
}
float GeometrySchlick_GGX_Direct(float NdotV, float roughness)
{
	float r = roughness + 1.0; 
	float k = (r*r) / 8.; // k computed for direct lighting. we use a diff constant for IBL
	return NdotV / (NdotV * (1.0-k) + k); // bug: div0 if NdotV=0 and k=0?
}
float Geometry_Smith(float NdotV, float NdotL, float roughness)
{
	float ggx2 = GeometrySchlick_GGX_Direct(NdotV,roughness);
	float ggx1 = GeometrySchlick_GGX_Direct(NdotL,roughness);
	return ggx1*ggx2;
}





