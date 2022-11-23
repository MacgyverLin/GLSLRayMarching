// Edited Shader by Nshuti Jean-Ren¨¦ (04/05/2021) based on the 
// Yellow Manypus created by Pol Jeremias - pol/2015
// and combine a an oscillating red disk from the Motion Blur Visualization at
// https://www.shadertoy.com/view/XdXXz4
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
//
#define SOUND_MULTIPLIER 1.0

//(Nshuti) changed function from sinus to cosinus
float cos01(float v){ return 0.5 + 0.5 * cos(v); }

//(Nshuti) disk function
vec4 disk(vec2 uv, vec2 center, float radius, vec4 color) {
    float dist = step(length(center - uv), radius);
    return vec4(dist, dist, dist, 1.0)*color * cos01(1.2 * iTime );
}

//(Nshuti) Added functions circle & scene from 
//shader : Motion Blur Visualization
//@https://www.shadertoy.com/view/XdXXz4
vec4 circle(vec2 p, vec2 center, float radius)
{
	return mix(vec4(1,1,1,0), vec4(1,0,0,1), smoothstep(radius + 0.005, radius - 0.005, length(p - center)));
}

vec4 scene(vec2 uv, float t, float rayon)
{
	return circle(uv, vec2(0, sin(t * 16.0) * (sin(t) * 0.5 + 0.5) * 0.5), rayon);
}

//(Nshuti) plot function used to"blackout" shader
float plot(vec2 coord, float y, float thickness){
    return smoothstep( y-thickness, y, coord.y) - smoothstep( y, y+thickness,
    coord.y);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    //(Nshuti) Create greyscale function to black out
    //the manypus
    vec2 xy = fragCoord.xy/iResolution.xy;
    xy -= abs(sin(iTime)/2.0);
    vec2 center = iResolution.xy * 0.5;
    float radius = 0.25 * iResolution.y;
    float y = cos01(xy.x)/15.0+0.1;
    float greyScale = plot( xy, y, 4.0);
    
	vec2 uv = fragCoord.xy / iResolution.xy;
    uv -= vec2(0.5);
	uv.x *= iResolution.x / iResolution.y;
    
    //(Nshuti) create oscillating red disk copied from Motion Blur Visualization
    float view = floor(fragCoord.x / iResolution.x);
    float frametime = (60. / (floor(view / 2.) + 1.));
	float time = floor((iTime + 3.) * frametime) / frametime * texture(iChannel0, vec2(0.1, 0.0) ).x;
	vec4 mainCol = scene(uv, time,0.1);
   
    float a = atan( uv.y, uv.x );
    float r = length( uv );
    
    //
    // Draw the white eye
    //
    //(Nshuti) Changed reactBase to depend on y-axis to have a fixed circular white eye
    float reactBase = SOUND_MULTIPLIER * texture(iChannel0, vec2(0.1, 0.0) ).y;
    float nr = r + reactBase * 0.06 * cos01(a * 0.2 +iTime);
    float c = 1.0 - smoothstep(0.04, 0.07, nr);
	
    //
    // Draw the manypus
    //
    uv = (fragCoord.xy / iResolution.xy) * 2.0 - 1.0;

    const float it = 10.0;
    float c1 = 0.0;
    for( float i = 0.0 ; i < it ; i += 1.0 )
    {
        float i01 = i / it;
        float rnd = texture( iChannel1, vec2(i01)).x;
        float react = SOUND_MULTIPLIER * texture(iChannel0, vec2(i01, 0.0) ).x;
        
        float a = rnd * 3.1415;
        uv = uv * mat2( cos(a), -sin(a), sin(a), cos(a) );
        
        // Calculate the line
        float t= 0.3 * abs(1.0 / sin( uv.x * 3.1415 + sin(uv.y * 30.0 * rnd +iTime) * 0.13)) - 1.0;
        
        // Kill repetition in the x axis
        t *= 1.0 - smoothstep(0.3, 0.53, abs(uv.x));
        
        // Kill part of the y axis so it looks like a line with a beginning and end
        float base = 0.1 + react;
        rnd *= 0.2;
        t *= 1.0 - smoothstep(base + rnd, base + 0.3 + rnd, abs(uv.y));
        
        c1 += t;
        // (Nshuti) modulate radius of disk inversely by t to add fractured effect
        radius /= t;
    }
    
    //
    // Calculat the final color
    //
    c1 = clamp(c1, 0.0, 1.0);
    //vec3 col = mix(vec3(0.5,0.85,0.0), vec3(0.0), c1 - c);
    //(Nshuti) Mix greyscale function and changed colour of vec3 from yellow to lime green (no longer
    //visible due to greyscale function -> result purple red-ish colour 
    vec3 col = mix(vec3(0.5,0.85,0.0), vec3(0.0), c1 - c + greyScale);
    col += c;
    // (Nshuti) Add oscillating red disk (mainCol) and fragmented disk
    fragColor = vec4( col, 1.0) +  disk(fragCoord.xy, center, radius, vec4(1.0, 0.0, 0.0, 1.0)+ mainCol) ;

    
}