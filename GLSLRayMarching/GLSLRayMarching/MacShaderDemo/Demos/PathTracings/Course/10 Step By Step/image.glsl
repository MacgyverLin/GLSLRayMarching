#define INFINITY 9999999.0
#define PI 3.141592653589
#define NUM_SAMPLES 32
#define NUM_BOUNCES 3

int seed;
int flat_idx;

///////////////////////////////////////////////////////
// random
void encrypt_tea(inout uvec2 arg)
{
	uvec4 key = uvec4(0xa341316c, 0xc8013ea4, 0xad90777d, 0x7e95761e);
	uint v0 = arg[0], v1 = arg[1];
	uint sum = 0u;
	uint delta = 0x9e3779b9u;

	for(int i = 0; i < 32; i++) 
	{
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
struct Camera
{
	vec3 position;
	vec3 forward;
	vec3 right;
	float aspect;
};

struct Ray
{
	vec3 origin, dir;
};

vec3 ray_at(in Ray ray, float t)
{
	return ray.origin + t * ray.dir;
}

struct Transform
{
	vec3 position;
	vec3 rotation;
};

vec3 transformPosition(vec3 p)
{
	return vec3(0.0);
}

vec3 transformDir(vec3 p)
{
	return vec3(0.0);
}

////////////////////////////////////////////////////
struct HitRecord
{
	bool hit;
	bool hitLight;
	float t;
	vec3 position;
	vec3 normal;
	vec3 tangent;
	vec3 binormal;

	vec4 albedo;
};

////////////////////////////////////////////////////
// Plane
struct Plane
{
	Transform transform;
	vec3 normal;
	vec3 tangent;
	vec3 binormal;

	vec2 size;

	vec4 albedo;
};

void intersect_plane(in Ray ray, in Plane plane, out HitRecord hitrecord)
{
    float denom = dot(ray.dir, plane.normal);
    
	float t = dot(plane.transform.position - ray.origin, plane.normal) / denom;

	if(t > 0.0)
	{
		vec3 p_tmp = ray_at(ray, t);

		vec3 diff = p_tmp - plane.transform.position;
		float u = dot(diff, plane.tangent) / plane.size.x;
		float v = dot(diff, plane.binormal) / plane.size.y;
		if(abs(u) < 1.0 && abs(v) < 1.0)
		{
			hitrecord.hit		= true;
			hitrecord.hitLight	= false;
			hitrecord.t			= t;
			hitrecord.position	= p_tmp;
			hitrecord.normal	= plane.normal;
			hitrecord.tangent	= plane.tangent;
			hitrecord.binormal	= plane.binormal;
			
			hitrecord.albedo	= plane.albedo;
		}
		else
		{
			hitrecord.hit		= false;
			hitrecord.t			= INFINITY;
		}
	}
	else
	{
		hitrecord.hit		= false;
		hitrecord.t			= INFINITY;
	}
}

/////////////////////////////////////////////////////
// Light
struct Light
{
	Transform transform;
	vec3 normal;
	vec3 tangent;
	vec3 binormal;

	vec2 size;

	vec4 albedo;
};

vec3 randomSampleLight(in Light light)
{
	vec2 rng = get_random();
	return light.transform.position + vec3((rng.x - 0.5) * light.size.x, 0, (rng.y - 0.5) * light.size.y);
}

void intersect_light(in Ray ray, in Light light, out HitRecord hitrecord)
{
    float denom = dot(ray.dir, light.normal);
	float t = dot(light.transform.position - ray.origin, light.normal) / denom;

	vec3 p_tmp = ray_at(ray, t);
	if(t > 0.0)
	{
		vec3 diff = p_tmp - light.transform.position;
		float u = dot(diff, light.tangent) / light.size.x;
		float v = dot(diff, light.binormal) / light.size.y;
		if(abs(u) < 0.5 && abs(v) < 0.5)
		{
			hitrecord.hit		= true;
			hitrecord.hitLight	= true;
			hitrecord.t			= t;
			hitrecord.position	= p_tmp;
			hitrecord.normal	= light.normal;
			hitrecord.tangent	= light.tangent;
			hitrecord.binormal	= light.binormal;

			hitrecord.albedo	= light.albedo;
		}
		else
		{
			hitrecord.hit		= false;
			hitrecord.t			= INFINITY;
		}
	}
	else
	{
		hitrecord.hit		= false;
		hitrecord.t			= INFINITY;
	}
}

/////////////////////////////////////////////////////
// AABB
struct AABB
{
	vec3 min_;
	vec3 max_;
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

/////////////////////////////////////////////////////
// Box
struct Box
{
	Transform transform;
	vec3 size;

	vec4 albedo;
};

void intersect_box(in Ray ray, in Box box, out HitRecord hitrecord)
{
	Ray ray_tmp			= ray;
	mat4 r				= rotate_y(box.transform.rotation[1]);
	ray_tmp.origin		-= box.transform.position;
	ray_tmp.origin		= vec3(r * vec4(ray_tmp.origin, 1.0));
	ray_tmp.dir			= vec3(r * vec4(ray_tmp.dir, 0));

	float t_min = 0.0;
	float t_max = 999999999.0;
	if(intersect_aabb(ray_tmp, AABB(-box.size, box.size), t_min, t_max)) 
	{
		vec3 p = ray_at(ray_tmp, t_min);
		p /= box.size;
		if(abs(p.x) > abs(p.y)) 
		{
			if(abs(p.x) > abs(p.z)) 
			{
				hitrecord.normal = vec3(p.x > 0.0 ? 1.0 : -1.0, 0, 0);
				hitrecord.tangent = vec3(0, 1, 0);
				hitrecord.binormal = vec3(0, 0, 1);
			}
			else 
			{
				hitrecord.normal = vec3(0, 0, p.z > 0.0 ? 1.0 : -1.0);
				hitrecord.tangent = vec3(0, 1, 0);
				hitrecord.binormal = vec3(1, 0, 0);
			}
		}
		else if(abs(p.y) > abs(p.z)) 
		{
			hitrecord.normal = vec3(0, p.y > 0.0 ? 1.0 : -1.0, 0);
			hitrecord.tangent = vec3(0, 0, 1);
			hitrecord.binormal = vec3(1, 0, 0);
		}
		else 
		{
			hitrecord.normal = vec3(0, 0, p.z > 0.0 ? 1.0 : -1.0);
			hitrecord.tangent = vec3(0, 1, 0);
			hitrecord.binormal = vec3(1, 0, 0);
		}

		hitrecord.hit		= true;
		hitrecord.hitLight	= false;
		hitrecord.t			= t_min;
		hitrecord.position	= ray_at(ray, hitrecord.t);
		hitrecord.normal	= vec3(transpose(r) * vec4(hitrecord.normal, 0.0));
		hitrecord.tangent	= vec3(transpose(r) * vec4(hitrecord.tangent, 0.0));
		hitrecord.binormal	= vec3(transpose(r) * vec4(hitrecord.binormal, 0.0));

		hitrecord.albedo	= box.albedo;
	}
	else
	{
		hitrecord.hit		= false;
		hitrecord.t			= INFINITY;
	}
}

///////////////////////////////////////////////////////////////////
// Scene Description
Camera camera;

#define NUM_BOXES 2
Box boxes[NUM_BOXES];

#define NUM_LIGHTS 1
Light lights[NUM_LIGHTS];

#define NUM_PLANES 5
Plane planes[NUM_PLANES];

///////////////////////////////////////////////////////////////////
void intersect(in Ray ray, inout HitRecord hitrecord)
{
	hitrecord.hit		= false;
	hitrecord.hitLight	= false;
	hitrecord.t			= INFINITY;
	hitrecord.albedo	= vec4(0.0);

	for(int i=0; i<NUM_LIGHTS; i++)
	{
		HitRecord lightHitrecord;
		intersect_light(ray, lights[i], lightHitrecord);
		if(lightHitrecord.t < hitrecord.t) 
		{
			hitrecord = lightHitrecord;
		}
	}

	for(int i=0; i<NUM_BOXES; i++)
	{
		HitRecord boxHitrecord;
		intersect_box(ray, boxes[i], boxHitrecord);
		if(boxHitrecord.t < hitrecord.t) 
		{
			hitrecord = boxHitrecord;
		}
	}

	for(int i=0; i<NUM_PLANES; i++)
	{
		HitRecord planeHitrecord;
		intersect_plane(ray, planes[i], planeHitrecord);
		if(planeHitrecord.t < hitrecord.t) 
		{
			hitrecord = planeHitrecord;
		}
	}
}

bool test_visibility(vec3 p1, vec3 p2)
{
	const float eps = 1e-5;

	Ray r = Ray(p1, normalize(p2 - p1));
	r.origin += eps * r.dir;

	HitRecord hitrecord;
	intersect(r, hitrecord);

	return hitrecord.t > distance(p1, p2) - 2.0 * eps;
}

float getLightArea(in Light light)
{
	return light.size.x * light.size.y;
}

vec3 getLightLe(in Light light)
{
	return light.albedo.rgb * light.albedo.a;
}

void sampleLight(in Light light, inout HitRecord hitrecord, inout vec3 radiance, inout vec3 throughput)
{ 
	/* NEE */
	vec3 lightPosition = randomSampleLight(light);
	vec3 lightDirection = lightPosition - hitrecord.position;

	float sqrR = dot(lightDirection, lightDirection);
	lightDirection = normalize(lightDirection);
	
	float G = max(0.0, dot(hitrecord.normal, lightDirection)) * max(0.0, -dot(light.normal, lightDirection)) / sqrR;
	if(G > 0.0) 
	{
		float light_pdf = 1.0 / (getLightArea(light) * G);
		float brdf_pdf	= 1.0 / PI;
		float w = light_pdf / (light_pdf + brdf_pdf);

		vec3 brdf = hitrecord.albedo.rgb / PI;
		vec3 Le = getLightLe(light);

		if(test_visibility(hitrecord.position, lightPosition)) 
		{
			radiance += w * (throughput * (Le * brdf) / light_pdf);
		}
	}
}

bool sampleBRDF(in Light light, inout HitRecord hitrecord, inout vec3 radiance, inout vec3 throughput)
{ 
	/* brdf */
	mat3 onb = construct_ONB_frisvad(hitrecord.normal);

	Ray rayNext = Ray
	(
		hitrecord.position, 
		normalize(onb * sample_cos_hemisphere(get_random()))
	);
	rayNext.origin += rayNext.dir * 1e-5;

	HitRecord hitrecordNext;
	intersect(rayNext, hitrecordNext);
	if(!hitrecordNext.hit)
		return false;

	if(hitrecordNext.hitLight)			// if hit a light
	{ 
		float G = max(0.0, dot(rayNext.dir / hitrecordNext.t, hitrecord.normal)) * max(0.0, -dot(rayNext.dir / hitrecordNext.t, hitrecordNext.normal));
		if(G > 0.0)						// if hit back side of light source
		{
			return false;
		}
		else
		{
			float light_pdf = 1.0 / (getLightArea(light) * G);
			float brdf_pdf = 1.0 / PI;
			float w = brdf_pdf / (light_pdf + brdf_pdf);

			vec3 brdf = hitrecord.albedo.rgb / PI;
			vec3 Le = getLightLe(light);

			radiance += w * (throughput * (Le * brdf) / brdf_pdf);

			return false;
		}
	}
	else								// if hit an object
	{
		vec3 brdf = hitrecord.albedo.rgb / PI;
		float brdf_pdf = 1.0 / PI;

		throughput *= brdf / brdf_pdf;
		hitrecord = hitrecordNext;

		return true;
	}
}

vec3 traceWorld(Ray ray)
{
	vec3 radiance = vec3(0);
	vec3 throughput = vec3(1.0);

	HitRecord hitrecord;
	intersect(ray, hitrecord);
	if(hitrecord.hit)					// hit shader
	{
		if(hitrecord.hitLight)			// if hit a light
		{ 
			return hitrecord.albedo.rgb * hitrecord.albedo.a;
		}
		else							// if hit an object
		{
			for(int i = 0; i < NUM_BOUNCES; i++) 
			{
				for(int j = 0; j < NUM_LIGHTS; j++) 
				{
					sampleLight(lights[j], hitrecord, radiance, throughput);

					if( !sampleBRDF(lights[j], hitrecord, radiance, throughput) )
						break;
				}
			}
	
			return radiance;
		}
	}
	else								// miss shader
	{
		return vec3(0.0);
	}
}

//////////////////////////////////////////////////////
void init()
{
	seed = 0;
	rand_seed();

	camera = Camera(vec3(0, 0, 3.125), vec3(0.0, 0.0, -1.0), vec3(1.0, 0.0, 0.0), iResolution.x / iResolution.y);

	boxes[0] = Box( Transform(vec3(-0.35, -0.50, -0.35), vec3(0.0, 0.3, 0.0)), vec3(0.25, 0.50, 0.25),  vec4(0.7, 0.7, 0.7, 0) );
	boxes[1] = Box( Transform(vec3( 0.50, -0.75,  0.35), vec3(0.0, 0.0, 0.0)), vec3(0.25, 0.25, 0.25),  vec4(0.7, 0.7, 0.7, 0) );
	
	const vec3 light_position = vec3(0.0, 0.90, 0.5);
	const vec3 light_normal = vec3(0, -1, 0);
	const vec2 light_size = vec2(0.5, 0.5);
	const float light_area = light_size.x * light_size.y;
	const vec4 light_albedo0 = vec4(1, 1, 1, 2.0 / (light_area));
	const vec4 light_albedo1 = vec4(0, 1, 0, 2.0 / (light_area));

	lights[0] = Light( Transform(vec3(light_position), vec3(0, 0, 0)), light_normal, vec3( 1,  0,  0), vec3( 0,  0,  1), light_size, light_albedo0 );
	#if NUM_LIGHTS >1
		lights[1] = Light( Transform(vec3(-1,  0,  0), vec3(0, 0, 0)), vec3( 1,  0,  0), vec3( 0,  1,  0), vec3( 0,  0,  1), light_size, light_albedo1 );
	#endif

	planes[0] = Plane( Transform(vec3(-1,  0,  0), vec3(0, 0, 0)), vec3( 1,  0,  0), vec3( 0,  1,  0), vec3( 0,  0,  1), vec2(1, 1), vec4(0.9, 0.1, 0.1, 0));
	planes[1] = Plane( Transform(vec3( 1,  0,  0), vec3(0, 0, 0)), vec3(-1,  0,  0), vec3( 0,  1,  0), vec3( 0,  0,  1), vec2(1, 1), vec4(0.1, 0.9, 0.1, 0));
	planes[2] = Plane( Transform(vec3( 0, -1,  0), vec3(0, 0, 0)), vec3( 0,  1,  0), vec3( 1,  0,  0), vec3( 0,  0,  1), vec2(1, 1), vec4(0.7, 0.7, 0.7, 0));
	planes[3] = Plane( Transform(vec3( 0,  1,  0), vec3(0, 0, 0)), vec3( 0, -1,  0), vec3( 1,  0,  0), vec3( 0,  0,  1), vec2(1, 1), vec4(0.7, 0.7, 0.7, 0));
	planes[4] = Plane( Transform(vec3( 0,  0, -1), vec3(0, 0, 0)), vec3( 0,  0,  1), vec3( 1,  0,  0), vec3( 0,  1,  0), vec2(1, 1), vec4(0.7, 0.7, 0.7, 0));
}

Ray generateRay(Camera camera, in vec2 fragCoord)
{
	vec2 p = (fragCoord.xy + get_random() - vec2(0.5, 0.5)) / vec2(iResolution) - vec2(0.5);

	return Ray(camera.position, normalize(vec3(p.x * camera.aspect, p.y, -1.0)));
}

void moveLight(inout Light l)
{
	l.transform.position  = vec3(0.5 * sin(iTime), 0.90, 0.5 * cos(iTime));
}

void moveCamera(inout Camera c)
{
	c.position = vec3(0, 0, 3.125) + vec3(0.5 * sin(iTime), 0.5 * cos(iTime), 0.00);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
	init();

	//moveLight(lights[0]);
	//moveCamera(camera);

	vec3 radiance = vec3(0);
	for(int i = 0; i < NUM_SAMPLES; i++) 
	{
		Ray ray = generateRay(camera, fragCoord);

		radiance += traceWorld(ray);
	}

	radiance = radiance / float(NUM_SAMPLES);

	fragColor = vec4(pow(radiance, vec3(1.0 / 2.2)), 1.0);
}