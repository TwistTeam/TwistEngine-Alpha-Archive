package game.backend.utils;

import flixel.util.FlxTimer;
import flixel.tweens.FlxTween;
import flixel.util.FlxAxes;

@:access(flixel.FlxSprite)
class FlxObjectTools
{
	public static inline function cancelTween<T:FlxTween>(tween:T):T
	{
		tween?.cancel();
		return tween;
	}

	public static function followSpr(spr:FlxSprite, target:FlxSprite, x:Float = 0, y:Float = 0)
	{
		spr.cameras = target.cameras;
		spr.setPosition(target.x + x, target.y + y);
		spr.scrollFactor.set(target.scrollFactor.x, target.scrollFactor.y);
	}

	public static function makeSolid<T:FlxSprite>(sprite:T, width:Float, height:Float, color:FlxColor = FlxColor.WHITE):T
	{
		sprite.makeGraphic(1, 1, color);
		// sprite.setGraphicSize(Std.int(width),Std.int(height));
		sprite.setGraphicSize(width, height);
		sprite.updateHitbox();
		return sprite;
	}

	public static inline function loadFrames<T:FlxSprite>(sprite:T, image:String, ?lib:String):T
	{
		sprite.frames = Paths.getSparrowAtlas(image, lib);
		return sprite;
	}

	public static function precache<T:FlxSprite>(sprite:T):T
	{
		final originalAlpha = sprite.alpha;
		sprite.alpha = 0.00001;
		if (sprite.isSimpleRender(FlxG.camera))
			sprite.drawSimple(FlxG.camera);
		else
			sprite.drawComplex(FlxG.camera);
		sprite.alpha = originalAlpha;
		return sprite;
	}

	/**
	 * persistent draw hide
	 */
	public static inline function hide<T:FlxSprite>(sprite:T):T
	{
		sprite.alpha = 0.000000001;
		return sprite;
	}

	/**
	 * applies shader to sprite BUT checks if its allowed to.
	 * @param useFramePixel prevents frame clipping on shader usage.
	 */
	public static inline function applyShader<T:FlxSprite>(sprite:T, shader:flixel.system.FlxAssets.FlxShader, useFramePixel = false):T
	{
		// if (!ClientPrefs.shaders) return sprite;
		sprite.useFramePixels = useFramePixel;
		sprite.shader = shader;
		return sprite;
	}

	public static inline function setScale<T:FlxSprite>(sprite:T, scaleX:Float, ?scaleY:Null<Float>, ?updatehitbox = true):T
	{
		scaleY ??= scaleX;

		sprite.scale.set(scaleX, scaleY);
		if (updatehitbox)
			sprite.updateHitbox();
		return sprite;
	}

	public static inline function centerOnSprite<T:FlxSprite>(follower:T, target:FlxSprite, axes:FlxAxes = XY):T
	{
		if (axes.x)
			follower.x = target.x + (target.width - follower.width) / 2;
		if (axes.y)
			follower.y = target.y + (target.height - follower.height) / 2;

		return follower;
	}

	public static inline function screenAlignment<T:FlxSprite>(sprite:T, alignment:SpriteAlignment):T
	{
		switch (alignment)
		{
			case TOPLEFT:
				sprite.setPosition();
			case TOPMID:
				sprite.screenCenter(X).y = 0;
			case TOPRIGHT:
				sprite.setPosition(FlxG.width - sprite.width, 0);
			case MIDLEFT:
				sprite.screenCenter(Y).x = 0;
			case MIDDLE:
				sprite.screenCenter();
			case MIDRIGHT:
				sprite.screenCenter(Y).x = FlxG.width - sprite.width;
			case BOTTOMLEFT:
				sprite.setPosition(0, FlxG.height - sprite.height);
			case BOTTOMMID:
				sprite.screenCenter(X).y = FlxG.height - sprite.height;
			case BOTTOMRIGHT:
				sprite.setPosition(FlxG.width - sprite.width, FlxG.height - sprite.height);
		}
		return sprite;
	}

	//-----------animShortcuts-----------//

	public static inline function addAnimByPrefix<T:FlxSprite>(sprite:T, name:String, prefix:String, fps:Int = 24, looped:Bool = true):T
	{
		sprite.animation.addByPrefix(name, prefix, fps, looped);
		return sprite;
	}

	public static inline function playAnim<T:FlxSprite>(sprite:T, name:String, forced:Bool = true):T
	{
		sprite.animation.play(name, forced);
		return sprite;
	}

	public static inline function getCurAnimName(sprite:FlxSprite):String
		return sprite.animation.curAnim.name;
}

enum SpriteAlignment
{
	TOPLEFT;
	TOPMID;
	TOPRIGHT;
	MIDLEFT;
	MIDDLE;
	MIDRIGHT;
	BOTTOMLEFT;
	BOTTOMMID;
	BOTTOMRIGHT;
}
