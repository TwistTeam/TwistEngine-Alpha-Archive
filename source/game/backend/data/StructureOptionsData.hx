package game.backend.data;

import flixel.input.keyboard.FlxKey;
import flixel.util.FlxSignal.FlxTypedSignal;
import game.backend.system.EffectsScreen;
import game.backend.system.InfoAPI;
import game.backend.utils.ClientPrefs.Category;
import game.backend.utils.ClientPrefs.Percent;
import game.backend.utils.ClientPrefs.defaultInstance as ClientPrefsDefault;
import game.states.betterOptions.OptionsSubState;
import game.states.playstate.PlayState;
import openfl.display3D.Context3DMipFilter;
import openfl.display3D.Context3DTextureFilter;

class StructureOptionsData
{
	public static var cancelNextCallback:Bool = false; // fire
	public static final onChangePre:FlxTypedSignal<SaveOption -> Void> = new FlxTypedSignal();
	public static final onChangePost:FlxTypedSignal<SaveOption -> Void> = new FlxTypedSignal();

	@:noCompletion static var game(get, never):PlayState;
	@:noCompletion static inline function get_game()
		return PlayState.instance;

	@:noCompletion static var optionsMenu(get, never):OptionsSubState;
	@:noCompletion static inline function get_optionsMenu()
		return OptionsSubState.instance;

	public static var runtimeData:Map<String, Array<SaveOption>> = null;

