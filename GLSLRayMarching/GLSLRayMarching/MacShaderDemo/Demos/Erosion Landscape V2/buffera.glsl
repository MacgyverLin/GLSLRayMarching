//terrain
const vec2 OFF = vec2(.1, 0.3);
const float BLUR_AMT = .1;

const vec2 NRM_EPS = vec2(.1,0.);
const float NRM_SOFT = .002;
const int OCT = 16;




float GetTerrain(vec2 p)
{
    float data = 0.;
    if(iFrame < 5 || IsSpaceDown(iChannel3))
    {
        p/=iResolution.xy;
        p += OFF;
        float s = 2.5;
        float a = .5;
        
        for(int i = 0; i < OCT; i++)
        {
            data += abs(Noise2D((p+vec2(float(i)*7.8936345, float(i)*-13.73467))*s)*a-a/2.)/2.*.7+
            Noise2D((p-17.+vec2(float(i)*7.8936345, float(i)*-13.73467))*s)*a*.3;
            s*= 1.7;
            a*= .5;
        }
       
        data = pow(1.-data, 7.8)*1.8* mix(1., .4, pow(length((p-OFF-.5)*.8), .7))-.08;
    }
    else
    {
        data = texture(iChannel1, p/iResolution.xy).w;
    }
    
    return data;
}

vec3 GetTerrainNrm(vec2 uv)
{ 
    vec3 nrm = vec3(0.);
    nrm.x = -(GetTerrain(uv+NRM_EPS) - GetTerrain(uv-NRM_EPS));
    nrm.y = -(GetTerrain(uv+NRM_EPS.yx) - GetTerrain(uv-NRM_EPS.yx));
    nrm.z = NRM_EPS.x*NRM_SOFT;
    nrm = normalize(nrm);
    
    return nrm;
}

 

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    float f = GetTerrain(fragCoord);
    vec4 data = texture(iChannel2, fragCoord/iResolution.xy);
    f-= mix(.6, 1., Noise2D(fragCoord/iResolution.xy*80.))*iResolution.x*.0000000005*(length(data.xy)-90.)*float(texelFetch(iChannel3, ivec2(50, 2),0).x<=0.);
    

    f = clamp(f,0.,1.);
    fragColor = vec4(GetTerrainNrm(fragCoord),f);
}