float noise(vec2 p)
{
    vec2 ip = floor(p), fp = fract(p);
    fp = smoothstep(0.,1.,fp);
    return mix(
               mix(hash12(ip+vec2(0,0)), hash12(ip+vec2(1,0)), fp.x),
               mix(hash12(ip+vec2(0,1)), hash12(ip+vec2(1,1)), fp.x),
               fp.y);
}

float fbm(vec2 p, int lv)
{
    float a = 1.0;
    float t = 0.0;
    for( int i=0; i<lv; i++ )
    {
        p += vec2(13.102,1.535);
        t += a*noise(p);
        p *= mat2(3,4,-4,3) * 0.4;
        a *= 0.5;
    }
    return 0.5*t;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = (2.*fragCoord-iResolution.xy)/iResolution.y;
    
    float mtHeight = fbm(uv.xx+0.6, 8);
    float mtHeightSm = fbm(uv.xx+0.6, 3);
    vec3 col = vec3(0);
    vec2 sunPos = vec2(0.8,-0.8);
    vec3 skyCol = vec3(0.075,0.310,0.518);
    float q = uv.y-sunPos.y;
    float q2 = uv.x-sunPos.x;
    skyCol = mix(skyCol, vec3(0.482,0.580,0.902), exp(-0.5*q*q-0.2*q2*q2));
    vec3 cloudCol = mix(skyCol, vec3(0.5), 0.2);
    skyCol = mix(skyCol, vec3(0.706,0.851,0.953), exp(-q*q*3.-0.5*q2*q2));
    skyCol = mix(skyCol, vec3(0.980,0.5,0.3), exp(-q*q*10.-0.5*q2*q2));
    skyCol = mix(skyCol, vec3(1.0,1.0,0.7), exp(-3.*length(uv-sunPos)));
    vec3 cloudCol2 = mix(skyCol, vec3(0.5), 0.2);
    vec3 cloudCol3 = mix(vec3(0.980,0.5,0.3),vec3(1.0,1.0,0.7), exp(-length(uv-sunPos)));
    cloudCol3 = mix(cloudCol3, cloudCol, smoothstep(0.,-1.,uv.y+0.3*uv.x));
    
    float w = 1.5*length(fwidth(uv));
    float isSky = smoothstep(0.,w,uv.y+0.3*uv.x+0.2*max(uv.x,0.)+1.-mtHeight);
    col = mix(col, skyCol, isSky);
    col = mix(col, skyCol, 0.5*smoothstep(-0.5,0.1,uv.y+0.3*uv.x+0.2*max(uv.x,0.)+1.-mtHeightSm));
    
    vec2 fuv = fract(0.1*uv);
    vec2 uvv = 20.*fuv*(1.-fuv)*(0.5-fuv);
    uvv = vec2(1,-1)*uvv.yx;
    vec2 uv2 = uv + uvv*cos(0.1*iTime);// twisting
    
    float silver = fbm(30.*uv - 0.06*iTime, 8) + 30.*(uv.y + 0.8);
    silver = smoothstep(0.,1.,silver)*smoothstep(2.,1.,silver) * 1./(1.+500.*q2*q2) * isSky;
    col += silver * vec3(0.9,0.6,0.3) * 100.;
    
    
    float lowClouds = fbm(5.*uv + 0.1*iTime, 8);
    float midClouds = fbm(3.*uv + vec2(0.06,-0.03)*iTime, 8);
    float hiClouds = fbm(uv2 + vec2(0.1,0.01)*iTime, 8) - 0.5;
    float hiClouds2 = fbm(uv + 10. + vec2(0.062,-0.03)*iTime, 8) - 0.5;
    col = mix(col, cloudCol3, 0.5*smoothstep(0.,1., -uv.y+3.*hiClouds));
    col = mix(col, cloudCol3, 0.5*smoothstep(0.,1., -uv.y+3.*hiClouds2));
    col = mix(col, vec3(0.9,0.6,0.3) * 100., 1./(1.+2000.*(q*q+q2*q2)));
    col += vec3(0.9,0.6,0.3) * 2./(1.+10.*sqrt(q*q+0.3*q2*q2));
    col = mix(col, 0.8*cloudCol, 0.8*smoothstep(0.,1., -2.*(uv.y+0.5)+midClouds));
    col = mix(col, 0.5*cloudCol, smoothstep(0.,1., -3.*(uv.y+0.8)+lowClouds));
    
    
    col = mix(col, col*pow(col/(col.r+col.g+col.b), vec3(dot(uv,uv)*0.3)), 0.2); // vignette
    col = pow(col, vec3(2.2));
    col = (col*(2.51*col+0.03))/(col*(2.43*col+0.59)+0.14); // tonemapping
    col = pow(col, vec3(1./2.2));
    
    col += 0.03 * (hash12(fragCoord)-0.5) * sqrt(iResolution.y/400.);

    // Output to screen
    fragColor = vec4(col,1.0);
}