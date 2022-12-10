//By Sergio
#define AA 1
float sdElipsoid(vec3 pos,vec3 rad){
	float k0 = length(pos/rad);
    float k1 = length(pos/rad/rad);
	return k0*(k0-1.0)/k1;
}

float sdRoundBox( vec3 p, vec3 b, float r )
{
  vec3 d = abs(p) - b;
  return length(max(d,0.0)) - r
         + min(max(d.x,max(d.y,d.z)),0.0); 
}

float sdCappedCylinder( vec3 p, float h, float r )
{
  vec2 d = abs(vec2(length(p.xz),p.y)) - vec2(h,r);
  return min(max(d.x,d.y),0.0) + length(max(d,0.0));
}
float sdCapsule( vec3 p, vec3 a, vec3 b, float r )
{
    vec3 pa = p - a, ba = b - a;
    float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
    return length( pa - ba*h ) - r;
}
float sdTriPrism( vec3 p, vec2 h )
{
    vec3 q = abs(p);
    return max(q.z-h.y,max(q.x*0.866025+p.y*0.5,-p.y)-h.x*0.5);
}

float det( vec2 a, vec2 b ) { return a.x*b.y-b.x*a.y; }
vec3 getClosest( vec2 b0, vec2 b1, vec2 b2 ) 
{
    float a =     det(b0,b2);
    float b = 2.0*det(b1,b0);
    float d = 2.0*det(b2,b1);
    float f = b*d - a*a;
    vec2  d21 = b2-b1;
    vec2  d10 = b1-b0;
    vec2  d20 = b2-b0;
    vec2  gf = 2.0*(b*d21+d*d10+a*d20); gf = vec2(gf.y,-gf.x);
    vec2  pp = -f*gf/dot(gf,gf);
    vec2  d0p = b0-pp;
    float ap = det(d0p,d20);
    float bp = 2.0*det(d10,d0p);
    float t = clamp( (ap+bp)/(2.0*a+b+d), 0.0 ,1.0 );
    return vec3( mix(mix(b0,b1,t), mix(b1,b2,t),t), t );
}

vec4 sdBezier( vec3 a, vec3 b, vec3 c, vec3 p )
{
	vec3 w = normalize( cross( c-b, a-b ) );
	vec3 u = normalize( c-b );
	vec3 v =          ( cross( w, u ) );

	vec2 a2 = vec2( dot(a-b,u), dot(a-b,v) );
	vec2 b2 = vec2( 0.0 );
	vec2 c2 = vec2( dot(c-b,u), dot(c-b,v) );
	vec3 p3 = vec3( dot(p-b,u), dot(p-b,v), dot(p-b,w) );

	vec3 cp = getClosest( a2-p3.xy, b2-p3.xy, c2-p3.xy );

	return vec4( sqrt(dot(cp.xy,cp.xy)+p3.z*p3.z), cp.z, length(cp.xy), p3.z );
}


float sdSphere(vec3 pos,float rad){
	return length(pos)-rad;
}
float smin( float a, float b, float k )
{
    float h = max( k-abs(a-b), 0.0 )/k;
    return min( a, b ) - h*h*k*(1.0/4.0);
}

float smax( float d1, float d2, float k ) {
    float h = clamp( 0.5 - 0.5*(d2+d1)/k, 0.0, 1.0 );
    return mix( d2, -d1, h ) + k*h*(1.0-h); }

