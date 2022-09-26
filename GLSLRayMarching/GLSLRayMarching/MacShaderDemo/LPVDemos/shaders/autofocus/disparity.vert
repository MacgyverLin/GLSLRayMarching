#pragma once

inline constexpr char disparity_vert[] = R"(
#version 330 core
#line 5

// Properties of desired camera
uniform float focus_distance;
uniform vec3 eye;
uniform vec3 forward;
uniform vec3 up;
uniform vec3 right;
uniform mat4 VP;

// Properties of current data camera
uniform vec2 data_eye;

uniform vec2 size;

layout (location = 0) in vec2 position;

out vec2 st;

/******************************************************************
Forward declared fuction that is appended later depending on the 
data camera projection/parameterization used for the light field.
******************************************************************/
vec2 projectToDataCamera(vec3 point);

void main() 
{
    vec2 p = position * size;
    vec3 focal_point = eye + forward * focus_distance + p.x * right + p.y * up;

    st = projectToDataCamera(focal_point);

    vec3 e2p = normalize(focal_point - eye);
    gl_Position = VP * vec4(vec3(eye.xy + e2p.xy * (-1 / e2p.z), eye.z - 1), 1.0);
})";