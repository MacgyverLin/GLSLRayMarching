/*

    Abstract Terrain Objects
    ------------------------

	Rendering some abstract geometry onto some terrain in a basic sci-fi tone.

	This was inspired by one of Mike Winkelmann's images, which I've included 
	a link to below. The original image is nicer -- partly due to the fact that
	I'm restricted by realtime constraints, and possibly, because I have the
	artistic vision of a programmer. :D
	
	Mike Winkelmann is the guy behind the amazing sci-fi flavored Beeple imagery 
	that appears in various corners of the internet. For anyone not familiar 
	with his work, it's well worth the look. Shau has been putting up a few 
	Beeple inspired shaders lately, which reminded me that I'd been meaning to
	do the same.

	Most of this is pretty standard stuff: Render some sky, terrain, and some 
	objects, with an extra reflective pass on the objects to make them shiny.
	I went to the trouble to blend materials when the shiny objects were near 
	the terrain. That involved a little bit of fiddly mixing, which complicated 
	the code a little, but nothing that anyone here couldn't handle. :)


	Original Image:

	// Putting abstract geometry on terrain is a weird but common concept 
	// amongst the graphics community, and this is a beautiful example.
	TRIOMETRIC - Beeple
	https://twitter.com/beeple/status/848029629973749760


	Examples:

	// One of Shau's Beeple inspired shaders.
	Data Surge - shau
	https://www.shadertoy.com/view/3dSXzm

	// Cool and qwirky. I love the rendering style.
	[SH16B] valley flight  - Bananaft
	https://www.shadertoy.com/view/XldGR7

	// I like the rendering style of this also.
	RayCraft - jolle
	https://www.shadertoy.com/view/tslGRX

	// Another one of Shau's. Fun to watch.
	XANNN - shau
	https://www.shadertoy.com/view/llSfzR

*/

// Maximum ray distance. Analogous to the far plane.
#define FAR 100. 

// More correct third pass: The reflection off the reflected surface is less
// noticeable, so we're saving some computing power and faking it, which means
// this is not on by default. However, if your computer can afford it, this is 
// a better option.
//#define THIRD_PASS


// Scene object ID. Either the Terrain object (0) or the chrome object (0).
vec4 objID, oSvObjID;
float svObjID; // Global ID to keep a copy of the above from pass to pass.


// vec2 to vec2 hash.
vec2 hash22(vec2 p) { 

    // Faster, but doesn't disperse things quite as nicely. However, when framerate
    // is an issue, and it often is, this is a good one to use. Basically, it's a tweaked 
    // amalgamation I put together, based on a couple of other random algorithms I've 
    // seen around... so use it with caution, because I make a tonne of mistakes. :)
    float n = sin(dot(p, vec2(1, 113)));
    return fract(vec2(262144, 32768)*n)*2. - 1.; 
    
    // Animated.
    //p = fract(vec2(262144, 32768)*n); 
    // Note the ".45," insted of ".5" that you'd expect to see. When edging, it can open 
    // up the cells ever so slightly for a more even spread. In fact, lower numbers work 
    // even better, but then the random movement would become too restricted. Zero would 
    // give you square cells.
    //return sin( p*6.2831853 + iTime ); 
    
}


// Fabrice's consice, 2D rotation formula.
//mat2 r2(float th){ vec2 a = sin(vec2(1.5707963, 0) + th); return mat2(a, -a.y, a.x); }
// Standard 2D rotation formula.
mat2 r2(in float a){ float c = cos(a), s = sin(a); return mat2(c, s, -s, c); }

// The path is a 2D sinusoid that varies over time, depending upon the frequencies, and amplitudes.
vec2 path(in float t){ 

    //return vec2(0);
    //float s = sin(t/24.)*cos(t/12.);
    //return vec2(s*4., 0.);
    
    float a = sin(t*.11);
    float b = cos(t*.14);
    return vec2((a*2./2. - b*1.5/2.), b*1.7/4. + a*1.5/4.);
    
    //return vec2(sin(t*.15)*2.4, cos(t*.25)*1.7*.5); 
}

// Smooth fract function.
float sFract(float x, float sf){
    
    x = fract(x);
    return min(x, (1. - x)*x*sf);
    
}


