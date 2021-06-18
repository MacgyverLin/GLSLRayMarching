// rays per pixel
const int NS = 2;
// max reflection
const int ITER = 32;

const bool light_sampling = true;

const float EPS = .00001;
const float INF = 10000.;
const float PI = 3.14159265;

const float fov = 1.0;

const uint K = 0x456789abU;
const float uint_range = 1. / float(0xFFFFFFFFU);

void xorshift(inout uint seed) {
    seed ^= seed << 24;
    seed ^= seed >> 1;
    seed *= K;
    seed ^= seed << 1;
    seed *= K;
}

float next_float(inout uint seed) {
    xorshift(seed);
    return float(seed - 1U) * uint_range;
}

float next_float(inout uint seed, float min_v, float max_v) {
    return min_v + (max_v - min_v) * next_float(seed);
}

float atan2(float y, float x){
    return x == 0.0 ? sign(y) * PI*.5 : atan(y, x);
}

struct Hit {
    vec3 rp;
    vec3 nv;
    int index;
};

struct Material {
    int type;
    
    vec3 albedo;
    vec3 emit;

    float ref_idx;
};

// type for Material
const int LAMBERTIAN = 0;
const int METAL = 1;
const int DIELECTRIC = 2;

const vec3 COL_RED = vec3(.65, .05, .05);
const vec3 COL_BLUE = vec3(.05, .05, .65);
const vec3 COL_WHITE = vec3(.73);
const vec3 COL_GREEN = vec3(.12, .45, .15);

const vec3 NO_LIGHT = vec3(.0);

const Material MAT_WHITE = Material(LAMBERTIAN, COL_WHITE, NO_LIGHT, 0.);
const Material MAT_ALUMINUM = Material(METAL, vec3(0.8, 0.85, 0.88), NO_LIGHT, 0.);
const Material MAT_GLASS = Material(DIELECTRIC, COL_WHITE, NO_LIGHT, 1.5);

const int RECT = 0;
const int SPHERE = 1;

struct Geo {
    int type;

    vec2 size;
    mat4 m;
    mat4 im;
};

struct Box {
    Geo rects[6];
    mat4 m;
    mat4 im;
};

// Models
const int LEN_GEOS = 7;
const int LEN_BOXES = 2;
Geo geos[LEN_GEOS];
Box boxes[LEN_BOXES];
Material materials[LEN_GEOS + LEN_BOXES];

// importance samplings
const int N_SAMPLING = 1;
Geo samplings[N_SAMPLING];

void rot_x(const float theta, inout mat4 m, inout mat4 im) {
    m = mat4(
        1., 0., 0., 0.,
        0., cos(theta), sin(theta), 0.,
        0., -sin(theta), cos(theta), 0.,
        0., 0., 0., 1.
    ) * m;
    im *= mat4(
        1., 0., 0., 0.,
        0., cos(-theta), sin(-theta), 0.,
        0., -sin(-theta), cos(-theta), 0.,
        0., 0., 0., 1.
    );
}

void rot_y(float theta, inout mat4 m, inout mat4 im) {
    m = mat4(
        cos(theta), 0., sin(theta), 0.,
        0., 1., 0., 0.,
        -sin(theta), 0., cos(theta), 0.,
        0., 0., 0., 1.
    ) * m;
    im *= mat4(
        cos(-theta), 0., sin(-theta), 0.,
        0., 1., 0., 0.,
        -sin(-theta), 0., cos(-theta), 0.,
        0., 0., 0., 1.
    );
}

void rot_z(float theta, inout mat4 m, inout mat4 im) {
    m = mat4(
        cos(theta), sin(theta), 0., 0.,
        -sin(theta), cos(theta), 0., 0.,
        0., 0., 1., 0.,
        0., 0., 0., 1.
    ) * m;
    im *= mat4(
        cos(-theta), sin(-theta), 0., 0.,
        -sin(-theta), cos(-theta), 0., 0.,
        0., 0., 1., 0.,
        0., 0., 0., 1.
    );
}

void trans_xyz(const float dx, const float dy, const float dz, inout mat4 m, inout mat4 im) {
    m = mat4(
        1., 0., 0., 0.,
        0., 1., 0., 0.,
        0., 0., 1., 0.,
        dx, dy, dz, 1.
    ) * m;
    im *= mat4(
        1., 0., 0., 0.,
        0., 1., 0., 0.,
        0., 0., 1., 0.,
        -dx, -dy, -dz, 1.
    );
}

