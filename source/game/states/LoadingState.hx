package game.states;

import flixel.FlxCamera;
import flixel.addons.transition.FlxTransitionableState;
import flixel.math.FlxMath;
import flixel.math.FlxPoint.FlxBasePoint;
import flixel.util.typeLimit.NextState;

import game.backend.data.jsons.StageData;
import game.backend.system.song.Song;
import game.backend.system.states.MusicBeatSubstate;
import game.backend.utils.MemoryUtil;
import game.backend.utils.PathUtil;
import game.backend.utils.ThreadUtil;
import game.objects.game.Character;
import game.objects.game.notes.Note.EventNote;
import game.objects.improvedFlixel.FlxFixedText;
import game.states.playstate.PlayState;

import haxe.Json;
import haxe.PosInfos;

import lime.app.Future;

// #if sys
// import sys.FileSystem;
// #end

#if target.threaded
import sys.thread.Mutex;
import sys.thread.Lock;
#end

#if VIDEOS_ALLOWED
import game.objects.VideoSprite;
import hxvlc.externs.Types;
import hxvlc.flixel.FlxInternalVideo;
import hxvlc.openfl.Video;
#end

using Lambda;

typedef LoadingStateCallback = Null<LoadingState> -> Void;

@:access(flixel.system.frontEnds.BitmapFrontEnd)
class LoadingState extends MusicBeatSubstate
{
	public static inline function loadAndSwitchState(target:FlxState, intrusive = true, funcsPrepare:Array<LoadingStateCallback> = null)
	{
		MusicBeatState.switchState(getNextState(target, intrusive, funcsPrepare));
	}

	static inline function getNextState(target:FlxState, intrusive:Bool = true, funcsPrepare:Array<LoadingStateCallback> = null):FlxState
	{
		#if MULTI_THREADING_ALLOWED
		return intrusive ? new LoadingState(funcsPrepare, _ -> MusicBeatState.switchState(target)) : target;
		#else
		return target;
		#end
	}

	public function new(postFuncsPrepare:Array<LoadingStateCallback> = null, onComplete:LoadingStateCallback)
	{
		Main.canClearMem = false;
		#if target.threaded
		@:privateAccess
		FlxBasePoint._mutex = new Mutex();
		#end
		// this.target = target;
		this.onComplete = onComplete;

		if (postFuncsPrepare != null)
		{
			var len = funcsPrepare.length;
			funcsPrepare.resize(funcsPrepare.length + postFuncsPrepare.length);
			for (i in postFuncsPrepare)
				funcsPrepare[len++] = i;
		}
		super();
	}

	public var maxThreadsAllowed:Int = 1; // ?TODO: Support interpolation of an asset into the game under multiple threads

	public var startedLoading:Bool = false;
	public var canLeave:Bool = false;
	public var onComplete:LoadingStateCallback;
	public var funcsPrepare:Array<LoadingStateCallback> = [];

	public var callbacks:MultiCallback = null;
	public var stopMusic:Bool = false;

	var dirtyUpdateGraphics:Bool = false;

	var preLoadedGraphicsKeys:Array<String>;
	var oldGPUCacheAllowed:Bool = false;

	override function create()
	{
		super.create();
		oldGPUCacheAllowed = ClientPrefs.cacheOnGPU;
		if (script == null)
		{
			FlxG.signals.preUpdate.addOnce(onComplete.bind(this));
			return;
		}

		add(callbacks = new MultiCallback(onLoaded, onProgress, "Loading Screen"));

		preLoadedGraphicsKeys = [for (i in FlxG.bitmap._cache.keys()) i];
		call("createPost");
		ClientPrefs.cacheOnGPU = false;
		startedLoading = true;
		if (funcsPrepare.length == 0)
			preparePlayState();
	}

	override function destroy()
	{
		super.destroy();
		#if target.threaded
		@:privateAccess
		FlxBasePoint._mutex = null;
		#end
		ClientPrefs.cacheOnGPU = oldGPUCacheAllowed;
	}

	var currentUsedThread:Int = 0;

