package game.objects;

import flixel.FlxCamera;
import flixel.addons.effects.FlxSkewedSprite;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxFrame.FlxFrameAngle;
import flixel.graphics.frames.FlxFrame;
import flixel.math.FlxAngle;
import flixel.math.FlxMatrix;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.system.FlxAssets.FlxGraphicAsset;
import flixel.system.FlxAssets.FlxShader;
import flixel.util.FlxDestroyUtil;
import flixel.util.FlxSignal;
import flixel.util.FlxStringUtil;

import flxanimate.FlxAnimate;

import haxe.io.Path;

import openfl.Assets;
import openfl.display.BlendMode;
import openfl.geom.ColorTransform;
import openfl.geom.Matrix;

@:access(flixel.animation)
@:access(flxanimate.animate)
class TwistSprite extends game.objects.FlxAnimate
{
	public var extraData(get, never):Dynamic; // lua hx lua hx lua hx others shits
	@:noCompletion var _extraData:Dynamic;
	@:noCompletion function get_extraData() {
		_extraData ??= {};
		return _extraData;
	}

	/*
	public var extraData(get, never):Map<String,Dynamic>; // lua hx lua hx lua hx others shits
	@:noCompletion var _extraData:Map<String,Dynamic>;
	@:noCompletion function get_extraData() {
		_extraData ??= new Map<String,Dynamic>();
		return _extraData;
	}
	*/

	public var animOffsets:Map<String, FlxPoint> = new Map<String, FlxPoint>();

	public var zoomFactor:Float = 1;
	public var initialZoom:Null<Float> = null;
	public var drawAlways:Bool = false;

	var __drawingOffset(default, null):FlxPoint = __zeroPoint;

	public function new(X:Float = 0, Y:Float = 0, ?SimpleGraphic:FlxGraphicAsset, ?Settings:Settings)
	{
		super(X, Y, SimpleGraphic, Settings);
		showMidPoint = false;
	}

	@:access(game.objects.TwistSprite)
	public static function copyFrom(source:TwistSprite)
	{
		final spr = new TwistSprite();
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
		spr.transformMatrix = source.transformMatrix;
		spr.matrixExposed = source.matrixExposed;
		return spr;
	}
	public override function loadAtlas(path:String)
	{
		super.loadAtlas(AssetsPaths.getPath("images/" + path));
	}

	@:deprecated('The loadAnimation method has been renamed to loadFrames')
	public inline function loadAnimation(path:String)
		loadFrames(path);

	public function loadFrames(path:String)
	{
		toggleAtlas = true;
		loadAtlas(path);
		if (!atlasIsValid)
		{
			toggleAtlas = false;
			frames = AssetsPaths.getFrames(path);
		}
	}

	public var frameOffsetAngle:Null<Float> = null;


	public override function draw()
	{
		checkClipRect();
		super.draw();
	}
	@:noCompletion
	override function drawComplex(camera:FlxCamera):Void
	{
		_frame.prepareMatrix(_matrix, FlxFrameAngle.ANGLE_0, checkFlipX(), checkFlipY());
		_matrix.translate(-origin.x, -origin.y);
		_matrix.scale(scale.x, scale.y);

		if (matrixExposed && transformMatrix != null)
		{
			_matrix.concat(transformMatrix);
			_matrix.translate(-__drawingOffset.x, -__drawingOffset.y);
		}
		else
		{
			if (bakedRotationAngle <= 0)
			{
				updateTrig();

				if (angle != 0)
					_matrix.rotateWithTrig(_cosAngle, _sinAngle);
			}
			updateSkewToMatrix(_matrix);

			if (frameOffsetAngle == null || frameOffsetAngle == angle)
			{
				_matrix.translate(-__drawingOffset.x, -__drawingOffset.y);
			}
			else
			{
				var angleOff = (-angle + frameOffsetAngle) * FlxAngle.TO_RAD;
				_matrix.rotate(angleOff);
				_matrix.translate(-__drawingOffset.x, -__drawingOffset.y);
				_matrix.rotate(-angleOff);
			}
		}

		getScreenPosition(_point, camera).subtractPoint(offset);
		_point.add(origin.x, origin.y);
		_matrix.translate(_point.x, _point.y);

		if (isPixelPerfectRender(camera))
		{
			_matrix.tx = Math.ffloor(_matrix.tx);
			_matrix.ty = Math.ffloor(_matrix.ty);
		}

		doAdditionalMatrixStuff(_matrix, camera);

		camera.drawPixels(_frame, framePixels, _matrix, colorTransform, blend, antialiasing, shader);
	}

