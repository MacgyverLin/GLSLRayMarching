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

// Some columns, derived from Slisesix
//
//   https://www.shadertoy.com/view/NtlSDs


#define AA 1


// https://iquilezles.org/articles/distfunctions
float udBox( in vec3 p, in vec3 abc )
{
	return length(max(abs(p)-abc,0.0));
}
// https://iquilezles.org/articles/distfunctions
float sdBox( in vec3 p, in vec3 b ) 
{
    vec3 q = abs(p) - b;
    return min(max(q.x,max(q.y,q.z)),0.0) + length(max(q,0.0));
}
// https://iquilezles.org/articles/smin
float smin( float a, float b, float k )
{
    float h = max(k-abs(a-b),0.0);
    return min(a, b) - h*h*0.25/k;
}
// https://iquilezles.org/articles/smin
float smax( float a, float b, float k )
{
    float h = max(k-abs(a-b),0.0);
    return max(a, b) + h*h*0.25/k;
}

// https://iquilezles.org/articles/biplanar
float roundcube( vec3 p, vec3 n )
{
    n = abs(n);
	float x = texture( iChannel0, p.yz ).x;
	float y = texture( iChannel0, p.zx ).x;
	float z = texture( iChannel0, p.xy ).x;
	return (x*n.x + y*n.y + z*n.z)/(n.x+n.y+n.z);
}

#define ZERO (min(iFrame,0))

//------------------------------------------

vec3 column( in float x, in float y, in float z )
{
    float y2=y-0.25;
    float y3=y-0.25;
    float y4=y-1.0;

    float dsp = abs( min(cos(1.5*0.75*6.283185*x/0.085), cos(1.5*0.75*6.283185*z/0.085)));
    dsp *= 1.0-smoothstep(0.8,0.9,abs(x/0.085)*abs(z/0.085));
    float di1=sdBox( vec3(x,mod(y+0.08,0.16)-0.08,z), vec3(0.10*0.85+dsp*0.03*0.25,0.079,0.10*0.85+dsp*0.03*0.25)-0.008 )-0.008;
    float di2=sdBox( vec3(x,y,z), vec3(0.12,0.29,0.12)-0.007 )-0.007;
    float di3=sdBox( vec3(x,y4,z), vec3(0.14,0.02,0.14)-0.006 )-0.006;
    float nx = max( abs(x), abs(z) );
    float nz = min( abs(x), abs(z) );	
    float di4=sdBox( vec3(nx, y, nz), vec3(0.14,0.3,0.05)-0.004 )-0.004;
	float di5=smax(-(y-0.291),sdBox( vec3(nx, (y2+nz)*0.7071, (nz-y2)*0.7071), vec3(0.12, 0.16*0.7071, 0.16*0.7071)-0.004)-0.004,0.007 + 0.0001);
    float di6=sdBox( vec3(nx, (y3+nz)*0.7071, (nz-y3)*0.7071), vec3(0.14, 0.10*0.7071, 0.10*0.7071)-0.004)-0.004;

    float dm1 = min(min(di5,di3),di2);
    float dm2 = min(di6,di4);
	vec3 res = vec3( dm1, 3.0, 1.0 );
	if( di1<res.x ) res = vec3( di1, 2.0, dsp );
    if( dm2<res.x ) res = vec3( dm2, 5.0, 1.0 );
    
	return res;
}

float wave( in float x, in float y )
{
    return sin(x)*sin(y);
}

#define SC 15.0
vec3 map( vec3 pos )
{
pos /= SC;

    // floor
    vec2 id = floor((pos.xz+0.1)/0.2 );
    float h = 0.012 + 0.008*sin(id.x*2313.12+id.y*3231.219);
    vec3 ros = vec3( mod(pos.x+0.1,0.2)-0.1, pos.y, mod(pos.z+0.1,0.2)-0.1 );
    vec3 res = vec3( udBox( ros, vec3(0.096,h,0.096)-0.005 )-0.005, 0.0, 0.0 );

    // ceilin
	float x = fract( pos.x+128.0 ) - 0.5;
	float z = fract( pos.z+128.0 ) - 0.5;
    float y = (1.0 - pos.y)*0.6;// + 0.1;
    float dis = 0.4 - smin(sqrt(y*y+x*x),sqrt(y*y+z*z),0.01);
    float dsp = abs(sin(31.416*pos.y)*sin(31.416*pos.x)*sin(31.416*pos.z));
    dis -= 0.02*dsp;

	dis = max( dis, y );
    if( dis<res.x )
    {
        res = vec3(dis,1.0,dsp);
    }

    // columns
	vec2 fc = fract( pos.xz+128.5 ) - 0.5;
	vec3 dis2 = column( fc.x, pos.y, fc.y );
    if( dis2.x<res.x )
    {
        res = dis2;
    }
    
    fc = fract( pos.xz+128.5 )-0.5;
    dis = length(vec3(fc.x,pos.y,fc.y)-vec3(0.0,-0.565,0.0))-0.6;
    dis -= texture(iChannel0,1.5*pos.xz).x*0.02;
    if( dis<res.x ) res=vec3(dis,4.0,1.0);
    
    
	res.x*=SC;
    return res;
}

