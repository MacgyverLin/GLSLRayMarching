// afl_ext 2017 
// This shader is 100% public domain (uses glsl-atmosphere, which is also public domain)
 
#define time iTime
#define mouse (iMouse.xy / iResolution.xy)
#define resolution iResolution.xy


#define time iTime
#define mouse (iMouse.xy / iResolution.xy)
#define resolution iResolution.xy

// lower this if your GPU cries for mercy (set to 0 to remove clouds!)
#define CLOUDS_STEPS 47
#define ENABLE_SSS 1



#define DRAG_MULT 0.048
#define ITERATIONS_RAYMARCH 13
#define ITERATIONS_NORMAL 48
#define WATER_DEPTH 2.1

// returns vec2 with wave height in X and its derivative in Y
vec2 wavedx(vec2 position, vec2 direction, float speed, float frequency, float timeshift) {
    float x = dot(direction, position) * frequency + timeshift * speed;
    float wave = exp(sin(x) - 1.0);
    float dx = wave * cos(x);
    return vec2(wave, -dx);
}

float supernoise3dX(vec3 p);

float getwaves(vec2 position, int iterations){
    position *= 0.1;
	position += time * 0.1;
	float iter = 0.0;
    float phase = 6.0;
    float speed = 2.0;
    float weight = 1.0;
    float w = 0.0;
    float ws = 0.0;
    for(int i=0;i<iterations;i++){
        vec2 p = vec2(sin(iter), cos(iter));
        vec2 res = wavedx(position, p, speed, phase, iTime);
        position += p * res.y * weight * DRAG_MULT;
        w += res.x * weight;
        iter += 12.0;
        ws += weight;
        weight = mix(weight, 0.0, 0.2);
        phase *= 1.18;
        speed *= 1.07;
    }
    return (w / ws);// * supernoise3dX(0.3 *vec3(position.x, position.y, 0.0) + iTime * 0.1);
}

float raymarchwater(vec3 camera, vec3 start, vec3 end, float depth){
    vec3 pos = start;
    float h = 0.0;
    float hupper = depth;
    float hlower = 0.0;
    vec2 zer = vec2(0.0);
    vec3 dir = normalize(end - start);
    for(int i=0;i<318;i++){
        h = getwaves(pos.xz, ITERATIONS_RAYMARCH) * depth - depth;
        if(h + 0.01 > pos.y) {
            return distance(pos, camera);
        }
        pos += dir * (pos.y - h);
    }
    return -1.0;
}

float H = 0.0;
vec3 normal(vec2 pos, float e, float depth){
    vec2 ex = vec2(e, 0);
    H = getwaves(pos.xy, ITERATIONS_NORMAL) * depth;
    vec3 a = vec3(pos.x, H, pos.y);
    return normalize(cross((a-vec3(pos.x - e, getwaves(pos.xy - ex.xy, ITERATIONS_NORMAL) * depth, pos.y)), 
                           (a-vec3(pos.x, getwaves(pos.xy + ex.yx, ITERATIONS_NORMAL) * depth, pos.y + e))));
}
mat3 rotmat(vec3 axis, float angle)
{
	axis = normalize(axis);
	float s = sin(angle);
	float c = cos(angle);
	float oc = 1.0 - c;
	
	return mat3(oc * axis.x * axis.x + c,           oc * axis.x * axis.y - axis.z * s,  oc * axis.z * axis.x + axis.y * s, 
	oc * axis.x * axis.y + axis.z * s,  oc * axis.y * axis.y + c,           oc * axis.y * axis.z - axis.x * s, 
	oc * axis.z * axis.x - axis.y * s,  oc * axis.y * axis.z + axis.x * s,  oc * axis.z * axis.z + c);
}
vec3 getRay(vec2 uv){
   uv = (uv * 2.0 - 1.0)* vec2(resolution.x / resolution.y, 1.0);
	vec3 proj = normalize(vec3(uv.x, uv.y, 1.5));	
    if(resolution.y < 400.0) return proj;
	vec3 ray = rotmat(vec3(0.0, -1.0, 0.0), 3.0 * (mouse.x * 2.0 - 1.0)) * rotmat(vec3(1.0, 0.0, 0.0), 1.5 * (mouse.y * 2.0 - 1.0)) * proj;
    return ray;
}

