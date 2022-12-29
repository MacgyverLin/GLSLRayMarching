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
    vec3 op = p;
    vec3 n = normalize(vec3(cos(iTime), 1, sin(iTime)));
    //p += p.y;
    float m = 0.2;
    float time = 0. * iTime;
   // p *= 0.7;
    
    for (float i = 0.; i < 4.; i++) {
        time += 0.25 * p.y + -0.25 * iTime + pi/4.;
       // p = sabs(1.15 * p) - m;
        p = sabs(p) - m;
        p.xy *= Rot(time + pi/3.);
        p.zy *= Rot(time);
        m *= 0.9;
    }
    
    p.xz *= Rot(iTime*.1);
    
    //float d = sdBox(p, vec3(0.15)) - 0.0;
    float d = length(p) - 0.25;
    return 1.5 * d;
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

    vec3 ro = vec3(0, 3, -3)*.7;
    ro.yz *= Rot(-m.y*3.14+1.);
    ro.xz *= Rot(-m.x*6.2831);
    
    vec3 rd = GetRayDir(uv, ro, vec3(0,0.,0), 1.05);
    
    vec3 col = texture(iChannel0, rd).rgb;
    col = pow(col, vec3(2.2));
    
    float d = RayMarch(ro, rd, 1.); // outside of object
    
    float IOR = 1.05; // index of refraction
    
    if(d<MAX_DIST) {
        vec3 p = ro + rd * d; // 3d hit position
        vec3 n = GetNormal(p); // normal of surface... orientation
        vec3 r = reflect(rd, n);
        vec3 refOutside = texture(iChannel0, r).rgb;
        refOutside = pow(refOutside, vec3(2.2));
        vec3 rdIn = refract(rd, n, 1./IOR); // ray dir when entering
        
        vec3 pEnter = p - n*SURF_DIST*3.;
        float dIn = RayMarch(pEnter, rdIn, -1.); // inside the object
        
        vec3 pExit = pEnter + rdIn * dIn; // 3d position of exit
        vec3 nExit = -GetNormal(pExit); 
        
        vec3 reflTex = vec3(0);
        
        vec3 rdOut = vec3(0);
        
        float abb = .004;
        
        // red
        rdOut = refract(rdIn, nExit, IOR-abb);
        if(dot(rdOut, rdOut)==0.) rdOut = reflect(rdIn, nExit);
        reflTex.r = texture(iChannel0, rdOut).r;
        
        // green
        rdOut = refract(rdIn, nExit, IOR);
        if(dot(rdOut, rdOut)==0.) rdOut = reflect(rdIn, nExit);
        reflTex.g = texture(iChannel0, rdOut).g;
        
        // blue
        rdOut = refract(rdIn, nExit, IOR+abb);
        if(dot(rdOut, rdOut)==0.) rdOut = reflect(rdIn, nExit);
        reflTex.b = texture(iChannel0, rdOut).b;
        
        reflTex = pow(reflTex, vec3(2.2));
        
        float dens = 0.1 * cos(pi * dot(rd, n));
        float optDist = exp(-dIn*dens);
        optDist = pow(optDist, 3.);
        reflTex = reflTex*optDist;//*vec3(1., .05,.2);
        
        float fresnel = pow(1.+dot(rd, n), 3.);
       // col = vec3(fresnel);
        col = mix(reflTex, refOutside, fresnel);
        //col *= n*.1+.9;
        //col *= 1.5;
    }
    
    col = pow(col, vec3(.4545));	// gamma correction
    
    fragColor = vec4(col,1.0);
}