#define PI 3.1415926
#define V vec2(0.,1.)

#define t iTime
#define r iResolution.xy
#define c fragCoord
#define cl(i) clamp(i,0.,1.)

#define MAT_NULL -1.
#define MAT_ANTHER 0.
#define MAT_FILAMENT 1.
#define MAT_PISTIL 2.
#define MAT_PETAL 3.
#define MAT_CALYX 4.
#define MAT_TREE 5.

float hash(vec2 _v)
{
    return fract(sin(dot(_v,vec2(89.44,19.36)))*22189.22);
}

float iHash(vec2 _v,vec2 _r)
{
    float h00 = hash(vec2(floor(_v*_r+V.xx)/_r));
    float h10 = hash(vec2(floor(_v*_r+V.yx)/_r));
    float h01 = hash(vec2(floor(_v*_r+V.xy)/_r));
    float h11 = hash(vec2(floor(_v*_r+V.yy)/_r));
    vec2 ip = vec2(smoothstep(V.xx,V.yy,mod(_v*_r,1.)));
    return (h00*(1.-ip.x)+h10*ip.x)*(1.-ip.y)+(h01*(1.-ip.x)+h11*ip.x)*ip.y;
}

float noise(vec2 _v)
{
    float sum = 0.;
    for(int i=1; i<9; i++)
    {
        sum += iHash(_v+vec2(i),vec2(2.*pow(2.,float(i))))/pow(2.,float(i));
    }
    return sum;
}

mat2 rotate( float _th )
{
    return mat2( cos(_th), -sin(_th), sin(_th), cos(_th) );
}

float pole( vec3 _p, float _r, float _l )
{
    vec2 d = abs( vec2( length( _p.xz ), _p.y ) ) - vec2( _r, _l );
    return min( max( d.x, d.y ), 0. ) + length( max( d, 0. ) );
}

float pole( vec3 _p, float _r )
{
    return length( _p.xz ) - _r;
}

float smin( float _a, float _b, float _k )
{
    float h = cl( 0.5+0.5*( _b-_a )/_k );
    return mix( _b, _a, h ) - _k*h*( 1.-h );
}

vec2 stamen( vec3 _p )
{
    vec2 dist = vec2( 1E2 );
    vec2 distC = dist;
    float phase = floor( atan( _p.z, _p.x )/PI/2.*13.-1. );
    vec3 offset = vec3( .04, -.0, .04 ) * ( 1. + sin( t )*.1 );
    offset.xz *= .6 + hash( vec2( phase*1.9873, 821.122 ) )*.6;
    vec3 p = _p - V.xyx*.01;
    p.xz = rotate( floor( phase )*PI*2./13. ) * p.xz;
    vec3 pa = p + ( sin(p.x*200.)*sin(p.y*200.)*sin(p.z*200.) ) * .003 - offset - V.xyx*.1;
    distC = vec2( length( pa ) - .005, MAT_ANTHER );
    if( distC.x < dist.x ){ dist = distC; }
    pa = p + vec3( sin(p.y*20.), 0., cos(p.y*20.) )*.003 - offset * ( .5+.5*sin( p.y/.1*PI/2. ) );
    distC = vec2( pole( pa-V.xyx*.025,  sin( pa.y/.1*PI )*.001, .075 ), MAT_FILAMENT );
    if( distC.x < dist.x ){ dist = distC; }
    return dist;
}

vec2 pistil( vec3 _p )
{
    vec3 p = _p;
    float pistil = pole( p - V.xyx*.01 + vec3( cos(p.y*50.), 0., sin(p.y*50.) )*.001, .004, .06 );
    pistil = smin( pistil, length( vec2( length( p.xz )-.007, p.y-.07 ) )-.001, .01 );
    return vec2( pistil, MAT_PISTIL );
}

