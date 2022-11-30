/*--------------------------------------------------------------------------------------
License CC0 - http://creativecommons.org/publicdomain/zero/1.0/
To the extent possible under law, the author(s) have dedicated all copyright and related and neighboring rights to this software to the public domain worldwide. This software is distributed without any warranty.
----------------------------------------------------------------------------------------

I tried to do lots of different lighting features with this. It has ambient occlusion.
I did a traced shadow for sky light, but it took too much code space, so I faked it. (#define)
There is bounced light from where the sun rays hit.
There is light from the stained glass dome.
There are glowy rays and god rays.
I kept running into code size limits on this one. I probably would have gone forever
if it wasn't for those damn "unknown error" things when the code gets too big.
I tried to do refraction in the crystal, but hit code size limits.
-Otavio Good
*/
#define MANUAL_CAMERA 0
#define TRACED_SKY_SHADOWS 0

float PI=3.14159265;
vec3 sunColOrig = vec3(255.0, 208.0, 100.0) / 255.0;
vec3 environmentSphereColor = vec3(0.3001, 0.501, 0.901);
vec3 environmentGroundColor = vec3(0.4001, 0.25, 0.1) * 0.25;

float sparkle;
float sinking;
float marchingMultplier = 1.0;
float glowDist;
float globalRadial;
float shadow;
float localTime;
vec3 sunCol;
float rotateGem;

float distFromSphere;
vec3 normal;
vec3 texBlurry;

float material;

vec3 saturate(vec3 a)
{
	return clamp(a, 0.0, 1.0);
}
vec2 saturate(vec2 a)
{
	return clamp(a, 0.0, 1.0);
}
float saturate(float a)
{
	return clamp(a, 0.0, 1.0);
}

float SmoothMix(float a, float b, float x)
{
	float t = x*x*(3.0 - 2.0*x);
	return mix(a, b, t);
}
vec3 RotateX(vec3 v, float rad)
{
	float cos = cos(rad);
	float sin = sin(rad);
	//if (RIGHT_HANDED_COORD)
	return vec3(v.x, cos * v.y + sin * v.z, -sin * v.y + cos * v.z);
	//else return new float3(x, cos * y - sin * z, sin * y + cos * z);
}
vec3 RotateY(vec3 v, float rad)
{
	float cos = cos(rad);
	float sin = sin(rad);
	//if (RIGHT_HANDED_COORD)
	return vec3(cos * v.x - sin * v.z, v.y, sin * v.x + cos * v.z);
	//else return new float3(cos * x + sin * z, y, -sin * x + cos * z);
}
vec3 RotateZ(vec3 v, float rad)
{
	float cos = cos(rad);
	float sin = sin(rad);
	//if (RIGHT_HANDED_COORD)
	return vec3(cos * v.x + sin * v.y, -sin * v.x + cos * v.y, v.z);
}

// makes a thick line and passes back gray in x and derivates for lighting in yz
vec3 ThickLine(vec2 uv, vec2 posA, vec2 posB, float radiusInv)
{
	vec2 dir = posA - posB;
	float dirLen = length(dir);
	vec2 dirN = normalize(dir);
	float dotTemp = clamp(dot(uv - posB, dirN), 0.0, dirLen);
	vec2 proj = dotTemp * dirN + posB;
	float d1 = distance(uv, proj);
	vec2 derivative = (uv - proj);

	float finalGray = saturate(1.0 - d1 * radiusInv);
	// multiply derivative by gray so it smoothly fades out at the edges.
	return vec3(finalGray, derivative * finalGray);
}

// makes a rune in the 0..1 uv space. Seed is which rune to draw.
// passes back gray in x and derivates for lighting in yz
vec3 Rune(vec2 uv, vec2 seed)
{
	vec3 finalLine = vec3(0.0, 0.0, 0.0);
	for (int i = 0; i < 4; i++)	// number of strokes
	{
		// generate seeded random line endPoints - just about any texture should work.
		// Hopefully this randomness will work the same on all GPUs (had some trouble with that)
		vec2 posA = texture(iChannel1, floor(seed+0.5) / iChannelResolution[1].xy).xy;
		vec2 posB = texture(iChannel1, floor(seed+1.5) / iChannelResolution[1].xy).xy;
		seed += 2.0;
		// expand the range and mod it to get a nicely distributed random number - hopefully. :)
		posA = fract(posA * 128.0);
		posB = fract(posB * 128.0);
		// each rune touches the edge of its box on all 4 sides
		if (i == 0) posA.y = 0.0;
		if (i == 1) posA.x = 0.999;
		if (i == 2) posA.x = 0.0;
		if (i == 3) posA.y = 0.999;
		// snap the random line endpoints to a grid 2x3
		vec2 snaps = vec2(2.0, 3.0);
		posA = (floor(posA * snaps) + 0.5) / snaps;	// + 0.5 to center it in a grid cell
		posB = (floor(posB * snaps) + 0.5) / snaps;
		//if (distance(posA, posB) < 0.0001) continue;	// eliminate dots.

		// Dots (degenerate lines) are not cross-GPU safe without adding 0.001 - divide by 0 error.
		vec3 tl = ThickLine(uv, posA, posB + 0.001, 10.0);
		if (tl.x > finalLine.x) finalLine = tl;
	}
	return finalLine.xyz;
}

