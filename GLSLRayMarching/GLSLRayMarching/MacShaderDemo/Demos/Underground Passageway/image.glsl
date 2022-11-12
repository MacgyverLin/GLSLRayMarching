/*

    Underground Passageway
    ----------------------

	A simple demonstration of procedural texture construction and usage. In this case, creating 
	a rocky surface, then mapping it onto a basic scene... I guess another way to put it would
	be, yet another tunnel. :)

    There's a standard technique that a lot of texture artists employ to produce rocky surfaces, 
    which involves splatting a heap of beveled looking 2D shapes onto a texture using some kind 
    of blend -- like min, max, lighten, etc. The resultant heightmap is then mapped onto the 3D 
    suface as usual. If I were to explain the process in terms the average Shadertoy user would
	understand, it'd be a more sophisticated version of Voronoi.

    The method is simple enough, but to get the rocks looking right, you need some large object 
    overlap. In theory, this is trivial -- Just check a wider spread of neighboring cells. Of 
    course, something like a 7x7 cell check with non standard shapes is not currently feasible 
	in realtime, which means the only way to benefit from the technique is to precalculate the 
	values once in one of the buffers then use the buffer block to texture the scene surface. 
	This brings with it a whole  heap of  annoyances. The worst, I feel, is having to deal with 
	texture wrapping. Everything needs to be wrapped -- warping, random values, overlays, scaling. 
	Some things are prohibitively difficult to wrap, and some won't wrap at all. There are also 
	realtime texture mapping concerns, but for basic surfaces, that's not too difficult.

	I kind of patched a lot of this together, so there'd more than likely be some repeat
	routines across the two tabs that I could place in the "common" code tab. I'll tidy it up
	a bit in due course.

	Anyway, this was just a simple proof of concept. The main point of the excercise was to show 
	that under the right circumstances, it's possible to precalculate more complex surface 
	details for realtime usage.
	

	Related examples:

	// I'm using some older code of mine, but Fabrice has already produced something along
	// these lines. I haven't had a proper look at the code, but I will when I get a chance.
	rocks (WIP) - FabriceNeyret2 
	https://www.shadertoy.com/view/ls3fzj

    // Precalculated terrain.
    Scrolling Terrain - Dr2
	https://www.shadertoy.com/view/4dlczH


	// One of my favorite simple coloring jobs.
    Skin Peeler - Dave Hoskins
    https://www.shadertoy.com/view/XtfSWX
    Based on one of my all time favorites:
    Xyptonjtroz - Nimitz
	https://www.shadertoy.com/view/4ts3z2

*/

// The far plane. I'd like this to be larger, but the extra iterations required to render the 
// additional scenery starts to slow things down on my slower machine.
#define FAR 80.

// Object identification. Usually, I like to store the individual object fields inside a vector,
// then sort them outside of the raymarching loop. They're global, because they're sometimes
// spread among various functions, and I'd rather not confuse matters by passing them from 
// function to function... and by that, I mean I'm lazy. :D
float svObjID;
vec4 vObjID, svVobjID;


// Fabrice's concise, 2D rotation formula.
//mat2 rot2(float th){ vec2 a = sin(vec2(1.5707963, 0) + th); return mat2(a, -a.y, a.x); }
// Standard 2D rotation formula - Nimitz says it's faster, so that's good enough for me. :)
mat2 rot2(in float a){ float c = cos(a), s = sin(a); return mat2(c, s, -s, c); }


// 3x1 hash function.
float hash(vec3 p){ return fract(sin(dot(p, vec3(21.71, 157.97, 113.43)))*45758.5453); }

/*
// IQ's smooth minium function. 
float smin(float a, float b , float s){
    
    float h = clamp( 0.5 + 0.5*(b-a)/s, 0. , 1.);
    return mix(b, a, h) - h*(1.0-h)*s;
}


// Smooth maximum, based on IQ's smooth minimum.
float smax(float a, float b, float s){
    
    float h = clamp( 0.5 + 0.5*(a-b)/s, 0., 1.);
    return mix(b, a, h) + h*(1.0-h)*s;
}
*/

// Commutative smooth maximum function. Provided by Tomkh, and taken 
// from Alex Evans's (aka Statix) talk: 
// http://media.lolrus.mediamolecule.com/AlexEvans_SIGGRAPH-2015.pdf
// Credited to Dave Smith @media molecule.
float smax(float a, float b, float k){
    
   float f = max(0., 1. - abs(b - a)/k);
   return max(a, b) + k*.25*f*f;
}


// Commutative smooth minimum function. Provided by Tomkh, and taken 
// from Alex Evans's (aka Statix) talk: 
// http://media.lolrus.mediamolecule.com/AlexEvans_SIGGRAPH-2015.pdf
// Credited to Dave Smith @media molecule.
float smin(float a, float b, float k){

   float f = max(0., 1. - abs(b - a)/k);
   return min(a, b) - k*.25*f*f;
}



#define RIGID
// Standard 2x2 hash algorithm.
vec2 hash22(vec2 p) {
    
    // Faster, but probaly doesn't disperse things as nicely as other methods.
    float n = sin(dot(p, vec2(113, 1)));
    p = fract(vec2(2097152, 262144)*n)*2. - 1.;
    #ifdef RIGID
    return p;
    #else
    return cos(p*6.283 + iGlobalTime);
    //return abs(fract(p+ iGlobalTime*.25)-.5)*2. - .5; // Snooker.
    //return abs(cos(p*6.283 + iGlobalTime))*.5; // Bounce.
    #endif

}


