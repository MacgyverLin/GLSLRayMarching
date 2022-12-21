/**
 * Written by Gerard Geer.
 * License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
 * 
 * Version 1.0
 * Version 1.1 	Optomized/cleaned up a bit, and did some more documentin'.
 * Version 1.2 	Gave pipes a clear protective coating. (I made them shiny.) 
 * 				I also changed some colors.
 * Version 1.3	Functioned out determining reflectivity and deflection. This allowed me
 * 				to add some variation in the reflections in the form of puddles
 * 				and a less roof-icured ceiling.
 * Version 1.4	Implemented mainVR.
 * Version 1.41 Unimplemented mainVR. Sorry guys...
 * Version 1.42 Optimized a small bit, and also added angle dependence for the reflections.
 *				(Took out one case in the texturing if statements, and remove the branching
 *				in u().)
 */

// Main marching steps.
#define V_STEPS 80
// Shadow marching steps.
#define R_STEPS 80
// Maximum successful marching distance.
#define EPSILON .0005
// Max possible depth, from corner to corner.
#define MAX_DEPTH 175.0

const vec3 UP = vec3(0.0, 1.0, 0.0); // An up vector.

// Scene object dimensions, modulus repetitions and offsets.
const vec3 GARAGE_DIM = vec3(90.,8.,150.);
#define GARAGE_OFF 4.		/* Along the Y axis. */

const vec2 PILLAR_DIM = vec2(1.5);
#define PILLAR_OFF 26.66 	/* Along the X axis. */
const vec2 PILLAR_REP = vec2(26.66,10.);

const vec3 RAFTER_DIM = vec3(3.,.75,3.);
const vec3 RAFTER_OFF = vec3(26.66,7.625,0.);
const vec2 RAFTER_REP = vec2(26.66,10.);

const vec2 BOLLARD_DIM = vec2(.25,2.);
const vec2 BOLLARD_OFF = vec2(.05,5.);

const vec2 PIPES_OFF  = vec2(1.,7.);
#define PIPES_REP 26.66		/* Along the X axis. */
#define PIPES_R 	.2

const vec3 LIGHTS_A   = vec3(-2.,7.825,0.);
const vec3 LIGHTS_B   = vec3( 2.,7.825,0.);
#define LIGHTS_R    .125
const vec2 LIGHTS_REP = vec2(13.,10.);

#define PUDDLESCALE .005

// Object IDs. (For texturing and whatnot).
#define ID_GARAGE 	1.0
#define ID_PILLAR 	2.0
#define ID_BOLLARDS 4.0
#define ID_RAFTER 	8.0
#define ID_PIPES  	16.0
#define ID_LIGHTS 	32.0
#define ID_WIRES	64.0

// Texture definition.
#define NOISE_S iChannel0

// Lighting color.
const vec3 LCOLOR = vec3(1.,.95,.95);	// Light color.
const vec3 ACOLOR = vec3(.01, .017, .02);	// Ambient light color.

// Object base colors.
const vec3 PIPECOLOR = vec3(.4,.07,.06);	// Color of the pipe.
const vec3 CLAMPCOLOR = vec3(.7,.675,.6); 	// Color of the pipe brackets.
const vec3 PILLARCOLOR = vec3(1.0, 1.0, .1);// Color of pillar paint.
const vec3 WALLCOLOR = vec3(.05,.1,.8);		// Wall base paint.
const vec3 BOLLARDCOLOR = vec3(1.,1.,0.); 	// Bollard color.
const vec3 WIRECOLOR = vec3(.01);			// Ceiling wire color.
const vec3 LIGHTCOLOR = vec3(1.0);			// Lights are always white petty much.
const vec3 CAGECOLOR = vec3(.08, .02, .01); // Light caging color.
const vec3 PUDDLECOLOR = vec3(.07,.08,.0); // The color of the grit in the puddles.

// Occlusion samples.
#define OCC_SAMPLES 3.0
// Occlusion attenuation samples.
#define OCC_FACTOR 1.
// Light and reflection penumbra factors.
#define LPFACTOR 30.0
#define RPFACTOR 15.0
// Oren-Nayar material reflectance coefficient.
#define MAT_REFLECTANCE 3.0

