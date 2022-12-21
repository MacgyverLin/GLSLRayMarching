// Initial camera settings

vec3 cp = vec3(4.2, 2.8, 2.9); // Camera position
vec3 ct = vec3(1.0, 0.8, 0.0); // Camera target

#define ROTATE_CAMERA 1

// Initial light settings

vec4 ac = vec4(0.2, 0.2, 0.2, 1.0); // Ambient color
vec4 lc = vec4(1.0, 0.88, 0.54, 1.0); // Light color
vec3 lp = vec3(4.0, 1.5, -3.5); // Light position

#define USE_LIGHT_RADIUS 1

float lr = 12.0; // Light radius

// Rendering settings

const int mx = 64; // Max steps
const float pr = 0.001; // Precision
const float np = 0.01; // View frustum near plane
const float fp = 16.0; // View frustum far plane
vec3 sc = vec3(0.74, 0.90, 1.0); // Sky color

// Helpers

const vec2 e = vec2(0.0, 0.008); // Swizzle helper for normal calculation

// Distance functions

vec2 u(vec2 a, vec2 b)
{
    return (a.x < b.x) ? a : b;
}

float dfb(vec3 p, vec3 s)
{
    vec3 d = abs(p) - s;
    return min(max(d.x, max(d.y, d.z)), 0.0) + length(max(d, 0.0));
}

float dfs(vec3 p, float r)
{
    return length(p) - r;
}

vec3 rp(vec3 p, vec3 s)
{
    return mod(p, s) - 0.5 * s;
}

float dfd(vec3 p)
{
    float s1 = length(p - cp);
    float s2 = length(p);
    float m1 = 1.0 - clamp(s1 / 12.0, 0.0, 1.0);
    float m2 = clamp(s2 / 8.0, 0.0, 2.0);

    float a = sin(p.x * 0.5) * 0.25 + sin(p.z * 1.5) * 0.1;
    float b = sin(p.z * 3.0 + p.x * 2.0) * 0.05;
    float c = sin(p.z * 40.0 * p.y + p.x * 20.0 * p.y) * 0.004;
    float d = sin(p.z * p.y * p.x * 80.0) * 0.005;

    return p.y + (a * m2 + b * m2 + c * m1 + d * m1);
}

float dfp(vec3 p, float s)
{
    float a = dfb(p, vec3(s, 0.05 * s, s));
    float b = dfb(p + vec3(0.0, -s, 0.0), vec3(s, s, s));

    float ab = mix(a, b, 0.52); 

    return ab;
}

float dfp1(vec3 p) {
    float a = dfp(p + vec3(-2.2, 0.5, 4.5), 1.5);
    float b = step(abs(sin(p.y * 30.0)), 0.5) * 0.015;

    return a + b;
}

float dfp2(vec3 p) {
    float a = dfp(p + vec3(0.0, 0.3, 0.0), 2.0);
    float b = step(abs(sin(p.y * 35.0)), 0.5) * 0.015;
    float c = dfb(p - vec3(1.8, 0.03, 0.0), vec3(0.2, 0.1, 0.1));
    float d = dfb(p - vec3(2.0, 0.02, 0.0), vec3(0.03, 0.08, 0.04));

    a = min(a + b, max(-d, c));

    return a;
}

float dfss(vec3 p, float s)
{
    float aa = dfb(p, vec3(s, 0.05 * s, s));
    float bb = dfb(p + vec3(0.0, -s, 0.0), vec3(s, s, s));
    float c = dfb(p + vec3(0.0, 0.18, 0.0), vec3(s * 1.1, 0.22 * s, s * 1.1));
    float d = dfb(p + vec3(0.0, -0.25, 0.0), vec3(s * 0.915, 0.066 * s, s * 0.915));
    float e = dfb(p + vec3(0.0, -1.78, 0.0), vec3(s * 0.22, 0.016 * s, s * 0.22));

    float a = mix(aa, bb, 0.5);

    float x = mod(p.x * 40.0, 2.0) * 0.002 + mod(p.z * 40.0, 2.0) * 0.002;
    float x2 = mod(floor(p.x * 10.0), 2.0) * 0.005 + mod(floor(p.z * 10.0), 2.0) * 0.005;

    a = max(-c, min(min(a + x, d + x2), e + x2));

    float b = dfs(p, s * 0.8);

    return max(-b, a);
}

