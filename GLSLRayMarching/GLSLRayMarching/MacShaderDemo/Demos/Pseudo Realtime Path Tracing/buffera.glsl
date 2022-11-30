/*

    Pseudo Realtime Path Tracing
    ----------------------------
    
    Using a pseudo path tracing technique to produce a simple realtime scene 
    lit up with multiple emitters. Basically, this was an excuse to play 
    around with pretty colors. :)
    
    At this stage, I'm sure most have seen those cool looking faux realtime 
    path traced examples at demo competitions and on Shadertoy. All of them
    use a simple trick, which I'm sure has been around for ages, but I first
    saw it in Shadertoy user W23's "Path Racer" example.
    
    Path tracing involves multiple bounces with random surface reflections 
    based on surface properties. The results are great -- fuzzy reflections,
    soft lighting, shadows, etc, but require a heap of random samples to look
    right. Regular purely reflected multiple bounce examples require just the 
    one sample, but look too sharp and unnatural.
    
    This particular example uses random surface reflections, but restricts the
    randomness to a fairly narrow cone-like domain around the purely reflected
    ray. That way, you're still getting the fuzzy shadows, lights, etc from
    the surrounding scene. However, due to the narrowness of the random spread
    around the rays, fewer samples are required for things to converge.
    
    The resultant lighting is not entirely realistic, but it looks nice. The 
    weird bounce angles can also be mitigated by using small tiles with 
    variable roughness values. Because of the narrow beams used, smaller 
    roughness values tend to look better, which is fine by me, because it 
    makes everything look more sparkly. :)
    
    Geometrically speaking, the scene is about as basic as it gets. The tiling 
    was made up on the spot and contains random emitters, which act as multiple 
    light sources. The multi-emitter color bleeding effect would be near 
    impossible to emulate using cheaper Blinn-Phong methods. By the way, I 
    settled on the "Organic 2" texture, but it works with others. I almost went
    with the "Stars" texture, which gives things a slight planetarium feel.
    
    
    
    Other examples:
    
    // A lot of the realtime path tracing demos out there
    // are based on elements from this example.
    past racer by jetlag - w23
    https://www.shadertoy.com/view/Wts3W7

    // Simple, but georgeous lighting and colors.
	Corridor Travel - NuSan
    https://www.shadertoy.com/view/3sXyRN

*/


// Sample number and blend number: The trick is to find a balance between the
// two, or use a faster computer. :)

// Number of samples: My computer can handle more. If yours is struggling, you 
// can lower this. Naturally, sample number is proportional to noise quality.
#define sampNum 16

// The blended samples per frame: Higher numbers give the impression of more
// samples, which boosts quality. However, there's a price to pay, and that's 
// ghosting effects. Larger numbers will result in noticeable ghosting.
#define blendNum 4.




// Standard 2D rotation formula.
mat2 rot2(in float a){ float c = cos(a), s = sin(a); return mat2(c, -s, s, c); }


// IQ's vec2 to float hash.
float hash21(vec2 p){  return fract(sin(dot(p, vec2(27.619, 57.583)))*43758.5453); }



// Random seed.
vec2 seed = vec2(.13, .27);

// Vec2 to vec2 hash function.
vec2 hash22() {
    
    seed = fract(seed + vec2(.7123, .6247));
     
    return fract(sin(vec2(dot(seed.xy, vec2(12.989, 78.233)), dot(seed.xy, vec2(41.898, 57.263))))
                      *vec2(43758.5453, 23421.6361));
}

/*
// Vec2 to vec3 hash function.
vec3 hash23(){
    
    seed = fract(seed + vec2(.7123, .6247));
     
    return fract(sin(vec3(dot(seed.xy, vec2(12.989, 78.233)), dot(seed.xy, vec2(39.687, 78.233)),
                          dot(seed.xy, vec2(41.898, 57.263))))*vec3(43758.5453, 23421.6361, 28234.8477));
}
*/

