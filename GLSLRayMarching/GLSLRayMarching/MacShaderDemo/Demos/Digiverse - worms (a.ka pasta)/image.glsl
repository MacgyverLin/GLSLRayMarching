/* 

    Worms from "Digiverse" (demoscene producion)
	
    https://www.youtube.com/watch?v=p5p_qWKrKj0
    http://www.pouet.net/prod.php?which=76719


*/


/*
	http://bit.ly/shadertoy-plugin
*/





#pragma optimize(off)






#define FAR 10.
#define t iTime
#define mt iChannelTime[1]
#define FOV 80.0
#define FOG .4

#define PI 3.14159265
#define TAU (2*PI)
#define PHI (1.618033988749895)

vec3 light = vec3(0.0);
vec3 opRep( vec3 p, vec3 c )
{
    return mod(p,c)-0.5*c;
}

vec3 opU2( vec3 d1, vec3 d2 ) {
    if (d1.x < d2.x) return d1;
    return d2;
}

vec3 opS2( vec3 d1, vec3 d2 )
{	
    if (-d2.x > d1.x) return -d2;
    return d1;
}

float vmax(vec3 v) {
	return max(max(v.x, v.y), v.z);
}

void pR(inout vec2 p, float a) {
	p = cos(a)*p + sin(a)*vec2(p.y, -p.x);
}

// Repeat around the origin by a fixed angle.
// For easier use, num of repetitions is use to specify the angle.
float pModPolar(inout vec2 p, float repetitions) {
	float angle = 2.*PI/repetitions;
	float a = atan(p.y, p.x) + angle/2.;
	float r = length(p);
	float c = floor(a/angle);
	a = mod(a,angle) - angle/2.;
	p = vec2(cos(a), sin(a))*r;
	// For an odd number of repetitions, fix cell index of the cell in -x direction
	// (cell index would be e.g. -5 and 5 in the two halves of the cell):
	if (abs(c) >= (repetitions/2.)) c = abs(c);
	return c;
}

// Box: correct distance to corners
float fBox(vec3 p, vec3 b) {
	vec3 d = abs(p) - b;
	return length(max(d, vec3(0))) + vmax(min(d, vec3(0)));
}

float fCross(vec3 p, vec3 size) {
	return min(fBox(p, size), min(fBox(p, size.zxy), fBox(p, size.yzx)));
}

// Repeat in two dimensions
vec2 pMod2(inout vec2 p, vec2 size) {
	vec2 c = floor((p + size*0.5)/size);
	p = mod(p + size*0.5,size) - size*0.5;
	return c;
}

// pasta
float spi(vec3 p, bool hole) {
    vec3 op = p;

    pR(p.yz, p.x * .4);    
    
    float y = pModPolar(p.zy, 3.);
    
    p.z -= .09 + sin(p.z) * .07;
    
    pR(p.yz, p.x * 5.);    
    
    float x = pModPolar(p.zy, 5.);
	
    p.z -= .01;
    p.z -= (.03 + x / 65. + sin(p.z * 3. + y / 34.) * .43) * .3;
	
    op.x -= y * .01 + x * .01;
    
 	float l = length(p.zy) - .01 - sin(p.z) * 0.03;
    if (hole) return l;
	return max(l, op.x - iTime * .3 + .15);
        
}

// scene
vec3 map(vec3 p) {
    vec3 op = p;
    vec3 obj = vec3(0, 1., 1.0), 
        obj2 = vec3(FAR, 2., 0.);

    vec3 orgP = p;
 
    p = opRep(orgP, vec3(.5));
    
    vec3 size = vec3(0.2, .32, .1 );
    
    #define C size *= 1.1; p = opRep(orgP, vec3(0.35) + size.y + size.z); obj = opS2(obj, vec3(fCross(p, size) + .05, 0.0, 1.));
    
    // add or remove C :)
    C C C
    
    vec3 p2 = op;
    
    p2.y -= .4;
    p2.z -= 4.8;
	
    op.yz -= vec2(.4, 4.8);
    
    if (length(op.zy) - .15 < 0.1) {
        obj.x = max(obj.x, -spi(p2, true) + .02);
        obj2.x = spi(p2, false);
    } else { 
     	obj2.x = length(op.zy) - .15;   
    }
    
    return opU2(obj, obj2);
}

vec3 trace(vec3 ro, vec3 rd) {
    vec3 t = vec3(0., -1., 0.0), d;
    for (int i = 0; i < 70; i++) {
        d = map(ro + rd * t.x);
        if (abs(d.x) < 0.001 || t.x > FAR) break;
        t.x += d.x * .7; 
    }
    t.yz = d.yz;
    return t;
}

