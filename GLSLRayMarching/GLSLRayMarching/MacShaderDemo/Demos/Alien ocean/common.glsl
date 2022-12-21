#define PI 3.141592
#define EPS 0.005

#define ITERS_RAY    17
#define ITERS_NORMAL 45
#define W_DEPTH  2.2
#define W_SPEED  1.4
#define W_DETAIL .75

const mat2 rot = mat2(cos(12.),sin(12.),-sin(12.),cos(12.));

vec3 srf(vec2 pos, int n, float time)
{
    pos *= W_DEPTH;
    float freq = 0.6;
    float t = W_SPEED*time;
    float weight = 1.0;
    float w = 0.0;
    vec2 dx = vec2(0);
    
    vec2 dir = vec2(1,0);
    for(int i=0;i<n;i++){
        dir = rot*dir;
        float x = dot(dir, pos) * freq + t;
        float wave = exp(sin(x)-1.);
        vec2 res = vec2(wave, wave*cos(x)) * weight;
        pos    -= dir*res.y*.48;
        w      += res.x;
        dx     += res.y*dir / pow(weight,W_DETAIL);
        weight *= .8;
        freq   *= 1.2;
        t   *= 1.08;
    }
    float ws = (pow(.8,float(n))-1.)*-5.; //Geometric sum
    
    return vec3(w / ws,dx / pow(ws,1.-W_DETAIL));
}

vec3 norm(vec2 p, int n, float time){
    return normalize(vec3(-srf(p.xy, n, time).yz,1.).xzy);
}

vec3 camera_ray(vec3 vo, vec2 uv, vec2 muv, float iTime)
{
    vec3 vd = normalize(vec3(uv,1));
    
    //Add Mouse rotation
    vec4 cs = vec4(cos(muv),sin(muv));
    vd.yz = mat2(cs.y,cs.w,-cs.w,cs.y)*vd.yz;
    vd.xz = mat2(cs.x,cs.z,-cs.z,cs.x)*vd.xz;
    //Add Water bobbing
    vec2 ang = norm(vo.xz,5, iTime).xz*-.05*PI;
    cs = vec4(cos(ang),sin(ang));
    vd.xy = mat2(cs.x,cs.z,-cs.z,cs.x)*vd.xy;
    vd.zy = mat2(cs.y,cs.w,-cs.w,cs.y)*vd.zy;    
    return vd;
}