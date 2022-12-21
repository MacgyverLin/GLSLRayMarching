//               = Fractal Cabin In The Woods =         
//               by Maximilian Knape  ¡¤¡Æ>| 2022            
// -----------------------------------------------------------
// This work is licensed under a Creative Commons Attribution-
//        NonCommercial-ShareAlike 3.0 Unported License

#define GAMMA vec3(.4545)

#define MAX_STEPS 180
#define STEP_FAC 0.8
#define MAX_DIST 1000.
#define MIN_DIST 1.

#define SURF_DIST .005
#define SURF_MUL 2000.
#define SURF_EXP 1.4

#define PP_GLOW 0.6
#define PP_ACES 0.5
#define PP_CONT 0.4
#define PP_VIGN 2.0
#define AO_OCC 0.3
#define AO_SCA 0.4

#define AA_ENAB false //compile time warning
#define AA_THRE .03   //fps warning

#define CAM_MOVEMENT true //set false to stop animation

#define iTime iTime*1.
#define PI 3.14159265358979
#define S(x,y,t) smoothstep(x,y,t)
#define cAngle vec2(cos(PI/12.), sin(PI/12.))

vec2 Map(in vec3 p) 
{   
    //puh, that escalated quickly..
    //wanted a simple small room - steady image
    //therefore needed a house and a world around
    //ended up here, a bit messy but I like it. <3
    
    float d = 10e10, col;
    float dis = length(p.xz);
    
    //ground
    float terrain = max(0., p.y + 3.*dot(sin(p/13.-2.3), cos(p/21.-15.5)) + 
                    pow((p.x+100.)/100., 3.) + pow(p.z/50., 2.) - 3.);
    col = 3.1 + step(100.,dis)*5.1;
    d = terrain*.8;
    
    //grass
    if (dis < 100.) 
    {   //it works, but nothing more
        float grass = max(0.,terrain - .1 - .6*noise(p.xz/8.1-14.3) + 
                      .13*noise(p.xz*11.11+32.) * S(100., 0., dis));
        grass = mix(grass, terrain, pow(S(30.+grass*50.,3., dis), 2.));
        if (p.x > 0.) grass = mix(grass, terrain - .1*(noise(p.zx * vec2(10.,2.))-.5), 
            S(3., 1.5, abs(p.z -5.*pow(sin((p.x-10.)/30.), 3.)) + .1*cos(p.z*5.)));
        col = mix(col, 8.05 + grass*.3, step(grass, d));
        d = min(d, grass * S(-100., 100., dis));
    }
    
    //forest
    if (dis > 50.) 
    {   //bob style
        float tree = MAX_DIST; 
        const float gridSize = 30.;
        vec3 pos = mod(p.xyz, vec3(gridSize)) - vec3(gridSize/2.);
        pos.xz += (vec2(noise(round(p.xz/gridSize-.5)))*2.-1.) * gridSize/2.4;
        float wind = S(.5, 1., noise(p.xz/100. + vec2(iTime/12.) + p.y/300.)) * (p.y-terrain)/10. * (1.-dis/MAX_DIST);
        pos.y = terrain -5.;
        float needles = fract(-p.y/4. + .5*noise(pos.xz*5.1) + atan(10.*(pos.x/pos.z+p.z))) * 10.;
        tree = max(dot(cAngle, vec2(length(pos.xz + wind), pos.y - needles - S(30., 300., dis)*60.+10.)), -pos.y-needles+1.);
        col = mix(col, 7.3, step(tree, d));
        d = min(d, tree * (S(50., MAX_DIST, dis)+.4));
    } 
    
    //house
    if (dis < 30.) 
    {   //earthship, seams liveable in some kind 
        float house;
        float frame = sdKMC(p - vec3(0,0,0), 10, vec3(0,4,0), vec3(0.001), vec4(4,3,10.+ step(-p.y, -10.)*(p.x+15.)/15.,10)).x;
        col = mix(col, 1.7, step(frame, d));
        house = min(d, frame);

        float screed = length(max(vec3(0.), abs(vec3(0,-4.7,0) + p) - vec3(9.5,.1,9.5))) - .1;
        col = mix(col, 6.1, step(screed, house));
        house = min(house, max(screed, -(length(p - vec3(0,5,0)) - 4.4)));

        vec3 rot = p;
        rot.xy *= Rot(-.07);
        float roof = length(max(vec3(0.), abs(rot/vec3(1, 1.+ cos(rot.z*20.)*.004,1) - vec3(2,11,0)) - vec3(12,.03,12))) - .03;
        col = mix(col, 5.9, step(roof, house));
        house = min(house, max(roof, -(length(p - vec3(0,10,0)) - 3.5)));

        float lSph = length(rot / vec3(1.2,.3,1.2) - vec3(0.6,36,0)) - 3.;
        col = mix(col, -0.2, step(lSph, house));
        house = min(house, lSph*.6);

        float concrete = sdKMC(p/1.05 - vec3(0,-5,0), 8, vec3(-5), vec3(0.), vec4(4,3,12,13)).x;
        col = mix(col, 2.2, step(concrete, house));
        house = min(house, concrete);

        if (step(-5., -p.y) * step(-1., p.y) * step(-10., -length(p.xz)) > 0.)
        {
            rot = p; //messy stairs
            rot.xz *= Rot(0.65 * floor((p.y)*5.)/5.);
            rot = max(abs(rot - vec3(0,-3,4)) - vec3(.2+.4*step(4.8,p.y), .2, 2.-1.5*S(3., 5., p.y)), 0.);
            float stairs = length(mod(rot, vec3(0,.2,0)))-.01;
            col = mix(col, 9.2, step(stairs, house));
            house = min(house, stairs*.8); 
            
            float sphere = length(p - vec3(0,.3,0)) - 1.;
            col = mix(col, 4.6, step(sphere, house));
            house = min(house, sphere);
        }
        
        d = mix(smin(terrain, house, 1.3), d, S(20., 30., dis));
    }

    return vec2(d, col);
}