vec2 petals( vec3 _p )
{
    float dist = 1E2;
    vec3 p = _p;
    p.y -= pow( length( p.xz ), .5)*.2-.055;
    p.xz = rotate( floor( atan( p.z, p.x )/PI/2.*5.-2. )*PI*2./5. ) * p.xz;
    p.xy = rotate( -.3 + sin( t )*.1 ) * p.xy;
    p.x += .14;
    p.x *= ( 1. - pow( abs( sin( atan( p.z, p.x ) ) ), .1 )*.3 )*1.4;
    p += ( sin(_p.x*20.)*sin(_p.y*20.)*sin(_p.z*20.) ) * .018;
    dist = min( dist, pole( p, .1, .001 ) );
    return vec2( dist, MAT_PETAL + cl( length( _p.xz ) ) );
}

vec2 calyx( vec3 _p )
{
    float dist = 1E2;
    
    vec3 p = _p;
    p.y -= pow( length( p.xz ), .2)*.2-.13;
    p.xz = rotate( floor( atan( p.z, p.x )/PI/2.*5.-2. )*PI*2./5. ) * p.xz;
    p.xy = rotate( -.3 ) * p.xy;

    vec3 ptemp = p;
    p.x += .04;
    p.x *= max( pow( abs( sin( atan( p.z, p.x ) ) ), .1 ), .6 );
    p += ( sin(_p.x*20.)*sin(_p.y*20.)*sin(_p.z*20.) ) * .018;
    dist = smin( dist, pole( p, .03, .001 ), .02 );

    p = ptemp + V.xyx*.15;
    p.x -= .02;
    p.x *= max( pow( abs( sin( atan( p.z, p.x ) ) ), .1 ), .6 );
    p += ( sin(_p.x*20.)*sin(_p.y*20.)*sin(_p.z*20.) ) * .018;
    dist = smin( dist, pole( p, .01, .001 ), .02 );
    
    dist = smin( dist, pole( _p + vec3( cos(_p.y*20.), 0., sin(_p.y*20.) )*.004 + V.xyx*.15, .01, .09 ), .02 );
    
    return vec2( dist, MAT_CALYX + cl( -_p.y-.05 ) );
}

vec2 blossom( vec3 _p, float _h )
{
    vec2 dist = vec2( 1E2 );
    if( length( _p ) < .28 )
    {
        dist = stamen( _p );
        vec2 distC = pistil( _p );
        if( distC.x < dist.x ){ dist = distC; }
        distC = petals( _p );
        if( distC.x < dist.x ){ dist = distC; }
        distC = calyx( _p );
        if( distC.x < dist.x ){ dist = distC; }
    }
    else
    {
        dist = vec2( length( _p )-.27, MAT_NULL );
    }
	return dist;
}

vec2 branch( vec3 _p )
{
    vec2 dist = vec2( 1E2 );
    vec3 p = _p;
    p.xy = rotate( -1. )*p.xy;
    vec3 pt = p + sin( p.x*10. )*sin( p.y*10. )*sin( p.z*10. ) * .03;
    dist = vec2( pole( pt, .1 ), MAT_TREE );
    p.zx = rotate( floor( p.y*2.+.5 )*.7 - .5 )*p.zx;
    float th = atan( p.z, p.x );
    if( th < 0. ){ p.zx = rotate( PI )*p.zx; }
    p.yz = rotate( PI/2. )*p.yz;
    p.y -= .3;
    p.z = mod( p.z+.25, .5 )-.25;
    vec2 distC = blossom( p, 12.4 );
    if( distC.x < dist.x ){ dist = distC; }
    return dist;
}

vec2 scene( vec3 _p )
{
    vec2 dist = branch( _p );
    return dist;
}

