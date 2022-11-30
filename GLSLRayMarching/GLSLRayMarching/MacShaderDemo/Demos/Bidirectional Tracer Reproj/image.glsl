// Fork of "Volumetric laser tracer" by michael0884. https://shadertoy.com/view/NtXSR4
// 2021-07-22 19:27:50

vec3 encodeSRGB(vec3 linearRGB)
{
    vec3 a = 12.92 * linearRGB;
    vec3 b = 1.055 * pow(linearRGB, vec3(1.0 / 2.)) - 0.055;
    vec3 c = step(vec3(0.0031308), linearRGB);
    return mix(a, b, c);
}

vec3 tone(vec3 c)
{
    c = XYZtosRGB(c);
    return tanh(encodeSRGB(c));
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec4 acc = texture(iChannel0, fragCoord/iResolution.xy);
    fragColor = vec4(tone(0.1*acc.xyz/acc.w), 1.0);
}