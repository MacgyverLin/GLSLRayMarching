// Abandoned base on Mars. Created by Reinder Nijhoff 2013
// Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License.
// @reindernijhoff
//
// https://www.shadertoy.com/view/4sfGR7
//

#define DIRT
#define DYNAMICLIGHTNING
//#define SHADOWS
//#define REFLECTION

#define ROOMSIZE 10.
#define PORTALSIZE 1.5
#define PORTALHEIGHT 3.0

// seconds needed to walk through room
#define WALKINGSPEED 3.

#define MAXDISTANCE 1000.
#define MAXMATERIALS 1000.

#define EXPOSURE 2.3
#define AMBIANT 2.2
#define DYNAMICLIGHTSTRENGTH 7.
#define PI 3.1415926

#define NUMBEROFLIGHTS 2

float dirtFactor;

//
// math functions
//

const mat2 mr = mat2 (0.84147,  0.54030,
					  0.54030, -0.84147 );
float hash( float n ) {
	return fract(sin(n)*43758.5453);
}
vec2 hash2( float n ) {
    return fract(sin(vec2(n,n+1.0))*vec2(2.1459123,3.3490423));
}

vec3 hash3( float n ) {
    return fract(sin(vec3(n,n+1.0,n+2.0))*vec3(3.5453123,4.1459123,1.3490423));
}
float noise(in float x) {
	float p = floor(x);
	float f = fract(x);
		
	f = f*f*(3.0-2.0*f);	
	return mix( hash(p+  0.0), hash(p+  1.0),f);
}
float noise( in vec2 x )
{
    vec2 p = floor(x);
    vec2 f = fract(x);
	vec2 uv = p.xy + f.xy*f.xy*(3.0-2.0*f.xy);
	return textureLod( iChannel1, (uv+118.4)/256.0, 0.0 ).x;
}
float fbm( vec2 p ) {
	float f;
	f  =      0.5000*noise( p ); p = mr*p*2.02;
	f +=      0.2500*noise( p ); p = mr*p*2.33;
	f +=      0.1250*noise( p ); p = mr*p*2.01;
	f +=      0.0625*noise( p ); p = mr*p*2.01;
	return f/(0.9175);
}
vec3 rotate(vec3 r, float v){ return vec3(r.x*cos(v)+r.z*sin(v),r.y,r.z*cos(v)-r.x*sin(v));}
float crossp( vec2 a, vec2 b ) { return a.x*b.y - a.y*b.x; }

//
// intersection functions
//

void intersectPlane(const vec3 ro, const vec3 rd, const float height, out float dist) {	
	dist = MAXDISTANCE;
	if (rd.y==0.0) {
		return;
	}
	
	float d = -(ro.y - height)/rd.y;
	d = min(MAXDISTANCE, d);
	if( d > 0. ) {
		dist = d;
	}
}

void intersectSegment(const vec3 ro, const vec3 rd, const vec2 a, const vec2 b, out float dist, out float u) {
	dist = MAXDISTANCE;
	vec2 p = ro.xz;
	vec2 r = rd.xz;
	vec2 q = a-p;
	vec2 s = b-a;
	float rCrossS = crossp(r, s);
	
	if( rCrossS == 0.){
		return;
	}
	float t = crossp(q, s) / rCrossS;
	u = crossp(q, r) / rCrossS;
	
	if(0. <= t && 0. <= u && u <= 1.){
		dist = t;
	}
}

//
// material functions
//

float matfhf, matflf;
float matnoisehf;
vec3 math3;

void materialInit(in float seed, const vec2 coord) {
	matfhf = fbm( coord * 171. );
	matflf = fbm( coord );
	matnoisehf = noise( coord * 193. );
	math3  = hash3( seed * 11. );
}

vec3 materialBaseColor( float t ) {
	return textureLod( iChannel0, vec2(1.1459123*t,2.3490423*t), 0. ).xyz;
}

