


// A regular extruded block grid.
//
// The idea is very simple: Produce a normal grid full of packed objects.
// That is, use the grid cell's center pixel to obtain a height value (read in
// from a height map), then render a pylon at that height.

// For a 2D extruded block tiling four objects are needed. For the Cairo tiling,
// each block needs to be subdivided into two seperate pentagonal pieces, so 
// that's eight pentagon distances all up. Since there are no vec8 containers in 
// WebGL, we need to make one. By the way, for regular 2D Cairo tiles, you only 
// need four or even two, depending what you're trying to do.
//
struct vect8{ vec4 distA; vec4 distB; vec4 distC; };


vect8 df(vec2 q){
    
    
    // Block dimension: Length to height ratio with additional scaling. By the way,
    // I'm being sneaky here and not applying the vec2(.8660254, 1) stretch scaling
    // that gives you proper scaled hexagons. One reason is that they're mutated by
    // the offset vertices anyway, and the main one is that it makes wrapping more
    // difficult. Not impossible, but more complicated.
	const vec2 dim = GSCALE;
    // A helper vector, but basically, it's the size of the repeat cell.
	const vec2 s = dim*2.; 
   

    // Cell center, local coordinates and overall cell ID.
    vec2 p, ip;
    
    // Individual block ID.
    vec2 cntr = vec2(0);

    
    // Four block corner postions.
    const vec2 ll = vec2(.5);
    //vec2[4] ps4 = vec2[4](vec2(-ll.x, ll.y), ll, -ll, vec2(ll.x, -ll.y));
    #ifdef FLAT_TOP
    // Flat top.
    vec2[4] ps4 = vec2[4](vec2(-ll.x, ll.y), ll + vec2(0., ll.y), -ll, vec2(ll.x, -ll.y) + vec2(0., ll.y));
    #else
    // Pointed top.
    vec2[4] ps4 = vec2[4](vec2(-ll.x, ll.y), ll, -ll + vec2(ll.x, 0), vec2(ll.x, -ll.y) + vec2(ll.x, 0));
    #endif
    
    
    vect8 tile;

    // Height scale. Not used here.
    //const float hs = .15;

   
    for(int i = min(iFrame, 0); i<4; i++){

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
        
        // Scaling the ID.
	    idi *= s;
 
  
          
        // Hexagon vertices.
        vec2[6] v1 = vec2[6](vert[0].xy, vert[0].zw, vert[1].xy, vert[1].zw, vert[2].xy, vert[2].zw);
        

        // Moving the vertices in to help create rounded hexagons. Rounded offset hexgons can
        // be created by simply adding a factor to the distance field. Unfortunately, in a 
        // packed grid, that would create overlap, so it's necessary to move the points in
        // first, then add the amount. This is less trivial, as you can see, but is just a
        // bit of trigonometry. The following is robust, but was something I came up with on
        // the spot, so if anyone knows of a more elegant way, feel free to let me know.
        // Remember that this is just a one-off precalculation, so speed isn't a factor.
        const float ndg = .0175*8.*GSCALE.x;
        vec2[6] tmpV;
        
        for(int j = min(iFrame, 0); j<6; j++){
            
            // Vertices and flanking neighbors.
            vec2 g = v1[j];
            vec2 g1 = v1[(j + 1)%6];
            vec2 g2 = v1[(j + 5)%6];
            vec2 nj = normalize(g1 - g); // Tangent vector.
         
            // Move the vertices in the direction of the tangent vector
            // by the nudge factor.
            vec2 v1 = g - g1;
            vec2 v2 = g - g2;
            // Angle between vectors.
            float ang = acos(dot(v1, v2)/length(v1)/length(v2));
            float sl = ndg/tan(ang/2.);
            tmpV[j] = g + sl*nj + ndg*nj.yx*vec2(1, -1);
            
            if(dot(v1, vec2(1))>1e8) break; // Fake break to get compile time down.
        }
                               
        v1 = tmpV;                 

        float face1 = sdPoly(p, v1);
        // float face1 =  sHexS(p, scale/2.);
        face1 -= ndg*.9;
        tile.distA[i] = face1;
        
        // No precalculated heights for this example, since we'll be reading
        // from a precalculated texture in the "Image" tab.
        /*
        // Using the original outer vertices for the offset factor.
        vec2 inC = vec2(0);//(vert[0].xy + vert[0].zw + vert[1].xy + vert[1].zw + vert[2].xy + vert[2].zw)/6.;
        vec2 idi1 = idi + inC.xy;
        float h = hm(idi1);
        tile.distB[i] = h;
        */
        
        
    }
    
    // Return the tile struct.
    return tile;

}


// Cube mapping for face identification - Adapted from one of Fizzer's routines. 
int CubeFaceCoords(vec3 p){

    // Elegant cubic space stepping trick, as seen in many voxel related examples.
    vec3 f = abs(p); f = step(f.zxy, f)*step(f.yzx, f); 
    
    ivec3 idF = ivec3(p.x<.0? 0 : 1, p.y<.0? 2 : 3, p.z<0.? 4 : 5);
    
    return f.x>.5? idF.x : f.y>.5? idF.y : idF.z; 
}


void mainCubemap(out vec4 fragColor, in vec2 fragCoord, in vec3 rayOri, in vec3 rayDir){
    
    
    // UV coordinates.
    //
    // For whatever reason (which I'd love expained), the Y coordinates flip each
    // frame if I don't negate the coordinates here -- I'm assuming this is internal, 
    // a VFlip thing, or there's something I'm missing. If there are experts out there, 
    // any feedback would be welcome. :)
    vec2 uv = fract(fragCoord/iResolution.y*vec2(1, -1));
    
    // Adapting one of Fizzer's old cube mapping routines to obtain the cube face ID 
    // from the ray direction vector.
    int faceID = CubeFaceCoords(rayDir);
    
    
    // Setting the global time variable so that the "Common" tab can recognize time.
    setTime(iTime);
  
    // Pixel storage.
    vec4 col;
   
    // Initial conditions -- Performed just the once upon initialization.
    //if(abs(tx(iChannel0, uv).w - iResolution.y)>.001){
    //
    // IQ gave me the following tip, which saved me a heap of trouble and an extra channel. 
    // I'm not sure how he figured this out, but he pretty much knows everything. :D
    //
    // If the texture hasn't loaded, or if we're on the first frame, initialize whatever 
    // you wish to initialize. In this case, I'm precalculating an expensive distance
    // field and storing it in some of the cube map faces.
    if(textureSize(iChannel0, 0).x<2 || iFrame<1){
        
        // INITIALIZING.
        
        // Construct a distance field, then store it.
    	vect8 d = df(uv);
        
        if(faceID == 0) col = d.distA; // Distance fields.
        //if(faceID == 1) col = d.distB; // Pylon heights.
        if(faceID == 5) col = vec4(1)*hm(uv);//d.distB; // Pylon heights.
    
        
        //repSc = 1024.;
        //if(faceID == 5) {
            //col = vec4(1)*hm(uv*repSc);
        //}
     
    }
    else {
        if(faceID == 0) col = tx0(iChannel0, uv);
        //if(faceID == 1) col = tx1(iChannel0, uv);
        if(faceID == 5) col = tx5(iChannel0, uv);
        
    }


    // Store in the cube map.
    fragColor = col;
    
}