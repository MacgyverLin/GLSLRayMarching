// Temporal AA / denoise
//
// Lots more terrible ad hoc corrections to reduce ghosting, "fireflies" etc.

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{    
    vec2 uv = fragCoord/iResolution.xy;
    vec2 uvAspectCorrected = vec2(uv.x*(iResolution.x/iResolution.y), uv.y);
       
    vec2 fragCoordDejittered = fragCoord;
    vec2 uvDejittered = uv;
    
    vec3 currentDirect = UDIRECT_ILLUMINATION(fragCoordDejittered).rgb*hdrScale;
    currentDirect = max(vec3(0), currentDirect);
    
    vec3 currentIndirect = vec3(0);
    
    currentIndirect = UBOUNCE_LIGHT(fragCoordDejittered).rgb*hdrScale;
    currentIndirect = max(vec3(0), currentIndirect);
    currentIndirect = clamp(currentIndirect, vec3(0.0001), vec3(hdrScale));
       
    float currentDepth = UDEPTH(fragCoordDejittered)*depthScale;
    
    float currentDepthMax = 0.0;
    currentDepthMax = max(UDEPTH(fragCoordDejittered+vec2(1,0))*depthScale, currentDepthMax);
    currentDepthMax = max(UDEPTH(fragCoordDejittered+vec2(-1,0))*depthScale, currentDepthMax);
    currentDepthMax = max(UDEPTH(fragCoordDejittered+vec2(0,1))*depthScale, currentDepthMax);
    currentDepthMax = max(UDEPTH(fragCoordDejittered+vec2(0,-1))*depthScale, currentDepthMax);
    currentDepthMax = max(UDEPTH(fragCoordDejittered+vec2(1,1))*depthScale, currentDepthMax);
    currentDepthMax = max(UDEPTH(fragCoordDejittered+vec2(-1,1))*depthScale, currentDepthMax);
    currentDepthMax = max(UDEPTH(fragCoordDejittered+vec2(1,-1))*depthScale, currentDepthMax);
    currentDepthMax = max(UDEPTH(fragCoordDejittered+vec2(-1,-1))*depthScale, currentDepthMax);

    float currentDepthMin = 100000.0;
    currentDepthMin = min(UDEPTH(fragCoordDejittered+vec2(1,0))*depthScale, currentDepthMin);
    currentDepthMin = min(UDEPTH(fragCoordDejittered+vec2(-1,0))*depthScale, currentDepthMin);
    currentDepthMin = min(UDEPTH(fragCoordDejittered+vec2(0,1))*depthScale, currentDepthMin);
    currentDepthMin = min(UDEPTH(fragCoordDejittered+vec2(0,-1))*depthScale, currentDepthMin);
    currentDepthMin = min(UDEPTH(fragCoordDejittered+vec2(1,1))*depthScale, currentDepthMin);
    currentDepthMin = min(UDEPTH(fragCoordDejittered+vec2(-1,1))*depthScale, currentDepthMin);
    currentDepthMin = min(UDEPTH(fragCoordDejittered+vec2(1,-1))*depthScale, currentDepthMin);
    currentDepthMin = min(UDEPTH(fragCoordDejittered+vec2(-1,-1))*depthScale, currentDepthMin);
    
    float oldDepthMax = 0.0;
    oldDepthMax = max(UDEPTH_CHANNEL1(fragCoord+vec2(1,0)), oldDepthMax);
    oldDepthMax = max(UDEPTH_CHANNEL1(fragCoord+vec2(-1,0)), oldDepthMax);
    oldDepthMax = max(UDEPTH_CHANNEL1(fragCoord+vec2(0,1)), oldDepthMax);
    oldDepthMax = max(UDEPTH_CHANNEL1(fragCoord+vec2(0,-1)), oldDepthMax);
    oldDepthMax = max(UDEPTH_CHANNEL1(fragCoord+vec2(1,1)), oldDepthMax);
    oldDepthMax = max(UDEPTH_CHANNEL1(fragCoord+vec2(-1,1)), oldDepthMax);
    oldDepthMax = max(UDEPTH_CHANNEL1(fragCoord+vec2(1,-1)), oldDepthMax);
    oldDepthMax = max(UDEPTH_CHANNEL1(fragCoord+vec2(-1,-1)), oldDepthMax);


    float oldDepthMin = 100000.0;
    oldDepthMin = min(UDEPTH_CHANNEL1(fragCoord+vec2(1,0)), oldDepthMin);
    oldDepthMin = min(UDEPTH_CHANNEL1(fragCoord+vec2(-1,0)), oldDepthMin);
    oldDepthMin = min(UDEPTH_CHANNEL1(fragCoord+vec2(0,1)), oldDepthMin);
    oldDepthMin = min(UDEPTH_CHANNEL1(fragCoord+vec2(0,-1)), oldDepthMin);
    oldDepthMin = min(UDEPTH_CHANNEL1(fragCoord+vec2(1,1)), oldDepthMin);
    oldDepthMin = min(UDEPTH_CHANNEL1(fragCoord+vec2(-1,1)), oldDepthMin);
    oldDepthMin = min(UDEPTH_CHANNEL1(fragCoord+vec2(1,-1)), oldDepthMin);
    oldDepthMin = min(UDEPTH_CHANNEL1(fragCoord+vec2(-1,-1)), oldDepthMin);
    
    ray currentRay;
    // Current frame ray direction, camera ray and direction must match Buffer A
    
    
    float mouseLocation = 0.1;
    #ifdef ANIMATE_CAMERA
	    mouseLocation += /*0.01*iMouse.x+*/ + iTime/9.0;
    #endif
    
    #ifdef INTERACTIVE
	    mouseLocation += 0.002*iMouse.x;
    #endif
  
    currentRay.origin = vec3( 2.8*cos(0.1+.33*mouseLocation), 0.5 + 0.15*cos(0.37*mouseLocation), 2.8*cos(0.5+0.35*mouseLocation) );
    currentRay.direction = stereographicPlaneToSphere((vec2(uvAspectCorrected) - 0.5)/1.5);
    currentRay.direction.xyz = normalize(currentRay.direction.xzy); 

    // Recover world position of current frame intersection point from ray direction
    float pixelDepthForReprojection = UDEPTH(uv*iResolution.xy)*depthScale;
    vec3 currentWorldPosition = normalize(currentRay.direction)*pixelDepthForReprojection*2.0 + currentRay.origin;

    // Previous frame data
    vec3 prevRayOrigin = texelFetch(iChannel1, ivec2(0), 0).xyz;
    vec3 prevWorldPosition = currentWorldPosition+(currentRay.origin - prevRayOrigin);
    vec3 prevRayDirection = prevWorldPosition-prevRayOrigin;
    float prevPixelDepth = length(prevRayDirection);
    prevRayDirection = normalize(prevRayDirection);
    
    // Find warped UV coords based on world space position of this pixel at previous frame
    prevRayDirection.xzy = prevRayDirection.xyz;
    vec2 prevUv = stereographicSphereToPlane(normalize(prevRayDirection))*1.5 + 0.5;
    prevUv = vec2(prevUv.x/(iResolution.x/iResolution.y), prevUv.y);
       
    // Store temporal reprojection parameters
    if(ivec2(fragCoord) == ivec2(0,0))
    {
        // Store latest camera pos for reprojection
        fragColor.xyz = currentRay.origin;
        return;
    }
    if(ivec2(fragCoord) == ivec2(1,0))
    {
        // Copy second-latest camera pos for reprojection
        fragColor.xyz = texelFetch(iChannel1, ivec2(0,0), 0).xyz;
        return;
    }
    
    // Sample history color with Catmull-Rom filter
    // since bilinear results in too much blurring from repeated re-sampling of reprojected history
    vec3 oldColor = textureLod(iChannel1, prevUv, 0.0).rgb;
    vec3 oldColorSharp = SampleTextureCatmullRom(iChannel1, prevUv, iChannelResolution[1].xy, 0.0, 0).rgb;
   
    // HW filtering is fine for depth
    float oldDepth = textureLod(iChannel1, prevUv, 0.0).w*depthScale;
    
    bool offscreen = false;
    float mixWeight = 0.0;
    
    // Don't read offscreen pixels or region reserved for non-color (camera) data
    vec2 borderPadding = 1.0*vec2(1.0/(ceil(iResolution.x)), 1.0/(ceil(iResolution.y)));
    if(prevUv.x <= borderPadding.x || prevUv.y <= borderPadding.y || prevUv.x >= 1.0 - borderPadding.x || prevUv.y >= 1.0 - borderPadding.y ||
       (floor(prevUv.y*iResolution.y) <= 1.0 && floor(prevUv.x*iResolution.x) <= 10.0))
    {
        offscreen = true;
    }
	
    // TODO dilate motion vector, i.e. take longest in neighborhood?
    // BUG for some reason this seems to behave differently based on overall distance to camera -- precision issue?
    mixWeight = max(0.0,(50.0*(sqrt(currentDepth)-sqrt(oldDepth)-0.01)));
    //mixWeight += saturate(200.0*(currentDepth-oldDepth));
    mixWeight = (mixWeight + 0.04);

    vec2 biasUv = vec2(0);
   	
    mixWeight = saturate(mixWeight);

    // Don't use Catmull-Rom for newly-unoccluded regions since they are extremely noisy
    if(mixWeight < 0.1 && !offscreen)
    {
        oldColor = oldColorSharp;
    }
    
    if(offscreen)
    {
       mixWeight = 1.0;
    }
    
    #ifdef CLAMP_INDIRECT      
        vec3 blurredGi1 = textureLod(iChannel2, uvDejittered, 1.5).rgb*hdrScale;
        currentIndirect = min(currentIndirect, blurredGi1 + 0.01);
        currentIndirect = max(currentIndirect, blurredGi1 - 0.02);

        vec3 blurredGi2 = textureLod(iChannel2, uvDejittered, 2.5).rgb*hdrScale;
        currentIndirect = min(currentIndirect, blurredGi2 + 0.03);
        currentIndirect = max(currentIndirect, blurredGi2 - 0.04);

        if(mixWeight > 0.15 || offscreen)
        {
            // Blur indirect pixels more when we don't have history data
            vec3 blurredGi3 = textureLod(iChannel2, uvDejittered, 4.5).rgb*hdrScale;
            currentIndirect = min(currentIndirect, blurredGi3 + 0.005);
            currentIndirect = max(currentIndirect, blurredGi3 - 0.04);

            vec3 blurredGi4 = textureLod(iChannel2, uvDejittered, 5.5).rgb*hdrScale;
            currentIndirect = min(currentIndirect, blurredGi4 + 0.01);
            currentIndirect = max(currentIndirect, blurredGi4 - 0.08);

            // For debugging. Also happens to look neat.
            //currentIndirect = vec3(1,0,0);
        }
        else
        {
            vec3 blurredGi5 = textureLod(iChannel2, uvDejittered, 4.5).rgb*hdrScale;
            currentIndirect = min(currentIndirect, blurredGi5 + 0.08);
            currentIndirect = max(currentIndirect, blurredGi5 - 0.1);
        }
    #endif
    
    //currentDirect += bloomIntensity*getBloom(iChannel1, prevUv, iChannelResolution[0].xy, mod(iTime*139.8 + iMouse.x, 4096.0), bokehAspectRatio*iResolution.x/iResolution.y).rgb;
       
    vec3 combinedColor = mix(oldColor, currentDirect + currentIndirect, mixWeight);
    
    if(currentDepth >= maxDepth - 0.01)
    {
        vec3 sunDirection = initialSunDirection;
        vec3 sunColor = initialSunColor;
        #ifdef ANIMATE_SUN
            sunDirection.yz *= ROT(mod(iTime*0.05, PI*2.0));
            sunDirection.xy *= ROT(sin(mod(iTime*0.025, PI*2.0)));
            // "moon"
            if (sunDirection.y <= 0.0)
            {
                float colorMix = smoothstep(0.0, -0.2, sunDirection.y);
                if(sunDirection.y <= -0.2)
                {
                    sunDirection.y += 0.2;
                    sunDirection.y *= -1.0;
                    sunDirection.y -= 0.2;
                }
                sunColor = mix(sunColor, moonColor, colorMix);
            }
        #endif

        combinedColor.rgb = getSky(currentRay, sunDirection, sunColor);
    }
    
    combinedColor = clamp(combinedColor, vec3(0.0001), 2.0*vec3(hdrScale));



    // For debugging
    //float minMaxVisualize = distance(currentDepthMin, oldDepthMin) + distance(currentDepthMax, oldDepthMax);
 
    float combinedDepth = currentDepth/depthScale;
    
    // For debugging
    //fragColor = vec4(vec3(minMaxVisualize), combinedDepth);
    //fragColor = vec4(vec3(mixWeight), combinedDepth);
    //fragColor = vec4(vec3(biasUv, 0.0), combinedDepth);
    //fragColor = vec4(vec3(distance(oldDepthMax, oldDepthMin)), combinedDepth);
    //fragColor = vec4(vec3(distance(currentDepthMax, currentDepthMin)), combinedDepth);
    //fragColor = vec4(blurGi(uv), combinedDepth);
    //fragColor = vec4(currentDirect + currentIndirect, combinedDepth);
    
    fragColor = vec4(combinedColor, combinedDepth);
}