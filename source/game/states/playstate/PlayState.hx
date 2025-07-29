package game.states.playstate;

// game
import hscript.Interp;
import hscript.Parser;
import game.backend.data.StrumsManiaData;
import game.backend.data.jsons.StageData;
// import game.backend.system.ReplayHandler;
import game.backend.system.audio.EffectSound;
import game.backend.system.scripts.FunkinLua;
import game.backend.system.scripts.HScript;
import game.backend.system.scripts.ScriptPack;
import game.backend.system.scripts.ScriptUtil;
import game.backend.system.song.Conductor.mainInstance as Conductor;
import game.backend.system.song.Rating;
import game.backend.system.song.Section;
import game.backend.system.song.Song;
import game.backend.system.states.MusicBeatState;
import game.backend.utils.Controls;
import game.backend.utils.Difficulty;
import game.backend.utils.GamepadUtil;
import game.backend.utils.Highscore;
import game.backend.utils.WindowUtil;
import game.objects.*;
import game.objects.game.*;
import game.objects.game.DialogueBoxPsych.DialogueFile;
import game.objects.game.notes.*;
import game.objects.game.notes.Note.EventNote;
import game.objects.improvedFlixel.*;
import game.states.editors.CharacterEditorState;
import game.states.editors.ChartingState;
import game.states.editors.SongsState;
import game.states.substates.GameOverSubstate;
import game.states.substates.PauseSubState;
import game.states.substates.pauses.*;
import game.states.FreeplayState;
#if TOUCH_CONTROLS
import game.mobile.objects.MobileHitbox.MobileHint;
import game.mobile.objects.MobileHitbox.HintStatus;
#end

import game.modchart.*;

import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxSpriteGroup;
import flixel.input.keyboard.FlxKey;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.system.FlxSound;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxSort;
import flixel.util.FlxSave;
import flixel.util.FlxTimer;
import flixel.util.helpers.FlxBounds;
import flixel.util.helpers.FlxRange;

import haxe.Json;

import lime.utils.Assets;

import openfl.events.KeyboardEvent;

using flixel.util.FlxStringUtil;

class PlayState extends MusicBeatState {
	public static var STRUM_X = 42;
	public static var STRUM_X_MIDDLESCROLL = -278;

	public var ratingStuff:Array<{percent:Float, name:String}> = [
		{percent:20,	name: 'You Suck!'	},	// https://youtube.com/clip/UgkxqA_3yxQ-pps1cjtLkzFrtkW6_dOOkiPQ?si=VLN9slqmwSELKVp6
		{percent:40,	name: 'Shit'		},	// From 20% to 39%
		{percent:50,	name: 'Bad'			},	// From 40% to 49%
		{percent:60,	name: 'Bruh'		},	// From 50% to 59%
		{percent:69,	name: 'Meh'			},	// From 60% to 68%
		{percent:70,	name: 'Nice'		},	// 69%
		{percent:80,	name: 'Good'		},	// From 70% to 79%
		{percent:90,	name: 'Great'		},	// From 80% to 89%
		{percent:100,	name: 'Sick!'		},	// From 90% to 99%
		{percent:100,	name: 'Perfect!!'	} // The value on this one isn't used actually, since Perfect is always "1"
	];

	public var boyfriendMap:Map<String, Character> = new Map<String, Character>();
	public var dadMap:Map<String, Character> = new Map<String, Character>();
	public var gfMap:Map<String, Character> = new Map<String, Character>();

	public var variables(get, never):Map<String, Dynamic>;
	@:noCompletion inline function get_variables() return scriptPack.variables;

	#if LUA_ALLOWED
	public var modchartTweens(get, never):Map<String, FlxTween>;
	public var modchartSprites(get, never):Map<String, ModchartSprite>;
	public var modchartTimers(get, never):Map<String, FlxTimer>;
	public var modchartSounds(get, never):Map<String, FlxSound>;
	public var modchartTexts(get, never):Map<String, ModchartText>;
	public var modchartSaves(get, never):Map<String, FlxSave>;

	@:noCompletion inline function get_modchartTweens() return scriptPack.modchartTweens;
	@:noCompletion inline function get_modchartSprites() return scriptPack.modchartSprites;
	@:noCompletion inline function get_modchartTimers() return scriptPack.modchartTimers;
	@:noCompletion inline function get_modchartSounds() return scriptPack.modchartSounds;
	@:noCompletion inline function get_modchartTexts() return scriptPack.modchartTexts;
	@:noCompletion inline function get_modchartSaves() return scriptPack.modchartSaves;
	#end


	// public var pauseSubStates:Map<String, PauseSubState>/* = new Map<String, PauseSubState>()*/; // soon

	// event variables
	public var isCameraOnForcedPos:Bool = false;

	public var BF_POS:FlxPoint	= FlxPoint.get(770.0, 100.0);
	public var DAD_POS:FlxPoint	= FlxPoint.get(100.0, 100.0);
	public var GF_POS:FlxPoint	= FlxPoint.get(400.0, 130.0);

	// DEPRECATED!!!
	public var BF_X(get, set):Float;
	public var BF_Y(get, set):Float;
	public var DAD_X(get, set):Float;
	public var DAD_Y(get, set):Float;
	public var GF_X(get, set):Float;
	public var GF_Y(get, set):Float;

	@:noCompletion inline function get_BF_X():Float			return BF_POS.x;
	@:noCompletion inline function get_BF_Y():Float			return BF_POS.y;
	@:noCompletion inline function get_DAD_X():Float		return DAD_POS.x;
	@:noCompletion inline function get_DAD_Y():Float		return DAD_POS.y;
	@:noCompletion inline function get_GF_X():Float			return GF_POS.x;
	@:noCompletion inline function get_GF_Y():Float			return GF_POS.y;

	@:noCompletion inline function set_BF_X(v:Float):Float		return BF_POS.x  = v;
	@:noCompletion inline function set_BF_Y(v:Float):Float		return BF_POS.y  = v;
	@:noCompletion inline function set_DAD_X(v:Float):Float		return DAD_POS.x = v;
	@:noCompletion inline function set_DAD_Y(v:Float):Float		return DAD_POS.y = v;
	@:noCompletion inline function set_GF_X(v:Float):Float		return GF_POS.x  = v;
	@:noCompletion inline function set_GF_Y(v:Float):Float		return GF_POS.y  = v;

	public var songSpeedTween:FlxTween;
	public var songSpeed(default, set):Float = 1;
	public var songSpeedType:String = "multiplicative";
	public var noteKillOffset:Float = 350;

	public var playbackRate(default, set):Float = 1;

	public var boyfriendGroup:FlxSpriteGroup;
	public var bfGroup(get, never):FlxSpriteGroup;
	inline function get_bfGroup() return boyfriendGroup;
	public var dadGroup:FlxSpriteGroup;
	public var gfGroup:FlxSpriteGroup;

	public var modManager:ModManager;

	public static var isPixelStage:Bool = false;
	public static var SONG(default, set):Song = null;
	@:noCompletion static inline function set_SONG(i) {
		// if (SONG != null && SONG != i) SONG.dispose();
		return SONG = i;
	}
	public static var isStoryMode:Bool = false;
	public static var storyWeek:Int = 0;
	public static var storyPlaylist:Array<String> = [];
	public static var storyDifficulty:Int = 1;

	public static function loadSong(songName:String, ?difficulty:String, ?difficultyList:Array<String>, ?isStoryMode:Null<Bool>):Null<Song>
	{
		var a = Song.loadFromJsonSimple(songName, difficulty);
		if (a == null)
			return null;

		difficultyList ??= Difficulty.defaultList;
		Difficulty.list = difficultyList;
		setSong(a);
		return a;
	}

	public static function setSong(SONG:Song)
	{
		PlayState.SONG = SONG;
		PlayState.isStoryMode = isStoryMode == true;
		var index:Int = -1;
		for (i => diff in Difficulty.list)
		{
			if (SONG.difficulty.toLowerCase() == diff.toLowerCase())
			{
				index = i;
				break;
			}
		}
		PlayState.storyDifficulty = index;
		trace(Difficulty.list, SONG.difficulty, PlayState.storyDifficulty);
	}

	public var stageData:StageFile;
	public var curStage:String = '';

	// public static var storyDifficulty:Int = 1;
	public var spawnTime:Float = 1500;

	public var inst:EffectSound;
	public var vocals:EffectSound;
	public var vocalsDAD:EffectSound;
	public var songGroup:FlxSoundGroup;

	public var dad:Character = null;
	public var gf:Character = null;
	public var boyfriend:Character = null;
	public var playerCharacters:Array<Character> = [];

	#if NOTE_BACKWARD_COMPATIBILITY
	public var notes:FlxTypedGroup<Note>;
	// public var sustainNotes:FlxTypedGroup<Note>;
	// public var regularNotes:FlxTypedGroup<Note>;
	public var unspawnNotes:Array<Note> = new Array<Note>();
	#end
	public var eventNotes:Array<EventNote> = new Array<EventNote>();

	private var strumLine:FlxPoint;

	// Handles the new epic mega sexy cam code that i've done
	public var camFollow:FlxPoint;
	private static var prevCamFollow(default, null):FlxPoint;
	public var camFollowPos:FlxObject;
	private static var prevCamFollowPos(default, null):FlxObject;

	public var strumLines:Array<StrumLine> = [];
	public var strumLineNotes:FlxTypedGroup<StrumNote>;
	public var opponentStrumLine:StrumLine;
	public var playerStrumLine:StrumLine;
	public var opponentStrums:StrumGroup;
	public var playerStrums:StrumGroup;
	public var grpNoteSplashes(get, never):FlxTypedGroup<NoteSplash>;
	inline function get_grpNoteSplashes()
	{
		return playerStrumLine.noteSplashes;
	}

	public var camZooming:Bool = false;
	public var camZoomingMult:Float = 1;
	public var camZoomingDecay:Float = 1;
	public var curSong:String = "";

	public var gfSpeed:Int = 1;
	public var combo:Int = 0;
	public var maxCombo:Int = 0;
	public var timeBarGroup:FlxSpriteGroup;
	public var iconsGroup:FlxTypedSpriteGroup<HealthIcon>;
	public var healthBarGroup:FlxSpriteGroup;

	// public var healthBarGradient:FlxSprite;
	public var healthBarFlipX(default, set):Bool = true;
	public dynamic function set_healthBarFlipX(e:Bool):Bool return iconsGroup.flipX = healthBarFlipX = e;

	public var healthBounds(default, set):FlxBounds<Float> = new FlxBounds<Float>(0, 2);
	inline function set_healthBounds(e:FlxBounds<Float> ):FlxBounds<Float> {
		healthBounds = e;
		health = health;
		return healthBounds;
	}
	public inline function setHealthBounds(min:Float = 0, max:Float = 2):FlxBounds<Float> return healthBounds.set(min, max);

	public var healthPercent(get, set):Float;

	function get_healthPercent():Float
	{
		return FlxMath.remapToRange(health, healthBounds.min, healthBounds.max, 0, 1);
	}
	function set_healthPercent(i:Float):Float
	{
		i = FlxMath.bound(i, 0, 1);
		return health = FlxMath.remapToRange(i, 0, 1, healthBounds.min, healthBounds.max);
	}
	public var health(default, set):Float = 1;
	inline function set_health(e:Float):Float{
		if (healthBounds.active) e = CoolUtil.boundTo(e, healthBounds.min, healthBounds.max);
		if(e != health)
		{
			callOnScripts('onUpdateHealth', [e]); // return percent
			health = e;
			doDeathCheck();
			updateHealthIcons();
			callOnScripts('onUpdateHealthPost', [e]); // return percent
		}
		return health;
	}
	public dynamic function updateHealthIcons(){
		final percent = Math.round(FlxMath.remapToRange(health, healthBounds.min, healthBounds.max, 0, 100));
		iconsGroup.forEach((icon:HealthIcon) -> {
			if (icon.isPlayer)
				icon.updateHealth(percent);
			else
				icon.updateHealth(100 - percent);
		});
	}

	var songPercent:Float = 0;

	public var ratingsData:Array<Rating> = Rating.loadDefault();
	public var sicks(get, never):Int;
	inline function get_sicks():Int return ratingsData[0].hits;

	public var goods(get, never):Int;
	inline function get_goods():Int return ratingsData[1].hits;

	public var bads(get, never):Int;
	inline function get_bads():Int return ratingsData[2].hits;

	public var shits(get, never):Int;
	inline function get_shits():Int return ratingsData[3].hits;

	private var generatedMusic:Bool = false;
	public var endingSong:Bool = false;
	public var startingSong:Bool = false;
	private var updateTime:Bool = false;
	// public static var changedDifficulty:Bool = false;
	public static var chartingMode:Bool = false;

	// Gameplay settings
	public var healthDrainPercent:Float = 0;
	public var healthGain:Float = 1;
	public var healthLoss:Float = 1;
	public var instakillOnMiss:Bool = false;
	@:isVar
	public var cpuControlled(get, set):Null<Bool> = false;
	function get_cpuControlled():Null<Bool> return playerStrumLine?.cpuControlled ?? cpuControlled;
	function set_cpuControlled(i:Null<Bool>):Null<Bool>
	{
		i ??= ClientPrefs.getGameplaySetting('botplay', false) || ChartingState.botPlayChartMod;
		if (!ScriptPack.resultIsStop(callOnScripts('onBotplayChange', [i], false)))
		{
			cpuControlled = i;
			if (playerStrumLine != null)
			{
				playerStrumLine.cpuControlled = i;
			}
			setOnLuas('botPlay', cpuControlled);
		}
		return cpuControlled;
	}
	public var practiceMode:Bool = false;

	private var botplaySine:Float = 0;

	public var iconP1:HealthIcon;
	public var iconP2:HealthIcon;
	public var baseScaleIcons:Float = 1;

	public var camGame:CoolCamera;
	public var camHUD:CoolCamera;
	public var camOther:FlxCamera;
	public var camControls:FlxCamera;
	public var camPAUSE:FlxCamera;
	public var cameraSpeed:Float = 1;
	public var middleScrollMode:Bool = ClientPrefs.middleScroll;

	var dialogue:Array<String> = ['blah blah blah', 'coolswag'];
	var dialogueJson:DialogueFile = null;

	public var songScore:Int = 0;
	public var songHits:Int = 0;
	public var songMisses:Int = 0;

	public static var campaignScore:Int = 0;
	public static var campaignMisses:Int = 0;
	public static var seenCutscene:Bool = false;
	public static var deathCounter:Int = 0;

	public var defaultCamZoom(default, set):Float = 1;
	public var defaultCamHUDZoom(default, set):Float = 1;
	public var mainDefaultZoom(default, set):Float = 1;

	inline function set_defaultCamZoom(e:Float):Float
	{
		defaultCamZoom = e;
		camGame.defaultZoom = e * mainDefaultZoom;
		return e;
	}
	inline function set_defaultCamHUDZoom(e:Float):Float
	{
		defaultCamHUDZoom = e;
		camHUD.defaultZoom = e * mainDefaultZoom;
		return e;
	}

	inline function set_mainDefaultZoom(e:Float):Float
	{
		mainDefaultZoom = e;
		camGame.defaultZoom = defaultCamZoom * e;
		camHUD.defaultZoom = defaultCamHUDZoom * e;
		return mainDefaultZoom = e;
	}

	// how big to stretch the pixel art assets
	public static var daPixelZoom:Float = 6;

	public var inCutscene:Bool = false;
	public var skipCountdown:Bool = false;

	var songLength:Float = 0;

	// i have no fucking idea why i made this - richTrash21
	public var bfCamOffset:FlxPoint  = FlxPoint.get();
	public var dadCamOffset:FlxPoint = FlxPoint.get();
	public var gfCamOffset:FlxPoint  = FlxPoint.get();

	// DEPRECATED!!!
	public var boyfriendCameraOffset(get, set):Array<Float>;
	public var opponentCameraOffset(get, set):Array<Float>;
	public var girlfriendCameraOffset(get, set):Array<Float>;

	@:noCompletion inline function get_boyfriendCameraOffset():Array<Float>
		return [bfCamOffset.x, bfCamOffset.y];

	@:noCompletion inline function get_opponentCameraOffset():Array<Float>
		return [dadCamOffset.x, dadCamOffset.y];

	@:noCompletion inline function get_girlfriendCameraOffset():Array<Float>
		return [gfCamOffset.x, gfCamOffset.y];

	@:noCompletion inline function set_boyfriendCameraOffset(a:Array<Float>):Array<Float> {
		if (a != null && a.length > 1) bfCamOffset.set(a[0], a[1]);
		return a;
	}
	@:noCompletion inline function set_opponentCameraOffset(a:Array<Float>):Array<Float> {
		if (a != null && a.length > 1) dadCamOffset.set(a[0], a[1]);
		return a;
	}
	@:noCompletion inline function set_girlfriendCameraOffset(a:Array<Float>):Array<Float> {
		if (a != null && a.length > 1) gfCamOffset.set(a[0], a[1]);
		return a;
	}

	// Discord RPC variables
	// var storyDifficultyText:String = "";
	public var detailsText:String = "";
	public var detailsSong:String = "";
	public var detailsPausedText:String = "";
	public var detailsGameOverText:String = "";
	public var discordSmallImage(get, default):String = null;
	function get_discordSmallImage()
	{
		return discordSmallImage.isNullOrEmpty() ? (iconP2?.getCharacter() ?? "") : discordSmallImage;
	}
	public var curPortrait:String = null;

	// Lua shit
	public static var instance(default, null):PlayState;

	public var scriptPack:ScriptPackPlayState;
	#if LUA_ALLOWED
	public var luaArray(get, set):Array<FunkinLua>;
	@:noCompletion inline function get_luaArray() return scriptPack.luaArray;
	@:noCompletion inline function set_luaArray(e) return scriptPack.luaArray = e;
	#end
	#if HSCRIPT_ALLOWED
	public var hscriptArray(get, set):Array<HScript>;
	@:noCompletion inline function get_hscriptArray() return scriptPack.hscriptArray;
	@:noCompletion inline function set_hscriptArray(e) return scriptPack.hscriptArray = e;
	#end

