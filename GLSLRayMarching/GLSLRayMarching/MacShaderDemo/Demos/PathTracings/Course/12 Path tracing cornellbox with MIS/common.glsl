#define INFINITY 9999999.0
#define PI 3.141592653589

////////////////////////////////////////////////
// Math
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

////////////////////////////////////////////////
// Random
int seed;
int flat_idx;

void InitRandom()
{
	seed = 0;
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

vec3 SampleCosHemisphere()
{
	vec2 uv = Random();

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

////////////////////////////////////////////////
// Sphere
struct Sphere
{
	vec3 position;
	float radius;
	int material;
};

vec2 Cartesian2SphericalCoordinates(vec3 p)
{
	float r = sqrt(length(p));
	float a = sqrt(length(p.xy));

	float theta = acos(p.z / r) / PI;
	float phi = (asin(p.y / a) / PI) + 0.5;

	return vec2(theta, phi);
}

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

bool IsInside(vec3 p, vec3 position, vec3 normal, vec2 size)
{
	bool hit = false;

	//int which;
	if (abs(normal.x) > abs(normal.y))
	{
		if (abs(normal.x) > abs(normal.z))
		{
			hit = all(lessThanEqual(abs(p.yz - position.yz), size));
		}
		else
		{
			hit = all(lessThan(abs(p.xy - position.xy), size));
		}
	}
	else
	{
		if (abs(normal.y) > abs(normal.z))
		{
			hit = all(lessThan(abs(p.xz - position.xz), size));
		}
		else
		{
			hit = all(lessThan(abs(p.xy - position.xy), size));
		}
	}

	return hit;
}


float IntersectPlane(Plane plane, Ray ray, inout HitRecord hitRecord)
{
	mat4 transform = GetTransform(plane.rotation, plane.position);
	mat4 invTransform = inverse(transform);

	Ray localRay = TransformRay(ray, invTransform);

	float denom = localRay.dir.z;
	float t = -localRay.origin.z  / denom;

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

			return t;
		}
		else
		{
			return INFINITY;
		}
	}
	else
	{
		return INFINITY;
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

////////////////////////////////////////////////
// Light
/*
struct Light
{
	vec3 position;
	vec3 rotation;
	vec2 size;
	int material;
};
*/


/*
float IntersectLight(Light light, Ray ray, inout HitRecord hitRecord)
{
	mat4 transform = GetTransform(light.rotation, light.position);
	mat4 invTransform = inverse(transform);

	Ray localRay = TransformRay(ray, invTransform);

	float denom = localRay.dir.z;
	float t = -localRay.origin.z / denom;

	if (t > 0.0 && t < hitRecord.t_min)
	{
		vec3 p = RayAt(localRay, t);

		bool hit = all(lessThan(abs(p.xy), light.size));
		if (hit)
		{
			hitRecord.hit = true;
			hitRecord.t_min = t;
			hitRecord.position = vec3(transform * vec4(p, 1.0));
			hitRecord.normal = normalize(vec3(transform * vec4(0.0, 0.0, 1.0, 0.0)));
			hitRecord.material = light.material;
			hitRecord.uv = p.xy / light.size;

			return t;
		}
		else
		{
			return INFINITY;
		}
	}
	else
	{
		return INFINITY;
	}
}
*/

////////////////////////////////////////////////
// Environment Color
vec3 GetEnvironmentColor()
{
	return vec3(0.0, 0.0, 0.0);
}

////////////////////////////////////////////////
// Environment Color
Ray SampleMaterial(Material material, vec3 position, vec3 normal)
{
	vec3 dir = normalize(ConstructMatrixForNormal(normal) * SampleCosHemisphere());

	Ray ray_next = Ray(position, dir);
	ray_next.origin += ray_next.dir * 1e-5;

	return ray_next;
}