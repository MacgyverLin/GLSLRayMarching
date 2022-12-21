// Eric Jang (c) 2016
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0

#define clamp01(a) clamp(a,0.0,1.0)
#define opS(d1,d2) max(-d1,d2)
// union 2 objects carrying material info
#define opU(a,b) ((a.x < b.x) ? a : b) 

#define PI 3.14159
#define BOAT_SPEED .4
//#define disable_village 1

// rendering docks is slow. Think of better way to do this.
//#define DOCKS 1

#define WOOD_MAT 0.
#define STRAW_MAT 1.
#define VILLAGE_MAT 2.
#define DOCKS_MAT 3.
#define DUDE_MAT 4.
#define FISH_MAT 5.

#define ID_NONE -1
#define ID_SKY 0
#define ID_WATER 1
#define ID_MOUNTAIN 2
#define ID_VILLAGE 3

vec3 sun_dir=normalize(vec3(0.18,0.1,1.));

float boat_dx;
#define START_POS vec3(7.,0.,7.6)

// hash maps sequences to random-ish values
float hash(float u)
{
    float f=u*13.1;
    return fract(sin(f)*134735.3);
}

float Hash2d(vec2 uv) { return fract(sin(uv.x + uv.y * 37.0)*104003.9); }
vec3 hash3( float n ) { return fract(sin(vec3(n,n+1.0,n+2.0))*vec3(84.54531253,42.145259123,23.349041223));}

vec3 rX(const in vec3 v, const in float cs, const in float sn) {return mat3(1.0,0.0,0.0,0.0,cs,sn,0.0,-sn,cs)*v;}
vec3 rY(const in vec3 v, const in float cs, const in float sn) {return mat3(cs,0.0,-sn,0.0,1.0,0.0,sn,0.0,cs)*v;}
vec3 rZ(const in vec3 v, const in float cs, const in float sn) {return mat3(cs,sn,0.0,-sn,cs,0.0,0.0,0.0,1.0)*v;}

// modeling functions
float smin( float a, float b, float k )
{
    float h = clamp( 0.5+0.5*(b-a)/k, 0.0, 1.0 );
    return mix( b, a, h ) - k*h*(1.0-h);
}

float sdSphere( vec3 p, float s )
{
  return length(p)-s;
}

float sdCappedCylinder( vec3 p, vec2 h )// h = radius, height
{
  vec2 d = abs(vec2(length(p.xz),p.y)) - h;
  return min(max(d.x,d.y),0.0) + length(max(d,0.0));
}

float dPlane(in vec3 ro, in vec3 rd)
{
    vec3 p0=vec3(0.);
    vec3 n=vec3(0.,1.,0.);
    return dot(p0-ro,n)/dot(rd,n);
}

float udRoundBox( vec3 p, vec3 b, float r )
{
  return length(max(abs(p)-b,0.0))-r;
}

float noise2d(vec2 uv)
{
    vec2 fr = fract(uv.xy);
    vec2 fl = floor(uv.xy);
    // 4 slightly different shifted versions
    // of the same set of blocky tiles.
    // we blend them together in x,y directions via
    // 3 mix operations
    // a=mix h00, h10 across x axis, 
    // b=mix h10, h11 across x axis
    // c=mix a,b across y axis
    // to get smooth clouds texture.
    float h00 = Hash2d(fl);
    float h10 = Hash2d(fl + vec2(1,0));
    float h01 = Hash2d(fl + vec2(0,1));
    float h11 = Hash2d(fl + vec2(1,1));
    return mix(mix(h00, h10, fr.x), mix(h01, h11, fr.x), fr.y);
}

float clouds(in vec3 rd)
{
    vec2 p=rd.xz/rd.y; // rd.xz/rd.y scales down farther in horizon 
 	float n = noise2d(p*1.0); 
    n += noise2d(p*2.0)*0.5;
    n += noise2d(p*4.0)*0.25;
    n += noise2d(p*8.0)*0.125;
    
	// n = mix(n * 0.4, n, clamp01(abs(rd.y*3.)));  // fade clouds in distance    
    n = mix(n,0.4*n, clamp01(abs(rd.y*3.2)));  // clouds thicker farther away (personal pref)
    return n;
}

