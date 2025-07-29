package game.states.editors;

import game.backend.data.jsons.StageData;
import game.backend.system.song.*;
import game.backend.system.song.Conductor.BPMChangeEvent;
import game.backend.system.song.Conductor.mainInstance as Conductor;
import game.backend.system.song.Section.SwagSection;
import game.backend.system.song.Song.SwagSong;
import game.backend.system.states.MusicBeatState;
import game.backend.utils.ClientPrefs.showSaveStatus;
import game.backend.utils.Difficulty;
import game.backend.utils.Highscore;
import game.backend.utils.WindowUtil;
import game.objects.AttachedSprite;
import game.objects.FlxUIDropDownMenuCustom;
import game.objects.Prompt;
import game.objects.game.Character.CharacterFile;
import game.objects.game.Character;
import game.objects.game.HealthIcon;
import game.objects.game.notes.Note;
import game.objects.game.notes.StrumNote;
import game.states.editors.MasterEditorMenu;
import game.states.playstate.PlayState;

import flixel.addons.display.FlxGridOverlay;
import flixel.addons.ui.FlxUI;
import flixel.addons.ui.FlxUISlider;
import flixel.addons.ui.FlxUICheckBox;
import flixel.addons.ui.FlxInputText;
import flixel.addons.ui.FlxUIInputText;
import flixel.addons.ui.FlxUINumericStepper;
import flixel.addons.ui.FlxUITabMenu;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxGroup;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.system.FlxSound;
import flixel.system.FlxAssets;
import flixel.text.FlxText; // import inside objects
import flixel.util.FlxSave;

import game.objects.improvedFlixel.FlxFixedText;
import game.objects.FlxStaticText;

import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.ui.FlxButton;
import flixel.util.FlxColor;
import flixel.util.FlxStringUtil;
import flixel.util.FlxSort;

import haxe.format.JsonParser;
import haxe.io.Bytes;
import haxe.io.Path;
import haxe.Json;

import lime.utils.Assets;
import lime.media.AudioBuffer;

import openfl.events.Event;
import openfl.events.IOErrorEvent;
import openfl.media.Sound;
import openfl.net.FileReference;
import openfl.utils.ByteArray;
import openfl.utils.Assets as OpenFlAssets;
import openfl.display3D.textures.RectangleTexture;
import openfl.display.BitmapData;
import openfl.geom.Rectangle;

typedef LocalSongOption = {
	label:String,
	field:String,
	?callback:(FlxUIInputText, String, String) -> Void
}

@:access(flixel.sound.FlxSound._sound)
@:access(openfl.media.Sound.__buffer)
class ChartingState extends MusicBeatUIState
{
	// Used for backwards compatibility with 0.1 - 0.3.2 charts, though, you should add your hardcoded custom note types here too.
	public static var noteTypeList:Array<String> = ['', 'Alt Animation', 'Hey!', 'Hurt Note', 'GF Sing', 'No Animation'];

	private var noteTypeIntMap:Map<Int, String> = new Map<Int, String>();
	private var noteTypeMap:Map<String, Null<Int>> = new Map<String, Null<Int>>();

	public var ignoreWarnings = false;

	var eventStuff:Array<Array<String>> = [
		[
			'',
			"Nothing. Yep, that's right."
		],
		[
			'Hey!',
			"Plays the \"Hey!\" animation from Bopeebo,\nValue 1: BF = Only Boyfriend, GF = Only Girlfriend,\nSomething else = Both.\nValue 2: Custom animation duration,\nleave it blank for 0.6s"
		],
		[
			'Set GF Speed',
			"Sets GF head bopping speed,\nValue 1: 1 = Normal speed,\n2 = 1/2 speed, 4 = 1/4 speed etc.\nUsed on Fresh during the beatbox parts.\n\nWarning: Value must be integer!"
		],
		[
			'Kill Henchmen',
			"For Mom's songs, don't use this please, i love them :("
		],
		[
			'Add Camera Zoom',
			"Used on MILF on that one \"hard\" part\nValue 1: Camera zoom add (Default: 0.015)\nValue 2: UI zoom add (Default: 0.03)\nLeave the values blank if you want to use Default."
		],
		[
			'Play Animation',
			"Plays an animation on a Character,\nonce the animation is completed,\nthe animation changes to Idle\n\nValue 1: Animation to play.\nValue 2: Character (Dad, BF, GF)"
		],
		[
			'Camera Follow Pos',
			"Value 1: X\nValue 2: Y\n\nThe camera won't change the follow point\nafter using this, for getting it back\nto normal, leave both values blank."
		],
		[
			'Alt Idle Animation',
			"Sets a specified suffix after the idle animation name.\nYou can use this to trigger 'idle-alt' if you set\nValue 2 to -alt\n\nValue 1: Character to set (Dad, BF or GF)\nValue 2: New suffix (Leave it blank to disable)"
		],
		[
			'Screen Shake',
			"Value 1: Camera shake\nValue 2: HUD shake\n\nEvery value works as the following example: \"1, 0.05\".\nThe first number (1) is the duration.\nThe second number (0.05) is the intensity."
		],
		[
			'Change Character',
			"Value 1: Character to change (Dad, BF, GF)\nValue 2: New character's name"
		],
		[
			'Change Scroll Speed',
			"Value 1: Scroll Speed Multiplier (1 is default)\nValue 2: Time it takes to change fully in seconds."
		],
		['Set Property',		"Value 1: Variable name\nValue 2: New value"],
		['Flash New',			"Value 1: Time"],
		['Setting Camera Zoom', "Value 1: Cam Zooming Frequency\nValue 2: Cam Zooming Offset"],
		['Switch Hud',			"Value 1: hud name"],
		['Beat Icons',			"Value 1: Freq\nIf the value is empty, the Beat event will simply be executed."],
		['Run Haxe Code',		""],
		['',					"Nothing. Yep, that's right."]
	];

	var UI_box:FlxUITabMenu;

	public static var goToPlayState:Bool = false;
	public static var botPlayChartMod:Bool = false;

	/**
	 * Array of notes showing when each section STARTS in STEPS
	 * Usually rounded up??
	 */
	public static var curSec:Int = 0;

	public static var lastSection:Int = 0;
	private static var lastSong:String = '';

	var bpmTxt:FlxStaticText;

	var camPos:FlxObject;
	var strumLine:FlxSprite;
	var strumLineNotes:FlxTypedGroup<StrumNote>;
	var curSong:String = 'Test';
	var amountSteps:Int = 0;

	var highlight:FlxSprite;

	public static final GRID_SIZE:Int = 40;

	static final CAM_OFFSET:Int = 360;

	var dummyArrow:FlxSprite;

	var curRenderedSustains:FlxTypedGroup<FlxSprite>;
	var curRenderedNotes:FlxTypedGroup<EditorNote>;
	var curRenderedNoteType:FlxTypedGroup<AttachedFlxText>;

	var nextRenderedSustains:FlxTypedGroup<FlxSprite>;
	var nextRenderedNotes:FlxTypedGroup<EditorNote>;

	var gridBG:FlxSprite;
	var nextGridBG:FlxSprite;

	var daquantspot = 0;
	var curEventSelected:Int = 0;
	var curUndoIndex = 0;
	var curRedoIndex = 0;
	var _song:Song;
	/*
	 * WILL BE THE CURRENT / LAST PLACED NOTE
	**/
	var curSelectedNote:Array<Dynamic> = null;

	var playbackSpeed:Float = 1;

	var tempBpm:Float = 0;

	var vocal:FlxSound;
	var vocalBF:FlxSound;

	var vocals:Array<FlxSound> = [];

	var leftIcon:HealthIcon;
	var rightIcon:HealthIcon;

	var value1InputText:ColorfullInputText;
	var value2InputText:ColorfullInputText;
	var value3InputText:ColorfullInputText;
	var currentSongName:String;

	var zoomTxt:FlxStaticText;

	static final zoomList:Array<Float> = [0.25, 0.5, 1, 2, 3, 4, 6, 8, 12, 16, 24];
	var curZoom:Int = 2;

	private var blockPressWhileTypingOn:Array<FlxUIInputText> = [];
	private var blockPressWhileTypingOnStepper:Array<FlxUINumericStepper> = [];
	private var blockPressWhileScrolling:Array<FlxUIDropDownMenuCustom> = [];

	var timeBar:FlxSprite;
	var waveformInstSprite:FlxSprite;
	var waveformBoyfriendSprite:FlxSprite;
	var waveformDadSprite:FlxSprite;
	var waveformVoicesSprite:FlxSprite;
	var blackLinesLayer:FlxTypedGroup<FlxSprite>;
	var gridLayer:FlxTypedGroup<FlxSprite>;

	public static var quantization:Int = 16;
	public static var curQuant = 3;

	public static final quantizations:Array<Int> = [4, 8, 12, 16, 20, 24, 32, 48, 64, 96, 192];

	public static var vortex:Bool = false;

	public var mouseQuant:Bool = false;

	var save = game.backend.utils.ClientPrefs.editorsSave;
	var blockInput:Bool = false;
	var listOfInput:Array<FlxUIInputText> = [];

	public function new(){
		super(false);
	}

