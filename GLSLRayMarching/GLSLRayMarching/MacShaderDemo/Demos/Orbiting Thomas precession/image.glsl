/*
An implication of the rotation of the orbiting body is
that it experiences faster orbital cycles.
At ultra relativistic speeds two times faster.
This is where the correction 1/2 to spin-orbit coupling
in quantum mechanics comes from. (If I am not mistaken...)
*/

#define MAX_ITER 100.
#define MAX_DIST 10.
#define SURF .0001

vec4 fourvel;
//ray origin in the moving coords.
vec4 RO, rd;

vec3 col = vec3(0);



void updateVel(){
    // Fetch the offset from the Buffer A
    fourvel=texelFetch( iChannel0, ivec2(0,0), 0 );
}

vec4 getPos(float time){
    // Fetch the offset from the Buffer B
    
    int r= textureSize(iChannel1, 0).x;
    
    int frame= int(time*frames);
    int i=(frame+r)%r;
    
    vec4 pos =texelFetch( iChannel1, ivec2(i,0), 0 );
        
    return pos;
       
}



mat4 getInverse(float time){
    
    int r= textureSize(iChannel1, 0).x;
    
    int frame= int(time*frames);
    int i=(frame+r)%r;
    
    mat4 M;
    
    
    
    if(iFrame>10){
        for(int j=5;j<=8; j++)
              M[j-5]=texelFetch( iChannel1, ivec2(i,j), 0);
    }else{
        M=mat4(1,0,0,0,
               0,1,0,0,
               0,0,1,0,
               0,0,0,1);
    }
    
    /*
    if(iFrame>10){
        for(int j=1;j<=4; j++)
              M[j-1]=texelFetch( iChannel1, ivec2(i,j), 0);
    }else{
        M=mat4(1,0,0,0,
               0,1,0,0,
               0,0,1,0,
               0,0,0,1);
    }
    
    M=inverse(M);
    */
    
    return M;
   
}

float sdCone( in vec3 p, in vec3 c )
{
    p.y-=.03;
    vec2 q = vec2(length(p.xz), p.y );
    float d1 = -q.y - c.z;
    float d2 = max(dot(q,c.xy), q.y);
    return length(max(vec2(d1,d2),0.0)) + min(max(d1,d2), 0.);
}


float sdBox(vec4 p , vec3 s){
    
    p.xyz= abs(p.xyz)-s;
    return (length(max(p.xyz,0.))+ min(max(p.x,max(p.y,p.z)),0.))/(1.+length(fourvel.xyz));  
}

float sdBoxFrame( vec3 p, vec3 b, float e )
{
       p = abs(p  )-b;
  vec3 q = abs(p+e)-e;

  return min(min(
      length(max(vec3(p.x,q.y,q.z),0.0))+min(max(p.x,max(q.y,q.z)),0.0),
      length(max(vec3(q.x,p.y,q.z),0.0))+min(max(q.x,max(p.y,q.z)),0.0)),
      length(max(vec3(q.x,q.y,p.z),0.0))+min(max(q.x,max(q.y,p.z)),0.0))/(1.+length(fourvel.xyz));
}


float sdAxes(vec4 p , float rad){
    p.xy-=forceCenter.xy;

    p.xyz=fract(p.xyz)-.5; //this creates the grid of reference cubes    
    return  min(length(p.yz)-rad,length(p.xy)-rad); //length(p.xyz)-rad;  
}

// Distance from p to cylinder of radius r with spherical ends centered at a and b.
// This is a rare exception to the rule that all primitives are centered at the origin.
float sdCapsule( vec3 p, vec3 a, vec3 b, float r )
{
	vec3 pa = p-a, ba = b-a;
	float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
	return length( pa - ba*h ) - r;
}


float sdObject(vec4 q){
    q.x-=.0;
    q.z-=.0;
        
    vec4 Object4pos=mix(getPos(q.w),getPos(q.w+1./frames),fract(q.w*frames));
    
    q.xyz-=Object4pos.xyz;

    vec4 qq=vec4(q.xyz,0);
    qq*=getInverse(q.w);

    float d=sdBoxFrame(qq.xyz,vec3(.06),.007);
   // float d=sdBox(qq,vec3(.1));

   return min(d,d);

}



float sdArrow(vec4 q){

    vec3 tail=getPos(q.w).xyz;
    
    float l=length(tail-forceCenter);
    
    vec3 tip=tail-normalize(tail-forceCenter)*l*.4;

    float dist= sdCapsule(q.xyz, tip, tail,clamp(.02*l,.0,.03));
       
    float angle= atan((tail-forceCenter).x, (tail-forceCenter).z);
    
    vec3 p=q.xyz;
    p-=tip;
    p.xy*=rot(PI*.5);
    p.yz*=rot(angle+PI*.5);
        
    return min(dist, sdCone(p, vec3(.25,clamp(.5*l,0.02,.2),clamp(.3*l,.0,.04))));
}

