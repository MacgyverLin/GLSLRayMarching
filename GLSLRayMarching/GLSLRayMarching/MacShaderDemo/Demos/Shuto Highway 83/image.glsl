// Shuto Highway 83 by Jerome Liard, April 2018
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
// https://www.shadertoy.com/view/XdyyDV
//
// An attempt at a city shader. Mouse to look around, 7 cameras, a bit more than a couple of minutes. 
// The roof top coffee break (?) camera has a special look down camera control when standing next to the roof border.
//
// June 2021 update:
// - Replaced the code by the original non preprocessed one.
// - Forced more loops (on 2 gradient evals) seems to have shortern shadertoy compilation by a couple seconds.
//
// I tried to go for a Japanese urban look with a mix of modern buildings and traditional tiled houses.
// Building arrangements within a grid cell use this https://www.shadertoy.com/view/4tXcRl (that's what they were designed for in the first place)
// But this time they are dda+raytraced instead of ray marched, which lifts limitation on height and perf constraints (no need to evaluate neighbors etc.).
//
// Tracing is a nested and composited dda/raytrace/raymarch hybrid;
//
//   1) raytrace ground infinite plane and highway drivable surface to reduce sdf melting on streets and highway vanishing point
//   2) 3d DDA trace a regular grid [traceBuildings()]
//      for each cell entered
//         partition the cell with a random split arrangements of 4 bounding boxes, 1 per building (or house)
//         raytrace all 4 bounding boxes (some calculations can be factorized, so it is not quite as bad as it sounds) [rayMarchCellObjects()]
//            when we hit a box, ray march a house or a building inside [rayMarchParametricBuilding()]
//            if there was a hit, calculate its normal and ray march for AO there
//   3) independently of DDA (except for occlusion early return), ray march highways, street lamps, z=0 ground, and march for AO there too (most of this is culled by buildings)
//   -> composite all the hits above as we go, early return everywhere we can etc. Note AO is not global (but it's ok enough)
//   4) trace the scene again for shadows (ouch) and lit
//
// Other:
//
//   - The sky probe function might be of interest to some (uncomment the test_sky() line to see).
//     It is a careful manual match of a reference hosek sky probe (see get_sky()) so that we don't have to do atmosphere calculations.
//     I used a radial gradient curve picking UI (make one in 30 minutes with your favorite imgui), 
//     and found that biexponentials are able to match the r,g,b sky gradients pretty well.
//   - The distance to curve algorithm (important for the highway and surrounding geom clip planes) might be of interest too, see evalHighway()
//   - Unhandled divide by zeros occasionally create buggy horizontal lines mid screen, sorry...
//   - I didn't want to rely on textures too much and was interested in volumetric detail, so it ended up flat-ish look overall
//   - Building windows use the old trick of tracing a ray past the window, assuming constant floor heights, and return an infinite neon plane on the ceiling. From outside, the infinite neon planes sometimes "leak" past real walls, we don't care
//   - If you look up there are airliners in the sky. 
//     Their silhouette is a pretty close match of and airbus as350 although in the final shader it's just some far away pixel vomit
//   - No AA so can be a bit flickery... sorry
//
/// -------------------------------------------------------- turn stuff on and off

/// trace building bounding boxes only
///#define DEBUG_BUILDINGS_BOUNDS

/// colorful debug showing the structure of the scene
///#define DEBUG_COLORING

#define HIGHWAY_CLIP
#define BUILDINGS
#define TILE_PERMUTATIONS
#define ROOF_OBJECTS
#define TRY_BALANCE_SIZES
#define OFFICE_NEON
#define WINDOWS_GROUND_REFLECTION
#define HIGHWAYS
#define WIDE_STREETS_LAMPS
#define HIGHWAY_LAMPS
#define LCD_PANELS
#define SHADOWS
#define AO
#define HORIZON_HACK

#define STICKY_MOUSE false

/// -------------------------------------------------------- perfs and shader crash raindances

/// this shader worked natively everywhere I tested, 
/// but webgl takes much longer to build and sometimes crashes, hitting seemingly random resource limits or timeouts
/// there has been cases where I had to force a loop to prevent driver crashes (even natively),
/// and there has been cases where where fiddling with for loops led to important perf variations
/// without ability to check the compiler output it is a bit of a raindance contest

/// try bend for loops to our will, this is from Fabrice's excellent page https://shadertoyunofficial.wordpress.com/
#define FORCE_LOOP +min(0,iFrame)

/// ----
/// top traceCity loop
#define FORCE_LOOP_LV0 FORCE_LOOP
///#define FORCE_LOOP_LV0
///#define UNROLL_LOOP0
/// ----
/// dda cell iteration loop
/// if not forcing loop here: compiler once crashed on GTX970 (not webgl), malloc fail
#define FORCE_LOOP_LV1 FORCE_LOOP
///#define FORCE_LOOP_LV1
/// ----
/// per dda cell iteration on 4 buildings
/// force loop was a little bit slower on radeon 5670 at some point in the past
#define FORCE_LOOP_LV2 FORCE_LOOP
///#define FORCE_LOOP_LV2
/// UNROLL_LOOP2: manual unroll (GTX970 got much slower at some point in the past)
///#define UNROLL_LOOP2
/// ----
/// sd_ParametricBuilding sdf ray march loop
#define FORCE_LOOP_LV3 FORCE_LOOP
///#define FORCE_LOOP_LV3
/// ----

/// ----
/// ao loop
#define FORCE_LOOP_AO FORCE_LOOP
///#define FORCE_LOOP_AO
/// ----

/// ----
/// sdf bits loop
#define FORCE_LOOP_S FORCE_LOOP
///#define FORCE_LOOP_S
/// ----

/// ----
/// airliners loop
#define FORCE_LOOP_B FORCE_LOOP
///#define FORCE_LOOP_B
/// ----

// those defines weren't in the first version of the shader 
// they cut a few seconds of compilation time on shadertoy
#define FORCE_GRAD_LOOP_BUILDING
#define FORCE_GRAD_LOOP_SCENE

// -------------------------------------------------------- lib stuff

#define PI 3.141592654
#define FLT_MAX /* FLT_MAX */1000000. 
#define SQR2 1.414213562

#define RED	vec3( 1, 0, 0 )
#define GREEN vec3( 0, 1, 0 )
#define BLUE vec3( 0, 0, 1 )
#define MAGENTA vec3( 1, 0, 1 )
#define BLEU_ARDOISE vec3( 0.32, 0.38, 0.47 )
#define GRIS_ARDOISE vec3( 0.35, 0.36, 0.41 )

vec3 zset( vec3 p, float v ) { return vec3( p.x, p.y, v );}

#define IMPL_SATURATE(type) type saturate( type x ) { return clamp( x, type(0.0), type(1.0) ); }

IMPL_SATURATE( float )
IMPL_SATURATE( vec4 )

float exp_decay( float x ) { return 1. - exp( -x ); }
// for rcp_decay, max x with something < 0 to prevent infinity and cull the other side
float rcp_decay( float x ) { return x / ( 1. + x ); }
float smoothstep_unchecked( float x ) { return ( x * x ) * ( 3.0 - x * 2.0 ); }
float linearstep( float a, float b, float x ) { return saturate( ( x - a ) / ( b - a ) ); }
float exp_bell( float x, float r ) { x *= ( 1. / r ); return exp( -x * x ); }
float smoothbump( float a, float r, float x ) { return 1.0 - smoothstep_unchecked( min( abs( x - a ), r ) / r ); }
float smoothbump( float x, float s1, float e1, float s2, float e2 ) { return smoothstep( s1, e1, x ) * smoothstep( e2, s2, x ); }
float cosbump( float x, float x0, float r ) { return ( 1. + cos( min( abs( ( x - x0 ) / r ), 1. ) * PI ) ) * 0.5; }
// like smoothstep, but takes a center and a radius instead
float smoothstep_c( float x, float c, float r ) { return smoothstep( c - r, c + r, x ); }
// band, centered at 0... like smoothstep_c but different semantics
float smoothband( float x, float r, float raa ) { return 1. - smoothstep_c( abs( x ), r, raa ); }
// range start,end
float smoothband( float x, float s, float e, float raa ) { return smoothband( x - ( e + s ) * 0.5, ( e - s ) * 0.5, raa ); }
vec2 perp( vec2 v ) { return vec2( -v.y, v.x ); }
// return range -pi,pi
float calc_angle( vec2 v ) { return atan( v.y, v.x ); }
float calc_angle( vec2 a, vec2 b ) { return calc_angle( vec2( dot( a, b ), dot( perp( a ), b ) ) ); }
vec3 contrast( vec3 x, vec3 s ) { return ( x - 0.5 ) * s + 0.5; }
float pow2( float x ) { return x * x; }
vec3 pow2( vec3 x ) { return x * x; }
vec4 pow2( vec4 x ) { return x * x; }
float pow5( float x ) { float x2 = x * x; return x2 * x2 * x; }
// in soft min don't go too crazy with small values of k
// those are not real min/max (returned values can exceed input values)
float soft_min2( float a, float b, float k ) { return -log2( exp2( -k * a ) + exp2( -k * b ) ) / k; }
float soft_max2( float a, float b, float k ) { return -soft_min2( -a, -b, k ); }
float powerful_scurve( float x, float p1, float p2 ) { return pow( 1.0 - pow( 1.0 - clamp( x, 0.0, 1.0 ), p2 ), p1 ); }
float maxcomp( float x ) { return x; }
float maxcomp( vec2 v ) { return max( v.x, v.y ); }
float maxcomp( vec3 v ) { return max( max( v.x, v.y ), v.z ); }
float mincomp( float x ) { return x; }
float mincomp( vec2 v ) { return min( v.x, v.y ); }
float mincomp( vec3 v ) { return min( min( v.x, v.y ), v.z ); }
vec3 luminance( vec3 c ) { return vec3( dot( vec3( 0.2989, 0.5866, 0.1145 ), c ) ); }
float sum( vec3 v ) { return v.x + v.y + v.z; }
// symmetrize/mirror x around a
float fold( float x, float a ) { return x + 2. * min( 0., a - x ); }
vec2 fold( vec2 p, vec2 o, vec2 n ) { float a = dot( p - o, n ); return p - 2. * min( a, 0. ) * n; }
// acos overflow bugs (subtle ot not) are the worse
float safe_acos( float x ) { return acos( clamp( x, -1., 1. ) ); }
vec4 safe_acos( vec4 x ) { return acos( clamp( x, vec4(-1.), vec4(1.) ) ); }

/// CLOSEST_POINT_TANGENT_TO_FUNC_21 calculates the distance to a 1d curve
/// input:
///  a_p               eval pos
///  a_func            the R->R function to evaluate, first guess (iteration start point) is vec2(a_p.x,a_func(a_p.x))
///                    a_func can be a macro, it seems
///  a_epsilon         epsilon used for derivative evaluation, must scale roughly with your working dimensions
///                    else the distance estimation will disolve as your epsilon disappears in floating point additions
///  a_num_iterations  num iterations - check actual quality of result to set this, often we just use 2
///  a_t0              the iteraton parameter start value, affects iteration speed a lot
///                    for a regular 1d function we use a_p.x
///                    for a polar function start at calc_angle(a_p)
/// output:
///  a_ret             the return value is a vec4 where .xy is vector to closest point on curve and .zw the derivative (tangent at the closest point)
///
/// - a_func(t) returns vec2(t,your1dfunc(t)) for 1d functions
/// - a_func(t) returns (yourpolarfunc(x)*unit_vector2(x)) for polar functions
/// a_func can be a macro

#define CLOSEST_POINT_TANGENT_TO_FUNC_21( a_ret, a_p, a_func, a_epsilon, a_num_iterations ) \
{ \
	/* we use this method for distance to curve: http://www.geometrie.tugraz.at/wallner/sproj.pdf */ \
	/* it is a bit different from https://iquilezles.org/articles/distance in that since it is iterative there is a potential quality/perf trade off */ \
	vec2 _p = a_p, _c, _dc; \
	float _epsilon = a_epsilon; \
	float _t = _p.x; /* t0, could be a parameter if the user knows better */ \
	for ( int _i = 0; _i < a_num_iterations; ++_i ) { \
		_c = a_func( _t ); \
		_dc = ( a_func( _t + _epsilon ) - _c ) * ( 1. / _epsilon ); \
		_t += dot( _p.xy - _c, _dc ) / dot( _dc, _dc ); /* simplification of _t += dot( _dc, _q - _c ) / dot( _dc, _dc ); where _q is _p.xy projected on (_c,_dc) line */ \
	} \
	a_ret = vec4( _c - _p, _dc ); \
}

// https://iquilezles.org/articles/smin
// polynomial smooth min (k = 0.1);
float smin_pol( float a, float b, float k )
{
	float h = clamp( 0.5 + 0.5 * ( b - a ) / k, 0.0, 1.0 );
	return mix( b, a, h ) - k * h * ( 1.0 - h );
}

// https://mynameismjp.wordpress.com/2016/10/09/sg-series-part-2-spherical-gaussians-101/
// v is the eval direction, v and axis assumed normalized and cos_v_axis = dot(v,axis)
float spherical_gaussian( float cos_v_axis, float amplitude, float sharpness ) { return amplitude * exp( ( cos_v_axis - 1. ) * sharpness ); }
vec3 spherical_gaussian( float cos_v_axis, vec3 amplitude, vec3 sharpness ) { return amplitude * exp( ( cos_v_axis - 1. ) * sharpness ); }
vec3 spherical_gaussian( float cos_v_axis, vec3 amplitude, float sharpness ) { return amplitude * exp( ( cos_v_axis - 1. ) * sharpness ); }

// https://iquilezles.org/articles/functions
float impulse( float a, float x ) { float ax = a * x; return ax * exp( 1. - ax ); }
vec2 impulse( vec2 a, vec2 x ) { vec2 ax = a * x; return ax * exp( vec2( 1. ) - ax ); }

float biexp2( float x, float a, float b ) { return ( ( a * b ) / ( a - b ) ) * ( exp2( -b * x ) - exp2( -a * x ) ); }
vec3 biexp2( vec3 x, vec3 a, vec3 b ) { return ( ( a * b ) / ( a - b ) ) * ( exp2( -b * x ) - exp2( -a * x ) ); }

//https://www.shadertoy.com/view/MsS3Wc
vec3 hsv2rgb( in vec3 c )
{
	vec3 rgb = clamp( abs( mod( c.x * 6.0 + vec3( 0.0, 4.0, 2.0 ), 6.0 ) - 3.0 ) - 1.0, 0.0, 1.0 );
	return c.z * mix( vec3( 1.0 ), rgb, c.y );
}

#define DECL_BOUNDS( btype, type, booltype ) \
struct btype { type pmin; type pmax; }; \
btype mkbounds_unchecked( type amin, type amax ) { btype ret; ret.pmin = amin; ret.pmax = amax; return ret; } \
type size( btype b ) { return b.pmax - b.pmin; } \
type center( btype b ) { return 0.5 * ( b.pmax + b.pmin ); } \
/* grid multiplier range */ \
/* bounds b is cell "0,0" */ \
/* min_xs is pmin offset (in multiples of bounds size) */ \
/* max_xs is pmax offset (in multiples of bounds size) */ \
btype mkbounds_unchecked_gx( btype b, type min_xs, type max_xs ) { type s = size( b ); btype ret = b; ret.pmin += s * min_xs; ret.pmax += s * max_xs; return ret; }

DECL_BOUNDS( bounds1, float, bool )
DECL_BOUNDS( bounds2, vec2, bvec2 )
DECL_BOUNDS( bounds3, vec3, bvec3 )

#define REPEAT_FUNCTIONS( type, btype ) \
type repeat( type x, type len ) { return len * fract( x * ( type( 1.0 ) / len ) ); }\
type repeat_mirror( type x, type len ) { return len * abs( type( -1.0 ) + 2.0 * fract( ( ( x * ( type( 1.0 ) / len ) ) - type( -1.0 ) ) * 0.5 ) ); }\
/* return identity in range start,start+len, and repeat mirror elsewhere */\
type repeat_mirror_l( type x, type start, type len ) { return start + repeat_mirror( x - start, len ); }\
type repeat_mirror_e( type x, type start, type end ) { return start + repeat_mirror( x - start, end - start ); }\
/* return identity in range start,start+len, and repeat elsewhere */\
type repeat_e( type x, type start, type end ) { return start + repeat( x - start, end - start ); }\
type repeat_b( type x, btype b ) { return b.pmin + repeat( x - b.pmin, b.pmax - b.pmin ); }\

REPEAT_FUNCTIONS( float, bounds1 )
REPEAT_FUNCTIONS( vec2, bounds2 )
REPEAT_FUNCTIONS( vec3, bounds3 )

#define TRI_FUNCTIONS(type,btype) \
/* function returns 0 at x = half_width */ \
type tri_p( type x, type half_width, type half_period )	{ return half_width - repeat_mirror( x, half_period ); } \
/* function returns 0 at x = half_width */ \
type tri_s( type x, type half_width, type half_spacing ) { return half_width - repeat_mirror( x, half_width + half_spacing ); } \
/* tri_b repeats bounds1 [s1,e1] inside a repeated bounds0 [s0,e0] */ \
/* be careful, it is *not* equivalent to using repeat_b on b0 and sd_bounds b1 inside that, unless b1 is centered */ \
/* use tri_b or sd_bounds_repeat_* to correctly repeat bounds sdf */ \
type tri_b( type p, type s0, type e0, type s1, type e1) { type c = s0 + ( e1 + s1 ) * 0.5; return -tri_p( p - c, ( e1 - s1 ) * 0.5, ( e0 - s0 ) * 0.5 ); } \
/* same as above but with bounds */ \
type tri_b( type p, btype b0, btype b1) { return tri_b( p, b0.pmin, b0.pmax, b1.pmin, b1.pmax ); }

TRI_FUNCTIONS( float, bounds1 )
TRI_FUNCTIONS( vec2, bounds2 )
TRI_FUNCTIONS( vec3, bounds3 )

// like smoothband() but repeated, using smoothstep as poor AA
// - r is the half width of the stripes
// - raa is the half size of the edge/aa smoothstep (ex: pixel_size)
// - period is the distance between 2 consecutive stripes
float stripes( float x, float period, float r, float raa ) { return smoothstep( r + raa, r - raa, repeat_mirror( x, period * 0.5 ) ); }
vec2 stripes( vec2 x, vec2 period, vec2 r, vec2 raa ) { return smoothstep( r + raa, r - raa, repeat_mirror( x, period * 0.5 ) ); }
// variation of stripes where multiple period overlap (stripes not centered on 0)
float stripes2( float x, float period, float r, float raa ) { return smoothstep( r + raa, r - raa, repeat_mirror( x - r, period * 0.5 ) ); }

// hash functions from David Hoskins's https://www.shadertoy.com/view/4djSRW using "integer stepped ranges" settings
#define HASHSCALE1 .1031
#define HASHSCALE3 vec3(.1031, .1030, .0973)
float hash11( float p ) { vec3 p3  = fract( vec3( p ) * HASHSCALE1 ); p3 += dot( p3, p3.yzx  + 19.19 ); return fract( ( p3.x + p3.y ) * p3.z ); }
vec3 hash32( vec2 p ) { vec3 p3 = fract( vec3( p.xyx ) * HASHSCALE3 ); p3 += dot( p3, p3.yxz  + 19.19 ); return fract( ( p3.xxy  + p3.yzz  ) * p3.zyx ); }

// hopefully stable hash (across gpus and/or webgl) functions, munged from iq's version https://www.shadertoy.com/view/XlXcW

