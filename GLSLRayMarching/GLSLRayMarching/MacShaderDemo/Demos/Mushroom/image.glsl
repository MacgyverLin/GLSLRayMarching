// Copyright Inigo Quilez, 2015 - https://iquilezles.org/
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

// make higher for higher quality
#if HW_PERFORMANCE==0
#define VIS_SAMPLES 1
#else
#define VIS_SAMPLES 2
#endif

vec3 hash3( vec3 n )
{
    return fract(sin(n)*vec3(158.5453123,278.1459123,341.3490423));
}

vec2 hash2( vec2 n )
{
    return fract(sin(n)*vec2(158.5453123,278.1459123));
}

vec2 sdSegment( in vec3 p, vec3 a, vec3 b )
{
	vec3 pa = p - a, ba = b - a;
	float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
	return vec2( length( pa - ba*h ), h );
}

float sdSphere( in vec3 p, in vec4 s )
{
    return length(p-s.xyz) - s.w;
}

float sdEllipsoid( in vec3 p, in vec3 c, in vec3 r )
{
    return (length( (p-c)/r ) - 1.0) * min(min(r.x,r.y),r.z);
}

float smin( float a, float b, float k )
{
	float h = clamp( 0.5 + 0.5*(b-a)/k, 0.0, 1.0 );
	return mix( b, a, h ) - k*h*(1.0-h);
}

vec2 smin( vec2 a, vec2 b, float k )
{
	float h = clamp( 0.5 + 0.5*(b.x-a.x)/k, 0.0, 1.0 );
	return vec2( mix( b.x, a.x, h ) - k*h*(1.0-h), mix( b.y, a.y, h ) );
}

float smax( float a, float b, float k )
{
	float h = clamp( 0.5 + 0.5*(b-a)/k, 0.0, 1.0 );
	return mix( a, b, h ) + k*h*(1.0-h);
}

// https://iquilezles.org/articles/texture
vec4 textureImproved( const sampler2D tex, in vec2 uv, in vec2 g1, in vec2 g2 )
{
    vec2 res = vec2( textureSize( tex, 0 ) );
	uv = uv*res + 0.5;
	vec2 iuv = floor( uv );
	//vec2 fuv = fract( uv );
    vec2 fuv = uv - iuv;
	//uv = iuv + fuv*fuv*(3.0-2.0*fuv);
    
    fuv = fuv*fuv*fuv*(fuv*(fuv*6.0-15.0)+10.0);
    
    uv = iuv + fuv;
    
	uv = (uv - 0.5)/res;
	return textureGrad( tex, uv, g1, g2 );
}

//---------------------------------------------------------------------------
vec3 drddx;
vec3 drddy;

float head( in vec3 p )
{
    // top
    float d3 = sdEllipsoid( p, vec3(0.0,-0.1,0.0),vec3(0.35,0.2,0.35) );
    d3 -= 0.03*(0.5+0.5*sin(11.0*p.z)*cos(9.0*p.x));
    //d3 -= 0.05*exp(-128.0*dot(p.xz,p.xz));
    
    // interior
    float d4 = sdSphere( p, vec4(0.0,-0.45,0.0,0.45) );
	d4 += 0.005*sin( 20.0*atan(p.x,p.z) );

    // substract
    return smax( d3, -d4, 0.02 );
}

float head2( in vec3 p )
{
    // top
    float d3 = sdEllipsoid( p, vec3(0.0,-0.1,0.0),vec3(0.35,0.2,0.35) );
    d3 -= 0.03*(0.5+0.5*sin(11.0*p.z)*cos(9.0*p.x));
    //d3 -= 0.1*exp(-64.0*dot(p.xz,p.xz));
    
    // interior
    float d4 = sdSphere( p, vec4(0.0,-0.45,0.0,0.48) );

    // substract
    return smax( d3, -d4, 0.02 );
}


