#include "/savestate.h"

///////////////////////////////////////////////////////////
#define keyboard iChannel1
#define KEY_DOWN(key)   (texture(keyboard, vec2((float(int(key)+1) + 0.5)/256, (0.0 + 0.5)/3)).r == 0)
#define KEY_CLICK(key)  (texture(keyboard, vec2((float(int(key)+1) + 0.5)/256, (1.0 + 0.5)/3)).r == 0)
#define KEY_TOGGLE(key) (texture(keyboard, vec2((float(int(key)+1) + 0.5)/256, (2.0 + 0.5)/3)).r == 0)
void ControlStateValue(inout AppState s)
{
	if(KEY_DOWN('x'))  // better quality
    {
		s.easuScale			-= 0.001;
		if(s.easuScale < EASU_ULTRA_QUALITY)
			s.easuScale = EASU_ULTRA_QUALITY;
	}
	else if(KEY_DOWN('z')) // lower quality
    {
		s.easuScale			+= 0.001;
		if(s.easuScale > EASU_PERFORMANCE)
			s.easuScale = EASU_PERFORMANCE;
	}
	if(KEY_DOWN('c'))
    {
		s.easuScale			= EASU_ULTRA_PERFORMANCE;
	}
	else if(KEY_DOWN('v'))
    {
		s.easuScale			= EASU_PERFORMANCE;
	}
	else if(KEY_DOWN('b'))
    {
		s.easuScale			= EASU_BALANCED;
	}
	else if(KEY_DOWN('n'))
    {
		s.easuScale			= EASU_QUALITY;
	}
	else if(KEY_DOWN('m'))
    {
		s.easuScale			= EASU_ULTRA_QUALITY;
	}

	if(KEY_DOWN('a')) // more sharp
    {
		MAKE_BLURER(s.rcasShapening, 0.001);
		
		if(LESS_SHARP_THAN(s.rcasShapening, RCAS_MIN_SHARP))
			s.rcasShapening = RCAS_MIN_SHARP;
	}
	else if(KEY_DOWN('s')) // less sharp
    {
		MAKE_SHARPER(s.rcasShapening, 0.001);

		if(MORE_SHARP_THAN(s.rcasShapening, RCAS_MAX_SHARP))
			s.rcasShapening = RCAS_MAX_SHARP;
	}
	if(KEY_DOWN('d'))
    {
		s.rcasShapening			= RCAS_SHARP_LEVEL1;
	}
	else if(KEY_DOWN('f'))
    {
		s.rcasShapening			= RCAS_SHARP_LEVEL2;
	}
	else if(KEY_DOWN('g'))
    {
		s.rcasShapening			= RCAS_SHARP_LEVEL3;
	}
	else if(KEY_DOWN('h'))
    {
		s.rcasShapening			= RCAS_SHARP_LEVEL4;
	}
	else if(KEY_DOWN('j'))
    {
		s.rcasShapening			= RCAS_SHARP_LEVEL5;
	}

	if(KEY_CLICK('q'))
    {
		s.displayMode	-= 1;
		if(s.displayMode < GFMB_GROUND_TRUTH)
			s.displayMode = GFMB_GROUND_TRUTH;
	}
	else if(KEY_CLICK('w'))
    {
		s.displayMode	+= 1;
		if(s.displayMode > GFMB_COMPARE_ALL)
			s.displayMode = GFMB_COMPARE_ALL;
	}
	if(KEY_CLICK('e'))
    {
		s.displayMode			= GFMB_GROUND_TRUTH;
	}
	else if(KEY_CLICK('r'))
    {
		s.displayMode			= GFMB_FSR;
	}
	else if(KEY_CLICK('t'))
    {
		s.displayMode			= GFMB_MFSR;
	}
	else if(KEY_CLICK('y'))
    {
		s.displayMode			= GFMB_BILINEAR;
	}
	else if(KEY_CLICK('u'))
    {
		s.displayMode			= GFMB_SSIM;
	}
	else if(KEY_CLICK('i'))
    {
		s.displayMode			= GFMB_COMPARE_ALL;
	}


	if(KEY_CLICK('p'))
    {
		if(s.showOrginalThumbnail)
			s.showOrginalThumbnail = false;
		else
			s.showOrginalThumbnail = true;
	}
}

//////////////////////////////////////////////////////////////////////////////////////
void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
	AppState s;
	InitializeState(s);
	ControlStateValue(s);

    vec2 vTexCoord = fragCoord * s.easuScale / iResolution.xy;
	if(vTexCoord.x>1 || vTexCoord.y>1)
		fragColor = vec4(0.0, 0.0, 0.0, 1.0);
	else
	{
		fragColor = texture(iChannel0, vTexCoord);
	}

	SaveState(s, fragCoord, fragColor);
}