// Compact, self-contained version of IQ's 3D value noise function.
float n3D(vec3 p){
    
	const vec3 s = vec3(113., 57., 27.);
	vec3 ip = floor(p); p -= ip; 
    vec4 h = vec4(0., s.yz, s.y + s.z) + dot(ip, s);
    //p = p*p*(3. - 2.*p);
    p *= p*p*(p*(p*6. - 15.) + 10.);
    h = mix(fract(sin(h)*43758.5453), fract(sin(h + s.x)*43758.5453), p.x);
    h.xy = mix(h.xz, h.yw, p.y);
    return mix(h.x, h.y, p.z); // Range: [0, 1].
}


// Smooth maximum, based on IQ's smooth minimum.
float smax(float a, float b, float s){
    
    float h = clamp(.5 + .5*(a - b)/s, 0., 1.);
    return mix(b, a, h) + h*(1. - h)*s;
}




// Cheap and nasty 2D smooth noise function with inbuilt hash function -- based on IQ's 
// original. Very trimmed down. In fact, I probably went a little overboard. I think it 
// might also degrade with large time values.
float n2D(vec2 p) {

	vec2 i = floor(p); p -= i; //p *= p*(3. - p*2.);  
    
    p *= p*p*(p*p*6. - p*15. + 10.); 
    
    return dot(mat2(fract(sin(mod(vec4(0, 1, 113, 114) + dot(i, vec2(1, 113)), 6.2831853))*43758.5453))*
                vec2(1. - p.y, p.y), vec2(1. - p.x, p.x) );

}

// FBM -- 4 accumulated noise layers of modulated amplitudes and frequencies.
float fbm(vec2 p){ return n2D(p)*.533 + n2D(p*2.)*.267 + n2D(p*4.)*.133 + n2D(p*8.)*.067; }
float fbmCam(vec2 p){ return n2D(p)*.533 + n2D(p*2.)*.267; }

// The triangle function that Shadertoy user Nimitz has used in various triangle noise demonstrations.
// See Xyptonjtroz - Very cool. Anyway, it's not really being used to its full potential here.
vec2 tri(in vec2 x){return abs(x - floor(x) - .5);} // Triangle function.
vec2 triS(in vec2 x){return cos(x*6.2831853)*.25 + .25;} // Smooth version.

// Height function layers. 
float h1(vec2 p){ return dot(tri(p + tri(p.yx*.5 + .25)), vec2(1)); }
float h1Low(vec2 p){ return dot(triS(p + triS(p.yx*.5 + .25)), vec2(1)); }

// Terrain height function. Just a few layers.
float h(vec2 p) {
    
    float ret = 0., m = 1., a = 1., s = 0.;
    
    //for(int i=0; i<1; i++) {
    
        ret += a*h1Low(p/m);
        //ret += a * n2D(p/m);
        p = r2(1.57/3.73)*p;
        //p = mat2(1, .75, -.75, 1)*p;
        m *= -.375;
        s += a;
        a *= .3;
    //}
    
    for(int i=1; i<5; i++) {
        ret += a*h1(p/m);
        //ret += a * n2D(p/m);
        p = r2(1.57/3.73)*p;
        //p = mat2(1, .75, -.75, 1)*p;
        m *= -.375;
        s += a;
        a *= .3;
    }
    
    ret /= s;
    
    return ret*.25 + ret*ret*ret*.75;

}

// The camera height function, which is a smoother version of the terrain function.
float hLow(vec2 p) {
    
    float ret = 0., m = 1., a = 1., s = 0.;
    for(int i=0; i<2; i++){
        
        ret += a*h1Low(p/m);
        //ret += a * n2D(p/m);
        p = r2(1.57/3.73)*p;
        //p = mat2(1, .75, -.75, 1)*p;
        m *= -.375;
        s += a;
        a *= .3;
    }
    
    ret /= s;
    
    return ret*.25 + ret*ret*ret*.75;

}

// Surface function.
float surfaceFunc(vec3 q){
    
    // Height.
    float sf = h(q.xz/20.);
    
    // Experimental way to dig out a trench.
    sf -= smax(1.4 - q.x*q.x*.5, 0., 1.)*.12;
    
    return (.5 - sf)*5.;
}

// Surface function for the camera.
float surfaceFuncCam(vec3 q){
    
    // Height.
    float sf = hLow(q.xz/20.);
    
    // Experimental way to dig out a trench.
    sf -= smax(1.4 - q.x*q.x*.5, 0., 1.)*.12;
    
    return (.5 - sf)*3.;
}

