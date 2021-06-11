//used macros and constants
#define PI 					3.1415926
#define TWO_PI 				6.2831852
#define FOUR_PI 			12.566370
#define INV_PI 				0.3183099
#define INV_TWO_PI 			0.1591549
#define INV_FOUR_PI 		0.0795775
#define EPSILON 			0.0001 
#define EQUAL_FLT(a,b,eps)	(((a)>((b)-(eps))) && ((a)<((b)+(eps))))
#define IS_ZERO(a) 			EQUAL_FLT(a,0.0,EPSILON)
//********************************************

struct Ray {
    vec3 origin;
    vec3 dir;
};
    
struct Camera {
    mat3 rotate;
    vec3 pos;
    float fovV;
    float lensSize;
    float focusDist;
    vec2 iPlaneSize;
};

struct SurfaceHitInfo {
    vec3 position_;
	vec3 normal_;
    vec3 tangent_;
    vec2 uv_;
    int mtl_id_;
};

//////////////////////////////////////////////////////////////////////////
// From smallVCM
// Converting PDF from Solid angle to Area
float PdfWtoA( float aPdfW, float aDist2, float aCosThere ){
    if( aDist2 < EPSILON )
        return 0.0;
    return aPdfW * abs(aCosThere) / aDist2;
}

// Converting PDF between from Area to Solid angle
float PdfAtoW( float aPdfA, float aDist2, float aCosThere ){
    float absCosTheta = abs(aCosThere);
    if( absCosTheta < EPSILON )
        return 0.0;
    
    return aPdfA * aDist2 / absCosTheta;
}

float misWeight( in float a, in float b ) {
    float a2 = a*a;
    float b2 = b*b;
    float a2b2 = a2 + b2;
    return a2 / a2b2;
}

// Geometry functions ***********************************************************
vec2 radialSampleDisk(in vec2 xi) {
    float r = sqrt(1.0 - xi.x);
    float theta = xi.y*TWO_PI;
	return vec2(cos(theta), sin(theta))*r;
}

//https://pdfs.semanticscholar.org/4322/6a3916a85025acbb3a58c17f6dc0756b35ac.pdf
//https://github.com/mmp/pbrt-v3/blob/9f717d847a807793fa966cf0eaa366852efef167/src/core/sampling.cpp#L113
vec2 concentricSampleDisk(in vec2 xi) {
    // Map uniform random numbers to $[-1,1]^2$
    vec2 uOffset = 2. * xi - vec2(1, 1);

    // Handle degeneracy at the origin
    if (uOffset.x == 0.0 && uOffset.y == 0.0) return vec2(.0);

    // Apply concentric mapping to point
    float theta, r;
    if (abs(uOffset.x) > abs(uOffset.y)) {
        r = uOffset.x;
        theta = (PI/4.0) * (uOffset.y / uOffset.x);
    } else {
        r = uOffset.y;
        theta = (PI/2.0) - (PI/4.0) * (uOffset.x / uOffset.y);
    }
    return r * vec2(cos(theta), sin(theta));
}

vec2 uniformPointWithinCircle( in float radius, in vec2 xi ) {
    vec2 p;
#ifdef CONCENTRIC_DISK
    p = concentricSampleDisk(xi);
#else
    p = radialSampleDisk(xi);
#endif
    p *= radius;
    return p;
}

vec3 uniformDirectionWithinCone( in vec3 d, in float phi, in float sina, in float cosa ) {    
	vec3 w = normalize(d);
    vec3 u = normalize(cross(w.yzx, w));
    vec3 v = cross(w, u);
	return (u*cos(phi) + v*sin(phi)) * sina + w * cosa;
}

//taken from: https://www.shadertoy.com/view/4sSSW3
void basis(in vec3 n, out vec3 f, out vec3 r) {
    if(n.z < -0.999999) {
        f = vec3(0 , -1, 0);
        r = vec3(-1, 0, 0);
    } else {
    	float a = 1./(1. + n.z);
    	float b = -n.x*n.y*a;
    	f = vec3(1. - n.x*n.x*a, b, -n.x);
    	r = vec3(b, 1. - n.y*n.y*a , -n.y);
    }
}

mat3 mat3FromNormal(in vec3 n) {
    vec3 x;
    vec3 y;
    basis(n, x, y);
    return mat3(x,y,n);
}

vec3 l2w( in vec3 localDir, in vec3 normal ) {
    vec3 a,b;
    basis( normal, a, b );
	return localDir.x*a + localDir.y*b + localDir.z*normal;
}

void cartesianToSpherical( 	in vec3 xyz,
                         	out float rho,
                          	out float phi,
                          	out float theta ) {
    rho = sqrt((xyz.x * xyz.x) + (xyz.y * xyz.y) + (xyz.z * xyz.z));
    phi = asin(xyz.y / rho);
	theta = atan( xyz.z, xyz.x );
}

