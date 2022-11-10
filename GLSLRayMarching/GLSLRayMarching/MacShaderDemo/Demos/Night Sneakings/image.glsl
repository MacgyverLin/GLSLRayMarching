// Comment these lines to disable the effect
#define BLOOM
#define GRAIN

#define BLOOM_SAMPLES 7
float threshold = 0.34;

vec4 bloom(vec2 uv)
{
    vec4 bloom = vec4(0.0);
    vec4 col = vec4(0.0);
    
    for (int x = -BLOOM_SAMPLES; x < BLOOM_SAMPLES; x++)
    for (int y = -BLOOM_SAMPLES; y < BLOOM_SAMPLES; y++)
    {
        col = texture(iChannel0, uv + vec2(x, y) * vec2(.0011));
        float val = ((0.3 * col.r) + (0.59 * col.g) + (0.11 * col.b));
        if (val < threshold) col = vec4(0.0);
        
        bloom += col;
    }
    
    bloom /= float((2 * BLOOM_SAMPLES) * (2 * BLOOM_SAMPLES));
    
    return bloom;
}


void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord/iResolution.xy;
    
    
    vec4 color = texture(iChannel0, uv);
#ifdef BLOOM
    color += bloom(uv) * 0.7;
#endif

#ifdef GRAIN
    vec2 guv = uv + noise(vec2(iTime)) + noise(vec2(uv));
    float h = hash12(guv)*0.3+0.7;
    color = color * mix(1.0, h, clamp(color.y, 0.7, 1.0));
#endif
    
    // gamma
    color.xyz = pow( color.xyz, vec3(0.735) );
    
    fragColor = color;
}