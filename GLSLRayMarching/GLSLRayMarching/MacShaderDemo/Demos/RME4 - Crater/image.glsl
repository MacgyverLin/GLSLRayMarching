#define getNormal getNormalHex

//#define raymarch vanillaRayMarch 
#define raymarch enchancedRayMarcher 

#define FAR 570.
#define INFINITY 1e32

#define FOV 110.0
#define FOG 1.

#define PI 3.14159265
#define TAU (2*PI)
#define PHI (1.618033988749895)

float vol = 0.;
float noise = 0.;

float hash12(vec2 p) {
	float h = dot(p,vec2(127.1,311.7));	
    return fract(sin(h)*43758.5453123);
}

// 3d noise
float noise_3(in vec3 p) {
    vec3 i = floor(p);
    vec3 f = fract(p);	
	vec3 u = f*f*(3.0-2.0*f);
    
    vec2 ii = i.xy + i.z * vec2(5.0);
    float a = hash12( ii + vec2(0.0,0.0) );
	float b = hash12( ii + vec2(1.0,0.0) );    
    float c = hash12( ii + vec2(0.0,1.0) );
	float d = hash12( ii + vec2(1.0,1.0) ); 
    float v1 = mix(mix(a,b,u.x), mix(c,d,u.x), u.y);
    
    ii += vec2(5.0);
    a = hash12( ii + vec2(0.0,0.0) );
	b = hash12( ii + vec2(1.0,0.0) );    
    c = hash12( ii + vec2(0.0,1.0) );
	d = hash12( ii + vec2(1.0,1.0) );
    float v2 = mix(mix(a,b,u.x), mix(c,d,u.x), u.y);
        
    return max(mix(v1,v2,u.z),0.0);
}

float fbm(vec3 x)
{
    float r = 0.0;
    float w = 1.0, s = 1.0;
    for (int i=0; i<7; i++)
    {
        w *= 0.5;
        s *= 2.0;
        r += w * noise_3(s * x);
    }
    return r;
}

vec3 fromRGB(int r, int g, int b) {
 	return vec3(float(r), float(g), float(b)) / 255.;   
}
    
vec3 
    light = vec3(0.0),
    p = vec3(0.),
    p2 = vec3(0.),
	lightDir = vec3(0.);

vec3 lightColour = normalize(vec3(1.8, 1.0, 0.3)); 

vec3 saturate(vec3 a) { return clamp(a, 0.0, 1.0); }
vec2 saturate(vec2 a) { return clamp(a, 0.0, 1.0); }
float saturate(float a) { return clamp(a, 0.0, 1.0); }

float smin( float a, float b, float k )
{
    float res = exp( -k*a ) + exp( -k*b );
    return -log( res )/k ;
}

void pR(inout vec2 p, float a) {
	p = cos(a)*p + sin(a)*vec2(p.y, -p.x);
}

struct geometry {
    float dist;
    float materialIndex;
    float specular;
    float diffuse;
    vec3 space;
    vec3 color;
};

float fSphere(vec3 p, float r) {
	return length(p) - r;
}


geometry scene(vec3 p) {
    geometry plane;

    float localNoise = fbm(p / 10.) * 2.;;
    p.y -= localNoise * .2;
    plane.dist = p.y;
    p.y *= 3.5;

    plane.dist = smin(plane.dist, length(p) - 25., .15 + localNoise * .2);
    plane.dist = max(plane.dist, -length(p) + 29.  + localNoise);
    plane.materialIndex = 4.;
    plane.space = p;
    plane.color = vec3(1., .2, .0);
    plane.diffuse = 0.;
    plane.specular = 22.1;
    
    return plane;
}


float t_min = 0.001;
float t_max = FAR;
const int MAX_ITERATIONS = 90;

geometry enchancedRayMarcher(vec3 o, vec3 d, int maxI) {
    geometry mp;
    
    float t_min = 0.001;
    float tb = (2.1-o.y)/d.y;
    
    if( tb<0.0 ) { mp.dist = INFINITY; return mp; }
    
    t_min = tb;
    
    float omega = 1.3;
    float t = t_min;
    float candidate_error = INFINITY;
    float candidate_t = t_min;
    float previousRadius = 0.;
    float stepLength = 0.;
    float pixelRadius = //tan(radians (FOV) / 2.0) 
        1. /350.;
    float functionSign = scene(o).dist < 0. ? -1. : +1.;
    
    
    for (int i = 0; i < MAX_ITERATIONS; ++i) {
        if (maxI > 0 && i > maxI) break; 
        mp = scene(d * t + o);
        float signedRadius = functionSign * mp.dist;
        float radius = abs(signedRadius);
        bool sorFail = omega > 1. &&
        (radius + previousRadius) < stepLength;
        if (sorFail) {
            stepLength -= omega * stepLength;
            omega = 1.;
        } else {
        	stepLength = signedRadius * omega * .8;
        }
        previousRadius = radius;
        float error = radius / t;
        if (!sorFail && error < candidate_error) {
            candidate_t = t;
            candidate_error = error;
        }
        if (!sorFail && error < pixelRadius || t > t_max) break;
        t += stepLength;
   	}
    
    mp.dist = candidate_t;
    
    if (
        (t > t_max || candidate_error > pixelRadius)
    	) mp.dist = INFINITY;
    
    
    return mp;
}

