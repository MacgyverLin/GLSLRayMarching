#version 300 es
precision highp float;

#include <common.glsl>
#include <lpv_common.glsl>

in vec3 v_position;
in vec3 v_normal;
in vec3 v_tangent;
in vec3 v_bitangent;
in vec2 v_tex_coord;
in vec4 v_light_space_position;
in vec4 v_world_space_position;
in vec3 v_world_space_normal;

#include <scene_uniforms.glsl>

uniform sampler2D u_diffuse_map;
uniform sampler2D u_specular_map;
uniform sampler2D u_normal_map;
uniform sampler2D u_shadow_map;

uniform vec3 u_dir_light_color;
uniform vec3 u_dir_light_view_direction;
uniform float u_ambient_light_attenuation;

struct SpotLight {
	vec3  color;
	float cone;
	vec3  view_position;
	vec3  view_direction;
};

#define NUM_SPOTLIGHTS 0
#if NUM_SPOTLIGHTS
uniform SpotLight[NUM_SPOTLIGHTS] u_spot_light;
#endif

// Light Propagation Volumes uniforms
uniform int u_lpv_grid_size;
uniform float u_indirect_light_attenuation;

uniform bool u_render_direct_light;
uniform bool u_render_indirect_light;

uniform sampler2D u_red_indirect_light;
uniform sampler2D u_green_indirect_light;
uniform sampler2D u_blue_indirect_light;

layout(location = 0) out vec4 o_color;

vec4 sample_grid_trilinear(in sampler2D t, vec3 grid_cell) {
	float f_grid_size = float(u_lpv_grid_size);
	float zFloor = floor(grid_cell.z);

	vec2 tex_coord = vec2(grid_cell.x / (f_grid_size * f_grid_size) + zFloor / f_grid_size , grid_cell.y / f_grid_size);

	vec4 t1 = texture(t, tex_coord);
	vec4 t2 = texture(t, vec2(tex_coord.x + (1.0 / f_grid_size), tex_coord.y));

	return mix(t1,t2, grid_cell.z - zFloor);
}

vec3 get_lpv_intensity()
{
	vec4 sh_intensity = dirToSH(-v_world_space_normal);
	vec3 grid_cell = getGridCellf(v_world_space_position.xyz, u_lpv_grid_size);

	vec4 red_light = sample_grid_trilinear(u_red_indirect_light, grid_cell);
	vec4 green_light = sample_grid_trilinear(u_green_indirect_light, grid_cell);
	vec4 blue_light = sample_grid_trilinear(u_blue_indirect_light, grid_cell);

	// Dot with sh coeffiencients to get directioal light intesity from the normal
	return vec3(dot(sh_intensity, red_light), dot(sh_intensity, green_light), dot(sh_intensity, blue_light));
}

void main()
{
	vec3 N = normalize(v_normal);
	vec3 T = normalize(v_tangent);
	vec3 B = normalize(v_bitangent);

	// NOTE: We probably don't really need all (or any) of these
	reortogonalize(N, T);
	reortogonalize(N, B);
	reortogonalize(T, B);
	mat3 tbn = mat3(T, B, N);

	// Rotate normal map normals from tangent space to view space (normal mapping)
	vec3 mapped_normal = texture(u_normal_map, v_tex_coord).xyz;
	mapped_normal = normalize(mapped_normal * vec3(2.0) - vec3(1.0));
	N = tbn * mapped_normal;

	vec3 diffuse = texture(u_diffuse_map, v_tex_coord).rgb;
	float shininess = texture(u_specular_map, v_tex_coord).r;

	vec3 lpv_intensity = get_lpv_intensity();
	vec3 lpv_radiance = vec3(max(0.0, lpv_intensity.r), max(0.0, lpv_intensity.g), max(0.0, lpv_intensity.b)) / PI;
	vec3 indirect_light = diffuse * lpv_radiance;

	vec3 wi = normalize(-u_dir_light_view_direction);
	vec3 wo = normalize(-v_position);

	float lambertian = saturate(dot(N, wi));

	//////////////////////////////////////////////////////////
	// Ambient
	vec3 color = u_ambient_color.rgb * diffuse * u_ambient_light_attenuation;

	//////////////////////////////////////////////////////////
	// Directional light

	// Shadow visibility
	// TODO: Probably don't hardcode bias
	// TODO: Send in shadow map pixel size as a uniform
	const float bias = 0.0029;
	vec2 texel_size = vec2(1.0) / vec2(textureSize(u_shadow_map, 0));
	vec3 light_space = v_light_space_position.xyz / v_light_space_position.w;
	float visibility = sample_shadow_map_pcf(u_shadow_map, light_space.xy, light_space.z, texel_size, bias);

	if (lambertian > 0.0 && visibility > 0.0)
	{
		vec3 wh = normalize(wi + wo);

		// Diffuse
		color += visibility * diffuse * lambertian * u_dir_light_color;

		// Specular
		float specular_angle = saturate(dot(N, wh));
		float specular_power = pow(2.0, 13.0 * shininess); // (fake glossiness from the specular map)
		float specular = pow(specular_angle, specular_power);
		color += visibility * shininess * specular * u_dir_light_color;
	}

	//////////////////////////////////////////////////////////
	// spot light
	#if NUM_SPOTLIGHTS
	for(int i = 0; i < NUM_SPOTLIGHTS; i++)
	{
		vec3 light_to_frag = v_position - u_spot_light[i].view_position;
		float distance_attenuation = 1.0 / max(0.01, lengthSquared(light_to_frag));

		vec3 wi = normalize(-light_to_frag);
		float lambertian = saturate(dot(N, wi));

		const float smoothing = 0.15;
		float inner = u_spot_light[i].cone - smoothing;
		float outer = u_spot_light[i].cone;
		float cone_attenuation = 1.0 - smoothstep(inner, outer, 1.0 - dot(-wi, u_spot_light[i].view_direction));

		if (lambertian > 0.0 && cone_attenuation > 0.0)
		{
			vec3 wh = normalize(wi + wo);

			// diffuse
			color += diffuse * distance_attenuation * cone_attenuation * lambertian * u_spot_light[i].color;

			// specular
			float specular_angle = saturate(dot(N, wh));
			float specular_power = pow(abs(2.0), 13.0 * shininess);
			float specular = pow(abs(specular_angle), specular_power);
			color += shininess * distance_attenuation * cone_attenuation * specular * u_spot_light[i].color;
		}
	}
	#endif

	// Output tangents
	if(u_render_direct_light && u_render_indirect_light)
		color = color + indirect_light * u_indirect_light_attenuation;
	else if (u_render_indirect_light)
		color = indirect_light * u_indirect_light_attenuation;
	else if(!u_render_direct_light)
		color = vec3(0.0);

	o_color = vec4(color / (color + vec3(1.0)), 1.0);
}
