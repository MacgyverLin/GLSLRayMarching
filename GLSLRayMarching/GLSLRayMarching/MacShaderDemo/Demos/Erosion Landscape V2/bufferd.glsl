void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    
    vec3 col = vec3(0.);
    vec4 data = texelFetch(iChannel0, ivec2(fragCoord),0);
    if(data.w >=FAR)
    {
        col = data.xyz;
    }
    else
    {
        //col = data.xyz;
        float focus = abs(data.w-FOCUS_DIST)/FAR*BLUR_MUL;
        float tot = 0.;
        int blur_size = int(focus+1.)*2;
        for(int x = -blur_size; x < blur_size; x++)
        {

            float w = Gaussian(float(x), 1., 0., focus);
            tot+=w;
            col += texelFetch(iChannel0, ivec2(fragCoord)+ivec2(x,0),0).xyz*w;
        }
        col/=tot;
    }

    fragColor = vec4(col,data.w);
}