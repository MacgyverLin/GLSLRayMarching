void mainImage( out vec4 fragColor, in vec2 fragCoord )
{  
    vec2 uv = (fragCoord) / iResolution.xy;

    vec3 voice = texture(iChannel0, vec2(uv.x*10.0, 0.0)).rgb;
    uv.y += voice.x*0.1;

    vec3 webimage = texture(iChannel1, uv).rgb;

    fragColor.xyz = webimage; // texture(iChannel2, uv).rgb;
}