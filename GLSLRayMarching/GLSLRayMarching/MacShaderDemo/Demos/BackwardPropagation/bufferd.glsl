void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = fragCoord / iResolution.xy;

    // init
    if (iTime == 0. || iFrame == 0)
    {
        fragColor = vec4(rnd(uv + vec2(6., 6.)), 0., rnd(uv - vec2(6., 6.)), 0.);
    }
    else
    {
        vec4 w1_b1_w2_b2 = texture(iChannel1, uv);
        vec4 w3_b3_w4_b4 = texture(iChannel2, uv);
        vec4 w5_b5_w6_b6 = texture(iChannel3, uv);
        vec4 Y = texture(iChannel0, uv);

        if (iTime > TRAIN_DURATION)
        {
            fragColor = w5_b5_w6_b6;
        }
        else
        {
            float t = getT(iTime);
            fragColor = updatedParametersBufferD(t, w1_b1_w2_b2, w3_b3_w4_b4, w5_b5_w6_b6, Y.rgb);
        }
    }
}

