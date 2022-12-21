// 'Ready Player One' dean_the_coder (Twitter: @deanthecoder)
// https://www.shadertoy.com/view/sllSDS (YouTube: https://youtu.be/jUx2yGj3pGo)
//
// "It's not about winning, it's about playing."
//
// Processed by 'GLSL Shader Shrinker'
// (https://github.com/deanthecoder/GLSLShaderShrinker)
//
// After just finishing the Ready Player One book,
// and watching the film a couple of times, I was inspired
// to try to make a scene inspired by it.
//
// Hope you like it!
//
// Tricks to get the performance:
//
// A relatively straight-forward ray-marching scene, but to keep
// the performance up I've tried to avoid adding noise into the SDF
// as much as possible - The finer detail on the terrain is applied
// when calculating the material color.
//
// The Iron Giant only has one real arm and leg - I've used mirroring
// on the X axis to duplicate the other side.
// The arm and leg SDF is generated from the same function, parameterized
// to slightly adjust appearance.
//
// Thanks to Evvvvil, Flopine, Nusan, BigWings, Iq, Shane,
// Blackle and a bunch of others for sharing their knowledge!

// License: Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License

#define Z0	min(iTime, 0.)
#define sat(x)	clamp(x, 0., 1.)
#define S(a, b, c) smoothstep(a, b, c)

float t, g;
struct Hit {
	float d;
	int id;
	vec3 uv;
};

#define HASH	p = fract(p * .1031); p *= p + 3.3456; return fract(p * (p + p));

vec4 h44(vec4 p) { HASH }

float n31(vec3 p) {
	const vec3 s = vec3(7, 157, 113);
	vec3 ip = floor(p);
	p = fract(p);
	p = p * p * (3. - 2. * p);
	vec4 h = vec4(0, s.yz, s.y + s.z) + dot(ip, s);
	h = mix(h44(h), h44(h + s.x), p.x);
	h.xy = mix(h.xz, h.yw, p.y);
	return mix(h.x, h.y, p.z);
}

float n21(vec2 p) { return n31(vec3(p, 1)); }

#define minH(a)	if (a.d < h.d) h = a

mat2 rot(float a) {
	float c = cos(a),
	      s = sin(a);
	return mat2(c, s, -s, c);
}

float hex(vec3 p, vec2 h) {
	const vec3 k = vec3(-.8660254, .5, .57735);
	p = abs(p);
	p.xy -= 2. * min(dot(k.xy, p.xy), 0.) * k.xy;
	vec2 d = vec2(length(p.xy - vec2(clamp(p.x, -k.z * h.x, k.z * h.x), h.x)) * sign(p.y - h.x), p.z - h.y);
	return min(max(d.x, d.y), 0.) + length(max(d, 0.));
}

float box(vec3 p, vec3 b) {
	vec3 q = abs(p) - b;
	return length(max(q, 0.)) + min(max(q.x, max(q.y, q.z)), 0.);
}

float cyl(vec3 p, vec2 hr) {
	vec2 d = abs(vec2(length(p.zy), p.x)) - hr;
	return min(max(d.x, d.y), 0.) + length(max(d, 0.));
}

float cap(vec3 p, float h, float r) {
	p.y -= clamp(p.y, 0., h);
	return length(p) - r;
}

float pod(vec3 p, float s) { return hex(p.xzy, vec2(.5 - (p.y > 0. ? p.y * .3 : 0.), 1) * s); }

float limb(inout vec3 p, float a1, float a2, float s) {
	float f, d,
	      oy = p.y;
	p.yz *= rot(a1);
	f = max(max(length(p.zy) - .45, p.x - p.y), -p.x);
	d = min(cyl(p, vec2(.5, .1)), f);
	f = p.y;
	p.y = abs(p.y + .7) - .7;
	d = min(d, length(p) - .35 + .1 * step(oy, -.3));
	p.y = f + 1.2;
	d = min(d, cap(p, 1., .2));
	p.y += .2;
	p.yz *= rot(a2);
	p.y += .1 + s;
	return min(d, pod(p, s));
}

vec3 rayDir(vec3 ro, vec3 lookAt, vec2 uv) {
	vec3 f = normalize(lookAt - ro),
	     r = normalize(cross(vec3(0, 1, 0), f));
	return normalize(f + r * uv.x + cross(f, r) * uv.y);
}

