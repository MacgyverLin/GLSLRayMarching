#define MAX_STEPS 128
#define MIN_DIST 1e-5
#define MAX_DIST 8.0
#define CAM_ANGLE 1e-3
#define TWO_PI 6.28318530718
#define PI 3.14159265359

//internal RNG state 
uvec4 s0; 

// https://www.pcg-random.org/
void pcg4d(inout uvec4 v)
{
	v = v * 1664525u + 1013904223u;
    v.x += v.y*v.w; v.y += v.z*v.x; v.z += v.x*v.y; v.w += v.y*v.z;
    v = v ^ (v>>16u);
    v.x += v.y*v.w; v.y += v.z*v.x; v.z += v.x*v.y; v.w += v.y*v.z;
}

float rand()
{
    pcg4d(s0); return float(s0.x)/float(0xffffffffu);
}

vec2 rand2()
{
    pcg4d(s0); return vec2(s0.xy)/float(0xffffffffu);
}

vec4 rand4()
{
    pcg4d(s0); return vec4(s0)/float(0xffffffffu);
}

vec3 nrand3(float sigma, vec3 mean)
{
	vec4 Z = rand4();
    return mean + sigma * sqrt(-2.0 * log(Z.xxy)) * 
           vec3(cos(TWO_PI * Z.z),sin(TWO_PI * Z.z),cos(TWO_PI * Z.w));
}

vec3 erot(vec3 p, vec3 ax, float ro) {
    return mix(dot(p,ax)*ax,p,cos(ro))+sin(ro)*cross(ax,p);
}

