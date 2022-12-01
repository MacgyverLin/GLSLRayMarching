/*

    Extruded Asymmetric Hexagons
    ----------------------------

	Here's a trimmed down version of my "Asymmetric Hexagon Landscape"
    example. Aesthetically speaking, I've kept it pretty basic. Without the 
    extra detail, it should definitely run faster. However, how well it runs 
    is still dependent upon how well your machine can deal with textures, and  
    other things.

	My laptop can run this in the 800 by 450 window form in its sleep, and 
    can almost run it in fullscreen (1920 by 1080), but experiences slight 
    stutter. Having said that, I think running any detailed pixel shader in
	fullscreen mode is a bit of a stretch for the GPU.

    Texture storage can be annoying to code, and a lot of systems still don't
	like the idea of putting them in memory and reading from them in realtime. 
    However, the alternative is to calculate really expensive distance 
    functions on the fly, which would be near impossible on present systems.
    This particular field comprises of packed pixel-perfect rounded asymmetric 
    extruded hexagons. As an aside, I've already tried to produce the same 
    using nonstorage methods and it practically grinds my machine to a halt. 

    Either way, this is a pretty simple field in the general scheme of things, 
    so if you wanted to raymarch something more elaborate, then some kind of 
    texture precalculation will be mandatory. With this particular method, I
	could turn it into a jigsaw, and the performance would remain relatively 
    unaffected.

    By the way, for anyone interested, the cheap 3D cross hatching-based 
    pencil ink post processing routine was written off the top of my head in 
    under ten minutes. It's substandard for sure, but effective (See the
	DRAW_STYLE directive below). I've been meaning to add one for a while, 
    since I haven't seen many written on Shadertoy. All routines like this 
    are just an extension of tri-planar texturing and greyscale pixel 
    thresholds, and are not very difficult to implement. Anyway, the code is
	at the bottom of the page.


 
	Other examples:

	// Dr2's latest, which takes a Voronoi approach. The Voronoi aesthetic is 
    // similar, and arguably, superior, which makes it the algorithm of choice 
    // in many situations. However, it involves more taps, plus gaining access 
    // to vertex information is definitely not as straight forward, which 
    // means there are times when an offset hexagon vertices approach would
    // be preferred.
    //
    Gliders Over Voropolis - Dr2
    https://www.shadertoy.com/view/WdKcz1
    
    // A more involved example.
    //
	Asymmetric Hexagon Landscape - Shane
 	https://www.shadertoy.com/view/tdtyDs

    // Flockaroo's less hacky sketch shader: This is a planar algorithm, 
    // and is great with static scenery and some moving scenery. For general 
    // moving scenery, it'd need to be converted to a tri-planar version.
    when voxels wed pixels - Flockaroo
    https://www.shadertoy.com/view/MsKfRw


*/

// The drawing style -- Choose greyscale pencil (2) to see the typical 
// cross hatching representation on its own.
//
// 0: No postprocessing, 1: Heavy greyscale pencil, 2: Greyscale pencil, 
// 3: Colored pencil.
#define DRAW_STYLE 2

// The pencil algorithm looks more authentic with this turned off -- I
// think it has something to do with our eyes not accepting pronounced
// lighting changes with animated sketches. However, I'd like the user 
// to see it with it turned on. Anyway, the ability to turn it off is 
// a compromise.
#define ENVIRONMENT_LIGHTING 

// Turning the metallic texturing on and off.
#define TEXTURED

// Colored blinking pylons.
#define BLINK 



// Max ray distance.
#define FAR 20.

// Pylong height scale. Between zero and one works, but larger numbers
// introduce more artifacts.
#define HS .6  

// Scene object ID to separate the mesh object from the terrain.
float objID;


// The path is a 2D sinusoid that varies over time, which depends upon the frequencies and amplitudes.
vec2 path(in float z){ 
    
    //return vec2(0);
    return vec2(3.*sin(z*.1) + .5*cos(z*.4), .25*(sin(z*.875)*.5 + .5));
}


