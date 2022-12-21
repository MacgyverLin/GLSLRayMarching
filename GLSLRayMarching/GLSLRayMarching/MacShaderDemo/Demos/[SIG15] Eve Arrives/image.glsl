// Created by inigo quilez - iq/2015
// https://www.youtube.com/c/InigoQuilez
// https://iquilezles.org/


// Unfortunatelly, too similar to Dave Hoskins' shader. 
// But it's one of my fav scenes from Wall-E, https://www.youtube.com/watch?v=vkAjOPqTghg
// (well, the shader is only vagely inspired in that sene really)


// number of samples (for blurring)
//#define HIGH_QUALITY 


#ifdef HIGH_QUALITY
  #define NS 8
#else
  #if HW_PERFORMANCE==0
    #define NS 1
  #else
    #define NS 2
  #endif
#endif


//------------ primitives ------------


float sdCapsule( vec3 p, vec3 a, vec3 b, float r )
{
	vec3 pa = p-a, ba = b-a;
	float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
	return length( pa - ba*h ) - r;
}

float sdSphere( in vec3 p, in vec4 s )
{
    return length(p-s.xyz) - s.w;
}

float sdEllipsoid( in vec3 p, in vec3 c, in vec3 r )
{
    p = p-c;
    float k0 = length(p/r);
    float k1 = length(p/(r*r));
    return k0*(k0-1.0)/k1;
}

float udRoundBox( vec3 p, vec3 b, float r )
{
  return length(max(abs(p)-b,0.0))-r;
}

//------------ operators ------------

float smin( float a, float b, float k )
{
	float h = clamp( 0.5 + 0.5*(b-a)/k, 0.0, 1.0 );
	return mix( b, a, h ) - k*h*(1.0-h);
}

float smax( float a, float b, float k )
{
	float h = clamp( 0.5 + 0.5*(b-a)/k, 0.0, 1.0 );
	return mix( a, b, h ) + k*h*(1.0-h);
}

vec2 minx( in vec2 a, in vec2 b )
{
    return (a.x<b.x)?a:b;
}

//------------ maths ------------

mat4 matRotate( in vec3 xyz )
{
    vec3 si = sin(xyz);
    vec3 co = cos(xyz);

	return mat4( co.y*co.z,                co.y*si.z,               -si.y,       0.0,
                 si.x*si.y*co.z-co.x*si.z, si.x*si.y*si.z+co.x*co.z, si.x*co.y,  0.0,
                 co.x*si.y*co.z+si.x*si.z, co.x*si.y*si.z-si.x*co.z, co.x*co.y,  0.0,
			     0.0,                      0.0,                      0.0,        1.0 );
}

mat4 matTranslate( float x, float y, float z )
{
    return mat4( 1.0, 0.0, 0.0, 0.0,
				 0.0, 1.0, 0.0, 0.0,
				 0.0, 0.0, 1.0, 0.0,
				 x,   y,   z,   1.0 );
}

mat4 matInverse( in mat4 m )
{
	return mat4(
        m[0][0], m[1][0], m[2][0], 0.0,
        m[0][1], m[1][1], m[2][1], 0.0,
        m[0][2], m[1][2], m[2][2], 0.0,
        -dot(m[0].xyz,m[3].xyz),
        -dot(m[1].xyz,m[3].xyz),
        -dot(m[2].xyz,m[3].xyz),
        1.0 );
}

//--------------------------------------------

float hash( float n )
{
    return fract(sin(n)*1751.5453);
}

//--------------------------------------------


mat4 mtxHead;

