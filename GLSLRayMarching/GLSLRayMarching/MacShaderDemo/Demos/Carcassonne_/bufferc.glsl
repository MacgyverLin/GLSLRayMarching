// Created by sebastien durand - 01/2019
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
// *****************************************************************************

// [Dave_Hoskins] Rolling hills - https://www.shadertoy.com/view/Xsf3zX
// [Shane] Voxel Corridor - https://www.shadertoy.com/view/MdVSDh
// [HLorenzi] Hand-drawn Sketch  - https://www.shadertoy.com/view/MsSGD1
// [Mercury] Lib - http://mercury.sexy/hg_sdf for updates
// [dr2] White Folly - https://www.shadertoy.com/view/ll2cDG


// Calculate textures and lights


//--------------------------------------------------------------------------
// Simply Perlin clouds that fade to the horizon...
// 200 units above the ground...
vec3 GetSky(in vec3 ro, in vec3 rd, sampler2D channel) {
    ro = vec3(0,1,0);
    vec3 col = 2.5*vec3(0.18,0.33,0.45) - rd.y*1.5;
	col *= 0.9;
    float sun = clamp( dot(rd,sunLight), 0.0, 1.0 );
	col += vec3(1., .6, .2)*.8*pow( sun, 32.0 );
 /*   
    vec2 cuv = ro.xz + rd.xz*(100.-ro.y)/rd.y;
    float cc = texture( channel, 0.0003*cuv +0.1+ 0.0023*time ).x;
    cc = 0.65*cc + 0.35*texture( channel, 0.0003*2.0*cuv + 0.0023*.5*time ).x;
    cc = smoothstep( 0.3, 1.0, cc );
    
    return clamp(mix( col, vec3(1.0,1.0,1.0)*(0.95+0.20*(1.0-cc)*sun), 0.7*cc ), vec3(0), vec3(1));
*/
    return clamp(col, vec3(0), vec3(1));
}


// Grey scale.
float getGrey(vec3 p){ return dot(p, vec3(.299, .587, .114)); }

// Tri-Planar blending function. Based on an old Nvidia writeup:
// GPU Gems 3 - Ryan Geiss: http://http.developer.nvidia.com/GPUGems3/gpugems3_ch01.html
vec3 tex3D( sampler2D tex, in vec3 p, in vec3 n ){  
    n = max(n*n, 0.001);
    n /= (n.x + n.y + n.z );  
	return (texture(tex, p.yz)*n.x + texture(tex, p.zx)*n.y + texture(tex, p.xy)*n.z).xyz;
}

// The brick groove pattern. Thrown together too quickly.
// Needs some tidy up, but it's quick enough for now.
//
const float w2h = 2.; // Width to height ratio.
const float mortW = 0.05; // Morter width.


float brick(vec2 p){
	p = fract(p*vec2(0.5/w2h, 0.5))*2.;
    p.x -= step(1., p.y)*.5;
    p = abs(fract(p + vec2(0, .5)) - .5)*2.;
    // Smooth grooves. Better for bump mapping.
    return smoothstep(0., mortW, p.x)*smoothstep(0., mortW*w2h, p.y);
    
}


// Surface bump function. Cheap, but with decent visual impact.
float bumpSurf3D( in vec3 p, in vec3 n){
 //   n = abs(n);
    return brick(n.x > .5 ? p.zy : n.y > .5 ? p.zx : p.xy);
}

// Standard function-based bump mapping function.
vec3 doBumpMapBrick(in vec3 p, in vec3 nor, float bumpfactor){
	vec3 n = abs(nor);
    const vec2 e = vec2(0.001, 0);
    float ref = bumpSurf3D(p, nor);                 
    vec3 grad = (vec3(bumpSurf3D(p - e.xyy, n), bumpSurf3D(p - e.yxy, n), bumpSurf3D(p - e.yyx, n) )-ref)/e.x;                     
    grad -= nor*dot(nor, grad);                            
    return normalize( nor + grad*bumpfactor );
	
}

// Texture bump mapping. Four tri-planar lookups, or 12 texture lookups in total. I tried to 
// make it as concise as possible. Whether that translates to speed, or not, I couldn't say.
vec3 doBumpMap( sampler2D tx, in vec3 p, in vec3 n, float bf){   
    const vec2 e = vec2(0.001, 0);
    // Three gradient vectors rolled into a matrix, constructed with offset greyscale texture values.    
    mat3 m = mat3( tex3D(tx, p - e.xyy, n), tex3D(tx, p - e.yxy, n), tex3D(tx, p - e.yyx, n));
    vec3 g = vec3(0.299, 0.587, 0.114)*m; // Converting to greyscale.
    g = (g - dot(tex3D(tx,  p , n), vec3(0.299, 0.587, 0.114)) )/e.x; 
    g -= n*dot(n, g);
    return normalize( n + g*bf ); // Bumped normal. "bf" - bump factor.
}

