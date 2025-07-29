package game.backend.utils;

import flixel.input.gamepad.FlxGamepadInputID;
import flixel.input.keyboard.FlxKey;
import flixel.input.FlxInput.FlxInputState;

// TODO: Android pads support
class Controls
{
	//Keeping same use cases on stuff for it to be easier to understand/use
	//I'd have removed it but this makes it a lot less annoying to use in my opinion

	//You do NOT have to create these variables/getters for adding new keys,
	//but you will instead have to use:
	//   controls.justPressed("ui_up")   instead of   controls.UI_UP

	//Dumb but easily usable code, or Smart but complicated? Your choice.
	//Also idk how to use macros they're weird as fuck lol

	// Pressed buttons (directions)
	public var UI_UP_P(get, never):Bool;
	public var UI_DOWN_P(get, never):Bool;
	public var UI_LEFT_P(get, never):Bool;
	public var UI_RIGHT_P(get, never):Bool;
	public var NOTE_UP_P(get, never):Bool;
	public var NOTE_DOWN_P(get, never):Bool;
	public var NOTE_LEFT_P(get, never):Bool;
	public var NOTE_RIGHT_P(get, never):Bool;

	// Held buttons (directions)
	public var UI_UP(get, never):Bool;
	public var UI_DOWN(get, never):Bool;
	public var UI_LEFT(get, never):Bool;
	public var UI_RIGHT(get, never):Bool;
	public var NOTE_UP(get, never):Bool;
	public var NOTE_DOWN(get, never):Bool;
	public var NOTE_LEFT(get, never):Bool;
	public var NOTE_RIGHT(get, never):Bool;

	// Released buttons (directions)
	public var UI_UP_R(get, never):Bool;
	public var UI_DOWN_R(get, never):Bool;
	public var UI_LEFT_R(get, never):Bool;
	public var UI_RIGHT_R(get, never):Bool;
	public var NOTE_UP_R(get, never):Bool;
	public var NOTE_DOWN_R(get, never):Bool;
	public var NOTE_LEFT_R(get, never):Bool;
	public var NOTE_RIGHT_R(get, never):Bool;

	// Pressed buttons (others)
	public var ACCEPT(get, never):Bool;
	public var BACK(get, never):Bool;
	public var PAUSE(get, never):Bool;
	public var RESET(get, never):Bool;

	// Released buttons (others)
	public var ACCEPT_R(get, never):Bool;
	public var BACK_R(get, never):Bool;
	public var PAUSE_R(get, never):Bool;
	public var RESET_R(get, never):Bool;

	// Any button
	public var ANY(get, never):Bool;
	public var ANY_P(get, never):Bool;
	public var ANY_R(get, never):Bool;

	// Debug buttons
	public var DEBUG_1(get, never):Bool;
	public var DEBUG_2(get, never):Bool;

	#if DEV_BUILD
	// Special debug buttons
	public var DEBUG_SKIP_SONG(get, never):Bool;
	public var DEBUG_SKIP_TIME(get, never):Bool;
	public var DEBUG_SPEED_UP(get, never):Bool;
	public var DEBUG_SPEED_UP_R(get, never):Bool;
	public var DEBUG_FREEZE(get, never):Bool;
	public var DEBUG_BOTPLAY(get, never):Bool;
	public var DEBUG_TOOGLE_HUD(get, never):Bool;
	#end

	//Gamepad & Keyboard stuff
	public var keyboardBinds:Map<String, Array<FlxKey>>;
	public var gamepadBinds:Map<String, Array<FlxGamepadInputID>>;
	public var controllerMode:Bool = false;

	public inline function justPressed(key:String):Bool
		return __inputHelper(key, FlxG.keys.anyJustPressed, _myGamepadJustPressed);

	public inline function pressed(key:String):Bool
		return __inputHelper(key, FlxG.keys.anyPressed, _myGamepadPressed);

	public inline function justReleased(key:String):Bool
		return __inputHelper(key, FlxG.keys.anyJustReleased, _myGamepadJustReleased);

	inline function _myGamepadJustPressed(keys:Array<FlxGamepadInputID>):Bool
		return __gamepadHelper(keys, FlxG.gamepads.anyJustPressed);

	inline function _myGamepadPressed(keys:Array<FlxGamepadInputID>):Bool
		return __gamepadHelper(keys, FlxG.gamepads.anyPressed);

	inline function _myGamepadJustReleased(keys:Array<FlxGamepadInputID>):Bool
		return __gamepadHelper(keys, FlxG.gamepads.anyJustReleased);

