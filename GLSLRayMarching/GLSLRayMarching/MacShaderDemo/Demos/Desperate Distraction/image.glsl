#define R iResolution
#define F gl_FragCoord
#define T iTime
#define PI 3.1415

#define DBG vec3(1.0, 0.0, 0.0)
#define BG  vec3(0.2)
#define PH0 vec3(0.0)
#define PH1 vec3(0.1)
#define FB0 vec3(0.6)
#define FB1 vec3(0.25, 0.25, 0.5)
#define FB2 vec3(0.7, 0.7, 0.9)
#define FB3 vec3(0.2)
#define FB4 vec3(1.0)
#define FB5 vec3(0.75)

#define ROUND0 0.01
#define ROUND1 0.004

float sdBox2( vec2 p, vec2 b )
{
  vec2 d = abs(p) - b;
  return min(max(d.x,d.y),0.0) + length(max(d,0.0));
}

mat2 rot(float a)
{ 
    float s = sin(a);
    float c = cos(a);
    return mat2( c, -s , s, c);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 q = F.xy/R.xy;
	vec2 p = 2.0*(q-0.5);
    p.x *= R.x/R.y;
    
    float bounce = sin(fract(2.0*0.35*T-0.5)*2.0*PI);
    float rotAnim = 2.0*(-0.5+ smoothstep(-0.6, 0.6, bounce) );
    mat2 r = rot(0.25*0.0174*rotAnim);
    p *= r;
    
    float yAnim = 0.5+0.5*cos(fract(2.0*0.35*T-0.5)*2.0*PI); // synced with feed scroll anim
    vec3 tiltTex = texture(iChannel0, vec3(0.0, 0.0, 0.125*0.35*T)).rgb;
    vec2 tiltAnim = vec2(0.1, 0.1) * (2.0*(smoothstep(0.0, 2.0, tiltTex.xy)-0.5));
    tiltAnim.y += 0.2*yAnim;    
    p *= mix( 0.95, 1.0, tiltTex.b);
    p += tiltAnim;
        
    float s0 = abs(p.x) - 0.9; // phone body
    float s01 = sdBox2(p +vec2(0.0, -0.95), vec2(0.2, 0.005)); // phone body speaker
    float s10 = sdBox2(p +vec2(0.0, 0.1), vec2(0.8, 0.9)); // phone top bar
    float s11 = sdBox2(p +vec2(-0.74, -0.72), vec2(0.01, 0.005)); // phone top bar battery
    float s12 = sdBox2(p +vec2(-0.69, -0.72), vec2(0.04, 0.02)); // phone top bar battery
    float s13 = sdBox2(p +vec2(-0.70, -0.72), vec2(0.035, 0.025)); // phone top bar battery
    float s14 = sdBox2(p +vec2( 0.75, -0.700), vec2(0.002, 0.005)); // phone top bar signal
    float s15 = sdBox2(p +vec2( 0.72, -0.710), vec2(0.002, 0.015)); // phone top bar signal
    float s16 = sdBox2(p +vec2( 0.69, -0.720), vec2(0.002, 0.025)); // phone top bar signal
    float s17 = sdBox2(p +vec2( 0.66, -0.728), vec2(0.002, 0.035)); // phone top bar signal
    
    float s2 = sdBox2(p +vec2(0.0, 0.25), vec2(0.8, 0.9)); // app body bg
    float s3 = sdBox2(p -vec2(0.0, 0.55), vec2(0.8, 0.11)); // app top bar
    
    float s40 = sdBox2(p +vec2(-0.68, -0.55), vec2(0.07)); // app top bar icon placeholder
    float s41 = max(  sdBox2(p +vec2( 0.69, -0.57), vec2(0.06)), // app top bar icon placeholder    
                      texture(iChannel1, p*0.35 - vec2(0.36, 0.60)).x );
    float s42 = sdBox2(p +vec2(-0.3, -0.55), vec2(0.07)); // app top bar icon placeholder
    float s43 = sdBox2(p +vec2( 0.0, -0.55), vec2(0.07)); // app top bar icon placeholder    
    float s44 = sdBox2(p +vec2( 0.3, -0.55), vec2(0.07)); // app top bar icon placeholder
    
    float s50 = sdBox2(p  -vec2(0.0, 0.3), vec2(0.8, 0.13)); // app lower bar placeholder
    float s51 = sdBox2(p +vec2( 0.0, -0.16), vec2(0.80, 0.0001)); // app lower bar separator line
    float s52 = sdBox2(p +vec2( 0.27, -0.3), vec2(0.0001, 0.132)); // app lower bar button separator line
    float s53 = sdBox2(p +vec2(-0.27, -0.3), vec2(0.0001, 0.132)); // app lower bar button separator line
    float s54 = sdBox2(p +vec2(-0.39, -0.3), vec2(0.07, 0.05)); // app lower bar button
    float s55 = sdBox2(p +vec2( 0.15, -0.3), vec2(0.07, 0.05)); // app lower bar button
    float s56 = sdBox2(p +vec2( 0.67, -0.3), vec2(0.07, 0.05)); // app lower bar button
        
    vec2 animP = p + vec2(0.0, -0.2 + smoothstep(0.5, 1.0, fract(2.0*0.35*T)) + floor(2.0*0.35*T) );
    animP.y = fract(animP.y)-0.5;
    
    float s60 = sdBox2(animP +vec2(0.0, 0.1), vec2(0.75, 0.5)); // app post top placeholder
    float s61 = sdBox2(animP +vec2(0.0, -0.14) +vec2( 0.0,   0.47), vec2(0.75 +2.0*ROUND0, 0.001)); // app post separator line
    float s62 = sdBox2(animP +vec2(0.0, -0.14) +vec2( 0.5,  -0.02), vec2(0.2, 0.2)); // app post top avatar
    float s63 = sdBox2(animP +vec2(0.0, -0.14) +vec2(-0.23, -0.12), vec2(0.42, 0.03)); // app post top name
    float s64 = sdBox2(animP +vec2(0.0, -0.14) +vec2(-0.16, -0.02), vec2(0.35, 0.02)); // app post top timestamp
    float s65 = sdBox2(animP +vec2(0.0, -0.14) +vec2( 0.1,   0.27), vec2(0.6, 0.02)); // app post text
    float s66 = sdBox2(animP +vec2(0.0, -0.14) +vec2( 0.14,  0.37), vec2(0.56, 0.02)); // app post text
    
    float s7 = sdBox2(animP +vec2(0.0, 0.0), vec2(0.1, 0.1)); // anim test
    
    float fadeAnim0 = smoothstep(-0.5, 0.5, sin(5.0*(p.x + 0.5)  + 3.0*T));
    float fadeAnim1 = smoothstep(-0.5, 0.5, sin(5.0*(p.x + 0.23) + 3.0*T));
    float fadeAnim2 = smoothstep(-0.5, 0.5, sin(5.0*(p.x + 0.1)  + 3.0*T));
    
    vec3 c = mix(PH0, BG, smoothstep(0.0, 0.01, s0 ));
      
    c = mix(PH1, c, smoothstep(0.0, 0.01, s01 ));
    c = mix(PH1, c, smoothstep(0.0, 0.01, s10 ));    
    c = mix(FB0, c, smoothstep(0.0, 0.01, s2 ));
    
    c = mix(FB4, c, smoothstep(0.0, 0.01, max(s2, s60 -ROUND0) ));
    c = mix(FB0, c, smoothstep(0.0, 0.01, max(s2, s61) ));
    c = mix(mix(FB0, FB5, fadeAnim0), c, smoothstep(0.0, 0.01, max(s2, s62 -ROUND0) ));
    c = mix(mix(FB0, FB5, fadeAnim1), c, smoothstep(0.0, 0.01, max(s2, s64) ));
    c = mix(mix(FB0, FB5, fadeAnim2), c, smoothstep(0.0, 0.01, max(s2, min( min(s63, s65), s66) ) ));
    // c = mix(DBG, c, smoothstep(0.0, 0.01, s7 ));

    c = mix(FB1, c, smoothstep(0.0, 0.01, s3 ));    
    c = mix(FB2, c, smoothstep(0.0, 0.01, s41 -ROUND0 ));
    c = mix(FB3, c, 0.5+0.5*smoothstep(0.0, 0.01, min( min(s42, s43), s44) -ROUND0 ));    
    c = mix(FB4, c, smoothstep(0.0, 0.01, s50 ));
    
    c = mix(FB0, c, smoothstep(0.0, 0.01, min( min( s51, s52 ), s53) ));
    c = mix(FB0, c, smoothstep(0.0, 0.01, min( min( s54, s55 ), s56) -ROUND0 ));
    
    c = mix(FB0, c, smoothstep(0.0, 0.01, max( -s13 +ROUND1, min(s11 -ROUND1, s12 -ROUND1)) ));
    float signalAnim = smoothstep(0.3, 0.31, fract(0.35*T));
    c = mix(FB3, c, smoothstep(0.0, 0.01, min( min(s15, s16), s17) -ROUND1 ));
    c = mix(mix(FB0, FB3, vec3(signalAnim) ), c, smoothstep(0.0, 0.01, s14 -ROUND1 ));    
    
    float glowTex = texture(iChannel0, vec3(0.05*p, 2.0*T)).r;
    float glowAnim = mix(0.9, 1.0, glowTex);
    c += 0.1*smoothstep(1.0, 0.0, s2) * glowAnim; // display glow
    
    c = smoothstep(0.1*glowAnim, 1.0, c);
    c *= 0.25 + 0.75*pow( 16.0*q.x*q.y*(1.0-q.x)*(1.0-q.y), 0.15 );    
    
    float grainTex = texture(iChannel0, vec3(20.0*q, T)).r;
    c *= mix(0.92, 1.0, grainTex);
    
    c = pow(c, vec3(0.4545));
    
    fragColor = vec4(c, 1.0);
}