// Tri-Planar blending function. Based on an old Nvidia writeup:
// GPU Gems 3 - Ryan Geiss: https://developer.nvidia.com/gpugems/GPUGems3/gpugems3_ch01.html
vec3 tex3D(sampler2D t, in vec3 p, in vec3 n){
    
    // We only want positive normal weightings. The normal is manipulated to suit
    // your needs.
    n = max(n*n - .2, .001); // n = max(abs(n) - .1, .001), etc.
    //n /= dot(n, vec3(1)); // Rough renormalization approximation.
    n /= length(n); // Renormalizing.
    
	vec3 tx = texture(t, p.yz).xyz; // Left and right sides.
    vec3 ty = texture(t, p.zx).xyz; // Top and bottom.
    vec3 tz = texture(t, p.xy).xyz; // Front and back.
    
    // Blending the surrounding textures with the normal weightings. If the surface is facing
    // more up or down, then a larger "n.y" weighting would make sense, etc.
    //
    // Textures are stored in sRGB (I think), so you have to convert them to linear space 
    // (squaring is a rough approximation) prior to working with them... or something like that. :)
    // Once the final color value is gamma corrected, you should see correct looking colors.
    return (tx*tx*n.x + ty*ty*n.y + tz*tz*n.z);
    
}

/*
// More concise, self contained version of IQ's original 3D noise function.
float noise3D(in vec3 p){
    
    // Just some random figures, analogous to stride. You can change this, if you want.
	const vec3 s = vec3(113, 157, 1);
	
	vec3 ip = floor(p); // Unique unit cell ID.
    
    // Setting up the stride vector for randomization and interpolation, kind of. 
    // All kinds of shortcuts are taken here. Refer to IQ's original formula.
    vec4 h = vec4(0., s.yz, s.y + s.z) + dot(ip, s);
    
	p -= ip; // Cell's fractional component.
	
    // A bit of cubic smoothing, to give the noise that rounded look.
    p = p*p*(3. - 2.*p);
    
    // Standard 3D noise stuff. Retrieving 8 random scalar values for each cube corner,
    // then interpolating along X. There are countless ways to randomize, but this is
    // the way most are familar with: fract(sin(x)*largeNumber).
    h = mix(fract(sin(h)*43758.5453), fract(sin(h + s.x)*43758.5453), p.x);
	
    // Interpolating along Y.
    h.xy = mix(h.xz, h.yw, p.y);
    
    // Interpolating along Z, and returning the 3D noise value.
    return mix(h.x, h.y, p.z); // Range: [0, 1].
	
}
*/


// Gradient noise. Ken Perlin came up with it, or a version of it. Either way, this is
// based on IQ's implementation. It's a pretty simple process: Break space into squares, 
// attach random 2D vectors to each of the square's four vertices, then smoothly 
// interpolate the space between them.
float gradN2D(in vec2 f){
    
    // Used as shorthand to write things like vec3(1, 0, 1) in the short form, e.yxy. 
   const vec2 e = vec2(0, 1);
   
    // Set up the cubic grid.
    // Integer value - unique to each cube, and used as an ID to generate random vectors for the
    // cube vertiies. Note that vertices shared among the cubes have the save random vectors attributed
    // to them.
    vec2 p = floor(f);
    f -= p; // Fractional position within the cube.
    

    // Smoothing - for smooth interpolation. Use the last line see the difference.
    //vec2 w = f*f*f*(f*(f*6.-15.)+10.); // Quintic smoothing. Slower and more squarish, but derivatives are smooth too.
    vec2 w = f*f*(3. - 2.*f); // Cubic smoothing. 
    //vec2 w = f*f*f; w = ( 7. + (w - 7. ) * f ) * w; // Super smooth, but less practical.
    //vec2 w = .5 - .5*cos(f*3.14159); // Cosinusoidal smoothing.
    //vec2 w = f; // No smoothing. Gives a blocky appearance.
    
    // Smoothly interpolating between the four verticies of the square. Due to the shared vertices between
    // grid squares, the result is blending of random values throughout the 2D space. By the way, the "dot" 
    // operation makes most sense visually, but isn't the only metric possible.
    float c = mix(mix(dot(hash22(p + e.xx), f - e.xx), dot(hash22(p + e.yx), f - e.yx), w.x),
                  mix(dot(hash22(p + e.xy), f - e.xy), dot(hash22(p + e.yy), f - e.yy), w.x), w.y);
    
    // Taking the final result, and converting it to the zero to one range.
    return c*.5 + .5; // Range: [0, 1].
}


// Gradient noise fBm.
float fBm(in vec2 p){
    
    return gradN2D(p)*.57 + gradN2D(p*2.)*.28 + gradN2D(p*4.)*.15;
    
}

// Cheap and nasty 2D smooth noise function with inbuilt hash function - based on IQ's 
// original. Very trimmed down. In fact, I probably went a little overboard. I think it 
// might also degrade with large time values. I'll swap it for something more robust later.
float n2D(vec2 p) {

	vec2 i = floor(p); p -= i; 
    //p *= p*p*(p*(p*6. - 15.) + 10.);
    p *= p*(3. - p*2.);  
    
	return dot(mat2(fract(sin(vec4(0, 1, 113, 114) + dot(i, vec2(1, 113)))*43758.5453))*
                vec2(1. - p.y, p.y), vec2(1. - p.x, p.x) );

}


// Repeat gradient lines. How you produce these depends on the effect you're after. I've used a smoothed
// triangle gradient mixed with a custom smoothed gradient to effect a little sharpness. It was produced
// by trial and error. If you're not sure what it does, just call it individually, and you'll see.
float grad(float x, float offs){
    
    // Repeat triangle wave. The tau factor and ".25" factor aren't necessary, but I wanted its frequency
    // to overlap a sine function.
    x = abs(fract(x/6.283 + offs - .25) - .5)*2.;
    
    float x2 = clamp(x*x*(-1. + 2.*x), 0., 1.); // Customed smoothed, peaky triangle wave.
    //x *= x*x*(x*(x*6. - 15.) + 10.); // Extra smooth.
    x = smoothstep(0., 1., x); // Basic smoothing - Equivalent to: x*x*(3. - 2.*x).
    return mix(x, x2, .15);
    
/*    
    // Repeat sine gradient.
    float s = sin(x + 6.283*offs + 0.);
    return s*.5 + .5;
    // Sine mixed with an absolute sine wave.
    //float sa = sin((x +  6.283*offs)/2.);
    //return mix(s*.5 + .5, 1. - abs(sa), .5);
    
*/
}