	private var luaDebugGroup:FlxTypedGroup<DebugLuaText>;

	public var introSoundsSuffix:String = '';

	// Less laggy controls
	public var keysArray:Array<String> = [
		'4K_note_left',
		'4K_note_down',
		'4K_note_up',
		'4K_note_right'
	];
	public var singAnimations:Array<String> = ['LEFT', 'DOWN', 'UP', 'RIGHT'];

	var precacheList:Map<String, String> = new Map<String, String>();

	public var healthbarStyle:String = 'sadsdxfgfdsfxzcjhgsajhdvgxzbcgvjhasdgjhxzcvghzxvchgxzvch';

	// var replayHandler:ReplayHandler;
	// var replayMode:Bool;

	public var songName:String;

	public var loadingSubState:LoadingState;

	public var isReloadedState:Bool = false;

	public function new(replay:Bool = false){
		// replayMode = replay;
		isReloadedState = Type.getClass(FlxG.state) == PlayState;
		// @:privateAccess trace(Type.getClassName(Type.getClass(FlxG.state)), Type.getClassName(Type.getClass(FlxG.game._nextState)));
		super();
	}

	#if (windows && target.threaded)
	@:noCompletion var isMainThreadFrozen:Bool = false;
	@:noCompletion function checkMainThreadActivity()
	{
		isMainThreadFrozen = false;
	}
	#end
	public override function create(){
		// if (Main.canClearMem) Paths.clearUnusedMemory();
		Main.canClearMem = false;
		trace('Start State.');
		/*
		subStateClosed.add(i -> {
			if (paused)
			{
				#if DEV_BUILD
				if (!isFreezed)
				{
					setPause(false);
				}
				#else
				setPause(false);
				#end
			}
		});
		subStateOpened.add(i -> {
			if (Std.isOfType(i, PauseSubState))
			{
				setPause(true);
			}
		});
		*/

		// Fix skipping song
		// todo: Fix window bug and apply it to Lime
		/*
		#if (windows && target.threaded)
		var stillNotCreated:Bool = true;
		FlxG.signals.postStateSwitch.addOnce(() -> stillNotCreated = false);
		ThreadUtil.createLoopingThread("PlayState.FixWindowDrag", () -> {
			@:privateAccess
			if (!stillNotCreated && !FlxG.game._lostFocus && active && exists && !cpuControlled && canPause && !paused)
			{
				if (isMainThreadFrozen)
				{
					Sys.println("опа");
					if (!ScriptPack.resultIsStop(callOnScripts('onPause', null, true)))
						openPauseMenu(); // idk
				}
				else
				{
					isMainThreadFrozen = true;
				}
			}
		}, 0.0, 0.1);
		FlxG.signals.preUpdate.add(checkMainThreadActivity);
		#end
		*/

		playbackRate = ClientPrefs.getGameplaySetting('songspeed', 1);

		// for lua
		instance = this;

		mainTweenManager = FlxTween.globalManager;
		mainTimerManager = FlxTimer.globalManager;
		FlxG.plugins.addPlugin(pauseTweenManager);
		FlxG.plugins.addPlugin(pauseTimerManager);

		scriptPack = new ScriptPackPlayState();

		if (FlxG.sound.music != null) FlxG.sound.music.stop();

		// Gameplay settings
		healthDrainPercent = ClientPrefs.getGameplaySetting('healthdrainperc', 0);
		healthGain = ClientPrefs.getGameplaySetting('healthgain', 1);
		healthLoss = ClientPrefs.getGameplaySetting('healthloss', 1);
		instakillOnMiss = ClientPrefs.getGameplaySetting('instakill', false);
		practiceMode = ClientPrefs.getGameplaySetting('practice', false);
		cpuControlled = null;

		// var gameCam:FlxCamera = FlxG.camera;
		FlxG.cameras.reset(camGame = new CoolCamera(1));
		camHUD = new CoolCamera(0);
		camOther = new FlxCamera();
		camOther.bgColor.alpha = 0;
		camControls = new FlxCamera();
		camControls.bgColor.alpha = 0;
		camPAUSE = new FlxCamera();
		camPAUSE.bgColor.alpha = 0;

		songGroup = new FlxSoundGroup();

		FlxG.cameras.setDefaultDrawTarget(camGame, true);
		FlxG.cameras.add(camHUD, false);
		FlxG.cameras.add(camOther, false);
		FlxG.cameras.add(camControls, false);
		FlxG.cameras.add(camPAUSE, false);

		// grpNoteSplashes = new FlxTypedGroup<NoteSplash>();
		mainTweenManager.active = mainTimerManager.active = false;

		#if TOUCH_CONTROLS
		createHitbox(false, camControls);
		#end

		function addCallback(loadState:LoadingState, id:String, func:() -> Void)
		{
			if (loadState == null)
			{
				func();
				return;
			}
			//trace('Add \'$id\'');
			var callback = loadState.callbacks.add(id);
			if (callback == null) return;
			loadState.funcsPrepare.push(state -> callback(func));
		}
		final callbacks:Array<LoadingState.LoadingStateCallback> = [
			addCallback.bind(_, "1", () -> {
				if (SONG == null) SONG = Song.loadFromJson('tutorial');

				Conductor.mapBPMChanges(SONG);
				Conductor.bpm = SONG.bpm;
				songName = Paths.formatToSongPath(SONG.song);
				curStage = SONG.stage;

				if (SONG.stage == null || SONG.stage.length < 1){
					// switch (songName){
					// 	default:
							curStage = 'stage';
					// }
				}
			}),
			addCallback.bind(_, "Load Stage.", () -> {
				SONG.stage = curStage;
				stageData = StageData.getStageFile(curStage);
				if (stageData == null){ // Stage couldn't be found, create a dummy stage for preventing a crash
					stageData = StageData.dummy();
				}
				StageData.forceNextDirectory = stageData.directory;

				if (stageData.isPixelStage == true)
					stageData.typeNotes = "pixel";
				stageData.typeNotesAbstract = stageData.typeNotes;
				defaultCamZoom = stageData.defaultZoom;
				isPixelStage = stageData.isPixelStage;
				BF_X = stageData.boyfriend[0];
				BF_Y = stageData.boyfriend[1];
				GF_X = stageData.girlfriend[0];
				GF_Y = stageData.girlfriend[1];
				DAD_X = stageData.opponent[0];
				DAD_Y = stageData.opponent[1];

				if (stageData.camera_speed != null) cameraSpeed = stageData.camera_speed;

				boyfriendCameraOffset = stageData.camera_boyfriend;
				if (boyfriendCameraOffset == null) boyfriendCameraOffset = [0, 0]; // Fucks sake should have done it since the start :rolling_eyes:

				opponentCameraOffset = stageData.camera_opponent;
				if (opponentCameraOffset == null) opponentCameraOffset = [0, 0];

				girlfriendCameraOffset = stageData.camera_girlfriend;
				if (girlfriendCameraOffset == null) girlfriendCameraOffset = [0, 0];

				boyfriendGroup = new FlxSpriteGroup(BF_X, BF_Y);
				dadGroup = new FlxSpriteGroup(DAD_X, DAD_Y);
				gfGroup = new FlxSpriteGroup(GF_X, GF_Y);

				// for character precaching
				GameOverSubstate.resetVariables();

				modManager = new ModManager(this);
				modManager.active = false;

				switch (curStage){
					case 'stage':
						var bg:BGSprite = new BGSprite('stageback', -600, -200);
						add(bg);

						var stageFront:BGSprite = new BGSprite('stagefront', -650, 600);
						stageFront.setGraphicSize(stageFront.width * 1.1);
						stageFront.updateHitbox();
						add(stageFront);
						if (!ClientPrefs.lowQuality){
							var stageLight:BGSprite = new BGSprite('stage_light', -125, -100);
							stageLight.setGraphicSize(stageLight.width * 1.1);
							stageLight.updateHitbox();
							add(stageLight);
							var stageLight:BGSprite = new BGSprite('stage_light', 1225, -100);
							stageLight.setGraphicSize(stageLight.width * 1.1);
							stageLight.updateHitbox();
							stageLight.flipX = true;
							add(stageLight);

							var stageCurtains:BGSprite = new BGSprite('stagecurtains', -500, -300, 1.2, 1.2);
							stageCurtains.setGraphicSize(stageCurtains.width * 0.9);
							stageCurtains.updateHitbox();
							add(stageCurtains);
						}
				}

				if (isPixelStage) introSoundsSuffix = '-pixel';

				if(stageData.objects != null && stageData.objects.length > 0)
				{
					var list:Map<String, FlxSprite> = StageData.addObjectsToState(stageData.objects, !stageData.hide_girlfriend ? gfGroup : null, dadGroup, boyfriendGroup, this);
					for (key => spr in list)
						if(!StageData.reservedNames.contains(key))
							variables.set(key, spr);
				}
				else
				{
					add(gfGroup);
					add(dadGroup);
					add(boyfriendGroup);
				}

				luaDebugGroup = new FlxTypedGroup<DebugLuaText>();
				luaDebugGroup.cameras = [camOther];
				add(luaDebugGroup);
			}),
			addCallback.bind(_, "Load Global Scripts.", () -> {
				// "GLOBAL" SCRIPTS
				loadScriptsFromFolder('scripts');
			}),
			addCallback.bind(_, "Load Stage Scripts.", () -> {
				// STAGE SCRIPTS
				loadScript('stages/$curStage');
			}),
			addCallback.bind(_, "Load Characters.", () -> {
				var gfVersion:String = SONG.gfVersion;
				if (gfVersion == null || gfVersion.length < 1)
					SONG.gfVersion = gfVersion = 'gf'; // Fix for the Chart Editor

				// trace('Load GF.');
				if (!stageData.hide_girlfriend){
					gf = new Character(0, 0, gfVersion);
					startCharacterPos(gf);
					gf.scrollFactor.set(0.95, 0.95);
					gfGroup.add(gf);
					startCharacterLua(gf);
					gfMap.set(gf.curCharacter, gf);
				}

				// trace('Load Dad.');
				dad = new Character(0, 0, SONG.player2);
				startCharacterPos(dad, true);
				dadGroup.add(dad);
				startCharacterLua(dad);
				dadMap.set(dad.curCharacter, dad);

				// trace('Load Boyfriend.');
				boyfriend = new Character(0, 0, SONG.player1, true);
				startCharacterPos(boyfriend);
				boyfriendGroup.add(boyfriend);
				startCharacterLua(boyfriend);
				playerCharacters = [boyfriend];
				boyfriendMap.set(boyfriend.curCharacter, boyfriend);

				GameOverSubstate.applyFromCharacter(boyfriend);
			}),
			addCallback.bind(_, "Load Dialogue.  (ignore)", () -> {
				var file:String = Paths.json(songName + '/dialogue'); // Checks for json/Psych Engine dialogue
				if (Assets.exists(file)) dialogueJson = DialogueBoxPsych.parseDialogue(file);

				// var file:String = Paths.txt(songName + '/' + songName + 'Dialogue'); // Checks for vanilla/Senpai dialogue
				// if (Assets.exists(file)) dialogue = CoolUtil.coolTextFile(file);

				Conductor.songPosition = -5000 / Conductor.songPosition;
			}),
			addCallback.bind(_, "idk", () -> {
				strumLine = FlxPoint.get(middleScrollMode ? STRUM_X_MIDDLESCROLL : STRUM_X, 50);
				if (ClientPrefs.downScroll) strumLine.y = FlxG.height - 150;

				add(healthBarGroup = new FlxSpriteGroup());

				add(timeBarGroup = new FlxSpriteGroup());

				iconsGroup = new FlxTypedSpriteGroup<HealthIcon>();
				iconsGroup.add(iconP1 = new HealthIcon(boyfriend.healthIcon, true));
				iconsGroup.add(iconP2 = new HealthIcon(dad.healthIcon, false));
				iconsGroup.visible = !ClientPrefs.hideHud;

				strumLineNotes = new FlxTypedGroup<StrumNote>();
				strumLineNotes.kill();

				// sustainNotes = new FlxTypedGroup<Note>();
				// regularNotes = new FlxTypedGroup<Note>();

				#if NOTE_BACKWARD_COMPATIBILITY
				notes = new FlxTypedGroup<Note>();
				// notes.memberRemoved.add(i -> {
				// 	regularNotes.remove(i, true);
				// 	sustainNotes.remove(i, true);
				// });
				#end

				// с нотами придётся ебаться, эх 😢
				playerStrumLine = new StrumLine(true, SONG.splashSkin, SONG.holdCoverSkin, modManager);
				opponentStrumLine = new StrumLine(false, SONG.splashSkin, SONG.holdCoverSkin, modManager);
				playerStrumLine.cpuControlled = @:bypassAccessor cpuControlled;
				playerStrums = playerStrumLine.strumNotes;
				opponentStrums = opponentStrumLine.strumNotes;
				playerStrumLine.cameras = opponentStrumLine.cameras = [camHUD];
				add(opponentStrumLine);
				add(playerStrumLine);

				add(strumLineNotes);
				// add(regularNotes);
				// sortStrumsNotes();
				// add(grpNoteSplashes);

				#if VIDEOS_ALLOWED
				// reusable player, finally!!
				videoPlayer = new VideoSprite();
				videoPlayer.camera = camOther;
				videoPlayer.bitmap.onEndReached.add(onEndVideo);
				videoPlayer.bitmap.onOpening.add(onPlayVideo, true); // only when sprite was just created
				videoPlayer.bitmap.onFormatSetup.add(onPlayVideo); // let graphic change first and then revive the sprite
				videoPlayer.bitmap.onEncounteredError.add(onVideoError);
				// insert(members.indexOf(subtitles), videoPlayer);
				add(videoPlayer);
				#end

				// precacheList.set(
				// 	(PlayState.SONG.splashSkin.isNullOrEmpty()) ?
				// 	Constants.DEFAULT_NOTESPLASH_SKIN : PlayState.SONG.splashSkin, 'image');
			}),
			addCallback.bind(_, "Load Data Scripts.", () -> {
				// SONG SPECIFIC SCRIPTS
				loadScriptsFromFolder(Constants.SONG_CHART_FILES_FOLDER + '/$songName');

			}),
			addCallback.bind(_, "Load Song.", () -> {
				setupStrumLine(opponentStrumLine);
				setupStrumLine(playerStrumLine);
				generateSong();

				// startCountdown();

				if (prevCamFollow != null)
				{
					camFollow = prevCamFollow;
					prevCamFollow = null;
				}
				else
				{
					final camPos:FlxPoint = FlxPoint.get();

					var point:FlxPoint = setCharCamOffset("boyfriend", false);
					camPos.addPoint(point);
					if (dad.curCharacter.startsWith('gf')){
						dad.setPosition(GF_X, GF_Y);
						if (gf != null)
							gf.visible = false;
					}
					point = setCharCamOffset("dad", false);
					camPos.addPoint(point);
					if(gf != null)
					{
						point = setCharCamOffset("gf", false);
						camPos.addPoint(point);
						camPos.scale(1 / 3);
					}
					else
					{
						camPos.scale(0.5);
					}

					camFollow = camPos;
				}

				if (prevCamFollowPos != null)
				{
					camFollowPos = prevCamFollowPos;
					prevCamFollowPos = null;
				}
				else
				{
					camFollowPos = new FlxObject(camFollow.x, camFollow.y, 2, 2);
				}

				add(camFollowPos);

				camGame.follow(camFollowPos, LOCKON, Math.POSITIVE_INFINITY);
				camGame.zoom = defaultCamZoom;
				camGame.focusOn(camFollow);
				// camGame.focusOn(camFollowPos.getPosition(FlxPoint.wea()));

				camGame.followLerp = camHUD.followLerp = Math.POSITIVE_INFINITY;
				FlxG.worldBounds.set(0, 0, FlxG.width, FlxG.height);
			}),
			addCallback.bind(_, "Load HUD.", () -> {
				// After all characters being loaded, it makes then invisible 0.01s later so that the player won't freeze when you change characters
				// add(strumLine);

				// FlxG.fixedTimestep = false;

				//switchHud('colorsadventurealpha');
				// if (SONG.song == 'South')
				// FlxG.camera.alpha = 0.7;
				// UI_camera.zoom = 1;

				// cameras = [FlxG.cameras.list[1]];

				timeBarGroup.cameras = healthBarGroup.cameras = [camHUD];

				health = (healthBounds.min + healthBounds.max) / 2;

				switchHud();

				startingSong = true;

				moveCameraSection();
			}),
			addCallback.bind(_, "Precache.", () -> {
				if (ClientPrefs.hitsoundVolume > 0) precacheList.set('hitsound', 'sound');
				precacheList.set('missnote1', 'sound');
				precacheList.set('missnote2', 'sound');
				precacheList.set('missnote3', 'sound');

				for (key => type in precacheList)
				{
					switch (type)
					{
						case "sound": Paths.sound(key);
						case "music": Paths.music(key);
						case "image": graphicCache.cache(AssetsPaths.image(key));
					}
				}
				precacheList.clear();
				if (loadingSubState != null)
					loadingSubState.canLeave = true; // IMPORTANT
			})
		];

		final lastCallback:LoadingState.LoadingStateCallback = subState -> { // On completed
			// subState?.close();

			// seenCutscene = isStoryMode && !seenCutscene;

			FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
			FlxG.stage.addEventListener(KeyboardEvent.KEY_UP, onKeyRelease);

			mainTweenManager.active = mainTimerManager.active = true;
			persistentDraw = persistentUpdate = true;

			startCountdown();

			RecalculateRating();

			callOnScripts('onCreatePost');

			// for (key => type in precacheList)
			// {
			// 	switch (type)
			// 	{
			// 		case "sound": Paths.sound(key);
			// 		case "music": Paths.music(key);
			// 		case "image": graphicCache.cache(AssetsPaths.image(key));
			// 	}
			// }

			Paths.clearUnusedMemory();

			trace('Done!');

			if (eventNotes.length < 1)
				checkEventNote();
			// traceMap(@:privateAccess FlxG.bitmap._cache);
			checkOnFocusLost();

			updateHealthIcons();

			// precacheList.clear();


			#if desktop
			// Updating Discord Rich Presence.

			// String that contains the mode defined here so it isn't necessary to call changePresence for each mode
			// detailsText = isStoryMode ? "Story Mode: " + WeekData.getCurrentWeek().weekName : "Freeplay";
			// detailsText = "Freeplay";
			// detailsPausedText = "Paused - " + detailsText;
			// detailsGameOverText = "Game Over - " + detailsText;

			detailsText = "Playing";
			detailsPausedText = "Paused";
			detailsGameOverText = "Game Over";

			detailsSong = SONG.display;
			if (cpuControlled)
			{
				detailsSong += ' - Botplay';
			}

			resetRPC();
			WindowUtil.endfix = ' - $detailsSong';
			#end
		}

		// if (isReloadedState)
		{
			callbacks.push(lastCallback);
			while(callbacks.length > 0)
			{
				callbacks.shift()(null);
			}
		}
		/*
		else // TODO: Fix openfl issue with function 'getMatriсes'
		{
			openSubState(loadingSubState = new LoadingState(callbacks, lastCallback));
			if (_requestSubStateReset)
			{
				_requestSubStateReset = false;
				resetSubState();
			}
			persistentDraw = persistentUpdate = false;
		}
		*/
		super.create();
	}