float rand2sTime(vec2 co){
    co *= time;
    return fract(sin(dot(co.xy,vec2(12.9898,78.233))) * 43758.5453);
}

float intersectPlane(vec3 origin, vec3 direction, vec3 point, vec3 normal)
{ 
    return clamp(dot(point - origin, normal) / dot(direction, normal), -1.0, 9991999.0); 
}
#define PI 3.141592
#define iSteps 16
#define jSteps 8

vec2 rsi(vec3 r0, vec3 rd, float sr) {
    // ray-sphere intersection that assumes
    // the sphere is centered at the origin.
    // No intersection when result.x > result.y
    float a = dot(rd, rd);
    float b = 2.0 * dot(rd, r0);
    float c = dot(r0, r0) - (sr * sr);
    float d = (b*b) - 4.0*a*c;
    if (d < 0.0) return vec2(1e5,-1e5);
    return vec2(
        (-b - sqrt(d))/(2.0*a),
        (-b + sqrt(d))/(2.0*a)
    );
}

float oct(float p){
    return fract(4768.1232345456 * sin(p));
}
float oct(vec2 p){
    return fract(4768.1232345456 * sin((p.x+p.y*43.0)));
}
float oct(vec3 p){
    return fract(4768.1232345456 * sin((p.x+p.y*43.0+p.z*137.0)));
}
float oct(vec4 p){
    return fract(4768.1232345456 * sin((p.x+p.y*43.0+p.z*137.0+p.w*2666.0)));
}

float achnoise(float x){
    float p = floor(x);
    float fr = fract(x);
    float L = p;
    float R = p + 1.0;

    float Lo = oct(L);
    float Ro = oct(R);

    return mix(Lo, Ro, fr);
}

float achnoise(vec2 x){
    vec2 p = floor(x);
    vec2 fr = fract(x);
    vec2 LB = p;
    vec2 LT = p + vec2(0.0, 1.0);
    vec2 RB = p + vec2(1.0, 0.0);
    vec2 RT = p + vec2(1.0, 1.0);

    float LBo = oct(LB);
    float RBo = oct(RB);
    float LTo = oct(LT);
    float RTo = oct(RT);

    float noise1d1 = mix(LBo, RBo, fr.x);
    float noise1d2 = mix(LTo, RTo, fr.x);

    float noise2d = mix(noise1d1, noise1d2, fr.y);

    return noise2d;
}
float achnoise(vec3 x){
    vec3 p = floor(x);
    vec3 fr = fract(x);
    vec3 LBZ = p + vec3(0.0, 0.0, 0.0);
    vec3 LTZ = p + vec3(0.0, 1.0, 0.0);
    vec3 RBZ = p + vec3(1.0, 0.0, 0.0);
    vec3 RTZ = p + vec3(1.0, 1.0, 0.0);

    vec3 LBF = p + vec3(0.0, 0.0, 1.0);
    vec3 LTF = p + vec3(0.0, 1.0, 1.0);
    vec3 RBF = p + vec3(1.0, 0.0, 1.0);
    vec3 RTF = p + vec3(1.0, 1.0, 1.0);

    float l0candidate1 = oct(LBZ);
    float l0candidate2 = oct(RBZ);
    float l0candidate3 = oct(LTZ);
    float l0candidate4 = oct(RTZ);

    float l0candidate5 = oct(LBF);
    float l0candidate6 = oct(RBF);
    float l0candidate7 = oct(LTF);
    float l0candidate8 = oct(RTF);

    float l1candidate1 = mix(l0candidate1, l0candidate2, fr[0]);
    float l1candidate2 = mix(l0candidate3, l0candidate4, fr[0]);
    float l1candidate3 = mix(l0candidate5, l0candidate6, fr[0]);
    float l1candidate4 = mix(l0candidate7, l0candidate8, fr[0]);


    float l2candidate1 = mix(l1candidate1, l1candidate2, fr[1]);
    float l2candidate2 = mix(l1candidate3, l1candidate4, fr[1]);


    float l3candidate1 = mix(l2candidate1, l2candidate2, fr[2]);

    return l3candidate1;
}


