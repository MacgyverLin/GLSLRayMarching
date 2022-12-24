
float FXAAamt = 0.5;




void mainImage(out vec4 fragColor, vec2 fragCoord){
    vec2 p = fragCoord.xy/iResolution.xy;
    vec2 pp = 1. / iResolution.xy;
    vec4 color = texture(iChannel0, vec2(fragCoord.xy * pp));
    vec3 luma = vec3(.299, 0.587, 0.114);
    
    float lumaNW = dot(texture(iChannel0, (fragCoord.xy + vec2(-1.0, -1.0)*FXAAamt) * pp).xyz, luma);
    float lumaNE = dot(texture(iChannel0, (fragCoord.xy + vec2(1.0, -1.0)*FXAAamt) * pp).xyz, luma);
    float lumaSW = dot(texture(iChannel0, (fragCoord.xy + vec2(-1.0, 1.0)*FXAAamt) * pp).xyz, luma);
    float lumaSE = dot(texture(iChannel0, (fragCoord.xy + vec2(1.0, 1.0)*FXAAamt) * pp).xyz, luma);
    float lumaM  = dot(color.xyz,  luma);
    float lumaMin = min(lumaM, min(min(lumaNW, lumaNE), min(lumaSW, lumaSE)));
    float lumaMax = max(lumaM, max(max(lumaNW, lumaNE), max(lumaSW, lumaSE)));

    vec2 dir = vec2(-((lumaNW + lumaNE) - (lumaSW + lumaSE)), ((lumaNW + lumaSW) - (lumaNE + lumaSE)));

    float dirReduce = max((lumaNW + lumaNE + lumaSW + lumaSE) *
                          (0.25 * (1.0/8.0)), (1.0/128.0));

    float rcpDirMin = 2.5 / (min(abs(dir.x), abs(dir.y)) + dirReduce);
    dir = min(vec2(8.0, 8.0),
              max(vec2(-8.0, -8.0),
              dir * rcpDirMin)) * pp;

    vec3 rgbA = 0.5 * (
        texture(iChannel0, fragCoord.xy * pp + dir * (1.0 / 3.0 - 0.5)).xyz +
        texture(iChannel0, fragCoord.xy * pp + dir * (2.0 / 3.0 - 0.5)).xyz);
    vec3 rgbB = rgbA * 0.5 + 0.25 * (
        texture(iChannel0, fragCoord.xy * pp + dir * -0.5).xyz +
        texture(iChannel0, fragCoord.xy * pp + dir * 0.5).xyz);

    float lumaB = dot(rgbB, luma);
    if ((lumaB < lumaMin) || (lumaB > lumaMax)){
        fragColor = vec4(rgbA, color.w);
    } else {
        fragColor = vec4(rgbB, color.w);
    }

}