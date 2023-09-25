#define INFINITY 9999999.0
#define PI 					3.1415926
#define TWO_PI 				6.2831852
#define FOUR_PI 			12.566370
#define INV_PI 				0.3183099
#define INV_TWO_PI 			0.1591549
#define INV_FOUR_PI 		0.0795775
#define EPSILON 0.0000001

vec3 finalPixel = vec3(0.);

void WriteFinalPixel(vec3 c)
{
	finalPixel = c;
}


////////////////////////////////////////////////
// Math
bool sameHemisphere(in vec3 n, in vec3 a, in vec3 b) {
	return ((dot(n, a) * dot(n, b)) > 0.0);
}

bool sameHemisphere(in vec3 a, in vec3 b) {
	return (a.z * b.z > 0.0);
}

bool is_inf(float val)
{
	return val != val;
	//return isinf(val);	//webGL 2.0 is required
}

float cosTheta(vec3 w) { return w.z; }
float cosTheta2(vec3 w) { return cosTheta(w) * cosTheta(w); }
float absCosTheta(vec3 w) { return abs(w.z); }
float sinTheta2(vec3 w) { return max(0.0, 1.0 - cosTheta2(w)); }
float sinTheta(vec3 w) { return sqrt(sinTheta2(w)); }
float tanTheta2(vec3 w) { return sinTheta2(w) / cosTheta2(w); }
float tanTheta(vec3 w) { return sinTheta(w) / cosTheta(w); }

float cosPhi(vec3 w) { float sin_Theta = sinTheta(w); return (sin_Theta == 0.0) ? 1.0 : clamp(w.x / sin_Theta, -1.0, 1.0); }
float sinPhi(vec3 w) { float sin_Theta = sinTheta(w); return (sin_Theta == 0.0) ? 0.0 : clamp(w.y / sin_Theta, -1.0, 1.0); }
float cosPhi2(vec3 w) { return cosPhi(w) * cosPhi(w); }
float sinPhi2(vec3 w) { return sinPhi(w) * sinPhi(w); }

mat3 mat3Inverse(in mat3 m)
{
	return mat3(vec3(m[0][0], m[1][0], m[2][0]),
		vec3(m[0][1], m[1][1], m[2][1]),
		vec3(m[0][2], m[1][2], m[2][2]));
}

mat3 ConstructMatrixForNormal(vec3 normal)
{
	mat3 ret;
	ret[1] = normal;
	if (normal.z < -0.999805696) {
		ret[0] = vec3(0.0, -1.0, 0.0);
		ret[2] = vec3(-1.0, 0.0, 0.0);
	}
	else {
		float a = 1.0 / (1.0 + normal.z);
		float b = -normal.x * normal.y * a;
		ret[0] = vec3(1.0 - normal.x * normal.x * a, b, -normal.x);
		ret[2] = vec3(b, 1.0 - normal.y * normal.y * a, -normal.y);
	}
	return ret;
}

mat4 RotateY(float a)
{
	mat4 ret = mat4(1.0);
	ret[0][0] = ret[2][2] = cos(a);
	ret[0][2] = sin(a);
	ret[2][0] = -ret[0][2];
	return ret;
}

mat4 GetTransform(vec3 r, vec3 p)
{
	mat4 ret = mat4(1.0);

	float cx = cos(r.x);
	float sx = sin(r.x);
	float cy = cos(r.y);
	float sy = sin(r.y);
	float cz = cos(r.z);
	float sz = sin(r.z);

	float a = cy * cz;
	float d = cy * sz;
	float g = -sy;

	float b = sx * sy * cz - cx * sz;
	float e = sx * sy * sz + cx * cz;
	float h = sx * cy;

	float c = cx * sy * cz + sx * sz;
	float f = cx * sy * sz - sx * cz;
	float i = cx * cy;

	//ret[0][0] =   a; ret[0][1] =   b; ret[0][2] =   c; ret[0][3] = p.x;
	//ret[1][0] =   d; ret[1][1] =   e; ret[1][2] =   f; ret[1][3] = p.y;
	//ret[2][0] =   g; ret[2][1] =   h; ret[2][2] =   i; ret[2][3] = p.z;
	//ret[3][0] = 0.0; ret[3][1] = 0.0; ret[3][2] = 0.0; ret[3][3] = 1.0;

	ret[0][0] = a; ret[0][1] = b; ret[0][2] = c; ret[0][3] = 0.0;
	ret[1][0] = d; ret[1][1] = e; ret[1][2] = f; ret[1][3] = 0.0;
	ret[2][0] = g; ret[2][1] = h; ret[2][2] = i; ret[2][3] = 0.0;
	ret[3][0] = p.x; ret[3][1] = p.y; ret[3][2] = p.z; ret[3][3] = 1.0;

	return ret;
}

