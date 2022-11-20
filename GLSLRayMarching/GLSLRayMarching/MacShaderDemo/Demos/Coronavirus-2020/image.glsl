// Created by EvilRyu
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

// From Virgill: https://www.shadertoy.com/view/ltKGzc
const float GA =2.399; 
mat2 rot = mat2(cos(GA),sin(GA),-sin(GA),cos(GA));
vec3 dof(sampler2D tex,vec2 uv,float rad)
{
	vec3 acc=vec3(0);
    vec2 pixel=vec2(.003*iResolution.y/iResolution.x,.003),angle=vec2(0,rad);;
    rad=1.;
	for (int j=0;j<80;j++)
    {  
        rad += 1./rad;
	    angle*=rot;
        vec4 col=texture(tex,uv+pixel*(rad-1.)*angle);
		acc+=col.xyz;
	}
	return acc/80.;
}

void mainImage(out vec4 fragColor,in vec2 fragCoord)
{
	vec2 uv = gl_FragCoord.xy / iResolution.xy;
    fragColor=vec4(0,0,0,1);
 	if( uv.y>.1 && uv.y<.9 )
    {
       	fragColor=vec4(dof(iChannel0,uv,texture(iChannel0,uv).w),1.);
    }

}