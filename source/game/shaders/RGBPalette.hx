package game.shaders;

import flixel.util.FlxColor;

class RGBPalette
{
	public var shader(default, null):RGBPaletteShader = new RGBPaletteShader();
	public var r(default, set):FlxColor;
	public var g(default, set):FlxColor;
	public var b(default, set):FlxColor;
	public var mult(default, set):Float;

	public function dispose(value:Float)
	{
		shader = null;
	}

	function set_r(color:FlxColor)
	{
		r = color;
		#if !macro
		shader.r.value = [color.redFloat, color.greenFloat, color.blueFloat];
		#end
		return color;
	}

	function set_g(color:FlxColor)
	{
		g = color;
		#if !macro
		shader.g.value = [color.redFloat, color.greenFloat, color.blueFloat];
		#end
		return color;
	}

	function set_b(color:FlxColor)
	{
		b = color;
		#if !macro
		shader.b.value = [color.redFloat, color.greenFloat, color.blueFloat];
		#end
		return color;
	}

	function set_mult(value:Float)
	{
		mult = FlxMath.bound(value, 0.0, 1.0);
		#if !macro
		shader.mult.value = [mult];
		#end
		return value;
	}

	public function new()
	{
		r = 0xFFFF0000;
		g = 0xFF00FF00;
		b = 0xFF0000FF;
		mult = 1.0;
	}
}

// automatic handler for easy usability
class RGBShaderReference
{
	public var r(get, set):FlxColor;
	public var g(get, set):FlxColor;
	public var b(get, set):FlxColor;
	public var mult(get, set):Float;
	public var enabled(default, set):Bool = true;

	public var parent(default, set):RGBPalette;

	var _owner:FlxSprite;
	var _original:RGBPalette;

	public function new(owner:FlxSprite, ref:RGBPalette)
	{
		_owner = owner;
		parent = _original = ref;
	}

	public function dispose(value:Float)
	{
		parent = null;
		_owner = null;
		_original = null;
	}

	function get_r()
		return parent.r;

	function get_g()
		return parent.g;

	function get_b()
		return parent.b;

	function get_mult()
		return parent.mult;

	function set_r(value:FlxColor)
	{
		if (allowNew && value != _original.r)
			cloneOriginal();
		return parent.r = value;
	}

	function set_g(value:FlxColor)
	{
		if (allowNew && value != _original.g)
			cloneOriginal();
		return parent.g = value;
	}

	function set_b(value:FlxColor)
	{
		if (allowNew && value != _original.b)
			cloneOriginal();
		return parent.b = value;
	}

	function set_mult(value:Float)
	{
		if (allowNew && value != _original.mult)
			cloneOriginal();
		return parent.mult = value;
	}

	function set_enabled(value:Bool)
	{
		_owner.shader = value ? parent.shader : null;
		return enabled = value;
	}

	function set_parent(value:RGBPalette):RGBPalette
	{
		_owner.shader = enabled ? value.shader : null;
		return parent = value;
	}

	public var allowNew = true;

	function cloneOriginal()
	{
		if (!allowNew)
			return;

		allowNew = false;
		if (_original != parent)
			return;

		parent = new RGBPalette();
		parent.r = _original.r;
		parent.g = _original.g;
		parent.b = _original.b;
		parent.mult = _original.mult;
		_owner.shader = parent.shader;
		// trace('created new shader');
	}
}

class RGBPaletteShader extends FlxShader
{
	@:glFragmentHeader('
		uniform vec3 r;
		uniform vec3 g;
		uniform vec3 b;
		uniform float mult;

		vec3 applyRGBEffect(vec3 color)
		{
			return mix(color, min(color.r * r + color.g * g + color.b * b, vec3(1.0)), mult);
		}
		vec4 applyRGBEffect(vec4 color)
		{
			return vec4(applyRGBEffect(color.rgb), color.a);
		}
		vec4 flixel_texture2DRGB(sampler2D bitmap, vec2 coord) {
			vec4 color = texture2D(bitmap, coord);
			if(color.a == 0.0 || mult == 0.0) {
				return flixel_applyColorTransform(color);
			}
			return flixel_applyColorTransform(applyRGBEffect(color));
		}', true)
	@:glFragmentSource('
		#pragma header

		void main() {
			gl_FragColor = flixel_texture2DRGB(bitmap, openfl_TextureCoordv);
		}')
	public function new()
	{
		super();
	}
}