vec2 map( vec3 p, float t )
{

    // ground
    vec3 s = p;
    s.y -= 0.1*sin( 0.25*p.z + 0.5*sin(0.25*p.x) );    
    s.y += 0.1*cos( 0.25*p.z + 0.5*cos(0.25*p.x) );        
    
    vec3 dpdx = t*drddx;
    vec3 dpdy = t*drddy;
    

    vec3 dsdx = dpdx - 0.1*cos( 0.25*p.z + 0.5*sin(0.25*p.x) )*(0.25*dpdx.z + 0.5*cos(0.25*p.x)*dpdx.x );
    vec3 dsdy = dpdy + 0.1*sin( 0.25*p.z + 0.5*cos(0.25*p.x) )*(0.25*dpdx.z - 0.5*sin(0.25*p.x)*dpdx.x );

    float d2 = s.y - 0.17;
    if( d2<2.0 )
    {
    d2 += 0.06*textureGrad( iChannel2, 0.15*s.xz, 0.15*dsdx.xz, 0.15*dsdy.xz ).x;
        
    d2 -= 1.5*pow(textureGrad( iChannel0, 0.01*s.xz,  0.01*dsdx.xz/256.0, 0.01*dsdy.xz/256.0 ).x,0.35) - 0.8;
    //d2 -= 1.5*pow(textureImproved( iChannel0, 0.01*s.xz,  0.01*dsdx.xz/256.0, 0.01*dsdy.xz/256.0 ).x,0.35) - 0.8;
            
    }
    d2 *= 0.8;
    vec2 res = vec2(d2,1.0);
    
    
    // mushroom
    vec3 d = vec3(0.0,0.95,0.0);
    vec3 q = p - d;
   
    float bb = length(q+vec3(0.0,0.3,0.0))-0.8;
    if( bb<0.0 )
    {
        // animate
        //float an = 0.5 + 0.5*cos(2.0*iTime + 9.0* p.y);
        //q.xz *= 1.1 - an*0.2*(1.0-smoothstep( 0.0, 0.6, abs(q.y+0.1) ));

        // stem
        float h = clamp(q.y+1.0,0.0,1.0);
        vec3 o = 0.12 * sin( h*3.0 + vec3(0.0,2.0,4.0) );
        o = o*4.0*h*(1.0-h) * h;
        float d1 = sdSegment( q + vec3(0.0,1.0,0.0) - o*vec3(1.0,0.0,1.0), vec3(0.0,0.0,0.0), vec3(0.0,1.0,0.0) ).x;
        d1 -= 0.04;
        d1 -= 0.1*exp(-16.0*h);

        float d3 = head( q );

        // mix head and stem
        d1 = smin( d1, d3, 0.2 );
        d1 *= 0.75;
        vec2 res2 = vec2(d1,0.0);


        // balls
        float ff = 10.0;
        vec3 id = floor(q*ff);
        vec3 wr = (id*2.0 + 1.0)/(2.0*ff);
        //wr += (-1.0+2.0*hash3(id)) * 0.2/ff;
        if( head2( wr )<0.0 )
        {
        vec3 r = (fract(q*ff) - 0.5)/ff;
        //r += (-1.0+2.0*hash3(id)) * 0.2/ff;
        float d5 = (length(r)-0.03);
        //vec3 n = abs(normalize(wr));
        //float d5 = sdEllipsoid( r, vec3(0.0), vec3(0.03) );
        if( d5<res2.x ) res2 = vec2(d5,2.0);
        }
        res = smin( res, res2, 0.1 );
    }
    else
    {
       res = min(res,vec2( bb+0.1, 2.0 ));
    }
    
#if 1
    vec2 pid = floor( (p.xz+2.0)/4.0 );
    p.xz = mod(p.xz+2.0,4.0)-2.0;
    if( dot(pid,pid)>0.5 )
    {
        p.xz += 1.0*(-1.0+2.0*hash2( vec2(313.1*pid.x + 171.4*pid.y,331.8*pid.x + 153.4*pid.y) ));
        float d3 = sdSphere(p,vec4(0.0,0.0,0.0,0.8));
        for( int i=0; i<6; i++ )
        {
            vec3 sc = -1.0+2.0*hash3( pid.x + pid.y*13.1 + float(i) + vec3(0.0,2.0,4.0) );
            sc.y = sqrt(abs(sc.y));
            sc = normalize(sc);
            float ss = 0.7 - 0.1*sin(pid.y + float(i)*13.1);
            vec4 pp = vec4(-sc,ss);
            d3 = smax( d3, -dot(vec4(p,1.0),pp), 0.02 );
        }
        d3 -= 0.1*sqrt(textureGrad( iChannel2, 0.1*s.zy, 0.1*dsdx.zy, 0.1*dsdy.zy ).x);
        if( d3<res.x  ) res = vec2(d3,3.0);
    }    
#endif
    
    return res;
}