/*
	A linear Bezier function. I'm going to use the built in mix here
	just in case the vendor interpolation is faster than implementing
	it myself.
*/
vec3 lb(vec3 a, vec3 b, float t)
{
    return mix(a, b, t);
}

/*
	The first derivative of a linear Bezier function. Ain't a
	built in for this. It's also normalized since it's exclusively
	used to specify camera direction.
*/
vec3 dlb(vec3 a, vec3 b, float t)
{
    return normalize( b - a );
}

/*
	A quadratic Bezier function. A more certain benefit of using mix()
	is that the recursive nature of a Bezier curve becomes immediately
	apparent, and makes the whole concept far easier to understand.
*/
vec3 qb(vec3 a, vec3 b, vec3 c, float t)
{
	return mix( mix(a,b,t), mix(b,c,t), t);
}

/*
	The first derivative of a quadratic Bezier function.
*/
vec3 dqb(vec3 a, vec3 b, vec3 c, float t)
{
    return normalize( (2.0-2.0*t)*(b-a) + 2.0*t*(c-b) );
}

/*
	A cubic Bezier function. Mixing in some more mixin mix()s.
*/
vec3 cb(vec3 a, vec3 b, vec3 c, vec3 d, float t)
{
	return mix(mix(mix(a,b,t), mix(b,c,t),t),mix(mix(b,c,t), mix(c,d,t),t), t);
}

/*
	Again, a derivative. This time of cubic Bezier function.
*/
vec3 dcb(vec3 a, vec3 b, vec3 c, vec3 d, float t)
{
	return normalize( 3.0*pow(1.0-t, 2.0)*(b-a) + 6.0*(1.0-t)*t*(c-b)+3.0*pow(t, 2.0)*(d-c) );
}

/*
	Creates and orientates ray origin and direction vectors based on a
	camera position and direction, with direction and position encoded as
	the camera's basis coordinates.
*/
void camera(in vec2 uv, in vec3 cp, in vec3 cd, in float f, out vec3 ro, out vec3 rd)
{
	ro = cp;
	rd = normalize((cp + cd*f + cross(cd, UP)*uv.x + UP*uv.y)-ro);
}

/*
	Returns a coefficient for a shutter fade.
*/
float shutterfade(in float s, in float e, in float t, in float duration)
{
    return min( smoothstep(s, s+duration, t), smoothstep(e, e-duration, t) );
}

/*
	A static camera path for the artsy shots. This one requires an input camera
	direction.
*/
void s_cam_path(in float s, in float e, in float f,
                in vec3 a, float t,
                out vec3 cp, inout vec3 cd, out float shutter)
{
    cp = a;
  	shutter = shutterfade(s, e, t, f);
}

/*
	Sets up camera direction and position along a linear Bezier curve, based on
	start and end times, and start and end positions.
*/
void l_cam_path(in float s, in float e, in float f, 
				in vec3 a, in vec3 b, in float t,
				out vec3 cp, out vec3 cd, out float shutter)
{
	cp = lb(a, b, smoothstep(s, e, t));
	cd = dlb(a, b, smoothstep(s, e, t));
	shutter = shutterfade(s, e, t, f);
}

/*
	Sets up camera direction and position along a quadratic Bezier curve, based
	on start and end times, and start and end positions.
*/
void q_cam_path(in float s, in float e, in float f, 
				in vec3 a, in vec3 b, in vec3 c, in float t,
				out vec3 cp, out vec3 cd, out float shutter)
{
	cp = qb(a, b, c, smoothstep(s, e, t));
	cd = -cross(dqb(a, b, c, smoothstep(s, e, t)), UP);
	shutter = shutterfade(s, e, t, f);
}

/*
	Sets up camera direction and position along a cubic Bezier curve, based on
	start and end times, and start and end positions.
*/
void c_cam_path(in float s, in float e, in float f, 
				in vec3 a, in vec3 b, in vec3 c, in vec3 d, float t,
				out vec3 cp, out vec3 cd, out float shutter)
{
	cp = cb(a, b, c, d, smoothstep(s, e, t));
	cd = dcb(a, b, c, d, smoothstep(s, e, t));
	shutter = shutterfade(s, e, t, f);
}

