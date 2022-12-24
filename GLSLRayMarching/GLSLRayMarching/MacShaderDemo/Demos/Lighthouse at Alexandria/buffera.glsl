#define pi acos(-1.)

#define MAX_STEPS 100
#define MAX_DIST 75.
#define SURF_DIST.001

vec3 skySun=vec3(.7,.1,.5);// ye old two suns trick
vec3 sun=normalize(vec3(.7,.1,2.));
vec3 sunCol=vec3(1.2,.30,.05)/1.2;
vec3 skyCol=vec3(.3,.4,.6)*.3;
//vec3 light=vec3(-2.6,2.15,2.);//vec3(-2.6,2.15,2.);

vec2 lighthouse(vec3 p){
    float dw=1000.;//distance to windows
    // main
    float d=sdPyramid(p,7.5);
    d=max(d,p.y-2.);
    //return d;
    vec3 bp=p;
    //4*symmetry
    bp.xz*=Rot(pi/4.);
    float an=pi/float(4.);
    float bn=mod(atan(bp.x,bp.z),2.*an)-an;
    bp.xz=length(bp.xz)*vec2(cos(bn),abs(sin(bn)));
    //cutouts
    vec3 nbp=bp;
    bp+=vec3(-.5,.5,0);
    //main box
    d=max(d,-sdBox(bp,vec3(.15,2.13,.3)));
    bp.y-=2.3;
    //top box
    d=max(d,-sdBox(bp,vec3(.15,.07,.3)));
    //bricks
    vec3 fp=1.-smoothstep(.0,fbm(p*500.)*.4,abs(fract(bp*vec3(40.,60.+fbm(p*30.)*.4,40.))-.5));
    d+=max(fp.z,fp.y)*.001;
    //walls
    vec3 wp=nbp;
    wp.x-=1.;
    float wd=sdBox(wp,vec3(.1,.24,2.3));
    wd=min(wd,sdBox(wp-vec3(.1,.26,.0),vec3(.02,.03,2.3)));
    wp-=vec3(.0,-.1,1.);
    wd=min(wd,max(sdPyramid(wp*3.,4.)/2.,p.y-.4)-fbm(p*3.)*.03);
    float b=sdBox(wp-vec3(0,.51,0.),vec3(.12,.01,.12))-fbm(p*3.)*.02;
    b=max(b,-(sdBox(wp-vec3(0,.5,0.),vec3(.1,1.,.11))));
    wd=min(wd,b);
    wd=max(wd,-(sdBox(wp-vec3(0.,-.3,-1.),vec3(.4,.5,.13))));
    d=min(d,wd);
    float wwd=sdBox(wp-vec3(0.,-.3,-1.),vec3(.4,.5,.13));
    wwd=min(wwd,sdBox(wp-vec3(.1,.32,.0),vec3(.034,.06,.04)));
    wp.z=mod(wp.z+1.,.15);
    wp.z-=.075;
    wwd=min(wwd,sdBox(wp-vec3(0,.15,0),vec3(.105,.02,.01)));
    wwd=min(wwd,sdBox(wp-vec3(0,.25,0),vec3(.105,.02,.01)));
    d=max(d,-max(wwd,sdBox(p+vec3(0,-.05,0),vec3(1.15,.2,1.15))));
    d=min(d,sdBox(wp-vec3(.07,.14,-.065),vec3(.05,.2,.01)));
    //brim
    d=min(d,sdBox(bp-vec3(-.01,.23,0),vec3(.01,.015,.5)));
    vec3 tbp=bp;
    tbp.z=mod(tbp.z,.1);
    d=min(d,sdBox(tbp-vec3(0.,.25,.04),vec3(.01,.015,.02)));
    //windows
    bp.y+=.72;
    float o=-sdBox(bp+vec3(0,.2,0),vec3(.2,.76,.26));
    bp.x+=.15;
    bp.zy=mod(bp.zy,.08);
    bp.y-=.04;
    bp.z-=.04;
    float w=-sdBox(bp,vec3(.011,.02,.014));
    w=min(w,o);
    dw=max(-w,0.);
    d=max(d,w);
    //lines
    bp=nbp;
    bp.y-=.8;
    b=sdBox(bp,vec3(.5,.9,.35));
    bp.z-=.04;
    bp.z=mod(bp.z,.08);
    bp.z-=.04;
    bp.x-=.35;
    float b2=sdBox(bp,vec3(.01,.85,.01));
    b=max(b,b2);
    d=min(d,b2);
    //cap
    d=min(d,sdPyramid((p+vec3(0,-2,0))*vec3(1,-1,1),.2));
    d=min(d,sdBox(p+vec3(0,-2.01,0),vec3(.5,.011,.5)));
    //corner cap
    vec3 op=p;
    op.xz=abs(op.xz);
    op.xz-=.45;
    op.y-=2.05;
    op.xz*=Rot(pi/4.);
    d=min(d,sdBox(op,vec3(.01,.03,.01)));
    op.y-=.03;
    op.xz*=Rot(pi/4.);
    d=min(d,sdOctahedron(op,.03));
    //top box
    b=sdBox(p-vec3(0,2.,0),vec3(.3,.15,.3));
    b=min(b,sdPyramid((p-vec3(0,2.15,0))*vec3(1.65,1.,1.65),.4));
    fp=1.-smoothstep(.0,fbm(p*500.)*.2,abs(fract(bp*vec3(0.,40.+fbm(p*30.)*.4,20.))-.5));
    b+=max(fp.y,fp.z)*.002;
    b-=fbm(p*30.)*.003;
    d=min(d,b);
    d=max(d,p.y-2.25);
    //top octogon
    bp=p;
    // bp.xz*=Rot(pi/4.);
    an=pi/float(8.);
    bn=mod(atan(bp.x,bp.z),2.*an)-an;
    bp.xz=length(bp.xz)*vec2(cos(bn),abs(sin(bn)));
    bp.y-=2.4;
    b=sdBox(bp,vec3(.2,.25,1.));
    //more bricks
    fp=1.-smoothstep(.0,fbm(p*500.)*.4,abs(fract(bp*vec3(0.,60.+fbm(p*30.)*.4,40.))-.5));
    b+=max(fp.y,fp.z)*.001;
    b-=fbm(p*30.)*.01;
    d=min(d,b);
    d=min(d,sdBox(bp-vec3(.2,.257,0),vec3(.02,.03,.02)));
    d=min(d,sdBox(bp-vec3(.2,.257,0),vec3(.01,.015,.2)));
    //windows
    o=-sdBox(bp-vec3(0,.04,0),vec3(.4,.15,1.));
    bp.x-=.2;
    bp.y=mod(bp.y,.1);
    bp.y-=.05;
    w=-sdBox(bp,vec3(.02,.03,.02));
    d=max(d,min(w,o));
    //top cyl
    bp=p;
    bp.y-=2.8;
    d=min(d,sdCappedCylinder(bp,.11,.2)+fbm(p*10.)*.01);
    bp.y-=.2;
    d=min(d,sdCappedCylinder(bp,.12,.01));
    d=min(d,sdCappedCylinder(bp,.12,.01));
    bp.y-=.26;
    d=min(d,sdCone(bp,vec2(.1,.15),.16));
    //top cyl columns
    bp=p;
    bp.y-=3.05;
    an=pi/float(8.);
    bn=mod(atan(bp.x,bp.z),2.*an)-an;
    bp.xz=length(bp.xz)*vec2(cos(bn),abs(sin(bn)));
    bp.x-=.08;
    d=min(d,sdCappedCylinder(bp,.015,.05));
    d=max(d,p.y-3.24);
    // base
    b=sdBox(p+vec3(0,.25,0),vec3(1.2,.2,1.2));//+.03-fbm(p)*.15;
    // fp=1.-smoothstep(.0,fbm(p*30.)*.12,abs(fract(p*vec3(6.,10.+fbm(p*3.)*.1,4.))-.5));
    // b+=max(fp.x,max(fp.y,fp.z))*.005;
    d=min(d,b);
    
    return vec2(d,dw);
}
float terrain(vec3 p){
    float c=1.;
    vec3 tp=p;
    tp*=2.;
    float t=fbm6(tp);
    float d=length(p-vec3(-2.2,-6.,2.1))-5.;
    d=opSmoothUnion(d,length(p-vec3(-2.,-6.2,1.))-5.,.2);
    d=opSmoothUnion(d,length(p-vec3(0.,-6.2,3.3))-5.,.2);
    d=opSmoothUnion(d,length(p-vec3(2.,-6.3,3.8))-5.,.2);
    d=opSmoothUnion(d,length(p-vec3(-4.,-8.1,-1.))-7.5,.5);
    
    d+=t*opSmoothUnion(1.*(p.y+1.1),.1,.1);
    
    return d;
}
float ocean(vec3 p){
    float d=0.;
    d+=.100000*noise(p.xz*1.);
    d+=.050000*noise(p.xz*2.);
    d+=.025000*noise(p.xz*4.);
    d+=.012500*noise(p.xz*8.);
    d+=.006250*noise(p.xz*16.);
    d+=.003125*noise(p.xz*32.);
    d*=.4;
    return d+p.y+1.5;
}
struct ddata{
    float x;
    float c;
    float dw;
};
ddata mapFast(vec3 p,vec3 rd){
    float d=10000.;
    float dw=10000.;
    if(rd.x<-.15&&abs(rd.y)<.38){
        vec3 lp=p;
        lp+=vec3(2.6,.8,-2.);
        lp.xz*=Rot(.5*pi);
        vec2 ld=lighthouse(lp);
        dw=ld.y;
        d=min(d,ld.x);
    }
    float t=10000.;
    if(rd.y<0.){
        vec3 tp=p;
        tp+=vec3(.3,0.,-.7);
        t=terrain(tp)-(.02-clamp(d*.1,0.,.02));
    }
    float o=ocean(p);
    float c=0.;
    if(d>t){
        d=t;
        c=1.;
    }
    if(d>o){
        d=o;
        c=2.;
    }
    return ddata(d,c,dw);
}
float map(vec3 p){
    vec3 lp=p;
    lp+=vec3(2.6,.8,-2.);
    lp.xz*=Rot(.5*pi);
    float d=lighthouse(lp).x;
    vec3 tp=p;
    tp+=vec3(.3,0.,-.7);
    float t=terrain(tp)-(.02-clamp(d*.1,0.,.02));
    float o=ocean(p);
    if(d>t){
        d=t;
    }
    if(d>o){
        d=o;
    }
    return d;
}
struct ray{
    float d;
    float s;
    float c;
    float dw;
};
ray RayMarch(vec3 ro,vec3 rd){
    ray d=ray(1.,0.,0.,10000.);
    
    for(int i=0;i<MAX_STEPS;i++){
        vec3 p=ro+rd*d.d;
        ddata dS=mapFast(p,rd);
        d.d+=dS.x;
        d.c=dS.c;
        d.dw=min(d.dw,dS.dw);
        d.s=float(i);
        if(d.d>MAX_DIST||abs(dS.x)<SURF_DIST)break;
    }
    
    return d;
}
vec3 GetNormal(vec3 p,vec3 rd){
    vec3 n=vec3(0.);
    for(int i=0;i<4;i++)
    {
        vec3 e=.5773*(2.*vec3((((i+3)>>1)&1),((i>>1)&1),(i&1))-1.);
        n+=e*mapFast(p+.0005*e,rd).x;
        if(n.x+n.y+n.z>100.)break;
    }
    return normalize(n);
}

