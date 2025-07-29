package game.backend.system;

import haxe.extern.EitherType;
import game.backend.assets.AssetsPaths;

import game.backend.data.jsons.StageData;
import haxe.PosInfos;

import flixel.graphics.frames.FlxAtlasFrames;
import flixel.graphics.FlxGraphic;

import openfl.display.BitmapData;
import openfl.media.Sound;
import openfl.utils.AssetType;
import flxanimate.frames.FlxAnimateFrames;

#if sys
import sys.io.File;
import sys.FileSystem;
#end

import game.backend.system.Mods;
#if yagp
import com.yagp.GifDecoder;
import game.backend.system.GifAtlas;
#end

import game.backend.utils.PathUtil;

@:access(openfl.display.BitmapData)
@:access(flixel.system.frontEnds)
class Paths{
	public static inline final SOUND_EXT = AssetsPaths.SOUND_EXT;
	public static inline final VIDEO_EXT = 'mp4';
	public static final ALLOWED_IMAGES = AssetsPaths.ALLOWED_IMAGES;

	public static inline function excludeAsset(key:String)
		if (!dumpExclusions.contains(key))
			dumpExclusions.push(key);

	public static var dumpExclusions:Array<String> =
	[
		'assets/music/freakyMenu.$SOUND_EXT',
		'assets/shared/music/breakfast.$SOUND_EXT',
		'assets/shared/music/tea-time.$SOUND_EXT',
	];

	@:noCompletion static var flxGraphicCashe(get, never):Map<String, FlxGraphic>;
	@:noCompletion static inline function get_flxGraphicCashe()	return FlxG.bitmap._cache;

	static var currentTrackedAssets:Array<String> = [];

	@:access(flixel.sound.FlxSound)
	@:access(openfl.media.Sound)
	public static function clearUnusedMemory(?posInfo:PosInfos)
	{
		Log('Clear Unused Memory', MAGENTA, posInfo);

		// AssetsPaths.assetsTree.unload(); // clear mods folders cashe
		// AssetsPaths.assetsTree.unloadDefaultLibs(); // clear default folders cashe

		AssetsPaths.assetsTree.unloadAllLibraries(); // clear all folders cashe

		// Clear sound cashe
		var usedSounds:Array<Sound> = [for (i in FlxG.sound.list) if (i.isValid()) i._sound];
		var music = FlxG.sound.music;
		if (music.isValid() && (music.persist && music.active))
			usedSounds.push(FlxG.sound.music._sound);

		final cache:openfl.utils.AssetCache = cast Assets.cache; // lol
		for (key => sound in cache.sound)
		{
			if (usedSounds.contains(sound)) continue;
			if (sound?.__buffer != null)
			{
				sound.__buffer.dispose();
				sound.__buffer = null;
			}
			cache.removeSound(key);
		}
		for (key in cache.font.keys())
			cache.removeFont(key);
		// for (key => bitmap in cache.bitmapData){
		// 	if (!FlxG.bitmap.checkCache(key)){
		// 		if (bitmap != null && bitmap.__texture != null){
		// 			bitmap.__texture.dispose();
		// 		}
		// 		cache.removeBitmapData(key);
		// 	}
		// }

		FlxG.bitmap.clearUnused();
		// FlxG.bitmap.clearCache();
	}

	public static inline function clearStoredMemory(?posInfo:PosInfos)
	{
		Log('Clear Stored Memory', MAGENTA, posInfo);
		for (key in FlxG.bitmap._cache.keys())
		{
			var obj = FlxG.bitmap._cache.get(key);
			// if (obj != null && key.startsWith(AssetsPaths.FLXGRAPHIC_PREFIXKEY))
			// 	trace(key, obj.useCount <= 0, obj.useCount);
			// trace(key, key.startsWith(AssetsPaths.FLXGRAPHIC_PREFIXKEY), obj?.useCount);
			if (obj != null && (key.startsWith(AssetsPaths.FLXGRAPHIC_PREFIXKEY) || !obj.persist) && obj.useCount <= 0)
			{
				FlxG.bitmap.removeKey(key);

				if (obj != null)
					obj.destroy();
			}
		}

		Main.fpsVar.resetViewMaxMemory();
		// FlxG.bitmap.clearCache();
	}

