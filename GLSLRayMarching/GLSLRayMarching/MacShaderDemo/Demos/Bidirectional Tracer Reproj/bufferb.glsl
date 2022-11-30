#define SPP 2

float ior;

struct Hit
{
    vec3 ro;//ray origin
    float td;//travelled distance
    vec3 rh;//ray hit position
    vec3 rd;//ray direction
    vec3 no;//normal at the hit position
    float id;//hit object id
    //other material stuff
};

struct Mat
{
    vec3 col; //color
    vec3 emi; //emission
    float rgh; //roughness
};

Mat getMaterial(float id)
{
    Mat outmat;
    outmat.col = vec3(1.0);
    outmat.emi = vec3(0.0);
    outmat.rgh = 0.3;
    return outmat;
}

vec3 opU( vec3 d, float iResult, float mat ) {
	return (iResult < d.y) ? vec3(d.x, iResult, mat) : d;
}

const float density = 0.003;

float iVolume( in vec3 ro, in vec3 rd, in vec2 distBound, inout vec3 normal )
{
    float d = -log(rand())/density;
    
    if (d < distBound.x || d > distBound.y) 
    {
        return MAX_DIST;
    } 
    else 
    {
    	return d;
    }
}

Hit worldhit(in vec3 ro, in vec3 rd, in vec2 dist) {
    vec3 normal;
    vec3 tmp0, tmp1, d = vec3(dist, 0.);
    
    
    
    d = opU(d, iPlane      (ro,                  rd, d.xy, normal, vec3(0,1,0), 0.), 1.);
    
    d = opU(d, iBox        (ro-vec3( 1,.252, -1), rd, d.xy, normal, vec3(.25)), 2.);
    d = opU(d, iSphere     (ro-vec3( 0,.252, 0), rd, d.xy, normal, .25), 3.);
    d = opU(d, iSphere     (ro-vec3( 0.6,.252, 0.2), rd, d.xy, normal, .25), 3.);
    d = opU(d, iSphere     (ro-vec3( -0.5,.252, 0.1), rd, d.xy, normal, .25), 3.);
    d = opU(d, iVolume     (ro, rd, d.xy, normal), 4.0);

    Hit res;
    res.ro = ro;
    res.rh = ro + d.y*rd;
    res.rd = rd;
    res.no = normal;
    res.id = d.z;
    res.td = d.y;
    return res;
}

void processHit(Hit res, inout vec3 ro, inout vec3 rd, inout float inside, inout vec3 col, inout vec3 att)
{
    Mat m = getMaterial(res.id);
    
    col += att*m.emi;
    att *= m.col;
    vec3 normal = res.no;
    if(res.id < 4.0)
    {
        if(res.id == 3.0)
        {
            ro = res.rh ;
             
            vec3 matn = normalize(nrand3(0.005, normal*inside));
            vec3 newrd = refract(rd, matn, pow(1.0 + 1.2*ior, -inside));
            if(length(newrd) > 0.5) //not total internal reflection
            {
                inside = -inside;
                rd = newrd;
            }
            else
            {
                rd =reflect(rd, matn); 
            } 
        }
        else
        {
            //surface scatter
            rd = reflect(res.rd, normalize(nrand3(m.rgh, normal))); 
            ro = res.rh + inside*res.no*5e-3;
        }
      
    } 
    else
    {
        //volume scatter
        rd = udir(rand2());
        ro = res.rh;
    }
}


#define LASER_PATH 7
int cpath;
vec3 path[LASER_PATH+1];

float getClosestLinePoint(vec3 ro, vec3 rd, vec3 x)
{
    return dot(rd, x - ro);
}

float rand(float a, float b)
{
    return mix(a, b, rand());
}

//Importance sample a point on a segment so that the probability of sampling a point on the segment r1 r2
//is inversely proportional to the square of the distance to point x
vec3 importanceSampleSegmentPoint(vec3 r1, vec3 r2, vec3 x)
{
    vec3 x0 = r1 - x;
    vec3 rd = normalize(r2 - r1);
    float l = length(r2 - r1);
    float a = dot(rd, x0);
    float x02 = dot(x0, x0);
    float sq = sqrt(x02 - a*a); 
    float t = sq*tan(rand(atan(a/sq),atan((l + a)/sq))) - a;
    return r1 + rd*t; //importance sampled point
}

//get closest point pair for 2 segments
void getClosestPointPair(vec3 r00, vec3 r01, vec3 r10, vec3 r11, out vec3 P1, out vec3 P2)
{
  vec3 delta1 = r01 - r00;
  vec3 delta2 = r11 - r10;
  vec3 rd1 = normalize(delta1);
  vec3 rd2 = normalize(delta2);
  float l1 = length(delta1);
  float l2 = length(delta2);
  vec3 delta3 = r00 - r10;
  float d1d2 = dot(rd1, rd2);
  float d1de = dot(rd1, delta3);
  float d2de = dot(rd2, delta3);
  float deno = 1.0/(1.0 - d1d2*d1d2);
  float t1 = (d1d2*d2de - d1de)*deno;
  float t2 = (d2de - d1d2*d1de)*deno;
  
  if(t1 < 0.0 || t1 > l1)
  {
      t1 = clamp(t1, 0.0, l1);
      P1 = r00 + t1*rd1;
      t2 = clamp(getClosestLinePoint(r10, rd2, P1), 0.0, l2);
      P2 = r10 + t2*rd2;
      return;
  }
  
  if(t2 < 0.0 || t2 > l2)
  {
      t2 = clamp(t2, 0.0, l2);
      P2 = r10 + t2*rd2;
      t1 = clamp(getClosestLinePoint(r00, rd1, P2), 0.0, l1);
      P1 = r00 + t1*rd1;
      return;
  }
  
   P1 = r00 + t1*rd1;
   P2 = r10 + t2*rd2;
}

