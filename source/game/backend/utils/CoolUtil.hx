package game.backend.utils;

#if HAXE_UI
import haxe.ui.Toolkit;
#end
import flixel.math.FlxMath;
import flixel.sound.FlxSound;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.graphics.frames.FlxFrame.FlxFrameAngle;
import flixel.graphics.frames.FlxFramesCollection;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.input.gamepad.FlxGamepad;
import flixel.input.gamepad.FlxGamepadInputID;
import flixel.input.gamepad.FlxGamepadManager;
import flixel.input.keyboard.FlxKey;
import flixel.tweens.FlxEase;
import flixel.util.typeLimit.OneOfFour;
import flixel.util.FlxArrayUtil;
import flixel.util.FlxColor;
import flixel.util.FlxDestroyUtil;
import flixel.util.FlxStringUtil;
import flixel.util.FlxSignal;
import flixel.util.FlxPool;
import flixel.FlxCamera;

import openfl.display.BitmapData;
import openfl.display.Shader;
import openfl.display.PNGEncoderOptions;
import openfl.display.OpenGLRenderer;
import openfl.display3D.Context3D;
import openfl.events.FocusEvent;
import openfl.events.KeyboardEvent;
import openfl.events.MouseEvent;
import openfl.filters.BitmapFilter;
import openfl.filters.ShaderFilter;
import openfl.geom.Matrix;
import openfl.geom.Rectangle;
import openfl.utils._internal.UInt8Array;

import lime.app.Future;
import lime.app.Promise;
import lime.graphics.*;

import haxe.Json;
import haxe.MainLoop;
import haxe.PosInfos;
import haxe.io.Path;

import game.backend.utils.MemoryUtil;
import game.backend.utils.ThreadUtil;
#if cpp
import game.backend.utils.native.HiddenProcess;
#end

#if sys
import sys.io.File;
import sys.FileSystem;
// import sys.thread.Thread;
#end

typedef DynamicColor = OneOfFour<FlxColor, Float, String, Array<Dynamic>>;

class DestroyableFlxMatrix extends flixel.math.FlxMatrix implements IFlxDestroyable {
	public function destroy() {
		identity();
	}
}

@:allow(game.backend.utils.ClientPrefs)
class CoolUtil
{
	public static inline function scale(x:Float, l1:Float, h1:Float, l2:Float, h2:Float):Float
		return ((x - l1) * (h2 - l2) / (h1 - l1) + l2);

	public static inline function clamp(n:Float, l:Float, h:Float)
	{
		if (n > h)
			n = h;
		if (n < l)
			n = l;
		return n;
	}
	public static function rotate(x:Float, y:Float, angle:Float, ?point:FlxPoint):FlxPoint
	{
		point ??= FlxPoint.weak();
		var _sin = Math.sin(angle);
		var _cos = Math.cos(angle);
		point.set(x * _cos - y * _sin, x * _sin + y * _cos);
		return point;
	}

	//Combines multiple eases into a singular ease function. from FPSPlus
	public static function easeCombine(eases:Array<EaseFunction>):Null<EaseFunction>{
		if (eases.length < 1) return null;
		return (v:Float) -> {
			if (v * eases.length >= eases.length){
				return v;
			}
			var index:Int = Math.floor(v * eases.length);
			return (index / eases.length) + (eases[index]((v - (index / eases.length)) * eases.length) / eases.length);
		}
	}

	public static inline function quantizeAlpha(f:Float, interval:Float){
		return Std.int((f + interval / 2) / interval) * interval;
	}


	public static var matrixesPool:FlxPool<DestroyableFlxMatrix> = new FlxPool(DestroyableFlxMatrix);

	public static function floorDecimal(value:Float, decimals:Int):Float
	{
		if (decimals < 1)
			return Math.ffloor(value);

		// var tempMult:Float = 1;
		// for (i in 0...decimals) tempMult *= 10;

		decimals = Std.int(Math.pow(10, decimals));
		return Math.ffloor(value * decimals) / decimals;
	}

	public static function roundDecimal(value:Float, decimals:Int):Float
	{
		if (decimals < 1)
			return Math.fround(value);

		decimals = Std.int(Math.pow(10, decimals));
		return Math.fround(value * decimals) / decimals;
	}

	public static inline function quantize(f:Float, snap:Float):Float
		return Math.fround(f * snap) / snap;

	public static function getErrorInfo(e:haxe.Exception, prefix:String = '', ?filePos:PosInfos):String
	{
		final text = prefix + e.message + '\n' + e.details();
		Log(text, RED);
		return text;
	}