vec3 Normal(in vec3 p) 
{
    const vec2 e = vec2(.005, 0);
    return normalize(Map(p).x - vec3(Map(p-e.xyy).x, Map(p-e.yxy).x,Map(p-e.yyx).x));
}

vec3 RayMarch(in vec3 ro, in vec3 rd) 
{
    float col = 0.;
	float dO = MIN_DIST;
    int steps = 0;
    
    for(int i = 0; i < MAX_STEPS; i++) 
    {
        steps = i;
        
    	vec3 p = ro + rd*dO;
        vec2 dS = Map(p);
        col = dS.y;
        dO += dS.x * mix(STEP_FAC, 1., dO/MAX_DIST);
        
        if (dO > MAX_DIST || dS.x < (SURF_DIST * (pow(dO/MAX_DIST, SURF_EXP)*SURF_MUL+1.))) break;
    }
    
    return vec3(dO, steps, col);
}

float SoftShadow(in vec3 ro, in vec3 lp, in float k) //Shane
{
    if (length(ro) > 200.) return 1.;

    const int maxIterationsShad = 24; 
    
    vec3 rd = lp - ro;

    float shade = 1.;
    float dist = .002;    
    float end = max(length(rd), .001);
    float stepDist = end/float(maxIterationsShad);
    
    rd /= end;

    for (int i = 0; i<maxIterationsShad; i++)
    {

        float h = Map(ro + rd*dist).x;
        shade = min(shade, smoothstep(0., 1., k*h/dist));
        dist += clamp(h, .02, .25);
        
        if (h < .0 || dist > end) break;
    }

    return min(max(shade, 0.) + .1, 1.); 
}


float CalcAO(in vec3 p, in vec3 n) //iq
{
    float occ = AO_OCC;
    float sca = AO_SCA;

    for( int i = 0; i < 5 ; i++ )
    {
        float h = 0.001 + 0.150 * float(i) / 4.0;
        float d = Map(p + h * n).x;
        occ += (h - d) * sca;
        sca *= 0.95;
    }
    return S(0.0, 1.0 , 1.0 - 1.5 * occ);    
}


const vec3 ambCol = vec3(.01,.02,.03) * 4.0;
const vec3 sunCol = vec3(1., .9, .8) * 1.2;
const vec3 skyCol = vec3(.3, .6, 1.) * 1.0;
const float specExp = 12.;

vec3 Shade( in vec3 col, 
            in float mat, 
            in vec3 p, 
            in vec3 n, 
            in vec3 rd, 
            in vec3 lP) 
{
    vec3  lidi = normalize(lP - p);
    float mafa = max(mat, .0),
          amoc = CalcAO(p, n),
          shad = SoftShadow(p + n*.015, lP, 2.),
          diff = max(dot(n, lidi), 0.) * shad,
          spec = pow(diff, max(1., specExp * mafa)),
          refl = pow(max(0., dot(lidi, reflect(rd, n))), max(1., specExp * 3. * mafa)) * shad;
    vec3  ambc = mix(sunCol/8., ambCol, S(10., 20., length(p.xz))*.2+.6);
          
    return mix( ambc * col * amoc +                           //ambient
                mix(diff * col * sunCol,                      //diffuse
                (spec * col + refl * mafa), mafa) * sunCol,   //specular
                
                col  * S(0., 1., amoc * amoc + .5),           //emission
                max(-mat, 0.));
}

