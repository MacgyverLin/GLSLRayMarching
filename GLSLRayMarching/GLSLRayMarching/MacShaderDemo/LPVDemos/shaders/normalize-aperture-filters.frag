#pragma once

inline constexpr char normalize_aperture_filters_frag[] = R"glsl(
#version 330 core
#line 5

uniform sampler2D accumulation_texture;

/****************************************************************************************
This is set to actual maximum filter weight sum (max alpha value of accumulation_texture) 
if the aperture filter weights shouldn't be normalized per pixel. Otherwise this can be 
set to 1 or 0 depending on if the aperture filter weight should be normalized at the
edges (where filter weight sum is < 1) or not.
****************************************************************************************/
uniform float max_weight_sum;

uniform float exposure;

in vec2 interpolated_texcoord;

out vec4 color;

vec3 srgbGammaCompress(vec3 c)
{
    return mix(
        1.055 * pow(c, vec3(1.0/2.4)) - 0.055,
        c * 12.92,
        lessThan(c, vec3(0.0031308))
    );
}

void main()
{
    vec4 c = texture(accumulation_texture, interpolated_texcoord);
    color.xyz = srgbGammaCompress(exposure * c.xyz / max(max_weight_sum, c.w));
})glsl";