	override function drawLimb(limb:FlxFrame, matrix:FlxMatrix, ?colorTransform:ColorTransform, ?filterin:Bool, ?blendMode:BlendMode, ?shader:FlxShader, ?cameras:Array<FlxCamera>)
	{
		if (/*colorTransform != null && (colorTransform.alphaMultiplier == 0 || colorTransform.alphaOffset == -255) ||*/ limb == null || limb.type == EMPTY)
			return;

		cameras ??= this.cameras;

		for (i => camera in cameras)
		{
			if (camera == null || !camera.visible || !camera.exists)
				return;

			limb.prepareMatrix(_matrix);
			_matrix.concat(matrix);

			if (!filterin)
			{
				_matrix.translate(-origin.x, -origin.y);

				_matrix.scale(scale.x, scale.y);

				if (bakedRotationAngle <= 0)
				{
					if (angle != 0)
						_matrix.rotateWithTrig(_cosAngle, _sinAngle);
				}

				if (matrixExposed && transformMatrix != null)
				{
					_matrix.concat(transformMatrix);
					_matrix.translate(-__drawingOffset.x, -__drawingOffset.y);
				}
				else
				{
					if (bakedRotationAngle <= 0)
					{
						updateTrig();

						if (angle != 0)
							_matrix.rotateWithTrig(_cosAngle, _sinAngle);
					}
					updateSkewToMatrix(_matrix);

					if (frameOffsetAngle == null || frameOffsetAngle == angle)
					{
						_matrix.translate(-__drawingOffset.x, -__drawingOffset.y);
					}
					else
					{
						var angleOff = (-angle + frameOffsetAngle) * FlxAngle.TO_RAD;
						_matrix.rotate(angleOff);
						_matrix.translate(-__drawingOffset.x, -__drawingOffset.y);
						_matrix.rotate(-angleOff);
					}
				}

				_matrix.translate(_camerasCashePoints[i].x, _camerasCashePoints[i].y);

				doAdditionalMatrixStuff(_matrix, camera);

				if (isPixelPerfectRender(camera))
				{
					_matrix.tx = Math.ffloor(_matrix.tx);
					_matrix.ty = Math.ffloor(_matrix.ty);
				}

				if (!limbOnScreen(limb, _matrix, camera))
					continue;
				#if FLX_DEBUG
				FlxBasic.visibleCount++;
				#end
			}
			camera.drawPixels(limb, null, _matrix, colorTransform, blendMode, filterin || antialiasing, shader);
		}
	}

	override function updateSkewMatrix():Void
	{
		final _skewMatrix = FlxAnimate._skewMatrix;
		_skewMatrix.identity();
		if (skew.x != 0 || skew.y != 0)
		{
			_skewMatrix.b = Math.tan(skew.y * FlxAngle.TO_RAD);
			_skewMatrix.c = Math.tan(-skew.x * FlxAngle.TO_RAD);
		}
	}

	/**
	 * Made in case developer wanna finalize stuff with the matrix.
	*/
	public function doAdditionalMatrixStuff(matrix:FlxMatrix, camera:FlxCamera)
	{
		if (__shouldDoScaleProcedure())
		{
			matrix.translate(-camera.origin.x, -camera.origin.y);

			var diff = FlxMath.lerp(initialZoom ?? camera.initialZoom, camera.zoom, zoomFactor) / camera.zoom;
			matrix.scale(diff, diff);
			matrix.translate(camera.origin.x, camera.origin.y);
		}
	}

	public override function destroy()
	{
		transformMatrix = null;

		if (animOffsets != null)
		{
			for (_ => e in animOffsets)
				e.put();
			// animOffsets.clear();
			animOffsets = null;
		}
		super.destroy();
	}

	public var atlasPlayingAnim(get, set):String;
	inline function get_atlasPlayingAnim()
		return anim.curAnimName;
	inline function set_atlasPlayingAnim(i:String)
		return anim.curAnimName = i;

	// ANIMS
	public function playAnim(AnimName:String, Force:Bool = false, Reversed:Bool = false, Frame:Int = 0):Bool
	{
		if (AnimName == null)
			return false;
		if (useAtlas)
		{
			if (anim.existsByName(AnimName) || anim.symbolDictionary.exists(AnimName))
				anim.play(AnimName, Force, Reversed, Frame);
			else
				return false;
		}
		else
		{
			if (animation.exists(AnimName))
				animation.play(AnimName, Force, Reversed, Frame);
			else
				return false;
		}
		updateAnimOffsets();
		return true;
	}