	@:access(openfl.text.TextField)
	public static function removeEventListeners(textField:openfl.text.TextField)
	{
		textField.removeEventListener(FocusEvent.FOCUS_IN, textField.this_onFocusIn);
		textField.removeEventListener(FocusEvent.FOCUS_OUT, textField.this_onFocusOut);
		textField.removeEventListener(KeyboardEvent.KEY_DOWN, textField.this_onKeyDown);
		textField.removeEventListener(MouseEvent.MOUSE_DOWN, textField.this_onMouseDown);
		textField.removeEventListener(MouseEvent.MOUSE_WHEEL, textField.this_onMouseWheel);

		textField.removeEventListener(MouseEvent.DOUBLE_CLICK, textField.this_onDoubleClick);
	}

	public static function toDynamic(obj:Map<String, Dynamic>):Dynamic
	{
		var nd:Dynamic = {};
		for (k => v in obj)
			Reflect.setField(nd, k, v);
		return nd;
	}

	@:noUsing public static function filterFileListByPath(iterList:Iterable<String>, targetFolder:String, ?getFolders:Null<Bool>):Array<String> {
		if (!targetFolder.endsWith("/"))
			targetFolder = targetFolder + "/";

		var arrList = targetFolder.length == 1 ? [
			for (i in iterList) i
		] : [
			for (i in iterList)
				if (i.startsWith(targetFolder)
				&& (getFolders != null && (i.indexOf("/", targetFolder.length) != -1) == getFolders
				|| getFolders == null))
					i.substr(targetFolder.length)
		];

		if (getFolders != false && arrList.length > 0) {
			var i:Int = arrList.length;
			var i2:Int;
			while (i > 0) {
				i--;
				i2 = arrList[i].indexOf("/");
				if(i2 != -1)
					arrList[i] = arrList[i].substr(0, i2);
			}

			// remove duplicates
			i = arrList.length;
			while (i > 0) {
				i--;
				while (i != arrList.indexOf(arrList[i])) {
					arrList.splice(i, 1);
					i--;
				}
			}
		}
		return arrList;
	}

	/**
	 * Tries to get a color from a `Dynamic` variable.
	 * @param c `Dynamic` color.
	 * @return The result color, or `null` if invalid.
	 */
	public static function getColorFromDynamic(c:Dynamic):Null<FlxColor>
	{
		/*
		// -1
		if (c is Int)
			return c;
		*/

		// -1.0
		if (c is Float)
			return Std.int(c);

		// "#FFFFFF"
		if (c is String)
			return FlxColor.fromString(c);

		// [255, 255, 255]
		if (c is Array)
		{
			var r:Int = 0;
			var g:Int = 0;
			var b:Int = 0;
			var a:Int = 255;
			var array:Array<Float> = cast c;
			if (array != null)
				for (k => e in array)
				{
					switch k
					{
						case 0:
							r = Std.int(e);
						case 1:
							g = Std.int(e);
						case 2:
							b = Std.int(e);
						case 3:
							a = Std.int(e);
					}
				}
			return FlxColor.fromRGB(r, g, b, a);
		}
		return null;
	}

	@:access(flixel.sound.FlxSound)
	@:access(openfl.media.Sound)
	public static function isValid(sound:FlxSound):Bool
		return sound?._transform != null && sound._sound?.__buffer != null;

	public static inline function capitalize(text:String):String
	{
		text = text.trim();
		return text.charAt(0).toUpperCase() + text.substr(1).toLowerCase();
	}

	public static inline function equalArray(arr1:Array<Dynamic>, arr2:Array<Dynamic>):Bool
	{
		return FlxArrayUtil.equals(arr1, arr2);
	}

	public static function filterTypedef(list:Any, ass:Map<String, Dynamic>)
	{
		for (varName => boolshit in ass)
		{
			var varMain = varName.trim();

			if (!Reflect.hasField(list, varMain))
				continue;
			var variable:Dynamic = Reflect.field(list, varMain) ?? Reflect.getProperty(list, varMain);

			// trace(variable);
			if ((Std.isOfType(variable, Array) && Std.isOfType(boolshit, Array) ? equalArray(variable, boolshit) : variable == boolshit))
			{
				// try Reflect.setField(list, varMain, null);
				Reflect.deleteField(list, varMain);
				trace('Deleted $varMain');
				// break;
			}
		}
		// trace(list);
		return list;
	}

	static final hideChars = ~/[\t\n\r]/;

	public static function colorFromString(color:String):FlxColor
	{
		var color:String = hideChars.split(color).join('').trim();
		if (color.startsWith('0x'))
			color = color.substring(color.length - 6);
		return FlxColor.fromString(color) ?? FlxColor.fromString('#$color') ?? FlxColor.WHITE;
	}

