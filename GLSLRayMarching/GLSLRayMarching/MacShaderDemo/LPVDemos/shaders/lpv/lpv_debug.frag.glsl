#version 300 es
precision lowp float;

#include <lpv_common.glsl>

flat in ivec3 v_index;
smooth in vec3 v_normal;

uniform int u_lpv_size;
uniform sampler2D u_lpv_red;
uniform sampler2D u_lpv_green;
uniform sampler2D u_lpv_blue;

layout(location = 0) out vec4 o_color;

void main()
{
	int x = v_index.x + v_index.z * u_lpv_size;
	int y = v_index.y;
	ivec2 index = ivec2(x, y);

	vec4 red_coef   = texelFetch(u_lpv_red,   index, 0);
	vec4 green_coef = texelFetch(u_lpv_green, index, 0);
	vec4 blue_coef  = texelFetch(u_lpv_blue,  index, 0);

	vec4 sh = dirToSH(v_normal);
	float r = dot(sh, red_coef);
	float g = dot(sh, green_coef);
	float b = dot(sh, blue_coef);

	vec3 color = vec3(r, g, b);
	o_color = vec4(color, 1.0);
}
