/*
    Underground Passageway
    ----------------------

	A simple demonstration of procedural texture construction and usage. In this case, creating 
	a rocky surface, then mapping it onto a basic scene... I guess another way to put it would
	be, yet another tunnel. :)

    There's a standard technique that a lot of texture artists employ to produce rocky surfaces 
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

	Anyway, this was just a simple proof of concept. The main point of this was to show that 
	under the right circumstances, it's possible to precalculate more complex surface details
	for realtime usage.
	

	Related examples:

	// I'm using some older code of mine, but Fabrice has already produced something along
	// these lines. I haven't had a proper look at the code, but I will when I get a chance.
	rocks (WIP) - FabriceNeyret2 
	https://www.shadertoy.com/view/ls3fzj


	// One of my favorite simple coloring jobs.
    Skin Peeler - Dave Hoskins
    https://www.shadertoy.com/view/XtfSWX
    Based on one of my all time favorites:
    Xyptonjtroz - Nimitz
	https://www.shadertoy.com/view/4ts3z2

*/


// Shorthand, so that the texture lines read a little better.
vec4 tx(vec2 p){ return texture(iChannel0, p); }

/*
// Screen blend.
float screenBlend(vec2 va1, vec2 va2){ 
    return 1. - (1. - va1.x*va1.y)*(1. - va2.x*va2.y);
}
*/

// 2x2 matrix rotation. Note the absence of "cos." It's there, but in disguise, and comes courtesy
// of Fabrice Neyret's "ouside the box" thinking. :)
mat2 rot2( float a ){ vec2 v = sin(vec2(1.570796, 0) + a);	return mat2(v, -v.y, v.x); }


// vec2 to vec2 hash.
float hash21(vec2 p, vec2 scale, float repScale) { 

    // The key to repeat procedural textures that are construct with random hash
    // functions, which is pretty much all of them. :) Dave Hoskins has a 
    // beginner reference on here somewhere.
    p = mod(p*scale, repScale);
    
    // Faster, but doesn't disperse things quite as nicely. However, when framerate
    // is an issue, and it often is, this is a good one to use. Basically, it's a tweaked 
    // amalgamation I put together, based on a couple of other random algorithms I've 
    // seen around... so use it with caution, because I make a tonne of mistakes. :)
    return fract(sin(dot(p, vec2(57.927, 127.763)))*43758.5453);
} 

#define RIGID
// Standard 2x2 hash algorithm.
vec2 hash22(vec2 p, vec2 scale, float repScale) {
  
    p = mod(p*scale, repScale);
    // Faster, but probaly doesn't disperse things as nicely as other methods.
    float n = sin(dot(p, vec2(1, 113)));
    p = fract(vec2(2097152, 262144)*n);
    #ifdef RIGID
    return p;
    #else
    return cos(p*6.283 + iGlobalTime)*.5 + .5;
    //return abs(fract(p+ iGlobalTime*.25)-.5)*2. - .5; // Snooker.
    //return abs(cos(p*6.283 + iGlobalTime))*.5; // Bounce.
    #endif

}

// Standard 2x2 hash algorithm.
vec2 hash22G(vec2 p, vec2 scale, float repScale) {

    p = mod(p*scale, repScale);
    // Faster, but probaly doesn't disperse things as nicely as other methods.
    float n = sin(dot(p, vec2(27, 57)));
    return fract(vec2(2097152, 262144)*n)*2. - 1.;

}

// Gradient noise. Ken Perlin came up with it, or a version of it. Either way, this is
// based on IQ's implementation. It's a pretty simple process: Break space into squares, 
// attach random 2D vectors to each of the square's four vertices, then smoothly 
// interpolate the space between them.
float gradN2D(in vec2 f, vec2 scale, float repScale){
  
   f *= repScale;
    
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
    float c = mix(mix(dot(hash22G(p + e.xx, scale, repScale), f - e.xx), dot(hash22G(p + e.yx, scale, repScale), f - e.yx), w.x),
                  mix(dot(hash22G(p + e.xy, scale, repScale), f - e.xy), dot(hash22G(p + e.yy, scale, repScale), f - e.yy), w.x), w.y);
    
    // Taking the final result, and converting it to the zero to one range.
    return c*.5 + .5; // Range: [0, 1].
}

// Gradient noise fBm.
float fBm(in vec2 p, vec2 scale, float repScale){
    
    p *= repScale;
    return gradN2D(p, scale, repScale)*.57 + gradN2D(p, scale, repScale*2.)*.28 + gradN2D(p, scale, repScale*4.)*.15;
    
}

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


