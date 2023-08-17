#define NUM_SAMPLES 32
#define NUM_BOUNCES 3


Material materials[19] = Material[]
(
	Material(vec3(-1.0), 0.0, 0.0, -1.0, vec3(2.0 / (0.5 * 0.5))),

	Material(vec3(0.1, 0.9, 0.1), 0.0, 0.0, -1.0, vec3(-1.0)),
	Material(vec3(0.1, 0.9, 0.9), 0.0, 0.0, -1.0, vec3(-1.0)),

	Material(vec3(0.9, 0.9, 0.9), 0.0, 0.0, -1.0, vec3(-1.0)),
	Material(vec3(0.9, 0.1, 0.1), 0.0, 0.0, -1.0, vec3(-1.0)),
	Material(vec3(0.1, 0.9, 0.1), 0.0, 0.0, -1.0, vec3(-1.0)),
	Material(vec3(0.1, 0.1, 0.9), 0.0, 0.0, -1.0, vec3(-1.0)),

	Material(vec3(0.9, 0.9, 0.9), 1.0, 0.0, -1.0, vec3(-1.0)),
	Material(vec3(0.9, 0.1, 0.1), 1.0, 0.0, -1.0, vec3(-1.0)),
	Material(vec3(0.1, 0.9, 0.1), 1.0, 0.0, -1.0, vec3(-1.0)),
	Material(vec3(0.1, 0.1, 0.9), 1.0, 0.0, -1.0, vec3(-1.0)),

	Material(vec3(0.9, 0.9, 0.9), 0.0, 1.0, -1.0, vec3(-1.0)),
	Material(vec3(0.9, 0.1, 0.1), 0.0, 1.0, -1.0, vec3(-1.0)),
	Material(vec3(0.1, 0.9, 0.1), 0.0, 1.0, -1.0, vec3(-1.0)),
	Material(vec3(0.1, 0.1, 0.9), 0.0, 1.0, -1.0, vec3(-1.0)),

	Material(vec3(0.9, 0.9, 0.9), 1.0, 1.0, -1.0, vec3(-1.0)),
	Material(vec3(0.9, 0.1, 0.1), 1.0, 1.0, -1.0, vec3(-1.0)),
	Material(vec3(0.1, 0.9, 0.1), 1.0, 1.0, -1.0, vec3(-1.0)),
	Material(vec3(0.1, 0.1, 0.9), 1.0, 1.0, -1.0, vec3(-1.0))
);

Plane light = Plane(vec3(0.00, 0.90, 0.50), vec3(-PI / 2, 0, 0), vec2(0.25, 0.25), 0);
Sphere s0 = Sphere(vec3(-0.35,  0.50, -0.35), 0.20, 1);
Sphere s1 = Sphere(vec3( 0.50,  0.00,  0.35), 0.20, 2);
Box b0 = Box(vec3(-0.35, -0.50, -0.35), vec3(0.0, 0.3, 0.0), vec3(0.25, 0.50, 0.25), 3);
Box b1 = Box(vec3(0.50, -0.75, 0.35), vec3(0.5, 0.0, 0.0), vec3(0.25, 0.25, 0.25), 3);
Plane l = Plane(vec3(-1, 0, 0), vec3(0, -PI / 2, 0), vec2(1, 1), 4);
Plane r = Plane(vec3(1, 0, 0), vec3(0, PI / 2, 0), vec2(1, 1), 5);
Plane d = Plane(vec3(0, -1, 0), vec3(PI / 2, 0, 0), vec2(1, 1), 3);
Plane u = Plane(vec3(0, 1, 0), vec3(-PI / 2, 0,  0), vec2(1, 1), 3);
Plane b = Plane(vec3(0, 0, -1), vec3(0, 0, 0), vec2(1, 1), 3);

vec3 SampleLightPosition()
{
	return PlaneGetPoint(light);
}

vec3 GetLightNormal()
{
	return PlaneGetNormal(light);
}

bool TraceRay(Ray ray, inout HitRecord hitRecord)
{
	hitRecord = HitRecord(false, INFINITY, vec3(0.0), vec3(0.0), 0, vec2(0.0, 0.0));

	IntersectPlane(light, ray, hitRecord);

	IntersectBox(b0, ray, hitRecord);

	IntersectBox(b1, ray, hitRecord);

	IntersectSphere(s0, ray, hitRecord);

	IntersectSphere(s1, ray, hitRecord);

	IntersectPlane(l, ray, hitRecord);

	IntersectPlane(r, ray, hitRecord);

	IntersectPlane(d, ray, hitRecord);

	IntersectPlane(u, ray, hitRecord);

	IntersectPlane(b, ray, hitRecord);

	return hitRecord.t_min != INFINITY;
}

