// Final post-processing
// 

// Sample scene color with FXAA, 0-1 range uvs
vec4 sceneColor(vec2 uv)
{
    vec4 outColor = vec4(FXAA(uv, iChannel1, 1.0/iResolution.xy), 1.0);
    
    return outColor;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	vec2 uv = fragCoord.xy / iResolution.xy;
    vec2 uvAspectCorrected = uv - 0.5;
    uvAspectCorrected = vec2(uvAspectCorrected.x*(iResolution.x/iResolution.y), uvAspectCorrected.y);
    uvAspectCorrected += 0.5;
    
    // Fringe
	const int fringeSamples = 6;
    float fringeAmount = fringeStrength*saturate(distance(uvAspectCorrected, vec2(0.5))-fringeStart);

    vec4 outColor = vec4(0);

    if(fringeAmount > 0.0)
    {
        for(int i = 0; i < fringeSamples; i++)
        {
            float fringe = 1.0+(float(i-fringeSamples/2)*fringeAmount)/float(fringeSamples);
            outColor += vec4(sceneColor(((uv-0.5)*fringe + 0.5)))*HUE(mod(0.85-1.0*float(i)/float(fringeSamples), 1.0));
        }
        outColor /= float(fringeSamples)*0.6;
    }
    else
    {
        outColor = vec4(sceneColor(uv));
    }

    
    // Vignette
    outColor *= pow(saturate(1.25-1.5*distance(uv, vec2(0.5))), 0.9);
    outColor += 0.001*(hash12(fragCoord+mod(iTime, 512.0)*0.21+0.1*iMouse.xy)-0.5);
    
    // Saturation / discolor highlights
    outColor = mix(outColor, vec4(1, 1, 0.66, 1)*vec4(dot(outColor.rgb, luma)), 1.0-saturate(1.05-dot(outColor.rgb, luma))); 
    
    // Saturation / discolor shadows
    outColor = mix(outColor, vec4(0.6, 0.8, 1, 1)*vec4(dot(outColor.rgb, luma)), saturate(0.3-3.0*dot(outColor.rgb, luma))); 
    
    // Tonemap + color grade
   	outColor = toneMap(outColor, vec3(0.95,0.95,0.85), vec3(1.15, 1.3, 1.3));
    
    // Ungraded tonemap
    //outColor = toneMap(outColor, vec3(1), vec3(1));
    
    fragColor = pow(outColor, vec4(1.0/gamma));
    
    // For debugging depth
    //fragColor = vec4(1.0-UDEPTH(fragCoord)*maxDepth);
    // For debugging GI
	//fragColor = textureLod(iChannel0, uv, 0.0);
}