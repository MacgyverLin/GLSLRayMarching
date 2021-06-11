/*MOVE THE LIGHT WITH THE MOUSE!*/

#define DIFFUSE 1
#define MIRROR 2
#define GLASS 3
#define EMISSION 4

#define SPHERE_COUNT (9+1)
#define LIGHT_COUNT 1

#define INFINITY 1000000.
#define M_PI 3.1415926535897932384626433832795
#define M_E 2.7182818284590452353602874

#define SAMPLES 10
#define MAX_BOUNCES 5

//#define BRUTE_FORCE
#define ACCUMULATE
#define PBRT_CONE_SAMPLING

struct Sphere{
    vec3 p; //geometric information pos: g.xyz radius: g.w
    float r; //radius
    vec3 c; //color of the sphere
    float s; //roughness or ior
    int m; //material
};

float hash1(inout float seed)
{
    return fract(sin(seed += 0.1)*43758.5453123);
}

float nrand( vec2 n )
{
	return fract(sin(dot(n.xy, vec2(12.9898, 78.233)))* 43758.5453);
}

vec2 hash2(inout float seed)
{
    return fract(sin(vec2(seed+=0.1,seed+=0.1))*vec2(43758.5453123,22578.1459123));
}


float hash12(vec2 p)
{
	vec3 p3  = fract(vec3(p.xyx) * .1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

vec2 uniform_disk_sample(inout float seed) //in polar coordinates theta, r
{
    vec2 p = hash2(seed);
    return vec2(2. * M_PI * p.x, sqrt(p.y));
}

vec3 cosine_weighted_hemi_sample(inout float seed)
{
    vec2 p = uniform_disk_sample(seed);
    return normalize(vec3(sin(p.x) * p.y, cos(p.x) * p.y, sqrt(1. - p.y * p.y)));
}


Sphere spheres[SPHERE_COUNT] = Sphere[SPHERE_COUNT](Sphere(vec3(1., 3.2, -0.5), .5,vec3(1., 1., 1.), 1.45, GLASS),
                                                    Sphere(vec3(0., 5.2, -0.5), .5,vec3(0.1, 0.5, 0.9), 1.45, DIFFUSE),
                                                    Sphere(vec3(-1., 4.2, -0.5), .5,vec3(1., 1., 1.), 1.45, MIRROR),
                                                    Sphere(vec3(1.8, 5.2, 4.654), .1, vec3(1., 1, 1.) * 3.6, 0., EMISSION),
                                                    Sphere(vec3(0., 4., -1000), 999.,vec3(1, 1, 1), 0., DIFFUSE),
                                                    Sphere(vec3(1001., 0., 0.), 999.,vec3(.1, 0.9, 0.1), 0., DIFFUSE),
                                                    Sphere(vec3(-1001., 0., 0.), 999.,vec3(0.9, .1, 0.1), 0., DIFFUSE),
                                                    Sphere(vec3(0., 1005.5, 0.5), 999.,vec3(.9, 0.9, 0.9), 0., DIFFUSE),
                                                    Sphere(vec3(0., 0., 1001.7), 999.,vec3(.9, 0.9, 0.9), 0., DIFFUSE)

                                                    , Sphere(vec3(0., 5.2, 1.5), .5,vec3(0.1, 0.5, 0.9), 1.45, DIFFUSE)
                                                    );
int lights[LIGHT_COUNT] = int[LIGHT_COUNT] (3);//index of the spheres to be directly sampled
//#endif


struct Ray{
	vec3 o;//origin
    vec3 d;//direction
};

    
float intersect_sphere(in Ray r, in Sphere s)
{
    r.o = r.o - s.p; //translate everything so that the sphere is centered
    
    float b = dot(r.o, r.d);
    float delta = b * b - dot(r.o, r.o) + s.r * s.r;
    
   	if (delta < 0.) return -1.;
    
    float sqdelta = sqrt(delta);
    
    if (-b - sqdelta > 0.001) return -b - sqdelta; //epsilon to avoid self intersection
    else if (-b + sqdelta > 0.001) return -b + sqdelta;
    return -1.;
}

bool intersect_scene(const in Ray r, out float t, out int idx, out Ray hit, out bool inside)
{
	t = INFINITY;
    idx = -1;
    for (int i = 0; i < SPHERE_COUNT; i++){
        float n_t = intersect_sphere(r, spheres[i]);
        if (n_t > 0. && n_t < t){
     		t = n_t;
            idx = i;
        }
    }
    if  (t == INFINITY){
        return false;
    }
    else{
		hit.o = r.o +  r.d  * t; //this point might be beneath the surface of the sphere
        hit.d = normalize(hit.o - spheres[idx].p);
        inside = distance(r.o, spheres[idx].p) <= spheres[idx].r;
        hit.d *= inside ? -1. : 1.; //flip the normal if inside the sphere
        //hit.o += hit.d * 0.1; //make sure the point does not go through
        return true;
    }
}

vec3 cone_uniform(in float theta, in vec3 dir, inout float seed)
{
    
    vec3 left = cross(dir, vec3(0., 1., 0.));//error for vertical vectors
    //vec3 left2 = cross(dir, vec3(0., 0., 1.));
    //left = length(left) > length(left2) ? normalize(left) : normalize(left2);
    left = length(left) > 0.1 ? normalize(left) : normalize(cross(dir, vec3(0., 0., 1.)));
    vec3 up = normalize(cross(dir, left));
    
    //cone sampling implementation from pbrt
    vec2 u = hash2(seed);
    float cos_theta = (1. - u.x) + u.x * cos(theta);
    float sin_theta = sqrt(1. - cos_theta * cos_theta);
    float phi = u.y * 2. * M_PI;    
    return normalize(
           left * cos(phi) * sin_theta +
           up   * sin(phi) * sin_theta +
           dir  * cos_theta);

}

vec3 sample_light(const in Ray p, in int light_idx, inout float seed, out float inv_prob) //return the radiance already scaled by the pdf
{
    Sphere l = spheres[light_idx];
    vec3 dir = normalize(l.p - p.o);
    float dist = length(l.p - p.o);
    float theta = asin(l.r / dist);
    Ray r = Ray(p.o + p.d * 0.0001, cone_uniform(theta, dir, seed)); //epsilon to make sure it self intersects
    
    float t;
    int idx;
    Ray hit;
    inv_prob = (2. * (1. - cos(theta)));
    bool inside;
    intersect_scene(r, t, idx, hit, inside);
    if (idx == light_idx){
        return l.c.xyz * max(0., dot(r.d, p.d)) * inv_prob;
    }
    return vec3(0., 0., 0.);
}

float snell (float sin_theta, float iori, float iort)
{
    return iori / iort * sin_theta;
}

float fresnel(float iori, float iort, float cosi, float cost){
    float rpar = (iort * cosi - iori * cost) / (iort * cosi + iori * cost);
    float rper = (iori * cosi - iort * cost) / (iori * cosi + iort * cost);
    rpar *= rpar;
    rper *= rper;
    return (rpar + rper) / 2.;
}

#ifndef BRUTE_FORCE
vec3 get_radiance(Ray r, inout float seed){
    vec3 rad = vec3(0.,0.,0.);
   	float t;
    int idx;
    Ray hit;
    vec3 brdf = vec3(1.,1.,1.);
    bool delta = true;
    bool inside = false;

    for (int b = 0; b < MAX_BOUNCES; b++){
        if(!intersect_scene(r, t, idx, hit, inside)){
            return rad + brdf * vec3(0.0, 0.0, 0.0); //return sky color;
        }
        float prob = 0.;
        int mat = spheres[idx].m;
        if (mat == DIFFUSE){
            delta = false;
            vec3 tangent = normalize(cross(r.d, hit.d));
            vec3 bitangent = normalize(cross(hit.d, tangent));
            vec3 nr = cosine_weighted_hemi_sample(seed);;
           	r.d = normalize(tangent * nr.x + bitangent * nr.y + hit.d * nr.z);
            brdf *= spheres[idx].c.xyz;

            for (int k = 0; k < LIGHT_COUNT; k++)
            {
                vec3 acc = brdf * sample_light(hit, lights[k], seed, prob);
                rad += acc;
            }
            
            //return rad;
        }
        else if (mat == MIRROR)
        {
            delta = true;
            r.d = reflect(r.d, hit.d);

            brdf *= spheres[idx].c.xyz;
        }
        else if (mat == GLASS){
            delta = true;
            float cosi = abs(dot(hit.d, r.d));
            float sini = sqrt(1. - cosi * cosi);
            float iort = spheres[idx].s;
            float iori = 1.;
            if (inside){
                iori = iort;
                iort = 1.;
            }
            float sint = snell(sini, iori, iort);
            float cost = sqrt(1. - sint * sint);
            float frsn = fresnel(iori, iort, cosi, cost);

            if (hash1(seed) > frsn){//ray transmitted
                vec3 bitangent = normalize(r.d - dot(hit.d, r.d) * hit.d);
                r.d = normalize(bitangent * sint - cost * hit.d);
                brdf *= spheres[idx].c;
            }
            else{ //ray reflected
                r.d = reflect(r.d, hit.d);
            }
            
        }
        else if (mat == EMISSION)
        {
            return rad + brdf * (delta ? spheres[idx].c.xyz : vec3(0.,0.,0.));
        }
        r.o = hit.o + r.d * 0.001;
        //if(length(brdf) < 0.1) return rad;// or something like this, also considering lights
    }
    return rad;
    
}
#endif

Ray ray_from_camera(vec2 uv, float fov, vec3 cam_pos, vec3 look_at, vec3 right_vector)
{//fov is expressed in radians
    float fl = 1./tan(fov / 2.); //focal length
   	return Ray(cam_pos, normalize(vec3(uv.x, fl, uv.y)));
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    spheres[lights[0]].p.xz += (texture(iChannel1, vec2(0., fragCoord/iResolution.xy)).xy - vec2(0.5, 0.5)) * vec2(3.5, 5.);
    vec2 uv0 = fragCoord/iResolution.xy;
    
    vec3 col;
    for (int s = 0; s < SAMPLES; s++){
        float seed = hash12(fragCoord.xy + iTime * M_PI + float(s) * 634.2342) + nrand(uv0 * iTime) * 52.2246 + hash2(uv0.x).x; //
        vec2 uv = (fragCoord + hash2(seed) - 1. - iResolution.xy /2.)/max(iResolution.x, iResolution.y);
        col += get_radiance(ray_from_camera(uv, M_PI * 0.5, vec3(0., -4., .8), vec3(0.,0.,0.), vec3(0.,0.,0.)), seed);
    }
    col /= float(SAMPLES);
#ifdef ACCUMULATE
    float start = texture(iChannel1, vec2(0., fragCoord/iResolution.xy)).z;
    float interval = float(iFrame) - start;
    col = (texture(iChannel0, fragCoord/iResolution.xy).xyz * interval + col) / (interval + 1.);
#endif
    fragColor = vec4(col , 0.0);
}