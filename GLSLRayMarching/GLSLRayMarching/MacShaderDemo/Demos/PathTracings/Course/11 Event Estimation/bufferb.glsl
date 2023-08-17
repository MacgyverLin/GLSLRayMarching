//Accumulate history colors.

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec4 color = vec4(0.0, 0.0, 0.0, 1.0);

    if (iFrame == 0)
    {
        fragColor = color; return;
    }

    vec2 uv = fragCoord / iResolution.xy;
    vec3 bufferA = texture(iChannel0, uv).rgb;
    vec4 bufferB = texture(iChannel1, uv);

    if (iMouse.z > 0.0)
    {
        fragColor = vec4(bufferA, 1.0);
    }
    else
    {
        bufferB.a += 1.0;
        color.rgb = mix(bufferB.rgb, bufferA, 1.0 / bufferB.a);
        fragColor = vec4(color.rgb, bufferB.a);
    }

}