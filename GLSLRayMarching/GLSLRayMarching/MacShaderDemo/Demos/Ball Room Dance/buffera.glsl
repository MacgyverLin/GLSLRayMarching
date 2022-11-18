// Created by SHAU - 2019
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

#define R iResolution.xy
#define T mod(iTime, DURATION)

//Physics from dr2 & iapafoto 
//https://www.shadertoy.com/view/Xsy3WR
void animate(int idx, //current ball index  
             inout vec4 bp,  //current ball position
             inout vec4 bv) { //current ball velocity

    vec3 rn = vec3(0),
         dr = vec3(0), 
         f = vec3(0);
    
    float fOvlap = 1000.,
          fDamp = 3.0, //reduced damping from 7 as per iapafotos suggestion :)
          grav = 70.,
          rSep = 0.0,
          rr = 0.;
    
    //test ball to ball collisions
    for (int i=7; i<NBALLS; i++) {
        vec4 ball = load(iChannel0, R, i, POS);
        dr = bp.xyz - ball.xyz;
        rSep = length(dr);
        rr = bp.w + ball.w;
        if (i != idx && rSep < rr) {
            f += fOvlap * (rr / rSep - 1.) * dr;
        }
    }

    //gravity direction animation
    vec3 bd = normalize(-bp.xyz) * (step(T, 11.) + step(48., T));
    if (T<10. || T>48.) bd = -bd;    
    vec3 dg = vec3(0.0, 1.0, 0.0) * step(13.,T) * step(T, 48.);
    dg.xy *= rot(max(0.0, T-13.)*0.2);
    dg += bd;
    
    //walls
    dr = vec3(8.6, 4.8, 3.0) - abs(bp.xyz) + bp.w;
    
    //update forces
    f -= step(dr, vec3(1.)) * fOvlap*sign(bp.xyz) * (1./ abs(dr) - 1.) * dr +
                        grav*dg + fDamp*bv.xyz;
    
    //update velocity and position
    float dt = 0.01;
    bv.xyz += dt * f;
    bp.xyz += dt * bv.xyz;
}


void mainImage(out vec4 C, vec2 U) {
    
    vec3 hash = (hash33(vec3(U,float(iFrame)))-.5)*2.; //hash -1 to 1
    int idx = int(U.x-.5); //ball index
    float fidx = float(idx), //float version of ball index
          type = U.y; //data type
    
    vec4 bp = load(iChannel0, R, idx, POS);
    vec4 bv = load(iChannel0, R, idx, VEL);
    
    if (iFrame < 2) {

        //fixed balls
        if (idx==0) {
            //right wall
            bp = vec4(40.0, 0.0, 0.0, 30.0);
        } else if (idx==1) {
            //left wall
            bp = vec4(-40.0, 0.0, 0.0, 30.0);
        } else if (idx==2) {
            //back wall
            bp = vec4(0.0, 0.0, 40.0, 30.0);
        } else if (idx==3) {
            //floor
            bp = vec4(0.0, 60.0, 0.0, 54.0);
        } else if (idx==4) {
            //ceiling
            bp = vec4(0.0, -60.0, 0.0, 54.0);
        } else if (idx==5) {
            //right fill
            bp = vec4(50.0, 0.0, 50.0, 56.0);
        } else if (idx==6) {
            //left fill
            bp = vec4(-50.0, 0.0, 50.0, 56.0);
        } else if (idx>6) {
            vec3 bc = vec3(4.6, 0.0, 0.0);
            bc.xy *= rot(float(idx-6) * 0.483);
            bp = vec4(bc, 1.0);
        }
        
        bv = vec4(hash.xy, hash.z*0.4, 1.0) * 2.0;
        
    } else {        
        if (idx>6) {
            animate(idx, bp, bv);   
        }
    }
    
    //save
    if (type==POS) {
        C = bp; //ball position    
    } else if (type==VEL) {
        C = bv; //ball velocity
    }
}
