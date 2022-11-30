/*
	The mathematics details by 834144373(恬纳微晰)
	This shader url : https://www.shadertoy.com/view/XdVfRm
	Licence: CC3.0 署名（BY）-非商业性使用（NC）-相同方式共享（SA）
	Also 834144373 is 恬纳微晰 or TNWX or 祝元洪
*/
//----------Some For Option Math Constant Define---------
#define MY_E 					2.7182818
#define ONE_OVER_E				0.3678794
#define PI 						3.1415926
#define TWO_PI 					6.2831852
#define FOUR_PI 				12.566370
#define INVERSE_PI 				0.3183099
#define ONE_OVER_TWO_PI 		0.1591549
#define ONE_OVER_FOUR_PI 		0.0795775
#define OFFSET_COEF 			0.0001
#define INFINITY         		1000000.0
//--------------------Material Fresnel-------------------- 
//水
#define F0_WATER        0.02	
//塑料
#define F0_PLASTIC      0.03	
//塑料-主高光
#define F0_PLASTIC_HIGH 0.05	
//玻璃
#define F0_GLASS        0.08	
//钻石
#define F0_DIAMOND      0.17	
//铁制
#define F0_IRON         0.56	
//铜制
#define F0_COPPER       0.95	
//金制
#define F0_GOLD         1.00	
//铝制
#define F0_ALUMINIUM    0.91	
//银制
#define F0_SILVER       0.95

//Monte Carlo by Importance Samplering Methods
/*
 	F(N) ≈ (1/N) * SUM( f(Xi)/pdf(Xi) ) <1,N>
*/
//----------------------Math Function---------------------
float seed;
float GetRandom(){return fract(sin(seed++)*43758.5453123);}
#if __VERSION__ >= 300
float FastSqrt(float x){return intBitsToFloat(532483686 + (floatBitsToInt(x) >> 1));}
#endif
float POW2(float x){ return x*x;}
float POW3(float x){ return x*x*x;}
float POW4(float x){ float x2 = x*x; return x2*x2;}
float POW5(float x){ float x2 = x*x; return x2*x2*x;}

float Complement(float coeff){ return 1.0 - coeff; }
float cosTheta(vec3 w) { return w.z; }
float cosTheta2(vec3 w) { return w.z*w.z; }
float cosTheta4(vec3 w) { float cos2Theta = cosTheta2(w); return cos2Theta*cos2Theta;}
float absCosTheta(vec3 w) { return abs(w.z); }
float sinTheta2(vec3 w) { return Complement(w.z*w.z); }
float sinTheta(vec3 w) { return sqrt(clamp(sinTheta2(w),0.,1.)); }
float tanTheta2(vec3 w) { return sinTheta2(w) / cosTheta2(w); }
float tanTheta(vec3 w) { return sinTheta(w) / cosTheta(w); }

float cosPhi(vec3 w) { return w.x / sinTheta(w);}
float sinPhi(vec3 w) { return w.y / sinTheta(w);}
float cosPhi2(vec3 w){ return w.x*w.x/sinTheta2(w);}
float sinPhi2(vec3 w){ return w.y*w.y/sinTheta2(w);}
//angle(θ,ϕ)
vec3 Angle2Cartesian(vec2 angle){
	float SinTheta = sin(angle.x);
	vec2 CosSinPhi = vec2(cos(angle.y),sin(angle.y));
	return vec3(SinTheta*CosSinPhi,cos(angle.x)); //x,y,z
}
//计算正交向量基
//http://orbit.dtu.dk/files/126824972/onb_frisvad_jgt2012_v2.pdf
void naive (vec3 n,vec3 b1,vec3 b2){
    // If n is near the x-axis , use the y- axis . Otherwise use the x- axis .
    if(n.x > 0.9) b1 = vec3(0.0,1.0,0.0);
    else b1 = vec3(1.0,0.0,0.0);
    b1 -= n* dot (b1 , n ); // Make b1 orthogonal to n
    b1 *= inversesqrt(dot(b1,b1)); // Normalize b1
    b2 = cross (n , b1 ); // Construct b2 using a cross product
}
void hughes_moeller (vec3 n,vec3 b1,vec3 b2 ){
    // Choose a vector orthogonal to n as the direction of b2.
    if(abs(n.x )>abs(n.z)) b2 = vec3(-n.y,n.x,0.);
    else b2 = vec3 (0.,-n.z,n.y );
    b2 *= inversesqrt(dot(b2,b2 )); // Normalize b2
    b1 = cross (b2 , n ); // Construct b1 using a cross product
}
void frisvad(in vec3 n, out vec3 f, out vec3 r){
    if(n.z < -0.999999) {
        f = vec3(0.,-1,0);
        r = vec3(-1, 0, 0);
    } else {
    	float a = 1./(1.+n.z);
    	float b = -n.x*n.y*a;
    	f = vec3(1. - n.x*n.x*a, b, -n.x);
    	r = vec3(b, 1. - n.y*n.y*a , -n.y);
    }
}
mat3 CoordBase(vec3 n){
	vec3 x,y;
    frisvad(n,x,y);
    return mat3(x,y,n);
}


