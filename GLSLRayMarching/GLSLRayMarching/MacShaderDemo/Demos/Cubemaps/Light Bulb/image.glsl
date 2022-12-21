// Created by evilryu
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

#define BULB 0.0
#define BASE 1.0
#define LINE 2.0
float smin(float a, float b, float k)
{
    float h = clamp(0.5+0.5*(b-a)/k, 0.0, 1.0);
    return mix(b, a, h) - k*h*(1.0-h);
}
void rotate_z(inout vec3 p, float a) { 
	float c,s;vec3 q=p; 
 	c = cos(a); s = sin(a); 
 	p.x = c * q.x - s * q.y; 
 	p.y = s * q.x + c * q.y;
} 

float sphere(vec3 p, float r) {
    return length(p)-r;
}

float upperbulb(vec3 p, vec2 h)
{
    vec2 d = abs(vec2(length(p.xz) ,p.y)) - vec2(h.x*max((1.0-p.y),0.0), h.y);
    return min(max(d.x,d.y),0.0) + length(max(d,0.0));
}

float cylinder(vec3 p, vec2 h)
{
    vec2 d = abs(vec2(length(p.xz) ,p.y)) - vec2(h.x, h.y);
    return min(max(d.x,d.y),0.0) + length(max(d,0.0));
}

vec3 bulb(vec3 pos, float mate){
    float d1 = sphere(pos, 0.4);
    float d2 = upperbulb(vec3(pos.x, pos.y-0.5, pos.z), vec2(0.2, 0.3));
    float d3 = cylinder(vec3(pos.x, pos.y-0.96, pos.z), vec2(0.16+0.011*sin(82.0*pos.y), 0.15));
    float d4 = cylinder(vec3(pos.x, pos.y-10.0, pos.z), vec2(0.03, 10.0));
    float dg = smin(d1, d2, 0.23);
    float d = smin(dg, d3, 0.08);
    if(d3 < dg) mate = BASE;
    if(d4 < d) mate = LINE;
    d = smin(d, d4, 0.2);
    return vec3(d, mate, 1e10);
}

vec3 base(vec3 pos) {
    float mate;
    float d1 = cylinder(vec3(pos.x, pos.y-0.96, pos.z), vec2(0.16+0.011*sin(82.0*pos.y), 0.15));
    float d2 = cylinder(vec3(pos.x, pos.y-11.0, pos.z), vec2(0.03, 10.0));
    rotate_z(pos, 3.14159265*0.5);
    float d3 = cylinder(vec3(pos.x+0.05+0.041*sin(50.0*pos.y), 
                             pos.y, pos.z+0.041*cos(50.0*pos.y)), 
                        vec2(0.005, 0.08));
    float d = smin(d1, d2, 0.2);
    if(d1 < d2) mate = BASE; else mate = LINE;
    if(d > d3) {d = d3; mate = LINE;}
    return vec3(d, mate, d3);
}


vec3 f(vec3 pos){
    vec3 p1 = pos + vec3(0.0, 0.36, 0.5);
    vec3 d1 = bulb(p1, BULB);
    return d1;
}

vec3 f_partial(vec3 pos) {
    vec3 p1 = pos + vec3(0.0, 0.36, 0.5);
    vec3 d1 = base(p1);    
    return d1;
}

vec3 calcnormal(vec3 p){ 
    vec3 e=vec3(0.001,0.0,0.0); 
    return normalize(vec3(f(p+e.xyy).x-f(p-e.xyy).x, 
                      f(p+e.yxy).x-f(p-e.yxy).x, 
                      f(p+e.yyx).x-f(p-e.yyx).x)); 
}

vec3 lighting(vec3 n, vec3 ro, vec3 rd, vec3 p, vec4 mate, float type) {
    vec3 l1dir = normalize(vec3(1.0));
    vec3 l1col = vec3(1.0);
    
    float diff = max(0.0, dot(n, l1dir));
    float back = max(0.0, dot(n, -l1dir));
    float spec = max(0.0, pow(clamp(dot(l1dir, reflect(rd, n)), 0.0, 1.0), 32.0));
    
    vec3 lin;
    
    if(type < BASE) {
        lin = 2.0 * spec * vec3(0.7, 0.9, 1.0);
    } else {
    	lin = (diff + 0.5 * back) * mate.xyz + spec * vec3(1.0);
    }
    return lin;
}

