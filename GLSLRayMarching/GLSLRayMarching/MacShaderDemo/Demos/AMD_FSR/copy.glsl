vec4 getOriginalImage(in vec2 vTexCoord)
{
    return texture(iChannel0, vTexCoord);
}

vec4 getScaledimage(in vec2 vTexCoord)
{
    return texture(iChannel1, vTexCoord / iEasuScale);
}

vec4 getEASUImage(in vec2 vTexCoord)
{
    return texture(iChannel2, vTexCoord);
}

vec4 getEASURCASImage(in vec2 vTexCoord)
{
    return texture(iChannel3, vTexCoord);
}

void showAllBuffer(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 vTexCoord = fragCoord / iResolution.xy;

    if(vTexCoord.x >= 0.00 && vTexCoord.x < 0.249)
        fragColor = getScaledimage(vTexCoord);
    else if(vTexCoord.x >= 0.25 && vTexCoord.x < 0.499)
        fragColor = getEASUImage(vTexCoord);
    else if(vTexCoord.x >= 0.50 && vTexCoord.x < 0.749)
        fragColor = getEASURCASImage(vTexCoord);
    else if(vTexCoord.x >= 0.750 && vTexCoord.x < 0.999)
        fragColor = getOriginalImage(vTexCoord);
    else
        fragColor = vec4(1.0, 1.0, 1.0, 1.0);
}

void showFSROnOff(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 vTexCoord = fragCoord / iResolution.xy;
	float div_pos = iMouse.x / iResolution.x;

    if(vTexCoord.x >= 0.00 && vTexCoord.x < div_pos-0.001)
        fragColor = getOriginalImage(vTexCoord);
    else if(vTexCoord.x >= div_pos && vTexCoord.x < 0.999)
        fragColor = getEASURCASImage(vTexCoord);
    else
        fragColor = vec4(1.0, 1.0, 1.0, 1.0);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    //showAllBuffer(fragColor, fragCoord);
    showFSROnOff(fragColor, fragCoord);
}