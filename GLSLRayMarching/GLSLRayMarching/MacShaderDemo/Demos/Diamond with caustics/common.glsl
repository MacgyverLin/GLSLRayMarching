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

const float PI = 3.14159265358979323846;

const float CAMERA_FOV = PI / 3.0;
const float CAMERA_DISTANCE = 2.0;
const vec3 CAMERA_TARGET = vec3(0.0, 0.1, 0.0);

const vec3 SUN_DIRECTION = normalize(vec3(-1.0, 1.0, 1.0));
const vec3 SUN_COLOR = vec3(200.0);

const vec3 GROUND_COLOR = vec3(0.6, 0.8, 0.4);

const float DIAMOND_IOR_RED = 2.42;
const float DIAMOND_IOR_GREEN = 2.425;
const float DIAMOND_IOR_BLUE = 2.43;
const float AIR_IOR = 1.0;

const vec2 PROJECTION_SIZE = vec2(4.0, 4.0);
const vec2 PROJECTION_OFFSET = vec2(-2.0, -2.0);

#define DEBUG_PROJECTION_BOUNDS 0

const int MAX_NUMBER_OF_BOUNCES = 4;

const int NUMBER_OF_CAUSTICS_SAMPLES = 8;
const float CAUSTICS_HISTORY_FRAMES = 768.0;

// Range [0, a browser explodes].
const int NUMBER_OF_AA_SAMPLES = 8;

float getPlaneIntersection(
    in vec3 origin, in vec3 direction,
    in vec3 planeNormal, in float planeDistance,
    in float tMin, in float tMax,
    out vec3 normal)
{
    float distanceToPlane = planeDistance - dot(planeNormal, origin);
    float cosA = dot(planeNormal, direction);
    if (abs(cosA) < 1e-5)
        return tMax;
    float t = distanceToPlane / cosA;
    if (t >= tMin)
    {
        normal = cosA > 0.0 ? -planeNormal : planeNormal;
        return min(t, tMax);
    }
    return tMax;
}

