// Created by SHAU - 2019
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

#define UI0 1597334673U
#define UI1 3812015801U
#define UI2 uvec2(UI0, UI1)
#define UI3 uvec3(UI0, UI1, 2798796415U)
#define UIF (1.0 / float(0xffffffffU))

#define ZERO (min(iFrame,0))
#define R iResolution.xy
#define EPS 0.005
#define FAR 240.0
#define PI 3.14159
#define T mod(iTime, 19.0)
#define H 20.0

#define LA  vec2(0.5, 0.5)
#define CP  vec2(1.5, 0.5)
#define SP  vec2(3.5, 0.5)
#define BP  vec2(4.5, 0.5)
#define ARM vec2(5.5, 0.5)
#define LGT vec2(6.5, 0.5)

#define ELC1 100.5
#define ELC2 200.5
#define ELC3 300.5

#define FL 2.0

//Dave Hoskins - improved hash without sin
//https://www.shadertoy.com/view/XdGfRR
float hash12(vec2 p) {
	uvec2 q = uvec2(ivec2(p)) * UI2;
	uint n = (q.x ^ q.y) * UI0;
	return float(n) * UIF;
}

vec2 hash22(vec2 p) {
	uvec2 q = uvec2(ivec2(p))*UI2;
	q = (q.x ^ q.y) * UI2;
	return vec2(q) * UIF;
}

vec3 hash33(vec3 p) {
	uvec3 q = uvec3(ivec3(p)) * UI3;
	q = (q.x ^ q.y ^ q.z)*UI3;
	return vec3(q) * UIF;
}

//Shane IQ
float n3D(vec3 p) {    
	const vec3 s = vec3(7, 157, 113);
	vec3 ip = floor(p); 
    p -= ip; 
    vec4 h = vec4(0., s.yz, s.y + s.z) + dot(ip, s);
    p = p * p * (3. - 2. * p);
    h = mix(fract(sin(h) * 43758.5453), fract(sin(h + s.x) * 43758.5453), p.x);
    h.xy = mix(h.xz, h.yw, p.y);
    return mix(h.x, h.y, p.z);
}

//Fabrice
mat2 rot(float x) {return mat2(cos(x), sin(x), -sin(x), cos(x));}

//IQ Sphere Functions
vec2 sphIntersect(vec3 ro, vec3 rd, vec4 sph) {
    vec3 oc = ro - sph.xyz;
    float b = dot(oc, rd),
          c = dot(oc, oc) - sph.w * sph.w,
          h = b * b - c;
    if (h < 0.0) return vec2(0.0);
    h = sqrt(h);
    float tN = -b - h,
          tF = -b + h;
    return vec2(tN, tF);
}

float sphDensity(vec3 ro, vec3 rd, vec4 sph, float dbuffer) {

    vec3  rc = (ro - sph.xyz) / sph.w;
    float ndbuffer = dbuffer / sph.w,
          b = dot(rd, rc),
          c = dot(rc, rc) - 1.0,
          h = b * b - c;
    if (h < 0.0) return 0.0;
    h = sqrt(h);
    float t1 = -b - h,
          t2 = -b + h;

    if (t2 < 0.0 || t1 > ndbuffer) return 0.0;
    t1 = max(t1, 0.0);
    t2 = min(t2, ndbuffer);

    float i1 = -(c * t1 + b * t1 * t1 + t1 * t1 * t1 / 3.0);
    float i2 = -(c * t2 + b * t2 * t2 + t2 * t2 * t2 / 3.0);
    return (i2 - i1) * (3.0 / 4.0);
}

vec3 sphNormal(in vec3 pos, in vec4 sph) {
    return normalize(pos-sph.xyz);
}

vec3 camera(vec2 U, vec2 r, vec3 ro, vec3 la, float fl) {
    vec2 uv = (U - r*.5)/r.y;
    vec3 fwd = normalize(la-ro),
         rgt = normalize(vec3(fwd.z, 0., -fwd.x));
    return normalize(fwd + fl*uv.x*rgt + fl*uv.y*cross(fwd, rgt));
}

float vMap(vec3 p) {
    float hit = 0.0;
    vec2 h2 = hash22(floor(p.xz*0.25));
    if (p.z > 0.0) {
        if (p.y < -10.0 && h2.x > 0.5) hit=1.0;
        if (p.y > 10.0 && h2.y > 0.5) hit=1.0;
    }
    return hit;   
}

//Voxel Rendering
float maxcomp(in vec4 v) {
    return max(max(v.x,v.y), max(v.z,v.w));
}

