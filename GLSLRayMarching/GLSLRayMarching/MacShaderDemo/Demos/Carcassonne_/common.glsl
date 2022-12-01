// Created by sebastien durand - 01/2019
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
// *****************************************************************************

// [Dave_Hoskins] Rolling hills - https://www.shadertoy.com/view/Xsf3zX
// [Shane] Voxel Corridor - https://www.shadertoy.com/view/MdVSDh
// [HLorenzi] Hand-drawn Sketch  - https://www.shadertoy.com/view/MsSGD1
// [Mercury] Lib - http://mercury.sexy/hg_sdf for updates
// [dr2] White Folly - https://www.shadertoy.com/view/ll2cDG




//#define ALTERNATE_MODE


#define EDGE_WIDTH 5e-3
#define NB_ITER 100
#define MAX_DIST 90.
#define PRECISION 2e-4
#define PI 3.14159265
#define TAO 6.28318530718
#define PHI (sqrt(5.)*0.5 + 0.5)
#define SQRT2 1.41421356237 // sqrt(2.)
#define _SQRT2 .70710678118




vec3 sunLight = normalize(vec3(15,25,10));
vec2 iRes;
vec2 fCoord;
float time;



// -- START OF MERCURY LIB -----------------------------------
// !!! Be careful, this is an adaptation !!!
// for true lib, go to http://mercury.sexy/hg_sdf
// -----------------------------------------------------------

// Maximum/minumum elements of a vector
float vmax(vec2 v) {
	return max(v.x, v.y);
}

float vmax(vec3 v) {
	return max(max(v.x, v.y), v.z);
}

// Cheap Box: distance to corners is overestimated
#define fBoxCheap( p,  b) vmax(abs(p)-(b))

// Blobby ball object. You've probably seen it somewhere. This is not a correct distance bound, beware.
float fBlob(vec3 p) {
	p = abs(p);
	if (p.x < max(p.y, p.z)) p = p.yzx;
	if (p.x < max(p.y, p.z)) p = p.yzx;
	float b = max(max(max(
		dot(p, normalize(vec3(1, 1, 1))),
		dot(p.xz, normalize(vec2(PHI+1., 1)))),
		dot(p.yx, normalize(vec2(1, PHI)))),
		dot(p.xz, normalize(vec2(1, PHI))));
	float l = length(p);
	return l - 1.5 - 0.2 * .75* cos(min(sqrt(1.01 - b / l)*(PI / 0.25), PI));
}

// Torus in the XZ-plane
float fTorus(vec3 p, float smallRadius, float largeRadius) {
	return length(vec2(length(p.xz) - largeRadius, p.y)) - smallRadius;
}

// Cylinder standing upright on the xz plane
float fCylinder(vec3 p, float r, float height) {
	return max(length(p.xz) - r, abs(p.y) - height);
}

// Rotate around a coordinate axis (i.e. in a plane perpendicular to that axis) by angle <a>.
// Read like this: R(p.xz, a) rotates "x towards z".
// This is fast if <a> is a compile-time constant and slower (but still practical) if not.
void pR(inout vec2 p, float a) {
	p = cos(a)*p + sin(a)*vec2(p.y, -p.x);
}

// Shortcut for 45-degrees rotation
void pR45(inout vec2 p) {
	p = (p + vec2(p.y, -p.x))*sqrt(0.5);
}

// Repeat space along one axis. Use like this to repeat along the x axis:
// <float cell = pMod1(p.x,5);> - using the return value is optional.
void pMod1(inout float p, float size) {
	float halfsize = size*0.5;
	float c = floor((p + halfsize)/size);
	p = mod(p + halfsize, size) - halfsize;
}

// Repeat around the origin by a fixed angle.
// For easier use, num of repetitions is use to specify the angle.
void pModPolar(inout vec2 p, float repetitions) {
	float angle = TAO/repetitions;
	float a = atan(p.y, p.x) + angle*.5;
	a = mod(a,angle) - angle*.5;
	p = vec2(cos(a), sin(a))*length(p);
}

