#define EPS vec2(1e-3, 0.0)
#define ON vec2(1.0, 0.0)

vec2 t;
float time;

vec3 rotateX(float a, vec3 v)
{
	return vec3(v.x, cos(a) * v.y + sin(a) * v.z,
				cos(a) * v.z - sin(a) * v.y);
}


vec3 rotateY(float a, vec3 v)
{
	return vec3(cos(a) * v.x + sin(a) * v.z, v.y,
				cos(a) * v.z - sin(a) * v.x);
}

vec2 cubeInterval(vec3 ro, vec3 rd)
{
	vec3 slabs0 = (vec3(+1.0) - ro) / rd;
	vec3 slabs1 = (vec3(-1.0) - ro) / rd;
	
	vec3 mins = min(slabs0, slabs1);
	vec3 maxs = max(slabs0, slabs1);
	
	
	return vec2(max(max(mins.x, mins.y), mins.z),
				min(min(maxs.x, maxs.y), maxs.z));
}

float N(vec2 p)
{
	p = mod(p, vec2(101.0));
	return fract(sin(p.x * 41784.0) + sin(p.y * 32424.0));
}

float smN2(vec2 p)
{
	vec2 fp = floor(p);
	vec2 pf = smoothstep(0.0, 1.0, fract(p));
	
	return mix( mix(N(fp), N(fp + ON), pf.x), 
			   mix(N(fp + ON.yx), N(fp + ON.xx), pf.x), pf.y);
}

float smN3(vec3 p)
{
	vec2 o = vec2(111.0);
	return mix(smN2(p.xy + floor(p.z) * o),
			   smN2(p.xy + (floor(p.z) + 1.0) * o), smoothstep(0.0, 1.0, fract(p.z)));
}

float fbm3(vec3 p)
{
	float f = 0.0, x;
	for(int i = 1; i <= 7; ++i)
	{
		x = exp2(float(i));
		f += (smN3(p * x) - 0.5) / x;
	}
	return f;
}

#define fbm2(g) fbm3(vec3(g, 0.0))

float pulse(float e0, float e1, float x)
{
	return step(e0, x) - step(e1, x);
}

float beam(float x)
{
	x = clamp(x, 0.0, 1.0);
	return smoothstep(0.7, 1.0, pow(1.0 - 2.0 * abs(x - 0.5), 0.02));
}

float beamShadow(float x)
{
	x = clamp(x + 0.1, 0.0, 0.5);
	return smoothstep(0.7, 1.0, pow(1.0 - 2.0 * abs(x - 0.5), 0.1));
}

vec3 wood(vec2 p)
{
	p += vec2(200.0);
	p.x *= 1.2;
	p.y *= 0.6;
	return vec3(0.4, 0.25, 0.1) * (1.0 + fbm2(p));
}

vec3 crate(vec3 o, vec2 p)
{
	float shadow = mix(0.5, 1.0, smoothstep(0.0, 0.2, o.y + 1.0));
	
	float innercoord = fract(p.x * 3.0);
	vec2  outercoord = abs(p) * 3.0 - vec2(2.0);
	float acrosscoord = min(0.3, abs(dot(p, vec2(1.0)))) * 8.0 - 2.0;
	
	float inner = beam(innercoord);
	
	float outers0 = beamShadow(outercoord.y);
	float outers1 = beamShadow(outercoord.x);
	
	float outerm0 = beam(outercoord.y);
	float outerm1 = beam(outercoord.x);
	
	float acrosss0 = 1.0 - beamShadow(acrosscoord);
	float acrossm0 = 1.0 - beam(acrosscoord);
	
	o += vec3(1e-2);
	
	float stain = (smoothstep(0.95, 1.0, fbm3(mod(o, vec3(5.01)) * 0.5) + 0.8 + fbm3(mod(o, vec3(5.01)) * 4.0) * 0.4));
	
	float v = inner * (1.0 - acrosss0) + acrossm0;
	
	v = v * (1.0 - outers1) + outerm1;
	
	vec3 innercol = wood(vec2(p.x * 3.0, p.y)) * 0.76;
	vec3 acrosscol = wood(vec2(dot(p, vec2(1.0)) * 3.0, p.x * 2.0));
	vec3 outer0col = wood(p.yx * vec2(4.0, 1.4)) * vec3(1.0, 1.0, 0.9);
	vec3 outer1col = wood(p.xy * vec2(4.0, 1.4));
	
	vec3 col = mix(innercol, acrosscol, acrossm0);
	
	col = mix(col, outer1col, outerm1);
	col = mix(col, outer0col, outerm0);
	
	float f = mix(0.5, 1.0,
				  (1.0 - pow(abs(p.x), 30.0)) * (1.0 - pow(abs(p.y), 30.0)));
	
	return shadow * (v * (1.0 - outers0) + outerm0) * col * f * mix(vec3(1.0), vec3(0.8, 0.7, 0.5), stain);
}