float isEdge(in vec2 uv, vec4 va, vec4 vb, vec4 vc, vec4 vd) {
    vec2 st = 1.0 - uv;

    // edges
    vec4 wb = smoothstep( 0.85, 0.99, vec4(uv.x,
                                           st.x,
                                           uv.y,
                                           st.y) ) * ( 1.0 - va + va*vc );
    // corners
    vec4 wc = smoothstep( 0.85, 0.99, vec4(uv.x*uv.y,
                                           st.x*uv.y,
                                           st.x*st.y,
                                           uv.x*st.y) ) * ( 1.0 - vb + vd*vb );
    return maxcomp(max(wb, wc));
}

float castRay(
    in vec3 ro, 
    in vec3 rd, 
    out vec3 oVos, 
    out vec3 oDir, 
    in int zero, 
    in int steps) 
{
	vec3 pos = floor(ro),
	     ri = 1.0/rd,
	     rs = sign(rd),
	     dis = (pos-ro + 0.5 + rs*0.5) * ri;
	
	float res = -1.0;
	vec3 mm = vec3(0.0);
	for(int i =zero; i<steps; i++) {
        float ns = vMap(pos);
		if (ns>0.5 ) {
            res=1.0;
            break;
        }
		mm = step(dis.xyz, dis.yzx) * step(dis.xyz, dis.zxy);
		dis += mm * rs * ri;
        pos += mm * rs;
	}

	vec3 nor = -mm*rs;
	vec3 vos = pos;
	
    // intersect the cube	
	vec3 mini = (pos-ro + 0.5 - 0.5*vec3(rs))*ri;
	float t = max ( mini.x, max ( mini.y, mini.z ) );
	
	oDir = mm;
	oVos = vos;

	return t*res;
}

vec4 renderVoxels(
    vec3 ro, 
    vec3 rd, 
    vec3 lp, 
    vec3 bp,
    float lgt,
    int zero, 
    int steps) 
{
    
    vec3 pc = vec3(0),
         vos = vec3(0),
         dir = vec3(0);
    float mint = FAR;
    float t = castRay(ro, rd, vos, dir, zero, steps);
    
    if (t>0.0) {
        mint = t;
        vec3 n = -dir*sign(rd);
        vec3 p = ro + rd*t;
        vec3 ld = normalize(lp - p);
        vec3 bld = normalize(bp - p);
        float blt = length(bp - p);
        
        vec3 uvw = p - vos;        
        vec3 v1  = vos + n + dir.yzx;
	    vec3 v2  = vos + n - dir.yzx;
	    vec3 v3  = vos + n + dir.zxy;
	    vec3 v4  = vos + n - dir.zxy;
		vec3 v5  = vos + n + dir.yzx + dir.zxy;
        vec3 v6  = vos + n - dir.yzx + dir.zxy;
	    vec3 v7  = vos + n - dir.yzx - dir.zxy;
	    vec3 v8  = vos + n + dir.yzx - dir.zxy;
	    vec3 v9  = vos + dir.yzx;
	    vec3 v10 = vos - dir.yzx;
	    vec3 v11 = vos + dir.zxy;
	    vec3 v12 = vos - dir.zxy;
 	    vec3 v13 = vos + dir.yzx + dir.zxy; 
	    vec3 v14 = vos - dir.yzx + dir.zxy ;
	    vec3 v15 = vos - dir.yzx - dir.zxy;
	    vec3 v16 = vos + dir.yzx - dir.zxy;
		vec4 vc = vec4(vMap(v1),  vMap(v2),  vMap(v3),  vMap(v4));
	    vec4 vd = vec4(vMap(v5),  vMap(v6),  vMap(v7),  vMap(v8));
	    vec4 va = vec4(vMap(v9),  vMap(v10), vMap(v11), vMap(v12));
	    vec4 vb = vec4(vMap(v13), vMap(v14), vMap(v15), vMap(v16));
        
        vec2 uv = vec2( dot(dir.yzx, uvw), dot(dir.zxy, uvw) );
        float www = 1.0 - isEdge( uv, va, vb, vc, vd );
        
        pc = vec3(0.0,0.2,0.0) * max(0.05, dot(ld, n));
        //ball glow
        pc += vec3(0.8,1.0,0.0) * lgt * max(0.05, dot(bld, n)) / (1.0 + blt*blt*0.02);
        //edges
        pc += vec3(0.0,0.3,0.0)*(1.0-www) * step(p.y, 0.0);
    }
    
    return vec4(pc, mint);
}