vec2 Cartesian2SphericalCoordinates(vec3 p)
{
	float r = sqrt(length(p));
	float a = sqrt(length(p.xy));

	float theta = acos(p.z / r) / PI;
	float phi = (asin(p.y / a) / PI) + 0.5;

	return vec2(theta, phi);
}

////////////////////////////////////////////////
// Random
int seed;
int flat_idx;

void InitRandom(float iTime)
{
	seed = int(iTime * 100000.0);
	flat_idx = int(dot(gl_FragCoord.xy, vec2(1, 4096)));
}

void EncryptTea(inout uvec2 arg)
{
	uvec4 key = uvec4(0xa341316c, 0xc8013ea4, 0xad90777d, 0x7e95761e);
	uint v0 = arg[0], v1 = arg[1];
	uint sum = 0u;
	uint delta = 0x9e3779b9u;

	for (int i = 0; i < 32; i++) {
		sum += delta;
		v0 += ((v1 << 4) + key[0]) ^ (v1 + sum) ^ ((v1 >> 5) + key[1]);
		v1 += ((v0 << 4) + key[2]) ^ (v0 + sum) ^ ((v0 >> 5) + key[3]);
	}
	arg[0] = v0;
	arg[1] = v1;
}

vec2 Random()
{
	uvec2 arg = uvec2(flat_idx, seed++);
	EncryptTea(arg);
	return fract(vec2(arg) / vec2(0xffffffffu));
}

vec2 SampleDisk(vec2 uv)
{
	float theta = 2.0 * 3.141592653589 * uv.x;
	float r = sqrt(uv.y);
	return vec2(cos(theta), sin(theta)) * r;
}

vec3 SampleCosHemisphere(vec2 uv)
{
	vec2 disk = SampleDisk(uv);
	return vec3(disk.x, sqrt(max(0.0, 1.0 - dot(disk, disk))), disk.y);
}

////////////////////////////////////////////////
// Ray
struct Ray
{
	vec3 origin;
	vec3 dir;
};

Ray GenRay(vec2 fragCoord, vec3 cam_center, vec2 resolution)
{
	vec2 p = fragCoord.xy / resolution - vec2(0.5);
	float a = float(resolution.x) / float(resolution.y);
	if (a < 1.0)
		p.y /= a;
	else
		p.x *= a;

	Ray ray;
	ray.origin = cam_center;
	vec2 r = Random();
	vec3 ray_dir = normalize(vec3(p + r.x * dFdx(p) + r.y * dFdy(p), -1));
	ray.dir = ray_dir;

	return ray;
}

vec3 RayAt(in Ray ray, float t)
{
	return ray.origin + t * ray.dir;
}

Ray TransformRay(Ray ray, mat4 transform)
{
	Ray result;

	result.origin = vec3(transform * vec4(ray.origin, 1.0));
	result.dir = vec3(transform * vec4(ray.dir, 0));

	return result;
}

////////////////////////////////////////////////
// HitRecord
struct HitRecord
{
	bool hit;
	float t_min;
	vec3 position;
	vec3 normal;
	int material;
	vec2 uv;
};


////////////////////////////////////////////////
// Material
struct Material
{
	vec3 albedo;
	float metallic;
	float roughness;
	float ior;
	vec3 emmissive;
};

bool isMaterialTransparent(Material material)
{
	return material.ior >= 0.0;
}

bool isEmmissive(Material material)
{
	return any(greaterThan(material.emmissive, vec3(0.0)));
}

vec3 GetAlbedo(Material mat)
{
	return mat.albedo;
}

float GetMetallic(Material mat)
{
	return mat.metallic;
}

float GetRoughness(Material mat)
{
	return mat.roughness;
}

vec3 GetEmmissive(Material mat)
{
	return mat.emmissive;
}

float NDFBeckmannAniso(float ax, float ay, float NoH, vec3 H, vec3 X, vec3 Y)
{
	float XoH = dot(X, H);
	float YoH = dot(Y, H);
	float d = -(XoH * XoH / (ax * ax) + YoH * YoH / (ay * ay)) / NoH * NoH;
	return exp(d) / (PI * ax * ay * NoH * NoH * NoH * NoH);
}

