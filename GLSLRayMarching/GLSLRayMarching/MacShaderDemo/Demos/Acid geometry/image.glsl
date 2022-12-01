// Created by XORXOR, 2016
// Attribution-NonCommercial-ShareAlike 4.0 International (CC BY-NC-SA 4.0)
// https://www.shadertoy.com/view/4ldXR4
//
// Remake of davidope's animgif
// http://dvdp.tumblr.com/post/96924050968/testing-toon-shaders-for-an-illustration-project

#define PI 3.141592653589793
#define TWO_PI 6.283185307179586
#define SQRT_2 1.4142135623730951

vec3 hash3( float n )
{
    return fract( sin( vec3( n, n + 1.0, n + 2.0 ) ) *
            vec3( 13.5453123, 31.1459123, 37.3490423 ) );
}

// from iq
float sdBox( vec3 p, vec3 b )
{
    vec3 d = abs( p ) - b;
    return min( max( d.x, max( d.y, d.z ) ), 0.0 ) + length( max( d, 0.0 ) );
}

float sdHexPrism( vec3 p, vec2 h )
{
    vec3 q = abs( p );
    return max( q.y - h.y, max( ( q.x * 0.866025 + q.z * 0.5 ), q.z ) - h.x );
}

float sdEllipsoid( vec3 p, vec3 r )
{
    return ( length( p / r ) - 1.0 ) * min( min( r.x, r.y ), r.z );
}

vec2 opU( vec2 d2, vec2 d1 )
{
    return ( d2.x < d1.x ) ? d2 : d1;
}

vec2 opS( vec2 d2, vec2 d1 )
{
    return( -d1.x > d2.x ) ? vec2( -d1.x, d1.y ) : d2;
}

float smin( float a, float b, float k )
{
    float h = clamp( 0.5 + 0.5 *( b - a ) / k, 0.0, 1.0 );
    return mix( b, a, h ) - k * h * ( 1.0 - h );
}

// from hg_sdf
float sdCapsule( vec3 p, float r, float c )
{
    return mix( length( p.yz ) - r,
                length( vec3( p.y, abs( p.x ) - c, p.z ) ) - r,   step( c, abs( p.x ) ) );
}

vec2 opRep( vec2 p, vec2 size, vec2 start, vec2 stop )
{
    vec2 halfSize = size * 0.5;
    vec2 c = floor( p / size );
    p = mod( p , size ) - halfSize;
    if ( c.y > stop.y )
    {
        p.y += size.y * ( c.y - stop.y );
    }
    if ( c.y < start.y )
    {
        p.y += size.y * ( c.y - start.y );
    }
    return p;
}

// Rotate around a coordinate axis (i.e. in a plane perpendicular to that axis) by angle <a>.
// Read like this: R(p.xz, a) rotates "x towards z".
// This is fast if <a> is a compile-time constant and slower (but still practical) if not.
void pR( inout vec2 p, float a )
{
    p = cos( a ) * p + sin( a ) * vec2( p.y, -p.x );
}

// Shortcut for 45-degrees rotation
void pR45( inout vec2 p )
{
    p = ( p + vec2( p.y, -p.x ) ) * sqrt( 0.5 );
}

vec2 sdSmokingCube( vec3 p, float t, float minDistance )
{
    vec2 cube = opS( vec2( sdBox( p, vec3( 1.0 ) ), 1.0 ),
                      vec2( sdBox( p - vec3( 0.0, 0.0, 0.1 ), vec3( 0.72, 0.72, 1.0 ) ), 2.0 ) );
    vec2 smoke = vec2( 9999.0, 7.0 );
    vec3 smokeDir = vec3( 1.0 );

    // rendering the smoke from spheres is really slow
    // trying a quick speedup by checking the distance from the smoke bounding sphere first
    float smokeBounds = length( p - vec3( 0.5, 0.5, 1.3 ) ) - 1.0;
    if ( smokeBounds < min( cube.x, minDistance ) )
    {
#define NUM_PARTICLES 15

        for ( int i = 0; i < NUM_PARTICLES; i++ )
        {
            float pt = fract( t + float( i ) / float( NUM_PARTICLES ) );
            float d = length( p + vec3( 0.0, 0.0, -0.8 ) +
                         0.15 - hash3( float( i ) ) * 0.3
                         - pt * ( smokeDir + 0.5 * hash3( float( i ) ) - vec3( 0.25 ) ) ) - 0.25 * ( 1.0 - pt );
            smoke.x = min( smoke.x, d );
        }
    }

    return opU( cube, smoke );
}

