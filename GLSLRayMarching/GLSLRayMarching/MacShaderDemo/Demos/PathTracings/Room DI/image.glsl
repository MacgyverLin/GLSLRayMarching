const float t = 16.0;//nr. sample per pixel

#define pi acos(-1.0)
#define pi2 pi/2.0

struct Sphere
{
	vec4 center_radius;
	int idmaterial;
};

struct Box
{
    vec3 min, max;
   int idmaterial;
};
    
struct Cylinder 
{
    vec3 c;
    float r,h;
    int idmaterial;
};

Box box0;
Sphere sfere[4];
Box boxe[15];
Cylinder cylinder[4];
//Material material[6];

vec3 light = vec3(0.0, 0.0, 0.0);
vec3 cub, lcub, nrm, crm;
vec2 uvCoord;
vec2 p,rv2;
vec2 randv2;
float side = 1.0;
float time ;
float f0, f1,f2,f3;


vec2 rand2(){// implementation derived from one found at: lumina.sourceforge.net/Tutorials/Noise.html
   randv2+=vec2(1.0,1.0);
   return vec2(fract(sin(dot(randv2.xy ,vec2(12.9898,78.233))) * 43758.5453),
      		   fract(cos(dot(randv2.xy ,vec2(4.898,7.23))) * 23421.631));
}

vec3 CosineWeightedSampleHemisphere ( vec3 normal, vec2 rnd )
{
   //rnd = vec2(rand(vec3(12.9898, 78.233, 151.7182), seed),rand(vec3(63.7264, 10.873, 623.6736), seed));
   float phi = acos( sqrt(1.0 - rnd.x)) ;
   float theta = 2.0 * 3.14 * rnd.y ;

   vec3 sdir = cross(normal, (abs(normal.x) < 0.5001) ? vec3(1.0, 0.0, 0.0) : vec3(0.0, 1.0, 0.0));
   vec3 tdir = cross(normal, sdir);

   return normalize(phi * cos(theta) * sdir + phi * sin(theta) * tdir + sqrt(1.0 - rnd.x) * normal);
}

vec3 cosPowDir(vec3  dir, float power) 
{//creates a biased random sample
   vec2 r=rand2()*vec2(6.2831853,1.0);
   vec3 sdir=cross(dir,((abs(dir.x)<0.5)?vec3(1.0,0.0,0.0):vec3(0.0,1.0,0.0)));
   vec3 tdir=cross(dir,sdir); 
   r.y=pow(r.y,0.01/power);
   float oneminus = sqrt(1.0-r.y*r.y);
   return cos(r.x)*oneminus*sdir + sin(r.x)*oneminus*tdir + r.y*dir;
}

vec2 intersectCube(vec3 origin, vec3 ray, Box cube) {      
   vec3   tMin = (cube.min - origin) / ray;      
   vec3   tMax = (cube.max - origin) / ray;      
   vec3     t1 = min(tMin, tMax);      
   vec3     t2 = max(tMin, tMax);
   float tNear = max(max(t1.x, t1.y), t1.z);
   float  tFar = min(min(t2.x, t2.y), t2.z);
   return vec2(tNear, tFar);   
}

vec3 normalForCube(vec3 hit, Box cube)
{  
   if(hit.x < cube.min.x + 0.0001) return vec3(-1.0, 0.0, 0.0);   
   else if(hit.x > cube.max.x - 0.0001) return vec3( 1.0, 0.0, 0.0);   
   else if(hit.y < cube.min.y + 0.0001) return vec3(0.0, -1.0, 0.0);   
   else if(hit.y > cube.max.y - 0.0001) return vec3(0.0, 1.0, 0.0);      
   else if(hit.z < cube.min.z + 0.0001) return vec3(0.0, 0.0, -1.0);   
   else return vec3(0.0, 0.0, 1.0);   
}

float intersectSphere(vec3 origin, vec3 ray, Sphere s) {   
   vec3 toSphere = origin - s.center_radius.xyz;      
   float sphereRadius = s.center_radius.w;
   float a = dot(ray, ray);      
   float b = dot(toSphere, ray);   
   float c = dot(toSphere, toSphere) - sphereRadius*sphereRadius;   
   float discriminant = b*b - a*c;      
   if(discriminant > 0.0) {      
      float t = (-b - sqrt(discriminant)) ;   
      if(t > 0.0) return t;      
   }   
   return 10000.0;   
}  