void materialDirt(  vec2 coord, out vec3 color, out vec2 normal ) {
	color = vec3( 0.7, 0.5, 0.4 ) * (0.75*matfhf+0.25);
	normal = vec2( matnoisehf*2. -1. );
}

vec2 materialGrooves( float seed, bool iswall ) {
	vec2 math2 = hash2( seed );
	if( iswall ) return clamp( floor(math2*6.) * 0.125 - 0.25, vec2(0.), vec2(1.));
	return clamp( floor( math2*4.) * 0.125, vec2(0.), vec2(1.));
}

float grooveHeight( float l, float w, float p ) {
	if( l == 0. ) return 1.;
	return smoothstep( l, (l-w), abs(2.*mod(p, l)-l) );
}

float materialHeightMap( vec2 grooves, vec2 coord ) {
	return min( grooveHeight( grooves.x, 0.01, coord.x ), grooveHeight( grooves.y, 0.01, coord.y ));
}

float materialDirtAmount( vec2 grooves, vec2 coord ) {
	vec2 f = mix( vec2(0.01), grooves*2., dirtFactor );
	return 1. - 0.5*min( grooveHeight( grooves.x, f.x, coord.x ), grooveHeight( grooves.y, f.y, coord.y ));
}

// calculate color

void getMaterial( float seed, vec2 coord, vec2 grooves,  bool isfloor, bool iswall, 
			  	  out vec3 color, out vec2 normal, out float spec ) {

	float height = materialHeightMap( grooves, coord );	
	normal.x = (height-materialHeightMap( grooves, coord-vec2(0.002,0.) )) * 500.;
	normal.y = (height-materialHeightMap( grooves, coord-vec2(0.,0.002) )) * 500.;
	normal += (0.2 * fract( math3.y * 1.64325 )) * (vec2( matfhf, matnoisehf ) - vec2(0.5));
	
	spec = (height + 4.*matfhf )*0.1*fract( math3.x * 1.13 )*matflf;
	
	vec3 color1 = materialBaseColor( seed ); 	
	vec3 color2 = materialBaseColor( seed*2.6345 ); 	

	// checkboard ?
	bool checkx = grooves.x > 0. && mod( coord.x, grooves.x*2. ) < grooves.x;
	bool checky = grooves.y > 0. && mod( coord.y, grooves.y*2. ) < grooves.y;
	
	if( fract( math3.z * 4.435 ) < 0.5 && ((checkx && checky) || (!checkx && !checky)) ) {
		color = mix( color2, color1, matflf*fract(math3.y*45.234) );
	} else {		
		color = mix( color1, color2, matflf*fract(math3.y*45.234) );
	}
	
	color *= (0.4+0.6*height+0.2*fract( math3.x*3.76 )*matfhf);
		
#ifdef DIRT	
	if( dirtFactor > 0.1 ) { // dirt
		vec2 dirtNormal; vec3 dirtColor;		
		materialDirt( coord, dirtColor, dirtNormal );
		
		float dirtAmount = materialDirtAmount( grooves, coord );	

		if( iswall ) {
			dirtAmount += clamp( dirtFactor - coord.y, -dirtAmount, 1.);
		} else	if( !isfloor ) {
			dirtAmount *= 0.5; // less dirt on ceiling
		}
	
		float dirtMix = clamp( 10. * (0.5* (dirtAmount * matflf + matfhf ) - (1.-dirtFactor)), 0., 1.);
	
		if( dirtFactor > 0.1 ) {
			color = mix( color, dirtColor, dirtMix );
			spec *= 1. - dirtMix;
			normal = mix( normal, dirtNormal, dirtMix );
		}
	}
#endif
}