// Repeat in two dimensions
void pMod2(inout vec2 p, vec2 size) {
	vec2 c = floor((p + size*0.5)/size);
	p = mod(p + size*0.5,size) - size*0.5;
}

// Mirror in both dimensions and at the diagonal, yielding one eighth of the space.
// translate by dist before mirroring.
void pMirrorOctant (inout vec2 p, vec2 dist) {
    p = abs(p)-dist;
	p.xy = p.y>p.x ? p.yx : p.xy;
}

// Reflect space at a plane
void pReflect(inout vec3 p, vec3 planeNormal, float offset) {
	float t = dot(p, planeNormal)+offset;
	p -= step(0.,-t)*2.*t*planeNormal;
}

float fOpDifferenceColumns(float a, float b, float r, float n) {
	a = -a;
	float m = min(a, b);
	//avoid the expensive computation where not needed (produces discontinuity though)
	if (a < r && b < r) {
		vec2 p = vec2(a, b);
//		float columnradius = r*SQRT2/n/2.0;
//		columnradius = r*SQRT2/((n-1.)*2.+SQRT2);
		float columnradius = r*SQRT2/((n-1.)*2.+SQRT2);

		pR45(p);
		p.y += columnradius;
		p.x -= SQRT2/2.*r;
		p.x += -columnradius*SQRT2*.5;

		if (mod(n,2.) == 1.) {
			p.y += columnradius;
		}
		pMod1(p.y,columnradius*2.);

		float result = -length(p) + columnradius;
		result = max(result, p.x);
		result = min(result, a);
		return -min(result, b);
	} else {
		return -m;
	}
}

// -- END OF MERCURY STUFF ---------------------------------------------




// -- Distance functions -----------------------------------------------

// The "Stairs" flavour produces n-1 steps of a staircase:
// much less stupid version by paniq
float fOpUnionStairs(float a, float b, float r, float n) {
	float s = r/n, u = b-r;
	return min(min(a,b), .5 * (u + a + abs (mod (u - a + s, 2. * s) - s)));
}


float sdCapsule(in vec3 p, in vec3 a, in vec3 b, in float rout, in float rin) {
    vec3 pa = p - a, ba = b - a;
    float h = clamp(dot(pa,ba)/dot(ba,ba), 0., 1.);
    float d = length(pa-ba*h);  
    return max(rout-d, d-rin);
}

// iq: https://iquilezles.org/articles/distfunctions
float sdCone(vec3 p, vec2 c) {
    // c must be normalized
    return dot(c,vec2(length(p.zx),p.y));
}

float sdTorus82(in vec3 p, float r, vec2 sz) {
	return max(abs(length(p.xz) - r)-sz.x, abs(p.y) - sz.y);
}

float sdWindow(vec2 p) {
    p.x = abs(p.x)+.05; // gothique
    return min(length(p.xy)-.1, max(p.x-.1, abs(p.y+.07)-.05));
}

float sdWall(vec3 p, float h, float s) {
    float d = max(p.y-h, abs(p.z) -.05);  // Mur droit
    p.x = mod(p.x+.4,.8) -.4;
    return -fOpUnionStairs(s*sdWindow((p.xy - vec2(0., h*.8))/s), -d, .05, 2.);
}

float sdHouse(vec3 p0) {
    const float h = .7;
    vec3 p = p0;
    p.z += 1.3;
    p.x -= .4;
    p.z = abs(p.z);
    pReflect(p, vec3(-_SQRT2,0,_SQRT2),.0);
    pReflect(p, vec3(_SQRT2,0,_SQRT2),.6);

    vec3 p2 = p;
    
    p.y -= h+.58;
    float d = max( abs(p.z+.38)*.6+p.y*.5, -(p.y-.2)) -.5;  // toit
#ifdef MAP_FULL
    d = max(d, -(   max(abs(p.z+.35)*.6+(p.y+.02)*.5,-(p.y+.02)) -.5   ) );  // toit
#endif
    p.y += h+.58;
	
    pR(p2.zy, .1);
    d = min(d, max(max(p2.z-.7, .5-p.z), p.y-h*1.5));  // Mur droit
    d = max(d, -fBoxCheap(p0-vec3(-.5,.4,-.5), vec3(.18,.45,.2))); // ouverture porte
#ifdef MAP_FULL
    d = min(d, fBoxCheap(p0-vec3(-.5,.4,-.65), vec3(.18,.44,.02))); // porte
#endif    
    p.x = mod(p.x+1.,2.) -1.;
    d = max(d, -fBoxCheap(p.xy-vec2(0,h+.03), vec2(.17,.15)));  // fenetres
    return d;
}


