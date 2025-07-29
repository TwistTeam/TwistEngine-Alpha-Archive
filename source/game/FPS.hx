package game;

import flixel.graphics.tile.FlxDrawBaseItem;
import flixel.input.keyboard.FlxKey;
import flixel.math.FlxMath;
import flixel.util.FlxSignal;
import flixel.util.FlxStringUtil;
import game.backend.assets.IModsAssetLibrary;
import game.backend.assets.ScriptedAssetLibrary;
import game.backend.data.EngineData;
import game.backend.system.InfoAPI;
import game.backend.system.macros.GitCommitMacro;
import game.backend.utils.ThreadUtil;
import openfl.Lib;
import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.display.DisplayObject;
import openfl.display.DisplayObjectContainer;
import openfl.display.Sprite;
import openfl.events.Event;
#if android
import openfl.events.TouchEvent;
#if extension-androidtools
import extension.androidtools.os.Build;
#end
#end
#if gl_stats
import openfl.display._internal.stats.Context3DStats;
import openfl.display._internal.stats.DrawCallContext;
#end
import openfl.geom.*;
import openfl.system.System;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.text._internal.TextFormatRange;

#if neko
import neko.vm.Gc;
#elseif cpp
import cpp.vm.Gc;
#elseif hl
import hl.Gc;
#end

private enum abstract FPSAlighEnum(FPSAligh) from FPSAligh to FPSAligh
{
	var LEFT_TOP:FPSAligh = 0x00;
	var LEFT_BOTTOM:FPSAligh = 0x01;
	var RIGHT_TOP:FPSAligh = 0x10;
	var RIGHT_BOTTOM:FPSAligh = 0x11;
}

enum abstract FPSVisible(UByte) from UByte to UByte from Int to Int from UInt to UInt
{
	var FPS_FULL:FPSVisible = 3;
	var FPS_HALF:FPSVisible = 2;
	var FPS_ONLY_FRAMERATE:FPSVisible = 1;
	var FPS_NONE:FPSVisible = 0;

	@:from public static function fromString(i:String):FPSVisible
	{
		return switch (i) {
			case "FPS_FULL": FPS_FULL;
			case "FPS_HALF": FPS_HALF;
			case "FPS_ONLY_FRAMERATE": FPS_ONLY_FRAMERATE;
			default: FPS_NONE;
		}
	}

	@:to function toString():String
	{
		return switch abstract {
			case FPS_FULL: "FPS_FULL";
			case FPS_HALF: "FPS_HALF";
			case FPS_ONLY_FRAMERATE: "FPS_ONLY_FRAMERATE";
			default: "FPS_NONE";
		}
	}
	@:op(A > B) private static inline function gt(a:FPSVisible, b:FPSVisible):Bool
	{
		return (a : Int) > (b : Int);
	}

	@:op(A >= B) private static inline function gte(a:FPSVisible, b:FPSVisible):Bool
	{
		return (a : Int) >= (b : Int);
	}

	@:op(A < B) private static inline function lt(a:FPSVisible, b:FPSVisible):Bool
	{
		return (a : Int) < (b : Int);
	}

	@:op(A <= B) private static inline function lte(a:FPSVisible, b:FPSVisible):Bool
	{
		return (a : Int) <= (b : Int);
	}
}


abstract FPSAligh(UByte) from UByte to UByte from Int to Int from UInt to UInt
{
	public var RIGHT(get, never):Bool;
	public var DOWN(get, never):Bool;

	inline function get_RIGHT()
		return this & 0x10 == 0x10;

	inline function get_DOWN()
		return this & 0x01 == 0x01;

	@:from public static function fromString(i:String):FPSAligh
	{
		var e:Int = 0;
		i = i.toUpperCase().trim();
		if (i.startsWith("RIGHT"))
			e |= 0x10;
		if (i.endsWith("BOTTOM"))
			e |= 0x01;
		return e;
	}

	@:to function toString():String
	{
		return (RIGHT ? "RIGHT" : "LEFT") + "_" + (DOWN ? "BOTTOM" : "TOP");
	}
}

@:access(openfl.text.TextField)
class FPS extends Sprite
{
	/**
	 * Because reading any data from DisplayObject is insanely expensive in hxcpp, keep track of whether we need to update it or not.
	 */
	public var active:Bool;