void getWallMaterial( float seed, vec2 coord,  
					  out vec3 color, out vec2 normal, out float spec ) {
	coord *= 0.25;	
	materialInit( seed, coord );
	
	float s = mod( floor( math3.y*13.4361 ), 8. ) * 0.125;
	
	float wseed = seed;
	if( coord.y > s ) wseed += 1.;	

	vec2 grooves = materialGrooves( wseed, true );

	getMaterial( seed, coord, vec2(grooves.x, max( grooves.y, s )), false, true, color, normal, spec );
}

void getFloorMaterial( float seed, vec2 coord, bool isfloor,  
					   out vec3 color, out vec2 normal, out float spec ) {
	
	coord *= 0.25;	
	materialInit( seed, coord );
	vec2 grooves = materialGrooves( seed, false );

	getMaterial( seed, coord, grooves, isfloor, false, color, normal, spec );
}

//
// level creation
//

vec3 portalPlacements; // t=-1, t=0, t=1
bool inRoom;
float currentSeed, currentSeedFract, roomSeed;
vec3 ambiantLight;
vec2 pillarPosition;
float pillarAngle, roomHeight;
vec2 roommorph;
vec3 roomoffset;


//
// Initialization
//

void init( float t ) {
	float seed =  t / WALKINGSPEED;
	currentSeedFract = fract( seed );	
	currentSeed = floor( seed );	
	inRoom = mod( currentSeed, 2. ) < 1.;

	// dirt in base
	dirtFactor = 0.4+0.2*cos(iTime*0.05+0.5);
	
	// possible values: 0., 1., 2., 3. (n,e,s,w)
	portalPlacements = floor( mod( vec3( 
		noise(currentSeed*0.25-0.25), noise(currentSeed*0.25-0.0), noise(currentSeed*0.25+0.25) )*4., vec3(4.) ) );	
	
	ambiantLight = mix( materialBaseColor( currentSeed ), materialBaseColor( currentSeed+1. ), currentSeedFract );
	ambiantLight = normalize( ambiantLight+vec3(0.5) );

	roomSeed = (currentSeed+(inRoom?0.:1.));
	roommorph = 0.5*hash2( roomSeed ) + vec2( 0.5 );
	pillarPosition = (vec2(-0.7)+1.4*hash2( roomSeed*11. ))*(ROOMSIZE*roommorph);
	pillarAngle = hash( roomSeed )*6.;
	roomHeight = PORTALHEIGHT+PORTALHEIGHT*2.*hash(roomSeed);
}

//
// Render level
//

vec2 avoidPillar( in vec2 position ) {
	vec2  v = position - pillarPosition;
	float d = length(v);
	if( d < 1.5 ) {
		position += (1.5-d)*normalize(v);
	}
	return position;
}

