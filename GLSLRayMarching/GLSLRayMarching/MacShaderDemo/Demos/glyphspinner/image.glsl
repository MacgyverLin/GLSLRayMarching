/* "glyphspinner" by mattz
   License: https://creativecommons.org/licenses/by-nc-sa/3.0/

   I've been carrying this shader in my head for a long time, 
   glad I finally had some time to work on it!

   Towards the end of developing a shader, I'm always pleased
   if I realize I've zoned out watching it run instead of 
   putting the finishing touches on it, which certainly was
   the case here.

   Since I couldn't get the glyph edges nicely antialiased, 
   I decided to leave the backgrounda  bit rough, too, which
   you can see if you pause the shader. 

*/

//#define PERSPECTIVE

const vec3 bgcolor = vec3(0, 0.1, 0.1);
const vec3 color_a = vec3(1.0, 0.4, 0);
const vec3 color_b = vec3(0.3, 0, 0.7);
const vec3 outline = vec3(1, 0, 0.2);

float t = 0.0;

// texture is 1024x1024
const float TEX_RES = 1024.;

// texture is 16x16 glyphs
const float GLYPHS_PER_UV = 16.;

// since the texture is uint8 it has a bias to represent 0
const float TEX_BIAS = 127./255.;

// get font UV coords from screen coords
vec2 font_from_screen(vec2 tpos, vec2 char_pos) {    
    return (tpos + char_pos + 0.5)/GLYPHS_PER_UV;
}


float sample_dist_gaussian(vec2 uv) {

    float dsum = 0.;
    float wsum = 0.;
    
    const int nstep = 3;
    
    const float w[3] = float[3](1., 2., 1.);
    
    for (int i=0; i<nstep; ++i) {
        for (int j=0; j<nstep; ++j) {
            
            vec2 delta = vec2(float(i-1), float(j-1))/TEX_RES;
            
            float dist = textureLod(iChannel0, uv-delta, 0.).w - TEX_BIAS;
            float wij = w[i]*w[j];
            
            dsum += wij * dist;
            wsum += wij;

        }
    }
    
    return dsum / wsum;
}


/* Rotate about x-axis */
mat3 rotX(in float t) {
    float cx = cos(t), sx = sin(t);
    return mat3(1., 0, 0, 
                0, cx, sx,
                0, -sx, cx);
}


/* Rotate about y-axis */
mat3 rotY(in float t) {
    float cy = cos(t), sy = sin(t);
    return mat3(cy, 0, -sy,
                0, 1., 0,
                sy, 0, cy);

}


float approx_font_dist(vec2 p, int cidx) {

    float d = max(abs(p.x) - 0.25,
                  max(p.y - 0.3, -0.28 - p.y));
    
    vec2 cpos = vec2(float(cidx%16), float(15-cidx/16));
    vec2 uv = font_from_screen(p, cpos);
    
    float fd = sample_dist_gaussian(uv); 
        
    
    d = max(d, fd);
        
    
    return d;
    
}

vec3 map(in vec3 pos) {	

    int ca = int(t) % 26;
    int cb = (ca + 1) % 26;
    int cc = (ca + 2) % 26;

    float da = approx_font_dist(pos.xy, 65+ca);
    float dc = approx_font_dist(pos.xy, 65+cc);
    
    float ft = fract(t);
    
    if (ft > 0.95) {
        da = mix(min(da, dc), dc, smoothstep(0.95, 1.0, ft));
    } else if (ft > 0.9) {
        da = mix(da, min(da, dc), smoothstep(0.9, 0.95, ft));
    }
                   
    float db = approx_font_dist(pos.zy, 65+cb);
                   
    
    return vec3(max(da, db), da, db);
   
}

/* IQ's distance marcher. */
vec3 castRay( in vec3 ro, in vec3 rd) {
    
    const int rayiter = 80;
    const float dmax = 8.;

    const float precis = 0.001;   
    float h=2.0*precis;

    float t = 0.0;
    vec2 m = vec2(-1.0);

    for( int i=0; i<rayiter; i++ ) {

        if( abs(h)<precis||t>dmax ) { continue; }
        
        t += min(0.25, h);
        vec3 res = map( ro+rd*t );
        h = res.x;
        m = res.yz;
        
    }    

    if (t > dmax) { return vec3(-1); }
    if (abs(h) > 4.0*precis) { return vec3(-1); }

    return vec3(t, m);

}

vec3 shade( in vec3 ro, in vec3 rd ,
           inout vec3 c){

    vec3 tm = castRay(ro, rd);        

    if (tm.x >= 0.0) {

        vec3 pos = ro + tm.x*rd;
        
        vec3 d = map(pos);
        
        
        float flip = mod(t, 2.0) < 1.0 ? -1.0 : 1.0;
        
        vec3 fg = mix(color_a, color_b,
                      step(flip*d.y, flip*d.z));
                
        c = mix(fg, outline, smoothstep(0.003, 0.0, abs(d.y-d.z)-0.008));

    }

    return c;

}

