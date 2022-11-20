// THE SCARY CSG BITS
const float fiveTime = 9.;
const float maxTime = 11.5;


vec4 bg(vec2 p, inout vec4 fragColor) {
    vec2 sky = vec2(sdBox(tX(p, vec2(0.0,0.25)), vec2(1.0,0.25)), 23.0);
    draw(p, sky, fragColor);
    
    vec2 tpp = tX(p, vec2(-0.85,0.05));
    tpp.x = repeat(tpp.x, 0.15);
    vec2 tree1 = vec2(sdCircle2(tpp, 0.1), 24.0);
    draw(p, tree1, fragColor);
    
    tpp = tX(p, vec2(-0.85,0.00));
    tpp.x = repeat(tpp.x, 0.1);
    tree1 = vec2(sdCircle2(tpp, 0.1), 24.0);
    draw(p, tree1, fragColor);
    
    vec2 cloud = vec2(sdEllipse(tX(p, vec2(0.03, 0.4)),vec2(0.1,0.04)), 1.0);
    vec2 cloud1 = vec2(sdEllipse(tX(p, vec2(0.15, 0.4)),vec2(0.1,0.04)), 1.0);
    add(cloud, cloud1);
    vec2 cloud2 = vec2(sdEllipse(tX(p, vec2(0.1, 0.44)),vec2(0.1,0.04)), 1.0);
    add(cloud, cloud2);
    draw(p, cloud, fragColor);
    
    vec2 clouda = vec2(sdEllipse(tX(p, vec2(-0.5, 0.3)),vec2(0.1,0.04)), 1.0);
    vec2 clouda2 = vec2(sdEllipse(tX(p, vec2(-0.55, 0.34)),vec2(0.1,0.04)), 1.0);
    add(clouda, clouda2);
    draw(p, clouda, fragColor);
    
    vec2 cloudb = vec2(sdEllipse(tX(p, vec2(0.65, 0.3)),vec2(0.1,0.04)), 1.0);
    draw(p, cloudb, fragColor);
    
    return fragColor;
}


vec4 sceneDistance(vec2 p, inout vec4 fragColor)
{
    float modTime = 4.;
    modTime = mod((iTime-4.),maxTime);
    bg(p, fragColor);
    
    return fragColor;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = vec2(fragCoord.x / iResolution.x, fragCoord.y / iResolution.y);
    uv -= 0.5;
    uv /= vec2(iResolution.y / iResolution.x, 1);
    fragColor = vec4(1.0,0.94,0.67,1.0);
    sceneDistance(uv, fragColor);
}
