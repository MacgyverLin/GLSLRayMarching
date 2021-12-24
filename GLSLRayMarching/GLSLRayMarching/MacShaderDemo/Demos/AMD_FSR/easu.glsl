#include "/savestate.h"

///////////////////////////////////////////////////////////
#define A_GPU 1
#define A_GLSL 1
#include "/ffx_a.h"

#define FSR_EASU_F 1
AU4 con0, con1, con2, con3;

AF4 FsrEasuRF(AF2 p) { return textureGather(iChannel0, p, 0); }
AF4 FsrEasuGF(AF2 p) { return textureGather(iChannel0, p, 1); }
AF4 FsrEasuBF(AF2 p) { return textureGather(iChannel0, p, 2); }

AF3 FsrEasuSampleF(AF2 p) { return textureLod(iChannel0, p, 0).xyz; }

#include "/ffx_fsr1.h"

void computeSize(out vec2 outputTexCoord, out vec2 viewportSize, out vec2 sourceSize, out vec2 outputSize, in vec2 fragCoord, in vec2 resolution, in float easuScale)
{
    outputTexCoord  = fragCoord / resolution.xy;

    viewportSize = resolution.xy / easuScale;
    sourceSize = resolution.xy;
    outputSize = resolution.xy;
}

vec4 EASU(in vec2 fragCoord, in float easuScale)
{
    vec2 outputTexCoord;
    vec2 viewportSize;
    vec2 sourceSize;
    vec2 outputSize;
    computeSize(outputTexCoord, viewportSize, sourceSize, outputSize, fragCoord, iResolution.xy, easuScale);

    /////////////////////////////////////////////////////
    FsrEasuCon(con0, con1, con2, con3,
        viewportSize.x, viewportSize.y,  // Viewport size (top left aligned) in the input image which is to be scaled.
        sourceSize.x, sourceSize.y,      // The size of the input image.
        outputSize.x, outputSize.y);     // The output resolution.

    AU2 gxy = AU2(outputTexCoord.xy * outputSize.xy); // Integer pixel position in output.
    AF3 Gamma2Color = AF3(0, 0, 0);
    FsrEasuL(Gamma2Color, gxy, con0, con1, con2, con3);

    return vec4(Gamma2Color, 1.0);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	AppState s;
	InitializeState(s);

    fragColor = EASU(fragCoord, s.easuScale);
}