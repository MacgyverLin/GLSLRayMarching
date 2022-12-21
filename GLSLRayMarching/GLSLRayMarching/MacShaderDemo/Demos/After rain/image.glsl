#define OCTAVES  8.0

#define MAX_STEPS  32
#define THRESHOLD .01

const float fogDensity = 0.25;

float rand(vec2 co){
   return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

float rand2(vec2 co){
   return fract(cos(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}


float interFunc2(float t) {
   return 6.0*pow(t, 5.0) - 15.0 * pow(t, 4.0) + 10.0 * pow(t, 3.0);
}

// Rough Value noise implementation
float valueNoiseSimple(vec2 vl) {
   float minStep = 1.0 ;

   vec2 grid = floor(vl); // Left-bottom corner of the grid
   vec2 gridPnt1 = grid;
   vec2 gridPnt2 = vec2(grid.x, grid.y + minStep);
   vec2 gridPnt3 = vec2(grid.x + minStep, grid.y);
   vec2 gridPnt4 = vec2(gridPnt3.x, gridPnt2.y);

    // Removed perlinNoise, Value noise is much faster and has good enough result
    float s = rand2(grid); // 0,0
    float t = rand2(gridPnt3); // 1,0
    float u = rand2(gridPnt2); // 0,1
    float v = rand2(gridPnt4); // 1,1
    
    float x1 = smoothstep(0., 1., fract(vl.x));
    float interpX1 = mix(s, t, x1);
    float interpX2 = mix(u, v, x1);
    
    float y = smoothstep(0., 1., fract(vl.y));
    float interpY = mix(interpX1, interpX2, y);
    
    return interpY;
}

float fractalNoise(vec2 vl) {
    float persistance = 2.0;
    float amplitude = 1.2;
    float rez = 0.0;
    vec2 p = vl;
    
    for (float i = 0.0; i < OCTAVES; i++) {
        rez += amplitude * valueNoiseSimple(p);
        amplitude /= persistance;
        p *= persistance; // Actually the size of the grid and noise frequency
        //frequency *= persistance;
    }
    return rez;
}

float scene(vec3 a) {
   
   float zVal = fractalNoise(vec2(a.x- 5., a.z ));
   return a.y + 0.2 + sin(zVal / 2.); // add smoothing noise to the plane
   
   //return min(length(a - vec3(0., -0.015, 0.)) - .25, a.y + 0.2);
}

vec3 snormal(vec3 a) {
   vec2 e = vec2(.0001, 0.);
   float w = scene(a);
    /*
       return normalize(vec3(
       scene(a+e.xyy) - scene(a-e.xyy),
       scene(a+e.yxy) - scene(a-e.yxy),
       scene(a+e.yyx) - scene(a-e.yyx) ));
*/

   return normalize(vec3(
       scene(a+e.xyy) - w,
       e.x,
       scene(a+e.yyx) - w));
}

float trace(vec3 O, vec3 D, out float hill) {
    float L = 0.;
    int steps = 0;
    float d = 0.;
    for (int i = 0; i < MAX_STEPS; ++i) {
        d = scene(O + D*L);
        L += d;
        
        if (d < THRESHOLD*L) // Adaptive threshold 
            break;
    }
    
    hill = d;
    return L;
}

float occluded(vec3 p, float len, vec3 dir) {
    return max(0., len - scene(p + len * dir));
}

float occlusion(vec3 p, vec3 normal) {
    vec3 rotZccw = vec3(-normal.y, normal.xz);
    vec3 rotZcw = vec3(normal.y, -normal.x, normal.z);
    
    vec3 rotXccw = vec3(normal.x, normal.z, -normal.y);
    vec3 rotXcw = vec3(normal.x, -normal.z, normal.y);
    
    vec3 rotYccw = vec3(normal.z, normal.y, -normal.x);
    vec3 rotYcw = vec3(-normal.z, normal.y, normal.x);
    
    float rez = 0.;
    float dst = .2;

   	rez+= occluded(p, dst, normal);
    
    rez+= occluded(p, dst, rotXccw);
    rez+= occluded(p, dst, rotXcw);

    rez+= occluded(p, dst, rotYccw);
    rez+= occluded(p, dst, rotYcw);

    rez+= occluded(p, dst, rotZccw);
    rez+= occluded(p, dst, rotZcw);

    // Basically we should count number of intersections to use
    // Monte-Carlo approximation. But, we can use information
    // about distance to the surface. 
    return (1. - min(rez, 1.));
}


vec3 enlight(vec3 p, vec3 normal, vec3 eye, vec3 lightPos) {
    vec3 dir = lightPos - p;
    vec3 eyeDir = eye - p;
    vec3 I = normalize(dir);
    vec3 color = texture(iChannel0, p.xz *.5 + .5).rgb;//vec3(.0, .5, .0);//
    
    vec3 ambient = color;
    vec3 diffuse = max(dot(normal, I), 0.) * color.rgb;

    diffuse = clamp(diffuse, 0., 1.) * 0.75;

    vec3 refl = normalize(-reflect(I, normal));
    float spec = max(dot(refl, normalize(eyeDir)), 0.);
    
    spec = pow(spec, 0.3 * 60.); // the main power of material:)
    spec = clamp(spec, 0., 1.);
    
    vec3 Ispec = spec * vec3(1.0, 1.0, .9);
    
    return Ispec + diffuse + ambient * occlusion(p, normal);
}



void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord.xy / iResolution.xy;
    vec2 centered_uv = uv * 2. - 1.;
    centered_uv.x *= iResolution.x / iResolution.y;
    
    vec2 sunPos = vec2(.845 * iResolution.x / iResolution.y, .2);

    float timeOffset = iTime / 5.;
    
    vec3 O = vec3(0., 0.1, 1. - timeOffset);
    float h = scene(O) * 0.65;
    O.y -= h;
    
    vec3 D = normalize(vec3(centered_uv, -1.0)); //fov

    float hill;
    float path = trace(O, D, hill);
    vec3 coord = O + path * D;

    vec3 resColor;
    vec3 skyBlueColor = vec3(0.529411765, 0.807843137, 0.980392157); // nice blue color
    vec3 sunColor = vec3(1.0, 1.0, .975);
    vec3 sunGalo = vec3(.7, .7, .5);

    // Background color
    vec3 bgColor = mix(vec3(1.), skyBlueColor, clamp(centered_uv.y, 0., 1.));
    float sunDst = length(centered_uv - sunPos) ;
    float sunFluctuation = valueNoiseSimple(centered_uv - sunPos + timeOffset);
    sunFluctuation = clamp(sunFluctuation * .25, 0.1, .2);
    
    float galoVal= exp(-pow(sunDst * 0.35, 1.15));
    float val  = clamp(1. / (sunDst *110.5), 0., 1.);
    
    bgColor = mix(bgColor, sunColor*val + (galoVal + sunFluctuation) * sunGalo, galoVal + .5);
    
    if (hill >= 0.2) {
        float cloudCeil = centered_uv.y * .5 - .085;
        vec2 cloudCoord = centered_uv / cloudCeil;
        cloudCoord.y += timeOffset / 4.;
        cloudCoord.x /= pow(iResolution.x / iResolution.y, 3.5);
        float cloudNoise = -2. + 2. * fractalNoise(cloudCoord + 3.5);
        resColor = (bgColor + clamp(cloudNoise, 0., 1.) );
        resColor = mix(bgColor, resColor, clamp(cloudCeil, 0., 1.));
    } else {
        vec3 lightPos = vec3(5., 3. -h, -2. - timeOffset);
        vec3 normal = snormal(coord);
        
        resColor = enlight(coord, normal, O, lightPos);
    
        // Calc some fog
    	float fogFactor = exp(-pow(abs(fogDensity * (coord.z - 1.5 + timeOffset)), 4.0));
    	fogFactor = clamp(fogFactor, 0.0, 1.0);
    	resColor = mix(bgColor, resColor, fogFactor);
    }

    fragColor = vec4(resColor, 1.);
}