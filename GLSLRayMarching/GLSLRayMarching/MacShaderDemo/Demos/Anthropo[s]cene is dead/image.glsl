// Created by sebastien durand - 10/2018
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
// ---------------------------------------------------------
//
// Based / Adapted / Inspired from:
//
// [asalga] Metal Ball - https://www.shadertoy.com/view/MssGRl
// [Dave_Hoskins] 2Tweet Water Caustic - https://www.shadertoy.com/view/MdKXDm
// [Davidar] Global Wind Circulation - https://www.shadertoy.com/view/MdGBWG
// [FabriceNeyret2] message: click to see #2 - https://www.shadertoy.com/view/llyXRW
// [iq] Palettes - https://www.shadertoy.com/view/ll2GD3
// [iq] Plotter - https://www.shadertoy.com/view/lslBzS
// [Maarten] 2d signed distance functions - https://www.shadertoy.com/view/4dfXDn
// [mattz] SDF texture filtering, take 2 - https://www.shadertoy.com/view/4sVyWh
// [TekF] Humanoid Silhouettes - https://www.shadertoy.com/view/4scBWN
// [Virgil] Bouncing cam - https://www.shadertoy.com/view/llK3Dy)
// --------------------------------------------------------


#define WITH_XR


const vec2 shadowDelta = vec2(-.03,.03);
float gTime;

vec2 hash21(float p)
{
	vec3 p3 = fract(vec3(p) * vec3(.1031, .1030, .0973));
	p3 += dot(p3, p3.yzx + 19.19);
    return fract((p3.xx+p3.yz)*p3.zy);
}

// --------------------------------------------------------
// [iq] https://www.shadertoy.com/view/ll2GD3
// --------------------------------------------------------
vec3 pal( in float t, in vec3 a, in vec3 b, in vec3 c, in vec3 d ) {
    return a + b*cos( 6.28318*(c*t+d) );
}
vec3 palette(float k) {
    return pal( k, vec3(.5),vec3(.5),vec3(1),vec3(0.,.33,.67) );
}

// --------------------------------------------------------
// [Hazel Quantock] https://www.shadertoy.com/view/4scBWN
// --------------------------------------------------------

float RoundMax(float a, float b, float r) {
    a += r; b += r;
    float f = ( a > 0. && b > 0. ) ? sqrt(a*a+b*b) : max(a,b);
    return f - r;
}

float RoundMin(float a, float b, float r) {
    return -RoundMax(-a,-b,r);
}

// --------------------------------------------------------
// [TekF] Humanoid Silhouettes - https://www.shadertoy.com/view/4scBWN
// --------------------------------------------------------
float sdHumanoid(in vec2 uv, in float phase ) {
    #define Rand(idx) fract(phase*pow(1.618,float(idx)))
    float n3 = sin((uv.y-uv.x*.7)*11.+phase)*.014; // "pose"
    float n0 = sin((uv.y+uv.x*1.1)*23.+phase*2.)*.007;
    float n1 = sin((uv.y-uv.x*.8)*37.+phase*4.)*.004;
    float n2 = sin((uv.y+uv.x*.9)*71.+phase*8.)*.002;
    float head = length((uv-vec2(0,1.65))/vec2(1,1.2))-.15/1.2;
    float neck = length(uv-vec2(0,1.5))-.05;
    float torso = abs(uv.x)-.25;
    torso = RoundMax( torso, uv.y-1.5, .2 );
    torso = RoundMax( torso, -(uv.y-.5-.4*Rand(3)), .0 );
    float f = RoundMin(head,neck,.04);
    f = RoundMin(f,torso,.02);
    float leg =
        Rand(1) < .3 ?
        abs(uv.x)-.1-.1*uv.y : // legs together
    	abs(abs(uv.x+(uv.y-.8)*.1*cos(phase*3.))-.15+.1*uv.y)-.05-.04*Rand(4)-.07*uv.y; // legs apart
    leg = max( leg, uv.y-1. );
    f = RoundMin(f,leg,.2*Rand(2));
    f += (-n0+n1+n2+n3)*(.1+.9*uv.y/1.6);
    return max( f, -uv.y );
}


float sdHumans(in vec2 p, in int nb) {
    float d = 9999.;
    for (int i=0; i<nb; i++) {
        d = min(d, sdHumanoid(p, float(i)/float(nb)));
        p.x-=.6; //+.1*cos(float(i+1)*1245.);
    }
    return d;
}

// ------------------------------------------------------------


