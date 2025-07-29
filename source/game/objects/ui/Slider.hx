package game.objects.ui;

import openfl.desktop.Clipboard;
import lime.ui.KeyModifier;
import lime.ui.KeyCode;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.math.FlxRect;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.group.FlxSpriteGroup;
import flixel.util.FlxDestroyUtil;

enum abstract TypeButton(UByte) from UByte to UByte
{
	var HORIZONTAL = 0x0;
	var VERTICAL = 0x1;

	@:to inline function toString():String
	{
		return switch (this)
		{
			case VERTICAL: 'VERTICAL';
			default: 'HORIZONTAL';
		}
	}

	@:from static inline function fromString(s:String):TypeButton
	{
		return switch (s.toLowerCase().trim())
		{
			case 'vertical': VERTICAL;
			default: HORIZONTAL;
		}
	}
}

class Slider extends FlxSpriteGroup implements UIInterface implements IUIFocusable
{
	public var canSelected:Bool = true;
	public var inUIState:Bool = UIState.instance != null;

	static var _curSelectedSlider:Slider;

	public var selected(default, set):Bool = false;

	inline function set_selected(e:Bool):Bool
	{
		if (e != selected)
		{
			if (inUIState)
				UIState.instance.currentFocus = e ? this : null;
			selected = e;
		}
		return e;
	}

	public var flipped:Bool;
	public var type(default, set):TypeButton = VERTICAL;
	public var bg:FlxSprite;
	public var upper:FlxSprite;
	public var curret:FlxSprite;
	public var factor:Float;
	public var min:Float;
	public var max:Float;
	public var decimals:Int;
	public var widthShit:Float;
	public var variable:Float;
	public var onChange:(Float, Float) -> Void;

	public var onSelectedBind:Void->Void;
	public var onStaticBind:Void->Void;
	public var onReleaseBind:Void->Void;
	public var onPressedBind:Void->Void;

	public function new(X:Float, Y:Float, width:Int = 200, height:Int = 50, ?onChange:(Float, Float) -> Void, ?min:Float = 0, ?max:Float = 1,
			?variable:Float = 1, ?decimals:Int = 2, ?type:TypeButton = VERTICAL, ?flipped:Bool = false)
	{
		super();
		x = X;
		y = Y;

		@:bypassAccessor this.type = type;
		this.min = min;
		this.max = max;
		this.variable = variable;
		this.decimals = decimals;
		this.flipped = flipped;
		this.onChange = onChange;
		widthShit = max - min;
		color = 0xff333333;

		bg = new FlxSprite().makeGraphic(width, height, 0xFF181818);
		upper = new FlxSprite().makeGraphic(width, height, 0xffcccccc);
		curret = new FlxSprite().makeGraphic(5, height, 0xffe6e6e6);
		curret.offset.x += curret.width / 2;
		curret.scale.y *= 1.5;
		add(bg);
		add(upper);
		add(curret);

		upper.clipRect = FlxRect.get(0, 0, upper.frameWidth, upper.frameHeight);

		updateSlider((variable - min) / widthShit);

		forEach(spr -> spr.moves = false);
	}

	public var pressed:Bool = false;
	public var mousePoint:FlxPoint = FlxPoint.get();

	public override function update(elapsed:Float):Void
	{
		if (canSelected)
			if (_curSelectedSlider == null || _curSelectedSlider == this)
			{
				if (FlxG.mouse.justReleased && selected && pressed)
				{
					onRelease();
					pressed = false;
				}
				else
				{
					mousePoint = FlxG.mouse.getScreenPosition(camera, mousePoint);
					if (CoolUtil.mouseOverlapping(this, mousePoint) || pressed)
					{
						if (FlxG.mouse.pressed)
						{
							onPressed();
							pressed = true;
							updateSlider(CoolUtil.boundTo(type == VERTICAL ? (mousePoint.x - curret.width / 2 - upper.x) / upper.width : (mousePoint.y
								- upper.y) / upper.height, 0, 1));
						}
						else
						{
							onSelected();
							pressed = false;
						}
					}
					else
					{
						onStatic();
						pressed = false;
					}
				}
			}
		super.update(elapsed);
	}

