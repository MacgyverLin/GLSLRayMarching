//Post-processing.

// Narkowicz 2015, "ACES Filmic Tone Mapping Curve"
vec3 Tonemap_ACES(const vec3 x) {
    const float a = 2.51;
    const float b = 0.03;
    const float c = 2.43;
    const float d = 0.59;
    const float e = 0.14;
    return (x * (a * x + b)) / (x * (c * x + d) + e);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = fragCoord / iResolution.xy;
    vec3 color = texture(iChannel0, uv).rgb;

    color = Tonemap_ACES(color);
    color = pow(color, vec3(0.4545));

    fragColor = vec4(color, 1.0);
}