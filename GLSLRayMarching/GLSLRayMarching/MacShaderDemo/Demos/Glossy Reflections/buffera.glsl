/*

    Glossy Reflections
    ------------------
    
    I do a bit of path tracing in the background, but noticed that I haven't
    put a 3D one up on Shadertoy yet, so I dug up a very old example and 
    prettied it up a bit, just to get one on the board, as they say. I'll put
    up some more interesting examples in due course.
    
    People say realtime path tracing is here... I'm not entirely convinced, 
    but I've seen some mind blowing examples out there. Either way, it's
    definitely possible to trace out some inexpensive rudimentary geometry 
    and produce a simple but nicely lit scene. 
    
    This particular scene comprises one sphere, four walls and some pattern 
    generated emitters. With the spare cycles, I've attempted to produce some 
    glossy reflections. Due to the limited number of samples, the results 
    aren't perfect by any stretch, but I can remember being utterly amazed by 
    a realtime raytraced Phong-lit white sphere on a brown background running 
    at under 10 FPS back in the 90s, so it's an improvement. :) 
    

*/


// Sample number and blend number: The trick is to find a balance between the
// two, or use a faster computer. :)

// Number of samples: My computer can handle more. If yours is struggling, you 
// can lower this. Naturally, sample number is proportional to noise quality.
#define sampNum 32

// The blended samples per frame: Higher numbers give the impression of more
// samples, which boosts quality. However, there's a price to pay, and that's 
// ghosting effects. Any more than 2 or 3 will result in noticeable ghosting.
#define blendNum 2.



// Standard 2D rotation formula.
mat2 rot2(in float a){ float c = cos(a), s = sin(a); return mat2(c, -s, s, c); }


// IQ's vec2 to float hash.
float hash21(vec2 p){  return fract(sin(dot(p, vec2(27.619, 57.583)))*43758.5453); }

float hash31(in vec3 p){
    return fract(sin(dot(p, vec3(91.537, 151.761, 72.453)))*435758.5453);
}


// Commutative smooth maximum function. Provided by Tomkh, and taken 
// from Alex Evans's (aka Statix) talk: 
// http://media.lolrus.mediamolecule.com/AlexEvans_SIGGRAPH-2015.pdf
// Credited to Dave Smith @media molecule.
float smax(float a, float b, float k){
    
   float f = max(0., 1. - abs(b - a)/k);
   return max(a, b) + k*.25*f*f;
}


/*
// Tone mapping: There are so many to choose from, and which one you use depends on
// what you're after, but I prefer the Uncharted 2 tone map since it works as advertised,
// which is tone down values in the high dynamic range and leave the others alone.
float A = .22, B = .3, C = .1, D = .2, E = .01, F = .22;//.3;
//float W = 11.2;

vec3 Un2Tone(vec3 x){

   return ((x*(A*x + C*B) + D*E)/(x*(A*x + B) + D*F))-E/F;
}
vec4 Uncharted2Tonemap(vec4 col){

   float ExposureBias = 1.;
   col.xyz = Un2Tone(ExposureBias*col.xyz);

   col.w = 2.2;//1./dot(col, vec4(.299, .587, .114, 0));
   vec3 whiteScale = 1./Un2Tone(vec3(col.w));//col.www
   
   return vec4(col.xyz*whiteScale, col.w); 
}
*/

/////
vec2 seed = vec2(.13, .27);

vec2 hash22() {
    
    seed += fract(seed + vec2(.7123, .6247));
     
    return fract(sin(vec2(dot(seed.xy, vec2(12.989, 78.233)), dot(seed.xy, vec2(41.898, 57.263))))
                      *vec2(43758.5453, 23421.6361));
}


// IQ's box routine.
float sBox(in vec2 p, in vec2 b, float r){

  vec2 d = abs(p) - b + r;
  return min(max(d.x, d.y), 0.) + length(max(d, 0.)) - r;
}


/////////
// A concatinated spherical coordinate to world coordinate conversion.
vec3 sphericalToWorld(vec3 sphCoord){
   
    vec4 cs = vec4(cos(sphCoord.xy), sin(sphCoord.xy));
    return vec3(cs.w*cs.x, cs.y, cs.w*cs.z)*sphCoord.z;
}
  

// Useful polyhedron constants. 
#define PI 3.14159265359
#define TAU 6.2831853
#define PHI 1.618033988749895 

