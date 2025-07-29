package game.objects.openfl;

import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.tweens.misc.AngleTween;
import flixel.tweens.misc.ColorTween;
import flixel.tweens.misc.NumTween;
import flixel.tweens.misc.ShakeTween;
import flixel.tweens.misc.VarTween;
import flixel.tweens.motion.CircularMotion;
import flixel.tweens.motion.CubicMotion;
import flixel.tweens.motion.LinearMotion;
import flixel.tweens.motion.LinearPath;
import flixel.tweens.motion.QuadMotion;
import flixel.tweens.motion.QuadPath;
import flixel.util.FlxArrayUtil;
import flixel.util.FlxAxes;
import flixel.util.FlxColor;
import flixel.util.FlxDestroyUtil.IFlxDestroyable;
import openfl.display.Stage;
import openfl.events.Event;

@:access(flixel.tweens)
@:access(flixel.tweens.FlxTween)
class FlxGlobalTween
{
	/**
	 * The global tweening manager that handles global tweens
	 * @since 4.2.0
	 */
	// public static var globalManager:FlxGlobalTweenManager;
	public static var globalManager:FlxTweenManager;

	/**
	 * Tweens numeric public properties of an Object. Shorthand for creating a VarTween, starting it and adding it to the TweenManager.
	 *
	 * ```haxe
	 * FlxTween.tween(Object, { x: 500, y: 350, "scale.x": 2 }, 2.0, { ease: easeFunction, onStart: onStart, onUpdate: onUpdate, onComplete: onComplete, type: ONESHOT });
	 * ```
	 *
	 * @param	Object		The object containing the properties to tween.
	 * @param	Values		An object containing key/value pairs of properties and target values.
	 * @param	Duration	Duration of the tween in seconds.
	 * @param	Options		A structure with tween options.
	 * @return	The added VarTween object.
	 */
	public static function tween(Object:Dynamic, Values:Dynamic, Duration:Float = 1, ?Options:TweenOptions):VarTween
	{
		return globalManager.tween(Object, Values, Duration, Options);
	}

	/**
	 * Tweens some numeric value. Shorthand for creating a NumTween, starting it and adding it to the TweenManager. Using it in
	 * conjunction with a TweenFunction requires more setup, but is faster than VarTween because it doesn't use Reflection.
	 *
	 * ```haxe
	 * function tweenFunction(s:FlxSprite, v:Float) { s.alpha = v; }
	 * FlxTween.num(1, 0, 2.0, { ease: easeFunction, onStart: onStart, onUpdate: onUpdate, onComplete: onComplete, type: ONESHOT }, tweenFunction.bind(mySprite));
	 * ```
	 *
	 * Trivia: For historical reasons, you can use either onUpdate or TweenFunction to accomplish the same thing, but TweenFunction
	 * gives you the updated Float as a direct argument.
	 *
	 * @param	FromValue	Start value.
	 * @param	ToValue		End value.
	 * @param	Duration	Duration of the tween.
	 * @param	Options		A structure with tween options.
	 * @param	TweenFunction	A function to be called when the tweened value updates.  It is recommended not to use an anonymous
	 *							function if you are maximizing performance, as those will be compiled to Dynamics on cpp.
	 * @return	The added NumTween object.
	 */
	public static function num(FromValue:Float, ToValue:Float, Duration:Float = 1, ?Options:TweenOptions, ?TweenFunction:Float->Void):NumTween
	{
		return globalManager.num(FromValue, ToValue, Duration, Options, TweenFunction);
	}

	/**
	 * A simple shake effect for FlxSprite. Shorthand for creating a ShakeTween, starting it and adding it to the TweenManager.
	 *
	 * ```haxe
	 * FlxTween.shake(Sprite, 0.1, 2, FlxAxes.XY, { ease: easeFunction, onStart: onStart, onUpdate: onUpdate, onComplete: onComplete, type: ONESHOT });
	 * ```
	 *
	 * @param	Sprite       Sprite to shake.
	 * @param   Intensity    Percentage representing the maximum distance
	 *                       that the sprite can move while shaking.
	 * @param   Duration     The length in seconds that the shaking effect should last.
	 * @param   Axes         On what axes to shake. Default value is `FlxAxes.XY` / both.
	 * @param	Options      A structure with tween options.
	 * @return The added ShakeTween object.
	 */
	public static function shake(Sprite:FlxSprite, Intensity:Float = 0.05, Duration:Float = 1, ?Axes:FlxAxes = XY, ?Options:TweenOptions):ShakeTween
	{
		return globalManager.shake(Sprite, Intensity, Duration, Axes, Options);
	}

