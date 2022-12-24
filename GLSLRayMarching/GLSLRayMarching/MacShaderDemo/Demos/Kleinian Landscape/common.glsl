// Kleinian Landscape
//
// Except where otherwise specified or cited, all work is my own and available under
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

// Constants, helper functions
// 

#define CLAMP_INDIRECT
#define ANIMATE_CAMERA
#define ANIMATE_SUN
#define INTERACTIVE
#define ROUGHNESS_MAP
#define INDIRECT_GATHER_CHECK_DIRECTION


////////// GENERAL

#define PI 3.1415926536

const float gamma = 2.2;

// Dynamic range; keep as low as possible since these buffers are packed with very low precision
const float hdrScale = 2.0;
const float depthScale = 8.0;
const float maxDepth = 8.0;
const float depthDistributionExponent = 1.0;

const vec3 luma = vec3(0.299, 0.587, 0.114);
const float goldenAngle = 2.4;

#ifdef TEMPORAL_JITTER
	const float AAjitter = 1.0;
#else
	const float AAjitter = 0.0;
#endif

float saturate(float a)
{
    return clamp(a, 0.0, 1.0);
}

// from Dave Hoskins: https://www.shadertoy.com/view/4djSRW
// Hash without Sine
// MIT License...
/* Copyright (c)2014 David Hoskins.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.*/

//----------------------------------------------------------------------------------------
//  1 out, 1 in...
float hash11(float p)
{
    p = fract(p * .1031);
    p *= p + 33.33;
    p *= p + p;
    return fract(p);
}

