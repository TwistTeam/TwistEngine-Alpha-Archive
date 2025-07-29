package flixel.graphics.tile;

import flixel.FlxCamera;
import flixel.graphics.frames.FlxFrame;
import flixel.graphics.tile.FlxDrawBaseItem.FlxDrawItemType;
import flixel.math.FlxMatrix;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.system.FlxAssets.FlxShader;
import flixel.util.FlxColor;
import flixel.util.FlxDestroyUtil;
import openfl.display.Graphics;
import openfl.display.ShaderParameter;
import openfl.display.TriangleCulling;
import openfl.geom.ColorTransform;

typedef DrawData<T> = openfl.Vector<T>;

/**
 * @author Zaphod
 */
@:access(openfl.geom.Matrix)
@:access(openfl.display.Graphics)
@:access(openfl.display.BitmapData)
class FlxDrawTrianglesItem extends FlxDrawBaseItem<FlxDrawTrianglesItem>
{
	static var point:FlxPoint = new FlxPoint();
	static var rect:FlxRect = new FlxRect();
	static var bounds:FlxRect = new FlxRect();

	public var shader:FlxShader;
	var alphas:Array<Float> = [];
	var colorMultipliers:Array<Float>;
	var colorOffsets:Array<Float>;

	public var vertices:DrawData<Float> = new DrawData<Float>();
	public var indices:DrawData<Int> = new DrawData<Int>();
	public var uvtData:DrawData<Float> = new DrawData<Float>();
	public var colors:DrawData<Int> = new DrawData<Int>();

	public var verticesPosition:Int = 0;
	public var indicesPosition:Int = 0;
	public var colorsPosition:Int = 0;

	// var bounds:FlxRect = FlxRect.get();

	public function new()
	{
		type = FlxDrawItemType.TRIANGLES;
		super();
	}

	public override function render(camera:FlxCamera):Void
	{
		if (!FlxG.renderTile || numTriangles == 0)
			return;

		var shader = shader ?? graphics.shader ?? camera.defaultShader;

		if (shader == null)
			return;

		final canvasGraphics = camera.canvas.graphics;

		canvasGraphics.overrideBlendMode(blend);

		var bitmapInput = shader.bitmap;
		bitmapInput.input = graphics.bitmap;
		bitmapInput.filter = (FlxSprite.allowAntialiasing && (camera.antialiasing || antialiasing)) ? FlxSprite.defaultTextureFilter : NEAREST;
		bitmapInput.mipFilter = FlxSprite.defaultMipFilter; // todo: a separate parameter
		bitmapInput.lodBias = FlxSprite.defaultLodBias; // todo: a separate parameter
		bitmapInput.wrap = REPEAT; // in order to prevent breaking tiling behaviourin classes that use drawTriangles
		shader.alpha.value = alphas;

		shader.colorMultiplier.value = colorMultipliers;
		shader.colorOffset.value = colorOffsets;

		setParameterValue(shader.isFlixelDraw, true);
		setParameterValue(shader.hasColorTransform, colored || hasColorOffsets);

		canvasGraphics.beginShaderFill(shader);
		canvasGraphics.drawTriangles(vertices, indices, uvtData, TriangleCulling.NONE);

		#if FLX_DEBUG
		if (FlxG.debugger.drawDebug)
		{
			var gfx:Graphics = camera.debugLayer.graphics;
			gfx.lineStyle(1, FlxColor.BLUE, 0.5);
			gfx.drawTriangles(vertices, indices, uvtData);
		}
		#end

		super.render(camera);
	}

