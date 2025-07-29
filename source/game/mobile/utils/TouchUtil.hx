package game.mobile.utils;

import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxObject;
#if TOUCH_CONTROLS
import flixel.input.touch.FlxTouch;
#else
import flixel.input.mouse.FlxMouse;
#end
import flixel.math.FlxPoint;

/**
 * Utility class for handling touch input within the FlxG context.
 */
class TouchUtil
{
	/**
	 * Indicates if any touch is currently pressed.
	 */
	public static var pressed(get, never):Bool;

	/**
	 * Indicates if any touch was just pressed this frame.
	 */
	public static var justPressed(get, never):Bool;

	/**
	 * Indicates if any touch was just released this frame.
	 */
	public static var justReleased(get, never):Bool;

	/**
	 * The first touch in the FlxG.touches list.
	 */
	#if TOUCH_CONTROLS
	public static var touch(get, never):FlxTouch;
	#else
	public static var touch(get, never):FlxMouse;
	#end

	/**
	 * Checks if the specified object overlaps with any active touch.
	 *
	 * @param object The FlxBasic object to check for overlap.
	 * @param camera Optional camera for the overlap check. Defaults to the object's camera.
	 *
	 * @return `true` if there is an overlap with any touch; `false` otherwise.
	 */
	public static function overlaps(object:FlxBasic, ?camera:FlxCamera):Bool
	{
		#if TOUCH_CONTROLS
		if (object == null) return false;

		for (touch in FlxG.touches.list)
		{
			if (touch.overlaps(object, camera ?? object.camera)) return true;
		}
		#end

		return false;
	}

	/**
	 * Checks if the specified object overlaps with any active touch using precise point checks.
	 *
	 * @param object The FlxObject to check for overlap.
	 * @param camera Optional camera for the overlap check. Defaults to all cameras of the object.
	 *
	 * @return `true` if there is a precise overlap with any touch; `false` otherwise.
	 */
	public static function overlapsComplex(object:FlxObject, ?camera:FlxCamera):Bool
	{
		#if TOUCH_CONTROLS

		if (object == null) return false;
		if (camera == null)
		{
			for (camera in object.cameras)
			{
			for (touch in FlxG.touches.list)
			{
				@:privateAccess
				if (object.overlapsPoint(touch.getWorldPosition(camera, object._point), true, camera)) return true;
			}
			}
		}
		else
		{
			@:privateAccess
			if (object.overlapsPoint(touch.getWorldPosition(camera, object._point), true, camera)) return true;
		}
		#end

		return false;
	}

	/**
	 * Checks if the specified object overlaps with a specific point using precise point checks.
	 *
	 * @param object The FlxObject to check for overlap.
	 * @param point The FlxPoint to check against the object.
	 * @param inScreenSpace Whether to take scroll factors into account when checking for overlap.
	 * @param camera Optional camera for the overlap check. Defaults to all cameras of the object.
	 *
	 * @return `true` if there is a precise overlap with the specified point; `false` otherwise.
	 */
	public static function overlapsComplexPoint(object:FlxObject, point:FlxPoint, ?inScreenSpace:Bool = false, ?camera:FlxCamera):Bool
	{
		#if TOUCH_CONTROLS
		if (object == null || point == null) return false;

		if (camera == null)
		{
			for (camera in object.cameras)
			{
			@:privateAccess
			if (object.overlapsPoint(point, inScreenSpace, camera))
			{
				point.putWeak();

				return true;
			}
			}
		}
		else
		{
			@:privateAccess
			if (object.overlapsPoint(point, inScreenSpace, camera))
			{
			point.putWeak();

			return true;
			}
		}
		#end

		point.putWeak();

		return false;
	}

	@:noCompletion
	private static function get_pressed():Bool
	{
		#if TOUCH_CONTROLS
		for (touch in FlxG.touches.list)
		{
			if (touch.pressed) return true;
		}
		#end

		return false;
	}

	@:noCompletion
	private static function get_justPressed():Bool
	{
		#if TOUCH_CONTROLS
		for (touch in FlxG.touches.list)
		{
			if (touch.justPressed) return true;
		}
		#end

		return false;
	}

	@:noCompletion
	private static function get_justReleased():Bool
	{
		#if TOUCH_CONTROLS
		for (touch in FlxG.touches.list)
		{
			if (touch.justReleased) return true;
		}
		#end

		return false;
	}

	@:noCompletion
	#if TOUCH_CONTROLS
	static function get_touch():FlxTouch
	{
		for (touch in FlxG.touches.list)
		{
			if (touch != null) return touch;
		}

		return FlxG.touches.getFirst();
	}
	#else
	static inline function get_touch():FlxMouse
	{
		return FlxG.mouse;
	}
	#end
}