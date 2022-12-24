void mainImage(out vec4 fragColor,in vec2 fragCoord)
{
    fragColor=texture(iChannel0,fragCoord/iResolution.xy);
}