float sdCappedCone( in vec3 p, in vec3 c ) // c=vec3(bottom radius, angle , height)
{
    vec2 q = vec2( length(p.xz), p.y );
    vec2 v = vec2( c.z*c.y/c.x, -c.z );
    vec2 w = v - q;
    vec2 vv = vec2( dot(v,v), v.x*v.x );
    vec2 qv = vec2( dot(v,w), v.x*w.x );
    vec2 d = max(qv,0.0)*qv/vv;
    return sqrt( dot(w,w) - max(d.x,d.y) )* sign(max(q.y*v.x-q.x*v.y,w.y));
}

float sdEllipsoid( in vec3 p, in vec3 r )
{
    return (length( p/r ) - 1.0) * min(min(r.x,r.y),r.z);
}

float sdTriPrism( vec3 p, vec2 h )
{
    vec3 q = abs(p);
    return max(q.z-h.y,max(q.x*0.866025+p.y*0.5,-p.y)-h.x*0.5);
}

float sdHouse(vec3 p, vec3 i, vec3 o, float h1, float h2) 
{ 
    // implemented as the intersection of an inner
    // udroundbox and outer udroundbox rotated 45 degrees
    // i and o are the xyz scales, respectively.
    // o is shifted down h units prior
    return max(udRoundBox(p-vec3(0.,-h1,0.),i,.01),
               udRoundBox(rZ(p-vec3(0.,-h2,0.),0.707106,0.707106),o,.01));
}

vec2 sdvillage(in vec3 p, float seed)
{
    vec3 R,q,q2; float d;
    vec3 scale=vec3(.5,1.,1.);
    
    vec2 dm=vec2(1000.,ID_NONE);
    for (float i=0.; i<4.; i+=1.) {
        R=hash3(seed+i)-.5; // dx, dy, ry
        q=p-vec3(i*3.2-R.x,R.y,-R.x);
        // rotate
        q=rY(q,cos(R.z),sin(R.z));
        
        d=sdHouse(q, vec3(1.,1.,1.), vec3(2.), -.6, 1.);
        dm=opU(dm,vec2(d,VILLAGE_MAT));
        
        q.y-=1.1;
        float roof=opS(sdTriPrism((q-vec3(0.,-.1,0.))*scale,vec2(.8,1.4)),
                       sdTriPrism(q*scale,vec2(.8,1.3)));
        dm=opU(dm,vec2(roof,DOCKS_MAT));
        
        // second story
        if (hash(seed+i)>0.3) {
            q2=q-vec3(0.,1.,0.);
            d=sdHouse(q2, vec3(1.,2.,1.), vec3(2.), -.6, 1.);
            dm=opU(dm,vec2(d,VILLAGE_MAT));
            q2.y-=1.1;
            float roof=opS(sdTriPrism((q2-vec3(0.,-.1,0.))*scale,vec2(.8,1.4)),
                           sdTriPrism(q2*scale,vec2(.8,1.3)));
            dm=opU(dm,vec2(roof,DOCKS_MAT));
        }    
    }
    
    return dm;
}

// signed distance function for village
float sdBoardWalk(in vec3 p, in vec2 s)
{
    // s = width, half length
    float d= udRoundBox(p,vec3(s.x,0.03,s.y/2.),0.03);
    float rx, dx, dz;
    float l; vec3 q;
    float k=0.;
    for (float i=-2.; i<2.; i+=1.)
    {
        dz=i*s.y/4.+s.y/8.;
        for (float j=0.; j<2.; j+=1.)
        {
            if (hash(k)>.05)
            {
               dx=(2.*j-1.)*s.x+.04;
                q=p-vec3(dx,0.,dz);
                rx=(Hash2d(vec2(i,j))-.5)*.4;
                q=rX(q,cos(rx),sin(rx));
                d=min(d,sdCappedCylinder(q,vec2(.01,.7)));
            }
        }
        k+=1.;
    }
    return d;
}