// k should be negative. -4.0 works nicely.
float smin(float a, float b, float k)
{
	// I'm guessing that base 2 operations are the fastest.
	return log2(exp2(k*a)+exp2(k*b))/k;
}

vec3 GetSunColorReflection(vec3 rayDir, vec3 sunDir)
{
	vec3 localRay = normalize(rayDir);
	float sunIntensity = 1.0 - (dot(localRay, sunDir) * 0.5 + 0.5);
	//sunIntensity = (float)Math.Pow(sunIntensity, 14.0);
	sunIntensity = max(0.0, 0.01 / sunIntensity - 0.025);
	sunIntensity = min(sunIntensity, 40000.0);
	vec3 ground = mix(environmentGroundColor, environmentSphereColor,
					  pow(abs(localRay.y), 0.35)*sign(localRay.y) * 0.5 + 0.5);
	return ground + sunCol * sunIntensity;
}

float dSphere(vec3 p, float rad)
{
	return length(p) - rad;
}

float dBox(vec3 pos, vec3 b)
{
	return length(max(abs(pos)-(b),0.0));
}

float dBoxSlant(vec3 p, vec3 b)
{
	float size = b.x;
	float f = length(max(abs(p)-(b),0.0));
	//float f = length(max(abs(p.x)+abs(p.z)-(b),0.0));
	//f = max(f, p.y*0.5 + abs(p.x) + abs(p.z) - size * 0.995);
	return f;
}

float sdBox(vec3 p, vec3 b)
{
	vec3 d = abs(p) - b;
	return min(max(d.x,max(d.y,d.z)),0.0) + length(max(d,0.0));
}
float dBoxSigned(vec3 p)
{
	float b = 1.0;
	vec3 b2 = vec3(6.0, 2.0, 2.0);
	vec3 center = vec3(0, -2.0, 0.0);
	vec3 d = abs(p - center) - b2;//*abs(cos(p.y + 0.5));
	return min(max(d.x,max(d.y,d.z)),0.0) + length(max(d,0.0));
}

float dFloor(vec3 p)
{
	return p.y + 1.0;
}

float sdColumn( vec3 p, vec3 c )
{
	float cyl = length(p.xz-c.xy)-c.z;// + abs(p.y);
	cyl -= cos(p.y*2.0)*0.045;
	float a = atan(p.x - c.x, p.z - c.y);
	a /= 2.0*PI;
	float subs = 48.0;
	a *= subs;
	//cyl *= pow(sin(a), 0.5) * 0.925 + 1.0;
	cyl += abs(sin(a)) * 0.015;

	cyl = max(cyl, p.y - 2.4);
	cyl = min(cyl, dBox(p + vec3(0.0, 1.0, 0.0), vec3(0.3, 0.2, 0.3)));
	cyl = smin(cyl, dBoxSlant(RotateY(p, PI/4.0) + vec3(0.0, -2.3, 0.0), vec3(0.3, 0.15, 0.3)), -24.0);
	//cyl = min(cyl, dBox(RotateY(p, PI/4.0) + vec3(0.0, -2.3, 0.0), vec3(0.3, 0.15, 0.3)));
	return cyl;
}

float sdCapsule( vec3 p, vec3 a, vec3 b, float r )
{
    vec3 pa = p - a, ba = b - a;
    float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
    return length( pa - ba*h ) - r;
}

float length16(vec2 v)
{
	return pow(pow(abs(v.x),16.0) + pow(abs(v.y), 16.0), 1.0/16.0);
	//return pow((pow(v.x,16.0) + pow(v.y, 16.0)), (1.0/16.0));
}
float sdTorusBricks( vec3 p, vec2 t, vec3 center, float subs )
{
	p -= center;
	float a = globalRadial;// + PI/6.0;// atan(p.x, p.z);
	a = pow(abs(sin(a*subs)), 0.25);
	//a = mod(a,PI*2.0) - 0.5;
	//a = a *0.025 + 0.975;
	a = a *0.2 + 0.8;
	vec2 q = vec2(length(p.xz)-t.x,p.y);
	return length16(q)-t.y*a;
}
float sdTorusArch( vec3 p, vec2 t, vec3 center, float subs )
{
	p -= center;
	float a = atan(p.y, p.z);
	a = pow(abs(sin(a*subs)), 0.25);
	//a = mod(a,PI*2.0) - 0.5;
	//a = a *0.025 + 0.975;
	a = a *0.25 + 0.75;
	p.y -= cos(p.y)*0.4;
	vec2 q = vec2(length(p.yz)-t.x,p.x);
	return length16(q)-t.y*a;
}

