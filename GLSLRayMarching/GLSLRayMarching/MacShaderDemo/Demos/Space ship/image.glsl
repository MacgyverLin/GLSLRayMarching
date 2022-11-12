#define EPS 0.00002

#define MAX_DIST 10.0

// SHIP SDF /////////////////////////////////////////
float sdSphere( vec3 p, float s )
{
    return length(p)-s;
}

float sdEllipsoid( in vec3 p, in vec3 r ) // approximated
{
    float k0 = length(p/r);
    float k1 = length(p/(r*r));
    return k0*(k0-1.0)/k1;
}

// vertical
float sdCone( in vec3 p, in vec2 c, float h )
{
    vec2 q = h*vec2(c.x,-c.y)/c.y;
    vec2 w = vec2( length(p.xz), p.y );
    
	vec2 a = w - q*clamp( dot(w,q)/dot(q,q), 0.0, 1.0 );
    vec2 b = w - q*vec2( clamp( w.x/q.x, 0.0, 1.0 ), 1.0 );
    float k = sign( q.y );
    float d = min(dot( a, a ),dot(b, b));
    float s = max( k*(w.x*q.y-w.y*q.x),k*(w.y-q.y)  );
	return sqrt(d)*sign(s);
}

float sdTorus( vec3 p, vec2 t )
{
  vec2 q = vec2(length(p.xz)-t.x,p.y);
  return length(q)-t.y;
}

float sdCapsule( vec3 p, vec3 a, vec3 b, float r )
{
  vec3 pa = p - a, ba = b - a;
  float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
  return length( pa - ba*h ) - r;
}

float sdCappedCone(vec3 p, vec3 a, vec3 b, float ra, float rb)
{
    float rba  = rb-ra;
    float baba = dot(b-a,b-a);
    float papa = dot(p-a,p-a);
    float paba = dot(p-a,b-a)/baba;
    float x = sqrt( papa - paba*paba*baba );
    float cax = max(0.0,x-((paba<0.5)?ra:rb));
    float cay = abs(paba-0.5)-0.5;
    float k = rba*rba + baba;
    float f = clamp( (rba*(x-ra)+paba*baba)/k, 0.0, 1.0 );
    float cbx = x-ra - f*rba;
    float cby = paba - f;
    float s = (cbx < 0.0 && cay < 0.0) ? -1.0 : 1.0;
    return s*sqrt( min(cax*cax + cay*cay*baba,
                       cbx*cbx + cby*cby*baba) );
}


float sdRoundBox( vec3 p, vec3 b, float r )
{
  vec3 q = abs(p) - b;
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0) - r;
}


float opSubtract( float d1, float d2 ) {
	 return max(-d1,d2); 
}

vec3 opElongate(in vec3 p, in vec3 h )
{
    return p - clamp( p, -h, h );
}

float opSmoothUnion( float d1, float d2, float k ) {
    float h = clamp( 0.5 + 0.5*(d2-d1)/k, 0.0, 1.0 );
    return mix( d2, d1, h ) - k*h*(1.0-h); 

}

float shipWindows(in vec3 p) {
    return sdRoundBox(vec3(abs(p.x) - 0.56, p.y - 0.76, p.z-0.57), vec3(0.5, 0.5, 0.5), 0.05);
}

// returns 0 for body, 1 for window
float windowDeform(in vec3 p){
	return 1.0 - smoothstep(0.0, 0.01, shipWindows(p));
}


float shipBody( in vec3 p) {
	return opSmoothUnion(
		sdEllipsoid(p, vec3(0.3, 0.4, 0.3)),
		sdCapsule(vec3(abs(p.x), p.y, abs(p.z)), vec3(0.2, 0.0, 0.2), vec3(0.28, -0.1, 0.28), 0.015),
		0.02
	) + 0.01 * windowDeform(p);
}

float shipEngine( in vec3 p){
	return opSubtract(
		sdCone(p + vec3(0.0, 0.34, 0.0), vec2(0.6, 1.0), 0.25),
		sdCone(p + vec3(0.0, 0.42, 0.0), vec2(0.40, 1.0), 0.05) - 0.07
	);
}


// ring and landing gear
float shipRing( in vec3 p){
	return min(
		sdTorus(opElongate(p + vec3(0, 0.05, 0), vec3(0, 0.05, 0)), vec2(0.4, 0.013)),
		sdCappedCone(vec3(abs(p.x), p.y, abs(p.z)), vec3(0.1, -0.3, 0.1), vec3(0.17, -0.5, 0.17), 0.02, 0.01)
	);
}




float ship(in vec3 p){
	return min(
		min(
			shipBody(p),
			shipEngine(p)
		),
		shipRing(p)
	);
}

