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


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// #pragma parameter uFSR_SHARPENING "FSR RCAS Sharpening Amount (Lower = Sharper)" 0.2 0.0 2.0
// const float uFSR_SHARPENING = 0.2;

// #pragma parameter uFSR_FILMGRAIN "FSR LFGA Film Grain Intensity" 0.3 0.0 2.0 0.02
// const float uFSR_FILMGRAIN = 0.3;

// #pragma parameter uFSR_GRAINCOLOR "FSR LFGA Film Grain Color: Gray | RGB" 1.0 0.0 1.0 1.0
// const float uFSR_GRAINCOLOR = 1.0;

// #pragma parameter uFSR_GRAINPDF "FSR LFGA Grain PDF Curve (0.5 = Triangular, Lower = Gaussian)" 0.3 0.1 0.5 0.05
// const float uFSR_GRAINPDF = 0.5;

/////////////////////////////////////////////////////////////////////////////////////////
#define A_GPU 1
#define A_GLSL 1
#include "/ffx_a.h"

#define FSR_RCAS_F 1
AU4 con0;

AF4 FsrRcasLoadF(ASU2 p) { return AF4(texelFetch(iChannel0, p, 0)); }
void FsrRcasInputF(inout AF1 r, inout AF1 g, inout AF1 b) {}

#include "/ffx_fsr1.h"

// prng: A simple but effective pseudo-random number generator [0;1[
float prng(vec2 uv, float time) 
{
    return fract(sin(dot(uv + fract(time), vec2(12.9898, 78.233))) * 43758.5453);
}

// pdf: [-0.5;0.5[
// Removes noise modulation effect by reshaping the uniform/rectangular noise
// distribution (RPDF) into a Triangular (TPDF) or Gaussian Probability Density
// Function (GPDF).
// shape = 1.0: Rectangular
// shape = 0.5: Triangular
// shape < 0.5: Gaussian (0.2~0.4)
float pdf(float noise, float shape) 
{
    float orig = noise * 2.0 - 1.0;
    noise = pow(abs(orig), shape);
    noise *= sign(orig);
    noise -= sign(orig);
    return noise * 0.5;
}

void computeSize(out vec2 outputTexCoord, out vec2 sourceSize, out vec2 outputSize, in vec2 fragCoord)
{
    outputTexCoord  = fragCoord / iResolution.xy;

    sourceSize = iResolution.xy;
    outputSize = iResolution.xy;
}

vec4 RCAS(in vec2 fragCoord, in float rcasSharpening)
{
    vec2 outputTexCoord;
    vec2 sourceSize;
    vec2 outputSize;
    computeSize(outputTexCoord, sourceSize, outputSize, fragCoord);

    /////////////////////////////////////////////////////
    FsrRcasCon(con0, rcasSharpening);

    AU2 gxy = AU2(outputTexCoord.xy * outputSize.xy); // Integer pixel position in output.
    AF3 Gamma2Color = AF3(0, 0, 0);
    FsrRcasF(Gamma2Color.r, Gamma2Color.g, Gamma2Color.b, gxy, con0);

    /*
    // FSR - [LFGA] LINEAR FILM GRAIN APPLICATOR
    if (uFSR_FILMGRAIN > 0.0) {
        if (uFSR_GRAINCOLOR == 0.0) {
            float noise = pdf(prng(outputTexCoord, uFrameCount * 0.11), uFSR_GRAINPDF);
            FsrLfgaF(Gamma2Color, vec3(noise), uFSR_FILMGRAIN);
        } else {
            vec3 rgbNoise = vec3(
                pdf(prng(outputTexCoord, uFrameCount * 0.11), uFSR_GRAINPDF),
                pdf(prng(outputTexCoord, uFrameCount * 0.13), uFSR_GRAINPDF),
                pdf(prng(outputTexCoord, uFrameCount * 0.17), uFSR_GRAINPDF)
            );
            FsrLfgaF(Gamma2Color, rgbNoise, uFSR_FILMGRAIN);
        }
    }
    */

    return vec4(Gamma2Color, 1.0);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
	AppState s;
	InitializeState(s);

    fragColor = RCAS(fragCoord, s.rcasShapening);
}