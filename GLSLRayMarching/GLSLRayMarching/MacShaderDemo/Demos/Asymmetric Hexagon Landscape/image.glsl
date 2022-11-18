/*

    Asymmetric Hexagon Landscape
    ----------------------------

	Just for fun, I coded up a landscape of extruded asymmetric hexagonal blocks 
    tailored to resemble randomly packed polygons. It's more of a proof of concept 
    than anything else. I think it runs well enough, and I've documented the code 
    to a certain degree, but I wouldn't take any of it too seriously. I had the 
    idea to do this when I was in Bavaria back in March, so that provided minor 
    inspiration for the design. It's rendered in an abstract low-poly cartoon style.

	The code was hastily put together with old projects and makes use of something
	I constructed in 2D a long time ago when attempting to produce a fast random 
    Delaunay pattern. The idea is simple in concept, since it's nothing more than a 
    grid of hexagons with offset vertices. The Delaunay pattern I was after turned 
    out to be less interesting than I'd hoped for, due to the restricted offsets 
    involved. However, I always figured it'd look pretty cool in extruded form. The 
    thing holding me back was the usual speed constraints. In fact, speed was not 
    the primarily concern, but rather the painful buffer setup and wrapping 
    considerations required to make it fast. By the way, apologies in advance for
	the longer compile time; I'll try to get that down later.

	Mattz and IQ have already posted some pretty cool hexagon related traversals,
	and I'm pretty sure Abje -- who puts together a lot of clever stuff that slips
	under the radar -- has already produced a Voronoi prism cell traverser, along 
    with a couple of other people. Fizzer's basically constructed every traversal 
    at one point or another, so I guess I'm saying that this isn't an entirely new 
    concept. Having said that, it is unique in the sense that it consists of 
    rounded asymmetric hexagons, plus it's a buffer-stored raymarched field that 
    can render pretty quickly... if you have a machine that works well reading 
    textures. I won't go as far as to say that it's an extruded straight edged 
    Voronoi grid, but it definitely has that kind of feel to it.
	
    There are too many possible improvements and enhancements to name. There are 
    provisions within the code for neighboring hexagon checks, which allows for all 
    kinds of features like bridges, stairs, etc, but of course that would add to 
    the complexity. Either way, I'd like to do something along those lines at some 
    stage. For anyone interested, I'll put up a simple version featuring just the
	offset hexagons soon.

    

	Other examples:

	// I've always been a fan of Tomkh's work.
    Voronoi Column Tracing -  Tomkh 
	https://www.shadertoy.com/view/4lyGDV
    Base on:
    Reactive Voronoi - Glk7
    https://www.shadertoy.com/view/Ml3GDX
    
	// Here's a proper Voronoi traverser. Like all TekF's stuff, it's 
    // very stylish and confusingly fast. :)
    TekF - Infinite City 
	https://www.shadertoy.com/view/4df3DS


*/




// Max ray distance.
#define FAR 20.



// Scene object ID to separate the mesh object from the terrain.
float objID;


