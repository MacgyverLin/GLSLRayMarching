#define FARCLIP    55.0

#define MARCHSTEPS 60
#define SHSTEPS    30
#define SHPOWER    1.5

#define MAT1       1.0

#define CLD1 iTime*0.35
#define CLD2 iTime*0.15

/***********************************************/

float hash(float n) { 
	return fract(sin(n)*43758.5453123); 
}

float noise3(vec3 x) {
    vec3 p = floor(x);
    vec3 f = fract(x);
    f = f*f*(3.0-2.0*f);
    float n = p.x + p.y*57.0 + p.z*113.0;
    float res = mix(mix(mix( hash(n+  0.0), hash(n+  1.0),f.x),
                        mix( hash(n+ 57.0), hash(n+ 58.0),f.x),f.y),
                    mix(mix( hash(n+113.0), hash(n+114.0),f.x),
                        mix( hash(n+170.0), hash(n+171.0),f.x),f.y),f.z);
    return res;
}

/***********************************************/
vec2 DE(vec3 p) {
    vec2 t=vec2( (p.y+4.0-texture(iChannel0,p.xz*0.002).x*5.0- texture(iChannel0,p.xz*0.03).x*0.2 )*0.5, 1.0);
    
    float g=p.y+2.4;
    if (t.x>g) t.x=g;
    
    return t;
}

/***********************************************/

void DEcloudsPWR(vec3 p, float t, inout float cpwr) {
    float c= -p.y-1.0-noise3(p*1.9+CLD1)*0.4;
    if (c>t) cpwr=c-t;
}

vec4 DEclouds(vec3 p, vec3 lig) {
    float c=-p.y-1.0-noise3(p*1.3+CLD1)*0.6;
        vec4 clr =vec4( mix( vec3(0.1,0.1,0.1), vec3(0.8,0.9,1.0), c*0.5 ), clamp(c,0.0,1.0));
        float ww=-p.y-1.0-noise3(p*1.5+0.6*lig+CLD2)*0.8;
	    float dif =  clamp((clr.w - ww)/0.6, 0.0, 1.0 );
        vec3 brdf = 0.9+ vec3(0.6, 0.5, 0.4)*dif;  
	clr.xyz *= brdf;
    clr.w*=0.35;
    clr.xyz*=clr.w;
    return clr;
}

/***********************************************/
vec3 normal(vec3 p) {
	vec3 e=vec3(0.01,-0.01,0.0);
	return normalize( vec3(	e.xyy*DE(p+e.xyy).x +	e.yyx*DE(p+e.yyx).x +	e.yxy*DE(p+e.yxy).x +	e.xxx*DE(p+e.xxx).x));
}
/***********************************************/
float calcSh( vec3 ro, vec3 rd, float s, float e, float k ) {
	float res = 1.0;
    for( int i=0; i<SHSTEPS; i++ ) {
    	if( s>e ) break;
        float h = DE( ro + rd*s ).x;
        res = min( res, k*h/s );
    	s += 0.02*SHPOWER;
    }
    return clamp( res, 0.0, 1.0 );
}

/***********************************************
void rot( inout vec3 p, vec3 r) {
	float sa=sin(r.y); float sb=sin(r.x); float sc=sin(r.z);
	float ca=cos(r.y); float cb=cos(r.x); float cc=cos(r.z);
	p*=mat3( cb*cc, cc*sa*sb-ca*sc, ca*cc*sb+sa*sc,	cb*sc, ca*cc+sa*sb*sc, -cc*sa+ca*sb*sc,	-sb, cb*sa, ca*cb );
}

/***********************************************/
#define sun normalize(vec3(-0.4,0.15,1.0))

vec3 sky(vec3 rd){
    float sa=max(dot(rd,sun),0.0);
    float v=pow(0.9-max(rd.y+0.1,0.0),12.0);
    vec3 s=mix(vec3(0.8,0.6,0.3),vec3(0.1,0.1,0.1),v);
        s=s+vec3(0.7,0.2,0.0)*sa*sa*0.5;
        s=s+vec3(1.0,2.0,1.0)*min(pow(sa,650.0)*1.5,0.3);
    return clamp(s,0.0,1.0);
}
/***********************************************/
vec3 fog(vec3 color, vec3 fcolor, float depth, float density){
	const float e = 2.71828182845904523536028747135266249;
	float f = pow(e, -pow(depth*density, 2.0));
	return mix(fcolor, color, f);
}