vec3 ToOtherSpaceCoord(mat3 otherSpaceCoord,vec3 vector){
	return vector * otherSpaceCoord;
}
vec3 RotVector(mat3 otherSpaceCoord,vec3 vector){
	return otherSpaceCoord * vector;
}
//-----------------Specular BRDF Microfacet---------------
/*
			   D(h)F(v,h)G(l,v,h)		D(Distribution)   
	f(l,v) = ———————————-    F(Fresnel)
				   4(n•l)(n•v)			G(Geometry)
*/
//--->Distribution Term<----
float D_GGX(float roughress,vec3 N,vec3 H){
	float r2 = POW2(roughress);
    float cosTheta2 = POW2(dot(N,H));
    return (1.0/PI) * sqrt(roughress/(cosTheta2 * (r2 - 1.0) + 1.0));	
}
//------>Fresnel Term<------
float F_Schlick(float F0, vec3 L,vec3 H){
    return F0 + (1.0 - F0)*POW5(1.0-dot(L,H));
}
/*
	https://github.com/thefranke/dirtchamber/blob/master/shader/brdf.hlsl
*/
#define OneOnLN2_x6 8.656170 // == 1/ln(2) * 6   (6 is SpecularPower of 5 + 1)
vec3 F_schlick_opt(vec3 SpecularColor,vec3 E,vec3 H){
    // In this case SphericalGaussianApprox(1.0f - saturate(dot(E, H)), OneOnLN2_x6) is equal to exp2(-OneOnLN2_x6 * x)
    return SpecularColor + (1.0 - SpecularColor) * exp2(-OneOnLN2_x6 * clamp(0.,1.,dot(E, H)));
}
//------------Multiple Importance Sample Weight-----------
/*
	heuristic
	here βis 2;so power of coeff
*/
float MISWeight(float a,float b){
	float a2 = a*a;
	float b2 = b*b;
	return a2/(a2+b2);
}
float MISWeight(float coffe_a,float aPDF,float coffe_b,float bPDF){
    return MISWeight(coffe_a * aPDF,coffe_b*bPDF);
}
//--------------Probability Density Function and Sample--------------
/*
	----------------GGX NDF-----------------
	D(m)  	 = a^2/(PI*((a^2-1)*cos^2(θ)+1)^2)
	Ph(ω) 	= a^2*cos(θ)/(PI*((a^2-1)*cos^2(θ)+1)^2) 
	Ph(θ,ϕ) = a^2*cos(θ)*sin(θ)/(PI*((a^2-1)*cos^2(θ)+1)^2)
	So we can get θ,ϕ by inverse CDF
		ϕ = 2*PI*ϵ      
		θ = arccos{sqrt[(1-ϵ)/(ϵ*(a^2-1)+1)]} Or θ = arctan{a*sqrt[ϵ/(1-ϵ)]} 
	Note: ϵ or 1-ϵ is uniform distribution noise at (0,1)
*/
vec2 GGXSampleAngle(float x1,float x2,float a){
	float phi   = TWO_PI * x2;
	float theta = atan(a*sqrt(x1/(1.0-x1)));
	return vec2(theta,phi);
}
/*
	----------------Beckmann NDF-----------------
	D(m)  	= 	   1/(PI*a^2*cos^4(θ)))*ϵ^-(tan(θ)/a)^2
	Ph(ω) 	= 	   1/(PI*a^2*cos^3(θ)))*ϵ^-(tan(θ)/a)^2
	Ph(θ,ϕ) = sin(θ)/(PI*a^2*cos^3(θ)))*ϵ^-(tan(θ)/a)^2
	So we can get θ,ϕ by inverse CDF
		ϕ = 2*PI*ϵ      
		θ = arccos{sqrt[1/(1-a^2*ln(1-ϵ))]} Or θ = arctan{sqrt[-a^2*ln(1-ϵ)]} 
	Note: ϵ or 1-ϵ is uniform distribution noise at (0,1)
*/
vec2 BeckmannSampleAngle(float x1,float x2,float a){
	float phi	= TWO_PI * x2;
	float theta = atan(sqrt(-a*a*log(1.0-x1)));
	return vec2(theta,phi);
}
/*
	----------------Blinn NDF-----------------
	D(m)  	 = (a+2)/_2PI * [cos(θ)]^(a)
	Ph(ω) 	= (a+2)/_2PI * [cos(θ)]^(a+1)
	Ph(θ,ϕ) = (a+2)/_2PI * [cos(θ)]^(a+1) * sin(θ)
	So we can get θ,ϕ by inverse CDF
		ϕ = 2*PI*ϵ      
		θ = arccos{1/(ϵ^(a+2))}  Or  θ = arccos{1/(ϵ^(a+1))}  <note:form PBRT>
	Note: ϵ or 1-ϵ is uniform distribution noise at (0,1)
*/
vec2 BlinSampleAngle(float x1,float x2,float a){
	float phi   = TWO_PI * x2;
	float theta = acos(1.0/pow(x1,a+1.0));		//<note:form PBRT>
	return vec2(theta,phi);
}
/*---------------------------------
	Whether it’s solid angle or spherical coordinate. 
	What we have so far is the pdf for half-vector,a transformation is necessary.
---> P(θ) = Ph(θ)*(dWh)/(dWi) = Ph(θ)/(4*Wo*wh)
*/
float PDF_h2theta(float pdf_h,vec3 wi,vec3 wh){
	return 0.25*pdf_h/dot(wi,wh);//return pdf_h/(4.0*dot(wo,wh));
}
vec3 UniformUnitShpereRay(float x1,float x2){
	float theta = PI * x1;
    float phi   = TWO_PI * x2;
    float sinTheta = sin(theta);
    return vec3(sinTheta*cos(phi),sinTheta*sin(phi),cos(theta));
}
vec3 DiffuseUnitSpehreRay(float x1,float x2){
	float theta = acos(sqrt(1.0-x1));
    float phi   = TWO_PI * x2;
    float sinTheta = sin(theta);
    return vec3(sinTheta*cos(phi),sinTheta*sin(phi),cos(theta));
}
/*
Form https://www.shadertoy.com/view/4ssXRX
	 https://www.shadertoy.com/view/MslGR8
	 https://www.loopit.dk/banding_in_games.pdf
*/
float nrand( vec2 n ){
	return fract(sin(dot(n.xy, vec2(12.9898, 78.233)))* 43758.5453);
}
//float GetRandom(float seed){return fract(sin(seed)*43758.5453123);}
float TriangularNoise(vec2 n,float time){
    float t = fract(time);
	float nrnd0 = nrand( n + 0.07*t );
	float nrnd1 = nrand( n + 0.11*t );
	return (nrnd0+nrnd1) / 2.0;
}
vec2 TriangularNoise2DShereRay(vec2 n,float time){
	float theta = TWO_PI*GetRandom();
    float r = TriangularNoise(n,time);
    return vec2(cos(theta),sin(theta))*(1.-r);
}
//---------------VNDF-----------------
/*
	https://hal.inria.fr/hal-00942452v1/document
	https://hal.archives-ouvertes.fr/hal-01509746/document
	https://hal.inria.fr/file/index/docid/996995/filename/article.pdf
	and some reference https://www.shadertoy.com/view/llfyRj
  	alpha_x/alpha_y is anisotropic roughness; U1/U2 is uniform random numbers
*/
vec3 sampleGGXVNDF(vec3 V_, float alpha_x, float alpha_y, float U1, float U2){
	// stretch view
	vec3 V = normalize(vec3(alpha_x * V_.x, alpha_y * V_.y, V_.z));
	// orthonormal basis
	vec3 T1 = (V.z < 0.9999) ? normalize(cross(V, vec3(0,0,1))) : vec3(1,0,0);
	vec3 T2 = cross(T1, V);
	// sample point with polar coordinates (r, phi)
	float a = 1.0 / (1.0 + V.z);
	float r = sqrt(U1);
	float phi = (U2<a) ? U2/a * PI : PI + (U2-a)/(1.0-a) * PI;
	float P1 = r*cos(phi);
	float P2 = r*sin(phi)*((U2<a) ? 1.0 : V.z);
	// compute normal
	vec3 N = P1*T1 + P2*T2 + sqrt(max(0.0, 1.0 - P1*P1 - P2*P2))*V;
	// unstretch
	N = normalize(vec3(alpha_x*N.x, alpha_y*N.y, max(0.0, N.z)));
	return N;
}
/*
------>GGX Distribution
*/
float GGX_Distribution(vec3 wh, float alpha_x, float alpha_y) {
    float tan2Theta = tanTheta2(wh);
    if(alpha_x == alpha_y){
    	//------when alpha_x == alpha_y so
    	float c = alpha_x + tan2Theta/alpha_x;
    	return 1.0/(PI*cosTheta4(wh)*c*c);
	}else{
		float alpha_xy = alpha_x * alpha_y;
		float e_add_1 = 1. + tan2Theta / alpha_xy;
    	return 1.0 / (PI * alpha_xy * cosTheta4(wh) * e_add_1 * e_add_1);
	}
}
/*
    	Λ(ω) = (-1+sign(a)sqrt(1+1/(a*a))/2 where a = 1/(ai*tan(theta_i))   	<0,π>
	so  Λ(ω) = (-1+sqrt(1+ai^2*tan^2(θ)))/2		<0,π/2>
*/
float lambda(vec3 w, float alpha_x, float alpha_y){
	return 0.5*(-1.0 + sqrt(1.0 + alpha_x*alpha_y*tanTheta2(w)));
}
/*
	  G (wo,wi) = G1(wo)G1(wi) 
	  G1(ωo,ωm) = 1/(1+Λ(ωo)) 
*/
float GGX_G1(vec3 w, float alpha_x, float alpha_y) {
    return 1.0 / (1.0 + lambda(w, alpha_x, alpha_y));
}
/*
	https://jo.dreggn.org/home/2016_microfacets.pdf
	G2(ωi, ωo, ωm) is masking-shadowing
	G2(ωi, ωo, ωm) = G1(ωi, ωm)G1(ωo, ωm)  [Walter et al.2007]
		<If ωi and ωo are on the same side of the microsurface (i.e. reflection),it has the closed for>
	G2(ωi, ωo) = 1/[1+Λ(ωi)+Λ(ωo)]

------>GGX Geometry
*/
float GGX_G2(vec3 wo, vec3 wi, float alpha_x, float alpha_y) {
    return 1.0 / (1.0 + lambda(wo, alpha_x, alpha_y) + lambda(wi, alpha_x, alpha_y));
}
/*
	https://hal.inria.fr/hal-00996995v1/document
	PDF(ωm·ωg)D(ωm)	 previous
	PDF Dωi(ωm)		   now this
		Dωi(ωm) = G1(ωi,ωm)|ωi·ωm|D(ωm)/|ωi·ωg|
*/
float GGX_PDF(vec3 wi, vec3 wh, float alpha_x, float alpha_y) {
    return GGX_Distribution(wh, alpha_x, alpha_y) * GGX_G1(wi, alpha_x, alpha_y) * abs(dot(wi, wh)) / abs(wi.z);
}
//For Diffuse Lambert Sample
float Diffuse_PDF(vec3 L){
	return INVERSE_PI*cosTheta(L);
}
//For Reflect Micro-fact Sample
float Specular_PDF(vec3 wi, vec3 wh, float alpha_x, float alpha_y){
	return PDF_h2theta(GGX_PDF(wi,wh,alpha_x,alpha_y),wi,wh); 
}
//--------------------Post Processing---------------------
vec3 GammaCorrect(vec3 col,float coeff){
	return pow(col,vec3(coeff));
}
vec3 GammaCorrect(vec3 col,vec3 coeff){
	return pow(col,coeff);
}
vec3 ExposureCorrect(vec3 col, float linfac, float logfac){
	return linfac*(1.0 - exp(col*logfac));
}
/*
	An almost-perfect approximation from http://chilliant.blogspot.com.au/2012/08/srgb-approximations-for-hlsl.html?m=1
*/
vec3 GammaToLinear(vec3 sRGB){
    return sRGB * (sRGB * (sRGB * 0.305306011 + 0.682171111) + 0.012522878);
}
vec3 LinearToGamma(vec3 linRGB){
    linRGB = max(linRGB, vec3(0.));
    return max(1.055 * pow(linRGB, vec3(0.416666667)) - 0.055, vec3(0.));
}
vec3 SimpleToneMapping(vec3 col){
	return 1.0/(1.0+col);
}
float Luminance(vec3 linearRGB){
    return dot(linearRGB, vec3(0.2126729,  0.7151522, 0.0721750));
}
//------------------------YCoCg-R---------------------------
//x:Y y:Co z:Cg
/*
	Co  = R - B;
	tmp = B + Co/2;
	Cg  = G - tmp;
	Y   = tmp + Cg/2;
*/
vec3 RGB2YCoCg_R(vec3 RGB) {
	vec3 YCoCg_R;//x:Y y:Co z:Cg
	YCoCg_R.y = RGB.r - RGB.b;
	float tmp = RGB.b + YCoCg_R.y / 2.;
	YCoCg_R.z = RGB.g - tmp;
	YCoCg_R.x = tmp + YCoCg_R.z / 2.;
	return YCoCg_R;
}
/*
	tmp = Y - Cg/2;
	G   = Cg + tmp;
	B   = tmp - Co/2;
	R   = B + Co;
*/
vec3 YCoCg_R2RGB(vec3 YCoCg_R) {
	vec3 RGB;
	float tmp = YCoCg_R.x - YCoCg_R.z / 2.;
	RGB.g = YCoCg_R.z + tmp;
	RGB.b = tmp - YCoCg_R.y / 2.;
	RGB.r = RGB.b + YCoCg_R.y;
	return RGB;
}
//-------------------------YCoCg----------------------------
/*
	 Y = R/4 + G/2 + B/4
	Co = R/2 - B/2
	Cg =-R/4 + G/2 - B/4
*/
vec3 RGB2YCoCg(vec3 RGB) {
	vec3 YCoCg;
	YCoCg.x =  RGB.r / 4. + RGB.g / 2. + RGB.b / 4.;
	YCoCg.y =  RGB.r / 2. - RGB.b / 2. ;
	YCoCg.z = -RGB.r / 4. + RGB.g / 2. - RGB.b / 4.;
	return YCoCg;
}
/*
	R = Y + Co - Cg
	G = Y + Cg
	B = Y - Co - Cg
*/
vec3 YCoCg2RGB(vec3 YCoCg) {
	vec3 RGB;
	RGB.r = YCoCg.x + YCoCg.y - YCoCg.z;
	RGB.g = YCoCg.x + YCoCg.z;
	RGB.b = YCoCg.x - YCoCg.y - YCoCg.z;
	return RGB;
}
/*
	ACES
	https://knarkowicz.wordpress.com/2016/01/06/aces-filmic-tone-mapping-curve/
*/
vec3 ACESFilm(vec3 x ){
    const float a = 2.51;
    const float b = 0.03;
    const float c = 2.43;
    const float d = 0.59;
    const float e = 0.14;
    return clamp(vec3(0.),vec3(1.),(x*(a*x+b))/(x*(c*x+d)+e));
}
/*
	http://filmicworlds.com/blog/filmic-tonemapping-operators/
	https://de.slideshare.net/hpduiker/filmic-tonemapping-for-realtime-rendering-siggraph-2010-color-course
*/
const float A = 0.15;//ShoulderStrength
const float B = 0.50;//LinearStrength
const float C = 0.10;//LinearAngle
const float D = 0.20;//ToeStrength
const float E = 0.02;
const float F = 0.30;
const float W = 10.2;

