// Candlestick - @P_Malin
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
// 
// Playing with iterative raymarching and cubemap materials.
//
// Try commenting out LOW_QUALITY and uncommmenting ENABLE_MIRROR below.

//#define LOW_QUALITY

#ifdef LOW_QUALITY

	#define kRaymarchMaxIter 32
	#define kMaxIter 3
	#define kShadowIter 8

#else

	#define kRaymarchMaxIter 128
	#define kMaxIter 4
	#define kShadowIter 16

#endif 

//#define ENABLE_MIRROR

//#define BURN_DOWN

float fSceneIntensity = 0.5;

vec3 vFlameLightColour = vec3(1.0, 0.5, 0.1) * 10.0;
vec3 vFlameColour1 = vec3(1.0, 0.5, 0.1);
vec3 vFlameColour2 = vec3(1.0, 0.05, 0.01);

vec3 BlackBody( float t )
{
    float h = 6.6e-34; // Planck constant
    float k = 1.4e-23; // Boltzmann constant
    float c = 3e8;// Speed of light

    vec3 w = vec3( 610.0, 549.0, 468.0 ) / 1e9; // sRGB approximate wavelength of primaries
    
    // This would be more accurate if we integrate over a range of wavelengths
    // rather than a single wavelength for r, g, b
    
    // Planck's law https://en.wikipedia.org/wiki/Planck%27s_law
    
    vec3 w5 = w*w*w*w*w;    
    vec3 o = 2.*h*(c*c) / (w5 * (exp(h*c/(w*k*t)) - 1.0));

    return o;
}

vec3 GetFlameWander()
{
    vec3 vFlameWander = vec3(0.0, 0.0, 0.0);

	vFlameWander.x = sin(iTime * 20.0);
	vFlameWander.z = sin(iTime * 10.0) * 2.0;

    return vFlameWander;	
}

float fWaxExtinction = 5.0;

float kExposure = 3.5;

vec3 vCandlestickPos = vec3(-3.0, 0.0, 2.0);

#ifndef BURN_DOWN
	float fCandleTop = max(2.2, 3.8);
#else
	float fCandleTop = max(2.2, 3.8 - iTime * 0.005);
#endif

vec3 GetLightPos()
{
    return vCandlestickPos + vec3(0.0, fCandleTop + 0.35, 0.0) - GetFlameWander() * 0.01;
}

#define kMaterialWood   0.0
#define kMaterialGold 	1.0
#define kMaterialWax 	2.0
#define kMaterialWick	3.0
#define kMaterialChrome	4.0
#define kMaterialPaper	5.0

vec3 RotateX( const in vec3 vPos, const in float s, const in float c )
{
	vec3 vResult = vec3( vPos.x, c * vPos.y + s * vPos.z, -s * vPos.y + c * vPos.z);

	return vResult;
}

vec3 RotateY( const in vec3 vPos, const in float s, const in float c )
{
	vec3 vResult = vec3( c * vPos.x + s * vPos.z, vPos.y, -s * vPos.x + c * vPos.z);

	return vResult;
}

vec2 GetDistanceFloor( const in vec3 vPos )
{
	return vec2(vPos.y, kMaterialWood);
}

vec2 GetDistanceCandlestick( const in vec3 vPos )
{
	vec2 vProfilePos = vec2( length(vPos.xz), vPos.y );

	float fTop = 2.0;
	float fBottom = 0.0;
	
	float fOutside = -1.0;
	
	float fDist = vProfilePos.x;	
	float fVerticalPos = vProfilePos.y;
	
	if(fVerticalPos > fTop)
	{
		fVerticalPos = fTop;
		fOutside = 1.0;
	}

	if(fVerticalPos < fBottom)
	{
		fVerticalPos = fBottom;		
		fOutside = 1.0;
	}

	float t = fVerticalPos;
	float a = 3.14 * 2.0;
	float b = 0.15;
	float fHorizontalPos = 0.4 + sin(t * a) * b;
	float fHorizontalPosDelta = (cos(t * a) * a * b) / a;
	
	float fHorizontalDist = vProfilePos.x - fHorizontalPos;
	
	if(fOutside > 0.0)
	{
		vec2 vClosest = vec2(min(fHorizontalPos, vProfilePos.x), fVerticalPos);
		
		fDist = length(vClosest - vProfilePos);		
	}
	else
	{
		
		if(fHorizontalDist > 0.0)
		{
			fOutside = 1.0;
		}

		if(fOutside < 0.0)
		{		
			float fTopDist = fTop - fVerticalPos;
			float fBottomDist = fVerticalPos - fBottom;
			fDist = min(fTopDist, fBottomDist);
			fDist = min(fDist, -fHorizontalDist);
		}
		else
		{
			fDist = fHorizontalDist / sqrt(1.0 + fHorizontalPosDelta * fHorizontalPosDelta);	
		}
	}
	
	float fBevel = 0.1;
	float fStickDistance = fOutside * fDist -fBevel;
	
	float fBaseTop = 0.1;
	float fBaseRadius = 1.0;
	vec2 vBaseClosest = vProfilePos;
	vBaseClosest.y = min(vBaseClosest.y, fBaseTop);
	vBaseClosest.x = min(vBaseClosest.x, fBaseRadius);

	float fBaseDistance = length(vProfilePos - vBaseClosest) - fBevel;
	
	return vec2( min(fStickDistance, fBaseDistance), kMaterialGold);
}

