void mainImage(out vec4 fragColor, in vec2 fragCoord){


    // The other buffer has a maximum Y-resolution of 540 set, which 
    // means any pixels outside that are not rendered. On a 1980x1080
    // fullscreen resolution, this means roughly a quarter of the pixels
    // are rendered, which is a huge saving. Of course, this also means
    // that the scene needs to be upscaled, which will make things less
    // crisp, but you can't have everything. :)
    //
    // By the way, this tip came from Shadertoy user, spalmer, who has
    // a heap of interesting work for anyone interested:
    // https://www.shadertoy.com/user/spalmer
    //
    float maxRes = 540.;
    vec2 uv = fragCoord/iResolution.xy;
    // If the resolution exceeds the maximum, upscale.
    if(iResolution.y>maxRes) uv = (fragCoord/iResolution.xy - .5)*maxRes/iResolution.y + .5;
    
    // Retrieving the stored color.
    vec4 col = texture(iChannel0, uv);

    // Rough gamma correction and screen presentation.
    fragColor = pow(col, vec4(1./2.2));
    
}