vec3 scatter =vec3(0.);
float sp = 2.0833;
vec3 lpos1=vec3(0); vec3 lpos2=vec3(0);
vec3 lpos3=vec3(0, 1, 0);

float time =0.;
float kk=0.;
void dmin(inout vec3 d, float x, float y, float z)
{
	if( x < d.x ) d = vec3(x, y, z);
}

// method by iq/shane
float noise(vec3 p)
{
	vec3 ip=floor(p);
	p-=ip;
	vec3 s=vec3(7, 157, 113);
	vec4 h=vec4(0, s.yz, s.y+s.z)+dot(ip, s);
	p=p*p*(3.-2.*p);
	h=mix(fract(sin(h)*43758.5), fract(sin(h+s.x)*43758.5), p.x);
	h.xy=mix(h.xz, h.yw, p.y);
	return mix(h.x, h.y, p.z);
}

float hash11(float p)
{
	p = fract(p * .1031);
	p *= p + 19.19;
	p *= p + p;
	return fract(p);
}

// method by fizzer
vec3 hashHs(vec3 n, float seed)
{
	float u = hash11(78.233+seed);
	float v = hash11(10.873+seed);
	float a = 6.2831853 * v;
	u = 2.0*u - 1.0;
	return normalize(n+vec3(sqrt(1.0-u*u) * vec2(cos(a), sin(a)), u));
}

void pR(inout vec2 p, float a)
{
	p = cos(a)*p+sin(a)*vec2(p.y, -p.x);
}

float sdRoundBox(vec3 p, vec3 b, float r)
{
	vec3 d = abs(p) - b;
	return length(max(d, 0.0)) - r;
}

float pattern(vec2 p)
{
	p.x += 5.5;
	p.y *= 2.;
	p = floor(p);
	if( iTime>160./sp*kk&&iTime<192./sp ) p.y += floor(iTime*sp/2.)*17.;
	p = floor(p);
	return (sin(p.x*p.y) > .8) ? 2. : .9;
}

float vines(vec3 p, float s, float t)
{
	p.x=abs(p.x)+t*.1;
	pR(p.yz, p.x*1.); p=abs(p); p.yz -= .06*s;
	pR(p.yz, p.x*-3.); p=abs(p); p.yz -= .05*s;
	pR(p.yz, p.x*5.+t); p=abs(p); p.yz -= .04*(s*.5+.5);
	return length(p.yz);
}

vec3 map(vec3 p, bool flag)
{
	float wallnoise = (noise(83.*p)+noise(17.*p))*noise(7.*p);
	vec3 d = vec3(1, 0, 0);

	float sd1 = length(p+lpos1)-.4;
	float sd2 = length(p+lpos2)-.4;
	float waves = 0.;
	if( iTime > 48./sp) waves=0.03;						
	dmin(d, 1.49+kk*2.5-abs(p.x+0.01*wallnoise), .99-0.5*wallnoise, 0.); 
	if( kk>0. ) {
		dmin(d, 1.2+p.y, pattern(p.xz)-.6*wallnoise, 0.); 	

		dmin(d,
			max(vines(p+vec3(0, 0, 2), .5+5./(1.+p.x*p.x*2.), iTime)-.02,
				max(
					abs(p.x)-3.,
					3.5-(iTime-77.)*.25+max(iTime-192./sp, 0.)*2.+sin(p.y*20.)*sin(p.z*10.) - abs(p.x)
				)
			),.1, .2);

		vec3 q=p.yxz;
		q.z=fract(q.z/3.-.2)*3.-1.5;
		q.y=abs(q.y)-3.5;
		q.x -= 6.;
		dmin(d,vines(q, 1.3+20./(1.+q.x*q.x*.45), 0.)-.05,.1, .2);
	}
	else {
		dmin(d, .8-waves*sin(8.*p.z+time)*sin(6.*p.x+1.6*time+sin(2.*p.z))+p.y, .25, waves);
		dmin(d, 0.75-p.z, .8*sin(20.*p.x), 0.); 	
		dmin(d, 0.8-p.y, pattern(p.xz)-.6*wallnoise, 0.); 	
	}
	float amp = 0.;
	if( iTime > 96./sp &&fract(iTime*sp/4.)<=0.75+kk )  amp=abs(sin(20.*p.z));
	if( iTime>96./sp && flag && fract(iTime*sp/4.)<=0.75+kk )
	{
		scatter += max(-(sd1-1.2), 0.)*.06*vec3(0, 1, 1); 
		scatter += max(-(sd2-1.2), 0.)*.06*vec3(2, 1, 0);
	}

	if( iTime>32./sp )
	{
		dmin(d,sd1,.07+amp,-1.);
		dmin(d,sd2,.07+amp,1.); 
	}

	vec3 q = abs(p);
	if (iTime>24./sp&&fract(iTime*sp/8.)>=0.924-kk&&(iTime<60./sp||iTime>64./sp))
	{
		q.x -= 1.49+kk*2.4;
		q.y -= .4+.4*sin(time)*(1.-kk)+kk*.4;
		dmin(d, length(q.xy)-.015, 2., -.4);
	}

	if( iTime>64./sp)
		if( iTime<192./sp)
		{
			q=p+vec3(0, 0, 2.);
			pR(q.xy, 0.33*time);
			pR(q.xz, 0.4*time);
			float rb=sdRoundBox(q, vec3(.48), .08);
			dmin(d, rb, -.7+1.9*abs(sin(10.*q.x+10.*q.y)), 0.);
		}
		else
			dmin(d, length(p+vec3(0, 0, 2))-.5, .07+amp, 0.);
	return d;
}