	static var __zeroPoint(get, null):FlxPoint = new FlxPoint();
	@:noCompletion static inline function get___zeroPoint():FlxPoint return __zeroPoint.set();
	public function updateAnimOffsets(?anotherAnim:String)
	{
		anotherAnim ??= getAnimName();
		__drawingOffset = getAnimOffset(anotherAnim);
	}

	public function getAnimOffset(name:String):FlxPoint
		return animOffsets.get(name) ?? __zeroPoint;

	public function hasAnimation(AnimName:String):Bool
		return useAtlas ? (anim.existsByName(AnimName)/*
			|| anim.symbolDictionary.exists(AnimName)*/) : animation.exists(AnimName);

	public function getAnimName()
		return useAtlas ? atlasPlayingAnim : animation.curAnim?.name;

	public function addOffset(name:String, x:Float = 0, y:Float = 0)
	{
		if (animOffsets.exists(name))
		{
			animOffsets[name].set(x, y);
		}
		else
		{
			animOffsets[name] = FlxPoint.get(x, y);
		}
	}

	public function switchOffset(anim1:String, anim2:String)
	{
		final old = animOffsets[anim1];
		animOffsets[anim1] = animOffsets[anim2];
		animOffsets[anim2] = old;
	}

	public function addAllAnimations()
	{
		if (useAtlas)
		{
			// idk
		}
		else
		{
			CoolUtil.tryExportAllAnimsFromXmlFlxSprite(this);
		}
	}

	public function addAnimation(Name:String, Prefix:String, Indices:Array<Int> = null, Offsets:Array<Float> = null, FrameRate:Float = 24,
		LoopPoint:Int = 0, Looped:Bool = false, FlipX:Bool = false, FlipY:Bool = false)
	{
		if (useAtlas)
		{
			anim.addAnimation(Name, Prefix, FrameRate, Looped, Indices);
		}
		else
		{
			if (Indices == null || Indices.length == 0)
				animation.addByPrefix(Name, Prefix, 24, Looped, FlipX, FlipY);
			else
				animation.addByIndices(Name, Prefix, Indices, "", 24, Looped, FlipX, FlipY);
		}
		updateDeAnimation(Name, LoopPoint, FrameRate, FlipX, FlipY, useAtlas);
		if (Offsets != null && Offsets.length > 1)
			addOffset(Name, Offsets[0], Offsets[1]);
	}

	public function updateDeAnimation(anim:String, loopPoint:Int, fps:Float, flipX:Bool, flipY:Bool, ?isAtlas:Bool)
	{
		if (isAtlas)
		{
			// idk
			final anim = this.anim.getByName(anim);
			if (anim != null)
			{
				anim.loopPoint = loopPoint;
				anim.instance.flipX = flipX;
				anim.instance.flipY = flipY;
				anim.frameRate = fps;
			}
			// if (anim.symbolDictionary.exists(anim)){
			// 	final symbol = anim.symbolDictionary.get(anim);
			// 	symbol.loopPoint = loopPoint;
			// }
		}
		else
		{
			final anim = animation.getByName(anim);
			if (anim != null)
			{
				anim.flipX = flipX;
				anim.flipY = flipY;
				anim.frameRate = fps;
				anim.loopPoint = loopPoint;
			}
		}
	}

	// Draw Offsets overrides
	@:noCompletion override function drawSimple(camera:FlxCamera):Void
	{
		__add__drawing__offset(); // add them to the current one's
		super.drawSimple(camera); // draw sprite
		__remove__drawing__offset(); // revert
	}

	public override function getScreenBounds(?newRect:FlxRect, ?camera:FlxCamera):FlxRect
	{
		camera ??= FlxG.camera;

		__add__drawing__offset();
		__doPreZoomScaleProcedure(camera);
		newRect = _getScreenBounds(newRect, camera);
		__doPostZoomScaleProcedure();
		__remove__drawing__offset();
		return newRect;
	}

	public override function isOnScreen(?camera:FlxCamera):Bool
	{
		return drawAlways || super.isOnScreen(camera); // i'm lazy ass to fix zoomFactor
	}

	@:noCompletion extern inline function _getScreenBounds(?newRect:FlxRect, ?camera:FlxCamera):FlxRect
	{
		newRect ??= FlxRect.get();

		newRect.setPosition(x, y);
		if (pixelPerfectPosition)
			newRect.floor();
		_scaledOrigin.set(origin.x * Math.abs(scale.x), origin.y * Math.abs(scale.y)); // Fix negative scale visible
		newRect.x += -Std.int(camera.scroll.x * scrollFactor.x) - offset.x + origin.x - _scaledOrigin.x;
		newRect.y += -Std.int(camera.scroll.y * scrollFactor.y) - offset.y + origin.y - _scaledOrigin.y;
		if (isPixelPerfectRender(camera))
			newRect.floor();
		newRect.setSize(frameWidth * Math.abs(scale.x), frameHeight * Math.abs(scale.y));
		return newRect.getRotatedBounds(angle, _scaledOrigin, newRect);
	}

