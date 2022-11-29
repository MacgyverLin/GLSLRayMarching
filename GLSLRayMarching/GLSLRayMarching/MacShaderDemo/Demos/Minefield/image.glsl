// Feature Options - (Comment out to disable)
#define PARTICLES // Slow, disable for decent speedup

// Description : Array and textureless GLSL 2D/3D/4D simplex
// noise functions.
// Author : Ian McEwan, Ashima Arts.
// License : Copyright (C) 2011 Ashima Arts. All rights reserved.
// Distributed under the MIT License. See LICENSE file.
// https://github.com/ashima/webgl-noise

vec3 mod289(vec3 x) {
  return x - floor(x * (1.0 / 289.0)) * 289.0;
}

vec4 mod289(vec4 x) {
  return x - floor(x * (1.0 / 289.0)) * 289.0;
}

vec4 permute(vec4 x) {
     return mod289(((x*34.0)+1.0)*x);
}

vec4 taylorInvSqrt(vec4 r) {
  return 1.79284291400159 - 0.85373472095314 * r;
}

float snoise(vec3 v) {
  const vec2 C = vec2(1.0/6.0, 1.0/3.0) ;
  const vec4 D = vec4(0.0, 0.5, 1.0, 2.0);

// First corner
  vec3 i = floor(v + dot(v, C.yyy) );
  vec3 x0 = v - i + dot(i, C.xxx) ;

// Other corners
  vec3 g = step(x0.yzx, x0.xyz);
  vec3 l = 1.0 - g;
  vec3 i1 = min( g.xyz, l.zxy );
  vec3 i2 = max( g.xyz, l.zxy );

  // x0 = x0 - 0.0 + 0.0 * C.xxx;
  // x1 = x0 - i1 + 1.0 * C.xxx;
  // x2 = x0 - i2 + 2.0 * C.xxx;
  // x3 = x0 - 1.0 + 3.0 * C.xxx;
  vec3 x1 = x0 - i1 + C.xxx;
  vec3 x2 = x0 - i2 + C.yyy; // 2.0*C.x = 1/3 = C.y
  vec3 x3 = x0 - D.yyy; // -1.0+3.0*C.x = -0.5 = -D.y

// Permutations
  i = mod289(i);
  vec4 p = permute( permute( permute(
             i.z + vec4(0.0, i1.z, i2.z, 1.0 ))
           + i.y + vec4(0.0, i1.y, i2.y, 1.0 ))
           + i.x + vec4(0.0, i1.x, i2.x, 1.0 ));

// Gradients: 7x7 points over a square, mapped onto an octahedron.
// The ring size 17*17 = 289 is close to a multiple of 49 (49*6 = 294)
  float n_ = 0.142857142857; // 1.0/7.0
  vec3 ns = n_ * D.wyz - D.xzx;

  vec4 j = p - 49.0 * floor(p * ns.z * ns.z); // mod(p,7*7)

  vec4 x_ = floor(j * ns.z);
  vec4 y_ = floor(j - 7.0 * x_ ); // mod(j,N)

  vec4 x = x_ *ns.x + ns.yyyy;
  vec4 y = y_ *ns.x + ns.yyyy;
  vec4 h = 1.0 - abs(x) - abs(y);

  vec4 b0 = vec4( x.xy, y.xy );
  vec4 b1 = vec4( x.zw, y.zw );

  //vec4 s0 = vec4(lessThan(b0,0.0))*2.0 - 1.0;
  //vec4 s1 = vec4(lessThan(b1,0.0))*2.0 - 1.0;
  vec4 s0 = floor(b0)*2.0 + 1.0;
  vec4 s1 = floor(b1)*2.0 + 1.0;
  vec4 sh = -step(h, vec4(0.0));

  vec4 a0 = b0.xzyw + s0.xzyw*sh.xxyy ;
  vec4 a1 = b1.xzyw + s1.xzyw*sh.zzww ;

  vec3 p0 = vec3(a0.xy,h.x);
  vec3 p1 = vec3(a0.zw,h.y);
  vec3 p2 = vec3(a1.xy,h.z);
  vec3 p3 = vec3(a1.zw,h.w);

//Normalise gradients
  vec4 norm = taylorInvSqrt(vec4(dot(p0,p0), dot(p1,p1), dot(p2, p2), dot(p3,p3)));
  p0 *= norm.x;
  p1 *= norm.y;
  p2 *= norm.z;
  p3 *= norm.w;

// Mix final noise value
  vec4 m = max(0.6 - vec4(dot(x0,x0), dot(x1,x1), dot(x2,x2), dot(x3,x3)), 0.0);
  m = m * m;
  return 42.0 * dot( m*m, vec4( dot(p0,x0), dot(p1,x1),
                                dot(p2,x2), dot(p3,x3) ) );
}

//
//
//
//

float sphere(vec3 pos, float r)
{
	return length(pos) - r;
}

float cylinder(vec3 p, float c)
{
	return length(p.xz) - c;
}

float repeat(float pos, float c)
{
	return mod(pos, c) - c * 0.5;
}

vec2 rotate(vec2 pos, float angle)
{
	float c = cos(angle), s = sin(angle);
	return vec2(pos.x*c + pos.y*s, pos.y*c - pos.x*s);
}