bool gridSolidity1(vec3 rp)
{
	rp = floor(rp);
	return rp.y < (N(rp.xz * 2.0) * 10.0 - 20.0 / (1.0 + abs(rp.x)));
}


float groundSolidity(vec2 p)
{
	return gridSolidity1(vec3(p.x, -2.0, p.y)) ? 1.0 : 0.0;
}

float groundShadow(vec2 p)
{
	vec2 fp = floor(p);
	vec2 pf = smoothstep(0.0, 1.0, fract(p));
	
	return mix( mix(groundSolidity(fp), groundSolidity(fp + ON), pf.x), 
			   mix(groundSolidity(fp + ON.yx), groundSolidity(fp + ON.xx), pf.x), pf.y);
}

vec3 stone(vec2 p)
{
	p += vec2(200.0);
	p.x *= 1.2;
	p.y *= 0.6;
	return vec3(0.5, 0.5, 0.51) * smoothstep(0.0, 0.9, 1.0 + fbm2(p));
}

vec3 stoneFloor(vec3 o, vec2 p)
{
	float shadow = 1.0 - groundShadow(o.xz * 2.0 - vec2(0.5));
	return fbm2(p * 4.0) * 0.1 + shadow * mix(0.6, 0.65, smoothstep(0.0, 0.1, fbm2(o.xz * 2.0))) * vec3(0.7, 0.7, 0.8);
}

vec3 wall(vec3 o, vec2 p)
{
	float f = mix(0.5, 1.0,
				  (1.0 - pow(abs(p.x), 30.0)) * (1.0 - pow(abs(p.y), 30.0)));
	
	if(o.y < -0.99)
		return stoneFloor(o, p) * f * 0.7;
	
	float innercoord = fract(p.x * 7.0);
	vec2  outercoord = abs(p) * 3.0 - vec2(2.0);
	float acrosscoord = min(0.3, abs(dot(p, vec2(1.0)))) * 8.0 - 2.0;
	
	float inner = beam(innercoord);
	
	float outers0 = beamShadow(outercoord.y);
	
	float outerm0 = beam(outercoord.y);
	
	float g = pow(clamp((-o.y - 0.5) * 2.0, 0.0, 1.0), 2.0);
	
	float stain = (smoothstep(0.95, 1.0, fbm3(mod(o, vec3(5.0)) * 4.0) + 0.8 + g + fbm3(mod(o, vec3(5.0)) * 16.0) * 0.6));
	
	vec3 innercol = stone(vec2(p.x, p.y) * 2.0) * 0.76;
	vec3 outer0col = stone(p.yx * vec2(4.0, 1.4)) * vec3(1.0, 1.0, 0.9);
	
	vec3 col = mix(innercol, outer0col, outerm0);
	
	float fray = smoothstep(0.0, 0.5, stain) - smoothstep(0.5, 1.0, stain);
	
	return vec3(fray) * 0.2 * (1.0 - outerm0) + (inner * (1.0 - outers0) + outerm0) * col * f *
		mix(vec3(1.0), vec3(0.5, 0.4, 0.3), 0.5 * stain * (1.0 - outerm0));
}



vec2 cubeProject(vec3 v)
{
	vec3 av = abs(v);
	
	if(av.x > av.y && av.x > av.z)
		return v.yz / av.x;
	else if(av.y > av.x && av.y > av.z)
		return v.xz / av.y;
		else
			return v.xy / av.z;   
		}