vec3 normalForSphere(vec3 hit, Sphere s) {   
   return (hit - s.center_radius.xyz) / s.center_radius.w;   
} 

float iCylinder(vec3 ro, vec3 rd, Cylinder cylinder)
{
	vec3  rc = ro - cylinder.c;
    float a = dot( rd.xz, rd.xz );
	float b = dot( rc.xz, rd.xz );
	float c = dot( rc.xz, rc.xz ) - cylinder.r*cylinder.r;//0.249;
	float d = b*b - a*c;
	if( d>=0.0 )
	{
		// cylinder			
		float s = (-b - sqrt( d ))/a;
        float hy = ro.y-cylinder.c.y+s*rd.y;
		if( s>0.0 && hy<cylinder.h && hy>-cylinder.h )
		{
			return s;
		}
		// cap			
		/*s = (cylinder.h - ro.y+cylinder.c.y)/rd.y;
		if( s>0.0 && (s*s*a+2.0*s*b+c)<0.0 )
		{
			return s;
		}*/
	}
    return 100000.0;
}

vec3 normalforCylinder(vec3 hit,Cylinder cylinder)
{
    vec3 nor;
	nor.xz = hit.xz - cylinder.c.xz;
    nor.y = 0.0;
    nor = nor/cylinder.r;
    //nor.y = 1.0*sign(hit.y-cylinder.c.y);
    return nor;
}

