package game.objects.openfl;

import flixel.FlxG;
import flixel.util.FlxTimer;

class FlxGlobalTimer
{
	public static var globalManager:FlxGlobalTimerManager;
}
class FlxGlobalTimerManager extends FlxTimerManager
{
	public var useTimeScale:Bool = false;
	public function new():Void
	{
		super();
		FlxG.signals.preStateSwitch.remove(clear);
		Main.mainInstance.onPostEnterFrame.add(onPostEnterFrame);
	}

	@:access(flixel.FlxGame)
	function onPostEnterFrame() {
		update(FlxG.game._elapsedMS / 1000 * (useTimeScale ? FlxG.timeScale : 1));
	}

	public override function destroy():Void
	{
		super.destroy();
		Main.mainInstance.onPostEnterFrame.remove(onPostEnterFrame);
	}
}