// Ship map
float map(in vec3 p){
    float d2 = dot(p,p);
    if(d2 > 1.){
        return sqrt(d2)-0.5;
    }
    return ship(p.xzy); // Rotat eship so it's horizontal
}

float windowMat(in vec3 p) {
    return smoothstep(-0.001, 0.0,-shipWindows(p.xzy));
}


float engineMat(in vec3 p) {
    return smoothstep(-EPS - 0.01, -EPS, -shipEngine(p.xzy));
}


// Engine plume
// returns 3D value noise - from https://iquilezles.org/articles/gradientnoise/
float noise( in vec3 x )
{
    vec3 i = floor(x);
    vec3 f = fract(x);
	f = f*f*(3.0-2.0*f);
	vec2 uv = (i.xy+vec2(37.0,17.0)*i.z) + f.xy;
	vec2 rg = textureLod( iChannel0, (uv+0.5)/256.0, 0.0).yx;
	return mix( rg.x, rg.y, f.z ) - 0.5;
    
}
float fbm( in vec3 x, in float H, in int octaves)
{    
    float G = exp2(-H);
    float f = 1.0;
    float a = 1.0;
    float t = 0.0;
    for( int i=0; i<octaves; i++ )
    {
        t += a*noise(f*x);
        f *= 2.0;
        a *= G;
    }
    return t;
}

float exhaustNoise(in vec3 p, in int octaves){
    vec3 p2 = p.xzy;
    vec3 noise_pos = p2 * vec3(10. / p2.y, 2., 10. / p2.y) + vec3(0., 50. * iTime, 0.); // Moving origin to make exhaust move
   
    float strength = smoothstep(0.25, 2., -p2.y) * -p2.y * 0.1;
    float distort = fbm(noise_pos, 1.2, octaves) * strength;
    return distort;
}

float exhaust(in vec3 p, in int octaves) {
    vec3 p2 = p.xzy + vec3(0., -0.25, 0.); // origin centered on start of exhaust
    float distort = exhaustNoise(p, octaves);

    return sdCone(p2, vec2(0.1, 1.0), 100.0) + distort;
}

vec3 exhaustNormal( in vec3 pos ) // for function f(p)
{
    const float h = 0.001;
    #define ZERO (min(iFrame,0)) // non-constant zero
    vec3 n = vec3(0.0);
    for( int i=ZERO; i<4; i++ )
    {
        vec3 e = 0.5773*(2.0*vec3((((i+3)>>1)&1),((i>>1)&1),(i&1))-1.0);
        n += e*exhaust(pos+e*h, 2);
    }
    return normalize(n);
}



float softshadow( in vec3 ro, in vec3 rd, float mint, float k )
{
    float res = 1.0;
    float t = mint;
	float h = 1.0;
    for( int i=0; i<32; i++ )
    {
        h = map(ro + rd*t);
        res = min( res, k*h/t );
		t += clamp( h, 0.005, 0.1 );
    }
    return clamp(res,0.0,1.0);
}


// From https://iquilezles.org/articles/normalsSDF/
vec3 calcNormal( in vec3 pos ) // for function f(p)
{
    const float h = 0.0001;      // replace by an appropriate value
    #define ZERO (min(iFrame,0)) // non-constant zero
    vec3 n = vec3(0.0);
    for( int i=ZERO; i<4; i++ )
    {
        vec3 e = 0.5773*(2.0*vec3((((i+3)>>1)&1),((i>>1)&1),(i&1))-1.0);
        n += e*map(pos+e*h);
    }
    return normalize(n);
}


float calcAO( in vec3 pos, in vec3 nor )
{
	float occ = 0.0;
    float sca = 1.0;
    for( int i=0; i<5; i++ )
    {
        float h = 0.01 + 0.12*float(i)/4.0;
        float d = map( pos + h*nor );
        occ += (h-d)*sca;
        sca *= 0.95;
        if( occ>0.35 ) break;
    }
    return clamp( 1.0 - 3.0*occ, 0.0, 1.0 ) * (0.5+0.5*nor.y);
}


bool intersect( in vec3 ro, in vec3 rd, out float dist )
{
	float h = 1.0;
	dist = 0.0;
    for( int i=0; i<128; i++ )
    {
		if( h < EPS * dist) return true;
		h = map(ro + rd * dist);
        dist += h;
		if( dist > MAX_DIST) return false;
    }
	return false;
}

// Often fails because of inexact SDF, but this is okay - it leads to a cool pattern in the exhaust.
bool intersect_exhaust( in vec3 ro, in vec3 rd, out float dist )
{
	float h = 1.0;
	dist = 0.0;
    for( int i=0; i<64; i++ )
    {
		if( h < 0.0001 * dist) return true;
        vec3 p = ro + rd * dist;
		h = exhaust(ro + rd * dist, 6);
        dist += h * 0.9;
		if( dist > 20.) return false;
    }
	return h < 0.01;
}

