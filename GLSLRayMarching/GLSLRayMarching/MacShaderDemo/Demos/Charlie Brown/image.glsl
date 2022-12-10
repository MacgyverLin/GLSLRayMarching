void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
   vec2 uv = fragCoord.xy / iResolution.xy;
    vec4 r = texture(iChannel0, uv);
	
    // gamma
    r = clamp(r,0.0,1.0);
	r = vec4( pow( r , vec4(1.9/2.2)));    
    
    fragColor =  r;
}
