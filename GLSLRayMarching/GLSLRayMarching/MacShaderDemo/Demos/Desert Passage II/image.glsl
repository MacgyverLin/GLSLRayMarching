/*

	Desert Passage II
	-----------------

	Encoding precalculated functions into the cube map faces to create a rocky landscape 
    tunnel flythrough. This has been sitting in my account for a while, but I was too lazy
	to tidy the code up and post it until now. :)

    To be honest, I find wrapped texture precalculation, packing and subsequent unpacking a
	little on the laborious side, so I wouldn't expect anyone to want to try to sift through
	the code in order to decipher it. Regardless, this is just a proof of concept to show
    that it's possible to encode more interesting surfaces (2D or 3D) into textures for 
    realtime use.

    The surfaces themselves are just layers of 3D Voronoi and noise, which are pretty easy 
    to produce, but prohibitively expensive to construct on the fly in realtime. The sand
    pattern comes from another example of mine.

	Encoding 3D information into textures isn't new, and has been performed by myself and 
	others on Shadertoy a few times. This version is unique in the sense that neighboring
	values are packed into all four channels in order to reduce the total number of texture
	calls required for smooth interpolation -- Down from 8 to 2, which is obviously quicker.
	However, as mentioned previously, how well your machine handles this will depend on its
	ability to deal with textures in memory and other things.

	My machine can almost run this in fullscreen at full efficiency. However, if you have a 
    system that doesn't enjoy this, I apologize in advance, but will add that texture
	precalculation is still worth the effort.
	


	Related examples:

	// It won Breakpoint way back in 2009. For anyone not familiar with the demoscene, 
    // it's a big deal. :)
	Elevated - IQ
	https://www.shadertoy.com/view/MdX3Rr


	// One of my favorite simple coloring jobs.
    Skin Peeler - Dave Hoskins
    https://www.shadertoy.com/view/XtfSWX
    Based on one of my all time favorites:
    Xyptonjtroz - Nimitz
	https://www.shadertoy.com/view/4ts3z2

*/

// The far plane. I'd like this to be larger, but the extra iterations required to render the 
// additional scenery starts to slow things down on my slower machine.
#define FAR 100.


// Tri-Planar blending function. Based on an old Nvidia tutorial by Ryan Geiss.
vec3 tex3D( sampler2D t, in vec3 p, in vec3 n ){ 
    
    n = n = max(abs(n) - .2, 0.001); // max(abs(n), 0.001), etc.
    n /= dot(n, vec3(1));
	vec3 tx = texture(t, p.yz).xyz;
    vec3 ty = texture(t, p.zx).xyz;
    vec3 tz = texture(t, p.xy).xyz;
    
    // Textures are stored in sRGB (I think), so you have to convert them to linear space 
    // (squaring is a rough approximation) prior to working with them... or something like that. :)
    // Once the final color value is gamma corrected, you should see correct looking colors.
    return (tx*tx*n.x + ty*ty*n.y + tz*tz*n.z);
}


/* 
// Standard 2x2 hash algorithm.
vec2 hash22(vec2 p) {
    
    // Faster, but probaly doesn't disperse things as nicely as other methods.
    float n = sin(dot(p, vec2(113, 1)));
    return fract(vec2(2097152, 262144)*n)*2. - 1.;

}
*/

