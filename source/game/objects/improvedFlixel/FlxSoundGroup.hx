package game.objects.improvedFlixel;

import flixel.sound.FlxSound;
import flixel.tweens.FlxTween;
import flixel.util.FlxDestroyUtil.IFlxDestroyable;

class FlxSoundGroup extends flixel.sound.FlxSoundGroup implements IFlxDestroyable
{
	public var fadeTween:FlxTween;

	public function play(ForceRestart:Bool = false, StartTime:Float = 0.0, ?EndTime:Float):Void
	{
		for (sound in sounds)
			sound.play(ForceRestart, StartTime, EndTime);
	}

	public function stop():Void
	{
		for (sound in sounds)
			sound.stop();
	}

	public function destroy()
	{
		var i:FlxSound;
		while (sounds.length > 0)
		{
			i = sounds.pop();
			FlxG.sound.list.remove(i);
			i?.destroy();
		}
	}

	public function fadeOut(Duration:Float = 1, ?To:Float = 0, ?onComplete:FlxTween->Void):FlxSoundGroup
	{
		fadeTween?.cancel();
		fadeTween = FlxTween.num(volume, To, Duration, {onComplete: onComplete}, set_volume);
		return this;
	}

	public function fadeIn(Duration:Float = 1, From:Float = 0, To:Float = 1, ?onComplete:FlxTween->Void):FlxSoundGroup
	{
		for (i in sounds)
		{
			if (!i.playing)
			{
				play();
			}
		}
		fadeTween?.cancel();
		fadeTween = FlxTween.num(From, To, Duration, {onComplete: onComplete}, set_volume);
		return this;
	}
}