	// public static inline function boundTo(value:Float, min:Float, max:Float):Float return Math.max(min, Math.min(max, value));
	public static inline function boundTo(value:Float, ?min:Float, ?max:Float):Float
		return FlxMath.bound(value, min, max);

	public static function shadersToFilters(target:Array<Shader>):Array<BitmapFilter>
	{
		return [for (i in target) new ShaderFilter(i)];
	}

	public static inline function colorFromFlxSprite(sprite:FlxSprite, ?quality:Null<Float>):FlxColor
		return FlxColor.fromInt(dominantColor(sprite, quality));

	public static function coolTextFile(path:String, trim = true):Array<String>
	{
		return Assets.exists(path) ? listFromString(Assets.getText(path), trim) : [];
	}

	public static function listFromString(string:String, trim = true):Array<String>
	{
		final list = unixNewLine(string).split('\n');
		return trim ? trimArray(list) : list;
	}

	public static inline function trimArray(array:Array<String>):Array<String>
	{
		return array.map(StringTools.trim);
	}

	static final IDK:Int = -13520687;

	@:access(openfl.display.BitmapData)
	@:access(openfl.display.OpenGLRenderer)
	@:access(openfl.display.Stage)
	@:access(openfl.display3D.Context3D)
	@:access(openfl.display3D._internal.Context3DState)
	@:access(openfl.display3D.textures.TextureBase)
	public static function dominantColor(sprite:FlxSprite, ?quality:Null<Float>):Int
	{
		final bitmap = sprite.pixels;
		if (bitmap == null) return -1;
		// trace("duh");
		quality ??= 1.0;
		if (quality > 1) quality = 1; // nuh huh
		var image:Image = bitmap.image;
		// if (!bitmap.readable || image == null || image.data == null)
		// 	return -1;
		// trace("duh");
		// trace(!bitmap.readable, image == null, image.data == null);
		#if sys
		if (!bitmap.readable || image == null || image.data == null) // well
		{
			// var renderer:OpenGLRenderer = cast FlxG.stage.__renderer;
			// var context:Context3D = renderer.__context3D;
			var context:Context3D = FlxG.stage.context3D;
			// trace("duh");
			if (context == null) return -1;
			// trace("duh");
			var texture = bitmap.getTexture(context);
			if (texture != null)
			{
				// trace("duh");
				var gl = context.gl;

				var backBufferWidth = bitmap.width;
				var backBufferHeight = bitmap.height;

				// var cacheRTT = context.__state.renderToTexture;
				// var cacheRTTDepthStencil = context.__state.renderToTextureDepthStencil;
				// var cacheRTTAntiAlias = context.__state.renderToTextureAntiAlias;
				// var cacheRTTSurfaceSelector = context.__state.renderToTextureSurfaceSelector;

				var cacheGLT = context.__contextState.__currentGLTexture2D;
				context.__bindGLTexture2D(texture.__getTexture());

				var data = new UInt8Array(backBufferWidth * backBufferHeight * 4);
				gl.readPixels(0, 0, backBufferWidth, backBufferHeight, texture.__format,
				gl.UNSIGNED_BYTE, data);

				var buffer = new ImageBuffer(data, backBufferWidth, backBufferHeight);
				buffer.format = BGRA32;
				buffer.premultiplied = true;

				image = new Image(buffer, 0, 0, backBufferWidth, backBufferHeight);
				image.transparent = bitmap.transparent;

				context.__bindGLTexture2D(cacheGLT);
				// if (cacheRTT != null)
				// {
				// 	context.setRenderToTexture(cacheRTT, cacheRTTDepthStencil, cacheRTTAntiAlias, cacheRTTSurfaceSelector);
				// }
				// else
				// {
				// 	context.setRenderToBackBuffer();
				// }
				trace("duh");
			}
			else
			{
				return -1;
			}
		}
		#end
		if (image == null || image.data == null)
			return -1;

		var countByColor:Map<Int, Int> = new Map<Int, Int>();
		if (!FlxMath.equal(quality, 1.0))
		{
			var frameWidth:Int = Std.int(image.width * quality);
			var frameHeight:Int = Std.int(image.height * quality);
			for (col in 0...frameWidth)
				for (row in 0...frameHeight)
				{
					var colorOfThisPixel:Int = image.getPixel32(Std.int(col / quality), Std.int(row / quality), ARGB32);
					if (colorOfThisPixel == 0)
						continue;
					if (countByColor.exists(colorOfThisPixel))
						countByColor[colorOfThisPixel]++;
					else if (countByColor[colorOfThisPixel] != IDK)
						countByColor[colorOfThisPixel] = 1;
				}
		}
		else
		{
			for (col in 0...image.width)
				for (row in 0...image.height)
				{
					var colorOfThisPixel:Int = image.getPixel32(col, row, ARGB32);
					if (colorOfThisPixel == 0)
						continue;
					if (countByColor.exists(colorOfThisPixel))
						countByColor[colorOfThisPixel]++;
					else if(countByColor[colorOfThisPixel] != IDK)
						countByColor[colorOfThisPixel] = 1;
				}
		}
		var maxCount = 0;
		var maxKey:Int = -1; // after the loop this will store the max color
		countByColor[FlxColor.BLACK] = 0;
		for (key => count in countByColor)
		{
			if (count > maxCount)
			{
				maxCount = count;
				maxKey = key;
			}
		}

		countByColor.clear();
		return maxKey;
	}

