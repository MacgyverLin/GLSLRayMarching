// Shader made Live during OMZG Shader Royale (12/02/2021) in about 80m
// 1st place
// https://www.twitch.tv/videos/911443995?t=01h12m13s

#define FEEDBACK 1
#define ALL_COLORS 1

float time=0.0;

mat2 rot(float a) {
  
  float ca=cos(a);
  float sa=sin(a);
  return mat2(ca,sa,-sa,ca);
}

vec3 rnd(vec3 p) {
  return fract(sin(p*524.574+p.yzx*874.512)*352.341);
}

float rnd(float t) {
  return fract(sin(t*472.547)*537.884);
}

float curve(float t, float d) {
  t/=d;
  return mix(rnd(floor(t)), rnd(floor(t)+1.), pow(smoothstep(0.,1.,fract(t)), 10.));
}

vec3 curve(vec3 t, float d) {
  t/=d;
  return mix(rnd(floor(t)), rnd(floor(t)+1.), pow(smoothstep(0.,1.,fract(t)), vec3(10.)));
}

float box(vec3 p, vec3 s) {
  p=abs(p)-s;
  return max(p.x, max(p.y,p.z));
}

vec3 repeat(vec3 p, vec3 s) {
  return (fract(p/s+.5)-.5)*s;  
}

vec3 atm=vec3(0);
vec3 id=vec3(0);
float map(vec3 p) {
  
  if(time>10.) p.y += curve(time*5.-length(p.xz), 1.3)*.6;
  if(time>36.) p.xz *= rot(time*.4-length(p.xz)*.3);
    
  vec3 p2=p+sin(time*vec3(1,1.2,.8)*.2)*.03;
  float mm=10000.;
  id=vec3(0);
  // This is the main kifs, making lots of plane cuts in everything
  // we get back the distance to the nearest plane in "mm"
  // also each "block" between plane gets a different "id"
  for(float i=1.; i<4.; ++i) {
    float t=time*0.1+curve(time+i*.2, 1.3)*4.;
    p2.xz *= rot(t);
    t+=sign(p2.x); // this makes the cuts not totaly symmetric
    p2.yx *= rot(t*.7);
    
    id += sign(p2)*i*i; // change id depending on what plane's side we are
    p2=abs(p2);
    mm=min(mm, min(p2.x,min(p2.y,p2.z)));
    
    p2-=0.2+sin(time*.3)*.3;
  }
  
  // now we translate each "block" randomly according to the id
  p += (curve(rnd(id)+time*.3,.7)-.5)*.8;
  
  // to have the random breaks without killing the SDF completly, we will have to make the ray "slow down" near the planes
  // we will also use that as translucent glowy shape
  float d2=min(mm,1.5-length(p));
  
  // block shapes
  float d=abs(length(p)-1.-mm*1.4)-.1;
  
  // add boxes or cylinder randomly on each block
  vec3 r2=rnd(id+.1);
  if(r2.x<.3) {
    d=min(d, max(box(repeat(p2, vec3(.25)), vec3(.1)), d-.1)); 
  } else if(r2.x<.7) {
    d=min(d, max(length(repeat(p2, vec3(.15)).xy-.05), d-.2)); 
  }
  
  // cut everything by the planes
  d=max(d,0.06-mm);
  
  // translucent glowy shape, appearing sometimes
  atm += vec3(1,0.5,0.3)*r2*0.0013/(0.01+abs(d2))*max(0.,curve(time+r2.y, .3)-.4);
  // put the plane cuts in the SDF, but with max(0.2) so the ray will just slow down but then go through it
  d2=max(d2,0.2);  
  d=min(d,d2);
  
  // floor plan
  float d3 = p.y+2.;
  
  // tried adding things to the terrain, but failed ^^
  vec3 p3 = repeat(p,vec3(10,10,10));
  //d3 = min(d3, length(p3.xz)-0.7);
  //d=min(d, max(d3, 0.5-abs(p3.y)));
  
  d=min(d, max(d3, .2-mm));
  
  return d;
}

void cam(inout vec3 p) {
  
  float t=time*.2;//+curve(time, 1.3)*7.;
  p.yz *= rot(sin(t*1.3)*.5-.7);
  p.xz *= rot(t);
}

