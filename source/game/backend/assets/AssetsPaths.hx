package game.backend.assets;

import haxe.PosInfos;
import haxe.io.Path;
import lime.utils.AssetLibrary;
import openfl.utils.AssetType;
import flixel.graphics.frames.FlxFramesCollection;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.system.FlxAssets.FlxGraphicAsset;
import flixel.graphics.FlxGraphic;
// import game.backend.assets.LimeLibrarySymbol;
import game.backend.assets.ModsFolder;
import game.backend.utils.PathUtil;
#if yagp
import game.backend.system.GifAtlas;
#end
import game.backend.system.MultiFramesCollection;
import flxanimate.frames.FlxAnimateFrames;

// import game.backend.scripting.Script;

class AssetsPaths
{
	/**
	 * Preferred sound extension for the game's audio files.
	 * Currently is set to `mp3` for web targets, and `ogg` for other targets.
	 */
	public static inline final SOUND_EXT = #if web "mp3" #else "ogg" #end;

	public static final ALLOWED_IMAGES = ["png", "jpg", "jpeg", "jpe"];
	public static final ALLOWED_VIDEOS = [
		"3gp", "asf", "avi", "divx", "dvr", "f4v", "flv",
		"m2ts", "m2v", "m4v", "mkv", "mov", "mov", "mp4",
		"mpeg", "mpg", "mpg", "mts", "mxf", "nsv", "ogv",
		"rm", "rmvb", "ts", "vob", "webm", "wmv", "xvid"
	]; // todo: test them all

	public static var assetsTree:AssetsLibraryList;

	public static var tempFramesCache:Map<String, FlxFramesCollection> = [];

	public static function getAllValidAssetFolders()
		return [
			Constants.SONG_AUDIO_FILES_FOLDER,
			"characters",
			Constants.SONG_CHART_FILES_FOLDER,
			Constants.SONG_EVENTS_FILES_FOLDER,
			"fonts",
			"images",
			Constants.SONG_NOTETYPES_FILES_FOLDER,
			"scripts",
			"shaders",
			"sounds",
			"source",
			"stages",
			"videos"
		];

	public static final HX_REGEX = ~/\.hx$/i;
	public static final IMAGE_REGEX = ~/\.(png|jpe?g|jpeg?)$/i;
	public static final LUA_REGEX = ~/\.lua$/i;
	public static final SOUND_REGEX = #if web ~/\.mp3$/i #else ~/\.ogg$/i #end;
	public static final VIDEO_REGEX = new EReg('\\.(${ALLOWED_VIDEOS.join("|")})$', "i");

	public static final FLXGRAPHIC_PREFIXKEY:String = "TwG|";

	public static function init()
	{
		// FlxG.signals.preStateCreate.add(_ -> resetFramesCache());
	}

	public static function resetFramesCache()
	{
		// trace(Main.canClearMem);
		if (!Main.canClearMem)
			return;

		for (i in tempFramesCache)
		{
			if (i != null && i.parent != null)
			{
				i.parent.persist = false;
			}
		}
		tempFramesCache.clear();

		FlxAnimateFrames.clearCache();
		#if yagp
		for (_ => i in GifAtlas.fileCache)
			i.destroy();
		for (_ => i in GifAtlas.directoryCache)
			i.destroy();
		GifAtlas.fileCache.clear();
		GifAtlas.directoryCache.clear();
		#end
	}

	public static function fileExists(key:String, ?library:String)
		return Assets.exists(getPath(key, library));

	public static function getTextFromFile(key:String):String
		return Assets.getText(getPath(key));

	public static inline function getPath(file:String, ?library:String)
		return library == null ? 'assets/$file' : '$library:assets/$library/$file';

	public static inline function video(key:String, ?ext:String = "mp4")
	{
		// if (!VIDEO_REGEX.match(key))
		if (key != null && !ALLOWED_VIDEOS.contains(PathUtil.extension(key)))
			key += ".mp4";
		return getPath('videos/$key');
	}

	public static inline function file(file:String, ?library:String)
		return getPath(file, library);

	public static inline function txt(key:String, ?library:String)
		return getPath('data/$key.txt', library);

	public static inline function fragShader(key:String, ?library:String)
		return getPath('shaders/$key.frag', library);

	public static inline function vertShader(key:String, ?library:String)
		return getPath('shaders/$key.vert', library);

