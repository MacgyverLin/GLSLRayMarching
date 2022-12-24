
MOUNTAIN_FUNCTIONS

// Water.
const float WATER_HEIGHT = -0.3;
float waterFunction(in vec3 pos, in float time){
	const int size = 6;
    const float f = 75.;
    const float m = 0.0005;
    const vec3 vecs[size] = vec3[](
        vec3( f*1.,  f*2.,  m*0.2),
        vec3(f*0.5, f*0.5,  m*0.1),
        vec3(f*-1., f*0.2,  m*0.1),
        vec3( f*0.,f*-0.5,  m*0.5),
        vec3( f*2., f*-2., m*0.01),
        vec3(f*-2.,  f*5., m*0.01)
    );
    float waveHeight = 0.;
    for(int i=0; i<size; i++) {
        // The speed of waves on water is independent on amplitude and wavelength.
    	waveHeight += sin(pos.x*vecs[i].x+pos.z*vecs[i].y+0.01*time*length(vecs[i].xy))*vecs[i].z;
    }
    return waveHeight + WATER_HEIGHT;
}

float sdWater(in vec3 pos){
    const float maxWaveHeight = (.2+.1+.1+.5+.01+.01)*.05;
    const float maxWaterHeight = maxWaveHeight + WATER_HEIGHT; // See waterFunction(.).
    if(pos.y - maxWaterHeight > maxWaveHeight){
    	return pos.y - maxWaterHeight;
    }
    
    float waveHeight = waterFunction(pos, iTime);
    
	float heightDiff = pos.y - waveHeight;
    const float maxSlope = 1.;
    float nextDist = heightDiff/sqrt(maxSlope*maxSlope + 1.);
    
    return max(nextDist, pos.y-maxWaterHeight);
}

void sdWaterNormal(in vec3 pos, inout vec3 normal, inout float sd){
	sd = sdWater(pos);
    vec3 cameraPos = texelFetch(iChannel0, ivec2(CAMERA_POS, 0), 0).xyz;
    float df = max(sqrt(length(cameraPos-pos)), 1.)*0.01;
    vec2 e = vec2(df, 0.);
    normal = normalize(sd - vec3(
    	sdWater(pos - e.xyy),
    	sdWater(pos - e.yxy),
    	sdWater(pos - e.yyx)
    ));
}