vec2 sddocks(in vec3 p)
{   
    vec2 s=vec2(.5,2.); // .5 wide, 4. long
    float d=10000.;
    float t, ry;
    float i=2.;

    
#if 0
        t=hash(i);
        ry=(t-.5)*.8;
        d=min(d,sdBoardWalk(rY(p-vec3(0.,0.,i*1.5),cos(ry),sin(ry)),vec2(.5,1.7+.1*t)));
#endif
	return vec2(d,DOCKS_MAT);
}

vec2 sdboat(in vec3 p) // sanpan-style boat.
{
    // wood stuff
    // hull
    vec3 q=rZ(p,cos(.03),sin(.03));
    float d=sdTriPrism((q-vec3(0.,-1.2,0.))*vec3(1.,-1.,1.),vec2(3.,.5)); // size, z-thickness
    
    vec2 offset=vec2(0.2,14.6);
    float cylinder= length(q.xy-offset)-14.5;
    d=opS(cylinder,d);
    
    float inner=udRoundBox(q-vec3(0.,0.3,0.),vec3(2.4,.2,.4),.03);
    d=opS(inner,d);
    
    // dude
   q=p-vec3(1.8,0.,0.2);
   float d2=sdSphere(q-vec3(0.,1.04,0.),.15); 
   
   float torso=sdEllipsoid( q-vec3(0.11,0.62,0.),vec3(.07,.2,.14) );
   torso=smin(torso,sdEllipsoid(q-vec3(0.05,0.45,0.),vec3(.09,.1,.15)),.12);
   d2=smin(d2,torso,.1);
   float legs=sdEllipsoid(q-vec3(0.11,0.14,.08), vec3(.03,.1,.03));
    legs=min(sdEllipsoid(q-vec3(0.11,0.14,-.08), vec3(.03,.1,.03)),legs);    
   d2=smin(legs,d2,.1);

    // pole
#if 1
   float pole=sdCappedCylinder(rZ(q-vec3(1.2,0.,0.16),cos(-1.),sin(-1.)),vec2(.02,2.4));
	d=min(d,pole);
#endif
    
    // straw stuff
    // roof
   vec3 q1=p-vec3(-0.5,0.,0.);
   
   float roof=opS(
   	sdCappedCylinder(q1.yxz,vec2(.48,.9)),
   	sdCappedCylinder(q1.yxz,vec2(.5,.8 ))
   );
   q1.x-=0.6;	
   q1=rZ(q1,cos(.05),sin(.05));
   //float roof1=opS(sdCappedCylinder(q1.yxz,vec2(.51,.6)),
   //                sdCappedCylinder(q1.yxz, vec2(.54,.5)));
   float roof1=sdCappedCylinder(q1.yxz, vec2(.54,.5));
   roof1=opS(udRoundBox(q1-vec3(0.,-.85,0.),vec3(1.),0.01),roof1);
   roof=min(roof,roof1);
    
   // hat
   vec3 q2=rX(q-vec3(0.,1.25,0.), cos(.1), sin(.1));
   float hat=sdCappedCone(q2,vec3(.2,.4,.18));
    

   vec2 dude=vec2(d2,DUDE_MAT);
   vec2 wood=vec2(d,WOOD_MAT);
   vec2 straw=vec2(min(hat,roof),STRAW_MAT);
   vec2 tm=opU(dude,opU(wood,straw));
    
#if 1
   // fish (q3 is fish coordinates)
   float fs=1000.; float f; vec3 q3;
   for (float i=0.; i<3.; i+=1.) {
   	q3=p-vec3(-1.6,0.15,-.2+i*.25);
    f=sdEllipsoid(q3,vec3(.3,.05,.15));
   	fs=min(f,fs);
   }
   
    vec2 fish=vec2(fs,FISH_MAT);    
    tm=opU(fish,tm);
#endif
    
    return tm;
   	
    
}

