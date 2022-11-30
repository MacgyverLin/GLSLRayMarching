// See Buffer A

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    fragColor = pow(texelFetch(iChannel0, ivec2(fragCoord), 0), vec4(1.0 / 2.2));
}