#define V 3

const float PI = 3.14159265;

// Adds pikachu to the image
vec3 addPikachu(vec2 uv, vec3 bg) {
    float screenRatio = iResolution.x / iResolution.y;
    const vec2 picDim = vec2(128.0, 120.0);
    const float bTop = 0.5;
    float bLeft = 0.55 - 0.5 * bTop * picDim.x / (picDim.y * screenRatio);
    float bRight = 0.55 + 0.5 * bTop * picDim.x / (picDim.y * screenRatio);
    if(uv.x < bLeft || uv.x > bRight || uv.y > bTop)
        return bg;

    int idx_x = int(picDim.x * (uv.x - bLeft) / (bRight - bLeft));
    int idx_y = int(picDim.y * (bTop - uv.y) / bTop);

    return pikachuText(idx_x, idx_y, bg);
}

// Finds a vector normal to the given vector
vec2 vnorm(in vec2 v) {
    return vec2(v.y, -v.x);
}

// Moves the points according to time and the id of the line
vec2 getOffset(vec2 pos, vec2 posParent, vec2 offsetParent, int i) {
    float rMag = i < 5 ? 0.1 : 0.04;
    float lMag = i < 5 ? 0.04 : 0.01;
    float period = 0.25 + 0.05 * mod(float(i), 3.0);
    float tShift = iTime - 1.3 * float(i);
    vec2 rOffset = rMag * 0.666 * floor(1.5*cos(7.0*float(i) + tShift / period)
                                        * vnorm(pos - posParent - offsetParent));
    vec2 lOffset = lMag * 0.666 * floor(1.5*cos(11.0*float(i) + tShift / period)
                                        * (pos - posParent - offsetParent));
    return offsetParent + rOffset + lOffset;
}

// Returns the lines that make the lightning
const int nbVertices = 25;
const int nbLines = nbVertices - 1;
vec4[nbLines] getLines() {
    const vec2[nbVertices] vertices = vec2[nbVertices] (
        vec2(0.5, 0.1), vec2(0.2, 0.3), vec2(0.32, 0.5),
        vec2(0.51, 0.55), vec2(0.75, 0.51), vec2(0.8, 0.2),
        vec2(-0.05, 0.15), vec2(-0.15, 0.35), vec2(0.1, 0.6),
        vec2(0.25, 0.7), vec2(-0.1, 0.5), vec2(-0.1, 0.8),
        vec2(0.17, 1.1), vec2(0.3, 1.1), vec2(0.45, 0.69),
        vec2(0.59, 0.83), vec2(0.48, 1.15), vec2(0.8, 1.15),
        vec2(0.79, 0.79), vec2(0.94, 1.2), vec2(1.03, 1.07),
        vec2(1.1, 0.63), vec2(0.93, 0.31), vec2(1.15, 0.1),
        vec2(1.1, 0.28)
    );
    const ivec2[nbLines] lines = ivec2[nbLines] (
        ivec2(0, 1), ivec2(0, 2), ivec2(0, 3), ivec2(0, 4),
        ivec2(0, 5), ivec2(1, 6), ivec2(1, 7), ivec2(2, 8),
        ivec2(2, 9), ivec2(8, 10), ivec2(8, 11), ivec2(9, 12),
        ivec2(9, 13), ivec2(3, 14), ivec2(3, 15), ivec2(14, 16),
        ivec2(15, 17), ivec2(4, 18), ivec2(18, 19), ivec2(18, 20),
        ivec2(4, 21), ivec2(5, 22), ivec2(5, 23), ivec2(22, 24)
    );
    vec2[nbVertices] offsets;
    offsets[0] = vec2(0.0, 0.0);
    for(int i = 0; i < nbLines; i++) {
        offsets[lines[i].y] = getOffset(vertices[lines[i].y],
                                        vertices[lines[i].x],
                                        offsets[lines[i].x], i);
    }
    vec4[nbLines] verticeLines;
    for(int i = 0; i < nbLines; i++) {
        verticeLines[i] = vec4(vertices[lines[i].x] + offsets[lines[i].x],
                               vertices[lines[i].y] + offsets[lines[i].y]);
    }
    return verticeLines;
}

// Returns the lines that make Pikachu
const int nbPkVertices = 5;
const int nbPkLines = 5;
vec4[nbPkLines] getPkLines() {
    const vec2[nbPkVertices] vertices = vec2[nbPkVertices] (
        vec2(0.43, 0.08), vec2(0.48, 0.3), vec2(0.54, 0.29),
        vec2(0.59, 0.18), vec2(0.59, 0.07)
    );
    const ivec2[nbPkLines] lines = ivec2[nbPkLines] (
        ivec2(0, 1), ivec2(1, 2), ivec2(2, 3), ivec2(3, 4), ivec2(4, 0)
    );
    vec4[nbPkLines] verticeLines;
    for(int i = 0; i < nbPkLines; i++) {
        verticeLines[i] = vec4(vertices[lines[i].x], vertices[lines[i].y]);
    }
    return verticeLines;
}

