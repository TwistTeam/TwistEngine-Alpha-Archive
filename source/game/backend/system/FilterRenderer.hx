package game.backend.system;

import flixel.math.FlxPoint;
import flixel.system.FlxAssets.FlxShader;
import flixel.FlxCamera;

import openfl.display.BitmapData;
import openfl.display.BlendMode;
import openfl.display.DisplayObjectRenderer;
import openfl.display.Graphics;
import openfl.display.OpenGLRenderer;
import openfl.display.IBitmapDrawable;
import openfl.display3D.Context3D;
import openfl.display3D.Context3DClearMask;
import openfl.display3D.textures.TextureBase;
import openfl.filters.BitmapFilter;
import openfl.filters.BlurFilter;
import openfl.filters.ShaderFilter;
import openfl.geom.ColorTransform;
import openfl.geom.Matrix;
import openfl.geom.Point;
import openfl.geom.Rectangle;
import openfl.utils.ByteArray;

import openfl.display._internal.Context3DGraphics;
#if (js && html5)
import openfl.display.CanvasRenderer;
import openfl.display._internal.CanvasGraphics as GfxRenderer;
import lime._internal.graphics.ImageCanvasUtil;
#else
import openfl.display.CairoRenderer;
import openfl.display._internal.CairoGraphics as GfxRenderer;
#end

import lime.graphics.cairo.*;

import openfl.utils._internal.UInt8Array;
import lime.graphics.Image;
import lime.graphics.ImageBuffer;
import lime.graphics.ImageChannel;

// TODO: Support for CPU based games (Cairo/Canvas only renderers)
@:access(openfl.display.BitmapData)
@:access(openfl.display.CanvasRenderer)
@:access(openfl.display.CairoRenderer)
@:access(openfl.display.DisplayObject)
@:access(openfl.display.OpenGLRenderer)
@:access(openfl.display.Stage)
@:access(openfl.display.Graphics)
@:access(openfl.display.Shader)
@:access(openfl.display3D.Context3D)
@:access(openfl.filters.BitmapFilter)
@:access(openfl.geom.ColorTransform)
@:access(openfl.geom.Rectangle)
class FilterRenderer
{
	public var pushToImageData:Bool = false;
	public var clearColors:Bool = true;

	public var hardwareRenderer:OpenGLRenderer;

	public function new()
	{
		hardwareRenderer = new OpenGLRenderer(FlxG.game.stage.context3D);
		hardwareRenderer.__worldTransform = new Matrix();
		hardwareRenderer.__worldColorTransform = new ColorTransform();

		// context = new openfl.display3D.Context3D(null);
	}

	public function applyFilter(startBmp:BitmapData, outBmp:BitmapData, casheBmp:BitmapData, casheBmp2:BitmapData, filters:Array<BitmapFilter>, ?rect:Rectangle, ?clipRect:Rectangle)
	{
		if (filters == null)
			return;

		var context = hardwareRenderer.__context3D;

		hardwareRenderer.__setBlendMode(NORMAL);
		hardwareRenderer.__worldAlpha = 1;

		hardwareRenderer.__worldTransform.identity();
		hardwareRenderer.__worldColorTransform.__identity();

		// var clipWidth = rect?.width ?? outBmp.width;
		// var clipHeight = rect?.height ?? outBmp.height;
		// bitmap.__setUVRect(context, 0, 0, clipWidth, clipHeight);
		// bitmap2.__setUVRect(context, 0, 0, clipWidth, clipHeight);
		// bitmap3.__setUVRect(context, 0, 0, clipWidth, clipHeight);

		hardwareRenderer.__setRenderTarget(outBmp);

		if (startBmp != outBmp)
		{
			var _oldRenderTransform = startBmp.__renderTransform.clone();
			if (rect != null)
				startBmp.__renderTransform.translate(Math.abs(rect.x), Math.abs(rect.y));
			if (clipRect != null)
			{
				startBmp.__renderTransform.translate( -clipRect.x, -clipRect.y);
				clipRect.x = Math.abs(rect.x);
				clipRect.y = Math.abs(rect.y);
			}
			if (clearColors)
				context.clear(0, 0, 0, 0, 0, 0, Context3DClearMask.COLOR);
			hardwareRenderer.__scissorRect(clipRect);
			hardwareRenderer.__renderFilterPass(startBmp, hardwareRenderer.__defaultDisplayShader, true);
			hardwareRenderer.__scissorRect();
			startBmp.__renderTransform.copyFrom(_oldRenderTransform);
		}

		var bitmap:BitmapData = outBmp;
		var bitmap2:BitmapData = casheBmp;
		var bitmap3:BitmapData = casheBmp2;

		for (filter in filters)
		{
			if (filter.__preserveObject)
			{
				hardwareRenderer.__setRenderTarget(bitmap3);
				hardwareRenderer.__renderFilterPass(bitmap, hardwareRenderer.__defaultDisplayShader, filter.__smooth);
			}

			for (i in 0...filter.__numShaderPasses)
			{
				hardwareRenderer.__setBlendMode(filter.__shaderBlendMode);
				hardwareRenderer.__setRenderTarget(bitmap2);
				hardwareRenderer.__renderFilterPass(bitmap, filter.__initShader(hardwareRenderer, i, filter.__preserveObject ? bitmap3 : null), filter.__smooth);

				hardwareRenderer.__setRenderTarget(bitmap);
				hardwareRenderer.__renderFilterPass(bitmap2, hardwareRenderer.__defaultDisplayShader, filter.__smooth);
			}

			filter.__renderDirty = false;
		}

		if (pushToImageData || openfl.Lib.current.stage.context3D == null)
			writeCurToBitmap(outBmp);

		hardwareRenderer.__context3D.setRenderToBackBuffer();
	}

