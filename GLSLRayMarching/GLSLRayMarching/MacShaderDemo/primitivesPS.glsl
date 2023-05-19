#version 430 core

in vec4 color;

uniform mat4 M;
uniform mat4 V;
uniform mat4 P;

out vec4 FragColor;

void main()
{
	FragColor = color;
}