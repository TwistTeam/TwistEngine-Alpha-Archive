package game.backend.utils;

import game.states.playstate.PlayState;

class Difficulty
{
	public static final defaultList = [
		// "Easy",
		"Normal",
		// "Hard"
	];
	public static var list:Array<String> = null;
	public static final defaultDifficulty = "Normal"; // The chart that has no suffix and starting difficulty on Freeplay/Story Mode

	public static function getFilePath(?str:String):String
	{
		if (str == null)
			return "";
		// str = PlayState.storyDifficulty;
		str = str.trim();
		return str.length == 0 || str == getDefault() ? "" : Paths.formatToSongPath("-" + str);
	}

	public static function resetList()
	{
		if (list == null)
			list = [];
		else
			__copy__helper(list, defaultList);
	}

	public static function copyFrom(diffs:Array<String>)
	{
		list ??= [];
		__copy__helper(list, diffs);
	}

	public static function getString(?num:Int):String
	{
		return list == null ? getDefault() : list[num ?? PlayState.storyDifficulty];
	}

	public static inline function getDefault():String
	{
		return defaultDifficulty;
	}

	extern static inline function __copy__helper(__to:Array<String>, __from:Array<String>)
	{
		__to.resize(__from.length);
		for (__i => __item in __from)
			__to[__i] = __item;
	}

	public static function getDifficultyFromFullPath(path:String):String
	{
		var indexData:Int = path.lastIndexOf(Constants.SONG_CHART_FILES_FOLDER + "/");
		if (indexData == -1)
			return null;

		var shorterPath:String = path.substring(indexData + Constants.SONG_CHART_FILES_FOLDER.length + 1, path.length);
		indexData = shorterPath.indexOf("/");
		if(indexData == -1)
			return null;

		var song:String = shorterPath.substring(0, indexData);
		var _regex:EReg = new EReg('$song\\/$song([-a-z]+)(.json)?$', "i"); // todo: check for equality of song titles in rereg?
		if (!_regex.match(shorterPath))
			return null;

		return _regex.matched(1).substring(1);
	}
}