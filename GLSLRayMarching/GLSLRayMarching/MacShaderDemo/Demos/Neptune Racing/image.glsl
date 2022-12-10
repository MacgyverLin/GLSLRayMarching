// Neptune Racing. December 2014
// https://www.shadertoy.com/view/XtX3Rr


// Uses sphere tracing to accumulate direction normals across the landscape.
// Materials are calculated after the tracing loop from alphas and distances
// stored in a stack.
// Change ScoopRadius for depth of field.

#define PI 3.141596
vec3 sunLight  = normalize( vec3(  0.35, 0.2,  0.3 ) );
vec3 moon  = vec3(  45000., 30000.0,  -30000. );
const vec3 sunColour = vec3(.4, .6, 1.);
#define FOG_COLOUR vec3(0.07, 0.05, 0.05)
vec4 aStack[2];
vec4 dStack[2];
vec2 fcoord;


//--------------------------------------------------------------------------
float Hash(vec2 p)
{
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 33758.5453)-.5;
}

//--------------------------------------------------------------------------
float Noise(in vec3 x)
{
    vec3 p = floor(x);
    vec3 f = fract(x);
	f = f*f*(3.0-2.0*f);
	vec2 uv = (p.xy+vec2(37.0,17.0)*p.z) + f.xy;
	vec2 rg = textureLod( iChannel2, (uv+ 0.5)/256.0, 0.0 ).yx;

	return mix( rg.x, rg.y, f.z );
}

//-----------------------------------------------------------------------------------
const mat3 m = mat3( 0.00,  0.80,  0.60,
                    -0.80,  0.46, -0.48,
                    -0.60, -0.38,  0.64 ) * 2.43;
float Turbulence( vec3 p )
{
    float f;
    f  = 0.5000*Noise( p ); p = m*p;
    f += 0.2500*Noise( p ); p = m*p;
    f += 0.1250*Noise( p ); p = m*p;
    f += 0.0625*Noise( p ); p = m*p;
    f += 0.0312*Noise( p ); 
	return f;
}

//--------------------------------------------------------------------------
float SphereIntersect( in vec3 ro, in vec3 rd, in vec4 sph )
{
	vec3 oc = ro - sph.xyz;
	float b = dot( oc, rd );
	float c = dot( oc, oc ) - sph.w*sph.w;
	float h = b*b - c;
	if( h<0.0 ) return -1.0;
	return -b - sqrt( h );
}

//-----------------------------------------------------------------------------------
float Terrain( in vec2 q, float bias )
{
	float tx1 = smoothstep( 0.,.4, textureLod( iChannel0, 0.000015*q, bias ).y);
    tx1   = mix(tx1, textureLod( iChannel1, 0.00003*q, bias ).x, tx1);
	return tx1*355.0;
}


//--------------------------------------------------------------------------
float Map( in vec3 p )
{
	float h = Terrain( p.xz, -100.0 );
	float  turb =Turbulence( p * vec3(1.0, 1., 1.0)*.05 ) * 25.3;
	return p.y-h+turb;
}
//--------------------------------------------------------------------------
// Grab all sky information for a given ray from camera
vec3 GetSky(in vec3 rd)
{
	float sunAmount = max( dot( rd, sunLight), 0.0 );
	float v = pow(1.0-max(rd.y,0.0),4.);
	vec3  sky = mix(vec3(.0,0.01,.04), vec3(.1, .04, .07), v);
	//sky *= smoothstep(-0.3, .0, rd.y);
	sky = sky + sunColour * sunAmount * sunAmount * .15;
	sky = sky + sunColour * min(pow(sunAmount, 1800.0), .3);
	return clamp(sky, 0.0, 1.0);
}
//--------------------------------------------------------------------------
 vec3 GetClouds(vec3 p,vec3 dir)
 {
    float n = (1900.0-p.y)/dir.y;
    vec2 p2 = p.xz + dir.xz * n;
    vec3 clo = textureLod(iChannel3, p2*.00001+.2,0.).zyz * .04;
	n = (1000.0-p.y)/dir.y;
	p2 = p.xz + dir.xz * n;
    clo += textureLod(iChannel0, p2*.00001-.4, 0.0).zyz * .04;
    clo = clo * pow(max(dir.y, 0.0), .8)*3.0;
     return clo;

 }

