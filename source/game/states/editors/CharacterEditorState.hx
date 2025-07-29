package game.states.editors;

import game.states.substates.Secret;
import game.backend.system.states.MusicBeatState;
import game.backend.utils.WindowUtil;
import game.objects.game.BGSprite;
import game.objects.game.Character;
import game.objects.game.HealthIcon;
import game.objects.ui.ColorPickerGroup;
import game.objects.Bar;
import game.objects.FlxUIDropDownMenuCustom;
import game.objects.FlxStaticText;
import game.states.editors.MasterEditorMenu;

import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxSpriteGroup;
import flixel.graphics.FlxGraphic;
import flixel.text.FlxText; // import inside objects
import flixel.animation.FlxAnimation;
import flixel.addons.ui.FlxUI;
import flixel.addons.ui.FlxUICheckBox;
import flixel.addons.ui.FlxUIInputText;
import flixel.addons.ui.FlxUINumericStepper;
import flixel.addons.ui.FlxUITabMenu;
import flixel.system.debug.interaction.tools.Pointer.GraphicCursorCross;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.input.mouse.FlxMouseEventManager;
import flixel.ui.FlxButton;
import flixel.util.FlxColor;

import openfl.net.FileReference;
import openfl.events.Event;
import openfl.events.IOErrorEvent;

import haxe.Json;
import haxe.io.Path;

// import tjson.TJSON as Json;
import lime.system.Clipboard;

@:access(game.objects.game.Character)
class CharacterEditorState extends MusicBeatUIState
{
	var char:Character;
	var ghostChar:Character;
	var textAnim:FlxStaticText;
	var bgLayer:FlxTypedGroup<FlxSprite>;
	var charLayer:FlxTypedGroup<Character>;
	var dumbTexts:FlxTypedGroup<FlxStaticText>;
	// var animList:Array<String> = [];
	var curAnim:Int = 0;
	var curCharacter:String = 'bf.json';
	var goToPlayState:Bool = true;

	public function new(?curCharacter:String, ?goToPlayState:Bool)
	{
		super(false);
		if (curCharacter != null)
			this.curCharacter = curCharacter + '.json';
		this.goToPlayState = goToPlayState;
	}

	var UI_box:FlxUITabMenu;
	var UI_characterbox:FlxUITabMenu;

	var camEditor:FlxCamera;
	var camHUD:FlxCamera;

	var leHealthIcon:HealthIcon;
	var characterList:Array<String> = [];

	var cameraFollowPointer:FlxSprite;
	var healthBar:Bar;
	var healthPercent:Float = 0.5;

	var overlapedBar:Bool = false;
	var listOfInput:Array<FlxUIInputText> = [];
	var blockPressWhileScrolling:Array<FlxUIDropDownMenuCustom> = [];

	var silhouettes:FlxSpriteGroup;
	var dadPosition:FlxPoint/* = FlxPoint.weak()*/;
	var bfPosition:FlxPoint/* = FlxPoint.weak()*/;

	final preGPUCashing = ClientPrefs.cacheOnGPU;

