const float epsilon = 0.02;
const float pi = 3.14159265359;
const float speed = 3.0;
const vec3 wallsColor = vec3(0.05, 0.025, 0.025);
const vec3 lightColor = vec3(0.3, 0.6, 1.0);
const vec3 lightColor2 = vec3(0.5, 0.35, 0.35);
const vec3 fogColor = vec3(0.05, 0.05, 0.2);
const float curvAmout = 0.075;
const float reflAmout = 0.8;

//Distance Field functions by iq :
//https://iquilezles.org/articles/distfunctions
float sdCylinder( vec3 p, vec3 c )
{
  return length(c.xy - p.xz) - c.z;
}

float sdCappedCylinder( vec3 p, vec2 h )
{
  vec2 d = abs(vec2(length(p.xz),p.y)) - h;
  return min(max(d.x,d.y),0.0) + length(max(d,0.0));
}

float sdSphere( vec3 p, float s )
{
  return length(p)-s;
}

float sdBox( vec3 p, vec3 b )
{
  vec3 d = abs(p) - b;
  return min(max(d.x,max(d.y,d.z)),0.0) + length(max(d,0.0));
}

vec3 opRep( vec3 p, vec3 c )
{
    return mod(p,c)-0.5*c;
}

vec2 linearStep2(vec2 mi, vec2 ma, vec2 v)
{
    return clamp((v - mi) / (ma - mi), 0.0 ,1.0);
}

float tunnel( vec3 p, vec3 c )
{
  return -length(c.xy - p.xz) + c.z;
}

vec4 distfunc(vec3 pos)
{
    vec3 repPos = opRep(pos, vec3(4.0, 1.0, 4.0));
    vec2 sinPos = sin((pos.z * pi / 8.0) + vec2(0.0, pi)) * 1.75;
    vec3 repPosSin = opRep(pos.xxz + vec3(sinPos.x, sinPos.y, 0.0), vec3(4.0, 4.0, 0.0));
    
    float cylinders = sdCylinder(vec3(repPos.x, pos.y, repPos.z), vec3(0.0, 0.0, 0.5));
    float s = sin(iTime*3.0 + floor(pos.z*0.25));
    float cutCylinders1 = sdBox(vec3(pos.x, pos.y, repPos.z), vec3(100.0, clamp(s, 0.025, 0.75), 1.0));
    float cutCylinders2 = sdBox(vec3(repPos.x, pos.y, repPos.z), vec3(0.035, 100.0, 10.0));
    float cuttedCylinders = max(-cutCylinders2, max(-cutCylinders1, cylinders));
    
    float innerCylinders = sdCylinder(vec3(repPos.x, pos.y, repPos.z), vec3(0.0, 0.0, 0.15));
    float tubes1 = sdCylinder(vec3(repPosSin.x, 0.0, pos.y - 0.85), vec3(0.0, 0.0, 0.025));
    float tubes2 = sdCylinder(vec3(repPosSin.y, 0.0, pos.y + 0.85), vec3(0.0, 0.0, 0.025));
    float tubes = min(tubes1, tubes2);  
    float lightsGeom = min(tubes, innerCylinders);
    
    float resultCylinders = min(cuttedCylinders, lightsGeom);
    
    float spheres = sdSphere(vec3(repPos.x, pos.y, repPos.z), (s*0.5+0.5)*1.5);
    float light = min(tubes, spheres);
    
    vec2 planeMod = abs(fract(pos.xx * vec2(0.25, 4.0) + 0.5) * 4.0 - 2.0) - 1.0;
    float planeMod2 = clamp(planeMod.y, -0.02, 0.02) * min(0.0, planeMod.x);
    float cylindersCutPlane = sdCylinder(vec3(repPos.x, pos.y, repPos.z), vec3(0.0, 0.0, 0.6));
    float spheresCutPlane = sdSphere(vec3(repPos.x, pos.y, repPos.z), 1.3);
    
    float plane = 1.0 - abs(pos.y + clamp(planeMod.x, -0.04, 0.04) + planeMod2);
    float t = tunnel(pos.xzy * vec3(1.0, 1.0, 3.0), vec3(0.0, 0.0, 8.5));
    float cutTunnel = sdBox(vec3(pos.x, pos.y, repPos.z), vec3(100.0, 100.0, 0.1));
    plane = min(max(-cutTunnel, t), max(-spheresCutPlane, max(-cylindersCutPlane, plane)));
    
    float dist = min(resultCylinders, plane);
    float occ = min(cuttedCylinders, plane);
    
    float id = 0.0;
    
    if(lightsGeom < epsilon)
    {
       id = 1.0; 
    }
    
	return vec4(dist, id, light, occ);
}