vec4 hash44_( ivec4 x0 )
{
	uint k = 1103515245U;  // GLIB C
	uvec4 x = uvec4( x0 );
	x = (( x >> 13U ) ^ x.yzwx ) * k;
	x = (( x >> 13U ) ^ x.zwxy ) * k;
//	x = (( x >> 13U ) ^ x.wxyz ) * k; // can't really tell the difference 
	return vec4( x ) * ( 1.0 / float( 0xffffffffU ));
}

vec4 hash42_( ivec2 x0 )
{
	uint k = 1103515245U;  // GLIB C
	uvec4 x = uvec4( x0, x0 * 0x8da6b343 );
	x = (( x >> 13U ) ^ x.yzwx ) * k;
	x = (( x >> 13U ) ^ x.zwxy ) * k;
//	x = (( x >> 13U ) ^ x.wxyz ) * k; // can't really tell the difference 
	return vec4( x ) * ( 1.0 / float( 0xffffffffU ));
}

vec2 hash22_( ivec2 p ) { return hash42_( p ).xy; }
vec2 hash24_( ivec4 p ) { return hash44_( p ).xy; }

#define V45 vec2( 0.707106781, 0.707106781 )
#define V60 vec2( 0.5, 0.866025403 )

// return a unit vector, or an angle (it's the same thing)
vec2 unit_vector2( float angle ) { return vec2( cos( angle ), sin( angle ) ); }
// note that if point p is also a unit vector, rotate_with_unit_vector returns the same as doing unit_vector2 on the sum of the angles (obvious but)
vec2 rotate_with_unit_vector( vec2 p, vec2 cs ) { return vec2( cs.x * p.x - cs.y * p.y, cs.y * p.x + cs.x * p.y ); }
vec2 rotate_with_unit_vector_neg( vec2 p, vec2 cs ) { return vec2( cs.x * p.x + cs.y * p.y, -cs.y * p.x + cs.x * p.y ); }
vec2 rotate_with_angle( vec2 p, float a_angle ) { return rotate_with_unit_vector( p, unit_vector2( a_angle ) ); }
// theta is the angle with the z axis, range [0,pi]
// phi is the angle with x vectors on z=0 plane, range [0,2pi]
vec3 zup_spherical_coords_to_vector( float theta, float phi ) { vec2 theta_vec = unit_vector2( theta ); return vec3( theta_vec.y * unit_vector2( phi ), theta_vec.x ); }
vec3 yup_spherical_coords_to_vector( float theta, float phi ) { return zup_spherical_coords_to_vector( theta, phi ).yzx; }

mat4 yup_spherical_coords_to_matrix( float theta, float phi )
{
	vec3 y = yup_spherical_coords_to_vector( theta, phi );
	vec3 z = yup_spherical_coords_to_vector( theta + PI * 0.5, phi );
	vec3 x = cross( y, z );
	return mat4( vec4( x, 0.0 ), vec4( y, 0.0 ), vec4( z, 0.0 ), vec4( 0, 0, 0, 1 ) );
}

mat4 z_rotation( float angle ) { vec2 v = unit_vector2( angle ); return mat4( vec4( v.x, v.y, 0.0, 0.0 ), vec4( -v.y, v.x, 0.0, 0.0 ), vec4( 0, 0, 1, 0 ), vec4( 0, 0, 0, 1 ) ); }

struct Ray { vec3 o; vec3 d; };

Ray mkray( vec3 o, vec3 d ) { Ray tmp; tmp.o = o; tmp.d = d; return tmp; }
Ray get_view_ray( vec2 normalized_pos, float z, float aspect, float tan_half_fovy ) { vec3 p = vec3( normalized_pos * vec2( aspect, 1.0 ) * tan_half_fovy, -1.0 ) * z; return mkray( p, normalize( p ) ); }

mat4 lookat( vec3 eye, vec3 center, vec3 up ) { vec3 z = normalize( eye - center ); vec3 x = normalize( cross( up, z ) ); vec3 y = cross( z, x ); return mat4( vec4( x, 0.0 ), vec4( y, 0.0 ), vec4( z, 0.0 ), vec4( eye, 1.0 ) ); }

float plane_trace_z( Ray ray, float base, float epsilon ) { return abs( ray.d.z ) > epsilon ? ( base - ray.o.z ) / ray.d.z : FLT_MAX; }

// build a little quadric so that y'(0)=0, y(r)=r, y'(r)=1 here
float her2( float x, float r ) { return 0.5 * ( ( 1.0 / r ) * x * x + r ); }

// customize max of f(x)=0 and f(x)=x in the x in [ -r,r] interval
float curved_max_vfunc_hard_bevel( float x, float r ) { return max( r, abs( x ) ); }
float curved_max_vfunc_weld_quadric( float x, float r ) { x = abs( x ); if ( x > r ) return x; return her2( x, r ); }
// rr in 0,1, set < 1 if you want to see a flat bit
// rr == 1 gives a soft bevel, slightly different shape and a bit more expensive than curved_max_vfunc_weld_quadric
float curved_max_vfunc_round_bevel( float x, float r, float rr )
{
	x = abs( x );
	if ( x > r ) return x;
	float a = rr * r; // make bevel radius relative to r (so rr is a 0,1 value, if you go above 1 yo get a discontinuity at 0)
	float cr = a * SQR2; // this is the radius of the circle used to make the round bevel
	vec2 c = vec2( r - a, r + a ); // center of round bevel is at (r-a,r+a) (on a y=1-x line that emanates from (r,r))
	return c.y - sqrt( cr * cr - pow2( max( 0.0, x - c.x ) ) );
}

// max
float opI( float d1, float d2 ) { return max( d1, d2 ); }
float opI_soft2( float a, float b, float k ) { return soft_max2( a, b, k ); }
float opI_hard_bevel( float a, float b, float r ) { float c = ( a + b ) * 0.5; return c + curved_max_vfunc_hard_bevel( a - c, r ); }
float opI_round_bevel( float a, float b, float r, float rr ) { float c = ( a + b ) * 0.5; return c + curved_max_vfunc_round_bevel( a - c, r, rr ); }
float opU( float d1, float d2 ) { return -max( -d1, -d2 ); }
float opU_hard_bevel( float a, float b, float r ) { return -opI_hard_bevel( -a, -b, r ); }
float opS( float d1, float d2 ) { return max( -d2, d1 ); }
float opS_hard_bevel( float a, float b, float r ) { return opI_hard_bevel( -b, a, r ); }
float opI( float d1, float d2, float d3 ) { return max( max( d1, d2 ), d3 ); }
// Band/border operations (extract a band from an sdf)
// band c-r,c+r
float opB_rc( float d, float r, float c ) { return abs( d - c ) - r; }
// band -w,0
float opB_inside( float d, float w ) { float r = w * 0.5; return opB_rc( d, r, -r ); }
// band 0,w
float opB_outside( float d, float w ) { float r = w * 0.5; return opB_rc( d, r, r ); }
// band mi,ma
// should be same as sd_bounds_range(d,mi,ma)
float opB_range( float d, float mi, float ma ) { return opB_rc( d, ( ma - mi ) * 0.5, ( mi + ma ) * 0.5 ); }

// trying many apis to see what sticks.

float sd_bounds_range_round( vec2 p, vec2 mi, vec2 ma, float r )
{
	vec2 h = ( ma - mi ) * 0.5;
	p = abs( p - ( mi + ma ) * 0.5 );
	vec2 c = h - r;
	float mask = max( step( c.x, p.x ), step( c.y, p.y ) );
	return mix( -r + max( ( p - c ).x, ( p - c ).y ), length( max( p - c, 0.0 ) ) - r, mask );
}

float sd_bounds_half_size( float p, float h ) { p = abs( p ) - h; return p; }
float sd_bounds_half_size( vec2 p, vec2 h ) { p = abs( p ) - h; return opI( p.x, p.y ); }
float sd_bounds_half_size( vec3 p, vec3 h ) { p = abs( p ) - h; return opI( p.x, p.y, p.z ); }
float sd_bounds_range( vec2 p, vec2 mi, vec2 ma ) { vec2 hmi = mi * 0.5; vec2 hma = ma * 0.5; return sd_bounds_half_size( p - ( hma + hmi ), hma - hmi ); }
// those bounds repeat might be good after all, since they centering and lead to a correct repeat...
float sd_bounds_range( float p, float mi, float ma ) { return sd_bounds_half_size( p - ( ( ma + mi ) * 0.5 ), ( ma - mi ) * 0.5 ); }
float sd_bounds_range( vec3 p, vec3 mi, vec3 ma ) { return sd_bounds_half_size( p - ( ( ma + mi ) * 0.5 ), ( ma - mi ) * 0.5 ); }
float sd_bounds( vec2 p, bounds2 b ) { return sd_bounds_range( p, b.pmin, b.pmax ); }
float sd_bounds( vec3 p, bounds3 b ) { return sd_bounds_range( p, b.pmin, b.pmax ); }
// see sd_bounds_repeat_range_range instead of sd_bounds_repeat_size_margin
float sd_bounds_repeat_size_margin( float p, float size, float margin ) { return sd_bounds_range( repeat( p, size ), margin, size - margin ); }
float sd_bounds_repeat_size_margin( vec2 p, vec2 size, vec2 margin ) { return sd_bounds_range( repeat( p, size ), margin, size - margin ); }
float sd_bounds_repeat_size_margin( vec3 p, vec3 size, vec3 margin ) { return sd_bounds_range( repeat( p, size ), margin, size - margin ); }
// repeat bounds with margin, (mi1,ma1) is included inside (mi,ma)
float sd_bounds_repeat_range_range( float p, float mi, float ma, float mi1, float ma1 ) { return maxcomp( tri_b( p, mi, ma, mi1, ma1 ) ); }
float sd_bounds_repeat_range_range( vec2 p, vec2 mi, vec2 ma, vec2 mi1, vec2 ma1 ) { return maxcomp( tri_b( p, mi, ma, mi1, ma1 ) ); }

// https://learnopengl.com/#!PBR/Theory
// http://graphicrants.blogspot.jp/
// alpha = roughness*roughness and "m stands for the microfacet normal... in practice you input the half vector for m"
// Trowbridge-Reitz
float D_GGX( float m_dot_n, float alpha ) { float alpha_sqr = alpha * alpha; return alpha_sqr / ( PI * pow2( pow2( m_dot_n ) * ( alpha_sqr - 1. ) + 1. ) ); }
float G_kelemen( float n_dot_l, float n_dot_v, float v_dot_h ) { return n_dot_l * n_dot_v / pow2( v_dot_h ); }
float F_none( float v_dot_h, float F0 ) { return F0; }
float F_schlick( float v_dot_h, float F0 ) { return F0 + ( 1. - F0 ) * pow5( 1. - v_dot_h ); }

// I am not going to pretend anything is physically realistic here, but at least try to use standardized functions
// v = wi
vec3 add_light_contrib( vec3 albedo, vec3 l, vec3 n, vec3 v, vec3 Li, float dwi, float kdiffuse, float kspecular, float roughness )
{
	float F0 = 0.08;
	float alpha = roughness * roughness;
	vec3 h = normalize( l + v );
	float eps = 1e-4; // else divides by zero
	float n_dot_l = max( eps, dot( n, l ) );
	float n_dot_v = max( eps, dot( n, v ) );
	float n_dot_h = max( eps, dot( n, h ) );
	float v_dot_h = max( eps, dot( h, v ) );
	float D = D_GGX( n_dot_h, alpha ); // n_dot_h should probably be clamped to >=0
	float G = G_kelemen( n_dot_l, n_dot_v, v_dot_h );
//	float F = F_none( n_dot_v, F0 );
	float F = F_schlick( n_dot_v, F0 );
//	float F = F_schlick( n_dot_h, F0 ); // can't be right
	return ( ( kdiffuse * albedo * ( 1. / PI )
			   + kspecular * ( D * F * G ) / ( 4. * n_dot_l * n_dot_v ) ) ) * Li * n_dot_l * dwi;
}

//http://www.cs.utah.edu/~reinhard/cdrom/tonemap.pdf
vec3 tonemap_reinhard( vec3 x ) { return x / ( 1. + x ); }

vec3 gamma_correction( vec3 L ) { return pow( L, vec3( 0.45 ) ); }
// mentioned in http://resources.mpi-inf.mpg.de/tmo/logmap/ , more dark tones friendly than just pow(L,0.45)
vec3 gamma_correction_itu( vec3 L ) { return mix( 4.5061986 * L, 1.099 * pow( L, vec3( 0.45 ) ) - 0.099, step( vec3( 0.018 ), L ) ); }

// returns 0 if v component is zero, rcp else, pass s = sign( v ) (values for s are -1, 0, 1)
vec3 zrcp( vec3 v, vec3 s ) { s = abs( s ); return s / ( ( s - vec3( 1. ) ) + v ); }

// encapsulate dda iteration a little bit for readability
struct DDA3
{
	vec3 start, v; // v = end - start
	vec3 s; // sign(v)
	vec3 f1; // spacing (as a fraction of v, not distance) between 2 grid lines, to be multiplied by v to get a vector
	vec3 f; // segment intersects unit grid at points i = dda.start + ( dda.t[k] + i * dda.t1[k] ) * dda.v
	vec3 c; // cell index we entered (coords of bottom left corner)
	int done; // iteration end condition
	vec3 am; // argmin used during iteration
	vec3 p; // which point we entered the cell from, or start, or end
};

// iterate on p = dda.start + ( dda.end - dda.start ) * dda.alpha such that p intersect canonical dda.a
// supporting arbitrary cell size is not much more expensive so we do it
DDA3 dda_init( vec3 a_start, vec3 a_end, vec3 a_size, bool a_finite )
{
	DDA3 dda;
	dda.start = a_start;
	dda.v = a_end - a_start;
	dda.s = sign( dda.v ); // -1, 0, 1
#if 0
	vec3 v_zrcp = zrcp( dda.v, dda.s );
#else
	vec3 v_zrcp = vec3( 1. ) / dda.v; // divide by zero
#endif
	vec3 cell_size_rcp = vec3( 1. ) / a_size;
	dda.c = floor( a_start * cell_size_rcp ); // start cell
	dda.f = ( ( dda.c + ( dda.s + vec3( 1. ) ) * 0.5 ) * a_size - a_start ) * v_zrcp; // go positive or negative direction, initial fractional t

	// do this only for dda_step_segment
	if ( a_finite ) dda.f = min( vec3( 1. ), dda.f + 1. - abs( dda.s ) ); // if the sign is 0, set t to 1, meaning we are done on this axis

	dda.f1 = dda.s * v_zrcp * a_size; // per axis grid steping as a fraction of v
	dda.done = 0;
	dda.am = vec3( 0. );
	dda.p = dda.start;
	return dda;
}

// returns 1,0,0 if x is the min, 0,1,0 if y is the min, 0,0,1 if z is the min (function code is from iq's shader)
// very good for shader because we don't have to use random access which is sometimes borked in surprising ways
vec3 argminv( vec3 v ) { return step( v.xyz, v.yxy ) * step( v.xyz, v.zzx ); }

// iterate on all cells intersecting the input segment
// make sure you called dda_init with a_finite = true
// dda.done == 1 is the loop exit condition
//void dda_step_segment( inout DDA3 dda )
//{
//	if ( sum( dda.f ) == 3. ) ++dda.done; // all 1. means we covered v and we should be at the end point
//	else
//	{
//		dda.am = argminv( dda.f );
//		dda.p = dda.start + sum( dda.am * dda.f ) * dda.v;
//		dda.c += dda.am * dda.s;
//		dda.f = min( dda.f + dda.am * dda.f1, vec3( 1. ) ); // next dda.f
//	}
//}

// iterate forever - if you don't care about iterating exactly the segment length, a bunch of things can be skipped
// make sure you called dda_init with a_finite = false
void dda_step_infinite( inout DDA3 dda )
{
	dda.am = argminv( dda.f );
	dda.p = dda.start + sum( dda.am * dda.f ) * dda.v;
	dda.c += dda.am * dda.s;
	dda.f = dda.f + dda.am * dda.f1; // next dda.f
}

vec3 dda_point( in DDA3 dda, float f ) { return dda.start + dda.v * f; }

// t0, t1 are t ranges along rays on each dimension, returns (union min, union max) range, ray intersects iff .y > .x
vec2 intersect_ranges( vec3 t0, vec3 t1 )
{
	return vec2( maxcomp( vec3( min( t0.x, t1.x ), min( t0.y, t1.y ), min( t0.z, t1.z ) ) ),
				 mincomp( vec3( max( t0.x, t1.x ), max( t0.y, t1.y ), max( t0.z, t1.z ) ) ) );
}

struct Ranges_x4
{
	vec2 rA, rB, rC, rD; // ranges along the ray, for each bound b[i]
	bounds3 bA, bB, bC, bD; // we could store bounds2 + height
};

// factorize and pack a few terms used in raytracing of 4 children bounds

struct Split4bSetup
{
	vec3 drcp;
	float dz;
	vec3 dmargin;
	vec2 dmin, dmax;
};

Split4bSetup setup_Split4b( Ray ray, vec2 amin, vec2 amax, vec2 margin )
{
	Split4bSetup set;
	set.drcp = vec3( 1. ) / ray.d; // divide by zero
	set.dmin = ( amin - ray.o.xy ) * set.drcp.xy;
	set.dmax = ( amax - ray.o.xy ) * set.drcp.xy;
	set.dz = ray.o.z * set.drcp.z;
	set.dmargin = vec3( margin * set.drcp.xy, 0. );
	return set;
}

// --------------
// |   |   | D  |
// | A | B |----| amix.z
// |   |   | C  |
// --------------
//   amix.x amix.y

void trace_Split4b_xxy( inout Ranges_x4 ret, Ray ray, in Split4bSetup set, vec3 amix, vec4 h )
{
	vec3 set_dmix = ( amix - ray.o.xxy ) * set.drcp.xxy; // split axis described in amix are x,x,y
	ret.rA = intersect_ranges( vec3( set.dmin.x, set.dmin.y, -set.dz ) + set.dmargin, vec3( set_dmix.x, set.dmax.y, h.x * set.drcp.z - set.dz ) - set.dmargin );
	ret.rB = intersect_ranges( vec3( set_dmix.x, set.dmin.y, -set.dz ) + set.dmargin, vec3( set_dmix.y, set.dmax.y, h.y * set.drcp.z - set.dz ) - set.dmargin );
	ret.rC = intersect_ranges( vec3( set_dmix.y, set.dmin.y, -set.dz ) + set.dmargin, vec3( set.dmax.x, set_dmix.z, h.z * set.drcp.z - set.dz ) - set.dmargin );
	ret.rD = intersect_ranges( vec3( set_dmix.y, set_dmix.z, -set.dz ) + set.dmargin, vec3( set.dmax.x, set.dmax.y, h.w * set.drcp.z - set.dz ) - set.dmargin );
}

void bound_Split4b_xxy( inout Ranges_x4 ret, Ray ray, vec2 amin, vec2 amax, vec3 amix, vec4 h, vec2 margin )
{
	vec3 m = vec3( margin, 0. );
	ret.bA = mkbounds_unchecked( vec3( amin.x, amin.y, 0. ) + m, vec3( amix.x, amax.y, h.x ) - m );
	ret.bB = mkbounds_unchecked( vec3( amix.x, amin.y, 0. ) + m, vec3( amix.y, amax.y, h.y ) - m );
	ret.bC = mkbounds_unchecked( vec3( amix.y, amin.y, 0. ) + m, vec3( amax.x, amix.z, h.z ) - m );
	ret.bD = mkbounds_unchecked( vec3( amix.y, amix.z, 0. ) + m, vec3( amax.x, amax.y, h.w ) - m );
}

// -----------------
// |   |   |   |   |
// | A | B | C | D |
// |   |   |   |   |
// -----------------
//   amix.x amix.y amix.z