	public var fpsText:TextField;
	public var innerGroup:DisplayObjectContainer;
	public var bgBitmap:Bitmap;
	public var offsetX:Float;
	public var offsetY:Float;
	public var onUpdatePosition:FlxTypedSignal<FPSAligh -> Void> = new FlxTypedSignal();

	/**
		The current frame rate, expressed using frames-per-second
	**/
	// public var currentFPS(default, null):Int = 0;
	// @:noCompletion var times(default, null):Array<Float> = [];
	public var currentFPS(get, set):Float;
	@:noCompletion inline function get_currentFPS()		return currentDrawFPS;
	@:noCompletion inline function set_currentFPS(i)	return currentDrawFPS = i;

	public var currentDrawFPS(default, null):Float = 0;
	public var currentTypeRender(default, null):String = null;

	public var multScale(default, set):Float = #if mobile 2.5 #else 1 #end;
	@:noCompletion function set_multScale(i:Float):Float {
		if (multScale != i && !FlxMath.equal(i, 0)) // prevent zero scale
		{
			multScale = i;
			scaleX = scaleX;
			scaleY = scaleY;
		}
		return multScale;
	}

	public var currentMem(default, null):Float;
	@:noCompletion var _currentMem(get, never):Float;
	@:noCompletion inline function get__currentMem()
		return #if cpp
				Gc.memInfo64(Gc.MEM_INFO_CURRENT);
			#elseif hl
				Gc.stats().currentMemory;
			#else
				System.totalMemory;
			#end
	public var memoryMegasMax(default, null):Float = 0;
	public var alignment(default, set):FPSAligh = RIGHT_TOP;

	@:noCompletion function set_alignment(i)
	{
		alignment = i;
		_dirtyUpdatePos = true;
		return alignment;
	}

	public var showMem(default, set):Bool = true;

	@:noCompletion function set_showMem(i)
	{
		showMem = i;
		_dirtyUpdatePos = true;
		return showMem;
	}

	public var showSysInfo(default, set):Bool = false;

	@:noCompletion function set_showSysInfo(i)
	{
		showSysInfo = i;
		_dirtyUpdatePos = true;
		return showSysInfo;
	}

	public var showHaxeLibs(default, set):Bool = false;

	@:noCompletion function set_showHaxeLibs(i)
	{
		showHaxeLibs = i;
		_dirtyUpdatePos = true;
		return showHaxeLibs;
	}

	public var showDebugInfo(default, set):Bool = false;

	@:noCompletion function set_showDebugInfo(i)
	{
		showDebugInfo = i;
		_dirtyUpdatePos = true;
		return showDebugInfo;
	}

	@:keep @:noCompletion override function set_scaleX(value:Float):Float
	{
		__scaleX = super.set_scaleX(value * multScale) / multScale;
		_dirtyUpdatePos = true;
		return __scaleX;
	}

	@:keep @:noCompletion override function set_scaleY(value:Float):Float
	{
		__scaleY = super.set_scaleY(value * multScale) / multScale;
		_dirtyUpdatePos = true;
		return __scaleY;
	}

	public function changeFont(newFont:String)
	{
		fpsText.defaultTextFormat.font = Assets.getFont(
			AssetsPaths.font(newFont)
		)?.fontName ?? flixel.system.FlxAssets.FONT_DEFAULT;
		_dirtyUpdatePos = true;
	}

	public function updatePos()
	{
		if (parent != null)
		{
			if (alignment.RIGHT)
			{
				fpsText.__textFormat.align = RIGHT;
				x = stage.stageWidth;
			}
			else
			{
				fpsText.__textFormat.align = LEFT;
				x = 0;
			}
			if (alignment.DOWN)
			{
				y = stage.stageHeight;
			}
			else
			{
				y = 0;
			}
		}

		updateText();
		onUpdatePosition.dispatch(alignment);

		updateBG();
	}
	@:noCompletion var _dirtyUpdatePos:Bool = true;

	@:noCompletion var _altStyle:openfl.utils.Object;

