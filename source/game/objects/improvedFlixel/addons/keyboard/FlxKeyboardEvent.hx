package game.objects.improvedFlixel.addons.keyboard;

import flixel.input.keyboard.FlxKey;
import flixel.util.FlxDestroyUtil.IFlxDestroyable;

class FlxKeyboardEvent implements IFlxDestroyable
{
	public static var globalManager:FlxKeyboardEventManager;

	public var keyList:Array<FlxKey>;
	public var onPressed:KeyboardEventCallback;
	public var onReleased:KeyboardEventCallback;
	public var onJustPressed:KeyboardEventCallback;
	public var onJustReleased:KeyboardEventCallback;
	public var pressAllKeys:Bool;

	public function new(keyList:Array<FlxKey>, onPressed:KeyboardEventCallback, onJustPressed:KeyboardEventCallback, onReleased:KeyboardEventCallback,
			onJustReleased:KeyboardEventCallback, pressAllKeys:Bool)
	{
		this.keyList = keyList;
		this.onPressed = onPressed;
		this.onReleased = onReleased;
		this.onJustPressed = onJustPressed;
		this.onJustReleased = onJustReleased;
		this.pressAllKeys = pressAllKeys;
	}

	public function destroy()
	{
		keyList = null;
		onPressed = null;
		onReleased = null;
		onJustPressed = null;
		onJustReleased = null;
	}

	/**
	 * Adds the key combination event to `this` registry.
	 *
	 * @param   keyList          List of keys that dispatches this event.
	 * @param   onPressed        Callback when key combination is pressed.
	 * @param   onJustPressed    Callback when key combination was just pressed.
	 * @param   onReleased       Callback when key combination is released.
	 * @param   onJustReleased   Callback when key combination was just released.
	 * @param   pressAllKeys     If true, all keys need to be pressed to trigger `onPressed`
	 *                           and `onJustPressed` callbacks.
	 */
	public static inline function add(keyList:Array<FlxKey>, ?onPressed:KeyboardEventCallback, ?onJustPressed:KeyboardEventCallback, ?onReleased:KeyboardEventCallback,
			?onJustReleased:KeyboardEventCallback, pressAllKeys = true):Void
	{
		globalManager.add(keyList, onPressed, onJustPressed, onReleased, onJustReleased, pressAllKeys);
	}

	/**
	 * Removes the key combination from `this` registry.
	 */
	public static inline function remove(keyList:Array<FlxKey>):Void
	{
		globalManager.remove(keyList);
	}

	/**
	 * Removes all registered key combinations from `this` registry.
	 */
	public static inline function removeAll():Void
	{
		globalManager.removeAll();
	}

	/**
	 * Sets the onPressed callback associated with the key combination.
	 *
	 * @param   onPressed   Callback when the key combination is pressed.
	 *                      Must have key combination list as argument - e.g. `onPressed(keyList:Array<FlxKey>)`.
	 */
	public static inline function setPressedCallback(keyList:Array<FlxKey>, onPressed:KeyboardEventCallback):Void
	{
		globalManager.setPressedCallback(keyList, onPressed);
	}

	/**
	 * Sets the onJustPressed callback associated with the key combination.
	 *
	 * @param   onJustPressed   Callback when the key combination was just pressed.
	 *                          Must have key combination list as argument - e.g. `onJustPressed(keyList:Array<FlxKey>)`.
	 */
	public static inline function setJustPressedCallback(keyList:Array<FlxKey>, onJustPressed:KeyboardEventCallback):Void
	{
		globalManager.setJustPressedCallback(keyList, onJustPressed);
	}

	/**
	 * Sets the onReleased callback associated with the key combination.
	 *
	 * @param   onReleased   Callback when the key combination is released.
	 *                       Must have key combination list as argument - e.g. `onReleased(keyList:Array<FlxKey>)`.
	 */
	public static inline function setReleasedCallback(keyList:Array<FlxKey>, onReleased:KeyboardEventCallback):Void
	{
		globalManager.setReleasedCallback(keyList, onReleased);
	}

	/**
	 * Sets the onJustReleased callback associated with the key combination.
	 *
	 * @param   onJustReleased   Callback when the key combination was just released.
	 *                           Must have key combination list as argument - e.g. `onJustReleased(keyList:Array<FlxKey>)`.
	 */
	public static inline function setJustReleasedCallback(keyList:Array<FlxKey>, onJustReleased:KeyboardEventCallback):Void
	{
		globalManager.setJustReleasedCallback(keyList, onJustReleased);
	}
}

typedef KeyboardEventCallback = (keyList:Array<FlxKey>)->Void;