vec4 calcColor( in vec3 pos, in vec3 nor, in float sid, out float ke )
{
	vec3 col = vec3( 1.0 );
	float ks = 1.0;
    ke = 0.0;

    float kk = 0.2+0.8*roundcube( 1.0*pos, nor );
	
    // floor
    if( sid<0.5 )
	{
        col = texture( iChannel1, 6.0*pos.xz ).xyz;
		vec2 id = floor((pos.xz+0.1)/0.2 );
    	col *= 1.0 + 0.5*sin(id.y*2313.12+id.x*3231.219);
	}
    // ceilin
    else if( sid<1.5 )
	{
		float fx = fract( pos.x+128.0 ); 
	    float fz = fract( pos.z+128.0 ); 
		col = vec3(0.7,0.6,0.5)*1.3;
		float p = 1.0;
		p *= smoothstep( 0.02, 0.03, abs(fx-0.1) );
		p *= smoothstep( 0.02, 0.03, abs(fx-0.9) );
		p *= smoothstep( 0.02, 0.03, abs(fz-0.1) );
		p *= smoothstep( 0.02, 0.03, abs(fz-0.9) );
		//col = mix( vec3(0.6,0.2,0.1), col, p );
        col = mix( vec3(2.0), col, p );
	}
    // columns
    else if( sid<2.5 )
	{
        float id = floor((pos.y+0.08)/0.16);
        col = vec3(0.7,0.6,0.5);
        col *= 1.0 + 0.4*cos(id*312.0 + floor(pos.x+0.5)*33.1 + floor(pos.z+0.5)*13.7);
	}
    // columns bottom
    else if( sid<3.5 )
	{
        col = vec3(0.7,0.6,0.5);
        col *= 0.25 + 0.75*smoothstep(0.0,0.1,pos.y);
	}
    // dirt
    else if( sid<4.5 )
	{
        col = vec3(0.2,0.15,0.1)*0.5;
        ks = 0.05;
    }
    // colums stone
    else // if( sid<5.5 )
	{
        col = vec3(1.0);
        
        col *= 0.25 + 0.75*smoothstep(0.0,0.1,pos.y);
        ks = 1.0;
        kk = kk*0.5+0.5;
	}

	
    return vec4(col * 1.2 * kk,ks);
}

vec3 raycast( in vec3 ro, in vec3 rd, in float precis, in float maxd )
{
    float t = 0.001;
    float dsp = 0.0;
    float sid = -1.0;
    for( int i=0; i<128; i++ )
    {
	    vec3 res = map( ro+rd*t );
        if( abs(res.x)<(precis*t)||t>maxd ) break;
	    sid = res.y;
		dsp = res.z;
        t += res.x;
    }

    if( t>maxd ) sid=-1.0;
    return vec3( t, sid, dsp );
}

// https://iquilezles.org/articles/rmshadows
float softshadow( in vec3 ro, in vec3 rd, in float mint, in float maxt, in float k )
{
	float res = 1.0;
    float t = mint;
    for( int i=0; i<32; i++ )
    {
        float h = map( ro + rd*t ).x;
        res = min( res, k*h/t );
        t += clamp(h,0.1,1.0);
		if( res<0.001 || t>maxt ) break;
    }
    return clamp( res, 0.0, 1.0 );
}

