package game.states.editors;

import game.backend.data.jsons.WeekData;
import game.backend.system.states.MusicBeatState;
import game.states.editors.*;
import game.objects.Alphabet;
import game.objects.FlxStaticText;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.util.FlxColor;

class MasterEditorMenu extends MusicBeatState
{
	static var options:Array<String> = [
		'Chart Editor',
		'Character Editor',
		'UI Test State',
		'Stage Editor',
		'Mods Songs'
	];
	private var grpTexts:FlxTypedGroup<Alphabet>;
	private var directories:Array<String> = [null];

	private static var curSelected = 0;
	private var curDirectory = 0;
	private var directoryTxt:FlxStaticText;
	private var modPathTxt:FlxStaticText;

	override function create()
	{
		Main.canClearMem = true;
		FlxG.camera.bgColor = FlxColor.BLACK;
		#if DISCORD_RPC
		// Updating Discord Rich Presence
		DiscordClient.changePresence("Editors Main Menu", null);
		#end

		var bg:FlxSprite = new FlxSprite(Paths.image('menuDesat'));
		// bg.setGraphicSize(FlxG.width * 1.1);
		// bg.updateHitbox();
		// if (options.length > 0)	bg.scrollFactor.set(0, Math.max(0.25 - (0.05 * (options.length - 3)), 0.1));
		// else					bg.scrollFactor.set();
		bg.color = 0xFF353535;
		bg.screenCenter();
		add(bg);

		grpTexts = new FlxTypedGroup<Alphabet>();
		add(grpTexts);

		for (i in 0...options.length)
		{
			var leText:Alphabet = new Alphabet(90, 320, options[i], true);
			leText.isMenuItem = true;
			leText.targetY = i;
			grpTexts.add(leText);
			leText.snapToPosition();
		}

		#if MODS_ALLOWED
		var textBG:FlxSprite = new FlxSprite(0, FlxG.height - 42).makeGraphic(FlxG.width, 42, 0xFF000000);
		textBG.alpha = 0.6;
		add(textBG);

		directoryTxt = new FlxStaticText(textBG.x, textBG.y + 8, FlxG.width);
		directoryTxt.setFormat(null, 20, FlxColor.WHITE, CENTER);
		add(directoryTxt);
		modPathTxt = new FlxStaticText(0, textBG.y - 14 - 2);
		modPathTxt.setFormat(null, 10, 0xffb4b4b4, LEFT);
		add(modPathTxt);

		ModsFolder.updateModsList();
		directories = directories.concat(ModsFolder.listMods);

		var found:Int = directories.indexOf(ModsFolder.currentModFolderPath);
		if(found > -1) curDirectory = found;
		changeDirectory();
		#end
		changeSelection();

		super.create();
		Paths.clearUnusedMemory();
		Paths.clearStoredMemory();
		game.objects.game.HealthIcon.clearDatas();
		FlxG.mouse.visible = false;
		persistentUpdate = true;
		Main.transition.curTransition = game.objects.transitions.VanilaTransition;
	}

	var pressedExits = false;
	override function update(elapsed:Float)
	{
		if (pressedExits)
		{
			super.update(elapsed);
			return;
		}
		if (FlxG.mouse.wheel != 0)
		{
			changeSelection(FlxG.mouse.wheel > 0 ? -1 : 1);
		}
		else
		{
			if (controls.UI_UP_P)	changeSelection(-1);
			if (controls.UI_DOWN_P)	changeSelection(1);
		}
		#if MODS_ALLOWED
		if(controls.UI_LEFT_P)
			changeDirectory(-1);
		if(controls.UI_RIGHT_P)
			changeDirectory(1);
		#end

		if (controls.BACK)
		{
			// final window = lime.app.Application.current.window;
			// final posY = window.y;
			// FlxG.autoPause = false;
			// flixel.tweens.FlxTween.num(1, 0, 0.5, {
			// 	onComplete: (_) -> {
			// 		Sys.exit(1);
			// 	}, ease: flixel.tweens.FlxEase.expoIn
			// }, (i) -> {
			// 	game.backend.utils.native.Windows.setWindowTransparencyAlpha(i);
			// 	window.y = Math.round(posY + (1 - i) * FlxG.height);
			// 	// openfl.Lib.current.alpha = i;
			// });
			// return;
			pressedExits = true;
			MusicBeatState.switchState(new MainMenuState());
		}

		if (controls.ACCEPT || FlxG.mouse.justPressed)
		{
			switch(options[curSelected])
			{
				case 'Character Editor':
					LoadingState.loadAndSwitchState(new CharacterEditorState(null, false), false);
				case 'Chart Editor':
					LoadingState.loadAndSwitchState(new ChartingState(), false);
				case 'Stage Editor':
					LoadingState.loadAndSwitchState(new StageEditorState({stage: 'stage', bf: 'bf', dad: 'dad', gf: 'gf'}), false);
				case 'Mods Songs':
					LoadingState.loadAndSwitchState(new SongsState(), false);
				case 'UI Test State':
					LoadingState.loadAndSwitchState(new TestState(), false);
			}
			if (FlxG.sound.music != null)
			{
				FlxG.sound.music.volume = 0;
				FlxG.sound.music.stop();
			}
			#if DISCORD_RPC
			DiscordClient.reloadJsonData();
			#end
			pressedExits = true;
		}

		super.update(elapsed);
	}

	function changeSelection(change:Int = 0){
		curSelected = FlxMath.wrap(curSelected + change, 0, options.length - 1);
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
		for (i => item in grpTexts.members)
		{
			item.targetY = i - curSelected;
			item.alpha = item.targetY == 0 ? 1 : 0.6;
		}
	}

	#if MODS_ALLOWED
	function changeDirectory(change:Int = 0)
	{
		curDirectory = FlxMath.wrap(curDirectory + change, 0, directories.length - 1);
		ModsFolder.switchMod(directories[curDirectory]);

		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);

		// WeekData.setDirectoryFromWeek();
		if (directories[curDirectory] == null || directories[curDirectory].length < 1)
		{
			directoryTxt.text = '< No Mod Directory Loaded >';
			modPathTxt.text = '';
		}
		else
		{
			directoryTxt.text = '< Loaded Mod Directory: ' + ModsFolder.currentModFolder + ' >';

			// modPathTxt.text = 'Path: ' + ModsFolder.currentModFolderPath.substring(0, ModsFolder.currentModFolderPath.length - ModsFolder.currentModFolder.length);
			modPathTxt.text = 'Path: ' + ModsFolder.currentModFolderPath;
		}

		modPathTxt.x = FlxG.width - modPathTxt.width - 2;
		// directoryTxt.text = directoryTxt.text.toUpperCase();
	}
	#end
}