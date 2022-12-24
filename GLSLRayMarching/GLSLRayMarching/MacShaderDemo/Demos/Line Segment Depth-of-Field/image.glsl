const float pi = 3.14159265358979323;

float dot2( in vec3 v ) { return dot(v,v); }

// Originally from https://www.shadertoy.com/view/llcfRf
// Modified to remove the caps and return the whole intersection interval.
vec2 iCappedCone2( in vec3  ro, in vec3  rd, 
                  in vec3  pa, in vec3  pb, 
                  in float ra, in float rb )
{
    vec3  ba = pb - pa;
    vec3  oa = ro - pa;
    vec3  ob = ro - pb;
    
    float m0 = dot(ba,ba);
    float m1 = dot(oa,ba);
    float m3 = dot(rd,ba);

    // body
    float m4 = dot(rd,oa);
    float m5 = dot(oa,oa);
    float rr = ra - rb;
    float hy = m0 + rr*rr;
    
    float k2 = m0*m0    - m3*m3*hy;
    float k1 = m0*m0*m4 - m1*m3*hy + m0*ra*(rr*m3*1.0        );
    float k0 = m0*m0*m5 - m1*m1*hy + m0*ra*(rr*m1*2.0 - m0*ra);
    
    float h = k1*k1 - k2*k0;
    if( h<0.0 ) return vec2(-1.0);

    return ((vec2(-1, +1) * sqrt(h)) - k1) / k2;
}

// Originally from https://www.shadertoy.com/view/4lcSRn
// Modified to remove the caps and return the whole intersection interval.
vec2 iCylinder2( in vec3 ro, in vec3 rd, 
                in vec3 pa, in vec3 pb, in float ra ) // point a, point b, radius
{
    // center the cylinder, normalize axis
    vec3 cc = 0.5*(pa+pb);
    float ch = length(pb-pa);
    vec3 ca = (pb-pa)/ch;
    ch *= 0.5;

    vec3  oc = ro - cc;

    float card = dot(ca,rd);
    float caoc = dot(ca,oc);
    
    float a = 1.0 - card*card;
    float b = dot( oc, rd) - caoc*card;
    float c = dot( oc, oc) - caoc*caoc - ra*ra;
    float h = b*b - a*c;
    if( h<0.0 ) return vec2(-1.0);
    
    return ((vec2(-1, +1) * sqrt(h)) - b) / a;
}

float dofLine(vec3 c0, vec3 c1, float ra, vec3 p0, vec3 p1)
{
    float dlen = length(p1 - p0);
    vec3 dir = (p1 - p0) / dlen;
    
    // Test for intersection of the line segment with the cone of defocused rays.
    
    vec2 res = iCappedCone2(p0, dir, c0, c1, ra, 0.);
    
    if(res.y < 0. || res.x > dlen)
    {
        // To avoid rendering subpixel-sized lines which would end up being heavily under-sampled,
        // the center of the defocus cone is modelled as a thick cylinder.
        
        vec2 res2 = iCylinder2(p0, dir, c0, c1, 2e-3);

        if(res2.y > res2.x && res2.y > 0. && res2.x < dlen)
        {
            res.x = min(res.x, res2.x);
            res.y = max(res.y, res2.y);
        }
        
        if(res.y < 0. || res.x > dlen)
            return 0.;
    }
    
    vec3 q0 = p0 + dir * res.x;
    vec3 q1 = p0 + dir * res.y;

    // Contribution is modelled somewhat on the usual monte carlo raytracing.
    // This amounts to integrating coverage of a varying disc by a small point.
    // Function to integrate is: 1 / (pi * ((a * x + b) ^ 2))
    // Integral is: -1 / (pi * a * a * x + pi * a * b)
    
    vec3 cd = c1 - c0;
    float cl2 = ra / dot(cd, cd);

    float z0 = dot(q0 - c1, cd);
    float z1 = dot(q1 - c1, cd);

    float a = cl2 * (z1 - z0);
    float b = cl2 * z0;

    float i0 = pi * a * b;
    float i1 = pi * a * (a + b);
    
    i0 = 1e-4 / max(1e-10, abs(i0)) * sign(i0);
	i1 = 1e-4 / max(1e-10, abs(i1)) * sign(i1);
    
    return min(1., abs(i1 - i0));
}


