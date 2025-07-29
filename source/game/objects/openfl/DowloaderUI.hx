package game.objects.openfl;

#if UPDATE_FEATURE
import flixel.tweens.FlxEase;
import flixel.util.FlxTimer;

import game.FPS;
import game.backend.system.net.Downloader;
import game.objects.openfl.FlxGlobalTween;
import game.objects.openfl.FlxGlobalTimer;

import openfl.display.DisplayObject;
import openfl.display.DisplayObjectContainer;
import openfl.display.Graphics;
import openfl.display.Sprite;
import openfl.events.MouseEvent;
import openfl.geom.Point;
import openfl.geom.Rectangle;
import openfl.text.TextField;
import openfl.text.TextFormat;

class DowloaderUI extends DisplayObjectContainer {

	var backend:Downloader;

	var progressBar:Sprite;
	var statusText:TextField;
	var cancelText:TextField;
	var percentText:TextField;
	var toggleDisplayPercent:Bool = true;
	var pathText:TextField;
	var barColor:FlxColor = FlxColor.WHITE;

	var lastAlignment:FPSAligh = 0;

	var displayPath:String;
	var dowlSpeed:Int = 0;
	var updateStatusText:Bool = true;

	var timer:FlxTimer = null;

	public function new(dowloader:Downloader)
	{
		backend = dowloader;

		displayPath = dowloader.outputFilePath;

		var maxLength:Int = 48;
		if (CoolUtil.detectRecordingPrograms() && !displayPath.contains("./")) // to prevent a stream, or a recording, from being shown to the public
		{
			var fag = displayPath.split("/");
			for (i in 0...fag.length - 1)
			{
				fag[i] = "".rpad("#", fag[i].length);
			}
			displayPath = fag.join("/");

			maxLength = displayPath.lastIndexOf("/") - 14;
		}

		if (displayPath.length > maxLength)
		{
			displayPath = "..." + displayPath.substring(displayPath.lastIndexOf("/", displayPath.length - maxLength) + 1, displayPath.length);
		}

		statusText = setupTextField();
		statusText.text = "Dowload shit";

		cancelText = setupTextField(16);
		cancelText.text = "Cancel?";
		@:privateAccess
		cancelText.__textFormat.align = CENTER;
		cancelText.autoSize = CENTER;
		cancelText.alpha = 0.0;
		cancelText.textColor = 0xFB4E4E;

		percentText = setupTextField(null, _ -> {
			toggleDisplayPercent = !toggleDisplayPercent;
		}, _ -> {
			percentText.alpha = 0.7;
		}, _ -> {
			percentText.alpha = 1.0;
		});

		var dirToOp = haxe.io.Path.directory(backend.outputFilePath);
		pathText = setupTextField(10, _ -> {
			CoolUtil.openFolder(dirToOp);
			if (timer != null)
				timer.reset(timer.timeLeft / 2.5);
		}, _ -> {
			pathText.alpha = 0.7;
		}, _ -> {
			pathText.alpha = 1.0;
		});
		pathText.text = displayPath;

		var alphaTextTween:flixel.tweens.FlxTween = null;
		progressBar = new Sprite();
		addMouseEventsToObj(progressBar, _ -> {
			if (backend.isConnected && !backend.cancelRequested)
				backend.cancel();

		}, _ -> {
			var percent:Float = 1.0;
			if (alphaTextTween != null)
			{
				percent = alphaTextTween.percent;
				alphaTextTween.cancel();
			}
			alphaTextTween = FlxGlobalTween.num(
				cancelText.alpha,
				((backend.isCompleted || backend.cancelRequested) ? 0.0 : 1.0),
				1.2 * percent,
				{
					onComplete:_ -> alphaTextTween = null
				},
				cancelText.set_alpha
			);
		}, _ -> {
			var percent:Float = 1.0;
			if (alphaTextTween != null)
			{
				percent = alphaTextTween.percent;
				alphaTextTween.cancel();
			}
			alphaTextTween = FlxGlobalTween.num(
				cancelText.alpha,
				0.0,
				0.25 * percent,
				{
					onComplete:_ -> alphaTextTween = null
				},
				cancelText.set_alpha
			);
		});

		super();

		mouseEnabled = true;
		__drawableType = SPRITE;

		addChild(progressBar);
		addChild(statusText);
		addChild(percentText);
		addChild(pathText);
		addChild(cancelText);

		Main.fpsVar.onUpdatePosition.add(updatePositions);
		updatePositions(Main.fpsVar.alignment);
		updateProgressBar();
		backend.onCompleted.add(onCompleted);
		backend.onCanceled.add(onCompleted);

		/*
		var __lastBytes:Int = 0;
		var __lastTime:Float = 0.0;

		backend.onProgress.add(() -> {
			@:privateAccess
			var time:Float = FlxG.game.getTimer();

			var deltaB:Int = backend.gotContent - __lastBytes;
			var deltaT:Float = time - __lastTime;

			__lastBytes = backend.gotContent;
			__lastTime = time;

			if (backend.gotContent != backend.contentLength)
				dowlSpeed = Math.floor(deltaB / deltaT);
		});
		*/

		/*
		backend.onCompleted.add(updateProgressBar);
		backend.onProgress.add(updateProgressBar);
		backend.onCanceled.add(updateProgressBar);
		*/
	}

