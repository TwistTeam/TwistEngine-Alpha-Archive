package game.objects.improvedFlixel;

import openfl.display.BitmapData;
import openfl.events.FocusEvent;
import openfl.events.KeyboardEvent;
import openfl.events.MouseEvent;
import openfl.geom.Rectangle;
import openfl.filters.BitmapFilter;

import flixel.FlxG;
import flixel.graphics.frames.FlxFrame;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.util.FlxDestroyUtil;

@:access(openfl.filters.BitmapFilter)
@:access(openfl.geom.Rectangle)
@:access(openfl.text._internal.TextEngine)
@:access(openfl.text.TextField)
class FlxFixedText extends FlxText
{
	public var graphicPadding(default, set):Float = 1;
	public var useFilters(default, set):Bool = true;
	// public var gpuRender:Bool = false;

	public var filters(default, set):Array<BitmapFilter>; // TODO: Remade styles to filters

	// @:noCompletion var _lastGraphicWidthOffset:Int = 0;
	// @:noCompletion var _lastGraphicHeightOffset:Int = 0;

	public function new(X:Float = 0, Y:Float = 0, FieldWidth:Float = 0, ?Text:String, Size:Int = 8, EmbeddedFont:Bool = true)
	{
		_oldGraphicTextRect = new Rectangle();
		_oldGraphicTextRect.setTo(0, 0, 0, 0);
		super(X, Y, FieldWidth, Text, Size, EmbeddedFont);
		// textField.removeEventListeners();
	}

	override function set_borderSize(Value:Float):Float
	{
		if (borderStyle != NONE)
		{
			if (graphicPadding < Value)
				graphicPadding = Value;
			if (!FlxMath.equal(Value, borderSize))
				_regen = true;
		}

		return borderSize = Value;
	}

	function set_graphicPadding(Value:Float):Float
	{
		if (!FlxMath.equal(Value, graphicPadding))
			_regen = true;

		return graphicPadding = Value;
	}

	/**
	 * Internal, reused frequently during drawing and animating.
	 */
	@:noCompletion
	var _oldGraphicTextRect:Rectangle;

