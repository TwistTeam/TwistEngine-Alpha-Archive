package game.states.editors;

import game.backend.assets.ModsFolder;
import game.backend.data.jsons.StageData;
import game.backend.system.scripts.*;
import game.backend.system.scripts.FunkinLua.DebugLuaText;
import game.backend.system.scripts.ScriptPack.ScriptPackPlayState;
import game.backend.system.song.Conductor.mainInstance as Conductor;
import game.backend.system.states.MusicBeatState;
import game.backend.utils.WindowUtil;
import game.objects.FlxStaticText;
import game.objects.FlxUIDropDownMenuCustom;
import game.objects.FunkinSprite;
import game.objects.game.BGSprite;
import game.objects.game.Character;
import game.objects.game.CoolCamera;
import game.objects.game.HealthIcon;
import game.objects.improvedFlixel.FlxFixedText;
import game.objects.ui.CustomList;
import game.states.editors.MasterEditorMenu;

import flixel.FlxCamera;
import flixel.addons.display.FlxGridOverlay;
import flixel.animation.FlxAnimation;
import flixel.animation.FlxAnimationController;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxFrame;
import flixel.graphics.frames.FlxFramesCollection;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxSpriteGroup;
import flixel.input.keyboard.FlxKey;
import flixel.input.mouse.FlxMouseEvent;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.system.debug.interaction.tools.Pointer.GraphicCursorCross;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.ui.FlxButton;
import flixel.util.FlxColor;
import flixel.util.FlxDestroyUtil;
import flixel.util.FlxSort;
import flixel.util.FlxSpriteUtil;

import openfl.display.BlendMode;
import openfl.display.Graphics;
import openfl.events.Event;
import openfl.events.IOErrorEvent;
import openfl.events.KeyboardEvent;
import openfl.net.FileReference;
import openfl.utils.Assets as OpenFlAssets;

import haxe.Json;
import haxe.io.Path;

#if MODS_ALLOWED
import sys.io.File;
import sys.FileSystem;
#elseif sys
import sys.FileSystem;
#end

using game.backend.utils.FlxObjectTools;

typedef SpriteData = {
	obj:FlxSprite,
	image:String,
	tag:String,
	?animations:Array<AnimArray>,	?curAnim:String,
	?noAntialiasing:Bool,
	?invisible:Bool,
	?x:Float,		?y:Float,
	?alpha:Float,
	?color:Null<FlxColor>,
	?scaleX:Float,			?scaleY:Float,
	?scrollFactorX:Float,	?scrollFactorY:Float,
	?width:Null<Int>, 		?height:Null<Int>,
	?extra:Array<{name:String, varible:Dynamic}>,

	?order:Int,

	// Editor stuff
	?blocked:Bool
}

/*
@:private @:publicFields class LayerSprite extends FlxSpriteGroup{
	var data:SpriteData;
	var pointer:FlxSprite = new FlxSprite(FlxGraphic.fromClass(GraphicCursorCross));
	var baseSprite:FlxSprite;
	function new(?baseSpr:FlxSprite, ?graphic:FlxGraphic, ?animData:{frames:FlxFramesCollection, animContoller:FlxAnimationController}){
		super(0,0);
		if(baseSpr != null){
			baseSprite = baseSpr;
			setPosition(baseSprite.x, baseSprite.y);
			scrollFactor.set(baseSprite.scrollFactor.x, baseSprite.scrollFactor.y);
			baseSprite.x = baseSprite.y = 0;
			baseSprite.scrollFactor.x = baseSprite.scrollFactor.y = 1;
		}else if(graphic != null){
			baseSprite = new FlxSprite(graphic);
		}else if(animData != null){
			baseSprite = new FlxSprite();
			baseSprite.frames = animData.frames;
			baseSprite.animation = animData.animContoller;
		}else{
			baseSprite = new FlxSprite(null); // load stupid flixel logo
		}
		var maxSizeOfPointer:Int = Std.int(Math.max(baseSprite.width/2, 40));
		pointer.setGraphicSize(maxSizeOfPointer, maxSizeOfPointer);
		pointer.updateHitbox();
		add(baseSprite);
		add(pointer);
	}
	function updateSprites(?newGraphic){

	}
}
*/

typedef Aaaaaa = {
	spr:FlxSprite,
	type:String,
	?onPress:FlxSprite->Void,
	?onRelease:FlxSprite->Void,
	?onOver:FlxSprite->Void,
	?onOut:FlxSprite->Void
}

class SectionOfList extends FlxSpriteGroup // NEEDED HEIGHT 25
{
	public var eventsObjects:Map<String, FlxSprite> = [];
	public var data:SpriteData;
	public var text:FlxText;
	public function new(parent:LayersList, data:SpriteData, height:Int = 25, ?objectsWithFunctions:Array<Aaaaaa>)
	{
		super();
		this.data = data;
		if (objectsWithFunctions != null)
			for (i in objectsWithFunctions)
				addObj(i);
	}
	public function addObj(i:Aaaaaa)
	{
		if (i == null || i.spr == null) return;
		add(i.spr);
		i.spr.moves = false;
		if (i.onPress != null || i.onRelease != null || i.onOver != null || i.onOut != null)
		{
			FlxMouseEvent.add(i.spr, i.onPress, i.onRelease, i.onOver, i.onOut);
			eventsObjects.set(i.type, i.spr);
		}
		else
		{
			i.spr.active = false;
		}
	}
	public var selected:Bool = false;
	public override function update(e)
	{
		super.update(e);
		if(selected)
			CursorManager.instance.cursor = 'button';
	}
	public override function destroy()
	{
		for (_ => i in eventsObjects) FlxMouseEvent.remove(i);
		eventsObjects.clear();
		eventsObjects = null;
		data = null;
		text = null;
		super.destroy();
	}
}

class StageEditorState extends MusicBeatState
{
	public var uiLayer:FlxTypedGroup<FlxSprite> = new FlxTypedGroup<FlxSprite>();

	public var layers:FlxTypedGroup<FlxSprite> = new FlxTypedGroup<FlxSprite>();
	public var layersMap:Map<FlxSprite, SpriteData> = new Map<FlxSprite, SpriteData>();

	public var camGame:CoolCamera = new CoolCamera();
	public var camHUD:CoolCamera = new CoolCamera();
	public var camOther:FlxCamera = new FlxCamera();
	public var camOtherOther:FlxCamera = new FlxCamera();
	public var camUI:FlxCamera = new FlxCamera();

	public var stageData:StageFile;
	public var curStage:String = '';
	public var defaultCamZoom(get, set):Float;
	public inline function get_defaultCamZoom():Float return camGame.defaultZoom;
	public inline function set_defaultCamZoom(e:Float):Float return camGame.defaultZoom = e;

	public var isPixelStage:Bool = false;

	public var BF_X:Float = 770;
	public var BF_Y:Float = 100;
	public var DAD_X:Float = 100;
	public var DAD_Y:Float = 100;
	public var GF_X:Float = 400;
	public var GF_Y:Float = 130;

	public var boyfriend:Character;
	public var gf:Character;
	public var dad:Character;

	public var charactersList:Array<Character> = new Array<Character>();
	public var beatAnimList:Array<FlxSprite> = new Array<FlxSprite>();

	public var scriptPack:ScriptPackPlayState;
	#if LUA_ALLOWED
	public var luaArray(get, set):Array<FunkinLua>;
	inline function get_luaArray() return scriptPack.luaArray;
	inline function set_luaArray(e) return scriptPack.luaArray = e;
	#end
	public var hscriptArray(get, set):Array<HScript>;
	inline function get_hscriptArray() return scriptPack.hscriptArray;
	inline function set_hscriptArray(e) return scriptPack.hscriptArray = e;
	private var luaDebugGroup:FlxTypedGroup<DebugLuaText>;

	// static final _hitboxShader:HitBoxShader = new HitBoxShader();
	// var _flxhitbox:FlxSprite;

	var infoObjText:FlxStaticText;
	var _curNameObj:String = "";
	var layersList:LayersList;
	// var ispixel:FlxUICheckBox;