vec2 map( vec3 p )
{
    vec3 q = p; q.x = abs(q.x);
    vec3 hp = (mtxHead*vec4(p,1.0)).xyz;

    // body
    p.yz = mat2(0.98,-0.2,0.2,0.98)*p.yz;
    
    float d1 = sdEllipsoid( p, vec3(0.0,0.15,0.0), vec3(0.41,0.83,0.41) );
    float d2 = sdSphere( p, vec4(0.0,1.4,0.0,1.2) );
    float d9 = sdCapsule( q, vec3(0.5,-0.6,0.02), vec3(0.45,0.07,-0.02), 0.15 );
    float body = smax( d1, -d2, 0.03 );
    body = smax( body, -d9, 0.01 );
    
    
    // head
    float d3 = sdSphere( hp, vec4(0.0,0.0,0.0,0.4) );
    float d4 = sdSphere( hp, vec4(0.0,0.45,0.008,0.65) );
    float head = smax( d3, d4, 0.05 );
    // head hole    
    float d5 = sdEllipsoid( hp, vec3(0.0,0.0,0.4), vec3(0.48,0.3,0.2) );
    //d5 = smax( d5, sdSphere( hp, vec4(0.0,0.34,0.2, 0.46 )), 0.07 );
    d5 = smax( d5, sdSphere( hp, vec4(0.0,0.49,0.2, 0.6 )), 0.07 );
    head = smax( head, -d5, 0.025 );
    
    // face
    float d6 = sdSphere( hp, vec4(0.0,0.04,-0.05,0.41) );
    float m2 = smax(d6,d5,0.01);

    
    // arm
    float d7 = sdEllipsoid( q, vec3(0.5,-0.15,0.0), vec3(0.1,0.35,0.1) );
    float d8 = sdEllipsoid( q, vec3(0.54,-0.15,0.0), vec3(0.1,0.35,0.1) );
//    d8 = sdCapsule( q, vec3(0.6,-0.6,0.02), vec3(0.55,0.09,-0.02), 0.15 );
    d7 = max( d7, d8 );
    float arm = d7;
    

    float m1 = min( min( body, head ), arm );
                        
    return minx( vec2(m1,0.0),
                 vec2(m2,1.0) );
}

vec3 calcNormal( in vec3 pos, in float eps )
{
    vec2 e = vec2(1.0,-1.0)*0.5773*eps;
    return normalize( e.xyy*map( pos + e.xyy ).x + 
					  e.yyx*map( pos + e.yyx ).x + 
					  e.yxy*map( pos + e.yxy ).x + 
					  e.xxx*map( pos + e.xxx ).x );
}

float calcAO( in vec3 pos, in vec3 nor )
{
	float occ = 0.0;
    for( int i=0; i<8; i++ )
    {
        //float h = 0.01 + 0.22*float(i)/7.0;
        float h = 0.01 + 0.21*float(i)/7.0;
        occ += (h-map( pos + h*nor )).x;
    }
    return clamp( 1.0 - 5.8*occ/8.0, 0.0, 1.0 );    
}

float calcSoftshadow( in vec3 ro, in vec3 rd, float k )
{
    float res = 1.0;
    float t = 0.01;
#ifdef HIGH_QUALITY
    for( int i=0; i<64; i++ )
#else
    for( int i=0; i<16; i++ )
#endif    
    {
        float h = map(ro + rd*t ).x;
        res = min( res, smoothstep(0.0,1.0,k*h/t) );
#ifdef HIGH_QUALITY
        t += clamp( h, 0.01, 0.025 );
#else        
        t += clamp( h, 0.04, 0.1 );
#endif        
		if( res<0.01 ) break;
    }
    
    return clamp(res,0.0,1.0);
}


vec3 sundir = normalize( vec3(1.0,0.3,-0.5) );

