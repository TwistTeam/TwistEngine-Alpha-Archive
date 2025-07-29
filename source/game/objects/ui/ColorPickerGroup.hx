package game.objects.ui;

import game.backend.utils.Controls.instance as controls;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.addons.display.shapes.FlxShapeCircle;
import flixel.math.FlxPoint;
import flixel.math.FlxMath;
import flixel.group.FlxSpriteGroup;
import flixel.util.FlxGradient;
import flixel.util.FlxColor;

import lime.system.Clipboard;

class ColorPickerGroup extends FlxSpriteGroup
{
	public var defaultColor:FlxColor = 0xFFFFFFFF;
	public var colorFunc:FlxColor -> Void = _ -> {};
	public var getColorFunc:Void -> FlxColor = () -> return 0xF;

	public var copyButton:FlxSprite;
	public var pasteButton:FlxSprite;

	public var colorGradient:FlxSprite;
	public var colorGradientSelector:FlxSprite;
	public var colorPalette:FlxSprite;
	public var colorWheel:FlxSprite;
	public var colorWheelSelector:FlxSprite;

	public var text:FlxText;

	public function new(?defaultColor:FlxColor, ?setFunc:FlxColor -> Void, ?getFunc:Void -> FlxColor) {
		super();

		if (defaultColor != null) this.defaultColor = defaultColor;
		if (setFunc != null) this.colorFunc = setFunc;
		if (getFunc != null) this.getColorFunc = getFunc;

		colorGradient = FlxGradient.createGradientFlxSprite(60, 180, [FlxColor.WHITE, FlxColor.BLACK]);
		colorGradient.setPosition(0, 0);
		add(colorGradient);

		colorGradientSelector = new FlxSprite(-10, 100).makeGraphic(80, 5, FlxColor.WHITE);
		colorGradientSelector.offset.y = 2.5;
		add(colorGradientSelector);

		colorPalette = new FlxSprite(colorGradient.x, 195, Paths.image('noteColorMenu/palette', false));
		colorPalette.origin.set(0, 0);
		colorPalette.scale.set(15, 15);
		colorPalette.updateHitbox();
		colorPalette.antialiasing = false;
		add(colorPalette);

		colorWheel = new FlxSprite(80, colorGradient.y, Paths.image('noteColorMenu/colorWheel'));
		colorWheel.setGraphicSize(colorGradient.height);
		colorWheel.updateHitbox();
		add(colorWheel);

		colorWheelSelector = new FlxShapeCircle(0, 0, 4, {thickness: 0}, FlxColor.WHITE);
		colorWheelSelector.offset.set(4, 4);
		colorWheelSelector.alpha = 0.6;
		add(colorWheelSelector);

		copyButton = new FlxSprite(0, 270, Paths.image('noteColorMenu/copy'));
		copyButton.alpha = 0.6;
		add(copyButton);

		pasteButton = new FlxSprite(copyButton.x + copyButton.width + 20, copyButton.y, Paths.image('noteColorMenu/paste'));
		pasteButton.alpha = 0.6;
		add(pasteButton);

		text = new FlxText(pasteButton.x + pasteButton.width + 20, pasteButton.y, 0, '');
		text.setFormat(null, 20, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE_FAST, FlxColor.BLACK);
		add(text);

		updateColors();
	}

