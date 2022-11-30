bool trace(inout vec3 pos, in vec3 dir){
    pos += dir*sdf(pos);
    pos += dir*sdf(pos);
    for(int i = 0; i < MaxStepsDirect; i++){
        float dist = sdf(pos);
        if(dist > MaxDist) break;
        if(dist < MinDist){
            pos -= (2.*MinDist-dist) * dir;
            pos -= (2.*MinDist-sdf(pos)) * dir;
            pos -= (2.*MinDist-sdf(pos)) * dir;
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
    vec3 pos = cam.pos;
    if(trace(pos, dir)) fragColor = vec4(pos, 1.);
}