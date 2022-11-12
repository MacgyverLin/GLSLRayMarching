/*

    Extruded Truchet Pattern
    ------------------------
    
    I enjoy utilizing simple 2D techniques to render faux 3D imagery.
    Sometimes, I'll do it for nostalgic reasons, and other times out of 
    sheer curiosity to see if it's possible to make a particular 3D 
    scene without the use of a 3D rendering scheme.
    
    Anyway, a while back, I raymarched a very basic extruded blobby 
    square grid-based Truchet in order to have an actual 3D visual 
    reference when constucting my "Faux Layered Extrusion" example. I 
    came across it recently, so decided to pretty it up a little.
    
    I enjoyed making this, mainly because it didn't involve any thinking.
    The 2D blobby Truchet consisted of just a few lines, extruding it 
    was as simple as it gets, and the coloring was just applying 2D 
    rendering techniques to the floor and top extruded face. I wish all 
    examples were this easy. :) By the way, I'm going to post a slightly 
    more complicated blobby Truchet example after this.
    


    References:

    // Fake 3D extrusion using 2D techniques.
	Faux Layered Extrusion - Shane
    https://www.shadertoy.com/view/Wsc3Ds

    // BigWIngs's popular Youtube channel. It's always informative seeing how 
    // others approach various graphics topics.
    Shader Coding: Truchet Tiling Explained! -  The Art of Code
	https://www.youtube.com/watch?v=2R7h76GoIJM


*/
 

// Show the blue floor markers.
//#define BLUE_MARKERS

// Subtle textured lines.
#define LINES

// Curve shape - Round: 0, Semi-round: 1, Octagonal: 2, Superellipse: 3, Straight: 4.
#define SHAPE 0


// Object ID: Either the back plane, extruded object or beacons.
int objID;

// Standard 2D rotation formula.
mat2 rot2(in float a){ float c = cos(a), s = sin(a); return mat2(c, -s, s, c); }

// IQ's vec2 to float hash.
float hash21(vec2 p){  return fract(sin(dot(p, vec2(27.619, 57.583)))*43758.5453); }


// Various distance metrics.
float dist(vec2 p){

    #if SHAPE == 0
    return length(p);
    #else 
    p = abs(p);
    #endif
    
    #if SHAPE == 1
    return max(length(p), (p.x + p.y)*.7071 + .015);
    #elif SHAPE == 2
    return max((p.x + p.y)*.7071, max(p.x, p.y));
    #elif SHAPE == 3
    return pow(dot(pow(p, vec2(3)), vec2(1)), 1./3.); // 1.666, 4., etc.
    #else
    return (p.x + p.y)*.7071;
    #endif
    

}

/*
// IQ's extrusion formula.
float opExtrusion(in float sdf, in float pz, in float h, in float sf){

    // Slight rounding. A little nicer, but slower.
    vec2 w = vec2( sdf, abs(pz) - h) + sf;
  	return min(max(w.x, w.y), 0.) + length(max(w, 0.)) - sf;
}
*/

// A standard square grid 2D blobby Truchet routine: Render circles
// in opposite corners of a tile, reverse the pattern on alternate
// checker tiles, and randomly rotate.
float tr(vec2 p){

    
    // ID and local coordinates.
    const float sc = .5;
    vec2 ip = floor(p/sc) + .5;
    p -= ip*sc;
    
    // Random value, and alternate checkers.
    float rnd = fract(sin(dot(ip, vec2(1, 113)))*45758.5453);
  
    if(rnd<.5) p.y = -p.y; // Rotate.
    
    // Opposite diagonal circles distances, etc.
    float d = min(dist(p - .5*sc), dist(p + .5*sc)) - .5*sc;
    #if SHAPE == 4
    // If using straight lines, adjusting the width. 
    d += (.5 - .5/sqrt(2.))*sc;
    #endif
    
    if(rnd<.5) d = -d; // Flip random.
    
    // Comment out to spoil the illusion.
    if(mod(ip.x + ip.y, 2.)<.5) d = -d; // Flip alternate checkers.
    
    // Using a little CSG for some double edges. Interesting,
    // but "less is more," as they say. :)
    //return min(d, abs(d + .03) - .03 - sc/8.); // Truchet border.
    
    // Wided the field a little, then return.
    return d - .03;

}
 
