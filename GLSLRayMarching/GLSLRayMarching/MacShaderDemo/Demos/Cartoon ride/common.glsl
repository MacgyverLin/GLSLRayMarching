
#define FAR 400.
//#define PRECISE
//#define WITH_AO

#define ID_SKY    0.
#define ID_SHIP   1.
#define ID_GROUND 2.
#define ID_PATH   3.

#define EDGE_WIDTH 5e-3



// Frequencies and amplitudes of the "path" function, used to shape the tunnel and guide the camera.
const float freqA = .34*.15/3.75;
const float freqB = .25*.25/2.75;
const float ampA = 20.;
const float ampB = 4.;


vec3 gRO;
mat3 gbaseShip;

float gedge;
float gedge2;
float glastt;


// 2x2 matrix rotation. Angle vector, courtesy of Fabrice.
mat2 rot2( float th ){ vec2 a = sin(vec2(1.5707963, 0) + th); return mat2(a, -a.y, a.x); }

// 1x1 and 3x1 hash functions.
float hash(float n){ return fract(cos(n)*45758.5453); }
float hash(vec3 p){ return fract(sin(dot(p, vec3(7, 157, 113)))*45758.5453); }


// Smooth maximum, based on the function above.
float smaxP(float a, float b, float s){    
    float h = clamp(.5 + .5*(a - b)/s, 0., 1.);
    return mix(b, a, h) + h*(1. - h)*s;
}

float sdVerticalCapsule( vec3 p, float h, float r ) {
  p.y -= clamp( p.y, 0.0, h );
  return length( p ) - r;
}

float sdTorus( vec3 p, vec2 t ) {
  vec2 q = vec2(length(p.xz)-t.x,p.y);
  return length(q)-t.y;
}

float sdBox( vec3 p, vec3 b ) {
  vec3 q = abs(p) - b;
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}

float sdBox( in vec2 p, in vec2 b ) {
    vec2 d = abs(p)-b;
    return length(max(d,0.0)) + min(max(d.x,d.y),0.0);
}

float sdCappedCylinder( vec3 p, float h, float r ) {
  vec2 d = abs(vec2(length(p.xz),p.y)) - vec2(h,r);
  return min(max(d.x,d.y),0.0) + length(max(d,0.0));
}

void pModPolar(inout vec2 p, float repetitions) {
	float angle = 2.*3.141592/repetitions;
	float a = atan(p.y, p.x) + angle*.5;
	a = mod(a,angle) - angle*.5;
	p = vec2(cos(a), sin(a))*length(p);
}

void pR45(inout vec2 p) {
	p = (p + vec2(p.y, -p.x))*sqrt(0.5);
}

// The path is a 2D sinusoid that varies over time, depending upon the frequencies, and amplitudes.
vec2 path(in float z){ 
    return vec2(ampA*sin(z * freqA) + 2.*cos(z*.0252) - 1., 10.+ ampB*cos(z * freqB) * (.5+ .5*sin(z*0.0015)));
}

float sdGround(in vec3 p, sampler2D channel){
    p += vec3(0,2,0);
    float tx1 = 2.5*textureLod(channel, p.xz/28. + p.xy/100., 0.).x;
    float tx2 = 2.*textureLod(channel, p.xy/vec2(31.,15.), 0.).x;
  	float tx = tx1 - tx2;

    vec3 q = p*.125;
    float h = dot(sin(q)*cos(q.yzx), vec3(.222)) + dot(sin(q*1.5)*cos(q.yzx*1.5), vec3(.111));

    float d = p.y + h*6.;
    q = p*.07125;
    float h3 = dot(sin(q)*cos(q.yzx), vec3(.222)) + dot(sin(q*1.5)*cos(q.yzx*1.5), vec3(.111));
    float d3 = p.y + h3*22.-22.;
  
    q = sin(p*.5 + h);
    float h2 = q.x*q.y*q.z;
  
    vec3 p0 = p;
    p.xy -= path(p.z);
    
    float dPath = length(p.xy)-38.;
    
    vec3 p1 = p;
    float tnl = 1.5 - length(p.xy*vec2(1.2, 1.96)) + h2;// - (1. - tx)*.25;
    
    p.xz = mod(p0.xz+150.,300.)-150.; 
    
    float dCaps = mix(999., sdVerticalCapsule(p+vec3(45,60,50), 130., 15.) + tx1, step(2500., p0.z));
    
    p = p1;
    p.z = mod(p.z+250.,500.)-250.; 
    
    float dGate = sdTorus(p.yzx-vec3(25,25,5), vec2(50.,15.))+tx1;
	dCaps = mix(dCaps, dGate, step(4600., p0.z));
            
    p.xz = mod(p0.xz+450.,900.)-450.;
    float dCaps2 = sdVerticalCapsule(p+vec3(20,55,0), 100., 30.) + .5*tx;
        
    float d4 = smaxP(d - tx*.5+ tnl*.4, .2*tnl, 8.);
    d3 = mix(d3, d4, smoothstep(.5,1., .5+.5*(sin(p0.z*.001-.8))));
    
    d = min(dCaps, smaxP(d3, d4, 10.));
    float dend = max(p0.y-60., -dPath-.5*tx+.25*tx2);
    d = mix(d, dend, smoothstep(7000.,9000., p0.z)*smoothstep(12000.,9000., p0.z));
    d = smaxP(-dCaps2, d,2.);
            
    return d;
}

