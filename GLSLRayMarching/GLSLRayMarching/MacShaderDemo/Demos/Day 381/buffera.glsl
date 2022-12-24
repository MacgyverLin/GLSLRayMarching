
#define TAA false


vec3 getNormal(vec3 p);
vec3 getSun(vec2 uv, vec2 sunPos, vec3 sunPosW, vec3 ro, mat3 vp);


float side = 1.;

float t = 0.;
float firstT = 0.;
vec3 firstRo = vec3(0);
vec3 firstRd = vec3(0);
float grh = 0.;
float ng = 0.;

float nIceBergs;

float mapClouds(vec3 p){
    float currHeight = p.y;
    
    p *= 0.5;
    float cloudsRange = (cloudsHigherLimit - cloudsLowerLimit)*0.494;
    float cloudsMid = cloudsLowerLimit + cloudsRange;
    
    float fb = cyclicNoiseClouds(p*1. + iTime*0., false,iTime);
    float f = cyclicNoiseClouds(p*0.4 + iTime*0.04 + fb*0.3, true,iTime);
    //f = (f*0.4 + cyclicNoise(p*0.5 + f*2. - fb*1.4 + iTime))*cyclicNoise(p*0.2 + 5.+ f*4.);
        //f *= pow( smoothstep( 1.,0., abs(currHeight - cloudsHigherLimit + cloudsRange)/cloudsRange*0.9), 2.29);
    
    //f = fb;
    f = max(f,0.);
    f *= pow( smoothstep( 1.,0., abs(currHeight - cloudsHigherLimit + cloudsRange)/cloudsRange*0.9), 2.29);
    
    return f;
}




vec2 getSea(vec3 p){
    float d = p.y;
    vec3 pp = vec3(p.x,2. - iTime*.36,p.z);
    float n = cyclicNoiseSea(pp*0.5, false);
    float on = n;
    //n = pow((n),1.9);
    
    d -= n;
    
    return vec2(d,IDSEA);
}


vec2 getIcebergs(vec3 p){
    float d = 10e4;
    
    p.y += 1.;
    
    
    float n = cyclicNoiseRocks(vec3(p.x,p.y*0.,p.z)*0.4, false);
    
    nIceBergs = cyclicNoiseRocksTri(vec3(p.x,p.y*0.3,p.z)*1., false);
    
    n = smoothstep(0.3,1.,n*0.94);
    
    
    
    //n += rockTex;
    
    
    d = abs(p.y + 2.5)   - (  n*7.3) - 0.;
    d -= nIceBergs*1.;
    
    return vec2(d,2.);
}


