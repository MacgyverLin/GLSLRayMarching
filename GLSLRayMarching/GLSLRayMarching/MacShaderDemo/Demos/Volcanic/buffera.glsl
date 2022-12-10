//#define HIGH_QUALITY_NOISE

float noise( in vec3 x )
{
    vec3 p = floor(x);
    vec3 f = fract(x);
	f = f*f*(3.0-2.0*f);
#ifndef HIGH_QUALITY_NOISE
	vec2 uv = (p.xy+vec2(37.0,17.0)*p.z) + f.xy;
	vec2 rg = textureLod( iChannel0, (uv+ 0.5)/256.0, 0.0 ).yx;
#else
	vec2 uv  = (p.xy+vec2(37.0,17.0)*p.z);
	vec2 rg1 = textureLod( iChannel0, (uv+ vec2(0.5,0.5))/256.0, 0.0 ).yx;
	vec2 rg2 = textureLod( iChannel0, (uv+ vec2(1.5,0.5))/256.0, 0.0 ).yx;
	vec2 rg3 = textureLod( iChannel0, (uv+ vec2(0.5,1.5))/256.0, 0.0 ).yx;
	vec2 rg4 = textureLod( iChannel0, (uv+ vec2(1.5,1.5))/256.0, 0.0 ).yx;
	vec2 rg  = mix( mix(rg1,rg2,f.x), mix(rg3,rg4,f.x), f.y );
#endif	
	return mix( rg.x, rg.y, f.z );
}

float noise( in vec2 x )
{
    vec2 p = floor(x);
    vec2 f = fract(x);
	vec2 uv = p.xy + f.xy*f.xy*(3.0-2.0*f.xy);
	return textureLod( iChannel0, (uv+118.4)/256.0, 0.0 ).x;
}

const mat3 m = mat3( 0.00,  0.80,  0.60,
                    -0.80,  0.36, -0.48,
                    -0.60, -0.48,  0.64 );

float fbm4( in vec3 q )
{
    float f  = 0.5000*noise( q ); q = m*q*2.02;
          f += 0.2500*noise( q ); q = m*q*2.03;
          f += 0.1250*noise( q ); q = m*q*2.01;
          f += 0.0625*noise( q );
    return f;
}
    
vec4 texcube( sampler2D sam, in vec3 p, in vec3 n )
{
	return texture( sam, p.yz )*abs(n.x) +
           texture( sam, p.zx )*abs(n.y) +
           texture( sam, p.xy )*abs(n.z);
}

//=====================================================================

float lava( in vec2 p )
{
	p += vec2(2.0,4.0);
    float f  = 0.5000*noise( p ); p = p*2.02;
          f += 0.2500*noise( p ); p = p*2.03;
          f += 0.1250*noise( p ); p = p*2.01;
          f += 0.0625*noise( p );
    return f;
}

float displacement( in vec3 p )
{
    float dis = textureLod( iChannel2, p.xz, 0.0 ).x;
    return fbm4(p+vec3(1.0,0.0,0.8)) - dis*0.01;
}

float mapTerrain( in vec3 pos )
{
	return pos.y*0.1 + (displacement(pos*vec3(0.8,1.0,0.8)) - 0.4)*(1.0-smoothstep(1.0,3.0,pos.y));
}

float raymarchTerrain( in vec3 ro, in vec3 rd )
{
    // bounding plane
    const float hmax = 1.9;
    float tp = (hmax-ro.y)/rd.y;
    float tmax = (tp<0.0)?30.0:tp;

    // raymarch
    float t = 0.1;
    for( int i=0; i<350; i++ )
    {
	    float h = mapTerrain( ro+rd*t );
        if( abs(h)<(0.00025*t) || t>tmax ) break;
        t += h*0.8;
    }
    return (t>tmax) ? -1.0 : t;
}

// https://iquilezles.org/articles/rmshadows
float softshadow( in vec3 ro, in vec3 rd, float mint, float k )
{
    // bounding plane
    const float hmax = 1.9;
    float tp = (hmax-ro.y)/rd.y;
    float tmax = (tp<0.0)?30.0:tp;

    // raymarch
    float res = 1.0;
    float t = mint;
    for( int i=0; i<100; i++ )
    {
        float h = mapTerrain(ro + rd*t);
        res = min( res, k*max(h,0.0)/t );
        t += clamp( h, 0.01, 0.4 );
		if( res<0.001 || t>tmax ) break;
    }
    return clamp(res,0.0,1.0);
}

