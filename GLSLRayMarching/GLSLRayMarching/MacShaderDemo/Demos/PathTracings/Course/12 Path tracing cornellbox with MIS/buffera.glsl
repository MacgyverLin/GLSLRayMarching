#define KEY_DOWN(key)   (texture(iChannel2, vec2((float(key+1) + 0.5)/256.0, (0.0 + 0.5)/3)).r == 0)
#define KEY_CLICK(key)  (texture(iChannel2, vec2((float(key+1) + 0.5)/256.0, (1.0 + 0.5)/3)).r == 0)
#define KEY_TOGGLE(key) (texture(iChannel2, vec2((float(key+1) + 0.5)/256.0, (2.0 + 0.5)/3)).r == 0)

const vec2 acc_start_coord = vec2(0, 0);
const vec2 metallic_coord = vec2(1, 0);
const vec2 camerapos_coord = vec2(2, 0);

int getStartFrame()
{
	return int(texture(iChannel0, (acc_start_coord + vec2(0.5, 0.5)) / iResolution.xy).r);
}

float getMetallic()
{
	return texture(iChannel0, (metallic_coord + vec2(0.5, 0.5)) / iResolution.xy).r;
}

float getRougness()
{
	return texture(iChannel0, (metallic_coord + vec2(0.5, 0.5)) / iResolution.xy).g;
}

vec3 OutputColor(vec3 color, in vec2 fragCoord)
{
	// 	    if(iMouse.z > 0.0 || KEY_DOWN('r') || KEY_DOWN('f') || KEY_DOWN('t') || KEY_DOWN('g'))
	if (all(equal(floor(fragCoord.xy).xy, acc_start_coord)))
	{
		if (iMouse.z > 0.0)
			return vec3(iFrame);    // save Start Frame in pixel
		else
			return vec3(getStartFrame()); // return Start Frame in pixel
	}
	/*
	else if(all(equal(floor(fragCoord.xy).xy, camerapos_coord)))
	{
		vec3 cameraPos = getCameraPos();

		if(iFrame==0)
		{
			cameraPos = vec3(50.0, 40.8, 172.0);
		}

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

		float roughness = getMetallic();
		if(KEY_DOWN('t'))
		{
			roughness += 0.001;
			if(roughness > 1.0)
				roughness = 1.0;
		}
		else if(KEY_DOWN('g'))
		{
			roughness -= 0.001;
			if(roughness < 0.0)
				roughness = 0.0;
		}

		return vec3(metallic, roughness, 1.0);
	}
	*/
	else
	{
		int frame = iFrame - getStartFrame();

		vec3 oldcolor = texture(iChannel0, fragCoord.xy / iResolution.xy).rgb;

		color = oldcolor * float(frame) / float(frame + 1) + color / float(frame + 1);

		return color;
	}
}


////////////////////////////////////////////////////////////////
#define NUM_SAMPLES 1
#define NUM_BOUNCES 10