float scribble(vec2 p, float k) {
    
    float scl = k/iResolution.y;
    
    float kspiral = 0.2;
    
    vec2 c = p*scl;
    vec2 c0 = floor(c+0.5);
    
    float d = 1e5;
    
    for (int i=-1; i<2; ++i) {
        for (int j=-1; j<2; ++j) {
            
            vec2 cij = c0 + vec2(float(i), float(j));
                       
            vec4 r = textureLod(iChannel1, (cij+0.5)/256., 0.);
            cij += 0.5*(r.xy - 0.5);
            
            vec2 diff = c - cij;
            float sz = 0.3 + 0.3*(r.z - 0.5);
            
            float t = r.z *  10253.5721;
            float c = cos(t), s = sin(t);
            
            diff = mat2(c, -s, s, c) * diff;

            vec2 sq = abs(diff) - sz;
            float dsqr = max(sq.x, sq.y);
            
            if (r.w < 0.5) {
                
                if (r.w < 0.25) {
                    d = min(d, abs(dsqr));
                } else {
                    float dx = abs(dot(abs(diff), normalize(vec2(-1,1))));
                    dx = max(dx, dsqr);
                    d = min(d, dx);
                }
                
            } else if (r.w < 0.75) {
                
                d = min(d, abs(length(diff) - sz));
                                
            } else {
                
                diff.x = abs(diff.x);
                
                float dtri = max(-diff.y, 
                                 dot(diff, vec2(0.8660254037844386, 0.5)));
                
                d = min(d, abs(dtri-0.85*sz));
                
            }

        }
    }
    
    return step(0., d-0.1);
    
}

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {

    vec2 uv = (fragCoord.xy - .5*iResolution.xy) * 0.8 / (iResolution.y);

    t = 0.45*max(0.0, iTime-2.0);
    
    float s = scribble(fragCoord + 0.45*iTime*vec2(75., 30), 7.);

    vec3 bgdark = mix(bgcolor, vec3(0), 0.6);
    vec3 bglite = mix(bgcolor, vec3(1), 0.25);
    vec3 color = mix(bgcolor, bgdark, s);
    
    float rad = 0.05*iResolution.y;
    float m = rad;
    float x0 = m+rad;
    
    if (max(iMouse.x, iMouse.y) > x0) {        

        float row = floor(4.0 - 4.0 * iMouse.y / iResolution.y);
        float ux = clamp( (iMouse.x - x0) / (iResolution.x - 2.*x0), 0., 1.);
        
        if (mod(row, 2.0) != 0.0) { ux = 1.0 - ux; }
        
        t = 6.5 * (ux + row) + 1e-5;

    }
    
    float u = fract(t);
    u = smoothstep(0.1, 0.9, u);
    
    float midbump = smoothstep(0.5, 0.0, abs(u-0.5));

    float thetay = -1.5707963267948966*u;
    float thetax = 0.4*midbump;

    mat3 Rview = rotY(thetay)*rotX(thetax); 

#ifdef PERSPECTIVE
    const float f = 1.5;
    vec3 rd = Rview*normalize(vec3(uv, f));
    vec3 ro = Rview*vec3(0,0,-f);
#else
    vec3 rd = Rview*vec3(0, 0, 1);
    vec3 ro = Rview*vec3(uv*0.9, -3.5);
#endif
    
    if (max(iMouse.z, iMouse.w) > x0) {
        
        vec2 p = fragCoord - iResolution.xy*vec2(0.5, 0);
        
        float row = floor(4.0*fragCoord.y/iResolution.y);
        float rowy = (row + 0.5)* iResolution.y * 0.25;
         
        float dx = sign(p.x);
        float dy = mod(row, 2.0) > 0.0 ? -1.0 : 1.0;
        dy *= dx;
        
        vec2 ctr = vec2(dx*(0.5*iResolution.x - x0),
                        rowy + dy*rad);
        
        float dcirc = 1e5;
        float dly = abs(p.y - rowy);
        float dlx = abs(p.x) - (0.5*iResolution.x - m);
        
        if (p.x > 0.5 || (row != 0. && row != 3.)) { 
            vec2 dctr = p - ctr;
            dcirc = abs(length(dctr) - rad);
            dcirc = max(-dctr.x*dx, max(dctr.y*dy, dcirc));
            dcirc = min(dcirc, max(dctr.y*-dy, abs(dctr.x-dx*rad)));
            dlx = abs(p.x) - (0.5*iResolution.x - x0);
        }
        
        float dpath = min(dcirc, max(dlx, dly)) - 2.0;
        
        color = mix(color, bglite, smoothstep(1., 0., dpath));
    }
    
    shade(ro, rd, color);

    color = pow(color, vec3(1.0/2.2));

    fragColor = vec4(color, 1);

}