float sdLineCreneaux(vec3 p) {
    float d =  max(abs(p.z)-.025, abs(p.y+.13)-.26); // mur du creneau
    d = min(d, max(abs(p.z+.15)-.15, abs(p.y+.11)-.05)); // chemin de ronde
    p.x = mod(p.x+.1, .2)-.1;
    d = min(d, length(p.zy-vec2(.025,-.11))-.01); // petit cylindre decoratif
    vec3 p1 = p.zyx;
    pR45(p.yz);
	d = max(d, p.z-.18); // champfrein	
	return max(d, 
        -min(fBoxCheap(p1.yz-vec2(-.25,0.), vec2(.05,.07)), // fentes du bas
        	 fBoxCheap(p1.yz-vec2(.08,0.), vec2(.1,.03)))); // fente dans les meurtrieres
}


float sdRoundCreneaux(vec3 p, float r) {
	float height = 2.6;
    
    float dc = length(p.xz)-r;
    float d = min(max(p.y-.1, max(dc, -dc-.05)),
                  max(p.y+.1, max(dc, -dc-.3)));
    d = max(d, sdCone(vec3(p.x,-r-.2-p.y,p.z), normalize(vec2(1.))));
	
    pModPolar(p.xz, r*90./3.);
    d = max(d, 
        -min(fBoxCheap(p.yz-vec2(-.25,0.), vec2(.05,.07)), // fentes du bas
        	 fBoxCheap(p.yz-vec2(.08,0.), vec2(.1,.03)))); // fente dans les meurtrieres

    d = max(-p.y-.29,d);
    
    return min(d, fTorus(p+vec3(0,.11,0), .01,r)); 
}


// [dr2] White Folly - https://www.shadertoy.com/view/ll2cDG
float sdCircleStairs (vec3 q) {
  float a = length (q.xz) > 0. ? atan (q.z,- q.x) / TAO : 0.;
  q.xz = vec2(24.* a, length(q.xz) - 6.);
  pR45(q.xy);
  float s = mod(q.x, sqrt(.5));
  return max (q.y - min(s, sqrt(.5) - s), abs(q.z-3.)-6.);
}


float sdStairs(vec3 q0) {
  q0.x *= 1.3;
  const float k = .04;
  vec3 q = q0;
  pR45(q.yx);
  float s = mod(q.x, k*sqrt (2.));
  return .5*min(fBoxCheap(q0-vec3(-1.4,1.2,0.),vec3(.2,.05,.1)),max(q0.y-1.2,max(max(q.y - min(s, k*sqrt (2.)-s), abs(q.z)-.1), -k - q.y)));
}


void malaxSpace(inout vec3 p0) {
    pReflect(p0, normalize(vec3(.8,0,.8)),2.0);
//    pReflect(p0, normalize(vec3(.3,0,.8)),2.0);
/*
  //  pReflect(p0, normalize(vec3(-.6,0,1.02)),3.5);
    pReflect(p0.zyx, normalize(vec3(-.05,0,1.)),.75);
    pReflect(p0, normalize(vec3(-.35,0,.15)),2.);
    pReflect(p0.zyx, normalize(vec3(-.4,0,.9)),3.7);
  */
       // pR45(p0.xz);
   // p0.x += 2.*cos(iTime);
  //  pMirrorOctant(p0.xz,vec2(0.,10.));
}

