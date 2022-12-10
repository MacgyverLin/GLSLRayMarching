// "space rock" 
//
// by Val "valalalalala" GvM - 2020
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
//
// based off https://www.shadertoy.com/view/tsyfDw

#define RAY_MARCH_STEPS           133
#define RAY_MARCH_TOO_FAR         float( RAY_MARCH_STEPS )
#define RAY_MARCH_CLOSE           0.0071
#define PI2                       6.283185307179586

#define VECTOR_PROJECTION(a,b,p) clamp( dot( p - a, b - a ) / dot( b - a, b - a ), 0., 1. )
#define TRIG(len, angle)         (len * vec2( cos( angle ), sin( angle ) ))

/////////////////////////////////////////////////////////
vec2 hash( vec2 x )  // replace this by something better
{
    const vec2 k = vec2( 0.3183099, 0.3678794 );
    x = x*k + k.yx;
    return -1.0 + 2.0*fract( 16.0 * k*fract( x.x*x.y*(x.x+x.y)) );
}

float noise( in vec2 p )
{
    vec2 i = floor( p );
    vec2 f = fract( p );
	
	vec2 u = f*f*(3.0-2.0*f);

    return mix( mix( dot( hash( i + vec2(0.0,0.0) ), f - vec2(0.0,0.0) ), 
                     dot( hash( i + vec2(1.0,0.0) ), f - vec2(1.0,0.0) ), u.x),
                mix( dot( hash( i + vec2(0.0,1.0) ), f - vec2(0.0,1.0) ), 
                     dot( hash( i + vec2(1.0,1.0) ), f - vec2(1.0,1.0) ), u.x), u.y);
}

/////////////////////////////////////////////////////////

mat3 makeCamera( vec3 origin, vec3 target, float roll ) {
	vec3 up = vec3(sin(roll), cos(roll), 0.0);
	vec3 zz = normalize(target - origin);
	vec3 xx = normalize(cross(zz, up));
	vec3 yy = normalize(cross(xx, zz));
	return mat3( xx, yy, zz );
}

///////////////////////////////////////////////////////////////////////////////


float starSegmentSDF( vec3 point, vec3 a, vec3 center, float thickness ) {
    float h = VECTOR_PROJECTION( a, center, point );
    vec3 q = a + ( center - a ) * h;
    h = pow( h, 0.7 ) * .8;      
    return length( point - q ) - thickness * h;
}

float starSDF( vec3 point, vec3 center, float len, float thickness ) {
    vec3 a0 = vec3( +0.000 * len, +1.000 * len, center.z ); // @ r:+1.570 , d:90
    vec3 a1 = vec3( -0.952 * len, +0.309 * len, center.z ); // @ r:+2.827 , d:162
    vec3 a2 = vec3( -0.588 * len, -0.810 * len, center.z ); // @ r:+4.084 , d:234
    vec3 a3 = vec3( +0.587 * len, -0.810 * len, center.z ); // @ r:+5.340 , d:306
    vec3 a4 = vec3( +0.951 * len, +0.309 * len, center.z ); // @ r:+6.597 , d:378
    
    float d0 = starSegmentSDF( point, a0, center, thickness );
    float d1 = starSegmentSDF( point, a1, center, thickness );
    float d2 = starSegmentSDF( point, a2, center, thickness );
    float d3 = starSegmentSDF( point, a3, center, thickness );
    float d4 = starSegmentSDF( point, a4, center, thickness );

    return min( d0, min( d1, min( d2, min( d3, d4 ) ) ) );
}

float starSDF_old( vec3 point, vec3 center, float len, float thickness ) {
    const int count = 5;
    float d = RAY_MARCH_TOO_FAR;
    for ( int i = 0 ; i < count ; i++ ) {
        float angle = PI2 * float( i ) / float( count ) + PI2 / float ( count ) * 0.25;
        vec3 a = vec3( center.xy + TRIG(len, angle), center.z );
        float h = VECTOR_PROJECTION( a, center, point );
        vec3 q = a + ( center - a ) * h;
        h = pow( h, 0.7 ) * .8;
        d = min( d, length( point - q ) - thickness * h );
    }
    
    return d;
}

