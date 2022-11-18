/*--------------------------------------------------------------------------------------
License CC0 - http://creativecommons.org/publicdomain/zero/1.0/
To the extent possible under law, the author(s) have dedicated all copyright and related and neighboring rights to this software to the public domain worldwide. This software is distributed without any warranty.
----------------------------------------------------------------------------------------
^ This means do ANYTHING YOU WANT with this code. Because we are programmers, not lawyers.
-Otavio Good
*/

// ---------------- Config ----------------
// This is an option that lets you render high quality frames for screenshots. It enables
// stochastic antialiasing and motion blur automatically for any shader.
//#define NON_REALTIME_HQ_RENDER
const float frameToRenderHQ = 20.0; // Time in seconds of frame to render
const float antialiasingSamples = 16.0; // 16x antialiasing - too much might make the shader compiler angry.

//#define MANUAL_CAMERA


#define ZERO_TRICK max(0, -iFrame)
// --------------------------------------------------------
// These variables are for the non-realtime block renderer.
float localTime = 0.0;
float seed = 1.0;

// Animation variables
float animStructure = 1.0;
float fade = 1.0;

// ---- noise functions ----
float v31(vec3 a)
{
    return a.x + a.y * 37.0 + a.z * 521.0;
}
float v21(vec2 a)
{
    return a.x + a.y * 37.0;
}
float Hash11(float a)
{
    return fract(sin(a)*10403.9);
}
float Hash21(vec2 uv)
{
    float f = uv.x + uv.y * 37.0;
    return fract(sin(f)*104003.9);
}
vec2 Hash22(vec2 uv)
{
    float f = uv.x + uv.y * 37.0;
    return fract(cos(f)*vec2(10003.579, 37049.7));
}
vec2 Hash12(float f)
{
    return fract(cos(f)*vec2(10003.579, 37049.7));
}
float Hash1d(float u)
{
    return fract(sin(u)*143.9);	// scale this down to kill the jitters
}
float Hash2d(vec2 uv)
{
    float f = uv.x + uv.y * 37.0;
    return fract(sin(f)*104003.9);
}
float Hash3d(vec3 uv)
{
    float f = uv.x + uv.y * 37.0 + uv.z * 521.0;
    return fract(sin(f)*110003.9);
}
float mixP(float f0, float f1, float a)
{
    return mix(f0, f1, a*a*(3.0-2.0*a));
}
const vec2 zeroOne = vec2(0.0, 1.0);
float noise2d(vec2 uv)
{
    vec2 fr = fract(uv.xy);
    vec2 fl = floor(uv.xy);
    float h00 = Hash2d(fl);
    float h10 = Hash2d(fl + zeroOne.yx);
    float h01 = Hash2d(fl + zeroOne);
    float h11 = Hash2d(fl + zeroOne.yy);
    return mixP(mixP(h00, h10, fr.x), mixP(h01, h11, fr.x), fr.y);
}
float noise(vec3 uv)
{
    vec3 fr = fract(uv.xyz);
    vec3 fl = floor(uv.xyz);
    float h000 = Hash3d(fl);
    float h100 = Hash3d(fl + zeroOne.yxx);
    float h010 = Hash3d(fl + zeroOne.xyx);
    float h110 = Hash3d(fl + zeroOne.yyx);
    float h001 = Hash3d(fl + zeroOne.xxy);
    float h101 = Hash3d(fl + zeroOne.yxy);
    float h011 = Hash3d(fl + zeroOne.xyy);
    float h111 = Hash3d(fl + zeroOne.yyy);
    return mixP(
        mixP(mixP(h000, h100, fr.x),
             mixP(h010, h110, fr.x), fr.y),
        mixP(mixP(h001, h101, fr.x),
             mixP(h011, h111, fr.x), fr.y)
        , fr.z);
}

const float PI=3.14159265;

vec3 saturate(vec3 a) { return clamp(a, 0.0, 1.0); }
vec2 saturate(vec2 a) { return clamp(a, 0.0, 1.0); }
float saturate(float a) { return clamp(a, 0.0, 1.0); }