vec3 GetRayDir(vec2 uv,vec3 p,vec3 l,float z){
    vec3 f=normalize(l-p),
    r=normalize(cross(vec3(0,1,0),f)),
    u=cross(f,r),
    c=f*z,
    i=c+uv.x*r+uv.y*u,
    d=normalize(i);
    return d;
}
float softShadow(vec3 ro,vec3 lp){
    vec3 rd=normalize(lp);
    float mh=10000.;
    float res=1.;
    for(float t=SURF_DIST;t<10.;)
    {
        float h=map(ro+rd*t);
        res = min( res, 32.*h/t );
        if(h<SURF_DIST)
        	return 0.;
        t+=h;
    }
    return res;
}
vec3 skyColor(in vec3 ro,in vec3 rd)
{
    rd.y+=.03;
    vec3 col=skyCol-.3*rd.y*.7;
    
    float t=(1000.-ro.y)/rd.y;
    if(t>0.)
    {
        vec2 uv=(ro+t*rd).xz;
        float cl=texture(iChannel0,.00001*uv.yx).x;
        cl=smoothstep(.3,.7,cl);
        col=mix(col,vec3(.2,.2,.1),.1*cl);
        cl-=smoothstep(.3,.7,texture(iChannel0,.00001*uv.yx+skySun.yx*.005).x);
        cl=clamp(cl,0.,1.);
        col=mix(col,sunCol*.5,.1*cl);
    }
    
    float sd=pow(clamp(.25+.75*dot(normalize(skySun),rd),0.,1.),4.);
    col=mix(col,sunCol,sd*exp(-abs((60.-50.*sd)*rd.y)));
    
    return col;
}
vec4 textureBox(in sampler2D tex,in vec3 pos,in vec3 nor)
{
    vec4 cx=texture(tex,pos.yz);
    vec4 cy=texture(tex,pos.xz);
    vec4 cz=texture(tex,pos.xy);
    vec3 m=nor*nor;
    return(cx*m.x+cy*m.y+cz*m.z)/(m.x+m.y+m.z);
}

