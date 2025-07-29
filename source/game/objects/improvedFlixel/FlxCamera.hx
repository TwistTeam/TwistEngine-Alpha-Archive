package game.objects.improvedFlixel;

#if macro
import haxe.macro.*;
#else

import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxFrame;
import flixel.graphics.tile.FlxDrawTrianglesItem;
import flixel.math.FlxMath;
import flixel.math.FlxMatrix;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.system.FlxAssets.FlxShader;
import flixel.util.FlxArrayUtil;
import flixel.util.FlxDestroyUtil;

import game.shaders.RuntimeCustomBlendShader;
import game.backend.utils.BitmapDataUtil;

import openfl.Lib;
import openfl.display.BitmapData;
import openfl.display.BlendMode;
import openfl.display.Graphics;
import openfl.display.Sprite;
import openfl.display3D.textures.TextureBase;
import openfl.filters.BitmapFilter;
import openfl.filters.ShaderFilter;
import openfl.geom.ColorTransform;
import openfl.geom.Matrix;
import openfl.geom.Point;
import openfl.geom.Rectangle;

import lime.app.Application;

/**
 * This camera supports blendmodes, unlike VSlice's current FunkinCamera.
 *
 * WARNING: Blendmodes doesn't work correctly with `widescreen`.
 *
 * Fix angle by RichTrash21
 * WideScreen grabbed from YoshiCrafter flixel
 */
@:access(flixel.graphics.FlxGraphic)
@:access(flixel.graphics.frames.FlxFrame)
@:access(game.backend.utils.BitmapDataUtil)
@:access(openfl.display.BitmapData)
@:access(openfl.display.DisplayObject)
@:access(openfl.display3D.Context3D)
@:access(openfl.display3D.textures.TextureBase)
class FlxCamera extends flixel.FlxCamera
{
	/**
	 * Widescreen dimensions multipliers
	 * For example, if the camera is in widescreen mode and the game is in 1920x720 while the camera is in 1280x720,
	 * the value will be equal to `new FlxPoint(1.5, 1);`.
	 */
	public var widescreenMultipliers(default, null):FlxPoint = FlxPoint.get(0, 0);

	/**
	 * Whenever the camera should be widescreen or not.
	 *  ̶I̶f̶ ̶n̶u̶l̶l̶,̶ ̶w̶i̶l̶l̶ ̶u̶s̶e̶ ̶t̶h̶e̶ ̶`̶F̶l̶x̶G̶.̶w̶i̶d̶e̶s̶c̶r̶e̶e̶n̶`̶ ̶v̶a̶r̶i̶a̶b̶l̶e̶.̶
	 */
	public var widescreen(default, set):Bool = false;

	function set_widescreen(v:Bool)
	{
		if (widescreen != (widescreen = v))
			updateScrollRect();
		return widescreen;
	}

	/**
	 * Applies a clipin so that the camera stays within the boundaries of FlxG.game.
	 */
	public var useBoundsClipping(default, set):Bool = false;

	function set_useBoundsClipping(v:Bool)
	{
		if (useBoundsClipping != (useBoundsClipping = v))
			updateScrollRect();
		return useBoundsClipping;
	}

	/**
	 * An array of filters to apply to the background behind this camera.
	 */
	public var bgFilters:Null<Array<BitmapFilter>> = null;
	public var bgShader:FlxShader = null;
	public var bgFrameTicksUpdate:Null<Int> = null;

	public var freezeDraws:Bool = false;

	public var scrollAngle(default, set):Float;

	public var followActive:Bool = true;

	public var fxActive:Bool = true;

	public var pixelZoomDecimal:Null<Float>; // 1000

	public var shakeFix:Bool = true;

	public var enableCustomBlendShader:Bool = true;

	public var captureBGMode(default, set):Bool = false;
	public var bgMatrix:Null<FlxMatrix> = null;

	// @:noCompletion var _dirtyUpdateTransformOnBlendModeGodDamit:Bool = false;
	var _customBlendShader:RuntimeCustomBlendShader;

	@:noCompletion var _casheRect:Rectangle;
	@:noCompletion var _capturedBGCameras:Array<flixel.FlxCamera> = [];
	@:noCompletion var _capturedBGCamerasVisible:Array<Bool> = [];
	@:noCompletion var _capturedBGCameraBitmap:BitmapData = null;
	@:noCompletion var _capturedBGCameraDirty:Bool = false;

	@:noCompletion var _validBGFilters:Bool = false;