vec3 RotateX(vec3 v, float rad)
{
  float cos = cos(rad);
  float sin = sin(rad);
  return vec3(v.x, cos * v.y + sin * v.z, -sin * v.y + cos * v.z);
}
vec3 RotateY(vec3 v, float rad)
{
  float cos = cos(rad);
  float sin = sin(rad);
  return vec3(cos * v.x - sin * v.z, v.y, sin * v.x + cos * v.z);
}
vec3 RotateZ(vec3 v, float rad)
{
  float cos = cos(rad);
  float sin = sin(rad);
  return vec3(cos * v.x + sin * v.y, -sin * v.x + cos * v.y, v.z);
}

// This spiral noise works by successively adding and rotating sin waves while increasing frequency.
// It should work the same on all computers since it's not based on a hash function like some other noises.
// It can be much faster than other noise functions if you're ok with some repetition.
const float nudge = 0.71;	// size of perpendicular vector
float normalizer = 1.0 / sqrt(1.0 + nudge*nudge);	// pythagorean theorem on that perpendicular to maintain scale
// Total hack of the spiral noise function to get a rust look
float RustNoise3D(vec3 p)
{
    float n = 0.0;
    float iter = 1.0;
    float pn = noise(p*0.125);
    pn += noise(p*0.25)*0.5;
    pn += noise(p*0.5)*0.25;
    pn += noise(p*1.0)*0.125;
    for (int i = ZERO_TRICK; i < 7; i++)
    {
        //n += (sin(p.y*iter) + cos(p.x*iter)) / iter;
        float wave = saturate(cos(p.y*0.25 + pn) - 0.998);
        wave *= noise(p * 0.125)*1016.0;
        n += wave;
        p.xy += vec2(p.y, -p.x) * nudge;
        p.xy *= normalizer;
        p.xz += vec2(p.z, -p.x) * nudge;
        p.xz *= normalizer;
        iter *= 1.4733;
    }
    return n;
}

// ---- functions to remap / warp space ----
float repsDouble(float a)
{
    return abs(a * 2.0 - 1.0);
}
vec2 repsDouble(vec2 a)
{
    return abs(a * 2.0 - 1.0);
}

vec2 mapSpiralMirror(vec2 uv)
{
    float len = length(uv);
    float at = atan(uv.x, uv.y);
    at = at / PI;
    float dist = (fract(log(len)+at*0.5)-0.5) * 2.0;
    at = repsDouble(at);
    at = repsDouble(at);
    return vec2(abs(dist), abs(at));
}

vec2 mapSpiral(vec2 uv)
{
    float len = length(uv);
    float at = atan(uv.x, uv.y);
    at = at / PI;
    float dist = (fract(log(len)+at*0.5)-0.5) * 2.0;
    //dist += sin(at*32.0)*0.05;
    // at is [-1..1]
    // dist is [-1..1]
    at = repsDouble(at);
    at = repsDouble(at);
    return vec2(dist, at);
}

vec2 mapCircleInvert(vec2 uv)
{
    float len = length(uv);
    float at = atan(uv.x, uv.y);
    //at = at / PI;
    //return uv;
    len = 1.0 / len;
    return vec2(sin(at)*len, cos(at)*len);
}

vec3 mapSphereInvert(vec3 uv)
{
    float len = length(uv);
    vec3 dir = normalize(uv);
    len = 1.0 / len;
    return dir * len;
}

// ---- shapes defined by distance fields ----
// See this site for a reference to more distance functions...
// https://iquilezles.org/articles/distfunctions
float length8(vec2 v)
{
	return pow(pow(abs(v.x),8.0) + pow(abs(v.y), 8.0), 1.0/8.0);
}

// box distance field
float sdBox(vec3 p, vec3 radius)
{
  vec3 dist = abs(p) - radius;
  return min(max(dist.x, max(dist.y, dist.z)), 0.0) + length(max(dist, 0.0));
}

