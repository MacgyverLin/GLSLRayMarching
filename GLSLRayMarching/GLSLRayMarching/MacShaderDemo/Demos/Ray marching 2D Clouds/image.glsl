const float cloudscale = 0.45;
const float speed = 0.03;
const vec3 skycolour1 = vec3(0.2, 0.4, 0.6);
const vec3 skycolour2 = vec3(0.4, 0.7, 1.0);
const float ambient = 0.15;
const float intensity = 1.25;


const mat2 m = mat2( 1.6,  1.2, -1.2,  1.6 );

vec2 hash( vec2 p ) {
	p = vec2(dot(p,vec2(127.1,311.7)), dot(p,vec2(269.5,183.3)));
	return -1.0 + 2.0*fract(sin(p)*43758.5453123);
}

float noise( in vec2 p ) {
    p = p * cloudscale;
    const float K1 = 0.366025404; // (sqrt(3)-1)/2;
    const float K2 = 0.211324865; // (3-sqrt(3))/6;
	vec2 i = floor(p + (p.x+p.y)*K1);	
    vec2 a = p - i + (i.x+i.y)*K2;
    vec2 o = (a.x>a.y) ? vec2(1.0,0.0) : vec2(0.0,1.0); //vec2 of = 0.5 + 0.5*vec2(sign(a.x-a.y), sign(a.y-a.x));
    vec2 b = a - o + K2;
	vec2 c = a - 1.0 + 2.0*K2;
    vec3 h = max(0.5-vec3(dot(a,a), dot(b,b), dot(c,c) ), 0.0 );
	vec3 n = h*h*h*h*vec3( dot(a,hash(i+0.0)), dot(b,hash(i+o)), dot(c,hash(i+1.0)));
    return dot(n, vec3(70.0));	
}

float fbm(vec2 n) {
	float total = 0.0, amplitude = 0.1;
	for (int i = 0; i < 7; i++) {
		total += noise(n) * amplitude;
		n = m * n;
		amplitude *= 0.4;
	}
	return total;
}

float density(vec2 p, vec2 aspect, vec2 time)
{
    //ridged noise shape
	vec2 uv = p * aspect;
    
    float s1 = 1.0;
    
    float r = 0.0;
	uv *= s1;
    uv -= time;
    float weight = 0.8;
    for (int i=0; i<5; i++){
		r += abs(weight*noise( uv ));
        uv = m*uv + time;
		weight *= 0.7;
    }
    
    //noise shape
    float s2 = 1.2;
    
	float f = 0.0;
    uv = p * aspect;
	uv *= s2;
    uv -= time;
    weight = 0.7;
    for (int i=0; i<8; i++){
		f += weight*noise( uv );
        uv = m*uv + time;
		weight *= 0.6;
    }
    
    f *= r + f * 1.;
    f = clamp(f, 0., 1.);
    f = 1. - (1. - f) * (1. - f);
    return f;
    
}

// -----------------------------------------------

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
   
    vec2 aspect = vec2(iResolution.x/iResolution.y, 1.0);
    
    vec2 p0 = fragCoord.xy / iResolution.xy;
    float q = fbm(p0 * cloudscale * 0.5);
    
     
    float t = (iTime + 45.0) * speed;
    vec2 time = vec2(q + t * 1.0, q + t * 0.25);
	
    vec2 dist = (vec2(16.) / iResolution.xy);
    const int steps = 8;
    float steps_inv = 1.0 / float(steps);
    
    vec2 sun_dir = ((iMouse.xy / iResolution.xy) * 2. - 1.);
    
    vec2 dp = normalize(sun_dir) * dist * steps_inv;
    
    float T = 0.0;
    
    vec2 p = p0;
    float dens0 = density(p, aspect, time);
    float A = dens0;
    
    for(int i = 0; i < steps; ++i)
    {
        float h = float(i) * steps_inv;
        p +=  dp * (1. + h * (hash(p) * 0.75)); // increase step size for each step
        
   		float dens = density(p, aspect, time);
        T += (clamp((dens0 - dens), 0.0, 1.0) + ambient * steps_inv) * (1. - h);
    }
    
    T = clamp(T, 0.0, 1.0);
    
    vec3 skycolour = mix(skycolour2, skycolour1, p0.y);
    
    
    vec3 C = vec3(0.0);
    C = vec3(T) * intensity;
    C = vec3(1.) - (vec3(1.) - C) * (vec3(1.) - skycolour * 0.5);
    
    float A2 = smoothstep(0.2, 1.0, A * A);
    
    
    float sun = 1. - clamp( distance(p0 * vec2(2.) - vec2(1.), sun_dir * 1.2), 0.0, 1.0);
   	vec3 suncolour = vec3(pow(sun, 2.5)) * 0.5;
    
    skycolour += suncolour;
    
    vec3 R =  mix(skycolour, C, A2);
    
    fragColor = vec4( R, 1.0 );
}