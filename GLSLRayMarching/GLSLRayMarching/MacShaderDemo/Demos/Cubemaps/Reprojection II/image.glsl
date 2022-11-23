// Reprojection II - @P_Malin

// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

#define FORCE_SHADOW
#define ENABLE_REFLECTION

struct C_Ray
{
    vec3 vOrigin;
    vec3 vDir;
};
	
#define kMaxDist 1000.0
#define kEpsilon 0.0001
	
void TraceSlab(const in C_Ray ray, const in vec3 vMin, const in vec3 vMax, const in vec3 vNormal, inout float fNear, inout float fFar)
{
	vec3 vMinOffset = vMin - ray.vOrigin;
	vec3 vMaxOffset = vMax - ray.vOrigin;

	// Project offset and dir
	float fMinOffset = dot(vMinOffset, vNormal);	
	float fMaxOffset = dot(vMaxOffset, vNormal);	
	
	float fDir = dot(ray.vDir, vNormal);
		
	if(abs(fDir) < kEpsilon)
	{
		// ray parallel to slab
		
		//if origin is not between slabs return false;
		if((fMinOffset > 0.0) || (fMaxOffset < 0.0))
		{
			fNear = kMaxDist;
			fFar = -kMaxDist;
		}
		
		// else this slab does not influence the result
	}
	else
	{
		// ray is not parallel to slab, calculate intersections
		
		float t0 = (fMinOffset) / fDir;
		float t1 = (fMaxOffset) / fDir;
		
		float fIntersectNear = min(t0, t1);
		float fIntersectFar = max(t0, t1);
		
		fNear = max(fNear, fIntersectNear); // track largest near
		fFar = min(fFar, fIntersectFar); // track smallest far
	}
}
	
float TraceBox( const in C_Ray ray, const in vec3 vCorner1, const in vec3 vCorner2 )
{
	vec3 vMin = min(vCorner1, vCorner2);
	vec3 vMax = max(vCorner1, vCorner2);
	
	float fNear = -kMaxDist;
	float fFar = kMaxDist;
	
	TraceSlab(ray, vMin, vMax, vec3(1.0, 0.0, 0.0), fNear, fFar);
	TraceSlab(ray, vMin, vMax, vec3(0.0, 1.0, 0.0), fNear, fFar);
	TraceSlab(ray, vMin, vMax, vec3(0.0, 0.0, 1.0), fNear, fFar);
	
	if(fNear > fFar)
	{
		return kMaxDist;
	}
	
	if(fFar < 0.0)
	{
		return kMaxDist;
	}
	
	return fNear;
}

vec3 Project( vec3 a, vec3 b )
{
	return a - b * dot(a, b);
}

float TraceCylinder( const in C_Ray ray, vec3 vPos, vec3 vDir, float fRadius, float fLength )
{	
	vec3 vOffset = vPos - ray.vOrigin;
	
	vec3 vProjOffset = Project(vOffset, vDir);
	vec3 vProjDir = Project(ray.vDir, vDir);
	float fProjScale = length(vProjDir);
	vProjDir /= fProjScale;
	
	// intersect circle in projected space
	
	float fTClosest = dot(vProjOffset, vProjDir);
	
	vec3 vClosest = vProjDir * fTClosest;
	float fDistClosest = length(vClosest - vProjOffset);
	if(fDistClosest > fRadius)
	{
		return kMaxDist;
	}
	float fHalfChordLength = sqrt(fRadius * fRadius - fDistClosest * fDistClosest);
	float fTIntersectMin = (fTClosest - fHalfChordLength) / fProjScale;
	float fTIntersectMax = (fTClosest + fHalfChordLength) / fProjScale;
	
	// cap cylinder ends
	TraceSlab(ray, vPos, vPos + vDir * fLength, vDir, fTIntersectMin, fTIntersectMax);

	if(fTIntersectMin > fTIntersectMax)
	{
		return kMaxDist;
	}
	
	if(fTIntersectMin < 0.0)
	{
		return kMaxDist;
	}
	
	return fTIntersectMin;		
}
			   

float TraceFloor( const in C_Ray ray, const in float fHeight )
{
	if(ray.vOrigin.y < fHeight)
	{
		return 0.0;
	}
	
	if(ray.vDir.y > 0.0)
	{
		return kMaxDist;
	}
	
	float t = (fHeight - ray.vOrigin.y) / ray.vDir.y;
	
	return max(t, 0.0);
}

