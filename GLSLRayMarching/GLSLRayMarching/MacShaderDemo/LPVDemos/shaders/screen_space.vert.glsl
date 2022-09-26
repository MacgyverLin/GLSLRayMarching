#version 300 es

#include <mesh_attributes.glsl>

out vec2 v_tex_coord;

void main()
{
	v_tex_coord = a_position.xy * vec2(0.5) + vec2(0.5);
	gl_Position = vec4(a_position, 1.0);
}
