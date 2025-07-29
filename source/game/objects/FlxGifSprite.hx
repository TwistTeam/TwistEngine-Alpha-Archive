package game.objects;

class FlxGifSprite extends flixel.FlxSprite
{
	public function new(gifFile:String, X:Float = 0, Y:Float = 0, ?useCustomFps:Null<Float> = null, ?looped:Bool = true)
	{
		super(X, Y);
		#if yagp
		frames = Paths.getGifAtlas(gifFile, useCustomFps == null);
		animation.addByPrefix('main', haxe.io.Path.withoutDirectory(gifFile), useCustomFps == null ? 24 : useCustomFps, looped);
		animation.play('main');
		#end
	}
}
