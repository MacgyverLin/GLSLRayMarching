//Building on ideas from
//https://www.shadertoy.com/view/fd3SRN
//https://www.shadertoy.com/view/fsySWm
//https://www.shadertoy.com/view/stdGz4
//https://www.shadertoy.com/view/7sKGRy
//https://www.shadertoy.com/view/fsyGD3
//https://www.shadertoy.com/view/fdyGDt
//https://www.shadertoy.com/view/7dVGDd
//https://www.shadertoy.com/view/NsKGDy

//I had some plans to make a more elaborate shape using the "fully animated subdivision"
//but it ended up not looking that interesting when applied to an octree and it's too
//expensive to make shapes out of multiple "sheets" of this.

//I hope you enjoy it none the less :) 
//(sorry if it's expensive I didn't do much opmimizing)

#define MDIST 150.0
#define STEPS 164.0
#define pi 3.1415926535
#define pmod(p,x) (mod(p,x)+0.5*(x))
#define rot(a) mat2(cos(a),sin(a),-sin(a),cos(a))

//this is a useless trick but it's funny
#define vmm(v,minOrMax) minOrMax(v.x,minOrMax(v.y,v.z))

//iq box sdf
float ebox( vec3 p, vec3 b ){
  vec3 q = abs(p) - b;
  return length(max(q,0.0)) + min(vmm(q,max),0.0);
}
//iq palette
vec3 pal( in float t, in vec3 a, in vec3 b, in vec3 c, in vec3 d ){
    return a + b*cos(2.*pi*(c*t+d));
}
float h11 (float a) {
    return fract(sin((a)*12.9898)*43758.5453123);
}
//https://www.shadertoy.com/view/fdlSDl
vec2 tanha(vec2 x) {
  vec2 x2 = x*x;
  return clamp(x*(27.0 + x2)/(27.0+9.0*x2), -1.0, 1.0);
}
float tanha(float x) {
  float x2 = x*x;
  return clamp(x*(27.0 + x2)/(27.0+9.0*x2), -1.0, 1.0);
}

struct sdResult
{
    vec2 center;
    vec2 dim;
    float id;
    float vol;
};