float sdFish(vec2 p) {
    float dsub = min(length(p-vec2(.8,.0)) - .45, length(p-vec2(-.14,.05)) - .11);  
    p.y = abs(p.y);
    float d = length(p-vec2(.0,-.15)) - .3;
    d = min(d, length(p-vec2(.56,-.15)) - .3);
    d = max(d, -dsub);
    return d-.055;
}

float sdMedusa(vec2 p) {
    p /= .5;
    float d = max(length(p) - .5, -p.y);
    p+=.05*sin(15.*p.y+5.*gTime);
    float d2 = smoothstep(0.,.5,abs(p.x));
    p+=.2;
    d2 = min(d2, smoothstep(0.,.5,abs(p.x)));
    p-=.4;
    d2 = min(d2, smoothstep(0.,.5,abs(p.x)));
    d2 = max(-p.y-.6,max(p.y,d2));
    return min(d,d2)*.5;
}

//  Maarten : https://www.shadertoy.com/view/4dfXDn
float triangleDist(vec2 p, float width, float height) {
	vec2 n = normalize(vec2(height, width / 2.0));
	return max(	abs(p.yx).x*n.x + p.x*n.y - (height*n.y), -p.x);
}


//  Maarten : https://www.shadertoy.com/view/4dfXDn
float boxDist(vec2 p, vec2 size) {
	//size -= vec2(radius);
	vec2 d = abs(p) - size;
  	return min(max(d.x, d.y), 0.0) + length(max(d, 0.0));
}


float sdFactory(vec2 p) { 	
    p += vec2(.2);
    float d = triangleDist(p, .2, .2);
    d = min(d,triangleDist(p-vec2(.2,0), .2, .2));
    d = min(d,triangleDist(p.yx-vec2(-.2,.45), .15, 1.));
    d = min(d, boxDist(p - vec2(.2,-.1), vec2(.2,.1))); 
    d = max(d, p.y-.4); 
    d = max(d, -boxDist(p-vec2(.1,-.075), vec2(.05,.05))); 
    d = max(d, -boxDist(p-vec2(.3,-.075), vec2(.05,.05))); 
    return d;
}

// ------------------------------------------------------------

float sdTriPrism( vec2 p, float k) {
    vec2 q = abs(p);
    return max(q.x*0.866025+p.y*0.5,-p.y)-k;
}

float udBox( vec2 p, vec2 b ) {
  return length(max(abs(p)-b,0.0));
}
 
float sdArrow(vec2 p) {
    return min(sdTriPrism(p,.3), 
               udBox( p + vec2(0,0.9), vec2(0.2, 0.6) ) );
}

// ------------------------------------------------------------

float lineSegDist( vec2 uv, vec2 ba, vec2 a, float r ) {
    vec2 pa = uv - a - ba*r; ba = -ba*r;
    return length( pa - ba*clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 ) );
}

float snowFlake(vec2 p) {
    p*=4.;
    p.y = -abs(p.y);

    float d2 = lineSegDist(p, vec2(-1., 0.), vec2(-1.2,-.5), 1.2); 
    d2 = min(d2, lineSegDist(p, vec2(-1., 0.), vec2(-1.6,-.15), .8)); 

    p.x = abs(p.x);
    

    float a = .6;
    float d = lineSegDist(p, vec2(1., 0.), vec2(.0,0.), 1.);
    d = min(d, lineSegDist(p, vec2(.5, -.866), vec2(0.,0.), 1.));
    d = min(d, lineSegDist(p, vec2(.5, -.866), vec2(a,0.), .25));
    d = min(d, lineSegDist(p, vec2(-.5, -.866), vec2(a*.5,-.866*a), .25));
    d = min(d, lineSegDist(p, vec2(1., 0.), vec2(a*.5,-.866*a), .25));
	
    return min(d, d2)-.08;
}


float hash( const in vec3 p ) {
	float h = dot(p,vec3(127.1,311.7,758.5453123));	
    return fract(sin(h)*43758.5453123);
}

float hash( const in vec2 p ) {
	float h = dot(p,vec2(127.1,311.7));	
    return fract(sin(h)*43758.5453123);
}


// rotation 
vec2 rotate(vec2 uv, float a) {
    float ca = cos(a), sa = sin(a);
    return uv*mat2(ca,sa,-sa,ca);
}

// rotation arround a center point
vec2 rotate(vec2 uv, float a, vec2 c) {
    float ca = cos(a), sa = sin(a);
    return (uv-c)*mat2(ca,sa,-sa,ca)+c;
}

vec3 shadow(float dShape, vec3 c, vec3 cfill) {
    return mix(c, cfill, .75*(1.-smoothstep(.0,.05, max(0.,dShape))));
}

