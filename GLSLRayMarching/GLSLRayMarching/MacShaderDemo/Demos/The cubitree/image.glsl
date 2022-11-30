// Created by anatole duprat - XT95/2014
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.


// cheap bloom based on mipmap !
vec3 bloom( sampler2D tex, vec2 p) {
    vec3 col = vec3(0.);
    for (int i=1; i<9; i++)
        col += textureLod(tex, p, float(i)).rgb / float(9-i);
    
    return max(col-.6, vec3(0.));
}


//Main
void mainImage( out vec4 fragColor, in vec2 fragCoord )
{

	vec2 uv = fragCoord.xy/iResolution.xy;
    vec3 col = texture(iChannel0, uv).rgb;
    
	//post process
    vec2 q = uv;
    col = pow( col*2., vec3(1.75) );
	col *= sqrt( 32.0*q.x*q.y*(1.0-q.x)*(1.0-q.y) ); //from iq
    col += bloom(iChannel0, uv)*2.;
	
	//fragColor = vec4( col*min(iTime/5., 1.), 1. );
    
    
    fragColor = vec4(col, 1.);
}