bool gridSolidity0(vec3 rp)
{
	if(rp.x < 1.0 && rp.y < -2.0)
		return true;
		
	vec2 wc = fract(rp.xy * 0.4);
	
	float wires = pulse(-0.17, -0.1, 3.6 - sin(wc.x * 3.14159 * 2.0 + rp.z * 123.0) - wc.y * 4.0);
	
	wires += pulse(-0.3, -0.1, 11.4 - sin(wc.x * 3.14159 * 2.0 + rp.z * 23.0) - wc.y * 16.0);
	
	return (length(floor(rp.xy)) > 3.0) ||
		((wires * step(fract(rp.z), 1e-3) * step(1.0, rp.y)) > 0.0);
}

bool traverseUniformGridStep(vec3 ro, vec3 rd, vec3 increment, inout vec3 intersection, out float t)
{
	t = min(intersection.x, min(intersection.y, intersection.z));
	vec3 rp = ro + rd * t;
	
	intersection += increment * step(intersection.xyz, intersection.yxy) *
		step(intersection.xyz, intersection.zzx);
	
	return gridSolidity1(rp) || gridSolidity0(rp);
}

float traverseUniformGrid(vec3 ro, vec3 rd)
{
	ro *= 2.0;
	rd *= 2.0;
	
	vec3 increment = vec3(1.0) / rd;
	vec3 intersection = ((floor(ro) + round(rd * 0.5 + vec3(0.5))) - ro) * increment;
	float t;
	
	increment = abs(increment);
	ro += rd * 1e-3;
	
	if(traverseUniformGridStep(ro, rd, increment, intersection, t))
		return t;
	
	if(traverseUniformGridStep(ro, rd, increment, intersection, t))
		return t;
	
	if(traverseUniformGridStep(ro, rd, increment, intersection, t))
		return t;
	
	if(traverseUniformGridStep(ro, rd, increment, intersection, t))
		return t;
	
	if(traverseUniformGridStep(ro, rd, increment, intersection, t))
		return t;
	
	if(traverseUniformGridStep(ro, rd, increment, intersection, t))
		return t;
	
	if(traverseUniformGridStep(ro, rd, increment, intersection, t))
		return t;
	
	if(traverseUniformGridStep(ro, rd, increment, intersection, t))
		return t;
	
	if(traverseUniformGridStep(ro, rd, increment, intersection, t))
		return t;
	
	if(traverseUniformGridStep(ro, rd, increment, intersection, t))
		return t;
	
	if(traverseUniformGridStep(ro, rd, increment, intersection, t))
		return t;
	
	
	return 1e4;
}


float torchFlicker()
{
	return 1.0 - 0.3 * pulse(0.0, 0.4, fract(time * 0.2)) * pulse(0.4, 0.5, fract(time * 6.0)) +
		pulse(0.1, 0.12, fract(time * 0.12));
}

float torchOn()
{
	return smoothstep(0.0, 0.2, time - 4.0);
}

float torch(vec3 cp, vec3 cv, vec3 cw, vec3 rp, float nearest, out vec3 torch_o, out vec3 torch_d)
{
	torch_o = cp + cv;
	torch_d = cw;
	
	float d = dot(normalize(rp - torch_o), -torch_d);
	
	float sparkles = 1.2 + 0.7 * smoothstep(0.95, 1.0, smN2(t.xy * 50.0 + vec2(time * 10.0 + cos(t.y * 10.0 + time * 0.3) * 2.0, sin(t.x * 10.0 + time * 0.3) * 2.0)));
	sparkles += 0.2 * smoothstep(0.95, 1.0, smN2(t.xy * 20.0 + vec2(time * 10.0 + cos(t.y * 10.0 + time * 0.3), sin(t.x * 10.0 + time * 0.3))));
	
	return torchOn() * sparkles * torchFlicker() * 0.5 * (smoothstep(0.9, 1.0, d) * 2.0 + smoothstep(0.7, 1.0, d) * 0.3 + smoothstep(0.88, 0.88 + nearest * 0.02, d)) / distance(rp, cp);
}

float look(float x)
{
	float c = floor(x);
	return smoothstep(0.5, 1.0, 1.0 - abs(fract(x) - 0.5) * 2.0) * step(0.2, cos(mod(c, 20.0) * 3.0));
}


