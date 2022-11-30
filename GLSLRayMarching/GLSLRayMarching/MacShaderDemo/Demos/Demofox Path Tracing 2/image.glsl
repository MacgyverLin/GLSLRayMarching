void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec3 color = texture(iChannel0, fragCoord / iResolution.xy).rgb;

    // apply exposure (how long the shutter is open)
    color *= c_exposure;

    // convert unbounded HDR color range to SDR color range
    color = ACESFilm(color);

    // convert from linear to sRGB for display
    color = LinearToSRGB(color);
    
    fragColor = vec4(color, 1.0f);
}