// Copyright Inigo Quilez, 2017 - https://iquilezles.org/
// I am the sole copyright owner of this Work.
// You cannot host, display, distribute or share this Work neither
// as it is or altered, here on Shadertoy or anywhere else, in any
// form including physical and digital. You cannot use this Work in any
// commercial or non-commercial product, website or project. You cannot
// sell this Work and you cannot mint an NFTs of it or train a neural
// network with it without permission. I share this Work for educational
// purposes, and you can link to it, through an URL, proper attribution
// and unmodified screenshot, as part of your educational material. If
// these conditions are too restrictive please contact me and we'll
// definitely work it out.

// You can buy a metal print of this shader here:
// https://www.redbubble.com/i/metal-print/Ladybug-by-InigoQuilez/39845563.0JXQP

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 q = fragCoord / iResolution.xy;
    
    
    // dof
    const float focus = 2.35;

    vec4 acc = vec4(0.0);
    const int N = 12;
	for( int j=-N; j<=N; j++ )
    for( int i=-N; i<=N; i++ )
    {
        vec2 off = vec2(float(i),float(j));
        
        vec4 tmp = texture( iChannel0, q + off/vec2(800.0,450.0) ); 
        
        float depth = tmp.w;
        
        vec3  color = tmp.xyz;
        
        float coc = 0.05 + 12.0*abs(depth-focus)/depth;
        
        if( dot(off,off) < (coc*coc) )
        {
            float w = 1.0/(coc*coc); 
            acc += vec4(color*w,w);
        }
    }
    
    vec3 col = acc.xyz / acc.w;

    
    // gamma
    col = pow( col, vec3(0.4545) );
    
    // color correct - it seems my laptop has a fucked up contrast/gamma seeting, so I need
    //                 to do this for the picture to look okey in all computers but mine...
    col = col*1.1 - 0.06;
    
    // vignetting
    col *= 0.8 + 0.3*sqrt( 16.0*q.x*q.y*(1.0-q.x)*(1.0-q.y) );

    fragColor = vec4(col,1.0);
}