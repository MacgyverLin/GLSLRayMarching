// MIT License
// 
// Copyright (c) 2021 Vladislav Belov
// 
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
// 
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
// 
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

vec3 getRandomDirection(in vec2 planePosition, in int sampleIdx, in vec2 frameOffset)
{
    vec2 offset = vec2(planePosition.x * 8.0, planePosition.y / 1.0);
    vec2 noiseUV = vec2(sampleIdx, 0.0) / iChannelResolution[1].xy + offset + frameOffset;
    vec3 noise = texture(iChannel1, noiseUV).rgb;
    vec3 direction = normalize(noise * 2.0 - 1.0);
    if (abs(direction.y) < 1e-3)
        direction = SUN_DIRECTION;
    else if (direction.y < 0.0)
        direction.y = -direction.y;
    return direction;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec4 data = texture(iChannel0, vec2(0, 0));
    // We need to reset the history when the resolution is changed.
    bool outdated = data.xy != iResolution.xy;
    if (fragCoord.x <= 1.0 && fragCoord.y <= 1.0)
    {
        fragColor = vec4(iResolution.xy, outdated ? float(iFrame) : data.z, 0.0);
        return;
    }
    
    vec2 uv = fragCoord / iResolution.xy;
    vec2 planePosition = uv * PROJECTION_SIZE + PROJECTION_OFFSET;
    vec3 position = vec3(planePosition.x, 0.0, planePosition.y);
    // Noise texture offset for each frame.
    vec2 frameOffset = texture(iChannel1, vec2(
        int(mod(float(iFrame), float(iChannelResolution[1].x))),
        int(iFrame) / int(iChannelResolution[1].y)) / iChannelResolution[1].xy).rg;
    
    vec3 color = vec3(0.0);
    for (int sampleIdx = 0; sampleIdx < NUMBER_OF_CAUSTICS_SAMPLES; ++sampleIdx)
    {
        vec3 direction = getRandomDirection(planePosition, sampleIdx, frameOffset);
        float cosA = clamp(dot(vec3(0.0, 1.0, 0.0), direction), 0.0, 1.0);
        color += traceScene(position + direction * 1e-3, direction, iChannel0, float(iFrame)) * cosA;
    }
    color /= float(NUMBER_OF_CAUSTICS_SAMPLES);
    
    vec4 history = (float(iFrame) <= 1.0 || outdated) ? vec4(0.0) : texture(iChannel0, uv);
    float weight = 1.0 / CAUSTICS_HISTORY_FRAMES;
    fragColor = vec4(history.rgb * (1.0 - weight) + color * weight, 1.0);
}