float sdPedestal( vec3 p, vec2 h )
{
	p.y += 0.5 + sinking*0.2;
    vec3 q = abs(p);
    return max(q.y-h.y,max(q.z+q.x*0.57735,q.x*1.1547)-(h.x*(2.35 - p.y)));
}

float matMin(float a, float b, float matNum)
{
	if (a < b)
	{
		//material = 0.0;
		return a;
	}
	else
	{
		material = matNum;
		return b;
	}
}

// This makes the stained glass windows in the dome.
float dTiles(vec3 p)
{
	float subs = 16.0;
	float final = length(p) - 2.2;
	float a = globalRadial;// atan(p.x, p.z);
	a /= 2.0*PI;
	a *= subs;
	a = abs((fract(a) - 0.5))*2.0;	// triangle wave from 0.0 to 1.0
	a -= 0.15;
	a *= 6.0;
	a = max(0.0, a);
	a = min(0.75, a);

	float b = atan(length(p.xz), p.y);
	b /= 2.0*PI;
	b *= subs;
	b = abs((fract(b) - 0.5))*2.0;	// triangle wave from 0.0 to 1.0
	b -= 0.15;
	b *= 6.0;
	b = max(0.0, b);
	b = min(0.75, b);
	
	a = a*b;

	a = a *0.2 + 0.8;
	b = b *0.2 + 0.8;
	
	final = final - a;
	final = max(final, 0.5-p.y);
	final = min(final, length(p.xz) - 0.5);	// oculus - cylinder in middle
	return final/1.414;
}

float GemCut(vec3 p)
{
	float size = 0.5;
	float f = length(p) - size;
	if (f <= 1.0)
	{
		marchingMultplier = 0.65;
		f = max(f, p.y - size * 0.25);
		
		f = max(f, p.y + max(abs(p.x), abs(p.z)) - size * 0.7);
		
		f = max(f, -p.y + max(abs(p.x), abs(p.z)) - size * 0.6);
		//f = max(f, -p.y + p.x - size * 0.6);
		//f = max(f, -p.y - p.x - size * 0.6);
		//f = max(f, -p.y + p.z - size * 0.6);
		//f = max(f, -p.y - p.z - size * 0.6);

		f = max(f, p.y + abs(p.x) + abs(p.z) - size * 0.95);
		//f = max(f, p.y + p.x + p.z - size * 0.95);
		//f = max(f, p.y - p.x + p.z - size * 0.95);
		//f = max(f, p.y - p.x - p.z - size * 0.95);
		//f = max(f, p.y + p.x - p.z - size * 0.95);

		f = max(f, -p.y + abs(p.x) + abs(p.z) - size * 0.85);
		//f = max(f, -p.y + p.x + p.z - size * 0.85);
		//f = max(f, -p.y - p.x + p.z - size * 0.85);
		//f = max(f, -p.y - p.x - p.z - size * 0.85);
		//f = max(f, -p.y + p.x - p.z - size * 0.85);
	} else marchingMultplier = 1.0;
	return f;
}

float GenSwirl(vec3 p, float anim)
{
	vec2 spin = vec2(sin(p.y*1.75-anim), cos(p.y*1.75 - anim));
	float swirl = length(p.xz + spin*0.2) - 0.05;
	swirl = max(swirl, p.y - 5.25);
	swirl = max(swirl, p.y - fract(anim)*10.0 + 2.0);
	swirl = max(swirl, -(p.y - fract(anim)*10.0 + 5.0));
	return swirl;
}