void initscene()
{
    box0.min = vec3(-2.0, -1.2, -2.0);//room
   	box0.max = vec3( 2.0,  1.2,  2.0);
    
    light = vec3(cos(time *0.0)*1.65-0.5, sin(time*0.0)*0.65+0.7, sin(time*0.5)*1.65);

    float h = sin(time*3.0)*0.03;
    float sinr = sin(time)*0.5; float cosr = cos(time)*0.5;
    sfere[0].center_radius = vec4( 0.0, h-0.3, 0.0,    0.523);//rosu
   	sfere[1].center_radius = vec4( 0.0, h-0.29, 0.0,    0.520);//verde
   	sfere[2].center_radius = vec4(sinr, h+0.1,cosr,    0.123);//albastru
    
    vec3 center = vec3(0.8,-0.8,-1.6); 
    cylinder[0].c = vec3( 0.55,0.0, 0.25) + center;
    cylinder[0].r = 0.04;
    cylinder[0].h = 0.4;
    
    cylinder[1].c = vec3( 0.55,0.0,-0.25) + center;
    cylinder[1].r = 0.04;
    cylinder[1].h = 0.4;
    
    cylinder[2].c = vec3(-0.55,0.0, 0.25) + center;
    cylinder[2].r = 0.04;
    cylinder[2].h = 0.4;
    
    cylinder[3].c = vec3(-0.55,0.0,-0.25) + center;
    cylinder[3].r = 0.04;
    cylinder[3].h = 0.4;

   	center = vec3(-1.55,-0.2, 0.5);
    cub = vec3(0.0, 0.0, 0.0) + center;//corp dulap
    lcub = vec3(0.4, 1.0, 0.8);    
   	boxe[0].min = cub - lcub;
   	boxe[0].max = cub + lcub;
    
   	cub = vec3(0.5, 0.0, +0.0) + center;//fanta
   	lcub = vec3(0.12, 0.98, 0.01);
   	boxe[1].min = cub - lcub;
   	boxe[1].max = cub + lcub;
    
   	cub = vec3(0.02, 0.99, 0.0) + center;//plafon
   	lcub = vec3(0.43, 0.015, 0.85);
   	boxe[2].min = cub - lcub;
   	boxe[2].max = cub + lcub;   
    
   	cub = vec3( 0.380, 0.0, 0.385) + center;//oglinda dreapta
   	lcub = vec3(0.03, 0.77, 0.18);    
   	boxe[3].min = cub - lcub;
   	boxe[3].max = cub + lcub;
    
   	cub = vec3(0.385, 0.0, -0.385) + center;//oglinda stanga
   	lcub = vec3(0.03, 0.77, 0.18);
   	boxe[4].min = cub - lcub;
   	boxe[4].max = cub + lcub;

   	cub = vec3(0.41, 0.0, 0.06) + center;//maner dreapta
   	lcub = vec3(0.021, 0.1, 0.01);
   	boxe[5].min = cub - lcub;
   	boxe[5].max = cub + lcub;

   	cub = vec3(0.41, 0.0, -0.06) + center;//maner stanga
   	lcub = vec3(0.021, 0.1, 0.01);
   	boxe[6].min = cub - lcub;
   	boxe[6].max = cub + lcub;

   /*	cub = vec3(0.0, 0.0, 0.0) + center;//bbox
   	lcub = vec3(0.47, 1.2, 0.87);
   	boxe[7].min = cub - lcub;
   	boxe[7].max = cub + lcub;*/
//dulap

//birou
	center = vec3(0.8,-0.8,-1.6);
   	cub = vec3( 0.0, 0.4, 0.0) + center;//tablie
   	lcub = vec3(0.65, 0.015, 0.35);
   	boxe[7].min = cub - lcub;
   	boxe[7].max = cub + lcub;

//scaun
   	cub = vec3(-0.0, 0.1, 0.5) + center;//tablie
   	lcub = vec3(0.25, 0.015, 0.25);
   	boxe[8].min = cub - lcub;
   	boxe[8].max = cub + lcub;

   	cub = vec3(-0.22, -0.15, 0.28) + center;//picior stanga fata
   	lcub = vec3(0.03, 0.25, 0.03);
   	boxe[9].min = cub - lcub;
   	boxe[9].max = cub + lcub;

   	cub = vec3( 0.22, -0.15, 0.28) + center;//picior dreapta fata
   	lcub = vec3(0.03, 0.25, 0.03);
   	boxe[10].min = cub - lcub;
   	boxe[10].max = cub + lcub;

   	cub = vec3( 0.22, 0.2,  0.72) + center;//picior dreapta spate
   	lcub = vec3(0.03, 0.60, 0.03);
   	boxe[11].min = cub - lcub;
   	boxe[11].max = cub + lcub;

   	cub = vec3(-0.22, 0.2,  0.72) + center;//picior stanga spate
   	lcub = vec3(0.03, 0.60, 0.03);
   	boxe[12].min = cub - lcub;
   	boxe[12].max = cub + lcub;

   	cub = vec3(-0.0, 0.6,  0.74) + center;//spatar
   	lcub = vec3(0.25, 0.10, 0.01);
   	boxe[13].min = cub - lcub;
   	boxe[13].max = cub + lcub;
    
    cub = vec3(-0.4,-0.87,  1.9) ;//calorifer
   	lcub = vec3(0.55, 0.3, 0.06);
   	boxe[14].min = cub - lcub;
   	boxe[14].max = cub + lcub;
}

