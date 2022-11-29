// Haunted forest shader
//
// Created by Frank Hugenroth /frankenburgh/ 04/2013

#define V2 1

// random/hash function              
float hash( float n )
{
  return fract(cos(n)*41415.92653);
}

// 2d noise function
float noise( in vec2 x )
{
  vec2 p  = floor(x);
  vec2 f  = smoothstep(0.0, 1.0, fract(x));
  float n = p.x + p.y*57.0;

  return mix(mix( hash(n+  0.0), hash(n+  1.0),f.x),
    mix( hash(n+ 57.0), hash(n+ 58.0),f.x),f.y);
}

// 3d noise function
float noise( in vec3 x )
{
  vec3 p  = floor(x);
  vec3 f  = smoothstep(0.0, 1.0, fract(x));
  float n = p.x + p.y*57.0 + 113.0*p.z;

  return mix(mix(mix( hash(n+  0.0), hash(n+  1.0),f.x),
    mix( hash(n+ 57.0), hash(n+ 58.0),f.x),f.y),
    mix(mix( hash(n+113.0), hash(n+114.0),f.x),
    mix( hash(n+170.0), hash(n+171.0),f.x),f.y),f.z);
}


mat3 m = mat3( 0.00,  1.60,  1.20, -1.60,  0.72, -0.96, -1.20, -0.96,  1.28 );

// Fractional Brownian motion
float fbm( vec3 p )
{
  float f = 0.5000*noise( p ); p = m*p*1.2;
  f += 0.2500*noise( p ); p = m*p*1.3;
  f += 0.1666*noise( p ); p = m*p*1.4;
  f += 0.0834*noise( p );
  return f;
}




float branch(in float ang, in vec2 uv, in float len, in float th, in float sharpness )
{
	float x = sin(ang*2.*3.14159);
	float y = cos(ang*2.*3.14159);

	float ans2 = y*uv.x-x*uv.y;
	bool hit2 = ans2>=0. && ans2< len;
	if (!hit2)
		return 1.0;

	float ans = x*uv.x+y*uv.y;

	float t = pow(1.-ans2/len, .25)*th + (1.0-ans2/len)*.01;
#ifdef V2
	ans += texture(iChannel0, vec2(ans2/len*.008+.74, th+.3)).r * 0.13;
	ans += texture(iChannel0, vec2(ans2/len*.01+.91, th+.3)).r * 0.06;
	ans += texture(iChannel0, vec2(ans2/len*.03+.5 , th+.4)).g * 0.06;
	ans += texture(iChannel0, vec2(ans2/len*.03+.51, th+.4)).g * 0.03;
#else
	ans += texture(iChannel0, vec2(ans2/len*.02+.74, th+.3)).r * 0.17;
	ans += texture(iChannel0, vec2(ans2/len*.02+.91, th+.3)).r * 0.09;
	ans += texture(iChannel0, vec2(ans2/len*.07+.5 , th+.4)).g * 0.09;
	ans += texture(iChannel0, vec2(ans2/len*.07+.51, th+.4)).g * 0.05;
#endif
	float val = clamp(pow(abs(ans) / abs(t), 1.), 0.0, 1.0);

	val = pow(val, sharpness);
	return val;
}


float trunk(in float ang, in vec2 uv, in float len, in float strength, in float sharpness )
{
	float x = sin(ang*2.*3.14159);
	float y = cos(ang*2.*3.14159);

	float ans2 = y*uv.x-x*uv.y;
	bool hit2 = ans2>=0. && ans2< len;
	if (!hit2)
		return 1.0;

	float ans = x*uv.x+y*uv.y;

	float t = pow(1.-ans2/len, .25)*strength + (1.0-ans2/len)*texture(iChannel0, vec2(ans2/len*.3, len*.8)).r*.025;
#ifdef V2
	ans += texture(iChannel0, vec2(ans2/len*.1, strength)).r * 0.04;
#else
	ans += texture(iChannel0, vec2(ans2/len*.2, strength)).r * 0.08;
#endif

	float val = clamp(pow(abs(ans) / abs(t), 1.), 0.0, 1.0);

	val = pow(val, sharpness);
	return val;
}