float getDiamondIntersection(
    in vec3 origin, in vec3 direction,
    in float tMin, in float tMax,
    out vec3 normal)
{
    float tCandidate = tMax;
    vec3 normalCandidate;
    tCandidate = getPlaneIntersection(origin, direction, vec3(0.0, 0.70711, 0.70711), 0.53033, tMin, tMax, normalCandidate); if (tCandidate < tMax) { vec3 position = origin + direction * tCandidate; if (dot(vec3(0.70711, -0.5, -0.5), position) <= -0. && dot(vec3(0.0, 0.0, -1.), position) <= 0.0 && dot(vec3(-0.70711, -0.5, -0.5), position) <= 0.0 && dot(vec3(-0., -1., 0.0), position) <= 0.0 && dot(vec3(0.70711, 0.5, 0.5), position) <= 0.5 && dot(vec3(0.5, 0.85355, 0.14645), position) <= 0.5 && dot(vec3(0.0, 1.0, 0.0), position) <= 0.5 && dot(vec3(-0.5, 0.85355, 0.14645), position) <= 0.5 && dot(vec3(-0.70711, 0.5, 0.5), position) <= 0.5 && dot(vec3(-0.5, 0.14645, 0.85355), position) <= 0.5 && dot(vec3(-0., 0.0, 1.0), position) <= 0.5 && dot(vec3(0.5, 0.14645, 0.85355), position) <= 0.5) { tMax = tCandidate; normal = normalCandidate; } }
    tCandidate = getPlaneIntersection(origin, direction, vec3(0.70711, -0.5, -0.5), -0., tMin, tMax, normalCandidate); if (tCandidate < tMax) { vec3 position = origin + direction * tCandidate; if (dot(vec3(0.0, 0.70711, 0.70711), position) <= 0.53033 && dot(vec3(0.0, 0.0, -1.), position) <= 0.0 && dot(vec3(-0.70711, -0.5, -0.5), position) <= 0.0 && dot(vec3(-0., -1., 0.0), position) <= 0.0 && dot(vec3(0.70711, 0.5, 0.5), position) <= 0.5 && dot(vec3(0.5, 0.85355, 0.14645), position) <= 0.5 && dot(vec3(0.0, 1.0, 0.0), position) <= 0.5 && dot(vec3(-0.5, 0.85355, 0.14645), position) <= 0.5 && dot(vec3(-0.70711, 0.5, 0.5), position) <= 0.5 && dot(vec3(-0.5, 0.14645, 0.85355), position) <= 0.5 && dot(vec3(-0., 0.0, 1.0), position) <= 0.5 && dot(vec3(0.5, 0.14645, 0.85355), position) <= 0.5) { tMax = tCandidate; normal = normalCandidate; } }
    tCandidate = getPlaneIntersection(origin, direction, vec3(0.0, 0.0, -1.), 0.0, tMin, tMax, normalCandidate); if (tCandidate < tMax) { vec3 position = origin + direction * tCandidate; if (dot(vec3(0.0, 0.70711, 0.70711), position) <= 0.53033 && dot(vec3(0.70711, -0.5, -0.5), position) <= -0. && dot(vec3(-0.70711, -0.5, -0.5), position) <= 0.0 && dot(vec3(-0., -1., 0.0), position) <= 0.0 && dot(vec3(0.70711, 0.5, 0.5), position) <= 0.5 && dot(vec3(0.5, 0.85355, 0.14645), position) <= 0.5 && dot(vec3(0.0, 1.0, 0.0), position) <= 0.5 && dot(vec3(-0.5, 0.85355, 0.14645), position) <= 0.5 && dot(vec3(-0.70711, 0.5, 0.5), position) <= 0.5 && dot(vec3(-0.5, 0.14645, 0.85355), position) <= 0.5 && dot(vec3(-0., 0.0, 1.0), position) <= 0.5 && dot(vec3(0.5, 0.14645, 0.85355), position) <= 0.5) { tMax = tCandidate; normal = normalCandidate; } }
    tCandidate = getPlaneIntersection(origin, direction, vec3(-0.70711, -0.5, -0.5), 0.0, tMin, tMax, normalCandidate); if (tCandidate < tMax) { vec3 position = origin + direction * tCandidate; if (dot(vec3(0.0, 0.70711, 0.70711), position) <= 0.53033 && dot(vec3(0.70711, -0.5, -0.5), position) <= -0. && dot(vec3(0.0, 0.0, -1.), position) <= 0.0 && dot(vec3(-0., -1., 0.0), position) <= 0.0 && dot(vec3(0.70711, 0.5, 0.5), position) <= 0.5 && dot(vec3(0.5, 0.85355, 0.14645), position) <= 0.5 && dot(vec3(0.0, 1.0, 0.0), position) <= 0.5 && dot(vec3(-0.5, 0.85355, 0.14645), position) <= 0.5 && dot(vec3(-0.70711, 0.5, 0.5), position) <= 0.5 && dot(vec3(-0.5, 0.14645, 0.85355), position) <= 0.5 && dot(vec3(-0., 0.0, 1.0), position) <= 0.5 && dot(vec3(0.5, 0.14645, 0.85355), position) <= 0.5) { tMax = tCandidate; normal = normalCandidate; } }
    tCandidate = getPlaneIntersection(origin, direction, vec3(-0., -1., 0.0), 0.0, tMin, tMax, normalCandidate); if (tCandidate < tMax) { vec3 position = origin + direction * tCandidate; if (dot(vec3(0.0, 0.70711, 0.70711), position) <= 0.53033 && dot(vec3(0.70711, -0.5, -0.5), position) <= -0. && dot(vec3(0.0, 0.0, -1.), position) <= 0.0 && dot(vec3(-0.70711, -0.5, -0.5), position) <= 0.0 && dot(vec3(0.70711, 0.5, 0.5), position) <= 0.5 && dot(vec3(0.5, 0.85355, 0.14645), position) <= 0.5 && dot(vec3(0.0, 1.0, 0.0), position) <= 0.5 && dot(vec3(-0.5, 0.85355, 0.14645), position) <= 0.5 && dot(vec3(-0.70711, 0.5, 0.5), position) <= 0.5 && dot(vec3(-0.5, 0.14645, 0.85355), position) <= 0.5 && dot(vec3(-0., 0.0, 1.0), position) <= 0.5 && dot(vec3(0.5, 0.14645, 0.85355), position) <= 0.5) { tMax = tCandidate; normal = normalCandidate; } }
    tCandidate = getPlaneIntersection(origin, direction, vec3(0.70711, 0.5, 0.5), 0.5, tMin, tMax, normalCandidate); if (tCandidate < tMax) { vec3 position = origin + direction * tCandidate; if (dot(vec3(0.0, 0.70711, 0.70711), position) <= 0.53033 && dot(vec3(0.70711, -0.5, -0.5), position) <= -0. && dot(vec3(0.0, 0.0, -1.), position) <= 0.0 && dot(vec3(-0.70711, -0.5, -0.5), position) <= 0.0 && dot(vec3(-0., -1., 0.0), position) <= 0.0 && dot(vec3(0.5, 0.85355, 0.14645), position) <= 0.5 && dot(vec3(0.0, 1.0, 0.0), position) <= 0.5 && dot(vec3(-0.5, 0.85355, 0.14645), position) <= 0.5 && dot(vec3(-0.70711, 0.5, 0.5), position) <= 0.5 && dot(vec3(-0.5, 0.14645, 0.85355), position) <= 0.5 && dot(vec3(-0., 0.0, 1.0), position) <= 0.5 && dot(vec3(0.5, 0.14645, 0.85355), position) <= 0.5) { tMax = tCandidate; normal = normalCandidate; } }
    tCandidate = getPlaneIntersection(origin, direction, vec3(0.5, 0.85355, 0.14645), 0.5, tMin, tMax, normalCandidate); if (tCandidate < tMax) { vec3 position = origin + direction * tCandidate; if (dot(vec3(0.0, 0.70711, 0.70711), position) <= 0.53033 && dot(vec3(0.70711, -0.5, -0.5), position) <= -0. && dot(vec3(0.0, 0.0, -1.), position) <= 0.0 && dot(vec3(-0.70711, -0.5, -0.5), position) <= 0.0 && dot(vec3(-0., -1., 0.0), position) <= 0.0 && dot(vec3(0.70711, 0.5, 0.5), position) <= 0.5 && dot(vec3(0.0, 1.0, 0.0), position) <= 0.5 && dot(vec3(-0.5, 0.85355, 0.14645), position) <= 0.5 && dot(vec3(-0.70711, 0.5, 0.5), position) <= 0.5 && dot(vec3(-0.5, 0.14645, 0.85355), position) <= 0.5 && dot(vec3(-0., 0.0, 1.0), position) <= 0.5 && dot(vec3(0.5, 0.14645, 0.85355), position) <= 0.5) { tMax = tCandidate; normal = normalCandidate; } }
    tCandidate = getPlaneIntersection(origin, direction, vec3(0.0, 1.0, 0.0), 0.5, tMin, tMax, normalCandidate); if (tCandidate < tMax) { vec3 position = origin + direction * tCandidate; if (dot(vec3(0.0, 0.70711, 0.70711), position) <= 0.53033 && dot(vec3(0.70711, -0.5, -0.5), position) <= -0. && dot(vec3(0.0, 0.0, -1.), position) <= 0.0 && dot(vec3(-0.70711, -0.5, -0.5), position) <= 0.0 && dot(vec3(-0., -1., 0.0), position) <= 0.0 && dot(vec3(0.70711, 0.5, 0.5), position) <= 0.5 && dot(vec3(0.5, 0.85355, 0.14645), position) <= 0.5 && dot(vec3(-0.5, 0.85355, 0.14645), position) <= 0.5 && dot(vec3(-0.70711, 0.5, 0.5), position) <= 0.5 && dot(vec3(-0.5, 0.14645, 0.85355), position) <= 0.5 && dot(vec3(-0., 0.0, 1.0), position) <= 0.5 && dot(vec3(0.5, 0.14645, 0.85355), position) <= 0.5) { tMax = tCandidate; normal = normalCandidate; } }
    tCandidate = getPlaneIntersection(origin, direction, vec3(-0.5, 0.85355, 0.14645), 0.5, tMin, tMax, normalCandidate); if (tCandidate < tMax) { vec3 position = origin + direction * tCandidate; if (dot(vec3(0.0, 0.70711, 0.70711), position) <= 0.53033 && dot(vec3(0.70711, -0.5, -0.5), position) <= -0. && dot(vec3(0.0, 0.0, -1.), position) <= 0.0 && dot(vec3(-0.70711, -0.5, -0.5), position) <= 0.0 && dot(vec3(-0., -1., 0.0), position) <= 0.0 && dot(vec3(0.70711, 0.5, 0.5), position) <= 0.5 && dot(vec3(0.5, 0.85355, 0.14645), position) <= 0.5 && dot(vec3(0.0, 1.0, 0.0), position) <= 0.5 && dot(vec3(-0.70711, 0.5, 0.5), position) <= 0.5 && dot(vec3(-0.5, 0.14645, 0.85355), position) <= 0.5 && dot(vec3(-0., 0.0, 1.0), position) <= 0.5 && dot(vec3(0.5, 0.14645, 0.85355), position) <= 0.5) { tMax = tCandidate; normal = normalCandidate; } }
    tCandidate = getPlaneIntersection(origin, direction, vec3(-0.70711, 0.5, 0.5), 0.5, tMin, tMax, normalCandidate); if (tCandidate < tMax) { vec3 position = origin + direction * tCandidate; if (dot(vec3(0.0, 0.70711, 0.70711), position) <= 0.53033 && dot(vec3(0.70711, -0.5, -0.5), position) <= -0. && dot(vec3(0.0, 0.0, -1.), position) <= 0.0 && dot(vec3(-0.70711, -0.5, -0.5), position) <= 0.0 && dot(vec3(-0., -1., 0.0), position) <= 0.0 && dot(vec3(0.70711, 0.5, 0.5), position) <= 0.5 && dot(vec3(0.5, 0.85355, 0.14645), position) <= 0.5 && dot(vec3(0.0, 1.0, 0.0), position) <= 0.5 && dot(vec3(-0.5, 0.85355, 0.14645), position) <= 0.5 && dot(vec3(-0.5, 0.14645, 0.85355), position) <= 0.5 && dot(vec3(-0., 0.0, 1.0), position) <= 0.5 && dot(vec3(0.5, 0.14645, 0.85355), position) <= 0.5) { tMax = tCandidate; normal = normalCandidate; } }
    tCandidate = getPlaneIntersection(origin, direction, vec3(-0.5, 0.14645, 0.85355), 0.5, tMin, tMax, normalCandidate); if (tCandidate < tMax) { vec3 position = origin + direction * tCandidate; if (dot(vec3(0.0, 0.70711, 0.70711), position) <= 0.53033 && dot(vec3(0.70711, -0.5, -0.5), position) <= -0. && dot(vec3(0.0, 0.0, -1.), position) <= 0.0 && dot(vec3(-0.70711, -0.5, -0.5), position) <= 0.0 && dot(vec3(-0., -1., 0.0), position) <= 0.0 && dot(vec3(0.70711, 0.5, 0.5), position) <= 0.5 && dot(vec3(0.5, 0.85355, 0.14645), position) <= 0.5 && dot(vec3(0.0, 1.0, 0.0), position) <= 0.5 && dot(vec3(-0.5, 0.85355, 0.14645), position) <= 0.5 && dot(vec3(-0.70711, 0.5, 0.5), position) <= 0.5 && dot(vec3(-0., 0.0, 1.0), position) <= 0.5 && dot(vec3(0.5, 0.14645, 0.85355), position) <= 0.5) { tMax = tCandidate; normal = normalCandidate; } }
    tCandidate = getPlaneIntersection(origin, direction, vec3(-0., 0.0, 1.0), 0.5, tMin, tMax, normalCandidate); if (tCandidate < tMax) { vec3 position = origin + direction * tCandidate; if (dot(vec3(0.0, 0.70711, 0.70711), position) <= 0.53033 && dot(vec3(0.70711, -0.5, -0.5), position) <= -0. && dot(vec3(0.0, 0.0, -1.), position) <= 0.0 && dot(vec3(-0.70711, -0.5, -0.5), position) <= 0.0 && dot(vec3(-0., -1., 0.0), position) <= 0.0 && dot(vec3(0.70711, 0.5, 0.5), position) <= 0.5 && dot(vec3(0.5, 0.85355, 0.14645), position) <= 0.5 && dot(vec3(0.0, 1.0, 0.0), position) <= 0.5 && dot(vec3(-0.5, 0.85355, 0.14645), position) <= 0.5 && dot(vec3(-0.70711, 0.5, 0.5), position) <= 0.5 && dot(vec3(-0.5, 0.14645, 0.85355), position) <= 0.5 && dot(vec3(0.5, 0.14645, 0.85355), position) <= 0.5) { tMax = tCandidate; normal = normalCandidate; } }
    tCandidate = getPlaneIntersection(origin, direction, vec3(0.5, 0.14645, 0.85355), 0.5, tMin, tMax, normalCandidate); if (tCandidate < tMax) { vec3 position = origin + direction * tCandidate; if (dot(vec3(0.0, 0.70711, 0.70711), position) <= 0.53033 && dot(vec3(0.70711, -0.5, -0.5), position) <= -0. && dot(vec3(0.0, 0.0, -1.), position) <= 0.0 && dot(vec3(-0.70711, -0.5, -0.5), position) <= 0.0 && dot(vec3(-0., -1., 0.0), position) <= 0.0 && dot(vec3(0.70711, 0.5, 0.5), position) <= 0.5 && dot(vec3(0.5, 0.85355, 0.14645), position) <= 0.5 && dot(vec3(0.0, 1.0, 0.0), position) <= 0.5 && dot(vec3(-0.5, 0.85355, 0.14645), position) <= 0.5 && dot(vec3(-0.70711, 0.5, 0.5), position) <= 0.5 && dot(vec3(-0.5, 0.14645, 0.85355), position) <= 0.5 && dot(vec3(-0., 0.0, 1.0), position) <= 0.5) { tMax = tCandidate; normal = normalCandidate; } }
    return tMax;
}

