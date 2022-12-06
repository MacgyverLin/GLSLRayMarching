// License: CC BY 4.0

#define ANIMATE_CLOUDS 0

const float R0 = 6360e3;
const float Ra = 6380e3;
const int steps = 128;
const int stepss = 8;
const float g = .76;
const float g2 = g * g;
const float Hr = 8e3;
const float Hm = 1.2e3;
const float I = 10.;

#define t iTime

vec3 C = vec3(0., -R0, 0.);
vec3 bM = vec3(21e-6);
vec3 bR = vec3(5.8e-6, 13.5e-6, 33.1e-6);
vec3 Ds = normalize(vec3(0., .09, -1.));

float noise(in vec2 v) { return textureLod(iChannel0, (v+.5)/256., 0.).r; }

// by iq
float noise(in vec3 v) {
	vec3 p = floor(v);
    vec3 f = fract(v);
	//f = f*f*(3.-2.*f);
	
	vec2 uv = (p.xy+vec2(37.,17.)*p.z) + f.xy;
	vec2 rg = textureLod( iChannel0, (uv+.5)/256., 0.).yx;
	return mix(rg.x, rg.y, f.z);
}

float fnoise(in vec3 v) {
#if ANIMATE_CLOUDS
	return
		.55 * noise(v) +
		.225 * noise(v*2. + t *.4) +
		.125 * noise(v*3.99) +
		.0625 * noise(v*8.9);
#else
	return
		.55 * noise(v) +
		.225 * noise(v*2.) +
		.125 * noise(v*3.99) +
		.0625 * noise(v*8.9);
#endif
}

float cloud(vec3 p) {
	float cld = fnoise(p*2e-4);
	cld = smoothstep(.4+.04, .6+.04, cld);
	cld *= cld * 40.;
	return cld;
}

void densities(in vec3 pos, out float rayleigh, out float mie) {
	float h = length(pos - C) - R0;
	rayleigh =  exp(-h/Hr);

	float cld = 0.;
	if (5e3 < h && h < 10e3) {
		cld = cloud(pos+vec3(23175.7, 0.,-t*3e3));
		cld *= sin(3.1415*(h-5e3)/5e3);
	}
	mie = exp(-h/Hm) + cld;
}

float escape(in vec3 p, in vec3 d, in float R) {
	vec3 v = p - C;
	float b = dot(v, d);
	float c = dot(v, v) - R*R;
	float det2 = b * b - c;
	if (det2 < 0.) return -1.;
	float det = sqrt(det2);
	float t1 = -b - det, t2 = -b + det;
	return (t1 >= 0.) ? t1 : t2;
}

// this can be explained: http://www.scratchapixel.com/lessons/3d-advanced-lessons/simulating-the-colors-of-the-sky/atmospheric-scattering/
vec3 scatter(vec3 o, vec3 d) {
	float L = escape(o, d, Ra);	
	float mu = dot(d, Ds);
	float opmu2 = 1. + mu*mu;
	float phaseR = .0596831 * opmu2;
	float phaseM = .1193662 * (1. - g2) * opmu2 / ((2. + g2) * pow(1. + g2 - 2.*g*mu, 1.5));
	
	float depthR = 0., depthM = 0.;
	vec3 R = vec3(0.), M = vec3(0.);
	
	float dl = L / float(steps);
	for (int i = 0; i < steps; ++i) {
		float l = float(i) * dl;
		vec3 p = o + d * l;

		float dR, dM;
		densities(p, dR, dM);
		dR *= dl; dM *= dl;
		depthR += dR;
		depthM += dM;

		float Ls = escape(p, Ds, Ra);
		if (Ls > 0.) {
			float dls = Ls / float(stepss);
			float depthRs = 0., depthMs = 0.;
			for (int j = 0; j < stepss; ++j) {
				float ls = float(j) * dls;
				vec3 ps = p + Ds * ls;
				float dRs, dMs;
				densities(ps, dRs, dMs);
				depthRs += dRs * dls;
				depthMs += dMs * dls;
			}
			
			vec3 A = exp(-(bR * (depthRs + depthR) + bM * (depthMs + depthM)));
			R += A * dR;
			M += A * dM;
		} else {
			return vec3(0.);
		}
	}
	
	return I * (R * bR * phaseR + M * bM * phaseM);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
	if (iMouse.z > 0.) {
		float ph = 3.3 * (1. - iMouse.y / iResolution.y);
		Ds = normalize(vec3(iMouse.x / iResolution.x - .5, sin(ph), cos(ph)));
	}
	
	vec2 uv = fragCoord.xy / iResolution.xy * 2. - 1.;
	uv.x *= iResolution.x / iResolution.y;
	
	vec3 O = vec3(uv * .1, 0.) + vec3(0., 25e2, 0.);
	vec3 D = normalize(vec3(uv, -2.));
	
	float att = 1.;
	if (D.y < -.02) {
		float L = - O.y / D.y;
		O = O + D * L;
		
		D.y = -D.y;
		D = normalize(D+vec3(0.,.003*sin(t+6.2831*noise(O.xz*.8+vec2(0.,-t*3e3))),0.));
		att = .6;
	}
	
	vec3 color = att * scatter(O, D);

	float env = pow(1. - smoothstep(.5, iResolution.x / iResolution.y, length(uv*.8)), .3);
	fragColor = vec4(env * pow(color, vec3(.4)), 1.);
}