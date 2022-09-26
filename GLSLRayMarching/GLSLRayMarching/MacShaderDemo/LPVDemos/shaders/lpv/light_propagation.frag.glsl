#version 300 es
precision highp float;

#define PI 3.1415926f

#include <lpv_common.glsl>

uniform highp int u_grid_size;

uniform sampler2D u_red_contribution;
uniform sampler2D u_green_contribution;
uniform sampler2D u_blue_contribution;

uniform sampler2D u_red_geometry_volume;
uniform sampler2D u_green_geometry_volume;
uniform sampler2D u_blue_geometry_volume;

uniform bool u_first_iteration;

flat in ivec2 v_cell_index;

layout(location = 0) out vec4 o_red_color;
layout(location = 1) out vec4 o_green_color;
layout(location = 2) out vec4 o_blue_color;

layout(location = 3) out vec4 o_next_iteration_red_color;
layout(location = 4) out vec4 o_next_iteration_green_color;
layout(location = 5) out vec4 o_next_iteration_blue_color;

vec4 red_contribution = vec4(0.0);
vec4 green_contribution = vec4(0.0);
vec4 blue_contribution = vec4(0.0);
float occlusion_amplifier = 1.0f;

// orientation = [ right | up | forward ] = [ x | y | z ]
const mat3 neighbourOrientations[6] = mat3[] (
    // Z+
    mat3(1, 0, 0,0, 1, 0,0, 0, 1),
    // Z-
    mat3(-1, 0, 0,0, 1, 0,0, 0, -1),
    // X+
    mat3(0, 0, 1,0, 1, 0,-1, 0, 0
        ),
    // X-
    mat3(0, 0, -1,0, 1, 0,1, 0, 0),
    // Y+
    mat3(1, 0, 0,0, 0, 1,0, -1, 0),
    // Y-
    mat3(1, 0, 0,0, 0, -1,0, 1, 0)
);

// Faces in cube
const ivec2 sideFaces[4] = ivec2[] (
    ivec2(1, 0),   // right
    ivec2(0, 1),   // up
    ivec2(-1, 0),  // left
    ivec2(0, -1)   // down
);

vec3 get_eval_side_direction(int index, mat3 orientation)
{
    const float small_component = 0.4472135; // 1 / sqrt(5)
    const float big_component = 0.894427; // 2 / sqrt(5)

    vec2 current_side = vec2(sideFaces[index]);
    return orientation * vec3(current_side.x * small_component, current_side.y * small_component, big_component);
}

vec3 get_reproj_side_direction(int index, mat3 orientation)
{
    ivec2 current_side = sideFaces[index];
    return orientation * vec3(current_side.x, current_side.y, 0);
}