vec3 rayMarch(vec3 rayDir, vec3 cameraOrigin)
{
    const int maxItter = 100;
	const float maxDist = 30.0;
    
    float totalDist = 0.0;
	vec3 pos = cameraOrigin;
	vec4 dist = vec4(epsilon);
    
    for(int i = 0; i < maxItter; i++)
	{
		dist = distfunc(pos);
		totalDist += dist.x;
		pos += dist.x * rayDir;
        
        if(dist.x < epsilon || totalDist > maxDist)
		{
			break;
		}
	}
    
    return vec3(dist.x, totalDist, dist.y);
}

vec3 rayMarchReflection(vec3 rayDir, vec3 cameraOrigin)
{
    const int maxItter = 30;
	const float maxDist = 20.0;
    
    float totalDist = 0.0;
	vec3 pos = cameraOrigin;
	vec4 dist = vec4(epsilon);

    for(int i = 0; i < maxItter; i++)
	{
		dist = distfunc(pos);
		totalDist += dist.x;
		pos += dist.x * rayDir;
        
        if(dist.x < epsilon || totalDist > maxDist)
		{
			break;
		}
	}
    
    return vec3(dist.x, totalDist, dist.y);
}

//Inpired From iq's ao :
//https://www.shadertoy.com/view/Xds3zN
vec2 AOandFakeAreaLights(vec3 pos, vec3 n)
{
	vec4 res = vec4(0.0);
    
	for( int i=0; i<3; i++ )
	{
		vec3 aopos = pos + n*0.3*float(i);
		vec4 d = distfunc(aopos);
		res += d;
	}
    
    float ao = clamp(res.w, 0.0, 1.0);
    float light = 1.0 - clamp(res.z*0.3, 0.0, 1.0);
    
	return vec2(ao, light * ao);   
}

//Camera Function by iq :
//https://www.shadertoy.com/view/Xds3zN
mat3 setCamera( in vec3 ro, in vec3 ta, float cr )
{
	vec3 cw = normalize(ta-ro);
	vec3 cp = vec3(sin(cr), cos(cr),0.0);
	vec3 cu = normalize( cross(cw,cp) );
	vec3 cv = normalize( cross(cu,cw) );
    return mat3( cu, cv, cw );
}

//Normal and Curvature Function by Nimitz;
//https://www.shadertoy.com/view/Xts3WM
vec4 norcurv(in vec3 p)
{
    vec2 e = vec2(-epsilon, epsilon);   
    float t1 = distfunc(p + e.yxx).x, t2 = distfunc(p + e.xxy).x;
    float t3 = distfunc(p + e.xyx).x, t4 = distfunc(p + e.yyy).x;

    float curv = .25/e.y*(t1 + t2 + t3 + t4 - 4.0 * distfunc(p).x);
    return vec4(normalize(e.yxx*t1 + e.xxy*t2 + e.xyx*t3 + e.yyy*t4), curv);
}

