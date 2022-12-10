/* Sky Scattering taken from Round Rock Island by 'Hamneggs' */
//https://www.shadertoy.com/view/4d3GRX

/* Bump mapping and tunnel distance function taken from user Shane's raymarch site */
//view-source:raymarching.com/WebGL/WebGL_TextureBumpedTunnel.htm

#define NUM_STEPS 64
#define PI   3.141593
#define EPS 0.001
#define CINEMATIC
//#define SNOW
//#define JAGGED

// Frequencies and amplitudes of tunnel "A" and "B". See then "path" function.
const float freqA = 0.05;
const float freqB = 0.09;
const float ampA = 6.4;
const float ampB = -2.7;

/***** -Begin Atmospheric Scattering- *****/
/* 
	Okay this is not my atmospheric scattering solution, and for the
	life of me I can't find the shader that I'm borrowing it from.
	It's an implementation of the method discussed in this paper:
	http://www.cs.utah.edu/~shirley/papers/sunsky/sunsky.pdf

	The nice thing is that it's not the usual Scratchapixel solution.
*/
float saturatedDot( in vec3 a, in vec3 b )
{
	return max( dot( a, b ), 0.0 );   
}
vec3 YxyToXYZ( in vec3 Yxy )
{
	float X = Yxy.g * ( Yxy.r / Yxy.b );
	float Z = ( 1.0 - Yxy.g - Yxy.b ) * ( Yxy.r / Yxy.b );

	return vec3(X,Yxy.r,Z);
}
vec3 XYZToRGB( in vec3 XYZ )
{
	// CIE/E
	return XYZ * mat3
	(
		 2.3706743, -0.9000405, -0.4706338,
		-0.5138850,  1.4253036,  0.0885814,
 		 0.0052982, -0.0146949,  1.0093968
	);
}
vec3 YxyToRGB( in vec3 Yxy )
{
	vec3 XYZ = YxyToXYZ( Yxy );
	vec3 RGB = XYZToRGB( XYZ );
	return RGB;
}
void calculatePerezDistribution( in float t, out vec3 A, out vec3 B, out vec3 C, out vec3 D, out vec3 E )
{
	A = vec3(  0.1787 * t - 1.4630, -0.0193 * t - 0.2592, -0.0167 * t - 0.2608 );
	B = vec3( -0.3554 * t + 0.4275, -0.0665 * t + 0.0008, -0.0950 * t + 0.0092 );
	C = vec3( -0.0227 * t + 5.3251, -0.0004 * t + 0.2125, -0.0079 * t + 0.2102 );
	D = vec3(  0.1206 * t - 2.5771, -0.0641 * t - 0.8989, -0.0441 * t - 1.6537 );
	E = vec3( -0.0670 * t + 0.3703, -0.0033 * t + 0.0452, -0.0109 * t + 0.0529 );
}
vec3 calculateZenithLuminanceYxy( in float t, in float thetaS )
{
	float chi  	 	= ( 4.0 / 9.0 - t / 120.0 ) * ( PI - 2.0 * thetaS );
	float Yz   	 	= ( 4.0453 * t - 4.9710 ) * tan( chi ) - 0.2155 * t + 2.4192;

	float theta2 	= thetaS * thetaS;
    float theta3 	= theta2 * thetaS;
    float T 	 	= t;
    float T2 	 	= t * t;

	float xz =
      ( 0.00165 * theta3 - 0.00375 * theta2 + 0.00209 * thetaS + 0.0)     * T2 +
      (-0.02903 * theta3 + 0.06377 * theta2 - 0.03202 * thetaS + 0.00394) * T +
      ( 0.11693 * theta3 - 0.21196 * theta2 + 0.06052 * thetaS + 0.25886);

    float yz =
      ( 0.00275 * theta3 - 0.00610 * theta2 + 0.00317 * thetaS + 0.0)     * T2 +
      (-0.04214 * theta3 + 0.08970 * theta2 - 0.04153 * thetaS + 0.00516) * T +
      ( 0.15346 * theta3 - 0.26756 * theta2 + 0.06670 * thetaS + 0.26688);

	return vec3( Yz, xz, yz );
}
vec3 calculatePerezLuminanceYxy( in float theta, in float gamma, in vec3 A, 
                                 in vec3 B, in vec3 C, in vec3 D, in vec3 E )
{
	return ( 1.0 + A * exp( B / cos( theta ) ) ) * 
           ( 1.0 + C * exp( D * gamma ) + E * cos( gamma ) * cos( gamma ) );
}
vec3 calculateSkyLuminanceRGB( in vec3 s, in vec3 e, in float t )
{
	vec3 A, B, C, D, E;
	calculatePerezDistribution( t, A, B, C, D, E );
	float thetaS = acos( saturatedDot( s, vec3(0,1,0) ) );
	float thetaE = acos( saturatedDot( e, vec3(0,1,0) ) );
	float gammaE = acos( saturatedDot( s, e )		   );
	vec3 Yz = calculateZenithLuminanceYxy( t, thetaS );
	vec3 fThetaGamma = calculatePerezLuminanceYxy( thetaE, gammaE, A, B, C, D, E );
	vec3 fZeroThetaS = calculatePerezLuminanceYxy( 0.0,    thetaS, A, B, C, D, E );
	vec3 Yp = Yz * ( fThetaGamma / fZeroThetaS );
	return YxyToRGB( Yp );
}
const vec3 UP = vec3(0.0, 1.0, 0.0);						// An up vector.

