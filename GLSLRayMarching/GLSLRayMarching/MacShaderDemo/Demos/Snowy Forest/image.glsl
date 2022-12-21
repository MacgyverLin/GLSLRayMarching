// tonemap
vec3 filmic(vec3 x) {
    float a = 2.51;
    float b =  .03;
    float c = 2.43;
    float d =  .59;
    float e =  .14;
    return (x*(a*x+b))/(x*(c*x+d)+e);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    // normalized pixel coordinates
    vec2 p = fragCoord/iResolution.xy;
    
    // base texture with subtle CA
    vec2 off = (p-.5)*.0035; // CA offset
    vec3 col = vec3(texture(iChannel0, p+off).r,
                    texture(iChannel0, p).g,
                    texture(iChannel0, p-off).b);
                    
    col = pow(col, vec3(.4545)); // gamma correction
    col = filmic(col);
    col = col*.25+.75*col*col*(3.-2.*col); // contrast
    col = pow(col, vec3(.83,1,.75)); // color grade
    col = col*vec3(1.2,1.1,1)-vec3(.1,.05,0); // color contrast
        
    // vignette
    col *= .4+.6*pow(64. * p.x*p.y*(1.-p.x)*(1.-p.y), .1);
    
    //col *= .96+.1*sin(p.y*1000.+iTime); // old CRT effect
    
    // output
    fragColor = vec4(col,1.0);
}