// https://iquilezles.org/articles/normalsSDF
vec3 calcNormal( in vec3 pos, in float t )
{
    float eps = max(0.02,0.001*t);
    vec2 e = vec2(1.0,-1.0)*0.5773*eps;
    return normalize( e.xyy*mapTerrain(pos+e.xyy) + 
					  e.yyx*mapTerrain(pos+e.yyx) + 
					  e.yxy*mapTerrain(pos+e.yxy) + 
					  e.xxx*mapTerrain(pos+e.xxx) );
}

const vec3 lig = normalize( vec3(-0.3,0.4,0.7) );

vec4 mapClouds( in vec3 pos )
{
	vec3 q = pos*0.5 + vec3(0.0,-iTime,0.0);
	
	float d = clamp( fbm4(q)-0.55, 0.0, 1.0 );
	d *= smoothstep( 0.5, 0.55, lava(0.1*pos.xz)+0.01 );
	
	vec4 res = vec4( d );
	res.xyz  = 0.25*mix( vec3(1.0,0.8,0.7), 0.2*vec3(0.4,0.4,0.4), d );
	res.xyz *= 0.5 + 0.5*smoothstep(-2.0, 1.0, pos.y);
	return res;
}

vec4 raymarchClouds( in vec3 ro, in vec3 rd, in vec3 bcol, float tmax, in vec2 px )
{
	vec4 sum = vec4( 0.0 );
	float sun = pow( clamp( dot(rd,lig), 0.0, 1.0 ), 6.0 );
	float t = texture(iChannel0,px/256.0).x*0.1;
	for( int i=0; i<60; i++ )
	{
		vec4 col = mapClouds( ro + t*rd );
		
        col.xyz += vec3(1.0,0.7,0.4)*0.4*sun*(1.0-col.w);
		col.xyz = mix( col.xyz, bcol, 1.0-exp(-0.00006*t*t*t) );
        col.a *= 2.0;
		col.rgb *= col.a;
		sum = sum + col*(1.0 - sum.a);	

		t += max(0.1,0.05*t);
		if( t>tmax || sum.w>0.95 ) break;
	}
	sum.xyz /= (0.001+sum.w);
	return clamp( sum, 0.0, 1.0 );
}

vec3 path( float time )
{
	return vec3( 16.0*cos(0.2+0.075*time), 1.5, 16.0*sin(0.1+0.0825*time) );
}

mat3 setCamera( in vec3 ro, in vec3 ta, float cr )
{
	vec3 cw = normalize(ta-ro);
	vec3 cp = vec3(sin(cr), cos(cr), 0.0);
	vec3 cu = normalize( cross(cw,cp) );
	vec3 cv = normalize( cross(cu,cw) );
    return mat3( cu, cv, cw );
}

