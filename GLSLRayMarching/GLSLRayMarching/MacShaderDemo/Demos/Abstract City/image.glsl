void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec4 data = texelFetch(iChannel0, ivec2(fragCoord), 0);
    vec3 col = data.rgb/data.a;
      
    // color grade
    col = pow(col, vec3(.8,.95,.86));
    col = mix(col, dot(col, vec3(1))/vec3(3), -.75); // boost the saturation
    
    // vignette
    vec2 p = fragCoord/iResolution.xy;
    col *= .2+.8*pow(64. * p.x*p.y*(1.-p.x)*(1.-p.y), .1);

    fragColor = vec4(col,1.0);
}