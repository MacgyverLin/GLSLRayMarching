//#define AA 3
#define AO
//#define GIF

// voronoi - adapted from iq https://www.shadertoy.com/view/ldl3W8

vec2 hash2( vec2 p )
{
    return fract(sin(vec2(dot(p,vec2(127.1,311.7)),dot(p,vec2(269.5,183.3))))*43758.5453);
}

float voronoi( in vec2 x )
{
    vec2 cell = floor(x);

    float d = 1e12;
    for( int j=-1; j<=1; j++ )
    for( int i=-1; i<=1; i++ )
    {
        vec2 offset = vec2(float(i),float(j));
        vec2 pos = hash2( cell + offset );
        vec2 r = cell + offset + pos;
        d = min(d, length(x - r));
    }

    return d;
}

// HG_SDF 

const float PI  = 3.14159265359;
const float PHI = 1.61803398875;

void pR(inout vec2 p, float a) {
    p = cos(a)*p + sin(a)*vec2(p.y, -p.x);
}

float smin(float a, float b, float k){
    float f = clamp(0.5 + 0.5 * ((a - b) / k), 0., 1.);
    return (1. - f) * a + f  * b - f * (1. - f) * k;
}

float smax(float a, float b, float k) {
    return -smin(-a, -b, k);
}

float range(float vmin, float vmax, float value) {
  return (value - vmin) / (vmax - vmin);
}

float rangec(float a, float b, float t) {
    return clamp(range(a, b, t), 0., 1.);
}


// Modelling

float time;
bool lightingPass;
mat3 modelMat;

struct Model {
	float d;
    vec3 p;
    vec2 uv;
    vec2 cell;
    float wedges;
    float slice;
    float len;
};

Model leaf(vec3 p, vec3 cellData) {
    //cellData = vec3(0,0,.1);
    
    vec2 cell = cellData.xy;
    float cellTime = cellData.z;
    
    //cell.x = 0.;
    //cell.y = .1;
    //cellTime = .2;

    float d = 1e12;
    float d2 = 1e12;
    float slice = 1e12;
    float wedge, wedges;

    // orient
    pR(p.xz, -cell.x);
    pR(p.zy, cell.y);

    vec3 pp = p;

    cellTime = max(cellTime, 0.);

    float core = length(p) - .1;

    float len = max(cellTime*3. - .2, 0.);
    len = pow(len, .33);
    float llen = len;


    if (cellTime > 0.) {

        // wedge
        float ins = .25;
        p.z += ins;
        vec3 n = normalize(vec3(1,0,.35));
        wedge = -dot(p, n);
        wedge = max(wedge, dot(p, n * vec3(1,1,-1)));
        wedge = smax(wedge, p.z - len*1.12 - ins, len);
        p.z -= ins;

        // wedge2
        ins = .2;
        p.z += ins;
        n = normalize(vec3(1,0,.4));
        float wedge2 = -dot(p, n);
        wedge2 = max(wedge2, dot(p, n * vec3(1,1,-1)));
        wedge2 = smax(wedge2, p.z - len*.95 - ins, len*.6);
        p.z -= ins;

        float r = len / 8.;

        float top = p.y - len * .5;
        float curve = smoothstep(0., .2, cellTime);

        len *= mix(1.5, .65, curve);
        pR(p.zy, -mix(.2, .7, curve));
        slice = length(p - vec3(0,len,0)) - len;
        d2 = abs(slice) - .05;
        d2 = max(d2, top);
        
        float d3 = smax(d2, wedge, .05);
        float d4 = smax(d2, wedge2, .05);
        wedges = smin(wedge, wedge2, .01);
        d3 = smin(d3, d4, .01);
        d = d3;
        
        p = pp;
        len = llen;
        vec2 uv = p.xz / len;
        return Model(d, p, uv, cell, wedges, slice, len);
    }

	return Model(d, p, vec2(0), vec2(0), 0., 0., 0.);
}