/*
	Animates the camera, choosing a path based on the current time. Also
	performs camera shuttering.
*/
void animate_cam(in vec2 uv, in float t, out vec3 ro, out vec3 rd, out float shutter)
{
	// "Yeah I'm not gonna const-out all of those positions."
    vec3 cp, cd;   // Vectors into which we store the camera position/direction.
	t = mod(t, 60.); // Restart the camera animation every 60 seconds.
     //t = 7.3;
    // Each clause here is a different scene, determined by the current time
    // into the animation. They are ordered longest-duration-first so the
	// conditionals of the most likely clauses are evaluated first, cutting
	// down on false comparisons.
    if(t >= 22.0 && t < 32.0)	// 10 seconds.
    {
        l_cam_path(	20.0, 32.0, .5, 
					vec3(40., 2., -68.0), vec3(-38., 3., 75.0), t,
					cp, cd, shutter);
    }
    else if(t >= 46.0 && t < 54.0)	// 8 seconds.
    {
        l_cam_path(	46.0, 54.0, .5, 
					vec3(17., 5.0, 15.0), vec3(17., 5.0, 45.0), t,
					cp, cd, shutter);
        cd = vec3(-0.57735, 0.57735, 0.57735);
    }
	else if(t >= 8.0 && t < 15.0)		// 7 seconds.
	{
		l_cam_path(	8.0, 15.0, .5, 
					vec3(16., 2., -25.0), vec3(16., 3., 25.0), t,
					cp, cd, shutter);
		cd = vec3(-0.707107, 0, 0.707107);
	}
   	else if(t >= 0.0 && t < 5.0)	// 5 seconds.
	{
		l_cam_path(	0.0, 5.0, .5, 
					vec3(0.0, 4., -5.0), vec3(0.0, 4., 5.0), t,
					cp, cd, shutter);
	}
	else if(t >= 15.0 && t < 20.0)	// 5 seconds.
	{
		c_cam_path(	15.0, 20.0, .5,
					vec3(5.0, 3., 5.0), vec3(-1.0, 3., 5.0), vec3(1.0, 3., -5.0), vec3(-10.0, 3., -5.0), t,
					cp, cd, shutter);
	}
    else if(t >= 32.0 && t < 37.0)	// 5 seconds.
    {
        q_cam_path(	32.0, 37.0, .5, 
					vec3(-38.0, 1.5, -.075), vec3(-38.1, 1.5, .0), vec3(-38., 1.5, .075), t,
					cp, cd, shutter);
    }
    else if(t >= 42.0 && t < 46.0)	// 4 seconds.
    {
        c_cam_path(	42.0, 46.0, .5,
					vec3(10.0, 2., 0.0), vec3(10.0, 2., 10.0), vec3(18.0, 2., 10.0), vec3(18.0, 2., 20.0), t,
					cp, cd, shutter);
    }
	else if(t >= 5.0 && t < 8.0)	// 3 seconds.
	{
		q_cam_path(	5.0, 8.0, .5, 
					vec3(-16.0, 3., -1.1), vec3(-13, 3., 4.0), vec3(-6., 3., -1.1), t,
					cp, cd, shutter);
	}
    else if(t >= 39.0 && t < 42.0)	// 3 seconds.
    {
        l_cam_path(	39.0, 42.0, .5, 
					vec3(22., 1., 22.0), vec3(26., 3.5, 26.0), t,
					cp, cd, shutter);
    }
    else if(t >= 20.0 && t < 22.0)	// 2 seconds.
    {
        cd = vec3(0.995037, -0.0995037, 0.);
        s_cam_path( 20.0, 22.0, .5,
                    vec3(-38., 3., 78.0), t,
                    cp, cd, shutter);
    }
    else if(t >= 37.0 && t < 39.0)	// 2 seconds.
    {
        cd = vec3(-0.0618984, -0.123797, 0.990375);
        s_cam_path( 37.0, 39.0, .5,
                    vec3(14.5, .75, 6.), t,
                    cp, cd, shutter);
    }
    else if(t >= 54.0 && t < 56.0)	// 2 seconds.
    {
        cd = vec3(1.,0.,0.);
        s_cam_path( 54.0, 56.0, .5,
                    vec3(-24., .5, 6.75), t,
                    cp, cd, shutter);
    }
    else if(t >= 56.0 && t < 58.0)	// 2 seconds.
    {
        cd = vec3(-0.912871, 0.365148, 0.182574);
        s_cam_path( 56.0, 58.0, .5,
                    vec3(-3.5, 7.0, 4.), t,
                    cp, cd, shutter);
    }
    else if(t > 58.0 && t < 60.0)	// 2 seconds.
    {
        cd = vec3(-0.408248, -0.408248, 0.816497);
        s_cam_path( 58.0, 60.0, .5,
                    vec3(11.5, 7.85, -20.), t,
                    cp, cd, shutter);
    }
	camera(uv, cp, cd, 1.0, ro, rd);
}