float sdRoundedCylinder( vec3 p, float ra, float rb, float h )
{
    vec2 d = vec2( length(p.xz)-2.0*ra+rb, abs(p.y) - h );
    return min(max(d.x,d.y),0.0) + length(max(d,0.0)) - rb;
}
vec2 smallLarva(vec3 p){

    float rad = 0.25+abs(p.y/7.+0.01);
    vec3 q =p;
    
    
    //BODY
	float d1 = sdElipsoid(q,vec3(rad,0.4,rad-0.03));
    float m;
    
    float k;
 

 
    //HEAD
    
    vec3 hp = p;
    
    hp.y+=sin(hp.x*34.)*0.01;
    hp.y+=sin((hp.x+0.95)*5.)*0.16;
  
    //hp.x-=hp.z*hp.z*k;
    float head = sdRoundBox(hp-vec3(0.0,0.15,0.08),vec3(0.15,0.005,0.07),0.001);
    d1=smin(head,d1,0.1);
    float at = sdElipsoid(p-vec3(0.0,0.4,0.08),vec3(0.009,0.1,0.009));
    at = min(at,sdElipsoid(p-vec3(0.1,0.34,0.08),vec3(0.009,0.1,0.009)));
    at = min(at,sdElipsoid(p-vec3(-0.1,0.34,0.08),vec3(0.009,0.1,0.009)));
    d1 = smin(d1,at,0.01);
    
    //MOUTH
    vec3 cp = p;
    float a;
    a= 1.5708;
    cp.zy*=mat2(cos(a),sin(a),-sin(a),cos(a));
    cp.x*=0.6;
    cp.z*=0.8;
 	float c = sdRoundedCylinder(cp-vec3(0,-0.1,0.1),0.02,0.01,0.2);
    cp.x*=0.5;
    float c1 = sdRoundedCylinder(cp-vec3(0,-0.1,0.14),0.02,0.4,0.2);
    
    c = max(-c1,c);
   
    if(-c>d1){
    m = 3.5;
    }
    else{
    m =1.5;
    }
    d1 = smax(c,d1,0.007);
   
    //EYE
    float k1 = mix(1.,1.,(sign(q.x)+1.)/2.);
    q.x = abs(q.x);
    float eye = sdElipsoid(q-vec3(0.08,0.2,0.17),vec3(0.084,0.074,0.064)*k1);
    /*
    q = qc;
    q-=vec3(0.00,0.17,0.162);
  
    q.x=abs(q.x);
    q.y-=pow(q.x-0.08,2.)*1.2;
    .x-=0.08;
    float eyecap = sdRoundedCylinder(q,0.04,0.02,0.001);
    float em = 2.5;
    if(eyecap<eye) em = 1.5;
   
    eye = smin(eye,eyecap,0.02); */
    if(eye<d1){
    	m = 2.5;
    }
   
    d1 = smin(eye,d1,0.01);
    
    //TEETH
    vec3 tp = p;
   	tp.y-=tp.x*tp.x*12.2;
    tp.x=abs(tp.x);
    float teeth = sdRoundBox(tp-vec3(0.0,0.12,0.21),vec3(0.02,0.005,0.002)/1.4,0.01);
    tp = p;
    tp.x+=0.035;
   	tp.y-=tp.x*tp.x*12.2;
    tp.x=abs(tp.x+0.01);
    teeth = min(sdRoundBox(tp-vec3(-0.0,0.12,0.21),vec3(0.02,0.005,0.002)/1.4,0.01),teeth);
    tp = p;
    tp.x-=0.035;
   	tp.y-=tp.x*tp.x*12.2;
    teeth = min(sdRoundBox(tp-vec3(-0.0,0.12,0.21),vec3(0.02,0.005,0.002)/1.4,0.01),teeth);
    if(teeth<d1){
    m = 4.5;
    }
    
    d1 =min(d1,teeth);
    
    //TONGUE
    vec3 top = p;
   	top -=vec3(0.0,-0.035,0.3);
    
    float tx = 0.06;
    tx+=(p.z+0.2);
    tx/=12.2;
    a=-1.1;
    top.yz=mat2(cos(a),sin(a),-sin(a),cos(a))*top.yz;
    top.y+=top.z*top.z*1.;

    float tongue = sdElipsoid(top,vec3(tx,0.02,0.15));
    float t2 = sdElipsoid(p-vec3(0.,0.07,0.2),vec3(0.04,0.02,0.04));
    tongue = smin(tongue,t2,0.03);
    if(tongue<d1) m = 11.5;
    d1=min(tongue,d1);
    

    
    
    return vec2(d1,m);




}