// One sand function layer... which is comprised of two mixed, rotated layers of repeat gradients lines.
float sandL(vec2 p){
    
    // Layer one. 
    vec2 q = rot2(3.14159/18.)*p; // Rotate the layer, but not too much.
    q.y += (gradN2D(q*18.) - .5)*.05; // Perturb the lines to make them look wavy.
    float grad1 = grad(q.y*80., 0.); // Repeat gradient lines.
   
    q = rot2(-3.14159/20.)*p; // Rotate the layer back the other way, but not too much.
    q.y += (gradN2D(q*12.) - .5)*.05; // Perturb the lines to make them look wavy.
    float grad2 = grad(q.y*80., .5); // Repeat gradient lines.
      
    
    // Mix the two layers above with an underlying 2D function. The function you choose is up to you,
    // but it's customary to use noise functions. However, in this case, I used a transcendental 
    // combination, because I like the way it looked better.
    // 
    // I feel that rotating the underlying mixing layers adds a little variety. Although, it's not
    // completely necessary.
    q = rot2(3.14159/4.)*p;
    //float c = mix(grad1, grad2, smoothstep(.1, .9, n2D(q*vec2(8))));//smoothstep(.2, .8, n2D(q*8.))
    //float c = mix(grad1, grad2, n2D(q*vec2(6)));//smoothstep(.2, .8, n2D(q*8.))
    //float c = mix(grad1, grad2, dot(sin(q*12. - cos(q.yx*12.)), vec2(.25)) + .5);//smoothstep(.2, .8, n2D(q*8.))
    
    // The mixes above will work, but I wanted to use a subtle screen blend of grad1 and grad2.
    float a2 = dot(sin(q*12. - cos(q.yx*12.)), vec2(.25)) + .5;
    float a1 = 1. - a2;
    
    // Screen blend.
    float c = 1. - (1. - grad1*a1)*(1. - grad2*a2);
    
    // Smooth max\min
    //float c = smax(grad1*a1, grad2*a2, .5);
   
    return c;
    
    
}

// A global value to record the distance from the camera to the hit point. It's used to tone
// down the sand height values that are further away. If you don't do this, really bad
// Moire artifacts will arise. By the way, you should always avoid globals, if you can, but
// I didn't want to pass an extra variable through a bunch of different functions.
//float gT;

float sand(vec2 p){
    
    // Rotating by 45 degrees. I thought it looked a little better this way. Not sure why.
    // I've also zoomed in by a factor of 4.
    //p = vec2(p.y - p.x, p.x + p.y)*.7071/4.;
    
    p /= 6.;
    
    // Sand layer 1.
    float c1 = sandL(p);
    
    // Second layer.
    // Rotate, then increase the frequency -- The latter is optional.
    vec2 q = rot2(3.14159/12.)*p;
    float c2 = sandL(q*1.25);
    
    // Mix the two layers with some underlying gradient noise.
    c1 = mix(c1, c2, smoothstep(.1, .9, gradN2D(p*vec2(4))));
    
/*   
	// Optional screen blending of the layers. I preferred the mix method above.
    float a2 = gradN2D(p*vec2(4));
    float a1 = 1. - a2;
    
    // Screen blend.
    c1 = 1. - (1. - c1*a1)*(1. - c2*a2);
*/    
    
    // Extra grit. Not really necessary.
    //c1 = .7 + fBm(p*128.)*.3;
    
    // A surprizingly simple and efficient hack to get rid of the super annoying Moire pattern 
    // formed in the distance. Simply lessen the value when it's further away. Most people would
    // figure this out pretty quickly, but it took me far too long before it hit me. :)
    return c1;
}

/////////

/*     
float t3D(sampler2D tex, vec3 p, vec3 n) {
    float ta = texture(tex, p.yz).a;
    float tb = texture(tex, p.xz).a;
    float tc = texture(tex, p.xy).a;
    return(ta + tb + tc) / 3.;
}
*/


// The path is a 2D sinusoid that varies over time, which depends upon the frequencies and amplitudes.
vec2 path(in float z){ 
    
    return vec2(4.*sin(z * .1), cos(z * .1));
}



// Crosss sectional distance. It can be cylindrical, square, hexagonal, octagonal, etc.
float polDist(vec2 p){
    
    
	// Standard circular length.
    return length(p);
    
    // More options, but since we're using cylindrical mapping, a lot wouldn't 
    // really work, unless you rewrote the texture mapping to match.
    
    
    // A hacky arch-like variation.
    //return mix(length(p), min(length(p), max(abs(p.x), abs(p.y + 2.5 - .5) + 1.)), .5);

    // Square cross section.
    //p = abs(p);
    //return max(p.x, p.y);
    
    // Hexagonal cross section.
    //p = abs(p);
    //return max(p.x*.8660254 + p.y*.5, p.y);

    // Octagonal cross section.
    //p = abs(p);
    //return max(max(p.x, p.y), (p.x + p.y)*.7071);
    
    
    // Dodecahedral cross section.
    //p = abs(p);
    //vec2 p2 = p.xy*.8660254 + p.yx*.5;
    //return max(max(p2.x, p2.y), max(p.y, p.x)); 
    
    
    //const float pwr = 4.;
    //return pow( dot(pow(abs(p), vec2(pwr)), vec2(1)), 1./pwr);

    
}


