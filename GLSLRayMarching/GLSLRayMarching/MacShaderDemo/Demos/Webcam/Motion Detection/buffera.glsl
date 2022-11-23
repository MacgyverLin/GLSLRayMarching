void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord.xy / iResolution.xy;
    vec4 c_t1 = texture( iChannel0, uv );   
    vec4 c_t0 = texture( iChannel1, uv );
    float value = float(iFrame);
    fragColor = mod(value,2.0) == 0. ?c_t0:c_t1;
}
