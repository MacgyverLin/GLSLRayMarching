#version 300 es

#include <mesh_attributes.glsl>

out vec2 v_tex_coord;

void main()
{
	v_tex_coord = a_position.xy * vec2(0.5) + vec2(0.5);

	// Force z/w == 1.0 so that we can render with depth test equal to the clear depth
	gl_Position = vec4(a_position.xy, 1.0, 1.0);
}
