package game.backend;

class ShaderResizeFix
{
	public static var doResizeFix:Bool = true;

	public static function init() {
		FlxG.signals.gameResized.add((w:Int, h:Int) -> fixSpritesShadersSizes());
		// FlxG.signals.postStateSwitch.add(fixSpritesShadersSizes);
	}

	public static function fixSpritesShadersSizes() {
		if (!doResizeFix) return;

		fixSpriteShaderSize(FlxG.game);

		for (cam in FlxG.cameras.list) {
			fixSpriteShaderSize(cam?.flashSprite);
		}
	}

	@:access(openfl.display.DisplayObject)
	@:access(openfl.display.BitmapData)
	public static inline function fixSpriteShaderSize(sprite:openfl.display.DisplayObject)
	{
		if (sprite == null || !sprite.cacheAsBitmap) return;

		function dispose(bitmapData:openfl.display.BitmapData)
		{
			if (bitmapData != null)
			{
				bitmapData.fullDispose();
			}
			return null;
		}
		sprite.__cacheBitmapData = dispose(sprite.__cacheBitmapData);
		sprite.__cacheBitmapData2 = dispose(sprite.__cacheBitmapData2);
		sprite.__cacheBitmapData3 = dispose(sprite.__cacheBitmapData3);
	}
}