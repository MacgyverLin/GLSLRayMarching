void mainCubemap( out vec4 fragColor, in vec2 fragCoord, in vec3 rayOri, in vec3 rayDir )
{
    // Ray direction as color
    vec3 col = 0.5 + 0.5*rayDir;

    // Output to cubemap
    fragColor = vec4(col,1.0);
}

float max3(vec3 rd) {
   return max(max(rd.x, rd.y), rd.z);
}

void mainCubemap1( out vec4 fragColor, in vec2 fragCoord, in vec3 rayOri, in vec3 rayDir )
{
    vec3 rd = abs(rayDir);
    
    vec3 col = vec3(0);
    if (max3(rd) == rd.x)
        col = vec3(1, 0, 0);
    if (max3(rd) == rd.y) 
        col = vec3(0, 1, 0);
    if (max3(rd) == rd.z) 
        col = vec3(0, 0, 1);
    
    fragColor = vec4(col,1.0); // Output cubemap
}