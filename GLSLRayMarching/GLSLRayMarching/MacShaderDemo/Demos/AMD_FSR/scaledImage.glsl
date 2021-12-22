struct AppState
{
	float easuScale;		// = 2.0;
	float rcasShapening;	// = 0.2;
	bool showOrginalThumbnail; // false
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

	data = LoadValue(1, 0);
}

void StoreValue(vec2 fragCoord, vec2 re, vec4 va, inout vec4 fragColor)
{
	fragCoord = floor(fragCoord);

	fragColor = ((fragCoord.x == re.x && fragCoord.y == re.y) ? va : fragColor);
}

void SaveState(in AppState s, in vec2 fragCoord, inout vec4 fragColor)
{
    StoreValue(fragCoord, vec2(0., 0.), vec4(s.easuScale, s.rcasShapening, (s.showOrginalThumbnail) ? 1.0 : 0.0, 0.0), fragColor);
}

void InitializeState(out AppState s)
{
	LoadState(s);

    if(iFrame<=1)
    {
	    s.easuScale = 1.8;
	    s.rcasShapening = 0.01;
		s.showOrginalThumbnail = false;
    }
}

#define keyboard iChannel1
#define KEY_DOWN(key)   (texture(keyboard, vec2((float(int(key)+1) + 0.5)/256, (0.0 + 0.5)/3)).r == 0)
#define KEY_CLICK(key)  (texture(keyboard, vec2((float(int(key)+1) + 0.5)/256, (1.0 + 0.5)/3)).r == 0)
#define KEY_TOGGLE(key) (texture(keyboard, vec2((float(int(key)+1) + 0.5)/256, (2.0 + 0.5)/3)).r == 0)

#define ULTRA_QUALITY			1.3
#define QUALITY					1.5
#define BALANCED				1.7
#define PERFORMANCE				2.0
#define ULTRA_PERFORMANCE		2.5

#define RCAS_SHARP_LEVEL5		0.001
#define RCAS_SHARP_LEVEL4		0.010
#define RCAS_SHARP_LEVEL3		0.100
#define RCAS_SHARP_LEVEL2		1.000
#define RCAS_SHARP_LEVEL1		2.000
#define RCAS_MAX_SHARP			RCAS_SHARP_LEVEL5
#define RCAS_MIN_SHARP			RCAS_SHARP_LEVEL1

#define MORE_SHARP_THAN(a, b)		(a < b)
#define LESS_SHARP_THAN(a, b)		(a > b)
#define MAKE_SHARPER(a, b)			(a = a - b)
#define MAKE_BLURER(a, b)			(a = a + b)

void ControlStateValue(inout AppState s)
{
	if(KEY_DOWN('w'))  // better quality
    {
		s.easuScale			-= 0.001;
		if(s.easuScale < ULTRA_QUALITY)
			s.easuScale = ULTRA_QUALITY;
	}
	else if(KEY_DOWN('q')) // lower quality
    {
		s.easuScale			+= 0.001;
		if(s.easuScale > ULTRA_PERFORMANCE)
			s.easuScale = ULTRA_PERFORMANCE;
	}
	if(KEY_DOWN('e'))
    {
		s.easuScale			= ULTRA_PERFORMANCE;
	}
	else if(KEY_DOWN('r'))
    {
		s.easuScale			= PERFORMANCE;
	}
	else if(KEY_DOWN('t'))
    {
		s.easuScale			= BALANCED;
	}
	else if(KEY_DOWN('y'))
    {
		s.easuScale			= QUALITY;
	}
	else if(KEY_DOWN('u'))
    {
		s.easuScale			= ULTRA_QUALITY;
	}

	if(KEY_DOWN('a'))
    {
		MAKE_BLURER(s.rcasShapening, 0.001);
		
		if(LESS_SHARP_THAN(s.rcasShapening, RCAS_MIN_SHARP))
			s.rcasShapening = RCAS_MIN_SHARP;
	}
	else if(KEY_DOWN('s'))
    {
		MAKE_SHARPER(s.rcasShapening, 0.001);

		if(MORE_SHARP_THAN(s.rcasShapening, RCAS_MAX_SHARP))
			s.rcasShapening = RCAS_MAX_SHARP;
	}
	if(KEY_DOWN('d'))
    {
		s.rcasShapening			= RCAS_SHARP_LEVEL5;
	}
	else if(KEY_DOWN('f'))
    {
		s.rcasShapening			= RCAS_SHARP_LEVEL4;
	}
	else if(KEY_DOWN('g'))
    {
		s.rcasShapening			= RCAS_SHARP_LEVEL3;
	}
	else if(KEY_DOWN('h'))
    {
		s.rcasShapening			= RCAS_SHARP_LEVEL2;
	}
	else if(KEY_DOWN('j'))
    {
		s.rcasShapening			= RCAS_SHARP_LEVEL1;
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