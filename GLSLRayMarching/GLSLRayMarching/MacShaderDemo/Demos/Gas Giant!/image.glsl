// Reference shaders below
// RAYMARCHED BALL (iq):  https://www.shadertoy.com/view/ldfSWs
// NOISE (iq): https://www.shadertoy.com/view/4sfGzS#
// CUBEMAP (iq): https://www.shadertoy.com/view/ltl3D8
// SWIRLY STUFF (Antonalog): https://www.shadertoy.com/view/4s23WK
// STAR/FLARE (mu6k): https://www.shadertoy.com/view/4sX3Rs
// RAY V SPHERE (reinder): https://www.shadertoy.com/view/4tjGRh

const int star_iterations = 10;
const float distort_iterations = 5.0;
const float tex_scale = 0.025;
const float time_scale = 0.2;
const vec3 col_star = vec3( 1.0, 0.7, 0.5 );
const vec3 pos_star = vec3( 0.0, 9.0, 30.0 );
const vec3 world_up = vec3( 0.0, 1.0, 0.0 );

struct CameraInfo
{
    vec3 pos;
    vec3 dir;
    mat3 m;
    mat3 mInv;
};

float hash( float n ) { return fract(sin(n)*123.456789); }

vec2 rotate( in vec2 uv, float a)
{
    float c = cos( a );
    float s = sin( a );
    return vec2( c * uv.x - s * uv.y, s * uv.x + c * uv.y );
}

float noise( in vec3 p )
{
    vec3 fl = floor( p );
    vec3 fr = fract( p );
    fr = fr * fr * ( 3.0 - 2.0 * fr );

    float n = fl.x + fl.y * 157.0 + 113.0 * fl.z;
    return mix( mix( mix( hash( n +   0.0), hash( n +   1.0 ), fr.x ),
                     mix( hash( n + 157.0), hash( n + 158.0 ), fr.x ), fr.y ),
                mix( mix( hash( n + 113.0), hash( n + 114.0 ), fr.x ),
                     mix( hash( n + 270.0), hash( n + 271.0 ), fr.x ), fr.y ), fr.z );
}

float fbm( in vec2 p, float t )
{
    float f;
    f  = 0.5000 * noise( vec3( p, t ) ); p *= 2.1;
    f += 0.2500 * noise( vec3( p, t ) ); p *= 2.2;
    f += 0.1250 * noise( vec3( p, t ) ); p *= 2.3;
    f += 0.0625 * noise( vec3( p, t ) );
    return f;
}

vec2 field(vec2 p)
{
    float t = time_scale * iTime;

    p.x += t;

    float n = fbm( p, t );

    float e = 0.25;
    float nx = fbm( p + vec2( e, 0.0 ), t );
    float ny = fbm( p + vec2( 0.0, e ), t );

    return vec2( n - ny, nx - n ) / e;
}

vec3 distort( in vec2 p )
{
    for( float i = 0.0; i < distort_iterations; ++i )
    {
        p += field( p ) / distort_iterations;
    }
    vec3 s = 2.5 * texture( iChannel0, vec2( 0.0, p.y * tex_scale ) ).xyz;

    return fbm( p, 0.0 ) * s;
}

vec2 map( in vec2 uv )
{
    uv.x *= 5.0;
    uv.x += 0.01 * iTime;
    uv.y *= 15.0;
    return uv;
}

vec3 doBackgroundStars( in vec3 dir )
{
    vec3 n  = abs( dir );
    vec2 uv = ( n.x > n.y && n.x > n.z ) ? dir.yz / dir.x: 
              ( n.y > n.x && n.y > n.z ) ? dir.zx / dir.y:
                                           dir.xy / dir.z;
    
    float f = 0.0;
    
    for( int i = 0 ; i < star_iterations; ++i )
    {
        uv = rotate( 1.07 * uv + vec2( 0.7 ), 0.5 );
        
        float t = 10. * uv.x * uv.y + iTime;
        vec2 u = cos( 100. * uv ) * fbm( 10. * uv, 0.0 );
        f += smoothstep( 0.5, 0.55, u.x * u.y ) * ( 0.25 * sin( t ) + 0.75 );
    }
    
    return f * col_star;
}

vec3 doMainStar( in vec2 uv, in vec2 sp)
{
    float t = atan( uv.x - sp.x, uv.y - sp.y );
    float n = 2.0 + noise( vec3( 10.0 * t, iTime, 0.0 ) );
    float d = length( uv - sp ) * 25.0;
    return ( ( 1.0 + n ) / ( d * d * d ) ) * col_star;
}

float doCastSphere( in vec3 p, in vec3 rd )
{
    float b = dot( p, rd );
    float c = dot( p, p ) - 1.0;
    
    float f = b * b - c;
    if( f >= 0.0 )
    {
        return -b - sqrt( f );
    }
    return -1.0;
}

