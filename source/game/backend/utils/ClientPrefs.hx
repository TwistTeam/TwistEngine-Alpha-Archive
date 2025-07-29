package game.backend.utils;

import flixel.input.gamepad.FlxGamepadInputID;
import flixel.input.keyboard.FlxKey;
import flixel.math.FlxMath;
import flixel.util.FlxSave;

import game.FPS.FPSAligh;
import game.backend.assets.ModsFolder;
import game.backend.system.scripts.GlobalScript;
import game.backend.system.EffectsScreen;
import game.objects.ScreenPlugin;

import openfl.display3D.Context3DMipFilter;
import openfl.display3D.Context3DTextureFilter;
import openfl.events.Event;

import haxe.ds.StringMap;

import lime.app.Application;

#if target.threaded
import sys.thread.Thread;
#end

// Special types
typedef Percent = Float;
typedef Category = String;

typedef RuntimeClientPrefsData = Dynamic;
class ClientPrefs
{
	@:noCompletion var saveFields:Array<String>;

	public var downScroll:Bool = false;
	public var middleScroll:Bool = false;
	public var opponentStrums:Bool = true;

	public var showFPS(default, set):Bool = true;
	@:noCompletion function set_showFPS(i)
	{
		if (Main.fpsVar != null)
			Main.fpsVar.visible = i;
		return showFPS = i;
	}
	public var fpsAligh(default, set):String = "LEFT_TOP";
	function set_fpsAligh(i)
	{
		if (Main.fpsVar != null)
			Main.fpsVar.alignment = FPSAligh.fromString(i);
		return fpsAligh = i;
	}
	public var fpsScale(default, set):Percent = 1;
	@:noCompletion function set_fpsScale(i)
	{
		if (Main.fpsVar != null)
			Main.fpsVar.scaleX = Main.fpsVar.scaleY = i;
		return fpsScale = i;
	}
	public var showCurretFPS:Bool = true;
	public var showMemory(default, set):Bool = true;
	@:noCompletion function set_showMemory(i)
	{
		if (Main.fpsVar != null)
			Main.fpsVar.showMem = i;
		return showMemory = i;
	}
	public var showSystemInfo(default, set):Bool = false;
	@:noCompletion function set_showSystemInfo(i)
	{
		#if DEV_BUILD
		if (Main.fpsVar != null)
			Main.fpsVar.showSysInfo = i;
		#end
		return showSystemInfo = i;
	}
	public var showDebugInfo(default, set):Bool = false;
	@:noCompletion function set_showDebugInfo(i)
	{
		#if DEV_BUILD
		if (Main.fpsVar != null)
			Main.fpsVar.showDebugInfo = i;
		#end
		return showDebugInfo = i;
	}

	public var globalAntialiasing(default, set):Bool = FlxSprite.allowAntialiasing;
	@:noCompletion function set_globalAntialiasing(i:Bool):Bool
	{
		return FlxSprite.allowAntialiasing = globalAntialiasing = i;
	}
	public var cacheOnGPU:Bool = #if hl false #else true #end; //?
	public var multiThreading:Bool = true;
	public var lowQuality:Bool = false;
	// public var vsyncDraw:Bool = false;
	public var framerate(default, set):Int = 144;
	function set_framerate(i:Int):Int
	{
		var drawI:Int = getValidDrawFrameRate(i);
		if (drawI > getValidDrawFrameRate(FlxG.drawFramerate))
		{
			FlxG.updateFramerate = i;
			FlxG.drawFramerate = drawI;
		}
		else
		{
			FlxG.drawFramerate = drawI;
			FlxG.updateFramerate = i;
		}
		return framerate = i;
	}

	// function getValidDrawFrameRate(i:Int):Int
	// {
	// 	return #if (!html5 && !switch) vsyncDraw ? FlxMath.minInt(i, Std.int(Application.current.window.displayMode.refreshRate)) : #end i;
	// }

	inline function getValidDrawFrameRate(i:Int):Int
	{
		return i;
	}

