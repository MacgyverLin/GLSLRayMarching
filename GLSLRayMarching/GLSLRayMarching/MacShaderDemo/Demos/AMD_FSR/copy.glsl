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

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
	AppState s;
	InitializeState(s);

    if(s.show_GROUNDTRUTH_FSR_MFSR_BILINEAR			        == GFMB_GROUND_TRUTH)
        showGroundTruth(fragColor, fragCoord, s.easuScale, s.showOrginalThumbnail);
    else if(s.show_GROUNDTRUTH_FSR_MFSR_BILINEAR			== GFMB_FSR)
        showFSR(fragColor, fragCoord, s.easuScale, s.showOrginalThumbnail);
    else if(s.show_GROUNDTRUTH_FSR_MFSR_BILINEAR			== GFMB_MFSR)
        showMFSR(fragColor, fragCoord, s.easuScale, s.showOrginalThumbnail);
    else if(s.show_GROUNDTRUTH_FSR_MFSR_BILINEAR			== GFMB_BILINEAR)
        showBilinearFiltered(fragColor, fragCoord, s.easuScale, s.showOrginalThumbnail);
    else if(s.show_GROUNDTRUTH_FSR_MFSR_BILINEAR			== GFMB_COMPARE_ALL)
        compareAll(fragColor, fragCoord, s.easuScale, s.showOrginalThumbnail);
    
    //showFSRComparision(fragColor, fragCoord, s.easuScale, s.showOrginalThumbnail);
}