	/**
	 * Tweens numeric value which represents angle. Shorthand for creating a AngleTween object, starting it and adding it to the TweenManager.
	 *
	 * ```haxe
	 * FlxTween.angle(Sprite, -90, 90, 2.0, { ease: easeFunction, onStart: onStart, onUpdate: onUpdate, onComplete: onComplete, type: ONESHOT });
	 * ```
	 *
	 * @param	Sprite		Optional Sprite whose angle should be tweened.
	 * @param	FromAngle	Start angle.
	 * @param	ToAngle		End angle.
	 * @param	Duration	Duration of the tween.
	 * @param	Options		A structure with tween options.
	 * @return	The added AngleTween object.
	 */
	public static function angle(?Sprite:FlxSprite, FromAngle:Float, ToAngle:Float, Duration:Float = 1, ?Options:TweenOptions):AngleTween
	{
		return globalManager.angle(Sprite, FromAngle, ToAngle, Duration, Options);
	}

	/**
	 * Tweens numeric value which represents color. Shorthand for creating a ColorTween object, starting it and adding it to a TweenPlugin.
	 *
	 * ```haxe
	 * FlxTween.color(Sprite, 2.0, 0x000000, 0xffffff, 0.0, 1.0, { ease: easeFunction, onStart: onStart, onUpdate: onUpdate, onComplete: onComplete, type: ONESHOT });
	 * ```
	 *
	 * @param	Sprite		Optional Sprite whose color should be tweened.
	 * @param	Duration	Duration of the tween in seconds.
	 * @param	FromColor	Start color.
	 * @param	ToColor		End color.
	 * @param	Options		A structure with tween options.
	 * @return	The added ColorTween object.
	 */
	public static function color(?Sprite:FlxSprite, Duration:Float = 1, FromColor:FlxColor, ToColor:FlxColor, ?Options:TweenOptions):ColorTween
	{
		return globalManager.color(Sprite, Duration, FromColor, ToColor, Options);
	}

	/**
	 * Create a new LinearMotion tween.
	 *
	 * ```haxe
	 * FlxTween.linearMotion(Object, 0, 0, 500, 20, 5, false, { ease: easeFunction, onStart: onStart, onUpdate: onUpdate, onComplete: onComplete, type: ONESHOT });
	 * ```
	 *
	 * @param	Object			The object to move (FlxObject or FlxSpriteGroup)
	 * @param	FromX			X start.
	 * @param	FromY			Y start.
	 * @param	ToX				X finish.
	 * @param	ToY				Y finish.
	 * @param	DurationOrSpeed	Duration (in seconds) or speed of the movement.
	 * @param	UseDuration		Whether to use the previous param as duration or speed.
	 * @param	Options			A structure with tween options.
	 * @return The LinearMotion object.
	 */
	public static function linearMotion(Object:FlxObject, FromX:Float, FromY:Float, ToX:Float, ToY:Float, DurationOrSpeed:Float = 1, UseDuration:Bool = true,
			?Options:TweenOptions):LinearMotion
	{
		return globalManager.linearMotion(Object, FromX, FromY, ToX, ToY, DurationOrSpeed, UseDuration, Options);
	}

	/**
	 * Create a new QuadMotion tween.
	 *
	 * ```haxe
	 * FlxTween.quadMotion(Object, 0, 100, 300, 500, 100, 2, 5, false, { ease: easeFunction, onStart: onStart, onUpdate: onUpdate, onComplete: onComplete, type: ONESHOT });
	 * ```
	 *
	 * @param	Object			The object to move (FlxObject or FlxSpriteGroup)
	 * @param	FromX			X start.
	 * @param	FromY			Y start.
	 * @param	ControlX		X control, used to determine the curve.
	 * @param	ControlY		Y control, used to determine the curve.
	 * @param	ToX				X finish.
	 * @param	ToY				Y finish.
	 * @param	DurationOrSpeed	Duration (in seconds) or speed of the movement.
	 * @param	UseDuration		Whether to use the previous param as duration or speed.
	 * @param	Options			A structure with tween options.
	 * @return The QuadMotion object.
	 */
	public static function quadMotion(Object:FlxObject, FromX:Float, FromY:Float, ControlX:Float, ControlY:Float, ToX:Float, ToY:Float,
			DurationOrSpeed:Float = 1, UseDuration:Bool = true, ?Options:TweenOptions):QuadMotion
	{
		return globalManager.quadMotion(Object, FromX, FromY, ControlX, ControlY, ToX, ToY, DurationOrSpeed, UseDuration, Options);
	}