	@:noCompletion var _blendShaderCount:Int = 0;

	@:noCompletion var _lastExistsOnFreezeRender:Bool;

	var _bgBitmap:BitmapData;
	var _bgFrame:FlxFrame;

	public function new(X:Float = 0, Y:Float = 0, Width:Int = 0, Height:Int = 0, Zoom:Float = 0, ?blendShaderPath:String)
	{
		followLerp = Math.POSITIVE_INFINITY;
		super(X, Y, Width, Height, Zoom);
		_bgFrame = new FlxFrame(new FlxGraphic('', null));
		_bgFrame.parent.preloadGPU();
		_bgFrame.frame = new FlxRect();
		loadCustomBlendShader(blendShaderPath);

		Main.mainInstance.onFinalDraw.add(__onFinalDraw);
		// FlxG.signals.preUpdate.add(__onPreUpdate);
		FlxG.signals.preDraw.add(__onPreDraw);
		FlxG.signals.postDraw.add(__onPostDraw);
	}
	/*
	function __onPreUpdate()
	{
		if (_lastDisplayObjectsAlpha.length == 0 && _lastDisplayObjects.length == 0) return;
		for (i in 0..._lastDisplayObjects.length)
		{
			_lastDisplayObjects[i].alpha = _lastDisplayObjectsAlpha[i];
		}
		_lastDisplayObjects.clear();
		_lastDisplayObjectsAlpha.clear();
	}
	*/
	public function redrawCapturedBG()
	{
		_capturedBGCameraDirty = true;
	}


	override function onResize()
	{
		super.onResize();
		if (captureBGMode)
			redrawCapturedBG();
	}
	function __onPreDraw()
	{
		canvas.transform.matrix = __get__rotated__matrix();
		canvas.__updateTransforms(); // update canvas transforms to fix snap zoom
		// _dirtyUpdateTransformOnBlendModeGodDamit = true;
		if (_capturedBGCameraDirty)
		{
			if (_capturedBGCameraBitmap != null && _capturedBGCameras.length == 0 && captureBGMode)
			{
				// trace("disable", _capturedBGCameraBitmap != null, _capturedBGCameras.length, _capturedBGCamerasVisible);
				var list = FlxG.cameras.list;
				var thisIndex = list.indexOf(this);
				_capturedBGCameras.resize(thisIndex);
				_capturedBGCamerasVisible.resize(thisIndex);
				var camera;
				for (i in 0...thisIndex)
				{
					camera = list[i];
					_capturedBGCamerasVisible[i] = camera.visible;
					_capturedBGCameras[i] = camera;
					camera.visible = false;
				}
				// trace("disablePost", _capturedBGCameraBitmap != null, _capturedBGCamerasVisible);
			}
			else if (_capturedBGCameras.length > 0)
			{
				// trace("enable", _capturedBGCameraBitmap != null, _capturedBGCameras.length, _capturedBGCamerasVisible);
				for (i in 0..._capturedBGCameras.length)
				{
					_capturedBGCameras[i].visible = _capturedBGCamerasVisible[i];
					_capturedBGCameras[i].flashSprite.__update(false, true);
				}
				_capturedBGCameras.resize(0);
				_capturedBGCamerasVisible.resize(0);
				_capturedBGCameraBitmap = null;
			}
			// else
			// {
			// 	trace("idk", _capturedBGCameraBitmap != null, _capturedBGCameras.length, _capturedBGCamerasVisible);
			// }
			// trace(_capturedBGCameras.length);
			_capturedBGCameraDirty = false;
		}
		_lastExistsOnFreezeRender = exists;
		exists = _lastExistsOnFreezeRender && !freezeDraws;
	}
	function __onFinalDraw()
	{
		_validBGFilters = true;
	}
	function __onPostDraw()
	{
		_validBGFilters = false;
		exists = _lastExistsOnFreezeRender;
	}

	public function loadCustomBlendShader(path:Null<String>)
	{
		_customBlendShader = new RuntimeCustomBlendShader(path);
	}

	public override function destroy()
	{
		Main.mainInstance.onFinalDraw.remove(__onFinalDraw);
		// FlxG.signals.preUpdate.remove(__onPreUpdate);
		FlxG.signals.preDraw.remove(__onPreDraw);
		FlxG.signals.postDraw.remove(__onPostDraw);

		_bgMatrix = null;
		_bgBitmap = null;
		_bgFrame = FlxDestroyUtil.destroy(_bgFrame);

		_customBlendShader = null;
		bgFilters = null;

		widescreenMultipliers = FlxDestroyUtil.put(widescreenMultipliers);

		__origin = FlxDestroyUtil.put(__origin);
		__rotatedBounds = FlxDestroyUtil.put(__rotatedBounds);
		__angleMatrix = null;

		//updateBGFilters();
		super.destroy();
	}

