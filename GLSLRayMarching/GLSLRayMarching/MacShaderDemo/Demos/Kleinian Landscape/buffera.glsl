// Path tracing, partly based (unsurprisingly) on iq's implementation
//
// Single sample, one bounce, but stores indirect bounces as "point lights" for re-use across neighboring pixels (done in Buffer B) so we only compute final direct light here.
// I have no idea if any of this is a good idea, but it was a fun experiment.
// Supports specular (GGX) with multiple importancs sampling, and uses a roughness map

vec4 orbitTrap;

float sphere(vec3 ray, vec3 dir, vec3 center, float radius)
{
	vec3 rc = ray-center;
	float c = dot(rc, rc) - (radius*radius);
	float b = dot(dir, rc);
	float d = b*b - c;
	float t = -b - sqrt(abs(d));
	float st = step(0.0, min(t,d));
	return mix(-1.0, t, st);
}

float intersect(in ray ray, int maxSteps, float bias)
{
    float res = -1.0;

    float t = bias;
    
    for(int i=1; i<maxSteps+1; i++ )
    {
		vec3 samplePoint = ray.origin+ray.direction*t;
        if (samplePoint.y >= 1.0 || samplePoint.y <= -1.0 )//|| max(abs(samplePoint.x),abs(samplePoint.z)) >= 6.0)
        {
            return -1.0;
        }

        float h = sceneDistanceFunction(samplePoint, orbitTrap);
        if(h < mix(0.0001, 0.01, saturate(distance(ray.origin, samplePoint)/12.0)/*smoothstep(0.0, 6.0, distance(ray.origin, samplePoint))*/) || t > maxDepth) 
        {
            break;
        }
        //if( h<0.0012 || t>tmax ) break;
        t +=  h;
    }
    
    if(t<maxDepth) 
    {
        res = t;
    }
    
    return res;
}

// TODO this
/*
vec3 dropToFloor(in vec3 origin, int maxSteps)
{
    float res = -1.0;
    
    float t = 0.001;
    for(int i=1; i<maxSteps+1; i++ )
    {
		vec3 samplePoint = origin + vec3(0, -1, 0)*t;
        if (samplePoint.y >= 1.0 || samplePoint.y <= -1.0 )//|| max(abs(samplePoint.x),abs(samplePoint.z)) >= 6.0)
        {
            // No floor found
            return origin;
        }
        float h = sceneDistanceFunction(samplePoint, orbitTrap);
        if(h < 0.001 || t > maxDepth)
        {
            break;
        }
        t +=  h;
    }
    
    if(t<maxDepth) 
    {
        res = t;
    }
    
    return origin + vec3(0, -res, 0);
}
*/

float shadow(in ray ray, int maxSteps)
{
    float res = 0.0;

    float t = 0.001;
    
    float k = 8.0;
    
    float h = 0.1;
    
    for(int i=1; i<maxSteps+1; i++ )
    {
        vec3 samplePoint = ray.origin+ray.direction*t;
        if (samplePoint.y >= 1.0 || samplePoint.y <= -1.0 )//|| max(abs(samplePoint.x),abs(samplePoint.z)) >= 6.0)
        {
            return 1.0;
        }
        h = sceneDistanceFunction(ray.origin+ray.direction*t, orbitTrap);
        res = min( res, (k*h)/t );
        //if( h<0.0015*pow(distance(ray.origin, samplePoint), 1.0) || t>tmax) break;
        if(h < 0.00009 || t > maxDepth) 
        {
            break;
        }
        t += h;
    }

    if(t > maxDepth)
    {
        res = 1.0;
    }
    
    return res;
}

float softShadow(in ray ray, int maxSteps/*float mint, float k*/)
{
    float k = 4.0;
    float res = 0.0;
    float t = 0.001;
	float h = 1.0;
    
    for( int i=0; i<int(maxSteps); i++ )
    {
        h = sceneDistanceFunction(ray.origin + ray.direction*t, orbitTrap);

        if(res<0.001)
        {
            break;
        }
        t += h;//clamp( h, 0.01, 0.05 );
    }
    return 1.0-saturate(res);
}

