#define N 23    	// number of sources

int MODE = 5;		// source distrib
float POW = 1.;		// fading with distance


const float k = 2.*3.14159/.04,  // 2 Pi / wavelenght
	        c = 0.1;			 // wavespeed

#define t iTime

bool keyToggle(int ascii) {
	return false;//(texture(iChannel2,vec2((.5+float(ascii))/256.,0.75)).x > 0.)
}

float rnd(float i) {
	return mod(4000.*sin(23464.345*i+45.345),1.);
}
float srnd(float i) { return 2.*rnd(i)-1.; }

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	vec2 R = iResolution.xy,
        uv = (2.*fragCoord - R ) / R.y;

	// --- controls

	vec2 mouse = (2.*iMouse.xy - R ) / R.y;
	if (iMouse.z<=0.) 
			mouse = vec2(1.5*cos(.2345*t)-.7*sin(t),sin(.3214*t)+.5*cos(1.234*t))/1.5;

	bool DISPLAY = keyToggle(64+23);  					// waves vs energy
	bool RND = keyToggle(64+18);						// even vs random source distrib
	MODE = ( (keyToggle(32)||keyToggle(64+19)) ? 1 : 3 ) + ( (RND) ?0:1); 	// line or circle source
	POW = (keyToggle(64+16)) ? 0. : 1.; 				// 1/r decrease or not
		
	// --- calc sources contribs
	
	float x = -.75, y=-.7, 
		  xt = x  +((keyToggle(64+20))?.03*t:0.);
	const float stp = 1.54/float(N);
	
	float Phi[N],D2[N];
	for (int i=0; i<N; i++) {
		vec2 P;	// generates sources distribution
		if 		(MODE==1) { P = vec2(x,-.9); x+= stp;}
		else if (MODE==2) { P = vec2(x,-.9); x+= stp*(1.+srnd(float(i))); }
		else if (MODE==3) { P = .99*vec2(sin(4.*xt),-cos(4.*xt)); xt+= stp;}
		else if (MODE==4) { P = .99*vec2(sin(4.*xt),-cos(4.*xt)); xt+= stp*(1.+.7*srnd(float(i)));}
		else if (MODE==5) { P = vec2(2.*x,y); x+= 1.4*sqrt(stp); 
						    if (x>.7) { x=-.7; y+=sqrt(1.4*stp);} }
		// the key: wave's phase pixel to source calibrated by wave phase mouse to source
		float dm = length(mouse-P),	phim = dm, //   -c*t,
			  d  = length(uv-P),	phi  = d -c*t;
		Phi[i] = k*(phi-phim);  // stores wave attributes
		D2[i] = pow(d,POW);

		if (d<0.01) { fragColor = vec4(0,0,1,0); return; }
	}
	
	// --- combines waves or energy
	
	float v = 0.;
	if (DISPLAY)   				// waves 		
		for (int i=0; i<N; i++)
			v += cos(Phi[i])/D2[i];

		else {						// energy . is int_t{ ( sum_i{waves(i,x,t)} )^2 }
#if 1
			for (int i=0; i<N; i++) {
				for (int j=0; j<N; j++) 
					v += cos(Phi[j]-Phi[i]) / (D2[i]*D2[j]);			
				//	if (j<i) v += 2.*cos(Phi[j]-Phi[i]) / (D2[i]*D2[j]); // not faster !
				//v += 1./ (D2[i]*D2[i]);
			}
#else
		for (int i=0; i<N; i++)
			v += 1./ (D2[i]*D2[i]);
		int i=0, j=N-1;
		for (int k=0; k<N*(N-1)/2; k++) {
			if (i>=j) { i=0; j--; }
			v += 2.*cos(Phi[j]-Phi[i]) / (D2[i]*D2[j]);
		}		
#endif			
		v = sqrt(v/2.);
	}
	v = v*4.5/float(N);
	fragColor = v* vec4(1,.5,.25, 1);
}