float TracePillar( const in C_Ray ray, in vec3 vPos )
{
	vPos.y = -1.0;
	float fRadius = 0.3;
	float fDistance = TraceCylinder( ray, vPos, vec3(0.0, 1.0, 0.0), fRadius, 10.0);
	float fBaseSize = 0.4;
	
	vec3 vBaseMin = vec3(-fBaseSize, 0.0, -fBaseSize);
	vec3 vBaseMax = vec3(fBaseSize, 0.8, fBaseSize);
	fDistance = min( fDistance, TraceBox( ray, vPos + vBaseMin, vPos + vBaseMax) );
	
	float fTopSize = 0.4;
	vec3 vTopMin = vec3(-fTopSize, 5.6, -fTopSize);
	vec3 vTopMax = vec3(fTopSize, 7.0, fTopSize);
	fDistance = min( fDistance, TraceBox( ray, vPos + vTopMin, vPos + vTopMax) );
	
	return fDistance;	
}

float TraceColumn( const in C_Ray ray, vec3 vPos )
{
	vec3 vColumnMin = vec3(-0.84, -10.0, -0.4);
	vec3 vColumnMax = - vColumnMin;
	return TraceBox( ray, vPos + vColumnMin, vPos + vColumnMax );	
}

float fBuildingMin = -90.0;
float fBuildingMax = 50.0;

float TraceBuildingSide( const in C_Ray ray )
{
	float fDistance = kMaxDist;
	
	float fStepHeight = 0.14;
	float fStepDepth = 0.2;
	float fStepStart = 7.5;
	fDistance = min(fDistance, TraceBox( ray, vec3(fBuildingMin, -1.5 + fStepHeight * 0.0, fStepStart + fStepDepth * 0.0), vec3(fBuildingMax, -1.5 + fStepHeight * 1.0, fStepStart + 20.0) ));
	fDistance = min(fDistance, TraceBox( ray, vec3(fBuildingMin, -1.5 + fStepHeight * 1.0, fStepStart + fStepDepth * 1.0), vec3(fBuildingMax, -1.5 + fStepHeight * 2.0, fStepStart + 20.0) ));
	fDistance = min(fDistance, TraceBox( ray, vec3(fBuildingMin, -1.5 + fStepHeight * 2.0, fStepStart + fStepDepth * 2.0), vec3(fBuildingMax, -1.5 + fStepHeight * 3.0, fStepStart + 20.0) ));
	fDistance = min(fDistance, TraceBox( ray, vec3(fBuildingMin, -1.5 + fStepHeight * 3.0, fStepStart + fStepDepth * 3.0), vec3(fBuildingMax, -1.5 + fStepHeight * 4.0, fStepStart + 20.0) ));

	float x = -2.0;
	for(int i=0; i<5; i++)
	{
		vec3 vBase = vec3(x * 11.6, 0.0, 0.0);
		x += 1.0;
		
		fDistance = min(fDistance, TraceColumn(ray, vBase + vec3(0.0, 0.0, 8.5)));
		
		
		fDistance = min(fDistance, TracePillar(ray, vBase + vec3(-4.1, 0.0, 8.5)));	
		fDistance = min(fDistance, TracePillar(ray, vBase + vec3(4.0, 0.0, 8.5)));
	}
	

	float fBackWallDist = 9.5;
	float fBuildingHeight = 100.0;
	fDistance = min(fDistance, TraceBox( ray, vec3(fBuildingMin, -3.0, fBackWallDist), vec3(fBuildingMax, fBuildingHeight, fBackWallDist + 10.0) ));

	float fBuildingTopDist = 8.1;
	float fCeilingHeight = 4.7;
	fDistance = min(fDistance, TraceBox( ray, vec3(fBuildingMin, fCeilingHeight, fBuildingTopDist), vec3(fBuildingMax, fBuildingHeight, fBuildingTopDist + 10.0) ));

	float fRoofDistance = 6.0;
	float fRoofHeight = 21.0;
	fDistance = min(fDistance, TraceBox( ray, vec3(fBuildingMin, fRoofHeight, fRoofDistance), vec3(fBuildingMax, fRoofHeight + 0.2, fRoofDistance + 10.0) ));	
	
	return fDistance;
}
	