vec3 calcNormal( in vec3 pos, in float eps, float t )
{
    vec2 e = vec2(1.0,-1.0)*0.5773*eps*t;
    return normalize( e.xyy*map( pos + e.xyy, t ).x + 
					  e.yyx*map( pos + e.yyx, t ).x + 
					  e.yxy*map( pos + e.yxy, t ).x + 
					  e.xxx*map( pos + e.xxx, t ).x );
}

float calcAO( in vec3 pos, in vec3 nor, float t )
{
	float occ = 0.0;
    for( int i=0; i<8; i++ )
    {
        float h = 0.005 + 0.25*float(i)/7.0;
        vec3 dir = normalize( sin( float(i)*73.4 + vec3(0.0,2.1,4.2) ));//+ gl_FragCoord.x*17.0 + gl_FragCoord.y*13.0 ) );
        dir = normalize( nor + dir );
        occ += (h-map( pos + h*dir, t ).x);
    }
    return clamp( 1.0 - 9.0*occ/8.0, 0.0, 1.0 );    
}

float calcSSS( in vec3 pos, in vec3 nor, in float t )
{
	float occ = 0.0;
    for( int i=0; i<8; i++ )
    {
        float h = 0.002 + 0.1*float(i)/7.0;
        vec3 dir = normalize( sin( float(i)*13.0 + vec3(0.0,2.1,4.2) ) );
        dir *= sign(dot(dir,nor));
        
        occ += (h-map( pos - h*dir, t).x);
    }
    occ = clamp( 11.0*occ/8.0, 0.0, 1.0 );    
    return occ*occ;
}


float softshadow( in vec3 ro, in vec3 rd, float k )
{
    float res = 1.0;
    float t = 0.01;
    for( int i=0; i<32; i++ )
    {
        vec3 pos = ro + rd*t;
        float h = map(pos, length(pos) ).x;
        res = min( res, smoothstep(0.0,1.0,k*h/t) );
        t += clamp( h, 0.04, 0.1 );
		if( res<0.01 ) break;
    }
    return clamp(res,0.0,1.0);
}

vec4 texcube( sampler2D sam, in vec3 p, in vec3 n, in float k, in vec3 gx, in vec3 gy )
{
    vec3 m = pow( abs( n ), vec3(k) );
	vec4 x = textureGrad( sam, p.yz, gx.yz, gy.yz );
	vec4 y = textureGrad( sam, p.zx, gx.yz, gy.zx );
	vec4 z = textureGrad( sam, p.xy, gx.yz, gy.xy );
	return (x*m.x + y*m.y + z*m.z) / (m.x + m.y + m.z);
}

vec3 sunDir = normalize( vec3(-0.5,0.3,0.4) );

