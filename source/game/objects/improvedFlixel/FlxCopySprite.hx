package game.objects.improvedFlixel;

import openfl.geom.Matrix;

import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxFrame.FlxFrameAngle;
import flixel.math.FlxAngle;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.util.FlxDestroyUtil;

class FlxCopySprite extends FlxSprite
{
	public var copiedSprite:FlxSprite;

	public var skew(default, null):FlxPoint = FlxPoint.get();

	public var transformMatrix(default, null):Matrix = new Matrix();

	public var matrixExposed:Bool = true;

	var _skewMatrix:Matrix = new Matrix();

	public function new(x:Float, y:Float, sprite:FlxSprite){
		super(x, y);
		copiedSprite = sprite;
		flipX = sprite.flipX;
		flipY = sprite.flipY;
	}

	@:noCompletion
	override function drawSimple(camera:FlxCamera):Void{
		getScreenPosition(_point, camera).subtractPoint(offset);
		if (isPixelPerfectRender(camera))
			_point.floor();

		_point.copyToFlash(_flashPoint);
		@:privateAccess
		camera.copyPixels(copiedSprite._frame, copiedSprite.framePixels, _flashRect, _flashPoint, colorTransform, blend, antialiasing);
	}

	@:noCompletion
	override function drawComplex(camera:FlxCamera):Void{
		copiedSprite._frame.prepareMatrix(_matrix, FlxFrameAngle.ANGLE_0, checkFlipX(), checkFlipY());
		_matrix.translate(-copiedSprite.origin.x, -copiedSprite.origin.y);
		_matrix.translate(-origin.x, -origin.y);
		_matrix.scale(copiedSprite.scale.x, copiedSprite.scale.y);
		_matrix.scale(scale.x, scale.y);

		if (matrixExposed)
		{
			_matrix.concat(transformMatrix);
		}
		else
		{
			if (bakedRotationAngle <= 0)
			{
				updateTrig();

				if (angle != 0) _matrix.rotateWithTrig(_cosAngle, _sinAngle);
			}

			updateSkewMatrix();
			_matrix.concat(_skewMatrix);
		}

		getScreenPosition(_point, camera).subtractPoint(copiedSprite.offset).subtractPoint(offset);
		_point.add(copiedSprite.origin.x, copiedSprite.origin.y);
		_point.add(origin.x, origin.y);
		_matrix.translate(_point.x, _point.y);

		if (isPixelPerfectRender(camera))
		{
			_matrix.tx = Math.ffloor(_matrix.tx);
			_matrix.ty = Math.ffloor(_matrix.ty);
		}
		@:privateAccess
		camera.drawPixels(copiedSprite._frame, copiedSprite.framePixels, _matrix, colorTransform, blend, antialiasing, shader);
	}

	function updateSkewMatrix():Void{
		_skewMatrix.identity();

		if (skew.x == 0 && skew.y == 0)
			return;
		_skewMatrix.b = Math.tan(skew.y * FlxAngle.TO_RAD);
		_skewMatrix.c = Math.tan(skew.x * FlxAngle.TO_RAD);
	}

	public override function isSimpleRender(?camera:FlxCamera):Bool{
		if (FlxG.renderBlit)
			return super.isSimpleRender(camera) && (skew.x == 0) && (skew.y == 0) && !matrixExposed;
		else
			return false;
	}
	@:access(flixel.FlxCamera)
	override function getBoundingBox(camera:FlxCamera):FlxRect{
		getScreenPosition(_point, camera);

		_rect.set(_point.x, _point.y, copiedSprite.width, copiedSprite.height);
		_rect = camera.transformRect(_rect);

		if (isPixelPerfectRender(camera))
			_rect.floor();

		return _rect;
	}
	public override function getScreenBounds(?newRect:FlxRect, ?camera:FlxCamera):FlxRect{
		if (newRect == null)	newRect = FlxRect.get();
		if (camera == null)		camera = FlxG.camera;

		newRect.setPosition(x, y);
		if (pixelPerfectPosition)
			newRect.floor();
		_scaledOrigin.set(origin.x * scale.x, origin.y * scale.y);
		newRect.x += -Std.int(camera.scroll.x * scrollFactor.x) - offset.x + origin.x - _scaledOrigin.x;
		newRect.y += -Std.int(camera.scroll.y * scrollFactor.y) - offset.y + origin.y - _scaledOrigin.y;
		if (isPixelPerfectRender(camera))
			newRect.floor();
		newRect.setSize(copiedSprite.frameWidth * Math.abs(scale.x), copiedSprite.frameHeight * Math.abs(scale.y));
		return newRect.getRotatedBounds(angle, _scaledOrigin, newRect);
	}

	public override function destroy():Void{
		skew = FlxDestroyUtil.put(skew);
		_skewMatrix = null;
		transformMatrix = null;

		super.destroy();
	}
}