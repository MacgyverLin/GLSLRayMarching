
#define t2D(x, y) texture(iChannel0, fract(uv-vec2(x, y)/res))


float terrain(vec2 p){
    float temp=10.;
    if(abs(p.x)>5. || abs(p.y)>5.) return 0.;
    return texture(iChannel0, p/10. + vec2(0.5,0.5)).x*2. - 1.2;
}

float water(vec2 p){
    float temp=10.;
    if(abs(p.x)>5. || abs(p.y)>5.) return 0.;
    return texture(iChannel0, p/10. + vec2(0.5,0.5)).y;
}

vec3 calculate_normal(vec3 p)
{    
    float height_mod = 1.;
    float prec = 0.01;
    float xp = terrain(p.xz+vec2(prec,0.))*height_mod;
    float xm = terrain(p.xz-vec2(prec,0.))*height_mod;
    
    float zp = terrain(p.xz+vec2(0.,prec))*height_mod;
    float zm = terrain(p.xz-vec2(0.,prec))*height_mod;
    
    //vec3 dx = vec3(p.xz+vec2(0.001, 0.), xp) - vec3(p.xz-vec2(0.001,0.), xm);
    //vec3 dy = vec3(p.xz+vec2(0.,0.001), zp) - vec3(p.xz-vec2(0.,0.001), zm);
    
    vec3 dx = vec3(p.x+prec, xp, p.y) - vec3(p.x-prec, xm, p.y);
    vec3 dy = vec3(p.x, zp, p.y+prec) - vec3(p.x, zm, p.y-prec);
    
    return cross(normalize(dx), normalize(dy));
}

bool pointTerrain(vec3 p){
    float terrain_range = 3.;
    if(abs(p.x)>5. || abs(p.y)>5.) return false;
    return terrain(p.xz) >= p.y*0.5;
}

vec3 castRayTerrain2(vec3 camPos, vec3 camDir){
    for(float i=1.; i<12.; i+=.01){
    	vec3 p = camPos + i*camDir;
        
        if (p.y <0.) break;
        if(pointTerrain(p)){
            vec3 col = vec3(p.xz, terrain(p.xz));
            vec3 normal = calculate_normal(p);
            
            float lightDist = 9.;
            float lightHeight = 5.;
            vec3 light_position = vec3(lightDist*cos(-iTime), lightHeight, lightDist*sin(-iTime));
            light_position = camPos + vec3(-5.,0.,1.);
            
            vec3 direction_to_light = normalize(p - light_position);
            float diffuse_intensity = max(0.0, dot(normal, direction_to_light));
            
            vec3 color=vec3(1,0,0);
            float temp = p.y;
            p.y/=3.5;
            if(p.y<0.18) color = vec3(0.2,0.2 + 0.8 *p.y*p.y*30.,1)*(p.y*3.+.4);
            else if(p.y<0.22) color = vec3(246./255.,215./255.,150./255.)*(1.-p.y)*1.5;
            else if(p.y<0.3) color = vec3(11./255.,102./255.,35./255.);
            else if(p.y<0.33) color = vec3(139./255.,69./255.,19./255.);
            else color = vec3(1.);
                
            vec3 eye = normalize(vec3(p.x, terrain(p.xz), p.z)-camPos);
            vec3 reflec = 2.*normal*dot(normal, direction_to_light)-direction_to_light;
            float spec = dot(eye, reflec);
            spec = pow(spec, 5.);
            //spec*=0.2;
            //spec *= water(p.xz)*300.;
            spec=0.;
            
            color  = 1. * terrain(p.xz) * vec3(.8, .5, .2);
            color = fbm(p.xz*0.2)*vec3(34./255., 139./255., 34./255.);
            //color = mix(color, vec3(1.), 0.5*max(0.,));
            
            if(normal.y>-0.91) color = mix(color, vec3(139./255.,69./255.,19./255.)*0.4, -normal.y*0.8);
            //color = mix(color, vec3(114./255., 98./255., 91./255.), terrain(p.xz)*0.9);
            color = mix(color, vec3(130./255., 100./255., 80./255.), terrain(p.xz)*0.9);
            
            if(dot(normal, -vec3(0,1,0))>0.99) color = vec3(1.)*0.6;
            if(water(p.xz)>0.0002) color = vec3(1.)*0.6;//vec3(139./255.,69./255.,19./255.)*0.4;
            
            
            
            
            
            //spec *= length(color)*length(color)*0.2;
            diffuse_intensity *=2.;
            return color*0.1 + color*diffuse_intensity + vec3(1.)*spec;
        }
    }
    return vec3(1.);//vec3(.5,.8,.9);
}





float landMap(vec3 p) {
    return p.z - texture(iChannel0, fract(p.xy)).r;
}

float waterMap(vec3 p) {
    return p.z - (texture(iChannel0, fract(p.xy)).r+texture(iChannel0, fract(p.xy)).g);
}

