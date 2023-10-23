
vec2 loss(Model source, Model v, int frame) {
    vec2 err = vec2(0.0);
    for (int i = 0; i < FIT_POINTS; ++i) {
        vec2 p = get_point(i, frame);
        ModelIO io;
        io.i[0] = vec2(p.x, 0.0);
        model_eval(source, v, io);
        err += ad_sq(ad_sub(io.o[0], p.y));
    }
    err /= float(FIT_POINTS);
    err = ad_sqrt(err);
    //vec2 cost = model_cost(source, v);
    //err.x += pow(err.y - 1.0, 2.0);
    return err;
}

// https://arxiv.org/abs/2307.06324
float alphastep() {
    int n = (iFrame + 1) & ~iFrame;
    return float(n % 63) * alpha;
}
#define alpha alphastep()

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    setup_s_K(iFrame);
    ivec2 fc = ivec2(fragCoord);
    int ci = fc.x;
    int mi = fc.y;
    if (ci < ModelSize) {
        Model startp;

        if (iFrame == 0) {
            Random rng = seed(ivec2(mi, 0));
            model_init(startp, rng);
            fragColor = vec4(startp.c[ci], 0.0, 0.0, 0.0);
        }
        else {
            Model m, v, ema;
            float t = float(iFrame + 1);
            for (int i = 0; i < ModelSize; ++i) {
                vec4 data = texelFetch(iChannel0, ivec2(i, mi), 0);
                startp.c[i] = data.r;
                m.c[i] = data.g;
                v.c[i] = data.b;
#if EMA
                ema.c[i] = data.a;
#endif                
            }

            vec2 l = loss(startp, startp, iFrame);

            Random rng = seed(seed(mi), iFrame);
#if 1
            {
                Model testp;
                Model testm;
                Model testv;
                // apply one round of differential evolution
                // do more and more the later it is
                float CR = tanh(t / (60.0 * 30.0));
                float F = 0.0;
                ivec3 k = sample_k_3(rng, int(iResolution.y), mi);
                int R = range(rng, 0, ModelSize);
                for (int i = 0; i < ModelSize; ++i) {
                    if ((i == R) || (random(rng) < CR)) {
                        vec4 ai = texelFetch(iChannel0, ivec2(i, k.x), 0);
                        vec4 bi = texelFetch(iChannel0, ivec2(i, k.y), 0);
                        vec4 ci = texelFetch(iChannel0, ivec2(i, k.z), 0);
                        testp.c[i] = ai.x + F * (bi.x - ci.x);
                        testm.c[i] = ai.y + F * (bi.y - ci.y);
                        testv.c[i] = ai.z + F * (bi.z - ci.z);
                    }
                    else {
                        testp.c[i] = startp.c[i];
                        testm.c[i] = m.c[i];
                        testv.c[i] = v.c[i];
                    }
                }
                vec2 newloss = loss(testp, testp, iFrame);
                if (newloss.x < l.x) {
                    startp = testp;
                    m = testm;
                    v = testv;
                }
            }
#endif
            Model g;
#if FULL_GRADIENT
            Model d;
            for (int i = 0; i < ModelSize; ++i) {
                d.c[i] = 0.0;
            }
            d.c[0] = 1.0;
            g.c[0] = loss(startp, d, iFrame).y;
            for (int i = 1; i < ModelSize; ++i) {
                d.c[i - 1] = 0.0;
                d.c[i] = 1.0;
                g.c[i] = loss(startp, d, iFrame).y;
            }
            vec2 f_d = vec2(1.0);
#else
            float nf = 0.0;
            for (int i = 0; i < ModelSize; ++i) {
                g.c[i] = clamp(gaussian(rng, 0.0, 1.0), -gradient_clamp, gradient_clamp);
                nf += g.c[i] * g.c[i];
            }
#if NORMALIZE_MC_GRADIENT
            nf = 1.0 / (nf + epsilon); // surface of d-sphere
            //nf *= pow(random(rng), 1.0/float(NUM_WEIGHTS)); // inside d-ball
            for (int i = 0; i < ModelSize; ++i) {
                g.c[i] = g.c[i] * nf;
            }
#endif
            vec2 f_d = loss(startp, g, iFrame);
#endif
            for (int i = 0; i < ModelSize; ++i) {
#if STEPMETHOD == STEPMETHOD_SOFTCLAMP_NEWTON
                // softclamped newton's method
                float g_c_i = tanh(f_d.x / (g.c[i] * f_d.y));
#elif STEPMETHOD == STEPMETHOD_CLAMP_NEWTON
                // softclamped newton's method
                float g_c_i = clamp(f_d.x / (g.c[i] * f_d.y), -newton_clamp_limit, newton_clamp_limit);
#elif STEPMETHOD == STEPMETHOD_NEWTON
                // newton's method
                float g_c_i = f_d.x / (g.c[i] * f_d.y);
#else // STEPMETHOD == STEPMETHOD_GRADIENT
                float g_c_i = g.c[i] * f_d.y;
#endif
#if (METHOD == METHOD_ADAM)                
                // Adam gradient descent (https://arxiv.org/abs/1412.6980, algorithm 1)
                float g2_c_i = g_c_i * g_c_i;
                m.c[i] = mix(g_c_i, m.c[i], beta1);
                v.c[i] = mix(g2_c_i, v.c[i], beta2);
                float mu_c_i = m.c[i] / (1.0 - pow(beta1, t));
                float vu_c_i = v.c[i] / (1.0 - pow(beta2, t));
                startp.c[i] = startp.c[i] - alpha * mu_c_i / (sqrt(vu_c_i) + epsilon);
#elif (METHOD == METHOD_ADAMAX)
                // AdaMax gradient descent (https://arxiv.org/abs/1412.6980, algorithm 2)
                m.c[i] = mix(g_c_i, m.c[i], beta1);
                v.c[i] = max(beta2 * v.c[i], abs(g_c_i));
                startp.c[i] = startp.c[i] - (alpha / (1.0 - pow(beta1, t))) * m.c[i] / (v.c[i] + epsilon);
#else // FGD
                // Gradients without Backpropagation (https://arxiv.org/abs/2202.08587)
                startp.c[i] = startp.c[i] - alpha * g_c_i;
#endif
            }
#if EMA
            // Ema extension (https://arxiv.org/abs/1412.6980, 7.2)
            for (int i = 0; i < NUM_WEIGHTS; ++i) {
                ema.c[i] = mix(startp.c[i], ema.c[i], beta2);
            }
#endif                 
            fragColor = vec4(startp.c[ci], m.c[ci], v.c[ci], ema.c[ci]);
        }
    }
}