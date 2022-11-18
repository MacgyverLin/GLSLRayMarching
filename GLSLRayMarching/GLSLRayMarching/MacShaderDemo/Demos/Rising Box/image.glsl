#define time (iTime+100.)

mat3 lookat(vec3 d, vec3 up)
{
	vec3 w = normalize(d),u = normalize(cross(w,up));
    return (mat3(u,cross(u,w),w));
}

mat2 rotate(float a)
{
	return mat2(cos(a), sin(a), -sin(a), cos(a));	
}

/*
mat3 rotate(in vec3 axis, in float theta)
{
  axis = normalize(axis);
  float x = axis.x, y = axis.y, z = axis.z, s = sin(theta), c = cos(theta), o = 1.0-c;
  return mat3(
    o*x*x+c,o*x*y+z*s,o*z*x-y*s,
    o*x*y-z*s,o*y*y+c,o*y*z+x*s,
    o*z*x+y*s,o*y*z-x*s,o*z*z+c
    );
}
*/

/*
vec3 rotate(vec3 p, vec3 axis, float theta) 
{
 	vec4 q = vec4(normalize(axis)*sin(theta/2.), cos(theta/2.)); // quaternion
    return p+2.*cross(cross(p, q.xyz)-q.w*p, q.xyz);
}
*/

vec3 rotate(vec3 p,vec3 axis,float theta)
{
    axis=normalize(axis);
    vec3 v = cross(p, axis), u = cross(axis,v);
    return u * cos(theta) + v * sin(theta) + axis * dot(p, axis);   
}

float hash(float n)
{
    return fract(sin(n) * 43758.5453123);
}

float udRoundBox( vec3 p, vec3 b, float r )
{
  return length(max(abs(p)-b,0.0))-r;
}

float map(in vec3 p)
{
    vec3 g = vec3(floor(p.xz/4.0),0);
    p.xz = mod(p.xz,4.0) -2.0;
    float n = max(0.5,hash(dot(g.xy,vec2(10,180))));
    p.y-=n*n*time*7.;
    float s = 10.*hash(dot(g.xy,vec2(5,10)));
    if(s<3.) return 1.0;
    g.z = floor(p.y/s);
    p.y = mod(p.y,s)-s/2.;
    if(hash(dot(g,vec3(5,70,1)))<0.6) return 1.0;
	p = rotate(p, vec3(
        hash(dot(g,vec3(5,27,123)))*2.-1.,
        hash(dot(g,vec3(15,370,23)))*2.-1.,
        hash(dot(g,vec3(25,570,3)))*2.-1.
        ), time + hash(dot(g,vec3(25,570,553)))*3.);
	    /*
	p *= rotate(vec3(
        hash(dot(g,vec3(5,27,123)))*2.-1.,
        hash(dot(g,vec3(15,370,23)))*2.-1.,
        hash(dot(g,vec3(25,570,3)))*2.-1.
        ), time + hash(dot(g,vec3(25,570,553)))*3.);
	*/
    return udRoundBox(p,vec3(0.5),0.2);
}

vec3 calcNormal(in vec3 pos){
  vec2 e = vec2(1, -1) * 0.002;
  return normalize(
    e.xyy*map(pos+e.xyy)+e.yyx*map(pos+e.yyx)+ 
    e.yxy*map(pos+e.yxy)+e.xxx*map(pos+e.xxx)
  );
}

vec3 doColor(vec3 p)
{
    if (p.y>10.0) return vec3(0,0.7,0.8);
    if (p.y>0.0) return vec3(0.3,0.7,0.2);
    return vec3(0);
}

vec3 rayCastPlane(vec3 ro, vec3 rd, vec3 pos, vec3 nor, vec3 up)
{
	float z = dot(pos-ro,nor)/dot(rd,nor);
    vec3 p=ro+rd*z, a=p-pos, u=normalize(cross(nor,up)),v=normalize(cross(u,nor));
    return vec3(-dot(a,u),dot(a,v),z);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 p = (fragCoord*2.-iResolution.xy)/iResolution.y;
	vec3 ro = vec3(0.0, 25.0, 20.0);
    ro.xz *= rotate(iTime*0.1);
    vec3 rd = lookat(-ro,vec3(0,1,0))*normalize(vec3(p,2));	
	vec3 col = mix(vec3(0.05, 0.05, 0.3), vec3(0.8), smoothstep(.5, 2.5, length(p*vec2(1,2))));
	const float maxd = 80.0, precis = 0.01;
	float t = 0.0, d;
 	for(int i = 0; i < 150; i++)
  	{
		vec3 p=ro + rd * t;
    	t += d = min(map(p), 1.0); // rewrite 2018/01/10
        //t += d = min(map(p),
        //    min((step(0.0,rd.x)-fract(p.x))/rd.x, (step(0.0,rd.z)-fract(p.z))/rd.z)+precis);
    	if(d < precis || t > maxd) break;
  	}
  	if(d < precis)
  	{
	  	vec3 p = ro + rd * t;
	 	vec3 nor = calcNormal(p);
    	vec3 li = normalize(vec3(1));
        vec3 bg = col;
        col = doColor(p);
        float dif = clamp(dot(nor, li), 0.3, 1.0);
        float amb = max(0.5 + 0.5 * nor.y, 0.0);
        float spc = pow(clamp(dot(reflect(normalize(p - ro), nor), li), 0.0, 1.0), 30.0);
        col *= dif * amb ;
        col += spc;
        col = clamp(col,0.0,1.0);
        col = mix(bg, col, exp(-t*t*0.0001));
  		col = pow(col, vec3(0.6));        
    } 
    vec3 c = rayCastPlane(ro, rd, vec3(0), vec3(0,1,0), vec3(0,0,1));
    if (c.z<t)
    {
 		col = mix(col,vec3(1,0.95,0.9),smoothstep(30.,0.,length(c.xy))) ;
        col = mix(col,vec3(0.9,0.5,0.2),smoothstep(1.,0.,map(ro+rd*c.z)));
   	}
    c = rayCastPlane(ro, rd, vec3(0,10,0), vec3(0,1,0), vec3(0,0,1));
    if (c.z<t)
    {
 		col = mix(col,vec3(0.8,0.7,0.2),smoothstep(1.,0.,map(ro+rd*c.z))) ;
	}    
    fragColor = vec4(col, 1.0);;
}