float getProx(vec3 p, float dist) {
    vec3 o = vec3(-dist, dist, 0.);
    vec2 res = .01 * iResolution.xy;
	return
    	(
            landMap(p+o.xzz/res.xyy) + landMap(p+o.yzz/res.xyy) +
			landMap(p+o.zxz/res.xyy) + landMap(p+o.zyz/res.xyy) +
			landMap(p+o.zzx/res.xyy) + landMap(p+o.zzy/res.xyy)  
		) / dist;
}

/*

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
	vec2 res = iResolution.xy;
    vec2 uv = fragCoord.xy / res;
    
    float lh = t2D(0.,  0.).r;
    float wv = t2D(0.,  0.).g;
    wv=0.;
    vec3 landCol  = .65 * lh * vec3(.8, .5, .2);
    vec3 waterCol = max(0., 1.-16.*wv) * vec3(.2, .4, .7);
    vec3 outCol;
    
    vec3 lightPos = normalize(vec3(4.*(iMouse.xy/res-.5), 1.));
    
    vec3 p = vec3(uv, lh);
    
    vec3 o = vec3(-1., 1., 0.);
    vec3 landNorm =
        vec3(
			landMap(p-o.xzz/res.xyy)-landMap(p-o.yzz/res.xyy),
			landMap(p-o.zxz/res.xyy)-landMap(p-o.zyz/res.xyy),
			landMap(p-o.zzx/res.xyy)-landMap(p-o.zzy/res.xyy)
		);
    
    vec3 waterNorm =
        vec3(
			waterMap(p-o.xzz/res.xyy)-waterMap(p-o.yzz/res.xyy),
			waterMap(p-o.zxz/res.xyy)-waterMap(p-o.zyz/res.xyy),
			waterMap(p-o.zzx/res.xyy)-waterMap(p-o.zzy/res.xyy)
		);
    
    // cheap ao
    landCol += .1 * getProx(p, .02);
    landCol += .3 * getProx(p, .07);
    
    // add diffuse reflection to landscape
    landCol += .45 * max(0., dot(normalize(landNorm), lightPos));
    
    // mix bump-mapped land and unmodified water color
    waterCol = mix(waterCol, landCol, .5);
    
    // add specular reflection to water
    vec3 ref = reflect(-lightPos, normalize(waterNorm));
    waterCol +=  .5 * pow(max(0., dot(normalize(waterNorm), ref)), 8.);
    
    // mix land color with water color based on water volume
    outCol = mix(landCol, waterCol, step(4./65535., wv));
    
	fragColor = vec4(outCol, 1.);
    //fragColor = vec4(lh, 0, 0, 1.);
}
*/

vec3 spherePos = vec3(0,0,0);

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = fragCoord/iResolution.x;
    uv-=vec2(0.5,0.5*iResolution.y/iResolution.x);
    uv*=2.;

    //camera stuff
    //vec3 camPos = vec3(-2.,0.,-5.*abs(sin(iTime*0.1)));
    vec3 camPos = vec3(0.,2.+3.*abs(sin(iTime)),-5.);
    camPos = vec3(0.,2.,-6.);
    float camDist = 7.;
    float camSpeed = 0.3;
    camPos = vec3(camDist*cos(camSpeed*iTime), 4., camDist*sin(camSpeed*iTime));
    vec3 camDir = normalize(spherePos - camPos);
    
    vec3 uvDir = vec3(uv,1);
    
    //Getting the 3 camera vectors
    vec3 camUp = normalize(vec3(0,1,0)-camDir*dot(camDir, vec3(0,1,0)));
    vec3 camSide = cross(camUp, camDir);
    
    //Transforming it into the uv plane
    vec3 planeCenter = camPos + camDir;
    vec3 planePoint = planeCenter + uv.x*camSide + uv.y*camUp;
    
    uvDir = normalize(planePoint - camPos);
    
    
    //vec3 pointDest = camPos+camDir+ uv.x*camSide*iResolution.x + uv.y*camUp*iResolution.y;
    //vec3 pointDir = normalize(pointDest - camDir); 

    //vec3 col = castRayTerrain2(camPos, pointDir);
    
    vec3 col = castRayTerrain2(camPos, uvDir);
    //vec3 col = castRayTerrain_mod(camPos, uvDir);
    
    //vec3 col = castRaySphere(camPos, camDir2);
    //vec3 col = castRaySphere(camPos, uvDir);
    
    //col = calculate_normal(uv.xyy);
    //col = vec3(fbm(uv));
    //col = vec3(uv, fbm(vec3(uv*4., 0.)));
    
    //col = vec3(uv, 0.)*fbm(vec3(uv, 0.));
    

    // Output to screen
    fragColor = vec4(col,1.0);
    //fragColor = vec4(fbm(vec3(uv, 0.)));
    
    //fragColor=vec4(texture(iChannel0, fragCoord.xy/iResolution.xy).x);
    //fragColor = vec4(terrain(uv*10.));
}