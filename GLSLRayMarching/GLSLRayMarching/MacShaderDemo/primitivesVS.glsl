#version 430 core
layout(location = 0) in vec3 vPos;
layout(location = 1) in vec3 vNormal;
layout(location = 2) in vec4 vCol;
layout(location = 3) in vec2 vUV;

out vec4 color;


uniform mat4 worldTransform;
// #define USE_UNIFORM_BLOCK
#ifdef USE_UNIFORM_BLOCK
layout(std140, binding = 0) uniform TransformData
{
	uniform mat4 viewTransform;
	uniform mat4 projTransform;
};
#else
	uniform mat4 viewTransform;
	uniform mat4 projTransform;
#endif
uniform int lod;
uniform float ratio;

void main()
{
	gl_Position = projTransform * viewTransform * worldTransform * vec4(vPos, 1.0);
	color = vCol;
}