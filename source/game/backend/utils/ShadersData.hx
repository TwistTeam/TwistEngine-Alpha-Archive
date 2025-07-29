package game.backend.utils;

import haxe.ds.Vector;
import flixel.addons.display.FlxRuntimeShader;

class ShadersData
{
	public static var runtimeShaders:Map<String, Vector<String>> = new Map();

	public static function init()
	{
		FlxG.signals.preStateSwitch.add(() -> runtimeShaders.clear());
	}

	public static function createRuntimeShader(name:String, ?customName:String = '', useCache:Bool = true, ?glslVersion:Int = 120):FlxRuntimeShader
	{
		if (!ClientPrefs.shaders)
			return null;
		final shaderName:String = (customName == '' ? name : customName);
		if (runtimeShaders.exists(shaderName) || initShader(name, customName))
		{
			var arr:Vector<String> = runtimeShaders.get(shaderName);
			if (arr.length == 0)
				return null;
			return new FlxRuntimeShader(arr.get(0), arr.get(1));
		}
		FlxG.log.warn('Shader $name is missing!');
		return new FlxRuntimeShader();
	}

	public static function initShader(shaderFile:String = null, ?customName:String = '', useCache:Bool = true):Bool
	{
		if (ClientPrefs.shaders)
		{
			final shaderName:String = (customName == '' ? shaderFile : customName);
			var frag:String = AssetsPaths.fragShader('$shaderFile');
			var vert:String = AssetsPaths.vertShader('$shaderFile');
			final fragFound:Bool = Assets.exists(frag);
			final vertFound:Bool = Assets.exists(vert);
			frag = fragFound ? Assets.getText(frag) : null;
			vert = vertFound ? Assets.getText(vert) : null;

			if (fragFound || vertFound)
			{
				var notArray:Vector<String> = new Vector<String>(2);
				notArray.set(0, frag);
				notArray.set(1, vert);
				runtimeShaders.set(shaderName, notArray);
				return true;
			}

			FlxG.log.warn('Missing shader $shaderFile .frag AND .vert files!');
		}
		return false;
	}
}