	function checkBitmapImage(bitmap:BitmapData)
	{
		if (bitmap == null || bitmap.image != null && bitmap.image.data != null) return;
		#if sys
		var buffer = new ImageBuffer(new UInt8Array(bitmap.width * bitmap.height * 4), bitmap.width, bitmap.height);
		buffer.format = BGRA32;
		buffer.premultiplied = true;

		bitmap.image = new Image(buffer, 0, 0, bitmap.width, bitmap.height);

		// #elseif (js && html5)
		// var buffer = new ImageBuffer (null, width, height);
		// var canvas:CanvasElement = cast Browser.document.createElement ("canvas");
		// buffer.__srcCanvas = canvas;
		// buffer.__srcContext = canvas.getContext ("2d");
		//
		// image = new Image (buffer, 0, 0, width, height);
		// image.type = CANVAS;
		//
		// if (fillColor != 0) {
		//
		// image.fillRect (image.rect, fillColor);
		//
		// }
		#else
		bitmap.image = new Image(null, 0, 0, bitmap.width, bitmap.height, 0x0);
		#end

		bitmap.image.transparent = bitmap.transparent;
		bitmap.image.version = 0;

		bitmap.__isValid = true;
		bitmap.readable = true;
	}

	public function writeCurToBitmap(bitmap:BitmapData, ?renderBuffer:TextureBase, ?format:Null<Int>)
	{
		// if (bitmap == null) return;
		var gl = hardwareRenderer.__gl;
		// if (renderBuffer == null) return;
		renderBuffer ??= bitmap.getTexture(hardwareRenderer.__context3D);
		checkBitmapImage(bitmap);
		@:privateAccess
		gl.readPixels(0, 0, bitmap.width, bitmap.height, renderBuffer.__format, format ?? /* gl.FASTEST */ gl.UNSIGNED_BYTE, bitmap.image.data);
		@:privateAccess
		bitmap.__textureVersion = -1;
	}

