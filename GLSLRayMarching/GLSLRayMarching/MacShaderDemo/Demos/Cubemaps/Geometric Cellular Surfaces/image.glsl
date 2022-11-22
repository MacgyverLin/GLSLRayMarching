/*


	Geometric Cellular Surfaces
	---------------------------


	Precalculating isosurface values then packing them into the cubemap to produce scenes 
    in realtime that would normally be prohibitively expensive.

	I put up an example a short while back that involved packing a 100 sided voxel cube
    into one pixel channel of one face of the cubemap. I mentioned that if using all four 
	channels, you could increase the resolution to 160 pixels per dimension, so that is
	what I've done here. From here, it's possible to pack a 256 pixel per side cube into 
    four faces of the cubemap, or pack other 3D surfaces into the other cubemap faces,
	but for now, I'm concentrating on packing a 160 resolution cube into one face of a 
    cubemap. Of secondary importance, I'm also reading an interpolated 2D surface from 
	another face, in order to demonstrate the cubemap's versatility.

	For some reason, packing 3D coordinates into a 2D texture is a task that I don't
	particularly enjoy -- It reminds me of the "trying to fit a square peg into a round 
    hole" expression. I don't even enjoy coding the relatively easy one channel version, 
    let alone the extra fiddly four channel one. For that reason, I procrastinated a 
    while before putting this together... To be fair, Shadertoy has not exactly been 
    inundated with 3D packing examples, four channels or otherwise, so I'm guessing most 
    others feel the same way. Furthermore, I had to code this from scratch. Anyway, I'm 
    going to try my best to explain the process -- while it's still fresh in my head, so 
    others can benefit.

	Basically, you're taking a voxelated cube of dimensions X, Y and Z, then filling the 
    individual voxels with precalculated values -- In this case, it will be a 3D surface 
    isovalue at each position. In order to do this, you need to take the pixels on a 2D 
    texture surface (we'll be using cubemap faces), convert them to 3D positions, fill 
    them with values, then read them back again -- usually from within the raymarching 
    loop, but you might simply wish to texture or bump map a surface, etc.

	The process is quite simple, once you get your head around it. The trick is to think
	of both the 2D space and the 3D space in one dimensional form. For instance, a
    16 by 16 texture is 256 pixels, regardless of how things wrap. A 6 pixel-per-side voxel
	cube is 216 pixels, regardless of how it wraps. Therefore, all you need to do is 
    convert your 2D coordinates to a one dimensional lookup number (X + Y*texDimX), and 
    your 3D coordinates to the same (X + Y*cubeDimX + Z*cubeDimX*cubeDimY), then perform
	the conversions like so:

    2D to 3D (uv to voxel):

    int iPos = uvX + uvY*texDimX;
    cubeX = mod(iPos, cubeDimX); 
    cubeY = mod(floor(iPos/cubeDimX), cubeDimY); 
    cubeZ = mod(floor(iPos/(cubeDimX*cubeDimY)), cubeDimZ);

    3D to 2D (voxel to uv):

    int iPos = cubeX + cubeY*cubeDimX + cubeZ*cubeDimX*cubeDimY;
    uvX = mod(iPos, texDimX); 
    uvY = mod(floor(iPos/texDimX), texDimY); 
  
    I'm ignoring a few minor details, like scaling and snapping pizels to their centers to 
    avoid seam line artifacts. In addition, putting more values into the four texture 
    channels require some extra X dimension scaling and modulo involving the number 4, but 
    that's essentially it. You can find the details in the "Common" tab.
	

	
    
    Other examples:

    // Really nice example, and the thing that motivated me to get in amongst it
	// and finally learn to read and write from the cube map. I have a few 3D packing 
    // examples coming up, which use more simplistic formulas, but I couldn't tell 
    // you whether that translates to extra speed or not. Probably not. :)
    Copper / Flesh - tdhooper
    https://www.shadertoy.com/view/WljSWz

*/

// The maximum allowable ray distance. In this case, we're using a back plane of
// sorts, which nothing goes beyond, so it's kind of redundant, but it's here anyway.
#define FAR 20.


// 2D rotation formula.
mat2 rot2(float a){ float c = cos(a), s = sin(a); return mat2(c, s, -s, c); }