vec3 shade( in vec3 ro, in vec3 rd, in float t, in float m )
{
    float eps = 0.0015;
    
    vec3 pos = ro + t*rd;
    vec3 nor = calcNormal( pos, eps, t );
    float kk;

    vec3 mateD = vec3(0.2,0.16,0.11);
    vec3 mateS = vec3(0.2,0.12,0.07);
    float mateK = 0.0;


    vec3 dpdx = t*drddx;
    vec3 dpdy = t*drddy;
    
    if( m<0.5 )
    {
        vec3 onor = nor;
        vec3 d = pos - vec3(0.0,1.0,0.0);
        
        mateD = vec3(0.15,0.15,0.15)*1.1;
        mateK = 0.2;
        
        mateS = vec3(0.4,0.1,0.1)*1.0;
        mateD *= 0.05 + 2.0*pow(1.0-texcube( iChannel0, pos*0.25, nor, 1.0, dpdx*0.25, dpdy*0.25 ).xyz, vec3(6.0));

        float h = clamp( pos.y, 0.0, 1.0 );
        vec3 o = 0.12 * sin( h*3.0 + vec3(0.0,2.0,4.0) );
        o = o*4.0*h*(1.0-h) * h;
        d = pos - o*vec3(1.0,0.0,1.0);
        float an = atan(d.x,d.z);
        vec2 uv1 = vec2( an*8.0, length(d.xz)*2.0  );
        vec2 uv2 = vec2( an*1.0, d.y*1.0  );
  
        // bump
        float bt = smoothstep( 0.7, 0.9, pos.y );
        vec3 bn1 = 0.1*(-1.0+2.0*texture( iChannel1, 0.05*uv1 ).xyz);
        vec3 bn2 = 0.4*(-1.0+2.0*texture( iChannel1, 0.05*uv2 ).xyz);
        vec3 onn = 0.1*(-1.0+2.0*texcube( iChannel1, pos, nor, 1.0, dpdx, dpdy ).xyz );
        nor = normalize( nor + mix(bn2,bn1,bt) + onn );

            
        float isd = smoothstep( 0.5, 0.6, -onor.y );
        mateD = mix( mateD, vec3(0.25,0.16,0.11), isd );

        mateD = mix( mateD, vec3(0.08,0.08,0.05)*0.2, 0.92*(1.0-smoothstep(0.1,0.5,pos.y)) );
    }
	else if( m<1.5 )
    {
        mateD = vec3(0.08,0.08,0.06)*0.55;
        mateS = vec3(0.0);
        mateK = 1.0;
        
        mateD *= 0.7 + 2.0*texture( iChannel2, pos.xz*0.008, -8.0 ).xyz;

        float ll = smoothstep( 0.2, 0.3, textureGrad(iChannel0,pos.xz*.1, dpdx.xz*0.1, dpdy.xz*0.1).x );
        ll *= smoothstep(0.5,1.0,nor.y);
        mateD = mix( mateD, vec3(0.4,0.15,0.15)*0.07, ll);
    }
	else if( m<2.5 )
    {
        mateK = 1.0;
        mateD = vec3(0.11,0.11,0.11);
        mateS = vec3(0.7,0.3,0.1)*2.0;
    }
	else //if( m<3.5 )
    {
        mateS = vec3(0.0,0.0,0.0);
        mateK = 0.2;
        
        mateD = vec3(0.65,0.6,0.45);
        mateD *= 0.2 + 0.8*texcube( iChannel2, pos*0.07, nor, 1.0, dpdx*0.7, dpdy*0.7 ).x;
        mateD *= .14;
    }
    
    
    vec3 hal = normalize( sunDir-rd );
    float fre = clamp(1.0+dot(nor,rd), 0.0, 1.0 );
    float occ = calcAO( pos, nor, t );
    float sss = calcSSS( pos, nor, t );

    
        
    float dif1 = clamp( dot(nor,sunDir), 0.0, 1.0 );
    float sha = softshadow( pos, sunDir, 32.0 ); 
    dif1 *= sha;
    float spe1 = clamp( dot(nor,hal), 0.0, 1.0 );

    float bou = clamp( 0.5-0.5*nor.y, 0.0, 1.0 );

    vec3 col = 6.0*vec3(1.6,1.0,0.5)*dif1;//*(0.5+0.5*occ);
    col += 6.0*pow( spe1, 16.0 )*dif1*mateK;
    col += 2.0*fre*(0.1+0.9*dif1);//*occ;
    col += sss*mateS*4.0;
    col += 4.0*vec3(0.2,0.6,1.3)*occ*(0.5+0.5*nor.y);
    col += 3.0*vec3(0.2,0.6,1.3)*occ*smoothstep( 0.0, 0.5, reflect( rd, nor ).y )*occ;
    col += 1.0*vec3(0.2,0.2,0.2)*bou*(0.5+0.5*occ);
    
    col *= mateD;
    
    t *= 0.5;
    col = mix( col, vec3(0.3,0.3,.3)*0.4, 1.0-exp( -0.1*t ) );
    col = mix( col, vec3(0.4,0.5,.6)*0.4, 1.0-exp( -0.001*t*t ) );

    col *= 0.9;

    return col;        
}