vec2 df(vec3 p)
{
    vec2 a = vec2(dfd(p), 0.0);
    vec2 b = vec2(min(dfp1(p), dfp1(p + vec3(8.0, 0.2, -6.0))), 1.0);
    vec2 c = vec2(dfp2(p), 1.0);

    float t0 = 0.08;
    float t1 = -5.0;
    float t = 1.0;

    if(iTime < 10.0) {
        t = sin(iTime * 0.15);   
    }

    vec2 d = vec2(dfss(p + vec3(0.0, mix(t1, t0, t), 0.0), 2.04), 2.0);

    vec2 r = u(u(u(a, b), c), d);

    return r;
}

// Rendering

vec3 cn(vec3 p)
{
    return normalize(vec3(df(p + e.yxx).x - df(p - e.yxx).x, df(p + e.xyx).x - df(p - e.xyx).x, df(p + e.xxy).x - df(p - e.xxy).x));
}

float ss(vec3 ro, vec3 rd, float mint, float tmax) // thanks iq
{
    float res = 1.0;
    float t = mint;

    for(int i=0; i<16; i++)
    {
        float h = df(ro + rd * t).x;
        res = min(res, 8.0 * h / t);
        t += clamp(h, 0.02, 0.10);
        
        if(h < 0.001 || t > tmax)
        {
            break;
        }
    }

    return clamp(res, 0.0, 1.0);
}

float ao(vec3 p, vec3 n)  // thanks iq
{
    float s = 0.01;
    float t = s;
    float oc = 0.0;

    for(int i=0; i<9; i++)
    {
        float d = df(p + n * t).x;
        oc += t - d;
        t += s;
    }

    return clamp(oc, 0.0, 1.0);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    #if ROTATE_CAMERA
    float s = 0.02;
    float l = length(ct.xz - cp.xz) + 0.5;
    cp.x = sin(iTime * s + 1.0) * l;
    cp.z = cos(iTime * s + 1.0) * l;
    #endif

    vec3 wu = vec3(0.0, 1.0, 0.0);
    vec3 cd = normalize(ct - cp);
    vec3 cr = normalize(cross(wu, cd));
    vec3 cu = normalize(cross(cd, cr));

    vec2 uv = gl_FragCoord.xy * 2.0 / iResolution.xy - 1.0;
    uv.y *= iResolution.y / iResolution.x;

    vec4 bc = vec4(mix(vec3(1.0), sc, gl_FragCoord.y / iResolution.y * 0.5), 1.0);
    vec4 c = bc;
    vec3 rd = normalize(cd + cr * uv.x + cu * uv.y);
    float t = np;
    bool h = false;
    vec3 p;
    vec2 d;

    for(int i=0; i<mx; i++)
    {
        p = cp + rd * t;
        d = df(p);

        if((d.x < pr) || (i == (mx - 1)))
        {
            h = true;

            break;
        }
        else
        {
            t += d.x;

            if(t > fp)
            {
                break;
            }
        }
    }
    
    if(h)
    {
		vec3 ld = lp - p;

        vec3 n = cn(p);

        float dl = max(0.0, dot(n, normalize(ld)));

        vec4 mc = vec4(0.5, 0.5, 0.5, 1.0);
        float s = 0.0;

        if(d.y == 1.0)
        {
            mc = vec4(0.82, 0.66, 0.34, 1.0);
        }
        else if(d.y == 2.0)
        {
            s = pow(dl, 32.0); 

            mc = vec4(0.6, 0.6, 0.6, 1.0);   
        }
        else {
            mc = vec4(0.82, 0.66, 0.34, 1.0);
        }

        #if USE_LIGHT_RADIUS
        vec3 r = ld / lr;
        float a = max(0.0, 1.0 - dot(r, r));
        c = mc * (ac + lc * (dl + s) * a);
        #else
        c = mc * (ac + lc * (dl + s));
        #endif

        c *= ss(p, lp, 0.02, 2.5);
        c -= ao(p, n) * 0.4;

        c = mix(c, bc, 1.0 - exp(-0.01 * t * t));   
    }

    fragColor = c;
}