// The cubemap texture resultion.
#define cubemapRes vec2(1024)

// If you use all four channels of one 1024 by 1024 cube face, that would be
// 4096000 storage slots (1024*1024*4), which just so happens be 160 cubed.
// In other words, you can store the isosurface values of a 160 voxel per side
// cube into one cube face of the cubemap.
//
// The voxel cube dimensions: That's the one you'd change, but I don't really
// see the point, since setting it to the maximum resolution makes the most
// sense. For demonstrative purposes, dropping it to say, vec3(80), will show
// how a decrease in resolution will affect things. Increasing it to above the
// allowable resolution (for one cube face) to say, vec3(200), will display the
// wrapping issues.
//
// On a side note, I'm going to put up an example later that uses four of the 
// cubemap faces, which should boost the resolution to 256... and hopefully,
// not add too much to the complexity, and consequent lag that would follow.
const vec3 dimsVox = vec3(100); 
const vec3 scale = vec3(1, 1, 1);
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

    vec4 rTx;
    
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
vec4 txChSm(samplerCube tx, in vec3 p){
   
    p = mod(floor(p), dims);
    //vec2 uv = mod(floor(dot(p, vec3(1, dims.x, dims.x*dims.y))/vec2(1, cubemapRes.x)), cubemapRes);
    vec2 uv = floor(dot(p, vec3(1, dims.x, dims.x*dims.y))/vec2(1, cubemapRes.x));
    // It's important to snap to the pixel centers. The people complaining about
    // seam line problems are probably... definitely not doing this. :)
    uv = fract((uv + .5)/cubemapRes) - .5;
    return texture(tx, vec3(-.5, uv.yx));
    
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
	//const vec3 e = vec3(0, 1, 1./4.);
	const vec2 e = vec2(0, 1);

    // Technically, this will center things, but it's relative, and not necessary here.
    //p -= .5/dimsVox.x;
    
    p *= dimsVox;
    vec3 ip = floor(p);
    p -= ip;

    
    //int ch = (int(ip.x)&3), chNxt = ((ch + 1)&3);  //int(mod(ip.x, 4.))
    //ip.x /= 4.;
/*
    float c = mix(mix(mix(txChSm(tx, ip + e.xxx, ch).x, txChSm(tx, ip + e.yxx, chNxt).x, p.x),
                     mix(txChSm(tx, ip + e.xyx, ch).x, txChSm(tx, ip + e.yyx, chNxt).x, p.x), p.y),
                 mix(mix(txChSm(tx, ip + e.xxy, ch).x, txChSm(tx, ip + e.yxy, chNxt).x, p.x),
                     mix(txChSm(tx, ip + e.xyy, ch).x, txChSm(tx, ip + e.yyy, chNxt).x, p.x), p.y), p.z);
*/
    
     vec4 txA = txChSm(tx, ip + e.xxx);
     vec4 txB = txChSm(tx, ip + e.yxx);

     float c = mix(mix(mix(txA.x, txB.x, p.x), mix(txA.y, txB.y, p.x), p.y),
                   mix(mix(txA.z, txB.z, p.x), mix(txA.w, txB.w, p.x), p.y), p.z);

 
 	/*   
    // For fun, I tried a straight up average. It didn't work. :)
    vec4 c = (txChSm(tx, ip + e.xxx*sc, ch) + txChSm(tx, ip + e.yxx*sc, chNxt) +
             txChSm(tx, ip + e.xyx*sc, ch) + txChSm(tx, ip + e.yyx*sc, chNxt) +
             txChSm(tx, ip + e.xxy*sc, ch) + txChSm(tx, ip + e.yxy*sc, chNxt) +
             txChSm(tx, ip + e.xyy*sc, ch) + txChSm(tx, ip + e.yyy*sc, chNxt) + txChSm(tx, ip + e.yyy*.5, ch))/9.;
 	*/
    
    return vec4(c);

}




// If you want things to wrap, you need a wrapping scale. It's not so important
// here, because we're performing a wrapped blur. Wrapping is not much different
// to regular mapping. You just need to put "p = mod(p, gSc)" in the hash function
// for anything that's procedurally generated with random numbers. If you're using
// a repeat texture, then that'll have to wrap too.
vec3 gSc;


