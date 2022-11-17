// Squishy balls by nimitz (twitter: @stormoid)
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License
// Contact the author for other licensing options

float sbox(vec3 p, vec3 b)
{
  vec3 d = abs(p) - b;
  return min(max(d.x,max(d.y,d.z)),0.0) + length(max(d,0.0));
}

float map(vec3 p, vec4[5] sp)
{
    float d = 100.;
    
    for (int i=0; i<5; i++)
    {
    	d = min(length(p-sp[i].xyz)-sp[i].w, d);
    }
    
    float box = - sbox(p, vec3(2.2,2.2,2.2));
    box = pow(box, 3.); //Cube is a hard surface, increase the distance metric
    d = min(d, box);
    
    return d;
}

vec3 normal(vec3 p, vec4[5] sp)
{  
    vec2 e = vec2(-1., 1.)*0.005;
	return normalize(e.yxx*map(p + e.yxx, sp) + e.xxy*map(p + e.xxy, sp) + 
					 e.xyx*map(p + e.xyx, sp) + e.yyy*map(p + e.yyy, sp) );   
}

vec3 hash3( float n ){return fract(sin(vec3(n,n+1.0,n+2.0))*vec3(43758.5453123,22578.1459123,19642.3490423))*2.0-1.0;}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 p = fragCoord.xy/iResolution.xy;
    vec2 w = 1./iChannelResolution[0].xy;
    
    if (p.y > 2.*w.y)
        discard;
    
    vec4[6] sp;
    vec4[5] sp2;
    
    sp[1] = texture(iChannel0, vec2(1.5, 0.5)*w);
    sp[2] = texture(iChannel0, vec2(2.5, 0.5)*w);
    sp[3] = texture(iChannel0, vec2(3.5, 0.5)*w);
    sp[4] = texture(iChannel0, vec2(4.5, 0.5)*w);
    sp[5] = texture(iChannel0, vec2(5.5, 0.5)*w);
    
    vec4[6] sv;
    
    sv[1] = texture(iChannel0, vec2(1.5, 1.5)*w);
    sv[2] = texture(iChannel0, vec2(2.5, 1.5)*w);
    sv[3] = texture(iChannel0, vec2(3.5, 1.5)*w);
    sv[4] = texture(iChannel0, vec2(4.5, 1.5)*w);
    sv[5] = texture(iChannel0, vec2(5.5, 1.5)*w);
    
    if (iFrame%1800 == 20)
    {
        sp[1] = vec4(0, 0.9, 1, 1);
        sp[2] = vec4(1, 0.5, 0, 0.95);
        sp[3] = vec4(-1, -0.5, 1, 0.9);
        sp[4] = vec4(1, -0.2, 1, 0.85);
        sp[5] = vec4(-0.5, 0.5, -1.5,0.8);
        
        sv[1] = vec4(hash3(float(iFrame)), 0)*0.04;
        sv[2] = vec4(hash3(float(iFrame+1)), 0)*0.06;
        sv[3] = vec4(hash3(float(iFrame+2)), 0)*0.06;
        sv[4] = vec4(hash3(float(iFrame+3)), 0)*0.06;
        sv[5] = vec4(hash3(float(iFrame+4)), 0)*0.06;
    }
    
    float cp = fragCoord.x;
    vec4 csp = vec4(0);
    vec4 csv = vec4(0);
    float td = 100.;
    int cnt = 0;
    
    //split into the current object and the rest
    for (int i=1; i<6; i++)
    {
        if (i == int(cp))
        {
            csp = sp[i];
            csv = sv[i];
        }
        else
        {
            sp2[cnt] = sp[i];
            cnt++;
        }
    }
    
    //evaluate the movement of the current object
    vec3 nor = normal(csp.xyz, sp2);
    float dst = map(csp.xyz, sp2);
#if 0
    //csv.xyz += (nor*0.0025*(exp(-dst*7. + 1.5))); //Repulsion
    csv.xyz += (nor*0.002*(exp(-dst*7. + 2.))); //Repulsion
    csv.xyz *= clamp(1.5*(abs(dst)),0.,1.)*0.01+0.99; //internal and external friction
#else
    csv.xyz += (nor*0.0025*(exp(-dst*8. + 1.75))); //Repulsion
    csv.xyz *= clamp(1.5*(abs(dst)),0.,1.)*0.006+0.994; //internal and external friction
#endif
    csv.y -= 0.0001; //gravity
    csv.xyz = clamp(csv.xyz, vec3(-0.5), vec3(0.5)); //Sanity
    csp.xyz += csv.xyz;
    
    vec4 ret = vec4(0);
    
    if (fragCoord.y < 1.0)
    {
        ret = csp;
    }
    else
        ret = csv;
    
    fragColor = ret;
}