vec3 calc(const in mat4 m, in vec3 p) {
    return (m * vec4(p, 1.)).xyz;
}

vec3 rot(const in mat4 m, const in vec3 p) {
    return mat3(m) * p;
}

vec3 random_in_sphere(inout uint seed) {
    vec3 v;
    for (int i = 0; i < 1024; ++i) {
        v.x = next_float(seed, -1.0, 1.0);
        v.y = next_float(seed, -1.0, 1.0);
        v.z = next_float(seed, -1.0, 1.0);
        if (length(v) < 1.) return v;
    }
    return normalize(v);
}

vec3 random_unit_vector(inout uint seed) {
    return normalize(random_in_sphere(seed));
}

vec3 random_in_rect(const in Geo rect, inout uint seed) {
    float x = rect.size.x * next_float(seed, -1., 1.);
    float y = rect.size.y * next_float(seed, -1., 1.);
    float z = 0.;
    return calc(rect.im, vec3(x, y, z));
}

void gen_box(const float w, const float h, const float d, inout Box box) {
    { // front
        mat4 m = mat4(1.0), im = mat4(1.0);
        trans_xyz(0., 0., d, m, im);
        box.rects[0] = Geo(RECT, vec2(w, h), m, im);
    }
    { // back
        mat4 m = mat4(1.0), im = mat4(1.0);
        trans_xyz(0., 0., -d, m, im);
        box.rects[1] = Geo(RECT, vec2(w, h), m, im);
    }
    { // left
        mat4 m = mat4(1.0), im = mat4(1.0);
        trans_xyz(-w, 0., 0., m, im);
        rot_y(PI * 0.5, m, im);
        box.rects[2] = Geo(RECT, vec2(d, h), m, im);
    }
    { // right
        mat4 m = mat4(1.0), im = mat4(1.0);
        trans_xyz(w, 0., 0., m, im);
        rot_y(-PI * 0.5, m, im);
        box.rects[3] = Geo(RECT, vec2(d, h), m, im);
    }
    { // top
        mat4 m = mat4(1.0), im = mat4(1.0);
        trans_xyz(0., -h, 0., m, im);
        rot_x(PI * 0.5, m, im);
        box.rects[4] = Geo(RECT, vec2(w, d), m, im);
    }
    { // bottom
        mat4 m = mat4(1.0), im = mat4(1.0);
        trans_xyz(0., h, 0., m, im);
        rot_x(-PI * 0.5, m, im);
        box.rects[5] = Geo(RECT, vec2(w, d), m, im);
    }
}