float GetDistanceWaxTop( const in vec3 vPos )
{
	vec2 vProfilePos = vec2( length(vPos.xz), vPos.y );

	float fCurve = 1.0;
	
	return vProfilePos.y - fCandleTop - vProfilePos.x * vProfilePos.x * fCurve;	
}

vec2 GetDistanceCandle( const in vec3 vPos )
{
	vec2 vProfilePos = vec2( length(vPos.xz), vPos.y );
	
	float fDistance = vProfilePos.x - 0.2;
		
	float fDistanceTop = GetDistanceWaxTop(vPos);
	
	if(fDistanceTop > fDistance)
	{
		fDistance = fDistanceTop;
	}
	
	return vec2(fDistance, kMaterialWax);
}


vec2 GetDistanceWick( const in vec3 vPos )
{
	vec2 vProfilePos = vec2( length(vPos.xz), vPos.y );
	
	float fDistance = vProfilePos.x - 0.015;
	
	float fDistanceTop = vProfilePos.y - (fCandleTop + 0.2);
	if(fDistanceTop > fDistance)
	{
		fDistance = fDistanceTop;
	}
	
	return vec2(fDistance, kMaterialWick);
}

vec2 GetDistanceSphere( const in vec3 vPos )
{
	float fDistance = length(vPos - vec3(1.3, 0.75, 1.0)) - 0.75;

	return vec2(fDistance, kMaterialChrome);
}

float GetDistanceBox( const in vec3 vPos, const in vec3 vDimension )
{
	vec3 vDist = abs(vPos) - vDimension;
  	float fDistance =  min(max(vDist.x,max(vDist.y,vDist.z)),0.0) + length(max(vDist,0.0));

	return fDistance;	
}

vec3 vMirrorGlassSize = vec3(2.5, 2.0, 0.1);
float fMirrorFrameSize = 0.2;

vec3 vMirrorStandSize = vec3(2.8, 1.5, 0.5);
float fMirrorStandWidth = 0.2;

float g_MirrorRotSin = sin(-0.3);
float g_MirrorRotCos = cos(-0.3);

float g_MirrorTiltSin = sin(0.1);
float g_MirrorTiltCos = cos(0.1);

vec2 GetDistanceMirrorGlass( const in vec3 vPos )
{	
	float fDistance = GetDistanceBox(vPos, vMirrorGlassSize);
	return vec2(fDistance, kMaterialChrome);
}

vec2 GetDistanceMirrorFrame( const in vec3 vPos )
{
	float fDistanceOuterFrame = GetDistanceBox(vPos, vMirrorGlassSize + vec3(fMirrorFrameSize)) - 0.2;
	float fDistanceFrameHole = GetDistanceBox(vPos + vec3(0.0, 0.0, fMirrorFrameSize * 2.0), vMirrorGlassSize + vec3(0.0, 0.0, fMirrorFrameSize * 2.0));
	
	float fDistance = max(fDistanceOuterFrame, -fDistanceFrameHole);
	
	return vec2(fDistance, kMaterialWood);
}


vec2 GetDistanceMirror( const in vec3 vPos )
{
	vec2 vResult = GetDistanceMirrorFrame(vPos);
	
	vec2 vGlass = GetDistanceMirrorGlass(vPos);
	
	if(vGlass.x < vResult.x)
	{
		vResult = vGlass;
	}
		
	return vResult;
}