// Getting the video texture. I've deliberately stretched it out to fit across the screen,
// which means messing with the natural aspect ratio.
//
// By the way, it'd be nice to have a couple of naturally wider ratio videos to choose from. :)
//
vec3 getTex(sampler2D tex, in vec2 p){
    
    // Strething things out so that the image fills up the window. You don't need to,
    // but this looks better. I think the original video is in the oldschool 4 to 3
    // format, whereas the canvas is along the order of 16 to 9, which we're used to.
    // If using repeat textures, you'd comment the first line out.
    //p *= vec2(iResolution.y/iResolution.x, 1);
    //p = p/2. + .5;
    //p = (floor(p*1024.) + .5)/1024.;
    vec3 tx = texture(tex, p).xyz;
    //vec3 tx = textureLod(iChannel0, p, 0.).xyz;
    return tx*tx; // Rough sRGB to linear conversion.
}

// Tri-Planar blending function: Based on an old Nvidia writeup:
// GPU Gems 3 - Ryan Geiss: http://http.developer.nvidia.com/GPUGems3/gpugems3_ch01.html
vec3 tex3D(sampler2D tex, in vec3 p, in vec3 n){    
    
    // Ryan Geiss effectively multiplies the first line by 7. It took me a while to realize that 
    // it's largely redundant, due to the division process that follows. I'd never noticed on 
    // account of the fact that I'm not in the habit of questioning stuff written by Ryan Geiss. :)
    n = max(n*n - .2, .001); // max(abs(n), 0.001), etc.
    n /= dot(n, vec3(1)); 
    //n /= length(n); 
    
    // Texure samples. One for each plane.
    vec3 tx = texture(tex, p.yz).xyz;
    vec3 ty = texture(tex, p.zx).xyz;
    vec3 tz = texture(tex, p.xy).xyz;
    
    // Multiply each texture plane by its normal dominance factor.... or however you wish
    // to describe it. For instance, if the normal faces up or down, the "ty" texture sample,
    // represnting the XZ plane, will be used, which makes sense.
    
    // Textures are stored in sRGB (I think), so you have to convert them to linear space 
    // (squaring is a rough approximation) prior to working with them... or something like that. :)
    // Once the final color value is gamma corrected, you should see correct looking colors.
    return mat3(tx*tx, ty*ty, tz*tz)*n; // Equivalent to: tx*tx*n.x + ty*ty*n.y + tz*tz*n.z;

}



// Height map value, which is just the pixel's greyscale value.
float hmB(in vec2 p){ 
     
    return dot(getTex(iChannel1, p), vec3(.299, .587, .114)); 
}

// The height map. It was orginally supposed to be a fast texture call, but then
// I was insistent on creating a valley that followed the camera path, which would
// be pretty difficult to encode into a repeat texture... Anyway, it's slower now,
// but within acceptable ranges.
float hmBlock(in vec2 p){ 
    
    
    // Wrapping things around the camera path.
    vec2 pth = path(p.y);
    p -= pth; // Y is the Z coordinate here.
    
    float d = abs((p.x + .5) - .5)*2.;
    
    // Scaling by 1/16 and snapping to repeat texture pixels. Alternatively, you 
    // can change the cube map filter to "nearest" and save a calculation, which
    // is what I've done.
    p /= 24.;
    // p = (floor(p*1024./16.) + .5)/1024.;  
    
    // Retrieving the height value from the precalculated wrapped texture map.
    float h = tx5(iChannel0, p).x; 
                    
    // Carving out a path.
    h = mix(h + pth.y,  h/1.5 + pth.y/2., 1. - smoothstep(0., .75, d - .25));
    
    #ifdef QUANTIZE_HEIGHT
    // Quantizing the height levels. More expensive, but it looks a little neater.
    h = floor(h*23.999)/23.;
    #endif
    
    return h;
    
    
}