// fill shape
vec3 fill(float dShape, vec3 c, vec3 cfill) {
    return mix(c, cfill, 1.-smoothstep(.0,.01, dShape));
}

vec3 fill(float dShape, vec3 c, vec4 cfill) {
    return mix(c, cfill.rgb, cfill.a*(1.-smoothstep(.0,.01, dShape)));
}

// draw shape
vec3 draw(float dShape, vec3 c, vec3 cdraw, float ep) {
    return mix(c, cdraw, 1.-smoothstep(0., .01, 2.5*abs(dShape-ep/2.)-ep));
}


// Bouncing cam by Virgil (https://www.shadertoy.com/view/llK3Dy)
float Bounce(float t) {
    return fract(t-1.)<1.? fract(-t)*0.1*sin(45.*t):0.;
}


float anim(float t, float t0, float dt) {
	return clamp((t-t0)/dt, 0., 1.);
}

//----------------------------------------------------------
// FONT
//----------------------------------------------------------
// Adapted from
//  [mattz] https://www.shadertoy.com/view/4sVyWh
//----------------------------------------------------------
float sample_dist_gaussian(vec2 uv) {
    const int nstep = 3;
    const float w[3] = float[3](1., 2., 1.);
    float d, wij, dsum = 0., wsum = 0.;    
    for (int i=0; i<nstep; ++i) {
        for (int j=0; j<nstep; ++j) {
            vec2 delta = vec2(float(i-1), float(j-1))/1024.;
            d = textureLod(iChannel0, uv-delta, 0.).w - 127./255.;
            wij = w[i]*w[j];
            dsum += wij * d;
            wsum += wij;
        }
    }
    return dsum / wsum;
}

float sdFont(vec2 p, int c) {
    vec2 uv = (p + vec2(float(c%16), float(15-c/16)) + .5)/16.;
    return max(max(abs(p.x) - .25, max(p.y - .35, -.38 - p.y)), sample_dist_gaussian(uv));
}


//----------------------------------------------------------
// Adapted from
//  [FabriceNeyret2] https://www.shadertoy.com/view/llyXRW
//----------------------------------------------------------
float sdMessage(vec2 p, int[52] text, int start, float scale, float bold, float italic) { // --- to alter in the icon with the alter message
    p /= scale;
    p.x += p.y*italic;
    float d = 9999., bounce;
    vec2 pp;
    //for (int i=start; i<text.length(); i++) {  // Compile time : 14s
    for (int i=min(iFrame,0)+start; i<text.length(); i++) { // COmpile time 2s [Thanks iq :)]   
        if (text[i] == 0) break;
        // anim ---
        bounce = ElasticEaseOut(anim(float(i)-5.*gTime, -3., 2.));
        pp = p;
       // pp.y += bounce;
        pp = rotate(pp,bounce);
        // ---
        d = min(d, sdFont(pp, text[i]));
        p.x-=.5;

    }
    return d*scale - bold;
}

//----------------------------------------------------------
// [Dave_Hoskins] https://www.shadertoy.com/view/MdKXDm
//----------------------------------------------------------
#define F length(.5-fract(k.xyw*=mat3(-2,-1,2, 3,-2,1, 1,2,2)*
vec4 water(vec2 p) {
    vec4 k;
    k.xy = p*(sin(k=iDate*.5).w+2.)/2e2;
    return pow(min(min(F.5)),F.4))),F.3))), 7.)*25.+vec4(0,.35,.5,1);
}

vec4 mapSphere(in vec2 uv, float r, in vec2 c) {
    float d = distance(uv,c);
	if (d < r) {
		vec3 n = mix(vec3(0,0,1), normalize(vec3(uv-c, 0)), d/r);
		float lat = acos(-n.y), 		
			  u = -acos(n.x/sqrt(1.0-n.y*n.y)) / (2. * PI) + gTime / 2.0,
              v = lat / PI; // rotation
        vec3 dirLight = normalize(vec3(1,0,1)),
			 col = vec3(1.);//vec3(.5)+.5*vec3(dot(n, dirLight));
        float k = smoothstep(r*.9,r,d);
		return vec4(mix(col,vec3(0),k), 1.-k) *  texture(iChannel1, fract(vec2(u,v))*vec2(160,72)/iChannelResolution[1].xy);
	}
  	return vec4(0);
}

                  
int[] txt = int[] (_T,_e,_m,_p,_e,_r,_a,_t,_u,_r,_e,0,_J,_e,_l,_l,_y,_F,_i,_s,_h,0,_A,_c,_i,_d,0,_P,_o,_p,_u,_l,_a,_t,_i,_o,_n,0,_S,_c,_e,_n,_e,2,_i,_s,2,_D,_e,_a,_d,0);


