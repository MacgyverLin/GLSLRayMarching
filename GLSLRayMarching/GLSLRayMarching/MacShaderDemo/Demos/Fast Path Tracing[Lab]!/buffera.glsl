/*
	"Fast PathTracing[Lab]!" by 834144373(恬纳微晰)
	This shader url : https://www.shadertoy.com/view/XdVfRm
	Licence: CC3.0 署名（BY）-非商业性使用（NC）-相同方式共享（SA）
	Also 834144373 is 恬纳微晰 or TNWX or 祝元洪
*/
/*
--------------------Main Reference Knowledge-------------------
MIS: [0]https://graphics.stanford.edu/courses/cs348b-03/papers/veach-chapter9.pdf
     [1]https://hal.inria.fr/hal-00942452v1/document
     [2]Importance Sampling Microfacet-Based BSDFs using the Distribution of Visible Normals. Eric Heitz, Eugene D’Eon
     [3]Understanding the Masking-Shadowing Function in Microfacet-Based BRDFs. Eric Heitz
     [4]Microfacet Models for Refraction through Rough Surfaces. Bruce Walter, Stephen R. Marschner, Hongsong Li, Kenneth E. Torrance
	Note: More details about theory and math you can easy find on "Common" shader.
*/
#define GI_DEPTH 3

/*Scene Objects*/
#define N_SPHERES 3
#define N_ELLIPSOIDS 1
#define N_OPENCYLINDERS 1
#define N_CONES 1
#define N_DISKS 1
#define N_QUADS 1
#define N_BOXES 1

/*Type*/
#define LIGHT 0
#define DIFF 1
#define REFR 2
#define SPEC 3
#define CHECK 4
#define COAT 5
#define VOLUME 6
#define TRANSLUCENT 7
#define SPECSUB 8
#define WATER 9
#define WOOD 10
#define SEAFLOOR 11
#define TERRAIN 12
#define CLOTH 13
#define LIGHTWOOD 14
#define DARKWOOD 15
#define PAINTING 16

const vec3 BACKGROUD_COL = vec3(0.,0.,0.);

const vec3 ZERO = vec3(0.,0.,0.);
const vec3 ONE  = vec3(1.,1.,1.);
const vec3 UP   = vec3(0.,1.,0.);
//const vec3 FORWORD = vec3(0.,0.,1.);
//const vec3 RIGHT   = vec3(1.,0.,0.);

struct Ray { vec3 origin; vec3 direction; };
struct Sphere { float radius; vec3 position; vec3 emission; vec3 color; float roughness; int type; };
struct Ellipsoid { vec3 shape; vec3 position; vec3 emission; vec3 color; float roughness; int type; };
struct OpenCylinder { float radius; vec3 pos1; vec3 pos2; vec3 emission; vec3 color; float roughness; int type; };
struct Cone { vec3 pos0; float radius0; vec3 pos1; float radius1; vec3 emission; vec3 color; float roughness; int type; };
struct Disk { float radiusSq; vec3 pos; vec3 normal; vec3 emission; vec3 color; float roughness; int type; };
struct Quad { vec3 normal; vec3 v0; vec3 v1; vec3 v2; vec3 v3; vec3 emission; vec3 color; float roughness; int type; };
struct Box { vec3 minCorner; vec3 maxCorner; vec3 emission; vec3 color; float roughness; int type; };
struct Intersection {float distance;vec2 uv; vec3 normal; vec3 emission; vec3 color; float roughness; int type; };

struct Light{float radius;vec3 direction;vec3 emission;float radiance;float pdf;int type;};
struct Material{float id;vec2 uv;vec3 normal;vec3 specular;vec3 diffuse;float roughness;int type;}; 
    
Sphere spheres[N_SPHERES];
Ellipsoid ellipsoids[N_ELLIPSOIDS];
OpenCylinder openCylinders[N_OPENCYLINDERS];
Cone cones[N_CONES];
Disk disks[N_DISKS];
Quad quads[N_QUADS];
Box boxes[N_BOXES];
    