// Standard Ray-Marching stuff --------------------------------------------
// [Dave_Hoskins] Hash without Sine - https://www.shadertoy.com/view/4djSRW
//--------------------------------------------------------------------------
#define MOD2 vec2(3.07965, 7.4235)
#define HASHSCALE1 .1031
#define HASHSCALE3 vec3(.1031, .1030, .0973)


float hash11(float p) {
	vec3 p3  = fract(vec3(p) * HASHSCALE1);
    p3 += dot(p3, p3.yzx + 1019.19);
    return fract((p3.x + p3.y) * p3.z);
}

float hash13(vec3 p3) {
	p3  = fract(p3 * HASHSCALE1);
    p3 += dot(p3, p3.yzx + 1019.19);
    return fract((p3.x + p3.y) * p3.z);
}

vec2 hash21(float p) {
	vec3 p3 = fract(vec3(p) * HASHSCALE3);
	p3 += dot(p3, p3.yzx + 1019.19);
    return fract((p3.xx+p3.yz)*p3.zy);

}

float HashT( float p ) {
	vec2 p2 = fract(vec2(p) / MOD2);
    p2 += dot(p2.yx, p2.xy+19.19);
	return fract(p2.x * p2.y);
}

//--------------------------------------------------------------------------
// [Dave_Hoskins] Rolling hills - https://www.shadertoy.com/view/Xsf3zX
//--------------------------------------------------------------------------

float NoiseT( in vec2 x ) {
    vec2 p = floor(x), f = fract(x);
    f = f*f*(3.-2.*f);
    float n = p.x + p.y*57.0;
    return mix(mix( HashT(n     ), HashT(n+  1.),f.x),
               mix( HashT(n+ 57.), HashT(n+ 58.),f.x),f.y);
}

float Terrain( in vec2 p) {
	float w = 50., f = .0;
	for (int i = 0; i < 3; i++) {
		f += NoiseT(p)* w;
		w *= .62;
		p *= 2.5;
	}
	return f;
}

//--------------------------------------------------------------------------


