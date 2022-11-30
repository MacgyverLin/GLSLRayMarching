//second DoF pass

#define dir normalize(vec2(1.0, -1.0))

vec3 ACESFilm(vec3 x)
{
    float a = 2.51;
    float b = 0.03;
    float c = 2.43;
    float d = 0.59;
    float e = 0.14;
    return (x*(a*x+b))/(x*(c*x+d)+e);
}


void mainImage( out vec4 fragColor, in vec2 fragCoord ){
    
    Camera cam = getCam(iTime);
    
    vec4 col = vec4(0);
    float samples = 0.0, dr, influence, depth;
    vec2 d;
    vec4 p;
    for(int i = 0; i < DoFSamples; i++){
        d = dir * float(2*i-DoFSamples)/float(DoFSamples) * DoFClamping;
        p = texture(iChannel0, (fragCoord + d*iResolution.y*cam.aperture)/iResolution.xy);
        dr = min(abs(p.a-cam.focalDistance)/p.a, DoFClamping);
        influence = clamp((dr - length(d))*iResolution.y*cam.aperture + .5, 0.0, 1.0) / (dr*dr+.001);
        col += influence * p;
        samples += influence;
    }
    
    col /= samples;
    
    fragColor = vec4(ACESFilm(col.rgb), 1.);
}