vec3 doMaterial( in vec3 pos )
{
    vec2 uv;
    uv.x = atan( pos.x, pos.z );
    uv.y = asin( pos.y );
    return distort( map( uv ) );
}

vec3 doLighting( in vec3 n, in vec3 c, in vec3 rd, in vec3 rdc )
{
    vec3  l   = normalize( pos_star + 2.0 * ( pos_star - dot( pos_star, rdc ) * rdc ) );
    float ndl = dot( n, l );
    float ndr = dot( n, -rd );
    float ldr = dot( l, rd );
    float f   = max( ndl, 0.0 ) + 0.002;
    float g   = ldr * smoothstep( 0.0, 0.1, ndr ) * pow( 1.0 - ndr, 10.0 );
    return clamp( f * c + g * col_star, 0.0, 1.0 );
}

float doFlare( in vec2 uv, in vec2 dir, float s )
{
    float d = length( uv - dot( uv, dir ) * dir );
    float f = 0.0;
    f += max( pow( 1.0 - d, 128.0 ) * ( 1.0   * s - length( uv ) ), 0.0 );
    f += max( pow( 1.0 - d,  64.0 ) * ( 0.5   * s - length( uv ) ), 0.0 );
    f += max( pow( 1.0 - d,  32.0 ) * ( 0.25  * s - length( uv ) ), 0.0 );
    f += max( pow( 1.0 - d,  16.0 ) * ( 0.125 * s - length( uv ) ), 0.0 );
    return f;
}

float doLensGlint( in vec2 uv, in vec2 c, float r, float w )
{
    float l = length( uv - c );
    return length( c ) * smoothstep( 0.0, w * r, l ) * ( 1.0 - smoothstep( w * r, r, l ) );
}

vec3 render( in vec2 uv, in CameraInfo ci )
{
    // create view ray
    vec3 rd  = ci.m * normalize( vec3( uv, 1.0 ) );
    vec3 rdc = ci.m * vec3( 0.0, 0.0, 1.0 );
    
    // background stars
    vec3 c = doBackgroundStars( rd );
    
    // main star
    vec3 cp = ci.mInv * (pos_star - ci.pos);
    vec2 sp = cp.xy / cp.z;
    if( cp.z > 0. )
    {
        c += doMainStar( uv, sp );
    }
    
    // planet
    float t = doCastSphere( ci.pos, rd );
    if( t > 0.0 )
    {
        vec3 pos = ci.pos + t * rd;
        vec3 nor = normalize( pos );
        c = doMaterial( pos );
        c = doLighting( nor, c, rd, rdc );
    }
    
    // lens flare
    if( cp.z > 0.0 && sp.x > -1.0 && sp.x < 1.0 )
    {
        float oc = smoothstep( 0.35, 0.4, length( sp ) );
        float f = 0.0;
        f += doFlare( uv - sp, vec2( 1.,0. ), oc );
        f += oc * 0.05 * doLensGlint( uv, -0.4 * sp, 0.2, 0.92 );
        f += oc * 0.09 * doLensGlint( uv, -0.8 * sp, 0.3, 0.95 );
        f += oc * 0.04 * doLensGlint( uv, -1.1 * sp, 0.06, 0.8 );
        c += f * col_star;
    }
    
    return c;
}

CameraInfo doCamera( in vec3 pos, in vec3 dir )
{
    CameraInfo ci;
    
    vec3 ww = dir;
    vec3 uu = normalize( cross( ww, world_up ) );
    vec3 vv = normalize( cross( uu, ww ) );
    mat3 m = mat3( uu, vv, ww );
    mat3 mInv = mat3( uu.x, vv.x, ww.x,
                      uu.y, vv.y, ww.y,
                      uu.z, vv.z, ww.z );
    
    ci.pos = pos;
    ci.dir = dir;
    ci.m = m;
    ci.mInv = mInv;
    
    return ci;
}

void mainImage (out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = gl_FragCoord.xy / iResolution.xy - 0.5;
    uv.x *= iResolution.x / iResolution.y;
    
    vec2 m = iMouse.xy / iResolution.xy;
    
    // camera default movement
    float cx = cos( 0.1 * iTime + 3.55 );
    float sx = sin( 0.1 * iTime + 3.55 );
    float cy = 0.;
    
    // camera mouse movement
    if( iMouse.z > 0. )
    {
        cx = cos( 10. * m.x );
        sx = sin( 10. * m.x );
        cy = cos( 3.2 * m.y );
    }
    
    // camera position/direction
    vec3 camPos = 2. * vec3( cx - sx, cy, sx + cx );
    vec3 camDir = normalize( -camPos );

    // render scene
    vec3 c = render( uv, doCamera( camPos, camDir ) );
    //vec3 c = vec3( distort( map( uv ) ) );
    //vec3 c = vec3( fbm( map( uv ), iTime ) );
    
    // gamma correction
    c = pow( c, vec3( 0.4545 ) );
    
    fragColor = vec4( c, 1.0 );
}