float map(vec3 p0) { 
    
	float d= 999.;
    float h = Terrain(p0.xz*.3);
        
    malaxSpace(p0);
 	d = p0.y - h*mix(.002,.04, smoothstep(.1,3.,sign(p0.z)*abs(p0.x))*smoothstep(10.,MAX_DIST,length(p0.xz)));
    
    vec3 p = p0;
    float dc = length(p.xz-vec2(0,2));
    
 	// Rempart
    d = min(d, max(-min(.8-p.y, dc-6.-.3),sdCone(p-vec3(0,6.*8.4,2.), normalize(vec2(1.,.13)))));   
	d = min(d, sdRoundCreneaux(p-vec3(0,.9,2.), 6.55));
    d = min(d, sdStairs(p-vec3(1.2,-.45,8.2))); // Escaliers 
    
    vec3 p1 = p-vec3(0,0,2);
    pMirrorOctant(p1.xz, vec2(3.9)); // pour faire 4 tours d'un coups
    
    p.x = abs(p.x);
    d = min(d, max(-1.1+p1.y, sdCone(p1 - vec3(2.4,5.,-2.4), normalize(vec2(1.,.1))))); // Tour rampart
    d = max(d, -sdTorus82(p-vec3(0,.91,2.), 6.375, vec2(.08, .15))); // Porte tour rampart
    d = min(d, sdRoundCreneaux(p1-vec3(2.4,1.3,-2.4), .5));

    p.z += .05;
  
    vec3 p2 = p, ph = p;

    // Chemin de ronde
    p.z -= .1;
    pReflect(p, normalize(vec3(-1.,0,1.)),1.7);
    pReflect(p, normalize(vec3( 1.,0,1.)),1.2);

    p1 = p;
    p1.x = abs(p1.x); // Pour doubler les tours
    p1 -= vec3(1.2,0.,0.);

    // Tour du chemin de ronde
    d = min(d, max(-1.7+p1.y, sdCone(p1 - vec3(0,7.,0.), normalize(vec2(1.,.05)))));
    d = min(d, sdRoundCreneaux(p1-vec3(0,1.9,0), .35));
    d = min(d, sdWall(p-vec3(.5,0.,-.07), 1.1,1.));  // Mur droit
    d = min(d, sdLineCreneaux(p-vec3(0.,1.3,.0)));

    // Donjon
    d = min(d, sdHouse((vec3(p.x-.2,p.y,p.z+1.2)).zyx*1.6)/1.6);
    d = min(d, sdWall(p-vec3(.0,0.,-1.28),2.,1.));
    
    // Tour du donjon
    float d2 = sdLineCreneaux(p-vec3(0.,2.2,-1.2));
    d2 = min(d2, sdCapsule(p, vec3(.28,1.9,-1.3), vec3(.28,2.7,-1.3), .09, .17));

#ifdef FULL_MAP    
    d = fOpUnionStairs(d, d2, .04, 3.);
#else
    d = min(d, d2);
#endif
    d = min(d, max(-p.y+2.7,
                   min(sdCone((p-vec3(.28,3.3,-1.3)), vec2(1.,.4)),
                       sdCone((p-vec3(.28,3.6,-1.3)), vec2(1.,.22)))));
 	float dWin = sdWindow(p.xy-vec2(.28,2.45));
  
	d = -fOpUnionStairs(dWin,-d, .05,2.);

    ph.z -= .5;
	pR45(ph.zx);
    ph.z -= 4.6;
    ph.x += 1.;
 
    pReflect(ph, normalize(vec3(-1.,0,.7)),1.);
    
    d = min(d, fBlob((ph-vec3(0,1.,0))*4.)/4.); // arbre feuilles
    d = min(d, max(ph.y-1.,length(ph.xz)-.04)); // arbre tronc

    pMirrorOctant(ph.xz, vec2(1.5,1.6));

    // Petites maisons
    d = min(d, sdHouse((vec3(ph.x-.2,ph.y,ph.z+.6))*3.)/3.);
#ifdef FULL_MAP  
    d = min(d, fBoxCheap(ph-vec3(.15,0.,-.95), vec3(.05,.9,.05)));  // cheminee
#endif  
    
    d = min(d, sdStairs(p2-vec3(1.2,-.01,-.285)));    // escaliers

   // r = length(p0.yz-vec2(.4,-2.2));
   // d = min(d, max(abs(p0.x)-.2, r-.04)); 
    
    // Grande porte
    p0.x = abs(p0.x)+.1; // gothique    
 
    float dDoor = min(fCylinder(p0.xzy-vec3(0.,3.5,0.5),.2,6.), fBoxCheap(p0-vec3(0.,.35,3.5), vec3(.2,.18,6.)));

	d = max(-fBoxCheap(p-vec3(1.5,1.35,-.15), vec3(3.5,.15,.07)), d); // Porte chemin de ronde
    d = fOpUnionStairs(d, fBoxCheap(p0-vec3(0,.18,-1.35),vec3(.4,.6,.1)),.1,5.);
    d = -fOpUnionStairs(-d, fBoxCheap(p0-vec3(0,.18,-1.1),vec3(.37,.57,.1)),.02,2.);
    d = fOpDifferenceColumns(d, dDoor, .03,3.);
    d = min(d, fBoxCheap(p0-vec3(0,.185,-1.2),vec3(.38,.05,.1)));
    d = min(d,.025*sdCircleStairs(40.*(vec3(.45-p0.x,p0.y+.09,p0.z+1.1)))); // escalier circulaires de l'entree
	d = min(d, fBoxCheap(vec3(p.x,abs(p.y-1.15)-.95,p.z+1.8), vec3(10.5,.02,0.5)));

    // Puit
    float r = length(p0.xz-vec2(3.,3.1));
    d = min(d, max(p0.y-.3, r-.2)); 
	d = max(d, .14-r);

    return d;
}



