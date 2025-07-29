package game.objects.openfl;

#if UPDATE_FEATURE
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;

import game.backend.data.EngineData;
import game.backend.system.net.Downloader;
import game.backend.system.net.GitHub;
import game.backend.utils.FileUtil;
import game.backend.utils.HttpUtil;

import thx.semver.Version;

import openfl.display.Sprite;
import openfl.events.Event;
import openfl.events.MouseEvent;
import openfl.geom.Point;
import openfl.geom.Rectangle;
import openfl.text.*;
import openfl.text._internal.TextFormatRange;

#if GLOBAL_SCRIPT
import game.backend.system.scripts.GlobalScript;
import game.backend.system.scripts.ScriptPack;
#end

#if cpp
import game.backend.utils.native.HiddenProcess;
#end

using DateTools;

@:access(openfl.text)
class UpdaterPopup extends Sprite
{
	// Эксперименты над репозом снейка, мухэхэхэ - Redar13
	public static inline final owner:String = "PurSnake";
	public static inline final repository:String = "Animania-Online";
	public static inline final branch:String = "dev";

	public static final gitHubUrlVersionFile:String = 'https://raw.githubusercontent.com/$owner/$repository/refs/heads/$branch/version.txt';
	public static final gitHubRepUrlReleases:String = 'https://api.github.com/repos/$owner/$repository/releases';
	public static final gitHubRepBuildFile:Null<String> = null;
	/*
	public static final gitHubRepBuildFile:Null<String> = MacroUtils.getFromMap(MacroUtils.platformName.toLowerCase(), [
		"windows" => "FunkinWindows",
		"linux" => "FunkinLinux",
		"android" => "FunkinAndroid",
	], "FunkinWindows");
	*/
	// public static final RELEASE_DATE_FORMAT:String = "yyyy-MM-dd'T'HH:mm:ss.SSSX";
	// public static final maxNextUpdateDate:String = Date.now().format(RELEASE_DATE_FORMAT);