	override function create()
	{
		preGPUCashing = ClientPrefs.cacheOnGPU;
		ClientPrefs.cacheOnGPU = false;
		// Default options
		save.data.voices_volume ??= 1;
		save.data.voicebf_volume ??= 1;
		save.data.voiceDad_volume ??= 1;
		save.data.inst_volume ??= 0.6;
		save.data.pressbf_volume ??= 0.5;
		save.data.pressDad_volume ??= 0.5;

		_song = PlayState.SONG;
		if (_song == null)
		{
			// CoolUtil.difficulties = CoolUtil.defaultDifficulties.copy();
			_song = new Song(Song.getTemplateSong());
			addSection();
			PlayState.SONG = _song;
		}
		if (_song.arrowSkin == null || _song.arrowSkin.length < 1 || Paths.image('game/ui/notes/${_song.arrowSkin}') == null)
		{
			trace("Note skin " + _song.arrowSkin + " doesn't exits.");
			_song.arrowSkin = Constants.DEFAULT_NOTE_SKIN;
		}
		botPlayChartMod = false;
		// Paths.clearMemory();
		#if DISCORD_RPC
		// Updating Discord Rich Presence
		DiscordClient.changePresence("Chart Editor", _song.display);
		#end

		vortex = save.data.chart_vortex;
		ignoreWarnings = save.data.ignoreWarnings;
		var bg:FlxSprite = new FlxSprite(Paths.image('menuDesat'));
		bg.scrollFactor.set();
		bg.color = 0xFF222222;
		add(bg);

		gridLayer = new FlxTypedGroup<FlxSprite>();
		add(gridLayer);
		blackLinesLayer = new FlxTypedGroup<FlxSprite>();
		add(blackLinesLayer);
		var gridBlackLine:FlxSprite = new FlxSprite(GRID_SIZE * 5).makeGraphic(2, 1, FlxColor.BLACK);
		gridBlackLine.origin.y = 0;
		blackLinesLayer.add(gridBlackLine);
		gridBlackLine = new FlxSprite(GRID_SIZE).makeGraphic(2, 1, FlxColor.BLACK);
		gridBlackLine.origin.y = 0;
		blackLinesLayer.add(gridBlackLine);

		waveformInstSprite = new FlxSprite(GRID_SIZE, 0).makeGraphic(1, 1, 0x00FFFFFF);
		add(waveformInstSprite);
		waveformBoyfriendSprite = new FlxSprite(GRID_SIZE, 0).makeGraphic(1, 1, 0x00FFFFFF);
		add(waveformBoyfriendSprite);
		waveformDadSprite = new FlxSprite(GRID_SIZE, 0).makeGraphic(1, 1, 0x00FFFFFF);
		add(waveformDadSprite);
		waveformVoicesSprite = new FlxSprite(GRID_SIZE, 0).makeGraphic(1, 1, 0x00FFFFFF);
		add(waveformVoicesSprite);

		var eventIcon:FlxSprite = new FlxSprite(-GRID_SIZE - 5, -90, Paths.image('eventArrow'));
		leftIcon = new HealthIcon('bf');
		rightIcon = new HealthIcon('dad');
		eventIcon.scrollFactor.set(1, 1);
		leftIcon.scrollFactor.set(1, 1);
		rightIcon.scrollFactor.set(1, 1);

		eventIcon.setGraphicSize(30, 30);
		// leftIcon.setGraphicSize(0, 45);
		// rightIcon.setGraphicSize(0, 45);

		add(eventIcon);
		add(leftIcon);
		add(rightIcon);

		leftIcon.setPosition(GRID_SIZE + 10, -120);
		rightIcon.setPosition(GRID_SIZE * 5.2, -120);

		curRenderedSustains = new FlxTypedGroup<FlxSprite>();
		curRenderedNotes = new FlxTypedGroup<EditorNote>();
		curRenderedNoteType = new FlxTypedGroup<AttachedFlxText>();

		nextRenderedSustains = new FlxTypedGroup<FlxSprite>();
		nextRenderedNotes = new FlxTypedGroup<EditorNote>();

		if (_song.notes == null || _song.notes.length < 2)
		{
			addSection();
			addSection();
		}

		if (curSec >= _song.notes.length)
			curSec = _song.notes.length - 1;

		FlxG.mouse.visible = true;
		// save.bind('funkin', 'ninjamuffin99');

		tempBpm = _song.bpm;

		// sections = _song.notes;

		currentSongName = Paths.formatToSongPath(_song.song);
		loadSong();
		reloadGridLayer();
		Conductor.bpm = _song.bpm;
		Conductor.mapBPMChanges(_song);

		strumLine = new FlxSprite(0, 50).makeGraphic(Std.int(GRID_SIZE * 9), 4);
		add(strumLine);

		strumLineNotes = new FlxTypedGroup<StrumNote>();
		for (i in 0...8){
			var note:StrumNote = new StrumNote(0, strumLine.y, i % 4, i >= 4, 0);
			note.playAnim('static', true);
			note.setGraphicSize(GRID_SIZE, GRID_SIZE);
			note.updateHitbox();
			strumLineNotes.add(note);
			note.scrollFactor.set(1, 1);
		}
		add(strumLineNotes);

		camPos = new FlxObject(0, 0, 1, 1);
		camPos.setPosition(strumLine.x + CAM_OFFSET, strumLine.y);

		dummyArrow = new FlxSprite().makeGraphic(GRID_SIZE, GRID_SIZE);
		add(dummyArrow);

		UI_box = new FlxUITabMenu(null, [
			{name: "Song", label: 'Song'},
			{name: "Section", label: 'Section'},
			{name: "Note", label: 'Note'},
			{name: "Events", label: 'Events'},
			{name: "Charting", label: 'Charting'},
			{name: "Properties", label: 'Properties'},
		], true);

		UI_box.resize(300, 420);
		UI_box.x = FlxG.width / 2 + GRID_SIZE / 2;
		UI_box.y = 25;
		UI_box.scrollFactor.set();

		bpmTxt = new FlxStaticText(UI_box.x + UI_box.width + 20, UI_box.y + 25, 0, "", 16);
		bpmTxt.scrollFactor.set();
		add(bpmTxt);

		var tipText:FlxStaticText = new FlxStaticText(UI_box.x, 0, 0, "
		W/S or Mouse Wheel - Change Conductor's strum time
		A/D - Go to the previous/next section
		O/P - Change Snap
		Up/Down - Change Conductor's Strum Time with Snapping
		Hold Shift to move 4x faster
		Left Bracket / Right Bracket - Change Song Playback Rate (SHIFT to go Faster)
		ALT + Left Bracket / Right Bracket - Reset Song Playback Rate
		Hold Control and click on an arrow to select it
		Z/X - Zoom in/out
		N - Flip Cur Section (Grafex thing)
		Enter - Play your chart
		Q/E - Decrease/Increase Note Sustain Length
		Space - Stop/Resume song", 8);
		tipText.setFormat(null, 8, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE_FAST, FlxColor.BLACK);
		// tipText.borderSize = 2;
		tipText.scrollFactor.set();
		tipText.y = FlxG.height - tipText.height - 15;
		add(tipText);
		add(UI_box);

		addSongUI();
		addSectionUI();
		addNoteUI();
		addEventsUI();
		addChartingUI();
		addPropertiesUI();
		updateChars();
		updateWaveform();
		// UI_box.selected_tab = 4;

		add(curRenderedSustains);
		add(curRenderedNotes);
		add(curRenderedNoteType);
		add(nextRenderedSustains);
		add(nextRenderedNotes);

		if (lastSong != currentSongName) changeSection();
		lastSong = currentSongName;

		zoomTxt = new FlxStaticText(10, 10, 0, "Zoom: 1 / 1", 16);
		zoomTxt.scrollFactor.set();
		zoomTxt.y = FlxG.height - zoomTxt.height - 10;
		add(zoomTxt);

		updateGrid();
		super.create();
		updateInfoText();
		lime.app.Application.current.window.onDropFile.add(LoadFromFile);

		listOfInput = blockPressWhileTypingOn.concat(cast blockPressWhileTypingOnStepper).filter(i -> return i != null);

		blockPressWhileScrolling = blockPressWhileScrolling.filter(i -> return i != null);
		for (i in blockPressWhileScrolling)
		{
			i.focusGained = () -> {
				for (j in listOfInput)				 j.active = false;
				for (j in blockPressWhileScrolling)	 j.active = false;
				i.active = true;
				FlxG.sound.keysAllowed = false;
			}
			i.focusLost = () -> {
				for (j in listOfInput)				 j.active = true;
				for (j in blockPressWhileScrolling)	 j.active = true;
				FlxG.sound.keysAllowed = true;
			}
		}
		/*
		listOfInput = blockPressWhileTypingOn.concat(cast blockPressWhileTypingOnStepper);

		listOfInput = listOfInput.filter(i -> return i != null);
		blockPressWhileScrolling = blockPressWhileScrolling.filter(i -> return i != null);
		for (i in listOfInput)
		{
			i.focusGained = () -> {
				for (j in listOfInput) j.active = false;
				i.active = true;
				FlxG.sound.keysAllowed = false;
			}
			var returnInput = () -> {
				for (j in listOfInput) j.active = true;
				FlxG.sound.keysAllowed = true;
			}
			i.focusLost = returnInput;
		}
		for (i in blockPressWhileScrolling)
		{
			i.focusGained = () -> {
				for (j in listOfInput)				 j.active = false;
				for (j in blockPressWhileScrolling)	 j.active = false;
				i.active = true;
				FlxG.sound.keysAllowed = false;
			}
			i.focusLost = () -> {
				for (j in listOfInput)				 j.active = true;
				for (j in blockPressWhileScrolling)	 j.active = true;
				FlxG.sound.keysAllowed = true;
			}
		}
		*/

		WindowUtil.endfix = ' - Charting Editor';
		// WindowUtils.preventClosing = true;
		// WindowUtil.onClosing = () -> {
		// 	openSubState(new SaveWarning());
		// };
		// lime.app.Application.current.window.onShow.add(function(){trace('geeee');});
		// lime.app.Application.current.window.mouseLock = true;
		// lime.app.Application.current.window.onMove.add(function(x:Float, y:Float){trace(x,y);});
		// lime.app.Application.current.window.onHide.add(function(){trace('HEY');});
	}
	function LoadFromFile(file:String){
		// try{
			var infoShit = DropFileUtil.getInfoPath(file, CHART);
			if (infoShit == null || ModsFolder.currentModFolder != infoShit.modFolder) return;

			// ModsFolder.currentModFolder = infoShit.modFolder;

			// ModsFolder.currentModFolder = '';
			loadJson(file, true);
		// }
	}

	var check_mute_inst:FlxUICheckBox = null;
	var check_mute_vocals:FlxUICheckBox = null;
	var check_enable_voiceDadVolume:FlxUICheckBox = null;
	var check_enable_voiceBFVolume:FlxUICheckBox = null;
	var check_vortex:FlxUICheckBox = null;
	var check_warnings:FlxUICheckBox = null;
	var playSoundBf:FlxUICheckBox = null;
	var playSoundDad:FlxUICheckBox = null;
	var UI_songTitle:FlxUIInputText;
	var optimizeJsonBox:FlxUICheckBox;
	// var noteSkinInputText:FlxUIInputText;
	// var noteSplashesInputText:FlxUIInputText;
	var stageDropDown:FlxUIDropDownMenuCustom;
	var songDropDown:FlxUIDropDownMenuCustom;
	var songs:Array<String>;

	public function loadSongs():Array<String>
	{
		var files = [];
		// if (Mods.modsMode)
		// 	directories.push('${Paths.mods(ModsFolder.currentModFolder)}/');
		// trace(directories);
		final a = AssetsPaths.getFolderDirectories(Constants.SONG_CHART_FILES_FOLDER, true);
		a.reverse();
		for (songFolder in a){
			for (file in AssetsPaths.getFolderContent(songFolder, true)){
				if(file.endsWith('.json'))
					files.push(file);
			}
		}
		// trace(files);
		return files;
	}

	function addSongUI():Void{
		songs = ['TEMPLATE'];
		for (i in loadSongs()) songs.push(i);

		songDropDown = new FlxUIDropDownMenuCustom(10, 10, FlxUIDropDownMenuCustom.makeStrIdLabelArray(songs, true),
			function(valueText:String){
				if (valueText != '0'){
					loadJson(songs[Std.parseInt(valueText)], true);
				}else{
					PlayState.SONG = null;
					MusicBeatState.resetState();
				}
			}, new FlxUIDropDownHeader(280, 30));
		// songDropDown.selectedLabel = _song.song;
		blockPressWhileScrolling.push(songDropDown);

		// UI_songTitle = new FlxUIInputText(10, 10, 70, _song.song, 8);
		// blockPressWhileTypingOn.push(UI_songTitle);

		var check_voices = new FlxUICheckBox(1000, 25, null, null, "Has voice track", 100);
		check_voices.checked = _song.needsVoices;
		// _song.needsVoices = check_voices.checked;
		check_voices.callback = function(){
			_song.needsVoices = check_voices.checked;
			// trace('CHECKED!');
		}

		var saveButton:FlxButton = new FlxButton(110, 48, "Save", function(){
			saveLevel();
		});

		// var reloadSongJson:FlxButton = new FlxButton(saveButton.x + 90, saveButton.y, "Reload JSON", function(){
		// 	loadJson(_song.song.toLowerCase());
		// });

		var reloadSong:FlxButton = new FlxButton(saveButton.x + 90, saveButton.y, "Reload Audio", function(){
			currentSongName = Paths.formatToSongPath(_song.song);
			loadSong();
			updateWaveform();
		});

		var loadAutosaveBtn:FlxButton = new FlxButton(reloadSong.x, saveButton.y + 30, 'Load Autosave', function(){
			PlayState.SONG = new Song(Song.parseJSONshit(save.data.autosave));
			MusicBeatState.resetState();
		});

		var loadEventJson:FlxButton = new FlxButton(loadAutosaveBtn.x, loadAutosaveBtn.y + 30, 'Load Events', function(){
			var songName:String = Paths.formatToSongPath(_song.song);
			var file:String = Paths.json(songName + '/events');
			if (OpenFlAssets.exists(file)){
				clearEvents();
				final events:SwagSong = Song.loadFromJson('events', songName);
				if (events != null){
					_song.events = events.events;
					changeSection(curSec);
				}
			}
		});

		var saveEvents:FlxButton = new FlxButton(saveButton.x, saveButton.y + 30, 'Save Events', function(){
			saveEvents();
		});

		optimizeJsonBox = new FlxUICheckBox(saveEvents.x, saveEvents.y + 30, null, null, "Optimize JSON?", 55);
		optimizeJsonBox.checked = true;

		var clear_events:FlxButton = new FlxButton(320, 310, 'Clear events', function(){
			openSubState(new Prompt('This action will clear current progress.\n\nProceed?', 0, clearEvents, null, ignoreWarnings));
		});
		clear_events.color = FlxColor.RED;
		clear_events.label.color = FlxColor.WHITE;

		var clear_notes:FlxButton = new FlxButton(320, clear_events.y + 30, 'Clear notes', function(){
			openSubState(new Prompt('This action will clear current progress.\n\nProceed?', 0, function(){
				for (sec in 0..._song.notes.length) _song.notes[sec].sectionNotes = [];
				updateGrid();
			}, null, ignoreWarnings));
		});
		clear_notes.color = FlxColor.RED;
		clear_notes.label.color = FlxColor.WHITE;

		var stepperBPM:FlxUINumericStepper = new FlxUINumericStepper(10, 70, 1, 1, 1, 4000, 3);
		stepperBPM.value = Conductor.bpm;
		stepperBPM.name = 'song_bpm';
		blockPressWhileTypingOnStepper.push(stepperBPM);

		var stepperSpeed:FlxUINumericStepper = new FlxUINumericStepper(10, stepperBPM.y + 35, 0.1, 1, 0.1, 10, 1);
		stepperSpeed.value = _song.speed;
		stepperSpeed.name = 'song_speed';
		blockPressWhileTypingOnStepper.push(stepperSpeed);

		var tempMap:Map<String, Bool> = new Map<String, Bool>();
		var characters:Array<String> = [];
		/*
			for (i in 0...characters.length) {
				tempMap.set(characters[i], true);
		}*/

		final a = AssetsPaths.getFolderContent('characters', true);
		a.reverse();
		for (path in a){
			if (path.endsWith('.json')){
				var charToCheck:String = new Path(path).file;
				if (charToCheck.endsWith('-dead') || tempMap.exists(charToCheck))	continue;
				tempMap.set(charToCheck, true);
				characters.push(charToCheck);
			}
		}

		var player1DropDown = new FlxUIDropDownMenuCustom(10, stepperSpeed.y + 45, FlxUIDropDownMenuCustom.makeStrIdLabelArray(characters, true),
		function(character:String){
			_song.player1 = characters[Std.parseInt(character)];
			updateChars();
			updateWaveform();
		});
		player1DropDown.selectedLabel = _song.player1;
		blockPressWhileScrolling.push(player1DropDown);

		var gfVersionDropDown = new FlxUIDropDownMenuCustom(player1DropDown.x, player1DropDown.y + 40,
			FlxUIDropDownMenuCustom.makeStrIdLabelArray(characters, true), function(character:String){
			_song.gfVersion = characters[Std.parseInt(character)];
			updateChars();
			updateWaveform();
		});
		gfVersionDropDown.selectedLabel = _song.gfVersion;
		blockPressWhileScrolling.push(gfVersionDropDown);

		var player2DropDown = new FlxUIDropDownMenuCustom(player1DropDown.x, gfVersionDropDown.y + 40,
			FlxUIDropDownMenuCustom.makeStrIdLabelArray(characters, true), function(character:String){
			_song.player2 = characters[Std.parseInt(character)];
			updateChars();
			updateWaveform();
		});
		player2DropDown.selectedLabel = _song.player2;
		blockPressWhileScrolling.push(player2DropDown);

		tempMap.clear();
		var stages:Array<String> = ['stage'];
		final a = AssetsPaths.getFolderContent('stages', true);
		a.reverse();
		for (path in a){
			if (path.endsWith('.json')){
				var stageToCheck:String = new Path(path).file;
				if (tempMap.exists(stageToCheck))	continue;
				tempMap.set(stageToCheck, true);
				stages.push(stageToCheck);
			}
		}

		stageDropDown = new FlxUIDropDownMenuCustom(player1DropDown.x + 140, player1DropDown.y, FlxUIDropDownMenuCustom.makeStrIdLabelArray(stages, true),
			function(character:String){
				_song.stage = stages[Std.parseInt(character)];
			});
		stageDropDown.selectedLabel = _song.stage;
		blockPressWhileScrolling.push(stageDropDown);

		// var skin = PlayState.SONG.arrowSkin;
		// if (skin == null) skin = '';
		// noteSkinInputText = new FlxUIInputText(player2DropDown.x, player2DropDown.y + 50, 150, skin, 8);
		// blockPressWhileTypingOn.push(noteSkinInputText);

		// noteSplashesInputText = new FlxUIInputText(noteSkinInputText.x, noteSkinInputText.y + 35, 150, _song.splashSkin, 8);
		// blockPressWhileTypingOn.push(noteSplashesInputText);

		// var reloadNotesButton:FlxButton = new FlxButton(noteSplashesInputText.x + 5, noteSplashesInputText.y + 20, 'Change Notes', function(){
		// 	_song.arrowSkin = noteSkinInputText.text;
		// 	reloadStrumNotes();
		// 	updateGrid();
		// });

		var tab_group_song = new FlxUI(null, UI_box);
		tab_group_song.name = "Song";
		// tab_group_song.add(UI_songTitle);

		tab_group_song.add(check_voices);
		tab_group_song.add(clear_events);
		tab_group_song.add(clear_notes);
		tab_group_song.add(saveButton);
		tab_group_song.add(saveEvents);
		tab_group_song.add(optimizeJsonBox);
		tab_group_song.add(reloadSong);
		// tab_group_song.add(reloadSongJson);
		tab_group_song.add(loadAutosaveBtn);
		tab_group_song.add(loadEventJson);
		tab_group_song.add(stepperBPM);
		tab_group_song.add(stepperSpeed);
		// tab_group_song.add(reloadNotesButton);
		// tab_group_song.add(noteSkinInputText);
		// tab_group_song.add(noteSplashesInputText);
		tab_group_song.add(new FlxStaticText(stepperBPM.x, stepperBPM.y - 15, 0, 'Song BPM:'));
		// tab_group_song.add(new FlxStaticText(stepperBPM.x + 100, stepperBPM.y - 15, 0, 'Song Offset:'));
		tab_group_song.add(new FlxStaticText(stepperSpeed.x, stepperSpeed.y - 15, 0, 'Song Speed:'));
		tab_group_song.add(new FlxStaticText(player2DropDown.x, player2DropDown.y - 15, 0, 'Opponent:'));
		tab_group_song.add(new FlxStaticText(gfVersionDropDown.x, gfVersionDropDown.y - 15, 0, 'Girlfriend:'));
		tab_group_song.add(new FlxStaticText(player1DropDown.x, player1DropDown.y - 15, 0, 'Boyfriend:'));
		tab_group_song.add(new FlxStaticText(stageDropDown.x, stageDropDown.y - 15, 0, 'Stage:'));
		// tab_group_song.add(new FlxStaticText(noteSkinInputText.x, noteSkinInputText.y - 15, 0, 'Note Texture:'));
		// tab_group_song.add(new FlxStaticText(noteSplashesInputText.x, noteSplashesInputText.y - 15, 0, 'Note Splashes Texture:'));
		tab_group_song.add(player2DropDown);
		tab_group_song.add(gfVersionDropDown);
		tab_group_song.add(player1DropDown);
		tab_group_song.add(stageDropDown);
		tab_group_song.add(songDropDown);

		UI_box.addGroup(tab_group_song);

		FlxG.camera.follow(camPos, LOCKON, Math.POSITIVE_INFINITY);
	}

	var stepperBeats:FlxUINumericStepper;
	var check_mustHitSection:FlxUICheckBox;
	var check_gfSection:FlxUICheckBox;
	var check_changeBPM:FlxUICheckBox;
	var stepperSectionBPM:FlxUINumericStepper;
	var check_altAnim:FlxUICheckBox;

	var sectionToCopy:Int = 0;
	var notesCopied:Array<Dynamic>;
	var mirrorButton:FlxButton;
	var swapSection:FlxButton;
	function addSectionUI():Void
	{
		var tab_group_section = new FlxUI(null, UI_box);
		tab_group_section.name = 'Section';

		check_mustHitSection = new FlxUICheckBox(10, 15, null, null, "Must hit section", 100);
		check_mustHitSection.name = 'check_mustHit';
		check_mustHitSection.checked = _song.notes[curSec].mustHitSection;

		check_gfSection = new FlxUICheckBox(10, check_mustHitSection.y + 22, null, null, "GF section", 100);
		check_gfSection.name = 'check_gf';
		check_gfSection.checked = _song.notes[curSec].gfSection;
		// _song.needsVoices = check_mustHit.checked;

		check_altAnim = new FlxUICheckBox(check_gfSection.x + 120, check_gfSection.y, null, null, "Alt Animation", 100);
		check_altAnim.checked = _song.notes[curSec].altAnim;

		stepperBeats = new FlxUINumericStepper(10, 100, 1, 4, 1, 6, 2);
		stepperBeats.value = getSectionBeats();
		stepperBeats.name = 'section_beats';
		blockPressWhileTypingOnStepper.push(stepperBeats);
		check_altAnim.name = 'check_altAnim';

		check_changeBPM = new FlxUICheckBox(10, stepperBeats.y + 30, null, null, 'Change BPM', 100);
		check_changeBPM.checked = _song.notes[curSec].changeBPM;
		check_changeBPM.name = 'check_changeBPM';

		stepperSectionBPM = new FlxUINumericStepper(10, check_changeBPM.y + 20, 1, Conductor.bpm, 0, 999, 1);
		stepperSectionBPM.value = (check_changeBPM.checked) ? _song.notes[curSec].bpm : Conductor.bpm;

		stepperSectionBPM.name = 'section_bpm';
		blockPressWhileTypingOnStepper.push(stepperSectionBPM);

		var check_eventsSec:FlxUICheckBox = null;
		var check_notesSec:FlxUICheckBox = null;
		var copyButton:FlxButton = new FlxButton(10, 190, "Copy Section", function()
		{
			notesCopied = [];
			sectionToCopy = curSec;
			for (i in _song.notes[curSec].sectionNotes)
				notesCopied.push(i);

			final startThing:Float = sectionStartTime();
			final endThing:Float = sectionStartTime(1);
			for (event in _song.events){
				final strumTime:Float = event[0];
				if (endThing > event[0] && event[0] >= startThing){
					final copiedEventArray:Array<Dynamic> = [];
					for (i in 0...event[1].length){
						final eventToPush:Array<Dynamic> = event[1][i];
						copiedEventArray.push([eventToPush[0], eventToPush[1], eventToPush[2], eventToPush[3]]);
					}
					notesCopied.push([strumTime, -1, copiedEventArray]);
				}
			}
		});

		var pasteButton:FlxButton = new FlxButton(copyButton.x + 100, copyButton.y, "Paste Section", function(){
			if (notesCopied == null || notesCopied.length < 1) return;

			final addToTime:Float = Conductor.stepCrochet * (getSectionBeats() * 4 * (curSec - sectionToCopy));
			// trace('Time to add: ' + addToTime);

			for (note in notesCopied){
				var copiedNote:Array<Dynamic> = [];
				final newStrumTime:Float = note[0] + addToTime;
				if (note[1] < 0){
					if (check_eventsSec.checked){
						var copiedEventArray:Array<Dynamic> = [];
						for (i in 0...note[2].length){
							final eventToPush:Array<Dynamic> = note[2][i];
							copiedEventArray.push([eventToPush[0], eventToPush[1], eventToPush[2], eventToPush[3]]);
						}
						_song.events.push([newStrumTime, copiedEventArray]);
					}
				}else{
					if (check_notesSec.checked){
						copiedNote = [newStrumTime, note[1], note[2], note[3], note[4] != null ? note[4] : ''];
						_song.notes[curSec].sectionNotes.push(copiedNote);
					}
				}
			}
			updateGrid();
		});

		var clearSectionButton:FlxButton = new FlxButton(pasteButton.x + 100, pasteButton.y, "Clear", function(){
			if (check_notesSec.checked) _song.notes[curSec].sectionNotes = [];

			if (check_eventsSec.checked){
				var i:Int = _song.events.length - 1;
				final startThing:Float = sectionStartTime();
				final endThing:Float = sectionStartTime(1);
				while (i > -1){
					final event:Array<Dynamic> = _song.events[i];
					if (event != null && endThing > event[0] && event[0] >= startThing)
						_song.events.remove(event);
					--i;
				}
			}
			updateGrid();
			updateNoteUI();
		});
		clearSectionButton.color = FlxColor.RED;
		clearSectionButton.label.color = FlxColor.WHITE;

		check_notesSec = new FlxUICheckBox(10, clearSectionButton.y + 25, null, null, "Notes", 100);
		check_notesSec.checked = true;
		check_eventsSec = new FlxUICheckBox(check_notesSec.x + 100, check_notesSec.y, null, null, "Events", 100);
		check_eventsSec.checked = true;

		swapSection = new FlxButton(10, check_notesSec.y + 40, "Swap section", function(){
			var curSect = _song.notes[curSec];
			for (i => note in curSect.sectionNotes)
			{
				note[1] = (note[1] + 4) % 8;
				curSect.sectionNotes[i] = note;
			}
			updateGrid();
		});

		var stepperCopy:FlxUINumericStepper = null;
		var copyLastButton:FlxButton = new FlxButton(10, swapSection.y + 30, "Copy last section", function(){
			var value:Int = Std.int(stepperCopy.value);
			if (value == 0) return;

			final daSec = FlxMath.maxInt(curSec, value);

			for (note in _song.notes[daSec - value].sectionNotes){
				final strum = note[0] + Conductor.stepCrochet * (getSectionBeats(daSec) * 4 * value);

				_song.notes[daSec].sectionNotes.push([strum, note[1], note[2], note[3]]);
			}

			final startThing:Float = sectionStartTime(-value);
			final endThing:Float = sectionStartTime(-value + 1);
			for (event in _song.events){
				if (endThing > event[0] && event[0] >= startThing){
					final strumTime:Float = event[0] + Conductor.stepCrochet * (getSectionBeats(daSec) * 4 * value);
					var copiedEventArray:Array<Dynamic> = [];
					for (i in 0...event[1].length){
						final eventToPush:Array<Dynamic> = event[1][i];
						copiedEventArray.push([eventToPush[0], eventToPush[1], eventToPush[2], eventToPush[3]]);
					}
					_song.events.push([strumTime, copiedEventArray]);
				}
			}
			updateGrid();
		});
		copyLastButton.setGraphicSize(80.0, 25.0);
		copyLastButton.updateHitbox();

		stepperCopy = new FlxUINumericStepper(copyLastButton.x + 100, copyLastButton.y + 10.0, 1, 1, -999, 999, 0);
		blockPressWhileTypingOnStepper.push(stepperCopy);

		var duetButton:FlxButton = new FlxButton(10, copyLastButton.y + 45, "Duet Notes", function(){
			var duetNotes:Array<Array<Dynamic>> = [];
			for (note in _song.notes[curSec].sectionNotes){
				final boob = note[1] + (note[1] > 3 ? -4 : 4);
				duetNotes.push([note[0], boob, note[2], note[3]]);
			}

			for (i in duetNotes) _song.notes[curSec].sectionNotes.push(i);

			updateGrid();
		});
		mirrorButton = new FlxButton(duetButton.x + 100, duetButton.y, "Mirror Notes", function(){
			// var duetNotes:Array<Array<Dynamic>> = [];
			for (note in _song.notes[curSec].sectionNotes){
				final boob = 3 - note[1] % 4 + ((note[1] > 3) ? 3 : 0);
				final copiedNote:Array<Dynamic> = [note[0], note[1] = boob, note[2], note[3]];
				// duetNotes.push(copiedNote);
			}

			// for (i in duetNotes) _song.notes[curSec].sectionNotes.push(i);

			updateGrid();
		});

		var insertSectionButton = new FlxButton(swapSection.x + 100.0, swapSection.y, "Insert Empty Section", () ->
		{
			// copy this section data and insert it
			var _curSection = _song.notes[curSec];
			var newSection = {
				sectionBeats: 4.0, // _curSection.sectionBeats
				bpm: _curSection.bpm,
				changeBPM: _curSection.changeBPM,
				mustHitSection: _curSection.mustHitSection,
				gfSection: _curSection.gfSection,
				sectionNotes: [],
				// typeOfSection: _curSection.typeOfSection,
				altAnim: _curSection.altAnim
			};
			_song.notes.insert(curSec, newSection);
			Log('inserted section: $newSection', GRAY);

			// offset notes
			var thisSectionTime = sectionStartTime();
			var nextSectionTime = sectionStartTime(1);
			var addTime = nextSectionTime - thisSectionTime;
			Log('this sec time: $thisSectionTime, next sec time: $nextSectionTime', GRAY);

			if (_song.events == null)
				_song.events = [];

			var countNotes = 0;
			for (i in (curSec + 1)..._song.notes.length)
			{
				for (note in _song.notes[i].sectionNotes)
				{
					note[0] += addTime;
					countNotes++;
				}
			}
			var countEvents = 0;
			for (event in _song.events)
			{
				if (event[0] < thisSectionTime)
					continue;

				event[0] += addTime;
				countEvents++;
			}
			Log('advanced $countNotes notes and $countEvents events by $addTime', GRAY);

			updateGrid();
		});
		insertSectionButton.setGraphicSize(80.0, 25.0);
		insertSectionButton.updateHitbox();

		var deleteSectionButton = new FlxButton(insertSectionButton.x + 100.0, insertSectionButton.y, "Delete Section", () ->
		{
			if (_song.notes.length == 1)
			{
				Log('can\'t remove only existing section!', RED);
				FlxG.sound.play(Paths.sound("cancelMenu"));
				return;
			}

			if (_song.events == null)
				_song.events = [];

			var thisSectionTime = sectionStartTime();
			if (_song.notes[curSec + 1] == null) // quickly remove section and it's events, then roll back
			{
				var sec = _song.notes.pop();
				// check if this note was selected and unselect it
				if (sec.sectionNotes.contains(curSelectedNote))
					curSelectedNote = null;

				// bye bye!!😏👈
				Log('section deleted: $sec', GRAY);
				Log('rolled back section to ${--curSec}', GRAY);
				Conductor.songPosition = sectionStartTime();
				FlxG.sound.music.time = Math.ffloor(Conductor.songPosition);

				var i = 0;
				while (i < _song.events.length)
				{
					var event = _song.events[i];
					if (event[0] >= thisSectionTime) // event is on this section, obliterate it💥💥
					{
						// check if this event was selected and unselect it
						if (noteCheck(event))
						{
							curSelectedNote = null;
							changeEventSelected();
						}
						_song.events.remove(event);
						Log('event deleted: $event', GRAY);
					}
					else // event is on previous section, skip it
						i++;
				}
			}
			else // remove current section and roll back next sections
			{
				var sec = _song.notes[curSec];
				// check if this note was selected and unselect it
				if (sec.sectionNotes.contains(curSelectedNote))
					curSelectedNote = null;

				_song.notes.remove(sec);
				Log('section deleted: $sec', GRAY);

				var nextSectionTime = sectionStartTime(1);
				var subtractTime = nextSectionTime - thisSectionTime;

				var countNotes = 0;
				for (i in curSec..._song.notes.length)
				{
					for (note in _song.notes[i].sectionNotes)
					{
						note[0] = Math.max(note[0] - subtractTime, 0.0);
						countNotes++;
					}
				}
				var i = 0;
				var countEvents = 0;
				while (i < _song.events.length)
				{
					var event:Array<Dynamic> = _song.events[i];
					var time = event[0];
					if (time >= nextSectionTime) // event is on next section, roll it back
					{
						event[0] = Math.max(time - subtractTime, 0.0);
						countEvents++;
						i++;
					}
					else if (time >= thisSectionTime) // event is on this section, obliterate it💥💥
					{
						// check if this event was selected and unselect it
						if (noteCheck(event))
						{
							curSelectedNote = null;
							changeEventSelected();
						}
						_song.events.remove(event);
						Log('event deleted: $event', GRAY);
					}
					else // event is on previous section, skip it
						i++;
				}
				Log('rolled back $countNotes notes and $countEvents events by $subtractTime', GRAY);
			}

			updateGrid();
		});
		deleteSectionButton.color = FlxColor.RED;
		deleteSectionButton.label.color = FlxColor.WHITE;

		tab_group_section.add(new FlxStaticText(stepperBeats.x, stepperBeats.y - 15, 0, 'Beats per Section:'));
		tab_group_section.add(stepperBeats);
		tab_group_section.add(stepperSectionBPM);
		tab_group_section.add(check_mustHitSection);
		tab_group_section.add(check_gfSection);
		tab_group_section.add(check_altAnim);
		tab_group_section.add(check_changeBPM);
		tab_group_section.add(copyButton);
		tab_group_section.add(pasteButton);
		tab_group_section.add(clearSectionButton);
		tab_group_section.add(check_notesSec);
		tab_group_section.add(check_eventsSec);
		tab_group_section.add(swapSection);
		tab_group_section.add(insertSectionButton);
		tab_group_section.add(deleteSectionButton);
		tab_group_section.add(stepperCopy);
		tab_group_section.add(copyLastButton);
		tab_group_section.add(duetButton);
		tab_group_section.add(mirrorButton);

		UI_box.addGroup(tab_group_section);
	}

	var stepperSusLength:FlxUINumericStepper;
	var strumTimeInputText:FlxUIInputText; // I wanted to use a stepper but we can't scale these as far as i know :(
	var noteTypeDropDown:FlxUIDropDownMenuCustom;
	var currentType:Int = 0;

	function addNoteUI():Void{
		var tab_group_note = new FlxUI(null, UI_box);
		tab_group_note.name = 'Note';

		stepperSusLength = new FlxUINumericStepper(10, 25, Conductor.stepCrochet / 2, 0, 0, Conductor.stepCrochet * 64);
		stepperSusLength.value = 0;
		stepperSusLength.name = 'note_susLength';
		blockPressWhileTypingOnStepper.push(stepperSusLength);

		strumTimeInputText = new FlxUIInputText(10, 65, 180, "0");
		tab_group_note.add(strumTimeInputText);
		blockPressWhileTypingOn.push(strumTimeInputText);

		var key:Int = 0;
		var displayNameList:Array<String> = [];
		while (key < noteTypeList.length){
			displayNameList.push(noteTypeList[key]);
			noteTypeMap.set(noteTypeList[key], key);
			noteTypeIntMap.set(key, noteTypeList[key]);
			key++;
		}

		for (file in AssetsPaths.getFolderContent(Constants.SONG_NOTETYPES_FILES_FOLDER, false)){
			if (file.endsWith('.lua') || file.endsWith('.hx') || (file.endsWith('.txt') && file != 'readme.txt')){
				var fileToCheck:String = file.substr(0, file.lastIndexOf('.'));
				if (!noteTypeMap.exists(fileToCheck)){
					displayNameList.push(fileToCheck);
					noteTypeMap.set(fileToCheck, key);
					noteTypeIntMap.set(key, fileToCheck);
					key++;
				}
			}
		}

		for (i in 1...displayNameList.length)
			displayNameList[i] = i + '. ' + displayNameList[i];

		noteTypeDropDown = new FlxUIDropDownMenuCustom(10, 105, FlxUIDropDownMenuCustom.makeStrIdLabelArray(displayNameList, true), function(character:String){
			currentType = Std.parseInt(character);
			if (curSelectedNote != null && curSelectedNote[1] > -1){
				curSelectedNote[3] = noteTypeIntMap.get(currentType);
				updateGrid();
			}
		});
		blockPressWhileScrolling.push(noteTypeDropDown);

		tab_group_note.add(new FlxStaticText(10, 10, 0, 'Sustain length:'));
		tab_group_note.add(new FlxStaticText(10, 50, 0, 'Strum time (in miliseconds):'));
		tab_group_note.add(new FlxStaticText(10, 90, 0, 'Note type:'));
		tab_group_note.add(stepperSusLength);
		tab_group_note.add(strumTimeInputText);
		tab_group_note.add(noteTypeDropDown);

		UI_box.addGroup(tab_group_note);
	}

	var eventDropDown:FlxUIDropDownMenuCustom;
	var descTextBG:FlxSprite;
	var descText:FlxStaticText;
	var selectedEventText:FlxStaticText;

	function addEventsUI():Void{
		var tab_group_event = new FlxUI(null, UI_box);
		tab_group_event.name = 'Events';

		var isHX:Bool = false;
		var contains:Bool = false;
		for (file in AssetsPaths.getFolderContent(Constants.SONG_EVENTS_FILES_FOLDER, false)){
			if (file != 'readme.txt' && (file.endsWith('.txt') || (isHX = file.endsWith('.hx')))){
				var fileToCheck:String = file.substr(0, file.lastIndexOf('.'));
				contains = true;
				for (i in eventStuff)
				{
					if (i[0] == fileToCheck)
					{
						contains = false;
						break;
					}
				}
				if(contains)
					eventStuff.push([fileToCheck, Assets.getText(Constants.SONG_EVENTS_FILES_FOLDER + '/' + fileToCheck + ".txt") ?? ""]);
				isHX = false;
			}
		}

		descText = new FlxStaticText(20, 240, 250, eventStuff[0][0]);
		descTextBG = new FlxSprite(descText.x - 3, descText.y - 3).makeGraphic(250, 1, 0xFF000000);
		descTextBG.origin.set(0, 0);
		updateDescTextBG();

		tab_group_event.add(new FlxStaticText(20, 30, 0, "Event:"));
		eventDropDown = new FlxUIDropDownMenuCustom(20, 50,
			FlxUIDropDownMenuCustom.makeStrIdLabelArray([for (i in 0...eventStuff.length) eventStuff[i][0]], true),
			function(pressed:String){
				final selectedEvent:Int = Std.parseInt(pressed);
				descText.text = eventStuff[selectedEvent][1];
				if (curSelectedNote != null && eventStuff != null){
					if (curSelectedNote != null && curSelectedNote[2] == null) curSelectedNote[1][curEventSelected][0] = 	eventStuff[selectedEvent][0];
					updateGrid();
				}
				updateDescTextBG();
			}
		);
		blockPressWhileScrolling.push(eventDropDown);

		tab_group_event.add(new FlxStaticText(20, 90, 280, "Value 1:"));
		value1InputText = new ColorfullInputText(20, 110, 280, "");
		blockPressWhileTypingOn.push(value1InputText);

		tab_group_event.add(new FlxStaticText(20, 130, 280, "Value 2:"));
		value2InputText = new ColorfullInputText(20, 150, 280, "");
		blockPressWhileTypingOn.push(value2InputText);

		tab_group_event.add(new FlxStaticText(20, 170, 280, "Value 3:"));
		value3InputText = new ColorfullInputText(20, 190, 280, "");
		blockPressWhileTypingOn.push(value3InputText);

		// New event buttons
		var removeButton:FlxButton = new FlxButton(eventDropDown.x + eventDropDown.width + 10, eventDropDown.y, '-', function(){
			if (curSelectedNote != null && curSelectedNote[2] == null){ // Is event note
				if (curSelectedNote[1].length < 2){
					_song.events.remove(curSelectedNote);
					curSelectedNote = null;
				}else
					curSelectedNote[1].remove(curSelectedNote[1][curEventSelected]);

				var eventsGroup:Array<Dynamic>;
				--curEventSelected;
				if (curEventSelected < 0)
					curEventSelected = 0;
				else if (curSelectedNote != null && curEventSelected >= (eventsGroup = curSelectedNote[1]).length)
					curEventSelected = eventsGroup.length - 1;

				changeEventSelected();
				updateGrid();
			}
		});
		removeButton.setGraphicSize(removeButton.height, removeButton.height);
		removeButton.updateHitbox();
		removeButton.color = FlxColor.RED;
		removeButton.label.color = FlxColor.WHITE;
		removeButton.label.size = 12;
		setAllLabelsOffset(removeButton, -30, 0);
		tab_group_event.add(removeButton);

		var addButton:FlxButton = new FlxButton(removeButton.x + removeButton.width + 10, removeButton.y, '+', function(){
			if (curSelectedNote != null && curSelectedNote[2] == null){ // Is event note
				var eventsGroup:Array<Dynamic> = curSelectedNote[1];
				eventsGroup.push(['', '', '']);

				changeEventSelected(1);
				updateGrid();
			}
		});
		addButton.setGraphicSize(removeButton.width, removeButton.height);
		addButton.updateHitbox();
		addButton.color = FlxColor.GREEN;
		addButton.label.color = FlxColor.WHITE;
		addButton.label.size = 12;
		setAllLabelsOffset(addButton, -30, 0);
		tab_group_event.add(addButton);

		var moveLeftButton:FlxButton = new FlxButton(addButton.x + addButton.width + 20, addButton.y, '<', function(){
			changeEventSelected(-1);
		});
		moveLeftButton.setGraphicSize(addButton.width, addButton.height);
		moveLeftButton.updateHitbox();
		moveLeftButton.label.size = 12;
		setAllLabelsOffset(moveLeftButton, -30, 0);
		tab_group_event.add(moveLeftButton);

		var moveRightButton:FlxButton = new FlxButton(moveLeftButton.x + moveLeftButton.width + 10, moveLeftButton.y, '>', function(){
			changeEventSelected(1);
		});
		moveRightButton.setGraphicSize(moveLeftButton.width, moveLeftButton.height);
		moveRightButton.updateHitbox();
		moveRightButton.label.size = 12;
		setAllLabelsOffset(moveRightButton, -30, 0);
		tab_group_event.add(moveRightButton);

		selectedEventText = new FlxStaticText(addButton.x - 100, addButton.y + addButton.height + 6, (moveRightButton.x - addButton.x) + 186,
			'Selected Event: None');
		selectedEventText.alignment = CENTER;
		tab_group_event.add(selectedEventText);

		tab_group_event.add(descTextBG);
		tab_group_event.add(descText);
		tab_group_event.add(value1InputText);
		tab_group_event.add(value2InputText);
		tab_group_event.add(value3InputText);
		tab_group_event.add(eventDropDown);

		UI_box.addGroup(tab_group_event);
	}


	function changeEventSelected(change:Int = 0){
		if (curSelectedNote != null && curSelectedNote[2] == null){ // Is event note
			curEventSelected += change;
			if (curEventSelected < 0)
				curEventSelected = Std.int(curSelectedNote[1].length) - 1;
			else if (curEventSelected >= curSelectedNote[1].length)
				curEventSelected = 0;
			selectedEventText.text = 'Selected Event: ' + (curEventSelected + 1) + ' / ' + curSelectedNote[1].length;
		}else{
			curEventSelected = 0;
			selectedEventText.text = 'Selected Event: None';
		}
		updateNoteUI();
	}

	function setAllLabelsOffset(button:FlxButton, x:Float, y:Float)
		for (point in button.labelOffsets)
			point.set(x, y);

	var metronome:FlxUICheckBox;
	var mouseScrollingQuant:FlxUICheckBox;
	var metronomeStepper:FlxUINumericStepper;
	var metronomeOffsetStepper:FlxUINumericStepper;
	var disableAutoScrolling:FlxUICheckBox;
	#if desktop
	var waveformUseInstrumental:FlxUICheckBox;
	var waveformUseVoices:FlxUICheckBox;
	#end
	var instVolume:FlxUINumericStepper;
	var voicesVolume:FlxUINumericStepper;
	var voiceDadVolume:FlxUINumericStepper;
	var voiceBFVolume:FlxUINumericStepper;
	var dadPressVolume:FlxUINumericStepper;
	var bfPressVolume:FlxUINumericStepper;
	#if FLX_PITCH
	var sliderRate:FlxUISlider;
	#end

	function addChartingUI(){
		var tab_group_chart = new FlxUI(null, UI_box);
		tab_group_chart.name = 'Charting';

		#if desktop
		save.data.chart_waveformInstrumental ??= false;
		save.data.chart_waveformVocals ??= false;

		waveformUseInstrumental = new FlxUICheckBox(10, 90, null, null, "Waveform for Instrumental", 100);
		waveformUseInstrumental.checked = save.data.chart_waveformInstrumental;
		waveformUseInstrumental.callback = function(){
			save.data.chart_waveformInstrumental = waveformUseInstrumental.checked;
			updateWaveform();
		}

		waveformUseVoices = new FlxUICheckBox(waveformUseInstrumental.x + 120, waveformUseInstrumental.y, null, null, "Waveform for Voices", 100);
		waveformUseVoices.checked = save.data.chart_waveformVocals;
		waveformUseVoices.callback = function(){
			save.data.chart_waveformVocals = waveformUseVoices.checked;
			updateWaveform();
		}
		#end

		check_mute_inst = new FlxUICheckBox(10, 310, null, null, "Mute Instrumental (in editor)", 100);
		check_mute_inst.checked = false;
		check_mute_inst.callback = function(){
			updateVolume('inst');
		}
		mouseScrollingQuant = new FlxUICheckBox(10, 200, null, null, "Mouse Scrolling Quantization", 100);
		save.data.mouseScrollingQuant ??= false;
		mouseScrollingQuant.checked = save.data.mouseScrollingQuant;

		mouseScrollingQuant.callback = function(){
			save.data.mouseScrollingQuant = mouseScrollingQuant.checked;
			mouseQuant = save.data.mouseScrollingQuant;
		}

		/*
		var filterButton:FlxButton = new FlxButton(waveformUseVoices.x, mouseScrollingQuant.y, "Filter overlapping notes", function()
		{
			var lastTime:Int = -10;
			var lastDir:Int = -2;
			for (daSection in _song.notes)
			{
				daSection.sectionNotes.sort((i1:Array<Dynamic>, i2:Array<Dynamic>) -> FlxSort.byValues(-1, i1[0], i2[0]));
				for (i in daSection.sectionNotes)
				{
					if (Std.int(i[0]) == lastTime){
						daSection.sectionNotes.remove(i);
						trace([i, " was removed"]);
					}
					lastTime = Std.int(i[0]);
					lastDir = i[1]
				}
			}
			updateGrid();
		});
		*/

		check_vortex = new FlxUICheckBox(10, 160, null, null, "Vortex Editor (BETA)", 100);
		save.data.chart_vortex ??= false;
		check_vortex.checked = save.data.chart_vortex;

		check_vortex.callback = function(){
			save.data.chart_vortex = check_vortex.checked;
			vortex = save.data.chart_vortex;
			reloadGridLayer();
		}

		check_warnings = new FlxUICheckBox(10, 120, null, null, "Ignore Progress Warnings", 100);
		save.data.ignoreWarnings ??= false;
		check_warnings.checked = save.data.ignoreWarnings;

		check_warnings.callback = function(){
			save.data.ignoreWarnings = check_warnings.checked;
			ignoreWarnings = save.data.ignoreWarnings;
		}

		check_mute_vocals = new FlxUICheckBox(check_mute_inst.x + 120, check_mute_inst.y, null, null, "Mute Vocals (in editor)", 100);
		check_mute_vocals.checked = false;
		check_mute_vocals.callback = function(){
			var a:Float = check_mute_vocals.checked ? 0 : voicesVolume.value;
			vocals[0].volume = a;
			if (vocals.length > 1){
				vocals[0].volume *=  check_enable_voiceDadVolume.checked ? voiceDadVolume.value * a : 0;
				vocals[1].volume =  check_enable_voiceBFVolume.checked ? voicesVolume.value * voiceBFVolume.value * a : 0;
			}
		}

		playSoundBf = new FlxUICheckBox(check_mute_inst.x, check_mute_vocals.y + 30, null, null, 'Play Sound (Boyfriend notes)', 100, function(){
			save.data.chart_playSoundBf = playSoundBf.checked;
		});
		if (save.data.chart_playSoundBf == null)
			save.data.chart_playSoundBf = false;
		playSoundBf.checked = save.data.chart_playSoundBf;

		playSoundDad = new FlxUICheckBox(check_mute_inst.x + 120, playSoundBf.y, null, null, 'Play Sound (Opponent notes)', 100, function(){
			save.data.chart_playSoundDad = playSoundDad.checked;
		});
		if (save.data.chart_playSoundDad == null)
			save.data.chart_playSoundDad = false;
		playSoundDad.checked = save.data.chart_playSoundDad;

		metronome = new FlxUICheckBox(10, 15, null, null, "Metronome Enabled", 100, function(){
			save.data.chart_metronome = metronome.checked;
		});
		if (save.data.chart_metronome == null)
			save.data.chart_metronome = false;
		metronome.checked = save.data.chart_metronome;

		metronomeStepper = new FlxUINumericStepper(15, 55, 5, _song.bpm, 1, 4500, 1);
		metronomeOffsetStepper = new FlxUINumericStepper(metronomeStepper.x + 100, metronomeStepper.y, 25, 0, 0, 4000, 1);
		blockPressWhileTypingOnStepper.push(metronomeStepper);
		blockPressWhileTypingOnStepper.push(metronomeOffsetStepper);

		dadPressVolume = new FlxUINumericStepper(playSoundDad.x, playSoundDad.y + 20, 0.02, save.data.pressDad_volume, 0, 1, 2);
		bfPressVolume = new FlxUINumericStepper(playSoundBf.x, playSoundBf.y + 20, 0.02, save.data.pressbf_volume, 0, 1, 2);
		dadPressVolume.name = 'dadPressVolume';
		bfPressVolume.name = 'bfPressVolume';
		blockPressWhileTypingOnStepper.push(dadPressVolume);
		blockPressWhileTypingOnStepper.push(bfPressVolume);

		disableAutoScrolling = new FlxUICheckBox(metronome.x + 120, metronome.y, null, null, "Disable Autoscroll (Not Recommended)", 120, function(){
			save.data.chart_noAutoScroll = disableAutoScrolling.checked;
		});
		if (save.data.chart_noAutoScroll == null)
			save.data.chart_noAutoScroll = false;
		disableAutoScrolling.checked = save.data.chart_noAutoScroll;

		#if FLX_PITCH
		sliderRate = new FlxUISlider(this, 'playbackSpeed', 120, 200, 0.5, 3, 150, 15, 5, FlxColor.WHITE, FlxColor.BLACK);
		sliderRate.nameLabel.text = 'Playback Rate';
		tab_group_chart.add(sliderRate);
		#end

		instVolume = new FlxUINumericStepper(metronomeStepper.x, 270, 0.1, 1, 0, 1, 1);
		instVolume.value = save.data.inst_volume;
		instVolume.name = 'inst_volume';
		blockPressWhileTypingOnStepper.push(instVolume);

		voicesVolume = new FlxUINumericStepper(
			#if desktop waveformUseVoices.x #else 10 #end,
			instVolume.y, 0.1, 1, 0, 1, 1);
		voicesVolume.value = save.data.voices_volume;
		voicesVolume.name = 'voices_volume';
		blockPressWhileTypingOnStepper.push(voicesVolume);

		voiceDadVolume = new FlxUINumericStepper(voicesVolume.x, check_vortex.y - 28, 0.1, 1, 0, 1, 1);
		voiceDadVolume.value = save.data.voiceDad_volume;
		voiceDadVolume.name = 'voiceDad_volume';
		blockPressWhileTypingOnStepper.push(voiceDadVolume);

		voiceBFVolume = new FlxUINumericStepper(voiceDadVolume.x, mouseScrollingQuant.y - 28, 0.1, 1, 0, 1, 1);
		voiceBFVolume.value = save.data.voicebf_volume;
		voiceBFVolume.name = 'voicebf_volume';
		blockPressWhileTypingOnStepper.push(voiceBFVolume);

		check_enable_voiceDadVolume = new FlxUICheckBox(voiceDadVolume.x + 70, voiceDadVolume.y, null, null, "", 1);
		check_enable_voiceDadVolume.checked = true;
		check_enable_voiceDadVolume.callback = function(){
			if (vocals.length > 1)
				vocals[0].volume = !check_enable_voiceDadVolume.checked || check_mute_vocals.checked ? 0 : voicesVolume.value;
		}

		check_enable_voiceBFVolume = new FlxUICheckBox(voiceBFVolume.x + 70, voiceBFVolume.y, null, null, "", 1);
		check_enable_voiceBFVolume.checked = true;
		check_enable_voiceBFVolume.callback = function(){
			if (vocals.length > 1)
				vocals[1].volume = !check_enable_voiceBFVolume.checked || check_mute_vocals.checked ? 0 : voicesVolume.value;
		}


		tab_group_chart.add(new FlxStaticText(metronomeStepper.x, metronomeStepper.y - 15, 0, 'BPM:'));
		tab_group_chart.add(new FlxStaticText(metronomeOffsetStepper.x, metronomeOffsetStepper.y - 15, 0, 'Offset (ms):'));
		tab_group_chart.add(new FlxStaticText(instVolume.x, instVolume.y - 15, 0, 'Inst Volume'));
		tab_group_chart.add(new FlxStaticText(voicesVolume.x, voicesVolume.y - 15, 0, 'Voices Volume'));
		tab_group_chart.add(metronome);
		tab_group_chart.add(disableAutoScrolling);
		tab_group_chart.add(metronomeStepper);
		tab_group_chart.add(metronomeOffsetStepper);
		#if desktop
		tab_group_chart.add(waveformUseInstrumental);
		tab_group_chart.add(waveformUseVoices);
		#end
		tab_group_chart.add(instVolume);
		tab_group_chart.add(voicesVolume);
		tab_group_chart.add(voiceDadVolume);
		tab_group_chart.add(voiceBFVolume);
		tab_group_chart.add(new FlxStaticText(voiceDadVolume.x - 2, voiceDadVolume.y - 15, 0, 'Voice Opponent Volume'));
		tab_group_chart.add(new FlxStaticText(voiceBFVolume.x - 2, voiceBFVolume.y - 15, 0, 'Voice Boyfriend Volume'));
		tab_group_chart.add(check_mute_inst);
		tab_group_chart.add(check_mute_vocals);
		tab_group_chart.add(check_enable_voiceDadVolume);
		tab_group_chart.add(check_enable_voiceBFVolume);
		tab_group_chart.add(check_vortex);
		tab_group_chart.add(mouseScrollingQuant);
		// tab_group_chart.add(filterButton);
		tab_group_chart.add(check_warnings);
		tab_group_chart.add(playSoundBf);
		tab_group_chart.add(playSoundDad);
		tab_group_chart.add(dadPressVolume);
		tab_group_chart.add(bfPressVolume);
		UI_box.addGroup(tab_group_chart);
	}

	function addPropertiesUI()
	{
		var tab_group_properties = new FlxUI(null, UI_box);
		tab_group_properties.name = 'Properties';
		var lastX:Float = 10;
		var lastY:Float = 10;
		var options:Array<LocalSongOption> = [
			{
				label: "Notes Texture",
				field: "arrowSkin",
				callback: (flxtext, txt, action) -> {
					final songData = PlayState.SONG;
					var finalColor:FlxColor = 0xFF000000;
					if (!Assets.exists(AssetsPaths.file('images/$txt.xml')))
					{
						finalColor = 0xFFFF0000;
					}
					flxtext.color = finalColor;
					if (action == FlxInputText.ENTER_ACTION)
					{
						if (flxtext.color == 0xFF000000)
						{
							reloadStrumNotes();
							updateGrid();
						}
						// else
						// {
						// 	FlxG.sound.play(Paths.sound("badnoise" + FlxG.random.int(1, 3)));
						// }
					}
				}
			},
			{
				label: "Splash Texture",
				field: "splashSkin",
				callback: (flxtext, txt, action) -> {
					var finalColor:FlxColor = 0xFF000000;
					if (!Assets.exists(AssetsPaths.file('images/$txt.xml')))
					{
						finalColor = 0xFFFF0000;
					}
					flxtext.color = finalColor;
					// if (action == FlxInputText.ENTER_ACTION && flxtext.color != 0xFF000000)
					// {
					// 	FlxG.sound.play(Paths.sound("badnoise" + FlxG.random.int(1, 3)));
					// }
				}
			},
			{
				label: "Hold Note Cover Texture",
				field: "holdCoverSkin",
				callback: (flxtext, txt, action) -> {
					var finalColor:FlxColor = 0xFF000000;
					if (!Assets.exists(AssetsPaths.file('images/$txt.xml')))
					{
						finalColor = 0xFFFF0000;
					}
					flxtext.color = finalColor;
					// if (action == FlxInputText.ENTER_ACTION && flxtext.color != 0xFF000000)
					// {
					// 	FlxG.sound.play(Paths.sound("badnoise" + FlxG.random.int(1, 3)));
					// }
				}
			},
			{
				label: "Artist:",
				field: "artist"
			},
			{
				label: "Charter:",
				field: "charter"
			},
			{
				label: "Display song:",
				field: "display",
				#if DISCORD_RPC
				callback: (_, _, _) -> { // fun
					DiscordClient.changePresence("Chart Editor", _song.display);
				}
				#end
			},
			{
				label: "Media Postfix:",
				field: "postfix",
				callback: (flxtext, txt, action) -> {
					var finalColor:FlxColor = 0xFF000000;
					if (Paths.inst(_song.song, _song.postfix) == null)
					{
						finalColor.red += PlayState.SONG.needsVoices ? 75 : 75 * 2;
					}
					if (PlayState.SONG.needsVoices && Paths.voices(_song.song, 'Voices' + _song.postfix) == null
						&& (
							Paths.voices(_song.song, 'Voices_Player' + _song.postfix) == null
							|| Paths.voices(_song.song, 'Voices_Opponent' + _song.postfix) == null
						)
					)
					{
						finalColor.red += 75;
					}
					flxtext.color = finalColor;
					if (action == FlxInputText.ENTER_ACTION)
					{
						if (flxtext.color == 0xFF000000)
						{
							trace('Postfix \'${_song.postfix}\' is valid');
							loadSong();
						}
						// else
						// {
						// 	FlxG.sound.play(Paths.sound("badnoise" + FlxG.random.int(1, 3)));
						// }
					}
				}
			},
		];

		for (i in options)
		{
			if (lastY + 66 >= UI_box.height)
			{
				lastX += 170;
				lastY = 10;
			}
			tab_group_properties.add(new FlxStaticText(lastX, lastY, 0, (i.label ?? i.field.capitalize() + ':')));
			lastY += 14;
			var inputText = new ColorfullInputText(lastX, lastY, 160, "");
			// if (Reflect.hasField(_song, i.field))
			{
				inputText.text = Std.string(Reflect.getProperty(_song, i.field) ?? "");
				inputText.callback = (
					i.callback != null ? function(txt:String, action:String)
					{
						Reflect.setProperty(_song, i.field, txt);
						i.callback(inputText, txt, action);
					}
					:
					function(txt:String, action:String)
					{
						Reflect.setProperty(_song, i.field, txt);
					}
				);
			}
			// else
			// {
			// 	// for (i in Reflect.fields(_song))
			// 	// 	trace(i + ": " + Reflect.field(_song, i));
			// 	Log('Invalid \'${i.field}\' field in song data', RED);
			// }
			blockPressWhileTypingOn.push(inputText);
			tab_group_properties.add(inputText);
			lastY += 28;
		}
		UI_box.addGroup(tab_group_properties);
	}

	@:privateAccess
	function loadSong():Void{
		if (FlxG.sound.music != null){
			FlxG.sound.music.stop();
			// vocals.stop();
		}
		final cache:openfl.utils.AssetCache = cast OpenFlAssets.cache;
		for (i in [vocal, vocalBF])
		{
			FlxG.sound.list.remove(i);
			if (i == null)
				continue;
			if (i._sound != null && cache != null){
				for (key => sound in cache.sound){
					if (sound == i._sound){
						if (sound?.__buffer != null)
						{
							sound.__buffer.dispose();
							sound.__buffer = null;
						}
						cache.removeSound(key);
						break;
					}
				}
			}
			i.destroy();
		}

		vocal = new FlxSound();
		vocalBF = new FlxSound();
		if(PlayState.SONG.needsVoices)
		{
			final songData = PlayState.SONG;
			final singleVocals:openfl.media.Sound = Paths.voices(songData.song, 'Voices' + songData.postfix);
			if (singleVocals == null)
			{
				vocalBF.loadEmbedded(Paths.voices(songData.song, 'Voices_Player' + songData.postfix));
				vocal.loadEmbedded(Paths.voices(songData.song, 'Voices_Opponent' + songData.postfix));
			}
			else
			{
				vocal.loadEmbedded(singleVocals);
			}
		}
		vocal.volume = vocalBF.volume = save.data.voices_volume;
		vocal.volume *= save.data.voiceDad_volume;
		vocalBF.volume *= save.data.voicebf_volume;
		FlxG.sound.list.add(vocal);
		FlxG.sound.list.add(vocalBF);
		vocals = [vocal];
		if (vocalBF.isValid())
			vocals.push(vocalBF);

		generateSong();
		FlxG.sound.music.pause();
		Conductor.songPosition = sectionStartTime();
		FlxG.sound.music.time = Conductor.songPosition;
	}

	function generateSong()
	{
		FlxG.sound.playMusic(Paths.inst(currentSongName, PlayState.SONG.postfix), save.data.inst_volume /*, false*/);
		if (check_mute_inst != null)
			updateVolume('inst');
		if (check_mute_vocals != null)
			updateVolume('voices');
		FlxG.sound.music.onComplete = function()
		{
			FlxG.sound.music.pause();
			Conductor.songPosition = 0;
			for (i in vocals)
			{
				i.pause();
				i.time = 0;
			}
			changeSection();
			curSec = 0;
			updateGrid();
			updateSectionUI();
			for (i in vocals)
				i.play();
		}
	}

	override function getEvent(id:String, sender:Dynamic, data:Dynamic, ?params:Array<Dynamic>)
	{
		if (id == FlxUICheckBox.CLICK_EVENT)
		{
			final check:FlxUICheckBox = cast sender;
			switch (check.getLabel().text){
				case 'Must hit section':
					_song.notes[curSec].mustHitSection = check.checked;

					updateGrid();
					updateHeads();
					updateWaveform();

				case 'GF section':
					_song.notes[curSec].gfSection = check.checked;

					updateGrid();
					updateHeads();
					updateWaveform();

				case 'Change BPM':
					_song.notes[curSec].changeBPM = check.checked;
					FlxG.log.add('changed bpm shit');
					reloadBPMChanges();
				case "Alt Animation":
					_song.notes[curSec].altAnim = check.checked;
			}
		}
		else if (id == FlxUINumericStepper.CHANGE_EVENT && (sender is FlxUINumericStepper))
		{
			final nums:FlxUINumericStepper = cast sender;
			switch (nums.name){
				case 'song_speed':
					_song.speed = nums.value;

				case 'song_bpm':
					_song.bpm = nums.value;
					Conductor.mapBPMChanges(_song);
					Conductor.bpm = nums.value;

					reloadBPMChanges();

				case 'section_bpm':
					_song.notes[curSec].bpm = nums.value;
					reloadBPMChanges();

				case 'section_beats':
					_song.notes[curSec].sectionBeats = nums.value;

					reloadBPMChanges();

				case 'note_susLength':
					if (curSelectedNote != null && curSelectedNote[1] > -1){
						curSelectedNote[2] = nums.value;
						updateGrid();
					}else
						sender.value = 0;

				case 'inst_volume':
					updateVolume('inst');

				case 'voices_volume' | 'voiceDad_volume' | 'voicebf_volume':
					updateVolume('voices');
				case 'bfPressVolume':
					save.data.pressbf_volume = bfPressVolume.value;
				case 'dadPressVolume':
					save.data.pressDad_volume = dadPressVolume.value;
			}
		}
		else if (id == FlxUIInputText.CHANGE_EVENT && (sender is FlxUIInputText))
		{
			// if (sender == noteSplashesInputText)
			// 	_song.splashSkin = noteSplashesInputText.text;
			// else
			if (curSelectedNote != null)
			{
				var curEvent = curSelectedNote[1][curEventSelected];
				if(curEvent != null)
				{
					if (sender == value1InputText){
						curEvent[1] = value1InputText.text;
						updateGrid();
					}else if (sender == value2InputText){
						curEvent[2] = value2InputText.text;
						updateGrid();
					}else if(sender == value3InputText) {
						curEvent[3] = value3InputText.text;
						updateGrid();
					}
				}
				if (sender == strumTimeInputText){
					curSelectedNote[0] = Std.parseFloat(strumTimeInputText.text).getDefault(0);
					updateGrid();
				}
			}
		}
		/*
		else if (id == FlxUISlider.CHANGE_EVENT && (sender is FlxUISlider))
		{
			switch (sender)
			{
				case 'playbackSpeed':
					playbackSpeed = #if FLX_PITCH Std.int(sliderRate.value) #else 1.0 #end;
			}
		}
		*/
		// FlxG.log.add(id + " WEED " + sender + " WEED " + data + " WEED " + params);
	}

	function updateDescTextBG() descTextBG.scale.y = descText.height + 6;

	function updateVolume(type:String)
		switch(type){
			case 'inst':
				FlxG.sound.music.volume = check_mute_inst.checked ? 0 : instVolume.value;
				save.data.inst_volume = instVolume.value;
			case 'voices':
				if (check_mute_vocals.checked)
					for(i in vocals) i.volume = 0;
				else{
					vocals[0].volume = voicesVolume.value;
					if (vocals.length > 1){
						vocals[0].volume *= check_enable_voiceDadVolume.checked ? voiceDadVolume.value : 0;
						vocals[1].volume = check_enable_voiceBFVolume.checked ? voicesVolume.value * voiceBFVolume.value : 0;
					}
					save.data.voicebf_volume = voiceBFVolume.value;
					save.data.voiceDad_volume = voiceDadVolume.value;
					save.data.voices_volume = voicesVolume.value;
				}
		}

	var updatedSection:Bool = false;

	function sectionStartTime(add:Int = 0):Float{
		var daBPM:Float = _song.bpm;
		var daPos:Float = 0;
		for (i in 0...curSec + add)
		{
			if (_song.notes[i] != null){
				if (_song.notes[i].changeBPM)
					daBPM = _song.notes[i].bpm;
			}
			daPos += getSectionBeats(i) * (1000 * 60 / daBPM);
		}
		return daPos;
	}

	var lastConductorPos:Float;
	var colorSine:Float = 0;

	// var curSelectedObj:Dynamic = null;

	var updatethat:Bool = true;
	var canDragNote:Bool = false; // not supported

	var goback:Bool = false;

	override function update(elapsed:Float) {
		if (!goback && subState == null && updatethat)
		{
			curStep = recalculateSteps();

			if (FlxG.sound.music.time < 0)
			{
				FlxG.sound.music.pause();
				FlxG.sound.music.time = 0;
			}
			else if (FlxG.sound.music.time > FlxG.sound.music.length)
			{
				FlxG.sound.music.pause();
				FlxG.sound.music.time = 0;
				changeSection();
			}
			Conductor.songPosition = FlxG.sound.music.time;

			FlxG.mouse.visible = true; // cause reasons. trust me
			camPos.y = strumLine.y;
			if (!disableAutoScrolling.checked)
			{
				if (Math.ceil(strumLine.y) >= gridBG.height)
				{
					if (_song.notes[curSec + 1] == null) addSection(_song.notes[curSec]?.sectionBeats ?? 4);
					changeSection(curSec + 1, false);
				}
				else if (strumLine.y < -strumLine.height)
				{
					changeSection(curSec - 1, false);
				}
			}

			if (FlxG.mouse.x > gridBG.x
				&& FlxG.mouse.x < gridBG.x + gridBG.width
				&& FlxG.mouse.y > gridBG.y
				&& FlxG.mouse.y < gridBG.y + gridBG.height)
			{
				dummyArrow.visible = true;
				dummyArrow.x = Math.ffloor(FlxG.mouse.x / GRID_SIZE) * GRID_SIZE;
				if (FlxG.keys.pressed.SHIFT)
				{
					dummyArrow.y = FlxG.mouse.y;
				}
				else
				{
					final gridmult = GRID_SIZE / (quantization / 16);
					dummyArrow.y = Math.ffloor(FlxG.mouse.y / gridmult) * gridmult;
				}
				CursorManager.instance.cursor = 'button';
			}
			else
			{
				CursorManager.instance.cursor = null;
				dummyArrow.visible = false;
			}

			if (FlxG.mouse.justPressed)
			{
				if (FlxG.mouse.overlaps(curRenderedNotes, FlxG.camera))
				{
					for (note in curRenderedNotes.members)
					{
						if (note == null || !note.alive)
							continue;
						if (FlxG.mouse.overlaps(note, FlxG.camera))
						{
							canDragNote = false;
							if (FlxG.keys.pressed.CONTROL)
							{
								canDragNote = true;
								selectNote(note);
							}
							else if (FlxG.keys.pressed.ALT)
							{
								selectNote(note);
								curSelectedNote[3] = noteTypeIntMap.get(currentType);
								updateGrid();
							}
							else
							{
								// trace('tryin to delete note...');
								deleteNote(note);
							}
							break;
						}
					}
				}
				// else if (FlxMath.inBounds(FlxG.mouse.x - gridBG.x, 0, gridBG.width)
				// 	&& FlxMath.inBounds(FlxG.mouse.y - gridBG.y, 0, (GRID_SIZE * getSectionBeats() * 4) * zoomList[curZoom]))
				else if (FlxG.mouse.x > gridBG.x
					&& FlxG.mouse.x < gridBG.x + gridBG.width
					&& FlxG.mouse.y > gridBG.y
					// && FlxG.mouse.y < gridBG.y + (GRID_SIZE * getSectionBeats() * 4) * zoomList[curZoom])
					&& FlxG.mouse.y < gridBG.y + gridBG.height)
				{
					addNote();
				}
			}
			// else if (canDragNote && FlxG.mouse.pressed)
			// {
			// }

			// if (curSelectedObj != null){
			// 	for (i in blockPressWhileScrolling) i.skipButtonUpdate = false;
			// 	for (i in blockPressWhileTypingOnStepper) i.skipButtonUpdate = false;
			// 	for (i in blockPressWhileTypingOn) i.hasFocus = false;
			// 	if (curSelectedObj is FlxUIInputText || curSelectedObj is FlxUIDropDownMenuCustom)
			// 		curSelectedObj.skipButtonUpdate = true;
			// 	else
			// 		// if (curSelectedObj is FlxUIInputText)
			// 			curSelectedObj.hasFocus = true;
			// }
			if (FlxG.sound.keysAllowed)
			{
				// curSelectedObj = null;
				if (FlxG.keys.justPressed.N)
				{
					check_mustHitSection.checked = _song.notes[curSec].mustHitSection = !_song.notes[curSec].mustHitSection;
					swapSection.onUp.fire();
					updateHeads();
					#if desktop
					updateWaveform();
					#end
				}

				if (FlxG.keys.justPressed.ENTER)
				{
					autosaveSong();
					FlxG.mouse.visible = false;
					PlayState.SONG = _song;
					FlxG.sound.music.stop();
					for (i in vocals)
						i.stop();
					if (FlxG.keys.pressed.SHIFT) botPlayChartMod = true;
					// if(_song.stage == null) _song.stage = stageDropDown.selectedLabel;
					StageData.loadDirectory(_song);
					goback = true;
					LoadingState.loadAndSwitchState(new PlayState());
				}

				if (curSelectedNote != null && curSelectedNote[1] > -1)
				{
					if (FlxG.keys.justPressed.E)
						changeNoteSustain(Conductor.stepCrochet);

					if (FlxG.keys.justPressed.Q)
						changeNoteSustain(-Conductor.stepCrochet);
				}

				if (FlxG.keys.justPressed.BACKSPACE)
				{
					/*
					// if(onMasterEditor) {
					updatethat = false;
					var box:TextBox = new TextBox("Leave from Chart Editor?", true, "yesOrNot", 0.7, "GRAY", ["no", "yes"]);
					box.screenCenter(X);
					//box.y += 90;
					box.y += camPos.y - FlxG.height / 5;
					box.x -= (strumLine.x + CAM_OFFSET) / 1.25;
					add(box);
					box.sounds = box.flicker = box.transes = false;
					box.time = 0;
					FlxG.sound.music.pause();
					for (i in vocals) i.pause();
					box.arrayFunction[0] = function():Void{
						updatethat = true;
					}
					box.arrayFunction[1] = function():Void{
						MusicBeatState.switchState(new MasterEditorMenu());
						FlxG.sound.playMusic(Paths.music('freakyMenu'));
						FlxG.mouse.visible = false;
					}
					// }
					*/
					goback = true;
					FlxG.sound.music.pause();
					for (i in vocals)
					{
						i.pause();
						i.time = FlxG.sound.music.time;
					}
					PlayState.chartingMode = false;
					MusicBeatState.switchState(new MasterEditorMenu());
					return;
				}

				if (FlxG.keys.justPressed.Z && curZoom > 0)
				{
					--curZoom;
					updateZoom();
				}
				if (FlxG.keys.justPressed.X && curZoom < zoomList.length - 1)
				{
					++curZoom;
					updateZoom();
				}

				if (FlxG.keys.justPressed.TAB)
				{
					UI_box.selected_tab = FlxMath.wrap(UI_box.selected_tab + (FlxG.keys.pressed.SHIFT ? -1 : 1), 0, UI_box.numTabs - 1);
					/*
					if (FlxG.keys.pressed.SHIFT)
					{
						UI_box.selected_tab--;
						if (UI_box.selected_tab < 0)
							UI_box.selected_tab = UI_box.numTabs - 1;
					}
					else
					{
						UI_box.selected_tab++;
						if (UI_box.selected_tab >= UI_box.numTabs - 1)
							UI_box.selected_tab = 0;
					}
					*/
				}
				if (FlxG.keys.justPressed.SPACE)
				{
					if (FlxG.sound.music.playing)
					{
						FlxG.sound.music.pause();
						for (i in vocals)
						{
							i.pause();
						}
					}
					else
					{
						for (i in vocals)
						{
							i.play(true, FlxG.sound.music.time);
						}
						FlxG.sound.music.play();
					}
				}

				if (FlxG.keys.justPressed.R)
					resetSection(FlxG.keys.pressed.SHIFT);

				if (FlxG.mouse.wheel != 0)
				{
					FlxG.sound.music.pause();
					if (!mouseQuant)
					{
						FlxG.sound.music.time -= (FlxG.mouse.wheel * Conductor.stepCrochet * 0.8);
					}
					else
					{
						final snap:Float = quantization / 4;
						final increase:Float = 1 / snap;
						FlxG.sound.music.time = Conductor.beatToSeconds(CoolUtil.quantize(curDecBeat, snap) - FlxG.mouse.wheel * increase);
					}
					for (i in vocals)
					{
						i.pause();
						i.time = FlxG.sound.music.time;
					}
				}

				// ARROW VORTEX SHIT NO DEADASS

				if (FlxG.keys.pressed.W || FlxG.keys.pressed.S)
				{
					FlxG.sound.music.pause();

					var holdingShift:Float = 1;
					if (FlxG.keys.pressed.CONTROL)
						holdingShift = 0.25;
					else if (FlxG.keys.pressed.SHIFT)
						holdingShift = 4;

					final daTime:Float = 700 * elapsed * holdingShift;

					if (FlxG.keys.pressed.W)
						FlxG.sound.music.time -= daTime;
					else
						FlxG.sound.music.time += daTime;

					for (i in vocals)
					{
						i.pause();
						i.time = FlxG.sound.music.time;
					}
				}

				if (!vortex)
				{
					if (FlxG.keys.justPressed.UP || FlxG.keys.justPressed.DOWN)
					{
						FlxG.sound.music.pause();
						updateCurStep();
						final beat:Float = curDecBeat;
						final snap:Float = quantization / 4;
						final increase:Float = 1 / snap;
						if (FlxG.keys.pressed.UP)
							FlxG.sound.music.time = Conductor.beatToSeconds(CoolUtil.quantize(beat, snap) - increase);
						else
							FlxG.sound.music.time = Conductor.beatToSeconds(CoolUtil.quantize(beat, snap) + increase);
					}
				}

				var style = (FlxG.keys.pressed.SHIFT ? 3 : currentType);

				// AWW YOU MADE IT SEXY <3333 THX SHADMAR
				if (FlxG.keys.justPressed.P){
					curQuant++;
					if (curQuant > quantizations.length - 1)
						curQuant = 0;

					quantization = quantizations[curQuant];
				}
				if (FlxG.keys.justPressed.O){
					curQuant--;
					if (curQuant < 0)
						curQuant = quantizations.length - 1;

					quantization = quantizations[curQuant];
				}
				if (vortex)
				{
					var controlArray:Array<Bool> = [
						FlxG.keys.justPressed.ONE, FlxG.keys.justPressed.TWO, FlxG.keys.justPressed.THREE, FlxG.keys.justPressed.FOUR,
						FlxG.keys.justPressed.FIVE, FlxG.keys.justPressed.SIX, FlxG.keys.justPressed.SEVEN, FlxG.keys.justPressed.EIGHT
					];

					if (controlArray.contains(true))
						for (i in 0...controlArray.length)
							if (controlArray[i])
								doANoteThing(Conductor.songPosition, i, style);

					if (FlxG.keys.justPressed.UP || FlxG.keys.justPressed.DOWN)
					{
						FlxG.sound.music.pause();

						updateCurStep();
						// FlxG.sound.music.time = (Math.round(curStep/quants[curQuant])*quants[curQuant]) * Conductor.stepCrochet;

						// (Math.floor((curStep+quants[curQuant]*1.5/(quants[curQuant]/2))/quants[curQuant])*quants[curQuant]) * Conductor.stepCrochet;//snap into quantization
						final snap:Float = quantization / 4;
						final feces:Float = Conductor.beatToSeconds(CoolUtil.quantize(curDecBeat, snap) + ((FlxG.keys.pressed.UP ? -1 : 1) / snap));
						FlxG.sound.music.time = feces;
						// FlxTween.tween(FlxG.sound.music, {time: feces}, 0.1, {ease: FlxEase.circOut}); // what a fuck
						for (i in vocals)
						{
							i.pause();
							i.time = FlxG.sound.music.time;
						}

						final secStart:Float = sectionStartTime();
						final datime = (feces - secStart) - (((curSelectedNote != null) ? curSelectedNote[0] : 0) - secStart);
						// idk math find out why it doesn't work on any other section other than 0
						if (curSelectedNote != null)
						{
							final controlArray:Array<Bool> = [
								 FlxG.keys.pressed.ONE, FlxG.keys.pressed.TWO, FlxG.keys.pressed.THREE, FlxG.keys.pressed.FOUR,
								FlxG.keys.pressed.FIVE, FlxG.keys.pressed.SIX, FlxG.keys.pressed.SEVEN, FlxG.keys.pressed.EIGHT
							];

							if (controlArray.contains(true))
							{
								for (i in 0...controlArray.length)
								{
									if (curSelectedNote[1] == i && controlArray[i])
									{
										curSelectedNote[2] += datime - curSelectedNote[2] - Conductor.stepCrochet;
									}
								}
								updateGrid();
								updateNoteUI();
							}
							controlArray.clearArray();
						}
					}
					controlArray.clearArray();
				}

				final shiftThing:Int = FlxG.keys.pressed.SHIFT ? 4 : 1;

				if (FlxG.keys.justPressed.D)
					changeSection(curSec + shiftThing);
				if (FlxG.keys.justPressed.A)
					if (curSec <= 0)
						changeSection(_song.notes.length - 1);
					else
						changeSection(curSec - shiftThing);
			}
			else if (FlxG.keys.justPressed.ENTER)
			{
				for (i in listOfInput)
					if (i.hasFocus)
					{
						FlxG.sound.keysAllowed = true;
						i.hasFocus = false;
						break;
					}
			}

			strumLineNotes.visible = vortex;

			if (FlxG.sound.music.time < 0){
				FlxG.sound.music.pause();
				FlxG.sound.music.time = 0;
			}else if (FlxG.sound.music.time > FlxG.sound.music.length){
				FlxG.sound.music.pause();
				FlxG.sound.music.time = 0;
				changeSection();
			}
			Conductor.songPosition = FlxG.sound.music.getCurrentTime();
			strumLineUpdateY();
			camPos.y = strumLine.y;
			var alpha = FlxG.sound.music.playing ? 1 : 0.35;
			for (i in strumLineNotes)
			{
				i.y = strumLine.y;
				i.alpha = alpha;
			}

			#if FLX_PITCH
			// PLAYBACK SPEED CONTROLS //
			var holdingShift = FlxG.keys.pressed.SHIFT;
			var holdingLB = FlxG.keys.pressed.LBRACKET;
			var holdingRB = FlxG.keys.pressed.RBRACKET;
			var pressedLB = FlxG.keys.justPressed.LBRACKET;
			var pressedRB = FlxG.keys.justPressed.RBRACKET;

			if (!holdingShift && pressedLB || holdingShift && holdingLB)
				playbackSpeed -= (holdingShift ? Math.max(elapsed, 0.1) : 0.1);
			if (!holdingShift && pressedRB || holdingShift && holdingRB)
				playbackSpeed += (holdingShift ? Math.max(elapsed, 0.1) : 0.1);
			if (FlxG.keys.pressed.ALT && (pressedLB || pressedRB || holdingLB || holdingRB))
				playbackSpeed = 1;

			playbackSpeed = FlxMath.bound(playbackSpeed, 0.5, 3);

			FlxG.sound.music.pitch = vocal.pitch = vocalBF.pitch = playbackSpeed;
			#end

			// static var playedSound:Array<Bool> = [false, false, false, false]; // Prevents ouchy GF sex sounds
			curRenderedNotes.forEachAlive(function(note:EditorNote)
			{
				if (curSelectedNote != null)
				{
					final noteDataToCheck:Int = (note.noteData > -1 && note.mustPress != _song.notes[curSec].mustHitSection) ? note.noteData + 4 : note.noteData;

					if (curSelectedNote[0] == note.strumTime && ((curSelectedNote[2] == null && noteDataToCheck < 0)
						|| (curSelectedNote[2] != null && curSelectedNote[1] == noteDataToCheck)))
					{
						colorSine += elapsed;
						final colorVal:Float = 0.7 + Math.sin(Math.PI * colorSine) * 0.3;
						flixel.util.FlxColorTransformUtil.setMultipliers(note.colorTransform, colorVal, colorVal, colorVal, note.colorTransform.alphaMultiplier);
					}
				}

				if (note.strumTime <= Conductor.songPosition)
				{
					if (note.alpha == 1 && FlxG.sound.music.playing && note.noteData > -1)
					{
						// final noteDataToCheck:Int = note.mustPress != _song.notes[curSec].mustHitSection ? note.noteData + 4 : note.noteData;
						// final noteDataToCheck:Int = note.noteData % 4;
						final strumLine = strumLineNotes.members[note.mustPress ? note.noteData + 4 : note.noteData];
						strumLine.playAnim('confirm', true);
						strumLine.resetAnim = ((note.sustainLength / 1000) + 0.15) / playbackSpeed;
						// if (!playedSound[data]){
							if ((playSoundBf.checked && note.mustPress) || (playSoundDad.checked && !note.mustPress))
							{
								FlxG.sound.play(Paths.sound('hitsound'), (note.mustPress ? bfPressVolume : dadPressVolume).value).pan = note.noteData < 4 ? -0.35 : 0.35;
								// would be coolio
								// playedSound[data] = true;
							}

							// lol
							// data = note.noteData;
							// if (note.mustPress != _song.notes[curSec].mustHitSection) data += 4;
						// }
					}
					note.alpha = 0.4;
				}
				else
				{
					note.alpha = 1;
				}
			});
			// for(i in 0...playedSound.length) playedSound[i] = false;

			//if (lastConductorPos != Conductor.songPosition)
				updateInfoText();
			if(FlxG.sound.music.playing)
			{
				var s = curDecBeat % 1 * .25;
				s *= 1 - s * 0.25 * leftIcon.data.bobInsetity;
				leftIcon.scale.x = leftIcon.scale.y = (leftIcon.baseScale * leftIcon.data.scale + s) * .5;
				if (metronome.checked && lastConductorPos != Conductor.songPosition)
				{
					var metroInterval:Float = 60 / metronomeStepper.value;
					var metroStep:Int = Math.floor(((Conductor.songPosition + metronomeOffsetStepper.value) / metroInterval) / 1000);
					var lastMetroStep:Int = Math.floor(((lastConductorPos + metronomeOffsetStepper.value) / metroInterval) / 1000);
					if (metroStep != lastMetroStep)
					{
						FlxG.sound.play(Paths.sound('Metronome_Tick'));
						// trace('Ticked');
					}
				}
			}
			else
			{
				leftIcon.scale.x = leftIcon.scale.y = leftIcon.baseScale * leftIcon.data.scale * .5;
			}
			rightIcon.scale.x = rightIcon.scale.y = rightIcon.baseScale * rightIcon.data.scale * .5;
			leftIcon.updateOffsets();
			rightIcon.updateOffsets();
			lastConductorPos = Conductor.songPosition;
		}
		super.update(elapsed);
	}

	inline function updateInfoText()
	{
		bpmTxt.text = 'Song: ${_song.song}
		${
			FlxStringUtil.formatTime(FlxMath.roundDecimal(Conductor.songPosition / 1000, 2), true)
		} / ${
			FlxStringUtil.formatTime(FlxMath.roundDecimal(FlxG.sound.music.length / 1000, 2), true)
		}
		Section: $curSec
		Beat: $curBeat
		Step: $curStep
		Beat Snap: ${quantization}th';
	}

	function updateZoom()
	{
		final daZoom:Float = zoomList[curZoom];
		var zoomThing:String = '1 / $daZoom';
		if (daZoom < 1)
			zoomThing = '${Math.round(1 / daZoom)} / 1';
		zoomTxt.text = 'Zoom: $zoomThing';
		reloadGridLayer();
	}

	/*
	function loadAudioBuffer() {
		if(audioBuffers[0] != null) {
			audioBuffers[0].dispose();
		}
		audioBuffers[0] = null;
		var leVocals:String = Paths.getPath(currentSongName + '/Inst.' + Paths.SOUND_EXT, SOUND, 'songs');
		if (OpenFlAssets.exists(leVocals)) { //Vanilla inst
			audioBuffers[0] = AudioBuffer.fromFile('./' + leVocals.substr(6));
			//trace('Inst found');
		}

		if(audioBuffers[1] != null) {
			audioBuffers[1].dispose();
		}
		audioBuffers[1] = null;
		var leVocals:String = Paths.getPath(currentSongName + '/Voices.' + Paths.SOUND_EXT, SOUND, 'songs');
		if (OpenFlAssets.exists(leVocals)) { //Vanilla voices
			audioBuffers[1] = AudioBuffer.fromFile('./' + leVocals.substr(6));
			//trace('Voices found, LETS FUCKING GOOOO');
		}
	}
	*/

	function reloadBPMChanges()
	{
		// adjust note placement
		var len = _song.notes.length;
		var curSecReal:Int = curSec;
		var curSongPosition = Conductor.songPosition;

		var sectionStart:Float;
		var sectionEnd:Float;
		var section:SwagSection;
		var time:Float;

		for (_ in 0...2)
		{
			for (i in 0...len)
			// for (i in curSecReal...len)
			{
				// should fix presicion problems (istg)
				inline function round(t:Float):Float
					return FlxMath.roundDecimal(t, 4);

				curSec = i;
				sectionStart = round(sectionStartTime());
				sectionEnd = round(sectionStartTime(1));
				section = _song.notes[i];
				for (_ in 0...2)
				{
					for (note in section.sectionNotes)
					{
						if (note[1] == -1)
							continue;

						inline function moveNote(note:Array<Dynamic>, from:SwagSection, to:SwagSection)
						{
							to.sectionNotes.push(note);
							from.sectionNotes.remove(note);
							if (from.mustHitSection != to.mustHitSection)
								note[1] = (note[1] + 4) % 8;
						}

						time = round(note[0]);
						if (time >= sectionEnd) // move note to the next section
						{
							var nextIndex:Int = i + 1;
							if (nextIndex == _song.notes.length)
								addSection(section.sectionBeats);

							moveNote(note, section, _song.notes[nextIndex]);
						}
						else if (time < sectionStart) // move note to the previous section
						{
							moveNote(note, section, _song.notes[i - 1]);
						}
					}
				}
			}
		}
		curSec = curSecReal;
		Conductor.songPosition = curSongPosition;
		reloadGridLayer();
	}

	var lastSecBeats:Float = 0;
	var lastSecBeatsNext:Float = 0;

	function reloadGridLayer()
	{
		gridLayer.forEachAlive(obj -> obj.destroy()); // добить вышивших
		gridLayer.clear();
		var curSectionsLength:Float = getSectionBeats();
		gridBG = FlxGridOverlay.create(GRID_SIZE, GRID_SIZE, GRID_SIZE * 9, Std.int(GRID_SIZE * curSectionsLength * 4 * zoomList[curZoom]));
		#if desktop
		updateWaveform();
		#end

		var leHeight:Int = Std.int(gridBG.height);
		var foundNextSec:Bool = sectionStartTime(1) <= FlxG.sound.music.length;
		if (foundNextSec)
		{
			nextGridBG = FlxGridOverlay.create(GRID_SIZE, GRID_SIZE, GRID_SIZE * 9, Std.int(GRID_SIZE * getSectionBeats(curSec + 1) * 4 * zoomList[curZoom]));
			leHeight = Std.int(gridBG.height + nextGridBG.height);
		}
		else
		{
			nextGridBG = new FlxSprite().makeGraphic(1, 1, FlxColor.TRANSPARENT);
		}
		nextGridBG.y = gridBG.height;

		blackLinesLayer.forEachAlive(spr -> spr.scale.y = leHeight);

		gridLayer.add(nextGridBG);
		gridLayer.add(gridBG);

		if (foundNextSec)
		{
			var gridBlack:FlxSprite = new FlxSprite(0, gridBG.height).makeGraphic(Std.int(gridBG.width), Std.int(nextGridBG.height), FlxColor.BLACK);
			gridBlack.alpha = 0.4;
			gridLayer.add(gridBlack);
		}
		updateStrumNotesPositions();

		updateGrid();
		if (vortex)
			for (i in 1...Math.round(curSectionsLength))
				gridLayer.add(new FlxSprite(gridBG.x, GRID_SIZE * zoomList[curZoom] * 4 * i).makeGraphic(Std.int(gridBG.width), 3, 0x44FF0000));

		lastSecBeats = curSectionsLength;
		if (sectionStartTime(1) > FlxG.sound.music.length)
			lastSecBeatsNext = 0;
		else
			lastSecBeatsNext = getSectionBeats(curSec + 1);
	}

	inline function strumLineUpdateY()
		strumLine.y = getYfromStrum(
				(Conductor.songPosition - sectionStartTime())
					/ zoomList[curZoom]
					% (Conductor.stepCrochet * 16)
			) / (getSectionBeats() / 4);

	var preGPUCashing:Bool;

	override function destroy()
	{
		FlxG.sound.music.pitch = 1;
		ClientPrefs.cacheOnGPU = preGPUCashing;
		lime.app.Application.current.window.onDropFile.remove(LoadFromFile);
		@:privateAccess { // huh
			for (i in vocals)
				FlxG.sound.destroySound(i);
		}
		// WindowUtil.onClosing = null;
		WindowUtil.resetTitle();
		super.destroy();
	}

	var bfData:CharacterFile;
	var dadData:CharacterFile;
	var gfData:CharacterFile;

	inline function loadFromCharacter(char:String)
		return Character.resolveCharacterData(char, false, true);

	function updateChars()
	{
		bfData = loadFromCharacter(_song.player1);
		dadData = loadFromCharacter(_song.player2);
		gfData = loadFromCharacter(_song.gfVersion);
		updateHeads();
	}
	var waveformPrinted:Bool = true;

	var lastWaveformHeight:Int = 0;
	function updateWaveform()
	{
		#if desktop
		if (waveformPrinted)
		{
			var width:Int = Std.int(GRID_SIZE * 8);
			var height:Int = Std.int(gridBG.height);

			// DropEventInfo


			var _defaultPersist = flixel.graphics.FlxGraphic.defaultPersist;
			flixel.graphics.FlxGraphic.defaultPersist = false;
			for (obj in [waveformInstSprite, waveformBoyfriendSprite, waveformDadSprite, waveformVoicesSprite])
			{
				// if(lastWaveformHeight != height && obj.pixels != null){
				// 	obj.pixels.image.data = null;
				// 	obj.pixels.dispose();
				// 	obj.pixels.disposeImage();
				// 	obj.makeGraphic(width, lastWaveformHeight = height, 0x00FFFFFF);
				// }
				obj.makeGraphic(width, lastWaveformHeight = height, 0x00FFFFFF);
				obj.pixels.fillRect(new Rectangle(0, 0, gridBG.width, gridBG.height), 0x00ffffff);
				obj.graphic.destroyOnNoUse = true;
			}
			flixel.graphics.FlxGraphic.defaultPersist = _defaultPersist;
		}
		waveformPrinted = false;

		if ((waveformUseInstrumental == null || !waveformUseInstrumental.checked) && (waveformUseVoices == null || !waveformUseVoices.checked))
		{
			// trace('Epic fail on the waveform lol');
			return;
		}

		var steps:Int = Math.round(getSectionBeats() * 4);
		var st:Float = sectionStartTime();
		var et:Float = st + (Conductor.stepCrochet * steps);

		var wavsUsers:Array<String> = [];
		if (waveformUseInstrumental != null && waveformUseInstrumental.checked)
			wavsUsers.push('inst');

		if (waveformUseVoices != null && waveformUseVoices.checked)
			if (vocals.length > 1 || (vocals[1] != null && vocals[1].isValid()))
			{
				wavsUsers.push('bf');
				wavsUsers.push('dad');
			}
			else
			{
				wavsUsers.push('voices');
			}

		for (typeOfSong in wavsUsers)
		{
			var wavData:Array<Array<Array<Float>>> = [[[0], [0]], [[0], [0]]];

			var diraction:Float = 0;
			var waveformPixels:BitmapData;

			// Draws
			final gSize:Int = Std.int(GRID_SIZE * 8);
			final hSize:Int = Std.int(gSize / 2);

			var size:Float = 2;
			var colocSwag:FlxColor;
			var sound:FlxSound;
			switch (typeOfSong) {
				case 'dad':
					waveformPixels = waveformDadSprite.pixels;
					diraction = _song.notes[curSec].mustHitSection ? 1 : -1;
					var preCharacter = _song.notes[curSec].gfSection && !_song.notes[curSec].mustHitSection ? gfData : dadData;
					colocSwag = FlxColor.fromRGB(preCharacter.healthbar_colors[0], preCharacter.healthbar_colors[1], preCharacter.healthbar_colors[2]);
					sound = vocals[0];
					size /= 1.75;
				case 'voices':
					waveformPixels = waveformVoicesSprite.pixels;
					colocSwag = 0x8809FF00;
					sound = vocals[0];
				case 'bf':
					waveformPixels = waveformBoyfriendSprite.pixels;
					diraction = _song.notes[curSec].mustHitSection ? -1 : 1;
					var preCharacter = _song.notes[curSec].gfSection && _song.notes[curSec].mustHitSection ? gfData : bfData;
					colocSwag = FlxColor.fromRGB(preCharacter.healthbar_colors[0], preCharacter.healthbar_colors[1], preCharacter.healthbar_colors[2]);
					sound = vocals[1];
					size /= 1.75;
				default:
					waveformPixels = waveformInstSprite.pixels;
					sound = FlxG.sound.music;
					colocSwag = 0x88914b22;
			}
			if (sound._sound != null && sound._sound.__buffer != null){
				final bytes:Bytes = sound._sound.__buffer.data.toBytes();

				wavData = waveformData(sound._sound.__buffer, bytes, st, et, 1, wavData, Std.int(gridBG.height));
			}

			final leftLength:Int = (wavData[0][0].length > wavData[0][1].length ? wavData[0][0].length : wavData[0][1].length);

			final rightLength:Int = (wavData[1][0].length > wavData[1][1].length ? wavData[1][0].length : wavData[1][1].length);

			final length:Int = FlxMath.maxInt(leftLength, rightLength);

			for (i in 0...length){

				final lmin = FlxMath.bound(((i < wavData[0][0].length && i >= 0) ? wavData[0][0][i] : 0) * gSize, -hSize, hSize) / 4.48;
				final lmax = FlxMath.bound(((i < wavData[0][1].length && i >= 0) ? wavData[0][1][i] : 0) * gSize, -hSize, hSize) / 4.48;

				final rmin = FlxMath.bound(((i < wavData[1][0].length && i >= 0) ? wavData[1][0][i] : 0) * gSize, -hSize, hSize) / 4.48;
				final rmax = FlxMath.bound(((i < wavData[1][1].length && i >= 0) ? wavData[1][1][i] : 0) * gSize, -hSize, hSize) / 4.48;

				final min = lmin + rmin;
				final max = lmax + rmax;

				waveformPixels.fillRect(new Rectangle(
					Math.max(hSize - min * size + hSize / 2 * diraction, -1), // x position
					i,
					Math.min((min + max) * size, waveformPixels.width),
					1),
					colocSwag);
			}
			// switch (typeOfSong) {
			// 	case 'dad':
			// 		waveformBoyfriendSprite.pixels = waveformPixels;
			// 	case 'bf':
			// 		waveformDadSprite.pixels = waveformPixels;
			// 	case 'voices':
			// 		waveformVoicesSprite.pixels = waveformPixels;
			// 	default:
			// 		waveformInstSprite.pixels = waveformPixels;
			// }
		}

		waveformPrinted = true;
		#end
	}

	function waveformData(buffer:AudioBuffer, bytes:Bytes, time:Float, endTime:Float, multiply:Float = 1, ?array:Array<Array<Array<Float>>>,
			?steps:Float):Array<Array<Array<Float>>>
	{
		#if (lime_cffi && !macro)
		if (buffer == null || buffer.data == null)
			return array ?? [[[0], [0]], [[0], [0]]];

		var khz:Float = (buffer.sampleRate / 1000);
		var channels:Int = buffer.channels;

		var index:Int = Std.int(time * khz);

		var samples:Float = ((endTime - time) * khz);

		if (steps == null)
			steps = 1280;

		var samplesPerRow:Float = samples / steps;
		var samplesPerRowI:Int = Std.int(samplesPerRow);

		var gotIndex:Int = 0;

		var lmin:Float = 0;
		var lmax:Float = 0;

		var rmin:Float = 0;
		var rmax:Float = 0;

		var rows:Float = 0;

		var simpleSample:Bool = true; // samples > 17200;
		var v1:Bool = false;

		if (array == null)
			array = [[[0], [0]], [[0], [0]]];

		while (index < (bytes.length - 1))
		{
			if (index >= 0)
			{
				var byte:Int = bytes.getUInt16(index * channels * 2);

				if (byte > 65535 / 2)
					byte -= 65535;

				var sample:Float = (byte / 65535);

				if (sample > 0)
				{
					if (sample > lmax)
						lmax = sample;
				}
				else if (sample < 0)
				{
					if (sample < lmin)
						lmin = sample;
				}

				if (channels >= 2)
				{
					byte = bytes.getUInt16((index * channels * 2) + 2);

					if (byte > 65535 / 2)
						byte -= 65535;

					sample = (byte / 65535);

					if (sample > 0){
						if (sample > rmax)
							rmax = sample;
					}else if (sample < 0){
						if (sample < rmin)
							rmin = sample;
					}
				}
			}

			v1 = samplesPerRowI > 0 ? (index % samplesPerRowI == 0) : false;
			while (simpleSample ? v1 : rows >= samplesPerRow)
			{
				v1 = false;
				rows -= samplesPerRow;

				gotIndex++;

				var lRMin:Float = Math.abs(lmin) * multiply;
				var lRMax:Float = lmax * multiply;

				var rRMin:Float = Math.abs(rmin) * multiply;
				var rRMax:Float = rmax * multiply;

				if (gotIndex > array[0][0].length)
					array[0][0].push(lRMin);
				else
					array[0][0][gotIndex - 1] = array[0][0][gotIndex - 1] + lRMin;

				if (gotIndex > array[0][1].length)
					array[0][1].push(lRMax);
				else
					array[0][1][gotIndex - 1] = array[0][1][gotIndex - 1] + lRMax;

				if (channels >= 2)
				{
					if (gotIndex > array[1][0].length)
						array[1][0].push(rRMin);
					else
						array[1][0][gotIndex - 1] = array[1][0][gotIndex - 1] + rRMin;

					if (gotIndex > array[1][1].length)
						array[1][1].push(rRMax);
					else
						array[1][1][gotIndex - 1] = array[1][1][gotIndex - 1] + rRMax;
				}
				else
				{
					if (gotIndex > array[1][0].length)
						array[1][0].push(lRMin);
					else
						array[1][0][gotIndex - 1] = array[1][0][gotIndex - 1] + lRMin;

					if (gotIndex > array[1][1].length)
						array[1][1].push(lRMax);
					else
						array[1][1][gotIndex - 1] = array[1][1][gotIndex - 1] + lRMax;
				}

				lmin = 0;
				lmax = 0;

				rmin = 0;
				rmax = 0;
			}

			index++;
			rows++;
			if (gotIndex > steps)
				break;
		}

		return array;
		#else
		return array ?? [[[0], [0]], [[0], [0]]];
		#end
	}

	function changeNoteSustain(value:Float):Void
	{
		if (curSelectedNote != null && curSelectedNote[2] != null)
			curSelectedNote[2] = Math.max(curSelectedNote[2] + value, 0);

		updateNoteUI();
		updateGrid();
	}

	function recalculateSteps(add:Float = 0):Int{
		var lastChange:BPMChangeEvent = null;
		for (i in 0...Conductor.bpmChangeMap.length)
			if (FlxG.sound.music.time > Conductor.bpmChangeMap[i].songTime)
				lastChange = Conductor.bpmChangeMap[i];
		lastChange ??= {
			stepTime: 0,
			songTime: 0,
			bpm: 0
		}
		curStep = lastChange.stepTime + Math.floor((FlxG.sound.music.time - lastChange.songTime + add) / Conductor.stepCrochet);
		updateBeat();

		return curStep;
	}

	function resetSection(songBeginning:Bool = false):Void
	{
		updateGrid();

		FlxG.sound.music.pause();
		// Basically old shit from changeSection???
		FlxG.sound.music.time = sectionStartTime();

		if (songBeginning)
		{
			FlxG.sound.music.time = 0;
			curSec = 0;
		}

		for (i in vocals)
		{
			i.pause();
			i.time = FlxG.sound.music.time;
		}
		updateCurStep();

		updateGrid();
		updateSectionUI();
		updateWaveform();
	}

	function changeSection(sec:Int = 0, ?updateMusic:Bool = true):Void
	{
		if (_song.notes[sec] != null)
		{
			curSec = sec;
			if (updateMusic){
				FlxG.sound.music.pause();

				FlxG.sound.music.time = sectionStartTime();
				for (i in vocals)
				{
					i.pause();
					i.time = FlxG.sound.music.time;
				}
				updateCurStep();
			}

			var blah1:Float = getSectionBeats();
			var blah2:Float = getSectionBeats(curSec + 1);
			if (sectionStartTime(1) > FlxG.sound.music.length)
				blah2 = 0;

			if (blah1 != lastSecBeats || blah2 != lastSecBeatsNext)
				reloadGridLayer();
			else
				updateGrid();

			updateSectionUI();
		}
		else
		{
			changeSection();
		}
		Conductor.songPosition = FlxG.sound.music.time;
		updateWaveform();
	}

	var _lastBMP = -1;
	function updateSectionUI():Void
	{
		var sec = _song.notes[curSec];

		stepperBeats.value = getSectionBeats();
		check_mustHitSection.checked = sec.mustHitSection;
		check_gfSection.checked = sec.gfSection;
		check_altAnim.checked = sec.altAnim;
		check_changeBPM.checked = sec.changeBPM;
		stepperSectionBPM.value = sec.bpm;

		updateHeads();
	}

	inline function updateHeads():Void
	{
		var curSection = _song.notes[curSec];
		if (curSection == null) return;
		if (curSection.mustHitSection)
		{
			rightIcon.changeIcon(dadData.healthicon);
			leftIcon.changeIcon(curSection.gfSection ? gfData.healthicon : bfData.healthicon);
		}
		else
		{
			rightIcon.changeIcon(bfData.healthicon);
			leftIcon.changeIcon(curSection.gfSection ? gfData.healthicon : dadData.healthicon);
		}
	}

	function updateNoteUI():Void
	{
		if (curSelectedNote != null)
		{
			if (curSelectedNote[2] != null)
			{
				stepperSusLength.value = curSelectedNote[2];
				if (curSelectedNote[3] != null)
				{
					currentType = noteTypeMap.get(curSelectedNote[3]);
					if (currentType <= 0)
						noteTypeDropDown.selectedLabel = '';
					else
						noteTypeDropDown.selectedLabel = currentType + '. ' + curSelectedNote[3];
				}
			}
			else
			{
				eventDropDown.selectedLabel = curSelectedNote[1][curEventSelected][0];
				var selected:Int = Std.parseInt(eventDropDown.selectedId);
				if (selected > 0 && selected < eventStuff.length)
				{
					descText.text = eventStuff[selected][1];
					updateDescTextBG();
				}
				value1InputText.text = curSelectedNote[1][curEventSelected][1];
				value2InputText.text = curSelectedNote[1][curEventSelected][2];
				value3InputText.text = curSelectedNote[1][curEventSelected][3] ?? '';
			}
			strumTimeInputText.text = '' + curSelectedNote[0];
		}
	}

	function createTextForNoteTypes():AttachedFlxText
	{
		var daText = new AttachedFlxText(0, 0, 0, '');
		daText.borderSize = 1;
		return daText;
	}

	function updateGrid():Void
	{
		_song.events ??= [];
		curRenderedNotes.forEachAlive(spr -> spr.destroy()); // добить вышивших
		curRenderedSustains.forEachAlive(spr -> spr.destroy()); // добить вышивших
		curRenderedNoteType.forEachAlive(spr -> spr.kill()); // оглушить вышивших
		nextRenderedNotes.forEachAlive(spr -> spr.destroy()); // добить вышивших
		nextRenderedSustains.forEachAlive(spr -> spr.destroy()); // добить вышивших
		curRenderedNotes.clear();
		curRenderedSustains.clear();
		nextRenderedNotes.clear();
		nextRenderedSustains.clear();

		var curSectionData = _song.notes[curSec];
		if (curSectionData == null)
			return;

		if (curSectionData.changeBPM && curSectionData.bpm > 0)
		{
			Conductor.bpm = curSectionData.bpm;
			// trace('BPM of this section:');
		}
		else
		{
			// get last bpm
			var daBPM:Float = _song.bpm;
			for (i in 0...curSection)
				if (_song.notes[i]?.changeBPM)
					daBPM = _song.notes[i].bpm;
			Conductor.bpm = daBPM;
		}

		// CURRENT SECTION
		var beats:Float = getSectionBeats();
		for (i in curSectionData.sectionNotes)
		{
			var note:EditorNote = setupNoteData(i, false);
			curRenderedNotes.add(note);
			if (note.sustainLength > 0)
				curRenderedSustains.add(setupSusNote(note, beats));

			if (i[3] != null && note.noteType != null && note.noteType.length > 0)
			{
				final typeInt:Null<Int> = noteTypeMap.get(i[3]);

				var daText:AttachedFlxText = curRenderedNoteType.recycle(AttachedFlxText, createTextForNoteTypes);
				daText.setFormat(null, 10, FlxColor.BLACK, CENTER, FlxTextBorderStyle.OUTLINE_FAST, FlxColor.WHITE);
				daText.text = (typeInt == null ? '?\n' : '$typeInt\n') + i[3];
				daText.sprTracker = note;
				daText.borderSize = 1;
				daText.xAdd = (GRID_SIZE - daText.width)  / 2;
				daText.yAdd = (GRID_SIZE - daText.height) / 2;
			}
			note.mustPress = curSectionData.mustHitSection;
			if (i[1] > 3) note.mustPress = !note.mustPress;
		}

		// CURRENT EVENTS
		if (_song.events != null)
		{
			final startThing:Float = sectionStartTime();
			final endThing:Float = sectionStartTime(1);
			for (i in _song.events)
				if (endThing > i[0] && i[0] >= startThing)
				{
					var note:EditorNote = setupNoteData(i, false);
					curRenderedNotes.add(note);

					var eventLength:Null<Float> = note.extraData['eventLength'];
					var text:String = (
						(eventLength == null || eventLength == 1) ?
							'Event: ' + note.extraData['eventName']
									+ ' (' + Math.floor(note.strumTime) + ' ms)'
							+ '\nValue 1: ' + note.extraData['eventVal1']
							+ '\nValue 2: ' + note.extraData['eventVal2']
							+ '\nValue 3: ' + note.extraData['eventVal3']
						:
						eventLength + ' Events:\n' + note.extraData['eventName']
					);
					var daText:AttachedFlxText = curRenderedNoteType.recycle(AttachedFlxText, createTextForNoteTypes);
					daText.setFormat(null, 10, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE_FAST, FlxColor.BLACK);
					daText.text = text;
					daText.sprTracker = note;
					daText.xAdd = -daText.width - 10;
					daText.yAdd = 0;
					// if (eventLength!= null && eventLength > 1)
					// 	daText.yAdd += 8;
					// trace('test: ' + i[0], 'startThing: ' + startThing, 'endThing: ' + endThing);
				}
		}
		// NEXT SECTION
		final beats:Float = getSectionBeats(1);
		if (curSec < _song.notes.length - 1)
		{
			for (i in _song.notes[curSec + 1].sectionNotes)
			{
				final note:EditorNote = setupNoteData(i, true);
				note.alpha = 0.6;
				nextRenderedNotes.add(note);
				if (note.sustainLength > 0)
					nextRenderedSustains.add(setupSusNote(note, beats));
			}

			// NEXT EVENTS
			final startThing:Float = sectionStartTime(1);
			final endThing:Float = sectionStartTime(2);
			if (_song.events != null)
				for (i in _song.events)
					if (endThing > i[0] && i[0] >= startThing)
					{
						var note:EditorNote = setupNoteData(i, true);
						note.alpha = 0.6;
						nextRenderedNotes.add(note);
					}
		}
		updateStrumNotesPositions();
	}

	function setupNoteData(i:Array<Dynamic>, isNextSection:Bool):EditorNote
	{
		var daNoteInfo = i[1];
		final daSus:Dynamic = i[2];

		var curSecData = _song.notes[isNextSection ? curSec + 1 : curSec];
		final gottaHitNote:Bool = i[1] < 4 ? curSecData.mustHitSection : !curSecData.mustHitSection;
		final note:EditorNote = new EditorNote(i[0], daNoteInfo % 4, gottaHitNote, Constants.DEFAULT_TYPE_NOTE);
		if (daSus == null) // Event note
		{
			note.loadGraphic(Paths.image('eventArrow'));
			note.extraData['eventName'] = getEventName(i[1]);
			note.extraData['eventLength'] = i[1].length;
			if (i[1].length == 1)
			{
				note.extraData['eventVal1'] = i[1][0][1];
				note.extraData['eventVal2'] = i[1][0][2];
				var val3:Dynamic = i[1][0][3];
				if (val3 == null || val3 == "null")
					val3 = null;
				note.extraData['eventVal3'] = val3;
			}
			note.noteDataReal = note.noteData = -1;
			daNoteInfo = -1;
		}
		else // Common note
		{
			if (!Std.isOfType(i[3], String)) // Convert old note type to new note type format
				i[3] = noteTypeIntMap.get(i[3]);
			if (i.length > 3 && (i[3] == null || i[3].length < 1))
				i.remove(i[3]);
			note.sustainLength = daSus;
			note.noteType = i[3];
		}

		note.setGraphicSize(GRID_SIZE);
		note.updateHitbox();
		note.x = Math.ffloor(daNoteInfo * GRID_SIZE) + GRID_SIZE;
		if (isNextSection && curSecData.mustHitSection != _song.notes[curSec].mustHitSection)
			if (daNoteInfo > 3)
				note.x -= GRID_SIZE * 4;
			else if (daSus != null)
				note.x += GRID_SIZE * 4;

		note.y = getYfromStrumNotes(i[0] - sectionStartTime(), getSectionBeats(isNextSection ? 1 : 0));
		// if(isNextSection) note.y += gridBG.height;
		return note;
	}

	function getEventName(names:Array<Dynamic>):String
	{
		var retStr:String = '';
		var addedOne:Bool = false;
		for (i in 0...names.length){
			if (addedOne)
				retStr += ', ';
			retStr += names[i][0];
			addedOne = true;
		}
		return retStr;
	}

	var arrowSustains = [0xFF9B3B79, 0xFF04A0A0, 0xFF0BB502, 0xFFA5262B];
	function setupSusNote(note:EditorNote, beats:Float):FlxSprite
	{
		var height:Int = Math.floor(
			FlxMath.remapToRange(note.sustainLength, 0, Conductor.stepCrochet * 16, 0, GRID_SIZE * 16 * zoomList[curZoom])
			+ (GRID_SIZE * zoomList[curZoom]) - GRID_SIZE / 2
		);
		final minHeight:Int = Std.int((GRID_SIZE * zoomList[curZoom] / 2) + GRID_SIZE / 2);
		if(height < minHeight) height = minHeight;
		// if(height < 1) height = 1; //Prevents error of invalid height

		var spr:FlxSprite = new FlxSprite(note.x + GRID_SIZE / 2 - 4, note.y + GRID_SIZE / 2).makeGraphic(8, 1, arrowSustains[note.noteData]);
		spr.origin.y = 0;
		spr.scale.y = height;
		spr.moves = false;
		if (note.noteType != "Hurt Note") spr.shader = note.shader;

		return spr;
	}

	private function addSection(sectionBeats:Float = 4):Void
	{
		final sec:SwagSection = {
			sectionBeats: sectionBeats,
			bpm: _song.bpm,
			changeBPM: false,
			mustHitSection: true,
			gfSection: false,
			sectionNotes: [],
			// is this ever used?
			// typeOfSection: 0,
			altAnim: false
		}

		_song.notes.push(sec);
	}

	function selectNote(note:EditorNote):Void
	{
		var noteDataToCheck:Int = note.noteData;

		if (noteDataToCheck > -1)
		{
			if (note.mustPress != _song.notes[curSec].mustHitSection)
				noteDataToCheck += 4;
			for (i in _song.notes[curSec].sectionNotes)
				if (i != curSelectedNote && i.length > 2 && i[0] == note.strumTime && i[1] == noteDataToCheck){
					curSelectedNote = i;
					break;
				}
		}
		else
		{
			for (i in _song.events)
				// if (i != curSelectedNote && i[0] == note.strumTime)
				if (i[0] == note.strumTime)
				{
					curSelectedNote = i;
					curEventSelected = Std.int(curSelectedNote[1].length) - 1;
					break;
				}
		}
		changeEventSelected();

		updateGrid();
		updateNoteUI();
	}

	function deleteNote(note:EditorNote):Void
	{
		var noteDataToCheck:Int = note.noteData;
		if (noteDataToCheck > -1 && note.mustPress != _song.notes[curSec].mustHitSection)
			noteDataToCheck += 4;

		if (note.noteData > -1) // Normal Notes
		{
			for (i in _song.notes[curSec].sectionNotes)
				if (i[0] == note.strumTime && i[1] == noteDataToCheck)
				{
					if (noteCheck(i)) // i == curSelectedNote
						curSelectedNote = null;
					// FlxG.log.add('FOUND EVIL NOTE');
					_song.notes[curSec].sectionNotes.remove(i);
					break;
				}
		}
		else // Events
		{
			for (i in _song.events)
				if (i[0] == note.strumTime)
				{
					if (noteCheck(i)) // i == curSelectedNote
					{
						curSelectedNote = null;
						changeEventSelected();
					}
					// FlxG.log.add('FOUND EVIL EVENT');
					_song.events.remove(i);
					break;
				}
		}
		updateGrid();
	}

	// sanity check cuz dynamics (uggghhhhh)
	function noteCheck(note:Array<Dynamic>):Bool
	{
		if (curSelectedNote == null /*|| note == null*/)
			return false;

		for (i in 0...curSelectedNote.length)
		{
			// trace(curSelectedNote[i], note[i], curSelectedNote[i] == note[i]);
			// o-oh, impostor!!! (help)
			if (curSelectedNote[i] != note[i])
				return false;
		}
		return true;
	}

	public function doANoteThing(cs, d, style)
	{
		var delnote = false;
		if (strumLineNotes.members[d].overlaps(curRenderedNotes))
		{
			curRenderedNotes.forEachAlive(function(note:EditorNote)
			{
				if (note.overlapsPoint(FlxPoint.weak(strumLineNotes.members[d].x + 1, strumLine.y + 1)) && note.noteData == d % 4)
				{
					// trace('tryin to delete note...');
					if (!delnote)
						deleteNote(note);
					delnote = true;
				}
			});
		}

		if (!delnote)
			addNote(cs, d, style);
	}

	function updateStrumNotesPositions()
	{
		if (strumLineNotes == null) return;
		var indexOffset:Int = 0;
		if (_song.notes[curSec]?.mustHitSection)
			indexOffset = 4;
		for (i => member in strumLineNotes)
		{
			member.x = GRID_SIZE * (i + 1 + (member.isPlayer ? -indexOffset : indexOffset));
		}
	}
	function reloadStrumNotes()
	{
		if (strumLineNotes == null) return;
		for (member in strumLineNotes)
		{
			member.texture = (
				(_song.arrowSkin != null && _song.arrowSkin.length > 1) ? _song.arrowSkin
				: Constants.DEFAULT_NOTE_SKIN
			);
			member.setGraphicSize(GRID_SIZE, GRID_SIZE);
			member.updateHitbox();
		}
	}

	function clearSong():Void
	{
		for (daSection in _song.notes)
			if (daSection.sectionNotes != null)
				daSection.sectionNotes.resize(0);

		updateGrid();
	}

	private function addNote(?strum:Null<Float>, ?data:Null<Int>, ?type:Null<Int>):Void
	{
		// curUndoIndex++;
		// var newsong = _song.notes;
		//	undos.push(newsong);
		final noteStrum = strum ?? getStrumTime(dummyArrow.y * getSectionBeats() / 4, false) + sectionStartTime();
		final noteData = data ?? Math.floor((FlxG.mouse.x - GRID_SIZE) / GRID_SIZE);
		final daType = type ?? currentType;

		if (noteData > -1)
		{
			_song.notes[curSec].sectionNotes.push([noteStrum, noteData, 0, noteTypeIntMap.get(daType)]);
			curSelectedNote = _song.notes[curSec].sectionNotes[_song.notes[curSec].sectionNotes.length - 1];
		}
		else
		{
			_song.events.push([noteStrum, [
				[
					eventStuff[Std.parseInt(eventDropDown.selectedId)][0],
					cast(value1InputText.text, String),
					cast(value2InputText.text, String),
					cast(value3InputText.text, String)
				]
			]]);
			curSelectedNote = _song.events[_song.events.length - 1];
			curEventSelected = 0;
			changeEventSelected();
		}

		if (FlxG.keys.pressed.CONTROL && noteData > -1)
			_song.notes[curSec].sectionNotes.push([noteStrum, (noteData + 4) % 8, 0, noteTypeIntMap.get(daType)]);

		// trace(noteData + ', ' + noteStrum + ', ' + curSec);
		strumTimeInputText.text = curSelectedNote[0];

		updateGrid();
		updateNoteUI();
	}

	function getStrumTime(yPos:Float, doZoomCalc:Bool = true):Float
	{
		return FlxMath.remapToRange(yPos, gridBG.y, gridBG.y + gridBG.height * (doZoomCalc ? zoomList[curZoom] : 1), 0, 16 * Conductor.stepCrochet);
	}

	function getYfromStrum(strumTime:Float, doZoomCalc:Bool = true):Float
	{
		final leZoom:Float = doZoomCalc ? zoomList[curZoom] : 1;
		return FlxMath.remapToRange(strumTime, 0, 16 * Conductor.stepCrochet, gridBG.y, gridBG.y + gridBG.height * leZoom);
	}

	function getYfromStrumNotes(strumTime:Float, beats:Float):Float
	{
		final value:Float = strumTime / (beats * 4 * Conductor.stepCrochet);
		return GRID_SIZE * beats * 4 * zoomList[curZoom] * value + gridBG.y;
	}

	function getNotes():Array<Dynamic>
		return [for (i in _song.notes) i.sectionNotes];


	function loadJson(song:String, ?fromPath:Bool = false):Void
	{
		if (fromPath)
		{
			try
			{
				var rawJson = Assets.getText(song);
				// while (!rawJson.endsWith("}")) rawJson = rawJson.substr(0, rawJson.length - 1);

				var e = new Song(Song.parseJSONshit(rawJson));
				e.difficulty = Difficulty.getDifficultyFromFullPath(song) ?? e.difficulty;
				Difficulty.list = [e.difficulty]; // woo vomp
				PlayState.setSong(e);
				MusicBeatState.resetState();
			}
			catch(e)
			{
				trace(e);
				trace('Failed to load json  $song');
			}
		}
		else
		{
			try
			{
				PlayState.SONG = Song.loadFromJson(song.toLowerCase(), song.toLowerCase());
				MusicBeatState.resetState();
			}
			catch(e)
			{
				trace(e);
				final songLowercase:String = Paths.formatToSongPath(song.toLowerCase());
				final boob:String = Highscore.formatSong(songLowercase);
				trace('Failed to load json  $songLowercase/$boob');
			}
		}
	}

	function autosaveSong():Void
	{
		save.data.autosave = Json.stringify({"song": _song}, null);
		save.flush();
		showSaveStatus("Editors", save);
	}

	function clearEvents()
	{
		if (_song.events == null)
			_song.events = [];
		else
			_song.events.clear();
		updateGrid();
	}

	private function saveLevel()
	{
		if (_song.events != null)
			_song.events.sort(sortByTime);
		else
			_song.events = [];

		var needToUpdateGrid = false;
		var realCurSec = curSec;
		// remove out of bounds shit
		while (true)
		{
			// section check
			curSec = _song.notes.length - 1;
			var time = sectionStartTime(); // Math.floor
			var outOfBoundsSection = (time > FlxG.sound.music.length);
			if (outOfBoundsSection)
			{
				var sec = _song.notes.pop();
				// check if this note was selected and unselect it
				if (sec.sectionNotes.contains(curSelectedNote))
					curSelectedNote = null;

				// Log('removed out of bounds section: { time => $time, length => ${FlxG.sound.music.length}, data => $sec }', GRAY);
				needToUpdateGrid = true;
			}

			// event check
			var event:Array<Dynamic> = _song.events[_song.events.length - 1]; // 😭😭
			var outOfBoundsEvents = false;
			if (event != null)
			{
				time = event[0]; // Math.floor
				outOfBoundsEvents = (time > FlxG.sound.music.length);
				if (outOfBoundsEvents)
				{
					// check if this event was selected and unselect it
					if (noteCheck(event))
					{
						curSelectedNote = null;
						changeEventSelected();
					}
					_song.events.pop();
					// Log('removed out of bounds event(s): { time => $time, length => ${FlxG.sound.music.length}, data => $event }', GRAY);
					needToUpdateGrid = true;
				}
			}

			// cleared shit - end while loop
			if (!outOfBoundsSection && !outOfBoundsEvents)
				break;
		}
		curSec = realCurSec;
		if (needToUpdateGrid && curSec == (_song.notes.length - 1))
			updateGrid();

		final data:String = Json.stringify({
			song: _song
		}, optimizeJsonBox.checked ? null : "\t")?.trim();
		if (data != null && data.length > 0)
		{
			var savePath = FileUtil.getPathFromCurrentRoot([
				Constants.SONG_CHART_FILES_FOLDER,
				Paths.formatToSongPath(_song.song),
				Paths.formatToSongPath(_song.song) + '.json'
			]);
			FileUtil.browseForSaveFile([FileUtil.FILE_FILTER_JSON],
				path -> {
					#if sys
					sys.io.File.saveContent(path, data);
					#end
					FlxG.log.notice("Successfully saved LEVEL DATA.");
				},
				() -> FlxG.log.error("Problem saving Level data"),
				savePath,
				'Save "${_song.display}" Chart');

			/*
			var a = new FileDialog();
			a.onSave.add(_ -> FlxG.log.notice("Successfully saved LEVEL DATA."));
			if(!a.save(data.trim(), 'json', Path.join([
				#if MODS_ALLOWED ModsFolder.currentModFolderPath #else "assets" #end,
				Constants.SONG_CHART_FILES_FOLDER,
				Paths.formatToSongPath(_song.song),
				Paths.formatToSongPath(_song.song) + '.json'
			]), 'Save "${_song.display}" Chart'))
				FlxG.log.error("Problem saving Level data");
			*/
		}
	}

	inline function sortByTime(Obj1:Array<Dynamic>, Obj2:Array<Dynamic>):Int
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1[0], Obj2[0]);