/*
// Fancier rock function, but wasn't needed here.
float rock(vec2 p, vec2 ip,  vec2 scale, float repScale){
    
    //vec2 pert = vec2(gradN2D(p, vec2(1), 8.), gradN2D(p + .5, vec2(1), 8.)) - .5;
    //p += pert*.1;
    
    float rnd;// = hash21(ip);
    
    
    vec2 q;
    float taper = 0.;//-(q.y)*2.*.5 + .5;
    //p = vec2(abs(p.x)*1.5, (p.y)*1.5 - .25)*2.; // Triangle.


    // Slicing off more of the shape. In theory, it's more rock like, but
    // I prefer a more geometric single tapering.
    //for(int i=0; i<6; i++){
    //    rnd = hash21(ip + float(i), scale, repScale); //float(i)*.18;//
    //    q = rot2(rnd*6.2831)*p;
    //    taper = max(taper, -(q.y)*2.*.75 + .25);
    //}
 
    
    taper = (p.y)*2.*.65 + .35;
    //taper = mix(taper, max(taper, .5), .35); // Flattening the sharp edge a bit.
    
    p = abs(p)*2.;
    
    float shape = max(p.x, p.y);
    //float shape = max(p.x*.866025 - p.y*.5, p.y);
    //float shape = max(p.x*.866025 + p.y*.5, p.y);
    //float shape = max(max(p.x, p.y), (p.x + p.y)*.7071);
    //float shape = length(p);
    //float shape = dot(p, p)*2.;
    
    //shape = max(shape, -(shape - .75));
    
    //return shape;
    //return max(length(p) - .1, shape);
    return max(shape, taper);
    //return smoothstep(0., 1., max(shape, taper));
    
}
*/

// You can make this up as you go along, but the idea is to render a beveled kind of 
// shape. In this case, it's a simplistic pyramid (square field) mixed with a linear 
// gradient that forms a kind of wedge shape. As you could imagine, wedges tend to work 
// well with rock layers. A lot of texture artists employ this trick. I don't know who
// came up with the idea first, but I last came across it here:
//
// Substance Designer - Rock Height Tips
// Pierre FLEAU
// https://pfleau.artstation.com/projects/K9AwG
float rock(vec2 p){
    
    float taper = (p.y)*2.*.65 + .35; // Linear gradient of sorts.
    //float taper = p.y + .5; // Original.
    //taper = mix(taper, max(taper, .5), .35); // Flattening the sharp edge a bit.
    
    p = abs(p)*2.;
    //p = vec2(abs(p.x)*1.5, (p.y)*1.5 - .25)*2.; // Used with triangle.
    
    float shape = max(p.x, p.y); // Square.
    //float shape = max(p.x*.866025 - p.y*.5, p.y); // Triangle.
    //float shape = max(p.x*.866025 + p.y*.5, p.y); // Hexagon.
    //float shape = max(max(p.x, p.y), (p.x + p.y)*.7071); // Octagon.
    //float shape = length(p); // Circle.
    //float shape = dot(p, p); // Circle squared.
    
    
    //shape = (shape - .125)/(1. - .125);
    //shape = smoothstep(0., 1., shape);
    
    
    //return shape;
    return max(shape, taper);
    //return max(length(p) - .1, shape);
    
    
}