	var lastCamera:FlxCamera;
	var startupData:{stage:String, bf:String, dad:String, gf:String};
	override function create() {
		persistentUpdate = persistentDraw = true;
		if (lastCamera == null) lastCamera = camGame;
		camHUD.bgColor.alpha = camOther.bgColor.alpha = camUI.bgColor.alpha = camOtherOther.bgColor.alpha = 0;
		add(layers);

		#if LUA_ALLOWED
		luaDebugGroup = new FlxTypedGroup<DebugLuaText>();
		luaDebugGroup.cameras = [camOther];
		add(luaDebugGroup);
		#end

		FlxG.cameras.reset(camGame);
		FlxG.cameras.setDefaultDrawTarget(camGame, true);
		FlxG.cameras.add(camHUD, false);
		FlxG.cameras.add(camUI, false);
		FlxG.cameras.add(camOther, false);
		FlxG.cameras.add(camOtherOther, false);

		var tipText:FlxStaticText = new FlxStaticText(FlxG.width - 15, FlxG.height - 15, 0, "
		E/Q or Wheel Mouse - Camera Zoom In/Out
		R - Reload Stage
		Space - Play Random Animation on Selected Sprite
		Drag Middle Mouse Button - Move Camera
		Arrow Keys / Drag Left Mouse Button - Move Selected Sprite
		T - Reset Camera Zoom to Default
		TAB - Toggle UI HUD
		ALT + S - Open File Dialog to Load Stage
		ALT + W - Open File Dialog to Load Charater (Needed to Select Character)
		Hold X or Y to change values: Scroll Factor (< or >) and Scale ({ or })
		Hold Shift to Move 10x faster
		CTRL + S - Save stage in lua (WIP)", 8);
		tipText.cameras = [camHUD];
		tipText.setFormat(null, 8, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE_FAST, FlxColor.BLACK);
		tipText.borderSize = 0.75;
		add(tipText);
		tipText.x -= tipText.width;
		tipText.y -= tipText.height;

		infoObjText = new FlxStaticText(0, 15, FlxG.width);
		infoObjText.camera = camUI;
		infoObjText.setFormat(null, 12, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE_FAST, FlxColor.BLACK);
		infoObjText.borderSize = 1;
		add(infoObjText);

		layersList = new LayersList(FlxG.width - 230, 130, 230, 390);
		layersList.parentCamera = camUI;
		layersList.onChangeLayer = function(obj:FlxSprite, index:Int) {
			final data = cast(obj, SectionOfList).data;
			final oldOrder = data.order;
			// trace([data.order, index]);
			if (oldOrder < index){
				for (i in 0...oldOrder) {
					final data = layersMap.get(layers.members[i]);
					if (data != null)	data.order--;
				}
				index++;
			}
			for (i in index...layers.members.length) {
				final data = layersMap.get(layers.members[i]);
				if (data == null) continue;
				// trace([data.tag]);
				data.order++;
			}
			data.order = index;
			sortLayers();
		}
		layersList.overlapLayer = function(obj:FlxSprite):Bool {
			final obj = cast(obj, SectionOfList);
			return obj != null && obj.text != null && layersList.mousePoint.x <= obj.text.width + 10 && obj.mouseOverlapping();
		}
		layersList.antialiasing = false;
		FlxTween.tween(layersList, {x: layersList.x + FlxG.width / 2}, 0.5, {ease:FlxEase.quartOut, type:BACKWARD});

		ClientPrefs.cacheOnGPU = false;

		// _flxhitbox = new FlxSprite();
		// _flxhitbox.active = false;
		// _flxhitbox.shader = _hitboxShader;

		changeGF(startupData.gf);
		changeDAD(startupData.dad);
		changeBF(startupData.bf);

		// loadStage('stage');
		// loadStage('pyaterochka');
		loadStage(startupData.stage);
		FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, onPress);
		MusicBeatState.onSwitchState = r -> FlxTween.tween(layersList, {x: layersList.x + FlxG.width / 2}, 0.5, {ease:FlxEase.quartIn});
		super.create();
		FlxG.mouse.visible = true;
		updatePresence();
		#if sys
		lime.app.Application.current.window.onDropFile.add(LoadFromDroppedFile);
		#end
	}

	function createLayerForList(data:SpriteData) {
		final bg = new FlxSprite().makeSolid(layersList.width - layersList.outView * 2, 25, 0xFF606060);
		var posX = bg.width;
		function loadIconBozo(index:Int):FlxSprite {
			final spr = new FlxSprite(posX, 3); // (bg.height - spr.height) / 2;
			spr.loadGraphic(Paths.image('ui/editor/bozo_icons', false), true, 10, 10);
			spr.animation.add('yes',	[index * 2 + 1],	0);
			spr.animation.add('no',		[index * 2],		0);
			spr.setGraphicSize(19);
			spr.updateHitbox();
			spr.x -= spr.width;
			spr.antialiasing = false;
			posX = spr.x - 5;
			return spr;
		}
		var deleteIcon:FlxSprite = null;
		if (!['gfGroup', 'boyfriendGroup', 'dadGroup'].contains(data.tag)){
			deleteIcon = loadIconBozo(0);
			deleteIcon.animation.play('yes');
		}
		final hideIcon = loadIconBozo(1);
		hideIcon.animation.play(data.invisible ? 'yes' : 'no');

		final lockIcon = loadIconBozo(2);
		lockIcon.animation.play(!data.blocked ? 'yes' : 'no');

		final text = new FlxFixedText(10, lockIcon.y, 0, data.tag);
		final section = new SectionOfList(layersList, data, Std.int(bg.height));
		section.add(bg);
		section.add(text);
		section.text = text;
		final aaaaaaaaaaaaaaaaa:Array<Aaaaaa> = [
			{
				spr: deleteIcon,
				type: 'delete',
				onOut:(spr) -> {
					spr.animation.play('yes');
					section.selected = false;
				},
				onOver:(spr) -> {
					spr.animation.play('no');
					section.selected = true;
				},
				onRelease:(spr:FlxSprite) -> {
					for (sprite in layers.members)
						if (layersMap.exists(sprite) && layersMap.get(sprite).tag == data.tag){
							sprite.destroy();
							removeLayer(sprite, true);
							break;
						}
				}
			},
			{
				spr: hideIcon,
				type: 'visible',
				onOut:(spr) -> section.selected = false,
				onOver:(spr) -> section.selected = true,
				onRelease:(spr) -> {
					data.invisible = !data.invisible;
					spr.animation.play(data.invisible ? 'yes' : 'no');
					if (FlxG.keys.pressed.SHIFT){
						for (_ => i in layersMap) i.invisible = data.invisible;
						updateLayersData();
						updateLayersButtons();
					}else
						updateLayersData();
				}
			},
			{
				spr: lockIcon,
				type: 'block',
				onOut:(spr) -> section.selected = false,
				onOver:(spr) -> section.selected = true,
				onRelease:(spr) -> {
					data.blocked = !data.blocked;
					spr.animation.play(!data.blocked ? 'yes' : 'no');
					if (FlxG.keys.pressed.SHIFT){
						for (_ => i in layersMap) i.blocked = data.blocked;
						updateLayersData();
						updateLayersButtons();
					}else
						updateLayersData();
				}
			}
		];
		for (i in aaaaaaaaaaaaaaaaa) section.addObj(i);
		layersList.add(section);
		section.y = layersList.maxScrollY;
		return section;
	}
	function updateListLayers() {
		layersList.clear(true);
		final dataForLayers = [for (_ => data in layersMap) data];
		dataForLayers.sort(function(_1, _2) return FlxSort.byValues(-1, _1.order, _2.order));
		layers.clear();
		for (i in dataForLayers){
			createLayerForList(i);
			layers.add(i.obj);
		}

		// for (i in [for (i in 0...10) new FlxSprite(Paths.image('dog'))]) layersList.add(i);

		layersList.snapPos();
		sortLayers();
	}

	function updateLayersButtons() {
		layersList._members.forEachAlive((spr) -> {
			final spr = cast(spr, SectionOfList);
			if (spr != null && spr.data != null){
				spr.eventsObjects.get('visible').animation.play(spr.data.invisible ? 'yes' : 'no');
				spr.eventsObjects.get('block').animation.play(spr.data.blocked ? 'no' : 'yes');
			}
		});
	}

	function updateLayersData() {
		layers.forEachAlive((spr) -> {
			final data = layersMap.get(spr);
			if (data != null){
				spr.solid = !data.blocked; // yea
				spr.visible = !data.invisible;
			}
		});
	}

	function sortLayers(){
		final dataForLayers = [for (_ => data in layersMap) data];
		dataForLayers.sort(function(a, b){
			if (a.order == b.order) return 1;
			return FlxSort.byValues(-1, a.order, b.order);
		}
		// function(_1, _2) return FlxSort.byValues(-1, _1.order, _2.order)
		);
		// trace([for (i in dataForLayers) [i.tag, i.order, i.obj == null]]);

		layers.clear();
		for (i in dataForLayers) layers.add(i.obj);

		for (spr => data in layersMap) data.order = layers.members.indexOf(spr);
		// layers.sort(function(o, a:FlxSprite, b:FlxSprite){
		// 	final dataA = layersMap.get(a);
		// 	final dataB = layersMap.get(b);
		// 	if (dataA == null || dataB == null){
		// 		if (dataA == null) removeLayer(a); else removeLayer(b);
		// 		return 0;
		// 	}
		// 	if (dataA.order == dataB.order) return 1;
		// 	return FlxSort.byValues(o, dataA.order, dataB.order);
		// }, -1);

		// dataForLayers.sort(function(_1, _2) return FlxSort.byValues(-1, _1.order, _2.order));
		// trace([for (i in dataForLayers) [i.tag, i.order, i.obj == null]]);
	}