vec2 scene(in vec3 p)
{    
#ifdef disable_village
    return vec2(10000.,ID_NONE);
#endif
    // houses
	vec2 v1= sdvillage(rY(p-vec3(-2.,1.,20.),cos(-2.),sin(-2.)),0.);
    vec2 v2= sdvillage(rY(p-vec3(16.,.5,25.),cos(2.),sin(2.)),221.);
    vec2 tm=opU(v1,v2);
    
#ifdef DOCKS
    // docks
    float ry=1.2;
    vec3 q1=rY(p-vec3(-1.4,0.3,7.),cos(ry),sin(ry));
  	vec2 docks=sddocks(q1);
    tm=opU(docks,tm); 
#endif
    
    // boat
    vec3 q2=rY(p-START_POS,cos(.3),sin(.3))-vec3(boat_dx,0.,0.); // boat coordinates
	vec2 boat= sdboat(q2);
    
    return opU(tm,boat);
}

vec3 calcNormal( in vec3 p )
{
    vec3 e = vec3( 0.001, 0.0, 0.0 );
    vec3 n = vec3(
        scene(p+e.xyy).x - scene(p-e.xyy).x,
        scene(p+e.yxy).x - scene(p-e.yxy).x,
        scene(p+e.yyx).x - scene(p-e.yyx).x);
    return normalize(n);
}

vec3 background(in vec3 rd)
{
        vec3 col;
    
    // skycol fades into horizoncol closer to horizon
    vec3 skyCol = vec3( 0.49, 0.352, 0.294);
    vec3 horizonCol = vec3(0.866667, 0.47451, 0.270588);
    col=skyCol;
    col=mix(horizonCol,skyCol,clamp01(rd.y)*7.);
    
    // sunlight
    float sunlight=clamp01(pow(dot(rd,sun_dir),4.));
    
    // add sun
    //float sundot = smoothstep(.996,.999,sunlight);
    float sundot=1.-smoothstep(0.03,0.06,length(rd-sun_dir));
    col+=sundot*vec3(1.0,0.913725,0.458824);
    
    // clouds
    vec3 cloudcol=vec3( 0.623529,  0.298039,  0.164706)*1.5;

    //return cloudcol*sunlight;
    //col=vec3(clouds(rd));
    //col=mix(col,cloudcol*sunlight,clouds(rd));
    col=mix(col,cloudcol,clouds(rd));
    return clamp01(col);  
    
 #if 0
    
    vec3 col=vec3( 0.49, 0.352, 0.294); // sky color
    // add sun
    float sundot=1.-smoothstep(0.03,0.06,length(rd-sun_dir));
    col+=sundot*vec3(1.0,0.913725,0.458824);
   
    // clouds
    
    vec3 cloudcol=vec3(0.772549, 0.388235, 0.211765);
    col=mix(col,cloudcol*sunlight,clouds(rd));
    
    return col;
#endif
}

// FBM loop is inlined via macro
#define F (texture(iChannel0,p*s/1e3)/(s+=s)).x
float fbm(in vec2 p, in float s) { return F+F+F; }

vec3 cheapFog(in vec3 ro, in vec3 rd, in vec3 bgc, in vec3 p)
{
  float xscale=sqrt(clamp01(.8-abs(rd.x-.2))); // denser in valley
  float yscale=clamp01(1.-p.y*.02); // denser closer to ground
  float zscale=clamp01(sqrt(p.z*.01));// gets denser as we go farther out
  float n=clamp01(fbm(p.xy+iTime*4.,.1));
  float fog=xscale*yscale*zscale*n;
  //return vec3(fog);
  // lighting
  float sunlight=clamp01(pow(dot(rd,sun_dir),4.));
  vec3 fogc=mix(vec3(1.),vec3(0.843137,0.461373,0.247059),sunlight);
  // TODO - fog has to get lighting from sun.
  return mix(bgc,fogc,fog);
  //return mix(bgc,,fog);
}