	public static var data:Map<String, Array<SaveOption>> = [
		"VISUAL UI" => [
			{
				display: "RECEPTORS OVERLAP",
				variableName: "strumsNotesOverlap",
				description: 'Whether the note receptors should overlap the sustain notes.\nNote: When turned on, the hold covers is disabled.',
				onChange: () -> if (game != null) game.sortStrumsNotes(),
				changeInGameplay: true
			},
			{
				display: "NOTE SPLASHES",
				variableName: "noteSplashes",
				description: 'Show particles on SICK hit.',
				onChange: () -> if (game != null)
				{
					for (strumline in game.strumLines)
						strumline.updateVisibleNoteSplashes();
				},
				things: [
					{
						display: "SPLASH ALPHA",
						variableName: "splashAlpha",
						description: 'Change notesplashes alpha.',
						decimals: 2,
						scrollSpeed: 3.0,
						onChange: () -> if (game != null)
						{
							for (strumline in game.strumLines)
								strumline.noteSplashes.forEach(splash -> splash._updateAlphaSetting());
						},
						changeInGameplay: true
					},
					{
						display: "SPLASH SCALE",
						variableName: "noteSplashesScale",
						description: 'Change notesplashes scale.',
						minValue: 0.50,
						maxValue: 1.00,
						decimals: 2,
						scrollSpeed: 3.0,
						onChange: () -> if (game != null)
						{
							for (strumline in game.strumLines)
								strumline.noteSplashes.forEach(splash -> splash.baseScale = splash.baseScale);
						},
						changeInGameplay: true
					}
				],
				changeInGameplay: true
			},
			{
				display: "NOTE HOLD COVERS",
				variableName: "holdCovers",
				description: 'Displays the sustained splashes when holding down sustained notes.',
				onChange: () -> if (game != null)
				{
					for (strumline in game.strumLines)
						strumline.updateVisibleHoldCovers();
				},
				things: [
					{
						display: "RELEASE SPLASHES",
						variableName: "holdCoversRelease",
						description: 'Displays splashes when the end of a note is successfully released.',
						onChange: () -> if (game != null)
						{
							for (strumline in game.strumLines)
								strumline.holdCovers.forEachAlive(i -> i.updateVisibleReleaseSpark());
						},
						changeInGameplay: true
					},
					{
						display: "SPARKS",
						variableName: "holdSparks",
						description: 'Displays sparks when a sustained note is clamped.',
						onChange: () -> if (game != null)
						{
							for (strumline in game.strumLines)
								strumline.holdCovers.forEachAlive(i -> i.updateVisibleSparks());
						},
						changeInGameplay: true
					}
				],
				changeInGameplay: true
			},
			{
				display: "REMOVE END NOTE ON PRESS",
				variableName: "instaKillLastHoldNote",
				description: 'Removes the last part of a pressed sustained note.',
				onChange: () -> if (game != null)
				{
					for (strumline in game.strumLines)
						strumline.holdCovers.forEachAlive(i -> i.updateVisibleSparks());
				},
				changeInGameplay: true
			},
			#if COLOR_CORRECTION_ALLOWED
			{
				display: "COLOR CORRECTION",
				variableName: "allowColorCorrection",
				description: 'Toggle the camera zoom in-game.',
				onChange: () -> if (!EffectsScreen.checkSpecial())
				{
					EffectsScreen.shaders.clearArray();
					EffectsScreen.updateMain();
				},
				things: [
					{
						display: "GAMMA", // TODO: TRY SDL GAMMA
						variableName: "gamma",
						minValue: 0.10,
						maxValue: 2.00,
						decimals: 2,
						scrollSpeed: 3.0,
						onChange: () -> if (!EffectsScreen.checkSpecial())
						{
							EffectsScreen.shaders.clearArray();
							EffectsScreen.updateMain();
						},
						changeInGameplay: true
					},
					{
						display: "BRIGHTNESS", // TODO: TRY SDL BRIGHTNESS
						variableName: "brightness",
						minValue: 0.10,
						maxValue: 2.00,
						decimals: 2,
						scrollSpeed: 3.0,
						onChange: () -> if (!EffectsScreen.checkSpecial())
						{
							EffectsScreen.shaders.clearArray();
							EffectsScreen.updateMain();
						},
						changeInGameplay: true
					},
					{
						display: "CONTRAST",
						variableName: "contrast",
						minValue: 0.10,
						maxValue: 2.00,
						decimals: 2,
						scrollSpeed: 3.0,
						onChange: () -> if (!EffectsScreen.checkSpecial())
						{
							EffectsScreen.shaders.clearArray();
							EffectsScreen.updateMain();
						},
						changeInGameplay: true
					},
					{
						display: "SATURATION",
						variableName: "saturation",
						minValue: 0.10,
						maxValue: 2.00,
						decimals: 2,
						scrollSpeed: 3.0,
						onChange: () -> if (!EffectsScreen.checkSpecial())
						{
							EffectsScreen.shaders.clearArray();
							EffectsScreen.updateMain();
						},
						changeInGameplay: true
					}
				],
				changeInGameplay: true
			},
			#end
			{
				display: "COLOR BLIND",
				variableName: "filter",
				description: 'You can set colorblind filter (makes the game more playable for colorblind people).',
				arrayData: [
					{variable: "None"},
					{variable: "Deuteranopia"},
					{variable: "Protanopia"},
					{variable: "Tritanopia"},
					{variable: "Achromatopsia"},
					{variable: "Deuteranomaly"},
					{variable: "Protanomaly"},
					{variable: "Tritanomaly"},
					{variable: "Achromatomaly"}
				],
				onChange: () ->
					if (!EffectsScreen.checkSpecial())
					{
						EffectsScreen.shaders.clearArray();
						EffectsScreen.updateMain();
					},
				changeInGameplay: true
			},
			{
				display: "CAMERA ZOOMS",
				variableName: "camZooms",
				description: 'Toggle the camera zoom in-game.',
				changeInGameplay: true
			},
			{
				display: "SCORE TEXT ZOOM ON HIT",
				variableName: "scoreZoom",
				description: 'Zoom score on hit.',
				changeInGameplay: true
			},
			{
				display: "FLASHING LIGHT",
				variableName: "flashing",
				description: 'Toggle flashing lights that
							\ncan cause epileptic seizures and strain.',
				changeInGameplay: true
			},
			{
				display: "COMBO STACKING",
				variableName: "comboStacking",
				description: 'If unchecked, Ratings and Combo won\'t stack.',
				changeInGameplay: true
			},
			#if DISCORD_RPC
			{
				display: "DISCORD RICH PRESENCE",
				variableName: "disc",
				onChange: DiscordClient.check,
				description: 'Uncheck this to prevent accidental leaks, it will hide the Application from your \"Playing\" box on Discord.',
				changeInGameplay: true
			},
			#end
			{
				display: "GRAYSCALE BG OPTIONS",
				variableName: "bgOptionsShader",
				description: 'If checked, the background in the options menu will be black and white, which may cause lags.',
				changeInGameplay: true
			},
			{
				display: "USE SYSTEM CURSOR",
				variableName: "sysMouse",
				description: 'If checked, the game will show the native cursor instead of the in-game cursor.',
				changeInGameplay: true
			},
			{
				display: "AUTO PAUSE",
				variableName: "autoPause",
				description: 'If checked, the game automatically pauses if the screen isn\'t on focus.',
				onChange: () -> FlxG.autoPause = ClientPrefs.autoPause,
				changeInGameplay: true
			},
			{
				display: "ON WINDOW OUT VOLUME",
				variableName: "onWindowOutVolume",
				description: 'When focusing from the game window, the game sound will be reduced depending on the setting.\nNote: this works when \"AUTO PAUSE\" is turned off.',
				minValue: 0.0,
				maxValue: 1,
				decimals: 2,
				scrollSpeed: 3.0,
				changeInGameplay: true
			},
			{
				display: "SHOW FPS",
				variableName: "showFPS",
				description: 'Shows the game\'s frame count along
							\nwith additional information.',
				changeInGameplay: true,
				onChange: () -> if (Main.fpsVar != null) Main.fpsVar.visible = Main.fpsVar.active = ClientPrefs.showFPS,
				things: [
					{
						display: "SHOW CURRET FPS",
						variableName: "showCurretFPS",
						description: 'Removes the game\'s redundant frame count for display, like Psych Engine.',
						changeInGameplay: true
					},
					{
						display: "SHOW MEMORY",
						variableName: "showMemory",
						description: 'Displays most of the memory occupied by the game.',
						changeInGameplay: true
					},
					{
						display: "FPS ALIGH",
						variableName: "fpsAligh",
						description: 'Allows you to align the fps counter to the corners of the screen.',
						arrayData: [
							{variable: "LEFT_TOP",		display: "LEFT TOP"},
							{variable: "LEFT_BOTTOM",	display: "LEFT BOTTOM"},
							{variable: "RIGHT_TOP",		display: "RIGHT TOP"},
							{variable: "RIGHT_BOTTOM",	display: "RIGHT BOTTOM"}
						],
						changeInGameplay: true
					},
					{
						display: "FPS SCALE",
						variableName: "fpsScale",
						description: 'Allows you to control the size of the fps counter.',
						minValue: 0.6,
						maxValue: 1.25,
						decimals: 2,
						scrollSpeed: 2.0,
						changeInGameplay: true
					}
				]
			}
		],
		"GAMEPLAY" => [
			{
				display: "DOWN SCROLL",
				variableName: "downScroll",
				description: 'If checked, notes go Down instead of Up, simple enough.',
			},
			{
				display: "OPPONENT STRUMS",
				variableName: "opponentStrums",
				description: 'If unchecked, opponent notes get hidden.',
			},
			{
				display: "GHOST TAPPING",
				variableName: "ghostTapping",
				description: 'If checked, you won\'t get misses from pressing keys\nwhile there are no notes able to be hit.',
				changeInGameplay: true
			},
			{
				display: "MIDDLE SCROLL",
				variableName: "middleScroll",
				description: 'If checked, your notes get centered.',
			},
			{
				display: "NO RESET",
				variableName: "noReset",
				changeInGameplay: true,
				description: 'If checked, pressing Reset won\'t do anything.',

			},
			{
				display: "HITSOUND VOLUME",
				variableName: "hitsoundVolume",
				onChange: () -> if (!optionsMenu._generateCategories) FlxG.sound.play(Paths.sound('hitsound'), ClientPrefs.hitsoundVolume),
				changeInGameplay: true,
				description: 'Funny notes does \"Tick!\" when you hit them.',
			},
			{
				display: "MISS VOLUME",
				variableName: "missVolume",
				onChange: () -> if (!optionsMenu._generateCategories)
					FlxG.sound.play(Paths.soundRandom('missnote', 1, 3), FlxG.random.float(0.9, 1.05) * ClientPrefs.missVolume).pitch = FlxG.random.float(0.85, 1.15),
				changeInGameplay: true,
				description: 'Missed notes won\'t forgive you.',
			},
			/*
			{
				display: "RATING OFFSET",
				variableName: "ratingOffset",
				minValue: -30,
				maxValue: 30,
				typeVar: INT,
				displayFormat: "%vms",
				description: 'Changes how late/early you have to hit for a \"Sick!\"\nHigher values mean you have to hit later.',
			},
			{
				display: "SICK WINDOW",
				variableName: "sickWindow",
				minValue: -15,
				maxValue: 45,
				typeVar: INT,
				displayFormat: "%vms",
				description: 'Changes the amount of time you have\nfor hitting a \"Sick!\" in milliseconds.',
			},
			{
				display: "GOOD WINDOW",
				variableName: "goodWindow",
				minValue: -15,
				maxValue: 90,
				typeVar: INT,
				displayFormat: "%vms",
				description: 'Changes the amount of time you have\nfor hitting a \"Good\" in milliseconds.',
			},
			{
				display: "BAD WINDOW",
				variableName: "badWindow",
				minValue: -15,
				maxValue: 135,
				typeVar: INT,
				displayFormat: "%vms",
				description: 'Changes the amount of time you have\nfor hitting a \"Bad\" in milliseconds.',
			},
			{
				display: "SAFE FRAMES",
				variableName: "safeFrames",
				minValue: 2,
				maxValue: 10,
				decimals: 2,
				displayFormat: "%vms",
				description: 'Changes how many frames you have for\nhitting a note earlier or late.',
			}
			*/
		],
		#if DEV_BUILD
		"DEV" => [
			/*
			{
				display: "USE TXT CASHE",
				variableName: "useTxtCashe",
				changeInGameplay: true
			},
			*/
			{
				display: "SHOW DEBUG INFO",
				variableName: "showDebugInfo",
				description: 'Shows in the fps counter the stats of Flixel, OpenFL, FlxAnimate, used HaxeLibs and other crap.',
				changeInGameplay: true
			},
			{
				display: "SHOW SYSTEM INFO",
				variableName: "showSystemInfo",
				description: 'Displays the architecture of the user\'s computer and a little information about the renderer.',
				changeInGameplay: true
			},
			{
				display: "DISPLAY ERRORS",
				variableName: "displErrs",
				changeInGameplay: true,
				things:[
					{
						display: "USE ALERT WINDOW",
						variableName: "displErrsWindow",
						changeInGameplay: true
					}
				]
			},
		],
		#end
		"GRAPHICS" => [
			{
				display: "LOW QUALITY",
				variableName: "lowQuality",
				description: 'If checked, visual effects and objects that may affect the computer\'s workload are disabled.',
				// changeInGameplay: true,
			},
			{
				display: "GLOBAL ANTIALIASING",
				variableName: "globalAntialiasing",
				// onChange: () -> if (game == null) ClientPrefs.updateAntialiasing(),
				changeInGameplay: true,
				description: 'If unchecked, disables anti-aliasing, increases performance\nat the cost of sharper visuals.',
			},
			/*
			{
				display: "GLOBAL ANTIALIASING",
				variableName: "globalTextureFilter",
				changeInGameplay: true,
				arrayData: [
					{variable: "nearest",			display: "NEAREST"			},
					{variable: "linear",			display: "LINEAR"			},
					{variable: "anisotropic2x",		display: "ANISOTROPIC2X"	},
					{variable: "anisotropic4x",		display: "ANISOTROPIC4X"	},
					{variable: "anisotropic8x",		display: "ANISOTROPIC8X"	},
					{variable: "anisotropic16x",	display: "ANISOTROPIC16X"	},
				],
				description: '',
			},
			*/
			#if !web // TODO: SUPPORT WEB GL
			{
				display: "GLOBAL MIPMAP",
				variableName: "globalMipMapsEnable",
				changeInGameplay: true,
				description: 'Dynamically adjusts texture quality depending on window resolution and camera zoom.',
				things:[
					{
						display: "GLOBAL LOD BIAS",
						variableName: "globalLodBias",
						minValue: -1.0,
						maxValue: 1.0,
						decimals: 2,
						changeInGameplay: true,
						description: 'Offset for mipmap.\nUseful for adjusting the sharpness of distant objects.\n(It doesn\'t affect the computer\'s load.)',
					}
				],
			},
			#end
			{
				display: "SHADERS",
				variableName: "shaders",
				description: 'If unchecked, disables shaders.\nIt\'s used for some visual effects, and also CPU intensive for weaker PCs.',
			},
			/*
			{
				display: "GPU CASHING",
				variableName: "cacheOnGPU",
				changeInGameplay: true,
				description: 'If checked, allows the GPU to be used for caching textures, decreasing RAM usage.\nDon\'t turn this on if you have a shitty Graphics Card.',
			},
			*/
			/*
			#if MULTI_THREADING_ALLOWED
			{
				display: "MULTI THREADING",
				variableName: "multiThreading",
				changeInGameplay: true
			},
			{
				variableName: "maxValidThread",
				minValue: 1,
				maxValue: InfoAPI.cpuNumCores,
			},
			#end
			*/
			{
				display: "FRAMERATE",
				variableName: "framerate",
				minValue: 60,
				// maxValue: 290,
				maxValue: 360,
				typeVar: INT,
				decimals: 4,
				scrollSpeed: 2.0,
				displayFormat: "%v FPS",
				changeInGameplay: true,
				description: 'Pretty self explanatory, isn\'t it?',
			},
			// #if TEST_VERSION
			// {
			// 	display: "VSYNC",
			// 	variableName: "vsyncDraw",
			// 	onChange: () -> ClientPrefs.framerate = ClientPrefs.framerate,
			// 	changeInGameplay: true,
			// 	description: 'If checked, the game is drawn at the current screen frequency, but retains the frequency from the “FRAMERATE” option to update the game logic.',
			// }
			// #end
		],
		"CONTROLS" => [
			{
				display: "NOTES",
				variableName: null,
				changeInGameplay: true,
				things: [
					{
						display: "NOTE LEFT",
						variableName: "4K_note_left",
						changeInGameplay: true
					},
					{
						display: "NOTE DOWN",
						variableName: "4K_note_down",
						changeInGameplay: true
					},
					{
						display: "NOTE UP",
						variableName: "4K_note_up",
						changeInGameplay: true
					},
					{
						display: "NOTE RIGHT",
						variableName: "4K_note_right",
						changeInGameplay: true
					},
				]
			},
			{
				display: "UI",
				variableName: null,
				changeInGameplay: true,
				things: [
					{
						display: "UI LEFT",
						variableName: "ui_left",
						changeInGameplay: true
					},
					{
						display: "UI DOWN",
						variableName: "ui_down",
						changeInGameplay: true
					},
					{
						display: "UI UP",
						variableName: "ui_up",
						changeInGameplay: true
					},
					{
						display: "UI RIGHT",
						variableName: "ui_right",
						changeInGameplay: true
					},
				]
			},
			{
				display: "RESET",
				variableName: "reset",
				changeInGameplay: true
			},
			{
				display: "ACCEPT",
				variableName: "accept",
				changeInGameplay: true
			},
			{
				display: "BACK",
				variableName: "back",
				changeInGameplay: true
			},
			{
				display: "PAUSE",
				variableName: "pause",
				changeInGameplay: true
			},
			{
				display: "VOLUME",
				variableName: null,
				changeInGameplay: true,
				things: [
					{
						display: "MUTE",
						variableName: "volume_mute",
						onChange: ClientPrefs.reloadControls,
						changeInGameplay: true
					},
					{
						display: "VOLUME UP",
						variableName: "volume_up",
						onChange: ClientPrefs.reloadControls,
						changeInGameplay: true
					},
					{
						display: "VOLUME DOWN",
						variableName: "volume_down",
						onChange: ClientPrefs.reloadControls,
						changeInGameplay: true
					},
				]
			},
			{
				display: "FULLSCREEN",
				variableName: "fullscreen",
				onChange: ClientPrefs.reloadControls,
				changeInGameplay: true,
			},
			{
				display: "SCREENSHOT",
				variableName: "screenshot",
				onChange: ClientPrefs.reloadControls,
				changeInGameplay: true,
			},
			{
				display: "FPS LOG CHANGE",
				variableName: "fps_log_visible",
				onChange: ClientPrefs.reloadControls,
				changeInGameplay: true,
			},
			#if DEV_BUILD
			{
				display: "DEBUG",
				variableName: null,
				changeInGameplay: true,
				things: [
					{
						display: "SKIP SONG",
						variableName: "debug_skipSong",
						changeInGameplay: true
					},
					{
						display: "SKIP TIME",
						variableName: "debug_skipTime",
						changeInGameplay: true
					},
					{
						display: "SPEED UP",
						variableName: "debug_speedUp",
						changeInGameplay: true
					},
					{
						display: "FREEZE",
						variableName: "debug_freeze",
						changeInGameplay: true
					},
					{
						display: "BOTPLAY",
						variableName: "debug_botplay",
						changeInGameplay: true
					},
					{
						display: "CAMHUD TOOGLE",
						variableName: "debug_toogleHUD",
						changeInGameplay: true
					},
				]
			},
			#end
		]
	];