float bunny(vec3 p) {
    //sdf is undefined outside the unit sphere, uncomment to witness the abominations
    if (length(p) > 1.) {
        return (length(p)-0.9);
    }
    //neural networks can be really compact... when they want to be
    vec4 f00=sin(p.y*vec4(-3.02,1.95,-3.42,-.60)+p.z*vec4(3.08,.85,-2.25,-.24)-p.x*vec4(-.29,1.16,-3.74,2.89)+vec4(-.71,4.50,-3.24,-3.50));
    vec4 f01=sin(p.y*vec4(-.40,-3.61,3.23,-.14)+p.z*vec4(-.36,3.64,-3.91,2.66)-p.x*vec4(2.90,-.54,-2.75,2.71)+vec4(7.02,-5.41,-1.12,-7.41));
    vec4 f02=sin(p.y*vec4(-1.77,-1.28,-4.29,-3.20)+p.z*vec4(-3.49,-2.81,-.64,2.79)-p.x*vec4(3.15,2.14,-3.85,1.83)+vec4(-2.07,4.49,5.33,-2.17));
    vec4 f03=sin(p.y*vec4(-.49,.68,3.05,.42)+p.z*vec4(-2.87,.78,3.78,-3.41)-p.x*vec4(-2.65,.33,.07,-.64)+vec4(-3.24,-5.90,1.14,-4.71));
    vec4 f10=sin(mat4(-.34,.06,-.59,-.76,.10,-.19,-.12,.44,.64,-.02,-.26,.15,-.16,.21,.91,.15)*f00+
        mat4(.01,.54,-.77,.11,.06,-.14,.43,.51,-.18,.08,.39,.20,.33,-.49,-.10,.19)*f01+
        mat4(.27,.22,.43,.53,.18,-.17,.23,-.64,-.14,.02,-.10,.16,-.13,-.06,-.04,-.36)*f02+
        mat4(-.13,.29,-.29,.08,1.13,.02,-.83,.32,-.32,.04,-.31,-.16,.14,-.03,-.20,.39)*f03+
        vec4(.73,-4.28,-1.56,-1.80))/1.0+f00;
    vec4 f11=sin(mat4(-1.11,.55,-.12,-1.00,.16,.15,-.30,.31,-.01,.01,.31,-.42,-.29,.38,-.04,.71)*f00+
        mat4(.96,-.02,.86,.52,-.14,.60,.44,.43,.02,-.15,-.49,-.05,-.06,-.25,-.03,-.22)*f01+
        mat4(.52,.44,-.05,-.11,-.56,-.10,-.61,-.40,-.04,.55,.32,-.07,-.02,.28,.26,-.49)*f02+
        mat4(.02,-.32,.06,-.17,-.59,.00,-.24,.60,-.06,.13,-.21,-.27,-.12,-.14,.58,-.55)*f03+
        vec4(-2.24,-3.48,-.80,1.41))/1.0+f01;
    vec4 f12=sin(mat4(.44,-.06,-.79,-.46,.05,-.60,.30,.36,.35,.12,.02,.12,.40,-.26,.63,-.21)*f00+
        mat4(-.48,.43,-.73,-.40,.11,-.01,.71,.05,-.25,.25,-.28,-.20,.32,-.02,-.84,.16)*f01+
        mat4(.39,-.07,.90,.36,-.38,-.27,-1.86,-.39,.48,-.20,-.05,.10,-.00,-.21,.29,.63)*f02+
        mat4(.46,-.32,.06,.09,.72,-.47,.81,.78,.90,.02,-.21,.08,-.16,.22,.32,-.13)*f03+
        vec4(3.38,1.20,.84,1.41))/1.0+f02;
    vec4 f13=sin(mat4(-.41,-.24,-.71,-.25,-.24,-.75,-.09,.02,-.27,-.42,.02,.03,-.01,.51,-.12,-1.24)*f00+
        mat4(.64,.31,-1.36,.61,-.34,.11,.14,.79,.22,-.16,-.29,-.70,.02,-.37,.49,.39)*f01+
        mat4(.79,.47,.54,-.47,-1.13,-.35,-1.03,-.22,-.67,-.26,.10,.21,-.07,-.73,-.11,.72)*f02+
        mat4(.43,-.23,.13,.09,1.38,-.63,1.57,-.20,.39,-.14,.42,.13,-.57,-.08,-.21,.21)*f03+
        vec4(-.34,-3.28,.43,-.52))/1.0+f03;
    f00=sin(mat4(-.72,.23,-.89,.52,.38,.19,-.16,-.88,.26,-.37,.09,.63,.29,-.72,.30,-.95)*f10+
        mat4(-.22,-.51,-.42,-.73,-.32,.00,-1.03,1.17,-.20,-.03,-.13,-.16,-.41,.09,.36,-.84)*f11+
        mat4(-.21,.01,.33,.47,.05,.20,-.44,-1.04,.13,.12,-.13,.31,.01,-.34,.41,-.34)*f12+
        mat4(-.13,-.06,-.39,-.22,.48,.25,.24,-.97,-.34,.14,.42,-.00,-.44,.05,.09,-.95)*f13+
        vec4(.48,.87,-.87,-2.06))/1.4+f10;
    f01=sin(mat4(-.27,.29,-.21,.15,.34,-.23,.85,-.09,-1.15,-.24,-.05,-.25,-.12,-.73,-.17,-.37)*f10+
        mat4(-1.11,.35,-.93,-.06,-.79,-.03,-.46,-.37,.60,-.37,-.14,.45,-.03,-.21,.02,.59)*f11+
        mat4(-.92,-.17,-.58,-.18,.58,.60,.83,-1.04,-.80,-.16,.23,-.11,.08,.16,.76,.61)*f12+
        mat4(.29,.45,.30,.39,-.91,.66,-.35,-.35,.21,.16,-.54,-.63,1.10,-.38,.20,.15)*f13+
        vec4(-1.72,-.14,1.92,2.08))/1.4+f11;
    f02=sin(mat4(1.00,.66,1.30,-.51,.88,.25,-.67,.03,-.68,-.08,-.12,-.14,.46,1.15,.38,-.10)*f10+
        mat4(.51,-.57,.41,-.09,.68,-.50,-.04,-1.01,.20,.44,-.60,.46,-.09,-.37,-1.30,.04)*f11+
        mat4(.14,.29,-.45,-.06,-.65,.33,-.37,-.95,.71,-.07,1.00,-.60,-1.68,-.20,-.00,-.70)*f12+
        mat4(-.31,.69,.56,.13,.95,.36,.56,.59,-.63,.52,-.30,.17,1.23,.72,.95,.75)*f13+
        vec4(-.90,-3.26,-.44,-3.11))/1.4+f12;
    f03=sin(mat4(.51,-.98,-.28,.16,-.22,-.17,-1.03,.22,.70,-.15,.12,.43,.78,.67,-.85,-.25)*f10+
        mat4(.81,.60,-.89,.61,-1.03,-.33,.60,-.11,-.06,.01,-.02,-.44,.73,.69,1.02,.62)*f11+
        mat4(-.10,.52,.80,-.65,.40,-.75,.47,1.56,.03,.05,.08,.31,-.03,.22,-1.63,.07)*f12+
        mat4(-.18,-.07,-1.22,.48,-.01,.56,.07,.15,.24,.25,-.09,-.54,.23,-.08,.20,.36)*f13+
        vec4(-1.11,-4.28,1.02,-.23))/1.4+f13;
    float o = dot(f00,vec4(.09,.12,-.07,-.03))+dot(f01,vec4(-.04,.07,-.08,.05))+
        dot(f02,vec4(-.01,.06,-.02,.07))+dot(f03,vec4(-.05,.07,.03,.04))-0.16;
    return o*0.85; //its a nonperfect sdf
}

