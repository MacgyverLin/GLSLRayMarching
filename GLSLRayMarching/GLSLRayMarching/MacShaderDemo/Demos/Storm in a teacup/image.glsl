// Processed by 'GLSL Shader Shrinker' (Shrunk by 501 characters)
// (https://github.com/deanthecoder/GLSLShaderShrinker)

// Storm in a teacup
//
// This started with me trying to work out how to make a cloud,
// and then kinda developed from there...
// The sea and plane are deliberately voxel-y, partly
// to keep the frame rate up and partly coz I just like it. :)
//
// Thanks to Evvvvil, Flopine, Nusan, BigWings, Iq, Shane
// and a bunch of others for sharing their knowledge!

// License: Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License

float time, flash, glow;

struct MarchData {
	float d;
	vec3 mat; // RGB
	bool isCloud;
};

// Thanks Shane - https://www.shadertoy.com/view/lstGRB
float noise(vec3 p) {
	const vec3 s = vec3(7, 157, 113);
	vec3 ip = floor(p);
	vec4 h = vec4(0, s.yz, s.y + s.z) + dot(ip, s);
	p -= ip;
	h = mix(fract(sin(h) * 43758.545), fract(sin(h + s.x) * 43758.545), p.x);
	h.xy = mix(h.xz, h.yw, p.y);
	return mix(h.x, h.y, p.z);
}

float noise(float n) {
	float flr = floor(n);
	vec2 rndRange = fract(sin(vec2(flr, flr + 1.) * 12.9898) * 43758.545);
	return mix(rndRange.x, rndRange.y, fract(n));
}

float smin(float a, float b, float k) {
	float h = clamp(.5 + .5 * (b - a) / k, 0., 1.);
	return mix(b, a, h) - k * h * (1. - h);
}

MarchData minResult(MarchData a, MarchData b) {
	if (a.d < b.d) return a;
	return b;
}

mat2 rot(float a) {
	float c = cos(a),
	      s = sin(a);
	return mat2(c, s, -s, c);
}

float sdBox(vec3 p, vec3 b) {
	vec3 q = abs(p) - b;
	return length(max(q, 0.)) + min(max(q.x, max(q.y, q.z)), 0.);
}

float sdCappedCylinder(vec3 p, float h, float r) {
	vec2 d = abs(vec2(length(p.xy), p.z)) - vec2(h, r);
	return min(max(d.x, d.y), 0.) + length(max(d, 0.));
}

MarchData sdSea(vec3 p, const float bowlInner) {
	MarchData result;
	result.isCloud = false;
	mat2 r = rot(23.23);
	vec2 af = vec2(1);
	float t = time * .4,
	      wave = noise(p.x);
	for (int i = 0; i < 8; i++) {
		wave += (1. - abs(sin((p.x + t) * af.y))) * af.x;
		p.xz *= r;
		af *= vec2(.5, 1.64);
	}

	result.d = max(p.y + 1. - wave * .3, bowlInner);
	result.mat = vec3(.03, .09, .12) * wave;
	return result;
}

MarchData sdCup(vec3 p) {
	MarchData result;
	result.mat = vec3(1);
	result.isCloud = false;
	float bowlInner = length(p) + p.y * .1 - 2.;
	result.d = smin(max(abs(bowlInner) - .06, p.y), max(max(abs(length(p.xy - vec2(2, p.x * p.x * .1 - 1.1)) - .5) - .06, abs(p.z) - .06), -bowlInner), .1);
	return minResult(result, sdSea(p, bowlInner));
}

float sdSaucer(vec3 p) {
	float l = length(p.xz);
	p.y += 1.9 - l * (.1 + .02 * smoothstep(0., .1, l - 2.05));
	return sdCappedCylinder(p.xzy, 2.6, .01) - .02;
}

vec3 getRayDir(vec3 ro, vec2 uv) {
	vec3 forward = normalize(-ro),
	     right = normalize(cross(vec3(0, 1, 0), forward));
	return normalize(forward + right * uv.x + cross(forward, right) * uv.y);
}

float sdCloud(vec3 p) {
	float n = abs(smoothstep(0., 1., (noise(p * 4.) + noise(p * 9.292 - vec3(0, time, 0)) * .4) * .3) - .4) + .55;
	p.y -= 1.3;
	return min(length(p + vec3(.4, 0, 0)), length(p - vec3(.4, 0, 0))) - n;
}

MarchData sdPlane(vec3 p) {
	MarchData result;
	result.mat = vec3(.29, .33, .13);
	result.isCloud = false;

	// Scale, position, rotate.
	p *= 1.5;
	p.xz *= rot(time * .6);
	p.xy -= vec2(1.5, .4);
	p.xy *= rot(sin(time * 3.) * .1);

	// Fuselage.
	vec3 ppp,
	     pp = p + vec3(0, 0, .15);
	result.d = sdBox(pp, vec2(.04 + pp.z * .05, .3).xxy);

	// Prop.
	ppp = pp;
	ppp.z -= .33;
	ppp.xy *= rot(time * 8.);
	float d = sdBox(ppp, vec3(.09, .01 * sin(length(p.xy) * 34.), .005));

	// Tail.
	pp.yz += vec2(-.05, .26);
	result.d = min(min(result.d, sdBox(pp, vec3(.01, .06 * cos(pp.z * 25.6), .03))), sdBox(pp + vec3(0, .05, 0), vec3(.15 * cos(pp.z * 12.), .01, .03)));

	// Wings
	p.y = abs(p.y) - .08;
	result.d = min(result.d, sdBox(p, vec3(.3, .01, .1)));
	if (d < result.d) {
		result.d = d;
		result.mat = vec3(.05);
	}

	result.d = (result.d - .005) * .4;
	return result;
}

