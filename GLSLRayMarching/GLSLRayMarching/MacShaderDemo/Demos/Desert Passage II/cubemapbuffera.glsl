



// It can be a bit fiddly filling all four channels in at once, but thankfully, this is
// all calculated at startup. The idea is to put the function you wish to use in the
// middle of the loop here, instead of writing it out four times over.
vec4 funcFace0(vec3 p){
   
    
    //vec3 pix = vec3(1./4./dims.x, 0, 0);
    vec3 pix = vec3(1./1./dims.x, 0, 0);
 
    vec4 col;
    
    for(int i = 0; i<4; i++){
        
        vec3 q = p + vec3(0, i&1, i>>1)/dims.x;
        
        vec3 rotF = vec3(0); // Rotation factor - Range: [0, 1].
        
        // Wrapped multilayer tertiary order Voronoi.
        gSc = vec3(4);
        vec3 sc = vec3(1, 1, 1);
        vec3 v = Voronoi(q*gSc, sc, rotF, 1./1., 1);
        float res = max(1.-v.x, 0.);// mix(max(1. - v.x, 0.), (v.y - v.x), .0);
        gSc = vec3(8);
        sc = vec3(1, 1, 1);
        v = Voronoi((q - .0)*gSc, sc, rotF, 1., 1);
        res = mix(res, 1. - max(1. - v.x, 0.), .125); 
        //res = min(res, max((1. - v.x)/2., 0.));
        gSc = vec3(16);
        sc = vec3(1, 1, 1);
        rotF = vec3(1);
        v = Voronoi((q - .0)*gSc, sc, rotF, 1., 1);
        res = mix(res, max(v.y - v.x, 0.), .0625); 
        
    
        // The pixel channel value: On a side note, setting it to "v.y" is interesting,
        // but not the look we're going for here.
        col[i] = res;//max(1. - res*.85 - res*res*.15, 0.);
         
        //p += pix;
        
    }
    
    // Return the four function values -- One for each channel.
    return col;
    
}




// It can be a bit fiddly filling all four channels in at once, but thankfully, this is
// all calculated at startup. The idea is to put the function you wish to use in the
// middle of the loop here, instead of writing it out four times over.
vec4 funcFace1(vec2 uv){
    
    // It's a 2D conversion, but we're using a 3D function with constant Z value.
    vec3 p;
    // Just choose any Z value you like. You could actually set "p.z" to any constant,
    // or whatever, but I'm keeping things consistant.
    p.z = floor(.0*cubemapRes.x)/cubemapRes.x; 
       
    vec4 col;
    
    for(int i = 0; i<4; i++){

        // Since we're performing our own 2D interpolation, it makes sense to store
        // neighboring values in the other pixel channels. It makes things slightly
        // more confusing, but saves four texel lookups -- usually in the middel of
        // a raymarching loop -- later on.
        
        // The neighboring position for each pixel channel.
        p.xy = mod(floor(uv*cubemapRes) + vec2(i&1, i>>1), cubemapRes)/cubemapRes;

        // Individual Voronoi cell scaling.
        vec3 sc = vec3(1);
        vec3 rotF = vec3(0); // Rotation factor.
        
        // Put whatever function you want here. In this case, it's Voronoi.
        gSc = vec3(8);
        vec3 v = Voronoi(p*gSc, sc, rotF, 1., 0);
        float res = 1. - v.x;
        //gSc = vec3(16);
        //v = Voronoi(p*gSc, sc, rotF, 1., 1);
        //res = mix(res, v.y - v.x, .333);
        // The pixel channel value: On a side note, setting it to "v.y" is interesting,
        // but not the look we're going for here.
        
        // Layering in some noise as well. This is all precalculated, so speed isn't
        // the primary concern... Compiler time still needs to be considered though.
        gSc = vec3(4);
        float res2 = n3DT(p*gSc);
        gSc = vec3(8);
        res2 = mix(res2, n3DT(p*gSc), .333);
        gSc = vec3(16);
        res2 = mix(res2, n3DT(p*gSc), .333);
        //gSc = vec3(16);
        //res2 = mix(res2, n3DT(p*gSc), .333);
        
        // Mix in the Voronoi and the noise.
        col[i] =  mix(res, res2, .5);

    }
    
    return col;
}

