// Copyright Inigo Quilez, 2014 - https://iquilezles.org/
// I am the sole copyright owner of this Work.
// You cannot host, display, distribute or share this Work neither
// as it is or altered, here on Shadertoy or anywhere else, in any
// form including physical and digital. You cannot use this Work in any
// commercial or non-commercial product, website or project. You cannot
// sell this Work and you cannot mint an NFTs of it or train a neural
// network with it without permission. I share this Work for educational
// purposes, and you can link to it, through an URL, proper attribution
// and unmodified screenshot, as part of your educational material. If
// these conditions are too restrictive please contact me and we'll
// definitely work it out.

#define ANTIALIAS 2

#define ANIMATE

//#define FULL_PROCEDURAL

float hash1( float n ) { return fract(sin(n)*43758.5453); }
vec2  hash2( vec2  p ) { p = vec2( dot(p,vec2(127.1,311.7)), dot(p,vec2(269.5,183.3)) ); return fract(sin(p)*43758.5453); }

#ifdef FULL_PROCEDURAL
float noise( in vec2 x )
{
    vec2 p = floor(x);
    vec2 f = fract(x);
    f = f*f*(3.0-2.0*f);
    float n = p.x + p.y*57.0;
    return mix(mix( hash1(n+  0.0), hash1(n+  1.0),f.x),
               mix( hash1(n+ 57.0), hash1(n+ 58.0),f.x),f.y);
}

vec3 texturef( in vec2 p )
{
	vec2 q = p;
	p = p*vec2(6.0,128.0);
	float f = 0.0;
    f += 0.500*noise( p ); p = p*2.02;
    f += 0.250*noise( p ); p = p*2.03;
    f += 0.125*noise( p ); p = p*2.01;
	f /= 0.875;
	
	vec3 col = 0.6 + 0.4*sin( f*2.5 + 1.0+vec3(0.0,0.5,1.0) );
	col *= 0.7 + 0.3*noise( 8.0*q.yx );
	col *= 0.8 + 0.2*clamp(2.0*noise(256.0*q.yx ),0.0,1.0);
    col *= vec3(1.0,0.65,0.5) * 0.85;
    return col;

}
#else
vec3 texturef( in vec2 p )
{
    return texture( iChannel0, p ).xyz;
}
#endif

vec4 voronoi( in vec2 x, out vec2 resUV, out float resOcc )
{
    vec2 n = floor( x );
    vec2 f = fract( x );

	vec2 uv = vec2(0.0);
	vec4 m = vec4( 8.0 );
	float m2 = 9.0;
    for( int j=-2; j<=2; j++ )
    for( int i=-2; i<=2; i++ )
    {
        vec2 g = vec2( float(i),float(j) );
        vec2 o = hash2( n + g );
		#ifdef ANIMATE
        o = 0.5 + 0.5*sin( 0.5*iTime + 6.2831*o );
        #endif	
		vec2 r = g - f + o;

        // distance and tex coordinates		
        vec2 u = vec2( dot( r, vec2(0.5, 0.866) ), 
					   dot( r, vec2(0.5,-0.866) ) );
		vec2 d = vec2( -r.y, 1.0 );
		float h = 0.5*abs(r.x)+0.866*r.y;
		if( h > 0.0 ) 
		{ 
			u = vec2( h, r.x );
			d = vec2( 0.866*abs(r.x)+0.5*r.y, 0.5*step(0.0,r.x) ); 
		}
		
        if( d.x<m.x )
        {
			m2 = m.x;
            m.x = d.x;
            m.y = dot(n+g,vec2(7.0,113.0) );
			m.z = d.y;
			m.w = max(r.y,0.0);
			uv = u;
        }
        else if( d.x<m2 )
		{
			m2 = d.x;
        }
			
    }
	resUV = uv;
	resOcc = m2-m.x;
    return m;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec3 tot = vec3(0.0);
    
    #ifdef ANTIALIAS
    for( int j=0; j<ANTIALIAS; j++ )
    for( int i=0; i<ANTIALIAS; i++ )
    {
        vec2 off = vec2(float(i),float(j))/float(ANTIALIAS);
    #else
        vec2 off = vec2(0.0);
    #endif        
		
        vec2  q = (fragCoord+off)/iResolution.xy;
        vec2 p = -1.0 + 2.0*q;
        p.x *= iResolution.x/iResolution.y;
        vec2 uv = vec2(0.0);

        //vec2 dp = 2.0*vec2( 1.0/iResolution.y, 0.0 );
        vec2 dp = vec2( 0.004, 0.0 );

        float occ = 0.0;
        vec4  c = voronoi( 3.5*p, uv, occ );


        vec2 tmp; float tmp2;
        float d = abs(voronoi( 3.5*(p+dp.xy), tmp, tmp2 ).z - voronoi( 3.5*(p-dp.xy), tmp, tmp2 ).z ) + 
                  abs(voronoi( 3.5*(p+dp.yx), tmp, tmp2 ).z - voronoi( 3.5*(p-dp.yx), tmp, tmp2 ).z );

        // color
        c.y = hash1( c.y );
        vec3 col = 0.6 + 0.4*sin( c.y*2.5 + 1.0+vec3(0.0,0.5,1.0) );
        col *= 0.4 + 0.6*smoothstep( 0.1,0.25,abs(hash1(c.y+0.413)-0.5) );

        // texture	
        col *= 1.7*pow(texturef( uv ), vec3(0.4) );

        // lighting
        col *= clamp( 0.65 + c.z*0.35, 0.0, 1.0 );
        col *= sqrt(clamp(1.0 - c.x,0.0,1.0));
        col *= clamp(1.0-0.3*c.w, 0.0, 1.0 );
        col *= 0.6 + 0.4*vec3( sqrt(clamp(8.0*occ,0.0,1.0)) );

        // patern
        if( hash1(c.y)>0.6 )
        {
        float pa = sin(c.w+(1.0-0.7*c.y)*25.0*uv.y)*sin((1.0-0.7*c.y)*25.0*uv.x);
        col *= smoothstep( 0.0, 0.3, abs(pa-0.6) );
        col *= 1.0 - 0.35*smoothstep( 0.6, 0.7, pa );
        }

        // wireframe	
        col *= 1.0 - d;

        // tint 
        col = pow( col, vec3(1.0,1.0,0.8) );	

        // vigneting	
        col *= 0.7 + 0.3*pow( 16.0*q.x*q.y*(1.0-q.x)*(1.0-q.y), 0.2 );

        tot += col;
    }
    
    #ifdef ANTIALIAS
    tot /= float(ANTIALIAS*ANTIALIAS);
	#endif
    
	fragColor = vec4( tot, 1.0 );
}