vec2 GetDistanceMirrorStand( const in vec3 vPos )
{
	float fDistanceOuter = GetDistanceBox(vPos - vec3(0.0, 1.5, 0.0), vMirrorStandSize + vec3(fMirrorStandWidth));
	float fDistanceInner = GetDistanceBox(vPos - vec3(0.0, 1.5 + fMirrorStandWidth * 2.0, 0.0), vMirrorStandSize + vec3(0.0, fMirrorStandWidth ,1.0));
		
	float fDistance = max(fDistanceOuter, -fDistanceInner);

	return vec2(fDistance, kMaterialWood);
}

vec2 GetDistancePaper( const in vec3 vPos )
{
	float fDistance = GetDistanceBox(vPos, vec3(1.05, 0.01, 1.485));

	return vec2(fDistance, kMaterialPaper);
}

float g_PaperRotSin = sin(-0.1);
float g_PaperRotCos = cos(-0.1);

vec2 GetDistanceShadowCasters( const in vec3 vPos )
{
	vec2 vResult = vec2(1000.0, -1.0);

	vec3 vCandlestickLocalPos = vPos - vCandlestickPos;	

	vec2 vCandlestick = GetDistanceCandlestick(vCandlestickLocalPos);
	if(vCandlestick.x < vResult.x)
	{
		vResult = vCandlestick;
	}
	
	vec2 vSphere = GetDistanceSphere(vPos);
	if(vSphere.x < vResult.x)
	{
		vResult = vSphere;
	}
	
	
	vec3 vPapereLocalPos = RotateY(vPos, g_PaperRotSin, g_PaperRotCos);
	
	vec2 vPaper = GetDistancePaper(vPapereLocalPos);
	if(vPaper.x < vResult.x)
	{
		vResult = vPaper;
	}

	
	#ifdef ENABLE_MIRROR
	
	vec3 vMirrorLocalPos = vPos - vec3(0.0, 0.0, 3.5);
	vMirrorLocalPos = RotateY(vMirrorLocalPos, g_MirrorRotSin, g_MirrorRotCos);
	
	vec2 vMirrorStand = GetDistanceMirrorStand(vMirrorLocalPos);
	if(vMirrorStand.x < vResult.x)
	{
		vResult = vMirrorStand;
	}
	
	
	vec3 vMirrorPaneLocalPos = vMirrorLocalPos - vec3(0.0, 2.7, 0.0);	
	vMirrorPaneLocalPos = RotateX(vMirrorPaneLocalPos, g_MirrorTiltSin, g_MirrorTiltCos);
	
	vec2 vMirror = GetDistanceMirror(vMirrorPaneLocalPos);
	if(vMirror.x < vResult.x)
	{
		vResult = vMirror;
	}
	#endif	

	return vResult;
}

vec2 GetSceneDistance( vec3 vPos )
{    
	vec3 vCandlestickLocalPos = vPos - vCandlestickPos;	

	vec2 vResult = vec2(1000.0, -1.0);
			
	vec2 vFloor = GetDistanceFloor(vPos);
	if(vFloor.x < vResult.x)
	{
		vResult = vFloor;
	}
	
	vec2 vCandle = GetDistanceCandle(vCandlestickLocalPos);
	if(vCandle.x < vResult.x)
	{
		vResult = vCandle;
	}
	
	
	vec2 vWick = GetDistanceWick(vCandlestickLocalPos);
	if(vWick.x < vResult.x)
	{
		vResult = vWick;
	}	

	vec2 vSolids = GetDistanceShadowCasters(vPos);
	if(vSolids.x < vResult.x)
	{
		vResult = vSolids;
	}	

	return vResult;
}

vec2 Raycast( const in vec3 vOrigin, const in vec3 vDir )
{
	vec2 d = vec2(0.0, -1.0);
	float t = 0.01;
	for(int i=0; i<kRaymarchMaxIter; i++)
	{
		d = GetSceneDistance(vOrigin + vDir * t);
		if(abs(d.x) < 0.001)
		{
			break;
		}
		t += d.x;
		if(t > 100.0)
		{
			break;
		}
	}
	
	return vec2(t, d.y);
}

