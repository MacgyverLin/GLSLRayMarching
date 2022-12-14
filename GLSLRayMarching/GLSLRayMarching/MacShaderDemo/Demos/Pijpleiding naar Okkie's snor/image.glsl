// Winning shader made at Outline 2021 Shader Showdown Final

// The "Shader Showdown" is a demoscene live-coding shader battle competition.
// 2 coders battle for 25 minutes making a shader on stage. No google, no cheat sheets.
// The audience votes for the winner by making noise or by voting on their phone.

// This shader was coded live on stage in 25 minutes. Designed beforehand in several hours.

vec2 z,v,e=vec2(.00035,-.00035);float t,tt,b,g,gg,tn,a,la,pa;vec3 op,bp,pp,po,no,al,ld;vec4 np; //global variables
mat2 r2(float r){return mat2(cos(r),sin(r),-sin(r),cos(r));} // simple rotate 2d function
float smin(float a,float b,float k){ float h=max(0.,k-abs(a-b));return min(a,b)-h*h*.25/k;} //smooth blend addition geometry function
float smax(float a,float b,float k){ float h=max(0.,k-abs(-a-b));return max(-a,b)+h*h*.25/k;} //smooth blend substraction geometry function
vec2 smin( vec2 a, vec2 b,float k ){ float h=clamp(.5+.5*(b.x-a.x)/k,.0,1.);return mix(b,a,h)-k*h*(1.0-h);} //smooth blend add both geometries AND mateiral ID / colour together
vec4 texNoise(vec2 uv,sampler2D tex ){ float f = 0.; f+=texture(tex, uv*.125).r*.5; f+=texture(tex,uv*.25).r*.25; //Funciton simulating the perlin noise texture we have in Bonzomatic shader editor, written by yx
                       f+=texture(tex,uv*.5).r*.125; f+=texture(tex,uv*1.).r*.125; f=pow(f,1.2);return vec4(f*.45+.05);}