vec3 sphericalToCartesian( in float rho, in float phi, in float theta ) {
    float sinTheta = sin(theta);
    return vec3( sinTheta*cos(phi), sinTheta*sin(phi), cos(theta) )*rho;
}

vec3 sampleHemisphereCosWeighted(in vec2 xi) {
#ifdef CONCENTRIC_DISK
    vec2 xy = concentricSampleDisk(xi);
    float r2 = xy.x*xy.x + xy.y*xy.y;
    return vec3(xy, sqrt(max(0.0, 1.0 - r2)));
#else
    float theta = acos(sqrt(1.0-xi.x));
    float phi = TWO_PI * xi.y;
    return sphericalToCartesian( 1.0, phi, theta );
#endif
}

vec3 sampleHemisphereCosWeighted( in vec3 n, in vec2 xi ) {
    return l2w( sampleHemisphereCosWeighted( xi ), n );
}

vec3 randomDirection( in float Xi1, in float Xi2 ) {
    float theta = acos(1.0 - 2.0*Xi1);
    float phi = TWO_PI * Xi2;
    
    return sphericalToCartesian( 1.0, phi, theta );
}

// ************************  INTERSECTION FUNCTIONS **************************
bool solveQuadratic(float A, float B, float C, out float t0, out float t1) {
	float discrim = B*B-4.0*A*C;
    
	if ( discrim <= 0.0 )
        return false;
    
	float rootDiscrim = sqrt( discrim );
    
    float t_0 = (-B-rootDiscrim)/(2.0*A);
    float t_1 = (-B+rootDiscrim)/(2.0*A);
    
    t0 = min( t_0, t_1 );
    t1 = max( t_0, t_1 );
    
	return true;
}

bool rayAABBIntersection( in Ray ray, vec3 boxMin, vec3 boxMax, in bool forShadowTest, out float t, out SurfaceHitInfo isect ) {
    vec3 OMIN = ( boxMin - ray.origin ) / ray.dir;
    vec3 OMAX = ( boxMax - ray.origin ) / ray.dir;
    vec3 MAX = max ( OMAX, OMIN );
    vec3 MIN = min ( OMAX, OMIN );
    float t1 = min ( MAX.x, min ( MAX.y, MAX.z ) );
    t = max ( max ( MIN.x, 0.0 ), max ( MIN.y, MIN.z ) );
    
    if ( t1 <= t )
        return false;
    
    if( !forShadowTest ) {
        isect.position_ = ray.origin + ray.dir*t;
        
        if( EQUAL_FLT( isect.position_.x, boxMin.x, EPSILON ) ) {
            isect.normal_ =  vec3( -1.0, 0.0, 0.0 );
            isect.tangent_ 		= vec3( 0.0, 1.0, 0.0 );
            isect.uv_ = (isect.position_.yz - boxMin.yz)/(boxMax.yz - boxMin.yz);
        } else if( EQUAL_FLT( isect.position_.x, boxMax.x, EPSILON ) ) {
            isect.normal_ =  vec3( 1.0, 0.0, 0.0 );
            isect.tangent_ = vec3( 0.0, 1.0, 0.0 );
            isect.uv_ = (isect.position_.yz - boxMin.yz)/(boxMax.yz - boxMin.yz);
        } else if( EQUAL_FLT( isect.position_.y, boxMin.y, EPSILON ) ) {
            isect.normal_ =  vec3( 0.0, -1.0, 0.0 );
            isect.tangent_ = vec3( 1.0, 0.0, 0.0 );
            isect.uv_ = (isect.position_.xz - boxMin.xz)/(boxMax.xz - boxMin.xz);
        } else if( EQUAL_FLT( isect.position_.y, boxMax.y, EPSILON ) ) {
            isect.normal_ =  vec3( 0.0, 1.0, 0.0 );
            isect.tangent_ = vec3( 1.0, 0.0, 0.0 );
            isect.uv_ = (isect.position_.xz - boxMin.xz)/(boxMax.xz - boxMin.xz);
        } else if( EQUAL_FLT( isect.position_.z, boxMin.z, EPSILON ) ) {
            isect.normal_ =  vec3( 0.0, 0.0, -1.0 );
            isect.tangent_ = vec3( 1.0, 0.0, 0.0 );
            isect.uv_ = (isect.position_.xy - boxMin.xy)/(boxMax.xy - boxMin.xy);
        } else if( EQUAL_FLT( isect.position_.z, boxMax.z, EPSILON ) ) {
            isect.normal_ =  vec3( 0.0, 0.0, 1.0 );
            isect.tangent_ = vec3( 1.0, 0.0, 0.0 );
            isect.uv_ = (isect.position_.xy - boxMin.xy)/(boxMax.xy - boxMin.xy);
        }
        
        isect.uv_ /= 2.0;
    }
    
    return true;
}

