#define AUTOROTATE 1

#define FARCLIP    25.0

#define MARCHSTEPS 60
#define AOSTEPS    20
#define SHSTEPS    20
#define SHPOWER    2.0

#define PI         3.14
#define PI2        PI*0.5    

#define AMBCOL     vec3(1.0,1.0,1.0)
#define BACCOL     vec3(1.0,1.0,1.0)
#define DIFCOL     vec3(1.0,1.0,1.0)

#define MAT1       1.0  //terrain
#define MAT2       2.0  //sea
#define MAT3       3.0  //h walls
#define MAT4       4.0  //h roof


/***********************************************/
float rbox(vec3 p, vec3 s, float r) {	
    return length(max(abs(p)-s+vec3(r),0.0))-r;
}
float sdTriPrism(vec3 p, vec2 h){
    vec3 q = abs(p);
    return max(q.x-h.y,max(q.z*0.166025+p.y*0.5,-p.y)-h.x*0.5);
}
float pyramid( vec3 p, float h) {
	vec3 q=abs(p);
	return max(-p.y, (q.x+q.y+q.z-h)/3.0 );
}

vec2 rot(vec2 k, float t) {
    float ct=cos(t); 
    float st=sin(t);
    return vec2(ct*k.x-st*k.y,st*k.x+ct*k.y);
}


/***********************************************/

vec2 house(vec3 p) {
    float d=rbox(p,vec3(0.6,0.4,0.3),0.01);
    //so much crap for a few windows.. lol
    vec3 q=-abs(p);
        q+=vec3(0.09,0.28,0.3);
            q.x=clamp(q.x,-0.4,0.55);
            q.y=clamp(q.y, 0.0,0.6);
        q.x=mod(q.x,0.18)-0.5*0.18;
        q.y=mod(q.y,0.3)-0.5*0.3;
        float w=rbox(q,vec3(0.035,0.06,0.1),0.01);
    d=max(d,-w);
    q.x=-abs(p.x);
        q.xz+=vec2(0.6,-0.2);   
        w=rbox(q,vec3(0.1,0.06,0.035),0.01);
    d=max(d,-w);
    //roof
    p.y-=0.43;
        w=sdTriPrism(p,vec2(0.07,0.61));
//    d=min(d,w);
    return mix(vec2(d,MAT3), vec2(w,MAT4), step(w, d));
}

vec2 tower(vec3 p, float h) {
    float d=rbox(p,vec3(0.25,h,0.25),0.02);
    //windows
    vec3 q=p;
    q.y-=h*0.45;
    q.xy=-abs(q.xy)+vec2(0.3,0.17);
        float w=rbox(q,vec3(0.1,0.06,0.035),0.01);
    d=max(d,-w);

    //roof
    p.y-=h;
    p.xz=rot(p.xz,0.785398163);
    w=pyramid(p,0.4);
    
    return mix(vec2(d,MAT3), vec2(w,MAT4), step(w, d));
}


vec2 DE(vec3 p) {
    //terrain
    vec2 uv=-vec2(-p.x*0.002, p.z*0.002-0.02);
    float d=p.y+4.0 -texture(iChannel0, uv).x*5.0 + texture(iChannel0, p.xz*0.08).x*0.2;
    vec2 terrain=vec2(d*0.4,MAT1); 
  
    //sea 
    uv=vec2(p.y+2.0+sin(p.x+iTime)*0.02-texture(iChannel1, p.xz*0.02+iTime*0.003).x*0.5, MAT2);
    uv.x+=texture(iChannel1, p.xz*0.013-iTime*0.002).x*0.4;
    terrain=mix(terrain, uv, step(uv.x, terrain.x));

    vec2 castle=vec2(FARCLIP,0.0);
    //castle
    vec3 q=p;
    p.z-=0.8;
    if (p.z>-2.0 && p.z<2.0) {
        p.xy+=vec2(0.7,0.1);
        p.z=mod(p.z,2.0)-0.5*2.0;
        castle=house(p);
    } 

    p.z=-abs(q.z);
    p-=vec3(1.35,-0.2,-0.5);
    p.xz=rot(p.xz,1.8);
    uv=house(p);
    castle=mix(castle, uv, step(uv.x, castle.x));
    
    p=q;
    p.xz=rot(p.xz,1.5);
    p-=vec3(-0.90,-0.5,-0.9);
    uv=house(p);
    castle=mix(castle, uv, step(uv.x, castle.x));

    //towers
//    p=q;
    q.x-=0.4;
    uv=tower(q,0.6);
    castle=mix(castle, uv, step(uv.x, castle.x));
    q.xz-=vec2(-0.7,0.4);
    uv=tower(q,1.2);
    castle=mix(castle, uv, step(uv.x, castle.x));
    q.xz-=vec2(0.2,0.8);
    uv=tower(q,0.8);
    castle=mix(castle, uv, step(uv.x, castle.x));
 

    return mix(terrain, castle, step(castle.x, terrain.x));
}
/***********************************************/
vec3 normal(vec3 p) {
	vec3 e=vec3(0.01,-0.01,0.0);
	return normalize( vec3(	e.xyy*DE(p+e.xyy).x +	e.yyx*DE(p+e.yyx).x +	e.yxy*DE(p+e.yxy).x +	e.xxx*DE(p+e.xxx).x));
}
/***********************************************/
float calcAO(vec3 p, vec3 n ){
	float ao = 0.0;
	float sca = 1.0;
	for (int i=0; i<AOSTEPS; i++) {
        	float h = 0.01 + 1.2*pow(float(i)/float(AOSTEPS),1.5);
        	float dd = DE( p+n*h ).x;
        	ao += -(dd-h)*sca;
        	sca *= 0.65;
        if( ao>1.0 ) break;
    	}
   return clamp( 1.0 - 1.0*ao, 0.0, 1.0 );
 //  return clamp(ao,0.0,1.0);
}
/***********************************************/
float calcSh( vec3 ro, vec3 rd, float s, float e, float k ) {
	float res = 1.0;
    for( int i=0; i<SHSTEPS; i++ ) {
    	if( s>e ) break;
        float h = DE( ro + rd*s ).x;
        res = min( res, k*h/s );
    	s += 0.02*SHPOWER;
        if( res<0.001 ) break;
    }
    return clamp( res, 0.0, 1.0 );
}
/***********************************************/
#ifndef AUTOROTATE
void rotc( inout vec3 p, vec3 r) {
	float sa=sin(r.y); float sb=sin(r.x); float sc=sin(r.z);
	float ca=cos(r.y); float cb=cos(r.x); float cc=cos(r.z);
	p*=mat3( cb*cc, cc*sa*sb-ca*sc, ca*cc*sb+sa*sc,	cb*sc, ca*cc+sa*sb*sc, -cc*sa+ca*sb*sc,	-sb, cb*sa, ca*cb );
}
#endif
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
	vec3 ro =vec3(0.0, 5.0, -9.0);  //0.0,6.0,-15
	vec3 lig=normalize(vec3(0.0, 4.0, -15.0));