void trace_Split4b_xxx( inout Ranges_x4 ret, Ray ray, in Split4bSetup set, vec3 amix, vec4 h )
{
	vec3 set_dmix = ( amix - ray.o.xxx ) * set.drcp.xxx; // split axis described in amix are x,x,x
	ret.rA = intersect_ranges( vec3( set.dmin.x, set.dmin.y, -set.dz ) + set.dmargin, vec3( set_dmix.x, set.dmax.y, h.x * set.drcp.z - set.dz ) - set.dmargin );
	ret.rB = intersect_ranges( vec3( set_dmix.x, set.dmin.y, -set.dz ) + set.dmargin, vec3( set_dmix.y, set.dmax.y, h.y * set.drcp.z - set.dz ) - set.dmargin );
	ret.rC = intersect_ranges( vec3( set_dmix.y, set.dmin.y, -set.dz ) + set.dmargin, vec3( set_dmix.z, set.dmax.y, h.z * set.drcp.z - set.dz ) - set.dmargin );
	ret.rD = intersect_ranges( vec3( set_dmix.z, set.dmin.y, -set.dz ) + set.dmargin, vec3( set.dmax.x, set.dmax.y, h.w * set.drcp.z - set.dz ) - set.dmargin );
}

void bound_Split4b_xxx( inout Ranges_x4 ret, Ray ray, vec2 amin, vec2 amax, vec3 amix, vec4 h, vec2 margin )
{
	vec3 m = vec3( margin, 0. );
	ret.bA = mkbounds_unchecked( vec3( amin.x, amin.y, 0. ) + m, vec3( amix.x, amax.y, h.x ) - m );
	ret.bB = mkbounds_unchecked( vec3( amix.x, amin.y, 0. ) + m, vec3( amix.y, amax.y, h.y ) - m );
	ret.bC = mkbounds_unchecked( vec3( amix.y, amin.y, 0. ) + m, vec3( amix.z, amax.y, h.z ) - m );
	ret.bD = mkbounds_unchecked( vec3( amix.z, amin.y, 0. ) + m, vec3( amax.x, amax.y, h.w ) - m );
}

//        -----------
//        |  C |    |
// amix.y |----| D  |
//        |  A |----| amix.z
//        |    | B  |
//        -----------
//           amix.x

void trace_Split4b_xyy( inout Ranges_x4 ret, Ray ray, in Split4bSetup set, vec3 amix, vec4 h )
{
	vec3 set_dmix = ( amix - ray.o.xyy ) * set.drcp.xyy; // split axis described in amix are x,x,y
	ret.rA = intersect_ranges( vec3( set.dmin.x, set.dmin.y, -set.dz ) + set.dmargin, vec3( set_dmix.x, set_dmix.y, h.x * set.drcp.z - set.dz ) - set.dmargin );
	ret.rB = intersect_ranges( vec3( set_dmix.x, set.dmin.y, -set.dz ) + set.dmargin, vec3( set.dmax.x, set_dmix.z, h.y * set.drcp.z - set.dz ) - set.dmargin );
	ret.rC = intersect_ranges( vec3( set.dmin.x, set_dmix.y, -set.dz ) + set.dmargin, vec3( set_dmix.x, set.dmax.y, h.z * set.drcp.z - set.dz ) - set.dmargin );
	ret.rD = intersect_ranges( vec3( set_dmix.x, set_dmix.z, -set.dz ) + set.dmargin, vec3( set.dmax.x, set.dmax.y, h.w * set.drcp.z - set.dz ) - set.dmargin );
}

void bound_Split4b_xyy( inout Ranges_x4 ret, Ray ray, vec2 amin, vec2 amax, vec3 amix, vec4 h, vec2 margin )
{
	vec3 m = vec3( margin, 0. );
	ret.bA = mkbounds_unchecked( vec3( amin.x, amin.y, 0. ) + m, vec3( amix.x, amix.y, h.x ) - m );
	ret.bB = mkbounds_unchecked( vec3( amix.x, amin.y, 0. ) + m, vec3( amax.x, amix.z, h.y ) - m );
	ret.bC = mkbounds_unchecked( vec3( amin.x, amix.y, 0. ) + m, vec3( amix.x, amax.y, h.z ) - m );
	ret.bD = mkbounds_unchecked( vec3( amix.x, amix.z, 0. ) + m, vec3( amax.x, amax.y, h.w ) - m );
}

//  -------------
//  |   | D |   |
//  |   |   |   |
//  | A |---| C | amix.y
//  |   | B |   |
//  -------------
//  amix.x amix.z

void trace_Split4b_xyx( inout Ranges_x4 ret, Ray ray, in Split4bSetup set, vec3 amix, vec4 h )
{
	vec3 set_dmix = ( amix - ray.o.xyx ) * set.drcp.xyx; // split axis described in amix are x,x,y
	ret.rA = intersect_ranges( vec3( set.dmin.x, set.dmin.y, -set.dz ) + set.dmargin, vec3( set_dmix.x, set.dmax.y, h.x * set.drcp.z - set.dz ) - set.dmargin );
	ret.rB = intersect_ranges( vec3( set_dmix.x, set.dmin.y, -set.dz ) + set.dmargin, vec3( set_dmix.z, set_dmix.y, h.y * set.drcp.z - set.dz ) - set.dmargin );
	ret.rC = intersect_ranges( vec3( set_dmix.z, set.dmin.y, -set.dz ) + set.dmargin, vec3( set.dmax.x, set.dmax.y, h.z * set.drcp.z - set.dz ) - set.dmargin );
	ret.rD = intersect_ranges( vec3( set_dmix.x, set_dmix.y, -set.dz ) + set.dmargin, vec3( set_dmix.z, set.dmax.y, h.w * set.drcp.z - set.dz ) - set.dmargin );
}

void bound_Split4b_xyx( inout Ranges_x4 ret, Ray ray, vec2 amin, vec2 amax, vec3 amix, vec4 h, vec2 margin )
{
	vec3 m = vec3( margin, 0. );
	ret.bA = mkbounds_unchecked( vec3( amin.x, amin.y, 0. ) + m, vec3( amix.x, amax.y, h.x ) - m );
	ret.bB = mkbounds_unchecked( vec3( amix.x, amin.y, 0. ) + m, vec3( amix.z, amix.y, h.y ) - m );
	ret.bC = mkbounds_unchecked( vec3( amix.z, amin.y, 0. ) + m, vec3( amax.x, amax.y, h.z ) - m );
	ret.bD = mkbounds_unchecked( vec3( amix.x, amix.y, 0. ) + m, vec3( amix.z, amax.y, h.w ) - m );
}

// turn n relative sizes (unit don't matter, only respective sizes do) into n-1 unit size offsets
vec2 fractions( vec3 r ) { float sum_f_xy = r.x + r.y; float sum_f_xyz = sum_f_xy + r.z; return vec2( r.x, sum_f_xy ) / sum_f_xyz; }
vec3 fractions( vec4 r ) { float sum_f_xy = r.x + r.y; float sum_f_xyz = sum_f_xy + r.z; float sum_f_xyzw = sum_f_xyz + r.w; return vec3( r.x, sum_f_xy, sum_f_xyz ) / sum_f_xyzw; }

// -------------------------------------------------------- shader begin

/// expression is true when shadow has found a hit and is no longer interested in tracing the rest of everything - this helps quite a bit
#define SHADOW_EARLY_RET(a_t) (shadow_trace&&((a_t)!=FLT_MAX))
///#define SHADOW_EARLY_RET(a_t) false
/// tweak this value to minimize grainy artifacts due to distance to highway center line (used for many things, facades, highway objects etc)
#define CURVE_DISTANCE_EPSILON_OF_DEATH 0.001

/// the number of iterations we need to trace in a dda cell is a bit less than a would be full scene trace,
/// since we are already close to the surface thanks to the preliminary raytrace
/// but there is no magic, and if you are standing on a roof top you need more steps to close parallel planes
/// what we do is we give ebough steps (~70) but early return past a certain distance if there was no hit
#define DDA_CELL_SDF_MARCH_MAX_ITERATIONS 70
/// ...which is fine because DDA cell have an intrinsic max trace distance anyway, and we need to use it as it is a big optim (regardless of trace holes when we stand on roof tops)
/// fun anecdote: I overlooked that *major* optimization and bumped into it by chance during final tuning when trying to fix the roof top coffee break camera :-) 
#define ENABLE_MAX_DDA_TRACE_DISTANCE

#define MAX_DDA_ITER 37
#define MAX_DDA_TRACE 640. 
#define MAX_HIGHWAY_TRACE 640. 
#define FADE_START 480. 

/// dda cell size, each cell is a tile then split into 4 children each containing a building
#define CELL_SIZE vec3( 8., 8., 100. ) 
/// x = small spacing (back streets), y = large spacing (roads)
#define CELL_SPACING vec2( 0.47, 1.3 ) 

/// TYPE_BUILDING: 0.,1.,2.,3 (=0+tile_child_index)
/// TYPE_HOUSE: 4.,5.,6.,7 (=4+tile_child_index)
#define TYPE_HIGHWAY 8.
#define TYPE_ROAD 9. 
#define TYPE_SKY 10. 

#define MAX_BUILDING_HEIGHT 14.3 

#define AO_BEGIN() \
	{ /* ao algo from https://iquilezles.org/www/material/nvscene2008/rwwtt.pdf macrofified to avoid repetition */ \
		float _delta = 0.1, _a = 0.0, _b = 1.0; \
		for ( int _i = 0; _i < 5 FORCE_LOOP_AO; _i++ ) \
		{ \
			float _fi = float( _i ); \
			float _ao_t = _delta * _fi; \

///			float d = sd_Object( p + delta * fi * n, 0, _t, _view_ray, ... ); // example

#define AO_END(_ao_result) \
			_a += ( _ao_t  - d ) * _b; \
			_b *= 0.5; \
		} \
		_ao_result = max( 1.0 - 1.2 * _a, 0.0 ); \
	} \

float sd_SurfaceFacade7( vec3 p, float dAll )
{
	dAll -= -0.142857149;
	vec3 _p1 = p; vec2 _ci1 = vec2( 0.649999976, 0.375 ); vec2 _hp1 = vec2( 0.625, 0.300000011 ); vec2 _hw1 = vec2( 0.150000005, 0.074999988 ); vec2 _2hp1_rcp = vec2( 0.800000011, 1.666666626 ); _p1.xy -= _ci1; _p1.xy = -tri_p( _p1.xy, _hw1, _hp1 ); float _d1 = maxcomp( _p1.xy ); _d1 = opI( _d1, opB_range( p.z, -0.171428576, 0. ) );
	vec3 _p2 = p; vec2 _ci2 = vec2( 0.400000005, 0.234999999 ); vec2 _hp2 = vec2( 0.5, 0.300000011 ); vec2 _hw2 = vec2( 0.400000005, 0.015 ); vec2 _2hp2_rcp = vec2( 1, 1.666666626 ); _p2.xy -= _ci2; float _d2 = -tri_p( _p2.y, 0.015, 0.300000011 ); _d2 = opI( _d2, opB_range( p.z, -0.142857149, -0.128571435 ) );
	dAll = opS_hard_bevel( dAll, _d1, 0.007805752 );
	dAll = opU( dAll, _d2 );
	return dAll;
}

#define FLOOR_HEIGHT /*FLOOR_HEIGHT*/0.6

float sd_SurfaceFacade10( vec3 p, float dAll )
{
	vec3 _p1 = p; vec2 _ci1 = vec2( 0.570779979, 0.031555999 ); vec2 _hp1 = vec2( 0.569999992, 0.029999999 ); vec2 _hw1 = vec2( 0.560779988, 0.021556001 ); vec2 _2hp1_rcp = vec2( 0.877192974, 16.666667938 ); _p1.xy -= _ci1; _p1.xy = -tri_p( _p1.xy, _hw1, _hp1 ); float _d1 = maxcomp( _p1.xy ); _d1 = opI( _d1, opB_range( p.z, -0.028571428, 0.100000001 ) );
	dAll = opS_hard_bevel( dAll, _d1, 0.003604186 );
	return dAll; // return vec3(dAll,-0.028571428,0.100000001);
}

vec2 sd_SurfaceFacade0( vec3 p, float dAll )
{
	dAll -= -0.100000001;
	vec3 _p2 = p; vec2 _ci2 = vec2( 0.25, 0.362500011 ); vec2 _hp2 = vec2( 1., 0.300000011 ); vec2 _hw2 = vec2( 0.75, 0.137500002 ); vec2 _2hp2_rcp = vec2( 0.5, 1.666666626 ); _p2.xy -= _ci2; _p2.xy = -tri_p( _p2.xy, _hw2, _hp2 ); float _d2 = maxcomp( _p2.xy ); _d2 = opI( _d2, opB_range( p.z, -0.200000002, 0. ) );
	vec3 _p3 = p; vec2 _ci3 = vec2( -0.75, 0.300000011 ); vec2 _hp3 = vec2( 1., 0.300000011 ); vec2 _hw3 = vec2( 0.112500011, 0.300000011 ); vec2 _2hp3_rcp = vec2( 0.5, 1.666666626 ); _p3.xy -= _ci3; float _d3 = -tri_p( _p3.x, 0.112500011, 1. ); _d3 = opI( _d3, opB_range( p.z, -0.200000002, 0. ) );
	vec3 _p1 = p; vec2 _ci1 = vec2( 0.75, 0.362499982 ); vec2 _hp1 = vec2( 0.25, 0.300000011 ); vec2 _hw1 = vec2( 0.25, 0.147500008 ); vec2 _2hp1_rcp = vec2( 2, 1.666666626 ); _p1.xy -= _ci1; _p1.xy = -tri_p( _p1.xy, _hw1, _hp1 ); float _d1 = maxcomp( _p1.xy ); /*band*/_d1 = opB_rc( _d1, 0.008236314, 0.0 ); _d1 = opI( _d1, opB_range( p.z, -0.200000002, -0.19428572 ) );
	dAll = opS_hard_bevel( dAll, _d2, 0.007714285 );
	dAll = opU_hard_bevel( dAll, _d3, 0.009999996 );
	dAll = opU_hard_bevel( dAll, _d1, 0.005900437 );
	return vec2( dAll, p.z + 0.200000002 ); // return vec3(dAll,0,0.200000002);
}

vec2 sd_SurfaceFacade8( vec3 p, float dAll )
{
	vec3 _p3 = p; vec2 _ci3 = vec2( 0.200000002, 0.685000002 ); vec2 _hp3 = vec2( 0.354999989, 0.459999978 ); vec2 _hw3 = vec2( 0.149999991, 0.115000009 ); vec2 _2hp3_rcp = vec2( 1.408450722, 1.08695662 ); _p3.xy -= _ci3; _p3.xy = -tri_p( _p3.xy, _hw3, _hp3 ); float _d3 = maxcomp( _p3.xy ); _d3 = opI( _d3, opB_range( p.z, -0.057142857, 0.014285714 ) );
	vec3 _p1 = p; vec2 _ci1 = vec2( 0.200000002, 0.685000002 ); vec2 _hp1 = vec2( 0.354999989, 0.459999978 ); vec2 _hw1 = vec2( 0.149999991, 0.115000009 ); vec2 _2hp1_rcp = vec2( 1.408450722, 1.08695662 ); _p1.xy -= _ci1; _p1.xy = -tri_p( _p1.xy, _hw1, _hp1 ); float _d1 = maxcomp( _p1.xy ); /*band*/_d1 = opB_rc( _d1, 0.002559998, 0.0 ); _d1 = opI( _d1, opB_range( p.z, -0.071428574, 0. ) );
	vec3 _p2 = p; vec2 _ci2 = vec2( 0.287499994, 0.684999942 ); vec2 _hp2 = vec2( 0.354999989, 0.459999978 ); vec2 _hw2 = vec2( 0.057500004, 0.109999984 ); vec2 _2hp2_rcp = vec2( 1.408450722, 1.08695662 ); _p2.xy -= _ci2; _p2.xy = -tri_p( _p2.xy, _hw2, _hp2 ); float _d2 = maxcomp( _p2.xy ); /*band*/_d2 = opB_rc( _d2, 0.003154247, 0.0 ); _d2 = opI( _d2, opB_range( p.z, -0.085714288, -0.028571428 ) );
	dAll = opS_hard_bevel( dAll, _d3, 0.000975659 );
	dAll = opU_hard_bevel( dAll, _d1, 0.000975659 );
	dAll = opU_hard_bevel( dAll, _d2, 0.000138338 );
	return vec2( dAll, p.z + 0.057142857 ); // return vec3(dAll,-0.085714288,0.014285714);
}

// function used to make roof tiles
// a1 is the slope of curve going up (1.)
// a2 is the slope of curve going down (-2.)
// p is the period
float hard_waves( float x, float a1, float a2, float p ) { x = repeat( x, p ); x = min( a1 * x, a2 * x - a2 * p ); return x; }

// roof tiles height field (hf)
float hf_SurfaceRoofTiles( vec2 p ) { return ( 0.4 * hard_waves( p.y, 0.3, -1.6, 0.19 ) + 0.02 * abs( sin( p.x * 30. ) ) ); }

// build diagonal scopes on the top edges of a bounds b "extruded" by h
// they can be used as support planes for roof surface
// return value is a 3d point local to those symetrized diagonal plane spaces, that can be used to map the roof surface
// return value's .z is the distance to plane
// slope_ctrl controls the steepness of the roof planes, 1. for identity
// h is height of base house walls
// b is base/ground 2d scope bounds
// p is input world pos
// we don't return a scope because we are mirroring things here, Scope's .b and .dcc would have no sense
vec3 getRoofLocalX( vec3 p, float slope_ctrl, bounds2 b, float h )
{
	// gable roof with tiled surface
	float hw = ( b.pmax.x - b.pmin.x ) * 0.5; // half width
	float cx = ( b.pmax.x + b.pmin.x ) * 0.5; // center
	float h2 = hw * slope_ctrl; // roof height
	vec2 v = vec2( abs( p.x - cx ), p.z - ( h + h2 ) );
	vec2 yy = normalize( vec2( hw, -h2 ) );
	return vec3( p.y, dot( v, yy ), dot( v, perp( yy ) ) );
}

vec3 getRoofLocalY( vec3 p, float slope_ctrl, bounds2 b, float h )
{
	// gable roof with tiled surface
	float hw = ( b.pmax.y - b.pmin.y ) * 0.5; // half width
	float cy = ( b.pmax.y + b.pmin.y ) * 0.5; // center
	float h2 = hw * slope_ctrl; // roof height
	vec2 v = vec2( abs( p.y - cy ), p.z - ( h + h2 ) );
	vec2 yy = normalize( vec2( hw, -h2 ) );
	return vec3( p.x, dot( v, yy ), dot( v, perp( yy ) ) );
}

// rudimentary concept of "scope" for facade, roof surfaces etc.
struct Scope
{
	vec3 p; // point in scope space, plane at p.z = 0
	bounds2 b; // bounds of scope shape, for clipping/shape cast
	float dcc; // df of scope shape ("cookie cutter"), for clipping/shape cast, should be included in .b for consistancy
	float t; // marching distance, used for error thresholds, "inflating" detail etc.
};

Scope getScopeFacadeX( Scope base, float h, int select_side )
{
	Scope facade;
	facade.b = mkbounds_unchecked( vec2( base.b.pmin.y, 0.0 ), vec2( base.b.pmax.y, h ) );
	// note: we just flip the sign of p.x for the other side, it will horizontally flip the content but most often we don't care
	if ( select_side == ( 1 | 2 ) ) facade.p = vec3( base.p.y, base.p.z, abs( base.p.x - center( base.b ).x ) - size( base.b ).x * 0.5 );
	else if ( select_side == 1 ) facade.p = vec3( base.p.y, base.p.z, base.p.x - base.b.pmax.x );
	else if ( select_side == 2 ) facade.p = vec3( base.p.y, base.p.z, -base.p.x + base.b.pmin.x );
	facade.dcc = sd_bounds( facade.p.xy, facade.b );
	return facade;
}