float DistanceToObject(vec3 p)
{
	globalRadial = atan(p.x, p.z);
	// set up repeating spaces for pillars and arches
	vec3 c = vec3(1.0, 1.0, 1.0)* 4.0;
	float c2 = 5.2;
	vec3 q = mod(p,c)-0.5*c;
	float q2 = mod(p.x,c2)-0.5*c2;
	vec3 p2 = vec3(q.x, p.y, q.z);
	vec3 p3 = vec3(q2, p.y, p.z);

	float final = -sdCapsule(p, vec3(0.0,-0.5,0.0), vec3(0.0,2.25,0.0), 3.0);
	// This if condition is for a culling speedup and a cool bevel effect on the ceiling tiles.
	if (final < 0.01) final = max(final, -dTiles(p + vec3(0.0, -2.25, 0.0)));
	final = min(final, sdTorusBricks(p, vec2(2.75, 0.25), vec3(0.0, -0.795, 0.0), 12.0));
	final = max(final, -sdCapsule(p, vec3(-6.0,0.0,0.0), vec3(6.0,0.0,0.0), 2.0));
	//final = max(final, -sdCapsule(p, vec3(0.0,0.0,-16.0), vec3(0.0,0.0,16.0), 2.0));
	final = max(final, -dBoxSigned(p));
	//final = max(final, -sdCapsule(p, vec3(0.0,0.0,0.0), vec3(0.0,5.5,0.0), 0.5));//oculus
	final = max(final, p.y - 5.3);	// open the sky
	//final = max(final, sdCapsule(p, vec3(0.0,-0.5,0.0), vec3(0.0,0.5,0.0), 3.05));
	//final = max(final, -dSphere(p2, 0.08));
	final = min(final, sdColumn(p2, vec3(0.0, 0.0, 0.25)));
	//final = max(final, -sdBox(p - vec3(0.0,0.5,0.0), vec3(0.5, 1.0, 3.5)));

	final = min(final, sdTorusBricks(p, vec2(2.75, 0.25), vec3(0.0, 2.7, 0.0), 8.0));
	final = min(final, sdTorusBricks(p, vec2(0.75, 0.25), vec3(0.0, -1.0, 0.0), 3.0));
	final = min(final, sdTorusArch(p3, vec2(2.125, 0.3), vec3(0.0, 0.1, 0.0), 12.0));
	//final = min(final, sdTorusArch(p, vec2(2.125, 0.3), vec3(2.6, -0.1, 0.0), 6.0));
	//final = min(final, sdTorusArch(p, vec2(2.125, 0.3), vec3(-2.6, -0.1, 0.0), 6.0));
	final = min(final, dFloor(p));
	material = 0.0;

	// rotate the gem and light rays.
	vec3 pr = RotateY(p, rotateGem);
	// mirror light rays in each axis.
	if (pr.x < 0.0) pr.xz = -pr.xz;
	vec3 pr2 = pr;
	if (pr2.z < 0.0) pr2.xz = -pr2.xz;
	// glow rays
	if ((sparkle > 0.0) && (shadow != 1000000.0))
	{
		vec2 dir = vec2(1.0, 0.0);
		float rad = 0.04*max(0.0, sparkle - 0.2);
		float tempGlow = sdCapsule(pr, vec3(dir.x*0.25, 0.9 + sparkle, dir.y*0.25),
							   vec3(dir.x*3.0, 1.8 + sparkle, dir.y*3.0), rad)+saturate(0.6-sparkle);
		dir = vec2(0.0, 1.0);
		tempGlow = min(tempGlow, sdCapsule(pr2, vec3(dir.x*0.25, 0.9 + sparkle, dir.y*0.25),
							   vec3(dir.x*3.0, 1.8 + sparkle, dir.y*3.0), rad)+saturate(0.25-sparkle) );
		//dir = vec2(-1.0, 0.0);
		//tempGlow = min(tempGlow, sdCapsule(pr, vec3(dir.x*0.25, 0.9 + sparkle, dir.y*0.25),
		//					   vec3(dir.x*2.65, 1.7 + sparkle, dir.y*2.65), rad)+saturate(0.8-sparkle));
		//dir = vec2(0.0, -1.0);
		//tempGlow = min(tempGlow, sdCapsule(pr, vec3(dir.x*0.25, 0.9 + sparkle, dir.y*0.25),
		//					   vec3(dir.x*2.65, 1.7 + sparkle, dir.y*2.65), rad));
		//float len = length(p.xz)*0.5+0.5;
		//tempGlow = min(tempGlow, sdCapsule(pr, vec3(0.0, 1.0 + sparkle, 0.0),
		//					   vec3(0.0, -12.7, 0.0), rad*2.0)+saturate(0.25-sparkle) );
		// vertical glow from the pedestal to the crystal. capped cylinder.
		tempGlow = min(tempGlow, max(length(p.xz) - rad*2.0, p.y - 0.6 - sparkle));
		glowDist += 1.5*sparkle / max(0.1, tempGlow*tempGlow);
		final = matMin(final, tempGlow, 3.0);
	}
	float spirits = max(0.0, sinking - 7.0);
	float tempGlow2 = length(p.xyz - vec3(0.0,-0.95,0.0)) - 0.015 - pow(spirits, 1.5)*0.1;
	if ((spirits > 0.0) && (shadow != 1000000.0))
	{
		float anim = spirits - 2.0;
		float swirl = GenSwirl(p, anim);
		swirl = min(swirl, GenSwirl(p, anim+1.4));
		swirl = min(swirl, GenSwirl(p, anim+2.8));
		swirl = min(swirl, GenSwirl(p, anim+4.6));
		swirl = max(swirl, p.y-anim*3.0);
		tempGlow2 = smin(tempGlow2, swirl, -4.0);
		final = matMin(final, swirl, 3.0);

		glowDist += 1.5*sinking*0.1 / max(0.1, tempGlow2 * tempGlow2);
		glowDist *= min(1.0, spirits);
		final = matMin(final, tempGlow2, 3.0);
	}

	final = matMin(final, sdPedestal(p, vec2(0.25, 1.0)), 2.0);	// pedestal

	final = matMin(final, GemCut(pr - vec3(0, 0.8 + sparkle - sinking*0.2, 0)), 1.0);	// Gem

	return final;
}

