void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = fragCoord/iResolution.xy;

    // Time varying pixel color
    vec3 col = texture(iChannel0, uv).rgb;

    // Output to screen
    fragColor = vec4(col,1.0);
}