// Ray marching.
# define INTERSECTED 0
# define TOO_FAR 1
# define TOO_MANY_STEPS 2
float finalRes;
void marchWorld(
    inout vec3 pos, inout vec3 dir,
    out float dist, in float maxDist, in float minDist,
    out int numSteps, in int maxNumSteps,
    out vec3 color, out vec3 normal, out int returnCode
){
    dist = 0.;
    float prevDist = dist;
    numSteps = 0;
    color = vec3(0);
    vec3 prevPos = pos;
    float prevSd;
    float sd = 0.;
    // Trace.
    for(int i=0; i<maxNumSteps; i++) {
        //
        numSteps++;
        # define log16(x) log(x)/log(16.)
		//float res = clamp(50./(dist+0.0001), 1., 3.);
		float res = clamp(log16(1000./(dist+0.0000001)), 1., 3.);
        float f = fract(res);
        res = floor(res) + f*f*(3.-2.*f);
        //float res = 3.;
        finalRes = res;
        
        // Calc sd.
        prevSd = sd;
        float sdMount = sdMountain(/*in vec3=*/pos, res, /*differentiable=*/false);
        float sdWater = sdWater(/*in vec3=*/pos);
        sd = min(sdMount, sdWater);
        
        if(dist + sd > maxDist){
        	sd = maxDist-dist;
            dist += sd;
            pos += dir*sd;
            
            color = vec3(0);
            normal = vec3(0);
            
            returnCode = TOO_FAR;
        	return;
        }
        if(sd <= minDist + dist*0.001){
            // Linearly interpolate position.
            float fac = (minDist + dist*0.001 - sd) / (prevSd - sd);
            pos = mix(pos, prevPos, fac);
            
            if(sdMount < sdWater){
                // Mountain.
                sdMountainNormal(
                    /*in vec3 pos=*/pos, /*out vec3 normal=*/normal, /*out float sd=*/sd,
                    /*in float resolution=*/res+1., /*in float df=*/max(3./iResolution.x*dist, 0.00003)
                );
                // Gray dark.
                //color = vec3(110., 116., 120.)/255.;
                color = vec3(155., 155., 154.)/255.;
                // Gray light.
                color = mix(color, vec3(199., 194., 187.)/255., min(pow(normal.y+0.5, 8.), 1.));
                // Grass.
                float grassFactor = min(pow(normal.y+0.3, 8.), 1.);
                color = mix(color, vec3(146., 116., 32.)/255., grassFactor);
                // Sand.
                float sandFactor = min(pow(normal.y+0.2, 8.), 1.);
                sandFactor *= clamp(-pos.y*10.-2., 0., 1.);
                color = mix(color, vec3(219., 209., 180.)/255., sandFactor);
                // Snow.
                float snowFactor = min(pow(normal.y+0.2, 8.), 1.);
                snowFactor *= clamp(pos.y*10.-8.+sin(pos.x*2.)*3.*0., 0., 1.);
                color = mix(color, vec3(235., 235., 255.)/255., snowFactor);
                
                returnCode = INTERSECTED;
            	return;
            } else {
                // Water.
                sdWaterNormal(/*in vec3 pos=*/pos, /*out vec3 normal=*/normal, /*out float sd=*/sd);
                dir = reflect(dir, normal);
                prevDist = dist;
                dist += sd;
                prevPos = pos;
                pos += dir*sd;
                
                float diff = sdMount - sdWater;
                if(diff + cos(diff*200000. - iTime*8.)*0.00002 < 0.00003 - dist*0.001){
                	color = vec3(0.8,0.8,1)*2.;
                    
                    returnCode = INTERSECTED;
            		return;
                }
                
                continue;
            }
            
            //if(sd < 0.){
            //	color = vec3(1,0,0);
            //}
            
            //color=vec3(1,1,0);

            
        }
        
        //
        prevDist = dist;
        dist += sd;
        prevPos = pos;
        pos += dir*sd;
       	
    }
    returnCode = TOO_MANY_STEPS;
    return;
}

void marchWorldShaddow(
    inout vec3 pos, inout vec3 dir,
    out float dist, in float maxDist, in float minDist,
    out int numSteps, in int maxNumSteps, out float shaddowFactor,
    out int returnCode
){
    dist = 0.;
    float prevDist = dist;
    numSteps = 0;
    float sd = 0.;
    shaddowFactor = 1.;
    // Trace.
    for(int i=0; i<maxNumSteps; i++) {
        //
        numSteps++;
        # define log16(x) log(x)/log(16.)
		float res = clamp(log16(100./(dist+0.0000001)), 1., 3.);
        
        // Calc sd.
        float sdMount = sdMountain(/*in vec3=*/pos, res, /*differentiable=*/false);
        sd = sdMount;
        
        // Soft shaddows inspired by https://iquilezles.org/articles/rmshadows.
        shaddowFactor = min(shaddowFactor, 100.*sd/(dist+1e-6));
        
        if(dist + sd > maxDist){
            returnCode = TOO_FAR;
        	return;
        }
        if(sd <= minDist + dist*0.001){
            returnCode = INTERSECTED;
            return;
        }
        
        //
        dist += sd;
        pos += dir*sd;
       	
    }
    returnCode = TOO_MANY_STEPS;
    return;
}