float getR0(in float ior0, in float ior1)
{
    float ratio = (ior0 - ior1) / (ior0 + ior1);
    return ratio * ratio;
}

float getFresnel(in float cosA, in float r0)
{
    // 1.0001 is used to avoid powering zero (suggested by @Dave_Hoskins).
    return r0 + (1.0 - r0) * pow(1.0001 - cosA, 5.0);
}

struct Optics
{
    float r0;
    float etaIn;
    float etaOut;
};

Optics getOptics(in float ior0, in float ior1)
{
    Optics optics;
    optics.r0 = getR0(ior0, ior1);
    optics.etaIn = ior0 / ior1;
    optics.etaOut = ior1 / ior0;
    return optics;
}

vec3 traceEnvironment(
    in vec3 origin, in vec3 direction, in float tMin, in float tMax,
    in sampler2D projectedTexture, float frame)
{
    vec3 skyColor = mix(
        vec3(3.0, 3.0, 2.0),
        vec3(1.0, 2.0, 7.0),
        clamp(dot(direction, vec3(0.0, 1.0, 0.0)) * 0.8 + 0.2, 0.0, 1.0));
    // Ground intersection.
    vec3 groundNormal = vec3(0.0, 1.0, 0.0);
    float t = getPlaneIntersection(origin, direction, groundNormal, 0.0, tMin, tMax, groundNormal);
    if (t < tMax)
    {
        vec4 data = texture(projectedTexture, vec2(0, 0));
        vec3 position = origin + direction * t;
        vec2 projectionUV = (position.xz - PROJECTION_OFFSET) / PROJECTION_SIZE;
        vec4 projectedColor = texture(projectedTexture, projectionUV);
        vec3 color = projectedColor.rgb * projectedColor.a;
        if (frame - data.z < CAUSTICS_HISTORY_FRAMES)
            color = color / ((frame - data.z) + 1.0) * CAUSTICS_HISTORY_FRAMES;
#if DEBUG_PROJECTION_BOUNDS
        if (projectionUV.x >= 0.0 && projectionUV.x <= 1.0 &&
            projectionUV.y >= 0.0 && projectionUV.y <= 1.0)
        {
            color *= 0.5;
        }
#endif
        return mix(GROUND_COLOR * color, skyColor, smoothstep(0.0, 3.0, length(position)));
    }
    // Sky.
    return skyColor +
        SUN_COLOR * pow(clamp(dot(direction, SUN_DIRECTION), 0.0001, 1.0), 100.0);
}

