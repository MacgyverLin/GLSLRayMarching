//Set to 2.0 for AA
#define AA 1.0

#define STEPS 80.0
#define MDIST 35.0
#define pi 3.1415926535
#define rot(a) mat2(cos(a),sin(a),-sin(a),cos(a))
#define sat(a) clamp(a,0.0,1.0)

#define ITERS_TRACE 9
#define ITERS_NORM 20

#define HOR_SCALE 1.1
#define OCC_SPEED 1.4
#define DX_DET 0.65

#define FREQ 0.6
#define HEIGHT_DIV 2.5
#define WEIGHT_SCL 0.8
#define FREQ_SCL 1.2
#define TIME_SCL 1.095
#define WAV_ROT 1.21
#define DRAG 0.9
#define SCRL_SPEED 1.5
vec2 scrollDir = vec2(1,1);


//Built with some ideas from
//https://www.shadertoy.com/view/wldBRf
//https://www.shadertoy.com/view/ssG3Wt
//https://www.shadertoy.com/view/4dBcRD
//https://www.shadertoy.com/view/Xdlczl
vec2 wavedx(vec2 wavPos, int iters, float t){
    vec2 dx = vec2(0);
    vec2 wavDir = vec2(1,0);
    float wavWeight = 1.0; 
    wavPos+= t*SCRL_SPEED*scrollDir;
    wavPos*= HOR_SCALE;
    float wavFreq = FREQ;
    float wavTime = OCC_SPEED*t;
    for(int i=0;i<iters;i++){
        wavDir*=rot(WAV_ROT);
        float x = dot(wavDir,wavPos)*wavFreq+wavTime; 
        float result = exp(sin(x)-1.)*cos(x);
        //if(result>0.) foam+=result*0.3;
        result*=wavWeight;
        dx+= result*wavDir/pow(wavWeight,DX_DET); 
        wavFreq*= FREQ_SCL; 
        wavTime*= TIME_SCL;
        wavPos-= wavDir*result*DRAG; 
        wavWeight*= WEIGHT_SCL;
    }
    float wavSum = -(pow(WEIGHT_SCL,float(iters))-1.)*HEIGHT_DIV; 
    return dx/pow(wavSum,1.-DX_DET);
}

float wave(vec2 wavPos, int iters, float t){
    float wav = 0.0;
    vec2 wavDir = vec2(1,0);
    float wavWeight = 1.0;
    wavPos+= t*SCRL_SPEED*scrollDir;
    wavPos*= HOR_SCALE; 
    float wavFreq = FREQ;
    float wavTime = OCC_SPEED*t;
    for(int i=0;i<iters;i++){
        wavDir*=rot(WAV_ROT);
        float x = dot(wavDir,wavPos)*wavFreq+wavTime;
        float wave = exp(sin(x)-1.0)*wavWeight;
        wav+= wave;
        wavFreq*= FREQ_SCL;
        wavTime*= TIME_SCL;
        wavPos-= wavDir*wave*DRAG*cos(x);
        wavWeight*= WEIGHT_SCL;
    }
    float wavSum = -(pow(WEIGHT_SCL,float(iters))-1.)*HEIGHT_DIV; 
    return wav/wavSum;
}

vec3 norm(vec3 p){
    vec2 wav = -wavedx(p.xz, ITERS_NORM, iTime);
    return normalize(vec3(wav.x,1.0,wav.y));
}

float map(vec3 p){
    float a = 0.;
    int steps = ITERS_TRACE;
    p.y-= wave(p.xz,steps,iTime);
    a = p.y;
    return a;
}

vec3 pal(float t, vec3 a, vec3 b, vec3 c, vec3 d){
    return a+b*cos(2.0*pi*(c*t+d));
}
vec3 spc(float n,float bright){
    return pal(n,vec3(bright),vec3(0.5),vec3(1.0),vec3(0.0,0.33,0.67));
}
vec2 sunrot = vec2(-0.3,-0.25);

//Change the color of the scene here, it better withs some colors than others
float spec = 0.13;

