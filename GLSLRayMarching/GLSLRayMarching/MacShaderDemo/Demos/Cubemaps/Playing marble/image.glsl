// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
// Created by S. Guillitte 2015

float zoom=1.;

vec2 cmul( vec2 a, vec2 b )  { return vec2( a.x*b.x - a.y*b.y, a.x*b.y + a.y*b.x ); }
vec2 csqr( vec2 a )  { return vec2( a.x*a.x - a.y*a.y, 2.*a.x*a.y  ); }


mat2 rot(float a) {
	return mat2(cos(a),sin(a),-sin(a),cos(a));	
}

vec2 iSphere( in vec3 ro, in vec3 rd, in vec4 sph )//from iq
{
	vec3 oc = ro - sph.xyz;
	float b = dot( oc, rd );
	float c = dot( oc, oc ) - sph.w*sph.w;
	float h = b*b - c;
	if( h<0.0 ) return vec2(-1.0);
	h = sqrt(h);
	return vec2(-b-h, -b+h );
}

float map(in vec3 p) {
	
	float res = 0.;
	
    vec3 c = p;
	for (int i = 0; i < 10; ++i) {
        p =.7*abs(p)/dot(p,p) -.7;
        p.yz= csqr(p.yz);
        p=p.zxy;
        res += exp(-19. * abs(dot(p,c)));
        
	}
	return res/2.;
}



vec3 raymarch( in vec3 ro, vec3 rd, vec2 tminmax )
{
    float t = tminmax.x;
    float dt = .02;
    //float dt = .2 - .195*cos(iTime*.05);//animated
    vec3 col= vec3(0.);
    float c = 0.;
    for( int i=0; i<64; i++ )
	{
        t+=dt*exp(-2.*c);
        if(t>tminmax.y)break;
                
        c = map(ro+t*rd);               
        
        col = .99*col+ .08*vec3(c*c, c, c*c*c);//green	
        //col = .99*col+ .08*vec3(c*c*c, c*c, c);//blue
    }    
    return col;
}


void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	float time = iTime;
    vec2 q = fragCoord.xy / iResolution.xy;
    vec2 p = -1.0 + 2.0 * q;
    p.x *= iResolution.x/iResolution.y;
    vec2 m = vec2(0.);
	if( iMouse.z>0.0 )m = iMouse.xy/iResolution.xy*3.14;
    m-=.5;

    // camera

    vec3 ro = zoom*vec3(4.);
    ro.yz*=rot(m.y);
    ro.xz*=rot(m.x+ 0.1*time);
    vec3 ta = vec3( 0.0 , 0.0, 0.0 );
    vec3 ww = normalize( ta - ro );
    vec3 uu = normalize( cross(ww,vec3(0.0,1.0,0.0) ) );
    vec3 vv = normalize( cross(uu,ww));
    vec3 rd = normalize( p.x*uu + p.y*vv + 4.0*ww );

    
    vec2 tmm = iSphere( ro, rd, vec4(0.,0.,0.,2.) );

	// raymarch
    vec3 col = raymarch(ro,rd,tmm);
    if (tmm.x<0.)col = texture(iChannel0, rd).rgb;
    else {
        vec3 nor=(ro+tmm.x*rd)/2.;
        nor = reflect(rd, nor);        
        float fre = pow(.5+ clamp(dot(nor,rd),0.0,1.0), 3. )*1.3;
        col += texture(iChannel0, nor).rgb * fre;
    
    }
	
	// shade
    
    col =  .5 *(log(1.+col));
    col = clamp(col,0.,1.);
    fragColor = vec4( col, 1.0 );

}
