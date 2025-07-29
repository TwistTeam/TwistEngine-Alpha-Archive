package game.states.betterOptions;

// TODO: Rewrite this spagetti code

import flixel.text.FlxBitmapText;
import flixel.util.FlxTimer;
import haxe.extern.EitherType;

import flixel.input.gamepad.FlxGamepadInputID;
import flixel.system.FlxSound;
import flixel.util.FlxSort;
// import flixel.FlxCamera;
import flixel.addons.display.FlxRuntimeShader;
import flixel.graphics.FlxGraphic;
import flixel.group.FlxSpriteGroup;
import flixel.group.FlxGroup;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.math.FlxAngle;
import flixel.math.FlxRect;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.input.keyboard.FlxKey;
import flixel.input.mouse.FlxMouseEvent;
import flixel.util.FlxDestroyUtil;

import game.backend.data.StructureOptionsData;
import game.backend.system.CursorManager;
import game.backend.system.states.MusicBeatSubstate;
#if DISCORD_RPC
import game.backend.system.net.Discord;
#end
import game.backend.utils.ClientPrefs.*;
import game.backend.utils.ClientPrefs.defaultInstance as ClientPrefsDefault;
import game.backend.utils.Controls;
import game.backend.utils.MemoryUtil;
import game.objects.FlxStaticText;
import game.objects.improvedFlixel.addons.FlxTypeBitmapText;
import game.objects.ui.CustomList;
import game.objects.ui.FlxInputText;
import game.objects.ui.Slider;
import game.shaders.BloomOptionShader;
import game.states.betterOptions.*;
import game.states.playstate.PlayState;
import game.states.substates.PauseSubState;

import openfl.filters.ColorMatrixFilter;
import openfl.filters.ShaderFilter;
import openfl.geom.ColorTransform;
import openfl.text.TextFormat;
import openfl.media.Sound;

using flixel.util.FlxSpriteUtil;
using game.backend.utils.FlxBitmapFontTool;

class OptionSlider extends Slider
{
	public var parent:OptionSprite;

	var thatSound:FlxSound;
	public function new(parent:OptionSprite, width:Int = 200, height:Int = 30)
	{
		this.parent = parent;
		var min:Float = parent.data.minValue;
		var max:Float = parent.data.maxValue;
		if (parent.data.typeVar == INT)
		{
			min = Std.int(min);
			max = Std.int(max);
			// this.decimals = Std.int(Math.max(this.decimals, 1));
			// this.widthShit = Std.int(this.widthShit);
		}
		onPressedBind = () ->
		{
			parent.listParent.canDrag = false;
			if (OptionsSubState.instance.mouseMode)
				CursorManager.instance.cursor = 'button';
			OptionsSubState.curOption = parent;
		}
		onSelectedBind = () ->
		{
			parent.listParent.canDrag = false;
			if (OptionsSubState.instance.mouseMode)
				CursorManager.instance.cursor = 'button';
		}
		onStaticBind = () ->
		{
			parent.listParent.canDrag = true;
		}
		super(0, 0, width, height, (variable:Float, factor:Float) ->
		{
			var nextVar:Dynamic = this.parent.data.typeVar == INT ?
				Std.int(Math.fround((min + factor * widthShit) / decimals) * decimals)
			:
				FlxMath.roundDecimal(min + factor * widthShit, decimals);

			if (this.parent.data.variable != nextVar)
			{
				var sliderSound = OptionsSubState.instance.sliderSound;
				if (sliderSound != null)
				{
					@:privateAccess
					if (thatSound == null || thatSound._sound != sliderSound)
						thatSound = FlxG.sound.load(sliderSound, 0.6);
					thatSound.pitch = 1 + (factor - 0.5) / 8;
					thatSound.play(true);
				}

				ClientPrefs.setProperty(this.parent.data.variableName, nextVar);
				this.variable = this.parent.data.variable = nextVar;
				this.parent.setVarText();
				this.parent.data.onChange();
			}
		}, min, max, parent.data.variable, parent.data.decimals);
		bg.makeGraphic(width, height, 0xFF686868);
	}
}

private enum ButtonStatus
{
	BBSTATIC;
	BBSELECTED;
	BBPRESSED;
	BBRELEASED;
}

private typedef InputKey = EitherType<FlxKey, FlxGamepadInputID>;

class InputText extends FlxText
{
	public function new(X:Float = 0, Y:Float = 0, FieldWidth:Float = 0, ?Text:String, Size:Int = 8, EmbeddedFont:Bool = true)
	{
		super(X, Y, FieldWidth, Text, Size, EmbeddedFont);
		active = false;
	}
	override function regenGraphic()
	{
		super.regenGraphic();
		graphic.persist = false;
	}
	public var key:InputKey;
	public var curScale:Float = 1;
	public var status:ButtonStatus = BBSTATIC;
	public override function draw()
	{
		scale.x = scale.y = CoolUtil.fpsLerp(scale.x, curScale, 0.4);
		super.draw();
		if (OptionsSubState.instance.mouseMode && status != BBSTATIC)
			CursorManager.instance.cursor = 'button';
	}
}

class InputGroupText extends FlxTypedGroup<InputText>
{
	public var parent:OptionSprite;
	public var selectedText(default, set):InputText;

	public var isValid:Bool = true;

	function set_selectedText(newTxt:InputText)
	{
		if (selectedText != newTxt)
		{
			if (selectedText != null)
				selectedText.curScale = 1;
			selectedText = newTxt;
			if (newTxt != null)
				newTxt.curScale = 1.2;
		}
		return selectedText;
	}

	public var displayGamepad:Bool = OptionsSubState.instance?.controllerMode;

	public function updateTexts(?resetSelected:Bool = true)
	{
		var curX:Float = parent.textVarX;
		if (resetSelected && selectedText != null)
		{
			selectedText.status = BBSTATIC;
			selectedText = null;
		}
		forEachAlive(spr -> {
			spr.kill();
			parent.remove(spr, true);
			if (spr.key != null)
				FlxMouseEvent.remove(spr);
		});
		var formatKey:InputKey -> String = displayGamepad ? i -> i.bindToString() : i -> i.keyToString();
		function spawnTxtSpr(key:InputKey = null, txt:String = null)
		{
			var txtSpr = recycle(() -> {
				var txtSpr = new InputText();
				txtSpr.setFormat(Paths.font('PhantomMuff Full Letters 1-1-5.ttf'), 20, 0xFFFFFFFF, LEFT);
				txtSpr.moves = false;
				return txtSpr;
			});
			if (resetSelected || txtSpr != selectedText)
			{
				txtSpr.status = BBSTATIC;
				txtSpr.curScale = 1.;
				txtSpr.scale.set(1, 1);
			}
			txtSpr.text = txt ?? formatKey(key);
			txtSpr.key = key;
			if (key != null)
				FlxMouseEvent.add(txtSpr, onPress, onRelease.bind(true), onOver, onOut, false, true, false);
			curX -= txtSpr.width;
			txtSpr.setPosition(curX, (parent.bg.height - txtSpr.height) / 2);
			add(txtSpr);
			parent.add(txtSpr);
			return txtSpr;
		}
		isValid = false;
		if (parent == null)
		{
			spawnTxtSpr(null, "---");
		}
		else
		{
			final keys:Array<InputKey> = (displayGamepad ? ClientPrefs.gamepadBinds.get(parent.data.variableName) : ClientPrefs.keyBinds.get(parent.data.variableName));
			if (keys == null)
			{
				spawnTxtSpr(null, "---");
			}
			else
			{
				isValid = true;
				spawnTxtSpr(keys[0]);
				if (keys.length > 1)
					for(i in 1...keys.length)
					{
						spawnTxtSpr(null, " / ");
						spawnTxtSpr(keys[i]);
					}
			}
		}
	}
	public function new(parent:OptionSprite)
	{
		this.parent = parent;
		super();
	}

