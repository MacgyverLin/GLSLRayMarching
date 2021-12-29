#include "/savestate.h"

////////////////////////////////////////////////////////////////////////////////////////////
#define imageChannel iChannel0
#define easuChannel iChannel1
#define rcasChannel iChannel2
#define scaledimageChannel iChannel3

////////////////////////////////////////////////////////////////////////////////////////////
vec4 getGroundTruth(in vec2 texcoord)
{
    return texture(imageChannel, texcoord);
}

vec4 getOriginalImage(in vec2 texcoord, in float easuScale)
{
    vec2 newTexcoord = texcoord / easuScale;

    if(newTexcoord.x > 1.0 || newTexcoord.y > 1.0)
        return vec4(0.0, 0.0, 0.0, 1.0);
    else
        return texture(scaledimageChannel, texcoord);
}

vec4 getOriginalImageBilinearSuperSampled(in vec2 texcoord, in float easuScale)
{
    vec2 newTexcoord = texcoord / easuScale;

    return texture(scaledimageChannel, newTexcoord);
}

vec4 getEASUImage(in vec2 texcoord)
{
    return texture(easuChannel, texcoord);
}

vec4 getFSRImage(in vec2 texcoord)
{
    return texture(rcasChannel, texcoord);
}

float getSide(in vec2 fragCoord, bool vertical)
{
    vec2 texcoord = fragCoord / iResolution.xy;
    vec2 normal = vec2(-1.0, 1.0);
    if(vertical)
        normal = vec2(-1.0, 0.0);
    vec2 p0 = iMouse.xy / iResolution.xy;
    
    float side = dot(normal, texcoord - p0);
    return side;
}

/*
void showFSRComparision(out vec4 fragColor, in vec2 fragCoord, in float easuScale, bool showOrginalThumbnail)
{
    vec2 texcoord = fragCoord / iResolution.xy;
    float side = getSide(fragCoord, true);

    float slotSize = 0.4;
    float lineSize = 0.001;

    if(side < -slotSize-lineSize)
        fragColor = getGroundTruth(texcoord);
    else if(side > -slotSize && side < -0.05 - lineSize)
        fragColor = getOriginalImageBilinearSuperSampled(texcoord, easuScale);
    else if(side > -0.05 && side < slotSize - lineSize)
        fragColor = getFSRImage(texcoord);
    else if(side > slotSize)
        fragColor = getGroundTruth(texcoord);
    else
        fragColor = vec4(1.0, 1.0, 1.0, 1.0);


    if(showOrginalThumbnail)
    {
        if(texcoord.x < 1.0/easuScale && texcoord.y < 1.0/easuScale)
            fragColor = getOriginalImage(texcoord, easuScale);

        if((texcoord.x > 1.0/0.5-lineSize && texcoord.y > 1.0/0.5-lineSize) &&  (texcoord.x < 1.0/0.5 && texcoord.y < 1.0/0.5))
            fragColor = vec4(1.0, 1.0, 1.0, 1.0);
    }
}
*/

void showGroundTruth(out vec4 fragColor, in vec2 fragCoord, in float easuScale, bool showOrginalThumbnail)
{
    vec2 texcoord = fragCoord / iResolution.xy;
   
    fragColor = getGroundTruth(texcoord);
}

void showFSR(out vec4 fragColor, in vec2 fragCoord, in float easuScale, bool showOrginalThumbnail)
{
    vec2 texcoord = fragCoord / iResolution.xy;
   
    fragColor = getFSRImage(texcoord);
}

void showMFSR(out vec4 fragColor, in vec2 fragCoord, in float easuScale, bool showOrginalThumbnail)
{
    vec2 texcoord = fragCoord / iResolution.xy;
   
    fragColor = getFSRImage(texcoord);
}

void showBilinearFiltered(out vec4 fragColor, in vec2 fragCoord, in float easuScale, bool showOrginalThumbnail)
{
    vec2 texcoord = fragCoord / iResolution.xy;
   
    fragColor = getOriginalImageBilinearSuperSampled(texcoord, easuScale);
}

