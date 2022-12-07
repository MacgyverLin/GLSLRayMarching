//Cloud Ten
//by nimitz 2015 (twitter: @stormoid)
//License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License
// Contact the author for other licensing options

#define time iTime
mat2 mm2(in float a){float c = cos(a), s = sin(a);return mat2(c,s,-s,c);}
float noise(float t){return textureLod(iChannel0,vec2(t,.0)/iChannelResolution[0].xy,0.0).x;}
float moy = 0.;

float noise(in vec3 p)
{
    vec3 ip = floor(p);
    vec3 fp = fract(p);
	fp = fp*fp*(3.0-2.0*fp);
	vec2 tap = (ip.xy+vec2(37.0,17.0)*ip.z) + fp.xy;
	vec2 rz = textureLod( iChannel0, (tap+0.5)/256.0, 0.0 ).yx;
	return mix( rz.x, rz.y, fp.z );
}

float fbm(in vec3 x)
{
    float rz = 0.;
    float a = .35;
    for (int i = 0; i<2; i++)
    {
        rz += noise(x)*a;
        a*=.35;
        x*= 4.;
    }
    return rz;
}

float path(in float x){ return sin(x*0.01-3.1415)*28.+6.5; }
float map(vec3 p){
    return p.y*0.07 + (fbm(p*0.3)-0.1) + sin(p.x*0.24 + sin(p.z*.01)*7.)*0.22+0.15 + sin(p.z*0.08)*0.05;
}

float march(in vec3 ro, in vec3 rd)
{
    float precis = .3;
    float h= 1.;
    float d = 0.;
    for( int i=0; i<17; i++ )
    {
        if( abs(h)<precis || d>70. ) break;
        d += h;
        vec3 pos = ro+rd*d;
        pos.y += .5;
	    float res = map(pos)*7.;
        h = res;
    }
	return d;
}

vec3 lgt = vec3(0);
float mapV( vec3 p ){ return clamp(-map(p), 0., 1.);}
vec4 marchV(in vec3 ro, in vec3 rd, in float t, in vec3 bgc)
{
	vec4 rz = vec4( 0.0 );
	
	for( int i=0; i<150; i++ )
	{
		if(rz.a > 0.99 || t > 200.) break;
		
		vec3 pos = ro + t*rd;
        float den = mapV(pos);
        
        vec4 col = vec4(mix( vec3(.8,.75,.85), vec3(.0), den ),den);
        col.xyz *= mix(bgc*bgc*2.5,  mix(vec3(0.1,0.2,0.55),vec3(.8,.85,.9),moy*0.4), clamp( -(den*40.+0.)*pos.y*.03-moy*0.5, 0., 1. ) );
        col.rgb += clamp((1.-den*6.) + pos.y*0.13 +.55, 0., 1.)*0.35*mix(bgc,vec3(1),0.7); //Fringes
        col += clamp(den*pos.y*.15, -.02, .0); //Depth occlusion
        col *= smoothstep(0.2+moy*0.05,.0,mapV(pos+1.*lgt))*.85+0.15; //Shadows
        
		col.a *= .95;
		col.rgb *= col.a;
		rz = rz + col*(1.0 - rz.a);

        t += max(.3,(2.-den*30.)*t*0.011);
	}

	return clamp(rz, 0., 1.);
}

float pent(in vec2 p){    
    vec2 q = abs(p);
    return max(max(q.x*1.176-p.y*0.385, q.x*0.727+p.y), -p.y*1.237)*1.;
}

vec3 lensFlare(vec2 p, vec2 pos)
{
	vec2 q = p-pos;
    float dq = dot(q, q);
    vec2 dist = p*(length(p))*0.75;
	float ang = atan(q.x,q.y);
    vec2 pp = mix(p, dist, 0.5);
    float sz = 0.01;
    float rz = pow(abs(fract(ang*.8+.12)-0.5),3.)*(noise(ang*15.))*0.5;
    rz *= smoothstep(1.0, 0.0, dot(q,q));
    rz *= smoothstep(0.0, 0.01, dot(q,q));
    rz += max(1.0/(1.0 + 30.0*pent(dist + 0.8*pos)),.0)*0.17;
	rz += clamp(sz-pow(pent(pp + 0.15*pos),1.55),.0, 1.)*5.0;
	rz += clamp(sz-pow(pent(pp + 0.1*pos),2.4),.0, 1.)*4.0;
	rz += clamp(sz-pow(pent(pp - 0.05*pos),1.2),.0, 1.)*4.0;
    rz += clamp(sz-pow(pent((pp + .5*pos)),1.7),.0, 1.)*4.0;
    rz += clamp(sz-pow(pent((pp + .3*pos)),1.9),.0, 1.)*3.0;
    rz += clamp(sz-pow(pent((pp - .2*pos)),1.3),.0, 1.)*4.0;
    return vec3(clamp(rz,0.,1.));
}

