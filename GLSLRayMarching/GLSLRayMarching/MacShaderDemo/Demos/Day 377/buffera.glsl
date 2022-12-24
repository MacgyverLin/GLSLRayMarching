
#define TAA false

vec3 getNormal(vec3 p);
vec3 getSun(vec2 uv, vec2 sunPos, vec3 sunPosW, vec3 ro, mat3 vp);
float t = 0.;
float grh = 0.;
float ng = 0.;

float rockTex = 0.;
vec2 rocks;
float rockn = 0.;
float rockDsmooth = 0.;

vec3 particlesAccum = vec3(0);
float particles = 0.;

float mapClouds(vec3 p){
    float currHeight = p.y;
    
    p *= 0.5;
    float cloudsRange = (cloudsHigherLimit - cloudsLowerLimit)*0.494;
    float cloudsMid = cloudsLowerLimit + cloudsRange;
    
    float fb = cyclicNoiseClouds(p*1. + iTime*0., false);
    float f = cyclicNoiseClouds(p*0.4 + iTime*0.04 + fb*0.3, true);
    //f = (f*0.4 + cyclicNoise(p*0.5 + f*2. - fb*1.4 + iTime))*cyclicNoise(p*0.2 + 5.+ f*4.);
        //f *= pow( smoothstep( 1.,0., abs(currHeight - cloudsHigherLimit + cloudsRange)/cloudsRange*0.9), 2.29);
    
    //f = fb;
    f = max(f,0.);
    f *= pow( smoothstep( 1.,0., abs(currHeight - cloudsHigherLimit + cloudsRange)/cloudsRange*0.9), 2.29);
    
    return f;
}




vec2 getGround(vec3 p){
    float d = p.y;
    vec3 pp = vec3(p.x,2.,p.z)*0.2;
    float n = cyclicNoiseTerrain(pp, false);
    float on = n;
    //n = pow((n),1.9);
    
    d -= n*2.3;
    
    return vec2(d,1.);
}


vec2 getRocks(vec3 p){
    float d = 10e4;
    
    
    
    float n = cyclicNoiseRocks(vec3(p.x,p.y*0.4,p.z)*0.4, false);
    
    n = smoothstep(0.6,1.,n);
    
    
    rockDsmooth = p.y - ( n*1.6) - 0.6;
    
    rockTex = n*texture(iChannel1,p.xz*0.2).x*0.24; 
    
    rockTex += texture(iChannel1,p.yx*0.4).x*0.03;
    rockTex += texture(iChannel1,p.yz*0.3).x*0.03;
    
    n += rockTex;
    
    
    d = p.y - ( rockn = n*1.6) - 0.6;
    
    
    return vec2(d,2.);
}

vec2 getGrass(vec3 p, float groundHeight, float scale){
    p.y = groundHeight;
    vec3 op = p;
    p.xz = pmod(p.xz,vec2(scale));
    p = abs(p);
    
    p.xz -= scale * 0.25;
    
    
    //p.xz += smoothstep(0.,1.,p.y)*cyclicNoiseGrass(op + vec3(0,iTime*2.,0), false)*0.4*(2. - 1.);
    
    //float d = sdVerticalCapsule( p, 0.4, 0.0001 );
    float d = sdRoundCone( p, 0.04, 0.0001, 0.4 );
    return vec2( d, 3.);
}
vec2 getFlowers(vec3 p, float groundHeight, float scale){
    p.y = groundHeight;
    vec3 op = p;
    
    p.xz *= rot(0.4);
    p.xz = pmod(p.xz,vec2(scale));
    //p = abs(p);
    
    p.y -= 0.5;
    
    p.xz = abs(p.xz);
    p.xz -= 0.7;
    p.xz = abs(p.xz);
    
    p.xz = abs(p.xz);
    float d = max(length(p + vec3(0,0.04,0)) - 0.05,abs(p.y + 0.04) - 0.004);
    p.xz -= 0.06;
    
    p.xz *= rot(0.25*pi);
    p.yz *= rot(0.9);
    
    p.x *= 0.5;
    d = min(
            d,
            max(length(p) - 0.05,abs(p.y) - 0.001)
        );
    
    
    return vec2( d, 4.);
}

float getParticles(vec3 p ){
    
    
    p.x += iTime*2.;
    
    p += ng;
    
    
    //p.x += sin(p.z*pi)*1.1;
    //p = pmod(p,2.);
    
    
    p = opRepLim( p, 5., vec3(1000000,1,100000) );
    
    float d = length(p);
    
    particlesAccum += (1. - particlesAccum)*smoothstep(0.02,0.0,d);
    
    return d - 0.003;
}

