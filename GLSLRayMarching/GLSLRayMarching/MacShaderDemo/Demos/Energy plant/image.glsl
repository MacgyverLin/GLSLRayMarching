#define PI acos(-1.0)
#define TAU PI*2.0

const float maxd=80.0;

mat2 rot(float a)
{
    float s=sin(a), c=cos(a);
    return mat2(c,s,-s,c);
}

float lpNorm(vec3 p, float n)
{
	p = pow(abs(p), vec3(n));
	return pow(p.x+p.y+p.z, 1.0/n);
}

vec2 pSFold(vec2 p,float n)
{
    float h=floor(log2(n)),a =6.2831*exp2(h)/n;
    for(float i=0.0; i<h+2.0; i++)
    {
	 	vec2 v = vec2(-cos(a),sin(a));
		float g= dot(p,v);
 		p-= (g - sqrt(g * g + 5e-3))*v;
 		a*=0.5;
    }
    return p;
}

vec2 sFold45(vec2 p, float k)
{
    vec2 v = vec2(-1,1)*0.7071;
    float g= dot(p,v);
 	return p-(g-sqrt(g*g+k))*v;
}

float frameBox(vec3 p, vec3 s, float r)
{   
    p = abs(p)-s;
    p.yz=sFold45(p.yz, 1e-3);
    p.xy=sFold45(p.xy, 1e-3);
    p.x = max(0.0,p.x);
	return lpNorm(p,5.0)-r;
}

float sdRoundBox( vec3 p, vec3 b, float r )
{
  vec3 q = abs(p) - b;
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0) - r;
}

float deObj(vec3 p)
{   
    return min(min(sdRoundBox(p,vec3(0.3),0.1),frameBox(p,vec3(0.7),0.05)),frameBox(p,vec3(0.5),0.01));
}

float g = 0.0;

float map(vec3 p)
{
    float de=1e9;
    p.z-=iTime*1.5;
    p.z=mod(p.z,12.)-6.;
    vec3 q=p;
    p.xy=pSFold(p.xy,6.0);
    p.y-=5.;
    float s=1.0;
    for(float i=0.;i<6.;i++)
    {
        p.xy=abs(p.xy)-.5;
        p.z=abs(p.z)-.3;
        p.xy*=rot(-0.05);
        p.zy*=rot(0.1);
        s*=0.7;
        p*=s;
        p.xy*=rot(0.05);
        p.y-=0.3;
        vec3 sp=p/s;
        de=min(de,
           min(sdRoundBox(sp,vec3(0.3),0.1),
               frameBox(sp,vec3(0.7),0.05)));
    }
    q.z-=clamp(q.z,-1.,1.);
    float d=length(q)-0.5;
    g += 0.1/(0.2+d*d*5.0); // Distance glow by balkhan
    de=min(de,d+0.2);
    return de;
}

vec3 calcNormal(vec3 pos){
  vec2 e = vec2(1,-1) * 0.002;
  return normalize(
    e.xyy*map(pos+e.xyy)+e.yyx*map(pos+e.yyx)+ 
    e.yxy*map(pos+e.yxy)+e.xxx*map(pos+e.xxx)
  );
}

float march(vec3 ro, vec3 rd, float near, float far)
{
    float t=near,d;
    for(int i=0;i<100;i++)
    {
        t+=d=map(ro+rd*t);
        if (d<0.001) return t;
        if (t>=far) return far;
    }
    return far;
}

float calcShadow( vec3 light, vec3 ld, float len ) {
	float depth = march( light, ld, 0.0, len );	
	return step( len - depth, 0.01 );
}

vec3 doColor(vec3 p)
{
    return vec3(0.3,0.5,0.8)+cos(p*0.2)*.5+.5;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{  
    vec2 uv = (fragCoord * 2.0 - iResolution.xy) / iResolution.y;
    vec3 ro=vec3(2.5,3.5,8);
    vec3 ta =vec3(-1,0,0);
    vec3 w = normalize(ta-ro);
    vec3 u = normalize(cross(w,vec3(0,1,0)));
    vec3 rd=mat3(u,cross(u,w),w)*normalize(vec3(uv,2.0));
    vec3 col= vec3(0.05,0.05,0.1);
    float t=march(ro,rd,0.0,maxd);
    if(t<maxd)
    {
        vec3 p=ro+rd*t;
        col=doColor(p); 
        vec3 n = calcNormal(p);      
		vec3 lightPos=vec3(5,5,1);
    	vec3 li = lightPos - p;
		float len = length( li );
		li /= len;
		float dif = clamp(dot(n, li), 0.0, 1.0);
        float sha = calcShadow( lightPos, -li, len );
        col *= max(sha*dif, 0.2);
        float rimd = pow(clamp(1.0 - dot(reflect(-li, n), -rd), 0.0, 1.0), 2.5);
		float frn = rimd+2.2*(1.0-rimd);
    	col *= frn*0.8;
        col *= max(0.5+0.5*n.y, 0.0);
        col *= exp2(-2.*pow(max(0.0, 1.0-map(p+n*0.3)/0.3),2.0));
        col += vec3(0.8,0.6,0.2)*pow(clamp(dot(reflect(rd, n), li), 0.0, 1.0), 20.0);
        col = mix(vec3(0.1,0.1,0.2),col,  exp(-0.001*t*t));
		col += vec3(0.7,0.3,0.1)*g*(1.5+0.8*sin(iTime*3.5));
    	col = clamp(col,0.0,1.0);
            
    }
    col=pow(col,vec3(1.5));
    fragColor.xyz = col;
}