vec3 calcAlbedo(Model model) {    
    vec3 col = vec3(.15,.15,.4);

	vec3 p = model.p;
    float len = model.len;
    vec2 cell = model.cell;
    float wedges = model.wedges;
    float slice = model.slice;
    vec2 uv = model.uv;
    
    float v = voronoi((uv+4.)*30.);
    float v2 = voronoi((uv+4.)*4.+cell.x);

    col = mix(col, vec3(.125,.2,.4), 1.-v2);
    float tip = length(p - vec3(0,.2,len*.9));

    tip = smoothstep(.5, .0, tip);
    tip *= smoothstep(.07, .0, abs(slice+.01));
    tip *= smoothstep(-.2, .0, wedges);
    tip = pow(tip, 1.5);
    col = mix(col, vec3(1,.2,.5), tip);

    float vs = 1.-uv.y*1.;
    vs *= smoothstep(.0, -.1, wedges);
    vs *= smoothstep(.0, .05, abs(slice));
    v = smoothstep(vs + .1, vs - .5, v*1.5);
    col = mix(col, vec3(.05,.05,.2), v*v2);

    col *= mix(vec3(1), vec3(.5,5.,1.8), smoothstep(.2, 1.8, cell.y) * .75);
  
    return col;
}

vec3 calcCellData(
    vec2 cell,
    vec2 offset,
    float maxBloomOffset,
    mat2 transform,
    mat2 transformI,
    float stretch,
    float stretchStart,
    float stretchEnd,
    float t
) {

    float sz = maxBloomOffset + PI / 2.;

    cell = transform * cell;

    // Snap to cell center
    cell = round(cell);
    cell += offset;

    // Hide leaves outside the growth area
    cell = transformI * cell;
    cell.y *= stretch / sz / stretchStart;
    cell.y = max(cell.y, .5/stretchStart); // clamp, not sure why this magic number
    cell.y /= stretch / sz / stretchStart;
    cell = transform * cell;

    // Snap after clamp
    cell = round(cell);

    cell = transformI * cell;

    // calculate cell time
    float y = cell.y * (stretch / sz);
    float cellAppearTime = (stretchStart - y) / (stretchStart - stretchEnd);
    float cellTime = t - cellAppearTime;

    cell.y -= maxBloomOffset;

    return vec3(cell, cellTime);
}

Model opU(Model a, Model b) {
    if (a.d < b.d) {
    	return a;
    } else {
    	return b;
    }
}

mat2 phyllotaxis;
void calcPhyllotaxis() {
    vec2 cc = vec2(5., 8.);
    float aa = atan(cc.x / cc.y);
    float scale = (PI*2.) / sqrt(cc.x*cc.x + cc.y*cc.y);
    mat2 mRot = mat2(cos(aa), -sin(aa), sin(aa), cos(aa));
    mat2 mScale = mat2(1./scale,0,0,1./scale);
	phyllotaxis = mRot * mScale;
}

Model bloom(vec3 p, float t) {

    p.y -= .05;

    vec2 move = vec2(0, t);
    float stretchStart = .25;
    float stretchEnd = 1.;
    float stretch = mix(stretchStart, stretchEnd, t);
    float maxBloomOffset = PI / 2.;

    vec2 cell = vec2(
        atan(p.x, p.z),
        atan(p.y, length(p.xz)) + maxBloomOffset
    );

    mat2 mStretch = mat2(1,0,0,stretch);
    mat2 transform = phyllotaxis * mStretch;
    mat2 transformI = inverse(transform);

	Model res = Model(1e12, p, vec2(0), vec2(0), 0., 0., 0.);
    //res.d = length(p) - 1.; return res;

    // compile speed optim from IQ
    for( int m=min(iFrame,0); m<3; m++ )
    for( int n=min(iFrame,0); n<3; n++ )
    {
    	res = opU(res, leaf(p, calcCellData(cell, vec2(m, n) - 1., maxBloomOffset, transform, transformI, stretch, stretchStart, stretchEnd, t)));
    }

    return res;
}

