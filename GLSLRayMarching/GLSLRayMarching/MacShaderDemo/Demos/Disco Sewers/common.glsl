const float MIN_FLOAT = 1e-6;
const float MAX_FLOAT = 1e6;
const float PI = acos(-1.);
const float TAU = 2. * PI;
#define sat(x) clamp(x, 0., 1.)
#define S(a, b ,x) smoothstep(a, b, x)

mat2 rot(float a) {
    float c = cos(a), s = sin(a);
    return mat2(c, -s, s, c);
}

float hash11(float p) {
    return fract(sin(p * 78.233) * 43758.5453);
}
float hash21(vec2 p){
    return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

struct Hit {
    float dist;
    vec3 norm;
    int mat_id;
};

Hit default_hit() {
    return Hit(1e9, vec3(0.), -1);
}

Hit _min(Hit a, Hit b) {
    if (a.dist < b.dist) return a;
    return b;
}

bool plane_hit(in vec3 ro, in vec3 rd, in vec3 po, in vec3 pn, out float dist) {
    float denom = dot(pn, rd);
    if (denom > MIN_FLOAT) {
        vec3 rp = po - ro;
        float t = dot(rp, pn) / denom;
        if(t >= MIN_FLOAT && t < MAX_FLOAT){
			dist = t;
            return true;
        }
    }
    return false;
}

bool clamped_plane(in vec3 ro, in vec3 rd, in vec3 po, in vec3 pn, in float border, out float dist) {
    vec3 orto = cross(pn, vec3(0., 0., 1.));
    bool floor = plane_hit(ro, rd, po, pn, dist);
    vec3 hit_pos = ro + rd * dist;
    vec3 from_orig = po - hit_pos;
    return floor && abs(dot(orto, from_orig)) < border;
}

float sd_capped_cylinder(vec3 p, float h, float r) {
    vec2 d = abs(vec2(length(p.xz), p.y)) - vec2(h, r);
    return min(max(d.x, d.y), 0.0) + length(max(d, 0.0));
}

float sd_capped_torus(in vec3 p, in vec2 sc, in float ra, in float rb) {
    p.x = abs(p.x);
    float k = (sc.y * p.x > sc.x * p.y) ? dot(p.xy, sc) : length(p.xy);
    return sqrt(dot(p, p) + ra * ra - 2.0 * ra * k) - rb;
}

float sd_capsule(vec3 p, vec3 a, vec3 b, float r) {
  vec3 pa = p - a, ba = b - a;
  float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0 );
  return length(pa - ba * h) - r;
}

vec2 polar_mod(vec2 p, float n) {
    float a = mod(atan(p.y, p.x), TAU / n) - PI / n;
    return vec2(sin(a), cos(a)) * length(p);
}

float rand_in_range(float x, float a, float b) {
    return a + hash11(x) * (b - a);
}

#define march_macro(func, ro, rd, steps, tmin, tmax, res)       \
    {                                              \
        float t = tmin;                            \
        for (int i = 0;; ++i) {                    \
            vec3 p = (ro) + (rd) * t;              \
            float d = func(p);                     \
            if (abs(d) < 0.001) {                  \
                res = vec2(t, 1.);                 \
                break;                             \
            }                                      \
            t += d;                                \
            if (t > (tmax) || i > (steps)) {       \
                res = vec2(t, -1.);                \
                break;                             \
            }                                      \
        }                                          \
    }


#define get_norm_macro(func, p, res)                               \
    {                                                              \
        mat3 k = mat3(p, p, p) - mat3(0.0001);                     \
        res = normalize(vec3(func(p)) -                            \
                        vec3(func(k[0]), func(k[1]), func(k[2]))); \
    }

mat3 get_cam(in vec3 eye, in vec3 target) {
    vec3 zaxis = normalize(target - eye);
    vec3 xaxis = normalize(cross(zaxis, vec3(0., 1., 0.)));
    vec3 yaxis = cross(xaxis, zaxis);
    return mat3(xaxis, yaxis, zaxis);
}

vec3 mrp_diffuse(vec3 P, vec3 A, vec3 B, out float t) {
    vec3 PA = A - P, PB = B - P, AB = B - A;
    float a = length(PA), b = length(PB);
    t = sat(a / (b + a));
	return A + AB * t;
}

vec3 mrp_specular(vec3 P, vec3 A, vec3 B, vec3 R, out float t) {
    vec3 PA = A - P, PB = B - P, AB = B - A;

    float t_num = dot(R, A) * dot(AB, R) + dot(AB, P) * dot(R, R) -
                  dot(R, P) * dot(AB, R) - dot(AB, A) * dot(R, R);
    float t_denom = dot(AB, AB) * dot(R, R) - dot(AB, R) * dot(AB, R);
    t = sat(t_num / t_denom);

    return A + AB * t;
}

float compute_falloff(vec3 position, vec3 light_position) {
    float d = distance(position, light_position);
    return 1.0 / (d * d);
}

vec3 pal(float t, vec3 a, vec3 b, vec3 c, vec3 d) {
    return a + b * cos(2.0 * PI * (c * t + d));
}
vec3 spc(float n, float bright) {
    return pal(n, vec3(bright), vec3(0.5), vec3(1.0), vec3(0.0, 0.33, 0.67));
}


/////////////////////////////////////////
int MaxSamples = 10;