vec3 shade( in vec3 ro, in vec3 rd, in float t, float m )
{
    float eps = 0.001;
    vec3 pos = ro + t*rd;
    vec3 nor = calcNormal( pos, eps );
    vec3 ref = reflect( rd, nor );
    
    vec3 mate = vec3(1.0,1.0,1.0);
    
    if( m<0.5 )
    {
        mate = vec3(0.7);
    }
	else
    {
        mate = vec3(0.0,0.0,0.0);
        
        vec2 uv = (mtxHead * vec4(pos,1.0)).xy;

        uv.x = abs(uv.x);
        uv -= vec2(0.11,0.565-0.5);
        vec2 st  = uv;
        uv = mat2(0.9,-0.4,0.4,0.9)*uv;
        vec3 eye = vec3(0.02,0.2,0.9)*1.9;
        eye *= 0.9 + 0.1*sin(512.0*st.x + sin(512.0*st.y));
        
        float eyesN = 1.0-smoothstep( 0.03, 0.06, length(uv * vec2(0.7,1.0)) );
        float eyesB = 1.0-smoothstep( 0.00,0.008,abs(st.y));
        float bl = smoothstep( 0.9,0.91, sin(10.0*iTime)*sin(3.0*iTime) );
        float eyes = mix( eyesN, eyesB, bl );
        mate = mix( mate, eye, eyes );
        
        mate += (0.01+mate)*0.9*smoothstep(-0.1,0.1,sin(st.y*400.0));
    }
    
    vec3 hal = normalize( sundir - rd );
    
    float fre = clamp( 1.0 + dot(nor,rd), 0.0, 1.0 );
    float occ = calcAO( pos, nor );

    float bak = clamp( dot(nor,normalize(vec3(-sundir.x,0.0,-sundir.z))), 0.0, 1.0 );
    float dif = clamp( dot(nor,sundir), 0.0, 1.0 );
    float spe = clamp( dot(nor,hal), 0.0, 1.0 );
    float sha = calcSoftshadow( pos, sundir, 8.0 ); 
    dif *= sha;

    vec3 col = 1.4*vec3(1.0,0.9,0.8)*dif +  0.8*vec3(0.2,0.28,0.35)*occ;
    col += vec3(1.2,1.0,0.8)*fre*(0.3+0.7*dif)*occ*3.5;
    col += vec3(0.4,0.3,0.2)*bak*occ;
    
    col *= mate;
    
    col += 3.5*vec3(0.3,0.4,0.5) * smoothstep( -0.1, 0.1, ref.y ) * (0.04 + 0.96*pow( fre, 5.0 )) * occ;
    col += 2.0*vec3(1.0)*pow( spe, 64.0 ) * (0.2 + 0.8*pow( fre, 5.0 )) * (occ*dif);
    
    col = pow( col, vec3(0.8,1.0,0.9) );

    col *= mix( vec3(0.3,0.2,0.1), vec3(1.0), smoothstep(-1.0,0.4,pos.y) );
    return col;        
}

vec2 intersect( in vec3 ro, in vec3 rd, const float maxdist )
{
    vec2 res = vec2(-1.0);
    vec3 resP = vec3(0.0);
    float t = 3.0;
    for( int i=0; i<100; i++ )
    {
        vec3 p = ro + t*rd;
        vec2 h = map( p );
        res = vec2( t, h.y );

        if( h.x<(0.001*t) || t>maxdist ) break;
        
        t += h.x;//*0.5;
    }
	return res;
}

//----------------------------------------------------------------------------------
vec2 mapTerrain( vec3 p )
{
    float h = -2.5;
    h -= 1.5*sin( 5.0 + 0.2*p.z);
    h += 1.5*sin( 0.0 - 0.05*p.x - 0.05*p.z);
    float g = h;
    if( (p.y-h)<0.15 )
    h += 0.1*(textureLod( iChannel0, 0.1*p.xz, 0.0 ).x);

    float d1 = 0.2*(p.y-h);
        
    vec2 res = vec2( d1, 1.0 );
    
#if 1
    if( -p.z>11.0 )
    {
    float ss = 4.0;
    vec3 q = p;
    vec2 id = floor( (q.xz+0.5*ss)/ss );
    q.xz = mod( q.xz+0.5*ss, ss ) - 0.5*ss;
    

    float r1 = hash(121.11*id.x+id.y*117.4);
    float r2 = hash( 71.72*id.x+id.y* 61.9);
    float r3 = hash( 31.74*id.x+id.y*317.1);
    mat4 rm = matRotate( vec3(1.0*r1,313.13*r2,0.2) );
    
    vec3 r = (rm*vec4(q,0.0)).xyz;
    r.y -= g + 0.25;
    
    float d2 = 0.8*udRoundBox( r, vec3(2.,0.01+0.2*r3,0.1+0.5*r3), 0.002 );
    res.x = min( d1, d2 );
    }
#endif
        
    return res;
}