vec2 sdPyramid( vec3 p, vec2 h )
{
    const float a = 0.866025;
    vec3 q = abs( p );
    float dx = max( q.x - h.y, max( q.z * a + p.y * 0.5, -p.y ) - h.x * 0.5 );
    float dz = max( q.z - h.y, max( q.x * a + p.y * 0.5, -p.y ) - h.x * 0.5 );
    return vec2( max( dx, dz ), 3.0 );
}

vec2 sdWorm( vec3 p, vec2 t )
{
    vec2 q = vec2( length( p.xy ) - t.x, p.z );
    float dt = length( q ) - t.y;

    vec3 d = abs( p + vec3( 0.0, 1.0, 0.0 ) ) - vec3( t.x * 2.0, t.x, t.x );
    float dc = min( max( d.x, max( d.y, d.z ) ), 0.0 ) + length( max( d, 0.0 ) );

    return vec2( max( dt, -dc ), 4.0 );
}

vec2 sdPearl( vec3 p )
{
    return opU( vec2( length( p ) - 0.7, 6.0 ),
                opS( vec2( length( p ) - 1.0, 5.0 ),
                     vec2( sdHexPrism( p + vec3( 1.0, 0.0, 0.0 ) , vec2( 1.0, 1.1 ) ), 5.0 ) ) );
}

vec2 sdCloud( vec3 p )
{
    float d = sdCapsule( p, 0.5, 1.0 );
    d = smin( d, length( p + vec3( 0.0, -0.3, 0.0 ) ) - 0.6, 0.7 );
    d = smin( d, length( p + vec3( 0.3, 0.4, 0.0 ) ) - 0.2, 0.7 );
    d = smin( d, length( p + vec3( -0.4, 0.35, -0.1 ) ) - 0.3, 0.2 );

    return vec2( d, 6.0 );
}

vec2 map( vec3 pos )
{
    float t = iTime * 0.4;
    float tMod = fract( t );

    vec2 plane = vec2( abs( pos.y + 1.0 ), 0.0 );

    float pyramidSize = tMod * 1.16;
    vec2 pyramidBottom = sdPyramid( pos + vec3( 3.0, 1.0 - pyramidSize * 0.5, -2.0 ),
                              vec2( pyramidSize ) );
    vec2 pyramidTop = sdPyramid( pos + vec3( 3.0, 0.4 - pyramidSize * 1.7, -2.0 ),
                              vec2( 1.16 - pyramidSize ) );

    float wormOffset = tMod * -2.0;
    wormOffset += ( wormOffset <= -1.0 ) ? 2.0 : 0.0;
    wormOffset /= SQRT_2;
    vec3 wormPos = pos + vec3( 0.0 + wormOffset, 1.0, -4.0 + wormOffset );
    pR45( wormPos.xz );
    pR( wormPos.xy, tMod * TWO_PI );
    vec2 worm = sdWorm( wormPos, vec2( 1.0, 0.5 ) );

    vec3 pearlPos = pos - vec3( 3.0, 0.0, 2.0 );
    pR( pearlPos.xz, tMod * TWO_PI );
    vec2 pearl = sdPearl( pearlPos );

    float cloudSpeed = ( tMod * -8.0 ) * SQRT_2;
    vec3 cloudPos = pos - vec3( 4.0 + cloudSpeed, 3.0, 0.0 + cloudSpeed );
    pR45( cloudPos.xz );
    cloudPos.xz = opRep( cloudPos.xz, vec2( 8.0 ) , vec2( 0.0 ), vec2( 0.0 ) );
    vec2 cloud = sdCloud( cloudPos );

    vec2 res = opU( pyramidBottom,
               opU( pyramidTop,
               opU( worm,
               opU( pearl,
               opU( cloud, plane ) ) ) ) );

    vec2 cube = sdSmokingCube( pos, tMod, res.x );

    return opU( cube, res );
}

