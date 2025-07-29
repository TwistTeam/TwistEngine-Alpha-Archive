package game.backend.assets;

import flixel.util.FlxSignal;
import game.backend.utils.PathUtil;
import haxe.io.Path;
import lime.text.Font;
import lime.utils.AssetLibrary as LimeAssetLibrary;
import openfl.text.Font as OpenFLFont;
import openfl.utils.AssetLibrary;
import openfl.utils.AssetManifest;
#if sys
import sys.FileSystem;
import sys.io.File;
#end

class ModsFolder {
	/**
	 * INTERNAL - Only use when editing source mods!!
	 */
	public static var onModSwitch:FlxTypedSignal<String->Void> = new FlxTypedSignal<String->Void>();

	/**
	 * All availables mods.
	*/
	public static var listMods:Array<String> = [];

	/**
	 * Map mods with availables mods librares.
	*/
	public static var libsMods:Map<String, lime.utils.AssetLibrary> = [];

	/**
	 * Current mod folder. Will affect `Paths`.
	*/
	public static var currentModFolder(default, null):String = null;

	public static function setCurrentModFolder(path:String){
		currentModFolder = Path.withoutDirectory(path);
		path ??= "assets";
		currentModFolderPath = path;
		#if sys
		currentModFolderAbsolutePath = FileSystem.absolutePath(path);
		#else
		currentModFolderAbsolutePath = path;
		#end
	}
	/**
	  * Current path mod folder. Will affect `Paths`.
	*/
	public static var currentModFolderPath(default, null):String = "";
	/**
	  * Current absolute path mod folder. Will affect `Paths`.
	*/
	public static var currentModFolderAbsolutePath(default, null):String = "";

	/**
	 * Path to the `mods` folder.
	 */
	public static var modsPath:String = Constants.MODS_PATH;

	/**
	 * If accessing a file as assets/data/global/LIB_mymod.hx should redirect to mymod:assets/data/global.hx
	 */
	public static var useLibFile:Bool = false;

	/**
	 * Whenever its the first time mods has been reloaded.
	 */
	private static var __firstTime:Bool = true;

	/**
	 * Initialises `mods` folder by adding callbacks and such.
	 */
	public static function init() { }

	public static function updateModsList() {
		listMods.clearArray();
		for(i in libsMods)
			if (i != null)
				i.unload();
		libsMods.clear();
		listMods = getModDirectories();
		for (i in listMods) libsMods.set(i, loadModLib(i, true, i));
	}

	/**
	 * Load first mod of listMods.
	 * @param mod
	*/
	public static function loadTopMod(?triggerSignal:Bool = true) {
		if (listMods[0] != null) switchMod(listMods[0], triggerSignal);
	}

	/**
	 * Switches mod - unloads all the other mods, then load this one.
	 * @param mod
	 */
	public static function switchMod(mod:String, ?triggerSignal:Bool = true) {
		if (currentModFolderPath == mod) return;
		setCurrentModFolder(/* Options.lastLoadedMod = */ mod);
		reloadMods();
		if (triggerSignal)
			onModSwitch.dispatch(mod);
	}

	public static function reloadMods() {
		// if (!__firstTime)
		// 	FlxG.switchState(new game.backend.system.MainState());
		__firstTime = false;
		AssetsPaths.assetsTree.reset();
		if (currentModFolderPath != null && libsMods.exists(currentModFolderPath))
			AssetsPaths.assetsTree.addLibrary(libsMods.get(currentModFolderPath));
	}

	/**
	 * Loads a mod library from the specified path. Supports folders and zips.
	 * @param force Whenever the mod should be reloaded if it has already been loaded
	 * @param modName Name of the mod
	 */
	public static function loadModLib(path:String, force:Bool = false, ?modName:String) {
		#if MODS_ALLOWED
		#if ZIPLIBS_ALLOWED
		if (FileSystem.exists('$path.zip'))
			return loadLibraryFromZip(path.toLowerCase(), '$path.zip', force, modName);
		else
		#end
			return loadLibraryFromFolder(path.toLowerCase(), path, force, modName);
		#else
		return null;
		#end
	}

	public static function getLoadedMods():Array<String> {
		var libs = [];
		for (i in AssetsPaths.assetsTree.libraries) {
			var l = i;
			if (l is openfl.utils.AssetLibrary) {
				var al = cast(l, openfl.utils.AssetLibrary);
				@:privateAccess
				if (al.__proxy != null) l = al.__proxy;
			}
			var libString:String;
			if (/*l is ScriptedAssetLibrary ||*/ l is IModsAssetLibrary) libString = cast(l, IModsAssetLibrary).modName;
			else continue;
			libs.push(libString);
		}
		return libs;
	}

	public static function getModsFolders():Array<String>
	{
		var paths:Array<String> = [];
		#if MODS_ALLOWED
		if (FileSystem.exists(Constants.MODSLIST_FILE))
		{
			for (i in File.getContent(Constants.MODSLIST_FILE).listFromString())
			{
				if (i.length == 0 || i.startsWith("//")) continue;
				if (i.endsWith("*")) // accept /*
				{
					i = i.substr(0, i.length - 2);
					if(FileSystem.exists(i) && FileSystem.isDirectory(i))
						for (modFolder in FileSystem.readDirectory(i))
							paths.push(i + "/" + modFolder);
				}
				else
				{
					// if(FileSystem.exists(i) && FileSystem.isDirectory(i))
						paths.push(i);
				}
			}
			// FileSystem.absolutePath(i)
		}
		else
		{
			paths.push(modsPath);
		}
		#end
		return paths;
	}

	public static function getModDirectories():Array<String> {
		var list = new Array<String>();
		#if MODS_ALLOWED
		for (modsPath in getModsFolders()){
			if (!modsPath.endsWith("/"))
				modsPath = modsPath + "/";
			modsPath = Path.normalize(modsPath);
			if (!list.contains(modsPath))
			{
				if (FileSystem.isDirectory(modsPath))
					list.push(modsPath);
				else switch(PathUtil.extension(modsPath)?.toLowerCase()){
					case "zip":
						// is a zip mod!!
						list.push(PathUtil.withoutExtension(modsPath));
				}
			}
		}
		#end
		// trace(list);
		return list;
	}
	public static function prepareLibrary(libName:String, force:Bool = false):#if (java && lime) LimeAssetLibrary #else AssetLibrary #end {
		var assets:AssetManifest = new AssetManifest();
		assets.name = libName;
		assets.version = 2;
		assets.libraryArgs = [];
		assets.assets = [];

		return AssetLibrary.fromManifest(assets);
	}

	public static function registerFont(font:Font) {
		var openflFont = new OpenFLFont();
		@:privateAccess
		openflFont.__fromLimeFont(font);
		OpenFLFont.registerFont(openflFont);
		return font;
	}

	public static function prepareModLibrary(libName:String, lib:IModsAssetLibrary, force:Bool = false) {
		var openLib = prepareLibrary(libName, force);
		lib.prefix = "assets/";
		@:privateAccess
		openLib.__proxy = cast lib;
		return openLib;
	}

	public static function loadLibraryFromFolder(libName:String, folder:String, force:Bool = false, ?modName:String)
		return prepareModLibrary(libName, new ModsFolderLibrary(folder, libName, modName), force);
	#if ZIPLIBS_ALLOWED
	public static function loadLibraryFromZip(libName:String, zipPath:String, force:Bool = false, ?modName:String)
	{
		// trace(libName, zipPath);
		return prepareModLibrary(libName, new ZipFolderLibrary(zipPath, libName, modName), force);
	}
	#end
}