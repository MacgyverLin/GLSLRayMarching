// All Cyclic noise from nimitz
// PBR atmospheric scattering from Sebastian Lague video tutorial on youtube


void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = (fragCoord - 0.5*iResolution.xy)/iResolution.y;

    vec3 col = vec3(0);

    col = texture(iChannel0,fragCoord/iResolution.xy).xyz;
    
    col *= vec3(0.96,0.9,1.07);
    col *= exposure; 
    
    col = pow(col,vec3(1.03,0.98,1.05));
    col = mix(acesFilm(col), col, 0.);
    col = mix(col,smoothstep(0.,1.,col*vec3(1.0,1.02,1.08)),0.6);
    
    col *= 1. - dot(uv,uv*0.4)*1.5;
    
    col = pow(col,vec3(0.454545));
    
    fragColor = vec4(col,1.0);
}
