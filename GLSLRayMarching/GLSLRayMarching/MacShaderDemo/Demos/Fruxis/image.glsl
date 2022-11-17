// Copyright Inigo Quilez, 2013 - https://iquilezles.org/
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

#if HW_PERFORMANCE==0
#define AA 1
#else
#define AA 2
#endif

//#define USE_REFLECTIONS

vec3 hash3( float n )
{
    return fract(sin(vec3(n,n+1.0,n+2.0))*vec3(43758.5453123,22578.1459123,19642.3490423));
}


float noise( in vec3 x )
{
    vec3 p = floor(x);
    vec3 f = fract(x);
	f = f*f*(3.0-2.0*f);
	
	vec2 uv = (p.xy+vec2(37.0,17.0)*p.z) + f.xy;
	vec2 rg = textureLod( iChannel0, (uv+ 0.5)/256.0, 0.0 ).yx;
	return mix( rg.x, rg.y, f.z );
}

const mat2 m2 = mat2( 0.80, -0.60, 0.60, 0.80 );

float fbm4( vec3 p )
{
    float f = 0.0;

    f += 0.5000*noise( p ); p = p*2.02;
    f += 0.2500*noise( p ); p = p*2.03;
    f += 0.1250*noise( p ); ;

    return f/0.9375;
}


#define ZERO (min(iFrame,0))

float sdBox( in vec3 p, vec3 b )
{
  vec3 d = abs(p) - b;
  return min(max(d.x,max(d.y,d.z)),0.0) + length(max(d,0.0));
}

// https://iquilezles.org/articles/smin
float smax( float a, float b, float k )
{
    float h = max(k-abs(a-b),0.0);
    return max(a, b) + h*h*0.25/k;
}

//===========================================================================================
//===========================================================================================

float suelo( in vec3 pos, out vec3 uvw )
{
    uvw = pos;
    return pos.y;
}

float pared( in vec3 pos, out vec3 uvw )
{
    uvw = 4.0*pos;

    float d1 = 0.6 + pos.z;
    float d2 = 0.6 + pos.x;
    d1 = min(d1,d2);

    d1 = min( d1, sdBox( pos-vec3(0.0,2.0,0.0), vec3(1.5,0.05,1.5) ) );

    return d1;
}


float melon( in vec3 p, out vec3 uvw )
{
    vec3 c = p - vec3(0.0,0.215,0.0);

    vec3 q = 3.0*c*vec3(1.0,1.5,1.5);
    uvw = 3.0*c;

    float r = 1.0 - 0.007*sin(30.0*(-c.x+c.y-c.z));
    return 0.65*(length(q) - r)/3.0;
}

float manzana( in vec3 p, out vec3 uvw )
{
    vec3 q = p - vec3(0.5,0.1,0.5);
    float r = length(q.xz);
    q.y += 0.05*(1.0-clamp(r/0.1,0.0,1.0));
    q.y -= 0.03*(1.0-smoothstep(0.004,0.005,r));
    uvw = 10.0*q;
    return 0.4*(length(10.0*q) - 1.0)/10.0;
}


float uvas( in vec3 p, out vec3 uvw )
{
    vec3 q = p - vec3(-0.1,0.1,0.6);
    uvw = 10.0*q;
  
    float d1 = length(q-vec3(-0.09,0.10,-0.07)) - 0.12;
    float d2 = length(q-vec3( 0.11,0.05, 0.00)) - 0.09;
    float d3 = length(q-vec3(-0.07,0.03, 0.10)) - 0.10;
  
    return min(d1,min(d2,d3));
}



float lemon( in vec3 p, out vec3 uvw )
{
    vec3 q = p - vec3(0.7,0.06,0.2);
    uvw = 10.0*q;
    float s = 1.35;
    float r = clamp( (abs(q.x)-0.00)/(0.077-0.00), 0.0, 1.0 );
    s += 2.5* pow(r,24.0);
    q *= vec3(1.0,s,s);
    return 0.5*(length(12.0*q) - 1.0)/(12.0*s);
}

float jarron( in vec3 p, out vec3 uvw )
{
    vec3 q = p - vec3(-0.1,0.28,0.6);
    uvw = q;

    float d1 = length(q)-1.00/3.5;
    d1 = abs(d1+0.025/3.5)-0.025/3.5;
    
    float d2 = q.y + 0.1;

    //return max(  d1, d2 );
    return smax( d1, d2, 0.005 );
}


