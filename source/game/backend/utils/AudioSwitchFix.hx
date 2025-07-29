package game.backend.utils;

import flixel.sound.FlxSound;
import game.backend.utils.native.Windows;
import lime.media.AudioManager;

@:dox(hide)
class AudioSwitchFix {
	@:noCompletion static function onStateSwitch(state:FlxState):Void {
		#if windows
			if (Main.audioDisconnected) {
				var playingList:Array<PlayingSound> = [];
				for(e in FlxG.sound.list) {
					if (e.playing) {
						playingList.push({
							sound: e,
							time: e.time
						});
						e.stop();
					}
				}
				if (FlxG.sound.music != null)
					FlxG.sound.music.stop();

				AudioManager.shutdown();
				AudioManager.init();
				Main.changeID++;

				for(e in playingList) {
					e.sound.play(e.time);
				}

				Main.audioDisconnected = false;
			}
		#end
	}

	public static function init() {
		#if windows
		Windows.registerAudio();
		FlxG.signals.preStateCreate.add(onStateSwitch);
		#end
	}
}

typedef PlayingSound = {
	var sound:FlxSound;
	var time:Float;
}