// Makes a warped torus that rotates around
float sdTorusWobble( vec3 p, vec2 t, float offset)
{
   	float a = atan(p.x, p.z);
    float subs = 2.0;
	a = sin(a*subs+localTime*4.0+offset*3.234567);
	vec2 q = vec2(length(p.xz)-t.x-a*0.1,p.y);
	return length8(q)-t.y;
}

// simple cylinder distance field
float cyl(vec2 p, float r)
{
    return length(p) - r;
}

float glow = 0.0, glow2 = 0.0, glow3 = 0.0;
float pulse;
// This is the big money function that makes the crazy fractally shape
// The input is a position in space.
// The output is the distance to the nearest surface.
float DistanceToObject(vec3 p)
{
    vec3 orig = p;
    // Magically remap space to be in a spiral
    p.yz = mapSpiralMirror(p.yz);
    // Mix between spiral space and unwarped space. This changes the scene
    // from the tunnel to the spiral.
    p = mix(orig, p, animStructure);
//    p = mix(p, orig, cos(localTime)*0.5+0.5);

    // Cut out stuff outside of outer radius
	const float outerRad = 3.5;
    float lenXY = length(p.xy);
    float final = lenXY - outerRad;
    // Carve out inner radius
    final = max(final, -(lenXY - (outerRad-0.65)));

    // Slice the object in a 3d grid
    float slice = 0.04;
    vec3 grid = -abs(fract(p)-0.5) + slice;
    //final = max(final, grid.x);
    //final = max(final, grid.y);
    final = max(final, grid.z);

    // Carve out cylinders from the object on all 3 axis, scaled 3 times
    // This gives it the fractal look.
    vec3 rep = fract(p)-0.5;
    float scale = 1.0;
    float mult = 0.32;
    for (int i = ZERO_TRICK; i < 3; i++)
    {
        float uglyDivider = max(1.0, float(i));	// wtf is this? My math sucks :(
        // carve out 3 cylinders
        float dist = cyl(rep.xz/scale, mult/scale)/uglyDivider;
        final = max(final, -dist);
        dist = cyl(rep.xy/scale, mult/scale)/uglyDivider;
        final = max(final, -dist);
        dist = cyl(rep.yz/scale, mult/scale)/uglyDivider;
        final = max(final, -dist);
        // Scale and repeat.
        scale *= 1.14+1.0;// + sin(localTime)*0.995;
        rep = fract(rep*scale) - 0.5;
    }

    // Make radial struts that poke into the center of the spiral
    vec3 sp = p;
    sp.x = abs(sp.x)-5.4;
    sp.z = fract(sp.z) - 0.5;
    // Bad distance field on these makes them sometimes disappear. Math. :(
    float struts = sdBox(sp+vec3(2.95, 0.1-sin(sp.x*2.0)*1.1, 0.0), vec3(1.5, 0.05, 0.02))*0.5;
    //glow3 += (0.00005)/max(0.01, struts);
    final = min(final, struts);

    // Make spiral glows that rotate and pulse energy to the center
    rep.yz = (fract(p.yz)-0.5);
    rep.x = p.x;
    scale = 1.14+1.0;
    float jolt = max(0.0, sin(length(orig.yz) + localTime*20.0))*0.94;
    jolt *= saturate(0.3-pulse);
    float spiral = sdBox(RotateX(rep+vec3(-0.05,0.0,0.0), pulse), vec3(0.01+jolt,1.06, mult*0.01)/scale );
    glow3 += (0.0018)/max(0.0025,spiral);
    final = min(final, spiral + (1.0-animStructure) * 100.0);

    // Make a warped torus that rotates around and glows orange
    vec3 rp = p.xzy;
    rp.x = -abs(rp.x);
    rp.y = fract(rp.y) - 0.5;
    float torus = sdTorusWobble(rp + vec3(3.0, 0.0, 0.0), vec2(0.2, 0.0003), p.z);
    glow2 += 0.0015 / max(0.03, torus);
    final = min(final, torus);

    // Make the glowing tower in the center.
    // This also gives a bit of a glow to everything.
    glow += (0.02+abs(sin(orig.x-localTime*3.0)*0.15)*jolt )/length(orig.yz);

    return final;
}