// A regular extruded block grid.
//
// The idea is very simple: Produce a normal grid full of packed square pylons.
// That is, use the grid cell's center pixel to obtain a height value (read in
// from a height map), then render a pylon at that height.
 


vec4 blocks(vec3 q){
    
    
    // Pulling in the 4 precalculated offset values from their respective
    // cube map faces.
    //
    // By the way, calculating the minimum 2D face distance, then using it to
    // render the extruded block doesn't work... It'd be nice, but you have to
    // compare all 4 extruded blocks... It's obvious, yet if I haven't done this
    // for a while, it's the first thing I try. :D
    vec2 uv = (floor(q.xy*1024.) + .5)/1024.;
    vec4 p40 = tx0(iChannel0, uv);  // The 2D distance fields.  
    // Precalculated heights. These would have tripled the speed, but
    // unforturnately weren't practic


    // Block dimension: Length to height ratio with additional scaling. By the way,
    // I'm being sneaky here and not applying the vec2(.8660254, 1) stretch scaling
    // that gives you proper scaled hexagons. One reason is that they're mutated by
    // the offset vertices anyway, and the main one is that it makes wrapping more
    // difficult. Not impossible, but more complicated.
	const vec2 dim = GSCALE;
    // A helper vector, but basically, it's the size of the repeat cell.
	const vec2 s = dim*2.; 
 
    
    // Distance.
    float d = 1e5;
    // Cell center, local coordinates and overall cell ID.
    vec2 p, ip;
    
    // Individual brick ID.
    vec2 id = vec2(0);
    vec2 cntr = vec2(0);

    // Four block corner postions.
    const vec2 ll = vec2(.5);
    //vec2[4] ps4 = vec2[4](vec2(-ll.x, ll.y), ll, -ll, vec2(ll.x, -ll.y));
    // Pointed top.
    #ifdef FLAT_TOP
    // Flat top.
    vec2[4] ps4 = vec2[4](vec2(-ll.x, ll.y), ll + vec2(0., ll.y), -ll, vec2(ll.x, -ll.y) + vec2(0., ll.y));
    #else
    // Pointed top.
    vec2[4] ps4 = vec2[4](vec2(-ll.x, ll.y), ll, -ll + vec2(ll.x, 0), vec2(ll.x, -ll.y) + vec2(ll.x, 0));
    #endif  
    

    // Initializing the extruded face distance for the hexagon cell.
    float d2D = 1e5;
    
    for(int i = 0; i<4; i++){

        // Block center.
        cntr = ps4[i]/2.; 
        
        p = q.xy; // Local coordinates.
        ip = floor(p/s - cntr) + .5; // Local tile ID.
        p -= (ip + cntr)*s; // New local position.
        
        // Correct positional individual tile ID.
        vec2 idi = ip + cntr;
 
        // Hexagon vertices. 
        vec4[3] vert = vID; 
        
        
        #ifdef OFFSET_VERTICES
        // Offsetting the vertices. Note that accuracy is important here. I had a bug for
        // a while because I was premultiplying by "s," to save some calculations, which meant
        // points were not quite meeting at the joins... I won't bore you with the rest,
        // except to say that it's necessary to keep these numbers simple.
        const float vo = .15;
        vec4 vrt0 = idi.xyxy + vert[0]/2.;
        vec4 vrt1 = idi.xyxy + vert[1]/2.;
        vec4 vrt2 = idi.xyxy + vert[2]/2.;
        vrt0 = hash42B(vrt0);
        vrt1 = hash42B(vrt1);
        vrt2 = hash42B(vrt2);
        vert[0] += vrt0*vo;
   		vert[1] += vrt1*vo;
        vert[2] += vrt2*vo;
        #endif 
        
        // Scaling to enable rendering back in normal space.
        vert[0] *= dim.xyxy;
        vert[1] *= dim.xyxy;
        vert[2] *= dim.xyxy; 
        
          
        // Hexagon vertices.
        vec2[6] v1 = vec2[6](vert[0].xy, vert[0].zw, vert[1].xy, vert[1].zw, vert[2].xy, vert[2].zw); 
        
        
        // Scaling the ID.
	    idi *= s;
         
        
        // Offset hexagon center.
        //vec2 inC = vec2(0);
        // Preferred, but not necessary and it's a huge bottleneck, which surprises me.
        //vec2 inC = (vert[0].xy + vert[0].zw + vert[1].xy + vert[1].zw + vert[2].xy + vert[2].zw)/6.;
        //vec2 idi1 = idi + inC;
        
        // Stored 2D rounded offset hexagon face distance information. Without this, 
        // the example would fry your GPU.
        float face1 = p40[i];
        //float face1 = sdPoly(p, vert); 
        
        float h1 = hmBlock(idi); //p42[i] For future stored heights.
        h1 *= HS; // Height scaling.
        
        float face1Ext = opExtrusion(face1, (q.z - h1), h1); 
        
        /*
        // Lego style.
        float top = length(p) - .2*scale.x + .065*scale.x;
        float cyl1 = opExtrusion(abs(top) - .035*scale.x, q.z - (h1 + .01), h1 + .01);
        face1Ext = min(face1Ext, cyl1);
        */
        
        face1Ext += max(face1, -.015)*.5;
        face1Ext += face1*.05;
        
        
        // If applicable, update the overall minimum distance value,
        // ID, and pylon face distance. 
        if(face1Ext<d){
            d = face1Ext;
            id = idi;
            d2D = face1; // Recording the face distance.

        }
        
    }
    
    // Return the distance, position-based ID and triangle ID.
    return vec4(d, id, d2D);
}


