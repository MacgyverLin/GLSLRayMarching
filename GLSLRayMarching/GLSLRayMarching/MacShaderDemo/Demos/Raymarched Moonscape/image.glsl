// Processed by 'GLSL Shader Shrinker'
// (https://github.com/deanthecoder/GLSLShaderShrinker)

float hash(vec2 p) { return fract(sin(dot(p, vec2(123.45, 875.43))) * 5432.3); }

float noise(vec2 p) {
	vec2 i = floor(p),
	     f = fract(p);
	float a = hash(i),
	      b = hash(i + vec2(1, 0)),
	      c = hash(i + vec2(0, 1)),
	      d = hash(i + vec2(1));
	f = f * f * (3. - 2. * f);
	return mix(a, b, f.x) + (c - a) * f.y * (1. - f.x) + (d - b) * f.x * f.y;
}

float fbm(vec2 p) {
	float f = 0.;
	f += .5 * noise(p * 1.1);
	f += .22 * noise(p * 2.3);
	f += .155 * noise(p * 3.9);
	f += .0625 * noise(p * 8.4);
	f += .03125 * noise(p * 15.);
	return f;
}

float smoothBounds(float a, float b, float v) {
	float midPoint = a + (b - a) * .5;
	return smoothstep(a, midPoint, v) * smoothstep(b, midPoint, v);
}

float stars(vec2 uv) { return smoothBounds(.195, .2, fbm(uv * 1e2)); }

float rfbm(vec2 xz) { return abs(2. * fbm(xz) - 1.); }

float sdEarth(vec3 p) { return length(p - vec3(0, -.8, 2)) - .7; }

float sdTerrain(vec3 p) {
	if (p.y > 0.) return 1e10;
	float h = rfbm(p.xz * .2);
	p.xz += vec2(1);
	h += .5 * rfbm(p.xz * .8);
	h += .25 * rfbm(p.xz * 2.);
	h += .03 * rfbm(p.xz * 16.1);
	h *= .7 * fbm(p.xz);
	h -= .7;
	return abs(p.y - h) * .6;
}

vec2 map(vec3 p) {
	float d1 = sdTerrain(p),
	      d2 = sdEarth(p);
	return d1 < d2 ? vec2(d1, 1) : vec2(d2, 2);
}

vec3 calcNormal(vec3 p) {
	const vec2 e = vec2(1, -1) * 29e-5;
	return normalize(e.xyy * map(p + e.xyy).x + e.yyx * map(p + e.yyx).x + e.yxy * map(p + e.yxy).x + e.xxx * map(p + e.xxx).x);
}

float calcShadow(vec3 origin, vec3 lightOrigin) {
	float s = 1.,
	      d = .1;
	vec3 rayDir = normalize(lightOrigin - origin);
	while (d < 10. && s > 0.) {
		float distToObj = map(origin + rayDir * d).x;
		s = min(s, distToObj / d);
		d += clamp(distToObj, .2, 1.);
	}
	return smoothstep(0., 1., s);
}

void mainImage(out vec4 fragColor, vec2 fragCoord) {
	vec2 uv = (fragCoord - .5 * iResolution.xy) / iResolution.y;
	vec3 p, col,
	     rd = normalize(vec3(uv, 1));
	float d = .01,
	      id = 0.;
	for (float steps = 0.; steps < 80.; steps++) {
		p = vec3(0, 0, -3) + rd * d;
		vec2 h = map(p);
		if (abs(h.x) < .004 * d) {
			id = h.y;
			break;
		}

		if (d > 5.) break;
		d += h.x;
	}

	if (id < .5) col = vec3(stars(uv));
	else {
		vec3 sunPos = vec3(8. - 16. * iMouse.x / iResolution.x, 6. - cos(iTime * .2), -1. - iMouse.y / 18.),
		     n = calcNormal(p),
		     mainLight = vec3(1.82, 1.8, 1.78) * dot(n, normalize(sunPos - p));
		if (id > 1.5) {
			col = mix(mix(mix(vec3(.05, .05, .8), vec3(.05, .25, .05), smoothstep(.4, .52, fbm(n.xy * 3.1 + vec2(iTime * .05, 0)))), vec3(1), smoothstep(.8, .95, n.y) * smoothstep(.1, .8, fbm(n.xz * 10. + vec2(iTime * .1, 0)))), vec3(.3, .5, .95), smoothstep(-.5, 0., n.z));
			col *= mainLight;
		}
		else if (id > .5) col = vec3(.5) * mainLight * pow(calcShadow(p, sunPos), 2.);
	}

	fragColor = vec4(pow(col, vec3(.4545)), 1);
}