vec2 map(vec3 p){
    vec2 d = vec2(10e5);
    vec2 gr = getGround(p);
    float og = gr.x;
    vec2 rocks = getRocks(p);
    
    ng = cyclicNoiseGrass(vec3(p.x,p.y*0.1,p.z) + vec3(0,iTime*2.,0), false)*0.6*(2. - 1.) + 0.1;
    grh = cyclicNoiseGrass(p + vec3(0,0.,0), false)*0.4*(2. - 1.);
    vec3 gp = p;
    gp.xz += smoothstep(0.,1.,gr)*ng;
    
    
    vec2 flowers = getFlowers(gp, gr.x,5.4);
    
    vec2 grass = getGrass(gp, gr.x  + 0.4*(1.-grh*6.), 0.5);
    gp.xz *= rot(0.25);
    flowers = dmin(flowers, getFlowers(gp, gr.x,4.4).x, 4.);
    vec2 grassb = getGrass(gp + 0.2, gr.x - 0.4*grh, 0.5);
    gp.xz *= rot(0.5);
    flowers = dmin(flowers, getFlowers(gp, gr.x,4.4).x, 4.5);
    
    vec2 grassc = getGrass(gp + vec3(0.25,0,-0.2), gr.x - 0.4*sin(grh*20.), 0.5);
    gp.xz *= rot(0.25);
    flowers = dmin(flowers, getFlowers(gp, gr.x,3.4).x, 4.5);
    
    vec2 grassd = getGrass(gp + vec3(0.14,0,-0.2), gr.x  - 0.4*sin(grh*22.), 0.5);
    grass = dmin(grass, grassb.x,grassb.y );
    grass = dmin(grass, grassc.x,grassc.y );
    grass = dmin(grass, grassd.x,grassd.y );
    
    particles = getParticles(p);
    
    
    
    //grass.x = opSmoothSubtraction( -grass.x, -(rocks.x)*1.601 +0.804, 0.04 );
    
    
    rocks.x -= gr.x*0.6;
    //gr.x = opSmoothUnion( gr.x, rocks.x, 0.1 );
    
    
    d = dmin(d,gr.x,gr.y);
    d = dmin(d,rocks.x,rocks.y);
    d = dmin(d,grass.x,grass.y);
    d = dmin(d,flowers.x,flowers.y);
    
    
    
    if(d.y <= 2.)
        d.y = mix(1.,2.,smoothstep(0.,1.,exp(-rocks.x) - exp(-og*5.1)*7.1));
    
    
    
    return d;
}