float mantelito( in vec3 p, out vec3 uvw )
{
    vec3 q = p - vec3(-0.1,0.001,0.65);

    q.xz += 0.1*vec2( 0.7*sin(6.0*q.z+2.0)+0.3*sin(12.0*q.x+5.0),
                      0.7*sin(6.0*q.x+0.7)+0.3*sin(12.0*q.z+3.0) );

    q.xz = m2*q.xz;
    uvw = q;

    q.y -= 0.008*(0.5-0.5*sin( 40.0*q.x )*sin( 5.0*q.z ));

    return length(max(abs(q)-vec3(0.3,0.001,0.3),0.0))-0.0005;
}


float botella( in vec3 p, out vec3 uvw )
{
    vec3 q = p - vec3(-0.35,0.0,0.3);

    vec2 w = vec2( length(q.xz), q.y );
  
    float d1 = length( q - vec3(0.0, 0.8,0.0) );
    float d2 = length( q - vec3(0.0,-0.1,0.0) );

    uvw = q;
  
    float r = 1.0 - 0.8*pow(smoothstep( 0.5, 0.6, q.y ),4.0);
    r += 0.1 * smoothstep( 0.650, 0.66, q.y );
    r *= 1.0 - smoothstep( 0.675, 0.68, q.y );
  
    return min( min( d1, d2),(w.x - 0.11*r)*0.5 );
}

//======================

vec4 manzanaColor( in vec3 pos, in vec3 nor, out vec3 bnor )
{
    float spe = 1.0;
    bnor = vec3( 0.0 );

    float a = atan(pos.x,pos.z);
    float r = length(pos.xz);

    // red
    vec3 col = vec3(1.0,0.05,0.0);

    // green
    float f = smoothstep( 0.2, 0.9, fbm4(pos.xzy*0.8) );
    col = mix( col, vec3(1.0,0.6,0.1), f );

    // dirty
    col *= 0.75+0.25*fbm4(pos*4.0);

    // frekles
    f = smoothstep( 0.6, 1.0, fbm4(pos*48.0) );
    col = mix( col, vec3(0.9,0.9,0.6), f*0.5 );

    // stripes
    f = smoothstep( -0.6,1.0, noise( vec3(a*7.0 + pos.z,0.5*pos.y,pos.x)*2.0));
    f *= smoothstep(-0.5,1.0,pos.y + 0.75*(noise(4.0*pos.zyx)-0.5) );
    col = mix( col, vec3(0.4,0.2,0.0), 0.75*f );
    spe *= 1.0-f;

    // top
    f = 1.0-smoothstep( 0.14, 0.2, r );
    col = mix( col, vec3(0.2,0.18,0.15)*0.5, f );

	return vec4(0.5*col,spe);

}

float orangesBump( in vec3 pos )
{
    float f = fbm4( pos*16.0 );
    return f*f;
}
vec4 orangesColor( in vec3 pos, in vec3 nor, out vec3 bnor )
{
    bnor = vec3( 0.0 );

    vec2 e = vec2( 0.001, 0.0 );
    float re = orangesBump( pos );
    bnor = 0.07*normalize( vec3(orangesBump( pos+e.xyy ) - re,
                                orangesBump( pos+e.yxy ) - re,
                                orangesBump( pos+e.yyx ) - re ) );
	
    vec3 col = vec3(0.7,0.2,0.0);

    col = mix( col, vec3(0.7,0.35,0.05), fbm4( pos ) );

    return vec4( 0.6*col, 1.0 );
}

vec4 mantelitoColor( in vec3 pos, in vec3 nor, out vec3 bnor )
{
     bnor = vec3( 0.0 );


    vec3 col = vec3(1.0,0.9,0.8);
    float f = smoothstep( 0.0, 0.7, sin(180.0*pos.x) );
    col = mix( col, vec3(0.7,0.4,0.0), f );

    f = smoothstep( 0.0, 0.7, sin(180.0*pos.z)*sign(sin(180.0*pos.x)) );
    col = mix( col, vec3(0.0,0.2,0.6), f );

    return vec4( 0.3*col, 0.0 );
}

float lemonBump( in vec3 pos )
{
     return fbm4( pos*24.0 );
}