// Converting your UV coordinates to 3D coordinates. I've seen some pretty longwinded
// obfuscated conversions out there, but it shouldn't require anything more than 
// the following. By the way, the figure "dims.x" is factored down by four to account
// for the four pixel channels being utilized, but the logic is the same.
vec3 convert2DTo3D(vec2 uv){
    
    // Converting the fract(uv) coordinates from the zero to one range to the whole
    // number, zero to... 1023 range.
    uv = floor(uv*cubemapRes);
    
    // Converting the UV coordinate to a linear representation. The idea is to convert the
    // 2D UV coordinates to a linear value, then use that to represent the 3D coordinates.
    // This way, you can effectively fit all kinds of 3D dimensions into a 2D texture array
    // without having to concern yourself with 2D texture wrapping issues. In theory, so 
    // long as the dimensions fit, and the X dimension is a multiple of four, then anything
    // goes. As mentioned, the maximum cubic dimension allowable for one cube face is 
    // 160 cubed. In that respect, rectangular dimensions, like vec3(160, 80, 320), etc, 
    // would also fit.
    //
    // For instance, the 137th pixel in the third row on a 1024 by 1024 cubemap face texture 
    // would be the number 2185 (2*1024 + 137).
    float iPos = dot(uv, vec2(1, cubemapRes.x));
    
    // In this case the XY slices comprise of 160 pixels (or whatever number we choose) along 
    // X and Y, so the pixel position in any block would be modulo 160*160. The xyBlock position 
    // would have to be converted to X and Y positions, which would be xyBlock mod dimX, and 
    // floor(xyBlock/dimX) mod dimY respectively. The Z position would depend on how many 
    // 160 by 160 blocks deep we're in, which translates to floor(iPos/(dimX*dimY)).
    //
    // Anyway, that's what the following lines represent.
    
    // XY block (or slice) linear position.
    float xyBlock = mod(iPos, dims.x*dims.y);
    
    // Converting to X, Y and Z position.
    vec3 p = vec3(mod(floor(vec3(xyBlock, xyBlock, iPos)/vec3(1, dims.x, dims.x*dims.y)), dims));
    
    //vec3 p = vec3(mod(xySlice, dims.x), mod(floor((xySlice)/dims.x), dims.y),
                  //floor((iPos)/(dims.x*dims.y)));
    
    // It's not necessary, but I'm converting the 3D coordinates back to the zero to one
    // range... There'd be nothing stopping you from centralizing things (p/dims - .5), but 
    // this will do.
    return p/dims;
}



// Cube mapping - Adapted from one of Fizzer's routines. 
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
  
  
    // Pixel storage.
    vec4 col;
    

    // Initial conditions -- Performed upon initiation.
    //if(abs(tx(iChannel0, uv, 5).w - iResolution.y)>.001){
    //if(iFrame<1){
    //
    // Great hack, by IQ, to ensure that this loads either on the first frame, or in the
    // event that the texture hasn't loaded (this happens a lot), wait, then do it...
    // Well kind of. Either way, it works. It's quite clever, which means that it's something 
    // I never would have considered. :)
    if(textureSize(iChannel0,0).x<2 || iFrame<1){
        
        // This is part of an ugly hack that attempts to force the GPU compiler
        // to not unroll the Voronoi loops. Not sure if it'll work, but I'm 
        // trying it anyway, in the hope to get compiler times down on some
        // machines. For the record, this takes about 3 seconds to compile on 
        // my machine.
        gIFrame = iFrame;
        
        
        /*
        // Debug information for testing individual cubeface access.
        if(faceID==0) col = vec4(0, 1, 0, 1);
        else if(faceID==1) col = vec4(0, .5, 1, 1);
        else if(faceID==2) col = vec4(1, 1, 0, 1);
        else if(faceID==3) col = vec4(1, 0, 0, 1);
        else if(faceID==4) col = vec4(.5, .5, .5, 1);
        else col = vec4(1, 1, 1, 1);
        */
        
        
        // Fill the first cube face with a custum 3D function.
        if(faceID==0){
            
            vec3 p = convert2DTo3D(uv);
            
            col = funcFace0(p);
           
        }
        
        // Fill the second cube face with a custom 2D function... We're actually
        // reusing a 3D function, but it's in slice form, which essentially makes
        // it a 2D function.
        if(faceID==1){

            col = funcFace1(uv);
            
        }
        
        

        /*
        // Last channel on the last face: Used to store the current 
        // resolution to ensure loading... Yeah, it's wasteful and it
        // slows things down, but until there's a reliable initiation
        // variable, I guess it'll have to do. :)
        if(faceID==5){
            
            col.w = iResolution.y;
        }
        */

        
    }
    else {
        	
        // The cube faces have already been initialized with values, so from this point,
        // read the values out... There's probably a way to bypass this by using the 
        // "discard" operation, but this isn't too expensive, so I'll leave it for now.
        col = tx(iChannel0, uv, faceID);
    }
    
    
    // Update the cubemap faces.
    fragColor = col;
    
}