float sdBall(vec3 q){
    return length(q.xyz-forceCenter)-.03;
}


float getDist(vec4 q){
    float dist=sdAxes(q,.05);
    dist= min(dist, sdObject(q));
  
    dist= min(dist, sdArrow(q));

    dist=min(dist, sdBall(q.xyz));

    return dist;
}



void getMaterial(vec4 p){
    if(sdArrow(p)<.001){
        col=vec3(.9,.05,.1);
    }
    else if(sdBall(p.xyz)<.0001){
        col=vec3(.2);
    }
    else if(sdObject(p)<.01){
        col=vec3(0.6,.3,.0)*.4;
    }
    else{
        p.xy-=forceCenter.xy;
        p.xyz=fract(p.xyz)-.5; //this creates the grid of reference cubes
        if(length(p.yz)<length(p.xy)) col= vec3(1.,.3,.3);
        else col= vec3(.3,.3,1.);
    }
}

vec4 getRayDir(vec2 uv, vec4 lookAt, float zoom){

    vec3 f= normalize(lookAt.xyz);
    vec3 r= normalize(cross(vec3(0,1,0),f));
    vec3 u= cross(f,r);
    
    return vec4(normalize(f*zoom+uv.x*r+uv.y*u),lookAt.w/c);
    //the w-component determines how we look into past/future/present.
}

float RayMarch(vec4 ro, vec4 rd, float side){
    float dO=0.;
    float i=0.;
   while(i<MAX_ITER){
      vec4 p= ro+dO*rd; //if rd.w =-c we look back in time as we march further away
      
      float dS=side*getDist(p); 

      dO+=dS;
  
      if(dO>MAX_DIST||dS<SURF){
          break;
      }
      i++;
    } 
    
      return dO;
}

vec3 getNormal(vec4 p){
   vec2 e= vec2(0.001,0);
   float d=getDist(p);
   vec3 n = d-vec3(getDist(p- e.xyyy),getDist(p- e.yxyy),getDist(p- e.yyxy));
   
   return normalize(n);
}


vec3 DrawSlider(vec2 uv,float w,float h,float v)
{
   uv -=vec2(.0,.22);
   
    //Remap value by slider width
    v-=0.5;
    v *= 1. / (w * 2.);
    v+= .5;
    v = clamp(v,0.,1.);
    
    vec2 a = abs( uv /= vec2(w,h) );
    return max(a.x,a.y) < 1.
                ? uv.x +1. < v*2. 
                   ? vec3(v,1.-v,0)
                   : vec3(.1)
                   : vec3(0);
}


void mainImage( out vec4 fragColor, in vec2 fragCoord )
{  
    
    vec2 uv = (fragCoord-.5*iResolution.xy)/iResolution.y;
    vec2 m= vec2(.5);; 


    if(iMouse.w!=0.)   {    
        m = (iMouse.xy-.5)/iResolution.xy;
    }
    
    updateVel();
        
    //ray origin in lab coordinates:
    RO= vec4(-.4,0,0,t);  
    
    if(m!=vec2(0)){
        RO.xy*=rot((m.y-.5)*PI);
       RO.xz*=rot(-(m.x-.5)*2.*PI);
    }

    float zoom= 1.;
    
    //lookat in our moving coords:
    vec4 lookAt;
    lookAt = vec4(c, 0, 0, -1);
    
     
    if(m!=vec2(0)){
        lookAt.xy*=rot((m.y-.5)*PI);
        lookAt.xz*=rot(-(m.x-.5)*2.*PI);
    }
      
    //ray in our moving coords:
    vec4 ray= getRayDir(uv, lookAt, zoom);
  
    //ray direction from  moving coords to lab coords:
    rd= ray; //TransformMatrix*ray; 
    
 
    vec4 p=RO;        
   
    //the usual raymarch in lab coords:
    float d= RayMarch(p, rd, 1.);
    
    
     if(d<MAX_DIST){ //if we hit an object:
          p= p+ d*rd;
          
          getMaterial(p);

          vec3 n= getNormal(p);
      
          float dif= dot(n, normalize(vec3(-3,2,1)))*.3+.4;
          col/=length(d*rd)*.2;
          col*=dif*dif;            
      
    }
   

    fragColor = vec4(col,1.0); 

}