// "in my crawl space"
// Shadertoy port of our windows 4k intro:

// https://www.pouet.net/prod.php?which=82169

// https://www.youtube.com/watch?v=jw-nC5bINFc






void mainImage( out vec4 fragColor, in vec2 fragCoord )
{

	vec2 uv = (fragCoord.xy/iResolution.xy);
    fragColor = texture(iChannel0, uv);
}