float gao(vec3 p, vec3 r, float d) {
  return clamp(map(p+r*d)/d,0.,1.)*.5+.5;  
}

float rnd(vec2 uv) {
  return fract(dot(sin(uv*521.744+uv.yx*352.512),vec2(471.52)));
}


void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    time=mod(iTime*.3, 300.0);

	vec2 uv = vec2(fragCoord.x / iResolution.x, fragCoord.y / iResolution.y);
	uv -= 0.5;
	uv /= vec2(iResolution.y / iResolution.x, 1);
  
  //uv *= 1.+curve(time*3.-length(uv),.7)*.2; 

  vec3 s=vec3(curve(time, .7)-.5,curve(time+7.2, .8)-.5,-8);
  vec3 r=normalize(vec3(uv, .8 + curve(time, 1.7)*1.4));
  
  cam(s);
  cam(r);
  
  bool hit=false;
  
  vec3 p=s;
  // raymarching loop
  for(int i=0; i<100; ++i) {
    
    float d=map(p);
    if(d<0.001) {
      hit=true;
      break;
    }
    if(d>100.0) break;
    
    p+=r*d*.8;
    
  }
  
  vec3 col=vec3(0);
  if(hit) {
    vec3 id2=id;
    vec2 off=vec2(0.01,0);
    vec3 n=normalize(map(p)-vec3(map(p+off.xyy), map(p+off.yxy), map(p+off.yyx)));
    vec3 l=normalize(vec3(1,-3,2));
    if(dot(l,n)<0.) l=-l; // trick to have two opposite lights
    vec3 h=normalize(l+r);
    float spec=max(0.,dot(n,h));
    
    float fog=1.-clamp(length(p-s),0.,1.);
        
    // base shading
    float ao=gao(p,n,.1)*gao(p,n,.2)*gao(p,n,.4)*gao(p,n,.8);
    col += max(0.,dot(n,l)) * (0.3 + pow(spec,10.) + pow(spec,50.)) * ao * 3.;
    
    // subsurface effect, didn't managed to make it very good
    for(float i=1.; i<15.; ++i) {
      float dist=i*.07;
      col += max(0.,map(p+r*dist)) * vec3(.5+dist,0.5,0.5) * .8 * ao;
    }
    
    off.x=0.04;
    vec3 n2=normalize(map(p)-vec3(map(p+off.xyy), map(p+off.yxy), map(p+off.yyx)));
    // outline effect (thanks FMS_Cat for the very great trick of difference between two normals with different offset size)
    col += vec3(id2.x,id2.y*.5+.4,.7)*pow(curve(time-id2.z, .7),4.)*.1*length(n-n2);
    
    //col+=map(p-r*.2)*1.; // quickest shading there is
  }
  
  // add glow
  col += pow(atm*3.,vec3(2.));
  
  // saturated colors becomes white
  col += max(col.yzx-1.,0.);
  col += max(col.zxy-1.,0.);
  
  // vignet
  col *= 1.2-length(uv);
  
  #if ALL_COLORS
  if(time>18.) {
      float t4 = time*.3+uv.y*.6;
      if(time>30.) t4+=floor(abs(uv.x+col.x*.1)*3.)*17.;
      col.xz*=rot(t4);
      col.yz*=rot(t4*1.3);
      col=abs(col);
  }
  #endif
  
  // "tonemapping"
  col=smoothstep(0.0,1.,col);
  col=pow(col, vec3(.4545));
  
  #if FEEDBACK
  if(time>24.) {
      vec2 uv2=fragCoord.xy / iResolution.xy;
      uv2-=.5;
      uv2*=.92+rnd(uv2)*.03;
      uv2+=.5;
      vec3 c2=texture(iChannel0, uv2).xyz;
      float t3=0.0;
      c2.xz *= rot(.05+t3);
      c2.xy *= rot(.02+t3);
      c2=abs(c2);
      float fac=clamp(1.5-length(uv)*1.3,0.,1.);
      fac=min(fac, max(0.,pow(fract(time*.5),2.)));
      col *= 0.3+fac*.7;
      col += c2*.9*(1.-fac);
  }
  #endif
  
    fragColor = vec4(col, 1);
}