	public static inline function json(key:String, ?library:String)
		return getPath('data/$key.json', library);

	public static inline function ps1(key:String, ?library:String)
		return getPath('data/$key.ps1', library);

	public static function sound(key:String, ?library:String)
		return getPath('sounds/$key.$SOUND_EXT', library);

	public static inline function soundRandom(key:String, min:Int, max:Int, ?library:String)
		return sound(key + FlxG.random.int(min, max), library);

	public static inline function music(key:String, ?library:String)
		return getPath('music/$key.$SOUND_EXT', library);

	public static inline function mediaSong(song:String, file:String)
		return getPath('${Constants.SONG_AUDIO_FILES_FOLDER}/${Paths.formatToSongPath(song)}/$file.$SOUND_EXT', null);

	public static inline function voices(song:String, ?character:String = 'Voices')
		return mediaSong(song, character);

	public static inline function inst(song:String, ?prefix:String = "")
		return mediaSong(song, "Inst" + prefix);

	public static function image(key:String, ?library:String)
	{
		if (!IMAGE_REGEX.match(key))
			key += ".png";
		/*
			if (checkForAtlas) {
				var atlasPath = getPath('images/$key/spritemap.$ext', library);
				var multiplePath = getPath('images/$key/1.$ext', library);
				if (atlasPath != null && Assets.exists(atlasPath)) return atlasPath.substr(0, atlasPath.length - 14);
				if (multiplePath != null && Assets.exists(multiplePath)) return multiplePath.substr(0, multiplePath.length - 6);
			}
		 */
		return getPath('images/$key', library);
	}

	public static function atlasImage(key:String, ?library:String)
	{
		var atlasPath = getPath('images/$key/spritemap.png', library);
		var multiplePath = getPath('images/$key/1.png', library);
		if (atlasPath != null && Assets.exists(atlasPath))
			return atlasPath.substr(0, atlasPath.length - 14);
		if (multiplePath != null && Assets.exists(multiplePath))
			return multiplePath.substr(0, multiplePath.length - 6);
		return getPath('images/$key', library);
	}

	public static function imageGraphic(key:String, ?allowGPU:Bool = true, ?library:String, ?unique:Bool = false, ?filePos:PosInfos):FlxGraphic
	{
		key = image(key, library);
		var keyStore:String = FLXGRAPHIC_PREFIXKEY + key;
		var graphic:FlxGraphic = FlxG.bitmap.get(keyStore);
		if (graphic != null)
			return graphic;
		Assets.allowGPU = allowGPU;
		graphic = FlxGraphic.fromAssetKey(key, keyStore);
		if (graphic == null)
		{
			Log('oh no $key returning null NOOOO', RED, filePos);
		}
		else
		{
			graphic.persist = true;
			// graphic.preloadGPU();
		}
		Assets.allowGPU = #if hl false #else true #end;
		return graphic;
	}

	/*
		public static inline function script(key:String, ?library:String, isAssetsPath:Bool = false) {
			var scriptPath = isAssetsPath ? key : getPath(key, library);
			if (!Assets.exists(scriptPath)) {
				var p:String;
				for(ex in Script.scriptExtensions) {
					p = '$scriptPath.$ex';
					if (Assets.exists(p)) {
						scriptPath = p;
						break;
					}
				}
			}
			return scriptPath;
		}
	 */
	public static inline function font(key:String)
		return getPath('fonts/$key');

	public static inline function obj(key:String)
		return getPath('models/$key.obj');

	public static inline function dae(key:String)
		return getPath('models/$key.dae');

	public static inline function md2(key:String)
		return getPath('models/$key.md2');

	public static inline function md5(key:String)
		return getPath('models/$key.md5');

	public static inline function awd(key:String)
		return getPath('models/$key.awd');

	public static inline function getSparrowAtlas(key:String, ?library:String)
	{
		var mainKey = image(key, library);
		return FlxAtlasFrames.fromSparrow(
			FlxG.bitmap.add(mainKey, AssetsPaths.FLXGRAPHIC_PREFIXKEY + mainKey),
			file('images/$key.xml', library)
		);
	}

	public static inline function getSparrowAtlasAlt(key:String)
		return FlxAtlasFrames.fromSparrow(
			FlxG.bitmap.add('$key.png', AssetsPaths.FLXGRAPHIC_PREFIXKEY + '$key.png'),
			'$key.xml'
		);

