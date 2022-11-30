#define PI 3.1415927
#define ZERO min(0.0, iTime)



////////////
// Random //
////////////

// Seeds are initialized in main
uint perFrameSeed;
vec3 rand;

uint lcg(uint i) {
    return 1103515245u * i + 12345u;
}

// Return the i-th term of the golden ratio sequence
float goldenSequence(uint i) {
    return float(2654435769u * i) / 4294967296.0;
}

// Return the i-th vector of Martin Roberts' R2 sequence
// http://extremelearning.com.au/unreasonable-effectiveness-of-quasirandom-sequences/
vec2 plasticSequence(uint i) {
    return vec2(3242174889u * i, 2447445414u * i) / 4294967296.0;
}

// Combine the two previous sequences
vec3 sequence3D(uint i) {
    return vec3(plasticSequence(i), goldenSequence(i));
}

vec3 toroidalJitter(vec3 x, vec3 jitter) {
    return 2.0 * abs(fract(x + jitter) - 0.5);
}



//////////////
// Sampling //
//////////////

// Generate an orthonormal vector basis around N
void genTB(vec3 N, out vec3 T, out vec3 B) {
    float s = N.z < 0.0 ? -1.0 : 1.0;
    float a = -1.0 / (s + N.z);
    float b = N.x * N.y * a;
    T = vec3(1.0 + s * N.x * N.x * a, s * b, -s * N.x);
    B = vec3(b, s + N.y * N.y * a, -N.y);
}

// Generate a random direction around N
// The direction probability is proportional to the cosinus of the angle relative to N
// Takes two uniformly distributed random values (r)
vec3 cosineSample(vec3 N, vec2 r) {
    vec3 T, B;
    genTB(N, T, B);
    r.x *= 2.0 * PI;
    float s = sqrt(1.0 - r.y);
    return T * (cos(r.x) * s) + B * (sin(r.x) * s) + N * sqrt(r.y);
}

// Generate a uniformly distributed random direction in a cone around N
// Takes two uniformly distributed random values (r)
vec3 coneSample(vec3 N, float cosTmax, vec2 r) {
    vec3 T, B;
    genTB(N, T, B);
    r.x *= 2.0 * PI;
    r.y = 1.0 - r.y * (1.0 - cosTmax);
    float s = sqrt(1.0 - r.y * r.y);
    return T * (cos(r.x) * s) + B * (sin(r.x) * s) + N * r.y;
}



/////////////
// Shading //
/////////////

// Schlick-Fresnel approximation
vec3 fresnel(float cosEN, vec3 F0) {
    float e = 1.0 - cosEN;
    float e5 = e * e; e5 *= e5 * e;
    return (1.0 - e5) * F0 + e5;
}