	var __offsetX:Float = 0;
	var __offsetY:Float = 0;

	override function updateScrollRect():Void
	{
		var w = width * initialZoom * FlxG.scaleMode.scale.x;
		var h = height * initialZoom * FlxG.scaleMode.scale.y;

		var rect:Rectangle = _scrollRect.scrollRect ?? new Rectangle();

		if (widescreen)
		{
			var w2:Float = Application.current.window.width;
			var h2:Float = Application.current.window.height;

			__offsetX = (w - w2) / 2;
			__offsetY = (h - h2) / 2;

			rect.setTo(__offsetX, __offsetY, w2 - __offsetX, h2 - __offsetY);

			widescreenMultipliers.set(w2 / w, h2 / h);
		}
		else
		{
			rect.setTo(0, 0, w, h);
			__offsetX = __offsetY = 0;
			widescreenMultipliers.set(1, 1);
		}

		var useBoundsClipping = !widescreen && useBoundsClipping;
		if (useBoundsClipping)
		{
			var flxGameRect = new Rectangle(
				-x * FlxG.scaleMode.scale.x, -y * FlxG.scaleMode.scale.y,
				FlxG.scaleMode.gameSize.x, FlxG.scaleMode.gameSize.y
			);

			// trace(flxGameRect);
			// trace(rect);

			var left =	 Math.max(rect.left,	flxGameRect.left);
			var right =	 Math.min(rect.right,	flxGameRect.right);
			var top =	 Math.max(rect.top,		flxGameRect.top);
			var bottom = Math.min(rect.bottom,	flxGameRect.bottom);
			if (right > left && bottom > top)
			{
				rect.setTo(left, top, right - left, bottom - top);
			}
			else
			{
				rect.setEmpty();
			}
			// trace(rect);
		}

		_scrollRect.x = __offsetX - w * 0.5;
		_scrollRect.y = __offsetY - h * 0.5;

		var scrollRect = _scrollRect.scrollRect;
		var resetFilters = scrollRect == null || scrollRect.width != rect.width || scrollRect.height != rect.height;
		_scrollRect.scrollRect = rect;
		if (resetFilters)
		{
			game.backend.ShaderResizeFix.fixSpriteShaderSize(flashSprite);
		}
	}

	/**
	 * Fill the camera with the specified color.
	 *
	 * @param   Color        The color to fill with in `0xAARRGGBB` hex format.
	 * @param   BlendAlpha   Whether to blend the alpha value or just wipe the previous contents. Default is `true`.
	 */
	public override function fill(Color:FlxColor, BlendAlpha:Bool = true, FxAlpha:Float = 1.0, ?graphics:Graphics):Void
	{
		if (FlxG.renderBlit)
		{
			if (BlendAlpha)
			{
				_fill.fillRect(_flashRect, Color);
				buffer.copyPixels(_fill, _flashRect, _flashPoint, null, null, BlendAlpha);
			}
			else
			{
				if (widescreen)
				{
					_casheRect ??= new Rectangle();
					_casheRect.setTo(_flashRect.x * widescreenMultipliers.x - (widescreenMultipliers.x - 1),
						_flashRect.y * widescreenMultipliers.y - (widescreenMultipliers.y - 1), _flashRect.width * widescreenMultipliers.x,
						_flashRect.height * widescreenMultipliers.y);
					buffer.fillRect(_casheRect, Color);
				}
				else
				{
					buffer.fillRect(_flashRect, Color);
				}
			}
			return;
		}

		if (FxAlpha == 0) return;

		final bounds = __get__bounds();
		graphics ??= canvas.graphics;
		graphics.overrideBlendMode(null); // https://github.com/richTrash21/fade-bug-test // thx
		graphics.beginFill(Color, FxAlpha);
		// i'm drawing rect with these parameters to avoid light lines at the top and left of the camera,
		// which could appear while cameras fading
		graphics.drawRect(bounds.x - 1, bounds.y - 1, bounds.width + 2, bounds.height + 2);
		graphics.endFill();
	}

