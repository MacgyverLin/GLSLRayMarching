//-----------------------------------------------------
// Created by sebastien durand - 2018
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
//-----------------------------------------------------


// Change this to improve quality (3 is good)
#define ANTIALIASING 1

//#define WITH_SHADOW
#define WITH_AO

// Isosurface Renderer
#define g_traceLimit 64
#define g_traceSize .004

#define STAR_VOXEL_STEPS 20
#define STAR_VOXEL_STEP_SIZE 3.
#define STAR_RADIUS .02
#define ZERO (min(0, iFrame))

float gTime;

//---------------------------------------------------------------------
//    Animation
//---------------------------------------------------------------------

//                       Contact           Down               Pass               Up      


vec3[9] HEAD = vec3[9](  vec3(50,24,0),    vec3(73,30,0),     vec3(94,20,0),     vec3(117,15,0),  
                         vec3(85+50,24,0), vec3(85+73,30,0),  vec3(85+94,20,0),  vec3(85+117,15,0), vec3(168+50,24,0));

vec3[9] SHOULDER = vec3[9](vec3(44,47,16),   vec3(66,53,16),    vec3(91,43,16),    vec3(115,38,16), 
                         vec3(85+51,50,16),vec3(85+73,55,16), vec3(85+91,43,16), vec3(85+111,37,16), vec3(168+44,47,16));

vec3[9] ELBOW = vec3[9]( vec3(25,64,25),   vec3(46,67,25),    vec3(88,70,25),    vec3(120,65,25),
                         vec3(85+54,62,25),vec3(85+87,67,25), vec3(85+91,71,25), vec3(85+92,61,25), vec3(168+25,64,25));

vec3[9] WRIST = vec3[9](vec3(20,85,15),   vec3(35,76,20),    vec3(88,100,25),   vec3(128,89,25), 
                         vec3(164,85,15),  vec3(85+102,81,20),vec3(85+88,98,25),vec3(85+82,81,20), vec3(168+20,85,15));

vec3[9] HIP = vec3[9](vec3(42,90,10),  vec3(62,95,10.),   vec3(83,88,10),   vec3(107,83,10),  
                         vec3(127,92,10), vec3(147,94,10.),  vec3(168,91,10),  vec3(192,85,10), vec3(42+168,90,10));

vec3[9] KNEE = vec3[9]( vec3(29,118,7),  vec3(48,120,8),   vec3(97,117,10),  vec3(130,107,10), 
                         vec3(144,120,7), vec3(167,118,7),  vec3(167,118,7),  vec3(181,111,7), vec3(168+29,118,7));

vec3[9] ANKLE=vec3[9](vec3(5,134,5),   vec3(22,132,6),   vec3(71,122,10),  vec3(113,127,10), 
                         vec3(162,146,5), vec3(164,146,5),  vec3(164,146,5),  vec3(168,137,5), vec3(168+5,134,5));

vec3[9] FOOT = vec3[9](  vec3(14,150,10), vec3(16,150,10),  vec3(63,139,10),  vec3(119,143,10), 
                         vec3(178,139,10),vec3(182,150,10), vec3(182,150,10), vec3(182,150,10), vec3(168+14,150,10));


vec3 shoulder1, elbow1, wrist1, head,
     shoulder2, elbow2, wrist2;
vec3 foot1, ankle1, knee1, hip1,
     foot2, ankle2, knee2, hip2;

mat2 rot, rot2;

// Interpolate pos of articulations
vec3 getPos(vec3 arr[9], int it, float kt, float z) {
    it = it%8;
    vec3 p = mix(arr[it], arr[it+1], kt);
	return .02*vec3(p.x+floor(gTime/8.)*168., 150.-p.y, p.z*z);
}


//---------------------------------------------------------------------
//    HASH functions (iq)
//---------------------------------------------------------------------

float hash( float n ) { return fract(sin(n)*43758.5453123); }

vec3 hash33( const in vec3 p) {
    return fract(vec3(
        sin( dot(p,    vec3(127.1, 311.7, 758.5453123))),
        sin( dot(p.zyx,vec3(127.1, 311.7, 758.5453123))),
        sin( dot(p.yxz,vec3(127.1, 311.7, 758.5453123))))*43758.5453123);
}