//---------------------------------------------


#define ID_GROUND 1
#define ID_SMALL_TOUR 2
#define ID_CASTLE 3
#define ID_STONE 4
#define ID_TREE_1 5
#define ID_TREE_2 6
#define ID_HOUSE_WALL 7
#define ID_HOUSE_ROOF 8
#define ID_GROUND_CASTLE 9
#define ID_PUIT 10

vec3 getTexture(vec3 p0, vec3 rd, inout vec3 n, inout vec2 spe, float t,
                sampler2D channel1, sampler2D channel2, sampler2D channel3){ 
    float h = Terrain(p0.xz*.3);
    float elev = p0.y - .002*h;
    
    spe = vec2(0.,1000.);
    
	vec3 p = p0;
   	malaxSpace(p);

    p.x = abs(p.x);
  
    // Texture scale factor.        
    const float tSize1 = 1.; //.5;//1./6.;
	
    // puit
    vec3 pp = p;
    pp.x = abs(pp.x) +.1;// gothique  
  //  pMirror(pp.x, -.1);  
    float rp = length(pp.xz-vec2(3.,3.1));
    
    // arbre
    p.z += .05;
   
    vec3 ph = p;
   
    //vec3 p2 = p, ph = p;

    // Chemin de ronde
    ph.z -= .5;
	pR45(ph.zx);
    ph.z -= 4.6;
    ph.x += 1.;
    pReflect(ph, normalize(vec3(-1.,0,.7)),1.);
    
    vec3 pm = ph;
    pMirrorOctant(pm.xz, vec2(1.5,1.6));

    float ra = length(ph.xz);
    
    int id = rp < .202 ? ID_PUIT :
        //rp<3.1 ? ID_HOUSE_WALL :
        elev<.002 || length(p.xz)>10. ? (abs(p.z+1.9) < 1.9 && abs(p.x) < 2.3 ? ID_GROUND_CASTLE : ID_GROUND) :// sol
        p.y>2.7 ? ID_SMALL_TOUR : // toit tour conique 
        abs(p.z+2.) < 1.55 && abs(p.x) < 2. ? ID_CASTLE :  // chateau
        (length(p.xz-vec2(0,2.)) > 5.83 || (rp>3. && p.z<0.6)) ? ID_STONE :  // rempart 
        //abs(p.x) > 1.8 ? p.y < 2.5 ? vec3(.4,.4,.1) : vec3(.5,.9,.7) : //arbres
        ra < .5 ? (ra < .051 && p.y<.7 ? ID_TREE_1 : ID_TREE_2) :
        p.y < .325 ? ID_HOUSE_WALL : // mur maisonettes   
        ID_HOUSE_ROOF;  // toit maisonettes

    
    vec3 c = vec3(1);
    
    switch(id) {
        case ID_TREE_1 : 
        	n = doBumpMap(channel1, p0.xyz*vec3(1.,.1,1.)*tSize1, n, .07/(1. + t/MAX_DIST));
        	c = vec3(.4,.3,.2); break;
        case ID_TREE_2 :
        	n = doBumpMap(channel1, p0*4.*tSize1, n, .07/(1. + t/MAX_DIST)); 
        	c = vec3(.2,.5,.4); break;
        case ID_PUIT : 
        	n = doBumpMap(channel2, p0*1.95*tSize1, n, .007/(1. + t/MAX_DIST)); 
        	n = doBumpMapBrick(p*30., n, .015); c = .5*vec3(1.,.9,.7); break;
        case ID_GROUND :
        
        
            n = doBumpMap(channel1, p0*tSize1, n, .007/(1. + t/MAX_DIST));//max(1.-length(fwidth(sn)), .001)*hash(sp)/(1.+t/FAR)
			c = NoiseT(1000.*p0.xz)*mix(vec3(.7,.7,.6), vec3(.3,.5,.4), smoothstep(.0,.05, abs(abs(p.x*1.2+.05)-.1)));
       	// test
        	break;
        
        case ID_GROUND_CASTLE :  
        	n = doBumpMapBrick(p0*5., n, .005); 
        	c = vec3(.8,.8,.7); break;
        case ID_SMALL_TOUR : 
        	c = vec3(1.,.7,1); break;
        case ID_CASTLE : 
        	n = doBumpMap(channel3, p0*4.*tSize1, n, .007/(1. + t/MAX_DIST));
        	
        //	c = vec3(.95,.9,.85), smoothstep(0.,.1, sin(10.*p.y))); 
        	c = mix(vec3(1.), vec3(.95,.9,.85), smoothstep(0.,.1, sin(15.*p.y))); 
        	break;
        case ID_STONE : 
        	spe = vec2(.5,99.); 
        	n = doBumpMapBrick(p*8., n, .03);
        	n = doBumpMap(channel1, p0*1.5*tSize1, n, .01/(1. + t/MAX_DIST));
        	c = .5*vec3(1.,.85,.7); break;
        case ID_HOUSE_WALL :
        	//if (length(pm.xz)-.2
        	//n = doBumpMapBrick(p*15., n, .03); 
        	//c = vec3(1.,.9,.7);
            if (abs(pm.x-.0335) <.06 && abs(pm.z+.8) <.2 && pm.y<.285) {
                // porte
                n = doBumpMapBrick(vec3(.3, pm.x+.13, pm.z)*32., n, .03); 
                n = doBumpMap(channel1, 3.*pm.yxz*tSize1, n, .02/(1. + t/MAX_DIST));
                c = .6*vec3(0.,.6,1); 
            } else {	
	        	n = doBumpMap(channel2, p0*1.95*tSize1, n, .007/(1. + t/MAX_DIST)); 
                c = vec3(1.,.95,.9);
            }
                c = c * mix(.4*vec3(.2,.6,.7), vec3(1), 
                      1.-.5*smoothstep(.3,.05, p0.y)*smoothstep(.3, .6,texture(channel2, p0.xy*4.*tSize1).x));
            break;
        case ID_HOUSE_ROOF :
        	spe = vec2(1.,9.); 
        	//n = doBumpMapBrick((p-vec3(0.,.01,0.))*30., n, .03); 
        	n = doBumpMap(channel3, p0*tSize1, n, .025/(1. + t/MAX_DIST));
        	c = vec3(.55,.32,.2) * mix(vec3(1), .7*vec3(.2,.6,.7), 
                  .5*smoothstep(.2,.9,texture(channel2, p0.xy*4.*tSize1).x));
                   //  tex3D(channel2, p0*4.*tSize1, n).x));
        	break;        	
    }
    
    	// prevent normals pointing away from camera (caused by precision errors)
	n = normalize(n - max(.0, dot (n,rd))*rd);
    
    return c;
}