	/**
	 * Checks whether this camera contains a given point or rectangle, in
	 * screen coordinates.
	 * @since 4.3.0
	 */
	@:noCompletion override function __containsPoint(point:FlxPoint, width:Float = 0, height:Float = 0):Bool
	{
		var bounds = __get__bounds();
		var contained = (point.x + width > bounds.left) && (point.x < bounds.right) && (point.y + height > bounds.top) && (point.y < bounds.bottom);
		point.putWeak();
		return contained;
	}
	/*
		{
			var offsetX = viewOffsetX;
			var offsetY = viewOffsetY;
			var offsetW = viewOffsetWidth;
			var offsetH = viewOffsetHeight;

			if (widescreen)
			{
				var wRatio = (width * initialZoom * FlxG.scaleMode.scale.x - Application.current.window.width) * FlxG.scaleMode.scale.x * 2;
				var hRatio = (height * initialZoom * FlxG.scaleMode.scale.y - Application.current.window.height) * FlxG.scaleMode.scale.y * 2;

				offsetX += wRatio;
				offsetW -= wRatio;

				offsetY += hRatio;
				offsetH -= hRatio;
			}

			var contained = (point.x + width > offsetX) && (point.x < offsetW) && (point.y + height > offsetY) && (point.y < offsetH);
			point.putWeak();
			return contained;
		}
	 */

	@:noCompletion override function __containsRect(rect:FlxRect):Bool
		return __get__bounds().overlaps(rect);

	public override function drawTriangles(graphic:FlxGraphic, vertices:DrawData<Float>, indices:DrawData<Int>, uvtData:DrawData<Float>, ?colors:DrawData<Int>,
		?position:FlxPoint, ?blend:BlendMode, repeat:Bool = false, smoothing:Bool = false, ?transform:ColorTransform, ?shader:FlxShader):Void
	{
		if (enableCustomBlendShader && _customBlendShader.listAvailableBlends.contains(blend))
		{
			Macro.buildRenderBlendMode(super.drawTriangles(graphic, vertices, indices, uvtData, colors, position, null, repeat, smoothing, transform, shader), blend);
		}
		else
		{
			super.drawTriangles(graphic, vertices, indices, uvtData, colors, position, blend, repeat, smoothing, transform, shader);
		}
	}
	public override function copyPixels(?frame:FlxFrame, ?pixels:BitmapData, ?sourceRect:Rectangle, destPoint:Point, ?transform:ColorTransform, ?blend:BlendMode,
		?smoothing:Bool = false, ?shader:FlxShader):Void
	{
		if (enableCustomBlendShader && _customBlendShader.listAvailableBlends.contains(blend))
		{
			Macro.buildRenderBlendMode(super.copyPixels(frame, pixels, sourceRect, destPoint, transform, null, smoothing, shader), blend);
		}
		else
		{
			super.copyPixels(frame, pixels, sourceRect, destPoint, transform, blend, smoothing, shader);
		}
	}
	public override function drawPixels(?frame:FlxFrame, ?pixels:BitmapData, matrix:FlxMatrix, ?transform:ColorTransform, ?blend:BlendMode, ?smoothing:Bool = false,
		?shader:FlxShader):Void
	{
		if (enableCustomBlendShader && _customBlendShader.listAvailableBlends.contains(blend))
		{
			Macro.buildRenderBlendMode(super.drawPixels(frame, pixels, matrix, transform, null, smoothing, shader), blend);
		}
		else
		{
			super.drawPixels(frame, pixels, matrix, transform, blend, smoothing, shader);
		}
	}