float ufoSDF( vec3 point, vec3 center, float angle, float len ) {
    vec2 o = vec2( cos( angle ), sin( angle ) );    
    vec3 p = vec3( center.xy + len * o, center.z );
    
    float h = VECTOR_PROJECTION( p, center, point );
    //h = clamp( h, 0.6, 1. ); // <-- fun
    h = clamp( h, 0.1, 1. );
    
    vec3 q = mix( 
        p + h * ( center - p ),
        p - h * ( center - p ) * 2.5,
        step(.8,h)
    );
    
    float r = len * pow(h,1.85) * 1.3;
    r += 0.023 * (1.-step(0.6,h)+step(.9,h));
    r += 0.2*h;
    
    return length( point - q ) - r ;
}

float planetSDF( vec3 point ) {
    vec2 rot = point.xy + TRIG(1.,iTime*0.235);
    float n = 
        + 0.10 * noise( rot * 3. )
        + 0.03 * noise( rot * 9. )
        + 0.01 * noise( rot * 23. )
    ;
    return length(point) - 1.1 + 2.9 * n;
}

float stars( vec3 point ) {
    float t = iTime * .061;
    float scale = .7;

    vec3 i_point = floor( point * scale );
    vec3 f_point = fract( point * scale );
    f_point.z = i_point.z = point.z + 1.5;
 
    float o = 3.*noise( i_point.xy * 721.3789 + t );
    o = clamp( o, -.3, +.3 ) + .55;

    return starSDF( f_point - o, vec3(.0), .13, .07 );
}


float starsx( vec3 point ) {
    float t = iTime * 2.;
    float scale = 1.2;
    
    float n = 0.1 * noise( 444. * (point.xy + t ) );
    point.xy = fract( ( point.xy + TRIG(.4,t+0.2*point.y) ) * scale );

    return starSDF( point -.4, vec3(.0,.0,-1.3), .19, .07 );
}

float stars_old( vec3 point ) {
    float t = iTime * 2.;
    float scale = .8;
    
    vec3 qq = floor( point*scale );
    float nn = noise( 3. * floor( point.xy + t ) );
   
    vec3 c = vec3(.1+TRIG(.2,t*nn),-1.3);
    
    point.xy = fract( point.xy*scale );
    //point.x += 0.7 * mod( floor( qq.y ), 2. );

    return starSDF( point -.5, c, .19, .07 );
    
    

    float d = RAY_MARCH_TOO_FAR;
    const int rows = 3;
    const int cols = 5;
    

    
    for ( int row = 0 ; row < rows ; row++ ) {
        float r = float( row ) / float( rows );
        for ( int col = 0 ; col < cols ; col++ ) {
            float c = float( col ) / float( cols );
            c -= 0.25*mod(r,0.5);
            
            vec3 s = vec3( c * 9.4 - 3.8, r * 6.3 - 1.9, -1.3 );
            s = vec3( c * 1., r * 6.3 - 1.9, -1.3 );
            
            float n = noise( 1.2 * ( s.xy + t + r + c ) );
            s.xy += TRIG(.3,n * PI2 );
            
            d = min( d, starSDF( point, s, .19, .07 ) );
            break;
        }
        break;
    }   
    
    vec2 n = vec2( d, -d ) + 0.4 * abs(sin(t) ) + point.xy;
    float sparkle = fract( noise( 133. * n ) );
    
    return d - .003 * sparkle;
}

float ufo( vec3 point ) {
    vec2 t = TRIG( 1., iTime  *.8);
    vec3 u = vec3( t.x * 3., t.x * 0.2, 1.5 + t.y * 1. );
    //u = vec3(.2,-.1,2.8);
    float w = 1.57 + 0.02 - 0.04 * sin( iTime * 8. );
    return ufoSDF( point, u, w, .08 ); 
}