float cubicPulse( float c, float w, float x ){
    x = abs(x - c);
    if( x>w ) return 0.0f;
    x /= w;
    return 1.0f - x*x*(3.0f-2.0f*x);
}

float CubicPulse(vec2 p){
	return p.y - cubicPulse(0.5, 0.2, p.x);
}

float impulse( float k, float x ){
    float h = k*x;
    return max(0.,h*exp(1.0f-h));
}

float Impulse(vec2 p){	
	return p.y - 1.5*impulse(1.-p.x, 5.0);
}

vec3 animFactory(float t0, vec2 uv, vec3 c) {
    float ss = smoothstep(7.,12.,t0);
    vec4 col = mapSphere(uv+vec2(-1,0), .3, vec2(0));
    c = mix(c, mix(col.rgb,vec3(col.r+col.g+col.b)*.3,ss), col.a);
    float k = smoothstep(.0,.02,abs(length(uv+vec2(-1,0))-.29));
    c = mix(vec3(0), c, k);
    uv.x -= 1.;
    float scale = 1.+.2*(t0-4.);
    uv *= scale;
    uv.y -= ExpoEaseOut(fract(t0));
    uv = mod(uv+.5,1.)-.5; 

    vec3 cu = shadow(sdFactory(uv+shadowDelta),c,vec3(0));
    cu = fill(sdFactory(uv),cu,mix(vec3(1,0,0),vec3(.4),ss));
    cu = draw(sdFactory(uv),cu,vec3(0),.03);
    return mix(c, cu, smoothstep(5.,12.,t0));
}

vec3 animPopulation(float t0, vec2 uv, vec3 c) {
    uv.y += .5;
    uv.x +=.55;
    vec2 uv0 =uv;
    uv = rotate(uv, -1.57*BounceEaseOut(anim(t0, 43.5-28., 1.)));

    float nb = 50.*(impulse(1.-.08*(t0-1.), 5.0));

    uv0.x += -3.+t0*.1; 

    PLOT(Impulse, vec3(1,0,0), c, uv0-vec2(.5,0));
    c = fill(sdMessage(uv0*3.+vec2(+4.,.22), txt, 27, .5, 0., .0)/3., c, vec4(1,0,0,1));

    float dShape = sdHumans(uv*10., 1+int(nb))/10.;
    float dShapeSh = sdHumans(uv*10.+shadowDelta, 1+int(nb))/10.;         

    c = shadow(dShapeSh, c, vec3(0,0.,0.));
    c = fill(dShape, c, vec3(1));
	return c;
}

vec3 animOcean(float t0, vec2 uv, vec3 c, vec2 fc) {

    vec2 uv0 = uv;
    uv.y += .1*cos(t0-9.);
    uv.x += .3*(t0)-2.;
    vec2 uv2 = mod(uv+.2,.4)-.2;

    c = mix(c, mix(water(fc).rgb, vec3(0,1,1),.1*t0), .1);

    vec3 col;
    float hsh = hash(floor((uv+.2)/.4));
	float dShape=999., dShapeSh=999.;
    if (hsh>.1*(t0-2.)) {
        dShape = sdFish(3.*uv2)/3.;
        dShapeSh = sdFish(3.*(uv2+shadowDelta))/3.;
        col = vec3(1,0,0);

    } else if (hsh>.2+.05*(t0-3.)) {
        dShape = sdMedusa(3.*uv2)/3.;
        dShapeSh = sdMedusa(3.*(uv2+shadowDelta))/3.;
        col = vec3(0,1.,.7);
    }

    c = shadow(dShapeSh, c, vec3(0,0.,0.));
    c = fill(dShape, c, col);

    uv.x -= .6;
    dShape = mix(sdMessage(uv, txt, 17, .5, .0, .0), sdMessage(uv, txt, 12, .5, .0, .0), smoothstep(3.5,8.5,t0));
    c = fill(dShape, c, vec4(0,.7,.7,.2));


    float k = 1.+2.8*BounceEaseOut(anim(t0, 7.,2.));
    uv0+=vec2(k*.17,-(k-1.)*.2);
    uv0 /= k;
    uv0 = rotate(uv0, -1.57*BounceEaseOut(anim(t0, 7., 4.)));
    c = fill(sdMessage(uv0, txt, 22, .5, 0., .0)*k, c, mix(vec4(0), vec4(0,1,0,.2), smoothstep(2.,10.,t0)));

    return c;
}


