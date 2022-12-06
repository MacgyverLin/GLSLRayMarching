// Created by Sebastien DURAND - 2014
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

//----------------------------------------------------------------
// A lot from IQ shader Bridge (https://www.shadertoy.com/view/Mds3z2)

// 360 degres cam (comment for postcard section)
//#define ALLAROUND_CAM

// Because does not works with trees on my firefox !!!??
#define TREES

#define NB_ITER 64 

bool withMen, withWomen;  // Optimization: only calculate head if it is visible by the current ray

const float cc = .866, ss = -.5;
const mat2 Rot = mat2(cc,ss,-ss,cc);
const mat2 Rot2 = mat2(cc,-ss,ss,cc);

float noise( in vec2 x) {
    vec2 f = fract(x);
	return -1.0 + 2.0*textureLod( iChannel0, ((floor(x) + f.xy*f.xy*(3.0-2.0*f.xy))+0.5)/256.0, -100.0 ).x;
}

//----------------------------------------------------------------

float sdTorus(in vec3 p, in vec3 t ) {
  vec3 q = vec3(length(p.xz)-t.x,p.y,p.z);
  return max(length(q.x)-t.y, length(q.y)-t.z);
}

float sdCapsule(in vec3 p, in vec3 a, in vec3 b, in float r1, in float r2 ) {
    vec3 pa = p - a, ba = b - a;
    float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
    return length( pa - ba*h ) - mix(r1,r2,h);
}

bool intersectSphere(in vec3 ro, in vec3 rd, in vec3 c, in float r) {
    ro -= c;
	float b = dot(rd,ro), d = b*b - dot(ro,ro) + r*r;
	return (d>0. && -sqrt(d)-b > 0.);
}

//----------------------------------------------------------------

float smin( float a, float b, float k ) {
	float h = clamp( 0.5 + 0.5*(b-a)/k, 0.0, 1.0 );
	return mix( b, a, h ) - k*h*(1.-h);
}

vec2 smin(in vec2 a, in vec2 b ) {
	float h = clamp( .5 + 1.25*(b.x-a.x), 0., 1. );
	return mix( b, a, h ) - .4*h*(1.-h);
}

vec2 mini(in vec2 a, in vec2 b ) {
	return a.x<b.x?a:b;
}

//----------------------------------------------------------------


float terrain(in vec2 p) {
    p+=vec2(5,8.5);
    return 3.3 + 2.*cos(.1*length(p))-(1.6-1.6*cos(p.x/4.5)*cos(p.y/3.5))+.006*noise(p.yx*35.); // very regular patern + a little bit of noise
}


float trees(in vec3 p, in float h ) {
    vec2 v = p.xz;
	float e = .5*smoothstep( 0.4, 0.6, textureLod(iChannel1,0.001*v, -32.0).x )
	            *smoothstep( 23.0, 24.0, abs(p.z-3.) );
    v = mod( v, 5.0 ) - 2.5;
    float a = p.y - (h +6.0*e);
    return max(dot(vec2(0.94,0.342), vec2(length(v),a)),a);
}

vec2 girl(vec3 p) {
    p/=.85;

    vec2 res = vec2(length(p-vec3(0,3,0))-1.8, 0.);
    
    if (withWomen) {
		res.x = min(res.x, length(p-vec3(0,5.3,0))-1.4);
        p.xz*=Rot2;

        vec3 p1 = p - vec3(0,5.3,0);

        p1.xy*=Rot;

        float angle = atan(p1.x,p1.z);
        float k = .05*abs(cos(1.5+10.*angle));
        float cc = cos(3.14-10.*p1.y);
        float hat = sdTorus(p1, vec3(1.3,.3,.3))-.03*cc-.5*k;

        if (p1.y>0.) hat = min(hat, length(p1)-1.5-.5*k);

        hat = smin(hat, length(p-vec3(1.2,6.5,.0))-.4, 1.1);
        p1.z=abs(p1.z);
        hat = smin(hat, length(p1-vec3(-.54,-.6,1.34))-.18,.43);
        float hat2 = length(p1-vec3(-.4,-.95,1.6))-.25;

        vec3 p0 = p;    

        p0-=vec3(0,4.3,0)*(1.+.05*cos(p0.x));

        float echarpe = sdTorus(p0, vec3(1.3,.3,.3))-.05*cos(3.14-10.*p0.y);
        float noze = sdCapsule(p, vec3(-1.6,5.1,0), vec3(0,5.,0), .12, .3 );

        p.z = abs(p.z);
        float eyes = length(p-vec3(-1.3,5.32,.25))-.15;
        res = res.x<hat2 ? res : vec2(hat2, 8.); 
        res = res.x<eyes ? res : vec2(eyes, 12.); 
        res = res.x<noze ? res : vec2(noze, 13.); 
        res = res.x<hat ? res : vec2(hat,   mod(1.5708*angle,1.)>.5?8.:9.); 
        res = res.x<echarpe ? res : vec2(echarpe*.9, mod(1.5708*atan(p0.x,p0.z),1.)>.5?8.:9.); 
        res.x*=.9;
    }
    res.x*=.85;
    return res;
}