	public function applySetting(key:InputKey):Bool
	{
		if (Std.int(key) < 0) return true;
		final arrayInput:Dynamic = displayGamepad ? ClientPrefs.gamepadBinds.get(parent.data.variableName) : ClientPrefs.keyBinds.get(parent.data.variableName);
		final arrayInput:Array<Int> = cast arrayInput;
		if (arrayInput != null)
		{
			// if (displayGamepad)
			// {
			// 	for (_ => i in ClientPrefs.gamepadBinds)
			// 		if (i.contains(key))
			// 			return false;
			// }
			// else
			// {
			// 	for (_ => i in ClientPrefs.keyBinds)
			// 		if (i.contains(key))
			// 			return false;
			// }

			var curIndex = arrayInput.indexOf(selectedText?.key) ?? (arrayInput.length - 1);

			arrayInput[curIndex] = key;

			if (arrayInput.contains(key))
			{
				// arrayInput.remove(key);
				// arrayInput.push(-1);
				for (i => input in arrayInput)
				{
					if (input == key && i != curIndex)
					{
						arrayInput.remove(input);
						arrayInput.push(-1);
					}
				}

				// return false;
			}

			updateTexts(false);

			if (selectedText != null)
			{
				selectedText.curScale = 1.2;
				selectedText.scale.x = selectedText.scale.y = selectedText.curScale * 0.75;
			}
		}
		return true;
	}

	public function onPress(spr:InputText)
	{
		spr.status = BBPRESSED;
		// animation.play('push');
	}

	public function onRelease(apply:Bool = true, spr:InputText)
	{
		spr.status = BBRELEASED;
		parent.listParent.canDrag = false;
		if (apply && !OptionsSubState.instance.selectKey /*&& OptionsSubState.curOption == parent && selectedText == spr*/)
		{
			FlxG.sound.play(
				Paths.sound("optionsStuff/" + (displayGamepad ? "bindPadChange" : "keyBoardChange"))
			).pitch = FlxMath.roundDecimal(FlxG.random.float(0.8, 1.2) * 0.8, 2);
			OptionsSubState.instance.selectKey = true;
			OptionsSubState.instance.mouseMode = true;
			spr.curScale = 1.35;
			spr.scale.x = spr.scale.y = spr.curScale * 1.1;
		}
		OptionsSubState.curOption = parent;
		selectedText = spr;
	}

	public function onOver(spr:InputText)
	{
		spr.status = BBSELECTED;

		if (parent.listParent.canDrag == true)
			parent.data.onEmergence();
		parent.listParent.canDrag = false;
	}

	public function onOut(spr:InputText)
	{
		spr.status = BBSTATIC;

		// animation.play('idle');
		if (parent.listParent.canDrag == false)
			parent.data.onOut();
		parent.listParent.canDrag = true;
	}

	public override function destroy()
	{
		forEachAlive(spr -> {
			parent.remove(spr, true);
			if (spr.key != null)
				FlxMouseEvent.remove(spr);
		});
		super.destroy();
		parent = null;
	}
}
class ArrowPress extends FlxSprite
{
	private var origScale:Float = 1;

	public var parent:OptionSprite;
	public var left:Bool;
	public var status:ButtonStatus = BBSTATIC;

	public function new(left:Bool = false, parent:OptionSprite)
	{
		super();
		this.parent = parent;
		frames = Paths.getSparrowAtlas('campaign_menu_UI_assets', false);
		animation.addByPrefix('idle', (this.left = left) ? 'arrow left' : 'arrow right', 0);
		setGraphicSize(18);
		updateHitbox();
		animation.play('idle');
		color = 0xFF333333;
		origScale = (scale.x + scale.y) / 2;
		FlxMouseEvent.add(this, _ -> onPress(), _ -> onRelease(), /* null, */_ -> onOver(), _ -> onOut(), false, true, false);
	}

	public override function update(elapsed:Float):Void
	{
		super.update(elapsed);
		if (OptionsSubState.instance.mouseMode && status != BBSTATIC)
			CursorManager.instance.cursor = 'button';
	}

	@:noCompletion var _lastChange:Bool = true;

	public function onPress(change:Bool = true)
	{
		status = BBPRESSED;
		// animation.play('push');
		color = 0xFFFFFFFF;
		scale.x = scale.y = origScale * 1.1;
		_lastChange = change;
	}

	public function onRelease()
	{
		status = BBRELEASED;
		color = 0xFF999999;
		parent.listParent.canDrag = false;
		scale.x = scale.y = origScale * 1.01;
		OptionsSubState.curOption = parent;
		applySetting();
		OptionsSubState.instance.optChFlxSound?.play(true);
	}

	public function applySetting(?changeIndex:Bool = true)
	{
		switch (parent.data.typeVar)
		{
			case STR | CATEGORY | DYNAMIC:
				var curData:CategoryFunction = parent.getCurCategData();
				if (curData == null && !changeIndex)
					return;

				var nextIndex:Int = FlxMath.wrap(
					(curData == null ? 0 :
					parent.data.arrayData.indexOf(curData))
					+ (changeIndex ? (left ? -1 : 1) * (FlxG.keys.pressed.SHIFT ? 2 : 1) : 0), 0,
					parent.data.arrayData.length - 1);
				curData = parent.data.arrayData[nextIndex];
				if (_lastChange)
					ClientPrefs.setProperty(parent.data.variableName, curData.variable);
				parent.data.variable = ClientPrefs.field(parent.data.variableName);
				parent.setVarText(curData.display);
				OptionsSubState.instance.updatePositions();
				if (_lastChange)
				{
					parent.data.onChange();
					curData.thing();
				}
			case BOOL:
				if (_lastChange)
					ClientPrefs.setProperty(parent.data.variableName, ClientPrefs.field(parent.data.variableName) != true);
				parent.data.variable = ClientPrefs.field(parent.data.variableName);
				parent.setVarText();
				OptionsSubState.instance.updatePositions();
				if (_lastChange)
					parent.data.onChange();
			default:
		}
	}

	public function onOver(changeParent:Bool = true)
	{
		status = BBSELECTED;
		if (changeParent)
		{
			// OptionsSubState.curOption = parent;
			OptionsSubState.lastDir[left ? 1 : 0] = true;
		}
		color = 0xFF999999;
		if (parent.listParent.canDrag == true)
			parent.data.onEmergence();
		parent.listParent.canDrag = false;
		scale.x = scale.y = origScale * 1.02;
		if (left)
			parent.arrowRight.onOut(false);
		else
			parent.arrowLeft.onOut(false);
		OptionsSubState.lastDir[left ? 0 : 1] = false;
	}

	public function onOut(changeParent:Bool = true)
	{
		status = BBSTATIC;
		if (changeParent)
		{
			// parent.alpha = 0.8;
			OptionsSubState.lastDir[left ? 1 : 0] = false;
			CursorManager.instance.cursor = null;
		}
		color = 0xFF333333;
		// animation.play('idle');
		if (parent.listParent.canDrag == false)
			parent.data.onOut();
		parent.listParent.canDrag = true;
		scale.x = scale.y = origScale;
	}

	public override function destroy()
	{
		parent = null;
		FlxMouseEvent.remove(this);
		super.destroy();
	}
}

class CategoryArrowSpr extends FlxSprite
{
	private var origScale:Float = 1;

	public var isLocked:Bool = false;
	public var _tween:FlxTween;
	public var parent:OptionSprite;
	public var status:ButtonStatus = BBSTATIC;

	public function new(parent:OptionSprite)
	{
		this.parent = parent;
		super();
		isLocked = Reflect.field(FlxG.save.data, "OPT_CATEG_" + (parent.data.variableName ?? parent.data.display)) == true;
		frames = Paths.getSparrowAtlas('campaign_menu_UI_assets', false);
		animation.addByPrefix('idle', "arrow left", 0);
		setGraphicSize(18);
		updateHitbox();
		animation.play('idle');
		color = 0xFF333333;
		angle = isLocked ? 0 : -90;
		origScale = (scale.x + scale.y) / 2;
		FlxMouseEvent.add(this, _ -> onPress(), _ -> onRelease(), _ -> onOver(), _ -> onOut(), false, true, false);
	}

	public override function update(elapsed:Float):Void
	{
		super.update(elapsed);
		if (OptionsSubState.instance.mouseMode && status != BBSTATIC)
			CursorManager.instance.cursor = 'button';
	}

	public function onPress()
	{
		status = BBPRESSED;
		// animation.play('push');
		color = 0xFFFFFFFF;
		scale.x = scale.y = origScale * 1.1;
	}

	public function onRelease()
	{
		status = BBRELEASED;
		color = 0xFF999999;
		parent.listParent.canDrag = false;
		scale.x = scale.y = origScale * 1.01;
		OptionsSubState.curOption = parent;
		changeLock(!isLocked);
		OptionsSubState.instance.optChFlxSound?.play(true);
	}