void traceRoom( bool inside, float seed, bool isroom, vec3 roo, vec3 rd,
				out float dist, out vec3 color, out vec3 normal, out vec3 bumpnormal, out float spec) {
	
	float p1, p2;
	dist = MAXDISTANCE;
	vec3 offset;
		
	color = normal = bumpnormal = vec3(0.); spec = 0.;
	
	if( inside ) {
		p1 = mod( portalPlacements[0]+2., 4.); // enter room this side
		p2 = portalPlacements[1]; // leaving room this side
		offset = vec3(0.);
	} else {
		// if you're not inside this room, calculate offset of room
		seed += 1.;
		p1 = portalPlacements[1]; // enter room this side
		offset = 2.*vec3( p1==1.?ROOMSIZE:p1==3.?-ROOMSIZE:0., 0., p1==0.?ROOMSIZE:p1==2.?-ROOMSIZE:0. );
		p1 = mod( p1+2., 4.); // enter room this side
		p2 = portalPlacements[2]; // leaving room this side
	}

	bool hitfloor;

	vec3 ro = roo - offset;	
	vec3 t1, t2, hitnormal;
	vec2 hittex;
	float d, hitmaterial;
	
	// intersect with floor and ceiling
	t1 = vec3( -1., 0., 0. );
	t2 = vec3( 0., 0., -1. );

	// floor		
	intersectPlane( ro, rd, 0.0, d );
	if( d < dist && all( lessThan( abs( (ro+d*rd).xz), vec2(ROOMSIZE)))) {
		dist = d;
		hitmaterial	= mod(seed*124.565431, MAXMATERIALS); // procedural foor material
		hitnormal = vec3( 0., 1., 0.);
		hitfloor = true;
		hittex = (rd*dist+ro).xz;
	}
	// ceiling
	intersectPlane( ro, rd, isroom?roomHeight:PORTALHEIGHT, d );
	if( d < dist && all( lessThan( abs( (ro+d*rd).xz), vec2(ROOMSIZE)))) {
		dist = d;
		hitmaterial	= mod(seed*131.565431, MAXMATERIALS); // procedural foor material
		hitnormal = vec3( 0., -1., 0.);
		hitfloor = false;
		hittex = (rd*dist+ro).xz;
	}

	vec2 hits, hite, s, e;
	float u, hitu = -1.;
	
	if(	isroom ) {
		roomoffset = offset;
		
		// the walls, check for each side of room...
		for( int i=0; i<4; i++ ) {
			if( i == 0 ) {
				s = vec2( -ROOMSIZE, ROOMSIZE )*roommorph;
				e = abs(s); //vec2( ROOMSIZE, ROOMSIZE )*roommorph;
			} else if( i == 1 ) {
				e = vec2( ROOMSIZE, -ROOMSIZE )*roommorph;
				s = abs(e); //vec2( ROOMSIZE, ROOMSIZE )*roommorph;
			} else if( i == 2 ) {
				e = vec2( -ROOMSIZE, -ROOMSIZE )*roommorph;
				s = e; e.x = -e.x; //vec2( ROOMSIZE, -ROOMSIZE )*roommorph;
			} else {
				s = vec2( -ROOMSIZE, -ROOMSIZE )*roommorph;
				e = s; e.y=-e.y;//vec2( -ROOMSIZE, ROOMSIZE )*roommorph;
			}
			
			if( float(i) != p1 && float(i) != p2  ) { // normal wall
				
				intersectSegment( ro, rd, s, e, d, u );
				if( d < dist ) { dist = d; hitu = u; hits = s; hite = e; }

			} else { // three walls with portal
				vec2 sp, ep;
				if( i == 0 ) {
					sp = vec2( -PORTALSIZE, ROOMSIZE );
					ep = vec2( PORTALSIZE, ROOMSIZE );
				} else if( i == 1) {
					sp = vec2( ROOMSIZE, PORTALSIZE );
					ep = vec2( ROOMSIZE, -PORTALSIZE );
				} else if( i == 2) {
					sp = vec2( -PORTALSIZE, -ROOMSIZE );
					ep = vec2( PORTALSIZE, -ROOMSIZE );
				} else {
					sp = vec2( -ROOMSIZE, -PORTALSIZE );
					ep = vec2( -ROOMSIZE, PORTALSIZE );
				}
								
				intersectSegment( ro, rd, s, sp, d, u );
				if( d < dist ) { dist = d; hitu = u; hits = s; hite = sp; }
				
				intersectSegment( ro, rd, ep, e, d, u );
				if( d < dist ) { dist = d; hitu = u; hits = ep; hite = e; }
				
				// portal!
				intersectSegment( ro, rd, sp, ep, d, u );
				if( d < dist && (rd.y*d+ro.y > PORTALHEIGHT) ) { 
					dist = d; hitu = u; hits = sp; hite = ep;
				}
			}
		}
	} else { 
		// we are in a portal; check walls:		
		float totalu = 2.0 * ROOMSIZE;
		if( mod( p1, 2.) == mod( p2, 2.) ) {
			// straight	
		
			vec2 ps, pw;
			if( p1==0. || p1==2.) {
				ps = vec2( 0., ROOMSIZE );
				pw = vec2( PORTALSIZE, 0. );
			} else {
				ps = vec2( ROOMSIZE, 0. );
				pw = vec2( 0., PORTALSIZE );
			}
			
			vec2 o2, o1 = vec2(0.); 
			for( int j=0; j<6; j++ ) {
				if( j!=5 ) o2 = hash2(float(j)); else o2 = vec2(0.);
				
				s = o1+pw+ps*(1.-float(j)/3.);
				e = o2+pw+ps*(1.-float(j+1)/3.);
				
				intersectSegment( ro, rd, s, e, d, u );
				if( d < dist ) { dist = d; hitu = totalu+u; hits = s; hite = e; }
				
				e = o1-pw+ps*(1.-float(j)/3.);
				s = o2-pw+ps*(1.-float(j+1)/3.);
				
				intersectSegment( ro, rd, s, e, d, u );
				if( d < dist ) { dist = d; hitu = totalu-u; hits = s; hite = e; }
				
				o1=o2;
				totalu += distance( e, s );
			}		
		} else {
			// curved
			float a; vec2 o;
			if( min(p1, p2) == 0. ) {
				if( max(p1, p2) == 1. ) {
					a = PI * 0.5; o = vec2( ROOMSIZE, ROOMSIZE );
				} else {
					a = PI * 0.0; o = vec2( -ROOMSIZE, ROOMSIZE );
				}
			} else if( min(p1, p2) == 1. ) {
				a = PI * 1.0; o = vec2( ROOMSIZE, -ROOMSIZE );
			} else {
				a = PI * 1.5; o = vec2( -ROOMSIZE, -ROOMSIZE );
			}
			float da = 0.5 * PI / 6.;
			for( int j=0; j<6; j++ ) {
				float si = sin(a); float co = cos(a);
				float ds = sin(a+da); float dc = cos(a+da);
				a+=da;
				
				s = o+vec2( (ROOMSIZE+PORTALSIZE)*co , -(ROOMSIZE+PORTALSIZE)*si );
				e = o+vec2( (ROOMSIZE+PORTALSIZE)*dc, -(ROOMSIZE+PORTALSIZE)*ds);
				
				intersectSegment( ro, rd, s, e, d, u );
				if( d < dist ) { dist = d; hitu = totalu+u; hits = s; hite = e; }
				
				e = o+vec2( (ROOMSIZE-PORTALSIZE)*co , -(ROOMSIZE-PORTALSIZE)*si );
				s = o+vec2( (ROOMSIZE-PORTALSIZE)*dc, -(ROOMSIZE-PORTALSIZE)*ds);
				
				intersectSegment( ro, rd, s, e, d, u );
				if( d < dist ) { dist = d; hitu = totalu-u; hits = s; hite = e; }
				
				totalu += distance( e, s );
			}
		}
	}
	
	
	if(	isroom ) {			
		// pillar	
		for( int i=0; i<4; i++ ) {
			float angle = float(i)*PI*0.5+pillarAngle;
			s = vec2( cos( angle ), sin( angle ) ) + pillarPosition; 
			e = vec2( cos( angle+PI*0.5 ), sin( angle+PI*0.5 ) ) + pillarPosition;
				
			intersectSegment( ro, rd, s, e, d, u );
			if( d < dist ) { dist = d; hitu = u; hits = s; hite = e; }
		}
	}
	
	if( dist >= MAXDISTANCE ) {
		return;
	}
	
	// calculate color for material
	
	vec2 ntangent;
	
	if( hitu >= 0. ) {
		vec2 sme = hits-hite;
		float lt = length(sme);
		hittex.x = lt*hitu;
		hittex.y = (ro+rd*dist).y; 
		hitnormal = normalize( vec3( -sme.y, 0., sme.x ));
		t2 = vec3( 0., -1., 0. );
		t1 = cross( hitnormal, t2 );

		getWallMaterial( mod(seed*14.1565431, MAXMATERIALS),
						hittex, color, ntangent, spec );	
	} else {
		getFloorMaterial( hitmaterial, hittex, hitfloor,
				 		  color, ntangent, spec );
	}
	
	normal = hitnormal;
	bumpnormal = normalize( (normal + ntangent.x*t1) + ntangent.y*t2 );
}