vec2 man(vec3 p) {
	float body = min(
            length(p-vec3(0,3,0))-1.8,
        	length(p-vec3(0,5.3,0))-1.4);
    vec2 res = vec2(body, 0.);
    
    vec3 p1=p;
    p1.z = abs(p1.z);
    float hand = min(sdCapsule(p1, vec3(.5,4.2,0), vec3(-1.6,3.2,2), .12, .09 ),
                     sdCapsule(p1, vec3(-1.2,3.3,1.8), vec3(-1.6,3.6,2.1), .1, .05));

    res = res.x<hand ? res : vec2(hand,    12.); 

    if (withMen) {
        vec3 p1 = p - vec3(0,5.3,0);

        p1.xy*=Rot;
        p.xz*=Rot;

        float angle = atan(p1.x,p1.z);
        float k = .05*abs(cos(1.5+10.*angle));
        float cc = cos(3.14-10.*p1.y);
        float hat = sdTorus(p1, vec3(1.3,.3,.3))-.03*cc-1.1*k;
        if (p1.y>0.) hat = min(hat, length(p1)-1.5-2.*k);

        hat = min(hat, length(p1-vec3(.3,2.,.0))-.54);

        vec3 p0 = p;    

        p0-=vec3(0,4.3,0)*(1.+.05*cos(p0.x));

        float echarpe = sdTorus(p0, vec3(1.3,.3,.3))-.05*cos(3.14-10.*p0.y);
        float noze = sdCapsule(p, vec3(-1.8,5.1,0), vec3(0,5.,0), .12, .3 );

        p.z = abs(p.z);
        float eyes = length(p-vec3(-1.3,5.43,.3))-.15;

        res = res.x<eyes    ? res : vec2(eyes,    12.); 
        res = res.x<noze    ? res : vec2(noze,    13.); 
        res = res.x<hat     ? res : vec2(hat,     mod(1.5708*angle,1.)>.5?10.:11.); 
        res = res.x<echarpe ? res : vec2(echarpe*.9, mod(1.5708*atan(p0.x,p0.z),1.)>.5?10.:11.); 
        res.x*= 0.9;
    }
    
    return res;
}


vec2 map(in vec3 p) {
	// Terrain
	float h = terrain(p.xz);

    // Snowmens
    vec2 res =  smin(mini(man(p-vec3(-1.3,0,3)), girl(p-vec3(-2,0.25,8))), vec2(p.y - h, 0.));
  
    // Trees
#ifdef TREES
    float dis = trees(p,h);
    return dis<res.x ? vec2(dis, 1.) : res;
#else
    return res;
#endif    
}

const float precis = 0.0235;
const vec3 eps = vec3(precis,0.0,0.0);

vec3 intersect( in vec3 ro, in vec3 rd ) {
    float h = precis*1.5, t = 4.0;
    vec2 res;
    for( int i=0; i<NB_ITER; i++ ){
        if(h<precis||t>100.) break;
        t += h;
	    res = map( ro+rd*t );
        h = res.x;
    }
    return vec3( t, res.y, (t>100.) ? -1.0 : res.y );
}
/*
vec3 calcNormal(in vec3 p) {
    vec2 e = vec2(eps.x, -eps.x); 
    return normalize(e.xyy * map(p + e.xyy).x + e.yyx * map(p + e.yyx).x + e.yxy * map(p + e.yxy).x + e.xxx * map(p + e.xxx).x);;
}
*/

