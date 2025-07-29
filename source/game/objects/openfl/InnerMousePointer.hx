package game.objects.openfl;

import flixel.util.FlxGradient;

import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.display.GradientType;
import openfl.display.InterpolationMethod;
import openfl.display.Shape;
import openfl.display.SpreadMethod;
import openfl.geom.Matrix;
import openfl.geom.Point;
import openfl.geom.Rectangle;

@:access(openfl.display.DisplayObject)
class InnerMousePointer extends Bitmap {
	public function new() {
		super(createRadialGradientBitmapData(60, 60, [0xFFFFFFFF, 0x00FFFFFF]), null, true);
		scrollRect = new Rectangle();
	}
	public static function createRadialGradientBitmapData(width:UInt, height:UInt, colors:Array<FlxColor>, interpolate:Bool = true):BitmapData
	{
		if (width < 1)
			width = 1;

		if (height < 1)
			height = 1;

		var gradient:GradientMatrix = FlxGradient.createGradientMatrix(width, height, colors);
		var shape = new Shape();
		var interpolationMethod = interpolate ? InterpolationMethod.RGB : InterpolationMethod.LINEAR_RGB;

		#if flash
		var colors = colors.map(function(c):UInt return c);
		#end
		var matrix = new Matrix();
		matrix.createGradientBox(width, height, 0, 0, 0);
		shape.graphics.beginGradientFill(GradientType.RADIAL, colors, gradient.alpha,
			/*gradient.ratio*/ null, matrix, SpreadMethod.REFLECT, interpolationMethod,
			0);

		shape.graphics.drawRect(0, 0, width, height);

		var data = new BitmapData(width, height, true, FlxColor.TRANSPARENT);
		data.draw(shape);
		return data;
	}

	@:noCompletion var ____rect:Rectangle = new Rectangle();
	@:noCompletion var ____matrix:Matrix = new Matrix();
	@:noCompletion
	override function __enterFrame(deltaTime:Int):Void
	{
		if (parent != null)
		{
			x = parent.mouseX - width / 2;
			y = parent.mouseY - height / 2;
			__scrollRect.setTo(0, 0, width, height);
			// ____rect = parent.getBounds(null);
			// ____rect.x = ____rect.y = 0;
			// __scrollRect = ____rect.intersection(__scrollRect);

			__scrollRect.width = Math.min(__scrollRect.width, parent.width - x);
			__scrollRect.height = Math.min(__scrollRect.height, parent.height - y);
			__scrollRect.x = Math.min(x, 0.0);
			__scrollRect.y = Math.min(y, 0.0);
			scrollRect = __scrollRect;
		}
		super.__enterFrame(deltaTime);
	}
}