vec2 map(vec3 p){
    vec2 d = vec2(10e5);
    vec2 dsea = getSea(p);
    vec2 dicebergs = getIcebergs(p);
    //vec2 dbal = getIcebergs(p);
    
    dsea.x += sin(dicebergs.x*14. - iTime*3.)*exp(-dicebergs.x*1.1)*0.02;
    //dsea.x -= sin(dicebergs.x*14. + iTime*7.)*clamp(1.-dicebergs.x*1.,0.,1.)*0.02;
    dsea.x = max(dsea.x,-dicebergs.x + 0.01);
    
    
    
    
    
    d = dmin(d,dsea.x,dsea.y);
    d = dmin(d,dicebergs.x,dicebergs.y);
    
    
    
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
    vec2 muv = iMouse.xy/iResolution.xy;
    
    
    vec3 col = vec3(0);
    
    
    
    vec3 sunPos = vec3(-1,.7,2.)*2300.;
    vec3 sunDir = normalize(sunPos);

    
    vec3 ro = vec3(0);
    
    ro.z += iTime;
    
    ro.x -= 1.4;
    
    
    vec3 lookAt = vec3(0,0,ro.z +4.);
    
        
    float T = -iTime*0.1;
    
    float sea = getSea(ro).x;
    
    //float rocks = getRocks(ro).x*1.04; 
    
    ro += groundOffs;
    lookAt += groundOffs;
    lookAt.y -= muv.y*3.;
    lookAt.x += (1.-muv.x)*5. + 2.;
    
    mat3 vp = getRd(ro,lookAt);
    
    vec3 rd = normalize(vec3(uv,1.))*vp;
    
    firstRo = ro;
    firstRd = rd;
    
    
    // Marching
    
    vec3 atten = vec3(1);
    vec3 accumIceberg = vec3(0);
    float tAccumIceberg = 0.;
    vec3 p = ro;
    vec2 d;
    //bool marchingIceberg = false;
    float depthView;
    vec3 atmosphere;
    bool hitSky = false;
    
    
    vec3 hitCol = vec3(0);
    for(int reflection = 0; reflection < reflections; reflection++){
        
        if(!hitDiffuse && !hitSky){
            p = ro + rd*0.05;
            for(int i = 0; i < marchSteps ; i++){
                d = map(p);
                d.x *= side * distScale;
                if(side == -1.){
                    d.x = min(d.x,0.5);
                    
                    float dens = 0.075;
                    dens *= 1. - tAccumIceberg;
                    dens *= d.x;
                    
                    vec3 c = vec3(0.1,0.2,0.08 + sin(p.z*0.5)*0.0);
                    
                    float n = cyclicNoiseRocks( p*2., true);
                    c = mix(
                        c,
                        vec3(0,0.4,0.4),
                        pow(abs(n)*1.,3.)*4.9);
                    c = mix(
                        c,
                        c*c,
                        pow(abs(n),15.)*1.9);
                    
                    
                    
                    accumIceberg  += dens*c;
                    tAccumIceberg += dens;
                }
                if (t > maxDist || i == marchSteps - 1){
                    if(reflection == 0){
                        firstT = t;
                    } 
                    if(refractedInIceberg){
                        hitCol += skyCol*atten;
                        //hitCol = hitCol * exp(-depthView*0.1) + atten*getAtmosphere(vec3(0,ro.y,0), rd, t, depthView, sunPos);
                        
                        hitSky = true;
                    
                    } else if(reflectedFromWater){
                        hitCol = hitCol * exp(-depthView*0.1) + atten*getAtmosphere(vec3(0,ro.y,0), rd, t, depthView, sunPos);
                        hitSky = true;
                    }
                    break;
                } else if (d.x < marchEps ){
                    if(reflection == 0){
                        firstT = t;
                    }
                
                    vec3 n = getNormal(p)*side;
                    vec3 hf = normalize(sunDir - rd);
                    float diff = max(dot(n,sunDir),0.);
                    float spec = pow(max(dot(n,hf),0.),18.);
                    float fres = pow( 1. - max(dot( n, -rd),0.001),5.);
                    fres = max(fres,0.);
                
                    //float rockiness = d.y - 1.;
                    //rockiness = clamp(rockiness,0.,1.);
                    //float AO = mix(ao(.5,0.2)*ao(3.9,0.5)*ao(2.2,0.5)*ao(4.2,0.5),1.,0.34);
                    float AO = mix(ao(.25,0.5)*ao(1.2,0.5)*ao(.8,0.1),1.,0.2);
                    
                    //float SSS = sss(.3)*sss(0.04)*sss(.1)*5.;
                    
                    vec3 albedo = vec3(0);
                    vec3 iceCol = vec3(0);
                    vec3 seaCol = vec3(0);
                    if(d.y == IDICEBERG){
                        refractedInIceberg = true;
                        albedo = vec3(0.6,0.8,1)*0.1;
                        atten = mix(atten, albedo*atten,0.1);
                        if(side == -1.){
                            atten *= 1. - tAccumIceberg;
                            iceCol += accumIceberg*atten;
                        } 
                        if( reflection == 1){
                            }
                        atten *= AO;
                        
                        rd = refract(rd, n, 0.95);
                        ro = p ;
                        t = 0.;
                        
                        iceCol += albedo*atten*pow(clamp(abs(nIceBergs),0.,1.),4.)*0.9;
                        //iceCol += albedo*atten*smoothstep(0.1,0.04,nIceBergs)*4.9;
                        //iceCol += albedo*atten*smoothstep(0.2,0.1,AO)*4.9;
                        
                        
                        iceCol += (fres + spec)*skyCol*atten;
                        
                        
                        hitCol += iceCol;
                        atten *= 1. - albedo;
                        
                        
                        side *= -1.;
                    } else {
                        // water
                        AO = mix(AO,1.,0.9);
                        //albedo = vec3(0.8,0.9,1.)*1.;
                        albedo = vec3(1.,1.,1.)*1.;
                        
                        
                        //AO *= ao(.5)*ao(1.2);
                        //seaCol += albedo*pow(AO*0.4,13.);
                        atten *= (spec + fres)*AO*albedo;
                        //hitCol += seaCol*atten;
                        reflectedFromWater = true;
                        
                        ro = p;
                        t = 0.1;
                        rd = reflect(rd,n);
                    }

                    break;
                }

                p = ro + rd*(t += d.x);
            }
    
        }
    }
    
    
    atmosphere = getAtmosphere(vec3(0,firstRo.y,0), firstRd, firstT, depthView, sunPos);
    
    // Clouds
    
    vec3 cloudRo = firstRo;
    vec3 cloudRd = firstRd;
    
    if(reflectedFromWater){
        cloudRo = ro;
        cloudRo = rd;
    }
    
    float lowerCloudLimitDist = plaIntersect( cloudRo - vec3(0,cloudsLowerLimit,0), cloudRd, vec4(0,-1,0,0) );
    float higherCloudLimitDist = plaIntersect( cloudRo - vec3(0,cloudsHigherLimit,0), cloudRd, vec4(0,-1,0,0) );
    
    float volumetricDith = r21(fragCoord + sin(iTime*20.)*20.)*volumetricDithAmt;
    
    float cloudLength = higherCloudLimitDist - lowerCloudLimitDist; 
    float cloudStepSz = cloudLength/(cloudSteps);
    vec3 cloudP = cloudRo + rd * ( lowerCloudLimitDist + volumetricDith*cloudLength );
    
    
    float cloudDensTotal = 0.;
    vec3 cloudAccum = vec3(0.);
    
    
    for(float i = 0.; i < cloudSteps ; i++){
        float d = mapClouds(cloudP);
        
        float difffact = clamp( d*1. - mapClouds(cloudP + sunDir*1.4)*0.5  + 0.22, 0., 1. );
        vec3 diff = mix( atmosphere*0.1 + vec3(0.04,0.07,0.2)*(0.4 - smoothstep(0.,1.,1. - atmosphere*1.8)*0.1), (vec3(1,0.9,0.9)*1. + sunCol*0.4 + atmosphere*.4)*0.4, difffact );
        //vec3 diff = vec3(0.2); 
        vec3 absorption = mix( vec3(0.8,0.85,0.9), vec3(0.5,0.9,0.7)*0.6, clamp( cloudDensTotal*0.5, 0., 1. ) );
        vec3 fringe = vec3(0.1,0.5,0.5)*clamp( 1. - d*3., 0.,1.);
        
        d = d*(1.-cloudDensTotal)*cloudStepSz;
        
        cloudDensTotal += d;
        cloudAccum += d*(diff*2.7*absorption + fringe*(0.1 + diff*0.9)*2.64);

            
        if( cloudDensTotal > 1.){
            break;
        }
        cloudP += rd*cloudStepSz;
    }
    
    
    // Wind
    vec3 windRo = firstRo;
    vec3 windRd = firstRd;
    if(reflectedFromWater){
        //windRo = ro;
        //windRd = rd;
    }
    vec3 windP = windRo + windRd*volumetricDith*0.00 ;
    float windStepSz = min(firstT,14.)/windSteps;
    
    
    
    vec3 windAccum = vec3(0);
    float windT = 0.;
    
    for(float i = 0.; i < windSteps ; i++){
        vec3 wp = windP*1. - vec3(-iTime*1.,0.,0.);
            float dens = cyclicNoiseWind(wp,false)*0.239 + 0.0;
        dens *= smoothstep(1.,0.,windP.y*0.10 + 0.04);
        
        dens *= dens*(1.-windT)*windStepSz;
        windAccum += dens*vec3(.5,0.7,0.9)*2.6;
        windT += dens;
        
        if( windT > 1.){
            break;
        }
        windP += windRd*windStepSz;
    }
    
    
    
    // Coloring
    

    // Compositing
    
    col += hitCol;
    
    atmosphere += getSun(rd.xy, sunDir.xy, sunPos, ro, vp)*atten;
    //float depthViewFac = smoothstep(0.,1.,exp(-depthView*1.) + exp(-firstT*0.01));
    float depthViewFac = smoothstep(0.,1.,exp(-depthView*0.01 ));
    
    //float depthViewFac = exp(-depthView*0.000001);
    
    
    col = col * depthViewFac + atmosphere;//*(1. - depthViewFac) ; 
    
    
    cloudAccum *= atten;
    
    cloudDensTotal *= length(atten)/length(vec3(1));
    if (!refractedInIceberg &&  lowerCloudLimitDist > 0.){
        cloudAccum = mix(cloudAccum,col,clamp(1.-exp(-lowerCloudLimitDist*0.01 + 0.4),0.,1.));
        col = mix(col,cloudAccum*1. , pow(clamp(cloudDensTotal*1. - 0.,0.,1.),4.));
    }
    
    //windAccum *= smoothstep(0.,1.,firstT*0.1 - 0.01);
    
    col = mix(col,windAccum,windT);
    //col = (col - windAccum) + 2.*windAccum*vec3(0.5,0.9,1.2);
    
    if(TAA && iFrame >1 && iMouse.z < 1.){
        fragColor = mix(prevFrame, col.xyzz,0.4);
    } else {
        fragColor = col.xyzz;
    }
    
    
    
    
    fragColor.w = cloudDensTotal + float(hitDiffuse)*1.;
}


vec3 getNormal(vec3 p){
      vec3 n = vec3(0.0);
    for( int i=0; i<4; i++ )
    {
        vec3 e = 0.5773*(2.0*vec3((((i+3)>>1)&1),((i>>1)&1),(i&1))-1.0);
        n += e*map(p+e*normalEps).x;
    }
    return normalize(n);
}
vec3 getNormalq(vec3 p){
    vec2 t = vec2(normalEps, 0.);
    return normalize(map(p).x - vec3(
        map(p - t.xyy).x,
        map(p - t.yxy).x,
        map(p - t.yyx).x
    ));
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

