package game.states;

import flixel.text.FlxText;

import game.backend.system.EffectsScreen;
import game.backend.system.Mods;
import game.backend.system.scripts.GlobalScript;
import game.backend.utils.Highscore;
import game.objects.improvedFlixel.addons.keyboard.*;
#if UPDATE_FEATURE
import game.objects.openfl.UpdaterPopup;
#end

#if ALLOW_HAPTICS
import extension.haptics.Haptic;
#end

class InitState extends flixel.FlxState{
	public static var initiated:Bool = false;
	@:access(flixel.FlxGame)
	override function create(){
		super.create();

		#if ALLOW_HAPTICS
		Haptic.initialize();
		#end

		#if android
		FlxG.android.preventDefaultKeys = [BACK];
		#end

		FlxG.plugins.addPlugin(FlxKeyboardEvent.globalManager = new FlxKeyboardEventManager());
		#if sys
		FlxG.plugins.addPlugin(new game.objects.ScreenPlugin());
		#end

		if (!initiated)
		{
			// GlobalScript.init();
			// GlobalScript.call("preGameStart");
			Main.loadGameSettings();
		}
		FlxG.stage.color = 0xFF000000;

		ClientPrefs.saveSettings(false);

		FlxG.bitmap.reset();
		FlxG.sound.destroy(true);

		game.backend.assets.AssetsPaths.assetsTree.reset();

		ModsFolder.updateModsList();
		ModsFolder.loadTopMod();

		Highscore.load();
		if(!EffectsScreen.checkSpecial()) EffectsScreen.updateMain();

		#if DISCORD_RPC
		DiscordClient.reloadJsonData();
		DiscordClient.start();
		#end

		#if hxvlc
		/*
		var txt = new FlxText(0, 0, "Loading...");
		txt.setFormat(null, 24, FlxColor.WHITE);
		txt.screenCenter();
		add(txt);
		*/

		trace("Init LibVLC...");
		hxvlc.util.Handle.initAsync(s -> {
			trace(s ? "LibVLC initialized successfully!" : "Error on initializing LibVLC!");
			goToNextState();
		});
		#else
		goToNextState();
		#end
	}

	function goToNextState()
	{
		if (!initiated)
		{
			// GlobalScript.init();
			// GlobalScript.call("postGameStart");
		}
		initiated = true;
		if (Main.fpsVar != null)
		{
			Main.fpsVar.visible = ClientPrefs.showFPS;
			Main.fpsVar.alpha = 1;
		}
		game.backend.system.states.MusicBeatState.switchState(new game.states.MainMenuState()); // initial game state
		#if UPDATE_FEATURE
		UpdaterPopup.init();
		#end
	}

	override function update(elapsed:Float){}
}
