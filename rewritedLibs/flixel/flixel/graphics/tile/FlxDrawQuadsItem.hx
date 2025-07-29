package flixel.graphics.tile;

import flixel.FlxCamera;
import flixel.graphics.frames.FlxFrame;
import flixel.graphics.tile.FlxDrawBaseItem.FlxDrawItemType;
import flixel.graphics.tile.FlxGraphicsShader;
import flixel.math.FlxMatrix;
import flixel.system.FlxAssets.FlxShader;
import openfl.Vector;
import openfl.display.BitmapData;
import openfl.display.ShaderParameter;
import openfl.geom.ColorTransform;
import openfl.geom.Matrix;
import openfl.geom.Rectangle;

@:access(openfl.geom.Matrix)
@:access(openfl.geom.Rectangle)
@:access(openfl.display.Graphics)
@:access(openfl.display.BitmapData)
class FlxDrawQuadsItem extends FlxDrawBaseItem<FlxDrawQuadsItem>
{
	public static inline var VERTICES_PER_QUAD = 4;

	public var shader:FlxShader;

	var rects:Vector<Float> = new Vector<Float>();
	var transforms:Vector<Float> = new Vector<Float>();
	var alphas:Array<Float> = [];
	var colorMultipliers:Array<Float>;
	var colorOffsets:Array<Float>;

	public function new()
	{
		type = FlxDrawItemType.TILES;
		super();
	}

	public override function reset():Void
	{
		super.reset();
		rects.length = 0;
		transforms.length = 0;
		alphas.resize(0);
		shader = null;
		// alphas.splice(0, alphas.length);
		// if (colorMultipliers != null)
			colorMultipliers?.resize(0);
			// colorMultipliers.splice(0, colorMultipliers.length);
		// if (colorOffsets != null)
			// colorOffsets.splice(0, colorOffsets.length);
			colorOffsets?.resize(0);
	}

	public override function dispose():Void
	{
		super.dispose();
		rects = null;
		transforms = null;
		alphas = null;
		colorMultipliers = null;
		colorOffsets = null;
		shader = null;
	}

	public function addQuad(frame:FlxFrame, matrix:FlxMatrix, ?transform:ColorTransform):Void
	{
		var rect = frame.frame;

		rects.push(rect.x);
		rects.push(rect.y);
		rects.push(rect.width);
		rects.push(rect.height);

		transforms.push(matrix.a);
		transforms.push(matrix.b);
		transforms.push(matrix.c);
		transforms.push(matrix.d);
		transforms.push(matrix.tx);
		transforms.push(matrix.ty);

		var lena = alphas.length;
		alphas.resize(lena + VERTICES_PER_QUAD);

		if (colored || hasColorOffsets)
		{
			colorOffsets ??= [];
			colorMultipliers ??= [];

			var lenm = colorMultipliers.length;
			colorMultipliers.resize(lenm + 4 * VERTICES_PER_QUAD);
			var leno = colorOffsets.length;
			colorOffsets.resize(leno + 4 * VERTICES_PER_QUAD);

			if (transform != null)
			{
				for (_ in 0...VERTICES_PER_QUAD)
				{
					colorMultipliers[lenm++] = transform.redMultiplier;
					colorMultipliers[lenm++] = transform.greenMultiplier;
					colorMultipliers[lenm++] = transform.blueMultiplier;
					colorMultipliers[lenm++] = 1.0; // transform.alphaMultiplier;
					colorOffsets[leno++] = transform.redOffset;
					colorOffsets[leno++] = transform.greenOffset;
					colorOffsets[leno++] = transform.blueOffset;
					colorOffsets[leno++] = transform.alphaOffset;
					alphas[lena++] = transform.alphaMultiplier;
				}
			}
			else
			{
				for (_ in 0...VERTICES_PER_QUAD)
				{
					colorMultipliers[lenm++] = 1.0;
					colorMultipliers[lenm++] = 1.0;
					colorMultipliers[lenm++] = 1.0;
					colorMultipliers[lenm++] = 1.0;
					colorOffsets[leno++] = 0.0;
					colorOffsets[leno++] = 0.0;
					colorOffsets[leno++] = 0.0;
					colorOffsets[leno++] = 0.0;
					alphas[lena++] = 1.0;
				}
			}
		}
		else
		{
			var alphMult = transform?.alphaMultiplier ?? 1.0;
			for (_ in 0...VERTICES_PER_QUAD)
			{
				alphas[lena++] = alphMult;
			}
		}
	}

