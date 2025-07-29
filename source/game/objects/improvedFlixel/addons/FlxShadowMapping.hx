package game.objects.improvedFlixel.addons;

import flixel.FlxCamera;
import flixel.group.FlxGroup;
import flixel.math.FlxPoint;
import flixel.system.FlxAssets.FlxShader;
import flixel.util.FlxDestroyUtil;

import openfl.display.BitmapData;
import openfl.display.ShaderInput;
import openfl.display.ShaderParameter;

// TODO
@:access(openfl.display.ShaderParameter)
class FlxShadowMapping extends FlxObject
{
	public var collisions:FlxGroup = new FlxGroup();
	public var cameraRenderer:FlxCamera;
	public var shadowShader:FlxShader;
	public var outputSize:FlxPoint = null;

	public var lightPoint:FlxObject = new FlxObject();

	@:noCompletion var __lightPoint:ShaderParameter<Float> = null;
	@:noCompletion var _dirtyShadow:Bool;

	@:noCompletion
	override function initVars():Void
	{
		super.initVars();
		_dirtyShadow = true;
	}

	public override function update(elapsed:Float):Void
	{
		if (lightPoint != null)
		{
			lightPoint.update(elapsed);
			if (!_dirtyShadow)
			{
				_dirtyShadow = lightPoint.last.x != lightPoint.x || lightPoint.last.y != lightPoint.y;
			}
		}
		super.update(elapsed);
	}
	public override function draw():Void
	{
		renderShadow();
		super.draw();
	}

	public function renderShadow():Void
	{
		if (!_dirtyShadow || shadowShader == null || __lightPoint == null) return;

		_dirtyShadow = false;
	}

	function searchShaderInputs():Void {
		this.__lightPoint = null;
		if (shadowShader == null)
			return;

		var __lightPoint:ShaderParameter<Float> = shadowShader.data.field("lightPoint");
		if (__lightPoint != null && __lightPoint.__isUniform && __lightPoint.type == FLOAT2)
			this.__lightPoint = __lightPoint;

	}

	function updateShaderLightPosition():Void {
		if (__lightPoint == null || lightPoint == null) return;
		lightPoint.getScreenPosition(_point, cameraRenderer);
		__lightPoint.value = [_point.x / cameraRenderer.width, _point.y / cameraRenderer.height];
	}

	public override function destroy():Void
	{
		super.destroy();

		__lightPoint = null;

		cameraRenderer = null; // FlxDestroyUtil.destroy(cameraRenderer);
		lightPoint = FlxDestroyUtil.destroy(lightPoint);
		collisions = FlxDestroyUtil.destroy(collisions);
		outputSize = FlxDestroyUtil.put(outputSize);
	}
}