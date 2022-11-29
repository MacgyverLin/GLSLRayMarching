// Moonlight. Created by Reinder Nijhoff 2013
// Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License.
// @reindernijhoff
//
// https://www.shadertoy.com/view/4sl3z4
//

#define SHOWALL
//#define SHOWBOTTLE

#ifdef SHOWALL
	#define SHOWBOTTLE
	//#define BOTTLESHADOW 0
	#define SHOWMOUNTAINS
	#define CLOUDDETAiL
#endif

#define CLOUDSHARPNESS 0.001
#define WINDSPEED vec2(-43.0, 32.0)
#define BUMPFACTOR 0.05
#define BUMPDISTANCE 70.
#define MAXMOUNTAINDISTANCE 40.
#define SKYCOLOR vec3(0.1,0.1,0.15)
#define MOONLIGHTCOLOR vec3(.4,0.4,0.2)
#define SKYBYMOONLIGHTCOLOR vec3(.4,.2,0.87)
#define BOTTLECOLOR vec3( 0.7, 1., 0.6 )*0.3
#define WATERCOLOR vec3( 0.2, 0.2, 0.4 )

#define EXPOSURE 0.9
#define EPSILON 0.01
#define MARCHSTEPS 100

#define time (iTime + 23.0)
#define CLOUDCOVER (0.1*cos( time*0.072+0.2 ) + 0.26)
#define moont (time * 0.1)
#define moonf (-time * 0.1)
#define moondir normalize( vec3( cos(moont), 0.8*(0.6+0.5*sin(moonf)), sin(moont) ) )

// math functions

const mat3 m = mat3( 0.00,  0.90,  0.60,
                    -0.90,  0.36, -0.48,
                    -0.60, -0.48,  0.34 );

const mat2 mr = mat2 (0.84147,  0.54030,
                      0.54030, -0.84147 );

float hash( float n ) {
    return fract(sin(n)*43758.5453);
}

float noise( in vec3 x )
{
    vec3 p = floor(x);
    vec3 f = fract(x);
	f = f*f*(3.0-2.0*f);
	
	vec2 uv = (p.xy+vec2(37.0,17.0)*p.z) + f.xy;
	vec2 rg = textureLod( iChannel0, (uv+ 0.5)/256.0, 0.0 ).yx;
	return mix( rg.x, rg.y, f.z );
}

float noise( in vec2 x )
{
    vec2 p = floor(x);
    vec2 f = fract(x);
	vec2 uv = p.xy + f.xy*f.xy*(3.0-2.0*f.xy);
	return textureLod( iChannel0, (uv+118.4)/256.0, 0.0 ).x;
}


float fbm( vec3 p ) {
    float f;
    f  =      0.5000*noise( p ); p = m*p*2.02;
    f +=      0.2500*noise( p ); p = m*p*2.33;
    f +=      0.1250*noise( p ); p = m*p*2.01;
    f +=      0.0625*noise( p ); 
    return f/(0.9175);
}

float fbm( vec2 p ) {
    float f;
    f  =      0.5000*noise( p ); p = mr*p*2.02;
    f +=      0.2500*noise( p ); p = mr*p*2.33;
    f +=      0.1250*noise( p ); p = mr*p*2.01;
    f +=      0.0625*noise( p ); 
    return f/(0.9175);
}

// heightmaps

float heightMap( vec3 pos ) {
	float n = noise( vec2(0.0,4.2)+pos.xz*0.14 );
	return 9.*(n-0.7);
}

float waterHeightMap( vec2 pos ) {
	vec2 posm = pos * mr;
	posm.x += 0.25*time;
	float f = fbm( vec3( posm*1.9, time*0.27 ));
	float height = 0.5+0.1*f;
	height += 0.13*sin( posm.x*6.0 + 10.0*f );

#ifdef SHOWBOTTLE	
	float d = length(pos-vec2(-3., 0.));
	height += 0.1 * cos( d*50.-time*4. ) * (1. - smoothstep( 0., 1.0, d) );
#endif
	
	return  height;
}

// intersection functions

