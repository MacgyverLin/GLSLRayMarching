#version 300 es

#include <mesh_attributes.glsl>
layout(location = 10) in vec3 a_translation;

uniform mat4 u_projection_from_world;

void main()
{
	vec3 translated_position = a_position + a_translation;
	gl_Position = u_projection_from_world * vec4(translated_position, 1.0);
}
