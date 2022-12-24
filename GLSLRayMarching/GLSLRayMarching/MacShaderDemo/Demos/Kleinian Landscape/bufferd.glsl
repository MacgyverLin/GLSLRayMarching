// Bokeh with fake color fringing + autofocus, anamorphic (including realistic "swirly" artifacts near edges)
//
// Ended up quite hairy/hacky from to trying to avoid edge/background bleed artifacts, but works pretty well.
// I originally wanted to do a separable version but didn't have enough buffers left, so it's fairly slow.

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 randomSeed = (fragCoord * .152 + iTime * 1500. + iMouse.x);
    float random = hash12(randomSeed)*PI*2.0;
    
    vec2 uv = fragCoord/iResolution.xy;
    
    float depth = textureLod(iChannel0, uv, 0.0).w*depthScale;
        
    // Autofocus
    float focalDepth = texelFetch(iChannel1, ivec2(0), 0).w;
    float focalDepthNew = min(min(min(textureLod(iChannel0, vec2(0.5, 0.25), 5.5).w*depthScale, textureLod(iChannel0, vec2(0.6, 0.5), 6.5).w*depthScale), textureLod(iChannel0, vec2(0.4, 0.5), 6.5).w*depthScale), textureLod(iChannel0, vec2(0.5, 0.5), 8.0).w*depthScale);
    focalDepth = mix(focalDepth, focalDepthNew, 0.05);
    
    vec2 offsetUv = vec2(0);
    vec4 foregroundColor = vec4(0);
    vec4 backgroundColor = vec4(0);
    vec4 midgroundColor = vec4(0);
    vec4 midgroundColorNoFringe = vec4(0);
    vec4 totalColor = vec4(0);
    
    const float steps = 32.0;
    const float stepsSmooth = 24.0;
    
    vec2 radiusClamp = vec2(bokehClamp);
    radiusClamp.y *= iResolution.x/iResolution.y;
    
    // Radius of circle of confusion based on depth at current pixel
    vec2 trueRadius = vec2(bokehScale);
    trueRadius.y *= iResolution.x/iResolution.y;
    trueRadius *= 1.0-focalDepth/depth;
  
    vec2 erodedRadius = vec2(1);
    vec2 smoothedRadius = vec2(0);
    
    const float additionalDilation = 1.25;
    const float searchMipLevel = 0.0;
    
    // Preprocess, estimate kernel size etc.
    for(float i = 0.0; i < stepsSmooth; i++)
    {   
        vec2 searchRadius = additionalDilation/**vec2(1.0/bokehAspectRatio, 1)*/*(radiusClamp*pow((i)/steps, 0.5));
        offsetUv = uv + searchRadius*vec2(sin(i*goldenAngle/* + random*/), cos(i*goldenAngle/* + random*/));
        
        float depthGathered = textureLod(iChannel0, offsetUv, searchMipLevel).w*depthScale;

        vec2 radiusGathered = vec2(bokehScale);
        radiusGathered.y *= iResolution.x/iResolution.y;
        radiusGathered *= 1.0-focalDepth/depthGathered;
        
        if(length(radiusGathered) >= length(radiusClamp))
        {
            radiusGathered = radiusClamp;
        }
        
        smoothedRadius += abs(radiusGathered);
        erodedRadius = min(abs(radiusGathered), erodedRadius);
    }
    smoothedRadius /= stepsSmooth;
    
    // Main blur
    // Limited radius
    vec2 radiusBias = vec2(bokehForceSharp);
    radiusBias.y *= iResolution.x/iResolution.y;
    vec2 radius = max(vec2(0), smoothedRadius-radiusBias);
    radius /= (1.0-bokehForceSharp);
    
    float totalBlur = 0.0;
    bool fringeValid = true;
    
    // Try to sample from lower-res mips to reduce noise, but don't want to go too low and introduce any visible blockiness
    float mipLevel = min(max(log2(length(erodedRadius*iResolution.xy/3.0))+0.5, 0.0), max(log2(length(min(smoothedRadius, trueRadius)*iResolution.xy/3.0))-1.5, 0.0));   
    mipLevel = min(mipLevel, 2.0);
  
    vec4 currentColor;
    vec4 colorFringed;
    float falloff = 1.0;
    float vignette = 1.0;
    if(length(radius) > 1.0/length(iResolution.xy))
    {
        for(float i = 0.5; i < steps; i++)
        {   
            vec2 offset = (radius*pow(i/steps, 0.5))*vec2(sin(i*goldenAngle + random), cos(i*goldenAngle + random));
            
            // "Swirly" bokeh
            offset *= ROT(atan((uv.x-0.5)/(iResolution.y/iResolution.x), uv.y-0.5)-PI);
            if(offset.y >= radius.y-3.0*(radius.y)*distance(uv, vec2(0.5)))
            {
                vignette = saturate(offset.y - (radius.y-3.0*(radius.y)*distance(uv, vec2(0.5))));
                vignette = saturate(1.0 - 0.8*vignette/radius.y);
                vignette = saturate(0.0001 + vignette);
                offset.y /= 1.0+saturate(1.0-vignette)/2.0;
                
            }
            offset *= ROT(-atan((uv.x-0.5)/(iResolution.y/iResolution.x), uv.y-0.5)+PI);

            offset *= vec2(1.0/bokehAspectRatio, 1);
            
            offsetUv = uv + offset;

            falloff = ((i+1.0)/steps);

            // Using dilated depth to reduce bleed
            float depthGathered = textureLod(iChannel2, offsetUv, 0.0).w*depthScale;

            vec2 radiusGathered = vec2(bokehScale);
            radiusGathered.y *= iResolution.x/iResolution.y;
            radiusGathered *= 1.0-focalDepth/depthGathered;
            radiusGathered *= vec2(1.0/bokehAspectRatio, 1);
          
            float distanceFromCenter = distance(offsetUv, uv);

            if((depthGathered > depth && length(trueRadius) < bokehScale/6.0 /*&& length(radiusGathered) > length(trueRadius)*/))
            {
                float factor = smoothstep(bokehScale/80.0, bokehScale/6.0, length(trueRadius));
                offsetUv = mix(uv, offsetUv, factor);
            }
            float curMipLevel = mipLevel;
            currentColor = textureLod(iChannel0, offsetUv, mipLevel);
            colorFringed = currentColor * 12.1*vec4(1.0, 0.16, 0.3, 1.0) * HUE(mod((0.2 + 0.3*float(i)/float(steps-1.0)), 1.0)) * falloff;
            totalBlur += 1.0*vignette;

            // Is the sample we gathered at a depth such that it would actually be scattered onto the current pixel?
            if((length(radiusGathered) < distanceFromCenter*0.66))
            {
                fringeValid = false;
                currentColor = vec4(0,0,0,1);
                colorFringed = vec4(0,0,0,1);
                totalBlur -= 1.0*vignette;
            }
             
            midgroundColor += mix(currentColor, colorFringed, bokehFringe)*vignette;
            midgroundColorNoFringe += currentColor*vignette;
        }
        // If we rejected some samples, the color fringe would become biased
        if(!fringeValid)
        {
            midgroundColor = midgroundColorNoFringe;
        }
        else
        {
            midgroundColor = mix(midgroundColorNoFringe, midgroundColor, smoothstep(0.0, 4.0/length(iResolution.xy), length(radius)));
        }
        if(totalBlur > 0.0)
        {
	        midgroundColor /= totalBlur;
        }
        else
        {
            midgroundColor = textureLod(iChannel0, uv, 0.0);
        }
    }
    else
    {
        midgroundColor = textureLod(iChannel0, uv, 0.0);
        // For debugging
        //midgroundColor = vec4(1,0,0,1)*textureLod(iChannel0, uv, 0.0)*steps;
    }
    
    totalColor += midgroundColor;
    
    // Bloom
    totalColor += bloomIntensity*getBloom(iChannel0, uv, iChannelResolution[0].xy, mod(iTime*13.8 + iMouse.x, 1024.0), bokehAspectRatio*iResolution.x/iResolution.y);
    
    // Auto exposure
    float exposure = texelFetch(iChannel1, ivec2(1, 0), 0).w;
    float exposureNew = length(textureLod(iChannel0, vec2(0.5, 0.5), 8.0).rgb)*3.0 + 0.5;
    exposure = mix(exposure, exposureNew, 0.05);  
    exposure = max(exposure, 0.0) + 0.001;
    totalColor /= exposure;

    float outAlpha = 0.0;
    
    if(ivec2(fragCoord) == ivec2(0,0))
    {
        // Store focal depth
        fragColor.w = focalDepth;
        return;
    }
    if(ivec2(fragCoord) == ivec2(1,0))
    {
        // Store exposure
        fragColor.w = exposure;
        return;
    }
    
    fragColor = vec4(totalColor.rgb, fragColor.w);
}