vec3 sky(vec3 rd){
    float px = 1.5/min(iResolution.x,iResolution.y);
    vec3 rdo = rd;
    float rad = 0.075;
    vec3 col = vec3(0);

    //Sun
    rd.yz*=rot(sunrot.y);
    rd.xz*=rot(sunrot.x);
    float sFade = 2.5/min(iResolution.x,iResolution.y);
    float zFade = rd.z*0.5+0.5;
    
    vec3 sc = spc(spec-0.1,0.6)*0.85;
    float a = length(rd.xy);
    vec3 sun=smoothstep(a-px-sFade,a+px+sFade,rad)*sc*zFade*2.;
    col+=sun;
    col+=rad/(rad+pow(a,1.7))*sc*zFade;
    col=col+mix(col,spc(spec+0.1,0.8),sat(1.0-length(col)))*0.2;
    
    //This code provides the implication of clouds :)
    float e = 0.;
    vec3 p = rdo;
    p.xz*=0.4;
    p.x+=iTime*0.007;
    for(float s=200.;s>10.;s*=0.8){
        p.xz*=rot(s);
        p+=s;
        e+=abs(dot(sin(p*s+iTime*0.02)/s,vec3(1.65)));
    }
    e*=smoothstep(0.5,0.4,e-0.095);
    
    col += (e)*smoothstep(-0.02,0.3,rdo.y)*0.8*(1.0-sun*3.75)*mix(sc,vec3(1),0.4);
    
    return (col);
}
void render( out vec4 fragColor, in vec2 fragCoord ){
    vec2 uv = (fragCoord-0.5*iResolution.xy)/min(iResolution.y,iResolution.x);
    vec3 col = vec3(0);
    vec3 ro = vec3(0,2.25,-3)*1.1;
    bool click = iMouse.z>0.;
    if(click){
    ro.yz*=rot(2.0*min(iMouse.y/iResolution.y-0.5,0.15));
    ro.zx*=rot(-7.0*(iMouse.x/iResolution.x-0.5));
    }
    vec3 lk = vec3(0,2,0);
    vec3 f = normalize(lk-ro);
    vec3 r = normalize(cross(vec3(0,1,0),f));
    vec3 rd = normalize(f*(0.9)+uv.x*r+uv.y*cross(f,r));

    float dO = 0.;
    bool hit = false;
    float d = 0.;
    vec3 p = ro;

    float tPln = -(ro.y-1.86)/rd.y;
    if(tPln>0.||click){
        if(!click)dO+=tPln;
        for(float i = 0.; i<STEPS; i++){
            p = ro+rd*dO;d = map(p);dO+=d;
            if(abs(d)<0.005||i>STEPS-2.0){
                hit = true;
                break;
            }
            if(dO>MDIST){
                dO = MDIST;
                break;
            }
        }
    }
    vec3 skyrd = sky(rd);
    if(hit){
    vec3 n = norm(p);
    vec3 rfl = reflect(rd,n);
    rfl.y = abs(rfl.y);
    vec3 rf = refract(rd,n,1./1.33); 
    vec3 sd = normalize(vec3(0,0.3,-1.0));
    float fres = clamp((pow(1. - max(0.0, dot(-n, rd)), 5.0)),0.0,1.0);

    vec3 sunDir = vec3(0,0.15,1.0);
    sunDir.xz*=rot(-sunrot.x);
    col += sky(rfl)*fres*0.9;
    float subRefract =pow(max(0.0, dot(rf,sunDir)),35.0);
    //This effect is exaggerated much more than is realistic because I like it :) 
    col += pow(spc(spec-0.1,0.5),vec3(2.2))*subRefract*2.5;
    vec3 rd2 = rd;
    rd2.xz*=rot(sunrot.x);
    vec3 waterCol = min(sat(spc(spec-0.1,0.4))*0.05*pow(min(p.y+0.5,1.8),4.0)*length(skyrd)*(rd2.z*0.3+0.7),1.0);
   
    waterCol = sat(spc(spec-0.1,0.4))*(0.4*pow(min(p.y*0.7+0.9,1.8),4.)*length(skyrd)*(rd2.z*0.15+0.85));
    col += waterCol*0.17;
    //col+=smoothstep(0.95,1.55,wave(p.xz,25,iTime))*mix(waterCol*0.3,vec3(1),0.2)*0.2;

    col = mix(col,skyrd,dO/MDIST);
    }
    else{
        col += skyrd;
    }
    col = sat(col);
    col = pow(col,vec3(0.87));
    col *=1.0-0.8*pow(length(uv*vec2(0.8,1.)),2.7);
    fragColor = vec4(col,1.0);
    
}

#define ZERO min(0.0,iTime)
void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    float px = 1.0/AA;
    vec4 col = vec4(0);
    
    if(AA==1.0) {render(col,fragCoord); fragColor = col; return;}
    
    for(float i = ZERO; i <AA; i++){
        for(float j = ZERO; j <AA; j++){
            vec4 col2;
            vec2 coord = vec2(fragCoord.x+px*i,fragCoord.y+px*j);
            render(col2,coord);
            col.rgb+=col2.rgb;
        }
    }
    col/=AA*AA;
    fragColor = vec4(col);
}