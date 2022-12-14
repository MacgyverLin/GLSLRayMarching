// This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0
// Unported License. To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/3.0/ 
// or send a letter to Creative Commons, PO Box 1866, Mountain View, CA 94042, USA.
// =========================================================================================================

#define sat(a) clamp(a, 0., 1.)
mat2 r2d(float a) { float c = cos(a), s = sin(a); return mat2(c,-s,s,c);}
float _cube(vec3 p, vec3 s)
{
    vec3 l = abs(p)-s;
    return max(max(l.x,l.y),l.z);
}

float map(vec3 p)
{
    float limits = _cube(p,vec3(3.,1.,3.));
    p.xz *= r2d(iTime*.01);
    p.xz += vec2(0., iTime);
    p.xz*=.5;

    float land = -p.y + .5-(
    texture(iChannel0, p.xz*.01).x
    -asin(sin(p.x*10.*sin(p.z*2.)))*.05
    -sin(p.z*7.+p.x*2.)*.2
    -sin(p.z*10.+p.x*20.)*.05
    -sin(p.z*50.+p.x*2.+length(p))*.02)*1.25
    ;
    return max(land, limits);
}

vec3 getCam(vec3 rd, vec2 uv)
{
    float fov = 1.;
    vec3 r = normalize(cross(rd, vec3(0.,1.,0.)));
    vec3 u = normalize(cross(rd, r));
    
    return normalize(rd+fov*(r*uv.x+u*uv.y));
}

vec2 trace(vec3 ro, vec3 rd, int steps)
{
    vec3 p = ro;
    for (int i = 0; i < steps; ++i)
    {
        float d = map(p);
        if (d < 0.01)
            return vec2(d, distance(ro, p));
        p+= rd*d*.5;
    }
    return vec2(-1.);
}
vec3 getNormal(float d, vec3 p)
{
    vec2 e = vec2(0.01,0.);
    return -normalize(vec3(d)-vec3(map(p-e.xyy),map(p-e.yxy),map(p-e.yyx)));
}

vec3 gradient(float f)
{
    //return vec3(1.)*sat((sin(f*100.)-.9)*10.);
    float stp = 0.025;
    vec3 col;
    col = mix(vec3(0.996,0.663,0.086), vec3(0.847,0.133,0.788), f);
    col = floor(col/stp)*stp;
    return col;
}

vec3 rdr(vec2 uv)
{
    vec3 col = 1.-gradient(sat((uv.y+.5)*1.));
    float dist = 10.;
    vec3 ro = vec3(dist, -dist, -dist);
    vec3 ta = vec3(0.,0.,0.);
    vec3 rd = normalize(ta-ro);
    rd = getCam(rd, uv);
    vec2 res = trace(ro, rd, 64);
    if (res.y > 0.)
    {
        vec3 p = ro+rd*res.y;
        vec3 n = getNormal(res.x, p);//normalize(cross(dFdx(p), dFdy(p)));
        vec3 lpos = vec3(15.);
        vec3 ldir = lpos-p;
        vec3 rgb = gradient(p.y);
        
        col = rgb;//*sat(dot(normalize(rd+ldir), n));
        if (dot(n, vec3(0.,1.,0.)) > 0.01)
        col -= sat((sin(p.y*25.)-.975)*50.);
    }
    
    return col;
}



void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = (fragCoord-vec2(.5)*iResolution.xy)/iResolution.xx;

    vec3 col = rdr(uv);
    { // Not so cheap antialiasing SSAA x4

        vec2 off = vec2(1., -1.)/(iResolution.x*2.);
        vec3 acc = col;
        // To avoid too regular pattern yielding aliasing artifacts
        mat2 rot = r2d(uv.y*5.); // a bit of value tweaking, appears to be working well
        acc += rdr(uv-off.xx*rot);
        acc += rdr(uv-off.xy*rot);
        acc += rdr(uv-off.yy*rot);
        acc += rdr(uv-off.yx*rot);
        col = acc/5.;
    }
    col = col.yxz;
    col = pow(col, vec3(1.45));
    fragColor = vec4(col,1.0);
}