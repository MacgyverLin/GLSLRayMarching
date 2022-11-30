//first DoF pass

#define dir normalize(vec2(1.0, 1.0))


void mainImage( out vec4 fragColor, in vec2 fragCoord ){
    
    Camera cam = getCam(iTime);
    
    vec4 col = vec4(0);
    float samples = 0.0, dr, influence, depth;
    vec2 d, de;
    vec4 p;
    for(int i = 0; i < DoFSamples; i++){
        d = dir * float(2*i-DoFSamples)/float(DoFSamples) * DoFClamping;
        vec2 de = (fragCoord + d*iResolution.y*cam.aperture)/iResolution.xy;
        p.rgb = texture(iChannel0, de).rgb;
        p.a = length(texture(iChannel1, de).rgb - cam.pos);
        dr = min(abs(p.a-cam.focalDistance)/p.a, DoFClamping);
        influence = clamp((dr - length(d))*iResolution.y*cam.aperture + .5, 0.0, 1.0) / (dr*dr+.001);
        col += influence * p;
        samples += influence;
    }
    
    col /= samples;
    
    fragColor = col;
}