vec2 mapTerrainH( vec3 p )
{
    float h = -2.5;
    h -= 1.5*sin( 5.0 + 0.2*p.z);
    h += 1.5*sin( 0.0 - 0.05*p.x - 0.05*p.z);
    float g = h;
    h += 0.1*(textureLod( iChannel0, 0.1*p.xz, 0.0 ).x);

    float d1 = 0.2*(p.y-h);
        
    vec2 res = vec2( d1, 1.0 );
    
#if 1   
    if( -p.z>11.0 )
    {
    float ss = 4.0;
    vec3 q = p;
    vec2 id = floor( (q.xz+0.5*ss)/ss );
    q.xz = mod( q.xz+0.5*ss, ss ) - 0.5*ss;
    

    float r1 = hash(121.11*id.x+id.y*117.4);
    float r2 = hash( 71.72*id.x+id.y* 61.9);
    float r3 = hash( 31.74*id.x+id.y*317.1);
    mat4 rm = matRotate( vec3(1.0*r1,313.13*r2,0.2) );
    
    vec3 r = (rm*vec4(q,0.0)).xyz;
    r.y -= g + 0.25;
    
    float d2 = 0.8*udRoundBox( r, vec3(2.,0.01+0.2*r3,0.1+0.5*r3), 0.002 );
    res.x = min( d1, d2 );
    }
#endif
        
    return res;
}


vec3 calcNormalTerrain( in vec3 pos, in float eps )
{
    vec2 e = vec2(1.0,-1.0)*0.5773*eps;
    return normalize( e.xyy*mapTerrainH( pos + e.xyy ).x + 
					  e.yyx*mapTerrainH( pos + e.yyx ).x + 
					  e.yxy*mapTerrainH( pos + e.yxy ).x + 
					  e.xxx*mapTerrainH( pos + e.xxx ).x );
}

float calcSoftshadowTerrain( in vec3 ro, in vec3 rd, float k )
{
    float res = 1.0;
    float t = 0.01;
    for( int i=0; i<16; i++ )
    {
        float h = mapTerrain(ro + rd*t ).x;
        res = min( res, smoothstep(0.0,1.0,k*h/t) );
        t += clamp( h, 0.04, 0.1 );
		if( res<0.01 ) break;
    }
    return clamp(res,0.0,1.0);
}

vec3 shadeTerrain( in vec3 ro, in vec3 rd, in float t, float m )
{
    vec3 pos = ro + rd * t;
    vec3 nor = calcNormalTerrain( pos, 0.01 );
    vec3 hal = normalize( sundir - rd );
    
    vec3 col = texture( iChannel0, 0.01*pos.xz ).xyz*0.14 * vec3(1.1,1.0,0.9);
    

    float dif = clamp( dot(sundir,nor), 0.0, 1.0 );
    float spe = clamp( dot(nor,hal), 0.0, 1.0 );
    float amb = clamp( 0.3 + 0.7*nor.y, 0.0, 1.0 );
    //dif *= calcSoftshadowTerrain( pos+nor*0.1, sundir, 32.0 );
    vec3 lig = dif*vec3(3.0,2.0,1.5)*2.0 + pow(spe,8.0)*3.0*dif*4.0 + vec3(0.5,0.6,1.0)*amb;
        
    col *= lig;

    return col;
}
    
vec2 intersectTerrain( in vec3 ro, in vec3 rd, float maxdist )
{
    vec2 res = vec2(-1.0);
    float t = 1.0;
    
    for( int i=0; i<256; i++ )
    {
        vec3 p = ro + t*rd;
        vec2 h = mapTerrain( p );
        res = vec2( t, h.y );
        if( h.x<(0.001*t) || t>maxdist ) break;
        t += h.x;
    }
    
	return res;
}