// Map the scene using SDF functions.
bool hideCloud;
MarchData map(vec3 p) {
	MarchData result = sdCup(p);
	result.d = min(result.d, sdSaucer(p));
	result = minResult(result, sdPlane(p));
	float d,
	      gnd = length(p.y + 1.7);
	if (flash > 0.) {
		d = max(length(p.xz * rot(fract(time) * 3.141) + vec2(noise(p.y * 6.5) * .08) - vec2(.5, 0)), p.y - .7);
		glow += .001 / (.01 + 2. * d * d);
		if (d < result.d) result.d = d;
	}

	if (gnd < result.d) {
		result.d = gnd;
		result.mat = vec3(.2);
	}

	if (!hideCloud) {
		d = sdCloud(p);
		if (d < result.d) {
			result.d = d * .7;
			result.isCloud = true;
		}
	}

	return result;
}

vec3 calcNormal(vec3 p, float t) {
	vec2 e = vec2(.5773, -.5773) * t * 1e-4;
	return normalize(e.xyy * map(p + e.xyy).d + e.yyx * map(p + e.yyx).d + e.yxy * map(p + e.yxy).d + e.xxx * map(p + e.xxx).d);
}

vec3 cloudNormal(vec3 p) {
	const vec2 e = vec2(.5773, -.5773);
	return normalize(e.xyy * sdCloud(p + e.xyy) + e.yyx * sdCloud(p + e.yyx) + e.yxy * sdCloud(p + e.yxy) + e.xxx * sdCloud(p + e.xxx));
}

float calcShadow(vec3 p, vec3 lightPos) {
	// Thanks iq.
	vec3 rd = normalize(lightPos - p);
	float res = 1.,
	      t = .1;
	for (float i = 0.; i < 32.; i++) {
		float h = map(p + rd * t).d;
		res = min(res, 10. * h / t);
		t += h;
		if (res < .001 || t > 3.) break;
	}

	return clamp(res, 0., 1.);
}

// Quick ambient occlusion.
float ao(vec3 p, vec3 n, float h) { return map(p + h * n).d / h; }

float cloudAo(vec3 p, vec3 n, float h) { return sdCloud(p + h * n) / h; }

vec3 vignette(vec3 col, vec2 fragCoord) {
	vec2 q = fragCoord.xy / iResolution.xy;
	col *= .5 + .5 * pow(16. * q.x * q.y * (1. - q.x) * (1. - q.y), .4);
	return col;
}

vec3 applyLighting(vec3 p, vec3 rd, float d, MarchData data) {
	vec3 sunDir = normalize(vec3(6, 10, -4) - p),
	     n = calcNormal(p, d);
	return data.mat * (max(0., dot(sunDir, n)) * mix(.4, 1., calcShadow(p, vec3(6, 10, -4))) + max(0., dot(sunDir * vec3(-1, 0, -1), n)) * .3) * dot(vec3(ao(p, n, .2), ao(p, n, .5), ao(p, n, 2.)), vec3(.2, .3, .5)) * vec3(2, 1.6, 1.4) * exp(-length(p) * .14);
}

vec3 cloudLighting(vec3 p, float den) {
	vec3 n = cloudNormal(p),
	     col = vec3(2, 1.6, 1.4) * (1. + flash);
	return min(.75, den) * max(.1, dot(normalize(vec3(6, 10, -4) - p), n)) * cloudAo(p, n, 1.) * col;
}

vec3 getSceneColor(vec3 ro, vec3 rd) {
	// Raymarch.
	MarchData h;
	float d = .01,
	      den = 0.,
	      maxCloudD = 0.;
	hideCloud = false;
	vec3 p, cloudP;
	for (float steps = 0.; steps < 120.; steps++) {
		p = ro + rd * d;
		h = map(p);
		if (h.d < .0015) {
			if (!h.isCloud) break;
			hideCloud = true;
			cloudP = p;
			maxCloudD = 20. - sdCloud(p + rd * 20.);
		}

		if (d > 55.) break; // Distance limit reached - Stop.
		d += h.d; // No hit, so keep marching.
	}

	if (hideCloud) {
		for (float i = 0.; i < 20.; i++)
			den += clamp(-sdCloud(cloudP + rd * maxCloudD * i / 20.) * .2, 0., 1.);
	}

	hideCloud = false;
	return applyLighting(p, rd, d, h) + cloudLighting(cloudP, den) + vec3(glow) + flash * .05;
}

void mainImage(out vec4 fragColor, vec2 fragCoord) {
	time = mod(iTime, 120.);
	flash = step(.55, pow(noise(time * 8.), 5.));
    
	vec3 col = vec3(0),
	     ro = vec3(0, 2, -5);
	ro.xz *= rot(-.6);
    
	vec2 uv = (fragCoord - .5 * iResolution.xy) / iResolution.y;
	col += getSceneColor(ro, getRayDir(ro, uv));

	// Output to screen.
	fragColor = vec4(vignette(pow(col, vec3(.4545)), fragCoord), 1);
}