	public static function forEach(data:Array<SaveOption>, func:SaveOption -> Void, recurse = true)
	{
		for (i in data)
		{
			if (recurse && i.things != null)
				forEach(i.things, func, recurse);
			func(i);
		}
	}
	public static function filterMapOfOptions(data:Map<String, Array<SaveOption>>)
	{
		for (_ => j in data)
			forEach(j, filterOption, true);
		/*
		function findCateg(optionData:SaveOption)
		{
			if (optionData.things != null)
				for (i in optionData.things)
					findCateg(i);
			filterOption(optionData);
			return optionData;
		}

		for (_ => dat in data)
			for (optionData in dat)
				findCateg(optionData);
		*/
		return data;
	}

	public static function filterOption(optionData:SaveOption)
	{
		final varName = optionData.variableName;
		optionData.variable = ClientPrefs.getProperty(varName);
		optionData.isRuntime = ClientPrefs.curRuntimeData != null && Reflect.hasField(ClientPrefs.curRuntimeData, varName);

		optionData.defaultValue ??= ClientPrefsDefault.getProperty(varName);

		optionData.minValue ??= 0;
		optionData.maxValue ??= 1;
		optionData.scrollSpeed ??= 1.;
		optionData.decimals ??= 1;
		optionData.diffInt ??= 1;

		if (optionData.description != null)
			optionData.description = optionData.description.replace("	", "");

		if (optionData.onChange == null)
		{
			optionData.onChange = () -> {
				onChangePre.dispatch(optionData);
				onChangePost.dispatch(optionData);
			}
		}
		else
		{
			var thatChange = optionData.onChange;
			optionData.onChange = () -> {
				onChangePre.dispatch(optionData);
				if (!cancelNextCallback)
					thatChange();
				cancelNextCallback = false;
				onChangePost.dispatch(optionData);
			}
		}

		optionData.onOut ??= () -> {};
		optionData.onEmergence ??= () -> {};
		if (optionData.arrayData == null)
			optionData.arrayData = [];
		else
			for (i in optionData.arrayData)
			{
				i.thing ??= () -> {};
				i.visibleChilds ??= true;
			}

		if (optionData.typeVar == null)
		{
			if (ClientPrefs.keyBinds.exists(varName))
			{
				optionData.typeVar = INPUT;
				optionData.variable = ClientPrefs.keyBinds.get(varName);
			}
			else if (optionData.variable != null)
			{
				if (optionData.variable is Percent)
					optionData.typeVar = PERCENT;
				else if (optionData.variable is Float)
				{
					optionData.typeVar = Type.typeof(optionData.variable).match(TInt) ? INT : FLOAT;
				}
				else if (optionData.variable is Bool)
					optionData.typeVar = BOOL;
				else if (optionData.variable is String)
					optionData.typeVar = STR;
				else if (optionData.variable is Category)
					optionData.typeVar = CATEGORY;
				else
					optionData.typeVar = DYNAMIC;
			}
			else
			{
				optionData.typeVar = NONE;
			}
		}
		optionData.displayFormat ??= (optionData.typeVar == PERCENT ? "%v %" : "%v"); // смешнявка
		return optionData;
	}

