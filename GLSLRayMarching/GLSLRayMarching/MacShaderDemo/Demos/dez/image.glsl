struct polygon{
	vec2 A, B, C;
};
float roundBox(vec2 coord, vec2 pos, vec2 b ){
  return length(max(abs(coord-pos)-b,0.0));
}
float box(vec2 coord, vec2 pos, vec2 size){
	if((coord.x<(pos.x+size.x)) &&
	   (coord.x>(pos.x-size.x)) &&
	   (coord.y<(pos.y+size.y)) && 
	   (coord.y>(pos.y-size.y)) ) 
		return 1.0;
	return 0.0;
}
float sun(vec2 coord, vec2 pos, float size){
	if(length(coord-pos)<size)
		return 1.0;
	return 0.0;
}
float rand(vec2 co){
    return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}
float _sign(vec2 p1, vec2 p2, vec2 p3){
  return (p1.x - p3.x) * (p2.y - p3.y) - (p2.x - p3.x) * (p1.y - p3.y);
}
int PIT(vec2 pt, vec2 v1, vec2 v2, vec2 v3){
	int b1, b2, b3;

	if(_sign(pt, v1, v2) < 0.0) b1=1;
	if(_sign(pt, v2, v3) < 0.0) b2=1;
	if(_sign(pt, v3, v1) < 0.0) b3=1;
	if((b1 == b2) && (b2 == b3))
		return 1;
	return 0;
}

int PIT(vec2 pt, polygon X){
	int b1, b2, b3;

	if(_sign(pt, X.A, X.B) < 0.0) b1=1;
	if(_sign(pt, X.B, X.C) < 0.0) b2=1;
	if(_sign(pt, X.C, X.A) < 0.0) b3=1;
	if((b1 == b2) && (b2 == b3))
		return 1;
	return 0;
}


void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	float vasenKulmakarva=floor(mod(iTime*0.8,2.0))*0.1;
	float oikeaKulmakarva=floor(mod(iTime*0.3,2.0))*0.1;
	float vasenSilma=min(max(0.24*sin(iTime),0.006),0.06);
	float oikeaSilma=min(max(0.24*sin(iTime),0.006),0.06);
	float suu=iTime*10.0;
	vec4 tulos;
	vec4 lopullinentulos=vec4(1.0);
	vec2 uv = fragCoord.xy / iResolution.xy;
	float aspectCorrection = (iResolution.x/iResolution.y);
	vec2 coordinate_entered = 2.0 * uv - 1.0;
	for(float rgbare=0.0; rgbare<2.0; rgbare++){
	vec2 coord = vec2(aspectCorrection,1.0) *coordinate_entered;
	coord.x*=1.0+rgbare*0.009;
	coord*=1.0+rand(coord+iTime)/(pow(iTime,7.0)*3.0)-length(coord)*10.0/(pow(iTime*1.1,24.0));
	coord*=1.0+0.1*sin(iTime*0.1);
	tulos=vec4(vec3(200.0/255.0, 10.0/255.0, 65.0/255.0),1.0);
	if(mod(coord.x+coord.y,0.2)>0.1){
		if(sun(coord,vec2(0.0),0.7)==1.0)
		   tulos.xyz=vec3(1.0,262.0/512.0, 74.0/255.0);
	}
	if(mod(coord.x+coord.y+iTime*0.1,0.2)<0.1){
		for(float j=-6.0; j<6.0; j++)
		for(float i=-5.0; i<5.0; i++){
			vec2 posi=vec2(i/2.0,j/2.0);
			vec2 size=vec2(0.22);
			if(box(coord,posi,size)==1.0 && mod(i+j,2.0)==0.0)
		   		tulos.xyz-=vec3(0.4,0.5,0.3);
		}
	}
	
	for(float i=0.0; i<3.141*2.0; i+=3.141*0.2){
		float aikakerroin=iTime*0.6;
		vec2 A=vec2(0.0,0.0);
		vec2 B=vec2(cos(aikakerroin+i), sin(aikakerroin+i));
		vec2 C=vec2(cos(aikakerroin+i-3.141*0.1), sin(aikakerroin+i-3.141*0.1));
		if(mod(coord.x+coord.y,0.2)>0.1)
		if(PIT(coord, A, B, C)==1)
			tulos.xyz=vec3(1.0,222.0/512.0, 64.0/255.0);
	}
	
	if(roundBox(coord, vec2(0.0,0.0), vec2(0.37, 0.37) )<0.1)
		tulos.xyz=vec3(0.0, 0.0, 0.0);
	
	if(roundBox(coord, vec2(0.0,0.0), vec2(0.33, 0.33) )<0.1 &&
	   roundBox(coord, vec2(0.0,-0.3), vec2(0.11, 0.11) )>0.1)
		tulos.xyz=vec3(0.97, 0.97, 0.97);
	
	if(mod(coord.x+coord.y,0.04)<0.02)
	if(roundBox(coord, vec2(0.3,-0.12), vec2(0.06, oikeaSilma) )<0.01)
		tulos.xyz=vec3(0.0, 0.0, 0.0);
	
	if(mod(coord.x+coord.y,0.04)<0.02)
	if(roundBox(coord, vec2(-0.3,-0.12), vec2(0.06, vasenSilma) )<0.01)
		tulos.xyz=vec3(0.0, 0.0, 0.0);
	
	if(roundBox(coord, vec2(0.0,-0.3), vec2(0.07, 0.07) )<0.1)
		tulos.xyz=vec3(0.97, 0.97, 0.97);
	
	for(float i=-0.1; i<0.1; i+=0.04)
	if(roundBox(coord, vec2(i,-0.35), vec2(0.001, 0.13+sin(suu+i)*0.01) )<0.01)
		tulos.xyz=vec3(0.0, 0.0, 0.0);
		
	if(roundBox(coord, vec2(0.3,0.0+oikeaKulmakarva), vec2(0.08, 0.001) )<0.008)
		tulos.xyz-=vec3(0.7, 0.7, 0.7);
	
	if(roundBox(coord, vec2(-0.3,0.0+vasenKulmakarva), vec2(0.08, 0.001) )<0.008)
		tulos.xyz-=vec3(0.7, 0.7, 0.7);
	tulos.xyz=tulos.xyz-vec3(min(max(-0.44+length(coord)*0.41,0.0),1.0))+vec3(0.06*rand(vec2(coord.x+coord.y,iTime*coord.y*coord.x)));
	
	if(rgbare==0.0)
		lopullinentulos.r=tulos.r;
	if(rgbare==1.0)
		lopullinentulos.gb=tulos.gb;
	}
	if(mod(fragCoord.y,2.0)<1.0)   /////////////////////////
	lopullinentulos.xyz=lopullinentulos.xyz/1.3;
	fragColor = lopullinentulos;
}