void mainImage( out vec4 fragColor, in vec2 fragCoord ) 
{
#define EPS 2.e-3
	vec2 uv = fragCoord.xy / iResolution.xy;
	uv.x = 1.-uv.x;
	vec2 uvx = uv+vec2(EPS,0.);
	vec2 uvy = uv+vec2(0.,EPS);
	
	vec2 ref = vec2(.5,.5);
	vec3 col0 = texture(iChannel0, ref).xyz;
	float lum0 = (col0.x+col0.y+col0.z)/3.;
	
	bool isin = (uv.x > .5+.5*sin(iTime));
	
	vec3 tex,texx,texy;
	vec2 grad; float g=1.;
	
	for (int i=0; i<30; i++) 
	{
		tex = texture(iChannel0, uv).xyz;

		if (isin)
		{
			uvx = uv+vec2(EPS,0.);
			uvy = uv+vec2(0.,EPS);	
		}
		texx = texture(iChannel0, uvx).xyz;
		texy = texture(iChannel0, uvy).xyz;
		grad  = vec2(texx.x-tex.x,texy.x-tex.x); 
//		if (i==0) g = dot(grad,grad);
		
		uv    += EPS*grad;
		uvx.x += EPS*grad.x;
		uvy.y += EPS*grad.y;
	}
	
	vec3 col = texture(iChannel0, uv).xyz;
    vec3 m = vec3(.2,.1,.1);
	float lum = (col.x+col.y+col.z)/3.;
#if 1
	g = 4.*dot(grad,grad);
	g = pow(max(0.,1.-g),30.);
	g = clamp(g,0.,1.);
#endif
	col = g * col / pow(lum,.55);
	
	fragColor = vec4(col, 1.0);
}