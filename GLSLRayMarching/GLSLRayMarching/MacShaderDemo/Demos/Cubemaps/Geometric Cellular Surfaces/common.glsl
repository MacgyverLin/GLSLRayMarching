// The cubemap texture resultion.
#define cubemapRes vec2(1024)

// If you use all four channels of one 1024 by 1024 cube face, that would be
// 4096000 storage slots (1024*1024*4), which just so happens be 160 cubed.
// In other words, you can store the isosurface values of a 160 voxel per side
// cube into one cube face of the cubemap.
//
// The voxel cube dimensions -- That's the one you'd change, but I don't really
// see the point, since setting it to the maximum resolution makes the most
// sense. For demonstrative purposes, dropping it to say, vec3(80), will show
// how a decrease in resolution will affect things. Increasing it to above the
// allowable resolution (for one cube face) to say, vec3(200), will display the
// wrapping issues.
//
// On a side note, I'm going to put up an example later that uses four of the 
// cubemap faces, which should boost the resolution to 256... and hopefully,
// not add too much to the complexity, and consequent lag that would follow.
const vec3 dimsVox = vec3(160, 160, 160); 
const vec3 scale = vec3(4, 1, 1);
const vec3 dims = dimsVox/scale;



// Reading into one of the cube faces, according to the face ID. To save on cycles,
// I'd hardcode the face you're after into all but the least costly of situations.
// This particular function is used just once for an update in the "CubeA" tab.
//
// The four cube sides - Left, back, right, front.
// NEGATIVE_X, POSITIVE_Z, POSITIVE_X, NEGATIVE_Z
// vec3(-.5, uv.yx), vec3(uv, .5), vec3(.5, uv.y, -uv.x), vec3(-uv.x, uv.y, -.5).
//
// Bottom and top.
// NEGATIVE_Y, POSITIVE_Y
// vec3(uv.x, -.5, uv.y), vec3(uv.x, .5, -uv.y).
vec4 tx(samplerCube tx, vec2 p, int id){    

    //vec4 rTx;
    
    vec2 uv = fract(p) - .5;
    // It's important to snap to the pixel centers. The people complaining about
    // seam line problems are probably not doing this.
    //p = (floor(p*cubemapRes) + .5)/cubemapRes; 
    
    vec3[6] fcP = vec3[6](vec3(-.5, uv.yx), vec3(.5, uv.y, -uv.x), vec3(uv.x, -.5, uv.y),
                          vec3(uv.x, .5, -uv.y), vec3(-uv.x, uv.y, -.5), vec3(uv, .5));
 
    
    return texture(tx, fcP[id]);
}


vec4 texMapCh(samplerCube tx, vec3 p){
    
    p *= dims;
    int ch = (int(p.x*4.)&3);
    p = mod(floor(p), dims);
    float offset = dot(p, vec3(1, dims.x, dims.x*dims.y));
    vec2 uv = mod(floor(offset/vec2(1, cubemapRes.x)), cubemapRes);
    // It's important to snap to the pixel centers. The people complaining about
    // seam line problems are probably not doing this.
    uv = fract((uv + .5)/cubemapRes) - .5;
    return vec4(1)*texture(tx, vec3(-.5, uv.yx))[ch];
    
}

// Used in conjunction with the function below. When doing things eight times over, any 
// saving is important. If I could trim this down more, I would, but there's wrapping
// and pixel snapping to consider. Having said that, I might take another look at it,
// at some stage.
vec4 txChSm(samplerCube tx, in vec3 p, in int ch){
   
    p = mod(floor(p), dims);
    //vec2 uv = mod(floor(dot(p, vec3(1, dims.x, dims.x*dims.y))/vec2(1, cubemapRes.x)), cubemapRes);
    // I think the fract call below already wraps things, so no "mod" call needed.
    vec2 uv = floor(dot(p, vec3(1, dims.x, dims.x*dims.y))/vec2(1, cubemapRes.x));
    // It's important to snap to the pixel centers. The people complaining about
    // seam line problems are probably... definitely not doing this. :)
    uv = fract((uv + .5)/cubemapRes) - .5;
    return vec4(1)*texture(tx, vec3(-.5, uv.yx))[ch];
    
}