	@:access(openfl.text.StyleSheet.__styles)
	public function new(offsetX:Float = 10, offsetY:Float = 10)
	{
		super();

		this.offsetX = offsetX;
		this.offsetY = offsetY;

		mouseEnabled = false;

		bgBitmap = new Bitmap(new BitmapData(1, 1, false, 0xFF000000));
		// bgSprite = new Sprite();
		// bgBitmap.mouseEnabled = false;
		// bgBitmap.graphics.beginFill(0xFF000000);
		// bgBitmap.graphics.drawRect(0, 0, 1, 1);
		// bgBitmap.graphics.endFill();
		bgBitmap.alpha = 1 / 3;
		addChild(bgBitmap);

		innerGroup = new DisplayObjectContainer();
		innerGroup.mouseEnabled = true;
		innerGroup.__drawableType = SPRITE;
		addChild(innerGroup);

		fpsText = new TextField();
		fpsText.selectable = fpsText.mouseEnabled = false;
		fpsText.defaultTextFormat = new TextFormat(Assets.getFont(
			AssetsPaths.font("VCR OSD Mono Cyr.ttf")
		)?.fontName ?? flixel.system.FlxAssets.FONT_DEFAULT, 12, 0xEEEEEE);
		fpsText.autoSize = LEFT;
		fpsText.multiline = true;

		fpsText.__styleSheet = new openfl.text.StyleSheet();
		fpsText.__styleSheet.__styles.set("bold-format", _altStyle = {
			fontSize: fpsText.defaultTextFormat.size + 1,
			color: 0xFFFFFF.hex(6)
		});

		innerGroup.addChild(fpsText);

		innerGroup.x = offsetX;
		innerGroup.y = offsetY;

		fpsText.removeEventListeners();

		@:bypassAccessor {
			alignment = FPSAligh.fromString(ClientPrefs.fpsAligh);
			showMem = ClientPrefs.showMemory;
			showSysInfo = ClientPrefs.showSystemInfo;
			showHaxeLibs = true;
			showDebugInfo = ClientPrefs.showDebugInfo;
		}
		// bind orig set method
		super.set_scaleX(super.set_scaleY(ClientPrefs.fpsScale));

		FlxG.signals.postUpdate.add(flixelUpdate);
		FlxG.signals.gameResized.add((w, h) -> updatePos());
		updatePos();
		updateVisible();

		var wind = Lib.current.stage.window;
		if (wind != null)
		{
			wind.onRenderContextLost.add(() -> {
				Log("The context of the rendering is lost", YELLOW);
				updateCurrentTypeRenderer();
			});
			wind.onRenderContextRestored.add(_ -> {
				updateCurrentTypeRenderer();
				Log('Restoring the rendering context -> \'$currentTypeRender\'', YELLOW);
			});
		}
		updateCurrentTypeRenderer();
		addEventListener(Event.ADDED_TO_STAGE, _ -> { // maybe??
			updatePos();
			_dirtyUpdatePos = false;
		});
		#if android
		addEventListener(TouchEvent.TOUCH_BEGIN, _ -> {
			curVisible = Std.int(FlxMath.wrap(curVisible + 1, FPS_ONLY_FRAMERATE, FPS_FULL));
		});
		// addEventListener(TouchEvent.TOUCH_ROLL_OUT, _ -> { // todo lol?
		// 	curVisible = Std.int(FlxMath.wrap(curVisible + 1, FPS_ONLY_FRAMERATE, FPS_FULL));
		// });
		#end
		FlxG.signals.postStateSwitch.add(resetViewMaxMemory);
	}

	function updateCurrentTypeRenderer() {
		var type = Lib.current.stage.window?.context.type;
		currentTypeRender = type != null ? Std.string(type).toUpperCase() : "|UNKNOWN|";
	}

	// Event Handlers
	@:noCompletion
	override function __enterFrame(deltaTime:Int):Void {
		super.__enterFrame(deltaTime);
		if (_dirtyUpdatePos)
		{
			_dirtyUpdatePos = false;
			updatePos();
		}
		updateBG();
	}


	extern inline function __calc__fps(__cur__fps:Float, __e:Float):Float
		return FlxMath.lerp(__e == 0.0 ? 0.0 : 1.0 / __e, __cur__fps, Math.exp(-__e * 15.0));

	@:noCompletion var deltaTimeout:Float = 0.0;

	public var deltaTimeUpdate:UInt32 = 75;

	public var keysToggleVisible:Array<FlxKey> = [FlxKey.F3];