void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec4 prevFrame = texture(iChannel2,fragCoord/iResolution.xy);

    if(TAA){
        vec2 taaidx = r23(vec3(fragCoord,float(iFrame)))*4.;
        fragCoord += float(iMouse.z>0.)*.6*vec2(sin(float(taaidx.x)*pi/4.),cos(float(taaidx.x)*pi/4.))*taaidx.y/4.;

    }
    
    
    vec2 uv = (fragCoord - 0.5*iResolution.xy)/iResolution.y;
    
    
    vec3 col = vec3(0);
    
    
    
    vec3 sunPos = vec3(-1,.4 + sin(iTime)*.12*0.,2.)*2300.;
    vec3 sunDir = normalize(sunPos);

    
    vec3 ro = vec3(0);
    
    ro.z += iTime;
    
    
    
    
    vec3 lookAt = vec3(0,0,ro.z + 15.*float(iMouse.z < 1.));
    vec2 muv = iMouse.xy/iResolution.xy;
    
    ro.y += muv.y*2210.;
        
        
    float T = -iTime*0.1;
    ro.xz -= vec2(cos(muv.x*6. + T),sin(muv.x*6. + T))*10.;
        
    if (iMouse.z > 0.) {
        
    }
    
    float ground = getGround(ro).x;
    
    ro.y -= ground;
    
    
    float rocks = getRocks(ro).x*1.04; 
    
    
    ro.y -= rockDsmooth*1.7 * smoothstep(0.5,0.2,rocks);;
    
    
    //ro.y -= smoothstep(rocks, 0.,rocks)*rocks*1.4;
    
    ro += groundOffs;
    lookAt.y -= getGround(lookAt).x;
    lookAt += groundOffs;
    
    
    mat3 vp = getRd(ro,lookAt);
    
    vec3 rd = normalize(vec3(uv,1.))*vp;
    
    //vec2 sunViewSpace = sunDir.xy;
    
    
    // Marching
    
    vec3 p = ro;
    vec2 d;
    for(int i = 0; i < marchSteps ; i++){
        d = map(p);
        
        if(i< 20)
            d.x = min(d.x,abs(particles) + 0.02);
    
        if(d.x < marchEps){
            hit = true;
            break;
        } else if (t > 69.){
            break;
        }
        
        p = ro + rd*(t += d.x * distScale);
    }
    
    
    float depthView;
    vec3 atmosphere = getAtmosphere(vec3(0,ro.y - 0.,0), rd, t, depthView, sunPos);
    
    
    // Clouds
    
    float lowerCloudLimitDist = plaIntersect( ro - vec3(0,cloudsLowerLimit,0), rd, vec4(0,-1,0,0) );
    float higherCloudLimitDist = plaIntersect( ro - vec3(0,cloudsHigherLimit,0), rd, vec4(0,-1,0,0) );
    
    float volumetricDith = r21(fragCoord + sin(iTime*20.)*20.)*volumetricDithAmt;
    
    float cloudLength = higherCloudLimitDist - lowerCloudLimitDist; 
    float cloudStepSz = cloudLength/(cloudSteps);
    vec3 cloudP = ro + rd * ( lowerCloudLimitDist + volumetricDith*cloudLength );
    
    
    float cloudDensTotal = 0.;
    vec3 cloudAccum = vec3(0.);
    
    
    for(float i = 0.; i < cloudSteps ; i++){
        float d = mapClouds(cloudP);
        
        float difffact = clamp( d*1. - mapClouds(cloudP + sunDir*1.4)*1.4  + 0.22, 0., 1. );
        vec3 diff = mix( atmosphere*0.2 + vec3(0.04,0.07,0.2)*(0.4 - smoothstep(0.,1.,1. - atmosphere*1.8)*0.1), (vec3(1,0.9,0.9)*1. + sunCol*0.4 + atmosphere*.4)*0.4, difffact );
        vec3 absorption = mix( vec3(0.8,0.9,0.8), vec3(1,0.9,0.7)*0.6, clamp( cloudDensTotal*0.5, 0., 1. ) );
        vec3 fringe = vec3(0.1,0.5,0.5)*clamp( 1. - d*3., 0.,1.);
        
        d = d*(1.-cloudDensTotal)*cloudStepSz;
        
        cloudDensTotal += d;
        cloudAccum += d*(diff*3.7*absorption + fringe*(0.1 + diff*0.9)*2.64);

        // map(cloudP).x < 0.

            
        if( cloudDensTotal > 1.){
            break;
        }
        cloudP += rd*cloudStepSz;
    }
    
    
    // Wind
    vec3 windP = ro + rd*volumetricDith*0.00 ;
    float windStepSz = min(t,24.)/windSteps;
    
    float windAccum = 0.;
    //vec3 windAccum = vec3(0.);
    
    for(float i = 0.; i < windSteps ; i++){
        vec3 wp = windP*0.51 - vec3(-iTime*3.,smoothstep(0.,1.,windP.y*0.5 - 1.9),0.);
            float dens = cyclicNoiseWind(wp,true)*0.019;
        dens *= smoothstep(1.,0.,windP.y*0.15 + 0.4);
        
        windAccum += dens*(1.-windAccum)*windStepSz;
        
        if( windAccum > 1.){
            break;
        }
        windP += rd*windStepSz;
    }
    
    vec3 mountP = rd*50.;
    float mountT = 0.;
    bool hitMount = false;
    // Background Mountains
    if(false && !hit){
        for(float i = 0.; i < marchStMountains ; i++){
            float d = mountP.y - 1.- smoothstep(0.4,1.6,cyclicNoiseTerrain(mountP*0.17,false))*7.;
             
            if( d < marchEpsMount){
                hitMount = true;
                break;
            }
            mountP += rd*d*0.8;
        }
        if(hitMount){
            p = mountP;
            t = 20. + mountT;
            d.y = 2.; 
            //hitCol = vec3(0.1);
            hit = true;

        }
    }
    
    
    // Coloring
    
    vec3 hitCol = vec3(0);
    vec3 ambientCol = atmosphere*1.;
    if(hit){
        vec3 n = getNormal(p);
        
        if(d.y == 3.){
            n = mix(n,vec3(0,1,0),1.);
            n = normalize(n);
        }
        
        vec3 hf = normalize(sunDir - rd);
        float diff = max(dot(n,sunDir),0.);
        float spec = pow(max(dot(n,hf),0.),6.);
        float fres = pow( 1. - max(dot( n, -rd),0.001),5.);
        fres = max(fres,0.);
        
        
        float rockiness = d.y - 1.;
        rockiness = clamp(rockiness,0.,1.);
        float AO = ao(1.9)*ao(0.2)*ao(4.2)*ao(0.8)*2.;
        float SSS = sss(.3)*sss(0.04)*sss(.1)*5.;
        
        float shad = diff;
        float rtMod = pow(abs(rockTex*4.5),5.);
        float rtModInv = pow(abs( 1.-rockTex*4.)*1.2,5.);
        vec3 rock = vec3(0.4,0.4,0.35);
        
        {
            vec3 ot = tex3D( iChannel3, p, n );
            rock = mix(rock, rock*vec3(1.,0.6,0.6)*1., clamp(ot.r*1.,0.,1.));
            
            rock = mix(rock, rock*vec3(0.4,0.7,0.2)*1.7, clamp(ot.g*1.+ n.y*0.8,0.,1.));
            
            
            
            float rockAO = clamp(AO + 20.*rtMod + 0.02, 0., 1.);
            rock += (spec + fres*0.4)*0.02;
            //rock = mix( 0.4*(rock*(vec3(0.1,0.1,0.1) + ambientCol*0.3 + sunCol*1.3))*ambianceScale,rock*1.,shad);
            rock = mix( (vec3(0.7,1.,0.6) -rtModInv*vec3(.9,0.5,0.6) + 0.6)*(rock*(0.2+ ambientCol*0.3 + sunCol*0.2))*ambianceScale,rock,rockAO*1.);
        
        
            
        }
        
        
        vec3 grass = vec3(0.5,1.,0.05)*1.;
        grass.x += sin(grh*20.)*0.2;
        grass.yz += sin(grh*50. + 4.)*0.05;
        grass.xyz -= (1.-grh)*pow(abs(sin(grh*20. + 4.)),4.)*0.6*vec3(0.,0.9,0.5);
        
        float cloudShad = pow(cyclicNoiseWind(p*0.2 + iTime*0.35,true)*1.,0.7);
        
        cloudShad -= ng*0.2;
        
        
        grass = mix(grass, vec3(0.4,0.5,0.9)*grass*cloudShad, 0.9);        
        { 
            //grass = mix( vec3(0.1,0.4,0.1)*0.5,grass,AO);
            
            shad = clamp(shad + SSS*.5, 0., 1.);
            AO = clamp(AO + SSS*1. , 0., 1.)*0.5 + 0.4;
            grass += (spec + fres*.4)*0.2;
            //grass = mix( (grass*vec3(0.4,0.4,0.2) + ambientCol*0. + sunCol*(1. - diff)*0.54)*ambianceScale,grass*1.,shad);
            grass = mix( vec3(0.1,0.4,0.1)*0.5,grass,AO);
            float aoo = ao(1.9);
            aoo = smoothstep(0.,0.6,aoo);    
            grass = mix( grass*vec3(0.5,0.5,0.8)*0.8,grass, aoo );
            
        }
        
        
        vec3 flower =vec3(0.5,0.5,0.05)*2.; 
        if(d.y == 4.5)
            flower = vec3(0.95,0.62,0.95)*0.7;
        {
            flower *= pow(AO,0.7);
        }
        
        hitCol = mix(grass,rock,rockiness);
        
        
        if(d.y == 3.){
            hitCol = grass;
        } else if(d.y >= 4.){
            hitCol = flower;
        }
        hitCol = mix(hitCol, hitCol*cloudShad,0.2);
        
    }
    

    // Compositing
    
    col += hitCol;
    
    if(hit){
       atmosphere *= 1.-pow(exp(-(t)*.04 ),2.);
    }
    
    atmosphere += getSun(rd.xy, sunDir.xy, sunPos, ro, vp);
    float depthViewFac = smoothstep(0.,1.,exp(-depthView*0.02) + exp(-t*0.4));
    
    col = col * depthViewFac + atmosphere; 
    
    if (!hit  && lowerCloudLimitDist > 0.){
        cloudAccum = mix(cloudAccum,col,clamp(1.-exp(-lowerCloudLimitDist*0.01 + 0.4),0.,1.));
        col = mix(col,cloudAccum*1. , pow(clamp(cloudDensTotal*1. - 0.,0.,1.),4.));
    }
    windAccum *= smoothstep(0.,1.,t*0.2 - 1.);
    col = (col - windAccum) + 4.*windAccum*vec3(1,0.9,0.8);
    
    col += particlesAccum;
    
    if(TAA && iFrame >1 && iMouse.z < 1.){
        fragColor = mix(prevFrame, col.xyzz,0.4);
    } else {
        fragColor = col.xyzz;
    }
    
    
    
    
    fragColor.w = cloudDensTotal + float(hit)*1.;
}