//choose a laser path segment p0 p1 with probability proportional to the path segment lenght and 
//inverse distance to the camera ray path segment r0 r1
void importanceSamplePath(vec3 r0, vec3 r1, out vec3 p0, out vec3 p1)
{
    float score[LASER_PATH];
    float totalscore = 0.0;
    vec3 P0, P1;
    for(int i = 0; i < cpath; i++)
    {
        getClosestPointPair(r0,r1,path[i],path[i+1],P0,P1);
        float s = distance(path[i],path[i+1])/distance(P0,P1);
        totalscore += s;
        score[i] = totalscore;
    }
    
    //target score
    float rscore = rand()*totalscore;
    
    for(int i = 0; i < cpath; i++)
    {
        if(rscore < score[i]) //found score
        {
            p0 = path[i];
            p1 = path[i+1];
            return;
        }
    }
}

//next event estimation sample using the light path
void connectPath(Hit res, inout vec3 col, inout vec3 att)
{
    //camera ray path
    vec3 r0 = res.ro;
    vec3 r1 = res.rh;
    
    //get random path
    vec3 p0, p1;
    importanceSamplePath(r0,r1,p0,p1);
    
    //find 2 closest points on camera segment and light path 
    vec3 s1, s2;
    getClosestPointPair(p0, p1, r0, r1, s1, s2); 
    
    vec3 pathp = importanceSampleSegmentPoint(p0, p1, s2);
    vec3 camp = importanceSampleSegmentPoint(r0, r1, s1);
    
    //trace a ray from the camp to pathp
    vec3 delta = pathp - camp;
    float td = length(delta);
    
    
    Hit con = worldhit( camp, normalize(delta), vec2(.001, td));
    
    if(con.td >= td) col += att/(td+1e-10);
    //col += att*pathhit(res.ro, res.rd, res.td);
}

bool getRay(vec2 uv, out vec3 ro, out vec3 rd)
{
    mat3 cam = getCam(get(CamA));
    vec2 apert_cent = -0.*uv; 
    vec2 ap = aperture();  
    if(!(distance(ap, apert_cent) < 1.0)) return false;  
    float apd = length(ap);  
    vec3 daperture = ap.x*cam[0] + ap.y*cam[1]; 
    ro = get(CamP).xyz + aperture_size*daperture;
    float focus =2.5 + 0.8*pow(apd,5.0);
    rd = normalize(focus*(cam*vec3(FOV*uv, 1.0)) - aperture_size*daperture);
    return true;
}

vec4 render(vec2 fragCoord)
{
    fragCoord += nrand2(0.5, vec2(0.));
    vec2 uv = (fragCoord - 0.5*iResolution.xy)/iResolution.y;
   
    vec3 ro, rd, normal;
  
    // get a random refractive index different per pixel
    ior = 0.7*(rand() - 0.5);
    //ior = -0.2;
    //ior = (fract(gl_FragCoord.y/3.)-.5);
    //slightly more realistic dispesion law
    float id=1./(1.0 + ior);
    // compute index of refraction associated color 
    vec3 scol = WavelengthToXYZLinear(350.0*(ior + 0.5) + 350.0);
     ior = id;
     
    //trace laser   
    ro = get(RayO).xyz;
    rd = normalize(get(RayD).xyz + 0.01*udir(rand2()));
    
    float inside = 1.0;
    
    vec3 col = vec3(0.0);
    vec3 att = scol;
    
    
    for(cpath = 0; cpath < LASER_PATH - 1; cpath++)
    {
        path[cpath] = ro;
        Hit res = worldhit( ro, rd, vec2(.001, MAX_DIST));
        if (res.id > 0.) 
        {
            processHit(res,ro,rd,inside,col,att);
        }
        else 
        {
            ro = res.rh;
            break;
        }
    }
    path[cpath+1] = ro;
    
    if(!getRay(uv, ro, rd)) return vec4(0,0,0,1);
    
    col = vec3(0.0);
    att = scol;
    inside = 1.0;
    
    for(int i = 0; i < 5; i++)
    {
        Hit res = worldhit( ro, rd, vec2(.001, MAX_DIST));
        
        connectPath(res, col, att);
        processHit(res,ro,rd,inside,col,att);
    }
   
    return vec4(col, 1.0);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    rng_initialize(fragCoord, iFrame);

    fragColor = vec4(0.0);
    for(int i = 0; i < SPP; i++)
        fragColor += clamp(render(fragCoord),-0.2e3,0.2e3);
       
    
    mat3 prevcam = getCam(get(PrevCamA));
    vec3 prevcamp = get(PrevCamP).xyz;
    
    vec3 ro, rd;
    vec2 uv = (fragCoord - 0.5*iResolution.xy)/iResolution.y;
    getRay(uv, ro, rd);
    
    Hit res = worldhit( ro, rd, vec2(.001, MAX_DIST));
    
     vec3 cv = get(CamV).xyz;
    vec3 rep = reproject(prevcam, prevcamp, iResolution.xy, ro + rd*res.td);
    float reject = 0.975*float(all(lessThan(rep.xy, iResolution.xy)) && all(greaterThan(rep.xy,vec2(0))));
    reject *= smoothstep(5.0, 0.0, length(cv));
    fragColor += texture(iChannel0, rep.xy/iResolution.xy)*reject;
   
    
}