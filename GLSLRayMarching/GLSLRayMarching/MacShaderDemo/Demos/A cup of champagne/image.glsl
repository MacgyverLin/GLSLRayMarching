// Rendering parameters
#define RAY_LENGTH_MAX		20.0
#define RAY_BOUNCE_MAX		10
#define RAY_STEP_MAX		80
#define LIGHT				vec3 (1.0, 1.0, -1.0)
#define AMBIENT				0.2
#define SPECULAR_POWER		3.0
#define SPECULAR_INTENSITY	0.5
#define DEFORMATION			2.2

// Rendering options (for those who have a slow GPU)
#define PROPAGATION
#define DISPERSION

// Macros used to handle color channels
#ifdef DISPERSION
	#define COLOR float
	#define CHANNEL(x) dot (x, channel)
#else
	#define COLOR vec3
	#define CHANNEL(x) x
#endif

// Math constants
#define DELTA	0.001
#define PI		3.14159265359

// Smooth minimum
float smin (in float a, in float b, in float k) {
	float h = clamp (0.5 + 0.5 * (a - b) / k, 0.0, 1.0);
	return mix (a, b, h) - k * h * (1.0 - h);
}

// Materials
struct Material {
	vec3 color;
	float behavior; // from -1.0 (fully reflective) to 1.0 (fully transparent)
	vec3 refractIndex; // not used if behavior < 0.0
};
Material getMaterial (in int materialIndex) {
	Material material;
	if (materialIndex == 0) { // Glass
		material = Material (vec3 (0.8, 0.8, 0.8), 0.9, vec3 (1.50, 1.55, 1.60));
	} else if (materialIndex == 1) { // Champagne
		material = Material (vec3 (1.0, 1.0, 0.0), 0.8, vec3 (1.50, 1.55, 1.60));
    } else { // materialIndex == 2 // Table
		material = Material (vec3 (0.5, 0.5, 1.0), -0.5, vec3 (2.0, 2.1, 2.2));
	}
	return material;
}

// Distance to the glass
float getDistanceGlass (in vec3 p, in float d, in float dxz) {
	d = max (max (d - 1.45, 1.4 - d) / DEFORMATION, p.y - 0.4);
	d = min (d, max (dxz - 0.5, p.y + 2.5));
	d = smin (d, max (dxz - 0.08, p.y + 1.4), 0.1);
	return max (d, -p.y - 2.55);
}

// Distance to the champagne
float getDistanceChampagne (in vec3 p, in float d) {
	d = max ((d - 1.4) / DEFORMATION, p.y + p.x * 0.1 * cos (iTime * 2.0));
	return max (d, 0.015 - length (mod (p - vec3 (0.0, iTime, 0.0), 0.4) - 0.2));
}

// Distance to the table
float getDistanceTable (in vec3 p, in float dxz) {
	return max (max (dxz - 1.6, p.y + 2.55), -p.y - 3.2);
}

// Distance to a given material
float getDistanceMaterial (in vec3 p, in int materialIndex) {
	float materialDist;
	if (materialIndex == 0) {
		materialDist = getDistanceGlass (p, length (p * vec3 (DEFORMATION, 1.0, DEFORMATION)), length (p.xz));
	} else if (materialIndex == 1) {
		materialDist = getDistanceChampagne (p, length (p * vec3 (DEFORMATION, 1.0, DEFORMATION)));
    } else { // materialIndex == 2
		materialDist = getDistanceTable (p, length (p.xz));
	}
	return materialDist;
}

// Distance to the scene
#define MATERIAL_PROCESS(MATERIAL) if (materialDist < 0.0) materialTo = MATERIAL; sceneDist = min (sceneDist, materialFrom != MATERIAL ? materialDist : -materialDist);
float getDistanceScene (in vec3 p, in int materialFrom, out int materialTo) {
	float d = length (p * vec3 (DEFORMATION, 1.0, DEFORMATION));
	float dxz = length (p.xz);

	// Air
	materialTo = -1;
	float sceneDist = RAY_LENGTH_MAX;

	// Champagne
	float materialDist = getDistanceChampagne (p, d);
	MATERIAL_PROCESS (1)

	// Glass
	materialDist = getDistanceGlass (p, d, dxz);
	MATERIAL_PROCESS (0)

	// Table
	materialDist = getDistanceTable (p, dxz);
	MATERIAL_PROCESS (2)

	// Return the distance
	return sceneDist;
}

// Normal at a given point
vec3 getNormal (in vec3 p, in int materialIndex) {
	const vec2 h = vec2 (DELTA, -DELTA);
	return normalize (
		h.xxx * getDistanceMaterial (p + h.xxx, materialIndex) +
		h.xyy * getDistanceMaterial (p + h.xyy, materialIndex) +
		h.yxy * getDistanceMaterial (p + h.yxy, materialIndex) +
		h.yyx * getDistanceMaterial (p + h.yyx, materialIndex)
	);
}

