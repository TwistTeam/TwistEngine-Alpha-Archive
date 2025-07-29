package game.states.substates;

import game.backend.data.jsons.WeekData;
import game.backend.utils.Highscore;
import game.objects.Alphabet;
import game.objects.game.HealthIcon;
import game.states.FreeplayState;

import flixel.util.FlxColor;

class ResetScoreSubState extends MusicBeatSubstate
{
	var alphabetArray:Array<Alphabet> = [];
	var icon:HealthIcon;
	var onYes:Bool = false;
	var yesText:Alphabet;
	var noText:Alphabet;

	var difficulty:String;
	var song:SongMeta;
	var week:Int;

	var isWeek(get, never):Bool;
	function get_isWeek():Bool return week > -1;

	// Week -1 = Freeplay
	public function new(song:SongMeta, character:String = null, difficulty:String = null, week:Int = -1)
	{
		this.song = song;
		this.week = week;
		this.difficulty = difficulty;

		super(FlxColor.BLACK);
		_bgSprite.alpha = 0.0;

		var nameBuf:StringBuf = new StringBuf();
		// if (isWeek)
		// 	nameBuf.add(WeekData.weeksLoaded.get(WeekData.weeksList[week]).weekName);
		nameBuf.add(song.data.displaySongName ?? song.data.songName);
		if (difficulty != null && difficulty.trim().length > 0)
		{
			nameBuf.add(" ("); nameBuf.add(difficulty); nameBuf.add(")");
		}

		var name:String = nameBuf.toString();

		var scaleFactor:Float = 18 / Math.max(name.length, 18.0); // Fucking Winter Horrorland
		var text:Alphabet = new Alphabet(0, 180, "Reset the score of", true);
		text.screenCenter(X);
		text.scrollFactor.set();
		alphabetArray.push(text);
		text.alpha = 0;
		add(text);

		text = new Alphabet(0, text.y + 90, name, true);
		text.scaleX = Math.min(1, 980 / text.width);
		text.screenCenter(X);
		if (!isWeek)
			text.x += 60 * scaleFactor;
		text.scrollFactor.set();
		alphabetArray.push(text);
		text.alpha = 0;
		add(text);

		if (!isWeek && character != null)
		{
			icon = new HealthIcon(character);
			icon.setScale(scaleFactor * icon.baseScale * (icon.data?.scale ?? 1));
			icon.updateHealth(50);
			icon.setPosition(text.x - icon.width + 10 * scaleFactor, text.y - 30);
			icon.alpha = 0;
			add(icon);
		}

		yesText = new Alphabet(0, text.y + 150, 'Yes', true);
		yesText.screenCenter(X);
		yesText.x -= 200;
		yesText.scrollFactor.set();
		add(yesText);
		noText = new Alphabet(0, text.y + 150, 'No', true);
		noText.screenCenter(X);
		noText.x += 200;
		noText.scrollFactor.set();
		add(noText);
		updateOptions();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		_bgSprite.alpha += elapsed * 1.5;
		if (_bgSprite.alpha > 0.6)
			_bgSprite.alpha = 0.6;


		for (i in 0...alphabetArray.length)
		{
			alphabetArray[i].alpha += elapsed * 2.5;
		}
		if (!isWeek)
			icon.alpha += elapsed * 2.5;

		if (controls.UI_LEFT_P || controls.UI_RIGHT_P)
		{
			FlxG.sound.play(Paths.sound('scrollMenu'), 1);
			onYes = !onYes;
			updateOptions();
		}
		if (controls.BACK)
		{
			FlxG.sound.play(Paths.sound('cancelMenu'), 1);
			close();
		}
		else if (controls.ACCEPT)
		{
			if (onYes)
				// if (isWeek)
				// 	Highscore.resetWeek(WeekData.weeksList[week]);
				// else
					Highscore.resetSong(song.data.songName, difficulty);

			FlxG.sound.play(Paths.sound('cancelMenu'), 1);
			close();
		}
	}

	var scales:Array<Float> = [0.75, 1];
	var alphas:Array<Float> = [0.6, 1.25];
	function updateOptions()
	{
		var confirmInt:Int = onYes ? 1 : 0;

		yesText.alpha = alphas[confirmInt];
		yesText.scale.set(scales[confirmInt], scales[confirmInt]);
		noText.alpha = alphas[1 - confirmInt];
		noText.scale.set(scales[1 - confirmInt], scales[1 - confirmInt]);
		if (!isWeek)
			icon.updateHealth(onYes ? 10 : 50);
	}
}
