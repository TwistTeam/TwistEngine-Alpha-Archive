package game.objects;

import flixel.FlxCamera;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxFrame;
import flixel.math.FlxMatrix;
import flixel.math.FlxRect;
import flixel.util.FlxArrayUtil;
import game.backend.utils.BitmapDataUtil;
import openfl.display.BitmapData;
import openfl.filters.BitmapFilter;

/**
 * A modified `FlxSprite` that supports filters.
 * The name's pretty much self-explanatory.
 */
@:access(openfl.display.BitmapData)
@:access(openfl.geom.Rectangle)
@:access(openfl.filters.BitmapFilter)
@:access(flixel.graphics.frames.FlxFrame)
class FlxFilteredSprite extends FlxSprite
{
	@:noCompletion var _filterMatrix:FlxMatrix;

	/**
	 * An `Array` of shader filters (aka `BitmapFilter`).
	 */
	public var filters(default, set):Array<BitmapFilter>;

	/**
	 * a flag to update the image with the filters.
	 * Useful when trying to render a shader at all times.
	 */
	public var filterDirty:Bool = false;

	@:noCompletion var filtered:Bool;

	@:noCompletion var _blankFrame:FlxFrame;

	var _filterBmp1:BitmapData;
	var _filterBmp2:BitmapData;

	override public function update(elapsed:Float)
	{
		super.update(elapsed);
		if (!filterDirty && filters != null)
		{
			for (filter in filters)
			{
				if (filter.__renderDirty)
				{
					filterDirty = true;
					break;
				}
			}
		}
	}

	@:noCompletion
	override function initVars():Void
	{
		super.initVars();
		_filterMatrix = new FlxMatrix();
		filters = null;
		filtered = false;
	}

	override public function draw():Void
	{
		checkEmptyFrame();

		if (alpha == 0 || _frame.type == FlxFrameType.EMPTY)
			return;

		if (dirty) // rarely
			calcFrame(useFramePixels);

		if (filterDirty)
			filterFrame();

		for (camera in cameras)
		{
			if (!camera.visible || !camera.exists || !isOnScreen(camera))
				continue;

			getScreenPosition(_point, camera).subtractPoint(offset);

			if (isSimpleRender(camera))
				drawSimple(camera);
			else
				drawComplex(camera);

			#if FLX_DEBUG
			FlxBasic.visibleCount++;
			#end
		}

		#if FLX_DEBUG
		if (FlxG.debugger.drawDebug)
			drawDebug();
		#end
	}

	@:noCompletion
	override function drawComplex(camera:FlxCamera):Void
	{
		_frame.prepareMatrix(_matrix, FlxFrameAngle.ANGLE_0, checkFlipX(), checkFlipY());
		_matrix.concat(_filterMatrix);
		_matrix.translate(-origin.x, -origin.y);
		_matrix.scale(scale.x, scale.y);

		if (bakedRotationAngle <= 0)
		{
			updateTrig();

			if (angle != 0)
				_matrix.rotateWithTrig(_cosAngle, _sinAngle);
		}

		_point.add(origin.x, origin.y);
		_matrix.translate(_point.x, _point.y);

		if (isPixelPerfectRender(camera))
		{
			_matrix.tx = Math.ffloor(_matrix.tx);
			_matrix.ty = Math.ffloor(_matrix.ty);
		}

		camera.drawPixels((filtered) ? _blankFrame : _frame, framePixels, _matrix, colorTransform, blend, antialiasing, shader);
	}

	@:noCompletion
	function filterFrame()
	{
		filterDirty = false;
		_filterMatrix.identity();

		if (filters != null && filters.length > 0)
		{
			_flashRect.setEmpty();

			for (filter in filters)
			{
				_flashRect.__expand(-filter.__leftExtension,
					-filter.__topExtension, filter.__leftExtension
					+ filter.__rightExtension,
					filter.__topExtension
					+ filter.__bottomExtension);
			}
			_flashRect.width += frameWidth;
			_flashRect.height += frameHeight;

			_flashRect.width = Math.floor(_flashRect.width * 1.25);
			_flashRect.height = Math.floor(_flashRect.height * 1.25);

			if (_blankFrame == null)
				_blankFrame = new FlxFrame(null);

			if (_blankFrame.parent == null || _flashRect.width > _blankFrame.parent.width || _flashRect.height > _blankFrame.parent.height)
			{
				disposeBlankFrame();

				_blankFrame.parent = FlxGraphic.fromRectangle(Math.ceil(_flashRect.width), Math.ceil(_flashRect.height), 0, true);
				_filterBmp1 = new BitmapData(_blankFrame.parent.width, _blankFrame.parent.height, 0);
				_filterBmp2 = new BitmapData(_blankFrame.parent.width, _blankFrame.parent.height, 0);
			}
			_blankFrame.offset.copyFrom(_frame.offset);

			var oldClean = BitmapDataUtil.filterRenderer.clearColors;
			BitmapDataUtil.filterRenderer.clearColors = true;
			BitmapDataUtil.filterRenderer.applyFilter(
				frame.parent.bitmap, _blankFrame.parent.bitmap,
				_filterBmp1, _filterBmp2,
				filters, _flashRect, frame.frame.copyToFlash()
			);
			BitmapDataUtil.filterRenderer.clearColors = oldClean;

			_blankFrame.frame = (_blankFrame.frame ?? FlxRect.get()).set(0, 0, _blankFrame.parent.bitmap.width, _blankFrame.parent.bitmap.height);
			_filterMatrix.translate(_flashRect.x, _flashRect.y);
			_frame = _blankFrame.copyTo();
			filtered = true;
		}
		else
		{
			resetFrame();
			filtered = false;
		}
	}

	@:noCompletion
	function set_filters(value:Array<BitmapFilter>)
	{
		if (!FlxArrayUtil.equals(filters, value))
			filterDirty = true;

		return filters = value;
	}

	@:noCompletion
	override function set_frame(value:FlxFrame)
	{
		if (value != frame)
			filterDirty = true;

		return super.set_frame(value);
	}

	override public function destroy()
	{
		super.destroy();
		disposeBlankFrame();
		_blankFrame?.destroy();
		_blankFrame = null;
		_filterBmp1 = null;
		_filterBmp2 = null;
	}

	public function disposeBlankFrame()
	{
		if (_blankFrame == null || _blankFrame.parent == null)
			return;
		_blankFrame.parent.destroy();
		_filterBmp1.__texture?.dispose();
		_filterBmp1.dispose();
		_filterBmp2.__texture?.dispose();
		_filterBmp2.dispose();
	}
}
