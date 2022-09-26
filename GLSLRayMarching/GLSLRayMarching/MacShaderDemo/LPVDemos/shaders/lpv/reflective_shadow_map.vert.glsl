#version 300 es

#include <mesh_attributes.glsl>

uniform mat4 u_world_from_local;
uniform mat4 u_light_projection_from_world;

out vec3 v_world_space_normal;
out vec4 v_world_space_position;
out vec2 v_tex_coord;

void main()
{
	v_tex_coord = a_tex_coord;

	mat4 normal_matrix = transpose(inverse(u_world_from_local));
	v_world_space_position = u_world_from_local * vec4(a_position, 1.0);
	v_world_space_normal = vec3(normal_matrix * vec4(a_normal, 0.0));

	gl_Position = u_light_projection_from_world * u_world_from_local * vec4(a_position, 1.0);
}
