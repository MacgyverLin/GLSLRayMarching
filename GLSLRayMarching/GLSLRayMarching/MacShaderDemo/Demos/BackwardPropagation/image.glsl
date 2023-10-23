void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = fragCoord / iResolution.xy;

    vec2 mouseCoords = iMouse.xy / iResolution.xy;
    if ((mouseCoords.x > 0.001 && uv.x > mouseCoords.x) || (mouseCoords.x == 0. && uv.x > 0.5))
    {
        fragColor = texture(iChannel0, uv);
    }
    else
    {
        vec4 w1_b1_w2_b2 = texture(iChannel1, uv);
        vec4 w3_b3_w4_b4 = texture(iChannel2, uv);
        vec4 w5_b5_w6_b6 = texture(iChannel3, uv);

        float t = getT(iTime);
        vec3 rgb = forwardPropagationPrediction(t, w1_b1_w2_b2, w3_b3_w4_b4, w5_b5_w6_b6);

        fragColor = vec4(rgb, 1.0);
        // fragColor = w1_b1_w2_b2;
        // fragColor = w3_b3_w4_b4;
        // fragColor = w5_b5_w6_b6;    
    }
}
