
const vec2 txState      = vec2(1.0,0.0);
vec4 loadValue( in vec2 re )
{
    return texture( iChannel1, (0.5+re) / iChannelResolution[1].xy, -100.0 );
}

//#define NO_WEBCAMPRESENT

float isRedColorRGB( vec3 color )
{
    vec3 wantedColor=  vec3( 1.0, .0, .0 );
    float distToColor = distance( color.rgb, wantedColor ) ;
    return distToColor;
}

float isRedColor( vec3 color )
{
    return isRedColorRGB(color);
}


const float threshold = .6;
vec3 onlyRedImage( vec3 color, float grey, float isRed )
{
    vec3 resColor = vec3(0.);
    if ( isRed  < threshold )
        resColor = color;
    return resColor;
}

float Circle( vec2 uv, float size )
{
    if ( length(uv) < size )
        return 1.;
    return 0.;
}

float HorizontalLine( vec2 uv, float size )
{
    uv = uv /  vec2( size, .02);
    vec2 absUV = abs(uv);
    
    return 1.-step( 1., max(absUV.x, absUV.y) );
}
float VerticalLine( vec2 uv, float size )
{
    uv = uv /  vec2( .02, size);
    vec2 absUV = abs(uv);
    
    return 1.-step( 1., max(absUV.x, absUV.y) );
}


float WorldLimit( vec2 uv )
{
    float level = .0;
    level = max( level, VerticalLine(uv-vec2( .02, .5), .5));
    level = max( level, VerticalLine(uv-vec2( .04, .5), .5));
    level = max( level, VerticalLine(uv-vec2( 1.48, .5), .5 ));
    level = max( level, VerticalLine(uv-vec2( 1.46, .5), .5 ));
    level = max( level, HorizontalLine(uv-vec2(.75, .01), .75 ));
    level = max( level, HorizontalLine(uv-vec2(.75, .03), .75 ));
    level = max( level, HorizontalLine(uv-vec2(.75, .99), .75 ));
	level = max( level, HorizontalLine(uv-vec2(.75, .97), .75 ));
	return level;
}

vec3 level2( vec2 uv )
{
    uv.x *=1.5;
    vec3 color = vec3(.0);
    

    // create the level :
    float level = WorldLimit(uv);
    
    level = max( level, HorizontalLine(uv-vec2(.34, .3), .31 ));
    level = max( level, HorizontalLine(uv-vec2(1.16, .3), .31 ));
    level = max( level, HorizontalLine(uv-vec2( .75, .5), .54 ));
    level = max( level, VerticalLine(uv-vec2( .3, .9), .2 ));
    level = max( level, VerticalLine(uv-vec2( 1.2, .9), .2 ));
    level = max( level, HorizontalLine(uv-vec2(.42, .7), .18 ));
    level = max( level, HorizontalLine(uv-vec2(1.08, .7), .18 ));
    level = max( level, Circle( uv - vec2(.75, .11 ), .05) );
    
    const vec3 redColor = vec3(1., .0, .0);
    color = mix( color, redColor, level );

    
    // add the blue zone :
    vec2 uv2 = uv -vec2( .75,.99);
    uv2.y *= 3.;
    vec2 b = vec2(.1, .1);
    float zone = 1.- step( .3, length(max(abs(uv2)-b,0.0)));
	const vec3 blueColor = vec3(.0, .0, 1.);
    color = mix( color, blueColor, zone );

    return color;
}
vec3 level0( vec2 uv )
{
    uv.x *=1.5;
    vec3 color = vec3(.0);
    

    // create the level :
    float level = WorldLimit(uv);
    
    
    const vec3 redColor = vec3(1., .0, .0);
    color = mix( color, redColor, level );

    
    // add the blue zone :
    vec2 uv2 = uv -vec2( .75,.99);
    uv2.y *= 3.;
    vec2 b = vec2(.1, .1);
    float zone = 1.- step( .3, length(max(abs(uv2)-b,0.0)));
	const vec3 blueColor = vec3(.0, .0, 1.);
    color = mix( color, blueColor, zone );

    return color;
}
vec3 level1( vec2 uv )
{
    uv.x *=1.5;
    vec3 color = vec3(.0);
    

    // create the level :
    float level = WorldLimit(uv);
    
    level = max( level, HorizontalLine(uv-vec2( .75, .5), .54 ));
    
    const vec3 redColor = vec3(1., .0, .0);
    color = mix( color, redColor, level );

    
    // add the blue zone :
    vec2 uv2 = uv -vec2( .75,.99);
    uv2.y *= 3.;
    vec2 b = vec2(.1, .1);
    float zone = 1.- step( .3, length(max(abs(uv2)-b,0.0)));
	const vec3 blueColor = vec3(.0, .0, 1.);
    color = mix( color, blueColor, zone );

    return color;
}
vec3 level(vec2 uv )
{
    float level     = mod(loadValue( txState ).y, 3.);
    
    if ( level < 1. )
        return level0(uv);
    else if (level < 2.)
        return level1(uv);
    return level2(uv);
}



#ifndef  NO_WEBCAMPRESENT
void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	vec2 uv = fragCoord.xy / iResolution.xy;
    vec3 origColor = vec3( texture(iChannel0, uv));
    float grey = dot(vec3(origColor), vec3(0.299, 0.587, 0.114) );
    
    float isRed = isRedColor( origColor );
    
    // get red color from camera :
	vec3 color = onlyRedImage( origColor, grey, isRed );
    
    // add level :
    color += level(uv);
    
    // to help debug without camera :)
    if (iMouse.z > .5 )
    {
        vec2 mouseUV = iMouse.xy / iResolution.xy;
        mouseUV.x = (1.-mouseUV.x);
        
        float m = HorizontalLine( uv - mouseUV, .05);
        const vec3 redColor = vec3(1., .0, .0);
    	color = mix( color, redColor, m );
    }
    
	fragColor = vec4(color, .1);
}
#else

//-------------------------------------------------------------


void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	vec2 uv = fragCoord.xy / iResolution.xy;
    uv -= vec2(.5);
    
    vec3 color = vec3(.0);
    //vec3 color = vec3(1., .0, .0);
    const float repeatValue = .2;
    const float repeatValue2 = repeatValue /2.;
    uv = mod( uv+vec2(repeatValue2), repeatValue) - vec2(repeatValue2);
    //if ( length(uv )  < .05)
    //    color = vec3(1., .0, .0);
    const vec3 redColor = vec3(1., .0, .0);
    color = mix( color, redColor, 1.-step( .05, length(uv) ) );
	fragColor = vec4(color, .1);
}
#endif //  NO_WEBCAMPRESENT