// Smooth texture interpolation that access individual channels: You really need this -- I 
// wish you didn't, but you do. I wrote it a while ago, and I'm pretty confident that it works. 
// The smoothing factor isn't helpful at all, which surprises me -- I'm guessing it molds things 
// to the shape of a cube. Anyway, it's written in the same way that you'd write any cubic 
// interpolation: 8 corners, then a linear interpolation using the corners as boundaries.
//
// It's possible to use more sophisticated techniques to achieve better smoothing, but as you 
// could imagine, they require more samples, and are more expensive, so you'd have to think about 
// it before heading in that direction -- Perhaps for texturing and bump mapping.
vec4 texMapSmoothCh(samplerCube tx, vec3 p){

    // Voxel corner helper vector.
	const vec3 e = vec3(0, 1, 1./4.);

    // Technically, this will center things, but it's relative, and not necessary here.
    //p -= .5/dimsVox.x;
    
    p *= dimsVox;
    vec3 ip = floor(p);
    p -= ip;

    
    int ch = (int(ip.x)&3), chNxt = ((ch + 1)&3);  //int(mod(ip.x, 4.))
    ip.x /= 4.;

    vec4 c = mix(mix(mix(txChSm(tx, ip + e.xxx, ch), txChSm(tx, ip + e.zxx, chNxt), p.x),
                     mix(txChSm(tx, ip + e.xyx, ch), txChSm(tx, ip + e.zyx, chNxt), p.x), p.y),
                 mix(mix(txChSm(tx, ip + e.xxy, ch), txChSm(tx, ip + e.zxy, chNxt), p.x),
                     mix(txChSm(tx, ip + e.xyy, ch), txChSm(tx, ip + e.zyy, chNxt), p.x), p.y), p.z);

 
 	/*   
    // For fun, I tried a straight up average. It didn't work. :)
    vec4 c = (txChSm(tx, ip + e.xxx*sc, ch) + txChSm(tx, ip + e.yxx*sc, chNxt) +
             txChSm(tx, ip + e.xyx*sc, ch) + txChSm(tx, ip + e.yyx*sc, chNxt) +
             txChSm(tx, ip + e.xxy*sc, ch) + txChSm(tx, ip + e.yxy*sc, chNxt) +
             txChSm(tx, ip + e.xyy*sc, ch) + txChSm(tx, ip + e.yyy*sc, chNxt) + txChSm(tx, ip + e.yyy*.5, ch))/9.;
 	*/
    
    return c;

}




// If you want things to wrap, you need a wrapping scale. It's not so important
// here, because we're performing a wrapped blur. Wrapping is not much different
// to regular mapping. You just need to put "p = mod(p, gSc)" in the hash function
// for anything that's procedurally generated with random numbers. If you're using
// a repeat texture, then that'll have to wrap too.
float gSc;


