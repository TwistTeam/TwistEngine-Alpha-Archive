package game.backend.assets;

import game.backend.assets.IModsAssetLibrary;
import openfl.text.Font as OpenFLFont;
import lime.utils.AssetLibrary;
import lime.text.Font;

// yea, codename is realy cool
class AssetsLibraryList extends AssetLibrary
{
	public var libraries:Array<AssetLibrary> = [];

	private var __defaultLibraries:Array<AssetLibrary> = [];

	public var base:AssetLibrary;

	public override function isLocal(id:String, type:String)
	{
		#if sys
		return true;
		#else
		for (i in libraries)
			if (i.isLocal(id, type))
				return true;
		return false;
		#end
	}

	public function new(?base:AssetLibrary)
	{
		super();
		base ??= Assets.getLibrary(null);
		addLibrary(this.base = base);
		__defaultLibraries.push(base);
	}

	public function unloadDefaultLibs()
	{
		#if !html5
		for (l in __defaultLibraries)
			l.unload();
		#end
	}

	public function unloadLibraries()
	{
		#if !html5
		for (l in libraries)
			if (!__defaultLibraries.contains(l))
				l.unload();
		#end
	}

	public function unloadAllLibraries()
	{
		#if !html5
		for (l in libraries)
			l.unload();
		#end
	}

	public function disposeLibraries()
	{
		#if !html5
		for (l in libraries)
			if (!__defaultLibraries.contains(l) && (l : Dynamic).dispose != null)
				(l : Dynamic).dispose();
		#end
	}

	public function disposeAllLibraries()
	{
		#if !html5
		for (l in libraries)
			if ((l : Dynamic).dispose != null)
				(l : Dynamic).dispose();
		#end
	}

	public function reset()
	{
		unloadLibraries();

		libraries.clearArray();

		// adds default libraries in again
		for (d in __defaultLibraries)
			addLibrary(d);
	}

	public function addLibrary(lib:AssetLibrary)
	{
		libraries.insert(0, lib);
		return lib;
	}

	public function removeLibrary(lib:AssetLibrary)
		return lib != null && libraries.remove(lib);

	public function existsSpecific(id:String, type:String, source:AssetSource = BOTH)
	{
		if (!id.startsWith("assets/") && existsSpecific('assets/$id', type, source))
			return true;
		for (k => e in libraries)
		{
			if (shouldSkipLib(k, source))
				continue;
			if (e.exists(id, type))
				return true;
		}
		return false;
	}

	public override function exists(id:String, type:String):Bool
		return existsSpecific(id, type, BOTH);

	public function getSpecificPath(id:String, source:AssetSource = BOTH)
	{
		for (k => e in libraries)
		{
			if (shouldSkipLib(k, source))
				continue;
			@:privateAccess
			if (e.exists(id, e.types.get(id)))
			{
				var path = e.getPath(id);
				if (path != null)
					return path;
			}
		}
		return null;
	}

	public override function getPath(id:String)
		return getSpecificPath(id, BOTH);

	public function getFiles(folder:String, ignoreEmbedded:Bool, source:AssetSource = BOTH):Array<String>
	{
		var content:Array<String> = [];
		for (k in 0...libraries.length)
		{
			if (shouldSkipLib(k, source))
				continue;

			var l:AssetLibrary = libraries[k];

			if (l is openfl.utils.AssetLibrary)
			{
				@:privateAccess
				l = cast(l, openfl.utils.AssetLibrary).__proxy;
			}

			// #if MODS_ALLOWED
			if (l is IModsAssetLibrary)
			{
				var lib = cast(l, IModsAssetLibrary);
				for (e in lib.getFiles(folder))
					content.push(e);
			}
			else if (!ignoreEmbedded || Lambda.count(l.classTypes) == 0)
			// #end
			{
				for (i in CoolUtil.filterFileListByPath(l.list(null), folder, false))
					content.push(i);
			}
		}
		// trace(folder + "*: " + content);
		return content;
	}

	public function getFolders(folder:String, ignoreEmbedded:Bool, source:AssetSource = BOTH):Array<String>
	{
		var content:Array<String> = [];
		for (k in 0...libraries.length)
		{
			if (shouldSkipLib(k, source))
				continue;

			var l:AssetLibrary = libraries[k];

			if (l is openfl.utils.AssetLibrary)
			{
				@:privateAccess
				l = cast(l, openfl.utils.AssetLibrary).__proxy;
			}

			if (l is IModsAssetLibrary)
			{
				for (e in cast(l, IModsAssetLibrary).getFolders(folder))
					content.push(e);
			}
			else if (!ignoreEmbedded || Lambda.count(l.classTypes) == 0)
			{
				for(i in CoolUtil.filterFileListByPath(l.list(null), folder, true))
				{
					content.push(i);
				}
			}
		}
		// trace(folder + "*: " + content);
		return content;
	}

	public function getSpecificAsset(id:String, type:String, source:AssetSource = BOTH):Dynamic
	{
		try
		{
			var ass;
			if (!id.startsWith("assets/") && (ass = getSpecificAsset('assets/$id', type, source)) != null)
			{
				return ass;
			}
			var asset;
			var typeLocal;
			for (k => e in libraries)
			{
				if (shouldSkipLib(k, source))
					continue;
				@:privateAccess
				if (e.exists(id, typeLocal = e.types.get(id)))
				{
					if ((asset = e.getAsset(id, type)) != null)
					{
						return asset;
					}
				}
			}
			return null;
		}
		catch (e)
		{
			Log(e, RED);
			return null;
		}
	}

	private function shouldSkipLib(k:Int, source:AssetSource)
	{
		return switch (source)
		{
			case BOTH: false;
			case SOURCE: k < libraries.length - __defaultLibraries.length;
			case MODS: k >= libraries.length - __defaultLibraries.length;
		};
	}

	public override function getAsset(id:String, type:String):Dynamic
		return getSpecificAsset(id, type, BOTH);

	public override function getFont(id:String):Font {
		var font = super.getFont(id);
		@:privateAccess if (font != null && !OpenFLFont.__fontByName.exists(font.name))
			OpenFLFont.registerFont(font);
		return font;
	}
}

enum abstract AssetSource(Null<Bool>) from Bool from Null<Bool> to Null<Bool>
{
	var SOURCE = true;
	var MODS = false;
	var BOTH = null;
}
