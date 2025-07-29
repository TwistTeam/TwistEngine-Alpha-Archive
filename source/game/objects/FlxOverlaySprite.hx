package game.objects;

import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxFrame;
import flixel.math.FlxRect;

import openfl.display.BitmapData;
import openfl.filters.BitmapFilter;
import openfl.geom.Rectangle;

import game.backend.utils.BitmapDataUtil;

@:access(flixel.FlxCamera)
@:access(flixel.graphics.FlxGraphic)
@:access(flixel.graphics.frames.FlxFrame)
@:access(game.objects.improvedFlixel.FlxCamera)
@:access(openfl.display.BitmapData)
@:access(openfl.display.DisplayObjectContainer)
@:access(openfl.filters.BitmapFilter)
class FlxOverlaySprite extends game.objects.improvedFlixel.FlxBGSprite
{
	public var useFilters:Bool = true;

	public var filters:Array<BitmapFilter> = [];

	public function new()
	{
		super();
		_frame = new FlxFrame(new FlxGraphic('', null));
		_frame.frame = new FlxRect();
		// makeGraphic(FlxG.width, FlxG.height, FlxColor.TRANSPARENT, true, FlxG.bitmap.getUniqueKey("bg_graphic_camera"));
	}

	/**
	 * Called by game loop, updates then blits or renders current frame of animation to the screen
	 */
	@:access(openfl.geom.Rectangle)
	@:access(flixel.FlxCamera)
	public override function draw():Void
	{
		if (alpha == 0.0)
			return;

		var pixels:BitmapData = null;
		// if (pixels == null)
		// 	return;

		for (camera in cameras)
		{
			if (!camera.visible || !camera.exists)
			{
				continue;
			}

			camera.canvas.__updateTransforms(); // update canvas transforms to fix snap zoom
			inline function getKey() return 'SprOverl${this.ID}';
			pixels = BitmapDataUtil.fromFlxCameraToBitmapData(camera, null, true, false, true, true, getKey());
			if (useFilters)
				BitmapDataUtil.applyFilters(pixels, filters, getKey());

			// if (this.pixels != pixels)
			{
				// this.pixels = pixels;
				_frame.parent.bitmap = pixels;
				_frame.frame.set(0, 0, pixels.width, pixels.height);
			}
			camera.fill(camera.bgColor.to24Bit(), camera.useBgAlphaBlending, camera.bgColor.alphaFloat);
			// updateHitbox();
			// Rectangle.__pool.release(rect);

			var _negativeSinScrollAngle = 0.0, _negativeCosScrollAngle = 1.0;
			if (camera is FlxCamera) // is't improved camera?
			{
				var camera:FlxCamera = cast camera;
				_negativeSinScrollAngle = camera._negativeSinScrollAngle;
				_negativeCosScrollAngle = camera._negativeCosScrollAngle;
			}
			_matrix.identity();
			_matrix.scale(
				camera.viewWidth / pixels.width,
				camera.viewHeight / pixels.height
			);
			// _matrix.scale(1 / pixels.width, 1 / pixels.height);
			if (_negativeSinScrollAngle != 0.0 || _negativeCosScrollAngle != 1.0)
			{
				camera.getFactorOrigin(_point);
				_point.scale(camera.viewWidth, camera.viewHeight);
				_matrix.translate(-_point.x, -_point.y);
				_matrix.rotateWithTrig(_negativeCosScrollAngle, _negativeSinScrollAngle);
				_matrix.translate(_point.x, _point.y);
			}
			_matrix.translate(camera.viewMarginLeft, camera.viewMarginTop);
			camera.drawPixels(_frame, _matrix, colorTransform, blend, antialiasing, shader);

			#if FLX_DEBUG
			FlxBasic.visibleCount++;
			#end
		}
	}
}