	public static inline function clearCurret(type:String, key:String) {}

	public static var currentLevel(default, set):String;
	static inline function set_currentLevel(name:String):String return currentLevel = name.toLowerCase();

	public static inline function setCurrentLevel(name:String) return currentLevel = name;

	public static inline function getPath(file:String, ?type:AssetType = TEXT, ?library:Null<String>, ?modsAllowed:Bool)
		return AssetsPaths.getPath(file, library);

	public static inline function getLibraryPath(file:String, type:AssetType = TEXT, library = "shared")
		// return (library == "shared" ? getSharedPath(file, type) : getLibraryPathForce(file, library));
		return AssetsPaths.getPath(file, library == "shared" ? null : library);

	static inline function getLibraryPathForce(file:String, library:String)
		// return Assets.exists('$library:assets/${langGlobalFolder}shared/$library/$file')?'$library:assets/${langGlobalFolder}shared/$library/$file':'$library:assets/$library/$file';
		// return '$library:assets/$library/$file';
		return AssetsPaths.getPath(file, library);

	public static inline function getSharedPath(file:String = '', type:AssetType = TEXT)
		// return Assets.exists('assets/${langGlobalFolder}shared/$file', type) ? 'assets/${langGlobalFolder}shared/$file' : 'assets/shared/$file';
		// return 'assets/shared/$file';
		return AssetsPaths.getPath(file, null);

	public static inline function file(file:String, type:AssetType = TEXT, ?library:String)
		return AssetsPaths.file(file, library);

	public static inline function txt(key:String, ?library:String)
		return getPath('data/$key.txt', TEXT, library);

	public static inline function txtSound(key:String, ?library:String)
		return getPath('sounds/$key.txt', TEXT, library);

	public static inline function xml(key:String, ?library:String)
		return getPath('data/$key.xml', TEXT, library);

	public static inline function json(key:String, ?library:String)
		return AssetsPaths.json(key, library);

	public static inline function shaderFragment(key:String, ?library:String)
		return AssetsPaths.fragShader(key, library);

	public static inline function shaderVertex(key:String, ?library:String)
		return AssetsPaths.vertShader(key, library);

	public static inline function lua(key:String, ?library:String)
		return getPath('$key.lua', TEXT, library);

	public static inline function video(key:String){
		return AssetsPaths.video(key);
	}

	public static inline function sound(key:String, ?library:String, ?filePos:PosInfos):Sound
		return returnSound('sounds', key, library, filePos);

	public static inline function soundRandom(key:String, min:Int, max:Int, ?library:String, ?filePos:PosInfos):Sound
		return sound(key + FlxG.random.int(min, max), library, filePos);

	public static inline function music(key:String, ?library:String, ?filePos:PosInfos):Sound
		return returnSound('music', key, library, filePos);

	public static inline function voices(song:String, ?character:String = 'Voices', ?filePos:PosInfos):Sound
		return returnSound(Constants.SONG_AUDIO_FILES_FOLDER, '${formatToSongPath(song)}/$character', filePos);

	public static inline function inst(song:String, ?postfix:String = '', ?filePos:PosInfos):Sound
		return returnSound(Constants.SONG_AUDIO_FILES_FOLDER, '${formatToSongPath(song)}/Inst$postfix', filePos);


	public static inline function image(key:String, ?library:String, ?allowGPU:Bool = true, ?filePos:PosInfos):FlxGraphic
		return AssetsPaths.imageGraphic(key, allowGPU, library, filePos);