	public static inline function getPackerAtlas(key:String, ?library:String)
	{
		var mainKey = image(key, library);
		return FlxAtlasFrames.fromSpriteSheetPacker(
			FlxG.bitmap.add(mainKey, AssetsPaths.FLXGRAPHIC_PREFIXKEY + mainKey),
			file('images/$key.txt', library)
		);
	}

	public static inline function getPackerAtlasAlt(key:String)
		return FlxAtlasFrames.fromSpriteSheetPacker(
			FlxG.bitmap.add('$key.png', AssetsPaths.FLXGRAPHIC_PREFIXKEY + '$key.png'),
			'$key.txt'
		);

	public static inline function getAsepriteAtlas(key:String, ?library:String)
	{
		var mainKey = image(key, library);
		return FlxAtlasFrames.fromAseprite(
			FlxG.bitmap.add(mainKey, AssetsPaths.FLXGRAPHIC_PREFIXKEY + mainKey),
			file('images/$key.json', library)
		);
	}

	public static inline function getAsepriteAtlasAlt(key:String)
		return FlxAtlasFrames.fromAseprite(
			FlxG.bitmap.add('$key.png', AssetsPaths.FLXGRAPHIC_PREFIXKEY + '$key.png'),
			'$key.json'
		);

	public static inline function getAssetsRoot():String
		return ModsFolder.currentModFolder == null ? './assets' : '${ModsFolder.modsPath}${ModsFolder.currentModFolder}';

	public static function getMultipleFrames(keys:Array<String>, assetsPath:Bool = false, ?library:String):MultiFramesCollection
	{
		var keyStr:String = keys.join("|");
		var _graphic = FlxG.bitmap.add("flixel/images/logo/default.png", false, "MultiFramesCollection: " + keyStr);
		var finalFrames = MultiFramesCollection.findFrame(_graphic);
		if (finalFrames != null)
			return finalFrames;
		finalFrames = new MultiFramesCollection(_graphic);
		var framesChilds:FlxFramesCollection;
		for (i in keys)
		{
			if ((framesChilds = getFrames(i, assetsPath, library)) != null)
			{
				finalFrames.addFrames(framesChilds);
			}
		}
		return finalFrames;
	}

	/**
	 * Gets frames at specified path.
	 * @param key Path to the frames
	 * @param library (Additional) library to load the frames from.
	 */
	public static function getFrames(key:String, assetsPath:Bool = false, ?library:String)
	{
		var frames = tempFramesCache[key];
		if (frames != null)
		{
			if (frames.parent?.bitmap?.readable)
				return frames;
			else
				tempFramesCache.remove(key);
		}
		tempFramesCache[key] = frames = loadFrames(assetsPath ? key : atlasImage(key, library));
		if (frames?.parent != null)
			frames.parent.persist = true;
		return frames;
	}

	/**
	 * Loads frames from a specific image path. Supports Sparrow Atlases, Packer Atlases, Asesprite Atlas and Gif.
	 * @param path Path to the image
	 * @param Unique Whenever the image should be unique in the cache
	 * @param Key Key to the image in the cache
	 * @return FlxFramesCollection Frames
	 */
	static function loadFrames(path:String, ?Unique:Bool):FlxFramesCollection
	{
		var noExt = PathUtil.withoutExtension(path);

		/*
			if (Assets.exists('$noExt/1.png'))
			{
				// MULTIPLE SPRITESHEETS!!

				var graphic = FlxG.bitmap.add("flixel/images/logo/default.png", false, '$noExt/mult');
				var frames = MultiFramesCollection.findFrame(graphic);
				if (frames != null)
					return frames;

				trace("no frames yet for multiple atlases!!");
				var cur = 1;
				var finalFrames = new MultiFramesCollection(graphic);
				while (Assets.exists('$noExt/$cur.png'))
				{
					var spr = loadFrames('$noExt/$cur.png');
					finalFrames.addFrames(spr);
					cur++;
				}
				return finalFrames;
			}
			#if yagp
			else if (Assets.exists('$noExt/1.gif'))
			{
				var graphic = FlxG.bitmap.add("flixel/images/logo/default.png", false, '$noExt/mult');
				var frames = MultiFramesCollection.findFrame(graphic);
				if (frames != null)
					return frames;

				trace("no frames yet for multiple atlases!!");
				var cur = 1;
				var finalFrames = new MultiFramesCollection(graphic);
				while (Assets.exists('$noExt/$cur.gif'))
				{
					var spr = GifAtlas.fromFile('$noExt/$cur.gif');
					finalFrames.addFrames(spr);
					cur++;
				}
				return finalFrames;
			}
			#end
			else
		 */
		if (Assets.exists('$noExt.xml'))
		{
			return AssetsPaths.getSparrowAtlasAlt(noExt);
		}
		else if (Assets.exists('$noExt.txt'))
		{
			return AssetsPaths.getPackerAtlasAlt(noExt);
		}
		else if (Assets.exists('$noExt.json'))
		{
			return AssetsPaths.getAsepriteAtlasAlt(noExt);
		}
		#if yagp
		else if (Assets.exists('$noExt.gif'))
		{
			return GifAtlas.fromFile('$noExt.gif');
		}
		#end

		var graph:FlxGraphic = FlxG.bitmap.add(path, Unique);
		return graph?.imageFrame;
	}