vec2 opUnion(vec2 a, vec2 b)
{
    return (a.x < b.x)?a:b;
}

vec2 scene(vec3 p)
{
    vec2 plane = vec2(p.z + 0.5, 0);
    vec2 bunnys = vec2(bunny(p), 1);
    return opUnion(bunnys, plane);
}

vec3 norm(vec3 p) {
    mat3 k = mat3(p,p,p)-mat3(0.001);
    return normalize(scene(p).x - vec3(scene(k[0]).x,scene(k[1]).x,scene(k[2]).x));
}

float trace(inout vec4 ro, vec3 rd)
{
    vec2 de = vec2(-1);
    for(int i = 0; i < MAX_STEPS; i++)
    {
        de = scene(ro.xyz); 
        float md = max(CAM_ANGLE*ro.w,MIN_DIST);
        ro += vec4(rd, 1.0)*(de.x - 2.0*step(de.x, md)*md); 
        if(de.x < md) return de.y;
        if(ro.w > MAX_DIST) return -1.0;
    }
    return de.y;
}

vec3 pathtrace(vec4 ro, vec3 rd)
{
    vec3 outcol = vec3(0.); vec3 matcol = vec3(1.);
    for(int i = 0; i<4; i++)
    {
        float hit = trace(ro, rd);
        if(hit>=0.0)
        {
            vec3 n = norm(ro.xyz); //geometric normal
            vec3 s = sin(100.*erot(ro.xyz, vec3(1), 3.2)) + sin(150.*erot(ro.xyz, vec3(0,1,0.5), 1.2));
            
            float roughness =(rand()>0.5)?0.5:0.05;
            if(hit == 0.0)
            {
                bool tile =mod(ro.x, 1.0) + mod(ro.y, 1.0) > 1.0;
                matcol *= tile?vec3(0.780,0.678,0.678):vec3(1.000,1.000,1.000); 
            }
            else
            {
                matcol *= vec3(0.804,0.914,0.996);
            }
            vec3 m = normalize(nrand3(roughness, n) + 0.1*hit*s); //material normal
            rd = reflect(rd,m);
        }
        else
        {
            outcol += matcol*pow(texture(iChannel1, rd.xzy).xyz,vec3(2.0));
            break;
        }
    }
    return outcol;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    //RNG
    s0 = uvec4(fragCoord, uint(iFrame), uint(fragCoord.x) + uint(fragCoord.y));

    fragColor = texture(iChannel0, fragCoord/iResolution.xy);
    
    fragCoord += rand2();
    vec2 uv = (fragCoord-0.5*iResolution.xy)/iResolution.y;
    vec2 mouse = iMouse.xy/iResolution.y;

    vec3 cam = normalize(vec3(1.5,uv));
    vec3 init = vec3(-3.,0,0);
    
    float yrot = 0.5 - 0.5*mouse.y;
    float zrot = 4.0*mouse.x;
    if (iMouse.z > 0.) {
        fragColor *= 0.0;
    }
    cam = erot(cam, vec3(0,1,0), yrot);
    cam = erot(cam, vec3(0,0,1), zrot);
    
    init = erot(init, vec3(0,1,0), yrot);
    init = erot(init, vec3(0,0,1), zrot);
    
    fragColor += vec4(pathtrace(vec4(init, 0.), cam), 1.0);
}