float RaycastShadow( const in vec3 vOrigin, const in vec3 vDir, const in float k )
{
	float fShadow = 1.0;
	float t = 0.01;
	float fDelta = 1.0 / float(kShadowIter);
	for(int i=0; i<kShadowIter; i++)
	{
		float d = GetDistanceShadowCasters(vOrigin + vDir * t).x;
		
		fShadow = min( fShadow, k * d / t );
		
		t = t + fDelta;
	}
	
	return clamp(fShadow, 0.0, 1.0);
}

float GetAmbientOcclusion( const in vec3 vPos, const in vec3 vNormal)
{	
	float fAmbientOcclusion = 0.0;
	
	float fStep = 0.1;
	float fDist = 0.0;
	for(int i=0; i<=5; i++)
	{
		fDist += fStep;
		
		vec2 vSceneDist = GetSceneDistance(vPos + vNormal * fDist);
		
		float fAmount = (fDist - vSceneDist.x);
		
		fAmbientOcclusion += max(0.0, fAmount * fDist );                                  
	}
	
	return max(1.0 - fAmbientOcclusion, 0.0);
}

vec3 GetSceneNormal( const in vec3 vPos )
{
    const float fDelta = 0.001;

    vec3 vOffset1 = vec3( fDelta, -fDelta, -fDelta);
    vec3 vOffset2 = vec3(-fDelta, -fDelta,  fDelta);
    vec3 vOffset3 = vec3(-fDelta,  fDelta, -fDelta);
    vec3 vOffset4 = vec3( fDelta,  fDelta,  fDelta);

    float f1 = GetSceneDistance( vPos + vOffset1 ).x;
    float f2 = GetSceneDistance( vPos + vOffset2 ).x;
    float f3 = GetSceneDistance( vPos + vOffset3 ).x;
    float f4 = GetSceneDistance( vPos + vOffset4 ).x;

    vec3 vNormal = vOffset1 * f1 + vOffset2 * f2 + vOffset3 * f3 + vOffset4 * f4;

    return normalize( vNormal );
}

vec3 HackHDR( const in vec3 vCol )
{	
	return (-log(1.0 - min(vCol, 0.98)));
}

vec3 SampleEnvironment( const in vec3 vDir )
{
	vec3 vSample = textureLod(iChannel0, vDir, 0.0).rgb;
	return (HackHDR(vSample * vSample)) * fSceneIntensity;
}

vec3 SampleDiffuse( const in vec3 vDir )
{
	vec3 vSample = textureLod(iChannel1, vDir, 0.0).rgb;
	vSample = vSample * vSample;
	
	// hack bright spots out of blurred environment
	float fMag = length(vSample);	
	vSample = mix(vSample, vec3(0.15, 0.06, 0.03), smoothstep(0.1, 0.25, fMag));
	
	return vSample * fSceneIntensity;
}

vec3 GetFlameIntensity( const in vec3 vOrigin, const in vec3 vDir, const in float fDistance )
{
	vec3 vFlamePos = vec3(0.0, fCandleTop + 0.25, 0.0) + vCandlestickPos;
	vec3 vToFlame = vFlamePos - vOrigin;
	
	float fClosestDot = dot(vDir, vToFlame);
	fClosestDot = clamp(fClosestDot, 0.0, fDistance);
	
	vec3 vClosestPos = vOrigin + vDir * fClosestDot;
	vec3 vClosestToFlame = vClosestPos - vFlamePos;
	
	vClosestToFlame.xz *= (vClosestToFlame.y + 1.0) * 1.5;
	vClosestToFlame.y *= 0.5;
	vClosestToFlame *= 8.0;

	float fSwayAmount = (1.0 + vClosestToFlame.y ) * 0.05;
	vClosestToFlame += GetFlameWander() * fSwayAmount;
	
	float fClosestDist = length(vClosestToFlame);
		
	float fBrightness = smoothstep(1.0, 0.5, fClosestDist) * 2.0;
			
	float fHeightFade = (vClosestToFlame.y * 0.5 + 0.5);
	fBrightness *= clamp(dot(vClosestToFlame.xz, vClosestToFlame.xz) + fHeightFade, 0.0, 1.0);

	//return mix(vFlameColour1 * 32.0, vFlameColour2, 1.0 - fBrightness) * fBrightness;
    
    return BlackBody( 300.0 + pow(fBrightness, 0.8) * 600.0 );
}