/*
	Combines the sky radiance from the magic above with a specular 
	highl^H^H^H^H^H^Hsun.
*/
vec3 sky( in vec3 d, in vec3 ld )
{
    // Get the sky color.
    vec3 sky = calculateSkyLuminanceRGB(ld, d, 3.0);
    
    // How night time is it? This variable will tell you.
    float night = smoothstep(-0.0, -0.5, clamp(dot(ld, UP),-0.5, -0.0));
    // Set a general brightness level so we don't just have a white screen,
    // and artificially darken stuff at night so it looks good.
    sky *= .040-.035*night;
    
    // Create a spot for the sun. This version gives us some nice edges
    // without having a pow(x,VERY_LARGE_NUMBER) call.
    
    
   	// Mix the sky with the sun.
    //sky = sky*(1.0+sunspot);
    
    // Also add in the stars.
    return sky;
}

/***** -End Atmospheric Scattering- *****/

mat2 r2(float a){
    float s = sin(a);
    float c = cos(a);
    return mat2(s, -c, c,  s);
}

//Random function
float rand(vec2 n) { 
	return fract(sin(dot(n, vec2(12.9898, 4.1414))) * 43758.5453);
}
//Noise function
float noise(vec2 n) {
	const vec2 d = vec2(0.0, 1.0);
	vec2 b = floor(n), f = smoothstep(vec2(0.0), vec2(1.0), fract(n));
	return mix(mix(rand(b), rand(b + d.yx), f.x), mix(rand(b + d.xy), rand(b + d.yy), f.x), f.y);
}

// The path is a 2D sinusoid that varies over time, depending upon the frequencies, and amplitudes.
vec2 path(in float z){ return vec2(ampA*sin(z * freqA), ampB*cos(z * freqB)); }
vec2 path2(in float z){ return vec2(ampB*sin(z * freqB*1.5), ampA*cos(z * freqA*1.3)); }
// The triangle function that Shadertoy user Nimitz has used in various triangle noise demonstrations.
// See Xyptonjtroz - Very cool. Anyway, it's not really being used to its full potential here.
vec3 tri(in vec3 x){return abs(x-floor(x)-.5);} // Triangle function.
vec3 triSmooth(in vec3 x){return cos(x*6.2831853)*0.25+0.25;} // Smooth version. Not used here.