vec4 lemonColor( in vec3 pos, in vec3 nor, out vec3 bnor )
{
    bnor = vec3( 0.0 );

    vec2 e = vec2( 0.001, 0.0 );
    float re = lemonBump( pos );
    bnor = 0.07*normalize( vec3(lemonBump( pos+e.xyy ) - re,
                               lemonBump( pos+e.yxy ) - re,
                               lemonBump( pos+e.yyx ) - re ) );

	vec3 col = vec3(1.0,0.8,0.0);

    col = mix( col, vec3(0.3,0.3,0.02), smoothstep( 0.75, 0.82, abs(pos.x) ) );

    return vec4( 0.3*col, 1.0 );
}

vec4 botleColor( in vec3 pos, in vec3 nor, out vec3 bnor )
{
	float spe = 1.0;
    bnor = vec3( 0.0 );

    vec3 col = 0.2*vec3(0.6,0.3,0.3);

    float f = smoothstep( 0.2, 0.21, pos.y ) - smoothstep( 0.39, 0.40, pos.y );
    f *= smoothstep( 0.0, 0.01, pos.z );
	col = mix( col, vec3(0.13,0.12,0.10), f );
    spe *= 1.0-f;
    
    float g = (smoothstep( 0.220, 0.225, pos.y ) - smoothstep( 0.375, 0.38, pos.y ))*smoothstep( 0.010, 0.02, pos.z );
    float h = (smoothstep( 0.230, 0.235, pos.y ) - smoothstep( 0.365, 0.37, pos.y ))*smoothstep( 0.025, 0.03, pos.z );
    col *= 1.0-0.7*(g-h);

    return vec4( col*0.6, spe );
}


vec4 melonColor( in vec3 pos, in vec3 nor, out vec3 bnor )
{
    bnor = vec3( 0.0 );

    float a = atan(pos.y,pos.z);
    float r = length(pos.xz);

    // lightGreenBase
    vec3 col = vec3(0.4,.8,0.1);

    // darkGreenBase
    float f = smoothstep( -0.7, 0.6, fbm4(pos*4.0) );
    col = mix( col, vec3(0.01,.3,0.05), f );

    // dirty
    col *= 0.8+0.2*smoothstep( -1.0, 1.0, fbm4(pos*4.0) );

    // dirty
    col *= 0.5+0.5*smoothstep( -0.44, -0.3, fbm4(pos*64.0) );

    // frekles
    f = smoothstep( 0.3, 0.6, fbm4(pos*60.0) );
    col = mix( col, vec3(0.71,0.85,0.4), f*0.4 );

    // stripes
    float q = 0.5 + 0.5*fbm4(30.0*pos);
    f = fbm4( vec3(a*10.0 + pos.z + 1.4*q,1.5*pos.y,3.5*pos.x)*1.5);
    f = smoothstep( -0.5,0.7,f);
    col = mix( col, vec3(0.01,0.1,0.01), f );

    return vec4( 1.2*col, 1.0 );
}


float floorBump( in vec2 pos, out vec2 id )
{
    float w  = 0.015;
    float y  = mod( pos.x*8.0, 1.0 );
    float iy = floor( pos.x*8.0 );
    float x  = mod( pos.y*1.0 + sin(iy)*8.0, 1.0 );
    float f  = smoothstep( 0.0, w,     y ) - smoothstep( 1.0-w,     1.0, y );
          f *= smoothstep( 0.0, w/8.0, x ) - smoothstep( 1.0-w/8.0, 1.0, x );
    id = vec2( iy, floor(pos.y*1.0 + sin(iy)*8.0) );
    return f;
}

vec4 floorColor( in vec3 pos, in vec3 nor, out vec3 bnor )
{
    bnor = vec3( 0.0 );

    vec2 id;
    vec2 tmp;
    float er = floorBump( pos.xz, id );

	
    vec2 e = vec2( 0.005, 0.0 );
    bnor = vec3( -(floorBump( pos.xz+e.xy, tmp ) - er), 150.0*e.x,
                 -(floorBump( pos.xz+e.yx, tmp ) - er) );
    bnor = normalize(bnor);


    vec3 col = vec3(0.6,0.4,0.3)*0.6;

	float f = 0.5+0.5*fbm4( 16.0*pos*vec3(6.0,0.0,0.5)+vec3(id,0.0) );
    col = mix( col, vec3(0.4,0.2,0.1)*0.56, f );

    col *= 0.85 + 0.15*fbm4( 8.0*pos );
    col *= 0.50 + 0.50*er;

    col *= 1.0 + 0.2*sin(32.0*(id.x-id.y));
    col += 0.01*sin( vec3(0.0,1.0,2.0)+32.0*(id.x+id.y) );

    return vec4( col, 2.0 );
}