	public function updateProgressBar()
	{
		var percent:Float = backend.contentLength == 0 ? 0 : backend.gotContent / backend.contentLength;

		var barWidth:UInt = 180;
		var barHeight:UInt = 20;
		// var barHeight:UInt = Std.int(Math.abs(percentText.height)) + 2;

		var graphics:Graphics = progressBar.graphics;
		graphics.clear();
		graphics.beginFill(0x000000, 0.5);
		graphics.drawRect(0, 0, barWidth, barHeight);
		graphics.endFill();
		if (percent > 0.0)
		{
			graphics.beginFill(barColor.rgb, barColor.alphaFloat);
			graphics.drawRect((lastAlignment.RIGHT ? barWidth * (1.0 - percent) : 0), 0, barWidth * percent, barHeight);
			graphics.endFill();
		}

		if (updateStatusText)
		{
			var status:String;
			if (backend.isCompleted)
			{
				status = "Completed";
			}
			else if (backend.cancelRequested && !backend.isConnected)
			{
				status = "Cancelled";
			}
			else
			{
				status = backend.cancelRequested ? "Canceling" : backend.isDownloading ? "Dowloading" : "Connecting";
				status = status.rpad(".", status.length + 1 + Math.floor((FlxG.game.ticks / 400) % 3));
			}
			statusText.text = status;
		}

		percentText.text = backend.isDownloading ? (
				toggleDisplayPercent ?
					Std.string(Math.round(percent * 100)) + "%"
				:
					backend.gotContent.formatBytes() + "/" + backend.contentLength.formatBytes()
			) : "";
		// percentText.text += "\n(" + dowlSpeed.formatBytes() + ")";
		percentText.y = progressBar.y + (progressBar.height - percentText.height) / 2.0;

		progressBar.y = statusText.height + 2;
		pathText.y = progressBar.y + progressBar.height + 4;
		cancelText.y = progressBar.y + (progressBar.height - cancelText.height) / 2.0;

		if (lastAlignment.RIGHT)
		{
			for (i in __children)
			{
				i.x = -i.width;
			}
			// progressBar.x += _barTextOffsetX * 1600.0;
			// statusText.x += _statusTextOffsetX * 1600.0;
			percentText.x = progressBar.x - percentText.width - 2;
		}
		else
		{
			for (i in __children)
			{
				i.x = 0;
			}
			// progressBar.x -= _barTextOffsetX * 1600.0;
			// statusText.x -= _statusTextOffsetX * 1600.0;
			percentText.x = progressBar.x + barWidth + 2;
		}
		cancelText.x = progressBar.x;
		cancelText.width = progressBar.width;
		// cancelText.scaleX = progressBar.scaleX;
		// cancelText.scaleY = progressBar.scaleY;
	}

	function setupTextField(?size:Null<Int>, ?onClick:MouseEvent->Void, ?onOver:MouseEvent->Void, ?onOut:MouseEvent->Void)
	{
		size ??= 12;
		var txt = new TextField();
		txt.mouseEnabled = onClick != null || onOver != null;
		addMouseEventsToObj(txt, onClick, onOver, onOut);
		txt.selectable = false;
		txt.defaultTextFormat = new TextFormat(Assets.getFont(
			AssetsPaths.font("VCR OSD Mono Cyr.ttf")
		)?.fontName ?? flixel.system.FlxAssets.FONT_DEFAULT, 12, 0xEEEEEE);
		txt.autoSize = LEFT;
		return txt;
	}

