


// depth of field function, thanks to iq
vec4 dof(sampler2D sam, vec2 p) {
    const float focus = 3.5;
    vec4 col = vec4(0);
    
    for(int i=-5; i<=5; i++) {
    for(int j=-5; j<=5; j++) {
        vec2 of = vec2(i,j);
        vec4 tmp = texture(iChannel0, p+of*.002); 
        float depth = tmp.w;
        vec3 color = tmp.xyz;
        float coc = 8.*abs(depth-focus)/depth;
        if(dot(of,of) < coc*coc) {
            float w = 1./(coc*coc); 
            col += vec4(color*w,w);
        }
    }
    }
    return col/col.a;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 p = fragCoord/iResolution.xy;
    
    vec3 col = dof(iChannel0, p).rgb;
    
    col = pow(col, vec3(.4545)); // gamma correction
    col = vec3(1)*dot(col,vec3(1))/3.; // rgb to greyscale
    col = col*2.-.5; // contrast
    col = clamp(col, 0., 1.);
    col = pow(col,vec3(.95,1.,.9)); // color curve
    
    col = clamp(col,0.,1.);
    // vignette
    col *= clamp(pow(64. * p.x*p.y*(1.-p.x)*(1.-p.y), .1), 0., 1.);    
    
    fragColor = vec4(col,1.0);
}