void gen_models(const float t) {

    vec3 EMIT_LIGHT = vec3(15.);
    int i = 0, j = 0;
    float dy = 0.25;
    float w = 0.5;
    float h = 0.5;
    float depth = 1.0;

    {   // back
        mat4 m = mat4(1.0), im = mat4(1.0);
        trans_xyz(0., -h, -depth*.5, m, im);
        rot_x(PI, m, im);
        geos[i] = Geo(RECT, vec2(w, h), m, im);
        materials[i] = MAT_WHITE;
        i++;
    }
    {   // right
        mat4 m = mat4(1.0), im = mat4(1.0);
        trans_xyz(0.5, -h -EPS, 0., m, im);
        rot_y(PI *.5, m, im);
        geos[i] = Geo(RECT, vec2(w, h), m, im);
        materials[i] = Material(LAMBERTIAN, COL_RED, NO_LIGHT, 0.);
        i++;
    }
    {   // left
        mat4 m = mat4(1.0), im = mat4(1.0);
        trans_xyz(-0.5, -h, 0., m, im);
        rot_y(-PI *.5, m, im);
        geos[i] = Geo(RECT, vec2(w, h), m, im);
        materials[i] = Material(LAMBERTIAN, COL_GREEN, NO_LIGHT, 0.);
        i++;
    }
    {   // bottom
        mat4 m = mat4(1.0), im = mat4(1.0);
        trans_xyz(0., 0., 0., m, im);
        rot_x(PI / 2.0, m, im);
        geos[i] = Geo(RECT, vec2(w, h), m, im);
        materials[i] = MAT_WHITE;
        Material(LAMBERTIAN, COL_WHITE, NO_LIGHT, 0.);
        i++;
    }
    {   // top
        mat4 m = mat4(1.0), im = mat4(1.0);
        trans_xyz(0., -h * 2.0, 0., m, im);
        rot_x(-PI / 2.0, m, im);
        geos[i] = Geo(RECT, vec2(w, h), m, im);
        materials[i] = MAT_WHITE;
        i++;
    }
    {   // light
        float light_size = 0.2; // * (sin(t) + 1.1);
        mat4 m = mat4(1.0), im = mat4(1.0);
        trans_xyz(0., -h * 2.0 + 0.1, 0., m, im);
        rot_x(-PI / 2.0, m, im);
        geos[i] = Geo(RECT, vec2(light_size), m, im);
        materials[i] = Material(LAMBERTIAN, COL_WHITE, EMIT_LIGHT, 0.);
        samplings[j++] = geos[i];

        i++;
    }
    {
        mat4 m = mat4(1.0), im = mat4(1.0);
        trans_xyz(.05, -.25, .18, m, im);
        geos[i] = Geo(SPHERE, vec2(0.15), m, im);
        materials[i] = MAT_GLASS;
        i++;
    }

    int k = 0;
    float box_size = 0.15;
    {
        float box_height = 0.05;
        gen_box(box_size, box_height, box_size, boxes[0]);

        float phi = (t * 20. - 15.0) * PI / 180.0;
        float dh = box_height;

        mat4 m = mat4(1.0), im = mat4(1.0);
        trans_xyz(0.05, -dh, 0.18, m, im);
        rot_y(phi, m, im);
        boxes[0].m = m;
        boxes[0].im = im;
        materials[i] = Material(LAMBERTIAN, COL_BLUE, NO_LIGHT, 0.);

        i++;
    }
    {
        float box_height = 0.3;
        gen_box(box_size, box_height, box_size, boxes[1]);

        float phi = (t * 30. +75.0) / 180.0;
        float dh = box_height;

        mat4 m = mat4(1.0), im = mat4(1.0);
        trans_xyz(-0.19, -dh, -0.25, m, im);
        rot_y(phi, m, im);
        boxes[1].m = m;
        boxes[1].im = im;
        materials[i] = MAT_ALUMINUM;
        i++;
    }
}

vec3 background(const in vec3 rd) {
    return vec3(0.);
}

bool hit_sphere(
        const in vec3 ro0,
        const in vec3 rd0,
        const in Geo sphere,
        const float t_min,
        inout float t_max,
        out vec3 rp,
        out vec3 nv) {

    // matrix calculation
    vec3 rd = rot(sphere.m, rd0);
    vec3 ro = calc(sphere.m, ro0);
    
    float radius = sphere.size.x;

    vec3 oc = ro;
    float a = dot(rd, rd);
    float half_b = dot(oc, rd);
    float c = dot(oc, oc) - radius * radius;
    float discriminant = half_b * half_b - a * c;

    // no intersection
    if (discriminant < 0.0) return false;

    float sq_disc = sqrt(discriminant);

    float t;
    if (sq_disc < EPS) {
        // 1 intersection
        t = -half_b / a;
    } else {
        // 2 intersection (t1: near, t2: far)
        float t1 = (-half_b - sq_disc) / a;
        float t2 = (-half_b + sq_disc) / a;
        if (t1 > t_max || t2 < t_min) return false;
        
        if (t1 > t_min) {
            t = t1;  
        } else if (t2 < t_max) {
            t = t2;
        } else {
            return false;
        }
    }
    
    t_max = t;
    rp = ro + t * rd;
    nv = rp / radius;

    // inverse matrix calculation
    nv = rot(sphere.im, nv);
    rp = calc(sphere.im, rp);

    return true;
}

bool hit_rect(
        const in vec3 ro0,
        const in vec3 rd0,
        const in Geo rect,
        const float t_min,
        inout float t_max,
        out vec3 rp,
        out vec3 nv) {

    // matrix calculation
    vec3 rd = rot(rect.m, rd0);
    vec3 ro = calc(rect.m, ro0);

    float t = - ro.z / rd.z;
    if (t < t_min || t > t_max) return false;

    vec2 min_p = - rect.size;
    vec2 max_p = rect.size;
    vec3 p = ro + t * rd;
    if (p.x < min_p.x || p.x > max_p.x
        || p.y < min_p.y || p.y > max_p.y) {
        return false;
    }

    nv = vec3(0., 0., 1.0);

    // inverse matrix calculation
    nv = rot(rect.im, nv);
    rp = calc(rect.im, p);

    t_max = t;
    return true;
}