	var _timePressed:Float = 0;
	function onPress(event:KeyboardEvent) {
		final eventKey:FlxKey = event.keyCode;
		final pressedX:Bool = FlxG.keys.pressed.X;
		final pressedY:Bool = FlxG.keys.pressed.Y;
		final isPressedXY:Bool = pressedX || pressedY;
		if (FlxG.keys.checkStatus(eventKey, JUST_RELEASED)){
			if (curObject != null){
				if (_timePressed > 0.03){
					if (eventKey == FlxKey.RBRACKET){
						curObject.scale.set(FlxMath.roundDecimal(curObject.scale.x, 3),
											FlxMath.roundDecimal(curObject.scale.y, 3));
						updateCurObjText();
					}else if (eventKey == FlxKey.LBRACKET){
						curObject.scale.set(FlxMath.roundDecimal(curObject.scale.x, 3),
											FlxMath.roundDecimal(curObject.scale.y, 3));
						updateCurObjText();
					}else if (eventKey == FlxKey.COMMA){
						curObject.scrollFactor.set(FlxMath.roundDecimal(curObject.scrollFactor.x, 4),
													FlxMath.roundDecimal(curObject.scrollFactor.y, 4));
						updateCurObjText();
					}else if (eventKey == FlxKey.PERIOD){
						curObject.scrollFactor.set(FlxMath.roundDecimal(curObject.scrollFactor.x, 4),
													FlxMath.roundDecimal(curObject.scrollFactor.y, 4));
						updateCurObjText();
					}
				}
			}
			return;
		}

		#if sys
		if (FlxG.keys.checkStatus(eventKey, JUST_PRESSED)){
			_timePressed = 0;
			if (FlxG.keys.pressed.CONTROL){
				if (eventKey == FlxKey.S) dummSave();
				return;
			}else if (FlxG.keys.pressed.ALT){
				if (eventKey == FlxKey.S){
					var a = new FileDialog();
					a.onSelect.add((path) -> loadStage(new Path(path).file));
					if(!a.open('json', Path.join([FileSystem.exists(ModsFolder.currentModFolderAbsolutePath) ?
						ModsFolder.currentModFolderAbsolutePath
						:
						Path.join([Sys.getCwd(), '/assets']),
						'stages']).replace('/', '\\') + '/', 'Select to load stage:'))
							FlxG.log.error("Problem open data");
					return;
				}
			}
			if (curObject != null){
				if (FlxG.keys.pressed.ALT){
					if (eventKey == FlxKey.W){
						if (Std.isOfType(curObject, Character)){
							var a = new FileDialog();
							a.onSelect.add(path -> {
								final func = (curObject == boyfriend ? changeBF : curObject == dad ? changeDAD : curObject == gf ? changeGF : null);
								path = new Path(path).file;
								if (func == null) // custom character
									changeCharacter(cast(curObject, Character), path, curData.tag, cast(curObject, Character).isPlayer);
								else
									func(path);
							});
							if(!a.open('json', Path.join([FileSystem.exists(ModsFolder.currentModFolderAbsolutePath) ?
								ModsFolder.currentModFolderAbsolutePath
								:
								Path.join([Sys.getCwd(), 'assets']),
								'characters']).replace('/', '\\') + '/', 'Select new character'))
									FlxG.log.error("Problem open data");
						}
					}else if (eventKey == FlxKey.S){
						var a = new FileDialog();
						// a.onSelect.add(path -> trace(path));
						a.onSelect.add(path -> loadStage(new Path(path).file));
						if(!a.open('json', Path.join([FileSystem.exists(ModsFolder.currentModFolderAbsolutePath) ?
							ModsFolder.currentModFolderAbsolutePath
							:
							Path.join([Sys.getCwd(), '/assets']),
							'stages']).replace('/', '\\') + '/', 'Select to load stage:'))
								FlxG.log.error("Problem open data");
					}
					return;
				}
				if (!Std.isOfType(curObject, Character)){
					if (eventKey == FlxKey.SPACE){
						if (Std.isOfType(curObject, FunkinSprite)){
							final curObject = cast(curObject, FunkinSprite);
							final arrayAnims = curObject.getNameList();
							var oldAnim = curObject.curAnimName;
							var animNext = FlxG.random.getObject(arrayAnims);
							if (arrayAnims.length > 1)
								while (animNext == oldAnim) animNext = FlxG.random.getObject(arrayAnims);

							if (curData != null) curData.curAnim = animNext;
							curObject.playAnim(animNext, true);
						#if LUA_ALLOWED
						}
						else if (Std.isOfType(curObject, FunkinLua.ModchartSprite))
						{
							if (curObject.animation == null) return;
							final curObject = cast(curObject, FunkinLua.ModchartSprite);
							final arrayAnims = curObject.animation.getNameList();
							var animNext = FlxG.random.getObject(arrayAnims);
							final oldAnim = curObject.animation.curAnim != null ? curObject.animation.curAnim.name : '';
							if (arrayAnims.length > 1)
								while (animNext == oldAnim) animNext = FlxG.random.getObject(arrayAnims);

							if (curData != null) curData.curAnim = animNext;
							curObject.playAnim(animNext, true);
						#end
						}
						else
						{
							if (curObject.animation == null) return;
							final arrayAnims = curObject.animation.getNameList();
							var animNext = FlxG.random.getObject(arrayAnims);
							final oldAnim = curObject.animation.curAnim != null ? curObject.animation.curAnim.name : '';
							if (arrayAnims.length > 1)
								while (animNext == oldAnim) animNext = FlxG.random.getObject(arrayAnims);
							if (curData != null) curData.curAnim = animNext;
							curObject.animation.play(animNext, true);
						}
					}else if (eventKey == 46 /*FlxKey.DELETE*/){
						curObject.destroy();
						removeLayer(curObject, true);
						curObject = null;
						updateTextInfo("");
					}
				}else if (eventKey == FlxKey.SPACE){
						final curObject = cast(curObject, Character);
						final arrayAnims = curObject.getNameList();
						var oldAnim = curObject.curAnimName;
						var animNext = FlxG.random.getObject(arrayAnims);
						if (arrayAnims.length > 1)
							while (animNext == oldAnim) animNext = FlxG.random.getObject(arrayAnims);

						curObject.playAnim(animNext, true);
					}
				if (eventKey == FlxKey.RBRACKET){
					curObject.scale.set(FlxMath.roundDecimal(curObject.scale.x + (pressedX ? 0.05 : 0), 3),
										FlxMath.roundDecimal(curObject.scale.y + (pressedY ? 0.05 : 0), 3));
					updateCurObjText();
				}else if (eventKey == FlxKey.LBRACKET){
					curObject.scale.set(FlxMath.roundDecimal(curObject.scale.x - (pressedX ? 0.05 : 0), 3),
										FlxMath.roundDecimal(curObject.scale.y - (pressedY ? 0.05 : 0), 3));
					updateCurObjText();
				}else if (eventKey == FlxKey.COMMA){
					curObject.scrollFactor.set(FlxMath.roundDecimal(curObject.scrollFactor.x + (pressedX ? 0.05 : 0), 5),
												FlxMath.roundDecimal(curObject.scrollFactor.y + (pressedY ? 0.05 : 0), 5));
					updateCurObjText();
				}else if (eventKey == FlxKey.PERIOD){
					curObject.scrollFactor.set(FlxMath.roundDecimal(curObject.scrollFactor.x - (pressedX ? 0.05 : 0), 5),
												FlxMath.roundDecimal(curObject.scrollFactor.y - (pressedY ? 0.05 : 0), 5));
					updateCurObjText();
				}
			}
			trace(Std.string(eventKey));
			return;
		}
		#end
		_timePressed += FlxG.elapsed;
		if (curObject != null){
			if (_timePressed > 0.03){
				if (eventKey == FlxKey.RBRACKET){
					curObject.scale.set(FlxMath.roundDecimal(curObject.scale.x + (pressedX ? 0.05 * FlxG.elapsed * 240 : 0), 3),
										FlxMath.roundDecimal(curObject.scale.y + (pressedY ? 0.05 * FlxG.elapsed * 240 : 0), 3));
					updateCurObjText();
				}else if (eventKey == FlxKey.LBRACKET){
					curObject.scale.set(FlxMath.roundDecimal(curObject.scale.x - (pressedX ? 0.05 * FlxG.elapsed * 240 : 0), 3),
										FlxMath.roundDecimal(curObject.scale.y - (pressedY ? 0.05 * FlxG.elapsed * 240 : 0), 3));
					updateCurObjText();
				}else if (eventKey == FlxKey.COMMA){
					curObject.scrollFactor.set(FlxMath.roundDecimal(curObject.scrollFactor.x + (pressedX ? 0.05 * FlxG.elapsed * 240 : 0), 5),
												FlxMath.roundDecimal(curObject.scrollFactor.y + (pressedY ? 0.05 * FlxG.elapsed * 240 : 0), 5));
					updateCurObjText();
				}else if (eventKey == FlxKey.PERIOD){
					curObject.scrollFactor.set(FlxMath.roundDecimal(curObject.scrollFactor.x - (pressedX ? 0.05 * FlxG.elapsed * 240 : 0), 5),
												FlxMath.roundDecimal(curObject.scrollFactor.y - (pressedY ? 0.05 * FlxG.elapsed * 240 : 0), 5));
					updateCurObjText();
				}
			}
		}
	}
	function updateCurObjText() {
		updateDataObj(curObject);
		updateTextInfoToCurData();
	}
	#if sys
	// final lastDirectory:String = ModsFolder.currentModFolder;
	function LoadFromDroppedFile(file:String)
	{
		// trace(file);
		// try{
			var infoShit = DropFileUtil.getInfoPath(file, STAGE);
			if (infoShit != null)
			{
				// ModsFolder.currentModFolder = infoShit.modFolder;
				loadStage(infoShit.file);
				trace('LOADED STAGE: ' + infoShit);
				return;
			}
			if(file.endsWith('.json'))
			{
				var infoShit = DropFileUtil.getInfoPath(file, CHARACTER);
				if (infoShit == null){
					return;
				}

				// trace('ADDED CHARACTER: ' + infoShit);
				// trace(curObject == gf); // test
			}
			else if(AssetsPaths.IMAGE_REGEX.match(file))
			{
				var bitmapCracker = null;
				var infoShit = DropFileUtil.getInfoPath(file, IMAGE);
				if (infoShit == null){
					infoShit = DropFileUtil.getInfoPath(file, null);
					// if the file does not exist in the game, try to get it from your computer
					try{
						bitmapCracker = Paths.connectBitmap(openfl.display.BitmapData.fromFile(file), file, false, false);
					}catch(e){
						CoolUtil.getErrorInfo(e, 'Error on load "$file"!\n');
						return;
					}
				}

				final graphic = bitmapCracker == null ? Paths.image('${infoShit.file}.${infoShit.extension}') : bitmapCracker;
				if (graphic == null) return;
				final sprite = new FlxSprite();
				var animated = false;
				if (infoShit.extension == 'png' && Paths.fileExists('images/${infoShit.file}.xml'))
				{
					try
					{
						sprite.frames = Paths.getSparrowAtlas('${infoShit.file}');
						sprite.tryExportAllAnimsFromXmlFlxSprite();
						animated = true;
						trace('ADDED SPRISHEET IMAGE: ' + infoShit);
					}
					catch(e)
					{
						CoolUtil.getErrorInfo(e, 'Error when exporting animation: ');
					}
				}
				else
				{
					sprite.loadGraphic(graphic);
					trace('ADDED IMAGE: ' + infoShit);
				}
				// god damn, why flxmouse stopped on focus off
				sprite.screenCenter();
				sprite.setPosition(sprite.x + FlxG.camera.scroll.x, sprite.y + FlxG.camera.scroll.y);
				sprite.antialiasing = true;
				fixPos(sprite);
				addLayer(sprite);
				final data = layersMap.get(sprite);
				data.order = layers.length;
				final programPath = Sys.programPath();
				trace(programPath);
				data.image = (infoShit.path.startsWith(programPath) ? infoShit.path.substr(programPath.length) : infoShit.path);
				data.tag = Path.withoutDirectory(Path.withoutExtension(data.image)); // may stupid
				if (animated){
					data.animations = [];
					data.curAnim = sprite.animation.name;
					for (animName => i in @:privateAccess sprite.animation._animations){
						data.animations.push({
							anim:		animName,
							name:		animName,
							fps:		i.frameRate,
							loop:		i.looped,
							//indices:	,
							//offsets:	,

							loopPoint:	i.loopPoint,
							flipX:		i.flipX,
							flipY:		i.flipY
						});
					}
				}
				createLayerForList(layersMap.get(sprite));
				layersList.updateHeightScroll();
			}

			// var modFolder = file.split("\\");
			// // trace(modFolder);
			// trace(ModsFolder.currentModDirectory = modFolder[modFolder.length - 1 - 3]);
			// // ModsFolder.currentModDirectory = '';
			// loadJson(file, true);
		// }
	}
	#end

