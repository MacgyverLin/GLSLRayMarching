/*

	Abandoned Construction
	----------------------

	Have you ever wondered what a herringbone tiling of 3 by 2 rectangles would look like
	in extruded heightmap form? Neither have I, but I began coding a brick pattern on a 
	2D plane, and this is where I ended up. :D

    A lot of repetitive tiling examples utilize a square grid. I prefer them for the
	obvious reason that they're simpler to use. Of course, a lot of interesting scenes 
	require triangles and hexagons, so on occasion, I'll make use of those too. Like 
	everyone else, these single regular polygons are the ones I stick to. However, there 
	are countless other tiling arrangements that remain underutilized, like this one.

	As previously mentioned, this is based on a herringbone arrangement and consists of a 
    single 3 by 2 rectangle. I like this particular arrangement and tile size because it 
	has a kind of ordered randomness feel to it that more common sizes -- like 2 by 1 -- 
	lack. The downside is the added complexity due to the fact that grid skewing and 
	unskewing is required to minimize the number of taps (four, all up, which is pretty
	good) needed to cover the plane. I can't speak for everyone else, but I get a little
	confused with logic that doesn't stay in a straight line. :)

	In regard to the code, it's all been patched together from my other examples. It's 
	reasonably efficient, but probably not organized as much as I'd like. I've employed
	a lot of standard prioritization techniques, like raymarching the main objects and
	adding smaller details via bump mapping, etc. I've also used cheaper functions where
	possible. By the way, I have a 2D example featuring the same herringbone pattern that 
	I'll put up later, which will be a little easier to decipher.

	Whenever putting something relatively simple, like this, together, I always appreciate 
	the amount of work that goes into virtually all of Dr2's examples. I have a couple of 
	interesting 3D examples coming up, but for now, I'm going back to simpler 2D stuff. :)
    
	


	Related examples:

	// This was the only herringbone pattern example I could find on Shadertoy, and from
	// what I can see, Fabrice has covered Nx1 (Whole integer multiples), which don't 
    // require skewing. I have an extruded example that cover this range and half integer
    // multiples as well, but I need to think of an interesting scene first. Perhaps,
	// I'll leave that to Fabrice. :)
	Herringbone pattern - FabriceNeyret2 
    https://www.shadertoy.com/view/4dVyDw

	// One of my favorite simple coloring jobs.
    Skin Peeler - Dave Hoskins
    https://www.shadertoy.com/view/XtfSWX
    Based on one of my all time favorites:
    Xyptonjtroz - Nimitz
	https://www.shadertoy.com/view/4ts3z2

*/

// Cheap, and very lazy, night time postprocessing. Kind of effective though. :)
//#define NIGHT

// The far plane. I'd like this to be larger, but the extra iterations required to render the 
// additional scenery starts to slow things down on my slower machine.
#define FAR 60.


// Fabrice's concise, 2D rotation formula.
//mat2 rot2(float th){ vec2 a = sin(vec2(1.5707963, 0) + th); return mat2(a, -a.y, a.x); }
// Standard 2D rotation formula - Nimitz says it's faster, so that's good enough for me. :)
mat2 rot2(in float a){ float c = cos(a), s = sin(a); return mat2(c, s, -s, c); }


// 3x1 hash function.
float hash( vec3 p ){ return fract(sin(dot(p, vec3(21.71, 157.97, 113.43)))*45758.5453); }


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


