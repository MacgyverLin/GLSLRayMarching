const float NINE5 = 0.9510565, THREE0 = 0.309017, EIGHT09 = 0.80902,
            FIVE8 = 0.58778525;
const vec3 FIRST_PLANE = vec3(0., -1., 0.),
           SECOND_PLANE = vec3(NINE5, -THREE0, 0.),
           THIRD_PLANE = vec3(FIVE8, EIGHT09, 0.),
           FOURTH_PLANE = vec3(-FIVE8, EIGHT09, 0.),
           FIFTH_PLANE = vec3(-NINE5, -THREE0, 0.);

///////////////////////////////////////////////////////
float pipe(vec3 p, float l, float w) {
    float d = 1e9;
    p = p.xzy;
    p.y = abs(p.y);

    {
        vec3 q = p.yzx;
        q.x -= l; q.y += 0.29;
        q.yx *= rot(-PI / 4.);
        const float an = 1. / sqrt(2.);
        d = sd_capped_torus(q, vec2(an), 0.3, w);
    }
    d = min(d, sd_capped_cylinder(p, w, l));
    d = min(d, sd_capped_cylinder(p - vec3(0., l, 0.), w + 0.02,  0.1) - 0.01);

    p.xz = polar_mod(p.xz, 9.);
    p.xz *= rot(-PI / 2.);
    d = min(d, (length(p - vec3(w + 0.03, l, 0.0)) - 0.022));

    return d;
}
           
const float PIPE_MOD_DIST = 10.;
float rand_pipe(vec3 p, float id, float y) {
    vec3 yoffset = cross(vec3(0., 0., 1.), FOURTH_PLANE);
    yoffset.xy *= rot(3.7 * PI / 6.);

    float l = rand_in_range(id, 1.5, PIPE_MOD_DIST / 3. - 0.5);
    float w = (PIPE_MOD_DIST - l) / 3.;
    float zoff = rand_in_range(id + 0.1, -w / 3., w);

    p = p - yoffset * 0.15 * y - vec3(0., 0., zoff);
    return pipe(p, l, 0.1);
}

float pipe_map(vec3 p) {
    float id = floor((p.z + PIPE_MOD_DIST / 2.) / PIPE_MOD_DIST);
    p.z = mod(p.z + PIPE_MOD_DIST / 2., PIPE_MOD_DIST) - PIPE_MOD_DIST / 2.;

    p.xy *= rot(3.7 * PI / 6.);
    p += vec3(0.55, 0.8, 0.);

    float top = rand_pipe(p, id, 1.);
    float bottom = rand_pipe(p, id + PI, -1.);

    return min(top, bottom);
}
////////////////////////////////////////////////////

// Thanks Tater! https://www.shadertoy.com/view/NlKGWK
const float ITERS_TRACE = 8., ITERS_NORM = 25.,

            HOR_SCALE = 1.1, OCC_SPEED = 1.4, DX_DET = 0.65,

            FREQ = 1.09, HEIGHT_DIV = 5.5, WEIGHT_SCL = 0.8, FREQ_SCL = 1.2,
            TIME_SCL = 1.095, WAV_ROT = 1.21, DRAG = 0.6, SCRL_SPEED = 0.5;
vec2 scrollDir = vec2(0, 1);
vec2 wavedx(vec2 wavPos, float iters, float t){
    vec2 dx = vec2(0);
    vec2 wavDir = vec2(1,0);
    float wavWeight = 1.0;
    wavPos += t * SCRL_SPEED * scrollDir;
    wavPos *= HOR_SCALE;
    float wavFreq = FREQ;
    float wavTime = OCC_SPEED * t;
    for (float i = 0.; i < iters; i++) {
        wavDir *= rot(WAV_ROT);
        float x = dot(wavDir, wavPos) * wavFreq + wavTime;
        float result = exp(sin(x) - 1.) * cos(x) * wavWeight;
        dx += result * wavDir / pow(wavWeight, DX_DET);
        wavFreq *= FREQ_SCL;
        wavTime *= TIME_SCL;
        wavPos -= wavDir * result * DRAG;
        wavWeight *= WEIGHT_SCL;
    }
    float wavSum = -(pow(WEIGHT_SCL, float(iters)) - 1.) * HEIGHT_DIV;
    return dx / pow(wavSum, 1. - DX_DET);
}

float wave(vec2 wavPos, float iters, float t) {
    float wav = 0.0;
    vec2 wavDir = vec2(1, 0);
    float wavWeight = 1.0;
    wavPos += t * SCRL_SPEED * scrollDir;
    wavPos *= HOR_SCALE;
    float wavFreq = FREQ;
    float wavTime = OCC_SPEED * t;
    for (float i = 0.; i < iters; i++) {
        wavDir *= rot(WAV_ROT);
        float x = dot(wavDir, wavPos) * wavFreq + wavTime;
        float wave = exp(sin(x)  - 1.0) * wavWeight;
        wav += wave;
        wavFreq *= FREQ_SCL;
        wavTime *= TIME_SCL;
        wavPos -= wavDir * wave * DRAG * cos(x);
        wavWeight *= WEIGHT_SCL;
    }
    float wavSum = -(pow(WEIGHT_SCL, float(iters)) - 1.) * HEIGHT_DIV;
    return wav / wavSum;
}