// Block ID -- It's a bit lazy putting it here, but it works. :)
vec4 gID;

// The extruded image.
float map(vec3 p){
    
    // Floor.
    //float fl = p.y;

    // The extruded blocks.
    vec4 d4 = blocks(p.xzy);
    gID = d4; // Individual block ID.
 
    // Overall object ID.
    objID = p.y<d4.x? 1. : 0.;
    
    // Combining the floor with the extruded image
    return min(p.y, d4.x);
 
}

 
// Basic raymarcher.
float trace(in vec3 ro, in vec3 rd){

    // Overall ray distance and scene distance.
    float t = 0., d;
    
    for(int i = 0; i<96; i++){
    
        d = map(ro + rd*t);
        // Note the "t*b + a" addition. Basically, we're putting less emphasis on accuracy, as
        // "t" increases. It's a cheap trick that works in most situations... Not all, though.
        if(abs(d)<.001*(1. + t*.125) || t>FAR) break; // Alternative: 0.001*max(t*.25, 1.), etc.
        
        t += i<40? d*.5 : d*.75; 
        //t += d*.8; 
    }

    return min(t, FAR);
}


// Standard normal function. It's not as fast as the tetrahedral calculation, but more symmetrical.
vec3 getNormal(in vec3 p, float t) {
	const vec2 e = vec2(.001, 0);
    
    
    //vec3 n = normalize(vec3(map(p + e.xyy) - map(p - e.xyy),
    //map(p + e.yxy) - map(p - e.yxy),	map(p + e.yyx) - map(p - e.yyx)));
    
    float sgn = 1.;
    vec3 n = vec3(0);
    float mp[6];
    vec3[3] e6 = vec3[3](e.xyy, e.yxy, e.yyx);
    for(int i = min(iFrame, 0); i<6; i++){
		mp[i] = map(p + sgn*e6[i/2]);
        sgn = -sgn;
        if(sgn>2.) break;
    }
    
    return normalize(vec3(mp[0] - mp[1], mp[2] - mp[3], mp[4] - mp[5]));
}


