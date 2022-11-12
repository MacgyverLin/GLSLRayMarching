/*
Procural image made for Revision 2020 4k Excutable Graphics competition
It's a direct reference to M.C. Escher's "Waterfall" with an awesome impossible geometry.
https://www.pouet.net/prod.php?which=85268

See a bit behind the magic here: https://twitter.com/NuSan_fx/status/1249424629783027712
*/

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{	       
    vec2 res = iResolution.xy;
	vec2 frag = fragCoord.xy;
	vec2 uv = frag/res.xy;
	
	vec4 value=texture(iChannel0,uv);
    
	fragColor = vec4(value.xyz/value.w, 1);
}
