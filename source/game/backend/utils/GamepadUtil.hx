package game.backend.utils;

import flixel.FlxG;
import flixel.input.gamepad.FlxGamepad;

class GamepadUtil
{
	public static function init()
	{
		FlxG.gamepads.deviceConnected.add(connetedGamepad ->		Log('Connected: ${Std.string(connetedGamepad)}', GREEN));
		FlxG.gamepads.deviceDisconnected.add(disconnetedGamepad ->	Log('Disconnected: ${Std.string(disconnetedGamepad)}', RED));
	}

	public static function doVibrate(milliseconds:Float = 250, intensity:Int = 100)
	{
		// lime.ui.Haptic.vibrate(intensity, Math.ceil(milliseconds)); // only works on phones, fuck | TODO
	}
}