void moveCamera( in float time, out vec3 oRo, out vec3 oTa, out float oCr, out float oFl )
{
    oFl = 2.1;
    oCr = 0.3*sin(1.0+0.07*time);
    oRo = path( time+0.0 );
    oTa = path( time+1.6 );
	oTa.y *= 0.35 + 0.25*sin(0.09*time);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 p = (2.0*fragCoord-iResolution.xy)/iResolution.y;
	
    // camera	
	float off = step( 0.001, iMouse.z )*6.0*iMouse.x/iResolution.x;
    float time = 3.4 + iTime + off;
    vec3 ro, ta; float cr, fl;
    moveCamera( time, ro, ta, cr, fl );
    
	// camera2world transform
    mat3 cam = setCamera( ro, ta, cr );

    // ray    
    vec3 rd = cam * normalize(vec3(p.xy,fl));

    // sky	 
    vec3  col = vec3(0.36,0.43,0.54) - rd.y*0.5;
    float sun = clamp( dot(rd,lig), 0.0, 1.0 );
	col += vec3(1.0,0.8,0.4)*0.24*pow( sun, 6.0 );

	vec3 bcol = col;
    
    // terrain	
	float t = raymarchTerrain(ro, rd);
    float st = t;
    if( t>0.0 )
	{
		vec3 pos = ro + t*rd;
		vec3 nor = calcNormal( pos, t );
		vec3 ref = reflect( rd, nor );
		
        // lighting
		float hhh = 1.0 - smoothstep(-2.0, 1.0, pos.y);
		float sun = clamp( dot( nor, lig ), 0.0, 1.0 );
		float sha = 0.0; if( sun>0.01) sha=softshadow(pos,lig,0.001,32.0);
		float bac = clamp( dot( nor, normalize(lig*vec3(-1.0,0.0,-1.0)) ), 0.0, 1.0 );
		float sky = 0.5 + 0.5*nor.y;
        float lav = smoothstep( 0.5, 0.55, lava(0.1*pos.xz) )*hhh*clamp(0.5-0.5*nor.y,0.0,1.0);
		float occ = pow( (1.0-displacement(pos*vec3(0.8,1.0,0.8)))*1.6-0.5, 2.0 );
		float amb = 1.0;
        float fre = 1.0+dot(nor,rd); fre = fre*fre;

		vec3 lin = vec3(0.0);
		lin += 1.3*sun*vec3(1.80,1.27,0.99)*pow(vec3(sha),vec3(1.0,1.2,1.5));
		lin += 1.0*sky*vec3(0.16,0.20,0.40)*occ;
		lin += 1.0*bac*vec3(0.40,0.28,0.20)*occ;
		lin += 1.0*amb*vec3(0.15,0.17,0.20)*occ;
		lin += lav*vec3(3.00,0.61,0.00);

        // surface shading/material		
        vec3 te = texcube( iChannel1, 0.5*pos, nor ).xyz;
		col = te;
		col = col*(0.2+0.8*texcube( iChannel2, 4.0*vec3(2.0,8.0,2.0)*pos, nor ).x);

		vec3 lava = vec3(1.0,0.9,0.2);
		lava *= texture( iChannel2, pos.xz ).xyz;
		col = mix( col, 0.8*lava, hhh );
		
		vec3 verde = vec3(0.2,0.2,0.05);
		verde *= 0.2+1.6*texture( iChannel1, 7.1*pos.xz ).xyz;
		verde += 0.1*texture( iChannel1, 1.0*pos.xz ).xyz;
        verde *= 1.0+fre*fre;
		col = mix( col, verde, smoothstep(0.0, 0.8, nor.y)*smoothstep(0.0, 0.1, pos.y-0.8 ) );
		
		col = lin * col;

        // sun spec
        vec3 hal = normalize(lig-rd);
        col += (te.x*te.x)*vec3(11.0,8.0,5.0)*sun*sha*
               pow( clamp(dot(nor,hal),0.0,1.0), 8.0 ) *
               (0.04+0.96*pow(clamp(1.0+dot(hal,rd),0.0,1.0),5.0));
            
		// atmospheric
        vec3 ext = exp2(-t*t*0.001*vec3(0.5,1.0,2.0) );
        col = col*ext + 0.6*(1.0-ext)*(1.0-0.7*hhh);
    }

    // sun glow
    col += vec3(1.0,0.6,0.2)*0.2*sun*sun*clamp( (rd.y+0.4)/(0.0+0.4),0.0,1.0);
	
    // smoke	
    vec4 res = raymarchClouds( ro, rd, bcol, (t<0.0)?600.0:t, fragCoord );
	col = mix( col, res.xyz, res.w );

    // gain
    col *= 1.6/(1.0+col);
    col *= vec3(1.02,1.04,1.0);

    // gamma	
	col = pow( clamp( col, 0.0, 1.0 ), vec3(0.45) );

    // contrast, desat, tint and vignetting	
	col = col*col*(3.0-2.0*col);
	col = mix( col, vec3(col.x+col.y+col.z)*0.33, 0.2 );
      
    //-------------------------------------
	// velocity vectors
    //-------------------------------------
    float vel = -1.0;
    if( st>0.0 )
    {
        // old camera position
        float oldTime = time - 1.0/30.0; // 1/30 of a second blur
        vec3 oldRo, oldTa; float oldCr, oldFl;
        moveCamera( oldTime, oldRo, oldTa, oldCr, oldFl );
        mat3 oldCam = setCamera( oldRo, oldTa, oldCr );
        // world space
        vec3 wpos = ro + rd*st;
        // camera space
        vec3 cpos = vec3( dot( wpos - oldRo, oldCam[0] ),
                          dot( wpos - oldRo, oldCam[1] ),
                          dot( wpos - oldRo, oldCam[2] ) );
        // ndc space
        vec2 npos = oldFl * cpos.xy / cpos.z;
        // screen space
        vec2 spos = 0.5 + 0.5*npos*vec2(iResolution.y/iResolution.x,1.0);
        // compress velocity vector in a single float
        vec2 uv = fragCoord/iResolution.xy;
        spos = clamp( 0.5 + 0.5*(spos - uv)/0.25, 0.0, 1.0 );
        vel = floor(spos.x*1023.0) + floor(spos.y*1023.0)*1024.0;
    }

    fragColor = vec4( col, vel );
}