	@:access(flixel.graphics.FlxGraphic)
	public static function connectBitmap(bitmapOrGraphic:EitherType<BitmapData, FlxGraphic>, file:String, allowGPU:Bool = true, cashe:Bool = true, ?filePos:PosInfos):FlxGraphic
	{
		if (file == null || bitmapOrGraphic == null)
		{
			Log('oh no $file returning null NOOOO', RED, filePos);
			return null;
		}
		final isGraphic = bitmapOrGraphic is FlxGraphic;
		var bitmap:BitmapData = isGraphic ? cast (bitmapOrGraphic, FlxGraphic).bitmap : bitmapOrGraphic;
		if (allowGPU && ClientPrefs.cacheOnGPU && Assets.allowGPU)
		{
			bitmap.lock();
			if (bitmap.__texture == null)
			{
				bitmap.image.premultiplied = true;
				bitmap.getTexture(FlxG.stage.context3D);
			}

			bitmap.__surface ??= lime.graphics.cairo.CairoImageSurface.fromImage(bitmap.image);

			bitmap.readable = true;
			bitmap.image.data = null;
			bitmap.unlock();
		}

		var newGraphic:FlxGraphic;
		if (isGraphic)
		{
			newGraphic = cast bitmapOrGraphic;
		}
		else
		{
			newGraphic = FlxGraphic.fromBitmapData(bitmap, false, AssetsPaths.FLXGRAPHIC_PREFIXKEY + file, cashe);
			if (cashe && Assets.cache.enabled) Assets.cache.setBitmapData(file, bitmap);
			// Log('$file loaded! (${filePos.fileName}:${filePos.lineNumber})', GREEN);
		}

		// newGraphic.preloadGPU();
		return newGraphic;
	}

	public static inline function getTextFromFile(key:String, ?ignoreMods:Bool = false):String
		return Assets.getText(getPath(key, TEXT));

	public static function getBytes(key:String, ?ignoreMods:Bool = false):haxe.io.Bytes
		return Assets.getBytes(getPath(key, TEXT));

	public static inline function font(key:String, mod:Bool = true)
		return getPath('fonts/$key');

	public static inline function fileExists(key:String, ?type:AssetType, ?ignoreMods:Bool = false, ?library:String)
		return Assets.exists(getPath(key, type, library, false));

	#if yagp
	public static inline function getGifAtlas(path:String, ?library:String = null, ?useFrameDuration:Bool = true, ?allowGPU:Bool = true, ?useCashe:Bool = true):FlxAtlasFrames{
		path = getPath('images/$path.gif', library);
		// if (!GifAtlas.fileCache.exists(path) && Assets.exists(path))
		// 	return GifAtlas.fileCache[path] = new GifAtlas().addFramesFromGif(GifDecoder.parseByteArray(Assets.getBytes(path)), path, useFrameDuration, allowGPU);
		// else
		// 	return GifAtlas.fileCache[path];
		return (useCashe && GifAtlas.fileCache.exists(path)) || Assets.exists(path) ? GifAtlas.fromFile(path, useCashe, useFrameDuration, allowGPU) : null;
	}

	public static inline function getGifAtlasFromDirectory(path:String, ?library:String = null, ?useFrameDuration:Bool = true, ?allowGPU:Bool = true, ?useCashe:Bool = true):FlxAtlasFrames{
		path = getPath('images/$path', library);
		// if (!GifAtlas.fileCache.exists(path) && Assets.exists(path))
		// 	return GifAtlas.fileCache[path] = new GifAtlas().addFramesFromGif(GifDecoder.parseByteArray(Assets.getBytes(path)), path, useFrameDuration, allowGPU);
		// else
		// 	return GifAtlas.fileCache[path];
		return Assets.exists(path) && FileSystem.isDirectory(path) ? GifAtlas.fromDirectory(path, useCashe, useFrameDuration, allowGPU) : null;
	}
	#end

	public static function getAtlas(key:String, ?library:String, ?allowGPU:Bool = true):flixel.graphics.frames.FlxFramesCollection{
		Assets.allowGPU = allowGPU;
		final atlas = AssetsPaths.getFrames(key, library);
		Assets.allowGPU = true;
		return atlas;
	}