	function set_playbackRate(value:Float):Float {
		playbackRate = FlxG.timeScale = value;
		for (i in FlxG.sound.list) if (i != null) i.pitch = i.pitch;
		Conductor.callculateSafeZoneOffset();
		resetRPC();
		// setOnLuas('playbackRate', playbackRate);
		return value;
	}
	/*
		function set_playbackRate(value:Float):Float
			{
				if(generatedMusic)
				{
					if(vocals != null) vocals.pitch = value;
					FlxG.sound.music.pitch = value;
				}
				FlxG.timeScale = value;
				//FlxAnimationController.globalSpeed = value;
				//trace('Anim speed: ' + FlxAnimationController.globalSpeed);
				Conductor.callculateSafeZoneOffset();
				setOnLuas('FlxG.timeScale', FlxG.timeScale);
				return value;
			}
	 */

	public function cachePause(){
		precacheList.set('alphabet', 'image');
		Paths.music(PauseSubState.songName ?? "breakfast");
	}
	public function cacheCountdown(){
		for (asset in (isPixelStage ? ['pixelUI/ready-pixel', 'pixelUI/set-pixel', 'pixelUI/date-pixel'] : ['ready', 'set', 'go']))
			precacheList.set(asset, 'image');

		Paths.sound('intro3' + introSoundsSuffix);
		Paths.sound('intro2' + introSoundsSuffix);
		Paths.sound('intro1' + introSoundsSuffix);
		Paths.sound('introGo' + introSoundsSuffix);
	}

	public function cachePopUpScore(){
		var pixelShitPart1:String = '';
		var pixelShitPart2:String = '';
		if (isPixelStage)
		{
			pixelShitPart1 = 'pixelUI/';
			pixelShitPart2 = '-pixel';
		}
		for (i in ["sick", "good", "bad", "shit", "combo"])
			precacheList.set(pixelShitPart1 + i + pixelShitPart2, 'image');

		for (i in 0...10)
			precacheList.set(pixelShitPart1 + 'num' + i + pixelShitPart2, 'image');
	}

	public function setupStrumLine(strumLine:StrumLine)
	{
		if (strumLine == null || ScriptPack.resultIsStop(callOnHScript("onPreSetupStrumLine", [strumLine])))
			return;

		if (!strumLines.contains(strumLine))
			strumLines.push(strumLine);

		#if NOTE_BACKWARD_COMPATIBILITY
		strumLine.onSpawnNote.add(notes.insert.bind(0, _));
		strumLine.onSpawnNote.add(unspawnNotes.remove.bind(_));
		strumLine.onDestroyNote.add(notes.remove.bind(_, true));
		#end

		strumLine.onSpawnNote.add(onSpawnNoteStrumLine.bind(_, strumLine));

		strumLine.onUpdateNote.add(onUpdateNoteStrumLine.bind(_, _, _, _, strumLine));

		strumLine.onMissNote.add(onMissNoteStrumLine.bind(_, strumLine));

		callOnHScript("onSetupStrumLine", [strumLine]);
	}

	function onSpawnNoteStrumLine(dunceNote:Note, strumLine:StrumLine)
	{
		callOnLuas('onSpawnNote', [0, dunceNote.noteData, dunceNote.noteType, dunceNote.isSustainNote, dunceNote.strumTime]);
		callOnHScript('onSpawnNote', [dunceNote]);
	}
	function onUpdateNoteStrumLine(daNote:Note, time:Float, speed:Float, timeScale:Float, strumLine:StrumLine)
	{
		if (!daNote.noteWasHit && daNote.canBeHit && !daNote.ignoreNote && !daNote.ignorePress)
		{
			// if (daNote.mustPress)
			if (strumLine.isPlayer)
			{
				if((strumLine.cpuControlled || daNote.cpuControl) && (daNote.isSustainNote || daNote.strumTime <= time))
					goodNoteHit(daNote, strumLine);
			}
			else if (daNote.wasGoodHit)
			{
				opponentNoteHit(daNote, strumLine);
			}
		}

		if (daNote.clipRect != null && daNote.clipRect.isEmpty)
			daNote.disconnectHoldCover();
	}
	function onMissNoteStrumLine(daNote:Note, strumLine:StrumLine)
	{
		(daNote.mustPress ? noteMiss : noteOpponentMiss)(daNote, strumLine, false);
	}

	public var runtimeShaders(get, never):Map<String, Array<String>>;
	@:noCompletion inline function get_runtimeShaders() return scriptPack.runtimeShaders;
	@:noCompletion public inline function createRuntimeShader(name:String, ?glslVersion:Int = 110):flixel.addons.display.FlxRuntimeShader
		return scriptPack.createRuntimeShader(name, glslVersion);

	@:noCompletion public inline function initLuaShader(name:String, ?shader:String, ?glslVersion:Int = 110):Bool
		return scriptPack.initLuaShader(name, shader, glslVersion);

	function loadScriptsFromFolder(folder:String){
		#if (LUA_ALLOWED || HSCRIPT_ALLOWED)
		#if MODS_ALLOWED
		var filesPushed:Array<String> = [];
		#end
		for (i in AssetsPaths.getFolderContent(folder, true))
		{
			i = 'assets/$i';
			#if MODS_ALLOWED
			if (!filesPushed.contains(i))
			#end
			{
				#if LUA_ALLOWED
				if (AssetsPaths.LUA_REGEX.match(i)){
					scriptPack.loadLuaScript(i);
					#if MODS_ALLOWED
					filesPushed.push(i);
					#end
				}
				#end
				#if HSCRIPT_ALLOWED
				if (AssetsPaths.HX_REGEX.match(i)){
					loadHScript(i);
					#if MODS_ALLOWED
					filesPushed.push(i);
					#end
				}
				#end
			}
		}
		#end
	}
	function loadScript(scriptFile:String)
	{
		#if LUA_ALLOWED
		final luaTL:String = AssetsPaths.getPath(scriptFile + ".lua");
		if (Assets.exists(luaTL))	scriptPack.loadLuaScript(luaTL);
		#end
		#if HSCRIPT_ALLOWED
		final hxTL:String = AssetsPaths.getPath(scriptFile + ".hx");
		if (Assets.exists(hxTL))	loadHScript(hxTL);
		#end
	}

	public function loadHScript(path:String, ?classSwag:Dynamic, ?extraParams:Map<String, Dynamic>){
		if (classSwag == null) classSwag = PlayState.instance;
		final script = HScript.loadStateModule(path, classSwag, extraParams).getPlayStateParams();
		scriptPack.hscriptArray.push(script);
		script.execute();
		return script;
	}

	function set_songSpeed(value:Float):Float
	{
		// if (generatedMusic)
		// {
		// 	var ratio:Float = value / songSpeed; // funny word huh
		// 	notes.forEach(note -> note.resizeByRatio(ratio));
		// 	for (note in unspawnNotes) note.resizeByRatio(ratio);
		// }
		songSpeed = value;
		noteKillOffset = 350;
		return value;
	}
	public dynamic function addTextToDebug(text:String, color:FlxColor)
	{
		var newText:DebugLuaText = luaDebugGroup.recycle(DebugLuaText);
		newText.text = text;
		newText.color = color;
		newText.disableTime = 6;
		newText.alpha = 1;
		newText.setPosition(10, 8 - newText.height);

		luaDebugGroup.forEachAlive(spr -> spr.y += newText.height + 2);
	}

	public var dadColor:FlxColor = FlxColor.RED;
	public var bfColor:FlxColor = FlxColor.LIME;
	public dynamic function healthBarUpdate(elapsed:Float) {}
	public function clearHudMembers()
	{
		callOnHScript('onClearHud', [healthbarStyle]);
		timeBarGroup.clear();
		healthBarGroup.clear();
		baseScaleIcons = 1;
		healthBarUpdate = null;
		callOnHScript('onClearHudPost', [healthbarStyle]);
	}

	// TODO: REWRITE TO CLASS HUD
	public function switchHud(?newHud:String, ?MUSTupdate:Null<Bool>)
	{
		if (MUSTupdate == null) MUSTupdate = true;
		if (newHud == null)
		{
			newHud = "";
		}
		else
		{
			newHud = newHud.toLowerCase().trim();
		}
		if (newHud != healthbarStyle && MUSTupdate){
			clearHudMembers();
			healthbarStyle = newHud;
			final a = callOnHScript('onUpdateHud');
			if (!ScriptPack.resultIsStop(a))
			{
				switch(healthbarStyle)
				{
					default: // Add here your hud
				}
			}
			var result = callOnHScript('onUpdateHudPost');
			if (!ScriptPack.resultIsStop(result))
			{
				if (healthBarUpdate != null) healthBarUpdate(FlxG.elapsed);
				reloadHealthBarColors(true);
				if (updateScore != null) updateScore(false, true);
			}
		}
	}
	public dynamic function flipHealthBar() iconsGroup.flipX = !iconsGroup.flipX;

	public function reloadHealthBarColors(?customBFColor:Null<Int>, ?customDadColor:Null<Int>, ?start:Bool = false)
	{
		callOnScripts('onUpdateHealthBarColors', []);

		bfColor = customBFColor ?? boyfriend.healthColor;

		dadColor = customDadColor ?? (SONG.notes[curSection] == null || !SONG.notes[curSection].gfSection || gf == null ?
			dad.healthColor
		:
			gf.healthColor);

		updateColorsInHealthBar(start);

		callOnScripts('onUpdateHealthBarColorsPost', []);
	}
	public dynamic function updateColorsInHealthBar(start){
		/*
		if (healthBar == null) return;
		healthBar.createFilledBar(dadColor, bfColor);
		healthBar.updateBar();
		*/
	}
	public function addCharacterToList(newCharacter:String, type:Int){
		switch (type)
		{
			case 0:
				if (!boyfriendMap.exists(newCharacter))
				{
					var newBoyfriend:Character = new Character(0, 0, newCharacter, true);
					boyfriendMap.set(newCharacter, newBoyfriend);
					boyfriendGroup.add(newBoyfriend);
					newBoyfriend.alpha = 0.00001;
					startCharacterPos(newBoyfriend);
					startCharacterLua(newBoyfriend);
				}
			case 1:
				if (!dadMap.exists(newCharacter))
				{
					var newDad:Character = new Character(0, 0, newCharacter);
					dadMap.set(newCharacter, newDad);
					dadGroup.add(newDad);
					newDad.alpha = 0.00001;
					startCharacterPos(newDad, true);
					startCharacterLua(newDad);
				}
			case 2:
				if (gf != null && !gfMap.exists(newCharacter))
				{
					var newGf:Character = new Character(0, 0, newCharacter);
					newGf.scrollFactor.set(0.95, 0.95);
					gfMap.set(newCharacter, newGf);
					gfGroup.add(newGf);
					newGf.alpha = 0.00001;
					startCharacterPos(newGf);
					startCharacterLua(newGf);
				}
		}
	}

	function startCharacterLua(char:Character)
	{
		var doPush:Bool = false;
		var file:String;
		#if LUA_ALLOWED
		file = AssetsPaths.getPath('characters/' + char.curCharacter + '.lua');
		if (doPush = Assets.exists(file))
		{
			for (script in luaArray)
			{
				if (script.scriptName == file)
				{
					doPush = false;
					break;
				}
			}
		}
		if (doPush) scriptPack.loadLuaScript(file);
		#end

		#if HSCRIPT_ALLOWED
		file = AssetsPaths.getPath('characters/' + char.curCharacter + '.hx');

		if (doPush = Assets.exists(file))
		{
			for (script in hscriptArray)
			{
				if (script.scriptName == file)
				{
					doPush = false;
					break;
				}
			}
		}

		if (doPush) loadHScript(file, char, ['PlayState' => PlayState.instance]);
		#end
	}

	public #if !LUA_ALLOWED inline #end function getLuaObject(tag:String, text:Bool = true):FlxSprite
	{
		#if LUA_ALLOWED
		if (modchartSprites.exists(tag)) return modchartSprites.get(tag);
		if (text && modchartTexts.exists(tag)) return modchartTexts.get(tag);
		#end
		return null;
	}

	function startCharacterPos(char:Character, ?gfCheck:Bool = false)
	{
		if (gfCheck && char.curCharacter.startsWith('gf')) // IF DAD IS GIRLFRIEND, HE GOES TO HER POSITION
		{
			char.setPosition(GF_X, GF_Y);
			char.scrollFactor.set(0.95, 0.95);
			char.danceEveryNumBeats = 2;
		}
	}

	public var playingVideo(get, never):Bool;
	@:noCompletion inline function get_playingVideo():Bool
		return #if VIDEOS_ALLOWED videoPlayer != null && videoPlayer.bitmap != null && videoPlayer.bitmap.isPlaying #else false #end;

	public var videoPlayer:#if VIDEOS_ALLOWED VideoSprite #else Dynamic #end;

	#if VIDEOS_ALLOWED
	public static function initVideoSpriteToSong(spr:VideoSprite, ?targetTime:Null<Float>)
	{
		targetTime ??= Conductor.songPosition;
		spr.vSynsPos = () -> Math.floor(Conductor.songPosition - targetTime);
	}

	@:noCompletion var __reviveVideo = false;

	@:noCompletion function onPlayVideo()
	{
		if (__reviveVideo)
		{
			videoPlayer.exists = true;
			__reviveVideo = false;
		}
		initVideoSpriteToSong(videoPlayer);
	}

	@:noCompletion function onEndVideo()
	{
		startAndEnd();

		videoPlayer.stop();
		videoPlayer.exists = false;
	}

	@:noCompletion function onVideoError(msg:String)
	{
		Log('Video Err: $msg', RED);
		onEndVideo();
	}
	#end

	public function startVideo(name:String, antialias:Bool = true){
		#if VIDEOS_ALLOWED
		inCutscene = true;

		final isHttps = name.contains('://');
		final filepath:String = isHttps ? name : Paths.video(name);
		if (!isHttps && !Assets.exists(filepath))
		{
			FlxG.log.warn('Couldnt find video file: ' + name);
			startAndEnd();
			return false;
		}
		__reviveVideo = true;
		videoPlayer.load(filepath);
		videoPlayer.play();
		videoPlayer.antialiasing = antialias;
		#end
		return true;
	}

	function startAndEnd()
	{
		if (endingSong)
			endSong();
		else
			startCountdown();
	}

	var dialogueCount:Int = 0;

	public var psychDialogue:DialogueBoxPsych;

	// You don't have to add a song, just saying. You can just do "startDialogue(dialogueJson);" and it should work
	public function startDialogue(dialogueFile:DialogueFile, ?song:String):Void
	{
		// TO DO: Make this more flexible, maybe?
		if (psychDialogue != null)
			return;

		if (dialogueFile.dialogue.length > 0){
			inCutscene = true;
			precacheList.set('dialogue', 'sound');
			precacheList.set('dialogueClose', 'sound');
			psychDialogue = new DialogueBoxPsych(dialogueFile, song);
			// psychDialogue.scrollFactor.set();
			if (endingSong)
			{
				psychDialogue.finishThing = function()
				{
					psychDialogue = null;
					endSong();
				}
			}
			else
			{
				psychDialogue.finishThing = function()
				{
					psychDialogue = null;
					startCountdown();
				}
			}
			psychDialogue.nextDialogueThing = startNextDialogue;
			psychDialogue.skipDialogueThing = skipDialogue;
			psychDialogue.cameras = [camHUD];
			add(psychDialogue);
		}
		else
		{
			FlxG.log.warn('Your dialogue file is badly formatted!');
			if (endingSong)
				endSong();
			else
				startCountdown();
		}
	}

	public var startTimer:FlxTimer;
	public var finishTimer:FlxTimer = null;

	// For being able to mess with the sprites on Lua
	public var startOnTime:Float = 0;

	// var thisTimer:FlxTimer = null;
	// var songTitle:SongTitle;
	public var swaCounter:Int = 0;

	public dynamic function createCountSprite(name:String, sound:String):FlxSprite
	{
		if (sound != null)
			FlxG.sound.play(Paths.sound(sound + introSoundsSuffix), 0.6);
		if (name == null) return null;
		var graphic = Paths.image(name);
		if (graphic == null) return null;

		var countdown:FlxSprite = new FlxSprite(graphic);
		countdown.cameras = [camHUD];
		// countdown.scrollFactor.set();
		countdown.screenCenter();
		addAheadObject(countdown, strumLineNotes);
		return countdown;
	}

