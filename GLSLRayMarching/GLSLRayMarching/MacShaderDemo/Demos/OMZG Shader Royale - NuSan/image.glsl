// Shader made Live during OMZG Shader Royale (12/02/2021) in about 80m
// 1st place
// https://www.twitch.tv/videos/911443995?t=01h12m13s
// Code is in "Buffer A" so I can use "feedback" effects

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
  vec2 uv=fragCoord.xy / iResolution.xy;
  fragColor = texture(iChannel0, uv);
}