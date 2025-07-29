package game.states.substates;

import game.backend.data.jsons.WeekData;
import game.backend.system.scripts.ScriptUtil;
import game.states.FreeplayState;
import game.states.betterOptions.OptionsSubState;
import game.states.editors.SongsState;
import game.states.playstate.PlayState;

import flixel.addons.transition.FlxTransitionableState;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.system.FlxSound;

class PauseSubState extends MusicBeatSubstate
{
	var grpMenuShit:FlxTypedGroup<FlxSprite>;
	var menuItems:Array<String> = ['Resume', 'Restart', /* 'Exit the Game',*/ 'Exit'];
	var curSelected:Int = 0;

	public var pauseMusic:FlxSound = null;
	var itIsAccepted:Bool = false;
	var curTime:Float = Math.max(0, game.backend.system.song.Conductor.mainInstance.songPosition);

	var holdTime:Float = 0;
	var cantUnpause:Float = 0.1;

	// var botplayText:FlxText;
	public static var songName:String = null;

	public var defaultFreezeBGDraws:Bool = false;
	public var freezeBGDraws(default, set):Bool;

	function set_freezeBGDraws(i:Bool):Bool
	{
		freezeBGDraws = i;
		updateBGCamerasList();
		return freezeBGDraws;
	}

	var playstate:PlayState;

	var _bgCamerasFreezeStatus:Array<Bool>;
	var _bgCameras:Array<FlxCamera>;

	public function new(?scriptName:String, ?freezeBGDraws:Bool)
	{
		playstate = PlayState.instance;
		cameras = [playstate.camPAUSE];

		this.freezeBGDraws = freezeBGDraws ?? defaultFreezeBGDraws;
		// this.freezeBGDraws = true;

		super(FlxColor.TRANSPARENT, true, scriptName);
		bgSprite.cameras = cameras;
	}
	override function create()
	{
		playstate.setPause(true);
		createUI();
		super.create();
	}

	function updateBGCamerasList()
	{
		if (_bgCameras != null && _bgCamerasFreezeStatus != null)
		{
			for (i in 0..._bgCameras.length)
			{
				_bgCameras[i].freezeDraws = _bgCamerasFreezeStatus[i];
			}
		}

		var cameraList = FlxG.cameras.list;
		var length = cameraList.indexOf(camera);
		_bgCameras = new Array();
		for (i in 0...length)
		{
			if (Std.isOfType(cameraList[i], FlxCamera))
				_bgCameras.push(cast cameraList[i]);
		}

		_bgCamerasFreezeStatus = new Array();
		_bgCamerasFreezeStatus.resize(_bgCameras.length);
		for (i in 0..._bgCameras.length)
		{
			_bgCamerasFreezeStatus[i] = _bgCameras[i].freezeDraws;
			_bgCameras[i].freezeDraws = freezeBGDraws || _bgCameras[i].freezeDraws;
		}
	}

	function createUI():Void
	{
		if (pauseMusic == null)
		{
			pauseMusic = FlxG.sound.load(Paths.music(songName ?? "breakfast"), 0, true);
			if (pauseMusic != null)
			{
				pauseMusic.play(false, FlxG.random.int(0, Std.int(pauseMusic.length / 2)));
				pauseMusic.fadeIn(2, 0, 0.4);
			}
		}

		call("createUI");
	}

	function openOptions(){
		openSubState(new OptionsSubState());
		persistentUpdate = true;
	}

	@:access(game.states.playstate.PlayState)
	function endSong()
	{
		close();
		#if NOTE_BACKWARD_COMPATIBILITY
		var unspawnNotes = playstate.unspawnNotes;
		while (unspawnNotes.length > 0) unspawnNotes.pop();
		#end
		for (i in playstate.strumLines)
		{
			var unspawnNotes = i.unspawnNotes;
			while (unspawnNotes.length > 0) unspawnNotes.pop().destroy();
		}
		//unspawnNotes.splice(0, unspawnNotes.length - 1);
		//playstate.seenResults = true;
		playstate.finishSong(true);
	}

	function exit()
	{
		if (call("exit") != ScriptUtil.Function_Stop)
		{
			PlayState.deathCounter = 0;
			PlayState.seenCutscene = false;

			var prevTransition = Main.transition.curTransition;
			Main.transition.curTransition = game.objects.transitions.StickersTransition;
			game.objects.transitions.StateTransition.finishCallback = () -> {
				Main.transition.curTransition = prevTransition;
			}
			// WeekData.loadTheFirstEnabledMod();
			playstate.cancelMusicFadeTween();
			// if (PlayState.isStoryMode)
			// 	MusicBeatState.switchState(new StoryMenuState());
			// else
				MusicBeatState.switchState(#if EDITORS_ALLOWED SongsState.inDebugFreeplay ? new SongsState() : #end new FreeplayState());
			PlayState.chartingMode = false;
		}
	}

	public function songRestart(noTrans:Bool = false)
	{
		PauseSubState.restartSong(noTrans);
	}

	public static function restartSong(noTrans:Bool = false)
	{
		var playstate = PlayState.instance;
		if (playstate == null) return;
		playstate.paused = true; // For lua
		if (FlxG.sound.music != null) FlxG.sound.music.volume = 0;

		playstate.songGroup.volume = 0;

		if (noTrans) FlxTransitionableState.skipNextTransIn = FlxTransitionableState.skipNextTransOut = true;
		FlxG.resetState();
	}

	override function destroy()
	{
		freezeBGDraws = false;

		if (pauseMusic != null)
		{
			pauseMusic.fadeTween?.cancel();
			FlxG.sound.list.remove(pauseMusic, true);
			pauseMusic.stop();
			pauseMusic = null;
			// pauseMusic.destroy();
		}
		_bgCameras = null;
		_bgCamerasFreezeStatus = null;
		// haxe.Log.trace(haxe.CallStack.callStack(), null);
		super.destroy();
		#if DEV_BUILD
		if (!playstate.isFreezed)
		{
			playstate.setPause(false);
		}
		#else
		playstate.setPause(false);
		#end
	}
}