// Input is UV coordinate of pixel to render.
// Output is RGB color.
vec3 RayTrace(in vec2 fragCoord )
{
    glow = 0.0;
    glow2 = 0.0;
    glow3 = 0.0;
	// -------------------------------- animate ---------------------------------------
    // Default to spiral shape
    animStructure = 1.0;

    // Make a cycling, clamped sin wave to animate the glow-spiral rotation.
    float slt = sin(localTime);
    float stepLike = pow(abs(slt), 0.75)*sign(slt);
    stepLike = max(-1.0, min(1.0, stepLike*1.5));
    pulse = stepLike*PI/4.0 + PI/4.0;

	vec3 camPos, camUp, camLookat;
	// ------------------- Set up the camera rays for ray marching --------------------
    // Map uv to [-1.0..1.0]
	vec2 uv = fragCoord.xy/iResolution.xy * 2.0 - 1.0;

#ifdef MANUAL_CAMERA
    // Camera up vector.
	camUp=vec3(0,1,0);

	// Camera lookat.
	camLookat=vec3(0,0.0,0);

    // debugging camera
    float mx=iMouse.x/iResolution.x*PI*2.0;// + localTime * 0.166;
	float my=-iMouse.y/iResolution.y*10.0;// + sin(localTime * 0.3)*0.8+0.1;//*PI/2.01;
	camPos = vec3(cos(my)*cos(mx),sin(my),cos(my)*sin(mx))*8.35;
#else
    // Do the camera fly-by animation and different scenes.
    // Time variables for start and end of each scene
    const float t0 = 0.0;
    const float t1 = 9.0;
    const float t2 = 16.0;
    const float t3 = 24.0;
    const float t4 = 40.0;
    const float t5 = 48.0;
    const float t6 = 70.0;
    // Repeat the animation after time t6
    localTime = fract(localTime / t6) * t6;
    /*const float t0 = 0.0;
    const float t1 = 0.0;
    const float t2 = 0.0;
    const float t3 = 0.0;
    const float t4 = 0.0;
    const float t5 = 0.0;
    const float t6 = 18.0;*/
    if (localTime < t1)
    {
	    animStructure = 0.0;
        float time = localTime - t0;
        float alpha = time / (t1 - t0);
        fade = saturate(time);
        fade *= saturate(t1 - localTime);
        camPos = vec3(56.0, -2.5, 1.5);
        camPos.x -= alpha * 6.8;
        camUp=vec3(0,1,0);
        camLookat=vec3(50,0.0,0);
    } else if (localTime < t2)
    {
    	animStructure = 0.0;
        float time = localTime - t1;
        float alpha = time / (t2 - t1);
        fade = saturate(time);
        fade *= saturate(t2 - localTime);
        camPos = vec3(12.0, 3.3, -0.5);
        camPos.x -= smoothstep(0.0, 1.0, alpha) * 4.8;
        camUp=vec3(0,1,0);
        camLookat=vec3(0,5.5,-0.5);
    } else if (localTime < t3)
    {
        animStructure = 1.0;
        float time = localTime - t2;
        float alpha = time / (t3 - t2);
        fade = saturate(time);
        fade *= saturate(t3 - localTime);
        camPos = vec3(12.0, 6.3, -0.5);
        camPos.y -= alpha * 1.8;
        camPos.x = cos(alpha*1.0) * 6.3;
        camPos.z = sin(alpha*1.0) * 6.3;
        camUp=normalize(vec3(0,1,-0.3 - alpha * 0.5));
        camLookat=vec3(0,0.0,-0.5);
    } else if (localTime < t4)
    {
        animStructure = 1.0;
        float time = localTime - t3;
        float alpha = time / (t4 - t3);
        fade = saturate(time);
        fade *= saturate(t4 - localTime);
        camPos = vec3(12.0, 3.0, -2.6);
        camPos.y -= alpha * 1.8;
        camPos.x = cos(alpha*1.0) * 6.5-alpha*0.25;
        camPos.z += sin(alpha*1.0) * 6.5-alpha*0.25;
        camUp=normalize(vec3(0,1,0.0));
        camLookat=vec3(0,0.0,-0.0);
    } else if (localTime < t5)
    {
        animStructure = 1.0;
        float time = localTime - t4;
        float alpha = time / (t5 - t4);
        fade = saturate(time);
        fade *= saturate(t5 - localTime);
        camPos = vec3(0.0, -7.0, -0.9);
        camPos.y -= alpha * 1.8;
        camPos.x = cos(alpha*1.0) * 1.5-alpha*1.5;
        camPos.z += sin(alpha*1.0) * 1.5-alpha*1.5;
        camUp=normalize(vec3(0,1,0.0));
        camLookat=vec3(0,-3.0,-0.0);
    } else if (localTime < t6)
    {
        float time = localTime - t5;
        float alpha = time / (t6 - t5);
        float smoothv = smoothstep(0.0, 1.0, saturate(alpha*1.8-0.1));
        animStructure = 1.0-smoothv;
        fade = saturate(time);
        fade *= saturate(t6 - localTime);
        camPos = vec3(10.0, -0.95+smoothv*1.0, 0.0);
        camPos.x -= alpha * 6.8;
        camUp=normalize(vec3(0,1.0-smoothv,0.0+smoothv));
        camLookat=vec3(0,-0.0,-0.0);
    }
#endif

	// Camera setup.
	vec3 camVec=normalize(camLookat - camPos);
	vec3 sideNorm=normalize(cross(camUp, camVec));
	vec3 upNorm=cross(camVec, sideNorm);
	vec3 worldFacing=(camPos + camVec);
	vec3 worldPix = worldFacing + uv.x * sideNorm * (iResolution.x/iResolution.y) + uv.y * upNorm;
	vec3 rayVec = normalize(worldPix - camPos);

	// ----------------------------- Ray march the scene ------------------------------
	float dist = 1.0;
	float t = 0.1 + Hash2d(uv)*0.1;	// random dither-fade things close to the camera
	const float maxDepth = 45.0; // farthest distance rays will travel
	vec3 pos = vec3(0,0,0);
    const float smallVal = 0.000625;
	// ray marching time
    for (int i = ZERO_TRICK; i < 210; i++)	// This is the count of the max times the ray actually marches.
    {
        // Step along the ray. Switch x, y, and z because I messed up the orientation.
        pos = (camPos + rayVec * t).yzx;
        // This is _the_ function that defines the "distance field".
        // It's really what makes the scene geometry. The idea is that the
        // distance field returns the distance to the closest object, and then
        // we know we are safe to "march" along the ray by that much distance
        // without hitting anything. We repeat this until we get really close
        // and then break because we have effectively hit the object.
        dist = DistanceToObject(pos);
        // This makes the ray trace more precisely in the center so it will not miss the
        // vertical glowy beam.
        dist = min(dist, length(pos.yz));

        t += dist;
        // If we are very close to the object, let's call it a hit and exit this loop.
        if ((t > maxDepth) || (abs(dist) < smallVal)) break;
    }

	// --------------------------------------------------------------------------------
	// Now that we have done our ray marching, let's put some color on this geometry.
	float glowSave = glow;
	float glow2Save = glow2;
	float glow3Save = glow3;

	vec3 sunDir = normalize(vec3(0.93, 1.0, -1.5));
	vec3 finalColor = vec3(0.0);

	// If a ray actually hit the object, let's light it.
    if (t <= maxDepth)
	{
        // calculate the normal from the distance field. The distance field is a volume, so if you
        // sample the current point and neighboring points, you can use the difference to get
        // the normal.
        vec3 smallVec = vec3(smallVal, 0, 0);
        vec3 normalU = vec3(dist - DistanceToObject(pos - smallVec.xyy),
                           dist - DistanceToObject(pos - smallVec.yxy),
                           dist - DistanceToObject(pos - smallVec.yyx));
        vec3 normal = normalize(normalU);

        // calculate 2 ambient occlusion values. One for global stuff and one
        // for local stuff
        float ambientS = 1.0;
        ambientS *= saturate(DistanceToObject(pos + normal * 0.05)*20.0);
        ambientS *= saturate(DistanceToObject(pos + normal * 0.1)*10.0);
        ambientS *= saturate(DistanceToObject(pos + normal * 0.2)*5.0);
        ambientS *= saturate(DistanceToObject(pos + normal * 0.4)*2.5);
        ambientS *= saturate(DistanceToObject(pos + normal * 0.8)*1.25);
        float ambient = ambientS * saturate(DistanceToObject(pos + normal * 1.6)*1.25*0.5);
        //ambient *= saturate(DistanceToObject(pos + normal * 3.2)*1.25*0.25);
        //ambient *= saturate(DistanceToObject(pos + normal * 6.4)*1.25*0.125);
        //ambient = max(0.05, pow(ambient, 0.3));	// tone down ambient with a pow and min clamp it.
        ambient = saturate(ambient);

        // calculate the reflection vector for highlights
        //vec3 ref = reflect(rayVec, normal);

        // Trace a ray toward the sun for sun shadows
        float sunShadow = 1.0;
        float iter = 0.01;
        vec3 nudgePos = pos + normal*0.002;	// don't start tracing too close or inside the object
		for (int i = ZERO_TRICK; i < 30; i++)
        {
            float tempDist = DistanceToObject(nudgePos + sunDir * iter);
	        sunShadow *= saturate(tempDist*150.0);	// Shadow hardness
            if (tempDist <= 0.0) break;
            //iter *= 1.5;	// constant is more reliable than distance-based
            iter += max(0.01, tempDist)*1.0;
            if (iter > 4.2) break;
        }
        sunShadow = saturate(sunShadow);

        // make a few frequencies of noise to give it some texture
        float n =0.0;
        n += noise(pos*32.0);
        n += noise(pos*64.0);
        n += noise(pos*128.0);
        n += noise(pos*256.0);
        n += noise(pos*512.0);
        n *= 0.8;
        normal = normalize(normal + (n-2.0)*0.1);

        // ------ Calculate texture color  ------
        vec3 texColor = vec3(0.95, 1.0, 1.0);
        vec3 rust = vec3(0.65, 0.25, 0.1) - noise(pos*128.0);
        // Call the function that makes rust stripes on the texture
        texColor *= smoothstep(texColor, rust, vec3(saturate(RustNoise3D(pos*8.0))-0.2));

        // apply noise
        texColor *= vec3(1.0)*n*0.05;
        texColor *= 0.7;
        texColor = saturate(texColor);

        // ------ Calculate lighting color ------
        // Start with sun color, standard lighting equation, and shadow
        vec3 lightColor = vec3(3.6) * saturate(dot(sunDir, normal)) * sunShadow;
        // weighted average the near ambient occlusion with the far for just the right look
        float ambientAvg = (ambient*3.0 + ambientS) * 0.25;
        // a red and blue light coming from different directions
        lightColor += (vec3(1.0, 0.2, 0.4) * saturate(-normal.z *0.5+0.5))*pow(ambientAvg, 0.35);
        lightColor += (vec3(0.1, 0.5, 0.99) * saturate(normal.y *0.5+0.5))*pow(ambientAvg, 0.35);
        // blue glow light coming from the glow in the middle
        lightColor += vec3(0.3, 0.5, 0.9) * saturate(dot(-pos, normal))*pow(ambientS, 0.3);
        lightColor *= 4.0;

        // finally, apply the light to the texture.
        finalColor = texColor * lightColor;
        // sun reflection to make it look metal
        //finalColor += vec3(1.0)*pow(n,4.0)* GetSunColorSmall(ref, sunDir) * sunShadow;// * ambientS;
        // visualize length of gradient of distance field to check distance field correctness
        //finalColor = vec3(0.5) * (length(normalU) / smallVec.x);
	}
    else
    {
        // Our ray trace hit nothing, so draw sky.
    }
    // add the ray marching glows
    float center = length(pos.yz);
    finalColor += vec3(0.3, 0.5, 0.9) * glowSave*1.2;
    finalColor += vec3(0.9, 0.5, 0.3) * glow2*1.2;
    finalColor += vec3(0.25, 0.29, 0.93) * glow3Save*2.0;

    // vignette?
    finalColor *= vec3(1.0) * saturate(1.0 - length(uv/2.5));
    finalColor *= 1.0;// 1.3;

	// output the final color without gamma correction - will do gamma later.
	return vec3(clamp(finalColor, 0.0, 1.0)*saturate(fade+0.25));
}

