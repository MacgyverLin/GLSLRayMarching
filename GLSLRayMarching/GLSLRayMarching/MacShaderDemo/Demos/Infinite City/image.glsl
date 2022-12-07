// Infinite City
// Hazel Quantock - 2013
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.


// slightly shaky street-level view!
//#define FIRST_PERSON


vec2 Rand( vec2 pos )
{
	return textureLod( iChannel0, (pos+.5)/256.0, 0.0 ).xz;
}

vec3 VoronoiPoint(vec2 pos, vec2 delta )
{
	const float randScale = .8; // reduce this to remove axis-aligned hard edged errors
	
	vec2 p = floor(pos)+delta;
	vec2 r = (Rand(p)-.5)*randScale;
	vec2 c = p+.5+r;
	
	// various length calculations for different patterns
	//float l = length(c-pos);
	//float l = length(vec3(c-pos,.1));
	float l = abs(c.x-pos.x)+abs(c.y-pos.y); // more interesting shapes
	
	return vec3(c,l);
}

// For building height I want to know which voronoi point I used
// For side-walls I want difference between distance of closest 2 points
vec3 Voronoi( vec2 pos )
{
	// find closest & second closest points
	vec3 delta = vec3(-1,0,1);

	// sample surrounding points on the distorted grid
	// could get 2 samples for the price of one using a rotated (17,37) grid...
	vec3 point[9];
	point[0] = VoronoiPoint( pos, delta.xx );
	point[1] = VoronoiPoint( pos, delta.yx );
	point[2] = VoronoiPoint( pos, delta.zx );
	point[3] = VoronoiPoint( pos, delta.xy );
	point[4] = VoronoiPoint( pos, delta.yy );
	point[5] = VoronoiPoint( pos, delta.zy );
	point[6] = VoronoiPoint( pos, delta.xz );
	point[7] = VoronoiPoint( pos, delta.yz );
	point[8] = VoronoiPoint( pos, delta.zz );

	vec3 closest;
	closest.z =
		min(
			min(
				min(
					min( point[0].z, point[1].z ),
					min( point[2].z, point[3].z )
				), min(
					min( point[4].z, point[5].z ),
					min( point[6].z, point[7].z )
				)
			), point[8].z
		);
	
	// find second closest
	// maybe there's a better way to do this
	closest.xy = point[8].xy;
	for ( int i=0; i < 8; i++ )
	{
		if ( closest.z == point[i].z )
		{
			closest = point[i];
			point[i] = point[8];
		}
	}
		
	float t;
	t = min(
			min(
				min( point[0].z, point[1].z ),
				min( point[2].z, point[3].z )
			), min(
				min( point[4].z, point[5].z ),
				min( point[6].z, point[7].z )
			)
		);

	/*slower:
	float t2 = 9.0;
	vec3 closest = point[8];
	for ( int i=0; i < 8; i++ )
	{
		if ( point[i].z < closest.z )
		{
			t2 = closest.z;
			closest = point[i];
		}
		else if ( point[i].z < t2 )
		{
			t2 = point[i].z;
		}
	}*/
	
	return vec3( closest.xy, t-closest.z );
}


float DistanceField( vec3 pos, float dist )
{
	vec3 v = Voronoi(pos.xz);
	vec2 r = Rand(v.xy*4.0); // per-building seed
	
	float f = (.2+.3*r.y-v.z)*.5; //.7071; // correct for max gradient of voronoi x+z distance calc
	
	// random height
	float h = r.x; // v.xy is position of cell centre, use it as random seed
	h = mix(.2,2.0,pow(h,2.0));
	h = pos.y-h;

	// we get precision problems caused by the discontinuity in height
	// so clamp it near to the surface and then apply a plane at max height	
	h = max( min( h, .008*dist ), pos.y-2.0 );

//	f = max( f, h );
	if ( f > 0.0 && h > 0.0 )
		f = sqrt(f*f+h*h); // better distance computation, to reduce errors
	else
		f = max(f,h);
	
	f = min( f, pos.y ); // ground plane
	
	return f;
}

float DistanceField( vec3 pos )
{
	return DistanceField( pos, 10.0 );
}

// normal
// could do this analytically, by looking at the maths when comupting voronoi value
// but the lions share of the cost is in the trace, not this, so I shalln't worry
vec3 GetNormal( vec3 pos )
{
	vec3 n;
	vec2 delta = vec2(0,1);

	// allow a slight curve so it looks more interesting
	#ifdef FIRST_PERSON
		delta *= .004;
	#else
		delta *= .04;
	#endif
	
	n.x = DistanceField( pos+delta.yxx ) - DistanceField( pos-delta.yxx );
	n.y = DistanceField( pos+delta.xyx ) - DistanceField( pos-delta.xyx );
	n.z = DistanceField( pos+delta.xxy ) - DistanceField( pos-delta.xxy );

	// we get some black on surfaces because of flat spots in the voronoi
	// fix that by giving it an arbitrary (and incorrect) normal
	if ( dot(n,n) == 0.0 )
		n.y += 1.0;

	return normalize(n);
}


