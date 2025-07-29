package game.objects;

import flixel.FlxCamera;
import flixel.system.FlxAssets.FlxGraphicAsset;
import flixel.util.FlxDestroyUtil;

import game.objects.FlxAnimate;

@:access(flxanimate.animate)
class FunkinSprite extends TwistSprite
{
	public var finishedAnim(get, never):Bool;
	@:noCompletion inline function get_finishedAnim():Bool
		return isAnimFinished();

	public var curAnimName(get, never):String;
	@:noCompletion inline function get_curAnimName():String
		return getAnimName();

	public var pausedAnim(get, never):Bool;
	function get_pausedAnim():Bool
	{
		if (useAtlas)
		{
			return (!animateAtlas.anim?.isPlaying) ?? true;
		}
		else
		{
			return animation.curAnim?.paused ?? true;
		}
	}

	public var curFrame(get, set):Int;
	function get_curFrame():Int
	{
		if (useAtlas)
		{
			return animateAtlas.anim?.curFrame ?? -1;
		}
		else
		{
			return animation.curAnim?.curFrame ?? -1;
		}
	}
	function set_curFrame(e):Int
	{
		if (useAtlas)
		{
			final anim = animateAtlas.anim;
			return (anim == null ? -1 : anim.curFrame = e);
		}
		else
		{
			final anim = animation.curAnim;
			return (anim == null ? -1 : anim.curFrame = e);
		}
	}

	public var curNumFrames(get, never):Int;
	function get_curNumFrames():Int
	{
		if (useAtlas)
		{
			return animateAtlas.anim?.length ?? -1;
		}
		else
		{
			return animation.curAnim?.numFrames ?? -1;
		}
	}

	// public override var numFrames(get, never):Int;
	// @:noCompletion function get_numFrames() return useAtlas ? 0 : frames?.numFrames ?? 0;
	public var animateAtlas(get, never):FlxAnimate;
	@:noCompletion inline function get_animateAtlas():FlxAnimate
		return this;

	public static function copyFrom(source:FunkinSprite)
	{
		final spr = new FunkinSprite();
		@:privateAccess {
			spr.setPosition(source.x, source.y);
			spr.frames = source.frames;
			spr.animation.copyFrom(source.animation);
			spr.visible = source.visible;
			spr.angle = source.angle;
			spr.alpha = source.alpha;
			spr.flipX = source.flipX;
			spr.flipY = source.flipY;
			spr.antialiasing = source.antialiasing;
			spr.scale.set(source.scale.x, source.scale.y);
			spr.scrollFactor.set(source.scrollFactor.x, source.scrollFactor.y);
			spr.skew.set(source.skew.x, source.skew.y);
			spr.blend = source.blend;
			spr.transformMatrix = source.transformMatrix;
			spr.matrixExposed = source.matrixExposed;
		}
		return spr;
	}

	public var flipOffsetX:Bool = false;
	public var flipOffsetY:Bool = false;
	public var altFlipX:Bool = false;
	public var altFlipY:Bool = false;
	public override function draw()
	{
		if (altFlipX || altFlipY || flipOffsetX || flipOffsetY)
		{
			final _flipX:Bool = flipX;
			final _flipY:Bool = flipY;
			final __drawX:Float = __drawingOffset.x;
			final __drawY:Float = __drawingOffset.y;
			final scaleX:Float = scale.x;
			final scaleY:Float = scale.y;
			final offsetX:Float = offset.x;
			final offsetY:Float = offset.y;
			if (flipOffsetX)
			{
				offset.x *= -1;
			}
			if (flipOffsetY)
			{
				offset.y *= -1;
			}
			if (altFlipX)
			{
				flipX = !flipX;
				scale.x *= -1;
				__drawingOffset.x *= -1;
			}
			if (altFlipY)
			{
				flipY = !flipY;
				scale.y *= -1;
				__drawingOffset.y *= -1;
			}
			super.draw();
			flipX = _flipX;
			flipY = _flipY;
			scale.set(scaleX, scaleY);
			__drawingOffset.set(__drawX, __drawY);
			offset.set(offsetX, offsetY);
		}
		else
			super.draw();
	}
}
