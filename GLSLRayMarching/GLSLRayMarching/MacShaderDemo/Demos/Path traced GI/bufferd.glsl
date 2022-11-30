


void mainImage( out vec4 fragColor, in vec2 fragCoord ){
    
    Camera cam = getCam(iTime);
    
    vec4 col = texelFetch(iChannel0, ivec2(fragCoord), 0);
    vec4 tx = texelFetch(iChannel1, ivec2(fragCoord), 0);
    vec3 finalPos = tx.rgb;
    col.a = length(cam.pos-finalPos);
    
    vec2 uv = (fragCoord-iResolution.xy/2.0) / iResolution.y;
    vec3 dir = uv2dir(cam, uv);
    
    if(tx.a != 0.) {
        vec3 dc, ec;
        sdf(finalPos, dc, ec);
        col.rgb = ec + dc * (col.rgb + directLight(finalPos, normalEstimation(finalPos)));
    } else {
        finalPos = cam.pos + dir * 100.;
    }
    
    vec3 volCol = vec3(0.), volAbs = vec3(1.), pos = cam.pos;
    float stepDist = (tx.a == 0. ? FogRange : min(FogRange, col.a))/float(FogSteps);
    vec3 stepAbs = exp(-Density*stepDist);
    vec3 stepCol = (vec3(1.) - stepAbs) * henyeyGreenstein(-LightDir, dir);
    pos += stepDist * dir * texture(iChannel2, fragCoord/vec2(1024)).a;
    for(int i = 0; i < FogSteps; i++){
        volAbs *= stepAbs;
        volCol += stepCol*volAbs*directLight(pos, -LightDir);
        pos += dir * stepDist;
    }
    
    col.rgb = col.rgb*volAbs + volCol;
	
    

    fragColor = col;
}