#ifdef NON_REALTIME_HQ_RENDER
// This function breaks the image down into blocks and scans
// through them, rendering 1 block at a time. It's for non-
// realtime things that take a long time to render.

// This is the frame rate to render at. Too fast and you will
// miss some blocks.
const float blockRate = 20.0;
void BlockRender(in vec2 fragCoord)
{
    // blockSize is how much it will try to render in 1 frame.
    // adjust this smaller for more complex scenes, bigger for
    // faster render times.
    const float blockSize = 64.0;
    // Make the block repeatedly scan across the image based on time.
    float frame = floor(iTime * blockRate);
    vec2 blockRes = floor(iResolution.xy / blockSize) + vec2(1.0);
    // ugly bug with mod.
    //float blockX = mod(frame, blockRes.x);
    float blockX = fract(frame / blockRes.x) * blockRes.x;
    //float blockY = mod(floor(frame / blockRes.x), blockRes.y);
    float blockY = fract(floor(frame / blockRes.x) / blockRes.y) * blockRes.y;
    // Don't draw anything outside the current block.
    if ((fragCoord.x - blockX * blockSize >= blockSize) ||
    	(fragCoord.x - (blockX - 1.0) * blockSize < blockSize) ||
    	(fragCoord.y - blockY * blockSize >= blockSize) ||
    	(fragCoord.y - (blockY - 1.0) * blockSize < blockSize))
    {
        discard;
    }
}
#endif

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
#ifdef NON_REALTIME_HQ_RENDER
    // Optionally render a non-realtime scene with high quality
    BlockRender(fragCoord);
