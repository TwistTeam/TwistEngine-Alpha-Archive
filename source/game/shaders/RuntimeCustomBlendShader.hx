package game.shaders;

import flixel.addons.display.FlxRuntimeShader;

import openfl.display.BitmapData;
import openfl.display.BlendMode;
import openfl.display.ShaderInput;
import openfl.display.ShaderParameter;
import openfl.utils.Assets;

class RuntimeCustomBlendShader extends FlxRuntimeShader
{
	public var listAvailableBlends(default, null):Array<BlendMode> = [];

	// only different name purely for hashlink fix
	public var blendSource(get, set):BitmapData;

	function get_blendSource():BitmapData
	{
		return iBlendSource?.input;
	}
	function set_blendSource(value:BitmapData):BitmapData
	{
		if (iBlendSource != null)
		{
			iBlendSource.input = value;
		}
		return value;
	}

	// name change make sure it's not the same variable name as whatever is in the shader file
	public var blendSwag(default, set):BlendMode;

	function get_blendSwag():BlendMode
	{
		return iBlendMode == null || iBlendMode.value == null ? null : cast iBlendMode.value[0];
	}
	function set_blendSwag(value:BlendMode):BlendMode
	{
		if (iBlendMode != null)
		{
			if (iBlendMode.value == null)
				iBlendMode.value = [cast value];
			else
				iBlendMode.value[0] = cast value;
		}
		return value;
	}

	var iBlendSource:ShaderInput<BitmapData>;
	var iBlendMode:ShaderParameter<Int>;

	public function new(?path:String)
	{
		path ??= AssetsPaths.fragShader("engine/customBlend");
		super(Assets.exists(path) ? Assets.getText(path) : null, null, null);
	}

	@:access(openfl.display.BlendMode)
	public override function __initGL():Void
	{
		var dirty = __glSourceDirty || __paramBool == null;
		if (dirty)
		{
			iBlendSource = null;
			iBlendMode = null;
			listAvailableBlends.clear();
		}

		super.__initGL();

		if (dirty)
		{
			var lastPosition, name;

			var regex = new EReg("[^\\/	 ]const int BLMODE_([A-Za-z_]+)", "");

			var lastMatch:UInt = 0;

			while (regex.matchSub(glFragmentSource, lastMatch))
			{
				name = regex.matched(1);

				listAvailableBlends.push(BlendMode.fromString(name.toLowerCase()));
				// trace(name);

				lastPosition = regex.matchedPos();
				lastMatch = lastPosition.pos + lastPosition.len;
			}
			// trace(listAvailableBlends);
			if(listAvailableBlends.contains(BlendMode.NORMAL))
				listAvailableBlends.push(null);
		}
	}

	/*
	public function updateFrameInfo(frame:FlxFrame)
	{
		// NOTE: uv.width is actually the right pos and uv.height is the bottom pos
		uFrameBounds.value = [frame.uv.x, frame.uv.y, frame.uv.width, frame.uv.height];
	}
	*/
}