

// Producing hexagons with offset vertices can be a little painful, but it's 
// doable. Regular hexagon grids are almost trivial, but don't really suit this
// example. Either way, comment this out to see.
#define OFFSET_VERTICES

// Changing the Bavarian look to a Mediterrainean one... Actually, with more of a 
// limestone sheen, it'd remind me slightly of the super crowded Maltese coastline.
//#define ARID

// Quantizing the height levels. More expensive, if not precalated, but it looks 
// a little neater -- Windows line up with the terraced levels, etc.
#define QUANTIZE_HEIGHT

// Quantize the water level, meaning make each water block move independently... Or 
// is it discreetize, or perhaps noncontinuous? Either way, you know what I mean. :)
#define QUANTIZE_WATER

// Grayscale, for that artsy look. Well, it's close to greyscale, but not quite. :)
//#define GRAYSCALE


// Quantization levels.
#define LEVELS 19.
#define WLEV 7.22 //floor(LEVELS*.38)



// Work around for the time variable.
float gTime = 0.;
void setTime(float tm){ gTime = tm; }
    



// Grid pattern repeat scale. Baking wrapped distance fields into textures can be 
// a little fiddly.
float repSc = 1024./32.;

// This sets the scale of the extruded shapes. Because of the way I've calculated
// things, the scale needs to be even divisors and each term needs to be equal --
// I use it in other applications where I can use two different numbers though. 
// As above, if you choose this option, a reset will be necessary. Ie. Hit the 
// back button.
#define GSCALE vec2(1./8.)
 
// Flat top hexagon.
#define FLAT_TOP
#ifdef FLAT_TOP
// Vertices and mid edge points: Clockwise from the left.
vec4[3] vID = vec4[3](vec4(-2./3., 0, -2./6., .5), vec4(2./6., .5, 2./3., 0), vec4(2./6., -.5, -2./6., -.5)); 
vec4[3] eID = vec4[3](vec4(-.5, .25, 0, .5), vec4(.5, .25, .5, -.25), vec4(0, -.5, -.5, -.25));
#else
// Vertices and mid edge points: Clockwise from the bottom left. -- Basically, the ones 
// above rotated anticlockwise. :)
vec4[3] vID = vec4[3](vec4(-.5, -2./6., -.5, 2./6.), vec4(0, 2./3.,.5, 2./6.), vec4(.5, -2./6., 0, -2./3.));
vec4[3] eID = vec4[3](vec4(-.5, 0, -.25, .5), vec4(.25, .5, .5, 0), vec4(.25, -.5, -.25, -.5));
#endif

////////

// Reading from various cube map faces.
vec4 tx0(samplerCube tx, vec2 p){    

    return textureLod(tx, vec3(-.5, fract(p.yx) - .5), 0.);
    //return texture(tx, vec3(-.5, fract(p.yx) - .5));
}
/*
vec4 tx1(samplerCube tx, vec2 p){    

    p = fract(p) - .5;
    return textureLod(tx,  vec3(.5, p.y, -p.x), 0.);
    //return texture(tx, vec3(.5, p.y, -p.x));
}

vec4 tx2(samplerCube tx, vec2 p){    

    p = fract(p) - .5;
    return textureLod(tx,  vec3(p.x, -.5, p.y), 0.);
    //return texture(tx, vec3(p.x, -.5, p.y));
}
*/
vec4 tx5(samplerCube tx, vec2 p){    

   
    return textureLod(tx, vec3(fract(p) - .5, .5), 0.);
    //return texture(tx, vec3(fract(p) - .5, .5));
}

/*
vec4 tx1B(samplerCube tx, vec2 p){    

    p = (floor(p*1024.) + .5)/1024.;
    p = fract(p) - .5;
    
    return textureLod(tx, vec3(.5, p.y, -p.x), 0.);
    //return texture(tx, vec3(.5, p.y, -p.x));
}

vec4 tx2B(samplerCube tx, vec2 p){    

    p = (floor(p*1024.) + .5)/1024.;
    p = fract(p) - .5;
    
    return textureLod(tx, vec3(p.x, -.5, p.y), 0.);
    //return texture(tx, vec3(.5, p.y, -p.x));
}
*/


// Standard 2D rotation formula.
mat2 rot2(in float a){ float c = cos(a), s = sin(a); return mat2(c, -s, s, c); }


// IQ's vec2 to float hash.
float hash21(vec2 p){  return fract(sin(dot(p, vec2(27.609, 57.583)))*43758.5453); }

/*
// IQ's vec2 to float hash.
vec2 hash22B(vec2 p){ 
   
    p = (floor(p*1024.) + .5)/1024.;
    p = mod(p*repSc*GSCALE*2., repSc);
    p = vec2(dot(p, vec2(27.619, 113.583)), dot(p, vec2(57.527, 85.491)));
    p = fract(sin(p)*43758.5453)*2. - 1.; 
    return p;
    
    
    //return sin(p*6.2831853 + gTime);//mix(p, sin(p*6.2831853 + iTime), .35);
    
}
*/
// Based on IQ's hash formula.
vec4 hash42B(vec4 p){ 

    p = (floor(p*1024.) + .5)/1024.;
  
    p = mod(p*repSc*GSCALE.x*2., repSc);
   
    p = vec4(dot(p.xy, vec2(27.619, 113.583)), dot(p.xy, vec2(57.527, 85.491)),
             dot(p.zw, vec2(27.619, 113.583)), dot(p.zw, vec2(57.527, 85.491)));
                                                  
    p = fract(sin(p)*43758.5453)*2. - 1.; 
    return p;
    
    
    //return sin(p*6.2831853 + gTime);//mix(p, sin(p*6.2831853 + iTime), .35);
    
}