	var specialVoice:String = '';
	public dynamic function spawnCountDownSprite(swagCounter:Int){}
	public var countDownTimes:Null<Int> = null;
	public var countDownSeconds:Null<Float> = null;
	public function startCountdown():Void
	{
		// var startCountdownFunction = function() {
		if (startedCountdown)
		{
			callOnScripts('onStartCountdown');
			return;
		}

		inCutscene = false;
		if (!ScriptPack.resultIsStop(callOnScripts('onStartCountdown')))
		{
			if (skipCountdown || startOnTime > 0) skipArrowStartTween = true;

			if (!ScriptPack.resultIsStop(callOnScripts('onGenerateStrumnotes')))
			{
				generateStaticArrows(false);
				generateStaticArrows(true);
			}

			function setVar(str:String, value:Dynamic)
			{
				variables.set(str, value);
				setOnLuas(str, value);
			}
			var i:UInt = 0;
			for (line in strumLines)
			{
				for (strum in line.strumNotes)
				{
					setVar('defaultStrumX' + i, strum.defPos.x);
					setVar('defaultStrumY' + i, strum.defPos.y);
					i++;
				}
			}
			for (i => strum in playerStrums.members)
			{
				setVar('defaultPlayerStrumX' + i, strum.defPos.x);
				setVar('defaultPlayerStrumY' + i, strum.defPos.y);
			}
			for (i => strum in opponentStrums.members)
			{
				setVar('defaultOpponentStrumX' + i, strum.defPos.x);
				setVar('defaultOpponentStrumY' + i, strum.defPos.y);
				// if(middleScrollMode) strum.visible = false;
			}
			if (countDownSeconds == null) countDownSeconds = Conductor.crochet / 1000;
			if (countDownTimes == null) countDownTimes = 5;
			startedCountdown = true;
			Conductor.songPosition = -countDownSeconds * 1000 * countDownTimes;
			setOnLuas('startedCountdown', true);
			callOnScripts('onCountdownStarted');

			modManager.receptors = [playerStrums.members, opponentStrums.members];
			callOnHScript('preModifierRegister');
			modManager.registerDefaultModifiers();
			callOnHScript('postModifierRegister');

			if (startOnTime < 0) startOnTime = 0;

			if (startOnTime > 0)
			{
				clearNotesBefore(startOnTime);
				setSongTime(startOnTime - 350);
				return;
			}
			else if (skipCountdown)
			{
				Conductor.songPosition = -(Conductor.crochet * 1.5); // huh
			}
			else
			{

				startTimer = new FlxTimer().start(countDownSeconds, function(tmr:FlxTimer)
				{
					danceCharacters(tmr.loopsLeft);

					spawnCountDownSprite(countDownTimes - tmr.loopsLeft - 1);

					/*
					notes.forEachAlive(function(note:Note){
						if (ClientPrefs.opponentStrums || note.mustPress){
							note.copyAlpha = false;
							note.alpha = note.multAlpha;
							if (middleScrollMode && !note.mustPress)
								note.alpha *= 0.35;
						}
					});
					*/
					callOnScripts('onCountdownTick', [countDownTimes - tmr.loopsLeft - 1]);
				}, countDownTimes);
			}
		}
	}

	public function sortStrumsNotes()
	{
		for (i in strumLines)
		{
			i.updateSustainNotesOrder();
		}
	}

	public function addBehindGF(obj:FlxBasic)	addBehindObject(obj, gfGroup);

	public function addBehindBF(obj:FlxBasic)	addBehindObject(obj, boyfriendGroup);

	public function addBehindDad(obj:FlxBasic)	addBehindObject(obj, dadGroup);

	public function clearNotesBefore(time:Float)
	{
		for (i in strumLines)
		{
			i.clearNotesBefore(time);
		}

		#if NOTE_BACKWARD_COMPATIBILITY
		var i:Int = unspawnNotes.length - 1;
		var daNote:Note;
		while (i > -1)
		{
			daNote = unspawnNotes[i--];
			if (daNote.strumTime - 350 < time)
			{
				unspawnNotes.remove(daNote);
			}
		}

		i = notes.length - 1;
		while (i > -1)
		{
			daNote = notes.members[i--];
			if (daNote.strumTime - 350 < time)
			{
				notes.remove(daNote, true);
			}
		}
		#end
	}

	public dynamic function updateScore(miss:Bool = false, ?start:Bool = false) {}

	public function setSongTime(time:Float)
	{
		if (time < 0)
			time = 0;
		Conductor.songPosition = time;
		for (sound in songGroup.sounds)
		{
			if (time <= sound.length)
			{
				sound.play(true, time);
				// sound.pitch = FlxG.timeScale;
			}
			else
			{
				sound.pause();
			}
		}
		if (videoPlayer?.bitmap != null)
			videoPlayer.bitmap.time += Math.round(time - Conductor.songPosition);
	}

	function startNextDialogue()
	{
		dialogueCount++;
		callOnScripts('onNextDialogue', [dialogueCount]);
	}

	function skipDialogue()
	{
		callOnScripts('onSkipDialogue', [dialogueCount]);
	}

	function startSong():Void
	{
		#if TOUCH_CONTROLS
		if (hitbox != null) hitbox.visible = true;
		#end

		startingSong = false;

		// @:privateAccess
		// FlxG.sound.playMusic(inst._sound, 1, false);
		// inst.pitch = FlxG.timeScale;
		inst.onComplete = onSongComplete;

		songGroup.play();

		setSongTime(Math.max(0, startOnTime - 500));

		startOnTime = 0;

		if (paused)
		{
			// trace('Oopsie doopsie! Paused sound');
			songGroup.pause();
		}

		#if desktop
		resetRPC(true);
		#end
		checkEventNote();
		setOnLuas('songLength', songLength);
		callOnScripts('onSongStart');
	}

	var noteTypes:Array<String> = [""];
	var eventsPushed:Array<String> = [];
	public var songLoops:Bool = false;
	public var loopSongBounds:FlxRange<Int>;
	var _loopPending = false;

	function generateSong(?reset:Bool):Void
	{
		#if sys
		var prevTime = Sys.time();
		#end
		callOnScripts('onSongGeneratedPost');
		final songData = SONG;
		songSpeed = switch (songSpeedType = ClientPrefs.getGameplaySetting('scrolltype', 'multiplicative'))
		{
			case "multiplicative":	songData.speed * ClientPrefs.getGameplaySetting('scrollspeed', 1);
			case "constant":		ClientPrefs.getGameplaySetting('scrollspeed', 1);
			default:				songData.speed;
		}

		if (reset)
		{
			// noteTypes.clear();
			// eventsPushed.clear();
			#if NOTE_BACKWARD_COMPATIBILITY
			unspawnNotes.clear();
			#end
			eventNotes.splice(0, eventNotes.length - 1);
			for (i in strumLines)
			{
				i.destroyNotes();
			}
		}
		Conductor.bpm = songData.bpm;

		final isValidLoop = songLoops && songGroup.sounds.length > 0;
		if (!isValidLoop)
		{
			curSong = songData.song;
			inst = EffectSound.load(Paths.inst(songData.song, songData.postfix));
			if(SONG.needsVoices)
			{
				final singleVocals:openfl.media.Sound = Paths.voices(songData.song, 'Voices' + songData.postfix);
				if (singleVocals == null)
				{
					vocals = EffectSound.load(Paths.voices(songData.song, 'Voices_Player' + songData.postfix));
					vocalsDAD = EffectSound.load(Paths.voices(songData.song, 'Voices_Opponent' + songData.postfix));
				}
				else
				{
					vocals = EffectSound.load(singleVocals);
				}
			}

			// vocals.pitch = FlxG.timeScale;
			// vocalsDAD.pitch = FlxG.timeScale;

			addSongLines([inst, vocals, vocalsDAD]);
		}
		// Song duration in a float, useful for the time left feature
		songLength = inst.length;
		setOnLuas('songLength', songLength);

		// replayHandler = new ReplayHandler();
		// if (replayMode)
		// {
		// 	trace('Load Replay...');
		// 	replayHandler.load(songData.song);
		// 	trace(replayHandler.toString());
		// 	// if (replayHandler.data.ratings.length > 0){
		// 	// }
		// }
		var rangeStart:Int = -FlxMath.MAX_VALUE_INT;
		var rangeEnd:Int = FlxMath.MAX_VALUE_INT;
		if (songLoops && loopSongBounds != null)
		{
			rangeStart = loopSongBounds.start;
			rangeEnd = loopSongBounds.end;
		}
		trace('Load Events...');
		loadEvents('events', rangeStart, rangeEnd);

		//Event Notes
		loadEvents(songData, rangeStart, rangeEnd);

		if (SONG.arrowSkin.isNullOrEmpty() || Paths.image(SONG.arrowSkin) == null)
		{
			trace("Note skin " + SONG.arrowSkin + " doesn't exits.");
			SONG.arrowSkin = Constants.DEFAULT_NOTE_SKIN;
		}

		trace('Load Chart...');
		final noteData:Array<SwagSection> = songData.notes;
		var swagNote:Note;
		var sustainNote:Note;
		var lastNewNoteTypes:Array<String> = [];
		final funcCreateNoteName:String = "onCreateNote";
		final scriptsToRunCreate:Array<HScript> = hscriptArray.filter(i -> i.interp.variables.exists(funcCreateNoteName));
		var daBpm:Float = Conductor.bpm;
		var curStepCrochet:Float = 60 / Conductor.bpm * 1000 / 4.0;
		for (section in noteData)
		{
			if (section.changeBPM && daBpm != section.bpm)
				curStepCrochet = 60 / Conductor.bpm * 1000 / 4.0;

			for (songNotes in section.sectionNotes)
			{
				final daStrumTime:Float = songNotes[0];
				if (songLoops && (daStrumTime < rangeStart || daStrumTime > rangeEnd))
					continue;
				final daNoteData:Int = Std.int(songNotes[1] % 4);
				var gottaHitNote:Bool = songNotes[1] < 4 == section.mustHitSection;

				swagNote = new Note(daStrumTime, daNoteData, null, /** old note **/ null, false, false, gottaHitNote);
				// swagNote.ID = unspawnNotes.length;
				// swagNote.cpuControl = !gottaHitNote;
				swagNote.sustainLength = songNotes[2];
				swagNote.gfNote = section.gfSection && songNotes[1] < 4;
				swagNote.noteType = Std.isOfType(songNotes[3], String)
					? songNotes[3]
					: ChartingState.noteTypeList[songNotes[3]]; // Backward compatibility + compatibility with Week 7 charts
				#if NOTE_BACKWARD_COMPATIBILITY
				unspawnNotes.push(swagNote);
				#end

				if (section.altAnim && !section.gfSection && !gottaHitNote)
					swagNote.animSuffix = "-alt";
				final floorSus:Int = Math.floor(swagNote.sustainLength / curStepCrochet) + 1;
				if (floorSus > 1)
				{
					swagNote.tail.resize(floorSus);
					#if NOTE_BACKWARD_COMPATIBILITY
					var _notesLen:Int = unspawnNotes.length;
					unspawnNotes.resize(_notesLen + floorSus);
					#end
					sustainNote = swagNote;
					for (i in 0...floorSus)
					{
						sustainNote = new Note(daStrumTime + curStepCrochet * i, daNoteData, null, sustainNote, true, false, gottaHitNote);
						sustainNote.gfNote = swagNote.gfNote;
						sustainNote.noteType = swagNote.noteType;
						sustainNote.animSuffix = swagNote.animSuffix;
						// sustainNote.ID = _notesLen;
						sustainNote.parent = swagNote;
						// !sus ඞ
						// final factor:Int = i - floorSus % 2;
						// if(factor > 0 && factor % 2 == 0 && i != floorSus) sustainNote.flipY = !swagNote.flipY;
						swagNote.tail[i] = sustainNote;
						#if NOTE_BACKWARD_COMPATIBILITY
						unspawnNotes[_notesLen] = sustainNote;
						_notesLen++;
						#end
					}
					swagNote.tail[swagNote.tail.length - 1].isLastSustain = true;
				}

				var result:Dynamic = null;
				if (scriptsToRunCreate.length > 0)
					for (i in scriptsToRunCreate)
					{
						result = i.call(funcCreateNoteName, [swagNote]) ?? result;
					}
				if (result == null)
				{
					var line:StrumLine = gottaHitNote ? playerStrumLine : opponentStrumLine;

					line.addNote(swagNote);
					line.addNotes(swagNote.tail);
				}

				if(!noteTypes.contains(swagNote.noteType))
				{
					noteTypes.push(swagNote.noteType);
					// if (swagNote.noteType.length > 0)
					lastNewNoteTypes.push(swagNote.noteType);
				}
			}
		}

		trace('Events: ' + eventNotes.length);
		// trace(unspawnNotes.length);

		for (i in strumLines)
		{
			i.sortNotes();
		}


		#if NOTE_BACKWARD_COMPATIBILITY
		unspawnNotes.sort(function (Obj1:Note, Obj2:Note):Int
			return FlxSort.byValues(FlxSort.ASCENDING, Obj1.strumTime, Obj2.strumTime)
		);
		#end
		// sustainNotes.active = regularNotes.active = false;
		// No need to sort if there's a single one or none at all
		if (eventNotes.length > 1)
			eventNotes.sort(function (Obj1:EventNote, Obj2:EventNote):Int
				return FlxSort.byValues(FlxSort.ASCENDING, Obj1.strumTime, Obj2.strumTime)
			);
		generatedMusic = true;
		for (i in lastNewNoteTypes)
			loadScript(Constants.SONG_NOTETYPES_FILES_FOLDER + "/" + i);
		callOnScripts('onSongGenerated');
		trace('Song Loaded.');

		#if sys
		trace('Took ${Sys.time() - prevTime} seconds');
		#end
	}
	function loadEvents(json:haxe.extern.EitherType<String, Song>, ?rangeStart:Null<Int>, ?rangeEnd:Null<Int>):Void
	{
		var eventsJson:Song = json is Song ? cast json : Song.loadFromJson(json, SONG.song);
		if (eventsJson == null) return;
		rangeStart ??= -FlxMath.MAX_VALUE_INT;
		rangeEnd ??= FlxMath.MAX_VALUE_INT;

		for (event in eventsJson.events) //Event Notes
		{
			if (event[0] < rangeStart || event[0] > rangeEnd)
				continue;
			for (i in 0...event[1].length)
				makeEvent(event, i);
		}
	}

	public inline function addSongLines(sounds:Array<FlxSound>)
	{
		for (i in sounds)
			addSongLine(i);
	}
	public function addSongLine(line:FlxSound)
	{
		if (line == null || !line.isValid())
			return;
		if (songGroup.add(line) && FlxG.sound.list.members.indexOf(line) == -1)
			FlxG.sound.list.add(line);
	}

	inline function makeEvent(event:Array<Dynamic>, i:Int)
	{
		pushEvent(event[0], event[1][i]);
	}
	function pushEvent(time:Float, args:Array<Dynamic>)
	{
		var subEvent:EventNote = new EventNote(time + ClientPrefs.noteOffset, args[0], args[1], args[2], args[3]);
		eventNotes.push(subEvent);
		eventPushed(subEvent);
		callOnScripts('onEventPushed', [subEvent.event, subEvent.value1 ?? '',
			subEvent.value2 ?? '', subEvent.value3 ?? '', subEvent.strumTime]);
	}
	function eventPushed(event:EventNote)
	{
		switch (event.event)
		{
			case 'Change Character':
				addCharacterToList(event.value2, switch (event.value1.toLowerCase().trim())
				{
					case 'gf'	| 'girlfriend'	|	'2':	2;
					case 'dad'	| 'opponent'	|	'1':	1;
					default:								0;
				});
		}
		if(!eventsPushed.contains(event.event))
		{
			eventsPushed.push(event.event);
			loadScript(Constants.SONG_EVENTS_FILES_FOLDER + "/" + event.event);
		}
		event.strumTime -= eventEarlyTrigger(event);
	}
	function eventEarlyTrigger(event:EventNote):Float
	{
		var returnedValue:Null<haxe.extern.EitherType<Float, String>> = callOnScripts('eventEarlyTrigger', [
			event.event, event.value1 ?? '', event.value2 ?? '', event.value3 ?? '', event.strumTime
		]);

		if(returnedValue == null && returnedValue == ScriptUtil.Function_Continue)
			return 0;
		return returnedValue;
	}


	public var skipArrowStartTween:Bool = false;

	public var strumsManiaType:String = '4K';

