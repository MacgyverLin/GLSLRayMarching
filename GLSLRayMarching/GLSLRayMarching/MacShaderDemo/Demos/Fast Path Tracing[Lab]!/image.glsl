/*
	"Fast PathTracing[Lab]!" by 834144373(恬纳微晰)
	This shader url : https://www.shadertoy.com/view/XdVfRm
	Licence: CC3.0 署名（BY）-非商业性使用（NC）-相同方式共享（SA）
	Also 834144373 is 恬纳微晰 or TNWX or 祝元洪
*/
/*
--------------------Main Reference Knowledge-------------------
MIS: [0]https://graphics.stanford.edu/courses/cs348b-03/papers/veach-chapter9.pdf
     [1]https://hal.inria.fr/hal-00942452v1/document
     [2]Importance Sampling Microfacet-Based BSDFs using the Distribution of Visible Normals. Eric Heitz, Eugene D’Eon
     [3]Understanding the Masking-Shadowing Function in Microfacet-Based BRDFs. Eric Heitz
     [4]Microfacet Models for Refraction through Rough Surfaces. Bruce Walter, Stephen R. Marschner, Hongsong Li, Kenneth E. Torrance
	Note: More details about theory and math you can easy find on "Common" shader.
*/
void mainImage( out vec4 C, in vec2 U ){
    vec2 R = iResolution.xy;
   	vec2 uv = U/R;
    
    /*
		Thanks for reinder suggestion for anti-aliasing,:)
		I uncomment FXAA and added the Triangular Noise for camera dither.
		if you don't do the some tracing,like game,the best is "Triangular Noise and TAA".
		And if you just do a fewer sample with tracing,it seems "AI-Denoise" can help you.	
	*/
    //C = FXAA(iChannel0,uv,R);
    C = texture(iChannel0,uv);
    
    //C.rgb = ExposureCorrect(C.rgb,1.1, -1.3);
    C.rgb = ExposureCorrect(C.rgb,2.1, -0.8);
    C.rgb = ACESFilmicToneMapping(C.rgb);
}

/* 
	Hum... if you see black point on screen,please report,
	because it's NAN point,so thanks :)
*/