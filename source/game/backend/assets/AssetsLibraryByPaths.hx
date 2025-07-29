package game.backend.assets;

import haxe.io.Path;
import lime.app.Event;
import lime.app.Future;
import lime.app.Promise;
import lime.graphics.Image;
import lime.media.AudioBuffer;
import lime.text.Font;
import lime.utils.AssetLibrary;
import lime.utils.AssetType;
import lime.utils.Assets as LimeAssets;
import lime.utils.Bytes;
import openfl.text.Font as OpenFLFont;
#if sys
import sys.FileStat;
import sys.FileSystem;
import sys.io.File;
#end

class AssetsLibraryByPaths extends AssetLibrary implements IModsAssetLibrary {
	public var folderPath:String;
	public var modName:String;
	public var libName:String;
	public var useImageCache:Bool = false;
	public var prefix = 'assets/';

	public function new(folderPath:String, ?paths:Array<String>, libName:String, ?modName:String) {
		this.folderPath = folderPath;
		this.libName = libName;

		this.modName = modName ?? libName;

		super();
		if (paths != null)
			for (i in paths)
			{
				__parseAsset(i);
				// trace(_parsedAsset);
				this.paths.set(_parsedAsset, _parsedAsset);
			}
	}

	public var _parsedAsset:String;

	public override function getAudioBuffer(id:String):AudioBuffer {
		if (cachedAudioBuffers.exists(id))
		{
			return cachedAudioBuffers.get(id);
		}
		if (exists(id, "SOUND"))
		{
			var path = getAssetPath();
			// editedTimes[id] = FileSystem.stat(path).mtime.getTime();
			final e = AudioBuffer.fromFile(path);
			cachedAudioBuffers.set(id, e);
			// LimeAssets.cache.audio.set('$libName:$id', e);
			return e;
		}
		return null;
	}
	public override function getBytes(id:String):Bytes
	{
		// if (cachedBytes.exists(id))
		// {
		// 	return cachedBytes.get(id);
		// }
		if (exists(id, "BINARY"))
		{
			var path = getAssetPath();
			var bytes = Bytes.fromFile(path);
			// cachedBytes.set(id, bytes);
			// editedTimes[id] = FileSystem.stat(path).mtime.getTime();
			return bytes;
		}
		return null;
	}

	public override function getFont(id:String):Font
	{
		if (cachedFonts.exists(id))
		{
			return cachedFonts.get(id);
		}
		if (exists(id, "FONT"))
		{
			var path = getAssetPath();
			cachedFonts.set(id, ModsFolder.registerFont(Font.fromBytes(Bytes.fromFile(path))));
			// editedTimes[id] = FileSystem.stat(path).mtime.getTime();
			return cachedFonts.get(id);
		}
		return null;
	}

	public override function getImage(id:String):Image
	{
		// if (cachedImages.exists(id))
		// {
		// 	var img = cachedImages.get(id);
		// 	if ((img.data == null) == ClientPrefs.cacheOnGPU)
		// 		return img;
		// 	else
		// 		cachedImages.remove(id);
		// }
		if (exists(id, "IMAGE"))
		{
			var img = Image.fromFile(getAssetPath());
			// cachedImages.set(id, img);
			// editedTimes[id] = FileSystem.stat(path).mtime.getTime();
			return img;
		}
		return null;
	}

	public override function getPath(id:String):String
	{
		return __parseAsset(id) ? getAssetPath() : null;
	}

	public function __parseAsset(asset:String):Bool {
		if (!asset.startsWith(prefix)) return false;
		_parsedAsset = asset.replace("\\", "/").substr(prefix.length);
		if(ModsFolder.useLibFile) {
			var file = new haxe.io.Path(_parsedAsset);
			if(file.file.startsWith("LIB_")) {
				var library = file.file.substr(4);
				if(library != modName) return false;

				_parsedAsset = file.dir + "." + file.ext;
			}
		}
		return true;
	}

	public function __isCacheValid(cache:Map<String, Dynamic>, asset:String, isLocal:Bool = false) {
		return cache.exists(isLocal ? '$libName:$asset': asset);
	}

	public override function exists(asset:String, type:String):Bool {
		if(!__parseAsset(asset)) return false;

		return paths[_parsedAsset] != null;
	}

	private function getAssetPath() {
		return '$folderPath/$_parsedAsset';
	}

	public function getFiles(folder:String):Array<String> {
		var content:Array<String> = [];

		if (!folder.endsWith("/")) folder = folder + "/";
		if (!__parseAsset(folder)) return content;

		for(k => e in paths) {
			if (k.startsWith(_parsedAsset)) {
				var fileName = e.substr(_parsedAsset.length);
				if (!fileName.contains("/"))
					content.push(fileName);
			}
		}
		return content;
	}

	public function getFolders(folder:String):Array<String> {
		var content:Array<String> = [];

		if (!folder.endsWith("/")) folder = folder + "/";
		if (!__parseAsset(folder)) return content;

		for(k => e in paths) {
			if (k.startsWith(_parsedAsset)) {
				var fileName = e.substr(_parsedAsset.length);
				if (fileName.contains("/")) {
					var s = fileName.substr(0, fileName.indexOf("/"));
					if (!content.contains(s))
						content.push(s);
				}
			}
		}
		return content;
	}
	public function dispose()
	{
		unload();
	}
}