void compareAll(out vec4 fragColor, in vec2 fragCoord, in float easuScale, bool showOrginalThumbnail)
{
    vec2 texcoord = fragCoord / iResolution.xy;
    float side = getSide(fragCoord, false);

    float slotSize = 0.8;
    float lineSize = 0.001;

    if(side < -slotSize-lineSize)
        fragColor = getOriginalImage(texcoord, easuScale);
    else if(side > -slotSize && side < 0.0 - lineSize)
        fragColor = getEASUImage(texcoord);
    else if(side > 0.0 && side < slotSize - lineSize)
        fragColor = getFSRImage(texcoord);
    else if(side > slotSize && side < slotSize * 2.0 - lineSize)
        fragColor = getGroundTruth(texcoord);
    else if(side > slotSize * 2.0)
        fragColor = getOriginalImageBilinearSuperSampled(texcoord, easuScale);
    else
        fragColor = vec4(1.0, 1.0, 1.0, 1.0);

    if(showOrginalThumbnail)
    {
        if(texcoord.x < 1.0/easuScale && texcoord.y < 1.0/easuScale)
            fragColor = getOriginalImage(texcoord, easuScale);

        if((texcoord.x > 1.0/0.5-lineSize*10 && texcoord.y > 1.0/0.5-lineSize*10) &&  (texcoord.x < 1.0/0.5 && texcoord.y < 1.0/0.5))
            fragColor = vec4(1.0, 1.0, 1.0, 1.0);
    }
}

void showSSIM(out vec4 fragColor, in vec2 fragCoord, in float easuScale, bool showOrginalThumbnail)
{
    vec2 window_size = vec2(8, 8);

    vec2 texcoord = fragCoord / iResolution.xy;
    vec2 texelOffset = vec2(1.0) / float(iResolution.xy);

    float k1 = 0.01;                    // default SSIM
    float k2 = 0.03;                    // default SSIM
    float L = 1.0;                      // 
    float ux = 0.0;                     // average x
    float uy = 0.0;                     // average y
    float ox = 0.0;                     // var x ^ 2
    float oy = 0.0;                     // var y ^ 2
    float oxy = 0.0;                    // covar x y
    float c1 = (k1 * L) * (k1 * L);     // c1
    float c2 = (k2 * L) * (k2 * L);     // c2
    float c3 = c2 / 2;                  // c3
    for(int j=0; j<window_size.y; j++)
    {
        for(int i=0; i<window_size.x; i++)
        {
            vec2 uv = texcoord + vec2(texelOffset.x * i, texelOffset.y * j);
            vec4 fragColor1 = getGroundTruth(uv);
            vec4 fragColor2 = getFSRImage(uv);
            ux += fragColor1.r * 0.3 + fragColor1.g * 0.5 + fragColor1.b * 0.1;
            uy += fragColor2.r * 0.3 + fragColor2.g * 0.5 + fragColor2.b * 0.1;
        }
    }
    ux /= (window_size.x * window_size.y);
    uy /= (window_size.x * window_size.y);
    float l = (2 * ux * uy + c1) / (ux * ux + uy * uy + c1);    // luma
    float c = (2 * ox * oy + c2) / (ox * ox + oy * oy + c1);    // contrast
    float s = (oxy + c3) / (ox + oy + c3);                      // structure
    
    float alpha = 1.0;
    float beta = 1.0;
    float gamma = 1.0;
    float ssim = l;
    ssim = 1.0 - (ssim-0.999)/0.001;

    fragColor = vec4(ssim, ssim, ssim, 1.0);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
	AppState s;
	InitializeState(s);

    if(s.displayMode			        == GFMB_GROUND_TRUTH)
        showGroundTruth(fragColor, fragCoord, s.easuScale, s.showOrginalThumbnail);
    else if(s.displayMode			== GFMB_FSR)
        showFSR(fragColor, fragCoord, s.easuScale, s.showOrginalThumbnail);
    else if(s.displayMode			== GFMB_MFSR)
        showMFSR(fragColor, fragCoord, s.easuScale, s.showOrginalThumbnail);
    else if(s.displayMode			== GFMB_BILINEAR)
        showBilinearFiltered(fragColor, fragCoord, s.easuScale, s.showOrginalThumbnail);
    else if(s.displayMode			== GFMB_SSIM)
        compareAll(fragColor, fragCoord, s.easuScale, s.showOrginalThumbnail);
    else if(s.displayMode			== GFMB_COMPARE_ALL)
        showSSIM(fragColor, fragCoord, s.easuScale, s.showOrginalThumbnail);
}