#define AUTO  //Comment this line to gain mouse controll.

#define MAX_STEPS 300
#define SURF_DIST 1e-3
#define MAX_DIST 100.
#define float2 vec2
#define float3 vec3
#define float4 vec4
#define lerp mix
#define frac fract
#define saturate(v) clamp(v,.0,.1)
#define fmod mod
float hash21(float2 p) {
    p = frac(p * float2(233.34, 851.74));
    p += dot(p, p + 23.45);
    return frac(p.x * p.y);
}
float2 hash22(float2 p) {
    float k = hash21(p);
    return float2(k, hash21(p + k));
}
float sdSphere(float3 p, float s)
{
    return length(p) - s;
}

mat3x3 rotateY(float theta) {
    float c = cos(theta);
    float s = sin(theta);

    return mat3x3(
        float3(c, 0, s),
        float3(0, 1, 0),
        float3(-s, 0, c)
    );
}
float opSmoothUnion(float d1, float d2, float k) {
    float h = clamp(0.5 + 0.5 * (d2 - d1) / k, 0.0, 1.0);
    return lerp(d2, d1, h) - k * h * (1.0 - h);
}
float opSmoothSubtraction(float d1, float d2, float k) {
    float h = clamp(0.5 - 0.5 * (d2 + d1) / k, 0.0, 1.0);
    return lerp(d2, -d1, h) + k * h * (1.0 - h);
}
float sdPlane(float3 p, float4 n)
{
    return dot(p, n.xyz) + n.w;
}
float sdRoundBox(float3 p, float3 b, float r)
{
    float3 q = abs(p) - b;
    return length(max(q, 0.0)) + min(max(q.x, max(q.y, q.z)), 0.0) - r;
}

float sdPig(float3 p,float jump) {
    p*= 1.0 + vec3(-0.2,0.2,-0.2)*(0.5+0.5*sin(iTime*10.0+3.5));
    float3 j = float3(.0, -jump, .0);
    p.x = abs(p.x);
    float g = opSmoothUnion(sdRoundBox(p+j, float3(1.), 0.1), sdSphere(p + j, 1.2), 1.); //Main Body
    g = min(g,
            opSmoothUnion(
                sdRoundBox(p - float3(0, -0.25, 0.9) + j, float3(0.4, 0.3, 0.5), 0.1),
                sdSphere(p - float3(0, -0.25, 0.9) + j, .5), .5) //nose
           );
    float s = sdRoundBox(p - float3(.2, -0.25, 1.5) + j, float3(0.03, 0.13, 0.2), 0.05); //nostrile
    s = min(s, sdRoundBox(p - float3(.4, 0.5, 1.3) + j, float3(0.05, 0.2, 0.05), 0.05)); //eye
    return opSmoothSubtraction(s, g, 0.02);
}

float sdBridge(float3 p, float t) {
    float gap = 2.4;
    float tread = min(fmod(t, 3.141529 * 2.) / 3.141529, 1.) * gap;
    float backScale = smoothstep(3.141529 * 2., 3.141529, fmod(t, 3.141529 * 2.));
    float frontScale = smoothstep(0., 3.141529, fmod(t, 3.141529 * 2.));
    float g = min(
        sdRoundBox(p - float3(0., -2.3 - ((1. - backScale) * 3.), gap * -1. - tread), float3(backScale), 0.1),
        sdRoundBox(p - float3(0., -2.3, 0. - tread), float3(1.), 0.1)
    );
    g = min(g, sdRoundBox(p - float3(0., -2.3, gap - tread), float3(1.), 0.1));
    float alternate = fmod(floor(t / (3.141529 * 2.)), 2.);
    p = (rotateY(alternate > 0.5 ? (frontScale - 1.) : (1. - frontScale))* p);
    return min(g, sdRoundBox(p - float3(0., -2.3, gap * 2. - tread), float3(frontScale), 0.1));
			}
float GetDist(float3 p) {
    
    float t = iTime * 10.;
    //float2 id = floor(p.xz * 0.2);
    //p.xz = frac(p.xz * 0.2) *5. - 2.5;
    //float2 h = hash22(id);
    float g = sdPig(p, max(sin(iTime * 10. /*+ h.x * 3.141529 * 2.*/), .0));
    //g = min(g, sdPlane(p-float3(0,-1.3,0), float4(0, 1, 0, 0)));
    g = min(g, sdBridge(p, t));
    
    return g;
}
float CalculateAO(float3 p, float3 n) {
    float d = 0.6;
    return smoothstep(0.,d,GetDist(p + n*d));
}
float Raymarch(float3 ro, float3 rd) {
    float dO = 0.;
    float dS;
    for (int i = 0; i < MAX_STEPS; i+=1) {
        float3 p = ro + rd * dO;
        dS = GetDist(p);
        dO += dS;
        if (dS<SURF_DIST || dO>MAX_DIST) break;
    }
    return dO;
}

float3 GetNormal(float3 p) {
    float2 e = float2(1e-2, 0.);

    float3 n = GetDist(p) - float3(
        GetDist(p-e.xyy),
        GetDist(p-e.yxy),
        GetDist(p-e.yyx)
    );

    return normalize(n);
}

float4 scene (float3 ro,float3 rd)
{

    float4 col = float4(0);

    float d = Raymarch(ro, rd);
    float3 light1Dir = normalize(float3(.8, 1, .2));
    float3 light1Color = float3(1, 0.9, 0.9);

    if (d < MAX_DIST) {
        float3 p = ro + d * rd;
        float3 n = GetNormal(p);
        float ground = smoothstep(-1.18, -1.19, p.y);
        col.rgb = lerp(float3(1, .7, .8), float3(0.5, 0.6, 0.9), ground);
        col.rgb += pow(saturate(dot(reflect(rd, n), light1Dir)), .6) * light1Color * 0.3;
        col.rgb += n * 0.15;
        col.rgb *= CalculateAO(p, n) * 0.4 + 0.6;
    }
    else
    {
        float3 bg = lerp(float3(1, .7, .8), float3(0.5, 0.6, 0.9), rd.x);
        bg = lerp(bg, float3(.8, .5, .8), rd.y);
        col.rgb = bg;
    }
    return col;
}

mat2 Rot(float a) {
    float s = sin(a);
    float c = cos(a);
    return mat2(c, -s, s, c);
}

float3 GetRayDir(vec2 uv, vec3 p, vec3 l, float z) {
    vec3 f = normalize(l-p),
        r = normalize(cross(vec3(0,1,0), f)),
        u = cross(f,r),
        c = p+f*z,
        i = c + uv.x*r + uv.y*u,
        d = normalize(i-p);
    return d;
}


void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = (fragCoord-.5*iResolution.xy)/iResolution.y;
	vec2 m = iMouse.xy/iResolution.xy;
    
    vec3 col = vec3(0);
    
    vec3 ro = vec3(0, 5, -5);
    if(iMouse.w<0.5){
    	ro.yz *= Rot(-0.4);
    	ro.xz *= Rot(iTime*0.5+2.);
    }else{
        ro.yz *= Rot(-m.y*3.14+1.);
    	ro.xz *= Rot(-m.x*6.2831);
    }
    vec3 rd = GetRayDir(uv, ro, vec3(0), 1.);
    
    fragColor = scene(ro,rd);
}