	@:noUsing public static inline function numberArray(max:Int, ?min = 0):Array<Int>
		return [for (i in min...max) i];

	@:noUsing public static inline function precacheSound(sound:String, ?library:String)
		FlxG.sound.cache(AssetsPaths.sound(sound, library));

	@:noUsing public static inline function precacheMusic(sound:String, ?library:String)
		FlxG.sound.cache(AssetsPaths.music(sound, library));

	@:noUsing public static function fpsLerp(from:Float, to:Float, ratio:Float, ?elapsed:Float):Float
	{
		if (FlxMath.equal(from, to)) return to; // avoid EPSILON by rich
		return FlxMath.lerp(to, from, Math.pow(1.0 - ratio, (elapsed ?? FlxG.elapsed) * 60.0));
		// return FlxMath.lerp(to, from, Math.exp(-(elapsed ?? FlxG.elapsed) * 60.0 * ratio));
		/*
		if (from == to) return to;
		return FlxMath.lerp(to, from, Math.pow(1.0 - ratio, FlxG.elapsed * 60));
		*/
		// return FlxMath.lerp(to, from, Math.exp(-ratio * 60 * FlxG.elapsed)); // Math.min(ratio * 60 * FlxG.elapsed, 1)
	}

	public static function bindToString(key:Null<FlxGamepadInputID>):String
	{
		final model:FlxGamepadModel = FlxG.gamepads.firstActive?.detectedModel ?? UNKNOWN;

		return switch(key)
		{
			case null | NONE:				"---";

			// Analogs
			case LEFT_STICK_DIGITAL_LEFT:	"Left";
			case LEFT_STICK_DIGITAL_RIGHT:	"Right";
			case LEFT_STICK_DIGITAL_UP:		"Up";
			case LEFT_STICK_DIGITAL_DOWN:	"Down";
			case LEFT_STICK_CLICK:
				switch (model) {
					case PS4: "L3";
					case XINPUT: "LS";
					default: "Analog Click";
				}

			case RIGHT_STICK_DIGITAL_LEFT:	"C. Left";
			case RIGHT_STICK_DIGITAL_RIGHT:	"C. Right";
			case RIGHT_STICK_DIGITAL_UP:	"C. Up";
			case RIGHT_STICK_DIGITAL_DOWN:	"C. Down";
			case RIGHT_STICK_CLICK:
				switch (model) {
					case PS4: "R3";
					case XINPUT: "RS";
					default: "C. Click";
				}

			// Directional
			case DPAD_LEFT:					"D. Left";
			case DPAD_RIGHT:				"D. Right";
			case DPAD_UP:					"D. Up";
			case DPAD_DOWN:					"D. Down";

			// Top buttons
			case LEFT_SHOULDER:
				switch(model) {
					case PS4: "L1";
					case XINPUT: "LB";
					default: "L. Bumper";
				}
			case RIGHT_SHOULDER:
				switch(model) {
					case PS4: "R1";
					case XINPUT: "RB";
					default: "R. Bumper";
				}
			case LEFT_TRIGGER, LEFT_TRIGGER_BUTTON:
				switch(model) {
					case PS4: "L2";
					case XINPUT: "LT";
					default: "L. Trigger";
				}
			case RIGHT_TRIGGER, RIGHT_TRIGGER_BUTTON:
				switch(model) {
					case PS4: "R2";
					case XINPUT: "RT";
					default: "R. Trigger";
				}

			// Buttons
			case A:
				switch (model) {
					case PS4: "X";
					case XINPUT: "A";
					default: "Action Down";
				}
			case B:
				switch (model) {
					case PS4: "O";
					case XINPUT: "B";
					default: "Action Right";
				}
			case X:
				switch (model) {
					case PS4: "["; //This gets its image changed through code
					case XINPUT: "X";
					default: "Action Left";
				}
			case Y:
				switch (model) {
					case PS4: "]"; //This gets its image changed through code
					case XINPUT: "Y";
					default: "Action Up";
				}

			case BACK:
				switch(model) {
					case PS4: "Share";
					case XINPUT: "Back";
					default: "Select";
				}
			case START:
				switch(model) {
					case PS4: "Options";
					default: "Start";
				}

			default:
				[for (i in key.toString().split('_')) capitalize(i)].join(' ');
		}
	}