// This is similar to a Voronoi-like neighboring grid object function. Basically, you're 
// setting up a square grid, rendering an object in the grid cell, then comparing it with
// its neighbors in some way. The rendered objects are a little more sophisticated than 
// the simple circles, squares, and so forth, but the premise is the same.
//
// The particular function needs to render in a repetitive texture kind of way, so there's
// wrapping to consider as well. There's grid scaling, object scaling, rotation, etc...
// which between you and me was really annoying to code, but it's done now, so hopefully, 
// things will go more smoothly for anyone else who wishes to do this. :) In fact, I'm 
// hoping someone will make some improvents, etc, then produce some of the interesting 
// rock ground scenes that the Substance Designer people make.
float splatter(in vec2 p, float repScale, vec2 overlapFactor){
   
    p *= repScale; 

   
    // Must be factors of the repetition scale. If the repetition scale is, for example, 
    // 8, 1.5 won't work, but 2 would. Obviously, so would 1.
    vec2 scale = vec2(.75, 1.5); // Expand X, if you want to expand the strip length below.
    
    vec2 pert = vec2(gradN2D(p, vec2(1), 8.), gradN2D(p + .5, vec2(1), 8.)) - .5;
    p += pert*.125;

    
    vec2 ip = floor(p/scale);
    p = mod(p, scale) - scale/2.;

    
    
    vec3 d = vec3(4);
    
    vec2 dScale = overlapFactor;
    
    // There are 49 cell checks here... Ouch! Thankfully, this is only calculated on initiation,
    // so it doesn't matter a great deal.
    for(int j=-3; j<=3; j++){
        for(int i=-3; i<=3; i++){

            vec2 id = vec2(i, j);
            vec2 q = id*scale - p;
           
            // Scaling. Depending on the effect you're after, you can scale X and Y by a single
            // factor (using hash21), or with differing factors (hash22). You might even opt to
            // have no scaling at all.
            q *= 1. + (hash21(ip + id + 4., scale, repScale) - .5);
            
            // Random rotation. Again, the amount of rotation depends on the effect you're after.
            // In this case, I wanted the rock shapes to align with one another slightly, so a
            // factor of ".25" was used. I also wanted the rock's sedimentary layer lines 
            // (strata, I think it's called) to line up along the tunnel walls, so rotated by an 
            // extra factor of "pi/2."
            q = rot2((hash21(ip + id, scale, repScale) - .5)*6.2831*.25 + 3.14159/2.)*q;
            
            // Offsetting each shape. Like scaling and rotation, this is optional, and the factors
            // you use depend on what you're trying to achive.
            q += (hash22(ip + id + 2., scale, repScale) - .5)*.5*dScale;
            
            // The cell object you wish to render. How you go about it entirely up to you. I've
            // gone for a simple beveled square shape, but you can render far more sophisticated
            // things. By the way, if you simply rendered a circular blob, the pattern produced
            // would look a lot like regular cellular Voronoi.
            //d.z = rock(q/dScale, ip + id, scale, repScale);
            d.z = rock(q/dScale);
            //d.z = smoothstep(0., 1., d); // Optional smoothing. Doesn't work here.
            
            
            
            // Obtain the first order and second order distanced -- just like regular Voronoi. 
            // By the way, a minimum blend isn't mandatory. Others blends, like screen blends,
            // etc, are possible too.
			d.y = max(d.x, min(d.y, d.z)); // Second order distance -- Not used here.
            d.x = min(d.x, d.z); 
            //d.x = smin(d.x, d.z, .2); // A smooth blend. Sometimes, this can be effective.
            //d.x += 1./pow(d.z, 4.); // Needs to be compensated for outside the loop.

 
        }
    }
    
    // Compensation, if using the "c += 1./pow(d, 4.)" additive blend.
    //d.x = min(2./pow(d.x, 1./4.), 1.);
    
    //d.x = sqrt(max(d.x, 0.));
   
    // Reversing the return value. Depends what you're after.
    return 1. - d.x;
}


/*
// The max value of the N(0,1) PDF (probability density function)
// occurs at 0: 1./sqrt(2.*PI) = .39894;
float nPDF(in float x, in float sigma){

	return exp(-x*x/(sigma*sigma)/2.)/sigma*.39894;
}

// Blur function. Actually, it can be adapted for any filter, but here it's used to 
// blur pixels. It's not being used in this instance, because the jagged rock texture
// didn't seem to need it, but a lot of precalculated height maps do, this it's here
// for future use.
vec4 Blur(vec2 p) {
    

	// Kernel matrix dimension, and a half dimension calculation.
    const int mDim = 5, halfDim = (mDim - 1)/2;

    // You can experiment with different Laplacian related setups here. Obviously, when 
    // using the 3x3, you have to change "mDim" above to "3." There are widely varying 
    // numerical variances as well, so that has to be considered also.
    float kernel[mDim*mDim] = float[mDim*mDim](
        
    // Gaussian blur.
    1.,  4., 7.,  4.,  1.,
    4., 16.,  26., 16.,  4.,
    7., 26.,  41., .26, 7.,
    4., 16.,  26., 16.,  4.,
    1.,  4., 7.,  4.,  1.);

    //// Average blur.
    //1.,  1., 1.,  1.,  1.,
    //1.,  1., 1.,  1.,  1.,
    //1.,  1., 1.,  1.,  1.,
    //1.,  1., 1.,  1.,  1.,
    //1.,  1., 1.,  1.,  1.);
     
    
    // Calculating the Gaussian entries.
    //float sigma = 7.;
    //for (int j = 0; j < mDim*mDim; j++) kernel[j] = 0.;
    //int halfSize = (mDim*mDim - 1)/2;
    //for (int j = 0; j <= halfSize; ++j){
    //    kernel[halfSize + j] = kernel[halfSize - j] = nPDF(float(j), sigma);
    //}
 
    
    float total = 0.;
    
    //get the normalization factor (as the gaussian has been clamped)
    //for (int j = 0; j < mDim; j++)  total += kernel[j];
    for (int j = 0; j < mDim*mDim; j++) total += kernel[j];
    
    // Initiate the color. In this example, we only want the XY values, but just
    // in case you'd like to apply this elsewhere, I've included all four texture
    // channnels.
    vec4 col = vec4(0);
    
    // We're indexing neighboring pixels, so make this a pixel width.
    float px = 1./iResolution.y; 

    
    // There's a million boring ways to apply a kernal matrix to a pixel, and this 
    // is one of them. :)
    for (int j=0; j<mDim; j++){
        for (int i=0; i<mDim; i++){ 
            
            col += kernel[j*mDim + i]*tx(fract(p + vec2(i - halfDim, j - halfDim)*px));
        }
    }


    return col/total;
}

*/