vec3 render(in vec3 ro, in vec3 rd, in float res, in vec3 pos, in vec3 nor, in vec2 spe, in vec3 c0, float sh, float ao,
           sampler2D channel0, sampler2D channel1, sampler2D channel2, sampler2D channel3) {
	
		vec3 col;	
        float 
          amb = clamp(.5+.5*nor.y, .0, 1.),
          dif = clamp(dot( nor, sunLight ), 0., 1.);
		dif *= sh; 

		vec3 brdf =
			ao*.5*(amb)+// + bac*.15) +
			1.*dif*vec3(1.,.9,.7);
	
		float
			pp = clamp(dot(reflect(-sunLight,nor), -rd),0.,1.),
			fre = (.7+.3*dif)* ao*pow( clamp(1.+dot(nor,rd),0.,1.), 2.);
		vec3 sp = spe.x*sh*pow(pp,spe.y)*vec3(1., .6, .2);
	
		col = c0*(brdf + sp) + fre*(.5*c0+.5);
	return col;
}


float triangle(float x)
{
	return abs(1.0 - mod(abs(x), 2.0)) * 2.0 - 1.0;
}


const vec3 COL_PAPER = .9*vec3(.8,0.7,0.6);


float rand(float x)
{
    return fract(sin(x) * 43758.5453);
}