void intersectscene(vec3 ro, vec3 rd, inout float t, inout int i, bool bl)
{
    float tSphere6 = intersectSphere(ro, rd, sfere[3]);
    if(tSphere6 < t && bl) { t = tSphere6;i=6;}

   	/*float tSphere = intersectSphere(ro, rd, sfere[0]);
    if(tSphere < t) { t = tSphere;i=0;}
   	tSphere = intersectSphere(ro, rd, sfere[1]);
    if(tSphere < t) { t = tSphere;i=1;}
   	tSphere = intersectSphere(ro, rd, sfere[2]);
    if(tSphere < t) { t = tSphere;i=2;}
	*/
    
    
	float tcyl = iCylinder(ro, rd, cylinder[0]);
    if(tcyl<t) {t = tcyl; i = 10;}
    tcyl = iCylinder(ro, rd, cylinder[1]);
    if(tcyl<t) {t = tcyl; i = 11;}
    tcyl = iCylinder(ro, rd, cylinder[2]);
    if(tcyl<t) {t = tcyl; i = 12;}
    tcyl = iCylinder(ro, rd, cylinder[3]);
	if(tcyl<t) {t = tcyl; i = 13;}
    
	vec2 tboxc = intersectCube(ro, rd, boxe[0]); 
    if(tboxc.x>0.0 && tboxc.x<tboxc.y && tboxc.x < t) {t = tboxc.x; i = 20;}
    vec2 tboxf = intersectCube(ro, rd, boxe[1]); 
    //if(tboxf.x>0.0 && tboxf.x<tboxf.y && tboxf.x < t) {t = tboxf.x; i = 21;}
    vec2 tbox = intersectCube(ro, rd, boxe[2]); 
    if(tbox.x>0.0 && tbox.x<tbox.y && tbox.x < t) {t = tbox.x; i = 22;}
    tbox = intersectCube(ro, rd, boxe[3]); 
    if(tbox.x>0.0 && tbox.x<tbox.y && tbox.x < t) {t = tbox.x; i = 23;}
    tbox = intersectCube(ro, rd, boxe[4]); 
    if(tbox.x>0.0 && tbox.x<tbox.y && tbox.x < t) {t = tbox.x; i = 24;}
    tbox = intersectCube(ro, rd, boxe[5]); 
    if(tbox.x>0.0 && tbox.x<tbox.y && tbox.x < t) {t = tbox.x; i = 25;}    
    tbox = intersectCube(ro, rd, boxe[6]); 
    if(tbox.x>0.0 && tbox.x<tbox.y && tbox.x < t) {t = tbox.x; i = 26;} 

    float t1 = 200000.0;
    float t2 = 200000.0;  
    if(tboxf.x>0.0 && tboxf.x<tboxf.y) {t1 = tboxf.y; t2=tboxf.x;}
    if(t1>t && t2<t && i==20) {t=t1; i=21;}

    tbox = intersectCube(ro, rd, boxe[7]); 
    if(tbox.x>0.0 && tbox.x<tbox.y && tbox.x < t) {t = tbox.x; i = 27;}
    tbox = intersectCube(ro, rd, boxe[8]); 
    if(tbox.x>0.0 && tbox.x<tbox.y && tbox.x < t) {t = tbox.x; i = 28;}
    tbox = intersectCube(ro, rd, boxe[9]); 
    if(tbox.x>0.0 && tbox.x<tbox.y && tbox.x < t) {t = tbox.x; i = 29;}
    tbox = intersectCube(ro, rd, boxe[10]); 
    if(tbox.x>0.0 && tbox.x<tbox.y && tbox.x < t) {t = tbox.x; i = 30;}
    tbox = intersectCube(ro, rd, boxe[11]); 
    if(tbox.x>0.0 && tbox.x<tbox.y && tbox.x < t) {t = tbox.x; i = 31;}
    tbox = intersectCube(ro, rd, boxe[12]); 
    if(tbox.x>0.0 && tbox.x<tbox.y && tbox.x < t) {t = tbox.x; i = 32;}
    tbox = intersectCube(ro, rd, boxe[13]); 
	if(tbox.x>0.0 && tbox.x<tbox.y && tbox.x < t) {t = tbox.x; i = 33;}
    
    tbox = intersectCube(ro, rd, boxe[14]); 
    if(tbox.x>0.0 && tbox.x<tbox.y && tbox.x < t) {t = tbox.x; i = 34;}
}

