// "RayMarching starting point" 
// by Martijn Steinrucken aka The Art of Code/BigWings - 2020
// The MIT License
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions: The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software. THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
// Email: countfrolic@gmail.com
// Twitter: @The_ArtOfCode
// YouTube: youtube.com/TheArtOfCodeIsCool
// Facebook: https://www.facebook.com/groups/theartofcode/
//

#define MAX_STEPS 200
#define MAX_DIST 30.
#define SURF_DIST .001

#define S smoothstep
#define T iTime


mat2 Rot(float a) {
    float s=sin(a), c=cos(a);
    return mat2(c, -s, s, c);
}

struct Hit{
    float d;
    float obj;
    vec3 id;
};



float sdRoundBox( vec3 p, vec3 b, float r )
{
  vec3 q = abs(p) - b;
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0) - r;
}

float sdBox(vec3 p, vec3 s) {
    p = abs(p)-s;
	return length(max(p, 0.))+min(max(p.x, max(p.y, p.z)), 0.);
}


float opSmoothUnion( float d1, float d2, float k ) {
    float h = clamp( 0.5 + 0.5*(d2-d1)/k, 0.0, 1.0 );
    return mix( d2, d1, h ) - k*h*(1.0-h); }


Hit GetDist(vec3 p) {

    vec3 boxpos=p;

    
    boxpos.xz*=Rot(T*.7);
   boxpos.xy*=Rot(-T*.5);
   boxpos.yz*=Rot(-T*.8);
    
    float d = sdRoundBox(boxpos, vec3(.9),.2);
   
   float obj=-0.;
 //  boxpos.xy*=Rot(-T);
 //  boxpos.yz*=Rot(T);

    
   float rep=mix(.5,1.8,.5+.5*(sin(T*.4)));
   boxpos+=rep/2.;
   vec3 q=mod((boxpos),rep)-rep/2.;
   vec3 ids=floor(boxpos-q);
   float s2 = length(q)-(.08+(.05*sin(T+(ids.x+ids.y)+ids.z)))*(rep*2.);
   float s2bis = sdBox(q,vec3((.05+(.05*sin(T+(ids.x+ids.y)+ids.z)))*(rep*2.)));
   s2=mix(s2,s2bis,.5+.5*sin(T*2.+(ids.x+ids.y)+ids.z));
   s2=max(d+.01,s2);
   
   d=max(d,-s2+.08);//*(rep+.5));    
    
    if(s2<d)
        obj=1.;
    
    
    d=min(s2,d);
    
        
    vec3 q2=mod(p,2.)-1.;
    vec3 id=floor(p-q2);
    q2.y=p.y+sin(T+id.x*id.y)*.5+1.35;
    float ds=length(q2)-.4;    
    
    ds=max(ds,-sdBox(p,vec3(2.5)));
    ds=max(ds,length(p)-6.);
    if(ds<d){
        obj=3.;
    }
    d=min(d,ds);
    
    float pl=p.y+1.5;
    if(pl<d)
        obj=3.;
    
    d=opSmoothUnion(d,pl,.4);    
    
      

    return Hit(d,obj,ids);
}

Hit RayMarch(vec3 ro, vec3 rd,float direction) {
	float dO=0.;
    float obj=0.;
    vec3 id;
    for(int i=0; i<MAX_STEPS; i++) {
    	vec3 p = ro + rd*dO;
        Hit h=GetDist(p);
        obj=h.obj;
        id=h.id;
        float dS = h.d*direction;
        dO += dS;
        if(dO>MAX_DIST || abs(dS)<SURF_DIST) break;
    }
    
    return Hit(dO,obj,id);
}

vec3 GetNormal(vec3 p) {
	float d = GetDist(p).d;
    vec2 e = vec2(.001, 0);
    
    vec3 n = d - vec3(
        GetDist(p-e.xyy).d,
        GetDist(p-e.yxy).d,
        GetDist(p-e.yyx).d);
    
    return normalize(n);
}

vec3 GetRayDir(vec2 uv, vec3 p, vec3 l, float z) {
    vec3 f = normalize(l-p),
        r = normalize(cross(vec3(0,1,0), f)),
        u = cross(f,r),
        c = f*z,
        i = c + uv.x*r + uv.y*u,
        d = normalize(i);
    return d;
}



void mainImage( out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = (fragCoord-.5*iResolution.xy)/iResolution.y;
	vec2 m = iMouse.xy/iResolution.xy;

    vec3 ro = vec3(0, 1.5, -5);
    if(dot(m.xy,m.xy)>0.){
        ro.yz *= Rot(-min(m.y,.45)*3.14+1.);
        ro.xz *= Rot(-m.x*6.2831);
       }
       
   ro.xz*=Rot(T/2.);    
       
    vec3 rd = GetRayDir(uv, ro, vec3(0,0.,0), 1.);
    vec3 col = vec3(0);
   
    float bo=6.;
    float fresnel=1.;

    bool issecond=false;
    Hit h;
    float i=0.;
    vec3 p;
    for(;i<bo;i++){
    
        h=RayMarch(ro, rd,1.);
        float IOR=1.35;
        //col*=1./bo;
        

        if(h.d<MAX_DIST){
            
            if(h.obj==0.){
                p = ro + rd * h.d;
                vec3 n = GetNormal(p);
                
               
                vec3 rIn=refract(rd,n,1./IOR);

                Hit hIn= RayMarch(p-n*.003,rIn,-1.);
                
                float dIn=hIn.d;
                vec3 pIn=p+rIn*dIn;
                vec3 nIn=-GetNormal(pIn);

                vec3 rOut=vec3(0.);
                float shift=.01;

                rOut=refract(rIn,nIn,IOR);
                if(dot(rOut,rOut)==0.) rOut=reflect(-rIn,nIn);
                ro=pIn-nIn*.03;
                rd=rOut;
                
            }
            else if(h.obj==1.){
                vec3 p = ro + rd * h.d;
                vec3 n = GetNormal(p);
                float dif = dot(n, normalize(vec3(1,2,3)))*.5+.5;
                col+=((.5+.5*sin((vec3(.54,.3,.7)+h.id)*T))*fresnel)*.7;
                col *= vec3(dif);
                //*1./bo;
                break;
            }
            else if(h.obj==2.){
                break;
                vec3 p = ro + rd * h.d;
                vec3 n = GetNormal(p);
                float dif = dot(n, normalize(vec3(1,2,3)))*.5+.5;
                col+=vec3(.2,.1,.8);

                col *= vec3(dif);
                break;
            }
            else if(h.obj==3.){
                p = ro + rd * h.d;
                vec3 n = GetNormal(p);
                
                ro=p+n*.003;
                rd=reflect(rd,n);
                if(!issecond){
                    fresnel=pow(1.-dot(rd,n),2.);
                //col+=vec3(.03,.08,.1);
                   }
                issecond=true;
            }
            
        }
        else{
            vec3 bcolor=vec3(.08);
            if(i==0. ){
                col=bcolor;

                }
            else
                col=mix((col+texture(iChannel0,rd).rgb)/i*fresnel,bcolor,1.-S(15.,0.,length(p)));
            break;
        }
    }
    
    
 
    col = pow(col, vec3(.4545));	// gamma correction
    
    fragColor = vec4(col,1.0);
}