bool solveQuadratic(float A, float B, float C, out float t0, out float t1){
	float discrim = B*B-4.0*A*C;
    
	if ( discrim < 0.0 )
        	return false;
    
	float rootDiscrim = sqrt(discrim);

	float Q = (B > 0.0) ? -0.5 * (B + rootDiscrim) : -0.5 * (B - rootDiscrim); 
	float t_0 = Q / A; 
	float t_1 = C / Q;
	
	t0 = min( t_0, t_1 );
	t1 = max( t_0, t_1 );
    
	return true;
}
float SphereIntersect( float rad, vec3 pos, Ray ray ){
	float t = INFINITY;
	float t0, t1;
	vec3 L = ray.origin - pos;
	float a = dot( ray.direction, ray.direction );
	float b = 2.0 * dot( ray.direction, L );
	float c = dot( L, L ) - (rad * rad);
	if (!solveQuadratic( a, b, c, t0, t1))
		return INFINITY;
	if ( t1 > 0.0 )
		t = t1;
	if ( t0 >= 0.0 )
		t = t0;
	return t;
}
float EllipsoidIntersect( vec3 radii, vec3 pos, Ray r ){
	float t = INFINITY;
	float t0, t1;
	vec3 oc = r.origin - pos;
	vec3 oc2 = oc*oc;
	vec3 ocrd = oc*r.direction;
	vec3 rd2 = r.direction*r.direction;
	vec3 invRad = 1.0/radii;
	vec3 invRad2 = invRad*invRad;
	
	// quadratic equation coefficients
	float a = dot(rd2, invRad2);
	float b = 2.0*dot(ocrd, invRad2);
	float c = dot(oc2, invRad2) - 1.0;

	if (!solveQuadratic( a, b, c, t0, t1))
		return INFINITY;
	
	if ( t1 > 0.0 )
		t = t1;
		
	if ( t0 > 0.0 )
		t = t0;
	
	return t;
}
float OpenCylinderIntersect( vec3 p0, vec3 p1, float rad, Ray r, out vec3 n ){
	float r2=rad*rad;
	
	vec3 dp=p1-p0;
	vec3 dpt=dp/dot(dp,dp);
	
	vec3 ao=r.origin-p0;
	vec3 aoxab=cross(ao,dpt);
	vec3 vxab=cross(r.direction,dpt);
	float ab2=dot(dpt,dpt);
	float a=2.0*dot(vxab,vxab);
	float ra=1.0/a;
	float b=2.0*dot(vxab,aoxab);
	float c=dot(aoxab,aoxab)-r2*ab2;
	
	float det=b*b-2.0*a*c;
	
	if(det<0.0)
	return INFINITY;
	
	det=sqrt(det);
	
	float t = INFINITY;
	
	float t0=(-b-det)*ra;
	float t1=(-b+det)*ra;
	
	vec3 ip;
	vec3 lp;
	float ct;
	if (t1 > 0.0)
	{
		ip=r.origin+r.direction*t1;
		lp=ip-p0;
		ct=dot(lp,dpt);
		if((ct>0.0)&&(ct<1.0))
		{
			t = t1;
		     	n=(p0+dp*ct)-ip;
		}
		
	}
	if (t0 > 0.0)
	{
		ip=r.origin+r.direction*t0;
		lp=ip-p0;
		ct=dot(lp,dpt);
		if((ct>0.0)&&(ct<1.0))
		{
			t = t0;
			n=ip-(p0+dp*ct);
		}
		
	}
	return t;
}
float ConeIntersect( vec3 p0, float r0, vec3 p1, float r1, Ray r, out vec3 n ){
	r0 += 0.1;
	float t = INFINITY;
	vec3 locX;
	vec3 locY;
	vec3 locZ=-(p1-p0)/(1.0 - r1/r0);
	
	Ray ray = r;
	ray.origin-=p0-locZ;
	
	if(abs(locZ.x)<abs(locZ.y))
		locX=vec3(1,0,0);
	else
		locX=vec3(0,1,0);
		
	float len=length(locZ);
	locZ=normalize(locZ)/len;
	locY=normalize(cross(locX,locZ))/r0;
	locX=normalize(cross(locY,locZ))/r0;
	
	mat3 tm;
	tm[0]=locX;
	tm[1]=locY;
	tm[2]=locZ;
	
	ray.direction*=tm;
	ray.origin*=tm;
	
	float dx=ray.direction.x;
	float dy=ray.direction.y;
	float dz=ray.direction.z;
	
	float x0=ray.origin.x;
	float y0=ray.origin.y;
	float z0=ray.origin.z;
	
	float x02=x0*x0;
	float y02=y0*y0;
	float z02=z0*z0;
	
	float dx2=dx*dx;
	float dy2=dy*dy;
	float dz2=dz*dz;
	
	float det=(
		-2.0*x0*dx*z0*dz
		+2.0*x0*dx*y0*dy
		-2.0*z0*dz*y0*dy
		+dz2*x02
		+dz2*y02
		+dx2*z02
		+dy2*z02
		-dy2*x02
		-dx2*y02
        );
	
	if(det<0.0)
		return INFINITY;
		
	float t0=(-x0*dx+z0*dz-y0*dy-sqrt(abs(det)))/(dx2-dz2+dy2);
	float t1=(-x0*dx+z0*dz-y0*dy+sqrt(abs(det)))/(dx2-dz2+dy2);
	vec3 pt0=ray.origin+t0*ray.direction;
	vec3 pt1=ray.origin+t1*ray.direction;
	
	if(t1>0.0 && pt1.z>r1/r0 && pt1.z<1.0)
	{
		t=t1;
		n=pt1;
		n.z=0.0;
		n=normalize(n);
		n.z=-pt1.z/abs(pt1.z);
		n=normalize(n);
		n=tm*-n;
	}
	
	if(t0>0.0 && pt0.z>r1/r0 && pt0.z<1.0)
	{
		t=t0;
		n=pt0;
		n.z=0.0;
		n=normalize(n);
		n.z=-pt0.z/abs(pt0.z);
		n=normalize(n);
		n=tm*n;
	}
	return t;	
}
float DiskIntersect( vec3 diskPos, vec3 normal, float radius, Ray r ){
	vec3 n = normalize(-normal);
	vec3 pOrO = diskPos - r.origin;
	float denom = dot(n, r.direction);
	// use the following for one-sided disk
	//if (denom <= 0.0)
	//	return INFINITY;
	
        float result = dot(pOrO, n) / denom;
	if (result < 0.0)
		return INFINITY;
        vec3 intersectPos = r.origin + r.direction * result;
	vec3 v = intersectPos - diskPos;
	float d2 = dot(v,v);
	float radiusSq = radius * radius;
	if (d2 > radiusSq)
		return INFINITY;
	return result;
}
float QuadIntersect( vec3 v0, vec3 v1, vec3 v2, vec3 v3, vec3 normal, Ray r ){
	vec3 u, v, n;    // triangle vectors
	vec3 w0, w, x;   // ray and intersection vectors
	float rt, a, b;  // params to calc ray-plane intersect
	
	// get first triangle edge vectors and plane normal
	v = v2 - v0;
	u = v1 - v0; // switched u and v names to save calculation later below
	//n = cross(v, u); // switched u and v names to save calculation later below
	n = -normal; // can avoid cross product if normal is already known
	    
	w0 = r.origin - v0;
	a = -dot(n,w0);
	b = dot(n, r.direction);
	if (b < 0.0001)   // ray is parallel to quad plane
		return INFINITY;

	// get intersect point of ray with quad plane
	rt = a / b;
	if (rt < 0.0)          // ray goes away from quad
		return INFINITY;   // => no intersect
	    
	x = r.origin + rt * r.direction; // intersect point of ray and plane

	// is x inside first Triangle?
	float uu, uv, vv, wu, wv, D;
	uu = dot(u,u);
	uv = dot(u,v);
	vv = dot(v,v);
	w = x - v0;
	wu = dot(w,u);
	wv = dot(w,v);
	D = 1.0 / (uv * uv - uu * vv);

	// get and test parametric coords
	float s, t;
	s = (uv * wv - vv * wu) * D;
	if (s >= 0.0 && s <= 1.0)
	{
		t = (uv * wu - uu * wv) * D;
		if (t >= 0.0 && (s + t) <= 1.0)
		{
			return rt;
		}
	}
	
	// is x inside second Triangle?
	u = v3 - v0;
	///v = v2 - v0;  //optimization - already calculated above

	uu = dot(u,u);
	uv = dot(u,v);
	///vv = dot(v,v);//optimization - already calculated above
	///w = x - v0;   //optimization - already calculated above
	wu = dot(w,u);
	///wv = dot(w,v);//optimization - already calculated above
	D = 1.0 / (uv * uv - uu * vv);

	// get and test parametric coords
	s = (uv * wv - vv * wu) * D;
	if (s >= 0.0 && s <= 1.0)
	{
		t = (uv * wu - uu * wv) * D;
		if (t >= 0.0 && (s + t) <= 1.0)
		{
			return rt;
		}
	}


	return INFINITY;
}
float BoxIntersect( vec3 minCorner, vec3 maxCorner, Ray r, out vec3 normal ){
	vec3 invDir = 1.0 / r.direction;
	vec3 tmin = (minCorner - r.origin) * invDir;
	vec3 tmax = (maxCorner - r.origin) * invDir;
	
	vec3 real_min = min(tmin, tmax);
	vec3 real_max = max(tmin, tmax);
	
	float minmax = min( min(real_max.x, real_max.y), real_max.z);
	float maxmin = max( max(real_min.x, real_min.y), real_min.z);
	
	if (minmax > maxmin)
	{
		
		if (maxmin > 0.0) // if we are outside the box
		{
			normal = -sign(r.direction) * step(real_min.yzx, real_min) * step(real_min.zxy, real_min);
			return maxmin;	
		}
		
		else if (minmax > 0.0) // else if we are inside the box
		{
			normal = -sign(r.direction) * step(real_max, real_max.yzx) * step(real_max, real_max.zxy);
			return minmax;
		}
				
	}
	
	return INFINITY;
}

