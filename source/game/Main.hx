package game;

#if extension-androidtools
import extension.androidtools.content.Context;
import extension.androidtools.os.Build;
#end

import flixel.FlxG;
import flixel.input.keyboard.FlxKey;
import flixel.util.FlxPool;
import flixel.util.FlxSignal;

import game.Config;
import game.backend.CrashHandler;
import game.backend.assets.*;
import game.backend.system.macros.AssetsMacro;
import game.backend.system.scripts.GlobalScript;
import game.backend.utils.AudioSwitchFix;
import game.backend.utils.Controls;
import game.backend.utils.MemoryUtil;
import game.backend.utils.PathUtil;
import game.backend.utils.WindowUtil;
import game.backend.utils.native.Windows;
import game.objects.SaveIcon;
import game.objects.openfl.FlxGlobalTimer;
import game.objects.openfl.FlxGlobalTween;
import game.objects.transitions.TransitionsGroup;

import haxe.io.Path;

import lime.app.Application;
import lime.utils.Assets as LimeAssets;
import lime.utils.AssetType;

import openfl.Lib;
import openfl.display.DisplayObject;
import openfl.display.MovieClip;
import openfl.display.Sprite;
import openfl.display.StageScaleMode;
import openfl.errors.Error;
import openfl.events.UncaughtErrorEvent;
import openfl.utils.*;