	private function saveEvents()
	{
		_song.events.sort(sortByTime);
		final data:String = Json.stringify({
			song: {
				events: _song.events
			}
		}, optimizeJsonBox.checked ? null : "\t")?.trim();
		if (data != null && data.length > 0)
		{
			var savePath = FileUtil.getPathFromCurrentRoot([
				Constants.SONG_CHART_FILES_FOLDER,
				Paths.formatToSongPath(_song.song),
				"events.json"
			]);
			FileUtil.browseForSaveFile([FileUtil.FILE_FILTER_JSON],
				path -> {
					#if sys
					sys.io.File.saveContent(path, data);
					#end
					FlxG.log.notice("Successfully saved LEVEL DATA.");
				},
				() -> FlxG.log.error("Problem saving Level data"),
				savePath,
				'Save "${_song.display}" Events');

			/*
			var a = new FileDialog();
			a.onSave.add(_ -> FlxG.log.notice("Successfully saved LEVEL DATA."));
			if(!a.save(data, 'json', Path.join([
				#if MODS_ALLOWED ModsFolder.currentModFolderPath #else "assets" #end,
				Constants.SONG_CHART_FILES_FOLDER,
				Paths.formatToSongPath(_song.song),
				"events.json"
			]), 'Save "${_song.display}" Events'))
				FlxG.log.error("Problem saving Level data");
			*/
		}
	}