float achnoise(vec4 x){
    vec4 p = floor(x);
    vec4 fr = fract(x);
    vec4 LBZU = p + vec4(0.0, 0.0, 0.0, 0.0);
    vec4 LTZU = p + vec4(0.0, 1.0, 0.0, 0.0);
    vec4 RBZU = p + vec4(1.0, 0.0, 0.0, 0.0);
    vec4 RTZU = p + vec4(1.0, 1.0, 0.0, 0.0);

    vec4 LBFU = p + vec4(0.0, 0.0, 1.0, 0.0);
    vec4 LTFU = p + vec4(0.0, 1.0, 1.0, 0.0);
    vec4 RBFU = p + vec4(1.0, 0.0, 1.0, 0.0);
    vec4 RTFU = p + vec4(1.0, 1.0, 1.0, 0.0);

    vec4 LBZD = p + vec4(0.0, 0.0, 0.0, 1.0);
    vec4 LTZD = p + vec4(0.0, 1.0, 0.0, 1.0);
    vec4 RBZD = p + vec4(1.0, 0.0, 0.0, 1.0);
    vec4 RTZD = p + vec4(1.0, 1.0, 0.0, 1.0);

    vec4 LBFD = p + vec4(0.0, 0.0, 1.0, 1.0);
    vec4 LTFD = p + vec4(0.0, 1.0, 1.0, 1.0);
    vec4 RBFD = p + vec4(1.0, 0.0, 1.0, 1.0);
    vec4 RTFD = p + vec4(1.0, 1.0, 1.0, 1.0);

    float l0candidate1  = oct(LBZU);
    float l0candidate2  = oct(RBZU);
    float l0candidate3  = oct(LTZU);
    float l0candidate4  = oct(RTZU);

    float l0candidate5  = oct(LBFU);
    float l0candidate6  = oct(RBFU);
    float l0candidate7  = oct(LTFU);
    float l0candidate8  = oct(RTFU);

    float l0candidate9  = oct(LBZD);
    float l0candidate10 = oct(RBZD);
    float l0candidate11 = oct(LTZD);
    float l0candidate12 = oct(RTZD);

    float l0candidate13 = oct(LBFD);
    float l0candidate14 = oct(RBFD);
    float l0candidate15 = oct(LTFD);
    float l0candidate16 = oct(RTFD);

    float l1candidate1 = mix(l0candidate1, l0candidate2, fr[0]);
    float l1candidate2 = mix(l0candidate3, l0candidate4, fr[0]);
    float l1candidate3 = mix(l0candidate5, l0candidate6, fr[0]);
    float l1candidate4 = mix(l0candidate7, l0candidate8, fr[0]);
    float l1candidate5 = mix(l0candidate9, l0candidate10, fr[0]);
    float l1candidate6 = mix(l0candidate11, l0candidate12, fr[0]);
    float l1candidate7 = mix(l0candidate13, l0candidate14, fr[0]);
    float l1candidate8 = mix(l0candidate15, l0candidate16, fr[0]);


    float l2candidate1 = mix(l1candidate1, l1candidate2, fr[1]);
    float l2candidate2 = mix(l1candidate3, l1candidate4, fr[1]);
    float l2candidate3 = mix(l1candidate5, l1candidate6, fr[1]);
    float l2candidate4 = mix(l1candidate7, l1candidate8, fr[1]);


    float l3candidate1 = mix(l2candidate1, l2candidate2, fr[2]);
    float l3candidate2 = mix(l2candidate3, l2candidate4, fr[2]);

    float l4candidate1 = mix(l3candidate1, l3candidate2, fr[3]);

    return l4candidate1;
}

#define noise1d(a) achnoise(a)
#define noise2d(a) achnoise(a)
#define noise3d(a) achnoise(a)
#define noise4d(a) achnoise(a)
float supernoise3d(vec3 p){

	float a =  noise3d(p);
	float b =  noise3d(p + 10.5);
	return (a + b) * 0.5;
}
float supernoise3dX(vec3 p){

	float a =  noise3d(p);
	float b =  noise3d(p + 10.5);
	return (a * b);
}
float fbmHI(vec3 p){
   // p *= 0.1;
    p *= 0.0000169;
    p.x *= 0.489;
	p += time * 0.02;
	//p += getWind(p * 0.2) * 6.0;
	float a = 0.0;
    float w = 1.0;
    float wc = 0.0;
	for(int i=0;i<3;i++){
        //p += noise(vec3(a));
		a += clamp(2.0 * abs(0.5 - (noise3d(p))) * w, 0.0, 1.0);
		wc += w;
        w *= 0.5;
		p = p * 3.0;
	}
	return a / wc;// + noise(p * 100.0) * 11;
}
#define MieScattCoeff 2.0
vec3 wind(vec3 p){
    return vec3(
        supernoise3d(p),
        supernoise3d(p.yzx),
        supernoise3d(-p.xzy)
        ) * 2.0 - 1.0;
}
struct Ray { vec3 o; vec3 d; };
struct Sphere { vec3 pos; float rad; };

