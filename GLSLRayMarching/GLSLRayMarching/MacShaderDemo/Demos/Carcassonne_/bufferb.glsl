// Created by sebastien durand - 01/2019
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
// *****************************************************************************

// [Dave_Hoskins] Rolling hills - https://www.shadertoy.com/view/Xsf3zX
// [Shane] Voxel Corridor - https://www.shadertoy.com/view/MdVSDh
// [HLorenzi] Hand-drawn Sketch  - https://www.shadertoy.com/view/MsSGD1
// [Mercury] Lib - http://mercury.sexy/hg_sdf for updates
// [dr2] White Folly - https://www.shadertoy.com/view/ll2cDG


// Calculate Shadows and AO

float SoftShadow(in vec3 ro, in vec3 rd) {
    float res = 1.0, h, t = .005+hash13(ro)*.02;
    float dt = .01;
    for( int i=0; i<32; i++ ) {
		h = map( ro + rd*t );
		res = min( res, 10.*h/t );
		t += dt;
        dt+=.0025;
        if (h<PRECISION) break;
    }
    return clamp(res, 0., 1.);
}

float CalcAO(in vec3 pos, in vec3 nor) {
    float dd, hr=.01, totao=.0, sca=1.;
    for(int aoi=0; aoi<4; aoi++ ) {
        dd = map(nor * hr + pos);
        totao += -(dd-hr)*sca;
        sca *= .8;
        hr += .03;
    }
    return clamp(1.-4.*totao, 0., 1.);
}


void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
    
    iRes = iResolution.xy;
	fCoord = fragCoord;
	time = iTime+100.*iMouse.x/iResolution.x;
	    
    vec3 ro,rd;
    getCam(fragCoord.xy, iResolution.xy, time, ro, rd);
    

    vec2 uv = gl_FragCoord.xy / iResolution.xy;
    vec4 res = texture(iChannel0,uv);
       
 	float ao = 0., sh = 0., t = res.x;
    if (t<MAX_DIST) {
        vec3 pos = ro + rd * t;
    	vec3 nor = calcNormal(pos, rd, t);
        ao = CalcAO(pos, nor ),
		sh = SoftShadow( pos, sunLight); 
    }
    
    fragColor = vec4(res.x, ao, sh, res.y);    
}