	@:noCompletion static final _mapOverrideKeysName:Map<FlxKey, String> = [
		ESCAPE => "ESC",
		// BACKSPACE => "[←]",
		BACKSPACE => "BACK",
		NUMPADZERO => "#0",
		NUMPADONE => "#1",
		NUMPADTWO => "#2",
		NUMPADTHREE => "#3",
		NUMPADFOUR => "#4",
		NUMPADFIVE => "#5",
		NUMPADSIX => "#6",
		NUMPADSEVEN => "#7",
		NUMPADEIGHT => "#8",
		NUMPADNINE => "#9",
		NUMPADPLUS => "#+",
		NUMPADMINUS => "#-",
		NUMPADPERIOD => "#.",
		ZERO => "0",
		ONE => "1",
		TWO => "2",
		THREE => "3",
		FOUR => "4",
		FIVE => "5",
		SIX => "6",
		SEVEN => "7",
		EIGHT => "8",
		NINE => "9",
		PERIOD => ".",
	];
	public static function keyToString(key:Null<FlxKey>):String
	{
		return switch (key)
		{
			case null | 0 | NONE: "---";
			default: _mapOverrideKeysName.get(key) ?? key.toString();
		}
	}

	static var _mousePoint:FlxPoint = new FlxPoint();
	static var _objPoint:FlxPoint = new FlxPoint();
	static var _objRect:FlxRect = new FlxRect();
	public static var onVolumeChange(default, null):FlxTypedSignal<Float->Void>;
	public static var __easeMap = new Map<String, EaseFunction>();

	@:allow(game.Main)
	static function init()
	{
		for (f in Type.getClassFields(FlxEase))
			if (f.toUpperCase() != f) // a function field name
				__easeMap.set(f.toLowerCase(), Reflect.field(FlxEase, f));

		onVolumeChange = new FlxTypedSignal<Float->Void>();
		FlxG.sound.volumeHandler = onVolumeChange.dispatch;
		game.backend.system.CursorManager.init();
		game.backend.utils.BitmapDataUtil.init();
		#if HAXE_UI
		if (!Toolkit.initialized)
		{
			Toolkit.init({container: FlxG.game.stage});
			Toolkit.theme = 'dark';
		}
		#end

		// FlxG.signals.preStateSwitch.add(() -> {_mousePoint = FlxDestroyUtil.put(_mousePoint); _objPoint = FlxDestroyUtil.put(_objPoint);});
	}

	public static inline function getFlxEaseByString(ease:String):EaseFunction
		return __easeMap.get(ease.toLowerCase().trim());

	public static function mouseOverlapping<T:flixel.FlxObject>(obj:T, ?mousePoint:FlxPoint, ?camera:flixel.FlxCamera)
	{
		// if (_mousePoint == null) _mousePoint = FlxPoint.get();
		camera ??= obj.camera;
		mousePoint ??= FlxG.mouse.getScreenPosition(camera, _mousePoint);
		// if (_objPoint == null) _objPoint = FlxPoint.get();
		//   if (Std.isOfType(obj, FlxSprite))
		//   {
		//   	var obj:FlxSprite = cast obj;
		//   	obj.getScreenBounds(_objRect, camera);
		//   	return FlxMath.pointInCoordinates(mousePoint.x, mousePoint.y, _objRect.x, _objRect.y, _objRect.width, _objRect.height);
		//   }
		//   else
		{
			obj.getScreenPosition(_objPoint, camera);
			return FlxMath.pointInCoordinates(mousePoint.x, mousePoint.y, _objPoint.x, _objPoint.y, obj.width, obj.height);
		}
	}

	@:noUsing public static function smoothStep(edge0:Float, edge1:Float, x:Float):Float
	{
		x = FlxMath.bound((x - edge0) / (edge1 - edge0), 0, 1);
		return x * x * (3.0 - 2.0 * x);
		// return x * x * x * (x * (6.0 * x - 15.0) + 10.0);
	}

	@:noUsing public static function step(edge:Float, x:Float):Float
	{
		return edge > x ? 1 : 0;
	}

	@:noUsing public static function deleteFolder(delete:String)
	{
		#if sys
		if (!FileSystem.exists(delete))
			return;
		try
		{
			final files = FileSystem.readDirectory(delete);
			if (files.length == 0)
			{
				if (FileSystem.isDirectory(delete))
				{
					FileSystem.deleteDirectory(delete);
				}
				else
				{
					FileSystem.deleteFile(delete);
				}
			}
			else
			{
				for (file in files)
				{
					if (FileSystem.isDirectory(delete + "/" + file))
					{
						deleteFolder(delete + "/" + file);
						FileSystem.deleteDirectory(delete + "/" + file);
					}
					else
					{
						FileSystem.deleteFile(delete + "/" + file);
					}
				}
			}
		}
		#end
	}