vec3 normal(vec3 p)
{
	vec2 e = vec2(0,.0001);
	return normalize(map(p, false).x-vec3(map(p - e.yxx, false).x, map(p - e.xyx, false).x, map(p - e.xxy, false).x));
}
void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
	time=iTime*1.;
	kk = step(128., iTime*sp);
	if( fract(iTime*sp/8.)<.75 )
	{
		time += fract(-iTime*sp)+17.*ceil(iTime*sp);
		kk = step(156., iTime*sp);
	}

	vec2 uv = fragCoord.xy / iResolution.xy;
	fragColor = vec4(0);
	if( uv.y>.11 && uv.y<.89 )
	{
		float t1 = 0., t2 = 0., t3=0., seed = 0.;
		vec3 ro1 = vec3(0, 0, -2.5-kk*(1.+max(159.-iTime*sp, 0.)+max(iTime*sp-192., 0.)*.1)),
			 rd1 = normalize(vec3((2.*fragCoord.xy-iResolution.xy)/iResolution.x, 1));

		if( iTime>160./sp&&iTime<192./sp)
		{
			vec2 ca=sin(vec2(.35, .47)*(iTime+fract(-iTime/8.*sp)+42.*ceil(iTime/8.*sp)))*vec2(1., .3);
			pR(ro1.zy, ca.y); pR(rd1.zy, ca.y);	
			pR(ro1.xz, ca.x); pR(rd1.xz, ca.x);	
		}
        
		ro1.z-=2.5;
		lpos1 = vec3(1.*cos(time), .3*sin(time), 2.+sin(0.5*time));	
		lpos2 = vec3(1.2*cos(0.3*time), .4*sin(0.4*time), 2.+sin(0.2*time));
		lpos3=vec3(sin(0.5*time), 1, 0);
		if( kk>0. )
		{
			lpos1 = vec3(3, 0, 2);
			lpos2 = vec3(-3, 0, 2);
			lpos3=vec3(0, -1, 0);
		}
		seed=uv.x*uv.y+uv.y+uv.x+fract(iTime);
		vec3 scol=vec3(0), m1, m2, m3, ro2, rd2, nor1, nor2, pos1, pos2, pos3;

		for( int i = 0; i < 150; i++ )
		{
			seed=32.+seed*fract(seed);
			pos1 = ro1+rd1*t1;
			m1 = map(pos1, true);
			t1+=0.2*(m1.x);

			if( m1.x<0.001 )
			{
				scol+= vec3(1.+m1.z, 1., 1.-m1.z)*step(1., m1.y)*(150.-float(i))*(m1.z==.03 ? vec3(.6, .8, 1.) : vec3(1));
				break;
			}
			pos2=pos1+mix(lpos3, hashHs(lpos3, seed), 0.15)*t2; 
			m2 = map(pos2, false);
			t2+=m2.x;

			if( m2.y>=1.&&m2.z==0. )
				scol+=(.5+5.*m1.x*noise(7.*pos1+mix(vec3(iTime), vec3(0, -iTime, 0), kk)));	
		}

		nor1 = normal(pos1);
		m1.y=clamp(m1.y, 0., 1.);
		t2=0.;
		for( int i = 1; i < 100; i++ )
		{
			seed=32.+seed*fract(seed);
			rd2 = mix(reflect(rd1, nor1), hashHs(nor1, seed), m1.y);
			pos2 = pos1+ rd2*t2;
			m2 = map(pos2, false);
			t2+=0.2*m2.x;
			scol += vec3(1.+m2.z, 1., 1.-m2.z)*step(1., m2.y)*(m1.z==.03 ? vec3(.6, .8, 1.) : vec3(1));

		}

		scol=clamp(.009*scol+.06*scatter, 0., 1.) * clamp((236. / sp - iTime) / 8., 0., 1.);;

		fragColor =mix(scol.xyzz, texture(iChannel0, uv), pow(.0001, iTimeDelta));
	}
}