float paredBump( in vec2 pos )
{
    float y = mod( pos.y*1.0, 1.0 );
    float f = smoothstep( 0.0, 0.025, y ) - smoothstep( 0.975, 1.0, y );
    float ox = 0.5*mod(floor(pos.y*1.0),2.0);
    float x = mod( pos.x*1.0 + ox, 1.0 );
    f *= smoothstep( 0.0, 0.025, x ) - smoothstep( 0.975, 1.0, x );

    return f;
}

vec4 paredColor( in vec3 pos, in vec3 nor, out vec3 bnor )
{
	float spe = 1.0;
    bnor = vec3( 0.0 );

    vec2 qpos = pos.xy;
    if( abs(nor.x)>0.5 ) qpos = pos.zy;

	
    vec2 e = vec2( 0.01, 0.0 );
    float er = paredBump( qpos );
    bnor = vec3(-(paredBump( qpos+e.xy ) - er),
                -(paredBump( qpos+e.yx ) - er),
                1.0*e.x );
    if( abs(nor.x)>0.5 ) bnor=bnor.zyx;
    bnor = 1.0*normalize( bnor );

	
	
    vec3 col = vec3(1.0,0.8,0.7);
	
	col *= 0.9+0.1*fbm4( pos*vec3(20.0,0.0,20.0) );

    float y = mod( pos.y*1.0, 1.0 );
    float f = smoothstep( 0.5, 0.9, y );

    f *= fbm4(pos*2.0);
    spe *= 1.0-f;
    vec3 dirt = col*0.05;
    col = mix( col, dirt, f );

    return vec4( 0.6*col, spe );
}

float jarronBump( in vec3 pos )
{
     return 0.9*fbm4( pos*vec3( 0.0,48.0, 0.0) ) +
            0.1*fbm4( pos*128.0 );
}



vec4 jarronColor( in vec3 pos, in vec3 nor, out vec3 bnor )
{
    bnor = vec3( 0.0 );
/*
    vec2 e = vec2( 0.001, 0.0 );

    float re = jarronBump( pos );
    bnor = 0.2*normalize( vec3(jarronBump( pos+e.xyy ) - re,
                               jarronBump( pos+e.yxy ) - re,
                               jarronBump( pos+e.yyx ) - re ) );
*/
    vec3 col = vec3(0.5,0.3,0.1);
	
    col *= 0.2 + 0.8*smoothstep(0.0,1.0,fbm4( pos*vec3(0.0,24.0,0.0) ));

    return vec4( 0.4*col, 0.5 );
}

float map( in vec3 p, out vec4 muvw )
{
    float resT = 1000.0;
    vec4  resM = vec4(-1.0);

    vec3 mati = vec3(0.0);

	float dis = suelo( p, mati );
	if( dis<resT ) { resT=dis; resM=vec4(1.0,mati); }

	dis = pared( p, mati );
	if( dis<resT ) { resT=dis; resM=vec4(5.0,mati); }

	dis = jarron( p, mati );
	if( dis<resT ) { resT=dis; resM=vec4(4.0,mati); }

	dis = mantelito( p, mati );
	if( dis<resT ) { resT=dis; resM=vec4(9.0,mati); }

	dis = melon( p, mati );
	if( dis<resT ) { resT=dis; resM=vec4(2.0,mati); }

	dis = manzana( p, mati );
	if( dis<resT ) { resT=dis; resM=vec4(3.0,mati); }

	dis = lemon( p, mati );
	if( dis<resT ) { resT=dis; resM=vec4(6.0,mati); }

	dis = botella( p, mati );
	if( dis<resT ) { resT=dis; resM=vec4(7.0,mati); }

	dis = uvas( p, mati );
	if( dis<resT ) { resT=dis; resM=vec4(8.0,mati); }

    muvw = resM;
    return resT;
}