float TraceScene( const in C_Ray ray )
{        
    float fDistance = kMaxDist;
        
	float fFloorHeight = -1.5;
	fDistance = min(fDistance, TraceFloor( ray, fFloorHeight ));
	
	// end of row
	fDistance = min(fDistance, TraceBox( ray, vec3(fBuildingMax, fFloorHeight, -100.0), vec3(fBuildingMax+1.0, 100.0, 100.0) ));
	fDistance = min(fDistance, TraceBox( ray, vec3(fBuildingMin, fFloorHeight, -100.0), vec3(fBuildingMin-1.0, 100.0, 100.0) ));
		
	fDistance = min(fDistance, TraceBuildingSide( ray ));
	
	C_Ray ray2;					
	ray2.vOrigin = ray.vOrigin * vec3(1.0, 1.0, -1.0);
	ray2.vDir = ray.vDir * vec3(1.0, 1.0, -1.0);
	ray2.vOrigin.z -= 0.3;
	fDistance = min(fDistance, TraceBuildingSide( ray2 ));
					
	return fDistance;
}
               

void GetCameraRay( const in vec3 vPos, const in vec3 vForwards, const in vec3 vWorldUp, const in vec2 px, out C_Ray ray)
{
    vec2 vUV = ( px / iResolution.xy );
    vec2 vViewCoord = vUV * 2.0 - 1.0;	

	vViewCoord.x *= iResolution.x / iResolution.y;
	vViewCoord.y *= -1.0;

    ray.vOrigin = vPos;

    vec3 vRight = normalize(cross(vWorldUp, vForwards));
    vec3 vUp = cross(vRight, vForwards);
    
	vViewCoord *= 0.5;
	
    ray.vDir = normalize( vRight * vViewCoord.x + vUp * vViewCoord.y + vForwards);    
}

void GetCameraRayLookat( const in vec3 vPos, const in vec3 vCameraTarget, const in vec2 px, out C_Ray ray)
{
	vec3 vForwards = normalize(vCameraTarget - vPos);
	vec3 vUp = vec3(0.0, 1.0, 0.0);

	GetCameraRay(vPos, vForwards, vUp, px, ray);
}

void GetCameraPosAndTarget( float fCameraIndex, out vec3 vCameraPos, out vec3 vCameraTarget )
{
	float fCameraCount = 6.0;
	float fCameraIndexModCount = mod(fCameraIndex, fCameraCount);

	if(fCameraIndexModCount < 0.5)
	{
		vCameraPos = vec3(0.0, 0.0, 0.0);
		vCameraTarget = vec3(0.0, 0.0, 8.0);
	}
	else if(fCameraIndexModCount < 1.5)
	{
		vCameraPos = vec3(-3.0, 0.0, -5.0);
		vCameraTarget = vec3(3.0, -5.0, 5.0);
	}
	else if(fCameraIndexModCount < 2.5)
	{
		vCameraPos = vec3(8.0, 0.0, 0.0);
		vCameraTarget = vec3(-10.0, 0.0, 0.0);
	}
	else if(fCameraIndexModCount < 3.5)
	{
		vCameraPos = vec3(8.0, 3.0, -3.0);
		vCameraTarget = vec3(-4.0, -2.0, 0.0);
	}
	else if(fCameraIndexModCount < 4.5)
	{
		vCameraPos = vec3(8.0, 5.0, 5.0);
		vCameraTarget = vec3(-4.0, 2.0, -5.0);
	}
	else
	{
		vCameraPos = vec3(-10.0, 3.0, 0.0);
		vCameraTarget = vec3(4.0, 4.5, -5.0);
	}
}

vec3 BSpline( const in vec3 a, const in vec3 b, const in vec3 c, const in vec3 d, const in float t)
{
	const mat4 mSplineBasis = mat4( -1.0,  3.0, -3.0, 1.0,
							         3.0, -6.0,  0.0, 4.0,
							        -3.0,  3.0,  3.0, 1.0,
							         1.0,  0.0,  0.0, 0.0) / 6.0;	
	
	float t2 = t * t;
	vec4 T = vec4(t2 * t, t2, t, 1.0);
	
	vec4 vCoeffsX = vec4(a.x, b.x, c.x, d.x);
	vec4 vCoeffsY = vec4(a.y, b.y, c.y, d.y);
	vec4 vCoeffsZ = vec4(a.z, b.z, c.z, d.z);
	
	vec4 vWeights = T * mSplineBasis;
	
	vec3 vResult;
	
	vResult.x = dot(vWeights, vCoeffsX);
	vResult.y = dot(vWeights, vCoeffsY);
	vResult.z = dot(vWeights, vCoeffsZ);
	
	return vResult;
}