vec2 intersect( in vec3 ro, in vec3 rd, const float maxdist )
{
    vec2 res = vec2(-1.0);
    vec3 resP = vec3(0.0);
    float t = 0.1;
    for( int i=0; i<256; i++ )
    {
        vec3 p = ro + t*rd;
        vec2 h = map( p, t );
        res = vec2(t,h.y);

        if( abs(h.x)<(0.001*t) ||  t>maxdist ) break;
        
        t += h.x;
    }
	return res;
}

vec3 render( in vec3 ro, in vec3 rd )
{
    vec3 col = clamp(vec3(0.2,0.4,0.5) - 0.5*rd.y,0.0,1.0);
    col *= 0.6;
    col = mix( col, vec3(0.30,0.25,0.20), pow(1.0-rd.y,16.0) );
    
    float maxdist = 32.0;
    float tp = (1.25-ro.y)/rd.y; if( tp>0.0 ) maxdist = min( maxdist, tp );
    
    vec2 tm = intersect( ro, rd, maxdist );
    if( tm.y>-0.5 && tm.x < maxdist )
    {
        col = shade( ro, rd, tm.x, tm.y );
    }

    //col = clamp( col, 0.0, 1.0 );
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

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{	

    vec3 tot = vec3(0.0);
    #if VIS_SAMPLES<2
	int a = 0;
	{
        vec4 rr = vec4(0.0);

        vec2 p = (-iResolution.xy+2.0*fragCoord.xy)/iResolution.y;
    	float an = 10.0 + 0.2*sin(6.0+0.2*iTime);

        vec3 ro = vec3(0.0,0.5,0.5) + 2.1*vec3(cos(an),0.0,sin(an));
        vec3 ta = vec3(0.7,0.5,0.0);
        mat3 ca = setCamera( ro, ta, 0.4 );
        vec3 rd = normalize( ca * vec3(p,-2.8) );
        
    // ray differentials
    vec2 px = (-iResolution.xy+2.0*(fragCoord.xy+vec2(1.0,0.0)))/iResolution.y;
    vec2 py = (-iResolution.xy+2.0*(fragCoord.xy+vec2(0.0,1.0)))/iResolution.y;
    vec3 rdx = normalize( ca * vec3(px,-2.8) );
    vec3 rdy = normalize( ca * vec3(py,-2.8) );
    drddx = rdx - rd;
    drddy = rdy - rd;
        
    #else
	for( int a=0; a<VIS_SAMPLES; a++ )
	{
        vec4 rr = textureLod( iChannel1, (iTime*231.73 + fragCoord + 0.5+113.3137*float(a))/iChannelResolution[1].xy, 0.0  ).xzyw;

    	vec2 p = (-iResolution.xy+2.0*(fragCoord.xy+rr.zw-0.5))/iResolution.y;
    	float an = 10.0 + 0.2*sin(6.0+0.2*iTime);

        vec3 ro = vec3(0.0,0.5,0.5) + 2.1*vec3(cos(an),0.0,sin(an));
        vec3 ta = vec3(0.7,0.5,0.0);
        mat3 ca = setCamera( ro, ta, 0.4 );
        vec3 rd = normalize( ca * vec3(p,-2.8) );

        // dof
        vec3 fp = ro + rd * 1.7;
        ro += (ca[0].xyz*(-1.0+2.0*rr.x) + ca[1].xyz*(-1.0+2.0*rr.w))*0.012;
        rd = normalize( fp - ro );
    #endif

        vec3 col = render( ro, rd );

        float sun = clamp( 0.5 + 0.5*dot(rd,sunDir), 0.0, 1.0 );
        sun = sun*sun;
        col += vec3(0.5,0.4,0.3)*4.0*sun*sun;

        col = vec3(1.4,1.37,1.35)*col*1.3 - vec3(0.1,0.1,0.06)*2.4;
		tot += col;
    }    
    #if VIS_SAMPLES>1
	tot /= float(VIS_SAMPLES);
    #endif
        
    vec2 q = fragCoord.xy/iResolution.xy;
    tot *= 0.3 + 0.7*pow(16.0*q.x*q.y*(1.0-q.x)*(1.0-q.y),0.1);

    fragColor = vec4( tot, 1.0 );
}