// Dave's hash function. More reliable with large values, but will still eventually break down.
//
// Hash without Sine
// Creative Commons Attribution-ShareAlike 4.0 International Public License
// Created by David Hoskins.
// vec2 to vec2.
vec2 hash22(vec2 p){

	vec3 p3 = fract(vec3(p.xyx) * vec3(.1031, .1030, .0973));
    p3 += dot(p3, p3.yzx + 19.19);
    p = fract((p3.xx + p3.yz)*p3.zy)*2. - 1.;
    return p;
    
    // Note the "mod" call. Slower, but ensures accuracy with large time values.
    //mat2  m = r2(mod(iTime, 6.2831853)); 
	//p.xy = m * p.xy;//rotate gradient vector
  	//return p;
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
float gT;

float sand(vec2 p){
    
    // Rotating by 45 degrees. I thought it looked a little better this way. Not sure why.
    // I've also zoomed in by a factor of 4.
    p = vec2(p.y - p.x, p.x + p.y)*.7071/4.;
    
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
    return c1/(1. + gT*gT*.015);
}

/////////


// The path is a 2D sinusoid that varies over time, which depends upon the frequencies and amplitudes.

/*
// Based on the triangle function that Shadertoy user Nimitz has used in various triangle noise 
// demonstrations. See Xyptonjtroz - Very cool.
// https://www.shadertoy.com/view/4ts3z2
// Anyway, these have been modified slightly to emulate the sin and cos waves.
vec3 triS(in vec3 x){ return 1. - abs(fract(x/6.283185307 + .25) - .5)*4.; } // Triangle function.
vec3 triC(in vec3 x){ return 1. - abs(fract(x/6.283185307 + .5) - .5)*4.; } // Triangle function.
vec2 triS(in vec2 x){ return 1. - abs(fract(x/6.283185307 + .25) - .5)*4.; } // Triangle function.
vec2 triC(in vec2 x){ return 1. - abs(fract(x/6.283185307 + .5) - .5)*4.; } // Triangle function.
float triS(in float x){ return (1. - abs(fract(x/6.283185307 + .25) - .5)*4.); } // Triangle function.
float triC(in float x){ return (1. - abs(fract(x/6.283185307 + .5) - .5)*4.); } // Triangle function.

// Quantized version of the path below.
vec2 path(in float z){ 
    //return vec2(0);
    return vec2(triC(z*.18/1.)*2. - triS(z*.1/1.)*4., triS(z*.12/1.)*3. - 1.);
}
*/

// The path is a 2D sinusoid that varies over time, which depends upon the frequencies and amplitudes.
vec2 path(in float z){ 
    //return vec2(0);
    return vec2(cos(z*.18/1.)*2. - sin(z*.1/1.)*4., sin(z*.12/1.)*3. - 1.);
}


// A 2D texture lookup: GPUs don't make it easy for you. If wrapping wasn't a concern,
// you could get away with just one GPU-filtered filtered texel read. However, there
// are seam line issues, which means you need to interpolate by hand, so to speak.
// Thankfully, you can at least store the four neighboring values in one pixel channel,
// so you're left with one texel read and some simple interpolation.
//
// By the way, I've included the standard noninterpolated option for comparisson.
float txFace1(in samplerCube tx, in vec2 p){
   
    
    p *= cubemapRes;
    vec2 ip = floor(p); p -= ip;
    vec2 uv = fract((ip + .5)/cubemapRes) - .5;
    
    #if 0
    
    // The standard noninterpolated option. It's faster, but doesn't look very nice.
    // You could change the texture filtering to "mipmap," but that introduces seam
    // lines at the borders -- which is fine, if they're out of site, but not when you
    // want to wrap things, which is almost always.
    return texture(tx, vec3(.5, uv.y, -uv.x)).x; 
    
    #else
    
    // Smooth 2D texture interpolation using just one lookup. The pixels and
    // its three neighbors are stored in each channel, then interpolated using
    // the usual methods -- similar to the way in which smooth 2D noise is
    // created.
    vec4 p4 = texture(tx, vec3(.5, uv.y, -uv.x)); 

    return mix(mix(p4.x, p4.y, p.x), mix(p4.z, p4.w, p.x), p.y);
    
    // Returning the average of the neighboring pixels, for curiosity sake.
    // Yeah, not great. :)
    //return dot(p4, vec4(.25));
    
    #endif
/*   
    // Four texture looks ups. I realized later that I could precalculate all four of 
    // these, pack them into the individual channels of one pixel, then read them
    // all back in one hit, which is much faster.
    vec2 uv = fract((ip + .5)/cubemapRes) - .5;
    vec4 x = texture(tx, vec3(.5, uv.y, -uv.x)).x;
    uv = fract((ip + vec2(1, 0)+ .5)/cubemapRes) - .5;
    vec4 y = texture(tx, vec3(.5, uv.y, -uv.x)).x;
    uv = fract((ip + vec2(0, 1)+ .5)/cubemapRes) - .5;
    vec4 z = texture(tx, vec3(.5, uv.y, -uv.x)).x;
    uv = fract((ip + vec2(1, 1)+ .5)/cubemapRes) - .5;
    vec4 w = texture(tx, vec3(.5, uv.y, -uv.x)).x;

    return mix(mix(x, y, p.x), mix(z, w, p.x), p.y);
*/  
    
}

// 2D Surface function.
float surfFunc2D(in vec3 p){
    
     return txFace1(iChannel0, p.xz/64.);
}


// The 3D surface function. This one converts the 3D position to a 3D voxel 
// position in the cubemap, then reads the isovalue. Actually, one option does
// that, and the other is forced to read out eight neighboring values to 
// produce a smooth interpolated value. As in real life, it looks nicer, but 
// costs more. :)
float txFace0(in vec3 p){
    
    #if 0
    
    // One sample... Ouch. :D It's a shame this doesn't work, because it's 
    // clearly faster. Unfortunately, it's virtually pointless from an aesthetic
    // aspect, as you can see, but there'd be times when you could get away with it.
    vec3 col = texMapCh(iChannel0, p).xyz;
    
    #else
    
    // Eight samples, for smooth interpolation. Still not as good as the real 
    // thing -- and by that, I mean, calculating on the fly. However, it's 
    // good enough. I'd need to think about it, but I'm wondering whether a
    // four or five point tetrahedral interpolation would work? It makes my
    // head hurt thinking about it right now, but it might. :)
    vec3 col = texMapSmoothCh(iChannel0, p).xyz;
    
    #endif
    
    return col.x;
    
}


// 3D surface function.
float surfFunc3D(in vec3 p){ return txFace0(p/8.); }
    

// Tunnel cross sectional distance.
float dist(in vec2 p){
    
    return length(p);
    //p = abs(p);
    //return max((p.x + p.y)*.7071, max(p.x, p.y));
    
}

// Rock and object ID holders.
int rID = 0;
int svRID;
vec2 vRID;
vec2 svVRID;

// The desert scene. Adding a heightmap to an XZ plane. Not a complicated distance function. :)
float map(vec3 p){
    
    // Retrieve the 3D surface value. Note (in the function) that the 3D value has been 
    // normalized. That way, everything points toward the center.
    float sf3D = surfFunc3D(p);
    
    // Retrieve the 2D surface value from another cube map face.
    float sf2D = surfFunc2D(p);
     
    // Path function.
    vec2 pth = path(p.z); 

    
    // The tunnel itself.
    float tun = 2. - dist((p.xy - pth)*vec2(.7, 1));

    // Second tunnel --- Needs work, so not used here.
    //tun = smax(tun, 2. - dist((p.xy - path(p.z*1.5 + .5)*1.35)), 4.);
    
    
    // Terrain.
    float ter = p.y + (.5 - sf2D)*4. - sf2D*2.75;
 
    // Hollowing the tunnel out of the terrain.
    ter = smax(ter, tun, 3.);
     
    // Adding a bit more of the 2D texture and 3D texture.
    ter += (.5 - sf2D) +  (.5 - sf3D); 

    
    // The sand layer upon which the sand pattern sits -- The 
    // sand pattern itself is added later via bump mapping.
    float snd = p.y - pth.y - sf2D*2. + 2.65; 

    // Storing the terrain and sand layer distance for later usage.
    vRID = vec2(ter, snd);

    // Return the minimum distance.
    return min(ter, snd);
 
}



// Basic raymarcher.
float trace(in vec3 ro, in vec3 rd){

    float t = 0., h;
    
    for(int i=0; i<120; i++){
    
        h = map(ro + rd*t);
        // Note the "t*b + a" addition. Basically, we're putting less emphasis on accuracy, as
        // "t" increases. It's a cheap trick that works in most situations... Not all, though.
        if(abs(h)<.001*(t*.1 + 1.) || t>FAR) break; // Alternative: 0.001*max(t*.25, 1.), etc.
        
        t += h*.85; 
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

  
// Surface bump function..
float bumpSurf3D( in vec3 p){
    
    float n = 0.;
    // Mixing the sand and rock normals at the borders.
    float bordCol0Col1 = svVRID.x - svVRID.y;
    const float bordW = .05;
    
    // Rocks.
    if(svRID==0){
        n = txFace0(p/8.);
        n = mix(n, 1.-txFace0(p/2.), .25);
        n = mix(n, txFace0(p*1.5), .1);
        
        n = mix(.5, n, smoothstep(0., bordW, -(bordCol0Col1)));
    }
    else{
        
        // Sand.
        n = sand(p.xz*1.25);
        n = mix(.5, n, smoothstep(0., bordW, (bordCol0Col1)));
       
/*       
        // Sand pattern alternative.
        p *= vec3(1.65, 2.2, 3.85)/1.25;
        //float ns = n2D(p.xz)*.57 + n2D(p.xz*2.)*.28 + n2D(p.xz*4.)*.15;
        float ns = n3D(p)*.57 + n3D(p*2.)*.28 + n3D(p*4.)*.15;

        // vec2 q = rot2(-3.14159/5.)*p.xz;
        // float ns1 = grad(p.z*32., 0.);//*clamp(p.y*5., 0., 1.);//smoothstep(0., .1, p.y);//
        // float ns2 = grad(q.y*32., 0.);//*clamp(p.y*5., 0., 1.);//smoothstep(0., .1, p.y);//
        // ns = mix(ns1, ns2, ns);

        ns = (1. - abs(smoothstep(0., 1., ns) - .5)*2.);
        ns = mix(ns, smoothstep(0., 1., ns), .65);

        // Use the height to taper off the sand edges, before returning.
        //ns = ns*smoothstep(0., .2, p.y - .075);
    

        // A surprizingly simple and efficient hack to get rid of the super annoying Moire pattern 
        // formed in the distance. Simply lessen the value when it's further away. Most people would
        // figure this out pretty quickly, but it took far too long before it hit me. :)
        n = ns/(1. + gT*gT*.015);
*/        
        
        
    }
    
    
    
    
    //return mix(min(n*n*2., 1.), surfFunc3D(p*2.), .35);
    return n;//min(n*n*2., 1.);
    
    /*
    // Obtaining some terrain samples in order to produce a gradient
    // with which to distort the sand. Basically, it'll make it look
    // like the underlying terrain it effecting the sand. The downside
    // is the three extra taps per bump tap... Ouch. :) Actually, it's
    // not that bad, but I might attempt to come up with a better way.
    float n = txFace0(p);
    vec3 px = p + vec3(.001, 0, 0);
    float nx = txFace0(px);
    vec3 pz = p + vec3(0, 0, .001);
    float nz = txFace0(pz);
    
    // The wavy sand, that has been perturbed by the underlying terrain.
    return sand(p.xz + vec2(n - nx, n - nz)/.001*1.);
    */

}

// Standard function-based bump mapping routine: This is the cheaper four tap version. There's
// a six tap version (samples taken from either side of each axis), but this works well enough.
vec3 doBumpMap(in vec3 p, in vec3 nor, float bumpfactor){
    
    // Larger sample distances give a less defined bump, but can sometimes lessen the aliasing.
    const vec2 e = vec2(.001, 0); 
    
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



// I keep a collection of occlusion routines... OK, that sounded really nerdy. :)
// Anyway, I like this one. I'm assuming it's based on IQ's original.
float calcAO(in vec3 p, in vec3 n)
{
	float sca = 2., occ = 0.;
    for( int i = 0; i<5; i++ ){
    
        float hr = float(i + 1)*.2/5.;        
        float d = map(p + n*hr);
        occ += (hr - d)*sca;
        sca *= .7;
    }
    
    return clamp(1. - occ, 0., 1.);  
    
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
    float end = max(length(rd), .0001);
    //float stepDist = end/float(maxIterationsShad);
    rd /= end;

    // Max shadow iterations - More iterations make nicer shadows, but slow things down. Obviously, the lowest 
    // number to give a decent shadow is the best one to choose. 
    for (int i = min(iFrame, 0); i<maxIterationsShad; i++){

        float d = map(ro + rd*t);
        shade = min(shade, k*d/t);
        //shade = min(shade, smoothstep(0., 1., k*h/dist)); // Subtle difference. Thanks to IQ for this tidbit.
        // So many options here, and none are perfect: dist += min(h, .2), dist += clamp(h, .01, stepDist), etc.
        t += clamp(d, .05, .5); 
        
        
        // Early exits from accumulative distance function calls tend to be a good thing.
        if (d<0. || t>end) break; 
    }

    // Sometimes, I'll add a constant to the final shade value, which lightens the shadow a bit --
    // It's a preference thing. Really dark shadows look too brutal to me. Sometimes, I'll add 
    // AO also just for kicks. :)
    return max(shade, 0.); 
}

 
// Standard sky routine: Gradient with sun and overhead cloud plane. I debated over whether to put more 
// effort in, but the dust is there and I'm saving cycles. I originally included sun flares, but wasn't 
// feeling it, so took them out. I might tweak them later, and see if I can make them work with the scene.
vec3 getSky(vec3 ro, vec3 rd, vec3 ld){ 
    
    // Sky color gradients.
    vec3 col = vec3(.8, .7, .5), col2 = vec3(.4, .6, .9);
    
    //return mix(col, col2, pow(max(rd.y*.5 + .9, 0.), 5.));  // Probably a little too simplistic. :)
     
    // Mix the gradients using the Y value of the unit direction ray. 
    vec3 sky = mix(col, col2, pow(max(rd.y + .15, 0.), .5));
      
    // Adding the sun.
    float sun = clamp(dot(ld, rd), 0., 1.);
    sky += vec3(1, .7, .4)*vec3(pow(sun, 16.))*.2; // Sun flare, of sorts.
    sun = pow(sun, 32.); // Not sure how well GPUs handle really high powers, so I'm doing it in two steps.
    sky += vec3(1.6, 1, .5)*vec3(pow(sun, 32.))*.35; // Sun.
    
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
    return sky*vec3(1.1, 1, .9);
}



// Smooth fract function.
float sFract(float x, float sf){
    
    x = fract(x);
    return min(x, (1. - x)*x*sf);
    
}

// hash based 3d value noise
vec4 hash41(vec4 p){
    return fract(sin(p)*43758.5453);
}

// Compact, self-contained version of IQ's 3D value noise function.
float n3D(vec3 p){
    
	const vec3 s = vec3(27, 111, 57);
	vec3 ip = floor(p); p -= ip; 
    vec4 h = vec4(0., s.yz, s.y + s.z) + dot(ip, s);
    p = p*p*(3. - 2.*p); 
    //p *= p*p*(p*(p*6. - 15.) + 10.);
    h = mix(hash41(h), hash41(h + s.x), p.x);
    h.xy = mix(h.xz, h.yw, p.y);
    return mix(h.x, h.y, p.z); // Range: [0, 1].
}

// The grungey texture -- Kind of modelled off of the metallic Shadertoy texture,
// but not really. Most of it was made up on the spot, so probably isn't worth 
// commenting. However, for the most part, is just a mixture of colors using 
// noise variables.
vec3 GrungeTex(in vec3 p){
    
 	// Some fBm noise.
    //float c = n2D(p*4.)*.66 + n2D(p*8.)*.34;
    float c = n3D(p*3.)*.57 + n3D(p*7.)*.28 + n3D(p*15.)*.15;
   
    // Noisey bluish red color mix.
    vec3 col = mix(vec3(.25, .115, .02), vec3(.35, .5, .65), c);
    // Running slightly stretched fine noise over the top.
    col *= n3D(p*vec3(150., 150., 150.))*.5 + .5; 
    
    // Using a smooth fract formula to provide some splotchiness... Is that a word? :)
    col = mix(col, col*vec3(.75, .95, 1.1), sFract(c*4., 12.));
    col = mix(col, col*vec3(1.2, 1, .8)*.8, sFract(c*5. + .35, 12.)*.5);
    
    // More noise and fract tweaking.
    c = n3D(p*8. + .5)*.7 + n3D(p*18. + .5)*.3;
    c = c*.7 + sFract(c*5., 16.)*.3;
    col = mix(col*.6, col*1.4, c);
    
    // Clamping to a zero to one range.
    return clamp(col, 0., 1.);
    
}




void mainImage( out vec4 fragColor, in vec2 fragCoord ){	


	
	// Screen coordinates.
	vec2 u = (fragCoord - iResolution.xy*.5)/iResolution.y;
	
	// Camera Setup.     
	vec3 ro = vec3(0, 4.*0. - .5, iTime*5.); // Camera position, doubling as the ray origin.
    vec3 lookAt = ro + vec3(0, -.2*0., .5);  // "Look At" position.
    
    //vec3 lp = vec3(0, 0, ro.z + 8.);
    // Usually, you'd just make this a unit directional light, and be done with it, but I
    // like some of the angular subtleties of point lights, so this is a point light a
    // long distance away. Fake, and probably not advisable, but no one will notice.
    vec3 lp = vec3(0, 0, ro.z) + vec3(FAR*.125, FAR*.35, FAR);
	
	// Using the Z-value to perturb the XY-plane.
	// Sending the camera and "look at" vectors down the tunnel. The "path" function is 
	// synchronized with the distance function.
	ro.xy += path(ro.z);
	lookAt.xy += path(lookAt.z);
    //lp.xy += path(lp.z);
 
    
    // Using the above to produce the unit ray-direction vector.
    float FOV = 3.14159265/2.5; // FOV - Field of view.
    vec3 forward = normalize(lookAt - ro);
    vec3 right = normalize(vec3(forward.z, 0, -forward.x )); 
    vec3 up = cross(forward, right);

    // rd - Ray direction.
    vec3 rd = normalize(forward + FOV*u.x*right + FOV*u.y*up);
    
    // Swiveling the camera about the XY-plane (from left to right) when turning corners.
    // Naturally, it's synchronized with the path in some kind of way.
	rd.xy = rot2( path(lookAt.z).x/32.)*rd.xy;
    
  

	// Raymarching.
    float t = trace(ro, rd);
    
    gT = t;
    
    svVRID = vRID;
    svRID = vRID[0]<vRID[1]? 0 : 1;
    
   
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
        
        lDist /= FAR; // Scaling down the distance to something workable for calculations.
        float atten = 1./(1. + lDist*lDist*.025);

        
        // Texture scale factor.        
        const float tSize = 1./8.;
        
        // Extra shading in the sand crevices.
        float bSurf = bumpSurf3D(sp);
        
        vec3 oSn = sn;
        
        float bf = svRID == 0? .5 : .05;
        sn = doBumpMap(sp, sn, bf);
         
        
        // Soft shadows and occlusion.
        float sh = softShadow(sp, lp, sn, 8.); 
        float ao = calcAO(sp, sn); // Amb, 6.ient occlusion.
 
        
        float dif = max( dot( ld, sn ), 0.); // Diffuse term.
        float spe = pow(max( dot( reflect(-ld, sn), -rd ), 0.), 32.); // Specular term.
        float fre = clamp(1.0 + dot(rd, sn), 0., 1.); // Fresnel reflection term.
 
        // Schlick approximation. I use it to tone down the specular term. It's pretty subtle,
        // so could almost be aproximated by a constant, but I prefer it. Here, it's being
        // used to give a sandstone consistency... It "kind of" works.
		float Schlick = pow( 1. - max(dot(rd, normalize(rd + ld)), 0.), 5.);
		float fre2 = mix(.2, 1., Schlick);  //F0 = .2 - Dirt... or close enough.
       
        // Overal global ambience. It's made up, but I figured a little occlusion (less ambient light
        // in the corners, etc) and reflectance would be in amongst it... Sounds good, anyway. :)
        float amb = ao*.25;
        

        // 3D surface function.
        float sf3D = surfFunc3D(sp);
        
         
        // Coloring the soil - based on depth. Based on a line from Dave Hoskins's "Skin Peeler."
        col = clamp(mix(vec3(1.2, .75, .5)*vec3(1, .9, .8), vec3(.7, .5, .25), (sp.y - 1.)*.15), 
                vec3(.5, .25, .125), vec3(1));
          
        //col = min(vec3(1.2, .75, .5)*vec3(1, .9, .8), 1.);
    
         
        // Setting the terrain color and sand color. 
        vec3 col0 = col, col1 = col;
        
        // Trick to mix things at the borders for a less brutal transition.
        float bordCol0Col1 = svVRID.x - svVRID.y;
        const float bordW = .1;
        /*
        if(svRID==0 || abs(bordCol0Col1)<bordW){
 
            // Coloring the soil.
        	vec3 colR = mix(vec3(1, .8, .5), vec3(.5, .25, .125), clamp((sp.y + 2.)*.5, 0., 1.));
        	col0 = mix(col0, colR, .5);
            
        }
        */
        
        if(svRID==1 || abs(bordCol0Col1)<bordW){
            col1 = mix(col1*vec3(1.5), vec3(1, .9, .8), .2);
        }        
        // Return the color, which is either the sandy terrain color, the object color,
    	// or if we're in the vicinity of both, make it a mixture of the two.
    	col = mix(col0, col1, smoothstep(-bordW, bordW, bordCol0Col1));
        
         
       
        // Finer details.
        col = mix(col*vec3(1.05, 1, 1.2)/4., col, smoothstep(0., 1., sf3D));
        col = mix(col/1.35, col*1.35, bSurf);
        
        // Grungey overlay: Add more to the rock surface than the sand.
        // Surface texel.
        vec3 tx = GrungeTex(sp/4.);//*vec3(1.2, 1.15, 1.05);//
        col = mix(col, col*tx*3., mix(.5, .25, smoothstep(-bordW, bordW, bordCol0Col1))); 
        
        
        // Combining all the terms from above. Some diffuse, some specular - both of which are
        // shadowed and occluded - plus some global ambience. Not entirely correct, but it's
        // good enough for the purposes of this demonstation.        
        col = col*((dif + amb + vec3(1, .97, .92)*spe*fre2*1. +  vec3(1, .7, .4)*fre*spe*0.));
        
        
        // A bit of sky reflection. Not really accurate, but I've been using fake physics since the 90s. :)
        vec3 refSky = getSky(sp, reflect(rd, sn), ld);
        col += col*refSky*.05 + refSky*fre*fre2*.15; 
        
 
        // Applying the shadows and ambient occlusion.
        col = col*ao*atten*(sh + .25);
 
    }
    
  
    // Combine the scene with the sky using some cheap volumetric substance.
    vec3 gLD = normalize(lp - vec3(0, 0, ro.z));
    vec3 sky = getSky(ro, rd, gLD);
    
    // Simulating sun scatter over the sky and terrain: IQ uses it in his Elevated example.
    sky += vec3(1., .6, .2)*pow(max(dot(rd, gLD), 0.), 16.)*.25;
    sky = min(sky, 1.);
    
    //col = mix(col, sky, min(t*t*1.5/FAR/FAR, 1.)); // Quadratic fade off. More subtle.
    col = mix(col, sky, smoothstep(0., .99, t/FAR)); // Linear fade. Much dustier. I kind of like it.
    
    
    // Greyish tone.
    //col = mix(col, vec3(1)*dot(col, vec3(.299, .587, .114)), .5);
    
    
    // Standard way to do a square vignette. Note that the maxium value value occurs at "pow(0.5, 4.) = 1./16," 
    // so you multiply by 16 to give it a zero to one range. This one has been toned down with a power
    // term to give it more subtlety.
    u = fragCoord/iResolution.xy;
    col = min(col, 1.)*pow( 16.*u.x*u.y*(1. - u.x)*(1. - u.y) , .0625);
 
    // Done.
	fragColor = vec4(sqrt(clamp(col, 0., 1.)), 1);
}