vec3 wave_norm(vec3 p){
    vec2 wav = -wavedx(p.xz, ITERS_NORM, iTime * 0.3);
    return normalize(vec3(wav.x, 1.0, wav.y));
}

float water_map(vec3 p){
    float d = 1e9;
    p.y += 1.2;

    float waters = p.y - wave(p.xz, ITERS_TRACE, iTime * 0.4);
    d = min(d, waters);

    return d;
}
////////////////////////////////////////////////////

float GLOW = 0.;
float getGlow(float dist, float radius, float intensity){
	return pow(radius / max(dist, 1e-6), intensity);	
}

float light_map(vec3 p) {
    float c = 5.;
    p.z = mod(p.z + c / 2., c) - c / 2.;
    
    vec3 light_start = vec3(0.15, 1.25, 0.0);
    vec3 light_end = vec3(1., .63, 0.0);
    
    float l = sd_capsule(p, light_start, light_end, 0.025);
    GLOW += getGlow(l, 0.01, 1.7);
    return l;
}
////////////////////////////////////////////////////

Hit trace(in vec3 ro, in vec3 rd) {
    Hit hit = default_hit();
    float plane_dist = 1e9;
    bool wall = false;

    wall = clamped_plane(ro, rd, FIRST_PLANE + vec3(0., 0.4, 0.), FIRST_PLANE, 1., plane_dist);
    if (wall) {
        vec2 waters;
        march_macro(water_map, ro, rd, 100, plane_dist, plane_dist + 10., waters);
        if (waters.y > 0.) {
            vec3 norm = wave_norm(ro + rd * waters.x);
            hit = _min(hit, Hit(waters.x, norm, 1));
        }
    }

    wall = clamped_plane(ro, rd, SECOND_PLANE, SECOND_PLANE, 1., plane_dist);
    if (wall) {
        hit = _min(hit, Hit(plane_dist, -SECOND_PLANE, 2));
    }
    wall = clamped_plane(ro, rd, THIRD_PLANE * 0.8, THIRD_PLANE, 1., plane_dist);
    if (wall) {
        float wall2;
        wall = clamped_plane(ro, rd, THIRD_PLANE * 1.1, THIRD_PLANE, 1., wall2);
        if (wall) { hit = _min(hit, Hit(wall2, -THIRD_PLANE, 4)); }

        // Only collect glow
        vec2 lights;
        march_macro(light_map, ro, rd, 5, plane_dist, plane_dist + 4., lights);
    }
    wall = clamped_plane(ro, rd, FOURTH_PLANE * 0.8, FOURTH_PLANE , 2., plane_dist);
    if (wall) {
        float wall2;
        wall = clamped_plane(ro, rd, FOURTH_PLANE * 1.1, FOURTH_PLANE, 1., wall2);
        if (wall) { hit = _min(hit, Hit(wall2, -FOURTH_PLANE, 4)); }
        vec2 pipes;
        march_macro(pipe_map, ro, rd, 100, plane_dist, plane_dist + 10., pipes);
        if (pipes.y > 0.) {
            vec3 norm;
            get_norm_macro(pipe_map, ro + rd * pipes.x, norm);
            hit = _min(hit, Hit(pipes.x, norm, 6));
        }
    }
    wall = clamped_plane(ro, rd, FIFTH_PLANE, FIFTH_PLANE, 1., plane_dist);
    if (wall) {
        hit = _min(hit, Hit(plane_dist, -FIFTH_PLANE, 5));
    }

    return hit;
}

// https://www.elopezr.com/rendering-line-lights/
vec3 segment_light(vec3 ro, vec3 rd, Hit hit, vec3 albedo,
                   vec3 light_start, vec3 light_end, float n) {
    vec3 hit_pos = ro + rd * hit.dist;
    vec3 normal = hit.norm;
    vec3 litSurface = vec3(0.0);
    vec3 finalLightColor = vec3(0.0);

    vec3 A = light_start;
    vec3 B = light_end;
    vec3 P = hit_pos;

    float light_intensity = 2.0;
    vec3 surface_reflection = reflect(-rd, normal);

    vec3 rf = refract(rd, normal, 1. / 1.33);
    vec3 sd = normalize(vec3(0, 0.3, -1.0));
    float fres = clamp((pow(1. - max(0.0, dot(-normal, rd)), 5.0)), 0.0, 1.0);
    float spec = 0.13;

    vec3 surface_albedo = albedo;
    surface_albedo = mix(surface_albedo, vec3(0.1), smoothstep(0.2, 0.9, length(P.xy) - 0.5)); 

    {
        float t = 0.0;
        vec3 diffuseMRP = mrp_diffuse(hit_pos, A, B, t);

        finalLightColor = mix(vec3(1.0, 1.0, 1.0), vec3(1.0, 0.5, 0.0), t) * 1.5;
        //finalLightColor =
        //    mix(spc(sin(iTime), 1.), spc(cos(iTime - PI / 3.), 1.), t);

        vec3 light_dir = diffuseMRP - hit_pos;
        light_dir = normalize(light_dir);

        float NdotL = sat(dot(normal, light_dir));

        float falloff = compute_falloff(hit_pos, diffuseMRP);

        litSurface += (surface_albedo / PI) * finalLightColor *
                      light_intensity * falloff * NdotL;
    }

    {
        float t = 0.0;
        vec3 specularMRP =
            mrp_specular(hit_pos, A, B, surface_reflection, t);
        finalLightColor = mix(vec3(1.0, .3, .5), vec3(1.0, 1.0, 0.0), t);
        finalLightColor = mix(finalLightColor, vec3(1.0), 0.4);

        vec3 light_dir = specularMRP - hit_pos;
        light_dir = normalize(light_dir);

        float NdotL = sat(dot(normal, light_dir));

        vec3 H = normalize(-rd + light_dir);

        float NdotH = sat(dot(normal, H));

        float falloff = compute_falloff(hit_pos, specularMRP);

        float surface_roughness = 0.1;
        litSurface += 0.25 * vec3(pow(NdotH, pow(1000.0, 1.0 - surface_roughness))) *
                      finalLightColor * light_intensity * falloff * NdotL;
    }

    return litSurface;
}

