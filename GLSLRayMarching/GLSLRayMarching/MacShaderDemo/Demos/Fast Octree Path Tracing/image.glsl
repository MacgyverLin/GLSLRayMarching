void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
	vec2 uv = fragCoord.xy / iResolution.xy;
	vec3 color = texture(iChannel0, uv).rgb;
    
	fragColor = vec4(pow(clamp(color, 0., 1.), vec3(1.0/2.2)), 1.0);
}