float fir(in float ang, in vec2 uv, in float len, in float strength, in float sharpness )
{
	float x = sin(ang*2.*3.14159);
	float y = cos(ang*2.*3.14159);

	float ans2 = y*uv.x-x*uv.y;
	bool hit2 = ans2>=0. && ans2< len;
	if (!hit2)
		return 1.0;

	float ans = x*uv.x+y*uv.y;

	float t = pow(1.-ans2/len, .25)*strength + (1.0-ans2/len)*texture(iChannel0, vec2(ans2/len*.3, len*.8)).r*.15;
	ans += texture(iChannel0, vec2(ans2/len*.2, strength)).r * 0.04;

	float val = clamp(pow(abs(ans) / abs(t), 1.), 0.0, 1.0);

	val = pow(val, sharpness);
	return val;
}


float tree2(in float ang, in vec2 uv, in float len, in float th, in float sharpness)
{
	float val = 1.;
	// mid
	float x = sin(ang*2.*3.14159);
	float y = cos(ang*2.*3.14159);
	vec2 uvl = uv + vec2(-y*len*0.42 +x*len*+0.01 , x*len*0.42 +y*len*+0.01 );
	vec2 uvr = uv + vec2(-y*len*0.37 +x*len*-0.01 , x*len*0.37 +y*len*-0.01 );
	val *= branch(ang, uv, len, th, sharpness) * branch(ang-.095, uvl, len*.7, th*.3, sharpness) * branch(ang+.075, uvr, len*0.8, th*.2, sharpness);
	return val;
}


float tree1(in float ang, in vec2 uv, in float len, in float th, in float sharpness)
{
	float val = 1.;
	// mid
	float x = sin(ang*2.*3.14159);
	float y = cos(ang*2.*3.14159);
#ifdef V2
	vec2 uvl = uv + vec2(-y*len*0.60 -x*len*0.09 , x*len*0.60 -y*len*0.09 );
	vec2 uvr = uv + vec2(-y*len*0.59 -x*len*0.12 , x*len*0.59 -y*len*0.12 );
	val *= trunk(ang, uv, len, .024, sharpness) * branch(ang-.13, uvl, len*.7, .008, sharpness) * branch(ang+.125, uvr, len*1.2, .005, sharpness);
	// left
	float ang1 = ang-.1; float len1 = len*.7; vec2 uv1 = uvl;
	x = sin(ang1*2.*3.14159);y = cos(ang1*2.*3.14159);
	vec2 uvl1 = uv1 + vec2(-y*len1*0.01+x*len*-0.022, x*len1*0.01+y*len*-0.022);
	vec2 uvr1 = uv1 + vec2(-y*len1*0.5 +x*len* 0.01 , x*len1*0.5 +y*len* 0.01);
	val *= branch(ang1-.1, uvl1, len1*.7, .003, sharpness) * branch(ang1+.13, uvr1, len1*.6, 0.005, sharpness);
	// right
	float ang2 = ang+.13; float len2 = len*.6; vec2 uv2 = uvr;
	x = sin(ang2*2.*3.14159);y = cos(ang2*2.*3.14159);
	vec2 uvl2 = uv2 + vec2(-y*len2*0.6 +x*len*-0.04, x*len2*0.6 +y*len*-0.04);
	vec2 uvr2 = uv2 + vec2(-y*len2*0.5 +x*len*+0.045, x*len2*0.5 +y*len*+0.045);
	val *= branch(ang2-.072, uvl2, len2*.8, 0.001, sharpness) * branch(ang2+.13, uvr2, len2*.6, 0.003, sharpness);
#else
	vec2 uvl = uv + vec2(-y*len*0.60 -x*len*0.11 , x*len*0.60 -y*len*0.11 );
	vec2 uvr = uv + vec2(-y*len*0.59 -x*len*0.15 , x*len*0.59 -y*len*0.15 );
	val *= trunk(ang, uv, len, .024, sharpness) * branch(ang-.13, uvl, len*.7, .008, sharpness) * branch(ang+.125, uvr, len*1.2, .005, sharpness);
	// left
	float ang1 = ang-.1; float len1 = len*.7; vec2 uv1 = uvl;
	x = sin(ang1*2.*3.14159);y = cos(ang1*2.*3.14159);
	vec2 uvl1 = uv1 + vec2(-y*len1*0.01+x*len*+0.00, x*len1*0.01+y*len*+0.00);
	vec2 uvr1 = uv1 + vec2(-y*len1*0.4 +x*len* 0.02 , x*len1*0.4 +y*len* 0.02);
	val *= branch(ang1-.1, uvl1, len1*.7, .003, sharpness) * branch(ang1+.13, uvr1, len1*.6, 0.005, sharpness);
	// right
	float ang2 = ang+.13; float len2 = len*.6; vec2 uv2 = uvr;
	x = sin(ang2*2.*3.14159);y = cos(ang2*2.*3.14159);
	vec2 uvl2 = uv2 + vec2(-y*len2*0.6 +x*len*-0.08, x*len2*0.6 +y*len*-0.08);
	vec2 uvr2 = uv2 + vec2(-y*len2*0.5 +x*len*-0.022, x*len2*0.5 +y*len*-0.022);
	val *= branch(ang2-.032, uvl2, len2*.8, 0.001, sharpness) * branch(ang2+.13, uvr2, len2*.6, 0.003, sharpness);
#endif
	return val;
}





