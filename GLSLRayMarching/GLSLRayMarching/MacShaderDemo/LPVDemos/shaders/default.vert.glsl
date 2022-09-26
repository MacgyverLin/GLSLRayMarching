#version 300 es

#include <mesh_attributes.glsl>
#include <scene_uniforms.glsl>

uniform mat4 u_world_from_local;
uniform mat4 u_view_from_world;
uniform mat4 u_projection_from_view;
uniform mat4 u_light_projection_from_world;

out vec3 v_position;
out vec3 v_normal;
out vec3 v_tangent;
out vec3 v_bitangent;
out vec2 v_tex_coord;
out vec4 v_light_space_position;
out vec4 v_world_space_position;
out vec3 v_world_space_normal;

void main()
{
	mat4 view_from_local = u_view_from_world * u_world_from_local;

	mat4 world_normal_matrix = transpose(inverse(u_world_from_local));

	// NOTE: normal only works for uniformly scaled objects!
	vec4 view_space_position = view_from_local * vec4(a_position, 1.0);
	vec4 view_space_normal   = view_from_local * vec4(a_normal, 0.0);
	vec4 view_space_tangent  = view_from_local * vec4(a_tangent.xyz, 0.0);

	v_position  = vec3(view_space_position);
	v_normal    = vec3(view_space_normal);
	v_tangent   = vec3(view_space_tangent);
	v_bitangent = vec3(vec3(a_tangent.w) * cross(view_space_normal.xyz, view_space_tangent.xyz));

	v_tex_coord = a_tex_coord;

	// TODO: Clean up these these transformations into one matrix multiplication
	// (i.e. from camera view space to light projected with bias and offset)
	vec4 world_space_position = u_world_from_local * vec4(a_position, 1.0);
	v_light_space_position = u_light_projection_from_world * vec4(world_space_position.xyz, 1.0);
	v_light_space_position *= vec4(0.5, 0.5, 0.5, 1.0);
	v_light_space_position += vec4(0.5, 0.5, 0.5, 0.0);
	v_world_space_position = world_space_position;
	v_world_space_normal = normalize(vec3(world_normal_matrix * vec4(a_normal,0.0)));

	gl_Position = u_projection_from_view * view_space_position;

}