	override function regenGraphic():Void
	{
		if (textField == null || !_regen)
			return;

		_flashRect.setEmpty();
		if (filters != null && useFilters)
		{
			for (filter in filters)
			{
				filter.__renderDirty = false;
				_flashRect.__expand(-filter.__leftExtension, -filter.__topExtension,
					filter.__leftExtension + filter.__rightExtension,
					filter.__topExtension + filter.__bottomExtension);
			}
		}

		var newHeight:Int = Math.ceil(_autoHeight ? textField.textHeight + FlxText.VERTICAL_GUTTER : textField.height);
		_flashRect.inflate(graphicPadding, graphicPadding);

		_flashRect.width += textField.width;
		_flashRect.height += newHeight;

		if (!_flashRect.equals(_oldGraphicTextRect))
		{
			// trace(_flashRect);
			_oldGraphicTextRect.copyFrom(_flashRect);
			// Need to generate a new buffer to store the text graphic
			final key:String = FlxG.bitmap.getUniqueKey("text");
			makeGraphic(Math.floor(_oldGraphicTextRect.width), Math.floor(_oldGraphicTextRect.height), FlxColor.TRANSPARENT, false, key);
			frame.offset.set(Math.floor(_oldGraphicTextRect.x), Math.floor(_oldGraphicTextRect.y));

			graphic.bitmap.useCashedDraw = false;
			// @:privateAccess graphic.bitmap.readable = !gpuRender;

			if (_hasBorderAlpha)
			{
				FlxDestroyUtil.dispose(_borderPixels);
				_borderPixels = graphic.bitmap.clone();
			}
			frameWidth = Math.floor(textField.width);
			frameHeight = newHeight;
			width = frameWidth * scale.x;
			height = frameHeight * scale.y;

			if (_autoHeight)
				textField.height = newHeight;

			// _halfSize.set(0.5 * frameWidth, 0.5 * frameHeight);
		}
		else // Else just clear the old buffer before redrawing the text
		{
			// trace(_flashRect);
			// @:privateAccess graphic.bitmap.readable = !gpuRender;
			graphic.bitmap.fillRect(graphic.bitmap.rect, FlxColor.TRANSPARENT);
			if (_hasBorderAlpha)
			{
				if (_borderPixels == null)
					_borderPixels = new BitmapData(frameWidth, frameHeight, true);
				else
					_borderPixels.fillRect(_borderPixels.rect, FlxColor.TRANSPARENT);
			}
		}

		if (textField != null && textField.text != null)
		{
			// Now that we've cleared a buffer, we need to actually render the text to it
			copyTextFormat(_defaultFormat, _formatAdjusted);

			_matrix.identity();
			_matrix.translate(Math.floor(-_oldGraphicTextRect.x), Math.floor(-_oldGraphicTextRect.y));

			applyBorderStyle();
			applyBorderTransparency();
			applyFormats(_formatAdjusted, false);

			drawTextFieldTo(graphic.bitmap);
		}

		_regen = false;
		resetFrame();
	}
	override function drawTextFieldTo(graphic:BitmapData):Void
	{
		#if flash
		if (alignment == FlxTextAlign.CENTER && isTextBlurry())
		{
			var h:Int = 0;
			var tx:Float = _matrix.tx;
			for (i in 0...textField.numLines)
			{
				var lineMetrics = textField.getLineMetrics(i);

				// Workaround for blurry lines caused by non-integer x positions on flash
				var diff:Float = lineMetrics.x - Std.int(lineMetrics.x);
				if (diff != 0)
				{
					_matrix.tx = tx + diff;
				}
				_textFieldRect.setTo(0, h, textField.width, lineMetrics.height + lineMetrics.descent);

				graphic.draw(textField, _matrix, null, null, _textFieldRect, false);

				_matrix.tx = tx;
				h += Std.int(lineMetrics.height);
			}

			return;
		}
		#end
		#if !web
		// Fix to render desktop and mobile text in the same visual location as web
		_matrix.translate(-1, -1); // left and up
		graphic.draw(textField, _matrix);
		_matrix.translate(1, 1); // return to center
		#else
		graphic.draw(textField, _matrix);
		#end
	}

	public override function destroy()
	{
		_oldGraphicTextRect = null;
		super.destroy();
	}

	public override function update(elapsed:Float)
	{
		if (!_regen && useFilters && filters != null)
		{
			for (filter in filters)
			{
				if (filter.__renderDirty)
				{
					_regen = true;
					break;
				}
			}
		}
		super.update(elapsed);
	}

	function set_filters(newFilters:Array<BitmapFilter>):Array<BitmapFilter>
	{
		_regen = true;
		filters = newFilters;
		return textField == null || !useFilters ? null : textField.filters = filters;
	}
	function set_useFilters(a:Bool):Bool
	{
		if (useFilters != a)
		{
			_regen = true;
			textField.filters = a ? filters : null;
		}
		return useFilters = a;
	}

	/*
	@:noCompletion
	override function set_frame(Value:FlxFrame):FlxFrame
	{
		frame = Value;
		if (frame != null)
		{
			if (frame != null)
			{
				// frameWidth = Std.int(frame.sourceSize.x);
				// frameHeight = Std.int(frame.sourceSize.y);
				frameWidth = Std.int(frame.sourceSize.x) - _lastGraphicWidthOffset;
				frameHeight = Std.int(frame.sourceSize.y) - _lastGraphicHeightOffset;
			}
			_halfSize.set(0.5 * frameWidth, 0.5 * frameHeight);
			resetSize();
			dirty = true;
		}
		else if (frames != null && frames.frames != null && numFrames > 0)
		{
			frame = frames.frames[0];
			dirty = true;
		}
		else
		{
			return null;
		}

		if (FlxG.renderTile)
		{
			_frameGraphic = FlxDestroyUtil.destroy(_frameGraphic);
		}

		if (clipRect != null)
		{
			_frame = frame.clipTo(clipRect, _frame);
		}
		else
		{
			_frame = frame.copyTo(_frame);
		}

		return frame;
	}
	*/
}