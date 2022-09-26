#version 300 es
precision highp float;

layout (location = 0) in vec2 a_cell_index;

uniform highp int u_grid_size;
flat out ivec2 v_cell_index;

vec2 get_grid_output_position()
{
    vec2 offset_position = a_cell_index + vec2(0.5); //offset position to middle of texel
    float f_grid_size = float(u_grid_size);

    return vec2((2.0 * offset_position.x) / (f_grid_size * f_grid_size), (2.0 * offset_position.y) / f_grid_size) - vec2(1.0);
}

void main() 
{
    vec2 screen_pos = get_grid_output_position();

    v_cell_index = ivec2(a_cell_index);

    gl_PointSize = 1.0;
    gl_Position = vec4(screen_pos, 0.0, 1.0);
}