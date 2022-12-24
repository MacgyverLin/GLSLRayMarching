// Pounding Aldebaran - Result of an improvised live coding session on Twitch

// LIVE SHADER CODING, SHADER SHOWDOWN STYLE, EVERY TUESDAYS 21:00 Uk time:
// https://www.twitch.tv/evvvvil_

// "People who do not know how to laugh are always pompous and self-conceited." - William Makepeace Thackeray

vec2 z,v,e=vec2(.0035,-.0035); float t,tt,bb,b,b2,g,g2,td,cn,texNoi; vec3 pp,po,no,ld,al,lp; //global vars: same old garbage, just like any Coldplay album.
float bo(vec3 p,vec3 r){p=abs(p)-r;return max(max(p.x,p.y),p.z);} //box primitive function, yeah I know it's boring but then so is sitting next to you at a Wedding.
mat2 r2(float r){return mat2(cos(r),sin(r),-sin(r),cos(r));} //rotate function. Short and sweet, just like the meaningless chat we're gonna have at that wedding.
float smin(float a,float b,float h){float k=clamp((a-b)/h*.5+.5,0.,1.);return mix(a,b,k)-k*(1.-k)*h;} // Smooth merge - Merging geometry softly. Bit like a wedding actually, you know, being an excuse for two people eventually physically merging.
float noi(vec3 p){ // Noise function. I don't really understand any of this, I was so bored at that wedding that I spent all my neurones on halucinagenics, so much so I even forgot how to spell halucinogenics
  vec3 f=floor(p),s=vec3(7,157,113); 
  p-=f;vec4 h=vec4(0,s.yz,s.y+s.z)+dot(f,s);
  p=p*p*(3.-2.*p);
  h=mix(fract(sin(h)*43758.5),fract(sin(h+s.x)*43758.5),p.x);
  h.xy=mix(h.xz,h.yw,p.y);
  return mix(h.x,h.y,p.z);
}
vec2 pounder( vec3 p )
{ //Phallic symbol incoming, why be subtle when you can litterally fuck a planet's core? You're just not ambitious enough broski: I once fucked the sea.
  pp=abs(p+vec3(0,-6.,0))-vec3(0,5.+bb,0); //make new position pp out of p for the half spheres, abs symetry along y and animate. Give it some serious pumping action (that's what she said)
  vec2 h,t=vec2(length(pp)-2.2,6.); //WHITE SPHERE soon to be slashed in half, just like public services funding under Boris Johnson.
  t.x=abs(t.x)-.3; //Onion trick to make the sphere hollow, carving holes basically, this time with math rather than the smallest part of your body.
  t.x=max(t.x,-pp.y); //Slash sphere in half and reveal it hollow, just like those brexit promises. 
  h=vec2(length(pp)-2.2,3.); //BLACK SPHERE soon to be slashed in half, just like the UK's international reputation under Boris Johnson.
  h.x=abs(h.x)-.1; //Onion trick to make the sphere hollow, with smaller radius so it creates edge.
  h.x=max(h.x,-pp.y-.5); //Slash sphere in half and reveal it as a hollow, just like those brexit promises. 
  pp.xz*=r2(1.2+sin(p.y*(1.-0.07*bb))*.5); // reusing pp as new position for splines, rotate and twist a bit.
  h.x=min(h.x,bo(abs(abs(pp)-vec3(0.5,0.0,.6))-vec3(1,0,0.3),vec3(0.2,20.0,0.15))); //BLACK SPLINES Made out of couple of abs symetry cloning a bunch of fucking boxes.
  t=t.x<h.x?t:h; //Merge all geometries from both black and white materials. There is an interratial sex joke to be made here but I'm too scared of offended millenials.
  t.x=max(t.x,-(length(p.xz)-1.)); //HOLE IN MIDDLE, digs hole through both half spheres, letting the blue core through it. Noone will hear you scream in space but there is still time for sexual inuendos 
  h=vec2(bo(abs(abs(pp)-vec3(0.5,0.0,.6))-vec3(1,0,0.3),vec3(0.3,20.0,0.01)),6.); //GLOW SPLINES Made out of couple of abs symetry cloning a bunch of fucking boxes.
  g+=0.1/(0.1+h.x*h.x*(150.-sin(p.y*0.5+tt*2.)*149.)); //First glow, making the splines above glow and sweeping the glow along Y axis. It's like building fireworks but without the fun of burning things.
  t=t.x<h.x?t:h; //Merge the glow splines with the rest. Like putting fairy lights around your room to pretend you are not the twisted fucker your neighbour knows you are.
  h=vec2(  length(p.xz+texNoi*2.5)-(.5+0.2*sin(p.y*2.+tt*2.)),5.); //BLUE CORE, inifinte cylinder with bit of displacement along y and reusing texNoi for crunchy effect.
  g2+=0.1/(0.1+h.x*h.x*(5.-sin(p.y*0.5+tt*2.-0.5)*4.9)); //Second glow, making blue core glow and sweeping along y axis with a bit of an offset so it comes in a little after white.
  t=t.x<h.x?t:h; t.x*=0.9; //Merge the core with rest and tweak distance field a bit to avoid artifact (t.x*=0.9)
  return t;
}
// Rough shadertoy approximation of the bonzomatic noise texture by yx - https://www.shadertoy.com/view/tdlXW4
float texNoise(vec2 uv){ float f = 0.; f+=texture(iChannel0, uv*.125).r*.5;
    f+=texture(iChannel0,uv*.25).r*.25;f+=texture(iChannel0,uv*.5).r*.125;
    f+=texture(iChannel0,uv*1.).r*.125;f=pow(f,1.2);return f*.45+.05;
}// We miss you on Twitch Luna... Sending some love.
vec2 mp( vec3 p )
{ 
  texNoi=texNoise(0.35*vec2(p.y,dot(p.xz,vec2(.7))))*.2; //texture based noise with naive triplanar uvs, adds really nice tiny crunchy details hard to recreate with a 3d noise function
  td=noi(p*.2+1.5)*4.-noi(p*2.-.5)*.1-noi(p*.05)*2.+noi(p*.03)*5.-noi(p*.5)+texNoi; //td = terain displacement = a whole bunch of noise calls at different scales to create natural terrain. Bit like jamming your fingers in the socket and getting out an expensive haircut.
  float ripple=sin(5.*(length((p.xz+vec2(2,2))*.7)-(0.2))-tt*10.)*0.5*b2; //Ripple motion for the pounding.
  pp=p+td;//Make new position pp for terrain and add all the noise to displace it.
  pp.y-=sin(p.x*.1)-sin(p.x*30.)*0.01; //Bit more displacement for the terrain and a subtl frill along the x axis
  vec2 h,t=vec2(pp.y+5.+ripple,5.); //Create base terrain from a displaced plane
  cn=noi(p*1.5+ripple)*.2; //To make terrain more interesting than plane we gonna add some displaced infinite cylinders, but we need to tweak them even more with more noise. It's like seeing Autechre live, but as if it's wasn't fucked up enough, you also took some acid.
  t.x=smin(t.x,length(abs(pp.xz+cn)-vec2(5,5))-(1.1+ripple*.2-sin(p.y*.2)+sin(p.y*30.)*0.02),3.); //Add some vertical infinite tweaked out cylinder and do smooth merge with terrain. It's like genetrification, it's ok because hipsters are actually "nice guys".
  t.x=smin(t.x,length(abs(pp.xy+cn-vec2(0,3))-vec2(12,0))-(1.1+ripple*.2-sin(p.z*.2)),13.); //More infinite cylinders this time horizontal. Making caves makes me feel like a man... I miss the days of slaying sabre tooth tigers to impress the ladies.
  t.x*=0.55; //Remove the atrifact, fix me beautiful, baby.
  h=pounder(p+vec3(2,5,2)); //MAKE IT POUND! Yeah could have been boring but then we have major earth pounding action, who doesn't love pumping hey? Even Donald Trump is a fan.
  t=t.x<h.x?t:h; // Ah yeah make it pound but we gotta merge the columns with the rest, while retaining material IDs. It's like international diplomacy, everyone wants war, but let's have some tea and discuss these borders.
  h=vec2(length(cos((p*.3-td*.2)+vec3(0,tt*1.,0))),6.); //MAKE IT SNOW! I know winter is finished but I live in England were it's always bleak and we like it like this. Yeah you can keep your sunshine, Europe!
  g+=0.1/(0.1+h.x*h.x*400.); //Yeah make them little snow particles glow, it might lift the mood a bit, we sort of miss the European sunshine since Brexit.
  t=t.x<h.x?t:h; //Add particles to rest, like sprinkling glitter over your dick to make up for its lack of girth.
  return t;
}
vec2 tr( vec3 ro, vec3 rd ) // main trace / raycast / raymarching loop function 
{
  vec2 h,t= vec2(.1); //Near plane because when it all started there were no craft beer shops and boating shoes were for sailors.
  for(int i=0;i<128;i++){ //Main loop de loop 
    h=mp(ro+rd*t.x); //Marching forward like any good fascist army: without any care for culture theft (get distance to geom)
    if(h.x<.0001||t.x>40.) break; //conditional break we hit something or gone too far. Don't let the bastards break you down!
    t.x+=h.x;t.y=h.y; //Huge step forward and remember material id. Let me hold the bottle of gin while you count the colours.
  }
  if(t.x>40.) t.y=0.;//If we've gone too far then we stop, you know, like Alexander The Great did when he realised he left his iPhone charger in Greece. (10 points whoever gets the reference)
  return t;
}
#define a(d) clamp(mp(po+no*d).x/d,0.,1.)
#define s(d) smoothstep(0.,1.,mp(po+ld*d).x/d)
void mainImage( out vec4 fragColor, in vec2 fragCoord )//2 lines above are a = ambient occlusion and s = sub surface scattering
{
  vec2 uv=(fragCoord.xy/iResolution.xy-0.5)/vec2(iResolution.y/iResolution.x,1); //get UVs
  tt=mod(iTime+32.,62.8318);  //Time variable, modulo'ed to avoid ugly artifact. Imagine moduloing your timeline, you would become a cry baby straight after dying a bitter old man. Christ, that's some life you've lived, Steve.
  b=clamp(sin(tt*2.-1.4),0.,1.),b2=clamp(sin(tt*2.-2.2),0.,1.),bb=smoothstep(0.,1.,b); //some global animation variables. Because cranking automatons is almost as fun as maturbation, my friends.
  vec3 ro=mix(vec3(-2.-cos(tt*.4)*5.,5.,-17.+sin(tt*.2+1.)*-3.),vec3(cos(tt*.2)*3.,sin(tt*.4)*5.+6.,-12),ceil(sin(tt*.5))),//Ro=ray origin=camera position We bild camera right here broski. Gotta be able to see, to peep through the keyhole.
  cw=normalize(vec3(0,cos(tt*.1)*5.,0)-ro), //cw camera forward?      
  cu=normalize(cross(cw,vec3(0,1,0))), 		//cv camera up??
  cv=normalize(cross(cu,cw)), 				//cu camera left vector??? Not sure broh, too busy burning fossil fuels and maximizing my carbon footprint.
  rd=mat3(cu,cv,cw)*normalize(vec3(uv,.5)),co,fo,lp; //rd=ray direction (where the camera is pointing), co=final color, fo=fog color
  lp=vec3(2,5,2);//POINT LIGHT position is where the pounder is to create fake illumination from the core... Area lights I will do the day after I give up drinking, I promise.
  co=fo=vec3(.1)-length(uv)*.09-rd.y*.07; //background is grey with vignette and subtle vertical gradient based on ray direction y axis. It's grey like the heart of people from Birmingham.
  z=tr(ro,rd);t=z.x;//Trace the trace in the loop de loop. Aka sow those fucking ray seeds and reap them fucking pixels.
  if(z.y>0.){ //Yeah we hit something, unlike you trying it with that mediocre looking waitress
    po=ro+rd*t; //Get ray pos, know where you at, be where you is.
    no=normalize(e.xyy*mp(po+e.xyy).x+e.yyx*mp(po+e.yyx).x+e.yxy*mp(po+e.yxy).x+e.xxx*mp(po+e.xxx).x); //Make some fucking normals. You do the maths while I count how many instances of Holly Willoughby there really is.
    al=mix(vec3(1),vec3(0.0,.2,.3),min(td*.4+0.1*abs(sin(pp*1.)),1.)); //by default albedo is mix between white and blue but the mix is done with noise of terrain so give really nice details in hues of blue
    if(z.y<5.) al=vec3(0); //material ID < 5 makes it black
    if(z.y>5.) al=vec3(1); //material ID > 5 makes it white
    ld=normalize(lp-po);   //Point light direction shit, get light dir from light pos.
    float dif=max(0.,dot(no,ld)), //Dumb as fuck diffuse lighting
    attn=1.0-pow(min(1.0,length(lp-po)/20.),4.0), //Point light attenuation
    fr=pow(1.+dot(no,rd),4.), //Fr=fresnel which adds background reflections on edges to composite geometry better
    sp=pow(max(dot(reflect(-ld,no),-rd),0.),30.);//Sp=specular, stolen from Shane, who is "da man"
    co=attn*mix(sp+al*(a(.1)*a(.3)+.2)*(dif+(z.y==5.?s(0.8):0.)),fo,fr);//Building the final lighting result, compressing the fuck outta everything above into an RGB shit sandwich
    co=clamp(mix(fo,co,exp(-.0001*t*t*t)),0.,1.);//Fog soften things, but it won't stop hipsters from gentrifying the north of England.
  }  
  fragColor = vec4(pow(co+g*0.1+g2*0.20*vec3(0.0,.2,.3),vec3(0.45)),1);// Naive gamma correction
} //Thank you and good night brooooooski