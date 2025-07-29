package game.objects.improvedFlixel;

class FlxBGSprite extends flixel.system.FlxBGSprite
{
	/**
	 * Called by game loop, updates then blits or renders current frame of animation to the screen
	 */
	@:access(flixel.FlxCamera)
	public override function draw():Void
	{
		checkEmptyFrame();
		if (alpha == 0.0 || _frame.type == flixel.graphics.frames.FlxFrame.FlxFrameType.EMPTY)
			return;

		if (dirty) // rarely
			calcFrame(useFramePixels);

		for (camera in cameras)
		{
			if (!camera.visible || !camera.exists)
			{
				continue;
			}

			// _matrix.identity();
			_frame.prepareMatrix(_matrix, flixel.graphics.frames.FlxFrame.FlxFrameAngle.ANGLE_0, checkFlipX(), checkFlipY());

			camera.getViewMarginRect(_rect);

			_matrix.scale(_rect.width / frameWidth, _rect.height / frameHeight);
			_matrix.translate(_rect.x, _rect.y);
			_matrix.translate(-offset.x, -offset.y);

			camera.drawPixels(_frame, _matrix, colorTransform, blend, antialiasing, shader);

			#if FLX_DEBUG
			FlxBasic.visibleCount++;
			#end
		}
	}
}