float calcOcclusion(in vec3 pos,in vec3 nor,float ra,vec3 rd)
{
    float occ=0.;
    float sca=1.;
    for(int i=0;i<5;i++)
    {
        float h=.01+.12*float(i)/4.;
        float d=map(pos+h*nor);
        occ+=(h-d)*sca;
        sca*=.95;
        if(occ>.35)break;
    }
    return clamp(1.-3.*occ,0.,1.)*(.5+.5*nor.y);
}
void mainImage(out vec4 fragColor,in vec2 fragCoord)
{
    vec2 uv=(fragCoord.xy-.5*iResolution.xy)/iResolution.y;
    
    float ran=hash(uint(fragCoord.x+iResolution.x*fragCoord.y+(iResolution.x*iResolution.y)));
    vec3 col=vec3(0);
    
    vec3 lc=texture(iChannel1,fragCoord/iResolution.xy).xyz;
    
    /*
    if(iFrame<=5){
        fragColor=vec4(vec3(0),1.);
        return;
    }
    if(lc.x+lc.y+lc.z>.01||ran<.99-float(max(iFrame,0))*.01){
        fragColor=vec4(lc,1.);
        return;
    }
	*/
    
    vec3 ro=vec3(0,.5,-3);
    
    vec3 rd=GetRayDir(uv,ro,vec3(0,.5,0),1.);
    
    ray r=RayMarch(ro,rd);
    vec3 lp=sun;
    if(r.d<MAX_DIST){
        vec3 sp=ro+rd*r.d;
        vec3 sn=GetNormal(sp,rd);
        
        vec3 ld=normalize(sun);
        
        vec3 objCol=vec3(0.);
        vec3 N=sn;
        float rough=0.;
        float occ=1.;
        float sha=1.;
        if(r.c<1.){// tower
            objCol=vec3(.14,.10,.07)+.02*noise(sp*50.);
            objCol*=1.15;
            rough=textureBox(iChannel0,sp,sn).x;
            N*=textureBox(iChannel0,sp,sn).x;
            occ=calcOcclusion(sp,sn,ran,rd);
        }
        else if(r.c<2.){// land
            objCol=vec3(.95,.9,.85)*.4*texture(iChannel0,sp.xz*.015).xyz;
            objCol*=.25+.75*smoothstep(-25.,-24.,sp.y);
            objCol*=.32;
            float is_grass=smoothstep(.95,1.,sn.y);
            
            objCol=mix(objCol,vec3(.05,.07,.02)+texture(iChannel0,sp.xz*.015).xyz*.1-.05,is_grass);
            occ=calcOcclusion(sp,sn,ran,rd);
        }
        else if(r.c<3.){//ocean
            //foam
            float f=texture(iChannel0,sp.xz*2.).x;
            f*=(terrain(sp)+.9)*3.5+fbm(sp.xz*sp.xz*.001,8)*2.2;
            f=clamp(f,0.,1.);
            
            //sun
            float fresnel=(.04+(1.-.04)*(pow(1.-max(0.,dot(-sn,rd)),5.)));
            vec3 R=reflect(rd,sn);
            objCol=mix(vec3(1.),fresnel*skyColor(ro,R)*2.,f);
        };
        
        //lighing from iq's Greek Temple https://www.shadertoy.com/view/wdKSzd
        vec3 sunbak=normalize(vec3(-sun.x,0.,-sun.z));
        float dif=clamp(dot(N,sun),0.,1.);
        sha=softShadow(sp+N*SURF_DIST,sun);
        dif*=sha;
        float amb=(.8+.2*N.y);
        amb=mix(amb,amb*(.5+.5*smoothstep(-8.,-1.,sp.y)),0.);
        
        vec3 qos=sp/1.5-vec3(0.,1.,0.);
        
        float bak=clamp(.4+.6*dot(N,sunbak),0.,1.);
        bak*=.6+.4*smoothstep(-8.,-1.,qos.y);
        
        vec3 hal=normalize(sun-rd);
        
        float fre=pow(clamp(1.+dot(N,rd),0.,1.),5.);
        float spe=pow(clamp(dot(N,hal),0.,1.),rough)*(.1+.9*fre)*sha*(.5+.5*occ);
        col=vec3(0.);
        col+=amb*1.*vec3(.15,.25,.35)*occ*(1.+0.);
        col+=dif*7.*vec3(.9,.35,.35)*occ;
        col+=bak*2.*vec3(.1,.1,.2);
        col+=spe*10.*rough*occ;
        
        col*=objCol;
        col=clamp(col,0.,1.);
        
    }else{
        col=skyColor(ro,rd);
    }
    float fogF=smoothstep(0.,.95,r.d/50.);
    col=mix(col,skyColor(ro,rd),fogF);
    
    col=pow(col,vec3(1./2.2));
    fragColor=vec4(col,1.);
    
    /*
    if(lc.x+lc.y+lc.z<.01){
        fragColor=vec4(col,1.);
    }else{
        fragColor=vec4((col+lc)/2.,1.);
    }
	*/
}