// IQ's vec2 to float hash.
float hash21(vec2 p){
    p = mod(p, gSc);
    return fract(sin(dot(p, vec2(27.609, 157.583)))*43758.5453); 
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
// IQ's exponential-based smooth maximum function. Unlike the polynomial-based
// smooth maximum, this one is associative and commutative.
float smaxExp(float a, float b, float k){

    float res = exp(k*a) + exp(k*b);
    return log(res)/k;
}
*/

// IQ's exponential-based smooth minimum function. Unlike the polynomial-based
// smooth minimum, this one is associative and commutative.
float sminExp(float a, float b, float k){

    float res = exp(-k*a) + exp(-k*b);
    return -log(res)/k;
}


// With the spare cycles, I thought I'd splash out and use Dave's more reliable hash function. :)
//
// Dave's hash function. More reliable with large values, but will still eventually break down.
//
// Hash without Sine.
// Creative Commons Attribution-ShareAlike 4.0 International Public License.
// Created by David Hoskins.
// vec3 to vec3.
vec3 hash33G(vec3 p){

    
    p = mod(p, gSc);
	p = fract(p * vec3(.10313, .10307, .09731));
    p += dot(p, p.yxz + 19.1937);
    p = fract((p.xxy + p.yxx)*p.zyx)*2. - 1.;
    return p;
   
    /*
    // Note the "mod" call. Slower, but ensures accuracy with large time values.
    mat2  m = rot2(mod(iTime, 6.2831853));	
	p.xy = m * p.xy;//rotate gradient vector
    p.yz = m * p.yz;//rotate gradient vector
    //p.zx = m * p.zx;//rotate gradient vector
	return p;
    */

}

// Cheap vec3 to vec3 hash. I wrote this one. It's much faster than others, but I don't trust
// it over large values.
vec3 hash33(vec3 p){ 
   
    
    p = mod(p, gSc);
    //float n = sin(dot(p, vec3(7, 157, 113)));    
    //p = fract(vec3(2097152, 262144, 32768)*n)*2. - 1.; 
    
    //mat2  m = rot2(iTime);//in general use 3d rotation
	//p.xy = m * p.xy;//rotate gradient vector
    ////p.yz = m * p.yz;//rotate gradient vector
    ////p.zx = m * p.zx;//rotate gradient vector
	//return p;
    
    float n = sin(dot(p, vec3(57, 113, 27)));    
    return fract(vec3(2097152, 262144, 32768)*n)*2. - 1.;  

    
    //float n = sin(dot(p, vec3(7, 157, 113)));    
    //p = fract(vec3(2097152, 262144, 32768)*n); 
    //return sin(p*6.2831853 + iTime)*.5; 
}

// This is a variation on a regular 2-pass Voronoi traversal that produces a Voronoi
// pattern based on the interior cell point to the nearest cell edge (as opposed
// to the nearest offset point). It's a slight reworking of Tomkh's example, which
// in turn, is based on IQ's original example. The links are below:
//
// On a side note, I have no idea whether a faster solution is possible, but when I
// have time, I'm going to try to find one anyway.
//
// Voronoi distances - iq
// https://www.shadertoy.com/view/ldl3W8
//
// Here's IQ's well written article that describes the process in more detail.
// https://iquilezles.org/articles/voronoilines
//
// Faster Voronoi Edge Distance - tomkh
// https://www.shadertoy.com/view/llG3zy
//
//
vec3 cellID;
int gIFrame;
//
vec3 Voronoi(in vec3 p, in vec3 rd){
    
    // One of Tomkh's snippets that includes a wrap to deal with
    // larger numbers, which is pretty cool.

 
    vec3 n = floor(p);
    p -= n + .5;
 
    
    // Storage for all sixteen hash values. The same set of hash values are
    // reused in the second pass, and since they're reasonably expensive to
    // calculate, I figured I'd save them from resuse. However, I could be
    // violating some kind of GPU architecture rule, so I might be making 
    // things worse... If anyone knows for sure, feel free to let me know.
    //
    // I've been informed that saving to an array of vectors is worse.
    //vec2 svO[3];
    
    // Individual Voronoi cell ID. Used for coloring, materials, etc.
    cellID = vec3(0); // Redundant initialization, but I've done it anyway.

    // As IQ has commented, this is a regular Voronoi pass, so it should be
    // pretty self explanatory.
    //
    // First pass: Regular Voronoi.
	vec3 mo, o;
    
    // Minimum distance, "smooth" distance to the nearest cell edge, regular
    // distance to the nearest cell edge, and a line distance place holder.
    float md = 8., lMd = 8., lMd2 = 8., lnDist, d;
    
    // Note the ugly "gIFrame" hack. The idea is to force the compiler not
    // to unroll the loops, thus keep the program size down... or something. 
    // GPU compilation is not my area... Come to think of it, none of this
    // is my area. :D
    for( int k=min(-2, gIFrame); k<=2; k++ ){
    for( int j=min(-2, gIFrame); j<=2; j++ ){
    for( int i=min(-2, gIFrame); i<=2; i++ ){
    
        o = vec3(i, j, k);
        o += hash33(n + o) - p;
        // Saving the hash values for reuse in the next pass. I don't know for sure,
        // but I've been informed that it's faster to recalculate the had values in
        // the following pass.
        //svO[j*3 + i] = o; 
  
        // Regular squared cell point to nearest node point.
        d = dot(o, o); 

        if( d<md ){
            
            md = d;  // Update the minimum distance.
            // Keep note of the position of the nearest cell point - with respect
            // to "p," of course. It will be used in the second pass.
            mo = o; 
            cellID = vec3(i, j, k) + n; // Record the cell ID also.
        }
       
    }
    }
    }
    
    // Second pass: Distance to closest border edge. The closest edge will be one of the edges of
    // the cell containing the closest cell point, so you need to check all surrounding edges of 
    // that cell, hence the second pass... It'd be nice if there were a faster way.
    for( int k=min(-3, gIFrame); k<=3; k++ ){
    for( int j=min(-3, gIFrame); j<=3; j++ ){
    for( int i=min(-3, gIFrame); i<=3; i++ ){
        
        // I've been informed that it's faster to recalculate the hash values, rather than 
        // access an array of saved values.
        o = vec3(i, j, k);
        o += hash33(n + o) - p;
        // I went through the trouble to save all sixteen expensive hash values in the first 
        // pass in the hope that it'd speed thing up, but due to the evolving nature of 
        // modern architecture that likes everything to be declared locally, I might be making 
        // things worse. Who knows? I miss the times when lookup tables were a good thing. :)
        // 
        //o = svO[j*3 + i];
        
        // Skip the same cell... I found that out the hard way. :D
        if( dot(o - mo, o - mo)>.00001 ){ 
            
            // This tiny line is the crux of the whole example, believe it or not. Basically, it's
            // a bit of simple trigonometry to determine the distance from the cell point to the
            // cell border line. See IQ's article for a visual representation.
            lnDist = dot(0.5*(o + mo), normalize(o - mo));
            
            // Abje's addition. Border distance using a smooth minimum. Insightful, and simple.
            //
            // On a side note, IQ reminded me that the order in which the polynomial-based smooth
            // minimum is applied effects the result. However, the exponentional-based smooth
            // minimum is associative and commutative, so is more correct. In this particular case, 
            // the effects appear to be negligible, so I'm sticking with the cheaper polynomial-based 
            // smooth minimum, but it's something you should keep in mind. By the way, feel free to 
            // uncomment the exponential one and try it out to see if you notice a difference.
            //
            // // Polynomial-based smooth minimum.
            //lMd = smin(lMd, lnDist, lnDist*.75); //lnDist*.75
            //
            // Exponential-based smooth minimum. By the way, this is here to provide a visual reference 
            // only, and is definitely not the most efficient way to apply it. To see the minor
            // adjustments necessary, refer to Tomkh's example here: Rounded Voronoi Edges Analysis - 
            // https://www.shadertoy.com/view/MdSfzD
            lMd = sminExp(lMd, lnDist, 16.); 
            
            // Minimum regular straight-edged border distance. If you only used this distance,
            // the web lattice would have sharp edges.
            lMd2 = min(lMd2, lnDist);
        }

    }
    }
    }

    // Return the smoothed and unsmoothed distance. I think they need capping at zero... but 
    // I'm not positive.
    return max(vec3(lMd, lMd2, md), 0.);
}
