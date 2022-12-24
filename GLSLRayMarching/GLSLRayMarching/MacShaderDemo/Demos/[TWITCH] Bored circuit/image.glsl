// Bored circuit - Result of an improvised live coding session on Twitch
// LIVE SHADER CODING, SHADER SHOWDOWN STYLE, EVERY TUESDAYS 20:00 Uk time: 
// https://www.twitch.tv/evvvvil_

vec2 z,v,e=vec2(.00035,-.00035);float t,b,tt,g;vec3 op,po,no,al,ld,cutP;
mat2 r2(float r){return mat2(cos(r),sin(r),-sin(r),cos(r));}
float bo(vec3 p,vec3 r){p=abs(p)-r;return max(max(p.x,p.y),p.z);}
vec2 fb( vec3 p)
{   
    cutP=op=p;
    cutP.xy*=r2(.785);
    vec2 h,t=vec2(length(p.xz)-3.,5); //BLUE CUT PIECE
    t.x=abs(t.x)-.4;
    t.x=max(t.x,-(max(-p.x,abs(abs(abs(cutP.y)-2.)-1.)-.5)));
    t.x=max(t.x,abs(cutP.y)-5.);
    h=vec2(length(p.xz)-3.,6); //WHITE CUT PIECE
    h.x=abs(h.x)-.15;
    h.x=max(h.x,-(max(-p.x,abs(abs(abs(cutP.y)-2.)-1.)-.3)));
    h.x=max(h.x,abs(cutP.y)-5.5);
    float cutter=(abs(abs(cutP.y-8.)-10.)-3.);  
    h.x=min(h.x,max(length(p.xz)-.6,-cutter));//WHITE CYLINDER  
    float lazer=max(length(p.xz)-0.1,cutter+0.1);//LAZER
    g+=0.2/(0.1+lazer*lazer*5.);
    h.x=min(h.x,lazer);
    t=t.x<h.x?t:h;
    h=vec2(length(p.xz)-2.2,3);//BLACK CYLINDER CUT PIECE
    h.x=abs(h.x)-.4;
    h.x=max(h.x,abs(abs(cutP.y)-5.)-1.);
    t=t.x<h.x?t:h;
    return t;  
}
vec2 mp( vec3 p)
{
    op=p;
    vec4 np=vec4(p,1);
    vec2 h,t=vec2(1000);
    np.z-=30.;
    np.z=abs(abs(np.z)-20.)-10.;  
    vec4 bp=np.xzyw; 
    for(int i=0;i<4;i++){
        np.xyz=abs(np.xyz)-vec3(25.,clamp(5.5-ceil(-p.z*.05-.5)*4.,5.,15.),0);
        bp.xyz=abs(bp.xyz)-vec3(20.,clamp(10.-ceil(-p.z*.05)*4.,10.,20.),0);
        np.xy*=r2(.785);
        bp.xy*=r2(.785);
        h=fb(np.xyz); //DRAW VERTICAL FRACTAL
        h.x/=np.w*1.5;
        t=t.x<h.x?t:h;
        h=fb(bp.xyz); //DRAW HORIZONTAL FRACTAL
        h.x/=bp.w*1.5;
        t=t.x<h.x?t:h;
        h=vec2(bo(bp.xyz-vec3(12,0,0),vec3(1,100,1.+cos(p.z*.1)*2.)),3.);//DRAW BLACK BOXES
        h.x/=bp.w;
        t=t.x<h.x?t:h;
        np*=2.;
        bp*=2.;
    }
    p.z=mod(p.z-10.,20.)-10.; //WHITE SPHERES
    h=vec2(length(p)-1.5,6.);  
    t=t.x<h.x?t:h;  
    h=vec2(max(p.y,abs(p.x)-65.),7.);  //TERRAIN
    t=t.x<h.x?t:h;
    return t;  
}
vec2 tr( vec3 ro, vec3 rd )
{
    vec2 h,t=vec2(.1);
    for(int i=0;i<128;i++){
        h=mp(ro+rd*t.x);
        if(h.x<.0001||t.x>100.) break;
        t.x+=h.x;t.y=h.y;
    }
    if(t.x>100.) t.y=0.;
    return t;  
}
#define a(d) clamp(mp(po+no*d).x/d,0.,1.)
#define s(d) smoothstep(0.,1.,mp(po+ld*d).x/d)
float pattern(vec2 uv){return ceil(abs(sin(uv.y*5.))-.7-.5*sin(op.y*.1+tt))+ceil(abs(sin(uv.x*1.5))-.75);}
void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv=(fragCoord.xy/iResolution.xy-0.5)/vec2(iResolution.y/iResolution.x,1);
    tt=mod(iTime,56.52);
    b=ceil(sin(tt*.5));
    vec3 ro=mix(vec3(1),vec3(-2,3,1),b)*vec3(sin(tt*.5-.75)*6.,7.5,30.+sin(tt*.15)*70.),
        cw=normalize(vec3(0,0,20.+sin(tt*.5)*20.)-ro),cu=normalize(cross(cw,vec3(0,1,0))),cv=normalize(cross(cu,cw)),
        rd=mat3(cu,cv,cw)*normalize(vec3(uv,.75)),co,fo;
    co=fo=vec3(.2,.12,.12)-length(uv)*.1-rd.y*.3;
    ld=normalize(vec3(0.,.5,sin(tt*.15)*.5));  
    z=tr(ro,rd); t=z.x;
    if(z.y>0.){
        po=ro+rd*t;
        no=normalize(e.xyy*mp(po+e.xyy).x+ e.yyx*mp(po+e.yyx).x+e.yxy*mp(po+e.yxy).x+e.xxx*mp(po+e.xxx).x);
        float lines=1.; vec2 linesUV=op.xy*.1;
        for(int i=0;i<3;i++){      
            linesUV=abs(linesUV)-.15;
            lines=min(lines,pattern(linesUV));
            linesUV*=3.;
        }        
        al=mix(vec3(0),vec3(.05,.15,.35),lines);  
        float spo=exp2(7.-lines*5.);
        if(z.y<5.)al=vec3(0.);  
        if(z.y>5.)al=vec3(.8,.7,.8);  
        if(z.y>6.)al=vec3(0.1,.05,.05)+lines*.025,spo=exp2(10.-lines*5.);
        float dif=max(0.,dot(no,ld)),
            fr=pow(1.+dot(no,rd),4.),
            sp=pow(max(dot(reflect(-ld,no),-rd),0.),spo);
        co=mix(sp+al*(a(.05)*a(.1)+.2)*(dif*vec3(.7,.6,.4)+s(4.)),fo,min(fr,.5));
        co=mix(fo,co,exp(-.000005*t*t*t));
    }
    co=smoothstep(0.,1.,co);
    fragColor = vec4(pow(co+g*.4*vec3(.1,.2,.5),vec3(.45)),1);
}