bool raySphereIntersection( in Ray ray, in float radiusSquared, in bool forShadowTest, out float t, out SurfaceHitInfo isect ) {
    float t0, t1;
    vec3 L = ray.origin;
    float a = dot( ray.dir, ray.dir );
    float b = 2.0 * dot( ray.dir, L );
    float c = dot( L, L ) - radiusSquared;
    
    if (!solveQuadratic( a, b, c, t0, t1))
		return false;
    
    if( t0 > 0.0 ) {
    	t = t0;
    } else {
        if ( t1 > 0.0 ) {
            t = t1;
        } else {
            return false;
        }
    }
    
    if( !forShadowTest ) {
        isect.position_ = ray.origin + ray.dir*t;
        isect.normal_ = normalize( isect.position_ );

        float rho, phi, theta;
        cartesianToSpherical( isect.normal_, rho, phi, theta );
        isect.uv_.x = phi/PI;
        isect.uv_.y = theta/TWO_PI;

        isect.tangent_ = vec3( 0.0, 1.0, 0.0 );
        vec3 tmp = cross( isect.normal_, isect.tangent_ );
        isect.tangent_ = normalize( cross( tmp, isect.normal_ ) );
    }
	
	return true;
}

bool rayAAPlaneIntersection( in Ray ray, in float min_x, in float min_y, in float max_x, in float max_y, in bool forShadowTest, out float t, out SurfaceHitInfo isect ) {
    if ( IS_ZERO( ray.dir.z ) )
    	return false;
    
    t = ( -ray.origin.z ) / ray.dir.z;
    
    isect.position_ = ray.origin + ray.dir*t;
    
    if( (isect.position_.x < min_x) ||
       	(isect.position_.x > max_x) ||
      	(isect.position_.y < min_y) ||
      	(isect.position_.y > max_y) )
        return false;
    
    if( !forShadowTest ) {
        isect.uv_.x 		= (isect.position_.x - min_x)/(max_x - min_x);
        isect.uv_.y 		= (isect.position_.y - min_y)/(max_y - min_y);
        isect.normal_ 		= vec3( 0.0, 0.0, 1.0 );
        isect.tangent_ 		= vec3( 1.0, 0.0, 0.0 );
    }
    
    return true;
}

bool rayDiskIntersection( in Ray ray, in float r2, in float R2, in bool forShadowTest, out float t, out SurfaceHitInfo isect ) {
    if ( IS_ZERO( ray.dir.z ) )
    	return false;
    
    t = ( -ray.origin.z ) / ray.dir.z;
    
    isect.position_ = ray.origin + ray.dir*t;
    
    float d2 = dot(isect.position_, isect.position_);
    
    if( d2 < r2 || d2 > R2 )
        return false;
    
    if( !forShadowTest ) {
        float R = sqrt(R2);
        isect.uv_.x 		= (isect.position_.x - R)/(2.0*R);
        isect.uv_.y 		= (isect.position_.y - R)/(2.0*R);
        isect.normal_ 		= vec3( 0.0, 0.0, 1.0 );
        isect.tangent_ 		= vec3( 1.0, 0.0, 0.0 );
    }
    
    return true;
}

bool rayCylinderIntersection( in Ray r, in float radius, in float minZ, in float maxZ, in float maxPhi, in bool forShadowTest, out float t, out SurfaceHitInfo isect ) {
	float phi;
	vec3 phit;
    
	// Compute quadratic cylinder coefficients
	float a = r.dir.x*r.dir.x + r.dir.y*r.dir.y;
	float b = 2.0 * (r.dir.x*r.origin.x + r.dir.y*r.origin.y);
	float c = r.origin.x*r.origin.x + r.origin.y*r.origin.y - radius*radius;
 
	// Solve quadratic equation for _t_ values
	float t0, t1;
	if (!solveQuadratic( a, b, c, t0, t1))
		return false;

    if ( t1 < 0.0 )
        return false;
    
	t = t0;
    
	if (t0 < 0.0)
		t = t1;

	// Compute cylinder hit point and $\phi$
	phit = r.origin + r.dir*t;
	phi = atan(phit.y,phit.x);
    phi += PI;
    
	if (phi < 0.0)
        phi += TWO_PI;
 
	// Test cylinder intersection against clipping parameters
	if ( (phit.z < minZ) || (phit.z > maxZ) || (phi > maxPhi) ) {
		if (t == t1)
            return false;
		t = t1;
		// Compute cylinder hit point and $\phi$
		phit = r.origin + r.dir*t;
		phi = atan(phit.y,phit.x);
        phi += PI;

		if ( (phit.z < minZ) || (phit.z > maxZ) || (phi > maxPhi) )
			return false;
	}
    
    if( !forShadowTest ) {
        isect.position_ = phit;
        isect.uv_.x = (phit.z - minZ)/(maxZ - minZ);
        isect.uv_.y = phi/maxPhi;
        isect.normal_ = normalize( vec3( phit.xy, 0.0 ) );
        isect.tangent_ = vec3( 0.0, 0.0, 1.0 );
    }
    
	return true;
}