/*
// IQ's vec2 to float texture hash.
vec2 hash22T(sampler2D tx, vec2 p){ 
    
    //   p = (floor(p*1024.) + .5)/1024.;
    return textureLod(tx, p, 0.).xy;
    
}
*/ 

// vec2 to vec2 hash.
vec2 hash22C(vec2 p) { 

    p = mod(p, repSc);
    // Faster, but doesn't disperse things quite as nicely. However, when framerate
    // is an issue, and it often is, this is a good one to use. Basically, it's a tweaked 
    // amalgamation I put together, based on a couple of other random algorithms I've 
    // seen around... so use it with caution, because I make a tonne of mistakes. :)
    vec2 n = sin(vec2(dot(p, vec2(27.29, 57.81)), dot(p, vec2(7.14, 113.43))));
    return fract(vec2(262144.1397, 32768.8793)*n)*2. - 1.; 
    
    // Animated.
    //p = fract(vec2(262144, 32768)*n);
    //return sin(p*6.2831853 + gTime); 
    
}

// Based on IQ's gradient noise formula.
float n2D3G( in vec2 p ){
   
    vec2 i = floor(p); p -= i;
    
    vec4 v;
    v.x = dot(hash22C(i), p);
    v.y = dot(hash22C(i + vec2(1, 0)), p - vec2(1, 0));
    v.z = dot(hash22C(i + vec2(0, 1)), p - vec2(0, 1));
    v.w = dot(hash22C(i + 1.), p - 1.);

#if 1
    // Quintic interpolation.
    p = p*p*p*(p*(p*6. - 15.) + 10.);
#else
    // Cubic interpolation.
    p = p*p*(3. - 2.*p);
#endif

    return mix(mix(v.x, v.y, p.x), mix(v.z, v.w, p.x), p.y);
    
}


// Height map. Just a couple of gradient noise layers. 
// By the way, because this is precalculated, you could
// make this as extravagent as you wished.
float hm(in vec2 p){ 

    p *= repSc;
    
    // p = (floor(p*1024.) + .5)/1024.;
    //p /= 24.;
      
    return n2D3G(p)*.5 + .5;
 
    //return (n2D3G(p)*.66 + n2D3G(p*2.)*.34)*.5 + .5;
 
    
}

// Height map value, which is just the pixel's greyscale value.
//float hm(in vec2 p){ return dot(getTex(p), vec3(.299, .587, .114)); }


// IQ's extrusion formula.
float opExtrusion(in float sdf, in float pz, in float h){
    
    vec2 w = vec2(sdf, abs(pz) - h);
  	return min(max(w.x, w.y), 0.) + length(max(w, 0.));

    /*
    // Slight rounding. A little nicer, but slower.
    const float sf = .002;
    vec2 w = vec2( sdf, abs(pz) - h) + sf;
  	return min(max(w.x, w.y), 0.) + length(max(w, 0.)) - sf;
    */
}

// IQ's distance to a regular pentagon, without trigonometric functions. 
// Other distances here:
// https://iquilezles.org/articles/distfunctions2d
//
#define NV 6
//
float sdPoly(in vec2 p, in vec2[NV] v){

    const int num = v.length();
    float d = dot(p - v[0],p - v[0]);
    float s = 1.0;
    for( int i = 0, j = num - 1; i < num; j = i, i++){
    
        // distance
        vec2 e = v[j] - v[i];
        vec2 w =    p - v[i];
        vec2 b = w - e*clamp(dot(w, e)/dot(e, e), 0., 1. );
        d = min( d, dot(b,b) );

        // winding number from http://geomalgorithms.com/a03-_inclusion.html
        bvec3 cond = bvec3( p.y>=v[i].y, p.y<v[j].y, e.x*w.y>e.y*w.x );
        if( all(cond) || all(not(cond)) ) s*=-1.0;  
    }
    
    return s*sqrt(d);
}



// IQ's unsigned box formula.
float sBoxS(in vec2 p, in vec2 b, in float sf){

  return length(max(abs(p) - b + sf, 0.)) - sf;
}

// IQ's standard box function.
float sBox(in vec2 p, in vec2 b){
   
    vec2 d = abs(p) - b;
    return min(max(d.x, d.y), 0.) + length(max(d, 0.));
}

// This will draw a box (no caps) of width "ew" from point "a "to "b". I hacked
// it together pretty quickly. It seems to work, but I'm pretty sure it could be
// improved on. In fact, if anyone would like to do that, I'd be grateful. :)
float lBox(vec2 p, vec2 a, vec2 b, float ew){
    
    float ang = atan(b.y - a.y, b.x - a.x);
    p = rot2(ang)*(p - mix(a, b, .5));

    vec2 l = vec2(length(b - a), ew);
    return sBox(p, (l + ew)/2.) ;
}

/*
// This is a bound. Technically, it's not a proper distance field, but for
// this example, no one will notice. :)
float sHexS(in vec2 p, in vec2 b){
    
    p = abs(p);
    return max(p.x*.8660254 + p.y*.5 - b.x, p.y - b.y);
    //return max(p.y*.8660254 + p.x*.5, p.x) - b.x;;
}
*/

 