// The path is a 2D sinusoid that varies over time, which depends upon the frequencies and amplitudes.
vec2 path(in float z){ 
    
    //return vec2(0);
    return vec2(3.*sin(z*.1) + .5*cos(z*.4), .25*(sin(z*.875)*.5 + .5));
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



// The height map. It was orginally supposed to be a fast texture call, but then
// I was insistent on creating a valley that followed the camera path, which would
// be pretty difficult to encode into a repeat texture... Anyway, it's slower now,
// but within acceptable ranges.
float hmBlock(in vec2 p){ 
    
    //vec2 q = p; 
    
    // Wrapping things around the camera path.
    vec2 pth = path(p.y);
    p -= pth; // Y is the Z coordinate here.
    
    float d = abs((p.x + .5) - .5)*2.;
    
    // Scaling by 1/16 and snapping to repeat texture pixels. Alternatively, you 
    // can change the cube map filter to "nearest" and save a calculation, which
    // is what I've done.
    p /= 16.;
    // p = (floor(p*1024./16.) + .5)/1024.;  
    
    // Retrieving the height value from the precalculated wrapped texture map.
    float h = tx5(iChannel0, p).x; 
                    
    // Carving out a path.
    h = mix(h + pth.y,  h/1.5 + pth.y/2., 1. - smoothstep(0., .75, d - .15));
    
    // Quantizing the height levels. More expensive, but it looks a little neater.
    #ifdef QUANTIZE_HEIGHT
    h = floor(h*(LEVELS + .999))/LEVELS; 
    #endif
    h = max(h, WLEV/LEVELS);
/*
    if(h<= WLEV/LEVELS + .001) {
            
            float sf = dot(sin(q*8. - cos(q.yx*16. + iTime*2.)), vec2(.012)) - .024;
            //h += sf;
    }
*/
    return h;  
}




// A regular extruded block grid.
//
// The idea is very simple: Produce a normal grid full of packed square pylons.
// That is, use the grid cell's center pixel to obtain a height value (read in
// from a height map), then render a pylon at that height.
 
// Global vertices, local coordinates of the offset hexagon cell, plus the extruded 
// face information. It's lazy putting them here, but I'll tidy them up later.
vec4[3] gV;
vec2 gP;
float d2D;


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
    // unforturnately weren't practical for this particular example.
    //vec4 p45 = tx5(iChannel0, uv); 

    #ifndef QUANTIZE_WATER
    // Continuous water levels, meaning the water appears as a wavy coninuous plane.
    float sf = dot(sin(q*8. - cos(q.zxy*16. + iTime*2.)), vec3(.006)) - .018;
    #endif
    
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
  

    d2D = 1e5;
    
    float hexH = 0.; // Hexagon pylon height.
    
    

    // Height scale.
    const float hs = .6;


    // Initializing the global vertices and local coordinates of the hexagon cell.
    gV = vec4[3](vec4(0), vec4(0), vec4(0));
    gP = p;
    
    for(int i = min(0, iFrame); i<4; i++){

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
         
        vec4 vrt0 = idi.xyxy + vert[0]/2.;
        vec4 vrt1 = idi.xyxy + vert[1]/2.;
        vec4 vrt2 = idi.xyxy + vert[2]/2.;
        vrt0 = hash42B(vrt0);
        vrt1 = hash42B(vrt1);
        vrt2 = hash42B(vrt2);
         
        const float vo = .15;
        vert[0] += vrt0*vo;
   		vert[1] += vrt1*vo;
        vert[2] += vrt2*vo;
        //vert[3] += vrt1.zw*vo;
        //vert[4] += vrt2.xy*vo;
        //vert[5] += vrt2.zw*vo;
        #endif
 
        
        // Scaling to enable rendering back in normal space.
        vert[0] *= dim.xyxy;
        vert[1] *= dim.xyxy;
        vert[2] *= dim.xyxy;

        
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
        // float face1 = sdPoly(p, vert); 
  
        
        float h1 = hmBlock(idi); //p42[i] For future stored heights.
      
        // Animating the water levels. I added this at the last minute, so there'd
        // be better ways to go about it.
        if(h1<= WLEV/LEVELS + .001) {
            
            #ifdef QUANTIZE_WATER
            float sf = dot(sin(idi*8. - cos(idi.yx*16. + iTime*2.)), vec2(.012)) - .024;
            #endif
            h1 += sf;
        }

        h1 *= hs; // Height scaling.
        
        // Extruded offset hexagon.
        float face1Ext = opExtrusion(face1, (q.z - h1), h1); 
        
        face1Ext += max(face1, -.015)*.5;
         
        // Adding the top to the heigher pylons to act as roofs.
        #ifdef ARID
        if(h1>.4) face1Ext += face1*.35;
        #else
        if(h1>.4) face1Ext += face1*(h1*.6 + .25); 
        #endif

        
        // If applicable, update the overall minimum distance value,
        // ID, and box ID. 
        if(face1Ext<d){
            d = face1Ext;
            id = idi;
            hexH = h1;
       
            
            // Setting the vertices and local coordinates.
            gV = vert;
            gP = p;
            
            d2D = face1;
     
        }
        
    }
    
    // Return the distance, position-based ID and triangle ID.
    return vec4(d, id, hexH);
}



// Block ID -- It's a bit lazy putting it here, but it works. :)
vec4 gID;