//
// Since all triangles are the same size, etc, any triangles on
// a known icosahedron will do. The angles we need to determine are
// the angle from the top point to one of the ones below, the top
// point to the mid point below, and the angle from the top point
// to the center (centroid) of the triangle.
const vec3 triV0 = normalize(vec3(-1, PHI,  0));
const vec3 triV1 = normalize(vec3(-PHI, 0,  1));//0,  1,  PHI
const vec3 triV2 = normalize(vec3(0,  1,  PHI));//0,  1,  PHI
const vec3 mid = normalize(mix(triV1, triV2, .5));
const vec3 cntr = normalize(triV0 + triV1 + triV2);

// Angle between vectors: cos(a) = u.v/|u||v|. 
// U and V are normalized. Therefore, a = acos(u.v).
const float ang = acos(dot(triV0, triV1)); // Side length angle.
const float mAng = acos(dot(triV0, mid)); // Height angle.
const float cAng = acos(dot(triV0, cntr)); // Centroid angle.

// The latitude (in radians) of each of the top and bottom blocks is
// the angle between the top point (north pole) and one of the points below, 
// or the bottom point (south pole) and one of the ones above.
const float latBlock = ang;
const vec2 lat = vec2(cAng, mAng*2. - cAng);

//

// Returns the local world coordinates to the nearest triangle and the three
// triangle vertices in spherical coordinates.
vec3 getIcosTri(inout vec3 p, inout vec3[3] gVertID, const float rad){
       
 
    // Longitudinal scale.
    const float scX = 5.;


    // The sphere is broken up into two sections. The top section 
    // consists of the top row, and half the triangle in the middle
    // row that sit directly below. The bottom section is the same,
    // but on the bottome and rotated at PI/5 relative to the top. 
    // The half triangle rows perfectly mesh together to form the 
    // middle row or section.

    // Top and bottom section coordinate systems.The bottom section is 
    // rotated by PI/5 about the equator.
    vec3 q = p; // Top section coordinates.
    //vec3 q2 = vec3(rot2(-PI/scX)*p.xz, p.y).xzy; // Bottom section coordinates.

    // Converting to spherical coordinates.
    // X: Longitudinal angle -- around XZ, in this case.
    // Y: Latitudinal angle -- rotating around XY.
    // Z: The radius, if you need it.

    // Longitudinal angle for the top and bottom sections.
    ////vec4 sph = mod(a + vec4(0, 0, PI/5., PI/5.), TAU);
    vec4 sph = mod(atan(q.z, q.x) + vec4(0, 0, PI/5., PI/5.), TAU);
    sph = mod((floor(sph*scX/TAU) + vec4(.5, .5, 0, 0))/scX*TAU, TAU);


    float dist = 1e5;


    // Top and bottom block latitudes for each of the four groups of triangle to test.
    vec4 ayT4 = vec4(0, PI - latBlock, PI, latBlock);
    vec4 ayB4 = vec4(latBlock, latBlock, PI - latBlock, PI - latBlock);
    float ayT, ayB;

    int id;

    // Iterating through the four triangle group strips and determining the 
    // closest one via the closest central triangle point.
    for(int i = 0; i<4; i++){


        // Central vertex postion for this triangle.        
        int j = i/2;
        // The spherical coordinates of the central vertex point for this 
        // triangle. The middle mess is the lattitudes for each strip. In order,
        // they are: lat[0], lat[1], PI - lat[0], PI - lat[1]. The longitudinal
        // are just the polar coordinates. The bottom differ by PI/5. The final
        // spherical coordinate ranges from the sphere core to the surface.
        // On the surface, all distances are set to the radius.                
        vec3 sc = vec3(sph[i], float(j)*PI - float(j*2 - 1)*lat[i%2], rad);
 
        // Spherical to world, or cartesian, coordinates.
        vec3 wc = sphericalToWorld(sc);


        float vDist = length(q - wc);
        if(vDist<dist){
           dist = vDist;
           ayT = ayT4[i]; // Top triangle vertex latitude.
           ayB = ayB4[i]; // Bottom triangle vertex latitude.
           id = i;
        }


    }


    float ax = sph[id];
    // Flip base vertex postions on two blocks for clockwise order.
    float baseFlip = (id==0 || id==3)? 1. : - 1.;

    // The three vertices in spherical coordinates. I can't remember why
    // I didn't convert these to world coordinates prior to returning, but
    // I think it had to do with obtaining accurate IDs... or something. :)
    gVertID[0] = vec3(ax, ayT, rad);
    gVertID[1] = vec3(mod(ax - PI/5.*baseFlip, TAU), ayB, rad);
    gVertID[2] = vec3(mod(ax + PI/5.*baseFlip, TAU), ayB, rad);

    // Top and bottom poles have a longitudinal coordinate of zero.
    if (id%2==0) gVertID[0].x = 0.;


    return q;
}