// IQ's box routine.
float sBox(in vec2 p, in vec2 b, float r){

  vec2 d = abs(p) - b + r;
  return min(max(d.x, d.y), 0.) + length(max(d, 0.)) - r;
}



 
// A nice random hemispherical routine taken out of one of IQ's examples.
// The routine itself was written by Fizzer.
vec3 cosDir( in float seed, in vec3 n){

    vec2 rnd = hash22();
    float u = rnd.x;
    float v = rnd.y;
    
    // Method 1 and 2 first generate a frame of reference to use with an arbitrary
    // distribution, cosine in this case. Method 3 (invented by fizzer) specializes 
    // the whole math to the cosine distribution and simplfies the result to a more 
    // compact version that does not depend on a full frame of reference.

    // Method by fizzer: http://www.amietia.com/lambertnotangent.html
    float a = 6.2831853*v;
    u = 2.*u - 1.;
    return normalize(n + vec3(sqrt(1. - u*u)*vec2(cos(a), sin(a)), u));
    
}



// Sphere normal.
vec3 sphereNorm(vec3 p, float id, vec4 sph){
   
    return (p - sph.xyz)/sph.w; 
    
}
 
// Hitting a number of walls from the inside: You could simply raytrace four
// planes, but this is a little more concise. I was too lazy to write my own
// routine, so quickly adapted a working one (sadly, not many of those around) 
// from one of PublicIntI's examples. At some stage, I'll get in amongst it and 
// rewrite one, or find one of my older routines. Alternatively, if someone
// knows of a concise reliable function or sees a way to tidy the following up, 
// feel free to let me know. :)
//
// crystal exhibit(pathtraced) - public_int_i 
// https://www.shadertoy.com/view/wljSRz
//
// Ray-box intersection: The function take in the ray origin (offset if needed)
// the unit direction ray and the box dimensions, then returns the distance and 
// normal.
//
vec4 boxIntersect(vec3 ro, vec3 rd, vec3 dim) {

    const float maxT = 1e8;
 
    vec3 minD = (ro + dim)/rd, maxD = (ro - dim)/rd;
	minD = -(minD - step(vec3(-1e-6), minD)*(minD + maxT));
	maxD = -(maxD - step(vec3(-1e-6), maxD)*(maxD + maxT));
	minD = min(minD, maxD);
    
    // Result: Distance and normal.
    vec4 res = vec4(maxT, 0, 0, 0);

    // Performing some ray-plane intersections, modified to handle
    // two planes at once. I'd imagine you could cleverly combine this
    // into just one test, but I'm not clever, so I'll leave that to 
    // someone else. :D
     
    // We don't need the left and right walls for this example.
    //if (minD.x<maxT){
        //vec2 pd = abs(ro.zy + rd.zy*minD.x) - dim.zy;
        //if (max(pd.x, pd.y) < 0.) res = vec4(minD.x, -sign(rd.x), 0, 0);
    //}
    
    // Top and bottom surfaces, or ceiling and floor, if you prefer.
    if (minD.y<maxT){
        vec2 pd = abs(ro.xz + rd.xz*minD.y) - dim.xz;
        if (max(pd.x, pd.y) < 0.) res = vec4(minD.y, 0., -sign(rd.y), 0.);
    }
    
    // Front and back walls.
    if (minD.z<maxT){
        vec2 pd = abs(ro.xy + rd.xy*minD.z) - dim.xy;
        if (max(pd.x, pd.y) < 0.) res = vec4(minD.z, 0., 0., -sign(rd.z));
       
    }
    
    // Return the distance and normal.
    return res;
}
 
 
// Sphere intersection: Pretty standard, and adapted from one
// of IQ's formulae.
vec2 sphereIntersect(in vec3 ro, in vec3 rd, in vec4 sph){

    vec3 oc = ro - sph.xyz;
	float b = dot(oc, rd);
    if(b > 0.) return vec2(1e8, 0.);
	float c = dot(oc, oc) - sph.w*sph.w;
	float h = b*b - c;
	if(h<0.) return vec2(1e8, 0.);
	return vec2(-b - sqrt(h), 1.); 
    
}