bool hit_box(
        const in vec3 ro0,
        const in vec3 rd0,
        const in Box box,
        const float t_min,
        inout float t_max,
        out vec3 rp,
        out vec3 nv) {

    vec3 rd = rot(box.m, rd0);
    vec3 ro = calc(box.m, ro0);
    bool hit_flag = false;
    for (int j = 0; j < 6; ++j) {
        if (hit_rect(ro, rd, box.rects[j], t_min, t_max, rp, nv)) {
            hit_flag = true;
        }
    }
    if (hit_flag) {
        nv = rot(box.im, nv);
        rp = calc(box.im, rp);
    }
    return hit_flag;
}

bool hit(
        const in vec3 ro,
        const in vec3 rd,
        const in Geo geos[LEN_GEOS],
        const in Box boxes[LEN_BOXES],
        const in Material materials[LEN_GEOS + LEN_BOXES],
        inout uint seed,
        out Hit hit) {

    float t_min = EPS;
    float t_max = INF;
    bool hit_flag = false;
    vec3 nv;
    vec3 rp;

    int geo_idx = 0;
    for (int i = 0; i < LEN_GEOS; ++i) {
        switch (geos[i].type) {
            case RECT:
                if (hit_rect(ro, rd, geos[i], t_min, t_max, rp, nv)) {
                    geo_idx = i;
                    hit_flag = true;
                }
                break;
            case SPHERE:
                if (hit_sphere(ro, rd, geos[i], t_min, t_max, rp, nv)) {
                    geo_idx = i;
                    hit_flag = true;
                }
                break;
        }
    }

    for (int i = 0; i < LEN_BOXES; ++i) {
        int idx = LEN_GEOS + i;
        if (hit_box(ro, rd, boxes[i], t_min, t_max, rp, nv)) {
            geo_idx = idx;
            hit_flag = true;
        }
    }
    if (!hit_flag) return false;

    hit = Hit(rp, nv, geo_idx);
    return true;
}

float schlick(const float cosine, const float ref_idx) {
    float r0 = (1. - ref_idx) / (1. + ref_idx);
    r0 = r0 * r0;
    return r0 + (1. - r0) * pow((1. - cosine), 5.);
}

float cos_pdf(const in vec3 nv, const in vec3 scattered) {
    float cosine = dot(nv, scattered);
    return max(cosine / PI, 0.);
}

float rect_pdf(const in vec3 ro, const in vec3 rd, const in Geo rect) {
    vec3 rp, nv;
    float t = INF;
    if (!hit_rect(ro, rd, rect, EPS, t, rp, nv)) {
        return 0.;
    }
    
    float dist_sq = t * t;

    float cosine = abs(dot(nv, rd));
    float area = 4. * rect.size.x * rect.size.y * cosine;
    return dist_sq / area;
}

float sphere_pdf(const in vec3 ro, const in vec3 rd, const in Geo sphere) {
    vec3 rp, nv;
    float t = INF;
    if (!hit_sphere(ro, rd, sphere, EPS, t, rp, nv)) {
        return 0.;
    }

    float r = sphere.size.x;
    float cos_theta_max = sqrt(1. - r*r / length(rp - ro));
    float solid_angle = 2.* PI * (1. - cos_theta_max);
    return 1. / solid_angle;
}

