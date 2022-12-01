const float PI = 3.14159265359;
const float FOV = 67.0 / 180.0 * PI;
const float MAX = 10000.0;

// scatter constants
const float K_R = 0.166;
const float K_M = 0.025;
const float E = 14.3; // light intensity
const vec3 C_R = vec3(0.3, 0.7, 1.0); // 1 / wavelength ^ 4
const float G_M = -0.85; // Mie g

const float R_INNER = 1.0;
const float R = R_INNER * 1.025;
const float SCALE_H = 4.0 / (R - R_INNER);
const float SCALE_L = 1.0 / (R - R_INNER);

const int NUM_OUT_SCATTER = 10;
const float FNUM_OUT_SCATTER = 10.0;

const int NUM_IN_SCATTER = 10;
const float FNUM_IN_SCATTER = 10.0;

const float WATER_HEIGHT = 0.7;
const vec3 LIGHT = vec3(0, 0, 1.0);

#define SEED 171.

vec2 ray_vs_sphere(vec3 p, vec3 dir, float r)
{
	float b = dot(p, dir);
	float c = dot(p, p) - r * r;

	float d = b * b - c;
	if (d < 0.0)
		return vec2(MAX, -MAX);
	d = sqrt(d);

	return vec2(-b - d, -b + d);
}

float phase_mie(float g, float c, float cc)
{
	float gg = g * g;

	float a = (1.0 - gg) * (1.0 + cc);

	float b = 1.0 + gg - 2.0 * g * c;
	b *= sqrt(b);
	b *= 2.0 + gg;

	return 1.5 * a / b;
}

float phase_reyleigh(float cc)
{
	return 0.75 * (1.0 + cc);
}

float density(vec3 p)
{
	return exp(-(length(p) - R_INNER) * SCALE_H);
}

float optic(vec3 p, vec3 q)
{
	vec3 step = (q - p) / FNUM_OUT_SCATTER;
	vec3 v = p + step * 0.5;

	float sum = 0.0;
	for (int i = 0; i < NUM_OUT_SCATTER; i++)
	{
		sum += density(v);
		v += step;
	}
	sum *= length(step) * SCALE_L;

	return sum;
}

vec3 in_scatter(vec3 o, vec3 dir, vec2 e, vec3 l)
{
	float len = (e.y - e.x) / FNUM_IN_SCATTER;
	vec3 step = dir * len;
	vec3 p = o + dir * e.x;
    vec3 pa = p;
    vec3 pb = o + dir * e.y;
	vec3 v = p + dir * (len * 0.5);

	vec3 sum = vec3(0.0);
	for (int i = 0; i < NUM_IN_SCATTER; i++)
	{
		vec2 f = ray_vs_sphere(v, l, R);
		vec3 u = v + l * f.y;

		float n = (optic(p, v) + optic(v, u)) * (PI * 4.0);

		sum += density(v) * exp(-n * (K_R * C_R + K_M));

		v += step;
	}
	sum *= len * SCALE_L;

	float c = dot(dir, -l);
	float cc = c * c;
	return sum * (K_R * C_R * phase_reyleigh(cc) + K_M * phase_mie(G_M, c, cc)) * E;
}

vec3 scatter(vec3 ro, vec3 rd, vec2 f)
{
	vec2 e = ray_vs_sphere(ro, rd, R);
	if (e.x > e.y)
		return vec3(0);

	e.y = min(e.y, f.x);

	return in_scatter(ro, rd, e, LIGHT);
}
//###### end scatter

//###### noise
// credits to iq for this noise algorithm

mat3 m = mat3(0.00, 0.80, 0.60,
		-0.80, 0.36, -0.48,
		-0.60, -0.48, 0.64);

float hash(float n)
{
	return fract(sin(n) * 43758.5453);
}

