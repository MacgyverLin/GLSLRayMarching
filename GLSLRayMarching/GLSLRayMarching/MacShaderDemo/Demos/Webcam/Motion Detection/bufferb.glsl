
void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord.xy / iResolution.xy;
    vec4 c_t0 = texture( iChannel0, uv );
    vec4 c_t1 = texture( iChannel1, uv );
    
        
    vec4 diff = vec4(abs(c_t0.r - c_t1.r) ,abs(c_t0.g - c_t1.g) , abs(c_t0.b - c_t1.b),1.0);
    
    float threshold = 0.15;
    
    diff = step(threshold, diff);
    
    if(diff.r >= threshold || diff.g >= threshold || diff.b >= threshold)
        diff.r = diff.g = diff.b = 1.;
    
    vec4 motion = diff;
	fragColor = diff;               
}

