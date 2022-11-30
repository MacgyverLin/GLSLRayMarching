// created by florian berger (flockaroo) - 2022
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

// path traced lamborghini countach made of glass

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec4 c0=textureLod(iChannel0,fragCoord/iResolution.xy,0.);
    vec4 c=textureLod(iChannel0,fragCoord/iResolution.xy,max(1.7-1.7*(1.-exp2(-c0.w/12.)),0.));
    fragColor=c/c0.w;
}

