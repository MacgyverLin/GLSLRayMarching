const float pi = acos(-1.);
const float pi2 = pi * 2.;
const float TWO_PI = pi * 2.;
const float PI = acos(-1.);

mat2 rot2D(float r)
{
    float c = cos(r), s = sin(r);
    return mat2(c, s, -s, c);
}

// distance functions: ------------------------------------------------
float sdCircle(vec2 uv, vec2 origin, float radius)
{
    float d = length(uv - origin) - radius;
    return d;
}


float sdCircle2 (vec2 p, float radius)
{
    return length(p) - radius;
}

float sdAxisAlignedRect(vec2 uv, vec2 tl, vec2 br)
{
    vec2 d = max(tl - uv, uv - br);
    return length(max(vec2(0.0), d)) + min(0.0, max(d.x, d.y));
}

float sdEllipse( vec2 p, in vec2 ab )
{
    p = abs( p ); if( p.x > p.y ){ p=p.yx; ab=ab.yx; }
    
    float l = ab.y*ab.y - ab.x*ab.x;
    
    float m = ab.x*p.x/l;
    float n = ab.y*p.y/l;
    float m2 = m*m;
    float n2 = n*n;
    
    float c = (m2 + n2 - 1.0)/3.0;
    float c3 = c*c*c;
    
    float q = c3 + m2*n2*2.0;
    float d = c3 + m2*n2;
    float g = m + m*n2;
    
    float co;
    
    if( d<0.0 )
    {
        float h = acos(q/c3)/3.0;
        float s = cos(h);
        float t = sin(h)*sqrt(3.0);
        float rx = sqrt( -c*(s + t + 2.0) + m2 );
        float ry = sqrt( -c*(s - t + 2.0) + m2 );
        co = ( ry + sign(l)*rx + abs(g)/(rx*ry) - m)/2.0;
    }
    else
    {
        float h = 2.0*m*n*sqrt( d );
        float s = sign(q+h)*pow( abs(q+h), 1.0/3.0 );
        float u = sign(q-h)*pow( abs(q-h), 1.0/3.0 );
        float rx = -s - u - c*4.0 + 2.0*m2;
        float ry = (s - u)*sqrt(3.0);
        float rm = sqrt( rx*rx + ry*ry );
        co = (ry/sqrt(rm-rx) + 2.0*g/rm - m)/2.0;
    }
    
    float si = sqrt( 1.0 - co*co );
    
    vec2 r = ab * vec2(co,si);
    
    return length(r-p) * sign(p.y-r.y);
}


float sdLineSegment(vec2 uv, vec2 a, vec2 b, float lineWidth)
{
    vec2 rectDimensions = b - a;
    float angle = atan(rectDimensions.x, rectDimensions.y);
    mat2 rotMat = rot2D(-angle);
    a *= rotMat;
    b *= rotMat;
    float halfLineWidth = lineWidth / 2.;
    a -= halfLineWidth;
    b += halfLineWidth;
    return sdAxisAlignedRect(uv * rotMat, a, b);
}

float sdLineSegmentRounded(vec2 uv, vec2 a, vec2 b, float lineWidth)
{
    vec2 pa = uv-a, ba = b-a;
    float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
    return length( pa - ba*h ) - lineWidth*0.5;
}

float sdSquircle(vec2 uv, vec2 origin, float radius, float power, float rot_)
{
    mat2 rot = rot2D(rot_);
    vec2 v = abs((origin*rot) - (uv*rot));
    float d = pow(v.x,power) + pow(v.y, power);
    d -= pow(radius, power);
    return d;
}

const float HALF_PI = 1.57079632679;

float cro(in vec2 a, in vec2 b ) { return a.x*b.y - a.y*b.x; }

