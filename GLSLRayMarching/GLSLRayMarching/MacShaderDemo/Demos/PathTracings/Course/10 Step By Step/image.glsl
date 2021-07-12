#define INFINITY 9999999.0
#define PI 3.141592653589
#define NUM_SAMPLES 32
#define NUM_BOUNCES 3

int seed;
int flat_idx;

const float light_size = 0.5;
const float light_area = light_size * light_size;
const vec3 light_position = vec3(0.0, 0.90, 0.5);
const vec3 light_normal = vec3(0, -1, 0);
const vec4 light_albedo = vec4(1, 1, 1, 2.0 / (light_size * light_size));

///////////////////////////////////////////////////////
// random
void encrypt_tea(inout uvec2 arg)
{
	uvec4 key = uvec4(0xa341316c, 0xc8013ea4, 0xad90777d, 0x7e95761e);
	uint v0 = arg[0], v1 = arg[1];
	uint sum = 0u;
	uint delta = 0x9e3779b9u;

	for(int i = 0; i < 32; i++) {
		sum += delta;
		v0 += ((v1 << 4) + key[0]) ^ (v1 + sum) ^ ((v1 >> 5) + key[1]);
		v1 += ((v0 << 4) + key[2]) ^ (v0 + sum) ^ ((v0 >> 5) + key[3]);
	}
	arg[0] = v0;
	arg[1] = v1;
}

vec2 get_random()
{
  	uvec2 arg = uvec2(flat_idx, seed++);
  	encrypt_tea(arg);
  	return fract(vec2(arg) / vec2(0xffffffffu));
}

void rand_seed()
{
	seed = 0;
	flat_idx = int(dot(gl_FragCoord.xy, vec2(1, 4096)));
}

///////////////////////////////////////////////////////
// random sample
vec2 sample_disk(vec2 uv)
{
	float theta = 2.0 * 3.141592653589 * uv.x;
	float r = sqrt(uv.y);
	return vec2(cos(theta), sin(theta)) * r;
}

vec3 sample_cos_hemisphere(vec2 uv)
{
	vec2 disk = sample_disk(uv);
	return vec3(disk.x, sqrt(max(0.0, 1.0 - dot(disk, disk))), disk.y);
}

mat3 construct_ONB_frisvad(vec3 normal)
{
	mat3 ret;
	ret[1] = normal;
	if(normal.z < -0.999805696) 
	{
		ret[0] = vec3(0.0, -1.0, 0.0);
		ret[2] = vec3(-1.0, 0.0, 0.0);
	}
	else 
	{
		float a = 1.0 / (1.0 + normal.z);
		float b = -normal.x * normal.y * a;
		ret[0] = vec3(1.0 - normal.x * normal.x * a, b, -normal.x);
		ret[2] = vec3(b, 1.0 - normal.y * normal.y * a, -normal.y);
	}
	return ret;
}

mat4 rotate_y(float a)
{
	mat4 ret = mat4(1.0);
	ret[0][0] = ret[2][2] = cos(a);
	ret[0][2] = sin(a);
	ret[2][0] = -ret[0][2];
	return ret;
}

/////////////////////////////////////////////////////
// Ray
struct Ray
{
	vec3 origin, dir;
};

vec3 ray_at(in Ray ray, float t)
{
	return ray.origin + t * ray.dir;
}

/////////////////////////////////////////////////////
// AABB
struct AABB
{
	vec3 min_, max_;
};

bool intersect_aabb(in Ray ray, in AABB aabb, inout float t_min, inout float t_max)
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

////////////////////////////////////////////////////
// Plane
float intersect_plane(Ray ray, vec3 center, vec3 normal)
{
    float denom = dot(ray.dir, normal);
    float t = dot(center - ray.origin, normal) / denom;
	return t > 0.0 ? t : INFINITY;
}

/////////////////////////////////////////////////////
// Box
float intersect_box(Ray ray, out vec3 normal, vec3 size)
{
	float t_min = 0.0;
	float t_max = 999999999.0;
	if(intersect_aabb(ray, AABB(-size, size), t_min, t_max)) 
	{
		vec3 p = ray_at(ray, t_min);
		p /= size;
		if(abs(p.x) > abs(p.y)) 
		{
			if(abs(p.x) > abs(p.z)) 
			{
				normal = vec3(p.x > 0.0 ? 1.0 : -1.0, 0, 0);
			}
			else 
			{
				normal = vec3(0, 0, p.z > 0.0 ? 1.0 : -1.0);
			}
		}
		else if(abs(p.y) > abs(p.z)) 
		{
			normal = vec3(0, p.y > 0.0 ? 1.0 : -1.0, 0);
		}
		else 
		{
			normal = vec3(0, 0, p.z > 0.0 ? 1.0 : -1.0);
		}

		return t_min;
	}

	return INFINITY;
}

