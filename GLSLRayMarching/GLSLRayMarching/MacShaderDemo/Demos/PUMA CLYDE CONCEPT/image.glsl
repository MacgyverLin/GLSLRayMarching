#define PI 3.141592653589793
#define Rot(a) mat2(cos(a),-sin(a),sin(a),cos(a))
#define antialiasing(n) n/min(iResolution.y,iResolution.x)
#define S(d,b) smoothstep(antialiasing(1.0),b,d)
#define SHDOW_COL vec3(0.5)
#define MODE 2

// noise and fbm function from https://www.shadertoy.com/view/Xd3GD4
//-----------------------------------------------------------------------------
vec2 hash( vec2 p ){
    p = vec2( dot(p,vec2(127.1,311.7)),
             dot(p,vec2(269.5,183.3)) );
    return -1.0 + 2.0*fract(sin(p)*43758.5453123);
}
float noise2d( in vec2 p ){
    const float K1 = 0.366025404; // (sqrt(3)-1)/2;
    const float K2 = 0.211324865; // (3-sqrt(3))/6;
    
    vec2 i = floor( p + (p.x+p.y)*K1 );
    
    vec2 a = p - i + (i.x+i.y)*K2;
    vec2 o = (a.x>a.y) ? vec2(1.0,0.0) : vec2(0.0,1.0);
    vec2 b = a - o + K2;
    vec2 c = a - 1.0 + 2.0*K2;
    
    vec3 h = max( 0.5-vec3(dot(a,a), dot(b,b), dot(c,c) ), 0.0 );
    
    vec3 n = h*h*h*h*vec3( dot(a,hash(i+0.0)), dot(b,hash(i+o)), dot(c,hash(i+1.0)));
    
    return dot( n, vec3(70.0) );
}
float fbm(vec2 uv){
    float f;
    mat2 m = mat2( 1.6,  1.2, -1.2,  1.6 );
    f  = 0.5000*noise2d( uv ); uv = m*uv;
    f += 0.2500*noise2d( uv ); uv = m*uv;
    f += 0.1250*noise2d( uv ); uv = m*uv;
    f += 0.0625*noise2d( uv ); uv = m*uv;
    f = 0.5 + 0.5*f;
    return f;
}

mat2 bend(float p, float k) {
    float c = cos(k*p);
    float s = sin(k*p);
    mat2  m = mat2(c,-s,s,c);
    return m;
}

// https://iquilezles.org/articles/distfunctions2d
float sdBox( in vec2 p, in vec2 b )
{
    vec2 d = abs(p)-b;
    return length(max(d,0.0)) + min(max(d.x,d.y),0.0);
}

// https://iquilezles.org/articles/distfunctions2d
float sdRoundedBox( in vec2 p, in vec2 b, in vec4 r )
{
    r.xy = (p.x>0.0)?r.xy : r.zw;
    r.x  = (p.y>0.0)?r.x  : r.y;
    vec2 q = abs(p)-b+r.x;
    return min(max(q.x,q.y),0.0) + length(max(q,0.0)) - r.x;
}

vec3 outsole(vec2 p, vec3 col, vec3 bcol) {
    vec2 pref = p;
    float d = sdBox(p,vec2(0.7,0.03))-0.02;
    float shadow = sdBox(p-vec2(0.0,0.01),vec2(0.7,0.03))-0.02;
    col = mix(col,SHDOW_COL,S(shadow,-0.02));
    col = mix(col,bcol,S(d,0.0));
    
    p.x = mod(p.x,0.01)-0.005;
    float d2 = sdBox(p+vec2(0.0,0.01),vec2(0.0005,0.03));
    p = pref;
    
    d2 = max((p.x+0.3),d2);
    d2 = max(-(p.x+0.71),d2);
    
    float mask = dot(p,vec2(0.15,0.1))+0.07;
    d2 = max(mask,d2);
    
    col = mix(col,vec3(0.9),S(d2,0.0));
    
    float n = fbm(p*50.0+20.0)*1.5;
    d = sdBox((p+vec2(-0.1,0.01))*n*1.7,vec2(0.6,0.03));
    mask = dot(p,vec2(0.15,0.1))+0.066;
    d = max(-mask,d);
    d = max(p.x-0.7,d);
    d = max(-p.y-0.05,d);
    col = mix(col,vec3(0.9),S(d,0.0));
    
    // stitch
    d = sdBox(p-vec2(0.0,0.035),vec2(0.7,0.001));
    mask = smoothstep(0.04,0.05,mod(p.x,0.1)-0.05);
    d = max(mask,d);
    col = mix(col,vec3(0.9),S(d,0.0));
    
    return col;
}

