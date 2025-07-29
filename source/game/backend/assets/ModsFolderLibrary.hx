package game.backend.assets;

import lime.graphics.Image;
import lime.media.AudioBuffer;
import lime.media.vorbis.VorbisFile;
import lime.text.Font;
import lime.utils.AssetLibrary;
import lime.utils.Assets as LimeAssets;
import lime.utils.Bytes;
#if sys
import sys.FileStat;
import sys.FileSystem;
import sys.io.File;
#end

class ModsFolderLibrary extends AssetLibrary implements IModsAssetLibrary
{
	public var folderPath:String;
	public var modName:String;
	public var libName:String;
	public var useImageCache:Bool = true;
	public var prefix = 'assets/';

	public function new(folderPath:String, libName:String, ?modName:String)
	{
		while (folderPath.endsWith("/"))
			folderPath = folderPath.substring(0, folderPath.length - 1);
		this.folderPath = folderPath;
		this.libName = libName;
		this.prefix = 'assets/$libName/';
		this.modName = modName ?? libName;
		super();
	}

	public var _parsedAsset:String = null;

	private function getAssetPath()
	{
		return '$folderPath/$_parsedAsset';
	}

	public override function getPath(id:String):String
	{
		return __parseAsset(id) ? getAssetPath() : null;
	}

	public inline function getFolders(folder:String):Array<String>
		return __getFiles(folder, true);

	public inline function getFiles(folder:String):Array<String>
		return __getFiles(folder, false);


	public override function getText(id:String):String
	{
		// if (ClientPrefs.useTxtCashe && cachedText.exists(id))
		// {
		// 	return cachedText.get(id);
		// }
		// else
		{
			var bytes = getBytes(id);
			if (bytes == null)
				return null;

			var txt:String = bytes.getString(0, bytes.length);
			// cachedText.set(id, txt);
			return txt;
		}
	}

	#if sys
	private var editedTimes:Map<String, Float> = [];

	public function getEditedTime(asset:String):Null<Float>
	{
		return editedTimes[asset];
	}

	public override function unload():Void
	{
		editedTimes.clear();
		super.unload();
	}

	public override function getAudioBuffer(id:String):AudioBuffer
	{
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

	public function __getFiles(folder:String, folders:Bool = false)
	{
		if (!folder.endsWith("/"))
			folder = folder + "/";
		if (!__parseAsset(folder))
			return [];
		var path = getAssetPath();
		try
		{
			return [
				for (e in FileSystem.readDirectory(path)) if (FileSystem.isDirectory('$path$e') == folders) e
			];
		}
		catch (e)
		{
			// woops!!
		}
		return [];
	}

	public override function exists(asset:String, type:String):Bool
	{
		if (!__parseAsset(asset)) return false;

		return FileSystem.exists(getAssetPath());
	}

	private function __isCacheValid(cache:Map<String, Dynamic>, asset:String, isLocalCache:Bool = false)
	{
		if (!editedTimes.exists(asset))
			return false;
		if (editedTimes[asset] == null || editedTimes[asset] < FileSystem.stat(getPath(asset)).mtime.getTime())
		{
			// destroy already existing to prevent memory leak!!!
			var asset = cache[asset];
			if (asset != null)
			{
				switch (Type.getClass(asset))
				{
					case lime.graphics.Image:
						Log("Getting rid of image cause replaced", YELLOW);
						cast(asset, lime.graphics.Image);
				}
			}
			return false;
		}

		if (!isLocalCache)
			asset = '$libName:$asset';

		return cache.exists(asset) && cache[asset] != null;
	}
	#else
	private function __isCacheValid(cache:Map<String, Dynamic>, asset:String, isLocalCache:Bool = false)
	{
		if (!isLocalCache)
			asset = '$libName:$asset';

		return cache.exists(asset) && cache[asset] != null;
	}
	public function __getFiles(folder:String, folders:Bool = false)
	{
		if (!folder.endsWith("/"))
			folder = folder + "/";
		if (!__parseAsset(folder))
			return [];
		var path = getAssetPath();
		var list = list(null);
		var keys:Array<String> = (
			folders ? [for(i in list) if (i.startsWith(path)) i]
			: [for(i in list) if (i.startsWith(path)) i.substr(path.length)]
		);
		if (folders)
		{
			var e:Array<String> = [];
			for(i in keys.map(s -> return s.substring(0, s.lastIndexOf("/"))).map(s -> return s.substring(s.lastIndexOf("/"), s.length)))
			{
				if (i.length > 0 && !e.contains(i))
				{
					e.push(i);
				}
			}
			return e;
		}
		// keys.sort((a, b) -> return a > b ? -1 : 1);
		return keys;
	}

	public override function exists(asset:String, type:String):Bool
	{
		return __parseAsset(asset) ? super.exists(_parsedAsset, type) : false;
	}
	#end

	private function __parseAsset(asset:String):Bool
	{
		if (asset.startsWith(prefix))
		{
			_parsedAsset = asset.substr(prefix.length);
			if (ModsFolder.useLibFile)
			{
				var file = new haxe.io.Path(_parsedAsset);
				if (file.file.startsWith("LIB_"))
				{
					var library = file.file.substr(4);
					if (library != modName)
						return false;
					_parsedAsset = file.dir + "." + file.ext;
				}
			}
			return true;
		}
		return false;
	}
	public function dispose()
	{
		unload();
	}
}