	function _animateIntroStrumNote(strumLine:StrumGroup, targetAlpha:Float, babyArrow:StrumNote, index:Int):Any
	{
		var offset = 15 * strumLine.scaleNoteFactor;
		babyArrow.y -= offset;
		babyArrow.alpha = 0;
		FlxTween.tween(babyArrow, {y: babyArrow.y + offset, alpha: targetAlpha}, 0.8, {ease: FlxEase.circOut, startDelay: 0.3 * index * strumLine.scaleNoteFactor});
		return null;
	}
	private function generateStaticArrows(player:Bool):Void
	{
		var targetAlpha:Float = 1.;
		var posX:Null<Float> = null;
		if (middleScrollMode)
			posX = FlxG.width / 2;
		final strumsData = StrumsManiaData.data.get(strumsManiaType);
		if (player)
		{
			playerStrums.position.x = posX ?? FlxG.width / 4 * 3;
			playerStrums.position.y = strumLine.y;
			for (i in playerStrums.generateStrums(strumsData, {
				downScroll: ClientPrefs.downScroll,
				funcIn: (isStoryMode || skipArrowStartTween) ? null : _animateIntroStrumNote.bind(playerStrums, targetAlpha, _, _)
			}))
			{
				strumLineNotes.add(i);
				i.playAnim('static');
			}
		}
		else
		{
			opponentStrums.position.x = posX ?? FlxG.width / 4;
			opponentStrums.position.y = strumLine.y;
			if (middleScrollMode)
				targetAlpha *= 0.35;
			for (i in opponentStrums.generateStrums(strumsData, {
				downScroll: ClientPrefs.downScroll,
				funcIn: (isStoryMode || skipArrowStartTween) ? (babyArrow, index) -> {
					babyArrow.alpha = targetAlpha;
				} : _animateIntroStrumNote.bind(opponentStrums, targetAlpha, _, _)
			}))
			{
				strumLineNotes.add(i);
				i.visible = ClientPrefs.opponentStrums;
				i.playAnim('static');
			}
			if (middleScrollMode)
			{
				final centerIndex = Math.floor(opponentStrums.members.length / 2) - 1;
				posX /= 2;
				for (i => strum in opponentStrums.members)
				{
					if (i <= centerIndex)
						strum.x -= posX;
					else
						strum.x += posX;
					strum.defPos.x = strum.x;
				}
			}
		}
		/*
		for (i in 0...4){
			// FlxG.log.add(i);
			var targetAlpha:Float = 1.;
			if (middleScrollMode && player < 1) targetAlpha *= 0.35;

			var babyArrow:StrumNote = new StrumNote(middleScrollMode ? STRUM_X_MIDDLESCROLL : STRUM_X, strumLine.y, i, player);
			if (!isStoryMode && !skipArrowStartTween){
				babyArrow.y -= 15;
				babyArrow.alpha = 0;
				FlxTween.tween(babyArrow, {y: babyArrow.y + 15, alpha: targetAlpha}, 1, {ease: FlxEase.circOut, startDelay: (0.3 * i)});
			}else
				babyArrow.alpha = targetAlpha;

			if (player == 1){
				playerStrums.add(babyArrow);
			}else{
				babyArrow.cpuControl = true;
				if (middleScrollMode){
					babyArrow.x += 310;
					if (i > 1) // Up and Right
						babyArrow.x += FlxG.width / 2 + 25;
				}
				opponentStrums.add(babyArrow);
			}

			strumLineNotes.add(babyArrow);
			babyArrow.postAddedToGroup();
		}
		*/
	}

	// SWAG
	var mainTweenManager:FlxTweenManager;
	var mainTimerManager:FlxTimerManager;
	static var pauseTweenManager:FlxTweenManager = new FlxTweenManager();
	static var pauseTimerManager:FlxTimerManager = new FlxTimerManager();
	@:noCompletion var _isMainManagers:Bool = true;
	public function setTweens(boolVal:Bool)
	{
		if (boolVal != _isMainManagers){
			_isMainManagers = boolVal;
			mainTweenManager.active = mainTimerManager.active = boolVal;
			pauseTweenManager.active = pauseTimerManager.active = !boolVal;
			if (boolVal)
			{
				FlxTween.globalManager = mainTweenManager;
				FlxTimer.globalManager = mainTimerManager;
			}
			else
			{
				pauseTweenManager.completeAll();
				pauseTimerManager.completeAll();
				FlxTween.globalManager = pauseTweenManager;
				FlxTimer.globalManager = pauseTimerManager;
			}
		}
	}

	/*
	override function openSubState(SubState:FlxSubState){
		// if (paused) songGroup.pause();
		super.openSubState(SubState);
	}
	*/

	// Updating Discord Rich Presence.
	#if !DISCORD_RPC
	inline
	#end
	function resetRPC(?cond:Null<Bool>)
	{
		#if DISCORD_RPC
		cond ??= Conductor.songPosition > 0.0;
		DiscordClient.changePresence(paused ? detailsPausedText : detailsText, detailsSong,
			cond ? (songLength - Conductor.songPosition - ClientPrefs.noteOffset) / playbackRate : null,
			{
				smallImage: discordSmallImage,
				largeImage: curPortrait
			});
		#end
	}

	@:allow(game.states.substates.PauseSubState)
	function setPause(toogle:Bool)
	{
		paused = toogle;
		if (toogle)
		{
			onPause();
		}
		else
		{
			videoPlayer?.resume();
			setTweens(true);
			FlxG.sound.resume();
			if (!startingSong) resyncVocals();
			camGame.followActive = camHUD.followActive = camGame.fxActive = camHUD.fxActive = true;
			playbackRate = playbackRate;
			callOnScripts('onResume');

			if(!cpuControlled)
			{
				for (note in playerStrums)
				{
					if(note.animation.name != null && note.animation.name != 'static')
					{
						note.playAnim('static');
						note.resetAnim = 0;
					}
				}
			}
			#if desktop
			// if (startTimer != null && startTimer.finished) {
			WindowUtil.endfix = ' - $detailsSong';
			resetRPC(startTimer != null && startTimer.finished);
			// } else {
			//	DiscordClient.changePresence(detailsText, detailsSong,
			//		songLength
			//		- Conductor.songPosition
			//		- ClientPrefs.noteOffset, {smallImage: iconP2.getCharacter(), largeImage: curPortrait});
			// }
			#end
		}
	}
	function onPause()
	{
		if (playingVideo)
			videoPlayer?.pause();
		persistentUpdate = false;
		persistentDraw = true;
		setTweens(false);
		FlxG.timeScale = 1;
		FlxG.sound.pause();
		camGame.followActive = camHUD.followActive = camGame.fxActive = camHUD.fxActive = false;
		// if (inst != null){
		// 	inst.pause();
		// 	vocals.pause();
		// 	vocalsDAD.pause();
		// }
		#if desktop
		resetRPC(false);
		WindowUtil.endfix = ' - $detailsSong - Paused';
		#end
	}

	public override function onFocus():Void
	{
		if (!ScriptPack.resultIsStop(callOnScripts('onFocus', null, true)))
		{
			#if DISCORD_ALLOWED
			if (health > 0 && !paused)
				resetRPC();
			#end
		}
		super.onFocus();
	}
	@:access(flixel.FlxGame)
	function checkOnFocusLost()
	{
		if (FlxG.autoPause || !FlxG.game._lostFocus || !startedCountdown || !canPause || paused || cpuControlled)
			return;
		if (!ScriptPack.resultIsStop(callOnScripts('onPause', null, true)))
			openPauseMenu(); // idk
	}
	public override function onFocusLost():Void
	{
		if (!ScriptPack.resultIsStop(callOnScripts('onFocusLost', null, true)))
		{
			#if DISCORD_ALLOWED
			if (health >= 0 && !paused)
				resetRPC(false);
			#end
		}

		checkOnFocusLost();
	}

	function resyncVocals():Void
	{
		if (songGroup == null || finishTimer != null && songGroup.sounds.length <= 1)
			return;
		final instTime:Float = songGroup.sounds[0].time;
		// trace('Resync Vocals  ${Math.round(Conductor.songPosition)} --> ${instTime}');
		Conductor.songPosition = instTime;
		for (i in 1...songGroup.sounds.length)
		{
			final sound = songGroup.sounds[i];
			if (instTime <= sound.length)
				sound.time = instTime;
		}
	}

	public var paused:Bool = false;
	public var canReset:Bool = true;

	public var updateConductorPosition:Bool = true;
	public var useVSyns:Bool = true;
	var startedCountdown:Bool = false;
	var canPause:Bool = true;

	#if DEV_BUILD
	@:noCompletion var isScrollingSong:Bool = false;
	@:noCompletion var isCpuControlled:Bool = false;
	@:allow(game.states.substates.PauseSubState)
	@:noCompletion var isFreezed:Bool = false;
	@:noCompletion var speedOfTimeSkip:Int = 1;
	@:noCompletion var _freezeIsPressed:Bool = false;
	#else
	@:noCompletion var speedOfTimeSkip(get, never):Int;
	inline function get_speedOfTimeSkip():Int return 1;
	#end

	// var __vocalOffsetViolation:Float = 0;
	public var updateCameraPosition:Bool = true;
	public var allowMissOpponent:Bool = false;
	public override function update(elapsed:Float)
	{
		#if DEV_BUILD
		if (isFreezed)
		{
			if (controls.PAUSE && canPause && startedCountdown && !ScriptPack.resultIsStop(callOnScripts('onPause', null, false)))
				openPauseMenu();

			if (controls.DEBUG_BOTPLAY)
			{
				cpuControlled = !cpuControlled;
				return;
			}

			if (controls.DEBUG_TOOGLE_HUD)
			{
				camHUD.visible = !camHUD.visible;
				cpuControlled = camHUD.visible ? null : true;
				return;
			}

			if (controls.DEBUG_FREEZE && !_freezeIsPressed)
			{
				setPause(false);
				isFreezed = false;
				_freezeIsPressed = true;
			}
			else
			{
				_freezeIsPressed = false;
				return;
			}
		}
		#end

		callOnScripts('onUpdate', [elapsed]);
		if (!inCutscene && updateCameraPosition)
		{
			/*if (!camGame.tweeningX)*/	camFollowPos.x = CoolUtil.fpsLerp(camFollowPos.x, camFollow.x, 0.04 * cameraSpeed);
			/*if (!camGame.tweeningY)*/	camFollowPos.y = CoolUtil.fpsLerp(camFollowPos.y, camFollow.y, 0.04 * cameraSpeed);
		}
		#if VIDEOS_ALLOWED
		if (playingVideo && (controls.PAUSE || controls.ACCEPT) && (startingSong || endingSong))
			onEndVideo();
		#end

		if (controls.PAUSE && canPause && startedCountdown && !ScriptPack.resultIsStop(callOnScripts('onPause', null, false)))
			openPauseMenu();

		if (startedCountdown && updateConductorPosition)
		{
			Conductor.songPosition += elapsed * 1000;
			if (useVSyns && /*FlxG.game.ticks % 200 < 100 && */!endingSong && songGroup.sounds.length > 0 && Conductor.songPosition >= 0)
			{
				var mainSound = songGroup.sounds[0];
				mainSound.getCurrentTime();
				var timeDiff:Float = Math.abs(mainSound.time - Conductor.songPosition - Conductor.offset);
				Conductor.songPosition = CoolUtil.fpsLerp(Conductor.songPosition, mainSound.time, 0.04167);
				if (timeDiff > 1000 * playbackRate)
					Conductor.songPosition += 1000 * FlxMath.signOf(timeDiff);
			}
		}
		if (generatedMusic)
		{
			checkEventNote();
		}

		super.update(elapsed);

		var noLoopBounds = loopSongBounds == null;
		if (!startingSong && songLoops && (noLoopBounds || Conductor.songPosition >= loopSongBounds.end))
		{
			_loopPending = true;
		}

		if (_loopPending)
		{
			generateSong(true);
			setSongTime(loopSongBounds.start);
			setSongTime(noLoopBounds ? 0.0 : loopSongBounds.start);
			clearNotesBefore(Conductor.songPosition);
			updateConductor();
			_loopPending = false;
		}

		setOnLuas('curDecStep', curDecStep);
		setOnLuas('curDecBeat', curDecBeat);

		if (healthBarUpdate != null)
			healthBarUpdate(elapsed);

		if (startingSong)
		{
			if (startedCountdown && Conductor.songPosition >= 0)
				startSong();
			else if (!startedCountdown)
				Conductor.songPosition = -Conductor.crochet * 5;
		}

		// Conductor.lastSongPos = inst.time;

		cameraZooming(elapsed);

		// RESET
		if (!ClientPrefs.noReset && controls.RESET && canReset && !inCutscene && startedCountdown && !endingSong)
		{
			health = 0;
			trace("RESET = True");
		}

		if (modManager != null && modManager.active)
		{
			modManager.updateTimeline(curDecStep);
			modManager.update(elapsed);
		}

		if (generatedMusic && !inCutscene && !cpuControlled)
			keyShit();

		for (i in strumLines)
		{
			i.updateNotesAtTime(elapsed, Conductor.songPosition, songSpeed, playbackRate, generatedMusic && !inCutscene && startedCountdown);
		}

		#if DEV_BUILD
		if (/*!InfoAPI.STRANGER && */!endingSong && !startingSong)
		{
			if (!isScrollingSong)
			{
				if (controls.DEBUG_SKIP_SONG)
				{
					KillNotes();
					inst.onComplete();
				}
				if (controls.DEBUG_SKIP_TIME)
				{
					final targetTime = Conductor.songPosition + (FlxG.keys.pressed.SHIFT ? 20000 : 10000) * playbackRate;
					setSongTime(targetTime);
					clearNotesBefore(Conductor.songPosition);
					if(Conductor.songPosition > inst.length) finishSong();
				}
				if (controls.DEBUG_FREEZE && !_freezeIsPressed)
				{
					setPause(true);
					isFreezed = true;
					_freezeIsPressed = true;
				}
				if (controls.DEBUG_BOTPLAY)
				{
					cpuControlled = !cpuControlled;
				}
				if (controls.DEBUG_TOOGLE_HUD)
				{
					camHUD.visible = !camHUD.visible;
					cpuControlled = camHUD.visible ? null : true;
				}
			}
			if (controls.DEBUG_SPEED_UP && !isScrollingSong)
			{
				isScrollingSong = true;
				isCpuControlled = cpuControlled;
				cpuControlled = true;
				speedOfTimeSkip = FlxG.keys.pressed.SHIFT ? 20 : 10;
				playbackRate *= speedOfTimeSkip;
				songSpeed *= speedOfTimeSkip;
			}
			else if (controls.DEBUG_SPEED_UP_R && isScrollingSong)
			{
				isScrollingSong = false;
				cpuControlled = isCpuControlled;
				songSpeed /= speedOfTimeSkip;
				playbackRate /= speedOfTimeSkip;
				speedOfTimeSkip = 1;
			}
		}
		#end

		#if EDITORS_ALLOWED
		if (!endingSong && !inCutscene)
		{
			if (controls.DEBUG_1 && !ScriptPack.resultIsStop(callOnScripts('onGoDebugState', ['ChartEditorState'])))
			{
				openChartEditor();
			}

			if (controls.DEBUG_2 && !ScriptPack.resultIsStop(callOnScripts('onGoDebugState', ['CharacterEditorState'])))
			{
				persistentUpdate = false;
				// paused = true;
				cancelMusicFadeTween();
				MusicBeatState.switchState(new CharacterEditorState(/*SONG.player2*/ (FlxG.keys.pressed.SHIFT ? boyfriend : dad).curCharacter, true));
			}
		}
		#end

		setOnLuas('cameraX', camFollowPos.x);
		setOnLuas('cameraY', camFollowPos.y);
		callOnScripts('onUpdatePost', [elapsed]);
		#if DEV_BUILD
		_freezeIsPressed = false;
		#end
	}

	public dynamic function cameraZooming(elapsed:Float)
	{
		if (camZooming)
		{
			/*if (!camGame.tweeningZoom)*/	camGame.zoom = CoolUtil.fpsLerp(camGame.zoom, camGame.defaultZoom, 0.052083 * camZoomingDecay);
			/*if (!camHUD.tweeningZoom)*/	camHUD.zoom = CoolUtil.fpsLerp(camHUD.zoom, camHUD.defaultZoom, 0.052083 * camZoomingDecay);
		}
	}

	var customPauseState:String;
	function openPauseMenu()
	{
		openSubState(switch customPauseState
		{
			case null:				new PauseBasic();
			case customPauseState:	new PauseSubState(customPauseState);
		});
	}
	#if EDITORS_ALLOWED
	function openChartEditor()
	{
		persistentUpdate = false;
		paused = true;
		cancelMusicFadeTween();
		MusicBeatState.switchState(new ChartingState());
		chartingMode = true;

		#if DISCORD_RPC
		DiscordClient.changePresence("Chart Editor");
		#end
	}
	#end

	public var isDead:Bool = false; // Don't mess with this on Lua!!!

	function doDeathCheck(?skipHealthCheck:Bool = false)
	{
		if (!((skipHealthCheck || health <= healthBounds.min) && !practiceMode && !isDead))
			return false;
		if (ScriptPack.resultIsStop(callOnScripts('onGameOver', null, false)))
			return true;

		isDead = true;
		canPause = false;
		deathCounter++;
		boyfriend.stunned = true;
		paused = true;
		songGroup.stop();
		playbackRate = 1;

		#if DISCORD_RPC
		// Game Over doesn't get his own variable because it's only used here
		DiscordClient.changePresence(detailsGameOverText, detailsSong, {
			smallImage: discordSmallImage,
			largeImage: curPortrait
		});
		WindowUtil.prefix = 'Game Over - ';
		WindowUtil.endfix = ' - $detailsSong';
		#end
		setTweens(false);
		openSubState(new GameOverSubstate());
		persistentUpdate = false;
		persistentDraw = false;

		return true;
	}

	public function checkEventNote()
	{
		var pos = Conductor.songPosition;
		if (pos < 0) pos = 0;
		while (eventNotes[0] != null && pos >= eventNotes[0].strumTime)
		{
			var eventNote = eventNotes.shift();
			triggerEventNote(eventNote.event, eventNote.value1 != null ? eventNote.value1 : '', eventNote.value2 != null ? eventNote.value2 : '',
				eventNote.value3 != null ? eventNote.value3 : '', eventNote.strumTime);
		}
	}

	public inline function getControl(key:String) return Reflect.getProperty(controls, key);