void calculateColor(ray cameraRay, float sa, vec2 fragCoord, out vec3 camHitPosition, out float depth, out vec3 camHitNormal, out vec3 baseColor, out vec3 directLight, out vec3 indirectLight, out pointLight bounceLight, vec3 sunDirection, vec3 sunColor)
{
    const float epsilon = 0.0001;
    float seed = mod(iTime, 1024.0)+0.13*iMouse.x+1.25*iMouse.y;
    
    vec3 bounceColor = vec3(1);
    
    vec3 totalDirect = vec3(0);
    vec3 totalGi = vec3(0);
    
    ray currentRay = cameraRay;
    
    // TODO manually unroll bounces to reduce number of ifs?
    for(int bounce = 0; bounce<2; bounce++)
    {
        currentRay.direction = normalize(currentRay.direction);
        
       
        float traced = -1.0;
        if(bounce == 0)
        {
            traced = intersect(currentRay, 128, 0.005);
        }
        else
        {
            traced = intersect(currentRay, 80, 0.005);
        }
        if(traced < 0.0)
        {
            if( bounce==0 ) 
            {
                // No hit, draw BG
                vec3 bgColor = getSky(currentRay, sunDirection, sunColor);
                totalDirect = bgColor;

                // Out
                directLight = bgColor;
                indirectLight = vec3(0);

                return;
            }
            break;
        }

        vec3 position = currentRay.origin + currentRay.direction*traced;
        vec3 surfaceNormal = calcNormal(position);
        
        vec3 triplanarNormal = surfaceNormal;
		
        float emissiveFactor = saturate((1.0 - orbitTrap.z*50.0)*100000.0);
        
        vec3 emissiveColor = pow(((sin(position.x*5.0+mod(iTime, 1024.0)/2.0)+1.0)/2.0), 8.0)*1.33*pow(vec3(0.35,1.0,0.55),vec3(2.0))*emissiveFactor + 0.02*vec3(0.35,1.0,0.55)*emissiveFactor;

        vec3 surfaceColor1 = vec3(0.7);
        vec3 surfaceColor2 = vec3(0.6, 0.5, 0.8);

        vec3 surfaceColor = mix(surfaceColor1, surfaceColor2, saturate((orbitTrap.y*3.5-0.25)*1.0))*(1.0-emissiveFactor) + emissiveFactor*(vec3(0.5,0.8,1.0));
        
        #ifdef ROUGHNESS_MAP
        	float roughness = saturate(pow(triPlanarMapCatRom(iChannel2, 5.0, triplanarNormal, position*7.0, iChannelResolution[2].xy), vec3(2.0)).r*2.0);
		#else
        	const float roughness = 0.4;
        #endif
        
		// Direct lighting
        vec3 iColor = vec3(0.0);

        // Direct sun light
        vec3 currentSunDir = sunDirection;
        
        float sunDiffuse = 0.0;
        float sunSpec = 0.0;

        if(bounce == 0)
        {
            sunDiffuse = saturate(dot(currentSunDir, surfaceNormal))*0.9;
            sunSpec = GGX(surfaceNormal, -currentRay.direction, currentSunDir, roughness, 0.1);
        }
        else
        {
            sunDiffuse = saturate(dot(currentSunDir, surfaceNormal));
            sunSpec = 0.0;
        }
        float sunShadow = 1.0;
        if(sunDiffuse > 0.0) 
        {
            sunShadow = shadow(ray(position + surfaceNormal*epsilon, currentSunDir), 80);
        }

        iColor += sunColor*sunDiffuse*sunShadow + sunColor*sunSpec*sunShadow;
        
        // Carry surface color through next bounce
        vec3 previousBounceColor = bounceColor;
        bounceColor *= surfaceColor;

		if(bounce == 0)
        {
            totalDirect += bounceColor*iColor + emissiveColor;
            // Out
            camHitPosition = position;
            depth = traced;
            baseColor = surfaceColor;
            camHitNormal = surfaceNormal;
        }
        else if(bounce == 1)
        {
            totalGi += bounceColor*iColor + emissiveColor;

            // Virtual point light from direct lighting of first bounce, accumulated in Buffer B
            bounceLight.worldPosition = position;
            bounceLight.normal = surfaceNormal;
            bounceLight.color = (previousBounceColor*iColor + emissiveColor);

            // TODO texture map
            
            float lightDistance = distance(bounceLight.worldPosition, camHitPosition);
            float NdotL = saturate(dot(normalize(camHitNormal), normalize(bounceLight.worldPosition - camHitPosition)));
            	
            if(NdotL > 0.00001 && length(baseColor) > 0.00001)
            {	
                // Cancel out cosine distribution
                bounceLight.color /= NdotL;
                // Cancel out inverse square attenuation 
                bounceLight.color *= lightDistance*lightDistance;
                // For debugging direct light
                //bounceLight.color *= 0.0;
            }
        }

		// Send bounce ray
        vec3 reflectDirection = reflect(normalize(currentRay.direction), normalize(surfaceNormal));
        currentRay.direction = cosineDirection(surfaceNormal, fragCoord, seed);

        currentRay.origin = position;
    }
    
    // Out
	directLight = totalDirect;
    indirectLight = totalGi;
}