// I = ΔΦ/4π
const vec3 LIGHTCOLOR = vec3(0.8,0.8,0.3);
vec3 GetLightIntensity(){
	return 50.* LIGHTCOLOR;
}

float SceneIntersect( Ray r, inout Intersection intersec ){
    float d = INFINITY;	
    float t = 0.;
    vec3 normal = vec3(0.);
    for(int i=0;i<spheres.length();i++){
        t = SphereIntersect(spheres[i].radius,spheres[i].position,r);
        if (t < d){
            d = t;
            intersec.normal = normalize((r.origin + r.direction * t) - spheres[i].position);
            intersec.emission = spheres[i].emission;
            intersec.color = spheres[i].color;
            intersec.roughness = spheres[i].roughness;
            intersec.type = spheres[i].type;
		}
    }
    /*
    for(int i=0;i<ellipsoids.length();i++){
    	t = EllipsoidIntersect(ellipsoids[i].shape,ellipsoids[i].position,r);
        if (t < d){
        	d = t;
            intersec.normal = normalize((r.origin + r.direction * t - ellipsoids[i].position)/(ellipsoids[i].shape*ellipsoids[i].shape));
            intersec.emission = ellipsoids[i].emission;
            intersec.color = ellipsoids[i].color;
            intersec.roughness = ellipsoids[i].roughness;
            intersec.type = ellipsoids[i].type;
        }
    }
    for(int i=0;i<openCylinders.length();i++){
    	t = OpenCylinderIntersect(openCylinders[i].pos1, openCylinders[i].pos2, openCylinders[i].radius, r, normal);
        if (t < d){
        	d = t;
            intersec.normal = normalize(normal);
            intersec.emission = openCylinders[i].emission;
            intersec.color = openCylinders[i].color;
            intersec.roughness = openCylinders[i].roughness;
            intersec.type = openCylinders[i].type;
        }
    }
	*/
    /*
    for(int i=0;i<cones.length();i++){
    	t = ConeIntersect(cones[i].pos0, cones[i].radius0,cones[i].pos1,cones[i].radius1, r, normal);
        //t = OpenCylinderIntersect(openCylinders[i].pos1, openCylinders[i].pos2, openCylinders[i].radius, r, normal);
        if (t < d){
            d = t;
            intersec.normal = normalize(normal);
            intersec.emission = cones[i].emission;
            intersec.color = cones[i].color;
            intersec.roughness = cones[i].roughness;
            intersec.type = cones[i].type;
        }
    }
	*/
	/*
    for(int i=0;i<disks.length();i++){
    	t = DiskIntersect( disks[i].pos, disks[i].normal, disks[i].radiusSq, r );
        if (t < d){
        	d = t;
            intersec.normal = normalize(disks[i].normal);
            intersec.emission = disks[i].emission;
            intersec.color = disks[i].color;
            intersec.roughness = disks[i].roughness;
            intersec.type = disks[i].type;
        }
    }
	*/
    
    for(int i=0;i<quads.length();i++){
        t = QuadIntersect( quads[i].v0, quads[i].v1, quads[i].v2, quads[i].v3, quads[i].normal, r );
        if (t < d){
        	d = t;
            intersec.normal = normalize(quads[i].normal);
            intersec.emission = quads[i].emission;
            intersec.color = quads[i].color;
            intersec.roughness = quads[i].roughness;
            intersec.type = quads[i].type;
        }
    }
	
    for(int i=0;i<boxes.length();i++){
    	t = BoxIntersect(boxes[0].minCorner,boxes[0].maxCorner,r,normal);
        if(t < d){
        	d = t;
            intersec.normal = normalize(normal);
            intersec.emission = boxes[i].emission;
            intersec.color = boxes[i].color;
            intersec.roughness = boxes[i].roughness;
            intersec.type = boxes[i].type;
        }
    }
    intersec.distance = d;
    return d;
}
void SetupScene(){
	spheres[0] = Sphere( 0.2, vec3(-0.1 , 0., 0.), vec3(0.), vec3(0.3,1. ,0.  ), 0.7, SPEC);
	spheres[1] = Sphere( 0.23, vec3(0.2, 0.1, 0.), vec3(0.), vec3(1.,0.,0.05), 0.4, SPEC);
   	spheres[2] = Sphere( 0.4, vec3(0.2, 0.4,0.3),vec3(1.,0.8,0.8),vec3(1.,0.,0.4), 0.05, SPEC);
    ellipsoids[0] = Ellipsoid(vec3(1.,2.,1.),vec3(-1.,0.,1.5),vec3(0.2),vec3(0.,0.8,0.5),0.4,SPEC);
	openCylinders[0] = OpenCylinder(0.3,vec3(0.,0.2,0.),vec3(0.,0.,0.),vec3(0.2),vec3(0.,0.6,0.9),0.4,SPEC);
	cones[0] = Cone(vec3(1.,1.,0.),0.5,vec3(5.,1.,0.), 1., vec3(0.5),vec3(1.,1.,0.),0.4,SPEC);
    disks[0] = Disk(1.0, vec3(0.,2.,0.), vec3(0.,1.,0.), vec3(0.7,0.8,0.7), vec3(0.2,0.3,0.4), 0.2, LIGHT);
    quads[0] = Quad(vec3(0.,0.,1.),vec3(-0.5,0.,-1.), vec3(0.5,0.,-1.), vec3(0.5 ,0.55 ,-1. ), vec3(-0.5,0.55,-1.), vec3(0.6,0.6,0.6), vec3(0.4,0.5,0.6),0.4, LIGHT);
    boxes[0] =  Box(vec3(-0.7,-0.3,-0.7),vec3(0.7,0.0,0.7), vec3(0.,0.,0.), vec3(0.,0.2,0.1), 0.1, DIFF);
}
#define time iTime*0.1
mat3 CameraCoordBase(vec3 campos,vec3 lookAt,vec3 up){
	vec3 LookForward = normalize(lookAt - campos);
    vec3 BaseRight = normalize(cross(LookForward,up));
    vec3 BaseUp    = normalize(cross(BaseRight,LookForward));
    mat3 mat = mat3(BaseRight,BaseUp,LookForward);
	return mat;
}

