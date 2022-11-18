// Created by SHAU - 2019
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

/* Animation Buffer */

//Dave Hoskins - Pylon 
//https://www.shadertoy.com/view/XltSRf
//Catmull-rom spline
vec3 spline(vec3 p0, vec3 p1, vec3 p2, vec3 p3, float t) {
    
    vec3 c2 = -0.5 * p0	+  0.5 * p2;
	vec3 c3 =        p0	+ -2.5 * p1 +  2.0 * p2 + -0.5 * p3;
    vec3 c4 = -0.5 * p0	+  1.5 * p1 + -1.5 * p2 +  0.5 * p3;
	
    return(((c4 * t + c3) * t + c2) * t + p1);
}

void positionAtTime(inout vec3 cameraPosition) {
    
    //initialise camera arrays
    //number of positions must be +3 number of seconds that loop plays
    vec3 cameraPath[22];
    cameraPath[0]  = vec3( 10.0,  0.0, 2.0);
    cameraPath[1]  = vec3( 10.0,  0.0, 20.0);
    cameraPath[2]  = vec3( 10.0,  2.0, 50.0);
    cameraPath[3]  = vec3( 8.0,   4.0, 90.0);
    cameraPath[4]  = vec3( 5.0,   5.0, 140.0);
    cameraPath[5]  = vec3( 2.0,   6.0, 200.0);
    cameraPath[6]  = vec3( 0.0,   6.0, 260.0);
    cameraPath[7]  = vec3(-2.0,   6.0, 315.0);
    
    cameraPath[8]  = vec3( -4.0,  5.0, 370.0);
    cameraPath[9]  = vec3( -6.0,  4.0, 425.0);
    cameraPath[10] = vec3( -8.0,  2.0, 480.0);
    
    cameraPath[11] = vec3( -8.0,  0.0, 535.0);
    cameraPath[12] = vec3( -8.0, -2.0, 590.0);
    cameraPath[13] = vec3( -4.0, -5.0, 645.0);
    cameraPath[14] = vec3( -2.0, -3.0, 695.0);
    cameraPath[15] = vec3(  2.0, -1.0, 745.0);
    cameraPath[16] = vec3(  6.0,  2.0, 795.0);
    cameraPath[17] = vec3(  6.0,  3.0, 845.0);
    cameraPath[18] = vec3(  6.0,  4.0, 895.0);
    cameraPath[19] = vec3(  6.0,  5.0, 935.0);
    cameraPath[20] = vec3(  6.0,  5.0, 965.0);
    cameraPath[21] = vec3(  6.0,  5.0, 995.0);

    int nt = int(T);
    float ft = fract(T);
    
    vec3 p0 = cameraPath[nt];
    vec3 p1 = cameraPath[nt + 1];
    vec3 p2 = cameraPath[nt + 2];
    vec3 p3 = cameraPath[nt + 3];
    
    cameraPosition = spline(p0, p1, p2, p3, ft);
}

void mainImage(out vec4 C, in vec2 U) {
    
    const float ballRad = 0.5;
    
    vec4 bp = vec4(0.0, 0.0, 40.0, ballRad);
    vec3 la = vec3(0.0, 0.0, 0.0),
         ro = vec3(0.0, 0.0, 0.0),
         sp = vec3(0.0, 0.0, 0.0);
    float vaa = 0.6,
          haa = -0.4,
          ta = 0.0,
          sa = T*0.4,
          spd = 50.0,
          lgt = 0.0;
    
    //camera
    positionAtTime(ro);
    
    //speed of ball and ship
    float offset = min(31.0, T*4.0);
    bp.z += T * spd;    
    la.z += offset + T * spd;
    sp.z += offset + T * spd;
    
    //arm angles
    vaa -= clamp((T-5.0) * 0.2, 0.0, 0.2) - 
           clamp((T-15.0) * 0.1, 0.0, 0.2);
    haa += clamp((T-5.0) * 0.1, 0.0, 0.3) -
           clamp((T-10.0) * 0.1, 0.0, 0.3);
    ta += clamp((T-6.0) * 0.3, 0.0, 0.6) -
          clamp((T-10.0) * 0.2, 0.0, 0.6);
    
    //electricity
    float h1 = hash12(U + 20.0) - 0.5;
    vec2 h2 = (hash22(U+111.3+T*2.9)-0.5) * 2.0;    
    vec3 bolt = vec3(h2.x, ballRad, h2.y);
    bolt.xy *= rot(T*h1*17.0);
    bolt.yz *= rot(-sa); //rotate with ship
    bolt = normalize(bolt) * ballRad;
    if (U.y==ELC1) {
       C = vec4(bolt, 1.0); 
    } else if (U.y==ELC2) {
       bolt.yz *= rot(-2.094395); 
       C = vec4(bolt, 1.0); 
    } else if (U.y==ELC3) {
       bolt.yz *= rot(-4.188790); 
       C = vec4(bolt, 1.0); 
    }
    
    //light
    lgt = step(8.0, T);
    
    if (U==LA) {
        C = vec4(la, 0.0);    
    } else if (U==CP) {
        C = vec4(ro, 0.0);    
    } else if (U==SP) {
        C = vec4(sp, 0.0);    
    } else if (U==BP) {
        C = bp;    
    } else if (U==ARM) {
        C = vec4(vaa, haa, ta, sa);
    } else if (U==LGT) {
        C = vec4(lgt, 0.0, 0.0, 0.0);
    } 
}