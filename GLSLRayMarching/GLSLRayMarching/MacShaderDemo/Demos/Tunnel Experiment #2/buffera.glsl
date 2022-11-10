
#define eps 0.001
#define S smoothstep
#define T iTime
#define TX texture
#define C clamp

#define MAX_STEPS 100
#define MAX_DIST 50.
#define pi 3.14159265

float ROUNDING_FACTOR = 0.;
float ROTATION_FACTOR = 10.;

float TUBE_RIB_REP_FACTOR = 10.;
float TUBE_RIB_AMP_FACTOR = .0;
float TUNNEL_RADIUS_FACTOR = 1.5;
float SIDE_NUM = 3.;

float TEETH_FLOAT = 2.;
float TEETH_REACH = 1.5;
float TEETH_SHAPE_X = 0.5;
float TEETH_SHAPE_Y = 0.15;
float TEETH_SHAPE_POW_Z = 0.2;
float CAMERA_Z_POS = 0.;
float CAMERA_ROTATE_XZ = 0.;
float GAMMA = 0.8;
float BRIGHTNESS = 1.;
vec3 FAR_LIGHT_POS = vec3(0.,0.,1.4);
vec3 CLOSE_LIGHT_POS = vec3(0.,-0.,-1.4);
vec3 backgroundColor = vec3(1.);
float PATH_AMPLITUDE = 0.;


//uncomment for more movement


float smin( float a, float b, float k )
{
    float h = clamp( 0.5+0.5*(b-a)/k, 0.0, 1.0 );
    return mix( b, a, h ) - k*h*(1.0-h);
}

float smax( float a, float b, float k ){
    float h = clamp( 0.5 + 0.5 * (a - b) / k, 0.0, 1.0 );
    return mix( b, a, h ) + k * h * (1.0 - h);
}

mat2 rot(float a){
    float c = cos(a), s = sin(a);
    return mat2(c,-s,s,c);
}
    
float sdBox(vec3 p, vec3 d){
    p = abs(p)-d;
    return length(max(p,0.)) + 
    min(max(p.x,max(p.y,p.z)), 0.)-ROUNDING_FACTOR;
}
float sdBox2D(vec3 p, vec3 d){
    p = abs(p)-d;
    //return length(max(p,0.)) + 
    return max(p.x,p.z);
}
vec2 modPolar(vec2 p, float n){

    float a0 = float(n) / radians(360.); 
    float a = round( atan(p.y, p.x) * a0 ) / a0;
    
    p -= vec2(cos(a), sin(a));
    
    p *= rot(-a);
    
    return p;
}

vec3 path(vec3 p){
    // #if PATH_ON == 1.
     p.x += sin(p.z/4.)*PATH_AMPLITUDE;
     p.y += sin(p.z/4.+3.)*PATH_AMPLITUDE;
   //  #endif
     return p;
}

float globalID = -1.;
float glow;

