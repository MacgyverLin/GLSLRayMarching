
const float count = 100.;

float speed = .3;
float friction = 3.;
float fade = 0.1;
float thin = 0.02;

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    // coordinates
    vec2 uv = fragCoord/iResolution.xy;
    vec2 p = (2.*fragCoord-iResolution.xy)/iResolution.y;
    
    // buffer
    vec4 frame = texture(iChannel0, uv);
    
    // pixels are data (bottom left)
    if (fragCoord.y < 1. && fragCoord.x < count)
    {
        float id = fragCoord.x;
            
        // init
        if (iFrame < 1)
        {
            // random position and velocity
            frame = vec4(hash41(id)*2.-1.);
            frame.zw *= .01;
        }
        else
        {
            // coordinates
            vec2 aspect = vec2(iResolution.x/iResolution.y, 1.);
            vec2 p = frame.xy;
            vec2 offset = vec2(0);
            vec2 target = vec2(0);
            
            // respawn
            float t = iTime * 10.;
            float idd = id+floor(t) * count;
            if (hash11(idd) > .95 && fract(t) < .1)
            {
                frame = hash41(idd)*2.-1.;
                frame.xy *= aspect;
                frame.zw *= .01;
                fragColor = frame;
                return;
            }
            
            // interaction
            if (iMouse.z > 0.)
            {
                target = (2.*iMouse.xy-iResolution.xy)/iResolution.y;
            }
            
            // curl
            float noise = fbm(vec3(p, length(p) + iTime));
            float a = noise * 6.28;
            offset += vec2(cos(a), sin(a));
            
            // target
            offset += normalize(target.xy-p) * 2. * length(target.xy-p);
            
            // jitter
            offset += (hash21(id)*2.-1.)*(.5+.5*sin(iTime));
            
            // inertia
            vec2 velocity = frame.zw;
            velocity = velocity * (1.-friction*iTimeDelta) + offset * speed * iTimeDelta;
            
            // apply
            frame.xy += velocity;
            frame.zw = velocity;
        }
    }
    
    // pixels are colors
    else
    {
        float matID = 0.;
        float dist = 100.;
        float dither = texture(iChannel1, fragCoord/1024.).r;

        for (float i = 0.; i < count; ++i)
        {
            // iterate pixel data
            vec4 data = texelFetch(iChannel0, ivec2(i,0), 0);
            
            // circle shape (jitter blending with previous pos)
            vec2 pos = data.xy - data.zw * dither;
            float shape = length(pos-p);
            matID = shape < dist ? i : matID;
            dist = min(dist, shape);
        }

        // grayscale
        float shade = smoothstep(thin,.0,dist);

        // buffer
        frame.r = max(frame.r - fade, shade);
        
        // material layer
        if (dist < thin) frame.g = matID;
    }
    
    fragColor = frame;
}