/*
// Nine tap blur.
vec4 Blur9(vec2 p) {
    
    vec2 px = 1./iResolution.yy;
    // Four spots aren't required in this case, but are when the above isn't aspect correct.
    vec4 e = vec4(px, 0, -px.x);
 
    // Averaging nine pixels.
    return (tx(p - e.xy) +  tx(p - e.zy ) + tx(p - e.wy) + // First row.
			tx(p - e.xz) + tx(p) + tx(p + e.xz) + 		     // Seond row.
			tx(p + e.wy) + tx(p + e.zy) +  tx(p + e.xy))/9.;  // Third row
    
 
}
 
// Five tap Laplacian -- The simplest Laplacian filter... unless there's a more minimalistic one.
vec4 Blur5(vec2 p) {
    
    vec3 e = vec3(1./iResolution.yy, 0);

	return (tx(p - e.zy) + tx(p - e.xz) + tx(p) + tx(p + e.xz) + tx( p +  e.zy))/5.;
}

*/


void mainImage( out vec4 fragColor, in vec2 fragCoord ){

    vec2 uv = fragCoord.xy / iResolution.xy;
     
    vec4 col = texture(iChannel0, uv);
 
        
    if(iFrame<10 || abs(iResolution.x - col.x)>.001){
        
        // Not really necessary, but it's here anyway.
        vec2 p = fract(uv);

        //vec2 olFact = vec2(1.5); // Vertical and horizontal overlap factor.
        // If the grid itself is scaled by something like "1.5," for instance, the frequency
        // must be a multiple.
    
        // Four layers of varying frequencies. This is way too much work for a GPU to 
        // handle inside a distance field, and possibly a little too much to put together
        // in realtime at fullscreen. Thankfully, this is calculated just the once...
        // OK, technically for 10 frames at the beginning, but that's just to avoid things
        // getting skipped on the first few frames.
        float l1 = splatter(p - vec2(.5), 9., vec2(3., 1.5));
        float l2 = splatter(p + vec2(.5), 12., vec2(3., 1.5));
        float l3 = splatter(p, 15., vec2(3., 1.5));
        float l4 = splatter(p + vec2(.5, .5), 64., vec2(1.5));
 
        // Layer variations. I almost went with the less detailed "min(l2, l1)" option, but
        // decided on the three layer version instead. By the way, if you do try some of these,
        // be sure to reset to observe the change, or get rid of the "if" statement above.
        float df = 1.;
        //df = l1;
        //df = min(l2, l1);
        //df = smin(l2, l1, .15);
        df = min(min(l1, l2), (l3));
        //df = smin(smin(l3, l2, .15), l1, .15);
        //df = max(max(l3, l2), l1);
        //df = max(min(l3, l2), l1);
        //df = min(max(l2, l1), l3);
        //df = max(min(l2, l1), l3);
        //df = max(min(l3, l1), l2);
        //df = l1*.7 + l2*.2 + l3*.1;
    
        // Cracks... More thought should be put into this, but this will do for now.
     	//float cracks = smoothstep(0., .5, min(l3, l4));
     	float cracks = smoothstep(0., .1, min(l1, l4) - .25);
        //cracks *= 1. - smoothstep(0., .1, gradN2D(uv, vec2(1, 1), 60.) - .65);
    
        df = mix(df, cracks, .03);
        //df *= (cracks*.1 + 1.);
    
        // Extra roughage.
        df = mix(df, fBm(uv, vec2(1, 1), 16.), .05);
    
        // Putting the distance field value in the final channel. Two channels are used to store 
        // the resolution values, although only one is needed. With fixed sized buffers or a 
        // flag to signal a change in canvas size, this step wouldn't be necessary.
        fragColor = vec4(iResolution.xy, 0., df);
 
    }
    /*else if(iFrame<11){
        
	    // Usually performed in a separate buffer. Also this doesn't account for screen changes.
		// The logic for that is simple enough, but I'm not using it here anyway.
        //col = Blur(uv);
		col = Blur5(uv);
        fragColor = vec4(col, 1.);
    }*/
    else fragColor = col;
    
    
    

}