// https://iquilezles.org/articles/normalsSDF
vec3 calcNormal( in vec3 pos )
{
#if 0
	vec3 eps = vec3( 0.001, 0.0, 0.0 );
	vec3 nor = vec3(
	    map(pos+eps.xyy).x - map(pos-eps.xyy).x,
	    map(pos+eps.yxy).x - map(pos-eps.yxy).x,
	    map(pos+eps.yyx).x - map(pos-eps.yyx).x );
	return normalize(nor);
#else
    // inspired by tdhooper and klems - a way to prevent the compiler from inlining map() 4 times
    vec3 n = vec3(0.0);
    for( int i=ZERO; i<4; i++ )
    {
        vec3 e = 0.5773*(2.0*vec3((((i+3)>>1)&1),((i>>1)&1),(i&1))-1.0);
        n += e*map(pos+e*0.001).x;
    }
    return normalize(n);
#endif    
}

vec3 doBumpMap( in vec3 pos, in vec3 nor )
{
    const float e = 0.001;
    const float b = 0.005;
    
	float ref = roundcube( 7.0*pos, nor );
    vec3 gra = -b*vec3( roundcube(7.0*vec3(pos.x+e, pos.y, pos.z),nor)-ref,
                        roundcube(7.0*vec3(pos.x, pos.y+e, pos.z),nor)-ref,
                        roundcube(7.0*vec3(pos.x, pos.y, pos.z+e),nor)-ref )/e;
	
	vec3 tgrad = gra - nor*dot(nor,gra);
    
    return normalize( nor-tgrad );
}

float calcAO( in vec3 pos, in vec3 nor )
{
    float ao = 0.0;
    float sca = 15.0;
    for( int i=ZERO; i<5; i++ )
    {
        float hr = SC*(0.01 + 0.01*float(i*i));
        float dd = map( pos + hr*nor ).x;
        ao += (hr-dd)*sca/SC;
        sca *= 0.85;
    }
    return 1.0 - clamp( ao*0.3, 0.0, 1.0 );
}

vec3 getLightPos( in int i )
{
    vec3 lpos;
    
    lpos.x = 0.5 + 2.2*cos(0.22+0.1*iTime + 17.0*float(i) );
    lpos.y = 0.25;
    lpos.z = 1.5 + 2.2*cos(2.24+0.1*iTime + 13.0*float(i) );

    // make the lights avoid the columns
    vec2 ilpos = floor( lpos.xz );
    vec2 flpos = lpos.xz - ilpos;
    flpos = flpos - 0.5;
    if( length(flpos)<0.2 ) flpos = 0.2*normalize(flpos);
    lpos.xz = ilpos + flpos;

    return lpos*SC;
}

vec4 getLightCol( in int i )
{
    float li = sqrt(0.5 + 0.5*sin(2.0*iTime+ 23.1*float(i)));
    float h = float(i)/8.0;
    vec3 c = mix( vec3(1.0,0.8,0.6), vec3(1.0,0.3,0.05), 0.5+0.5*sin(40.0*h) );
    return vec4( c, li );
}

const int kNumLights = 9;

