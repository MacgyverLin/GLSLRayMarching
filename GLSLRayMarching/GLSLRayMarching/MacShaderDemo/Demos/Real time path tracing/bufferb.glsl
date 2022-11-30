bool trace(inout vec3 pos, in vec3 dir, out vec3 normal){
    pos += dir*sdf(pos);
    pos += dir*sdf(pos);
    for(int i = 0; i < MaxStepsDirect; i++){
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

void mainImage(out vec4 fragColor, in vec2 fragCoord){
    
    Camera cam = getCam(iTime);
    
    vec2 uv = (fragCoord-iResolution.xy/2.0) / iResolution.y;
    vec3 dir = uv2dir(cam, uv);
    fragColor = vec4(0.);
    vec3 pos = cam.pos, normal;
    if(trace(pos, dir, normal)) fragColor = vec4(pos, 1.);
}