geometry vanillaRayMarch(vec3 o, vec3 d, int maxI) {
    geometry mp;
    
    float l = -.1;
    
    for (int i = 0; i < 30; i++) {
        if (abs(l) < 0.1 || l > 130.) {
            break;
        }
        
        mp = scene(o + d * l);
        l += mp.dist;
    }
    
    mp.dist = l;
    return mp;
}

float softShadow(vec3 ro, vec3 lp, float k) {
    const int maxIterationsShad = 125;
    vec3 rd = (lp - ro); // Unnormalized direction ray.


    float shade = 1.;
    float dist = 1.0;
    float end = max(length(rd), 0.01);
    float stepDist = end / float(maxIterationsShad);
    
    float tb = (8.0-ro.y)/normalize(rd).y; 
    if( tb>0.0 ) end = min( end, tb );
    
    rd /= end;
    for (int i = 0; i < maxIterationsShad; i++) {
        float h = scene(ro + rd * dist).dist;
        shade = min(shade, smoothstep(0.0, 1.0, k * h / dist)); 
        dist += min(h, stepDist * 2.); 
        if (h < 0.001 || dist > end) break;
    }
    return min(max(shade, 0.3), 1.0);
}


#define EPSILON .001
vec3 getNormalHex(vec3 pos)
{
	float d=scene(pos).dist;
	return normalize(
        vec3(
            scene(
                pos+vec3(EPSILON,0,0)).dist-d,
                scene(pos+vec3(0,EPSILON,0)).dist-d,
                scene(pos+vec3(0,0,EPSILON)).dist-d 
        	)
    	);
}

float getAO(vec3 hitp, vec3 normal, float dist)
{
    vec3 spos = hitp + normal * dist;
    float sdist = scene(spos).dist;
    return clamp(sdist / dist, 0.4, 1.0);
}

vec3 Sky(in vec3 rd, bool showSun, vec3 lightDir)
{
   	float sunSize = 1.;
   	float sunAmount = max(dot(rd, lightDir), .1);
   	float v = pow(1.2 - max(rd.y, .5), 1.1);
   	vec3 sky = mix(fromRGB(255,200,100), vec3(1.1, 1.2, 1.3) / 10., v);
   	sky += lightColour * sunAmount * sunAmount * 1. + lightColour * min(pow(sunAmount, 1e4)* sunSize,1233. * sunSize);

   	return clamp(sky, 0.0, 1.0);
}

vec3 doColor( in vec3 sp, in vec3 rd, in vec3 sn, in vec3 lp, geometry obj) {
	vec3 sceneCol = vec3(0.0);
    lp = sp + lp;
    vec3 ld = lp - sp; // Light direction vector.
    float lDist = max(length(ld / 2.), 0.001); // Light to surface distance.
    ld /= lDist; // Normalizing the light vector.
	float atten = 1. / (1.0 + lDist * 0.025 + lDist * lDist * 0.2);
	float diff = max(dot(sn, ld), obj.diffuse);
    float spec = max(dot(reflect(-ld, sn), -rd), obj.specular / 2.);
	vec3 objCol = obj.color;//getObjectColor(sp, sn, obj);
	sceneCol += (objCol * (diff + .15) * spec * 0.1);// * atten;
    return sceneCol;
}


void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    
    //lightColour = normalize(fromRGB(133,7,142)) * 2.; 
    
    vec2 uv = fragCoord.xy / iResolution.xy - .5;

    uv.y *= 1.2;
    vol = texture(iChannel0, vec2(.5, .25)).r  * 4.; 
    float t2 = iTime;
    float 
        sk = sin(-t2 * .1) * 48.0, 
        ck = cos(-t2 * .1) * 48.0,
        
        mat = 0.;
    
    light = vec3(0., 7., 100.);        
    lightDir = light;
    
    
    vec3 
        vuv = vec3(0., 1., 0. ),
    	ro = vec3(ck, 18., sk);
    
    vec3
        vrp =  vec3(0., 0., 0.),
		
    	vpn = normalize(vrp - ro),
    	u = normalize(cross(vuv, vpn)),
    	v = cross(vpn, u),
    	vcv = (ro + vpn),
    	scrCoord = (vcv + uv.x * u * iResolution.x/iResolution.y + uv.y * v),
    	rd = normalize(scrCoord - ro),
        hit;        
	
    vec3 sceneColor = vec3(0.);
	
    geometry tr = raymarch(ro, rd, 0);    
    
    float fog = smoothstep(FAR * FOG, 0., tr.dist) * 1.;
    hit = ro + rd * tr.dist;
    
    vec3 sn = getNormal(hit);	
    
    float sh = softShadow(hit, hit + light, 8.2);
    
    float 
        ao = getAO(hit, sn, 10.2);

    noise = fbm(mod(hit + 20. + hit.yzx* 4., 40.) / 1.);
	vec3 sky = Sky(rd, true, normalize(light)) * 1.;
    
    if (tr.dist < FAR) { 
        sceneColor = (doColor(hit, rd, sn, light, tr) * 1.) * 1.;
        sceneColor *= ao; 
        sceneColor *= sh;
        sceneColor = mix(sceneColor, sky, saturate(tr.dist * 4.5 / FAR));
    } else {
        sceneColor = sky;
    }
    
    fragColor = vec4(clamp(sceneColor * (1. - length(uv) / 3.5), 0.0, 1.0), 1.0);
    fragColor = pow(fragColor, 1./vec4(1.2));

}
