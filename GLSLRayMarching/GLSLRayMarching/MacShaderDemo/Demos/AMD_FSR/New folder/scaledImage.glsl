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

#define keyboard iChannel1
#define KEY_DOWN(key)   (texture(keyboard, vec2((float(int(key)+1) + 0.5)/256, (0.0 + 0.5)/3)).r == 0)
#define KEY_CLICK(key)  (texture(keyboard, vec2((float(int(key)+1) + 0.5)/256, (1.0 + 0.5)/3)).r == 0)
#define KEY_TOGGLE(key) (texture(keyboard, vec2((float(int(key)+1) + 0.5)/256, (2.0 + 0.5)/3)).r == 0)
void UpdateStateValue(inout AppState s)
{
	if(KEY_DOWN('w'))
    {
		s.easuScale			+= 0.1;
		if(s.easuScale < 1.0)
			s.easuScale = 1.0;
	}
	else if(KEY_DOWN('s'))
    {
		s.easuScale			-= 0.1;
		if(s.easuScale > 4.0)
			s.easuScale = 4.0;
	}
	
	if(KEY_DOWN('q'))
    {
		s.rcasShapening		+= 0.1;
		if(s.rcasShapening < 2.0)
			s.rcasShapening = 2.0;
	}
	else if(KEY_DOWN('a'))
    {
		s.rcasShapening		-= 0.1;
		if(s.rcasShapening < 0.01)
			s.rcasShapening = 0.01;
	}
}

//////////////////////////////////////////////////////////////////////////////////////
void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
	AppState s;
	InitializeState(s);
	//UpdateStateValue(s);

    vec2 vTexCoord = fragCoord / iResolution.xy;
    fragColor = texture(iChannel0, vTexCoord * iEasuScale);

	fragColor = SaveState(s, fragCoord, fragColor);
}