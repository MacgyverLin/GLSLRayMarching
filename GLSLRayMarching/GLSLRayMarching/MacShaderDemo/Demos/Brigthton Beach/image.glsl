// Brighton Beach. David Hoskins - 2013
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

// It uses binary subdivision to accurately find the pebble height map.
// I've probably overdone the post noise effect, but tough, it's staying for now!

//v 1.1 Added water, plus colour gradient and extra shine to wet stones.
//v 1.2 Some optimisations.

//#define STEREO 
//#define VARY_SIZE

vec3 sunLight  = normalize( vec3(  0.35, 0.3,  0.6 ) );
vec3 cameraPos;
vec3 sunColour = vec3(1.0, .8, .7);
const mat2 rotate2D = mat2(1.932, 1.623, -1.623, 1.952);
float gTime;
 
//--------------------------------------------------------------------------
// Noise functions...
float Hash( float n )
{
    return fract(sin(n)*43758.5453123);
}

//--------------------------------------------------------------------------
float Hash(vec2 p)
{
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

//--------------------------------------------------------------------------
vec2 Hash2(vec2 p) 
{
	float r = 523.0*sin(dot(p, vec2(37.3158, 53.614)));
	return vec2(fract(17.12354 * r), fract(23.15865 * r));
}

//--------------------------------------------------------------------------
float Noise( in vec2 x )
{
    vec2 p = floor(x);
    vec2 f = fract(x);
    f = f*f*(3.0-2.0*f);
    float n = p.x + p.y*57.0;
    float res = mix(mix( Hash(n+  0.0), Hash(n+  1.0),f.x),
                    mix( Hash(n+ 57.0), Hash(n+ 58.0),f.x),f.y);
    return res;
}

//--------------------------------------------------------------------------
vec2 Noise2( in vec2 x )
{
    vec2 p = floor(x);
    vec2 f = fract(x);
    f = f*f*(3.0-2.0*f);
    vec2 res = mix(mix( Hash2(p), Hash2(p + vec2(1.0,0.0)),f.x),
                   mix( Hash2(p + vec2(0.0,1.0)), Hash2(p + vec2(1.0,1.0)),f.x),f.y);
    return res-vec2(.5);
}

//--------------------------------------------------------------------------
float CloudNoise( in vec2 uv )
{
	vec2 iuv = floor(uv);
	vec2 fuv = fract(uv);
	uv = (iuv + fuv*fuv*(3.0-2.0*fuv)) / 1024.0;
    return texture(iChannel0, uv, -100.0 ).z;
}

//--------------------------------------------------------------------------
float SmoothTerrain( in vec2 p)
{
	vec2 pos = p*0.013;
	float w = 27.0;
	vec2 dxy = vec2(0.0, 0.0);
	float f = .0;
	for (int i = 0; i < 3; i++)
	{
		f += Noise(pos) * w;
		w = -w * 0.5;
		pos *= 2.0;
	}
	// Slide down hill between -8 and 21 of pos.y for sea to appear...
	f -= smoothstep(-12.0, 23.0, pos.y)*30.0-2.0;
	return f;
}

//--------------------------------------------------------------------------
vec2 Terrain( in vec2 p)
{
	// type is either 0.0 for land or > 1.0 for depth in sea...
	float type = 0.0;
	float f = SmoothTerrain(p);
	// Now the pebbles...
	#ifdef VARY_SIZE
	p *= .38+(Noise2(p*.001)*.15);
	#else
	p *= .45;
	#endif
	p = p + Noise2(p);
	vec2 v2 = fract(p)-.5;
	f += max(.45-(dot(v2,v2)), 0.0)*(1.5+Hash(floor(p))*3.0);
	float water = Noise(p*.02+vec2(0.0, iTime*.28))*8.0+sin(p.y*.5+iTime)*.3;
	if (f < water)
	{
		type = 1.0+(water-f);
		f = water;
	}
	return vec2(f, type);
}

//--------------------------------------------------------------------------
vec2 Map(in vec3 p)
{
	vec2 h = Terrain(p.xz);
    return vec2(p.y - h.x, h.y);
}

//--------------------------------------------------------------------------
float Shadow( in vec3 ro, in vec3 rd)
{
	float res = 1.0;
	float t = .01;
	
	for (int i = 0; i < 6; i++) 
	{
        float d = Map(ro + rd * t).x;
        res = min(res, 0.1 * d / t);

        t += .05;
    }

    return clamp(res*1.7,.1, 1.0);
}
//--------------------------------------------------------------------------
float FractalNoise(in vec2 xy)
{
	float w = .8;
	float f = 0.0;

	for (int i = 0; i < 4; i++)
	{
		f += CloudNoise(xy) * w;
		w = w*0.5;
		xy = rotate2D * xy;
	}
	return f;
}

//--------------------------------------------------------------------------
vec3 GetClouds(in vec3 sky, in vec3 rd)
{
	//if (rd.y < 0.0) return sky;
    rd.y = max(rd.y,0.0);
	// Uses the ray's y component for horizon fade of fixed colour clouds...
	float v = (2300.0-cameraPos.y)/rd.y;
	rd.xz = (rd.xz * v + cameraPos.xz+vec2(300.0,-3830.0)) * 0.004;
	float f = (FractalNoise(rd.xz) -.1) * 3.0;
	vec3 cloud = mix(vec3(.25, .12, .02), vec3(.13, .12, .1), min(f*1.2, 1.0));
	sky = mix(sky, cloud, clamp(f*rd.y*rd.y*5.5, 0.0, 1.0));
	return sky;
}

//--------------------------------------------------------------------------
// Grab all sky information for a given ray from camera
vec3 GetSky(in vec3 rd)
{
    rd.y = abs(rd.y);
	float sunAmount = max( dot( rd, sunLight), 0.0 );
	float v = pow(1.0-max(rd.y,0.0),8.);
	vec3  sky = mix(vec3(.1, .15, .2), vec3(.27, .25, .22), v);
	sky = sky + sunColour * sunAmount * sunAmount * .3;
	sky = sky + sunColour * min(pow(sunAmount, 650.0)*.5, .1);
	return clamp(sky, 0.0, 1.0);
}

//--------------------------------------------------------------------------
// Merge peebles into te sky background for correct fog colouring...
vec3 ApplyFog( in vec3  rgb, in float dis, in vec3 dir)
{
	float fogAmount = clamp(dis* 0.000022, 0.0, 1.0);
	return mix( rgb, GetSky(dir), fogAmount );
}

//--------------------------------------------------------------------------
// Calculate sun light...
void DoLighting(inout vec3 mat, in vec3 pos, in vec3 normal, in vec3 eyeDir, in float dis)
{
	float h = dot(sunLight,normal);
	mat = mat * (max(h, 0.0)+.2);
	// Specular...
	vec3 R = reflect(sunLight, normal);
    float fre = pow(1.0 + dot(normal, eyeDir), 2.0) * 5.0;
	float specAmount = pow( max(dot(R, normalize(eyeDir)), 0.0), 20.0) * (.5+smoothstep(8.0, 0.0, pos.y)*4.0);
	mat = mix(mat, sunColour, specAmount*fre);
}

//--------------------------------------------------------------------------
vec3 Texturize(vec3 p, vec3 n )
{
	vec3 x = texture(iChannel3, p.yz, 1.0).xyz;
	vec3 y = texture(iChannel3, p.zx, 1.0).xyz;
	vec3 z = texture(iChannel3, p.xy, 1.0).xyz;
	return (x*abs(n.x) + y*abs(n.y) + z*abs(n.z))*.6;
}

//--------------------------------------------------------------------------
vec3 TerrainColour(vec3 pos, vec3 dir,  vec3 normal, float dis, float type)
{
	vec3 mat;
	dis *= dis;
	if (type >= 1.0)
	{
		// Sea...
		normal = normalize(reflect(dir, normal));
		mat = GetSky(normal);
		float sunAmount = max( dot( normal, sunLight), 0.0 );
		// Emphasise sun as a reflection,
		// because the sky reflect has been diminished...
		mat = mix(mat, sunColour, pow(sunAmount, 150.0)*2.0);
		mat = GetClouds(mat, normal);
		mat = mix(mat*mat, vec3(0.0, 0.005, .01), .3);
		// The depth of rocks appears to make a nice foam effect,
		// so I'll just let it do the whole job...
		// 'type' doubles up for material type and depth.
		mat = mix(vec3(1.0), mat, clamp((type-.4)*.3 + texture(iChannel0, pos.xz*.1).z*2.5, .85, 1.0));
		mat = ApplyFog(mat, dis, dir);
		return mat;
	}else
	{
		// Land...
		#ifdef VARY_SIZE
		vec2 p = pos.xz * (.38+(Noise2(pos.xz*.001)*.15));
		#else
		vec2 p = pos.xz * .45;
		#endif
		vec2 rnd = Noise2(p);
		mat.xy = floor(p+rnd);
		float f = Noise(mat.xy);
		if(f < .25) 
			mat = texture(iChannel0, p*.36).xyz;
		else
		if(f < .5) 
			mat = texture(iChannel1, p).xyz;
		else
		if(f < .75) 
			mat = texture(iChannel2, p*.12).xyz*.35;
		else
			mat = texture(iChannel3, p*1.3).xyz*.5;
		// Add some variation to the normal for a rougher wet look...
		normal = normalize(normal+Texturize(pos*.25, normal));
		mat *= smoothstep(1.0, 10.0, pos.y);
		DoLighting(mat, pos, normal,dir, dis);

		mat *= Shadow(pos, sunLight);
	}

	mat = ApplyFog(mat, dis, dir);
	return mat;
}

//--------------------------------------------------------------------------
// Home in on the surface by dividing by two and split...
float BinarySubdivision(in vec3 rO, in vec3 rD, float t, float oldT)
{
	float halfwayT = 0.0;
	for (int n = 0; n < 6; n++)
	{
		halfwayT = (oldT + t ) * .5;
		(Map(rO + halfwayT*rD).x < .1) ? t = halfwayT:	oldT = halfwayT;
		
	}
	return t;
}

//--------------------------------------------------------------------------
bool Scene(in vec3 rO, in vec3 rD, out float resT, out float type )
{
    float t = 8.;
	float oldT = 0.0;
	float delta = 0.4;
    bool ret = false;
	for( int j=0; j<110; j++ )
	{
		if (t > 220.0) break; // ...Too far awway
	    vec3 p = rO + t*rD;

		vec2 h = Map(p); // ...Get this position's height mapping.
		// Are we inside, and close enough to fudge a hit?...
		if( h.x < 0.1)
		{
			// Yes! So home in on height map...
///			resT = BinarySubdivision(rO, rD, t, oldT);
			type = h.y;
            ret = true;
			break;
		}
		// Delta ray advance - a fudge between the height returned
		// and the distance already travelled.
		// It's a really fiddly compromise between speed and accuracy
		delta = max(0.02, 0.5*h.x) + (t*0.005);
		oldT = t;
		t += delta;
	}
    if (ret) resT = BinarySubdivision(rO, rD, t, oldT);

	return ret;
}

//--------------------------------------------------------------------------
vec3 CameraPath( float t )
{
	float m = 1.0+(iMouse.x/iResolution.x)*300.0;
	gTime = (iTime*5.0+m+610.)*.006 + t;
    vec2 p = vec2(200.0 * sin(3.54*gTime), 75.0 * cos(3.0*gTime) );
	return vec3(p.x+55.0, 0.6, -94.0+p.y);
} 

//--------------------------------------------------------------------------
vec3 PostEffects(vec3 rgb, vec2 xy)
{
	// Gamma first...
	rgb = pow(rgb, vec3(0.45));
	
	// Then...
	#define CONTRAST 1.2
	#define SATURATION 1.3
	#define BRIGHTNESS 1.3
	rgb = mix(vec3(.5), mix(vec3(dot(vec3(.2125, .7154, .0721), rgb*BRIGHTNESS)), rgb*BRIGHTNESS, SATURATION), CONTRAST);
	// Tint and vignette...
	rgb *= vec3(.5, .5, .47) + 0.5*pow(50.0*xy.x*xy.y*(1.0-xy.x)*(1.0-xy.y), 0.2 );	
	// Noise...
	rgb = clamp(rgb-Hash(rgb.rb+xy*iTime)*.05, 0.0, 1.0);

	return rgb;
}

//--------------------------------------------------------------------------
void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 xy = fragCoord.xy / iResolution.xy;
	vec2 uv = (-1.0 + 2.0 * xy) * vec2(iResolution.x/iResolution.y,1.0);
	vec3 camTar;

	#ifdef STEREO
	float isCyan = mod(fragCoord.x + mod(fragCoord.y,2.0),2.0);
	#endif
	
	cameraPos.xz = CameraPath(0.0).xz;
	
	float tim = mod(gTime+.8, 1.9);
	float jump = max(sin(smoothstep(0.3, .8, tim)* 3.1415), 0.0) * 80.0;
	
	camTar.xz	 = CameraPath(.005).xz;
	cameraPos.y = SmoothTerrain(CameraPath(.005).xz) + jump + 10.0;
	// Bob camera above water line...
	if (cameraPos.y < 13.0)
	{
		float f = 13.0-cameraPos.y;
		cameraPos.y = 13.0 - f*(1.0-min(f/10.0, 1.0));
	}
	camTar.y = cameraPos.y-jump*.05;
	
	float roll = .4*sin(iTime*.25);
	vec3 cw = normalize(camTar-cameraPos);
	vec3 cp = vec3(sin(roll), cos(roll),0.0);
	vec3 cu = normalize(cross(cw,cp));
	vec3 cv = normalize(cross(cu,cw));
	vec3 dir = normalize( uv.x*cu + uv.y*cv + 1.5*cw );

	#ifdef STEREO
	cameraPos += .5*cu*isCyan; // move camera to the right - the rd vector is still good
	#endif

	vec3 col;
	float distance;
	float type;
	if( !Scene(cameraPos, dir, distance, type) )
	{
		// Missed scene, now just get the sky value...
		col = GetSky(dir);
		col = GetClouds(col, dir);
	}
	else
	{
		// Get world coordinate of landscape...
		vec3 pos = cameraPos + distance * dir;
		// Get normal from sampling the high definition height map
		// Use the distance to sample larger gaps to help stop aliasing...
		float p = min(.5, .001+.00005 * distance*distance);
		vec3 nor  	= vec3(0.0,		    Terrain(pos.xz).x, 0.0);
		vec3 v2		= nor-vec3(p,		Terrain(pos.xz+vec2(p,0.0)).x, 0.0);
		vec3 v3		= nor-vec3(0.0,		Terrain(pos.xz+vec2(0.0,-p)).x, -p);
		nor = cross(v2, v3);
		nor = normalize(nor);

		// Get the colour using all available data...
		col = TerrainColour(pos, dir, nor, distance, type);
	}


	col = PostEffects(col, xy);
	
	#ifdef STEREO	
	col *= vec3( isCyan, 1.0-isCyan, 1.0-isCyan );	
	#endif
	
	fragColor=vec4(col,1.0);
}

//--------------------------------------------------------------------------