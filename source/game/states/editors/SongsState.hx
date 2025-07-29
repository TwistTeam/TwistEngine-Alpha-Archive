package game.states.editors;

import flixel.effects.FlxFlicker;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import game.backend.data.jsons.WeekData;
import game.backend.system.song.Conductor.mainInstance as Conductor;
import game.backend.system.song.Song;
import game.backend.system.states.MusicBeatState;
import game.backend.utils.Difficulty;
import game.backend.utils.Highscore;
import game.objects.FlxStaticText;
import game.objects.ui.FlxInputText;
import game.states.playstate.PlayState;
import game.states.substates.GameplayChangersSubstate;
import game.states.substates.ResetScoreSubState;
import haxe.Json;
import haxe.io.Path;

// -ТИМОХА ЧЁ ТЫ ТВОРИШЬ НАХУЙ?!
// -ЭТО ROFLS!
class SongsState extends MusicBeatState
{
	public var textGroup:FlxTypedGroup<FlxStaticText>;

	var songs:Array<Array<String>> = []; // <'PATH', 'SONG NAME', 'MODFOLDER', 'NAME SONG FOR SAVE'> or <'MODNAME', 'BYTES'>

	static var curSelected:Int = 0;

	var scoreText:FlxStaticText;
	var lerpScore:Int = 0;
	var lerpRating:Float = 0;
	var intendedScore:Int = 0;
	var intendedMisses:Int = 0;
	var intendedRating:Float = 0;

	public static var inDebugFreeplay:Bool = false;

	public function loadSongs()
	{
		// Mods.pushGlobalMods();
		final files:Array<Array<String>> = [];

		var songName:String;
		var diff:String;
		for (songFolder in AssetsPaths.getFolderDirectories(Constants.SONG_CHART_FILES_FOLDER, true))
		{
			songFolder = songFolder.toLowerCase();
			songName = songFolder.substring(songFolder.lastIndexOf('/') + 1);
			for (file in AssetsPaths.getFolderContent(songFolder, true))
			{
				if (!file.endsWith('.json') || file.toLowerCase().substring(file.lastIndexOf('/') + 1).indexOf(songName) == -1)
					continue;
				diff = Difficulty.getDifficultyFromFullPath(file);
				if (diff != null && diff.trim().length == 0)
					diff = null;
				files.push([
					file.substring(songFolder.length + 1, file.length - 5),
					file.substring(0, file.length - 5),
					diff
				]);
			}
		}
		// files.reverse();
		return files;
	}

	var searchInput:FlxInputText;