/***********************************************/
void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
    vec2 p = -1.0 + 2.0 * fragCoord.xy / iResolution.xy;
    p.x *= iResolution.x/iResolution.y;	
	vec3 ta = vec3(0.0, 0.0, 0.0);
	vec3 ro =vec3(0.0, 1.3, -5.0);
    vec3 lig=vec3(0.0,1.0,1.0);

ta.z+=iTime*2.5;
ro.z+=iTime*2.5;
	
/*	vec2 mp=iMouse.xy/iResolution.xy;
	rot(ro,vec3(mp.x,mp.y,0.0));
	rot(lig,vec3(mp.x,mp.y,0.0));	*/

	vec3 cf = normalize( ta - ro );
    vec3 cr = normalize( cross(cf,vec3(0.0,1.0,0.0) ) );
    vec3 cu = normalize( cross(cr,cf));
	vec3 rd = normalize( p.x*cr + p.y*cu + 2.5*cf );

	vec4 clds=vec4(0.0);
	float cpwr=0.0;
	
	//march terrain ...
	vec2 r=vec2(0.0);	
	float d=0.0;
	vec3 ww;
	for(int i=0; i<MARCHSTEPS; i++) {
		ww=ro+rd*d;
		r=DE(ww);
    	DEcloudsPWR(ww,r.x,cpwr);
        if( abs(r.x)<0.0 || r.x>FARCLIP ) break;
        d+=r.x;
	}
    r.x=d;
    
    //march clouds ...
    float t=0.0;
    for(int i=0; i<MARCHSTEPS; i++) {
		vec3 p=ro+rd*t;
		clds+=DEclouds(p,lig)*(1.0 - clds.w);
		t+=0.6;
	}

	//colors ... 
	
    vec3 col=sky(rd);

	if( r.x<FARCLIP ) {
            vec3 nor=normal(ww);
        	float amb= 1.0;		
        	float dif= clamp(dot(nor, lig), 0.0,1.0);
        	float bac= clamp(dot(nor,-lig), 0.0,1.0);
        	float sh= calcSh(ww, lig, 0.01, 2.0, 4.0);

    		if (r.y==MAT1) ww=vec3(1.3)* texture(iChannel1, ww.xz*0.2).xyz;
    	    ww *= 0.5*amb + 0.4*dif*sh + 0.05*bac;
    	    
		   //faking sunlight like a big boy here
    	   vec3 colf=mix(col*0.8,ww, clamp(abs(nor.z*1.8), 0.0,1.0));     
    	   
           colf = mix( colf, clds.xyz, clamp(cpwr,0.0,1.0) );

           col=fog(colf, col, r.x, 0.03);
	} else {
	    //clouds top
	    ro.z-=iTime*100.0;
	    float sd=dot(rd,sun);
	    float t = clamp( pow(1.0-0.5*rd.y, 8.0), 0.0,1.0);
	    clds=vec4(0.0);
	        for (int i=0; i<MARCHSTEPS; i++) {
                float c = (float(i-MARCHSTEPS)*2.0+3.0-ro.y) / rd.y;
                vec3 cpos = ro + rd*c;
                     cpos*=vec3(0.007,0.025,0.0062);
                float a = smoothstep(0.0, 1.0, noise3( cpos ))*0.8; 
                vec3 lc = mix(vec3( 0.8, 0.8, 0.9 ), vec3( 0.1,0.1,0.1 ), a); 
                a=(1.0-clds.w)*a; 
                clds += vec4(lc*a, a); 
                if (clds.w>0.9) break;
            }
            
            clds.rgb /= clds.w+0.001;
            col=mix( col, clds.rgb , clds.w*(1.0-t) );            
	} 

	fragColor = vec4( col, 1.0 );
}
