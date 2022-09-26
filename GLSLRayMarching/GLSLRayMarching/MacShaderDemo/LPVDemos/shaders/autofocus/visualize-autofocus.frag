#pragma once

inline constexpr char visualize_autofocus_frag[] = R"glsl(
#version 330 core
#line 5

uniform sampler2D disparity_image;

uniform ivec2 size;
uniform ivec2 template_min;
uniform ivec2 template_max;
uniform ivec2 search_min;
uniform ivec2 search_max;

in vec2 interpolated_texcoord;

out vec4 color;

vec2 srgbGammaCompress(vec2 c)
{
    return mix(
        1.055 * pow(c, vec2(1.0/2.4)) - 0.055,
        c * 12.92,
        lessThan(c, vec2(0.0031308))
    );
}

void main()
{
    ivec2 px = ivec2(interpolated_texcoord * size);
    ivec2 search_size = search_max - search_min;
    ivec2 template_size = template_max - template_min;
    const int w = 2;
    
    if(px.x < search_size.x && px.y < search_size.y)
    {
        vec2 c = srgbGammaCompress(texture(disparity_image, (search_min + px) / vec2(size)).xy);
        color = vec4(vec3(c.r), 1.0);

        ivec2 offset = (search_size - template_size) / 2;
        if(px.x < template_size.x + offset.x + w && px.y < template_size.y + offset.y + w && px.x > offset.x - w && px.y > offset.y - w)
        {
            if(px.x > template_size.x + offset.x || px.y > template_size.y + offset.y || px.x < offset.x || px.y < offset.y)
            {
                color *= 0.1;
            }
        }
        else
        {
            color *= 0.75;
        }
        return;
    }

    if(px.x < search_size.x * 2 && px.y < search_size.y)
    {
        ivec2 offset = ivec2(search_size.x, 0) + (search_size - template_size) / 2;
        if(px.x < template_size.x + offset.x && px.y < template_size.y + offset.y && px.x > offset.x && px.y > offset.y)
        {
            vec2 c = srgbGammaCompress(texture(disparity_image, (template_min + px - offset) / vec2(size)).xy);
            color = vec4(vec3(c.g), 1.0);
            return;
        }
        color = vec4(0.25);
        return;
    }

    vec2 c = srgbGammaCompress(texture(disparity_image, interpolated_texcoord).xy);

    color = vec4(c.r, 0.5 * (c.r + c.g), c.g, 1.0);

    if(px.x > search_min.x && px.x < search_max.x && px.y > search_min.y && px.y < search_max.y)
    {
        if(px.x < search_min.x + w || px.x > search_max.x - w || px.y < search_min.y + w || px.y > search_max.y - w)
        {
            color *= 0.1;
        }
        if(px.x > template_min.x && px.x < template_max.x && px.y > template_min.y && px.y < template_max.y)
        {
            if(px.x < template_min.x + w || px.x > template_max.x - w || px.y < template_min.y + w || px.y > template_max.y - w)
            {
                color *= 0.1;
            }
        }
    }
    else
    {
        color *= 0.75;
    }
})glsl";