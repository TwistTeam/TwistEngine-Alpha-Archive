package game.backend.utils;

#if UI_POPUPS
import haxe.ui.notifications.*;
import haxe.ui.Toolkit;

class Notifications
{
	static var _garrysSound = new flixel.sound.FlxSound();
	public static function show(title:String, body:String, type:NotificationType = Error)
	{
		if (type == Warning || type == Error)
		{
			FlxG.sound.list.add(_garrysSound);
			_garrysSound.loadEmbedded(Paths.sound("system/FX-8"));
			_garrysSound.useTimeScaleToPitch = false;
			_garrysSound.play(true);
			FlxG.sound.list.remove(_garrysSound);
		}
		NotificationManager.instance.addNotification({
			title: title,
			body: body,
			expiryMs: 8000,
			type: type
		});
	}
}
#end