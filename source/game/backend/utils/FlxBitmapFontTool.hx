package game.backend.utils;

import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxBitmapFont;
import flixel.graphics.frames.FlxFrame;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.system.FlxAssets;
import flixel.util.FlxColor;

import openfl.Assets;
import openfl.display.BitmapData;
import openfl.geom.Matrix;
import openfl.geom.Rectangle;
import openfl.text.*;
import openfl.utils.AssetType;

using flixel.util.FlxUnicodeUtil;

@:access(flixel.graphics.frames.FlxBitmapFont)
@:access(flixel.graphics.frames.FlxFrame)
@:access(openfl.geom.Rectangle)
@:access(openfl.text)
class FlxBitmapFontTool
{
	@:isVar static var _textField(get, null):TextField = null;
	static function get__textField():TextField
	{
		if (_textField == null)
		{
			_textField = new TextField();
			_textField.selectable = _textField.mouseEnabled = false;
			_textField.multiline = _textField.wordWrap = _textField.embedFonts = true;
			_textField.sharpness = 100;
			_textField.autoSize = TextFieldAutoSize.LEFT;
			_textField.removeEventListeners();
		}
		return _textField;
	}

	// TODO: Fix in html5
	public static function fromFont(?cl:Class<FlxBitmapFont>, format:TextFormat, ?letters:String, charBGColor:Int = FlxColor.TRANSPARENT):FlxBitmapFont {

		if (letters == null)
			letters = FlxBitmapFont.DEFAULT_CHARS;

		var fontPath = format.font;
		var sourceFont:Font = fontPath == null || !Assets.exists(fontPath, AssetType.FONT) ? null : Assets.getFont(fontPath);
		if (sourceFont == null)
		{
			format.font = fontPath = FlxAssets.FONT_DEFAULT;
			sourceFont = Assets.getFont(fontPath);
		}
		final keyCashe:String = '${AssetsPaths.FLXGRAPHIC_PREFIXKEY}$charBGColor($letters)|FlxBitmapFont\'${format.__toCacheKey()}\'';
		var graphic:FlxGraphic = FlxG.bitmap.get(keyCashe);
		var frame:FlxFrame;
		var font:FlxBitmapFont;
		if (graphic != null)
		{
			frame = graphic.imageFrame.frame;
			font = FlxBitmapFont.findFont(frame);
			if (font != null)
				return font;
		}

		_textField.text = letters;
		if (_textField.textWidth >= FlxG.bitmap.maxTextureSize)
		{
			_textField.width = FlxG.bitmap.maxTextureSize;
		}
		_textField.setTextFormat(_textField.defaultTextFormat = format);

		_textField.width = Math.sqrt(_textField.textWidth * _textField.textHeight); // convert to square format

		var bd:BitmapData = new BitmapData(Std.int(_textField.width), Std.int(_textField.textHeight), true, charBGColor);
		#if !web
		final _matrix = new Matrix();
		// Fix to render desktop and mobile text in the same visual location as web
		_matrix.translate(-1, -1); // left and up
		bd.draw(_textField, _matrix);
		#else
		bd.draw(_textField);
		#end

		graphic = FlxG.bitmap.add(bd, false, keyCashe);
		frame = graphic.imageFrame.frame;

		final letterSpacing:Float = format.letterSpacing ?? 0.0;

		font = new FlxBitmapFont(frame);
		// font.lineHeight = format.size + letterSpacing;
		// font.lineHeight = Std.int(_textField.__textEngine.lineHeights[0]);
		font.lineHeight = Std.int(format.size * 1.2);
		font.size = format.size;
		font.spaceWidth = Std.int(format.size / 2.0);
		font.fontName = fontPath;
		font.bold = format.bold;
		font.italic = format.italic;

		var rect = new Rectangle();
		_textField.__updateLayout();
		for (i in 0..._textField.text.length)
		{
			__getCharBoundaries(_textField, i, rect);
			// rect.inflate(-letterSpacing / 2, -letterSpacing / 2);
			font.addCharFrame(letters.uCharCodeAt(i),
				FlxRect.get().copyFromFlash(rect),
				FlxPoint.get(),
				// FlxPoint.get(-letterSpacing / 2, -letterSpacing / 2),
				Std.int(rect.width - letterSpacing)
			);
		}

		// trace(font.lineHeight, font.size, font.fontName, font.bold, font.italic);

		return font;
	}

	static function __getCharBoundaries(_textField:TextField, charIndex:Int, rect:Rectangle) {
		for (group in _textField.__textEngine.layoutGroups)
		{
			if (charIndex >= group.startIndex && charIndex < group.endIndex)
			{
				try
				{
					var x = group.offsetX;

					for (i in 0...(charIndex - group.startIndex))
					{
						x += group.getAdvance(i);
					}

					// TODO: Is this actually right for combining characters?
					var lastPosition = group.getAdvance(charIndex - group.startIndex);

					rect.setTo(x, group.offsetY, lastPosition, group.ascent + group.descent);
					return true;
				}
				catch(e)
				{
					trace(e);
				}
			}
		}

		return false;
	}
}