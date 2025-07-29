package openfl.display;

import openfl.utils.ByteArray;

#if !openfl_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
class GraphicsShader extends Shader
{
	@:glVertexHeader("attribute float openfl_Alpha;
		attribute vec4 openfl_ColorMultiplier;
		attribute vec4 openfl_ColorOffset;
		attribute vec4 openfl_Position;
		attribute vec2 openfl_TextureCoord;

		varying float openfl_Alphav;
		varying vec4 openfl_ColorMultiplierv;
		varying vec4 openfl_ColorOffsetv;
		varying vec2 openfl_TextureCoordv;

		uniform mat4 openfl_Matrix;
		uniform bool openfl_HasColorTransform;
		uniform vec2 openfl_TextureSize;", true)
	@:glVertexBody("openfl_Alphav = openfl_Alpha;
		openfl_TextureCoordv = openfl_TextureCoord;
		gl_Position = openfl_Matrix * openfl_Position;
		if (openfl_HasColorTransform) {
			openfl_ColorMultiplierv = openfl_ColorMultiplier;
			openfl_ColorOffsetv = openfl_ColorOffset / 255.0;
		}", true)
	@:glVertexSource("
		#pragma header

		void main(void) {

			#pragma body

		}")
	@:glFragmentHeader("varying float openfl_Alphav;
		varying vec4 openfl_ColorMultiplierv;
		varying vec4 openfl_ColorOffsetv;
		varying vec2 openfl_TextureCoordv;

		uniform bool openfl_HasColorTransform;
		uniform vec2 openfl_TextureSize;
		uniform sampler2D bitmap;
		vec4 openfl_applyColorTransform(vec4 color)
		{
			if (color.a == 0.0)
				return color;
			if (openfl_HasColorTransform)
			{
				float _tempAlpha = color.a;
				color.rgb /= _tempAlpha;
				color = openfl_ColorOffsetv + color * openfl_ColorMultiplierv;
				color.rgb = clamp(color.rgb * _tempAlpha, 0.0, 1.0);
			}
			return color * openfl_Alphav;
		}", true)
	@:glFragmentBody("
		gl_FragColor = openfl_applyColorTransform(texture2D(bitmap, openfl_TextureCoordv));
	")
	#if emscripten
	@:glFragmentSource("
		#pragma header

		void main(void) {

			#pragma body

			gl_FragColor = gl_FragColor.bgra;

		}")
	#else
	@:glFragmentSource("
		#pragma header

		void main(void) {

			#pragma body

		}")
	#end
	public function new(?code:ByteArray)
	{
		super(code);
	}
}
