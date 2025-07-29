package game.shaders;

import flixel.FlxG;

class ColorSwap
{
	public var shader(default, null):ColorSwapShader = new ColorSwapShader();
	public var hue(default, set):Float = 0;
	public var saturation(default, set):Float = 0;
	public var brightness(default, set):Float = 0;

	public function dispose() {
		shader = null;
		return null;
	}

	inline function set_hue(value:Float) {
		hue = value;
		#if !macro
		shader.uTime.value[0] = hue;
		#end
		return hue;
	}

	inline function set_saturation(value:Float) {
		saturation = value;
		#if !macro
		shader.uTime.value[1] = saturation;
		#end
		return saturation;
	}

	inline function set_brightness(value:Float) {
		brightness = value;
		#if !macro
		shader.uTime.value[2] = brightness;
		#end
		return brightness;
	}

	public function new()
	{
		#if !macro
		shader.uTime.value = [hue, saturation, brightness];
		#end
	}
}

class ColorSwapShader extends flixel.system.FlxAssets.FlxShader {
	@:glFragmentSourceFile('./sourceShaders/ColorSwap.frag')
	public function new()
	{
		super();
	}
}