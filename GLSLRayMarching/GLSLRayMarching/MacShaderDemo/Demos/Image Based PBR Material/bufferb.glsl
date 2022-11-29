// Buffer B : Material Roughness map
//
// Author : SÃ©bastien BÃ©rubÃ©
//
// This is just noise, you could implement whatever roughness map you want.
// This needs some clean-up, as it was originally coded as 3D noise, but only a 2D slice is used here.

#define saturate(x) clamp(x,0.0,1.0)
float UTIL_distanceToLineSeg(vec2 p, vec2 a, vec2 b)
{
    //Scalar projection of ap in the ab direction = dot(ap,ab)/|ab| : Amount of ap aligned towards ab
    //Divided by |ab| again, it becomes normalized along ab length : dot(ap,ab)/(|ab||ab|) = dot(ap,ab)/dot(ab,ab)
    //The clamp provides the line seg limits. e is therefore the "capped orthogogal projection".
    //       p
    //      /
    //     /
    //    a--e-------b
    vec2 ap = p-a;
    vec2 ab = b-a;
    vec2 e = a+clamp(dot(ap,ab)/dot(ab,ab),0.0,1.0)*ab;
    return length(p-e);
}
vec2 noise(vec2 p)
{
    return texture(iChannel1,p,-100.0).xy;
}
struct repeatInfo
{
	vec2 pRepeated;
    vec2 anchor;
};
repeatInfo UTIL_repeat(vec2 p, float interval)
{
    repeatInfo rInfo;
    rInfo.pRepeated = p / interval; //Normalize
    rInfo.pRepeated = fract(rInfo.pRepeated+0.5)-0.5; //centered fract
    rInfo.pRepeated *= interval; //Rescale
    rInfo.anchor = p-rInfo.pRepeated;
    return rInfo;
}
float MAT_scratchTexture(vec2 p)
{
    const float squareWidth = 0.10*2.0;
    const float moveAmp   = squareWidth*0.75;
    const float lineWidth = 0.0005;
    float repeatInterval = squareWidth+moveAmp;
    repeatInfo rInfo = UTIL_repeat(p,repeatInterval);
    float margin = repeatInterval-squareWidth;
    
    vec2 a = moveAmp*noise(rInfo.anchor);
    vec2 b = -moveAmp*noise(rInfo.anchor+10.0);
    float dseg = 1000.0*UTIL_distanceToLineSeg(rInfo.pRepeated, a, b)/squareWidth;
    return saturate(10.0/dseg-0.5)*0.25;
}

float MAT_layeredScratches(vec2 p)
{
    const mat2 m2 = mat2(0.8,-0.6,0.6,0.8);
    float I = MAT_scratchTexture(p);
    p = m2*p;
    I += MAT_scratchTexture(p*1.11+2.0);
    p = m2*p;
    I += MAT_scratchTexture(p*1.24+3.8);
    p = m2*p;
    I += MAT_scratchTexture(p*1.34+5.3);
    p = m2*p;
    I += MAT_scratchTexture(p*1.34+5.3);
    p = m2*p;
    I += MAT_scratchTexture(p*1.34+5.3);
        
    return I;
}

float MAT_triplanarScratches(vec3 p, vec3 n)
{
    //Idea from http://http.developer.nvidia.com/GPUGems3/gpugems3_ch01.html
    //Figure 1-23 Triplanar Texturing
    float fTotal = abs(n.x)+abs(n.y)+abs(n.z);
    return ( abs(n.x)*MAT_layeredScratches(p.zy)
            +abs(n.y)*MAT_layeredScratches(p.xz)
            +abs(n.z)*MAT_layeredScratches(p.xy))/fTotal;
}