	// #if lime_cffi @:access(haxe.Timer.getMS) #end
	@:access(flixel.FlxGame._elapsedMS)
	@:access(openfl.display.Stage.__deltaTime)
	function flixelUpdate():Void
	{
		/*
			final now:Float = #if lime_cffi haxe.Timer.getMS() #else haxe.Timer.stamp() * 1000 #end;
			times.push(now);
			while (times[0] < now - 1000) times.shift();

			currentFPS = (ClientPrefs.showCurretFPS || FlxG.updateFramerate > times.length ? times.length : FlxG.updateFramerate);
		*/

		// ignores FlxG.timeScale
		currentDrawFPS = __calc__fps(currentDrawFPS, FlxG.game._elapsedMS / 1000);

		#if desktop
		if (visible && FlxG.keys.anyJustPressed(keysToggleVisible))
		{
			curVisible = Std.int(FlxMath.wrap(curVisible + 1, FPS_NONE, FPS_FULL));
		}
		#end
		// prevents the overlay from updating every frame
		deltaTimeout += FlxG.game._elapsedMS;
		if (deltaTimeout < deltaTimeUpdate)
			return;

		deltaTimeout -= deltaTimeUpdate;

		// if (active*/){
		updateText();
		// }
	}

	public var curVisible(default, set):FPSVisible = FPS_HALF;
	function set_curVisible(newVisible:FPSVisible)
	{
		// if (curVisible != newVisible)
		{
			curVisible = newVisible;
			updateVisible();
			updatePos();
		}
		return curVisible;
	}
	function updateVisible()
	{
		bgBitmap.visible = (curVisible > FPS_NONE);
	}

	@:noCompletion var _text:String = null;
	@:noCompletion var _textBuffer:StringBuf = null;
	@:noCompletion var _maxMemorytext:String = 0.formatBytes();
	static final _defaultAfterNewLine:String = "\n";
	var _afterNewLine:String = "\n";
	var _curSpace:String = "";

	function addSpace(len:Int = 2)
	{
		_curSpace = _curSpace.rpad(" ", _curSpace.length + len);
	}
	function removeSpace(len:Int = 2)
	{
		_curSpace = _curSpace.substring(0, _curSpace.length - len);
	}
	function addLine(?str:String, ?altStr:Dynamic)
	{
		if (str != null || altStr != null)
		{
			if (!alignment.RIGHT)
				// _text += _curSpace;
				_textBuffer.add(_curSpace);
			if (str != null)
				// _text += str;
				_textBuffer.add(str);
			if (altStr != null)
			{
				_textBuffer.add("<bold-format>"); _textBuffer.add(Std.string(altStr)); _textBuffer.add("</bold-format>");
				// _text += "<alt-text>" + Std.string(altStr) + "</alt-text>";
			}
			// _text += Std.string(altStr);
			// _textBuffer.add(altStr);
			if (alignment.RIGHT)
				// _text += _curSpace;
				_textBuffer.add(_curSpace);
		}
		// _text += _afterNewLine;
		_textBuffer.add(_afterNewLine);
	}

	/*
	function addLine(str:Dynamic = "", useFormat:Bool = true)
	{
		_text += (Std.string(str));
		_text += ("\n");
	}
	*/

	@:noCompletion var _endStuffStr:String = null;
	@:noCompletion var _haxelibsListStr:String = null;
	@:noCompletion var _sysInfoListStr:String = null;