// Sphere position and radius.
const vec4 sph4 = vec4(0, -.32, 1.35, .68);

// Hacking in a normal for the box equation.
vec3 boxNrm;

// Scene normal logic: Not that exciting for this example. :)
vec3 getNorm(vec3 p, float id){
    
    return (id<.5)? sphereNorm(p, id, sph4) : boxNrm; 
}


// Intersection logic for all objects.
vec3 intersect(vec3 ro, vec3 rd){
    
    // Containers for two objects. Usually there'd be more.
    vec2[2] q;
    
    // The sphere.
    q[0] = sphereIntersect(ro, rd, sph4);//vec2(1e5);//
    //q[0].x = 1e5;
 
    // The box tube object, or 4 walls at once, if you prefer. :)
    vec4 bx = boxIntersect(ro - vec3(0, 1, -.5), rd, vec3(1e8, 2, 3.5));
    q[1] = vec2(bx.x, 1);
    boxNrm = bx.yzw; 
   
    
    // Returning the object distance, a hit ID (inside surface, etc, and redundant 
    // for this example) and the object ID used for materials and so forth.
    return q[0].x<q[1].x? vec3(q[0], 0) : vec3(q[1], 1);
    
    /*
    // For more objects, you need to do a little more work.
    vec3 d = vec3(1e5);
    
    for(int i = 0; i<2; i++){
       if(q[i].x< d.x) d = vec3(q[i], i);
    }
        
    return d;
    */
    
}

// The wall and floor pattern, which is just something quick and effective.
// It's an offset row square grid pattern with some random subdivision.
vec3 distField(vec2 p){
    
    // Scale.
    vec2 sc = vec2(1)/5.;//vec2(6./5., 4./5.)/5.;
    
    // Edge width.
    const float ew = .0125;
    
    vec2 q = p;
    // Partitioning into cells and providing the local cell ID
    // and local coordinates.
    //p.x += floor(hash21(floor(p.yy/sc.yy))*1.9999)/2.*sc.x;
    // Offset alternate rows.
    if(mod(floor(p.y/sc.y), 2.)<.5) p.x += sc.x/2.;
    // Cell ID and local coordinates.
    vec2 ip = floor(p/sc);
    p -= (ip + .5)*sc;
    
    // Random subdivision.
    if(hash21(ip + .1/sc)<.5){
        sc /= 2.;
        p = q;
        ip = floor(p/sc);
        p -= (ip + .5)*sc;
         
        /*
        // Extra subdivision.
        if(hash21(ip + .1/sc)<.666){
            sc /= 2.;
            p = q;
            ip = floor(p/sc);
            p -= (ip + .5)*sc;
             
        }*/
    }     
    
    // Rounded square.
    float sh = sBox(p, sc/2. - ew, .15*sc.x);//1.5*sc.x*sc.x
    //float sh = length(p) - sc.x/2. + ew;
 
    // Producing a rounded circle.
    float d = sh; 
    
    // Putting a hole in it just to break things up.
    //d = max(d, -(length(p) - .2*sc.x));
    
    // Rings.
    //d = abs(d + .125*sc.x) - .125*sc.x;
    
    // Returning the distance and local cell ID. Note that the 
    // distance has been rescaled by the scaling factor.
    return vec3(d, ip*sc);
}

// IQ's signed square formula with some roundness thrown in. 
float sBoxS(in vec2 p, in vec2 b, in float rf){
  
  vec2 d = abs(p) - b + rf;
  return min(max(d.x, d.y), 0.) + length(max(d, 0.)) - rf;
    
}