	override function create()
	{
		// FlxG.sound.playMusic(Paths.music('breakfast'), 0.5);

		ClientPrefs.cacheOnGPU = false;

		camEditor = new FlxCamera();
		camHUD = new FlxCamera();
		camHUD.bgColor.alpha = 0;
		FlxG.cameras.reset(camEditor);
		FlxG.cameras.add(camHUD, false);
		FlxG.cameras.setDefaultDrawTarget(camEditor, true);
		Paths.clearStoredMemory(); // reload icons after playstate
		Paths.clearUnusedMemory();
		Main.clearCache();

		add(bgLayer = new FlxTypedGroup<FlxSprite>());

		/*
			silhouettes = new FlxSpriteGroup();
			// add(silhouettes);

			dadPosition.set(100, 100);
			bfPosition.set(770, 100);

			var dad:FlxSprite = new FlxSprite(dadPosition.x, dadPosition.y, Paths.image('ui/editor/silhouetteDad'));
			dad.antialiasing = ClientPrefs.globalAntialiasing;
			dad.active = false;
			dad.offset.set(-4, 1);
			silhouettes.add(dad);

			var boyfriend:FlxSprite = new FlxSprite(bfPosition.x, bfPosition.y + 350, Paths.image('ui/editor/silhouetteBF'));
			boyfriend.antialiasing = ClientPrefs.globalAntialiasing;
			boyfriend.active = false;
			boyfriend.offset.set(-6, 2);
			silhouettes.add(boyfriend);

			silhouettes.alpha = 0.25;
		 */

		add(charLayer = new FlxTypedGroup<Character>());

		cameraFollowPointer = new FlxSprite(FlxGraphic.fromClass(GraphicCursorCross));
		cameraFollowPointer.setGraphicSize(40, 40);
		cameraFollowPointer.updateHitbox();
		cameraFollowPointer.color = FlxColor.WHITE;
		cameraFollowPointer.antialiasing = false;
		add(cameraFollowPointer);

		loadChar(!curCharacter.startsWith('bf'), false);

		healthBar = new Bar(30, FlxG.height - 75, 'healthBar', () -> healthPercent, 0, 1);
		healthBar.flipped = !char.isPlayer;
		healthBar.setColors(FlxColor.LIME, FlxColor.RED);
		healthBar.cameras = [camHUD];
		add(healthBar);

		recreateIcon();

		var aaa:FlxMouseEventManager = new FlxMouseEventManager();
		aaa.add(healthBar, function(_):Void
		{
			if (camHUD.visible)
			{
				curCursor = "button";
				overlapedBar = true;
			}
		},
		null,
		function(_):Void
		{
			if (!overlapedBar && camHUD.visible)
			{
				curCursor = "button";
				overlapedBar = true;
			}
		},
		function(_):Void
		{
			if (overlapedBar && !FlxG.mouse.pressed)
			{
				curCursor = "";
				overlapedBar = false;
			}
		});
		/*
		aaa.add(leHealthIcon, function(_):Void
		{
			leHealthIcon.baseScale = FlxG.mouse.pressed ? 0.95 : 1.1;
			// overlapedBar = true;
		}
		function(_):Void {
			// final arrayAnims = [for (i in leHealthIcon.animsStats.keys()) i];
			// final oldAnim = leHealthIcon.animation.name;
			// var animNext = FlxG.random.getObject(arrayAnims);
			// if (arrayAnims.length > 1)
			// 	while (animNext == oldAnim)
			// 		animNext = FlxG.random.getObject(arrayAnims);
			// leHealthIcon.playAnim(animNext, true);
			leHealthIcon.isPlayer = !leHealthIcon.isPlayer;
			leHealthIcon.baseScale = FlxG.mouse.pressed ? 0.95 : 1.1;
			// overlapedBar = true;
		},
		function(_):Void
		{
			leHealthIcon.baseScale = FlxG.mouse.pressed ? 0.95 : 1.1;
		},
		function(_):Void
		{
			leHealthIcon.baseScale = 1;
			// overlapedBar = false;
		});
		*/
		add(aaa);

		dumbTexts = new FlxTypedGroup<FlxStaticText>();
		add(dumbTexts);
		dumbTexts.cameras = [camHUD];

		textAnim = new FlxStaticText(300, 16);
		textAnim.setFormat(null, 20, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		textAnim.borderSize = 1;
		textAnim.cameras = [camHUD];
		add(textAnim);

		genBoyOffsets();

		var tipText:FlxStaticText = new FlxStaticText(FlxG.width - 15, FlxG.height - 15, 0, "
		E/Q or Wheel Mouse - Camera Zoom In/Out
		R - Reset Camera Zoom
		W/S - Previous/Next Animation
		Space - Play Animation
		Drag Middle Mouse Button - Move Camera
		Arrow Keys / Drag Left Mouse Button - Move Character Offset
		Drag Right Mouse Button - Move Main Character Offset
		Drag Middle and Right Mouse Button - Move Character Camera Point
		T - Reset Current Offset
		TAB - Toggle UI HUD
		Hold Shift to Move 10x slower", 8);
		tipText.cameras = [camHUD];
		tipText.setFormat(null, 8, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE_FAST, FlxColor.BLACK);
		tipText.borderSize = 1;
		add(tipText);
		tipText.x -= tipText.width;
		tipText.y -= tipText.height;

		UI_box = new FlxUITabMenu(null, [
			// {name: 'Offsets', label: 'Offsets'},
			{name: 'Settings', label: 'Settings'},
		], true);
		UI_box.cameras = [camHUD];

		UI_box.resize(250, 120);
		UI_box.x = FlxG.width - 275;
		UI_box.y = 25;

		UI_characterbox = new FlxUITabMenu(null, [
			{name: 'Character', label: 'Character'},
			{name: 'Properties', label: 'Properties'},
			{name: 'Animations', label: 'Animations'},
			{name: 'Icon', label: 'Icon'},
		], true);
		UI_characterbox.cameras = [camHUD];

		UI_characterbox.resize(350, 250);
		UI_characterbox.x = UI_box.x - 100;
		UI_characterbox.y = UI_box.y + UI_box.height;
		add(UI_characterbox);
		add(UI_box);
		UI_characterbox.antialiasing = UI_box.antialiasing = true;

		final bruh = [
			// addOffsetsUI(),
			addSettingsUI(),
			addCharacterUI(),
			addPropertiesUI(),
			addAnimationsUI(),
			addIconUI()
		];

		final stupedGroup:Array<FlxSprite> = [
			for (group in bruh) for (i in group.members) if (i != null && !Std.isOfType(i, FlxStaticText))
				i
		];
		for (i in stupedGroup)
		{
			if (Std.isOfType(i, FlxUIDropDownMenuCustom))
			{
				final i:FlxUIDropDownMenuCustom = cast i;
				i.focusGained = function()
				{
					for (j in stupedGroup)
						if (j.visible)
							j.active = false;
					i.active = true;
					FlxG.sound.keysAllowed = false;
				}
				i.focusLost = () ->
				{
					for (j in stupedGroup)
						if (j.visible)
							j.active = true;
					FlxG.sound.keysAllowed = true;
				}
			}
			else if (Std.isOfType(i, FlxUIInputText))
			{
				final i:FlxUIInputText = cast i;
				i.focusGained = function()
				{
					// for (j in stupedGroup) if (j.visible) j.active = false;
					i.active = true;
					FlxG.sound.keysAllowed = false;
				}
				i.focusLost = () ->
				{
					// for (j in stupedGroup) if (j.visible) j.active = true;
					FlxG.sound.keysAllowed = true;
				}
			}
			else if (Std.isOfType(i, FlxUINumericStepper))
			{
				@:privateAccess final i:FlxUIInputText = cast(cast(i, FlxUINumericStepper).text_field, FlxUIInputText);
				if (i == null)
					continue;
				i.focusGained = function()
				{
					// for (j in stupedGroup) if (j.visible) j.active = false;
					i.active = true;
					FlxG.sound.keysAllowed = false;
				}
				i.focusLost = () ->
				{
					// for (j in stupedGroup) if (j.visible) j.active = true;
					FlxG.sound.keysAllowed = true;
				}
			}
		}
		UI_characterbox.selected_tab_id = 'Character';

		FlxG.mouse.visible = true;
		reloadCharacterOptions();
		tipText.x = UI_characterbox.x + UI_characterbox.width - tipText.width;

		super.create();
		lime.app.Application.current.window.onDropFile.add(loadFromFile);
		updateCurAnimText();
		WindowUtil.endfix = ' - Character Editor';
		// check_player.checked = check_player.checked;
	}

	function loadFromFile(file:String)
	{
		trace(file);
		// try{
		var infoShit;
		infoShit = DropFileUtil.getInfoPath(file, ANIMATE_ATLAS);
		if (infoShit != null)
		{
			trace(infoShit);
			// if (infoShit.modFolder != ModsFolder.currentModFolder && infoShit.modFolder != "assets")
			// {
			// 	return;
			// }
			reloadCharacterImage(infoShit.file);
		}
		if (file.endsWith('.json'))
		{
			infoShit = DropFileUtil.getInfoPath(file, CHARACTER);
			if (infoShit == null)
			{
				infoShit = DropFileUtil.getInfoPath(file, ICON);
				if (infoShit == null)
					return;
				leHealthIcon.changeIcon(healthIconInputText.text = infoShit.file);
				char.healthIcon = infoShit.file;
				updatePresence();
				return;
			}

			// ModsFolder.currentModFolder = infoShit.modFolder;
			curCharacter = infoShit.file + '.json';
			check_player.checked = curCharacter.startsWith('bf');
			loadChar(!check_player.checked);
			updatePresence();
			reloadCharacterDropDown();
		}
		else if (file.endsWith('.png') || file.endsWith('.xml'))
		{
			infoShit = DropFileUtil.getInfoPath(file, ICONPNG);
			if (infoShit == null)
			{
				infoShit = DropFileUtil.getInfoPath(file, IMAGE /* CHARACTERPNG */);
				if (infoShit == null)
				{
					return;
				}
				/*
				// trace([infoShit.modFolder, ModsFolder.currentModFolder]);
				if (infoShit.modFolder != ModsFolder.currentModFolder && infoShit.modFolder != "assets")
				{
					return;
				}
				*/
				reloadCharacterImage(infoShit.file);
				return;
			}
			trace(infoShit.file);
			leHealthIcon.changeIcon(healthIconInputText.text = infoShit.file);
			char.healthIcon = infoShit.file;
			updatePresence();
		}

		// var modFolder = file.split("\\");
		// // trace(modFolder);
		// trace(ModsFolder.currentModFolder = modFolder[modFolder.length - 1 - 3]);
		// // ModsFolder.currentModFolder = '';
		// loadJson(file, true);
		// }
	}

	override function destroy()
	{
		WindowUtil.resetTitle();
		ClientPrefs.cacheOnGPU = preGPUCashing;
		lime.app.Application.current.window.onDropFile.remove(loadFromFile);
		super.destroy();
	}

	var OFFSET_X:Float = 300;

	function reloadBGs()
	{
		while (bgLayer.members.length > 0)
		{
			bgLayer.members.pop()?.destroy();
		}
		bgLayer.clear();

		final playerXDifference = char.isPlayer ? 670 : 0;

		bgLayer.add(new BGSprite('stageback', -600 + OFFSET_X - playerXDifference, -300, 0.9, 0.9));

		var stageFront:BGSprite = new BGSprite('stagefront', -650 + OFFSET_X - playerXDifference, 500);
		stageFront.setGraphicSize(stageFront.width * 1.1);
		stageFront.updateHitbox();
		bgLayer.add(stageFront);
		char.setPosition(OFFSET_X + 100, 0);
		char.updateFlip();
		updatePointerPos();
		recreateIcon();
	}

	/*var animationInputText:FlxUIInputText;
		function addOffsetsUI() {
			var tab_group = new FlxUI(null, UI_box);
			tab_group.name = "Offsets";

			animationInputText = new FlxUIInputText(15, 30, 100, 'idle', 8);

			var addButton:FlxButton = new FlxButton(animationInputText.x + animationInputText.width + 23, animationInputText.y - 2, "Add", function()
			{
				var theText:String = animationInputText.text;
				if(theText != '') {
					var alreadyExists:Bool = false;
					for (i in 0...animList.length) {
						if(animList[i] == theText) {
							alreadyExists = true;
							break;
						}
					}

					if(!alreadyExists) {
						char.animOffsets.set(theText, [0, 0]);
						animList.push(theText);
					}
				}
			});

			var removeButton:FlxButton = new FlxButton(animationInputText.x + animationInputText.width + 23, animationInputText.y + 20, "Remove", function()
			{
				var theText:String = animationInputText.text;
				if(theText != '') {
					for (i in 0...animList.length) {
						if(animList[i] == theText) {
							if(char.animOffsets.exists(theText)) {
								char.animOffsets.remove(theText);
							}

							animList.remove(theText);
							if(char.curAnimName == theText && animList.length > 0) {
								char.playAnim(animList[0], true);
							}
							break;
						}
					}
				}
			});

			var saveButton:FlxButton = new FlxButton(animationInputText.x, animationInputText.y + 35, "Save Offsets", function()
			{
				saveOffsets();
			});

			tab_group.add(new FlxStaticText(10, animationInputText.y - 18, 0, 'Add/Remove Animation:'));
			tab_group.add(addButton);
			tab_group.add(removeButton);
			tab_group.add(saveButton);
			tab_group.add(animationInputText);
			UI_box.addGroup(tab_group);
			return tab_group;
	}*/

	var charDropDown:FlxUIDropDownMenuCustom;
	var check_player:FlxUICheckBox;

	function addSettingsUI()
	{
		var tab_group = new FlxUI(null, UI_box);
		tab_group.name = "Settings";

		check_player = new FlxUICheckBox(10, 60, null, null, "Playable Character", 100);
		check_player.checked = curCharacter.startsWith('bf');
		check_player.callback = function() {
			char.isPlayer = !char.isPlayer;
			char.flipX = !char.flipX;
			ghostChar.flipX = char.flipX;
			char.updateFlip();
			ghostChar.updateFlip();
			updateHealthBarColor();
			reloadBGs();
		};

		charDropDown = new FlxUIDropDownMenuCustom(10, 30, FlxUIDropDownMenuCustom.makeStrIdLabelArray([''], true), function(character:String)
		{
			character = characterList[Std.parseInt(character)];
			if (!character.endsWith('.json'))
			{
				reloadCharacterDropDown();
				// charDropDown.selectedLabel = curCharacter;
				return;
			}
			curCharacter = character;
			check_player.checked = curCharacter.startsWith('bf');
			loadChar(!check_player.checked);
			updatePresence();
			reloadCharacterDropDown();
		});
		blockPressWhileScrolling.push(charDropDown);
		charDropDown.selectedLabel = curCharacter;
		reloadCharacterDropDown();
		var reloadCharacter:FlxButton = new FlxButton(140, 20, "Reload Char", function()
		{
			loadChar(!check_player.checked);
			reloadCharacterDropDown();
		});

		var templateCharacter:FlxButton = new FlxButton(140, 50, "Load Template", function()
		{
			curCharacter = "dad.json"; // HERE DEFAULT CHARACTER
			charDropDown.selectedLabel = curCharacter;
			check_player.checked = curCharacter.startsWith('bf');
			loadChar(!check_player.checked);
			updatePresence();
			reloadCharacterDropDown();
		});
		templateCharacter.color = FlxColor.RED;
		templateCharacter.label.color = FlxColor.WHITE;

		tab_group.add(new FlxStaticText(charDropDown.x, charDropDown.y - 18, 0, 'Character:'));
		tab_group.add(check_player);
		tab_group.add(reloadCharacter);
		tab_group.add(charDropDown);
		tab_group.add(reloadCharacter);
		tab_group.add(templateCharacter);
		UI_box.addGroup(tab_group);
		return tab_group;
	}

	var scaleIconStepper:FlxUINumericStepper;
	var positionIconXStepper:FlxUINumericStepper;
	var positionIconYStepper:FlxUINumericStepper;
	var flipIconXCheckBox:FlxUICheckBox;
	var noAntialiasingIconCheckBox:FlxUICheckBox;
	var colorPicker:ColorPickerGroup;
	var healthIconInputText:FlxUIInputText;

	function addIconUI()
	{
		var tab_group = new FlxUI(null, UI_box);
		tab_group.name = "Icon";

		colorPicker = new ColorPickerGroup(char.healthColor, function(e)
		{
			char.healthColor = e;
			updateHealthBarColor();
		}, () -> char.healthColor);
		colorPicker.x = 20;
		colorPicker.y = UI_characterbox.y + 50;

		healthIconInputText = new FlxUIInputText(15, 35, 75, leHealthIcon.getCharacter(), 8);

		scaleIconStepper = new FlxUINumericStepper(15, healthIconInputText.y + 40, 0.1, 1, 0.05, 10, 2);

		flipIconXCheckBox = new FlxUICheckBox(healthIconInputText.x + healthIconInputText.width + 20, healthIconInputText.y, null, null, "Flip X", 40);
		flipIconXCheckBox.checked = false;
		// if(char.isPlayer) flipIconXCheckBox.checked = !flipIconXCheckBox.checked;
		flipIconXCheckBox.callback = function() { };

		var reloadImage:FlxButton = new FlxButton(flipIconXCheckBox.x + flipIconXCheckBox.width + 10, 30, "Reload Image", function()
		{
			leHealthIcon.changeIcon(healthIconInputText.text);
			char.healthIcon = healthIconInputText.text;
			updatePresence();
		});

		noAntialiasingIconCheckBox = new FlxUICheckBox(flipIconXCheckBox.x, flipIconXCheckBox.y + 30, null, null, "No Antialiasing", 80);
		noAntialiasingIconCheckBox.checked = !leHealthIcon.antialiasing;
		// noAntialiasingIconCheckBox.callback = function() { leHealthIcon.antialiasing = !noAntialiasingIconCheckBox.checked};
		var saveCharacterButton:FlxButton = new FlxButton(reloadImage.x + reloadImage.width + 5, reloadImage.y, "Save Icon", () ->
		{
			colorPicker.defaultColor = char.healthColor;
		});

		var decideIconColor:FlxButton = new FlxButton(saveCharacterButton.x, saveCharacterButton.y + saveCharacterButton.height + 10, "Get Icon Color",
			function()
			{
				var coolColor = CoolUtil.colorFromFlxSprite(leHealthIcon);
				char.healthColor = coolColor;
				// char.healthColorArray[0] = coolColor.red;
				// char.healthColorArray[1] = coolColor.green;
				// char.healthColorArray[2] = coolColor.blue;

				// healthColorStepperR.value = coolColor.red;
				// healthColorStepperG.value = coolColor.green;
				// healthColorStepperB.value = coolColor.blue;
				// getEvent(FlxUINumericStepper.CHANGE_EVENT, healthColorStepperR, null);
				// getEvent(FlxUINumericStepper.CHANGE_EVENT, healthColorStepperG, null);
				// getEvent(FlxUINumericStepper.CHANGE_EVENT, healthColorStepperB, null);
				resetHealthBarColor();
			});

		// healthColorStepperR = new FlxUINumericStepper(singDurationStepper.x, saveCharacterButton.y, 20, char.healthColorArray[0], 0, 255, 0);
		// healthColorStepperG = new FlxUINumericStepper(singDurationStepper.x + 65, saveCharacterButton.y, 20, char.healthColorArray[1], 0, 255, 0);
		// healthColorStepperB = new FlxUINumericStepper(singDurationStepper.x + 130, saveCharacterButton.y, 20, char.healthColorArray[2], 0, 255, 0);

		tab_group.add(new FlxStaticText(15, healthIconInputText.y - 18, 0, 'Health icon file:'));
		tab_group.add(new FlxStaticText(15, scaleIconStepper.y - 18, 0, 'Scale:'));
		// tab_group.add(new FlxStaticText(positionXStepper.x, positionXStepper.y - 18, 0, 'Character X/Y:'));
		// tab_group.add(new FlxStaticText(positionCameraXStepper.x, positionCameraXStepper.y - 18, 0, 'Camera X/Y:'));
		// tab_group.add(new FlxStaticText(healthColorStepperR.x, healthColorStepperR.y - 18, 0, 'Health bar R/G/B:'));
		tab_group.add(reloadImage);
		tab_group.add(decideIconColor);
		tab_group.add(healthIconInputText);
		tab_group.add(scaleIconStepper);
		tab_group.add(flipIconXCheckBox);
		tab_group.add(noAntialiasingIconCheckBox);
		// tab_group.add(positionXStepper);
		// tab_group.add(positionYStepper);
		// tab_group.add(healthColorStepperR);
		// tab_group.add(healthColorStepperG);
		// tab_group.add(healthColorStepperB);
		tab_group.add(saveCharacterButton);
		tab_group.add(colorPicker);
		// add(colorPicker);
		UI_characterbox.addGroup(tab_group);
		return tab_group;
	}

	var imageInputText:FlxUIInputText;

	var numBeatDanceStepper:FlxUINumericStepper;
	var singDurationStepper:FlxUINumericStepper;
	var scaleStepper:FlxUINumericStepper;
	var positionXStepper:FlxUINumericStepper;
	var positionYStepper:FlxUINumericStepper;
	var positionCameraXStepper:FlxUINumericStepper;
	var positionCameraYStepper:FlxUINumericStepper;

	var fixFlipCheckBox:FlxUICheckBox;
	var flipXCheckBox:FlxUICheckBox;
	var flipYCheckBox:FlxUICheckBox;
	var noAntialiasingCheckBox:FlxUICheckBox;

	var optimizeJsonBox:FlxUICheckBox;

	// var healthColorStepperR:FlxUINumericStepper;
	// var healthColorStepperG:FlxUINumericStepper;
	// var healthColorStepperB:FlxUINumericStepper;

	function addCharacterUI()
	{
		var tab_group = new FlxUI(null, UI_box);
		tab_group.name = "Character";

		imageInputText = new FlxUIInputText(15, 30, 200, 'characters/BOYFRIEND', 8);
		var reloadImage:FlxButton = new FlxButton(imageInputText.x + 210, imageInputText.y - 3, "Reload Image", function()
		{
			reloadCharacterImage(imageInputText.text);

			// var paths = [for (i in imageInputText.text.split(";")) i.trim()];
			var isInvalid:Bool = char.curAnimName != char.animationsArray[curAnim]?.anim;
			// for (i in paths)
			// 	isInvalid = Paths.getAtlas(i) == null || isInvalid;

			if (FlxG.random.bool(3.5))
				openSubState(new Secret(isInvalid));

		});

		// healthIconInputText = new FlxUIInputText(15, imageInputText.y + 35, 75, leHealthIcon.getCharacter(), 8);

		singDurationStepper = new FlxUINumericStepper(15, imageInputText.y + 45, 0.1, 4, 0, 999, 1);

		numBeatDanceStepper = new FlxUINumericStepper(singDurationStepper.x, singDurationStepper.y + 45, 1, char.danceEveryNumBeats, 1, 69, 0);

		scaleStepper = new FlxUINumericStepper(15, numBeatDanceStepper.y + 40, 0.05, 1, 0.05, 10, 2);


		fixFlipCheckBox = new FlxUICheckBox(numBeatDanceStepper.x + 100, numBeatDanceStepper.y - 23, null, null, "Fix Flip", 50);
		fixFlipCheckBox.checked = char.fixFlip;
		fixFlipCheckBox.callback = function()
		{
			char.fixFlip = !char.fixFlip;
			ghostChar.fixFlip = char.fixFlip;
			char.updateFlip();
			ghostChar.updateFlip();
		};


		flipXCheckBox = new FlxUICheckBox(numBeatDanceStepper.x + 100, numBeatDanceStepper.y, null, null, "Flip X", 50);
		flipXCheckBox.checked = char.flipX;
		if (char.isPlayer)
			flipXCheckBox.checked = !flipXCheckBox.checked;
		flipXCheckBox.callback = function()
		{
			char.originalFlipX = !char.originalFlipX;
			char.flipX = char.originalFlipX;
			if (char.isPlayer)
				char.flipX = !char.flipX;

			ghostChar.flipX = char.flipX;
			char.updateFlip();
			ghostChar.updateFlip();
		};

		flipYCheckBox = new FlxUICheckBox(flipXCheckBox.x, flipXCheckBox.y + 23, null, null, "Flip Y", 50);
		flipYCheckBox.checked = char.flipY;
		flipYCheckBox.callback = function()
		{
			char.originalFlipY = !char.originalFlipY;
			char.flipY = ghostChar.flipY = char.originalFlipY;
		};

		noAntialiasingCheckBox = new FlxUICheckBox(flipYCheckBox.x, flipYCheckBox.y + 35, null, null, "No Antialiasing", 80);
		noAntialiasingCheckBox.checked = char.noAntialiasing;
		noAntialiasingCheckBox.callback = function()
		{
			char.antialiasing = false;
			if (!noAntialiasingCheckBox.checked && ClientPrefs.globalAntialiasing)
				char.antialiasing = true;
			char.noAntialiasing = noAntialiasingCheckBox.checked;
			ghostChar.antialiasing = char.antialiasing;
		};

		positionXStepper = new FlxUINumericStepper(flipXCheckBox.x + 110, flipXCheckBox.y, 10, char.positionArray[0], -9000, 9000, 0);
		positionYStepper = new FlxUINumericStepper(positionXStepper.x + 60, positionXStepper.y, 10, char.positionArray[1], -9000, 9000, 0);

		positionCameraXStepper = new FlxUINumericStepper(positionXStepper.x, positionXStepper.y + 40, 10, char.cameraPosition[0], -9000, 9000, 0);
		positionCameraYStepper = new FlxUINumericStepper(positionYStepper.x, positionYStepper.y + 40, 10, char.cameraPosition[1], -9000, 9000, 0);

		var saveCharacterButton:FlxButton = new FlxButton(reloadImage.x, noAntialiasingCheckBox.y + 20, "Save Character", function()
		{
			saveCharacter();
			colorPicker.defaultColor = char.healthColor;
		});

		optimizeJsonBox = new FlxUICheckBox(saveCharacterButton.x - 65, saveCharacterButton.y, null, null, "Optimize JSON?", 55);
		optimizeJsonBox.checked = true;

		// healthColorStepperR = new FlxUINumericStepper(singDurationStepper.x, saveCharacterButton.y, 20, char.healthColorArray[0], 0, 255, 0);
		// healthColorStepperG = new FlxUINumericStepper(singDurationStepper.x + 65, saveCharacterButton.y, 20, char.healthColorArray[1], 0, 255, 0);
		// healthColorStepperB = new FlxUINumericStepper(singDurationStepper.x + 130, saveCharacterButton.y, 20, char.healthColorArray[2], 0, 255, 0);

		tab_group.add(new FlxStaticText(15, imageInputText.y - 18, 0, 'Image file name:'));
		// tab_group.add(new FlxStaticText(15, healthIconInputText.y - 18, 0, 'Health icon name:'));
		tab_group.add(new FlxStaticText(15, singDurationStepper.y - 18, 0, 'Sing Animation length:'));
		tab_group.add(new FlxStaticText(15, numBeatDanceStepper.y - 18, 0, 'Dance beat factor:'));
		tab_group.add(new FlxStaticText(15, scaleStepper.y - 18, 0, 'Scale:'));
		tab_group.add(new FlxStaticText(positionXStepper.x, positionXStepper.y - 18, 0, 'Character X/Y:'));
		tab_group.add(new FlxStaticText(positionCameraXStepper.x, positionCameraXStepper.y - 18, 0, 'Camera X/Y:'));
		// tab_group.add(new FlxStaticText(healthColorStepperR.x, healthColorStepperR.y - 18, 0, 'Health bar R/G/B:'));
		tab_group.add(imageInputText);
		tab_group.add(reloadImage);
		// tab_group.add(healthIconInputText);
		tab_group.add(singDurationStepper);
		tab_group.add(numBeatDanceStepper);
		tab_group.add(scaleStepper);
		tab_group.add(fixFlipCheckBox);
		tab_group.add(flipXCheckBox);
		tab_group.add(flipYCheckBox);
		tab_group.add(noAntialiasingCheckBox);
		tab_group.add(positionXStepper);
		tab_group.add(positionYStepper);
		tab_group.add(positionCameraXStepper);
		tab_group.add(positionCameraYStepper);
		// tab_group.add(healthColorStepperR);
		// tab_group.add(healthColorStepperG);
		// tab_group.add(healthColorStepperB);
		tab_group.add(saveCharacterButton);
		tab_group.add(optimizeJsonBox);
		UI_characterbox.addGroup(tab_group);
		return tab_group;
	}

	var characterDeathName:FlxUIInputText;
	var characterDeathSound:FlxUIInputText;
	var characterDeathConfirm:FlxUIInputText;
	var characterDeathMusic:FlxUIInputText;
	var characterDeathMusicBPM:FlxUINumericStepper;
	function addPropertiesUI()
	{
		var tab_group = new FlxUI(null, UI_box);
		tab_group.name = "Properties";

		characterDeathName = new FlxUIInputText(15, 35, 150, char.gameoverProperties?.char ?? "", 8);
		characterDeathSound = new FlxUIInputText(characterDeathName.x, characterDeathName.y + 43, 150, char.gameoverProperties?.startSound ?? "", 8);
		characterDeathConfirm = new FlxUIInputText(characterDeathName.x, characterDeathSound.y + 40, 150, char.gameoverProperties?.confirmSound ?? "", 8);
		characterDeathMusic = new FlxUIInputText(characterDeathName.x, characterDeathConfirm.y + 43, 150, char.gameoverProperties?.music ?? "", 8);
		characterDeathMusicBPM = new FlxUINumericStepper(characterDeathName.x, characterDeathMusic.y + 40, 5, char.gameoverProperties?.bpm ?? 100, 0, 1000, 2);

		tab_group.add(new FlxStaticText(characterDeathName.x, characterDeathName.y - 18, 0, 'Game Over Character:'));
		tab_group.add(new FlxStaticText(characterDeathSound.x, characterDeathSound.y - 18, 0, 'Game Over Starting Sound:'));
		tab_group.add(new FlxStaticText(characterDeathConfirm.x, characterDeathConfirm.y - 18, 0, 'Game Over Confirm Sound:'));
		tab_group.add(new FlxStaticText(characterDeathMusic.x, characterDeathMusic.y - 18, 0, 'Game Over Music:'));
		tab_group.add(new FlxStaticText(characterDeathMusicBPM.x, characterDeathMusicBPM.y - 18, 0, 'Game Over Music BPM:'));

		tab_group.add(characterDeathName);
		tab_group.add(characterDeathSound);
		tab_group.add(characterDeathConfirm);
		tab_group.add(characterDeathMusic);
		tab_group.add(characterDeathMusicBPM);

		UI_characterbox.addGroup(tab_group);
		return tab_group;
	}

	var ghostDropDown:FlxUIDropDownMenuCustom;
	var animationDropDown:FlxUIDropDownMenuCustom;
	var animationInputText:FlxUIInputText;
	var animationNameInputText:FlxUIInputText;
	var animationIndicesInputText:FlxUIInputText;
	var animationNameFramerate:FlxUINumericStepper;
	var animationLoopPoint:FlxUINumericStepper;
	var animationLoopCheckBox:FlxUICheckBox;
	var animationFlipXCheckBox:FlxUICheckBox;
	var animationFlipYCheckBox:FlxUICheckBox;
	var addUpdateButton:FlxButton;

	function addAnimationsUI()
	{
		var tab_group = new FlxUI(null, UI_box);
		tab_group.name = "Animations";

		animationInputText = new FlxUIInputText(15, 85, 80, '', 8);
		animationNameInputText = new FlxUIInputText(animationInputText.x, animationInputText.y + 35, 150, '', 8);
		animationIndicesInputText = new FlxUIInputText(animationNameInputText.x, animationNameInputText.y + 40, 250, '', 8);
		animationNameFramerate = new FlxUINumericStepper(animationInputText.x + 170, animationInputText.y, 1, 24, 0, 240, 2);
		animationLoopPoint = new FlxUINumericStepper(animationNameFramerate.x + 100, animationNameFramerate.y, 1, 0, 0, 9999, 0);
		animationLoopCheckBox = new FlxUICheckBox(animationNameInputText.x + 170, animationNameInputText.y - 1, null, null, "Should it Loop?", 80);
		animationFlipXCheckBox = new FlxUICheckBox(animationLoopCheckBox.x + 110, animationLoopCheckBox.y, null, null, "Flip X", 33);
		animationFlipYCheckBox = new FlxUICheckBox(animationFlipXCheckBox.x, animationFlipXCheckBox.y + 23, null, null, "Flip Y", 33);

		animationDropDown = new FlxUIDropDownMenuCustom(15, animationInputText.y - 55, FlxUIDropDownMenuCustom.makeStrIdLabelArray([''], true),
			function(pressed:String)
			{
				// var selectedAnimation:Int = ;
				final anim:AnimArray = char.animationsArray[Std.parseInt(pressed)];
				if (anim == null)
					return;
				animationInputText.text = anim.anim;
				animationNameInputText.text = anim.name;
				animationLoopCheckBox.checked = anim.loop;
				animationNameFramerate.value = anim.fps == null ? 24 : anim.fps;
				animationLoopPoint.value = anim.loopPoint;
				animationFlipXCheckBox.checked = anim.flipX;
				animationFlipYCheckBox.checked = anim.flipY;
				if (anim.indices == null)
				{
					animationIndicesInputText.text = '';
				}
				else
				{
					final indicesStr:String = anim.indices.toString();
					animationIndicesInputText.text = indicesStr.substr(1, indicesStr.length - 2);
				}
			});

		ghostDropDown = new FlxUIDropDownMenuCustom(animationDropDown.x + 150, animationDropDown.y, FlxUIDropDownMenuCustom.makeStrIdLabelArray([''], true),
			function(pressed:String)
			{
				final selectedAnimation:Int = Std.parseInt(pressed) - 1;
				// trace('chupep');
				ghostChar.visible = false;
				// trace('chupep');
				char.alpha = 1;
				// trace('chupep');
				if (selectedAnimation >= 0)
				{
					// trace('chupep');
					ghostChar.visible = true;
					// trace('chupep');
					// if (char.animationsArray[selectedAnimation] != null) trace(char.animationsArray[selectedAnimation].anim);
					ghostChar.playAnim(char.animationsArray[selectedAnimation].anim, true);
					// trace('chupep');
					char.alpha = 0.85;
					// trace('chupep');
				}
				// reloadGhost();
			});
		blockPressWhileScrolling.push(animationDropDown);
		blockPressWhileScrolling.push(ghostDropDown);
		addUpdateButton = new FlxButton(20, animationIndicesInputText.y + 17, "Add/Update", function()
		{
			var index:Int;
			// if (animationInputText.text.trim() == '') return;
			var indices:Array<Int> = [];
			var indicesStr:Array<String> = animationIndicesInputText.text.trim().split(",");
			if (!animationIndicesInputText.text.contains(",") && animationIndicesInputText.text.contains('...'))
			{
				var umm:Array<Int> = [for (i in animationIndicesInputText.text.split('...'))
					if (!Math.isNaN(index = Std.parseInt(i)) /* && index > -1*/)
						index
				];
				if (umm.length > 1 && umm[0] != umm[1])
				{
					indicesStr = [
						for (i in (umm[0] < umm[1] ? umm[0]...umm[1] + 1 : umm[1]...umm[0] + 1)) Std.string(i)
					];
					if (umm[0] >= umm[1])
						indicesStr.reverse();
				}

				animationIndicesInputText.text = indicesStr.join(', ');
			}
			for (i => str in indicesStr)
			{
				if (/*str != null && */str != '' && !Math.isNaN(index = Std.parseInt(str)) && index > -1)
					indices.push(index);
			}
			// trace(indices);
			// trace(indicesStr);

			var lastAnim:String = char.getAnimName();

			var lastOffsets:Array<Float> = [char.__drawingOffset.x, char.__drawingOffset.y];
			for (anim in char.animationsArray)
				if (animationInputText.text == anim.anim)
				{
					lastOffsets = anim.offsets;
					if (char.hasAnimation(animationInputText.text))
						char.removeAnimation(animationInputText.text);
					char.animationsArray.remove(anim);
					break;
				}

			var newAnim:AnimArray = {
				anim: animationInputText.text,
				name: animationNameInputText.text,
				fps: FlxMath.roundDecimal(animationNameFramerate.value, 2),
				loop: animationLoopCheckBox.checked,
				loopPoint: Std.int(animationLoopPoint.value),
				flipX: animationFlipXCheckBox.checked,
				flipY: animationFlipYCheckBox.checked,
				indices: indices,
				offsets: lastOffsets
			};
			char.addAnimation(newAnim.anim, newAnim.name, newAnim.indices, newAnim.offsets, newAnim.fps, newAnim.loopPoint, newAnim.loop == true,
				newAnim.flipX, newAnim.flipY);
			char.animationsArray.push(newAnim);
			// var deAnim:FlxAnimation = char.animation.getByName('' + newAnim.anim);
			// if(deAnim != null && deAnim.frames.length > 0) animationLoopPoint.value = newAnim.loopPoint = Math.round(CoolUtil.boundTo(animationLoopPoint.value, 0, deAnim.frames.length - 2));
			/*
				if(indices != null && indices.length > 0) char.animation.addByIndices('' + newAnim.anim, '' + newAnim.name, newAnim.indices, "", 24, newAnim.loop);
				else char.animation.addByPrefix('' + newAnim.anim, '' + newAnim.name, 24, newAnim.loop);

				if(!char.animOffsets.exists(newAnim.anim)) char.addOffset(newAnim.anim, 0, 0);
				var deAnim:FlxAnimation = char.animation.getByName('' + newAnim.anim);
				if(deAnim != null && deAnim.frames.length > 0) animationLoopPoint.value = newAnim.loopPoint = Math.round(CoolUtil.boundTo(animationLoopPoint.value, 0, deAnim.frames.length - 2));
				char.animationsArray.push(newAnim);
				char.updateFlxAnimation(newAnim); */

			if (lastAnim == animationInputText.text)
			{
				var leAnim:FlxAnimation = char.animation.getByName(lastAnim);
				if (leAnim != null && leAnim.frames.length > 0)
				{
					char.playAnim(lastAnim, true);
				}
				else
				{
					for (i in 0...char.animationsArray.length)
					{
						if (char.animationsArray[i] != null)
						{
							leAnim = char.animation.getByName(char.animationsArray[i].anim);
							if (leAnim != null && leAnim.frames.length > 0)
							{
								char.playAnim(char.animationsArray[i].anim, true);
								curAnim = i;
								break;
							}
						}
					}
				}
			}

			reloadAnimationDropDown();
			genBoyOffsets();
			trace('Added/Updated animation: ' + animationInputText.text);
		});

		var flipAnimButton:FlxButton = new FlxButton(addUpdateButton.x, addUpdateButton.y + 23, "Flip Left Right", function()
		{
			if (char.animationsArray.length < 2)
				return;
			var curGhostAnim = ghostDropDown.selectedLabel; // KILL
			function replaceAnim(anim:AnimArray, nextAnim:String)
			{
				var oldName = anim.name;
				anim.anim = nextAnim;
				for (i in [char, ghostChar])
				{
					if (i.hasAnimation(anim.name))
						i.removeAnimation(oldName);

					i.addAnimation(anim.anim, anim.name, anim.indices, anim.offsets, anim.fps, anim.loopPoint, anim.loop, anim.flipX,
						anim.flipY);
				}
			}
			for (anim in char.animationsArray)
				if (anim.anim.indexOf('singRIGHT') != -1)
				{
					replaceAnim(anim, anim.anim.replace('singRIGHT', 'singLEFT'));
				}
				else if (anim.anim.indexOf('singLEFT') != -1)
				{
					replaceAnim(anim, anim.anim.replace('singLEFT', 'singRIGHT'));
				}

			ghostDropDown.selectedLabel = curGhostAnim; // kill
			reloadAnimationDropDown();
			ghostDropDown.selectedLabel = curGhostAnim; // kill
			genBoyOffsets();
			ghostDropDown.selectedLabel = curGhostAnim; // kill

			char.playAnim(char.animationsArray[curAnim].anim, false);
			if (ghostChar.animation.curAnim != null && char.animation.curAnim != null && char.curAnimName == ghostChar.curAnimName)
				ghostChar.playAnim(char.curAnimName, false);

			ghostDropDown.selectedLabel = curGhostAnim; // kill
		});

		var removeButton:FlxButton = new FlxButton(addUpdateButton.x + addUpdateButton.width + 30, addUpdateButton.y, "Remove", function()
		{
			for (anim in char.animationsArray)
			{
				if (animationInputText.text == anim.anim)
				{
					final resetAnim:Bool = anim.anim == char.curAnimName;

					if (char.hasAnimation(anim.anim))
						char.removeAnimation(anim.anim);
					// if(char.animation.getByName(anim.anim) != null) char.animation.remove(anim.anim);

					if (char.animOffsets.exists(anim.anim))
					{
						char.animOffsets.get(anim.anim).put();
						char.animOffsets.remove(anim.anim);
					}
					char.animationsArray.remove(anim);
					char.animation.curAnim = null;
					if (resetAnim && char.animationsArray.length > 0)
						char.playAnim(char.animationsArray[0].anim, true);
					reloadAnimationDropDown();
					genBoyOffsets();
					trace('Removed animation: ' + animationInputText.text);
					break;
				}
			}
		});

		var removeAllButton:FlxButton = new FlxButton(removeButton.x, flipAnimButton.y, "Remove All Anims", function()
		{
			for (anim in char.animationsArray)
			{
				if (char.hasAnimation(anim.anim))
					char.removeAnimation(anim.anim);
				if (char.animOffsets.exists(anim.anim))
				{
					char.animOffsets.get(anim.anim).put();
					char.animOffsets.remove(anim.anim);
				}
			}
			char.animation.curAnim = null;
			char.animationsArray = [];
			reloadAnimationDropDown();
			genBoyOffsets();
		});

		var autoFindButton:FlxButton = new FlxButton(removeButton.x + removeButton.width + 30, addUpdateButton.y, "Find Anims", function()
		{
			if (char.frames == null || char.frames.frames == null)
				return;
			function addAnim(animJson:String, animBase:String)
			{
				for (i in char.animationsArray)
					if (i.anim == animJson)
						return; // if already added, will ignore

				var newAnim:AnimArray = {
					anim: animJson,
					name: animBase,
					fps: 24
				};
				if (char.hasAnimation(newAnim.name))
					char.removeAnimation(newAnim.name);

				char.addAnimation(newAnim.anim, newAnim.name, newAnim.indices, null, newAnim.fps,
					newAnim.loopPoint, newAnim.loop, newAnim.flipX, newAnim.flipY);
				char.animationsArray.push(newAnim);
				trace('Added $animJson from $animBase');
			}

			if (!char.useAtlas)
			{
				var deFrames:Array<String> = [];
				var e;
				for (i in char.frames.frames)
				{
					e = i.name.substr(0, i.name.length - 3);
					if (!deFrames.contains(e))
						deFrames.push(e);
				}
				var nameAnim;
				var missName;
				var altName;
				for (anim in deFrames)
				{
					nameAnim = anim.toLowerCase();
					missName = nameAnim.indexOf('miss') != -1 ? 'miss' : '';
					altName = nameAnim.indexOf('alt') != -1 ? '-alt' : '';
					if (nameAnim.indexOf('idle') != -1)
						addAnim('idle' + altName, anim);
					else if (nameAnim.indexOf('left') != -1)
						addAnim('singLEFT' + missName + altName, anim);
					else if (nameAnim.indexOf('right') != -1)
						addAnim('singRIGHT' + missName + altName, anim);
					else if (nameAnim.indexOf('down') != -1)
						addAnim('singDOWN' + missName + altName, anim);
					else if (nameAnim.indexOf('up') != -1)
						addAnim('singUP' + missName + altName, anim);
					else if (nameAnim.indexOf('hey') != -1)
						addAnim('hey' + altName, anim);
					else if (nameAnim.indexOf('loop') != -1)
						addAnim('deathLoop' + altName, anim);
					else if (nameAnim.indexOf('confirm') != -1)
						addAnim('deathConfirm' + altName, anim);
					else if (nameAnim.indexOf('die') != -1 || nameAnim.indexOf('death') != -1)
						addAnim('firstDeath' + altName, anim);
					// trace(nameAnim);
				}
			}

			genBoyOffsets();
			reloadAnimationDropDown();
			// reloadGhost();
		});

		var removeMissingAnimsButton:FlxButton = new FlxButton(autoFindButton.x, flipAnimButton.y, "Remove Missing Anims", function()
		{
			var e = [];
			for (anim in char.animationsArray)
			{
				if (char.hasAnimation(anim.anim)) continue;
				e.push(anim);
				char.removeAnimation(anim.anim);
				if (char.animOffsets.exists(anim.anim))
				{
					char.animOffsets.get(anim.anim).put();
					char.animOffsets.remove(anim.anim);
				}
				trace('Removed \"${anim.anim}\" anim');
			}
			if (e.length > 0)
				for (i in e)
					char.animationsArray.remove(i);
			genBoyOffsets();
			reloadAnimationDropDown();
		});
		for (button in [removeAllButton, removeMissingAnimsButton])
		{
			for (i in button.labelOffsets)
			{
				i.y -= 2;
			}
			button.label.y -= 2;
		}

		/* // use funkin packer https://neeeoo.github.io/funkin-packer/
		var optimButton:FlxButton = new FlxButton(autoFindButton.x, flipAnimButton.y, "Optimize Image", function()
		{
			if (char.useAtlas)
				return;
			final assetsPath:String = 'assets/images/' + char.imageFile + '.png'; // lame
			CoolUtil.optimizeImageSyns(Assets.getPath(assetsPath), char.frames, FlxG.keys.pressed.SHIFT ) // Why not?
				.onComplete((_) -> {})
				.onError((e) -> trace(e));
		});
		*/

		tab_group.add(new FlxStaticText(animationDropDown.x, animationDropDown.y - 18, 0, 'Animations:'));
		tab_group.add(new FlxStaticText(ghostDropDown.x, ghostDropDown.y - 18, 0, 'Animation Ghost:'));
		tab_group.add(new FlxStaticText(animationInputText.x, animationInputText.y - 18, 0, 'Animation name:'));
		tab_group.add(new FlxStaticText(animationNameFramerate.x, animationNameFramerate.y - 18, 0, 'Framerate:'));
		tab_group.add(new FlxStaticText(animationLoopPoint.x - 20, animationLoopPoint.y - 18, 0, 'Start Frame on loop:'));
		tab_group.add(new FlxStaticText(animationNameInputText.x, animationNameInputText.y - 18, 0, 'Animation on .XML/.TXT/.JSON file:'));
		tab_group.add(new FlxStaticText(animationIndicesInputText.x, animationIndicesInputText.y - 18, 0, 'ADVANCED - Animation Indices:'));

		tab_group.add(animationInputText);
		tab_group.add(animationNameInputText);
		tab_group.add(animationIndicesInputText);
		tab_group.add(animationNameFramerate);
		tab_group.add(animationLoopPoint);
		tab_group.add(animationLoopCheckBox);
		tab_group.add(animationFlipXCheckBox);
		tab_group.add(animationFlipYCheckBox);
		tab_group.add(addUpdateButton);
		tab_group.add(removeButton);
		tab_group.add(autoFindButton);
		tab_group.add(flipAnimButton);
		// tab_group.add(optimButton);
		tab_group.add(removeAllButton);
		tab_group.add(removeMissingAnimsButton);
		tab_group.add(ghostDropDown);
		tab_group.add(animationDropDown);
		UI_characterbox.addGroup(tab_group);
		return tab_group;
	}

	override function getEvent(id:String, sender:Dynamic, data:Dynamic, ?params:Array<Dynamic>)
	{
		/*
			if (sender is FlxUIInputText || sender is FlxUICheckBox)
				sender.active = canPress;
			else if (sender is FlxUINumericStepper)
				sender.skipButtonUpdate = canPress;
		 */
		if (id == FlxUITabMenu.CLICK_EVENT && (sender is FlxUITabMenu))
		{
			if (sender == UI_characterbox)
			{
				switch(data)
				{
					case "Icon":
						UI_characterbox.resize(350, 570);
					default:
						UI_characterbox.resize(350, 250);
				}
			}
		}
		else if (id == FlxUIInputText.CHANGE_EVENT && (sender is FlxUIInputText))
		{
			if (sender == healthIconInputText)
			{
				leHealthIcon.changeIcon(healthIconInputText.text);
				char.healthIcon = healthIconInputText.text;
				updatePresence();
			}
			else if (sender == imageInputText)
			{
				char.imageFile = imageInputText.text;
			}
			else if(sender == characterDeathName
				|| sender == characterDeathSound
				|| sender == characterDeathConfirm
				|| sender == characterDeathMusic
				)
			{
				if (char.gameoverProperties == null)
				{
					char.gameoverProperties = new GameOverProperties(characterDeathName.text,
						characterDeathSound.text,
						characterDeathMusic.text,
						characterDeathConfirm.text,
						characterDeathMusicBPM.value
					);
				}
				else
				{
					char.gameoverProperties.char = characterDeathName.text;
					char.gameoverProperties.startSound = characterDeathSound.text;
					char.gameoverProperties.music = characterDeathMusic.text;
					char.gameoverProperties.confirmSound = characterDeathConfirm.text;
				}
			}
		}
		else if (id == FlxUINumericStepper.CHANGE_EVENT && (sender is FlxUINumericStepper))
		{
			if (sender == scaleStepper)
			{
				final factor = (sender.value - char.jsonScale) * (FlxG.keys.pressed.SHIFT ? 4 : 1); // 0.2 : 0.05
				sender.value = char.jsonScale += factor;
				ghostChar.scale.x = ghostChar.scale.y = char.scale.x = char.scale.y = char.jsonScale;
				// ghostDropDown.selectedLabel = '';
				// final lastGhostAnim:String = ghostDropDown.selectedLabel;
				// reloadCharacterImage(char.imageFile);
				// ghostChar.playAnim(ghostDropDown.selectedLabel = lastGhostAnim);
			}
			else if (sender == positionXStepper)
			{
				char.positionOffsets.x = positionXStepper.value;
				char.offset.x = -char.positionOffsets.x;
				updatePointerPos();
			}
			else if (sender == positionYStepper)
			{
				char.positionOffsets.y = positionYStepper.value;
				char.offset.y = -char.positionOffsets.y;
				updatePointerPos();
			}
			else if (sender == singDurationStepper)
			{
				char.singDuration = singDurationStepper.value; // ermm you forgot this??
			}
			else if (sender == numBeatDanceStepper)
			{
				char.danceEveryNumBeats = Std.int(numBeatDanceStepper.value);
			}
			else if (sender == positionCameraXStepper)
			{
				char.cameraPos.x = positionCameraXStepper.value;
				updatePointerPos();
			}
			else if (sender == positionCameraYStepper)
			{
				char.cameraPos.y = positionCameraYStepper.value;
				updatePointerPos();
			}
			else if(sender == characterDeathMusicBPM)
			{
				if (char.gameoverProperties == null)
				{
					char.gameoverProperties = new GameOverProperties(characterDeathName.text,
						characterDeathSound.text,
						characterDeathMusic.text,
						characterDeathConfirm.text,
						characterDeathMusicBPM.value
					);
				}
				else
				{
					char.gameoverProperties.bpm = characterDeathMusicBPM.value;
				}
			}
			/* else if(sender == healthColorStepperR){
					char.healthColorArray[0] = Math.round(healthColorStepperR.value);
					healthBar.color = FlxColor.fromRGB(char.healthColorArray[0], char.healthColorArray[1], char.healthColorArray[2]);
				}else if(sender == healthColorStepperG){
					char.healthColorArray[1] = Math.round(healthColorStepperG.value);
					healthBar.color = FlxColor.fromRGB(char.healthColorArray[0], char.healthColorArray[1], char.healthColorArray[2]);
				}else if(sender == healthColorStepperB){
					char.healthColorArray[2] = Math.round(healthColorStepperB.value);
					healthBar.color = FlxColor.fromRGB(char.healthColorArray[0], char.healthColorArray[1], char.healthColorArray[2]);
			}*/
		}
	}

	function reloadCharacterImage(file:String)
	{
		final lastAnim:String = char.curAnimName;
		// var oldImage:String = char.imageFile;
		try
		{
			char.imageFile = imageInputText.text = file;
			char.loadFrames(file);
			char.scale.set(char.jsonScale, char.jsonScale);
			char.updateHitbox();
			// char.getNameList();
		}
		catch (e)
		{
			// char.imageFile = imageInputText.text = oldImage;
			final resultStr = '[WARN] Error when loading an image.\n${e.details()}' /* + '\n\nIf you try to re-load image you get a crash lol.'*/;
			Log(resultStr, RED);
			lime.app.Application.current.window.alert(resultStr, 'Error!11111');
			return;
		}
		if (char.animationsArray != null && char.animationsArray.length > 0)
			for (anim in char.animationsArray)
			{
				char.addAnimation(anim.anim, anim.name, anim.indices, anim.offsets, anim.fps, anim.loopPoint, anim.loop == true, anim.flipX,
					anim.flipY);
			}
		else
			char.addAnimation('idle', 'BF idle dance');

		if (lastAnim == '' || !char.playAnim(lastAnim, true))
			char.dance();

		for (i in char.animationsArray)
		{
			final point = char.animOffsets[i.anim];
			if (point != null)
				i.offsets = [point.x, point.y];
		}
		reloadGhost();
		ghostDropDown.selectedLabel = '';
		updatePointerPos();

		char.playAnim(char.curAnimName, true);
	}

	final _getRecycleTxt:Void -> FlxStaticText = () -> {
		var text = new FlxStaticText();
		text.setFormat(null, 16, 0xFFB3B3B3, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		text.borderSize = 1;
		return text;
	}
	function genBoyOffsets():Void
	{
		// var i:Int = dumbTexts.members.length-1;
		// while(i >= 0) {
		// 	var memb:FlxStaticText = dumbTexts.members[i];
		// 	if(memb != null) {
		// 		memb.kill();
		// 		dumbTexts.remove(memb);
		// 		memb.destroy();
		// 	}
		// 	--i;
		// }
		dumbTexts.forEachAlive(spr -> spr.kill());

		final curAnimName:String = char.curAnimName;
		textAnim.visible = true;
		if (char.animationsArray.length < 1)
		{
			final text:FlxStaticText = dumbTexts.recycle(_getRecycleTxt);
			text.setPosition(10, 550);
			text.text = "ERROR! No animations found.";
			text.color = 0xFFC01010;
			textAnim.visible = false;
		}
		else
		{
			var text:FlxStaticText;
			for (i => anim in char.animationsArray)
			{
				text = dumbTexts.recycle(_getRecycleTxt);
				text.setPosition(10, 550 - 18 * (char.animationsArray.length - i - 1));

				text.text = '$i) ' + anim == null ? "NULL OBJECT REFERENCE" : (anim.anim
						+  ": [" + (anim.offsets == null ? "0, 0" : anim.offsets.join(", ")) + "]");

				text.scale.set(1, 1);
				if (anim == null)
					text.color = 0xFFFF0000;
				else if (anim.anim == curAnimName)
				{
					text.scale.scale(1.075);
					text.x += 4;
					text.color = (char.curAnimName == curAnimName ? 0xFFFFFFFF : 0xFFFF0000);
				}
				else
				{
					text.color = 0xFFFFFFFF;
				}
			}
		}
	}

	function loadChar(isDad:Bool, blahBlahBlah:Bool = true)
	{
		var charName = curCharacter.substr(0, curCharacter.length - 5);
		var prevAnim = char?.curAnimName;
		charLayer.forEach(spr -> spr.destroy());
		charLayer.clear();
		ghostChar = new Character(0, 0, charName, !isDad);
		ghostChar.debugMode = true;
		ghostChar.alpha = 0.6;

		char = new Character(0, 0, charName, !isDad);
		char.debugMode = true;
		char.showPivot = true;
		for (i in char.animationsArray)
		{
			final point = char.animOffsets[i.anim];
			if (point == null)
				continue;
			i.offsets = [point.x, point.y];
		}
		char.animationsArray = Character.sortAnims(char.animationsArray);
		if (prevAnim != null && !char.playAnim(prevAnim, true) && !char.playAnim("idle", true) && char.animationsArray[0] != null)
			char.playAnim(char.animationsArray[0].anim, true);

		charLayer.add(ghostChar);
		charLayer.add(char);

		char.offset.set(-char.positionOffsets.x, -char.positionOffsets.y);

		// if (textAnim != null)
		{
			curAnim = 0;
			final aaa:String = char.curAnimName;
			if (char.animationsArray.length > 0 && aaa != null)
			{
				for (i in 0...char.animationsArray.length)
				{
					if (char.animationsArray[i].anim == aaa)
					{
						curAnim = i;
						break;
					}
				}
			}
		}

		reloadCharacterOptions();
		reloadBGs();

		// char.playAnim(char.curAnimName, true);
		if (blahBlahBlah)
			genBoyOffsets();
	}

	function updatePointerPos()
	{
		char.updateFlip();
		var point = char.getCameraPosition();
		cameraFollowPointer.setPosition(point.x + (char.isPlayer ? -100 : 150) - cameraFollowPointer.width / 2, point.y - cameraFollowPointer.height / 2 - 100);
	}

	function findAnimationByName(name:String):AnimArray
	{
		for (anim in char.animationsArray)
			if (anim.anim == name)
				return anim;
		return null;
	}

	function reloadCharacterOptions()
	{
		if (UI_characterbox == null) return;

		imageInputText.text = char.imageFile;
		healthIconInputText.text = char.healthIcon;
		singDurationStepper.value = char.singDuration;
		numBeatDanceStepper.value = char.danceEveryNumBeats;

		fixFlipCheckBox.checked = char.fixFlip;
		flipXCheckBox.checked = char.originalFlipX;
		flipYCheckBox.checked = char.originalFlipY;
		noAntialiasingCheckBox.checked = char.noAntialiasing;
		resetHealthBarColor();
		colorPicker.defaultColor = char.healthColor;
		leHealthIcon.changeIcon(healthIconInputText.text);
		// noAntialiasingIconCheckBox.checked = !leHealthIcon.antialiasing;
		positionXStepper.value = char.positionArray[0];
		positionYStepper.value = char.positionArray[1];
		positionCameraXStepper.value = char.cameraPosition[0];
		positionCameraYStepper.value = char.cameraPosition[1];
		characterDeathName.text = char.gameoverProperties?.char ?? "bf-dead";
		characterDeathSound.text = char.gameoverProperties?.startSound ?? "fnf_loss_sfx";
		characterDeathConfirm.text = char.gameoverProperties?.confirmSound ?? "gameOverEnd";
		characterDeathMusic.text = char.gameoverProperties?.music ?? "gameOver";
		characterDeathMusicBPM.value = char.gameoverProperties?.bpm ?? 100;
		reloadAnimationDropDown();
		scaleStepper.value = char.jsonScale;
		// reloadCharacterImage(char.imageFile);
		updatePresence();
		// animationInputText.text =
		// addUpdateButton.onUp.fire();
	}

	function reloadAnimationDropDown()
	{
		char.animationsArray = Character.sortAnims(char.animationsArray);
		var anims:Array<String> = [];
		var ghostAnims:Array<String> = [''];
		for (anim in char.animationsArray)
		{
			anims.push(anim.anim);
			ghostAnims.push(anim.anim);
		}
		if (anims.length < 1)
			anims.push('NO ANIMATIONS'); // Prevents crash

		animationDropDown.setData(FlxUIDropDownMenuCustom.makeStrIdLabelArray(anims, true));
		ghostDropDown.setData(FlxUIDropDownMenuCustom.makeStrIdLabelArray(ghostAnims, true));
		reloadGhost();
	}

	function reloadGhost()
	{
		for (anim in ghostChar.animationsArray)
			ghostChar.removeAnimation(anim.anim);
		ghostChar.animationsArray.clear();
		ghostChar.imageFile = char.imageFile;
		ghostChar.loadFrames(ghostChar.imageFile);
		ghostChar.scale.copyFrom(char.scale);
		ghostChar.updateHitbox();
		for (anim in char.animationsArray)
			ghostChar.addAnimation(anim.anim, anim.name, anim.indices, anim.offsets, anim.fps, anim.loopPoint, anim.loop, anim.flipX, anim.flipY);

		// trace(ghostChar.animation.getNameList());
		char.alpha = 0.85;
		ghostChar.visible = true;

		if (ghostDropDown.selectedLabel.length < 1)
		{
			ghostChar.visible = false;
			char.alpha = 1;
		}

		ghostChar.color = 0xFF666688;
		ghostChar.antialiasing = char.antialiasing;
	}

	function reloadCharacterDropDown()
	{
		characterList.clear();
		final a = AssetsPaths.getFolderContent('characters', false);
		a.reverse();
		for (file in a)
			if (file.endsWith('.json') && !characterList.contains(file))
				characterList.push(file);

		charDropDown.setData(FlxUIDropDownMenuCustom.makeStrIdLabelArray(characterList, true));
		charDropDown.selectedLabel = curCharacter;
	}

	function resetHealthBarColor()
	{
		// healthColorStepperR.value = char.healthColorArray[0];
		// healthColorStepperG.value = char.healthColorArray[1];
		// healthColorStepperB.value = char.healthColorArray[2];
		updateHealthBarColor();
		colorPicker.updateColors();
	}
	function updateHealthBarColor()
	{
		healthBar.setColors(char.healthColor.getInverted(), char.healthColor);
	}
	function recreateIcon()
	{
		if (healthBar == null) return;
		var oldIndex = members.length;
		if (leHealthIcon != null)
		{
			oldIndex = members.indexOf(leHealthIcon);
			remove(leHealthIcon);
			leHealthIcon.destroy();
		}

		var isPlayer = check_player?.checked ?? char.isPlayer;

		leHealthIcon = new HealthIcon(char.healthIcon, isPlayer, false);
		insert(oldIndex, leHealthIcon);
		leHealthIcon.y = FlxG.height - 150;
		leHealthIcon.cameras = [camHUD];
		leHealthIcon.updateHealth(50);
	}

	function updatePresence()
	{
		#if DISCORD_RPC
		// Updating Discord Rich Presence
		DiscordClient.changePresence("Character Editor", "Character: " + curCharacter, {smallImage: leHealthIcon.getCharacter()});
		#end
	}

	var dragChar:Bool = false;
	var dragUmm:Bool = false;
	var curCursor:String = "";
	var _pressedTimer:Float;
	var _doPressedSkipFrames:Bool;

	var goback:Bool = false;
	var mousePos:FlxPoint = new FlxPoint();

	override function update(elapsed:Float)
	{
		FlxG.mouse.getScreenPosition(camHUD, mousePos);
		curCursor = "";
		if (overlapedBar)
		{
			if (FlxG.sound.keysAllowed && !FlxG.mouse.justReleased)
			{
				if (FlxG.mouse.pressed)
				{
					healthPercent = (mousePos.x - healthBar.leftBar.x) / healthBar.barWidth;
					if (!healthBar.flipped)
					{
						healthPercent = 1.0 - healthPercent;
					}
				}
				curCursor = "button";
			}
			else
			{
				overlapedBar = false;
			}
		}
		if (!overlapedBar && !goback && FlxG.sound.keysAllowed)
		{
			// for (i in [animationInputText, imageInputText, healthIconInputText, animationNameInputText, animationIndicesInputText])
			// 	if(i.hasFocus){
			// 		if(FlxG.keys.pressed.CONTROL && FlxG.keys.justPressed.V && Clipboard.text != null) { //Copy paste
			// 			i.text = ClipboardAdd(i.text);
			// 			i.caretIndex = i.text.length;
			// 			getEvent(FlxUIInputText.CHANGE_EVENT, i, null, []);
			// 		}

			// 		if(FlxG.keys.justPressed.ENTER) i.hasFocus = false;

			// 		super.update(elapsed);
			// 		return;
			// 	}

			if (FlxG.keys.justPressed.ESCAPE)
			{
				goback = true;
				if (goToPlayState)
				{
					MusicBeatState.switchState(new game.states.playstate.PlayState());
				}
				else
				{
					// game.states.MainMenuState.playMusic(Paths.music('freakyMenu'));
					MusicBeatState.switchState(new MasterEditorMenu());
				}
				FlxG.mouse.visible = false;
				return;
			}

			if (FlxG.keys.justPressed.TAB)
			{
				camHUD.visible = !camHUD.visible;
				// UI_box.skipButtonUpdate = UI_characterbox.skipButtonUpdate = !camHUD.visible;
				// for (i in [UI_box, UI_characterbox]) i.forEachOfType(flixel.addons.ui.interfaces.IFlxUIClickable, (i) -> {
				// 	cast(i, FlxSprite).active = camHUD.visible;
				// });
			}

			if (FlxG.keys.justPressed.R && !ColorPickerGroup.pointerOverlaps(colorPicker))
				FlxG.camera.zoom = 1;

			final pressedE = FlxG.keys.pressed.E;
			final pressedQ = FlxG.keys.pressed.Q;
			if (pressedE && FlxG.camera.zoom < 25)
				FlxG.camera.zoom += elapsed * FlxG.camera.zoom;
			else if (pressedQ && FlxG.camera.zoom > 0.005)
				FlxG.camera.zoom -= elapsed * FlxG.camera.zoom;

			final notOnBox = !camHUD.visible || (
				mousePos.x < UI_characterbox.x
				|| mousePos.x > UI_characterbox.x + UI_characterbox.width
				|| mousePos.y < UI_box.y
				|| mousePos.y > UI_box.y + UI_box.height + UI_characterbox.height
			);

			final factor = FlxG.keys.pressed.SHIFT ? 10 : 25;
			if (FlxG.mouse.wheel != 0)
				FlxG.camera.zoom = CoolUtil.boundTo(FlxG.camera.zoom + FlxG.mouse.wheel / factor * FlxG.camera.zoom, 0.005, 25);
			if ((pressedE != pressedQ || FlxG.mouse.wheel != 0) && FlxG.camera.zoom > 0.005 && FlxG.camera.zoom < 25)
			{
				mousePos.set((FlxG.width / 2 - mousePos.x) / FlxG.camera.zoom, (FlxG.height / 2 - mousePos.y) / FlxG.camera.zoom);
				FlxG.camera.scroll.x -= FlxG.mouse.wheel * mousePos.x / factor;
				FlxG.camera.scroll.y -= FlxG.mouse.wheel * mousePos.y / factor;
				if (pressedE != pressedQ)
				{
					if (pressedQ)
					{
						FlxG.camera.scroll.x += elapsed * mousePos.x;
						FlxG.camera.scroll.y += elapsed * mousePos.y;
					}
					else
					{
						FlxG.camera.scroll.x -= elapsed * mousePos.x;
						FlxG.camera.scroll.y -= elapsed * mousePos.y;
					}
				}
			}
			// if (FlxG.keys.justPressed.P){
			// 	updatePreview();
			// }
			/*if (FlxG.keys.pressed.I || FlxG.keys.pressed.J || FlxG.keys.pressed.K || FlxG.keys.pressed.L){
				var addToCam:Float = 500 * elapsed;
				if (FlxG.keys.pressed.SHIFT)
					addToCam *= 4;

				if (FlxG.keys.pressed.I)
					FlxG.camera.scroll.y -= addToCam;
				else if (FlxG.keys.pressed.K)
					FlxG.camera.scroll.y += addToCam;

				if (FlxG.keys.pressed.J)
					FlxG.camera.scroll.x -= addToCam;
				else if (FlxG.keys.pressed.L)
					FlxG.camera.scroll.x += addToCam;
			}else*/

			final pressedRight = FlxG.mouse.pressedRight;
			final pressedMiddle = FlxG.mouse.pressedMiddle;
			final pressedLeft = FlxG.mouse.pressed;

			if (pressedMiddle && !pressedRight && (notOnBox || dragUmm))
			{
				FlxG.camera.scroll.x -= FlxG.mouse.deltaScreenX;
				FlxG.camera.scroll.y -= FlxG.mouse.deltaScreenY;
				curCursor = 'hand';
				if (FlxG.mouse.justPressedMiddle)
					dragUmm = true;
			}
			else if (pressedRight && (notOnBox || dragUmm))
			{
				if (FlxG.mouse.justMoved)
				{
					final factor:Float = (FlxG.keys.pressed.SHIFT ? .2 : 1);
					if (pressedMiddle)
					{
						char.cameraPos.x = positionCameraXStepper.value += FlxG.mouse.deltaScreenX * (check_player.checked || char.altFlipX ? -factor : factor);
						char.cameraPos.y = positionCameraYStepper.value += FlxG.mouse.deltaScreenY * factor;
					}
					else
					{
						positionXStepper.value = char.positionOffsets.x += FlxG.mouse.deltaScreenX * (factor);
						positionYStepper.value = char.positionOffsets.y += FlxG.mouse.deltaScreenY * factor;
					}
					updatePointerPos();
				}
				if (FlxG.mouse.justPressedRight)
					dragUmm = true;
				curCursor = 'hand';
			}
			if (FlxG.mouse.justReleasedRight && dragUmm)
			{
				char.cameraPos.x = positionCameraXStepper.value = FlxMath.roundDecimal(char.cameraPos.x, 2);
				char.cameraPos.y = positionCameraYStepper.value = FlxMath.roundDecimal(char.cameraPos.y, 2);
				char.positionOffsets.x = positionXStepper.value = FlxMath.roundDecimal(char.positionOffsets.x, 2);
				char.positionOffsets.y = positionYStepper.value = FlxMath.roundDecimal(char.positionOffsets.y, 2);
				dragUmm = false;
				updatePointerPos();
			}
			if (char.animationsArray.length > 0)
			{
				final jpW = FlxG.keys.justPressed.W;
				final jpS = FlxG.keys.justPressed.S;
				if ((jpW || jpS) && !pressedLeft)
				{
					if (jpW)
						curAnim--;
					else
						curAnim++;

					curAnim = FlxMath.wrap(curAnim, 0, char.animationsArray.length - 1);
					char.playAnim(char.animationsArray[curAnim].anim, true);
					genBoyOffsets();
				}
				if (FlxG.keys.justPressed.SPACE)
				{
					// genBoyOffsets();
					char.playAnim(char.animationsArray[curAnim].anim, true);
				}

				if (FlxG.keys.justPressed.T)
				{
					var anim = char.animationsArray[curAnim];
					anim.offsets = [0, 0];

					char.addOffset(anim.anim);
					ghostChar.addOffset(anim.anim);
					genBoyOffsets();
					playAnim();
				}
				if (pressedLeft && (notOnBox || dragChar) && !colorPicker.pressed)
				{
					if (!pressedMiddle)
					{
						if (FlxG.mouse.justMoved)
						{
							var anim = char.animationsArray[curAnim];
							/*if (anim == null){
								anim = {
									anim: animationInputText.text,
									name: animationNameInputText.text,
									fps: FlxMath.roundDecimal(animationNameFramerate.value, 2),
									loop: animationLoopCheckBox.checked,
									loopPoint: Std.int(animationLoopPoint.value),
									flipX: animationFlipXCheckBox.checked,
									flipY: animationFlipYCheckBox.checked,
									offsets: [0, 0]
								};
								ghostChar.animationsArray[curAnim] = anim;
								char.addOffset(char.curAnimName);
								ghostChar.addOffset(char.curAnimName);
							}else*/
							if (anim.offsets == null || anim.offsets.length <= 1)
							{
								char.addOffset(char.curAnimName);
								ghostChar.addOffset(char.curAnimName);
								anim.offsets = [0, 0];
								// playAnim();
								char.updateAnimOffsets();
								ghostChar.updateAnimOffsets();
							}
							final factor:Float = (FlxG.keys.pressed.SHIFT ? .2 : 1);
							anim.offsets[0] -= FlxG.mouse.deltaScreenX * (char.fixFlip && check_player.checked ? -factor : factor);
							anim.offsets[1] -= FlxG.mouse.deltaScreenY * factor;

							char.addOffset(anim.anim, anim.offsets[0], anim.offsets[1]);
							ghostChar.addOffset(anim.anim, anim.offsets[0], anim.offsets[1]);

							// if (char.curAnimName == anim.anim)
							// {
							// 	char.__drawingOffset.set(anim.offsets[0], anim.offsets[1]);
							// 	if (anim.anim == ghostChar.curAnimName)
							// 	{
							// 		ghostChar.__drawingOffset.copyFrom(char.__drawingOffset);
							// 	}
							// }
							// playAnim();
						}
						dragChar = true;
						curCursor = 'button';
					}
				}
				else
				{
					for (i => key in [
						FlxG.keys.justPressed.LEFT,
						FlxG.keys.justPressed.RIGHT,
						FlxG.keys.justPressed.UP,
						FlxG.keys.justPressed.DOWN
					])
						if (key)
						{
							safeOffsets();
							char.animationsArray[curAnim].offsets[i > 1 ? 1 : 0] += (i % 2 == 1 ? -1 : 1) * (FlxG.keys.pressed.SHIFT ? 10 : 1);
							updateGhostAndOffsets();
						}
				}
				if (FlxG.mouse.justReleased && dragChar)
				{
					dragChar = false;
					// curCursor = ('crosshair');
					updateGhostAndOffsets();
				}
				var prZ = FlxG.keys.pressed.Z;
				var prX = FlxG.keys.pressed.X;

				if (prZ || prX)
				{
					if (char.useAtlas || char.animation.getByName(char.curAnimName) != null)
					{ // like in flash!!! :D
						if (!char.pausedAnim)
							char.pauseAnimation();
						var add:Int = 0;
						if (FlxG.keys.justPressed.Z)
							add--;
						else if (FlxG.keys.justPressed.X)
							add++;
						if (prZ || prX)
						{
							_pressedTimer += elapsed;
							if (_pressedTimer > 0.5) _doPressedSkipFrames = true;
						}
						if (_doPressedSkipFrames
							&& _pressedTimer > (FlxG.keys.pressed.SHIFT ? 0.5 : 1)
								/ (char.useAtlas ? char.animateAtlas.anim.framerate : char.animation.curAnim.frameRate )
						)
						{
							if (prZ)
								add--;
							else if (prX)
								add++;
							_pressedTimer = 0;
						}
						else if (FlxG.keys.pressed.SHIFT)
						{
							add *= 4;
						}
						char.curFrame = Std.int(FlxMath.wrap(char.curFrame + add, 0, char.curNumFrames - 1));
						if (ghostChar.visible && ghostChar.curAnimName == char.curAnimName)
							ghostChar.curFrame = char.curFrame;
					}
				}
				else
				{
					_pressedTimer = 0;
					_doPressedSkipFrames = false;
				}
			}
			else if (!dragUmm)
				curCursor = (pressedMiddle ? 'hand' : '');
		}
		/*else
			for (i in [animationInputText, imageInputText, healthIconInputText, animationNameInputText, animationIndicesInputText])
				i.hasFocus = false; */
		// camHUD.zoom = FlxG.camera.zoom;
		char.offset.set(-char.positionOffsets.x, -char.positionOffsets.y);
		ghostChar.setPosition(char.x, char.y);
		ghostChar.offset.set(char.offset.x, char.offset.y);
		updateCurAnimText();
		var isPlayer = check_player?.checked ?? char.isPlayer;
		var xPos:Float;
		if (isPlayer)
			xPos = healthBar.x + healthBar.width - 75; // 150 / 2
		else
			xPos = -15;
		leHealthIcon.x = xPos;
		healthBar.flipped = !isPlayer;
		leHealthIcon.updatePsych();
		leHealthIcon.updateHealth(Math.floor((
			healthPercent
		) * 100));
		CursorManager.instance.cursor = curCursor;
		super.update(elapsed);
	}

	function updateCurAnimText()
	{
		if (char.animationsArray[curAnim] != null)
		{
			var neededAnim = char.animationsArray[curAnim];
			textAnim.text = neededAnim.anim;
			final notsameAnim = (char.curAnimName != textAnim.text);
			if (char.curNumFrames < 0 || notsameAnim)
				textAnim.text += ' (ERROR!)';
			final txtFrame:String = (char.curFrame != -1 || notsameAnim ? '[${char.curFrame}/${char.curNumFrames - 1}]' : 'null');
			textAnim.text += '\nCurrent Frame: $txtFrame';
		}
		else
			textAnim.text = '';
	}

	function playAnim(forse:Bool = false)
	{
		final _curAnim = char.animation.getByName(char.curAnimName);
		var anim = char.animationsArray[curAnim];
		if (forse || _curAnim != null && !_curAnim.paused)
		{
			char.playAnim(anim?.anim ?? char.curAnimName, false);
			if (char.curAnimName == ghostChar.curAnimName)
				ghostChar.playAnim(char.curAnimName, false);
		}
		else if (anim != null && anim.offsets != null)
		{
			char.__drawingOffset.set(anim.offsets[0], anim.offsets[1]);
			if (char.curAnimName == ghostChar.curAnimName)
				ghostChar.__drawingOffset.set(char.__drawingOffset.x, char.__drawingOffset.y);
		}
	}

	function safeOffsets() // : ) 🔥🔥🔥🔥
	{
		var anim = char.animationsArray[curAnim];
		if (anim == null || anim.offsets == null || anim.offsets.length <= 1)
		{
			char.addOffset(char.curAnimName);
			ghostChar.addOffset(char.curAnimName);
			if (anim != null)
			{
				if (anim.offsets == null)
					anim.offsets = [];
				anim.offsets[0] = char.__drawingOffset.x;
				anim.offsets[1] = char.__drawingOffset.y;
			}
		}
	}

	function updateGhostAndOffsets()
	{
		final _curAnim = char.animation.getByName(char.curAnimName);
		var anim = char.animationsArray[curAnim];
		if (anim == null || anim.offsets == null || anim.offsets.length <= 1)
		{
			char.addOffset(char.curAnimName);
			ghostChar.addOffset(char.curAnimName);
			var anim = anim;
			if (_curAnim != null && !_curAnim.paused)
			{
				char.playAnim(char.curAnimName, false);
				if (char.curAnimName == ghostChar.curAnimName)
					ghostChar.playAnim(char.curAnimName, false);
			}
			else if (anim != null && anim.offsets != null)
			{
				char.__drawingOffset.set(anim.offsets[0], anim.offsets[1]);
				if (char.curAnimName == ghostChar.curAnimName)
					ghostChar.__drawingOffset.set(char.__drawingOffset.x, char.__drawingOffset.y);
			}
			return;
		}
		final x = anim.offsets[0] = FlxMath.roundDecimal(anim.offsets[0], 2);
		final y = anim.offsets[1] = FlxMath.roundDecimal(anim.offsets[1], 2);
		char.addOffset(anim.anim, x, y);
		ghostChar.addOffset(anim.anim, x, y);
		final _curAnim = char.animation.getByName(char.curAnimName);
		if (_curAnim != null && !_curAnim.paused)
		{
			char.playAnim(char.curAnimName, false);
			if (ghostChar.curAnimName != null && char.curAnimName == ghostChar.curAnimName)
				ghostChar.playAnim(char.curAnimName, false);
		}
		else if (anim != null && anim.offsets != null)
		{
			char.__drawingOffset.set(anim.offsets[0], anim.offsets[1]);
			if (char.curAnimName == ghostChar.curAnimName)
				ghostChar.__drawingOffset.set(char.__drawingOffset.x, char.__drawingOffset.y);
		}
		genBoyOffsets();
	}

	function updatePreview()
	{
	}

	function saveCharacter()
	{
		var data:String = Json.stringify(char.getJson(), optimizeJsonBox.checked ? null : "\t").trim();
		if (data.length > 0)
		{
			var savePath = FileUtil.getPathFromCurrentRoot([
				"characters",
				char.curCharacter + '.json'
			]);
			trace("open in " + savePath);
			FileUtil.browseForSaveFile([FileUtil.FILE_FILTER_JSON],
				path -> {
					#if sys
					sys.io.File.saveContent(path, data);
					#end
					FlxG.log.notice("Successfully saved file.");
				},
				() -> FlxG.log.error("Problem saving file"),
				savePath,
				'Save "${char.curCharacter}"');
		}
	}

	function ClipboardAdd(prefix:String = ''):String
	{
		if (prefix.toLowerCase().endsWith('v')) // probably copy paste attempt
			prefix = prefix.substring(0, prefix.length - 1);

		var text:String = prefix + Clipboard.text.replace('\n', '');
		return text;
	}
}