	/**
	 * Create a new CubicMotion tween.
	 *
	 * ```haxe
	 * FlxTween.cubicMotion(_sprite, 0, 0, 500, 100, 400, 200, 100, 100, 2, { ease: easeFunction, onStart: onStart, onUpdate: onUpdate, onComplete: onComplete, type: ONESHOT });
	 * ```
	 *
	 * @param	Object 		The object to move (FlxObject or FlxSpriteGroup)
	 * @param	FromX		X start.
	 * @param	FromY		Y start.
	 * @param	aX			First control x.
	 * @param	aY			First control y.
	 * @param	bX			Second control x.
	 * @param	bY			Second control y.
	 * @param	ToX			X finish.
	 * @param	ToY			Y finish.
	 * @param	Duration	Duration of the movement in seconds.
	 * @param	Options		A structure with tween options.
	 * @return The CubicMotion object.
	 */
	public static function cubicMotion(Object:FlxObject, FromX:Float, FromY:Float, aX:Float, aY:Float, bX:Float, bY:Float, ToX:Float, ToY:Float,
			Duration:Float = 1, ?Options:TweenOptions):CubicMotion
	{
		return globalManager.cubicMotion(Object, FromX, FromY, aX, aY, bX, bY, ToX, ToY, Duration, Options);
	}

	/**
	 * Create a new CircularMotion tween.
	 *
	 * ```haxe
	 * FlxTween.circularMotion(Object, 250, 250, 50, 0, true, 2, true, { ease: easeFunction, onStart: onStart, onUpdate: onUpdate, onComplete: onComplete, type: ONESHOT });
	 * ```
	 *
	 * @param	Object			The object to move (FlxObject or FlxSpriteGroup)
	 * @param	CenterX			X position of the circle's center.
	 * @param	CenterY			Y position of the circle's center.
	 * @param	Radius			Radius of the circle.
	 * @param	Angle			Starting position on the circle.
	 * @param	Clockwise		If the motion is clockwise.
	 * @param	DurationOrSpeed	Duration of the movement in seconds.
	 * @param	UseDuration		Duration of the movement.
	 * @param	Ease			Optional easer function.
	 * @param	Options			A structure with tween options.
	 * @return The CircularMotion object.
	 */
	public static function circularMotion(Object:FlxObject, CenterX:Float, CenterY:Float, Radius:Float, Angle:Float, Clockwise:Bool,
			DurationOrSpeed:Float = 1, UseDuration:Bool = true, ?Options:TweenOptions):CircularMotion
	{
		return globalManager.circularMotion(Object, CenterX, CenterY, Radius, Angle, Clockwise, DurationOrSpeed, UseDuration, Options);
	}

	/**
	 * Create a new LinearPath tween.
	 *
	 * ```haxe
	 * FlxTween.linearPath(Object, [FlxPoint.get(0, 0), FlxPoint.get(100, 100)], 2, true, { ease: easeFunction, onStart: onStart, onUpdate: onUpdate, onComplete: onComplete, type: ONESHOT });
	 * ```
	 *
	 * @param	Object 			The object to move (FlxObject or FlxSpriteGroup)
	 * @param	Points			An array of at least 2 FlxPoints defining the path
	 * @param	DurationOrSpeed	Duration (in seconds) or speed of the movement.
	 * @param	UseDuration		Whether to use the previous param as duration or speed.
	 * @param	Options			A structure with tween options.
	 * @return	The LinearPath object.
	 */
	public static function linearPath(Object:FlxObject, Points:Array<FlxPoint>, DurationOrSpeed:Float = 1, UseDuration:Bool = true,
			?Options:TweenOptions):LinearPath
	{
		return globalManager.linearPath(Object, Points, DurationOrSpeed, UseDuration, Options);
	}