void propagate()
{
    // Use solid angles to avoid inaccurate integral value stemming from low-order SH approximations
    const float direct_face_solid_angle = 0.4006696846f / PI;
	const float side_face_solid_angle = 0.4234413544f / PI;

    // Add contributions of neighbours to this cell
    for (int neighbour = 0; neighbour < 6; neighbour++)
    {
        mat3 orientation = neighbourOrientations[neighbour];
        vec3 direction = orientation * vec3(0.0, 0.0, 1.0);

        // Index offset in our flattened version of the lpv grid
        ivec2 index_offset = ivec2(
            direction.x + (direction.z * float(u_grid_size)), 
            direction.y
        );

        ivec2 neighbour_index = v_cell_index - index_offset;

        vec4 red_contribution_neighbour = texelFetch(u_red_contribution, neighbour_index, 0);
        vec4 green_contribution_neighbour = texelFetch(u_green_contribution, neighbour_index, 0);
        vec4 blue_contribution_neighbour = texelFetch(u_blue_contribution, neighbour_index, 0);

        // No occlusion
        float red_occlusion_val = 1.0;
        float green_occlusion_val = 1.0;
        float blue_occlusion_val = 1.0;

        // No occlusion in the first step
        if (!u_first_iteration) {
            vec3 h_direction = 0.5 * direction;
            ivec2 offset = ivec2(
                h_direction.x + (h_direction.z * float(u_grid_size)),
                h_direction.y
            );
            ivec2 occ_coord = v_cell_index - offset;

            vec4 red_occ_coeffs = texelFetch(u_red_geometry_volume, occ_coord, 0);
            vec4 green_occ_coeffs = texelFetch(u_green_geometry_volume, occ_coord, 0);
            vec4 blue_occ_coeffs = texelFetch(u_blue_geometry_volume, occ_coord, 0);

            red_occlusion_val = 1.0 - clamp(occlusion_amplifier * dot(red_occ_coeffs, dirToSH(-direction)), 0.0, 1.0);
            green_occlusion_val = 1.0 - clamp(occlusion_amplifier * dot(green_occ_coeffs, dirToSH(-direction)), 0.0, 1.0);
            blue_occlusion_val = 1.0 - clamp(occlusion_amplifier * dot(blue_occ_coeffs, dirToSH(-direction)), 0.0, 1.0);
        }

        float occluded_direct_face_red_contribution = red_occlusion_val * direct_face_solid_angle;
        float occluded_direct_face_green_contribution = green_occlusion_val * direct_face_solid_angle;
        float occluded_direct_face_blue_contribution = blue_occlusion_val * direct_face_solid_angle;

        vec4 direction_cosine_lobe = evalCosineLobeToDir(direction);
        vec4 direction_spherical_harmonic = dirToSH(direction);

        red_contribution += occluded_direct_face_red_contribution * max(0.0, dot(red_contribution_neighbour, direction_spherical_harmonic)) * direction_cosine_lobe;
        green_contribution += occluded_direct_face_green_contribution * max(0.0, dot( green_contribution_neighbour, direction_spherical_harmonic)) * direction_cosine_lobe;
        blue_contribution += occluded_direct_face_blue_contribution * max(0.0, dot(blue_contribution_neighbour, direction_spherical_harmonic)) * direction_cosine_lobe;

        // Add contributions of faces of neighbour
        for (int face = 0; face < 4; face++)
        {
            vec3 eval_direction = get_eval_side_direction(face, orientation);
            vec3 reproj_direction = get_reproj_side_direction(face, orientation);

            // No occlusion in the first step
            if (!u_first_iteration) {
                vec3 h_direction = 0.5 * direction;
                ivec2 offset = ivec2(
                    h_direction.x + (h_direction.z * float(u_grid_size)),
                    h_direction.y
                );
                ivec2 occ_coord = v_cell_index - offset;

                vec4 red_occ_coeffs = texelFetch(u_red_geometry_volume, occ_coord, 0);
                vec4 green_occ_coeffs = texelFetch(u_green_geometry_volume, occ_coord, 0);
                vec4 blue_occ_coeffs = texelFetch(u_blue_geometry_volume, occ_coord, 0);

                red_occlusion_val = 1.0 - clamp(occlusion_amplifier * dot(red_occ_coeffs, dirToSH(-direction)), 0.0, 1.0);
                green_occlusion_val = 1.0 - clamp(occlusion_amplifier * dot(green_occ_coeffs, dirToSH(-direction)), 0.0, 1.0);
                blue_occlusion_val = 1.0 - clamp(occlusion_amplifier * dot(blue_occ_coeffs, dirToSH(-direction)), 0.0, 1.0);
            }

            float occluded_side_face_red_contribution = red_occlusion_val * side_face_solid_angle;
            float occluded_side_face_green_contribution = green_occlusion_val * side_face_solid_angle;
            float occluded_side_face_blue_contribution = blue_occlusion_val * side_face_solid_angle;

            vec4 reproj_direction_cosine_lobe = evalCosineLobeToDir(reproj_direction);
			vec4 eval_direction_spherical_harmonic = dirToSH(eval_direction);
			
		    red_contribution += occluded_side_face_red_contribution * max(0.0, dot(red_contribution_neighbour, eval_direction_spherical_harmonic)) * reproj_direction_cosine_lobe;
			green_contribution += occluded_side_face_green_contribution * max(0.0, dot(green_contribution_neighbour, eval_direction_spherical_harmonic)) * reproj_direction_cosine_lobe;
			blue_contribution += occluded_side_face_blue_contribution * max(0.0, dot(blue_contribution_neighbour, eval_direction_spherical_harmonic)) * reproj_direction_cosine_lobe;
        }
    }
}

void main()
{
    propagate();

    o_red_color = red_contribution;
    o_green_color = green_contribution;
    o_blue_color = blue_contribution;

    o_next_iteration_red_color = red_contribution;
    o_next_iteration_green_color = green_contribution;
    o_next_iteration_blue_color = blue_contribution;
}