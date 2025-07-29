package flixel.system;

import flixel.FlxBasic;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.util.FlxColor;

class FlxBGSprite extends FlxSprite
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
		for (camera in cameras)
		{
			if (!camera.visible || !camera.exists)
			{
				continue;
			}

			camera.getViewMarginRect(_rect);
			_matrix.setTo(_rect.width, 0, 0, _rect.height, _rect.x, _rect.y);
			// _matrix.setTo(camera.viewWidth, 0, 0, camera.viewHeight, camera.viewMarginLeft, camera.viewMarginTop);
			camera.drawPixels(frame, _matrix, colorTransform);

			#if FLX_DEBUG
			FlxBasic.visibleCount++;
			#end
		}
	}
}