bool traceShadow( vec3 roo, vec3 rd, float maxdist ) { 	

	float u, d = MAXDISTANCE;
	vec3 ro = roo - roomoffset;
	vec2 e, s;
	
	for( int i=0; i<4; i++ ) {
			float angle = float(i)*PI*0.5+pillarAngle;
			s = vec2( cos( angle ), sin( angle ) ) + pillarPosition; 
			e = vec2( cos( angle+PI*0.5 ), sin( angle+PI*0.5 ) ) + pillarPosition;
				
			intersectSegment( ro, rd, s, e, d, u );
			if( d < maxdist ) return true;
		}
	return false;
}

float trace( vec3 roo, vec3 rd, out vec3 color, out vec3 normal, out float spec ) {	
	normal = color = vec3( 0. );
	vec3 matcolor, bumpnormal, hitcolor, hitnormal, hitbumpnormal;
	float dist = MAXDISTANCE, d, hitspec;	
	
	// trace room
	traceRoom( inRoom, currentSeed, true, roo, rd, dist,
				 matcolor, normal, bumpnormal, spec);
	// trace portal
	traceRoom( !inRoom, currentSeed, false, roo, rd, d,
				  hitcolor, hitnormal, hitbumpnormal, hitspec);
	if( d < dist ) {
		dist = d;
		matcolor = hitcolor; normal = hitnormal; bumpnormal = hitbumpnormal; spec = hitspec;
	}

	vec3 intersection  = roo + rd*dist;
	
	// lightning
	color = (matcolor*ambiantLight)*(AMBIANT*(0.7 + 0.4*clamp( dot(bumpnormal, normalize( vec3( 0.2, 0.3, 0.5) ) ), 0., 1.)));
	color *= clamp( 7.5/dist, 0., 1.);
	
	vec3 offset = roomoffset + vec3( 0., 0.5*roomHeight, 0. );
	
#ifdef DYNAMICLIGHTNING	
	for( int i=0; i<NUMBEROFLIGHTS; i++ ) {	
		float fi = float(i); 
		vec3 lightcolor = hash3( roomSeed+float(i*643) );
		
		vec3 lightpos = (lightcolor*vec3(0.8*ROOMSIZE*roommorph.x,0.5*roomHeight,0.8*ROOMSIZE*roommorph.y)*
								 cos((2.*(fi+iTime))*lightcolor ))+offset;
		vec3 lightvec = lightpos-intersection;
		
		if( dot( lightvec, normal ) < 0. ) continue;
		
		float l = length( lightvec );
		vec3 nlightvec = lightvec * (1./l);
		
		// diffuse
		float diff = DYNAMICLIGHTSTRENGTH * clamp( dot( nlightvec, bumpnormal ), 0., 1.);	
		
#ifndef REFLECTION		
		// specular		
		float specu = clamp( dot( reflect(rd,bumpnormal), nlightvec ), 0.0, 1.0 );
		specu = 20. * DYNAMICLIGHTSTRENGTH * spec * (pow(specu,16.0) + 0.5*pow(specu,4.0));
#endif
		
#ifdef SHADOWS		
		if( !traceShadow( nlightvec*0.001+intersection, nlightvec, l ) )
#endif
#ifdef REFLECTION			
			color += matcolor*lightcolor*(diff / (l*l));		
#else
			color += matcolor*lightcolor*((diff+specu) / (l*l));
#endif
	}
#endif
	
	normal = bumpnormal;
	return dist;
}