vec3 render( in vec3 ro, in vec3 rd )
{
    vec3 col = mix( vec3(1.0,1.0,1.0),
               vec3(0.8,0.6,0.4),
               sqrt(max(rd.y,0.0)) );

    float sun = clamp( dot(rd,sundir), 0.0, 1.0 );
    col += 0.9*pow( sun, 64.0 );
    
    // terrain
    float maxdistTerrain = 200.0;
    float bp = (4.0-ro.y)/rd.y; if( bp>0.0 && bp<maxdistTerrain ) maxdistTerrain = bp;
    vec2 res = intersectTerrain( ro, rd, maxdistTerrain );
    float t = res.x;
    if( t < maxdistTerrain )
    {
        col = shadeTerrain( ro, rd, t, res.y );
    }
    
    // eve
    const float maxdist = 6.0;
    res = intersect( ro, rd, maxdist );
    if( res.x < maxdist )
    {
        t = res.x;
        col = shade( ro, rd, t, res.y );
    }


    // fog
    if( t<maxdistTerrain )
    {
        float f = exp(-0.03*t);
        col *= f;
        vec3 fcol = mix( vec3(1.0,0.9,0.9), vec3(1.1,0.8,0.4), exp(-0.01*t) );
        col += (1.0-f)*fcol*0.8;    
    }

    col += 0.4*pow( sun, 20.0 );
    
    return pow( col, vec3(0.45) );
}

mat3 setCamera( in vec3 ro, in vec3 rt, in float cr )
{
	vec3 cw = normalize(rt-ro);
	vec3 cp = vec3(sin(cr), cos(cr),0.0);
	vec3 cu = normalize( cross(cw,cp) );
	vec3 cv = normalize( cross(cu,cw) );
    return mat3( cu, cv, -cw );
}


vec3 title( in vec3 col, in vec2 p )
{
    return col;
}


void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    float time = iTime;

    float rt = mod( time, 15.0 );
    float zo = step( 11.0, rt );
    float zf = clamp( (rt-11.0)/(15.0-11.0), 0.0, 1.0 );

    float an1 = sin(0.5*time*1.0+0.4)*(1.0-zo);
    float an2 = sin(0.5*time*1.3+0.0)*(1.0-zo);
    float an3 = sin(2.0*time);
    an1 = an1*an1*an1;
    an2 = an2*an2*an2;
    
    mat4 hRot = matRotate( vec3(-0.2*an1*an1*an1 - 0.1*zo,-1.0*an2*an2*an2, 0.0) );
    mat4 hTra = matTranslate( 0.0,0.5+0.015*an3-0.02*zo,0.11 );

    mtxHead = matInverse( hTra * hRot );

    vec2 q = fragCoord.xy/iResolution.xy;

    float an4 = 0.3 + 0.2*sin(0.04*time);
    vec3 ro = vec3( -5.2*sin(an4), 0.0+0.05*zo, 5.2*cos(an4) );
    
    vec3 ta = vec3(0.0,0.2+0.3*zo,0.0);
    ta += 0.02*cos( 1.0*time + vec3(0.0,2.0,3.0) )*(1.0-0.25*zo);
    ro += 0.02*cos( 1.0*time + vec3(1.0,3.5,5.0) )*(1.0-0.25*zo);
    mat3 ca = setCamera( ro, ta, 0.0 );
    float fl = 1.5 * (2.2 + 2.5*zo*(1.0+0.25*zf));
    

    vec3 col = vec3(0.0);
    for( int j=0; j<NS; j++ )
    for( int i=0; i<NS; i++ )
    {    
        vec2 o = (1.0+abs(q.x-0.5)*8.0*iResolution.x/850.0)*(vec2(float(i),float(j))/float(NS)-0.5);
        vec2 p = (-iResolution.xy+2.0*(fragCoord.xy+o))/iResolution.y;

        vec3 rd = normalize( ca * vec3(p,-fl) );

        col += render( ro, rd );
    }
    col /= float(NS*NS);
    
    // saturate
    col = mix( col, vec3(dot(col,vec3(0.333))), -0.1 );

    // vignette
    col *= 0.2 + 0.8*pow(16.0*q.x*q.y*(1.0-q.x)*(1.0-q.y), 0.1 );

    // letterbox
    col *= 1.0 - smoothstep( 0.4, 0.41, abs(q.y-0.5) );

    // flicker
    col *= 1.0 + 0.015*fract( 17.1*sin( 13.1*floor(12.0*iTime) ));
    

    col = title( col, q );
    
    fragColor = vec4( col, 1.0 );
}
