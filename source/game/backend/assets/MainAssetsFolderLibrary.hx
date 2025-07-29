package game.backend.assets;

import haxe.io.Path;
import lime.utils.AssetLibrary;
import lime.utils.Assets as LimeAssets;
import lime.media.AudioBuffer;
import lime.graphics.Image;
import lime.text.Font;
import lime.utils.Bytes;
#if sys
import sys.FileStat;
import sys.FileSystem;
import sys.io.File;
#end
// TODO
class MainAssetsFolderLibrary extends AssetLibrary implements IModsAssetLibrary
{
	public var folderPath:String;
	public var modName:String;
	public var libName:String;
	public var useImageCache:Bool = true;
	public var prefix = 'assets/';

	public function new(path:String, libName:String)
	{
		this.folderPath = path;
		this.libName = libName;
		this.prefix = 'assets/$libName/';
		super();
	}

	private function __isCacheValid(cache:Map<String, Dynamic>, asset:String, isLocal:Bool = false):Bool return exists(asset, null);

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

	public var _parsedAsset:String = null;

	public override function getPath(id:String):String
	{
		return __parseAsset(id) ? getAssetPath() : null;
	}

	public inline function getFolders(folder:String):Array<String>
		return __getFiles(folder, true);

	public inline function getFiles(folder:String):Array<String>
		return __getFiles(folder, false);

	public function __getFiles(folder:String, folders:Bool = false)
	{
		if (!folder.endsWith("/"))
			folder = folder + "/";
		if (!__parseAsset(folder))
			return [];
		var path = getAssetPath();
		var list = [
			for (file in list(null))
				if (file.startsWith(path))
					file.substr(path.length)
		];

		// var folderName = folder.substr(folder.lastIndexOf("/"));
		// list.filter(path -> return (path.indexOf("/") != -1) == folders);

		list.filter(path -> return (path.indexOf("/") != -1) == folders);
		return list;
	}

	private function getAssetPath()
	{
		return '$folderPath/$_parsedAsset';
	}
	public function dispose()
	{
		unload();
	}
}