//----------------------------------------------------------------------------------------
//  1 out, 2 in...
float hash12(vec2 p)
{
	vec3 p3  = fract(vec3(p.xyx) * .1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

//----------------------------------------------------------------------------------------
//  1 out, 3 in...
float hash13(vec3 p3)
{
	p3  = fract(p3 * .1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}


//----------------------------------------------------------------------------------------
///  2 out, 2 in...
vec2 hash22(vec2 p)
{
	vec3 p3 = fract(vec3(p.xyx) * vec3(.1031, .1030, .0973));
    p3 += dot(p3, p3.yzx+33.33);
    return fract((p3.xx+p3.yz)*p3.zy);

}



// from Fabrice Neyret
#define ROT(a)  mat2( cos(a), -sin(a), sin(a), cos(a) )
#define HUE(v) ( .6 + .6 * cos( 2.*PI*(v) + vec4(0,-2.*PI/3.,2.*PI/3.,0) ) )



// Buffer unpacking
#define UBOUNCE_COLOR(coord) (unpack(texelFetch(iChannel0, ivec2(coord), 0).y))
#define UBOUNCE_POSITION(coord) (unpack(texelFetch(iChannel0, ivec2(coord), 0).z))
#define UBOUNCE_LIGHT(coord) (texelFetch(iChannel2, ivec2(coord), 0))
#define UBOUNCE_LIGHT_BLUR(coord) UBOUNCE_LIGHT(coord)

#define UDIRECT_ILLUMINATION(coord) (unpack(texelFetch(iChannel0, ivec2(coord), 0).x))
#define UNORMAL(coord) (((unpack(texelFetch(iChannel0, ivec2(coord), 0).w)).xyz - 0.5)*2.0)
#define UDEPTH(coord) (pow(texelFetch(iChannel0, ivec2(coord), 0).w, depthDistributionExponent))

#define UDEPTH_CHANNEL1(coord) (texelFetch(iChannel1, ivec2(coord), 0).w)
#define UBASE_COLOR(coord) vec3((unpack(texelFetch(iChannel0, ivec2(coord), 0).x)).w, (unpack(texelFetch(iChannel0, ivec2(coord), 0).y)).w, (unpack(texelFetch(iChannel0, ivec2(coord), 0).z)).w)

// Color packing from cornusammonis: https://www.shadertoy.com/view/Xlfcz8
uint packSnorm4x8(vec4 x) 
{
	x = clamp(x,-1.0, 1.0) * 127.0;
    uvec4 sig = uvec4(mix(vec4(0), vec4(1), greaterThanEqual(sign(x),vec4(0))));
    uvec4 mag = uvec4(abs(x));
    uvec4 r = sig << 7 | mag;
    return r.x << 24 | r.y << 16 | r.z << 8 | r.w;
}
vec4 unpackSnorm4x8(uint x) 
{
	uvec4 r = (uvec4(x) >> uvec4(24, 16, 8, 0)) & uvec4(0xFF);
    uvec4 sig = r >> 7;
    uvec4 mag = r & uvec4(0x7F);
    vec4 fsig = mix(vec4(-1), vec4(1), greaterThanEqual(sig,uvec4(1)));
    vec4 fmag = vec4(mag) / 127.0;
    return fsig * fmag;
}

#define unpack(x) unpackSnorm4x8(floatBitsToUint(x))
#define pack(x) uintBitsToFloat(packSnorm4x8(x))


////////// SCENE

struct pointLight
{
    vec3 worldPosition;
    vec3 normal;
    vec3 color;
};
    
struct directionalLight
{
    vec3 worldPosition;
    float angle;
    vec3 color;
};
    
struct ray
{
    vec3 origin;
    vec3 direction;
};
    
struct material
{
    vec3 baseColor;
    float roughness;
    float metal;
};

vec3 initialSunDirection = normalize(vec3(-0.2, 0.7, -0.4));
vec3 initialSunColor = 1.25*vec3(1.0,0.60,0.3);
// "Moon" is just sun reflected and re-colored when it crosses horizon line
vec3 moonColor = 1.5*vec3(1.0,0.60,0.3)*vec3(0.25, 0.45, 0.75);
vec3 skyColor = vec3(0);

// Sphere inversion fractal, similar to iq's "Apollonian" (https://www.shadertoy.com/view/4ds3zn) but with octogonal symmetry
float map(vec3 p, inout vec4 orbitTrap)
{
    const float s = 1.0;//0.97;
    const float horizontalWrap = sqrt(s*2.0)/2.0;
    
	float scale = 1.0;

	orbitTrap = vec4(1000.0); 
    
    for(int i=0; i<9; i++)
	{
        p.xz /= horizontalWrap;
        vec3 pOffset = (0.5*p+0.5);

        vec3 pOffsetWrap = 2.0*fract(pOffset);
        
        p = -1.0 + pOffsetWrap;
        p.xz *= horizontalWrap;
        
		float r2 = dot(p,p);
		
        if(i < 2)
        {
	        orbitTrap.z = min(orbitTrap.z, vec4(abs(p),r2).z);
        }
        if(i > 2)
        {
            orbitTrap.xyw = min(orbitTrap.xyw, vec4(abs(p),r2).xyw);
        }
        
		float k = s/r2;
		p     *= k;
		scale *= k;
	}
	
	float fractal = 0.33*abs(p.y)/scale;
    return fractal;
}

float sceneDistanceFunction(vec3 p, inout vec4 orbitTrap)
{
    return map(p, orbitTrap);
}

vec3 calcNormal(in vec3 position)
{
    vec3 eps = vec3(0.0001,0.0,0.0);
    vec4 dummyOrbitTrap;

    return normalize( 
        vec3(
        sceneDistanceFunction(position+eps.xyy, dummyOrbitTrap) - sceneDistanceFunction(position-eps.xyy, dummyOrbitTrap),
        sceneDistanceFunction(position+eps.yxy, dummyOrbitTrap) - sceneDistanceFunction(position-eps.yxy, dummyOrbitTrap),
        sceneDistanceFunction(position+eps.yyx, dummyOrbitTrap) - sceneDistanceFunction(position-eps.yyx, dummyOrbitTrap))
    	);
}

vec3 getSky(ray cameraRay, vec3 sunDirection, vec3 sunColor)
{
    // TODO could take dot product with some random hemisphere samples to create fake stars
    vec3 bgColor = vec3(1.0);

    #ifdef WATER
        if(cameraRay.direction.y < 0.0)
        {
            cameraRay.direction *= vec3(1, -1, 1);
            bgColor *= waterColor;
        }
    #endif

    bgColor *= skyColor + saturate((dot(cameraRay.direction, sunDirection)-.9975)*800.0)*sunColor*80.0 + saturate(dot(cameraRay.direction, sunDirection)+0.75)*sunColor*0.015;
	return bgColor;
}


////////// PATH TRACING
    
const int unpackedNone = 0;

// TODO flags for applying filters to packed textures
/*
const int unpackedDirect = 1;
const int unpackedBounce = 2;
const int unpackedDepth = 3;
const int unpackedBaseColor = 4;
*/

// from hornet, who says:
// note: entirely stolen from https://gist.github.com/TheRealMJP/c83b8c0f46b63f3a88a5986f4fa982b1
//
// Samples a texture with Catmull-Rom filtering, using 9 texture fetches instead of 16.
// See http://vec3.ca/bicubic-filtering-in-fewer-taps/ for more details
vec4 sampleLevel0(sampler2D sceneTexture, vec2 uv, float mipLevel)
{
    return textureLod(sceneTexture, uv, mipLevel);
}
vec4 SampleTextureCatmullRom(sampler2D sceneTexture, vec2 uv, vec2 texSize, float mipLevel, int getPacked)
{
    vec4 result = vec4(0.0);
    if(getPacked == unpackedNone)
    {
        // We're going to sample a a 4x4 grid of texels surrounding the target UV coordinate. We'll do this by rounding
        // down the sample location to get the exact center of our "starting" texel. The starting texel will be at
        // location [1, 1] in the grid, where [0, 0] is the top left corner.
        vec2 samplePos = uv * texSize;
        vec2 texPos1 = floor(samplePos - 0.5) + 0.5;

        // Compute the fractional offset from our starting texel to our original sample location, which we'll
        // feed into the Catmull-Rom spline function to get our filter weights.
        vec2 f = samplePos - texPos1;

        // Compute the Catmull-Rom weights using the fractional offset that we calculated earlier.
        // These equations are pre-expanded based on our knowledge of where the texels will be located,
        // which lets us avoid having to evaluate a piece-wise function.
        vec2 w0 = f * ( -0.5 + f * (1.0 - 0.5*f));
        vec2 w1 = 1.0 + f * f * (-2.5 + 1.5*f);
        vec2 w2 = f * ( 0.5 + f * (2.0 - 1.5*f) );
        vec2 w3 = f * f * (-0.5 + 0.5 * f);

        // Work out weighting factors and sampling offsets that will let us use bilinear filtering to
        // simultaneously evaluate the middle 2 samples from the 4x4 grid.
        vec2 w12 = w1 + w2;
        vec2 offset12 = w2 / w12;

        // Compute the final UV coordinates we'll use for sampling the texture
        vec2 texPos0 = texPos1 - vec2(1.0);
        vec2 texPos3 = texPos1 + vec2(2.0);
        vec2 texPos12 = texPos1 + offset12;

        texPos0 /= texSize;
        texPos3 /= texSize;
        texPos12 /= texSize;
        
        result += sampleLevel0(sceneTexture, vec2(texPos0.x,  texPos0.y), mipLevel) * w0.x * w0.y;
        result += sampleLevel0(sceneTexture, vec2(texPos12.x, texPos0.y), mipLevel) * w12.x * w0.y;
        result += sampleLevel0(sceneTexture, vec2(texPos3.x,  texPos0.y), mipLevel) * w3.x * w0.y;

        result += sampleLevel0(sceneTexture, vec2(texPos0.x,  texPos12.y), mipLevel) * w0.x * w12.y;
        result += sampleLevel0(sceneTexture, vec2(texPos12.x, texPos12.y), mipLevel) * w12.x * w12.y;
        result += sampleLevel0(sceneTexture, vec2(texPos3.x,  texPos12.y), mipLevel) * w3.x * w12.y;

        result += sampleLevel0(sceneTexture, vec2(texPos0.x,  texPos3.y), mipLevel) * w0.x * w3.y;
        result += sampleLevel0(sceneTexture, vec2(texPos12.x, texPos3.y), mipLevel) * w12.x * w3.y;
        result += sampleLevel0(sceneTexture, vec2(texPos3.x,  texPos3.y), mipLevel) * w3.x * w3.y;
    }
    
    return result;
}


vec3 triPlanarMap(sampler2D inTexture, float contrast, vec3 normal, vec3 position)
{
    vec3 xTex = textureLod(inTexture, (position).yz, 0.0).rgb;
    vec3 yTex = textureLod(inTexture, (position).xz, 0.0).rgb;
    vec3 zTex = textureLod(inTexture, -(position).xy, 0.0).rgb;
    vec3 weights = normalize(abs(pow(normal.xyz, vec3(contrast))));
    
    return vec3(xTex*weights.x + yTex*weights.y + zTex*weights.z);
}

// from tux: https://www.shadertoy.com/view/lsj3z3
vec3 triPlanarMapCatRom(sampler2D inTexture, float contrast, vec3 normal, vec3 position, vec2 texResolution)
{
    vec3 signs = sign(normal);
    
    vec3 xTex = SampleTextureCatmullRom(inTexture, (position).yz, texResolution, 0.0, 0).rgb;
    vec3 yTex = SampleTextureCatmullRom(inTexture, (position).xz, texResolution, 0.0, 0).rgb;
    vec3 zTex = SampleTextureCatmullRom(inTexture, -(position).xy, texResolution, 0.0, 0).rgb;
    
    vec3 weights = max(abs(normal) - vec3(0.0, 0.4, 0.0), 0.0);
    weights /= max(max(weights.x, weights.y), weights.z);
    float sharpening = 10.0;
    weights = pow(weights, vec3(sharpening, sharpening, sharpening));
    weights /= dot(weights, vec3(1.0, 1.0, 1.0));
  
    return clamp(vec3(xTex*weights.x + yTex*weights.y + zTex*weights.z), vec3(0), vec3(1));
}
    

// from iq
vec3 cosineDirection(in vec3 nor, vec2 fragCoord, float seed)
{
    vec2 randomSeed = (fragCoord * .152 + seed * 1500. + 50.0);
    vec2 random = hash22(randomSeed);
    float u = random.x;
    float v = random.y;
    
    // method 2 by pixar:  http://jcgt.org/published/0006/01/01/paper.pdf
    float ks = (nor.z>=0.0)?1.0:-1.0;     //do not use sign(nor.z), it can produce 0.0
    float ka = 1.0 / (1.0 + abs(nor.z));
    float kb = -ks * nor.x * nor.y * ka;
    vec3 uu = vec3(1.0 - nor.x * nor.x * ka, ks*kb, -ks*nor.x);
    vec3 vv = vec3(kb, ks - nor.y * nor.y * ka * ks, -nor.y);

    float a = 6.2831853 * v;
    return sqrt(u)*(cos(a)*uu + sin(a)*vv) + sqrt(1.0-u)*nor;
}

// from John Hable: https://gist.github.com/Kuranes/3065139b10f2d85074da
float GGX(vec3 N, vec3 V, vec3 L, float roughness, float F0)
{
    float alpha = roughness*roughness;

    vec3 H = normalize(V+L);

    float dotNL = saturate(dot(N,L));

    float dotLH = saturate(dot(L,H));
    float dotNH = saturate(dot(N,H));

    float F, D, vis;

    // D
    float alphaSqr = alpha*alpha;
    float denom = dotNH * dotNH *(alphaSqr-1.0) + 1.0;
    D = alphaSqr/(PI * denom * denom);

    // F
    float dotLH5 = pow(1.0-dotLH,5.);
    F = F0 + (1.-F0)*(dotLH5);

    // V
    float k = alpha/2.;
    float k2 = k*k;
    float invK2 = 1.-k2;
    vis = 1./(dotLH*dotLH*invK2 + k2);

    float specular = dotNL * D * F * vis;
    return specular;
}


// Camera projection stuff
vec3 stereographicPlaneToSphere(vec2 cartPointOnPlane) 
{
    float x2 = cartPointOnPlane.x*cartPointOnPlane.x;
    float y2 = cartPointOnPlane.y*cartPointOnPlane.y;
    return vec3(
        (2.0*cartPointOnPlane.x) / (1.0 + x2 + y2), 
	    (-1.0 + x2 + y2) / (1.0 + x2 + y2),
        (2.0*cartPointOnPlane.y) / (1.0 + x2 + y2));
}
vec2 stereographicSphereToPlane(vec3 cartPointOnSphere) 
{
    return vec2(
        cartPointOnSphere.x / (1.0-cartPointOnSphere.y), 
        cartPointOnSphere.z / (1.0-cartPointOnSphere.y));
}
vec2 cameraRayToUv(ray cameraRay, float projectionDist)
{
    vec2 uv = vec2(normalize(cameraRay.direction).x, normalize(cameraRay.direction).y);
    uv *= projectionDist/dot(normalize(cameraRay.direction), vec3(0, 0, projectionDist));
    return uv;
}
ray uvToCameraRay(vec2 uv, float projectionDist)
{
    ray cameraRay;
    cameraRay.direction = normalize(vec3(uv.x, uv.y, projectionDist));
    return cameraRay;
}


////////// POST

// Bloom settings
const float bloomIntensity = 0.02;
const float bloomRadius = 0.06;

// Fringe/chromatic aberration settings
const float fringeStrength = 0.01;
const float fringeStart = 0.4;

// Bokeh settings
const float bokehScale = 0.0075;
const float bokehClamp = 0.0125;
const float bokehForceSharp = 0.001;
const float bokehFringe = 0.6;
float bokehAspectRatio = 1.75;

// FXAA settings
const float spanMax = 3.0;
const float reduceMult = (1.0/spanMax);
const float reduceMin = (1.0/48.0);
const float subPixelShift = (1.0/4.0);

vec3 FXAA( vec2 uv2, sampler2D tex, vec2 rcpFrame) 
{
    vec4 uv = vec4( uv2, uv2 - (rcpFrame * (0.5 + subPixelShift)));
   
    float lumaTopLeft = dot(textureLod(tex, uv.zw, 0.0).xyz, luma);
    float lumaTopRight = dot(textureLod(tex, uv.zw + vec2(1,0)*rcpFrame.xy, 0.0).xyz, luma);
    float lumaBottomLeft = dot(textureLod(tex, uv.zw + vec2(0,1)*rcpFrame.xy, 0.0).xyz, luma);
    float lumaBottomRight = dot(textureLod(tex, uv.zw + vec2(1,1)*rcpFrame.xy, 0.0).xyz, luma);
    float lumaCenter  = dot(textureLod(tex, uv.xy, 0.0).xyz,  luma);

    float lumaMin = min(lumaCenter, min(min(lumaTopLeft, lumaTopRight), min(lumaBottomLeft, lumaBottomRight)));
    float lumaMax = max(lumaCenter, max(max(lumaTopLeft, lumaTopRight), max(lumaBottomLeft, lumaBottomRight)));

    vec2 direction;
    direction.x = -((lumaTopLeft + lumaTopRight) - (lumaBottomLeft + lumaBottomRight));
    direction.y =  ((lumaTopLeft + lumaBottomLeft) - (lumaTopRight + lumaBottomRight));

    float dirReduce = max(
        (lumaTopLeft + lumaTopRight + lumaBottomLeft + lumaBottomRight) * (0.25 * reduceMult),
        reduceMin);
    float rcpDirMin = 1.0/(min(abs(direction.x), abs(direction.y)) + dirReduce);
    
    direction = min(vec2( spanMax,  spanMax),
          max(vec2(-spanMax, -spanMax),
          direction * rcpDirMin)) * rcpFrame.xy;

    vec3 rgbA = (1.0/2.0) * (
        textureLod(tex, uv.xy + direction * (1.0/3.0 - 0.5), 0.0).xyz +
        textureLod(tex, uv.xy + direction * (2.0/3.0 - 0.5), 0.0).xyz);
    vec3 rgbB = rgbA * (1.0/2.0) + (1.0/4.0) * (
        textureLod(tex, uv.xy + direction * (0.0/3.0 - 0.5), 0.0).xyz +
        textureLod(tex, uv.xy + direction * (3.0/3.0 - 0.5), 0.0).xyz);
    
    float lumaB = dot(rgbB, luma);

    if((lumaB < lumaMin) || (lumaB > lumaMax)) return rgbA;
    
    return rgbB; 
}

// "Airy disc" bloom, complete gibberish and not based on anything physical; I just like the way it looks.
vec4 getBloom(sampler2D sceneTexture, vec2 uv, vec2 resolution, float seed, float aspectRatio)
{ 
    vec2 randomSeed = (uv*resolution * .152 + seed);
    float random = hash12(randomSeed)*PI*2.0;

    float stepsCenter = 7.0;
    float stepsRing = 6.0;
    float mipLevel = log2(resolution.x)/2.25;
    vec4 outColor = vec4(0);
    
    float bloomSum = 0.0;
    float weight = 0.0;
    float totalBloom = 0.0;

    vec2 radius = vec2(bloomRadius);
    radius.y *= aspectRatio;

    vec2 offsetUv = uv;
    
    for(float j = 1.0; j < (stepsCenter + 1.0); j++)
    {   
        offsetUv = uv + (radius*pow(j/(stepsCenter + 1.0), 0.75))*vec2(sin(j*goldenAngle+random), cos(j*goldenAngle+random));

        weight = 1.0;
        
        vec4 colorFringe = 6.0*vec4(1.0, 0.25, 0.7, 1.0) * HUE(mod((0.2 + 0.3*j/stepsCenter), 1.0));
        
        outColor += weight*colorFringe*textureLod(sceneTexture, offsetUv, mipLevel);
        totalBloom += weight;
    }
    
    radius *= 2.0;
    
    for(float j = 2.0; j < (stepsRing + 2.0); j++)
    {   
        offsetUv = uv + (radius*pow(j/(stepsRing + 2.0), 0.25))*vec2(sin(j*goldenAngle+random), cos(j*goldenAngle+random));

        weight = 0.5;
       
        vec4 colorFringe = 6.0*vec4(1.0, 0.25, 0.7, 1.0) * HUE(mod((0.2 + 0.3*j/stepsRing), 1.0));
        
        outColor += weight*colorFringe*textureLod(sceneTexture, offsetUv, mipLevel);
        totalBloom += weight;
    }
    
    return outColor/totalBloom;
}

vec4 toneMap(vec4 inputColor, vec3 gamma, vec3 exposure)
{
    vec3 gradedColor = vec3(pow(inputColor.r,gamma.r)*exposure.r,pow(inputColor.g,gamma.g)*exposure.g,pow(inputColor.b,gamma.b)*exposure.b);
    vec4 graded = vec4(1.0-1.0/(gradedColor + vec3(1.0)), inputColor.w);
    
    vec3 x = clamp(graded.xyz,0.0001,0.999);
    
    // ACES tone mapping approximation from https://knarkowicz.wordpress.com/2016/01/06/aces-filmic-tone-mapping-curve/
    const float a = 2.51;
    const float b = 0.03;
    const float c = 2.43;
    const float d = 0.59;
    const float e = 0.14;
    return vec4(clamp((x*(a*x+b))/(x*(c*x+d)+e),0.0001,0.999), inputColor.z);
}