	public static inline function getLastOfArray<T>(a:Array<T>):T
		return a[a.length - 1];

	public static inline extern function last<T>(a:Array<T>):T
		return getLastOfArray(a);

	public static inline extern function getLast<T>(a:Array<T>):T
		return getLastOfArray(a);

	public static inline function clearArray<T>(a:Array<T>):Array<T>
	{
		// while (a.length > 0) a.pop();
		a.resize(0);
		return a;
	}

	public static inline extern function clear<T>(a:Array<T>):Array<T>
	{
		return clearArray(a);
	}

	@:deprecated("Use autoAnimations")
	inline public static function tryExportAllAnimsFromXmlFlxSprite<T:FlxSprite>(sprite:T, ?filePos:PosInfos):FlxSprite
	{
		return autoAnimations(sprite, filePos);
	}

	/**
	 * Try to generate animations based on `FlxSprite` frame collection.
	 * @param   sprite      `FlxSprite` to generate animations for.
	 * @param   trimChars   How many characters to trim from the end of frame name?
	 * @param   autoPlay    If `true`, plays first added animation.
	 * @return This `FlxSprite` for chaining.
	 */
	public static function autoAnimations<T:FlxSprite>(sprite:T, trimChars = 4, autoPlay = true, ?filePos:PosInfos):FlxSprite
	{
		final anims:Array<String> = [];
		if (sprite.frames != null)
		{
			// for (name in @:privateAccess sprite.frames.framesByName.keys())
			for (frame in sprite.frames.frames)
			{
				// name = name.substr(0, name.length - trimChars);
				final name = frame.name.substr(0, frame.name.length - trimChars);
				if (!anims.contains(name))
					anims.push(name);
			}
		}

		if (anims.length == 0)
		{
			Log("No animations, damn. :(", YELLOW, filePos);
		}
		else
		{
			for (anim in anims)
				sprite.animation.addByPrefix(anim, anim, 24, false);
			if (autoPlay)
				sprite.animation.play(anims[0]);
		}

		return sprite;
	}

	public static function setFieldDefault<T>(v:Dynamic, name:String, defaultValue:T):T
	{
		if (Reflect.hasField(v, name))
		{
			final f:Null<Dynamic> = Reflect.field(v, name);
			if (f != null)
				return cast f;
		}
		Reflect.setField(v, name, defaultValue);
		return defaultValue;
	}

	public static inline function isNaN(v:Dynamic)
	{
		return v is Float && Math.isNaN((v : Float));
	}

	public static inline function getDefault<T>(v:Null<T>, defaultValue:T):T
		return (v == null || isNaN(v)) ? defaultValue : v;

	@:noUsing public static inline function getFrontCamera():FlxCamera
		return FlxG.cameras.list[FlxG.cameras.list.length - 1];

	public static inline function addZeros(str:String, num:Int):String
	{
		// for (_ in 0...(num - str.length))
		// 	str = '0$str';
		// return str;
		return str.lpad("0", num);
	}

	public static inline function addEndZeros(str:String, num:Int):String
	{
		// for (_ in 0...(num - str.length))
		// 	str += '0';
		return str.rpad("0", num);
	}

	public static inline function getSavePath():String
		@:privateAccess
		return FlxG.stage.application.meta.get("company") + "/" + flixel.util.FlxSave.validate(FlxG.stage.application.meta.get("file"));

	/**
		Formats hours, minutes and seconds to just seconds.
	**/
	@:noUsing public static inline function timeToSeconds(h:Float, m:Float, s:Float):Float
		return h * 3600 + m * 60 + s;

	@:access(flixel.FlxGame)
	@:noUsing public static function alert(?message:String, ?title:String)
	{
		if (!ClientPrefs.displErrs)
			return;
		#if UI_POPUPS
		if (!ClientPrefs.displErrsWindow)
		{
			FlxG.mouse.visible = true;
			game.backend.utils.Notifications.show(title, message, Warning);
		}
		else
		#else
		if (ClientPrefs.displErrsWindow)
		#end
		{
			var oldAutoPause = FlxG.autoPause;
			FlxG.autoPause = true; // trying to stop game
			FlxG.stage.application.window.alert(message, title);
			FlxG.autoPause = oldAutoPause;
		}
	}

	@:noUsing public static inline function browserLoad(site:String)
	{
		#if linux
		Sys.command('/usr/bin/xdg-open', [site]);
		#else
		FlxG.openURL(site);
		#end
	}