vec2 BigLarva(vec3 p){
	
    vec3 mp = p;
    p.x-=0.7;
    vec3 gp = p;
    float m = 5.5;
    float rad = 0.35-((p.y)/10.);
    vec3 q =p-vec3(0.0,0.3,0.0);
	float d1 = sdElipsoid(q,vec3(rad,0.7,rad-0.03));
    float d2 = sdSphere(q-vec3(0.0,0.5,-0.1),0.17);
    d1 =smin(d2,d1,0.2);
   	float a =0.27;
    q-=vec3(-0.02,0.4,0.17);
 	q.yz=mat2(cos(a),sin(a),-sin(a),cos(a))*q.yz;

    
    //HEAD
    
    vec3 hp = p;
    hp.z+=0.07;
    hp.y-=0.66;
    hp.y+=sin(hp.x*24.-0.4)*0.03;
    hp.y+=sin((hp.x+0.95)*5.)*0.16;
  	float head = sdRoundBox(hp-vec3(0.0,0.15,0.08),vec3(0.15,0.005,0.07),0.001);
    d1=smin(head,d1,0.1);
    
    
    
    //HOLE
    a = -0.2;
    p.y-=0.44;
    p.z-=0.224;
    p.yz=mat2(sin(a),cos(a),-cos(a),sin(a))*p.yz;
    p.x=abs(p.x);
    p.x-=0.07;
    float hole = sdRoundedCylinder(p,0.024,0.02,0.02);
    
    
    
    //EYE
    float eye = sdElipsoid(q-vec3(0.07,0.1,0.01),vec3(0.075,0.094,0.06));
    eye = min(eye,sdElipsoid(q-vec3(-0.07,0.1,0.),vec3(0.075,0.094,0.06)));
    if(eye<d1){
    m = 6.5;
    }
    d1=smin(eye,d1,0.04);
    d1=min(d1,hole);
    p.x-=0.01;
    float h2 = sdCappedCylinder(p,0.028,0.156);
    if(-h2>d1){
    m = 3.5;
    }
   
   	d1=max(-h2,d1);
    
    //MOUTH
    mp-=vec3(0.7,0.2,0.3);
    a = 3.14159;
    mp.xy=mat2(cos(a),sin(a),-sin(a),cos(a))*mp.xy;
    float mouth = sdTriPrism(mp,vec2(0.09,0.22));
    
    if(-mouth>d1){
    m = 3.5;
    }
    
    
    
    d1=smax(mouth,d1,0.01);
    float cx = 0.03+mp.y*mp.y+0.1;
    cx/=7.4;
    a = -0.55;
    mp.x-=0.0;
    mp.y+=0.01;
    mp.z+=0.015;
   
    mp.xy=mat2(cos(a),sin(a),-sin(a),cos(a))*mp.xy;
    
    float cm = sdElipsoid(mp-vec3(0.05,0.0,0.0),vec3(cx,0.08,0.02));
    a = 0.55*2.;
    mp.xy=mat2(cos(a),sin(a),-sin(a),cos(a))*mp.xy;
    cm = smin(cm,sdElipsoid(mp-vec3(-0.05,0.0,0.0),vec3(cx,0.08,0.02)),0.05);
  
    d1=smin(cm,d1,0.01);
    
    //HEAD ANTENNA
  	a=2.3;

    gp -= vec3(-0.1,0.3,-0.1);
  	vec4 b = sdBezier( vec3(0.0,0.6,-0.0), vec3(-0.1,0.7,-0.1), vec3(-0.2,0.5,-0.15), gp );
    float at = b.x;
    at -= 0.03 - 0.025*b.y;
    at=smin(at,sdSphere(gp-vec3(-0.2,0.5,-0.15),0.03),0.01);
    d1=smin(at,d1,0.03);
    return vec2(d1,m);

}
vec2 rock(vec3 p){
    float x = p.x-0.7-1.4;
    float m = 7.5;
    vec3 q = p;
	p.y+=x*x*0.1;
    //SMALL ROCK
	float roc = sdRoundBox(p-vec3(1.2+1.4,-0.35,0.1),vec3(0.2,0.04,0.07)*3.,0.2);
    //BIG ROCK
    float ro = sdRoundBox(vec3(q.x+0.4,-0.3+q.y+sin(q.x*5.)*(0.01+(q.x*q.z)/53.),q.z)-vec3(-0.8,-0.1,-2.8),vec3(0.2,0.04,0.07)*10.,0.2)-0.5;
    
    float roc1 = sdElipsoid(q-vec3(-0.5,-0.6,0.2),vec3(0.2,0.08,0.09)*4.5);
    float dis = texture( iChannel3, 0.4*p.xy ).x+texture( iChannel2, 7.0*p.zx).x*1.5;
    dis += texture( iChannel3, 0.4*p.zy ).x+texture( iChannel2, 7.0*p.zy ).x*1.5;
 
    roc -= 0.005*dis*0.2;
    ro -= 0.005*dis*0.03;
    if(ro<roc) m = 9.5;
    roc=min(ro,roc);
    if(roc1<roc) m = 8.5;
   	roc1=min(roc,roc1);
    return vec2(roc1,m);

}
vec2 wheat(vec3 p){
	vec3 q =p;

    q-=vec3(2.3,-0.8,-0.3);
    
    vec4 b = sdBezier( vec3(0.0,0.6,-0.0), vec3(-0.0,1.3,0.0), vec3(-0.7/1.1,1.9,-0.0)/1.05, q )+0.001;
    float at = b.x;
    at -= 0.03 - 0.025*b.y;
    
    q = p-vec3(1.8,0.85,-0.3);
   	
    float a =(3.14159-1.4);
 
    q.xy=mat2(cos(a),sin(a),-sin(a),cos(a))*q.xy;
    q.x-=q.y*q.y*1.8;
    
    float off = (0.005+(q.y+0.1)/15.)*0.4;
 
    vec3 r  = q;
    float wh = sdElipsoid(q,vec3(off,0.025,off)*3.);
    q=p-vec3(1.87,0.9,-0.3);
   
    a = -a-1.14;
    q.xy=mat2(cos(a),sin(a),-sin(a),cos(a))*q.xy;
    q.x+=q.y*q.y*1.8;
    off = (0.005+(q.y+0.1)/15.)*0.4;
  
    vec3 l  = q;
    wh = min(wh,sdElipsoid(q,vec3(off,0.025,off)*3.));
    
    
    
    wh = min(wh,sdElipsoid(r+vec3(0.05,0.05,0.0),vec3(off,0.025,off)*2.5));
    
    wh = min(wh,sdElipsoid(l+vec3(-0.05,0.05,0.0),vec3(off,0.025,off)*2.5));
    wh = min(wh,sdElipsoid(r+vec3(0.05,0.05,0.0)*1.8,vec3(off,0.025,off)*2.3));
    
    wh = min(wh,sdElipsoid(l+vec3(-0.05,0.03,0.0)*1.8,vec3(off,0.025,off)*2.3));
    
    at = min(wh,at);
    return vec2(at,10.5);;


}