	final preGPUCashing = ClientPrefs.cacheOnGPU;

	override function destroy(){
		if (scriptPack != null) scriptPack.destroy();
		WindowUtil.resetTitle();
		#if sys
		lime.app.Application.current.window.onDropFile.remove(LoadFromDroppedFile);
		#end
		FlxG.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onPress);

		camGame.bgColor = 0xFF000000;
		// ModsFolder.currentModFolder = lastDirectory;
		// Paths.setCurrentLevel('');
		ClientPrefs.cacheOnGPU = preGPUCashing;
		_dragMousePoint?.put();
		_objMousePoint?.put();
		_oldPosCurObj?.put();
		_mousePoint?.put();
		super.destroy();
	}

	function updatePresence() {
		#if DISCORD_RPC
		DiscordClient.changePresence("Stage Editor", curStage);
		#end
		WindowUtil.endfix = ' - Stage Editor - $curStage';
	}
	public function new(?startup:{stage:String, bf:String, dad:String, gf:String}){
		super(false);
		// Paths.setCurrentLevel('shared');

		startupData = startup ?? { // load default stage
			stage: 'stage',
			bf: 'bf',
			dad: 'dad',
			gf: 'gf'
		};
	}

	function changeCharacter(char:Character, newName:String, tag:String = '', isPlayer:Bool = false, isGF:Bool = false, defaultX:Float = 0, defaultY:Float = 0) {
		if (tag.length > 1) tag = newName;
		final notAdded:Bool = char == null || !layers.members.contains(char);
		if (notAdded)
			char = new Character(defaultX, defaultY, newName, isPlayer);
		else
			char.switchCharater(newName);
		char.debugMode = true;
		char.extraData.STAGE_EDITOR_CHARNAME = tag;
		if (notAdded) addLayer(char);
		settingCharacterData(char, true);
		startCharacterPos(char, !isPlayer || isGF);
		// startCharacterLua(char.curCharacter);
		final curAnim = char.curAnimName;
		if (curAnim != null) char.playAnim(curAnim);
		return char;
	}

	function changeBF(newName:String)	boyfriend = changeCharacter(boyfriend, newName, 'boyfriendGroup', true, false, BF_X, BF_Y);
	function changeGF(newName:String)	gf = changeCharacter(gf, newName, 'gfGroup', false, true, GF_X, GF_Y);
	function changeDAD(newName:String)	dad = changeCharacter(dad, newName, 'dadGroup', false, false, DAD_X, DAD_Y);

	function updateTextInfo(newString:String){
		infoObjText.text = newString;
		infoObjText.x = FlxG.width - infoObjText.width - 10;
	}
	function updateTextInfoToCurData() {
		if (layersMap.exists(curObject)){
			curData = layersMap.get(curObject);
			updateTextInfo('Tag: ${curData.tag}\nImage File: ${curData.image}\nPos: ${[curData.obj.x, curData.obj.y]}\nScale: ${[curData.scaleX, curData.scaleY]}\nScrollFactor: ${[curData.scrollFactorX, curData.scrollFactorY]}\nWidth: ${curData.width}, Height: ${curData.height}');
		}else{
			curData = null;
			updateTextInfo('');
		}
	}

	var curData(default, null):SpriteData;
	var curObject(default, set):FlxSprite;
	var _oldPosCurObj:FlxPoint = FlxPoint.get();
	function set_curObject(newObject:FlxSprite):FlxSprite {
		if (curObject != newObject){
			if (curObject != null /* && layersMap.exists(curObject)*/){
				// curObject.alpha = layersMap.get(curObject).alpha;
				if (curObject.colorTransform != null) // laggy
					curObject.setColorTransform();
					// obj.colorTransform.greenMultiplier =
					// 	obj.colorTransform.blueMultiplier =
					// 		// obj.colorTransform.alphaMultiplier =
					// 		obj.colorTransform.redMultiplier = 1.0;
				if (curObject.exists)
					updateDataObj(curObject);
			}
			if (newObject != null /* && layersMap.exists(newObject)*/){
				// newObject.alpha = layersMap.get(newObject).alpha * 0.8;
				if (newObject.colorTransform != null) // laggy
					newObject.setColorTransform(0.75, 0.75, 0.75);
					// obj.colorTransform.greenMultiplier =
					// 	obj.colorTransform.blueMultiplier =
					// 		// obj.colorTransform.alphaMultiplier =
					// 		obj.colorTransform.redMultiplier = 0.75;
				curObject = newObject;
				_oldPosCurObj.set(curObject.x, curObject.y);

				_dragMousePoint.copyFrom(_mousePoint);
				updateTextInfoToCurData();
			}else curObject = newObject;
		}
		return newObject;
	}

	var finded:Bool = true;
	var curCursor:String = "";
	var _dragMousePoint = FlxPoint.get();
	var _objMousePoint = FlxPoint.get();
	var _mousePoint = FlxPoint.get();

	function fixPos(spr:FlxObject) spr.setPosition(FlxMath.roundDecimal(spr.x, 2), FlxMath.roundDecimal(spr.y, 2)); // normalize position

	function checkOverlapLayers() {
		// var _point = FlxG.mouse.getPositionInCameraView(layers.camera);
		// if (layers.camera.containsPoint(_point)){
		FlxG.mouse.getWorldPosition(lastCamera, _mousePoint);
		finded = false;
		var obj;
		for (i in 0...layers.members.length){
			obj = layers.members[layers.members.length - 1 - i];
			// if(obj != null && CoolUtil.mouseOverlapping(obj)){
				// layersMap.exists(obj)
			if (obj == null || !obj.solid || !obj.visible || obj.alpha == 0)
				continue;

			if (obj.camera.ID != lastCamera.ID)
			{
				lastCamera = obj.camera;
				FlxG.mouse.getWorldPosition(lastCamera, _mousePoint);
			}
			final isFlxAnimate = Std.isOfType(obj, flxanimate.FlxAnimate) ? cast (obj, flxanimate.FlxAnimate)?.useAtlas : false;
			if ((isFlxAnimate && obj.mouseOverlapping(lastCamera))
				|| (obj.graphic?.bitmap?.image?.data != null && obj.pixelsOverlapPoint(_mousePoint, 0x0F, obj.camera)))
			{
				curObject = obj;
				finded = true;
				break;
			}
		}
	}
	var leavingFromEditor:Bool = false;
	override function update(elapsed:Float){
		curCursor = '';
		if (FlxG.keys.justPressed.ESCAPE || leavingFromEditor)
		{
			// game.states.MainMenuState.playMusic(Paths.music('freakyMenu'));
			if (!leavingFromEditor)
			{
				MusicBeatState.switchState(new MasterEditorMenu());
				leavingFromEditor = true;
			}
			FlxG.mouse.visible = false;
			super.update(elapsed);
			return;
		}
		if (FlxG.keys.justPressed.R)
		{
			loadStage(curStage);
			super.update(elapsed);
			return;
		}
		scriptPack.call('onUpdate', [elapsed]);

		if (!layersList.canDrag || !layersList.inBoxMouse && !layersList.crack){
		// if (true){
			if (FlxG.keys.justPressed.TAB){
				camUI.visible = camOther.visible = camHUD.visible = !camHUD.visible;
			}
			final pressed = FlxG.mouse.pressed;
			final justPressed = FlxG.mouse.justPressed;
			final justReleased = FlxG.mouse.justReleased;
			final pressedMiddle = FlxG.mouse.pressedMiddle;
			if (true)
			{
				if (!pressedMiddle && justPressed)
				{
					curObject = null;
					checkOverlapLayers();
					if (curObject != null) fixPos(curObject);
					updateTextInfoToCurData();
				}
				if (curObject != null && (!finded || (justReleased/* && FlxG.game.ticks - FlxG.mouse.justPressedTimeInTicks > FlxG.updateFramerate / 25*/))){
					fixPos(curObject);
				}
			}
			else
			{
				if (!pressed)
				{
					if (curObject != null && (!finded || justPressed))
					{
						fixPos(curObject);
						curObject = null;
						updateTextInfo("");
					}
					if (!pressedMiddle && FlxG.mouse.justMoved) checkOverlapLayers();
				}
			}

			if (curObject != null && FlxG.keys.anyPressed([FlxKey.UP, FlxKey.DOWN, FlxKey.RIGHT, FlxKey.LEFT]))
			{
				final factor = (FlxG.keys.pressed.SHIFT ? 6 : 1) * (FlxG.keys.pressed.CONTROL ? 8 : 20) * FlxG.elapsed;

				if (FlxG.keys.pressed.DOWN)			curObject.y += factor;
				if (FlxG.keys.pressed.UP)			curObject.y -= factor;

				if (FlxG.keys.pressed.RIGHT)		curObject.x += factor;
				if (FlxG.keys.pressed.LEFT)			curObject.x -= factor;

				fixPos(curObject);
				updateCurObjText();
			}

			if (curObject != null) curCursor = 'button';
			layersList.canDrag = true;
			final factor = FlxG.keys.pressed.SHIFT ? 0.4 : 1;
			if (pressed && curObject != null )
			{
				FlxG.mouse.getWorldPosition(curObject.camera, _objMousePoint);
				curObject.x = _oldPosCurObj.x + _objMousePoint.x - _dragMousePoint.x;
				curObject.y = _oldPosCurObj.y + _objMousePoint.y - _dragMousePoint.y;
				curCursor = 'hand';
				updateCurObjText();
				layersList.canDrag = false;
			}
			else
			{
				if (FlxG.keys.justPressed.T) FlxG.camera.zoom = camGame.defaultZoom;
				var factor = FlxG.keys.pressed.SHIFT ? 0.4 : 1;
				if(pressedMiddle){
					layersList.canDrag = false;
					FlxG.camera.scroll.x -= FlxG.mouse.deltaScreenX * factor;
					FlxG.camera.scroll.y -= FlxG.mouse.deltaScreenY * factor;
					// curCursor = 'hand';
					// if (pressed && curObject != null){
					// 	curObject.x -= FlxG.mouse.deltaScreenX * curObject.scrollFactor.x * factor;
					// 	curObject.y -= FlxG.mouse.deltaScreenY * curObject.scrollFactor.y * factor;
					// }
				}

				factor *= 25;

				final pressedE = FlxG.keys.pressed.E;
				final pressedQ = FlxG.keys.pressed.Q;
				if (pressedE != pressedQ){
					if (pressedE && FlxG.camera.zoom < 25)	FlxG.camera.zoom += elapsed * FlxG.camera.zoom;
					else if (FlxG.camera.zoom > 0.005)		FlxG.camera.zoom -= elapsed * FlxG.camera.zoom;
				}

				// if (FlxG.keys.pressed.E) camGame.angle += elapsed / factor * 100;
				// else if (FlxG.keys.pressed.Q) camGame.angle -= elapsed / factor * 100;

				FlxG.camera.zoom = CoolUtil.boundTo(FlxG.camera.zoom + FlxG.mouse.wheel / factor * FlxG.camera.zoom, 0.005, 25);
				if ((pressedE != pressedQ || FlxG.mouse.wheel != 0) && FlxG.camera.zoom > 0.005 && FlxG.camera.zoom < 25){
					final mousePos = FlxG.mouse.getScreenPosition(camUI);
					mousePos.set((FlxG.width / 2 - mousePos.x) / FlxG.camera.zoom,
								(FlxG.height / 2 - mousePos.y) / FlxG.camera.zoom);
					FlxG.camera.scroll.x -= FlxG.mouse.wheel * mousePos.x / factor;
					FlxG.camera.scroll.y -= FlxG.mouse.wheel * mousePos.y / factor;
					if (pressedE != pressedQ){
						if (pressedQ){
							FlxG.camera.scroll.x += elapsed * mousePos.x;
							FlxG.camera.scroll.y += elapsed * mousePos.y;
						}else{
							FlxG.camera.scroll.x -= elapsed * mousePos.x;
							FlxG.camera.scroll.y -= elapsed * mousePos.y;
						}
					}
					// if (pressed && curObject != null){
					// 	curObject.x -= mousePos.x * curObject.scrollFactor.x;
					// 	curObject.y -= mousePos.y * curObject.scrollFactor.y;
					// }
					mousePos.put();
					layersList.canDrag = false;
				}
			}
		}
		CursorManager.instance.cursor = curCursor;
		super.update(elapsed);
		scriptPack.call('onUpdatePost', [elapsed]);
	}

	public function addTextToDebug(text:String, color:FlxColor)
	{
		#if LUA_ALLOWED
		var newText:DebugLuaText = luaDebugGroup.recycle(DebugLuaText);
		newText.text = text;
		newText.color = color;
		newText.disableTime = 6;
		newText.alpha = 1;
		newText.setPosition(10, 8 - newText.height);

		luaDebugGroup.forEachAlive(spr -> spr.y += newText.height + 2);
		#end
	}

	function loadStage(stage:String){
		if (scriptPack != null) scriptPack.destroy();
		scriptPack = new ScriptPackPlayState();
		var aaa:Array<FlxSprite> = [gf, dad, boyfriend];
		layers.forEachAlive(function(spr){
			if (!aaa.contains(spr)) FlxDestroyUtil.destroy(spr);
			// else aaa.remove(spr);
		});
		layersList.clear(true);
		//updateListLayers();
		aaa.clearArray();
		layers.clear();
		layersMap.clear();
		charactersList.clearArray();
		beatAnimList.clearArray();
		camGame.bgColor = 0xFF303030;

		stageData = StageData.getStageFile(stage) ?? StageData.dummy(); // Stage couldn't be found, create a dummy stage for preventing a crash

		camGame.defaultZoom = defaultCamZoom = stageData.defaultZoom;
		isPixelStage = stageData.isPixelStage;
		BF_X = stageData.boyfriend[0];
		BF_Y = stageData.boyfriend[1];
		GF_X = stageData.girlfriend[0];
		GF_Y = stageData.girlfriend[1];
		DAD_X = stageData.opponent[0];
		DAD_Y = stageData.opponent[1];
		stageData.camera_boyfriend ??= [0, 0]; // Fucks sake should have done it since the start :rolling_eyes:
		stageData.camera_opponent ??= [0, 0];
		stageData.camera_girlfriend ??= [0, 0];
		stageData.camera_speed ??= 1;
		switch (stage)
		{
			case 'stage': // classic
				var bg:BGSprite = new BGSprite('stageback', -600, -200);
				addLayer(bg);

				var stageFront:BGSprite = new BGSprite('stagefront', -650, 600);
				stageFront.setGraphicSize(stageFront.width * 1.1);
				stageFront.updateHitbox();
				addLayer(stageFront);
				if (!ClientPrefs.lowQuality)
				{
					var stageLight:BGSprite = new BGSprite('stage_light', -125, -100);
					stageLight.setGraphicSize(stageLight.width * 1.1);
					stageLight.updateHitbox();
					addLayer(stageLight);
					var stageLight:BGSprite = new BGSprite('stage_light', 1225, -100);
					stageLight.setGraphicSize(stageLight.width * 1.1);
					stageLight.updateHitbox();
					stageLight.flipX = true;
					addLayer(stageLight);

					var stageCurtains:BGSprite = new BGSprite('stagecurtains', -500, -300, 1.2, 1.2);
					stageCurtains.setGraphicSize(stageCurtains.width * 0.9);
					stageCurtains.updateHitbox();
					addLayer(stageCurtains);
				}
		}
		gf.setPosition(GF_X, GF_Y);
		boyfriend.setPosition(BF_X, BF_Y);
		dad.setPosition(DAD_X, DAD_Y);
		addCharacter(gf);
		addCharacter(dad);
		addCharacter(boyfriend);
		curStage = stage;

		gf.scrollFactor.set(0.95, 0.95);

		trace('Load Stage Scripts.');
		// STAGE SCRIPTS
		loadScript('stages/' + curStage);

		gf.visible = !stageData.hide_girlfriend;
		// var camPos:FlxPoint = FlxPoint.get(gfCameraOffset[0], gfCameraOffset[1]);
		// if (gf.visible){
		// 	camPos.x += gf.getGraphicMidpoint().x + gf.cameraPosition[0];
		// 	camPos.y += gf.getGraphicMidpoint().y + gf.cameraPosition[1];
		// }

		if (dad.curCharacter.startsWith('gf'))
		{
			dad.setPosition(GF_X, GF_Y);
			gf.visible = false;
		}
		// changeGF(startupData.gf);
		// changeDAD(startupData.dad);
		// changeBF(startupData.bf);
		startCharacterPos(gf);
		startCharacterPos(dad);
		startCharacterPos(boyfriend);

		scriptPack.call('onCreatePost');
		for (spr => data in layersMap) data.order = layers.members.indexOf(spr);
		updateListLayers();
		Paths.clearUnusedMemory();
		Paths.clearStoredMemory();
		updatePresence();
	}

	function loadScript(scriptFile:String)
	{
		#if LUA_ALLOWED
		final luaTL:String = AssetsPaths.getPath(scriptFile + ".lua");
		if (Assets.exists(luaTL))	loadLuaScript(luaTL);
		#end
		#if HSCRIPT_ALLOWED
		final hxTL:String = AssetsPaths.getPath(scriptFile + ".hx");
		if (Assets.exists(hxTL))	loadHScript(hxTL);
		#end
	}

	function loadHScript(path:String, ?classSwag:Dynamic, ?extraParams:Map<String, Dynamic>):HScript{
		if (classSwag == null) classSwag = FlxG.state;
		if (extraParams == null) extraParams = new Map<String, Dynamic>();
		final script = HScript.loadStateModule(path, classSwag, extraParams).getPlayStateParams();
		final deState = this;

		script.variables.set('game', deState);
		script.variables.set('PlayState', deState);
		script.variables.set('gfGroup', gf);
		script.variables.set('boyfriendGroup', boyfriend);
		script.variables.set('dadGroup', dad);
		script.variables.set('setVar', function(_) {});
		script.variables.set('getVar', function(_) {});
		script.variables.set('removeVar', function(_) {});
		script.variables.set('debugPrint', function(_) {});
		script.variables.set('add', function(obj:FlxBasic) if (Std.isOfType(obj, FlxSprite)) deState.addLayer(cast obj));
		script.variables.set('insert', function(pos:Int, obj:FlxBasic) if (Std.isOfType(obj, FlxSprite)) deState.insertLayer(pos, cast obj));
		script.variables.set('remove', function(obj:FlxBasic, splice:Bool = false) if (Std.isOfType(obj, FlxSprite)) deState.removeLayer(cast obj, splice));
		script.variables.set('addBehindGF', function(obj:FlxObject)
			if (Std.isOfType(obj, FlxSprite))
				deState.insertLayer(deState.layers.members.indexOf(deState.gf), cast obj)
		);
		script.variables.set('addBehindDad', function(obj:FlxObject)
			if (Std.isOfType(obj, FlxSprite))
				deState.insertLayer(deState.layers.members.indexOf(deState.dad), cast obj)
		);
		script.variables.set('addBehindBF', function(obj:FlxObject)
			if (Std.isOfType(obj, FlxSprite))
				deState.insertLayer(deState.layers.members.indexOf(deState.boyfriend), cast obj)
		);
		script.variables.set('createGlobalCallback', function(_){});
		script.variables.set('reorder', function(obj:flixel.FlxBasic, index:Int){
			script.variables['remove'](obj, true);
			return script.variables['insert'](index, obj);
		});
		script.variables.set('addBehindObject', function(obj:flixel.FlxObject, behindObj:flixel.FlxObject)
			return if (obj is FlxSprite && behindObj is FlxSprite) script.variables['insert'](deState.layers.members.indexOf(cast behindObj), cast obj)
		);
		script.variables.set('addAheadObject', function(obj:flixel.FlxObject, behindObj:flixel.FlxObject)
			return if (obj is FlxSprite && behindObj is FlxSprite) script.variables['insert'](deState.layers.members.indexOf(cast behindObj) + 1, cast obj)
		);
		script.variables.set('addHxObject', function(obj:FlxObject, front:Bool = false){
			if (!Std.isOfType(obj, FlxSprite)) return obj;
			final obj:FlxSprite = cast (obj, FlxSprite);

			return front ? deState.addLayer(obj) : deState.insertLayer(FlxMath.minInt(
				FlxMath.minInt(
						layers.members.indexOf(deState.gf),
						layers.members.indexOf(deState.boyfriend)
					),
						layers.members.indexOf(deState.dad)
				), obj);
		});
		script.variables.set('debugPrint', function(text:String, ?color:FlxColor = null) {
			if(color == null) color = FlxColor.WHITE;
			addTextToDebug(text, color);
		});
		hscriptArray.push(script);
		return script.execute();
	}

	function loadLuaScript(path:String)
	{
		#if LUA_ALLOWED
		final script = new FunkinLua(path);
		// Song/Week shit
		script.set('curBpm', 160);
		script.set('bpm', 160);
		script.set('scrollSpeed', 3);
		script.set('crochet', Conductor.calculateCrochet(160));
		script.set('stepCrochet', Conductor.calculateCrochet(160) / 4);
		script.set('songLength', 0);
		script.set('songName', '');
		script.set('startedCountdown', false);

		script.set('isStoryMode', false);
		// script.set('difficulty', PlayState.storyDifficulty);
		// script.set('difficultyName', CoolUtil.difficulties[PlayState.storyDifficulty]);
		script.set('weekRaw', 0);
		script.set('week', '');
		script.set('seenCutscene', false);

		// Gameplay settings
		script.set('healthGainMult', 1);
		script.set('healthLossMult', 1);
		script.set('instakillOnMiss', false);
		script.set('botPlay', false);
		script.set('practice', false);

		// Character shit
		script.set('boyfriendName', 'bf');
		script.set('dadName', 'dad');
		script.set('gfName', 'gf');
		inline function cameraFromString(cam:String):FlxCamera{
			return switch (cam.toLowerCase()) {
				case 'camhud' | 'hud':		camHUD;
				case 'camother' | 'other':	camOther;
				default:					camGame;
			}
		}
		script.addCallback("setObjectCamera", function(obj:String, camera:String = ''){
			var real = ScriptPackPlayState.instance.getLuaObject(obj);
			if (real != null){
				real.cameras = [cameraFromString(camera)];
				return true;
			}

			var killMe:Array<String> = obj.split('.');
			var object:FlxSprite = FunkinLua.getObjectDirectly(killMe[0]);
			if (killMe.length > 1) object = FunkinLua.getVarInArray(FunkinLua.getPropertyLoopThingWhatever(killMe), killMe[killMe.length - 1]);

			if (object != null){
				object.cameras = [cameraFromString(camera)];
				return true;
			}
			script.luaTrace("Object " + obj + " doesn't exist!", false, false, FlxColor.RED);
			return false;
		});

		script.addCallback("debugPrint", function(text1:Dynamic = '', text2:Dynamic = '', text3:Dynamic = '', text4:Dynamic = '', text5:Dynamic = ''){
			if (text1 == null) text1 = '';
			if (text2 == null) text2 = '';
			if (text3 == null) text3 = '';
			if (text4 == null) text4 = '';
			if (text5 == null) text5 = '';
			script.luaTrace('' + text1 + text2 + text3 + text4 + text5, true, false);
		});

		script.addCallback("triggerEvent", function(name:String, ?arg1:Dynamic = '', ?arg2:Dynamic = '', ?arg3:Dynamic = '', ?strumTime:Float = 0){});

		script.addCallback("addLuaSprite", function(tag:String, front:Bool = false){
			final shit:FunkinLua.ModchartSprite = ScriptPackPlayState.instance.modchartSprites.get(tag);
			if (shit != null && !shit.wasAdded){
				if (front)
					addLayer(shit);
				else{
					var position:Int = layers.members.indexOf(gf);
					if (layers.members.indexOf(boyfriend) < position)
						position = layers.members.indexOf(boyfriend);
					else if (layers.members.indexOf(dad) < position)
						position = layers.members.indexOf(dad);
					final position:Int = FlxMath.minInt(
							FlxMath.minInt(
								layers.members.indexOf(gf),
								layers.members.indexOf(boyfriend)
							),
								layers.members.indexOf(dad)
						);

					insertLayer(position, shit);
				}
				layersMap.get(shit).tag = tag;
				shit.wasAdded = true;

				// trace('added a thing: ' + tag);
			}
		});
		script.luaTrace = function(text:String, ignoreCheck:Bool = false, deprecated:Bool = false, color:FlxColor = FlxColor.WHITE) {
			if (ignoreCheck || script.getBool('luaDebugMode'))	{
				if (deprecated && !script.getBool('luaDeprecatedWarnings')) return;
				addTextToDebug(text, color);
				trace(text);
			}
		}

		script.addCallback("removeLuaSprite", function(tag:String, destroy:Bool = true){
			if (!ScriptPackPlayState.instance.modchartSprites.exists(tag))
				return;

			var pee:FunkinLua.ModchartSprite = ScriptPackPlayState.instance.modchartSprites.get(tag);
			if (destroy) pee.kill();

			if (pee.wasAdded){
				removeLayer(pee, true);
				pee.wasAdded = false;
			}

			if (destroy){
				pee.destroy();
				ScriptPackPlayState.instance.modchartSprites.remove(tag);
			}
		});

		/*
		script.addCallback("getProperty", function(variable:String, ?allowMaps:Bool = false){
			final killMe:Array<String> = variable.split('.');
			if(killMe.length > 1)
				return FunkinLua.getVarInArray(FunkinLua.getPropertyLoopThingWhatever(killMe), killMe[killMe.length-1], allowMaps);
			return FunkinLua.getVarInArray(FunkinLua.getInstance(), variable, allowMaps);
		});
		script.addCallback("setProperty", function(variable:String, value:Dynamic, allowMaps:Bool = false){
			final killMe:Array<String> = variable.split('.');
			if(killMe.length > 1)
				return FunkinLua.setVarInArray(FunkinLua.getPropertyLoopThingWhatever(killMe), killMe[killMe.length-1], value, allowMaps);
			return FunkinLua.setVarInArray(FunkinLua.getInstance(), variable, value, allowMaps);
		});
		*/
		script.addCallback("getPropertyFromGroup", function(obj:String, index:Int, variable:Dynamic, ?allowMaps:Bool = false){
			final split:Array<String> = obj.split('.');
			var realObject:Dynamic = null;
			if(split.length > 1)
				realObject = FunkinLua.getPropertyLoop(split, true, false, allowMaps);
			else
				realObject = Reflect.getProperty(FunkinLua.getInstance(), obj);

			if(Std.isOfType(realObject, FlxTypedGroup))
			{
				return FunkinLua.getGroupStuff(realObject.members[index], variable, allowMaps);
			}

			var leArray:Dynamic = realObject[index];
			if(leArray != null) {
				var result:Dynamic = null;
				if(Type.typeof(variable) == Type.ValueType.TInt)
					result = leArray[variable];
				else
					result = FunkinLua.getGroupStuff(leArray, variable, allowMaps);
				return result;
			}
			script.luaTrace("getPropertyFromGroup: Object #" + index + " from group: " + obj + " doesn't exist!", false, false, FlxColor.RED);
			return null;
		});

		script.addCallback("addCharacterToList", function(name:String, type:String){});
		script.addCallback("setPropertyFromGroup", function(obj:String, index:Int, variable:Dynamic, value:Dynamic, ?allowMaps:Bool = false){
			final split:Array<String> = obj.split('.');
			var realObject:Dynamic = null;
			if(split.length > 1)
				realObject = FunkinLua.getPropertyLoop(split, true, false, allowMaps);
			else
				realObject = Reflect.getProperty(FunkinLua.getInstance(), obj);

			if(Std.isOfType(realObject, FlxTypedGroup)) {
				FunkinLua.setGroupStuff(realObject.members[index], variable, value, allowMaps);
				return value;
			}

			final leArray:Dynamic = realObject[index];
			if(leArray != null) {
				if(Type.typeof(variable) == Type.ValueType.TInt) {
					leArray[variable] = value;
					return value;
				}
				FunkinLua.setGroupStuff(leArray, variable, value, allowMaps);
			}
			return value;
		});
		luaArray.push(script);
		script.execute();
		#end
	}

	var updateList = false;
	public function insertLayer(index:Int, Sprite:FlxSprite) {
		layers.insert(index, Sprite);
		setMap(Sprite);
		return Sprite;
	}
	public function removeLayer(Sprite:FlxSprite, destroy:Bool = false) {
		layers.remove(Sprite);
		final curData = layersMap.get(Sprite);
		if (curData != null){
			for (i in layersList._members){
				if (cast(i, SectionOfList).data == curData){
					layersList.remove(i, true);
					break;
				}
			}
		}
		if (destroy){
			if (curData != null) curData.obj = null; // remove reference
			layersMap.remove(Sprite);
			sortLayers();
		}
		return Sprite;
	}
	public function addLayer(Sprite:FlxSprite) {
		layers.add(Sprite);
		setMap(Sprite);
		return Sprite;
	}
	public function addCharacter(Char:Character) {
		addLayer(Char);
		settingCharacterData(Char);
		charactersList.push(Char);
		beatAnimList.push(Char);
		return Char;
	}
	function settingCharacterData(Char:Character, reset:Bool = true) {
		final _data = layersMap.get(Char);
		if (_data == null) return;
		_data.image = Char.imageFile; // funny
		_data.tag = Char.extraData.STAGE_EDITOR_CHARNAME;

		// Reset
		if (reset)
		{
			Char.scrollFactor.set(1, 1);
			Char.color = 0xFFFFFFFF;
			Char.alpha = 1;
			Char.visible = true;
		}
	}

	function setMap(Sprite:FlxSprite)
	{
		var imageStr:String = Sprite.graphic != null ? Sprite.graphic.key.substr(Sprite.graphic.key.indexOf('images/'), Sprite.graphic.key.indexOf('.')) : null;
		var fileName:String = CoolUtil.getLastOfArray(imageStr.split('/'));
		var filePlace:String = Sprite.graphic != null ? Sprite.graphic.key.substr(Sprite.graphic.key.indexOf('images/') + 'images/'.length) : null;
		#if sys
		final programPath = Sys.programPath();
		if(filePlace != null && filePlace.startsWith(programPath))
			filePlace = filePlace.substr(programPath.length);
		#end
		layersMap.set(Sprite, {
			obj: Sprite,
			tag:	Path.withoutExtension(fileName), // may stupid
			image:	filePlace,
			x:		Sprite.x,						y:		Sprite.y,
			width:	Std.int(Sprite.width),			height:	Std.int(Sprite.height),
			scaleX:	Sprite.scale.x,					scaleY:	Sprite.scale.y,
			scrollFactorX:Sprite.scrollFactor.x,	scrollFactorY:Sprite.scrollFactor.y,
			alpha:	Sprite.alpha,					color:	Sprite.color,
			invisible: !Sprite.visible
		});
	}

	function updateDataObj(Sprite:FlxSprite) {
		final _dataObj = layersMap.get(Sprite);
		if (_dataObj == null)
			return _dataObj;
		_dataObj.x					=	Sprite.x;
		_dataObj.y					=	Sprite.y;
		//  _dataObj.width			=	Std.int(Sprite.width);
		//  _dataObj.height			=	Std.int(Sprite.height);
		_dataObj.scaleX				=	Sprite.scale.x;
		_dataObj.scaleY				=	Sprite.scale.y;
		_dataObj.scrollFactorX		=	Sprite.scrollFactor.x;
		_dataObj.scrollFactorY		=	Sprite.scrollFactor.y;
		_dataObj.order				=	layers.members.indexOf(Sprite);

		if (Std.isOfType(Sprite, Character)){
			final Sprite:Character = cast Sprite;
			_dataObj.x -= Sprite.positionArray[0];
			_dataObj.y -= Sprite.positionArray[1];
		}

		return _dataObj;
	}
	function startCharacterLua(name:String){
		/*
		#if LUA_ALLOWED
		var doPush:Bool = false;
		var luaFile:String = 'characters/' + name + '.lua';
		#if MODS_ALLOWED
		if (FileSystem.exists(Paths.modFolders(luaFile)))
		{
			luaFile = Paths.modFolders(luaFile);
			doPush = true;
		}
		else
		{
			luaFile = Paths.getSharedPath(luaFile);
			if (FileSystem.exists(luaFile))
				doPush = true;
		}
		#else
		luaFile = Paths.getSharedPath(luaFile);
		if (Assets.exists(luaFile))
		{
			doPush = true;
		}
		#end

		if (doPush)
		{
			for (script in luaArray)
				if (script.scriptName == luaFile)
					return;

			luaArray.push(new FunkinLuaStEd(luaFile));
		}
		#end
		*/
	}

	function startCharacterPos(char:Character, ?gfCheck:Bool = false)
	{
		if (gfCheck && char.curCharacter.startsWith('gf')) // IF DAD IS gf, HE GOES TO HER POSITION
		{
			char.setPosition(GF_X, GF_Y);
			char.scrollFactor.set(0.95, 0.95);
			char.danceEveryNumBeats = 2;
		}
	}

	/*
	@:access(flixel.FlxSprite)
	override function draw() {
		super.draw();
		if (curObject != null && curObject.exists && curObject.visible){
			for (camera in curObject.cameras){
				if (camera.visible && camera.exists && curObject.isOnScreen(camera)){
					_flxhitbox.setPosition(curObject.x, curObject.y);
					_flxhitbox.angle = curObject.angle;
					_flxhitbox.origin.copyFrom(curObject.origin);
					_flxhitbox.offset.copyFrom(curObject.offset);
					_flxhitbox.scrollFactor.copyFrom(curObject.scrollFactor);
					_flxhitbox.scale.copyFrom(curObject.scale);
					_flxhitbox.cameras = [camera];
					_flxhitbox._frame = curObject._frame;
					// _hitboxShader.size = 30 / curObject.scale.x * curObject.scale.y;
					_hitboxShader.uv = curObject._frame.uv;
					// trace(curObject._frame.uv.toString());
					if (_flxhitbox.isSimpleRender(camera))
						_flxhitbox.drawSimple(camera);
					else
						_flxhitbox.drawComplex(camera);
				}
			}
		}
	}
	*/

	// SAVE STUFF

	function toArgumetsString(agrs:Array<Dynamic>)
		return [for (i in agrs) if (Std.isOfType(i, String)) '\'$i\'' else Std.string(i)].join(', ');

	var _fileJson:FileReference;
	var _fileLua:FileReference;

	function saveLua()
	{
		final charactersDatas = [for (i in charactersList) if (i != null && layersMap.exists(i)) layersMap.get(i)];
		final dadData = layersMap.get(dad);
		final gfData = layersMap.get(gf);
		final boyfriendData = layersMap.get(boyfriend);
		var objectsData:Array<SpriteData> = [for (_ => i in layersMap) i];
		var objectsNames:Array<String> = [];
		for (i in objectsData){
			while (objectsNames.contains(i.tag)){
				i.tag += '_clone';
			}
			objectsNames.push(i.tag);
		}
		objectsData.sort((a, b) -> return a.order > b.order ? 1 : -1);
		var data:String = '-- GENERETED BY TWIST ENGINE ${game.backend.data.EngineData.engineVersion}\r-- THANK YOU FOR USING THIS ENGINE FOR THE STAGE\r';
		data += "function onCreatePost()\r\r";
		for (dataObject in objectsData) // fuck it all
		{
			if (dataObject.tag == null || dataObject.tag.length == 0 ) continue;
			final obj = dataObject.obj;
			final charObj:Character = cast obj;
			final isChar = charactersDatas.contains(dataObject);
			if (isChar)
			{
				if (dataObject.tag == 'gfGroup')
				{
					if (dataObject.scrollFactorX != 0.95 || dataObject.scrollFactorY != 0.95)
						data += '\tsetScrollFactor(${toArgumetsString([dataObject.tag, dataObject.scrollFactorX, dataObject.scrollFactorY])})\r';
				}
				else
				{
					if (dataObject.scrollFactorX != 1 || dataObject.scrollFactorY != 1)
						data += '\tsetScrollFactor(${toArgumetsString([dataObject.tag, dataObject.scrollFactorX, dataObject.scrollFactorY])})\r';
				}
			}
			else
			{
				data += '\t${((dataObject.animations == null || dataObject.animations.length < 1) ?
					'makeLuaSprite' : 'makeAnimatedLuaSprite')}(${toArgumetsString([dataObject.tag,
						haxe.io.Path.withoutExtension(dataObject.image), dataObject.x, dataObject.y])
					})\r';

				if (dataObject.scrollFactorX != 1 || dataObject.scrollFactorY != 1)
					data += '\tsetScrollFactor(${toArgumetsString([dataObject.tag, dataObject.scrollFactorX, dataObject.scrollFactorY])})\r';
			}

			if (!isChar && dataObject.animations != null)
			{
				final unusedAnimations = dataObject.animations.filter((anim) -> return dataObject.curAnim != anim.anim);
				for (i in dataObject.animations)
				{
					if (i == null || unusedAnimations.contains(i)) continue;
					if (i.indices != null && i.indices.length > 0)
						data += '\taddAnimationByIndices(${toArgumetsString([dataObject.tag, i.anim, i.name, [for (i in i.indices) i].join(', '), i.fps, i.loop])})\r';
					else
						data += '\taddAnimationByPrefix(${toArgumetsString([dataObject.tag, i.anim, i.name, i.fps, i.loop])})\r';

					if (i.offsets != null && i.offsets.length > 1)
						data += '\taddOffset(${toArgumetsString([dataObject.tag, i.anim, i.offsets[0], i.offsets[1]])})\r';
				}
				if (dataObject.curAnim != null)
					data += '\tplayAnim(${toArgumetsString([dataObject.tag, dataObject.curAnim])})\r';
			}
			if (dataObject.alpha != 1)
				data += '\tsetProperty(\'${dataObject.tag}.alpha\', ${dataObject.alpha})\r';

			// if (dataObject.color != null && dataObject.color % 0x00ffffff != 0xffffff)
			// 	data += '\tsetProperty(\'${dataObject.tag}.color\', FlxColor(\'#${dataObject.color.toHexString(true, false)}\'))\r';

			if (dataObject.noAntialiasing)
				data += '\tsetProperty(\'${dataObject.tag}.antialiasing\', false)\r';

			if (dataObject.invisible)
				data += '\tsetProperty(\'${dataObject.tag}.visible\', false)\r';

			if (obj.flipX)
				data += '\tsetProperty(\'${dataObject.tag}.flipX\', true)\r';

			if (obj.flipY)
				data += '\tsetProperty(\'${dataObject.tag}.flipY\', true)\r';

			if (isChar){
				if (charObj.jsonScale != dataObject.scaleX || dataObject.scaleY != charObj.jsonScale)
					data += '\tscaleObject(${toArgumetsString([dataObject.tag, dataObject.scaleX, dataObject.scaleY])}, false)\r';
			}else
				if (dataObject.scaleX != 1 || dataObject.scaleY != 1)
					data += '\tscaleObject(${toArgumetsString([dataObject.tag, dataObject.scaleX, dataObject.scaleY])}, false)\r';

			if (isChar) continue;
			data += '\taddLuaSprite(${toArgumetsString([dataObject.tag, dataObject.order > Math.min(dadData.order, Math.min(gfData.order, boyfriendData.order))])})\r';
			data += '\r';
		}

		data += 'end';
		objectsData.clearArray();

		if (data.length <= 0) return;

		var savePath = FileUtil.getPathFromCurrentRoot([
			"stages",
			'$curStage.lua'
		]);
		FileUtil.browseForSaveFile([FileUtil.FILE_FILTER_LUA],
			path -> {
				#if sys
				sys.io.File.saveContent(path, data);
				#end
			},
			() -> FlxG.log.error("Problem saving json file"),
			savePath,
			'Save $curStage.lua');
		/*
		var a = new FileDialog();
		if(!a.save(data, 'lua', curStage + '.lua')) FlxG.log.error("Problem saving lua file");
		*/
	}
	function dummSave() {
		final dadData = layersMap.get(dad);
		final gfData = layersMap.get(gf);
		final boyfriendData = layersMap.get(boyfriend);
		final data = Json.stringify({
			directory: "",
			defaultZoom: defaultCamZoom,
			isPixelStage: false,
			typeNotes: 'fnf',

			boyfriend: [boyfriendData.x, boyfriendData.y],
			girlfriend: [gfData.x, gfData.y],
			opponent: [dadData.x, dadData.y],
			hide_girlfriend: false,

			camera_boyfriend: [0, 0],
			camera_opponent: [0, 0],
			camera_girlfriend: [0, 0],
			camera_speed: 1
		}, "\t");

		if (data.length <= 0) return;

		var savePath = FileUtil.getPathFromCurrentRoot([
			"stages",
			'$curStage.json'
		]);
		FileUtil.browseForSaveFile([FileUtil.FILE_FILTER_JSON],
			path -> {
				#if sys
				sys.io.File.saveContent(path, data);
				#end
				saveLua();
			},
			() -> {
				FlxG.log.error("Problem saving json file");
				saveLua();
			},
			savePath,
			'Save $curStage.json');
	}
}

