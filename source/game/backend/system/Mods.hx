package game.backend.system;

/*
import haxe.io.Path;
import game.backend.assets.ModsFolder;

#if sys
import sys.FileSystem;
import sys.io.File;
#end

typedef ModsList = {
	enabled:Array<String>,
	disabled:Array<String>,
	all:Array<String>
}

class Mods
{
	public static var modsMode(default, null):Bool = false; 
	public static var currentModDirectory(default, set):String = '';
	inline static function set_currentModDirectory(e:String):String{
		// modsMode = Paths.getSharedPath().indexOf(e) == -1;
		currentModDirectory = e.trim();
		if (currentModDirectory == '') currentModDirectory = null;
		return currentModDirectory;
	}

	// public static var langGlobalFolder = "";
	public static var currentLevel(default, set):String;
	inline static function set_currentLevel(name:String):String return currentLevel = name.toLowerCase();

	public inline static function setCurrentLevel(name:String) return currentLevel = name;

	public static var ignoreModFolders:Array<String> = [
		#if ACHIEVEMENTS_ALLOWED 'achievements', #end
		'characters',
		'custom_events',
		'custom_notetypes',
		'data',
		'fonts',
		'images',
		'songs',
		'music',
		'scripts',
		'sounds',
		'shaders',
		'stages',
		'videos',
		'weeks'
	];

	private static var globalMods:Array<String> = [];
	inline public static function getGlobalMods():Array<String> return globalMods;

	public static function pushGlobalMods(){ // prob a better way to do this but idc
		globalMods.clearArray();
		for (mod in parseList().enabled){
			final pack:Dynamic = getPack(mod);
			if (pack != null && pack.runsGlobally) globalMods.push(mod);
		}
		return globalMods;
	}

	public static function getModDirectories():Array<String>
		return ModsFolder.getModDirectories();
	
	public static function mergeAllTextsNamed(path:String, ?defaultDirectory:String, allowDuplicates:Bool = false)
	{
		if (defaultDirectory == null) defaultDirectory = Paths.getSharedPath();
		defaultDirectory = defaultDirectory.trim();
		if (!defaultDirectory.endsWith('/')) defaultDirectory += '/';
		if (!defaultDirectory.startsWith('assets/')) defaultDirectory = 'assets/$defaultDirectory';

		final mergedList:Array<String> = [];
		final paths:Array<String> = directoriesWithFile(defaultDirectory, path);

		final defaultPath:String = defaultDirectory + path;
		if(paths.contains(defaultPath))
		{
			paths.remove(defaultPath);
			paths.insert(0, defaultPath);
		}

		for (file in paths)
		{
			final list:Array<String> = CoolUtil.coolTextFile(file);
			for (value in list)
				if ((allowDuplicates || !mergedList.contains(value)) && value.length > 0)
					mergedList.push(value);
		}
		return mergedList;
	}

	public static function directoriesWithFile(path:String, fileToFind:String, mods:Bool = true)
	{
		final foldersToCheck:Array<String> = [];
		foldersToCheck.push(path + fileToFind);

		return foldersToCheck;
	}

	public static function getPack(?folder:String):Dynamic
	{
		#if MODS_ALLOWED
		if (folder == null) folder = currentModDirectory;

		final path = Paths.mods(folder + '/pack.json');
		if(FileSystem.exists(path)) {
			try{
				final rawJson:String = lime.utils.Assets.getText(path);
				if (rawJson != null && rawJson.length > 0) return haxe.Json.parse(rawJson);
			}catch(e:Dynamic){
				trace(e);
			}
		}
		#end
		return null;
	}

	public static var updatedOnState:Bool = false;
	public static var list:ModsList = {enabled: [], disabled: [], all: []};
	public static function parseList():ModsList{
		if (!updatedOnState) updateModList();
		list.enabled = [];
		list.disabled = [];

		trace(list);
		return list;
	}
	
	private static function updateModList()
	{
		list.all = getModDirectories();
		updatedOnState = true;
	}

	public static function loadTopMod()
	{
		currentModDirectory = '';
		#if MODS_ALLOWED
		final list:Array<String> = parseList().enabled;
		if (list != null && list[0] != null) currentModDirectory = list[0];
		#end
	}
}
*/