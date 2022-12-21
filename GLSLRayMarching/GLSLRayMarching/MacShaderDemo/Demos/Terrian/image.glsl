// Created by evilryu
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

// A practice of terrian
// Inspired by:
// iq's Rainforest: https://www.shadertoy.com/view/4ttSWf
// Shane's Dry Rocky Gorge: https://www.shadertoy.com/view/lslfRN


void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 p = fragCoord/iResolution.xy;

    vec3 col=texture(iChannel0, p ).xyz;    
    col*=0.5 + 0.5*pow( 16.0*p.x*p.y*(1.0-p.x)*(1.0-p.y), 0.05 );
         
    fragColor = vec4( col, 1.0 );
}
