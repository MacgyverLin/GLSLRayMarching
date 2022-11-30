//controller

//Keyboard constants
const int keyLe = 37, keyUp = 38, keyRi = 39, keyDn = 40, keyA = 65, keyB = 66, keyC = 67, keyD = 68, keyE = 69, keyF = 70, keyG = 71, keyH = 72, keyI = 73, keyJ = 74, keyK = 75, keyL = 76, keyM = 77, keyN = 78, keyO = 79, keyP = 80, keyQ = 81, keyR = 82, keyS = 83, keyT = 84, keyU = 85, keyV = 86, keyW = 87, keyX = 88, keyY = 89, keyZ = 90;

bool pressed(int k) 
{
    return texelFetch(iChannel3, ivec2(k, 0), 0).x > 0.5;
}

const float force =25.0;
const float mouse_sens = 100.0;
const float roll_speed = 0.5;

void mainImage( out vec4 o, in vec2 p )
{
    p = floor(p);
    if(p.x > NAddr && p.y > 0.) discard;
    
    //get camera data
    vec3 cp = get(CamP).xyz;
    vec4 ca = normalize(get(CamA));
    
    vec3 pcp = cp;
    vec4 pca = ca;
    
    vec3 ro = get(RayO).xyz;
    vec3 rd = get(RayD).xyz;
    
    float mode = 0.0;
    if(pressed(keyR)) mode = 1.0;
    
    //initialization
    if(iFrame < 10)
    {
        cp = vec3(-1.,1.5,-1);
        ca = aa2q( normalize(vec3(0,1,0)), -PI*0.6/4.0);
        mat3 cam = getCam(ca);
        ca = qq2q(ca, aa2q(cam*vec3(1,0,0), -PI*0.4/4.0)); 
        ro = vec3( -2,.252, 0);
        rd = normalize(vec3(0.3,0.,-0.002));
    }
    vec4 oldca = ca;
    if(p.x == PrevCamP) o = vec4(cp, 0);
    if(p.x == PrevCamA) o = ca;
    
    mat3 cam = getCam(ca);
    
    //get velocities
    vec3 cv = get(CamV).xyz;
    vec4 cav = get(CamAV);
    
    float dt = 1./60.0;
    //update position
    if(pressed(keyW)) cv += force*dt*cam*vec3(0,0,1);
    if(pressed(keyS)) cv += force*dt*cam*vec3(0,0,-1);
    if(pressed(keyA)) cv += force*dt*cam*vec3(-1,0,0);
    if(pressed(keyD)) cv += force*dt*cam*vec3(1,0,0);
    
    cp += dt*cv;
    cv += -cv*tanh(10.0*dt);
    
    //update camera orientation
    vec2 dmouse = dt*mouse_sens*(iMouse.xy - get(PrevMouse).xy)/iResolution.x;
    
    if(length(dmouse) < 0.1)
    {
        //rotate around y ax
        ca = qq2q(ca, aa2q(cam*vec3(0,1,0), -dmouse.x)); 
        //rotate around x ax
        ca = qq2q(ca, aa2q(cam*vec3(1,0,0), dmouse.y));
    }
    
    //roll camera
    if(pressed(keyQ)) ca = qq2q(ca, aa2q(cam*vec3(0,0,1), -roll_speed*dt)); 
    if(pressed(keyE)) ca = qq2q(ca, aa2q(cam*vec3(0,0,1), roll_speed*dt)); 
    
    if(distance(oldca, ca) > 0.001 || length(cv) > 0.01) mode = 1.0;
    
    if(pressed(keyN)) 
    {
        rd = cam*vec3(0,0,1);
        ro = cp + 0.05*cam*vec3(1,1,0);
    }
    
    if(p.x == CamP) o = vec4(cp, mode);
    if(p.x == CamA) o = ca;
    if(p.x == PrevCamP) o = vec4(pcp, mode);
    if(p.x == PrevCamA) o = pca;
    if(p.x == CamV) o = vec4(cv, 0.0);
    if(p.x == CamAV) o = vec4(0.0);
    if(p.x == PrevMouse) o = vec4(iMouse.xy, 0, 0);
    if(p.x == RayO) o = vec4(ro, 0);
    if(p.x == RayD) o = vec4(rd, 0);
}