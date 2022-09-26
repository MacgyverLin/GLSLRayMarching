#version 300 es

#include <mesh_attributes.glsl>
layout(location = 10) in vec3 a_translation;
layout(location = 11) in vec3 a_index;

uniform mat4 u_projection_from_world;

flat out ivec3 v_index;
smooth out vec3 v_normal;

void main()
{
	v_index = ivec3(a_index);
	v_normal = normalize(a_position);

	vec3 translated_position = a_position + a_translation;
	gl_Position = u_projection_from_world * vec4(translated_position, 1.0);
}