float sdUnevenCapsule( in vec2 p, in vec2 pa, in vec2 pb, in float ra, in float rb )
{
    p  -= pa;
    pb -= pa;
    float h = dot(pb,pb);
    vec2  q = vec2( dot(p,vec2(pb.y,-pb.x)), dot(p,pb) )/h;
    
    //-----------
    
    q.x = abs(q.x);
    
    float b = ra-rb;
    vec2  c = vec2(sqrt(h-b*b),b);
    
    float k = cro(c,q);
    float m = dot(c,q);
    float n = dot(q,q);
    
    if( k < 0.0 ) return sqrt(h*(n            )) - ra;
    else if( k > c.x ) return sqrt(h*(n+1.0-2.0*q.y)) - rb;
    return m                       - ra;
}
const int N = 4;
float sdPoly( in vec2[N] v, in vec2 p )
{
    const int num = v.length();
    float d = dot(p-v[0],p-v[0]);
    float s = 1.0;
    for( int i=0, j=num-1; i<num; j=i, i++ )
    {
        // distance
        vec2 e = v[j] - v[i];
        vec2 w =    p - v[i];
        vec2 b = w - e*clamp( dot(w,e)/dot(e,e), 0.0, 1.0 );
        d = min( d, dot(b,b) );
        
        // winding number from http://geomalgorithms.com/a03-_inclusion.html
        bvec3 cond = bvec3( p.y>=v[i].y, p.y<v[j].y, e.x*w.y>e.y*w.x );
        if( all(cond) || all(not(cond)) ) s*=-1.0;
    }
    
    return s*sqrt(d);
}

float sdBox( in vec2 p, in vec2 b )
{
    vec2 d = abs(p)-b;
    return length(max(d,vec2(0))) + min(max(d.x,d.y),0.0);
}

float sdTriangle( in vec2 p0, in vec2 p1, in vec2 p2, in vec2 p )
{
    vec2 e0 = p1 - p0;
    vec2 e1 = p2 - p1;
    vec2 e2 = p0 - p2;
    
    vec2 v0 = p - p0;
    vec2 v1 = p - p1;
    vec2 v2 = p - p2;
    
    vec2 pq0 = v0 - e0*clamp( dot(v0,e0)/dot(e0,e0), 0.0, 1.0 );
    vec2 pq1 = v1 - e1*clamp( dot(v1,e1)/dot(e1,e1), 0.0, 1.0 );
    vec2 pq2 = v2 - e2*clamp( dot(v2,e2)/dot(e2,e2), 0.0, 1.0 );
    
    float s = sign( e0.x*e2.y - e0.y*e2.x );
    vec2 d = min( min( vec2( dot( pq0, pq0 ), s*(v0.x*e0.y-v0.y*e0.x) ),
                      vec2( dot( pq1, pq1 ), s*(v1.x*e1.y-v1.y*e1.x) )),
                 vec2( dot( pq2, pq2 ), s*(v2.x*e2.y-v2.y*e2.x) ));
    
    return -sqrt(d.x)*sign(d.y);
}

float sdfStar5( in vec2 p )
{
    const vec2 k1 = vec2(0.809016994375, -0.587785252292);
    const vec2 k2 = vec2(-k1.x,k1.y);
    p.x = abs(p.x);
    p -= 2.0*max(dot(k1,p),0.0)*k1;
    p -= 2.0*max(dot(k2,p),0.0)*k2;
    
    const vec2 k3 = vec2(0.951056516295,  0.309016994375);
    return dot( vec2(abs(p.x)-0.1,p.y), k3);
}

// Operators
vec2 tX(vec2 p, vec2 t) { return p - t; }

void diff(inout vec2 d1, in vec2 d2) {
    if (-d2.x > d1.x) {
        d1.x = -d2.x;
        d1.y = d2.y;
    }
}

void add(inout vec2 d1, in vec2 d2) {
    if (d2.x < d1.x) d1 = d2;
}

void intersection(inout vec2 d1, in vec2 d2) {
    if (d1.x < d2.x) d1 = d2;
}


float smoothMerge(float d1, float d2, float k)
{
    float h = clamp(0.5 + 0.5*(d2 - d1)/k, 0.0, 1.0);
    return mix(d2, d1, h) - k * h * (1.0-h);
}