// Render.
void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec3 cameraPos = texelFetch(iChannel0, ivec2(CAMERA_POS, 0), 0).xyz;
    vec3 forward = normalize(texelFetch(iChannel0, ivec2(CAMERA_DIRECTION, 0), 0).xyz);
    vec3 right = normalize(cross(forward, vec3(0,1,0)));
    vec3 up = cross(right, forward);
    
    vec2 uv = (fragCoord-0.5*iResolution.xy)/iResolution.x;
    float aspectRatio = iResolution.x / iResolution.y;

    vec3 camPos = vec3(cameraPos.x, cameraPos.y, cameraPos.z);
    vec3 viewDir = normalize(forward*0.5 + right * uv.x + up * uv.y);
    
    vec3 pos = camPos;
    vec3 dir = viewDir;
    float dist = 0.;
    float maxDist = 40.;
    float minDist = 0.00001;
    int numSteps;
    int maxNumSteps = 200;
    vec3 color;
    vec3 normal;
    int returnCode;
    marchWorld(
        /*inout vec3 pos=*/pos, /*inout vec3 dir=*/dir,
        /*out float dist=*/dist, /*in float maxDist=*/maxDist, /*in float minDist=*/minDist,
        /*out int numSteps=*/numSteps, /*in int maxNumSteps=*/maxNumSteps,
        /*out vec3 color=*/color, /*out vec3 normal=*/normal, /*out int returnCode=*/returnCode
    );
    
    vec3 lightDir = normalize(vec3(5.,-1,3.));
    //float t = iTime*0.1 + 177.;
    //vec3 lightDir = normalize(vec3(sin(t),cos(t),1.));
    
    float shaddowFactor;
    if(returnCode == INTERSECTED){
        vec3 shaddowPos = pos-lightDir*minDist*2.;
        vec3 shaddowDir = -lightDir;
        float shaddowDist;
        float shaddowMaxDist = maxDist;
        float shaddowMinDist = minDist;
        int shaddowNumSteps;
        int shaddowMaxNumSteps = maxNumSteps;
        shaddowFactor;
        int shaddowReturnCode;
        marchWorldShaddow(
            /*inout vec3 pos=*/shaddowPos, /*inout vec3 dir=*/shaddowDir,
            /*out float dist=*/shaddowDist, /*in float maxDist=*/shaddowMaxDist, /*in float minDist=*/shaddowMinDist,
            /*out int numSteps=*/shaddowNumSteps, /*in int maxNumSteps=*/shaddowMaxNumSteps, /*out float shaddowFactor=*/shaddowFactor,
            /*out int returnCode=*/shaddowReturnCode
        );
        shaddowFactor *= max(shaddowDist / shaddowMaxDist, shaddowDist/shaddowMaxDist);
    } else {
    	shaddowFactor = 1.;
    }
    
    
    // Ambient occlusion.
    vec3 occlusionColor = vec3(0.,0.,0.);
    float occlusionFactor = float(numSteps)/log(dist+10.) * max(dot(-viewDir, normal), 0.);
    occlusionFactor = max(1.-occlusionFactor*0.025, 0.);
    
    float diff = max(dot(-lightDir, normal), 0.)*0.75;
    
    vec3 reflectDir = reflect(lightDir, normal); // reflect(I, N) = I - 2.0 * dot(N, I) * N.
    float spec = pow(max(dot(reflectDir, -viewDir), 0.0), 8.) * 0.5;
    
    float ambient = 0.5*occlusionFactor;
    
    /*float sum = diff + spec + ambient;
    if(sum > 1.){
    	diff /= sum;
    	spec /= sum;
    	ambient /= sum;
    }*/
    color = (color*diff*shaddowFactor + color*spec*shaddowFactor) + color*ambient;
    
    //float test = texelFetch( iChannel0, ivec2(DO_BUFFER_UPDATE,0), 0 ).x;
    //color.r += test;
    
    // Mist.
    vec3 mistColor = vec3(0.5,0.6,0.9);
    float skyColorFactor = clamp(viewDir.y * 1., 0., 1.);
    skyColorFactor = skyColorFactor*skyColorFactor*(3.-2.*skyColorFactor);
    mistColor = mix(mistColor, vec3(0.3, 0.4, 0.9), skyColorFactor);
    float mistFactor = max(float(numSteps)/float(maxNumSteps), float(dist)/float(maxDist));
    mistFactor = pow(mistFactor, 1.);
    color = mix(color, mistColor, mistFactor);
    
    // The sun.
    float d = dist/maxDist * 2.*max(mistFactor*mistFactor*mistFactor-0.5, 0.)*min(pow(max(dot(dir, -lightDir), 0.), 1024.), 1.);
    //float d = ;
    color = min(color + vec3(d), 1.);
    
    /*float testF = 1073741824.;
    int testI = int(testF);
    if(testF == float(testI)){
    	color.g = 1.;
    }*/
    
    /*float testF = texelFetch(iChannel0, ivec2(PRECISION_TEST, 0), 0).x;
    if(int(testF) == PRECISION_NUMBER){
    	color.g = 1.;
    }*/
    
    //color.r = ceil(finalRes-1.)/3.;
    
    // Output to screen
    fragColor = vec4(color,1.0);
}



