vec4 tex3d(vec3 pos, vec3 normal)
{
	// loook up brick texture, blended across xyz axis based on normal.
	vec4 texX = texture(iChannel0, pos.yz);
	vec4 texY = texture(iChannel0, pos.xz);
	vec4 texZ = texture(iChannel0, pos.xy);
	vec4 tex = mix(texX, texZ, abs(normal.z));
	tex = mix(tex, texY, abs(normal.y));//.zxyw;
	return tex;
}

// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------
void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	localTime = fract((iTime)/54.0)*54.0;//mod(iTime+30.0, 55.0);	// repeat anim after this many seconds.
	sinking = localTime - 30.0;//clamp(localTime - 30.0, 0.0, 16.5);	// start and end the sinking of the pedestal
	if (sinking < 0.0) sinking = 0.0;// mac/chrome/nvidia bug didn't let me use max. :(
	vec2 uv = fragCoord.xy/iResolution.xy * 2.0 - 1.0;// - 0.5;

	// Camera up vector.
	vec3 camUp=vec3(0,1,0); // vuv

	vec3 shake = texture(iChannel3, vec2(localTime * 1.372, 0.0)).xyz*0.04 * saturate(sinking);
	// Camera lookat.
#if MANUAL_CAMERA
	vec3 camLookat=vec3(0,1.0,0);	// vrp
	vec3 camPos=vec3(2.7, 2.7, 2.7);

	if (localTime < 5.0)
	{
		//camLookat.y = mix(3.0, 1.0, saturate(localTime*0.2));
		//camPos.x = smoothstep(0.0, 2.75, saturate(localTime*0.2));
	}

	float mx=iMouse.x/iResolution.x*PI*2.0;// + iTime * 0.1;
	float my=-iMouse.y/iResolution.y*10.0;// + sin(iTime * 0.3)*0.2+0.2;//*PI/2.01;
	camPos=vec3(cos(my)*cos(mx),sin(my),cos(my)*sin(mx))*camPos; 	// prp
#else
	vec3 camLookat=vec3(0,1.0,0);	// vrp
	vec3 camPos=vec3(0.0, 0.0, 0.0);
	float firstTimer = saturate(localTime * 0.09);
	camPos.x = SmoothMix(-3.5, 2.6, firstTimer);
	camPos.z = pow(abs(sin(firstTimer*PI)), 3.0)*2.0;
	camPos.z -= firstTimer;

#endif

	camLookat += shake;
	camPos += shake;

	// Camera setup.
	vec3 camVec=normalize(camLookat - camPos);//vpn
	vec3 sideNorm=normalize(cross(camUp, camVec));	// u
	vec3 upNorm=cross(camVec, sideNorm);//v
	vec3 worldFacing=(camPos + camVec);//vcv
	vec3 worldPix = worldFacing + uv.x * sideNorm * (iResolution.x/iResolution.y) + uv.y * upNorm;//scrCoord
	vec3 relVec = normalize(worldPix - camPos);//scp

	// -------------------------- Animate some things -----------------------------
	float sunSpeed = 0.045;
	vec3 sunDir;// = normalize(vec3(sin(iTime*sunSpeed), -3.0, sin(iTime*sunSpeed)));
	sunDir = normalize(vec3(localTime*sunSpeed - 0.95, -3.0, localTime*sunSpeed - 0.95));
	//sparkle = saturate((1.0 - abs(sin(iTime*sunSpeed))) - 0.8) * 5.0;
	sparkle = min(1.0, saturate(-sunDir.y - 0.988) * 200.0);
	sparkle = smoothstep(0.0, 1.0, sparkle);
	float sparkleLasting = max(sparkle, saturate(localTime - 20.0));
	glowDist = 0.0;
	sunCol = min(sunColOrig, (sunColOrig * 0.00025)*pow(2.5, localTime));
	rotateGem = SmoothMix(0.0, 3.0*PI, saturate((localTime - 14.0)/15.0));

	// ------------------------------ Ray march -----------------------------------
	float dist = 0.02;
	float t = 0.1;
	float maxDepth = 40.0;
	vec3 pos = vec3(0,0,0);
	// ray marching time
	for (int i = 0; i < 120; i++)
	{
		if ((t > maxDepth) || (abs(dist) < 0.001))
		{
			break;	// break doesn't work on some machines
			continue;	// so do a continue for those
		}
		pos = camPos + relVec * t;
		dist = DistanceToObject(pos);
		t += dist * marchingMultplier;	// because deformations mess up distance function.
	}
	float finalMaterial = material;
	marchingMultplier = 1.0;

	// ----------------------------------------------------------------------------

	// oculus is the word for the hole in the roof of the dome.
	vec3 oculus = vec3(0.0, 5.3, 0.0);
	vec3 floorHit = (oculus) + sunDir * 6.3 / abs(sunDir.y);

	vec3 cr = normalize(cross(-sunDir, relVec));
	float d1 = dot(oculus, cr);
	float d2 = dot(pos, cr);
	float haze = pow(saturate(1.0 - abs(d1 - d2) * 2.0), 0.6);

	vec3 finalColor = vec3(1.0,1.0,1.0);// GetSunColorReflection(relVec, -sunDir) + vec3(0.1, 0.1, 0.1);

	// calculate normal from distance field
	vec3 smallVec = vec3(0.005, 0, 0);
	vec3 dx = pos - smallVec.xyy;
	vec3 dy = pos - smallVec.yxy;
	vec3 dz = pos - smallVec.yyx;
	vec3 normal = vec3(dist - DistanceToObject(dx),
					   dist - DistanceToObject(dy),
					   dist - DistanceToObject(dz));
	normal = normalize(normal);
	
	// -------------------------- Shadow trace to oculus --------------------------
	float origGlowDist = glowDist;
	shadow = 1000000.0;
	//for (int i = 1; i < 8; i++)
	//{
	//	vec3 midPos = mix(pos, oculus, float(i) / 64.0);
	//	float shadow0 = max(0.0, DistanceToObject(midPos));
	//	shadow = min(shadow, shadow0);
	//}