	inline function getSectionBeats(?section:Null<Int>):Float
	{
		/*
		if (section == null) section = curSec;
		final val:Null<Float> = (_song.notes[section] != null) ? _song.notes[section].sectionBeats : null;
		return val != null ? val : 4;
		*/
		return _song?.notes[section ?? curSec]?.sectionBeats ?? 4;
	}
}

class ColorfullInputText extends FlxUIInputText
{
	var flxColorEreg = new EReg('(?:${[for (i in FlxColor.colorLookup.keys()) i].join("|")})|(?:(?:0x|#)(?:(?:[0-9A-F]{2}){3,4}))', "i");
	private override function onChange(action:String):Void
	{
		super.onChange(action);
		updateBGColor();
	}
	private override function set_caretIndex(newCaretIndex:Int):Int
	{
		if (newCaretIndex != caretIndex)
		{
			var i = super.set_caretIndex(newCaretIndex);
			updateBGColor();
			return i;
		}
		else
		{
			return super.set_caretIndex(newCaretIndex);
		}
	}
	function updateBGColor()
	{
		var mainColor:FlxColor = FlxColor.WHITE;
		if (flxColorEreg.match(text))
		{
			var pos = flxColorEreg.matchedPos();
			while (pos != null && !FlxMath.inBounds(caretIndex, pos.pos, pos.pos + pos.len))
			{
				if (!flxColorEreg.matchSub(text, pos.pos + pos.len))
				{
					pos = null;
					break;
				}
				pos = flxColorEreg.matchedPos();
			}
			if (pos != null)
				mainColor = FlxColor.fromString(flxColorEreg.matched(0)) ?? FlxColor.WHITE;
		}
		@:bypassAccessor backgroundColor = mainColor;
		fieldBorderColor = mainColor.getInverted();
		color = fieldBorderColor;
	}
}