vec3 render( in vec3 ro, in vec3 rd )
{ 
    vec3 col = vec3(0.0);
    vec3 res = raycast(ro,rd,0.00001*SC,10.0*SC);
    float t = res.x;
    if( res.y>-0.5 )
    {
        vec3 pos = ro + t*rd;
        vec3 nor = calcNormal( pos );

        float ao = calcAO( pos, nor );
        ao *= 0.7 + 0.6*res.z;
        
        pos /= SC;
		t /= SC;
        
        float ke = 0.0;
        vec4 mate = calcColor( pos, nor, res.y, ke );
        col = mate.xyz;
        float ks = mate.w;

        nor = doBumpMap( pos, nor );

        
        // lighting
        float fre = clamp(1.0+dot(nor,rd),0.0,1.0);
        vec3 lin = 0.03*ao*vec3(0.25,0.20,0.20)*(0.5+0.5*nor.y);
		vec3 spe = vec3(0.0);
        for( int i=0; i<kNumLights; i++ )
        {
            vec3 lpos = getLightPos(i);
            vec4 lcol = getLightCol(i);
            
            vec3 lig = lpos/SC - pos;
            float llig = dot( lig, lig);
            float im = inversesqrt( llig );
            lig = lig * im;
            float dif = clamp( dot( nor, lig ), 0.0, 1.0 );
			float at = 2.0*exp2( -2.3*llig )*lcol.w;
            dif *= at;
            float at2 = exp2( -0.35*llig );

			float sh = 0.0;
			if( dif>0.001 ) { sh = softshadow( pos*SC, lig, 0.02*SC, sqrt(llig)*SC, 32.0 ); dif *= sh; }
            float dif2 = clamp( dot(nor,normalize(vec3(-lig.x,0.0,-lig.z))), 0.0, 1.0 );
            
            lin += 2.50*dif*lcol.xyz;
            lin += 0.10*dif2*vec3(0.35,0.20,0.10)*at2*ao*vec3(1.5,1.0,0.5);
            lin += fre*fre*col*ao*ke*10.0*clamp(0.5+0.5*dot(nor,lig),0.0,1.0)*sh;
                        
            vec3 hal = normalize(lig-rd);
            float pp = clamp( dot(nor,hal), 0.0, 1.0 );
            pp = pow(pp,1.0+ke*3.0);
            spe += ks*(5.0)*lcol.xyz*at*dif*(0.04+0.96*pow(1.0-clamp(dot(hal,-rd),0.0,1.0),5.0))*(pow(pp,16.0) + 0.5*pow(pp,4.0));
            
        }
    
        col = col*lin + 2.0*spe + 4.0*ke*fre*col*col*ao;
    }
	else
    {
		t /= SC;
    }
    
	col *= exp( -0.055*t*t );

    
    // lights
	for( int i=0; i<kNumLights; i++ )
	{
        vec3 lpos = getLightPos(i);
        vec4 lcol = getLightCol(i);
        
        vec3 lv = (lpos - ro)/SC;
        float ll = length( lv );
        if( ll<t )
        {
            float dle = clamp( dot( rd, lv/ll ), 0.0, 1.0 );
			dle = 1.0-smoothstep( 0.0, 0.2*(0.7+0.3*lcol.w), acos(dle)*ll );
            col += dle*dle*6.0*lcol.w*lcol.xyz*exp( -0.07*ll*ll );
        }
    }

    
	return col;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 mo = iMouse.xy/iResolution.xy;

    vec3 tot = vec3(0.0);

    #if AA>1
    for( int m=ZERO; m<AA; m++ )
    for( int n=ZERO; n<AA; n++ )
    {
        // pixel coordinates
        vec2 o = vec2(float(m),float(n)) / float(AA) - 0.5;

        vec2 p = (2.0*(fragCoord+o)-iResolution.xy)/iResolution.y;
#else
        vec2 p = (2.0*fragCoord-iResolution.xy)/iResolution.y;
#endif        
        float time = iTime;

        // camera	
        vec3 ce = vec3( 0.5, 0.25, 1.5 );
        vec3 ro = ce + vec3( 1.3*cos(0.11*time + 6.0*mo.x), 0.65*(1.0-mo.y)- 0.4, 1.3*sin(0.11*time + 6.0*mo.x) );
        vec3 ta = ce + vec3( 0.95*cos(1.2+.08*time), 0.4*0.25+0.75*ro.y- 0.2, 0.95*sin(2.0+0.07*time) );
        ro *= SC;
        ta *= SC;
        float roll = -0.15*sin(0.1*time);

        // distort
        float r2 = p.x*p.x*0.3164 + p.y*p.y;
        p *= (7.15-sqrt(38.0-12.0*r2))/(r2+1.0);

        // camera tx
        vec3 cw = normalize( ta-ro );
        vec3 cp = vec3( sin(roll), cos(roll),0.0 );
        vec3 cu = normalize( cross(cw,cp) );
        vec3 cv = normalize( cross(cu,cw) );
        vec3 rd = normalize( p.x*cu + p.y*cv + 1.5*cw );

        vec3 col = render( ro, rd );

        col = col*2.0/(1.0+col);
        col = pow( col, vec3(0.4545) );
        col *= vec3(1.0,1.05,1.0);
        col += vec3(0.0,0.03,0.0);
        tot += col;

#if AA>1
    }
    tot /= float(AA*AA);
#endif

    // vigneting
    {
 	vec2 q = fragCoord.xy/iResolution.xy;
    tot *= 0.25+0.75*pow( 16.0*q.x*q.y*(1.0-q.x)*(1.0-q.y), 0.15 );
    }
    
    fragColor = vec4( tot, 1.0 );
}

void mainVR( out vec4 fragColor, in vec2 fragCoord, in vec3 fragRayOri, in vec3 fragRayDir )
{
    vec3 ro = fragRayOri + vec3( 0.5*SC, 1.8, 1.5*SC );
    vec3 rd = fragRayDir;
    
    vec3 col = render( ro, rd );

  	col = pow( col, vec3(0.4545) );

    fragColor = vec4( col, 1.0 );
}