#ifdef AUTOROTATE	
	ro.z-=sin(iTime*0.1)*2.0;
    ro.xz=rot(ro.xz,iTime*0.123);
    ro.yz=rot(ro.yz,sin(iTime*0.075)*0.3);
    lig.xz=rot(lig.xz,iTime*0.123);
#else
	vec2 mp=iMouse.xy/iResolution.xy;
	rotc(ro,vec3(mp.x,mp.y,0.0));
	rotc(lig,vec3(mp.x,mp.y,0.0));
#endif
	vec3 cf = normalize( ta - ro );
    vec3 cr = normalize( cross(cf,vec3(0.0,1.0,0.0) ) );
    vec3 cu = normalize( cross(cr,cf));
	vec3 rd = normalize( p.x*cr + p.y*cu + 2.5*cf );

	vec3 col=vec3(0.82,0.85,0.92);
	/* trace */
	vec2 r=vec2(0.0);	
	float d=0.0;
	vec3 ww;
	for(int i=0; i<MARCHSTEPS; i++) {
		ww=ro+rd*d;
		r=DE(ww);		
        if( abs(r.x)<0.00 || r.x>FARCLIP ) break;
        d+=r.x;
	}
    r.x=d;
	/* draw */
	if( r.x<FARCLIP ) {
	    vec2 rs=vec2(0.0,0.2);  //rim and spec

	    if (r.y==MAT1) {
	            col=vec3(1.0,0.76,0.55)*texture(iChannel1,ww.xz*0.2).xyz*1.6;
	            col=mix(col,vec3(0.1,0.66,0.25),texture(iChannel0,ww.xz*0.05).x*0.5);
	    }
	    if (r.y==MAT2) { col=vec3(0.13,0.16,0.35); rs=vec2(1.0); }


	    if (r.y==MAT3) { col=3.75*texture(iChannel2,ww.xy*3.0).xyz*texture(iChannel2,ww.zy*3.0).xyz; rs.y=0.4; }
	    if (r.y==MAT4) { col=vec3(0.76,0.46,0.35); rs.y=0.4; }


		vec3 nor=normal(ww);

    	float amb= 1.0;		
    	float dif= clamp(dot(nor, lig), 0.0,1.0);
    	float bac= clamp(dot(nor,-lig), 0.0,1.0);
    	float rim= pow(1.+dot(nor,rd), 3.0);
    	float spe= pow(clamp( dot( lig, reflect(rd,nor) ), 0.0, 1.0 ) ,16.0 );
    	float ao= calcAO(ww, nor);
    	float sh= calcSh(ww, lig, 0.01, 2.0, 4.0);

	    col *= 0.5*amb*AMBCOL*ao + 0.4*dif*DIFCOL*sh + 0.05*bac*BACCOL*ao;
	    col += 0.3*rim*amb * rs.x;
    	col += 0.5*pow(spe,1.0)*sh * rs.y;


        vec3 ff=vec3(0.82,0.85,0.92);
        col=fog(col,ff,r.x*0.047,ww.y);
	}



	fragColor = vec4( col, 1.0 );
}
