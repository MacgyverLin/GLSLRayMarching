vec3 ACESFilm(vec3 x){
    float a = 2.51;
    float b = 0.03;
    float c = 2.43;
    float d = 0.59;
    float e = 0.14;
    return (x*(a*x+b))/(x*(c*x+d)+e);
}


mat3 gaussianFilter = mat3(41, 26, 7,
                           26, 16, 4,
                           7,  4,  1) / 273.;

vec3 bloom(float scale, float threshold, vec2 fragCoord){
    float logScale = log2(scale);
    vec3 bloom = vec3(0);
    for(int y = -2; y <= 2; y++)
        for(int x = -2; x <= 2; x++)
            bloom += gaussianFilter[abs(x)][abs(y)] * textureLod(iChannel0, (fragCoord+vec2(x, y)*scale)/iResolution.xy, logScale).rgb;
    
    return max(bloom - vec3(threshold), vec3(0));
}

void mainImage( out vec4 fragColor, in vec2 fragCoord ){
    
    Camera cam = getCam(iTime);
    
    vec4 col = vec4(0.);
    float frd = iResolution.y*cam.aperture*DoFClamping;
    int rd = int(ceil(frd - .5));
    for(int y = -rd; y <= rd; y++){
        int ln = int(ceil(sqrt(frd*frd-float(y*y)) - .5));
        for(int x = -ln; x <= ln; x++){
            vec4 p = texelFetch(iChannel0, ivec2(clamp(fragCoord + vec2(x, y), vec2(0), iResolution.xy-1.)), 0);
            float dof = min(abs(p.a-cam.focalDistance)/p.a, DoFClamping) * iResolution.y*cam.aperture;
            p.a = 1.;
            p *= clamp((dof - length(vec2(x, y))) + .5, 0.0, 1.0) / (dof*dof+.5);
            col += p;
    	}
    }
    
    col /= col.a;
    
    vec3 bloomSum = vec3(0.);
    bloomSum += bloom(.07 * iResolution.y, .0, fragCoord) * .06;
    
    fragColor = vec4(ACESFilm(col.rgb + bloomSum), 1.);
}
