/**
 * Created by Steven Sell (ssell) / 2017
 * License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
 * https://www.shadertoy.com/view/ldjBzt
 *
 * An aeons-old city is found within the frozen heart of Antarctica.
 * Inspired by the novella 'At the Mountains of Madness' by H.P. Lovecraft.
 *
 *     Buffer A: Scene rendering.
 *     Image: Scene sampling and antialiasing.
 *
 * ------------------------------------------------------------------------
 * - References / Sources
 * ------------------------------------------------------------------------
 *
 * As with all of my shaders, part of this work is something old, part is
 * something new, and part is something borrowed. Oh, there is also some blue.
 *
 * [Terrain]
 *
 *     'Value Noise Derivatives' - iq
 *     https://iquilezles.org/articles/morenoise
 *
 *         This was my first go with this method of heightmap generation,
 *         so naturally iq's article on it was tremendously helpful.
 *
 * [Lighting]
 *
 *     'Outdoors Lighting' - iq
 *      https://iquilezles.org/articles/outdoorslighting
 *
 *         Second time using this lighting setup, and it works very well 
 *         for large, outdoor scenes.
 *
 * [Volumetric Fog]
 *
 *     'Frozen Wasteland' - Dave_Hoskins
 *     https://www.shadertoy.com/view/Xls3D2
 *
 *     'Xyptonjtroz' - Nimitz
 *     https://www.shadertoy.com/view/4ts3z2
 *
 *         Though my final fog result is fairly different from theirs, they were
 *         still valuable resources. The Noise3D function is taken from Dave_Hoskins.
 *
 * [Pathing]
 *
 *     'Fourier vs Spline Interpolation' - revers
 *     https://www.shadertoy.com/view/MlGSz3
 *
 *         Used revers' Catmull-Rom implementation in the camera path interpolation.
 * 
 * [SDFs]
 *
 *     'Modeling with Distance Functions' - iq
 *     https://iquilezles.org/articles/distfunctions
 *
 *     'Smooth Minimum' - iq
 *     https://iquilezles.org/articles/smin
 *
 *         Naturally.
 *
 * [Anti-Aliasing]
 *
 *     'Anti-Aliasing Compare' - JasonD
 *     https://www.shadertoy.com/view/4dGXW1
 *
 *         Implemented '3Dfx rotated grid' in SampleAA().
 *
 * ------------------------------------------------------------------------
 * - Known Issues / To-Do
 * ------------------------------------------------------------------------
 *
 *     - Terrain 'warp' bubbles.
 *     - Fullscreen performance.
 *     - General refactoring.
 *     - City aliasing.
 *     - The sky is pretty plain.
 *     - A better title...
 */

vec4 SampleAA(sampler2D sampler, in vec2 uv)
{
    vec2 s = vec2(1.0 / iResolution.x, 1.0 / iResolution.y);
    vec2 o = vec2(0.11218413712, 0.33528304367) * s;
    
    return (texture(sampler, uv + vec2(-o.x,  o.y)) +
            texture(sampler, uv + vec2( o.y,  o.x)) +
            texture(sampler, uv + vec2( o.x, -o.y)) +
            texture(sampler, uv + vec2(-o.y, -o.x))) * 0.25;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	vec2 uv = fragCoord.xy / iResolution.xy;
	
    vec3 color = SampleAA(iChannel0, uv).rgb;
    color *= 0.5 + 0.5 * pow(16.0 * uv.x * uv.y * (1.0 - uv.x) * (1.0 - uv.y), 0.1); // Vignette
    
    fragColor = vec4(color, 1.0);
}