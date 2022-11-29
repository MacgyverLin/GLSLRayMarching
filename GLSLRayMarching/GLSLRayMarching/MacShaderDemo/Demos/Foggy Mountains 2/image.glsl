
// Use mouse to control the camera & time.


float time = 0.0;
	 
vec3 rotate(vec3 r, float v){ return vec3(r.x*cos(v)+r.z*sin(v),r.y,r.z*cos(v)-r.x*sin(v));}

float noise( in vec3 x )
{
	float  z = x.z*64.0;
	vec2 offz = vec2(0.317,0.123);
	vec2 uv1 = x.xy + offz*floor(z); 
	vec2 uv2 = uv1  + offz;
	return mix(textureLod( iChannel0, uv1 ,0.0).x,textureLod( iChannel0, uv2 ,0.0).x,fract(z))-0.5;
}

float noises( in vec3 p){
	float a = 0.0;
	for(float i=1.0;i<6.0;i++){
		a += noise(p)/i;
		p = p*2.0 + vec3(0.0,a*0.001/i,a*0.0001/i);
	}
	return a;
}

float base( in vec3 p){
	return noise(p*0.00002)*1200.0;
}

float ground( in vec3 p){
	return base(p)+noises(p.zxy*0.00005+10.0)*40.0*(0.0-p.y*0.01)+p.y;
}

float clouds( in vec3 p){
	float b = base(p);
	p.y += b*0.5/abs(p.y) + 100.0;
	return noises(vec3(p.x*0.3+((time+iMouse.y)*30.0),p.y,p.z)*0.00002)-max(p.y,0.0)*0.00009;
}


void mainImage( out vec4 fragColor, in vec2 fragCoord )
{	
    time        = iTime*5.0+floor(iTime*0.1)*150.0;
    vec2 uv     = fragCoord.xy/(iResolution.xx*0.5)-vec2(1.0,iResolution.y/iResolution.x);
    vec3 campos   = vec3(30.0,500.0,time*8.0);
		 campos.y = 500.0-base(campos);
    vec3 ray   = rotate(normalize(vec3(uv.x,uv.y-sin(time*0.05)*0.2-0.1,1.0).xyz),time*0.01+iMouse.x*0.009);
    vec3 pos    = campos+ray;
    vec3 sun    = vec3(0.0,0.6,-0.4);    	
	
    // raymarch
    float test  = 0.0;
    float fog   = 0.0;
	float dist  = 0.0;

	vec3  p1 = pos;	
	for(float i=1.0;i<50.0;i++){
        test  = ground(p1); 
		fog  += max(test*clouds(p1),fog*0.02);
		p1   += ray*min(test,i*i*0.5);
		dist += test;
		if(abs(test)<10.0||dist>40000.0) break;
	}

	float l     = sin(dot(ray,sun));
	vec3  light = vec3(l,0.0,-l)+ray.y*0.2;
    
	float amb = smoothstep(-100.0,100.0,ground(p1+vec3(0.0,30.0,0.0)+sun*10.0))-smoothstep(1000.0,-0.0,p1.y)*0.7;
	vec3  ground = vec3(0.30,0.30,0.25)+sin(p1*0.001)*0.01+noise(vec3(p1*0.002))*0.1+amb*0.7+light*0.01;
		
	float f = smoothstep(0.0,800.0,fog);
	vec3  cloud = vec3(0.70,0.72,0.70)+light*0.05+sin(fog*0.0002)*0.2+noise(p1)*0.05;

	float h = smoothstep(10000.,40000.0,dist);
	vec3  sky = cloud+ray.y*0.1-0.02;	
	
	fragColor = vec4(sqrt(smoothstep(0.2,1.0,mix(mix(ground,sky,h),cloud,f)-dot(uv,uv)*0.1)),1.0);
	

}