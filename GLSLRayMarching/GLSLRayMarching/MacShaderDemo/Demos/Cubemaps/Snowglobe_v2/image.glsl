// shader by Andrei Jiman
//
//Many thanks to the following:
//            - IA¡Àigo QuAlez for the distance functions, shadows and ambient occlusion and noise... and smin :)
//            - TekF for the CamPolar function and the sphere trace function
 
#define PI (3.1415926535897932384626433832795)
 
#define FIREFOX_HACK 0
 
const vec3 e = vec3(0.001,0.0,0.0);
 
#define GetNormal(fun, p)         normalize(vec3(fun(p+e.xyy) - fun(p-e.xyy), fun(p+e.yxy) - fun(p-e.yxy), fun(p+e.yyx) - fun(p-e.yyx)));
 
float dot2( in vec3 v )                                                                      {return dot(v,v);}
float sdPlane( vec3 p, vec4 n )                                                    {return dot(p,n.xyz) + n.w;}
float sdSphere( vec3 p, float s )                                 {return length(p)-s;}
float udRoundBox( vec3 p, vec3 b, float r ) {return length(max(abs(p)-b,0.0))-r;}
float udBox( vec3 p, vec3 b )                                                       {return length(max(abs(p)-b,0.0));}
float sdCappedCylinder( vec3 p, vec2 h )
{
                vec2 d = abs(vec2(length(p.xz),p.y)) - h;
                return min(max(d.x,d.y),0.0) + length(max(d,0.0));
}
 
float phong(vec3 l, vec3 e, vec3 n, float power)
{
    float nrm = (power + 8.0) / (PI * 8.0);
    return pow(max(dot(l,reflect(e,n)),0.0), power) * nrm;
}
 
#define AA 0
 
mat3 rX(float a) {return mat3(1.0,0.0,0.0,0.0,cos(a),-sin(a),0.0,sin(a), cos(a));}
mat3 rY(float a) {return mat3(cos(a),0.0,sin(a),0.0,1.0,0.0,-sin(a),0.0,cos(a));}
mat3 rZ(float a) {return mat3(cos(a),-sin(a),0.0,sin(a),cos(a),0.0,0.0,0.0,1.0);}
 
vec3 triPlanar(in sampler2D tex, in vec3 p, in vec3 n)
{
    mat3 texMat = mat3(texture(tex, p.yz).rgb, texture(tex, p.xz).rgb, texture(tex, p.xy).rgb);
    return texMat * abs(n);;
}
 
//----------------------------------------------------------------
// SHAPES
const float maxd = 10.0;
 
float shapeBall(in vec3 pos)
{
    return sdSphere( pos, 0.6 );
}
 
float traceBall(in vec3 pos, in vec3 ray)
{
                float r = 0.6;
               
                float t = dot(-pos,ray);
               
                float p = length(-pos-t*ray);
                if ( p > r )
                                return 0.0;
               
                return t-sqrt(r*r-p*p);
}
 
float shapeSupport(in vec3 pos)
{
    vec3 p = pos;
    p.y += 0.55;
   
    return sdCappedCylinder(p, vec2(0.55, 0.2)) - 0.03;;
}
 
float traceSupport(in vec3 pos, in vec3 ray)
{
    float h = 1.0;
    float t = 0.0;
    for( int i=0; i<60; i++ )
    {
        if( h<0.01 || t>maxd ) break;
        h = shapeSupport(pos+ray*t);
        t += h;
    }
 
    if( t>maxd ) t=-1.0;
               
    return t;
}
 
float smin( float a, float b, float k )
{
    float h = clamp( 0.5+0.5*(b-a)/k, 0.0, 1.0 );
    return mix( b, a, h ) - k*h*(1.0-h);
}
 
//3d noise by iq
float hash( float n )          {return fract(sin(n)*43758.5453123);}
 
float noise( in vec3 x )
{
    vec3 p = floor(x);
    vec3 f = fract(x);
    f = f*f*(3.0-2.0*f);
    float n = p.x + p.y*57.0 + 113.0*p.z;
    float res = mix(mix(mix( hash(n+  0.0), hash(n+  1.0),f.x),
                        mix( hash(n+ 57.0), hash(n+ 58.0),f.x),f.y),
                    mix(mix( hash(n+113.0), hash(n+114.0),f.x),
                        mix( hash(n+170.0), hash(n+171.0),f.x),f.y),f.z);
    return res;
}
 