float map(vec3 p){
    
    p = path(p);
    p.xy*=rot(p.z/(ROTATION_FACTOR));//+(0.5+0.5*sin(mod(iTime/5.,2.)))*2.)   );
    float radius = TUNNEL_RADIUS_FACTOR;//0.8
    float num = SIDE_NUM; //5 to 8
    float z = sin(floor(p.z/4.))/4.;
    float d = 1000.;
    float tunnel = length(p.xy) - 3.4 
                                - abs(sin(p.z*TUBE_RIB_REP_FACTOR))
                                *TUBE_RIB_AMP_FACTOR;
    d = min(d,tunnel);
    //p.xy -= vec2(z);
    
    //magic!
    vec3 st = vec3(modPolar(p.xy, num), mod(p.z, 4.)-2. );
    
    float wall = sdBox( st-vec3(radius,0.,0.), vec3(0.1,2.,2.) );
    d = min(-d,wall);
    //d = min(d, length(st-vec3(radius,0.,0.))-0.3);
    
    //d = min(d, sdBox( st-vec3(radius,0.,0.), vec3(0.6,.3, pow(length(p.xy)-1., 2.7) ) ));
    
    //door layer one thick
    float layer1 = sdBox( st-vec3(radius,0.,0.), vec3(0.5,4.,.1) );
    //door layer two thinner
    float layer2 = sdBox( st-vec3(radius,0.,0.), vec3(0.8,3.,.08) );
    //door layer three really thin edge thing
    float layer3 = sdBox( st-vec3(radius,0.,0.), vec3(0.84,3.7,.01) );
    
    d = min(d,min(layer1,min(layer2,layer3)));
    //
    vec3 st3 = vec3(modPolar(p.xy, num), mod(p.z, .2)-.1);
    float lines = sdBox( st3-vec3(radius*1.0,0.,0.), vec3(0.1, 1.85,.02) );
    //float lines = sdBox( st3-vec3(radius,0.,0.), vec3(0.15,1.,.03) );
    d = min(d,lines);
    vec3 st2 = vec3(modPolar(p.xy, num), mod(p.z, 2.)-1.);
    //panel thing
    float panel = sdBox( st2-vec3(radius,0.,0.), vec3(0.4,1.1,.9));
    d = min(d,panel);
    
    //panel-indent thing
    //first version has artifacts
    //float indent = sdBox( st2-vec3(radius*0.74,0.,0.), vec3(0.15,.58,.8) );
    float indent = sdBox( st2-vec3(radius*0.74,0.,0.), vec3(0.15,.8,.75) );
    d = smax(d, -indent,0.003);
    float outdent = sdBox( st2-vec3(radius,0.,0.), vec3(0.15,.5,.78) );
    d = min(d, outdent);
    
    //ramp thing
    float ramp = sdBox( vec3(st.x,mod(st.y*TEETH_FLOAT,1.)-.5,st.z*TEETH_REACH)-vec3(radius,0.,0.), vec3(TEETH_SHAPE_X,TEETH_SHAPE_Y, pow(length(st.x/9.)/9., TEETH_SHAPE_POW_Z) ));
    
    /*
    //basic ramp no teeth
    ramp = sdBox(st-vec3(radius,0.,0.), vec3(0.8,.2, pow(length(st.x/4.), 1.9) ));
    
    //basic side teeth
    ramp = sdBox( vec3(st.x,mod(st.y*4.,1.)-.5,st.z)-vec3(radius,0.,0.), vec3(0.8,.2, pow(length(st.x/4.), 1.9) ));

    //full teeth
    ramp = sdBox( vec3(st.x,mod(st.y*4.,1.)-.5,st.z)-vec3(radius,0.,0.), vec3(0.85,.3, pow(length(st.x/4.), 1.9) ));

    //thin cover
    ramp = sdBox( vec3(st.x,mod(st.y*4.,1.)-.5,st.z)-vec3(radius,0.,0.), vec3(1.5,.3, pow(length(st.x/7.), 1.) ));

    //cover
    ramp = sdBox( vec3(st.x,mod(st.y*4.,1.)-.5,st.z)-vec3(radius,0.,0.), vec3(1.,.3, pow(length(st.x/1.), 1.) ));
    //exposed
    ramp = sdBox( vec3(st.x,mod(st.y*4.,1.)-.5,st.z)-vec3(radius,0.,0.), vec3(.8,.3, pow(length(st.x/1.), 1.) ));
    */  
    
    
    //ramp = max(ramp, -sdBox( st-vec3(radius,0.,-.3), vec3(0.5,.05, 0.2 ) ));
    d = smin(d,ramp,0.01);
    
    vec3 st4 = vec3(p.x,p.y,mod(p.z,2.)-1.);
    float bridge = sdBox( st4-vec3(0.,-1.1,0.), vec3(0.6,.04, .8 ));
    //d = min(d,bridge);
    //globalID = 5.;
    
    float minVal = min(min(
                        min(
                            min(layer3,lines),
                            min(panel,bridge)),
                        min(
                            min(wall, outdent),
                            min(layer1,layer2))), min(indent,ramp));
                            
    minVal = min(minVal,-tunnel);
    if(minVal == wall)globalID = 32.;
    
    else if(minVal == layer1)globalID = 2.;
    else if(minVal == layer2)globalID = 3.;
    else if(minVal == layer3)globalID = 4.;
    else if(minVal == outdent)globalID = 5.;
    else if(minVal == lines)globalID = 6.;
    else if(minVal == bridge)globalID = 7.;
    else if(minVal == panel)globalID = 5.;
    else if(minVal == ramp)globalID = 5.;
    else if(minVal == -tunnel)globalID = 33.;
    //else globalID = 9.;
    
    //else if(minVal == tunnel)globalID = 80.;
    
    if(minVal == layer3){
        glow += smoothstep(0.2,1.,0.015/pow(layer3,.9))*3.;
    }
    if(minVal == lines){ 
       glow += abs(max(0.01,(0.0001/(0.03*pow(lines, 1.)))));
    }
    
    
    return d;
}