	public function changeLock(locked:Bool, snap:Bool = false)
	{
		if (isLocked != locked)
		{
			isLocked = locked;
			if (snap)
			{
				angle = locked ? 0 : -90;
			}
			else
			{
				_tween?.cancel();
				_tween = FlxTween.num(angle, locked ? 0 : -90, 0.15, {ease: FlxEase.backOut, onComplete: _ -> _tween = null}, set_angle);
			}
			Reflect.setField(FlxG.save.data, "OPT_CATEG_" + (parent.data.variableName ?? parent.data.display), isLocked);
			OptionsSubState.instance.updatePositions();
		}
	}

	public function onOver()
	{
		status = BBSELECTED;
		color = 0xFF999999;
		if (parent.listParent.canDrag == true)
			parent.data.onEmergence();
		parent.listParent.canDrag = false;
		scale.x = scale.y = origScale * 1.02;
	}

	public function onOut(changeParent:Bool = true)
	{
		status = BBSTATIC;
		if (changeParent)
		{
			// parent.alpha = 0.8;
			// OptionsSubState.curOption = parent;
			CursorManager.instance.cursor = null;
		}
		color = 0xFF333333;
		// animation.play('idle');
		if (parent.listParent.canDrag == false)
			parent.data.onOut();
		parent.listParent.canDrag = true;
		scale.x = scale.y = origScale;
	}

	public override function destroy()
	{
		parent = null;
		_tween?.cancel();
		FlxMouseEvent.remove(this);
		super.destroy();
	}
}

typedef ButtonData =
{
	var widthOffset:Int;
	var indexOffset:Int;
	var height:Int;
}

class OptionSprite extends FlxSpriteGroup
{
	public static inline final START_X_OPTIONS:Int = 360;
	public static inline final WIDTH_OPTIONS:Int = 220;
	public static inline final BG_PADDING:Int = 22;

	public var canRestart:Bool = true;
	public var defaultVar:Dynamic = true;

	public var listParent:CustomList;
	public var parent:OptionSprite;
	public var childs:Array<OptionSprite> = [];
	public var data:SaveOption;

	public var origID:Int;

	public var bg:FlxSprite;
	public var displayText:FlxStaticText;
	public var textVar:FlxStaticText;

	public var arrowLeft:ArrowPress;
	public var arrowRight:ArrowPress;

	public var categArrow:CategoryArrowSpr;

	public var slider:OptionSlider;

	public var controlText:InputGroupText;

	public var textVarX:Float = 0;
	public var textVarWidth:Float = WIDTH_OPTIONS;

	public function new(data:SaveOption, parent:OptionSprite, listParent:CustomList, buttData:ButtonData, ?canRestart:Bool = true, ?x:Float = 0, ?y:Float = 0)
	{
		super();
		this.canRestart = canRestart && this.data?.typeVar != INPUT; // NOT AVAILABLE FOR INPUT
		if (canRestart)
		{
			// defaultVar = Reflect.field(ClientPrefs);
		}
		this.x = x + 40;
		this.y = y;
		this.data = data;
		this.parent = parent;
		this.listParent = listParent;
		if (parent != null)
			parent.childs.push(this);

		add(bg = createBGSpr(listParent.width - 80 - buttData.indexOffset * buttData.widthOffset - listParent.outView * 2, buttData.height, BG_PADDING));

		displayText = new FlxStaticText();
		inline function format(text:FlxText)
		{
			text.setFormat(Paths.font('PhantomMuff Full Letters 1-1-5.ttf'), 20, 0xFFFFFFFF, LEFT);
		}
		format(displayText);
		displayText.text = this.data.display ?? (this.data.typeVar == INPUT ? this.data.display : this.data.variableName);
		displayText.setPosition(10, (bg.height - displayText.height) / 2);
		add(displayText);

		switch (this.data.typeVar)
		{
			case FLOAT | PERCENT | INT:
				slider = new OptionSlider(this, WIDTH_OPTIONS - 60, 8);
				slider.x = START_X_OPTIONS + 30 - this.x;
				slider.y = bg.height - slider.height - BG_PADDING - 16;

				textVar = new FlxStaticText();
				format(textVar);
				textVarX = textVar.x = START_X_OPTIONS;
				textVar.y = slider.y - textVar.height;
				add(slider);
				add(textVar);
				setVarText(true);
			case INPUT:
				textVarX = bg.width - BG_PADDING - 14 - 40;
				controlText = new InputGroupText(this);
				controlText.updateTexts();
			// case STR | CATEGORY:
			// case BOOL:
			case STR | CATEGORY | BOOL | DYNAMIC:
				arrowLeft = new ArrowPress(true, this);
				arrowLeft.x = START_X_OPTIONS - this.x;
				arrowLeft.y = (bg.height - arrowLeft.height) / 2;

				arrowRight = new ArrowPress(false, this);
				arrowRight.x = arrowLeft.x + WIDTH_OPTIONS - arrowRight.width;
				arrowRight.y = (bg.height - arrowRight.height) / 2;

				textVar = new FlxStaticText();
				format(textVar);
				textVarX = textVar.x = START_X_OPTIONS;
				textVar.y = (bg.height - textVar.height) / 2;
				add(arrowLeft);
				add(arrowRight);
				add(textVar);
				setVarText(true);
			case NONE:
				displayText.size += 10;
				displayText.setPosition((bg.width - displayText.width) / 2, (bg.height - displayText.height) / 2);

				categArrow = new CategoryArrowSpr(this);
				add(categArrow);
				categArrow.setPosition(x + bg.width - BG_PADDING - 24 - categArrow.width, (bg.height - categArrow.height) / 2);

			default:
		}
		antialiasing = true;
		moves = false;
	}

	public function updateControlText(?controllerMode:Bool, ?resetSelected:Bool)
	{
		if (controlText != null)
		{
			if (controllerMode != null)
				controlText.displayGamepad = controllerMode;
			controlText.updateTexts(resetSelected ?? true);
		}
	}

	extern public static inline function createBGSpr(width, height, padding)
	{
		var bg = new FlxSprite().makeGraphic(width + padding * 2, height + padding * 2, FlxColor.TRANSPARENT);
		bg.offset.x = padding;
		// final e = FlxG.stage.quality;
		// FlxG.stage.quality = LOW;
		bg.drawRoundRect(padding, padding, width, height, 10, 10, 0xFF0A0A0A, {
			thickness: 4,
			color: 0xFF5F5F5F,
			jointStyle: ROUND,
			// miterLimit: 3
		});
		// FlxG.stage.quality = e;
		bg.alpha = 0.7;
		return bg;
	}

	var textVarTween:FlxTween;

	public function setVarText(?textNext:String, ?cancelTween:Bool = false)
	{
		if (textVar == null)
			return;
		textNext ??= switch (data.typeVar)
		{
			case STR | CATEGORY | DYNAMIC: getCurCategData()?.display ?? Std.string(data.variable);
			default: Std.string(data.variable);
		}
		var oldText = textVar.text;
		switch (data.typeVar)
		{
			case INT | FLOAT:
				textVar.text = data.displayFormat.replace('%v', textNext);
			case PERCENT:
				textVar.text = data.displayFormat.replace('%v', Std.string(Std.parseFloat(textNext) * 100));
			case STR | CATEGORY | DYNAMIC:
				textVar.text = data.displayFormat.replace('%v', textNext.replace("_", " ").toUpperCase());
			case BOOL:
				textVar.text = data.variable == true ? "ON" : "OFF";
			default:
		}
		if (oldText == textVar.text)
			return;
		textVar.x = textVarX - (textVar.width - textVarWidth) / 2;
		if (!cancelTween)
		{
			OptionsSubState.instance.checkRestartVariables();

			textVarTween?.cancel();
			textVar.scale.set(1.05, 1.05);
			textVarTween = FlxTween.tween(textVar.scale, {x: 1, y: 1}, 0.2, {ease: FlxEase.circOut});
		}
	}

	public function getCurCategData()
	{
		if (data.arrayData != null)
		{
			for (i in data.arrayData)
			{
				if (i.variable == data.variable)
				{
					return i;
				}
			}
		}
		return null;
	}

