#pragma once

inline constexpr char light_field_renderer_vert[] = R"(
#version 330 core
#line 5

// Properties of desired camera
uniform mat4 VP;
uniform float focus_distance;
uniform vec3 eye;
uniform vec3 forward;
uniform vec3 right;
uniform vec3 up;
uniform float aperture_diameter;

// Properties of current data camera
uniform vec2 data_eye;

layout (location = 0) in vec2 position;
layout (location = 1) in vec2 texcoord;

out vec2 aperture_texcoord;
out vec2 data_image_coord;

/******************************************************************
Forward declared fuction that is appended later depending on the 
data camera projection/parameterization used for the light field.
******************************************************************/
vec2 projectToDataCamera(vec3 point);

void main() 
{
    // Subtract because the vertex will be located on the opposite side of the data eye
    vec3 aperture = eye - (position.x * right + position.y * up) * aperture_diameter;

    // Project aperture point to focal plane through the ray that passes through the data camera
    vec3 a2d = vec3(data_eye, 0.0) - aperture;
    vec3 focal_point = aperture + a2d * (focus_distance / dot(a2d, forward));
    
    aperture_texcoord = texcoord;

    // Point on focal plane projected to the image space of the data camera
    data_image_coord = projectToDataCamera(focal_point);

    // Point on focal plane projected to the image space of the desired camera. The point is projected to a plane parallel 
    // with the camera plane first. This seems to handle some edge cases close to z=0 that I haven't figured out yet.
    vec3 e2p = normalize(focal_point - eye);
    gl_Position = VP * vec4(eye.xy + e2p.xy * (-1 / e2p.z), eye.z - 1, 1.0);
})";