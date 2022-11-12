float st=.025, maxdist=15.;
vec3 ldir=vec3(0.,-1.,-1.),col=vec3(0.);

mat2 rot(float a) {
	float s=sin(a),c=cos(a);
    return mat2(c,s,-s,c);
}

vec3 fractal(vec2 p) {
    vec2 pos=p;
    float d, ml=100.;
    vec2 mc=vec2(100.);
    p=abs(fract(p*.1)-.5);
    vec2 c=p;
    for(int i=0;i<8;i++) {
        d=dot(p,p);
        p=abs(p+1.)-abs(p-1.)-p;
    	p=p*-1.5/clamp(d,.5,1.)-c;
        mc=min(mc,abs(p));
        if (i>2) ml=min(ml*(1.+float(i)*.1),abs(p.y-.5));
    }
    mc=max(vec2(0.),1.-mc);
    mc=normalize(mc)*.8;
    ml=pow(max(0.,1.-ml),6.);
    return vec3(mc,d*.4)*ml*(step(.7,fract(d*.1+iTime*.5+pos.x*.2)))-ml*.1;
}

float map(vec2 p) {
    vec2 pos=p;
    float t=iTime;
    col+=fractal(p);
    vec2 p2=abs(.5-fract(p*8.+4.));
	float h=0.;
    h+=sin(length(p)+t);
    p=floor(p*2.+1.);
    float l=length(p2*p2);
    h+=(cos(p.x+t)+sin(p.y+t))*.5;
    h+=max(0.,5.-length(p-vec2(18.,0.)))*1.5;
    h+=max(0.,5.-length(p+vec2(18.,0.)))*1.5;
    p=p*2.+.2345;
    t*=.5;
    h+=(cos(p.x+t)+sin(p.y+t))*.3;
    return h;
}

vec3 normal(vec2 p, float td) {
	vec2 eps=vec2(0.,.001);
    return normalize(vec3(map(p+eps.yx)-map(p-eps.yx),2.*eps.y,map(p+eps.xy)-map(p-eps.xy)));
}

vec2 hit(vec3 p) {
    float h=map(p.xz);
    return vec2(step(p.y,h),h);
}

vec3 bsearch(vec3 from,vec3 dir,float td) {
    vec3 p;
    st*=-.5;
    td+=st;
    float h2=1.;
    for (int i=0;i<20;i++) {
        p=from+td*dir;
        float h=hit(p).x;
        if (abs(h-h2)>.001) {
            st*=-.5;
	        h2=h;
        }
        td+=st;
    }
	return p;
}

vec3 shade(vec3 p,vec3 dir,float h,float td) {
    ldir=normalize(ldir);
	col=vec3(0.);
    vec3 n=normal(p.xz,td);
	col*=.25;
    float dif=max(0.,dot(ldir,-n));
    vec3 ref=reflect(ldir,dir);
    float spe=pow(max(0.,dot(ref,-n)),8.);
    return col+(dif*.5+.2+spe*vec3(1.,.8,.5))*.2;
}


vec3 march(vec3 from,vec3 dir) {
	vec3 p, col=vec3(0.);
    float td=.5, k=0.;
    vec2 h;
    for (int i=0;i<600;i++) {
    	p=from+dir*td;
        h=hit(p);
        if (h.x>.5||td>maxdist) break;
        td+=st;
    }
    if (h.x>.5) {
        p=bsearch(from,dir,td);
    	col=shade(p,dir,h.y,td);
    } else {
    }
	col=mix(col,2.*vec3(mod(gl_FragCoord.y,4.)*.1),pow(td/maxdist,3.));
    return col*vec3(.9,.8,1.);
}

mat3 lookat(vec3 dir,vec3 up) {
	dir=normalize(dir);vec3 rt=normalize(cross(dir,normalize(up)));
    return mat3(rt,cross(rt,dir),dir);
}

vec3 path(float t) {
	return vec3(cos(t)*5.5,1.5-cos(t)*.0,sin(t*2.))*2.5;
}

void mainImage(out vec4 fragColor,in vec2 fragCoord)
{
    vec2 uv = (fragCoord-iResolution.xy*.5)/iResolution.y;
	float t=iTime*.2;
    vec3 from=path(t);
    vec3 dir=normalize(vec3(uv,.7));
    vec3 adv=path(t+.1)-from;
    dir=lookat(adv+vec3(0.,-.2-(1.+sin(t*2.)),0.),vec3(adv.x*.1,1.,0.))*dir;
    vec3 col=march(from, dir)*1.5;
    fragColor = vec4(col,1.);
}