vec3 Palette(int index, in vec3 p)
{
    switch (index)
    {
        case 0: return vec3(1.);                                       //lightsphere
        case 1: return vec3(.8, .4, .35);                              //frame
        case 2: return vec3(.6, .6, .6);                               //concrete
        case 3: return vec3(.4, .3, .2)*(.25 + .25*noise(-p.xz/PI));   //terrain
        case 4: return hsv2rgb_smooth(vec3(fract(iTime/21.), .8, .8)); //sphere
        case 5: return vec3(.2, .6, .8);                               //roof
        case 6: return vec3(.5);
        case 7: return vec3(.3, .8, .2)*(.1 + .1*noise(p.xz/10.));     //trees
        case 8: return vec3(.5, .8, .2)*(.13 + .15*noise(p.xz/6.2));   //grass
        case 9: return vec3(.8, .5, .2)*(.2 + .4*noise(p.xy*vec2(.1,100.))); //messy stairs
    }
    return vec3(0.);
}

void Render( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = (fragCoord-.5 * iResolution.xy) / iResolution.y;
	vec2 m = S(vec2(0), vec2(1), iMouse.xy / iResolution.xy);

    if (length(m) <= 0.) m = vec2(0.65,.9);
    if (CAM_MOVEMENT && !AA_ENAB) 
        m = mix(m, pow(vec2(sin(iTime/69.-1.), -cos(iTime/69.)), vec2(3)) *
            vec2(.6, .3) + vec2(.6, .6), S(10., 100., (iMouse.z > 0.) ? 0. : iTime));

    vec3 ro = vec3(-1., 3., -8.-m.x*60.);
    ro.yz *= Rot(-m.y * PI/4. + PI/4.);
    ro.xz *= Rot(-m.x * PI * 2.);
    vec3 rd = R(uv, ro, vec3(0., 5., 0.), .8);
    
    vec3 bg = skyCol * (.2 + S(-.1, 0.3, dot(rd, vec3(0,1,0))));
    vec3 lPos = vec3(2,2,-2)*100.; 
    vec3 col = bg;
    vec3 p = vec3(0.);
    
    vec3 rmd = RayMarch(ro, rd);

    if(rmd.x < MAX_DIST) 
    {
        p = ro + rd * rmd.x;
        vec3 n = Normal(p);
        
        float shine = fract(rmd.z)*abs(rmd.z)/rmd.z;
        int index = int(floor(abs(rmd.z)));
        col = Palette(index, p);
        
        if (index == 3) n *= .8 + .6*noise(p.xz*33.);
        if (index == 8) n *= mix(.7 + .6*noise(p.xz*7.), 1., S(10., 150., rmd.x));
        
        col = Shade(col, shine, p, n, rd, lPos);   
        //col = vec3(1) * CalcAO(p, n);
    }
    
    float disFac = S(0., 1., pow(rmd.x / MAX_DIST, 1.2));
    
    col = mix(col, bg, disFac);

    float sdir = dot(normalize(lPos-ro), rd);
    float sblend =  pow(S(0.1, 1.2, sdir), 3.)*.6 + 
                    pow(max(sdir,0.01), 2000.);
    col += sblend * disFac * sunCol;
    
    float glow = pow(rmd.y / float(MAX_STEPS), 1.2) + sblend*sblend;
    col += glow * normalize(mix(sunCol/10., ambCol, S(10., 20., length(p.xz))*.5+.5)) * PP_GLOW;
    
    float hfog = S(0.3, .8, noise(p.zx/100.+vec2(iTime/21.))) * S(25., -10., p.y) * S(0., .05, disFac);
    col += glow * hfog * .8;
    
    
    fragColor = vec4(col,1.0);
}

vec4 PP(vec3 col, vec2 uv)
{
    col = mix(col, (col * (2.51 * col + 0.03)) / (col * (2.43 * col + 0.59) + 0.14), PP_ACES);
    col = mix(col, S(vec3(0.), vec3(1.), col), PP_CONT);  
    col *= S(PP_VIGN,-PP_VIGN/5., dot(uv,uv)); 
    col = pow(col, GAMMA);
    
    return vec4(col, 1.);
}

//totally unusable in realtime.
void mainImage(out vec4 O, vec2 U) //Fabrice - easy adaptive super sampling | edited
{
    Render(O,U);
    
    if (AA_ENAB && fwidth(length(O)) > AA_THRE)
    {
        vec4 o;
        for (int k=0; k < 9; k+= k==3?2:1 )
          { Render(o,U+vec2(k%3-1,k/3-1)/3.); O += o; }
        O /= 9.;
        //O.r++; //Show sampled area
    }
    
    O = PP(vec3(O), (U-.5 * iResolution.xy) / iResolution.y);
}