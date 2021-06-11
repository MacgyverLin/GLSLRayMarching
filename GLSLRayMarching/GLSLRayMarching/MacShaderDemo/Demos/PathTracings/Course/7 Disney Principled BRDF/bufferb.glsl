const vec2 acc_start_uv = vec2(0.0); //accumulation start frame

int GetFrame() 
{
	if( iMouse.z > 0.0 ) 
	{
        return 0;
    } 
	else 
	{
        return iFrame - int(texture(iChannel0, (acc_start_uv + vec2(0.5, 0.5)) / iResolution.xy).x);
    }
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	vec2 uv = fragCoord.xy / iResolution.xy;
	vec2 uvtest = floor(fragCoord.xy);

	if(all(equal(uvtest, acc_start_uv))) 
	{
		fragColor = vec4(GetFrame());
	}
	else
	{
		int frame = GetFrame();
		vec4 c0 = texture(iChannel0, uv);
		vec4 c1 = texture(iChannel1, uv);
		fragColor = (c0 * float(frame) + c1) / float(frame + 1);
	
		fragColor.a = 1.0;
	}
}