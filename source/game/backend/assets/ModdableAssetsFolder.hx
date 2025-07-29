package game.backend.assets;

import lime.utils.AssetLibrary;

#if sys
/**
 * Used to prevent crashes
 */
class ModdableAssetsFolder extends ModsFolderLibrary {
	public var oldLibrary:AssetLibrary;

	public override function exists(id:String, type:String)
		return id.startsWith("assets/") || exists('assets/$id', type) ? super.exists(id, type) : oldLibrary.exists(id, type);

	public override function getAsset(id:String, type:String):Dynamic {
		if (id.startsWith("assets/"))
			return super.getAsset(id, type);
		var possibleReplacement = getAsset('assets/$id', type);
		return possibleReplacement == null ? oldLibrary.getAsset(id, type) : possibleReplacement;
	}

	public function new(folder:String, libName:String, oldLib:AssetLibrary)
	{
		super(folder, libName);
		oldLibrary = oldLib;
		trace(Type.getClassName(Type.getClass(oldLibrary)));
	}

	#if MODS_ALLOWED
	private override function __parseAsset(asset:String):Bool {
		var prefix = 'assets/';
		if (!asset.startsWith(prefix)) return false;
		_parsedAsset = asset.substr(prefix.length);
		return true;
	}
	#end
}
#end