// Crosss sectional distance. It can be cylindrical,
// square, hexagonal, octagonal, etc.
float dist(vec2 p){
    
    

    //return length(p);
    
    // Square cross section.
    //p = abs(p);
    //return max(p.x, p.y);
    
    // Hexagonal cross section.
    //p = abs(p);
    //return max(p.x*.8660254 + p.y*.5, p.y);

    // Octagonal cross section.
    p = abs(p);
    return max(max(p.x, p.y), (p.x + p.y)*.7071);
    
    
    // Dodecahedral cross section.
    //p = abs(p);
    //vec2 p2 = p.xy*.8660254 + p.yx*.5;
    //return max(max(p2.x, p2.y), max(p.y, p.x)); 
    
    //const float pwr = 4.;
    //return pow( dot(pow(abs(p), vec2(pwr)), vec2(1)), 1./pwr);

    
}



vec4 getCylTex(vec3 p){
    
    vec2 uv = vec2(atan(p.y, p.x)/6.2831, p.z);
    return texture(iChannel0, uv*vec2(1., 1./16.));
}



// The tunnel scene. In essence, it's a texture mapped cylinder wrapped around a path, 
// with a floor and some repetive overhead XZ cylinder-like shapes. Nothing complicatied.
float map(vec3 p){
    
    // Perturbing the walls with a sinusoidal function just a bit to give the tunnel a 
    // less man made feel.
    vec3 pert = p*vec3(1, 1, .5);
    pert = sin(pert - cos(pert.yzx*2.))*.25;
    
    //float id = floor(p.z/16.)*16. + 8.;
    //vec3 pos = vec3(path(id), id);
    //vec3 q = p - pos;
     
    // Wrapping the tunnel, vents and floor around the path.
    p.xy -= path(p.z).xy;
    
    // The ground. Nothing fancy. 
    float ground = p.y + 2.375 + pert.y*.125;
    
    
    // A pretty hacky vent shaft object. I'll rewrite this in a better way at some
    // stage, so I wouldn't pay too much attention to it.
    vec3 q = p;
    // Repeting the shafts every 16 units.
    q.z = mod(q.z + 0., 16.) - 8.; // (q.z/16. - floor(q.z/16.))*16. - 8.;
    

    // The shaft cross section. I decided to make them octagonal, for whatever reason, 
    // but it's not mandatory.
    float sCirc = dist(q.xz) - 1.15;
   
    // The ventilation shaft.
    float shafts = max(abs(sCirc) - .1, abs(q.y - (4.6)) - 2.);
    
    // The rim under the vent.
    float rim = dist(vec2(sCirc, q.y - 2.6)) - .15; 
    
    shafts = min(shafts, rim);
    
    
    // Shaft holes. The end bit is needed to stop the shaft holes from continuing
    // through the floor.
    float shaftHoles = max(min(sCirc - .05, rim - .1), -p.y);
    //shaftHoles = smin(shaftHoles, rim, 1.);
    
 
    // Subdividing space into smaller lots to create the vent grids. I probably should
    // had created these separately in order to set unique materials, but I've attached 
    // them to the vent object.
    q.xz = mod(q.xz, .25) - .25/2.;
    q.y -= 3. - .25;
    float ventGrid = length(q.xy) - .035;//min(length(q.yz), length(q.xy)) - .05;
    ventGrid = max(ventGrid, sCirc);
    //shafts = min(shafts, ventGrid);
    
    // Cylindrically mapping the rocky texture onto the walls of the cylinder. The 
    // cylinder has been warped here and then, so it's not an exact fit, but no one
    // will notice.
    float sf = getCylTex(p).a;
    
    // Arrange for the rocky base to effect the sand level ever so slightly.
    ground += (.5 - sf)*.25;

    p.xy *= vec2(.9, 1); // Widen the tunnel just a bit.
    // Add the sinusoidal perturbations to the tunnel via some space warping. You could
    // also do this in height map form, but I chose this way... for some reason that
    // escapes me at present. :)
    p += pert; 
   
    // The tunnel object -- otherwise known as a glorified cylinder. We're approaching
    // the cylinder walls from the inside. Hence, the negative sign.
    float tun =  -(polDist(p.xy) - 2.7);
    
    // There a light sitting about the vents outside the tunnel, so I've given the
    // tunnel a bit of thickness. That's all this is 
    tun = max(tun + (.5-sf)*1., -(tun + 4.));
    // Creating some holes in the tunnel roof for the vents to fit into. A smooth blend
    // is used to smoothen the rocks around the grated end of the vent.
    tun = smax(tun, -shaftHoles, .5);
     
    
    // Save the IDs. For speed, they're sorted outside the loop.
    vObjID = vec4(tun, shafts, ground, ventGrid);
    
    float df = min(min(tun, ventGrid), min(shafts, ground));
    

    // Return the distance -- Actually, a fraction of the distance, since a lot of 
    // this isn't Lipschitz friendly, for want of a better term. :)
    return df*.86;
 
}



// Basic raymarcher.
float trace(in vec3 ro, in vec3 rd){

    float t = 0., h;
    //gT = t;
    
    for(int i=0; i<128; i++){
    
        h = map(ro + rd*t);
        // Note the "t*b + a" addition. Basically, we're putting less emphasis on accuracy, as
        // "t" increases. It's a cheap trick that works in most situations... Not all, though.
        if(abs(h)<0.001*(t*.125 + 1.) || t>FAR) break; // Alternative: 0.001*max(t*.25, 1.), etc.
        
        t += h; 
        //gT = t;
    }

    return min(t, FAR);
}

