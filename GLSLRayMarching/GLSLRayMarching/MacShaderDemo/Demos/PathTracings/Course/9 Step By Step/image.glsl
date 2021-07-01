#define GAMMA 2.2f

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
	vec2 uv = fragCoord.xy / iResolution.xy;
	vec3 color = texture(iChannel0, uv).rgb;
    
	fragColor = vec4(clamp(pow(color, vec3(1./GAMMA)), 0., 1.), 1.);
}