	public static var missingBitmap(get, null):BitmapData; // Source reference lol
	static function get_missingBitmap():BitmapData
	{
		if (missingBitmap == null)
		{
			missingBitmap = new BitmapData(100, 100, false, 0xFF000000);
			var rect = new Rectangle();
			rect.setTo(0, 0, missingBitmap.width / 2, missingBitmap.height / 2);
			missingBitmap.fillRect(rect, 0xFFFF00FF);
			rect.setTo(rect.width, rect.height, missingBitmap.width, missingBitmap.height);
			missingBitmap.fillRect(rect, 0xFFFF00FF);
		}
		return missingBitmap;
	}

	public override function render(camera:FlxCamera):Void
	{
		if (@:bypassAccessor rects.length == 0)
			return;
		final canvasGraphics = camera.canvas.graphics;

		canvasGraphics.overrideBlendMode(blend);

		var shader = this.shader ?? graphics.shader ?? camera.defaultShader;

		var bitmap = graphics.bitmap;
		if (shader == null || bitmap == null || (!bitmap.readable && bitmap.__texture == null))
		{
			// trace(shader == null, bitmap == null, !bitmap.readable, bitmap.__texture == null, (!bitmap.readable && bitmap.__texture == null));
			var matr = new Matrix();
			if (bitmap != null)
			{
				matr.scale(bitmap.width / missingBitmap.width, bitmap.height / missingBitmap.height);
			}
			if (shader == null)
			{
				canvasGraphics.__commands.beginBitmapFill(missingBitmap, matr, true, false);
			}
			else
			{
				var bitmapInput = shader.bitmap;
				bitmapInput.input = missingBitmap;
				bitmapInput.filter = NEAREST;
				bitmapInput.wrap = REPEAT;
				bitmapInput.mipFilter = MIPNONE;
				shader.alpha.value = alphas;
				shader.colorMultiplier.value = colorMultipliers;
				shader.colorOffset.value = colorOffsets;

				setParameterValue(shader.isFlixelDraw, true);
				setParameterValue(shader.hasColorTransform, colored || hasColorOffsets);

				canvasGraphics.beginShaderFill(shader, matr);
			}

			canvasGraphics.__visible = true;
		}
		else
		{
			var bitmapInput = shader.bitmap;
			bitmapInput.input = bitmap;
			bitmapInput.filter = (FlxSprite.allowAntialiasing && (camera.antialiasing || antialiasing)) ? FlxSprite.defaultTextureFilter : NEAREST;
			bitmapInput.mipFilter = FlxSprite.defaultMipFilter; // todo: a separate parameter
			bitmapInput.lodBias = FlxSprite.defaultLodBias; // todo: a separate parameter
			shader.alpha.value = alphas;
			shader.colorMultiplier.value = colorMultipliers;
			shader.colorOffset.value = colorOffsets;

			setParameterValue(shader.isFlixelDraw, true);
			setParameterValue(shader.hasColorTransform, colored || hasColorOffsets);

			canvasGraphics.beginShaderFill(shader);
		}

		// canvasGraphics.drawQuads(rects, null, transforms);

		var tileRect:Rectangle = new Rectangle();
		var tileTransform:Matrix = new Matrix();

		var ri:Int;

		var minX:Float = Math.POSITIVE_INFINITY;
		var minY:Float = Math.POSITIVE_INFINITY;
		var maxX:Float = Math.NEGATIVE_INFINITY;
		var maxY:Float = Math.NEGATIVE_INFINITY;
		var cuah:Float;

		var i:Int = 0;
		var lena = Math.floor(rects.length / 4);
		while (i < lena)
		{
			ri = i * 4;
			tileRect.setTo(0, 0, rects[ri + 2], rects[ri + 3]);

			if (tileRect.width <= 0 || tileRect.height <= 0)
			{
				i++;
				continue;
			}

			ri = i * 6;
			tileTransform.setTo(transforms[ri], transforms[ri + 1], transforms[ri + 2], transforms[ri + 3], transforms[ri + 4], transforms[ri + 5]);

			tileRect.__transform(tileRect, tileTransform);

			cuah = tileRect.x;
			if (minX > cuah)
				minX = cuah;
			cuah = tileRect.y;
			if (minY > cuah)
				minY = cuah;

			cuah = tileRect.right;
			if (maxX < cuah)
				maxX = cuah;
			cuah = tileRect.bottom;
			if (maxY < cuah)
				maxY = cuah;
			i++;
		}

		canvasGraphics.__inflateBounds(minX, minY);
		canvasGraphics.__inflateBounds(maxX, maxY);

		canvasGraphics.__commands.drawQuads(rects, null, transforms);

		canvasGraphics.__dirty = true;
		canvasGraphics.__visible = true;

		super.render(camera);
	}

	public static inline function setParameterValue(parameter:ShaderParameter<Bool>, value:Bool):Void
	{
		if (parameter.value == null)
		{
			parameter.value = [value];
		}
		else
		{
			parameter.value[0] = value;
		}
	}
}