vec3 Uncharted2Tonemap(vec3 x){
   	return ((x*(A*x+C*B)+D*E)/(x*(A*x+B)+D*F))-E/F;
}
#define Gamma 2.2
vec3 ACESFilmicToneMapping(vec3 col){
	vec3 curr = Uncharted2Tonemap(col);
    const float ExposureBias = 2.0;
	curr *= ExposureBias;
    curr /= Uncharted2Tonemap(vec3(W));
    return LinearToGamma(curr);
}
/*
	https://github.com/TheRealMJP/BakingLab/blob/master/BakingLab/ToneMapping.hlsl
*/
vec3 Linear2sRGB(vec3 color){
    vec3 x = color * 12.92;
    vec3 y = 1.055 * pow(clamp(vec3(0.),vec3(1.),color),vec3(0.4166667)) - 0.055;
    vec3 clr = color;
    clr.r = color.r < 0.0031308 ? x.r : y.r;
    clr.g = color.g < 0.0031308 ? x.g : y.g;
    clr.b = color.b < 0.0031308 ? x.b : y.b;
    return clr;
}
vec3 sRGB2Linear(vec3 color){
    vec3 x = color / 12.92f;
    vec3 y = pow(max((color+0.055f)/1.055, 0.0),vec3(2.4));
    vec3 clr = color;
    clr.r = color.r <= 0.04045 ? x.r : y.r;
    clr.g = color.g <= 0.04045 ? x.g : y.g;
    clr.b = color.b <= 0.04045 ? x.b : y.b;
    return clr;
}
// Applies the filmic curve from John Hable's presentation
vec3 ToneMapFilmicALU(vec3 color){
    color = max(vec3(0.),color-0.004);
    color = (color*(6.2*color+0.5))/(color*(6.2*color+1.7)+0.06);
    return color;
}
vec3 ColorGrade(vec3 vColor){
    vec3 vHue = vec3(.97, .8, .2);
    vec3 vGamma = 1. + vHue * 0.6;
    vec3 vGain = vec3(0.9) + vHue * vHue * 8.0;
    vColor *= 1.5;
    float fMaxLum = 100.0;
    vColor /= fMaxLum;
    vColor = pow( vColor, vGamma );
    vColor *= vGain;
    vColor *= fMaxLum;  
    return vColor;
}

