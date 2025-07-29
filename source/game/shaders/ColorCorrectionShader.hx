package game.shaders;

import openfl.display.ShaderParameter;
import flixel.addons.display.FlxRuntimeShader;

class ColorCorrectionShader extends FlxRuntimeShader
{
	public var brightness(get, set):Float;
	public var gamma(get, set):Float;
	public var contrast(get, set):Float;
	public var saturation(get, set):Float;

	var isaturation:ShaderParameter<Float> = null;
	var icontrast:ShaderParameter<Float> = null;
	var igamma:ShaderParameter<Float> = null;
	var ibrightness:ShaderParameter<Float> = null;

	public function new(?shaderFile:String):Void
	{
		var path = AssetsPaths.fragShader(shaderFile ?? "engine/colorCorrection");
		super(Assets.exists(path) ? Assets.getText(path) : null);
	}
	override function __initGL():Void
	{
		if (__glSourceDirty || __paramBool == null)
		{
			isaturation = null;
			icontrast = null;
			igamma = null;
			ibrightness = null;
		}
		super.__initGL();
	}

	public function updateByClientPrefs()
	{
		#if COLOR_CORRECTION_ALLOWED
		set(
			ClientPrefs.brightness,
			ClientPrefs.gamma,
			ClientPrefs.contrast,
			ClientPrefs.saturation,
		);
		#else
		set(
			1.0,
			1.0,
			1.0,
			1.0,
		);
		#end
	}
	public function set(brightness:Float, gamma:Float, contrast:Float, saturation:Float) {
		this.brightness = brightness;
		this.gamma = gamma;
		this.contrast = contrast;
		this.saturation = saturation;
	}

	function get_saturation():Float
	{
		return isaturation?.value[0] ?? 1.0;
	}

	function get_gamma():Float
	{
		return igamma?.value[0] ?? 1.0;
	}

	function get_contrast():Float
	{
		return icontrast?.value[0] ?? 1.0;
	}

	function get_brightness():Float
	{
		return ibrightness?.value[0] ?? 1.0;
	}

	function set_gamma(value:Float):Float
	{
		if (igamma != null)
			igamma.value[0] = value;
		return value;
	}

	function set_saturation(value:Float):Float
	{
		if (isaturation != null)
			isaturation.value[0] = value;
		return value;
	}

	function set_contrast(value:Float):Float
	{
		if (icontrast != null)
			icontrast.value[0] = value;
		return value;
	}

	function set_brightness(value:Float):Float
	{
		if (ibrightness != null)
			ibrightness.value[0] = value;
		return value;
	}
}