// mat3 rotation... I did this in a hurry, but I think it's right. :)
// I have a much better version of this that I'll have to find.
mat3 rot(vec3 ang){
    
    vec3 c = cos(ang), s = sin(ang);

    return mat3(c.x*c.z - s.x*s.y*s.z, -s.x*c.y, -c.x*s.z - s.x*s.y*c.z,
                c.x*s.y*s.z + s.x*c.z, c.x*c.y, c.x*s.y*c.z - s.x*s.z,
                c.y*s.z, -s.y, c.y*c.z);
    
}

 
 
void mainImage(out vec4 fragColor, in vec2 fragCoord){


    
    // Setting a maximum resolution, then upscaling. I picked up this tip when
    // looking at one of Spalmer's examples, here:
    // https://www.shadertoy.com/view/sdKXD3
    float maxRes = 540.;
    float iRes = min(iResolution.y, maxRes);
    //ivec2 iR = ivec2(fragCoord);
    //if(iR.y > 0 || iR.x>3){
    fragColor = vec4(0, 0, 0, 1);
    vec2 uv2 = abs(fragCoord - iResolution.xy*.5) - iRes/2.*vec2(iResolution.x/iResolution.y, 1.);
    if(any(greaterThan(uv2, vec2(0)))) return;  // if(uv2.x>0. || uv2.y>0.) return;
    //} 
    
    float sf = 1./iResolution.y;
        
    // Screen pixel coordinates.
    vec2 seed0 = fract(iTime/vec2(111.13, 57.61))*vec2(-.143, .457);
    vec2 uv0 = (fragCoord - iResolution.xy*.5)/iRes;
    
  
    float FOV = 1.; // FOV - Field of view.
    vec3 ro = vec3(0, .25, -2);
    // "Look At" position.
    vec3 lk = ro + vec3(0, -.01, .25);
    vec3 fwd = normalize(lk - ro);
    vec3 rgt = normalize(vec3(fwd.z, 0., -fwd.x )); 
    // "right" and "forward" are perpendicular, due to the dot product being zero. Therefore, I'm 
    // assuming no normalization is necessary? The only reason I ask is that lots of people do 
    // normalize, so perhaps I'm overlooking something?
    vec3 up = cross(fwd, rgt); 
    
    // Camera.
    mat3 mCam = mat3(rgt, up, fwd);
    mCam *= rot(vec3(0, .05, 0)); 
    mCam *= rot(vec3(0, 0, -sin(iTime/6.)*.125)); 
    
    // Accumulative color.
    vec3 aCol = vec3(0);
    
    
    for(int j = min(0, iFrame); j<sampNum; j++){
        
        // Seed value and jitter.
        seed = uv0 + seed0 + vec2(j*57, j*27)/1321.;
        vec2 jit = hash22()*2. - 1.;
        
        // Jittered UV coordinate.
        vec2 uv = uv0 - jit/iResolution.y;

        // Using the above to produce the unit ray-direction vector.
        vec3 rd = mCam*normalize(vec3(uv, 1./FOV));

        // Camera position. Initially set to the ray origin.
        vec3 cam = ro;
        // Surface postion. Also initially set to the ray origin.
        vec3 sp = ro;

        vec3 col = vec3(0);
        
        // Emissive, throughput and sample colors.
        vec3 emissive = vec3(0);
        vec3 through = vec3(1);
        vec3 sCol = vec3(0);
        
        // Fog.
        float fogD = 1e8;
       
        
        // Just four bounces. More looks better, but the extra randomess
        // requires more samples. For static scenes, that's not a problem,
        // but this is a realtime one.
        for(int i = min(0, iFrame); i<4; i++){

            
            vec3 scene = intersect(sp, rd); // Scene intersection.

            float t = scene.x; // Scene distance.
            float retVal = scene.y; // Redundant here, but used when refraction is involved.
            float id = scene.z;// Object ID.
            
            // Set the fog distance on the first pass.
            if(i==0) fogD = t;

            sp += rd*t; // Advance the ray position.

  
            if(t<1e8){

                
                vec3 sn = getNorm(sp, id); // Normal.

                vec3 oCol = vec3(0), emissive = vec3(0); // Object color, and emissivity.

                emissive = vec3(0);
                float rough = 0.;

               
                if(id<.5) { 
                   
                    // Placing an offset subdivided grid pattern on the sphere,
                    // then randomly lighting up random cells.
 
                    // Texture coordinates.
                    vec3 txP = sp - sph4.xyz;
                    // Rotation.
                    txP.xy *= rot2(-3.14159/12.);
                    txP.xz *= rot2(-iTime/4.);
                    
                    // Using spherical coordinates to put some latitudinal squares
                    // around the longitudinal direction... Not much different to the
                    // way you'd put a square grid on a plane, but with spherical
                    // coordinates.
                    
                    float aNum = 32.; // Scale.
                    
                    // Spherical longitudinal and latitudinal angles.
                    vec2 sphA = vec2(atan(txP.z, txP.x), atan(length(txP.xz), txP.y))/6.2831;
                    vec2 sphID = (floor(sphA*aNum) + .5)/aNum;
                    
                    // Offsetting alternate rows just for fun.
                    if(mod(sphID.y*aNum - .5, 2.)<.5){
                        
                        sphA.x = fract(sphA.x + .5/aNum);
                        // The above is the same as:
                        //txP.xz *= rot2(3.14159/aNum);
                        //sphA.x = atan(txP.z, txP.x)/6.2831;
                        //sphID.x = (floor(sphA.x*aNum) + .5)/aNum;
                        sphID.x = (floor(sphA.x*aNum) + .5)/aNum;
                    }
                    
                    // Original scale and latitudinal dimension.
                    float aNum0 = aNum, y0 = sphID.y;
                    
                    // Local X and Y square grid coordinates.
                    vec2 sph = mod(sphA, 1./aNum) - .5/aNum;
                  
                    // Random subdivision.
                    if(hash21(sphID + .3)<.5 && abs(y0 - .25)<4./aNum/2.){
                        aNum *= 2.;
                        sph = mod(sphA, 1./aNum) - .5/aNum;
                        sphID = (floor(sphA*aNum) + .5)/aNum;
                    } 
                    
                    
                    // Rounded square.
                    float d = sBoxS(sph, vec2(.5/aNum) - .0025, .15/aNum);
                    // Distance field isoline boundary.
                    d = smoothstep(0., sf, d);

                    
                    // Render the pattern onto the sphere.
                    oCol = mix(vec3(1), vec3(.1), d);
                    
                    // Emissivity.
                    // Using a texture to color the emissive lights.
                    vec3 tx = texture(iChannel1, sphID + iTime/128.).xyz; tx *= tx;
                    // Fade out emissivity higher up the walls.
                    float st = clamp(sp.y/1.25 - 1., 0., 1.);
                    float rnd = smoothstep(st, 1., dot(tx, vec3(.299, .587, .114)));
              
        
                    // Emissivity.
                    emissive = vec3(0);
                    // Color a limited set of bands around the equator.
                    //if(abs(b0 - .25)<6./aNum0/2.) { emissive = oCol*(rnd*.99 + .01)*2.;  }
                    if(abs(y0 - .25)<4./aNum0/2.) { emissive = oCol*tx*tx*rnd*16.;  }
                    emissive = mix(emissive, vec3(0), d);
                    emissive = mix(emissive, emissive.zyx, clamp((sp.y + .5)*3., 0., 1.));
                    
                    
                    // Roughness.
                    rough = hash21(vec2(sphID.x*aNum, sphID.y) + .23)*.5; //(clamp(.5 - d3.x/.2, 0., 1.))*
                
               }
               else {

                   
                    // Producing a wall and floor pattern, coloring it, and using
                    // parts to act as emitters.
                    
                    // Back wall or not.
                    float sgn = (abs(sn.z)>.5)? 1. : -1.;
                    
                    // UV coordinates for the walls and floors.
                    vec2 uv = sgn>.5? sp.xy : abs(sn.x)>.5? sp.yz : sp.xz;

                    // Distance field pattern:
                    // Returns the distance field and cell ID.
                    vec3 d3 = distField(uv);
                    // Distance field isoline boundary.
                    d3.x = smoothstep(0., sf, d3.x);
 
                    // Render the pattern on the walls, ceiling and floor.
                    oCol = mix(vec3(1), vec3(.1), d3.x);
                    
                    // Emissivity.
                    // Using a texture to color the emissive lights.
                    vec3 tx = texture(iChannel1, d3.yz/16. - vec2(-1, 2)*iTime/64.).xyz; tx *= tx;
                    // Fade out emissivity higher up the walls.
                    float st = clamp(d3.z/1.25 - 1., 0., 1.);
                    float rnd = smoothstep(st, 1., dot(tx, vec3(.299, .587, .114)));
                    if(sgn<.5) rnd = 0.; // No lights on the floor or ceiling.
                    //if(sn.z>.5) rnd = 0.;
                    // Pattern based emissivity -- It doesn't always have to be object based.
                    emissive = mix(oCol*tx*tx*rnd*16., vec3(0), d3.x);
                    emissive = mix(emissive, emissive.zyx, clamp(sp.y, 0., 1.));
                    
                    // Roughness.
                    rough = hash21(d3.yz + .1)*.5; //(clamp(.5 - d3.x/.2, 0., 1.))*
 
                  
                }
                
                
                // I definitely like the more natural way in which colors are applied
                // when rendering this way. We only add surface color when it's been
                // hit by a ray that has visited a light source at some point.
                sCol += emissive*through;
                // Applying this bounce's color to future bounces. For instance, if we
                // hit a pink emitter then hit another surface later, that surface will
                // incorporate a bit of pink into it.
                through *= oCol;


                vec3 ref = reflect(rd, sn); // Purely reflected vector.
                vec3 rrd = cosDir(0., sn); // Random half hemisphere vector.
                //vec3 rrd = normalize(hash23() - .5); // Less evenly distributed.


                // Mimicking surface inconsistancies with fuzzy reflections.
                // Rougher surfaces have a greater chance of randomly reflecting at any direction
                // and smoother surfaces are more likely to purely reflect.
                //float rChance = step(rough, hash21(uv + vec2(i*277, j*113) + fract(iTime*.977 + .137)));
                //rd = (mix(rrd, ref, rChance));
                //rd = normalize(mix(ref, rrd, rough));
                rd = normalize(ref + rrd*rough);
                if(dot(rd, sn)<0.) rd = -rd; // Not sure this line really matters.


                sp += sn*1e-5;
                //rd = ref; // Pure reflection override. Not as effective at all.

            } 
            
            
             if(aCol.x>1e5) break; // Attempting to reduce compile time. 
        }
        
        // Applying some fog, if necessary. You don't actually see this, but
        // I want it there for completeness.
        sCol = mix(vec3(0), sCol, 1./(1. + fogD*fogD*.02));

        
        // Accumulate the sample color.
        aCol += sCol;
        
        if(sCol.x>1e5) break; // Attempting to reduce compile time.
        
        
    }
    
    // Average color over all samples.
    aCol /= float(sampNum);
    
   
    /////
    

    
    // Mix the previous frames in with no camera reprojection.
    // It's OK, but full temporal blur will be experienced.
    vec4 preCol = texelFetch(iChannel0, ivec2(fragCoord), 0);
    float blend = (iFrame < 2) ? 1. : 1./blendNum; 
    fragColor = mix(preCol, vec4(clamp(aCol, 0., 1.), 1), blend);
    
    // No reprojection or temporal blur, for comparisson.
    //fragColor = vec4(max(aCol, 0.), 1);
    
}