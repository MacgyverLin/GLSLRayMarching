float time;
vec3 pln;

float terrain(vec3 p)
{
	float nx=floor(p.x)*10.0+floor(p.z)*100.0,center=0.0,scale=2.0;
	vec4 heights=vec4(0.0,0.0,0.0,0.0);
	
	for(int i=0;i<5;i+=1)
	{
		vec2 spxz=step(vec2(0.0),p.xz);
		float corner_height = mix(mix(heights.x, heights.y, spxz.x),
								  mix(heights.w, heights.z, spxz.x),spxz.y);
		
		vec4 mid_heights=(heights+heights.yzwx)*0.5;
		
		heights =mix(mix(vec4(heights.x,mid_heights.x,center,mid_heights.w),
					     vec4(mid_heights.x,heights.y,mid_heights.y,center), spxz.x),
					 mix(vec4(mid_heights.w,center,mid_heights.z,heights.w), 
						 vec4(center,mid_heights.y,heights.z,mid_heights.z), spxz.x), spxz.y);
		
		nx=nx*4.0+spxz.x+2.0*spxz.y;
		
		center=(center+corner_height)*0.5+cos(nx*20.0)/scale*30.0;
		p.xz=fract(p.xz)-vec2(0.5);
		p*=2.0;
		scale*=2.0;
	}
	
		
	float d0=p.x+p.z;
	
	vec2 plh=mix( mix(heights.xw,heights.zw,step(0.0,d0)),
				  mix(heights.xy,heights.zy,step(0.0,d0)), step(p.z,p.x));
	
	pln=normalize(vec3(plh.x-plh.y,2.0,(plh.x-center)+(plh.y-center)));

	if(p.x+p.z>0.0)
		pln.xz=-pln.zx;
	
	if(p.x<p.z)
		pln.xz=pln.zx;
	
	p.y-=center;	
	return dot(p,pln)/scale;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	time=iTime*0.4;
	vec2 uv=(fragCoord.xy / iResolution.xy)*2.0-vec2(1.0);
	uv.x*=iResolution.x/iResolution.y;
	
	float sc=(time+sin(time*0.2)*4.0)*0.8;
	vec3 camo=vec3(sc+cos(time*0.2)*0.5,0.7+sin(time*0.3)*0.4,0.3+sin(time*0.4)*0.8);
	vec3 camt=vec3(sc+cos(time*0.04)*1.5,-1.5,0.0);
	vec3 camd=normalize(camt-camo);
	
	vec3 camu=normalize(cross(camd,vec3(0.5,1.0,0.0))),camv=normalize(cross(camu,camd));
	camu=normalize(cross(camd,camv));
	
	mat3 m=mat3(camu,camv,camd);
	
	vec3 rd=m*normalize(vec3(uv,1.8)),rp;
	
	float t=0.0;
	
	for(int i=0;i<100;i+=1)
	{
		rp=camo+rd*t;
		float d=terrain(rp);
		if(d<4e-3)
			break;
		t+=d;
	}

	vec3 ld=normalize(vec3(1.0,0.6,2.0));
	fragColor.rgb=mix(vec3(0.1,0.1,0.5)*0.4,vec3(1.0,1.0,0.8),pow(0.5+0.5*dot(pln,ld),0.7));
	fragColor.rgb=mix(vec3(0.5,0.6,1.0),fragColor.rgb,exp(-t*0.02));
	
}
