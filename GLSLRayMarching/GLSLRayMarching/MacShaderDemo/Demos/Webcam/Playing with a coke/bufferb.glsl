//
// Gameplay computation.
//
// The gameplay buffer is 14x14 pixels. The whole game is run/played for each one of these
// pixels. A filter in the end of the shader takes only the bit  of infomration that needs 
// to be stored in each texl of the game-logic texture.

const vec2 txBallPosVel = vec2(0.0,0.0);
const vec2 txState      = vec2(1.0,0.0);
const vec2 txDebug      = vec2(2.0,0.0);
const vec2 txScore      = vec2(3.0,0.0);


const float KEY_SPACE = 32.5/256.0;


float isInside( vec2 p, vec2 c ) { vec2 d = abs(p-0.5-c) - 0.5; return -max(d.x,d.y); }
float isInside( vec2 p, vec4 c ) { vec2 d = abs(p-0.5-c.xy-c.zw*0.5) - 0.5*c.zw - 0.5; return -max(d.x,d.y); }

float hash1( float n ) { return fract(sin(n)*138.5453123); }


vec4 loadValue( in vec2 re )
{
    return texture( iChannel0, (0.5+re) / iChannelResolution[0].xy, -100.0 );
}

void storeValue( in vec2 re, in vec4 va, inout vec4 fragColor, in vec2 fragCoord )
{
    fragColor = ( isInside(fragCoord,re) > 0.0 ) ? va : fragColor;
}
void storeValue( in vec4 re, in vec4 va, inout vec4 fragColor, in vec2 fragCoord )
{
    fragColor = ( isInside(fragCoord,re) > 0.0 ) ? va : fragColor;
}

bool hasCollision( vec2 pos )
{
    vec3 origColor = vec3( texture(iChannel1, pos));
    if ( origColor.r > .0001)
    {
        return true;
    }
    return false;
}
bool hasWon( vec2 pos )
{
    vec3 origColor = vec3( texture(iChannel1, pos));
    if ( origColor.b > .5)
    {
        return true;
    }
    return false;
}

vec2 getNormal( vec2 pos)
{
    vec3 diff 		= vec3(vec2( 1., 1.) / iResolution.xy, .0);
    vec3 rightColor = vec3(texture(iChannel1, pos + diff.xz ));
    vec3 downColor  = vec3(texture(iChannel1, pos + diff.zy ));
    vec3 leftColor  = vec3(texture(iChannel1, pos - diff.xz ));
    vec3 upColor    = vec3(texture(iChannel1, pos - diff.zy ));

    float difX = rightColor.r - leftColor.r;
    float difY = downColor.r - upColor.r;
    vec2 norm1 = vec2( -difX, -difY);
    if ( length( norm1 ) > .00001)
    	return normalize(norm1);
    return vec2(.0);
}



void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    // don't compute gameplay outside of the data area
    if( fragCoord.x > 4.0 || fragCoord.y>1.0 ) discard;
    
    
    vec4  balPosVel = loadValue( txBallPosVel );
    float state     = loadValue( txState ).x;
    float debug 	= loadValue( txDebug).x;
    float debug2 	= loadValue( txDebug).y;
    float level     = loadValue( txState ).y;
    float score     = loadValue( txScore ).x;
    
    
    //---------------------------------------------------------------------------------
    // init
	//---------------------------------------------------------------------------------
	if( iFrame==0 )
    {
        state = -1.0;
        level = .5;
    }
	
    if( state < -0.5 )
    {
        state = 0.0;
        balPosVel = vec4(.94,.1, -.01,.01);
        state = 0.0;
        debug = 1.0;
        debug2 = 1.0;
    }

    // Game :
    // game over (or won), wait for space key press to resume
    if( state > 0.5 )
    {
        float pressSpace = texture( iChannel2, vec2(KEY_SPACE,0.25) ).x;
        if( pressSpace>0.5 )
        {
            state = -1.0;
            level += 1.;
        }
    }
    
    // if game mode (not game over), play game
    else 
    {
        //balPosVel = vec4(.3,.3+fTrame*.02, 0.6,1.0);
         // bounce
         balPosVel.xy += balPosVel.zw;
        
        if ( hasCollision( balPosVel.xy) )
        {
            vec2 n = getNormal(balPosVel.xy);
            balPosVel.zw = reflect(  balPosVel.zw, n );
            debug += 1.;
        }
        if ( hasWon(balPosVel.xy) )
        {
            score += 1.;
            state = 1.;
        }
        
        if ( balPosVel.x < .05 || balPosVel.x > .95)
            balPosVel.z = -balPosVel.z;
        if ( balPosVel.y < .05 || balPosVel.y > .95 )
            balPosVel.w = - balPosVel.w;
    }
    
    //---------------------------------------------------------------------------------
	// store game state
	//---------------------------------------------------------------------------------
    fragColor = vec4(0.0);
 
    storeValue( txBallPosVel, vec4(balPosVel),             fragColor, fragCoord );
    storeValue( txState,      vec4(state,level,0.0,0.0),   fragColor, fragCoord );
    storeValue( txDebug,      vec4(debug,debug2,0.0,0.0),  fragColor, fragCoord );
    storeValue( txScore,      vec4(score,0.,0.0,0.0),  	   fragColor, fragCoord );
    
}