// Tri-Planar blending function. Based on an old Nvidia tutorial by Ryan Geiss.
vec3 tex3D( sampler2D t, in vec3 p, in vec3 n ){ 
    
    n = max(abs(n) - .2, 0.001); // max(abs(n), 0.001), etc.
    n /= dot(n, vec3(1));
	vec3 tx = texture(t, p.yz).xyz;
    vec3 ty = texture(t, p.zx).xyz;
    vec3 tz = texture(t, p.xy).xyz;
    
    // Textures are stored in sRGB (I think), so you have to convert them to linear space 
    // (squaring is a rough approximation) prior to working with them... or something like that. :)
    // Once the final color value is gamma corrected, you should see correct looking colors.
    return (tx*tx*n.x + ty*ty*n.y + tz*tz*n.z);
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


// Like above, but with no smoothing. Uses for the extruded brick height, so the smoothing
// isn't noticeable, so we may as well cut the line out and save the GPU some work.
float n2DS(vec2 p) {

	vec2 i = floor(p); p -= i; 
    //p *= p*p*(p*(p*6. - 15.) + 10.);
    //p *= p*(3. - p*2.);  
    
	return dot(mat2(fract(sin(vec4(0, 1, 113, 114) + dot(i, vec2(1, 113)))*43758.5453))*
                vec2(1. - p.y, p.y), vec2(1. - p.x, p.x) );

}

// The path is a 2D sinusoid that varies over time, which depends upon the frequencies and amplitudes.
vec2 path(in float z){ 
    
    return vec2(6.*sin(z * .1), 0);
}

// A very cheap surface function. Used for the underlying sand surface.
float surfFunc( in vec3 p){
    
    // More expensive, but not noticeable enough to use.
    //p /= 3.;
    //return n2D(p.xz)*.57 + n2D(p.xz*2.)*.28 + n2D(p.xz*4.)*.15;
    
    // Just two layers.
    p /= 2.5;
    return n2D(p.xz)*.67 + n2D(p.xz*2.)*.33;
    

}

// vec2 to vec2 hash.
vec2 hash22B(vec2 p) { 

    // Faster, but doesn't disperse things quite as nicely. However, when framerate
    // is an issue, and it often is, this is a good one to use. Basically, it's a tweaked 
    // amalgamation I put together, based on a couple of other random algorithms I've 
    // seen around... so use it with caution, because I make a tonne of mistakes. :)
    float n = sin(dot(p, vec2(27, 57)));
    return fract(vec2(262144, 32768)*n)*2. - 1.; 
    
    // Animated.
    //p = fract(vec2(262144, 32768)*n);
    //return sin(p*6.2831853 + iTime); 
    
}
 
// Based on IQ's gradient noise formula.
float n2D3G(in vec2 p){
   
    vec2 i = floor(p); p -= i;
    
    vec4 v;
    v.x = dot(hash22(i), p);
    v.y = dot(hash22(i + vec2(1, 0)), p - vec2(1, 0));
    v.z = dot(hash22(i + vec2(0, 1)), p - vec2(0, 1));
    v.w = dot(hash22(i + 1.), p - 1.);

#if 1
    // Quintic interpolation.
    p = p*p*p*(p*(p*6. - 15.) + 10.);
#else
    // Cubic interpolation.
    p = p*p*(3. - 2.*p);
#endif

    return mix(mix(v.x, v.y, p.x), mix(v.z, v.w, p.x), p.y);
    //return v.x + p.x*(v.y - v.x) + p.y*(v.z - v.x) + p.x*p.y*(v.x - v.y - v.z + v.w);
}


// Height map values. Just some noise, with a path cut out for the camera to go through.
float hm(in vec2 p){
    
    // Camera path. 
    vec2 pth = p.xy - path(p.y);
    float camPath = abs(pth.x);
    
    // Scaling.
    p = p/2.5;// + iTime/4.;
    
    // Noise, for the terrain, or block heights
    float n = n2DS(p.xy + 7.5);//*.67 + n2D(p.xy*2.)*.33;
    
    // Cutting a camera path out of the noisy terrain.
    n = smoothstep(.2, 1., n)*clamp(camPath - .6, 0., 1.);
 
    
    return n; // Range [0, 1]... hopefully. :)

}



float sBox(in vec3 p, in vec3 b){
   

  vec3 d = abs(p) - b;
  return min(max(max(d.x, d.y), d.z), 0.) + length(max(d, 0.));
}

float sBoxS(in vec2 p, in vec2 b, in float sf){
   

  vec2 d = abs(p) - b + sf;
  return min(max(d.x, d.y), 0.) + length(max(d, 0.)) - sf;
}

/*
float sBoxS(in vec3 p, in vec3 b, in float sf){
   

  vec3 d = abs(p) - b + sf;
  return min(max(max(d.x, d.y), d.z), 0.) + length(max(d, 0.)) - sf;
}
*/

// IQ's extrusion formula.
float opExtrusion(in float sdf, in float pz, in float h){
    
    
    vec2 w = vec2( sdf, abs(pz) - h );
  	return min(max(w.x, w.y), 0.) + length(max(w, 0.));

    /*
    // Slight rounding. A little nicer, but I want to save every operation
    // I can.
    const float sf = .005;
    vec2 w = vec2(sdf, abs(pz) - h) + sf;
  	return min(max(w.x, w.y), 0.) + length(max(w, 0.)) - sf;
    */
}

 
// Skewing and unskewing.
vec2 skewXY(vec2 p, vec2 v){ return mat2(1, -v.y, v.x, 1)*p; }
vec2 unskewXY(vec2 p, vec2 v){ return inverse(mat2(1, -v.y, v.x, 1))*p; }

 
// Extruded 3 by 2 bricks, laid out in a herringbone formation with heights
// derived from a simple height function. It was a little fiddly to code,
// but anyone could figure it out.
vec4 herringbone3D(vec3 q3){
    
    // Scale.
    const float scale = 1./3.;
    // Skewing vector. Each brick staggers down by this amount... for some
    // reason that made sense to me at the time... I should probably write 
    // these things down. :D
	const vec2 sk = vec2(1, -1)/5.; // 12 x .2
    // Brick dimension: Length to height ratio with additional scaling.
	const vec2 dim = vec2(1.5, 1)*scale;
    // A helper vector, but basically, it's the size of the repeat cell.
    // Again, the little correction factor made sence to me at the time.
    // When the reasoning comes to me, I'll update the comments. :)
	vec2 s = (vec2(2.5, 2.5) - abs(sk)/2.)*scale; // 12 x .2

    // A hacky Z-scaling factor to help avoid artifacts. In case it isn't 
    // obvious, I didn't enjoy coding this. :D
    q3.y *= scale/2.;
    
    
    // Distance.
    float d = 1e5;
    // Cell center, local coordinates and overall cell ID.
    vec2 cntr, p, ip;
    
    // Individual brick ID.
    vec2 id = vec2(0);
    vec2 l = dim;
    cntr = vec2(0);
    float boxID = 0.; // Box ID. Not used in this example, but helpful.
    
    for(int i = 0; i<4; i++){
         
        if(i==2) {
            cntr = vec2((dim.x + dim.y)/2., -dim.y/4.);
            l = l.yx;
        }

        // Working with skewed grids can be a bit confusing, but it's not
        // so bad. However, following someone elses logic is always confusing,
        // so for now, just trust that this particular process works. If you're
        // like me, and you need to do things for yourself, create a pattern
        // that involves a skewed grid, and the following should make more sense.
        // 
        // Local coordinates, based on a square grid.
        p = q3.xz - cntr;
        p = skewXY(p, sk); // Skewing by the X and Y skewing values.
        ip = floor(p/s) + .5; // Local tile ID.
        p -= (ip)*s; // New local position.
        p = unskewXY(p, sk); // Unskewing.


        // At the this point, you render whatever object you wish to render, just
        // like with any other grid. In this case it's an extruded pylon that 
        // takes its height from a height map function.
        
        // Rounded box.
        float di2D = sBoxS(p, l/2., .04);
        // Correct positional individual tile ID.
        vec2 idi = ip*s + cntr;
        // Don't forget to unskew the ID... Yeah, skewing is confusing. :)
        idi = unskewXY(idi, sk);
        // The extruded block height. See the height map function, above. I've
        // Also used to the floor function to snap the heights to specific
        // quantized values.
        float h = max(floor(hm(idi)*24.999)/24., 0.)*.5 + .002;
        
        // The extruded distance function value.
        float di = opExtrusion(di2D + .01, q3.y - h, h);

        // For all tiles above a certain height, bore out the center to give it
        // a Besser block feel.
        if(h>.0025){

            di = max(di, -(di2D + .1));
        }


        // If necessary, update the minimum tile value, position-based ID, and block ID.
        if(di<d){
            d = di;
            id = idi;
            boxID = float(i);

        }

        // Move the grid center to the new position. From the pattern, you can see that
        // each tile is rendered down by factor equivalent to the longest length.
        cntr -= -dim.y;
        
    }
    
    // Return the distance, unskewed position-base ID and box ID.
    return vec4(d, id, boxID);
}

// Brick ID and scene object ID.
vec2 bID;
vec3 objID;

// The flat shaded terrain and the mesh.
float map(vec3 p){
    
    
    // Terrain function. Essentially, the sand, in this case. 
    float ter = p.y + (.5 - surfFunc(p))*.8 - .05;

    // The extruded herringbone heightmap.
    vec4 her = herringbone3D(p); 

    // The individual brick pylon ID.
    bID = her.yz;
    
 
    // Placing the individual object IDs in a container. This will
    // be sorted outside the loop. It's also necessary to compare
    // values, to mix materials. Like, for instance, where the sand
    // meets the brick surface.
    objID = vec3(ter, her.x, 1e5);
    
    
    // Combining the blocks with the terrain. I've combined them with 
    // a touch of smoothing to make it look a little more organic.
    return smin(ter, her.x, .005);
 
}


// Basic raymarcher.
float trace(in vec3 ro, in vec3 rd){

    float t = 0., d;
    
    // Hack to force loop unrolling. I can't say I'm happy with it, but it is what it is. :)
    // If someone has a better idea, feel free to let me know.
    //int zer = int(min(iTime, 0.)); 
    for(int i = 0; i<128; i++){
    
        d = map(ro + rd*t);
        // Note the "t*b + a" addition. Basically, we're putting less emphasis on accuracy, as
        // "t" increases. It's a cheap trick that works in most situations... Not all, though.
        if(abs(d)<.001*(t*.05 + 1.) || t>FAR) break; // Alternative: 0.001*max(t*.25, 1.), etc.
        
        // I concocted this mess in a desperate attempt to get more mileage out of the ray, and 
        // amazingly, it worked. Having said that, you probably shouldn't try this at home. :D
        t += i<32? d*.75 : d*(1. + t*.05); 
    }

    return min(t, FAR);
}


/*
// Tetrahedral normal - courtesy of IQ. I'm in saving mode, so the two "map" calls saved make
// a difference. Also because of the random nature of the scene, the tetrahedral normal has the 
// same aesthetic effect as the regular - but more expensive - one, so it's an easy decision.
vec3 normal(in vec3 p, float ef)
{  
    vec2 e = vec2(-1, 1)*.001*ef;   
	return normalize(e.yxx*map(p + e.yxx) + e.xxy*map(p + e.xxy) + 
					 e.xyx*map(p + e.xyx) + e.yyy*map(p + e.yyy) );   
}
*/

 
// Standard normal function. It's not as fast as the tetrahedral calculation, but more symmetrical.
vec3 normal(in vec3 p, float ef) {
	vec2 e = vec2(.001*ef, 0);
	return normalize(vec3(map(p + e.xyy) - map(p - e.xyy), map(p + e.yxy) - map(p - e.yxy),	map(p + e.yyx) - map(p - e.yyx)));
}

/*
// Tri-Planar blending function. Based on an old Nvidia writeup:
// GPU Gems 3 - Ryan Geiss: https://developer.nvidia.com/gpugems/GPUGems3/gpugems3_ch01.html
vec3 tex3D(sampler2D t, in vec3 p, in vec3 n ){
    
    n = max(abs(n) - .2, 0.001);
    n /= dot(n, vec3(1));
	vec3 tx = texture(t, p.yz).xyz;
    vec3 ty = texture(t, fract(p.zx)).xyz;
    vec3 tz = texture(t, p.xy).xyz;

    // Textures are stored in sRGB (I think), so you have to convert them to linear space 
    // (squaring is a rough approximation) prior to working with them... or something like that. :)
    // Once the final color value is gamma corrected, you should see correct looking colors.
    return (tx*tx*n.x + ty*ty*n.y + tz*tz*n.z);
    
}


// Texture bump mapping. Four tri-planar lookups, or 12 texture lookups in total.
vec3 doBumpMap( sampler2D tx, in vec3 p, in vec3 n, float bf){
   
    const vec2 e = vec2(0.001, 0);
    
    // Three gradient vectors rolled into a matrix, constructed with offset greyscale texture values.    
    mat3 m = mat3( tex3D(tx, p - e.xyy, n), tex3D(tx, p - e.yxy, n), tex3D(tx, p - e.yyx, n));
    
    vec3 g = vec3(0.299, 0.587, 0.114)*m; // Converting to greyscale.
    g = (g - dot(tex3D(tx,  p , n), vec3(0.299, 0.587, 0.114)) )/e.x; g -= n*dot(n, g);
                      
    return normalize( n + g*bf ); // Bumped normal. "bf" - bump factor.
	
}
*/

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





// A global value to record the distance from the camera to the hit point. It's used to tone
// down the sand height values that are further away. If you don't do this, really bad
// Moire artifacts will arise. By the way, you should always avoid globals, if you can, but
// I didn't want to pass an extra variable through a bunch of different functions.
float gT;

// Surface bump function..
float bumpSurf3D( in vec3 p){
    
    
    
    p *= vec3(1.65, 2.2, 3.85);
    //float ns = n2D(p.xz)*.57 + n2D(p.xz*2.)*.28 + n2D(p.xz*4.)*.15;
    float ns = n3D(p)*.57 + n3D(p*2.)*.28 + n3D(p*4.)*.15;
    
    // vec2 q = rot2(-3.14159/5.)*p.xz;
    // float ns1 = grad(p.z*32., 0.);//*clamp(p.y*5., 0., 1.);//smoothstep(0., .1, p.y);//
    // float ns2 = grad(q.y*32., 0.);//*clamp(p.y*5., 0., 1.);//smoothstep(0., .1, p.y);//
    // ns = mix(ns1, ns2, ns);
    
    ns = (1. - abs(smoothstep(0., 1., ns) - .5)*2.);
    ns = mix(ns, smoothstep(0., 1., ns), .65);
    
    // Use the height to taper off the sand edges, before returning.
    ns = ns*smoothstep(0., .2, p.y - .075);
    
    
    // A surprizingly simple and efficient hack to get rid of the super annoying Moire pattern 
    // formed in the distance. Simply lessen the value when it's further away. Most people would
    // figure this out pretty quickly, but it took far too long before it hit me. :)
    return ns/(1. + gT*gT*.015);
    

}

// Standard function-based bump mapping routine: This is the cheaper four tap version. There's
// a six tap version (samples taken from either side of each axis), but this works well enough.
vec3 doBumpMap(in vec3 p, in vec3 nor, float bumpfactor){
    
    // Larger sample distances give a less defined bump, but can sometimes lessen the aliasing.
    const vec2 e = vec2(0.001, 0); 
    
    // Gradient vector: vec3(df/dx, df/dy, df/dz);
    float ref = bumpSurf3D(p);
    vec3 grad = (vec3(bumpSurf3D(p - e.xyy),
                      bumpSurf3D(p - e.yxy),
                      bumpSurf3D(p - e.yyx)) - ref)/e.x; 
    
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

// Cheap shadows are hard. In fact, I'd almost say, shadowing particular scenes with limited 
// iterations is impossible... However, I'd be very grateful if someone could prove me wrong. :)
float softShadow(vec3 ro, vec3 lp, vec3 n, float k){

    // More would be nicer. More is always nicer, but not really affordable... Not on my slow test machine, anyway.
    const int maxIterationsShad = 32; 
    
    ro += n*.0015;
    vec3 rd = lp - ro; // Unnormalized direction ray.
    

    float shade = 1.;
    float t = 0.;//.0015; // Coincides with the hit condition in the "trace" function.  
    float end = max(length(rd), 0.0001);
    //float stepDist = end/float(maxIterationsShad);
    rd /= end;

    // Max shadow iterations - More iterations make nicer shadows, but slow things down. Obviously, the lowest 
    // number to give a decent shadow is the best one to choose. 
    //int zer = int(min(iTime, 0.)); // Hack to force loop unrolling.
    for (int i = 0; i<maxIterationsShad; i++){

        float d = map(ro + rd*t);
        shade = min(shade, k*d/t);
        //shade = min(shade, smoothstep(0., 1., k*h/dist)); // Subtle difference. Thanks to IQ for this tidbit.
        // So many options here, and none are perfect: dist += min(h, .2), dist += clamp(h, .01, stepDist), etc.
        t += clamp(d*.75, .05, .35); 
        
        
        // Early exits from accumulative distance function calls tend to be a good thing.
        if (d<0. || t>end) break; 
    }

    // Sometimes, I'll add a constant to the final shade value, which lightens the shadow a bit --
    // It's a preference thing. Really dark shadows look too brutal to me. Sometimes, I'll add 
    // AO also just for kicks. :)
    return max(shade, 0.); 
}



// I keep a collection of occlusion routines... OK, that sounded really nerdy. :)
// Anyway, I like this one. I'm assuming it's based on IQ's original.
float calcAO(in vec3 p, in vec3 n)
{
	float sca = 3., occ = 0.;
    for( int i = 0; i<5; i++ ){
    
        float hr = float(i + 1)*.15/5.;        
        float d = map(p + n*hr);
        occ += (hr - d)*sca;
        sca *= .7;
    }
    
    return clamp(1. - occ, 0., 1.);  
    
    
}


// Standard sky routine: Gradient with sun and overhead cloud plane. I debated over whether to put more 
// effort in, but the dust is there and I'm saving cycles. I originally included sun flares, but wasn't 
// feeling it, so took them out. I might tweak them later, and see if I can make them work with the scene.
vec3 getSky(vec3 ro, vec3 rd, vec3 ld){ 
    
    // Sky color gradients.
    vec3 col = vec3(.8, .7, .5), col2 = vec3(.4, .6, .9);
    
    // Probably a little too simplistic. :)
    //return mix(col, col2, pow(max(rd.y*.5 + .9, 0.), 5.))*vec3(1.2, .95, .7); 
    
    // Mix the gradients using the Y value of the unit direction ray. 
    vec3 sky = mix(col, col2, pow(max(rd.y + .15, 0.), .5));
    //sky *= vec3(.84, 1, 1.17); // Adding some extra vibrancy.
    
     
    float sun = clamp(dot(ld, rd), 0., 1.);
    sky += vec3(1, .7, .4)*vec3(pow(sun, 16.))*.2; // Sun flare, of sorts.
    sun = pow(sun, 32.); // Not sure how well GPUs handle really high powers, so I'm doing it in two steps.
    sky += vec3(1, .9, .7)*vec3(pow(sun, 32.))*.35/vec3(1.2, 1, .8); // Sun.
    
     // Subtle, fake sky curvature.
    rd.z *= 1. + length(rd.xy)*.15;
    rd = normalize(rd);
   
    // A simple way to place some clouds on a distant plane above the terrain -- Based on something IQ uses.
    const float SC = 1e5;
    float t = (SC - ro.y - .15)/(rd.y + .15); // Trace out to a distant XZ plane.
    vec2 uv = (ro + t*rd).xz; // UV coordinates.
    
    // Mix the sky with the clouds, whilst fading out a little toward the horizon (The rd.y bit).
	if(t>0.) sky =  mix(sky, vec3(2), smoothstep(.45, 1., fBm(1.5*uv/SC))*
                        smoothstep(.45, .55, rd.y*.5 + .5)*.4);
    
    // Return the sky color.
    return sky*vec3(1.2, 1, .8);
     
}



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

/////
// Code block to produce some layers of smokey haze. Not sophisticated at all.
// If you'd like to see a much more sophisticated version, refer to Nitmitz's
// Xyptonjtroz example. Incidently, I wrote this off the top of my head, but
// I did have that example in mind when writing this.

// Hash to return a scalar value from a 3D vector.
float hash31(vec3 p){ return fract(sin(dot(p, vec3(127.1, 311.7, 74.7)))*43758.5453); }

// Several layers of cheap noise to produce some subtle smokey haze.
// Start at the ray origin, then take some samples of noise between it
// and the surface point. Apply some very simplistic lighting along the 
// way. It's not particularly well thought out, but it doesn't have to be.
float getMist(in vec3 ro, in vec3 rd, in vec3 lp, in float t){

    float mist = 0.;
    
    //ro -= vec3(0, 0, iTime*3.);
    
    float t0 = 0.;
    
    for (int i = 0; i<24; i++){
        
        // If we reach the surface, don't accumulate any more values.
        if (t0>t) break; 
        
        // Lighting. Technically, a lot of these points would be
        // shadowed, but we're ignoring that.
        float sDi = length(lp-ro)/FAR; 
	    float sAtt = 1./(1. + sDi*.25);
	    
        // Noise layer.
        vec3 ro2 = (ro + rd*t0)*2.5;
        float c = noise3D(ro2)*.65 + noise3D(ro2*3.)*.25 + noise3D(ro2*9.)*.1;
        //float c = noise3D(ro2)*.65 + noise3D(ro2*4.)*.35; 

        float n = c;//max(.65-abs(c - .5)*2., 0.);//smoothstep(0., 1., abs(c - .5)*2.);
        mist += n*sAtt;
        
        // Advance the starting point towards the hit point. You can 
        // do this with constant jumps (FAR/8., etc), but I'm using
        // a variable jump here, because it gave me the aesthetic 
        // results I was after.
        t0 += clamp(c*.25, .1, 1.);
        
    }
    
    // Add a little noise, then clamp, and we're done.
    return max(mist/48., 0.);
    
    // A different variation (float n = (c. + 0.);)
    //return smoothstep(.05, 1., mist/32.);

}

//////

void mainImage( out vec4 fragColor, in vec2 fragCoord ){	


	
	// Screen coordinates.
	vec2 u = (fragCoord - iResolution.xy*.5)/iResolution.y;
	
	// Camera Setup.     
	vec3 ro = vec3(0, 1.5, iTime*2.); // Camera position, doubling as the ray origin.
    vec3 lk = ro + vec3(0, -.1, .5);  // "Look At" position.
    
	
	// Using the Z-value to perturb the XY-plane.
	// Sending the camera and "look at" vectors down the tunnel. The "path" function is 
	// synchronized with the distance function.
	ro.xy += path(ro.z);
	lk.xy += path(lk.z);

 
    // Using the above to produce the unit ray-direction vector.
    float FOV = 3.14159265/2.5; // FOV - Field of view.
    vec3 fw = normalize(lk - ro);
    vec3 rt = normalize(vec3(fw.z, 0, -fw.x )); 
    vec3 up = cross(fw, rt);

    // rd - Ray direction.
    vec3 rd = normalize(fw + (u.x*rt + u.y*up)*FOV);
    // Warping the ray to give that curved lens effect.
    rd = normalize(vec3(rd.xy, rd.z*(1. - length(rd.xy)*.25)));
    
    // Swiveling the camera about the XY-plane (from left to right) when turning corners.
    // Naturally, it's synchronized with the path in some kind of way.
	rd.xy = rot2( path(lk.z).x/48.)*rd.xy;
    
	
    // Usually, you'd just make this a unit directional light, and be done with it, but I
    // like some of the angular subtleties of point lights, so this is a point light a
    // long distance away. Fake, and probably not advisable, but no one will notice.
    vec3 lp = vec3(FAR*.25, FAR*.35, FAR) + vec3(0, 0, ro.z);
 

	// Raymarching.
    float t = trace(ro, rd);
    
    // Saving objects.
    vec2 svBID = bID;
    vec3 oSvObjID = objID; // Saving the list of object IDs for blending purposes.
    // Closest object ID.
    float svObjID = objID.x < objID.y? 0. : 1.;

    // Global distance. Used to mitigate Moire pattern effects.
    gT = t;
   
    // Sky. Only retrieving a single color this time.
    //vec3 sky = getSky(rd);
    
    // The passage color.
    vec3 col = vec3(0);
    
    // Surface point. "t" is clamped to the maximum distance, and I'm reusing it to render
    // the mist, so that's why it's declared in an untidy position outside the block below...
    // It seemed like a good idea at the time. :)
    vec3 sp = ro + t*rd; 
    
    float pathHeight = sp.y;//surfFunc(sp);// - path(sp.z).y; // Path height line, of sorts.
    
    // If we've hit the ground, color it up.
    if (t < FAR){
    
        
        vec3 sn = normal(sp, 1.); // Surface normal. //*(1. + t*.125)
        
        // Light direction vector. From the sun to the surface point. We're not performing
        // light distance attenuation, since it'll probably have minimal effect.
        vec3 ld = lp - sp;
        float lDist = max(length(ld), 0.001);
        ld /= lDist; // Normalize the light direct vector.
        
        lDist /= FAR; // Scaling down the distance to something workable for calculations.
        float atten = 1./(1. + lDist*lDist*.05);

        
        // Texture scale factor.        
        const float tSize = 1./8.;
        
        
        // Function based bump mapping.
        if(svObjID==0.) sn = doBumpMap(sp, sn, .1);///(1. + t*t/FAR/FAR*.25)
        
        // Texture bump mapping.
        float bf = .01;//(pathHeight + 5. < 0.)?  .05: .025;
        //sn = doBumpMap(iChannel0, sp*tSize, sn, bf/(1. + t/FAR));
        
        
        // Soft shadows and occlusion.
        float sh = softShadow(sp, lp, sn, 8.);
        float ao = calcAO(sp, sn); // Ambient occlusion.
        
        // Add AO to the shadow. No science, but adding AO to things sometimes gives a bounced light look.
        sh = min(sh + .25, 1.); 
        
        float dif = max( dot( ld, sn ), 0.); // Diffuse term.
        float spe = pow(max( dot( reflect(-ld, sn), -rd ), 0.0 ), 5.); // Specular term.
        float fre = clamp(1.0 + dot(rd, sn), 0., 1.); // Fresnel reflection term.
 
        // Schlick approximation. I use it to tone down the specular term. It's pretty subtle,
        // so could almost be aproximated by a constant, but I prefer it. Here, it's being
        // used to give a sandstone consistency... It "kind of" works.
		float Schlick = pow( 1. - max(dot(rd, normalize(rd + ld)), 0.), 5.0);
		float fre2 = mix(.2, 1., Schlick);  //F0 = .2 - Hard clay... or close enough.
       
        // Overal global ambience. It's made up, but I figured a little occlusion (less ambient light
        // in the corners, etc) and reflectance would be in amongst it... Sounds good, anyway. :)
        float amb = ao*.35;// + fre*fre2*.2;
        

        
        
        
		// Surface texel.
        vec3 tx = tex3D(iChannel0, sp/2., sn);
 
        tx = smoothstep(-.2, .4, tx);
    	//tx = mix(tx, vec3(1)*dot(tx, vec3(.299, .587, .114)), .5); // Toning down a little.
        
        vec3 sndTx = mix(vec3(1, .95, .7), vec3(.9, .6, .4), fBm(sp.xz*16.));
        
        vec3 col0 = col;
        vec3 col1 = col;
        
        float bordCol0Col1 = oSvObjID.x - oSvObjID.y;
        const float bordW = .1;
        
        
        // Blocks.
        if(svObjID==1. || abs(bordCol0Col1)<bordW){
            col1 = tx*mix(vec3(1), sndTx*2., .6);///vec3(1, .9, .8)*1.5; 
            
            col1 *= 1./(1. + t*t*.005);
            
            vec3 bTx = texture(iChannel0, svBID).xyz; bTx *= bTx;
            bTx =  smoothstep(0., .5, bTx);
            
            col1 = mix(col1, col1*bTx*2.4, .35);
        }
       
        // Sand.
        if(svObjID==0. || abs(bordCol0Col1)<bordW){
        
            // Give the sand a bit of a sandstone texture.
        	col0 = sndTx;//mix(vec3(1, .95, .7), vec3(.9, .6, .4), fBm(sp.xz*16.));
        	col0 = mix(col0*1.4, col0*.6, fBm(sp.xz*32. - .5));///(1. + t*t*.001)
     
             // Extra shading in the sand crevices.
            float bSurf = bumpSurf3D(sp);
            col0 *= bSurf*.75 + .5;
            col0 *= vec3(1.5, 1.45, 1.3)/2.;
 
        }
        
        
        
        
        // Return the color, which is either the sandy terrain color, the object color,
    	// or if we're in the vicinity of both, make it a mixture of the two.
    	col = mix(col0, col1, smoothstep(-bordW, bordW, bordCol0Col1));
       
        // Lamest sand sprinkles ever. :)
        col = mix(col*.7 + (hash(floor(sp*96.))*.7 + hash(floor(sp*192.))*.3)*.3, col, min(t*t/FAR, 1.));
        col *= vec3(1.2, 1, .9); // Extra color -- Part of last minute adjustments.
    
        
        // Combining all the terms from above. Some diffuse, some specular - both of which are
        // shadowed and occluded - plus some global ambience. Not entirely correct, but it's
        // good enough for the purposes of this demonstation.        
        col = col*(dif + amb + vec3(1, .97, .92)*fre2*spe*2.)*atten;
        
        
        // A bit of sky reflection. Not really accurate, but I've been using fake physics since the 90s. :)
        vec3 refSky = getSky(sp, reflect(rd, sn), ld);
        col += col*refSky*.05 + refSky*fre*fre2*atten*.15; 
        
 
        // Applying the shadows and ambient occlusion.
        col *= sh*ao;

        
    }
    
  
    // Combine the scene with the sky using some cheap volumetric substance.
	float dust = getMist(ro, rd, lp, t)*(1. - smoothstep(0., 1., pathHeight*.05));//(-rd.y + 1.);
    vec3 gLD = normalize(lp - vec3(0, 0, ro.z));
    vec3 sky = getSky(ro, rd, gLD);//*mix(1., .75, dust);
    //col = mix(col, sky, min(t*t*1.5/FAR/FAR, 1.)); // Quadratic fade off. More subtle.
    col = mix(col, sky, smoothstep(0., .95, t/FAR)); // Linear fade. Much dustier. I kind of like it.
    
    
    // Mild dusty haze... Not really sure how it fits into the physical situation, but I thought it'd
    // add an extra level of depth... or something. At this point I'm reminded of the "dog in a tie 
    // sitting at the computer" meme with the caption, "I have no idea what I'm doing." :D
    vec3 mistCol = vec3(1, .95, .9); // Probably, more realistic, but less interesting.
    col += (mix(col, mistCol, .66)*.66 + col*mistCol*1.)*dust;
    
    
    // Simulating sun scatter over the sky and terrain: IQ uses it in his Elevated example.
    col += vec3(1., .7, .4)*pow( max(dot(rd, gLD), 0.), 16.)*.4;
    
    
    // Applying the mild dusty haze.
    col = col*.75 + (col + .25*vec3(1.2, 1, .9))*mistCol*dust*1.5;
    
    
    // Really artificial. Kind of cool, but probably a little too much.    
    //col *= vec3(1.2, 1, .9);

    #ifdef NIGHT
    // Cheapest, laziest night time postprocessing ever. :D
    col *= vec3(.4, .6, 1);
    #endif
    
    // Standard way to do a square vignette. Note that the maxium value value occurs at "pow(0.5, 4.) = 1./16," 
    // so you multiply by 16 to give it a zero to one range. This one has been toned down with a power
    // term to give it more subtlety.
    u = fragCoord/iResolution.xy;
    col = min(col, 1.)*pow( 16.*u.x*u.y*(1. - u.x)*(1. - u.y) , .0625);
 
    // Rough gamma correction, and present to screen.
	fragColor = vec4(sqrt(clamp(col, 0., 1.)), 1);
}