float shapeSnow(in vec3 pos)
{
    float dp = sdPlane( pos, vec4(0.0, 1.0, 0.0, 0.3) );
   
#if !FIREFOX_HACK
    dp += noise(pos.xzy * 123.0) * 0.01;
    dp += noise(pos.xzy * 35.12679) * 0.02;
#endif
   
    vec3 poss1 = pos + vec3(0.0, 0.2, 0.0);
    poss1 *= 0.99 + noise(pos * 200.0) * 0.01;
   
    vec3 poss2 = pos - vec3(0.0, 0.05, 0.0);
    poss2 *= 0.99 + noise(pos * 200.0) * 0.02;
   
    float ds1 = sdSphere(poss1, 0.2);
    float ds2 = sdSphere(poss2, 0.13);
   
    ds1 = smin(ds1, ds2, 0.03);
   
    dp = smin(dp, ds1, 0.05);
   
    return max(dp, shapeBall(pos + 0.1));
}
 
float traceSnow(in vec3 pos, in vec3 ray)
{
    float h = 1.0;
    float t = 0.0;
    for( int i=0; i<60; i++ )
    {
        if( h<0.01 || t>maxd ) break;
        h = shapeSnow(pos+ray*t);
        t += h;
    }
 
    if( t>maxd ) t=-1.0;
               
    return t;
}
 
float shapeTable(in vec3 pos)
{
    vec3 b = vec3(3.0, 0.2, 1.5);
    vec3 p = pos;
    p.y += 0.9;
   
    vec3 presentSize = vec3(0.4);
    vec3 pPr1 = pos + vec3(1.55, +0.145, 0.5);
   
    pPr1 = rY(0.2 * PI) * pPr1;
   
    float dTable = udRoundBox(p, b, 0.1);
    float dPresent1 = udRoundBox(pPr1, presentSize, 0.075);
 
//enable for table feet
#if 0
    float l1 = udBox(p - vec3(2.5, -1.7, 1.2), vec3(0.2, 2.0, 0.2));
    float l2 = udBox(p - vec3(2.5, -1.7, -1.2), vec3(0.2, 2.0, 0.2));
    float l3 = udBox(p - vec3(-2.5, -1.7, 1.2), vec3(0.2, 2.0, 0.2));
    float l4 = udBox(p - vec3(-2.5, -1.7, -1.2), vec3(0.2, 2.0, 0.2));
   
    dTable = min(dTable, l1);
    dTable = min(dTable, l2);
    dTable = min(dTable, l3);
    dTable = min(dTable, l4);
#endif
   
    return min(dTable, dPresent1);
}
 
float traceTable(in vec3 pos, in vec3 ray)
{
    float h = 1.0;
    float t = 0.0;
    for( int i=0; i<50; i++ )
    {
        if( h<0.001 || t>maxd ) break;
        h = shapeTable(pos+ray*t);
        t += h;
    }
 
    if( t>maxd ) t=-1.0;
               
    return t;
}
 
//----------------------------------------------------------------
 
float map( in vec3 pos )
{
    float d1 = shapeBall(pos);
    float d2 = shapeTable(pos);
    float d3 = shapeSupport(pos);
   
    return min( d1, min(d2, d3) );
}
 
//----------------------------------------------------------------
// SHADING
vec3 lig = normalize(vec3(1.0,0.9,0.7));
 
float calcSoftshadow( in vec3 _lo, in float _k )
{
    float _res = 1.0;
    float _t = 0.0;
                float _h = 1.0;
   
    for( int _i=0; _i<16; _i++ )
    {
        _h = map(_lo + lig * _t);
        _res = min( _res, _k *_h / _t );
                                _t += clamp( _h, 0.01, 1.0 );
                               
        if( _h<0.001 ) break;
    }
   
    return clamp(_res,0.0,1.0);
}
 
float calcOcclusion( in vec3 pos, in vec3 nor )
{
    float occ = 0.0;
    float sca = 1.0;
    for( int i=0; i<4; i++ )
    {
        float hr = 0.02 + 0.025*float(i*i);
        vec3 aopos =  nor * hr + pos;
        float dd = map( aopos );
        occ += -(dd-hr)*sca;
        sca *= 0.95;
    }
    return 1.0 - clamp( occ, 0.0, 1.0 );
}
 
