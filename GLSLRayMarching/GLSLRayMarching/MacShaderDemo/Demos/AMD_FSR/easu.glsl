#define A_GPU 1
#define A_GLSL 1
#include "/ffx_a.h"

#define FSR_EASU_F 1
AU4 con0, con1, con2, con3;

AF4 FsrEasuRF(AF2 p) { return textureGather(iChannel0, p, 0); }
AF4 FsrEasuGF(AF2 p) { return textureGather(iChannel0, p, 1); }
AF4 FsrEasuBF(AF2 p) { return textureGather(iChannel0, p, 2); }

#include "/ffx_fsr1.h"

void computeSize(out vec2 outputTexCoord, out vec2 viewportSize, out vec2 sourceSize, out vec2 outputSize, in vec2 fragCoord)
{
    outputTexCoord  = fragCoord / iResolution.xy;

    viewportSize = iResolution.xy / iEasuScale;
    sourceSize = iResolution.xy;
    outputSize = iResolution.xy;
}

void EASU( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 outputTexCoord;
    vec2 viewportSize;
    vec2 sourceSize;
    vec2 outputSize;
    computeSize(outputTexCoord, viewportSize, sourceSize, outputSize, fragCoord);

    /////////////////////////////////////////////////////
    FsrEasuCon(con0, con1, con2, con3,
        viewportSize.x, viewportSize.y,  // Viewport size (top left aligned) in the input image which is to be scaled.
        sourceSize.x, sourceSize.y,      // The size of the input image.
        outputSize.x, outputSize.y);     // The output resolution.

    AU2 gxy = AU2(outputTexCoord.xy * outputSize.xy); // Integer pixel position in output.
    AF3 Gamma2Color = AF3(0, 0, 0);
    FsrEasuF(Gamma2Color, gxy, con0, con1, con2, con3);

    fragColor = vec4(Gamma2Color, 1.0);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    EASU(fragColor, fragCoord);
}