package game.backend.utils;

class PathUtil
{
	@:noUsing public static function directory(path:String)
	{
		return path.substring(0, path.lastIndexOf("/"));
	}
	@:noUsing public static function extension(path:String):String
	{
		var cp = path.lastIndexOf(".");
		return cp == -1 ? null : path.substring(cp + 1);
	}
	@:noUsing public static function withoutExtension(path:String):String
	{
		var cp = path.lastIndexOf(".");
		return cp == -1 ? path : path.substring(0, cp);
	}
}