// this is kind of gross.. :-(
int whatsClosest( vec3 point ) {
    int what = 0;
    float d = RAY_MARCH_TOO_FAR;
    float q;
    
    q = planetSDF( point );
    if ( q < d ) {
        what = 1;
        d = q;
    }
    
    q = stars( point );
    if ( q < d ) {
        what = 2;
        d = q;
    }
    
    q = ufo( point );
    if ( q < d ) {
        what = 3;
        d = q;
    }
    return what;
}

float sceneDistance( vec3 point ) {
    float d = planetSDF( point );
    d = min( d, stars( point ) );
    d = min( d, ufo( point ) );   
    return d;
}

float rayMarch( in vec3 origin, in vec3 direction ) {
    float total = .0;
    for ( int i = 0 ; i < RAY_MARCH_STEPS ; i++ ) {
        vec3 point = origin + direction * total;
                
        float current = sceneDistance( point );
        total += current;
        if ( total > RAY_MARCH_TOO_FAR || abs(current) < RAY_MARCH_CLOSE ) {
            break;
        }
    }
    return total;
}

vec3 sceneNormal(vec3 p) {
	float d = sceneDistance(p);
    vec2 e = vec2(RAY_MARCH_CLOSE, .0);
    return normalize( d - vec3(
        sceneDistance(p-e.xyy),
        sceneDistance(p-e.yxy),
        sceneDistance(p-e.yyx))
    );
}

float pointLight( vec3 point, vec4 light ) {
    vec3 normal = sceneNormal( point );
    
    vec3 towardLight = light.xyz - point;
    float toLight = length( towardLight );
    towardLight = normalize( light.xyz - point );

    float diffuse = clamp( dot( normal, towardLight ), 0., 1. );
    
    vec3 lightStart = point + normal * RAY_MARCH_CLOSE * 2.;
    float d = rayMarch( lightStart, towardLight );
    diffuse *= 1. - 0.5 * smoothstep( d * 0.9, d, toLight );

    float lightStrength = .7 + .3 * light.w / dot( toLight, toLight );  
    return diffuse * lightStrength;
}

vec3 colorPoint( vec3 point ) {
    vec4 light    = vec4( .0, 7., 1., 6. );
    float ambient = 0.07;
    float gamma   = 1.33;
    
    float lighting = pointLight( point, light );
    lighting = ( 1. -  ambient ) * gamma * lighting;
    
    float d = dot( point, point );
    
    // ...
        
    vec3 rock = 1. * vec3( .9, .2, .1 );
    vec3 star = 2. * vec3( .9, .9, .3 );
    vec3 ufo  = 2. * vec3( .5, .6, .8 );
    
    vec3 color = rock;
    switch( whatsClosest( point ) ) {
        case 2: color = star; break;
        case 3: color = ufo; break;
    }
    
	return vec3( color * ambient + color * lighting );
}

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
	vec2 uv = ( 2. * gl_FragCoord.xy - iResolution.xy ) / iResolution.y; 
    
    // camera settings
    
    float t = 0. * iTime + 1.57;
	vec3  eye  = vec3( 4. * cos( t ), 4., 4. * sin( t ) );  
    eye = vec3( 0., 0., 4. );
	vec3  look = vec3( .0 );
	float roll = 0.2 * cos( iTime );
    float zoom = 0.3 + 4. * ( 1. - abs( sin( iTime * .66 ) ) );
    zoom = 2.2;

    // setup and use the camera
    
	mat3 camera = makeCamera( eye, look, roll );
    vec3 direction = vec3( uv.xy, zoom );
    direction = normalize( camera * direction );
    
    // do the ray marching (sphere tracing)

    float distance_ = rayMarch( eye, direction );
    float tooFar = step( RAY_MARCH_TOO_FAR, distance_ );
    vec3 point = eye + direction * distance_;
    
	// the end
    vec3 background = vec3(0.);
    vec3 blue = vec3( .0, .0, .9 ); 
    
    vec2 at = uv + cos( iTime * .1 );
    background += blue * (0.1 + 0.9 * noise( at * 4. ) );
    
    background += vec3(.27)*step(0.5,noise(-at*99.));
    
    
    fragColor = vec4( mix( colorPoint( point ), background, tooFar ), 1. );
}