float planetradius = 6378000.1;
float minhit = 0.0;
float maxhit = 0.0;
float rsi2(in Ray ray, in Sphere sphere)
{
    vec3 oc = ray.o - sphere.pos;
    float b = 2.0 * dot(ray.d, oc);
    float c = dot(oc, oc) - sphere.rad*sphere.rad;
    float disc = b * b - 4.0 * c;
    vec2 ex = vec2(-b - sqrt(disc), -b + sqrt(disc))/2.0;
    minhit = min(ex.x, ex.y);
    maxhit = max(ex.x, ex.y);
    return mix(ex.y, ex.x, step(0.0, ex.x));
}
vec3 atmosphere(vec3 r, vec3 r0, vec3 pSun, float iSun, float rPlanet, float rAtmos, vec3 kRlh, float kMie, float shRlh, float shMie, float g) {
    // Normalize the sun and view directions.
    pSun = normalize(pSun);
    r = normalize(r);

    // Calculate the step size of the primary ray.
    vec2 p = rsi(r0, r, rAtmos);
    if (p.x > p.y) return vec3(0,0,0);
    p.y = min(p.y, rsi(r0, r, rPlanet).x);
    float iStepSize = (p.y - p.x) / float(iSteps);
	float rs = rsi2(Ray(r0, r), Sphere(vec3(0), rAtmos));
	vec3 px = r0 + r * rs;
shMie *= ( (pow(fbmHI(px  ) * (supernoise3dX(px* 0.00000669 + time * 0.001)*0.5 + 0.5) * 1.3, 3.0) * 0.8 + 0.5));
    
    // Initialize the primary ray time.
    float iTime = 0.0;

    // Initialize accumulators for Rayleigh and Mie scattering.
    vec3 totalRlh = vec3(0,0,0);
    vec3 totalMie = vec3(0,0,0);

    // Initialize optical depth accumulators for the primary ray.
    float iOdRlh = 0.0;
    float iOdMie = 0.0;

    // Calculate the Rayleigh and Mie phases.
    float mu = dot(r, pSun);
    float mumu = mu * mu;
    float gg = g * g;
    float pRlh = 3.0 / (16.0 * PI) * (1.0 + mumu);
    float pMie = 3.0 / (8.0 * PI) * ((1.0 - gg) * (mumu + 1.0)) / (pow(1.0 + gg - 2.0 * mu * g, 1.5) * (2.0 + gg));

    // Sample the primary ray.
    for (int i = 0; i < iSteps; i++) {

        // Calculate the primary ray sample position.
        vec3 iPos = r0 + r * (iTime + iStepSize * 0.5);

        // Calculate the height of the sample.
        float iHeight = length(iPos) - rPlanet;

        // Calculate the optical depth of the Rayleigh and Mie scattering for this step.
        float odStepRlh = exp(-iHeight / shRlh) * iStepSize;
        float odStepMie = exp(-iHeight / shMie) * iStepSize;

        // Accumulate optical depth.
        iOdRlh += odStepRlh;
        iOdMie += odStepMie;

        // Calculate the step size of the secondary ray.
        float jStepSize = rsi(iPos, pSun, rAtmos).y / float(jSteps);

        // Initialize the secondary ray time.
        float jTime = 0.0;

        // Initialize optical depth accumulators for the secondary ray.
        float jOdRlh = 0.0;
        float jOdMie = 0.0;

        // Sample the secondary ray.
        for (int j = 0; j < jSteps; j++) {

            // Calculate the secondary ray sample position.
            vec3 jPos = iPos + pSun * (jTime + jStepSize * 0.5);

            // Calculate the height of the sample.
            float jHeight = length(jPos) - rPlanet;

            // Accumulate the optical depth.
            jOdRlh += exp(-jHeight / shRlh) * jStepSize;
            jOdMie += exp(-jHeight / shMie) * jStepSize;

            // Increment the secondary ray time.
            jTime += jStepSize;
        }

        // Calculate attenuation.
        vec3 attn = exp(-(kMie * (iOdMie + jOdMie) + kRlh * (iOdRlh + jOdRlh)));

        // Accumulate scattering.
        totalRlh += odStepRlh * attn;
        totalMie += odStepMie * attn;

        // Increment the primary ray time.
        iTime += iStepSize;

    }

    // Calculate and return the final color.
    return iSun * (pRlh * kRlh * totalRlh + pMie * kMie * totalMie);
}
vec3 getatm(vec3 ray){
	vec3 sd = rotmat(vec3(1.0, 1.0, 0.0), time * 0.25) * normalize(vec3(0.0, 1.0, 0.0)); 
    vec3 color = atmosphere(
        ray,           // normalized ray direction
        vec3(0,6372e3,0),               // ray origin
        sd,                        // position of the sun
        22.0,                           // intensity of the sun
        6371e3,                         // radius of the planet in meters
        6471e3,                         // radius of the atmosphere in meters
        vec3(5.5e-6, 13.0e-6, 22.4e-6), // Rayleigh scattering coefficient
        21e-6,                          // Mie scattering coefficient
        8e3,                            // Rayleigh scale height
        1.2e3 * MieScattCoeff,                          // Mie scale height
        0.758                           // Mie preferred scattering direction
    );		
 	return color;
    
}