vec2 torchInterval(vec3 ro, vec3 rd, vec3 torch_o, vec3 torch_d)
{
	vec3 w = normalize(torch_d);
	vec3 u = normalize(cross(w, vec3(0.0, 1.0, 0.0)));
	vec3 v = normalize(cross(w, u));
	
	vec3 scale = vec3(0.03, 0.03, 0.2);
	
	rd = (transpose(mat3(u, v, w)) * rd) / scale;
	ro = (transpose(mat3(u, v, w)) * (ro - torch_o)) / scale;
	
	return cubeInterval(ro, rd);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	vec2 uv = fragCoord.xy / iResolution.xy;
	
	t = uv * 2.0 - vec2(1.0);
	t.x *= iResolution.x / iResolution.y;
	time = iTime;
	
	vec3 cp = vec3(0.3, -0.7 + pow(0.5 + 0.5 * cos(time * 10.0), 0.7) * 0.01, time * 0.2);
	
	vec3 cl;
	
	cl = vec3(cp.x - 3.0, cp.y + 2.5, floor(cp.z / 4.0) * 4.0 + 2.0) - cp;
	
	cl = mix(vec3(0.0, 0.0, 1.0), cl, look(cp.z / 4.0));
	
	vec3 ct = cp + rotateY(cos(time * 0.2) * 0.3 + sin(time * 3.0) * 0.02,
						   rotateX((0.5 + 0.5 * sin(time * 0.3)) * 0.2, -cl));
	vec3 cw = normalize(ct - cp);
	vec3 cu = normalize(cross(cw, vec3(0.0, 1.0, 0.0)));
	vec3 cv = normalize(cross(cu, cw));
	
	mat3 rm = mat3(cu, cv, cw);
	
	vec3 ro = cp, rd = rm * vec3(t.xy * 0.3, -0.25);
	
	float t = traverseUniformGrid(ro, rd);
	
	vec3 rp = ro + rd * t;
	vec2 cc = cubeProject(rp * 2.0 - (floor(rp * 2.0) + vec3(0.5))); 
	
	vec3 col0 = wall(rp, cc);
	vec3 col1 = crate(rp, cc);
	
	float order = gridSolidity0(rp * 2.0 + rd * 1e-3) ? 0.0 : 1.0;
	
	float nearest = t;
	
	vec3 l = vec3(0.01) + vec3(pow(1.0 - smoothstep(0.04, (2.0 - rp.y) * 0.15, distance(fract(rp.xz  * 0.6 + vec2(0.0)), vec2(0.5))), 2.0) *
							   1.0 * clamp(1.0-rp.y, 0.0, 1.0));
	
	vec3 torch_o, torch_d;
	
	vec3 ttilt = rm * vec3(-(iMouse.x - iResolution.x / 2.0) / iResolution.x,
					  -(iMouse.y - iResolution.y / 2.0) / iResolution.y * 0.5, 0.0);
	

	l += 0.8 * vec3(1.1, 1.1, 0.8) *
		torch(cp, cv * -0.2 + cu * 0.1, rotateY(cos(time * 2.0) * 0.03, normalize(cw + cu * -0.2 + ttilt)), rp, nearest, torch_o, torch_d);
	
	vec2 ti = torchInterval(ro, rd, torch_o, torch_d);
	float thit = step(ti.x, ti.y) * step(0.0, ti.x);
	
	float tdd = distance(torch_o, ro + rd * ti.x) + 0.5;
	
	vec3 col = mix(col0, col1, order) * mix(vec3(0.02, 0.03, 0.1) * (3.0 - rp.y) * 0.2, vec3(1.2, 1.2, 1.0), l);
	vec3 fog = vec3(0.2, 0.25, 0.2) * 0.8;
	
	float v = 1.0 - pow(distance(uv, vec2(0.5)), 2.0) * 0.5;
	
	fragColor.rgb = 1.5 * mix(fog, col, exp(-nearest * nearest * 0.1)) * v;
	
	fragColor.rgb = mix(fragColor.rgb, vec3(1.0, 1.0, 0.9) * (clamp(tdd * 0.3, 0.0, 1.0) +
					torchFlicker() * torchOn() * pow(clamp(tdd - 0.2, 0.0, 1.0) * 2.0, 30.0)), thit);
	
	fragColor.rgb *= 1.2;
	
	fragColor.rgb += vec3(N(fragCoord.xy) * 0.005);
	fragColor.a = 1.0;
}