//---------------------------------------------------------------------
//    Palette
// https://www.shadertoy.com/view/4dsSzr
//---------------------------------------------------------------------
vec3 heatmapGradient(float t) {
	return clamp((pow(t, 1.5) * .8 + .2) * vec3(smoothstep(0., .35, t) + t * .5, smoothstep(.5, 1., t), max(1. - t * 1.7, t * 7. - 6.)), 0., 1.);
}


//---------------------------------------------------------------------
//    Geometry
//---------------------------------------------------------------------

// Distance from ray to point
float distanceRayPoint(vec3 ro, vec3 rd, vec3 p, out float h) {
    h = dot(p-ro,rd);
    return length(p-ro-rd*h);
    //return length(cross(p-ro,rd));
}

// Distance line / line (must exist simplest way to do this)
float distanceLineLine(vec3 ro1, vec3 u, vec3 ro2, vec3 v) {
    vec3 w = ro1 - ro2;
    float a = dot(u,u), b = dot(u,v), c = dot(v,v),
          d = dot(u,w), e = dot(v,w),
          D = a*c - b*b,
     	  sc = (b*e - c*d) / D,
     	  tc = (a*e - b*d) / D;
    // get the difference of the two closest points
    vec3 dP = w + (sc * u) - (tc * v);
    return sc>0. ? length(dP) : 1e3;   // return the closest distance
}


//---------------------------------------------------------------------
//      Start field (iterate in a 3d grid)
//---------------------------------------------------------------------

vec4 renderStarField(in vec3 ro, in vec3 rd, in float tmax) { 
    vec3 ros = ro;
    ros /= STAR_VOXEL_STEP_SIZE;
	vec3 offset, id,
         pos = floor(ros),
	     mm, ri = 1./rd,
		 rs = sign(rd),
		 dis = (pos-ros + .5 + rs*.5) * ri;
    float dint, d = 0.;
    vec4 col = vec4(0),
         sum = vec4(0);
    
	for( int i=ZERO; i<STAR_VOXEL_STEPS; i++ ) {
        id = hash33(pos);
        offset = clamp(id+.1*cos(id+(id.x)*iTime),STAR_RADIUS, 1.-STAR_RADIUS);
        d = distanceRayPoint(ros, rd, pos+offset, dint);
        if (dint>0.&& dint*STAR_VOXEL_STEP_SIZE<tmax) {
            col.rgb = heatmapGradient(.4+id.x*.6);
            col = vec4(.6+.4*col.rgb, 1.)*(1.-smoothstep(STAR_RADIUS*.5,STAR_RADIUS,d));
            col.a *= smoothstep(float(STAR_VOXEL_STEPS),0.,dint);
            col.rgb *= col.a/dint;				                                
            sum += (1.-sum.a)*col;
            if (sum.a>.99) break;
        }
		mm = step(dis, dis.yxy) * step(dis, dis.zzx);
		dis += mm * rs * ri;
        pos += mm * rs;
	}
	return sum;
}


//---------------------------------------------------------------------
//   Modeling Primitives
//   [Inigo Quilez] https://iquilezles.org/articles/distfunctions
//---------------------------------------------------------------------

bool cube(vec3 ro, vec3 rd, vec3 sz, out float tn, out float tf) { //, out vec3 n) {
	vec3 m = 1./rd,
         k = abs(m)*sz,
         a = -m*ro-k*.5, 
         b = a+k;
//	n = -sign(rd)*step(a.yzx,a)*step(b.zxy,b);
    tn = max(max(a.x,a.y),a.z);
    tf = min(min(b.x,b.y),b.z);
	return tn>0. && tn<tf;
}

float sdCap(vec3 p, vec3 a, vec3 b, float r ) {
    vec3 pa = p - a, ba = b - a;
    float h = clamp( dot(pa,ba)/dot(ba,ba), 0., 1. );
    return length( pa - ba*h ) - r;
}

float sdCap2(vec3 p, vec3 a, vec3 b, float r1, float r2) {
    vec3 pa = p - a, ba = b - a;
    float h = clamp(dot(pa,ba)/dot(ba,ba), 0., 1. );
    return length( pa - ba*h ) - mix(r1,r2,h);
}

