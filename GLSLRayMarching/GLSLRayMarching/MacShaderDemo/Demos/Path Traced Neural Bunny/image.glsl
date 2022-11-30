//CC0 1.0 Universal https://creativecommons.org/publicdomain/zero/1.0/
//To the extent possible under law, Blackle Mori has waived all copyright and related or neighboring rights to this work.

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec4 col = texture(iChannel0, fragCoord/iResolution.xy); 
    fragColor = tanh(2.5*col/col.w);
}