// Toroidal distance function... Technically, a lot of these are just
// bounds, so not exactly correct, which means shadows, glow, and other
// things can be effected. However, they're cheaper, and you can't really
// tell here.
float distT(vec2 p){
    
    // Try some of the others, if you get bored enough. :)
    
    //return max(abs(p.x)*.866025 + p.y*.5, -p.y); // Triangle.
    //return length(p); // Circle.
    
    p = abs(p);
    return (p.x + p.y)*.7071; // Diamond.
    //return max(p.x, p.y); // Square.
    //return max(p.x*.866025 + p.y*.5, p.y); // Hexagon.
    //return max((p.x + p.y)*.7071 - .4, max(p.x, p.y)); // Octagon.
    
}

// Poloidal distance function. As mentioned above these are technically
// bounds, but they work well enough.
float distP(vec2 p){
    
    //return length(p); // Circle.
    
    p = abs(p);
    return max((p.x + p.y)*.7071 - .06, max(p.x, p.y)); // Beveled square.
    //return max(p.x*.866025 + p.y*.5, p.y); // Hexagon.
    //return max(p.x, p.y); // Square.
    
}

// Global scale, to space out the chrome objects.
const vec3 sc = vec3(16, 4, 4);

float objects(vec3 p){
    
    
    p.xz += sc.xz/2.;
    
    vec3 ip = floor(p/sc)*sc;
    
 
    // Repeating objects across the terrain in Z direction.
    p.xz = vec2(p.x, p.z - ip.z) - sc.xz*.5; // Equivalent to: mod(p.xz, sc) - sc*.5;
    // Repeating objects across the terrain in the X and Z directions.
    //p.xz = (p.xz - ip.xz) - sc.xz*.5; // vec2(p.x, mod(p.z, sc.y)) - sc*.5;
    
    
    // Obtaining the surface height at the center of the grid. This height is used
    // to shift the object to the approximate top of the terrain.
    float sf = surfaceFunc(ip);
    
    // Add the grid height to the object's Y position.
    p.y += sf - 1.8;
    
    // Use the object's Z position to rotate it about the XY plane. This effect looks
    // better on a flat terrain.
    p.xy = r2(sc.z/16. - ip.z/16.)*p.xy;
    // Random XZ rotation, just to show it can be done.
    //p.xz = r2((hash(ip.z) - .5)/2.)*p.xz;
    
    
    const float sz = 1.8;
    const float th = .5;
     
    // Toroidal angle. 
    //float a = atan(p.y, p.x);
    
    // Toroidal distance -- The large radius part.
    p.xy = vec2(distT(p.xy) - sz, p.z);
    // Windows logo warp. :)
    //p.xy = vec2(distT(p.xy) - sz + sin(a*4.)*.125, p.z);
    
    // Mobius-like twisting: Twisting the toroidal axis one full revolution
    // about the poloidal plane... Yeah, it confuses me too. :) Be sure to
    // uncomment the "atan" bit above.
    //p.xz = r2(a)*p.xz;
    
    
    // Poloidal distance. The smaller radius part. 
    float obj = distP(p.xz) - th/2.;
    
     
    // Return the cell object.
    return obj;
    
}


// The distance function. Just some geometric objects and some terrain.
float map(vec3 p){
    
    // Wrap everything around the path.
    p.xy -= path(p.z);
    
    // The surface function. Essentially, the bumps we add to the terrain.
    float sf = surfaceFunc(p);
    
    // The terrain, which we're lowering a bit.
    float terr = p.y + .0 + sf;

    // The chrome objects. 
    float obj = objects(p);
    
    // Store the terrain and object IDs, for sorting later.
    objID = vec4(terr, obj, 0, 0);
    
    // Return the minimum distance.
    return min(terr, obj);
    
}


// Standard raymarching routine.
float trace(vec3 ro, vec3 rd){
   
    float t = 0., d;
    
    for (int i=0; i<80; i++){

        d = map(ro + rd*t);
        
        if(abs(d)<.001*(t*.1 + 1.) || t>FAR) break;
        
        t += d*.866; // Using slightly more accuracy in the first pass.
    }
    
    return min(t, FAR);
}

// Second pass, which is the first, and only, reflected bounce. 
// Virtually the same as above, but with fewer iterations and less 
// accuracy.
//
// The reason for a second, virtually identical equation is that 
// raymarching is usually a pretty expensive exercise, so since the 
// reflected ray doesn't require as much detail, you can relax things 
// a bit - in the hope of speeding things up a little.
float traceRef(vec3 ro, vec3 rd){
    
    float t = 0., d;
    
    for (int i=0; i<56; i++){

        d = map(ro + rd*t);//*rDir;
        
        if(abs(d)<.001*(t*.1 + 1.) || t>FAR) break;
        
        t += d*.9;
    }
    
    return min(t, FAR);
}