// Fabrice's concise, 2D rotation formula.
//mat2 rot2(float th){ vec2 a = sin(vec2(1.5707963, 0) + th); return mat2(a, -a.y, a.x); }
// Standard 2D rotation formula - Nimitz says it's faster, so that's good enough for me. :)
mat2 rot2(in float a){ float c = cos(a), s = sin(a); return mat2(c, s, -s, c); }

// mat3 rotation... I did this in a hurry, but I think it's right. :)
mat3 rot(vec3 ang){
    
    vec3 c = cos(ang), s = sin(ang);

    return mat3(c.x*c.z - s.x*s.y*s.z, -s.x*c.y, -c.x*s.z - s.x*s.y*c.z,
                c.x*s.y*s.z + s.x*c.z, c.x*c.y, c.x*s.y*c.z - s.x*s.z,
                c.y*s.z, -s.y, c.y*c.z);
    
}


// 3x1 hash function.
float hash( vec3 p ){ return fract(sin(dot(p, vec3(21.71, 157.97, 113.43)))*45758.5453); }



// IQ's vec2 to float hash.
float hash21(vec2 p){
    return fract(sin(dot(p, vec2(27.609, 157.583)))*43758.5453); 
}

/*
// IQ's unsigned box formula.
float sBoxSU(in vec2 p, in vec2 b, in float sf){

  return length(max(abs(p) - b + sf, 0.)) - sf;
}
*/

