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
#define GFMB_SSIM					4
#define GFMB_COMPARE_ALL			5

struct AppState
{
	float easuScale;		// = 2.0;
	float rcasShapening;	// = 0.2;
	bool showOrginalThumbnail; // false
	int displayMode;
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
	s.displayMode = int(data.w);

	data = LoadValue(1, 0);
}

void StoreValue(vec2 fragCoord, vec2 re, vec4 va, inout vec4 fragColor)
{
	fragCoord = floor(fragCoord);

	fragColor = ((fragCoord.x == re.x && fragCoord.y == re.y) ? va : fragColor);
}

void SaveState(in AppState s, in vec2 fragCoord, inout vec4 fragColor)
{
    StoreValue(fragCoord, vec2(0., 0.), vec4(s.easuScale, s.rcasShapening, (s.showOrginalThumbnail) ? 1.0 : 0.0, float(s.displayMode)), fragColor);
}

void InitializeState(out AppState s)
{
	LoadState(s);

    if(iFrame<=1)
    {
	    s.easuScale = 1.8;
	    s.rcasShapening = 0.2;
		s.showOrginalThumbnail = false;
		s.displayMode = GFMB_FSR;
    }
}