// Bump function. 
float bumpSurf3D( in vec3 p, float t){
    
    
    float c, c0 = 0., c1 = 0.;
    
    //float bordTx0Tx1 = oSvObjID.x - oSvObjID.y;
    //const float bordW = .0;
    
    
    // Terrain.
    if(svObjID == 0.){// || abs(bordTx0Tx1)<bordW) {
        
        c0 = fbm(p.xz*8.);
        
        c0 = (1. - c0)/3.;
    }
    /*
    // Metallic objects. The original image has a metallic bump, 
    // but I wanted to keep it smooth.
    if(svObjID == 1.){// || abs(bordTx0Tx1)<bordW) {
    
        
        c1 = (n3D(p*6.)*.66 + n3D(p*12.)*.34);
        c1 = smoothstep(0., .1, n3D(p*3.) - .65)*c1/12.;
        
        //c1 = (1. - smoothstep(.05, .3, c1))/4.;
        
    }
    */
    // Used to fade the bump when objects are near one another, but
    // I feel it's a little bit of overkill, for this particular example.
    //c = mix(c0, c1, step(oSvObjID.y, oSvObjID.x));
    //c = mix(c0, c1, smoothstep(-bordW/2., bordW/2., bordTx0Tx1));
    
    c = c0;
    
    // Fading the bump out over distance.
    return c/(1. + t*t*3.);
    
}


// Standard function-based bump mapping routine: This is the cheaper four tap version. There's
// a six tap version (samples taken from either side of each axis), but this works well enough.
vec3 doBumpMap(in vec3 p, in vec3 nor, float bumpfactor, float t){
    
    // Larger sample distances give a less defined bump, but can sometimes lessen the aliasing.
    const vec2 e = vec2(.001, 0); 
    
    // Gradient vector: vec3(df/dx, df/dy, df/dz);
    float ref = bumpSurf3D(p, t);
    vec3 grad = (vec3(bumpSurf3D(p - e.xyy, t),
                      bumpSurf3D(p - e.yxy, t),
                      bumpSurf3D(p - e.yyx, t)) - ref)/e.x; 
    
    /*
    // Six tap version, for comparisson. No discernible visual difference, in a lot of cases.
    vec3 grad = vec3(bumpSurf3D(p - e.xyy, t) - bumpSurf3D(p + e.xyy, t),
                     bumpSurf3D(p - e.yxy, t) - bumpSurf3D(p + e.yxy, t),
                     bumpSurf3D(p - e.yyx, t) - bumpSurf3D(p + e.yyx, t))/e.x*.5;
    */
       
    // Adjusting the tangent vector so that it's perpendicular to the normal. It's some kind 
    // of orthogonal space fix using the Gram-Schmidt process, or something to that effect.
    grad -= nor*dot(nor, grad);          
         
    // Applying the gradient vector to the normal. Larger bump factors make things more bumpy.
    return normalize(nor + grad*bumpfactor);
	
}



// Cheap shadows are the bain of my raymarching existence, since trying to alleviate artifacts is an excercise in
// futility. In fact, I'd almost say, shadowing - in a setting like this - with limited  iterations is impossible... 
// However, I'd be very grateful if someone could prove me wrong. :)
float softShadow(vec3 ro, vec3 lp, float k, float t){

    // More would be nicer. More is always nicer, but not really affordable... Not on my slow test machine, anyway.
    const int maxIterationsShad = 32; 
    
    vec3 rd = lp - ro; // Unnormalized direction ray.

    float shade = 1.;
    float dist = .0015; // Coincides with the hit condition in the "trace" function.  
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
        dist += clamp(h, .05, .5); 
        
        // Early exits from accumulative distance function calls tend to be a good thing.
        if (h<0. || dist > end) break; 
    }

    // I've added a constant to the final shade value, which lightens the shadow a bit. It's a preference thing. 
    // Really dark shadows look too brutal to me. Sometimes, I'll add AO also just for kicks. :)
    return min(max(shade, 0.) + .2, 1.); 
}


// Standard normal function. It's not as fast as the tetrahedral calculation, but more symmetrical.
vec3 getNormal(in vec3 p) {
	const vec2 e = vec2(.001, 0);
	return normalize(vec3(map(p + e.xyy) - map(p - e.xyy), map(p + e.yxy) - map(p - e.yxy),	map(p + e.yyx) - map(p - e.yyx)));
}