	public inline function triggerEvent(eventName:String, ?value1:String, ?value2:String, ?value3:String, ?strumTime:Float)
	{
		triggerEventNote(eventName, value1, value2, value3, strumTime);
	}
	var _eventHSInterp:Interp;
	var _eventHSParser:Parser;
	public function triggerEventNote(eventName:String, ?value1:String, ?value2:String, ?value3:String, ?strumTime:Float)
	{
		switch (eventName)
		{
			case 'Switch Hud': switchHud(value1);

			case 'Flash New':
				if (!ClientPrefs.flashing) return;
				var val1:Float = Std.parseFloat(value1).getDefault(1.);
				var val2:Int = Std.parseInt(value2).getDefault(0xFFFFFFFF);
				final cam:FlxCamera = switch(value3.toLowerCase().trim()) {
										case 'camhud' | 'hud': camHUD;
										case 'camother' | 'other': camOther;
										default: camGame;
									}
				cam.flash(val2, val1);

			case 'Hey!':
				var value:Int = switch (value1.toLowerCase().trim()){
					case 'bf' | 'boyfriend' | '0':	0;
					case 'gf' | 'girlfriend' | '1':	1;
					default:						2;
				}

				var time:Float = Std.parseFloat(value2);
				if (Math.isNaN(time) || time <= 0) time = 0.6;

				if (value != 0)
				{
					if (dad.curCharacter.startsWith('gf'))
					{
						// Tutorial GF is actually Dad! The GF is an imposter!! ding ding ding ding ding ding ding, dindinding, end my suffering
						dad.playAnim('cheer', true);
						dad.specialAnim = true;
						dad.heyTimer = time;
					}
					else if (gf != null)
					{
						gf.playAnim('cheer', true);
						gf.specialAnim = true;
						gf.heyTimer = time;
					}
				}
				else if (value != 1)
				{
					boyfriend.playAnim('hey', true);
					boyfriend.specialAnim = true;
					boyfriend.heyTimer = time;
				}

			case 'Set GF Speed':
				var value:Int = Std.parseInt(value1);
				if (Math.isNaN(value) || value < 1) value = 1;
				gfSpeed = value;

			case 'Add Camera Zoom':
				if (ClientPrefs.camZooms /*&& FlxG.camera.zoom < 1.35*/)
				{
					camGame.zoom += Std.parseFloat(value1).getDefault(0.015);
					camHUD.zoom += Std.parseFloat(value2).getDefault(0.03);
				}

			case 'Play Animation':
				// trace('Anim to play: ' + value1);
				var char:Character = switch (value2.toLowerCase().trim())
				{
					case 'bf' | 'boyfriend' | '1':	boyfriend;
					case 'gf' | 'girlfriend' | '2':	gf;
					default:						dad;
				}

				if (char != null)
				{
					char.playAnim(value1, true);
					char.specialAnim = true;
				}

			case 'Camera Follow Pos':
				if (camFollow == null) return;
				var val1:Float = Std.parseFloat(value1);
				var val2:Float = Std.parseFloat(value2);

				isCameraOnForcedPos = false;
				if (!Math.isNaN(val1) || !Math.isNaN(val2))
				{
					isCameraOnForcedPos = true;
					if (Math.isNaN(val1)) val1 = 0;
					if (Math.isNaN(val2)) val2 = 0;
					camFollow.x = val1;
					camFollow.y = val2;
				}

			case 'Alt Idle Animation':
				var char:Character = switch (value1.toLowerCase().trim()){
					case 'gf' | 'girlfriend' | '2':	gf;
					case 'boyfriend' | 'bf' | '1':	boyfriend;
					default:						dad;
				}

				if (char != null)
				{
					@:bypassAccessor char.idleSuffix = value2;
					char.recalculateDanceIdle();
				}

			case 'Setting Camera Zoom':
				if (value1.length > 0)
				{
					camZoomingFreq = Std.parseInt(value1).getDefault(0);
				}
				if (value2.length > 0)
				{
					camZoomingOffset = Std.parseInt(value2).getDefault(0);
				}

			case 'Sing Animation Prefix':
				var char:Character = switch (value1.toLowerCase().trim())
				{
					case 'gf' | 'girlfriend' | '2':	gf;
					case 'boyfriend' | 'bf' | '1':	boyfriend;
					default:						dad;
				}

				if (char != null)
				{
					if (value2 == null || value2.trim().length == 0)
						value2 = 'sing';
					char.singAnimsPrefix = value2;
				}

			case 'Screen Shake':
				final valuesArray:Array<String> = [value1, value2];
				for (i => camera in [camGame, camHUD])
				{
					if (valuesArray[i].length == 0) continue;
					final split:Array<String> = valuesArray[i].split(',');
					var duration:Float = 0;
					var intensity:Float = 0;
					if (split[0] != null) duration = Std.parseFloat(split[0]).getDefault(0);
					if (split[1] != null) intensity = Std.parseFloat(split[1]).getDefault(0);

					if (duration > 0 && intensity != 0) camera.shake(intensity, duration);
				}
			case 'Change Character':
				var charType:Int = switch (value1.toLowerCase().trim()){
					case 'gf' | 'girlfriend' | '2':	2;
					case 'dad' | 'opponent' | '1':	1;
					default:						0;
				}

				function removeScriptsFromCharacter(char)
				{
					var checkNameRegex = new EReg("\\/" + char.curCharacter + ".[a-zA-Z]+$", "");
					#if LUA_ALLOWED
					for (script in luaArray)
					{
						if (checkNameRegex.match(script.scriptName))
						{
							// trace('removed script: ${script}');
							script.call('onDestroy');
							#if hscript
							script.hscript = null;
							#end
							script.stop();
							luaArray.remove(script);
							break;
						}
					}
					#end
					#if HSCRIPT_ALLOWED
					for (script in hscriptArray)
					{
						if (checkNameRegex.match(script.scriptName))
						{
							// trace('removed script: ${script}');
							script.call('onDestroy');
							script.destroy();
							hscriptArray.remove(script);
							break;
						}
					}
					#end
				}
				switch (charType)
				{
					case 0:
						if (boyfriend.curCharacter != value2)
						{
							addCharacterToList(value2, charType);

							removeScriptsFromCharacter(boyfriend);
							var lastAlpha:Float = boyfriend.alpha;
							boyfriend.alpha = 0.00001;
							// trace(boyfriendMap);
							playerCharacters.remove(boyfriend);
							boyfriend = boyfriendMap.get(value2);
							boyfriend.alpha = lastAlpha;
							playerCharacters.push(boyfriend);
							iconP1.changeIcon(boyfriend.healthIcon);
							// iconP1.y = healthBar.y - iconP1.origHeight / 2;
							updateHealthIcons();
							reloadHealthBarColors();
							GameOverSubstate.applyFromCharacter(boyfriend);
						}
						setOnLuas('boyfriendName', boyfriend.curCharacter);

					case 1:
						if (dad.curCharacter != value2)
						{
							addCharacterToList(value2, charType);

							removeScriptsFromCharacter(dad);
							var wasGf:Bool = dad.curCharacter.startsWith('gf');
							var lastAlpha:Float = dad.alpha;
							dad.alpha = 0.00001;
							// trace(dadMap);
							dad = dadMap.get(value2);
							if (!dad.curCharacter.startsWith('gf')) {
								if (wasGf && gf != null) gf.visible = true;
							} else if (gf != null) gf.visible = false;

							dad.alpha = lastAlpha;
							iconP2.changeIcon(dad.healthIcon);
							// iconP2.y = healthBar.y - iconP2.origHeight / 2;
							updateHealthIcons();
							reloadHealthBarColors();
						}
						setOnLuas('dadName', dad.curCharacter);

					case 2:
						if (gf != null)
						{
							if (gf.curCharacter != value2)
							{
								addCharacterToList(value2, charType);

								removeScriptsFromCharacter(gf);

								var lastAlpha:Float = gf.alpha;
								gf.alpha = 0.00001;
								gf = gfMap.get(value2);
								gf.alpha = lastAlpha;
							}
							setOnLuas('gfName', gf.curCharacter);
						}
				}
				resetRPC();

			case 'Change Scroll Speed':
				if (songSpeedType == "constant") return;
				var val1:Float = Std.parseFloat(value1).getDefault(1);
				var val2:Float = Std.parseFloat(value2).getDefault(0);

				var newValue:Float = SONG.speed * ClientPrefs.getGameplaySetting('scrollspeed', 1) * val1;

				if (val2 <= 0)
				{
					songSpeed = newValue * speedOfTimeSkip;
				}
				else
				{
					songSpeedTween?.cancel();
					songSpeedTween = FlxTween.num(songSpeed / speedOfTimeSkip, newValue, val2, {
						ease: CoolUtil.getFlxEaseByString(value3),
						onComplete: _ -> songSpeedTween = null
					}, i -> songSpeed = i * speedOfTimeSkip);
				}

			case 'Run Haxe Code':
				if(_eventHSParser == null)
				{
					_eventHSParser = HScript.initParser();
					_eventHSParser.allowTypes = true;
				}
				if(_eventHSInterp == null)
				{
					_eventHSInterp = new Interp();
					_eventHSInterp.scriptObject = this;
					_eventHSInterp.allowStaticVariables = _eventHSInterp.allowPublicVariables = true;
					_eventHSInterp.errorHandler = err -> addTextToDebug(Std.string(err), FlxColor.RED);
					_eventHSInterp.staticVariables = ScriptPack.staticVariables;

					for(k => e in HScript.getDefaultVariables()) _eventHSInterp.variables.set(k, e);

					_eventHSInterp.variables.set("trace", Reflect.makeVarArgs(args -> addTextToDebug(args.join(', '), FlxColor.WHITE)));
				}
				_eventHSParser.line = 1;
				var code = value1 + '\n' + value2 + '\n' + value3 + '\n';
				try _eventHSInterp.execute(_eventHSParser.parseString(code)) catch(e) addTextToDebug(Std.string(e), FlxColor.RED);

			case 'Set Property':
				try
				{
					var killMe:Array<String> = value1.split('.');
					var um = value2.toLowerCase();
					var um2 = Std.parseFloat(value2);
					var value:Dynamic;
					if (um.indexOf('true') != -1 || um.indexOf('false') != -1)
						value = um.indexOf('true') != -1;
					else if (!CoolUtil.isNaN(um2))
						value = um2 is Float ? um2 : Std.int(um2);
					else value = value2;

					function setVarInArray(instance:Dynamic, variable:String, value:Dynamic, allowMaps:Bool = false):Any
					{
						final splitProps:Array<String> = variable.split('[');
						if(splitProps.length > 1)
						{
							var target:Dynamic = null;
							if(variables.exists(splitProps[0]))
							{
								target = variables.get(splitProps[0]) ?? target;
							}
							else
							{
								target = Reflect.getProperty(instance, splitProps[0]);
							}

							for (i in 1...splitProps.length)
							{
								final j:Dynamic = splitProps[i].substr(0, splitProps[i].length - 1);
								if(i >= splitProps.length - 1) // Last array
									target[j] = value;
								else // Anything else
									target = target[j];
							}
							return target;
						}

						if(variables.exists(variable)){
							variables.set(variable, value);
							return value;
						}
						Reflect.setProperty(instance, variable, value);
						return value;
					}

					function getVarInArray(instance:Dynamic, variable:String, allowMaps:Bool = false):Any{
						final splitProps:Array<String> = variable.split('[');
						if(splitProps.length > 1){
							var target:Dynamic = null;
							if(variables.exists(splitProps[0]))
							{
								target = variables.get(splitProps[0]) ?? target;
							}
							else
							{
								target = Reflect.getProperty(instance, splitProps[0]);
							}

							for (i in 1...splitProps.length)
							{
								final j:Dynamic = splitProps[i].substr(0, splitProps[i].length - 1);
								target = target[j];
							}
							return target;
						}

						if(variables.exists(variable))
						{
							final retVal:Dynamic = variables.get(variable);
							if(retVal != null) return retVal;
						}
						return Reflect.getProperty(instance, variable);
					}


					function getObjectDirectly(objectName:String):Dynamic
					{
						return getLuaObject(objectName, true) ?? getVarInArray(this, objectName);
					}
					function getPropertyLoopThingWhatever(killMe:Array<String>):Dynamic
					{
						var coverMeInPiss:Dynamic = getObjectDirectly(killMe[0]);
						for (i in 1...killMe.length - 1) coverMeInPiss = getVarInArray(coverMeInPiss, killMe[i]);
						return coverMeInPiss;
					}

					if (killMe.length > 1)
						setVarInArray(getPropertyLoopThingWhatever(killMe), killMe[killMe.length - 1], value);
					else
						setVarInArray(this, value1, value);
				}
				catch(e) Log(e, RED);
		}
		callOnScripts('onEvent', [eventName, value1, value2, value3, strumTime], true);
		// callOnScripts('onEvent$eventName', [eventName, value1, value2, value3, strumTime], true);
	}

	function moveCameraSection(?sec:Null<Int>):Void
	{
		sec = FlxMath.maxInt(sec ?? curSection, 0);

		if (SONG.notes[sec] == null) return;

		moveCamera(!SONG.notes[sec].mustHitSection);
		// moveCameraOnChar(gf != null && SONG.notes[curSection].gfSection ? 'gf' : SONG.notes[sec].mustHitSection ? 'boyfriend' : 'dad');
	}

	public var cameraPositions:Map<String, FlxPoint> = [];
	public var targetCharPos:FlxPoint;
	var _camTarget:String = '';

	public inline function moveCameraChar(char:String, ?forse:Bool = false)
	{
		moveCameraOnChar(char, forse);
	}
	public function moveCameraOnChar(char:String, ?forse:Bool = false)
	{
		_camTarget = char.toLowerCase().trim();
		if (forse || !isCameraOnForcedPos) setCharCamOffset(_camTarget, true);
		callOnScripts('onMoveCamera', [_camTarget]);
	}

	public dynamic function setCharCamOffset(char:String, moveCamera:Bool):FlxPoint
	{
		var charMidpoint:FlxPoint = cameraPositions.get(char) ?? FlxPoint.get();
		switch (char)
		{
			case 'dad' | 'opponent':					charMidpoint.copyFrom(dad.getCameraPosition()).add(150, -100).addPoint(dadCamOffset);
			case 'gf' | 'girlfriend' if (gf != null):	charMidpoint.copyFrom(gf.getCameraPosition()).addPoint(gfCamOffset);
			case 'bf' | 'boyfriend':					charMidpoint.copyFrom(boyfriend.getCameraPosition()).subtract(100, 100).addPoint(bfCamOffset);
		}
		cameraPositions.set(char, charMidpoint);
		targetCharPos = charMidpoint;
		if (moveCamera) camFollow?.set(charMidpoint.x, charMidpoint.y);
		return charMidpoint;
	}

	public inline function moveCamera(isDad:Bool)
	{
		moveCameraOnChar(gf != null && SONG.notes[curSection].gfSection ? 'gf' : isDad ? 'dad' : 'boyfriend');
	}

	public function snapCamFollowToPos(?x:Null<Float>, ?y:Null<Float>)
	{
		camFollow?.set(x ?? camFollow?.x ?? 0, y ?? camFollow?.y ?? 0);
		camFollowPos.setPosition(x, y);
	}

	// Any way to do this without using a different function? kinda dumb
	function onSongComplete()
	{
		if (songLoops)
		{
			_loopPending = true;
		}
		else
		{
			finishSong(false);
		}
	}


	public function finishSong(?ignoreNoteOffset:Bool):Void
	{
		var finishCallback:Void->Void = endSong; // In case you want to change it in a specific song.

		updateTime = false;
		songGroup.volume = 0;
		songGroup.pause();
		if (ClientPrefs.noteOffset <= 0 || ignoreNoteOffset)
			finishCallback();
		else
			finishTimer = new FlxTimer().start(ClientPrefs.noteOffset / 1000, _ -> finishCallback());
	}

