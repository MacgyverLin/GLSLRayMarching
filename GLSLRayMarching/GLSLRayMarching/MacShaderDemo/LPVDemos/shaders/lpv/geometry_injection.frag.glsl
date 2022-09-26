#version 300 es
precision highp float;

#include <lpv_common.glsl>

layout(location = 0) out vec4 o_red_color;
layout(location = 1) out vec4 o_green_color;
layout(location = 2) out vec4 o_blue_color;

uniform vec3 u_light_direction;

struct RSMTexel {
	vec3 world_position;
	vec3 world_normal;
	vec4 flux;
};

in RSMTexel v_rsm_texel;
in float surfel_area;

float calculateBlockingPotencial(vec3 dir, vec3 normal)
{
	return clamp((surfel_area * clamp(dot(normal, dir), 0.0, 1.0)) / (CELLSIZE * CELLSIZE), 0.0, 1.0); //It is probability so 0.0 - 1.0
}

//#define DEBUG_RENDER

void main()
{
    //Discard pixels with really small normal
	if (length(v_rsm_texel.world_normal) < 0.01) {
		discard;
	}

	vec3 light_dir = normalize(u_light_direction - v_rsm_texel.world_position); //Both are in world space
	float blocking_potencial = calculateBlockingPotencial(light_dir, v_rsm_texel.world_normal);

	vec4 SH_coeffs = evalCosineLobeToDir(v_rsm_texel.world_normal) * blocking_potencial;
	vec4 shR = SH_coeffs * v_rsm_texel.flux.r;
    vec4 shG = SH_coeffs * v_rsm_texel.flux.g;
    vec4 shB = SH_coeffs * v_rsm_texel.flux.b;

	#ifdef DEBUG_RENDER
    	o_red_color = vec4(normalize(shR.xyz),1.0);
    	o_green_color = vec4(normalize(shG.xyz),1.0);
    	o_blue_color = vec4(normalize(shB.xyz),1.0);
    #else
    	o_red_color = shR;
    	o_green_color = shG;
    	o_blue_color = shB;
    #endif
}