float surfFunc(in vec3 p){
        
   
    float n = dot(tri(p*0.48 + tri(p*0.24).yzx), vec3(0.444));
    p.xz = vec2(p.x + p.z, p.z - p.x) * 0.7071;
    return dot(tri(p*0.72 + tri(p*0.36).yzx), vec3(0.222)) + n; // Range [0, 1]
    
    
    // Other variations to try. All have range: [0, 1]
    
    /*
	return dot(tri(p*0.5 + tri(p*0.25).yzx), vec3(0.666));
	*/
    
    /*
    return dot(tri(p*0.5 + tri(p*0.25).yzx), vec3(0.333)) + 
           sin(p.x*1.5+sin(p.y*2.+sin(p.z*2.5)))*0.25+0.25;
	*/
    
    /*
    return dot(tri(p*0.6 + tri(p*0.3).yzx), vec3(0.333)) + 
           sin(p.x*1.75+sin(p.y*2.+sin(p.z*2.25)))*0.25+0.25; // Range [0, 1]
    */
    
    /*
    p *= 0.5;
    float n = dot(tri(p + tri(p*0.5).yzx), vec3(0.666*0.66));
    p *= 1.5;
    p.xz = vec2(p.x + p.z, p.z - p.x) * 1.7321*0.5;
    n += dot(tri(p + tri(p*0.5).yzx), vec3(0.666*0.34));
    return n;
    */
    
    /*
    p *= 1.5;
    float n = sin(p.x+sin(p.y+sin(p.z)))*0.57;
    p *= 1.5773;
    p.xy = vec2(p.x + p.y, p.y - p.x) * 1.7321*0.5;
    n += sin(p.x+sin(p.y+sin(p.z)))*0.28;
    p *= 1.5773;
    p.xy = vec2(p.x + p.y, p.y - p.x) * 1.7321*0.5;
    n += sin(p.x+sin(p.y+sin(p.z)))*0.15;
    return n*0.4+0.6;
    */

}
// Cheap...ish smooth minimum function.
float smoothMinP( float a, float b, float smoothing ){
    float h = clamp((b-a)*0.5/smoothing + 0.5, 0.0, 1.0 );
    return mix(b, a, h) - smoothing*h*(1.0-h);
}
// Smooth maximum, based on the function above.
float smoothMaxP(float a, float b, float smoothing){
    float h = clamp((a - b)*0.5/smoothing + 0.5, 0.0, 1.0);
    return mix(b, a, h) + h*(1.0 - h)*smoothing;
}
float map(vec3 p){
    vec2 tun = p.xy - path(p.z);
    vec2 tun2 = p.xy - path2(p.z);
    float d = 1.- smoothMinP(length(tun), length(tun2), 4.) + (0.5-surfFunc(p));
    float dd = (sin(p.x/2.)+cos(p.z/1.5));

#ifdef JAGGED
    return max(d, noise(p.zx/2.)+p.y+noise(p.xz/3.)+dd+surfFunc(p/2.));
#endif    
    return smoothMaxP(d, (noise(p.zx/2.)+p.y+noise(p.xz/3.)+dd+surfFunc(p/2.)), .5);
}

float trace(vec3 r, vec3 o){
    float t, d = 0.0;
    
    for(int i = 0; i < NUM_STEPS; i++){
        vec3 p = o + t*r;
        d = map(p);
        if(d < EPS) break;
        t += d *.5;
    }
    return t;
}
// Tri-Planar blending function. Based on an old Nvidia tutorial.
vec3 tex3D( sampler2D tex, in vec3 p, in vec3 n ){
  
    n = max((abs(n) - 0.2)*7., 0.001); // max(abs(n), 0.001), etc.
    n /= (n.x + n.y + n.z );  
    
	return (texture(tex, p.yz)*n.x + texture(tex, p.zx)*n.y + texture(tex, p.xy)*n.z).xyz;
}