//
// Camera path
//

vec3 initCamera( float f ) {	
	float p1 = mod( portalPlacements[0]+2., 4.);
	float p2 = portalPlacements[1];
	float mf = 1.-f;
	
	if( mod( p1, 2.) == mod( p2, 2.) ) {
		// straight	
		vec3 cam;
		if( p1==0.) {
			cam.xy = vec2( 0., ROOMSIZE-f*ROOMSIZE*2. );
		} else if( p1==1.) {
			cam.xy = vec2(  ROOMSIZE-f*ROOMSIZE*2., 0. );
		} else if( p1==2.) {
			cam.xy = vec2( 0., -ROOMSIZE+f*ROOMSIZE*2. );
		} else {
			cam.xy = vec2( -ROOMSIZE+f*ROOMSIZE*2., 0. );
		}
		cam.z = (p2==1.)?0.5*PI:(p2==2.)?PI:(p2==3.)?PI*1.5:0.;
		
		return cam;
	} else {
		// curved
		float a, an; vec2 o; 
		if( min(p1, p2) == 0. ) {
			if( max(p1, p2) == 1. ) {
				a = PI * 0.5; o = vec2( ROOMSIZE, ROOMSIZE );
			} else {
				a = PI * 0.0; o = vec2( -ROOMSIZE, ROOMSIZE );
			}
		} else if( min(p1, p2) == 1. ) {
			a = PI * 1.0; o = vec2( ROOMSIZE, -ROOMSIZE );
		} else {
			a = PI * 1.5; o = vec2( -ROOMSIZE, -ROOMSIZE );
		}
		if( mod(p1+1.,4.) == p2) f=mf;
		
		if( mod(p1+1.,4.) == p2) { // counter clockwise
			an = f*0.5*PI+(p1)*PI*0.5;
		} else {
			an = f*0.5*PI+(p1+1.)*PI*0.5;
		}
		
		a += f*PI*0.5;
		float s = sin(a); float c = cos(a);
		return vec3(o, an+0.5*PI)+vec3( c*ROOMSIZE, -s*ROOMSIZE, 0.);
	}
	return vec3(0.);
}