vec3 getSky(vec3 ro, vec3 rd, vec3 lp){

    // Gradient blues, and red, or something.
    vec3 sky = max(mix(vec3(1, .7, .6), vec3(.7, .9, 1.5), rd.y + .0), 0.)/4.; 
    
    // Last minute contrast.
    sky = pow(sky, vec3(1.25))*1.25;
    
    // Horizon strip.
    sky = mix(sky, vec3(1, .1, .05), (1. - smoothstep(-.1, .25, rd.y))*.3);
    
    
	// Blending in the sun.
    float sun = max(dot(normalize(lp - ro), rd), 0.);
    //sky = mix(sky, vec3(.6, 1, .5), pow(sun, 6.)*.5);
    sky = mix(sky, vec3(1, .7, .6)*.9, pow(sun, 6.));
    sky = mix(sky, vec3(1, .9, .8)*1.2, pow(sun, 32.));


    // Subtle, fake sky curvature.
    rd.z *= 1. + length(rd.xy)*.25;
    rd = normalize(rd);

    // A simple way to place some clouds on a distant plane above the terrain -- Based on something IQ uses.
    const float SC = 1e5;
    float tt = (SC - ro.y - .15)/(rd.y + .15); // Trace out to a distant XZ plane.
    vec2 uv = (ro + tt*rd).xz; // UV coordinates.

    // Mix the sky with the clouds, whilst fading out a little toward the horizon (The rd.y bit).
    if(tt>0.) {

        float cl = fbm(1.5*uv/SC);

        // White clouds.
        sky =  mix(sky, vec3(1)*vec3(1, .9, .85), smoothstep(.3, .95, cl)*
                   smoothstep(.475, .575, rd.y*.5 + .5)*.5); 
        // Fake dark shadow. Subtle, but kind of worth doing. :)
        sky =  mix(sky, vec3(0), smoothstep(.0, .95, cl)*fbm(7.*uv/SC)*
                   smoothstep(.475, .575, rd.y*.5 + .5)*.3);

    }

    // Speckles. Not science based, but it looks intering.
    vec3 p = (ro + rd*FAR)/1. + vec3(0, 0, iTime);
    float st = n3D(p)*.66 + n3D(p*2.)*.34;
    st = smoothstep(.1, .9, st - .0);
    sky = mix(sky, vec3(.7, .9, 1), (1. - sqrt(st))*.05);
    
    // The sky color.
    return sky;

}


// Coloring\texturing the scene objects, according to the object IDs.
vec3 getObjectColor(vec3 p, vec3 n){
    
    // Object texture color.

    // Contorting the texture coordinates to math the contorted scene.
    //vec3 txP = p - vec3(path(p.z), 0.);
    p = p - vec3(path(p.z), 0.);

    // Texture value, and individual texture values.
    vec3 tx, tx0, tx1;
    
    float bordTx0Tx1 = oSvObjID.x - oSvObjID.y;
    const float bordW = .075;
    
     
    // If we hit the terrain, or hit the region near the terrain, color
    // it up.
    if(svObjID==0. || abs(bordTx0Tx1)<bordW){
        
        // Noisy color mixing. Tweaked until it looked right.
        vec2 q = p.xz;

        float c = n2D(q)*.6 + n2D(q*3.)*.3 + n2D(q*9.)*.1;
        c = c*c*.7 + sFract(c*4., 12.)*.3;
        c = c*.9 + .2;
        tx0 = mix(vec3(1, .3, .2), vec3(1, .35, .25), n2D(q*6.));
        tx0 *= c;

        float c2 = n2D(q*20.)*.66 + n2D(q*40.)*.34;
        c2 = smoothstep(.1, .6, c2*c2);


        tx0 = mix(tx0*vec3(1.2, .8, .65).zyx, tx0, abs(n));
        tx0 = mix(tx0, vec3(0), c2*.4);

        //tx0 *= mix(vec3(1.2, .8, .6), vec3(1.2, .8, .6).yxz, -n.y*.5 + .5);

        
        /*
        // Extra shadowing. A bit much, in this case.
 		
		// Matches the terrain height function.
        float sf = h(p.xz/20.);
    
        // Experimental way to dig out a trench.
    	sf -= smax(1.4 - q.x*q.x*.5, 0., 1.)*.12;
        
        tx0 *= smoothstep(-.1, .5, sf) + .5;
        */
        
    }
     
    // If the ray hits the metallic object, or close to it, color it dark.
    // The shininess is provided with the relective color. I used to get 
    // this wrong all the time. :)
    if(svObjID==1. || abs(bordTx0Tx1)<bordW) tx1 = vec3(.08, .1, .12);
    
    
    // Return the color, which is either the terrain color, the shiny object color,
    // or if we're in the vicinity of both, make it a mixture of the two.
    tx = mix(tx0, tx1, smoothstep(-bordW, bordW, bordTx0Tx1));
   
    
    return tx; // Return the object color.
    
}