vec3 background(vec3 rd)
{
    return texture(iChannel3, rd).xyz;
}
 
vec3 shadeSupport(in vec3 pos, in vec3 ray)
{
    vec3 col = vec3(1.0);
    vec3 norm = GetNormal(shapeSupport, pos);
   
    float sha = calcSoftshadow( pos + norm*0.1, 8.0 );
    float occ = calcOcclusion( pos, norm );
   
    vec3 color3D = triPlanar(iChannel2, pos, norm);
   
    float spec = phong(lig, ray, norm, 1.0);
    float atten = dot(norm, lig);
   
    float f = 1.0 - smoothstep(0.3, 0.31, pos.y + 0.95);
   
    col = mix(vec3(0.2, 0.7, 0.7), vec3(1.0), f);
    col *= atten * 0.5 + 0.5;
    col *= sha * 0.5 + 0.5;
    col *= occ;
   
    col += max(spec * sha * color3D * 2.0, 0.0);
    col *= 0.8 + color3D * 0.5;
   
    return col;
}
 
vec3 shadeTable(in vec3 pos, in vec3 ray)
{
    vec3 nor = GetNormal(shapeTable, pos);
   
    float sha = calcSoftshadow( pos + nor*0.01, 8.0 );
    float occ = calcOcclusion( pos, nor );
    float atten = clamp(dot(nor, lig), 0.0, 1.0) * 0.7 + 0.3;
    float spec = phong(lig, ray, nor, 16.0) * sha;
               
    vec3 tex = triPlanar(iChannel1, pos, nor);
    vec3 col = tex;
   
    if (pos.y > -0.55)
        col = vec3(0.1, 0.3, 1.0) * atten;
   
    if (pos.y <= -0.599)
        spec = spec * tex.r * tex.r;
    else
    {
        float n = noise(pos * 200.0);
        spec = spec * n + n * 0.01;
       
        col = triPlanar(iChannel0, pos, nor);
       
        col.r = 0.8;
    }
   
    col *= 0.5 + sha * atten * 0.5;
    col *= occ;
   
    col += spec;
   
    return col;
}
 
vec3 shadeSnow(in vec3 po, in vec3 ray)
{
    vec3 col = vec3(0.8);
    vec3 norm = GetNormal(shapeSnow, po);
    float atten = dot(norm, lig);
   
    col *= 0.85 + atten * 0.3;
   
    return col;
}
 
#define SNOW_STEPS 16
 
float snowFlakes(in vec3 pos, in vec3 ray)
{
    float total = 0.0;
   
    vec3 p2 = pos;
   
    p2.y += iTime / 8.0;
    p2.x += iTime / 20.0;
   
    const float stepSize = 0.6 / float(SNOW_STEPS);
   
    for (int i=0;i<SNOW_STEPS;i++)
    {
        p2 += ray * stepSize * sqrt(float(i));
        
        vec3 p21, p22, p23;
        
        p21 = p2 * rX(45.0) * rY(45.0) * rZ(45.0);
        p22 = p21 * rX(-45.0) * rY(-45.0) * rZ(-45.0);
        p23 = p22 * rX(-45.0) * rY(45.0) * rZ(-45.0);
       
        float val = noise(p21.xyz * 64.0) * noise(p22.yzx * 32.0) * noise(p23.zxy * 16.0);
        total += pow(val * 2.0, 8.0);
    }
   
    return clamp(total, 0.0, 1.0) * 0.7;
}
 