	override function create()
	{
		inDebugFreeplay = true;
		FlxG.camera.bgColor = 0xFF000000;
		songs = loadSongs();

		curSelected = Std.int(Math.min(curSelected, songs.length - 1)); // safe

		FlxG.camera.antialiasing = true;

		textGroup = new FlxTypedGroup<FlxStaticText>();
		add(textGroup);

		if (songs.length > 0)
		{
			var BULLSHIT:Int = 0;
			var BULLSHITOFFSET:Int = 0;
			var BULLSHITOFFSETY:Int = 0;
			final max:Int = songs.length;
			var i:Array<String>;
			var text:FlxStaticText;
			while (BULLSHIT < max)
			{
				i = songs[BULLSHIT];
				text = new FlxStaticText(120 + FlxG.width * ((BULLSHIT + BULLSHITOFFSET) % 2) / 2,
					50 + 68 * (Std.int((BULLSHIT + BULLSHITOFFSET) / 2) + BULLSHITOFFSETY), 0, '', 30);
				text.ID = BULLSHIT;
				// if(i.length > 2){
				text.text = i[0] + ".json";
				text.alpha = 0.5;
				// var deSang:String = 'ERROR_DATA';
				// var rawJson = File.getContent(i[0]).trim();
				// final data = Song.parseJSONshit(rawJson);
				// try {
				// 	deSang = data.song; // aaaaauuuuuuuuhhhhhhhhhhhhhhh
				// }
				// i.push(i[1]);
				// }else{
				// 	text.size = 22;
				// 	text.screenCenter(X);
				// 	// text.text += ' ( ' + CoolUtil.getSizeString(Std.parseInt(i[1])) + ' )';
				// 	if ((BULLSHIT + BULLSHITOFFSET) % 2 == 1){
				// 		BULLSHITOFFSETY++;
				// 		text.y += 68;
				// 	}else{
				// 		BULLSHITOFFSET++;
				// 	}
				// }
				textGroup.add(text);
				BULLSHIT++;
			}

			scoreText = new FlxStaticText(FlxG.width * 0.7, 5, 0, "", 32);
			scoreText.setFormat(null, 32, FlxColor.WHITE, RIGHT); // idk how type default font
			scoreText.scrollFactor.set();
			add(scoreText);

			if (ModsFolder.currentModFolderPath != null && ModsFolder.currentModFolderPath.length > 0)
			{
				var warnTxt = new FlxStaticText(8, 5, 0, 'Warning, the engine is starting to be remaded and is scheduled to be detuned from Psych,
				so mods from Psych may break!
				Внимание, движок начинает переделываться и планируется отстраниться от Psych,
				поэтому моды с Psych могут сломаться!', 10);
				warnTxt.alpha = 0;
				warnTxt.alignment = LEFT;
				warnTxt.y = FlxG.height - warnTxt.height - 10;
				warnTxt.scrollFactor.set();
				flixel.tweens.FlxTween.tween(warnTxt, {alpha: 0.6}, 4);
				add(warnTxt);
			}

			/*
			searchInput = new FlxInputText(0, 0, 300);
			searchInput.allowUndo = false;
			searchInput.setFormat(null, 8, FlxColor.WHITE, RIGHT);
			searchInput.onChangeText.add(text -> {
				final index = textGroup.any((obj) -> return obj.text.substr(0, obj.text.indexOf('.json')) == text) ?
					textGroup.getFirstIndex((obj) -> return obj.text.substr(0, obj.text.indexOf('.json')) == text)
				:
					-1;
				trace(index);
				if (index == -1) return;
			});
			add(searchInput);
			FlxG.mouse.visible = true;
			*/

			changeSelection();
		}
		else
		{
			final text:FlxStaticText = new FlxStaticText(120, 100 + 68, 0, 'Songs not found', 60);
			text.screenCenter();
			textGroup.add(text);
		}
		#if DISCORD_RPC
		// Updating Discord Rich Presence
		// DiscordClient.changePresence(".. --. .-. .- . - / .-- / -. . / -.-. --- .-.. --- .-. ... / .- -.. ...- . -. - ..- .-. .", null);
		DiscordClient.changePresence();
		#end

		FlxG.camera.fade(FlxColor.BLACK, 0.5, true);

		if (FlxG.sound.music != null)
			FlxG.sound.music.fadeOut(0.45);

		super.create();
		FlxG.camera.followLerp = 0;
	}

	override function closeSubState()
	{
		super.closeSubState();
		if (songs.length > 1)
			changeSelection(0, false);
	}

	var isGoBack:Bool = false;

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (subState == null && !isGoBack)
		{
			if (songs.length > 1)
			{
				final shiftMult:Int = FlxG.keys.pressed.SHIFT ? 3 : 1;

				if (controls.UI_UP_P)
				{
					FlxG.camera.shake(0.001, 0.08);
					// if (textGroup.length != 2)
					changeSelection(-shiftMult - 1);
				}
				else if (controls.UI_DOWN_P)
				{
					FlxG.camera.shake(0.001, 0.08);
					// if (textGroup.length != 2)
					changeSelection(shiftMult + 1);
				}
				if (controls.UI_LEFT_P)
				{
					FlxG.camera.shake(0.001, 0.08);
					// if (textGroup.length != 2)
					changeSelection(-shiftMult);
				}
				else if (controls.UI_RIGHT_P)
				{
					FlxG.camera.shake(0.001, 0.08);
					// if (textGroup.length != 2)
					changeSelection(shiftMult);
				}
			}
			if (songs.length > 0)
				if (controls.ACCEPT)
				{
					if (Assets.exists(songs[curSelected][1] + '.json'))
					{
						goToPlayState();
					}
					else
					{
						trace('Couldnt find file for play');
						FlxG.sound.play(Paths.sound('whyNotLol/Voice (' + FlxG.random.int(1, 20) + ')'));
					}
				}
				// else if (controls.RESET)
				// {
				// 	openSubState(new ResetScoreSubState(songs[curSelected], '', -2));
				// 	FlxG.sound.play(Paths.sound('scrollMenuDown'));
				// }
			if (FlxG.keys.justPressed.CONTROL)
				openSubState(new GameplayChangersSubstate());
			if (controls.BACK)
			{
				FlxG.sound.play(Paths.sound('cancelMenu'));
				inDebugFreeplay = false;
				MusicBeatState.switchState(new game.states.editors.MasterEditorMenu());
				isGoBack = true;
			}
		}
		// super.update(elapsed);
	}