	public function drawableToBitmapData(object:IBitmapDrawable, target:BitmapData, ?matrix:Matrix, ?clipRect:Rectangle)
	{
		if (object == null || target == null) return;

		if (matrix != null)
			hardwareRenderer.__worldTransform.copyFrom(matrix);
		else
			hardwareRenderer.__worldTransform.identity();
		// target.__update(false, true);

		/*
		if (openfl.Lib.current.stage.context3D == null || true)
		{
			checkBitmapImage(target);
			target.fillRect(target.rect, 0);
			#if (js && html5)
			ImageCanvasUtil.convertToCanvas(target.image);
			@:privateAccess
			var softRenderer = new CanvasRenderer(target.image.buffer.__srcContext);
			#else
			var softRenderer = new CairoRenderer(new Cairo(target.getSurface()));
			#end
			softRenderer.__allowSmoothing = true;
			softRenderer.__worldTransform = new Matrix();
			softRenderer.__worldAlpha = 1;
			softRenderer.__worldColorTransform = new ColorTransform();

			#if (js && html5)
			target.__drawCanvas(target, softRenderer);
			#else
			target.__drawCairo(target, softRenderer);
			#end

			return target;
		}
		*/

		if (clipRect != null)
		{
			hardwareRenderer.__worldTransform.translate( -clipRect.x, -clipRect.y);
			clipRect.x = Math.abs(clipRect.x);
			clipRect.y = Math.abs(clipRect.y);
		}

		var context = hardwareRenderer.__context3D;
		var cacheRTT = context.__state.renderToTexture;
		var cacheRTTDepthStencil = context.__state.renderToTextureDepthStencil;
		var cacheRTTAntiAlias = context.__state.renderToTextureAntiAlias;
		var cacheRTTSurfaceSelector = context.__state.renderToTextureSurfaceSelector;
		// context.setRenderToBackBuffer();

		hardwareRenderer.__setRenderTarget(target);
		var renderBuffer = /*target.__texture ?? */target.getTexture(hardwareRenderer.__context3D);
		context.setRenderToTexture(renderBuffer);

		// if (pushToImageData)
		// 	target.fillRect(target.rect, 0);
		// else
		if (clearColors)
			context.clear(0, 0, 0, 0, 0, 0, Context3DClearMask.COLOR);
		// hardwareRenderer.__clear();

		hardwareRenderer.__scissorRect(clipRect);
		hardwareRenderer.__renderDrawable(object);
		if (pushToImageData || openfl.Lib.current.stage.context3D == null)
			writeCurToBitmap(target, renderBuffer);
		hardwareRenderer.__scissorRect();

		hardwareRenderer.__setRenderTarget(null);
		if (cacheRTT != null)
		{
			context.setRenderToTexture(cacheRTT, cacheRTTDepthStencil, cacheRTTAntiAlias, cacheRTTSurfaceSelector);
		}
		else
		{
			context.setRenderToBackBuffer();
		}
	}
	public function drawablesToBitmapData<T:IBitmapDrawable>(objects:Array<T>, target:BitmapData, ?matrix:Matrix, ?clipRect:Rectangle)
	{
		if (objects == null || objects.length == 0 || target == null) return;

		if (matrix != null)
			hardwareRenderer.__worldTransform.copyFrom(matrix);
		else
			hardwareRenderer.__worldTransform.identity();
		// target.__update(false, true);

		/*
		if (openfl.Lib.current.stage.context3D == null || true)
		{
			checkBitmapImage(target);
			target.fillRect(target.rect, 0);
			#if (js && html5)
			ImageCanvasUtil.convertToCanvas(target.image);
			@:privateAccess
			var softRenderer = new CanvasRenderer(target.image.buffer.__srcContext);
			#else
			var softRenderer = new CairoRenderer(new Cairo(target.getSurface()));
			#end
			softRenderer.__allowSmoothing = true;
			softRenderer.__worldTransform = new Matrix();
			softRenderer.__worldAlpha = 1;
			softRenderer.__worldColorTransform = new ColorTransform();

			#if (js && html5)
			target.__drawCanvas(target, softRenderer);
			#else
			target.__drawCairo(target, softRenderer);
			#end

			return target;
		}
		*/

		if (clipRect != null)
		{
			hardwareRenderer.__worldTransform.translate( -clipRect.x, -clipRect.y);
			clipRect.x = Math.abs(clipRect.x);
			clipRect.y = Math.abs(clipRect.y);
		}


		var context = hardwareRenderer.__context3D;
		var cacheRTT = context.__state.renderToTexture;
		var cacheRTTDepthStencil = context.__state.renderToTextureDepthStencil;
		var cacheRTTAntiAlias = context.__state.renderToTextureAntiAlias;
		var cacheRTTSurfaceSelector = context.__state.renderToTextureSurfaceSelector;
		// context.setRenderToBackBuffer();

		hardwareRenderer.__setRenderTarget(target);
		var renderBuffer = /*target.__texture ?? */target.getTexture(hardwareRenderer.__context3D);
		context.setRenderToTexture(renderBuffer);

		// if (pushToImageData)
		// 	target.fillRect(target.rect, 0);
		// else
		if (clearColors)
			context.clear(0, 0, 0, 0, 0, 0, Context3DClearMask.COLOR);
		// hardwareRenderer.__clear();

		hardwareRenderer.__scissorRect(clipRect);

		for (i in objects) hardwareRenderer.__renderDrawable(i);
		if (pushToImageData || openfl.Lib.current.stage.context3D == null)
			writeCurToBitmap(target, renderBuffer);

		hardwareRenderer.__scissorRect();

		hardwareRenderer.__setRenderTarget(null);
		if (cacheRTT != null)
		{
			context.setRenderToTexture(cacheRTT, cacheRTTDepthStencil, cacheRTTAntiAlias, cacheRTTSurfaceSelector);
		}
		else
		{
			context.setRenderToBackBuffer();
		}
	}
}