#if TRACED_SKY_SHADOWS
	float dist2 = 0.02;
	float t2 = 0.1;
	float maxDepth2 = 40.0;
	vec3 pos2 = vec3(0,0,0);
	// ray marching time
	float mCount = 0.0;
	for (int i = 0; i < 32; i++)
	{
		if ((t2 > maxDepth2) || (abs(dist2) < 0.001)) continue;	// break DOESN'T WORK!!! ARRRGGG!
		pos2 = (pos + normal*0.02) + normalize(oculus - pos) * t2;
		dist2 = DistanceToObject(pos2);
		t2 += dist2 * marchingMultplier;	// because deformations mess up distance function.
		mCount++;
	}
	if (dist2 < 0.01) shadow = 0.0;
	shadow = saturate(shadow * 300.9);
#else
	// fake the shadows
	float xzDist = length(pos.xz);
	shadow = (abs(xzDist - 3.0))*5.0;
	shadow += pow(saturate(-(pos.y - 2.5)), 3.0);
	shadow += saturate((pos.y - 2.5)*8.0);
	shadow *= 1.0 - saturate(xzDist - 2.995);
	shadow = saturate(shadow);

#endif

//	float shadow0 = max(0.0, DistanceToObject(mix(oculus, pos, 0.333)));
//	float shadow1 = max(0.0, DistanceToObject(mix(oculus, pos, 0.666)));
//	shadow0 = min(shadow0, shadow1);
	glowDist = origGlowDist;
	// ----------------------------------------------------------------------------

	// calculate ambient occlusion with 2 extra distance field queries
	float ambient = DistanceToObject(pos + normal * 1.0)*0.5;
	ambient += DistanceToObject(pos + normal * 0.1)*5.0;
	ambient = max(0.1, pow(abs(ambient), 0.5));	// tone down ambient with a pow and min clamp it.

	vec3 tempPos = pos;
	if (finalMaterial == 2.0) tempPos.y = pos.y + sinking*0.2;
	// look up brick texture, blended across xyz axis based on normal.
	vec4 tex = tex3d(tempPos*0.75, normal);
	//tex = tex * tex;	// gamma correct
	tex.xyz = pow(tex.xyz, vec3(1.35,1.35,1.35));	// gamma correct sorta

	// weathering texture
	vec3 texSpots = texture(iChannel3, pos.xz*0.085* (1.0 + pos.y*0.02)).xyz;
	texSpots = saturate(texSpots * 4.0 - 0.75);
	//if (pos.y < -0.999)
	texSpots.y = min(1.0-abs(normal.y*0.75), texSpots.y);	// only for vertical surfaces
	tex.xyz = mix(tex.xyz, vec3(0.3, 0.24, 0.25)*1.25-tex.xzy*0.45, texSpots.y);
	//tex.xyz = vec3(0.75, 0.75, 0.75);

	// Make the rune ring texture around the top ledge
	float radial = atan(pos.x, pos.z);
	radial /= 2.0*PI;
	vec2 runeUV = vec2(radial * 16.0, pos.y + 0.14) * 3.0;
	if (finalMaterial == 2.0)
	{
		runeUV = vec2(radial * 4.0, pos.y + 0.395 + sinking*0.2) * 9.0;
	}
	vec2 runeSeed = floor(runeUV)*vec2(1.0, 6.0);
	runeUV = fract(runeUV) + (tex.xy - 0.4)*0.25;

	// closing credit text
	if (localTime > 46.5)
	{
		float fu = floor((uv.x*0.5+0.5)*8.0);
		vec2 seed = vec2(15.0, 2.0);
		if (fu == 1.0) seed = vec2(-5,-5);
		if (fu == 2.0) seed = vec2(34,4);
		if (fu == 4.0) seed = vec2(19,5);
		if (fu == 5.0) seed = vec2(51,4);
		if (fu == 6.0) seed = vec2(66,-2);
		if (fu == 7.0) seed = vec2(-8,6);
		vec2 shift = uv + vec2(0.0, 0.125);
		runeUV = fract(shift*4.0);
		runeSeed = seed;
	}

	// Generate a rune based on a random seed.
	// GLSL unrolls function calls, so try really hard to only call this once. :(
	vec3 runeCol = Rune(runeUV, runeSeed);
	// If it is the base of the dome, do the runes for that.
	if (floor((pos.y + 0.14)*3.0) == 8.0)
	{
		tex.xyz *= (1.0 - pow(runeCol.x, 0.95)*0.65);
		normal.y -= runeCol.z*100.0;
	}
	else
	{
		if ((finalMaterial != 2.0) && (localTime <= 46.5)) runeCol = vec3(0.0, 0.0, 0.0);
	}

	// materials
	normal.y += (tex.z - 0.23)*2.0;	// fake bump map
	normal = normalize(normal);
	vec3 ref = reflect(relVec, normal);

	// Gem material
	if (finalMaterial == 1.0)
	{
		//vec3 refraction = normalize(mix(-ref, relVec, 0.5));
		tex.xyz = pow(texture(iChannel2, ref).xyz, vec3(2.0,2.0,2.0)) * vec3(0.9, 0.1, 0.5);
		//tex.xyz += pow(texture(iChannel2, ref).xyz, vec3(2.0,2.0,2.0)) * vec3(0.9, 0.1, 0.5);
	}
	// pedestal material
	else if (finalMaterial == 2.0)
	{
		//float radial = atan(pos.x, pos.z);
		//radial /= 2.0*PI;
		//runeUV = vec2(radial * 4.0, pos.y + 0.405 + sinking*0.2) * 9.0;
		//runeCol = vec3(0.0, 0.0, 0.0);
		if (abs(normal.y) < 0.99)
		{
//			runeCol = Rune(fract(runeUV) + (tex.xy - 0.4)*0.25, floor(runeUV)*vec2(1.0, 6.0));
			//runeCol.x = pow(runeCol.x, 2.0);
			tex.xyz *= (1.0 - pow(runeCol.x, 0.55)*0.85);// * (1.0+saturate(-runeCol.z)*18.0);
			//tex.xyz *= saturate(1.0 - vec3(0.997, 0.92, 0.997)*runeCol.x*0.8);//*0.3;
			normal.y -= runeCol.z*52.0;
			normal = normalize(normal);
			tex.xyz += sunCol*4.0*runeCol.x * max(0.0,sparkleLasting-0.6)*2.0;
		}
	}
	// glow ray material
	else if (finalMaterial == 3.0)
	{
		tex.xyz = sunCol*8.0;
	}

	// try to fake stained glass windows on the interior of the dome.
	float domeAlpha = 0.0;
	if (pos.y > 2.95)
	{
		domeAlpha = length(pos - vec3(0.0, 2.25, 0.0)) - 3.05;
		domeAlpha *= 12.0;
		domeAlpha = saturate(domeAlpha);
		//tex *= alpha;// mix(tex, tex*texture(iChannel1, pos.xz*0.75).xxxw, 0.5);
		vec3 t2 = texture(iChannel1, pos.xz*0.75).yzx;
		vec3 t3 = texture(iChannel1, pos.xz*0.5).yzz;
		t2 = t2*t2;
		t3 = t3*t3;
		t2 = saturate(t2*1.0 - 0.05) * vec3(12.0,1.0,6.0);
		t3 = saturate(t3*1.5 - 0.05) * vec3(0.0,2.0,2.0);
		tex.xyz = mix(tex.xyz, (t2 + t3), domeAlpha);
	}
	// glowing hole in the ground
	if (pos.y < -0.99)
	{
		if (length(pos.xz) < 0.5) tex.xyz = sunCol*1.5;
	}
	//tex.xyz = vec3(0.75, 0.75, 0.75);

	// if ray marching found an intersection, then calculate lighting and stuff
	if (t <= maxDepth)
	{
		vec3 lightDir = pos - oculus;
		float lenLightDir = length(lightDir);
		float skyMult = max(0.0, -lightDir.y) * max(0.0, dot(-lightDir, normal));
		skyMult *= 0.55 / (lenLightDir*lenLightDir);
		vec3 envLight = environmentSphereColor;// * skyMult;// + environmentGroundColor * (normal.y * 0.5 + 0.5);
		//vec3 envLight = mix(environmentGroundColor, environmentSphereColor, (normal.y * 0.5 + 0.5)) * 0.9;
		envLight *= shadow * skyMult;
		envLight += environmentSphereColor * 0.045;	// ambient is lame, but better than black.
		vec3 domeLight = vec3(1.0, 0.1, 0.5) * (normal.y * 0.5 + 0.5) * min(ambient, shadow) * 0.15;

		float d1 = dot(sunDir, pos);
		float d2 = dot(sunDir, oculus);
		float d3 = dot(sunDir, camPos);
		vec3 flatPos = pos - sunDir * d1;
		vec3 flatOculus = oculus - sunDir * d2;
		vec3 flatCam = camPos - sunDir * d3;
		float sunShadow = pow(saturate(0.5 - distance(flatPos, flatOculus)), 0.2);
		vec3 sunDirect = max(0.0, dot(-sunDir, normal)) * sunCol * sunShadow * 40.0;
		vec3 sunIndirect;// = 0.25*pow(saturate((3.5-distance(flatPos, flatOculus))), 2.0) * sunCol * 0.31;
		vec3 indirectDir = pos - floorHit;
		float indirectLen = length(indirectDir);
		indirectDir = normalize(indirectDir);
		sunIndirect = sunCol * (dot(-indirectDir, normal)*0.5+0.54) * 2.5 / pow(indirectLen, 1.75)*sunCol.x;
		finalColor = (envLight + sunIndirect + domeLight) * tex.xyz;
		finalColor *= vec3(1.0,1.0,1.0) * ambient;
		finalColor += (sunDirect) * tex.xyz;// * ambient;
		finalColor += max(vec3(0.0,0.0,0.0),
						  GetSunColorReflection(ref, normalize(-indirectDir))*0.5*tex.x*domeAlpha-0.25);
		finalColor += sunCol * runeCol.x * 1.5 * max(0.0,sparkleLasting-0.6)*2.0;
		//finalColor = domeLight * min(ambient, shadow);
		finalColor = mix(finalColor, vec3(0.015,0.015,0.015), pow(saturate(distance(pos, camPos)*0.075), 0.7) );
		//finalColor = vec3(1.0,1.0,1.0) * distance(pos, floorHit)*0.1;
		//finalColor = vec3(1.0,1.0,1.0) * distance(floorHit, pos)*0.01;// skyMult * shadow;
		if (distance(flatPos, flatCam) > distance(flatOculus, flatCam))
		{
			float ratioA = distance(flatOculus, flatCam) / distance(flatPos, flatCam);
			vec3 hazePos = mix(camPos, pos, ratioA);
			vec3 hazeNoise = texture(iChannel3, (hazePos.xz + vec2(0.0, -iTime* 0.125))* 0.03).xyz;
			haze = haze * hazeNoise.x;
			finalColor += (sunCol + vec3(1.0, 1.0, 1.0)) * haze * 0.15 * sunCol.x;
		}
		finalColor += sunCol * glowDist*0.001;
		//finalColor = vec3(1.0,1.0,1.0)*shadow*0.25;
		//finalColor = vec3(1.0,1.0,1.0)*mCount*0.005;
		//finalColor = vec3(saturate(tex.y-0.35), saturate(-(tex.y-0.35)), 0.0);
	}

	// closing credit text
	if (localTime > 46.5)
	{
		float creditsTimer = saturate((localTime - 47.0)*0.5);
		//finalColor = saturate(vec3(1.0,1.0,1.0)*0.25-creditsTimer);
		finalColor = vec3(1.0,1.0,1.0)*0.25;
		vec2 shift = uv + vec2(0.0, 0.125);
		//runeCol = Rune(fract(shift*4.0), vec2(seed, seed))*creditsTimer;
		runeCol *= creditsTimer;
		if (floor(shift.y*4.0) == 0.0)
		{
			finalColor = mix(finalColor, vec3(0.25, 0.025, 0.01), pow(runeCol.x, 0.75));
			finalColor += runeCol.z*2.0;
		}
		//finalColor = Rune(fract(uv*8.0), floor(uv*8.0*1.0+vec2(64.0, 0.0)*1.0)).xxx;
		//finalColor = Rune(fract(uv*8.0), floor(vec2(66.0, -2.0)*1.0)).xxx;
		// S - (-1, -7) :( (15, 2)
		// O - (5,-1) (-5, -5)
		// L - (34, 4)
		// S
		// T - (5,2) :( (19, 5)
		// I - (51, 4)
		// C - (66,-2)
		// E - (-8.0, 6.0)
		// N - (0, 4)
		// U - (-3, 0)
		// R -
	}

	fragColor = vec4(sqrt(clamp(finalColor*4.0, 0.0, 1.0)),1.0);
}