#define _LUT_Size 16.
vec3 ColorGradeLUT(sampler2D _LUT,vec3 color) {
    vec3 coord = color*(_LUT_Size -1.);
    coord.xy = vec2((coord.x + _LUT_Size*floor(coord.z)+.5)/ (_LUT_Size*_LUT_Size),(coord.y+0.5)/ _LUT_Size);
    return texture(_LUT,coord.xy).rgb;
}

/*
	https://www.shadertoy.com/view/MdyyRt from 834144373
	Or you can easy find from wiki
*/
#define _Strength 10.
vec4 FXAA(sampler2D _Tex,vec2 uv,vec2 RenderSize){
    vec3 e = vec3(1./RenderSize,0.);

    float reducemul = 0.125;// 1. / 8.;
    float reducemin = 0.0078125;// 1. / 128.;

    vec4 Or = texture(_Tex,uv); //P
    vec4 LD = texture(_Tex,uv - e.xy); //左下
    vec4 RD = texture(_Tex,uv + vec2( e.x,-e.y)); //右下
    vec4 LT = texture(_Tex,uv + vec2(-e.x, e.y)); //左上
    vec4 RT = texture(_Tex,uv + e.xy); // 右上

    float Or_Lum = Luminance(Or.rgb);
    float LD_Lum = Luminance(LD.rgb);
    float RD_Lum = Luminance(RD.rgb);
    float LT_Lum = Luminance(LT.rgb);
    float RT_Lum = Luminance(RT.rgb);

    float min_Lum = min(Or_Lum,min(min(LD_Lum,RD_Lum),min(LT_Lum,RT_Lum)));
    float max_Lum = max(Or_Lum,max(max(LD_Lum,RD_Lum),max(LT_Lum,RT_Lum)));

    //x direction,-y direction
    vec2 dir = vec2((LT_Lum+RT_Lum)-(LD_Lum+RD_Lum),(LD_Lum+LT_Lum)-(RD_Lum+RT_Lum));
    float dir_reduce = max((LD_Lum+RD_Lum+LT_Lum+RT_Lum)*reducemul*0.25,reducemin);
    float dir_min = 1./(min(abs(dir.x),abs(dir.y))+dir_reduce);
    dir = min(vec2(_Strength),max(-vec2(_Strength),dir*dir_min)) * e.xy;

    //------
    vec4 resultA = 0.5*(texture(_Tex,uv-0.166667*dir)+texture(_Tex,uv+0.166667*dir));
    vec4 resultB = resultA*0.5+0.25*(texture(_Tex,uv-0.5*dir)+texture(_Tex,uv+0.5*dir));
    float B_Lum = Luminance(resultB.rgb);

    //return resultA;
    if(B_Lum < min_Lum || B_Lum > max_Lum)
        return resultA;
    else 
        return resultB;
}