void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
/*	float f = Voronoi(fragCoord.xy/40.0).z;
	fragColor = vec4( vec3(f), 1.0 );*/
	
	vec2 mouse = iMouse.xy/iResolution.xy;

	float h;
	#ifdef FIRST_PERSON
		vec2 rot = vec2(-.2,.0)+vec2(6.28,-1.5)*mouse;
		
	//	vec3 rayStart = vec3(.1,.03,.1);//vec3(0,10,0) + vec3(1,0,1)*iTime + vec3(0,-8,0)*mouse.y;
	//	rayStart += -10.0*vec3(sin(rot.x),0,cos(rot.x));
	
		vec3 rayStart = vec3(0,.03,0) + iTime*vec3(-.02,0,.02);
		// find closest road to the right
		h = 1.0;
		for ( int i=0; i < 20; i++ )
		{
			if ( h < .01 )
				break;
			h = Voronoi( rayStart.xz ).z*.3;
			rayStart.xz += h;
		}
	
		float zoom = .7;
	#else
		vec2 rot = vec2(-.2,.28)+vec2(1.6,.5)*mouse;
		
		vec3 rayStart = vec3(0,5,0) + vec3(1,0,1)*iTime + vec3(0,6,0)*mouse.y;
		rayStart += -10.0*vec3(sin(rot.x),0,cos(rot.x));

		float zoom = 1.0;
	#endif
	
	vec3 rayDir = normalize( vec3( fragCoord.xy-iResolution.xy*.5, iResolution.x * zoom ) );
	rayDir.yz = rayDir.yz*cos(rot.y)+rayDir.zy*sin(rot.y)*vec2(-1,1);
	rayDir.xz = rayDir.xz*cos(rot.x)+rayDir.zx*sin(rot.x)*vec2(1,-1);

	// trace
	float t = 0.0;
	h = 1.0;
	for ( int i=0; i < 300; i++ )
	{
		if ( h < .001 )
			break;
		
		h = DistanceField(rayStart+rayDir*t, t);
		t += h;
	}
	
	// shade
	vec3 pos = rayStart+rayDir*t;
	vec3 norm = GetNormal(pos);
	vec3 v = Voronoi(pos.xz);
	
	vec2 r = Rand( v.xy ).xy;
	vec4 albedo = mix( mix( vec4(.4,.2,.0,0), vec4(1,1,1,0), r.x ),
					   mix( vec4(0,.2,.6,1), vec4(0,0,0,1), r.x ),
					   r.y );
	
	// floors
	if ( fract(pos.y*8.0) < .4 )
		albedo = mix( vec4(0,0,0,0), vec4(1,1,1,0), r.x );

	// remove reflection on rooves!
	albedo.w = mix ( albedo.w, 0.0, step( .2, norm.y ) );
	
	// roads
	albedo = mix( vec4(.05,.05,.05,0), albedo, step( .07, abs(v.z-.08) ) );
	
	vec3 lighting = max(0.0,dot(norm,normalize(vec3(-2,3,-1))))*vec3(1,.9,.8);
	lighting += vec3(.2); //ambient
	
	vec3 result = albedo.xyz * lighting;
	
	// reflections
	float fresnel = pow(1.0+dot(norm,rayDir),5.0);
	if ( fresnel > 1.0 ) fresnel = 0.0;
	fresnel = mix( .2, 1.0, fresnel );
	
	vec3 reflection = texture( iChannel1, reflect(rayDir,norm).xz/8.0 ).rgb*3.0;
	
	result = mix( result, reflection, fresnel*albedo.w );

	if ( h > .01 )//&& rayDir.y > 0.0 )
	{
		// sky
		result = mix( vec3(.3), vec3(.85,1.0,1.2), smoothstep( -.1,.1,rayDir.y ) );
	}
	
	// fake ambient occlusion
	result *= mix( .2, 1.0, smoothstep( 0.0, .7, pos.y ) );
	
	// fog
	//result = mix( vec3(.85,1.0,1.2), result, exp(-t*.02) );
	//More realistic fog
	result *= pow( vec3(.7,.57,.3), vec3(t*.02) ); // absorb more blue on distant things
	result += vec3(.7,.9,1.2)*(1.0-exp(-t*.02));
	
	fragColor = vec4(result,1);
}