vec3 calcNormal( vec3 pos, vec3 ray, float t) {
  //  vec2 e = vec2(eps.x, -eps.x); 
  //  return normalize(e.xyy * map(pos + e.xyy).x + e.yyx * map(pos + e.yyx).x + e.yxy * map(pos + e.yxy).x + e.xxx * map(pos + e.xxx).x);;

	float pitch = .5 * t / iResolution.x;
    
//#ifdef FAST
//	// don't sample smaller than the interpolation errors in Noise()
	pitch = max( pitch, .005 );
//#endif
	
	vec2 d = vec2(-1,1) * pitch;

	vec3 p0 = pos+d.xxx; // tetrahedral offsets
	vec3 p1 = pos+d.xyy;
	vec3 p2 = pos+d.yxy;
	vec3 p3 = pos+d.yyx;
	
	float f0 = map(p0).x;
	float f1 = map(p1).x;
	float f2 = map(p2).x;
	float f3 = map(p3).x;
	
	vec3 grad = p0*f0+p1*f1+p2*f2+p3*f3 - pos*(f0+f1+f2+f3);
	//return normalize(grad);	// prevent normals pointing away from camera (caused by precision errors)
	return normalize(grad - max(.0,dot (grad,ray ))*ray);
}



float softshadow( in vec3 ro, in vec3 rd, float k ) {
    float res=1., t=0.15, h=1.;
    for( int i=0; i<46; i++ ) {
        h = map(ro + rd*t).x;
        res = min( res, k*h/t );
		t += clamp( h, 0.15, 1.0 );
		if( h<0.012 ) break;
    }
    return clamp(res,0.0,1.0);
}

float calcOcc( in vec3 pos, in vec3 nor ) {
    return 1.;/*
    vec3 aopos;
	float hr=0., dd=0., totao = 0.;
    for(int aoi=0; aoi<8; aoi++ ){
       hr = 0.1 + 1.5*float(aoi*aoi)/64.;
       aopos = pos + nor * hr;
       dd = map( aopos).x;
	   totao += max( 0.0, hr-3.0*dd-0.01);
    }
    return clamp( 1.0 - 0.15*totao, 0.0, 1.0 );*/
}


vec3 lig = normalize(vec3(-0.5,0.25,-0.3));


void shade( in vec3 pos, in vec3 nor, in vec3 rd, in float matID, out vec3 mate){
// TODO: use an Array
    if( matID<0.5)        { mate = vec3(.8,.8,.8); }
    else if( matID>12.5 ) { mate = vec3(4.,.2,.2); }
    else if( matID>11.5 ) { mate = vec3(.1); }
    else if( matID>9.5 )  { mate = mix(vec3(0,.5,.6),vec3(.3,.8,.9), matID-10.); }
    else if( matID>7.5 )  { mate = mix(vec3(.6,0.2,.5),vec3(.9,.6,.8), matID-8.); }
 	else/*if( matID>.5)*/ { mate = vec3(0.05,0.1,0); }   
}