vec4 calcColor( in vec4 muvw, in vec3 nor, out vec3 bnor )
{
    vec4 surfaceColor = vec4(0.0);
         if( muvw.x < 1.5 ) surfaceColor = floorColor(     muvw.yzw, nor, bnor );
    else if( muvw.x < 2.5 ) surfaceColor = melonColor(     muvw.yzw, nor, bnor );
    else if( muvw.x < 3.5 ) surfaceColor = manzanaColor(   muvw.yzw, nor, bnor );
    else if( muvw.x < 4.5 ) surfaceColor = jarronColor(    muvw.yzw, nor, bnor );
    else if( muvw.x < 5.5 ) surfaceColor = paredColor(     muvw.yzw, nor, bnor );
    else if( muvw.x < 6.5 ) surfaceColor = lemonColor(     muvw.yzw, nor, bnor );
    else if( muvw.x < 7.5 ) surfaceColor = botleColor(     muvw.yzw, nor, bnor );
    else if( muvw.x < 8.5 ) surfaceColor = orangesColor(   muvw.yzw, nor, bnor );
    else                    surfaceColor = mantelitoColor( muvw.yzw, nor, bnor );
    return surfaceColor;
}

//===================================================================

float intersect( in vec3 ro, in vec3 rd, out vec4 info )
{
    float t = 0.0;
    for( int i=0; i<128; i++ )
    {
	    float h = map( ro+rd*t, info );
        if( (h)<0.001 ) break;
        t += h*0.9;
    }

    return t;
}

vec3 calcNormal( in vec3 pos )
{
    vec4 kk;
    vec2 e = vec2(1.0,-1.0)*0.5773*0.0005;
    return normalize( e.xyy*map( pos + e.xyy, kk ) + 
					  e.yyx*map( pos + e.yyx, kk ) + 
					  e.yxy*map( pos + e.yxy, kk ) + 
					  e.xxx*map( pos + e.xxx, kk ) );
}

float softshadow( in vec3 ro, in vec3 rd, float k )
{
    float res = 1.0;
    float t = 0.001;
	float h = 1.0;
	vec4 kk;
    for( int i=0; i<64; i++ )
    {
        h = map(ro + rd*t,kk);
        res = min( res, smoothstep(0.0,1.0,k*h/t) );
        if( res<0.001 ) break;
		t += clamp( h, 0.01, 1.0 );
    }
    return clamp(res,0.0,1.0);
}

float calcAO( in vec3 pos, in vec3 nor, in vec2 px )
{
	float off = 0.1*dot( px, vec2(1.2,5.3) );
	float totao = 0.0;
    for( int i=ZERO; i<20; i++ )
    {
		vec4 kk;
		vec3 aopos = -1.0+2.0*hash3(float(i)*213.47 + off);
		aopos = aopos*aopos*aopos;
		aopos *= sign( dot(aopos,nor) );
        totao += clamp( map( pos + nor*0.015 + 0.15*aopos, kk )*48.0, 0.0, 1.0 );
    }
	totao /= 20.0;
	
    return clamp( totao*totao*1.0, 0.0, 1.0 );
}


const vec3 rlight = vec3(3.62, 2.99, 0.71 );
vec3 lig = normalize(rlight);

