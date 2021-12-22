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
	    s.rcasShapening = 0.2;
		s.showOrginalThumbnail = false;
    }
}

#define keyboard iChannel1
#define KEY_DOWN(key)   (texture(keyboard, vec2((float(int(key)+1) + 0.5)/256, (0.0 + 0.5)/3)).r == 0)
#define KEY_CLICK(key)  (texture(keyboard, vec2((float(int(key)+1) + 0.5)/256, (1.0 + 0.5)/3)).r == 0)
#define KEY_TOGGLE(key) (texture(keyboard, vec2((float(int(key)+1) + 0.5)/256, (2.0 + 0.5)/3)).r == 0)
void ControlStateValue(inout AppState s)
{
	if(KEY_DOWN('w'))
    {
		s.easuScale			-= 0.001;
		if(s.easuScale < 1.3)
			s.easuScale = 1.3;
	}
	else if(KEY_DOWN('s'))
    {
		s.easuScale			+= 0.001;
		if(s.easuScale > 2.0)
			s.easuScale = 2.0;
	}
	
	if(KEY_DOWN('q'))
    {
		s.rcasShapening		+= 0.001;
		if(s.rcasShapening > 2.0)
			s.rcasShapening = 2.0;
	}
	else if(KEY_DOWN('a'))
    {
		s.rcasShapening		-= 0.001;
		if(s.rcasShapening < 0.001)
			s.rcasShapening = 0.001;
	}

	if(KEY_CLICK('r'))
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