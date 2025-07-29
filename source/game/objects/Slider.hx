package game.objects;

import flixel.FlxG;
import flixel.text.FlxText;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxPoint;
import flixel.math.FlxMath;
import openfl.geom.Rectangle;

class Slider extends FlxSpriteGroup
{
	public var targetSpr:FlxSprite = null;
	public var targetOffset:FlxPoint = new FlxPoint();
	public var min:Float;
	public var max:Float;
	public var val(default,set):Float;
	public var onChange:Void->Void = null;
	public var _bg:FlxSprite = new FlxSprite();
	public var _textSpr:FlxText = new FlxText(0, 0, 0, '', 20);
	public var _sliderSprite:FlxSprite = new FlxSprite();

	var border:Int;
	var heightSliderPart:Int;
	var targetWidth:Int;
	var changeValue:Float = 0.01;

	public function new(x:Float, y:Float, _width:Int, _height:Int, ?border:Int = 5, ?min:Float = 0, ?max:Float = 1, ?val:Float = 0.5, ?changeValue:Float = 0.01){
		super(x, y);

		this.min = min;
		this.max = max;
		this.border = border;
		this.changeValue = changeValue;
		this.targetWidth = _width - border * 2;
		this.val = val;

		_bg.makeGraphic(_width, _height, 0xFFFFFFFF);
		_bg.pixels.fillRect(new Rectangle(border, border, _bg.width - border * 2, _bg.height - border * 2), 0xFF222222);
		add(_bg);
		this.heightSliderPart = border * 3;
		_textSpr.width = _width - border * 2;
		_textSpr.x = border * 2;
		_textSpr.setFormat('', 20, 0xFFFFFFFF, RIGHT);

		_sliderSprite.makeGraphic(10, _height + heightSliderPart * 2, 0xFFFFFFFF);
		add(_sliderSprite);
		_sliderSprite.y = -heightSliderPart + y;
		add(_textSpr);
		setPos();
	}
	override function update(elapsed:Float)
	{
		if (targetSpr != null)
		{
			x = targetSpr.x + targetOffset.x;
			y = targetSpr.y + targetOffset.y;
		}
		if (FlxG.mouse.pressed && FlxG.mouse.justMoved
			&& (
				(FlxG.mouse.x > x - 20 && FlxG.mouse.y > y)
				&& (FlxG.mouse.x < x + _bg.width + 20 && FlxG.mouse.y < y + _bg.height)
				)
			)
			updateSliderPosition();
	}
	public function set_val(newVal:Dynamic):Dynamic{
		val = newVal;
		setPos();
		return newVal;
	}
	public function updateSliderPosition(){
		var oldVal = val;
		val = ((max - min) / changeValue);
		val = Math.ffloor(
			CoolUtil.boundTo((FlxG.mouse.x - x - border) / targetWidth, 0, 1) // find 0...1 value
					* val) / val;
		val = FlxMath.lerp(min, max, val);
		if (oldVal != val){
			trace('Value: $val');
			setPos();
			if (onChange != null) onChange();
		}
	}
	public function setPos() _sliderSprite.x = x + ((val - min) / (max - min)) * targetWidth - _sliderSprite.width / 2 + border;
}