class EditorNote extends Note
{
	public function new(strumTime:Float, noteData:Int, mustPress:Bool, ?typeNote:TypeNote)
	{
		super(strumTime, noteData, typeNote, null, false, true, mustPress);
		this.strumTime = strumTime;
	}
	override function update(elapsed:Float)
	{
		last.set(x, y);
		updateAnimation(elapsed);
	}
	override function reloadNote(?prefix:String, ?texture:String, ?suffix:String)
	{
		super.reloadNote(prefix, texture, suffix);
		setGraphicSize(ChartingState.GRID_SIZE);
		// updateHitBox();
	}
}

class AttachedFlxText extends FlxFixedText
{
	public var sprTracker:FlxSprite;
	public var xAdd:Float = 0;
	public var yAdd:Float = 0;

	public function new(X:Float = 0, Y:Float = 0, FieldWidth:Float = 0, ?Text:String, Size:Int = 8, EmbeddedFont:Bool = true)
	{
		super(X, Y, FieldWidth, Text, Size, EmbeddedFont);
		antialiasing = false;
		moves = false;
		borderQuality = 0.5;
	}

	override function draw()
	{
		if (sprTracker != null)
		{
			setPosition(sprTracker.x + xAdd, sprTracker.y + yAdd);
			angle = sprTracker.angle;
			alpha = sprTracker.alpha;
		}
		super.draw();
	}
}
