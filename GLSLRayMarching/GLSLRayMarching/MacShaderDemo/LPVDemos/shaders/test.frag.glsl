#version 300 es
precision highp float;

in vec3 v_position;
in vec3 v_normal;
in vec2 v_tex_coord;

layout(location = 0) out vec4 o_color;

void main()
{
	vec3 packed_normal = v_normal * vec3(0.5) + vec3(0.5);
	o_color = vec4(packed_normal, 1.0);
}