	// TODO: put in macros
	public static function fixOptions()
	{
		/*
		CoolUtil.execAsync(() ->
		{
			filterMapOfOptions(data);

			trace("Filtering options is complete.");
		});
		*/
		filterMapOfOptions(data);
	}
}

enum OptionType{
	NONE;
	FLOAT;
	STR;
	CATEGORY;
	INT;
	PERCENT;
	BOOL;
	INPUT;
	DYNAMIC;
}

typedef CategoryFunction = {
	var variable:Dynamic;
	@:optional var visibleChilds:Bool;
	@:optional var display:String;
	@:optional var thing:Void->Void;
}

typedef SaveOption = {
	var variableName:String;
	@:optional var display:String;
	@:optional var description:String;
	// @:optional var group:SaveGroupOptionsInput;
	@:optional var variable:Dynamic;
	@:optional var defaultValue:Dynamic;
	@:optional var displayFormat:String;
	@:optional var arrayData:Array<CategoryFunction>;
	@:optional var scrollSpeed:Null<Float>; // Only works if int/float and use keybord. Defines how fast it scrolls per second while holding left/right
	@:optional var previews:Array<String>; // TODO
	@:optional var checkVisible:Void->Bool; // thinking about different visibility for variations of notes 4-9, but idk
	@:optional var onChange:Void->Void;
	@:optional var onEmergence:Void->Void;
	@:optional var onOut:Void->Void;
	@:optional var things:Array<SaveOption>;
	@:optional var diffInt:Null<Int>; //Only used in int type
	@:optional var decimals:Null<Int>; //Only used in float/percent type
	@:optional var minValue:Dynamic; // Only used in int/float/percent type
	@:optional var maxValue:Dynamic; // Only used in int/float/percent type
	@:optional var typeVar:OptionType; // can find auto
	@:optional var changeInGameplay:Bool;
	@:optional var isRuntime:Bool;
	@:optional var beforeOption:String; // Used for runtime
	@:optional var afterOption:String; // Used for runtime
}