package game.objects;

import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxFrame;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMatrix;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.system.FlxAssets.FlxShader;
import flixel.util.FlxDestroyUtil;
import flixel.util.FlxSignal;
import game.backend.utils.BitmapDataUtil;
import openfl.display.BitmapData;
import openfl.display.BlendMode;
import openfl.filters.BitmapFilter;
import openfl.geom.ColorTransform;

@:access(flixel.FlxCamera)
@:access(flixel.graphics.FlxGraphic)
@:access(flixel.graphics.frames.FlxFrame)
@:access(openfl.display.DisplayObjectContainer)
class FlxLayerGroup<T:FlxBasic> extends FlxTypedGroup<T>
{
	public var antialiasing:Bool = FlxSprite.defaultAntialiasing;
	public var blend:BlendMode = BlendMode.NORMAL;
	public var colorTransform(default, null):ColorTransform = new ColorTransform();
	public var shader:FlxShader = null;
	public var matrix:FlxMatrix = null;
	public var basicDraw:Bool = false;
	public var forseDirtyDraw:Bool = true;
	public var dirtyDraw:Bool = true;
	public var filters:Array<BitmapFilter> = [];
	public var onPreDraw(get, never):FlxSignal;
	public var onPostDraw(get, never):FlxSignal;

	var _onPreDraw:FlxSignal;
	var _onPostDraw:FlxSignal;
	var _point:FlxPoint = new FlxPoint();
	var _matrix:FlxMatrix = new FlxMatrix();
	var _frame:FlxFrame;

	public function new(maxsize:Int = 0)
	{
		super(maxsize);
		_frame = new FlxFrame(new FlxGraphic('', null));
		_frame.frame = new FlxRect();
		FlxG.signals.gameResized.add(_gameResized);
	}
	function _gameResized(_, _) dirtyDraw = true;

	override function destroy()
	{
		super.destroy();
		_point = null;
		_matrix = null;
		_frame = FlxDestroyUtil.destroy(_frame);
		FlxG.signals.gameResized.remove(_gameResized);
		filters = null;
	}

	override function draw()
	{
		if (basicDraw)
		{
			super.draw();
			return;
		}
		if (members.length == 0) return;

		_dispatchSignal(_onPreDraw);
		var oldCameras = this.cameras;
		for (camera in oldCameras)
		{
			if (!camera.visible || !camera.exists)
				continue;

			var bitmapCam:BitmapData;
			if (dirtyDraw) // draw last layerd frame | todo: fix that
			{
				/*
				filterCamera.scroll.copyFrom(camera.scroll);
				filterCamera.targetOffset.copyFrom(camera.targetOffset);
				filterCamera.basicOffset.copyFrom(camera.basicOffset);
				filterCamera.x = camera.x;
				filterCamera.y = camera.y;
				filterCamera.width = camera.width;
				filterCamera.height = camera.height;
				filterCamera.setScale(camera.scaleX, camera.scaleY);
				filterCamera.updateFlashOffset();
				// filterCamera.update(0);
				*/
				var lastDrawItem = camera._currentDrawItem;
				var lastHead = camera._headOfDrawStack;
				var lastHeadTiles = camera._headTiles;
				var lastHeadTringles = camera._headTriangles;
				// var lastStorageTiles = camera._storageTilesHead;
				// var lastStorageTringles = camera._storageTrianglesHead;
				camera._currentDrawItem = null;
				camera._headOfDrawStack = null;
				camera._headTiles = null;
				camera._headTriangles = null;
				// camera._storageTilesHead = null;
				// camera._storageTrianglesHead = null;
				camera.canvas.__updateTransforms(); // update canvas transforms to fix snap zoom

				camera.canvas.graphics.clear();
				// camera.clearDrawStack();
				// var lastBgColor = camera.bgColor;
				// camera.bgColor = 0;
				this.cameras = [camera];
				super.draw();

				inline function getKey() return 'GrpFilt${this.ID}';
				bitmapCam = BitmapDataUtil.fromFlxCameraToBitmapData(camera, null, true, false, false, true, getKey());
				camera._currentDrawItem = lastDrawItem;
				camera._headOfDrawStack = lastHead;
				camera._headTiles = lastHeadTiles;
				camera._headTriangles = lastHeadTringles;
				// camera._storageTilesHead = lastStorageTiles;
				// camera._storageTrianglesHead = lastStorageTringles;
				// camera._headOfDrawStack.next = lastHead;
				// camera.bgColor = lastBgColor;
				BitmapDataUtil.applyFilters(bitmapCam, filters, getKey());

				_frame.parent.bitmap = bitmapCam;
				_frame.frame.set(0, 0, bitmapCam.width, bitmapCam.height);
			}
			else
			{
				bitmapCam = _frame.parent.bitmap;
			}
			if (bitmapCam == null)
				continue;

			_matrix.identity();
			_matrix.scale(
				camera.viewWidth / bitmapCam.width,
				camera.viewHeight / bitmapCam.height
			);
			if (this.matrix != null)
			{
				_matrix.concat(this.matrix);
			}

			var _negativeSinScrollAngle = 0.0, _negativeCosScrollAngle = 1.0;
			if (camera is FlxCamera) // is't improved camera?
			{
				var camera:FlxCamera = cast camera;
				_negativeSinScrollAngle = camera._negativeSinScrollAngle;
				_negativeCosScrollAngle = camera._negativeCosScrollAngle;
			}
			if (_negativeSinScrollAngle != 0.0 || _negativeCosScrollAngle != 1.0)
			{
				camera.getFactorOrigin(_point);
				_point.scale(camera.viewWidth, camera.viewHeight);
				_matrix.translate(-_point.x, -_point.y);
				_matrix.rotateWithTrig(_negativeCosScrollAngle, _negativeSinScrollAngle);
				_matrix.translate(_point.x, _point.y);
			}

			_matrix.translate(camera.viewMarginLeft, camera.viewMarginTop);
			camera.drawPixels(_frame, null, _matrix, this.colorTransform, blend, antialiasing, shader);
			#if FLX_DEBUG
			FlxBasic.visibleCount++;
			#end
		}
		this.cameras = oldCameras;
		dirtyDraw = forseDirtyDraw;
		_dispatchSignal(_onPostDraw);
	}

	function get_onPreDraw()
	{
		if (_onPreDraw == null)
			_onPreDraw = new FlxSignal();
		return _onPreDraw;
	}

	function get_onPostDraw()
	{
		if (_onPostDraw == null)
			_onPostDraw = new FlxSignal();
		return _onPostDraw;
	}

	@:noCompletion inline function _dispatchSignal(i:FlxSignal) {
		if (i != null)
			i.dispatch();
	}
}