/*
	Unions two distance functions together, returning
	the ID of and the distance to the nearest.
*/
vec2 u(in vec2 a, in vec2 b)
{
    // No more branching here!
    return mix(a,b,step(b.s,a.s));
}

/*
	A non-euclidean length function
*/
float length8(in vec2 a)
{
    return pow(pow(a.x,8.)+pow(a.y,8.), .125);
}

/*
	IQ's signed box distance function. I've edited it
	so the box dimensions passed in are manifested
	as the complete size of the box, not the distance
	each side is from the box's center.
*/
float box(in vec3 p, vec3 b)
{
    vec3 d = abs(p) - b*.5;
  	return min(max(d.x,max(d.y,d.z)),0.0) +
		length(max(d,0.));
}

/*
	2D columns for the pillars.
*/
float box2D(in vec2 p, in vec2 b)
{
    vec2 d = abs(p) - b*.5;
    return min(max(d.x, d.y), 0.)+
        length(max(d,0.));
}

/*
	IQ's signed capsule function.
*/
float capsule( vec3 p, vec3 a, vec3 b, float r )
{
	vec3 pa = p-a, ba = b-a;
	float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
	return length( pa - ba*h ) - r;
}

/*
	Cylinder distance function. (Also from IQ's 
	primitives example, but explicitly horizontal.)
*/
float cylinder( vec3 p, vec2 h )
{
  return max( length(p.xy)-h.x, abs(p.z)-h.y );
}

/*
	The outer box of the garage.
*/
float garage(in vec3 p)
{
	return -box(p-GARAGE_OFF, GARAGE_DIM);
}

/*
	The pillars of the garage.
*/
float pillars(in vec3 p)
{
    // Translate...
	p.x -= PILLAR_OFF;
    // Repeat...
	p.xz = mod(p.xz, PILLAR_REP)-.5*PILLAR_REP;
    // Evaluate.
	return box2D(p.xz, PILLAR_DIM);
}

/*
	The parking bollards.
*/
float bollards(in vec3 p)
{
    p.yz -= BOLLARD_OFF;
    p.xz = mod(p.xz, PILLAR_REP)-.5*PILLAR_REP;
    return cylinder(p, BOLLARD_DIM);
}

/*
	The rafters of the garage.
*/
float rafters(in vec3 p)
{
	p -= RAFTER_OFF;
	p.xz = mod(p.xz, RAFTER_REP)-.5*RAFTER_REP;
	return box(p, RAFTER_DIM);
}

/*
	A couple pipes that run the length of the garage.
*/
float pipes(in vec3 p)
{
    p.xy -= PIPES_OFF;
    p.x = mod(p.x, PILLAR_REP.x)-PILLAR_REP.x*.5;
	return length(p.xy)-PIPES_R;
}

/*
	Ceiling wires, because all garages have ceiling wires.
*/
float wires(in vec3 p)
{
    p.y -= 7.925;
    p.xz = mod(p.xz, 1.3)-.65;
    return min(length(p.xy)-.025, length(p.yz)-.025);
}