	@:noCompletion
	function __inputHelper(key:String, keysBindsFunction:Array<FlxKey>->Bool, gamepadBindsFunction:Array<FlxGamepadInputID>->Bool):Bool
	{
		if (keysBindsFunction(keyboardBinds[key]))
		{
			controllerMode = false;
			return true;
		}
		return gamepadBindsFunction(gamepadBinds[key]);
	}

	@:noCompletion
	function __gamepadHelper(keys:Array<FlxGamepadInputID>, f:FlxGamepadInputID->Bool):Bool
	{
		if (keys != null)
			for (key in keys)
				if (f(key))
					return controllerMode = true;

		return false;
	}

	@:noCompletion
	function __anyInputHelper(state:FlxInputState):Bool
	{
		if (FlxG.keys.checkStatus(FlxKey.ANY, state))
		{
			controllerMode = false;
			return true;
		}
		else if (FlxG.gamepads.anyButton(state))
		{
			controllerMode = true;
			return true;
		}
		return false;
	}

	inline function get_UI_UP_P()		return justPressed("ui_up");
	inline function get_UI_DOWN_P()		return justPressed("ui_down");
	inline function get_UI_LEFT_P()		return justPressed("ui_left");
	inline function get_UI_RIGHT_P()	return justPressed("ui_right");
	inline function get_NOTE_UP_P()		return justPressed("4K_note_up");
	inline function get_NOTE_DOWN_P()	return justPressed("4K_note_down");
	inline function get_NOTE_LEFT_P()	return justPressed("4K_note_left");
	inline function get_NOTE_RIGHT_P()	return justPressed("4K_note_right");

	inline function get_UI_UP()			return pressed("ui_up");
	inline function get_UI_DOWN()		return pressed("ui_down");
	inline function get_UI_LEFT()		return pressed("ui_left");
	inline function get_UI_RIGHT()		return pressed("ui_right");
	inline function get_NOTE_UP()		return pressed("4K_note_up");
	inline function get_NOTE_DOWN()		return pressed("4K_note_down");
	inline function get_NOTE_LEFT()		return pressed("4K_note_left");
	inline function get_NOTE_RIGHT()	return pressed("4K_note_right");

	inline function get_UI_UP_R()		return justReleased("ui_up");
	inline function get_UI_DOWN_R()		return justReleased("ui_down");
	inline function get_UI_LEFT_R()		return justReleased("ui_left");
	inline function get_UI_RIGHT_R()	return justReleased("ui_right");
	inline function get_NOTE_UP_R()		return justReleased("4K_note_up");
	inline function get_NOTE_DOWN_R()	return justReleased("4K_note_down");
	inline function get_NOTE_LEFT_R()	return justReleased("4K_note_left");
	inline function get_NOTE_RIGHT_R()	return justReleased("4K_note_right");

	inline function get_ACCEPT()		return justPressed("accept");
	inline function get_BACK()			return justPressed("back");
	inline function get_PAUSE()			return justPressed("pause");
	inline function get_RESET()			return justPressed("reset");

	inline function get_ACCEPT_R()		return justReleased("accept");
	inline function get_BACK_R()		return justReleased("back");
	inline function get_PAUSE_R()		return justReleased("pause");
	inline function get_RESET_R()		return justReleased("reset");

	inline function get_ANY()			return __anyInputHelper(JUST_PRESSED);
	inline function get_ANY_P()			return __anyInputHelper(PRESSED);
	inline function get_ANY_R()			return __anyInputHelper(RELEASED);

	inline function get_DEBUG_1()		return justPressed("debug_1");
	inline function get_DEBUG_2()		return justPressed("debug_2");

	#if DEV_BUILD
	inline function get_DEBUG_SKIP_SONG()		return justPressed("debug_skipSong");
	inline function get_DEBUG_SKIP_TIME()		return justPressed("debug_skipTime");
	inline function get_DEBUG_SPEED_UP()		return justPressed("debug_speedUp");
	inline function get_DEBUG_SPEED_UP_R()		return justReleased("debug_speedUp");
	inline function get_DEBUG_FREEZE()			return justPressed("debug_freeze");
	inline function get_DEBUG_BOTPLAY()			return justPressed("debug_botplay");
	inline function get_DEBUG_TOOGLE_HUD()		return justPressed("debug_toogleHUD");
	#end

	// IGNORE THESE
	public static var instance:Controls; // MAIN CONTROLS
	public function new(?keyBinds:Map<String, Array<FlxKey>>, ?gamepadBinds:Map<String, Array<FlxGamepadInputID>>)
	{
		this.keyboardBinds = keyBinds == null ? ClientPrefs.keyBinds : keyBinds;
		this.gamepadBinds = gamepadBinds == null ? ClientPrefs.gamepadBinds : gamepadBinds;
	}
}