#if (cpp && windows)
@:cppFileCode('
#include <windows.h>
#include <winuser.h>
')
#end
class Main extends flixel.FlxGame
{
	public static function main():Void
	{
		// Credits to MAJigsaw77 (he's the og author for this code)
		#if extension-androidtools
		Sys.setCwd(Path.addTrailingSlash(VERSION.SDK_INT > 30 ? Context.getObbDir() : Context.getExternalFilesDir()));
		#elseif ios
		Sys.setCwd(System.documentsDirectory);
		#end
		LogsGame.init();

		initAccess();

		#if !macro
		flxanimate.Utils.getFolderContent = function(folder:String, ?folders:Null<Bool>, ?addPath:Bool):Array<String>
		{
			if (!folder.endsWith("/"))
				folder += "/";
			var content:Array<String> = folders == null ?
				[for (j in [AssetsPaths.assetsTree.getFolders(folder, false, BOTH), AssetsPaths.assetsTree.getFiles(folder, false, BOTH)]) for (i in j) i]
			:
				(folders ? AssetsPaths.assetsTree.getFolders : AssetsPaths.assetsTree.getFiles)(folder, false, BOTH);
			if (addPath)
			{
				for (k => e in content)
					content[k] = '$folder$e';
			}
			return content;
		}
		#end

		FlxSprite.defaultAntialiasing = true;

		#if desktop
		var configPath:String = Path.directory(Path.withoutExtension(Sys.programPath()));

		#if windows
		configPath += "/plugins/alsoft.ini";
		#elseif mac
		configPath = Path.directory(configPath) + "/Resources/plugins/alsoft.conf";
		#elseif linux
		configPath += "/plugins/alsoft.conf";
		#end

		Sys.putEnv("ALSOFT_CONF", configPath);
		#end

		#if COLOR_CORRECTION_ALLOWED
		game.backend.system.EffectsScreen.colorCorrectionShader ??= new game.shaders.ColorCorrectionShader();
		#end
		new Main();
	}

	public static var muteKeys:Array<FlxKey> = [FlxKey.ZERO];
	public static var volumeDownKeys:Array<FlxKey> = [FlxKey.NUMPADMINUS, FlxKey.MINUS];
	public static var volumeUpKeys:Array<FlxKey> = [FlxKey.NUMPADPLUS, FlxKey.PLUS];

	public static var mainInstance(default, null):Main;
	public static var applicationScreen(get, never):MovieClip;

	@:noCompletion static inline function get_applicationScreen()
		return Lib.current;

	public static var fpsVar:FPS;
	public static var stateName:String = 'NONE';
	public static var saveIcon:SaveIcon;
	public static var transition:TransitionsGroup;

	public static var canClearMem:Bool = true;

	@:access(game.backend.assets.AssetsLibraryList)
	@:access(openfl.utils.Assets)
	@:access(lime.utils.Assets)
	public static function initAccess()
	{
		// for (i in LimeAssets.libraries.keys())
		// 	trace(i);
		// trace(LimeAssets.libraries.keys());
		AssetsPaths.assetsTree = new AssetsLibraryList();
		AssetsPaths.init();
		// LimeAssets.libraries.remove("default");

		if (LimeAssets.libraries.exists("assets") && !AssetsPaths.assetsTree.__defaultLibraries.contains(Assets.getLibrary("assets")))
		{
			AssetsPaths.assetsTree.__defaultLibraries.push(Assets.getLibrary("assets"));
			LimeAssets.libraries.remove("assets");
		}

		AssetsPaths.assetsTree.__defaultLibraries.push(Assets.getLibrary("embed"));
		LimeAssets.libraries.remove("embed");

		#if (EMBED_FILES && ZIPLIBS_ALLOWED)
		var _i:Int = 0;

		for (path in AssetsMacro.getSecretZipFilesMacro())
		{
			// trace(path);
			try
			{
				AssetsPaths.assetsTree.__defaultLibraries.push(ModsFolder.loadLibraryFromZip('hxzjbcjhxzbc' + _i++, "./" + path, true));
			}
			catch(e)
			{
				Sys.exit(1);
			}
		}
		// AssetsPaths.assetsTree.__defaultLibraries.push(ModsFolder.prepareModLibrary("EmbedScripts", new game.backend.assets.EmbedFilesLibrary()));
		#end

		#if USE_SYS_ASSETS
		#if RELEASE_BUILD
		var libName = "assets";
		var lib = new AssetsLibraryByPaths("./assets/", haxe.Resource.getBytes("TWAssets_Paths").toString().split(","), libName);
		// for (i in assets.assets)
		// 	trace(i.path);
		// trace(assets.assets.length);
		AssetsPaths.assetsTree.__defaultLibraries.push(ModsFolder.prepareModLibrary(libName, lib, true));
		#else
		AssetsPaths.assetsTree.__defaultLibraries.push(ModsFolder.loadLibraryFromFolder('assets', "./assets/", true));
		#end
		#end

		/*
		#if MODS_ALLOWED
		ModsFolder.init();
		ModsFolder.modsPath = './mods';
		// ModsFolder.addonsPath = './addons';
		#end
		*/

		AssetsPaths.assetsTree.libraries = AssetsPaths.assetsTree.__defaultLibraries.copy();

		var lib = new AssetLibrary();
		@:privateAccess
		lib.__proxy = AssetsPaths.assetsTree;
		// Assets.registerLibrary("default", lib);
		LimeAssets.libraries.set("default", lib);
		Assets.cache.enabled = true; // lol
		// for (i in LimeAssets.libraries.keys())
		// 	trace(i);
		// trace(AssetsPaths.assetsTree.__defaultLibraries);
	}

	public var curTime:Int;

	@:noCompletion var __lastFocusGlobalVolume:Null<Float>;

	@:access(flixel.FlxG.bitmap)
	@:access(flixel.FlxG.cameras)
	@:access(flixel.system.frontEnds.CameraFrontEnd)
	public function new()
	{
		mainInstance = this;
		#if (cpp && windows)
		untyped __cpp__("
				SetProcessDPIAware(); // allows for more crisp visuals
				DisableProcessWindowsGhosting() // lets you move the window and such if it's not responding
			");
		WindowUtil.setDarkMode(true);
		#end
		getTimer = () -> curTime = inline openfl.Lib.getTimer();

		// bound local save so flixels default save won't initialize
		FlxG.save.bind("funkin", CoolUtil.getSavePath());

		// __lastFocusGlobalVolume = FlxG.sound.volume;
		FlxG.signals.focusLost.add(onFocusOut);
		FlxG.signals.focusGained.add(onFocusIn);

		Application.current.onExit.add(onCloseApplication);

		// destroy original frontend
		FlxG.cameras.list = null;
		FlxG.cameras.defaults = null;
		FlxG.cameras._cameraRect = null;
		FlxG.cameras.cameraAdded.destroy();
		FlxG.cameras.cameraRemoved.destroy();
		FlxG.cameras.cameraResized.destroy();
		FlxG.cameras.cameraAdded = null;
		FlxG.cameras.cameraRemoved = null;
		FlxG.cameras.cameraResized = null;

		// add custom
		FlxG.cameras = new game.objects.improvedFlixel.CameraFrontEnd();

		// #if LUA_ALLOWED llua.Lua.set_callbacks_function(cpp.Callable.fromStaticFunction(game.backend.system.scripts.FunkinLua.CallbackHandler.call)); #end
		super(Config.gameSizes[0], Config.gameSizes[1], game.states.InitState,
			ClientPrefs.framerate, ClientPrefs.framerate, Config.skipSplash, Config.startFullscreen);

		var tweenManager = new flixel.tweens.FlxTween.FlxTweenManager();
		FlxGlobalTween.globalManager = tweenManager;
		FlxG.signals.preStateSwitch.remove(tweenManager.clear);
		// @:privateAccess
		// FlxG.signals.postUpdate.add(() -> tweenManager.update(_elapsedMS / 1000));
		@:privateAccess
		onPostEnterFrame.add(() -> tweenManager.update(_elapsedMS / 1000));

		FlxGlobalTimer.globalManager = new FlxGlobalTimerManager();

		GlobalScript.init();
		applicationScreen.stage.addChild(this);

		applicationScreen.stage.addChild(fpsVar = new FPS(10, 3));
		fpsVar.alpha = 0;
		fpsVar.changeFont("VCR OSD Mono Cyr.ttf");
		// applicationScreen.stage.align = "tl";
		applicationScreen.stage.scaleMode = StageScaleMode.NO_SCALE;

		applicationScreen.stage.addChild(saveIcon = new SaveIcon());

		#if html5
		FlxG.autoPause = false;
		FlxG.mouse.visible = false;
		#end
		// lime.utils.Log.throwErrors = false;
		applicationScreen.loaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, CrashHandler.onUncaughtCrash);
		#if cpp
		untyped __global__.__hxcpp_set_critical_error_handler(onError);
		#elseif hl
		hl.Api.setErrorHandler(onError);
		#end
		AudioSwitchFix.init();

		#if linux
		applicationScreen.stage.window.setIcon(lime.graphics.Image.fromFile("./icon.png"));
		#end
	}
	function onFocusOut()
	{
		trace('Window Focus Out');
		__lastFocusGlobalVolume = FlxG.sound.volume;
		FlxG.sound.volume *= ClientPrefs.onWindowOutVolume;
	}
	function onFocusIn()
	{
		trace('Window Focus In');
		if (__lastFocusGlobalVolume != null)
			FlxG.sound.volume = __lastFocusGlobalVolume;
	}

	override function create(_)
	{
		if (stage == null)
			return;
		super.create(_);
		var index:Int = soundTray == null || !Std.isOfType(soundTray, DisplayObject) ? numChildren : getChildIndex(cast soundTray);
		addChildAt(transition = new TransitionsGroup(), index);
	}

	public static function realoadDefaultFont(?fontName:String)
	{
		flixel.system.FlxAssets.FONT_DEFAULT = Assets.getFont(
				AssetsPaths.font('engine/${fontName ?? "Minecraft Rus.ttf"}') // РАССИЯ!!!
			)?.fontName ?? flixel.system.FlxAssets.FONT_DEFAULT;
	}

	public static function loadGameSettings()
	{
		WindowUtil.resetTitle();
		realoadDefaultFont();

		FlxG.fixedTimestep = false;

		game.backend.system.InfoAPI.init();

		FlxG.signals.postStateSwitch.add(() ->
		{
			// manual asset clearing since base openfl one doesnt clear lime one
			// doesnt clear bitmaps since flixel fork does it auto

			@:privateAccess {
				// clear uint8 pools
				for (pool in openfl.display3D.utils.UInt8Buff._pools)
				{
					for (b in pool.clear())
						b.destroy();
				}
				openfl.display3D.utils.UInt8Buff._pools.clear();
			}
			// if (canClearMem)
			// {
			// 	Paths.clearStoredMemory();
			// }
			// clearCache();
			// clearUnusedPools();
			MemoryUtil.clearMajor();
		});

		// FlxG.signals.preStateSwitch.add(Main.preClear);
		// FlxG.signals.postStateSwitch.add(Main.postClear);

		game.backend.ShaderResizeFix.init();
		// game.backend.utils.GamepadUtil.init();
		ClientPrefs.init();
		CoolUtil.init();
		game.backend.utils.ShadersData.init();
		Controls.instance = new Controls();
		fpsVar?.changeFont("VCR OSD Mono Cyr.ttf");
		#if CPP_WINDOWS
		if(WindowUtil.hasVersion("Windows 10")) WindowUtil.redrawWindowHeader();
		#end
	}

	#if (cpp || hl)
	private inline static function onError(message:Dynamic):Void
		throw '\n\rCritical Error!\n\r${Std.string(message)}\n';
	#end

	@:dox(hide) public static var audioDisconnected:Bool = false;
	public static var changeID:Int = 0;

	/*
	@:access(openfl.display3D.utils.UInt8Buff)
	public inline static function preClear(){ // before switch in last state
		if (canClearMem){
			Paths.clearStoredMemory();
			// clear uint8 pools
			for(pool in openfl.display3D.utils.UInt8Buff._pools) {
				for(b in pool.clear())
					b.destroy();
			}
			openfl.display3D.utils.UInt8Buff._pools.clear();
			clearCache();
		}
		clearUnusedPools();
	}
	public inline static function postClear(){ // after switch
		if (canClearMem){
			// Paths.clearUnusedMemory();
			clearCache();
		}
		clearUnusedPools();
	*/

	public static function clearUnusedPools() @:privateAccess {
		var pool:Dynamic = flixel.math.FlxPoint.FlxBasePoint.pool;
		pool._pool.splice(pool._count, pool._pool.length);
		pool = flixel.math.FlxRect._pool;
		pool._pool.splice(pool._count, pool._pool.length);
	}

	@:access(flixel.system.frontEnds.SoundFrontEnd)
	public static function clearCache()
	{
		var index:Int = 0;
		var length:Int = FlxG.sound.list.length;
		// clear non local assets in the tracked assets list
		var i:flixel.sound.FlxSound;
		while (length > index)
		{
			i = FlxG.sound.list.members[index];
			if (i == null)
			{
				FlxG.sound.list.remove(i);
				length--;
				continue;
			}
			if (!i.isValid() || !i.exists || !i.active)
			{
				FlxG.sound.destroySound(i);
				FlxG.sound.list.remove(i);
				length--;
				continue;
			}
			// trace([i.toString(), i.exists, i.active]);
			index++;
		}
	}

	public static function onCloseApplication(code:Int)
	{
		#if hxvlc
		hxvlc.util.Handle.dispose();
		#end
		#if DISCORD_RPC
		DiscordClient.shutdown();
		#end
		ClientPrefs.closeSettings(true);
		try AssetsPaths.assetsTree.disposeAllLibraries();
		// if (!FlxG.save.close())
		// 	Log("[WARN] Failed to save", RED);
		trace('Game\'s Closed');
	}

	public static var inSwitchStatus:Bool = true;

	var skipNextTickUpdate:Bool = false;

	public var onFinalDraw(default, null):FlxSignal = new FlxSignal();

	override function _draw()
	{
		FlxG.signals.preDraw.dispatch();

		if (FlxG.renderTile)
			flixel.graphics.tile.FlxDrawBaseItem.drawCalls = 0;

		#if FLX_POST_PROCESS
		if (postProcesses[0] != null)
			postProcesses[0].capture();
		#end

		FlxG.cameras.lock();

		FlxG.plugins.draw();

		_state.draw();

		onFinalDraw.dispatch();
		if (FlxG.renderTile)
		{
			FlxG.cameras.render();

			#if FLX_DEBUG
			debugger.stats.drawCalls(flixel.graphics.tile.FlxDrawBaseItem.drawCalls);
			#end
		}

		FlxG.cameras.unlock();

		FlxG.signals.postDraw.dispatch();

		#if FLX_DEBUG
		debugger.stats.flixelDraw(getTicks() - ticks);
		#end
	}

	public var onPreEnterFrame(default, null):FlxSignal = new FlxSignal();
	public var onPostEnterFrame(default, null):FlxSignal = new FlxSignal();

	public override function switchState()
	{
		inSwitchStatus = true;
		// Basic reset stuff
		FlxG.cameras.reset();
		FlxG.inputs.onStateSwitch();
		#if FLX_SOUND_SYSTEM
		FlxG.sound.destroy();
		#end

		FlxG.signals.preStateSwitch.dispatch();

		#if FLX_RECORD
		FlxRandom.updateStateSeed();
		#end

		// Destroy the old state (if there is an old state)
		_state?.destroy();

		// we need to clear bitmap cache only after previous state is destroyed, which will reset useCount for FlxGraphic objects
		FlxG.bitmap.clearCache();

		// Finally assign and create the new state
		_state = _nextState.createInstance();
		_state._constructor = _nextState;
		_nextState = null;

		if (_gameJustStarted)
			FlxG.signals.preGameStart.dispatch();

		FlxG.signals.preStateCreate.dispatch(_state);

		_state.create();

		if (_gameJustStarted)
			gameStart();

		#if FLX_DEBUG
		debugger.console.registerObject("state", _state);
		#end

		FlxG.signals.postStateSwitch.dispatch();

		// draw once to put all images in gpu then put the last update time to now to prevent lag spikes or whatever
		draw();
		_total = ticks = getTicks();
		skipNextTickUpdate = true;
		inSwitchStatus = false;
	}

	public override function onEnterFrame(t)
	{
		onPreEnterFrame.dispatch();
		if (skipNextTickUpdate != (skipNextTickUpdate = false))
			_total = ticks = getTicks();
		super.onEnterFrame(t);
		onPostEnterFrame.dispatch();
	}

	// #if !debug
	@:noCompletion
	override function __hitTest(x:Float, y:Float, shapeFlag:Bool, stack:Array<DisplayObject>, interactiveOnly:Bool, hitObject:DisplayObject) return false;
	@:noCompletion
	override function __hitTestHitArea(x:Float, y:Float, shapeFlag:Bool, stack:Array<DisplayObject>, interactiveOnly:Bool, hitObject:DisplayObject) return false;
	@:noCompletion
	override function __hitTestMask(x:Float, y:Float) return false;
	// #end
}