	public static inline function getSparrowAtlas(key:String, ?library:String, ?allowGPU:Bool = true):FlxAtlasFrames{
		// try{
		Assets.allowGPU = allowGPU;
		final atlas = AssetsPaths.getSparrowAtlas(key, library);
		Assets.allowGPU = true;
		// }catch(e){
		// 	Log('[getSparrowAtlas] - ERROR WHILE LOADING "$key" xml: ${e.message}.', RED, filePos);
		// 	lime.app.Application.current.window.alert('${e.message}\n\ntl;dr; no spritesheet lmao.\nbtw, this message won\'t crash the game! :D', 'XML ERROR!!');
		// 	return null;
		// }
		return atlas;
	}
	public static inline function getPackerAtlas(key:String, ?library:String, ?allowGPU:Bool = true):FlxAtlasFrames{
		Assets.allowGPU = allowGPU;
		final atlas = AssetsPaths.getPackerAtlas(key, library);
		Assets.allowGPU = true;
		return atlas;
	}

	static final invalidChars = ~/[~&\\;:<>#]/;
	static final hideChars = ~/[.,'"%?!]/;
	public static inline function formatToSongPath(path:String){
		final path = invalidChars.split(path.replace(' ', '-')).join("-");
		return hideChars.split(path).join("").toLowerCase();
	}

	public static function returnSound(path:String, key:String, ?library:String, ?filePos:PosInfos):Sound
	{
		if (PathUtil.extension(key) == null) key += '.$SOUND_EXT';
		key = getPath('$path/$key', SOUND, library);
		if (Assets.cache.hasSound(key) || Assets.exists(key))
			return Assets.getSound(key);
		Log('Could not find a Sound asset with ID \'$key\'.', RED, filePos);
		return null;
	}

	// static inline function pushLocalAssets(key:String = '') /*if (!localTrackedAssets.contains(key))*/ localTrackedAssets.push(key);

	#if MODS_ALLOWED
	public static inline function mods(key:String = '')		return 'mods/$key';
	public static inline function modsFont(key:String)		return modFolders('fonts/$key');
	public static inline function modsJson(key:String)		return modFolders('data/$key.json');
	public static inline function modsVideo(key:String)		return modFolders('videos/$key.$VIDEO_EXT');
	public static inline function modsSounds(path:String, key:String)		return modFolders('$path/$key');
	public static inline function modsImages(key:String, lib:String = '')	return modFolders('images/$key.png');
	public static inline function modsXml(key:String)		return modFolders('images/$key.xml');
	public static inline function modsTxt(key:String)		return modFolders('images/$key.txt');
	public static inline function modsShaderFragment(key:String, ?library:String)	return modFolders('shaders/$key.frag');
	public static inline function modsShaderVertex(key:String, ?library:String)		return modFolders('shaders/$key.vert');

	public static function modFolders(key:String, checkLib:Bool = true){
		final curModDir:String = ModsFolder.currentModFolder;
		final isValidLib:Bool = checkLib && StageData.forceNextDirectory != null && StageData.forceNextDirectory.trim().length > 0;
		if (curModDir != null && curModDir.length > 0){
			if (isValidLib){
				final fileToCheck:String = mods('$curModDir/${StageData.forceNextDirectory}/$key');
				if (FileSystem.exists(fileToCheck)) return fileToCheck;
			}
			final fileToCheck:String = mods('$curModDir/$key');
			if (FileSystem.exists(fileToCheck)) return fileToCheck;
		}
		/*
		for (mod in Mods.getGlobalMods()){
			if (isValidLib){
				final fileToCheck:String = mods('$mod/${StageData.forceNextDirectory}/$key');
				if (FileSystem.exists(fileToCheck)) return fileToCheck;
			}
			final fileToCheck:String = mods('$mod/$key');
			if (FileSystem.exists(fileToCheck)) return fileToCheck;
		}
		*/
		return mods(key);
	}
	#end
}