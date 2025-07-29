package game.backend.assets;

#if ZIPLIBS_ALLOWED
import lime.utils.AssetLibrary;

import game.backend.utils.PathUtil;
import game.backend.utils.SysZip;

import haxe.io.Path;
import haxe.zip.Reader;

import lime.app.Event;
import lime.app.Future;
import lime.app.Promise;
import lime.graphics.Image;
import lime.media.AudioBuffer;
import lime.text.Font;
import lime.utils.AssetType;
import lime.utils.Assets as LimeAssets;
import lime.utils.Bytes;

import openfl.text.Font as OpenFLFont;

import sys.FileStat;
import sys.FileSystem;
import sys.io.File;

class ZipFolderLibrary extends AssetLibrary implements IModsAssetLibrary {
	public var zipPath:String;
	public var modName:String;
	public var libName:String;
	public var useImageCache:Bool = false;
	public var prefix = 'assets/';

	public var zip:SysZip;
	public var assets:Map<String, SysZipEntry> = [];

	public function new(zipPath:String, libName:String, ?modName:String) {
		this.zipPath = zipPath;
		this.libName = libName;

		this.modName = modName ?? libName;

		var preLastIndex:Null<Int> = null;
		var lastIndex:Int;
		zip = SysZip.openFromFile(zipPath);
		zip.read();
		for(entry in zip.entries)
		{
			if (PathUtil.extension(entry.fileName) == null) continue; // ignore directories

			__parseAsset(entry.fileName);
			// trace(entry.fileName, _parsedAsset);
			assets[_parsedAsset] = entry;
			if (preLastIndex != null) continue;
			for (folder in AssetsPaths.getAllValidAssetFolders())
			{
				lastIndex = entry.fileName.indexOf(folder);
				if (lastIndex != -1)
				{
					preLastIndex = lastIndex;
				}
			}
		}

		if (preLastIndex == null)
		{
			Log('WARNING: The \'$zipPath\' mod doesn\'t have the right files. ', RED);
		}
		else if (preLastIndex > -1)
		{
			for (path => entry in assets)
			{
				assets.set(path.substring(preLastIndex), entry);
			}
		}

		super();
	}

	public var _parsedAsset:String;

	public override function getAudioBuffer(id:String):AudioBuffer {
		__parseAsset(id);
		return AudioBuffer.fromBytes(unzip(assets[_parsedAsset]));
	}
	public override function getBytes(id:String):Bytes {
		__parseAsset(id);
		return Bytes.fromBytes(unzip(assets[_parsedAsset]));
	}
	public override function getFont(id:String):Font {
		__parseAsset(id);
		return ModsFolder.registerFont(Font.fromBytes(unzip(assets[_parsedAsset])));
	}
	public override function getImage(id:String):Image {
		__parseAsset(id);
		return Image.fromBytes(unzip(assets[_parsedAsset]));
	}

	public override function getPath(id:String):String {
		if (!__parseAsset(id)) return null;
		return getAssetPath();
	}

	public inline function unzip(f:SysZipEntry)
		return f == null ? null : zip.unzipEntry(f);

	public function __parseAsset(asset:String):Bool {
		if (!asset.startsWith(prefix)) return false;
		_parsedAsset = asset.substr(prefix.length);
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

		// trace(asset, _parsedAsset, assets[_parsedAsset] != null);
		return assets[_parsedAsset] != null;
	}

	private function getAssetPath() {
		// trace('[ZIP]$zipPath/$_parsedAsset');
		return '$zipPath/$_parsedAsset';
	}

	public function getFiles(folder:String):Array<String> {
		var content:Array<String> = [];

		if (!folder.endsWith("/")) folder = folder + "/";
		if (!__parseAsset(folder)) return content;

		@:privateAccess
		for(k => e in assets) {
			if (k.startsWith(_parsedAsset)) {
				var fileName = k.substr(_parsedAsset.length);
				if (!fileName.contains("/"))
					content.push(fileName);
			}
		}
		return content;
	}

	public function getFolders(folder:String):Array<String> {
		var content:Array<String> = [];

		if (!folder.endsWith("/")) folder = folder + "/";
		if (!__parseAsset(folder)) return [];

		@:privateAccess
		for(k => e in assets) {
			if (k.startsWith(_parsedAsset)) {
				var fileName = k.substr(_parsedAsset.length);
				if (fileName.contains("/")) {
					var s = fileName.split("/")[0];
					if (!content.contains(s))
						content.push(s);
				}
			}
		}
		return content;
	}
	/*
	public override function unload():Void
	{
		if (zip != null)
		{
			zip.dispose();
			zip = null;
		}
		assets.clear();
		super.unload();
	}
	*/
	public function dispose():Void
	{
		if (zip != null)
		{
			zip.dispose();
			zip = null;
		}
		assets.clear();
		unload();
	}
}
#end