float DecodeFrame()
{
    return texelFetch(iChannel0, ivec2(0,0), 0).r;
}

// ACES Tonemap: https://github.com/TheRealMJP/BakingLab/blob/master/BakingLab/ACES.hlsl 
const mat3 ACESInputMat  = mat3(0.59719, 0.07600, 0.02840,    0.35458, 0.90834, 0.13383,    0.04823,  0.01566, 0.83777);
const mat3 ACESOutputMat = mat3(1.60475,-0.10208,-0.00327,   -0.53108, 1.10813,-0.07276,   -0.07367, -0.00605, 1.07602);
vec3 RRTAndODTFit(vec3 v) { return (v * (v + 0.0245786) - 0.000090537) / (v * (0.983729 * v + 0.4329510) + 0.238081); }
vec3 ACESFitted(vec3 color) { return clamp(ACESOutputMat * RRTAndODTFit(ACESInputMat * color), 0.0, 1.0); }

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord/iResolution.xy; // Normalized pixel coordinates (from 0 to 1)
    vec3 col = texture(iChannel0, uv).rgb / float(DecodeFrame()+1.); // Divide accumulation buffer by num frames
    col *= 1.;
    col = ACESFitted(col); // Tonemap
    col = pow(col, vec3(0.4545)); // Gamma 1/2.2
   	//col = vec3(0.2126*col.r + 0.7152*col.g + 0.0722*col.g); // Luminance
    fragColor = vec4(col, 1.);
}