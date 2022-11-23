
// Not surprinsgly, a lot come from the brick game from IQ: https://www.shadertoy.com/view/MddGzf


const vec2 txBallPosVel = vec2(0.0,0.0);
const vec2 txState      = vec2(1.0,0.0);
const vec2 txDebug      = vec2(2.0,0.0);
const vec2 txScore      = vec2(3.0,0.0);

const float ballRadius = 0.025;
const vec2 shadowOffset = vec2(0.015,0.015);

float hash1( float n ) { return fract(sin(n)*138.5453123); }


float SampleDigit(const in float n, const in vec2 vUV)
{
    if( abs(vUV.x-0.5)>0.5 || abs(vUV.y-0.5)>0.5 ) return 0.0;

    // digit data by P_Malin (https://www.shadertoy.com/view/4sf3RN)
    float data = 0.0;
         if(n < 0.5) data = 7.0 + 5.0*16.0 + 5.0*256.0 + 5.0*4096.0 + 7.0*65536.0;
    else if(n < 1.5) data = 2.0 + 2.0*16.0 + 2.0*256.0 + 2.0*4096.0 + 2.0*65536.0;
    else if(n < 2.5) data = 7.0 + 1.0*16.0 + 7.0*256.0 + 4.0*4096.0 + 7.0*65536.0;
    else if(n < 3.5) data = 7.0 + 4.0*16.0 + 7.0*256.0 + 4.0*4096.0 + 7.0*65536.0;
    else if(n < 4.5) data = 4.0 + 7.0*16.0 + 5.0*256.0 + 1.0*4096.0 + 1.0*65536.0;
    else if(n < 5.5) data = 7.0 + 4.0*16.0 + 7.0*256.0 + 1.0*4096.0 + 7.0*65536.0;
    else if(n < 6.5) data = 7.0 + 5.0*16.0 + 7.0*256.0 + 1.0*4096.0 + 7.0*65536.0;
    else if(n < 7.5) data = 4.0 + 4.0*16.0 + 4.0*256.0 + 4.0*4096.0 + 7.0*65536.0;
    else if(n < 8.5) data = 7.0 + 5.0*16.0 + 7.0*256.0 + 5.0*4096.0 + 7.0*65536.0;
    else if(n < 9.5) data = 7.0 + 4.0*16.0 + 7.0*256.0 + 5.0*4096.0 + 7.0*65536.0;
    
    vec2 vPixel = floor(vUV * vec2(4.0, 5.0));
    float fIndex = vPixel.x + (vPixel.y * 4.0);
    
    return mod(floor(data / pow(2.0, fIndex)), 2.0);
}

float PrintInt( in vec2 uv, in float value )
{
    float res = 0.0;
    float maxDigits = 1.0+ceil(.01+log2(value)/log2(10.0));
    float digitID = floor(uv.x);
    if( digitID>0.0 && digitID<maxDigits )
    {
        float digitVa = mod( floor( value/pow(10.0,maxDigits-1.0-digitID) ), 10.0 );
        res = SampleDigit( digitVa, vec2(fract(uv.x), uv.y) );
    }

    return res;
}


vec2 getNormalDir( vec2 pos)
{
    vec3 diff 		= vec3(vec2( 1., 1.) / iResolution.xy, .0);
    vec3 rightColor = vec3(texture(iChannel0, pos + diff.xz ));
    vec3 upColor  	= vec3(texture(iChannel0, pos + diff.zy ));
    vec3 leftColor  = vec3(texture(iChannel0, pos - diff.xz ));
    vec3 downColor  = vec3(texture(iChannel0, pos - diff.zy ));

    float difX = rightColor.r - leftColor.r;
    float difY = upColor.r - downColor.r;
    return vec2( -difX, -difY);
}
vec2 getNormal(vec2 pos)
{
    vec2 n = getNormalDir(pos);
    if ( length( n ) > .00001)
    	return normalize(n);
    return vec2(.0);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    float px = 1.0/iResolution.y;
    vec2 uv = fragCoord.xy / iResolution.xy;
    uv.x =1. - uv.x;
    
    vec2  ballPos   = texture( iChannel1, (txBallPosVel+0.5)/iChannelResolution[0].xy ).xy;
    float debug     = texture( iChannel1, (txDebug+0.5)/iChannelResolution[0].xy ).x;
    float debug2    = texture( iChannel1, (txDebug+0.5)/iChannelResolution[0].xy ).y;
    float score     = texture( iChannel1, (txScore+0.5)/iChannelResolution[0].xy ).x;
    float state     = texture( iChannel1, (txState+0.5)/iChannelResolution[0].xy ).x;
    
    vec3 redColor = vec3( texture(iChannel2, uv));

    // Use a grey camera as the background :
    float grey = dot(vec3(texture(iChannel3, uv)), vec3(0.299, 0.587, 0.114) );

    vec3 col;
     // board
    {
        col = 0.6*vec3(0.4,0.6,0.7)*(1.0-0.4*length( 2.*(uv-.5) ));
        col *= 1.0 - 0.1*smoothstep( 0.0,1.0,sin(uv.x*320.0)*sin(uv.y*320.0))*(1.0 - smoothstep( 1.0, 1.01, abs(uv.x) ) );
    }
    col += vec3(grey * .5);
    // add normal halo:
    vec2 normalMap = getNormalDir( uv );
    if( length(normalMap) > .002)
        col += vec3( .0, length(normalMap)*10., .0);

    // add red color :
    if ( length(redColor) > .001)
    {
    	col = redColor;
        if (redColor.b > .5 )
        {
            vec3 col1= vec3(.98,.95,.1);
            vec3 col2= vec3(.0);
            if( state > 0.5 )
            {
            	col1= vec3(hash1(iTime), hash1(iTime+.3), hash1(iTime+.5));
            	col2= vec3(hash1(iTime+1.), hash1(iTime+.2), hash1(iTime+.1));
            }

            vec2 square = step( .5, fract(uv*20.) ) * 2. - 1.;
            float squareVal = square.x * square.y;
            squareVal = (squareVal +1.) / 2.;
            col = mix( col1, col2, squareVal);
        }
    }

    vec3 emi = vec3(0.0);
    // ball 
    {
        float hit = .0;

        // shadow
        float f = 1.0-smoothstep( ballRadius*0.5, ballRadius*2.0, length( uv - ballPos + shadowOffset ) );
        col = mix( col, col*0.4, f );

        // shape
        f = length( uv - ballPos ) - ballRadius;
        vec3 bcol = vec3(1.0,0.6,0.2);
        bcol *= 1.0 + 0.7*smoothstep( -3.0*px, -1.0*px, f );
        bcol *= 0.7 + 0.3*hit;
        col = mix( col, bcol, 1.0-smoothstep( 0.0, px, f ) );
        
        emi  += bcol*0.75*hit*exp(-500.0*f*f );
    }
    // add emmission
    col += emi;
    
    {
        vec2 uv3 = vec2( 1.-uv.x, uv.y);
        float f = PrintInt( (uv3-vec2(.001, .002))*10.0, score);
        col = mix( col, vec3(.0,1.0,1.0), f );
    }
    
    
    
    // debug info :
   /*
    {
        float f;
        //f= PrintInt( (uv-vec2(.001, .001))*10.0, debug);
        //col = mix( col, vec3(.0,1.0,1.0), f );

		f = PrintInt( (uv-vec2(.7, .001))*10.0, debug2);
        col = mix( col, vec3(.0,.0,1.0), f );
    }
	//*/

    fragColor = vec4(col, .1);
}