void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	float time = iTime * 0.1;

	vec2 uv = fragCoord.xy / iResolution.y;
	uv -= vec2(.25, 0.);

	float val1 = 1.;
	float val2 = 1.;
	float val3 = 1.;
	float val4 = 1.;

	// trees
	val2 *= tree1(0.79+sin(time*5.+.0 )*0.006, uv                ,  .75, 0.024, 9.);
	val2 *= tree1(0.73+sin(time*5.+.1 )*0.006, uv+vec2(-1.15, 0.),  .99, 0.024, 9.);
	val3 *= tree2(0.73+sin(time*5.-.3 )*0.006, uv+vec2(-0.85, 0.), 1.00, 0.014, 8.);
	val3 *= tree2(0.78+sin(time*5.+.2 )*0.006, uv+vec2(0.182, 0.), 1.00, 0.014, 8.);
#if 1
	// trunks front
	val1 *= trunk(0.79+sin(time*5.+.4 )*0.008, uv+vec2(.2  , 0.), 1.2, .054, 4.);
	val1 *= trunk(0.77+sin(time*5.+.47)*0.004, uv+vec2(.27 , 0.), 1.2, .024, 8.);
	val1 *= trunk(0.72+sin(time*5.+.6 )*0.003, uv+vec2(-1.5, 0.), 2.2, .094, 3.);
	val1 *= trunk(0.72+sin(time*5.+.8 )*0.006, uv+vec2(-1.3, 0.), 2.2, .034, 10.);
	// trunks far
	val2 *= trunk(0.78+sin(time*5.-.64)*0.008, uv+vec2(.03 , 0.), 0.9, .013, 9.);
	val2 *= trunk(0.76+sin(time*5.-.27)*0.007, uv+vec2(.15 , 0.), 1.1, .030, 9.);
	val3 *= trunk(0.78+sin(time*5.-.37)*0.007, uv+vec2(-.15, 0.), 0.8, .010, 8.);
	val3 *= trunk(0.72+sin(time*5.+.37)*0.007, uv+vec2(-1.04,0.), 0.7, .013, 4.);
#endif
#if 1
	// far firs#1
    float bb = 0.;
	for (int b=0; b<7; b++)
	{
    	float rand = hash(bb*10.);
	    val3 *= fir(0.77+sin(time*5.+.37+rand)*0.007-bb*.010, uv+vec2(-.18-bb*.14-rand*.13 ,0.), 0.28+rand*.3,.011+rand*.003, 3.);	bb += 1.;
	}
	// very far firs#2
	bb = 0.;
	for (int b=0; b<7; b++)
	{
    	float rand = hash(bb*10.);
	    val3 *= fir(0.77+sin(time*5.-.37+rand*1.41)*0.004-bb*.009, uv+vec2(-.20-bb*.10-rand*.08 ,0.), 0.22+rand*.3,.007+rand*.003, 1.);	bb += 1.;
	}
