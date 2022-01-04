#define A_GPU 1
#define A_GLSL 1
#include "/ffx_a.h"

#define FSR_EASU_F 1
AU4 con0, con1, con2, con3;

AF4 FsrEasuRF(AF2 p) { return textureGather(iChannel0, p, 0); }
AF4 FsrEasuGF(AF2 p) { return textureGather(iChannel0, p, 1); }
AF4 FsrEasuBF(AF2 p) { return textureGather(iChannel0, p, 2); }

#include "/ffx_fsr1.h"

void computeSize(out vec2 vTexCoord, out vec2 sourceSize, out vec2 outputSize, in vec2 fragCoord)
{
    // Normalized pixel coordinates (from 0 to 1)
    vTexCoord  = fragCoord / iResolution.xy;

    sourceSize = iResolution.xy / iEasuScale;
    outputSize = iResolution.xy;
}

void EASUOff( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 vTexCoord;
    vec2 sourceSize;
    vec2 outputSize;
    computeSize(vTexCoord, sourceSize, outputSize, fragCoord);

    /////////////////////////////////////////////////////
    fragColor = texture(iChannel0, vTexCoord);
}

void EASUOn( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 vTexCoord;
    vec2 sourceSize;
    vec2 outputSize;
    computeSize(vTexCoord, sourceSize, outputSize, fragCoord);

    /////////////////////////////////////////////////////
    FsrEasuCon(con0, con1, con2, con3,
        sourceSize.x, sourceSize.y,  // Viewport size (top left aligned) in the input image which is to be scaled.
        sourceSize.x, sourceSize.y,  // The size of the input image.
        outputSize.x, outputSize.y); // The output resolution.

    AU2 gxy = AU2(vTexCoord.xy * outputSize.xy); // Integer pixel position in output.
    AF3 Gamma2Color = AF3(0, 0, 0);
    FsrEasuF(Gamma2Color, gxy, con0, con1, con2, con3);

    fragColor = vec4(Gamma2Color, 1.0);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    bool isMouseDown = iMouse.z > 0.;

    if(isMouseDown)
        EASUOff(fragColor, fragCoord);
    else
        EASUOn(fragColor, fragCoord);
}