/*
	The lights in the garage.
*/
float lights(in vec3 p)
{
	p.xz = mod(p.xz, LIGHTS_REP)-.5*LIGHTS_REP;
    // Fatten up those capsules.
    p.z *= .25;
	return capsule(p, LIGHTS_A, LIGHTS_B, LIGHTS_R);
}

/*
	A simple distance function.
*/
float dist(vec3 p)
{
    // Oh yeah that nesting right there I'm the king of tiny wings collectables.
	return min(min(min(min(min(pillars(p),wires(p)),bollards(p)),pipes(p)),rafters(p)), garage(p));
}

/*
	A distance function that also returns object ID.
*/
vec2 distID(vec3 p)
{
	vec2 r = u( vec2(pillars(p), ID_PILLAR), vec2(rafters(p), ID_RAFTER) );
	r = u( r, vec2(garage(p), ID_GARAGE) );
    r = u( r, vec2(bollards(p), ID_BOLLARDS) );
    r = u( r, vec2(lights(p), ID_LIGHTS) );
    r = u( r, vec2(pipes(p), ID_PIPES) );
    r = u( r, vec2(wires(p), ID_WIRES));
	return r;
}

/*
	A function that uses the tri-planar texturing method
	to return a value from a noise texture in 3D space.
*/
float n3D(in vec3 p, in vec3 n)
{
    n = abs(n);
    return 	texture(NOISE_S, p.xy).r*n.z +
        	texture(NOISE_S, p.zy).r*n.x +
        	texture(NOISE_S, p.xz).r*n.y;
}

/*
	Uses that noise function to generate an FBM.
*/
float fbm(in vec3 p, in vec3 n)
{
	// I distributed the finishing divide.
    return  0.57190716*n3D(p*1.1,n)+
			0.28515355*n3D(p*1.9,n)+
    		0.14297679*n3D(p*4.0,n);
}

/*
	Returns a trial-by-error procedural cement texture.
	It's even that fancy cement with the speckles in it.
*/
vec3 cement_tex(in vec3 p, in vec3 n)
{
    // Do some scaling...
    p*=.5;
    // Make a noise value that has vaguely cement like features, and
    // cale the brightness so that it looks a bit more like cement.
    return vec3( .6-pow( fbm( p+fbm(p, n),n ), 3.0 ) );
}

/*
	Takes a pre-existing cement value, and modifies it
	to fit the texturing needs of the pillars.
*/
vec3 tex_pillars(in vec3 p, in float d, in vec3 n, in vec3 cement)
{
    
    p.xz += p.zx; // So faces in front of each other aren't identical.
    
    // Only paint the pillars below y=3.
    if(p.y < 3.)
    {
        // Get a noise value to determine whether or not the given
        // point on a pillar has paint or is in a flake.
        //
        // This decreases the edge contrast of the paint flakes
        // as distance increases, so you don't have flikery gray
        // dots on far away pillars.
        float f  = smoothstep(.7-.15*d, .7+.15*d, fbm(p*.1, n));
        // Smoothstep will return whether or not the noise value
        // was greater than the threshold. Here we use that result
        // to mix between having cement with or without paint.
        return mix(PILLARCOLOR*cement, cement, f);
    }
    else return cement;
}

/*
	Returns a texel of the simple texture for the pipes on the pillars.
*/
vec3 tex_pipe(in vec3 p, in float d, in vec3 n)
{
    // Do some scaling to align the brackets with the pillars.
    p.z += 5.5;
    p.z *= .1;
    
    // If the fractional part of the distance along the pipe/z-axis
    // is below a threshold, return 0, otherwise return 1.
    float f = step(.1, p.z-floor(p.z));
    
    // Create the red foam color for the pipe.
    vec3 base = PIPECOLOR;
   	base.gb *= fbm(p*5., n);
    
    // Mix between bracket or foam.
    return mix(CLAMPCOLOR,base, f);
}

/*
	Returns a procedural texture for the bollards.
*/
vec3 tex_bollards(in vec3 p, in float d, in vec3 n, in vec3 cement)
{
    // Simply use the same paint-flaking effect as on the walls and
    // pillars, but with a different threshold for variety.
    float f  = smoothstep(.8-.15*d, .8+.15*d, fbm(p*.1, n));
    return mix(mix(BOLLARDCOLOR,cement,.275), cement, f);
}