float sun(vec3 ray){
 	vec3 sd = rotmat(vec3(1.0, 1.0, 0.0), time * 0.25) * normalize(vec3(0.0, 1.0, 0.0)); 

    return pow(max(0.0, dot(ray, sd)), 1228.0) * 110.0;
}
float smart_inverse_dot(float dt, float coeff){
    return 1.0 - (1.0 / (1.0 + dt * coeff));
}
#define VECTOR_UP vec3(0.0,1.0,0.0)
vec3 getSunColorDirectly(float roughness){
    vec3 sunBase = vec3(15.0);
	vec3 sd = rotmat(vec3(1.0, 1.0, 0.0), time * 0.25) * normalize(vec3(0.0, 1.0, 0.0)); 

    float dt = max(0.0, (dot(sd, VECTOR_UP)));
    float dtx = smoothstep(-0.0, 0.1, dt);
    float dt2 = 0.9 + 0.1 * (1.0 - dt);
    float st = max(0.0, 1.0 - smart_inverse_dot(dt, 11.0));
    vec3 supersundir = max(vec3(0.0),   vec3(1.0) - st * 4.0 * pow(vec3(50.0/255.0, 111.0/255.0, 153.0/255.0), vec3(2.4)));
//    supersundir /= length(supersundir) * 1.0 + 1.0;
    return supersundir * 4.0 ;
    //return mix(supersundir * 1.0, sunBase, st);
    //return  max(vec3(0.3, 0.3, 0.0), (  sunBase - vec3(5.5, 18.0, 20.4) *  pow(1.0 - dt, 8.0)));
}
#define xsupernoise3d(a) abs(0.5 - noise3d(a))*2.0
#define xsupernoise3dx(a) abs(0.5 - supernoise3d(a))*2.0
float fbmHxI(vec3 p){
   // p *= 0.1;
    p *= 0.021;
    float a = 0.0;
    float w = 0.5;
    for(int i=0;i<6;i++){
	float x = xsupernoise3dx(p);
        a += x * w;
        p = p * (2.9 + x * w * 0.006 );
        w *= 0.60;
    }
    return a;
}

#define CloudsFloor 1700.0
#define CloudsCeil 4000.0

float getHeightOverSea(vec3 p){
    vec3 atmpos = vec3(0.0, planetradius, 0.0) + p;
    return length(atmpos) - planetradius;
}
vec2 mirrored(vec2 v) {
    vec2 m = mod(v, 2.0);
    return mix(m, 2.0 - m, step(1.0, m));
}
float sampleDensity(vec3 pos, vec2 uv, float h){
    h = abs(h * 2.0 - 1.0);
   uv.x += iTime * 0.0002;
    uv.y += iTime * 0.0002;
  //  pos *= 0.01;
  //  uv += vec2(supernoise3d(pos), supernoise3d(pos+100.0))*0.01; 
	return smoothstep(h, 1.3, texture(iChannel0, mirrored(uv)).r + texture(iChannel0, mirrored(uv * 0.78 + 34.1235)).r);// * noise2d(uv);
}

