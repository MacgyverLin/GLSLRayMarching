#version 300 es
precision highp float;

#define PI 3.1415926f

#include <lpv_common.glsl>

layout(location = 0) out vec4 o_red_color;
layout(location = 1) out vec4 o_green_color;
layout(location = 2) out vec4 o_blue_color;

struct RSMTexel {
	vec3 world_position;
	vec3 world_normal;
	vec4 flux;
};

uniform lowp int u_grid_size;
uniform lowp int u_rsm_size;

in RSMTexel v_rsm_texel;

void main()
{
	float surfelWeight = float(u_grid_size) / float(u_rsm_size);
	vec4 SH_coeffs = (evalCosineLobeToDir(v_rsm_texel.world_normal) / PI) * surfelWeight;
	vec4 shR = SH_coeffs * v_rsm_texel.flux.r;
	vec4 shG = SH_coeffs * v_rsm_texel.flux.g;
	vec4 shB = SH_coeffs * v_rsm_texel.flux.b;

	o_red_color = shR;
	o_green_color = shG;
	o_blue_color = shB;
}