Scope getScopeFacadeY( Scope base, float h, int select_side )
{
	Scope facade;
	facade.b = mkbounds_unchecked( vec2( base.b.pmin.x, 0.0 ), vec2( base.b.pmax.x, h ) );
	// note: we just flip the sign of p.x for the other side, it will horizontally flip the content but most often we don't care
	if ( select_side == ( 1 | 2 ) ) facade.p = vec3( base.p.x, base.p.z, abs( base.p.y - center( base.b ).y ) - size( base.b ).y * 0.5 );
	else if ( select_side == 1 ) facade.p = vec3( base.p.x, base.p.z, base.p.y - base.b.pmax.y );
	else if ( select_side == 2 ) facade.p = vec3( base.p.x, base.p.z, -base.p.y + base.b.pmin.y );
	facade.dcc = sd_bounds( facade.p.xy, facade.b );
	return facade;
}

float sd_RoofTopObject2( float dsofar, Scope roof, float h, vec3 rnd )
{
	h *= 0.6 + 0.4 * mod( rnd.y, 4. ) * ( 1. / 3.333 );
	float roof_geom_max_height = 0.025; // a rough but conservative estimate of roof geometry height
	h = max( 0., h - roof_geom_max_height ); // fixme: hack: make sure h is bounding height instead
	// select a small bounds b0 as a fraction of b, that we are going to repeat
	bounds2 b0 = mkbounds_unchecked_gx( roof.b, vec2( 0.1, 0.1 ), vec2( -0.7, -0.7 ) );
	// select a subgrid, range of b0 we want to keep, store range in b3
	vec2 gridsize = vec2( 1. + mod( rnd.x, 4. ), 1. );
	bounds2 b3 = mkbounds_unchecked_gx( b0, vec2( 0., 0. ), gridsize - vec2( 1. ) );

//	if ( dsofar < sd_bounds_range( roof.p, vec3( b3.pmin, 0. ), vec3( b3.pmax, h ) ) || roof.p.z < 0. ) return dsofar; // early return if the roof object is further than dsofar, not necesserarily a win...

	// inside that select a centered bounds b1
	bounds2 b1 = mkbounds_unchecked_gx( b0, vec2( 0.1, 0.1 ), vec2( -0.1, -0.1 ) );
	vec3 p2 = roof.p;
	p2.xy = repeat_b( p2.xy, b0 ); // remember: b1 must be centered inside b0!

	Scope base = roof;
	base.p = p2;
	base.b = b1;
	base.dcc = sd_bounds( base.p.xy, base.b );
	base.dcc = opI( base.dcc, sd_bounds( roof.p.xy, b3 ) ); // only keep b3 area

	// select a subgrid (clip against)
	float d = opI( base.p.z - h, base.dcc );
	d = opI( -base.p.z, d );
//	d = opI( d, sd_bounds( roof.p.xy, mkbounds_unchecked_gx( b0, vec2( 0, 0 ), vec2( 2, 1 ) ) ) );

	{
		// facade
		Scope facade = getScopeFacadeY( base, h, 3 );
		vec3 p3 = facade.p;
		p3.xy *= 2.; float d2 = sd_SurfaceFacade10( p3, facade.p.z );
		d = opI( d2, d );
	}

	{
		// roof small border wall on top of object
		Scope roof2 = base;
		roof2.p.z -= h;
		float small_roof_border = opB_inside( roof2.dcc, 0.01 );
		small_roof_border = opI( small_roof_border, opB_inside( -roof2.p.z, roof_geom_max_height ) );
		d = opU( d, small_roof_border );
	}

	return opI( d, roof.dcc );
}

float sd_JPBuildingRoofTopWithObjects( float d, Scope roof, float roof_geom_max_height, bool enable_objects, vec3 rnd )
{
	// roof small border wall
	float dborder = opB_inside( roof.dcc, 0.02 );
	dborder = opI( dborder, opB_inside( -roof.p.z, 0.05 ) );
	// roof ground tiles, perhaps this should be textured but never mind. we get more detail
	float tile_size = 0.05;
	float dtiles = -mincomp( tri_s( roof.p.xy, vec2( tile_size * 0.5 ), vec2( 0.005 ) ) );
	dtiles = opI( roof.dcc + 0.05, dtiles ) + roof.t * 0.004; // add t in spacing so we can see it from far away
	dtiles = opI_round_bevel( dtiles, opB_range( roof.p.z, -0.001, 0.0025 ), 0.00125, 0.75 );
	d = opU( d, opU( dtiles, dborder ) );
	if ( enable_objects )
	{
		// parametric model for small features on roof
		Scope roof_object_scope = roof;
		float droof_object = FLT_MAX;
		droof_object = sd_RoofTopObject2( d, roof_object_scope, roof_geom_max_height, rnd );
//		droof_object = opI( droof_object, -roof.p.z ); // cut all the bits below roof object level
		d = opU( d, droof_object );
	}
	return d;
}

#define ROAD_HALFWIDTH (1.)
#define ROAD_WIDTH (ROAD_HALFWIDTH*2.)

// distance to highway center line requires special care in this shader
struct NearestHighwayRetval
{
	vec2 p; // query point
	vec2 pr; // query point in y repeat space
	float d; // distance to center line == length(d2f.xy)
	vec4 d2f; // .xy is vector to closest point, .zw is the tangent at closest point
	vec2 o_clip, n_clip; // clip plane so we can build clean clip facades for buildings in contact with the highway
};

// building sdf eval return value
struct ParametricBuildingRetval
{
	float d, droof; // distance to building and distance to closest roof point for coloring
	vec3 windr; // distance to window in .x, windows 2d orientation in .zw (orientation is for better categorizing of pixels)
};

// modern buildings, most often square but can be clipped by nearby highways
ParametricBuildingRetval sd_Building( float t, vec3 p, bounds2 b, float h, NearestHighwayRetval nh, vec3 rnd )
{
	float roof_geom_max_height = 0.3; // a rough but conservative estimate of roof geometry height
	h -= roof_geom_max_height; // fixme: hack: make sure h is bounding height instead

	// some building base scope
	Scope base;
	base.p = p;
	base.b = b;
	base.dcc = sd_bounds( base.p.xy, base.b );
	base.t = t;

	float d = -FLT_MAX; // opI( base.p.z - h, base.dcc ) is the base block, if you want to visualize it for debug

	vec3 windr = vec3( FLT_MAX );

	{
		// front facade
		Scope facade = getScopeFacadeX( base, h, 3 );
		vec2 d1 = sd_SurfaceFacade0( facade.p, facade.p.z );
		d = opI( d1.x, d );
		windr = vec3( d1.y, vec2( 1., 0. ) );
	}

	{
		// back facade with flat windows
		Scope facade = getScopeFacadeY( base, h, 3 );
		float d2 = sd_SurfaceFacade7( facade.p, facade.p.z );
		d = opI( d2, d );
	}

	#ifdef HIGHWAY_CLIP
	if ( nh.d != FLT_MAX )
	{
		// highway facing facade using nearest highway clip plane
		float d10 = dot( p.xy - nh.o_clip, nh.n_clip ) - ROAD_HALFWIDTH * 1.3;
		vec3 pr = vec3( dot( p.xy, perp( nh.n_clip ) ), p.z, -d10 ); // pr is the point in 2d facade space
		vec2 d3 = sd_SurfaceFacade0( pr, pr.z );
		d = opI( d3.x, d );

		// pick this window if it's closest
		windr = mix( windr, vec3( d3.y, nh.n_clip ), step( abs( d3.y ), abs( windr.x ) ) );
	}
	#endif

	float droof = d; // save d before we clamped base on h, that will give us a consistent base dcc to build the roof on
	d = opI( d, base.p.z - h );

	#ifdef ROOF_OBJECTS
	{
		Scope roof = base;
		roof.p.z -= h;
		roof.dcc = droof;
		d = sd_JPBuildingRoofTopWithObjects( d, roof, roof_geom_max_height, true, rnd ); // roof with border + objects on it
	}
	#endif

	ParametricBuildingRetval ret;
	ret.d = d;
	ret.windr = windr;
	ret.droof = FLT_MAX;
	return ret;
}

// house with a tiled roof (Kyoto has lots of those, though the roof type is different and here is just a super crude abstracted version)
ParametricBuildingRetval sd_House( vec3 p, float t, bounds2 b, float h, NearestHighwayRetval nh )
{
	h -= 1.4; // fixme: hack: make sure h is bounding height instead
	vec2 inset = size( b ) * 0.01; // b is conservative, the house must be included inside it
	b.pmin += inset; // we want roof to hang over a bit so shrink the base a bit
	b.pmax -= inset;
	// some building base scope
	Scope base;
	base.p = p;
	base.b = b;
	base.dcc = sd_bounds( base.p.xy, base.b );
	base.t = t;
	// the base block, if you want to visualize it for debug
//	float d = opI( base.p.z - h, base.dcc );
	// highway facing facade clipped using nearest highway clip plane
	#ifdef HIGHWAY_CLIP
	float d10 = nh.d != FLT_MAX ? dot( p.xy - nh.o_clip, nh.n_clip ) - ROAD_HALFWIDTH * 0.6 : FLT_MAX;
	#else
	float d10 = FLT_MAX;
	#endif
	base.dcc = opI( -d10, base.dcc  ); // clip the base shape so that we still get a bit of roof hang over

	ParametricBuildingRetval ret;
	float slope_ctrl = 0.7;
	// hip roof with tiled surface
	vec3 prfx = getRoofLocalX( p, slope_ctrl, base.b, h );
	float rfxd = opS( prfx.z - hf_SurfaceRoofTiles( prfx.xy ), prfx.z - ( -0.03 ) );
	rfxd = opI( base.dcc - 0.15, rfxd ); // vertical cookie cut, wider for roof geom
	vec3 prfy = getRoofLocalY( p, slope_ctrl, base.b, h );
	float rfyd = opS( prfy.z - hf_SurfaceRoofTiles( prfy.xy ), prfy.z - ( -0.03 ) );
	rfyd = opI( base.dcc - 0.15, rfyd ); // vertical cookie cut, wider for roof geom
	// add windows
	float dbottom = opI( base.dcc, opI( prfx.z, prfy.z ) );
	Scope wall_s = getScopeFacadeY( base, h, 3 );
	vec3 pf = vec3( wall_s.p.xy * 1.0 - vec2( 0., -0.28 ), wall_s.p.z * 2. );
	vec2 df8 = sd_SurfaceFacade8( pf, dbottom );
	dbottom = opI( wall_s.dcc, df8.x ); // base + window carved in
	dbottom = opI( -d10, dbottom  ); // clip the base shape so that we still get a bit of roof hang over
	ret.windr = vec3( df8.y, vec2( 0., 1. ) );
	// hip roof + roof surface
	ret.droof = opU( opI( rfyd, prfx.z ), opI( rfxd, prfy.z ) ); // just roof surface
	ret.d = opU( ret.droof, dbottom );
	// fill the empty bit under the roof (due to hang hover modeling),
	// which is visible when we did a highway clip
	float dz = ( p.z - h ) / slope_ctrl;
	ret.d = opU( ret.d, opI( base.dcc + max( dz, 0. ), -dz ) );
	return ret;
}

// highway curve as seem from above... wanted to do more complicated but stuck to the test curve instead
vec2 sd_HighwayCurveXY( float x ) { float xt = repeat_mirror_e( x, -20., 20. ); return vec2( x, smoothstep( 0., 15., xt ) * 8. ); }
vec3 sd_CameraCurveXY( float x ) { return vec3( x, sd_HighwayCurveXY( x ).y, 2.18 ); }

// highways are repeated on y axis
NearestHighwayRetval evalHighwaySetup( vec2 p )
{
	NearestHighwayRetval hret;
	hret.p = p.xy;
	hret.pr = p.xy;
	hret.pr.y = repeat_e( hret.pr.y, -35., 35. ); // note: mirror repeat wouldn't work
	return hret;
}

// do the actual distance to highway evaluation
NearestHighwayRetval evalHighway( vec2 p )
{
	NearestHighwayRetval hret = evalHighwaySetup( p );
	vec4 ret;
	CLOSEST_POINT_TANGENT_TO_FUNC_21( ret, hret.pr.xy, sd_HighwayCurveXY, CURVE_DISTANCE_EPSILON_OF_DEATH * p.x, 2 );
	hret.d = length( ret.xy ); // distance to center line, used in several places so cache
	hret.d2f = ret;
	return hret;
}

#define HIGHWAY_HEIGHT 2.

// used for lamp top silhouette
float crochet( float x, float s2, float s1, float a, float b, float ym ) { return max( min( 0., ( -( x - b ) ) * s1 ), ym ) + min( 0., ( x - a ) * s2 ); }

// street lamp object
// hw is the road half width
// p2.xy is cross section along u
// p2.y is already symmetric (distance to center)
vec2 sd_Lamps( float u, vec2 p2, float hw, float lw, float lamp_height, float period )
{
	vec2 p3 = p2.xy - vec2( hw, lamp_height ); // center to lamp corner
	float dline = opI( -dot( p3.xy, -V60 ), p3.x ); // lamp line
	float width = 0.04; // pole width
	float dslice = sd_bounds_repeat_range_range( u, 0., period, 0., width ); // slice
	dslice = opI( dslice, -p2.y ); // keep upper bit only
	float dpolebit = opB_outside( dline, 0.015 ); // only keep outside band
	dpolebit = opI( dpolebit, -p3.x - lw ); // subtract center bit
	float shrink = 0.004;
	float dlampbit = opB_inside( dline - shrink, 0.02 ); // only keep outside band, offset by shrink to ensure lamp geom stays in contact
	dlampbit = opI( dlampbit, -p3.x - lw ); // subtract center bit
	dlampbit = opI( dlampbit, -p2.y + lamp_height * 1.025 ); // only keep bit the top lamp bit (cut bottom)
	dlampbit += shrink; // make lamp geom smaller
	float d = opU( dpolebit, dlampbit );
	d = opI( d, dslice - crochet( p3.x, 0.1, 0.75, -0.1, -0.05, -0.01 ) ); // extract a slice, and also make the slice slightly triangular
	return vec2( d, dlampbit );
}

// there will be SIGN_N-1 signs visible per period (because of clipping in curvy bits)
#define SIGN_N (3.)
// pick a periodicity that doesn't expose the dodginess of the sdf in curvy sections
#define SIGN_PERIOD (2.*20./SIGN_N)
#define LDC_HEIGHT 0.3

// highway signs (LCD screens)
vec2 sd_HighwaySigns( float u, vec2 p2, float hw )
{
	u = repeat_mirror_e( u, -20., 20. ); // same repeat as sd_HighwayCurveXY
	float period = SIGN_PERIOD;
	u += period * 0.5;
	float width = 0.04;
	float h2 = 1.2; // sign start h
	float h3 = LDC_HEIGHT; // sign end h
	float dslice = sd_bounds_repeat_range_range( u, 0., period, 0., width ); // slice
	dslice = opI( dslice, -p2.y ); // keep upper bit only
	vec2 p3 = p2.xy - vec2( hw, h2 ); // center to lamp corner
	float d8 = opB_outside( p3.x, 0.015 ); // only keep outside band
	d8 = opI( d8, p3.y );
	d8 = opU( d8, sd_bounds_range( p3, vec2( -hw, 0. ), vec2( 0.05, h3 ) ) );
	return vec2( opI( d8, dslice ), FLT_MAX );
}

#define HIGHWAY_PAVEMENT_RATIO 0.5

// ray marched city bits, this is global and has nothing to do with the dda
// return value: .x closest distance, .y closest distance to light emitter material
vec3 sd_RayMarchedCityBits( vec3 p, int lod )
{
	float d = p.z - 0.; // zero ground

	NearestHighwayRetval hret = evalHighway( p.xy );

	float hw = ROAD_HALFWIDTH; // r1 is the half width
	float h = HIGHWAY_HEIGHT;

	vec3 crvp = vec3( hret.d, p.z, ( hret.pr + hret.d2f.xy ).x ); // curve 3d pos

	float d2 = sd_bounds_range( crvp.xy, vec2( 0.0, h - 0.05 ), vec2( hw, h ) ); // highway cross section main block
	float d3 = sd_bounds_range( crvp.xy, vec2( hw * 0.9, h - 0.01 ), vec2( hw * 1.01, h + 0.2 * 1.4 ) ); // highway cross section border bit
	d = opU( d, opU_hard_bevel( d3, d2, 0.05 ) );

	// supporting column
	vec2 ppp = vec2( h - p.z, hret.d );
	float d4 = ppp.y - ( 0.2 + 0.2 * pow( 1. - saturate( ppp.x * 2. ), 4. ) );
	d4 = opI( -h + p.z, d4 );
	d4 = opI( d4, sd_bounds_repeat_range_range( crvp.z, 0., 2., 0.5, 0.9 ) ); // subtract space between supporting columns
	d =  opU( d, d4 );

	vec2 dlamps = vec2( FLT_MAX );
	vec2 dlamps2 = vec2( FLT_MAX );

	#ifdef HIGHWAY_LAMPS
	dlamps = sd_Lamps( crvp.z, vec2( hret.d, p.z - h ), hw, 0.25, 1.2, 3.2 );
	d = opU( d, dlamps.x );
	#endif
	// add billboard signs on highways
	vec2 dsigns = sd_HighwaySigns( crvp.z, vec2( hret.d, p.z - h ), hw );
	d = opU( d, dsigns.x );

	// add ground and pavements
	vec3 pp = p;
	pp.xy = repeat_mirror_l( p.xy, vec2( 0., 0. ), CELL_SIZE.xy );
	vec2 extra = -vec2( 0.15 ); // expand pavement a bit
	// for pavement we just repeat a round box with left, bottom side using wide road width and top, right sides using small road width
	float dpavement = sd_bounds_range_round( pp.xy, CELL_SPACING.yy * 0.5 + extra, CELL_SIZE.xy - CELL_SPACING.xx - extra, 0.075 );
	dpavement = opS( dpavement, ( hret.d - ROAD_HALFWIDTH * HIGHWAY_PAVEMENT_RATIO ) ); // empty the bit below the highway... that makes roadmarkings worse
	dpavement = opI_hard_bevel( dpavement, pp.z - 0.025, 0.02 ); // hard bevel to create border, clip with pavement top plane
	d = opU( dpavement, d ); // add pavement

	#ifdef WIDE_STREETS_LAMPS
	// add lamps on wide roads
	float period = CELL_SIZE.x / 5.;
	// offset by peroid/2 to avoid putting lamps on crossing road (so we don't have to mask)
	dlamps2 = sd_Lamps( p.y + period * 0.5, vec2( repeat_mirror_l( p.x, 0., CELL_SIZE.x ), p.z )
						, CELL_SPACING.x * 1.3 // go on the pavement a bit
						, 0.08, 0.65, period );
	d = opU( d, dlamps2.x );
	#endif

	return vec3( d, opU( dlamps.y, dlamps2.y ), dsigns.x );
}

vec3 l2g( vec3 v ) { return pow( v, vec3( 1. / 2.22 ) ); }
vec3 g2l( vec3 v ) { return pow( v, vec3( 2.22 ) ); }

vec3 biexp2( float x, vec4 r, vec4 g, vec4 b ) { return biexp2( x * vec3( r.x, g.x, b.x ), vec3( r.y, g.y, b.y ), vec3( r.z, g.z, b.z ) ) * vec3( r.w, g.w, b.w ); }