float trace(vec3 ro, vec3 rd){
    
    float t, d= 0.;
    
    for(int i = 0; i < MAX_STEPS; i++){
        d = map(ro + rd*t);
        if(abs(d) < 0.001 || t > MAX_DIST) break;
        t += d*0.75;
    }
    
    return t;
}

float rtrace(vec3 ro, vec3 rd){
    
    float t, d= 0.;
    
    for(int i = 0; i < MAX_STEPS; i++){
        d = map(ro + rd*t);
        if(abs(d) < 0.001 || t > MAX_DIST) break;
        t += d*0.85;
    }
    
    return t;
}
vec3 normal(vec3 p){
    
    float d = map(p);
    vec2 e = vec2(eps,0.);
    
    vec3 n = d - vec3(
            map(p-e.xyy),
            map(p-e.yxy),
            map(p-e.yyx));
            
    return normalize(n);
}
vec3 camRay(vec2 uv, vec3 o, vec3 target, float zoom){
    
    vec3 fwd = normalize(target - o);
    vec3 uu = vec3(0.,1.,0.);
    vec3 right = normalize(cross(uu, fwd));
    //order matters
    vec3 up = cross(fwd,right);
    vec3 rd = right*uv.x + up*uv.y + fwd*zoom;
    return normalize(rd);

}

//from shane
float softShadow(vec3 ro, vec3 lp, float k){

    // More would be nicer. More is always nicer, but not really affordable... Not on my slow test machine, anyway.
    const int maxIterationsShad = 24; 
    
    vec3 rd = lp - ro; // Unnormalized direction ray.

    float shade = 1.;
    float dist = .002;    
    float end = max(length(rd), .001);
    float stepDist = end/float(maxIterationsShad);
    
    rd /= end;

    // Max shadow iterations - More iterations make nicer shadows, but slow things down. Obviously, the lowest 
    // number to give a decent shadow is the best one to choose. 
    for (int i = 0; i<maxIterationsShad; i++){

        float h = map(ro + rd*dist);
        //shade = min(shade, k*h/dist);
        shade = min(shade, smoothstep(0., 1., k*h/dist)); // Subtle difference. Thanks to IQ for this tidbit.
        // So many options here, and none are perfect: dist += min(h, .2), dist += clamp(h, .01, .2), 
        // clamp(h, .02, stepDist*2.), etc.
        dist += clamp(h, .02, .25);
        
        // Early exits from accumulative distance function calls tend to be a good thing.
        if (h<0. || dist>end) break; 
        //if (h<.001 || dist > end) break; // If you're prepared to put up with more artifacts.
    }

    // I've added 0.5 to the final shade value, which lightens the shadow a bit. It's a preference thing. 
    // Really dark shadows look too brutal to me.
    return min(max(shade, 0.) + .25, 1.); 
}
float getGrey(vec3 p)
{
    return p.x*0.299 + p.y*0.587 + p.z*0.114;
       }

//from shane, and he got it from an nvidia tutorial you can google
vec3 triPlanar(sampler2D tex, vec3 p, vec3 n)
{

 vec3 norm = max(abs(n), 0.0001);	//I'll keep it simple with just this
 float sum = norm.x+norm.y+norm.z;
 norm = norm/sum;
    return vec3(texture(tex, p.yz)*norm.x + 
                texture(tex, p.xz)*norm.y +
                texture(tex, p.xy)*norm.z) ;
    
}

vec3 bumpMap(sampler2D tex, in vec3 p, in vec3 n, float bumpfactor)
{

    const vec3 eps3 = vec3(0.001, 0., 0.);//I use swizzling here, x is eps
    float ref = getGrey(triPlanar(tex, p, n));//reference value 
    vec3 grad = vec3(getGrey(triPlanar(tex, p - eps3, n)) - ref,
                     //eps.yxz means 0.,0.001, 0. "swizzling
                     getGrey(triPlanar(tex, p - eps3.yxz, n)) - ref,
                     getGrey(triPlanar(tex, p - eps3.yzx, n)) - ref)/eps3.xxx;
    
    grad -= n*dot(grad, n);

    return normalize(n + grad*bumpfactor);
}

