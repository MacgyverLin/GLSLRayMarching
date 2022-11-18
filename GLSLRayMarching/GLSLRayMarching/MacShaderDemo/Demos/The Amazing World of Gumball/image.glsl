// THE SCARY CSG BITS
bool bothHighFiving = false;
const float fiveTime = 9.;
const float maxTime = 11.5;

////////////////
//  DARWIN   ///
////////////////

bool isDarwinBlinking = false;
bool isDarwinWalking = true;
vec4 darwin(vec2 p, inout vec4 fragColor, float modTime) {
    float time = 3.;//2;//
    time = (modTime-3.)*1.5;
    
    vec2 shadow = vec2(sdEllipse(tX(p, vec2(-0.02, -0.251)),vec2(0.1,0.007)), 26.0);
    draw(p, shadow, fragColor);
    
    // ARM - LEFT
    float armExtension = 0.;
    vec2 aPt = tX(p, vec2(-0.06, -0.03));
    
    ///////////////////
    float currentAngle = .17*cos(time*3.);
    
    aPt *= rot2D(currentAngle * PI);
    
    if (bothHighFiving) {
        float angleAtFiveTime = .17*cos(fiveTime*2.);
        float percentIncrease = clamp((modTime-fiveTime)/0.5, 0., 1.);
        float desiredAngle = -.64;
        desiredAngle = desiredAngle - currentAngle;
        float add = desiredAngle * percentIncrease;
        aPt *= rot2D((angleAtFiveTime +(add)) * PI);
        armExtension = .1*percentIncrease;
    }
    //////////////////
    
    vec2 arm1 = vec2(sdLineSegmentRounded(aPt, vec2(-0.0,0.0), vec2(-0.02,-0.076-armExtension*.8), 0.03), 15.0);
    draw(p, arm1, fragColor);
    
    // LEG - LEFT
    vec2 ppt = tX(p, vec2(-0.0, -0.0));
    vec2 legsize = vec2(0.0175,0.1);
    if (isDarwinWalking) {
        ppt *= rot2D(.11*sin(time*3.) * PI);
    }
    vec2 leg = vec2(sdBox(tX(ppt, vec2(-0.01, -0.115)), legsize),15.0);
    
    vec2 fpt = tX(ppt, vec2(-0.02, -0.21));
    vec2 fptbk = fpt;
    if (isDarwinWalking) {
        fpt *= rot2D(.1*sin(time*3.) * PI);
    }
    vec2 foot = vec2(sdLineSegmentRounded(fpt, vec2(-0.05,-0.0), vec2(0.01,-0.0), 0.05), 15.0);
    add(leg, foot);
    draw(p, leg, fragColor);
    vec2 wBox = vec2(sdBox(tX(fpt, vec2(0.0,0.0)), vec2(0.1,0.08)),15.0);
    intersection(leg, wBox);
    leg.y = 2.0;
    draw(p, leg, fragColor);
    wBox = vec2(sdBox(tX(fpt, vec2(0.02,0.0)), vec2(0.06,0.05)),15.0);
    intersection(leg, wBox);
    leg.y = 17.0;
    draw(p, leg, fragColor);
    vec2 spot = vec2(sdEllipse(tX(fptbk, vec2(0.01, 0.01)),vec2(0.0075,0.013)  ), 2.0);
    draw(p, spot, fragColor);
    
    // LEG - RIGHT
    ppt = tX(p, vec2(0.0, -0.0));
    
    if (isDarwinWalking) {
        ppt *= rot2D(-.1*sin(time*3.) * PI);
    }
    leg = vec2(sdBox(tX(ppt, vec2(0.01, -0.125)), legsize),15.0);
    fpt = tX(ppt, vec2(-0.0, -0.21));
    fptbk = fpt;
    if (isDarwinWalking) {
        fpt *= rot2D(-.1*sin(time*3.) * PI);
    }
    foot = vec2(sdLineSegmentRounded(fpt, vec2(-0.05,-0.0), vec2(0.01,-0.0), 0.05), 15.0);
    add(leg, foot);
    draw(p, leg, fragColor);
    wBox = vec2(sdBox(tX(fpt, vec2(0.0,0.0)), vec2(0.1,0.08)),15.0);
    intersection(leg, wBox);
    leg.y = 2.0;
    draw(p, leg, fragColor);
    wBox = vec2(sdBox(tX(fpt, vec2(0.02,0.0)), vec2(0.06,0.05)),15.0);
    intersection(leg, wBox);
    leg.y = 17.0;
    draw(p, leg, fragColor);
    spot = vec2(sdEllipse(tX(fptbk, vec2(0.01, 0.01)),vec2(0.0075,0.013)  ), 2.0);
    draw(p, spot, fragColor);
    
    vec2 origP = p;
    if (!bothHighFiving){
        p = tX(p, vec2(0, cos(time*4.)*.002));
    }
    // HEAD
    vec2 headP = tX(p, vec2(0.08, 0.07));
    vec2 i = vec2(sdUnevenCapsule(headP, vec2(-0.022,-0.01), vec2(-0.093,0.0), 0.09, 0.1025), 15.0);//sdSquircle(tX(p, vec2(-0.005, 0.075)), vec2(0), 0.135, 1.8, -1.1), 21.0);
    vec2 baseFace = vec2(sdUnevenCapsule(p, vec2(-0.03,0.0175), vec2(-0.09,0.03), 0.05, 0.065), 15.0);
    add(i,baseFace);
    
    // ARM - RIGHT
    aPt = tX(p, vec2(0.085, -0.02));
    aPt *= rot2D(.17*sin(time*3.) * PI);
    
    arm1 = vec2(sdLineSegmentRounded(aPt, vec2(-0.0,0.0), vec2(0.02,-0.076), 0.03), 15.0);
    add(i,arm1);
    
    vec2 tailP = tX(headP, vec2(0.07, -0.05));
    vec2 tail = vec2(sdCircle2(tailP, 0.035), 15.0);
    draw(p, tail, fragColor);
    
    draw(p, baseFace, fragColor);
    draw(p, i, fragColor);
    
    vec2 mouthP = tX(headP, vec2(-0.1, -0.02));
    vec2 mouthSlice = vec2(sdBox(tX(mouthP, vec2(-0.0, 0.035)), vec2(0.1,0.05)), 19.0);
    vec2 mouthSlice2 = vec2(sdCircle2(tX(mouthP, vec2(-0.0, -0.035)), 0.062), 19.0);
    vec2 mouth = vec2(sdCircle2(mouthP, 0.068), 19.0);
    diff(mouth, mouthSlice);
    mouth = vec2(smoothIntersection(mouth.x, mouthSlice2.x, 0.01), 19.0);
    draw(p, mouth, fragColor);
    
    mouth.y = 20.0;
    vec2 tongue = vec2(sdCircle2(tX(mouthP, vec2(0.03, -0.065)), 0.032), 20.0);
    intersection(tongue, mouth);
    draw(p, tongue, fragColor);
    
    vec2 shineP = tX(headP, vec2(0.04, 0.02));
    shineP *= rot2D(-.4 * PI);
    shineP.x =shineP.x*-sin(shineP.x)*25.;
    i = vec2(sdLineSegmentRounded(shineP, vec2(0.005,0.005), vec2(-0.025,-0.005), 0.02), 21.0);
    draw(p, i, fragColor);
    
    tail = vec2(sdCircle2(tX(tailP, vec2(-0.01, -0.0)), 0.015), 16.0);
    draw(p, tail, fragColor);
    
    vec2 tp1 = vec2(sdLineSegment(tX(tailP, vec2(0.0, 0.0)), vec2(0.02, -0.005), vec2(0.035, -0.012), 0.0025), 6.0);
    draw(p, tp1, fragColor);
    
    tp1 = vec2(sdLineSegment(tX(tailP, vec2(-0.01, -0.01)), vec2(0.025, -0.005), vec2(0.035, -0.012), 0.0025), 6.0);
    draw(p, tp1, fragColor);
    
    // EYES / EYEBROWS
    if (cos(time+10.*.9) > 0.99) {
        isDarwinBlinking = true;
    }
    if (!isDarwinBlinking) {
        // EYELASHES
        vec2 w1 = vec2(sdLineSegment(tX(p, vec2(0.08, 0.11)), vec2(-0.01, 0.0025), vec2(0.005, 0.01), 0.0025), 6.0);
        draw(p, w1, fragColor);
        w1 = vec2(sdLineSegment(tX(p, vec2(0.08, 0.095)), vec2(-0.01, 0.0025), vec2(0.011, 0.01), 0.0025), 6.0);
        draw(p, w1, fragColor);
        
        w1 = vec2(sdLineSegment(tX(p, vec2(-0.055, 0.11)), vec2(-0.02, -0.01), vec2(-0.0425, 0.01), 0.0025), 6.0);
        draw(p, w1, fragColor);
        w1 = vec2(sdLineSegment(tX(p, vec2(-0.045, 0.13)), vec2(-0.02, -0.01), vec2(-0.0405, 0.005), 0.0025), 6.0);
        draw(p, w1, fragColor);
        
        i = vec2(sdCircle2(tX(p, vec2(-0.055, 0.1)), 0.038), 5.0);
        draw(p, i, fragColor);
        
        i = vec2(sdCircle2(tX(p, vec2(0.0425, 0.0925)), 0.038), 5.0);
        draw(p, i, fragColor);
        
        //pupil
        float move1 =  0.025;//(0.03*abs(sin(time*2)));
        //        float move1 =  (0.03*abs(sin(time)));
        i = vec2(sdCircle2(tX(p, vec2(-0.002+move1, 0.09)), 0.02), 6.0);
        draw(p, i, fragColor);
        
        // pupil
        float move2 = 0.021;//(0.025*abs(sin(time*2)));
        //        float move2 = (0.025*abs(sin(time)));
        i = vec2(sdCircle2(tX(p, vec2(-0.0955+move2, 0.0965)), 0.02), 6.0);
        draw(p, i, fragColor);
        
        vec2 ebp = tX(p, vec2(-0.05, 0.155));
        ebp *= rot2D(.0 * PI);
        ebp.x =ebp.x*-sin(ebp.x)*25.;
        i = vec2(sdLineSegmentRounded(ebp, vec2(0.005,0.005), vec2(-0.005,-0.005), 0.0075), 6.0);
        draw(p, i, fragColor);
        
        vec2 ebp2 = tX(p, vec2(0.055, 0.145));
        ebp2 *= rot2D(-.075 * PI);
        ebp2.x =ebp2.x*-sin(ebp2.x)*25.;
        i = vec2(sdLineSegmentRounded(ebp2, vec2(0.005,0.005), vec2(-0.005,-0.005), 0.0075), 6.0);
        draw(p, i, fragColor);
    } else {
        vec2 ebp2 = tX(p, vec2(0.03, 0.085));
        ebp2 *= rot2D(-.075 * PI);
        i = vec2(sdLineSegmentRounded(ebp2, vec2(0.05,0.02), vec2(-0.005,-0.005), 0.01), 6.0);
        draw(p, i, fragColor);
        i = vec2(sdLineSegmentRounded(ebp2, vec2(0.075,-0.0025), vec2(-0.005,-0.005), 0.01), 6.0);
        draw(p, i, fragColor);
        
        vec2 ebp3 = tX(p, vec2(-0.015, 0.095));
        ebp3 *= rot2D(.0 * PI);
        i = vec2(sdLineSegmentRounded(ebp3, vec2(-0.05,0.02), vec2(-0.005,-0.005), 0.01), 6.0);
        draw(p, i, fragColor);
        i = vec2(sdLineSegmentRounded(ebp3, vec2(-0.075,-0.0025), vec2(-0.005,-0.005), 0.01), 6.0);
        draw(p, i, fragColor);
        
        vec2 ebp4 = tX(p, vec2(0.03, 0.1));
        ebp4 *= rot2D(.3 * PI);
        ebp4.x =ebp4.x*-sin(ebp4.x)*25.;
        i = vec2(sdLineSegmentRounded(ebp4, vec2(0.005,0.005), vec2(-0.003,-0.003), 0.004), 6.0);
        draw(p, i, fragColor);
        
        vec2 ebp5 = tX(p, vec2(-0.02, 0.105));
        ebp5 *= rot2D(-.3 * PI);
        ebp5.x =ebp5.x*-sin(ebp5.x)*25.;
        i = vec2(sdLineSegmentRounded(ebp5, vec2(0.005,0.005), vec2(-0.003,-0.003), 0.004), 6.0);
        draw(p, i, fragColor);
    }
    p = origP;
    
    return fragColor;
}

vec4 sceneDistance(vec2 p, inout vec4 fragColor)
{
    float modTime = 4.;
    modTime = mod((iTime-4.),maxTime);
    
    vec2 darwinP = tX(p, vec2(0.5, -0.01));
    if (modTime > 8.) {
        isDarwinWalking = false;
        darwinP = tX(p, vec2(0.2, -0.01));
        bothHighFiving = true;
    } else {
        darwinP = tX(p, vec2(1.-(modTime/100.)*10., -0.01));
    }
    
    darwin(darwinP, fragColor, modTime);
    
    if (modTime > 9.6) {
        float percentIncrease = clamp((modTime-10.)/1.4, 0.0001, 1.);
        float percent = 12.*percentIncrease;
        vec2 star = vec2(sdfStar5(tX(p, vec2(-0.01, -0.01))/percent)*percent, 22.0);
        draw(p, star, fragColor);
    }
    
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
