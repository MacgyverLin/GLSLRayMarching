/* Slightly Better Raymarcher */
/* By Giraugh */

#define MAX_STEPS 50
#define MAX_DIST 1000.
#define SURF_DIST 0.1
#define AMBIENT_LIGHT 0.
#define SUN_STRENGTH 1.
#define FOG_DENSITY .01
#define FOG_COL vec3(.45, .55, .65)
#define SKY_COL vec3(0.5,0.6,0.8)
#define SUN_COL vec3(1.0,0.9,0.9)

vec2 hash( vec2 p )
{
	p = vec2( dot(p,vec2(127.1,311.7)), dot(p,vec2(269.5,183.3)) );
	return -1.0 + 2.0*fract(sin(p)*43758.5453123);
}

float noise( in vec2 p )
{
    const float K1 = 0.366025404; // (sqrt(3)-1)/2;
    const float K2 = 0.211324865; // (3-sqrt(3))/6;

	vec2  i = floor( p + (p.x+p.y)*K1 );
    vec2  a = p - i + (i.x+i.y)*K2;
    float m = step(a.y,a.x); 
    vec2  o = vec2(m,1.0-m);
    vec2  b = a - o + K2;
	vec2  c = a - 1.0 + 2.0*K2;
    vec3  h = max( 0.5-vec3(dot(a,a), dot(b,b), dot(c,c) ), 0.0 );
	vec3  n = h*h*h*h*vec3( dot(a,hash(i+0.0)), dot(b,hash(i+o)), dot(c,hash(i+1.0)));
    return dot( n, vec3(70.0) );
}

float fbm(vec2 uv) {
    uv *= .02;
    mat2 m = mat2( 1.6,  1.2, -1.2,  1.6 );
    float f  = 0.5000*noise( uv ); uv = m*uv;
    f += 0.2500*noise( uv ); uv = m*uv;
    f += 0.1250*noise( uv ); uv = m*uv;
    f += 0.0625*noise( uv ); uv = m*uv;
    f += 0.01125*noise( uv ); uv = m*uv;
    f += 0.005*noise( uv ); uv = m*uv;
    return f;
}

mat2 Rot(float a) {
	float s = sin(a);
	float c = cos(a);
	return mat2(
    	c, -s, s, c
    );
}

float DBox(vec3 p, vec3 o, vec3 r) {
 	return length(max(abs(p - o) - r, 0.));   
}

float Terrain(vec3 p) {
 	float a = 7.;
    vec2 samp = p.xz - vec2(-5,0);// + vec2(sin(iTime), cos(iTime));
    //samp += 3. * fbm(samp);
    samp.y += 4. * iTime;
    return a * fbm(samp);
}

float GetBuildingDist(vec3 point) {
    vec3 bp = point;
    bp.z -= 60.;
    bp.z += 4. * iTime;
    bp.x += 40.;
    bp.z = mod(bp.z + 100., 200.) - 100.;
    bp.x = mod(bp.x + 40., 80.) - 40.;
    float boxD = DBox(vec3(bp.x, 0, bp.z), vec3(0), vec3(4., 1., 4.));
    return boxD;
}

// Return the distance to the nearest point in the scene
// from (point)
float GetDist(vec3 point) {
    // Ground
    float planeD = point.y - Terrain(point);
    
    
    // Trees
    vec3 tp = point;
    tp.z -= 12.;
    tp.z += 4. * iTime;
    tp.x += 16. * fbm(floor((tp.xz - .4) / .8));
    tp.z += 16. * fbm(floor((tp.xz - .4) / .8));
    tp.x = mod(tp.x + .4, .8) - .4;
    tp.z = mod(tp.z + .4, .8) - .4;
	tp.y -= Terrain(point);
    float treeN = fbm(vec2(-80., 380. - 4. * iTime));
    float s = .15;
    s *= smoothstep(-1., 1., Terrain(point));
    s *= (1. - smoothstep(1.6, 2.1, Terrain(point)));
    tp.y -= s * .75;
    float treeD = length(tp) - s;
    
    
    // Buildings
    float boxD = GetBuildingDist(point);
    
    return min(min(planeD, treeD), boxD);
}

// March a ray forwards into the scene determined by (GetDist)
// Returns the distance the ray travelled before getting
// below (SURF_DIST) distance from a surface or too far away 
float RayMarch(vec3 rayOrigin, vec3 rayDirection) {
    float d = 0.;
    for (int i = 0; i < MAX_STEPS; i++) {
        vec3 p = rayOrigin + rayDirection * d;
        float d_delta = GetDist(p);
        d += d_delta;
        if (d > MAX_DIST || abs(d_delta) < SURF_DIST) break; 
    }
    return d;
}