// Faster, lower quality exhaust
bool intersect_exhaust_lq( in vec3 ro, in vec3 rd, out float dist)
{
	float h = 1.0;
	dist = 0.0;
    for( int i=0; i<16; i++ )
    {
		if( h < 0.02 * dist) return true;
        vec3 p = ro + rd * dist;
		h = exhaust(ro + rd * dist, 1);
        dist += h * 0.9 + 0.02;
		if( dist > 50.) return false;
    }
	return false;
}

// From https://www.shadertoy.com/view/4slSWf
void generateRay( out vec3 resRo, out vec3 resRd, in vec3 po, in vec3 ta, in vec2 pi )
{
	vec2 p = (2.0*pi-iResolution.xy)/iResolution.y;
        
    // camera matrix
    vec3 ww = normalize( ta - po );
    vec3 uu = normalize( cross(ww,vec3(0.0,1.0,0.0) ) );
    vec3 vv = normalize( cross(uu,ww));

	// create view ray
	vec3 rd = normalize( p.x*uu + p.y*vv + 2.2*ww );

    resRo = po;
    resRd = rd;
}


vec3 fancyCube( sampler2D sam, in vec3 d, in float s, in float b )
{
    vec3 colx = texture( sam, 0.5 + s*d.yz/d.x, b ).xyz;
    vec3 coly = texture( sam, 0.5 + s*d.zx/d.y, b ).xyz;
    vec3 colz = texture( sam, 0.5 + s*d.xy/d.z, b ).xyz;
    
    vec3 n = d*d;
    
    return (colx*n.x + coly*n.y + colz*n.z)/(n.x+n.y+n.z);
}


vec2 hash( vec2 p ) { p=vec2(dot(p,vec2(127.1,311.7)),dot(p,vec2(269.5,183.3))); return fract(sin(p)*43758.5453); }

vec2 voronoi( in vec2 x )
{
    vec2 n = floor( x );
    vec2 f = fract( x );

	vec3 m = vec3( 8.0 );
    for( int j=-1; j<=1; j++ )
    for( int i=-1; i<=1; i++ )
    {
        vec2  g = vec2( float(i), float(j) );
        vec2  o = hash( n + g );
        vec2  r = g - f + o;
		float d = dot( r, r );
        if( d<m.x )
            m = vec3( d, o );
    }

    return vec2( sqrt(m.x), m.y+m.z );
}


// Background based off of https://www.shadertoy.com/view/llj3Rz
vec3 background( in vec3 d, in vec3 l , in float starsize)
{
    vec3 col = vec3(0.0);
         col += 0.6*pow( fancyCube( iChannel1, d, 0.05, 5.0 ).zyx, vec3(2.0) );
         col += 1.5*vec3(0.80,0.5,0.6)*pow( fancyCube( iChannel1, d, 0.1, 0.0 ).xxx, vec3(6.0) );
    float stars = smoothstep( 0.3, 0.7, fancyCube( iChannel1, d, 0.91, 0.0 ).x );

    col = smoothstep(0.15, 0.5, col);
    
    vec3 n = abs(d);
    n = n*n*n;
    
    vec2 vxy = voronoi( 30.0*d.xy*starsize );
    vec2 vyz = voronoi( 30.0*d.yz*starsize );
    vec2 vzx = voronoi( 30.0*d.zx*starsize );
    vec2 r = (vyz*n.x + vzx*n.y + vxy*n.z) / (n.x+n.y+n.z);
    col += 0.9 * stars * clamp(1.0-(3.0+r.y*5.0)*r.x,0.0,1.0);



    float s = clamp( dot(d,l), 0.0, 1.0 );
    col += 0.4*pow(s,10.0*starsize)*vec3(1.0,0.7,0.6)*2.0;
    col += 0.4*pow(s,100.0*starsize)*vec3(1.0,0.9,0.8)*2.0;
    
    return col;
}

vec3 BlackBody( float t )
{
    const float h = 6.6e-34; // Planck constant
    const float k = 1.4e-23; // Boltzmann constant
    const float c = 3e8;// Speed of light

    vec3 w = vec3( 610.0, 549.0, 468.0 ) / 1e9; // approximate wavelength of primaries
    
    // Planck's law https://en.wikipedia.org/wiki/Planck%27s_law
    
    vec3 w5 = w*w*w*w*w;    
    vec3 o = 2.*h*(c*c) / (w5 * (exp(h*c/(w*k*t)) - 1.0));

    return o;
}

