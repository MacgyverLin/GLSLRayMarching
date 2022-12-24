// Final indirect light 
//
// Makes use of what we computed in Buffer A.
// Recalculates screen space normals (they couldn't be stored properly in the buffer packing scheme without precision issues).

// Recalculate world position from depth, texture coordinate for reconstructing normal
// TODO optimize, or use a simpler camera projection
vec3 reCalcWorldPosition(vec2 uv)
{
    vec2 uvAspectCorrected = vec2(uv.x*(iResolution.x/iResolution.y), uv.y);
    ray currentRay;
    
    // Current frame ray direction, camera ray and direction must match Buffer A

    float mouseLocation = 0.1;
    #ifdef ANIMATE_CAMERA
    mouseLocation += iTime/9.0;
    #endif

    #ifdef INTERACTIVE
    mouseLocation += 0.002*iMouse.x;
    #endif

    currentRay.origin = vec3( 2.8*cos(0.1+.33*mouseLocation), 0.5 + 0.15*cos(0.37*mouseLocation), 2.8*cos(0.5+0.35*mouseLocation) );
    currentRay.direction = stereographicPlaneToSphere((vec2(uvAspectCorrected) - 0.5)/1.5);
    currentRay.direction.xyz = normalize(currentRay.direction.xzy); 

    
    // Recover world position of current frame intersection point from ray direction
    float pixelDepthForReprojection = UDEPTH(uv*iResolution.xy)*depthScale;
    return (currentRay.direction)*pixelDepthForReprojection + currentRay.origin;
}

// Reconstructs screen space normal for deferred rendering. Bad.
vec3 reCalcNormalFast(vec2 uv)
{
    float offsetPixel = 1.0;
    
    vec3 center = reCalcWorldPosition(uv);
    
    // Only sample two points, but vary which ones per frame in the hopes that temporal AA will smooth out artifacts
    if(iFrame % 4 == 0)
    {
        vec3 up = reCalcWorldPosition(uv+vec2(0, offsetPixel/iResolution.y));
        vec3 right = reCalcWorldPosition(uv+vec2(offsetPixel/iResolution.x, 0));
    
        return normalize(cross(up-center, center-right));
    }
    else if(iFrame % 4 == 1)
    {
        vec3 down = reCalcWorldPosition(uv+vec2(0, -offsetPixel/iResolution.y));
        vec3 left = reCalcWorldPosition(uv+vec2(-offsetPixel/iResolution.x, 0));

        return normalize(cross(center-down, left-center));
    }
    else if(iFrame % 4 == 2)
    {
        vec3 up = reCalcWorldPosition(uv+vec2(0, offsetPixel/iResolution.y));
        vec3 left = reCalcWorldPosition(uv+vec2(-offsetPixel/iResolution.x, 0));

        return normalize(cross(up-center, left-center));
    }
    else
    {
        vec3 down = reCalcWorldPosition(uv+vec2(0, -offsetPixel/iResolution.y));
        vec3 right = reCalcWorldPosition(uv+vec2(offsetPixel/iResolution.x, 0));

        return normalize(cross(center-down, center-right));
    }
}

// Reconstructs normal for deferred rendering using distance function. Slow.
vec3 reCalcNormalSlow(vec2 uv)
{
    float offsetPixel = 1.0;
    vec3 center = reCalcWorldPosition(uv);
    return calcNormal(center);
}

// Get the indirect lighting from a "virtual point light" as stored in Buffer A
vec3 getVirtualLightContribution(vec2 uv, vec2 offsetUv, vec3 baseColor, float roughness, vec3 camHitNormal, vec3 camHitPosition, out float dotProduct, out float brdfRef)
{
    // Avoid hotspots from lights nearly touching geometry
    float minDistance = 0.2;
    
    vec3 lightPosition = UBOUNCE_POSITION(offsetUv*iResolution.xy).xyz*depthScale;
    
    // Diffuse
    float diffuse = saturate(dot(normalize(camHitNormal), normalize(lightPosition - camHitPosition)))*0.9;
    float mouseLocation = 0.1;
    #ifdef ANIMATE_CAMERA
    	mouseLocation += iTime/9.0;
    #endif

    #ifdef INTERACTIVE
    	mouseLocation += 0.002*iMouse.x;
    #endif
    vec3 camOrigin = vec3( 2.8*cos(0.1+.33*mouseLocation), 0.5 + 0.15*cos(0.37*mouseLocation), 2.8*cos(0.5+0.35*mouseLocation) );
    float specular = GGX(normalize(camHitNormal), -normalize(camHitPosition - camOrigin), normalize(lightPosition - camHitPosition), roughness, 0.1);
    
    
    float lightDistance = max(distance(lightPosition, camHitPosition), minDistance);
    float lightDistance2 = lightDistance*lightDistance;
    dotProduct = dot(reCalcNormalFast(uv), reCalcNormalFast(offsetUv));
    
    brdfRef = diffuse + specular;
    
    return ((UBOUNCE_COLOR(offsetUv*iResolution.xy).rgb))/lightDistance2;
}