// ALPHA
@:private class HitBoxShader extends flixel.system.FlxAssets.FlxShader {
	public var size(default, set):Float;
	inline function set_size(e:Float){
		this.size = e;
		this.sizes.value = [e];
		return color;
	}
	public var color(default, set):FlxColor;
	inline function set_color(color:FlxColor){
		this.color = color;
		this.colord.value = [color.redFloat, color.greenFloat, color.blueFloat, color.alphaFloat];
		return color;
	}
	public var uv(default, set):FlxRect;
	inline function set_uv(e:FlxRect){
		this.uv = e;
		this.uvMap.value = [uv.x, uv.y, uv.width, uv.height];
		return uv;
	}
	@:glFragmentSource('
		#pragma header

		uniform float sizes;
		uniform vec4 colord;
		uniform vec4 uvMap;

		void main()
		{
			// Normalized pixel coordinates (from 0 to 1)
			vec2 uv = openfl_TextureCoordv.xy-uvMap.xy;
			vec2 uvSize = uvMap.zw - uvMap.xy;

			//borderSize (adjust this)
			sizes /= length(openfl_TextureSize);

			//make the border
			float mid = sizes*(openfl_TextureSize.y/openfl_TextureSize.x);
			float left = step(uv.x,mid);
			float right = 1.0-step(uv.x,uvSize.x-mid);
			float top = step(uv.y,sizes);
			float bottom = 1.0-step(uv.y,uvSize.y-sizes);
			float sDf = max(max(max(left,top),bottom),right);

			// Output to screen
			gl_FragColor = colord * openfl_Alphav * sDf;
		}
	')
	public function new(size:Float = 30, color:FlxColor = 0x79FF0000) {
		super();
		this.size = size;
		this.color = color;
		uvMap.value = [0, 0, 1, 1];
	}
}