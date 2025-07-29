package game.objects;

import flixel.sound.FlxSound;
import flixel.input.keyboard.FlxKey;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.math.FlxRect;
import flixel.math.FlxPoint;
import flixel.util.FlxDestroyUtil;
import flixel.util.FlxPool;

import game.backend.utils.MemoryUtil;
import game.objects.openfl.FlxGlobalTween;

import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.display.StageDisplayState;
import openfl.display.Sprite;
import openfl.events.MouseEvent;

import lime.graphics.Image;

import haxe.MainLoop;

#if sys
import sys.FileSystem;
import sys.io.FileOutput;
#end

class PooledSprite extends Sprite implements IFlxDestroyable
{
	public function destroy()
	{
		graphics.clear();
		removeChildren();
	}
}

class ScreenPlugin extends flixel.FlxBasic
{
	public static var instance:ScreenPlugin;

	public var fullscreenKeys(default, set):Array<FlxKey> = [FlxKey.F11];
	public var enableToggleFullscreen:Bool = true;

	public var screenshotKeys(default, set):Array<FlxKey> = [FlxKey.F12];
	public var enableToggleScreenshot:Bool = true;

	public var outlineRadius:Int = 10;

	public var spawnPosition:FlxPoint = new FlxPoint(5, 5);

	inline function set_fullscreenKeys(v:Array<FlxKey>):Array<FlxKey>
		return filterKeys(fullscreenKeys = v);

	inline function set_screenshotKeys(v:Array<FlxKey>):Array<FlxKey>
		return filterKeys(screenshotKeys = v);

	@:noCompletion function filterKeys(keys:Array<FlxKey>):Array<FlxKey>
	{
		if (keys == null)
		{
			keys = [];
		}
		else
		{
			while (keys.remove(-1)) {}
		}
		return keys;
	}

	// var _timerManager:FlxTimerManager;
	var _poolSprites:FlxPool<PooledSprite>;

	public override function new():Void
	{
		#if !sys
		throw "The ScreenPlugin not supported on this platform."; // todo?
		#end
		super();

		if (instance != null)
		{
			destroy();
			return;
		}

		instance = this;
		// _timerManager = new FlxTimerManager();
		_poolSprites = new FlxPool<PooledSprite>(PooledSprite);
	}

	@:access(flixel.tweens.FlxTweenManager)
	// @:access(flixel.util.FlxTimerManager)
	public override function update(elapsed:Float)
	{
		if (enableToggleFullscreen && FlxG.keys.anyJustPressed(fullscreenKeys))
			fullscreen(!FlxG.fullscreen);
		if (enableToggleScreenshot && FlxG.keys.anyJustPressed(screenshotKeys))
			screenShotScreen();
		// if (_timerManager._timers.length > 0) _timerManager.update(elapsed);
		super.update(elapsed);
	}

	@:noCompletion var __oldPos:FlxRect = new FlxRect(FlxG.stage.application.window.x, FlxG.stage.application.window.y, FlxG.stage.application.window.width,
		FlxG.stage.application.window.height);

	// Fixed fullscreen
	public function fullscreen(toggle:Bool):Void
	{
		// if (FlxG.stage.application.window.resizable){
		@:privateAccess
		FlxG.stage.__displayState = toggle ? StageDisplayState.FULL_SCREEN : StageDisplayState.NORMAL;
		FlxG.stage.application.window.fullscreen = false;
		FlxG.stage.application.window.borderless = toggle;
		FlxG.stage.application.window.maximized = toggle;
		if (toggle)
		{
			__oldPos.set(FlxG.stage.application.window.x, FlxG.stage.application.window.y, FlxG.stage.application.window.width,
				FlxG.stage.application.window.height);
		}
		else
		{
			FlxG.stage.application.window.x = Std.int(__oldPos.x);
			FlxG.stage.application.window.y = Std.int(__oldPos.y);
			FlxG.stage.application.window.width = Std.int(__oldPos.width);
			FlxG.stage.application.window.height = Std.int(__oldPos.height);
		}
		// }
	}

	var _sound:FlxSound = new FlxSound();

	var _flashColor:Null<FlxColor>;

	public var saveFolder:String = "./screenshots";

	public function screenShotScreen(silent:Bool = false):Void
	{
		var path:String = haxe.io.Path.join([saveFolder,
			"scr-"
			+ DateTools.format(Date.now(), "%Y-%m-%d_%H-%M-%S-")
			+ Std.string(Math.ceil(haxe.Timer.stamp() * 1000) % 60).addEndZeros(2)
			+ '.png']);
		var image:Image = FlxG.stage.application.window.readPixels();

		showCaptureFeedback(silent);
		showFancyPreview(BitmapData.fromImage(image));
		MainLoop.addThread(() ->
		{
			#if sys
			if (FileSystem.exists(saveFolder))
			{
				if (!FileSystem.isDirectory(saveFolder))
				{
					FileSystem.deleteFile(saveFolder);
					FileSystem.createDirectory(saveFolder);
				}
			}
			else
			{
				FileSystem.createDirectory(saveFolder);
			}

			var f:FileOutput = sys.io.File.write(path, true);
			try
			{
				f.write(image.encode(PNG, ClientPrefs.lowQuality ? 50 : 100));
			}
			catch (e)
			{
				Log(e, RED);
			}
			f.close();
			#end
			MainLoop.runInMainThread(MemoryUtil.clearMajor);
		});
	}

	// SETTINGS
	static inline final CAMERA_FLASH_START_ALPHA:Float = 1.1;
	static inline final CAMERA_FLASH_DURATION:Float = 0.25;