float NDFGGXAniso(float ax, float ay, float NoH, vec3 H, vec3 X, vec3 Y)
{
	float XoH = dot(X, H);
	float YoH = dot(Y, H);
	float d = XoH * XoH / (ax * ax) + YoH * YoH / (ay * ay) + NoH * NoH;
	return 1 / (PI * ax * ay * d * d);
}

float GSFImplicitGeometric(float NdotL, float NdotV)
{
	float Gs = (NdotL * NdotV);
	return Gs;
}

float GSFAshikhminShirley(float NdotL, float NdotV, float LdotH)
{
	float Gs = NdotL * NdotV / (LdotH * max(NdotL, NdotV));

	return  (Gs);
}

float GSFAshikhminPremoze(float NdotL, float NdotV)
{
	float Gs = NdotL * NdotV / (NdotL + NdotV - NdotL * NdotV);
	return  (Gs);
}

float GSFDuer(vec3 lightDirection, vec3 viewDirection, vec3 normalDirection, float NdotL, float NdotV)
{
	vec3 LpV = lightDirection + viewDirection;
	float Gs = dot(LpV, LpV) * pow(dot(LpV, normalDirection), -4.0);
	return  (Gs);
}

float GSFNeumann(float NdotL, float NdotV)
{
	float Gs = (NdotL * NdotV) / max(NdotL, NdotV);
	return  (Gs);
}

float GSFKelemen(float NdotL, float NdotV, float LdotV, float VdotH)
{
	float Gs = (NdotL * NdotV) / (VdotH * VdotH);
	return   (Gs);
}

float GSFWard(float NdotL, float NdotV, float VdotH, float NdotH)
{
	float Gs = pow(NdotL * NdotV, 0.5);
	return  (Gs);
}

float GSFKurt(float NdotL, float NdotV, float VdotH, float roughness)
{
	float Gs = NdotL * NdotV / (VdotH * pow(NdotL * NdotV, roughness));
	return  (Gs);
}

float GSFCookTorrence(float NdotL, float NdotV, float VdotH, float NdotH)
{
	float Gs = min(1.0, min(2.0 * NdotH * NdotV / VdotH, 2.0 * NdotH * NdotL / VdotH));
	return  (Gs);
}

float GSFSchlick(float NdotL, float NdotV, float roughness)
{
	float roughnessSqr = roughness * roughness;

	float SmithL = (NdotL) / (NdotL * (1.0 - roughnessSqr) + roughnessSqr);
	float SmithV = (NdotV) / (NdotV * (1.0 - roughnessSqr) + roughnessSqr);

	return (SmithL * SmithV);
}

float GSFGGX(float NdotL, float NdotV, float roughness)
{
	float roughnessSqr = roughness * roughness;
	float NdotLSqr = NdotL * NdotL;
	float NdotVSqr = NdotV * NdotV;

	float SmithL = (2.0 * NdotL) / (NdotL + sqrt(roughnessSqr + (1.0 - roughnessSqr) * NdotLSqr));
	float SmithV = (2.0 * NdotV) / (NdotV + sqrt(roughnessSqr + (1.0 - roughnessSqr) * NdotVSqr));

	float Gs = (SmithL * SmithV);
	return Gs;
}

float GSFSchlickGGX(float NdotL, float NdotV, float roughness)
{
	float k = roughness / 2.0;

	float SmithL = (NdotL) / (NdotL * (1.0 - k) + k);
	float SmithV = (NdotV) / (NdotV * (1.0 - k) + k);

	float Gs = (SmithL * SmithV);
	return Gs;
}

// PBR /////////////////////////////////////////////////////////////////////////////////////
vec3 FresnelSchlick(float HdotV, vec3 F0)
{
	HdotV = min(HdotV, 1.); // fixes issue where cosTheta is slightly > 1.0. a floating point issue that causes black pixels where the half and view dirs align
	return F0 + (1.0 - F0) * pow(1.0 - HdotV, 5.0);
}


float NDFGGX(float NdotH, float roughness)
{
	float a = roughness; // disney found rough^2 had more realistic results
	float a2 = a * a;
	float NdotH2 = NdotH * NdotH;
	float numerator = a2;
	float denominator = NdotH2 * (a2 - 1.0) + 1.0;
	denominator = PI * denominator * denominator;
	return numerator / max(denominator, EPSILON);
}