vec3 GetFlareIntensity( const in vec3 vOrigin, const in vec3 vDir )
{
	vec3 vToFlame = GetLightPos() - vOrigin;

	
	float fClosestDot = dot(vDir, vToFlame);
	fClosestDot = max(fClosestDot, 0.0);
	
	vec3 vClosestPos = vOrigin + vDir * fClosestDot;
	vec3 vClosestToFlame = vClosestPos - GetLightPos();
	
	float fClosestDist = length(vClosestToFlame);
		
	float fBrightness = (1.0 / (fClosestDist + 1.0));	

	return vFlameColour1 * pow(fBrightness, 5.0);
}

void TraceRay( inout vec3 vOrigin, inout vec3 vDir, out vec3 vColour, inout vec3 vRemaining )
{	
    vec3 vLightPos = GetLightPos();
	vec2 vHit = Raycast(vOrigin, vDir);
	
	vec3 vHitPos = vOrigin + vDir * vHit.x;
	vec3 vHitNormal = GetSceneNormal(vHitPos);
	
	vec3 vAlbedo = vec3(0.0);
	vec3 vSpecR0 = vec3(0.0);
	float fSmoothness = 0.0;

	vec3 vEmissive = vec3(0.0);
	vec3 vGlow = GetFlameIntensity(vOrigin, vDir, vHit.x);

	if(vHit.x > 20.0)
	{
		vColour = vGlow + GetFlareIntensity(vOrigin, vDir);
		vColour *= vRemaining;
		vOrigin = vHitPos;
	}
	else
	{
		float fAmbientOcclusion = GetAmbientOcclusion(vHitPos, vHitNormal);
	
		
		if(vHit.y <= kMaterialWood)
		{
			vAlbedo = texture(iChannel2, vHitPos.xz * 0.25 ).rgb;
			vAlbedo = vAlbedo * vAlbedo;	
			
			fSmoothness = vAlbedo.r * vAlbedo.r * 0.1;
		}
		else
		if(vHit.y <= kMaterialGold)
		{
			vAlbedo = vec3(0.3, 0.1, 0.05);
			vSpecR0 = vec3(0.9, 0.5, 0.05);
			fSmoothness = 1.0;
		}
		else
		if(vHit.y <= kMaterialWax)
		{
			vAlbedo = vec3(0.9);
			vSpecR0 = vec3(0.01);
			
			float fDistanceThroughWax = GetDistanceWaxTop(vHitPos - vCandlestickPos - GetFlameWander() * 0.025);
			vEmissive = vFlameLightColour * (exp(fWaxExtinction * fDistanceThroughWax));
		}
		else
		if(vHit.y <= kMaterialWick)			
		{
			vAlbedo = vec3(0.01);
		}
		else
		if(vHit.y <= kMaterialChrome)			
		{
			vAlbedo = vec3(0.3);
			vSpecR0 = vec3(0.85);
			fSmoothness = 1.0;
		}
		else
		if(vHit.y <= kMaterialPaper)			
		{
			vAlbedo = vec3(0.9);
			vSpecR0 = vec3(0.0);
			fSmoothness = 0.0;
		}

				
		vec3 vDiffuseLight = SampleDiffuse(vHitNormal) * fAmbientOcclusion;
			
		vec3 vToLight = vLightPos - vHitPos;
		float fDistToLight = length(vToLight);
		vec3 vNormToLight = normalize(vToLight);
		
		float fDot = clamp(dot(vNormToLight, vHitNormal), 0.0, 1.0);
		
		float fShadow = RaycastShadow(vHitPos, vToLight, 1.0);
	
		// Fake shadow from candle
		fShadow *= smoothstep(0.4, 0.6, length(vToLight.xz) / max(vToLight.y, 0.01));

		fShadow = mix(0.1 + 0.15 * fAmbientOcclusion, 1.0, fShadow);
	
		vec3 vLightIntensity = vFlameLightColour * fDot * fShadow;
		vLightIntensity /= fDistToLight * fDistToLight;
		vDiffuseLight += vLightIntensity;
		
		vec3 vReflectDir = normalize(reflect(vDir, vHitNormal));
		
		vec3 vHalf = normalize(vReflectDir + -vDir);
		float fFresnelDot = clamp(1.0 - dot(vHalf, -vDir), 0.0, 1.0);	
		float fFresnel = pow(fFresnelDot, 5.0);
				
		vec3 vReflectFraction = vSpecR0 + (vec3(1.0) - vSpecR0) * fFresnel * fSmoothness;
	
		vColour = (vDiffuseLight * vAlbedo + vEmissive) * (vec3(1.0) - vReflectFraction);
		vColour += GetFlareIntensity(vOrigin, vDir);
		vColour += vGlow;
		vColour *= vRemaining;
		vRemaining *= vReflectFraction;
		vOrigin = vHitPos;
		vDir = vReflectDir;
	}
	
}