// From https://www.shadertoy.com/view/4sc3z2
// and https://www.shadertoy.com/view/XsX3zB
#define MOD3 vec3(.1031,.11369,.13787)
vec3 hash33(vec3 p3)
{
    p3 = fract(p3 * MOD3);
    p3 += dot(p3, p3.yxz+19.19);
    return -1.0 + 2.0 * fract(vec3((p3.x + p3.y)*p3.z, (p3.x+p3.z)*p3.y, (p3.y+p3.z)*p3.x));
}
float simplexNoise(vec3 p)
{
    const float K1 = 0.333333333;
    const float K2 = 0.166666667;
    
    vec3 i = floor(p + (p.x + p.y + p.z) * K1);
    vec3 d0 = p - (i - (i.x + i.y + i.z) * K2);
    
    vec3 e = step(vec3(0.0), d0 - d0.yzx);
    vec3 i1 = e * (1.0 - e.zxy);
    vec3 i2 = 1.0 - e.zxy * (1.0 - e);
    
    vec3 d1 = d0 - (i1 - 1.0 * K2);
    vec3 d2 = d0 - (i2 - 2.0 * K2);
    vec3 d3 = d0 - (1.0 - 3.0 * K2);
    
    vec4 h = max(0.6 - vec4(dot(d0, d0), dot(d1, d1), dot(d2, d2), dot(d3, d3)), 0.0);
    vec4 n = h * h * h * h * vec4(dot(d0, hash33(i)), dot(d1, hash33(i + i1)), dot(d2, hash33(i + i2)), dot(d3, hash33(i + 1.0)));
    
    return dot(vec4(31.316), n);
}

// Creates the background texture
vec3 backgroundDefault(vec2 uv) {
    return vec3(0.05, 0.4, 0.2) + vec3(0.0, -0.05, 0.1)*simplexNoise(vec3(4.0*uv, 1.0));
}

float dot2(in vec2 v)
{
    return dot(v, v);
}

// Distance between p and the line from a to b
float lineDist( in vec2 p, in vec2 a, in vec2 b )
{
    vec2 adjRatio = vec2(1.0, iResolution.y / iResolution.x);
    vec2 pp = vec2((p.x - 0.5) / (1.0 + 0.3 * p.y) + 0.5, p.y);
    vec2 pa = (pp-a)*adjRatio, ba = (b-a)*adjRatio;
    float h = clamp(dot(pa,ba)/dot(ba,ba),0.0,1.0);
    float sdist = dot2(pa-ba*h);
    return sdist;
}

// Break the line according to the value of i
// and return the minimum distance between p and
// one of the sub-lines between a and b
float lineMultiDist(in vec2 p, in vec2 a, in vec2 b, in int i)
{
    float offset1 = 0.4 + 0.05 * cos(5.0 * iTime + float(i+3));
    float offset2 = 0.7 + 0.05 * cos(5.0 * iTime + float(i+5));
    float shift1 = 0.02 + 0.04 * cos(5.0 * iTime + float(i));
    float shift2 = -0.02 + 0.04 * sin(5.0 * iTime + float(i));
    vec2[4] points = vec2[4] (
        a,
        mix(a, b, offset1) + shift1 * vnorm(b - a),
        mix(a, b, offset2) + shift2 * vnorm(b - a),
        b
    );
    float dm = 10.0;
    for(int i = 0; i < 3; i++) {
        dm = min(dm, lineDist(p, points[i], points[i+1]));
    }
    return dm;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = fragCoord/iResolution.xy;
    float noiseMicro = simplexNoise(vec3(20.0*uv, floor(iTime * 10.)));
    float noiseMacro = simplexNoise(vec3(5.0*uv, iTime));
    vec2 uv_o = uv + 0.007 * vec2(noiseMicro, noiseMicro) + 0.02 * vec2(noiseMacro, noiseMacro);

    // Background color
    vec3 col = backgroundDefault(uv);
    
    // Pikachu contour
    vec4[nbPkLines] pkLines = getPkLines();
    float di = 10.0;
    for(int i = 0; i < nbPkLines; i++) {
        di = min(di, lineDist(uv, pkLines[i].xy, pkLines[i].zw));
    }
    di /= (1.0 + 0.2 * cos(2.0*iTime) + 0.05 * cos(15.0*iTime));
    float ampl = 1.0 / (1.0 + 3.0 * length(uv - vec2(0.5, 0.1)));
    col = mix(col, vec3(1.0, 0.9, 0.5),0.8*(1.0-smoothstep(0.0,0.12,sqrt(di)*ampl)));
    ampl = 1.0 / (1.0 + 3.0 * length(uv - vec2(0.5, 0.1)));
    col = mix(col, vec3(1.0, 0.95, 0.4),0.8*(1.0-smoothstep(0.0,0.05,sqrt(di)*ampl)));
     

    // Thunderbolts
    vec4[nbLines] lines = getLines();
    const int[nbLines] groups = int[nbLines] (
        0,1,2,3,4,0,0,1,1,1,1,1,1,2,2,2,2,3,3,3,3,4,4,4
    );
    float[5] showgroup = float[5] (1.3*iTime, 1.1*iTime+0.5, 1.0*iTime+0.7, 1.4*iTime+0.3, 1.2*iTime+0.1);
    di = 10.0;
    int lum = 0;
    for(int i = 0; i < nbLines; i++) {
        if(fract(showgroup[groups[i]]) > 0.5) {
        	di = min(di, lineMultiDist(uv_o, lines[i].xy, lines[i].zw, i));
            lum++;
        }
    }
  
    if(fract(iTime * 7.) > 0.2)
    {
    col = mix(col, vec3(0.9, 0.9, 0.7), 0.7 * float(lum) / float(nbLines));

    ampl = 1.0 / (1.0 + 3.0 * length(uv - vec2(0.5, 0.1)));
    col = mix(col, vec3(1.0, 0.9, 0.4), 1.0-smoothstep(0.000002,0.00008,di*ampl));
    col = mix(col, vec3(1.0, 1.0, 0.7), 1.0-smoothstep(0.000002,0.00001,di*ampl));
    }

    // Adding pikachu
    col = addPikachu(uv, col);
      
    // Vignetting
    col *= pow( 20.0*uv.x*uv.y*(1.0-uv.x)*(1.0-uv.y), 0.07 );

    // Output to screen
    fragColor = vec4(col,1.0);
}
