
// Cyclic noise from nimitz
// PBR atmospheric scattering from Sebastian Lague video tutorial on youtube
// value noise from shane
// triplanar blending from Shane, who got it from Ryan Geiss
// smooth ops & sdfs from IQ


void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = (fragCoord - 0.5*iResolution.xy)/iResolution.y;

    vec3 col = vec3(0);

    col = texture(iChannel0,fragCoord/iResolution.xy).xyz;
    
    col *= vec3(0.9,0.8,0.96);
    col *= exposure;
    
    col = mix(col,smoothstep(0.,1.,col*vec3(1.,1.,1.)),0.9);
    col = mix(acesFilm(col), col, 0.);
    col *= 1. - dot(uv,uv*0.4)*2.1;
    
    col = pow(col,vec3(0.454545));
    
    fragColor = vec4(col,1.0);
}