// manual match of one of the probes at http://cgg.mff.cuni.cz/projects/SkylightModelling/HosekWilkie_SkylightModel_SIGGRAPH2012_Supplement.pdf
vec3 get_sky( vec3 v, float sun_cos_theta, float cheat_glow_scale )
{
	vec3 l = vec3( sqrt( 1. - sun_cos_theta * sun_cos_theta ), 0., sun_cos_theta );
	float theta = safe_acos( v.z ); // in theory we don't need safe on normalized value, in practice you just never know
#if 0
	vec2 u = vec2( 0.5 ) + normalize( v.xy ) * theta / PI;
	u = -perp( u ); // sun is on +x axis
	vec3 ref = g2l( texture( iChannel0, u ).xyz );
	if ( u.x > 0.5 ) return ref; // show reference image we try to match
//	return BLUE;
#endif
	float sd = dot( v, l );
	vec3 sky_top_color = vec3( 0.0182, 0.040, 0.076 ) * 0.95; // top sky color in linear space
	vec3 sky_top = sky_top_color;
//	return ref - sky_top; // show remnant signal to match
	float x = ( 1. - theta / ( PI * 0.5 ) ) * 0.5;
	vec3 sky_radial = biexp2( x, vec4( 7.5, 15., 2., 0.1 ), vec4( 7.5, 10., 1.7, 0.14 ), vec4( 4., 5., 5.5, 0.075 ) ); // south curve
//	return ref - sky_top - sky_radial; // show remnant signal to match
	// maching the sun glow is more awkward
	vec3 sun_glow = // note: this affects lighting a lot as we sample sun center color for the main light
		spherical_gaussian( sd, vec3( 0.8, 0.6, 0.3 ) * 1., 27. ) + 
		spherical_gaussian( sd, vec3( 0.8, 0.4, 0.1 ) * 0.3, 8. );
	sun_glow *= cheat_glow_scale;
//	return sun_glow;
//	return ref - sky_top - sky_radial - sun_glow; // show remnant signal to match... should be black excepy for sun glow
	return max( vec3( 0. ), ( sky_top + sky_radial + sun_glow ) ) * 1.;
}

// align sky probe with l direction
vec3 get_sky( vec3 v, vec3 l, float cheat_glow_scale ) 
{ 
	if ( l.z != 0. ) v.xy = rotate_with_unit_vector_neg( v.xy, normalize( l.xy ) );
	return get_sky( v, l.z, cheat_glow_scale ); 
}

vec3 test_sky( vec2 fragCoord, vec3 l )
{
	vec2 u = fragCoord.xy / min( iResolution.x, iResolution.y );
	float theta = length( u - vec2( 0.5 ) ) * PI;
	float phi = calc_angle( u - vec2( 0.5 ) );
	vec3 v = zup_spherical_coords_to_vector( theta, phi );
	if ( theta > PI * 0.5 ) return MAGENTA;
	return l2g( get_sky( v, l, 1. ) );
}

// tentative japanese city building palette
vec3 get_building_palette( vec2 h )
{
	vec3 ivory = vec3( 1, 0.85, 0.7 ); // c11
	vec3 white = vec3( 1., 1., 1. ); // c01
	vec3 c = mix( mix( BLEU_ARDOISE, GRIS_ARDOISE * 0.5, h.x ), mix( white, ivory, h.x ), h.y );
//	vec3 c = mix( mix( c00, c10, h.x ), mix( c01, c11, h.x ), h.y );
	return c = mix( c, vec3( 0.6, 0.2, 0.2 ), smoothband( h.y - 0.5, 0.045, 0.01 ) * h.x * h.x * h.x ); // add rare reddish colors for occasional red tiles building
}

struct NumberArg { float h; vec2 s; float r; float w; float m; };

// only works with 3 and 8 because those are easy :-)
float sd_Number3or8( vec2 p, int num, NumberArg a )
{
	a.s *= 0.5;
	p.y = abs( p.y );
	float d = sd_bounds_range_round( p, vec2( -a.s.x + a.w + a.m, a.w * 0. ), a.s - a.w - a.m, a.r );
	d = opB_range( d, -a.w, a.w );
	if ( num == 3 ) d = opS( d, sd_bounds_range( p, vec2( -a.s.x - a.w, -a.w ), vec2( 0., a.s.y * a.h ) ) );
	return d;
}

// http://www.airbus.com/aircraft/passenger-aircraft/a350xwb-family/a350-900.html
// -10,10 -> 64m
// the silhouette is pretty accurate, modeled on top of blueprint
// in this shader it just becomes pixel vomit covering a few pixels but I couldn't let go
float sd_airliner_a350( vec2 p )
{
	p.y = abs( p.y ); // vertical symmetry
	float db1 = p.y - 0.98 * rcp_decay( max( -0.666, -( p.x - 10. ) ) ); // fuselage front
	float db2 = p.y - 0.98 * rcp_decay( max( -0.666, p.x - -7.8 ) ); // fuselage back
	float db = opI( db1, db2 ); // fuselage
	float dw1 = -( curved_max_vfunc_weld_quadric( p.x + 3.85, 0.85 ) * 2.3 - ( 9.7 - p.y ) ); // back wing curve
	float dw2 = curved_max_vfunc_weld_quadric( p.x + 3.45, 0.85 ) * 1.26 - ( 9.2 - p.y ); // front wing curve
	float d3 = -( p.x - ( -0.8 ) ); // back wing curve flat bit
	dw1 = opU( dw1, d3 );
	float dw = opI( opI( dw1, dw2 ), -( p.x + 4. ) ); // wing
	float ds = -( ( smoothstep( -6.5, -9.8, p.x ) ) * 2.55 - p.y ); // stabilizer
	ds = opI( ds, ( p.x + 6.5 ) );
	ds = opS( ds, ( p.x + 8.94 + p.y * 0.4 ) ); // final tail bit
	float dt = opI( p.x + 8., p.y - 0.45 * rcp_decay( max( -0.666, ( p.x - -9.75 ) * 1. ) ) );
	ds = opU( dt, ds ); // cut garbage
	vec2 pe = p - vec2( 1.5, 2.77 ); // engine pos
	float de = abs( pe.y ) - 0.8 * min( powerful_scurve( pe.x, 0.5, 4. ), powerful_scurve( 1. - ( pe.x - 1. ), 0.1, 4. ) ) + 0.3; // engine
	return opU( de, opU( ds, opU( dw, db ) ) );
}

#define IS_LAMP 1
#define IS_SIGN 2
#define IS_WINDOW 4
#define IS_ROOF 8

// another blob of stuff, yey
struct TraceCityRetval
{
	float t; // fixme: t or p. pick one? they might not be consistent
	vec3 p, n; // position, normal
	float ao;
	vec2 tile_index; // mostly for debug purpose
	float split_case; // split case [0,3] for coloring and randomization
	float sub_id; // children id in the 4 split
	int type;
};

#define is_equal_as_float( type, val ) (((type)!=(val))?0.:1.)

void pack_info( inout TraceCityRetval ct, vec2 tile_index, float split_case, float sub_id ) { ct.tile_index = tile_index; ct.split_case = split_case; ct.sub_id = sub_id; }
void pack_info1( inout TraceCityRetval ct, float t, vec3 p, vec3 n, float ao, int type ) { ct.t = t; ct.p = p; ct.n = n; ct.ao = ao; ct.type = type; }

// to easily make a polar coords heart, draw the heart you want, lay out r(theta) in cartesian space, and manual curve match it
float heart( float x ) { x = abs( repeat_e( x, -PI, PI ) ); return exp_decay( x * 1.2 ) * 0.7 + pow( max( x - PI * 0.5, 0. ) / ( PI * 0.5 ), 10. ) * 0.3; }

float heart_grid( vec2 sp, vec2 c )
{
	vec3 h = hash32( floor( sp / c ) );
	float s = 12. - 5. + 10. * h.z;
	vec2 sp3 = repeat( sp, c ) - c * 0.2 * h.xy;
	vec2 beat = impulse( vec2( 10. ), repeat( vec2( iTime, iTime + 0.08 ), vec2( 1.2 ) ) );
	float r = length( ( sp3 - c * 0.5 ) / ( 1. + beat * vec2( 0.3, 0.4 ) ) );
	float l = heart( calc_angle( sp3 - c * 0.5 ) );
	return step( r, l * s );
}

// ika is japanese for squid
float ika( vec2 p, float anim )
{
	vec2 p2 = p.xy;
	p2.y += 0.25;
	p2.x = abs( p.x );
	float d = opI_soft2( dot( p2 - vec2( 0., 1. ), V45 ), -p2.y - 0.1, 6. );
	d = opI_soft2( d, p2.y - 1., 10. );
	float a = calc_angle( p.xy );
	float r = length( p.xy );
	a = abs( repeat_e( a, -PI * 0.5, PI * 0.5 ) );
	float d3 = r - ( 0.3 + spherical_gaussian( cos( a - PI * mix( 0.4, 0.5, anim ) ), 0.8, 40. )
					 + spherical_gaussian( cos( a - PI * mix( 0.1, 0.4, anim ) ), 1.1, 40. ) );
	d3 = opI_soft2( p2.y, d3, 8. );
	d = opU( d, d3 );
	d = opS( d, length( ( p2 - vec2( 0.2 - anim * 0.075, 0.15 ) ) * vec2( 1. + anim * 0.5, 1. ) ) - 0.16 * ( 1. + anim * 0.4 ) ); // eyes
	return d;
}

float ika_grid( vec2 sp, float anim, vec2 c ) { return ika( repeat_e( sp, -c, c ) * 0.1, 1. - anim ); }

float star( vec2 p )
{
	vec2 n = normalize( vec2( 1., 0.4 ) ); // slope controls
	p.x = abs( p.x );
	p = fold( p, vec2( 0. ), vec2( -0.309016994, 0.951056516 ) ); // perp(90-72=18)
	p = fold( p, vec2( 0. ), vec2( -0.809016994, 0.587785252 ) ); // perp(90-72/2=54)
	vec2 v = p - vec2( 0., 1 );
	return opI( dot( v, n ), dot( v, vec2( -n.x, n.y ) ) );
}

float star_trail( vec2 p, out vec2 uv )
{
	p = rotate_with_angle( p, radians( -25. ) * p.x );
	p.y *= exp( p.x * 2. );
	p.x *= exp( p.y * 1. );
	vec2 pmin = vec2( -0.4, -0.1 );
	vec2 pmax = vec2( 0.4, 0.1 );
	uv = ( p - pmin ) / ( pmax - pmin );
	return sd_bounds_range( p, pmin, pmax );
}

void surfaceColor( TraceCityRetval ct, inout vec3 albedo, inout vec3 emitter, inout float road_marking_material )
{
	if (  ct.type == IS_ROOF ) albedo = max( vec3( 0. ), contrast( albedo, vec3( 1.75 ) ) ); // enhance disparity of roof colors

	float aa = 0.003; // sorry...
	NearestHighwayRetval nh;
	float is_highway_columns_zone = 0.; // just columns
	float d_pavement_below_highway = FLT_MAX;
	float d_highway_columns_zone = FLT_MAX;

	if ( ( ct.sub_id == TYPE_HIGHWAY ) || ( ct.sub_id == TYPE_ROAD ) )
	{
		nh = evalHighway( ct.p.xy );
		d_pavement_below_highway = nh.d - ROAD_HALFWIDTH * HIGHWAY_PAVEMENT_RATIO;
		d_highway_columns_zone = nh.d - ROAD_HALFWIDTH * 0.25;
		is_highway_columns_zone = smoothstep_c( -d_highway_columns_zone, 0., 0.005 ); // account for the bevel (mask of road flat bit)
	}

	vec3 road_base_color0 = vec3( 0.5, 0.53, 0.65 );

	if ( ( ct.sub_id == TYPE_HIGHWAY ) && true )
	{
		// roadmarkings on top of highway

		float hd = nh.d - ROAD_HALFWIDTH;
		float highway_road_bit_mask = 1. - smoothstep_c( nh.d, ROAD_HALFWIDTH - 0.2, 0.005 ); // account for the bevel (mask of road flat bit)

		vec2 u = ( nh.pr + nh.d2f.xy ); // works better
		u.y = nh.d;
		float snhd = nh.d * sign( nh.d2f.y ); // signed distance accross road when we need to distinguish ledft/right

		float curvature = smin_pol( abs( nh.d2f.w ) * 1.2, 1., 0.5 );

		float diagstripes0 = step( ( ROAD_HALFWIDTH * 0.9 - nh.d ) * sign( nh.d2f.y ), curvature );
		float diagstripes = diagstripes0 * smoothband( snhd, ROAD_HALFWIDTH * 0.1, ROAD_HALFWIDTH * 0.7, 0.005 ); // select road v band, sign( nh.d2f.y ) tells us which side of the road we are on

/// a few aliases - all those operate on floats
		#define SYMLINES(c,r) ( smoothband( abs( u.y ) - ROAD_WIDTH * c, r, aa ) )
		#define STRIPES(_k,period,len) ( stripes( u._k, period, len, aa ) )
		#define STRIPES2(_k,period,len) ( stripes2( u._k, period, len, aa ) )
		#define DIAGONALSTRIPES(period,len) ( stripes( u.x + hd * sign( nh.d2f.y ) * 1.5, period,len, aa ) )
		#define DOTTEDLINE(r,period,len) ( smoothband( u.y, r, aa ) * STRIPES2( x, period, len ) )
		#define ARROWS(center,period,len,width,slope) ( ( stripes2( u.x - fold(snhd, ROAD_WIDTH*(center))*(slope), period,len, aa ) ) * smoothband( snhd- ROAD_WIDTH*(center), (width)*0.5, aa ) )
		#define ADD( _col, _factor ) albedo_markings = mix( albedo_markings, _col, _factor )

		vec3 road_marking_color_white = vec3( 1. ) * 3.;
		vec3 road_marking_color_yellow = vec3( 1., 1., 0. ) * 2.;
		vec3 albedo_markings = vec3( 0. );

		ADD( road_marking_color_white, SYMLINES( 0.18, 0.016 ) * STRIPES2( x, 0.4, 0.1 ) * ( 1. - diagstripes ) );
		ADD( mix( road_marking_color_yellow, road_marking_color_white, 1. ), highway_road_bit_mask * STRIPES( y, 0.75, 0.016 ) * ( 1. - diagstripes ) );

		// the wide warning stripes
		ADD( road_marking_color_white, diagstripes * DIAGONALSTRIPES(  0.15 * 1.8, 0.05 ) );
		ADD( road_marking_color_white, ARROWS( -0.28, 0.4 * 16., 0.1 * 12., 0.24, 0.5 ) * ARROWS( -0.28, 0.4, 0.1, 0.24, 0.5 ) * ( 1. - diagstripes ) );

		{
			// highway road marking number
			vec2 np = ( ct.p.xy ); // vec2( u.x, nh.d2f.y );
			np.x = repeat_e( np.x, -20., 20. );
			np = ( perp( np ) + vec2( 0.25, 9. ) ) * vec2( 3.5, 0.75 );
			NumberArg args;
			args.h = 0.7;
			args.s = vec2( 1., 2. ) * 0.5;
			args.r = 0.1;
			args.w = 0.045;
			args.m = 0.025;
			float dn = sd_Number3or8( np, 8, args );
			dn = opU( dn, sd_Number3or8( np + vec2( -args.s.x * 1., 0. ), 3, args ) );
			if ( sign( nh.d2f.y ) > 0. ) dn = FLT_MAX;
			ADD( road_marking_color_yellow, smoothstep( aa, -aa, dn ) );
		}

		// make sure roadmarkings are only on top highway surface
		float space_filter = step( HIGHWAY_HEIGHT, ct.p.z ) // must be above highway height
			* step( 0., ct.n.z ) // surface must be pointing up
			* step( ct.p.z, HIGHWAY_HEIGHT + 0.5 ); // not higher than highway border walls

		{
			float blend = maxcomp( albedo_markings ) * space_filter;
			albedo = mix( albedo, min( albedo_markings + road_base_color0 * 0.70, vec3( 1. ) ), blend );
			road_marking_material = max( road_marking_material, blend );
		}

		#ifdef LCD_PANELS
		if ( ct.type == IS_SIGN )
		{
			// render stuff on LCD panels... shadertoy within shadertoy, hehe
			albedo_markings = vec3( 0. );

			float h2 = 1.2; // sign start h
			float h3 = LDC_HEIGHT; // sign end h

			if ( ct.p.z > HIGHWAY_HEIGHT + h2 - 0.0  )
			{
				float screenpixel = 0.01; // highway panel pizel size, in world size
				vec2 gp = ct.p.yz;
				gp.x = snhd;
				gp.y -= ( HIGHWAY_HEIGHT + h2 ); // make botton line be pixel coord y=0

				float d = sd_bounds_repeat_size_margin( gp, vec2( screenpixel ), vec2( 0.001 ) );
				float margin = step( d, 0. );

				// I don't AA properly because I suck, but at least tone the grid down
				margin = mix( margin, 1., ( 1. - exp( -max( ct.t - 6., 0. ) ) * 0.7 ) );

				vec2 sp = floor( gp / screenpixel ); // screen pixel

				// bottom margin x top margin x sides component
				float is_ldc_surface = step( 1., sp.y ) * step( sp.y, floor( LDC_HEIGHT / screenpixel ) - 2. ) * step( 0.5, abs( ct.n.x ) );

				margin *= is_ldc_surface;

				float index = floor( u.x / SIGN_PERIOD ); // same repeat as sd_HighwaySigns
				index = mod( index, 4. );

				#define ADD_EMITTER(c,v) emitter+=(c)*(v)*margin*1.;

				if ( index == 0.  )
				{
					// airliners
					vec2 c = vec2( 110., 110. );
					vec2 sp3 = rotate_with_unit_vector( sp, -V60 ) + vec2( -iTime * 100., 0. );
					sp3 = repeat( sp3, c );
					float d3 = sd_airliner_a350( ( sp3 - c * 0.5 ) * 0.2 );
					ADD_EMITTER( vec3( 1. ), step( d3, 0. ) );
				}
				else if ( index == 1.  )
				{
					// hearts
					float hg = heart_grid( -perp( sp ) + vec2( sin( iTime * 3. ) * 8., 6. + iTime * 40. ), vec2( 32., 40. ) );
					ADD_EMITTER( vec3( 1., 0., 0. ), hg );
					float hg2 = heart_grid( ( rotate_with_unit_vector( -sp, V45 ) * 2. ) + vec2( -iTime * 18., 6. ), vec2( 30., 30. ) );
					ADD_EMITTER( vec3( 0., 1., 1. ), hg2 * ( 1. - hg ) );
				}
				else if ( index == 2.  )
				{
					// rainbow stars
					vec2 sp3 = sp;
					sp3 *= 1.;
					sp3.y -= 100.;
					sp3 = rotate_with_angle( sp3, iTime );
					float a = calc_angle( sp3 );
					float r = length( sp3 );
					float r0 = 30.;
					float arclen0 = r0 * 2.; // use a rough sie ratio
					float ri = floor( r / r0 );
					float R = ri * r0;
					float numarc = floor( 2. * PI * R / arclen0 );
					float da = ( 2. * PI / numarc );
					float dai = floor( a / da );
					vec2 y = unit_vector2( da * ( dai + 0.5 ) );
					vec2 x = -perp( y );
					vec2 c = y * ( ri + 0.5 ) * r0;
					sp3 = vec2( dot( x, sp3 - c ), dot( y, sp3 - c ) );
					sp3 *= 0.025;
					sp3.y = -sp3.y;
					float d1 = star( sp3.xy * 3. );
					vec2 trail_uv;
					float d2 = star_trail( sp3.xy - vec2( -0.6, -0.1 ), trail_uv );
					vec3 rainbow = hsv2rgb( vec3( trail_uv.y, 1., 1. ) );
					vec3 c2 = vec3( 0. );
					if ( d2 < 0. ) c2 = rainbow;
					if ( d1 < 0. ) c2 = vec3( 1., 1., 0. );
					ADD_EMITTER( c2, max( step( d1, 0. ), step( d2, 0. ) ) );
				}
				else if ( index == 3.  )
				{
					// 2 layers of swimming squids or something
					float anim1 = ( sin( iTime * 8. ) + 1. ) * 0.5;
					vec2 sp1 = rotate_with_unit_vector( sp, -V45 ) + vec2( 0., 18. - iTime * 20. + anim1 * 4. );
					float l1 = step( ika_grid( sp1, anim1, vec2( 15., 15. ) ), 0. );
					ADD_EMITTER( vec3( 0., 1., 1. ), l1 );
					float anim2 = ( sin( iTime * 9. ) + 1. ) * 0.5;
					vec2 sp2 = rotate_with_unit_vector( sp, -V45 ) + vec2( 5., 9. - iTime * 35. + anim1 * 4. );
					float l2 = step( ika_grid( sp2, anim2, vec2( 40., 40. ) ), 0. );
					ADD_EMITTER( vec3( 1., 0., 0. ), l2 * ( 1. - l1 ) );
				}

				albedo = mix( albedo, albedo * 0.3, is_ldc_surface );
			}
		}
		#endif
	}

	if ( ( ct.sub_id == TYPE_ROAD ) && true )
	{
		// regular streets road markings
		NearestHighwayRetval nh = evalHighway( ct.p.xy );
		vec2 pp = repeat_mirror_l( ct.p.xy, vec2( 0., 0. ), CELL_SIZE.xy ); // road cells
		vec2 extra = -vec2( 0.15 );
		vec2 mina = CELL_SPACING.yy * 0.5 + extra;
		vec2 minb = CELL_SIZE.xy - CELL_SPACING.xx - extra;
		float d1 = sd_bounds_range_round( pp, mina, minb, 0.075 );
		float is_pure_road = step( 0., d1 );
		d1 = opS( d1, d_pavement_below_highway ); // empty the bit below the highway
		float is_road_or_below_highway_road = step( 0., d1 );
		vec2 is_wide_road = step( pp, mina );
		vec2 is_small_road = step( minb, pp );
		float is_wide_road_crossing = is_wide_road.x * is_wide_road.y;
		float is_small_road_crossing = is_small_road.x * is_small_road.y;
		float is_small_wide_road_crossing =  min( is_wide_road.x * is_small_road.y + is_wide_road.y * is_small_road.x, 1. );
		float crossing = min( is_small_road_crossing + is_wide_road_crossing + is_small_wide_road_crossing, 1. );
		vec3 road_marking_color_white = vec3( 1. ) * 2.;
		vec3 road_marking_color_yellow = vec3( 1., 1., 0. ) * 2.;
		vec3 albedo_markings = vec3( 0. );
		// white lines all around
		ADD( road_marking_color_white, smoothband( d1, 0.05, 0.05 + 0.02, aa ) );
		// wide roads markings
		ADD( road_marking_color_white, smoothband( pp.x, 0.01, aa ) * is_wide_road.x * ( 1. - crossing ) ); //DOTTEDLINE
		ADD( road_marking_color_white, smoothband( pp.y, 0.01, aa ) * is_wide_road.y * ( 1. - crossing ) ); //DOTTEDLINE
		// small road markings
		ADD( road_marking_color_white, smoothband( pp.x - CELL_SIZE.x, 0.01, aa ) * stripes( pp.y - CELL_SIZE.y, 0.2, 0.05, aa ) * ( 1. - crossing ) ); //DOTTEDLINE
		ADD( road_marking_color_white, smoothband( pp.y - CELL_SIZE.y, 0.01, aa ) * stripes( pp.x - CELL_SIZE.x, 0.2, 0.05, aa ) * ( 1. - crossing ) ); //DOTTEDLINE
		// yellow strips alongside highway columns
		ADD( road_marking_color_yellow, smoothband( d_highway_columns_zone, 0.05, aa )* ( 1. - is_wide_road.x ) * ( 1. - is_small_road.x ) );

		{
			// pedestrian crossings on large roads
			float crossing_width = 0.24;
			float dd = 0.5; // where do start crossing from
			vec2 pedestrian_crossingmask = stripes( pp - ( mina + vec2( dd ) ), minb - mina - vec2( dd ) * 2., vec2( crossing_width ), vec2( aa ) );
			vec2 pedestrian_crossingmask2 = stripes( pp - ( mina + vec2( dd ) ), minb - mina - vec2( dd ) * 2., vec2( crossing_width * 1.2 ), vec2( aa ) );
			pedestrian_crossingmask *= is_pure_road * ( 1. - is_highway_columns_zone );
			pedestrian_crossingmask2 *= is_pure_road * ( 1. - is_highway_columns_zone );
			albedo_markings *= ( 1. - pedestrian_crossingmask2.x ) * ( 1. - pedestrian_crossingmask2.y );
			ADD( road_marking_color_white, stripes( pp.y, 0.1, 0.025, aa ) * pedestrian_crossingmask.x );
			ADD( road_marking_color_white, stripes( pp.x, 0.1, 0.025, aa ) * pedestrian_crossingmask.y );
		}

		float blend = maxcomp( albedo_markings ) * is_road_or_below_highway_road * ( 1. - is_highway_columns_zone );
		albedo = mix( albedo, min( albedo_markings + road_base_color0 * 0.75, vec3( 1. ) ), blend );
		road_marking_material = max( road_marking_material, blend );
	}
}

