#define MAX_STEPS 400
#define MAX_DIST 10.
#define SURF_DIST .001

#define sabs(x) sqrt(x*x+1e-2)
#define pi 3.14159

mat2 Rot(float a) {
    float s=sin(a), c=cos(a);
    return mat2(c, -s, s, c);
}

float sdBox(vec3 p, vec3 s) {
    p = abs(p)-s;
	return length(max(p, 0.))+min(max(p.x, max(p.y, p.z)), 0.);
}


float GetDist(vec3 p) {
    //p.x += cos(2. * p.y + iTime);
   // p.xz *= Rot(2. * p.y + iTime);
   
    float l = 0.5 + 0.5 * thc(4., iTime);
    float d = sdBox(p, vec3(0.3)) - 0.3;
    d = abs(d) - 0.2;
    //float d = abs(length(p) - 0.8) - 0.3;
    return 0.4* d; // lower than I'd like it to be
}

float RayMarch(vec3 ro, vec3 rd, float side) {
	float dO=0.;
    
    for(int i=0; i<MAX_STEPS; i++) {
    	vec3 p = ro + rd*dO;
        float dS = GetDist(p)*side;
        dO += dS;
        if(dO>MAX_DIST || abs(dS)<SURF_DIST) break;
    }
    
    return dO;
}

vec3 GetNormal(vec3 p) {
	float d = GetDist(p);
    vec2 e = vec2(.001, 0);
    
    vec3 n = d - vec3(
        GetDist(p-e.xyy),
        GetDist(p-e.yxy),
        GetDist(p-e.yyx));
    
    return normalize(n);
}

vec3 GetRayDir(vec2 uv, vec3 p, vec3 l, float z) {
    vec3 f = normalize(l-p),
        r = normalize(cross(vec3(0,1,0), f)),
        u = cross(f,r),
        c = f*z,
        i = c + uv.x*r + uv.y*u,
        d = normalize(i);
    return d;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = (fragCoord-.5*iResolution.xy)/iResolution.y;
	vec2 m = iMouse.xy/iResolution.xy;

    float time = 0.2 * length(uv) + 0.65 * iTime;
    float sc = 3.2;
    vec3 ro = 3. * vec3(thc(sc, time), 
                        thc(sc, 2. * pi / 3. + time),
                        thc(sc, 4. * pi / 3. + time));

    vec3 rd = GetRayDir(uv, ro, vec3(0,0.,0), 2.);
    
    vec3 col = vec3(0.);//texture(iChannel0, rd).rgb;
    
    float d = RayMarch(ro, rd, 1.); // outside of object
    
    float IOR = 2.4;//mix(0., 1.5, 0.5 + 0.5 * thc(5., 0.6 * iTime)); // index of refraction
    
    if(d<MAX_DIST) {
        vec3 p = ro + rd * d; // 3d hit position
        vec3 n = GetNormal(p); // normal of surface... orientation
        vec3 r = reflect(rd, n);
             
        vec3 rdIn = refract(rd, n, 1./IOR); // ray dir when entering
        
        vec3 pEnter = p - n*SURF_DIST*3000.;
        float dIn = RayMarch(pEnter, rdIn, -1.); // inside the object
        
        vec3 pExit = pEnter + rdIn * dIn; // 3d position of exit
        vec3 nExit = -GetNormal(pExit); 
        
        vec3 rdOut = refract(rdIn, nExit, IOR);
       
        if(dot(rdOut, rdOut)==0.) rdOut = reflect(-n, nExit);
        //rdOut = reflect(rdIn, nExit);

        vec3 pExit2 = pExit - nExit*SURF_DIST*3.;
        float dExit = RayMarch(pExit2, rdOut, 1.);
        if (dExit < MAX_DIST)
            col = vec3(0.5 + 0.5 * rdOut);
        
        float fresnel = pow(1.+dot(rd, n), 4.);
        col += 0.3 * fresnel;
        vec3 refOutside = texture(iChannel0, r).rgb;
        col = mix(col, refOutside, fresnel);
    }
    
    col = pow(col, vec3(.4545));	// gamma correction
    
    fragColor = vec4(col,1.0);
}