vec2 map(vec3 p){
    
    float ground = p.y+0.35;
    float m  = 0.5;
    vec2 r = rock(p);
    if(r.x<ground) m = r.y;
    ground = min(ground ,r.x);
    vec2 w = wheat(p);
    if(w.x<ground) m = w.y;
    ground = min(w.x,ground);
    vec2 slarva = smallLarva(p);
    vec2 blarva = BigLarva(p);
    if(blarva.x<slarva.x){
        slarva = blarva;
    }
 
    return ground<slarva.x ? vec2(ground,m):slarva; 
}

vec2 ray(vec3 ro,vec3 rd){

	float t;
    vec2 h;
    vec3 p;
    for(int i=0;i<200;i++){
    	p = ro+rd*t;
        h= map(p);
        if(h.x<0.0001) break;
        t+=h.x;
        if(t>20.) break;
    
    }
    if(t>20.) t = -1.;
    return vec2(t,h.y);


}

float softshadow( in vec3 ro, in vec3 rd, float mint, float maxt, float k )
{
    float res = 1.0;
    float ph = 1e20;
    for( float t=mint; t<maxt; )
    {
        float h = map(ro + rd*t).x;
        if( h<0.001 )
            return 0.0;
        float y = h*h/(2.0*ph);
        float d = sqrt(h*h-y*y);
        res = min( res, k*d/max(0.0,t-y) );
        ph = h;
        t += h;
    }
    return res;
}