vec3 sceneNormal( vec3 _p )
{
    vec2 d = V*1E-4;
    return normalize( vec3(
        scene( _p + d.yxx ).x - scene( _p - d.yxx ).x,
        scene( _p + d.xyx ).x - scene( _p - d.xyx ).x,
        scene( _p + d.xxy ).x - scene( _p - d.xxy ).x
    ) );
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 p = (c*2.-r)/r.x;
    
    vec3 camPos = vec3( .8, 0., 1. );
    vec3 camTar = vec3( sin(t*.72), sin(t*.83), sin(t*.37) )*.01 - vec3( sin( t*.21 )*.2, -.2, .0 );
    vec3 camDir = normalize( camTar - camPos );
    vec3 camAir = V.xyx;
    vec3 camSid = normalize( cross( camDir, camAir ) );
    vec3 camTop = normalize( cross( camSid, camDir ) );
    
    vec3 rayDir = normalize( camSid * p.x + camTop * p.y + camDir );
    vec3 rayPos = camPos;
    float rayLen = 0.;
    vec2 dist = V.xx;
    for( int i=0; i<64; i++ )
    {
        dist = scene( rayPos )*vec2( .6, 1. );
        rayLen += dist.x;
        rayPos = camPos + rayDir * rayLen;
        if( dist.x < 2E-3 || 1E2 < rayLen ){ break; }
    }
    
    vec3 col = V.xxx;
    if( dist.x < 4E-3 )
    { 
        vec3 ligPos = vec3( 0., 1., 11. );
        vec3 nor = normalize( sceneNormal( rayPos ) );
        float dif = cl( dot( normalize( rayPos-ligPos ), -nor ) )*.3;
        float amb = .7;
        float speDot = cl( dot( normalize( normalize( rayPos-ligPos ) + normalize( rayPos-camPos ) ), -nor ) );
        float spe = cl( pow( speDot, 10. ) )*.1;
        vec3 matCol = V.xxx;
        if( floor( dist.y ) == MAT_NULL ){ amb = 1.; matCol = vec3( 1. ); }
        else if( floor( dist.y ) == MAT_ANTHER ){ matCol = vec3( .9, .9, .5 ); }
        else if( floor( dist.y ) == MAT_FILAMENT ){ matCol = vec3( .9, .9, .8 ); }
        else if( floor( dist.y ) == MAT_PISTIL ){ matCol = vec3( .8, .9, .6 ); }
        else if( floor( dist.y ) == MAT_PETAL ){ matCol = vec3( .9, .4, .8 ) + vec3( .1, .6, .2 ) * ( 1.-exp( -fract( dist.y )*16. ) ); }
        else if( floor( dist.y ) == MAT_CALYX ){ matCol = vec3( .7, .1, .3 ) + vec3( -.4, .4, -.4 ) * cl( fract( dist.y )*8. ); }
        else if( floor( dist.y ) == MAT_TREE ){
            nor += vec3(
                noise(vec2((rayPos.x+rayPos.z)*8.,rayPos.y*8.+27.1982))-.5,
                noise(vec2((rayPos.x+rayPos.z)*8.,rayPos.y*8.+28.1982))-.5,
                noise(vec2((rayPos.x+rayPos.z)*8.,rayPos.y*8.+29.1982))-.5
            )*2.;
            nor = normalize( nor );
            dif = cl( dot( normalize( rayPos-ligPos ), -nor ) )*.6;
            float speDot = cl( dot( normalize( normalize( rayPos-ligPos ) + normalize( rayPos-camPos ) ), -nor ) );
            float spe = cl( pow( speDot, 10. ) )*.1;
            matCol = vec3( .4, .3, .1 );
        }
       	col = ( dif + amb ) * matCol + spe;
    }
    else
    {
        col = vec3( .5, .7, .9 );
        for( float i=12.; i<39.; i+=1. )
        {
            vec2 pos = ( vec2( hash(vec2(i,198.33)), hash(vec2(i,298.33)) ) - .5 )*r/r.x*2.;
            pos += vec2( sin( t*.2*hash(vec2(i,19.233)) ), sin( t*.2*hash(vec2(i,29.233)) ) )*.01;
            col += cl( 12.-length(p-pos)*50. ) * vec3( 1., .7, .9 )*.02;
        }
    }
    
    col -= length( p )*.4;
    
    fragColor = vec4( col, 1. );
    
    
}