	public var noteSplashes:Bool = true;
	public var noteSplashesScale:Percent = 1.0;
	public var splashAlpha:Percent = 1.0;

	/*
	public var globalTextureFilter(default, set):String = LINEAR;
	function set_globalTextureFilter(i)
	{
		return FlxSprite.defaultTextureFilter = globalTextureFilter = i;
	}
	*/
	/*
	public var globalMipFilter(default, set):String = FlxSprite.defaultMipFilter;
	function set_globalMipFilter(i)
	{
		globalMipFilter = i;
		return FlxSprite.defaultMipFilter = i;
	}
	*/
	public var globalMipMapsEnable(default, set):Bool = #if mobile false #else FlxSprite.defaultMipFilter != MIPNONE #end;
	function set_globalMipMapsEnable(i)
	{
		FlxSprite.defaultMipFilter = i ? MIPLINEAR : MIPNONE;
		return globalMipMapsEnable = i;
	}
	public var globalLodBias(default, set):Percent = -FlxSprite.defaultLodBias;
	function set_globalLodBias(i)
	{
		globalLodBias = i;
		return FlxSprite.defaultLodBias = -i;
	}

	#if COLOR_CORRECTION_ALLOWED
	public var allowColorCorrection:Bool = false;
	public var brightness:Percent = 1.0;
	public var gamma:Percent = 1.0;
	public var contrast:Percent = 1.0;
	public var saturation:Percent = 1.0;
	#end

	public var holdCovers:Bool = true;
	public var holdCoversRelease:Bool = true;
	public var holdSparks:Bool = true;
	public var instaKillLastHoldNote:Bool = true;

	public var flashing:Bool = true;
	public var cursing:Bool = true;
	public var violence:Bool = true;
	public var camZooms:Bool = true;
	public var hideHud:Bool = false;
	public var bgOptionsShader:Bool = #if (web || mobile) false #else true #end;
	public var noteOffset:Int = 0;
	public var imagesPersist:Bool = false;
	public var ghostTapping:Bool = true;
	public var timeBarType:String = "Time Left";
	// public var healthbarStyle:String = "psych";
	public var filter:String = "None";
	public var scoreZoom:Bool = true;
	public var noReset:Bool = false;
	public var missVolume:Percent = 0.4;
	public var onWindowOutVolume:Percent = 1;
	public var shaders:Bool = true;
	public var hitsoundVolume:Percent = 0;
	public var comboStacking:Bool = true;
	#if DISCORD_RPC
	public var disc:Bool = true;
	#end
	public var transZoom:Bool = true;
	public var blockStOpt:Bool = false;
	public var sysMouse(default, set):Bool = true;
	@:access(openfl.display.Stage)
	function set_sysMouse(a)
	{
		if (FlxG.mouse != null)
		{
			FlxG.mouse.useSystemCursor = a;
			FlxG.mouse.visible = FlxG.mouse.visible;
			var stage = FlxG.game.stage;
			stage.__onMouse(openfl.events.MouseEvent.MOUSE_MOVE, stage.__pendingMouseX, stage.__pendingMouseY, 0);
		}
		return sysMouse = a;
	}
	public var displErrs:Bool = true;
	public var displErrsWindow:Bool = false;
	public var strumsNotesOverlap:Bool = false;
	public var autoPause(default, set):Bool = true;
	inline function set_autoPause(a)
		return FlxG.autoPause = #if (switch) false #else autoPause = a #end;

	public var maxValidThread(default, set):Int = 4;
	inline function set_maxValidThread(a) {
		/*
		if (game.backend.system.InfoAPI.cpuNumCores == -1) return maxValidThread = 4;
		var preMaxValidThread = Std.int(flixel.math.FlxMath.bound(a, 1, game.backend.system.InfoAPI.cpuNumCores));
		trace([preMaxValidThread, maxValidThread]);
		if (preMaxValidThread != maxValidThread){
			if (preMaxValidThread > maxValidThread){
				for(_ in 0...preMaxValidThread - maxValidThread)
					CoolUtil.gameThreads.push(Thread.createWithEventLoop(Thread.current().events.promise));
			}else{
				CoolUtil.__threadCycle -= maxValidThread - preMaxValidThread;
				for(_ in 0...maxValidThread - preMaxValidThread)
					CoolUtil.gameThreads.pop();
			}
		}
		trace(CoolUtil.gameThreads.length);
		return maxValidThread = preMaxValidThread;
		*/
		return maxValidThread = a;
	}