mat3 rot_x(float a){float sa = sin(a); float ca = cos(a); return mat3(1.,.0,.0,    .0,ca,sa,   .0,-sa,ca);}
mat3 rot_y(float a){float sa = sin(a); float ca = cos(a); return mat3(ca,.0,sa,    .0,1.,.0,   -sa,.0,ca);}
mat3 rot_z(float a){float sa = sin(a); float ca = cos(a); return mat3(ca,sa,.0,    -sa,ca,.0,  .0,.0,1.);}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{	
    vec2 q = fragCoord.xy / iResolution.xy;
    vec2 p = q - 0.5;
	float asp =iResolution.x/iResolution.y;
    p.x *= asp;
	vec2 mo = iMouse.xy / iResolution.xy;
	moy = mo.y;
    float st = sin(time*0.3-1.3)*0.2;
    vec3 ro = vec3(0.,-2.+sin(time*.3-1.)*2.,time*30.);
    ro.x = path(ro.z);
    vec3 ta = ro + vec3(0,0,1);
    vec3 fw = normalize( ta - ro);
    vec3 uu = normalize(cross( vec3(0.0,1.0,0.0), fw ));
    vec3 vv = normalize(cross(fw,uu));
    const float zoom = 1.;
    vec3 rd = normalize( p.x*uu + p.y*vv + -zoom*fw );
    
    float rox = sin(time*0.2)*0.6+2.9;
    rox += smoothstep(0.6,1.2,sin(time*0.25))*3.5;
   	float roy = sin(time*0.5)*0.2;
    mat3 rotation = rot_x(-roy)*rot_y(-rox+st*1.5)*rot_z(st);
	mat3 inv_rotation = rot_z(-st)*rot_y(rox-st*1.5)*rot_x(roy);
    rd *= rotation;
    rd.y -= dot(p,p)*0.06;
    rd = normalize(rd);
    
    vec3 col = vec3(0.);
    lgt = normalize(vec3(-0.3,mo.y+0.1,1.));  
    float rdl = clamp(dot(rd, lgt),0.,1.);
  
    vec3 hor = mix( vec3(.9,.6,.7)*0.35, vec3(.5,0.05,0.05), rdl );
    hor = mix(hor, vec3(.5,.8,1),mo.y);
    col += mix( vec3(.2,.2,.6), hor, exp2(-(1.+ 3.*(1.-rdl))*max(abs(rd.y),0.)) )*.6;
    col += .8*vec3(1.,.9,.9)*exp2(rdl*650.-650.);
    col += .3*vec3(1.,1.,0.1)*exp2(rdl*100.-100.);
    col += .5*vec3(1.,.7,0.)*exp2(rdl*50.-50.);
    col += .4*vec3(1.,0.,0.05)*exp2(rdl*10.-10.);  
    vec3 bgc = col;
    
    float rz = march(ro,rd);
    
    if (rz < 70.)
    {   
        vec4 res = marchV(ro, rd, rz-5., bgc);
    	col = col*(1.0-res.w) + res.xyz;
    }
    
    vec3 proj = (-lgt*inv_rotation);
    col += 1.4*vec3(0.7,0.7,0.4)*clamp(lensFlare(p,-proj.xy/proj.z*zoom)*proj.z,0., 1.);
    
    float g = smoothstep(0.03,.97,mo.x);
    col = mix(mix(col,col.brg*vec3(1,0.75,1),clamp(g*2.,0.0,1.0)), col.bgr, clamp((g-0.5)*2.,0.0,1.));
    
	col = clamp(col, 0., 1.);
    col = col*0.5 + 0.5*col*col*(3.0-2.0*col); //saturation
    col = pow(col, vec3(0.416667))*1.055 - 0.055; //sRGB
	col *= pow( 16.0*q.x*q.y*(1.0-q.x)*(1.0-q.y), 0.12 ); //Vign

	fragColor = vec4( col, 1.0 );
}