// Cast a ray for a given color channel (and its corresponding refraction index)
vec3 lightDirection = normalize (LIGHT);
COLOR raycast (in vec3 origin, in vec3 direction, in vec4 normal, in int materialTo, in COLOR color, in vec3 channel) {

	// Check the behavior of the material
	Material material = getMaterial (materialTo);
	float alpha = abs (material.behavior);
	color *= 1.0 - alpha;

	// The ray continues...
	int materialFrom = -1;
	float refractIndexFrom = 1.0;
	for (int rayBounce = 1; rayBounce < RAY_BOUNCE_MAX; ++rayBounce) {

		// Interface with the material
		float refractIndexTo;
		vec3 refraction;
		if (materialTo == -1) {
			refractIndexTo = 1.0;
			refraction = refract (direction, normal.xyz, refractIndexFrom);
		} else {
			refractIndexTo = dot (material.refractIndex, channel);
			refraction = material.behavior < 0.0 ? vec3 (0.0) : refract (direction, normal.xyz, refractIndexFrom / refractIndexTo);
		}
		if (dot (refraction, refraction) < DELTA) {
			direction = reflect (direction, normal.xyz);
			origin += direction * DELTA * 2.0;
		} else {
			direction = refraction;
			materialFrom = materialTo;
			refractIndexFrom = refractIndexTo;
		}

		// Ray marching
		for (int rayStep = 0; rayStep < RAY_STEP_MAX; ++rayStep) {
			float dist = max (getDistanceScene (origin, materialFrom, materialTo), DELTA);
			normal.w += dist;
			if (materialFrom != materialTo || normal.w > RAY_LENGTH_MAX) {
				break;
			}
			origin += direction * dist;
		}

		// Check whether we hit something
		if (materialFrom == materialTo) {
			break;
		}

		// Get the normal
		if (materialTo == -1) {
			normal.xyz = -getNormal (origin, materialFrom);
		} else {
			normal.xyz = getNormal (origin, materialTo);

			// Basic lighting
			material = getMaterial (materialTo);
			float relfectionDiffuse = max (0.0, dot (normal.xyz, lightDirection));
			float relfectionSpecular = pow (max (0.0, dot (reflect (direction, normal.xyz), lightDirection)), SPECULAR_POWER) * SPECULAR_INTENSITY;
			COLOR localColor = (AMBIENT + relfectionDiffuse) * CHANNEL (material.color) + relfectionSpecular;
			float localAlpha = abs (material.behavior);
			color += localColor * (1.0 - localAlpha) * alpha;
			alpha *= localAlpha;
		}
	}

	// Get the background color
	COLOR backColor = CHANNEL (texture (iChannel0, direction).rgb);

	// Return the intensity of this color channel
	return color + backColor * alpha;
}

// Main function
void mainImage (out vec4 fragColor, in vec2 fragCoord) {

	// Define the ray corresponding to this fragment
	vec2 frag = (2.0 * fragCoord.xy - iResolution.xy) / iResolution.y;
	vec3 direction = normalize (vec3 (frag, 4.0));

	// Set the camera
	vec3 origin = 5.0 * vec3 (cos (iTime * 0.1), 0.2 + 0.8 * sin (iTime * 0.2), sin (iTime * 0.1));
	vec3 forward = -origin;
	vec3 up = vec3 (sin (iTime * 0.3), 2.0, 0.0);
	mat3 rotation;
	rotation [2] = normalize (forward);
	rotation [0] = normalize (cross (up, forward));
	rotation [1] = cross (rotation [2], rotation [0]);
	direction = rotation * direction;
	origin.y -= 1.0;

	// Cast the initial ray
	vec4 normal = vec4 (0.0);
	int materialTo = -1;
	for (int rayStep = 0; rayStep < RAY_STEP_MAX; ++rayStep) {
		float dist = max (getDistanceScene (origin, -1, materialTo), DELTA);
		normal.w += dist;
		if (materialTo != -1 || normal.w > RAY_LENGTH_MAX) {
			break;
		}
		origin += direction * dist;
	}

	// Check whether we hit something
	if (materialTo == -1) {
		fragColor.rgb = texture (iChannel0, direction).rgb;
	} else {

		// Get the normal
		normal.xyz = getNormal (origin, materialTo);

		// Basic lighting
		float relfectionDiffuse = max (0.0, dot (normal.xyz, lightDirection));
		float relfectionSpecular = pow (max (0.0, dot (reflect (direction, normal.xyz), lightDirection)), SPECULAR_POWER) * SPECULAR_INTENSITY;
		fragColor.rgb = (AMBIENT + relfectionDiffuse) * getMaterial (materialTo).color + relfectionSpecular;

		// The ray continues...
		#ifdef PROPAGATION
			#ifdef DISPERSION
				fragColor.r = raycast (origin, direction, normal, materialTo, fragColor.r, vec3 (1.0, 0.0, 0.0));
				fragColor.g = raycast (origin, direction, normal, materialTo, fragColor.g, vec3 (0.0, 1.0, 0.0));
				fragColor.b = raycast (origin, direction, normal, materialTo, fragColor.b, vec3 (0.0, 0.0, 1.0));
			#else
				fragColor.rgb = raycast (origin, direction, normal, materialTo, fragColor.rgb, vec3 (1.0 / 3.0));
			#endif
		#endif
	}

	// Set the alpha channel
	fragColor.a = 1.0;
}