mat3 setCamera(in vec3 ro, in vec3 rt, in float cr)
{
	vec3 cw = normalize(rt-ro);
	vec3 cp = vec3(sin(cr), cos(cr),0.0);
	vec3 cu = normalize( cross(cw,cp) );
	vec3 cv = normalize( cross(cu,cw) );
    return mat3(cu, cv, -cw);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 jitter = vec2(hash12(vec2(13.1, mod(float(iFrame*4),4096.0))),hash12(vec2(4.1, mod(float(iFrame*3),4096.0))))*AAjitter-(AAjitter/2.0);
    
    vec2 jitteredCoord = fragCoord + jitter;
    vec2 uv = jitteredCoord/iResolution.xy;
	vec2 uvAspectCorrected = vec2(uv.x*(iResolution.x/iResolution.y), uv.y);
    
    float sa = hash13(vec3(iFrame, fragCoord.x, fragCoord.y));
    
    ray cameraRay;
    
    float mouseLocation = 0.1;
    #ifdef ANIMATE_CAMERA
	    mouseLocation += iTime/9.0;
    #endif
    #ifdef INTERACTIVE
	    mouseLocation += 0.002*iMouse.x;
    #endif
    
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


    // TODO more interesting camera movement
    // TODO avoid intersections
    cameraRay.origin = vec3( 2.8*cos(0.1+.33*mouseLocation), 0.5 + 0.15*cos(0.37*mouseLocation), 2.8*cos(0.5+0.35*mouseLocation) );
    //cameraRay.origin.y = 1.0;
    //cameraRay.origin = dropToFloor(cameraRay.origin, 7) + vec3(0, 0.02, 0);
    cameraRay.direction = stereographicPlaneToSphere((vec2(uvAspectCorrected) - 0.5)/1.5);
    cameraRay.direction.xyz = normalize(cameraRay.direction.xzy);
    
    vec3 color = vec3(0.0);
    
    // Results from ray tracing to pack up for use in subsequent passes
    pointLight bounceLight;
    vec3 baseColor = vec3(0);
    vec3 camHitPosition;
    vec3 directLight;
    vec3 indirectLight;
    vec3 camHitNormal;
    float depth;
    
	calculateColor(cameraRay, sa, fragCoord, camHitPosition, depth, camHitNormal, baseColor, directLight, indirectLight, bounceLight, sunDirection, sunColor);
    
    float dither = 0.008*hdrScale*(hash12(fragCoord+mod(iTime, 512.0)*0.21+0.1*iMouse.xy)-0.5);
    
    depth /= depthScale;
    if(depth <= 0.0 || depth > maxDepth)
    {
        depth = maxDepth;
    }
    
    directLight += dither;
    bounceLight.color += dither;
    
    directLight /= hdrScale;
    indirectLight /= hdrScale;
    bounceLight.color /= hdrScale;
    bounceLight.worldPosition /= depthScale;
    
    // Clamp brightness, preserve color
    float totalLight = max(max(length(indirectLight), length(directLight)),  length(bounceLight.color));
    if(totalLight >= 1.0)
    {
        directLight /= totalLight;
        indirectLight /= totalLight;
        bounceLight.color /= totalLight;
    }
    
    // For debugging
    //NdotL = saturate(dot(normalize(camHitNormal), normalize(bounceLight.worldPosition*depthScale - camHitPosition)));
    //virtualPointColor = baseColor*bounceLight.color*NdotL;
    //indirectLight = virtualPointColor;
    //bounceLight.color = indirectLight;
    
    // For debugging
    //bounceLight.color = camHitPosition/depthScale;//clamp(bounceLight.worldPosition, 0.0, depthScale);
    //bounceLight.color = camHitNormal;
    //bounceLight.color = bounceLight.worldPosition;
    
    
    
    // Buffer packing layout:
    // x = vec4(directLight.rgb, baseColor.r)
    // y = vec4(bounceLight.color.rgb, baseColor.g)
    // z = vec4(bounceLight.position.xyz, baseColor.b)
    // w = vec4(normal.xyz, depth)
    
    //#ifdef STORE_NORMAL
        // Tried packing both normal and depth, loses too much precision in depth to be useful for temporal reprojection
    //    fragColor = vec4(pack(vec4(directLight, baseColor.r)), pack(vec4(bounceLight.color, baseColor.g)), pack(vec4(bounceLight.worldPosition, baseColor.b)), pack(vec4(camHitNormal/2.0 + 0.5, pow((saturate(depth)), 1.0/depthDistributionExponent))));
    //#else
    	fragColor = vec4(pack(vec4(directLight, baseColor.r)), pack(vec4(bounceLight.color, baseColor.g)), pack(vec4(bounceLight.worldPosition, baseColor.b)), pow((saturate(depth)), 1.0/depthDistributionExponent));
    //#endif
}