float udRoundBox( vec3 p, vec3 b, float r ) {
  return length(max(abs(p)-b,0.))-r;
}

float sdCappedCylinder(vec3 p, vec2 h ) {
  vec2 d = abs(vec2(length(p.xz),p.y)) - h;
  return min(max(d.x,d.y),0.) + length(max(d,0.));
}

float sdPlane(vec3 p, vec3 n) {
  // n must be normalized
  return dot(p,n);
}

float smin(in float a, in float b, in float k ) {
    float h = clamp( .5+.5*(b-a)/k, 0., 1. );
    return mix( b, a, h ) - k*h*(1.-h);
}


//---------------------------------------------------------------------
//    Man + Ground distance field 
//---------------------------------------------------------------------
float mapGround(vec3 pos){
    vec3 te = textureLod(iChannel0, pos.xz*.1,1.).rgb;
    return pos.y+.3*length(te);
}

float map(in vec3 pos){
    
    const float r1= .15, r2 = .1, r3= .1;
    float d = 100.;
    
    // Leg 1
    d = min(d, sdCap2(pos, foot1, ankle1, r2,r1));
    d = min(d, sdCap(pos, ankle1, knee1, r1));
    d = min(d, sdCap2(pos, knee1, hip1, r1,r2));
 
    // Foot1 flat part - vector base linked to leg 1
    vec3 v2 = normalize(knee1 - ankle1);
    vec3 v1 = normalize(ankle1 - foot1-v2*.1);
    vec3 v3 = cross(v1,v2);
    d = max(d, -sdPlane(pos-ankle1+v2*.1, -cross(v1,v3))); 
    
    // Leg 2
    float d2 = sdCap2(pos, foot2, ankle2, r2,r1);
    d2 = min(d2, sdCap(pos, ankle2, knee2, r1));
    d2 = min(d2, sdCap2(pos, knee2, hip2, r1,r2));

    // Foot2 flat part - vector base linked to leg 2
    v2 = normalize(knee2 - ankle2);
    v1 = normalize(ankle2 - foot2-v2*.1);
    v3 = cross(v1,v2);
    d2 = max(d2, -sdPlane(pos-ankle2+v2*.1, -cross(v1,v3))); 

    d = min(d, d2);
    
    vec3 ep0 = mix(shoulder1,shoulder2,.5),
         ha0 = mix(hip1,hip2,.5);

    // Head
    d = min(d, sdCap2(pos, head - vec3(0,.17,0), head + vec3(-.02,.11,0),.13,.16));
    
    // Arm 1
    v1 = normalize(wrist1-elbow1);
    d = min(d, sdCap(pos, shoulder1, elbow1, r2));
    d = min(d, sdCap2(pos, elbow1, wrist1-.05*v1, r2,r3));

    // Hand1 - fix vector base to harm 1
    v3 = -normalize(cross(v1,normalize(wrist1-shoulder1)));
    v2 = -cross(v1,v3);
    vec3 c = wrist1-v3*.06-v1*.12;
    
	// Finders 1
    d2 = sdCap2(pos, c, wrist1+.1*(v2+v1+v3), .013,.033);
    d2 = min(d2, sdCap2(pos, c, wrist1+.18*(v1+v2*.2), .01,.03));
    d2 = min(d2, sdCap2(pos, c, wrist1+.2*(v1-v2*.2), .01,.03));
    d2 = min(d2, sdCap2(pos, c, wrist1+.15*(v1-v2*.6), .01,.026));
    
    // Arm 2
    v1 = normalize(wrist2-elbow2);
    d = min(d, sdCap(pos, shoulder2, elbow2, r2));
    d = min(d, sdCap2(pos, elbow2, wrist2-.05*v1, r2,r3));
    
    // Hand2 - fix vector base to harm 2
    v3 = normalize(cross(v1,normalize(wrist2-shoulder2)));
    v2 = cross(v1,v3);
    c = wrist2-v3*.06-v1*.12;
    
	// Finders 2     
    d2 = min(d2, sdCap2(pos, c, wrist2+.1*(v2+v1+v3), .013, .033));
    d2 = min(d2, sdCap2(pos, c, wrist2+.18*(v1+v2*.2), .01, .03));
    d2 = min(d2, sdCap2(pos, c, wrist2+.2*(v1-v2*.2), .01, .03));
    d2 = min(d2, sdCap2(pos, c, wrist2+.15*(v1-v2*.6), .01, .026));

    d = min(d, sdCap(pos, shoulder1, shoulder2, r2));
   	d = smin(d2, d, .08);
    
    // Torso
    vec3 a = mix(ha0,ep0,.15), b = mix(ha0,ep0,.78);
    
    // Neck
    d = smin(d, sdCap(pos, mix(shoulder1,shoulder2,.5)-vec3(.1,0,0), head-vec3(.08,.1,0), r2*.5),.06);
    d = smin(d, sdCap2(pos, a, b, .2,.26),.18);

    // Ground
    vec3 te = textureLod(iChannel0, pos.xz*.1,1.).rgb;
    d = min(d, pos.y+.3*length(te));
    
    // Belt
    vec3 pos2 = pos-ha0+vec3(0,-.13,.02);
    pos2.yz *= rot2;
    d = min(d,mix(d,sdCappedCylinder(pos2, vec2(.28,.08)),.4)); 
 
    // Backpack
    pos -= ep0;
    d2 = udRoundBox(pos+vec3(.33,.2,0), vec3(.1,.3,.2), .15); 
    d2 += .005*(smoothstep(.1,.6,cos(51.*(.2*pos.z+.4*pos.x*pos.x+pos.y)))+smoothstep(.4,.9,sin(51.*(.8*cos(1.+pos.z)+.4*pos.x+.2*pos.y))));
    pos.yz *= rot;
    d2 = smin(d2,mix(d,sdCappedCylinder(pos.yzx+vec3(.13,.04,.1), vec2(.37,.05)),.75),.05); 
    
    return min(d2,d);
}