float lateralSideBase(vec2 p) {
    vec2 pref = p;
    float d = sdBox(p,vec2(0.5,0.15));
    p*=Rot(radians(-3.0));
    
    float blend = smoothstep(-1.0,0.00,p.x)*(1.0-smoothstep(0.00,1.0,p.x));
    p.y *= mix(2.11,0.73,blend);
    float d2 = sdBox((p-vec2(0.0,0.11)),vec2(0.52,0.15));
    p = pref;
    p.y*=1.08;
    float d3 = length(p-vec2(-0.445,-0.02))-0.2;
    d = min(d,d2);
    d = min(d3,d);
    d = max(-p.y,d);
    return d;
}

vec3 shoelaceGuard(vec2 p, vec3 col, vec3 bcol) {
    float mask = dot(p,vec2(-0.03,0.08))-0.023;
    float d = lateralSideBase(p);
    d = max(-mask*2.5,d);
    col = mix(col,bcol,S(d,0.0));
    return col;
}

vec3 lateralSide(vec2 p, vec3 col, vec3 bcol, vec3 bcol2, vec3 bcol3) {
    vec2 pref = p;
    p.x*=0.99;
    p.y*=0.93;
    float d = lateralSideBase(p-vec2(0.0,0.002)); // shadow
    col = mix(col,SHDOW_COL,S(d,-0.01));
    p = pref;
    p.y*=0.95;
    d = lateralSideBase(p);
    col = mix(col,bcol,S(d,0.0));
    col = shoelaceGuard(p-vec2(0.0,-0.005),col,SHDOW_COL); // shadow
    col = shoelaceGuard(p,col,bcol2);
    
    // shoelace hole
    d = length(p-vec2(-0.05,0.315))-0.015;
    col = mix(col,bcol3,S(d,0.0));
    
    return col;
}
    
vec3 toeCap(vec2 p, vec3 col, vec3 bcol) {
    vec2 pref = p;
    float blend = smoothstep(-1.0,0.15,p.x)*(1.0-smoothstep(0.15,1.0,p.x));
    p.y *= mix(5.0,0.8,blend);
    float d = sdRoundedBox(p,vec2(0.2,0.1),vec4(0.0,0.0,0.1,0.0));
    d = max(-p.y-0.03,d);
    col = mix(col,bcol,S(d,0.0));
    return col;
}

float heelCounterbase(vec2 p) {
    mat2  m = bend(p.y,0.6);
    p = m*p.xy;
    p.x*=0.95;
    
    vec2 pref = p;
    float d =  sdBox(p,vec2(0.1,0.2))-0.03;
    p.y*=0.5;
    float mask = length(p-vec2(-0.07,0.222))-0.2;
    d = max(-mask,d);
    p = pref;
    p*=Rot(radians(-20.0));
    p.x*=1.7;
    p.y*=0.75;
    mask = length((p-vec2(-0.14,-0.05)))-0.2;
    d = max(-mask,d);
    
    p = pref;
    p*=Rot(radians(8.0));
    p.x*=1.7;
    d = max((length((p-vec2(0.14,0.027)))-0.21),d);
    
    return d;
}