vec3 shadeCity( TraceCityRetval ct, vec3 e, vec3 v, vec3 l, float shadow
				, float airliner, float a_contrast, vec2 uv, float aspect, float ground_ao )
{
	vec3 col = vec3( 0. );
	vec3 emitter = vec3( 0. );

	float is_sky = is_equal_as_float( ct.sub_id, TYPE_SKY );

#ifdef HORIZON_HACK
	// hack stretch sky horizon so it matches our trace horizon (means the sun position won't quite match with real sun position)
	float gamma = -e.z / MAX_DDA_TRACE; //=cos(PI/2.+beta)=sin(beta), beta is the extra angle that goes into the ground
	float alpha = -1. / ( gamma - 1. );
	vec3 v_hacked = vec3( v.xy, 1. + ( v.z - 1. ) * mix( alpha, 1., 0. ) ); // mix control how much hack correction (alpha) we want on horizon
	vec3 skycol_view = get_sky( normalize( v_hacked ), l, 0.4 );
#else
	vec3 skycol_view = get_sky( v, l, 0.4 );
#endif
//	if ( ct.t > MAX_DDA_TRACE ) return GREEN;

	// sun disk
	float sun0 = dot( l, v );

	if ( ct.sub_id == TYPE_SKY )
	{
		col = skycol_view;

		// we don't need to add a disk... let get_sky do it (also we messed with horizon and therefore sun position)
//		col += vec3( pow( sun, 20. ) * is_sky * 100. ); // sun disk (not flare/not glow, just the sun disk)

		float d_airliners = 1. - pow( max( 0., sun0 ), 8. ); // airliners
		col = mix( col, vec3( airliner ) + d_airliners * skycol_view * 2., airliner * 0.5 );

		#ifdef DEBUG_COLORING
		col = vec3( 0.0,0.1,0.8 );
		#endif
	}
	else
	{
		ivec4 ch = ivec4( ct.split_case, ct.sub_id, ct.tile_index );
		vec3 albedo = get_building_palette( hash24_( ch ) * mix( 1., 0.2, is_equal_as_float( ct.type, IS_ROOF ) ) ); // roof tiles use bottom left part of the 2d palette (ardoise)

		float road_marking_material = 0.;
		surfaceColor( ct, albedo, emitter, road_marking_material );

		#ifdef DEBUG_COLORING
		if ( ct.type == IS_WINDOW ) return vec3( 0.7 );
		if ( ct.type == IS_LAMP ) return vec3( 1., 1., 0. );
		if ( ct.type == IS_ROOF ) return BLEU_ARDOISE;
		if ( ct.type == IS_SIGN ) return vec3( 0., 1., 1. );
		return mix( albedo, hash44_( ch ).xyz, 0.5 );
		#endif

		float kdiffuse = mix( 0.75, 1., road_marking_material );
		float kspecular = mix( 0.15, 0.8, road_marking_material ) * shadow;
		float roughness = mix( 0.62, 0.1, road_marking_material );

		if ( ct.type == IS_ROOF ) { kspecular = 0.7; roughness = 0.2; }

		float Li_sky_color_saturation = 0.65; // how much we blend sky color in

		vec3 skycol_top = get_sky( vec3( 0., 0., 1. ), l, 1. );
		vec3 skycol_sun = get_sky( l, l, 1. );

		vec3 lr = vec3( -l.xy, l.z ); // sun light reflected from buildings from behind ("1 bounce")
		vec3 l2 = vec3( perp( l.xy ), l.z );
		vec3 l3 = vec3( -l2.xy, l.z );

		vec3 Li_sky_top = mix( skycol_top, vec3( luminance( skycol_top ) ), Li_sky_color_saturation );

		float s2 = mix( 0.8, 1., shadow );
#if 1
		// only add ambient on shadows
		col += 0.005 * ( 1. - shadow );
#endif
#if 1
		// skydome top light (highlights rooftops, too)
		col += s2 * add_light_contrib( albedo, vec3( 0., 0., 1. ), ct.n, -v, Li_sky_top, 5., kdiffuse, kspecular, roughness );
#endif
#if 1
		// a couple of lateral directions, pretend Li_sky_top, this works well for our axis aligned scene...
		col += s2 * add_light_contrib( albedo, l2, ct.n, -v, Li_sky_top, 1., kdiffuse, 0., roughness );
		col += s2 * add_light_contrib( albedo, l3, ct.n, -v, Li_sky_top, 1., kdiffuse, 0., roughness );
#endif
#if 1
		// sun light reflected by "buildings from behind" (1 bounce-ish) tip from iq's https://iquilezles.org/articles/outdoorslighting
		vec3 Li_sky_sun_back = 0.2 * mix( skycol_sun, vec3( luminance( skycol_sun ) ), Li_sky_color_saturation );
		// fade the highest positions as they don't get that much reflected light as there are no taller buildings, also that gives a bit of gradient
		Li_sky_sun_back *= 1. - min( ct.p.z / ( MAX_BUILDING_HEIGHT * 0.8 ), 1. );
		col += s2 * add_light_contrib( albedo, lr, ct.n, -v, Li_sky_sun_back, 0.5, kdiffuse, .0, roughness );
#endif
#if 1
		#ifdef AO
		col *= ct.ao * ct.ao * ct.ao * mix( ground_ao, 1., exp_decay( ct.p.z * 0.5 ) ); // we add a simple vertical occlusion term in addition to he marched ao
		#endif
#endif
#if 1
		// direct sun light (post ao!)
		vec3 Li_sky_sun_front = mix( skycol_sun, vec3( luminance( skycol_sun ) ), Li_sky_color_saturation );
		col += shadow * add_light_contrib( albedo, l, ct.n, -v, Li_sky_sun_front, 1., kdiffuse, kspecular, roughness );
#endif
//		col = mix( vec3( 1., 0., 0. ), col, shadow );

		if ( ct.type == IS_WINDOW )
		{
			vec3 vr = reflect( v, ct.n );

			 // windows sky reflections, assumes sky fades to black in lower hemisphere
			col += get_sky( vr, l, 1. ) * mix( 0.5, 1., shadow );

			#if 0
			// extra sun disk/glow? (get_sky has no sun disk)
			float sun1 = dot( l, vr ); // note: not hemisphere clamped
			col += skycol_sun * vec3( pow( ( sun1 + 1. )* 0.5, 70. ) )* mix( 0.15,1.f,shadow );
			#endif

			// make windows a bit reflective in bottom hemisphere too
			// just reflect a constant "ground color", fading with distance
			#ifdef WINDOWS_GROUND_REFLECTION
			if ( v.z < 0. )
			{
				float wt = plane_trace_z( mkray( e, vr ), 0., 1.e-6 );
				if ( wt > 0. && wt != FLT_MAX )
				{
//					col += RED * exp( -wt * 0.09 ); // red is kind of cool too :-)
					col += BLEU_ARDOISE * exp( -wt * 0.09 ) * 0.25; // reflect a city ground color, maybe this gradient could be a function of building height
				}
			}
			#endif

			// upper hemisphere window reflections (sky and office neon)
			#ifdef OFFICE_NEON
			if ( v.z > 0. )
			{
				// cheap but efficient neon hack
				Ray vr = mkray( e, v );
				float wt = plane_trace_z( vr, ceil( ct.p.z / FLOOR_HEIGHT ) * FLOOR_HEIGHT, 1.e-6 ); // infinite neon plane
				if ( wt > 0. && wt != FLT_MAX )
				{
					vec3 wp = vr.o + vr.d * wt;
					float neondepth = dot( ct.p - wp, ct.n );
					vec2 y = normalize( ct.n.xy );
					vec2 x = -perp( y );
					float dneon = sd_bounds_repeat_range_range( wp.x * x + wp.y * y, vec2( 0., 0. ), vec2( 0.8, 0.3 ) // neon periodicity
																, vec2( 0., 0. ), vec2( 0.34, 0.05 ) ); // neon size
					col += step( dneon, 0. ) * exp2( -neondepth * 2.8 );
				}
			}
			#endif
		}

		col += is_equal_as_float( ct.type, IS_LAMP ) * 0.9;
		col += emitter;

//		vec3 fog_color = mix( RED, GREEN, pow( ( sun0 + 1. ) * 0.5, mix( 7., 40., shadow ) ) );
		vec3 fog_color = mix( skycol_top * 1.5, skycol_sun, pow( ( sun0 + 1. ) * 0.5, mix( 7., 5., shadow ) ) ); // skycol_top color is a bit weak so boost it a bit
		col += fog_color * 0.55 * exp_decay( ct.t * 0.002 + ct.p.z * 0.007  ); // some kind of inscatter (so we add), along view distance and world height

		col = mix( col, skycol_view, smoothstep( FADE_START, MAX_DDA_TRACE, ct.t ) ); // fade with background

//		if ( ct.t > FADE_START ) return RED;
//		return skycol_view;
//		return skycol_top * 8.;
//		return skycol_sun;
//		return col;
	}

	col = 3.5 * tonemap_reinhard( col ); // expose
//	col = max( vec3( 0. ), contrast( col, vec3( a_contrast ) ) ); // post process
	col *= .2 + 0.8 * pow( 20. * uv.x * uv.y * ( 1. - uv.x ) * ( 1. - uv.y ), 0.075 ); // vignette
	col = gamma_correction_itu( col );

//	if ( v.z < 0. ) col = RED; // view real horizon

	return col;
}

// building heights distribution function
vec4 icdf( vec4 x ) { return mix( saturate( safe_acos( vec4( 1. ) - 4. * x ) / PI ), (x - vec4( 0.5 )) * 0.1, step( 0.5, x ) ); }

ParametricBuildingRetval sd_ParametricBuilding( float t, vec3 p, float building_type, bounds2 b2, float height, NearestHighwayRetval nh, vec3 rnd )
{
	if ( building_type == 0. ) return sd_House( p, t, b2, min( height, HIGHWAY_HEIGHT ), nh );
	return sd_Building( t, p, b2, height, nh, rnd );
}

struct ParametricBuildingHit
{
	float t;
	float tile_child_index;
	float building_type; // 0:house 1:building (could use 0. and 4. instead)
	float height;
	bounds2 b2;
	float d;
	vec3 windr;
	float is_roof;
	Ray ray2; // potentially permuted ray
	bool permuted;
	NearestHighwayRetval nh;
	vec3 rnd;
};

void rayMarchParametricBuilding( Ray ray2, bool permuted, vec2 ri, bounds3 bi, float kk, inout ParametricBuildingHit hit, vec2 cell_index )
{
	if ( ri.y <= ri.x || ri.y < 0. ) return; // no hit

	ri.x = max( ri.x, 0. );

	// warning: if you fiddle with early return here, check what happens to the shadow term!

	bounds2 b2 = mkbounds_unchecked( bi.pmin.xy, bi.pmax.xy ); // b2 is in maybe permuted space and contains the object

	vec2 base_size = size( b2 ); // this is the base size with x and y maybe permuted

//	if ( base_size.x <= 0. || base_size.y <= 0. ) return; // doesn't seem to contribute to the image... and is slower?

	NearestHighwayRetval nh;

	nh.d = FLT_MAX; // disable the clip plane

	#ifdef HIGHWAY_CLIP
	#ifdef HIGHWAYS
	{
		// some basic layout intersection tests outside marching loop... tedious block of code

		vec2 b2c = center( b2 );
		vec2 b2s = base_size; // size( b2 )

		if ( permuted ) // remember: b2 is in permuted space, dont use it in calculations below
		{
			b2c = b2c.yx; // back to world
			b2s = b2s.yx;
		}

		nh = evalHighway( b2c );

		nh.o_clip = nh.p + nh.d2f.xy; // closest highway center line point (b2c==nh.p)
		nh.n_clip = normalize( perp( nh.d2f.zw ) ); // can't use hret2.d2f.xy as it may be null

//		float b2cd = dot( b2c - nh.o_clip, nh.n_clip ); // distance to higway center line, signed
		float b2cd = dot( -nh.d2f.xy, nh.n_clip ); // should be same as above, saves a sub (lol)

		nh.n_clip *= sign( b2cd ); // orient the clip normal so we can build a facade (box center is on positive side)

		b2cd = abs( b2cd ); // now we are on the positive side

		float ml = length( b2s );

		if ( b2cd > ( ml + ROAD_WIDTH ) * 0.5 ) nh.d = FLT_MAX; // building far away enough regardless of rotation, disable the clip plane
		#ifdef TRY_BALANCE_SIZES
		else 
		{
			float l = b2s.y; // (fixme: corrected with slope) if we can assume horizonal ish roads
			float clipped_l = ( b2cd + l * 0.5 ) - max( b2cd - l * 0.5, ROAD_HALFWIDTH ); // size left after clipping

			base_size = b2s;
			base_size.y = clipped_l;

			// if the building was ultra thin to begin with, clipping is not going to make things any better
			// that filters out some garbage thin buildings
			if ( maxcomp( base_size ) > 10. * mincomp( base_size ) ) return;
		}
		#endif

//		nh.d = FLT_MAX; // uncomment to check actual size of building if they weren't clipped

		if ( permuted )
		{
			// back to permuted space
			nh.p = nh.p.yx;
			nh.pr = nh.pr.yx;
			nh.d2f = nh.d2f.yxwz;
			nh.n_clip = nh.n_clip.yx;
			nh.o_clip = nh.o_clip.yx;
		}
	}
	#endif
	#endif

	float height = bi.pmax.z; // pmax.z awkward?

	// make height not bigger than n times the smallest dimension on the 2d base, not that base_size may be permuted, we only care about the min dimension
	#ifdef TRY_BALANCE_SIZES
	height = min( height, 8. * mincomp( base_size ) );
	#endif

	float building_type = height < 3.4 ? 0. : 1.;

	if ( building_type == 1. ) height = ( 0.5 + floor( height / FLOOR_HEIGHT - 0.5 ) ) * FLOOR_HEIGHT; // make building height a multiple of floor height

	float t = ri.x; // start marching from first hit point

	vec3 rnd = vec3( cell_index, kk );

	for ( int j = 0; j < DDA_CELL_SDF_MARCH_MAX_ITERATIONS FORCE_LOOP_LV3; ++j )
	{
#ifdef ENABLE_MAX_DDA_TRACE_DISTANCE
		// no need to trace further than max cell size == massive win
		// we then have to pick a max trace distance, for that cell 2d diagonal size would be a start
		// but since cell height is higher than max building height, we use max building height instead
		if ( t - ri.x > MAX_BUILDING_HEIGHT ) break;
#endif

		vec3 p = ray2.o + t * ray2.d;

		ParametricBuildingRetval ddd = sd_ParametricBuilding( t, p, building_type, b2, height, nh, rnd );
		float d = ddd.d;

		if ( abs( d ) <= 0.001 * t )
		{
			if ( t < hit.t ) // we need to check vs other objects in the cell
			{
				// record a few things we need to do extra evals deriving from the final hit
				hit.t = t;
				hit.tile_child_index = kk;
				hit.building_type = building_type;
				hit.b2 = b2;
				hit.height = height;
				hit.d = d;
				hit.windr = ddd.windr;
				hit.is_roof = step( abs( d - ddd.droof ), 0.001 );
				hit.ray2 = ray2;
				hit.permuted = permuted;
				hit.nh = nh;
				hit.rnd = rnd;
			}

			break; // "return" is slower on radeon: 29ms -> 31ms (ancient wip timings)
		}

		float dt = d;
//		float dt = d * TFRAC; // shadows a bit better with this
//		float dt = abs( d ); // *TFRAC // only move forward (see inside of buildings...)

		t += dt;
//		p += dt * ray2.d; // do not do this, instead increment t and reevaluate p fully (loss of precision else)
	}
}