	public static function init()
	{
		/*
		var eregFile = ~/\/([^\s\/]*.\w*)$/;
		var url = "https://github.com/ShadowMario/FNF-PsychEngine/releases/download/1.0.2h/PsychEngine-Windows64.zip";
		var ui:UpdaterPopup = new UpdaterPopup({
			url: url,
			title: "Халоу",
			description: "Это типо тест на робит (<font size = \"8\">или не робит</font>)\n скатчка абдейтов\nили\nдругих файлов для других компьютеров.",
			filePath: "./" + (eregFile.match(url) ? eregFile.matched(1) : gitHubRepBuildFile),
			totalSize: 0x7de39a9a
		});
		FlxG.stage.addChild(ui);
		return;
		*/


		var newLastVersion:Version = null;
		try
		{
			newLastVersion = HttpUtil.requestText(gitHubUrlVersionFile)?.trim() ?? null;
			if (newLastVersion == null)
			{
				throw new haxe.Exception("Invalid data");
			}
			trace('Last version: $newLastVersion');
			if (newLastVersion <= (EngineData.modVersion : Version))
			{
				throw new haxe.Exception("No need");
			}
		}
		catch(e:Int)
		{
			Log("Invalid getted version: " + newLastVersion, RED);
			Log("Request status: " + HttpUtil.prettyStatus(e), RED);
			return;
		}
		catch(e:String)
		{
			Log("Error while downloading update! Unable to get latest release files. Message: " + HttpUtil.prettyStatus(e), RED);
			return;
		}
		catch(e:Dynamic)
		{
			Log(Std.string(e), RED);
			// trace(e);
			return;
		}

		var releasesHttp = new haxe.Http(gitHubRepUrlReleases);
		/*
		var userAgent = "request";
		#if cpp
		var proc:HiddenProcess = null;
		try
		{
			// https://docs.github.com/ru/rest/using-the-rest-api/getting-started-with-the-rest-api?apiVersion=2022-11-28#rate-limiting
			proc = new HiddenProcess("git", ["config", "--global", "user.name"]);
			var output = proc.stdout.readAll().toString().trim();
			trace(output, userAgent);
			if (output.length != 0)
				userAgent = output;
		}
		catch(e)
		{
			Log(e, RED);
		}
		proc?.close();
		#end
		*/
		releasesHttp.setHeader("User-Agent", HttpUtil.userAgent);
		releasesHttp.onData = function(data:String)
		{
			try
			{
				var latestRelease:GitHubRelease = cast haxe.Json.parse(data)[0];
				if (latestRelease == null)
				{
					Log("Error while downloading update! Latest release data is null", RED);
					return;
				}

				// trace(latestRelease);
				var buildAsset:Null<GitHubAsset> = null;
				if (gitHubRepBuildFile != null)
					for (asset in latestRelease.assets)
					{
						if (asset.name == gitHubRepBuildFile)
						{
							// for (i in Reflect.fields(asset))
							// 	trace(i + ": " + Reflect.field(asset, i));
							buildAsset = asset;
							break;
						}
					}

				if (buildAsset == null || buildAsset.browser_download_url == null)
				{
					trace("Unable to get a specific release! Taking the first random release.");
					buildAsset = latestRelease.assets[0];
				}
				if (buildAsset == null || buildAsset.browser_download_url == null)
				{
					Log("Error while downloading update! Unable to get download url", RED);
					return;
				}

				FlxG.signals.preUpdate.addOnce(onFounded.bind(buildAsset));
				// FlxG.signals.preUpdate.addOnce(() -> {
				// 	var url = buildAsset.browser_download_url;
				// 	var eregFile = ~/\/([^\s\/]*.\w*)$/;
				// 	var ui = new UpdaterPopup({
				// 		url: url,
				// 		title: null,
				// 		description: null,
				// 		filePath: "./" + (eregFile.match(url) ? eregFile.matched(1) : gitHubRepBuildFile),
				// 		totalSize: buildAsset.size,
				// 		gitHubAsset: buildAsset,
				// 	});
				// 	FlxG.stage.addChild(ui);
				// });
			}
			catch(e)
			{
				trace(e);
			}
		}
		releasesHttp.onError = function(msg:String)
		{
			Log("Error while downloading update! Unable to get latest release files. Message: " + HttpUtil.prettyStatus(msg), RED);
		}
		releasesHttp.request(false);
	}

	public static function onFounded(buildAsset:GitHubAsset) {
		#if GLOBAL_SCRIPT
		if (ScriptPack.resultIsStop(GlobalScript.call("onFoundedUpdate", [buildAsset])))
		{
			return;
		}
		#end
		var url = buildAsset.browser_download_url;
		var eregFile = ~/\/([^\s\/]*.\w*)$/;
		var ui = new UpdaterPopup({
			url: url,
			title: null,
			description: null,
			filePath: "./" + (eregFile.match(url) ? eregFile.matched(1) : gitHubRepBuildFile),
			totalSize: buildAsset.size,
			gitHubAsset: buildAsset,
		});
		FlxG.stage.addChild(ui);
	}

	var titleText:TextField;
	var descriptionText:TextField;
	var acceptText:TextButton;
	var declineText:TextButton;
	@:noCompletion var _enableButtons:Bool = true;
	@:noCompletion var _dirtyBGDraw:Bool = true;

	var baseWidth:UInt = 284;
	var baseHeight:UInt = 100;
	var buttonsHeight:UInt = 30;
	var linesSize:UInt = 2;

	var textPadding:UInt = 15;

	public var totalSize:UInt = 0;
	public var url:String = null;
	public var filePath:String = null;
	public var gitHubAsset:GitHubAsset = null;

	// var _tweenManager:FlxTweenManager = new FlxTweenManager();

