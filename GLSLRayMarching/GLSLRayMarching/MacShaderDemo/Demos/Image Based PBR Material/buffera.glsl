// Buffer A : Sliders
//
// Author : SÃ©bastien BÃ©rubÃ©
// Created : Dec 2015
// Modified : Mar 2016
#define saturate(x) clamp(x,0.0,1.0)
vec4 sliderVal = vec4(0.30,0.75,0.0,0.10); //Default slider values [0-1]

void SLIDER_setValue(float idx, float val)
{
    if(idx<0.) return;
    else if(idx<0.25) sliderVal[0] = saturate(val);
	else if(idx<0.50) sliderVal[1] = saturate(val);
	else if(idx<0.75) sliderVal[2] = saturate(val);
	else if(idx<1.00) sliderVal[3] = saturate(val);
}

float SLIDER_getValue(float idx)
{
    if     (idx<0.25) return sliderVal[0];
    else if(idx<0.50) return sliderVal[1];
    else if(idx<0.75) return sliderVal[2];
    else if(idx<1.00) return sliderVal[3];
	else return 0.;
}

void SLIDER_init(vec2 mousePos, vec2 cMin, vec2 cMax )
{
    vec4 cPingPong = texture(iChannel0,vec2(0));
    if(length(cPingPong)>0.001)
        sliderVal = cPingPong;
        
    float width = cMax.x-cMin.x;
    float height = cMax.y-cMin.y;
    if(mousePos.x>cMin.x && mousePos.x<cMax.x &&
       mousePos.y>cMin.y && mousePos.y<cMax.y )
    {
        float t = (mousePos.y-cMin.y)/height;
        t = clamp(t/0.75-0.125,0.,1.); //25% top/bottom margins
		SLIDER_setValue((mousePos.x-cMin.x)/width, t);
    }
}

//Returns the distance from point "p" to a given line segment defined by 2 points [a,b]
float UTIL_distanceToLineSeg(vec2 p, vec2 a, vec2 b)
{
    //       p
    //      /
    //     /
    //    a--e-------b
    vec2 ap = p-a;
    vec2 ab = b-a;
    //Scalar projection of ap in the ab direction = dot(ap,ab)/|ab| : Amount of ap aligned towards ab
    //Divided by |ab| again, it becomes normalized along ab length : dot(ap,ab)/(|ab||ab|) = dot(ap,ab)/dot(ab,ab)
    //The clamp provides the line seg limits. e is therefore the "capped orthogogal projection", and length(p-e) is dist.
    vec2 e = a+clamp(dot(ap,ab)/dot(ab,ab),0.0,1.0)*ab;
    return length(p-e);
}

//uv = slider pixel in local space [0-1], t = slider value [0-1], ar = aspect ratio (w/h)
vec4 SLIDER_drawSingle(vec2 uv, float t, vec2 ar, bool bHighlighted)
{
    const vec3  ITEM_COLOR = vec3(1);
    const vec3  HIGHLIGHT_COLOR = vec3(0.2,0.7,0.8);
    const float RAD = 0.05;  //Cursor radius, in local space
    const float LW  = 0.030; //Line width
    float aa  = 14./iResolution.x; //antialiasing width (smooth transition)
    vec3 selectionColor = bHighlighted?HIGHLIGHT_COLOR:ITEM_COLOR;
    vec3 cheapGloss   = 0.8*selectionColor+0.2*smoothstep(-aa,aa,uv.y-t-0.01+0.01*sin(uv.x*12.));
    vec2 bottomCenter = vec2(0.5,0.0);
	vec2 topCenter    = vec2(0.5,1.0);
    vec2 cursorPos    = vec2(0.5,t);
    float distBar = UTIL_distanceToLineSeg(uv*ar, bottomCenter*ar, topCenter*ar);
    float distCur = length((uv-cursorPos)*ar)-RAD;
    float alphaBar = 1.0-smoothstep(2.0*LW-aa,2.0*LW+aa, distBar);
    float alphaCur = 1.0-smoothstep(2.0*LW-aa,2.0*LW+aa, distCur);
    vec4  colorBar = vec4(mix(   vec3(1),vec3(0),smoothstep(LW-aa,LW+aa, distBar)),alphaBar);
    vec4  colorCur = vec4(mix(cheapGloss,vec3(0),smoothstep(LW-aa,LW+aa, distCur)),alphaCur);
    return mix(colorBar,colorCur,colorCur.a);
}

#define withinUnitRect(a) (a.x>=0. && a.x<=1. && a.y>=0. && a.y<=1.0)
vec4 SLIDER_drawAll(vec2 uv, vec2 cMin, vec2 cMax, vec2 muv)
{
    float width = cMax.x-cMin.x;
    float height = cMax.y-cMin.y;
    vec2 ar = vec2(0.30,1.0);
    uv  = (uv -cMin)/vec2(width,height); //pixel Normalization
    muv = (muv-cMin)/vec2(width,height); //mouse Normalization
    if( withinUnitRect(uv) )
    {
        float t = SLIDER_getValue(uv.x);
		bool bHighlight = withinUnitRect(muv) && abs(floor(uv.x*4.0)-floor(muv.x*4.0))<0.01;
		uv.x = fract(uv.x*4.0); //repeat 4x
		uv.y = uv.y/0.75-0.125; //25% margins
        return SLIDER_drawSingle(uv,t,ar,bHighlight);
    }
    return vec4(0);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 cMinSliders = vec2(0.9,0.80);
    vec2 cMaxSliders = vec2(1.0,1.00);
    vec2 uvSliders = fragCoord.xy / iResolution.xy;
    vec2 mousePos = iMouse.xy / iResolution.xy;
    SLIDER_init(mousePos, cMinSliders, cMaxSliders);
    vec4 cSlider = SLIDER_drawAll(uvSliders,cMinSliders, cMaxSliders, mousePos);
    
    if(length(fragCoord.xy-vec2(0,0))<1.) 
        fragColor = sliderVal;
	else fragColor = cSlider;
}