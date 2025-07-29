package flixel.graphics.tile;

// todo: optimize it
class FlxGraphicsShader extends openfl.display.GraphicsShader
{
	@:glVertexHeader("
		attribute float alpha;
		attribute vec4 colorMultiplier;
		attribute vec4 colorOffset;
		uniform bool hasColorTransform;
	")
	@:glVertexBody("openfl_Alphav *= alpha;

		if (hasColorTransform)
		{
			if (openfl_HasColorTransform)
			{
				openfl_ColorOffsetv = openfl_ColorOffsetv * colorMultiplier + colorOffset / 255.0;
				openfl_ColorMultiplierv *= colorMultiplier;
			}
			else
			{
				openfl_ColorOffsetv = colorOffset / 255.0;
				openfl_ColorMultiplierv = colorMultiplier;
			}
		}
	", true)
	@:glFragmentHeader("
		uniform bool isFlixelDraw;  // TODO: Is this still needed? Apparently, yes!
		#define hasTransform isFlixelDraw
		uniform bool hasColorTransform;
		vec4 flixel_applyColorTransform(vec4 color)
		{
			if (!isFlixelDraw || color.a == 0.0)
				return color;
			if (hasColorTransform || openfl_HasColorTransform)
			{
				float _tempAlpha = color.a;
				color.rgb /= _tempAlpha;
				color = openfl_ColorOffsetv + color * openfl_ColorMultiplierv;
				color.rgb = clamp(color.rgb * _tempAlpha, 0.0, 1.0);
			}
			return color*openfl_Alphav;
		}
		vec4 flixel_texture2D(sampler2D bitmap, vec2 coord)
		{
			return flixel_applyColorTransform(texture2D(bitmap, coord));
		}
	", true)
	#if emscripten
	@:glFragmentSource("
		#pragma header

		void main(void) {
			gl_FragColor = flixel_texture2D(bitmap, openfl_TextureCoordv).bgra;
		}")
	#else
	@:glFragmentSource("
		#pragma header

		void main(void) {
			gl_FragColor = flixel_texture2D(bitmap, openfl_TextureCoordv);
		}")
	#end
	public function new()
	{
		super();
	}

	public function preload()
	{
		__context = FlxG.stage.context3D;
		__init();
	}
}
