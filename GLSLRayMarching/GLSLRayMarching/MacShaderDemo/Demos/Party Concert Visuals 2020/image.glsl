//CC0 1.0 Universal https://creativecommons.org/publicdomain/zero/1.0/
//To the extent possible under law, Blackle Mori has waived all copyright and related or neighboring rights to this work.

float comp (vec3 p) {
    p = asin(sin(p)*.9);
    return length(p)-1.;
}

vec3 erot(vec3 p, vec3 ax, float ro) {
    return mix(dot(p,ax)*ax,p,cos(ro))+sin(ro)*cross(ax,p);
}

float smin(float a, float b, float k) {
    float h = max(0.,k-abs(b-a))/k;
    return min(a,b)-h*h*h*k/6.;
}

vec4 wrot(vec4 p) {
    return vec4(dot(p,vec4(1)), p.yzw + p.zwy - p.wyz - p.xxx)/2.;
}

float d1, d2, d3;
float t;
float lazors, doodad;
vec3 p2;
float bpm = 125.;
float scene(vec3 p) {
    p2 = erot(p, vec3(0,1,0), t);
    p2 = erot(p2, vec3(0,0,1), t/3.);
    p2 = erot(p2, vec3(1,0,0), t/5.);
    
    float bpt = iTime/60.*bpm;
        vec4 p4 = vec4(p2,0);
        p4=mix(p4,wrot(p4),smoothstep(-.5,.5,sin(bpt/4.)));
        p4 =abs(p4);
        p4=mix(p4,wrot(p4),smoothstep(-.5,.5,sin(bpt)));
    float fctr = smoothstep(-.5,.5,sin(bpt/2.));
    float fctr2 = smoothstep(.9,1.,sin(bpt/16.));
        doodad = length(max(abs(p4)-mix(0.05,0.07,fctr),0.)+mix(-0.1,.2,fctr))-mix(.15,.55,fctr*fctr)+fctr2;
    /*
        vec4 p4 = vec4(p2,0);
        p4=wrot(p4);
        p4 = abs(p4);
        p4=mix(p4,wrot(p4),smoothstep(-.5,.5,sin(t)));
        doodad = length(max(abs(p4)-0.07,0)+0.2)-.55;
    }*/
    
    p.x += asin(sin(t/80.)*.99)*80.;
    
    lazors = length(asin(sin(erot(p,vec3(1,0,0),t*.2).yz*.5+1.))/.5)-.1;
    d1 = comp(p);
    d2 = comp(erot(p+5., normalize(vec3(1,3,4)),0.4));
    d3 = comp(erot(p+10., normalize(vec3(3,2,1)),1.));
    return min(doodad,min(lazors,.3-smin(smin(d1,d2,0.05),d3,0.05)));
}

vec3 norm(vec3 p) {
    float precis = length(p) < 1. ? 0.005 : 0.01;
    mat3 k = mat3(p,p,p)-mat3(precis);
    return normalize(scene(p)-vec3(scene(k[0]),scene(k[1]),scene(k[2])));
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = (fragCoord-.5*iResolution.xy)/iResolution.y;

    float bpt = iTime/60.*bpm;
    float bp = mix(pow(sin(fract(bpt)*3.14/2.),20.)+floor(bpt), bpt,0.4);
    t = bp;
	vec3 cam = normalize(vec3(.8+sin(bp*3.14/4.)*.3,uv));
    vec3 init = vec3(-1.5+sin(bp*3.14)*.2,0,0)+cam*.2;
    init = erot(init,vec3(0,1,0),sin(bp*.2)*.4);
    init = erot(init,vec3(0,0,1),cos(bp*.2)*.4);
    cam = erot(cam,vec3(0,1,0),sin(bp*.2)*.4);
    cam = erot(cam,vec3(0,0,1),cos(bp*.2)*.4);
    vec3 p = init;
    bool hit = false;
    float atten = 1.;
    float tlen = 0.;
    float glo = 0.;
    float dist;
    float fog = 0.;
    float dlglo = 0.;
    bool trg = false;
    for (int i = 0; i <80 && !hit; i++) {
        dist = scene(p);
        hit = dist*dist < 1e-6;
        glo += .2/(1.+lazors*lazors*20.)*atten;
        dlglo += .2/(1.+doodad*doodad*20.)*atten;
        if (hit && ((sin(d3*45.)<-0.4 && (dist!=doodad )) || (dist==doodad && sin(pow(length(p2*p2*p2),.3)*120.)>.4 )) && dist != lazors) {
            trg = trg || dist==doodad;
            hit = false;
            vec3 n = norm(p);
            atten *= 1.-abs(dot(cam,n))*.98;
            cam = reflect(cam,n);
            dist = .1;
        }
        p += cam*dist;
        tlen += dist;
        fog += dist*atten/30.;
    }
    fog = smoothstep(0.,1.,fog);
    bool lz = lazors == dist;
    bool dl = doodad == dist;
    vec3 fogcol = mix(vec3(0.5,0.8,1.2), vec3(0.4,0.6,0.9), length(uv));
    vec3 n = norm(p);
    vec3 r = reflect(cam,n);
    float ss = smoothstep(-.3,0.3,scene(p+vec3(.3)))+.5;
    float fact = length(sin(r*(dl?4.:3.))*.5+.5)/sqrt(3.)*.7+.3;
    vec3 matcol = mix(vec3(0.9,0.4,0.3), vec3(0.3,0.4,0.8), smoothstep(-1.,1.,sin(d1*5.+iTime*2.)));
    matcol = mix(matcol, vec3(0.5,0.4,1.0), smoothstep(0.,1.,sin(d2*5.+iTime*2.)));
    if (dl) matcol = mix(vec3(1),matcol,0.1)*.2+0.1;
    vec3 col = matcol*fact*ss + pow(fact,10.);
    if (lz) col = vec3(4);
    fragColor.xyz = col*atten + glo*glo + fogcol*glo;
    
    fragColor.xyz = mix(fragColor.xyz, fogcol, fog);
    if(!dl)fragColor.xyz = abs(erot(fragColor.xyz, normalize(sin(p*2.)),0.2*(1.-fog)));
    if(!trg&&!dl)fragColor.xyz+=dlglo*dlglo*.1*vec3(0.4,0.6,0.9);
    fragColor.xyz = sqrt(fragColor.xyz);
    fragColor.xyz = smoothstep(vec3(0),vec3(1.2),fragColor.xyz);
}