//--------------------------------------------------------------------------
float ScoopRadius(float t)
{
	t = abs(t-150.) * 1.;
	t = t*0.006;
	return clamp(t*t, 256.0/iResolution.y, 20000.0/iResolution.y);
}

//--------------------------------------------------------------------------
// Calculate sun light...
vec3 DoLighting(in vec3 mat, in vec3 normal, in vec3 eyeDir, in float d,in vec3 sky)
{
	float h = dot(sunLight,normal);
	mat = mat * sunColour*(max(h, 0.0));
	mat += vec3(0.01, .01,.02) * max(normal.y, 0.0);
    normal = reflect(eyeDir, normal);
    mat += pow(max(dot(sunLight, normal), 0.0), 50.0)  * sunColour * .5;
    mat = mix(sky,mat, min(exp(-d*d*.000002), 1.0));
	return mat;
}

//--------------------------------------------------------------------------
vec3 GetNormal(vec3 p, float sphereR)
{
	vec2 eps = vec2(sphereR*.5, 0.0);
	return normalize( vec3(
           Map(p+eps.xyy) - Map(p-eps.xyy),
           Map(p+eps.yxy) - Map(p-eps.yxy),
           Map(p+eps.yyx) - Map(p-eps.yyx) ) );
}

//--------------------------------------------------------------------------
float Scene(in vec3 rO, in vec3 rD)
{
    //float t = 0.0;
	float t = 8.0 * Hash(fcoord);
	float  alphaAcc = 0.0;
	vec3 p = vec3(0.0);
    int hits = 0;

	for( int j=0; j < 95; j++ )
	{
		if (hits == 8  || t > 1250.0) break;
		p = rO + t*rD;
		float sphereR = ScoopRadius(t);
		float h =Map(p);
		if(h < sphereR)
		{
			// Accumulate the alphas...
			float alpha = (1.0 - alphaAcc) * min(((sphereR-h) / sphereR), 1.0);
            // If high enough to contribute nicely...
            if (alpha > (1./8.0))
            {
				// If a peice of the lanscape is scooped as a suitable alpha,
                // then it's put on the stacks...
			// put it on the 2 stacks, alpha and distance...
                aStack[1].yzw = aStack[1].xyz; aStack[1].x = aStack[0].w;
                aStack[0].yzw = aStack[0].xyz; aStack[0].x = alpha;
                dStack[1].yzw = dStack[1].xyz; dStack[1].x = dStack[0].w;
                dStack[0].yzw = dStack[0].xyz; dStack[0].x = t;
                alphaAcc += alpha;	
                hits++;
            }
            
		}
		t +=  h * .5 + t * 0.004;
       
	}
    
	return clamp(alphaAcc, 0.0, 1.0);
}





//--------------------------------------------------------------------------
vec3 PostEffects(vec3 rgb, vec2 xy)
{
	// Gamma first...
	rgb = pow(rgb, vec3(0.45));

	// Then...
	#define CONTRAST 1.1
	#define SATURATION 1.4
	#define BRIGHTNESS 1.2
	rgb = mix(vec3(.5), mix(vec3(dot(vec3(.2125, .7154, .0721), rgb*BRIGHTNESS)), rgb*BRIGHTNESS, SATURATION), CONTRAST);

	// Vignette...
	rgb *= .5+0.5*pow(180.0*xy.x*xy.y*(1.0-xy.x)*(1.0-xy.y), 0.3 );	

	return clamp(rgb, 0.0, 1.0);
}

//--------------------------------------------------------------------------
vec3 TexCube( sampler2D sam, in vec3 p, in vec3 n )
{
	vec3 x = texture( sam, p.yz ).xyz;
	vec3 y = texture( sam, p.zx ).xyz;
	vec3 z = texture( sam, p.xy ).xyz;
	return (x*abs(n.x) + y*abs(n.y) + z*abs(n.z))/(abs(n.x)+abs(n.y)+abs(n.z));
}
//--------------------------------------------------------------------------
vec3 Albedo(vec3 pos, vec3 nor)
{
    vec3 col = TexCube(iChannel1, pos*.01, nor).xzy + TexCube(iChannel3, pos*.02, nor);
    return col * .5;
}

//--------------------------------------------------------------------------
 float cross2(vec2 A, vec2 B)
 {
	return A.x*B.y-A.y*B.x;
 }