vec3 heelCounter(vec2 p, vec3 col, vec3 bcol, vec3 bcol2) {
    vec2 pref = p;
    float d =  heelCounterbase (p+vec2(0.01,0.005)); // shadow
    col = mix(col,SHDOW_COL,S(d,-0.01));
    d =  heelCounterbase (p);
    col = mix(col,bcol2,S(d,0.0));
    d =  heelCounterbase (p);
    float d2 =  sdBox((p-vec2(0.138,0.12))*Rot(radians(-12.0)),vec2(0.002,0.06))-0.017;
    d = max(-d2,d);
    col = mix(col,SHDOW_COL,S(d,-0.01));
    d2 =  sdBox((p-vec2(0.13,0.12))*Rot(radians(-12.0)),vec2(0.002,0.06))-0.017;
    d = max(-d2,d);
    col = mix(col,bcol,S(d,0.0));
    return col;
}

vec3 shoetongue(vec2 p, vec3 col, vec3 bcol, vec3 bcol2) {
    float d = sdBox(p*Rot(radians(-24.5)),vec2(0.38,0.05))-0.05;
    col = mix(col,bcol,S(d,0.0));
    d =  sdBox((p-vec2(0.231,0.202))*Rot(radians(-25.0)),vec2(0.1,0.001))-0.008;
    col = mix(col,SHDOW_COL,S(d,-0.005));
	d =  sdBox((p-vec2(0.23,0.21))*Rot(radians(-25.0)),vec2(0.1,0.001))-0.008;
    col = mix(col,bcol2,S(d,0.0));
    return col;
}

float shoelaseBase(vec2 p) {
    vec2 pref = p;
    float deg = 66.0;
    p*=Rot(radians(deg));
    p.y = mod(p.y,0.09)-0.045;
    float d = sdBox(p*Rot(radians(-10.0)),vec2(0.022,0.002))-0.013;
    p = pref;
    p*=Rot(radians(deg));
    d = max(-p.y-0.45,d);
    d = max(p.y-0.08,d);
    return d;
}

float shoelaseHole(vec2 p) {
    vec2 pref = p;
    float deg = 66.0;
    p*=Rot(radians(deg));
    p.y = mod(p.y,0.09)-0.045;
    float d = length(p)-0.02;
    p = pref;
    p*=Rot(radians(deg));
    d = max(-p.y-0.45,d);
    d = max(p.y-0.08,d);
    return d;
}

vec3 shoelace(vec2 p, vec3 col, vec3 bcol) {
    vec2 pref = p;
    
    float sh = shoelaseHole(p-vec2(0.011,-0.02));
    col = mix(col,vec3(0.0),S(sh,0.0));
    
    float d = shoelaseBase(p-vec2(-0.003,-0.007)); // shadow
    col = mix(col,SHDOW_COL,S(d,-0.005));
    d = shoelaseBase(p);
    col = mix(col,bcol,S(d,0.0));
    return col;
}

float stripeBase(vec2 p) {
    vec2 pref = p;
    
    p.x*=0.7;
    float d = length(p-vec2(0.0,0.0))-0.14;
    float d2 = length(p-vec2(0.22,-0.1))-0.22;
    
    d = max(-p.y-0.02,max(-d2,d ));
    p = pref;
    
    mat2  m = bend(p.y,-0.6);
    p = m*p.xy;
    
    float sc = mix(0.07,2.5,smoothstep(-1.0,1.0,p.x));
    p.y*=sc;
    float d3 = sdBox((p-vec2(0.3,0.24))*Rot(radians(-19.0)), vec2(0.335,0.041));
    d = min(d,d3);
    
    return d;
}

vec3 stripe(vec2 p, vec3 col, vec3 bcol){
    vec2 pref = p;
    mat2  m = bend(p.y,0.7);
    p = m*p.xy;
    p*=0.87;
    float d = stripeBase(p-vec2(0.005,-0.015)); // shadow
    col = mix(col,SHDOW_COL,S(d,-0.02));
    
    p = pref;
    p = m*p.xy;
    d = stripeBase(p);
    col = mix(col,bcol,S(d,0.0));
    return col;
}

float stitchBase(vec2 p, float size) {
    float d = sdBox(p,vec2(size,0.0001))*1.3;
    float mask = smoothstep(0.01,0.03,mod(p.x,0.03)-0.015);
    d = max(mask,d);
    return d;
}