// I paid hommage to the original and kept the same rotation... OK, I'm lazy. :D
vec3 rotObj(vec3 p){
    
    p.yz *= rot2(iTime*.2);
    p.zx *= rot2(iTime*.5);
    return p;    
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



// A scene object ID container. This is just enough for four objects.
// If you needed more, you'd have to use other methods.
vec4 objID;


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


float surfFunc3D(in vec3 p){
    
    p = normalize(p);
    
    return txFace0(p/1.5);
    
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


float surfFunc2D(in vec3 p){
    
    // Normalizing the coordinates to pull things toward the 
    // center. A bit of overkill, but I've left it there, in
    // case I change my mind. :)
    //p = normalize(p - vec3(0, 0, -(12. - 6.)))*12.;

	return txFace1(iChannel0, (p.xy)/8. - .5);

}



float map(in vec3 p){
   
   
    vec4 d;
    
    
    // Back wall.
    
    // Perturbing things a bit.
    vec3 q = p + sin(p*2. - cos(p.zxy*3.5))*.1;
    
    // Grabbing the 2D surface value from the second face of the cubemap.
    float sf2D = surfFunc2D(q);
    
    // Combining the 2D Voronoi value above with an extrusion process to creat some netting.
    d.z = smax(abs(-q.z + 6. - .5) - .05, (sf2D/2. - .025), .02);
    //d.z = -(length(q - vec3(0, 0, -(12. - 6.))) - 12.) + (.5 - sf2D)*.5;
    
    // The back plane itself -- created with a bit of extrusion and addition. 
    d.w = -q.z + 6.;
    float top = (.5 - smoothstep(0., .35, sf2D - .025));
    d.w = smin(d.w, smax(abs(d.w) - .75, -(sf2D/2. - .025 - .04), .02) + top*.1, .02);
    
    
    // The celluar geometric ball object.
    
    // Rotate the object.
    q = rotObj(p);
    // Perturb it a bit.
    q += sin(q*3. - cos(q.yzx*5.))*.05;

    // Retrieve the 3D surface value. Note (in the function) that the 3D value has been 
    // normalized. That way, everything points toward the center.
    float sf3D = surfFunc3D(q);
    
    
    // Adding a small top portion.
    top = (.5 - smoothstep(0., .35, sf3D - .025));
    
    d.x = length(q) - 1.; // The warped spherical base.
    
    // The gold, metallic spikey ball surface -- created via an extrusion process
    d.y = smin(d.x + .1, smax(d.x - .2, -(sf3D/2.-.025 - .06), .02) + top*.05, .1);
    
    // The spherical netting with holes -- created via an extrusion process.
    d.x = smax(abs(d.x) - .025, sf3D/2.-.025, .01);
    
    
    
    // Store the individual object values for sorting later. Sorting multiple objects
    // inside a raymarching loop probably isn't the best idea. :)
    objID = d;
    
    // Return the minimum object in the scene.
    return min(min(d.x, d.y), min(d.z, d.w));
}

/*
// Tetrahedral normal, to save a couple of "map" calls. Courtesy of IQ. In instances where there's no 
// descernible aesthetic difference between it and the six tap version, it's worth using.
vec3 calcNormal(in vec3 p){

    // Note the slightly increased sampling distance, to alleviate artifacts due to hit point inaccuracies.
    vec2 e = vec2(0.0025, -0.0025); 
    return normalize(e.xyy*map(p + e.xyy) + e.yyx*map(p + e.yyx) + e.yxy*map(p + e.yxy) + e.xxx*map(p + e.xxx));
}
*/


// Normal function. It's not as fast as the tetrahedral calculation, but more symmetrical.
vec3 calcNormal(in vec3 p) {
	
    const vec2 e = vec2(.002, 0);
    
    //return normalize(vec3(m(p + e.xyy) - m(p - e.xyy), m(p + e.yxy) - m(p - e.yxy),	
    //                      m(p + e.yyx) - m(p - e.yyx)));
    
    // This mess is an attempt to speed up compiler time by contriving a break... It's 
    // based on a suggestion by IQ. I think it works, but I really couldn't say for sure.
    float sgn = 1.;
    float mp[6];
    vec3[3] e6 = vec3[3](e.xyy, e.yxy, e.yyx);
    for(int i = min(iFrame, 0); i<6; i++){
		mp[i] = map(p + sgn*e6[i/2]);
        sgn = -sgn;
        if(sgn>2.) break; // Fake conditional break;
    }
    
    return normalize(vec3(mp[0] - mp[1], mp[2] - mp[3], mp[4] - mp[5]));
}

// Raymarching: The distance function is a little on the intensive side, so I'm 
// using as fewer iterations as necessary. Even though there's a breat, the compiler
// still has to unroll everything, and larger numbers make a difference.
float trace(in vec3 ro, in vec3 rd){
    
    float t = 0., d;
    
    for(int i = min(0, iFrame); i<80; i++){
    
        d = map(ro + rd*t);
        if(abs(d) < .001*(1. + t*.05) || t > FAR) break;
        t += d*.75;
    }
    
    return min(t, FAR);
}

float hash( float n ){ return fract(cos(n)*45758.5453); }

// I keep a collection of occlusion routines... OK, that sounded really nerdy. :)
// Anyway, I like this one. I'm assuming it's based on IQ's original.
float calcAO(in vec3 p, in vec3 n)
{
	float sca = 2., occ = 0.;
    for( int i = 0; i<5; i++ ){
    
        float hr = float(i + 1)*.25/5.;        
        float d = map(p + n*hr);
        occ += (hr - d)*sca;
        sca *= .7;
    }
    
    return clamp(1. - occ, 0., 1.);  
    
}

// Cheap shadows are hard. In fact, I'd almost say, shadowing particular scenes with limited 
// iterations is impossible... However, I'd be very grateful if someone could prove me wrong. :)
float softShadow(vec3 ro, vec3 lp, vec3 n, float k){

    // More would be nicer. More is always nicer, but not really affordable... 
    // Not on my slow test machine, anyway.
    const int maxIterationsShad = 32; 
    
    ro += n*.002; // Bumping off the surface enough to avoid self collision.
    vec3 rd = lp - ro; // Unnormalized direction ray.
    
    // Initial conditions.
    float shade = 1.;
    float t = 1e-6; // Cyberjax's suggestion to avoid divide by zero compiler warnings.
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
        t += clamp(d, .035, .35); 
        
        
        // Early exits from accumulative distance function calls tend to be a good thing.
        if (d<0. || t>end) break; 
    }

    // Sometimes, I'll add a constant to the final shade value, which lightens the shadow a bit --
    // It's a preference thing. Really dark shadows look too brutal to me. Sometimes, I'll add 
    // AO also just for kicks. :)
    return max(shade, 0.); 
}




void mainImage(out vec4 fragColor, in vec2 fragCoord){

    // Aspect correct screen coordinates.
    vec2 p = (fragCoord - iResolution.xy*.5)/iResolution.y;
    
    // Unit direction ray.
    vec3 rd = normalize(vec3(p, 1));
    
    // Ray origin, doubling as the camera postion.
    vec3 ro = vec3(sin(iTime/2.)*.5, cos(iTime/4.)*.1 - iTime*0., -3.);
    
    // Light position. Near the camera.
    vec3 lp = ro + vec3(0, .65, 1.35);
    
    // Ray march.
    float t = trace(ro, rd);
    
    
    // Object identification: Back plane: 3, Golden joins: 2., 
    // Ball joins: 1., Silver pipes:  0.
    float svObjID = objID.x<objID.y && objID.x<objID.z && objID.x<objID.w? 0.: 
    objID.y<objID.z && objID.y<objID.w ? 1. : objID.z<objID.w? 2. : 3.;

    
    // Initiate the scene color zero.
    vec3 col = vec3(0);
    
    // Surface hit. Color it up.
    if(t < FAR){
    
        // Position.
        vec3 pos = ro + rd*t;
        // Normal.
        vec3 nor = calcNormal(pos);
        
        // Light direction vector.
        vec3 ld = lp - pos;
        float lDist = max(length(ld), .001);
        ld /= lDist;
        
        // Light falloff - attenuation.
        float atten = 2./(1. + lDist*.05 + lDist*lDist*.025);
        
        // Soft shadow and occlusion.
        float shd = softShadow(pos, lp, nor, 8.); // Shadows.
        float ao = calcAO(pos, nor);
        shd = min(shd + .2*ao, 1.);
        
        
        float diff = max(dot(ld, nor), .0); // Diffuse.
        float spec = pow(max(dot(reflect(-ld, nor), -rd), 0.), 32.); // Specular.
        // Ramping up the diffuse. Sometimes, it can make things look more metallic.
        diff = pow(diff, 4.)*3.; 
        
        // Approximate Schlick value.
        float Schlick = pow( 1. - max(dot(rd, normalize(rd + ld)), 0.), 5.0);
		float fre2 = mix(.5, 1., Schlick);  //F0 = .5.
        
        
        // The rotated position and normal, for texturing the rotating
        // spherical object.
        vec3 txPos = rotObj(pos + vec3(0, iTime*0., 0));
        vec3 txNor = rotObj(nor);
        
        
        // Initializing the object color.
        vec3 oCol = vec3(0);
        
                
        
        // Silver metallic spherical netting.
        if(svObjID == 0.){
            oCol = vec3(.5, .4, .35);
            oCol += fre2;
            
            // Trusty "Rusty Metal" texture -- I'm trying to set a Shadertoy
        	// record for its overusage. :D
        	vec3 tx = tex3D(iChannel1, txPos*2., txNor);
        	tx = smoothstep(0., .5, tx);
            oCol *= tx;
        }
        
        // Gold metallic spikey ball.
        if(svObjID == 1.){
            oCol = vec3(.5, .4, .35); // Reddish grey.
            oCol += vec3(2.5, .75, .1)*fre2;
            
            // Another sample.
        	vec3 tx = tex3D(iChannel1, txPos, txNor);
        	tx = smoothstep(0., .5, tx);
            oCol *= tx;
        }
        
        // Back mesh.
        if(svObjID == 2.) { 
            oCol = vec3(.5, .4, .35); // Reddish grey... or is it greyish red? :)
            oCol += fre2;
              
        }        
        
        // Spikey prutruding back wall.
        if(svObjID == 3.) { 
            oCol = vec3(.8, 1, .7); // Greenish.
            
            // Since glass has a refrective index of... which means shorter wave 
            // lengths produce... Hmmm, some extra blue seems to look nice. :D
            oCol += vec3(.2, .6, 1)*fre2;
          
        }
        
        
        if(svObjID<1.5){ // Spherical objects.
               
            // Using the surface shade to color and shade some more.
            float oShd = surfFunc3D(txPos);
            oCol = mix(oCol, vec3(1, .0, .2), oShd/2.);
            oCol *= oShd*.8 + .2;
             
        }
        else { // Back plane objects.
            
             vec3 tx = tex3D(iChannel1, pos/6., nor);
        	 tx = smoothstep(0., .5, tx);
             oCol *= tx;
                  
             // Using the surface shade to color and shade some more.
             float oShd = surfFunc2D(pos);
             oCol = mix(oCol, vec3(1, .0, .2), oShd/2.);
             
             oCol *= oShd*.8 + .2;
            
        }
  
        
         
        // Diffuse plus ambient term.
        col = oCol*(diff + .35); 
        // Extra global Fresnel.
        //col += oCol*vec3(.3, .6, 1)*diff*fre2*fre2*.5;
        
        // Specular term.
        col += oCol*vec3(1, .9, .7)*spec*4.;
        
        // Using the stored 3D values to apply some cheapish fake reflection.
        vec3 refCol = col*vec3(.25, .5, 1)*smoothstep(.1, 1., txFace0(reflect(rd, nor)/1.5));
        vec4 refInt = vec4(12, 24, 24, 32);
        col += refCol*refInt[int(svObjID)&3];

        
        // Applying the ambient occlusion, shadows and attenuation.
        col *= ao*shd*atten;
         
    }
    
    
    // Screen color, with gamma correction. No fog or postprocessing.
    fragColor = vec4(pow(clamp(col, 0., 1.), vec3(1./2.2)), 1);
}