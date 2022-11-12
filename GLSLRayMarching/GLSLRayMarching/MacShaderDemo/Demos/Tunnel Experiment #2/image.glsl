
#define T(uv) texture(iChannel0,uv)

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = (fragCoord/iResolution.xy);

    //some sort of adhoch antialiasing based on
    //an anisotrpic effect by:ulianlumia
    //unstable universe - https://www.shadertoy.com/view/wtlfz8
    //fragColor = texelFetch(iChannel0, ivec2(fragCoord),0);
    fragColor = vec4(0.);
    float f = length(uv  - 0.6);
    float SHIFT = sin(iTime)*0.002;
    fragColor.x += T(uv + f*SHIFT).x;
    fragColor.y += T(uv -f*SHIFT/2.).y;
    fragColor.z += T(uv-f*SHIFT).z;
    fragColor.xyz *= 1.5;
}