	static function addMouseEventsToObj(obj:openfl.display.DisplayObject, ?onClick:MouseEvent->Void, ?onOver:MouseEvent->Void, ?onOut:MouseEvent->Void)
	{
		if (onClick != null)
		{
			obj.addEventListener(MouseEvent.MOUSE_DOWN, event -> {
				onClick(event);
				event.stopPropagation();
			});
		}
		if (onOver != null)
		{
			obj.addEventListener(MouseEvent.MOUSE_OVER, onOver);
		}
		if (onOut != null)
		{
			obj.addEventListener(MouseEvent.MOUSE_OUT, onOut);
		}
	}

	function updatePositions(alig:FPSAligh) {
		lastAlignment = alig;
	}

	@:noCompletion private override function __enterFrame(deltaTime:Int):Void
	{
		updateProgressBar();

		super.__enterFrame(deltaTime);

		FlxG.mouse.visible = FlxG.mouse.useSystemCursor = true;
	}

	// @:noCompletion var _barTextOffsetX:Float = 0;
	// @:noCompletion var _statusTextOffsetX:Float = 0;
	function onCompleted() {
		removeChildren();
		addChild(progressBar);
		addChild(statusText);
		addChild(pathText);

		var origCol:FlxColor = ((backend.cancelRequested ? 0xFFEE1B1B : 0xFF64EB1C) : FlxColor).getDarkened(0.1);
		var startCol:FlxColor = origCol.getLightened(0.3);
		var func = FlxColor.interpolate.bind(startCol, origCol, _);
		barColor = startCol;
		FlxGlobalTween.num(0, 1, 4.0, {ease: FlxEase.quadInOut}, i -> barColor = func(i));
		/*
		FlxGlobalTween.num(0, 1, 1.5, {
			ease: FlxEase.quadIn,
			startDelay: 5.0,
			onComplete: _ -> {
				progressBar.scaleX = progressBar.scaleY = 0;
			}
		}, i -> _barTextOffsetX = i);
		FlxGlobalTween.num(0, 1, 1.5, {
			ease: FlxEase.quadIn,
			startDelay: 5.0 + 1.0,
			onComplete: _ -> {
				statusText.scaleX = statusText.scaleY = 0;
				dispose();
			}
		}, i -> _statusTextOffsetX = i);
		*/

		var startTime:Float = backend.cancelRequested ? 30.0 : 60.0;

		timer = new FlxTimer(FlxGlobalTimer.globalManager);
		timer.start(startTime, _ -> {
			timer = null;
			// var totalWidthBar = progressBar.width;
			// var totalHeightBar = progressBar.height;
			// var rect = new Rectangle();
			var dePathText = pathText.text;
			FlxGlobalTween.num(1, 0, 1.7, {
				// ease: FlxEase.quadIn,
			}, i -> {
				pathText.text = dePathText.substring(0, Math.floor(dePathText.length * i));
			});

			var totalScaleYtBar = progressBar.scaleY;
			FlxGlobalTween.num(1, 0, 1.3, {
				ease: FlxEase.smootherStepIn,
				startDelay: 0.6,
				onComplete: _ -> {
					removeChild(progressBar);
				}
			}, i -> {
				// rect.setTo(0, 0, totalWidthBar * i, totalHeightBar * i * 2.0);
				// if (lastAlignment.RIGHT)
				// 	rect.x = totalWidthBar - rect.width;
				// progressBar.scrollRect = rect;
				progressBar.scaleY = totalScaleYtBar * i;
			});

			var deStatusText = statusText.text;
			FlxGlobalTween.num(1, 0, 1.7, {
				// ease: FlxEase.quadIn,
				startDelay: 0.9,
				onStart: _ -> {
					updateStatusText = false;
				},
				onComplete: _ -> {
					dispose();
				}
			}, i -> {
				statusText.text = deStatusText.substring(0, Math.floor(deStatusText.length * i));
			});
		});
		/*
		FlxGlobalTween.tween(progressBar, {scaleY: 0}, 2.0, {
			ease: FlxEase.quadIn,
			startDelay: 5.0
		});
		FlxGlobalTween.tween(statusText, {scaleY: 0}, 2.0, {
			ease: FlxEase.quadIn,
			startDelay: 5.0 + 1.5,
			onComplete: _ -> {
				dispose();
			}
		});
		*/
	}

	public function dispose()
	{
		if (parent != null)
			parent.removeChild(this);
		if (backend != null)
			backend = flixel.util.FlxDestroyUtil.destroy(backend);
		Main.fpsVar?.onUpdatePosition?.remove(updatePositions);
		FlxG.mouse.useSystemCursor = ClientPrefs.sysMouse;
	}
}
#end