	public static function openFolder(pathFolder:String)
	{
		#if windows
		Sys.command('explorer', [pathFolder.replace("/", "\\")]);
		#elseif mac
		// mac could be fuckie with where the log folder is relative to the game file...
		// if this comment is still here... it means it has NOT been verified on mac yet!
		//
		// FileUtil.hx note: this was originally used to open the logs specifically!
		// thats why the above comment is there!
		Sys.command('open', [pathFolder]);
		#end

		// TODO: implement linux
		// some shit with xdg-open :thinking: emoji...
	}

	static final byteNames = ["B", "KB", "MB", "GB" /*, "TB", "PB"*/];
	static final __log1024 = Math.log(1024);

	public static function formatBytes(bytes:Float, ?dec:Int):String
	{
		// if (bytes == 0)
		// 	return "0 " + byteNames[0];

		var power = Std.int(Math.log(bytes) / __log1024);
		if (power >= byteNames.length)
			power = byteNames.length - 1;
		return '${FlxMath.roundDecimal(bytes / Math.pow(1024, power), dec ?? 2)} ${byteNames[power]}';
	}

	@:noUsing public static function detectRecordingPrograms(?additionalProcList:Array<String>) {
		#if cpp
		var elProcess:HiddenProcess = null;
		var output:String = null;

		try
		{
			elProcess = new HiddenProcess("tasklist", ["/fo", "csv"]);
			output = elProcess.stdout.readAll().toString().toLowerCase();
		}
		catch(e)
		{
			Log(e, RED);
		}
		elProcess?.close();

		if (output != null && output.length != 0)
		{
			/*
			var blockedShit:Array<String> = ['bandicam', 'bdcam.exe', 'obs64.exe', 'obs32.exe', 'streamlabs obs.exe', 'streamlabs obs32.exe'];
			*/
			var blockedShit:Array<String> = [
				'bandicam', 'obs64', 'obs32', 'streamlabs ',  //здарова ГЕЙмеры
				'bdcam',  //любитель майнкрафт сериалов
				'fraps',  // сампер
				'xsplit', // рецедивист
				'hycam2', // бумер
				'twitchstudio', // мазохист
				'Game Bar' // ебать забавный челик
			];
			for (i in 0...blockedShit.length)
			{
				if (output.contains(blockedShit[i]))
				{
					return true;
				}
			}
			if (additionalProcList != null && additionalProcList.length != 0)
			{
				for (i in 0...additionalProcList.length)
				{
					if (output.contains(additionalProcList[i]))
					{
						elProcess?.close();
						return true;
					}
				}
			}
		}
		#end
		return false;
	}

	@:access(flixel.sound.FlxSound)
	@:access(flixel.system.frontEnds.SoundFrontEnd)
	public static function loadSound(?embeddedSound:flixel.system.FlxAssets.FlxSoundAsset, volume = 1.0, looped = false, ?typeSound:Class<FlxSound>,
			?group:flixel.sound.FlxSoundGroup, autoDestroy = false, autoPlay = false, ?url:String, ?onComplete:Void->Void, ?onLoad:Void->Void):FlxSound
	{
		if (embeddedSound == null && url == null)
		{
			FlxG.log.warn("FlxG.sound.load() requires either\nan embedded sound or a URL to work.");
			return null;
		}

		var sound:FlxSound = FlxG.sound.list.recycle(typeSound ?? FlxSound);

		if (embeddedSound == null)
		{
			var loadCallback = onLoad;
			if (autoPlay)
			{
				// Auto play the sound when it's done loading
				loadCallback = function()
				{
					sound.play();

					if (onLoad != null)
						onLoad();
				}
			}

			sound.loadStream(url, looped, autoDestroy, onComplete, loadCallback);
			FlxG.sound.loadHelper(sound, volume, group);
		}
		else
		{
			sound.loadEmbedded(embeddedSound, looped, autoDestroy, onComplete);
			FlxG.sound.loadHelper(sound, volume, group, autoPlay);
			// Call OnlLoad() because the sound already loaded
			if (onLoad != null && sound._sound != null)
				onLoad();
		}

		return sound;
	}

	public static function killSounds(songsArray:Array<FlxSound>) // neat function thing for songs
		for (i in songsArray)
		{
			// stop
			i.stop();
			i.destroy();
			@:privateAccess FlxG.sound.destroySound(i); // huh
		}