	dynamic function updateLines()
	{
		if (curVisible <= FPS_NONE)
			return;
		// if (curVisible == FPS_HALF) _afterNewLine = " - ";
		addLine("FPS: ", ClientPrefs.showCurretFPS || FlxG.updateFramerate > currentFPS ? Math.floor(currentFPS) : FlxG.updateFramerate);

		if (curVisible > FPS_ONLY_FRAMERATE)
		{
			if (showMem)
			{
				// currentMem = cast(System.totalMemory, UInt);
				// currentMem = cpp.vm.Gc.memInfo(cpp.vm.Gc.MEM_INFO_USAGE) / 1024 * 1000;
				// currentMem = Std.int(Math.abs(cpp.NativeGc.memInfo(0)));
				// currentMem = Std.int(Math.abs(cpp.vm.Gc.memInfo64(cpp.vm.Gc.MEM_INFO_USAGE)));
				// currentMem = game.backend.utils.MemoryUtil.getMemoryfromProcess();
				/*
				currentMem = cast System.totalMemory;
				if (currentMem <= FlxMath.MAX_VALUE_INT)
				{
					if (memoryMegasMax < currentMem)
					{
						memoryMegasMax = currentMem;
						_maxMemorytext = memoryMegasMax.getSizeString();
					}
					addLine("Memory: ", '${currentMem.getSizeString()} || $_maxMemorytext');
				}
				else
					addLine("<alt-text>" + "Memory Leaking: " + "</alt-text>"
						+ "<alt-text>"
							+ '-${cast(currentMem - FlxMath.MAX_VALUE_INT, UInt).getSizeString()}</alt-text>');
				// addLine('Memory: ${currentMem.getSizeString()} || ${memoryMegasMax.getSizeString()}');
				*/
				currentMem = _currentMem;
				if (memoryMegasMax < currentMem)
				{
					memoryMegasMax = currentMem;
					_maxMemorytext = memoryMegasMax.formatBytes();
				}
				addLine("Memory: ", '${currentMem.formatBytes()} || $_maxMemorytext');
				// addLine('Memory: ${currentMem.formatBytes()} / ${CoolUtil.formatBytes(cpp.vm.Gc.memInfo(cpp.vm.Gc.MEM_INFO_RESERVED))}');
			}
			#if DEV_BUILD
			/*
				if (AssetsPaths.assetsTree != null){
					for(e in AssetsPaths.assetsTree.libraries) {
						var l = e;
						if (l is openfl.utils.AssetLibrary) {
							var al = cast(l, openfl.utils.AssetLibrary);
							@:privateAccess
							if (al.__proxy != null) l = al.__proxy;
						}

						// if (l is ScriptedAssetLibrary)
						// 	addLine('${Type.getClassName(Type.getClass(l))} - ${cast(l, ScriptedAssetLibrary).scriptName} (${cast(l, ScriptedAssetLibrary).modName} | ${cast(l, ScriptedAssetLibrary).libName} | ${cast(l, ScriptedAssetLibrary).prefix})');
						// else
						if (l is IModsAssetLibrary)
							addLine('${cast(l, IModsAssetLibrary).modName} - ${cast(l, IModsAssetLibrary).libName} (${cast(l, IModsAssetLibrary).prefix})');
						// else
						// 	addLine(Std.string(e));
					}
					addLine();
				}
			 */

			// if (ClientPrefs.showSysInfo || ClientPrefs.showDebugInfo) addLine();
			if (showDebugInfo)
			{
				addLine();
				addLine(null, "Haxe");

				#if target.threaded
				addSpace();
				addLine(null, "Threads");
					addSpace();
					addLine("Count: ", ThreadUtil.threadCount);
					addLine(null, "Public Looped List:");
						addSpace();
						ThreadUtil.mutex.acquire();
						var thread:ThreadParams;
						for (i in FlxStringUtil.sortAlphabetically([for (i in ThreadUtil.loopingThreads.keys()) i]))
						{
							thread = ThreadUtil.loopingThreads.get(i);
							if (thread.isDestroyed || thread.thread == null)
							{
								addLine("<font color=\"#ef6666\">" + i + "</font>"); // RED
							}
							else if (thread.isPaused)
							{
								addLine("<font color=\"#999999\">" + i + "</font>"); // GRAY
							}
							else
							{
								addLine(i);
							}
						}
						ThreadUtil.mutex.release();
						removeSpace();
					removeSpace();
				removeSpace();
				#end
				addLine();
				addLine(null, "Flixel");
					addSpace();
					addLine("Elapsed: ", FlxG.elapsed);
					addLine("Stability: ", Std.string(Math.round(100 / FlxG.drawFramerate / FlxG.elapsed)) + " %");
					if (FlxG.state != null)
					{
						addLine("State: ", Type.getClassName(Type.getClass(FlxG.state)));
						var subState:FlxSubState = FlxG.state.subState;
						if (subState != null)
						{
							var subStateStr = '<alt-text>[I]</alt-text>';
							if (alignment.RIGHT)
							{
								subStateStr = subStateStr + " ←";
							}
							else
							{
								subStateStr = "→ " + subStateStr;
							}
							var order:Int = -1;
							var leftPart = subStateStr.substring(0, subStateStr.indexOf("[I]"));
							var rightPart = subStateStr.substring(subStateStr.indexOf("[I]") + 3);
							do
							{
								order += 2;
								addSpace(Std.int(Math.min(order, 2)));
								addLine(leftPart + Type.getClassName(Type.getClass(subState)) + rightPart);
								subState = subState.subState;
							}
							while (subState != null);
							removeSpace(order);
						}

						var len:UInt = 0;
						function fromState(state:flixel.FlxState)
						{
							if (state == null)
								return;
							state.forEach(_ -> len++, true);
							fromState(state.subState);
						}
						fromState(FlxG.state);
						addLine("Objects Count: ", Std.string(len));
						addLine("Last Draw Calls Count: ", Std.string(FlxDrawBaseItem.drawCalls));
					}
					// addLine("  Camera Count: ", FlxG.cameras.list.length);
					@:privateAccess {
						addLine("FlxGraphics Count: ", Lambda.count(FlxG.bitmap._cache));
						// addLine("Bitmaps Count: ${Lambda.count(cast (openfl.utils.Assets.cache, openfl.utils.AssetCache).	bitmapData)}  ");
						addLine("FlxG.game Childs Count: ", FlxG.game.numChildren);
						#if FLX_POINT_POOL
						addLine("FlxPoints Released: ", flixel.math.FlxPoint.FlxBasePoint.pool._count);
						// addLine("FlxPoints Count: ", flixel.math.FlxPoint.FlxBasePoint.pool._pool.length);
						#end
						addLine("FlxRects Released: ", flixel.math.FlxRect._pool._count);
						// addLine("FlxRects Count: ", flixel.math.FlxRect._pool._pool.length);
						addLine("FlxSounds Count: ", FlxG.sound.list.length);
						addLine("FlxTweens Count: ", flixel.tweens.FlxTween.globalManager._tweens.length);
						addLine("FlxTimers Count: ", flixel.util.FlxTimer.globalManager._timers.length);
						#if flxanimate
						addLine();
						addLine(null,  "FlxAnimate");
							addSpace();
							addLine("FlxPooledMatrixes Released: ", flxanimate.display.FlxPooledMatrix.pool._count);
							addLine("FlxPooledCameras Released: ", flxanimate.display.FlxPooledCamera.pool._count);
							removeSpace();
						#end
					}
					removeSpace();
				addLine();
				addLine(null, "OpenFL");
				@:privateAccess {
					addSpace();
					addLine("Rectangles Active: ", Rectangle.__pool.activeObjects);
					addLine("Rectangles Released: ", Rectangle.__pool.inactiveObjects);
					addLine("Points Active: ", Point.__pool.activeObjects);
					addLine("Points Released: ", Point.__pool.inactiveObjects);
					removeSpace();
				}
				// addLine();
				// addLine("GPU Memory: " + InfoAPI.vRAM); // not correct
				if (showHaxeLibs && curVisible > FPS_HALF)
				{
					if (_haxelibsListStr == null)
					{
						var prevText = _textBuffer;
						_textBuffer = new StringBuf();
						// _text = "";
						addLine();
						addLine(null, "HaxeLibs");
							addSpace();
							for (i in game.backend.system.macros.HaxeLibsMacro.libs)
								addLine(i.name.toUpperCase() + ": ", i.directory);
							#if android
							addLine();
							addLine("SOC MODEL: ", InfoAPI.SOC_MODEL);
							addLine("SKU: ", InfoAPI.SKU);
							addLine("SDK: ", InfoAPI.SDK);
							addLine();
							#end
							removeSpace();
						// _haxelibsListStr = _text;
						_haxelibsListStr = _textBuffer.toString();
						// _text = prevText;
						_textBuffer = prevText;
					}
					_textBuffer.add(_haxelibsListStr);
					// _text += _haxelibsListStr;
				}
			}
			if (curVisible > FPS_HALF)
			{
				if (showSysInfo)
				{
					if (_sysInfoListStr == null)
					{
						var prevText = _textBuffer;
						_textBuffer = new StringBuf();
						// _text = "";
						addLine();
						addLine("OS: ", InfoAPI.osInfo);
						addLine("CPU: ", InfoAPI.cpuName);
						// addLine("MEM: ", '${InfoAPI.totalMemStr} ${InfoAPI.memType}');
						addLine("MEM Type: ", InfoAPI.memType);
						addLine("Max Texture Size: ", '${InfoAPI.gpuMaxSize}x${InfoAPI.gpuMaxSize}');
						addLine("GPU: ", InfoAPI.gpuName);
						addLine();
						// _sysInfoListStr = _text;
						_sysInfoListStr = _textBuffer.toString();
						// _text = prevText;
						_textBuffer = prevText;
					}
					_textBuffer.add(_sysInfoListStr);
					// _text += _sysInfoListStr;
					addLine("Current Renderer Type: ", currentTypeRender);
					// if (Lib.current.stage.context3D != null)
					// 	addLine(null, "GPU AVAILABLE");
				}

				#if (gl_stats && !disable_cffi && (!html5 || !canvas))
				addLine();
				addLine("TotalDC: ", Std.string(Context3DStats.totalDrawCalls()));
				addLine("StageDC: ", Std.string(Context3DStats.contextDrawCalls(DrawCallContext.STAGE)));
				addLine("Stage3DDC: ", Std.string(Context3DStats.contextDrawCalls(DrawCallContext.STAGE3D)));
				#end

				if (_endStuffStr == null)
				{
					var prevText = _textBuffer;
					_textBuffer = new StringBuf();
					// _text = "";
					addLine();
					addLine("Twist Engine " + EngineData.engineVersion);
					#if DEV_BUILD
					addLine('Commit ${GitCommitMacro.number} (${GitCommitMacro.hash})');
					addLine('Build date: ${EngineData.lastCompile}');
					#end
					_endStuffStr = _textBuffer.toString();
					// _text = prevText;
					_textBuffer = prevText;
				}
				_textBuffer.add(_endStuffStr);
				// _text += _endStuffStr;
			}
			#end
		}
		_text = _textBuffer.toString();
		_text = _text.substring(0, _text.length - _afterNewLine.length);
		_textBuffer = null;
		// if (curVisible == FPS_HALF) _afterNewLine = _defaultAfterNewLine;
	}