// Calculate the surface normal at (point)
// can reduce (off) to improve accuracy
vec3 GetNormal(vec3 point) {
    float d = GetDist(point);
    float off = .01;
    vec3 n = vec3(
    	d - GetDist(point - vec3(off,0,0)),
        d - GetDist(point - vec3(0,off,0)),
        d - GetDist(point - vec3(0,0,off))
    );
    return normalize(n);
}


// Get how lit (not in shadow) the given point is. (With Penumbra)
float GetShadowSoft(vec3 ro, vec3 rd, float dmin, float dmax, float k) {
    float res = 1.;
    for (float d = dmin; d < dmax; ) {
        float sceneDist = GetDist(ro + rd * d);
        if (sceneDist < SURF_DIST) return AMBIENT_LIGHT;
        d += sceneDist;
        res = min(res, k * sceneDist / d);
    }
    return min(1., res + AMBIENT_LIGHT);
}

// Get how lit (not in shadow) the given point is.
float GetShadow(vec3 ro, vec3 rd, float dmin, float dmax) {
    for (float d = dmin; d < dmax; ) {
        float sceneDist = GetDist(ro + rd * d);
        if (sceneDist < SURF_DIST) return 0.0;
        d += sceneDist;
    }
    return 1.;
}

// Determine degree of lighting (0 to 1) at (pos) by (lightPos)
float GetLightingPoint(vec3 point, vec3 lightPos) {
    vec3 l = normalize(lightPos - point);
    vec3 n = GetNormal(point);
    float diff = clamp(dot(l, n), 0., 1.);
    
    float shadow = GetShadowSoft(point, l, SURF_DIST * 30., length(lightPos - point), 25.);
    
    return diff * shadow;
}


float GetLightingSun(vec3 point, vec3 sunDir) {
    vec3 n = GetNormal(point);
    float diff = clamp(dot(sunDir, n), 0., 1.);
    float shadow = GetShadowSoft(point, sunDir, SURF_DIST * 30., MAX_DIST, 25.);
    return diff * shadow;
}

vec3 GetFog(vec3 col, float dist) {
    float fogAmount = 1. - exp(-dist * FOG_DENSITY);
    return mix(col, FOG_COL, fogAmount);
}

vec3 GetFogSky(vec3 col, float dist, vec3 rayDir, vec3 sunDir) {
    float fogAmount = 1. - exp(-dist * FOG_DENSITY);
    float sunAmount = .5 * max(0., dot(rayDir, sunDir));
    vec3 fogCol = mix(SKY_COL, SUN_COL, pow(sunAmount, 1.));
    return mix(col, fogCol, fogAmount);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    // Normalized pixel coordinates (square) (from 0 to 1)
    vec2 uv = (fragCoord - .5*iResolution.xy)/iResolution.y;

    // Declare camera position in terms of ray origin and direction
    vec3 rayOrigin = vec3(0, 1, 0);
    vec3 rayDirection = normalize(vec3(uv.x, uv.y, 1));
    
    rayOrigin.y = max(7., Terrain(rayOrigin) + 2.);
    
    // RayMarch to find point
    float dist = RayMarch(rayOrigin, rayDirection);
    vec3 hitPoint = rayOrigin + dist * rayDirection;
    
    // Determine colour
	vec3 col = vec3(0, 0, 0);
    
    float yy = hitPoint.y;
    float ff = 90.;
    yy += .7 * fbm(ff * hitPoint.xz + vec2(0, 4. * ff * iTime));
    
    col += (1. - smoothstep(-1., 0., yy)) * vec3(1, 1, 0);
    col += (1. - smoothstep(-.5, 1.2, yy)) * vec3(0, 1, 0); 
    col += (smoothstep(0., 1., yy)) * vec3(0, .7, .2);
    //col += (smoothstep(1.4, 1.8, yy)) * vec3(1, 1, 1);
    
    if (yy > 1.6) {
        col = mix(col, vec3(1), smoothstep(1.7, 2.2, yy));
    }
    
    if (hitPoint.y <= -1.) {
     	col = mix(col, .4 * SKY_COL, min(1., pow(-hitPoint.y - 1., .2)));
    }
    
    // determine if is a building
    float bd = GetBuildingDist(hitPoint + 7. * SURF_DIST * rayDirection);
    if (bd <= 0.) {
        col = vec3(.1, .1, .12);
    }
    
    
    // Determine lighting
    vec3 sunDir = vec3(-1, -.3, 0); //vec3(-1, -.6, -0.3);
    vec3 lightPos = vec3(2. * cos(iTime), 4, 2. * sin(iTime));
    float lighting = 3. * AMBIENT_LIGHT + GetLightingSun(hitPoint, -sunDir);
    col *= min(1., lighting);
    
    if (hitPoint.y <= -1.) {
     	col = mix(col, SKY_COL, max(0., dot(rayDirection, -sunDir)));   
    }
    
    // Fog
    col = GetFogSky(col, dist, rayDirection, -sunDir);
    
    // Ouput colour at full transparency
    fragColor = vec4(col, 1);
}