	/*
		public static inline function optimizeFolder(folder:String){
			var count = 0;
			for (file in FileSystem.readDirectory(folder)){
				var fullPath = Path.join([folder, file]);
				if (FileSystem.isDirectory(fullPath))
					optimizeFolder(fullPath);
				else if (file.endsWith('.png')){
					var fileName = Path.withoutExtension(fullPath);
					if (FileSystem.exists('$fileName.xml')){
						var graphic = FlxG.bitmap.add(BitmapData.fromFile(fullPath), false, fullPath);
						optimizeImage(fullPath, FlxAtlasFrames.fromSparrow(graphic, File.getContent('$fileName.xml')), true);
						count++;
					}/* else if (FileSystem.exists('$fileName.json')){
						var graphic = FlxG.bitmap.add(BitmapData.fromFile(fullPath), false, fullPath);
						var frames = new FlxAtlasFrames(graphic);
						var curJson:flxanimate.data.SpriteMapData.AnimateAtlas = Json.parse(File.getContent('$fileName.json').replace(String.fromCharCode(0xFEFF), ""));
						if (curJson != null && curJson.ATLAS != null && curJson.ATLAS.SPRITES != null){
							for (curSprite in curJson.ATLAS.SPRITES){
								var sprite = curSprite.SPRITE;

								var rect = FlxRect.get(sprite.x, sprite.y, sprite.w, sprite.h);

								var size = new Rectangle(0, 0, rect.width, rect.height);
								var sourceSize = FlxPoint.get(size.width, size.height);
								if (sprite.rotated)
									sourceSize.set(size.height, size.width);

								var offset = FlxPoint.get();

								var angle = sprite.rotated ? FlxFrameAngle.ANGLE_NEG_90 : FlxFrameAngle.ANGLE_0;

								frames.addAtlasFrame(rect, sourceSize, offset, sprite.name, angle);
							}
							optimizeImage(fullPath, frames);
							count++;
						}
						else
						{
							FlxG.bitmap.remove(graphic);
							frames.destroy();
						}
					}*/
				/*}
			}
		}
		if (count > 0) trace('Optimized $count images in $folder');
	}*/

	public static function optimizeImage(path:String, frames:FlxFramesCollection, freeMemory:Bool = false):Dynamic
		#if sys
		if (FileSystem.exists(path))
			try
			{
				var maxX:Float = 0;
				var maxY:Float = 0;
				trace('Start');
				var maxMemberX:Float;
				var maxMemberY:Float;
				for (frame in frames.frames)
				{
					maxMemberX = frame.frame.right;
					maxMemberY = frame.frame.bottom;
					if (maxX < maxMemberX)
						maxX = maxMemberX;
					if (maxY < maxMemberY)
						maxY = maxMemberY;
				}
				var newWidth = Math.ceil(maxX);
				var newHeight = Math.ceil(maxY);
				var bmap = BitmapData.fromFile(path);
				trace('Encode...');
				var data = bmap.encode(new Rectangle(0, 0, newWidth, newHeight), new PNGEncoderOptions(false));
				trace('Encode complete!');
				trace('Saving...');
				File.saveBytes(path, data);
				trace('Saving complete!');
				bmap.dispose();
				bmap.disposeImage();
				data = null;
				if (freeMemory)
				MainLoop.runInMainThread(() -> {
					trace('Clear Memory!');
					Paths.clearUnusedMemory();
					Main.clearCache();
					MemoryUtil.clearMajor();
					MemoryUtil.clearMinor();
				});
				return null;
			}
			catch (e)
				return e;
		else
		#end
			return 'DEEZ NUTS ($path not found)';

	public static function optimizeImageSyns(path:String, frames:FlxFramesCollection, freeMemory:Bool = false):Future<String>
	{
		var promise = new Promise<String>();
		execAsync(() ->
		{
			var shit = optimizeImage(path, frames, freeMemory);
			if (shit == null)
				promise.complete('YIPE');
			else
				promise.error(shit);
		});
		return promise.future;
	}

	/**
	 * Gets the macro class created by hscript-improved for an abstract / enum
	 */
	@:noUsing public static inline function getMacroAbstractClass(className:String)
		return Type.resolveClass('${className}_HSC');

	// TO DO: REWRITE TO JUST USE FUNC CREATE AND ALLOW REMOVE UNUSED THREADS
	// static var gameThreads:Array<Thread> = [for (_ in 0...ClientPrefs.maxValidThread-1) Thread.createWithEventLoop(Thread.current().events.promise)];
	/*
	static var gameThreads:Array<Thread> = [
		for (_ in 0...1) Thread.createWithEventLoop(function() Thread.current().events.promise())
	];
	static var __threadCycle:Int = 0;
	*/

	public static inline function execAsync(func:Void->Void)
	{
		return ThreadUtil.create(func);
	}

	public static inline function unixNewLine(s:String):String
	{
		// TODO: should we account for legacy mac new line?
		return s.replace("\r", ""); // s.replace("\r\n", "\n").replace("\r", "");
	}
}