float sdShip(in vec3 p0) {
    p0 -= vec3(4,0,0);
    float d = length(p0) -4.;
    
    vec3 pRot = p0;
    pModPolar(pRot.zy, 16.);
    pRot.x = abs(pRot.x);
    d = min(d, length(pRot-vec3(2.6,0,3.))-.2);
	d = min(d, sdBox(pRot-vec3(4.5,0,.8), vec3(.5,.1,.2)));    
    
    vec3 p = p0;
    p.zy = abs(p.zy);
    p -= vec3(-5.6,2.5,2);
    pR45(p.yz);
    pR45(p.xy);
    return min(d, sdBox(p, vec3(1.,2,.2)));  
}

float sdPath(in vec3 p0) {
    float d2 = length(path(p0.z)-p0.xy)-.5;
    return max(d2, -gRO.z + p0.z);
}

float map(in vec3 p0, sampler2D channel) {
    float d = sdGround(p0,channel);
    float dPath = sdPath(p0-vec3(0,0,0));
    return min(dPath,d); 
}

float mapFull(in vec3 p0, sampler2D channel) {
    float d = sdGround(p0,channel);
    float dPath = sdPath(p0);
    return min(sdShip((p0-gRO)*gbaseShip),min(dPath,d)); 
}

vec2 min2(vec2 c0, vec2 c1) {
	return c0.x < c1.x ? c0 : c1;
}

vec2 mapColor(in vec3 p0, sampler2D channel) {
    float d = sdGround(p0, channel);
    float dPath = sdPath(p0);
    return min2(vec2(sdShip((p0-gRO)*gbaseShip), ID_SHIP), 
                min2(vec2(dPath, ID_PATH), vec2(d, ID_GROUND))); 
}


float logBisectTrace(in vec3 ro, in vec3 rd, sampler2D channel){
    float t = 0., told = 0., mid, dn;
    float d = map(rd*t + ro, channel);
    float sgn = sign(d);

    float lastDistEval = 1e10, lastt = 0.;
	vec3 rdShip = rd*gbaseShip;
	vec3 roShip = (ro-gRO)*gbaseShip;

    for (int i=0; i<164; i++){
        if (sign(d) != sgn || d < 0.01 || t > FAR) break;
 
        told = t;    
        t += step(d, 1.)*(log(abs(d) + 1.1) - d) + d;
        
        d = map(rd*t + ro, channel);
        d = min(d, sdShip(rdShip*t + roShip));
        
        if (d < lastDistEval) {
            lastt = t;
            lastDistEval = d;
        } else {
            if (d > lastDistEval + 0.0001 &&  lastDistEval/mix(30., lastt, smoothstep(FAR*.75, FAR*.9, t)) < EDGE_WIDTH) {
            	gedge = 1.f;
                if (glastt == 0.) glastt = lastt;
            }
            if (d > lastDistEval + 0.0001 && (lastDistEval < EDGE_WIDTH*40. || lastDistEval/lastt < EDGE_WIDTH*2.)) {
            	gedge2 = 1.f;
            }
			//edge = smoothstep(-EDGE_WIDTH,-EDGE_WIDTH*.5f,-(lastDistEval/100.));///lastt));
		}
    }
    if (glastt == 0.)  glastt = lastt;

#ifdef PRECISE
    // If a threshold was crossed without a solution, use the bisection method.
    if (sign(d) != sgn){
    
        // Based on suggestions from CeeJayDK, with some minor changes.

        dn = sign(map(rd*told + ro, channel));
        
        vec2 iv = vec2(told, t); // Near, Far

        // 6 iterations seems to be more than enough, for most cases...
        // but there's an early exit, so I've added a couple more.
        for (int ii=0; ii<8; ii++) { 
            //Evaluate midpoint
            mid = dot(iv, vec2(.5));
            float d = map(rd*mid + ro, channel);
            if (abs(d) < 0.001)break;
            iv = mix(vec2(iv.x, mid), vec2(mid, iv.y), step(0.0, d*dn));
        }

        t = mid;       
    }
#endif
    
    return min(t, FAR);
}