	public override function update(elapsed:Float)
	{
		if (dirtyUpdateGraphics && currentUsedThread == 0)
		{
			ClientPrefs.cacheOnGPU = oldGPUCacheAllowed;
			// FlxG.camera.visible = false;
			// trace('$preLoadedGraphicsKeys -> ${[for (i in FlxG.bitmap._cache.keys()) i]}');
			for (i in FlxG.bitmap._cache.keys())
			{
				if (preLoadedGraphicsKeys.contains(i) || !i.startsWith(AssetsPaths.FLXGRAPHIC_PREFIXKEY /*+ "assets/"*/))
					continue;
				if (Paths.connectBitmap(FlxG.bitmap._cache.get(i), i, true, false) != null)
				{
					Log('Finished preloading image \'$i\'', GREEN);
				}
				else
				{
					Log('Failed to cache image \'$i\'', RED);
				}
			}
			preLoadedGraphicsKeys = [for (i in FlxG.bitmap._cache.keys()) i];
			ClientPrefs.cacheOnGPU = false;
			dirtyUpdateGraphics = false;
			if (oldGPUCacheAllowed)
			{
				MemoryUtil.clearMajor();
			}
		}
		if (startedLoading)
		{
			while (funcsPrepare.length > 0 && currentUsedThread < maxThreadsAllowed)
			{
				var i = funcsPrepare.shift();
				if (i == null) continue;
				currentUsedThread++;

				var asyncLoader = new Future<Int>(() -> {
					i(this);
					return 0;
				}, true);
				asyncLoader.onComplete(_ -> {
					currentUsedThread--;
					dirtyUpdateGraphics = true;
				});
				asyncLoader.onError(_ ->
				{
					Log('Failed load assets: ${asyncLoader.error}', RED);
				});

				/*
				haxe.MainLoop.addThread(() -> {
					i(this);
					currentUsedThread--;
					dirtyUpdateGraphics = true;
				});
				*/
			}
		}
		super.update(elapsed);
	}

	function onProgress(loaded:Int, ?length:Null<Int>)
	{
		call("onProgress", [loaded, length]);
	}

	function onLoaded()
	{
		call("onLoaded");
	}

	var transitioning:Bool = false;

	public function preparePlayState()
	{
		trace("Start loading data files");
		final SONG = PlayState.SONG;

		funcsPrepare.push(state -> {
			loadCoolListFile(AssetsPaths.getPath('data/globalPreloadList.txt'), (?data) -> {
				loadPreloadList(data);
			});
		});
		funcsPrepare.push(state -> {
			loadCharacter(SONG.player1);
			loadCharacter(SONG.player2);
			loadJson(AssetsPaths.getPath('stages/' + SONG.stage + '.json'), (?stageData) -> {
				if (stageData == null) return;
				if (!stageData.hide_girlfriend)
					loadCharacter(SONG.gfVersion);

				loadPreloadList(stageData.preloadList);
			});
		});
		funcsPrepare.push(state -> {
			loadCoolListFile(AssetsPaths.getPath(Constants.SONG_CHART_FILES_FOLDER
				+ "/" + Paths.formatToSongPath(SONG.song)
				+ "/preloadList.txt"), (?data) -> {
				loadPreloadList(data);
			});
		});
		funcsPrepare.push(state -> {
			var eventsJson = Song.loadFromJson('events', SONG.song);
			if (eventsJson != null)
			{
				for (event in eventsJson.events) //Event Notes
					for (i in 0...event[1].length)
						makeEvent(event, i);
			}
			for (event in SONG.events)
				for (i in 0...event[1].length)
					makeEvent(event, i);
		});
		funcsPrepare.push(state -> {
			loadImage((PlayState.SONG.splashSkin != null && PlayState.SONG.splashSkin.length > 0) ?
			PlayState.SONG.splashSkin : Constants.DEFAULT_NOTESPLASH_SKIN);
			loadImage((PlayState.SONG.arrowSkin != null && PlayState.SONG.arrowSkin.length > 0) ?
			PlayState.SONG.arrowSkin : Constants.DEFAULT_NOTE_SKIN);

			loadSoundAlt(AssetsPaths.inst(SONG.song, SONG.postfix));
			loadSoundAlt(AssetsPaths.voices(SONG.song, 'Voices' + SONG.postfix));
			loadSoundAlt(AssetsPaths.voices(SONG.song, 'Voices_Player' + SONG.postfix));
			loadSoundAlt(AssetsPaths.voices(SONG.song, 'Voices_Opponent' + SONG.postfix));

			canLeave = true;
		});
		call("preparePlayState");
	}
	public inline function makeEvent(event:Array<Dynamic>, i:Int) pushEvent(event[0], event[1][i]);
	public function pushEvent(time:Float, args:Array<Dynamic>)
	{
		var event:EventNote = new EventNote(time, args[0], args[1], args[2], args[3]);
		switch (event.event){
			case 'Change Character':
				loadCharacter(event.value2);
		}
		call('onEventPushed', [event.event, event.value1 ?? '',
			event.value2 ?? '', event.value3 ?? '', event.strumTime]);
	}