#endif

    // Do a multi-pass render
    vec3 finalColor = vec3(0.0);
#ifdef NON_REALTIME_HQ_RENDER
    for (float i = 0.0; i < antialiasingSamples; i++)
    {
        const float motionBlurLengthInSeconds = 1.0 / 60.0;
        // Set this to the time in seconds of the frame to render.
	    localTime = frameToRenderHQ;
        // This line will motion-blur the renders
        localTime += Hash11(v21(fragCoord + seed)) * motionBlurLengthInSeconds;
        // Jitter the pixel position so we get antialiasing when we do multiple passes.
        vec2 jittered = fragCoord.xy + vec2(
            Hash21(fragCoord + seed),
            Hash21(fragCoord*7.234567 + seed)
            );
        // don't antialias if only 1 sample.
        if (antialiasingSamples == 1.0) jittered = fragCoord;
        // Accumulate one pass of raytracing into our pixel value
	    finalColor += RayTrace(jittered);
        // Change the random seed for each pass.
	    seed *= 1.01234567;
    }
    // Average all accumulated pixel intensities
    finalColor /= antialiasingSamples;
#else
    // Regular real-time rendering
    localTime = iTime;
    finalColor = RayTrace(fragCoord);
#endif

    fragColor = vec4(sqrt(clamp(finalColor, 0.0, 1.0)),1.0);
}