float noise(in vec3 x)
{
	vec3 p = floor(x);
	vec3 f = fract(x);

	f = f * f * (3.0 - 2.0 * f);

	float n = p.x + p.y * 57.0 + 113.0 * p.z;

	float res = mix(mix(mix(hash(n + 0.0), hash(n + 1.0), f.x),
				mix(hash(n + 57.0), hash(n + 58.0), f.x), f.y),
			mix(mix(hash(n + 113.0), hash(n + 114.0), f.x),
				mix(hash(n + 170.0), hash(n + 171.0), f.x), f.y), f.z);
	return res;
}

float fbm(vec3 p)
{
	float f;
	f = 0.5000 * noise(p);
	p = m * p * 2.02;
	f += 0.2500 * noise(p);
	p = m * p * 2.03;
	f += 0.1250 * noise(p);
	p = m * p * 2.01;
	f += 0.0625 * noise(p);
	return f;
}

//###### end noise

float rnd(float r)
{
	return r - mod(r, 0.04);
}

float terrain(vec3 p)
{
	return fbm(p * 10.) / 5. + fbm(p + SEED) - (1. / 5.);
}

vec3 waterColor(float h)
{
	return mix(vec3(0, .29, 0.85), vec3(0, 0, .25), h);
}

vec3 terrainColor(float h)
{
//	h *= 1.2;
	return h < .5 ?
        mix(vec3(1.), vec3(.41, .54, .09), h * 2.) :
		mix(vec3(.41, .54, .0), vec3(.91, .91, .49), (h - .5) * 2.);
}

vec3 surfaceColor(float height, float longitude) {
    if (height < (1.-WATER_HEIGHT))
        return terrainColor(1.0 - abs(longitude + height + WATER_HEIGHT - 1.0));
    else
        return waterColor(height / WATER_HEIGHT);
}

mat3 rm(vec3 axis, float angle)
{
	axis = normalize(axis);
	float s = sin(angle);
	float c = cos(angle);
	float oc = 1.0 - c;

	return mat3(oc * axis.x * axis.x + c, oc * axis.x * axis.y - axis.z * s, oc * axis.z * axis.x + axis.y * s,
		oc * axis.x * axis.y + axis.z * s, oc * axis.y * axis.y + c, oc * axis.y * axis.z - axis.x * s,
		oc * axis.z * axis.x - axis.y * s, oc * axis.y * axis.z + axis.x * s, oc * axis.z * axis.z + c);
}

vec3 render(vec3 ro, vec3 rd)
{
	mat3 r = rm(vec3(0, 1, 0), iTime / 10.);
    vec2 d = ray_vs_sphere(ro, rd, R_INNER);
	vec3 atmosphere = scatter(ro, rd, d);
    
    if (d.x < MAX - 1.0)
	{
		vec3 hit = normalize(d.x * rd + ro) * r;
		float h = (fbm(hit * 10.0) / 5.0 + fbm(hit + SEED)) - 0.2;
		return surfaceColor(h, hit.y) * length(atmosphere * 1.5) * (atmosphere + 0.75);
	}
    
    return atmosphere;
}

vec3 getRay(vec3 pos, vec3 dir, vec3 up, vec2 fragCoord)
{
	vec2 xy = fragCoord.xy / iResolution.xy - vec2(0.5);
	xy.y *= -iResolution.y / iResolution.x;

	vec3 eyed = normalize(dir);
	vec3 ud = normalize(cross(vec3(0.0, -1.0, 0.0), eyed));
	vec3 vd = normalize(cross(eyed, ud));

	float f = FOV * length(xy);
	return normalize(normalize(xy.x * ud + xy.y * vd) + (1.0 / tan(f)) * eyed);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
	float a = iMouse.x / iResolution.x * 10.;
	float h = iMouse.y / iResolution.y - 0.5;

	vec3 pos = vec3(3.5 * cos(a), h * 5., 3.5 * sin(a));
	vec3 dir = -normalize(pos);
	vec3 up = vec3(0, 1, 0);

	vec3 color = render(pos, getRay(pos, dir, up, fragCoord));

	fragColor = vec4(color, 1);
}