// IQ's signed box formula.
float sBoxS(in vec2 p, in vec2 b, in float sf){

  //return length(max(abs(p) - b + sf, 0.)) - sf;
  p = abs(p) - b + sf;
  return length(max(p, 0.)) + min(max(p.x, p.y), 0.) - sf;
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

/*
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
*/

// hash based 3d value noise
vec4 hash41T(vec4 p){
    p = mod(p, vec4(gSc, gSc));
    return fract(sin(p)*43758.5453);
}

// Compact, self-contained version of IQ's 3D value noise function.
float n3DT(vec3 p){
    
	const vec3 s = vec3(27, 111, 57);
	vec3 ip = floor(p); p -= ip; 
    vec4 h = vec4(0., s.yz, s.y + s.z) + dot(ip, s);
    p = p*p*(3. - 2.*p); 
    //p *= p*p*(p*(p*6. - 15.) + 10.);
    h = mix(hash41T(h), hash41T(h + s.x), p.x);
    h.xy = mix(h.xz, h.yw, p.y);
    return mix(h.x, h.y, p.z); // Range: [0, 1].
}


// David_Hoskins puts together some pretty reliable hash functions. This is 
// his unsigned integer based vec3 to vec3 version.
vec3 hash33(vec3 p)
{
    p = mod(p, gSc);
	uvec3 q = uvec3(ivec3(p))*uvec3(1597334673U, 3812015801U, 2798796415U);
	q = (q.x ^ q.y ^ q.z)*uvec3(1597334673U, 3812015801U, 2798796415U);
	return -1. + 2. * vec3(q) * (1. / float(0xffffffffU));
}


// IQ's extrusion formula.
float opExtrusion(in float sdf, in float pz, in float h){
    
    vec2 w = vec2(sdf, abs(pz) - h);
  	return min(max(w.x, w.y), 0.) + length(max(w, 0.));

    /*
    // Slight rounding. A little nicer, but slower.
    const float sf = .002;
    vec2 w = vec2( sdf, abs(pz) - h - sf/2.);
  	return min(max(w.x, w.y), 0.) + length(max(w + sf, 0.)) - sf;
    */
}

// Signed distance to a regular hexagon -- using IQ's more exact method.
float sdHexagon(in vec2 p, in float r){
    
  const vec3 k = vec3(-.8660254, .5, .57735); // pi/6: cos, sin, tan.

  // X and Y reflection.
  p = abs(p);
  p -= 2.*min(dot(k.xy, p), 0.)*k.xy;
    
  // Polygon side.
  return length(p - vec2(clamp(p.x, -k.z*r, k.z*r), r))*sign(p.y - r);
    
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

ivec4 gID;

// Distance metric: Put whatever you want here.
float distMetric(vec3 p, vec3 b, int id){
    
    
    if(id==0){
    	return (dot(p, p));///2.; // Sphere squared.
    }
    else {
        
        //float d2 = sBoxS(p.xy, b.xy, 0.);
        float d2 = sdHexagon(p.xy, min(b.x, b.y));
        return opExtrusion(d2, p.z, b.z);

        
        //return (dot(p, p));
        //return length(p); // Standard spherical Euclidean distance.

        //return max(max(length(p.xy), length(p.yz)), length(p.xz)); // Cylinder cross.

        //p = max(abs(p)*.8660254 + p.yzx*.5, -p);
        //return max(max(p.x, p.y), p.z); // Triangular.

        // Uncomment this for all metrics below.
        p = abs(p) - b;
        
        
        //p = (p + p.yzx)*.7071;
        //return max(max(p.x, p.y), p.z); // Can't remember -- Diamond related. :)


        return max(max(p.x, p.y), p.z); // Cube.
        //return (p.x + p.y + p.z)*.5;//7735; // Octahedron.

        //p = p*.8660254 + p.yzx*.5;
        //return max(max(p.x, p.y), p.z); // Hex.

/*        
        float taper = (p.x + p.y + p.z)/3.*2.*.65 + .35; // Linear gradient of sorts.
        //float taper = p.y + .5; // Original.
        //taper = mix(taper, max(taper, .5), .35); // Flattening the sharp edge a bit.

        p = abs(p)*2.;
        //p = vec2(abs(p.x)*1.5, (p.y)*1.5 - .25)*2.; // Used with triangle.

        float shape = max(max(p.x, p.y), p.z); // Square.
        //float shape = max(p.x*.866025 - p.y*.5, p.y); // Triangle.
        //float shape = max(p.x*.866025 + p.y*.5, p.y); // Hexagon.
        //float shape = max(max(p.x, p.y), (p.x + p.y)*.7071); // Octagon.
        //float shape = length(p); // Circle.
        //float shape = dot(p, p); // Circle squared.


        //shape = (shape - .125)/(1. - .125);
        //shape = smoothstep(0., 1., shape);


        //return shape;
        return max(shape, taper);
*/
    }
    
}

// 2D 3rd-order Voronoi: This is just a rehash of Fabrice Neyret's version, which is in
// turn based on IQ's original. I've simplified it slightly, and tidied up the "if" statements.
//
vec3 Voronoi(in vec3 q, in vec3 sc, in vec3 rotF, float offsF, int id){
    
    
	//const vec3 sc = vec3(1, 2, 1);
    gSc /= sc;
 	vec3 d = vec3(1e5); // 1.4, etc.
    
    float r;
    
    // Widen or tighten the grid coverage, depending on the situation. Note the huge (5x5x5 tap) 
    // spread. That's to cover the third order distances. In a lot of cases, (3x3x3) is enough,
    // but in some, 64 taps (4x4x4), or even more, might be necessary.
    //
    // Either way, this is fine for static imagery, but needs to be reined in for realtime use.
    for(int z = -2; z <= 2; z++){ 
        for(int y = -2; y <= 2; y++){ 
            for(int x =-2; x <= 2; x++){

                vec3 cntr = vec3(x, y, z) - .5;
                vec3 p = q;
				vec3 ip = floor(p/sc) + .5; 
                p -= (ip + cntr)*sc;
                ip += cntr;
                
                // Random position and rotation vectors.
                vec3 rndP = hash33(ip);
                vec3 rndR = hash33(ip + 3.)*6.2831*rotF;

                // Rotate.
                p = rot(rndR)*p;
                //p.xy *= rot2(rndR.x);
                //p.yz *= rot2(rndR.y);
                //p.zx *= rot2(rndR.z);
               
                // Postional offset.
                p -= rndP*offsF*sc;
                
                
                // Scale -- Redundant here.
				vec3 b = sc/2.*vec3(1, 1, 1.5);
                // Distance metric.
                r = distMetric(p, b, id);

                // 1st, 2nd and 3rd nearest distance metrics.
                d.z = max(d.x, max(d.y, min(d.z, r))); // 3rd.
                d.y = max(d.x, min(d.y, r)); // 2nd.
                d.x = min(d.x, r);//smin(d.x, r, .2); // Closest.
                
                // Redundant break in an attempt to ensure no unrolling.
                // No idea whether it works or not.
                if(d.x>1e5) break; 

            }
        }
    }

    
    return min(d, 1.);
    
}