// Cheap shadows are hard. In fact, I'd almost say, shadowing particular scenes with limited 
// iterations is impossible... However, I'd be very grateful if someone could prove me wrong. :)
float softShadow(vec3 ro, vec3 lp, vec3 n, float k){

    // More would be nicer. More is always nicer, but not really affordable... Not on my slow test machine, anyway.
    const int maxIterationsShad = 24; 
    
    ro += n*.0015;
    vec3 rd = lp - ro; // Unnormalized direction ray.
    

    float shade = 1.;
    float t = 0.;//.0015; // Coincides with the hit condition in the "trace" function.  
    float end = max(length(rd), 0.0001);
    //float stepDist = end/float(maxIterationsShad);
    rd /= end;

    // Max shadow iterations - More iterations make nicer shadows, but slow things down. Obviously, the lowest 
    // number to give a decent shadow is the best one to choose. 
    for (int i = 0; i<maxIterationsShad; i++){

        float d = map(ro + rd*t);
        shade = min(shade, k*d/t);
        //shade = min(shade, smoothstep(0., 1., k*h/dist)); // Subtle difference. Thanks to IQ for this tidbit.
        // So many options here, and none are perfect: dist += min(h, .2), dist += clamp(h, .01, stepDist), etc.
        t += clamp(d, .01, .25); 
        
        
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
	float sca = 2., occ = 0.;
    for( int i = 0; i<5; i++ ){
    
        float hr = float(i + 1)*.15/5.;        
        float d = map(p + n*hr);
        occ += (hr - d)*sca;
        sca *= .7;
        if(sca>1e5) break; // Compiler related.
    }
    
    return clamp(1. - occ, 0., 1.);  
    
}

// Compact, self-contained version of IQ's 3D value noise function. I have a transparent noise
// example that explains it, if you require it.
float n3D(in vec3 p){
    
	const vec3 s = vec3(7, 157, 113);
	vec3 ip = floor(p); p -= ip; 
    vec4 h = vec4(0., s.yz, s.y + s.z) + dot(ip, s);
    p = p*p*(3. - 2.*p); //p *= p*p*(p*(p * 6. - 15.) + 10.);
    h = mix(fract(sin(h)*43758.5453), fract(sin(h + s.x)*43758.5453), p.x);
    h.xy = mix(h.xz, h.yw, p.y);
    return mix(h.x, h.y, p.z); // Range: [0, 1].
}

// Very basic pseudo environment mapping... and by that, I mean it's fake. :) However, it 
// does give the impression that the surface is reflecting the surrounds in some way.
//
// More sophisticated environment mapping:
// UI easy to integrate - XT95    
// https://www.shadertoy.com/view/ldKSDm
vec3 envMap(vec3 p){
    
    p *= 4.;
    p.y += iTime;
    
    float n3D2 = n3D(p*2.);
   
    // A bit of fBm.
    float c = n3D(p)*.57 + n3D2*.28 + n3D(p*4.)*.15;
    c = smoothstep(.45, 1., c); // Putting in some dark space.
    
    p = vec3(c, c*c, c*c*c); // Redish tinge.
    
    return mix(p, p.xzy, n3D2*.4); // Mixing in a bit of purple.

}


void mainImage( out vec4 fragColor, in vec2 fragCoord ){

    
    // Screen coordinates.
	vec2 uv = (fragCoord - iResolution.xy*.5)/iResolution.y;
    
 	
	// Camera Setup.

	vec3 ro = vec3(0, 1.15, iTime*.75); // Camera position, doubling as the ray origin.
	vec3 lk = ro + vec3(0, -.2, .25); // "Look At" position.
    
    // Light positioning. One is just in front of the camera, and the other is in front of that.
    
    #if DRAW_STYLE == 0
    // With no pencil post processing, the light looks a little nicer here.
    const float lightZ = 4.5;
    #else
    // When using a pencil overlay, reposition the light to hit the surface more directly.
    const float lightZ = -.5;
    #endif
 	vec3 lp = ro + vec3(1.25, 1.5, lightZ);// Put it a bit in front of the camera.
    
    // Moving the camera and light along the path.
	ro.xy += path(ro.z); 
    lk.xy += path(lk.z); 
    lp.xy += path(lp.z); 

    // Using the above to produce the unit ray-direction vector.
    float FOV = 1.; // FOV - Field of view.
    vec3 fwd = normalize(lk - ro);
    vec3 rgt = normalize(vec3(fwd.z, 0., -fwd.x )); 
    // "right" and "forward" are perpendicular, due to the dot product being zero. Therefore, I'm 
    // assuming no normalization is necessary? The only reason I ask is that lots of people do 
    // normalize, so perhaps I'm overlooking something?
    vec3 up = cross(fwd, rgt); 

    // rd - Ray direction.
    //vec3 rd = normalize(fwd + FOV*uv.x*rgt + FOV*uv.y*up);
    vec3 rd = normalize(uv.x*rgt + uv.y*up + fwd/FOV);
    
    // Swiveling the camera about the XY-plane.
	//rd.xy *= rot2( sin(iTime/8. - cos(iTime/12.))/2. );

    // Setting the global time variable so that the "Common" tab can recognize time.
    setTime(iTime);

	 
    
    // Raymarch to the scene.
    float t = trace(ro, rd);
    
    // Save the block ID and object ID.
    vec4 svGID = gID;
    
    float svObjID = objID;
	
    // Initiate the scene color to black.
	vec3 col = vec3(0);
    
    // Surface position and surface normal. We're setting them
    // up here, due to some postprocess that require them...
    // See below.
	vec3 sp = ro + rd*t;
    vec3 sn = rd; // Surface normal for the sky dome.
    float gRnd = 0.; // Random number to move the hatching around.
    float gRndB = 0.; // Random number to move the hatching around.
	
	// The ray has effectively hit the surface, so light it up.
	if(t < FAR){
  	
    	// Normal overide for cases where we've hit
        // the surface. In this example, we don't see the 
        // horizon, so it would be always, but we still
        // need to do things correctly. :)
	    //sn = getNormal(sp, edge, crv, ef, t);
        sn = getNormal(sp, t);
        
          
        // Obtaining the texel color. 
	    vec3 texCol;   

        // The extruded grid.
        if(svObjID<.5){
            
            // Texturing.
            //
            #ifdef TEXTURED
            // Coloring the individual blocks with the saved ID.
            vec3 tx = getTex(iChannel1, svGID.yz/2.);
            //tx = smoothstep(.05, .5, tx);
            // Continuous tri-planar texturing.
            vec3 tx2 = tex3D(iChannel1, sp*1., sn);
            tx2 = smoothstep(.0, .5, tx2);
            #else
            vec3 tx = vec3(.35);
            vec3 tx2 = vec3(.35);
            #endif
            
			float rnd = hash21(svGID.yz); 
            gRnd = rnd;
            #ifdef BLINK
            // Blinking: Couldn't make it look right, but I'll look at it later.
            //rnd = rnd<.125? 1. : 0.;
            rnd = smoothstep(.9, .95, sin(6.2831*rnd + iTime)*.5 + .5);
            gRndB = rnd;
            vec3 bCol = vec3(1, .2, .05);
            bCol = mix(bCol, bCol.xzy, hash21(svGID.yz + .09)*.6);
            tx2 *= mix(vec3(1), bCol*5., rnd);
            #endif
            
            texCol = mix(tx, tx2, .5); // Blend.
            //texCol = vec3(.34);
            //float rnd = hash21(svGID.yz);
            //vec3 rndC = .5 + .45*cos(6.2831*(rnd)/4. + vec3(0, 1, 2) + 0.);
            //texCol = mix(texCol, rndC, .15);
            


            vec2 svP = sp.xz - svGID.yz;
            texCol = mix(texCol, vec3(0), 1. - smoothstep(0., .005, length(svP) - .04*GSCALE.x));
             
            // Hexagonal face value.
            float ht = hmBlock(svGID.yz)*HS;
            float hex = svGID.w;
   
            float hex2 = hex;
            hex = max(abs(hex), abs(sp.y - ht*2.)) - .001; // Face border.
            //hex = min(hex, abs(hex2 + .01) - .00125); // Extra border.
            
            // Coloring the sides of the columns. I wasn't feeling it. :)
            //vec3 rndC = .5 + .45*cos(6.2831*(ht)*4. + vec3(2, 1, 0) + 2.);
            //texCol = mix(texCol, texCol*rndC, (1. - smoothstep(0., .002, -(hex2)))*.9);
            
            // Applying the face border.
            texCol = mix(texCol, vec3(0), (1. - smoothstep(0., .002, hex)));
            
            
            // Failed attempts at decoration. I opted for "less is more" in the end. :)
            /*
            float rnd = hash21(svGID.yz);
            vec2 puv = rot2(ht*6.2831)*svP;
            float pat = abs(fract(puv.x*48.) - .5)*2. - .125;
            pat = smoothstep(0., .003*48.*(1. + t*t), pat);
            texCol = mix(texCol, texCol*pat, 1. - smoothstep(0., .003, -(sp.y - ht*2.)));
            */
            
            /*
            float ang = atan(svP.y, svP.x)/6.2831;
            float pat = abs(fract(ang*24.) - .5)*2. - .25;
            pat = smoothstep(0., .003*24.*(1. + t*t), pat);
            texCol = mix(texCol, texCol*vec3(2, 1, .5)*pat, 1. - smoothstep(0., .003, sp.y - ht));
            */
     
 
        }
        else {
            
            // The dark floor in the background. Hiddent behind the pylons, but
            // you still need it.
            texCol = vec3(0);
        }
       
    	
    	// Light direction vector.
	    vec3 ld = lp - sp;

        // Distance from respective light to the surface point.
	    float lDist = max(length(ld), .001);
    	
    	// Normalize the light direction vector.
	    ld /= lDist;

        
        
        // Shadows and ambient self shadowing.
    	float sh = softShadow(sp, lp, sn, 16.);
    	float ao = calcAO(sp, sn); // Ambient occlusion.
        //sh = min(sh + ao*.25, 1.);
	    
	    // Light attenuation, based on the distances above.
	    float atten = 1.25/(1. + lDist*.05);

    	
    	// Diffuse lighting.
	    float diff = max( dot(sn, ld), 0.);
        diff = pow(diff, 2.)*1.35; // Ramping up the diffuse.
    	
    	// Specular lighting.
	    float spec = pow(max(dot(reflect(ld, sn), rd ), 0.), 32.); 
	    
	    // Fresnel term. Good for giving a surface a bit of a reflective glow.
        float fre = pow(clamp(1. - abs(dot(sn, rd))*.5, 0., 1.), 2.);
        
		// Schlick approximation. I use it to tone down the specular term. It's pretty subtle,
        // so could almost be aproximated by a constant, but I prefer it. Here, it's being
        // used to give a hard clay consistency... It "kind of" works.
		//float Schlick = pow( 1. - max(dot(rd, normalize(rd + ld)), 0.), 5.);
		//float freS = mix(.15, 1., Schlick);  //F0 = .2 - Glass... or close enough.        
        
        // Combining the above terms to procude the final color.
        col = texCol*(diff*sh + ao*.25 + vec3(.25, .5, 1)*fre*sh + vec3(1, .5, .3)*spec*4.);

        #ifdef ENVIRONMENT_LIGHTING
        // Fake environment mapping.
        vec3 cTex = envMap(reflect(rd, sn));
        #if DRAW_STYLE==0
        col += col*cTex*5.;
        #elif DRAW_STYLE==1
        col += col*cTex*.5;
        #else  
        col += col*cTex*2.;
        #endif
        #endif
        
        // Shading.
        col *= ao*atten;
        
	
	}
    
    // Applying fog.
    vec3 fog = vec3(0);//mix(vec3(.25, .5, 1), vec3(1, .8, .6), rd.y*.5 + .5)*2.;
    col = mix(col, fog, smoothstep(0., .99, t/FAR));
    
    
    // Here's a quick hacky 3D cross hatching routine that I made up on the spot. 
    // You could do better, but this works surprisingly well for the amount of 
    // effort involved. Normally, there's an element of frequency grading involved,
    // but aside from that, all 3D hatching would be based on similar principles.
    //
    // Texure samples. One for each plane.
    mat2 m2 = rot2(3.14159/12.); // Rotation.
    sp += gRnd; // Constant translation from object to object.
    sp *= 3.; // Scaling.
    #if DRAW_STYLE==1
    sp *= 1.5; // Finer grain pencil for the heavy pencil.
    #endif
    sp += n3D(sp*12.)*.02; // Perturbation, since pencil lines aren't perfect.
    // Use the hatch texture, for obvious reasons. At some stage, I'll code
    // up one that's more specific to this purpose.
	vec3 tx = getTex(iChannel2, m2*sp.yz); 
    vec3 ty = getTex(iChannel2, m2*sp.xz);
    vec3 tz = getTex(iChannel2, m2*sp.xy);
    // Second level of cross hatching.
    sp *= 1.5; m2 *= rot2(3.14159/4.);
    vec3 tx2 = getTex(iChannel2, m2*sp.yz); 
    vec3 ty2 = getTex(iChannel2, m2*sp.xz); 
    vec3 tz2 = getTex(iChannel2, m2*sp.xy); 
    // Normal manipulation.
    sn = max(sn*sn - .2, .001); // max(abs(n), 0.001), etc.
    sn /= dot(sn, vec3(1)); 
    //sn /= length(sn); 
    // Multiply each texture plane by its normal dominance factor.
    tx = mat3(tx, ty, tz)*sn;
    tx = vec3(1)*dot(tx, vec3(.299, .587, .114));
    tx2 = mat3(tx2, ty2, tz2)*sn;
    tx2 = vec3(1)*dot(tx2, vec3(.299, .587, .114));
    tx = max(tx, tx2);
    // Compare the texture to the scene's color value.
    
    #if DRAW_STYLE==1
    // Straight cross hatching.
    // The "-.25" and ".6" terms control light and darkness. This little tidbit is
    // based on some of Flockaroos logic from his sketch shader, here:
    //
    // when voxels wed pixels - flockaroo
    // https://www.shadertoy.com/view/MsKfRw
    tx = vec3(1)*smoothstep(0., .45, dot((min(col, 1.) - tx), vec3(.299, .587, .114)));
    #ifdef BLINK
    col = mix(tx, col*tx*1.35, gRndB);
    #else
    col = tx;
    #endif
    #elif DRAW_STYLE==2
    // Straight cross hatching.
    // The "-.25" and ".6" terms control light and darkness.
    tx = vec3(1)*smoothstep(-.25, .6, dot((min(col, 1.) - tx), vec3(.299, .587, .114)));
    //tx = vec3(1)*clamp(dot((min(col, 1.) - tx), vec3(.299, .587, .114))/.6 + .25, 0., 1.);
    #ifdef BLINK
    col = mix(tx, col*tx*1.35, gRndB);
    #else
    col = tx;
    #endif
    #elif DRAW_STYLE==3
    // Colorize. 
    // The "-.25" and ".5" terms control light and darkness.
    tx = vec3(1)*smoothstep(-.2, .5, dot((min(col, 1.) - tx), vec3(.299, .587, .114)));
    // I was in a hurry here. It'd be better to perfrom some kind of nice
    // Photoshop style overlay.
    col *= tx*1.35;
    //col *= mix(vec3(1), tx*1.25, .85);
    //col = 1. - exp(-col*1.2); 
    //col = mix(col, max(col, tx), .25);
    #endif
    
    // Color to greyscale edge fade.
    //col = mix(col, tx, dot(uv, uv));
   
    // Debug: Just the height map.
    //uv = fragCoord/iResolution.y;
    //vec3 tx = tx5(iChannel0, uv/1.).xyz;
    //col = tx;
         
    
    // Rought gamma correction.
	fragColor = vec4(sqrt(max(col, 0.)), 1);
	
}