// The extruded image.
float map(vec3 p){
    
    // Floor.
    float fl = p.y;

    // The extruded blocks.
    vec4 d4 = blocks(p.xzy);
    gID = d4; // Individual block ID.
 
 
    // Overall object ID.
    objID = fl<d4.x? 1. : 0.;
    
    // Combining the floor with the extruded image
    return min(fl, d4.x);
 
}

 
// Basic raymarcher.
float trace(in vec3 ro, in vec3 rd){

    // Overall ray distance and scene distance.
    float t = 0., d;
    
    for(int i = 0; i<96; i++){
    
        d = map(ro + rd*t);
        // Note the "t*b + a" addition. Basically, we're putting less emphasis on accuracy, as
        // "t" increases. It's a cheap trick that works in most situations... Not all, though.
        if(abs(d)<.001*(1. + t*.1) || t>FAR) break; // Alternative: 0.001*max(t*.25, 1.), etc.
        
        t += i<32? d*.5 : d*.75; 
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
    const int maxIterationsShad = 32; 
    
    ro += n*.0011;
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
        
        // Note the ray shortening hack here. It's not entirely accurate, but reduces
        // shadow artifacts slightly for this particular stubborn distance field.
        t += clamp(d*.8, .01, .25); 
        
        
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
	float sca = 1.5, occ = 0.;
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
    
    p *= 3.;
    //p.y += iTime;
    
    float n3D2 = n3D(p*2.);
   
    // A bit of fBm.
    float c = n3D(p)*.57 + n3D2*.28 + n3D(p*4.)*.15;
    c = smoothstep(.4, 1., c); // Putting in some dark space.
    
    p = vec3(c, c*c, c*c); // Redish tinge.
    
    return mix(p, p.xzy, n3D2*.4); // Mixing in a bit of purple.
}

// Window distance field.
float distW(vec2 p, float sc){
    
    // Some hastily constructed arch windows consisting
    // of A square with a semi circle on top.
    p.y -= -sc*1.25/3.;
    float ci = length(p - vec2(0, sc*1.25)) - sc;
    float sq = sBox(p, vec2(sc, sc*1.25));
    return min(ci, sq);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord ){

    
    // Screen coordinates.
	vec2 uv = (fragCoord - iResolution.xy*.5)/iResolution.y;
	
	// Camera Setup.
	vec3 ro = vec3(0, 1.15, iTime); // Camera position, doubling as the ray origin.
	vec3 lk = ro + vec3(0, -.2, .25);//vec3(0, -.25, iTime);  // "Look At" position.
    
    // Light positioning. Near the camera.
 	vec3 lp = ro + vec3(-.185, 0, -.625);// Put it a bit in front of the camera.
    
    
    // Moving the camera along the path.
	ro.xy += path(ro.z); 
    lk.xy += path(lk.z); 
    // Artificially moving the light with the camera to give it point light and distant 
    // light qualities... Not accurate, but good enough for the purpose of the example.
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
	rd.xy *= rot2(path(ro.z).x/32.);

    // Setting the global time variable so that the "Common" tab can recognize time.
    setTime(iTime);

	 
    
    // Raymarch to the scene.
    float t = trace(ro, rd);
    
    // Save the block ID and object ID.
    vec4 svGID = gID;
    
    float svObjID = objID;
    
    vec2 svP = gP;
    vec2[6] svV = vec2[6](gV[0].xy, gV[0].zw, gV[1].xy, gV[1].zw, gV[2].xy, gV[2].zw);
    //float svH = gH;
    
    float svD2D = d2D;
  
	
    // Initiate the scene color to black.
	vec3 col = vec3(0);
	
	// The ray has effectively hit the surface, so light it up.
	if(t < FAR){
        
  	
    	// Surface position and surface normal.
	    vec3 sp = ro + rd*t;
	    //vec3 sn = getNormal(sp, edge, crv, ef, t);
        vec3 sn = getNormal(sp, t);
        
          
        // Obtaining the texel color. 
	    vec3 texCol;   

        // The extruded grid.
        if(svObjID<.5){
            
            
            // Colored block, for debug purposes.
            //vec3 rCol = .5 + .45*cos(6.2831*(svGID.w)/2. + vec3(2, 1, 0) + 2.);//hash21(svGID.yz)
             
            // Weighted center offset, so to speak.
            //vec2 dt = (svV[0] + svV[1] + svV[2] + svV[3] + svV[4] + svV[5])/6.;
       
            
            // Coloring, based on extruded hexagonal block height. 
            // It was a bit fiddly, but none of it was difficult...
            // On second thoughts, I didn't enjoy painting the windows
            // on the sides of the offset hexagons, but the rest was OK. :)
            
            // Hexagon pylon face ring.
            vec3 tCol;
            float hex = svD2D; //sdPoly(svP, svV);
            hex = max(abs(hex), abs(sp.y - svGID.w*2.)) - .001;
             
            
            
            // This looks like a bit of a mess, but it's pretty simple: Each 
            // pylon has a face top, and some sides. There are three different
            // height levels, which have different top and side colors. The
            // top level represents the buildings, the middle represents the
            // the surrounding land, and the bottom represents water. The coloring
            // is common sense.
            
            
            // Building colors, depending on the Bavarian looking landscape 
            // or the arid one. By the way, the define can be found in the
            // "Common" tab.
            #ifdef ARID
            float ra = hash21(svGID.yz + .53);
            vec3 rnd2 = vec3(ra, ra*.8, ra*ra*.5);
            
            texCol = vec3(1, .98, .9);
            tCol = vec3(1, .45, .4); 
            //tCol = vec3(.85, .6, .45);
            texCol = clamp(texCol*.9 + rnd2*.2, 0., 1.);
            tCol = clamp(tCol*.9 + rnd2*.2, 0., 1.);
            #else
            float ra = hash21(svGID.yz + .53);
            vec3 rnd2 = vec3(ra, ra*.9, ra*.8);
            
            texCol = vec3(1, .98, .95);
            tCol = vec3(1, .2, .2);
            texCol = clamp(texCol*.8 + rnd2*.4, 0., 1.);
            tCol = clamp(tCol*.8 + rnd2*.4, 0., 1.);
            #endif
            
           
            // Grass colors.
            if(svGID.w<.4) { 
                
                // tCol = mix(tCol, vec3(1)*dot(tCol, vec3(.299, .587, .114)), 1.);
                
                #ifdef ARID
                texCol = vec3(.8, .6, .45)*vec3(1, 1.05, .95);
                tCol = vec3(.7, .5, .4)*vec3(1, 1.05, .95); 
                //texCol = mix(texCol, vec3(1)*dot(tCol, vec3(.299, .587, .114)), .2);
                tCol = mix(tCol, vec3(1)*dot(tCol, vec3(.299, .587, .114)), .2);
                texCol = clamp(texCol*.9 + rnd2*.2, 0., 1.);
                
               
                tCol = clamp(tCol*.9 + rnd2*.2, 0., 1.);
                #else
                texCol = vec3(.8, .5, .3);
                tCol = vec3(.35, .65, .3);//vec3(.8, .5, .3);
                texCol = clamp(texCol*.8 + rnd2*.4, 0., 1.);
                tCol = clamp(tCol*.8 + rnd2*.4, 0., 1.);
                #endif
                
                
                 
            }
            
            //tCol *= vec3(1.4, 1.3, 1.1);
            //texCol = mix(texCol*vec3(1.4, 1.3, 1.1), tCol, .5);
            
            
            // Water colors.
            if(svGID.w<= WLEV/LEVELS*.6 + .001) { 
                texCol = vec3(.35, .65, 1);
                tCol = vec3(.25, .5, 1);
                
                #ifdef ARID
                texCol = clamp(texCol*.85 + rnd2.zyx*.3, 0., 1.)*vec3(.9, .95, 1);
                tCol = clamp(tCol*.85 + rnd2.zyx*.3, 0., 1.)*vec3(.9, .95, 1);
                #else
                texCol = clamp(texCol*.9 + rnd2.zyx*.2, 0., 1.)*vec3(.8, .9, 1);
                tCol = clamp(tCol*.9 + rnd2.zyx*.2, 0., 1.)*vec3(.8, .9, 1);
                #endif
            }
            
            
            // Extra random colors, just to mix things up. It's a simple trick to
            // to make colors just a little more interesting.
            vec3 rnd3 = vec3(hash21(svGID.yz + .73), hash21(svGID.yz + .51), hash21(svGID.yz)) - .5;
            texCol = clamp(texCol + rnd3*.1, 0., 1.);
            tCol = clamp(tCol - rnd3*.1, 0., 1.);
              
            // Applying the top face color and the side color.
            texCol = mix(texCol, tCol, (1. - smoothstep(0., .002, -(sp.y - svGID.w*2.)))*1.);
            texCol = mix(texCol, vec3(0), (1. - smoothstep(0., .002, hex)));
           
            
            
            // Painting the window on the sides of the top level hexagons. My brain was 
            // fighting me on this every step of the way, so I'm glad it's over. :D
            float win = 1e5;
            
            if(svGID.w>.4){ 
                
                
                //vec2 ctr = (svV[0] + svV[1] + svV[2] + svV[3] + svV[4] + svV[5])/6.;

                for(int j = 0; j<6; j++){
                    
                    
                    // Random window ID.
                    float wRnd = hash21(svGID.yz + floor((sp.y - svGID.w*2.)/(1./LEVELS*.6*2.)) + float(j));
                    
                    // Skip the occasional window.
                    if(wRnd<.35) continue;

                    // Current and next vertices.
                    vec2 g = svV[j];
                    vec2 g1 = svV[(j + 1)%6];
                    //vec2 g2 = svV[(j + 5)%6];
                    // Tangent normal.
                    vec2 nj = normalize(g1 - g).yx*vec2(1, -1);

                    // 3D hexagon center position.
                    vec3 cv = vec3(svP.x, 
                                   mod(sp.y - svGID.w*2., 1./LEVELS*.6*2.) - .5/LEVELS*.6*2., 
                                   svP.y);
               
                    // Mid edge position and angle.
                    vec2 gg = mix(g, g1, .5);
                    float ang = atan(gg.y, gg.x);
                    
                    // Polar coordinates.
                    vec2 spos = vec2(cos(ang), sin(ang))*length(gg);
                    vec2 newP = rot2(-atan(nj.x, nj.y))*(svP - spos);
                    
                    // Window base and height.
                    cv.xy = vec2(max(abs(newP.x), abs(newP.y)), cv.y);
                     
                    // Create the window for this particular hexagonal side.
                    float wSize = hash21(svGID.yz + .71)*.075 + .2;
                    win = min(win, distW(cv.xy, 1./LEVELS*.6*wSize*8.*GSCALE.x));

                }
                
                // Render the windows.
                win = max(win, sp.y - svGID.w*2.);
                texCol = mix(texCol, vec3(.1, .05, .03), (1. - smoothstep(0., .003, win - .002))*.5);
                texCol = mix(texCol, vec3(0), 1. - smoothstep(0., .003, win));
                texCol = mix(texCol, vec3(.1, .05, .03), 1. - smoothstep(0., .003, win + .005));
                 
            }
  
  
            // Adding a bit of texture.
            vec3 tx = tex3D(iChannel1, sp*4., sn);
            tx = smoothstep(.0, .5, tx);
            texCol *= tx*.6 + .6;
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
        sh = min(sh + ao*.0, 1.);
	    
	    // Light attenuation, based on the distances above.
	    float atten = 1./(1. + lDist*.05);

    	
    	// Diffuse lighting.
	    float diff = max( dot(sn, ld), 0.);
        //diff = pow(diff, 2.)*1.35; // Ramping up the diffuse.
    	
    	// Specular lighting.
	    float spec = pow(max(dot(reflect(ld, sn), rd ), 0.), 32.); 
	    
	    // Fresnel term. Good for giving a surface a bit of a reflective glow.
        float fre = pow(clamp(1. - abs(dot(sn, rd))*.5, 0., 1.), 2.);
        
		// Schlick approximation. I use it to tone down the specular term. It's pretty subtle,
        // so could almost be aproximated by a constant, but I prefer it. Here, it's being
        // used to give a hard clay consistency... It "kind of" works.
		float Schlick = pow( 1. - max(dot(rd, normalize(rd + ld)), 0.), 5.);
		float freS = mix(.15, 1., Schlick);  //F0 = .2 - Glass... or close enough.        
        
        // Combining the above terms to procude the final color. I'm applying more of a
        // conventioning shadow shade, which usually entails multiplying it by the 
        // diffuse component. Sometimes, I'll apply it to everything.
        col = texCol*(diff*sh + ao*.15 + .05 + vec3(1, .9, .7)*fre*.1);
       
        
        // Cheap environmapping for the water.
        if(svGID.w<= WLEV/LEVELS*.6 + .001) {
            vec3 cTex = envMap(reflect(rd, sn));
            col *= (.85 + cTex*1.5);
        }
        
        
        // Applying the ambient occlusion and attenuated light.
        col *= ao*atten;
	
	}
    
    // Applying some fog on the horizon.
    vec3 fog = mix(vec3(1, .9, .5), vec3(.5, .7, 1), rd.y*.5 + .5);
    col = mix(col, fog, smoothstep(0., .99, t/FAR));
    
    
    #ifdef GRAYSCALE
    // Well, close to greyscale, but not quite. :)
    col = vec3(1.05, 1, .95)*mix(col, vec3(1)*dot(col, vec3(.299, .587, .114)), .9);
    #endif

    // Rough gamma correction.
	fragColor = vec4(sqrt(max(col, 0.)), 1);
	
}