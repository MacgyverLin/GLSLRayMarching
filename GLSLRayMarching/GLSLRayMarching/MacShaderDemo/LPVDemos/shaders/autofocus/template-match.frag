#pragma once

/************************************************************************
Sum of squared differences between the search image (red channel) and template 
image (green channel) over all template pixels, when the template image is 
placed with its lower left corner over the current search image texel.
*************************************************************************/
inline constexpr char template_match_frag[] = R"glsl(
#version 330 core
#line 10

uniform sampler2D disparity_image;

uniform ivec2 size;
uniform ivec2 template_min;
uniform ivec2 template_max;

in vec2 interpolated_texcoord;

out vec4 color;

void main()
{
    vec2 S_xy = interpolated_texcoord * size;

    float sum = 0.0;
    for(int x = template_min.x; x < template_max.x; x++)
    {
        for(int y = template_min.y; y < template_max.y; y++)
        {
            vec2 T_xy = vec2(x, y);

            float S = texture(disparity_image, (S_xy + T_xy - template_min) / size).r;
            float T = texture(disparity_image, T_xy / size).g;

            sum += pow(S-T, 2);
        }
    }
    color.r = sum;
})glsl";