
void mainImage(out vec4 fragColor, in vec2 fragCoord){
    fragColor = render(fragCoord.xy, iTime, iResolution.xy, iChannel0);
}

