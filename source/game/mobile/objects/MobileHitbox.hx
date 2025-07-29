package game.mobile.objects;

#if TOUCH_CONTROLS
import game.objects.FunkinSprite;
import game.objects.improvedFlixel.FlxCamera;
import game.backend.utils.CoolUtil;
import game.backend.utils.Controls;
import game.states.playstate.PlayState;

import flixel.input.touch.FlxTouch;
import flixel.graphics.FlxGraphic;
import flixel.group.FlxSpriteGroup;
import flixel.util.FlxColor;
import flixel.math.FlxPoint;
import flixel.FlxG;

import openfl.display.BitmapData;
import openfl.display.Shape;
import openfl.geom.Matrix;

enum abstract HintStatus(Int) from Int to Int
{
	var RELEASED = 0;
	var PRESSED = 1;
}

class MobileHint extends FunkinSprite
{
	// 0 - Released | 1 - Pressed
	static final HINT_ALPHA:Array<Float> = [0.00001, 0.3];

	public var ignoreZone:Array<FunkinSprite> = [];

	public var currentTouch:FlxTouch;

	public var status:HintStatus = HintStatus.RELEASED;

	public var noteIndex:Int;

	public function new(x:Float = 0, y:Float = 0, width:Int, height:Int, color:FlxColor, noteIndex:Int):Void
	{
		super(x, y);

		this.alpha = HINT_ALPHA[1];
		this.noteIndex = noteIndex;
		this.loadGraphic(createHintGraphic(width, height, color));
	}

	public override function update(elapsed:Float):Void
	{
		super.update(elapsed);

		handleTouch();

		this.alpha = CoolUtil.fpsLerp(this.alpha, HINT_ALPHA[status], 0.3, elapsed);
	}

	private function handleTouch():Void
	{
		final overlaps:Bool = checkOverlap();

		if (currentTouch == null) return;

		if (currentTouch.justReleased)
		{
			performRelease();
		}

		if (status == HintStatus.PRESSED && !overlaps)
		{
			performRelease(true);
		}
	}

	private function checkOverlap():Bool
	{
		for (camera in cameras)
		{
			for (touch in FlxG.touches.list)
			{
				final worldPos:FlxPoint = touch.getWorldPosition(camera, this._point);

				for (object in ignoreZone)
				{
					final ignoredWorldPos:FlxPoint = touch.getWorldPosition(camera, object._point);

					if (overlapsPoint(ignoredWorldPos, true, camera))
						return false;
				}

				if (overlapsPoint(worldPos, true, camera))
				{
					handleStatus(touch);

					return true;
				}
			}
		}

		return false;
	}

	private function handleStatus(touch:FlxTouch):Void
	{
		if (touch != null && (touch.justPressed || (touch.pressed && status == HintStatus.RELEASED)))
		{
			currentTouch = touch;

			performPress();
		}
	}

	private function performPress():Void
	{
		this.status = HintStatus.PRESSED;

		handleInput(this.noteIndex);

		trace("pressed hint");
	}

	private function performRelease(out:Bool = false):Void
	{
		if (!out) currentTouch = null;

		this.status = HintStatus.RELEASED;

		handleInput(this.noteIndex, true);

		trace("released hint");
	}

	// Taken from https://github.com/FunkinDroidTeam/Funkin/blob/develop/source/funkin/mobile/ui/FunkinHitbox.hx
	// - sector
	private function createHintGraphic(width:Int, height:Int, color:FlxColor = 0xFFFFFFFF):FlxGraphic
	{
		var matrix:Matrix = new Matrix();
		matrix.createGradientBox(width, height, 0, 0, 0);

		var shape:Shape = new Shape();
		shape.graphics.beginGradientFill(RADIAL, [color, color], [0, 1], [60, 255], matrix, PAD, RGB, 0);
		shape.graphics.drawRect(0, 0, width, height);
		shape.graphics.endFill();

		var graphicData:BitmapData = new BitmapData(width, height, true, 0);
		graphicData.draw(shape, true);
		return FlxGraphic.fromBitmapData(graphicData, false, null, false);
	}

	@:access(game.states.playstate.PlayState)
	private static function handleInput(noteIndex:Int, shouldRelease:Bool = false):Void
	{
		if (PlayState.instance == null || Controls.instance == null) return;

		var bind:Array<Int> = Controls.instance.keyboardBinds.get(PlayState.instance.keysArray[noteIndex]);
		var key:Int = PlayState.getKeyFromEvent(PlayState.instance.keysArray, bind[0]);
		if (shouldRelease)
			PlayState.instance.keyReleased(key);
		else
			PlayState.instance.keyPressed(key);
	}
}

class MobileHitbox extends FlxTypedSpriteGroup<MobileHint>
{
	static final NOTE_COLORS:Array<FlxColor> = [FlxColor.PURPLE, FlxColor.CYAN, FlxColor.LIME, FlxColor.RED];

	var hintWidth:Int = Math.floor(FlxG.width / 4);

	public function new(x:Float = 0, y:Float = 0)
	{
		super(x, y);

		createHitbox();
	}

	private function createHitbox():Void
	{
		for (i in 0...4)
		{
			final hint:MobileHint = new MobileHint(hintWidth * i, 0, hintWidth, FlxG.height, NOTE_COLORS[i], i);
			add(hint);
		}
	}
}
#end