	public inline function loadSound(path:String, ?isExists:Bool)
	{
		loadSoundAlt(AssetsPaths.sound(path), isExists);
	}
	public function loadSoundAlt(path:String, ?isExists:Bool)
	{
		var callback = callbacks.add('sound: ' + path);
		if (callback == null) return;
		funcsPrepare.push(state -> {
			callback(() -> {
				if (isExists || Assets.cache.hasSound(path) || Assets.exists(path))
				{
					Assets.getSound(path);
				}
			});
		});
	}

	public inline function loadImage(path:String, ?isExists:Bool)
	{
		loadImageAlt(AssetsPaths.image(path), isExists);
	}
	public function loadImageAlt(path:String, ?isExists:Bool)
	{
		var callback = callbacks.add('image: ' + path);
		if (callback == null) return;
		funcsPrepare.push(state -> {
			callback(() -> {
				if (isExists || Assets.exists(path))
				{
					Assets.getBitmapData(path, false);
				}
			});
		});
	}

	#if VIDEOS_ALLOWED
	public inline function loadVideo(path:String)
	{
		loadVideoAlt(AssetsPaths.video(path));
	}
	public function loadVideoAlt(path:String)
	{
		/*
		var callback = callbacks.add('video: ' + path);
		if (callback == null) return;
		var lock = new Lock();
		funcsPrepare.push(state -> {
			callback(() -> {
				FlxG.signals.preUpdate.addOnce(() -> {
					var video = new Video();
					video.visible = false;
					video.forceRendering = true;
					// FlxG.game.addChild(video);
					var result = video.load(path, [VideoSprite.muted]);
					var videoCallback = () ->
					{
						trace(path);
						lock.release();
						if (video == null) return;
						video.dispose();
						// FlxG.game.removeChild(video);
						video = null;
					}
					if (!result)
					{
						videoCallback();
						return;
					}
					video.onOpening.add(() -> {
						if (video != null)
							video.role = LibVLC_Role_Game;
					});
					video.onFormatSetup.add(videoCallback);
					video.onEncounteredError.add(err -> {
						Log(err, RED); // what a fuck is 'Unknown error' // TODO
						videoCallback();
					});
					video.play(); // NEEDED TO LOAD IT
				});
				lock.wait(40);
			});
		});
		*/
	}
	#end
	public inline function loadAtlas(path:String)
	{
		loadAtlasAlt(AssetsPaths.image(path));
	}
	public function loadAtlasAlt(path:String)
	{
		var noExt = PathUtil.withoutExtension(path);
		var callback = callbacks.add('atlas: ' + noExt);
		if (callback == null) return;
		callback(() -> {
			if (Paths.getAtlas(noExt) == null)
				loadImageAlt(path);
			/*
			var imagesToLoad:Array<String> = [];

			if (Assets.exists('$noExt.xml')
				|| Assets.exists('$noExt.txt')
				|| Assets.exists('$noExt.json')
			)
			{
				imagesToLoad.push(path);
			}
			else
			{
				var noExt = noExt + "/spritemap";
				var i:Int = 0;
				while (Assets.exists('$noExt${++i}.png'))
				{
					imagesToLoad.push('$noExt$i.png');
				}
			}
			// trace(path + ": " + imagesToLoad);
			if (imagesToLoad.length > 0)
			{
				for (i in imagesToLoad)
					loadImageAlt(i, true);
			}
			else
			{
				loadImageAlt(path);
			}
			*/
		});
	}

	public function loadCoolListFile(path:String, preCallback:Null<Array<String>> -> Void)
	{
		var callback = callbacks.add('json: ' + path);
		if (callback == null) return;
		callback(() -> {
			if (Assets.exists(path))
			{
				var text = Assets.getText(path);
				if (text != null)
					preCallback(CoolUtil.unixNewLine(text).split("\n"));
			}
		});
	}

	public function loadJson(path:String, preCallback:Null<Dynamic> -> Void)
	{
		var callback = callbacks.add('json: ' + path);
		if (callback == null) return;
		callback(() -> {
			if (Assets.exists(path))
			{
				var data:Dynamic = null;
				try
				{
					var txt = Assets.getText(path);
					data = Json.parse(txt);
				}
				catch(e)
				{
					CoolUtil.alert(e.message, e.details());
				}
				preCallback(data);
			}
		});
	}