vec3 Tonemap( vec3 x )
{
    float a = 0.010;
    float b = 0.132;
    float c = 0.010;
    float d = 0.163;
    float e = 0.101;

    return ( x * ( a * x + b ) ) / ( x * ( c * x + d ) + e );
}
	
void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	vec2 vUV = fragCoord.xy / iResolution.xy;
	vec2 vWindow = vUV * 2.0 - 1.0;
	vWindow.x *= iResolution.x / iResolution.y;
	
	vec2 vMouse = iMouse.xy / iResolution.xy;
	
	float fHeading = 3.14 + (vMouse.x - 0.5) * 3.0;
	float fElevation = (vMouse.y - 0.5) + 0.15;
	float fCameraDistance = 3.0;
	
	if(iMouse.y <= 0.0)
	{
		fHeading = 3.0;
		fElevation = 0.25;
	}
	
	float fSinElevation = sin(fElevation);
	float fCosElevation = cos(fElevation);
	float fSinHeading = sin(fHeading);
	float fCosHeading = cos(fHeading);
	
	vec3 vCameraOffset;
	vCameraOffset.x = fSinHeading * fCosElevation;
	vCameraOffset.y = fSinElevation;
	vCameraOffset.z = fCosHeading * fCosElevation;
	
	vec3 vCameraPos = vec3(0.0, 2.5, -2.0);
	vCameraPos += vCameraOffset * fCameraDistance;

	vec3 vCameraTarget = vec3(-1.0, 2.0, 0.0);
	vec3 vForward = normalize(vCameraTarget - vCameraPos);
	vec3 vRight = normalize(cross(vec3(0.0, 1.0, 0.0), vForward));
	vec3 vUp = normalize(cross(vForward, vRight));
							  
	vec3 vDir = normalize(vWindow.x * vRight + vWindow.y * vUp + vForward * 2.0);
	
	vec3 vResult = vec3(0.0);
	
	vec3 vRemaining = vec3(1.0);
	for(int i=0; i<kMaxIter; i++)
	{
		vec3 vColour = vec3(0.0);
		
		TraceRay(vCameraPos, vDir, vColour, vRemaining);
		
		vResult += vColour;
	}
	
	{
		vec3 vColour = (SampleEnvironment(vDir));		
		//vColour += GetFlareIntensity(vOrigin, vDir);
		
		vResult += vColour * vRemaining;
	}	
	
	vec2 vCentreOffset = (vUV - 0.5) * 2.0;
	vResult.xyz *= 1.0 - dot(vCentreOffset, vCentreOffset) * 0.3;

	vResult.xyz = Tonemap( vResult.xyz * kExposure );
	
	fragColor = vec4(vResult,1.0);
}

void mainVR( out vec4 fragColor, in vec2 fragCoord, in vec3 fragRayOri, in vec3 fragRayDir )
{
    fragRayOri.z = -fragRayOri.z;
    fragRayDir.z = -fragRayDir.z;
    
    fragRayOri.y += 0.5;
    fragRayOri.z -= 0.25;
    
    fragRayOri *= 8.0;
    	
	vec3 vResult = vec3(0.0);
	
	vec3 vRemaining = vec3(1.0);
	for(int i=0; i<kMaxIter; i++)
	{
		vec3 vColour = vec3(0.0);
		
		TraceRay(fragRayOri, fragRayDir, vColour, vRemaining);
		
		vResult += vColour;
	}
	
	{
		vec3 vColour = (SampleEnvironment(fragRayDir));		
		//vColour += GetFlareIntensity(vOrigin, vDir);
		
		vResult += vColour * vRemaining;
	}	
    
 	vResult.xyz = Tonemap( vResult.xyz * kExposure );
   
    fragColor.rgb = vResult;
    fragColor.a = 1.0;
}