vec3 animTemperature(float t0, vec2 uv, vec3 c) {
    float dShape = 999.;
    float dShapeSh = 999.;
    vec2 uv0 = uv;
    uv0.x -= .5;
    uv0.y += 2.5-smoothstep(0.,2.,t0) + 4.*QuadEaseIn(anim(t0, 7.,1.));;
    float move = BounceEaseOut(anim(t0, 4.,4.));
    uv0.y -= 2.*move;
    uv0 = rotate(uv0, move);
    dShape = 999.;
    dShapeSh = 999.;
    for (int i=0;i<10; i++) {
        vec2 uv2 = uv0 + (.2*hash21(float(i))-1.);
        uv2.y += .1*cos(10.*t0+float(i));
        dShape = sdArrow(3.*uv2)/3.;
        dShapeSh = sdArrow(3.*(uv2+shadowDelta))/3.;
        c = shadow(dShapeSh, c, vec3(0));
        c = fill(dShape, c, palette(.1*float(i)));
        c = draw(dShape, c, vec3(0,0.,0.), .04);
        uv0.x += .15;
    }

    uv.y += .2;
    float bounce = BounceEaseOut(anim(t0, 1.,2.));
    uv.y -= bounce;

    uv = rotate(uv, -1.57*BounceEaseOut(anim(t0, 5., 1.)));
    uv.x -= 8.*QuadEaseIn(anim(t0, 6., 1.));  

    dShape = sdMessage(uv+vec2(.5,0), txt, 0, .5, -.005+.01*anim(t0, 4.,1.), -.2);
    dShapeSh = sdMessage(uv+vec2(.5,0)+shadowDelta, txt, 0, .5, .01, -.2);

    c = shadow(dShapeSh, c, vec3(0,0.,0.));
    c = fill(dShape, c, vec3(1.,1.,1.));
    c = draw(dShape, c, vec3(0,0.,0.), .04);
	return c;
}

vec4 XR(vec2 U) {
	vec2 p = iResolution.xy;
    return vec4(2,7,3,1) * 
        min(.1,abs(max(length(p=abs(U+U-p)/p.y)-.8,
        min(.5-p, .6*p-.7*p.x).y))/.1 -.5);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord) {
    

	vec2 uv = 2.*(fragCoord.xy / iResolution.y) -1.;
	vec2 q = fragCoord.xy / iResolution.xy;
   
    // Background
    vec3 colBack =  .2*vec3(hash(vec3(q,1.)))*vec3(.32,.48,.54);
    colBack = pow(colBack, vec3(0.41545) );   
    colBack *= 10.*pow(q.x*q.y*(1.0-q.x)*(1.0-q.y), .838);

    vec3 c = colBack;
    float a1 = 13., a2 = a1 + 18., a3 = a2+9., a4 = a3 + 18., a5 = a4 + 16.;
    
#ifdef WITH_XR       
    gTime = mod(iTime,  a5 + 20.);
#else
    gTime = mod(iTime,  a5 + 10.);
#endif
    
    if (gTime < a1){
        float t0 = gTime-2.;
		c = animPopulation(t0, uv, c);

    } else if (gTime < a2) {
        float t0 = gTime-a1;
        c = animFactory(t0, uv, c);
        
    } else if (gTime < a3){
     	float t0 = gTime - a2;
        c = animTemperature(t0, uv, c);
        
    } else if (gTime < a4) { 
        float t0 = gTime-a3;
        c = animOcean(t0, uv, c, fragCoord);
 
    } else if (gTime < a5) {
        float t0 = gTime-a4;
        c = animPopulation(t0+8., uv, c);
        
     
    } else if (gTime < a5 + 10.) {
        uv *=1.1;
        
		float tt = mod(gTime,2.)/1.5;
    	float ss = pow(tt,.2)*0.5 + 0.5;
    	float gPulse = (.25+ss*0.5*sin(tt*6.2831*3.0)*exp(-tt*4.0));
        
   		float d = sdMessage(uv+vec2(.62+.025*gPulse,.00*gPulse), txt, 38, .5+.01*gPulse, .01, -.2);
        // Heart pulse  
      
    	c = draw(d, c, vec3(1,0,0), .01 + gPulse*.02);
     
    } 
    

    if (gTime >= a5 + 10.) {
        fragColor = XR(fragCoord);
    } else {
    	c = pow(c,vec3(1.1,1.1,.9));
    	fragColor = vec4(c,1.);
    }


    
}