	/**
	 * Create a new QuadPath tween.
	 *
	 * ```haxe
	 * FlxTween.quadPath(Object, [FlxPoint.get(0, 0), FlxPoint.get(200, 200), FlxPoint.get(400, 0)], 2, true, { ease: easeFunction, onStart: onStart, onUpdate: onUpdate, onComplete: onComplete, type: ONESHOT });
	 * ```
	 *
	 * @param	Object			The object to move (FlxObject or FlxSpriteGroup)
	 * @param	Points			An array of at least 3 FlxPoints defining the path
	 * @param	DurationOrSpeed	Duration (in seconds) or speed of the movement.
	 * @param	UseDuration		Whether to use the previous param as duration or speed.
	 * @param	Options			A structure with tween options.
	 * @return	The QuadPath object.
	 */
	public static function quadPath(Object:FlxObject, Points:Array<FlxPoint>, DurationOrSpeed:Float = 1, UseDuration:Bool = true,
			?Options:TweenOptions):QuadPath
	{
		return globalManager.quadPath(Object, Points, DurationOrSpeed, UseDuration, Options);
	}

	/**
	 * Cancels all related tweens on the specified object.
	 *
	 * Note: Any tweens with the specified fields are cancelled, if the tween has other properties they
	 * will also be cancelled.
	 *
	 * @param Object The object with tweens to cancel.
	 * @param FieldPaths Optional list of the tween field paths to search for. If null or empty, all tweens on the specified
	 * object are canceled. Allows dot paths to check child properties.
	 *
	 * @since 4.9.0
	 */
	public static function cancelTweensOf(Object:Dynamic, ?FieldPaths:Array<String>):Void
	{
		globalManager.cancelTweensOf(Object, FieldPaths);
	}

	/**
	 * Immediately updates all tweens on the specified object with the specified fields that
	 * are not looping (type `FlxTween.LOOPING` or `FlxTween.PINGPONG`) and `active` through
	 * their endings, triggering their `onComplete` callbacks.
	 *
	 * Note: if they haven't yet begun, this will first trigger their `onStart` callback.
	 *
	 * Note: their `onComplete` callbacks are triggered in the next frame.
	 * To trigger them immediately, call `FlxTween.globalManager.update(0);` after this function.
	 *
	 * In no case should it trigger an `onUpdate` callback.
	 *
	 * Note: Any tweens with the specified fields are completed, if the tween has other properties they
	 * will also be completed.
	 *
	 * @param Object The object with tweens to complete.
	 * @param FieldPaths Optional list of the tween field paths to search for. If null or empty, all tweens on
	 * the specified object are completed. Allows dot paths to check child properties.
	 *
	 * @since 4.9.0
	 */
	public static function completeTweensOf(Object:Dynamic, ?FieldPaths:Array<String>):Void
	{
		globalManager.completeTweensOf(Object, FieldPaths);
	}
}

/*
 *  1017 |  public function shake(Sprite:FlxSprite, Intensity:Float = 0.05, Duration:Float = 1, ?Axes:FlxAxes = XY, ?Options:TweenOptions):ShakeTween
      |                                                                                                      ^^
      | Int should be Null<flixel.util.FlxAxes>

@:access(flixel.tweens)
@:access(flixel.tweens.FlxTween)
class FlxGlobalTweenManager extends FlxTweenManager
{
	var _stage:Stage;

	public function new():Void
	{
		super();
		FlxG.signals.preStateSwitch.remove(clear);
		_stage = FlxG.game.stage;
		if (_stage != null)
			_stage.addEventListener(Event.ENTER_FRAME, __enterFrame);
	}

	public var ticks(default, null):Int = 0;

	var _elapsedMS:Float;
	var _total:Int = 0;

	function __enterFrame(_)
	{
		ticks = getTimer();
		_elapsedMS = ticks - _total;
		_total = ticks;
		update(_elapsedMS / 1000);
	}

	public override function destroy():Void
	{
		super.destroy();
		if (_stage != null)
			_stage.removeEventListener(Event.ENTER_FRAME, __enterFrame);
	}

	dynamic function getTimer():Int
	{
		// expensive, only call if necessary
		return inline openfl.Lib.getTimer();
	}
}
*/