package game.backend.system;

import game.shaders.ColorCorrectionShader;
import game.shaders.GayBoyShader;

import openfl.filters.ColorMatrixFilter;
import openfl.filters.BitmapFilter;
import openfl.filters.ShaderFilter;
import openfl.display.Shader;

class EffectsScreen{
	static final matrix:Map<String, Array<Float>> = [
		"Deuteranopia" => [
				0.43,	0.72,	-0.15,	0,	0,
				0.34,	0.57,	0.09,	0,	0,
				-.02,	0.03,	1,		0,	0,
				0,		0,		0,		1,	0,
			],
		"Protanopia" => [
				0.20,	0.99,	-.19,	0,	0,
				0.16,	0.79,	0.04,	0,	0,
				0.01,	-.01,	1,		0,	0,
				0,		0,		0,		1,	0,
			],
		"Tritanopia" => [
				0.97,	0.11,	-.08,	0,	0,
				0.02,	0.82,	0.16,	0,	0,
				0.06,	0.88,	0.18,	0,	0,
				0,		0,		0,		1,	0,
			],
		"Achromatopsia" => [
				0.2126, 0.7152, 0.0722, 0,	0,
				0.2126, 0.7152, 0.0722, 0,	0,
				0.2126, 0.7152, 0.0722, 0,	0,
				0,      0,      0,		1,	0,
			],
		"Deuteranomaly" => [
				0.8,	0.2,	0,		0,	0,
				0.258,	0.742,	0,		0,	0,
				0,		0.142,	0.858,	0,	0,
				0,		0,		0,		1,	0,
			],
		"Protanomaly" => [
				0.817,	0.183,	0,		0,	0,
				0.333,	0.667,	0,		0,	0,
				0,		0.125,	0.875,	0,	0,
				0,		0,		0,		1,	0,
			],
		"Tritanomaly" => [
				0.967,	0.033,	0,		0,	0,
				0,		0.733,	0.267,	0,	0,
				0,		0.183,	0.817,	0,	0,
				0,    	0,		0,		1,	0,
			],
		"Achromatomaly" => [
				0.618,	0.320,	-0.062,	0,	0,
				0.163,	0.775,	0.062,	0,	0,
				0.163,	0.320,	0.516,	0,	0,
				0,    	0,    	0,		1,	0,
			]
	];

	public static var extraMatrix:Array<BitmapFilter> = [];

	public static var shaders:Array<BitmapFilter> = [];
	public static var extraShaders:Array<BitmapFilter> = [];

	#if COLOR_CORRECTION_ALLOWED
	public static var colorCorrectionShader:ColorCorrectionShader = null;
	#end
	// static var totalFilters:Array<BitmapFilter> = [];

	public static function updateMain()
	{
		var filters:Array<BitmapFilter> = extraMatrix.concat(shaders).concat(extraShaders);
		#if COLOR_CORRECTION_ALLOWED
		if (colorCorrectionShader != null)
		{
			colorCorrectionShader.updateByClientPrefs();
			if (ClientPrefs.allowColorCorrection)
				filters.push(new ShaderFilter(colorCorrectionShader));
		}
		#end
		if (matrix.exists(ClientPrefs.filter))
		{
			filters.push(new ColorMatrixFilter(matrix.get(ClientPrefs.filter)));
		}
		// if (totalFilters != filters){
			// Main.applicationScreen.filtersEnabled = true;
			// totalFilters = filters.copy();
			// trace(filters);
			Main.applicationScreen.stage.filters = filters;
			// trace('Effects Updated.');
		// }
	}
	public static function checkSpecial(){
		// setShaders(new game.shaders.ColorCorrectionShader());

		/*
		switch(ClientPrefs.filter){
			case 'Gameboy':
				setShaders(new GayBoyShader());
			default:
				return false;
		}
		return true;
		*/
		return false;
	}

	public static function resetExtra(){
		extraShaders.clearArray();
		extraMatrix.clearArray();
		updateMain();
	}

	public static function addShaders(?targets:Array<Shader>, ?single:Shader)
	{
		if (ClientPrefs.shaders && (single != null || targets != null))
		{
			if (targets != null)
			{
				for (i in targets) shaders.push(new ShaderFilter(i));
			}
			else
			{
				shaders.push(new ShaderFilter(single));
			}
			updateMain();
		}
	}
	public static function setShaders(?targets:Array<Shader>, ?single:Shader)
	{
		shaders.clearArray();
		if (ClientPrefs.shaders && (single != null || targets != null))
		{
			if (targets != null)
			{
				for (i in targets) shaders.push(new ShaderFilter(i));
			}
			else
			{
				shaders = [new ShaderFilter(single)];
			}
		}
		updateMain();
	}

	public static function addExtraShaders(?targets:Array<Shader>, ?single:Shader)
	{
		if (ClientPrefs.shaders && (single != null || targets != null))
		{
			if(targets != null)
			{
				for (i in targets)
				{
					extraShaders.push(new ShaderFilter(i));
				}
			}
			else
			{
				extraShaders.push(new ShaderFilter(single));
			}
			updateMain();
		}
	}
	public static function setExtraShaders(?targets:Array<Shader>, ?single:Shader)
	{
		extraShaders.clearArray();
		if (ClientPrefs.shaders && (single != null || targets != null)){
			if (targets != null)
			{
				for (i in targets)
					extraShaders.push(new ShaderFilter(i));
			}
			else
			{
				extraShaders = [new ShaderFilter(single)];
			}
		}
		updateMain();
	}

	public static function addExtraMatrix(?name:String)
	{
		if (name != null && matrix.exists(name) && name != ClientPrefs.filter)
		{
			extraMatrix.push(new ColorMatrixFilter(matrix[name]));
			updateMain();
		}
	}
	public static function setExtraMatrix(?name:String)
	{
		extraMatrix.clearArray();
		if (name != null && matrix.exists(name) && name != ClientPrefs.filter)
			extraMatrix = [new ColorMatrixFilter(matrix[name])];
		updateMain();
	}
}