bool intersectPlane(vec3 ro, vec3 rd, float height, out float dist) {	
	if (rd.y==0.0) {
		return false;
	}
		
	float d = -(ro.y - height)/rd.y;
	d = min(100000.0, d);
	if( d > 0. ) {
		dist = d;
		return true;
	}
	return false;
}

bool intersectHeightMap(vec3 ro, vec3 rd, float maxdist, const bool reflection, out float dist ) {
	float dt = 0.3;
	vec3 pos;
	dist = 0.0;
	bool hit = false;

	for( int i=0; i<MARCHSTEPS; i++) {
		if( hit || dist > maxdist ) break;
		
		dist += dt;
		dt = min( dt*1.1, 0.5 );
		pos = ro + rd*dist;
		if( heightMap( pos ) >= pos.y ) {
			hit = true;
		}
	}
	return hit;
}

bool intersectSphere ( in vec3 ro, in vec3 rd, in vec4 sph, out float dist, out vec3 normal ) {
    vec3  ds = ro - sph.xyz;
    float bs = dot( rd, ds );
    float cs = dot(  ds, ds ) - sph.w*sph.w;
    float ts = bs*bs - cs;
	
    if( ts > 0.0 ) {
        ts = -bs - sqrt( ts );
		if( ts>0. ) {
			normal = normalize( ((ro+ts*rd)-sph.xyz)/sph.w );
			dist = ts;
			return true;
		}
    }

    return false;
}

bool intersectCylinder( in vec3 ro, in vec3 rd, in vec3 A, in vec3 B, in float radius, out float dist, out vec3 normal) {
	vec3 AB = B - A;
	vec3 AO = ro - A;
 
	float AB_dot_d = dot( AB, rd );
	float AB_dot_AO = dot( AB, AO );
	float AB_dot_AB = dot( AB, AB );
 
	float m = AB_dot_d / AB_dot_AB;
	float n = AB_dot_AO / AB_dot_AB;
 
	vec3 Q = rd - (AB * m);
	vec3 R = AO - (AB * n);
 
	float a = dot( Q, Q );
	float b = 2.0 * dot( Q, R );
	float c = dot( R, R ) - (radius*radius);
 
	if(a == 0.0) {
		float adist = 100000., bdist = 100000.;
		if(	!intersectSphere( ro, rd, vec4( A, radius ), adist, normal ) ||
			!intersectSphere( ro, rd, vec4( B, radius ), bdist, normal ) ) {
			return false;
		}
 		dist = min (adist, bdist);
		normal = normalize((ro+rd*dist) - (adist<bdist?A:B) );
		return true;
	}
 
	float discriminant = b * b - 4.0 * a * c;
	if(discriminant < 0.0) {
		return false;
	}
 
	float sqrtdis = sqrt(discriminant);
	float tmin = (-b - sqrtdis) / (2.0 * a);
	float tmax = (-b + sqrtdis) / (2.0 * a);
	if( tmin < 0. )
		tmin = tmax;
	else 
		tmin = min(tmin, tmax); 
	
	if( tmin < 0. ) return false;
	
	float t_k1 = tmin * m + n;
	float dc = 10000000.;
	
	vec3 nc;
	
	if(t_k1 < 0.0)	{		
		if(intersectSphere( ro, rd, vec4( A, radius ), dist, normal)) {
			return true;
		} else {
			return false;
		}
	}
	else if(t_k1 > 1.0) {
		if(intersectSphere( ro, rd, vec4( B, radius ), dist, normal)) {
			return true;
		} else {
			return false;
		}
	} else {
		// On the cylinder...
		vec3 p1 = ro + (rd * tmin);
 		vec3 k1 = A + AB * t_k1;
		dist = tmin;
		normal = normalize( p1 - k1 );
		return true;
	}
	return false;
}
	