	extern inline function bindVoid(func:Void->Void)
		if (func != null)
			func();

	public function onSelected()
	{
		selected = true;
		color = 0xffffffff;
		bindVoid(onSelectedBind);
	}

	public function onStatic()
	{
		selected = false;
		color = 0xffbbbbbb;
		bindVoid(onStaticBind);
	}

	public function onRelease()
	{
		onSelected();
		selected = false;
		updateSlider((variable - min) / widthShit);
		_curSelectedSlider = null;
		bindVoid(onReleaseBind);
	}

	public function onPressed()
	{
		selected = true;
		color = 0xffdadada;
		_curSelectedSlider = this;
		bindVoid(onPressedBind);
	}

	public function updateSlider(_factor:Float)
	{
		factor = _factor;

		variable = FlxMath.roundDecimal(min + factor * widthShit, decimals);

		curret.setPosition(upper.x, upper.y);
		upper.clipRect.set(0, 0, upper.frameWidth, upper.frameHeight);
		if (flipped)
		{
			if (type == VERTICAL)
				curret.x += upper.frameWidth - (upper.clipRect.x = upper.frameWidth * factor);
			else
				curret.y += upper.frameHeight - (upper.clipRect.y = upper.frameHeight * factor);
		}
		else
		{
			if (type == VERTICAL)
				curret.x += upper.clipRect.width = upper.frameWidth * factor;
			else
				curret.y += upper.clipRect.height = upper.frameHeight * factor;
		}
		@:bypassAccessor upper.clipRect = upper.clipRect; // :)
		if (onChange != null)
			onChange(variable, factor);
	}

	@:noCompletion inline function set_variable(e:Float)
	{
		variable = e;
		updateSlider((variable - min) / widthShit);
		return variable;
	}

	@:noCompletion inline function set_type(e:TypeButton)
	{
		type = e;
		updateSlider(factor);
		return type;
	}

	@:noCompletion inline function set_max(e:Float)
	{
		max = e;
		widthShit = max - min;
		updateSlider(factor);
		return max;
	}

	@:noCompletion inline function set_min(e:Float)
	{
		min = e;
		widthShit = max - min;
		updateSlider(factor);
		return min;
	}

	public function onTextInput(newText:String):Void
	{
	}

	public function onKeyUp(e:KeyCode, modifier:KeyModifier):Void
	{
	}

	public function onKeyDown(e:KeyCode, modifier:KeyModifier):Void
	{
		switch (e)
		{
			// case LEFT:	changeSelection(-1);
			// case RIGHT:	changeSelection(1);
			// case DOWN | UP:
			// case HOME:	position = 0; 0.2
			// case END:	position = text.length;
			case V:
				if (modifier.ctrlKey)
				{
					// paste
					var str:String = Clipboard.generalClipboard.getData(TEXT_FORMAT);
					if (str == null)
						return;
					str = str.split(';')[0].replace(',', '.'); // fix variable like from Flash or Animate
					var variable:Null<Float> = Std.parseFloat(str);
					if (variable != null && !Math.isNaN(variable))
						updateSlider((variable - min) / widthShit);
				}
			default: // nothing
		}
	}

	public function onTextEdit(text:String, start:Int, end:Int):Void
	{
	}

	public override function destroy()
	{
		onSelectedBind = null;
		onStaticBind = null;
		onReleaseBind = null;
		onPressedBind = null;
		mousePoint = FlxDestroyUtil.put(mousePoint);
		upper.clipRect = FlxDestroyUtil.put(upper.clipRect);
		if (_curSelectedSlider == this)
			_curSelectedSlider = null;
		super.destroy();
	}
}