	public var graphicTemplate:Category = "MEDIUM";

	public var gameplaySettings:Map<String, Dynamic> = [
		"scrollspeed" => 1.0,
		"healthdrainperc" => 0.0,
		"scrolltype" => "multiplicative",
		// anyone reading this, amod is multiplicative speed mod, cmod is constant speed mod, and xmod is bpm based speed mod.
		// an amod example would be chartSpeed * multiplier
		// cmod would just be constantSpeed = chartSpeed
		// and xmod basically works by basing the speed on the bpm.
		// iirc (beatsPerSecond * (conductorToNoteDifference / 1000)) * noteSize (110 or something like that depending on it, prolly just use note.height)
		// bps is calculated by bpm / 60
		// oh yeah and you'd have to actually convert the difference to seconds which I already do, because this is based on beats and stuff. but it should work
		// just fine. but I wont implement it because I don't know how you handle sustains and other stuff like that.
		// oh yeah when you calculate the bps divide it by the songSpeed or rate because it wont scroll correctly when speeds exist.
		"songspeed" => 1.0,
		"healthgain" => 1.0,
		"healthloss" => 1.0,
		"instakill" => false,
		"practice" => false,
		"botplay" => false
	];

	public var comboOffset:Array<Int> = [0, 0, 0, 0];
	public var ratingOffset:Int = 0;
	public var sickWindow:Int = 45;
	public var goodWindow:Int = 90;
	public var badWindow:Int = 135;
	public var safeFrames:Float = 10;