bool intersectBottle ( in vec3 ro,  in vec3 rd, out float dist, out vec3 normal ) {		
	float d = 1000000.;
	bool  hitc;
	float distc;
	vec3  normalc;	
	
	float rx = sin( iTime ) * 0.2;	
	vec3 up = vec3( 0., 0.4 * cos(rx), 0.4 * sin(rx) );
	vec3 pos = vec3(  -3.0, 0.05*cos(iTime*0.6)+0.05, 0.);
	
	hitc = intersectCylinder( ro, rd, pos+up*1.5, pos-up*1.5, 0.07, distc, normalc);
	if( hitc && distc < d ) {
		d = distc;
		normal = normalc;
	}
	hitc = intersectCylinder( ro, rd, pos+up*0.15, pos-up*0.15, 0.22, distc, normalc);
	if( hitc && distc < d ) {
		d = distc;
		normal = normalc;
	}
	if( d < 1000000. ) {
		dist = d;
		return true;
	}
	return false;
}

// more copy-paste functions...

float cloudDensity( vec3 rd ) {
	float d;
	intersectPlane( vec3(0., 0., 0.), rd, 500., d );
	vec3 intersection = rd*d;	
	
	float cloud = 0.5 + 0.5*fbm( vec3( 
		(intersection.xz + WINDSPEED*time)*0.001, time*0.25) ) - (1.-CLOUDCOVER);

#ifdef CLOUDDETAiL	
	cloud += 0.02*noise((intersection.xz - WINDSPEED*time*0.01));
#endif
	
    if (cloud < 0.) cloud = 0.;
	
	cloud = 1. - pow(CLOUDSHARPNESS, cloud);
	
	cloud = mix( CLOUDCOVER, cloud, smoothstep( 0.0, 0.1, dot( rd, vec3(0.,1.,0.) ) ) );
	
	return cloud;
}

vec3 skyColor( vec3 rd ) {	
	float moonglow = clamp( 1.0782*dot(moondir,rd), 0.0, 2.0 );
	vec3 col = SKYCOLOR * moondir.y;
	col += .4*SKYBYMOONLIGHTCOLOR*moonglow;
	col += 0.43*MOONLIGHTCOLOR*pow( moonglow, 21.0 );

	// moon!
	float dist; vec3 normal; bool moonhit = false;
	if( intersectSphere( vec3(0., 0., 0.), rd, vec4( moondir, 0.07), dist, normal ) ) {
		float l = dot( normalize(vec3( -moondir.x, 0.0, -moondir.z)+vec3( 2.2, -1.6, 0.)), normal );
		col += 3.0*MOONLIGHTCOLOR*clamp(l, 0.0, 1.);
		moonhit = true;
	}
		
	// Do the stars...
	if( !moonhit ) {
		vec3 rds = rd;
		
		float v = 1.0/( 2. * ( 1. + rds.z ) );
		vec2 xy = vec2(rds.y * v, rds.x * v);
		float s = noise(rds.xz*134.);
		s += noise(rds.xz*370.);
		s += noise(rds.xz*870.);
		s = pow(s,19.0) * 0.00000001 * max(rd.y, 0.0 );
		if (s > 0.1) {
			vec3 backStars = vec3((1.0-sin(xy.x*20.0+time*13.0*rds.x+xy.y*30.0))*.5*s,s, s); 
			col += backStars;
		}
	}
	
	col *= (1.0-cloudDensity( rd ) );

	return col;
}

// trace function

