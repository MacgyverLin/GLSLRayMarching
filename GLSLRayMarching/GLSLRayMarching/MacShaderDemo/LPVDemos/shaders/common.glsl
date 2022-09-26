#ifndef COMMON_GLSL
#define COMMON_GLSL

#define PI     (3.14159265358979323846)
#define TWO_PI (2.0 * PI)

float saturate(in float value) {
	return clamp(value, 0.0, 1.0);
}

float lengthSquared(in vec2 v)
{
	return dot(v, v);
}

float lengthSquared(in vec3 v)
{
	return dot(v, v);
}

void reortogonalize(in vec3 v0, inout vec3 v1)
{
	// Perform Gram-Schmidt's re-ortogonalization process to make v1 orthagonal to v1
	v1 = normalize(v1 - dot(v1, v0) * v0);
}

vec2 spherical_from_direction(vec3 direction)
{
	highp float theta = acos(clamp(direction.y, -1.0, 1.0));
	highp float phi = atan(direction.z, direction.x);
	if (phi < 0.0) phi += TWO_PI;

	return vec2(phi / TWO_PI, theta / PI);
}

float sample_shadow_map(in sampler2D shadow_map, in vec2 uv, in float comparison_depth, in float bias)
{
	vec2 textureSize = vec2(4096.0);
	vec2 texelSize = vec2(1.0) / textureSize;
	vec2 txl = texelSize * 0.98;

	float tl = step(comparison_depth, texture(shadow_map, uv + vec2(0.0,   0.0)).x + bias);
	float tr = step(comparison_depth, texture(shadow_map, uv + vec2(txl.x, 0.0)).x + bias);
	float bl = step(comparison_depth, texture(shadow_map, uv + vec2(0.0,   txl.y)).x + bias);
	float br = step(comparison_depth, texture(shadow_map, uv + vec2(txl.x, txl.y)).x + bias);
	vec2 f = fract(uv * textureSize);
	float tA = mix(tl, tr, f.x);
	float tB = mix(bl, br, f.x);
	return mix(tA, tB, f.y);
}

float sample_shadow_map_pcf(in sampler2D shadow_map, in vec2 uv, in float comparison_depth, vec2 texel_size, in float bias)
{
	float tx = texel_size.x;
	float ty = texel_size.y;

	float visibility = 0.0;

	//
	// TODO: Do we need a big 9x9 PCF? Maybe smaller is sufficient?
	//

	visibility += sample_shadow_map(shadow_map, uv + vec2(-tx, -ty), comparison_depth, bias);
	visibility += sample_shadow_map(shadow_map, uv + vec2(-tx,   0), comparison_depth, bias);
	visibility += sample_shadow_map(shadow_map, uv + vec2(-tx, +ty), comparison_depth, bias);
	visibility += sample_shadow_map(shadow_map, uv + vec2(  0, -ty), comparison_depth, bias);
	visibility += sample_shadow_map(shadow_map, uv + vec2(  0,   0), comparison_depth, bias);
	visibility += sample_shadow_map(shadow_map, uv + vec2(  0, +ty), comparison_depth, bias);
	visibility += sample_shadow_map(shadow_map, uv + vec2(+tx, -ty), comparison_depth, bias);
	visibility += sample_shadow_map(shadow_map, uv + vec2(+tx,   0), comparison_depth, bias);
	visibility += sample_shadow_map(shadow_map, uv + vec2(+tx, +ty), comparison_depth, bias);

	return visibility / 9.0;

}

#endif // COMMON_GLSL
