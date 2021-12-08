vec4 getGroundTruth(in vec2 texcoord)
{
    return texture(iChannel0, texcoord);
}

vec4 getOriginalImage(in vec2 texcoord)
{
    vec2 newTexcoord = texcoord / iEasuScale;

    if(newTexcoord.x > 1.0 || newTexcoord.y > 1.0)
        return vec4(1.0, 1.0, 1.0, 1.0);
    else
        return texture(iChannel1, texcoord);
}

vec4 getOriginalScaledImage(in vec2 texcoord)
{
    vec2 newTexcoord = texcoord / iEasuScale;

    return texture(iChannel1, newTexcoord);
}

vec4 getEASUImage(in vec2 texcoord)
{
    return texture(iChannel2, texcoord);
}

vec4 getFSRImage(in vec2 texcoord)
{
    return texture(iChannel3, texcoord);
}

float getSide(in vec2 fragCoord)
{
    vec2 texcoord = fragCoord / iResolution.xy;
    vec2 normal = vec2(-1.0, 1.0);
    vec2 p0 = iMouse.xy / iResolution.xy;
    
    float side = dot(normal, texcoord - p0);
    return side;
}

void showAllBuffer(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 texcoord = fragCoord / iResolution.xy;
    float side = getSide(fragCoord);

    float slotSize = 0.8;
    float lineSize = 0.001;

    if(side < -slotSize-lineSize)
        fragColor = getOriginalScaledImage(texcoord);
    else if(side > -slotSize && side < 0.0 - lineSize)
        fragColor = getEASUImage(texcoord);
    else if(side > 0.0 && side < slotSize - lineSize)
        fragColor = getFSRImage(texcoord);
    else if(side > slotSize)
        fragColor = getGroundTruth(texcoord);
    else
        fragColor = vec4(1.0, 1.0, 1.0, 1.0);
}

void showFSRComparision(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 texcoord = fragCoord / iResolution.xy;
    float side = getSide(fragCoord);

    float slotSize = 0.8;
    float lineSize = 0.001;

    if(side < -slotSize-lineSize)
        fragColor = getOriginalScaledImage(texcoord);
    else if(side > -slotSize && side < slotSize - lineSize)
        fragColor = getFSRImage(texcoord);
    else if(side > slotSize)
        fragColor = getGroundTruth(texcoord);
    else
        fragColor = vec4(1.0, 1.0, 1.0, 1.0);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    //showAllBuffer(fragColor, fragCoord);
    showFSRComparision(fragColor, fragCoord);
}