	private inline function __shouldDoScaleProcedure()
		return zoomFactor != 1;

	static var __oldScrollFactor:FlxPoint = new FlxPoint();
	// static var __oldPos:FlxPoint = new FlxPoint();
	static var __oldScale:FlxPoint = new FlxPoint();
	var __skipZoomProcedure:Bool = false;

	private function __doPreZoomScaleProcedure(Camera:FlxCamera)
	{
		if (__skipZoomProcedure = !__shouldDoScaleProcedure())
			return;
		__oldScale.set(scale.x, scale.y);

		__oldScrollFactor.set(scrollFactor.x, scrollFactor.y);
		scrollFactor.scale(1 / FlxMath.lerp(initialZoom ?? Camera.initialZoom, Camera.zoom, zoomFactor) * Camera.zoom);

		scale.scale(1 / FlxMath.lerp(initialZoom ?? Camera.initialZoom, Camera.zoom, zoomFactor) * Camera.zoom);
	}

	private function __doPostZoomScaleProcedure()
	{
		if (__skipZoomProcedure)
			return;
		scale.set(__oldScale.x, __oldScale.y);
		scrollFactor.set(__oldScrollFactor.x, __oldScrollFactor.y);
	}

	public override function getScreenPosition(?point:FlxPoint, ?Camera:FlxCamera):FlxPoint
	{
		if (__shouldDoScaleProcedure())
		{
			Camera ??= FlxG.camera;
			__oldScrollFactor.set(scrollFactor.x, scrollFactor.y);
			scrollFactor.scale(1 / FlxMath.lerp(initialZoom ?? Camera.initialZoom, Camera.zoom, zoomFactor) * Camera.zoom);

			point = super.getScreenPosition(point, Camera);

			scrollFactor.set(__oldScrollFactor.x, __oldScrollFactor.y);

			return point;
		}
		return super.getScreenPosition(point, Camera);
	}

	public override function transformWorldToPixelsSimple(worldPoint:FlxPoint, ?result:FlxPoint):FlxPoint
	{
		__add__drawing__offset();
		result = super.transformWorldToPixelsSimple(worldPoint, result);
		__remove__drawing__offset();
		return result;
	}

	public override function transformScreenToPixels(screenPoint:FlxPoint, ?camera:FlxCamera, ?result:FlxPoint):FlxPoint
	{
		__add__drawing__offset();
		result = super.transformScreenToPixels(screenPoint, camera, result);
		__remove__drawing__offset();
		return result;
	}

	@:noCompletion extern inline function __add__drawing__offset()
	{
		// if (__drawingOffset != null)
			offset.add(__drawingOffset.x, __drawingOffset.y);
	}

	@:noCompletion extern inline function __remove__drawing__offset()
	{
		// if (__drawingOffset != null)
			offset.subtract(__drawingOffset.x, __drawingOffset.y);
	}

	public function removeAnimation(name:String)
	{
		if (useAtlas)
			anim.animsMap.remove(name);
		else
			animation.remove(name);
	}

	public function getNameList():Array<String>
	{
		return (useAtlas ? [for (name in anim.animsMap.keys()) name] : animation.getNameList());
	}

	public function resumeAnimation()
	{
		if (useAtlas)
			anim.resume();
		else
			animation.resume();
	}

	public function pauseAnimation()
	{
		if (useAtlas)
			anim.pause();
		else
			animation.pause();
	}

	public function stopAnimation()
	{
		if (useAtlas)
			anim.stop();
		else
			animation.stop();
	}

	public function isAnimFinished():Bool
		return useAtlas ? anim.finished : (animation.curAnim?.finished ?? true);

	public override function toString():String
	{
		return FlxStringUtil.getDebugString([
			LabelValuePair.weak("x", x),
			LabelValuePair.weak("y", y),
			LabelValuePair.weak("w", width),
			LabelValuePair.weak("h", height),
			LabelValuePair.weak("visible", visible),
			LabelValuePair.weak("velocity", velocity),
			LabelValuePair.weak("animOffset", __drawingOffset),
			LabelValuePair.weak("offsets", offset)
		]);
	}
}
