// based on one desert canyon of the fantastic Shane shader

// best for small size
#define WITH_AA

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord/iResolution.xy;
    vec4 res = texture(iChannel0, uv);

#ifdef WITH_AA
    
    vec3 dp = vec3(1./iResolution.xy, 0);
    float needAA = 0.;
    for (int j=-1; j<3; j++) {
        for (int i=-1; i<3; i++) {
            needAA += texture(iChannel0, uv).w;
        }
    }
    
    // Antialising only on edges and big curvature
    if (needAA > .5) {
    	for (int k=0; k<4; k++)
        	res += render(fragCoord+.66*vec2(k%2-1,k/2-1)-.33, iTime, iResolution.xy, iChannel0);
        res /= 5.;
    }
    
#endif

    fragColor = res;
    
}