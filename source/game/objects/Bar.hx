package game.objects;

import flixel.util.FlxDestroyUtil;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxRect;
import flixel.math.FlxPoint;
import flixel.math.FlxMath;
import flixel.util.helpers.FlxBounds;
import flixel.util.FlxColor;

// Originally modified by RichTrash21
class Bar extends FlxSpriteGroup
{
	public var leftBar:FlxSprite;
	public var rightBar:FlxSprite;
	public var bg:FlxSprite;

	public var bounds:FlxBounds<Float> = new FlxBounds<Float>(0, 1);
	public var percent(default, set):Float = 0.0;
	public var leftToRight(default, set):Bool = false;
	public var smoothFactor(default, set):Float = 0;
	@:noCompletion var lerpFactor:Float = 1;
	@:noCompletion function set_smoothFactor(i:Float):Float
	{
		lerpFactor = FlxMath.bound(i, 1);
		return smoothFactor = FlxMath.bound(i, 0, 1);
	}
	public var smoothMultiply:Float = 25;

	public var barCenter(get, never):Float; // DEPRECATED!!!

	public var centerPoint(default, null):FlxPoint = FlxPoint.get();
	@:noCompletion inline function get_barCenter():Float return centerPoint.x;

	// you might need to change this if you want to use a custom bar
	public var barWidth(default, set):Int = 1;
	public var barHeight(default, set):Int = 1;
	public var barOffset:FlxPoint = FlxPoint.get(3, 3);
	public var flipped(default, set):Bool = false;

	public var valueFunction:() -> Float;
	public var updateCallback:(value:Float, percent:Float) -> Void;

	public function new(x:Float, y:Float, image:String = 'healthBar', valueFunction:Void->Float = null, boundMIN:Float = 0, boundMAX:Float = 1)
	{
		super(x, y);

		this.valueFunction = valueFunction ?? () -> return 0.0;
		setBounds(boundMIN, boundMAX);

		_value = FlxMath.bound(this.valueFunction(), bounds.min, bounds.max);
		percent = FlxMath.remapToRange(_value, bounds.min, bounds.max, 0.0, 100.0);

		bg = new FlxSprite(Paths.image(image));
		barWidth = Std.int(bg.width - 6);
		barHeight = Std.int(bg.height - 6);

		leftBar = new FlxSprite().makeGraphic(Std.int(bg.width), Std.int(bg.height));

		rightBar = new FlxSprite().makeGraphic(Std.int(bg.width), Std.int(bg.height));
		rightBar.color = FlxColor.BLACK;

		leftBar.clipRect = FlxRect.get();
		rightBar.clipRect = FlxRect.get();

		add(leftBar);
		add(rightBar);
		add(bg);
		regenerateClips();
	}

	// internal value tracker
	var _value:Float;
	public function updateValue()
	{
		_value = FlxMath.bound(valueFunction(), bounds.min, bounds.max);
	}
	public override function update(elapsed:Float)
	{
		updateValue();
		percent = FlxMath.lerp(percent, FlxMath.remapToRange(_value, bounds.min, bounds.max, 0, 100),
			FlxMath.bound(FlxMath.lerp(1, smoothMultiply * elapsed / lerpFactor, smoothFactor), 0, 1));
		super.update(elapsed);
	}

	public function setBounds(min:Float = 0, max:Float = 1):FlxBounds<Float> return bounds.set(min, max);

	public function snapPercent()
	{
		updateValue();
		percent = FlxMath.remapToRange(_value, bounds.min, bounds.max, 0, 100);
	}

	public override function destroy()
	{
		bounds = null;
		barOffset = FlxDestroyUtil.put(barOffset);
		centerPoint = FlxDestroyUtil.put(centerPoint);
		if (leftBar != null)
		{
			leftBar.clipRect = FlxDestroyUtil.put(leftBar.clipRect);
			leftBar = null;
		}
		if (rightBar != null)
		{
			rightBar.clipRect = FlxDestroyUtil.put(rightBar.clipRect);
			rightBar = null;
		}
		valueFunction = null;
		updateCallback = null;
		bg = null;
		super.destroy();
	}

