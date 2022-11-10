
// taste of noise 7 by leon denise 2021/10/14
// result of experimentation with organic patterns
// using code from Inigo Quilez, David Hoskins and NuSan
// thanks to Fabrice Neyret for code reviews
// licensed under hippie love conspiracy

// return color from pixel coordinate
void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    fragColor = texture(iChannel0, fragCoord.xy/iResolution.xy);
}

