const float pi = 3.1415927;

//From Dave (https://www.shadertoy.com/view/XlfGWN)
float hash13(vec3 p){
	p  = fract(p * vec3(.16532,.17369,.15787));
    p += dot(p.xyz, p.yzx + 19.19);
    return fract(p.x * p.y * p.z);
}
float hash(float x){ return fract(cos(x*124.123)*412.0); }
float hash(vec2 x){ return fract(cos(dot(x.xy,vec2(2.31,53.21))*124.123)*412.0); }
float hash(vec3 x){ return fract(cos(dot(x.xyz,vec3(2.31,53.21,17.7))*124.123)*412.0); }


float sdSphere( vec3 p, float s )
{
  return length(p)-s;
}

float sdCappedCylinder( vec3 p, vec2 h )
{
  vec2 d = abs(vec2(length(p.xz),p.y)) - h;
  return min(max(d.x,d.y),0.0) + length(max(d,0.0));
}

float sdTorus( vec3 p, vec2 t )
{
  vec2 q = vec2(length(p.xz)-t.x,p.y);
  return length(q)-t.y;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	vec2 pp = fragCoord.xy/iResolution.xy;
	pp = -1.0 + 2.0*pp;
	pp.x *= iResolution.x/iResolution.y;

	vec3 lookAt = vec3(0.0, -0.1, 0.0);
    
    float eyer = 2.0;
    float eyea = (iMouse.x / iResolution.x) * pi * 2.0;
    float eyea2 = ((iMouse.y / iResolution.y)-0.24) * pi * 2.0;
    
	vec3 ro = vec3(
        eyer * cos(eyea) * sin(eyea2),
       eyer * cos(eyea2),
        eyer * sin(eyea) * sin(eyea2)); //camera position
    
    
	vec3 front = normalize(lookAt - ro);
	vec3 left = normalize(cross(normalize(vec3(0.0,1,-0.1)), front));
	vec3 up = normalize(cross(front, left));
	vec3 rd = normalize(front*1.5 + left*pp.x + up*pp.y); // rect vector
    
    
    vec3 bh = vec3(0.0,0.0,0.0);
    float bhr = 0.3;
    float bhmass = 5.0;
   	bhmass *= 0.001; // premul G
    
    vec3 p = ro;
    vec3 pv = rd;
    
    p += pv * hash13(rd + vec3(iTime)) * 0.02;
    
    float dt = 0.02;
    
    vec3 col = vec3(0.0);
    
    float noncaptured = 1.0;
    
    vec3 c1 = vec3(0.5,0.35,0.1);
    vec3 c2 = vec3(1.0,0.8,0.6);
    
    
    for(float t=0.0;t<1.0;t+=0.005)
    {
        p += pv * dt * noncaptured;
        
        // gravity
        vec3 bhv = bh - p;
        float r = dot(bhv,bhv);
        pv += normalize(bhv) * ((bhmass) / r);
        
        noncaptured = smoothstep(0.0,0.01,sdSphere(p-bh,bhr));
        
        
        
        // texture the disc
        // need polar coordinates of xz plane
        float dr = length(bhv.xz);
        float da = atan(bhv.x,bhv.z);
        vec2 ra = vec2(dr,da * (0.01 + (dr - bhr)*0.002) + 2.0 * pi + iTime*0.02 );
        ra *= vec2(10.0,20.0);
        
        vec3 dcol = mix(c2,c1,pow(length(bhv)-bhr,2.0)) * max(0.0,texture(iChannel1,ra*vec2(0.1,0.5)).r+0.05) * (4.0 / ((0.001+(length(bhv) - bhr)*50.0) ));
        
        col += max(vec3(0.0),dcol * step(0.0,-sdTorus( (p * vec3(1.0,50.0,1.0)) - bh, vec2(0.8,0.99))) * noncaptured);
        
        //col += dcol * (1.0/dr) * noncaptured * 0.01;
        
        // glow
        col += vec3(1.0,0.9,0.7) * (1.0/vec3(dot(bhv,bhv))) * 0.003 * noncaptured;
        
        //if (noncaptured<1.0) break;
        
    }
    
    // background - projection not right
    //col += pow(texture(iChannel0,pv.xy+vec2(1.5)).rgb,vec3(3.0));
    
    
    fragColor = vec4(col,1.0);
}