vec4 NOISE_trilinearWithDerivative(vec3 p)
{
    //Trilinear extension over noise derivative from (Elevated), & using the noise stacking trick from (Clouds).
	//Inspiration & Idea from :
    //https://www.shadertoy.com/view/MdX3Rr (Elevated)
    //https://www.shadertoy.com/view/XslGRr (Clouds)
    
    //For more information, see also:
    //NoiseVolumeExplained : https://www.shadertoy.com/view/XsyGWz
	//2DSignalDerivativeViewer : https://www.shadertoy.com/view/ldGGDR
    
    const float TEXTURE_RES = 256.0; //Noise texture resolution
    vec3 pixCoord = floor(p);//Pixel coord, integer [0,1,2,3...256...]
    //noise volume stacking trick : g layer = r layer shifted by (37x17 pixels)
    //(37x17)-> this value is the actual translation embedded in the noise texture, can't get around it.
	//Note : shift is different from g to b layer (but it also works)
    vec2 layer_translation = -pixCoord.z*vec2(37.0,17.0)/TEXTURE_RES; 
    
    vec2 c1 = texture(iChannel2,layer_translation+(pixCoord.xy+vec2(0,0)+0.5)/TEXTURE_RES,-100.0).rg;
    vec2 c2 = texture(iChannel2,layer_translation+(pixCoord.xy+vec2(1,0)+0.5)/TEXTURE_RES,-100.0).rg; //+x
    vec2 c3 = texture(iChannel2,layer_translation+(pixCoord.xy+vec2(0,1)+0.5)/TEXTURE_RES,-100.0).rg; //+z
    vec2 c4 = texture(iChannel2,layer_translation+(pixCoord.xy+vec2(1,1)+0.5)/TEXTURE_RES,-100.0).rg; //+x+z
    
    vec3 x = p-pixCoord; //Pixel interpolation position, linear range [0-1] (fractional part)
    
    vec3 x2 = x*x;
    vec3 t = (6.*x2-15.0*x+10.)*x*x2; //Quintic ease-in/ease-out function.
    vec3 d_xyz = (30.*x2-60.*x+30.)*x2; //dt/dx : Ease-in ease-out derivative.
    
    //Lower quad corners
    float a = c1.x; //(x+0,y+0,z+0)
    float b = c2.x; //(x+1,y+0,z+0)
    float c = c3.x; //(x+0,y+1,z+0)
    float d = c4.x; //(x+1,y+1,z+0)
    
    //Upper quad corners
    float e = c1.y; //(x+0,y+0,z+1)
    float f = c2.y; //(x+1,y+0,z+1)
    float g = c3.y; //(x+0,y+1,z+1)
    float h = c4.y; //(x+1,y+1,z+1)
    
    //Trilinear noise interpolation : (1-t)*v1+(t)*v2, repeated along the 3 axis of the interpolation cube.
    float za = ((a+(b-a)*t.x)*(1.-t.y)
               +(c+(d-c)*t.x)*(   t.y));
    float zb = ((e+(f-e)*t.x)*(1.-t.y)
               +(g+(h-g)*t.x)*(   t.y));
    float value = (1.-t.z)*za+t.z*zb;
    
    //Derivative scaling (texture lookup slope, along interpolation cross sections).
    //This could be factorized/optimized but I fear it would make it cryptic.
    float sx =  ((b-a)+t.y*(a-b-c+d))*(1.-t.z)
               +((f-e)+t.y*(e-f-g+h))*(   t.z);
    float sy =  ((c-a)+t.x*(a-b-c+d))*(1.-t.z)
               +((g-e)+t.x*(e-f-g+h))*(   t.z);
    float sz =  zb-za;
    
    return vec4(value,d_xyz*vec3(sx,sy,sz));
}

float ROUGHNESS_MAP_UV_SCALE = 6.00;//Valid range : [0.1-100.0]

//Stacked perlin noise
vec3 NOISE_volumetricRoughnessMap(vec3 p, float rayLen)
{
    vec4 sliderVal = vec4(0.5,0.85,0,0.5);
    ROUGHNESS_MAP_UV_SCALE *= 0.1*pow(10.,2.0*sliderVal[0]);
    
    float f = iTime;
    const mat3 R1  = mat3(0.500, 0.000, -.866,
	                     0.000, 1.000, 0.000,
                          .866, 0.000, 0.500);
    const mat3 R2  = mat3(1.000, 0.000, 0.000,
	                      0.000, 0.500, -.866,
                          0.000,  .866, 0.500);
    const mat3 R = R1*R2;
    p *= ROUGHNESS_MAP_UV_SCALE;
    p = R1*p;
    vec4 v1 = NOISE_trilinearWithDerivative(p);
    p = R1*p*2.021;
    vec4 v2 = NOISE_trilinearWithDerivative(p);
    p = R1*p*2.021+1.204*v1.xyz;
    vec4 v3 = NOISE_trilinearWithDerivative(p);
    p = R1*p*2.021+0.704*v2.xyz;
    vec4 v4 = NOISE_trilinearWithDerivative(p);
    
    return (v1
	      +0.5*(v2+0.25)
	      +0.4*(v3+0.25)
	      +0.6*(v4+0.25)).yzw;
}

void processSliders(in vec2 fragCoord)
{
    vec4 sliderVal = texture(iChannel0,vec2(0,0));
	ROUGHNESS_MAP_UV_SCALE *= 0.1*pow(10.,2.0*sliderVal[0]);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    processSliders(fragCoord);
    vec2 uv = 3.0*fragCoord.xy/iResolution.xy;
    vec3 roughnessNoise = NOISE_volumetricRoughnessMap(vec3(2.0*uv,0),1.0).rgb;
    float scratchTex = MAT_scratchTexture(2.0*uv);
    scratchTex += MAT_layeredScratches(uv+0.25);
    scratchTex += MAT_layeredScratches(1.7*uv+vec2(0.35));
    scratchTex += MAT_scratchTexture(uv+vec2(1.15));
    scratchTex += MAT_scratchTexture(uv+vec2(2.75));
    fragColor = vec4(roughnessNoise,scratchTex*0.3);
}