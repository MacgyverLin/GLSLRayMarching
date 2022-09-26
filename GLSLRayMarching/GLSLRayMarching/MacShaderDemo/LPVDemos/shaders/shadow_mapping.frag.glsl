#version 300 es
precision highp float;

layout(location = 0) out vec4 o_shadow_map;

void main()
{
	float c = gl_FragCoord.z;
	o_shadow_map = vec4(c, c, c, 1.0);
}