sdResult subdiv(vec2 p,float seed){
    vec2 dMin = vec2(-10.);
    vec2 dMax = vec2(10.);
    float t = iTime*0.6;
    float t2 = iTime;
    vec2 dim = dMax - dMin;
    float id = 0.;
    float ITERS = 6.;
    
    float MIN_SIZE = 0.1;
    float MIN_ITERS = 1.;
    
    //big thanks to @0b5vr for letting me use his cleaner subdiv implementation
    //https://www.shadertoy.com/view/NsKGDy
    vec2 diff2 = vec2(1);
    for(float i = 0.;i<ITERS;i++){
        vec2 divHash=tanha(vec2(sin(t2*pi/3.+id+i*t2*0.05),cos(t2*pi/3.+h11(id)*100.+i*t2*0.05))*3.)*0.35+0.5;
        //divHash=vec2(sin(t*pi/3.+id),cos(t*pi/3.+h11(id)*100.))*0.5+0.5;
        //if(iMouse.z>0.5){divHash = mix(divHash,M,0.9);}
        divHash = mix(vec2(0.5),divHash,tanha(sin(t*0.8)*5.)*0.2+0.4);
        vec2 divide = divHash * dim + dMin;
        divide = clamp(divide, dMin + MIN_SIZE+0.01, dMax - MIN_SIZE-0.01);
        vec2 minAxis = min(abs(dMin - divide), abs(dMax - divide));
        float minSize = min( minAxis.x, minAxis.y);
        bool smallEnough = minSize < MIN_SIZE;
        if (smallEnough && i + 1. > MIN_ITERS) { break; }
        dMax = mix( dMax, divide, step( p, divide ));
        dMin = mix( divide, dMin, step( p, divide ));
        diff2 =step( p, divide)-
        vec2(h11(diff2.x+seed)*10.,h11(diff2.y+seed)*10.);
        id = length(diff2)*100.0;
        dim = dMax - dMin;
    }
    vec2 center = (dMin + dMax)/2.0;
    sdResult result;
    result.center = center;
    result.id = id;
    result.dim = dim;
    result.vol = dim.x*dim.y;
    return result;
}
vec3 rdg = vec3(0);
float dibox(vec3 p,vec3 b,vec3 rd){
    vec3 dir = sign(rd)*b;   
    vec3 rc = (dir-p)/rd;
    return min(rc.x,rc.z)+0.01; 
}
bool traverse = true;
vec3 map(vec3 p){
    float seed = sign(p.y)-0.3;
    seed = 1.;
    //p.y = abs(p.y)-4.;

    vec2 a = vec2(99999,1);
    vec2 b = vec2(2);
    
    a.x = p.y-2.0;
    float id = 0.;
    if(a.x<0.1||!traverse){
        float t = iTime;
        sdResult sdr = subdiv(p.xz,seed);
        vec3 centerOff = vec3(sdr.center.x,0,sdr.center.y);
        vec2 dim = sdr.dim;

        float rnd = 0.05;
        float size = min(dim.y,dim.x)*1.;
        //size = 1.;
        size+=(sin((centerOff.x+centerOff.z)*0.6+t*4.5)*0.5+0.5)*2.;
        size = min(size,4.0);
        a.x = ebox(p-centerOff-vec3(0,0,0),vec3(dim.x,size,dim.y)*0.5-rnd)-rnd;
        if(traverse){
            b.x = dibox(p-centerOff,vec3(dim.x,1,dim.y)*0.5,rdg);
            a = (a.x<b.x)?a:b;
        }
        id = sdr.id;
    }
    return vec3(a,id);
}
vec3 norm(vec3 p){
    vec2 e = vec2(0.01,0.);
    return normalize(map(p).x-vec3(
    map(p-e.xyy).x,
    map(p-e.yxy).x,
    map(p-e.yyx).x));
}
void mainImage( out vec4 fragColor, in vec2 fragCoord ){
    vec2 R = iResolution.xy;
    vec2 uv = (fragCoord-0.5*R.xy)/R.y;
    vec3 col = vec3(0);
    
    vec3 ro = vec3(0,6.,-12)*1.2;

    ro.xz*=rot(0.35);
    vec3 lk = vec3(-1,-3,0.5);
    if(iMouse.z>0.){
       ro*=2.;
       lk = vec3(0);
       ro.yz*=rot(2.0*(iMouse.y/iResolution.y-0.5));
       ro.zx*=rot(-9.0*(iMouse.x/iResolution.x-0.5));
    }
    vec3 f = vec3(normalize(lk-ro));
    vec3 r = normalize(cross(vec3(0,1,0),f));
    vec3 rd = normalize(f*(1.8)+r*uv.x+uv.y*cross(f,r));
    rdg = rd;
    vec3 p = ro;
    float dO =0.;
    vec3 d;
    bool hit = false;
        
    for(float i = 0.; i<STEPS; i++){
        p = ro+rd*dO;
        d = map(p);
        dO+=d.x;
        if(d.x<0.005){
            hit = true;
            break;
        }
        if(dO>MDIST)break;
    }
    
    if(hit&&d.y!=2.0){
        traverse = false;
        vec3 n = norm(p);
        vec3 r = reflect(rd,n);
        vec3 e = vec3(0.5);
        vec3 al = pal(fract(d.z)*0.35-0.8,e*1.2,e,e*2.0,vec3(0,0.33,0.66));
        col = al;
        vec3 ld = normalize(vec3(0,45,0)-p);

        //sss from nusan
        float sss=0.1;
        float sssteps = 10.;
        for(float i=1.; i<sssteps; ++i){
            float dist = i*0.2;
            sss += smoothstep(0.,1.,map(p+ld*dist).x/dist)/(sssteps*1.5);
        }
        sss = clamp(sss,0.0,1.0);
        
        float diff = max(0.,dot(n,ld))*0.7+0.3;
        float amb = dot(n,ld)*0.45+0.55;
        float spec = pow(max(0.,dot(r,ld)),13.0);
        //blackle ao 
        #define AO(a,n,p) smoothstep(-a,a,map(p+n*a).x)
        float ao = AO(0.1,n,p)*AO(.2,n,p)*AO(.3,n,p);

        spec = smoothstep(0.,1.,spec);
        col = vec3(0.204,0.267,0.373)*
        mix(vec3(0.169,0.000,0.169),vec3(0.984,0.996,0.804),mix(amb,diff,0.75))
        +spec*0.3;
        col+=sss*al;
        col*=mix(ao,1.,0.65);
        col = pow(col,vec3(0.85));
    }
    else{
    col = mix(vec3(0.373,0.835,0.988),vec3(0.424,0.059,0.925),length(uv));

    }
    
    col *=1.0-0.5*pow(length(uv*vec2(0.8,1.)),2.7);
    vec3 col2 = smoothstep(vec3(0.0, 0.0, 0.0), vec3(1.1, 1.1, 1.3), col);
    col = mix(col,col2,0.5)*1.05;

    fragColor = vec4(col,1.0);
}