float calcOcclusion( in vec3 pos, in vec3 nor )
{
	float occ = 0.0;
    float sca = 1.0;
    for( int i=0; i<5; i++ )
    {
        float h = 0.01 + 0.11*float(i)/4.0;
        vec3 opos = pos + h*nor;
        float d = map( opos ).x;
        occ += (h-d)*sca;
        sca *= 0.95;
        
    }
    return clamp( 1.0 - 2.0*occ, 0.0, 1.0 );
}

vec3 calcNorm(vec3 p){
	const float eps = 0.0001;
    vec4 n = vec4(0.0);
    for( int i=min(iFrame,0); i<4; i++ )
    {
        vec4 s = vec4(p, 0.0);
        s[i] += eps;
        n[i] = map(s.xyz).x;
    }
    return normalize(n.xyz-n.w);
}

vec3 render(vec3 ro,vec3 rd){
	vec2 t = ray(ro,rd);
    vec3 sk=vec3(1.-rd.y,1.-rd.y,1.);
   
    vec3 col = sk;
    
    
    if(t.x>0.0){
        
        vec3 p = ro+rd*t.x;
        vec3 n = calcNorm(p);
        
        //float an = iTime;
        
        vec3 sun = vec3(-0.6,0.7,-0.4);
        vec3 sky = vec3(0.0,1.,0.0);
       
        float occ = calcOcclusion(p,n);
        float dif = dot(n,sun);
        
        float skydif = clamp(0.5+0.5*dot(n,vec3(0.0,1.0,0.0)),0.0,1.0);
        
        float grodif = clamp(dot(n,vec3(0.0,-1.0,0.0)),0.0,1.0);
        //TONGUE
        if(t.y>11.){
             
           vec3 r = reflect(-sun,n);
           vec3 spec = pow(max(0.0,dot(r,-rd)),28.)*vec3(1.);
           col = vec3(1.,0.6,0.7)*occ*0.8;
           col += dot(rd+sun,n)*0.1;
           col+=sk*skydif*0.1*(1.+dot(rd+sun,n));
           col+=vec3(0.9,0.6,0.5)*grodif;
           col+=spec;
        
        }
        //WHEAT
        else if(t.y>10.){
          
           col = vec3(1.,0.8,0.)*occ*0.9*(clamp(dif/1.7,0.,1.)+1.);
           
           col/=1.;
            
           col+=(1.+dot(rd,n)*2.)*0.2;
           col+=sk*skydif*0.1*(1.+dot(rd+sun,n));
           col+=vec3(0.9,0.6,0.5)*grodif;
           col*=1.5+dot(rd,n);
       
         
        
        
        }
        
        //BIG ROCK
        else if(t.y>9.){
        	col = vec3(0.8,0.4,0.15);
            vec3 r = reflect(-sun,n);
           	vec3 spec = pow(max(0.0,dot(r,-rd)),28.)*vec3(1.);
            
          	float shad = softshadow(p+n*0.001,sun,0.001,2.,64.);
            col = texture(iChannel3,p.xy).rgb*vec3(0.8,0.4,0.15)*occ*0.9*(clamp(dif/1.7,0.,1.)+1.);
            col*=1.+shad/3.;
           	col/=1.;
            col/=1.1;
            col += 0.2+dot(rd+sun,n)*0.2;
            col*=1.2;
           	col+=sk*skydif*0.1;
            col+=vec3(0.9,0.6,0.5)*grodif;
         
        
        
        }
        //SMALL ROCK
        
        else if(t.y>8.){
        	col = vec3(0.8,0.4,0.15);
            vec3 r = reflect(-sun,n);
           	vec3 spec = pow(max(0.0,dot(r,-rd)),28.)*vec3(1.);
            
         
            col =vec3(0.5)*occ*0.9*(clamp(dif/1.7,0.,1.)+1.);
           
            col/=1.1;
         
           	col+=(1.+dot(rd,n)*2.)*0.2;
            col+=sk*skydif*0.1*(1.+dot(rd+sun,n));
            col+=vec3(0.9,0.6,0.5)*grodif;
            col+=spec*0.2;
        
        }
        //Shiny ROCK
        else if (t.y>7.){
        	col = vec3(0.8,0.4,0.15);
            vec3 r = reflect(-sun,n);
           	vec3 spec = pow(max(0.0,dot(r,-rd)),28.)*vec3(1.);
            
         
            col = vec3(0.8,0.4,0.15)*occ*0.9*(clamp(dif/1.7,0.,1.)+1.);
           
            col/=1.1;
         
           	col+=(1.+dot(rd,n)*2.)*0.2;
            col+=sk*skydif*0.1*(1.+dot(rd+sun,n));
            col+=vec3(0.9,0.6,0.5)*grodif;
            col+=spec;
        
        }
        //BIG LARVA'S EYE
        
        else if(t.y>6.){
            p.x-=0.676;
            float lid =step(length(vec2(abs(p.x),p.y)-vec2(0.052,0.8)),0.03);;
            float lid1 =step(length(vec2(abs(p.x),p.y)-vec2(0.052,0.8)),0.047);;
            p.x-=0.026;
           	p.y-=0.02;
            float spec =step(length(vec2((p.x),p.y)-(vec2(0.052,0.8))),0.007);;
            spec +=step(length(vec2((p.x),p.y)-(vec2(-0.052,0.8))),0.007);;
        	vec3 d = vec3(0.6);
         
            vec3 ref = reflect(rd,n);
            float fac = ( lid1+lid);
            col = d;
            col-=clamp(lid,0.,1.);
            col = clamp(lid1-lid,0.,1.)*vec3(0.8,.55,0.)*0.6+col*(1.-(lid1-lid));
            col+=texture(iChannel0,ref).xyz*fac*0.35;
            col = clamp(col,vec3(0.),vec3(1.));
            col += dot(-rd*1.2,n)/2.1;
            col += dot(rd+sun,n)*0.6;
            col+=spec/1.5;
            
            col*=1.4;
        
        
        }
        
        //BIG LARVA'S BODY
        else if(t.y>5.){
            vec3 mat = vec3(smoothstep(0.16,0.07,p.y)-smoothstep(-0.05,-0.1,p.y));
            mat += vec3(smoothstep(-0.15,-0.2,p.y)-smoothstep(-0.25,-0.3,p.y));
            vec2 sp = p.xy;
            sp -=vec2(0.72,0.41);
            sp.x=abs(sp.x);
            mat+=vec3(smoothstep(0.1,0.02,length(sp-vec2(0.17,0.0))))/1.3;
           
            col = vec3(1.,0.8,0.)*occ*0.9*(clamp(dif/1.7,0.,1.)+1.);
           
            col/=1.1;
          
            col=mix(col,vec3(0.88,0.35,0.01)/1.2,clamp(mat.x,0.,1.));

           	col+=(1.+dot(rd,n)*2.)*0.2;
            col+=sk*skydif*0.1*(1.+dot(rd+sun,n));
            col+=vec3(0.9,0.6,0.5)*grodif;
     
         
        
        
        }
        
        
        //SMALL LARVA'S TEETH
        else if(t.y>4.){
        	col = vec3(1.);
       	 	col += dot(-rd*1.2,n)/2.1;
        	col += dot(rd+sun,n)*0.6;
            
        }
        else if(t.y>3.0){
            
        	col = vec3(0.0);
        }
        
        //SMALL LARVA'S EYE
        else if(t.y>2.0){
            float lid =step(length(vec2(abs(p.x),p.y)-vec2(0.08,0.22)),0.03);;
            float lid1 =step(length(vec2(abs(p.x),p.y)-vec2(0.08,0.225)),0.047);;
             
            float spec =step(length(vec2((p.x),p.y)-(vec2(0.1,0.245))),0.003);;
            spec +=step(length(vec2((p.x),p.y)-(vec2(-0.05,0.245))),0.003);;
        	vec3 d = vec3(0.6);
             
            vec3 ref = reflect(rd,n);
            float fac = ( lid1+lid);
            col = d;
            col-=clamp(lid,0.,1.);
            col = clamp(lid1-lid,0.,1.)*vec3(1.,0.,0.)*0.6+col*(1.-(lid1-lid));
            col+=texture(iChannel0,ref).xyz*fac*0.35;
            col = clamp(col,vec3(0.),vec3(1.));
            col += dot(-rd*1.2,n)/2.1;
            col += dot(rd+sun,n)*0.6;
            col+=spec/1.5;
            
            col*=1.4;
            //col+=lid1*vec3(1.,0.,0.);
            
        }
        
        //SMALL LARVA BODY
        else if(t.y>1.0){
            
            vec3 r = reflect(-sun,n);
           	vec3 spec = pow(max(0.0,dot(r,-rd)),28.)*vec3(1.);
            vec3 mat = vec3(smoothstep(0.1,0.05,p.y)-smoothstep(-0.05,-0.1,p.y));
            mat += vec3(smoothstep(-0.15,-0.2,p.y)-smoothstep(-0.25,-0.3,p.y));
           
         
            col = vec3(1.,0.,0.)*occ*0.9;
            
            col=mix(col,vec3(1.,0.75,0.01)/1.2,clamp(mat.x,0.,1.));
  
            col += dot(rd+sun,n)*0.5;
            col+=sk*skydif*0.5;
            col+=vec3(0.9,0.6,0.5)*grodif;
            col+=spec;
          
        
       
            
            
        
        }
        	//GROUND
           else if(t.y>0.0){
            	float shad = softshadow(p+n*0.001,sun,0.001,2.,64.);
               col = vec3(0.7,0.5,0.3)*0.6*shad;
               col += dot(rd+sun,n);
               col+=sk*skydif*0.1;
             
          
           }
        
    
    }



	return col;


}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    #if AA<2
    vec2 uv = (2.*fragCoord-iResolution.xy)/iResolution.y;
    
   
			float an_x = 10.*-iMouse.x/iResolution.x;
   			float an_y = 10.*-iMouse.y/iResolution.y;
   			//an_x=0.;
   			an_x+=sin(iTime/20.)/5.-0.45;
    		vec3 ta = vec3(0.7,0.7,0.2);
    		float off =2.2;
     		vec3 ro = ta+vec3(sin(an_x)*off,-0.3,cos(an_x)*off);
     
    		vec3 ww = normalize(ta-ro);
    	
    		vec3 uu = normalize(cross(ww,vec3(0.0,1.0,0.0)));
                   
    		vec3 vv = normalize(cross(uu,ww));
                   
                   
          
    
    
    		vec3 rd = normalize(uv.x*uu+uv.y*vv+1.5*ww);
    
    
    vec3 col = render(ro,rd);
   #else

    vec3 col = vec3(0.);
    	for( int m=0; m<AA; m++ )
        for( int n=0; n<AA; n++ )
        {
         vec2 rr = vec2( float(m), float(n) ) / float(AA);
            vec2 uv = (2.*(fragCoord+rr)-iResolution.xy)/iResolution.y;
   
			float an_x = 10.*-iMouse.x/iResolution.x;
   			float an_y = 10.*-iMouse.y/iResolution.y;
   			//an_x=0.;
   			an_x+=sin(iTime/20.)/5.-0.45;
    		vec3 ta = vec3(0.7,0.7,0.2);
    		float off =2.2;
     		vec3 ro = ta+vec3(sin(an_x)*off,-0.3,cos(an_x)*off);
     
    		vec3 ww = normalize(ta-ro);
    	
    		vec3 uu = normalize(cross(ww,vec3(0.0,1.0,0.0)));
                   
    		vec3 vv = normalize(cross(uu,ww));
                   
                   
          
    
    
    		vec3 rd = normalize(uv.x*uu+uv.y*vv+1.5*ww);
    
     col+= render(ro,rd);
        
        }
    col /= float(AA*AA);
    #endif
   
    
    

   
    fragColor = vec4(col,1.0);
}