	// Every key has two binds, add your key bind down here and then add your control on options/ControlsSubState.hx and Controls.hx
	public var keyBinds:Map<String, Array<FlxKey>> = [
		//Key Bind, Name for ControlsSubState
		/*
		"1K_note_down"			=> [S,			DOWN],	// LOL

		"2K_note_left"			=> [A,			LEFT],	// LOL
		"2K_note_right"			=> [D,			RIGHT],	// LOL

		"3K_note_left"			=> [A,			LEFT],	// LOL
		"3K_note_up"			=> [W,			UP],	// LOL
		"3K_note_right"			=> [D,			RIGHT],	// LOL
		*/

		"4K_note_left"			=> [A,			LEFT],
		"4K_note_down"			=> [S,			DOWN],
		"4K_note_up"			=> [W,			UP],
		"4K_note_right"			=> [D,			RIGHT],

		/*
		"5K_note_left"			=> [D,			D],
		"5K_note_down"			=> [F,			F],
		"5K_note_space"			=> [SPACE,		G],
		"5K_note_up"			=> [J,			J],
		"5K_note_right"			=> [K,			K],

		"6K_note_left"			=> [A,			A],
		"6K_note_down"			=> [S,			S],
		"6K_note_right"			=> [D,			D],
		"6K_note_extra_left"	=> [H,			H],
		"6K_note_extra_up"		=> [J,			J],
		"6K_note_extra_right"	=> [K,			K],

		"7K_note_left"			=> [A,			A],
		"7K_note_down"			=> [S,			S],
		"7K_note_right"			=> [D,			D],
		"7K_note_space"			=> [SPACE,		G],
		"7K_note_extra_left"	=> [H,			H],
		"7K_note_extra_up"		=> [J,			J],
		"7K_note_extra_right"	=> [K,			K],

		"8K_note_left"			=> [A,			A],
		"8K_note_down"			=> [S,			S],
		"8K_note_up"			=> [D,			D],
		"8K_note_right"			=> [F,			F],
		"8K_note_extra_left"	=> [H,			H],
		"8K_note_extra_down"	=> [J,			J],
		"8K_note_extra_up"		=> [K,			K],
		"8K_note_extra_right"	=> [L,			L],

		"9K_note_left"			=> [A,			A],
		"9K_note_down"			=> [S,			S],
		"9K_note_up"			=> [D,			D],
		"9K_note_right"			=> [F,			F],
		"9K_note_space"			=> [SPACE,		G],
		"9K_note_extra_left"	=> [H,			H],
		"9K_note_extra_down"	=> [J,			J],
		"9K_note_extra_up"		=> [K,			K],
		"9K_note_extra_right"	=> [L,			L],
		*/

		"ui_up"					=> [W,			UP],
		"ui_left"				=> [A,			LEFT],
		"ui_down"				=> [S,			DOWN],
		"ui_right"				=> [D,			RIGHT],

		"accept"				=> [SPACE,		ENTER],
		"back"					=> [BACKSPACE,	ESCAPE],
		"pause"					=> [ENTER,		ESCAPE],
		"reset"					=> [R],

		"volume_mute"			=> [ZERO],
		"volume_up"				=> [NUMPADPLUS, PLUS],
		"volume_down"			=> [NUMPADMINUS, MINUS],

		"fullscreen"			=> [#if web F #else F11 #end],
		"screenshot"			=> [#if web P #else F12 #end],

		"fps_log_visible"		=> [#if web L #else F3 #end],

		"debug_1"				=> [SEVEN],
		"debug_2"				=> [EIGHT],

		#if DEV_BUILD
		"debug_skipSong"		=> [ONE],
		"debug_skipTime"		=> [TWO],
		"debug_speedUp"			=> [THREE],
		"debug_freeze"			=> [FOUR],
		"debug_botplay"			=> [FIVE],
		"debug_toogleHUD"		=> [SIX],
		#end
	];

	public var gamepadBinds:Map<String, Array<FlxGamepadInputID>> = [
		"4K_note_left"			=> [LEFT_TRIGGER, X],
		"4K_note_down"			=> [LEFT_SHOULDER, A],
		"4K_note_up"			=> [RIGHT_SHOULDER, Y],
		"4K_note_right"			=> [RIGHT_TRIGGER, B],

		/*
		"5K_note_left"			=> [LEFT_TRIGGER, Y],
		"5K_note_down"			=> [LEFT_SHOULDER, X],
		"5K_note_space"			=> [DPAD_UP, DPAD_DOWN],
		"5K_note_up"			=> [RIGHT_SHOULDER, A],
		"5K_note_right"			=> [RIGHT_TRIGGER, B],
		*/

		"ui_up"					=> [DPAD_UP, LEFT_STICK_DIGITAL_UP],
		"ui_left"				=> [DPAD_LEFT, LEFT_STICK_DIGITAL_LEFT],
		"ui_down"				=> [DPAD_DOWN, LEFT_STICK_DIGITAL_DOWN],
		"ui_right"				=> [DPAD_RIGHT, LEFT_STICK_DIGITAL_RIGHT],

		"accept"				=> [A, START],
		"back"					=> [B],
		"pause"					=> [START],
		"reset"					=> [BACK]
	];

	public static var instance:ClientPrefs = new ClientPrefs();
	public static var defaultInstance:ClientPrefs = new ClientPrefs();

	// fix 0.7 psych
	public var data(get, never):ClientPrefs;
	inline function get_data() return this;
	public var defaultData(get, never):ClientPrefs;
	inline function get_defaultData() return defaultInstance;

	public var runtimeDatas:StringMap<RuntimeClientPrefsData> = new StringMap();
	public var curRuntimeData(get, set):RuntimeClientPrefsData;
	@:noCompletion function get_curRuntimeData()
	{
		var key:String = curRuntimeDataKey;
		var data:RuntimeClientPrefsData = runtimeDatas.get(key);
		if (data == null)
			runtimeDatas.set(key, data = {});
		return data;
	}
	@:noCompletion function set_curRuntimeData(i)
	{
		runtimeDatas.set(curRuntimeDataKey, i);
		return i;
	}
	public var curRuntimeDataKey(get, never):String;
	@:access(flixel.util.FlxSave)
	function get_curRuntimeDataKey()
	{
		return FlxSave.validate(ModsFolder.currentModFolderAbsolutePath);
	}

	public static var editorsSave:FlxSave;

	public function new() {}

	public static var controlsSave:FlxSave;
	public function init()
	{
		var nonSavebleVars:Array<String> = [
			"instance", "defaultInstance", "runtimeDatas", "data", "defaultData", "gamepadBinds", "keyBinds", "saveFields",
			"sickWindow",
			"goodWindow",
			"badWindow",
			"ratingOffset",
			"safeFrames",
			#if web
			"globalMipMapsEnable",
			"globalMipFilter",
			"globalLodBias",
			#end
			"cacheOnGPU",
		];


		saveFields = Type.getInstanceFields(game.backend.utils.ClientPrefs).filter(i -> !nonSavebleVars.contains(i) && !Reflect.isFunction(Reflect.field(this, i)));
		FlxG.save.bind("funkin", CoolUtil.getSavePath());
		// trace(saveFields);

		if (controlsSave == null)
		{
			controlsSave = new FlxSave();
			controlsSave.bind("controls_v3", CoolUtil.getSavePath());
		}

		if (editorsSave == null)
		{
			editorsSave = new FlxSave();
			editorsSave.bind("editors", CoolUtil.getSavePath());
		}

		loadPrefs();
		game.backend.data.StructureOptionsData.fixOptions();

		/* // todo?
		@:access(openfl.display3D.Context3D)
		inline function _setGLMultiSample(i:Bool) FlxG.stage.context3D?._setGLMultiSample(i);
		FlxG.stage.addEventListener(Event.RENDER, _ -> _setGLMultiSample(globalAntialiasingQuality == FULL));
		FlxG.stage.addEventListener(Event.ENTER_FRAME, _ -> _setGLMultiSample(false), false, 10, false);
		*/
	}

	public function clearInvalidKeys()
	{
		for (_ => keyBind in keyBinds)
			while(keyBind.remove(NONE)) { }
		for (_ => gamepadBind in gamepadBinds)
			while(gamepadBind.remove(NONE)) { }
	}

	public function field(field:String):Dynamic
	{
		final curData = curRuntimeData;
		if (curData == null) return null;
		if (Reflect.hasField(curData, field))
			return Reflect.field(curData, field);
		return Reflect.field(this, field);
	}
	public function setField(field:String, val:Dynamic)
	{
		final curData = curRuntimeData;
		if (curData == null) return;
		if (Reflect.hasField(curData, field))
		{
			Reflect.setField(curData, field, val);
		}
		else
		{
			Reflect.setField(this, field, val);
		}
	}
	public function getProperty(field:String):Dynamic
	{
		final curData = curRuntimeData;
		if (curData == null) return null;
		if (Reflect.hasField(curData, field))
			return Reflect.getProperty(curData, field);
		return Reflect.getProperty(this, field);
	}
	public function setProperty(field:String, val:Dynamic)
	{
		final curData = curRuntimeData;
		if (curData == null) return;
		if (Reflect.hasField(curData, field))
		{
			Reflect.setProperty(curData, field, val);
		}
		else
		{
			Reflect.setProperty(this, field, val);
		}
	}

	public function setRuntimeVariables(?options:Null<Map<String, Array<game.backend.data.StructureOptionsData.SaveOption>>>, ?force:Bool)
	{
		if (options != null)
		{
			for (_ => j in options)
				game.backend.data.StructureOptionsData.forEach(j, i -> {
					setRuntimeVariable(i.variableName, i.variable, i.defaultValue, force);
					game.backend.data.StructureOptionsData.filterOption(i);
				}, true);
		}
		game.backend.data.StructureOptionsData.runtimeData = options;
	}

	public function setRuntimeVariable(field:String, val:Dynamic, ?defaultVal:Dynamic, ?force:Bool)
	{
		var curData = curRuntimeData;
		var hasField = Reflect.hasField(curData, field);
		if (force || !hasField)
		{
			if (val != null)
			{
				Reflect.setField(curData, field, val);
			}
			else
			{
				Reflect.setField(curData, field, defaultVal);
			}
		}
		defaultVal ??= val;
		if (defaultVal != null)
		{
			Reflect.setField(defaultInstance.curRuntimeData, field, defaultVal);
		}
	}

	public static function showSaveStatus(titleName:String, flxSave:FlxSave, ?showDefaultStatus:Bool, ?filepos:haxe.PosInfos)
	{
		switch (flxSave.status)
		{
			case ERROR(msg):
				Log('$titleName: $msg', RED, filepos);
			case BOUND(name, path):
				if (showDefaultStatus)
					Log('$titleName: File \'$name\'' + (path == null ? "" : ' saved in \'$path\''), GREEN, filepos);
			case status:
				Log('$titleName: ${Std.string(status).toUpperCase()}', YELLOW, filepos);
		}
	}

	public function saveSettings(?showIcon:Bool = true)
	{
		// trace(FlxG.save.data);
		for (i in saveFields)
			Reflect.setField(FlxG.save.data, i, Reflect.getProperty(this, i));

		// trace(FlxG.save.data);

		FlxG.save.data.runtimeDatas ??= new StringMap();
		FlxG.save.data.runtimeDatas.set(curRuntimeDataKey, curRuntimeData);

		controlsSave.data.keyboard = keyBinds;
		controlsSave.data.gamepad = gamepadBinds;

		GlobalScript.call("onSaveSettings", [showIcon]);

		FlxG.save.flush();
		controlsSave.flush();

		showSaveStatus("Base", FlxG.save);
		showSaveStatus("Controls", controlsSave);

		FlxG.log.add("Settings saved!");
		Log("Settings saved!", GREEN);
		if (showIcon && Main.saveIcon != null)
			Main.saveIcon.show();
	}

	public function loadPrefs()
	{
		showSaveStatus("Base", FlxG.save);
		showSaveStatus("Controls", controlsSave);
		showSaveStatus("Editors", editorsSave);

		// if (FlxG.save.data.gameplaySettings != null)
		// {
		// 	final savedMap:Map<String, Dynamic> = FlxG.save.data.gameplaySettings;
		// 	for (name => value in savedMap)	gameplaySettings.set(name, value);
		// }
		for (i in saveFields)
		{
			// final value:Dynamic = Reflect.getProperty(FlxG.save.data, i);
			final value:Dynamic = Reflect.field(FlxG.save.data, i);
			// trace(i, value);
			if (value != null) Reflect.setProperty(this, i, value);
		}

		if (FlxG.save.data.runtimeDatas != null)
			runtimeDatas = FlxG.save.data.runtimeDatas.copy();

		// flixel automatically saves your volume! -okay
		if (FlxG.save.data.volume != null)	FlxG.sound.volume = FlxG.save.data.volume;
		if (FlxG.save.data.mute != null)	FlxG.sound.muted = FlxG.save.data.mute;

		// _load();

		var loadedControls:Map<String, Array<FlxKey>> = controlsSave.data.keyboard;
		if(loadedControls != null)
		{
			for (control => keys in loadedControls)
				if(keyBinds.exists(control))
					keyBinds.set(control, keys);
		}
		var loadedControls:Map<String, Array<FlxGamepadInputID>> = controlsSave.data.gamepad;
		if(loadedControls != null)
		{
			for (control => keys in loadedControls)
				if(gamepadBinds.exists(control))
					gamepadBinds.set(control, keys);
		}
		reloadVolumeKeys();
		GlobalScript.call("onLoadPrefs");
		Log("Settings loaded!", GREEN);
	}

	public function closeSettings(?save:Bool)
	{
		if (save)
			saveSettings(false);
		// FlxG.save.close();
		// controlsSave.close();
		// editorsSave.close();
		if (!FlxG.save.close())
			Log("[WARN] Failed to save base settings", RED);
		if (!controlsSave.close())
			Log("[WARN] Failed to save controls settings", RED);
		if (!editorsSave.close())
			Log("[WARN] Failed to save editors settings", RED);

		// showSaveStatus("Base", FlxG.save);
		// showSaveStatus("Controls", controlsSave);
		// showSaveStatus("Editors", editorsSave);
	}

	public inline function getGameplaySetting(name:String, defaultValue:Dynamic):Dynamic
	{
		return /*PlayState.isStoryMode ? defaultValue : */ ( gameplaySettings.get(name) ?? defaultValue);
	}

	public function resetGameplaySettings()
	{
		gameplaySettings = defaultInstance.gameplaySettings.copy();
	}

	public function reloadControls()
	{
		Main.muteKeys = copyKey(keyBinds.get("volume_mute"));
		Main.volumeDownKeys = copyKey(keyBinds.get("volume_down"));
		Main.volumeUpKeys = copyKey(keyBinds.get("volume_up"));
		FlxG.sound.muteKeys = Main.muteKeys;
		FlxG.sound.volumeDownKeys = Main.volumeDownKeys;
		FlxG.sound.volumeUpKeys = Main.volumeUpKeys;

		if (ScreenPlugin.instance != null)
		{
			ScreenPlugin.instance.fullscreenKeys = keyBinds.get("fullscreen");
			ScreenPlugin.instance.screenshotKeys = keyBinds.get("screenshot");
		}

		if (Main.fpsVar != null)
			Main.fpsVar.keysToggleVisible = keyBinds.get("fps_log_visible");
	}

	public function reloadVolumeKeys() {
		Main.muteKeys = keyBinds.get("volume_mute").copy();
		Main.volumeDownKeys = keyBinds.get("volume_down").copy();
		Main.volumeUpKeys = keyBinds.get("volume_up").copy();

		if (ScreenPlugin.instance != null)
		{
			ScreenPlugin.instance.fullscreenKeys = keyBinds.get("fullscreen");
			ScreenPlugin.instance.screenshotKeys = keyBinds.get("screenshot");
		}
		if (Main.fpsVar != null)
			Main.fpsVar.keysToggleVisible = keyBinds.get("fps_log_visible");

		toggleVolumeKeys(true);
	}
	public function toggleVolumeKeys(turnOn:Bool)
	{
		if(turnOn)
		{
			FlxG.sound.muteKeys = Main.muteKeys;
			FlxG.sound.volumeDownKeys = Main.volumeDownKeys;
			FlxG.sound.volumeUpKeys = Main.volumeUpKeys;
		}
		else
		{
			FlxG.sound.muteKeys = [];
			FlxG.sound.volumeDownKeys = [];
			FlxG.sound.volumeUpKeys = [];
		}
	}

	public function updateAntialiasing()
	{
		/*
		if (FlxG.state == null) return;
		if (FlxG.state.subState != null && FlxG.state.subState is game.states.betterOptions.OptionsSubState)
		{
			cast(FlxG.state.subState, game.states.betterOptions.OptionsSubState).options.antialiasing = globalAntialiasing;
		}
		var states = [FlxG.state];
		var curShitState = FlxG.state;
		while (curShitState.subState != null)
		{
			states.push(curShitState.subState);
			curShitState = curShitState.subState;
		}
		for (state in states)
			for (sprite in state.members)
			{
				if (sprite == null) continue;
				if(Std.isOfType(sprite, flixel.FlxSprite))
					cast(sprite, flixel.FlxSprite).antialiasing = globalAntialiasing;
			}
		*/
	}

	public function copyKey(arrayToCopy:Array<FlxKey>):Array<FlxKey>
	{
		var copiedArray:Array<FlxKey> = arrayToCopy.copy();
		while (copiedArray.remove(NONE)) { }
		return copiedArray;
	}
}