	function updateText()
	{
		// _textBuffer = null;
		if (_textBuffer == null)
			_textBuffer = new StringBuf();
		_text = "";
		_curSpace = "";
		updateLines();
		fpsText.htmlText = _text;
		fpsText.x = alignment.RIGHT ? -fpsText.width : 0;
	}

	function updateBG()
	{ // ugh
		updateInnerGroupPositions();
		bgBitmap.scaleX = innerGroup.width + offsetX * 2;
		bgBitmap.scaleY = innerGroup.height + offsetY * 2 + 3;
		if (alignment.RIGHT)
		{
			bgBitmap.x = -bgBitmap.scaleX;
			innerGroup.x = innerGroup.width;
		}
		else
		{
			innerGroup.x = bgBitmap.x = 0;
		}
		innerGroup.x += bgBitmap.x + offsetX;
		if (alignment.DOWN)
		{
			bgBitmap.y = -bgBitmap.scaleY;
			innerGroup.y = bgBitmap.y + offsetY;
		}
		else
		{
			bgBitmap.y = 0;
			innerGroup.y = offsetY;
		}
	}
	function updateInnerGroupPositions()
	{
		var _y:Float = 0.0;
		for (child in innerGroup.__children)
		{
			child.y = _y;
			_y += child.height + 3;
		}

	}

	#if UPDATE_FEATURE
	public function addDowloaderUI(dowloader) {
		var dowl = new game.objects.openfl.DowloaderUI(dowloader);
		dowl.y = innerGroup.height;
		innerGroup.addChild(dowl);
		// addChildAt(new game.objects.openfl.InnerMousePointer(), getChildIndex(bgBitmap) + 1);
	}
	#end

	public function resetViewMaxMemory()
	{
		memoryMegasMax = -1;
	}

	/*
	@:noCompletion private override function __hitTest(x:Float, y:Float, shapeFlag:Bool,
		stack:Array<DisplayObject>, interactiveOnly:Bool, hitObject:DisplayObject):Bool
	{
		return false;
	}

	@:noCompletion private override function __hitTestHitArea(x:Float, y:Float, shapeFlag:Bool,
		stack:Array<DisplayObject>, interactiveOnly:Bool, hitObject:DisplayObject):Bool
	{
		return false;
	}

	@:noCompletion private override function __hitTestMask(x:Float, y:Float):Bool
	{
		return false;
	}
	*/
}
