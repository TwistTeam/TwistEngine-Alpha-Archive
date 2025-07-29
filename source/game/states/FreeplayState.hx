package game.states;

import flixel.group.FlxGroup;
import haxe.extern.EitherType;
import game.backend.data.jsons.WeekData;
import game.backend.system.song.Conductor.mainInstance as Conductor;
import game.backend.system.song.Song;
import game.backend.utils.Highscore;
import game.objects.game.HealthIcon;
import game.objects.Alphabet;
import game.objects.improvedFlixel.FlxFixedText;
import game.states.editors.SongsState;
import game.states.editors.ChartingState;
import game.states.playstate.PlayState;
import game.states.substates.GameplayChangersSubstate;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxMath;
import flixel.tweens.*;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import openfl.media.Sound;
#if target.threaded
import sys.thread.Mutex;
import sys.thread.Thread;
#end
import game.backend.system.scripts.ScriptUtil;

@:publicFields
class SongMeta
{
	var data:SongMetaData;
	var modPack:String;
	var weekData:WeekData;

	function new(data:SongMetaData, ?modPack:String, ?weekData:WeekData)
	{
		this.data = data ?? WeekData.getDefaultSongMetaData();
		this.modPack = modPack;
		this.weekData = weekData;
	}
}

@:access(flixel.FlxCamera._scrollTarget)
class FreeplayState extends MusicBeatState
{
	public var songs:Array<SongMeta> = [];

	static var curSelected:Int = 0;
	static var curDifficultyIndex:Int = -1;

	var camFollow:FlxObject;
	var grpSongs:FlxGroup;
	var iconArray:Array<HealthIcon> = [];
	var camHUD:FlxCamera;
	var selectedSong:SongMeta;
	var selectedSaveScore:ScoreData;
	var bgSpr:FlxSprite;
	var curDifficulty(get, never):String;
	@:noCompletion function get_curDifficulty():String
	{
		if (curDifficultyIndex < 0) return null;
		var list = curDifficulties;
		return list == null ? null : list[curDifficultyIndex];
	}
	var curDifficulties(get, never):Array<String>;
	@:noCompletion function get_curDifficulties():Array<String>
	{
		return selectedSong?.weekData?.data.difficulties;
	}

	// Song playing stuff
	static var curSongPlaying:Array<EitherType<Int, String>> = [-1, 'pLease type mOd pAck HERE'];

	#if target.threaded
	var songThread:Thread;
	var _musicMutex:Mutex;
	#end
	var threadActive:Bool = true;

	var songToPlay:Sound = null;

	var intendedScore:Int = 0;
	var intendedMisses:Int = 0;
	var intendedRating:Float = 0;
	/*
	var lerpScore:Float = 0;
	var lerpRating:Float = 0;
	*/

	var grpAlphabetDispl:FlxTypedGroup<Alphabet>;
	var grpIconsDispl:FlxTypedGroup<HealthIcon>;

	override function destroy()
	{
		grpAlphabetDispl.clear();
		grpIconsDispl.clear();
		threadActive = false;
		super.destroy();
	}

	override function create()
	{
		Main.canClearMem = true;
		SongsState.inDebugFreeplay = false;
		Main.transition.curTransition = game.objects.transitions.VanilaTransition;
		bgSpr = new FlxSprite(Paths.image('menuDesat'));
		bgSpr.screenCenter();
		bgSpr.active = false;
		bgSpr.scrollFactor.set();
		add(bgSpr);
		camHUD = new FlxCamera();
		camHUD.bgColor.alpha = 0;
		FlxG.cameras.add(camHUD, false);

		// optimize quad draws
		add(grpAlphabetDispl = new FlxTypedGroup());
		add(grpIconsDispl = new FlxTypedGroup());
		add(grpSongs = new FlxGroup());
		grpSongs.visible = false;
		grpAlphabetDispl.active = grpIconsDispl.active = false;

		add(camFollow = new FlxObject(0, 0, 1, 1));
		FlxG.camera.follow(camFollow);
		FlxG.camera.targetOffset.set(FlxG.camera.viewWidth / 3 + 90, 320 - FlxG.camera.viewHeight / 2);

		// Thread.create(createSongs);
		generateSongsList();

		super.create();
		persistentUpdate = true;
		#if DISCORD_RPC
		DiscordClient.changePresence("In the Freeplay", null);
		#end
		if (FlxG.sound.music == null || !FlxG.sound.music.active)
			FlxG.sound.playMusic(Paths.music('freakyMenu'));
	}

