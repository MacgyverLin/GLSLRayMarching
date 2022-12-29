// https://twitter.com/gam0022/status/1453405601971666944
#define time iTime
#define PI acos(-1.)
#define TAU 2. * PI
#define L normalize(vec3(1, 1, 1))
#define saturate(x) clamp(x, 0., 1.)

float fbm(float x) { return sin(x) + 0.5 * sin(2. * x) + 0.25 * sin(4. * x); }

float dBox(vec3 p, vec3 b) {
    vec3 q = abs(p) - b;
    return length(max(q, 0.)) + min(max(q.x, max(q.y, q.z)), 0.0);
}

void rot(inout vec2 p, float a) { p = mat2(cos(a), sin(a), -sin(a), cos(a)) * p; }

float map(vec3 p) {
    float a = 4.5;
    p = mod(p, a) - a * 0.5;
    float s = 1.;

    for (int i = 0; i < 3; i++) {
        p = abs(p) - 0.5 + 0.04 * sin(time * TAU / 4.);
        rot(p.xy, 0.5);
        p = abs(p) - 0.4;
        rot(p.yz, 0.3 + 0.2 * sin(time * TAU / 4.));

        float b = 1.3 + 0.1 * sin(time * TAU / 4.);
        p *= b;
        s *= b;
    }

    return dBox(p, vec3(0.5, 0.05, 0.05)) / s;
}

float map2(vec3 p) {
    float m1 = map(p) - 0.05;
    vec3 a = vec3(1.0);
    p = mod(p, a) - 0.5 * a;

    for (int i = 0; i < 4; i++) {
        p = abs(p) - 0.5;
        rot(p.xy, 0.1);
        p = abs(p) - 0.3;
        rot(p.yz, 0.1);
    }

    return max(m1, dBox(p, vec3(1.1, 0.01, 0.01)));
}

vec3 getN(vec3 p) {
    vec2 eps = vec2(0.001, 0);
    return normalize(vec3(map(p + eps.xyy) - map(p - eps.xyy), map(p + eps.yxy) - map(p - eps.yxy), map(p + eps.yyx) - map(p - eps.yyx)));
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = vec2(fragCoord.x / iResolution.x, fragCoord.y / iResolution.y);
    uv -= 0.5;
    uv /= vec2(iResolution.y / iResolution.x, 1);

    vec3 ro = vec3(0, 0, time);
    vec3 target = ro + vec3(0., 0., 1.) + 0.01 * fbm(time * TAU * 2.);
    vec3 up = vec3(0, 1, 0);

    vec3 fwd = normalize(target - ro);
    vec3 right = normalize(cross(up, fwd));
    up = normalize(cross(fwd, right));
    vec3 ray = normalize(right * uv.x + up * uv.y + fwd * 0.5);

    vec3 p = ro;
    bool hit = false;
    float t = 0.0;
    int i;

    vec3 col = vec3(0);

    for (i = 0; i < 100; i++) {
        p = ro + ray * t;
        float d = map(p);

        if (d < 0.001) {
            hit = true;
            vec3 N = getN(p);
            float diffuse = dot(N, L);
            float specular = pow(saturate(dot(reflect(L, N), ray)), 10.0);
            col = vec3(1) * mix(diffuse, specular, 0.8);
            break;
        }

        t += d;
    }

    p = ro;
    float t2 = 0.0, ac = 0.0;
    for (i = 0; i < 100; i++) {
        p = ro + ray * t2;
        float d = map2(p);
        d = max(abs(d), 0.02);
        ac += exp(-10. * d);

        t2 += d * 0.5;
        if (t2 > t) break;
    }

    col += vec3(0.06, 0.3, 0.9) * ac * 0.1;

    fragColor = vec4(col, 1);
}