	public function flipBar()
	{
		return flipped = !flipped;
	}

	public function setColors(?left:FlxColor, ?right:FlxColor)
	{
		var leftBBar = leftBar;
		var rightBBar = rightBar;
		if (flipped)
		{
			leftBBar = rightBar;
			rightBBar = leftBar;
		}
		if (left != null)	leftBBar.color = left;
		if (right != null)	rightBBar.color = right;
	}

	var leftSize:Float = 0;
	public function updateBar()
	{
		if(leftBar == null || rightBar == null) return;

		leftBar.setPosition(bg.x, bg.y);
		rightBar.setPosition(bg.x, bg.y);

		leftSize = FlxMath.lerp(0, barWidth, (leftToRight ? percent / 100 : 1 - percent / 100));

		leftBar.clipRect.width = leftSize;
		leftBar.clipRect.height = barHeight;
		leftBar.clipRect.x = barOffset.x;
		leftBar.clipRect.y = barOffset.y;

		rightBar.clipRect.width = barWidth - leftSize;
		rightBar.clipRect.height = barHeight;
		rightBar.clipRect.x = barOffset.x + leftSize;
		rightBar.clipRect.y = barOffset.y;

		centerPoint.set(leftBar.x + leftSize + barOffset.x, leftBar.y + leftBar.clipRect.height * 0.5 + barOffset.y);
		if (flipX)
		{
			centerPoint.x = leftBar.x + width - (leftSize + barOffset.x);
		}
		if (flipY)
		{
			centerPoint.y = leftBar.y + height - (leftBar.clipRect.height * 0.5 + barOffset.y);
		}

		// setClipRectToFlxSprite(leftBar, leftBar.clipRect);
		// setClipRectToFlxSprite(rightBar, rightBar.clipRect);
		if (updateCallback != null)
			updateCallback(_value, percent);
	}

	/*
	@:access(flixel.FlxSprite)
	function setClipRectToFlxSprite(spr:FlxSprite, rect:FlxRect):FlxRect
	{
		@:bypassAccessor spr.clipRect = rect;

		if (spr.frames != null)
			spr.frame = spr.frames.frames[spr.animation.frameIndex];

		return rect;
	}
	*/

	public function regenerateClips()
	{
		if (leftBar != null)
		{
			leftBar.setGraphicSize(bg.width, bg.height);
			leftBar.updateHitbox();
		}
		if (rightBar != null)
		{
			rightBar.setGraphicSize(bg.width, bg.height);
			rightBar.updateHitbox();
		}
		updateBar();
	}

	function set_flipped(e)
	{
		if (flipped == e)
			return flipped;
		flipped = e;
		if (leftBar != null && rightBar != null)
		{
			final left = leftBar.color;
			final right = rightBar.color;
			leftToRight = e;
			if (flipped)
			{
				leftBar.color = right;
				rightBar.color = left;
			}
			else
			{
				leftBar.color = right;
				rightBar.color = left;
			}
		}
		return flipped;
	}

	function set_percent(value:Float)
	{
		final doUpdate:Bool = value != percent;
		percent = value;

		if(doUpdate) updateBar();
		return value;
	}

	function set_leftToRight(value:Bool)
	{
		leftToRight = value;
		updateBar();
		return value;
	}

	function set_barWidth(value:Int)
	{
		barWidth = value;
		regenerateClips();
		return value;
	}

	function set_barHeight(value:Int)
	{
		barHeight = value;
		regenerateClips();
		return value;
	}

	@:noCompletion override function set_x(Value:Float):Float // for dynamic center point update
	{
		final prevX:Float = x;
		super.set_x(Value);
		centerPoint.x += Value - prevX;
		return Value;
	}

	@:noCompletion override function set_y(Value:Float):Float
	{
		final prevY:Float = y;
		super.set_y(Value);
		centerPoint.y += Value - prevY;
		return Value;
	}

	@:noCompletion override function set_antialiasing(Antialiasing:Bool):Bool
	{
		if (exists && antialiasing != Antialiasing)
			transformChildren((spr:FlxSprite, val:Bool) -> spr.antialiasing = val, Antialiasing);

		return super.set_antialiasing(Antialiasing);
	}
}