	var _bgMatrix = new FlxMatrix();
	function drawBGFrame(bgBitmap:BitmapData, shader:FlxShader = null, matrix:FlxMatrix = null, smoothing:Bool = false, behindOfAll:Bool = false)
	{
		_bgFrame.parent.bitmap = bgBitmap;
		_bgFrame.frame.set(0, 0, bgBitmap.width, bgBitmap.height);

		_bgMatrix.identity();
		_bgMatrix.scale(
			viewWidth / bgBitmap.width,
			viewHeight / bgBitmap.height
		);
		if (matrix != null)
		{
			_bgMatrix.concat(matrix);
		}
		// _bgMatrix.scale(1 / frameWidth, 1 / frameHeight);
		if (_negativeCosScrollAngle != 1.0 || _negativeSinScrollAngle != 0.0)
		{
			getFactorOrigin(__origin);
			__origin.scale(viewWidth, viewHeight);
			_bgMatrix.translate(-__origin.x, -__origin.y);
			_bgMatrix.rotateWithTrig(_negativeCosScrollAngle, _negativeSinScrollAngle);
			_bgMatrix.translate(__origin.x, __origin.y);
		}
		_bgMatrix.translate(viewMarginLeft, viewMarginTop);


		// _bgMatrix.setTo(viewWidth / bgBitmap.width, 0, 0, viewHeight / bgBitmap.height, viewMarginLeft, viewMarginTop);

		if (behindOfAll)
		{
			var lastHead = _headOfDrawStack;
			_currentDrawItem = null;
			_headOfDrawStack = null;
			// _headTiles = null;
			// _headTriangles = null;
			super.drawPixels(_bgFrame, null, _bgMatrix, null, null, smoothing, shader);
			_headOfDrawStack.next = lastHead;
		}
		else
		{
			super.drawPixels(_bgFrame, null, _bgMatrix, null, null, smoothing, shader);
		}
	}

	public override function clearDrawStack()
	{
		_blendShaderCount = 0;
		super.clearDrawStack();
	}

	override function set_zoom(Zoom:Float):Float
	{
		zoom = (Zoom == 0) ? flixel.FlxCamera.defaultZoom : Zoom;
		if (!freezeDraws)
			setScale(zoom, zoom);
		return zoom;
	}

	public override function setScale(X:Float, Y:Float):Void
	{
		if (pixelZoomDecimal != null)
		{
			x = Math.ffloor(X * pixelZoomDecimal) / pixelZoomDecimal;
			Y = Math.ffloor(Y * pixelZoomDecimal) / pixelZoomDecimal;
		}
		super.setScale(X, Y);
	}

	/**
	 * Updates the camera scroll as well as special effects like screen-shake or fades.
	 */
	public override function update(elapsed:Float):Void
	{
		// follow the target, if there is one
		if (target != null && followActive)
		{
			updateFollow();
		}

		updateScroll();
		updateFlashSpritePosition();
		// if (!freezeDraws)
			flashSprite.filters = filtersEnabled ? filters : null;
		if (fxActive)
		{
			updateFlash(elapsed);
			updateFade(elapsed);
			updateShake(elapsed);
		}
	}

	@:noCompletion function __get__rotated__matrix():FlxMatrix
	{
		__angleMatrix.identity();
		__angleMatrix.translate(-origin.x, -origin.y);
		__angleMatrix.scale(scaleX, scaleY);
		// __angleMatrix.scale(totalScaleX, totalScaleY);
		if (_sinScrollAngle != 0.0 || _cosScrollAngle != 1.0)
			__angleMatrix.rotateWithTrig(_cosScrollAngle, _sinScrollAngle);
		__angleMatrix.translate(origin.x, origin.y);
		if (shakeFix)
			__angleMatrix.translate(_fxShakeXOffset, _fxShakeYOffset);
		// __angleMatrix.translate(x, y);
		__angleMatrix.scale(FlxG.scaleMode.scale.x, FlxG.scaleMode.scale.y);
		return __angleMatrix;
	}

	@:noCompletion extern inline function __get__bounds():FlxRect
	{
		return getViewMarginRect(__rotatedBounds);
	}
	public override function getViewMarginRect(?rect:FlxRect)
	{
		rect ??= FlxRect.get();

		var wRatio:Float = 0;
		var hRatio:Float = 0;
		if (widescreen)
		{
			var curWindow = Application.current.window;
			wRatio = curWindow.width / FlxG.scaleMode.scale.x - width * initialZoom * FlxG.scaleMode.scale.x;
			hRatio = curWindow.height / FlxG.scaleMode.scale.y - height * initialZoom * FlxG.scaleMode.scale.y;
		}

		rect.set(viewMarginLeft, viewMarginTop, viewWidth, viewHeight);
		return __get__rotated__bounds(rect, wRatio, hRatio);
	}

