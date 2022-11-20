// Created by SHAU - 2019
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

/*
    Still playing with concepts from Peter Shirley ray tracing in one weekend
    https://github.com/petershirley/raytracinginoneweekend
    This one is more of a ray tracer than a path tracer

    Some nice examples

    Reinder
    https://www.shadertoy.com/view/MtycDD
    https://www.shadertoy.com/view/XlycWh

    IQ
    https://www.shadertoy.com/view/MsdGzl
    https://www.shadertoy.com/view/Xtt3Wn
    https://www.shadertoy.com/view/Xd2fzR

    I like the reprojection technique of the latter but it didn't seem work
    too well with moving balls (for me). I need to research this more as it seems the demo
    also took this approach

      
    Reflecting balls by dr2
    https://www.shadertoy.com/view/Xsy3WR

    Ben-Hur balls. One of my favourites again from dr2
    https://www.shadertoy.com/view/MsVfRW

    A fun mashup by iapafoto
    https://www.shadertoy.com/view/XdGGWz
*/

#define R iResolution.xy
#define T mod(iTime, DURATION)

void mainImage(out vec4 C, vec2 U) {

    vec4 buf = texture(iChannel0, U/R);    
    vec3 pc = buf.xyz;
    
    //IQ
    pc = pow(pc, vec3(0.4545));
    pc = pow(pc, vec3(0.8,0.85,0.9));
    
    //gamma correction
    pc = pow(pc, vec3(1.0/1.6));

    C = vec4(pc, 1.0);
}