vec3 intersect( in vec3 ro, in vec3 rd, bool partial)
{
  	float t = 0.0;
    vec3 ret = vec3(-1.0, -1.0, 1e5);
    vec3 h = vec3(1.0);
   
    for( int i=0; i<64; i++ )
   	{
      	if( h.x<0.0005 || t>10.0 ) continue;
        if(partial) h = f_partial(ro + rd*t);
        else h = f(ro + rd*t);
       	ret = vec3(t,h.y,min(ret.z,h.z));
        t += h.x;
    }
    
    if(t>10.0) ret = vec3(-1.0, -1.0, ret.z);
    return ret;
}

vec4 material(float id, vec3 pos){
    vec4 mate = vec4(1.0);
    if(id < BULB+1.0) mate = vec4(0.98823, 0.6156, 0.6039, 0.8);
    else if(id < BASE + 1.0) mate = vec4(0.7529, 0.7529, 0.7529, 0.5);
    else if(id < LINE + 1.0) mate = vec4(0.02, 0.02, 0.02, 0.5);
    return mate;
}

vec3 getbg(vec3 pos) {
    return texture(iChannel0, pos).xyz;
}

vec3 getcolor(vec3 ro, vec3 rd, out vec3 pos, out vec4 mate, out vec3 n, 
              out float type, bool partial) {
    vec3 res, col = vec3(0.0);

    res = intersect(ro, rd, partial);
   
    type = res.y;
    col += pow(max(1.0 - res.z,0.0), 21.0+20.0*sin(iTime))*
           (vec3(1.7, 0.6470, 0.0));
    if(res.x > 0.0){
        pos = ro + rd * res.x;
        mate = material(res.y, pos);
        n = calcnormal(pos);
        col += lighting(n, ro, rd, pos, mate, type);
    }
    else
    {
        col += getbg(rd);
        type = 1e10;
    }
    return col;
}


vec3 tracer(vec2 fragCoord) {
    float fov=3.0;
    vec3 col = vec3(0.0);
    vec2 p = 2.0*(fragCoord.xy)/iResolution.xy-1.0;
    p.x*=iResolution.x/iResolution.y;
	vec2 m = iMouse.xy / iResolution.xy;
	if (iMouse.x == 0.0 && iMouse.y == 0.0) {
		m = vec2(iTime * 0.06 + 0.14,0.5);	
	}
	m = -1.0 + 2.0 * m;
	m *= vec2(4.0,-1.5);
	
	vec3 ta = vec3(0.0, 0.0, 0.0);
	vec3 ro = vec3(cos(m.x)*cos(m.y)*fov, sin(m.y)*fov, sin(m.x)*cos(m.y)*fov);

    vec3 cf = normalize(ta-ro); 
    vec3 cs = normalize(cross(cf,vec3(0.0,1.0,0.0))); 
    vec3 cu = normalize(cross(cs,cf)); 
    vec3 rd = normalize(p.x*cs + p.y*cu + fov*cf);
		
    vec3 pos, n;
    vec4 mate;
    float dist, type;
    col = getcolor(ro, rd, pos, mate, n, type, false);
    if(type < BASE) {
        vec3 refr = normalize(refract(rd, n, 0.8));
        float reflection = 0.04 + 0.96 * pow(1.0 - dot(-rd, n), 5.0);
        vec3 reflcol = getbg(normalize(reflect(rd, n)));
        vec3 refrcol = getcolor(pos+refr*0.001, refr, pos, mate, n, type, true);
		col = mix(refrcol*(1.0-reflection)+reflcol*0.3, col, 0.4); 
    }
    return  col;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	vec2 q = fragCoord.xy / iResolution.xy;
	vec3 col = tracer(fragCoord);
	// post
    col=pow(clamp(col,0.0,1.0),vec3(0.45)); 
    col=col*0.6+0.4*col*col*(3.0-2.0*col);
    col=mix(col, vec3(dot(col, vec3(0.33))), -0.7); 
    col*=pow(20.0*q.x*q.y*(1.0-q.x)*(1.0-q.y),0.7); 
    fragColor = vec4( col, 1.0 );
}