vec3 normal(in vec3 p, sampler2D channel) {  
    vec2 e = vec2(-1, 1)*.001;   
	return normalize(e.yxx*mapFull(p + e.yxx, channel) + e.xxy*mapFull(p + e.xxy, channel) + 
					 e.xyx*mapFull(p + e.xyx, channel) + e.yyy*mapFull(p + e.yyy, channel) );   
}


float softShadow(in vec3 ro, in vec3 rd, in float start, in float end, in float k, sampler2D channel){
    ro += rd*hash(ro);
    vec3 rdShip = rd*gbaseShip;
	vec3 roShip = (ro-gRO)*gbaseShip;
    float shade = 1.;
    const int maxIterationsShad = 24; 
    float dist = start;
    float stepDist = end/float(maxIterationsShad);
    for (int i=0; i<maxIterationsShad; i++){
        float h = min(map(ro + rd*dist, channel), sdShip(roShip + dist*rdShip));
        shade = min(shade, smoothstep(0., 1., k*h/dist));
        dist += clamp(h, .2, stepDist*2.);
        if (abs(h)<.001 || dist > end) break; 
    }
    return min(max(shade, 0.) + .1, 1.); 
}

#ifdef WITH_AO

float calculateAO( in vec3 p, in vec3 n, float maxDist, sampler2D channel )
{
	float ao = 0., l;
	const float nbIte = 6.;
    for(float i=1.; i< nbIte+.5; i++){
        l = (i + hash(i))*.5/nbIte*maxDist;
        ao += (l - mapFull( p + n*l, channel))/(1. + l);
    }
    return clamp(1. - ao/nbIte, 0., 1.);
}
#endif

// Pretty standard way to make a sky. 
vec3 getSky(in vec3 ro, in vec3 rd, vec3 sunDir){
	return vec3(smoothstep(.97,1.,max(dot(rd, sunDir), 0.)));
}

// Curve function, by Shadertoy user, Nimitz.
// Original usage (I think?) - Cheap curvature: https://www.shadertoy.com/view/Xts3WM
float curve(in vec3 p, sampler2D channel){
    const float eps = .05, amp = 4., ampInit = .5;
	vec2 e = vec2(-1, 1)*eps; // 0.05->3.5 - 0.04->5.5 - 0.03->10.->0.1->1.
    float t1 = mapFull(p + e.yxx, channel), t2 = mapFull(p + e.xxy, channel);
    float t3 = mapFull(p + e.xyx, channel), t4 = mapFull(p + e.yyy, channel);
    return clamp((t1 + t2 + t3 + t4 - 4.*mapFull(p, channel))*amp + ampInit, 0., 1.);
}