vec3 castRay( in vec3 ro, in vec3 rd, in float maxd ) {
	float d = MAX_DIST;
	float lastt, t = PRECISION*10.0;
    
	// edge detection
    float lastDistEval = 1e10;
	float edge = 0.0;
    float iter = 0.;
    //float dmin = MAX_DIST; // min sur le chemin (ne compte pas l'intersection)
    
    for( int i=0; i<NB_ITER; i++ ) {
		if (d<PRECISION || t>maxd) break;
        
		d = map(ro+rd*t);       
        if (d < lastDistEval) {
            lastt = t;
            lastDistEval = d;
        } else if (d > lastDistEval + 0.00001 && lastDistEval/lastt < EDGE_WIDTH) {
			edge = 1.0;
		}
		t += d;// + t*1e-3;
       // iter++;
	}
	return vec3(t, edge, iter);
}


// -- Calculate normals -------------------------------------

vec3 calcNormal(in vec3 pos, in vec3 ray, in float t) {

	float pitch = .2 * t / iRes.x;
	pitch = max( pitch, .002 );
	
	vec2 d = vec2(-1,1) * pitch;

	vec3 p0 = pos+d.xxx, p1 = pos+d.xyy, p2 = pos+d.yxy, p3 = pos+d.yyx;
	float f0 = map(p0), f1 = map(p1), f2 = map(p2), f3 = map(p3);
	
	vec3 grad = p0*f0+p1*f1+p2*f2+p3*f3 - pos*(f0+f1+f2+f3);
	// prevent normals pointing away from camera (caused by precision errors)
	return normalize(grad - max(.0, dot (grad,ray))*ray);
}




// - Camera -------------------

#define NB 16
float[] 
    camx = float[] ( 0.,   0.,  0.,  3., 8. ,  8.,  0.,  .6,  -3.6,     1.,   1.,   3.3, .1,   0., -1.25, -2.2,-15.),
	camy = float[] ( 0.3,  0.3,7.3, 7.3, 6.3, 7.3,  .4,  .3,  .6,     1.05, 20.55,   2.,  .5, .2, .35, .37, .37),
	camz = float[] ( 40.,  6.,  4., -3., -8., -6., -.4,  4.,  5.3,     8.2,  8.75,  0.,  1.2, -.03, -.65, -2.9, -2.9),
//                    0    1   2    3    4     5    6    7     8        9     10    11    12   13  14   15   16
    lookx = float[] ( 0.,  0.,  0., -2., -2., -6.,  0.,  -2., -2.,     -4.2, -.35,  0., .08, -.0, -3., -5., -20.),
	looky = float[] ( 7.2, 1.,  2.,  0.,  0.,  0.,  .4,  .6,  .6,      1.15,  1.4,  1., .6,  .4,  .3,  .35, .35),
	lookz = float[] ( 0.,  0., -2.,  5., -2.,  -1.,  5.,  3.6, 1.5,     7.5,  .05,   -1.,-.87, -.87,-2., -3., -3.);

    
mat3 LookAt(in vec3 ro, in vec3 up){
    vec3 fw=normalize(ro),
    	 rt=normalize(cross(fw,up));
    return mat3(rt, cross(rt,fw),fw);
}

vec3 RD(in vec3 ro, in vec3 cp, vec2 uv, vec2 res) {
    return LookAt(cp-ro, vec3(0,1,0))*normalize(vec3((2.*uv-res.xy)/res.y, 3.5));
}

bool isDrawing() {  
#ifdef ALTERNATE_MODE    
	return (.2*time) < 16. && sin(time)>0.;
#else
    return (.16*time) < 16.;
#endif    
}

void getCam(in vec2 uv, in vec2 res, in float time, out vec3 ro, out vec3 rd) {
       
	vec2 q = uv/res;
    
    float t = .16* time,
		 kt = smoothstep(0.,1.,fract(t));

    // - Interpolate positions and fractal configuration ---------------------
    int  i0 = int(t)%NB, i1 = i0+1;
    
    vec3 cp = mix(vec3(lookx[i0],looky[i0],lookz[i0]), vec3(lookx[i1],looky[i1],lookz[i1]), kt); 
  
    ro = mix(vec3(camx[i0],camy[i0],camz[i0]), vec3(camx[i1],camy[i1],camz[i1]), kt),
    ro += vec3(.01*cos(2.*time), .01*cos(time),0.);
    rd = RD(ro, cp, uv, res);
}