float watermap( in vec2 p ) { // -.04,.2 controls water flow in XZ plane
	return fbm((p-iTime*vec2(-.04,.2))*10.,.5);
}

vec3 shade(vec3 p, float m)
{
    vec3 n=calcNormal(p);
   	vec3 sun_dir=normalize(vec3(-0.28,3.,1.));
    vec3 col;
    vec3 q2=rY(p-START_POS,cos(.3),sin(.3))-vec3(boat_dx,0.,0.); // boat coordinates
	if (m==WOOD_MAT) {
        col=vec3(0.152941,0.0627451,0.0392157);
    }
    else if (m==DOCKS_MAT) {
        vec3 wood1=vec3(0.36, 0.275, 0.1625);
        vec3 wood2=vec3(0.152941,0.0627451,0.0392157);
        col=mix(wood1,wood2,Hash2d(floor(p.xz*vec2(4.,1.))));   
    }
    else if (m==STRAW_MAT) {
        
        vec4 t=texture(iChannel1,q2.xz/2.);
        col=t.xyz;
    } else if (m==DUDE_MAT) {
        vec3 fleshcol=vec3(0.909804,  0.713725,  0.541176);
        vec3 pantscol=vec3(0.266667,  0.376471,  0.509804);
        col=mix(pantscol,fleshcol,smoothstep(.4,.45,q2.y));
    } else if (m==VILLAGE_MAT) {
        col=vec3(0.152941,0.0627451,0.0392157)*.1;
        // add windows
        vec3 wcol1=vec3(0.972549, 0.294118, 0.137255);
        vec3 wcol2=vec3( 1.0,0.709804,0.415686);
        
        vec4 t=texture(iChannel1,.2+p.xy*vec2(.15,.05));
        //return vec3(1.-t.x*t.y);
        float w1=smoothstep(0.7,.8,1.-t.x); // cooler orange glow
        float w2=smoothstep(0.8,0.9,1.-t.x); // hotter yellow light
        //return vec3(w2);
        // skip phong lighting and go straight to color
        return mix(col,mix(wcol1,wcol2,w2*w1),pow(w1,.2));
    } else if (m==FISH_MAT) {
        float shine=pow(smoothstep(.8,.99,dot(n,vec3(0.,.98,.2))),6.);
        col=mix(vec3( 0.459, 0.482, 0.514),vec3( 0.870588, 0.819608, 0.760784),shine);
        //col=vec3(pow(smooths(dot(n,vec3(0.,1.,0.))),4.));
    }
    
    col*=1.1*clamp01( dot( n, sun_dir ) ); // phong lighting   
    return col;
}