//--------------------------------------------------------------------------
// Angle between 2 vectors...
 float GetAngle(vec2 A, vec2 B)
 {
	return atan(cross2(A,B), dot(A,B));
    //return  atan(B.y, B.x) - atan(A.y, A.x);
    //return (acos((A.x * B.x + A.y * B.y)/((sqrt(A.x*A.x + A.y*A.y) * sqrt(B.x*B.x + B.y*B.y))))/3.141);
}

//--------------------------------------------------------------------------
vec3 CameraPath( float t )
{
    float s = smoothstep(.0, 3.0, t);
	vec3 pos = vec3( t*30.0*s +120.0, 1.0, t* 220.* s -80.0);
	
	float a = t/4.0;
	pos.xz += vec2(1350.0 * cos(a), 350.0*sin(a));
    pos.xz += vec2(1400.0 * sin(-a*1.8), 400.0*cos(-a*4.43));

	return pos;
} 

//--------------------------------------------------------------------------
void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    fcoord = fragCoord;
	float m = 0.0;//(iMouse.x/iResolution.x)*10.0;
	float gTime = ((iTime+135.0)*.25+m);
    vec2 xy = fragCoord.xy / iResolution.xy;
	vec2 uv = (-1.0 + 2.0 * xy) * vec2(iResolution.x/iResolution.y,1.0);
	
	float hTime = mod(gTime+1.95, 2.0);
	
	vec3 cameraPos 	= CameraPath(gTime + 0.0);
	vec3 camTarget 	= CameraPath(gTime + .25);
    vec3 far	 	= CameraPath(gTime + .5);
    

    vec2 v1 = (far.xz-cameraPos.xz);
    vec2 v2 = (camTarget.xz-cameraPos.xz);
    float roll = clamp(GetAngle(v1 , v2)*2., -.9, .9  );
    
    
	float t = Terrain(cameraPos.xz, .0)+13.0;
    float t2 = Terrain(camTarget.xz, .0)+13.0;
    cameraPos.y = camTarget.y= t;
	
	//roll = roll;
	vec3 cw = normalize(camTarget-cameraPos);
	vec3 cp = vec3(sin(roll), cos(roll),0.0);
	vec3 cu = normalize(cross(cw,cp));
	vec3 cv = normalize(cross(cu,cw));
	vec3 dir = normalize(uv.x*cu + uv.y*cv + 1.1*cw);

	vec3 col = vec3(0.0);
	
    for (int i = 0; i <2; i++)
    {
		dStack[i] = vec4(-20.0);
        aStack[i] = vec4(0.0);
    }
	float alpha = Scene(cameraPos, dir);
	
     vec3 sky = GetSky(dir);
    // Render both stacks...
    for (int s = 0; s < 2; s++)
    {
        for (int i = 0; i < 4; i++)
		{
            float d = dStack[s][i];
            if (d < .0) continue;
            float sphereR = ScoopRadius(d);
            vec3 pos = cameraPos + dir * d;
            float occ = max(1.2-Turbulence(pos * vec3(1.0, 1., 1.0)*.05 )*1.2, 0.0);
            vec3 normal = GetNormal(pos, sphereR);
            vec3 c = Albedo(pos, normal);
			col += DoLighting(c, normal, dir, d, sky)* aStack[s][i]*occ;
        }
    }
    
   col += sky *  (1.0-alpha);
    
    if (alpha < .8)
    {
        // Do a quick moon...
        float t = SphereIntersect(cameraPos, dir, vec4(moon, 14000.0));
        if (t> 0.0)
        {
            vec3 moo = cameraPos + t * dir;
            vec3 nor = normalize(moo-moon);
            moo = TexCube(iChannel3, moo*.00001, nor)* max(dot(sunLight, nor), 0.0);
            
            sky = mix(sky, moo, .2);
        }
        else
        {
            float stars = pow(texture(iChannel2, vec2(atan(dir.x, dir.z), dir.y*2.0), -100.0).x, 48.0)*.35;
            stars *= pow(max(dir.y, 0.0), .8)*2.0;
            sky += stars;
        }
        sky += GetClouds(cameraPos, dir);
		col = mix(sky ,col, alpha);
    }

	col = PostEffects(col, xy) * smoothstep(.0, 2.0, iTime);	
	
	fragColor=vec4(col,1.0);
}