	public override function destroy()
	{
		if (textVarTween != null)
		{
			textVarTween.cancel();
			textVarTween = null;
		}
		childs.clearArray();
		controlText = FlxDestroyUtil.destroy(controlText);
		data = null;
		parent = null;
		listParent = null;
		bg = null;
		displayText = null;
		textVar = null;
		slider = null;
		arrowLeft = null;
		arrowRight = null;
		super.destroy();
	}

	override public function draw():Void
	{
		var camera = this.camera;
		if (!camera.visible || !camera.exists || !isOnScreen(camera))
			return;
		group.draw();

		#if FLX_DEBUG
		if (FlxG.debugger.drawDebug)
			drawDebug();
		#end
	}

	override function getScreenBounds(?newRect:FlxRect, ?camera:flixel.FlxCamera):FlxRect
	{
		return bg.getScreenBounds(newRect, camera);
	}

	// public override function toString():String
	// 	return 'This: ${data.variableName} || Id: $origID | CurretId: $ID || Parent: ${parent.data.variableName} || Childs: ${[for(i in childs) i.data.variableName]}';
}

@:access(flixel.FlxSprite)
@:access(game.backend.utils.Controls)
class OptionsSubState extends MusicBeatSubstate
{
	public static var instance:OptionsSubState;

	public var inGame(get, never):Bool;
	@:noCompletion inline function get_inGame():Bool return PlayState.instance != null;

	static var curCategory:String = 'VISUAL UI';