/*
	Draws a cage on the lights.
*/
vec3 tex_lights(in vec3 p, in float d, in vec3 n)
{
    // Do some scaling.
    p *= 4.;
    // We do the same thing as with the pipes here. If the
    // fractional part of the position is less than a threshold,
    // we return one value, and a different one otherwise,
    // except we use smoothstep so we can filter based on distance.
    float f = smoothstep(.1-.5*d, .1+.5*d, p.x-floor(p.x)) 
            * smoothstep(.1-.5*d, .1+.5*d, p.z-floor(p.z));
    // Mix between the cage and light color.
    return mix(CAGECOLOR, LIGHTCOLOR, f);
    if(p.x-floor(p.x)<.2 || p.z-floor(p.z)<.2) return vec3(.1, .025, .01);
    return vec3(1.);
}

/*
	Generates the oil stains on the ground. People need to
	keep their cars tuned up. Keep an eye on those gaskets
	and bolt torque specifications.
*/
float tex_stains(in vec3 p, in vec3 n)
{
    // Do some janky translation and scaling.
    p = vec3(p.xz+vec2(11.0, 1.0), p.z);
    p.xy *= vec2(.125, .4);
    
    // Set up repetition.
	p.xy = mod(p.xy, vec2(1.75, 2.0))-.5;
    
    // The oil spots are just a clamped circle gradient
    // times a noise value.
    float spill = clamp(length(p.xy), 0.,1.);
	return clamp(spill+fbm(p*.25, n)*1.35, 0.,1.);
}

/*
	Returns a puddle dirt coefficient. This is keyed with the puddle reflectivity
	regions. 
*/
float tex_puddles(in vec3 p, in vec3 n)
{
    return mix(1.,.15, smoothstep(.5,.8, fbm(PUDDLESCALE*p, n)));
}

/*
	Ah yes, what every parking place needs: lines.
*/
float tex_lines(in vec3 p, in vec3 n)
{
    // Do some translation, scaling and repetition,
    // and the same "if we're here, return this, otherwise
    // send back the other" jive.
    p.xz *= vec2(.035, .2);
    p.xz -= vec2(.17, .5);
    if(mod(p.x,1.) < .65 && mod(p.z,1.) < .05) return 1.;
    return 0.;
}

/*
	Textures the walls, floor and ceiling of the garage.
*/
vec3 tex_garage(in vec3 p, in float d, in vec3 n, in vec3 cement)
{
    // Texture the walls.
    if(length(n.xz) > .1 && p.y < 2.5)
    {
        // That same ol' filtering technique.
        float f  = smoothstep(.7-.15*d, .7+.15*d, fbm(p*.125, n));
        return mix(WALLCOLOR*cement, cement, f);
    }
    // Put some stains and lines on the floor.
    if(n.y > .8)
    {
        float stains = tex_stains(p, n), 
			  lines = tex_lines(p, n), 
			  puddles = tex_puddles(p, n);
        return mix(PUDDLECOLOR, (cement + lines)*stains, puddles);
    }
    // Make the ceiling dark like in absolutely all underground garages.
    if(n.y < -.8)
    {
        return cement *.025;
    }
    // Oherwise just return the original cement color.
    else return cement;
}

/*
	Returns a generated texture element given a point in space,
	and that point's object ID.
*/
vec3 tex(in vec3 p, in vec3 e, in vec3 n, in float id)
{
    vec3 cement = cement_tex(p, n);
    float d = length(p-e)/MAX_DEPTH;
	if(id == ID_GARAGE) return tex_garage(p, d, n, cement);
	else if(id == ID_PILLAR) return tex_pillars(p, d, n, cement);
	else if(id == ID_RAFTER) return cement;  
	else if(id == ID_PIPES)  return tex_pipe(p, d, n);
	else if(id == ID_LIGHTS) return tex_lights(p, d, n);
    else if(id == ID_BOLLARDS) return tex_bollards(p, d, n, cement);
    else return WIRECOLOR;
	return vec3(1.,0.,0.);
}