Hit map(vec3 p, bool shield) {
	vec3 pp, op,
	     rp = p;
	rp.xz *= rot(S(-1., 1., 1.5 * sin(cos(t * .5))) - .5);
	pp = rp;
	pp.z += .05;
	float bd, bdd, eye, mx, lxz, d,
	      chin = max(cap(pp, .6, .5), -pp.z - .45);
	chin = max(chin, rp.y - .6);
	pp.y -= 1.3 + pp.z * .2;
	pp.z += 1.1;
	bd = max(min(cap(rp, .7, .45), max(chin, -box(pp, vec3(1)))), .15 - rp.y + rp.z * .5);
	pp = rp;
	pp.x = abs(pp.x) - .2;
	pp.yz = rp.yz - vec2(.6, -.4);
	op = pp;
	bd = min(max(bd, .12 - length(pp)), cyl(rp - vec3(0, .7, 0), vec2(.5, .02)));
	eye = max(length(pp - vec3(0, 0, .1)) - .1, abs(pp.y) - S(1., .8, sin(t * .9)) + .05);
	g += 1e-4 / (.001 + eye * eye);
	Hit orb,
	    h = Hit(eye, 3, rp);
	mx = abs(p.x);
	pp.x = mx - .2;
	pp.yz = p.yz - vec2(.6, -.4);
	lxz = length(p.xz);
	d = .25 + .35 * step(p.y, -1.) * mix(.8, 1., sat(2. * abs(sin(p.y * 10.))));
	bdd = max(max(lxz - d, p.y - 1.), -p.y - 2.5);
	d = max(max(max(length(p.xz * vec2(.5, .9)) - (p.y + 6.2) * .12, p.y + 1.), -p.y - 2.), -box(pp + vec3(0, 2.4, 0), vec3(-pp.y * .18, .3, 1)));
	bd = min(bd, d);
	pp.x -= .4;
	pp.y += 1.4;
	pp.xz *= rot(.4);
	pp.xy *= rot(-.1);
	bd = min(bd, .9 * box(pp, vec3(.8, .5 + pp.z * .4, .25)));
	pp = p;
	pp.x = mx - 1.58;
	pp.xy *= rot(.1);
	pp.y += .8;
	bd = min(bd, limb(pp, -.2, .4, .7));
	d = box(pp + vec3(-.1, .9, 0), vec3(0, .2, .2));
	pp.xy *= rot(-.7 - sin(t) * .025);
	bd = min(bd, min(d, box(pp + vec3(-.8, 1, 0), vec3(0, .2, .2))) - .1 + .03 * abs(sin(pp.z * 20.75)));
	pp = p;
	pp.y += 3.2;
	pp.x = floor(mx * 5.) / 5.;
	minH(Hit(min(bdd, cap(pp, 1., .3)), 2, p));
	bd = min(bd, max(length(pp.zy) - .15, lxz - 1.));
	pp.x = mx - 1.;
	bd = min(bd, limb(pp, .2, -.2, 1.));
	pp.y += 1.4;
	bd = min(bd, max(max(hex(pp, vec2(.4, 1.2)), -pp.y), pp.z - .3));
	minH(Hit(bd, 1, p));
	op = p - vec3(10, -7, 30);
	orb = Hit(length(op) - 25., 0, op);
	g += .01 / (orb.d * orb.d * .1 + 1.);
	if (shield) minH(orb);
	pp = p - vec3(p.y + 74.875 + sin(p.y * 15.) * .05, n21(pp.xy * .5) * .2, -11.22);
	d = n21(pp.xz * .2);
	minH(Hit(pp.y - 2. * pow(d, 10.) + 7.1, 4, vec3(pp.xz, d)));
	op.xz *= rot(1.);
	p = op;
	op.xz = abs(op.xz) - 8.;
	pp = op;
	op.xz *= rot(op.y / 12.7348);
	d = 4. - 2.8 * pow(sin(.5 * pow(op.y * .39, .65) + .2), 1.8);
	d = min(max(box(op, vec3(d, 20, d)) - .1, box(pp, vec3(3.25, 20, 3.25))), box(p, vec3(12, .3, 12)) - .2);
	minH(Hit(d, 5, op));
	d = cyl(p.yxz, vec2(.7 - p.y * 0.12, 4.0)) - .5;
	minH(Hit(d, 2, op));
	p.y -= 5.;
	orb = Hit(length(p) - .7 + n31(p * 3. + t) * .4, 0, op);
	g += .01 / (orb.d * orb.d * .1 + 1.);
	minH(orb);
	return h;
}

vec3 N(vec3 p, float t) {
	float h = t * .4;
	vec3 n = vec3(0);
	for (int i = min(iFrame, 0); i < 4; i++) {
		vec3 e = .005773 * (2. * vec3(((i + 3) >> 1) & 1, (i >> 1) & 1, i & 1) - 1.);
		n += e * map(p + e * h, false).d;
	}

	return normalize(n);
}

