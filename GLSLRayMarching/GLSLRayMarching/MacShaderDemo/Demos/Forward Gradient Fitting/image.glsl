//////////////////////////////////////////////////////////

Model f_scoeffs;
float f_scoeffs_func(float x) {
    ModelIO io;
    io.i[0] = ad_const(x);
    model_eval(f_scoeffs, f_scoeffs, io);
    return io.o[0].x;
}

float f_error(float x) {
    return pow2(f_scoeffs_func(x) - target_func(x)) * 1000.0 - 1.0;
}

void paint() {
    setup_s_K(iFrame);
    float t = iTime;

    Random rng = seed(seed(get_origin()), iFrame);
    int mi = range(rng, 0, int(iResolution.y));
    //mi = 0;

    Model source;
    for (int i = 0; i < ModelSize; ++i) {
#if EMA
        source.c[i] = texelFetch(iChannel0, ivec2(i, mi), 0).a / (1.0 - pow(beta2, float(iFrame + 1)));
#else
        source.c[i] = texelFetch(iChannel0, ivec2(i, mi), 0).x;
#endif
    }

    set_source_rgb(0.0, 0.0, 0.0);
    clear();

    grid(vec2(1.0 / 10.0));
    set_line_width_px(1.0);
    set_source_rgba(vec4(vec3(1.0), 0.3));
    stroke();

    set_source_rgba(vec4(vec3(1.0), 0.7));
    rectangle(-1.0, -1.0, 2.0, 2.0);
    stroke();

    f_scoeffs = source;
#ifdef FIT_POINTS
    set_source_rgba(vec4(vec3(1.0, 0.5, 0.5), 1.0));
    for (int i = 0; i < FIT_POINTS; ++i) {
        vec2 p = get_point(i, iFrame);
        float y = f_scoeffs_func(p.x);
        float err = pow2(y - p.y) / 1e-3;
        move_to(p.x, -1.0);
        line_to(p.x, -1.0 + err);
        stroke();
    }
    set_source_rgba(vec4(vec3(1.0), 1.0));
    for (int i = 0; i < FIT_POINTS; ++i) {
        circle(get_point(i, iFrame), 0.02);
        fill();
    }
#else
    graph1D(target_func);
    set_source_rgba(vec4(vec3(1.0), 1.0));
    stroke();

    graph1D(f_error);
    set_source_rgba(vec4(vec3(1.0, 0.5, 0.5), 1.0));
    stroke();
#endif
#if 0
    graph1D(f_scoeffs_func_i0);
    set_line_width_px(1.0);
    set_source_rgba(vec4(vec3(0.8, 0.5, 1.0), 0.8));
    stroke();
    graph1D(f_scoeffs_func_i1);
    set_line_width_px(1.0);
    set_source_rgba(vec4(vec3(0.8, 0.5, 1.0), 0.8));
    stroke();
#endif
    graph1D(f_scoeffs_func);
    set_line_width_px(2.0);
    set_source_rgba(vec4(vec3(0.8, 0.5, 1.0), 1.0));
    stroke();
}

//////////////////////////////////////////////////////////

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    init(fragCoord, iMouse.xy, iResolution.xy);

    paint();

    blit(fragColor);
}