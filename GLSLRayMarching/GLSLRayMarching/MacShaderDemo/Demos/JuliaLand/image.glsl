
int julia(vec2 c, vec2 z) {
	z.y = mod(z.y + 0.9, 1.8) - 0.9;
	int counter = 0;
	while(counter < 600) {
		z = vec2(z.x * z.x - z.y * z.y, 2.0 * z.x * z.y) + c;
		if (length(z) > 2.) break;
		counter++;
	}
	return counter;
}

vec3 skycol(int counter) {
	float val = 2.0 * log(float(counter + 3)) - 3.891 - 1.570;
	float red = sin(0.5 * val) * 0.20 + 0.80;
	float gre = sin(0.5 * val) * 0.20 + 0.80;
	float blu = sin(0.5 * val) * 0.10 + 0.90;
	return vec3(red, gre, blu);
}

vec3 gndcol(int counter) {
	float val = 2.0 * log(float(counter + 3)) - 3.891 - 1.570;
	float red = sin(1.3 * val) * 0.250 + 0.350;
	float gre = sin(1.1 * val) * 0.282 + 0.518;
	float blu = sin(1.0 * val) * 0.694 + 0.306;
	return vec3(red, gre, blu) * (0.8 + 0.3 * sin(0.1 * float(counter)));
}


const vec3 camera = vec3(0.0, 0.3, 0.6);

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	vec2 uv = (gl_FragCoord.xy - 0.5 * iResolution.xy) / min(iResolution.x, iResolution.y) + vec2(0.0, 0.5);

	float den = camera.z / (camera.z - uv.y);
	vec2 r = 0.02 * vec2(uv.x * den, camera.y * abs(den));

	int counter;
	vec3 color;
	float t2 = 0.080 * iTime;
	float t3 = 0.004 * iTime;

	if(den > 0.0) {
		counter = julia(vec2(-0.8, 0.156), r + vec2(0.0, t2));
		color = gndcol(counter);
		if (counter < 100) {
			int counter0 = julia(vec2(-0.8, 0.156), vec2(-r.x, r.y + 0.9 + t3));
			color = mix(0.7 * skycol(counter0), color, float(counter) / 100.0);
		}
	} else {
		counter = julia(vec2(-0.8, 0.156), r + vec2(0.0, 0.9 + t3));
		color = skycol(counter);
	}
    
    // postprocessing
    // fog
    float fog = 0.9 * fract(r.y / (r.y + 0.04));
    color = mix(color, vec3(1.00, 0.90, 0.70), fog);
    // vignette
    color *= cos(uv.x) * cos(2.0 * (uv.y - 0.5)) + 0.2;
    
    // Output to screen
    fragColor = vec4(color,1.0);
}