	@:noCompletion extern inline function __get__rotated__bounds(rect:FlxRect, wRatio:Float = 0, hRatio:Float = 0):FlxRect
	{
		var scrollAngle = FlxMath.mod(scrollAngle, 360);
		if (scrollAngle == 0)
		{
			return rect;
		}

		getFactorOrigin(__origin);
		__origin.scale(rect.width, rect.height);

		rect.x += __origin.x;
		rect.y += __origin.y;

		var left	= -__origin.x;
		var top		= -__origin.y;
		var right	= -__origin.x + rect.width;
		var bottom	= -__origin.y + rect.height;
		if (scrollAngle < 90)
		{
			rect.x += _cosScrollAngle * left - _sinScrollAngle * bottom;
			rect.y += _sinScrollAngle * left + _cosScrollAngle * top;
		}
		else if (scrollAngle < 180)
		{
			rect.x += _cosScrollAngle * right - _sinScrollAngle * bottom;
			rect.y += _sinScrollAngle * left  + _cosScrollAngle * bottom;
		}
		else if (scrollAngle < 270)
		{
			rect.x += _cosScrollAngle * right - _sinScrollAngle * top;
			rect.y += _sinScrollAngle * right + _cosScrollAngle * bottom;
		}
		else
		{
			rect.x += _cosScrollAngle * left - _sinScrollAngle * top;
			rect.y += _sinScrollAngle * right + _cosScrollAngle * top;
		}
		// temp var, in case input rect is the output rect
		var newHeight = Math.abs(_cosScrollAngle * rect.height) + Math.abs(_sinScrollAngle * rect.width);
		rect.width = Math.abs(_cosScrollAngle * rect.width) + Math.abs(_sinScrollAngle * rect.height);
		rect.height = newHeight;

		rect.set(rect.x - wRatio, rect.y - hRatio, rect.width + wRatio * 2, rect.height + hRatio * 2); // todo: methods from Rectangle into FlxRect

		return rect;
	}

	@:noCompletion var _sinScrollAngle = 0.0;
	@:noCompletion var _cosScrollAngle = 1.0;
	@:noCompletion var _negativeSinScrollAngle = 0.0;
	@:noCompletion var _negativeCosScrollAngle = 1.0;

	@:noCompletion var __angleMatrix = new FlxMatrix();
	@:noCompletion var __rotatedBounds = FlxRect.get();
	@:noCompletion var __origin = FlxPoint.get();

	@:noCompletion inline function __update__trig()
	{
		final radians = FlxMath.mod(scrollAngle, 360) * flixel.math.FlxAngle.TO_RAD;
		_sinScrollAngle = Math.sin(radians);
		_cosScrollAngle = Math.cos(radians);
		_negativeSinScrollAngle = Math.sin(-radians);
		_negativeCosScrollAngle = Math.cos(-radians);
	}

	function set_scrollAngle(NewAngle:Float):Float
	{
		if (scrollAngle != NewAngle)
		{
			scrollAngle = NewAngle;
			if (!freezeDraws)
				__update__trig();
		}
		return NewAngle;
	}

	var _fxShakeXOffset:Float = 0;
	var _fxShakeYOffset:Float = 0;

	override function updateShake(elapsed:Float):Void
	{
		if (!shakeFix)
		{
			flashSprite.x -= _fxShakeXOffset;
			flashSprite.y -= _fxShakeYOffset;
		}
		_fxShakeXOffset = _fxShakeYOffset = 0;
		if (_fxShakeDuration > 0)
		{
			_fxShakeDuration -= elapsed;
			if (_fxShakeDuration <= 0)
			{
				if (_fxShakeComplete != null)
				{
					_fxShakeComplete();
				}
			}
			else
			{
				final pixelPerfect = pixelPerfectShake == null ? pixelPerfectRender : pixelPerfectShake;
				if (_fxShakeAxes.x)
				{
					_fxShakeXOffset = FlxG.random.float(-1, 1) * _fxShakeIntensity * width;
					if (pixelPerfect)
						_fxShakeXOffset = Math.fround(_fxShakeXOffset);
				}

				if (_fxShakeAxes.y)
				{
					_fxShakeYOffset = FlxG.random.float(-1, 1) * _fxShakeIntensity * height;
					if (pixelPerfect)
						_fxShakeYOffset = Math.fround(_fxShakeYOffset);
				}
			}
			if (shakeFix)
			{
				_fxShakeXOffset /= zoom;
				_fxShakeYOffset /= zoom;
			}
			else
			{
				_fxShakeXOffset *= FlxG.scaleMode.scale.x * zoom;
				_fxShakeYOffset *= FlxG.scaleMode.scale.y * zoom;
				flashSprite.x += _fxShakeXOffset;
				flashSprite.y += _fxShakeYOffset;
			}
		}
	}