float loop_noise(float x, float loopLen) {
    // cycle the edges
    x = mod(x, loopLen);

    float i = floor(x);  // floored integer component
    float f = fract(x);  // fractional component
    float u =
        f * f * f * (f * (f * 6. - 15.) + 10.);  // use f to generate a curve

    // interpolate from the current edge to the next one wrt cycles
    return mix(hash11(i), hash11(mod(i + 1.0, loopLen)), u);
}

// Hi Shane :x
vec3 boxy(vec3 sp, float time) {
    const vec2 sc = vec2(1. / 2., 1. / 4.);
    float sf = .005;
    vec2 p = rot(PI / 6.) * sp.zy;
    float iy = floor(p.y / sc.y);
    float rndY = hash21(vec2(iy));
    vec2 ip = floor(p / sc);
    p -= (ip + .5) * sc;

    float a = atan(sc.y, sc.x) + PI / 9.;
    vec2 pR = rot(-a) * p;
    float tri = pR.y < 0.? -1. : 1.;
    ip.x += tri * .5; 

    p = abs(p) - sc / 2.;
    float shp = max(p.x, p.y);
    shp = max(shp, -tri * pR.y);

    vec3 texCol = vec3(.04) + hash21(ip) *.02;
    texCol = mix(texCol, texCol * 2.5, (smoothstep(sf * 3.5, 0., abs(shp) - .015)));
    texCol = mix(texCol, vec3(0), (smoothstep(sf, 0., abs(shp + .06) - .005))*.5);

    if(abs(ip.y + 2.) > 7. && hash21(ip + .11) < .1){
        float sh = max(.1 - shp/.08, 0.);
        texCol = mix(texCol, vec3(0), smoothstep(sf, 0., shp));
        texCol = mix(texCol, vec3(sh), smoothstep(sf, 0., shp + .02));
        texCol = mix(texCol, vec3(0), smoothstep(sf, 0., shp + .04));
        texCol = mix(texCol, spc(hash21(ip), 1.)*.2, smoothstep(sf, 0., shp + .06));
    } 
    return texCol;
}

// iq https://www.shadertoy.com/view/MdjGR1
vec3 boxy_filtered( in vec3 uvw, in vec3 ddx_uvw, in vec3 ddy_uvw, in float time ) {
    int sx = 1 + int(clamp(4.0 * length(ddx_uvw - uvw), 0.0, float(MaxSamples - 1)));
    int sy = 1 + int(clamp(4.0 * length(ddy_uvw - uvw), 0.0, float(MaxSamples - 1)));

	vec3 no = vec3(0.0);

    for( int j=0; j < sy; j++) {
        for( int i = 0; i < sx; i++) {
            vec2 st = vec2(float(i), float(j)) / vec2(float(sx), float(sy));
            no += boxy(uvw + 
                    st.x * (ddx_uvw - uvw) + st.y * (ddy_uvw - uvw), time);
        }
    }

	return no / float(sx * sy);
}

const float RECORD_PERIOD = 50.;

vec3 pattern(vec3 p, float time, float n) {
    p *= 100.;
    vec2 uv = p.yz + vec2(2000., 2000.);
    float num_seg = n;

    float loop_length = RECORD_PERIOD;
    float transition_start = RECORD_PERIOD / 3.;

    float phi = atan(uv.y, uv.x + 1e-6);
    phi = phi / PI * 0.5 + 0.5;
    float seg = floor(phi * num_seg);
    float width = sin(seg) + 8.;

    float theta = (seg + 0.5) / num_seg * PI * 2.;
    vec2 dir1 = vec2(cos(theta), sin(theta));
    vec2 dir2 = vec2(-dir1.y, dir1.x);
    
    float radial_length = dot(dir1, uv);
    float prog = radial_length / width;
    float idx = floor(prog);

    const int NUM_CHANNELS = 3;
    vec3 col = vec3(0.);
    for (int i = 0; i < NUM_CHANNELS; ++i) {
        float off = float(i) / float(NUM_CHANNELS) - 1.5;
        time = time + off * .015;

        float theta1 = loop_noise(idx * 34.61798 + time,      loop_length);
        float theta2 = loop_noise(idx * 21.63448 + time + 1., loop_length);

        float transition_progress =
            (time - transition_start) / (loop_length - transition_start);
        float progress = clamp(transition_progress, 0., 1.);

        float threshold = mix(theta1, theta2, progress);

        float width2 = fract(idx * 32.721784) * 500.;
        float slide = fract(idx * seg * 32.74853) * 50. * time;
        float prog2 = (dot(dir2, uv) - slide) / width2;

        float c = clamp(width  * (fract(prog)  - threshold),      0., 1.)
                * clamp(width2 * (fract(prog2) + threshold - 1.), 0., 1.);

        col[i] = c;
    }
    
    return col;
}

vec3 pattern_filtered( in vec3 uvw, in vec3 ddx_uvw, in vec3 ddy_uvw, in float time, float n, vec2 res) {
    float pixel_uv_size = res.y / 5.;
    int sx = 1 + int(clamp(4.0 * length(ddx_uvw - uvw) * pixel_uv_size, 0.0, float(MaxSamples - 1)));
    int sy = 1 + int(clamp(4.0 * length(ddy_uvw - uvw) * pixel_uv_size, 0.0, float(MaxSamples - 1)));
    
	vec3 no = vec3(0.0);

    for( int j=0; j < sy; j++) {
        for( int i = 0; i < sx; i++) {
            vec2 st = vec2(float(i), float(j)) / vec2(float(sx), float(sy));
            no += pattern(uvw + 
                    st.x * (ddx_uvw - uvw) + st.y * (ddy_uvw - uvw), time, n);
        }
    }

	return no / float(sx * sy);
}