vec2 mp( vec3 p)
{
  op=p; //remember original position
  p.z=mod(p.z+tt*2.,20.)-10.; //modulo everything along z to repeat
  tn=texNoise((op.xz+vec2(.4,tt*2.))*.05,iChannel0).r; //perlin noise (texNoise  perlin texture in Bonzomatic)
  vec2 h=vec2(1000,1.),t=vec2(p.y+4.9+tn*4.+sin((op.z+tt*2.)*.5)*.5,0.); t.x*=0.6; //define white material id 0, define blue material id 1 with terrain with perlin noise and some diform
  np=vec4(p,1); //setup our position np as vec4 so we can track np scale in the .w to use np.w as divider to avoid artifact, line 28 + 29
  for(int i=0;i<3;i++){ //loop 3 times
    np.xz=abs(np.xz)-14.; //each iter mirrror symatery clone push out a bit
    a=length(np.xz)+tn*2.5+p.y*1.55+float(i)+cos(p.x*.5)*2.+sin(p.y*15.)*.1; //make mountain features on terrain which we will cut after, line 32+33
    np.xz-=cos(p.x);//wave deform everything along x axis
    np*=2.; //scale everything down twice each iter
   t.x=smin(t.x,a/np.w,1.5); //add mountain feature to blue terrain with smooth blend
   h.x=smin(h.x,a/np.w+.1,1.3); //add mountain feature to white material with smooth blend
   h.x=smin(h.x,.8*(length(np.zy+vec2(0,12.+float(i)*7.5))-.7-tn)/np.w,.8); //add horizontal wavey tubes along x axis
  }
  t.x=max(t.x,p.y+3.*(1.-tn*.2)); //cut mountain blue terrain to make a "plateau", with noise so it's not totally "flat"
  h.x=max(h.x,p.y+2.2*(1.-tn*.5)); //cut mountain white terrain to make a plateau, but bit higher, , with noise so it's not totally "flat"
  pp=op+vec3(0,5,0);pp.x=abs(abs(pp.x)-8.)-4.; //setup position for side tunnels, we will use position in infinite cylinder to cut tunnels
  a=length(pp.xy)-1.-tn+cos(p.z*.2)*.3; //make both infinite cylinder with position from above to dig tunnels in terrains
  bp=op;bp.x=abs(abs(abs(bp.x+4.)-8.)-4.)-1.; //prepare position for the white pipeline tubes
  h.x=smin(h.x,.9*(length(bp.xy+vec2(0,5.5+cos(p.x*.2)))-.9),1.); //Add white pipeline tubes to white material with smooth blend
  t.x=smax(a,t.x,.5); //dig out tunnel from blue terrain using inifnite tunnel cylinder from line 35
  h.x=smax(a+.5,h.x,.5); //dig out tunnel from white terrain using inifnite tunnel cylinder from line 35
  pp.xy*=r2(.785+sin(op.z*.2)+tt); //we gonna reuse the tunnel position for lazers, so rotate it along z here
  la=length(abs(pp.xy)-vec2(.3)); //carete lazers based on tunnel position which we rotated above
  b=cos(p.z*.5); //particle offset / dance along z axisgiving them a cool bop 
  pa=max(length(cos(op*.75+vec3(b,b*.5-tt,cos(p.x)))),abs(p.x)-10.); //make particles as 0 radius spheres, using cos of original op position and animated up  wish dance bop offset
  g+=0.1/(0.1+la*la*(80.-79.5*sin(op.z*.5+tt*2.+tn*5.))); //push lazer into blue glow variable to add glow at end (see last line)
  gg+=0.1/(0.1+pa*pa*500.);//push particles into white glow variable to add glow at end (see last line)
  h.x=min(la,h.x); //add lazers to white material so it doesn't glitch
  t=smin(t,h,.2); //MATERIAL SMOOTH BLEND. In all caps as people tend to ask how to do this. Yes it blends both geometries of white and blue material AS WELL as material ID +colour itself(see line 83)
  t.x=min(t.x,pa); //Add mmarticle to result scene so it doesn't glitch
  return t;
}
vec2 tr( vec3 ro,vec3 rd ) //simple raymarching function / loop
{
  vec2 h,t=vec2(.1); //near plane
  for(int i=0;i<128;i++){ //march forward up to 128 times
  h=mp(ro+rd*t.x); //get distance from scene
    if(h.x<.0001||t.x>40.) break; //if we are too close we hit something we stop, also if we gone too far, we stop (far plane)
    t.x+=h.x;t.y=h.y; //jump forward to how far we are from geom to optimize and remember material ID
    if(t.x>40.) t.y=-1.; //vauge optmization for later line 77, jurry is still out on this one...
  }
  return t;
}
#define a(d) clamp(mp(po+no*d).x/d,0.,1.) 
#define s(d) smoothstep(0.,1.,mp(po+ld*d).x/d)
void mainImage( out vec4 fragColor, in vec2 fragCoord ) //above a(d) is Ambient Occlusion and s(d) is Sub surface scatterring
{
  vec2 uv=(fragCoord.xy/iResolution.xy-0.5)/vec2(iResolution.y/iResolution.x,1); //get uv
  tt=12.+mod(iTime,62.83); //modulo time to avoid glitches past 2-3 minutes due to sin floating point precision
  vec3 ro=mix(vec3(4,-5,-10), vec3(cos(tt*.4+1.)*3.,-cos(tt*.4),-10), ceil(cos(tt*.4))), //ro is ray origin aka camera position
  cw=normalize(vec3(0,-7,0)-ro), //making a camera, vec3(0,-7,0) is the camera target
  cu=normalize(cross(cw,vec3(0,1,0))), //making a camera, vec3(0,1,0) is the up vector
  cv=normalize(cross(cu,cw)), //making a camera,
  rd=mat3(cu,cv,cw)*normalize(vec3(uv,.5)),co,fo;  //making a camera,0.5 is the field of view
  tn=texNoise(rd.xy*10.,iChannel0).r; //sample perlin noise to soften pseudo background caustics
  co=fo=vec3(.05,.2,.5)+rd.y*.2-cos(rd.x*(20.)+tt)*(.15*tn); //background colour is blue with gradient along camera direction y and with p[seudo caustic wave soften out with noise
  ld=normalize(vec3(.2,.5,-.5)); //light direction is from above
  z=tr(ro,rd);t=z.x; //draw scene, cast ray
  if(z.y>-1.){ //if material id is more than -1 than we muist have hit something
    po=ro+rd*t; //get position of where we hit 
    no=normalize(e.xyy*mp(po+e.xyy).x+e.yyx*mp(po+e.yyx).x+e.yxy*mp(po+e.yxy).x+e.xxx*mp(po+e.xxx).x); //get normals of where we hit based on position above
    al=mix(vec3(.1,.2,.5)-tn*.4,vec3(.5),z.y); //Reusing mmaterial ID as smoothblend to merge both material colours
    al+=pow((sin(po.x*2.+tt*2.)*.5+.5)*(sin(po.z*2.+tt*2.)*.5+.5),2.)*.5; //add size coded  pseudo-caustics
    float dif=max(0.,dot(no,ld)), //diffuse lighting
    fr=pow(1.+dot(no,rd),4.), //fresnel reflections
    sp=pow(max(dot(reflect(-ld,no),-rd),0.),40.); //specular lighting
    co=mix(sp*0.2+al*(a(.1)*a(.2)+.2)*(dif+s(.2))*vec3(.5,.7,1.),fo,min(fr,.5)); //final lighting is specular + albedo base colour * ambient occlusion twice + .2 ambient lighting * diffuse + subsurface scattering, then softened with fresnel
    co=mix(fo,co,exp(-.0001*t*t*t));//add pretty heavy fog
  }
  co=mix(co,co.xzy,length(uv)*.5); //gradient colours based on circle from center, nice size-coded colouring trick
  fragColor = vec4(pow(co+gg*.2+g*.2*vec3(.1,.2,.7),vec3(.55)),1); //return final colour with white and blue glows and bit of gamma correction
}