vec3 stitch(vec2 p, vec3 col, vec3 bcol, vec3 bcol2, vec3 bcol3) {
    vec2 pref = p;
    float d = stitchBase((p-vec2(0.2,-0.03))*Rot(radians(40.0)), 0.07);
    col = mix(col,bcol,S(d,0.0));
    d = stitchBase((p-vec2(0.27,-0.19))*Rot(radians(100.0)), 0.06);
    col = mix(col,bcol,S(d,0.0));
    d = stitchBase((p-vec2(-0.07,-0.045))*Rot(radians(-21.6)), 0.38);
    col = mix(col,bcol,S(d,0.0));
    
    d = stitchBase((p-vec2(-0.37,-0.22))*Rot(radians(105.0)), 0.04);
    col = mix(col,bcol,S(d,0.0));
    
    d = stitchBase((p-vec2(-0.43,-0.22))*Rot(radians(105.0)), 0.03);
    col = mix(col,bcol,S(d,0.0));
    
    // stitch for stripe
    mat2  m = bend(p.y,0.7);
    p = m*p.xy;
    d = stitchBase((p-vec2(0.32,-0.063))*Rot(radians(-9.0)), 0.28);
    col = mix(col,bcol2,S(d,0.0));
    p = pref;
    
    m = bend(p.y,-2.8);
    p = m*p.xy;
    d = stitchBase((p-vec2(-0.15,-0.092))*Rot(radians(9.0)), 0.146);
    col = mix(col,bcol2,S(d,0.0));
    p = pref;
    
    m = bend(p.y,0.7);
    p = m*p.xy;
    d = stitchBase((p-vec2(0.38,-0.076))*Rot(radians(-11.0)), 0.23);
    col = mix(col,bcol2,S(d,0.0));
    p = pref;
    
    m = bend(p.y,-2.0);
    p = m*p.xy;
    d = stitchBase((p-vec2(0.0,-0.193))*Rot(radians(-15.0)), 0.1);
    col = mix(col,bcol2,S(d,0.0));
    p = pref;
    
    // stitch for heelcounter
    p = pref;
    m = bend(p.y,1.0);
    p = m*p.xy;
    d = stitchBase((p-vec2(0.67,-0.04))*Rot(radians(32.0)), 0.07);
    col = mix(col,bcol3,S(d,0.0));
    return col;
}

vec3 floorShadow(vec2 p, vec3 col, float size) {
    p.y*=30.0;
    float d = length(p)-size;
    col = mix(col,vec3(0.3),S(d,-0.4));
    return col;
}

vec3 stripeMaterial(vec2 p, vec3 col) {
    vec2 pref = p;
    float sc = 6.0;
    p*=sc;
    float size = 0.01;
    p.x = mod(p.x,0.2)-0.1;
    p.y = mod(p.y,0.14)-0.07;
    float d =  sdBox(p,vec2(size))-0.03;
    col = mix(col,col*1.2,S(d,0.0));
    p = pref;
    p*=sc;
    p.x+=0.1;
    p.y+=0.07;
	p.x = mod(p.x,0.2)-0.1;
    p.y = mod(p.y,0.14)-0.07;
    d =  sdBox(p,vec2(size))-0.03;
    col = mix(col,col*1.2,S(d,0.0));
    return col;
}

vec3 lateralsideMaterial(vec2 p, vec3 col, vec3 col2) {
    p*= 2.5;
    p.x-=iTime*0.1;
    float size = 0.096;
    float mrg = 4.0;
    p.x = mod(p.x,size*mrg)-((size*mrg)*0.5);
    p.y = mod(p.y,size*mrg)-((size*mrg)*0.5);
    float d = sdBox(p,vec2(0.1));
    col = mix(col,col2,S(d,-0.01));
    p.x = mod(p.x,size*mrg)-((size*mrg)*0.5);
    p.y = mod(p.y,size*mrg)-((size*mrg)*0.5);
    d = sdBox(p,vec2(0.1));
    col = mix(col,col2,S(d,-0.01));
    return col;
}