	public static function formatTextByStruct(txt:String, extraStruct:Dynamic):String
	{
		// txt = txt.replace("$SIZE", instance.totalSize.formatBytes()).replace("$URL", instance.url).replace("$PATH", instance.filePath);
		for (i in Reflect.fields(extraStruct))
		{
			var key = "$" + i.toUpperCase();
			if (txt.indexOf(key) != -1)
				txt = txt.replace(key, Reflect.field(extraStruct, i));
		}
		return txt;
	}

	public function formatText(txt:String):String {
		txt = formatTextByStruct(txt, {
			size: totalSize.formatBytes(),
			url: url,
			path: filePath,
		});
		if (gitHubAsset != null)
		{
			txt = formatTextByStruct(txt, gitHubAsset);
		}

		return txt;
	}

	public function new(data:{
		url:String,
		filePath:String,
		?title:String,
		?description:String,
		?totalSize:UInt,
		?gitHubAsset:GitHubAsset
	})
	{
		url = data.url;
		filePath = data.filePath;
		totalSize = data.totalSize ?? 0;
		gitHubAsset = data.gitHubAsset;

		// FlxG.signals.preStateSwitch.remove(_tweenManager.clear);

		titleText = setupCenterTextField(formatText(data.title ?? "Hey!"), 16);

		descriptionText = setupCenterTextField();
		descriptionText.__styleSheet = new StyleSheet();
		descriptionText.__styleSheet.__styles.set("bold-format1", {
			fontSize: descriptionText.defaultTextFormat.size + 3
		});
		descriptionText.text = formatText(data.description ??  "Wouldn't you like to download\ngarbage content?\n<bold-format1>File size: $SIZE</bold-format1>");
		descriptionText.wordWrap = true;

		descriptionText.width = Math.floor(baseWidth - textPadding * 2.0);

		// trace(baseHeight, titleText.y + titleText.height + descriptionText.height + textPadding * 3.0);
		baseHeight = Std.int(Math.max(baseHeight, titleText.y + titleText.height + descriptionText.height + textPadding * 3.0));
		// trace(baseHeight);

		descriptionText.y = Math.max(baseHeight - buttonsHeight - descriptionText.height - textPadding / 2.0, titleText.y + titleText.height + textPadding / 4.0);

		declineText = new TextButton(baseWidth / 2, buttonsHeight, "Decline", 0xFFFFFFFF, () ->
		{
			if (!_enableButtons) return;
			trace("Decline");
			dispose();
		});
		acceptText = new TextButton(baseWidth / 2, buttonsHeight, "Accept", 0xFFFFFFFF, () ->
		{
			if (!_enableButtons) return;

			trace("Accept");

			_enableButtons = false;

			var oldAutoPause = FlxG.autoPause;
			FlxG.autoPause = true; // trying to stop game

			FileUtil.browseForSaveFile([FileUtil.FILE_FILTER_ZIP],
				path -> {
					dispose();
					Main.fpsVar.addDowloaderUI(Downloader.downloadFileFromUrl(url, path));
					FlxG.autoPause = oldAutoPause;
				},
				() -> {
					_enableButtons = true;
					FlxG.autoPause = oldAutoPause;
				},
				filePath,
				'Install New Build'
			);
		});
		acceptText.x += acceptText.baseWidth;
		declineText.y = acceptText.y = baseHeight - buttonsHeight;

		super();

		if (FlxG.stage != null)
		{
			FlxG.stage.addEventListener(Event.RESIZE, onResize);
			__oldStageWidth = FlxG.stage.stageWidth;
			__oldStageHeight = FlxG.stage.stageHeight;
		}

		addChild(titleText);
		addChild(descriptionText);
		addChild(declineText);
		addChild(acceptText);

		x = (__oldStageWidth - width) / 2.0;

		alpha = 0.95;

		buttonMode = true;
		useHandCursor = false;
		addEventListener(MouseEvent.MOUSE_DOWN, onHoverPress, false, 8);
		addEventListener(MouseEvent.MOUSE_UP, onHoverOut, false, 8);

		// scaleY = 0;
		// FlxG.signals.postStateSwitch.addOnce(() -> {
		// 	_tweenManager.num(scaleY, 1, 4, {ease:FlxEase.cubeInOut}, set_scaleY);
		// });
	}

