// Created by SHAU - 2019
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

vec3 fog(vec3 ro, vec3 rd, float maxt) {
    vec3 pc = vec3(0);
    float t = 0.0;
    for (int i=ZERO; i <64; i++) {
        vec3 p = ro + rd*t;
        float light = 1.0 - vMap(vec3(p.x, 11.0, p.z));  //inverse
        float dist = 20.0 - p.y;
        float atten = 0.06 / (1.0 + dist*dist * 0.04);
        pc += vec3(0,0.6,0) * atten * light;
        pc += n3D(p+T*-2.6)*0.002; 
        t += 0.6 + hash12(p.xz*3.0)*0.2;
        if (t>maxt) break;
    }
    return pc;
}

void mainImage(out vec4 C, in vec2 U) {
    
    vec3 pc = vec3(0),
         ro = texture(iChannel0, CP/R).xyz,
         la = texture(iChannel0, LA/R).xyz,
         bp = texture(iChannel0, BP/R).xyz,
         lgt = texture(iChannel0, LGT/R).xyz,
         rd = camera(U, R, ro, la, FL);
    
    vec4 res = renderVoxels(ro, rd, ro, bp, lgt.x, ZERO, 256);
    pc = res.xyz;
    float mint = res.w;
	    
    pc = mix(pc, vec3(0), mint/FAR);
    pc += fog(ro, rd, mint) * 0.8;
    C = vec4(pc, mint);
}