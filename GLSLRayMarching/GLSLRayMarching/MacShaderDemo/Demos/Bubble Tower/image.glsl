#define MAX_STEPS 400
#define MAX_DIST 30.
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
    float r1 = 0.75;
    float r2 = 0.45;
    float a = atan(p.x, p.z);
   // p.xz += 0.5 * cos(a + iTime);
    float d1 = length(p.xz) - r1;
  
    vec2 uv = vec2(d1, p.y);
    float av = atan(uv.x, uv.y);
    float rv = length(uv); // <----- change back to length(uv)
    //uv = vec2(2. * av, rv;
    float thing = 1.5 * av + 3.5 * p.y;
    //rv = mix(rv, log(2.8 * rv), 0.5 + 0.5 * thc(3.,iTime));
    rv = rv * (1.2 + 0.2 * cos(20. * rv));
    rv = mix(rv, uv.x, 0.5 + 0.5 * thc(3.,0.5 * iTime));
    uv = rv * vec2(cos(thing), sin(thing));
    
    uv *= Rot(a - iTime);
    uv.y = abs(uv.y) - 0.3;
    //uv.y += 0.1 * cos(a + iTime);
    //uv.y += 0.1 * cos(2. * a + iTime);
    float d2 = length(uv) - r2;
    
    return 0.3 * d2; //0.3
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

    float time = 0. * iTime;
    vec3 ro = vec3(0, 0. + time, 2.5);
    ro.yz *= Rot(-m.y*3.14+1.);
    ro.xz *= Rot(-m.x*6.2831);
    
    vec3 rd = GetRayDir(uv, ro, vec3(0,time,0), 0.8);
    
    vec3 col = texture(iChannel0, rd).rgb; //vec3(0.03);//
    
    float d = RayMarch(ro, rd, 1.); // outside of object
    
    float IOR = 1.;//mix(0., 1.5, 0.5 + 0.5 * thc(5., 0.6 * iTime)); // index of refraction
    
    if(d<MAX_DIST) {
        vec3 p = ro + rd * d; // 3d hit position
        vec3 n = GetNormal(p); // normal of surface... orientation
        vec3 r = reflect(rd, n);
             
        vec3 rdIn = refract(rd, n, 1./IOR); // ray dir when entering
        
        vec3 pEnter = p - n*SURF_DIST*30.;
        float dIn = RayMarch(pEnter, rdIn, -1.); // inside the object
        
        vec3 pExit = pEnter + rdIn * dIn; // 3d position of exit
        vec3 nExit = -GetNormal(pExit); 
        
        vec3 reflTex = vec3(0);
        
        vec3 rdOut = vec3(0);
        
        IOR = -1.; // <-- remove this to make it work like normal
        rdOut = -refract(rdIn, nExit, IOR);
       
        if(dot(rdOut, rdOut)==0.) rdOut = reflect(rdIn, nExit);
        reflTex = texture(iChannel0, rdOut).rgb;
        
        vec3 pExit2 = pExit - nExit*SURF_DIST*3.;
        float dExit = RayMarch(pExit2, rdOut, 1.);
        if (dExit < MAX_DIST) {
           vec3 pL = pExit2 + rdOut * dExit;
           vec3 nL = GetNormal(pL);
           float dif = dot(nL, normalize(vec3(1,2,3)))*.5+.5;
           //dif = 1.;//clamp(dif, 0., 1.);
           //dif = smoothstep(0., 1., dif);
           //dif = pow(4. * dif * (1.-dif), 2.);
           //col = vec3(dif);
          // float fresnel = pow(1.+dot(rdOut, nL), 3.);
           //col *= clamp(fresnel, 0., 1.);
           //col *= (0.5 + 0.5 * nL);
           vec3 e = vec3(0.9);
           col = pal(0.08 * dif + 0.5 + 0.15 * pL.y + 0.1 * nL.y, e, e, e, 0.7 * vec3(0.,0.33,0.66));
         
           //col *= 1. + 0.5 * thc(4., 12. * length(p) - iTime);
           col = mix(col, texture(iChannel0, rdOut).rgb, 0.28);
        }

        float fresnel = pow(1.+dot(rd, n), 2.);
        col = mix(col, vec3(fresnel),clamp( 1.5-length(p),0.,1.));
        fresnel = pow(fresnel, 3.);
        vec3 refOutside = texture(iChannel0, r).rgb;
        col = mix(col, 0.45/refOutside, fresnel);
       
        

    }
    //col *= 2.;
    col = pow(col, vec3(.4545));	// gamma correction
    
    fragColor = vec4(col,1.0);
}