/*
// Tetrahedral normal - courtesy of IQ. I'm in saving mode, so the two "map" calls saved make
// a difference. Also because of the random nature of the scene, the tetrahedral normal has the 
// same aesthetic effect as the regular - but more expensive - one, so it's an easy decision.
vec3 normal(in vec3 p)
{  
    vec2 e = vec2(-1., 1.)*0.001;   
	return normalize(e.yxx*map(p + e.yxx) + e.xxy*map(p + e.xxy) + 
					 e.xyx*map(p + e.xyx) + e.yyy*map(p + e.yyy) );   
}
*/

 
// Standard normal function. It's not as fast as the tetrahedral calculation, but more symmetrical.
vec3 normal(in vec3 p, float ef) {
	vec2 e = vec2(0.001*ef, 0);
	return normalize(vec3(map(p + e.xyy) - map(p - e.xyy), map(p + e.yxy) - map(p - e.yxy),	map(p + e.yyx) - map(p - e.yyx)));
}


// Compact, self-contained version of IQ's 3D value noise function. I have a transparent noise
// example that explains it, if you require it.
float n3D(in vec3 p){
    
	const vec3 s = vec3(113, 157, 1);
	vec3 ip = floor(p); p -= ip; 
    vec4 h = vec4(0., s.yz, s.y + s.z) + dot(ip, s);
    p = p*p*(3. - 2.*p); //p *= p*p*(p*(p * 6. - 15.) + 10.);
    h = mix(fract(sin(h)*43758.5453), fract(sin(h + s.x)*43758.5453), p.x);
    h.xy = mix(h.xz, h.yw, p.y);
    return mix(h.x, h.y, p.z); // Range: [0, 1].
}


// 3D noise fBm.
float fBm(in vec3 p){
    
    return n3D(p)*.57 + n3D(p*2.)*.28 + n3D(p*4.)*.15;
    
}

// Surface bump function..
float bumpSurf3D(in vec3 p, in vec3 n){
/*    
    // Obtaining some terrain samples in order to produce a gradient
    // with which to distort the sand. Basically, it'll make it look
    // like the underlying terrain it effecting the sand. The downside
    // is the three extra taps per bump tap... Ouch. :) Actually, it's
    // not that bad, but I might attempt to come up with a better way.
    float n = surfFunc(p);
    vec3 px = p + vec3(.001, 0, 0);
    float nx = surfFunc(px);
    vec3 pz = p + vec3(0, 0, .001);
    float nz = surfFunc(pz);
    
    // The wavy sand, that have been perturbed by the underlying terrain.
    return sand(p.xz + vec2(n - nx, n - nz)/.001*1.);
*/
    
    //float sf2 = t3D2(iChannel1, p/4., n);
    //return min(sf2/.66, 1.);
    
    float res = 0.;
    
    vec3 tSp = p;
    tSp.xy -= path(tSp.z).xy;
    
    if(svObjID == 0.){
        
        vec4 tx4 = getCylTex(tSp*3.);
        res = tx4.a;
    }
    else if(svObjID == 2.){
        //res = sand(tSp.xz);
        //vec4 tx4 = mix(texture(iChannel0, tSp.xz/8.), 1. - texture(iChannel0, tSp.xz/3.), .5);
        vec4 tx4 = texture(iChannel0, tSp.xz/4.);

        res = tx4.a;
        //res *= sand(tSp.xz);
    }
    
    return res;

}

// Standard function-based bump mapping routine: This is the cheaper four tap version. There's
// a six tap version (samples taken from either side of each axis), but this works well enough.
vec3 doBumpMap(in vec3 p, in vec3 nor, float bumpfactor){
    
    // Larger sample distances give a less defined bump, but can sometimes lessen the aliasing.
    const vec2 e = vec2(.001, 0); 
    
    // Gradient vector: vec3(df/dx, df/dy, df/dz);
    float ref = bumpSurf3D(p, nor);
    vec3 grad = (vec3(bumpSurf3D(p - e.xyy, nor),
                      bumpSurf3D(p - e.yxy, nor),
                      bumpSurf3D(p - e.yyx, nor)) - ref)/e.x; 
    
    /*
    // Six tap version, for comparisson. No discernible visual difference, in a lot of cases.
    vec3 grad = vec3(bumpSurf3D(p - e.xyy) - bumpSurf3D(p + e.xyy),
                     bumpSurf3D(p - e.yxy) - bumpSurf3D(p + e.yxy),
                     bumpSurf3D(p - e.yyx) - bumpSurf3D(p + e.yyx))/e.x*.5;
    */
       
    // Adjusting the tangent vector so that it's perpendicular to the normal. It's some kind 
    // of orthogonal space fix using the Gram-Schmidt process, or something to that effect.
    grad -= nor*dot(nor, grad);          
         
    // Applying the gradient vector to the normal. Larger bump factors make things more bumpy.
    return normalize(nor + grad*bumpfactor);
	
}

// Texture bump mapping. Four tri-planar lookups, or 12 texture lookups in total. I tried to 
// make it as concise as possible. Whether that translates to speed, or not, I couldn't say.
vec3 doBumpMap(sampler2D tx, in vec3 p, in vec3 n, float bf){
   
    const vec2 e = vec2(0.001, 0);
    
    // Three gradient vectors rolled into a matrix, constructed with offset greyscale texture values.    
    mat3 m = mat3( tex3D(tx, p - e.xyy, n), tex3D(tx, p - e.yxy, n), tex3D(tx, p - e.yyx, n));
    
    vec3 g = vec3(0.299, 0.587, 0.114)*m; // Converting to greyscale.
    g = (g - dot(tex3D(tx,  p , n), vec3(0.299, 0.587, 0.114)) )/e.x; g -= n*dot(n, g);
                      
    return normalize( n + g*bf ); // Bumped normal. "bf" - bump factor.
    
}

