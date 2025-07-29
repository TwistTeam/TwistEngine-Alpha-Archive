package game.objects.improvedFlixel;

import flixel.util.FlxColor;

class FlxCustomBGSprite extends FlxSprite
{
	public function new()
	{
		super();
		makeGraphic(1, 1, FlxColor.WHITE, true, FlxG.bitmap.getUniqueKey("bg_graphic_"));
		scrollFactor.set();
	}

	/**
	 * Called by game loop, updates then blits or renders current frame of animation to the screen
	 */
	@:access(flixel.FlxCamera)
	public override function draw():Void
	{
		if (alpha == 0.0)
			return;
		for (camera in cameras)
		{
			if (!camera.visible || !camera.exists)
			{
				continue;
			}

			// _frame.prepareMatrix(_matrix, FlxFrameAngle.ANGLE_0, checkFlipX(), checkFlipY());
			camera.getViewMarginRect(_rect);
			_matrix.identity();
			_matrix.scale(_rect.width / frameWidth, _rect.height / frameHeight);
			_matrix.translate(_rect.x, _rect.y);
			camera.drawPixels(frame, _matrix, colorTransform);

			#if FLX_DEBUG
			FlxBasic.visibleCount++;
			#end
		}
	}
}