// render subcall (for water refl). returns object id and color.
// this does shading calculations.
int trace(in vec3 ro, in vec3 rd, out vec3 col, out vec3 p)
{
    int obj=ID_SKY;   
    col=background(rd); // default color = sky
    
    // mountains
    // exponential jump + binary search refinement
    float h; float h2;
	float t=0.;
    float jump;
    for (int i=0; i<100; i++) {
        jump=0.05*t+0.1;
        t+=jump;
        p=ro+t*rd;
        
        // foreground mountains
        float vwidth=0.7;// valley width
        float xscale=abs(rd.x-.2)*2.; // valley centered around sun
		float zscale=abs(p.z)/15.; // river gets wider closer to camera        
        h=fbm(p.xz*3.,.3)*xscale*zscale-.25;
        
        // background mountains
        float zscale2=p.z/20.-.7; // only show up in background
        vec4 tex=texture(iChannel2,p.xz/140.);
        h2=((tex.x-.4)*zscale2*max(xscale+.15,0.)-.2)*30.;
        
        // binary search refinement
        if (p.y <h || p.y<h2) {
            for (int j=0; j<5; j++) {
                float dir=(p.y<h || p.y<h2) ? -1. : 1.;
                jump*=.5;
                t+=dir*jump;
                p=ro+t*rd;
            }
        }
        
        if (p.y<h) {
            col=vec3(0.180392, 0.0745098, 0.031372)*2.*(1.-sqrt(h));
            obj=ID_MOUNTAIN;
           break;
        } else if (p.y < h2) {
            col=mix(vec3(0.180392, 0.0745098, 0.031372)*.5,vec3(0.72549,  0.392157,  0.231373)*.8,t/300.);
            obj=ID_MOUNTAIN;
            break;
        } else if (p.y<0.){
            obj=ID_NONE;
        }
    }
    
    // trace village
    t=0.1;
    vec2 dm;
    vec3 p2;
    for (int i=0; i<40; i++)
    {
        p2=ro+rd*t;
        dm=scene(p2);
        if (dm.x<0.01 || t>500.) break;
        t+=dm.x;
    }
   	if (t<1000. && t<length(p-ro))
    {
        p=p2;
        col=shade(p2,dm.y);
    	obj=ID_VILLAGE;
    }
    // is water
    if (p.y<0. && p2.y<0.){
        obj=ID_NONE;
    }
    
	return obj;
}

#define BUMP 0.1
// dx,dz control turbulence of normal displacement for reflection
#define dx vec2(.1,0.)
#define dz vec2(0.,.1)
vec3 render(in vec3 ro, in vec3 rd)
{
    vec3 p; float d;
    vec3 col=vec3(0.);
    
  	// intersect foreground
    int obj=trace(ro,rd,col,p);
    vec3 p2;

    if (obj==ID_NONE) { // we must have hit water == ID_NONE   
        d=dPlane(ro,rd);
        float fresnel;// bool refl;
        p=ro+d*rd;
        vec3 n=normalize(vec3(
            -BUMP*(watermap(p.xz+dx)-watermap(p.xz-dx))/(2.*BUMP), // central difference approximation of normal
            1.,
            -BUMP*(watermap(p.xz+dz)-watermap(p.xz-dz))/(2.*BUMP)
        ));
        fresnel = pow(1.0-abs(dot(n,rd)),5.);
        rd = reflect( rd, n);
        ro=p;
        trace(ro,rd,col,p2);    
        vec3 watercol=vec3( 0.439216  ,0.270588 , 0.203922);
        col=mix(col,watercol,1.-fresnel);
    }
    
    col=cheapFog(ro,rd,clamp01(col),p);
	return col;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    boat_dx=-mod(iTime*BOAT_SPEED+5.8,25.);

    // alternate animation - boat sailing down the river
    //ry=-1.7+sin(iTime)*.01;
    //vec3 q2=rY(p-vec3(3.,0.,1.4),cos(ry),sin(ry))-vec3(-mod(iTime*BOAT_SPEED+8.,50.),0.,0.);
    vec2  p = (-iResolution.xy+2.0*fragCoord.xy)/iResolution.y; // x=(-1.5,1.5), y=(1,1)
    
    vec3 ro=vec3(0.,1.5,0.); // eye location
    vec3 ta=vec3(0.,3.,20.); // look location
    vec3 up = vec3( 0.0, 1.0, 0.0 ); // up axis of world
    float d = 2.5; // distance between eye and film plane
    
    // build ray
    vec3 ww = normalize( ta - ro); // film plane normal
    vec3 uu = normalize(cross( up, ww )); // horizontal axis of film plane
    vec3 vv = normalize(cross(ww,uu)); // vertical axis of film plane
    vec3 rd = normalize( p.x*uu + p.y*vv + d*ww );
    
    vec3 col=render(ro,rd);
    
    // vignette
    vec2 q = fragCoord.xy/iResolution.xy;
    col *= 0.5 + 0.5*pow(20.0*q.x*q.y*(1.0-q.x)*(1.0-q.y),0.4);

    fragColor=vec4(col,1.); 
}