float smoothIntersection( float d1, float d2, float k ) {
    float h = clamp( 0.5 - 0.5*(d2-d1)/k, 0.0, 1.0 );
    return mix( d2, d1, h ) + k*h*(1.0-h);
}

float merge(float d1, float d2)
{
    return min(d1, d2);
}

float mergeExclude(float d1, float d2)
{
    return min(max(-d1, d2), max(-d2, d1));
}

float substract(float d1, float d2)
{
    return max(-d1, d2);
}

float intersect(float d1, float d2)
{
    return max(d1, d2);
}

float repeat(float coord, float spacing) {
    return mod(coord, spacing) - spacing*0.5;
}


// MASKS
float fillMask(float distanceChange, float dist) {
    return smoothstep(distanceChange, -distanceChange, dist);
}

float blurMask(float distanceChange, float dist, float blurAmount) {
    float blurTotal = blurAmount*.01;
    return smoothstep(blurTotal+distanceChange, -distanceChange, dist);
}

float innerMask(float distanceChange, float dist, float width) {
    return smoothstep(distanceChange,-distanceChange,dist+width);
}

float outerMask(float distanceChange, float dist, float width) {
    return smoothstep(distanceChange,-distanceChange,dist-width);
}
const vec4 mixColors[] = vec4[](
    vec4(1,0,1,1),
    vec4(1,1,1,1),
    vec4(1,1,1,1),
    vec4(1,1,1,1),
    vec4(1,1,1,1),
    vec4(1,1,1,1),
    vec4(0,0,0,1),
    vec4(67./255.,196./255.,218./255.,1.),
    vec4(67./255.,196./255.,218./255.,1.),
    vec4(67./255.,196./255.,218./255.,1.),
    vec4(195./255.,218./255.,214./255.,1.),
    vec4(204./255.,96./255.,49./255.,1.),
    vec4(148./255.,86./255.,71./255.,1.),
    vec4(241./255.,217./255.,184./255.,1.),
    vec4(88./255.,89./255.,95./255.,1.),
    vec4(255./255.,117./255.,19./255.,1.),
    vec4(255./255.,117./255.,19./255.,1.),
    vec4(68./255.,188./255.,63./255.,1.),
    vec4(238./255.,124./255.,53./255.,1.),
    vec4(199./255.,65./255.,51./255.,1.),
    vec4(215./255.,79./255.,89./255.,1.),
    vec4(225./255.,178./255.,127./255.,1.),
    vec4(255./255.,255./255.,0,1.),
    vec4(135./255., 206./255., 235./255.,1.),
    vec4(34./255.,139./255.,34./255.,1.),
    vec4(1.0, 0.0, 0.0, 1.0),
    vec4(1.0,0.94,0.67,1.0)*.8
);

// Thanks to Daedelus for his amazingly helpful comment!! :-) 
void draw(vec2 uv, vec2 distAndMaterial, inout vec4 fragColor)
{
    float dist = distAndMaterial.x;
    int material = int(distAndMaterial.y);
    float distanceChange = fwidth(dist) * 0.5;
    
    const float[27] distanceChangeStops = float[27](0.004, 0.0, 0.004, 0.015, 0.015, 0.004, 0.0, 0.0015, 0.001, 0.004, 0.004, 0.004, 0.004, 0.004, 0.004, 0.004, 0.0, 0.004, 0.0, 0.004, 0.004, 0.0, 0.006, 0.0, 0.0, 0.0, 1.);
	float uWotM8 = distanceChangeStops[material];
    if(material == 26) {
        fragColor = mix(fragColor, mixColors[material], blurMask(distanceChange, dist, uWotM8));
    } else if(uWotM8!=0.0)
    {
        uWotM8 = outerMask(distanceChange, dist, uWotM8);
        if(material == 3 || material == 4) {
	    	fragColor = mix(fragColor, vec4(1,0,0,1), uWotM8);
        } else {
	    	fragColor = mix(fragColor, vec4(0,0,0,1), uWotM8);
        }
    }
    fragColor = mix(fragColor, mixColors[material], fillMask(distanceChange, dist));
}



