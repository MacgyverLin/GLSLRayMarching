// realistic color range
vec3 filmic(vec3 x) {
    float a = 2.51;
    float b =  .03;
    float c =  2.1;
    float d =   .7;
    float e =  .12;
    return (x*(a*x+b))/(x*(c*x+d)+e);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec4 data = texelFetch(iChannel0, ivec2(fragCoord), 0);
    vec3 col = data.rgb/data.a;
    
    col = pow(col,vec3(.4545)); // gamma correction
    col = filmic(col);
  
    // vignette
    vec2 p = fragCoord/iResolution.xy;
    col *= .5+.5*clamp(pow(100. * p.x*p.y*(1.-p.x)*(1.-p.y), .1), 0., 1.);
                    
    // output
    fragColor = vec4(col,1.0);
}