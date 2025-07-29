package game.shaders;

import flixel.FlxG;
import flixel.input.mouse.FlxMouse;
import flixel.math.FlxPoint;

/**
	Inherits all the standard flixel glsl nuts and bolts as defined in FlxGraphicsShader
	injects shader toy mainImage in constructor
**/
class FlxToyShader extends FlxShader
{
	/**
		#pragma header injects from glFragmentHeader on FlxGraphicsShader
	**/
	@:glFragmentSource("#pragma header

	// shadertoy uniforms
	uniform float iTime;
	uniform float iTimeDelta;
	uniform float iFrame;
	uniform vec4 iMouse;
	uniform vec3 iResolution;
	uniform sample2D iChannel1;
	uniform sample2D iChannel2;
	uniform sample2D iChannel3;
	#define iChannel0 bitmap
	#define texture flixel_texture2D
	// uniform float iChannelTime[4]; todo !
	// uniform vec3 iChannelResolution[4]; ! todo
	// uniform sampler2D iChanneli; ! todo

	//---------------------------------------------------------------------------------------------

	//!voidmainImage

	//---------------------------------------------------------------------------------------------

	void main()
	{
		// set the color untouched (do nothing),
		// gl_FragColor = flixel_texture2D(iChannel0, openfl_TextureCoordv);

		// store coord so it can be altered (openfl_TextureCoordv is read only)
		vec2 coord = openfl_TextureCoordv;

		// flip y axis to match shader toy
		coord.y = 1.0 - coord.y;

		// then process gl_FragColor with our copy of the shader toy mainImage function
		mainImage(gl_FragColor, coord * openfl_TextureSize);
		gl_FragColor = flixel_applyColorTransform(gl_FragColor);
	}")
	public var void_mainImage:String;

	public function new(?mainImageFunction:String)
	{
		var useDefaultFunction = mainImageFunction == null || mainImageFunction.length == 0;

		if (useDefaultFunction)
		{
			/** the default glsl function that shadertoy uses when you make a new one **/
			mainImageFunction = "
			void mainImage( out vec4 fragColor, in vec2 fragCoord )
			{
				// Normalized pixel coordinates (from 0 to 1)
				vec2 uv = fragCoord/iResolution.xy;

				// Time varying pixel color
				vec3 col = 0.5 + 0.5*cos(iTime+uv.xyx+vec3(0,2,4));

				// Output to screen
				fragColor = vec4(col,1.0);
			}";
		}
		this.void_mainImage = mainImageFunction;

		// inject mainImage function
		glFragmentSource = glFragmentSourceRaw.replace("//!voidmainImage", void_mainImage);
		// #if debug
		// trace('glVertexSource\n$glFragmentSource');
		// #end

		super();

		#if !macro
		// init uniforms so they can be used
		iResolution.value = [0.0, 0.0, 0.0];
		iTime.value = [0.0];
		iTimeDelta.value = [0.0];
		iFrame.value = [0.0];
		iMouse.value = [0.0, 0.0, 0.0, 0.0];
		#end
	}

	public function update(elapsed:Float, ?mouse:FlxMouse)
	{
		#if !macro
		iTime.value[0] += elapsed;
		iTimeDelta.value[0] = elapsed;
		update_iMouse(mouse);
		#end
	}
	@:noCompletion private override function __update():Void
	{
		#if !macro
		iResolution.value[0] = __textureSize.value[0];
		iResolution.value[1] = __textureSize.value[1];
		#end
		super.__update();
	}

	function update_iMouse(mouse:FlxMouse)
	{
		#if !macro
		if (mouse == null)
			return;
		var mousePosition = mouse.getPosition();
		// iMouse.xy is position of mouse
		iMouse.value[0] = mousePosition.x;
		// map y mouse y to shader toy expected
		iMouse.value[1] = iResolution.value[1] - mousePosition.y;

		if (mouse.pressed)
		{
			// mouseDown
			iMouse.value[2] = mousePosition.x;
			iMouse.value[3] = iResolution.value[1] - mousePosition.y;
		}
		else
		{
			// mouseUp
			iMouse.value[2] = 0.0;
			iMouse.value[3] = 0.0;
		}
		mousePosition.put();
		#end
	}
}