void rayMarchCellObjects( Ray ray2, Ranges_x4 iv, bool permuted, inout ParametricBuildingHit hit, vec2 cell_index, bool shadow_trace )
{
#ifdef DEBUG_BUILDINGS_BOUNDS

	#define BLD_BOX( rX, bX, idval ) \
	if ( iv.rX.y > iv.rX.x && hit.t > iv.rX.x && iv.rX.x > 0. ) \
	{ \
		hit.t = iv.rX.x; \
		/*b4 = iv.bX;*/ \
		hit.tile_child_index = idval; \
		hit.ray2 = ray2; \
		hit.permuted = permuted; \
	}

	BLD_BOX( rA, bA, 0. )
	BLD_BOX( rB, bB, 1. )
	BLD_BOX( rC, bC, 2. )
	BLD_BOX( rD, bD, 3. )
	
#else
	
#ifndef UNROLL_LOOP2
/// same cost as manually unroll (stable 29ms, vs 28,29ms for manually unrolled, old wip figures)
/// would like to also try prevent unroll but...
	vec2 ranges[4] = vec2[4]( iv.rA, iv.rB, iv.rC, iv.rD );
	bounds3 b4s[4] = bounds3[4]( iv.bA, iv.bB, iv.bC, iv.bD );
	for ( int i = 0; i< ( 4 FORCE_LOOP_LV2 ); ++i )
	{
		rayMarchParametricBuilding( ray2, permuted, ranges[i], b4s[i], float( i ), hit, cell_index );
	}
#else
	// manual unroll 74ms -> 69ms old radeon :-/ (old wip figures)
	rayMarchParametricBuilding( ray2, permuted, iv.rA, iv.bA, 0., hit, cell_index );
	if ( !SHADOW_EARLY_RET( hit.t ) ) rayMarchParametricBuilding( ray2, permuted, iv.rB, iv.bB, 1., hit, cell_index );
	if ( !SHADOW_EARLY_RET( hit.t ) ) rayMarchParametricBuilding( ray2, permuted, iv.rC, iv.bC, 2., hit, cell_index );
	if ( !SHADOW_EARLY_RET( hit.t ) ) rayMarchParametricBuilding( ray2, permuted, iv.rD, iv.bD, 3., hit, cell_index );
#endif

#endif
}

// ray march buildings in a cell
void traceBuildings( Ray a_ray, inout TraceCityRetval ct, float split_cells_spacing, bool shadow_trace )
{
	float maxh = MAX_BUILDING_HEIGHT;
	float minh = 2.;

	float rmin = -0.1;
	float rmax = max( 1., maxh );

	// we only dda trace the rmin, rmax z range
	float tbottom = plane_trace_z( a_ray, rmin, 1e-6 );
	float ttop = plane_trace_z( a_ray, rmax, 1e-6 );

	vec2 r0 = vec2( 0., MAX_DDA_TRACE );
	vec2 r1 = vec2( min( ttop, tbottom ), max( ttop, tbottom ) );
	vec2 r2 = vec2( max( r0.x, r1.x ), min( r0.y, r1.y ) ); // intersection of r0 and r1

//	if ( r2.y <= r2.x ) return; // non sensical per drop if we return...
	r2 *= step( r2.x, r2.y ); // ...so instead do a zero length iteration

	float start_t = r2.x; // remember initial jump to return something along a_ray

	Ray ray = mkray( a_ray.o + a_ray.d * start_t, a_ray.d ); // warp to tmin
	vec3 ray_end = a_ray.o + a_ray.d * r2.y;

	DDA3 dda = dda_init( ray.o, ray_end, CELL_SIZE, false );

	// trace within dda traversed cell
	ParametricBuildingHit hit;
	hit.t = FLT_MAX;
	float split_case = -1.;

	// dda traverse
	for ( int i = 0; i < ( MAX_DDA_ITER FORCE_LOOP_LV1 )
		  && dot( dda.p - a_ray.o, dda.p - a_ray.o ) < r2.y * r2.y; ++i )
	{
		// raytrace 4 boxes inside each cell
		bounds2 b = mkbounds_unchecked( dda.c.xy * CELL_SIZE.xy, ( dda.c.xy + vec2( 1., 1. ) ) * CELL_SIZE.xy ); // cell bounds
		ivec2 index = ivec2( dda.c.xy );
		vec4 a; a.xy = CELL_SPACING.xy * 0.5; a.zw = a.xy;
		if ( ( index.x & 1 ) == 0 ) a.xy = a.yx;
		if ( ( index.y & 1 ) == 0 ) a.zw = a.wz;
		b.pmin.xy += a.xz; // shrink cell bounds according to street margins (we alternate wide and narrow streets hence logic above)
		b.pmax.xy -= a.yw;

		vec2 margin = vec2( split_cells_spacing * 0.5 + 0.2 );

		vec2 r55 = hash22_( index ); // split type, permute

		Ray ray2 = ray;
		bool permuted = false;

		#ifdef TILE_PERMUTATIONS
		if ( r55.y > 0.5 )
		{
			// random permutations, else default patterns look more or less all aligned
			ray2.o.xyz = ray.o.yxz;
			ray2.d.xyz = ray.d.yxz;
			b.pmin.xy = b.pmin.yx;
			b.pmax.xy = b.pmax.yx;
			permuted = true;
		}
		#endif

		vec4 r4 = icdf( hash42_( index * 0x8da6b343 ) ); // heights hash
		vec4 rheights = mix( vec4( minh ), vec4( maxh ), r4 );
		vec4 r3 = hash42_( index * 0xb68f63e4 ); // split hash
		vec4 r3_0 = r3;

		r3.xyw = mix( vec3( 1. ), vec3( 5. ), r3.xyw ); // ratio of smallest to largest size
		r3.xy = fractions( r3.xyw ); // use r3.xyw as relative unit sizes
		r3.z = mix(  0.2,  0.8, r3.z );

		Ranges_x4 iv;

		Split4bSetup s4su = setup_Split4b( ray2, b.pmin.xy, b.pmax.xy, margin );

		// select a tile split pattern
		if ( r55.x > 0.75 )
		{
			bound_Split4b_xxy( iv, ray2, b.pmin.xy, b.pmax.xy, mix( b.pmin.xxy, b.pmax.xxy, r3.xyz ), rheights, margin );
			trace_Split4b_xxy( iv, ray2, s4su, mix( b.pmin.xxy, b.pmax.xxy, r3.xyz ), rheights );
			split_case = 0.;
		}
		else if ( r55.x > 0.5 )
		{
			r3.xyz = fractions( mix( vec4( 2. ), vec4( 3. ), r3_0 ) );

			bound_Split4b_xxx( iv, ray2, b.pmin.xy, b.pmax.xy, mix( b.pmin.xxx, b.pmax.xxx, r3.xyz ), rheights, margin );
			trace_Split4b_xxx( iv, ray2, s4su, mix( b.pmin.xxx, b.pmax.xxx, r3.xyz ), rheights );
			split_case = 1.;
		}
		else if ( r55.x > 0.25 )
		{
			bound_Split4b_xyy( iv, ray2, b.pmin.xy, b.pmax.xy, mix( b.pmin.xyy, b.pmax.xyy, r3.zxy ), rheights, margin );
			trace_Split4b_xyy( iv, ray2, s4su, mix( b.pmin.xyy, b.pmax.xyy, r3.zxy ), rheights );
			split_case = 2.;
		}
		else
		{
			bound_Split4b_xyx( iv, ray2, b.pmin.xy, b.pmax.xy, mix( b.pmin.xyx, b.pmax.xyx, r3.xzy ), rheights, margin );
			trace_Split4b_xyx( iv, ray2, s4su, mix( b.pmin.xyx, b.pmax.xyx, r3.xzy ), rheights );
			split_case = 3.;
		}

		hit.t = FLT_MAX;
		hit.tile_child_index = -1.; // no hit

		rayMarchCellObjects( ray2, iv, permuted, hit, dda.c.xy, shadow_trace );

		if ( hit.t != FLT_MAX ) break; // we have hit, gtfo and fill other extra bits out of the loop
//		if ( hit.t > ct.t ) return; // fixme: no point in continuing, but we should just set dda end point instead

		dda_step_infinite( dda ); // make sure you set a_finite to false in dda_init when calling this version
	}

	if ( hit.t >= ct.t ) return; // ct.t might be FLT_MAX so >= is important here

	// we hit a building
	ct.p = ray.o + hit.t * ray.d;
	ct.t = start_t + hit.t; // remember that we jumped at start

	if ( shadow_trace ) return; // we don't need normal, ao, material... gtfo

	// house type will use type index [0,3], building type will use index [4,7]
	pack_info( ct, dda.c.xy, split_case, hit.tile_child_index + hit.building_type * 4. );

	vec3 p = hit.ray2.o + hit.t * hit.ray2.d;

#ifndef DEBUG_BUILDINGS_BOUNDS
	
	vec3 h = vec3( 0.01, 0., 0. ); // h.x *= hit.t; // grainy normals tweak

	#ifdef FORCE_GRAD_LOOP_BUILDING
	vec3 dcomp;
	for ( int comp = 0 FORCE_LOOP; comp < 3; ++comp )
	{
		vec3 dp = p;
		dp[comp] += h.x;
		dcomp[comp] = sd_ParametricBuilding( hit.t, dp, hit.building_type, hit.b2, hit.height, hit.nh, hit.rnd ).d;
	}
	ct.n = normalize( dcomp - vec3( hit.d ) );
	#else
	ct.n = normalize( vec3( sd_ParametricBuilding( hit.t, p + h.xyz, hit.building_type, hit.b2, hit.height, hit.nh, hit.rnd ).d,
							sd_ParametricBuilding( hit.t, p + h.zxy, hit.building_type, hit.b2, hit.height, hit.nh, hit.rnd ).d,
							sd_ParametricBuilding( hit.t, p + h.yzx, hit.building_type, hit.b2, hit.height, hit.nh, hit.rnd ).d )
					  - hit.d ); // hit.d should be equal to sd_ParametricBuilding( hit.t, p, hit.building_type, hit.b2, hit.height, hit.nh, hit.rnd ).d
	#endif

	// do ao in permuted space
	#ifdef AO
	{
		Ray ao_ray = mkray( p, ct.n );
		AO_BEGIN()
			float d = sd_ParametricBuilding( _ao_t, ao_ray.o + _ao_t * ao_ray.d, hit.building_type, hit.b2, hit.height, hit.nh, hit.rnd ).d;
		AO_END( ct.ao )
	}
	#else
	ct.ao = 1.;
	#endif

	if ( hit.is_roof > 0. ) ct.type = IS_ROOF;

	if ( ( abs( hit.d - hit.windr.x ) < 0.001 ) // distance must be close to windows plane, stored in hit.windr.x
		 && ( 0.01 < abs( dot( hit.windr.yz, ct.n.xy ) ) ) // normal must match window orientation
		 // normal must be vertical
		 && ( abs( ct.n.z ) < 0.005 ) ) ct.type = IS_WINDOW;

	if ( hit.permuted ) ct.n.xy = ct.n.yx;

#endif
}

TraceCityRetval traceCity( Ray ray, bool shadow_trace )
{
	TraceCityRetval ct;
	pack_info1( ct, FLT_MAX, vec3( 0. ), vec3( 0. ), 1., 0 );
	pack_info( ct, vec2( 0. ), 0., TYPE_SKY );

	float split_cells_spacing = 0.025;

#if 1
	{
		// raytrace ground to close the horizon, only matters at street level (in bird view buildings occlude everything so it's useless) and traceBuildings needs its own ground for AO
		float t = plane_trace_z( ray, 0., 1e-6 );
		if ( 0. < t && t < ct.t && t < MAX_DDA_TRACE ) // use a max distance so the infinite plane doesn't extend beyond buildings horizon
		{
			pack_info1( ct, t, vec3( ( ray.o + t * ray.d ).xy, 0. ), vec3( 0., 0., 1. ), 1., 0 );
			pack_info( ct, vec2( 0. ), 0., TYPE_ROAD );
		}
	}
#endif

#if 1
	#ifdef HIGHWAYS
	if ( !SHADOW_EARLY_RET( ct.t ) )
	{
		// assuming highway is at constant height, we can raytrace that too and close a lot of the sdf marching hole at vanishing point
		float t = plane_trace_z( ray, HIGHWAY_HEIGHT, 1e-6 );
		if ( 0. < t && t < ct.t && t < MAX_HIGHWAY_TRACE )
		{
			vec3 p = ray.o + t * ray.d; // hit point
			if ( evalHighway( p.xy ).d < ROAD_HALFWIDTH )
			{
				pack_info1( ct, t, p, vec3( 0., 0., 1. ), 1., 0 );
				pack_info( ct, vec2( 0. ), 0., TYPE_HIGHWAY );
			}
		}
	}
	#endif
#endif

	#ifdef BUILDINGS
	if ( !SHADOW_EARLY_RET( ct.t ) ) traceBuildings( ray, ct, split_cells_spacing, shadow_trace );
	#endif

	#ifdef HIGHWAYS
	if ( !SHADOW_EARLY_RET( ct.t ) )
	{
		// ray marched scene component
		float t = 0.;
		bool hit = false;
		vec3 p, dd;
		// narrow fov need 200
		for ( int j = 0; j < 110 FORCE_LOOP_S; ++j )
		{
			p = ray.o + t * ray.d;

			dd = sd_RayMarchedCityBits( p, 0 );

			bool has_hit = abs( dd.x ) <= 0.001 * t; // no need to trace further than first building hit, or ground hit
			bool too_far = t > MAX_HIGHWAY_TRACE || t > ct.t; // hide glitter artifact in the distance, saves some ms too

			if ( has_hit || too_far )
			{
				hit = has_hit;
				break;
			}

			t += dd.x; // *TFRAC
		}

		if ( t < ct.t && hit )
		{
			ct.p = p;
			ct.t = t;

			if ( !shadow_trace ) // doubt it makes a difference, anyway shadow only need t
			{
				pack_info( ct, vec2( 0. ), 0., p.z < 0.004 * t ? TYPE_ROAD : TYPE_HIGHWAY );

				vec3 h = vec3( 0.01, 0., 0. );
		//		h.x *= t; // grainy normals tweak => but that inflate pavement edges weirdly

				#ifdef FORCE_GRAD_LOOP_SCENE
				vec3 dcomp;
				for ( int comp = 0 FORCE_LOOP; comp < 3; ++comp )
				{
					vec3 dp = ct.p;
					dp[comp] += h.x;
					dcomp[comp] = sd_RayMarchedCityBits( dp, 0 ).x;
				}
				ct.n = normalize( dcomp - vec3(dd.x) );
				#else
				ct.n = normalize( vec3( sd_RayMarchedCityBits( ct.p + h.xyz, 0 ).x,
										  sd_RayMarchedCityBits( ct.p + h.zxy, 0 ).x,
										  sd_RayMarchedCityBits( ct.p + h.yzx, 0 ).x )
									- dd.x );
				#endif
				
				#ifdef AO
				{
					Ray ao_ray = mkray( ct.p, ct.n );
					AO_BEGIN()
						float d = sd_RayMarchedCityBits( ao_ray.o + _ao_t * ao_ray.d, 0 ).x;
					AO_END( ct.ao )
				}
				#else 
				ct.ao = 1.;
				#endif

				ct.type = 0;

				if ( abs( dd.y - dd.x ) < 0.0000007 ) ct.type = IS_LAMP;
				if ( abs( dd.z - dd.x ) < 0.0000007 ) ct.type = IS_SIGN;
			}
		}
	}
	#endif

	ct.ao = min( ct.ao, 1. ); // apparently this goes above 1 and whitens far away pixel... so clamp

	return ct;
}

struct CameraPosAndTangent { vec3 eye; vec2 tangent; };
struct CameraRet { vec3 eye; vec3 target; float roll; float pitch; };

CameraRet init_cam() { CameraRet cam; cam.roll = 0.; cam.pitch = 0.; return cam; }

mat4 look_around_mouse_control( mat4 camera, float pitch, float tan_half_fovy, float look_at_the_abyss )
{
	float mouse_ctrl = 1.0;
	vec2 mm_offset = vec2( 0.0, pitch );
	vec2 mm = vec2( 0.0, 0.0 );

#ifndef EXTRA_3D_CAMERA
	if ( iMouse.z > 0.0 || STICKY_MOUSE ) mm = ( iMouse.xy - iResolution.xy * 0.5 ) / ( min( iResolution.x, iResolution.y ) * 0.5 );
#endif

	float mm_y = mm.y;

	mm.x = -mm.x;
	mm = sign( mm ) * pow( abs( mm ), vec2( 0.9 ) );
	mm *= PI * tan_half_fovy * mouse_ctrl;
	mm += mm_offset;

	if ( mm_y < 0. )
	{
		// very special case camera control for getRoofTopCoffeeBreakCamera
		vec3 v = camera[2].xyz;
		v.xy = rotate_with_angle( v.xy, mm.x );
		camera[3].xyz += v * mm.y * look_at_the_abyss;
	}

	return camera * yup_spherical_coords_to_matrix( mm.y, mm.x );
}

CameraPosAndTangent getDriveCameraPosAndTangent( float t, float lateral_move_amplitude )
{
//	t -= 200. * iSlider0;
	float x = t * 4.;
	float e = 1e-2;
	vec3 p1 = sd_CameraCurveXY( x );
	vec3 p2 = sd_CameraCurveXY( x + e );
	vec2 tangent = ( p2.xy - p1.xy ) / e;
	CameraPosAndTangent ret;
	ret.eye = p1;
	ret.tangent = tangent;
	ret.eye.xy += lateral_move_amplitude * perp( tangent ) * sin( 2. * PI * t / 5. ) * ROAD_HALFWIDTH * 0.5 * abs( tangent.y );
	return ret;
}