// Texture bump mapping. Four tri-planar lookups, or 12 texture lookups in total. I tried to 
// make it as concise as possible. Whether that translates to speed, or not, I couldn't say.
vec3 doBumpMap( sampler2D tx, in vec3 p, in vec3 n, float bf){
   
    const vec2 e = vec2(EPS, 0);
    
    // Three gradient vectors rolled into a matrix, constructed with offset greyscale texture values.    
    mat3 m = mat3( tex3D(tx, p - e.xyy, n), tex3D(tx, p - e.yxy, n), tex3D(tx, p - e.yyx, n));
    
    vec3 g = vec3(0.299, 0.587, 0.114)*m; // Converting to greyscale.
    g = (g - dot(tex3D(tx,  p , n), vec3(0.299, 0.587, 0.114)) )/e.x; g -= n*dot(n, g);
                      
    return normalize( n + g*bf ); // Bumped normal. "bf" - bump factor.
	
}
vec3 getNormal2(vec3 p)
{
    const float d = EPS;
    return normalize(vec3(map(p+vec3(d,0.0,0.0))-map(p+vec3(-d,0.0,0.0)),
                          map(p+vec3(0.0,d,0.0))-map(p+vec3(0.0,-d,0.0)),
                          map(p+vec3(0.0,0.0,d))-map(p+vec3(0.0,0.0,-d))));
}
vec3 getNormal(vec3 p) {
	vec2 e = vec2(EPS, 0.0);
	return normalize((vec3(map(p+e.xyy), map(p+e.yxy), map(p+e.yyx)) - map(p)) / e.x);
}
vec3 hash33(vec3 p){ 
    
    float n = sin(dot(p, vec3(7, 157, 113)));    
    return fract(vec3(2097152, 262144, 32768)*n);
}
void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	vec2 uv = fragCoord.xy / iResolution.xy;
    uv = uv * 2.0 - 1.0;
    uv.x *= iResolution.x / iResolution.y;
    
    float t = iTime;
    vec2 mm = iMouse.xy/iResolution.xy;
    mm.xy -= .5;
    
    vec3 r = normalize(vec3(uv, 1.0 - dot(uv,uv) * .15));
    if(iMouse.z < 1.0)
        mm = (vec2(.0, .2));
        
    vec3 l = normalize(vec3(mm, .2));
    //l.xz *= r2(t);
    // Camera Setup.
	vec3 lookAt = vec3(0.0, 0.0, t*4.);  // "Look At" position.
	vec3 o = lookAt + vec3(0.0, 0.0, -0.1); // Camera position, doubling as the ray origin.

	// Using the Z-value to perturb the XY-plane.
	// Sending the camera, "look at," and two light vectors down the tunnel. The "path" function is 
	// synchronized with the distance function. Change to "path2" to traverse the other tunnel.
	lookAt.xy += path(lookAt.z);
	o.xy += path2(o.z);
	
    r.yx*=r2(noise(vec2(t/3.))+1.);
    r.zy*=r2(noise(vec2(t/2.))+1.3);
    
    vec3 s = sky(r, l);
    
    float sunspot = smoothstep(.99935, .99965, max(dot(r,l),0.0));
    sunspot += smoothstep(.98000, 1.0, max(dot(r,l),0.0))*.05; // Corona.
    
    float hit = trace(r, o);
    vec3 sp = (o+hit*r);
    float d = map(sp);
    vec3 norm = getNormal(sp);   
    norm = doBumpMap(iChannel0, (sp)*(1.0/3.0), norm, 0.05);

    fragColor.a = 1.0; 
    vec4 tex = vec4(tex3D(iChannel0,(sp)*(1.0/3.0), norm), 1.0);
	float c = .0;
    c = max(c + dot(hash33(vec3(r))*2.-1., vec3(0.025)), 0.);
    float diffuse = clamp(dot(norm, l), 0.1, 1.0);

#ifdef SNOW
    if(dot(norm,UP) > .93)
        tex.rgb +=1.; 
#endif
    
    if(d < .5){
        float fog = smoothstep(0.4, 0.8 ,hit*.03);
        fragColor = mix(vec4(tex*diffuse), vec4(s, 1.0), fog);
    }
    else{
        fragColor.rgb = s * (1.0 + sunspot);
    }
    
#ifdef CINEMATIC
    if(uv.y > .75 || uv.y < -.75)
        fragColor=vec4(0.0);
    
    fragColor+=-c;
#endif
}