	function onHoverPress(event:MouseEvent)
	{
		startDrag(false, null);
		updateDragBounds();

		event.stopPropagation();
		event.preventDefault();
	}
	function onHoverOut(event:MouseEvent)
	{
		stopDrag();

		event.stopPropagation();
		event.preventDefault();
	}

	@:noCompletion var __oldStageWidth:Float = 0;
	@:noCompletion var __oldStageHeight:Float = 0;
	function onResize(_)
	{
		var _stage = FlxG.stage;
		var scaleFactorX = __oldStageWidth == 0 ? 1 : _stage.stageWidth / __oldStageWidth;
		var scaleFactorY = __oldStageHeight == 0 ? 1 : _stage.stageHeight / __oldStageHeight;
		// x -= width * (scaleFactorX - 1.0);
		// y -= height * (scaleFactorY - 1.0);
		x *= scaleFactorX;
		y *= scaleFactorY;
		updateDragBounds();
		__oldStageWidth = _stage.stageWidth;
		__oldStageHeight = _stage.stageHeight;
	}

	@:access(openfl.display.Stage)
	@:access(openfl.geom.Matrix)
	function updateDragBounds()
	{
		if (stage == null /* || stage.__dragObject != this*/ ) return;

		var __dragBounds:Rectangle = new Rectangle(
			-baseWidth / 2, -(baseHeight - buttonsHeight) / 2,
			Math.max(stage.stageWidth, 0.0),
			Math.max(stage.stageHeight, 0.0)
		);
		stage.__dragBounds = __dragBounds;

		if (__dragBounds != null)
		{
			var _x = this.x;
			var _y = this.y;

			if (_x < __dragBounds.x)
			{
				this.x = __dragBounds.x;
			}
			else if (_x > __dragBounds.width)
			{
				this.x = __dragBounds.width;
			}

			if (_y < __dragBounds.y)
			{
				this.y = __dragBounds.y;
			}
			else if (_y > __dragBounds.height)
			{
				this.y = __dragBounds.height;
			}
		}
	}

	function setupCenterTextField(txt:String = "", size:UInt = 12):TextField
	{
		var textField = new TextField();
		textField.selectable = textField.mouseEnabled = false;
		textField.removeEventListeners();
		textField.multiline = textField.embedFonts = true;
		textField.defaultTextFormat = new TextFormat(Assets.getFont(AssetsPaths.font("VCR OSD Mono Cyr.ttf"))?.fontName ?? flixel.system.FlxAssets.FONT_DEFAULT,
			size, 0xEEEEEE);
		textField.text = txt;
		textField.autoSize = CENTER;
		textField.__textFormat.align = CENTER;
		textField.x = textPadding;
		textField.y = textPadding / 4;
		textField.width = baseWidth - textField.x * 2;

		return textField;
	}

	// Event Handlers

	@:noCompletion
	override function __enterFrame(deltaTime:Int):Void
	{
		// _tweenManager.update(deltaTime / 1000);
		renderBG();
		super.__enterFrame(deltaTime);
		FlxG.mouse.visible = FlxG.mouse.useSystemCursor = true;
	}

	public function dispose()
	{
		if (FlxG.stage.focus == this)
		{
			FlxG.stage.focus = null;
		}

		parent.removeChild(this);

		// _tweenManager?.destroy();
		declineText?.dispose();
		acceptText?.dispose();
		// _tweenManager = null;
		declineText = null;
		acceptText = null;
		removeEventListener(MouseEvent.MOUSE_DOWN, onHoverPress);
		removeEventListener(MouseEvent.MOUSE_UP, onHoverOut);
		if (FlxG.stage != null)
		{
			FlxG.stage.removeEventListener(Event.RESIZE, onResize);
		}
		FlxG.mouse.useSystemCursor = ClientPrefs.sysMouse;
	}

