#define GAMMA 0.4
#define BRIGHTNESS 0.8
void f(inout vec3 c){
   c = vec3(0.,0.,0.);   
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = fragCoord/iResolution.xy;
	
    // Time varying pixel color
    //vec4 col = 0.5 + 0.5*cos(iTime+uv.xyx+vec3(0,2,4));
	//f(col);
    // Output to screen
    vec4 col = texture(iChannel0, uv);
    col *= BRIGHTNESS;
    col = vec4(pow(col.x, GAMMA), pow(col.y, GAMMA), pow(col.z, GAMMA), pow(col.w, GAMMA));
    fragColor = col * 1.3;
}