Model map(vec3 p) {
    p *= modelMat;
    float t;
    
    float bound = length(p) - 1.3;
    if (bound > .01 && ! lightingPass) {
		return Model(bound, p, vec2(0), vec2(0), 0., 0., 0.);
    }

    pR(p.xy, time * -PI);

    vec3 pp = p;
    
    float side = sign(p.y);
    p.y = abs(p.y);
	p.z *= side;

    t = time + .5 * side;
    t = sin(t * PI - PI/2.) * .5 + .5;
    pR(p.xz, time * PI);
    Model model = bloom(p, t);
    
    if (abs(p.y) < .34) {
        p = pp;
    	side *= -1.;
        p.yz *= side;
        t = time + .5 * side;
    	t = sin(t * PI - PI/2.) * .5 + .5;
        pR(p.xz, time * PI);
        Model model2 = bloom(p, t);
        model = opU(model, model2);
    }

    return model;
}

// compile speed optim from IQ https://www.shadertoy.com/view/Xds3zN
vec3 calcNormal(vec3 pos){
    vec3 n = vec3(0.0);
    for( int i=0; i<4; i++ )
    {
        vec3 e = 0.5773*(2.0*vec3((((i+3)>>1)&1),((i>>1)&1),(i&1))-1.0);
        n += e*map(pos+0.0005*e).d;
    }
    return normalize(n);
}

// https://www.shadertoy.com/view/3dyXzD
vec3 randDir( vec3 n, vec2 seed ) {
    vec3  uu = normalize( cross( n, vec3(0.0,1.0,1.0) ) );
    vec3  vv = cross( uu, n );
    
    float ra = sqrt(seed.y);
    float rx = ra*cos(6.2831*seed.x); 
    float ry = ra*sin(6.2831*seed.x);
    float rz = sqrt( 1.0-seed.y );
    vec3  rr = vec3( rx*uu + ry*vv + rz*n );

    return normalize( rr );
}

float hitLength(vec3 pos, vec3 dir, float maxDist) {
    float len = 0.;
    const int steps = 15;
    float dist = maxDist / float(steps);
    vec3 rayPos;
    for (int i = 0; i < steps; i++) {
        len += dist;
        dist = map(pos + dir * len).d;
        if (abs(dist) < .001) {
            break;
        }
        if (len > maxDist) {
            len = maxDist;
            break;
        }
    }
    return len / maxDist;
}

float calcAO(vec3 pos, vec3 nor, vec2 seed, float maxDist) {
    float len = 0.;
    const float SAMPLES = 3.;
    for (float x = 0.; x < SAMPLES; x++)
    for (float y = 0.; y < SAMPLES; y++)
    {
        vec2 s = seed + vec2(x, y) / SAMPLES;
        s = hash2(s);
        vec3 dir = randDir(nor, s);
        len += hitLength(pos, dir, maxDist);
    }

    len /= SAMPLES * SAMPLES;
    return len;
}

mat3 calcLookAtMatrix( in vec3 ro, in vec3 ta, in float roll )
{
    vec3 ww = normalize( ta - ro );
    vec3 uu = normalize( cross(ww,vec3(sin(roll),cos(roll),0.0) ) );
    vec3 vv = normalize( cross(uu,ww));
    return mat3( uu, vv, ww );
}

mat3 rotX(float a) {
    return mat3(1,0,0, 0,cos(a),-sin(a), 0,sin(a),cos(a));
}

mat3 rotY(float a) {
    return mat3(cos(a),0,sin(a), 0,1,0, -sin(a),0,cos(a));
}

mat3 rotZ(float a) {
    return mat3(cos(a),-sin(a),0, sin(a),cos(a),0, 0,0,1);
}

