package game.shaders;

import flixel.addons.display.FlxRuntimeShader;
import openfl.display.ShaderParameter;
import openfl.display._internal.ShaderBuffer;
import openfl.geom.Point;

@:access(openfl.display.ShaderParameter)
class BloomOptionShader extends FlxRuntimeShader
{
	var brightnessParameter:ShaderParameter<Float> = null;
	var _randArrFactors:Array<Float>;
	var __randArrIndx:Int = 0;
	public function new()
	{
		super(Assets.getText(Paths.shaderFragment('engine/bloomOption')));

		_randArrFactors = [for (i in 0...25) FlxG.random.float(0.8, 1.2)];

		final brightnessName = "ibrightness";
		brightnessParameter = getFloatParameter(brightnessName);
		if (brightnessParameter != null)
		{
			if (brightnessParameter.__length == 1)
			{
				brightnessParameter.value = [1.0];
			}
			else
			{
				trace('[WARN] Invalid \"$brightnessName\" length"');
				brightnessParameter = null;
			}
		}
		else
		{
			trace('[WARN] Invalid \"$brightnessName\"');
		}
		preload();
	}

	public function updateAnim() {
		if (brightnessParameter != null)
		{
			brightnessParameter.value[0] = _getRandomFloat();
		}
	}

	function _getRandomFloat() {
		__randArrIndx = (++__randArrIndx) % _randArrFactors.length;
		return _randArrFactors[__randArrIndx];
	}

}