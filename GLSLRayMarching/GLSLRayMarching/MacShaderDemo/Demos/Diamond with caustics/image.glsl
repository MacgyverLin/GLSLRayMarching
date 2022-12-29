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

vec3 getCameraRayDirection(in vec2 uv, in vec3 origin, in vec3 target)
{
    vec3 forward = normalize(target - origin);
    vec3 right = normalize(cross(vec3(0.0, 1.0, 0.0), forward));
    vec3 up = normalize(cross(forward, right));
    return normalize(forward * 0.5 / tan(CAMERA_FOV / 2.0) + uv.x * right + uv.y * up);
}

vec2 getSampleSubPixelOffset(in int sampleIdx, in vec2 uv)
{
    return texture(iChannel1, vec2(sampleIdx, uv.y) / iChannelResolution[1].xy).rg;
}

vec2 getCameraAngles()
{
    return vec2(
        (iMouse.x / iResolution.x) * PI,
        PI / 6.0 + PI / 6.0 * ((iMouse.y / iResolution.y) - 0.5) * 2.0);
}

vec3 applyColorCorrection(in vec3 color)
{
    return color / (vec3(1.0) + color);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec3 color = vec3(0.0);
    for (int sampleIdx = 0; sampleIdx < NUMBER_OF_AA_SAMPLES; ++sampleIdx)
    {
        vec2 subPixelOffset = getSampleSubPixelOffset(sampleIdx, fragCoord);
        vec2 uv = (fragCoord + subPixelOffset * 1.0) / iResolution.xy;
        vec2 cameraAngles = getCameraAngles();

        vec3 origin = vec3(sin(cameraAngles.x), sin(cameraAngles.y), -cos(cameraAngles.x));
        origin.xz *= cos(cameraAngles.y);
        origin *= CAMERA_DISTANCE;
        origin += CAMERA_TARGET;
        vec3 direction = getCameraRayDirection(
            vec2(uv.x - 0.5, (uv.y - 0.5) / (iResolution.x / iResolution.y)),
            origin, CAMERA_TARGET);

        color += applyColorCorrection(traceScene(origin, direction, iChannel0, float(iFrame)));
    }
    fragColor = vec4(color / float(NUMBER_OF_AA_SAMPLES), 1.0);
}
