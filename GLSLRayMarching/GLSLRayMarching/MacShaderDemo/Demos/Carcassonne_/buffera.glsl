// Created by sebastien durand - 01/2019
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
// *****************************************************************************

// [Dave_Hoskins] Rolling hills - https://www.shadertoy.com/view/Xsf3zX
// [Shane] Voxel Corridor - https://www.shadertoy.com/view/MdVSDh
// [HLorenzi] Hand-drawn Sketch  - https://www.shadertoy.com/view/MsSGD1
// [Mercury] Lib - http://mercury.sexy/hg_sdf for updates
// [dr2] White Folly - https://www.shadertoy.com/view/ll2cDG


// Calculate distance to scene

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
    iRes = iResolution.xy;
	fCoord = fragCoord;
	time = iTime+100.*iMouse.x/iResolution.x;
	
    vec3 ro, rd;
    getCam(fragCoord.xy, iResolution.xy, time, ro, rd);
    
    vec3 res = castRay(ro,rd, MAX_DIST);
    // distance, edge (0/1), iter
    fragColor = vec4(res.xyz,0.);
}