vec3 trace(vec3 ro, vec3 rd, float currentDistance, const bool reflection, out vec3 intersection, out vec3 normal, out float dist, out int material) 
{
	material = 0; // sky
	float d = 1000000.;
	bool  hitc;
	float distc;
	vec3  normalc;

#ifdef SHOWMOUNTAINS
	hitc = intersectHeightMap( ro, rd, MAXMOUNTAINDISTANCE-currentDistance, reflection, distc );
	if( hitc ) {
		material = 1; // mountain
		normal = -rd; // ahum
		d = distc;
	}
#endif

	hitc = intersectPlane( ro, rd, 0., distc);
	if( hitc && (distc < d) ) {
		material = 2; // water
		normal = vec3( 0., 1., 0. );
		d = distc;
	}
	
#ifdef SHOWBOTTLE
	hitc = intersectBottle( ro, rd, distc, normalc ); 
	if( hitc && (distc < d) ) {
		material = 3; // bottle
		normal = normalc;
		d = distc;
	}
#endif
	
	if( d < 100000. ) {
		dist = d;
		intersection = ro + rd*dist;
	}

	if( !reflection && material == 2 ) {
		vec2 coord = intersection.xz;
		vec2 dx = vec2( EPSILON, 0. );
		vec2 dz = vec2( 0., EPSILON );
		
		float bumpfactor = BUMPFACTOR * (1. - smoothstep( 0., BUMPDISTANCE, dist) );
		
		normal.x = bumpfactor * (waterHeightMap(coord + dx) - waterHeightMap(coord-dx) ) / (2. * EPSILON);
		normal.z = bumpfactor * (waterHeightMap(coord + dz) - waterHeightMap(coord-dz) ) / (2. * EPSILON);
		normal = normalize( normal );
	}
		
	vec3 col;
	float diff = clamp(dot(normal,moondir), 0., 1.);
	
	// shadow ?
#ifdef BOTTLESHADOW
	if( intersectBottle( intersection+normal*EPSILON, moondir, distc, normalc ) ) {
		diff = 0.;
	}
#endif
	
	if (material == 2) { // water
		col = WATERCOLOR * MOONLIGHTCOLOR * diff;
	} else if( material == 1 ) { // mountains
		col = mix( 0.5 * MOONLIGHTCOLOR * diff, vec3(0.), (currentDistance+dist)/MAXMOUNTAINDISTANCE);
	} else if( material == 3 ) { // bottle
		col = BOTTLECOLOR * diff * smoothstep( 0., 0.2, intersection.y );
	} else { // sky
		col = skyColor(rd);
	}
	
	if( material > 0 ) {
		col = mix( col, SKYCOLOR*CLOUDCOVER, clamp( dist/100., 0., 1.) );	
	}
		
	return col;
}
		
// main

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {

	vec2 q = fragCoord.xy/iResolution.xy;
    vec2 p = -1.0+2.0*q;
	p.x *= iResolution.x/iResolution.y;
    vec2 mo = iMouse.xy/iResolution.xy;
		 
	float a = moont + 0.3*sin( time*0.12 )+(mo.x>0.?(mo.x-0.5):0.)*3.1415*2.;
	// camera	
	vec3 ce = vec3( 0.0, 0.2, 0.0 );
	vec3 ro = ce + vec3( 1.3*cos(0.11*time + 6.0*mo.x), 0.65*(mo.y>0.?mo.y:0.5), 1.3*sin(0.11*time + 6.0*mo.x) );
	vec3 ta = ro + vec3( 0.95*cos(a), 0.75*ro.y-0.3+moondir.y*0.2, 0.95*sin(a) );
	
	float roll = -0.15*sin(0.1*time);
	
	// camera tx
	vec3 cw = normalize( ta-ro );
	vec3 cp = vec3( sin(roll), cos(roll),0.0 );
	vec3 cu = normalize( cross(cw,cp) );
	vec3 cv = normalize( cross(cu,cw) );
	vec3 rd = normalize( p.x*cu + p.y*cv + 1.5*cw );

	// raytrace
	int material;
	vec3 normal, intersection;
	float dist = 0., dist2 = 0.;
		
	vec3 col = trace(ro, rd, 0.0, false, intersection, normal, dist, material);

	if( material >= 2 ) {
		// reflection
		vec3 rfld = reflect( rd, normal );
		
		float reflectstrength = 1.-abs(dot( rd, normal ));
		
		col += 0.9 * reflectstrength * trace(intersection+rfld*EPSILON, rfld, dist, true, intersection, normal, dist2, material);
	}

	col = pow( col, vec3(EXPOSURE, EXPOSURE, EXPOSURE) );	
	col = clamp(col, 0.0, 1.0);
	
    // vigneting
    col *= 0.25+0.75*pow( 16.0*q.x*q.y*(1.0-q.x)*(1.0-q.y), 0.15 );
	
	fragColor = vec4( col,1.0);
}