bool TraceShadowRay(vec3 p1, vec3 p2)
{
	const float eps = 1e-5;

	Ray r = Ray(p1, normalize(p2 - p1));
	r.origin += eps * r.dir;

	HitRecord hitRecord = HitRecord(false, INFINITY, vec3(0.0), vec3(0.0), 0, vec2(0.0, 0.0));
	TraceRay(r, hitRecord);
	
	return hitRecord.t_min > distance(p1, p2) - 2.0 * eps;
}

vec3 PathTrace(Ray ray)
{
	vec3 contrib = vec3(0);
	vec3 throughput = vec3(1.0);

	HitRecord hitRecord;
	if (!TraceRay(ray, hitRecord))
	{
		return GetEnvironmentColor();
	}
	else
	{
		if (isEmmissive(materials[hitRecord.material]))  
		{
			// hit light source
			return materials[hitRecord.material].emmissive;
		}
		else
		{
			// not hit light source
			for (int i = 0; i < NUM_BOUNCES; i++)
			{
				// NEE
				{
					vec3 x = hitRecord.position;
					vec3 nx = hitRecord.normal;
					vec3 y = SampleLightPosition();
					vec3 ny = GetLightNormal();

					vec3 x_y = y - x;
					float sqrmagnitude_xy = dot(x_y, x_y);
					x_y /= sqrt(sqrmagnitude_xy);

					if (TraceShadowRay(hitRecord.position, y))
					{
						float G = max(0.0, dot(x_y, nx)) * max(0.0, dot(-x_y, ny)) / sqrmagnitude_xy;
						if (G > 0.0)
						{
							vec3 brdf = materials[hitRecord.material].albedo / PI;

							float lightPDF = 1.0 / (light.size.x * light.size.y * G);
							float brdfPDF = 1.0 / PI;
							float w = lightPDF / (lightPDF + brdfPDF);

							vec3 Le = materials[light.material].emmissive;
							contrib += throughput * (Le * w * brdf) / lightPDF;
						}
					}
				}

				// brdf
				{
					Ray ray_next;
					ray_next = SampleMaterial(materials[hitRecord.material], hitRecord.position, hitRecord.normal);
					
					HitRecord nextHitRecord;
					if (!TraceRay(ray_next, nextHitRecord))
					{
						return GetEnvironmentColor();

						break;
					}
					else
					{
						// hit light_source
						if (isEmmissive(materials[nextHitRecord.material]))
						{
							float G = max(0.0, dot(ray_next.dir, hitRecord.normal)) * max(0.0, dot(-ray_next.dir, nextHitRecord.normal)) / (nextHitRecord.t_min * nextHitRecord.t_min);
							if (G > 0.0)
							{
								vec3 brdf = materials[hitRecord.material].albedo / PI;
								float lightPDF = 1.0 / (light.size.x * light.size.y * G);
								float brdfPDF = 1.0 / PI;
								float w = brdfPDF / (lightPDF + brdfPDF);

								vec3 Le = materials[light.material].emmissive;
								contrib += throughput * (Le * w * brdf) / brdfPDF;
							}

							break;
						}
						else
						{
							float brdfPDF = 1.0 / PI;
							vec3 brdf = materials[hitRecord.material].albedo / PI;
							
							throughput *= brdf / brdfPDF;
							hitRecord = nextHitRecord;
						}
					}
				}
			}

			return contrib;
		}
	}
}

void Animate()
{
	light.position = vec3(0.5 * sin(iTime), 0.90, 0.5 * cos(iTime));

	b0.rotation.y = sin(iTime) * 0.3;
	b1.rotation.x = sin(iTime) * 0.3;

	b.position.x = 2.0 * sin(iTime);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
	InitRandom();
	Animate();

	vec3 cam_center = vec3(0, 0, 3.125);

	vec3 color = vec3(0);
	for (int i = 0; i < NUM_SAMPLES; i++)
	{
		Ray ray = GenRay(fragCoord, cam_center, vec2(iResolution));

		color += PathTrace(ray);
	}

	fragColor = vec4(pow(color / float(NUM_SAMPLES), vec3(1.0 / 2.2)), 1.0);
}