package game.shaders;

import game.states.playstate.PlayState;

class PixelSplashShaderRef
{
	public var shader:PixelSplashShader;

	public function dispose(value:Float)
	{
		shader = null;
	}

	public var pixel(default, set):Bool;

	inline function set_pixel(val:Bool):Bool
	{
		final pixelSize:Float = val ? PlayState.daPixelZoom : 1;
		#if !macro
		shader.uBlocksize.value = [pixelSize, pixelSize];
		#end
		return pixel = val;
	}

	public function copyValues(tempShader:RGBPalette)
	{
		#if !macro
		if (tempShader != null)
		{
			for (i in 0...3)
			{
				shader.r.value[i] = tempShader.shader.r.value[i];
				shader.g.value[i] = tempShader.shader.g.value[i];
				shader.b.value[i] = tempShader.shader.b.value[i];
			}
			shader.mult.value[0] = tempShader.shader.mult.value[0];
		}
		else
			shader.mult.value[0] = 0.0;
		#end
	}

	public function new(isRealyPixel:Bool = false)
	{
		shader = new PixelSplashShader();
		#if !macro
		shader.r.value = [0, 0, 0];
		shader.g.value = [0, 0, 0];
		shader.b.value = [0, 0, 0];
		shader.mult.value = [1];
		#end
		pixel = isRealyPixel;
	}
}

class PixelSplashShader extends RGBPalette.RGBPaletteShader
{
	@:glFragmentSource('
		#pragma header
		uniform vec2 uBlocksize;
		void main() {
			gl_FragColor = flixel_texture2DRGBPixel(bitmap, floor(coord * blocks) / blocks);
		}')
	public function new()
	{
		super();
	}
}