/////////////////////////////////////////////////////
// Light
vec3 sample_light(vec2 rng)
{
	return light_position + vec3(rng.x - 0.5, 0, rng.y - 0.5) * light_size;
}

float intersect_light(Ray ray)
{
	float t = intersect_plane(ray, light_position, light_normal);

	vec3 p = ray_at(ray, t);
	if(all(lessThan(abs(light_position - p).xz, vec2(light_size * 0.5)))) 
	{
		return t;
	}

	return INFINITY;
}

///////////////////////////////////////////////////////////////////
float intersect(Ray ray, inout vec3 p, inout vec3 normal, out vec4 albedo)
{
	float t_min = INFINITY;

	albedo = vec4(0.0);

	{
		float t = intersect_light(ray);
		if(t < t_min) {
			//albedo = vec3(100);
			albedo = light_albedo;
			//albedo = vec3(dot(ray.dir, light_normal) < 0.0 ? 1.0 : 0.0);
			normal = light_normal;
			t_min  = t;
			p = ray_at(ray, t);
		}
	}

	{
		vec3 normal_tmp;
		Ray ray_tmp = ray;
		//mat4 r = rotate_y(scene_time);
		mat4 r = rotate_y(0.3);
		ray_tmp.origin -= vec3(-0.35, -0.5, -0.35);
		ray_tmp.dir = vec3(r * vec4(ray_tmp.dir, 0));
		ray_tmp.origin = vec3(r * vec4(ray_tmp.origin, 1.0));
		float t = intersect_box(ray_tmp, normal_tmp, vec3(0.25, 0.5, 0.25));
		if(t < t_min) {
			t_min = t;
			p = ray_at(ray, t);
			albedo = vec4(0.7, 0.7, 0.7, 0);
			normal = vec3(transpose(r) * vec4(normal_tmp, 0.0));
		}
	}

	{
		vec3 normal_tmp;
		Ray ray_tmp = ray;
		ray_tmp.origin -= vec3(0.5, -0.75, 0.35);
		float t = intersect_box(ray_tmp, normal_tmp, vec3(0.25, 0.25, 0.25));
		if(t < t_min) {
			t_min = t;
			p = ray_at(ray, t);
			albedo = vec4(0.7, 0.7, 0.7, 0);
			normal = normal_tmp;
		}
	}

	// left
	{
		vec3 n = vec3(1, 0, 0);
		float t = intersect_plane(ray, vec3(-1, 0, 0), n);
		if(t < t_min) {
			vec3 p_tmp = ray_at(ray, t);
			if(all(lessThanEqual(p_tmp.yz, vec2(1))) && all(greaterThanEqual(p_tmp.yz,
							vec2(-1))))
			{
				normal = n;
				p = p_tmp;

				t_min = t;

				albedo = vec4(0.9, 0.1, 0.1, 0);
			}
		}
	}
	// right
	{
		vec3 n = vec3(-1, 0, 0);
		float t = intersect_plane(ray, vec3(1, 0, 0), n);
		if(t < t_min) {
			vec3 p_tmp = ray_at(ray, t);
			if(all(lessThanEqual(p_tmp.yz, vec2(1))) && all(greaterThanEqual(p_tmp.yz,
							vec2(-1))))
			{
				normal = n;
				p = p_tmp;

				t_min = t;

				albedo = vec4(0.1, 0.9, 0.1, 0);
			}
		}
	}
	// floor
	{
		vec3 n = vec3(0, 1, 0);
		float t = intersect_plane(ray, vec3(0, -1, 0), n);
		if(t < t_min) {
			vec3 p_tmp = ray_at(ray, t);
			if(all(lessThan(p_tmp.xz, vec2(1))) && all(greaterThan(p_tmp.xz,
							vec2(-1))))
			{
				normal = n;
				p = p_tmp;
				albedo = vec4(0.7, 0.7, 0.7, 0);

				t_min = t;
			}
		}
	}
	// ceiling
	{
		vec3 n = vec3(0, -1, 0);
		float t = intersect_plane(ray, vec3(0, 1, 0), n);
		if(t < t_min) {
			vec3 p_tmp = ray_at(ray, t);
			if(all(lessThan(p_tmp.xz, vec2(1))) && all(greaterThan(p_tmp.xz,
							vec2(-1))))
			{
				normal = n;
				p = p_tmp;
				albedo = vec4(0.7, 0.7, 0.7, 0);

				t_min = t;
			}
		}
	}
	// back wall
	{
		vec3 n = vec3(0, 0, 1);
		float t = intersect_plane(ray, vec3(0, 0, -1), n);
		if(t < t_min) {
			vec3 p_tmp = ray_at(ray, t);
			if(all(lessThan(p_tmp.xy, vec2(1))) && all(greaterThan(p_tmp.xy,
							vec2(-1))))
			{
				normal = n;
				p = p_tmp;
				albedo = vec4(0.7, 0.7, 0.7, 0);

				t_min = t;
			}
		}
	}


	normal = normalize(normal);

	return t_min;
}

