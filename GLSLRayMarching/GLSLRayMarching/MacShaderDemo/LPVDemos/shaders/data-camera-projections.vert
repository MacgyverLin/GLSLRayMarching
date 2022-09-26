#pragma once

inline constexpr char perspective_projection[] = R"(
uniform mat4 data_VP;

vec2 projectToDataCamera(vec3 point)
{
    vec4 clip_space = data_VP * vec4(point, 1.0);
    return (clip_space.xy / clip_space.w + 1.0) * 0.5;
})";

inline constexpr char light_slab_projection[] = R"(
uniform vec2 st_size;
uniform float st_distance; // uv |<--st_distance-->| st

vec2 projectToDataCamera(vec3 point)
{
    vec3 direction = normalize(point - vec3(data_eye, 0.0));
    return 0.5 + (data_eye + direction.xy * (-st_distance / direction.z)) / st_size;
})";