void GetCamera(out vec3 vCameraPos, out vec3 vCameraTarget)
{
	float fCameraGlobalTime = iTime * 0.5;
	float fCameraTime = fract(fCameraGlobalTime);
	float fCameraIndex = floor(fCameraGlobalTime);
	
	vec3 vCameraPosA;
	vec3 vCameraTargetA;
	GetCameraPosAndTarget(fCameraIndex, vCameraPosA, vCameraTargetA);
	
	vec3 vCameraPosB;
	vec3 vCameraTargetB;
	GetCameraPosAndTarget(fCameraIndex + 1.0, vCameraPosB, vCameraTargetB);
	
	vec3 vCameraPosC;
	vec3 vCameraTargetC;
	GetCameraPosAndTarget(fCameraIndex + 2.0, vCameraPosC, vCameraTargetC);
	
	vec3 vCameraPosD;
	vec3 vCameraTargetD;
	GetCameraPosAndTarget(fCameraIndex + 3.0, vCameraPosD, vCameraTargetD);
	
	vCameraPos = BSpline(vCameraPosA, vCameraPosB, vCameraPosC, vCameraPosD, fCameraTime);
	vCameraTarget = BSpline(vCameraTargetA, vCameraTargetB, vCameraTargetC, vCameraTargetD, fCameraTime);
}

vec3 SceneColor( C_Ray ray )
{
    float fHitDist = TraceScene(ray);
	vec3 vHitPos = ray.vOrigin + ray.vDir * fHitDist;
	
	vec3 vResult = texture(iChannel0, vHitPos.xyz).rgb;	
	vResult = vResult * vResult;
	
	#ifdef FORCE_SHADOW
	if( abs(vHitPos.z) > 9.48)
	{
		if( abs(vHitPos.x) < 20.0)
		{
			float fIntensity = length(vResult);
			
			fIntensity = min(fIntensity, 0.05);
			
			vResult = normalize(vResult) * fIntensity;
		}
	}
	#endif	
	
	#ifdef ENABLE_REFLECTION
	if(vHitPos.y < -1.4)
	{
		float fDelta = -0.1;
		float vSampleDx = texture(iChannel0, vHitPos.xyz + vec3(fDelta, 0.0, 0.0)).r;	
		vSampleDx = vSampleDx * vSampleDx;

		float vSampleDy = texture(iChannel0, vHitPos.xyz + vec3(0.0, 0.0, fDelta)).r;	
		vSampleDy = vSampleDy * vSampleDy;
		
		vec3 vNormal = vec3(vResult.r - vSampleDx, 2.0, vResult.r - vSampleDy);
		vNormal = normalize(vNormal);
		
		vec3 vReflect = reflect(ray.vDir, vNormal);
		
		float fDot = clamp(dot(-ray.vDir, vNormal), 0.0, 1.0);
		
		float r0 = 0.1;
		float fSchlick =r0 + (1.0 - r0) * (pow(1.0 - fDot, 5.0));
		
		vec3 vResult2 = texture(iChannel1, vReflect).rgb;	
		vResult2 = vResult2 * vResult2;
		float shade = smoothstep(0.3, 0.0, vResult.r);
		vResult += shade * vResult2 * fSchlick * 5.0;
	}
	#endif
	
	if(iMouse.z > 0.0)
	{
		vec3 vGrid =  step(vec3(0.9), fract(vHitPos + 0.01));
		float fGrid = min(dot(vGrid, vec3(1.0)), 1.0);
		vResult = mix(vResult, vec3(0.0, 0.0, 1.0), fGrid);
	}
	
	return sqrt(vResult);    
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    C_Ray ray;

	vec3 vResult = vec3(0.0);
	
	vec2 vMouse = iMouse.xy / iResolution.xy;	
	
	vec3 vCameraPos;
	vec3 vCameraTarget;
	
	GetCamera(vCameraPos, vCameraTarget);		

	GetCameraRayLookat( vCameraPos, vCameraTarget, fragCoord, ray);

    fragColor.rgb = SceneColor( ray );
    fragColor.a = 1.0;
}

void mainVR( out vec4 fragColor, in vec2 fragCoord, in vec3 fragRayOri, in vec3 fragRayDir )
{
    C_Ray ray;
 
    ray.vOrigin = fragRayOri * 10.0;
    ray.vOrigin.y += 3.0;
    ray.vDir = fragRayDir;
    
    fragColor.rgb = SceneColor( ray );
    fragColor.a = 1.0;
}