bool test_visibility(vec3 p1, vec3 p2)
{
	const float eps = 1e-5;

	Ray r = Ray(p1, normalize(p2 - p1));
	r.origin += eps * r.dir;

	vec3 n, p;
	vec4 a; // ignored
	float t_shadow = intersect(r, p, n, a);

	return t_shadow > distance(p1, p2) - 2.0 * eps;
}

vec3 pt_mis(Ray ray)
{
	vec3 contrib = vec3(0);
	vec3 tp = vec3(1.0);

	vec3 position, normal;
	vec4 albedo;
	float t = intersect(ray, position, normal, albedo);

	if(t == INFINITY)
		return vec3(0.0);

	if(albedo.a > 0.0) 
	{ 
		/* hight light source */
		return albedo.rgb * albedo.a;
	}

	for(int i = 0; i < NUM_BOUNCES; i++) 
	{
		mat3 onb = construct_ONB_frisvad(normal);

		{ 
			/* NEE */
			vec3 pos_ls = sample_light(get_random());
			vec3 l_nee = pos_ls - position;
			float rr_nee = dot(l_nee, l_nee);
			l_nee /= sqrt(rr_nee);
			float G = max(0.0, dot(normal, l_nee)) * max(0.0, -dot(l_nee, light_normal)) / rr_nee;

			if(G > 0.0) 
			{
				float light_pdf = 1.0 / (light_area * G);
				float brdf_pdf = 1.0 / PI;

				float w = light_pdf / (light_pdf + brdf_pdf);

				vec3 brdf = albedo.rgb / PI;

				if(test_visibility(position, pos_ls)) 
				{
					vec3 Le = light_albedo.rgb * light_albedo.a;
					contrib += tp * (Le * w * brdf) / light_pdf;
				}
			}
		}
		
		{ 
			/* brdf */
			vec3 dir = normalize(onb * sample_cos_hemisphere(get_random()));

			vec3 brdf = albedo.rgb / PI;

			Ray ray_next = Ray(position, dir);
			ray_next.origin += ray_next.dir * 1e-5;

			vec3 position_next, normal_next;
			vec4 albedo_next;
			float t = intersect(ray_next, position_next, normal_next, albedo_next);

			if(t == INFINITY)
				break;

			float brdf_pdf = 1.0 / PI;

			if(albedo_next.a > 0.0) 
			{ 
				/* hit light_source */
				float G = max(0.0, dot(ray_next.dir / t, normal)) * max(0.0, -dot(ray_next.dir / t, normal_next));
				if(G <= 0.0) /* hit back side of light source */
					break;

				float light_pdf = 1.0 / (light_area * G);

				float w = brdf_pdf / (light_pdf + brdf_pdf);

				vec3 Le = light_albedo.rgb * light_albedo.a;
				contrib += tp * (Le * w * brdf) / brdf_pdf;

				break;
			}

			tp *= brdf / brdf_pdf;

			position = position_next;
			normal = normal_next;
			albedo = albedo_next;
		}
	}

	return contrib;
}

//////////////////////////////////////////////////////
void init()
{
	seed = 0;

	rand_seed();
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
	init();

	vec2 p = fragCoord.xy / vec2(iResolution) - vec2(0.5);
	float a = float(iResolution.x) / float(iResolution.y);
	if(a < 1.0)
		p.y /= a;
	else
		p.x *= a;

	vec3 cam_center = vec3(0, 0, 3.125);

	vec3 s = vec3(0);
	for(int i = 0; i < NUM_SAMPLES; i++) 
	{
		Ray ray;
		ray.origin = cam_center;
		vec2 r = get_random();
		vec3 ray_dir = normalize(vec3(p + r.x * dFdx(p) + r.y * dFdy(p), -1));
		ray.dir = ray_dir;
		vec3 c = pt_mis(ray);
		s += c;
	}

	fragColor = vec4(pow(s / float(NUM_SAMPLES), vec3(1.0 / 2.2)), 1.0);
}