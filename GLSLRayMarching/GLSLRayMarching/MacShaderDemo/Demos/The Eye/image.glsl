// srtuss, 2014
// A 2D effect based on repetition of boxes and and motion-blur.

#define pi2 3.1415926535897932384626433832795

float tri(float x, float s)
{
    return (abs(fract(x / s) - 0.5) - 0.25) * s;
}

float hash(float x)
{
    return fract(sin(x * 171.2972) * 18267.978 + 31.287);
}

vec3 pix(vec2 p, float t, float s)
{
    s += floor(t * 0.25);
    float scl = (hash(s + 30.0) * 4.0);
    scl += sin(t * 2.0) * 0.25 + sin(t) * 0.5;
    t *= 3.0;
    vec2 pol = vec2(atan(p.y, p.x), length(p));
    float v;
    float id = floor(pol.y * 2.0 * scl);
    pol.x += t * (hash(id + s) * 2.0 - 1.0) * 0.4;
    float si = hash(id + s * 2.0);
    float rp = floor(hash(id + s * 4.0) * 5.0 + 4.0);
    v = (abs(tri(pol.x, pi2 / rp)) - si * 0.1) * pol.y;
    v = max(v, abs(tri(pol.y, 1.0 / scl)) - (1.0 - si) * 0.11);
    v = smoothstep(0.01, 0.0, v);
    return vec3(v);
}

vec3 pix2(vec2 p, float t, float s)
{
    return clamp(pix(p, t, s) - pix(p, t, s + 8.0) + pix(p * 0.1, t, s + 80.0) * 0.2, vec3(0.0), vec3(1.0));
}

vec2 hash2(in vec2 p)
{
	return fract(1965.5786 * vec2(sin(p.x * 591.32 + p.y * 154.077), cos(p.x * 391.32 + p.y * 49.077)));
}

#define globaltime (iTime - 2.555)

vec3 blur(vec2 p)
{
    vec3 ite = vec3(0.0);
    for(int i = 0; i < 20; i ++)
    {
        float tc = 0.15;
        ite += pix2(p, globaltime * 3.0 + (hash2(p + float(i)) - 0.5).x * tc, 5.0);
    }
    ite /= 20.0;
    ite += exp(fract(globaltime * 0.25 * 6.0) * -40.0) * 2.0;
    return ite;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	vec2 uv = fragCoord.xy / iResolution.xy;
    uv = 2.0 * uv - 1.0;
    uv.x *= iResolution.x / iResolution.y;
    uv += (vec2(hash(globaltime), hash(globaltime + 9.999)) - 0.5) * 0.03;
    vec3 c = vec3(blur(uv + vec2(0.005, 0.0)).x, blur(uv + vec2(0.0, 0.005)).y, blur(uv).z);
    c = pow(c, vec3(0.4, 0.6, 1.0) * 2.0) * 1.5;
    c *= exp(length(uv) * -1.0) * 2.5;
    c = pow(c, vec3(1.0 / 2.2));
	fragColor = vec4(c, 1.0);
}