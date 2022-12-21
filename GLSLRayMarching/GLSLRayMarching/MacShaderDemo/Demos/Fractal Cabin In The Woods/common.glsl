float sminCubic( float a, float b, float k ) //iq
{
    float h = max( k-abs(a-b), 0.0 )/k;
    return min( a, b ) - h*h*h*k*(1.0/6.0);
}

float smin( float a, float b, float k ) //iq
{
    float h = max( k-abs(a-b), 0.0 )/k;
    return min( a, b ) - h*h*k*(1.0/4.0);
}

vec3 hsv2rgb_smooth( in vec3 c ) //iq
{
    vec3 rgb = clamp( abs(mod(c.x*6.0+vec3(0.0,4.0,2.0),6.0)-3.0)-1.0, 0.0, 1.0 );
	rgb = rgb*rgb*(3.0-2.0*rgb);
    
	return c.z * mix( vec3(1.0), rgb, c.y);
}

mat2 Rot(in float a) //2D
{
    float s = sin(a);
    float c = cos(a);
    return mat2(c, -s, s, c);
}

#define Rot2D(p, a) p=cos(a)*p+sin(a)*vec2(p.y,-p.x)
vec3 Rot(in vec3 p, in vec3 r) //las
{
    Rot2D(p.xz, r.y);
    Rot2D(p.yx, r.z);
    Rot2D(p.zy, r.x);
    return p;
}

//keep air hot, the winter is comming:
vec2 sdKMC( in vec3 p,
            in int iters,
            in vec3 fTra,
            in vec3 fRot,
            in vec4 para)
{//kind of kaleidoscopic menger cube "structure"
    
    float d =   length(max(vec3(0.), abs(p) - para.z - 
                length(abs(fTra) + abs(sin(fRot)))));
    if (d > 0.) return vec2(10e3, 0.);
    
    int i;
    float col = 0.;
    float x1, y1;
    float r = p.x*p.x + p.y*p.y + p.z*p.z;
    
    for(i = 0; i < iters && r < 1e8; i++)
    {
        if (i > 0) 
        {
            p -= fTra;
            p = Rot(p, fRot);
        }

        p = abs(p);

        if (p.x-p.y < 0.) { x1=p.y; p.y=p.x; p.x=x1;}
        if (p.x-p.z < 0.) { x1=p.z; p.z=p.x; p.x=x1;}
        if (p.y-p.z < 0.) { y1=p.z; p.z=p.y; p.y=y1;}

        p.z -= 0.5 * para.x * (para.y - 1.) / para.y;
        p.z = -abs(p.z);
        p.z += 0.5 * para.x * (para.y - 1.) / para.y;

        p.x = para.y * p.x - para.z * (para.y - 1.);
        p.y = para.y * p.y - para.w * (para.y - 1.);
        p.z = para.y * p.z;

        r = p.x*p.x + p.y*p.y + p.z*p.z;
    }
    
    d = length(p) * pow(para.y, float(-i));

    return vec2(d, col);
}

float hash(float n) { return fract(sin(n)*43758.5453123); } //iq

float noise(in vec2 x) //iq
{
    vec2 p = floor(x);
    vec2 f = fract(x);

    f = f*f*(3.0-2.0*f);

    float n = p.x + p.y*57.0;
    float res = mix(mix(hash(n+  0.0), hash(n+  1.0), f.x),
                    mix(hash(n+ 57.0), hash(n+ 58.0), f.x), f.y);
    return res;
}

vec3 R(in vec2 uv, in vec3 p, in vec3 l, in float z)
{
    vec3 f = normalize(l-p),
        r = normalize(cross(vec3(0,1,0), f)),
        u = cross(f,r),
        c = p+f*z,
        i = c + uv.x*r + uv.y*u,
        d = normalize(i-p);
    return d;
}