	public override function updateFollow():Void
	{
		// Either follow the object closely,
		// or double check our deadzone and update accordingly.
		if (deadzone == null)
		{
			target.getMidpoint(_point);
			_point.addPoint(targetOffset);
			_scrollTarget.set(_point.x - width * 0.5, _point.y - height * 0.5);
		}
		else
		{
			var edge:Float;
			var targetX:Float = target.x + targetOffset.x;
			var targetY:Float = target.y + targetOffset.y;

			if (style == SCREEN_BY_SCREEN)
			{
				if (targetX >= viewRight)
					_scrollTarget.x += viewWidth;
				else if (targetX + target.width < viewLeft)
					_scrollTarget.x -= viewWidth;

				if (targetY >= viewBottom)
					_scrollTarget.y += viewHeight;
				else if (targetY + target.height < viewTop)
					_scrollTarget.y -= viewHeight;

				// without this we see weird behavior when switching to SCREEN_BY_SCREEN at arbitrary scroll positions
				bindScrollPos(_scrollTarget);
			}
			else
			{
				edge = targetX - deadzone.x;
				if (_scrollTarget.x > edge)
					_scrollTarget.x = edge;
				edge = targetX + target.width - deadzone.x - deadzone.width;
				if (_scrollTarget.x < edge)
					_scrollTarget.x = edge;

				edge = targetY - deadzone.y;
				if (_scrollTarget.y > edge)
					_scrollTarget.y = edge;
				edge = targetY + target.height - deadzone.y - deadzone.height;
				if (_scrollTarget.y < edge)
					_scrollTarget.y = edge;
			}

			if (target is FlxSprite)
			{
				_lastTargetPosition ??= FlxPoint.get(target.x, target.y); // Creates this point.
				_scrollTarget.x += (target.x - _lastTargetPosition.x) * followLead.x;
				_scrollTarget.y += (target.y - _lastTargetPosition.y) * followLead.y;

				_lastTargetPosition.x = target.x;
				_lastTargetPosition.y = target.y;
			}
		}

		if (followLerp == Math.POSITIVE_INFINITY)
			scroll.copyFrom(_scrollTarget); // no easing
		else
			scroll.set(
				CoolUtil.fpsLerp(scroll.x, _scrollTarget.x, followLerp),
				CoolUtil.fpsLerp(scroll.y, _scrollTarget.y, followLerp)
			);
	}

	// @:noCompletion var _lastRenderDirty:Array<Bool> = [];
	// @:noCompletion var _lastDisplayObjects:Array<openfl.display.DisplayObject> = [];

	// override function drawFX():Void
	// {
	// 	if (!freezeDraws)
	// 		super.drawFX();
	// }

	@:noCompletion static var _lastFilteredCameraIndex:Int = {
		FlxG.signals.postDraw.add(() -> _lastFilteredCameraIndex = 0);
		0;
	};