//---------------------------------------------------------------------
//   Ray marching scene if ray intersect bbox
//---------------------------------------------------------------------

float Trace(in vec3 pos, in vec3 ray, in float start, in float end ) {
    // Trace if in bbox (TODO: return intersection with ground otherwise)
    float t, h, tn, tf, dx = gTime*168.*.02/8.+.85;
    if (cube(pos-vec3(dx,1.35,0), ray, vec3(1.1, 1.7,.7)*2.,  tn, tf)) {
        end = min(tf, end);
        t = max(tn, start);
        for( int i=ZERO; i < g_traceLimit; i++) {
            h = map( pos+t*ray );
            if (h < g_traceSize || t > end)
                return t > end?100. : t;
            t += h + .002;
        }
    }
	return 100.;
}


//---------------------------------------------------------------------
//   Soft shadows
//---------------------------------------------------------------------

#ifdef WITH_SHADOW
float calcSoftshadow( in vec3 ro, in vec3 rd, in float mint, in float tmax ) {
	float h, res = 1., t = mint;
    for(int i=ZERO; i<24; i++) {
		h = map( ro + rd*t );
        res = min( res, 8.*h/t );
        t += clamp( h, .05, .20 );
        if( h<.01 || t>tmax ) break;
    }
    return clamp( res, .0, 1.);
}
#endif


//---------------------------------------------------------------------
//   Ambiant occlusion
//---------------------------------------------------------------------

#ifdef WITH_AO
float calcAO( in vec3 pos, in vec3 nor ){
	float dd, hr, sca = 1., totao = 0.;
    vec3 aopos; 
    for( int aoi=ZERO; aoi<5; aoi++ ) {
        hr = .01 + .05*float(aoi);
        aopos =  nor * hr + pos;
        totao += -(map( aopos )-hr)*sca;
        sca *= .75;
    }
    return clamp(1. - 4.*totao, 0., 1.);
}
#endif


//---------------------------------------------------------------------
//   Shading
//   Adapted from Shane / Iq
//---------------------------------------------------------------------

