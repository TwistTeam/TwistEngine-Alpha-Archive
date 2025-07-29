package game.objects;

import flixel.FlxSprite;
import flixel.math.FlxPoint;

class FlxExtendedSprite extends FlxSprite
{
	public var extraData(get, never):Dynamic; // lua hx lua hx lua hx others shits
	public var onGraphicLoaded:() -> Void;

	@:noCompletion var _extraData:Dynamic;

	@:noCompletion function get_extraData()
	{
		return _extraData ??= {};
	}

	public override function destroy()
	{
		_extraData = null;
		onGraphicLoaded = null;
		super.destroy();
	}

	public override function graphicLoaded():Void
	{
		if (onGraphicLoaded != null)
			onGraphicLoaded();
	}

	public function setScale(?X:Float, ?Y:Float):FlxPoint
		return X == null && Y == null ? scale : scale.set(X ?? Y, Y ?? X);
}