vec4 render(in vec2 fragCoord, float Time, vec2 Resolution, sampler2D channel){
        
    gedge = 0.;
    gedge2= 0.;
    glastt = 0.;
	
	// Screen coordinates.
	vec2 u = (fragCoord - Resolution.xy*.5)/Resolution.y;
    float dBox = sdBox(u, vec2(.5*Resolution.x/Resolution.y-.1,.4));
    
    vec3 col = vec3(.2);
   	float needAA = 0.; 
    float ed = 0., ed2 = 0., lastt1 = 0.;
    
    if (dBox <0.){	

        // Camera Setup.
        vec3 lookAt = vec3(0, 0, Time*100.);  // "Look At" position.
        vec3 ro = lookAt + vec3(0, 0, -.25); // Camera position, doubling as the ray origin.

        lookAt.xy += path(lookAt.z);
        ro.xy += path(ro.z);
        lookAt.y -= .071;

        // Using the above to produce the unit ray-direction vector.
        float FOV = 3.14159/2.; // FOV - Field of view.

        vec3 forward = normalize(lookAt - ro);
        vec3 right = normalize(vec3(forward.z, 0, -forward.x )); 

        right.xy *= rot2( path(lookAt.z).x/64.);
        right.xy *= rot2( -.7*cos(Time*.12));


        vec3 up = cross(forward, right);

        vec3 rd = normalize(forward + FOV*u.x*right + FOV*u.y*up);
        vec3 lp = vec3(.5*FAR, FAR, 1.5*FAR) + vec3(0, 0, ro.z);


        gRO = ro+vec3(0,0,1);
        gRO.xy = path(gRO.z);
        vec3 p2 = vec3(path(gRO.z+1.), gRO.z+1.);

        forward = normalize(p2 - gRO);
        right = normalize(vec3(forward.z, 0, -forward.x )); 
        right.xy *= rot2( path(lookAt.z).x/32.);
        up = cross(forward, right);
        gbaseShip = mat3(forward, up, right);

        float dist = mix(35., 15., smoothstep(7000.,8500., gRO.z));
        dist = mix(dist, 45., smoothstep(10000.,12000., gRO.z));
        ro += (dist*(.5+.5*cos(.31*Time))+2.)*vec3(.3,1,-2.);
        ro.x += .3*dist*cos(.31*Time);

        float t = logBisectTrace(ro, rd, channel);
        ed = gedge; ed2 = gedge2;  lastt1 = glastt;


        vec3 sky = getSky(ro, rd, normalize(lp - ro));

        col = sky;

        vec2 mapCol = mapColor(ro+t*rd, channel);

        vec3 sp;
		float cur;
        if (t < FAR){

            sp = ro+t*rd; // Surface point.
            vec3 sn = normal(sp, channel); // Surface normal.
            vec3 ld = lp-sp;
            ld /= max(length(ld), 0.001); // Normalize the light direct vector.

            float shd = softShadow(sp, ld, .1, FAR, 8., channel); // Shadows.
            cur = curve(sp, channel);
            float curv = cur*.9 +.1; // Surface curvature.
#ifdef WITH_AO
            float ao = calculateAO(sp, sn, 4., channel); // Ambient occlusion.
#else
            float ao = 1.;//calculateAO(sp, sn, 4., channel); // Ambient occlusion.
#endif
            float dif = max( dot( ld, sn ), 0.); // Diffuse term.
            float spe = pow(max( dot( reflect(-ld, sn), -rd ), 0. ), 5.); // Specular term.
            float fre = clamp(1.0 + dot(rd, sn), 0., 1.); // Fresnel reflection term.
            float Schlick = pow( 1. - max(dot(rd, normalize(rd + ld)), 0.), 5.);
            float fre2 = mix(.2, 1., Schlick);  //F0 = .2 - Hard clay... or close enough.
            float amb = fre*fre2 + .06*ao;        

            col = clamp(mix(vec3(.8, .5, .3), vec3(.5, .25, .125),(sp.y+1.)*.15), vec3(.5, .25, .125), vec3(1));
            col = pow(col, vec3(1.5));
            col = (col*(dif + .1) + fre2*spe)*shd*ao + amb*col;      
        }

        col = pow(max(col, 0.), vec3(.75));

        u = fragCoord/Resolution.xy;

        vec3 cGround = vec3(248,210,155)/256.;
        vec3 cSky = vec3(177,186,213)/256.;

        if (t < FAR){
            
            vec3 cFill;
            if (mapCol.y == ID_PATH) {
                cFill = vec3(1,.01,0.01);//mix(vec3(248,210,155)/256., vec3(248,185,155)/256., smoothstep(12.0,12.1,(sp.y)));
            }
            else if (mapCol.y == ID_SHIP) {
               	vec3 pShip = (sp-gRO)*gbaseShip;
                cFill = mix(vec3(0,1,1),vec3(.7),smoothstep(.0,.1, pShip.x-1.3));
            } else {
                cFill = mix(vec3(248,210,155)/256., vec3(248,185,155)/256., smoothstep(.0,.1,sp.y-8.));
                cFill = mix(cFill, vec3(1,0,0), .4*smoothstep(1000.,3000., gRO.z));
            	vec3 col3 = cos(sp.y*.08+1.1)*clamp(mix(vec3(.8, .5, .3), vec3(.5, .25, .125),(sp.y+1.)*.15), vec3(.5, .25, .125), vec3(1));

                cFill = mix(cFill, col3, .5*smoothstep(6000.,8500., gRO.z));
            }

            col = mix(cFill,cSky,t/FAR)*(.5+.5*smoothstep(.4,.5,length(col)));
            col = mix(col, vec3(.0), ed);
            col = mix(vec3(0), col, .5+.5*smoothstep(.4,.41,cur)); // Surface curvature.;
            ed2 += cur<.35?1.:0.;

        } else {
            col = mix(cSky*abs(1.-rd.y),vec3(1),smoothstep(1.3,1.4,length(col)));
            col = mix(col, vec3(.1), ed);
        	float sun = max(dot(rd, normalize(lp - ro)), 0.); // Sun strength.
			col = mix(vec3(0), col, smoothstep(.09/Resolution.y,.2/Resolution.y, abs(sun-.9892)));//.zyx;	
        }

        col = mix(col, cSky*abs(1.-rd.y), sqrt(smoothstep(FAR - (ed <0. ? 200. : 100.), FAR, lastt1)));
        
    }  
    
    // BD frame
    col = mix(col, vec3(.2),smoothstep(.0,1./Resolution.y,dBox));
    col = mix(col, vec3(0.),smoothstep(1./Resolution.y,.0,abs(dBox)-.005));

    return vec4(clamp(col, 0., 1.), ed2);
}