// we use those for drive camera vibrations
float noise( float x ) { float xi = floor( x ); return mix( hash11( xi ), hash11( xi + 1. ), smoothstep_unchecked( x - xi ) ); }
float noisem11( float x ) { return 2. * ( noise( x ) - 0.5 ); }
float fbm( float x ) { return noisem11( x ) + noisem11( x * 2. ) * 0.5 + noisem11( x * 4. ) * 0.25 + noisem11( x * 8. ) * 0.125; }

CameraRet getDriveCamera( float t )
{
	float lateral_move_amplitude = 1.;
	CameraPosAndTangent cam0 = getDriveCameraPosAndTangent( t, lateral_move_amplitude );

	CameraRet cam = init_cam();
	cam.eye = cam0.eye;

	// those 2 evals are for camera acceleration effects and target eval
	CameraPosAndTangent camnext1 = getDriveCameraPosAndTangent( t - 1.0, lateral_move_amplitude );
	CameraPosAndTangent camnext2 = getDriveCameraPosAndTangent( t + 0.5, lateral_move_amplitude );

	{
		// for road vibrations we must be close enough to road surface
		float driving_vibrations = max( smoothbump( HIGHWAY_HEIGHT, 4., cam.eye.z ), smoothbump( 0., 4., cam.eye.z ) );
		cam.eye.xy += driving_vibrations * perp( cam0.tangent ) * fbm( 100. + t * 0.1 ) * 0.3;
		cam.eye.z += driving_vibrations * fbm( t ) * 0.015; // road roughness
	}

	cam.roll = ( camnext2.tangent.y - camnext1.tangent.y ) * 0.3; // roll

	cam.target = camnext2.eye;

	// drift logic
	float tr = repeat_e( t, 0., 30. );
	cam.target.xy = cam.eye.xy + rotate_with_unit_vector( cam.target.xy - cam.eye.xy, unit_vector2( PI * smoothstep( 5., 10., tr ) + // 180 = flying looking backward for a while
																									PI * smoothstep( 15., 20., tr ) ) ); // 360 = back to travel direction
	return cam;
}

vec3 getStraightFlightCameraPos( float time )
{
	time += 200.;
	vec2 v = unit_vector2( -time * 0.05 );
	return vec3( v * 100. + 50. * log( 1. + time ), 15. );
}

CameraRet getStraightFlightCamera( float t, inout float tan_half_fovy, float duration )
{
	float u = t / duration;
	t += 8.;
	CameraRet cam = init_cam();
	cam.eye = getStraightFlightCameraPos( t );
	cam.target = getStraightFlightCameraPos( t + 1. );
	cam.target.xy = cam.eye.xy + rotate_with_unit_vector( cam.target.xy - cam.eye.xy, unit_vector2( -PI * smoothstep( 1., 0., u ) ) );
	tan_half_fovy = 0.5;
	cam.pitch = radians( -20. );
	return cam;
}

// get position of a point that travelled at constant speed a long a log spiral, starting from theta0
vec2 log_spiral( float d, float theta0, float a, float b )
{
//	d( theta ) = integral of a * exp( b * theta ) dtheta = ( exp( b * theta ) - exp( b * theta0 ) ) * a / b;
	float theta = log( d * ( b / a ) + exp( b * theta0 ) ) / b;
	return a * exp( b * theta ) * unit_vector2( theta );
}

vec3 getRoofTopCoffeeBreakCameraPos( float u )
{
	vec2 v = log_spiral( (u)*4.3, 0., 1., 1. );
	v -= normalize( v ) * 1.;
	v.xy *= vec2( 0.51, 0.95 );
	return vec3(v.xy,0.) + vec3(593.983276,-76.936417,8.693137); // add start position
}

// walk on a roof top and lookup at airliner
CameraRet getRoofTopCoffeeBreakCamera( float t, inout float tan_half_fovy, float duration, inout float look_at_the_abyss )
{
	CameraRet cam = init_cam();
	vec3 start_pos = vec3(593.983276,-76.936417,8.693137);
	float u = saturate( t / duration );
	cam.eye = getRoofTopCoffeeBreakCameraPos( u );
	cam.eye.z += ( ( 1. + sin( u * 95. ) ) * 0.5 ) * 0.001; // walk
	float ra = mix( -radians( 1.5 ), PI * 1.17, smoothstep( 0.2, 1., u ) );
	cam.target = cam.eye + vec3( unit_vector2( ra ), 0. );
	cam.pitch = smoothbump( u, 0.6, 0.75, 0.82, 1.01 ) * PI * 0.5 * 0.75;
	look_at_the_abyss = 0.2 * smoothstep( 0.8, 0.6, u );
	return cam;
}

// ( offset x, offset y, angle, time offset )
//#define LSFC vec4(iSlider2,iSlider3,iSlider4,iSlider5)
#define LSFC vec4(0.,0.35,0.2214,0.0928)

vec3 getLogSpiralCameraFlyPos( float t, inout float pitch )
{
	#if 0
	// old camera, a bit long
	float dz = exp_bell( t -35.5, 5. );
	pitch = radians( -18. );
	pitch -= dz * radians( 3.5 );
	#else
	float dz = exp_bell( t -15.5, 5. ) * 0.5;
	pitch = radians( -18. );
	pitch -= dz * radians( 3.5 );
	#endif
	return vec3( vec2( -100. ) + 200. * LSFC.xy, 8.3 )
		   + vec3( rotate_with_angle( log_spiral( LSFC.w * 200. + t * 1.2, 0.1, 1., 1. )
									  , -LSFC.z * PI * 2. ), dz * 3. );
}

// fly along a log spiral with constant roll
CameraRet getLogSpiralCameraFly( float t, inout float tan_half_fovy )
{
	CameraRet cam = init_cam();
	cam.eye = getLogSpiralCameraFlyPos( t, cam.pitch );
	cam.target = getLogSpiralCameraFlyPos( t + 1., cam.pitch );
	cam.roll = radians( 10. );
	tan_half_fovy = 0.53;
	return cam;
}

// goes through p1,p2
void catmullrom( out vec3 point, out vec3 derivative, float t, vec3 p0, vec3 p1, vec3 p2, vec3 p3 )
{
	float t2 = t * t;
	float t3 = t2 * t;
	vec3 a1 = -p0 + p2;
	vec3 a2 = 2. * p0 - 5. * p1 + 4. * p2 - p3;
	vec3 a3 = -p0 + 3. * p1 - 3. * p2 + p3;
	point = 0.5 * ( ( 2. * p1 ) + a1 * t + a2 * t2 + a3 * t3 );
	derivative = 0.5 * ( a1 + a2 * 2. * t + a3 * 3. * t2 ); // whilst we are at it
}

// goes through p1,p2,p3
void catmullrom( out vec3 point, out vec3 derivative, float t, vec3 p0, vec3 p1, vec3 p2, vec3 p3, vec3 p4 )
{
	if ( t < 0.5 ) catmullrom( point, derivative, t * 2., p0, p1, p2, p3 );
	else catmullrom( point, derivative, 2. * ( t - 0.5 ), p1, p2, p3, p4 );
}

//#define UTBSC vec2(iSlider0,iSlider1)
//#define UTBSC vec2(0.585714,0.35)
#define UTBSC vec2(0.585714,0.707143) // best

CameraRet getUnderTheBridgeStreetCamera( float t, inout float tan_half_fovy, float duration )
{
	CameraRet cam = init_cam();
	float u = saturate( t / duration );
	vec3 o = vec3( floor( UTBSC.x * 100. ) * 80. * 2., 
				   floor( UTBSC.y * 100. ) * CELL_SIZE.y, 0. );
	vec3 p0 = o + vec3( -80.457870, -10.903438, 0.591591 );
	vec3 p1 = o + vec3( -80.274940, -3.2, 0.517319 );
	vec3 p2 = o + vec3( -79.289925, 2.674706, 1.934119 );
	vec3 p3 = o + vec3( -74.650077819, 3.327467679, 3.193379163 );
	vec3 p4 = o + vec3( -71.289779663, 4.606474399, 3.521366834 );
	vec3 derivative;
	catmullrom( cam.eye, derivative, u, p0, p1, p2, p3, p4 );
	cam.target = cam.eye + derivative;
	cam.pitch = mix( radians( -22. ), 0., u );
	cam.roll = mix( radians( 0. ), radians( -8. ), smoothstep( 0.2, 0.8, u ) );
	return cam;
}

//#define IFC vec3(iSlider0,iSlider1,iSlider2)
#define IFC vec3(0.6,0.62,0.328)

CameraRet getIsoFlyCamera( float t, inout float tan_half_fovy, float duration )
{
	CameraRet cam = init_cam();
	vec2 travel_dir = normalize( vec2( -1.8, 1.4 ) );
	cam.eye = vec3( travel_dir * t * 4., 65. );
	cam.eye += vec3( IFC.x * 200., IFC.y * 200., 0. );
	cam.target = cam.eye + vec3( perp( travel_dir ), 0. );
	cam.pitch = radians( -60. * IFC.z );
	tan_half_fovy = 0.1;
	return cam;
}

// get close to a LCD panel that shows the squid invaders things
CameraRet getLCDScreenCloseUpCamera( float t, inout float tan_half_fovy, float duration )
{
	CameraRet cam = init_cam();
	cam.eye = vec3( -5.514656066, -0.541317582, 2.770161151 );
	cam.target = cam.eye + vec3( -1., 0., 0. );
	vec3 a = vec3( -6.56, -0.8, 3.3 );
	vec3 b = vec3( -6.56, 0.8, 3.3 );
	cam.eye.x += 1.5;
	cam.eye.z -= 0.5;
	float u = saturate( t / duration );
	vec3 c = mix( a, b, u );
	c.x += 0.8;
	cam.eye = mix( cam.eye, c - vec3( 0., 0., 0.5 ), u );
	cam.target = mix( cam.target, mix( a, b, 0.8 ), pow( u, 2. ) );
	tan_half_fovy = mix( 0.47, 0.4, u );
	return cam;
}

mat4 getCamera( inout float tan_half_fovy, inout float fade, inout float a_contrast, vec3 l, inout float time, inout float ground_ao )
{
	float total = 0.;
	// per camera time range: array of start, duration (yes I am aware of the syntax that pretends we can have arrays)
	vec2 r1 = vec2( total, 41. ); total += r1.y;
	vec2 r2 = vec2( total, 20. ); total += r2.y;
	vec2 r3 = vec2( total, 20. ); total += r3.y;
	vec2 r4 = vec2( total, 8.5 ); total += r4.y;
	vec2 r5 = vec2( total, 12. ); total += r5.y;
	vec2 r6 = vec2( total,  8. ); total += r6.y;
	vec2 r7 = vec2( total, 22. ); total += r7.y;

	time = mod( time, total ); // cycle through all cameras

//	vec2 r = r2; // <= select a specific camera to test here
//	time = r.x + mod( time, r.y );
//  time = r.x + 1.;

	float tr = 0.7; // fade half durations
	fade *= 1. -( max( cosbump( time, 0., tr ), cosbump( time, total, tr )) // those 2 overlap
				 + cosbump( time, r2.x, tr )+ cosbump( time, r3.x, tr )
				 + cosbump( time, r4.x, tr )+ cosbump( time, r5.x, tr )
				 + cosbump( time, r6.x, tr )+ cosbump( time, r7.x, tr ));

	float look_at_the_abyss = 0.;

	CameraRet cam;

	     if ( time < r1.x + r1.y ) { time -= r1.x; cam = getDriveCamera( time ); }
	else if ( time < r2.x + r2.y ) { time -= r2.x; cam = getLogSpiralCameraFly( time, tan_half_fovy ); ground_ao = 0.7; }
	else if ( time < r3.x + r3.y ) { time -= r3.x; cam = getRoofTopCoffeeBreakCamera( time, tan_half_fovy, r3.y, look_at_the_abyss ); ground_ao = 0.375; }
	else if ( time < r4.x + r4.y ) { time -= r4.x; cam = getUnderTheBridgeStreetCamera( time, tan_half_fovy, r4.y ); }
	else if ( time < r5.x + r5.y ) { time -= r5.x; cam = getStraightFlightCamera( time, tan_half_fovy, r5.y ); ground_ao = 0.7; }
	else if ( time < r6.x + r6.y ) { time -= r6.x; cam = getLCDScreenCloseUpCamera( time, tan_half_fovy, r6.y ); }
	else                           { time -= r7.x; cam = getIsoFlyCamera( time, tan_half_fovy, r7.y ); ground_ao = 0.375; }

	mat4 camera = lookat( cam.eye, cam.target, vec3( 0., 0., 1. ) ) * z_rotation( cam.roll );
	return look_around_mouse_control( camera, cam.pitch, tan_half_fovy, look_at_the_abyss );
}

// trace the silhouette of an a350 airliner, alt = 10000 at cruising altitude
float get_airliner( Ray view_ray, float alt, float cruising_speed_fraction, float d, vec2 mv // normalized please
					, float tan_half_fovy, float time_offset, float direction, float trail_fade, float time )
{
//	cruising_speed_fraction *= 5.; // DEBUG
	float airliner_cruising_speed = cruising_speed_fraction * ( 950000. / ( 60. * 60. ) ); // m/s
	float R1 = 5. * alt * tan_half_fovy; // make all trajectory disks roughly same radius from ground
	float R2 = R1 * 1.4;
	float fade_time = 1.;
	float h1 = sqrt( R1 * R1 - d * d );
	float h2 = sqrt( R2 * R2 - d * d );
	vec2 O = vec2( 0., 0 );
	vec2 c = O + mv * d;
	vec2 travel_direction = perp( mv ) * direction;
	float looptime = 2. * h2 / airliner_cruising_speed;
	float rt = mod( time + time_offset, looptime );
	float u = rt * airliner_cruising_speed;
	vec3 plane_pos = vec3( c + travel_direction * ( u - h2 ), alt );
	float t = plane_trace_z( view_ray, alt, 0. ); // epsilon zero, we don't care it's in the sky
	vec3 it = view_ray.o + view_ray.d * t;
	float dd = length( it.xy );
	float x = dot( it.xy - plane_pos.xy, -travel_direction ) - 47.;
	float y = abs( dot( it.xy - plane_pos.xy, perp( travel_direction ) ) );
	float fade = smoothstep( h2, h1, abs( u - h2 ) );
	float trail_disk_fade = smoothstep( R2, R1, dd );
	// note: y is already symmetrized
	float trail_half_spacing = 9.;
	float dc = exp_decay( x * 0.02 );
	float engine_trail = ( x < 0. ? 0. : smoothstep( 2., -1., abs( y - trail_half_spacing ) - dc * 4. ) )
	// trail distance decay
		* exp( -x * 0.00175 );
	float trail = engine_trail * fade * trail_disk_fade * trail_fade;
	float debug = 0.;
	vec2 uv = ( it - plane_pos ).xy * ( 20. / 64. ); // plane outline sdf to scale
	if ( length( uv ) > 12. ) return debug + trail + 0.; // outside plane sdf's disk
	return debug + trail + fade * smoothstep( 0.1, -0.1, sd_airliner_a350( rotate_with_unit_vector( uv, vec2( travel_direction.x, -travel_direction.y ) ) ) ); // plane
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	float aspect = iResolution.x / iResolution.y;
	vec2 u = fragCoord.xy / iResolution.xy;
	fragColor.a = 1.;
	float a_contrast = 1.;
	float fade = 1.;
	float ground_ao = 1.; // 1. == no ground ao... a bit of ground ao helps in flight cameras

#if 1
	vec3 l = normalize( vec3( 0.8, 0.025, 0.125 ) ); // sun direction
#else
// sun is meant to be at a sunset-ish position, looks bad else
	vec3 l = zup_spherical_coords_to_vector( PI * 0.5 * (1. - iSlider0), 2. * PI * (iSlider1 - 0.5) ); // sun direction
#endif

//	fragColor.rgb = test_sky( fragCoord, l ); return; // contemplate sky probe, for the interested reader
//	fragColor.rgb = get_building_palette( fragCoord.xy / min( iResolution.x, iResolution.y ) ); return; // for the curious

	float time = iTime + 20.;

#ifdef EXTRA_3D_CAMERA
	float tan_half_fovy = iTanHalfFovy;
	mat4 camera = mat4( iCamera[0], iCamera[1], iCamera[2], iCamera[3] );
#else
	float tan_half_fovy = 0.6; // fovy 61 deg
	mat4 camera = getCamera( tan_half_fovy, fade, a_contrast, l, time, ground_ao );
#endif

	Ray view_ray = get_view_ray( ( u - vec2( 0.5 )) * 2.0, 0.1, aspect, tan_half_fovy );
	view_ray = mkray( camera[3].xyz, ( camera * vec4( view_ray.d, 0.0 )).xyz );
	view_ray.d.z += 1e-5; // divide by zero quick workaround

#if defined(UNROLL_LOOP0)||!defined(SHADOWS)
	TraceCityRetval ct = traceCity( view_ray, false );
	float shadow = 1.;
#ifdef SHADOWS
	Ray sray = mkray( ct.p + ct.n * 0.0025 * ct.t, l );
	TraceCityRetval ct_shadow = traceCity( sray, true );
	shadow = step( FLT_MAX, ct_shadow.t );
#endif
#else
	// do view ray and shadow ray in a loop in hope to reduce chance of hitting webgl crashes
	Ray r = view_ray;
	TraceCityRetval ct;
	float shadow = 1.;
	for ( int i = 0; i < 2 FORCE_LOOP_LV0 ; ++i )
	{
		TraceCityRetval ctr = traceCity( r, i == 1 );
		r = mkray( ctr.p + ctr.n * 0.0025 * ctr.t, l ); // set shadow ray for second pass
		if ( i == 0 ) ct = ctr;
		shadow = step( FLT_MAX, ctr.t ); // only relevant at end of second pass
	}
#endif

#if 0
	// raytrace one last thing... only a tiny little thin one (actually, 3 tiny little thin ones)
	float airliner = 0.;
	airliner = max( airliner, get_airliner( view_ray, 1000., 0.3, 2000.,          V45, tan_half_fovy, 15.,  1., 1. , time ) ); // set time to 673 for debug
	airliner = max( airliner, get_airliner( view_ray, 5000., 0.8, 500. ,  vec2(1.,0.), tan_half_fovy, 45., -1., 1. , time ) );
	airliner = max( airliner, get_airliner( view_ray, 1500., 0.4, 0.   , vec2(-1.,0.), tan_half_fovy, 40., -1., 0.7, time ) );
#else
	// unrolling is cleaner than this horrible mess but I wanted the option to try force a loop
	float airliner = 0.;
	for ( int i = 0; i < 3 FORCE_LOOP_B; ++i )
	{
		float airliner_alt = 1000. + (i == 1 ? 4000. : 0.) + (i == 2 ? 500. : 0.);
		float airliner_cruising_speed_fraction = 0.3 + (i == 1 ? 0.5 : 0.) + (i == 2 ? 0.1 : 0.);
		float airliner_d = float(2-i) * 500. + (i == 0 ? 1000. : 0.);
		vec2 mv = (i == 0 ? V45 : vec2( 0. )) + (i == 1 ? vec2( 1., 0. ) : vec2( 0. )) + (i == 2 ? vec2( -1., 0. ) : vec2( 0. ));
		float time_offset = 15. + (i == 1 ? 30. : 0.) + (i == 2 ? 25. : 0.);
		float direction = (i == 0 ? 1. : -1.);
		float trail_fade = (i == 2 ? 0.7 : 1.);
		airliner = max( airliner, get_airliner( view_ray, airliner_alt, airliner_cruising_speed_fraction, airliner_d, mv, tan_half_fovy, time_offset, direction, trail_fade, time ) );
	}
#endif

	fragColor.rgb = fade * shadeCity( ct, view_ray.o, view_ray.d, l, shadow, airliner, a_contrast, u, aspect, ground_ao );
}