/*
	Returns the surface normal of the distance field at the given
	point p.
*/
vec3 norm(vec3 p)
{
    // The math behind this is cool beans.
	return normalize(vec3(dist(vec3(p.x+EPSILON,p.y,p.z)),
						  dist(vec3(p.x,p.y+EPSILON,p.z)),
						  dist(vec3(p.x,p.y,p.z+EPSILON)))-dist(p));
}

/*
	The ray-marching function. Marches a point p along a direction dir
	until it reaches a point within a minimum distance of the distance
	field.
	Returns the object ID of the found object.
*/
float march(inout vec3 p, vec3 dir)
{
	vec2 r = distID(p+dir*EPSILON);
	for(int i = 0; i < V_STEPS; i++)
	{
		if(r.s < EPSILON)
			return r.t;
		p += dir*r.s;
        r = distID(p);
	}
	return r.t;
}

/*
	Simple marched reflection that returns the position and object ID of
	the imaged surface.
*/
float reflection( inout vec3 start, in vec3 ldir, out vec3 finish)
{    
	float t = EPSILON;
	vec2 iter, res = vec2(1.0);
    for ( int i = 0; i < R_STEPS; ++i )
    {
        finish = start + ldir*t;
        iter = distID( finish );
        if ( iter.s < EPSILON*.1 )
            return iter.t;
        t += iter.s;
		if ( t > MAX_DEPTH )
			break;
    }
    return res.t;
}

/*
	Generates a reflection deflection map, because no surface in a parking
	garage is perfectly flat.
*/
vec2 bumpmap(in vec3 p, in vec3 n, in float id)
{
    // The garage floor and ceiling have their own reflectivities.
    if(id == ID_GARAGE)
    {
        // The floor is bumpy, with some smoother spots where puddles are.
        if(n.y > 0.8)
        {
            vec2 bumpy = .5*vec2(fbm(p, n),fbm(-p, n)) - .25;
			vec2 smth = vec2(0.);
        	return mix(bumpy,smth,step(.6, fbm(.005*p, n)));
        }
        // The ceiling is bumpy everywhere, but not shiny everywhere, as
        // handled in the reflectivity function.
        else if(n.y < -.8)
            return .25*vec2(n3D(p, n),n3D(-p, n)) - .125;
        else return vec2(0.);
    }
    // The pipes are smoothish.
    else if(id == ID_PIPES)
    {
		p *= .1;
        return .25*vec2(n3D(p, n),n3D(-p, n)) - .125;
    }
    else return vec2(0.);
}

/*
	Returns how reflective a position is.
*/
float reflectivity(in vec3 p, in vec3 n, in vec3 d, in float id, in float rid)
{
    float r = 0.;
    // The garage floor and ceiling have their own reflectivities.
    if(id == ID_GARAGE)
    {
        // The floor is shinier where puddles are.
        if(n.y > 0.8)
        {   
            // This is keyed with the puddle texture.
            r = mix(.1,.2, step(.6, fbm(PUDDLESCALE*p, n)));
        }
        // The ceiling isn't shiny everywhere.
        else if(n.y < -.8)
            r = mix(.0, .075, smoothstep(.3,.7, fbm(.005*p, n)));
        else r = 0.0;
    }
    // The pipes are quite shiny.
    else if(id == ID_PIPES)
    {
        r = .333;
    }
    // If we are reflecting the lights, bump up how reflected they are to
    // mimick the reflection of a light source being brighter than the
    // rest of the reflected image.
    if(rid == ID_LIGHTS) r *= 2.0;
    return r*=pow(length(cross(n,d)),2.0);
}

/*
	Calculates the ambient occlusion factor at a given point in space.
	Uses IQ's marched normal distance comparison technique.
*/
float occlusion(in vec3 p, in vec3 n)
{
	float r = .0;
    float s = -OCC_SAMPLES;
    const float u = 1.0/OCC_SAMPLES;
	for(float i = u; i < 1.0; i+=u)
	{
		r += pow(2.0,i*s)*(i-dist(p+i*n));
	}
	return clamp(0.,1.,1.0-r*OCC_FACTOR);
}

