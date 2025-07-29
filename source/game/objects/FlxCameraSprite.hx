package game.objects;

import flixel.FlxCamera;
import flixel.graphics.frames.FlxFrame.FlxFrameAngle;
import flixel.math.FlxMatrix;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;

import openfl.display.BitmapData;
import openfl.geom.Rectangle;

import game.backend.utils.BitmapDataUtil;

using flixel.util.FlxColorTransformUtil;

@:access(flixel.FlxCamera)
@:access(openfl.display.Sprite)
@:access(openfl.display.BitmapData)
@:access(openfl.display.DisplayObject)
class FlxCameraSprite extends flixel.FlxSprite
{
	public var dirtyDraw:Bool = true;
	public var resetDrawCalls:Bool = false;
	public var interactsCount:UInt = 3;
	public var thisCamera(default, set):FlxCamera;
	public var angleCamera:Null<Float>;

	public function new(x = 0.0, y = 0.0, ?camera:FlxCamera)
	{
		super(x, y);
		thisCamera = camera ?? FlxG.camera;
		resetDrawCalls = !FlxG.cameras.list.contains(thisCamera);
		updateHitbox();
		Main.mainInstance.onFinalDraw.add(onDraw);
	}

	public override function destroy()
	{
		Main.mainInstance.onFinalDraw.remove(onDraw);
		super.destroy();
	}

	public override function update(elapsed:Float):Void
	{
		#if FLX_DEBUG
		flixel.FlxBasic.activeCount++;
		#end
		last.set(x, y);

		if (path != null && path.active)
			path.update(elapsed);

		if (moves)
			updateMotion(elapsed);

		wasTouching = touching;
		touching = 0;
	}

	var lastesDrawQuads:Array<flixel.graphics.tile.FlxDrawBaseItem<Dynamic>> = [];
	var lastesMatrises:Array<game.backend.utils.CoolUtil.DestroyableFlxMatrix> = [];
	function onDraw()
	{
		if (!dirtyDraw || alpha == 0 || !visible || thisCamera == null) return;
		var pixels:BitmapData = this.pixels;
		// TODO
		// var interactsCount:UInt = ((cameras == null && thisCamera == FlxG.camera) || cameras.contains(thisCamera)) ? interactsCount : 1;
		// if (interactsCount == 0) return;
		var interactsCount:UInt = 1;
		var oldCacheKey = BitmapDataUtil.prefixBitmapCacheKey;
		BitmapDataUtil.prefixBitmapCacheKey += 'PrefCamSpr${this.ID}_';
		for (i in 0...interactsCount)
		{
			// var isLast = i == interactsCount - 1;
			// pixels = FlxG.bitmap.create(thisCamera.width, thisCamera.height, 0, false, 'CameraSprite${this.ID}|${i}___').bitmap;
			pixels = BitmapDataUtil.fromFlxCameraToBitmapData(thisCamera, null, resetDrawCalls, false, true, false, 'CamSpr${this.ID}|${i % 2}', angleCamera);

			if (resetDrawCalls)
				thisCamera.fill(thisCamera.bgColor.to24Bit(), thisCamera.useBgAlphaBlending, thisCamera.bgColor.alphaFloat);

			if (this.pixels != pixels)
				this.pixels = pixels;
			// updateHitbox();

			if (pixels != null)
			{
				var isColored:Bool = colorTransform?.hasRGBMultipliers();
				var hasColorOffsets:Bool = colorTransform?.hasRGBAOffsets();
				var _camera:FlxCamera;
				for (i => item in lastesDrawQuads)
				{
					if (item == null) continue;
					_camera = cameras[i];
					if (_camera != null && (_camera._headOfDrawStack == null || _camera._currentDrawItem == null))
					{
						#if FLX_RENDER_TRIANGLE
						lastesDrawQuads[i] = item = _camera.startTrianglesBatch(_frame.parent, antialiasing, isColored, blend);
						#else
						lastesDrawQuads[i] = item = _camera.startQuadBatch(_frame.parent, isColored, hasColorOffsets, blend, antialiasing, shader);
						#end
					}
					item.graphics ??= _frame.parent;
					item.addQuad(_frame, lastesMatrises[i], colorTransform);
				}
			}
		}
		BitmapDataUtil.prefixBitmapCacheKey = oldCacheKey;

	}