vec2 cloudsDensity3D(vec3 pos){
    vec3 ps = pos;

    vec3 p = ps * 0.009;
	vec3 timev = vec3(time*0.4, time * 0.005, 0.0);
	vec3 windpos = p * 0.01 + timev * 0.001;
    float h = getHeightOverSea(pos);
    float innerh = (h - CloudsFloor) / (CloudsCeil - CloudsFloor);
    float density = sampleDensity(pos, pos.xz * 0.00001, innerh);// * (0.9 + 0.1 * fbmHxI( ps * 0.02 + timev * 1.0));
    density *= (achnoise(p * 0.4) * 0.5 + achnoise(p * 2.5 * 0.4) * 0.25 + achnoise(p * 5.0 * 0.4) * 0.125);
    
    float measurement = (CloudsCeil - CloudsFloor) * 0.5;
    float mediana = (CloudsCeil + CloudsFloor) * 0.5;
    float mlt = (( 1.0 - (abs( h - mediana ) / measurement )));
    float init = smoothstep(0.1, 0.9, density * mlt);
    return  vec2(init, innerh) ;
}

vec2 UV = vec2(0.0);
vec4 internalmarchconservative(vec3 atm, vec3 p1, vec3 p2, float noisestrength){
    int stepcount = CLOUDS_STEPS;
    float stepsize = 1.0 / float(stepcount);
    float rd = fract(rand2sTime(UV)) * stepsize;
    float c = 0.0;
    float w = 0.0;
    float coverageinv = 1.0;
    vec3 pos = vec3(0);
    float clouds = 0.0;
    vec3 color = vec3(0.0);
	float colorw = 1.01;                      
    float godr = 0.0;
    float godw = 0.0;
    float depr = 0.0;
    float depw = 0.0;
    float iter = 0.0;
    vec3 lastpos = p1;
    //depr += distance(CAMERA, lastpos);
    depw += 1.0;
    float linear = distance(p1, mix(p1, p2, stepsize));
    float limit = distance(p1, p2);
    for(int i=0;i<CLOUDS_STEPS;i++){
        if(coverageinv <= 0.01) break;
        pos = mix(p1, p2, iter + rd);
        vec2 as = cloudsDensity3D(pos);
		vec3 timev = vec3(time*0.01, time * 0.01, 0.0);
        clouds = as.x*1.3;
        float W = clouds * max(0.0, coverageinv);
        color += W * vec3(as.y * as.y);
        colorw += W;

        coverageinv -= clouds;
        depr += step(0.99, coverageinv) * distance(lastpos, pos);
        lastpos = pos;
        iter += stepsize;
        //rd = fract(rd + iter * 124.345345);
    }
    if(coverageinv > 0.99) depr = 0.0;
    float cv = 1.0 - clamp(coverageinv, 0.0, 1.0);
    color *= getSunColorDirectly(0.0) * 3.0;
	vec3 sd = rotmat(vec3(1.0, 1.0, 0.0), time * 0.25) * normalize(vec3(0.0, 1.0, 0.0)); 
    color *= 0.5 + 0.5 * (1.0 / (0.2 + 1.0 * (1.0 - max(0.0, dot(sd, normalize(p2 - p1))))));
    return vec4(sqrt(max(0.0, (dot(sd, VECTOR_UP)))) * mix((color / colorw) + atm * min(0.6, 0.01 * depr), atm * 0.41, min(0.99, 0.00001 * depr)), cv);
}
vec3 aces_tonemap(vec3 color){	
	mat3 m1 = mat3(
        0.59719, 0.07600, 0.02840,
        0.35458, 0.90834, 0.13383,
        0.04823, 0.01566, 0.83777
	);
	mat3 m2 = mat3(
        1.60475, -0.10208, -0.00327,
        -0.53108,  1.10813, -0.07276,
        -0.07367, -0.00605,  1.07602
	);
	vec3 v = m1 * color;    
	vec3 a = v * (v + 0.0245786) - 0.000090537;
	vec3 b = v * (0.983729 * v + 0.4329510) + 0.238081;
	return pow(clamp(m2 * (a / b), 0.0, 1.0), vec3(1.0 / 2.2));	
}
float flare(vec3 p, vec3 r){
	return supernoise3dX(10.0 * normalize(p - r))  / pow(distance(p, r) * 10.0, 5.0);	
}
float cloudsSss(vec3 p, vec3 r){
	return 1.0 / pow(distance(p, r) * 1.0, 2.0);	
}
void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	vec2 uv = fragCoord.xy / resolution.xy;
 	UV = uv;
 	vec3 sd = rotmat(vec3(1.0, 1.0, 0.0), time * 0.25) * normalize(vec3(0.0, 1.0, 0.0)); 
	float waterdepth = 2.1;
	vec3 wfloor = vec3(0.0, -waterdepth, 0.0);
	vec3 wceil = vec3(0.0, 0.0, 0.0);
	vec3 orig = vec3(0.0, 2.0, 0.0);
	vec3 ray = getRay(uv);
	
	float spherehit = rsi2(Ray(orig, ray), Sphere(vec3(-2.0, 3.0, 0.0), 1.0));
	float fff = 1.0;
	
	
	float hihit = intersectPlane(orig, ray, wceil, vec3(0.0, 1.0, 0.0));
    
    Sphere sphere1 = Sphere(vec3(0), planetradius + CloudsFloor);
    Sphere sphere2 = Sphere(vec3(0), planetradius + CloudsCeil);
    if(ray.y >= -0.01){
        vec3 rray = vec3(ray.x, abs(ray.y), ray.z);
        vec3 atm = getatm(rray);
        vec3 C = atm * 2.0 + sun(rray);
        
        vec3 atmorg = vec3(0,planetradius,0);
        Ray r = Ray(atmorg, rray);
        float hitfloor = rsi2(r, sphere1);
        float hitceil = rsi2(r, sphere2);
        vec4 clouds = internalmarchconservative(atm, rray * hitfloor, rray * hitceil, 1.0);
        C = mix(C + flare(sd, ray), clouds.xyz * (1.0 + (1.0 - clouds.a * 0.5) * 2.0 * ray.y * cloudsSss(sd, ray)), clouds.a);
	    C *= fff * 0.5;
        //tonemapping
        C = aces_tonemap(C);
     	fragColor = vec4( C,1.0);   
        return;
    }
    vec3 fullcolor = vec3(0.0);
    vec2 pixel = 1.0 / iResolution.xy;
    ray = getRay(uv);


    fff = 1.0;


    hihit = intersectPlane(orig, ray, wceil, vec3(0.0, 1.0, 0.0));

    float lohit = intersectPlane(orig, ray, wfloor, vec3(0.0, 1.0, 0.0));
    vec3 hipos = orig + ray * hihit;
    vec3 lopos = orig + ray * lohit;
    float dist = raymarchwater(orig, hipos, lopos, waterdepth);
    vec3 pos = orig + ray * dist;

    vec3 N = normal(pos.xz, 0.01, waterdepth);
    N = mix(N, VECTOR_UP, 0.8 * min(1.0, sqrt(dist*0.01) * 1.1));
    vec2 velocity = N.xz * (1.0 - N.y);
    vec3 R = normalize(reflect(ray, N));
    vec3 RF = normalize(refract(ray, N, 0.66)); 
    float fresnel = (0.04 + (1.0-0.04)*(pow(1.0 - max(0.0, dot(-N, ray)), 5.0)));

    R.y = abs(R.y);
    vec3 atm = getatm(R);
    vec3 reflection = atm + sun(R);

    vec3 C = fresnel * (reflection) * 2.0 + flare(sd, ray);

    float superscat = pow(max(0.0, dot(RF, sd)), 16.0) ;
    #if ENABLE_SSS
    C += vec3(0.5,0.9,0.8) * superscat * getSunColorDirectly(0.0) * 81.0* (1.0 - 1.0 / (1.0 + 5.0 * max(0.0, dot(sd, VECTOR_UP))));
    vec3 waterSSScolor =  vec3(0.01, 0.33, 0.55)*  0.171 ;
    C += waterSSScolor * getSunColorDirectly(0.0) * (0.3 + getwaves(pos.xz, ITERATIONS_RAYMARCH)) * waterdepth * 0.3 * max(0.0, dot(sd, VECTOR_UP));
    //tonemapping
    #endif
    C *= fff * 0.5;
    C = aces_tonemap(C);
    fullcolor += C;
    
	fragColor = vec4(fullcolor,1.0);
}