	public static function getFolderDirectories(key:String, addPath:Bool = false, ignoreEmbedded:Bool = false,
			source:AssetsLibraryList.AssetSource = BOTH):Array<String>
	{
		if (!key.endsWith("/"))
			key += "/";
		var content = assetsTree.getFolders('assets/$key', ignoreEmbedded, source);
		if (addPath)
		{
			for (k => e in content)
				content[k] = '$key$e';
		}
		return content;
	}

	public static function getFolderContent(key:String, addPath:Bool = false, ignoreEmbedded:Bool = false,
			source:AssetsLibraryList.AssetSource = BOTH):Array<String>
	{
		if (!key.endsWith("/"))
			key += "/";
		var content = assetsTree.getFiles('assets/$key', ignoreEmbedded, source);
		if (addPath)
		{
			for (k => e in content)
				content[k] = '$key$e';
		}
		return content;
		/*
			if (!key.endsWith("/")) key = key + "/";

			if (ModsFolder.currentModFolder == null && !scanSource)
				return getFolderContent(key, false, addPath, true);

			var folderPath:String = scanSource ? getAssetsPath(key) : getLibraryPathForce(key, 'mods/${ModsFolder.currentModFolder}');
			var libThing = new LimeLibrarySymbol(folderPath);
			var library = libThing.library;

			if (library is openfl.utils.AssetLibrary) {
				var lib = cast(libThing.library, openfl.utils.AssetLibrary);
				@:privateAccess
				if (lib.__proxy != null) library = lib.__proxy;
			}

			var content:Array<String> = [];
			#if MODS_ALLOWED
			if (library is game.backend.assets.IModsAssetLibrary) {
				// easy task, can immediately scan for files!
				var lib = cast(library, game.backend.assets.IModsAssetLibrary);
				content = lib.getFiles(libThing.symbolName);
				if (addPath)
					for(i in 0...content.length)
						content[i] = '$folderPath${content[i]}';
			} else #end {
				@:privateAccess
				for(k=>e in library.paths) {
					if (k.toLowerCase().startsWith(libThing.symbolName.toLowerCase())) {
						if (addPath) {
							if (libThing.libraryName != "")
								content.push('${libThing.libraryName}:$k');
							else
								content.push(k);
						} else {
							var barebonesFileName = k.substr(libThing.symbolName.length);
							if (!barebonesFileName.contains("/"))
								content.push(barebonesFileName);
						}
					}
				}
			}

			if (includeSource) {
				var sourceResult = getFolderContent(key, false, addPath, true);
				for(e in sourceResult)
					if (!content.contains(e))
						content.push(e);
			}

			return content;
		 */
	}
	/*
		// Used in Script.hx
		@:noCompletion public static function getFilenameFromLibFile(path:String) {
			var file = new haxe.io.Path(path);
			if(file.file.startsWith("LIB_")) {
				return file.dir + "." + file.ext;
			}
			return path;
		}

		@:noCompletion public static function getLibFromLibFile(path:String) {
			var file = new haxe.io.Path(path);
			if(file.file.startsWith("LIB_")) {
				return file.file.substr(4);
			}
			return "";
		}
	 */
}