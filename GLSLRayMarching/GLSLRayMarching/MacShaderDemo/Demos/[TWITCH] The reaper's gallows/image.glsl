// "Les potences de la faucheuse" (The reaper's gallows)
// Result of an improvised live coding session on Twitch

// LIVE SHADER CODING, SHADER SHOWDOWN STYLE, EVERY TUESDAYS 21:00 Uk time:
// https://www.twitch.tv/evvvvil_

// "Managing Grimsby Town Football Club makes me feel like Mary Poppins!" - Ian Holloway, comical genius and current manager of Grimsby Town FC

// ABRASIVE COMMENTS ARE BACK BY POPULAR DEMAND! (good to hear)
// Those offended by swearing or shit jokes can go sit on a bag of sharp & pointy dicks!

vec2 z,v,e=vec2(.035,-.035);float t,tt,g,bz,by,bb,tn;vec3 po,no,ld,al,np,bp,pp; //global vars: same old garbage brought to you in less that 3 characters
float bo(vec3 p,vec3 r){p=abs(p)-r;return max(max(p.x,p.y),p.z);} //box primitive, because all you need is a box, a sphere, some sudafed pills and a fire proof trailer
mat2 r2(float r){return mat2(cos(r),sin(r),-sin(r),cos(r));} //rotate function, whether it's meth or pasta sauce, there ain't no cooking without stirring
float smin(float a,float b,float h){float k=clamp((a-b)/h*.5+.5,0.,1.);return mix(a,b,k)-k*(1.-k)*h;} // "Smoothing out the merge" just like when corporations takeover small companies but only fire the working class. (adds geomtry together with smooth blend)
float smax(float d1,float d2,float k){float h=clamp(0.5-0.5*(d2+d1)/k,0.,1.);return mix(d2,-d1,h)+k*h*(1.0-h);}// "Smoothing out the gape" helps ease the pain of getting fucked by corporation above. (removes geometry from another with smooth blend)
float noi(vec3 p){ // Noise function. Just like your manhood, it is rather small. (easy I know but I'm clutching at straws at this point. Wait... "clutching at straws"... Talking about your dick again? haha, get it?)
  vec3 f=floor(p),s=vec3(7,157,113); //I don't really understand any of this, I'm too busy buying expensive vaporizers and pretenting to be that one hot girl match on your tinder
  p-=f;vec4 h=vec4(0,s.yz,s.y+s.z)+dot(f,s);
  p=p*p*(3.-2.*p);
  h=mix(fract(sin(h)*43758.5),fract(sin(h+s.x)*43758.5),p.x);
  h.xy=mix(h.xz,h.yw,p.y);
  return mix(h.x,h.y,p.z);
}
float branch(vec3 p,float s,float y){ // we make trees out of branches, just like god made hipsters out of spite for the 90s
  float t=length(p.xz)-0.6+y;//Make a branch out of an infinite cylinder (length(p.xz)-radius gives you a cylinder innit)
  t=max(t,bo(p,vec3(10,s,10)));//Crop out the infinite cylinder into normal cylinder. Yeah, I could use a cylinder primitive function, but no I didn't memorize it. Some paths are best not taken drunk, such as cylinders.
  return t;//No matter the scale, this branch is always bigger than your dick (ALWAYS end on a penis joke. Try it at your next family reunion...)
}
vec2 tree(vec3 p){ //Make tree with new position bp by pushing it in a loop. Then at different iterations moving, rotating, splitting. No joke on this line. This is a serious thing, unlike Manchester United football club.
  bp=abs(p*.4-vec3(0,-7,10))-vec3(12,0,4); // Create new position bp to stick in da loop, we already abs symetery clone it to make 4 trees and shift the whole fucking thing a bit to be "snug around the hole" (thats' what she said)
  vec2 h=vec2(1000,3); //setup the tree shape in vec2 to pass material id 3 = black colour. h.x should be, like me, and at all times, pretty fucking high.
  for(int i=0;i<6;i++){ //loop da loop each iteration making new branch  and turning bit if i>1 then splitting as well. Nothing crazy clever just some pseudo fractal bullshit, but at least it's desolate.
    h.x=min(h.x,branch(bp,2.3,p.y*.016)); //Draw one branch each iter 2.3 is length of branch
    bp.y-=2.3; //2.3 is lngth of branch, fuck knows how i got there but this is prob to shift rotation axis point or branch center point
    if(i>1) bp.x=abs(bp.x); //After second branch we start splitting, much like a good religious schism but without the drama of secatarian massacres
    bp.xy*=r2(-0.2-float(i)*.1); //rotate exponentially each iteration. Look at me using big words like "exponentionally" without actually understanding them. Just like at my wedding bruv: completely fucking winging it.
    bp.yz*=r2(0.1); bp.xz*=r2(0.1+float(i)*0.7); //Couple more rotates to make it more random tree-like, twisteroo the fuckeroo basically
    bp.y-=2.2; //2.2 is length of branch little smaller to remove lines due to noise and junction shifting but still fuck knows how i got there but this is prob to shift rotation axis point or branch center point
  }
  return h;
}
// Rough shadertoy approximation of the bonzomatic noise texture by yx - https://www.shadertoy.com/view/tdlXW4
vec4 texNoise(vec2 uv){ float f = 0.; f+=texture(iChannel0, uv*.125).r*.5;
    f+=texture(iChannel0,uv*.25).r*.25;f+=texture(iChannel0,uv*.5).r*.125;
    f+=texture(iChannel0,uv*1.).r*.125;f=pow(f,1.2);return vec4(f*.45+.05);
}// We miss you on Twitch Luna... Sending some love.
vec2 mp( vec3 p )
{
  p.z=mod(p.z+tt*10.,200.)-100.;  // Make it all infinite & moving forward, one liner desolate trains are go. Easier than convincing your flatmate it wasn't you singing "Hit me baby one more time" in the shower
  tn=texNoise(0.07*vec2(p.z,dot(p.xy,vec2(.5)))).r;//Texture based noise to add layer of really nice detail to overall 3d noise from function which we gonna add to overall position, bare with me homeboy
  pp=p; // remember the position at this point before adding the noise, in hindsight should have done it other way round but hey, hindsight is a bitch and you're still looking at my fake pic on tinder. Reality is also a bitch, I agree.
  p+=noi(p)*.5+noi(p*.5)*.5+noi(p*.1)*4.+tn*.8+noi(p*0.05)*7.; //Adding all sorts of 3d noise from noise function the key is to add noise calls at different scales to make it natural terrain /rock like. The final touch is the texture based noise which costs but adds details tricky to recreate with just 3d noise
  np=p;np.y*=0.7; //TERRAIN: we create a new position np based on noised out p for the three spheres (mountains) on the left hand side of terrain. What's better than a couple of balls? A trio of dangly frippy balls my friend.
  np.xz-=vec2(60,20)+sin(p.z)*.4; // shift whole group of dangly balls, it's like teabagging but with numbers instead of your tongue (less fun, I know)
  by=sin(p.y*.3-.5); //"by" is to deform balls along the y axis with sin, simple subtle displacement shit, unlike ageing which is a more complex displacement problem and cannot be avoided. Gravity is a bitch
  vec2 h,t=vec2(length(np)-(15.-1.2*by),5); //Draw first ball on left. Don't worry, more balls incoming, we'll take it way past inuendo.
  np-=vec3(-5,-7,20.); //shift the second ball back right and up a bit. With numbers I said, and just like when British people kiss: no tongues! (yeah the french are always right when it comes to love making)
  t.x=smin(length(np)-(13.-1.*by),t.x,5.);//One more ball because we all are born with two, whether it's tits or balls.
  np-=vec3(-10,4,20);//Shift again the last ball, this time with your tongue. Numbers ain't never gonna get you laid, no matter what the academia tries to prove.
  t.x=smin(length(np)-(15.-1.6*by),t.x,5.); //third ball, yeah my virility complex is pushing me over the edge, a third ball is required. I should consider making babies, instagram could do with more posers.
  bb=by-sin(p.z*.25);//Combo both "by" y-axis displacement and a new z-axis displacement into one variable bb to apply to all terrain objects.
  t.x=smin(length(p+vec3(20,90,-30))-(80.-bb),t.x,5.); //Another sphere this time in the middle, ready to be pounded into a hole. What a slut!
  t.x=smin(t.x,p.y+55.,25.); //We add an overall plane to the terrain to merge all the spheres together into a sexy surface, one so sexy that you might give up your innocence only just to touch it
  t.x=smax(length(p.xz-vec2(-5,15))-(20.-bb),t.x,15.); //Dig a fucking hole into the terrain for the cave hole thing, smooth that shit out so that it doesn't hurt
  t.x=smin(length(p+vec3(80,50,-100))-(80.-bb),t.x,5.); //one more Sphere mountain, right at back this time
  t.x=smin(length(abs(p+vec3(0,65,-50))-vec3(70,0,0))-(55.-bb),t.x,5.); //Couple of mounts on the side of the hole. Man do i even need to make a dirty joke here? re-read the sentence, it's filthy. This shader is disgusting I'm not sure what you're still doing here.
  t.x*=0.45; //Helps remove the artifact due to too much disortion. Yeah, I know, it's a bit much 0.45, I ain't gonna lie. But it looks shit otherwise and you should really have a decent gpu... Despite living at your parents, you're not a student anymore.
  h=tree(p); t=t.x<h.x?t:h; //Yeah we make fucking trees. I know I couldn't make my children better looking but at least I can make desolate trees.
  pp-=vec3(1,-5,40)+tn;//GALLOWS start here "pp" is gonna be the gallows' position of the gallows. "Gallows start here" good name for a post-brexit punk album.
  pp.xz*=r2(2.5); //yeah we rotate gallows a bit because they ain't nuttin' like facing death head on
  h=vec2(bo(pp,vec3(1.5,16,1.5)),3); //First tall box for gallows, like the excitement of laying the first stone of a cathedral, but it's for killing people, i know i know, still exciting.
  h.x=min(h.x,bo(pp+vec3(0,-15,-5.5),vec3(1.5,1.5,7))); //Long box at top of gallows, pointing forward even though clearly, the only moving you're gonna do is dangling from the noose!
  pp-=vec3(0,11,5); bp=pp;bp.yz*=r2(-0.788); //make new "bp" position and rotate that 45 degrees to make the underside 45 degree bit of gallows, 
  h.x=0.7*min(h.x,bo(bp,vec3(1.,1.,6))); //draw the underside of gallows call it the final piece to the reaper's christmas stocking
  t=t.x<h.x?t:h; //Merge gallows and terrain together while retaining material ID (colour), like a company rebrand but with more colours and without "Judgemental Jenny" getting fired
  pp-=vec3(0,-5,6.5)+tn+sin(p.y*30.)*0.02+sin(p.y*.1+tt)*(1.-abs(sin(p.y*.05))); // position for the rope, we make it sway with sin but taper out the influence so it is not moving at top, using this: (1.-abs(sin(p.y*.05))
  h=vec2(0.7*bo(pp,vec3(0.2,10,0.2)),6); //ROPE: we draw the rope, has a bit of displacement to make it ropey, unlike your mad uncle who is a ropey geezer by default.
  t=t.x<h.x?t:h; //Merge rope + gallows + terrain while retaining material ID. Like having sex with someone of different skin colour but the babies come out two tone as they retain material ID
  h=vec2(0.3*length(p-vec3(-5,-60,15)-sin(p.z))-5.,6); //GLOWY CORE, "Push a sphere inside the hole and make it glow!" said the porn producer with a clipboard to the 2 bemused performers...
  h.x=min(h.x,length(pp+vec3(0,10,0))); //DANGLY LITTLE GLOW SPHERE AT END OF ROPE: Because an actual bell-end wasn't subtle enough...
  g+=0.1/(0.1+h.x*h.x*(.2-0.02*abs(sin(p.y*.2+tt*5.)))); //MAKE IT GLOW! Glow trick from Balkhan via Flopine & lsdLive. Big up Balkhan, flopine and lsdLive. Push object distance field into global "g" variable like this and add at the end see line 127
  t=t.x<h.x?t:h; //Merge glowy bits with rest... Hey when you finally move out of your parents house, don't forget to retain material-fucking-ID, yeah?
  return t;
}
vec2 tr( vec3 ro, vec3 rd ) // main trace / raycast / raymarching loop function 
{
  vec2 h,t= vec2(.1); //Near plane because when it all started there were no craft beer shops and boating shoes were for sailors.
  for(int i=0;i<128;i++){ //Main loop de loop 
    h=mp(ro+rd*t.x); //Marching forward like any good fascist army: without any care for culture theft (get distance to geom)
    if(h.x<.001||t.x>500.) break; //conditional break we hit something or gone too far. Don't let the bastards break you down!
    t.x+=h.x;t.y=h.y; //Huge step forward and remember material id. Let me hold the bottle of gin while you count the colours.
  }
  if(t.x>500.) t.y=0.;//If we've gone too far then we stop, you know, like Alexander The Great did when he realised he left his iPhone charger in Greece. (10 points whoever gets the reference)
  return t;
}
#define a(d) clamp(mp(po+no*d).x/d,0.,1.)
#define s(d) smoothstep(0.,1.,mp(po+ld*d).x/d)
void mainImage( out vec4 fragColor, in vec2 fragCoord )//2 lines above are a = ambient occlusion and s = sub surface scattering
{
  vec2 uv=(fragCoord.xy/iResolution.xy-0.5)/vec2(iResolution.y/iResolution.x,1); //get UVs
  tt=mod(iTime*1.25,56.4)+81.75; //MAin time variable, it's modulo'ed to avoid ugly artifact. Holding time in my hand: playing god is nearly as good as this crystal meth bag
  vec3 ro=vec3(sin(tt*.1+0.9)*5.,7,-20)*mix(vec3(1),vec3(-3,-2,2),ceil(sin(tt*.5))),//Ro=ray origin=camera position
  cw=normalize(vec3(0,cos(tt*.1)*5.,0)-ro), //cw camera forward?      
  cu=normalize(cross(cw,vec3(0,1,0))), 		//cv camera up??
  cv=normalize(cross(cu,cw)), 				//cu camera left vector??? Not sure broh, just like Greta Thunberg, I didn't go to school.
  rd=mat3(cu,cv,cw)*normalize(vec3(uv,.5)),co,fo,lp; //rd=ray direction (where the camera is pointing), co=final color, fo=fog color
  lp=vec3(0); lp.z=mod(lp.z-tt*10.,200.)-100.; //MODULO'ed POINT LIGHT. Best trick of this shader: make light pos modulo on z axis and to stop it from suddendly shifting pos, we make a light switch using sin of trime (line 120)
  lp+=vec3(0,-20,15); //"Stick the point light inside the hole!" shouted the porn producer again, still holding his clipboard, to the even more baffled performers
  v=vec2(abs(atan(rd.y-1.1,rd.x)),rd.z+tt*0.04); //Background spherical UVs to create cheap fake pseudo volumterics. Nice cheap dirty trick this, bit like your mad uncle trying to steal ice cream from kids.
  co=fo=vec3(.1)+texNoise(0.4*v).r*.2-length(uv)*.14; //YA YA we make some pseudo cloud from noise texture function call. It's like reinventing the steam engine but without having to hang out with boring engineering nerds.
  z=tr(ro,rd);t=z.x;//Trace the trace in the loop de loop. Aka sow those fucking ray seeds and reap them fucking pixels.
  if(z.y>0.){ //Yeah we hit something, unlike you during your last bar fight
    po=ro+rd*t; //Get da ray pos    
    no=normalize(e.xyy*mp(po+e.xyy).x+e.yyx*mp(po+e.yyx).x+e.yxy*mp(po+e.yxy).x+e.xxx*mp(po+e.xxx).x); //Make some fucking normals. You do the maths while I ponder how likeable Holly Willoughby really is.
    al=vec3(.7); //by default albedo is greyish
    if(z.y<5.) al=vec3(0); //material ID < 5 makes it black
    if(z.y>5.) al=vec3(1); //material ID > 5 makes it white
    ld=normalize(lp-po);   //Point light direction shit 
    float ll=length(lp-po), attn=1.0-pow(min(1.0,ll/(100.*abs(sin(tt/6.3662)))),4.0); //abs(sin(tt/6.3662)) is light Switch - 6.3662 = 20/PI + 200/15 * PI * 0.01
    float dif=max(0.,dot(no,ld)), //Dumb as fuck diffuse lighting
    fr=pow(1.+dot(no,rd),4.), //Fr=fresnel which adds background reflections on edges to composite geometry better
    sp=pow(max(dot(reflect(-ld,no),-rd),0.),30.);//Sp=specular, stolen from Shane
    co=mix(sp*.5+al*(a(.1)*a(1.)+0.1)*(dif+s(.4)),fo,min(fr,.4))*attn; //Building the final lighting result, compressing the fuck outta everything above into an RGB shit sandwich
    co=mix(fo,co,exp(-.0000005*t*t*t));//Fog soften things, and makes pseudo volumetrics, still though it won't save your marriage. Fucking your partner will.
  }  
  fragColor = vec4(pow(co+g*.1,vec3(0.45)),1);// Naive gamma correction, naive yes, but very small... LIKE YOUR DICK! (Told you to always end on a dick joke, no matter how cheap it is)
} //Thank you and good night brooooooski