float directLighting( in vec3 pos, in vec3 nor )
{

    vec3 ww = lig;
    vec3 uu = normalize( cross(ww, vec3(0.0,1.0,0.0)) );
    vec3 vv =          ( cross(uu,ww) );


    float shadowIntensity = softshadow( pos+0.001*nor, lig, 10.0 );

    vec3 toLight = rlight - pos;
    float att = smoothstep( 0.985, 0.997, dot(normalize(toLight),lig) );

    vec3 pp = pos - ww*dot(pos,ww);
    vec2 uv = vec2( dot(pp,uu), dot(pp,vv) );
    float pat = smoothstep( -0.5, 0.5, sin(10.0*uv.y) );

    return pat * att * shadowIntensity;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    //-----------------------------------------------------
    // camera
    //-----------------------------------------------------
	
    // position camera
	float an = 2.0*sin(0.7+0.5*iTime);// + step(0.0,iMouse.z)*10.0*iMouse.x/iResolution.x;
	vec3 ro = vec3(0.8 + 0.2*sin(2.0+an),0.4,1.1 + 0.25*sin(an));
    vec3 ta = vec3(-0.2,0.1,0.0);
    // camera matrix
    vec3 ww = normalize( ta - ro );
    vec3 uu = normalize( cross(ww,vec3(0.0,1.0,0.0) ) );
    vec3 vv = normalize( cross(uu,ww));

    //-----------------------------------------------------
	// render
    //-----------------------------------------------------
    vec3 tot = vec3(0.0);
    
    #if AA>1
    for( int m=ZERO; m<AA; m++ )
    for( int n=ZERO; n<AA; n++ )
    {
        // pixel coordinates
        vec2 o = vec2(float(m),float(n)) / float(AA) - 0.5;
        vec2 px = fragCoord+o;
        #else    
        vec2 px = fragCoord;
        #endif
        vec2 p = (2.0*px-iResolution.xy)/iResolution.y;
        // create view ray
        vec3 rd = normalize( p.x*uu + p.y*vv + 2.0*ww );

		vec3 rq = ro;
        vec3 col = vec3(0.0);
        vec3 fac = vec3(1.0);
        #ifdef USE_REFLECTIONS
        for( int j=ZERO; j<2; j++ )
        #endif
        {
            // raymarch
            vec4 info;
            float t = intersect(rq,rd,info);
            #ifdef USE_REFLECTIONS
            if( info.x<-0.5 )
                break;
            #endif		

            // geometry
            vec3 pos = rq + t*rd;
            vec3 nor = calcNormal(pos);
            vec3 ref = reflect( rd, nor );
            vec3 hal = normalize(lig-rd);

            vec3 bno = vec3(0.0);
            vec4 maa = calcColor( info, nor, bno );
            nor = normalize( nor + bno );

            // lighting
            float occ = calcAO(pos,nor,px);
            float bfl = clamp(-nor.y*0.8+0.2,0.0,1.0) * pow(clamp(1.0-pos.y/1.0,0.0,1.0),2.0);
            float amb = 1.0;
            float bce = clamp( nor.y*0.8+0.2,0.0,1.0);
            float dif = max(dot(nor,lig),0.0);
            float bac = max(dot(nor,normalize(vec3(-lig.x,0.0,-lig.z))),0.0);
            float sha = directLighting( pos, nor )*(0.5+0.5*occ);
            float fre = pow( clamp( 1.0 + dot(nor,rd), 0.0, 1.0 ), 3.0 );
            float spe = pow(clamp(dot(nor,hal),0.0,1.0),8.0);
			spe *= 0.04+0.96*pow( clamp( dot(lig,hal), 0.0, 1.0), 5.0 );
            float att = 0.1 + 0.9*smoothstep( 0.975, 0.997, dot(normalize(rlight - pos),lig) );

            // lights
            vec3 lin = vec3(0.0);
            lin += 2.30*dif*vec3(2.50,1.80,1.30)*pow(vec3(sha),vec3(1.0,1.3,1.6));
            lin += 1.00*bac*vec3(0.40,0.35,0.30)*occ*att;
            lin += 1.00*bfl*vec3(0.50+att*0.5,0.30,0.10)*occ*att;
            lin += 1.00*bce*vec3(0.30,0.20,0.20)*occ*att;
            lin += 1.00*amb*vec3(0.08,0.10,0.12)*occ*att;
            lin += 1.00*fre*vec3(3.00,3.00,3.00)*occ*att*(0.25+0.75*dif*sha);
            lin += 1.00*spe*vec3(3.00,3.00,3.00)*occ*att*dif*sha*maa.w;

            // surface-light interacion
            col += fac * (maa.xyz*lin + spe*maa.w*occ*sha*dif*0.25);

            #ifdef USE_REFLECTIONS
            fac *= maa.xyz*maa.w*spe;
            rq = pos + nor*0.01;
            rd = normalize(ref + 0.02*(2.0*hash3(p.x*11.0+p.y*7.0)-1.0));
            #endif	
        }

        // gamma
	    col = pow( clamp(col,0.0,1.0), vec3(0.4545) );

	    tot += col;
    #if AA>1
    }
    tot /= float(AA*AA);
    #endif

	//-----------------------------------------------------
	// postprocessing
    //-----------------------------------------------------

	// contrast
    tot = tot*0.6 + 0.4*tot*tot*(3.0-2.0*tot);
	
	// saturation
    tot = mix( tot, vec3(dot(tot,vec3(0.33))), 0.2 );
	
    // curves
    tot = pow(tot,vec3(0.85,0.95,1.0));

	// vigneting	
	vec2 q = fragCoord.xy / iResolution.xy;
    tot *= 0.7 + 0.3*pow( 16.0*q.x*q.y*(1.0-q.x)*(1.0-q.y), 0.15 );

    fragColor = vec4( tot, 1.0 );
}