float heightmap(vec2 uv)
{
    return (texture(iChannel0, uv.yx / 256.).r - .1) * 2.;
}
    
mat3 rotX(float a)
{
    return mat3(1., 0., 0., 0., cos(a), sin(a), 0., -sin(a), cos(a));
}

mat3 rotY(float a)
{
    return mat3(cos(a), 0., sin(a), 0., 1., 0., -sin(a), 0., cos(a));
}

mat3 rotZ(float a)
{
    return mat3(cos(a), sin(a), 0., -sin(a), cos(a), 0., 0., 0., 1.);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    float time = iTime;
    vec2 uv = fragCoord / iResolution.xy * 2. - 1.;
    uv.x *= iResolution.x / iResolution.y;

    vec3 ro = vec3(-0.2, 1., 0.);
    vec3 focus = ro + vec3(uv.xy, -3.5);

    float ra = .08;
    float t = iTime / 2.;
    
    mat3 m = rotX(.23);

    vec3 col = vec3(0.0);

    // Landscape.
    
    for(int y = -14; y < -1; ++y)
    {
        vec3 ps[4];
		for(int x = -6; x < 6; ++x)
        {            
            ps[1] = ps[0];
            ps[3] = ps[2];
            ps[0] = vec3(float(x + 0), 0, float(y + 0)) / 2.;
            ps[2] = vec3(float(x + 0), 0, float(y + 1)) / 2.;
            
            ps[0].y = heightmap(ps[0].xz + vec2(0., -floor(t))) + cos(iTime / 3.) * .1;
            ps[0].z += fract(t);
            ps[0] = m * ps[0];

            ps[2].y = heightmap(ps[2].xz + vec2(0., -floor(t))) + cos(iTime / 3.) * .1;
            ps[2].z += fract(t);
            ps[2] = m * ps[2];

            if(x > -6)
            {
                if(abs(x) > -y / 2)
                	continue;
  
                float f = 1. - smoothstep(2.8, 3.2,
                          abs(max(abs(ps[0].z + 3.), max(abs(ps[1].z + 3.),
                          max(abs(ps[2].z + 3.), abs(ps[3].z + 3.))))));
                
                if(f > 0.01)
                {
                    col += dofLine(ro, focus, ra, ps[0], ps[1]) * f * .5;
                    col += dofLine(ro, focus, ra, ps[1], ps[3]) * f * .5;
                }
            }
        }
    }
    
    // Dust particles.
    
    for(int i = 0; i < 32; ++i)
    {
        vec3 dotp = cos(vec3(19, 129, 99) * (float(i))) * vec3(2., 0.4, 5.) + vec3(0, 0.4, 0.);
        dotp.z += t;
        dotp.z = mod(dotp.z, 5.) - 6.;
        dotp = m * dotp;
        float f = 1. - smoothstep(1.5, 2., abs(dotp.z + 3.));
        if(f > 0.01)
        	col += dofLine(ro, focus, ra, dotp, dotp + 1e-4) * f * vec3(1,.8,.2);
    }
    

    col = pow(col + (1. - smoothstep(0., 3.8, length(uv))) * .1, vec3(1.8, 1.4, 1));

    fragColor.rgb = col * 2.;

    // Gamma correction

    fragColor.rgb = pow(min(fragColor.rgb, 1.), vec3(1. / 2.2)) +
        	texelFetch(iChannel1, ivec2(fragCoord) & 1023, 0).r / 100.;
    fragColor.a = 1.;
}