// Cheap shadows are the bain of my raymarching existence, since trying to alleviate artifacts is an excercise in
// futility. In fact, I'd almost say, shadowing - in a setting like this - with limited  iterations is impossible... 
// However, I'd be very grateful if someone could prove me wrong. :)
float softShadow(vec3 ro, vec3 lp, float k, float t){

    // More would be nicer. More is always nicer, but not really affordable.
    const int maxIterationsShad = 32; 
    
    vec3 rd = lp - ro; // Unnormalized direction ray.

    float shade = 1.;
    float dist = 0.001*(t*.125 + 1.);  // Coincides with the hit condition in the "trace" function.  
    float end = max(length(rd), 0.0001);
    //float stepDist = end/float(maxIterationsShad);
    rd /= end;

    // Max shadow iterations - More iterations make nicer shadows, but slow things down. Obviously, the lowest 
    // number to give a decent shadow is the best one to choose. 
    for (int i=0; i<maxIterationsShad; i++){

         
        float h = map(ro + rd*dist);
        shade = min(shade, k*h/dist);
        //shade = min(shade, smoothstep(0.0, 1.0, k*h/dist)); // Subtle difference. Thanks to IQ for this tidbit.
        // So many options here, and none are perfect: dist += min(h, .2), dist += clamp(h, .01, stepDist), etc.
        //h = clamp(h, .1, 1.); // max(h, .02);//
        h = max(h, .1);
        dist += h;

        
        // Early exits from accumulative distance function calls tend to be a good thing.
        if (shade<0.001 || dist > end) break; 
    }

    // I've added a constant to the final shade value, which lightens the shadow a bit. It's a preference thing. 
    // Really dark shadows look too brutal to me. Sometimes, I'll add AO also, just for kicks. :)
    return min(max(shade, 0.) + .05, 1.); 
}



// I keep a collection of occlusion routines... OK, that sounded really nerdy. :)
// Anyway, I like this one. I'm assuming it's based on IQ's original.
float calcAO(in vec3 p, in vec3 n)
{
	float ao = 0., l;
    const float maxDist = 2.;
	const float nbIte = 5.;
	//const float falloff = .9;
    for( float i=1.; i< nbIte+.5; i++ ){
    
        l = (i + .0)*.5/nbIte*maxDist;        
        ao += (l - map( p + n*l )); // / pow(1.+l, falloff);
    }
	
    return clamp(1.- ao/nbIte, 0., 1.);
}



// Fog color. Made up. I wanted a little bit of gradential color change.
vec3 getFogCol(vec3 rd){ 
     
    // Mix the gradients using the Y value of the unit direction ray. 
    return mix(vec3(.672, .7, .585), vec3(.336, .6, 1.053), pow(max(rd.y*.5 + .2, 0.), .5));

}



// Slight modified version of Nimitz's curve function. The tetrahedral and normal six
// tap versions are in there. If four taps gives you what you want, then that'd be the
// one to use.
//
// I think it's based on a discrete finite difference approximation to the continuous
// Laplace differential operator? Either way, it gives you the curvature of a surface, 
// which is pretty handy. I used it to do a bit of fake shadowing.
//
// Original usage (I think?) - Cheap curvature: https://www.shadertoy.com/view/Xts3WM
// Other usage: Xyptonjtroz: https://www.shadertoy.com/view/4ts3z2
//
// spr: sample spread, amp: amplitude, offs: offset.
float curve(in vec3 p, in float spr, in float amp, in float offs){

    float d = map(p);
    
    #if 1
    // Tetrahedral.
    vec2 e = vec2(-spr, spr); // Example: ef = .25;
    float d1 = map(p + e.yxx), d2 = map(p + e.xxy);
    float d3 = map(p + e.xyx), d4 = map(p + e.yyy);
    return max((d1 + d2 + d3 + d4 - d*4.)/e.y/2.*amp + offs + .5, 0.);
    #else  
    // Cubic.
    vec2 e = vec2(spr, 0); // Example: ef = .5;
	float d1 = map(p + e.xyy), d2 = map(p - e.xyy);
	float d3 = map(p + e.yxy), d4 = map(p - e.yxy);
	float d5 = map(p + e.yyx), d6 = map(p - e.yyx);
    return max((d1 + d2 + d3 + d4 + d5 + d6 - d*6.)/e.x/2.*amp + offs + .5, 0.);
    #endif

}


