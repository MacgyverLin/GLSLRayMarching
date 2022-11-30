vec3 ACESFilm(vec3 x)
{
    float a = 2.51;
    float b = 0.03;
    float c = 2.43;
    float d = 0.59;
    float e = 0.14;
    return (x*(a*x+b))/(x*(c*x+d)+e);
}

vec3 bloom(float scale, float threshold, vec2 fragCoord){
    float logScale = log2(scale)+1.0;
    
    vec3 bloom = vec3(0);
    for(int y = -1; y <= 1; y++)
        for(int x = -1; x <= 1; x++)
            bloom += textureLod(iChannel0, (fragCoord+vec2(x, y) * scale)/iResolution.xy, logScale).rgb;
    
    return max(bloom/9.0 - vec3(threshold), vec3(0));
}

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
    
    vec3 col = texelFetch(iChannel0, ivec2(fragCoord), 0).rgb;
    
    vec3 bloomSum = bloom(.25 * iResolution.y, .4, fragCoord) * .3
        		  + bloom(.1 * iResolution.y, .7, fragCoord) * .3;
    
    fragColor = vec4(ACESFilm(col + bloomSum), 1.0);
}