	var _storedColor:FlxColor;
	var holdingOnObj:FlxSprite;
	public var pressed(get, never):Bool;
	public function get_pressed()return holdingOnObj != null;
	override function update(elapsed:Float) {
		super.update(elapsed);
		// Copy/Paste buttons
		var generalMoved:Bool = FlxG.mouse.justMoved;
		var generalPressed:Bool = FlxG.mouse.justPressed;
		if(generalMoved)
		{
			copyButton.alpha = 0.6;
			pasteButton.alpha = 0.6;
		}

		if(pointerOverlaps(copyButton))
		{
			copyButton.alpha = 1;
			if(generalPressed)
			{
				Clipboard.text = getColor().toHexString(false, false);
				trace('copied: ' + Clipboard.text);
			}
		}
		else if (pointerOverlaps(pasteButton))
		{
			pasteButton.alpha = 1;
			if(generalPressed)
			{
				var formattedText = Clipboard.text.trim().toUpperCase().replace('#', '').replace('0x', '');
				var newColor:Null<FlxColor> = FlxColor.fromString('#' + formattedText);
				//trace('#${Clipboard.text.trim().toUpperCase()}');
				newColor ??= FlxColor.fromString(formattedText);
				if(newColor != null && formattedText.length == 6)
				{
					setColor(newColor);
					_storedColor = getColor();
					updateColors();
				}
			}
		}

		// Click
		if(generalPressed)
		{
			if (pointerOverlaps(colorWheel))
			{
				_storedColor = getColor();
				holdingOnObj = colorWheel;
			}
			else if (pointerOverlaps(colorGradient))
			{
				_storedColor = getColor();
				holdingOnObj = colorGradient;
			}
			else if (pointerOverlaps(colorPalette))
			{
				var a = pointerFlxPoint();
				holdingOnObj = colorPalette;
				setColor(colorPalette.pixels.getPixel32(
					Std.int((a.x - colorPalette.x) / colorPalette.scale.x),
					Std.int((a.y - colorPalette.y) / colorPalette.scale.y)));
				updateColors();
				a.put();
			}
			else
			{
				holdingOnObj = null;
			}
		}
		// holding
		if(holdingOnObj != null)
		{
			if (FlxG.mouse.justReleased || (controls.controllerMode && controls.justReleased('accept')))
			{
				holdingOnObj = null;
				_storedColor = getColor();
				updateColors();
			}
			else if (generalMoved || generalPressed)
			{
				if (holdingOnObj == colorGradient)
				{
					var a = pointerFlxPoint();
					final newBrightness = 1 - FlxMath.bound((a.y - colorGradient.y) / colorGradient.height, 0, 1);
					_storedColor.alpha = 1;
					if(_storedColor.brightness == 0) //prevent bug
						setColor(FlxColor.fromRGBFloat(newBrightness, newBrightness, newBrightness));
					else
						setColor(FlxColor.fromHSB(_storedColor.hue, _storedColor.saturation, newBrightness));
					updateColors(_storedColor);
					a.put();
				}
				else if (holdingOnObj == colorWheel)
				{
					var center:FlxPoint = FlxPoint.get(colorWheel.x + colorWheel.width / 2, colorWheel.y + colorWheel.height / 2);
					var mouse:FlxPoint = pointerFlxPoint();
					final hue:Float = FlxMath.wrap(FlxMath.wrap(Std.int(mouse.degreesTo(center)), 0, 360) - 90, 0, 360);
					final sat:Float = FlxMath.bound(mouse.dist(center) / colorWheel.width * 2, 0, 1);
					//trace('$hue, $sat');
					if(sat != 0) setColor(FlxColor.fromHSB(hue, sat, _storedColor.brightness));
					else setColor(FlxColor.fromRGBFloat(_storedColor.brightness, _storedColor.brightness, _storedColor.brightness));
					updateColors();
					center.put();
					mouse.put();
				}
			}
		}
		else if(controls.RESET)
		{
			setColor(defaultColor);
			updateColors();
		}
	}

	public static function pointerOverlaps(obj:flixel.FlxObject):Bool{
		var point = pointerFlxPoint();
		final result:Bool = (point.x >= obj.x) && (point.x < obj.x + obj.width) && (point.y >= obj.y) && (point.y < obj.y + obj.height);
		point.put();
		return result;
		// return FlxG.mouse.overlaps(obj, CoolUtil.getFrontCamera()); // poopooshiter
	}

	public static inline function pointerFlxPoint():FlxPoint return FlxG.mouse.getScreenPosition(CoolUtil.getFrontCamera());

	public function updateColors(?specific:Null<FlxColor>)
	{
		var color:FlxColor = getColor();
		var wheelColor:FlxColor = specific == null ? color : specific;

		text.text = 'R: ' + color.red + '\nG: ' + color.green + '\nB: ' + color.blue;

		text.color = color;

		colorWheel.color = FlxColor.fromHSB(0, 0, color.brightness);
		colorWheelSelector.setPosition(colorWheel.x + colorWheel.width / 2, colorWheel.y + colorWheel.height / 2);
		if(wheelColor.brightness != 0)
		{
			var hueWrap:Float = wheelColor.hue * Math.PI / 180;
			colorWheelSelector.x += Math.sin(hueWrap) * colorWheel.width / 2 * wheelColor.saturation;
			colorWheelSelector.y -= Math.cos(hueWrap) * colorWheel.height / 2 * wheelColor.saturation;
		}
		if (wheelColor == 0xFF000000) wheelColor = 0xFFFFFFFF;
		colorGradient.color = FlxColor.fromHSB(wheelColor.hue, wheelColor.saturation, 1);
		colorGradientSelector.y = colorGradient.y + colorGradient.height * (1 - color.brightness);
	}

	public function setColor(value:FlxColor) colorFunc(value);
	function getColor() return getColorFunc();
}
