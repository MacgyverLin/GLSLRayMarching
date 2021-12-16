struct AppState
{
	float easuScale;		// = 2.0;
	float rcasShapening;	// = 0.2;
};

vec4 LoadValue(int x, int y)
{
	return texelFetch(iChannel0, ivec2(x, y), 0);
}

void LoadState(out AppState s)
{
	vec4 data;

	data = LoadValue(0, 0);
	s.easuScale = data.x;
	s.rcasShapening = data.y;

	data = LoadValue(1, 0);
}

void StoreValue(vec2 fragCoord, vec2 re, vec4 va, inout vec4 fragColor)
{
	fragCoord = floor(fragCoord);
	fragColor = (fragCoord.x == re.x && fragCoord.y == re.y) ? va : fragColor;
}

vec4 SaveState(in AppState s, in vec2 fragCoord, inout vec4 fragColor)
{
    StoreValue(fragCoord, vec2(0., 0.), vec4(s.easuScale, s.rcasShapening, 0.0, 0.0), fragColor);
    StoreValue(fragCoord, vec2(1., 0.), vec4(0.0, 0.0, 0.0, 0.0), fragColor);

	return fragColor;
}

void InitializeState(out AppState s)
{
	LoadState(s);

    //if(iFrame<=1)
    {
	    s.easuScale = 2.0;
	    s.rcasShapening = 0.2;
    }
}



//////////////////////////////////////////////////////////////////////////////////////
#define A_GPU 1
#define A_GLSL 1
#include "/ffx_a.h"

#define FSR_EASU_F 1
AU4 con0, con1, con2, con3;

AF4 FsrEasuRF(AF2 p) { return textureGather(iChannel0, p, 0); }
AF4 FsrEasuGF(AF2 p) { return textureGather(iChannel0, p, 1); }
AF4 FsrEasuBF(AF2 p) { return textureGather(iChannel0, p, 2); }

#include "/ffx_fsr1.h"

void computeSize(out vec2 outputTexCoord, out vec2 viewportSize, out vec2 sourceSize, out vec2 outputSize, in vec2 fragCoord, in float easuScale)
{
    outputTexCoord  = fragCoord / iResolution.xy;

    viewportSize = iResolution.xy / easuScale;
    sourceSize = iResolution.xy;
    outputSize = iResolution.xy;
}

vec4 EASU(in vec2 fragCoord, in float easuScale)
{
    vec2 outputTexCoord;
    vec2 viewportSize;
    vec2 sourceSize;
    vec2 outputSize;
    computeSize(outputTexCoord, viewportSize, sourceSize, outputSize, fragCoord, easuScale);

    /////////////////////////////////////////////////////
    FsrEasuCon(con0, con1, con2, con3,
        viewportSize.x, viewportSize.y,  // Viewport size (top left aligned) in the input image which is to be scaled.
        sourceSize.x, sourceSize.y,      // The size of the input image.
        outputSize.x, outputSize.y);     // The output resolution.

    AU2 gxy = AU2(outputTexCoord.xy * outputSize.xy); // Integer pixel position in output.
    AF3 Gamma2Color = AF3(0, 0, 0);
    FsrEasuF(Gamma2Color, gxy, con0, con1, con2, con3);

    return vec4(Gamma2Color, 1.0);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
	AppState s;
	InitializeState(s);

    fragColor = EASU(fragCoord, s.easuScale);
}