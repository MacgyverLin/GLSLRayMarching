void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = fragCoord.xy / iResolution.xy;

    vec3 color = pow(texture(iChannel0, uv).rgb, vec3(1.0 / 2.2));
    fragColor = vec4(color, 1.0);
    /*
    vec3 color = pow(texture(iChannel0, uv).rgb * colorRange, vec3(2.2));
    color = pow(color, vec3(2.2));
    color += pow(getBloom(uv), vec3(2.2));
    color = pow(color, vec3(1.0 / 2.2));

    color = jodieReinhardTonemap(color);

    fragColor = vec4(color,1.0);
    */
}