vec3 get_material(vec3 ro, vec3 rd, Hit hit) {
    vec3 pos = ro + rd * hit.dist;
    vec3 nor = hit.norm;
    vec3 uvw = pos;
    vec3 ddx_uvw = uvw + dFdx(uvw); 
    vec3 ddy_uvw = uvw + dFdy(uvw); 

    vec3 col;
    switch (hit.mat_id) {
        // water
        case 1:
            float spec = 0.5;
            vec3 waterCol = sat(spc(spec - 0.1, 0.4)) *
                (0.4 * pow(min(pos.y * 0.7 + 0.9, 1.8), 4.) *(rd.z * 0.15 + 0.85));
            col = waterCol * 3.;
            break;
        // right wall
        case 2: {
            col = pattern_filtered(uvw, ddx_uvw, ddy_uvw, iTime, 1., iResolution.xy);
            col = mix(col, vec3(0.), smoothstep(.5, 0., pos.y + 0.7));
            break; }
        // up right
        case 3:
            col = boxy_filtered(uvw, ddx_uvw, ddy_uvw, iTime);
            break;
        // up left
        case 4:
            col = boxy_filtered(uvw, ddx_uvw, ddy_uvw, iTime);
            break;
        // left wall
        case 5:
            col = pattern_filtered(uvw, ddx_uvw, ddy_uvw, iTime, 1., iResolution.xy);
            col = mix(col, vec3(0.), smoothstep(.5, 0., pos.y + 0.7));
            break;
        case 6:
            col = vec3(0.);
            break;
        default:
            col = vec3(1.);
            break;
    }
    return col;
}

vec3 render(vec3 ro, vec3 rd) {
    Hit hit = trace(ro, rd);
    vec3 albedo = get_material(ro, rd, hit);
    vec3 pos = ro + rd * hit.dist;
    float c = 5.;
    float center = floor((pos.z + c / 2.) / c) * c;

    vec3 light_start = vec3(0., 1.05, 0.0);
    vec3 light_end = vec3(0.9, 0.4, 0.0);

    light_start += vec3(0.0, 0.0, center);
    light_end += vec3(0.0, 0.0, center);
    
    vec3 col = vec3(0.);
    if (hit.dist < 1e9) {
        col = segment_light(ro, rd, hit, albedo, light_start, light_end, center);
        float neighbour = ((pos.z > center) ? 1.0 : -1.0) * c;
        light_start += vec3(0., 0., neighbour);
        light_end += vec3(0., 0., neighbour);
        col += segment_light(ro, rd, hit, albedo, light_start, light_end, neighbour);

        col = mix(col, vec3(0.), smoothstep(0.4, 0.9, length((ro + rd * hit.dist).xy) - 0.5));
    }
    
    float fog = 1. - exp((15. - hit.dist) * .10);
    col = mix(col, vec3(0.00), max(fog, 0.));
    
    return col;
}

//https://knarkowicz.wordpress.com/2016/01/06/aces-filmic-tone-mapping-curve/
vec3 ACESFilm(vec3 x){
    return clamp((x * (2.51 * x + 0.03)) / (x * (2.43 * x + 0.59) + 0.14), 0.0, 1.0);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
    float time = iTime;
    vec2 uv = (fragCoord - 0.5 * iResolution.xy) / iResolution.y;
   
    vec3 ro = vec3(.0, 0., -9.);
    vec3 rd = normalize(vec3(uv, 1.));

    ro.z += time;
    
    vec3 col = render(ro, rd);
    
    col += GLOW * mix(vec3(1.0, 1.0, 1.0), vec3(1.0, 0.5, 0.0), 0.5);

    col = ACESFilm(col);
    col = pow(col, vec3(1. / 3.2));
    fragColor = vec4(col, 1.0);
}