void ColorAndNormal(vec3 hit, inout vec4 mcol, inout vec3 normal, vec2 tRoom, inout vec2 mref, inout float t, const int id)
{
	if(t == tRoom.y)
	{            
		mref = vec2(0.0,0.0);
        normal =-normalForCube(hit, box0);   
        if(abs(normal.x)>0.0)
        { 
            mcol.xyz = vec3(0.65,0.85,0.99);
            mref = vec2(0.0,1.0);
        } 
         else if(normal.y>0.0)
        {
            vec3 tcol = texture(iChannel1,1.0-(hit.xz-vec2(1.5,1.5))/3.5).xyz;
            float s = tcol.y+0.1;//-d
            s = pow(s,3.0)*0.75+0.01;
            mref = vec2((s*0.5+0.1),pow(1.0-s,2.0));;//vec2(s,pow(1.0-s,2.0));
            mcol.xyz = tcol+0.4;
        } 
        else if(abs(normal.z)>0.0)
        {
            mcol.xyz = vec3(0.65,0.85,0.99);
            mref = vec2(0.0,1.0);
            
            if(normal.z<0.0)
			{
            	vec2 c = vec2(-0.4,0.1);
            	if(	all(lessThanEqual(hit.xy,vec2(-0.05,0.6)+c)) &&
               		all(greaterThanEqual(hit.xy,vec2(-0.7,-0.6)+c)) ||
               		all(lessThanEqual(hit.xy,vec2(0.7,0.6)+c)) &&
               		all(greaterThanEqual(hit.xy,vec2(0.05,-0.6)+c)))
               		mcol = vec4(vec3(1.1),2.0);
			}
        }
	}     
	else   
	{
        	 if(id==0) {normal = normalForSphere(hit, sfere[0]); mcol = vec4(0.9,0.9,0.9,0.0); mref = vec2(0.0,0.0);}
        else if(id==1) {normal = normalForSphere(hit, sfere[1]); mcol = vec4(0.9,0.9,0.9,0.0); mref = vec2(0.0,0.0);}
        else if(id==2) {normal = normalForSphere(hit, sfere[2]); mcol = vec4(0.9,0.9,0.9,0.0); mref = vec2(0.0,0.0);}
        else if(id==6) {normal = normalForSphere(hit, sfere[3]); mcol = vec4(0.9,0.9,0.9,0.0); mref = vec2(0.0,0.0);}
    	else if(id==10) {normal = normalforCylinder(hit, cylinder[0]); mcol = vec4(0.9,0.9,0.9,0.0); mref = vec2(1.0,1000.0);}
        else if(id==11) {normal = normalforCylinder(hit, cylinder[1]); mcol = vec4(0.9,0.9,0.9,0.0); mref = vec2(1.0,1000.0);}
        else if(id==12) {normal = normalforCylinder(hit, cylinder[2]); mcol = vec4(0.9,0.9,0.9,0.0); mref = vec2(1.0,1000.0);}
        else if(id==13) {normal = normalforCylinder(hit, cylinder[3]); mcol = vec4(0.9,0.9,0.9,0.0); mref = vec2(1.0,1000.0);}
        else if(id==20) {normal = normalForCube(hit, boxe[0]); mcol = vec4(0.9,0.9,0.9,0.0); mref = vec2(0.0,0.0);}
        else if(id==21) {normal = normalForCube(hit, boxe[1]); mcol = vec4(0.9,0.9,0.9,0.0); mref = vec2(0.0,0.0);}
        else if(id==22) {normal = normalForCube(hit, boxe[2]); mcol = vec4(0.9,0.9,0.9,0.0); mref = vec2(0.0,0.0);}
        else if(id==23) {normal = normalForCube(hit, boxe[3]); mcol = vec4(0.9,0.9,0.9,0.0); mref = vec2(1.0,9000.0);}
        else if(id==24) {normal = normalForCube(hit, boxe[4]); mcol = vec4(0.9,0.9,0.9,0.0); mref = vec2(1.0,9000.0);}
        else if(id==25) {normal = normalForCube(hit, boxe[5]); mcol = vec4(0.9,0.9,0.9,0.0); mref = vec2(1.0,10.0);}
        else if(id==26) {normal = normalForCube(hit, boxe[6]); mcol = vec4(0.9,0.9,0.9,0.0); mref = vec2(1.0,10.0);}
        else if(id==27) {normal = normalForCube(hit, boxe[7]); mcol = vec4(0.1,0.1,0.1,0.0); mref = vec2(0.8,0.8);}
        else if(id==28) {normal = normalForCube(hit, boxe[8]); mcol = vec4(0.1,0.1,0.1,0.0); mref = vec2(0.6,0.8);}
        else if(id==29) {normal = normalForCube(hit, boxe[9]); mcol = vec4(0.1,0.1,0.1,0.0); mref = vec2(0.6,0.8);}
        else if(id==30) {normal = normalForCube(hit, boxe[10]); mcol = vec4(0.1,0.1,0.1,0.0); mref = vec2(0.6,0.8);}
        else if(id==31) {normal = normalForCube(hit, boxe[11]); mcol = vec4(0.1,0.1,0.1,0.0); mref = vec2(0.6,0.8);}
        else if(id==32) {normal = normalForCube(hit, boxe[12]); mcol = vec4(0.1,0.1,0.1,0.0); mref = vec2(0.6,0.8);}
        else if(id==33) {normal = normalForCube(hit, boxe[13]); mcol = vec4(0.1,0.1,0.1,0.0); mref = vec2(0.6,0.8);}
        else if(id==34) {normal = normalForCube(hit, boxe[14]); mcol = vec4(0.9,0.9,0.9,0.0); mref = vec2(0.05,3.8);}
        
        if(id>19 && id<23)//material for dulap
        {
            vec2 uv = hit.yz;
            uv = abs(normal.y) > 0.0 ? hit.zx : uv;
            uv = abs(normal.z) > 0.0 ? hit.yx : uv; 
            mcol.xyz = texture(iChannel1,1.0-(uv - vec2(1.5,-1.0))/vec2(5.5,0.5)).xyz - vec3(0.35,0.2,0.2);
            mref = vec2(0.5,0.2);// transparent, glossines
            //mcol.xyz = vec3(0.3,0.7,0.9);// color
            
            if(id==21)	normal = -normal;
        }
        
        if(id>26 && id<34)//masa scaun
        {
            mcol.xyz = vec3(0.2);
            mref = vec2(0.5,0.7);// transparent, glossines
            //mcol.xyz = vec3(0.3,0.7,0.9);// color
            
            if(id==21)	normal = -normal;
        }
        
        if(id==34)//calorifer
        {
            mcol.xyz = vec3(sin(hit.x*59.0)+2.0-0.2);
            mref = vec2(0.0,0.0);
        }
    }  
}