// Using the hit point, unit direction ray, etc, to color the scene. Diffuse, specular, falloff, etc. 
// It's all pretty standard stuff.
vec3 doColor(in vec3 ro, in vec3 sp, in vec3 rd, in vec3 sn, in vec3 lp, float edge, float crv, float ao, float t){
    
    // Initiate the scene (for this pass) to zero.
    vec3 sceneCol = vec3(0);
    
    if(t<FAR){ // If we've hit a scene object, light it up.
    
        vec3 ld = lp - sp; // Light direction vector.
        float lDist = max(length(ld), 0.001); // Light to surface distance.
        ld /= lDist; // Normalizing the light vector.

        // Attenuating the light, based on distance.
        float atten = 1.5/(1. + lDist*0.001 + lDist*lDist*0.0001);

        // Standard diffuse term.
        float diff = max(dot(ld, sn), 0.);
        //diff = pow(diff, 2.)*.66 + pow(diff, 4.)*.34;
        // Standard specualr term.
        float spec = pow(max(dot(reflect(-ld, sn), -rd), 0.), 32.);
        float fres = clamp(1. + dot(rd, sn), 0., 1.);
        //float Schlick = pow( 1. - max(dot(rd, normalize(rd + ld)), 0.), 5.0);
        //float fre2 = mix(.5, 1., Schlick);  //F0 = .5.
        
        // Ramp up the diffuse value on the shiny geometric object. It's a cheap
        // trick to make things look shiny.
        if(svObjID==1.) diff *= diff*2.;

        // Coloring the object, accoring to object ID,.        
        vec3 objCol = getObjectColor(sp, sn);

        
        // Combining the above terms to produce the final scene color.
        sceneCol = objCol*(diff + .35 + fres*fres*0. + vec3(.5, .7, 1)*spec);
        
        
        // Attenuation only. To save cycles, the shadows and ambient occlusion
        // from the first pass only are used.
        sceneCol *= atten;
    
    }
    
    
    // Get the sky color.  
    vec3 sky = getSky(ro, rd, lp);
    
    // Smoothly blend it in, according to the FAR plane distance. Basically, we want it
    // to fade in strongly as we hit the horizon.
    sceneCol = mix(sceneCol, sky, smoothstep(0., .95, t/FAR)); // exp(-.002*t*t), etc.
 
    
  
    // Return the color. Done once for each pass.
    return sceneCol;
    
}

// I keep a collection of occlusion routines... OK, that sounded really nerdy. :)
// Anyway, I like this one. I'm assuming it's based on IQ's original.
float calculateAO(in vec3 pos, in vec3 nor)
{
	float sca = 2., occ = 0.;
    for(int i=0; i<5; i++){
    
        float hr = .01 + float(i)*.5/4.;        
        float dd = map(nor * hr + pos);
        occ += (hr - dd)*sca;
        sca *= .7;
    }
    return clamp(1. - occ, 0., 1.);    
}


