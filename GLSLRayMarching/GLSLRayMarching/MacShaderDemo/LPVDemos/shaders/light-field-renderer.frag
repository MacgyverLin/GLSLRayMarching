#pragma once

inline constexpr char light_field_renderer_frag[] = R"(
#version 330 core
#line 5

uniform sampler2D data_image;

uniform float aperture_falloff;

out vec4 color;

in vec2 aperture_texcoord;
in vec2 data_image_coord;

vec3 srgbGammaExpand(vec3 c)
{
    return mix(
        pow((c + 0.055) / 1.055, vec3(2.4)), 
        c / 12.92,
        lessThan(c, vec3(0.04045))
    );
}

void main() 
{
    if(data_image_coord.x < 0.0 || data_image_coord.x > 1.0 || data_image_coord.y < 0.0 || data_image_coord.y > 1.0)
    {
        discard;
    }

    float aperture_filter = pow(clamp(1.0 - length((aperture_texcoord - 0.5) * 2.0), 0, 1), aperture_falloff);

    color = vec4(srgbGammaExpand(texture(data_image, data_image_coord).xyz) * aperture_filter, aperture_filter);
})";