vec3 traceSceneComponent(
    in vec3 origin, in vec3 direction, in sampler2D projectedTexture,
    in Optics optics, float frame)
{
    float tMin = 1e-5;
    float tMax = 1e3;
    vec3 color = vec3(0.0);
    float weight = 1.0;
    bool inside = false;
    // Diamond intersection.
    for (int bounce = 0; bounce < MAX_NUMBER_OF_BOUNCES; ++bounce)
    {
        vec3 normal = vec3(0.0);
        float t = getDiamondIntersection(origin, direction, tMin, tMax, normal);
        if (t < tMax)
        {
            float cosA = dot(normal, -direction);
            float fresnel = getFresnel(cosA, optics.r0);
            vec3 intersection = origin + direction * t;
            vec3 reflectDirection = reflect(direction, normal);
            vec3 refractDirection = refract(direction, normal, inside ? optics.etaOut : optics.etaIn);

            vec3 envDirection = inside ? refractDirection : reflectDirection;
            color += weight * (inside ? 1.0 - fresnel : fresnel) *
                traceEnvironment(intersection + envDirection * 1e-3, envDirection,
                    tMin, tMax, projectedTexture, frame);
            weight *= inside ? fresnel : 1.0 - fresnel;

            direction = inside ? reflectDirection : refractDirection;
            origin = intersection + direction * 1e-3;
            inside = !inside;
        }
        else
        {
            // If we left the diamond we won't need to return back because
            // it has a convex shape.
            break;
        }
    }
    return color + weight * traceEnvironment(origin, direction, tMin, tMax, projectedTexture, frame);
}

vec3 traceScene(
    in vec3 origin, in vec3 direction, in sampler2D projectedTexture, float frame)
{
    float red = traceSceneComponent(
        origin, direction, projectedTexture, getOptics(AIR_IOR, DIAMOND_IOR_RED), frame).r;
    float green = traceSceneComponent(
        origin, direction, projectedTexture, getOptics(AIR_IOR, DIAMOND_IOR_GREEN), frame).g;
    float blue = traceSceneComponent(
        origin, direction, projectedTexture, getOptics(AIR_IOR, DIAMOND_IOR_BLUE), frame).b;
    return vec3(red, green, blue);
}