vec3 doColor( in vec3 pos, in vec3 rd, in vec3 nor, in vec3 col){
    vec3 ref = reflect( rd, nor );

    // lighitng   
#ifdef WITH_AO
    float occ = calcAO( pos, nor );
#else
    float occ = 1.;
#endif
    vec3  lig = normalize( vec3(.4, .7, .6) ),
          hal = normalize( lig-rd );
    float amb = .4,//clamp( 0.5+0.5*nor.y, 0.0, 1.0 );
          dif = clamp( dot( nor, lig ), 0., 1. ),
          bac = clamp( dot( nor, normalize(vec3(-lig.x,0.,-lig.z))), 0., 1. )*clamp( 1.-pos.y,0.,1.),
          dom = smoothstep( -.1, .1, ref.y ),
          fre = pow( clamp(1.+dot(nor,rd),0.,1.), 2.);

#ifdef WITH_SHADOW
    dif *= calcSoftshadow( pos, lig, .2, 2.5 );
#endif
    float spe = pow( clamp( dot( nor, hal ), 0., 1. ),106.)*
        dif *
        (.04 + .96*pow( clamp(1. + dot(hal,rd), 0., 1.), 50. ));

    vec3 lin = .80*dif*vec3(1,.8,.55)*(.3+.7*occ) + 
    	(.4*amb*vec3(.4,.6,1.) +
    	 .5*dom*vec3(.4,.6,1.) +
    	 .5*bac*vec3(.25,.25,.25) +
    	 .25*fre*vec3(1)) * occ;
    return col*lin + 10.*spe*vec3(1,.9,.7);
}


//---------------------------------------------------------------------
//   Calculate normal
//   From TekF 
//---------------------------------------------------------------------
vec3 Normal( vec3 ro, vec3 rd, float t) {
	float pitch = .2 * t / iResolution.x;   
	pitch = max( pitch, .005 );
	vec2 d = vec2(-1,1) * pitch;

	vec3 p0 = ro+d.xxx, // tetrahedral offsets
	     p1 = ro+d.xyy,
	     p2 = ro+d.yxy,
	     p3 = ro+d.yyx;

	float f0 = map(p0), f1 = map(p1), f2 = map(p2),	f3 = map(p3);
	vec3 grad = p0*f0+p1*f1+p2*f2+p3*f3 - ro*(f0+f1+f2+f3);
	// prevent normals pointing away from camera (caused by precision errors)
	return normalize(grad - max(0., dot(grad,rd ))*rd);
}

vec3 NormalGround(vec3 ro, vec3 rd, float t) {
	float pitch = .2 * t / iResolution.x;   
	pitch = max( pitch, .005 );
	vec2 d = vec2(-1,1) * pitch;

	vec3 p0 = ro+d.xxx, // tetrahedral offsets
	     p1 = ro+d.xyy,
	     p2 = ro+d.yxy,
	     p3 = ro+d.yyx;

	float f0 = mapGround(p0), f1 = mapGround(p1), f2 = mapGround(p2),	f3 = mapGround(p3);
	vec3 grad = p0*f0+p1*f1+p2*f2+p3*f3 - ro*(f0+f1+f2+f3);
	// prevent normals pointing away from camera (caused by precision errors)
	return normalize(grad - max(.0,dot (grad,rd ))*rd);
}


//---------------------------------------------------------------------
//   Camera
//---------------------------------------------------------------------

mat3 setCamera( in vec3 ro, in vec3 ta, in float cr) {
	vec3 cw = normalize(ta-ro),
         cp = vec3(sin(cr), cos(cr),0.),
         cu = normalize( cross(cw,cp) ),
         cv = normalize( cross(cu,cw) );
    return mat3( cu, cv, cw );
}


//---------------------------------------------------------------------
//   Entry point
//---------------------------------------------------------------------