vec3 traceRef(vec3 ro, vec3 rd) {
    vec3 t = vec3(0., 1., 0.), d;

    for (int i = 0; i < 36; i++) {
        d = map(ro + rd * t.x);
        if (abs(d.x) < 0.001 || t.x> FAR) break;
        t.x += d.x;
    }
    t.yz = d.yz;
    return t;
}

float softShadow(vec3 ro, vec3 lp, float k) {
    const int maxIterationsShad = 18;
    vec3 rd = (lp - ro);

    float shade = 1.0;
    float dist = .01;
    float end = max(length(rd), 0.001);
    float stepDist = end / float(maxIterationsShad);

    rd /= end;
    for (int i = 0; i < maxIterationsShad; i++) {
        float h = map(ro + rd * dist).x;
        shade = min(shade, smoothstep(0.0, 1.0, k * h / dist)); 
        dist += min(h, stepDist * 2.); 
        if (h < 0.001 || dist > end) break;
    }
    return min(max(shade, 0.55), 1.0);
}

vec3 getNormal(in vec3 pos) {
    vec2 eps = vec2(0.001, 0.0);
    vec3 normal = vec3(
        map(pos + eps.xyy).x - map(pos - eps.xyy).x,
        map(pos + eps.yxy).x - map(pos - eps.yxy).x,
        map(pos + eps.yyx).x - map(pos - eps.yyx).x);
    return normalize(normal);
}

float getAO(in vec3 hitp, in vec3 normal) {
    float dist = .05;
    vec3 spos = hitp + normal * dist;
    float sdist = map(spos).x;
    return clamp(sdist / dist, 0.4, 1.0);
}

vec3 getObjectColor(vec3 p, vec3 n, vec2 mat) {
    if (mat.x == 0.0) return vec3(.0, .0, .1) + vec3(0., 1., 1.) * smoothstep(0.1, .0, fract(p.y * 9.));
    if (mat.x == 2.0) return vec3(.8, .0, .4) + floor(.1 + fract(p.x * 14. - 3. * iTime));
    
    return vec3(.0);
}

vec3 doColor( in vec3 sp, in vec3 rd, in vec3 sn, in vec3 lp, vec2 mat) {
	vec3 ld = lp - sp; 
    float lDist = max(length(ld), 0.001);
    ld /= lDist; 

    float atten = 2.0 / (1.0 + lDist * 0.525 + lDist * lDist * 0.05);
	float diff = max(dot(sn, ld), .1);
    float spec = pow(max(dot(reflect(-ld, sn), -rd), 0.0), 1.0);

    vec3 objCol = getObjectColor(sp, sn, mat);

    if (mat.x == 2.) spec = 0.;
    
    return (objCol * (diff + 0.15) + vec3(.1, .1, .1) * spec * .8) * atten;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    
    vec2 uv = fragCoord.xy / iResolution.xy - .5;
    
    uv *= tan(radians (FOV) / 2.0) * 2.;
    uv.y += sin(t * 3. + cos(4.*-t)) * 0.03;
    
    float 
        sk = sin(t * .3) * 22.0,
        ck = cos(t * .3) * 22.0,
        
        mat = 0.;
        
    light = vec3(0., 1., 1.);        
    
    vec3 sceneColor = vec3(0.);
    
    vec3 
        vuv = normalize(vec3(0., 1., sin(iTime) * .3)), // up
    	ro = vec3(t * .3 , 0.4 , 5.12 ), 
        oro,
    	vrp =  vec3(t * .3 - 18. + ck, 0.4, -43. + sk ),
		
    	vpn = normalize(vrp - ro),
    	u = normalize(cross(vuv, vpn)),
    	v = cross(vpn, u),
    	vcv = (ro + vpn),
    	scrCoord = (vcv + uv.x * u * iResolution.x/iResolution.y + uv.y * v),
    	rd = normalize(scrCoord - ro);
                

    vec3 lp = light + ro;

    vec3 tr = trace(ro, rd), otr = tr;    
    
    float fog = smoothstep(FAR * FOG, 0., tr.x * 3.);
    
    ro += rd * tr.x;
    
    vec3 sn = getNormal(ro);	
    float ao = getAO(ro, sn);
    
    sceneColor += doColor(ro, rd, sn, lp, tr.yz) * 4.;
    float sh = softShadow(ro, lp, 1.);
    
    rd = reflect(rd, sn);
    
    tr = traceRef(ro + rd * .015, rd);
	ro += rd * tr.x;
    
    sn = getNormal(ro);
   
    sceneColor += doColor(ro, rd, sn, lp, tr.yz);        
    sceneColor *= sh * fog * ao;

    fragColor = vec4(clamp(sceneColor, 0.0, 1.0), 1.0);
}