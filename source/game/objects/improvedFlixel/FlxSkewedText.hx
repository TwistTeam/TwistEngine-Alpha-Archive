package game.objects.improvedFlixel;

import flixel.FlxCamera;
import flixel.math.FlxAngle;
import flixel.math.FlxPoint;
import flixel.util.FlxDestroyUtil;
import game.objects.improvedFlixel.FlxFixedText;

class FlxSkewedText extends FlxFixedText
{
	/**
	 * Skewing factor for x/y axis in degrees.
	 */
	public var skew(default, null):FlxPoint;

	@:noCompletion override function initVars():Void
	{
		super.initVars();
		skew = FlxPoint.get();
	}

	/**
	 * **WARNING:** A destroyed `FlxBasic` can't be used anymore.
	 * It may even cause crashes if it is still part of a group or state.
	 * You may want to use `kill()` instead if you want to disable the object temporarily only and `revive()` it later.
	 *
	 * This function is usually not called manually (Flixel calls it automatically during state switches for all `add()`ed objects).
	 *
	 * Override this function to `null` out variables manually or call `destroy()` on class members if necessary.
	 * Don't forget to call `super.destroy()`!
	 */
	public override function destroy():Void
	{
		skew = FlxDestroyUtil.destroy(skew);
		super.destroy();
	}

	/**
	 * Returns the result of `isSimpleRenderBlit()` if `FlxG.renderBlit` is
	 * `true`, or `false` if `FlxG.renderTile` is `true`.
	 */
	public override function isSimpleRender(?camera:FlxCamera):Bool
	{
		if (FlxG.renderTile)
			return false;

		return isSimpleRenderBlit(camera) && skew.x == 0 && skew.y == 0;
	}

	@:noCompletion override function drawComplex(camera:FlxCamera):Void
	{
		_frame.prepareMatrix(_matrix, 0, checkFlipX(), checkFlipY());
		_matrix.translate(-origin.x, -origin.y);
		_matrix.scale(scale.x, scale.y);

		if (bakedRotationAngle <= 0 && angle != 0)
		{
			updateTrig();
			_matrix.rotateWithTrig(_cosAngle, _sinAngle);
		}

		// skew matrix
		if (skew.x != 0 || skew.y != 0)
		{
			final tanX = -skew.x * FlxAngle.TO_RAD, tanY = skew.y * FlxAngle.TO_RAD;

			final a1 = _matrix.a + _matrix.b * tanX;
			_matrix.b = _matrix.a * tanY + _matrix.b;
			_matrix.a = a1;

			final c1 = _matrix.c + _matrix.d * tanX;
			_matrix.d = _matrix.c * tanY + _matrix.d;
			_matrix.c = c1;

			final tx1 = _matrix.tx + _matrix.ty * tanX;
			_matrix.ty = _matrix.tx * tanY + _matrix.ty;
			_matrix.tx = tx1;
		}

		getScreenPosition(_point, camera).subtractPoint(offset).add(origin.x, origin.y);
		_matrix.translate(_point.x, _point.y);

		if (isPixelPerfectRender(camera))
		{
			_matrix.tx = Math.floor(_matrix.tx);
			_matrix.ty = Math.floor(_matrix.ty);
		}

		camera.drawPixels(_frame, framePixels, _matrix, colorTransform, blend, antialiasing, shader);
	}
}