	public function loadFile(path:String) {
		/*
		if (FileSystem.isDirectory(path))
		{
			for (path in AssetsPaths.getFolderContent(path, true))
				loadThing(path);
			return;
		}
		*/
		if (AssetsPaths.IMAGE_REGEX.match(path))
		{
			loadImageAlt(path);
		}
		else if (AssetsPaths.SOUND_REGEX.match(path))
		{
			loadSoundAlt(path);
		}
		else if (AssetsPaths.VIDEO_REGEX.match(path))
		{
			#if VIDEOS_ALLOWED
			loadVideoAlt(path);
			#end
		}
		else
		{
			loadAtlasAlt(path);
		}
	}
	public function loadPreloadList(list:Array<String>)
	{
		if (list == null)
			return;
		for (i in list)
		{
			i = i.replace("\\", "/");
			if (i.endsWith("*"))
			{
				i = i.substr(0, i.length - 1);
				for (path in AssetsPaths.getFolderContent(i, true))
				{
					loadFile("assets/" + path);
				}
			}
			else
			{
				loadFile("assets/" + i);
			}
		}
	}
	public function loadCharacter(file:String)
	{
		var callback = callbacks.add('character: ' + file);
		if (callback == null) return;
		callback(Character.precasheCharacter.bind(file, true));
		/*
		str = AssetsPaths.getPath('characters/$str.json');

		loadJson(str, (data:Dynamic) -> {
			if (data == null) return;
			var image:String = data.image;
			var healthicon:String = data.healthicon;
			if (image != null)
				for (i in image.replace(",", ";").split(";"))
					loadAtlas(i.trim());
			if (healthicon != null)
				loadAtlas("icons/" + healthicon);
		});
		*/
	}
}

class MultiCallback extends FlxBasic
{
	public var onProgress:Int -> Null<Int> -> Void; // (progress:Int, length:Null<Int>) -> Void
	public var onLoaded:Void->Void;
	public var logId:String = null;
	public var curID:String = null;
	public var length(default, null) = 0;
	public var numRemaining(default, null) = 0;

	var unfired = new Map<String, (() -> Void) -> Void>();
	var fired:Array<String> = [];
	var dirtyProgressUpdate:Bool = false;
	var completedLoad(get, never):Bool;
	function get_completedLoad()
	{
		return numRemaining == 0 && length > 0;
	}

	public function new(onLoaded:Void->Void, ?onProgress:Int -> Null<Int> -> Void, ?logId:String)
	{
		super();
		this.onLoaded = onLoaded;
		this.onProgress = onProgress;
		this.logId = logId;
		if (onProgress != null)
			onProgress(0, null);
	}
	public override function update(elapsed:Float) {
		super.update(elapsed);
		if (dirtyProgressUpdate && onProgress != null)
		{
			dirtyProgressUpdate = false;
			onProgress(length - numRemaining, length);
		}
		if (completedLoad && onLoaded != null)
		{
			onLoaded();
		}
	}

	public function add(id = 'untitled', ?filePos:PosInfos):(() -> Void) -> Void
	{
		var itemLogID = '$length:$id';
		if (unfired.exists(id) || fired.contains(id))
		{
			Log(itemLogID, RED);
			return null;
		}
		length++;
		numRemaining++;
		var func:(() -> Void) -> Void = function(proggCal:() -> Void) {
			var prevID = curID;
			curID = id;
			proggCal();

			haxe.MainLoop.runInMainThread(function():Void
			{
				if (unfired.exists(id))
				{
					unfired.remove(id);
					fired.push(id);
					numRemaining--;

					log('fired $itemLogID, $numRemaining remaining', filePos);

					dirtyProgressUpdate = true;

					if (numRemaining == 0)
					{
						log('all callbacks fired', filePos);
					}
				}
				else
					log('already fired $id', filePos);
			});
			curID = prevID;
		}
		unfired[id] = func;
		return func;
	}

	function log(msg:String, ?filePos:PosInfos):Void
	{
		if (logId != null) trace('\x1B[1m$logId\x1B[0m:\t$msg');
	}

	public function getFired():Array<String>
		return fired.copy();

	public function getUnfired():Array<(() -> Void) -> Void>
		return Lambda.array(unfired);
}