float GSFSchlickGGX(float NdotV, float roughness)
{
	float r = roughness + 1.0;
	float k = (r * r) / 8.; // k computed for direct lighting. we use a diff constant for IBL
	return NdotV / (NdotV * (1.0 - k) + k); // bug: div0 if NdotV=0 and k=0?
}

float GSFSmith(float NdotV, float NdotL, float roughness)
{
	float ggx1 = GSFSchlickGGX(NdotV, roughness);
	float ggx2 = GSFSchlickGGX(NdotL, roughness);

	return ggx1 * ggx2;
}

vec3 SampleBRDF(vec3 X, vec3 V, vec3 N, vec3 L, vec3 H, vec3 albedo, float metallic, float roughness)
{
	float NdotH = max(dot(N, H), 0.0);
	float NdotV = max(dot(N, V), 0.0);
	float NdotL = max(dot(N, L), 0.0);
	float HdotV = max(dot(H, V), 0.0);

	vec3 F;
	vec3 F0 = vec3(0.04); // Good average 'Fresnel at 0 degrees' value for common dielectrics
	F0 = mix(F0, albedo, vec3(metallic));
	F = FresnelSchlick(HdotV, F0);

	// Specular
	float NDF = NDFGGX(NdotH, roughness);
	float G = GSFSmith(NdotV, NdotL, roughness);
	float denominator = 4.0 * NdotV * NdotL;
	vec3 specular = NDF * G * F / max(denominator, 0.0000001); // safe guard div0

	// Diffuse
	vec3 kS = F;                        // Specular contribution
	vec3 kD = vec3(1.0) - F;           	// Diffuse contribution - Note: 1-kS ensures energy conservation
	kD *= 1.0 - metallic;     		    // Remove diffuse contribution for metals
	vec3 diffuse = kD * albedo / PI;

	return diffuse + specular;
}

vec4 SampleBRDFDirPDF(vec2 rng, float roughness)
{
	float a = roughness; // disney found rough^2 had more realistic results
	float a2 = a * a;

	float phi = 2.0 * PI * rng.x;
	float costheta = sqrt((1.0 - rng.y) / (1.0 + (a2 - 1.0) * rng.y));
	float sintheta = sqrt(1.0 - costheta * costheta);

	vec3 H;
	H.x = sintheta * cos(phi);
	H.y = sintheta * sin(phi);
	H.z = costheta;

	float d = (costheta * a2 - costheta) * costheta + 1.0;
	float D = a2 / (PI * d * d);
	float pdf = D * costheta;

	return vec4(H, pdf);
}

void SamplePBRMaterial(Material[19] materials, Ray ray, HitRecord hitRecord, out vec3 brdf, out float brdfPDF, out Ray nextRay)
{
	Material mat = materials[hitRecord.material];
	mat3 onb = ConstructMatrixForNormal(hitRecord.normal);

	vec3 albedo = GetAlbedo(mat);
	float metallic = GetMetallic(mat);
	float roughness = GetRoughness(mat);
	vec3 emmissive = GetEmmissive(mat);

	vec3 X = hitRecord.position;                             // x  - The location in space
	vec3 V = normalize(ray.origin - X); 			    	 // wo - Direction of the outgoing light
	vec3 N = hitRecord.normal;					             // n   - The surface normal at x
	vec3 L;
	vec3 H;

	//vec4 dirPDF = SampleBRDFDirPDF(Random(), roughness);
	//vec3 L = vec3(dirPDF.xyz);
	//vec3 H = normalize(V + L);
	if (Random().x < metallic)
	{
		L = reflect(-V, N);
		H = normalize(V + L);
	}
	else
	{
		L = normalize(onb * SampleCosHemisphere(Random())); // wi - Degative direction of the incoming light
		H = normalize(V + L);                               // half vec
	}
	//brdfPDF = dirPDF.w;    
	brdfPDF = 1.0 / PI;

	nextRay = Ray(hitRecord.position, L);
	nextRay.origin += nextRay.dir * 1e-5;


	brdf = SampleBRDF(X, V, N, L, H, albedo, metallic, roughness);
}