	function renderBG()
	{
		if (!_dirtyBGDraw)
			return;

		graphics.clear();
		graphics.beginFill(0x333333);
		graphics.drawRect(0, 0, baseWidth, baseHeight);
		graphics.endFill();
		graphics.beginFill(0xFFFFFF, 0.48);
		graphics.drawRect(0, baseHeight - buttonsHeight - linesSize / 2, baseWidth, linesSize);
		graphics.drawRect(baseWidth / 2 - linesSize / 2, baseHeight - buttonsHeight + linesSize / 2, linesSize, buttonsHeight - linesSize / 2);
		graphics.endFill();

		_dirtyBGDraw = false;
	}
}

class TextButton extends Sprite
{
	public var bgColor:FlxColor;
	public var callback:Void->Void;
	public var textField:TextField;
	public var selected(default, null):Bool = false;
	public var baseWidth:Float;
	public var baseHeight:Float;

	public function new(width:Float, height:Float, txt:String, bgColor:FlxColor = 0xffffffff, ?callback:Void->Void)
	{
		super();

		baseWidth = width;
		baseHeight = height;

		this.callback = callback;

		buttonMode = mouseEnabled = true;

		textField = new TextField();
		textField.selectable = textField.mouseEnabled = false;
		textField.removeEventListeners();
		textField.defaultTextFormat = new TextFormat(Assets.getFont(AssetsPaths.font("VCR OSD Mono Cyr.ttf"))?.fontName ?? flixel.system.FlxAssets.FONT_DEFAULT,
			16, 0xFFFFFF);
		textField.text = txt;
		textField.autoSize = LEFT;
		addChild(textField);

		addEventListener(MouseEvent.MOUSE_DOWN, onHoverPress, false, 9);
		addEventListener(MouseEvent.MOUSE_OVER, onHover, false, 9);
		addEventListener(MouseEvent.MOUSE_OUT, onHoverOut, false, 9);

		this.bgColor = bgColor;
	}

	public function renderGraphics()
	{
		graphics.clear();
		graphics.beginFill(bgColor.rgb, bgColor.alphaFloat * 0.1 * _selectFactor);
		graphics.drawRect(0, 0, baseWidth, baseHeight);
		graphics.endFill();
		@:privateAccess
		graphics.__visible = true;
	}

	@:noCompletion var _selectFactor:Float = 0;

	@:noCompletion private override function __enterFrame(deltaTime:Int):Void
	{
		_selectFactor = CoolUtil.fpsLerp(_selectFactor, Std.int(cast selected), 0.25, deltaTime / 1000);
		textField.scaleX = textField.scaleY = 1.0 + _selectFactor * 0.1;
		renderGraphics();
		textField.x = (width - textField.width) / 2.0;
		textField.y = (height - textField.height) / 2.0;

		super.__enterFrame(deltaTime);
	}

	public function dispose()
	{
		if (FlxG.stage.focus == this)
		{
			FlxG.stage.focus = null;
		}
		selected = false;
		removeEventListener(MouseEvent.MOUSE_DOWN, onHoverPress);
		removeEventListener(MouseEvent.MOUSE_OVER, onHover);
		removeEventListener(MouseEvent.MOUSE_OUT, onHoverOut);
	}

	function onHover(event:MouseEvent)
	{
		event.stopPropagation();
		event.preventDefault();
		selected = true;
	}

	function onHoverOut(event:MouseEvent)
	{
		event.stopPropagation();
		event.preventDefault();
		selected = false;
	}

	function onHoverPress(event:MouseEvent)
	{
		event.stopPropagation();
		event.preventDefault();
		if (callback == null)
			return;
		callback();
	}
}
#end
