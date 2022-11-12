#define resolution iResolution
#define time iTime


vec3 objcol;

// by Dave_Hoskins
float hash12(vec2 p)
{
	vec3 p3  = fract(vec3(p.xyx) * .1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

mat2 rot(float a){
    float s = sin(a), c = cos(a);
    return mat2(c, s, -s, c);
}

float de(vec3 pos)
{
    float t = mod(time,17.);
    float a=smoothstep(13.,15.,t)*8.-smoothstep(4.,0.,t)*4.;
    float f=sin(time*5.+sin(time*20.)*.2);
    pos.xz *= rot(time+.5);
    pos.yz *= rot(time);
    vec3 p = pos;
    float s=1.;
    for (int i=0; i<4; i++){
        p=abs(p)*1.3-.5-f*.1-a;
        p.xy*=rot(radians(45.));
        p.xz*=rot(radians(45.));
        s*=1.3;
    }
    float fra = length(p)/s-.5;
    pos.xy *= rot(time);
    p = abs(pos) - 2. - a;
    float d = length(p) - .7;
    d = min(d, max(length(p.xz)-.1,p.y));
    d = min(d, max(length(p.yz)-.1,p.x));
    d = min(d, max(length(p.xy)-.1,p.z));
    p = abs(pos);
    p.x -= 4.+a+f*.5;
    d = min(d, length(p) - .7);
    d = min(d, length(p.yz-abs(sin(p.x*.5-time*10.)*.3)));
    p = abs(pos);
    p.y -= 4.+a+f*.5;
    d = min(d, length(p) - .7);
    d = min(d, max(length(p.xz)-.1,p.y));
    d = min(d, fra);
    objcol = abs(p);
    if (d==fra) objcol=vec3(2.,0.,0.);
    return d;
}


vec3 normal(vec3 p) {
    vec2 d = vec2(0., .01);
    return normalize(vec3(de(p+d.yxx), de(p+d.xyx), de(p+d.xxy))-de(p));
}


vec3 march(vec3 from, vec3 dir)
{
    float d = 0., td = 0., maxdist = 30.;
    vec3 p = from, col = vec3(0.);
    for (int i = 0; i<100; i++)
    {
        float d2 = de(p) * (1.-hash12(gl_FragCoord.xy+time)*.2);
        if (d2<0.)
        {
            vec3 n = normal(p);
            dir = reflect(dir, n);
            d2 = .1;
          
        }
        d = max(.01, abs(d2));
        p += d * dir;
        td += d;
        if (td>maxdist) break;
        col += .01 * objcol;
    }
    return pow(col, vec3(2.));
}


void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord / resolution.xy - .5;
    uv.x *= resolution.x / resolution.y;
    vec3 from = vec3(0.,0.,-10.);
    vec3 dir = normalize(vec3(uv, 1.));
    vec3 col = march(from, dir);

    fragColor = vec4(col,1.);
}