void scatter_lambertian(const in vec3 rp, const in vec3 nv, inout uint seed, out vec3 rd, out float pdf) {

    vec3 rd1 = normalize(nv + random_unit_vector(seed));
    //rd1 = random_in_hemisphere(seed, nv);

    int n = 0;
    vec3 tmp_rd[N_SAMPLING];
    if (light_sampling) {
        for (int i = 0; i < N_SAMPLING; ++i) {
            vec3 on_target = random_in_rect(samplings[i], seed);
            vec3 rd2 = on_target - rp;
            tmp_rd[n++] = rd2;
        }
    }

    if (n == 0) {
        rd = rd1;
        pdf = cos_pdf(nv, rd);
        return;
    }

    // importance sampling rate
    float blend = 0.6;

    float r = next_float(seed);
    float rate = blend / float(n);
    rd = rd1;
    if (r < blend) {
        for (int i = n - 1; i >= 0; --i) {
            r -= rate;
            rd = tmp_rd[i];
            if (r <= 0.) {
                break;
            }
        }
        rd = normalize(rd);
    }

    float sum_pdf = 0.;
    if (light_sampling) {
        for (int i = 0; i < N_SAMPLING; ++i) {
            sum_pdf += rect_pdf(rp, rd, samplings[i]);
        }
    }
    pdf = (1. - blend) * cos_pdf(nv, rd) + rate * sum_pdf;
}

bool pathtracing(
        in vec3 ro,
        in vec3 rd,
        inout uint seed,
        inout vec3 col,
        inout int n) {

    vec3 attenuation = vec3(1.);
    for (int i = 0; i < ITER; ++i) {

        Hit ret;
        if (!hit(ro, rd, geos, boxes, materials, seed, ret)) {
            col += attenuation * background(rd);
            n++;
            return i > 0;
        }

        vec3 nv = ret.nv;
        bool front_face = dot(rd, nv) <= 0.0;
        if (!front_face) nv = -nv;

        Material material = materials[ret.index];
        if (length(material.emit) > 0.1) {
            if (front_face) {
                col += attenuation * material.emit;
            }
            n++;
            return i > 0;
        }

        vec3 albedo = material.albedo;
        int type = material.type;
        if (type == LAMBERTIAN) {
            for (int j = 0; j < 100; ++j) {
                float pdf;
                scatter_lambertian(ret.rp, nv, seed, rd, pdf);

                if (pdf <= 0.) continue;

                float scattering_pdf = cos_pdf(nv, rd);
                ro = ret.rp;
                attenuation *= albedo * scattering_pdf / pdf;
                break;
            }
            continue;
        }
        vec3 reflected = reflect(rd, ret.nv);
        if (type == METAL) {
            if (dot(reflected, nv) <= 0.0) {
                n++;
                return i > 0;
            }
            rd = reflected;
        } else if (type == DIELECTRIC) {
            float ref_idx = material.ref_idx;
            float etai_over_etat = front_face ? 1.0 / ref_idx : ref_idx;

            float cos_theta = min(dot(-rd, nv), 1.0);
            float sin_theta = sqrt(1.0 - cos_theta*cos_theta);
            if (etai_over_etat * sin_theta > 1.0) {
                rd = reflected;
            } else if (next_float(seed) < schlick(cos_theta, etai_over_etat)) {
                rd = reflected;
            } else {
                rd = refract(rd, nv, etai_over_etat);
            }
        }
        ro = ret.rp;
        attenuation *= albedo;
    }
    return true;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {

    vec2 r = iResolution.xy;
    vec2 uv = fragCoord/r;
    
    gen_models(0.0);

    vec2 p = (fragCoord.xy*2.-r) / min(r.x,r.y);
    float theta = PI * 1.5;

    // ray origin
    vec3 ro = vec3(cos(theta), 0.5, sin(theta));
    vec3 ta = vec3(0., 0.5, 0.);
    
    vec3 cdir = normalize(ta - ro);
    vec3 side = cross(cdir,vec3(0.,1.,0.));
    vec3 up = cross(side, cdir);

    uint seed = uint(fragCoord.y * r.x + fragCoord.x);
    xorshift(seed);
    seed ^= uint(iFrame);

    vec3 col = vec3(0.);
    int n = 0;
    for (int s = 0; s < NS; ++s) {
        float u = next_float(seed, -0.5, 0.5) / r.x;
        float v = next_float(seed, -0.5, 0.5) / r.y;
        vec3 rd = normalize((p.x + u)*side+(p.y + v)*up+cdir*fov);
        if (!pathtracing(ro, rd, seed, col, n)) break;
    }
    col = n > 0 ? sqrt(col / float(n)) : vec3(0.);

    vec3 lastFrameCol = texture(iChannel0, uv).rgb;
    col = mix(lastFrameCol, col, 1.0 / float(iFrame + 1));
    fragColor = vec4(col, 1.);
}