float shadow(vec3 p, vec3 ld) {
	float i, h,
	      s = 1.,
	      t = .1;
	for (i = Z0; i < 20.; i++) {
		h = map(t * ld + p, false).d;
		s = min(s, 30. * h / t);
		t += h;
		if (s < .001 || t > 20.) break;
	}

	return sat(s);
}

vec3 vig(vec3 c, vec2 fc) {
	vec2 q = fc.xy / iResolution.xy;
	c *= .5 + .5 * pow(16. * q.x * q.y * (1. - q.x) * (1. - q.y), .4);
	return c;
}

vec3 lights(vec3 p, vec3 rd, float d, Hit h) {
	if (h.id == 3) return vec3(1);
	vec3 n, c,
	     ld = normalize(vec3(2, 20, 15) - p);
	if (h.id == 0) {
		n = normalize(h.uv);
		float ns,
		      f = sat(.2 + .8 * dot(ld * vec3(-1, 1, 1), n));
		vec2 k = (n.xy * rot(t * .1) - vec2(.3, .1)) * rot(t * -.3) + vec2(.1, .2);
		for (float i = 0.; i < 2.; i++) {
			float l = length(k + i * .1);
			f += (.4 + .2 * sin(l * 60. - t * 2.)) * (.003 + S(.5, 0., l) * S(0., .5, l));
			t += 32.;
		}

		ns = n31(n * 19. + vec3(0, 0, t * 2.)) * .7 + n31(n * 39. + vec3(0, t * 2., 0)) * .3;
		f *= .5 + .5 * S(.2, .8, ns);
		return vec3(1, 1.1, 1.7) * f;
	}

	n = N(p, d);
	if (h.id == 1) c = vec3(.2);
	else if (h.id == 2) c = vec3(.01);
	else if (h.id == 4) {
		c = vec3(.55);
		n.xz += 4. * (h.uv.z * .5 + n21(p.xz) * .125 - .5 + (n21(p.xz * 2.) + n21(p.zx * 32.1)) * .05);
		n = normalize(n);
	}
	else if (h.id == 5) c = mix(vec3(-.05), vec3(2. * pow(sat(sin(t + p.y * .2)), 10.), 0, 0), step(.8, fract(p.y)) * step(-7., p.y));

	float gg = g,
	      l1 = sat(.1 + .9 * dot(ld, n)) * (.2 + .8 * shadow(p, ld)),
	      l2 = sat(.1 + .9 * dot(ld * vec3(-1, 0, -1), n)) * .3 + pow(sat(dot(rd, reflect(ld, n))), 10.),
	      fre = 1. - S(.7, 1., 1. + dot(rd, n)) * .5;
	g = gg;
	return (l1 + l2) * fre * c * vec3(.4, .32, .3);
}

vec3 sky(vec3 rd) {
	float f = pow(1. - sat(rd.y / .5), 3.);
	return vec3(.16, .18, .24) * f + vec3((1. - f) * S(-.2, -.7, rd.x) * step(.96, n31(rd * 2e2)) * .5 * (.01 + .99 * n31(rd * 40. - t * .5)));
}

vec3 march(inout vec3 p, vec3 rd) {
	float i,
	      d = .01;
	bool addOrb = true;
	Hit h, orb;
	vec3 orbP, c;
	g = 0.;
	for (i = Z0; i < 128.; i++) {
		h = map(p, addOrb);
		if (abs(h.d) < .0015) {
			if (h.id == 0) {
				orb = h;
				orbP = p;
				addOrb = false;
			}
			else break;
		}

		d += h.d;
		if (d > 64.) break;
		p += h.d * rd;
	}

	c = (d < 64. ? lights(p, rd, d, h) : sky(rd)) + g;
	if (!addOrb) c += lights(orbP, rd, d, orb);
	return c;
}

#define R	iResolution

vec3 render(vec3 ro, vec3 rd) {
	t = mod(iTime, 30.);
	return pow(max(vec3(0), march(ro, rd)), vec3(.45)) * sat(iTime);
}

void mainVR(out vec4 fragColor, vec2 fc, vec3 ro, vec3 rd) {
	rd.xz *= rot(-1.57);
	fragColor = vec4(render(vec3(-2, -4, -5), rd), 0);
}

void mainImage(out vec4 fragColor, vec2 fc) {
	vec2 uv = (fc - .5 * R.xy) / R.y;
	if (abs(uv.y) > .4) {
		fragColor = vec4(0);
		return;
	}

	t = mod(iTime, 30.);
	float p = S(1., 15., t);
	vec3 lookAt = vec3(3, -3, 0) * p,
	     ro = mix(vec3(0, 0, -5), vec3(6, -5, -11), p);
	fragColor = vec4(vig(render(ro, rayDir(ro, lookAt, uv)), fc), 0);
}