	@:access(openfl.geom.Rectangle)
	public override function draw()
	{
		if (alpha == 0)
			return;

		for (i in lastesMatrises)
			CoolUtil.matrixesPool.put(i);
		lastesMatrises.clearArray();
		lastesDrawQuads.clearArray();
		for (i => camera in cameras)
		{
			if (!camera.visible || !camera.exists || !isOnScreen(camera))
			{
				lastesMatrises.push(null);
				lastesDrawQuads.push(null);
				continue;
			}

			if (isSimpleRender(camera))
				drawSimple(camera);
			else
				drawComplex(camera);

			lastesDrawQuads.push(camera._currentDrawItem);
			#if FLX_DEBUG
			FlxBasic.visibleCount++;
			#end
		}

		#if FLX_DEBUG
		if (FlxG.debugger.drawDebug)
			drawDebug();
		#end
	}

	@:noCompletion
	override function drawSimple(camera:FlxCamera):Void
	{
		getScreenPosition(_point, camera).subtractPoint(offset);
		if (isPixelPerfectRender(camera))
			_point.floor();

		_point.copyToFlash(_flashPoint);

		camera._helperMatrix.identity();
		camera._helperMatrix.translate(_point.x + _frame.offset.x, _point.y + _frame.offset.y);

		var isColored:Bool = colorTransform?.hasRGBMultipliers();
		var hasColorOffsets:Bool = colorTransform?.hasRGBAOffsets();

		#if FLX_RENDER_TRIANGLE
		camera.startTrianglesBatch(_frame.parent, antialiasing, isColored, blend);
		#else
		camera.startQuadBatch(_frame.parent, isColored, hasColorOffsets, blend, antialiasing);
		#end
		var matrix = CoolUtil.matrixesPool.get();
		matrix.copyFrom(camera._helperMatrix);
		lastesMatrises.push(matrix);
	}

	@:noCompletion
	override function drawComplex(camera:FlxCamera):Void
	{
		_frame.prepareMatrix(_matrix, FlxFrameAngle.ANGLE_0, checkFlipX(), checkFlipY());
		_matrix.translate(-origin.x, -origin.y);
		_matrix.scale(scale.x, scale.y);

		if (bakedRotationAngle <= 0)
		{
			updateTrig();

			if (angle != 0)
				_matrix.rotateWithTrig(_cosAngle, _sinAngle);
		}

		getScreenPosition(_point, camera).subtractPoint(offset);
		_point.add(origin.x, origin.y);
		_matrix.translate(_point.x, _point.y);

		if (isPixelPerfectRender(camera))
		{
			_matrix.tx = Math.ffloor(_matrix.tx);
			_matrix.ty = Math.ffloor(_matrix.ty);
		}

		var isColored = colorTransform?.hasRGBMultipliers();
		var hasColorOffsets:Bool = colorTransform?.hasRGBAOffsets();

		#if FLX_RENDER_TRIANGLE
		camera.startTrianglesBatch(_frame.parent, antialiasing, isColored, blend);
		#else
		camera.startQuadBatch(_frame.parent, isColored, hasColorOffsets, blend, antialiasing, shader);
		#end
		var matrix = CoolUtil.matrixesPool.get();
		matrix.copyFrom(_matrix);
		lastesMatrises.push(matrix);
	}

	@:noCompletion function set_thisCamera(camera:FlxCamera):FlxCamera
	{
		if (thisCamera != camera)
		{
			thisCamera = camera;
			makeGraphic(thisCamera.width, thisCamera.height, 0, "cameraSprite_");
		}
		return camera;
	}
}

// Well, not really. -Redar
class FlxInvisibleCamera extends game.objects.improvedFlixel.FlxCamera
{
	override function updateFlashSpritePosition():Void
	{
		if (flashSprite != null)
		{
			flashSprite.x = FlxG.width * FlxG.scaleMode.scale.x * 4;
			flashSprite.y = FlxG.height * FlxG.scaleMode.scale.y * 4;
		}
	}
}