vec4 lighting(vec3 n, vec3 rayDir, vec3 reflectDir, vec3 pos)
{
    vec3 light = vec3(0.0, 0.0, 2.0 + iTime * speed);
    vec3 lightVec = light - pos;
	vec3 lightDir = normalize(lightVec);
    float atten = clamp(1.0 - length(lightVec)*0.1, 0.0, 1.0);
    float spec = pow(max(0.0, dot(reflectDir, lightDir)), 10.0);
    float rim = (1.0 - max(0.0, dot(-n, rayDir)));

    return vec4(spec*atten*lightColor2 + rim*0.2, rim); 
}

vec3 color(float id, vec3 pos)
{
    vec2 fp = vec2(1.0) - linearStep2(vec2(0.0), vec2(0.01), abs(fract(pos.xz * vec2(0.25, 1.0) + vec2(0.0, 0.5)) - 0.5));
    float s = fp.y + fp.x;
    return mix(wallsColor + s*lightColor*0.5, lightColor, id);
}

vec4 finalColor(vec3 rayDir, vec3 reflectDir, vec3 pos, vec3 normal, float ao, float id)
{
	vec4 l = lighting(normal, rayDir, reflectDir, pos);
	vec3 col = color(id, pos);
    float ao1 = 0.5 * ao + 0.5;
    float ao2 = 0.25 * ao + 0.75;
    vec3 res = (mix(col * ao1, col, id) + l.xyz) * ao2;
	return vec4(res, l.w); 
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord.xy/iResolution.xy;
    
    float move = iTime * speed;
    vec2 sinMove = sin((move * pi) / 16.0 + vec2(1.0, -1.0)) * vec2(5.0, 0.35);
    float camX = sinMove.x;
    float camY = 0.0;
    float camZ = -5.0 + move;                 
    vec3 cameraOrigin = vec3(camX, camY, camZ);
    
	vec3 cameraTarget = vec3(0.0, 0.0, cameraOrigin.z + 10.0);
    
	vec2 screenPos = uv * 2.0 - 1.0;
    
	screenPos.x *= iResolution.x/iResolution.y;
    
    mat3 cam = setCamera(cameraOrigin, cameraTarget, sinMove.y);
    
    vec3 rayDir = cam*normalize(vec3(screenPos.xy,1.0));
    vec3 dist = rayMarch(rayDir, cameraOrigin);
    
    vec3 res;
    vec2 fog;

	if(dist.x < epsilon)
    {
        vec3 pos = cameraOrigin + dist.y*rayDir;
        vec4 n = norcurv(pos);
        vec2 ao = AOandFakeAreaLights(pos, n.xyz);
        vec3 r = reflect(rayDir, n.xyz);
        vec3 rpos = pos + n.xyz*0.02;
        vec3 reflectDist = rayMarchReflection(r, rpos);
        fog = clamp(1.0 / exp(vec2(dist.y, reflectDist.y)*vec2(0.15, 0.2)), 0.0, 1.0);
        vec4 direct = finalColor(rayDir, r, pos, n.xyz, ao.x, dist.z) + n.w*curvAmout;
        
        vec4 reflN;
        vec2 reflAO;
        vec3 reflFinal;
        
        if(reflectDist.x < epsilon)
    	{
        	vec3 reflPos = rpos + reflectDist.y*r;
        	reflN = norcurv(reflPos);
            reflAO = AOandFakeAreaLights(reflPos, reflN.xyz);
            vec3 rr = reflect(r, reflN.xyz);
            vec4 refl = finalColor(r, rr, reflPos, reflN.xyz, reflAO.x, reflectDist.z);
            vec3 reflAreaLights = reflAO.y * lightColor * 0.5;
            reflFinal = (refl.xyz + reflN.w*curvAmout + reflAreaLights) * fog.y * reflAmout * direct.w;
        }
        else   
        {
            reflFinal = vec3(0.0, 0.0, 0.0);
        }
        
        vec3 areaLightsColor = ao.y * lightColor * 0.5;
        
        res = mix(fogColor, direct.xyz + reflFinal + areaLightsColor, fog.x);
    }
    else
    {
        res = fogColor; 
        fog = vec2(0.0);
    }
    
	fragColor = vec4(res, (dist.z) * fog);
}