void mainImage( out vec4 fragColor, in vec2 fragCoord ){	


	
	// Screen coordinates.
	vec2 u = (fragCoord - iResolution.xy*.5)/iResolution.y;
	
	// Camera Setup.     
	vec3 ro = vec3(0, 0, iTime*4.); // Camera position, doubling as the ray origin.
    vec3 lookAt = ro + vec3(0, 0, .5);  // "Look At" position.
    
    vec3 lp = ro + vec3(0, 64, 6);
    
	
	// Using the Z-value to perturb the XY-plane.
	// Sending the camera and "look at" vectors down the tunnel. The "path" function is 
	// synchronized with the distance function.
	ro.xy += path(ro.z);
	lookAt.xy += path(lookAt.z);
	lp.xy += path(lp.z);

    
    //float lz = floor((lp.z + 4.)/8.)*8. + 4.;
    //lz = lz + mod(lz, 8.);
    //lp = vec3(lp.xy, lz);
     
 
    // Using the above to produce the unit ray-direction vector.
    float FOV = 3.14159265/2.5; // FOV - Field of view.
    vec3 forward = normalize(lookAt - ro);
    vec3 right = normalize(vec3(forward.z, 0, -forward.x )); 
    vec3 up = cross(forward, right);

    // rd - Ray direction.
    vec3 rd = normalize(forward + FOV*u.x*right + FOV*u.y*up);
    
    // Swiveling the camera about the XY-plane (from left to right) when turning corners.
    // Naturally, it's synchronized with the path in some kind of way.
	rd.xy = rot2( path(lookAt.z).x/96.)*rd.xy;
    
    // Subtle up and down tilt, or camera pitch, if you prefer.
    //rd.yz = rot2(-slope/3.)*rd.yz;
	
    // Usually, you'd just make this a unit directional light, and be done with it, but I
    // like some of the angular subtleties of point lights, so this is a point light a
    // long distance away. Fake, and probably not advisable, but no one will notice.
    //vec3 lp = vec3(FAR*.25, FAR*.35, FAR) + vec3(0, 0, ro.z);
 

	// Raymarching.
    float t = trace(ro, rd);
    
    //gT = t;
    //svObjID = objID; // Save the object ID.
    svVobjID = vObjID;
    
    svObjID = svVobjID.x<svVobjID.y && svVobjID.x<svVobjID.z  && svVobjID.x<svVobjID.w? 
        	  0. : svVobjID.y<svVobjID.z &&  svVobjID.y<svVobjID.w? 
              1.: svVobjID.z<svVobjID.w? 2. : 3.;
    
   
    // Sky. Only retrieving a single color this time.
    //vec3 sky = getSky(rd);
    
    // The passage color. Can't remember why I set it to sky. I'm sure I had my reasons.
    vec3 col = vec3(0);
    
    // Surface point. "t" is clamped to the maximum distance, and I'm reusing it to render
    // the mist, so that's why it's declared in an untidy postion outside the block below...
    // It seemed like a good idea at the time. :)
    vec3 sp = ro+t*rd; 
    
    float pathHeight = sp.y;//surfFunc(sp);// - path(sp.z).y; // Path height line, of sorts.
    
    // If we've hit the ground, color it up.
    if (t < FAR){
    
        
        vec3 sn = normal(sp, 1.); // Surface normal. //*(1. + t*.125)
        
        // Light direction vector. From the sun to the surface point. We're not performing
        // light distance attenuation, since it'll probably have minimal effect.
        vec3 ld = lp - sp;
        float lDist = max(length(ld), 0.001);
        ld /= lDist; // Normalize the light direct vector.
        
        //lDist /= FAR; // Scaling down the distance to something workable for calculations.
        lDist /= 16.;
        float atten = 1./(1. + lDist*lDist*.025);
        
        
        
        // Function based bump mapping.
        sn = doBumpMap(sp, sn, .15);///(1. + t*t/FAR/FAR*.25)
        
        // Texture bump mapping.
        //
        // Texture scale factor.        
        float tSize = 1./1.;
        if(svObjID == 1.) tSize = 2.;
        vec3 tSp = sp;
        tSp.xy -= path(tSp.z).xy;
        
        float bf = .05;
        if(svObjID == 1. || svObjID == 3.) bf = .01;
        sn = doBumpMap(iChannel1, tSp*tSize, sn, bf);
        // Getting picky, and hacky. With no anisotropic filtering, I need a finer grad of
        // texture bumping on the rocks, but a wider coloring spread... It's not important. :)
        if(svObjID == 0.) tSize /= 2.;
        
        
        // Soft shadows and occlusion.
        float sh = softShadow(sp + sn*.002, lp, 8., t); 
        float ao = calcAO(sp, sn); // Ambient occlusion.
        
        // Using the curvature to darken the rock crevices a little more. It also has the effect of
        // lightening the sharp convex edges a bit. Not sure if that's a geological thing, but I noticed
        // that texture artists are fond of the look.
        // spr: sample spread, amp: amplitude, offs: offset.
		float spr = .3, amp = .4, offs = .5;
        float crv = curve(sp, spr, amp, offs)*.75 + .25;
        //float crv = curve(sp, spr, amp, offs);
        //crv = crv*.75 + smoothstep(1., 1.5, crv)*.5 + .125;
        
        
        
        // Add AO to the shadow. No science, but adding AO to things sometimes gives a bounced light look.
        sh = min(sh + ao*.15, 1.); 
        
        float dif = max( dot( ld, sn ), 0.0); // Diffuse term.
        float spe = pow(max( dot( reflect(-ld, sn), -rd ), 0.0 ), 5.); // Specular term.
        float fre = clamp(1.0 + dot(rd, sn), 0.0, 1.0); // Fresnel reflection term.
 
        // Schlick approximation. I use it to tone down the specular term. It's pretty subtle,
        // so could almost be aproximated by a constant, but I prefer it. Here, it's being
        // used to give a sandstone consistency... It "kind of" works.
		float Schlick = pow( 1. - max(dot(rd, normalize(rd + ld)), 0.), 5.0);
		float fre2 = mix(.2, 1., Schlick);  //F0 = .2 - Hard clay... or close enough.
       
        // Overal global ambience. It's made up, but I figured a little occlusion (less ambient light
        // in the corners, etc) and reflectance would be in amongst it... Sounds good, anyway. :)
        float amb = ao*.35;// + fre*fre2*.2;
        

        
        // COLORING AND TEXTURING.
        //
        // Starting with a bit of sandstone.
        col = mix(vec3(1, .95, .7), vec3(.9, .6, .4), fBm(sp.xz*16.));
        col = mix(col*1.4, col*.6, fBm(sp.xz*32. - .5));///(1. + t*t*.001)
        
        
        if(svObjID==0.){
            
            // A little extra rock shading.
            col = vec3(1);
            col *= mix(1./vec3(1, .875, .7875), vec3(1, .875, .7875)*1.2, crv);

            //crv = crv*.75 + .5;
            // Cheaper version of curvature.
            //vec4 tx4 = getCylTex(tSp);
            //col *= max(tx4.a/.66*1.35 - .1, 0.); // smoothstep(.0, .8, tx4.a);
         }
        
        

        // I couldn't be bothered going through the trouble to make a detailed texture like the
        // one below, so I used the one you see below. 
        vec3 tx = tex3D(iChannel1, tSp*tSize, sn);
        if(svObjID!=2.) col *= smoothstep(-.1, .7, tx)*2.;
        
        // Concreat shaft.
        // I couldn't decide whether the shaft vents were going to be concrete or metallic,
        // but concrete probably make more sense.
        if(svObjID==1.) {
             
             col = mix(col, vec3(1)*dot(col, vec3(.299, .587, .114)), .7)*vec3(1, 1.2, 1.3)*1.6;
        }
        
        // Metal grids accross the concrete shafts -- to adhere to health and safety regulations. :)
        if(svObjID==3.){
            col = mix(col, vec3(1)*dot(col, vec3(.299, .587, .114)), .7)*vec3(1, 1.2, 1.3);
            //dif *= pow(dif, 4.)*2.;
        }
        
        // I think every person with an interest in computer graphics is a bit of a perfectionist
        // at heart. Seeing the sharp geometric line between the sand and the rocks was irritating
        // me to the point where I had to do something about it... Hence, this mess. :D
        //
        // Anyway, the trick is to identify an isolinear region where two objects overlap, then 
        // blend the values. That means you're doubling up on calculations here and there, but not 
        // for too many pixels, so it shouldn't matter.
        if(svObjID==0. || svObjID==2.){ // Probably not necessary... Call it paranoia. :D
            
                
            // If the object is sand, or it's close to the rock, blend the sand
            // into the rock.
            if(abs(svVobjID.x - svVobjID.z)<.1 || svObjID == 2.){
                
                // Sand: svObjID = 2.
                float bmp = sand(tSp.xz)/(1. + t*t*.015);
                bmp = mix(bmp, bumpSurf3D(sp, sn), .35);
                vec3 col2 = mix(vec3(1, .95, .7), vec3(.9, .6, .4), fBm(tSp.xz*16.));
                col2 = mix(col2*1.4, col*.6, fBm(tSp.xz*32. - .5))*2./vec3(1, .85, .7);
                col2 = mix(col2 + (hash(floor(tSp*96.))*.7 + hash(floor(tSp*192.))*.3)*.3, col, min(t*t/FAR, 1.));
                col2 = mix(col2, vec3(1.5), .5);
                col2 *= bmp*.85 + .3;
                col2 *= vec3(1, .875, .7875);
            
                // Rocky walls: svObjID = 0.;
                vec3 col0 = col;
            
                col = mix(col2, col0, smoothstep(0., .1, svVobjID.z - svVobjID.x));
            }
                
           
        }
        
        
        
        // The scene looked a little too bleak, so I've artificially warmed everything up. :)
        // Comment it out, and you'll notice the difference.
        //col *= mix(1./vec3(1, .875, .7875), vec3(1, .875, .7875)*1.2, crv);
        //col *= vec3(1, .875, .7875);

        
        // Combining all the terms from above. Some diffuse, some specular - both of which are
        // shadowed and occluded - plus some global ambience. Not entirely correct, but it's
        // good enough for the purposes of this demonstation.        
        col = col*(dif + amb + vec3(1, .97, .92)*spe*fre2*2.)*atten;
        
        
        // SPOT LIGHTS.
        //
        // More fake lighting. This was just a bit of trial-and-error to produce some repetitive,
        // overhead spotlights eminating from the vent shafts. I came up with it in a hurry, so 
        // there'd no doubt be better ways to go about it, but for just a few lines, it's cheap
        // and gets the point across.
        //
        // In practical terms they're XZ 
        // cylinders repeated every 16 units. I tried to use a basis vector to tilt them in
        // the direction of the sunlight emanating from the vents, but wasn't happy with the result... 
        // I was probably doing it wrong. Either way, this works well enough.
        //
        // Cone-shaped sunlight eminating from the each vent... or something like that. :)
        vec3 nTSp = vec3(tSp.xy, mod(tSp.z + 0., 16.) - 8.);
        float spot = max(.5*max(-nTSp.y*.5 + 6., 0.) - length(nTSp.xz), 0.);
        spot *= fBm(tSp*2. + iTime)*.5 + .75;
        col = col*(.65 + spot); // + spot*spot*.25     
        
        if(svObjID == 1.){
            // Lighting the inside of the vent. In theory, that's where the lights supposed
            // to be coming from, but the natural setup isn't making it look that way, so
            // this is a fudge... One of many downsides to fake physics is the fake physics
            // domino effect. You have to add extra hacks to counter previous hacks, and so on. :)
        	col += spot*col*smoothstep(0., .25, tSp.y - 2.55);
        }

 
        // Applying the shadows, ambient occlusion and faux curvature shading.
        col *= sh*ao*crv;

    }
    
  
    // Combine the scene with a gradient fog color.
    vec3 sky = getFogCol(rd);
    //col = mix(col, sky, min(t*t*1.5/FAR/FAR, 1.)); // Quadratic fade off. More subtle.
    col = mix(col, sky, smoothstep(0., .95, t/FAR)); // Linear fade. Much dustier. I kind of like it.
    
    
    // Kind of interesting, but probably a little too much.    
    //col *= vec3(1.15, 1.025, .95);


    
    // Standard way to do a square vignette. Note that the maxium value value occurs at "pow(0.5, 4.) = 1./16," 
    // so you multiply by 16 to give it a zero to one range. This one has been toned down with a power
    // term to give it more subtlety.
    //u = fragCoord/iResolution.xy;
    //col = min(col, 1.)*pow( 16.*u.x*u.y*(1. - u.x)*(1. - u.y) , .0625);
 
    // Done.
	fragColor = vec4(sqrt(clamp(col, 0., 1.)), 1);
}