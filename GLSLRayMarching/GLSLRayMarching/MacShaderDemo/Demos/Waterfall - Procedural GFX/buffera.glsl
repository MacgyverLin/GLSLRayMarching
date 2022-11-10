/*
Procural image made for Revision 2020 4k Excutable Graphics competition
It's a direct reference to M.C. Escher's "Waterfall" with an awesome impossible geometry.
https://www.pouet.net/prod.php?which=85268

See a bit behind the magic here: https://twitter.com/NuSan_fx/status/1249424629783027712
*/

// sin-hash

float rnd11(float t) { return fract(sin(t*274.577)*352.841);}
vec3 rnd23(vec2 uv) {return fract(sin(uv.xyy*427.512+uv.yxx*374.524+uv.xyx*742.814)*342.554);}
float rnd31(vec3 t) {return fract(dot(sin(t*274.577+t.yzx*427.544),vec3(352.841)));}

float rnd21(vec2 p)
{
	vec3 p3  = fract(vec3(p.xyx) * .1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

float srnd21(vec2 p)
{
    vec2 ip=floor(p);
    p=fract(p);
    //p=smoothstep(0.,1.,p);
    
    float p1 = mix(rnd21(ip),rnd21(ip+vec2(1,0)),p.x);
    float p2 = mix(rnd21(ip+vec2(0,1)),rnd21(ip+vec2(1,1)),p.x);
    
    return mix(p1,p2,p.y);
}

float noise21(vec2 p, float pro, float st) {
    float v=0.0;
    float s=0.5;
    for(float i=0.; i<st; ++i) {
        v+=srnd21(p+i*72.3)*s;
        p*=pro;
        s*=0.5;
    }
    return v;
}

float pi=acos(-1.);
mat2 rot(float a) {return mat2(cos(a),sin(a),-sin(a),cos(a));}

float c01(float a) {return clamp(a,0.,1.);}

// stroke effects
float samp(vec2 uv, float col) {
    
    float base = col;
    float ret = 1.0;
        
	float alpha=0.7;
    for(float i=1.0; i>0.0; i-=0.1) {
        alpha=min(alpha,smoothstep(0.01,0.1,i-base));
        vec2 scale = vec2(40.0,1.0)*45.0*(1.0+0.2*rnd11(i+232.1));
        //vec2 uv3 = uv*rot(sin(rnd11(i+72.84))*.9 - 1.5);
		vec2 uv3 = uv*rot((rnd11(i+72.84)-.5)*.5);
        uv3.x += rnd11(i*3.2+12.7);
        float tval = noise21(uv3*scale,1.7,10.);
        //col *= mix(1.,step(tval*1.2-0.1,base),0.5);
        //tval=smoothstep(0.3,0.6,tval);
		tval=smoothstep(0.3,0.4,tval);
        ret *= mix(1.0,tval,alpha);
    }
    return ret;
}

// FIRST PASS

// noise value per pixel/frame
// to use for visual trickeries
float blend=0.0;

vec3 s,r,n=vec3(0);
vec3 boxid=vec3(0);

vec3 localpos=vec3(0);
float nd = 10000.0;

vec3 cutplane=vec3(0,1,0);

float box(vec3 p, vec3 s) {
    p=abs(p)-s;
    return max(p.x, max(p.y,p.z));
	//return length(max(p,vec3(0))) + min(0.,max(p.x,max(p.y,p.z)));
}

float box2(vec2 p, vec2 s) {
    p=abs(p)-s;
    return max(p.x, p.y);
}

float rep(float a, float d) {
	return (fract(a/d+.5)-.5)*d;
}

vec2 rep2(vec2 a, vec2 d) {
	return (fract(a/d+.5)-.5)*d;
}

float octa(vec3 p, float s) {
	p = abs(p);
    float m = p.x + p.y + p.z - s;
	return m*0.577;
}

float pathpart(vec3 p, float h) {
    
    vec3 bp=p;
    
    float d = box(p,vec3(6,h,1));
    p.y+=1.;    
    
    p.x-=0.0;
    p.x=abs(p.x);
    p.x-=5.0;
    p.xz=abs(p.xz);
    p.xz-=1.0;
    
    // we cut and blend the parts of the bridge
	float cut = dot(bp, cutplane)-1.0 - blend*2.;
    float d2 = box(p, vec3(0.2,10.0,0.2));
    d2 = max(d2, cut);
    
    d=min(d, d2);
    
    return d;
}

float pathtop(vec3 p) {
    
    vec3 bp=p;
    
	vec3 p2 = p+vec3(-5,7,0);
	p2.yz *= rot(-pi*0.5);
    p2.xy *= rot(-1.8);
	p2=abs(p2);
    p2.xy *= rot(pi*0.25);
    p2.yz *= rot(pi*0.25);
    p2=abs(p2);
    p2.yz *= rot(pi*0.25);
    p2.xy *= rot(pi*0.25);

	vec3 p3 = p+vec3(5,7,0);
	p3.yz *= rot(pi*0.5);
    p3.xy *= rot(.4);
	float b2 = box(p3, vec3(1.4));
	p3.xy*=rot(pi*.25);
	p3.yz*=rot(pi*.25);
	b2=min(b2, box(p3, vec3(1.4)));
	p3.yz*=rot(pi*.25);
	p3.xy*=rot(pi*.25);
	b2=min(b2, box(p3, vec3(1.4)));

    p.x=abs(p.x);
    p.x-=5.0;
    
    p.y+=5.0;
    float d = box(p,vec3(2.0,0.2,2.0));

	d=min(d, octa(p2, 2.5));
	d=min(d, b2);
    	
    p.y-=5.0;

    p.xz=abs(p.xz);
    p.xz-=1.0;
    
    float d2 = box(p, vec3(0.2,5.0,0.2));
    
    d=min(d, d2);
	    
    return d;
}

float waterpath(vec3 p) {
    
    vec3 bp=p;
    
    p.xz=-p.xz;
    p.xz+=vec2(15.,0.);
    if(p.x<p.z) p.xz=p.zx;
    p.x-=10.;
    if(p.x<p.z) p.xz=p.zx;
    p.y+=1.;
    return box(p,vec3(11,max(0.0,0.95 - bp.x*0.03),0.8));
}

float path(vec3 p){
    
    p.z+=10.;
    p.y+=3.;

    float d = pathpart(p,1.);
    p.xz=-p.zx+vec2(5,-5);
    d=min(d,pathpart(p,0.6));
    p.xz=-p.zx+vec2(5,-5);
    d=min(d,pathpart(p,0.4));
    p.xz=-p.zx+vec2(5,-5);
    d=min(d,pathpart(p,0.2));
    
    d=max(d, -waterpath(p));
    d=min(d, pathtop(p));
    
    p+=vec3(5,-0.1,2);
    d=min(d, box(p,vec3(1,0.3,1)));
    p.y+=0.33;
    d=max(d, -box(p,vec3(0.8,0.3,1.9)));
    
    return d;
}

vec3 cx,cy,cz=vec3(0);

float hou1(vec3 p) {

	vec3 bp=p;
	vec3 bp2=p;
	p+=vec3(-9,-.5,6);

	float d1=box2(p.xz,vec2(5,8));
	d1=min(d1, box2(p.xz-vec2(5,2.),vec2(3,5)));

	vec2 p2 = vec2(d1,p.y);
	float d = box2(p2, vec2(1,4.5));
	
	p.y+=5.0;
	d=min(d,max(abs(abs(p.y+0.3)-.3)-0.1, abs(d1)-0.2));

	p.xz=rep2(p.xz,vec2(1.0));
	d=min(d,box(p,vec3(0.1,1,0.1)));
	d=max(d,box2(p2,vec2(0.5,10)));

	bp+=vec3(-8,4,4);
	float d3 = box(bp,vec3(5,10,3));
	bp.z=-abs(bp.z);
	bp.y+=10.;
	float d4=dot(bp.yz,vec2(-0.7));
	d3=max(d3,d4);
	d3=min(d3, max(abs(d4)-0.15, box2(bp.xz-vec2(.5,0),vec2(5.5,4))));
	d3=max(d3, -box(bp2+vec3(-13.5,5.2,5.5), vec3(1,1.5,0.7)));
	vec3 bp3=bp2+vec3(-12.5,13,5);
	d3=min(d3, box(bp3, vec3(0.5,3,0.3)));
	float d5=dot(vec2(bp3.y+3.5,-abs(bp3.z)),vec2(-0.7));
	d3=min(d3,max(abs(d5)-0.1, max(abs(bp3.x),abs(bp3.z))-0.6));
		
	d=min(d, d3);
	d=min(d, max(d1,10.4-bp.y));

	// water entry
	d=max(d, -box(bp2+vec3(-3,7.5,10),vec3(5,4,1)));
	
	return d;
}

float wheel(vec3 p) {
	p+=vec3(-8,5.5,10);
	float d=max(abs(length(p.xy)-1.1)-.2,abs(p.z)-1.6);
	vec3 p3 = p-cz*35.;
	d=min(d, max(length(p3.xy)-0.8,abs(p3.z-2.5)-3.));
	float a=atan(p.x,-p.y)*pi*2.;
	a=rep(a,3.);
	vec3 p2=vec3(a, length(p.xy),p.z);
	p2.y-=1.3;
	d=min(d, box(p2, vec3(0.2,0.6,1.3))*.5);

	p+=vec3(-2,-2.5,0);

	p += sin(p.yzx*7.0+vec3(.4,.3,2.9))*.5;
	float s=(length(p)-1.0)*.3;
	s=max(s,length(p)-3.);

	d=min(d,s);

	return d;
}

float water(vec3 p) {
	p+=vec3(-9.5,5.,9.7);
	float d1 = length(p.xy+vec2(2,10.1))-2.0;
	d1=min(d1,box2(p.xy,vec2(.0,10.0)));
	
	float d= max(abs(d1)-.1,abs(p.z)-0.7);
	
	d=max(d, min((10.+p.y), -.1-p.x));
	d=max(d,-2.6-p.x);
	d=min(d, box(p+vec3(3.8,12,0),vec3(1.8,0.2,0.7)));
	d=min(d, box(p+vec3(4.8,12.1,3),vec3(0.8,0.1,3.0)));
	return d;
}

float stair(vec3 p, float size, float w, float h) {
  vec3 bp=p;
  p.xy *= rot(pi*0.25);
  p.x=rep(p.x,size*2.0);
  p.xy *= rot(pi*0.25);
  float d=box(p, vec3(size,size,w));
  d=max(d, abs(bp.y)-h);
  return d;
}

float back(vec3 p) {

	p+=vec3(10,12,0);

	vec3 ra = vec3(atan(p.x,p.z)*pi*2., p.y,length(p.xz)-80.0);

	ra.zy *= rot(-0.7);
	ra.z=rep(ra.z, 3.);
	ra.zy *= rot(0.7);

	float d = box(ra, vec3(20,1,1));
	d=max(d,dot(p.zx,normalize(vec2(-1.2,1))));

	d=max(d, 10.-abs(p.y-5.));

	return d;
}

float fore(vec3 p) {
	p+=vec3(3,0,17);
	float d=box(p, vec3(3,3,7));
	d=max(d,-box(p+vec3(0,4.5,0), vec3(2.5,2,5.5)));
	vec3 p2=p+vec3(0,1,-3.5);
	p2.y=max(0.,-p2.y);
	d=max(d, 1.-length(p2.zy));
	p.z+=5.;
	d=min(d,box(p, vec3(3.5,6,3.5)));
	d=max(d,-box(p+vec3(0,7,0), vec3(3,1.5,3)));

	return d;
}

float map(vec3 p){
    float d=10000.0;

	vec3 p5=p-vec3(10,11,-26);
	d=min(d, box(p5,vec3(20,10,15)));
	p5+=vec3(-4,6,-10.5);
	d=max(d, -box(p5,vec3(10,5,4)));
	p5+=vec3(5.5,0,13.5);
	d=max(d, -box(p5,vec3(7,10,9)));
	
    d=min(d, path(p));
    
    // close house
	d=min(d, max(hou1(p),p.z+9.5+blend*1.));

	// duplicated house but farer for visual trickery
	vec3 p3 = p-cz*35.;
	d=min(d, max(hou1(p3),-p.z-1.5));
    
    // left part
	p3+=vec3(1.5,0,1);
	vec3 p4=p3;
	p4.y=max(0.,-p4.y);
	d=max(d, 3.-length(p4.xy+vec2(-19,0)));
	d=min(d, box(p3+vec3(-20,-5,3),vec3(5,4,5)));
	d=max(d, -box(p3+vec3(-20,-1,3),vec3(4,1,4)));
		
	// arc 2
	vec3 p2=p+vec3(-7,0,0);
	p2.y=max(0.,-p2.y);
	d=max(d, -max(length(p2.xy)-2., abs(p2.z)-18.));
	
	d=min(d,wheel(p));

	float limw = -13.-p.y+blend*8.;
	d=min(d,max(water(p),limw));
	d=min(d,water(p-cz*31.2));

	d=min(d, back(p));
	d=min(d, fore(p));

	// Bottom part
    p5+=vec3(2.5,2,-14);
	d=min(d, box(p5,vec3(15,1,4)));
	p5+=vec3(1.5,1.25,0);
	d=min(d, stair(p5.zyx*vec3(-1.2,1.2,1), 0.35, 0.5, 2.));
	p5+=vec3(2.5,-1.25,7);
	d=min(d, stair(p5.zyx*vec3(-1,1,1), 0.25, 2.0, 2.));

    d=min(d, -p.y+50.);
    
    return d;
}


bool gotclose = false;
bool gotfar = false;


// suggested from tdhooper. Thanks!
// improve compilation time & overall fps.
const int NORMAL_STEPS = 6;
vec3 normal(vec3 pos) {
	vec3 eps = vec3(.01, 0, 0);
	vec3 nor = vec3(0);
	float invert = 1.;
	for (int i = 0; i < NORMAL_STEPS; i++) {
		nor += map(pos + eps * invert) * eps * invert;
		eps = eps.zxy;
		invert *= -1.;
	}
	return normalize(nor);
}

void trace() {
  
  vec3 p=s;
  for(int i=0; i<100; ++i) {
	float d=map(p);
      if(d<0.05) gotclose=true;
      if(gotclose && d>0.05) gotfar=true;
      if(d<0.001) break;
      if(d>100.0) break;
      p+=r*d;
  }
    
  vec2 off=vec2(0.01,0);
  n=normal(p);
    
  s = p;
}

float shadow(vec3 l) {
    float shad=1.0;
    vec3 p=s+n*0.1+l*0.1;
    float dd=0.;
    for(int i=0;i<50; ++i) {
        float d=map(p);
        //shad=min(shad,(abs(d)-.1)*10.);
        if(d<0.1) {
            shad=0.0;
            break;
        }
        if(dd>20.) break;
        p+=l*d;
        dd+=d;
    }
    return shad;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{	         
    vec2 frag = fragCoord.xy;
	vec2 uv = (frag-iResolution.xy*0.5)/iResolution.y;
    
    vec4 finalcolor = vec4(0);
    if(iFrame>0) {
        finalcolor += texture(iChannel0, fragCoord/iResolution.xy);
    }
    
    // verify if middle mouse clicked or if resolution changed
    if(iMouse.z > .5 || texelFetch(iChannel0, ivec2(0),0).y != iResolution.y) {
        finalcolor=vec4(0);
    }
	
    int tilecount = 10;
    int curtile = int(frag.y*float(tilecount)/iResolution.y);
    
    if(iFrame%tilecount == curtile) {
        float col=0.0;

        bool isback=false;

        if(abs(uv.x)<0.43) {
            uv+=vec2(0.02,0.045);

            vec3 finalp=vec3(0);
            vec3 finals=vec3(0);
            vec3 finaln=vec3(0,1,0);

            s=vec3(50,-40,-50);
            vec3 t = vec3(0,-4,0);

            cz=normalize(t-s);
            cx=normalize(cross(cz,vec3(0,1,0)));
            cy=cross(cz,cx);

            cutplane = cy;

            float fov = 34.0;

            float motime = iTime;

            float edge=1.0;
            float edge2=1.0;

            blend = rnd21(frag+vec2(motime,0));

            vec2 h = rnd23(frag-13.6+motime*37.7).xy * vec2(1.,6.283);
            vec3 voff = sqrt(h.x)*(cx*sin(h.y)+cy*cos(h.y))*.3/iResolution.y;
            // ortho
            s += vec3((uv.x*cx+uv.y*cy)*fov);
            r=normalize(cz + voff);
            // persp
            //r=normalize(uv.x*cx+uv.y*cy+fov*cz + voff*fov);
            finals=s;

            vec3 bs = s;
            float alpha=1.0;
            int bounce=4;
            int ZERO = min(0,iFrame);
            for(int j=ZERO; j<bounce; ++j) {
                trace();
                if(j==0) {
                    finalp=s; // s;
                    finaln=n;
                    if(gotfar) {
                        edge=0.0;
                    }
                }

                if(length(s)>200.) {
                    //col +=2.0*alpha*abs(r.y);
                    col += 2.7*alpha*c01(-r.y*2.);
                    break;
                } else {

                    vec3 id2 = floor(s*1.0+.01);
                    float r3d2 = rnd31(id2*27.33);



                    float fre=pow(max(0.,1.-abs(dot(r,n))),1.0);

                    float val=0.0;

                    vec3 l = normalize(vec3(4,-11,-1));
                    vec3 l2 = normalize(vec3(4,-3,-2)); // cheating !
                    float shad = shadow(l2);
                    //val += shad * 0.4;
                    val += shad * max(0.,dot(n,l)) * 1.2;

                    val=max(0.0,val);

                    col += val*alpha;


                    float rough = 1.0;// 0.0+1.0*r3d2;

                    if(j==0) {
                        //col = mix(col, 0.1, smoothstep(30,70,length(s)));
                        if(length(s)>38.) isback=true;
                        else {
                            edge2 *= step(0.9,map(s+n*0.05)/0.05);
                            edge2 *= step(0.9,-map(s-n*0.05)/0.05);
                        }
                    }

                    r=normalize(reflect(r,n) + normalize(rnd23(frag+vec2(0,j*375)+motime*172.3)-.5)*rough);

                    alpha *= fre;
                    s+=n*0.005;
                }
            }

            col *= mix(edge*edge2,1.,0.4);	

            #if 1
            // apply stroke effect
            float base=pow(col*.7,0.8)-0.0;
            vec3 projpos = finalp*2.0/length(finalp-finals);
            //vec3 projpos = finalp*0.02;
            vec3 vals = vec3(samp(projpos.zy, base), samp(projpos.zx, base), samp(projpos.xy, base));
            vec3 facts = abs(finaln);
            facts /= dot(facts,vec3(1.0));
            float newcol = dot(vals,facts);

            col *= mix(newcol,1.,0.3);
            #endif

            if(isback) {
                col=c01(col)*.4+.4;
            }

        }

        finalcolor += vec4(vec3(col)*mix(vec3(0.9,0.7,0.5), vec3(1.), smoothstep(0.8,0.9, col)), 1);
    }
    
    // store last rendered resolution
    if(ivec2(fragCoord)==ivec2(0)) {
        finalcolor=iResolution.xyxy;
    }
    
    fragColor = finalcolor;
}