/*
	Some super fake global illumination.
*/
vec3 gi(in vec3 p, in vec3 n, in float id)
{
	vec3 r = vec3(0.);
	if(id != ID_PIPES)
	{
		r += PIPECOLOR * pow(max(0., 1.0-pipes(p)),2.0)*.3;
	}
	return r;
}

/*
	Takes in a surface and eye position, and calculates an ambient and diffuse
	lighting term.
*/
void light(in vec3 p, in vec3 d, in vec3 e, in vec3 n, in float id,
		   out float amb, out float dif)
{
	if(id == ID_LIGHTS) amb = 1.0;
	else amb = occlusion(p, n);
   
	// Yep! The diffuse term is just the distance to the light.
    dif = clamp(1.0- pow( lights(p)*.1, 1.5 ), 0., 1.);
}

/*
	Shades a point, giving it lighting, reflection and texture.
*/
vec3 shade(in vec3 p, in vec3 d, in vec3 e, in float id)
{
	float amb, dif;	 // The ambient and diffuse lighting terms.
    vec3 n,			 // The surface normal at the first bounce.
         primary;	 // The primary and secondary colors.
    
    n = norm(p);	// Get the surface normal at the first bounce.
	light(p, d, e, n, id, amb, dif);	// Light the first bounce.
    primary = tex(p, e, n, id)*amb*dif*LCOLOR;	// Texture the first bounce.
	primary += gi(p, n, id);
	
    if((id == ID_GARAGE && abs(n.y) > .8) || id == ID_PIPES)
    {
		// The ID of the object in the reflection image.
		float rID;
		// The reflection's position, normal, direction and color.
		vec3 rp, rn, rd, secondary;
		
		// Create surface features so the reflections aren't pristine.
        n.xz += bumpmap(p, n, id);
		n = normalize(n);
		
		// Reflect the ray direction through the first surface normal.
		rd = reflect(d, n);
		// Get that reflection.
		rID = reflection(p, rd, rp);
		
		// Get the surface normal at the imaged position.
		rn = norm(rp);
		// Get the lighting at that point, using the new normal.
		light(rp, rd, p, rn, rID, amb, dif);
		// Get the texture in the reflection.
		secondary = tex(rp, p, rn, rID)*amb*dif*LCOLOR;
        
        return mix( primary, secondary, reflectivity(p, n, d, id, rID));
    }
	
	// Since we weren't on a reflective material we just return the
	// first color.
    else return primary;
}

/*
	Finalizes each pixel, performing tone-mapping and other post-processing 
	effects.
*/
vec3 post(vec2 uv, vec3 c)
{
	return pow(c, vec3(.4545));
}

/*
	Shadertoy's proprietary Main Image 2000 v2.0 A Realistic Other World & 
	Knuckles II HD Turbo Remix Last Round The Pre-Sequel Tactical Shading 
	Action function.
*/	
void mainImage(out vec4 color, in vec2 fragCoord)
{
    vec2 uv = fragCoord / iResolution.xy - 0.5;
	uv.x *= iResolution.x/iResolution.y; //fix aspect ratio
    
	vec3 pos, dir, eye;
	float id, shutter = 0.0;
    
    animate_cam(uv, iTime, pos, dir, shutter);
    
	eye = vec3(pos);
    
	id = march(pos, dir);
	color = vec4(post(uv,shade(pos, dir, eye, id)), 1.0)*shutter;
}

/*
	The Shadertoy VR entrypoint.
*/
/*
void mainV( out vec4 fragColor, in vec2 fragCoord, 
            in vec3 fragRayOri, in vec3 fragRayDir )
{
    vec2 uv = fragCoord / iResolution.xy - 0.5;
	uv.x *= iResolution.x/iResolution.y; //fix aspect ratio
    
	vec3 pos, dir, eye;
	float id, shutter = 0.0;
    
    animate_cam(uv, iTime, pos, dir, shutter);
    
    // I think this will work.
    pos += fragRayOri;
    dir = normalize(dir+fragRayDir);
    
	eye = vec3(pos);
    
	id = march(pos, dir);
	fragColor = vec4(post(uv,shade(pos, dir, eye, id)), 1.0)*shutter;
}*/