vec3 directLight(vec3 hit, vec3 normal, vec3 lightf, vec3 cl, inout bool i)
{
   vec3 color = vec3(0.0);
   int id = -1;
   i = false;
   //vec3 toLight = (lightf-hit);
   //float sqdist = dot(toLight,toLight);
   vec3 L = normalize(lightf-hit);;//(toLight*rsqrt(sqdist);
   float diffuse = clamp(dot(normal,L),0.0,0.7)+0.3;
 
   if(diffuse>0.0)
   {
      float ldist =distance(lightf,hit);// sqrt(sqdist);
      float sh = 1000.0;//distance(lightf,hit);
      intersectscene(hit + normal * 0.0001, L, sh, id, false);           
      if(sh>ldist)
         {color += cl * (diffuse/(ldist))*0.32; i = true;}
   }
   return color;
}

vec3 getColor(vec3 ro, vec3 rd)
{
    vec3 color = vec3(0.0);
    vec3 col = vec3(1.0);
    int id=-1;
    int tm = -1;
    
    for(int i=0; i<4; i++)
    {
    	float t = 10000.0; //seed++;
		
   		vec2 tRoom = intersectCube(ro, rd, box0);          
   		if(tRoom.x < tRoom.y)   t = tRoom.y; 
    
    	intersectscene(ro, rd, t, id, true);
    
    	vec3 hit = ro + rd * t;        
		vec4 mcol = vec4(vec3(0.99),0.0);
    	vec3 normal; 
    	vec2 mref = vec2(0);
      
    	ColorAndNormal(hit, mcol, normal, tRoom, mref, t, id);
    	hit = hit + normal * 0.00001;
         
        vec2 rnd = rand2();
        //rnd.x = 1.0/6.0 * ( float(i) + rnd.x );
        col *= mcol.xyz;
        if(mcol.w>0.0) 
        {
            if(i==0) {color = mcol.xyz; break;}
            float df=max(dot(rd,-normal),0.0)*2.0; //if(tm==1) df *= 19.0;
            color += col*mcol.xyz*mcol.w * df ;
            //if(tm==1) color += col * 1.5;
            break;
        }
		tm = -1;
        if(rnd.x>abs(mref.x))//diffuse
        {
        	rd = CosineWeightedSampleHemisphere ( normal, rnd);      
        	tm = 0;   
        
        	col *= clamp(dot(normal,rd),0.0,1.0)*0.62;
            color += col*.1;
            
            bool isLight = false;
         	//vec3 rnd3 = vec3(rand2(),rand2().x) *2.0 -1.0;
            rnd = rand2()*2.0-1.0;
         	vec3 lightf = vec3(-0.4,0.1,2.2) + vec3(rnd.x*0.65,rnd.y * 0.6,0.0);
         	vec3 dl = directLight(hit, normal, lightf, vec3(0.9,0.9,0.9), isLight);
            float nd = max(0.0,dot(lightf,vec3(0.0,0.0,1.0)))+max(0.0,dot(lightf,normal));
         	color += col * dl*5.0 *nd;
         	if(isLight) break;
        }       
        else 
        {
            vec3 nrd = reflect(rd,normal); tm = 1;//reflect
       		/*if(mref.x<0.0)//refract
            {
                //if(id==30)
                    //if(dot(rd,normal)>0.0) normal = -normal;
            	vec3 ior=vec3(1.0,1.52,1.0/1.12); tm = 2;
           	 	vec3 refr=refract(rd,normal,(side>=0.0)?ior.z:ior.y);//calc the probabilty of reflecting instead
           	 	vec2 ca=vec2(dot(normal,rd),dot(normal,refr)),n=(side>=0.0)?ior.xy:ior.yx,nn=vec2(n.x,-n.y);
            	if(rand2().y>0.5*(pow(dot(nn,ca)/dot(n,ca),2.0)+pow(dot(nn,ca.yx)/dot(n,ca.yx),2.0)))
               		nrd=refr;
            }*/
            rd = cosPowDir(nrd, mref.y*1.0);
            col *= 1.2;
        }
        
        ro = hit + rd * 0.0001; 
        
        if(dot(col,col) < 0.1 && i>3) break;
    }
    
 	return color;   
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    p = -1.0+2.0*fragCoord.xy/iResolution.xy;
	p.x *= iResolution.x/iResolution.y;
    vec2 mo = iMouse.xy/iResolution.xy;
		 
	float time = 15.0 + iTime;
    float seed = iTime + iResolution.y *(p.x+1.0) + p.y;
	
	randv2=fract(cos((fragCoord.xy+fragCoord.yx*vec2(1000.0,1000.0))+vec2(iTime))*10000.0);
	
    //move camera with mouse
	vec3 ro = vec3( 3.0*cos(8.0*mo.x), -0.9 + 2.5*(mo.y), 0.0 + 3.0*sin(8.0*mo.x) );
	vec3 ta = vec3( 0.0, 0.0, 0.0 );
	
    //camera path
    time = 0.2 * iTime;
    vec3 path = vec3(sin(time*0.5)*2.0, sin(time)*0.7, cos(time*0.5)*2.0);    
    //ro = path; ta = path + vec3(-sin(time*0.5)*0.5+0.0, -cos(time)*0.2, -cos(time*0.5)*0.5+0.0);
    
    //view of raymarch
    //ro = vec3(-0.4,-0.8, 1.0); ta = vec3(-0.4,-0.8, 1.5);
	// camera tx
	vec3 cw = normalize( ta-ro );
	vec3 cp = vec3( 0.0, 1.0, 0.0 );
	vec3 cu = normalize( cross(cw,cp) );
	vec3 cv = normalize( cross(cu,cw) );
	vec3 rd = normalize( p.x*cu + p.y*cv + 2.5*cw );
    
    initscene();
	
	vec3 col = vec3(0.0);

    for(float i=0.0; i<t; i++)
    {
        p += (rand2() * 2.0 - 1.0) * 0.7 / iResolution.x;
        rd = normalize( p.x*cu + p.y*cv + 2.5*cw );
    	col += getColor( ro, rd );
    }

    col = pow( clamp( col/t, 0.0, 1.0 ), vec3(0.65) );
    //col.g += tc;
    fragColor=vec4( col, 1.0 );
}