	var categories:Array<String> = ['VISUAL UI', 'GAMEPLAY', 'GRAPHICS', 'CONTROLS' #if DEV_BUILD , "DEV" #end];

	public var options:CustomList;
	public var _members:Array<OptionSprite> = [];
	public var _categories:Array<OptionSprite> = [];

	var _restartVariables:Map<String, Dynamic> = new Map<String, Dynamic>();
	var _neededToRestart(default, set):Bool = false;
	function set__neededToRestart(a:Bool)
	{
		if (_neededToRestart != a)
		{
			_restartTextTween?.cancel();
			_restartTextTween = FlxTween.num(restartText.alpha, a ? 0.6 : 0, a ? 0.6 : 0.2,
				{ease: FlxEase.quintInOut, onComplete: _ -> _restartTextTween = null},
				restartText.set_alpha);
		}
		return _neededToRestart = a;
	}
	public function checkRestartVariables()
	{
		var neededToRestart:Bool = false;
		for (i => variable in _restartVariables)
			if (ClientPrefs.field(i) != variable)
			{
				neededToRestart = true;
				break;
			}
		this._neededToRestart = neededToRestart;
	}

	public var neededToRestart(get, never):Bool;
	@:noCompletion inline function get_neededToRestart():Bool return _neededToRestart;

	private var camOptions:FlxCamera;

	public var mouseMode:Bool = true;
	public var enableBGOverlay:Bool = true;

	@:allow(game.backend.data.StructureOptionsData)
	var _generateCategories:Bool = false;

	public var allowControl:Bool = true;
	public var selectKey:Bool = false;

	public static var curOption(default, set):OptionSprite = null;
	public static var curOptionIndex:Int = 0;
	public static var lastDir:Array<Bool> = [false, false];
	public static var curLightShader:BloomOptionShader;

	var _categoriesSprs:Array<FlxStaticText> = [];

	// @:noCompletion
	static function set_curOption(newOption:OptionSprite):OptionSprite
	{
		if (curOption?.ID ?? -1 != newOption?.ID ?? -1)
		{
			if (curOption != null && curOption.exists)
			{
				if (curOption.arrowRight != null)
					curOption.arrowRight.onOut(false);
				if (curOption.arrowLeft != null)
					curOption.arrowLeft.onOut(false);

				if (curOption.slider != null)
					curOption.slider.onStatic();

				if (curOption.controlText != null && curOption.controlText.selectedText != null)
				{
					curOption.controlText.onOut(curOption.controlText.selectedText);
					curOption.controlText.selectedText = null;
				}

				if (curOption.categArrow != null)
					curOption.categArrow.onOut();

				curOption.bg.shader = null;
				curOption.bg.alpha = 0.7;
			}
			if (newOption != null && newOption.exists)
			{
				if (newOption.canRestart)
				{
					if (newOption.arrowRight != null)
					{
						if (lastDir[0])
							newOption.arrowRight.onOver();
						else
							newOption.arrowRight.onOut();
					}

					if (newOption.categArrow != null)
						newOption.categArrow.onOver();

					if (newOption.arrowLeft != null)
					{
						if (lastDir[1])
							newOption.arrowLeft.onOver();
						else
							newOption.arrowLeft.onOut();
					}

					if (newOption.slider != null)
						newOption.slider.onSelected();
				}
				newOption.bg.shader = curLightShader;
				if (curLightShader == null) newOption.bg.alpha = 1.0;
				curOptionIndex = instance._members.indexOf(newOption);
				OptionsSubState.instance.optChFlxSound?.play(true);
			}
			var descriptionText = instance.descriptionText;
			if (descriptionText != null)
			{
				var newText = newOption?.data.description ?? "";
				descriptionText.resetText(newText);
				descriptionText.start(null, true);
				descriptionText.typeCallback();
				descriptionText.visible = newText.length != 0;
			}
		}
		return curOption = newOption;
	}

	var lastMouseVisible:Bool;
	#if DISCORD_RPC
	// var lastDiscordPresence:DPresence = {};
	var lastDiscordDetails:String;
	#end
	public function new(?onOpen:Void -> Void, ?onClose:Void -> Void, ?disableBGOverlay:Bool)
	{
		enableBGOverlay = !disableBGOverlay;
		lastMouseVisible = FlxG.mouse.visible;
		instance = this;
		super();
		openCallback = () -> {
			#if DISCORD_RPC
			// for(i in Reflect.fields(DiscordClient.presence))
			// 	Reflect.setField(lastDiscordPresence, i, Reflect.getProperty(DiscordClient.presence, i));
			final presence = DiscordClient.presence;
			lastDiscordDetails = presence.details ?? "";
			DiscordClient.changePresence("In Options", presence.state, 0, {
				smallImage: presence.smallImageKey,
				smallText: presence.smallImageText,
				largeImage: presence.largeImageKey,
				largeText: presence.largeImageText,
				button1Label: presence.button1Label,
				button1Url: presence.button1Url,
				button2Label: presence.button2Label,
				button2Url: presence.button2Url
			});
			#end
			FlxG.mouse.visible = true;
			if (onOpen != null)
				onOpen();
		}
		closeCallback = () -> {
			#if DISCORD_RPC
			// for(i in Reflect.fields(lastDiscordPresence))
			// 	Reflect.setField(DiscordClient.presence, i, Reflect.field(lastDiscordPresence, i));
			final presence = DiscordClient.presence;
			DiscordClient.changePresence(lastDiscordDetails, presence.state, 0, {
				smallImage: presence.smallImageKey,
				smallText: presence.smallImageText,
				largeImage: presence.largeImageKey,
				largeText: presence.largeImageText,
				button1Label: presence.button1Label,
				button1Url: presence.button1Url,
				button2Label: presence.button2Label,
				button2Url: presence.button2Url
			});
			#end
			FlxG.mouse.visible = lastMouseVisible;
			if (onClose != null)
				onClose();
			if (!_parentState.destroySubStates)
				destroy(); // he's going to die anyway
		}
	}

	var _isControllerModeInput:Bool;
	var descriptionText:FlxTypeBitmapText;
	var txtTipe:FlxStaticText;
	var titleText:FlxStaticText;
	var restartText:FlxStaticText;
	var _restartTextTween:FlxTween;
	var topBar:FlxSprite;
	var bottomBar:FlxSprite;

	var optionTweens:FlxTweenManager;


	static var optionsControls:Controls = new Controls([
		"ui_up"		 => [W,			 UP],
		"ui_left"	 => [A,			 LEFT],
		"ui_down"	 => [S,			 DOWN],
		"ui_right"	 => [D,			 RIGHT],

		"accept"	 => [SPACE,		 ENTER],
		"back"		 => [BACKSPACE,	 ESCAPE],
		"reset"		 => [R]
	], [
		"ui_up"		 => [DPAD_UP,	 LEFT_STICK_DIGITAL_UP],
		"ui_left"	 => [DPAD_LEFT,	 LEFT_STICK_DIGITAL_LEFT],
		"ui_down"	 => [DPAD_DOWN,	 LEFT_STICK_DIGITAL_DOWN],
		"ui_right"	 => [DPAD_RIGHT, LEFT_STICK_DIGITAL_RIGHT],

		"accept"	 => [A,			 START],
		"back"		 => [B],
		"reset"		 => [BACK]
	]);

	public var resetSound:Sound;
	public var sliderSound:Sound;
	public var optChFlxSound:FlxSound;
	public var categChSound:Sound;

	@:access(flixel.text.FlxText)
	public override function create()
	{
		resetSound = Paths.sound("optionsStuff/reset");
		sliderSound = Paths.sound("optionsStuff/sliderShit");
		optChFlxSound = FlxG.sound.load(Paths.sound("optionsStuff/optCh") ?? Paths.sound("dialogue"));
		categChSound = Paths.sound("optionsStuff/categCh");
		if (inGame)
		{
			function a(datas:Array<SaveOption>)
			{
				if (datas == null) return;
				for(data in datas)
				{
					if (data.changeInGameplay != true && data.typeVar != INPUT)
						_restartVariables.set(data.variableName, ClientPrefs.field(data.variableName));
					a(data.things);
				}
			}

			for (_ => i in StructureOptionsData.data)
				a(i);
			if (StructureOptionsData.runtimeData != null)
				for (_ => i in StructureOptionsData.runtimeData)
					a(i);
		}

		add(optionTweens = new FlxTweenManager());

		bgShader = new FlxRuntimeShader(Assets.getText(Paths.shaderFragment('engine/bgOnOptions')));
		bgShader.setFloat("iFactor", _bgShaderFactor);

		camOptions = new FlxCamera();
		bgColor = camOptions.bgColor = FlxColor.TRANSPARENT;

		toogleBGTransition(true, 0.44, FlxEase.cubeOut);

		FlxG.cameras.add(camOptions, false);
		cameras = [camOptions];
		#if !web
		// Uncaught TypeError: parameter 1 is not of type 'WebGLUniformLocation'at openfl_display_ShaderParameter.__updateGL | ermm how
		curLightShader = new BloomOptionShader();
		#end
		options = new CustomList(72, 200, 660, 426, true);
		options.parentCamera = camOptions;
		options.filters = [
			new ShaderFilter(new FlxRuntimeShader(Assets.getText(Paths.shaderFragment('engine/gradientOption'))))
		];
		options.bgColor = FlxColor.TRANSPARENT;
		// options.slider.camera = camOptions;
		// options.slider.setPosition(options.x + options.width - options.slider.width, options.y);
		super.create();
		optionTweens.tween(options, {x: -options.width * 1.3}, 0.5, {ease: FlxEase.cubeOut, type: BACKWARD});

		bgSprite.cameras = cameras;

		topBar = new FlxSprite().makeSolid(FlxG.width * 1.5, 78 * 2, 0xFF000000);
		topBar.screenCenter(X);
		topBar.y = -topBar.height / 2;
		topBar.angle = -3;
		add(topBar);
		optionTweens.tween(topBar, {y: topBar.y - topBar.height}, 0.5, {ease: FlxEase.cubeOut, type: BACKWARD});

		bottomBar = new FlxSprite().makeSolid(topBar.width, topBar.height, 0xFF000000);
		bottomBar.screenCenter(X);
		bottomBar.y = FlxG.height + topBar.y;
		bottomBar.angle = topBar.angle;
		add(bottomBar);
		optionTweens.tween(bottomBar, {y: bottomBar.y + bottomBar.height}, 0.5, {ease: FlxEase.cubeOut, type: BACKWARD});

		txtTipe = new FlxStaticText(0, 0, 0);
		txtTipe.italic = true;
		txtTipe.setFormat(Paths.font('PhantomMuff Full Letters 1-1-5.ttf'), 17, 0xFFFFFFFF, RIGHT);
		add(txtTipe);
		updateTipeTxt();
		optionTweens.tween(txtTipe.offset, {y: txtTipe.offset.y - txtTipe.height * 2}, 0.4, {ease: FlxEase.cubeOut, type: BACKWARD});

		titleText = new FlxStaticText(12, 12, 0);
		titleText.setFormat(Paths.font('PhantomMuff Full Letters 1-1-5.ttf'), 26, FlxColor.WHITE, LEFT);

		var format = new FlxTextFormat();
		@:privateAccess
		format.format.size = titleText.size + 21;
		titleText.applyMarkup("GAME MENU\n<sus>OPTIONS<sus>", [new FlxTextFormatMarkerPair(format, "<sus>")]);
		add(titleText);

		@:privateAccess
		titleText.regenGraphic();
		titleText.filters = [
			new openfl.filters.GlowFilter(titleText.color.getLightened().to24Bit(), 0.5, 9, 9, 2, openfl.filters.BitmapFilterQuality.HIGH, false, true),
			// new openfl.filters.BlurFilter(100, 0, openfl.filters.BitmapFilterQuality.HIGH)
		];

		optionTweens.tween(titleText.offset, {y: titleText.offset.y + titleText.height * 2}, 0.4, {ease: FlxEase.cubeOut, type: BACKWARD});

		var format = new TextFormat(Paths.font('PhantomMuff Full Letters 1-1-5.ttf'), 20, 0xFFD7D7D7);
		format.letterSpacing = 10;
		descriptionText = new FlxTypeBitmapText(0, 0, "", flixel.graphics.frames.FlxBitmapFont.fromFont(format));
		descriptionText.delay = 0.015;
		descriptionText.autoSize = false;
		descriptionText.fieldWidth = 500;
		descriptionText.visible = false;
		descriptionText.typeCallback = () -> {
			descriptionText.setPosition(options.x + options.width + 20, 550 - (Math.max(descriptionText.numLines, 1) - 1) * descriptionText.font.lineHeight / 1.35);
		}
		add(descriptionText);

		restartText = new FlxStaticText(0, 0, 0, "Warning: Since you have changed settings affecting gameplay, the song will restart.");
		restartText.setFormat(Paths.font('PhantomMuff Full Letters 1-1-5.ttf'), 14, FlxColor.WHITE, LEFT);
		restartText.setPosition(10, FlxG.height - restartText.height - 10);
		restartText.alpha = 0;
		add(restartText);

		allowControl = false;
		new flixel.util.FlxTimer().start(0.35, _ -> allowControl = true);

		controllerMode = _isControllerModeInput = optionsControls.controllerMode;

		StructureOptionsData.onChangePost.add(onChangeOptions);

		createCategories();
		onChangeCategory(null, true);
		call("createPost");
	}

	var isClosing:Bool = false;
	public function goBack()
	{
		if (isClosing) return;
		isClosing = true;
		optionTweens.clear();
		optionTweens.tween(topBar, {y: topBar.y - topBar.height}, 0.3, {ease: FlxEase.cubeIn});
		optionTweens.tween(bottomBar, {y: bottomBar.y + bottomBar.height}, 0.3, {ease: FlxEase.cubeIn});
		if (descriptionText != null)
			optionTweens.tween(descriptionText, {
					"offset.x": descriptionText.offset.x + 500,
					alpha: 0
				}, 0.27, {ease: FlxEase.cubeIn, startDelay: 0.07});
		optionTweens.tween(txtTipe.offset, {y: txtTipe.offset.y - txtTipe.height * 2}, 0.23, {ease: FlxEase.cubeIn, startDelay: 0.03});
		optionTweens.tween(titleText.offset, {y: titleText.offset.y + titleText.height * 2}, 0.23, {ease: FlxEase.cubeIn, startDelay: 0.05});
		optionTweens.tween(options, {x: -options.width * 1.3}, 0.32, {ease: FlxEase.cubeIn});
		for (i => txtObj in _categoriesSprs)
		{
			optionTweens.tween(txtObj,
				{"offset.y": txtObj.offset.y + txtObj.height * 2, alpha: 0},
				0.25, {ease: FlxEase.cubeIn, startDelay: (_categoriesSprs.length - 1 - i) * 0.02});
		}
		optionTweens.tween(underlineCategory,
			{"offset.y": underlineCategory.offset.y + categoreSprTarget.height * 2, alpha: 0},
			0.25, {ease: FlxEase.cubeIn, startDelay: (_categoriesSprs.length - 1 - _categoriesSprs.indexOf(categoreSprTarget)) * 0.02});

		optionTweens.tween(restartText, {y: restartText.y + restartText.height * 2}, 0.3, {ease: FlxEase.cubeIn, startDelay: 0.03});

		FlxMouseEvent.globalManager.active = false;
		CursorManager.instance.cursor = null;

		toogleBGTransition(false, 0.3, FlxEase.cubeIn);

		new FlxTimer().start(0.33, _ -> {
			close();
		});
	}

	function onChangeOptions(optionData:SaveOption)
	{
		switch (optionData.variableName)
		{
			case "shaders" | "lowQuality" | "bgOptionsShader":
				toogleBGTransition(true, 0.2);
		}
	}

	@:noCompletion var _bgShaderFactor:Float = 0;
	@:noCompletion function _updateBGShaderFactor(i:Float)
	{
		_bgShaderFactor = i;
		bgShader.setFloat("iFactor", i);
	}

	var bgShader:FlxRuntimeShader;

	var _bgShaderTransitionTwn:FlxTween = null;
	var _bgColorTransitionTwn:FlxTween = null;
	function toogleBGTransition(enable:Bool, time:Float = 0.4, ?colorTwEase:flixel.tweens.FlxEase.EaseFunction)
	{
		if (!enableBGOverlay)
			enable = false;
		var targetShaderFactor:Float = enable ? 1.0 : 0.0;
		var myBGColor:FlxColor = FlxColor.BLACK;
		myBGColor.alphaFloat = 0.6;
		if (!enable)
			myBGColor = FlxColor.TRANSPARENT;

		final validShader:Bool = ClientPrefs.field("bgOptionsShader") && ClientPrefs.field("shaders") && !ClientPrefs.field("lowQuality");
		if (validShader)
		{
			if (_bgShaderFactor != targetShaderFactor)
			{
				_bgShaderTransitionTwn?.cancel();
				_bgShaderTransitionTwn = optionTweens.num(_bgShaderFactor, targetShaderFactor, time, {
					onStart: _ -> {
						camOptions.bgShader = bgShader;
					},
					onComplete: _ -> {
						_bgShaderTransitionTwn = null;
					}
				}, _updateBGShaderFactor);
			}
		}
		else
		{
			targetShaderFactor = 0;

			if (_bgShaderFactor != targetShaderFactor)
			{
				_bgShaderTransitionTwn?.cancel();
				_bgShaderTransitionTwn = optionTweens.num(_bgShaderFactor, targetShaderFactor, time, {
					onComplete: _ -> {
						camOptions.bgShader = null;
						_bgShaderTransitionTwn = null;
					}
				}, _updateBGShaderFactor);
			}
		}
		if (bgColor != myBGColor)
		{
			var func = FlxColor.interpolate.bind(bgColor, myBGColor, _);
			_bgColorTransitionTwn?.cancel();
			_bgColorTransitionTwn = optionTweens.num(0, 1, time, {
				ease: colorTwEase,
				onComplete: _ -> {
					_bgColorTransitionTwn = null;
				}
			}, i -> bgColor = func(i));
		}

		//camOptions.bgFilters = validShader ? [bgFilter] : null;
		// camOptions.bgFiltersTicksUpdate = validShader ? 100 : null;
	}

	var categoreSprTarget:FlxStaticText;
	var underlineTween:FlxTween;
	var oldTextTween:FlxTween;
	var newTextTween:FlxTween;
	var underlineCategory:FlxSprite;

	function createCategories()
	{
		final centerX = FlxG.width / 1.85;
		final factor = Math.max(800 / categories.length, 200);
		final len = categories.length - 1;
		underlineCategory = new FlxSprite().makeGraphic(1, 7, 0xFFFFFFFF);
		underlineCategory.origin.x = 0;
		for (i in _categoriesSprs) FlxMouseEvent.remove(i);
		_categoriesSprs.clearArray();
		for (i in 0...categories.length)
		{
			var txtObj = new FlxStaticText(centerX + (i - len / 2) * factor, 100, 0, categories[i]);
			txtObj.setFormat(Paths.font('PhantomMuff Full Letters 1-1-5.ttf'), 24, 0xFFFFFFFF);
			txtObj.cameras = [camOptions];
			txtObj.x += txtObj.width / 2;
			txtObj.color = 0xFF999999;
			add(txtObj);
			FlxMouseEvent.add(txtObj, updateCategoryText, null, _ -> CursorManager.instance.cursor = 'button', _ -> CursorManager.instance.cursor = null,
				false, true, false);
			_categoriesSprs.push(txtObj);

			final offsetY = txtObj.height * 2;
			txtObj.offset.y += offsetY;
			txtObj.alpha = 0;
			optionTweens.tween(txtObj, {
				"offset.y": txtObj.offset.y - offsetY,
				alpha: 1
			}, 0.35, {
				ease: FlxEase.cubeOut,
				startDelay: i * 0.03
			});
		}

		categoreSprTarget ??= _categoriesSprs[categories.indexOf(curCategory)];

		categoreSprTarget.color = 0xFFFFFFFF;
		underlineCategory.x = categoreSprTarget.x - 5;
		underlineCategory.y = categoreSprTarget.y + categoreSprTarget.height;
		underlineCategory.scale.x = categoreSprTarget.width + 10;
		add(underlineCategory);
		final offsetY = categoreSprTarget.height * 2;
		underlineCategory.offset.y += offsetY;
		underlineCategory.alpha = 0;
		optionTweens.tween(underlineCategory,
			{"offset.y": underlineCategory.offset.y - offsetY, alpha: 1},
			0.35, {ease: FlxEase.cubeOut, startDelay: _categoriesSprs.indexOf(categoreSprTarget) * 0.03});
	}

	function updateCategoryText(spr:FlxStaticText)
	{
		spr ??= _categoriesSprs[0];

		if (categoreSprTarget == spr)
			return;
		var oldText = categoreSprTarget;
		categoreSprTarget = spr;
		onChangeCategory(spr.text);
		oldTextTween?.cancel();
		oldTextTween = FlxTween.color(oldText, 0.3, oldText.color, 0xFF999999, {ease: FlxEase.cubeOut});

		newTextTween?.cancel();
		newTextTween = FlxTween.color(categoreSprTarget, 0.3, categoreSprTarget.color, 0xFFFFFFFF, {ease: FlxEase.cubeOut});

		selectKey = false;
		updateUnderlineTween();
		if (categChSound != null)
			FlxG.sound.play(categChSound);
	}

	function updateUnderlineTween()
	{
		underlineTween?.cancel();
		underlineTween = FlxTween.tween(underlineCategory, {x: categoreSprTarget.x - 5, "scale.x": categoreSprTarget.width
			+ 10}, 0.3, {ease: FlxEase.cubeOut});
	}

	function onChangeCategory(?text:String, ignore:Bool = false)
	{
		if (!ignore && categories.length < 2)
			return;
		text ??= curCategory;
		var nextIndex = FlxMath.wrap(categories.indexOf(text), 0, categories.length - 1);
		curCategory = categories[nextIndex];

		reloadCategory();
	}

	var widthOffset:Int = 20;
	var heightBar:Int = 58;

	function reloadCategory()
	{
		if (!StructureOptionsData.data.exists(curCategory))
		{
			Log('Category "$curCategory" is missing', RED);
			return;
		}
		_generateCategories = true;
		options.clear();
		curOption = null;
		while (_members.length > 0)
			_members.pop()?.destroy();
		CoolUtil.clearArray(_categories);
		var i:Int = 0;
		var offWidth:Int = 0;
		var lastParent:OptionSprite = null;
		function createBlock(optionData:SaveOption)
		{
			var box = new OptionSprite(optionData, lastParent, options, {
				widthOffset: widthOffset,
				height: heightBar,
				indexOffset: offWidth
			}, !inGame || optionData.changeInGameplay == true, offWidth * widthOffset);
			box.origID = box.ID = i++;
			_members.push(box);
		}
		function loadThings(datas:Array<SaveOption>)
		{
			for (optionData in datas)
			{
				if (optionData.checkVisible != null && !optionData.checkVisible())
					continue;

				createBlock(optionData);

				if (optionData.things == null)
					continue;
				offWidth++;
				lastParent = _members.getLastOfArray();
				_categories.push(lastParent);
				loadThings(optionData.things);
				offWidth--;
				lastParent = null;
			}
		}
		var data:Array<SaveOption> = StructureOptionsData.data.get(curCategory);
		var runtimeData:Null<Array<SaveOption>> = StructureOptionsData.runtimeData?.get(curCategory);
		if (runtimeData != null && runtimeData.length > 0)
		{
			data = data.copy();
			for (i in runtimeData)
			{
				if (i.beforeOption != null || i.afterOption != null)
				{
					var index = -1;
					var targetOption = i.beforeOption ?? i.afterOption;
					for (j => opt in data)
					{
						if (opt.variableName == targetOption)
						{
							index = j;
							if (i.afterOption != null)
								index++;
							break;
						}
					}
					if (index != -1)
					{
						data.insert(index, i);
					}
				}
				else
				{
					data.push(i);
				}
			}
		}
		loadThings(data);
		options.updateHeightScroll();
		updatePositions();
		_generateCategories = false;
	}

	public var controllerMode(default, set):Bool = false;
	function set_controllerMode(a:Bool)
	{
		if (controllerMode != a)
		{
			controllerMode = a;
			FlxG.sound.play(Paths.sound("optionsStuff/" + (controllerMode ? "bindPadChange" : "keyBoardChange"))
				).pitch = FlxMath.roundDecimal(FlxG.random.float(0.8, 1.2), 2);
			updateTipeTxt();
		}
		return a;
	}

	function updateTipeTxt() {
		var finalTxt = (controllerMode ? "Start": "R") + " - Reset to Default Settings";
		if (FlxG.gamepads.lastActive != null)
			finalTxt = "CTRL - Change to toggle gamepad / keyboard setting\n" + finalTxt;
		txtTipe.text = finalTxt;
		txtTipe.offset.x = -10;
		optionTweens.tween(txtTipe.offset, {x: 0}, 0.13, {ease: FlxEase.cubeOut, startDelay: 0.02});
		txtTipe.setPosition(FlxG.width - txtTipe.width - 11.65, FlxG.height - txtTipe.height - 11.91);
	}
	// CHILDS
	public function updatePositions()
	{
		var members = [for (i in _members) if (i != null && i.parent == null) i];
		for (spr in _categories)
		{
			switch (spr.data.typeVar)
			{
				case NONE:
					if (spr.categArrow?.isLocked)
						continue;
				case BOOL:
					if (spr.data.variable != true)
						continue;
				case CATEGORY:
					if (Std.string(spr.data.variable).toLowerCase() == 'none')
						continue;
				default:
			}
			var curCateg = spr.getCurCategData();
			if (curCateg != null && !curCateg.visibleChilds)
				continue;
			for (i in spr.childs)
				members.push(i);
		}
		members.sort((obj1, obj2) -> FlxSort.byValues(-1, obj1.origID, obj2.origID));
		options.clear(false, false);
		for (i => spr in members)
		{
			spr.y = i * (heightBar + 23.5);
			options.add(spr);
		}
		options.updateHeightScroll();
	}

	public function updateChildFromString(name:String)
	{
		for (spr in _members)
		{
			if (spr.data.variableName == name)
			{
				updateChilds(spr, spr.childs);
				break;
			}
		}
	}

	public function updateChilds(?spr:OptionSprite, ?arraySpr:Array<OptionSprite>)
	{
		if (arraySpr != null && arraySpr.length > 0)
		{
			for (spr in arraySpr)
			{
				updateChild(spr, true);
			}
		}
		else if (spr != null)
		{
			updateChild(spr, true);
		}
	}

	function updateChild(spr:OptionSprite, checkCHILDERS:Bool = false)
	{
		spr.data.variable = ClientPrefs.field(spr.data.variableName);
		switch (spr.data.typeVar)
		{
			case NONE:
			case STR | CATEGORY | DYNAMIC:
				var curData:CategoryFunction = spr.getCurCategData();
				if (curData != null)
					curData.thing();
				spr.setVarText(curData?.display);
			case INPUT:
				curOption.updateControlText();
			// case STR | CATEGORY | BOOL | NONE:
			case FLOAT | PERCENT | INT:
				spr.slider.updateSlider((spr.data.variable - spr.slider.min) / spr.slider.widthShit);
				spr.setVarText();
			default:
				spr.setVarText();
		}
		spr.data.onChange();
		if (checkCHILDERS)
			updateChilds(spr.childs);
	}


	static final BINDS_SWITCH:Array<FlxGamepadInputID> = [FlxGamepadInputID.LEFT_SHOULDER, FlxGamepadInputID.RIGHT_SHOULDER];

	public override function update(elapsed:Float)
	{
		curLightShader?.updateAnim();
		if (!isClosing)
		{
			if (FlxG.mouse.visible && FlxG.mouse.justMoved)
				mouseMode = true;
			FlxG.sound.keysAllowed = !selectKey;
			if (selectKey)
			{
				if (curOption != null && curOption.controlText != null)
					if(curOption.controlText.displayGamepad ?
						(FlxG.gamepads.lastActive.firstJustPressedID() ?? FlxGamepadInputID.NONE) != FlxGamepadInputID.NONE
						: FlxG.keys.firstJustPressed() != FlxKey.NONE)
					{
						if (curOption.data.typeVar == INPUT)
						{
							final result = curOption.controlText.applySetting(curOption.controlText.displayGamepad ?
								(FlxG.gamepads.lastActive.firstJustPressedID() ?? FlxGamepadInputID.NONE)
								:
								FlxG.keys.firstJustPressed()
							);
							if (result)
							{
								FlxG.sound.play(
										Paths.sound("optionsStuff/" + (curOption.controlText.displayGamepad ? "bindPadChange" : "keyBoardChange"))
									).pitch = FlxMath.roundDecimal(FlxG.random.float(0.8, 1.2), 2);
								selectKey = false;
							}
							else
							{
								FlxG.sound.play(Paths.sound("missnote" + FlxG.random.int(1, 3)),
									FlxG.random.float(0.9, 1.05) * ClientPrefs.missVolume).pitch = FlxMath.roundDecimal(FlxG.random.float(0.9, 1.1), 2);
							}
							curOption.data.onChange();
						}
						else
						{
							selectKey = false;
							FlxG.sound.play(Paths.sound("missnote" + FlxG.random.int(1, 3)),
								FlxG.random.float(0.9, 1.05) * ClientPrefs.missVolume).pitch = FlxMath.roundDecimal(FlxG.random.float(0.9, 1.1), 2);
						}
					}
					else if (FlxG.mouse.justPressed)
					{
						curOption.controlText.selectedText = null;
						selectKey = false;
					}
				if (optionsControls.controllerMode != _isControllerModeInput)
				{
					selectKey = false;
					controllerMode = _isControllerModeInput = optionsControls.controllerMode;
					for (i => spr in _members)
					{
						spr.updateControlText(controllerMode);
					}
				}
			}
			else if (allowControl)
			{
				if (optionsControls.ACCEPT)
					onAccept(false);
				else if (optionsControls.ACCEPT_R)
					onAccept(true);

				if (optionsControls.UI_UP_P)
					onChangeOption(false);
				else if (optionsControls.UI_DOWN_P)
					onChangeOption(true);

				if (optionsControls.UI_LEFT)
					onPressDir(true, true);
				else if (optionsControls.UI_RIGHT)
					onPressDir(false, true);

				if (optionsControls.UI_LEFT_P)
					onPressDir(true, true, true);
				else if (optionsControls.UI_RIGHT_P)
					onPressDir(false, true, true);

				if (optionsControls.UI_LEFT_R)
					onPressDir(true, false);
				else if (optionsControls.UI_RIGHT_R)
					onPressDir(false, false);

				if (controllerMode)
				{
					if (FlxG.gamepads.lastActive.anyJustPressed(BINDS_SWITCH))
						updateCategoryText(_categoriesSprs[FlxMath.wrap(categories.indexOf(categoreSprTarget.text)
							+ (FlxG.gamepads.lastActive.pressed.LEFT_SHOULDER ? -1 : 1),
							0, _categoriesSprs.length - 1)]);
				}
				else
				{
					if (FlxG.keys.justPressed.TAB)
						updateCategoryText(_categoriesSprs[FlxMath.wrap(categories.indexOf(categoreSprTarget.text)
							+ (FlxG.keys.pressed.SHIFT ? -1 : 1),
							0, _categoriesSprs.length - 1)]);
					else if (FlxG.keys.justPressed.Q || FlxG.keys.justPressed.E)
						updateCategoryText(_categoriesSprs[FlxMath.wrap(categories.indexOf(categoreSprTarget.text)
							+ (FlxG.keys.justPressed.Q ? -1 : 1),
							0, _categoriesSprs.length - 1)]);
				}

				if (controllerMode ? FlxG.gamepads.anyJustPressed(START) : FlxG.keys.justPressed.R) // RESET
				{
					// for(curOption in _members)
					if (curOption != null && curOption.data.typeVar != NONE)
					{
						if (curOption.data.typeVar == INPUT)
						{
							if (curOption.controlText.isValid)
							{
								if (curOption.controlText.displayGamepad)
								{
									ClientPrefs.gamepadBinds.set(curOption.data.variableName, ClientPrefsDefault.gamepadBinds.get(curOption.data.variableName).copy());
								}
								else
								{
									ClientPrefs.keyBinds.set(curOption.data.variableName, ClientPrefsDefault.keyBinds.get(curOption.data.variableName).copy());
								}
								if (resetSound != null)
								{
									FlxG.sound.play(resetSound);
								}
							}
						}
						else
						{
							ClientPrefs.setProperty(curOption.data.variableName, curOption.data.defaultValue);
							if (resetSound != null)
							{
								FlxG.sound.play(resetSound);
							}
						}
						curOption.data.onChange();
						updateChild(curOption);
					}
				}
				if (optionsControls.BACK)
					goBack();
				if (curOption?.data.typeVar == INPUT && FlxG.mouse.justPressed)
					curOption.controlText.selectedText = null;

				if (optionsControls.controllerMode != _isControllerModeInput)
				{
					controllerMode = _isControllerModeInput = optionsControls.controllerMode;
					for (i => spr in _members)
					{
						spr.updateControlText(controllerMode);
					}
				}
				if (FlxG.keys.justPressed.CONTROL)
				{
					controllerMode = !controllerMode && FlxG.gamepads.lastActive != null;
					for (i => spr in _members)
					{
						spr.updateControlText(controllerMode);
					}
				}
			}
		}
		super.update(elapsed);
	}

	function onChangeOption(down:Bool)
	{
		mouseMode = false;
		if (curOption == null)
		{
			curOptionIndex = down ? _members.length - 1 : 0;
			curOption = _members[curOptionIndex];
			if (curOption.arrowLeft != null && curOption.arrowRight != null)
			{
				curOption.arrowLeft.onPress(false);
				curOption.arrowRight.onOut(false);
			}
		}
		options.canDrag = true;
		final addedIndex = (down ? 1 : -1);
		curOptionIndex = FlxMath.wrap(curOptionIndex + addedIndex * (FlxG.keys.pressed.SHIFT ? 2 : 1), 0, _members.length - 1);

		inline function checkValid():Bool
		{
			return options._members.members.contains(_members[curOptionIndex] ?? _members[curOptionIndex = 0]);
		}
		while (!checkValid())
		{
			curOptionIndex = FlxMath.wrap(curOptionIndex + addedIndex, 0, _members.length - 1);
		}

		curOption = _members[curOptionIndex];
		options.scrollFloat = curOption.y + curOption.height / 2 - options.height / 2;
		if (CursorManager.instance.cursor == 'button')
			CursorManager.instance.cursor = null;
	}

	function onPressDir(left:Bool, pressed:Bool, just:Bool = false)
	{
		mouseMode = false;
		curOption ??= _members[0];
		options.canDrag = true;
		if (pressed)
		{
			switch (curOption.data.typeVar)
			{
				case NONE if (just):
					curOption.categArrow.onPress();
				case STR | CATEGORY | BOOL | DYNAMIC if (just):
					if (left)
					{
						curOption.arrowLeft.onPress();
						curOption.arrowRight.onOut(false);
					}
					else
					{
						curOption.arrowRight.onPress();
						curOption.arrowLeft.onOut(false);
					}
				case FLOAT | PERCENT | INT:
					curOption.slider.updateSlider(CoolUtil.boundTo(curOption.slider.factor
						+ (FlxG.elapsed * (FlxG.keys.pressed.SHIFT ? 10 : 1) / (curOption.data.typeVar == INT ? 10 * curOption.slider.decimals : Math.pow(10,
							curOption.slider.decimals))) * curOption.data.scrollSpeed * (left ? -2 : 2),
						0, 1));
					curOption.slider.onPressed();
				case INPUT if (just):
					final main = curOption.controlText;
					var index:Int = 0;
					if (main.selectedText != null)
					{
						main.onOut(main.selectedText);
						index = main.members.indexOf(main.selectedText);
					}
					var addIndex = left ? -1 : 1;
					var nextMember:InputText = main.selectedText == null ?
						main.members[left ? main.length - 1 : 0]
					:
						main.members[index = FlxMath.wrap(index + addIndex, 0, main.length - 1)];
					if (main.length > 1)
						while(nextMember == null || nextMember.key == null)
							nextMember = main.members[index = FlxMath.wrap(index + addIndex, 0, main.length - 1)];
					main.selectedText = nextMember.key == null ? null : nextMember;
					nextMember.status = BBSTATIC;
				default:
			}
		}
		else
		{
			switch (curOption.data.typeVar)
			{
				case STR | CATEGORY | BOOL | DYNAMIC:
					if (left)
					{
						curOption.arrowLeft.onRelease();
						curOption.arrowRight.onOut(false);
					}
					else
					{
						curOption.arrowRight.onRelease();
						curOption.arrowLeft.onOut(false);
					}
				case FLOAT | PERCENT | INT:
					curOption.slider.onRelease();
				case NONE:
					curOption.categArrow.onRelease();
				default:
			}
		}
	}

	function onAccept(release:Bool)
	{
		mouseMode = false;
		curOption ??= _members[0];
		if (release)
		{
			switch (curOption.data.typeVar)
			{
				case STR | CATEGORY | BOOL | DYNAMIC:
					if (curOption.arrowLeft.status != BBSTATIC)
						curOption.arrowLeft.onRelease();
					if (curOption.arrowRight.status != BBSTATIC)
						curOption.arrowRight.onRelease();
				case NONE:
					curOption.categArrow.onRelease();
				default:
			}
		}
		else
		{
			switch (curOption.data.typeVar)
			{
				case STR | CATEGORY | BOOL | DYNAMIC:
					if (curOption.arrowLeft.status != BBSTATIC)
						curOption.arrowLeft.onPress();
					if (curOption.arrowRight.status != BBSTATIC)
						curOption.arrowRight.onPress();
				case INPUT if (curOption.controlText?.selectedText != null):
					curOption.controlText.onRelease(true, curOption.controlText.selectedText);
				case NONE:
					curOption.categArrow.onPress();
				default:
			}
		}
	}
	public override function destroy()
	{
		if (inGame)
		{
			checkRestartVariables();
			if (neededToRestart)
			{
				PauseSubState.restartSong();
				_parentState.persistentUpdate = false;
				var pauseSubState:PauseSubState = cast _parentState;
				if (pauseSubState != null)
				{
					@:privateAccess
					pauseSubState.itIsAccepted = true;
				}
			}
		}
		curLightShader = null;
		curOption = null;
		curOptionIndex = 0;
		lastDir = [false, false];
		options.destroy();

		optionTweens.clear();

		StructureOptionsData.onChangePost.remove(onChangeOptions);

		// titleText.clipRect = FlxDestroyUtil.put(titleText.clipRect);
		for (i in _categoriesSprs) FlxMouseEvent.remove(i);

		if (underlineTween != null)
		{
			underlineTween.cancel();
			underlineTween = null;
		}
		if (oldTextTween != null)
		{
			oldTextTween.cancel();
			oldTextTween = null;
		}
		if (newTextTween != null)
		{
			newTextTween.cancel();
			newTextTween = null;
		}

		FlxG.cameras.remove(camOptions, false);
		camOptions.destroy();
		camOptions = null;
		instance = null;

		if (optChFlxSound != null)
		{
			@:privateAccess
			FlxG.sound.destroySound(optChFlxSound);
			optChFlxSound = null;
		}

		super.destroy();
		FlxMouseEvent.globalManager.active = true;
		CursorManager.instance.cursor = null;
		ClientPrefs.saveSettings();
		MemoryUtil.clearMajor();
		MemoryUtil.clearMinor();
	}
}