Material materials[19] = Material[]
(
	Material(vec3(0.0, 0.0, 0.0), 0.0, 0.0, -1.0, vec3(4.0, 4.0, 4.0)),

	Material(vec3(0.9, 0.9, 0.9), 0.0, 0.1, -1.0, vec3(-1.0)),
	Material(vec3(0.1, 0.9, 0.9), 0.0, 1.0, -1.0, vec3(-1.0)),

	Material(vec3(0.9, 0.9, 0.9), 0.0, 1.0, -1.0, vec3(-1.0)),
	Material(vec3(0.9, 0.1, 0.1), 0.0, 1.0, -1.0, vec3(-1.0)),
	Material(vec3(0.1, 0.9, 0.1), 0.0, 1.0, -1.0, vec3(-1.0)),
	Material(vec3(0.1, 0.1, 0.9), 0.0, 1.0, -1.0, vec3(-1.0)),

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

Plane light = Plane(vec3(0.00, 0.90, 0.50), vec3(-PI / 2.0, 0, 0), vec2(0.25, 0.25), 0);
Sphere s0 = Sphere(vec3(-0.35, 0.50, -0.35), 0.20, 1);
Sphere s1 = Sphere(vec3(0.50, 0.00, 0.35), 0.20, 2);
Box b0 = Box(vec3(-0.35, -0.50, -0.35), vec3(0.0, 0.3, 0.0), vec3(0.25, 0.50, 0.25), 1);
Box b1 = Box(vec3(0.50, -0.55, 0.35), vec3(0.5, 0.0, 0.0), vec3(0.25, 0.25, 0.25), 2);
Plane l = Plane(vec3(-1, 0, 0), vec3(0, -PI / 2.0, 0), vec2(1, 1), 3);
Plane r = Plane(vec3(1, 0, 0), vec3(0, PI / 2.0, 0), vec2(1, 1), 4);
Plane d = Plane(vec3(0, -1, 0), vec3(PI / 2.0, 0, 0), vec2(1, 1), 5);
Plane u = Plane(vec3(0, 1, 0), vec3(-PI / 2.0, 0, 0), vec2(1, 1), 6);
Plane b = Plane(vec3(0, 0, -1), vec3(0, 0, 0), vec2(1, 1), 3);





vec3 SampleLightPosition()
{
	return PlaneGetPoint(light);
}

vec3 SampleLightNormal()
{
	return PlaneGetNormal(light);
}

////////////////////////////////////////////////
// Environment Color
vec3 GetEnvironmentColor(vec3 dir)
{
	return texture(iChannel3, dir).rgb;
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
	vec3 direct = vec3(0);
	vec3 indirect = vec3(0);
	vec3 throughput = vec3(1.0);

	HitRecord hitRecord;
	if (!TraceRay(ray, hitRecord))
	{
		direct = GetEnvironmentColor(ray.dir);
	}
	else
	{
		if (isEmmissive(materials[hitRecord.material]))  /* hit light source */
		{
			direct = GetEmmissive(materials[hitRecord.material]);
		}
		else
		{
			float rrPDF = 0.3;
			//for (int i = 0; i < NUM_BOUNCES; i++)

			int i = 0;
			while (Random().x < rrPDF/* && i < NUM_BOUNCES*/ )
			{
				vec3 brdf;
				float brdfPDF;
				Ray ray_next;
				SamplePBRMaterial(materials, ray, hitRecord, 
					brdf, brdfPDF, ray_next);

				// BRDF Sampling
				{
					HitRecord nextHitRecord;
					if (!TraceRay(ray_next, nextHitRecord))
					{
						vec3 Li = GetEnvironmentColor(ray_next.dir);

						vec3 c = throughput * (brdf) * (Li / brdfPDF) / rrPDF;
						if (i == 0)
							direct += c;
						else
							indirect += c;
						break;
					}
					else
					{
						// hit light_source
						if (isEmmissive(materials[nextHitRecord.material]))
						{
							float G = max(0.0, dot(ray_next.dir, hitRecord.normal)) 
								* max(0.0, dot(-ray_next.dir, nextHitRecord.normal))
								/ (nextHitRecord.t_min * nextHitRecord.t_min);
							if (G > 0.0)
							{
								vec3 Li = GetEmmissive(materials[hitRecord.material]);
								float lightPDF = 1.0 / (light.size.x * light.size.y * G);
								float misW = brdfPDF / (lightPDF + brdfPDF);

								vec3 c = misW * throughput * (brdf) * (Li / brdfPDF) / rrPDF;
								if (i == 0)
									direct += c;
								else
									indirect += c;
								break;
							}
						}
						else
						{
							throughput *= brdf / brdfPDF;

							hitRecord = nextHitRecord;
						}
					}
				}

				i++;
			}
		}
	}


	return direct + indirect;
}

void Animate()
{
	//light.position = vec3(0.5 * sin(iTime), 0.90, 0.5 * cos(iTime));

	//b0.rotation.y = sin(iTime) * 0.3;
	//b1.rotation.x = sin(iTime) * 0.3;

	//b.position.x = 2.0 * sin(iTime);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
	InitRandom(iTime);
	Animate();

	vec3 cam_center = vec3(0, 0, 3.125);


	vec3 color = vec3(0);
	for (int i = 0; i < NUM_SAMPLES; i++)
	{
		Ray ray = GenRay(fragCoord, cam_center, vec2(iResolution));

		color += PathTrace(ray);
	}
	color = color / float(NUM_SAMPLES);


	fragColor = vec4(OutputColor(color, fragCoord), 1);
}