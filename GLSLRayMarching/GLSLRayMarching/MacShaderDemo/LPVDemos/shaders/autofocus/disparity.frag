#pragma once

inline constexpr char disparity_frag[] = R"(
#version 330 core
#line 5

uniform sampler2D image;

uniform int channel;

out vec4 color;

in vec2 st;

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
    if(st.x < 0 || st.x > 1 || st.y < 0 || st.y > 1)
    {
        discard;
    }

    vec3 linear = srgbGammaExpand(texture(image, st).xyz);

    float luminance = 0.2126 * linear.r + 0.7152 * linear.g + 0.0722 * linear.b;

    color = vec4(0.0, 0.0, 0.0, 1.0);
    color[channel] = luminance;
})";