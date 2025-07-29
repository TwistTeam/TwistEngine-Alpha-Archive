package game.objects;

import flixel.FlxCamera;
import flixel.math.FlxRect;
import flixel.math.FlxPoint;
import flixel.system.FlxAssets.FlxGraphicAsset;
import flixel.graphics.frames.FlxFrame.FlxFrameAngle;
import flixel.util.FlxDestroyUtil;

import openfl.geom.Matrix;

enum Direction
{
	HORIZONTAL;
	VERTICAL;
	NULL;
}

class ParallaxSprite extends FlxSprite
{
	public var pointOne:FlxObject = new FlxObject();
	public var pointTwo:FlxObject = new FlxObject();
	var _bufferOne:FlxPoint = FlxPoint.get();
	var _bufferTwo:FlxPoint = FlxPoint.get();

	/** An enum instance that determines what transformations are made to the sprite.
	 * @param HORIZONTAL    typically for ceilings and floors. Skews on the x axis, scales on the y axis.
	 * @param VERTICAL      typically for walls and backdrops. Scales on the x axis, skews on the y axis.
	 * @param NULL          unintallized value. Not to be confused with bools `scales` and `skews`
	**/
	public var direction:Direction = Direction.NULL;

	/**
	 * Creates a ParallaxSprite at specified position with a specified graphic.
	 * @param graphic		The graphic to load (uses haxeflixel's default if null)
	 * @param   X			The ParallaxSprite's initial X position.
	 * @param   Y			The ParllaxSprite's initial Y position.
	 */
	public function new(x:Float = 0, y:Float = 0, graphic:FlxGraphicAsset)
	{
		super(x, y, graphic);
		origin.set(0, 0);
	}

	/**
	 * Sets the sprites skew factors, direction.
	 * These can be set independently but may lead to unexpected behaivor.
	 * @param anchor		the camera's scroll where the sprite appears unchanged.
	 * @param scrollOne		the scroll factors of the first point.
	 * @param scrollTwo		the scroll factors of the second point.
	 * @param direction		the sprite's direction, which determines the skew.
	 * @param horizontal	typically for ceilings and floors. Skews on the x axis, scales on the y axis.
	 * @param vertical		typically for walls and backdrops. Scales on the x axis, skews on the y axis.
	**/
	public function fixate(anchorX:Float = 0, anchorY:Float = 0, scrollOneX:Float = 1, scrollOneY:Float = 1, scrollTwoX:Float = 1.1, scrollTwoY:Float = 1.1,
			?direct:String):ParallaxSprite
	{
		anchorX += x;
		anchorY += y;
		pointOne.setPosition(anchorX, anchorY);

		switch (direct?.toLowerCase()){
			case null | 'horizontal' | 'orizzontale' | 'horisontell' | "h":
				direction = HORIZONTAL;
				pointTwo.setPosition(anchorX, anchorY + frameHeight);
			case 'vertical' | 'vertikale' | 'verticale' | 'vertikal' | "v":
				direction = VERTICAL;
				pointTwo.setPosition(anchorX + frameWidth, anchorY);
			// default: pointTwo.setPosition(pointOne.x, pointOne.y);
		}
		scrollFactor.set(scrollOneX, scrollOneY);
		pointOne.scrollFactor.set(scrollOneX, scrollOneY);
		pointTwo.scrollFactor.set(scrollTwoX, scrollTwoY);
		return this;
	}

	public override function getScreenBounds(?newRect:FlxRect, ?camera:FlxCamera):FlxRect
	{
		if (newRect == null) newRect = FlxRect.get();
		if (camera == null) camera = FlxG.camera;

		pointOne.getScreenPosition(_bufferOne, camera);
		pointTwo.getScreenPosition(_bufferTwo, camera);

		newRect.x = x - camera.scroll.x * scrollFactor.x;
		newRect.y = y - camera.scroll.y * scrollFactor.y;

		newRect.width = frameWidth;
		newRect.height = frameHeight;

		if (isPixelPerfectRender(camera)) newRect.floor();

		return newRect.getRotatedBounds(angle, _scaledOrigin, newRect);
	}

	public override function destroy():Void
	{
		pointOne = FlxDestroyUtil.destroy(pointOne);
		pointTwo = FlxDestroyUtil.destroy(pointTwo);
		_bufferOne.put();
		_bufferTwo.put();
		direction = null;
		super.destroy();
	}

	@:noCompletion
	override function drawComplex(camera:FlxCamera):Void
	{
		_frame.prepareMatrix(_matrix, 0, checkFlipX(), checkFlipY());

		switch direction
		{
			case HORIZONTAL:
				_matrix.c = (_bufferTwo.x - _bufferOne.x) / frameHeight;
				_matrix.d = (_bufferTwo.y - _bufferOne.y) / frameHeight;
			case VERTICAL:
				_matrix.a = (_bufferTwo.x - _bufferOne.x) / frameWidth;
				_matrix.b = (_bufferTwo.y - _bufferOne.y) / frameWidth;
			default:
		}

		if (bakedRotationAngle <= 0)
		{
			updateTrig();

			if (angle != 0)
				_matrix.rotateWithTrig(_cosAngle, _sinAngle);
		}

		getScreenPosition(_point, camera).subtractPoint(offset);
		_matrix.tx += _point.x;
		_matrix.ty += _point.y;

		_matrix.scale(scale.x, scale.y);

		if (isPixelPerfectRender(camera))
		{
			_matrix.tx = Math.ffloor(_matrix.tx);
			_matrix.ty = Math.ffloor(_matrix.ty);
		}

		camera.drawPixels(_frame, framePixels, _matrix, colorTransform, blend, antialiasing, shader);
	}

	public override function isSimpleRender(?camera:FlxCamera):Bool
		return super.isSimpleRender(camera) && _matrix.c == 0 && _matrix.b == 0;
}