#define MAXITERS 300.0
#define LENFACTOR .15
#define NDELTA 0.001
#define NDELTAX vec3(NDELTA, 0., 0.)
#define NDELTAY vec3(0., NDELTA, 0.)
#define NDELTAZ vec3(0., 0., NDELTA)
float box(vec3 p, vec3 centre, vec3 dims) {
    vec3 d = abs(p - centre) - dims;
    return max(d.x, max(d.y, d.z));
}
const vec3 rDir = normalize(vec3(-3.0, 4.0, -2.0)), rCol = vec3(1.0, 0.6, 0.4),
    bDir = normalize(vec3(2.0, 3.0, -4.0)), bCol = vec3(0.3, 0.7, 1.0),
    gDir = normalize(vec3(4.0, -3.0, 0.0)), gCol = vec3(0.7, 1.0, 0.8);
mat3 rotationMatrix(vec3 axis, float angle)
{
    float s = sin(angle);
    float c = cos(angle);
    float oc = 1.0 - c;
    return mat3(oc * axis.x * axis.x + c,           oc * axis.x * axis.y - axis.z * s,  oc * axis.z * axis.x + axis.y * s, // 0.0,
                oc * axis.x * axis.y + axis.z * s,  oc * axis.y * axis.y + c,           oc * axis.y * axis.z - axis.x * s, // 0.0,
                oc * axis.z * axis.x - axis.y * s,  oc * axis.y * axis.z + axis.x * s,  oc * axis.z * axis.z + c);          // 0.0,
}
const float pi = 3.1415926536;
mat2 rot(float t) {
	float s = sin(t), c = cos(t);
    return mat2(c, s, -s, c);
}
vec3 rotSpace(vec3 p) {
    vec3 ap = abs(p);
    float angle = pi * smoothstep(5., 2., max(ap.x, max(ap.y, ap.z)));
    if (angle <= 0.) return p;
    vec3 axis = vec3(
        cos(iTime * 0.3),
        0.,
        sin(iTime * 0.3));
    return p * rotationMatrix(axis, angle);
}
float scene(vec3 p) {
    p = rotSpace(p);
    
    float l = iTime * 0.2 - .2;
    l = max(0., min(pow(l, 6.), 1000.));
    return min(box(p, vec3(0.), vec3(0.7, 0.1, l)),
           min(box(p, vec3(0.), vec3(0.1, l, 0.7)),
           min(box(p, vec3(0.), vec3(l, 0.7, 0.1)),
               box(p, vec3(0.), vec3(1.))
           )));
}
vec3 sceneNormal(vec3 p) {
    return normalize(vec3(
        scene(p + NDELTAX) - scene(p - NDELTAX),
        scene(p + NDELTAY) - scene(p - NDELTAY),
        scene(p + NDELTAZ) - scene(p - NDELTAZ)
	));
}
void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	vec2 uv = (fragCoord - iResolution.xy * 0.5) / iResolution.y;
    vec3 ray = normalize(vec3(uv, 1.));
    ray.yz *= rot(-0.12);
    ray.xz *= rot(-0.7853981634);
    vec3 cam = vec3(10., 2., -10.);
    vec3 pos = cam;
    float i = 0.;
    for (; i < MAXITERS; ++i) {
        float dist = scene(pos);
        if (dist < 0.001) break;
        pos += ray * dist * LENFACTOR;
    }
        vec3 col = vec3(1.);
            vec3 p2 = rotSpace(pos);
            if (abs(p2.x) > 1.001) col = vec3(1., .757, .224);
            else if (abs(p2.y) > 1.001) col = vec3(0., .576, .5255);
            else if (abs(p2.z) > 1.001) col = vec3(.2902, .204, .365);
    	fragColor = vec4(col * (
            rCol * abs(dot(rDir, sceneNormal(pos))) +
            gCol * pow(dot(gDir, sceneNormal(pos)), 5.) +
            bCol * abs(dot(bDir, sceneNormal(pos)))
        ), 1.0) * (1.0 - pow(i / 300., 2.));
}