	@:access(openfl.display.DisplayObject)
	@:access(openfl.display.Graphics)
	@:access(openfl.geom.Matrix)
	override function render()
	{
		canvas.transform.matrix = __get__rotated__matrix();

		var list = FlxG.cameras.list;
		if (_validBGFilters && (captureBGMode || bgShader != null || bgFilters != null && bgFilters.length > 0)
			&& list.indexOf(this) > 0
		)
		{
			var _bgBitmap = captureBGMode ? _capturedBGCameraBitmap : this._bgBitmap;
			var _filterRenderer = BitmapDataUtil.filterRenderer;
			var oldClearColors = _filterRenderer.clearColors;

			var cameraWidth:Int = Math.floor(width * FlxG.scaleMode.scale.x);
			var cameraHeight:Int = Math.floor(height * FlxG.scaleMode.scale.y);
			var keyCashe = BitmapDataUtil.prefixBitmapCacheKey + '_FlxCamera$ID.BACKGROUND:' + cameraWidth + "_" + cameraHeight + "_|_" + ID;
			if (_bgBitmap == null || (!captureBGMode && (bgFrameTicksUpdate == null || FlxG.game.ticks % bgFrameTicksUpdate >= bgFrameTicksUpdate / 2)))
			{
				_bgBitmap = BitmapDataUtil.getBitmapCashe(keyCashe, cameraWidth, cameraHeight);

				// var rect:Rectangle = null;
				var matrix = Matrix.__pool.get();
				matrix.translate(-x * FlxG.scaleMode.scale.x, -y * FlxG.scaleMode.scale.y);
				matrix.translate(-FlxG.scaleMode.offset.x, -FlxG.scaleMode.offset.y);
				_filterRenderer.clearColors = true;

				var camera:flixel.FlxCamera;
				var _flashSprite:openfl.display.Sprite;
				// var _lastFilters:Null<Array<BitmapFilter>>;
				var _oldDirty:Bool;
				for (i in 0...list.indexOf(this))
				{
					camera = list[i];
					// if (camera.x < this.x || camera.width > this.width
					// 	|| camera.y < this.y || camera.height > this.height)
					// 	continue;

					//_flashSprite = camera.canvas;
					_flashSprite = camera.flashSprite;
					_oldDirty = _flashSprite.__renderDirty;
					// _lastFilters = _flashSprite.__filters;
					_flashSprite.__renderDirty = false;
					// _flashSprite.__filters = null;
					if (camera._fxFlashAlpha > 0.0 || camera._fxFadeAlpha > 0.0)
					{
						var oldGraphicsDrawData = canvas.graphics.__commands.copy();
						camera.drawFX();
						_filterRenderer.drawableToBitmapData(_flashSprite, _bgBitmap, matrix);
						canvas.graphics.__commands = oldGraphicsDrawData;
					}
					else
					{
						_filterRenderer.drawableToBitmapData(_flashSprite, _bgBitmap, matrix);
					}
					_flashSprite.__renderDirty = _oldDirty;
					// _flashSprite.__renderable = false;
					// _flashSprite.__filters = _lastFilters;
					_filterRenderer.clearColors = false;
				}

				this._bgBitmap = _bgBitmap;
				if (captureBGMode)
				{
					// trace("Render", list.indexOf(this));
					_capturedBGCameraBitmap = _bgBitmap;
					_capturedBGCameraDirty = true;
				}
				Matrix.__pool.release(matrix);
			}

			if (bgFilters != null && bgFilters.length > 0)
			{
				var filteredBitmap = BitmapDataUtil.getBitmapCashe(keyCashe + "_f", _bgBitmap.width, _bgBitmap.height);
				_filterRenderer.clearColors = true;
				BitmapDataUtil.applyFilters(_bgBitmap, bgFilters, keyCashe, filteredBitmap);
				_bgBitmap = filteredBitmap;
			}
			_filterRenderer.clearColors = oldClearColors;

			drawBGFrame(_bgBitmap, bgShader, bgMatrix, ClientPrefs.globalAntialiasing, true);
		}

		//updateBGFilters();
		super.render();
	}

	function set_captureBGMode(i:Bool)
	{
		redrawCapturedBG();
		_capturedBGCameraBitmap = null;
		return captureBGMode = i;
	}

	override function set_x(x:Float):Float
	{
		this.x = x;
		updateFlashSpritePosition();
		updateScrollRect();
		return x;
	}

	override function set_y(y:Float):Float
	{
		this.y = y;
		updateFlashSpritePosition();
		updateScrollRect();
		return y;
	}

	override function set_followLerp(Value:Float):Float
		return followLerp = Value;

	override inline function get_viewMarginLeft():Float
	{
		return shakeFix ? viewMarginX - _fxShakeXOffset / scaleX : viewMarginX;
	}

	override inline function get_viewMarginTop():Float
	{
		return shakeFix ? viewMarginY - _fxShakeYOffset / scaleY : viewMarginY;
	}
}
#end

private class Macro
{
	public static macro function buildRenderBlendMode(blendObjJob:Expr, blend:Expr):Expr {
		return macro
		{
			/*
			if (_dirtyUpdateTransformOnBlendModeGodDamit)
			{
				canvas.transform.matrix = __get__rotated__matrix();
				canvas.__updateTransforms(); // update canvas transforms to fix snap zoom
				_dirtyUpdateTransformOnBlendModeGodDamit = false;
			}
			*/
			var oldCount:Int = _blendShaderCount;
			_bgBitmap = BitmapDataUtil.fromFlxCameraToBitmapData(this,
				null, true, false, oldCount == 0, true,
				'FlxCamOverlBG${oldCount % 2}');
			// _bgFrame.parent.bitmap = bgPixels;

			// render simple object
			$e{blendObjJob};

			_customBlendShader.blendSwag = $e{blend};
			_customBlendShader.blendSource = BitmapDataUtil.fromFlxCameraToBitmapData(this,
				null, true, false, false, true,
				'FlxCamOverlOBJ');

			_blendShaderCount = ++oldCount;

			drawBGFrame(_bgBitmap, _customBlendShader, ClientPrefs.globalAntialiasing /* smoothing */);
			_bgBitmap = null;
		}
	}

}