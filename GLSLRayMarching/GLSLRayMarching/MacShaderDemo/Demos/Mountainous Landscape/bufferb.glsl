#pragma optionNV(unroll none)
// This buffer is only changed on screen resolution change. When that happens, the mountain heightmap texture is refreshed once.

float getHeight(vec2 pos){
    float seed = texelFetch( iChannel0, ivec2(CHANGE_SEED, 0), 0 ).x * 0.02;
#if 0
    return layeredPerlinNoise(/*vec3 pos=*/vec3(pos*5., seed), /*int numLayers=*/8, /*int seed=*/0, /*int tileSize=*/5)*4.;
#else
    const int size = 4;
    const int numLayers = 8;
    float noiseX = layeredPerlinNoise(/*vec3 pos=*/vec3(pos*float(size), seed), /*int numLayers=*/numLayers, /*int seed=*/0, /*int tileSize=*/size);
    float noiseY = layeredPerlinNoise(/*vec3 pos=*/vec3(pos*float(size), seed), /*int numLayers=*/numLayers, /*int seed=*/1, /*int tileSize=*/size);
    pos += vec2(noiseX, noiseY)*0.2;
    return layeredPerlinNoise(/*vec3 pos=*/vec3(pos*float(size), seed), /*int numLayers=*/numLayers, /*int seed=*/2, /*int tileSize=*/size)*4.;
#endif
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec4 prevColor = texelFetch(iChannel1, ivec2(fragCoord), 0).xyzw;
    if(texelFetch( iChannel0, ivec2(DO_BUFFER_UPDATE,0), 0 ).x > 0.5){
        // Only run once every time the screen resolution or seed is changed.
        vec2 uv = (fragCoord-0.5*iResolution.xy);
        uv.x /= iResolution.y;
        uv.y /= iResolution.y;
		
        // Generate mountain noise.
        vec2 e = vec2(0, 1./iResolution.y);
        float noise[4];
        vec2 positions[4] = vec2[](
        	uv, uv + e.yx, uv + e.xy, uv + e.yy
        );
        for(int i=0; i<4; i++){
            noise[i] = getHeight(positions[i]);
        }
        
        //
        prevColor = vec4(noise[0], noise[1], noise[2], noise[3]);
        
    }
    
    fragColor = prevColor;
}


































