vec2 scene( vec3 ro, vec3 rd )
{
    float t = 0.01;
    for ( int i = 0; i < 100; i++ )
    {
        vec3 pos = ro + t * rd;
        vec2 res = map( pos );
        if ( res.x < 0.01 )
        {
            return vec2( t, res.y );
        }
        t += res.x;
    }
    return vec2( -1.0 );
}

// from eiffie
// https://www.shadertoy.com/view/4ss3WB
float calcEdge( vec3 pos )
{
    vec3 eps = vec3( 0.05, 0.0, 0.0 );
    float d000 = map( pos ).x;
    float d_100 = map( pos - eps.xyy ).x;
    float d100 = map( pos + eps.xyy ).x;
    float d0_10 = map( pos - eps.yxy ).x;
    float d010 = map( pos + eps.yxy ).x;
    float d00_1 = map( pos - eps.yyx ).x;
    float d001 = map( pos + eps.yyx ).x;
    float edge = abs( d000 - 0.5 * ( d_100 + d100 ) ) +
                 abs( d000 - 0.5 * ( d0_10 + d010 ) ) +
                 abs( d000 - 0.5 * ( d00_1 + d001 ) );

    return clamp( 1.0 - edge * 200.0, 0.0, 1.0 );
}

float calcShadow( vec3 ro, vec3 rd, float mint, float maxt )
{
    float t = mint;
    float res = 1.0;
    for ( int i = 0; i < 20; i++ )
    {
        float h = map( ro + rd * t ).x;
        res = min( res, 22.0 * h / t );
        t += h;
        if ( ( h < 0.001 ) || ( t > maxt ) )
        {
            break;
        }
    }
    return clamp( res + 0.7, 0.0, 1.0 );
}

vec3 generateRay( vec2 fragCoord, vec3 eye, vec3 target )
{
    vec2 uv = ( fragCoord.xy - 0.5 * iResolution.xy ) / iResolution.y;
    vec3 cw = normalize( target - eye );
    vec3 cu = cross( cw, vec3( 0, 1, 0 ) );
    vec3 cv = cross( cu, cw );
    mat3 cm = mat3( cu, cv, cw );
    vec3 rd = cm * normalize( vec3( uv, 2.5 ) );
    return rd;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    float mo = 2.0 + 0.5 * iMouse.x / iResolution.x;
    vec3 target = vec3( 1.0, 0.0, 0.0 );
    vec3 eye = vec3( 20.0 * cos( mo ), 6.0, 20.0 * sin( mo ) );
    vec3 rd = generateRay( fragCoord.xy, eye, target );
    vec3 rdLeft = generateRay( fragCoord.xy + vec2( 2.0, 0.0 ), eye, target );
    vec3 rdBottom = generateRay( fragCoord.xy + vec2( 0.0, 2.0 ), eye, target );

    vec3 col = vec3( 1.0, 0.0, 1.0 );
    vec2 res = scene( eye, rd );
    float edge = 1.0;
    if ( res.x > 0.0 )
    {
        vec3 pos = eye + res.x * rd;
        col = res.y < 0.5 ? vec3( 0.29, 0.00, 0.47 ) :
              res.y < 1.5 ? vec3( 0.20, 0.64, 0.38 ) :
              res.y < 2.5 ? vec3( 0.93, 0.20, 0.0 ) :
              res.y < 3.5 ? vec3( 0.90, 0.81, 0.14 ) :
              res.y < 4.5 ? vec3( 0.81, 0.00, 0.28 ) :
              res.y < 5.5 ? vec3( 0.07, 0.31, 0.82 ) :
              res.y < 6.5 ? vec3( 1.0 ) :
              res.y < 7.5 ? vec3( 0.13 ) : vec3( 0.0 );

        edge = calcEdge( pos );

        vec3 ldir = normalize( vec3( -7.0, 13.0, 7.0 ) );
        float sh = calcShadow( pos, ldir, 0.1, 8.0 );
        col *= sh;
    }

    if ( res.y < 0.5 || res.y > 3.5 )
    {
        // edge detection by iq
        // https://www.shadertoy.com/view/4slSWf
        vec2 resLeft = scene( eye, rdLeft );
        vec2 resBottom = scene( eye, rdBottom );
        edge = clamp( 1.0 - 1.0 * max( abs( res.x - resLeft.x ), abs( res.y - resBottom.y ) ), 0.0, 1.0 );
    }

    col *= edge;

    fragColor = vec4( col, 1.0 );
}