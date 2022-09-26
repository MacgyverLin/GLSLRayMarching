#version 300 es
precision lowp float;

uniform vec3 u_color;

layout(location = 0) out vec4 o_color;

void main()
{
	o_color = vec4(u_color, 1.0);
}
