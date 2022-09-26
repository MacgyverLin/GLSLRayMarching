#version 300 es
precision highp float;

layout(location = 0) in vec2 a_point_position;

uniform lowp int u_grid_size;
uniform lowp int u_rsm_size;

uniform sampler2D u_rsm_flux;
uniform sampler2D u_rsm_world_positions;
uniform sampler2D u_rsm_world_normals;

#include <lpv_common.glsl>

struct RSMTexel 
{
	vec3 world_position;
	vec3 world_normal;
	vec4 flux;
};

out RSMTexel v_rsm_texel;

RSMTexel get_rsm_texel(ivec2 texCoord) 
{
	RSMTexel texel;
	texel.world_normal = texelFetch(u_rsm_world_normals, texCoord, 0).xyz;

	// Displace the position by half a normal
	texel.world_position = texelFetch(u_rsm_world_positions, texCoord, 0).xyz + 0.5 * CELLSIZE * texel.world_normal;
	texel.flux = texelFetch(u_rsm_flux, texCoord, 0);
	return texel;
}

// Get ndc texture coordinates from gridcell
vec2 get_grid_output_position(ivec3 gridCell)
{
	float f_texture_size = float(u_grid_size);
	// Displace int coordinates with 0.5
	vec2 tex_coords = vec2((gridCell.x % u_grid_size) + u_grid_size * gridCell.z, gridCell.y) + vec2(0.5);
	// Get ndc coordinates
	vec2 ndc = vec2((2.0 * tex_coords.x) / (f_texture_size * f_texture_size), (2.0 * tex_coords.y) / f_texture_size) - vec2(1.0);
	return ndc;
}

void main()
{
	ivec2 rsm_tex_coords = ivec2(gl_VertexID % u_rsm_size, gl_VertexID / u_rsm_size);
	v_rsm_texel = get_rsm_texel(rsm_tex_coords);
	ivec3 grid_cell = getGridCelli(v_rsm_texel.world_position, u_grid_size);

	vec2 tex_coord = get_grid_output_position(grid_cell);

	gl_PointSize = 1.0;
	gl_Position = vec4(tex_coord, 0.0, 1.0);
}