	public var transitioning = false;
	public var seenResults = false;
	public function endSong():Void
	{
		#if TOUCH_CONTROLS
		removeHitbox();
		#end

		/*
		// Should kill you if you tried to cheat
		if (!startingSong){
			notes.forEach(function(daNote:Note){
				if (daNote.strumTime < songLength - Conductor.safeZoneOffset)
					health -= 0.05 * healthLoss;
			});
			for (daNote in unspawnNotes)
				if (daNote.strumTime < songLength - Conductor.safeZoneOffset)
					health -= 0.05 * healthLoss;

			if (doDeathCheck())	return;
		}
		*/

		// merTxt.visible = false;
		canPause = false;
		endingSong = true;
		inCutscene = false;
		setSongTime(songLength);
		updateTime = false;
		// camZooming = false;

		deathCounter = 0;
		seenCutscene = false;

		var ret:Dynamic = callOnScripts('onEndSong', null, false);
		if (!ScriptPack.resultIsStop(ret) && !transitioning)
		{
			playbackRate = 1;
			// if (!isStoryMode)
			// if (!seenResults && botplaySine == 0 && !replayMode && !practiceMode){
			// 	seenResults = true;
			// 	startedCountdown = false;
			// 	trace('Acc: ' + ratingPercent * 100 + '%');
			// 	trace('Score: ' + songScore);
			// 	trace('Misses: ' + songMisses);
			// 	MusicBeatState.switchState(new SongsState());
			// 	persistentUpdate = true;
			// 	camZooming = false;
			// 	return;
			// }
			#if EDITORS_ALLOWED
			if (chartingMode)
			{
				openChartEditor();
				return;
			}
			#end

			if (botplaySine == 0)
			{
				Highscore.save(SONG.song, {score: songScore, misses: songMisses, rating: ratingPercent.getDefault(0)}, Difficulty.getString());
			}

			chartingMode = false; // reset
			if (isStoryMode)
			{
				campaignScore += songScore;
				campaignMisses += songMisses;

				storyPlaylist.remove(storyPlaylist[0]);

				if (storyPlaylist.length <= 0)
				{
					// WeekData.loadTheFirstEnabledMod();
					/*
					if (!FreeplayState.doFreeplayInst)
						FlxG.sound.playMusic(Paths.music('freeplaymusic'));
					else
						FlxG.sound.playMusic(Paths.music('freakyMenu'));
					*/
					cancelMusicFadeTween();
					MusicBeatState.switchState(#if EDITORS_ALLOWED SongsState.inDebugFreeplay ? new SongsState() : #end new FreeplayState());
					// MusicBeatState.switchState(new StoryMenuState());

					// #if !switch
					// // if ()
					// if (!ClientPrefs.getGameplaySetting('practice', false) && !ClientPrefs.getGameplaySetting('botplay', false)){
					// 	StoryMenuState.weekCompleted.set(WeekData.weeksList[storyWeek], true);
					// 	/*
					// 	Highscore.saveWeekScore(WeekData.getWeekFileName(), campaignScore, campaignMisses, percent, Difficulty.getString());
					// 	*/
					// 	FlxG.save.data.weekCompleted = StoryMenuState.weekCompleted;
					// 	FlxG.save.flush();
					// }
					// #end
					// changedDifficulty = false;
					songGroup.stop();
				}
				else
				{
					// var difficulty:String = CoolUtil.getDifficultyFilePath();

					trace('LOADING NEXT SONG');
					trace(Paths.formatToSongPath(PlayState.storyPlaylist[0]));

					// FlxTransitionableState.skipNextTransIn = true;
					// FlxTransitionableState.skipNextTransOut = true;

					prevCamFollow = camFollow;
					prevCamFollowPos = camFollowPos;

					SONG = Song.loadFromJson(PlayState.storyPlaylist[0], PlayState.storyPlaylist[0]);
					songGroup.stop();

					cancelMusicFadeTween();
					LoadingState.loadAndSwitchState(new PlayState());
				}
			}
			else
			{
				trace('WENT BACK TO FREEPLAY??');
				cancelMusicFadeTween();
				MusicBeatState.switchState(#if EDITORS_ALLOWED SongsState.inDebugFreeplay ? new SongsState() : #end new FreeplayState());
				/*
				if (!FreeplayState.doFreeplayInst){
					FlxG.sound.playMusic(Paths.music('freeplaymusic'));
					Conductor.bpm = Json.parse(Paths.getTextFromFile('images/stupidBPMoptions.json')).bpmFreeplay;
				}
				else{
					FlxG.sound.playMusic(Paths.music('freakyMenu'));
					Conductor.bpm = Json.parse(Paths.getTextFromFile('images/stupidBPMoptions.json')).bpm;
				}*/
				// changedDifficulty = false;
				songGroup.stop();
			}
			transitioning = true;
		}
	}

	public function KillNotes()
	{
		for (i in strumLines)
		{
			i.destroyNotes();
		}
		#if NOTE_BACKWARD_COMPATIBILITY
		notes.clear();
		unspawnNotes.clear();
		#end
		eventNotes.clear();
	}

	public var totalPlayed:Int = 0;
	public var totalNotesHit:Float = 0.0;

	public var showCombo:Bool = false;
	public var showComboNum:Bool = true;
	public var showRating:Bool = true;

	function popUpScore(?note:Note, ?strumLine:StrumLine):Void
	{
		// boyfriend.playAnim('hey');

		// tryna do MS based judgment due to popular demand
		final daRating:Rating = Conductor.judgeNote(ratingsData, Math.abs(note.strumTime - Conductor.songPosition + ClientPrefs.ratingOffset) / FlxG.timeScale);

		totalNotesHit += daRating.ratingMod;
		note.ratingMod = daRating.ratingMod;
		if (!note.ratingDisabled) daRating.hits++;
		note.rating = daRating.name;

		if (daRating.noteSplash && strumLine != null)
			strumLine.spawnNoteSplashOnNote(note);

		if (practiceMode || cpuControlled)
		{
			if (popUpCombo != null)
				popUpCombo(daRating);
			return;
		}
		songScore += daRating.score;
		if (!note.ratingDisabled)
		{
			songHits++;
			totalPlayed++;
			RecalculateRating(false);
		}
		if (popUpCombo != null)
			popUpCombo(daRating);
	}

	public dynamic function popUpCombo(daRating:Rating) {}

	public var strumsBlocked:Array<Bool> = [];
	function onKeyPress(event:KeyboardEvent):Void
	{
		if (controls.controllerMode) return;
		#if debug
		//Prevents crash specifically on debug without needing to try catch shit
		@:privateAccess if (!FlxG.keys._keyListMap.exists(event.keyCode)) return;
		#end
		if(FlxG.keys.checkStatus(event.keyCode, JUST_PRESSED)) keyPressed(getKeyFromEvent(keysArray, event.keyCode));
	}

	// var neededPressedNotes:Array<Note> = [];
	function keyPressed(key:Int)
	{
		// writeToReplay(key, 'justPr');
		if(playerStrumLine == null || playerStrumLine.cpuControlled || paused || key < 0 || !generatedMusic || endingSong || boyfriend.stunned) return;

		// had to name it like this else it'd break older scripts lol
		if(ScriptPack.resultIsStop(callOnScripts('preKeyPress', [key], true)))
			return;

		// more accurate hit time for the ratings?
		final lastTime:Float = Conductor.songPosition;
		if(Conductor.songPosition >= 0)
			Conductor.songPosition = inst.getCurrentTime();

		// // heavily based on my own code LOL if it aint broke dont fix it
		// var pressNotes:Array<Note> = [];
		// var notesStopped:Bool = false;

		// obtain notes that the player can hit
		var notes = playerStrumLine.spawnedNotes;
		var sortedNotesList:Array<Note> = notes.filter(function(n:Note):Bool
			return n != null && n.noteDataReal == key && !n.isSustainNote
				&& !strumsBlocked[n.noteDataReal] && n.canBeHit && n.mustPress && !n.tooLate && !n.wasGoodHit && !n.blockHit // canHit
		);
		sortedNotesList.sort(sortHitNotes);

		if (sortedNotesList.length != 0) // slightly faster than doing `> 0` lol
		{
			var funnyNote:Note = sortedNotesList.pop(); // front note

			if (sortedNotesList.length != 0)
			{
				final doubleNote:Note = sortedNotesList.pop();

				if (doubleNote.noteDataReal == funnyNote.noteDataReal)
				{
					// if the note has a 0ms distance (is on top of the current note), kill it
					if (Math.abs(doubleNote.strumTime - funnyNote.strumTime) < 1.0)
					{
						playerStrumLine.destroyNote(doubleNote);
					}
					else if (doubleNote.strumTime < funnyNote.strumTime)
					{
						// replace the note if its ahead of time (or at least ensure "doubleNote" is ahead)
						funnyNote = doubleNote;
					}
				}
			}

			goodNoteHit(funnyNote, playerStrumLine);
		}
		else if (!ClientPrefs.ghostTapping && !boyfriend.stunned)
		{
			callOnScripts('onGhostTap', [key]);
			noteMissPress(Note.mapNoteData.get(StrumsManiaData.data.get(strumsManiaType)[key]));
		}

		/*
		if (sortedNotesList.length > 0){
			for (epicNote in sortedNotesList){
				for (doubleNote in pressNotes)
					if (Math.abs(doubleNote.strumTime - epicNote.strumTime) < 1){
						destroyNote(doubleNote);
					}else notesStopped = true;

				// eee jack detection before was not super good
				if (!notesStopped){
					goodNoteHit(epicNote);
					pressNotes.push(epicNote);
				}
			}
		}else
			noteMissPress(key);
		*/
		// more accurate hit time for the ratings? part 2 (Now that the calculations are done, go back to the time it was before for not causing a note stutter)
		Conductor.songPosition = lastTime;

		final spr:StrumNote = playerStrums.members[key];
		if (strumsBlocked[key] != true && spr != null && spr.animation.name != 'confirm')
		{
			playerStrumLine.strumPlayAnim(spr, "pressed");
		}
	}


	public static function sortHitNotes(a:Note, b:Note):Int
	{
		if (a.lowPriority && !b.lowPriority) return 1;
		if (!a.lowPriority && b.lowPriority) return -1;
		return FlxSort.byValues(FlxSort.ASCENDING, a.strumTime, b.strumTime);
	}

	function onKeyRelease(event:KeyboardEvent):Void
	{
		final key:Int = getKeyFromEvent(keysArray, event.keyCode);
		if(controls.controllerMode || key < 0) return;
		keyReleased(key);
	}

	@:access(game.backend.utils.Controls)
	function keyReleased(data:Int)
	{
		// writeToReplay(key, 'release');
		if(cpuControlled || paused || !startedCountdown
			|| controls.controllerMode && controls.__gamepadHelper(Controls.instance.gamepadBinds.get(keysArray[data]), FlxG.gamepads.anyPressed)
			|| !controls.controllerMode && FlxG.keys.anyPressed(Controls.instance.keyboardBinds.get(keysArray[data]))
		)
			return;
		playerStrumLine.stopHoldCoversByNoteData(data);
		playerStrumLine.strumPlayAnim(playerStrums.members[data], "static");
		// daNote.disconnectHoldCover();
	}

	public static function getKeyFromEvent(arr:Array<String>, key:FlxKey):Int
	{
		if(key == NONE)
			return -1;
		var note:Array<FlxKey>;
		for (i in 0...arr.length)
		{
			note = Controls.instance.keyboardBinds.get(arr[i]);
			for (j in 0...note.length)
				if(key == note[j])
					return i;
		}
		return -1;
	}

	// Hold notes
	// HOLDING
	var holdArray:Array<Bool> = [];
	var pressArray:Array<Bool> = [];
	var releaseArray:Array<Bool> = [];
	function keyShit():Void
	{
		holdArray.clear();
		pressArray.clear();
		releaseArray.clear();
		/*if (replayMode){
			pressArray = releaseArray = [for(_ in keysArray) false];

			// while (replayHandler.data.press.length > 0){
			// 	var leStrumTime:Float = replayHandler.data.press[0].hitTime;
			// 	if (Conductor.songPosition < replayHandler.data.press[0].hitTime) break;
			// 	var dir = replayHandler.data.press[0].direction;
			// 	holdArray[dir] = true;
			// 	// pressArray[dir] = false;
			// 	// releaseArray[dir] = false;
			// 	trace('hold $dir ass $leStrumTime');
			// 	replayHandler.data.press.shift();
			// }

			while (replayHandler.data.justPress.length > 0){
				var leStrumTime:Float = replayHandler.data.justPress[0].hitTime;
				if (Conductor.songPosition < replayHandler.data.justPress[0].hitTime) break;
				var dir = replayHandler.data.justPress[0].direction;
				pressArray[dir] = true;
				holdArray[dir] = true;
				// releaseArray[dir] = false;
				trace('justPressed $dir ass $leStrumTime  ${Conductor.songPosition}');
				replayHandler.data.justPress.shift();
			}

			while (replayHandler.data.release.length > 0){
				var leStrumTime:Float = replayHandler.data.release[0].hitTime;
				if (Conductor.songPosition < replayHandler.data.release[0].hitTime) break;
				var dir = replayHandler.data.release[0].direction;
				releaseArray[dir] = true;
				holdArray[dir] = false;
				// holdArray[dir] = false;
				// pressArray[dir] = false;
				trace('release $dir ass $leStrumTime  ${Conductor.songPosition}');
				replayHandler.data.release.shift();
			}
			// trace (pressArray , holdArray , releaseArray);
		}else*/{
			var note;
			for (i in 0...keysArray.length)
			{
				note = keysArray[i];
				holdArray.push(controls.pressed(note));
				if(controls.controllerMode)
				{
					pressArray.push(controls.justPressed(note));
					releaseArray.push(controls.justReleased(note));
				}
			}
		}
		// TO DO: Find a better way to handle controller inputs, this should work for now
		// if(pressArray.contains(true))
		{
			// if (pressArray == []) pressArray = [for(key in keysArray) controls.justPressed(key)];
			for (i in 0...pressArray.length)
				if(pressArray[i] == true && strumsBlocked[i] != true)
					keyPressed(i);
		}

		// FlxG.watch.addQuick('asdfa', upP);
		if (startedCountdown && !boyfriend.stunned && generatedMusic)
		{
			// rewritten inputs???
			// if (notes.length > 0)
			// notes.forEachAlive(function(daNote:Note){
			// 	// hold note functions
			// 	if (strumsBlocked[daNote.noteDataReal] != true && daNote.isSustainNote && holdArray[daNote.noteDataReal] == true && daNote.canBeHit
			// 		&& daNote.mustPress && !daNote.tooLate && !daNote.wasGoodHit && !daNote.blockHit)
			// 		goodNoteHit(daNote);
			// });

			var notes = playerStrumLine.spawnedNotes;
			if (notes.length > 0)
			{
				for (n in notes)
				{
					var isHolding:Bool = false;
					#if TOUCH_CONTROLS
					if (hitbox != null)
						isHolding = (hitbox.members[n.noteDataReal].status == HintStatus.PRESSED);
					#end

					if (!isHolding) isHolding = holdArray[n.noteDataReal];

					if(
						n != null && n.mustPress
						&& n.isSustainNote && isHolding
						&& !strumsBlocked[n.noteDataReal] && n.canBeHit
						&& n.parent != null && n.parent.wasGoodHit
						&& !n.tooLate && !n.blockHit
					)
						goodNoteHit(n, playerStrumLine);
				}
			}

			var isHoldingAny:Bool = false;
			#if TOUCH_CONTROLS
			if (hitbox != null)
			{
				hitbox.forEach((hint:MobileHint) -> {
					if (hint.status == HintStatus.PRESSED)
					{
						isHoldingAny = true;
						return;
					}
				});
			}
			#end

			if (!isHoldingAny) isHoldingAny = holdArray.contains(true);

			if (playerCharacters.length != 0 && isHoldingAny/* && !endingSong*/)
				for (i in playerCharacters)
					if (i.singDuration != 0)
						i.holdTimer = Math.min(i.holdTimer, Conductor.stepCrochet * 0.0011 * i.singDuration - FlxG.elapsed * 11);
			/*else if (boyfriend.animation.curAnim != null)
				if(boyfriend.animation.curAnim.name.startsWith('sing')
				&& !boyfriend.animation.curAnim.name.endsWith('miss'))
					if (boyfriend.singDuration != 0 && boyfriend.holdTimer > Conductor.stepCrochet * 0.0011 * boyfriend.singDuration)
						boyfriend.dance();
					else if (boyfriend.animation.curAnim.finished && boyfriend.holdTimer > Conductor.stepCrochet * 0.0011)
						boyfriend.dance();*/
		}

		// TO DO: Find a better way to handle controller inputs, this should work for now
		// if(/*strumsBlocked.contains(true) &&*/ releaseArray.contains(true))
			for (i in 0...releaseArray.length)
				if(releaseArray[i] || strumsBlocked[i] == true)
					keyReleased(i);
	}

	public var durationVibrate:Float = 150;
	public var intensityVibrate:Int = 50;

	function noteMiss(daNote:Note, strumLine:StrumLine, removeNote:Bool = true, ?char:Character):Void{ // You didn't hit the key and let it go offscreen, also used by Hurt Notes
		if(!ScriptPack.resultIsStop(callOnLuas('preNoteMiss', [getIndexOfNotes(daNote, strumLine), daNote.noteData, daNote.noteType, daNote.isSustainNote])))
			callOnHScript('preNoteMiss', [daNote, strumLine]);

		// Dupe note remove
		if (removeNote)
		{
			for(note in strumLine.spawnedNotes)
			{
				if (daNote.ID != note.ID
					&& daNote.mustPress
					&& daNote.noteDataReal == note.noteDataReal
					&& daNote.isSustainNote == note.isSustainNote
					&& Math.abs(daNote.strumTime - note.strumTime) < 1)
						strumLine.destroyNote(note);
			};
		}

		combo = 0;
		health -= daNote.missHealth * healthLoss;

		if (SONG.needsVoices && vocals.isValid())
				vocals.volume = 0;

		if (instakillOnMiss) doDeathCheck(true);

		// For testing purposes
		// trace(daNote.missHealth);
		songMisses++;
		if (!practiceMode)	songScore -= 10;

		totalPlayed++;
		RecalculateRating(true);

		if (playMissSound != null) playMissSound();
		if (controls.controllerMode) GamepadUtil.doVibrate(durationVibrate, intensityVibrate);
		final char = char ?? (daNote.gfNote && gf != null ? gf : boyfriend);
		if (!daNote.noMissAnimation && char.hasMissAnimations){
			var mainAnimName:String = char.singAnimsPrefix + singAnimations[daNote.noteData] + "miss";
			if (!char.playAnim(mainAnimName + daNote.animSuffix, !daNote.isSustainNote || char.forceSing))
				char.playAnim(mainAnimName, !daNote.isSustainNote || char.forceSing);
			if (char != gf && combo > 5 && gf != null && gf.playAnim('sad', true)) // play ":("
				gf.specialAnim = true;
			if (char.status != SINGLE_SING) char.status = SINGLE_SING;
		}
		daNote.disconnectHoldCover();

		if(!ScriptPack.resultIsStop(callOnLuas('noteMiss', [getIndexOfNotes(daNote, strumLine), daNote.noteData, daNote.noteType, daNote.isSustainNote])))
			callOnHScript('noteMiss', [daNote, strumLine]);
	}

	public dynamic function playMissSound()
	{
		FlxG.sound.play(Paths.soundRandom('missnote', 1, 3), FlxG.random.float(0.9, 1.05) * ClientPrefs.missVolume).pitch = FlxG.random.float(0.85, 1.15);
	}

	function noteOpponentMiss(daNote:Note, strumLine:StrumLine, removeNote:Bool = true, ?char:Character):Void // get real
	{
		if(!ScriptPack.resultIsStop(callOnLuas('preNoteOpponentMiss', [getIndexOfNotes(daNote, strumLine), daNote.noteData, daNote.noteType, daNote.isSustainNote])))
			callOnHScript('preNoteOpponentMiss', [daNote, strumLine]);

		// Dupe note remove
		if (removeNote){
			for(note in strumLine.spawnedNotes)
			{
				if (daNote.ID != note.ID
					&& !daNote.mustPress
					&& daNote.noteDataReal == note.noteDataReal
					&& daNote.isSustainNote == note.isSustainNote
					&& Math.abs(daNote.strumTime - note.strumTime) < 1)
						strumLine.destroyNote(note);
			};
		}

		health += daNote.missHealth;

		if(SONG.needsVoices)
			if (vocalsDAD.isValid())
				vocalsDAD.volume = 0;
			else if (vocals.isValid())
				vocals.volume = 0;

		final char = char ?? (daNote.gfNote && gf != null ? gf : dad);
		if (!daNote.noMissAnimation && char.hasMissAnimations)
		{
			var mainAnimName:String = char.singAnimsPrefix + singAnimations[daNote.noteData] + "miss";
			if (!char.playAnim(mainAnimName + daNote.animSuffix, !daNote.isSustainNote || char.forceSing))
				char.playAnim(mainAnimName, !daNote.isSustainNote || char.forceSing);
			// if (char != gf && gf != null && gf.playAnim('laught', true))
			// 	gf.specialAnim = true; // play "HEHEHA"
			if (char.status != SINGLE_SING) char.status = SINGLE_SING;
		}
		daNote.disconnectHoldCover();

		if(!ScriptPack.resultIsStop(callOnLuas('noteOpponentMiss', [getIndexOfNotes(daNote, strumLine), daNote.noteData, daNote.noteType, daNote.isSustainNote])))
			callOnHScript('noteOpponentMiss', [daNote, strumLine]);
	}
	function noteMissPress(direction:Int = 1):Void // You pressed a key when there was no notes to press for this key
	{
		if (ClientPrefs.ghostTapping) return; // fuck it

		callOnScripts('preNoteMissPress', [direction]);

		if (boyfriend.stunned)
		{
			callOnScripts('noteMissPress', [direction]);
			return;
		}

		health -= 0.05 * healthLoss;

		if (SONG.needsVoices && vocals.isValid()) vocals.volume = 0;

		if (instakillOnMiss) doDeathCheck(true);

		if (combo > 20 && gf != null && gf.playAnim('sad', true)) // play ":("
			gf.specialAnim = true;

		combo = 0;

		if (!practiceMode)	songScore -= 10;
		if (!endingSong)	songMisses++;

		totalPlayed++;
		RecalculateRating(true);

		if (playMissSound != null) playMissSound();
		// FlxG.sound.play(Paths.sound('missnote1'), 1, false);
		// FlxG.log.add('played imss note');
		if (controls.controllerMode) GamepadUtil.doVibrate(durationVibrate, Std.int(intensityVibrate / 3));
		/*
			boyfriend.stunned = true;

			// get stunned for 1/60 of a second, makes you able to
			new FlxTimer().start(1 / 60, function(tmr:FlxTimer)
			{
				boyfriend.stunned = false;
			});
		 */

		for (i in playerCharacters)
			if (i.hasMissAnimations)
				i.sing(singAnimations[direction] + 'miss', false);
		callOnScripts('noteMissPress', [direction]);
	}
	inline function getIndexOfNotes(note:Note, strumLine:StrumLine):Int
	{
		#if NOTE_BACKWARD_COMPATIBILITY
		return notes.members.indexOf(note);
		#else
		return strumLine.spawnedNotes.indexOf(note);
		#end
	}

	function opponentNoteHit(note:Note, strumLine:StrumLine):Void
	{
		if(note.hitByOpponent) return;

		if(!ScriptPack.resultIsStop(callOnLuas('preOpponentNoteHit', [getIndexOfNotes(note, strumLine), note.noteData, note.noteType, note.isSustainNote])))
			callOnHScript('preOpponentNoteHit', [note, strumLine]);

		camZooming = true;
		if (!note.noAnimation && !note.noSingAnimation){
			final char = note.gfNote && gf != null ? gf : dad;
			// if (char != null)
			char.sing(singAnimations[note.noteData] + note.animSuffix, !note.isSustainNote, note.nextNote != null);
		}
		if (SONG.needsVoices)
			if (vocalsDAD.isValid())
				vocalsDAD.volume = 1;
			else if (vocals.isValid())
				vocals.volume = 1;
		if (note.playStrum)
			strumLine.strumPlayConfirm(note.parentStrum, Conductor.stepCrochet * 0.00125);
		if (!note.isSustainNote)
			strumLine.spawnNoteSplashOnNote(note);
		note.hitByOpponent = note.noteWasHit = true;

		strumLine.spawnHoldCoverOnNote(note);

		// Someone said it's boring that the game doesn't have a health leak modification, and well.... Prevet Grafex, poshli igrat basketball.
		var drain = note.hitHealth * healthDrainPercent;
		if (drain > 0 && health > drain + 0.1 + healthBounds.min)
			health -= drain;

		if(!ScriptPack.resultIsStop(callOnLuas('opponentNoteHit', [getIndexOfNotes(note, strumLine), note.noteData, note.noteType, note.isSustainNote])))
			callOnHScript('opponentNoteHit', [note, strumLine]);

		if (!note.isSustainNote)
		{
			strumLine.destroyNote(note);
		}
	}
	// function writeToReplay(direction:Int, type:String = 'none'){
	// 	if (replayHandler == null || cpuControlled || replayMode || direction < 0) return;
	// 	var newData:DeKeyV1 = {
	// 		hitTime: Conductor.songPosition,
	// 		direction: direction
	// 	}
	// 	switch(type){
	// 		case 'justPr': replayHandler.data.justPress.push(newData);
	// 		case 'hold': replayHandler.data.press.push(newData);
	// 		case 'release': replayHandler.data.release.push(newData);
	// 	}
	// 	// trace('[$type]  $newData');
	// }
	function goodNoteHit(note:Note, strumLine:StrumLine):Void
	{
		// writeToReplay(note.noteData, 'hold');
		if(note.wasGoodHit || cpuControlled && note.ignoreNote) return;

		if(!ScriptPack.resultIsStop(callOnLuas('preGoodNoteHit', [getIndexOfNotes(note, strumLine), note.noteData, note.noteType, note.isSustainNote])))
			callOnHScript('preGoodNoteHit', [note, strumLine]);

		note.wasGoodHit = note.noteWasHit = true;

		if (note.hitCausesMiss)
		{
			switch (note.noteType)
			{
				case 'Hurt Note' if (!note.noMissAnimation): // Hurt note
					if (boyfriend.playAnim('hurt', true))
					{
						boyfriend.specialAnim = true;
					}
			}

			noteMiss(note, strumLine);
			if (!note.isSustainNote)
			{
				strumLine.spawnNoteSplashOnNote(note);
				strumLine.destroyNote(note);
			}
			return;
		}

		if (!note.noAnimation && !note.noSingAnimation)
		{
			final char = note.gfNote && gf != null ? gf : boyfriend;
			char.sing(singAnimations[note.noteData] + note.animSuffix, !note.isSustainNote, note.nextNote != null);
		}
		health += note.hitHealth * healthGain;

		if (note.playStrum)
		{
			if(cpuControlled)
				strumLine.strumPlayConfirm(note.parentStrum, Conductor.stepCrochet * 0.00125);
			else
				note.parentStrum?.playAnim('confirm', true);
		}

		strumLine.spawnHoldCoverOnNote(note);

		if(!ScriptPack.resultIsStop(callOnLuas('goodNoteHit', [getIndexOfNotes(note, strumLine), note.noteData, note.noteType, note.isSustainNote])))
			callOnHScript('goodNoteHit', [note, strumLine]);

		if (SONG.needsVoices && vocals.isValid()) vocals.volume = 1;


		if (note.isSustainNote) return;

		combo++;
		if (maxCombo < combo)
			maxCombo = combo;
		// if (combo > 9999) combo = 9999; // now funny
		popUpScore(note, strumLine);
		if (ClientPrefs.hitsoundVolume > 0 && !note.hitsoundDisabled)
			FlxG.sound.play(Paths.sound('hitsound'), ClientPrefs.hitsoundVolume);
		strumLine.destroyNote(note);
	}

	/*
	function spawnNoteSplashOnNote(note:Note)
	{
		if (ClientPrefs.noteSplashes && !note.noteSplashDisabled && note.playStrum)
		{
			final strum:StrumNote = note.parentStrum;
			if(strum != null && strum.alpha > 0.4 && strum.visible)
			{
				spawnNoteSplash(strum, note.noteData, note);
			}
		}
	}

	public function spawnNoteSplash(strum:StrumNote, data:Int, ?note:Note)
	{
		if (!ScriptPack.resultIsStop(callOnHScript("onSpawnNoteSplash", [strum, data, note])))
			grpNoteSplashes.recycle(NoteSplash).setupNoteSplash(strum.x + strum.width / 2, strum.y + strum.height / 2, data, note?.noteSplashTexture, note);
	}
	*/

	override function destroy()
	{
		/*
		FlxG.signals.preUpdate.remove(checkMainThreadActivity);
		ThreadUtil.stopThread("PlayState.FixWindowDrag");
		*/

		scriptPack.destroy();
		FlxG.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
		FlxG.stage.removeEventListener(KeyboardEvent.KEY_UP, onKeyRelease);

		songGroup.destroy();
		songGroup = null;

		instance = null;
		setTweens(true); // okay ookkaayy
		FlxG.plugins.remove(pauseTweenManager);
		FlxG.plugins.remove(pauseTimerManager);
		pauseTweenManager.clear();
		mainTweenManager = null;
		mainTimerManager = null;
		flixel.util.FlxDestroyUtil.putArray([
			BF_POS, GF_POS, DAD_POS,
			bfCamOffset, dadCamOffset, gfCamOffset,
			strumLine, camFollow
		].concat([for (_ => i in cameraPositions) i])
		);
		cameraPositions.clear();
		playbackRate = 1;
		Note.globalRgbShaders.clearArray();
		HealthIcon.clearDatas();
		remove(strumLineNotes, true);
		strumLineNotes = null;
		#if NOTE_BACKWARD_COMPATIBILITY
		unspawnNotes.clear();
		#end
		super.destroy();
		playerCharacters.clearArray();
		WindowUtil.resetTitle();
		ChartingState.botPlayChartMod = false;
	}

	public function cancelMusicFadeTween()
	{
		for (i in songGroup.sounds)
		{
			if (i.fadeTween == null)
				continue;
			i.fadeTween.cancel();
			i.fadeTween = null;
		}
	}

	function vsyns()
	{
		if (songGroup.sounds.length > 0 && songGroup.sounds[0].time >= -ClientPrefs.noteOffset)
		{
			final maxDelay = 20 * playbackRate;
			final realTime = Conductor.songPosition - Conductor.offset;
			for (i in songGroup.sounds)
			{
				if (Math.abs(i.time - realTime) > maxDelay)
				{
					resyncVocals();
					break;
				}
			}
		}
	}

	@:noCompletion var lastStepHit:Int = -1;
	override function stepHit()
	{
		super.stepHit();
		if (curStep == lastStepHit) return;

		lastStepHit = curStep;
		setOnLuas('curStep', curStep);
		callOnScripts('onStepHit', [curStep]);
	}

	public var camZoomingInterval:Int = 0;
	@:noCompletion public var camZoomingFreq(get, set):Int;
	@:noCompletion inline function get_camZoomingFreq():Int return camZoomingInterval;
	@:noCompletion inline function set_camZoomingFreq(i:Int):Int return camZoomingInterval = i;
	public var camZoomingOffset:Int = 0;
	public var iconBOBFreq:Int = 1;

	public dynamic function beatIcons()
	{
		iconsGroup.forEach(icon -> icon.onBeatScale());
	}

	public function danceCharacter(char:Character, curBeat:Int, danceEveryNumBeats:Int)
	{
		if (char.stunned || curBeat % danceEveryNumBeats != 0)
			return;

		// // fixes danceEveryNumBeats = 1 on idle dances (and idles with loop points)
		// final force:Bool = (char.danceEveryNumBeats == 1 && _curAnim.curFrame > (_curAnim.frameRate > 0 ? Math.round(4 / (24 * _curAnim.frameDuration)) : 0))
		// 				&& (!_curAnim.looped || (_curAnim.looped && _curAnim.loopPoint > 0));
		char.dance();
	}
	public dynamic function danceCharacters(curBeat:Int)
	{
		if (gf != null)
			danceCharacter(gf, curBeat, Math.round(gfSpeed * gf.danceEveryNumBeats));

		danceCharacter(boyfriend, curBeat, boyfriend.danceEveryNumBeats);
		danceCharacter(dad, curBeat, dad.danceEveryNumBeats);
	}

	@:noCompletion var lastBeatHit:Int = -1;
	override function beatHit()	{
		if (lastBeatHit == curBeat) return;

		// trace('BEAT HIT: ' + curBeat + ', LAST HIT: ' + lastBeatHit);

		// if (generatedMusic)	notes.sort(FlxSort.byY, ClientPrefs.downScroll ? FlxSort.ASCENDING : FlxSort.DESCENDING);

		if (iconBOBFreq > 0 && curBeat % iconBOBFreq == 0)
			beatIcons();

		danceCharacters(curBeat);

		if (ClientPrefs.camZooms && camZooming && camZoomingInterval > 0 && curBeat % camZoomingInterval == camZoomingOffset /*&& camGame.zoom < 1.35*/)
		{
			/*if (!camGame.tweeningZoom)*/	camGame.zoom += 0.015 * camZoomingMult;
			/*if (!camHUD.tweeningZoom)*/	camHUD.zoom += 0.03 * camZoomingMult;
		}

		super.beatHit();
		lastBeatHit = curBeat;

		setOnLuas('curBeat', curBeat); // DAWGG?????
		callOnScripts('onBeatHit', [curBeat]);
	}

	public var lastSection:Int = 0;
	public var addZoomOnSection:Bool = true;
	override function sectionHit() {
		if (lastSection == curSection) return;
		if (SONG.notes[curSection] != null)
		{
			if (generatedMusic && !endingSong && !isCameraOnForcedPos) moveCameraSection(curSection);

			if (ClientPrefs.camZooms && addZoomOnSection && camZooming && camZoomingInterval == 0 /*&& camGame.zoom < 1.35*/)
			{
				/*if (!camGame.tweeningZoom)*/	camGame.zoom += 0.015 * camZoomingMult;
				/*if (!camHUD.tweeningZoom)*/	camHUD.zoom += 0.03 * camZoomingMult;
			}

			if (SONG.notes[curSection].changeBPM)
			{
				Conductor.bpm = SONG.notes[curSection].bpm;
				setOnLuas('curBpm', Conductor.bpm);
				setOnLuas('crochet', Conductor.crochet);
				setOnLuas('stepCrochet', Conductor.stepCrochet);
			}

			setOnLuas('mustHitSection', SONG.notes[curSection].mustHitSection);
			setOnLuas('altAnim', SONG.notes[curSection].altAnim);
			setOnLuas('gfSection', SONG.notes[curSection].gfSection);
		}
		super.sectionHit();

		setOnLuas('curSection', curSection);
		callOnScripts('onSectionHit', [curSection]);
		lastSection = curSection;
	}

	public inline function callOnScripts(funcToCall:String, ?args:Array<Dynamic>, ?ignoreStops:Bool, ?exclusions:Array<String>):Dynamic
		return scriptPack.call(funcToCall, args, ignoreStops, exclusions);

	public inline function callOnHScript(funcToCall:String, ?args:Array<Dynamic>, ?ignoreStops:Bool, ?exclusions:Array<String>):Dynamic
		return scriptPack.callOnHScript(funcToCall, args, ignoreStops, exclusions);

	public inline function setOnHScript(variable:String, arg:Dynamic)
		return scriptPack.setOnHScript(variable, arg);

	public inline function callOnLuas(event:String, ?args:Array<Dynamic>, ?ignoreStops:Bool, ?exclusions:Array<String>):Dynamic
		#if LUA_ALLOWED
		return scriptPack.callOnLuas(event, args, ignoreStops, exclusions);
		#else
		return null;
		#end

	public inline function setOnLuas(variable:String, arg:Dynamic)
		#if LUA_ALLOWED
		return scriptPack.setOnLuas(variable, arg);
		#else
		return arg;
		#end

	function strumPlayAnim(spr:StrumNote, time:Float){
		if (spr == null) return;
		spr.playAnim('confirm', true);
		spr.resetAnim = Math.max(time, 0.15);
	}

	public var ratingName:String = '?';
	public var ratingPercent:Float = 0;
	public var ratingFC:String;

	public function RecalculateRating(badHit:Bool = false){
		setOnLuas('score', songScore);
		setOnLuas('misses', songMisses);
		setOnLuas('hits', songHits);

		var ret:Dynamic = callOnScripts('onRecalculateRating', null, true);
		if (!ScriptPack.resultIsStop(ret))
		{
			ratingName = '?';
			if (totalPlayed != 0) // Prevent divide by 0
			{
				// Rating Percent
				ratingPercent = CoolUtil.boundTo(totalNotesHit / totalPlayed, 0, 1);
				// trace((totalNotesHit / totalPlayed) + ', Total: ' + totalPlayed + ', notes hit: ' + totalNotesHit);

				// Rating Name
				if (ratingPercent < 1.0)
				{
					final rating = ratingPercent * 100;
					for (i in 0...ratingStuff.length - 1)
					{
						if (rating < ratingStuff[i].percent)
						{
							ratingName = ratingStuff[i].name;
							break;
						}
					}
				}
				else
				{
					ratingName = ratingStuff[ratingStuff.length - 1].name; // Uses last string
				}
			}

			if (fullComboFunction != null)
				fullComboFunction();
			else
				ratingFC = "";
		}
		if (updateScore != null) updateScore(badHit);
		setOnLuas('rating', ratingPercent);
		setOnLuas('ratingName', ratingName);
		setOnLuas('ratingFC', ratingFC);
	}

	public dynamic function fullComboFunction()
	{
		ratingFC = (
			songMisses < 1 ?
			(
				bads > 0 || shits > 0 ?	"FC"
				: goods > 0 ?			"GFC"
				: sicks > 0 ?			"SFC"
				: 						""
			)
			:
			songMisses < 10 ?
				"SDCB"
			:
				"Clear"
		);
	}
}
