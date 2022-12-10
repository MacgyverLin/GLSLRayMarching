// When focused on the shader window, space to reset terrain, One(1) to view terrain and particles, Two(2) to toggle erosion on and off.
//Based on a previous shader of mine, reworked to use reintegration tracking(https://michaelmoroz.github.io/Reintegration-Tracking/) for erosion.

// a quick dof, doesn't quite work on the clouds but it is good enough



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
            col += texelFetch(iChannel0, ivec2(fragCoord)+ivec2(0,x),0).xyz*w;
        }
        col/=tot;
    }
    
    col*=vec3(0.690,0.765,0.812)*.8;
    //col = vec3(focus); 
    if(texelFetch(iChannel3, ivec2(49,2),0).x>0.)col = texture(iChannel1, fragCoord/iResolution.xy).www*.5 +  texture(iChannel2, fragCoord/iResolution.xy).zzz*vec3(100,0,0);
    fragColor = vec4(pow(col, vec3(1./2.2)),1.0);
}