	static inline final PREVIEW_INITIAL_DELAY:Float = 0.1; // How long before the preview starts fading in.
	static inline final PREVIEW_FADE_IN_DURATION:Float = 0.2; // How long the preview takes to fade in.
	static inline final PREVIEW_FADE_OUT_DELAY:Float = 1.25; // How long the preview stays on screen.
	static inline final PREVIEW_FADE_OUT_DURATION:Float = 0.3; // How long the preview takes to fade out.

	/**
	 * Visual and audio feedback when a screenshot is taken.
	 */
	function showCaptureFeedback(silent:Bool):Void
	{
		if (ClientPrefs.flashing)
		{
			var flashSprite:PooledSprite = _poolSprites.get();
			flashSprite.x = flashSprite.y = 0;
			flashSprite.visible = true;
			flashSprite.buttonMode = flashSprite.mouseEnabled = false;
			flashSprite.graphics.beginFill((_flashColor ?? FlxColor.WHITE).rgb, 1);
			flashSprite.graphics.drawRect(0, 0, 1, 1);
			flashSprite.graphics.endFill();
			flashSprite.scaleX = FlxG.scaleMode.gameSize.x + FlxG.scaleMode.offset.x * 2;
			flashSprite.scaleY = FlxG.scaleMode.gameSize.y + FlxG.scaleMode.offset.y * 2;
			flashSprite.alpha = CAMERA_FLASH_START_ALPHA;
			FlxG.stage.addChild(flashSprite);
			@:privateAccess
			FlxGlobalTween.num(CAMERA_FLASH_START_ALPHA, 0, CAMERA_FLASH_DURATION, {ease: FlxEase.quadOut, onComplete: _ -> {
				FlxG.stage.removeChild(flashSprite);
				_poolSprites.put(flashSprite);
			}}, flashSprite.set_alpha);
		}

		if (!silent)
		{
			var sound = Paths.sound('system/screenshot_take');
			if (sound != null)
			{
				FlxG.sound.list.add(_sound);
				_sound.loadEmbedded(sound);
				_sound.useTimeScaleToPitch = false;
				_sound.play();
				FlxG.sound.list.remove(_sound);
			}
		}
	}

	function showFancyPreview(bitmap:BitmapData):Void
	{
		// ermmm stealing this??
		// var wasMouseHidden = false;
		// if (!FlxG.mouse.visible)
		// {
		// 	wasMouseHidden = true;
		// 	Cursor.show();
		// }

		var scale:Float = 0.2;

		// used for movement + button stuff
		var previewSprite:PooledSprite = _poolSprites.get();
		var previewBitmap = new Bitmap(bitmap);
		var outlineWidth = outlineRadius * 2;
		previewBitmap.x = outlineRadius;
		previewBitmap.y = outlineRadius;
		previewBitmap.width -= outlineWidth;
		previewBitmap.height -= outlineWidth;
		previewSprite.visible = true;
		previewSprite.graphics.beginFill(0xFFFFFF, 0.9);
		previewSprite.graphics.drawRect(0, 0, bitmap.width + outlineRadius, bitmap.height + outlineRadius);
		previewSprite.graphics.endFill();
		previewSprite.addChild(previewBitmap);
		previewSprite.scaleX = scale / FlxG.scaleMode.scale.x;
		previewSprite.scaleY = scale / FlxG.scaleMode.scale.y;
		previewSprite.buttonMode = previewSprite.mouseEnabled = true;

		var onHover = (e:MouseEvent) -> previewBitmap.alpha = 0.6;
		var onHoverOut = (e:MouseEvent) -> previewBitmap.alpha = 1;
		var onHoverPress = (e:MouseEvent) -> {
			e.stopImmediatePropagation();
			CoolUtil.openFolder(saveFolder);
		}

		previewSprite.addEventListener(MouseEvent.MOUSE_DOWN, onHoverPress, false, 8);
		previewSprite.addEventListener(MouseEvent.MOUSE_OVER, onHover);
		previewSprite.addEventListener(MouseEvent.MOUSE_OUT, onHoverOut);

		FlxG.stage.addChild(previewSprite);

		previewSprite.alpha = 0.0;
		previewSprite.x = spawnPosition.x;
		previewSprite.y = spawnPosition.y - 10;

		// Fade in.
		FlxGlobalTween.tween(previewSprite, {alpha: 1.0, y: previewSprite.y + 10}, PREVIEW_FADE_IN_DURATION, {
			ease: FlxEase.quartOut,
			startDelay: PREVIEW_INITIAL_DELAY, // Wait to fade in.
			onComplete: _ ->
			{
				// Fade out.
				FlxGlobalTween.tween(previewSprite, {alpha: 0.0, y: previewSprite.y - 10}, PREVIEW_FADE_OUT_DURATION, {
					ease: FlxEase.quartInOut,
					startDelay: PREVIEW_FADE_OUT_DELAY, // Wait to fade out.
					onComplete: _ ->
					{
						// if (wasMouseHidden)
						// {
						// 	Cursor.hide();
						// }

						previewSprite.removeEventListener(MouseEvent.MOUSE_DOWN, onHoverPress);
						previewSprite.removeEventListener(MouseEvent.MOUSE_OVER, onHover);
						previewSprite.removeEventListener(MouseEvent.MOUSE_OUT, onHoverOut);

						previewSprite.visible = false;
						FlxG.stage.removeChild(previewSprite);
						previewSprite.alpha = 1.0;
						_poolSprites.put(previewSprite);
					}
				});
			}
		});
	}

	public override function destroy()
	{
		if (instance == this)
			instance = null;

		if (FlxG.plugins.list.contains(this))
			FlxG.plugins.remove(this);

		fullscreenKeys.clearArray();
		screenshotKeys.clearArray();
		_poolSprites.clear();
		_poolSprites = null;
		// _timerManager = FlxDestroyUtil.destroy(_timerManager);
		super.destroy();
	}
}