	public override function reset():Void
	{
		super.reset();
		vertices.length = 0;
		indices.length = 0;
		uvtData.length = 0;
		colors.length = 0;

		verticesPosition = 0;
		indicesPosition = 0;
		colorsPosition = 0;
		alphas.resize(0);
		if (colorMultipliers != null)
			colorMultipliers.resize(0);
		if (colorOffsets != null)
			colorOffsets.resize(0);
		shader = null;
		/*
		alphas.splice(0, alphas.length);
		if (colorMultipliers != null)
			colorMultipliers.splice(0, colorMultipliers.length);
		if (colorOffsets != null)
			colorOffsets.splice(0, colorOffsets.length);
		*/
		// bounds.set();
	}

	public override function dispose():Void
	{
		super.dispose();

		shader = null;
		vertices = null;
		indices = null;
		uvtData = null;
		colors = null;
		// bounds = FlxDestroyUtil.put(bounds);
		alphas = null;
		colorMultipliers = null;
		colorOffsets = null;
	}

	public function addTriangles(vertices:DrawData<Float>, indices:DrawData<Int>, uvtData:DrawData<Float>, ?colors:DrawData<Int>, ?position:FlxPoint,
			?cameraBounds:FlxRect, ?transform:ColorTransform):Void
	{
		if (position == null)
			position = point.set();

		if (cameraBounds == null)
			cameraBounds = rect.set(0, 0, FlxG.width, FlxG.height);

		var verticesLength:Int = vertices.length;
		var numberOfVertices:Int = verticesLength >> 1;
		var prevIndicesLength:Int = this.indices.length;
		var prevUVTDataLength:Int = this.uvtData.length;
		var prevColorsLength:Int = this.colors.length;
		var prevNumberOfVertices:Int = this.numVertices;

		var tempX:Float, tempY:Float;
		var i:Int = 0;
		var currentVertexPosition:Int = this.vertices.length;

		while (i < verticesLength)
		{
			tempX = position.x + vertices[i];
			tempY = position.y + vertices[i + 1];

			this.vertices[currentVertexPosition++] = tempX;
			this.vertices[currentVertexPosition++] = tempY;

			// if (i == 0)
			// {
			// 	bounds.set(tempX, tempY, 0, 0);
			// }
			// else
			// {
				inflateBounds(bounds, tempX, tempY);
			// }

			i += 2;
		}

		if (cameraBounds.overlaps(bounds))
		{
			for (i in 0...uvtData.length)
			{
				this.uvtData[prevUVTDataLength + i] = uvtData[i];
			}

			var indicesLength:Int = indices.length;
			for (i in 0...indicesLength)
			{
				this.indices[prevIndicesLength + i] = indices[i] + prevNumberOfVertices;
			}

			if (colored)
			{
				for (i in 0...numberOfVertices)
				{
					this.colors[prevColorsLength + i] = colors[i];
				}

				colorsPosition += numberOfVertices;
			}

			verticesPosition += verticesLength;
			indicesPosition += indicesLength;
		}
		else
		{
			this.vertices.splice(this.vertices.length - verticesLength, verticesLength);
		}

		position.putWeak();
		cameraBounds.putWeak();

		var alphaMultiplier = transform?.alphaMultiplier ?? 1.0;
		var len = alphas.length;
		alphas.resize(len + numTriangles * 3);
		var targetLen = alphas.length;
		while (len < targetLen)
		{
			alphas[len++] = alphaMultiplier;
		}

		if (colored || hasColorOffsets)
		{
			colorMultipliers ??= [];
			colorOffsets ??= [];

			var lenm = colorMultipliers.length;
			colorMultipliers.resize(lenm + numTriangles * 3 * 4);
			var leno = colorOffsets.length;
			colorOffsets.resize(leno + numTriangles * 3 * 4);

			if (transform != null)
			{
				targetLen = colorMultipliers.length;
				while (lenm < targetLen)
				{
					colorMultipliers[lenm++] = transform.redMultiplier;
					colorMultipliers[lenm++] = transform.greenMultiplier;
					colorMultipliers[lenm++] = transform.blueMultiplier;
					colorMultipliers[lenm++] = 1.0; // colorMultipliers[lenm++] = transform.alphaMultiplier;
				}
				targetLen = colorOffsets.length;
				while (leno < targetLen)
				{
					colorOffsets[leno++] = transform.redOffset;
					colorOffsets[leno++] = transform.greenOffset;
					colorOffsets[leno++] = transform.blueOffset;
					colorOffsets[leno++] = transform.alphaOffset;
				}
			}
			else
			{
				targetLen = colorMultipliers.length;
				while (lenm < targetLen)
				{
					colorMultipliers[lenm++] = 1;
				}
				targetLen = colorOffsets.length;
				while (leno < targetLen)
				{
					colorOffsets[leno++] = 0;
				}
			}
		}
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

	public static function inflateBounds(bounds:FlxRect, x:Float, y:Float):FlxRect
	{
		if (x < bounds.x)
		{
			bounds.width += bounds.x - x;
			bounds.x = x;
		}
		else if (x > bounds.x + bounds.width)
		{
			bounds.width = x - bounds.x;
		}

		if (y < bounds.y)
		{
			bounds.height += bounds.y - y;
			bounds.y = y;
		}
		else if (y > bounds.y + bounds.height)
		{
			bounds.height = y - bounds.y;
		}

		return bounds;
	}

	public function addQuad(frame:FlxFrame, matrix:FlxMatrix, ?transform:ColorTransform):Void
	{
		var prevVerticesPos:Int = verticesPosition;

		// point.set();
		// point.transform(matrix);

		vertices[prevVerticesPos] = matrix.tx;
		vertices[prevVerticesPos + 1] = matrix.ty;

		uvtData[prevVerticesPos] = frame.uv.x;
		uvtData[prevVerticesPos + 1] = frame.uv.y;

		point.set(frame.frame.width, 0);
		point.transform(matrix);

		vertices[prevVerticesPos + 2] = point.x;
		vertices[prevVerticesPos + 3] = point.y;

		uvtData[prevVerticesPos + 2] = frame.uv.width;
		uvtData[prevVerticesPos + 3] = frame.uv.y;

		point.set(frame.frame.width, frame.frame.height);
		point.transform(matrix);

		vertices[prevVerticesPos + 4] = point.x;
		vertices[prevVerticesPos + 5] = point.y;

		uvtData[prevVerticesPos + 4] = frame.uv.width;
		uvtData[prevVerticesPos + 5] = frame.uv.height;

		point.set(0, frame.frame.height);
		point.transform(matrix);

		vertices[prevVerticesPos + 6] = point.x;
		vertices[prevVerticesPos + 7] = point.y;

		uvtData[prevVerticesPos + 6] = frame.uv.x;
		uvtData[prevVerticesPos + 7] = frame.uv.height;

		var prevNumberOfVertices:Int = numVertices;
		indices[indicesPosition++] = prevNumberOfVertices;
		indices[indicesPosition++] = prevNumberOfVertices + 1;
		indices[indicesPosition++] = prevNumberOfVertices + 2;
		indices[indicesPosition++] = prevNumberOfVertices + 2;
		indices[indicesPosition++] = prevNumberOfVertices + 3;
		indices[indicesPosition++] = prevNumberOfVertices;

		if (colored)
		{
			var red = 1.0;
			var green = 1.0;
			var blue = 1.0;
			var alpha = 1.0;

			if (transform != null)
			{
				red = transform.redMultiplier;
				green = transform.greenMultiplier;
				blue = transform.blueMultiplier;

				#if !neko
				alpha = transform.alphaMultiplier;
				#end
			}

			colors[colorsPosition++] = colors[colorsPosition++] =
				colors[colorsPosition++] = colors[colorsPosition++] = FlxColor.fromRGBFloat(red, green, blue, alpha);
		}

		verticesPosition += 8;
	}

	override function get_numVertices():Int
	{
		return vertices.length >> 1;
	}

	override function get_numTriangles():Int
	{
		return Std.int(indices.length / 3);
	}
}
