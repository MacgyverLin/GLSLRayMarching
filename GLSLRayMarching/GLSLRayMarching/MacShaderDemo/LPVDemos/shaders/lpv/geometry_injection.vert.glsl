#version 300 es
precision highp float;

#include <lpv_common.glsl>

#define PI 3.1415926f
#define DEG_TO_RAD PI / 180.0f

uniform int u_texture_size;
uniform int u_rsm_size;
uniform vec3 u_light_direction;

uniform sampler2D u_rsm_flux;
uniform sampler2D u_rsm_world_positions;
uniform sampler2D u_rsm_world_normals;

struct RSMTexel 
{
	vec3 world_position;
	vec3 world_normal;
	vec4 flux;
};

out RSMTexel v_rsm_texel;
out float surfel_area;

RSMTexel getRSMTexel(ivec2 texCoord) 
{
	RSMTexel texel;
	texel.world_normal = texelFetch(u_rsm_world_normals, texCoord, 0).xyz;

	// Displace the position by half a normal
	texel.world_position = texelFetch(u_rsm_world_positions, texCoord, 0).xyz + 0.5 * texel.world_normal;
	texel.flux = texelFetch(u_rsm_flux, texCoord, 0);
	return texel;
}

// Get ndc texture coordinates from gridcell
vec2 getRenderingTexCoords(ivec3 gridCell)
{
	float f_texture_size = float(u_texture_size);
	// Displace int coordinates with 0.5
	vec2 tex_coords = vec2((gridCell.x % u_texture_size) + u_texture_size * gridCell.z, gridCell.y) + vec2(0.5);
	// Get ndc coordinates
	vec2 ndc = vec2((2.0 * tex_coords.x) / (f_texture_size * f_texture_size), (2.0 * tex_coords.y) / f_texture_size) - vec2(1.0);
	return ndc;
}

// Sample from light
float calculateSurfelAreaLight(vec3 lightPos)
{
    float fov = 90.0f; //TODO fix correct fov
    float aspect = float(u_rsm_size / u_rsm_size);
    float tan_fov_x_half = tan(0.5 * fov * DEG_TO_RAD);
    float tan_fov_y_half = tan(0.5 * fov * DEG_TO_RAD) * aspect;

	return (4.0 * lightPos.z * lightPos.z * tan_fov_x_half * tan_fov_y_half) / float(u_rsm_size * u_rsm_size);
}

void main()
{
	ivec2 rsm_tex_coords = ivec2(gl_VertexID % u_rsm_size, gl_VertexID / u_rsm_size);
	v_rsm_texel = getRSMTexel(rsm_tex_coords);
	ivec3 v_grid_cell = getGridCelli(v_rsm_texel.world_position, u_texture_size);

	vec2 tex_coord = getRenderingTexCoords(v_grid_cell);

	gl_PointSize = 1.0;
	gl_Position = vec4(tex_coord, 0.0, 1.0);

    surfel_area = calculateSurfelAreaLight(u_light_direction);
}