float cloudShadow( in vec3 pos ) {
	return 0.45 + 0.55*smoothstep( 0.1, 0.35, texture( iChannel1, 0.0003*(pos.xz + lig.xz*(100.0-pos.y)/lig.y) + 0.1+0.0023*iTime ).x );
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	vec2 q = fragCoord.xy / iResolution.xy;
    vec2 p = -1.0 + 2.0 * q;
    p.x *= iResolution.x/iResolution.y;
    vec2 m = vec2(.5,0.);
	if( iMouse.z>0.0 ) m = iMouse.xy/iResolution.xy;


    //-----------------------------------------------------
    // animate
    //-----------------------------------------------------

	float ctime = iTime*2.;


    //-----------------------------------------------------
    // camera
    //-----------------------------------------------------

#ifdef ALLAROUND_CAM
    float an = .3+ctime*.1;
	vec3 ro = vec3(28.0*sin(an),6.*cos(4.-an*.5)+9.5,28.0*cos(an));
#else   
    float an = -.35+1.2*sin(5.3+0.05*ctime) - 6.2831*(m.x-0.05);
	vec3 ro = vec3(-28.0*sin(-an),3.5+clamp(15.*m.y, 0.,100.),-28.0*cos(-an));
#endif
    
    vec3 ta = vec3(2.0,2.5,0.0);

    // camera matrix
    vec3 ww = normalize( ta - ro );
    vec3 uu = normalize( cross(ww,vec3(0,1,0) ) );
    vec3 vv = normalize( cross(uu,ww));

	// create view ray
	vec3 rd = normalize( p.x*uu + p.y*vv + 3.7*ww );


    //-----------------------------------------------------
	// render
    //-----------------------------------------------------

	vec3 col = 2.5*vec3(0.18,0.33,0.45) - rd.y*1.5;
	col *= 0.9;
    float sun = clamp( dot(rd,lig), 0.0, 1.0 );
	col += vec3(2.0,1.5,0.0)*0.8*pow( sun, 32.0 );

    vec3 bgcol = col;

	withMen = intersectSphere(ro, rd, vec3(-1.3,5.6,3), 2.3);
	withWomen = intersectSphere(ro, rd, vec3(-2,4.75,8), 1.8);
	
	// raymarch
    vec3 tmat = intersect(ro,rd);
    if( tmat.z>-0.5 )
    {
        // geometry
        vec3 pos = ro + tmat.x*rd;
        vec3 nor = calcNormal(pos, rd, tmat.x);
		float occ = calcOcc(pos,nor) * clamp(0.7 + 0.3*nor.y,0.0,1.0);

        // materials
		vec3 mate = vec3(0);
        shade( pos, nor, rd, tmat.z, mate);

		vec3 ref = reflect( rd, nor );

		// lighting
        float sky = 0.6 + 0.4*nor.y;
		float bou = clamp(-nor.y,0.0,1.0);
		float dif = max(dot(nor,lig),0.0);
        float bac = max(0.2 + 0.8*dot(nor,normalize(vec3(-lig.x,0.0,-lig.z))),0.0);
		float sha = 0.0;
        if( dif>0.01 ) {
            withMen = intersectSphere(pos+0.01*nor, lig, vec3(-1.3,5.6,3), 2.3);
			withWomen = intersectSphere(pos+0.01*nor, lig, vec3(-2,4.75,8), 1.8);
            sha=softshadow( pos+0.01*nor, lig, 64.0 );
			sha *= cloudShadow( pos );
        }
        float fre = pow( clamp( 1.0 + dot(nor,rd), 0.01, 1.0 ), 3.0 );

		// lights
		vec3 lin = dif*vec3(1.70,1.15,0.70)*pow(vec3(abs(sha)),vec3(1.0,1.2,2.0));
		lin += 1.2*bou*vec3(0.15,0.20,0.20)*(0.5+0.5*occ);
        lin += occ*( fre*vec3(1.00,1.25,1.30)*0.5*(0.5+0.5*dif*sha)
                    +sky*vec3(0.05,0.20,0.45)
					+bac*vec3(0.20,0.25,0.25));

		// fog
       // if (tmat.x<0.) tmat.x = 0.;  
		col = mix( bgcol, mate*lin, exp(-0.0015*pow(abs(tmat.x),1.67)) );
    } else {
        vec2 cuv = ro.xz + rd.xz*(100.0-ro.y)/rd.y;
        float cc = texture( iChannel1, 0.0003*cuv +0.1+ 0.0023*iTime ).x;
        cc = 0.65*cc + 0.35*texture( iChannel1, 0.0003*2.0*cuv + 0.0023*.5*iTime ).x;
        cc = smoothstep( 0.3, 1.0, cc );
        col = mix( col, vec3(1.0,1.0,1.0)*(0.95+0.20*(1.0-cc)*sun), 0.7*cc );
    }

	// sun glow
    col += vec3(1.0,0.6,0.2)*0.4*pow( abs(sun), 4.0 );

	//-----------------------------------------------------
	// postprocessing
    //-----------------------------------------------------
    // gamma
	col = pow( abs(clamp(col,0.0,1.0)), vec3(0.45) );

    // contrast, desat, tint and vignetting	
	col = col*0.8 + 0.2*col*col*(3.0-2.0*col);
	col = mix( col, vec3(col.x+col.y+col.z)*0.333, 0.25 );
	col *= vec3(1.0,1.02,0.96);
	col *= 0.55 + 0.45*pow( abs(16.0*q.x*q.y*(1.0-q.x)*(1.0-q.y)), 0.15 );

    #ifdef STEREO
    col *= vec3( eyeID, 1.0-eyeID, 1.0-eyeID );
	#endif

    fragColor = clamp(vec4( col, 1.0 ),0.,1.);
}