float pat(vec2 uv) {
    vec2 p = vec2(atan(uv.x/uv.y), log(length(uv)));
   
   	p *= phyllotaxis;
    p = p * 4.;
    
    p -= vec2(0,8) * time;

    p = mod(p, 1.);
    float d = length(p - .5) - .1;
    float fw = fwidth(d);

    d = abs(d) - .01;
    d /= fw;
    d = clamp(d, 0., 1.);
    
    return d;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {

    vec3 col;
    vec3 tot = vec3(0.0);

    float mTime = mod(iTime / 4., 1.) + .35;
    time = mTime;
    
    calcPhyllotaxis();
    modelMat = rotZ(-.9) * rotX(.05) * rotY(-1.1);

    vec2 o = vec2(0);

    #ifdef AA
    for( int m=0; m<AA; m++ )
    for( int n=0; n<AA; n++ )
    {
    // pixel coordinates
    o = vec2(float(m),float(n)) / float(AA) - 0.5;
    // time coordinate (motion blurred, shutter=0.5)
    float d = 0.5*sin(fragCoord.x*147.0)*sin(fragCoord.y*131.0);
    time = mTime - 0.1*(1.0/24.0)*(float(m*AA+n)+d)/float(AA*AA-1);
    #endif

        vec2 p = (-iResolution.xy + 2.0*(fragCoord+o))/iResolution.y;

        vec3 camPos = vec3(0,0,-2.6);
        #ifdef GIF
        	camPos.z = -2.8;
       	#endif
        mat3 camMat = calcLookAtMatrix( camPos, vec3(0,-.05,0), 0.);
        vec3 rayDirection = normalize( camMat * vec3(p.xy,1.8) );

        vec3 rayPosition = camPos;
        float rayLength = 0.;
        float dist = 0.;
        bool bg = false;
        Model model;

        lightingPass = false;
        
        for (int i = 0; i < 300; i++) {
            rayLength += dist;
            rayPosition = camPos + rayDirection * rayLength;
            model = map(rayPosition);
            dist = model.d;

            if (abs(dist) < .001) {
                break;
            }
            
            if (rayLength > 5.) {
                bg = true;
                break;
            }
        }
        
        lightingPass = true;
        
        col = vec3(.4,.4,1);
        #ifndef GIF
        	col = mix(col, vec3(.0,1.5,1.5)*1.5, (1.-pat(p))*.5);
        	col = mix(col, vec3(.63,.7,1), smoothstep(2.5, .5, length(p)));
        #else
        	col = mix(col, vec3(.63,.7,1), .95);
        #endif
        col *= vec3(.9,1.,1.);
        col += .1;
        
        //bg = true;
        
        if ( ! bg) {

            vec3 pos = rayPosition;
            vec3 rd = rayDirection;
            vec2 seed = hash2(p + time);
            
            #ifndef AA
            	seed *= .0000001;
            #endif
            
            vec3  nor = calcNormal(pos);
            
            float occ = 1.;
            #ifdef AO
            	occ = calcAO(pos, nor, seed, .85);
            	occ = clamp(pow(occ*1.25, 1.5), 0., 1.);
            #endif
            float amb = sqrt(clamp( 0.5+0.5*nor.y, 0.0, 1.0 ));
            float fre = pow( clamp(1.0+dot(nor,rd),0.0,1.0), 2.0 );

            vec3 lin = vec3(0);
            lin += 1.70 * amb * vec3(1.30,1.00,0.70) * occ;
            lin += 0.90 * amb * vec3(0.30,0.80,1.30);
            lin += 1.00 * fre * vec3(1.00,1.00,1.00) * occ;


            vec3 albedo = calcAlbedo(model);
            col = albedo * lin;
            
            //col *= mix(vec3(1), vec3(.0,.5,.7)*.5, 1.-occ);

        }

        tot += col;
    #ifdef AA
    }
    tot /= float(AA*AA);
    #endif

    col = tot;
    col = pow( col, vec3(0.4545) );
    fragColor = vec4(col,1.0);
}
