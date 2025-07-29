package game.backend.utils;

import flixel.system.frontEnds.CameraFrontEnd;
import flixel.FlxCamera;

@:access(flixel.system.frontEnds.CameraFrontEnd)
@:access(flixel.FlxCamera)
@:access(flixel.FlxGame)
class FlxCameraUtil
{
	public static function removeAtIndex(main:Null<CameraFrontEnd> = null, index:Int, Destroy:Bool = true)
	{
		if (main == null) main = FlxG.cameras;
		main.removeAtIndex(index, Destroy);
	}
	public static function insert(main:Null<CameraFrontEnd> = null, indexToAdd:Int, Camera:FlxCamera, ?DefaultDrawTarget:Bool)
	{
		if (main == null) main = FlxG.cameras;
		return main.insert(Camera, indexToAdd, DefaultDrawTarget);
	}
}