#endif	
	
	vec3 col  = vec3(0., 0., 0.);
	vec3 tcol = vec3(0., 0., 0.);
	
	vec2 xy = -1.0 + 2.0*fragCoord.xy / iResolution.xy;
	vec2 s = xy*vec2(1.75,1.2);
	
	// get camera position and view direction
	vec3 campos = vec3(0.0, 0.0, 0.0);
	vec3 camtar = vec3(0.0, 0.35, 1.0);
	
	vec3 light       = normalize( vec3(  0.1, 0.55,  0.9 ) );
	
	float roll = 0.0;
	vec3 cw = normalize(camtar-campos);
	vec3 cp = vec3(sin(roll), cos(roll),0.0);
	vec3 cu = normalize(cross(cw,cp));
	vec3 cv = normalize(cross(cu,cw));
	vec3 rd = normalize( s.x*cu + s.y*cv + 1.6*cw );
	float sundot = clamp(dot(rd,light),0.0,1.0);

	if (val2<.99)
		tcol = 0.8*vec3(1.0,1.0,1.0)*pow( sundot, 300.0 );

	// render sky
    float t = pow(1.0-0.7*rd.y, 1.0);
    col += vec3(.1, .2, .4)*(1.0-t);
    // moon
    col += 0.30*min(vec3(2.0, 2.0, 2.0), vec3(2.0,2.0,2.0)*pow( sundot, 350.0 ));
    // moon haze
    col += 0.6*vec3(0.8,0.9,1.0)*pow( sundot, 6.0 );
    // stars
	vec3 stars = vec3(0.,0.,0.);
	if (t<1.0)
	{
		vec3 scol = clamp(vec3(1.2, 1.0, 0.8) * pow(noise(uv*120.), 120.) * 50. * (.5-pow(t,20.)), 0.0, 1.0);
		scol += clamp(vec3(1.2, 1.0, 0.8) * pow(noise(uv*160.), 300.) * 40. * (.5-pow(t,20.)), 0.0, 1.0);

		float st = 100.;
		float grow = .0;
		for (int i=0; i<12; i++)
		{
        	float sundot2 = clamp(dot(rd,normalize( vec3( 2.*noise(vec2(st, 0.))-1., noise(vec2(st, 1876.))+.3,  0.9 ) )),0.0,1.0);
	    	scol += 0.200*vec3(6.0,5.0,2.0)*pow( sundot2, 190000.0-grow );
			st += 11.;
			grow += 9000.;
		}
		stars = scol * (.3+.7*fbm(vec3(time*80., 10.0*uv.x+55.0*uv.y, 0.)));
	}	
	
	// Clouds
    vec2 shift = vec2( time*200.0, time*280.0 );
    vec4 sum = vec4(0,0,0,0); 
#if 1
	for (int q=1000; q<1060; q++) // 120 layers
    {
      if (sum.w>0.999) break;
      float c = (float(q-1000)*10.0+350.0-campos.y) / rd.y; // cloud height
      vec3 cpos = campos + c*rd + vec3(831.0+shift.x, 321.0+float(q-1000)*.15-shift.x*0.2, 1330.0+shift.y); // cloud position
      float alpha = smoothstep(0.5, 1.0, fbm( cpos*0.0015 ))*.9; // fractal cloud density
      vec3 localcolor = mix(vec3( 1.1, 1.05, 1.0 ), 0.7*vec3( 0.4,0.4,0.3 ), alpha); // density color white->gray
      alpha = (1.0-sum.w)*alpha; // alpha/density saturation (the more a cloud layer's density, the more the higher layers will be hidden)
      sum += vec4(localcolor*alpha, alpha); // sum up weightened color
    }
#endif
	float alpha = smoothstep(0.7, 1.0, sum.w);
    sum.rgb /= sum.w+0.0001;
    sum.rgb -= 0.6*vec3(0.8, 0.75, 0.7) * pow(sundot,10.0)*alpha;
    sum.rgb += 0.2*vec3(1.2, 1.2, 1.2) * pow(sundot,5.0)*(1.0-alpha);

	if (t<1.)
    	col = mix( col, sum.rgb , 1.0*sum.w*pow(sundot,3.0)*(1.0-pow(t,10.)) );

	
	// stars
	col += 1.0*stars*(1.-sum.w*sum.w);

	// trees #3
    col = col*val3 + (1.-t*.8)*vec3(0.3, 0.4, 0.5)*(1.0-val3);
	// trees #2
    col = col*val2 + (1.-t*.8)*vec3(0.1, 0.2, 0.3)*(1.0-val2);
	
	// moving fog
    float c = 650.0 / (rd.x-1.1);
    vec3 cpos = campos + c*rd + vec3(831.0-time*1000., 321.0, 0.0);
    col += fbm( cpos*0.0015 )*.3 - .10;

	// trees #1
	col *= val1; // trees
	// tree-moon glow
	col += 1.2*tcol*(1.-sum.w*sum.w);

	fragColor = vec4(col,1.0);
}