	function generateSongsList()
	{
		if (call("generateSongsList") != ScriptUtil.Function_Stop)
		{
			final lastMod = ModsFolder.currentModFolderPath;
			var i:Int = 0;
			WeekData.reloadWeeksFiles(true);
			// trace(WeekData.weeksListOrder);
			// trace([for(i in WeekData.weeksDatas) i.data]);
			var icon:HealthIcon;
			var songText:Alphabet;
			var group:FlxSpriteGroup;
			var weekData:WeekData;
			for (key in WeekData.weeksListOrder)
			{
				if (key == null)
					continue;
				weekData = WeekData.weeksDatas.get(key.file);
				if (weekData == null || weekData.data.hideInFreeplay)
					continue;
				ModsFolder.switchMod(key.modPack, false);
				for (data in weekData.data.songs)
				{
					// trace(data);
					if (data == null || data.invisibleInFreeplay)
						continue;
					group = new FlxSpriteGroup();
					group.alpha = 0.6;
					group.ID = i;
					group.moves = false;
					songText = new Alphabet(90, 320, data.displaySongName ?? data.songName, true);
					songText.ID = songText.targetY = i;
					songText.scaleX = Math.min(1, 980 / songText.width);
					songText.x = i * songText.distancePerItem.x + songText.startPosition.x;
					songText.y = i * 1.3 * songText.distancePerItem.y + songText.startPosition.y;
					group.add(songText);
					grpAlphabetDispl.add(songText);
					if (data.healthIcon != null && data.healthIcon.trim().length > 0)
					{
						icon = new HealthIcon(data.healthIcon);
						icon.ID = i;
						icon.setScale(icon.baseScale * (icon.data == null ? 1 : icon.data.scale));
						icon.updateHealth(50);
						icon.setPosition(songText.x + songText.width + 10, songText.y - (icon.height - songText.height) / 2);
						icon.updateOffsets();
						iconArray.push(icon);
						var _lastName:String = null;
						icon.animation.callback = (name, number, frameIndex) -> {
							if (number != 0 || _lastName == name)
								return;
							icon.updateOffsets();
							_lastName = name;
						}
						group.add(icon);
						grpIconsDispl.add(icon);
						// icon.ID = i;
						// add(icon);
					}
					i++;
					songs.push(new SongMeta(data, key.modPack, weekData));
					grpSongs.add(group);
					// FlxTween.num(0, group.alpha, 0.2, {}, @:privateAccess group.set_alpha);
				}
				game.objects.game.HealthIcon.clearDatas();
			}
			if (songs.length > 0)
				changeItem(0, true);
			ModsFolder.switchMod(lastMod, false);
		}
		call("generateSongsListPost");
		FlxG.camera.followLerp = 1 / 6;
	}

	var momIGoingToSong:Bool = false;
	var selectedSomethin:Bool = false;
	var allowControls:Bool = true;
	var allowOpenGameplayChangers:Bool = true;
	var allowOpenResetSubstate:Bool = true;
	var allowPlayInst:Bool = true;

	var forMouseClick = false;
	override function onFocus()
	{
		forMouseClick = true;
		super.onFocus();
	}

	override function update(elapsed:Float)
	{
		if (allowControls && subState == null && !momIGoingToSong)
		{
			if (controls.BACK && call("onExit") != ScriptUtil.Function_Stop)
			{
				selectedSomethin = true;
				FlxG.sound.play(Paths.sound('cancelMenu'));
				MusicBeatState.switchState(new MainMenuState());
				call("onExitPost");
			}
			if (songs.length > 0)
			{
				if (FlxG.mouse.wheel != 0)
					changeItem(FlxG.mouse.wheel > 0 ? -1 : 1);
				else
				{
					if (controls.UI_UP_P)
						changeItem(-1);
					if (controls.UI_DOWN_P)
						changeItem(1);
				}
				if (selectedSong != null)
				{
					if (controls.ACCEPT || (!forMouseClick && FlxG.mouse.justReleased))
					{
						if(call("onAccept") != ScriptUtil.Function_Stop)
							goToPlaystate();
						call("onAcceptPost");
					}
					if (allowPlayInst && FlxG.keys.justPressed.Z)
					{
						changeSongPlaying();
					}
					else if (allowOpenGameplayChangers && FlxG.keys.justPressed.CONTROL)
					{
						var a = new GameplayChangersSubstate();
						openSubState(a);
						a.cameras = [camHUD];
					}
					else if (allowOpenResetSubstate && controls.RESET)
					{
						if(call("onOpenResetSubstate") != ScriptUtil.Function_Stop)
						{
							var healthIconName:String = getHealthIcon(cast grpSongs.members[curSelected])?.char;

							var a = new game.states.substates.ResetScoreSubState(selectedSong, healthIconName, curDifficulty, -1);
							openSubState(a);
							a.cameras = [camHUD];
							FlxG.sound.play(Paths.sound('scrollMenu'));
						}
						call("onPostOpenResetSubstate");
					}
				}
			}
		}

		super.update(elapsed);
		// for (icon in iconArray)
		// 	// if (icon.isOnScreen())
		// 		icon.updateOffsets();
		forMouseClick = false;
	}

	var _bgTween:FlxTween;
	var intendedColor:FlxColor;

