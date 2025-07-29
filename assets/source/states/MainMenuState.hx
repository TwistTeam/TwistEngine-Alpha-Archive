import flixel.effects.FlxFlicker;
import game.states.MainMenuState;
import game.backend.system.states.MusicBeatState;

for (i in MainMenuState.optionShit)
	if(i[0] == "credits")
	{
		i[1] = () -> {
			FlxG.sound.play(Paths.sound('confirmMenu'));
			selectedSomethin = true;

			if (ClientPrefs.data.flashing)
				FlxFlicker.flicker(magenta, 1.1, 0.15, false);

			for (i => obj in menuItems.members)
			{
				if (i == MainMenuState.curSelected)
				{
					FlxFlicker.flicker(obj, 1, 0.06, false, false, _ ->
						MusicBeatState.switchState(new MusicBeatState("CreditsState"))
					);
				}
				else
				{
					FlxTween.tween(obj, {alpha: 0}, 0.4, {
						ease: FlxEase.quadOut,
						onComplete: _ -> obj.destroy()
					});
				}
			}
		};
		break;
	}