float spikes(vec3 pos)
{
	vec3 s1 = vec3(pos.xy, pos.z);
	vec3 s2 = vec3(rotate(pos.xy, 1.047), pos.z);
	vec3 s3 = vec3(rotate(pos.xy, 2.094), pos.z);
	vec3 s4 = vec3(rotate(s2.yz, -1.047), s2.x).zxy;
	vec3 s5 = vec3(rotate(s3.yz,  1.047), s3.x).zxy;
	vec3 s6 = vec3(rotate(pos.yz, 1.047), pos.x).zxy;
	
	float ss = 0.06;
	
	float c = min(
		min(
			min(cylinder(s1, ss), cylinder(s2, ss)),
			min(cylinder(s3, ss), cylinder(s4, ss))
		),
		min(cylinder(s5, ss), cylinder(s6, ss))
	);
	
	float s = sphere(pos, 1.3);
	
	return min(max(c, s),max(c-0.1, s+0.2));
}

float chains(vec3 pos, float instance)
{
	float t = iTime * 0.4 + instance * 10.0;
	float c = sqrt(1.0 - clamp(pos.y + 3.6, 0.0, 3.0) * 0.33);
	vec3 cp = pos + vec3(sin(pos.y*1.1+t) * c * 0.3, cos(pos.y*0.9) * 0.3, 0.0);
	return max(cylinder(cp, 0.02 * pow(sin(pos.y*25.0),2.0) + 0.02), pos.y);
}

float map(vec3 pos)
{
	float instance = floor(pos.z / 6.0 + 0.5);
	
	if (pos.x > 0.0) pos.z += 3.0; // Left vs Right
	pos.x -= 3.0 * sign(pos.x);
	
	// Repeat into distance
	vec3 rp = vec3(
		pos.x,
		pos.y,
		repeat(pos.z, 6.0)-2.0
	);
	
	// Make different heights
	rp.x += sin(instance * 17.0 + iTime * 0.9) * 0.05;
	rp.y += sin(instance * 10.0) * 0.4 + pow(cos(instance * 17.0 + iTime), 2.0) * 0.08;
	
	float minesSpikes = spikes(vec3(rotate(rp.xy, sin(instance)*0.2), rp.z));
	float minesMain = sphere(rp, 1.0);
	
	return min(min(chains(rp, instance), minesMain), minesSpikes);
}

vec3 normal(vec3 pos)
{
	vec2 eps = vec2(0.001, 0.0);
	float dx = map(pos+eps.xyy)-map(pos-eps.xyy);
	float dy = map(pos+eps.yxy)-map(pos-eps.yxy);
	float dz = map(pos+eps.yyx)-map(pos-eps.yyx);
	return normalize(vec3(dx, dy, dz));
}

vec3 trace(vec3 rayPos, vec3 rayDir, vec2 pixel)
{
	vec3 dustCol = vec3(0.2, 0.18, 0.15);
	vec3 fogCol = vec3(0.05, 0.1, 0.15) * pow(rayDir.z + 0.04, 8.0);
	vec3 lightPos = rayPos-vec3(0.0, 1.0, 0.0);
	
	float fog = 0.0;
	float t = 0.0;
	
	float spec = 0.0;
	vec4 col = vec4(0.0);
	vec2 uv = vec2(0.0);
	
	for (int i = 0; i < 40; i++)
	{
		vec3 pos = rayPos+rayDir*t;
		float h = map(pos);
		
		if (h < 0.005)
		{
			vec3 v = normalize(pos-rayPos); // View
			vec3 l = normalize(pos-lightPos); // Light
			vec3 n = normal(pos);
			float strength = pow(l.z + 0.08, 32.0);
			float d = max(-dot(n, l) * strength, 0.0);
				
			spec = pow(max(-dot(reflect(l, n), v), 0.0), 10.0) * strength;
			uv = n.xy;
			col = vec4(vec3(0.4) * d, max(1.0 - fog, 0.0));
			break;
		}
		
		if (fog > 0.995) 
		{
			t = 1e5;
			break;
		}
		
		t += h * 0.9;
		fog += h * 0.055 + 0.005;
	}
	
	float particle = 0.0;
	float scatter = 0.0;
	
	#ifdef PARTICLES
	float wt = snoise(vec3(pixel, iTime)) * 0.05 + 0.1;
	for (int i = 0; i < 50; i++)
	{
		vec3 pos = rayPos+rayDir*wt;
			
		vec3 lightDiff = lightPos-pos;
		float lightDist = length(lightDiff);
		float n = max(snoise(pos*vec3(5.0, 5.0, 5.0)), 0.0);
		
		float lightStrength = smoothstep(-0.7, -0.9, normalize(lightDiff).z);
		if (lightStrength > 0.0) scatter += 1.0 / lightDist * lightDist * 0.02 * lightStrength;
		particle += pow(smoothstep(0.85, 0.95, n), 32.0) * 0.5 * lightStrength;
		
		wt += 0.1;
		if (wt >= t) break;
	}
	#endif
	
	vec3 tex = texture(iChannel0, uv).rgb;
	return mix(fogCol, col.rgb*tex+vec3(spec*(smoothstep(0.43, 0.52, tex.b)+0.15)), col.a) + dustCol*particle;
}

vec3 camera(vec2 px)
{
	vec2 rd = (px / iResolution.yy - vec2(iResolution.x/iResolution.y*0.5-0.5, 0.0)) * 2.0 - 1.0;
	vec3 rayDir = normalize(vec3(rd.x*0.5, rd.y*0.5, 1.0));
	
	float x = sin(iTime*1.0) * 0.1 + 0.1;
	float y = cos(iTime*1.0) * 0.05 - 1.1;
	vec3 rayPos = vec3(x, y, iTime);
	
	return trace(rayPos, rayDir, px);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	fragColor = vec4(pow(camera(fragCoord.xy), vec3(0.4545)), 1.0);
}