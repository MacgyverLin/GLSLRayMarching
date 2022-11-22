// Created by inigo quilez - iq/2013
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.


vec2 map( vec3 p )
{
    vec2 d2 = vec2( p.y+1.0, 2.0 );

	float r = 1.0;
	float f = smoothstep( 0.0, 0.5, sin(3.0+iTime) );
	float d = 0.5 + 0.5*sin( 4.0*p.x + 0.13*iTime)*
		                sin( 4.0*p.y + 0.11*iTime)*
		                sin( 4.0*p.z + 0.17*iTime);
    r += f*0.4*pow(d,4.0);//*(0.5-0.5*p.y);
    vec2 d1 = vec2( length(p) - r, 1.0 );

    if( d2.x<d1.x) d1=d2;

	p = vec3( length(p.xz)-2.0, p.y, mod(iTime + 6.0*atan(p.z,p.x)/3.14,1.0)-0.5 );
	//p -= vec3( 1.5, 0.0, 0.0 );
    vec2 d3 = vec2( 0.5*(length(p) - 0.2), 3.0 );
    if( d3.x<d1.x) d1=d3;

	
	return d1;
}


vec4 sphereColor( in vec3 pos, in vec3 nor )
{
	vec2 uv = vec2( atan( nor.x, nor.z ), acos(nor.y) );
    vec3 col = (texture( iChannel3, uv ).xyz);
    float ao = clamp( 0.75 + 0.25*nor.y, 0.0, 1.0 );
    return vec4( col, ao );
}

vec4 satelitesColor( in vec3 pos, in vec3 nor )
{
	vec2 uv = vec2( atan( nor.x, nor.z ), acos(nor.y) );
    vec3 col = (texture( iChannel3, uv ).xyz);
    float ao = 1.0;
    return vec4( col, ao );
}

vec4 floorColor( in vec3 pos, in vec3 nor )
{
    vec3 col = texture( iChannel2, 0.5*pos.xz ).xyz;
	
    // fake ao
    float f = smoothstep( 0.1, 1.75, length(pos.xz) );

	return vec4( col, 0.5*f+0.5*f*f );
}

const float precis = 0.001;
vec2 intersect( in vec3 ro, in vec3 rd )
{
	float h=precis*2.0;
    vec3 c;
    float t = 0.0;
	float maxd = 9.0;
    float sid = -1.0;
    for( int i=0; i<100; i++ )
    {
        if( abs(h)<precis||t>maxd ) continue;//break;
        t += h;
	    vec2 res = map( ro+rd*t );
        h = res.x;
	    sid = res.y;
    }

    if( t>maxd ) sid=-1.0;
    return vec2( t, sid );
}


vec3 calcNormal( in vec3 pos )
{
    vec3  eps = vec3(precis,0.0,0.0);
    vec3 nor;
    nor.x = map(pos+eps.xyy).x - map(pos-eps.xyy).x;
    nor.y = map(pos+eps.yxy).x - map(pos-eps.yxy).x;
    nor.z = map(pos+eps.yyx).x - map(pos-eps.yyx).x;
    return normalize(nor);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 q = fragCoord.xy / iResolution.xy;
    vec2 p = -1.0 + 2.0 * q;
    p.x *= iResolution.x/iResolution.y;
    vec2 mo = iMouse.xy/iResolution.xy;
	
    // camera
	float an1 = 0.2*iTime-6.2831*mo.x;
	float an2 = clamp( 0.8 + 0.6*sin(2.2+iTime*0.11)  + 1.0*mo.y, 0.3, 1.35 );
    vec3 ro = 2.5*normalize(vec3(sin(an2)*cos(an1), cos(an2)-0.5, sin(an2)*sin(an1)));
    vec3 ww = normalize(vec3(0.0,0.0,0.0) - ro);
    vec3 uu = normalize(cross( vec3(0.0,1.0,0.0), ww ));
    vec3 vv = normalize(cross(ww,uu));
    vec3 rd = normalize( p.x*uu + p.y*vv + 1.4*ww );

    // raymarch
    vec3 col = texture( iChannel0, rd ).xyz;
	
    vec2 tmat = intersect(ro,rd);
    if( tmat.y>0.5 )
    {
        // geometry
        vec3 pos = ro + tmat.x*rd;
        vec3 nor = calcNormal(pos);
        vec3 ref = reflect(rd,nor);

		float rim = pow(clamp(1.0+dot(nor,rd),0.0,1.0),4.0);

        col = texture( iChannel1, nor ).xyz;

        // color
        vec4 mate = vec4(0.0);
        if( tmat.y<1.5 )
            mate = sphereColor(pos,nor);
        else if( tmat.y<2.5 )
            mate = floorColor(pos,nor);
        else
            mate = satelitesColor(pos,nor);
		
        col += 2.0*rim*pow(mate.w,3.0);
		col *= mate.w;
		col *= mate.xyz;

		// reflection occlusion		
		vec2 tref = intersect(pos+nor*0.001,ref);
		if( tref.y<0.5 )
		{
			float fre = 0.3 + 0.7*pow( clamp( 1.0 + dot( rd, nor ), 0.0, 1.0 ), 5.0 );
		    vec3 sss = texture( iChannel0, ref ).xyz;
		    col += 2.0*mate.w*pow(sss,vec3(4.0))*fre;
		}

        col = sqrt(col);
    }

    col *= 0.25 + 0.75*pow( 16.0*q.x*q.y*(1.0-q.x)*(1.0-q.y), 0.15 );

    fragColor = vec4(col,1.0);
}