// The scene's distance function: There'd be faster ways to do this, but it's
// more readable this way. Plus, this  is a pretty simple scene, so it's 
// efficient enough.
float m(vec3 p){
    
    // Back plane.
    float fl = -p.z;
    
    // 2D Truchet distance, for the extrusion cross section.
    float obj = tr(p.xy);
    
    // Extrude the 2D Truchet object along the Z-plane. Note that this is a cheap
    // hack. However, in this case, it doesn't make much of a visual difference.
    obj = max(obj, abs(p.z) - .125) - smoothstep(.03, .25, -obj)*.1;
    // Proper extrusion formula for comparisson.
    //obj = opExtrusion(obj, p.z, .125, .01) - smoothstep(.03, .25, -obj)*.1; 
    
    // Put some cylinder markers at opposite diagonals on the Truchet tiles.
    // This is for purely decorational purposes.
    float studs = 1e5;
    const float sc = .5;
    // Unique cell ID and local cell coordinates.
    vec2 q = p.xy + .5*sc;
    vec2 iq = floor(q/sc) + .5;
    q -= iq*sc;
    
    if(mod(iq.x + iq.y, 2.)>.5){  
        studs = max(length(q) - .1*sc - .02, abs(p.z) - .26);       
    }
    #ifdef BLUE_MARKERS
    else {
        studs = max(length(q) - .1*sc - .03, abs(p.z - .125) - .175);
    }
    #endif
    
    // Object ID.
    objID = fl<obj && fl<studs? 0 : obj<studs? 1 : 2;
    
    // Minimum distance for the scene.
    return min(min(fl, obj), studs);
    
}

