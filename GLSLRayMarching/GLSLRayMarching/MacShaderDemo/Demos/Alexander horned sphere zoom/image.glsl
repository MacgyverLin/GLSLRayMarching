#define WO_0 (1.0/8.0)
#define WO_1 (1.0/8.0)

#define FOG_MIN 0.0
#define FOG_MAX 1.0
#define FOG_COLOR vec3(0.325, 0.3, 0.375)

float isInInterval(float a, float b, float x) {
    return step(a, x) * (1.0 - step(b, x));
}

void outlineCheck(in vec2 uv, in float weight, in float aBase, inout float n) {
    vec4 data = textureLod(iChannel0, uv, 0.0);
    float depth = data.a;

    n += weight * (1.0 - isInInterval(aBase-0.004, aBase+0.004, depth));
}

float outline(in vec2 uv, in float aBase) {
    vec2 uvPixel = 1.0/iResolution.xy;
    float n = 0.0;

    outlineCheck(uv + vec2( 1.0, 0.0)*uvPixel, WO_1, aBase, n);
    outlineCheck(uv + vec2( 0.0, 1.0)*uvPixel, WO_1, aBase, n);
    outlineCheck(uv + vec2( 0.0,-1.0)*uvPixel, WO_1, aBase, n);
    outlineCheck(uv + vec2(-1.0, 0.0)*uvPixel, WO_1, aBase, n);

    outlineCheck(uv + vec2( 1.0, 1.0)*uvPixel, WO_0, aBase, n);
    outlineCheck(uv + vec2( 1.0,-1.0)*uvPixel, WO_0, aBase, n);
    outlineCheck(uv + vec2(-1.0, 1.0)*uvPixel, WO_0, aBase, n);
    outlineCheck(uv + vec2(-1.0,-1.0)*uvPixel, WO_0, aBase, n);

    return n;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = fragCoord / iResolution.xy;

    vec4 data = textureLod(iChannel0, uv, 0.0);
    float depth = data.a;

    float fogAmount = pow(mix(FOG_MIN, FOG_MAX, depth), 3.0);
    vec3 finalColor = mix(data.rgb, FOG_COLOR, fogAmount);

    float outlineAmount = outline(uv, depth);
    vec3 outlineColor = vec3(0.0);
    finalColor = mix(finalColor, outlineColor, outlineAmount*0.8);

    vec2 radv = uv - vec2(0.5);
    float dCorner = length(radv);
    float vignetteFactor = 1.0 - mix(0.0, 0.5, smoothstep(0.2, 0.707, dCorner));
    finalColor *= vignetteFactor;

    fragColor = vec4(finalColor, 1.0);
}