//
// Main
//

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
	vec2 q = fragCoord.xy/iResolution.xy;
	vec2 p = -1.0+2.0*q;
	p.x *= iResolution.x/iResolution.y;
	
	init( iTime+1.5 );
		
	vec3 camPosition = initCamera( currentSeedFract );
	if(inRoom) camPosition.xy = avoidPillar( camPosition.xy );
	
	vec3 ro = vec3( camPosition.x, 1.6+0.03*sin(iTime*6.), camPosition.y );
	vec3 ta = rotate( vec3(0.0, 0.0, 1.0), camPosition.z + 0.3*sin(iTime) );
		
	float roll = 0.13*sin(camPosition.z + 0.13*iTime);
	
	// camera tx
	vec3 cw = normalize( ta );
	vec3 cp = vec3( sin(roll), cos(roll),0.0 );
	vec3 cu = normalize( cross(cw,cp) );
	vec3 cv = normalize( cross(cu,cw) );
	vec3 rd = normalize( p.x*cu + p.y*cv + 1.5*cw );

	
	
	vec3 color, normal;
	float spec, dist;
	dist = trace( ro, rd, color, normal, spec );

#ifdef REFLECTION
	if( spec > 0.0) {
		vec3 speccolor = vec3(0.);
		float refspec;
		vec3 refl = normalize(reflect( rd, normal ));
		dist = trace( ro+rd*dist+refl*0.001, refl, speccolor, normal, refspec );	
		//dist = trace( ro, rd, speccolor, normal, refspec );				
		color += spec*speccolor;
	}
#endif
	
	color = pow( color, vec3(EXPOSURE) );
	
    // vigneting
    color *= 0.25+0.75*pow( 16.0*q.x*q.y*(1.0-q.x)*(1.0-q.y), 0.15 );
	
	fragColor = vec4( clamp(color, 0., 1.),1.0);
}