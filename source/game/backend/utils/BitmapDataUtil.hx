package game.backend.utils;

import flixel.FlxCamera;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxFrame;
import flixel.math.FlxMath;
import flixel.math.FlxMatrix;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;

import openfl.Lib;
import openfl.display.BitmapData;
import openfl.display.OpenGLRenderer;
import openfl.display.PNGEncoderOptions;
import openfl.display.Shader;
import openfl.display3D.Context3D;
import openfl.filters.BitmapFilter;
import openfl.geom.Matrix;
import openfl.geom.Rectangle;

import lime.app.Future;
import lime.app.Promise;
import lime.graphics.*;

import game.backend.system.FilterRenderer;

@:access(openfl.display)
@:access(openfl.geom)
@:access(flixel.FlxCamera)
class BitmapDataUtil {
	public static var filterRenderer:FilterRenderer;
	public static function init() {
		filterRenderer = new FilterRenderer();
		FlxG.signals.preStateSwitch.add(() -> {
			for (_ => i in _bitmapDrawCashe)
			{
				if (i == null) return;
				i.fullDispose();
			}
			_bitmapDrawCashe.clear();
			prefixBitmapCacheKey = "";
		});
	}
	public static var prefixBitmapCacheKey:String = "";

	public static function fromFlxCameraToBitmapData(camera:FlxCamera, ?bitmapData:BitmapData,
		resetDrawCalls:Bool = true, renderFilters:Bool = false, doFill:Bool = true, realScale:Bool = false,
		?keyCashe:String, ?customAngle:Null<Float>):BitmapData
	{
		var graphic = camera.canvas;
		// var graphic = camera._scrollRect;
		// var graphic = camera.flashSprite;
		if (graphic == null) return null;

		var cameraWidth:Int, cameraHeight:Int;
		if (realScale)
		{
			cameraWidth = Math.floor(camera.width * camera.initialZoom * FlxG.scaleMode.scale.x);
			cameraHeight = Math.floor(camera.height * camera.initialZoom * FlxG.scaleMode.scale.y);
		}
		else
		{
			cameraWidth = camera.width;
			cameraHeight = camera.height;
		}
		// cameraWidth = Math.round(cameraWidth * 1.2);
		// cameraHeight = Math.round(cameraHeight * 1.2);

		if (keyCashe == null)
		{
			keyCashe = "";
		}
		else
		{
			keyCashe += "_";
		}

		keyCashe = prefixBitmapCacheKey + keyCashe;
		if (bitmapData == null)
		{
			keyCashe += cameraWidth + "_" + cameraHeight;
		}
		else
		{
			keyCashe += bitmapData.width + "_" + bitmapData.height;
		}
		keyCashe += "_|_" + camera.ID;

		bitmapData ??= getBitmapCashe(keyCashe, cameraWidth, cameraHeight);

		if (doFill)
		{
			camera.fill(camera.bgColor.to24Bit(), camera.useBgAlphaBlending, camera.bgColor.alphaFloat);
		}

		camera.render();

		// var matrix = Matrix.__pool.get();
		var matrix = new Matrix();
		// matrix.translate(-scrollRect.x, -scrollRect.y);
		var scrollRect = camera._scrollRect.scrollRect;
		matrix.scale(scrollRect.width / bitmapData.width, scrollRect.height / bitmapData.height);
		if (customAngle != null)
		{
			matrix.translate(-bitmapData.width / 2, -bitmapData.height / 2);
			matrix.rotate(FlxMath.mod(customAngle, 360) * flixel.math.FlxAngle.TO_RAD);
			matrix.translate(bitmapData.width / 2, bitmapData.height / 2);
		}

		matrix.translate(-camera.x * FlxG.scaleMode.scale.x, -camera.y * FlxG.scaleMode.scale.y);
		// matrix.translate(-camera.canvas.x, -camera.canvas.y);
		matrix.translate(-FlxG.scaleMode.offset.x, -FlxG.scaleMode.offset.y);
		// matrix.translate(-camera.x * FlxG.scaleMode.scale.x, -camera.y * FlxG.scaleMode.scale.y);

		filterRenderer.drawableToBitmapData(graphic, bitmapData, matrix);

		// Matrix.__pool.release(matrix);

		if (renderFilters && camera.filtersEnabled)
		{
			applyFilters(bitmapData, camera.filters, keyCashe);
		}

		if (resetDrawCalls)
		{
			camera.clearDrawStack();
		}
		camera.canvas.graphics.clear();

		/*
		@:privateAccess
		if (disableConvert)
		{
			// filterRenderer.getCurrentBitmap(bitmapData);
			// var texture = filterRenderer.renderer.__context3D.__state.renderToTexture;
			// tex2.uploadCompressedTextureFromByteArray( atf2, 0 );
			// if (bitmapData.__texture == null)
			// 	bitmapData.__texture = context.createTexture(texture.width, texture.height, texture.format, false);
			bitmapData.__texture = filterRenderer.renderer.__context3D.__state.renderToTexture;
		}
		*/
		return bitmapData;
	}

	public static function applyFilters(bitmapData:BitmapData, filters:Array<BitmapFilter>, ?key:String, ?outBitmapData:BitmapData)
	{
		if (filters == null || filters.length == 0) return;
		key ??= "anonim";
		key += "_" + bitmapData.width + "_" + bitmapData.height;
		outBitmapData ??= bitmapData;
		filterRenderer.applyFilter(bitmapData, outBitmapData,
			getBitmapCashe(key + "_Filt1", bitmapData.width, bitmapData.height),
			getBitmapCashe(key + "_Filt2", bitmapData.width, bitmapData.height),
			filters);
	}

	@:access(openfl.display.BitmapData)
	public static function getBitmapCashe(key:String, width:Int, height:Int)
	{
		var bitmap = _bitmapDrawCashe.get(key);
		if (bitmap != null && bitmap.__isValid)
		{
			bitmap.disposeImage();
			// if (bitmap.__texture == null)
			{
				// if (bitmap.image != null)
				// 	bitmap.image.premultiplied = true;
				// bitmap.__surface = null;
				bitmap.getTexture(filterRenderer.hardwareRenderer.__context3D);
			}
			return bitmap;
		}

		bitmap = new BitmapData(width, height, true, 0);

		bitmap.disposeImage();
		bitmap.getTexture(filterRenderer.hardwareRenderer.__context3D);

		// bitmap.image.premultiplied = true;
		// bitmap.__surface = null;
		// bitmap.__surface = lime.graphics.cairo.CairoImageSurface.fromImage(bitmap.image);

		// bitmap.readable = true;
		// bitmap.image.data = null;

		_bitmapDrawCashe.set(key, bitmap);
		// trace([for (i in _bitmapDrawCashe.keys()) i].join(", "));
		return bitmap;
	}

	static var _bitmapDrawCashe = new Map<String, BitmapData>();
}