// hash without sine - the best choice for adding rain :)
// https://www.shadertoy.com/view/4djSRW
#define MOD3 vec3(443.8975,397.2973, 491.1871)
float hash12(vec2 p) {
	vec3 p3  = fract(vec3(p.xyx) * MOD3);
    p3 += dot(p3, p3.yzx + 19.19);
    return fract((p3.x + p3.y) * p3.z);
}

// multiscale noise from image
float getLand(vec2 p) {
    float f = 0.;
    for(int i=0; i<16; i++) {
        float pwv = pow(1.1, float(i));
        f += .25 / pwv * texture(iChannel1, p*pwv+.1*iTime+.2+.2*float(i)).r;
    }
    return f;
}

#define t2D(x, y) texture(iChannel0, fract(uv-vec2(x, y)/res))

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
    vec2 res = iResolution.xy;
    vec2 uv = fragCoord.xy / res;
    
    vec4 buf[9];
    buf[0] = t2D(0.,  0.);
    buf[1] = t2D(1.,  0.);
    buf[2] = t2D(-1., 0.);
    buf[3] = t2D(0.,  1.);
    buf[4] = t2D(0., -1.);
    buf[5] = t2D(1.,  1.);
    buf[6] = t2D(-1., 1.);
    buf[7] = t2D(1., -1.);
    buf[8] = t2D(-1.,-1.);
    
    float lhc = buf[0].r;  // land height (this cell)
    float wvc = buf[0].g;  // water volume (this cell)
    float whc = wvc + lhc; // water height (this cell)
    
    // land height & water volume (outputs)
    float lh, wv;
    
    // first frame operations
    if(iFrame<10 || texture(iChannel3, vec2(82.5/256., .2)).r>0.) {
        wv = 0.;
        
        // texture scale
        //vec2 ts = .125 * vec2(res.x/res.y, 1.);
        float ts = 3000.;
        vec2 o = vec2(-.5, .5);
        vec2 suv = smoothstep(0., 1., uv);
        
        // tiled landscape
        lh =
            mix(
                mix(
                    getLand((fragCoord-o.xx*res)/ts),
                    getLand((fragCoord-o.yx*res)/ts),
                    suv.x
                ),
                mix(
                    getLand((fragCoord-o.xy*res)/ts),
                    getLand((fragCoord-o.yy*res)/ts),
                    suv.x
                ),
                suv.y
            );
        float dist = distance(uv*0.5, 0.5*vec2(0.5,0.5));
        dist=sqrt(dist);
        dist = max(dist, .5);
        lh = 1.-dist;
        
        float noise = 0.1;
        lh = lh*(1.-noise) + noise*fbm(uv);
        
        dist = distance(uv*0.5, 0.5*vec2(0.5,0.5));
        dist*=.9; //.9 ideal
        //dist = pow(dist,2.)*2.;
        lh=1./dist;
        lh*=0.1;
        lh = max(lh, 0.1);
        lh = min(1.2, lh);
        
        noise = 0.35;
        lh = lh*(1.-noise) + noise*turbulent(uv) + 0.16; //use noise=0.35
        //lh = lh*(1.-noise) + noise*fbm(uv) + 0.16; //use noise=0.4
        
        if(dist < 0.07) lh-=0.2*(1.-dist/ 0.07)  ;
        //lh=max(min(0.7, dist),0.);
        //lh*=5.;
        //lh = 0.5 + fbm(uv)*0.5;
    }
    // simulation
    else {
		lh = buf[0].r;
        wv = buf[0].g;
        for(int i=1; i<9; i++) {
            float lhi = buf[i].r;  // land height (neighboring cell)
            float wvi = buf[i].g;  // water volume (neighboring cell)
            float whi = wvi + lhi; // water height (neighboring cell)
            float wslope = whi - whc; // water slope
            float lslope = lhi - lhc; // land slope
            
            // normalize corner weights for slopes
            if(i>4) {
                wslope /= sqrt(2.);
                lslope /= sqrt(2.);
            }
            
            if(wvc>0. && wslope<0.) {
                
                // give water
                wv += wslope / 9.;
                
                // basic erosion
                lh += .003 * wslope;
            }
            
            if(wvi>0. && wslope>0.) {
                
                // take water (currently less than it should, to help keep water from sticking to slopes)
                wv += wslope / 12.;
                
                // basic erosion
                lh -= .003 * wslope;
            }
            
            // give & take land base on water slope (help smooth things out)
            lh += .001 * wslope;
            
            // collapse steep land slopes (loss only)(helps widen gullies)
            if(lslope < -.002-.004*hash12(uv))
                lh += lslope / 9.;
        }
        
        // add land based on water volume
        //lh += .001 * wv;
        
        // 'evaporation'
        //wv -= 1. / 65535.;
        
        // 'rain'
        if(hash12(mod(uv+iTime/100., 100.))>.5)
            wv += 4. / 65535.;
    }
    
    fragColor = vec4(lh, .98*wv, 0., 0.);
}