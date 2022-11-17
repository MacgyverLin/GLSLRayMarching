
// https://github.com/jesusgollonet/ofpennereasing/tree/master/PennerEasing
#define PI 3.141592653589
#define _2PI 6.28318530718
#define PI_2 1.57079632679

#define _A 65
#define _B 66
#define _C 67
#define _D 68
#define _E 68
#define _F 70
#define _G 71
#define _H 72
#define _I 73
#define _J 74
#define _K 75
#define _L 76
#define _M 77
#define _N 78
#define _O 79
#define _P 80
#define _Q 81
#define _R 82
#define _S 83
#define _T 84
#define _U 85
#define _V 86
#define _W 87
#define _X 88
#define _Y 89
#define _Z 90
#define _a 97
#define _b 98
#define _c 99
#define _d 100
#define _e 101
#define _f 102
#define _g 103
#define _h 104
#define _i 105
#define _j 106
#define _k 107
#define _l 108
#define _m 109
#define _n 110
#define _o 111
#define _p 112
#define _q 113
#define _r 114
#define _s 115
#define _t 116
#define _u 117
#define _v 118
#define _w 119
#define _x 120
#define _y 121
#define _z 122

float BackEaseIn(float t) {
	float s = 1.70158;
	float postFix = t;
	return (postFix)*t*((s+1.)*t - s);
}
float BackEaseOut(float t) {	
	float s = 1.70158;
	return ((t=t-1.)*t*((s+1.)*t + s) + 1.);
}

float BackEaseInOut(float t) {
	float s = 1.70158;
	if (t < .5) 
		return .5*t*t*(((s*=(1.525))+1.)*t - s);
	t -= 2.;
	return .5*t*t*(((s*=(1.525))+1.)*t + s) + 1.;
}

float ElasticEaseIn (float t) {
	t-=1.;
	return -pow(2., 10.*t) * sin((t-.3/4.)*_2PI/.3 );
}

float ElasticEaseOut(float t) {
    return pow(2.,-10.*t) * sin((t-.3/4.)*_2PI/.3) + 1.;
}

float ElasticEaseInOut(float t) {
	return t < .5 ? .5*ElasticEaseIn(2.*t) : .5*ElasticEaseOut(2.*t-1.)+.5;
}

float CircEaseIn (float t) {
	return 1. - sqrt(1. - t*t);
}
float CircEaseOut(float t) {
	t--;
	return sqrt(1. - t*t);
}

float CircEaseInOut(float t) {
	return t < .5 ? -.5 * (sqrt(1. - t*t) - 1.) : .5 * (sqrt(1. - t*(t-=2.)) + 1.);
}


float QuadEaseIn (float t) {
	return t*t;
}
float QuadEaseOut(float t) {
	return - t*(t-2.);
}

float QuadEaseInOut(float t) {
	return .5* (t<.5 ? t*t : ((t-2.)*(--t) - 1.));
}

float CubicEaseIn (float t) {
	return t*t*t;
}
float CubicEaseOut(float t) {
	return (t=t-1.)*t*t + 1.;
}

float CubicEaseInOut(float t) {
	return t<.5 ? .5*t*t*t: .5*((t-=2.)*t*t + 2.);	
}


float QuintEaseIn (float t) {
	return t*t*t*t*t;
}

float QuintEaseOut(float t) {
	return (t=t-1.)*t*t*t*t + 1.;
}

float QuintEaseInOut(float t) {
	return t<.5 ? .5*t*t*t*t*t : .5*((t-=2.)*t*t*t*t + 2.);
}

float BounceEaseOut(float t) {
	if (t < (1./2.75)) {
		return 7.5625*t*t;
	} else if (t < 2./2.75) {
		t-= 1.5/2.75;
		return 7.5625*t*t + .75;
	} else if (t < 2.5/2.75) {
		t-= 2.25/2.75;
		return 7.5625f*t*t + .9375;
	} else {
		t-= 2.625/2.75;
		return 7.5625*t*t + .984375;
	}
}

float BounceEaseIn (float t) {
	return 1. - BounceEaseOut(1.-t);
}

float BounceEaseInOut(float t) {
	return t < .5 ? .5*BounceEaseIn(t*2.) : .5*BounceEaseOut(t*2.-1.) + .5;
}

float ExpoEaseIn (float t) {
	return pow(2., 10. * (t - 1.));
}
float ExpoEaseOut(float t) {
	return -pow(2., -10. * t) + 1.;	
}

float ExpoEaseInOut(float t) {
	return t < .5 ? .5*ExpoEaseIn(t*2.) : .5*ExpoEaseOut(t*2.-1.) + .5;
}

float SineEaseIn(float t) {
	return 1. - cos(t * PI_2);
}

float SineEaseOut(float t) {	
	return sin(t * PI_2);	
}

float SineEaseInOut(float t) {
	return .5 - .5 * cos(PI*t);
}


// [IQ] https://www.shadertoy.com/view/lslBzS Implicit / f(x) plotter thing.

//XY range of the display.
#define DISP_SCALE 3.0 

//Line thickness (in pixels).
#define LINE_SIZE 2.0

const vec2 GRAD_OFFS = vec2(0.001, 0);

#define GRAD(f, p) (vec2(f(p) - f(p + GRAD_OFFS.xy), f(p) - f(p + GRAD_OFFS.yx)) / GRAD_OFFS.xx)

//PLOT(Function, Color, Destination, Screen Position)
#define PLOT(f, c, d, p) d = mix(c, d, smoothstep(0.0, (LINE_SIZE / iResolution.y * DISP_SCALE), abs(f(p) / length(GRAD(f,p)))))