void SamplePBRMaterial1(Material[19] materials, Ray ray, HitRecord hitRecord, out vec3 brdf, out float brdfPDF, out Ray nextRay)
{
	Material mat = materials[hitRecord.material];
	mat3 onb = ConstructMatrixForNormal(hitRecord.normal);

	vec3 albedo = GetAlbedo(mat);
	float metallic = GetMetallic(mat);
	float roughness = GetRoughness(mat);
	vec3 emmissive = GetEmmissive(mat);

	vec3 X = hitRecord.position;                             // x  - The location in space
	vec3 V = normalize(ray.origin - X); 			    	 // wo - Direction of the outgoing light
	vec3 N = hitRecord.normal;					             // n   - The surface normal at x
	vec3 L;
	vec3 H;

	vec4 dirPDF = SampleBRDFDirPDF(Random(), roughness);
	H = vec3(dirPDF.xyz);
	L = normalize(H - V);
	brdfPDF = dirPDF.w;

	nextRay = Ray(hitRecord.position, L);
	nextRay.origin += nextRay.dir * 1e-5;

	brdf = SampleBRDF(X, V, N, L, H, albedo, metallic, roughness);
}


/*
void SamplePBRMaterial(Material[19] materials, Ray ray, HitRecord hitRecord, out vec3 brdf, out float brdfPDF, out Ray nextRay)
{
	Material mat = materials[hitRecord.material];
	mat3 onb = ConstructMatrixForNormal(hitRecord.normal);

	vec3 albedo = GetAlbedo(mat);
	float metallic = GetMetallic(mat);
	float roughness = GetRoughness(mat);
	vec3 emmissive = GetEmmissive(mat);

	vec3 X = hitRecord.position;  	                         // x  - The location in space
	vec3 O = normalize(ray.origin - X); 			    	 // wo - Direction of the outgoing light
	vec3 I = normalize(onb * SampleCosHemisphere(Random())); // wi - Degative direction of the incoming light
	vec3 N = hitRecord.normal;					             // n   - The surface normal at x

	float NdotI = max(dot(N, I), 0.0);

	vec3 H = normalize(O + I); // half vec
	float NdotH = max(dot(N, H), 0.0);
	float NdotO = max(dot(N, O), 0.0);
	float HdotO = max(dot(H, O), 0.0);

	// Fresnel term
	vec3 F0 = vec3(0.04); // Good average 'Fresnel at 0 degrees' value for common dielectrics
	F0 = mix(F0, albedo, vec3(metallic));
	vec3 F = Fresnel_Schlick(HdotO, F0);

	// BRDF - Cook-Torrance
	float NDF = Distribution_GGX(NdotH, roughness);
	float G = Geometry_Smith(NdotO, NdotI, roughness);
	float denominator = 4.0 * NdotO * NdotI;
	vec3 specular = NDF * G * F / max(denominator, 0.0000001); // safe guard div0

	// Diffuse vs Specular contribution
	//vec3 kS = F;                      // Specular contribution
	vec3 kD = vec3(1.0) - F;           	// Diffuse contribution - Note: 1-kS ensures energy conservation
	kD *= 1.0 - metallic;     		    // Remove diffuse contribution for metals

	vec3 diffuse = kD * albedo / PI;

	//#if DIFFUSE == 0
	//diffuse = vec3(0);
	//#endif

	//#if SPECULAR == 0
	//specular = vec3(0);
	//#endif

	nextRay = Ray(hitRecord.position, I);
	nextRay.origin += nextRay.dir * 1e-5;

	brdfPDF = 1.0 / PI;
	brdf = diffuse + specular;
}
*/

////////////////////////////////////////////////
// Sphere
struct Sphere
{
	vec3 position;
	float radius;
	int material;
};

bool IntersectSphere(Sphere sphere, Ray ray, inout HitRecord hitRecord)
{
	vec3 oc = ray.origin - sphere.position;
	float b = dot(oc, ray.dir);
	float c = dot(oc, oc) - sphere.radius * sphere.radius;

	float disc = b * b - c;
	if (disc >= 0.0)
	{
		float t = -b - sqrt(disc);

		if (t >= 0.0 && t < hitRecord.t_min)
		{
			vec3 p = RayAt(ray, t);

			hitRecord.hit = true;
			hitRecord.t_min = t;
			hitRecord.position = p;
			hitRecord.normal = normalize(p - sphere.position);
			hitRecord.material = sphere.material;

			hitRecord.uv = Cartesian2SphericalCoordinates(p - sphere.position);

			return true;
		}
		else
		{
			return false;
		}
	}
	else
	{
		return false;
	}
}