vec3 shadeBall(in vec3 pos, in vec3 ray)
{
    float ior = 0.98;
    vec3 norm = normalize(pos);
   
    vec3 refrRay = normalize(refract(ray, norm, ior));
    vec3 refrPos = pos + refrRay * 0.001;
   
    //reflection
    vec3 reflRay = normalize(reflect(ray, norm));
    vec3 reflPos = pos + reflRay * 0.001;
   
    float tb = traceBall(refrPos, refrRay);
    float ts = traceSnow(refrPos, refrRay);
   
    float ttr = traceTable(reflPos + reflRay * 0.001, reflRay);
   
    vec3 refl = vec3(0.0);
   
    if (ttr > 0.0)
        refl = shadeTable(reflPos + reflRay * ttr, reflRay);
    else
        refl = background(reflRay);
   
    
    vec3 col = vec3(0.0);
   
    if (ts > 0.0)
        col = shadeSnow(refrPos + refrRay * ts, refrRay) * 0.95;
    else
    {
        vec3 norm2 = normalize(refrPos + refrRay * tb);
        vec3 newRay2 = refract(refrRay, norm2, ior);
        vec3 newPos2 = refrPos + refrRay * tb;
 
        float tt = traceTable(newPos2 + newRay2 * 0.001, newRay2);
        float tsup = traceSupport(newPos2 + newRay2 * 0.001, newRay2);
 
        if (tt > 0.0 && (tt < tsup || tsup < 0.0))
        {
            col = shadeTable(newPos2 + newRay2 * tt, newRay2) * 0.8;
        }
        else if (tsup > 0.0)
            col = shadeSupport(newPos2 + newRay2 * tt, newRay2) * 0.8;
        else
            col = background(newRay2) * 0.6;
    }
   
    float flakes = snowFlakes(refrPos, refrRay);
   
    col += flakes;
   
    float spec = phong(lig, ray, norm, 16.0);
   
    col += max(spec, 0.0);
       
    col = mix(col, refl, pow(1.0 - dot(norm, -ray), 1.0));
   
    col += (1.0 - dot(norm, -ray)) * 0.2;
   
    return col;
}
 
 
//----------------------------------------------------------------
 
void camPolar( out vec3 pos, out vec3 dir, in vec3 origin, in vec2 rotation, in float dist, in float zoom, in vec2 offset, in vec2 fragCoord )
{
    // get rotation coefficients
    vec2 c = cos(rotation);
    vec4 s;
    s.xy = sin(rotation);
    s.zw = -s.xy;

    // ray in view space
    dir.xy = fragCoord.xy - iResolution.xy*.5 + offset;
    dir.z = iResolution.y*zoom;
    dir = normalize(dir);

    // rotate ray
    dir.yz = dir.yz*c.x + dir.zy*s.zx;
    dir.xz = dir.xz*c.y + dir.zx*s.yw;

    // position camera
    pos = origin - dist*vec3(c.x*s.y,s.z,c.x*c.y);
}
 
void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec3 col = vec3(0.0);
   
#if AA
	vec2 off[4];
    float osize = 0.25;
    off[0] = vec2(-osize, -osize);
    off[1] = vec2(osize, -osize);
    off[2] = vec2(-osize, osize);
    off[3] = vec2(osize, osize);
   
    for (int i = 0; i < 4; i++)
    {
        vec2 q = vec2(0.0);
#else
        vec2 q = fragCoord.xy / iResolution.xy;
#endif
        vec2 p = -1.0 + 2.0 * q;
        p.x *= iResolution.x/iResolution.y;

        vec3 camPos = vec3(0.0, 0.0, 0.0);
        vec2 camRot = vec2(0.3, iTime * 0.2);

        camRot.x += iMouse.y * 0.003;

        vec3 ro, rd;    
#if AA
        camPolar(ro, rd, camPos, camRot, 1.8 + 2.0 * iMouse.y * 0.002, 1.0, off[i], fragCoord);
#else
        camPolar(ro, rd, camPos, camRot, 1.8 + 2.0 * iMouse.y * 0.002, 1.0, vec2(0.0), fragCoord);
#endif

        float tBall = traceBall(ro,rd);
        float tTable = traceTable(ro, rd);
        float tSupport = traceSupport(ro, rd);

        int hit = 0;

        vec3 renderColor = vec3(0.0);
        if ((tBall > 0.0) && (tBall < tSupport || tSupport < 0.0) && (tBall < tTable || tTable < 0.0))
        {
            renderColor = shadeBall(ro+rd*tBall, rd);
        }
        else if ((tSupport > 0.0) && (tSupport < tTable || tTable < 0.0))
        {
            renderColor = shadeSupport(ro+rd*tSupport, rd);
        }
        else if (tTable > 0.0)
        {
            renderColor = shadeTable(ro+rd*tTable, rd);
        }
        else
            renderColor = background(rd);

        col += renderColor;
   
#if AA
    }
   
    col /= 4.0;
#endif
               
    fragColor = vec4( col, 1.0 );
}