void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
    
    iRes = iResolution.xy;
	fCoord = fragCoord;
	time = iTime+100.*iMouse.x/iResolution.x;
	
    vec3 ro,rd;
    getCam(fragCoord.xy, iResolution.xy, time, ro, rd);

    vec2 uv = gl_FragCoord.xy / iResolution.xy;
    vec4 res = texture(iChannel0,uv);
	vec3 c0;
    
	bool drawing = isDrawing(); 
    
    if( res.x < MAX_DIST ) {  
        vec3
        	pos = ro + res.x * rd,
        	nor = calcNormal(pos, rd, res.x);
        vec2 spe = vec2(1.,9.);
        c0 = drawing ? vec3(1.) : getTexture(pos, rd, nor, spe, res.x, iChannel1, iChannel2, iChannel3); 
        c0 = render(ro, rd, res.x, pos, nor, spe, c0, res.z, res.y, iChannel0, iChannel1, iChannel2, iChannel3);		
 
    } else {        	
         c0 = GetSky(ro, rd, iChannel0);
    }
   

    if (drawing) {
        
        float grey = getGrey(c0.rgb);
        grey = pow(grey,2.);

        float t = floor(iTime * 16.0) / 16.0;
        
        vec2 p = -1.+2.*uv;
        p.x *= -iResolution.x/iResolution.y;

        p += vec2(triangle(p.y * rand(time) * 4.0) * rand(time * 1.9) * 0.015,
                triangle(p.x * rand(time * 3.4) * 4.0) * rand(time * 2.1) * 0.015);
        p += vec2(rand(p.x * 3.1 + p.y * 8.7) * 0.01,
                  rand(p.x * 1.1 + p.y * 6.7) * 0.01);

//        float contour = texture(iChannel0, uv+.002*vec2(rand(time + p.x),rand(time + p.y)),.8).w;  // mipmap eable kind of free antialiasing
        float contour = texture(iChannel0, uv,.8).w;  // mipmap eable kind of free antialiasing

        float frq = 30.;
        float space = (rand(t * 6.6) * 0.1 + 0.9);
        float xs = 1.1*space;
        float ys = 1.1*space;
        float 	ht = 170.0 + rand(t) * frq,
              	ht1 = 110.0 + rand(t * 1.91) * frq,
             	ht3 = -110.0 + rand(t * 4.74) * frq,
            	ht4 = 170.0 + rand(t * 3.91) * frq;
        float hatchingB = max(
            clamp((sin(p.x * xs * ht  + p.y * ys * ht1) * 0.5 + 0.5) - grey, 0.0, 1.0),
            clamp((sin(p.x * xs * ht3 + p.y * ys * ht4) * 0.5 + 0.5) - grey - 0.4, 0.0, 1.0));
       
        p.y = 1.-p.y;
        grey *=.5;

    //    xs = 1.1*space;
    //    ys = 1.1*space;

        float hatchingW = max(            
            clamp((sin(p.x * xs * ht  + p.y * ys * ht1) * 0.5 + 0.5) - (1.-grey), 0.0, 1.0),
            clamp((sin(p.x * xs * ht3 + p.y * ys * ht4) * 0.5 + 0.5) - (1.-grey) - 0.4, 0.0, 1.0));

        c0 = COL_PAPER;  
      	c0 = mix(c0, .25*vec3(1.,.4,.1), smoothstep(.3,1.,hatchingB));  // Sanguine  
      	c0 = mix(c0, vec3(.85,.9,1.1), smoothstep(.6,1.,hatchingW));    // Pastel
//        c0 = mix(c0, .25*vec3(1.,.4,.1), smoothstep(.3,1.,contour)); // Contours Sanguine
        c0 = mix(c0, .125*vec3(1.,.4,.1), contour*contour); // Contours Sanguine
        
        ro = vec3(2.,5,2.);
    	rd = RD(ro, vec3(.01*iTime,0,.01*iTime), fragCoord.xy, iResolution.xy);
        
        res.x = -ro.y/rd.y;

        sunLight = normalize(vec3(-15.,25,10));
        
        vec3 pos = ro + res.x * rd;
        vec3 nor = doBumpMap(iChannel1, pos*.2, vec3(0,-1.,0), .05/(1. + res.x/MAX_DIST));
        vec3 c = render(ro, rd, res.x, pos, nor, vec2(1.,9.), c0, 1., 1., iChannel0, iChannel1, iChannel2, iChannel3);	
        
        c0 *= c; 
        
    } else {
        // Distance Fog (2 steps)
       	c0 = mix(c0, 2.*vec3(0.28,0.33,0.45), smoothstep(20., 1.5*MAX_DIST, res.x));
        c0 = mix(c0, 2.*vec3(0.28,0.33,0.45), .5*smoothstep(0., 20., res.x));
    }
    
    c0 = pow(c0,vec3(.7));
    fragColor = vec4(clamp(c0,0.0,1.0), res.x>0. ? res.x : 1000.);

}