float calcAo(vec3 p, vec3 n)
{
 
const float ao_samples = 5.;
    float r = 0.0, w = 1.0, d;
    for(float i = 0.01 ; i<ao_samples ; i+=1.1)
    {
    d = i/ao_samples;//1/5, 2/5, 3/5, 4/5, 1
    r += w*(d - map(p + n*d));
    w*=0.5;
    }

    return 1.0 - clamp(r,0.0, 1.0);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = (fragCoord-iResolution.xy*0.5)/iResolution.y;
   // vec2 m = iMouse.xy/iResolution.xy;
   // fragColor = vec4(0.);
    vec3 ro = vec3(0., 0., -3.+iTime*3. + CAMERA_Z_POS);
    ro = vec3(-path(ro).xy,ro.z);
    //ro.yz *= rot(-m.y*pi+1.);
    //ro.xz *= rot(-m.x*pi*2.);
    
    //I was getting some artifacts when I had y at 0.4 or -0.4
    //for these lights. Glow related artifacts, which was weird.
    //So I am just letting the x and y be guided by ro.
    vec3 farLight = ro + FAR_LIGHT_POS;
    vec3 closeLight = ro + CLOSE_LIGHT_POS;
    vec3 rd = camRay(uv, ro, ro + vec3(0.,0.,1.), 0.8);
    rd.xz *= rot(CAMERA_ROTATE_XZ);
    
    float t = min(MAX_DIST,trace(ro, rd));
    
    
    // Time varying pixel color
    vec3 col = vec3(0.0);//TX(iChannel0, rd).rgb;
    vec3 rcol = vec3(0.);
    if(t < MAX_DIST){
    
        vec3 p = ro + rd*t;
        vec3 n = normal(p);
        
        //col = n*0.5+0.5;//0.5 + 0.5*cos(iTime+uv.xyx+vec3(0,2,4));
        //col = abs(fract(vec3(atan(p.y,p.x)*pi,p.z,p.z))-0.5);
        //col= n*0.5+0.5;
        
        vec3 seedColor= vec3(3.,2.,5.)/2.;
        seedColor.xy *= rot(.7);
        vec3 alb = 1.*vec3((0.5+0.5*cos(seedColor*8. + globalID*6. + 30.).x)*1.2>0.);
        alb = 0.5+0.5*cos(seedColor*8. + globalID*19. + 34.);
        //alb.xz *= rot(1.3);
        alb = alb.zzz-0.1;
        
        //alb = 0.5+0.5*cos(vec3(1.,2.,4.)/1. + globalID*54.+1.);
        
        if(globalID < 2.) {
            alb *= triPlanar(iChannel0,p/4.,n).xxx;
            #ifdef BUMP_MAP_ON
                n = bumpMap(iChannel0, p/4., n, 0.01);
            #endif
        }
        
        else if(globalID == 6.){ alb = pow(
            triPlanar(iChannel1,p/4.,n).xxx,vec3(1.))*3.;
            #ifdef BUMP_MAP_ON
                n = bumpMap(iChannel1, p/4., n, 0.01);
            #endif
            }
        
        else if(
            globalID < 8.){ alb *= triPlanar(iChannel2,p/4.,n).xxx;
            #ifdef BUMP_MAP_ON
                n = bumpMap(iChannel2, p/4., n, 0.01);
            #endif
        }
        
        //alb = pow(alb,vec3(.3));

        if(globalID == 32.){ alb = backgroundColor*vec3(1.,0.3,0.);}
        if(globalID == 33.){ alb = backgroundColor*vec3(0.,0.3,0.8);}

        //light 1
        float ldist = length(farLight-p);
        vec3 ldir = (farLight-p)/ldist;
        float diff = max(dot(ldir,n),0.);
        float spec = pow(max(dot(reflect(-ldir,n),-rd),0.),200.)*1.;
        col = alb*0.9*diff + spec*vec3(0.5,0.8,0.9);
        
        float sha = softShadow(p,farLight,12.);
        float ao = calcAo(p,n);
        col *= ao;
        col *= sha;
        
        //light 2
        ldist = length(closeLight-p);
        ldir = (closeLight-p)/ldist;
        diff = max(dot(ldir,n),0.);
        spec = pow(max(dot(reflect(-ldir,n),-rd),0.),100.)*1.;
        col += alb*0.3*diff*vec3(1.,0.7,0.7);
        col/=2.;
        
        
        col += vec3(0.5+0.5*cos(iTime + seedColor + sin(p)/2.))*clamp(glow,0.,1.);//*pow(t/MAX_DIST,.7);

    }
    
    col = mix(col,vec3(0.), pow(t/MAX_DIST,1.9));
    
    // Output to screen
    col *= BRIGHTNESS;
    col = pow(col, vec3(GAMMA));
    fragColor = vec4(col,1.0);
}

