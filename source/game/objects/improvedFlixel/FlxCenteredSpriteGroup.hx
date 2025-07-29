package game.objects.improvedFlixel;

import flixel.group.FlxSpriteGroup;
import flixel.math.FlxPoint.FlxCallbackPoint;
import flixel.math.FlxPoint;
import flixel.util.FlxDestroyUtil;

typedef FlxCenteredSpriteGroup = FlxTypedCentrSprGr<FlxSprite>;

class FlxTypedCentrSprGr<T:FlxSprite> extends FlxTypedSpriteGroup<T> {
	@:noCompletion var lastOffset = FlxPoint.get();

	override function initVars()
	{
		super.initVars();
		overridePointCallbacks(cast origin, customOriginCallback);
		overridePointCallbacks(cast offset, customOffsetCallback);
	}

	override public function destroy()
	{
		super.destroy();
		lastOffset = FlxDestroyUtil.put(lastOffset);
	}

	public function customCenterOrigin()
	{
		origin.set(width / scale.x / 2.0, height / scale.y / 2.0);
	}

	override public function updateHitbox()
	{
		forEach((spr:FlxSprite) -> {
			spr.updateHitbox();
			spr.offset.addPoint(this.offset);
		});
		customCenterOrigin();
	}

	@:access(flixel.math.FlxCallbackPoint)
	inline function overridePointCallbacks(point:FlxCallbackPoint, callback:FlxPoint->Void)
	{
		point._setXCallback = point._setYCallback = point._setXYCallback = callback;
	}

	inline function customOffsetCallback(offset:FlxPoint)
	{
		if (_skipTransformChildren || group == null)
			return;

		for (sprite in _sprites)
		{
			if (sprite != null)
				customOffsetTransform(sprite, offset, offset.x - lastOffset.x, offset.y - lastOffset.y);
		}
		lastOffset.copyFrom(offset);
	}

	inline function customOffsetTransform(sprite:FlxSprite, ?offset:FlxPoint, deltaX:Float, deltaY:Float)
		sprite.offset.add(deltaX, deltaY);

	inline function customOriginCallback(origin:FlxPoint)
	{
		if (_skipTransformChildren || group == null)
			return;

		for (sprite in _sprites)
		{
			if (sprite != null)
				customOriginTransform(sprite, origin);
		}
	}

	inline function customOriginTransform(sprite:FlxSprite, origin:FlxPoint)
		sprite.origin.set(origin.x - (sprite.x - x), origin.y - (sprite.y - y));
}