Material GetMaterial(Intersection _intersec){
	Material mat;
    mat.type = _intersec.type;
    mat.uv = _intersec.uv;
    mat.normal = _intersec.normal;
    mat.diffuse = _intersec.color;
    mat.specular = LIGHTCOLOR;
    mat.roughness = _intersec.roughness;
    return mat;
}

float isSameHemishere(float cosA,float cosB){
	return cosA*cosB;
} 
//pdf area to solid angle
float PDF_Area2Angle(float pdf,float dist,float costhe){
	return pdf*dist*dist/costhe;
}
//vec3 v0; vec3 v1; vec3 v2; vec3 v3
//     A		B         C        D
/*  v3------v2
	|	 O	 |
	v0------v1
*/
vec3 LightSample(vec3 p,float x1,float x2,out vec3 wo,out float dist,out float pdf){
	vec3 v0v1 = quads[0].v1 - quads[0].v0;
    vec3 v0v3 = quads[0].v3 - quads[0].v0;
    float width  = length(v0v1);
    float height = length(v0v3);
    vec3 O = quads[0].v0 + v0v1*x1 + v0v3*x2;
    wo = O - p;
    dist = length(wo);
    wo = normalize(wo);
    float costhe = dot(-wo,quads[0].normal);
    pdf = PDF_Area2Angle(1./(width*height),dist,clamp(costhe,0.0001,1.));
    return costhe>0. ? GetLightIntensity(): vec3(0.);
}
vec3 MicroFactEvalution(Material mat,vec3 nDir,vec3 wo,vec3 wi){
	mat3 nDirSpace = CoordBase(nDir);
    //light dir
    vec3 L_local = ToOtherSpaceCoord(nDirSpace,wo);
    //eye dir
    vec3 E_local = ToOtherSpaceCoord(nDirSpace,wi);
    if(isSameHemishere(L_local.z,E_local.z) < 0.){
    	return ZERO;
    }
    if(any(equal(vec2(L_local.z,E_local.z),ZERO.xy))){
    	return ZERO;
    }
    float alpha = mat.roughness;
    vec3 H_local = normalize(L_local + E_local);
    float D = GGX_Distribution(H_local, alpha, alpha);
    float F = F_Schlick(F0_ALUMINIUM, L_local,H_local);
    float G = GGX_G2(L_local, E_local, alpha, alpha);
    vec3 specular_Col = mat.specular*0.25*D*G/clamp(L_local.z*E_local.z,0.,1.);
    vec3 diffuse_Col = mat.diffuse*INVERSE_PI;
    return mix(specular_Col,diffuse_Col,F);
}
float EnergyAbsorptionTerm(float roughness,vec3 wo){
	return mix(1.-roughness*roughness,sinTheta(wo),roughness);
}
//F function
vec3 LightingDirectSample(Material mat,vec3 p,vec3 nDir,vec3 vDir,out float pdf){
	vec3 L = vec3(0.,0.,0.);
    float x1 = GetRandom(),x2 = GetRandom();
    vec3 wo;
    float dist;
    vec3 Li = LightSample(p,x1,x2,wo,dist,pdf);
    float WoDotN = dot(wo,nDir);
    if(WoDotN >= 0. && pdf > 0.0001){
        vec3 Lr = MicroFactEvalution(mat,nDir,wo,vDir);
        Ray shadowRay = Ray(p,wo);
        Intersection shadow_intersc;
        float d = SceneIntersect(shadowRay,shadow_intersc);
        if(shadow_intersc.type == LIGHT){
            L = Lr*Li/pdf;
        }
    }
    return L;
}
//G function 
vec3 LightingBRDFSample(Material mat,vec3 p,vec3 nDir,vec3 vDir,inout float _pathWeight,inout Intersection _intersec,inout Ray ray,out float pdf){
	vec3 L = vec3(0.);
    float x1 = GetRandom(),x2 = GetRandom();
    mat3 nDirSpace = CoordBase(nDir);
    //light dir
    vec3 L_local;
    //eye dir
    vec3 E_local = ToOtherSpaceCoord(nDirSpace,vDir);
    float alpha = mat.roughness;
    if(E_local.z <= 0.)
        return ZERO;
    vec3 N_local = sampleGGXVNDF(E_local,alpha,alpha,x1,x2);
    N_local *= sign(E_local.z * N_local.z);

    float part_pdf = 0.5;
    float path_pdf = 0.;
    if(GetRandom() < part_pdf){
        //diffuse ray
        L_local = DiffuseUnitSpehreRay(x1,x2);
        path_pdf = Diffuse_PDF(L_local);
    }
    else{
        //specular ray
        L_local = reflect(-E_local, N_local);
        path_pdf = Specular_PDF(E_local,N_local,alpha,alpha);
    }
    
    vec3 wo = RotVector(nDirSpace,L_local); //to world coord base
    vec3 Lr = MicroFactEvalution(mat,nDir,wo,vDir);
    Ray shadowRay = Ray(p,wo);
    float d = SceneIntersect(shadowRay,_intersec);
    ray = Ray(p,wo);
    if(path_pdf > 0.0001){
        if(_intersec.type == LIGHT && cosTheta(L_local)>0.){
            L = GetLightIntensity()/(d*d)*Lr*dot(wo,nDir)/part_pdf;
        }
        L /=path_pdf;
    }
    pdf = path_pdf;
	//我们要简单得考虑物体对 能量 得损失(we should simple think about energy absorption)
    _pathWeight *= EnergyAbsorptionTerm(alpha,L_local);
    return L;
}
vec3 Randiance(Ray ray,float x1){
	float t = INFINITY;
    Intersection intersecNow;
    Intersection intersecNext;
    vec3 col = vec3(0.,0.5,0.);
    vec3 Lo = vec3(0.,0.,0.);
    float pathWeight = 1.;
    if(SceneIntersect(ray,intersecNow)>=INFINITY)
    	return BACKGROUD_COL;
    //显示光源
    if(intersecNow.type == LIGHT){
        Lo = GetLightIntensity();
        return Lo;
    }
	//计算GI光照
    for(int step=0;step<GI_DEPTH;step++){
		if(intersecNow.type == LIGHT)
            break;
   		vec3 viewDir = -ray.direction;
        vec3 nDir = intersecNow.normal;
        nDir = faceforward(nDir,-viewDir,nDir);
        Material mat = GetMaterial(intersecNow);
        if(dot(viewDir,nDir)<0.)
            break;
		//物体表面
        vec3 point = ray.origin + ray.direction * intersecNow.distance +nDir*0.00001;
        float Light_pdf,BRDF_pdf;
       	vec3 LIGHT_S = LightingDirectSample(mat,point,nDir,viewDir,Light_pdf);
        vec3 BRDF_S = LightingBRDFSample(mat,point,nDir,viewDir,pathWeight,intersecNext,ray,BRDF_pdf);
        Lo += LIGHT_S*MISWeight(1.,Light_pdf,1.,BRDF_pdf)
           +  BRDF_S*MISWeight(1.,BRDF_pdf,1.,Light_pdf);
        Lo *= pathWeight;
		intersecNow = intersecNext;
    }
    return Lo/float(GI_DEPTH);
}
#define R iResolution.xy
const vec2 FRAME_START_UV = vec2(0.,0.);
vec4 readValues(vec2 xy){
	return texture(iChannel0,(xy+0.5)/R);
}
void mainImage( out vec4 C, in vec2 U ){
	vec2 iU = U - 0.5;
    /*
		My new enhanced method noise seed.(test)
	*/
    seed = iTime*sin(iTime) + (U.x+R.x*U.y)/(R.y);
    
    vec2 uv = (U+U-R)/R.y;
    vec2 mousePos = readValues(FRAME_START_UV).yz/R*10.;
    if(iFrame == 0){
         mousePos = R/vec2(3.,4.);
	}
    vec3 pos = vec3(cos(mousePos.x),mousePos.y/2.-0.5,sin(mousePos.x));
    	 pos.xz *= 1.5;
    vec3 dir = normalize(vec3(uv,2.3));
	dir = RotVector(CameraCoordBase(pos,vec3(0.,0.05,0.),vec3(0.,1.,0.)),dir);
    dir = normalize(dir);
    SetupScene();
    
    mat3 cameraSpace = CoordBase(normalize(pos-vec3(0.,0.05,0.)));
    vec2 dither = TriangularNoise2DShereRay(uv,iTime);
    pos += (RotVector(cameraSpace,vec3(dither,0.)))*0.004;
    Ray ray = Ray(pos,dir);
    vec3 col = Randiance(ray,GetRandom());
    if(all(equal(iU,FRAME_START_UV))){
        if(iFrame == 0){
            C = vec4(1.,R/vec2(3.,4.),0.);
        }
        else{
            if(iMouse.z > 1.){
                C = vec4(1.,iMouse.xy,0.);
            }
            else{
                C = readValues(FRAME_START_UV);
                ++C.r;
            }
        }
    }
    else{
        if(iFrame == 0){
        	C = vec4(col.rgb,0.);
        	//with krax suggestion awoid NaN
            C = clamp(C, 0., 10.);
        }
        else{
            vec4 Frame_data = readValues(FRAME_START_UV);
            C = texture(iChannel0,U/R);
            //float N = col.r + col.g + col.b;
            //with krax suggestion awoid NaN
            col = clamp(col, 0., 10.);
            //if(!(N<0.))
            C = mix(C,vec4(col,1.),1./Frame_data.r);
        }
    }

}