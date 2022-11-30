float seed;

vec3 LightDir = vec3(.0, -1, .0);
vec3 LightColor = vec3(.7, .5, .3) * 13.;
float LightRadius = .05;

float randomFloat(){
    return fract(sin(seed++)*43758.54536156);
}

vec3 ortho(vec3 v) {
  return abs(v.x) > abs(v.z) ? vec3(-v.y, v.x, 0.0)  : vec3(0.0, -v.z, v.y);
}

vec3 getCosineWeightedSample(vec3 dir) {
	vec3 o1 = normalize(ortho(dir));
	vec3 o2 = normalize(cross(dir, o1));
	vec2 r = vec2(randomFloat(), randomFloat());
	r.x = r.x * 2.0 * Pi;
	r.y = pow(r.y, .5);
	float oneminus = sqrt(1.0-r.y*r.y);
	return cos(r.x) * oneminus * o1 + sin(r.x) * oneminus * o2 + r.y * dir;
}

vec3 directLight(vec3 pos, vec3 normal){
    float dotLight = -dot(normal, LightDir);
    if(dotLight < 0.0) return vec3(0);
    vec3 pos0 = pos;
    float minAngle = LightRadius;
    for(int i = 0; i < MaxShadowSteps; i++){
        float dist = sdf(pos);
        if(dist > MaxDist) break;
        if(dist < MinDist) return vec3(0.0);
        pos -= LightDir * dist * 3.0;	//goes 3 times faster since we don't need details
        minAngle = min(asin(dist/length(pos-pos0)), minAngle);
    }
    return LightColor * dotLight * clamp(minAngle/LightRadius, .0, 1.0);
}


vec3 background(vec3 dir){
    vec3 col = texture(iChannel3, dir).rgb;
    return col*col + col;
}



bool trace(inout vec3 pos, in vec3 dir, out vec3 normal){
    for(int i = 0; i < MaxStepsIndirect; i++){
        float dist = sdf(pos);
        if(dist > MaxDist) break;
        if(dist < MinDist){
            normal = normalEstimation(pos);
            pos -= (2.*MinDist-dist) * dir;
            return true;
        }
        pos += dir*dist;
    }
    return false;
}

vec3 sampleIndirectLight(vec3 pos, vec3 normal){
    vec3 dir = getCosineWeightedSample(normal);
    vec3 light = vec3(0.);
    for(int i = 0; i < Bounces; i++){
        if(!trace(pos, dir, normal)) return light+background(dir);
        else light += directLight(pos, normal);
    }
    return light;
}

float distancePixel(vec2 prevFragCoord, vec4 hit){
    if(  min(iResolution.xy, prevFragCoord) != prevFragCoord
      && max(vec2(0.)      , prevFragCoord) != prevFragCoord) return MaxDist;
    vec4 prevPos = texture(iChannel2, prevFragCoord/iResolution.xy);
    Camera cam = getCam(iTime);
    return length(prevPos-hit);
}

vec4 previousSample(vec4 hit){
    vec2 prevUv = pos2uv(getCam(iTime-iTimeDelta), hit.xyz);
    vec2 prevFragCoord = prevUv * iResolution.y + iResolution.xy/2.0;
    
    vec2 pfc, finalpfc;
    float dist, finaldist = MaxDist;
    for(int x = -1; x <= 1; x++){
        for(int y = -1; y <= 1; y++){
            pfc = prevFragCoord + PixelCheckDistance*vec2(x, y);
            dist = distancePixel(pfc, hit);
            if(dist < finaldist){
                finalpfc = pfc;
                finaldist = dist;
            }
    	}
    }
    
    Camera cam = getCam(iTime);
    if(finaldist < PixelAcceptance*length(hit.xyz-cam.pos)/cam.focalLength/iResolution.y)
        return texture(iChannel0, finalpfc/iResolution.xy);
    return vec4(0.);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord){
    
    seed = .256435865*fragCoord.x+.316548465*fragCoord.y+sin(iTime)*16886.3158915;
    
    Camera cam = getCam(iTime);
    
    vec4 hit = texelFetch(iChannel1, ivec2(fragCoord), 0);
    if(hit.a == 0.){
        vec2 uv = (fragCoord-iResolution.xy/2.0) / iResolution.y;
        fragColor = vec4(background(uv2dir(cam, uv)), 1.);
    } else {
        
        #if 0
        fragColor = previousSample(hit);
        fragColor.rgb = fragColor.a == 0. ? vec3(1., 0., 0.) : vec3(0., 1., 0.);
        fragColor.a = 1.;
        #else
        vec3 normal = normalEstimation(hit.xyz);
        
        vec3 dLight = directLight(hit.xyz, normal);
        vec3 iLight = vec3(0.);
        for(int i = 0; i < IndirectSamples; i++)
            iLight += sampleIndirectLight(hit.xyz, normal)/float(IndirectSamples);
        
        fragColor = previousSample(hit);
        if(fragColor.a < 1.) iLight = clamp(iLight, vec3(.1), vec3(.4)); // clamp gi for low sample count
        fragColor.a += fragColor.a > float(SamplesLimit) ? 0. : float(IndirectSamples);
        fragColor.rgb = mix(fragColor.rgb, iLight + dLight, 1.0/(fragColor.a/float(IndirectSamples)));
        #endif
    }
}