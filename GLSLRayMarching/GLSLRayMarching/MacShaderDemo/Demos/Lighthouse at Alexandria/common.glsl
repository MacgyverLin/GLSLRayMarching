float random(in vec2 st){
    return fract(sin(dot(st.xy,vec2(12.9898,78.233)))*43758.5453123);
}
// Based on Morgan McGuire @morgan3d
// https://www.shadertoy.com/view/4dS3Wd
float noise(in vec2 st){
    vec2 i=floor(st);
    vec2 f=fract(st);
    float a=random(i);
    float b=random(i+vec2(1.,0.));
    float c=random(i+vec2(0.,1.));
    float d=random(i+vec2(1.,1.));
    
    vec2 u=f*f*(3.-2.*f);
    
    return mix(a,b,u.x)+
    (c-a)*u.y*(1.-u.x)+
    (d-b)*u.x*u.y;
}
vec4 mod289(vec4 x){return x-floor(x*(1./289.))*289.;}
vec4 perm(vec4 x){return mod289(((x*34.)+1.)*x);}
vec2 hash2(float n){return fract(sin(vec2(n,n+1.))*vec2(43758.5453123,22578.1459123));}
float noise(vec3 p){
    vec3 a=floor(p);
    vec3 d=p-a;
    d=d*d*(3.-2.*d);
    
    vec4 b=a.xxyy+vec4(0.,1.,0.,1.);
    vec4 k1=perm(b.xyxy);
    vec4 k2=perm(k1.xyxy+b.zzww);
    
    vec4 c=k2+a.zzzz;
    vec4 k3=perm(c);
    vec4 k4=perm(c+1.);
    
    vec4 o1=fract(k3*(1./41.));
    vec4 o2=fract(k4*(1./41.));
    
    vec4 o3=o2*d.z+o1*(1.-d.z);
    vec2 o4=o3.yw*d.x+o3.xz*(1.-d.x);
    
    return o4.y*d.y+o4.x*(1.-d.y);
}

float fbm6(in vec3 p)
{
    float n=0.;
    n+=1.*noise(p*1.);
    n+=.50000*noise(p*2.);
    n+=.25000*noise(p*4.);
    n+=.12500*noise(p*8.);
    n+=.06250*noise(p*16.);
    n+=.03125*noise(p*32.);
    return n;
}



#define OCTAVES 1
float fbm(in vec3 st){
    // Initial values
    float value=0.;
    float amplitude=.5;
    float frequency=0.;
    //
    // Loop of octaves
    for(int i=0;i<OCTAVES;i++){
        value+=amplitude*noise(st);
        st*=2.;
        amplitude*=.5;
    }
    return value;
}
float fbm(in vec2 st,int oct){
    // Initial values
    float value=0.;
    float amplitude=.5;
    float frequency=0.;
    //
    // Loop of octaves
    for(int i=0;i<oct;i++){
        value+=amplitude*noise(st);
        st*=2.;
        amplitude*=.5;
    }
    return value;
}

mat2 Rot(float a){
    float s=sin(a),c=cos(a);
    return mat2(c,-s,s,c);
}

float hash(uint n)
{
    n=(n<<13U)^n;
    n=n*(n*n*15731U+789221U)+1376312589U;
    return uintBitsToFloat((n>>9U)|0x3f800000U)-1.;
}
float sdBox(vec3 p,vec3 b)
{
    vec3 q=abs(p)-b;
    return length(max(q,0.))+min(max(q.x,max(q.y,q.z)),0.);
}

float sdPyramid(vec3 p,float h)
{
    float m2=h*h+.25;
    
    p.xz=abs(p.xz);
    p.xz=(p.z>p.x)?p.zx:p.xz;
    p.xz-=.5;
    
    vec3 q=vec3(p.z,h*p.y-.5*p.x,h*p.x+.5*p.y);
    
    float s=max(-q.x,0.);
    float t=clamp((q.y-.5*p.z)/(m2+.25),0.,1.);
    
    float a=m2*(q.x+s)*(q.x+s)+q.y*q.y;
    float b=m2*(q.x+.5*t)*(q.x+.5*t)+(q.y-m2*t)*(q.y-m2*t);
    
    float d2=min(q.y,-q.x*m2-q.y*.5)>0.?0.:min(a,b);
    
    return sqrt((d2+q.z*q.z)/m2)*sign(max(q.z,-p.y));
}
float sdOctahedron(vec3 p,float s)
{
    p=abs(p);
    return(p.x+p.y+p.z-s)*.57735027;
}
float sdCappedCylinder(vec3 p,float h,float r)
{
    vec2 d=abs(vec2(length(p.xz),p.y))-vec2(h,r);
    return min(max(d.x,d.y),0.)+length(max(d,0.));
}
float sdCone(in vec3 p,in vec2 c,float h)
{
    vec2 q=h*vec2(c.x/c.y,-1.);
    
    vec2 w=vec2(length(p.xz),p.y);
    vec2 a=w-q*clamp(dot(w,q)/dot(q,q),0.,1.);
    vec2 b=w-q*vec2(clamp(w.x/q.x,0.,1.),1.);
    float k=sign(q.y);
    float d=min(dot(a,a),dot(b,b));
    float s=max(k*(w.x*q.y-w.y*q.x),k*(w.y-q.y));
    return sqrt(d)*sign(s);
}
float opSmoothUnion(float d1,float d2,float k)
{
    float h=max(k-abs(d1-d2),0.);
    return min(d1,d2)-h*h*.25/k;
    //float h = clamp( 0.5 + 0.5*(d2-d1)/k, 0.0, 1.0 );
    //return mix( d2, d1, h ) - k*h*(1.0-h);
}