	public function goToPlayState()
	{
		FlxG.sound.play(Paths.sound('confirmMenu'), 0.7);
		if (ClientPrefs.flashing)
			FlxFlicker.flicker(textGroup.members[curSelected], 10, 0.15, false);
		isGoBack = true;
		new FlxTimer().start(1.1, _ ->
		{
			var e = new Song(Song.parseJSONshit(Assets.getText(songs[curSelected][1] + '.json')));
			e.difficulty = Difficulty.getDifficultyFromFullPath(songs[curSelected][1]) ?? e.difficulty;
			Difficulty.list = [e.difficulty]; // woo vomp
			PlayState.setSong(e);
			PlayState.isStoryMode = false;
			#if EDITORS_ALLOWED
			if (FlxG.keys.pressed.SHIFT)
			{
				MusicBeatState.switchState(new ChartingState());
			}
			else
			#end
			{
				LoadingState.loadAndSwitchState(new PlayState());
			}

			if (FlxG.sound.music != null)
			{
				FlxG.sound.music.volume = 0;
				FlxG.sound.music.stop();
			}

			Conductor.songPosition = -5000;
		});
	}

	private inline function unselectableCheck(num:Int):Bool
		return songs[num].length > 1;

	public function changeSelection(change:Int = 0, ?playSound:Bool = true)
	{
		var obj = textGroup.members[curSelected];
		if (obj != null)
			obj.alpha = 0.5;

		if (songs.length > 1)
		{
			do
			{
				curSelected = flixel.math.FlxMath.wrap(curSelected + change, 0, songs.length - 1);
			}
			while (!unselectableCheck(curSelected));
		}
		else
		{
			curSelected = 0;
		}
		obj = textGroup.members[curSelected];
		// trace(songs[curSelected]);
		obj.alpha = 1;
		var point = obj.getMidpoint();
		FlxG.camera.scroll.y = point.y - FlxG.camera.height / 2;
		point.put();
		final data = Highscore.getSongData(songs[curSelected][0]);
		trace(songs[curSelected]);
		if (data == null)
		{
			intendedScore = 0;
			intendedRating = 0;
			intendedMisses = 0;
		}
		else
		{
			intendedScore = data.score;
			intendedRating = Math.floor(100 * data.rating);
			intendedMisses = data.misses;
		}

		scoreText.text = 'PERSONAL BEST: $intendedScore ($intendedRating%)\nMisses: $intendedMisses';
		// ModsFolder.currentModFolder = songs[curSelected][2];
		scoreText.x = FlxG.width - scoreText.width - 26;
		if (playSound)
			FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
	}
}
