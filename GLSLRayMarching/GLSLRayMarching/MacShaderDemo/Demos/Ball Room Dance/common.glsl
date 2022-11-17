// Created by SHAU - 2019
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

#define BUF(C, P, R) texture(C, P/R)
#define POS 10.5
#define VEL 20.5
#define NBALLS 20

#define DURATION 60.

#define RAYS 4
#define BOUNCES 3

#define LAMBERTIAN 1
#define METAL 2
#define DIFFUSE_LIGHT 3
#define PANEL_LIGHT 4

#define PI 3.141592
#define FAR 10000.
#define EPS 0.005

#define UI0 1597334673U
#define UI1 3812015801U
#define UI2 uvec2(UI0, UI1)
#define UI3 uvec3(UI0, UI1, 2798796415U)
#define UIF (1.0 / float(0xffffffffU))

struct Material {
    int type;
    vec3 albedo;
    vec3 emit;
    float v; 
}; 
const Material MISS_MATERIAL = Material(0, vec3(0), vec3(0), 0.0);

struct HitSphere {
    float t; 
    vec3 p;
    vec3 n; 
    vec3 c;
    float r;
    float id;
    Material mat;
};
HitSphere HIT_MISS = HitSphere(FAR,
                               vec3(0),
                               vec3(0),
                               vec3(0), 
                               0.0, 
                               0.0, 
                               MISS_MATERIAL); //miss

    
struct Ray {
    vec3 o;
    vec3 d;
};
    
//compact rotation - Fabrice
mat2 rot(float x) {return mat2(cos(x), sin(x), -sin(x), cos(x));}

//IQ cosine palattes
//https://iquilezles.org/articles/palettes
vec3 palette1(float t) {return vec3(.5) + vec3(.5) * cos(6.28318 * (vec3(1) * t * 0.1 + vec3(0, .33, .67)));}    
vec3 palette2(float t) {return vec3(.5) + vec3(.5) * cos(6.28318 * (vec3(1.0, 0.7, 0.4) * t * 0.1 + vec3(0.00, 0.15, 0.20)));}    
    
//Dave Hoskins - improved hash without sin
//https://www.shadertoy.com/view/XdGfRR
vec3 hash33(vec3 p) {
	uvec3 q = uvec3(ivec3(p)) * UI3;
	q = (q.x ^ q.y ^ q.z) * UI3;
	return vec3(q) * UIF;
}

vec2 hash22(vec2 p) {
	uvec2 q = uvec2(ivec2(p))*UI2;
	q = (q.x ^ q.y) * UI2;
	return vec2(q) * UIF;
}

float hash12(vec2 p) {
	uvec2 q = uvec2(ivec2(p)) * UI2;
	uint n = (q.x ^ q.y) * UI0;
	return float(n) * UIF;
}

//TODO: change to ivec2
vec4 load(sampler2D channel, vec2 R, int idx, float type) {
     return BUF(channel, vec2(float(idx)+.5, type), R);
}


