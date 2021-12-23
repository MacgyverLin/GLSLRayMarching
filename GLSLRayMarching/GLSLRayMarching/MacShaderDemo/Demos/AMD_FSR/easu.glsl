#define EASU_ULTRA_QUALITY			1.3
#define EASU_QUALITY				1.5
#define EASU_BALANCED				1.7
#define EASU_PERFORMANCE			2.0
#define EASU_ULTRA_PERFORMANCE		2.5

#define RCAS_SHARP_LEVEL5			0.001
#define RCAS_SHARP_LEVEL4			0.010
#define RCAS_SHARP_LEVEL3			0.100
#define RCAS_SHARP_LEVEL2			1.000
#define RCAS_SHARP_LEVEL1			2.000
#define RCAS_MAX_SHARP				RCAS_SHARP_LEVEL5
#define RCAS_MIN_SHARP				RCAS_SHARP_LEVEL1

#define MORE_SHARP_THAN(a, b)		(a < b)
#define LESS_SHARP_THAN(a, b)		(a > b)
#define MAKE_SHARPER(a, b)			(a = a - b)
#define MAKE_BLURER(a, b)			(a = a + b)

#define GFMB_GROUND_TRUTH			0
#define GFMB_FSR					1
#define GFMB_MFSR					2
#define GFMB_BILINEAR				3
#define GFMB_COMPARE_ALL			4

struct AppState
{
	float easuScale;		// = 2.0;
	float rcasShapening;	// = 0.2;
	bool showOrginalThumbnail; // false
	int show_GROUNDTRUTH_FSR_MFSR_BILINEAR;
};

#define valueChannel iChannel3
vec4 LoadValue(int x, int y)
{
	return texelFetch(valueChannel, ivec2(x, y), 0);
}

void LoadState(out AppState s)
{
	vec4 data;

	data = LoadValue(0, 0);
	s.easuScale = data.x;
	s.rcasShapening = data.y;
	s.showOrginalThumbnail = (data.z==1.0) ? true : false;
	s.show_GROUNDTRUTH_FSR_MFSR_BILINEAR = int(data.w);

	data = LoadValue(1, 0);
}

void StoreValue(vec2 fragCoord, vec2 re, vec4 va, inout vec4 fragColor)
{
	fragCoord = floor(fragCoord);

	fragColor = ((fragCoord.x == re.x && fragCoord.y == re.y) ? va : fragColor);
}

void SaveState(in AppState s, in vec2 fragCoord, inout vec4 fragColor)
{
    StoreValue(fragCoord, vec2(0., 0.), vec4(s.easuScale, s.rcasShapening, (s.showOrginalThumbnail) ? 1.0 : 0.0, float(s.show_GROUNDTRUTH_FSR_MFSR_BILINEAR)), fragColor);
}

void InitializeState(out AppState s)
{
	LoadState(s);

    if(iFrame<=1)
    {
	    s.easuScale = 1.8;
	    s.rcasShapening = 0.2;
		s.showOrginalThumbnail = false;
		s.show_GROUNDTRUTH_FSR_MFSR_BILINEAR = GFMB_FSR;
    }
}

///////////////////////////////////////////////////////////
/*
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
*/

#define A_GPU 1
#define A_GLSL 1
#define A_HALF 1
#include "/ffx_a.h"
#define FSR_EASU_H 1

//declare input callbacks

AU4 con0, con1, con2, con3;

AH4 FsrEasuRH(AF2 p) { return AH4(textureGather(iChannel0, p, 0)); }
AH4 FsrEasuGH(AF2 p) { return AH4(textureGather(iChannel0, p, 1)); }
AH4 FsrEasuBH(AF2 p) { return AH4(textureGather(iChannel0, p, 2)); }

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
    FsrEasuH(Gamma2Color, gxy, con0, con1, con2, con3);

    return vec4(Gamma2Color, 1.0);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	AppState s;
	InitializeState(s);

    fragColor = EASU(fragCoord, s.easuScale);
}