void mainImage(out vec4 fragColor, in vec2 fragCoord )
{
    gTime = iTime*6.;
   
    // Animation
    int it = int(floor(gTime));
    float kt = fract(gTime);
    
    float dz = 1.;
   
    head = getPos(HEAD, it, kt, dz);

    shoulder1 = getPos(SHOULDER, it, kt, -dz);
    elbow1 = getPos(ELBOW, it, kt, -dz);
    wrist1 = getPos(WRIST, it, kt, -dz);
    
    foot1 = getPos(FOOT, it, kt, dz);
    ankle1 = getPos(ANKLE, it, kt, dz);
    knee1 = getPos(KNEE, it, kt, dz);
    hip1 = getPos(HIP, it, kt, dz);
    
    shoulder2 = getPos(SHOULDER, it+4, kt, dz);
    elbow2 = getPos(ELBOW, it+4, kt, dz);
    wrist2 = getPos(WRIST, it+4, kt, dz);

    foot2 = getPos(FOOT, it+4, kt, -dz);
    ankle2 = getPos(ANKLE, it+4, kt, -dz);
    knee2 = getPos(KNEE, it+4, kt, -dz);
    hip2 = getPos(HIP, it+4, kt, -dz);

    
    float a = -1.5708*.4;
    rot = mat2(cos(a), sin(a), -sin(a), cos(a));
    
    a = -.15708;
    rot2 = mat2(cos(a), sin(a), -sin(a), cos(a));
    
    float dx = it%8 < 4 ? -85.*.02 : +85.*.02; 
    foot2.x += dx;
    ankle2.x += dx;
    knee2.x += dx;
    hip2.x += dx;

    shoulder2.x += dx;
    elbow2.x += dx;
    wrist2.x += dx;
    
// ------------------------------------
 
    vec2 q, m = iMouse.xy/iResolution.y - .5;
     
	float t, s1, s2, traceStart = .2;
    
    vec3 pos, ro, rd, col = vec3(0), colorSum = vec3(0);
     
#if (ANTIALIASING == 1)	
	int i=0;
#else
	for (int i=0;i<ANTIALIASING;i++) {
#endif
        float randPix = hash(iTime);
        vec2 subPix = .4*vec2(cos(randPix+6.28*float(i)/float(ANTIALIASING)),
                              sin(randPix+6.28*float(i)/float(ANTIALIASING)));        
    	// camera	
        q = (fragCoord.xy+subPix)/iResolution.xy;
        vec2 p = -1.0+2.0*q;
        p.x *= iResolution.x/iResolution.y;

        ro = vec3(hip1.x+12.*cos(3.14*(.01*iTime+m.x+.3)),3.+3.*abs(sin(.01314*iTime))+10.*(m.y+.3),hip1.z+12.*sin(3.14*(.01*iTime+m.x+.3)));// .9*cos(0.1*time), .45, .9*sin(0.1*time) );
        vec3 ta = hip1;

        ta.x +=1.2;
        ta.y = 1.2;
        
        // camera-to-world transformation
        mat3 ca = setCamera(ro, ta, 0.);

        // ray direction
        rd = ca * normalize( vec3(p.xy,4.5) );

        float tGround = -ro.y / rd.y;
        float traceEnd = 100.;//min(tGround,100.);
        traceStart = 10.;
        col = vec3(0);
        vec3 n;
        t = Trace(ro, rd, traceStart, traceEnd);
        
        if (tGround < 0.) 
            tGround = 100.;
        
        t = min(t, tGround);
        
        if (t<100.) {
            pos = ro + rd*t;
            n = pos.y<.02 ? NormalGround(pos, rd, t) : Normal(pos, rd, t);
            col = doColor(pos, rd, n, pos.y<.02 ? .02*vec3(.8,.8,.9) : vec3(.5,.0,.0));
            
        } else {
            // mysterious line in sky            
            float time = iTime*.5;
            float kt = fract(time);
            vec3 k = -.5+hash33(floor(time)+vec3(0, 2, 112));
            if (k.y>.25) {
                float t0 = distanceLineLine(ro,rd, k*200.+vec3(-100,0,0), normalize(k));
                col = vec3(1,.8,.7) * (1.-smoothstep(0.,.8,t0)) * smoothstep(.53,.01,rd.y+.2*kt);
                col *= (.5+.5*hash(time))*smoothstep(0.,1., kt);
            }
        }
        
#if (ANTIALIASING > 1)	
        colorSum += col;
	}
    
    col = colorSum/float(ANTIALIASING);
#endif
    
    // Render star dusts ------------------------
    vec4 star = renderStarField(ro, rd, t);
    	 star.rgb += col.rgb * (1. - star.a);
    	 col = star.rgb;
         
    // Post processing stuff --------------------
    // Fog
    float f = 50.;
    col = mix( vec3(.18), col, exp2(-t*vec3(.4,.6,1)/f) );
	// Gamma
    col = pow( col, vec3(.4545) );
    // Vigneting
    col *= pow(16.*q.x*q.y*(1.-q.x)*(1.-q.y), .1); 
    
	fragColor =  vec4(col,1);
}