vec3 shadeExhaust(vec3 p, vec3 rd) {
    vec3 norm = exhaustNormal(p);
    float ndotr = dot(rd, norm);
    float rim = pow(1.0-abs(ndotr),2.0);
    float temp_gradient = mix(1200., 0., -p.z * 0.03);
    float temperature = temp_gradient + smoothstep(-0.5, 0.5, -exhaustNoise(p, 8)) * 200.;
    float thickness = (rim + 0.03) * 0.00001;
    
    return vec3(BlackBody(temperature) * thickness);
}


vec3 shadeShip(vec3 p, vec3 rd, vec3 lightDir) {
    float window = windowMat(p);
    float engine = engineMat(p);
    vec3 norm = calcNormal(p);
    float spec_strength = mix(0.6, 0.9, window);
    spec_strength = mix(spec_strength, 0.01, engine);

	float ndotl = dot(norm,lightDir);
    float ao = mix(0.6, 1.0, calcAO(p, norm));
    float shadowAttenuation = softshadow(p + norm * EPS, lightDir, 0.01, 3.0);
    float occ = ao * shadowAttenuation;

    
    // Diffuse
    vec3 albedo = mix(vec3(0.9, 0.1, 0.1), vec3(0.05, 0.05, 0.05), window);
    albedo = mix(albedo, vec3(0.05), engine);
    
	vec3 light = smoothstep(-.1, 1.0, ndotl) * vec3(1.);

	vec3 col = albedo * light * occ;
	
    vec3 exhaust_dir = vec3(0., 0., -1.);
    float ndotexhaust = dot(norm, exhaust_dir);
    light = smoothstep(-.1, 1.0, ndotexhaust) * vec3(1., 0.8, 0.2) * 15.;
    float exhaust_occ = softshadow(p + norm * EPS, exhaust_dir, 0.001, 0.5) + 0.2;
    
	col += albedo * light * exhaust_occ;
    
	// specular
	vec3 h = normalize(lightDir-rd);
	float s = pow(max(0.0,dot(norm,h)),50.0) * spec_strength;
	
	vec3 specular = s*vec3(1.0);


    // Reflections
    // I think these look too sharp on the body of the ship. 
    // Skybox reflection
	vec3 rr = reflect(rd, norm);
    float rr_atten = softshadow(p + norm * EPS, rr, 0.01, 100.0);
	specular += mix(albedo * occ * spec_strength, background(rr, lightDir, spec_strength), rr_atten);
    
    // Exhaust reflection
    float exhaust_d;
    bool rr_exhaust_hit = intersect_exhaust_lq(p, rr, exhaust_d);
    if(rr_exhaust_hit){
        specular += rr_atten * spec_strength * shadeExhaust (p + rr * exhaust_d, rr);
    }
	
	float ndotr = dot(norm,rd);
	float fresnel = pow(1.0-abs(ndotr),5.0) * spec_strength;
	fresnel = mix(spec_strength, 1.0, fresnel );

	col = mix( col, specular, fresnel );
	
	return col;
}




vec3 encodeSRGB(vec3 linearRGB)
{
    vec3 a = 12.92 * linearRGB;
    vec3 b = 1.055 * pow(linearRGB, vec3(1.0 / 2.4)) - 0.055;
    vec3 c = step(vec3(0.0031308), linearRGB);
    return mix(a, b, c);
}


void mainImage( out vec4 fragColor, in vec2 fragCoord )
{

    // camera
    float an = 0.3*iTime;
	vec3  po = vec3(1.0 + 3.5*sin(an),1.0,3.5*cos(an));
    vec3  ta = vec3(0.0,0.0,0.0);

    vec3 ro,  rd;  generateRay( ro,  rd,  po, ta, fragCoord.xy );
    
    vec4 ship_sphere = vec4(vec3(0.), 0.6);
    
    vec3 col = vec3(0.0);

    vec3 star_dir = normalize(vec3(1., 1., 1.));//normalize(vec3(sin(0.5*iTime),2. * sin(0.34253*iTime),cos(0.5*iTime)));

    
    float dist; bool hit;
    float exhaust_dist;
    hit = intersect(ro, rd, dist);
    if(hit){
        vec3 pos = ro + dist * rd;
        col = shadeShip(pos, rd, star_dir);
        hit = intersect_exhaust(ro, rd, exhaust_dist);
        if(hit && exhaust_dist < dist){
            col += shadeExhaust(ro + rd * exhaust_dist, rd);
        }
    } else {
        col = background(rd, star_dir, 1.5) * 0.5;
        hit = intersect_exhaust(ro, rd, exhaust_dist);
        if(hit){
            col += shadeExhaust(ro + rd * exhaust_dist, rd);
        }
    }
    

    col = col * vec3(1., 1., 1.);
    col = encodeSRGB(col);
    // Output to screen
    fragColor = vec4(col, 0.0);
}