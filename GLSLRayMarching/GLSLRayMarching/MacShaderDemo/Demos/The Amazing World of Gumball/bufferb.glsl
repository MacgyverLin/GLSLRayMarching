// THE SCARY CSG BITS
bool bothHighFiving = false;
bool isBlinking = false;
bool isGumballWalking = true;
const float fiveTime = 9.;
const float maxTime = 11.5;


////////////////
//  GUMBALL  ///
////////////////
vec4 gumball(vec2 p, inout vec4 fragColor, float modTime) {
    float time = 5.;//2;//
    time = (modTime)*1.5;
    
    vec2 shadow = vec2(sdEllipse(tX(p, vec2(0.03, -0.251)),vec2(0.07,0.004)), 26.0);
    draw(p, shadow, fragColor);
    vec2 origP = p;
    if (!bothHighFiving){
        p = tX(p, vec2(0, cos(time*5.)*.002));
    }
    // EARS
    vec2 ear = vec2(sdUnevenCapsule(p, vec2(0.01,0.15), vec2(0.02,0.19), 0.063, 0.045), 9.0);
    draw(p, ear, fragColor);
    
    ear = vec2(sdUnevenCapsule(p, vec2(-0.09,0.13), vec2(-0.12,0.17), 0.063, 0.04), 9.0);
    draw(p, ear, fragColor);
    
    // HEAD
    vec2 i = vec2(sdSquircle(tX(p, vec2(-0.005, 0.075)), vec2(0), 0.135, 1.8, -0.6), 7.0);
    vec2 baseFace = vec2(sdUnevenCapsule(p, vec2(0.04,0.018), vec2(0.11,0.04), 0.063, 0.064), 9.0);
    add(i,baseFace);
    vec2 neck = vec2(sdUnevenCapsule(tX(origP, vec2(0.02, 0.0)), vec2(0.0,0.0), vec2(0.0,-0.1), 0.013, 0.02), 9.0);
    add(i,neck);
    draw(p, neck, fragColor);
    draw(p, baseFace, fragColor);
    draw(p, i, fragColor);
    
    // MOUTH
    vec2 mouth = vec2(sdEllipse(tX(p, vec2(0.02, 0.045)), vec2(0.03,0.01) + vec2(0.01,0.002)  ), 10.0);
    vec2 tri = vec2(sdTriangle( vec2(-0.03,0.03), vec2(-0.02,0.045), vec2(0.0,0.04), p), 10.0);
    add(mouth, tri);
    draw(p, mouth, fragColor);
    
    // NOSE
    
    vec2 nose = vec2(sdEllipse(tX(p, vec2(0.02, 0.053)), vec2(0.005,0.001) + vec2(0.01,0.002)  ), 11.0);
    draw(p, nose, fragColor);
    
    // MOUTH LINE
    vec2 mouthline = vec2(sdLineSegment(tX(p, vec2(0.02, 0.053)), vec2(0.005, -0.008), vec2(0.015, -0.02), 0.005), 6.0);
    draw(p, mouthline, fragColor);
    
    // WHISKERS
    vec2 w1 = vec2(sdLineSegment(tX(p, vec2(0.125, 0.0)), vec2(-0.01, 0.0025), vec2(0.015, -0.018), 0.0055), 6.0);
    draw(p, w1, fragColor);
    w1 = vec2(sdLineSegment(tX(p, vec2(0.125, 0.04)), vec2(0.01, -0.01), vec2(0.045, -0.028), 0.0055), 6.0);
    draw(p, w1, fragColor);
    
    w1 = vec2(sdLineSegment(tX(p, vec2(-0.125, 0.04)), vec2(0.014, -0.045), vec2(0.035, -0.03), 0.0055), 6.0);
    draw(p, w1, fragColor);
    w1 = vec2(sdLineSegment(tX(p, vec2(-0.105, 0.02)), vec2(0.014, -0.045), vec2(0.035, -0.025), 0.0055), 6.0);
    draw(p, w1, fragColor);
    w1 = vec2(sdLineSegment(tX(p, vec2(-0.095, -0.01)), vec2(0.034, -0.035), vec2(0.045, -0.015), 0.0055), 6.0);
    draw(p, w1, fragColor);
    
    // EYES / EYEBROWS
    if (sin(time+10.*.9) > 0.99) {
        isBlinking = true;
    }
    if (!isBlinking) {
        i = vec2(sdCircle2(tX(p, vec2(-0.055, 0.095)), 0.045), 5.0);
        draw(p, i, fragColor);
        
        i = vec2(sdCircle2(tX(p, vec2(0.06, 0.105)), 0.045), 5.0);
        draw(p, i, fragColor);
        
        float move1 =  0.025;//(0.03*abs(sin(time*2)));
        //        float move1 =  (0.03*abs(sin(time)));
        i = vec2(sdCircle2(tX(p, vec2(0.06+move1, 0.105)), 0.02), 6.0);
        draw(p, i, fragColor);
        
        float move2 = 0.021;//(0.025*abs(sin(time*2)));
        //        float move2 = (0.025*abs(sin(time)));
        i = vec2(sdCircle2(tX(p, vec2(-0.051+move2, 0.0965)), 0.02), 6.0);
        draw(p, i, fragColor);
        
        vec2 ebp = tX(p, vec2(-0.1, 0.15));
        ebp *= rot2D(.25 * PI);
        ebp.x =ebp.x*-sin(ebp.x)*25.;
        i = vec2(sdLineSegmentRounded(ebp, vec2(0.005,0.005), vec2(-0.005,-0.005), 0.0075), 6.0);
        draw(p, i, fragColor);
        
        vec2 ebp2 = tX(p, vec2(0.065, 0.175));
        ebp2.x =ebp2.x*-sin(ebp2.x)*25.;
        i = vec2(sdLineSegmentRounded(ebp2, vec2(0.005,0.005), vec2(-0.005,-0.005), 0.0075), 6.0);
        draw(p, i, fragColor);
    } else {
        vec2 ebp2 = tX(p, vec2(0.03, 0.1));
        i = vec2(sdLineSegmentRounded(ebp2, vec2(0.05,0.02), vec2(-0.005,-0.005), 0.01), 6.0);
        draw(p, i, fragColor);
        i = vec2(sdLineSegmentRounded(ebp2, vec2(0.075,-0.0025), vec2(-0.005,-0.005), 0.01), 6.0);
        draw(p, i, fragColor);
        
        vec2 ebp3 = tX(p, vec2(-0.025, 0.095));
        ebp3 *= rot2D(.07 * PI);
        i = vec2(sdLineSegmentRounded(ebp3, vec2(-0.05,0.02), vec2(-0.005,-0.005), 0.01), 6.0);
        draw(p, i, fragColor);
        i = vec2(sdLineSegmentRounded(ebp3, vec2(-0.075,-0.0025), vec2(-0.005,-0.005), 0.01), 6.0);
        draw(p, i, fragColor);
        
        vec2 ebp4 = tX(p, vec2(0.03, 0.11));
        ebp4 *= rot2D(.3 * PI);
        ebp4.x =ebp4.x*-sin(ebp4.x)*25.;
        i = vec2(sdLineSegmentRounded(ebp4, vec2(0.005,0.005), vec2(-0.003,-0.003), 0.004), 6.0);
        draw(p, i, fragColor);
        
        vec2 ebp5 = tX(p, vec2(-0.03, 0.105));
        ebp5 *= rot2D(-.3 * PI);
        ebp5.x =ebp5.x*-sin(ebp5.x)*25.;
        i = vec2(sdLineSegmentRounded(ebp5, vec2(0.005,0.005), vec2(-0.003,-0.003), 0.004), 6.0);
        draw(p, i, fragColor);
    }
    
    p = origP;
    
    float armExtension = 0.;
    
    // ARM - RIGHT
    vec2 aPt = tX(p, vec2(0.04, -0.08));
    float currentAngle = .16*sin(modTime*2.);
    
    aPt *= rot2D(currentAngle * PI);
    
    if (bothHighFiving) {
        float angleAtFiveTime = .16*abs(sin(fiveTime*2.));
        float percentIncrease = clamp((modTime-fiveTime)/0.5, 0., 1.);
        float desiredAngle = .5;
        desiredAngle = desiredAngle - currentAngle;
        float add = desiredAngle * percentIncrease;
        aPt *= rot2D((angleAtFiveTime +(add)) * PI);
        armExtension = .1*percentIncrease;
    }
    
    // HAND - RIGHT
    
    vec2 hPt = tX(aPt, vec2(0.005, -0.105-armExtension*.6));
    vec2 hand = vec2(sdCircle2(hPt, 0.015), 9.0);
    draw(p, hand, fragColor);
    
    vec2 f1 = vec2(sdLineSegment(tX(hPt, vec2(0.0, 0.0)), vec2(0.005, -0.0), vec2(0.012, -0.012), 0.0035), 6.0);
    draw(p, f1, fragColor);
    
    f1 = vec2(sdLineSegment(tX(hPt, vec2(0.0, 0.0)), vec2(-0.003, -0.005), vec2(0.002, -0.013), 0.0035), 6.0);
    draw(p, f1, fragColor);
    
    vec2 sleeveSize = vec2(0.01,0.02);
    vec2 sleeveInSize = vec2(0.002,0.02);
    vec2 sP = tX(aPt, vec2(-0.0025, -0.07-armExtension*.4));
    sP *= rot2D(.05 * PI);
    vec2 arm1 = vec2(sdLineSegmentRounded(aPt, vec2(-0.0,0.0), vec2(-0.006,-0.046-armExtension/3.), 0.02), 13.0);
    vec2 sleeve = vec2(sdBox(sP, vec2(sleeveSize.x, sleeveSize.y+armExtension/6.)),12.0);
    draw(p, arm1, fragColor);
    draw(p, sleeve, fragColor);
    sleeve = vec2(sdBox(sP, vec2(sleeveInSize.x, sleeveInSize.y+armExtension/6.)),12.0);
    draw(p, sleeve, fragColor);
    
    // TAIL
    vec2 tailPoint = tX(p, vec2(0.02, -0.15));
    tailPoint *= rot2D((-.3-(.01*-sin(time*3.)))* PI);
    vec2 tail = vec2(sdUnevenCapsule(tailPoint, vec2(0.0,0.0), vec2(0.0,-0.08), 0.004, 0.012), 9.0);
    draw(p, tail, fragColor);
    
    // LEG - RIGHT
    vec2 ppt = tX(p, vec2(0.0375, -0.185));
    vec2 legsize = vec2(0.01,0.02);
    
    if (isGumballWalking) {
        ppt *= rot2D(-.16*sin(time*3.) * PI);
    }
    
    vec2 leg = vec2(sdBox(tX(ppt, vec2(0.00, -0.01)), legsize),14.0);
    vec2 cuff = vec2(sdBox(tX(ppt, vec2(0.0, -0.03)), vec2(0.01,0.008)),13.0);
    
    // FOOT - RIGHT
    vec2 fpt = tX(ppt, vec2(-0.004, -0.052));
    vec2 foot = vec2(sdLineSegmentRounded(fpt, vec2(0.00,-0.0), vec2(0.015,-0.0), 0.02), 9.0);
    draw(p, foot, fragColor);
    
    vec2 t1 = vec2(sdLineSegment(tX(fpt, vec2(0.01, 0.0)), vec2(0.008, -0.001), vec2(0.015, -0.008), 0.0035), 6.0);
    draw(p, t1, fragColor);
    
    t1 = vec2(sdLineSegment(tX(fpt, vec2(0.01, 0.0)), vec2(-0.004, 0.0), vec2(0.006, -0.010), 0.0035), 6.0);
    draw(p, t1, fragColor);
    
    draw(p, leg, fragColor);
    draw(p, cuff, fragColor);
    
    
    
    // LEG - LEFT
    ppt = tX(p, vec2(0.0125, -0.185));
    if (isGumballWalking) {
        ppt *= rot2D(.17*sin(time*3.) * PI);
    }
    
    leg = vec2(sdBox(tX(ppt, vec2(0.00, -0.01)), legsize),14.0);
    cuff = vec2(sdBox(tX(ppt, vec2(0.0, -0.03)), vec2(0.01,0.008)),13.0);
    
    // FOOT - LEFT
    fpt = tX(ppt, vec2(-0.004, -0.052));
    foot = vec2(sdLineSegmentRounded(fpt, vec2(0.00,-0.0), vec2(0.015,-0.0), 0.02), 9.0);
    draw(p, foot, fragColor);
    
    t1 = vec2(sdLineSegment(tX(fpt, vec2(0.01, 0.0)), vec2(0.008, -0.001), vec2(0.015, -0.008), 0.0035), 6.0);
    draw(p, t1, fragColor);
    
    t1 = vec2(sdLineSegment(tX(fpt, vec2(0.01, 0.0)), vec2(-0.004, 0.0), vec2(0.006, -0.01), 0.0035), 6.0);
    draw(p, t1, fragColor);
    
    draw(p, leg, fragColor);
    draw(p, cuff, fragColor);
    
    // BODY
    vec2 torso1 = vec2(sdPoly(vec2[](vec2(0.02, -0.04),vec2(0.065, -0.04),vec2(0.06, 0.01),vec2(0.02, 0.02)), tX(p, vec2(-0.015, -0.1))), 13.0);
    vec2 tummy = vec2(sdLineSegmentRounded(tX(p, vec2(-0.0, -0.057)), vec2(0.045,-0.1), vec2(0.008,-0.1), 0.038), 13.0);
    add(torso1, tummy);
    draw(p, torso1, fragColor);
    
    vec2 belly = vec2(sdLineSegmentRounded(tX(p, vec2(-0.0, -0.057)), vec2(0.045,-0.1), vec2(0.008,-0.1), 0.038), 14.0);
    vec2 belSlice = vec2(sdBox(tX(p, vec2(-0.0, -0.11)), vec2(0.10,0.05)),14.0);
    vec2 belSlice2 = vec2(sdBox(tX(p, vec2(-0.0, -0.11)), vec2(0.10,0.05)),13.0);
    vec2 button = vec2(sdEllipse(tX(p, vec2(0.03, -0.16)), vec2(0.005,0.005) + vec2(0.01,0.002)  ), 13.0);
    diff(button, belSlice2);
    diff(belly, belSlice);
    draw(p, belly, fragColor);
    draw(p, button, fragColor);
    
    // PANTS LINES
    
    vec2 p1 = vec2(sdLineSegment(tX(p, vec2(0.03, -0.17)), vec2(0.01, 0.0015), vec2(0.015, -0.007), 0.0055), 6.0);
    draw(p, p1, fragColor);
    
    p1 = vec2(sdLineSegment(tX(p, vec2(0.0, -0.17)), vec2(0.02, 0.002), vec2(0.015, -0.007), 0.0055), 6.0);
    draw(p, p1, fragColor);
    
    // COLLAR
    vec2 collar = vec2(sdPoly(vec2[](vec2(0.012, 0.0),vec2(0.065, -0.005),vec2(0.06, 0.015),vec2(0.01, 0.02)), tX(p, vec2(-0.015, -0.08))), 12.0);
    draw(p, collar, fragColor);
    
    // ARM - LEFT
    
    aPt = tX(p, vec2(-0.0, -0.08));
    aPt *= rot2D(.16*cos(time*2.) * PI);
    
    // HAND - LEFT
    hPt = tX(aPt, vec2(0.005, -0.105));
    hand = vec2(sdCircle2(hPt, 0.015), 9.0);
    draw(p, hand, fragColor);
    
    f1 = vec2(sdLineSegment(tX(hPt, vec2(0.0, 0.0)), vec2(0.005, -0.0), vec2(0.012, -0.012), 0.0035), 6.0);
    draw(p, f1, fragColor);
    
    f1 = vec2(sdLineSegment(tX(hPt, vec2(0.0, 0.0)), vec2(-0.003, -0.005), vec2(0.002, -0.013), 0.0035), 6.0);
    draw(p, f1, fragColor);
    
    sP = tX(aPt, vec2(-0.0025, -0.07));
    sP *= rot2D(.05 * PI);
    vec2 sleeve2 = vec2(sdBox(sP, sleeveSize),12.0);
    arm1 = vec2(sdLineSegmentRounded(aPt, vec2(-0.0,0.0), vec2(-0.006,-0.046), 0.02), 13.0);
    draw(p, arm1, fragColor);
    draw(p, sleeve2, fragColor);
    sleeve2 = vec2(sdBox(sP, sleeveInSize),12.0);
    draw(p, sleeve2, fragColor);
    
    
    return fragColor;
}

vec4 sceneDistance(vec2 p, inout vec4 fragColor)
{
    float modTime = 4.;
    modTime = mod((iTime-4.),maxTime);
    
    vec2 gumP = tX(p, vec2(-0.3, 0.0));
    if (modTime > 8.) {
        isGumballWalking = false;
        gumP = tX(p, vec2(-0.2, 0.0));
        bothHighFiving = true;
    } else {
        gumP = tX(p, vec2(-1.+(modTime/100.)*10., 0.0));
    }
    
    gumball(gumP, fragColor, modTime);
    
    return fragColor;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    
    vec2 uv = vec2(fragCoord.x / iResolution.x, fragCoord.y / iResolution.y);
    fragColor = texture(iChannel0,uv);
    uv -= 0.5;
    uv /= vec2(iResolution.y / iResolution.x, 1);
    sceneDistance(uv, fragColor);
}