// Cheap shadows are hard. In fact, I'd almost say, shadowing particular scenes with limited 
// iterations is impossible... However, I'd be very grateful if someone could prove me wrong. :)
float softShadow(vec3 ro, vec3 lp, vec3 n, float k){

    // More would be nicer. More is always nicer, but not affordable for slower machines.
    const int iter = 24; 
    
    ro += n*.0015; // Bumping the shadow off the hit point.
    
    vec3 rd = lp - ro; // Unnormalized direction ray.

    float shade = 1.;
    float t = 0.; 
    float end = max(length(rd), 0.0001);
    rd /= end;
    
    //rd = normalize(rd + (hash33R(ro + n) - .5)*.03);
    

    // Max shadow iterations - More iterations make nicer shadows, but slow things down. Obviously, the lowest 
    // number to give a decent shadow is the best one to choose. 
    for (int i = 0; i<iter; i++){

        float d = m(ro + rd*t);
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
float calcAO(in vec3 p, in vec3 n){

	float sca = 2., occ = 0.;
    for( int i = min(iFrame, 0); i<5; i++ ){
    
        float hr = float(i + 1)*.15/5.;        
        float d = m(p + n*hr);
        occ += (hr - d)*sca;
        sca *= .7;
        
        // Deliberately redundant line that may or may not stop the 
        // compiler from unrolling.
        if(sca>1e5) break;
    }
    
    return clamp(1. - occ, 0., 1.);
}
  
// Standard normal function.
vec3 nr(in vec3 p){
	const vec2 e = vec2(.001, 0);
	return normalize(vec3(m(p + e.xyy) - m(p - e.xyy), m(p + e.yxy) - m(p - e.yxy),	
                          m(p + e.yyx) - m(p - e.yyx)));
}


void mainImage(out vec4 c, vec2 u){

    
    // Aspect correct coordinates. Only one line necessary.
    u = (u - iResolution.xy*.5)/iResolution.y;    
    
    // Unit direction vector, camera origin and light position.
    vec3 r = normalize(vec3(u, 1)), o = vec3(0, iTime/2., -3), l = o + vec3(.25, .25, 2.);
    
    // Rotating the camera about the XY plane.
    r.yz = rot2(.15)*r.yz;
    r.xz = rot2(-cos(iTime*3.14159/32.)/8.)*r.xz;
    r.xy = rot2(sin(iTime*3.14159/32.)/8.)*r.xy; 
  
    
    // Standard raymarching setup.
    float d, t = hash21(r.xy*57. + fract(iTime))*.5, glow = 0.;
    // Raymarch.
    for(int i=0; i<96; i++){ 
        
        d = m(o + r*t); // Surface distance.
        // Surface hit -- No far plane break, since it's just the floor.
        if(abs(d)<.001) break; 
        t += d*.7; // Advance the overall distance closer to the surface.
        
        // Accumulating light values along the way for some cheap glow.
        //float rnd = hash21(r.xy + float(i)/113. + fract(iTime)) - .5;
        glow += .2/(1. + abs(d)*5.);// + rnd*.2;
        
         
    }
    
    // Object ID: Back plane (0), or the metaballs (1).
    int gObjID = objID;
    
    
    // Very basic lighting.
    // Hit point and normal.
    vec3 p = o + r*t, n = nr(p); 
    
    
    // UV texture coordinate holder.
    vec2 uv = p.xy;
    // Cell ID and local cell coordinates for the texture we'll generate.
    float sc = .5; // Scale: .5 to about .2 seems to look OK.
    vec2 iuv = floor(uv/sc) + .5; // Cell ID.
    uv -= iuv*sc; // Local cell coordinates.
    
    // Half cell offset grid.
    vec2 uv2 = p.xy + .5*sc;
    vec2 iuv2 = floor(uv2/sc) + .5;
    uv2 -= iuv2*sc;
    
    // Smooth borders.
    float bord = max(abs(uv.x), abs(uv.y)) - .5*sc;
    bord = abs(bord) - .002;
    
    // 2D Truchet face distace -- Used to render borders, etc.
    d = tr(p.xy);
    
    // Subtle lines for a bit of texture.
    #ifdef LINES
    float lSc = 20.;
    float pat = (abs(fract((uv.x - uv.y)*lSc - .5) - .5)*2. - .5)/lSc;
    float pat2 = (abs(fract((uv.x + uv.y)*lSc + .5) - .5)*2. - .5)/lSc;
    #else
    float pat = 1e5, pat2 = 1e5;
    #endif     
     
    // Colors for the floor and extruded face layer. Each were made up and 
    // involve subtle gradients, just to mix things up.
    float sf = dot(sin(p.xy - cos(p.yx*2.)), vec2(.5));
    float sf2 = dot(sin(p.xy*1.5 - cos(p.yx*3.)), vec2(.5));
    vec4 col1 = mix(vec4(1., .75, .6, 0), vec4(1, .85, .65, 0), smoothstep(-.5, .5, sf));
    vec4 col2 = mix(vec4(.4, .7, 1, 0), vec4(.3, .85, .95, 0), smoothstep(-.5, .5, sf2)*.5);
    col1 = pow(col1, vec4(1.6));
    col2 = mix(col1.zyxw, pow(col2, vec4(1.4)), .666);
    
    // Object color.
    vec4 oCol;
  
    
    // Use whatever logic to color the individual scene components. I made it
    // all up as I went along, but things like edges, textured line patterns,
    // etc, seem to look OK.
    //
    if(gObjID == 0){
    
       // The blue floor:
       
       // Blue with some subtle lines.
       oCol = mix(col2, vec4(0), (1. - smoothstep(0., .01, pat2))*.35);
       // Square borders: Omit the middle of edges where the Truchet passes through.
       oCol = mix(oCol, vec4(0), (1. - smoothstep(0., .01, bord))*.8);
       // Darken alternate checkers. 
       if(mod(iuv.x + iuv.y, 2.)>.5) oCol *= .8;
       
       // Using the Truchet pattern for some bottom edging.
       oCol = mix(oCol, vec4(0), (1. - smoothstep(0., .01, d - .015))*.8);
       
       #ifdef BLUE_MARKERS
       // If the blue markers are included, render dark rings just under them.
       oCol = mix(oCol, vec4(0), (1. - smoothstep(0., .01, length(uv2) - .09))*.8);
       #endif
       
    }
    else if(gObjID==1){
    
        // Extruded Truchet:
 
        // White sides with a dark edge. 
        oCol = mix(vec4(1), vec4(0), 1. - smoothstep(0., .01, d + .05));
        
        // Golden faces with some subtle lines.
        vec4 fCol = mix(col1, vec4(0), (1. - smoothstep(0., .01, pat))*.35);
        // Square borders: Omit the middle of edges where the Truchet passes through.
        fCol = mix(fCol, vec4(0), (1. - smoothstep(0., .01, bord))*.8);
        // Darken alternate checkers on the face only.
        if(mod(iuv.x + iuv.y, 2.)<.5) fCol *= .8;
        
        // Apply the golden face to the Truchet, but leave enough room
        // for an edge.
        oCol = mix(oCol, fCol, 1. - smoothstep(0., .01, d + .08));
        
        
        // If the golden markers are included, render dark rings just under them.
        oCol = mix(oCol, vec4(0), (1. - smoothstep(0., .01, length(uv2) - .08))*.8);
        
    }
    else {
    
        // The cylinder markers:
        
        // Color and apply patterns, edges, etc, depending whether it's
        // blue floor makers or a golden Truchet one.
        oCol = col1;
        float ht = .26;
        if(mod(iuv2.x + iuv2.y + 1., 2.)>.5) {
            float tmp = pat; pat = pat2; pat2 = tmp;
            oCol = col2;
            ht = .05;
        }
        
        // Marker dot or outer edge.
        float mark = length(uv2);
        float markRim = max(abs(mark - .07), abs(p.z + ht)) - .003;
        
        // Render the pattern, edge and face dot.
        //oCol = mix(oCol, vec4(0), (1. - smoothstep(0., .01, max(pat, abs(p.z + ht))))*.35);
        oCol = mix(oCol, vec4(0), (1. - smoothstep(0., .01, markRim))*.8);
        oCol = mix(oCol, vec4(0), (1. - smoothstep(0., .01, mark - .015))*.8);    
    
    } 


    // Basic point lighting.   
    vec3 ld = l - p;
    float lDist = length(ld);
    ld /= lDist; // Light direction vector.
    float at = 1./(1. + lDist*lDist*.125); // Attenuation.
    
    // Very, very cheap shadows -- Not used here.
    //float sh = min(min(m(p + ld*.08), m(p + ld*.16)), min(m(p + ld*.24), m(p + ld*.32)))/.08*1.5;
    //sh = clamp(sh, 0., 1.);
    float sh = softShadow(p, l, n, 8.); // Shadows.
    float ao = calcAO(p, n); // Ambient occlusion.
    
    
    float df = max(dot(n, ld), 0.); // Diffuse.
    float sp = pow(max(dot(reflect(r, n), ld), 0.), 32.); // Specular.
    
      
    // Apply the lighting and shading. 
    c = oCol*(df*sh + sp*sh + .5)*at*ao;
    // Very metallic: Interesting, but ultimately, a bit much. :)
    //c = oCol*oCol*1.5*(pow(df, 3.)*2.*sh + sp*sh*2. + .25)*at*ao;
     
 
    // Rough gamma correction.
    c = sqrt(max(c, 0.));  

}