float charJ(vec2 p) {
    float d = sdBox(p-vec2(0.02,0.0),vec2(0.02,0.1));
    float d2 = sdBox(p-vec2(-0.04,-0.06),vec2(0.04,0.04));
    d = min(d,d2);
    d2 = sdBox(p-vec2(-0.02,-0.01),vec2(0.02,0.05));
    d = max(-d2,d);
    return d;
}
float charC(vec2 p) {
    float d = sdBox(p,vec2(0.06,0.1));
    float d2 = sdBox(p-vec2(0.03,0.00),vec2(0.05,0.06));
    d = max(-d2,d);
    return d;
}
float charL(vec2 p) {
    float d = sdBox(p,vec2(0.06,0.1));
    float d2 = sdBox(p-vec2(0.03,0.03),vec2(0.05,0.09));
    d = max(-d2,d);
    return d;
}
float charY(vec2 p) {
    float d = sdBox(p-vec2(0.00,0.05),vec2(0.06,0.05));
    float d2 = sdBox(p-vec2(0.00,-0.05),vec2(0.02,0.05));
    d = min(d,d2);
    d2 = sdBox(p-vec2(0.00,0.08),vec2(0.02,0.05));
    d = max(-d2,d);
    return d;
}
float charD(vec2 p) {
    float d = sdBox(p-vec2(-0.025,0.00),vec2(0.045,0.1));
    float d2 = sdBox(p-vec2(0.02,0.00),vec2(0.05,0.06));
    d = max(-d2,d);
    d2 = sdBox(p-vec2(0.04,0.02),vec2(0.02,0.08));
    d = min(d,d2);
    return d;
}
float charE(vec2 p) {
    float d = sdBox(p,vec2(0.06,0.1));
    float d2 = sdBox(p-vec2(0.03,0.00),vec2(0.05,0.06));
    d = max(-d2,d);
    d2 = sdBox(p,vec2(0.04,0.02));
    d = min(d,d2);
    return d;
}
vec3 logo(vec2 p, float size, vec3 col, vec3 bcol) {
    p*=size;
    mat2  m = mat2(1.0,-0.4,0.0,1.0); // sknew
    p*=m;
    
    float j = charJ(p-vec2(-0.4,0.0));
    float dt = sdBox(p-vec2(-0.31,0.0),vec2(0.02));
    float c = charC(p-vec2(-0.2,0.0));
    float l = charL(p-vec2(-0.05,0.0));
    float y = charY(p-vec2(0.08,0.0));
    float d = charD(p-vec2(0.24,0.0));
    float e = charE(p-vec2(0.39,0.0));
    
    float res = min(j,min(dt,min(c,min(l,min(y,min(d,e))))));
    col = mix(col,bcol,S(res,-0.01));
    return col;
}

vec3 pumaClyde(vec2 p, vec3 col) {
    float n = noise2d(p*20.0+200.0);
    
    vec3 wh = vec3(251.0/255.0,251.0/255.0,235.0/255.0);
    
    vec3 toeandtongueCol = vec3(n)*0.2;
    col = shoetongue(p-vec2(-0.05,-0.055),col,toeandtongueCol,wh*0.9);
    col = toeCap(p-vec2(-0.51,-0.235),col,toeandtongueCol);
    
    vec3 shoelaceGuardCol = (vec3(17.0/255.0,74.0/255.0,159.0/255.0)*0.95)-vec3(n)*0.03;
    vec3 lateralBaseCol = vec3(17.0/255.0,74.0/255.0,159.0/255.0)-vec3(n)*0.03;
    lateralBaseCol = lateralsideMaterial(p,vec3(17.0/255.0,74.0/255.0,159.0/255.0),wh)-vec3(n)*0.1;
    vec3 shoelaceHoleCol = vec3(0.0);
    col = lateralSide(p-vec2(0.19,-0.25),col,lateralBaseCol,shoelaceGuardCol,shoelaceHoleCol);
    
    vec3 stripeBaseCol = stripeMaterial(p,vec3(252.0/255.0,120.0/255.0,6.0/255.0));
    col = stripe(p-vec2(0.0,-0.24),col,stripeBaseCol);
    
    vec3 heelBaseCol = vec3(n)*0.2;
    vec3 heelPatchCol = vec3(252.0/255.0,120.0/255.0,6.0/255.0);
    col = heelCounter(p-vec2(0.592,-0.07),col,heelBaseCol,heelPatchCol);
    
    col = logo((p-vec2(0.2,0.0))*Rot(radians(-22.0)),4.0,col, vec3(1.0,0.843,0.0));
    
    vec3 stitchCol = vec3(0.0);
    vec3 stitchCol2 = vec3(0.0);
    vec3 stitchCol3 = vec3(0.4);
    col = stitch(p, col,stitchCol,stitchCol2,stitchCol3);
    
    vec3 outBaseCol = wh;
    col = outsole(p-vec2(0.0,-0.3),col,outBaseCol);
    
    vec3 shoelaceCol = vec3(17.0/255.0,74.0/255.0,159.0/255.0)*1.5;
    col = shoelace(p-vec2(0.0,0.055),col,shoelaceCol);
    
    return col;
}