vec3 getNormal(vec3 p){
      vec3 n = vec3(0.0);
    for( int i=0; i<4; i++ )
    {
        vec3 e = 0.5773*(2.0*vec3((((i+3)>>1)&1),((i>>1)&1),(i&1))-1.0);
        n += e*map(p+e*0.04).x;
    }
    return normalize(n);
}


vec3 getSun(vec2 uv, vec2 sunPos, vec3 sunPosW, vec3 ro, mat3 vp){
    
    vec2 sunUVOriginal = uv;
    
    vec2 sunUV = uv - sunPos;
    //float cloudDensPrevFrame = texture(iChannel2, ((sunUV*iResolution.y + 0.5*iResolution.xy)/iResolution.xy)).w;
    
    //vec2 sunUvPrevFrame = (normalize(sunPosW - ro)*inverse(getRd(ro,sunPosW))).xy;
    vec2 sunUvPrevFrame = (normalize(sunPosW - ro)*inverse(vp)).xy;
    
    sunUvPrevFrame = (sunUvPrevFrame*iResolution.y)/iResolution.xy + 0.5;
    
    float deltaUV = 0.04;
    float cloudDensPrevFrame = 
        texture(iChannel2, sunUvPrevFrame + deltaUV).w
        + texture(iChannel2, sunUvPrevFrame - deltaUV).w
        + texture(iChannel2, sunUvPrevFrame + vec2(-deltaUV,deltaUV)).w
        + texture(iChannel2, sunUvPrevFrame + vec2(deltaUV,-deltaUV)).w
        ; 
    
    cloudDensPrevFrame /= 4.;
    
    cloudDensPrevFrame = clamp(cloudDensPrevFrame,0.,1.);
    // sun
    vec3 sun = sunCol*smoothstep(0.07,0.,length(sunUV));
    sun += sunCol*vec3(1.,0.4,0.6)*smoothstep(0.1,0.,length(sunUV));
    sun += sunCol*vec3(0.7,0.4,0.6)*smoothstep(0.3,0.,length(sunUV))*0.5;
    sun += sunCol*vec3(0.3,0.4,0.6)*smoothstep(0.6,0.,length(sunUV))*0.35;
    
    
    // rays
    
    
    vec3 sunRays = 0.4*sunCol * smoothstep(0.015*(1. + smoothstep(1.,0.,abs(sunUV.x)) ) ,0.,abs(sunUV.y))*smoothstep(0.5,0.,abs(sunUV.x));
    
    for(float i = 0.; i < 8.; i++){
        sunUV *= rot(pi/8./1.);
        float mda = sin(i*pi/4.);
        float mdb = sin(i*pi/2.);
        float w = 0.03;
        float l = 0.1;
        sunRays += (sunCol) *
            mix(.8,.1,smoothstep(0.,0.25 +  sin(i*pi/ 4. + iTime)*0.1,length(sunUV))) *
            smoothstep(w + mda*w/4.,0.,abs(sunUV.y))*smoothstep((l + mdb*0.1)*1.5,0.,abs(sunUV.x));
    }   
    sunUV = sunUVOriginal - sunPos;
    vec3 flares = vec3(0);
    vec2 toMid = sunPos;
    vec2 dirToMid = -normalize(toMid);
    float lenToMid = length(toMid);

    // flares
    for(float i = 0.; i < 12.; i++){
          sunUV -= 2.*lenToMid*dirToMid/12.;
          float dfl = length(sunUV) - (0.1 + 0.1*sin(i*5.))*0.5;
          dfl *= 0.5;
          vec3 flare = 0.01*(sunCol)*smoothstep(0.02,0.,dfl);
          flare += 0.003*(sunCol*sunCol)*smoothstep(0.01,0.,abs(dfl - dFdx(uv.x)));
          flares += flare*abs(sin(i*10.));
    }   
    
    
    return (sun + sunRays + flares*3.*sunCol) * (1. - cloudDensPrevFrame*1.);
}