	function goToPlaystate()
	{
		persistentUpdate = false;
		try
		{
			var a = PlayState.loadSong(selectedSong.data.songName, curDifficulty, curDifficulties, false);
			if (a != null)
			{
				_bgTween?.cancel();

				momIGoingToSong = true;
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

				curSongPlaying = [-1, 'pLease type mOd pAck HERE'];
				FlxG.sound.music.stop();
			}
			else
			{
				Log('Song "${selectedSong.data.songName}" failed to load', RED);
			}
		}
		catch (e)
		{
			Log(e, RED);
		}
	}
	function changeItem(huh:Int = 0, ?snap:Bool)
	{
		if(call("changeItem", [huh, snap]) != ScriptUtil.Function_Stop)
		{
			var group:FlxSpriteGroup = cast grpSongs.members[curSelected];
			var icon:HealthIcon;
			if (group != null)
			{
				group.alpha = 0.6;
				icon = getHealthIcon(group);
				if (icon != null)
					icon.updateHealth(50);
			}
			curSelected = FlxMath.wrap(curSelected + huh, 0, grpSongs.length - 1);

			group = cast grpSongs.members[curSelected];
			if (group != null)
			{
				var songMeta = songs[group.ID];
				if (songMeta != null)
				{
					selectedSong = songMeta;
					ModsFolder.switchMod(selectedSong.modPack);
					final newColor:Int = selectedSong.data.freeplayColor.getColorFromDynamic() ?? 0xFFABCACA;
					if (newColor != intendedColor)
					{
						_bgTween?.cancel();
						intendedColor = newColor;
						if (snap)
							bgSpr.color = intendedColor;
						else
							_bgTween = FlxTween.color(bgSpr, 0.5, bgSpr.color, intendedColor, {ease: FlxEase.cubeOut});
					}
					group.alpha = 1.;
					camFollow.setPosition(group.members[0].x, group.members[0].y + group.members[0].height / 2);
					if (snap)
						FlxG.camera.snapToTarget();
				}
				icon = getHealthIcon(group);
				if (icon != null)
					icon.updateHealth(80);
				if (huh != 0)
					FlxG.sound.play(Paths.sound('scrollMenu'));
				updateSongSave();
			}
		}
		call("changeItemPost", [huh, snap]);
	}

	function updateSongSave()
	{
		call("onUpdateSongSave");
		final data = selectedSong == null ? null : Highscore.getSongData(selectedSong.data.songName, curDifficulty);
		// trace(songs[curSelected][0]);
		selectedSaveScore = data;
		if (data == null)
		{
			intendedScore = 0;
			intendedRating = 0;
			intendedMisses = 0;
		}
		else
		{
			intendedScore = data.score;
			intendedRating = data.rating;
			intendedMisses = data.misses;
		}
		// trace(data);
		call("onUpdateSongSavePost");
	}

	inline function getHealthIcon(group:FlxSpriteGroup):HealthIcon
		return group == null ? null : cast group.members[1];

	/*
		public override function beatHit()
		{
			if (cast curSongPlaying[0] != -1 && cast curSongPlaying[1] == ModsFolder.currentModFolderPath)
			{
				var group = grpSongs.members[cast curSongPlaying[0]];
				if (group != null)
				{
					var icon:HealthIcon = cast group.members[1];
					if (icon != null)
						FlxTween.num(icon.baseScale * 1.3, icon.baseScale, Conductor.crochet / 1100,{ease: FlxEase.cubeOut}, (i) -> icon.scale.set(i, i));
				}
			}
		}
	 */
	// from Forever engine
	function changeSongPlaying()
	{
		#if target.threaded
		_musicMutex ??= new Mutex();
		songThread ??= Thread.create(function()
		{
			var index:Null<Int>;
			while (threadActive)
			{
				index = Thread.readMessage(false);
				if (index == null) continue;

				if ((index == curSelected && index != cast curSongPlaying[0])
					|| cast curSongPlaying[1] != ModsFolder.currentModFolderPath)
				{
					trace("Loading index " + index);

					var inst:Sound = Paths.inst(songs[curSelected].data.songName);

					if (index == curSelected && threadActive)
					{
						if (inst != null)
						{
							_musicMutex.acquire();
							FlxG.sound.playMusic(songToPlay = inst);
							_musicMutex.release();
						}
						else
							trace("Inst is missing " + index);

						curSongPlaying[0] = curSelected;
						curSongPlaying[1] = ModsFolder.currentModFolderPath;
					}
					else
					{
						trace("Nevermind, skipping " + index);
					}
				}
				else
				{
					trace("Skipping " + index);
				}
			}
			trace("Killing thread");
			songThread = null;
		});

		songThread.sendMessage(curSelected);
		#else
		var inst:Sound = Paths.inst(songs[curSelected].data.songName);

		curSongPlaying[0] = curSelected;
		curSongPlaying[1] = ModsFolder.currentModFolderPath;
		FlxG.sound.playMusic(songToPlay = inst);
		#end
	}
}