void mainImage( out vec4 fragColor, in vec2 fragCoord ){

    // Screen coordinates.
	vec2 uv = (fragCoord - iResolution.xy*.5)/iResolution.y;
    
	
	// Camera Setup.
	vec3 ro = vec3(0, 1.25, iTime*2.); // Camera position, doubling as the ray origin.
	vec3 lk = ro + vec3(0, 0, .5);  // "Look At" position.
    
    
    // Light position. Set in up in the sky above the horizon -- out near the far plane.
    vec3 lp = ro + vec3(-20, 30, 60);
    
   
	// Using the Z-value to perturb the XY-plane.
	// Sending the camera, "look at," and light vector down the path, which is 
	// synchronized with the distance function.
    ro.xy += path(ro.z);
	lk.xy += path(lk.z);
	lp.xy += path(lp.z);
    
    // Using a smoother version of the terrain function to move the camera up and down.
    // Alternatively, you could thread it through some Bezier points... if you're not
    // lazy, like me. :D
    ro.y -= surfaceFuncCam(ro.xyz);
    lk.y -= surfaceFuncCam(lk.xyz);
    

    // Using the above to produce the unit ray-direction vector.
    float FOV = 3.14159/2.; // FOV - Field of view.
    vec3 forward = normalize(lk-ro);
    vec3 right = normalize(vec3(forward.z, 0., -forward.x )); 
    vec3 up = cross(forward, right);

    // rd - Ray direction.
    //vec3 rd = normalize(forward + FOV*uv.x*right + FOV*uv.y*up);
    
    // Warped unit direction vector, for a warped lens effect.
    vec3 rd = (forward + FOV*uv.x*right + FOV*uv.y*up);
    rd = normalize(vec3(rd.xy, rd.z - length(rd.xy)*.15));
    
    
    // Edge and curvature variables. Not used here.
    float edge = 0., crv = 1.;

    
    // FIRST PASS.
    //
    float t = trace(ro, rd); // Trace.

    // Save the object IDs after the first pass.
    svObjID = objID.x<objID.y? 0. : 1.;
    oSvObjID = objID;
    
    // Advancing the ray origin, "ro," to the new hit point.
    vec3 sp = ro + rd*t;
    
    // Retrieving the normal at the hit point, plus the edge and curvature values.
    //vec3 sn = getNormal(sp, edge, crv);
    vec3 sn = getNormal(sp);
    
    // Function based bump mapping. the final value is a fade off with
    // respect to distance.
    sn = doBumpMap(sp, sn, .2, t/FAR);
    

    
    // Fresnel. Handy for all kinds of aesthetic purposes. Not used here.
    //float fr = clamp(1. + dot(rd, sn), 0., 1.);
    
    // Shading. Shadows, ambient occlusion, etc. We're only performing this on the 
    // first pass. Not accurate, but faster, and in most cases, not that noticeable.
    // In fact, the shadows almost didn't make the cut, but it didn't quite feel 
    // right without them.
    float sh = softShadow(sp + sn*.002, lp, 12., t); // Set to "1.," if you can do without them.
    float ao = calculateAO(sp, sn);
    sh = (sh + ao*.3)*ao;
    

    // Retrieving the color at the initial hit point.
    vec3 sceneColor = doColor(ro, sp, rd, sn, lp, edge, crv, ao, t);

    
   
    // SECOND PASS
    
    // Reflected and refracted rays.
    vec3 refl = reflect(rd, sn); // Standard reflection.
    //vec3 refr = refract(rd, sn, 1./1.33); // Water refraction. Note the inverted index.
    
    // We're branching off from the same spot in two directions, so we'll use this so as
    // not to interfere with the original surface point vector, "sp." It was a style
    // choice on my part, but there are other ways.
    vec3 refSp; 
    
    // REFLECTED PASS
    //
    // Standard reflected ray, which is just a reflection of the unit
    // direction ray off of the intersected surface. You use the normal
    // at the surface point to do that.
    
    
    // Making thing complicated for myself, and anyone trying to read this, just so I
    // can blend the terrain into the object... In my defence, the unblended dirt doesn't
    // quite look right sitting against the object. :)
    float bordTx0Tx1 = oSvObjID.x - oSvObjID.y;
    const float bordW = .075; // Blend border width... Kind of.
    
    // If the ray hits the chrome geometric object, or the ground nearby, perform a
    // reflective pass.
    if((svObjID==1. || abs(bordTx0Tx1)<bordW)  && t<FAR){

        // The ray is edged off the surface, as required, but note that it has to be enough
        // to avoid conflict with the break condition in the "reflected" trace algorithm.
        t = traceRef(sp + refl*.002, refl);

        // Save the object IDs after the second pass.
        svObjID = objID.x<objID.y? 0. : 1.;
    	oSvObjID = objID;


        // Advancing the ray from the new origin, "sp," to the new reflected hit point.
        refSp = sp + refl*t;

        // Retrieving the normal at the reflected hit point.
        sn = getNormal(refSp);
        
        // Color at the reflected hit point.
        vec3 reflColor = doColor(sp, refSp, refl, sn, lp, edge, crv, 1., t);
        sceneColor = mix(sceneColor, sceneColor + reflColor*1.33, smoothstep(-bordW/2., bordW/2., bordTx0Tx1));
        //sceneColor = sceneColor + reflColor*1.33;
        //sceneColor = sceneColor*.35 + mix(reflColor, sceneColor, fr*fr*.66 + .34)*2.5;
        
        
        #ifndef THIRD_PASS
        // Very cheap third pass: It'd be nice to put a proper third pass in, but we're 
        // pushing our luck as it is, so we'll make do with a makeshift sky reflection.
      
        //if((svObjID==1. || abs(bordTx0Tx1)<bordW)  && t<FAR){
        if(svObjID == 1. && t<FAR){
            
            refl = reflect(refl, sn);
            vec3 sky = getSky(ro, refl, lp);
            sceneColor = mix(sceneColor, sceneColor*.7 + sceneColor*sky*5.*vec3(1.15, 1, .85), smoothstep(-bordW/2., bordW/2., bordTx0Tx1));
      
            //sceneColor = sceneColor + tpCol*sky*4.;
            //sceneColor = sceneColor*.7 + tpCol;
            //sceneColor = sceneColor*.35 + mix(reflColor, sceneColor, fr*fr*.66 + .34)*2.5;
            
        }
        #endif
    
    }
    
    /*
	// Really bad cheap reflection pass. Only here for debug purposes. 
    //if(svObjID==1. && t<FAR){
    if((svObjID==1. || abs(bordTx0Tx1)<bordW)  && t<FAR){
        
         vec3 sky = getSky(sp, refl, lp);
         sceneColor = mix(sceneColor, sceneColor + sceneColor*sky*20., smoothstep(-bordW/2., bordW/2., bordTx0Tx1));
      
    }
    */
    
    #ifdef THIRD_PASS
    // More correct third pass: Since it's just a reflection off a reflection of one
    // object, we're not using it by default, but it's there if you want it.
    if(svObjID == 1. && t<FAR){
        
        refl = reflect(refl, sn);
        
        t = traceRef(refSp + refl*.002, refl);

        // Save the object IDs after the third pass.
        svObjID = objID.x<objID.y? 0. : 1.;
    	oSvObjID = objID;
        

        // Advancing the ray from the new origin, "sp," to the new reflected hit point.
        refSp = refSp + refl*t;

        // Retrieving the normal at the reflected hit point.
        sn = getNormal(refSp);//*rDir;
        //edge = 0.;

        
        // Color at the reflected hit point.
        vec3 reflColor = doColor(sp, refSp, refl, sn, lp, edge, crv, 1., t);
        sceneColor = mix(sceneColor, sceneColor + reflColor*1.33, smoothstep(-bordW/2., bordW/2., bordTx0Tx1));
     
        //sceneColor = sceneColor + reflColor*1.25; 
    }
    #endif
     
    // APPLYING SHADOWS
    //
    // Multiply the shadow from the first pass by the final scene color. Ideally, you'd check to
    // see if the reflected point was in shadow, and incorporate that too, but we're cheating to
    // save cycles and skipping it. It's not really noticeable anyway.
    sceneColor *= sh;
    
    
    
   
    // POSTPROCESSING
    // Interesting red to blueish mix.
    //sceneColor = mix(sceneColor, pow(min(vec3(1.5, 1, 1)*sceneColor, 1.), vec3(1, 2.5, 12.)), uv.y);
    //sceneColor = pow(max(sceneColor, 0.), vec3(1.25))*1.33; // Adding a bit of contrast.
    //sceneColor *= mix(vec3(1.2, 1, .9).yxz, vec3(1.2, 1, .9).zyx, -rd.y*.5 + .5);
    
    /*
    vec2 u2 = uv*r2(3.14159/6.);
    float overlay = 1. + .35*sin(u2.x*3.14159*iResolution.y/1.5);
    overlay *= 1. + .35*sin(u2.y*3.14159*iResolution.y/1.5); 
    sceneColor *= overlay*1.1;
    */
    
    // Subtle vignette.
    uv = fragCoord/iResolution.xy;
    sceneColor *= pow(16.*uv.x*uv.y*(1. - uv.x)*(1. - uv.y) , .0625)*.5 + .5;
    // Colored varation.
    //sceneColor = mix(pow(min(vec3(1.5, 1, 1)*sceneColor, 1.), vec3(1, 2.5, 12.)).zyx, sceneColor, 
                    // pow( 16.0*uv.x*uv.y*(1.0-uv.x)*(1.0-uv.y) , .125)*.5 + .5);
    
    

    // Clamping the scene color, then presenting to the screen.
	fragColor = vec4(sqrt(max(sceneColor, 0.)), 1);
}