// This is where we accumulate the "point lights" from neighboring pixels that we stored in Buffer A
// Requires some ad hoc corrections since this causes us to miss some occlusion/shadows, but since everything is localized to nearby pixels it works pretty OK?
vec3 accumulateLights(vec2 uv)
{
    int steps = 32;
    vec2 radius = max(vec2(.01), 13.0/iResolution.xy);
    const float goldenAngle = 2.4;    
    
    float depth = UDEPTH(uv*iResolution.xy)*depthScale;
    vec3 baseColor = UBASE_COLOR(uv*iResolution.xy)/hdrScale;
    vec3 camHitNormal = reCalcNormalSlow(uv);
    vec3 camHitPosition = reCalcWorldPosition(uv);
    
    vec2 offsetUv = uv;
    vec3 sum = vec3(0);
    float totalBlur = 0.0;
    float weight = 1.0; 
    float dotProduct = 1.0;
    float brdfRef = 1.0;
    // Counterproductive to apply pixel jitter to low-discrepency points...
    //float seed = nrand(uv*iResolution.xy + vec2(mod(iTime*131.5,4096.0), mod(iTime*535.1,4096.0)));
    float seed = hash11(mod(iTime*33.1, 1024.0));
    mat2 rot = ROT(mod(seed, 2.0*PI));
    
    #ifdef ROUGHNESS_MAP
    	float roughness = saturate(pow(triPlanarMapCatRom(iChannel2, 5.0, camHitNormal, camHitPosition*7.0, iChannelResolution[2].xy), vec3(2.0)).r*2.0);
    #else
    	const float roughness = 0.4;
    #endif
    
    // Start with "correct" GI contribution (i.e. the path that was actually sent for this pixel)
    sum += getVirtualLightContribution(uv+0.0, uv, baseColor, roughness, camHitNormal, camHitPosition, dotProduct, brdfRef);
    sum *= brdfRef;
    totalBlur += 1.0;
  
    for(float i = 0.0; i < float(steps); i++)
    {       
        // Rotated Hammersley disc kernel
        //offsetUv = uv + ((hammersleyDisk(int(i), steps)))*radius*rot;	
        // Spiral kernel
        offsetUv = uv + (radius*pow(((i+1.0)/float(steps)), 0.5))*vec2(sin(mod((i+1.0)*goldenAngle+seed, 2.0*PI)), cos(mod((i+1.0)*goldenAngle+seed, 2.0*PI)));

        dotProduct = 1.0;
        vec3 sampledIndirect = getVirtualLightContribution(uv, offsetUv, baseColor, roughness, camHitNormal, camHitPosition, dotProduct, brdfRef);
        float sampledDepth = UDEPTH(floor(offsetUv*iResolution.xy))*depthScale;

        // TODO magic numbers
        weight = 1.0;
        
        // Add hoc occlusion part 1
        #ifdef INDIRECT_GATHER_CHECK_DIRECTION
        	if((dotProduct < 0.7) || distance(depth, sampledDepth) > 0.06 || saturate(sampledDepth-depth) > 0.01)
        #else
            if(distance(depth, sampledDepth) > 0.06 || saturate(sampledDepth-depth) > 0.01)
        #endif
        {
            weight = 0.0;
        }
        
        // Ad hoc occlusion part 2
        float curOcclusion = saturate(200000.0*(depth-sampledDepth-0.03));
        weight *= saturate(1.0-curOcclusion);

        sum += brdfRef*sampledIndirect*weight;
        totalBlur += weight;
    }
    
    // Fade into shadow when we don't have good sample coverage
    sum *= smoothstep(1.0, 2.0, totalBlur);
    
    return hdrScale*(baseColor*sum)/totalBlur;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{   
    vec2 uv = fragCoord/iResolution.xy;
    
    vec3 baseColor = UBASE_COLOR(fragCoord)/hdrScale;
    vec3 indirectLight = accumulateLights(uv);
    #ifdef CLAMP_INDIRECT
	    indirectLight = min(indirectLight, vec3(hdrScale/2.0));
    #endif
    float depth = UDEPTH(fragCoord);
    
    float currentDepthMin = 100000.0;
    currentDepthMin = min(UDEPTH(fragCoord+vec2(1,0))*1.0, currentDepthMin);
    currentDepthMin = min(UDEPTH(fragCoord+vec2(-1,0))*1.0, currentDepthMin);
    currentDepthMin = min(UDEPTH(fragCoord+vec2(0,1))*1.0, currentDepthMin);
    currentDepthMin = min(UDEPTH(fragCoord+vec2(0,-1))*1.0, currentDepthMin);
    currentDepthMin = min(UDEPTH(fragCoord+vec2(1,1))*1.0, currentDepthMin);
    currentDepthMin = min(UDEPTH(fragCoord+vec2(-1,1))*1.0, currentDepthMin);
    currentDepthMin = min(UDEPTH(fragCoord+vec2(1,-1))*1.0, currentDepthMin);
    currentDepthMin = min(UDEPTH(fragCoord+vec2(-1,-1))*1.0, currentDepthMin);
    
    fragColor = vec4(indirectLight, pow(currentDepthMin, 1.0/depthDistributionExponent));
}