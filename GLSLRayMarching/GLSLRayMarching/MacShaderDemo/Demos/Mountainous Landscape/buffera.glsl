
// This buffer is used to store global variables, like camera position and such.

MOUNTAIN_FUNCTIONS

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec4 prevColor = texelFetch(iChannel0, ivec2(fragCoord), 0);
    
    // Change movement mode.
    if(ivec2(fragCoord) == ivec2(MOVEMENT_MODE,0)){
        bool key1IsDown = texelFetch(iChannel2, ivec2(KEY_1,0), 0).x > 0.5;
        bool key2IsDown = texelFetch(iChannel2, ivec2(KEY_2,0), 0).x > 0.5;
        bool key3IsDown = texelFetch(iChannel2, ivec2(KEY_3,0), 0).x > 0.5;
        if(key1IsDown){
        	prevColor.r = MOVE_MODE_AUTO;
        }else if(key2IsDown){
        	prevColor.r = MOVE_MODE_WALK;
        }else if(key3IsDown){
        	prevColor.r = MOVE_MODE_FREE;
        }
    }
    float movementMode = texelFetch(iChannel0, ivec2(MOVEMENT_MODE, 0), 0).x;
    
    // Accelerate.
    float sensitivity = texelFetch(iChannel0, ivec2(CAMERA_SENSITIVITY, 0), 0).x;
    if(ivec2(fragCoord) == ivec2(CAMERA_SENSITIVITY,0)){
        if(sensitivity == 0.){
            sensitivity = 0.1;
            prevColor.r = 0.1;
        }
        if(texelFetch( iChannel2, ivec2(KEY_C,0), 0 ).x > 0.5 && prevColor.r < 0.15){
            prevColor.r *= 1.05;
        }
        if(texelFetch( iChannel2, ivec2(KEY_V,0), 0 ).x > 0.5 && prevColor.r > 0.001/10.){
            prevColor.r /= 1.05;
        }
    }
    
    // Rotate.
    vec3 forward = texelFetch(iChannel0, ivec2(CAMERA_DIRECTION, 0), 0).xyz;
    if(length(forward) == 0.){
        forward = vec3(0,0,-1);
    }
    forward = normalize(forward);
    vec3 right = normalize(cross(forward, vec3(0,1,0)));
    vec3 up = cross(right, forward);
    if(ivec2(fragCoord) == ivec2(CAMERA_DIRECTION,0)){
        if(movementMode == MOVE_MODE_AUTO){
            forward = vec3(
                -sin((iTime + START_TIME)*AUTO_MOVEMENT_SPEED + 0.2),
                -0.1,
                -cos((iTime + START_TIME)*AUTO_MOVEMENT_SPEED + 0.2)
            );
        }else{
            bool arrowRight = texelFetch( iChannel2, ivec2(KEY_RIGHT,0), 0 ).x > 0.5;
            bool arrowLeft = texelFetch( iChannel2, ivec2(KEY_LEFT,0), 0 ).x > 0.5;
            bool arrowUp = texelFetch( iChannel2, ivec2(KEY_UP,0), 0 ).x > 0.5;
            bool arrowDown = texelFetch( iChannel2, ivec2(KEY_DOWN,0), 0 ).x > 0.5;
            const float rotationSpeed = 0.04;
            if(arrowRight){
                forward = normalize(forward + right*rotationSpeed);
            }
            if(arrowLeft){
                forward = normalize(forward - right*rotationSpeed);
            }
            if(arrowUp){
                forward = normalize(forward + up*rotationSpeed);
            }
            if(arrowDown){
                forward = normalize(forward - up*rotationSpeed);
            }
        }
    	vec3 right = normalize(cross(forward, vec3(0,1,0)));
    	vec3 up = cross(right, forward);
        prevColor.xyz = normalize(forward);
    }
    
    // Calculate collision.
    vec3 pos;
    vec3 cameraPos;
    vec3 normal;
    float sd;
    if(ivec2(fragCoord) == ivec2(CAMERA_POS,0) || ivec2(fragCoord) == ivec2(VELOCITY,0)){
        cameraPos = texelFetch(iChannel0, ivec2(CAMERA_POS, 0), 0).xyz;
        pos = cameraPos - vec3(0, 0.001, 0);
        normal;
        sd;
        sdMountainNormal(
            /*in vec3 pos=*/pos, /*inout vec3 normal=*/normal, /*out float sd=*/sd,
            /*in float resolution=*/3., /*in float df=*/0.00003
        );
    }
    
    // Translate.
    if(ivec2(fragCoord) == ivec2(CAMERA_POS,0)){
        bool dDown = texelFetch( iChannel2, ivec2(KEY_D,0), 0 ).x > 0.5;
        bool aDown = texelFetch( iChannel2, ivec2(KEY_A,0), 0 ).x > 0.5;
        bool spaceDown = texelFetch( iChannel2, ivec2(KEY_SPACE,0), 0 ).x > 0.5;
        bool shiftDown = texelFetch( iChannel2, ivec2(KEY_SHIFT,0), 0 ).x > 0.5;
        bool wDown = texelFetch( iChannel2, ivec2(KEY_W,0), 0 ).x > 0.5;
        bool sDown = texelFetch( iChannel2, ivec2(KEY_S,0), 0 ).x > 0.5;
        if(movementMode == MOVE_MODE_AUTO){
            const float rad = 30.;
            vec3 camPos = vec3(
            	cos((iTime + START_TIME)*AUTO_MOVEMENT_SPEED)*rad,
                0.,
                -sin((iTime + START_TIME)*AUTO_MOVEMENT_SPEED)*rad
            );
        	prevColor.xyz = vec3(
            	camPos.x,
                //-sdMountain(camPos, 0., true)*3.+0.5,
                1.269,
                camPos.z
            );
        }else if(movementMode == MOVE_MODE_WALK){
        	vec3 velocity = texelFetch( iChannel0, ivec2(VELOCITY,0), 0 ).xyz;
            prevColor.xyz += velocity;
            if(sd < 0.){
            	prevColor.y += -sd - 0.00001;
            }
        } else if(movementMode == MOVE_MODE_FREE){
            if(wDown){
                prevColor.xyz += forward*sensitivity;
            }
            if(sDown){
                prevColor.xyz -= forward*sensitivity;
            }
            if(dDown){
                prevColor.xyz += right*sensitivity;
            }
            if(aDown){
                prevColor.xyz -= right*sensitivity;
            }
            if(spaceDown){
                prevColor.xyz += up*sensitivity;
            }
            if(shiftDown){
                prevColor.xyz -= up*sensitivity;
            }
        }
    }
    
    // Accelerate.
    if(ivec2(fragCoord) == ivec2(VELOCITY,0)){
        
        if(movementMode == MOVE_MODE_WALK){
            // Gravity.
            //const float gravity = -0.000002;
            const float gravity = -1.513888888888e-6 * 1.5; // 9.81m/s^2 * 1.5
            prevColor.y += gravity;
            
        	// Collision.
            vec3 velocity = prevColor.xyz;
            bool dDown = texelFetch( iChannel2, ivec2(KEY_D,0), 0 ).x > 0.5;
            bool aDown = texelFetch( iChannel2, ivec2(KEY_A,0), 0 ).x > 0.5;
            bool spaceDown = texelFetch( iChannel2, ivec2(KEY_SPACE,1), 0 ).x > 0.5;
            bool shiftDown = texelFetch( iChannel2, ivec2(KEY_SHIFT,0), 0 ).x > 0.5;
            bool wDown = texelFetch( iChannel2, ivec2(KEY_W,0), 0 ).x > 0.5;
            bool sDown = texelFetch( iChannel2, ivec2(KEY_S,0), 0 ).x > 0.5;
            vec3 flatForward = normalize(vec3(forward.x, 0, forward.z));
            if(sd < 0. && dot(velocity, normal) < 0.){
				// Collision impulse.
                //velocity = reflect(velocity, normal);
                velocity.y = 0.;
            }
            if(sd < 0.0002){
                float walkForce = 0.00001;
                const float jumpForce = 0.00006;
                if(shiftDown){
                	walkForce *= 2.;
                }
                // Walk force.
                velocity.xz *= 0.8; // Walking friction.
                vec3 walkForceVec = vec3(0);
                if(wDown){
                	walkForceVec += flatForward*walkForce;
                }
                if(sDown){
                    walkForceVec -= flatForward*walkForce;
                }
                if(dDown){
                    walkForceVec += right*walkForce;
                }
                if(aDown){
                    walkForceVec -= right*walkForce;
                }
            	if(spaceDown){
                    velocity.y = 0.;
                    walkForceVec += up*jumpForce;
                }
                if(dot(normalize(walkForceVec), normal) > -0.75){
	                velocity += walkForceVec;
                }
            }
            prevColor.xyz = velocity;
        } else {
        	prevColor.xyz = vec3(0);
        }
    }
    
    // Check for screen resolution change.
    if(ivec2(fragCoord) == ivec2(SCREEN_RESOLUTION,0)){
        prevColor.xy = iResolution.xy;
    }else if(ivec2(fragCoord) == ivec2(DO_BUFFER_UPDATE,0)){
        bool qIsDown = texelFetch( iChannel2, ivec2(KEY_Q, 0), 0 ).x > 0.5;
        bool eIsDown = texelFetch( iChannel2, ivec2(KEY_E, 0), 0 ).x > 0.5;
        if(
            texelFetch( iChannel0, ivec2(SCREEN_RESOLUTION, 0), 0 ).xy != iResolution.xy || qIsDown || eIsDown
        ){
        	prevColor.x = 1.;
        }else{
        	prevColor.x = 0.;
        }
    }
    
    // Check for screen resolution change.
    if(ivec2(fragCoord) == ivec2(PRECISION_TEST,0)){
        prevColor.x = PRECISION_NUMBER_F;
        
    }
    
    // Change seed.
    bool qIsDown = texelFetch(iChannel2, ivec2(KEY_Q,0), 0).x > 0.5;
    bool eIsDown = texelFetch(iChannel2, ivec2(KEY_E,0), 0).x > 0.5;
    if(ivec2(fragCoord) == ivec2(CHANGE_SEED,0)){
        if(qIsDown){
        	prevColor.r += 0.1;
        }
        if(eIsDown){
        	prevColor.r -= 0.1;
        }
    }
    
    //
    fragColor = prevColor;
}









