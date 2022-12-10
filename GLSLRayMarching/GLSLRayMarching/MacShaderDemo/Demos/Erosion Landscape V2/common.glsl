
const float WATER_HEIGHT = .02;
const float FOCUS_DIST = 2.3;
const float BLUR_MUL = 6.;


const vec2 WIND = vec2(.06, .1);
const float FAR = 5.;
uvec2 pcg2d(uvec2 v)
{
    //from https://www.shadertoy.com/view/XlGcRh
    v = v * 1664525u + 1013904223u;

    v.x += v.y * 1664525u;
    v.y += v.x * 1664525u;

    v = v ^ (v>>16u);

    v.x += v.y * 1664525u;
    v.y += v.x * 1664525u;

    v = v ^ (v>>16u);

    return v;
}
uvec3 pcg3d(uvec3 v) 
{
    //from https://www.shadertoy.com/view/XlGcRh
    v = v * 1664525u + 1013904223u;

    v.x += v.y*v.z;
    v.y += v.z*v.x;
    v.z += v.x*v.y;

    v ^= v >> 16u;

    v.x += v.y*v.z;
    v.y += v.z*v.x;
    v.z += v.x*v.y;

    return v;
}
vec2 Rand2D(vec2 v)
{
    return vec2(pcg2d(uvec2(v)))/float(0xffffffffu);
}
vec3 Rand3D(vec3 v)
{
    return vec3(pcg3d(uvec3(v)))/float(0xffffffffu);
}

float Noise2D(vec2 p)
{
    vec2 ap = abs(p);
    vec2 fr = fract(ap);
    fr = fr * fr * (3. - 2. * fr);
    
    float a = Rand2D(ap).x;
    float b = Rand2D(ap+vec2(1,0)).x;
    float c = Rand2D(ap+vec2(0,1)).x;
    float d = Rand2D(ap+vec2(1)).x;

    float v = mix(mix(a,b, fr.x),mix(c,d,fr.x), fr.y);
    

    

    return v;
}
float Noise3D(vec3 p)
{
    vec3 ap = abs(p);
    vec3 fr = fract(ap);
    fr = fr * fr * (3. - 2. * fr);
    
    float a = Rand3D(ap).x;
    float b = Rand3D(ap+vec3(1,0,0)).x;
    float c = Rand3D(ap+vec3(0,1,0)).x;
    float d = Rand3D(ap+vec3(1,1,0)).x;
    
    float e = Rand3D(ap+vec3(0,0,1)).x;
    float f = Rand3D(ap+vec3(1,0,1)).x;
    float g = Rand3D(ap+vec3(0,1,1)).x;
    float h = Rand3D(ap+vec3(1,1,1)).x;

    float v = mix(mix(mix(a,b, fr.x),mix(c,d,fr.x), fr.y), mix(mix(e,f, fr.x),mix(g,h,fr.x), fr.y), fr.z);
    

    

    return v;
}



bool IsSpaceDown(sampler2D key)
{
    return texelFetch(key, ivec2(32,0),0).x>0.;
}

float Gaussian(float x, float a, float b, float c)
{
    return a*exp(-(pow(x-b,2.)/pow(2.*c,2.)));
}