vec3 background(vec2 p, float t) {
    float d = -p.y-0.4;
    vec3 col = mix(vec3(0.7),vec3(0.65),S(d,0.0));
    
    vec3 wh = vec3(251.0/255.0,251.0/255.0,235.0/255.0);
    vec3 mat = lateralsideMaterial(p,vec3(17.0/255.0,74.0/255.0,159.0/255.0),wh)*0.5;
    float n = fbm(p*(10.0)+20.0)*1.3;
    d = length((p-vec2(-0.4,0.0))*n)-0.1;
    col = mix(col,mat,S(d,0.0));
    n = fbm(p*5.0+10.0)*1.5;
    d = length((p-vec2(0.5,0.2))*n)-0.1;
    col = mix(col,mat,S(d,0.0));
    
    p.x-=t;
    p.x = mod(p.x,0.5)-0.25;
    col = logo(p-vec2(0.0,-0.3),2.2,col, vec3(0.6));
    
    return col;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    float t = iTime*0.1;
    vec2 p = (fragCoord-.5*iResolution.xy)/iResolution.y;
    vec2 pref = p;
    vec3 col = background(p,t);
    
    vec3 logomat = stripeMaterial(p,vec3(252.0/255.0,120.0/255.0,6.0/255.0));
    col = logo(p-vec2(-0.395,0.395),1.8,col, vec3(0.5));
    col = logo(p-vec2(-0.4,0.4),1.8,col, logomat);
    
    p*=1.2;
    #if MODE == 2
    p.x+=t;
    p.x = mod(p.x,5.4)-2.7;
	p.x = abs(p.x);
    p.x*=-1.0;
    p.x+=1.8;
    col = pumaClyde((p-vec2(-0.05,0.1))*Rot(radians(-15.0)),col);
    p = pref;
    p*=1.2;
    p.x+=t;
    p.x = mod(p.x,5.4)-2.7;
    col = pumaClyde(p-vec2(0.0,-0.1),col);
    col = floorShadow(p-vec2(0.0,-0.55),col,0.6);
    #elif  MODE == 1
    col = pumaClyde((p-vec2(-0.05,0.1))*Rot(radians(-15.0)),col);
    #elif  MODE == 0
    col = pumaClyde(p,col);
    #endif
    
    p = pref;
    
    p*=1.2;
    #if MODE == 2
    p.x+=t;
    p.x = mod(p.x,5.4)-2.7;
    p.x = abs(p.x);
    p.x*=-1.0;
    p.x+=1.9;
    col = floorShadow(p-vec2(-0.55,-0.55),col,0.3);
    #elif  MODE == 1
    col = floorShadow(p-vec2(-0.65,-0.55),col,0.3);
    #elif  MODE == 0
    col = floorShadow(p-vec2(0.0,-0.55),col,0.6);
    #endif
    
    fragColor = vec4(col,1.0);
}