/////////

 
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
/////

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
    vec4 res;

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
        if (max(pd.x, pd.y) < 0.) res = vec4(minD.y, 0, -sign(rd.y), 0.);
    }
    
    // Front and back walls.
    if (minD.z<maxT){
        vec2 pd = abs(ro.xy + rd.xy*minD.z) - dim.xy;
        if (max(pd.x, pd.y) < 0.) res = vec4(minD.z, 0, 0, -sign(rd.z));
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
const vec4 sph4 = vec4(0, -.5, 1., .5);

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
    q[0] = sphereIntersect(ro, rd, sph4);
 
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
// Since it's a path traced example, I went with a cliche rounded
// quarter circle arrangement.
vec3 distField(vec2 p){
    
    // Scale.
    const float sc = 1.5;
    
    // Edge width.
    const float ew = .05;
    
    // Partitioning into cells and providing the local cell ID
    // and local coordinates.
    p *= sc;
    p += .5;
    vec2 ip = floor(p);
    p -= ip + .5;
    
    
    // Rounded square.
    float sq = sBox(p, vec2((1. - ew)/2.), .125);
    
    // Randomly rotate each cell.
    p = rot2(floor(hash21(ip)*8.)*6.2831/4.)*p;
       
    // A circle, offset to one of the corners.    
    float cir = length(p - .5 + ew*.7) - (1. - ew);
 
    // Producing a rounded circle.
    float d = max(cir, sq);
    
    // Putting a hole in it just to break things up.
    d = max(d, -(length(p - .07) - .1));
    
    //d = abs(d + .1) - .1;
    
    // Returning the distance and local cell ID. Note that the 
    // distance has been rescaled by the scaling factor.
    return vec3(d/sc, ip);
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
    // looking at one of spalmer's examples, here:
    // https://www.shadertoy.com/view/sdKXD3
    float maxRes = 540.;
    float iRes = min(iResolution.y, maxRes);
    //ivec2 iR = ivec2(fragCoord);
    //if(iR.y > 0 || iR.x>3){
    fragColor = vec4(0, 0, 0, 1);
    vec2 uv2 = abs(fragCoord - iResolution.xy*.5) - iRes/2.*vec2(iResolution.x/iResolution.y, 1.);
    if(any(greaterThan(uv2, vec2(0)))) return;  // if(uv2.x>0. || uv2.y>0.) return;
    //} 
        
    // Screen pixel coordinates.
    vec2 seed0 = fract(iTime/vec2(111.13, 57.61))*vec2(-.143, .457);
    vec2 uv0 = (fragCoord - iResolution.xy*.5)/iRes;
    
  
    float FOV = 1.; // FOV - Field of view.
    vec3 ro = vec3(0, 0, -2);
    // "Look At" position.
    vec3 lk = ro + vec3(0, 0, .25);
    vec3 fwd = normalize(lk - ro);
    vec3 rgt = normalize(vec3(fwd.z, 0., -fwd.x )); 
    // "right" and "forward" are perpendicular, due to the dot product being zero. Therefore, I'm 
    // assuming no normalization is necessary? The only reason I ask is that lots of people do 
    // normalize, so perhaps I'm overlooking something?
    vec3 up = cross(fwd, rgt); 
    
    // Camera.
    mat3 mCam = mat3(rgt, up, fwd);
    mCam *= rot(vec3(0, .05, 0)); 
    mCam *= rot(vec3(0, 0, -sin(iTime/4.)*.25)); 
    
    
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
       
        
        // Just three bounces. More looks better, but the extra randomess
        // requires more samples. For static scenes, that's not a problem,
        // but this is a realtime one.
        for(int i = min(0, iFrame); i<3; i++){

            
            vec3 scene = intersect(sp, rd); // Scene intersection.

            float t = scene.x; // Scene distance.
            float retVal = scene.y; // Redundant here, but used when refraction is involved.
            float id = scene.z;// Object ID.
            
            // Set the fog distance on the first pass.
            if(i==0) fogD = t;

            sp += rd*t; // Advance the ray position.

  
            if(t<1e8){

                
                vec3 sn = getNorm(sp, id); // Normal.

                vec3 oCol = vec3(0); // Object color.

                emissive = vec3(0);
                float rough = .9;

               
                if(id<.5) { 
                   
                    // The sphere.
                    oCol = vec3(1); 
                    
                    // Texture position. Rotating the texture instead of the sphere
                    // is cheating, but we can get away with it here.
                    vec3 tSp = sp - sph4.xyz;
                    tSp.xz *= rot2(-iTime/2.);
                    tSp.xy *= rot2(-3.14159/6.);

                    // Texturing the sphere with an icosahedral mapping.
                    //
                    // Obtaining the local cell coordinates and spherical coordinates
                    // for the icosahedron cell.
                    vec3[3] gV, gVID;

                    const float rad = .5;
                    vec3 lq = getIcosTri(tSp, gVID, rad);

                    gV[0] = sphericalToWorld(gVID[0]); 
                    gV[1] = sphericalToWorld(gVID[1]);
                    gV[2] = sphericalToWorld(gVID[2]); 
                    
                    // The cell center, which doubles as a cell ID,
                    // due to its uniqueness.
                    vec3 ctr = normalize((gV[0] + gV[1] + gV[2]))*rad;
 
                    // Sphere triangles. 
                    mat3 edge = mat3(cross(gV[0], gV[1]), cross(gV[1], gV[2]), cross(gV[2], gV[0]));
                    vec3 ep = (normalize(lq)*edge)/length(gV[0] - gV[1]);  
                    float tri = smax(smax(ep.x, ep.y, .07), ep.z, .07) + .025;
                    tri = max(tri, -(length(lq - ctr) - .05));
                    //tri = abs(tri + .01) - .02;
 
                    // Object color, random for each triangle.
                    vec3 dCol = mix(vec3(1, .4, .2), vec3(1), hash31(ctr + .02));
 
                    // Random blinking.
                    float rndV = hash31(ctr + .08);
                    rndV = sin(rndV*6.2831 + iTime)*.5 + .5;
                    rndV = smoothstep(.25, .75, sin(rndV*6.2831 + iTime)*.5 + .5);
                    //
                    dCol = mix(dCol/16., dCol*4., rndV);

                    // Emissivity.
                    emissive = mix(emissive, dCol, 1. - smoothstep(0., .005, tri));
                    
                    // Roughness.
                    //rough = .1;
                    rough = mix(.1, .9, 1. - smoothstep(0., .005, tri));
               
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
 
                    // Random color.
                    vec3 dCol = mix(vec3(1, .4, .2), vec3(1), hash21(d3.yz));

                    // Render the pattern on the walls, or the reverse on the floor and ceiling.
                    oCol = mix(vec3(.25), vec3(.5), 1. - smoothstep(0., .005, sgn*(d3.x + .02)));
                    //sgn*(abs((d3.x + .02+.02)) - .035)
                    

                    // Pattern based emissivity -- It doesn't always have to be object based.
                    emissive = mix(emissive, dCol*2., 1. - smoothstep(0., .01, d3.x + .02));
                    
                    // Random blinking.
                    float rnd = hash21(d3.yz + .43);
                    rnd = smoothstep(.9, .97, sin(rnd*6.2831 + iTime)*.5 + .5);
                    
                    // Ramping up the emissivity in tune with the blinking lights.
                    if(sgn>.5) emissive = mix(emissive/128., emissive, rnd);
                    else emissive = emissive/128.;

                    // Turn off the wall lights.
                    //emissive *= 0.;
                  
                }
               
                
                // Tweaking the color and emissive color values a bit.
                oCol = mix(oCol, oCol.xzy, clamp(sp.y - 1., 0., 1.));  
                emissive = mix(emissive, emissive.xzy, clamp(sp.y - 1., 0., 1.)); 
                emissive = clamp(emissive*vec3(1, .7, .6), 0., 20.);

                //emissive = emissive.zyx; 
                // Applying some fog, if necessary. You don't actually see this, but
                // I want it there for completeness.
                emissive = mix(vec3(0), emissive, 1./(1. + fogD*fogD*.02));




                
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

                // Mimicking surface inconsistancies with fuzzy reflections.
                // Rougher surfaces have a greater chance of randomly reflecting at any direction
                // and smoother surfaces are more likely to purely reflect.
                float rChance = step(rough, hash21(uv + vec2(i*277, j*113) + fract(iTime*.977 + .137)));
                rd = (mix(rrd, ref, rChance));


                sp += sn*1e-6;
                //rd = ref; // Pure reflection override. Not as effective at all.

            } 
            
            
             if(aCol.x>1e5) break; // Attempting to reduce compile time. 
        }
        

        // Tone mapping can be helpful in bringing the extremely high values
        // down to an acceptable range, but I didn't find it necessary here.
        //sCol = Uncharted2Tonemap(vec4(sCol, 1)).xyz; 
        
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