////////////////////////////////////////////////
// AABB
struct AABB
{
	vec3 min_;
	vec3 max_;
};

bool IntersectAABB(in Ray ray, in AABB aabb, inout float t_min, inout float t_max)
{
	vec3 div = 1.0 / ray.dir;
	vec3 t_1 = (aabb.min_ - ray.origin) * div;
	vec3 t_2 = (aabb.max_ - ray.origin) * div;

	vec3 t_min2 = min(t_1, t_2);
	vec3 t_max2 = max(t_1, t_2);

	t_min = max(max(t_min2.x, t_min2.y), max(t_min2.z, t_min));
	t_max = min(min(t_max2.x, t_max2.y), min(t_max2.z, t_max));

	return t_min < t_max;
}

////////////////////////////////////////////////
// Box
struct Box
{
	vec3 position;
	vec3 rotation;
	vec3 size;
	int material;
};

bool IntersectBox(Box box, Ray ray, inout HitRecord hitRecord)
{
	float t_min = 0.0;
	float t_max = 999999999.0;

	mat4 transform = GetTransform(box.rotation, box.position);
	mat4 invTransform = inverse(transform);

	Ray localRay = TransformRay(ray, invTransform);
	if (IntersectAABB(localRay, AABB(-box.size, box.size), t_min, t_max))
	{
		vec3 localHitPoint = RayAt(localRay, t_min);
		vec3 localNormal = vec3(0.);
		vec2 uv;

		vec3 p = localHitPoint / box.size;
		if (abs(p.x) > abs(p.y))
		{
			if (abs(p.x) > abs(p.z))
			{
				// x major
				localNormal.x = p.x > 0.0 ? 1.0 : -1.0;

				uv = p.yz;
			}
			else
			{
				// z major
				localNormal.z = p.z > 0.0 ? 1.0 : -1.0;

				uv = p.xy;
			}
		}
		else if (abs(p.y) > abs(p.z))
		{
			// y major
			localNormal.y = p.y > 0.0 ? 1.0 : -1.0;

			uv = p.xz;
		}
		else
		{
			// z major
			localNormal.z = p.z > 0.0 ? 1.0 : -1.0;

			uv = p.xy;
		}

		if (t_min < hitRecord.t_min)
		{
			hitRecord.hit = true;
			hitRecord.t_min = t_min;
			hitRecord.position = vec3(transform * vec4(localHitPoint, 1.0));
			hitRecord.normal = normalize(vec3(transform * vec4(localNormal, 0.0)));
			hitRecord.material = box.material;
			hitRecord.uv = uv;

			return true;
		}
		else
		{
			return false;
		}
	}
	else
	{
		return false;
	}
}


////////////////////////////////////////////////
// Plane
struct Plane
{
	vec3 position;
	vec3 rotation;
	vec2 size;
	int material;
};


bool IntersectPlane(Plane plane, Ray ray, inout HitRecord hitRecord)
{
	mat4 transform = GetTransform(plane.rotation, plane.position);
	mat4 invTransform = inverse(transform);

	Ray localRay = TransformRay(ray, invTransform);

	float denom = localRay.dir.z;
	float t = -localRay.origin.z / denom;

	if (t > 0.0 && t < hitRecord.t_min)
	{
		vec3 p = RayAt(localRay, t);

		bool hit = all(lessThan(abs(p.xy), plane.size));
		if (hit)
		{
			hitRecord.hit = true;
			hitRecord.t_min = t;
			hitRecord.position = vec3(transform * vec4(p, 1.0));
			hitRecord.normal = normalize(vec3(transform * vec4(0.0, 0.0, 1.0, 0.0)));
			hitRecord.material = plane.material;
			hitRecord.uv = p.xy / plane.size;

			return true;
		}
		else
		{
			return false;
		}
	}
	else
	{
		return false;
	}
}

vec3 PlaneGetNormal(Plane plane)
{
	mat4 transform = GetTransform(plane.rotation, plane.position);

	return normalize(vec3(transform * vec4(0.0, 0.0, 1.0, 0.0)));
}

vec3 PlaneGetPoint(Plane plane)
{
	mat4 transform = GetTransform(plane.rotation, plane.position);

	vec2 rng = (Random() - vec2(0.5)) * plane.size;

	return vec3(transform * vec4(rng.x, rng.y, 0.0, 1.0));
}