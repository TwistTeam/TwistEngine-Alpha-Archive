package flixel.addons.display;

import flixel.graphics.tile.FlxGraphicsShader;
import openfl.display.BitmapData;
import openfl.display.ShaderInput;
import openfl.display.ShaderParameter;
import openfl.display._internal.ShaderBuffer;
import openfl.display3D.Context3D;
import openfl.display3D.Program3D;
import openfl.display3D._internal.GLProgram;
import openfl.display3D._internal.GLShader;
import openfl.utils.ByteArray;
import openfl.utils._internal.Log;

import haxe.extern.EitherType;

/**
 * An wrapper for Flixel/OpenFL's shaders, which takes fragment and vertex source
 * in the constructor instead of using macros, so it can be provided data
 * at runtime (for example, when using mods).
 *
 * HOW TO USE:
 * 1. Create an instance of this class, passing the text of the `.frag` and `.vert` files.
 *    Note that you can set either of these to null (making them both null would make the shader do nothing???).
 * 2. Use `flxSprite.shader = runtimeShader` to apply the shader to the sprite.
 * 3. Use `runtimeShader.setFloat()`, `setBool()` etc. to modify any uniforms.
 * 4. Use `setBitmapData()` to add additional textures as `sampler2D` uniforms
 *
 * @author MasterEric
 * @see https://github.com/openfl/openfl/blob/develop/src/openfl/utils/_internal/ShaderMacro.hx
 * @see https://dixonary.co.uk/blog/shadertoy
 */
@:access(openfl.display3D.Context3D)
@:access(openfl.display3D.Program3D)
@:access(openfl.display.ShaderInput)
@:access(openfl.display.ShaderParameter)
class FlxRuntimeShader extends FlxGraphicsShader
{
	#if FLX_DRAW_QUADS
	// We need to add stuff from FlxGraphicsShader too!
	#else
	// Only stuff from openfl.display.GraphicsShader is needed
	#end
	// These variables got copied from openfl.display.GraphicsShader
	// and from flixel.graphics.tile.FlxGraphicsShader.

	static final PRAGMA_HEADER:String = "#pragma header";
	static final PRAGMA_BODY:String = "#pragma body";

	public var traceErrors:Bool = true;

	/**
	 * Constructs a GLSL shader.
	 * @param fragmentSource The fragment shader source.
	 * @param vertexSource The vertex shader source.
	 * Note you also need to `initialize()` the shader MANUALLY! It can't be done automatically.
	 */
	public function new(?fragmentSource:String, ?vertexSource:String, ?glslVersion:String):Void
	{
		if (glslVersion != null) {
			// Don't set the value (use getDefaultGLVersion) if it's null.
			this.glVersion = glslVersion;
		}

		if (fragmentSource == null)
		{
			this.glFragmentSource = __processFragmentSource(glFragmentSourceRaw);
		}
		else
		{
			this.glFragmentSource = __processFragmentSource(fragmentSource);
		}

		if (vertexSource == null)
		{
			this.glVertexSource = __processVertexSource(glVertexSourceRaw);
		}
		else
		{
			this.glVertexSource = __processVertexSource(vertexSource);
		}

		@:privateAccess {
			// This tells the shader that the glVertexSource/glFragmentSource have been updated.
			this.__glSourceDirty = true;
		}

		super();
	}

	/**
	 * Replace the `#pragma header` and `#pragma body` with the fragment shader header and body.
	 */
	@:noCompletion private function __processFragmentSource(input:String):String
	{
		input = StringTools.replace(input, PRAGMA_HEADER, glFragmentHeaderRaw);
		input = StringTools.replace(input, PRAGMA_BODY, glFragmentBodyRaw);
		return input;
	}

	/**
	 * Replace the `#pragma header` and `#pragma body` with the vertex shader header and body.
	 */
	@:noCompletion private function __processVertexSource(input:String):String
	{
		input = StringTools.replace(input, PRAGMA_HEADER, glVertexHeaderRaw);
		input = StringTools.replace(input, PRAGMA_BODY, glVertexBodyRaw);
		return input;
	}

	public var usesSourceShader(default, null):Bool = false;

	var __lastMessage:String = null;
	@:noCompletion private override function __createGLProgram(vertexSource:String, fragmentSource:String):GLProgram
	{
		var gl = __context.gl;

		var vertexShader = (usesSourceShader ? __createGLShader : __tryCreateGLShader)(vertexSource, gl.VERTEX_SHADER);
		if (!usesSourceShader && __lastMessage != null)
			return null;
		var fragmentShader = (usesSourceShader ? __createGLShader : __tryCreateGLShader)(fragmentSource, gl.FRAGMENT_SHADER);
		if (!usesSourceShader && __lastMessage != null)
			return null;

		var program = gl.createProgram();

		// Fix support for drivers that don't draw if attribute 0 is disabled
		for (param in __paramFloat)
		{
			if (param.name.indexOf("Position") != -1 && StringTools.startsWith(param.name, "openfl_"))
			{
				gl.bindAttribLocation(program, 0, param.name);
				break;
			}
		}

		gl.attachShader(program, vertexShader);
		gl.attachShader(program, fragmentShader);
		gl.linkProgram(program);

		if (gl.getProgramParameter(program, gl.LINK_STATUS) == 0)
		{
			var message = "Unable to initialize the shader program";
			message += "\n" + gl.getProgramInfoLog(program);
			#if !macro
			game.backend.CrashHandler.crashWithCustomMessage("SHADER ISSUE", message, "shader_issue");
			#else
			Log.error(message);
			#end
		}

		return program;
	}

	@:noCompletion private function __tryCreateGLShader(source:String, type:Int):EitherType<String, GLShader>
	{
		var gl = __context.gl;
		var shader:GLShader = gl.createShader(type);
		gl.shaderSource(shader, source);
		gl.compileShader(shader);
		var shaderInfoLog = gl.getShaderInfoLog(shader);
		var hasInfoLog = shaderInfoLog != null && StringTools.trim(shaderInfoLog).length != 0;
		var compileStatus = gl.getShaderParameter(shader, gl.COMPILE_STATUS);

		if (hasInfoLog || compileStatus == 0)
		{
			var message = (compileStatus == 0) ? "Error" : "Info";
			message += (type == gl.VERTEX_SHADER) ? " compiling vertex shader" : " compiling fragment shader";
			message += "\n" + shaderInfoLog + "\n";

			var count:Int = 0;
			for (i in source.split("\n"))
			{
				message += '\n${++count}: $i'; // Now it shows line numbers, yay
			}

			if (compileStatus == 0)
			{
				if (shader != null)
				{
					gl.deleteShader(shader);
					shader = null;
				}
				__lastMessage = message;
				return null;
			}
			else if (hasInfoLog)
			{
				Log.debug(message);
			}
		}
		return shader;
	}

	@:noCompletion private override function __initGL():Void
	{
		usesSourceShader = false;
		autoSetUniforms = true;
		if (__glSourceDirty || __paramBool == null)
		{
			// program?.dispose();
			program = null;

			__inputBitmapData = new Array();
			__paramBool = new Array();
			__paramFloat = new Array();
			__paramInt = new Array();

			glVertexSource = __processGLData(__processGLData(__processGLData(glVertexSource, "uniform"), "in"), "attribute");
			glFragmentSource = __processGLData(glFragmentSource, "uniform");
			__glSourceDirty = false;
		}

		if (__context != null && program == null)
		{
			var gl = __context.gl;

			var vertex = __buildSourcePrefix(false) + glVertexSource;
			var fragment = __buildSourcePrefix(true) + glFragmentSource;

			var id = vertex + fragment;

			if (__context.__programs.exists(id))
			{
				program = __context.__programs.get(id);
			}
			else
			{
				program = __context.createProgram(GLSL);

				// TODO
				// program.uploadSources (vertex, fragment);
				program.__glProgram = __createGLProgram(vertex, fragment);
				if (__lastMessage != null)
				{
					#if macro
					trace(__lastMessage);
					#else
					game.backend.CrashHandler.threadSaveContentWithTime("runtimeShaders/", __lastMessage);
					game.backend.utils.CoolUtil.alert(__lastMessage, "SHADER ISSUE");
					#end
					glVertexSource =  __processVertexSource(glVertexSourceRaw);
					glFragmentSource = __processFragmentSource(glFragmentSourceRaw);
					@:privateAccess {
						// This tells the shader that the glVertexSource/glFragmentSource have been updated.
						this.__glSourceDirty = true;
					}

					__lastMessage = null;
					usesSourceShader = true;
					__data = null;
					__init();
					return;
				}

				__context.__programs.set(id, program);
			}

			if (program != null)
			{
				glProgram = program.__glProgram;

				for (input in __inputBitmapData)
				{
					if (input.__isUniform)
					{
						input.index = gl.getUniformLocation(glProgram, input.name);
					}
					else
					{
						input.index = gl.getAttribLocation(glProgram, input.name);
					}
				}

				for (parameter in __paramBool)
				{
					if (parameter.__isUniform)
					{
						parameter.index = gl.getUniformLocation(glProgram, parameter.name);
					}
					else
					{
						parameter.index = gl.getAttribLocation(glProgram, parameter.name);
					}
				}

				for (parameter in __paramFloat)
				{
					if (parameter.__isUniform)
					{
						parameter.index = gl.getUniformLocation(glProgram, parameter.name);
					}
					else
					{
						parameter.index = gl.getAttribLocation(glProgram, parameter.name);
					}
				}

				for (parameter in __paramInt)
				{
					if (parameter.__isUniform)
					{
						parameter.index = gl.getUniformLocation(glProgram, parameter.name);
					}
					else
					{
						parameter.index = gl.getAttribLocation(glProgram, parameter.name);
					}
				}
			}
		}
	}

	/**
	 * Modify a float parameter of the shader.
	 *
	 * @param name The name of the parameter to modify.
	 * @param value The new value to use.
	 */
	public function setFloat(name:String, value:Float):Void
	{
		var prop:ShaderParameter<Float> = Reflect.field(this.data, name);
		@:privateAccess
		if (prop == null)
		{
			if (traceErrors)
				trace('[WARN] Shader float property ${name} not found.');
			return;
		}
		prop.value = [value];
	}

	/**
	 * Modify a float array parameter of the shader.
	 *
	 * @param name The name of the parameter to modify.
	 * @param value The new value to use.
	 */
	public function setFloatArray(name:String, value:Array<Float>):Void
	{
		var prop:ShaderParameter<Float> = Reflect.field(this.data, name);
		if (prop == null)
		{
			if (traceErrors)
				trace('[WARN] Shader float[] property ${name} not found.');
			return;
		}
		if (value.length < prop.__length)
		{
			if (traceErrors)
				trace('[WARN] Incorrect value of input to the ${name}.');
			return;
		}
		prop.value = value;
	}

	/**
	 * Modify an integer parameter of the shader.
	 *
	 * @param name The name of the parameter to modify.
	 * @param value The new value to use.
	 */
	public function setInt(name:String, value:Int):Void
	{
		var prop:ShaderParameter<Int> = Reflect.field(this.data, name);
		if (prop == null)
		{
			if (traceErrors)
				trace('[WARN] Shader int property ${name} not found.');
			return;
		}
		prop.value = [value];
	}

	/**
	 * Modify an integer array parameter of the shader.
	 *
	 * @param name The name of the parameter to modify.
	 * @param value The new value to use.
	 */
	public function setIntArray(name:String, value:Array<Int>):Void
	{
		var prop:ShaderParameter<Int> = Reflect.field(this.data, name);
		if (prop == null)
		{
			if (traceErrors)
				trace('[WARN] Shader int[] property ${name} not found.');
			return;
		}
		if (value.length < prop.__length)
		{
			if (traceErrors)
				trace('[WARN] Incorrect value of input to the ${name}.');
			return;
		}
		prop.value = value;
	}

	/**
	 * Modify a boolean parameter of the shader.
	 * @param name The name of the parameter to modify.
	 * @param value The new value to use.
	 */
	public function setBool(name:String, value:Bool):Void
	{
		var prop:ShaderParameter<Bool> = Reflect.field(this.data, name);
		if (prop == null)
		{
			if (traceErrors)
				trace('[WARN] Shader bool property ${name} not found.');
			return;
		}
		prop.value = [value];
	}

	/**
	 * Modify a boolean array parameter of the shader.
	 * @param name The name of the parameter to modify.
	 * @param value The new value to use.
	 */
	public function setBoolArray(name:String, value:Array<Bool>):Void
	{
		var prop:ShaderParameter<Bool> = Reflect.field(this.data, name);
		if (prop == null)
		{
			if (traceErrors)
				trace('[WARN] Shader bool[] property ${name} not found.');
			return;
		}
		if (value.length < prop.__length)
		{
			if (traceErrors)
				trace('[WARN] Incorrect value of input to the ${name}.');
			return;
		}
		prop.value = value;
	}

	/**
	 * Modify a bitmap data parameter of the shader.
	 * @param name The name of the parameter to modify.
	 * @param value The new value to use.
	 */
	public function setBitmapData(name:String, value:BitmapData):Void
	{
		var prop:ShaderInput<BitmapData> = Reflect.field(this.data, name);
		if (prop == null)
		{
			if (traceErrors)
				trace('[WARN] Shader sampler2D property ${name} not found.');
			return;
		}
		prop.input = value;
	}

	/**
	 * Retrieve a float parameter of the shader.
	 * @param name The name of the parameter to retrieve.
	 * @return The value of the parameter.
	 */
	public function getFloat(name:String):Null<Float>
	{
		var prop:ShaderParameter<Float> = Reflect.field(this.data, name);
		if (prop == null || prop.value.length == 0)
		{
			if (traceErrors)
				trace('[WARN] Shader float property ${name} not found.');
			return null;
		}
		return prop.value[0];
	}

	/**
	 * Retrieve a float array parameter of the shader.
	 * @param name The name of the parameter to retrieve.
	 * @return The value of the parameter.
	 */
	public function getFloatArray(name:String):Null<Array<Float>>
	{
		var prop:ShaderParameter<Float> = Reflect.field(this.data, name);
		if (prop == null)
		{
			if (traceErrors)
				trace('[WARN] Shader float[] property ${name} not found.');
			return null;
		}
		return prop.value;
	}

	/**
	 * Retrieve an integer parameter of the shader.
	 * @param name The name of the parameter to retrieve.
	 * @return The value of the parameter.
	 */
	public function getInt(name:String):Null<Int>
	{
		var prop:ShaderParameter<Int> = Reflect.field(this.data, name);
		if (prop == null || prop.value.length == 0)
		{
			if (traceErrors)
				trace('[WARN] Shader int property ${name} not found.');
			return null;
		}
		return prop.value[0];
	}

	/**
	 * Retrieve an integer array parameter of the shader.
	 * @param name The name of the parameter to retrieve.
	 * @return The value of the parameter.
	 */
	public function getIntArray(name:String):Null<Array<Int>>
	{
		var prop:ShaderParameter<Int> = Reflect.field(this.data, name);
		if (prop == null)
		{
			if (traceErrors)
				trace('[WARN] Shader int[] property ${name} not found.');
			return null;
		}
		return prop.value;
	}

	/**
	 * Retrieve a boolean parameter of the shader.
	 * @param name The name of the parameter to retrieve.
	 * @return The value of the parameter.
	 */
	public function getBool(name:String):Null<Bool>
	{
		var prop:ShaderParameter<Bool> = Reflect.field(this.data, name);
		if (prop == null || prop.value.length == 0)
		{
			if (traceErrors)
				trace('[WARN] Shader bool property ${name} not found.');
			return null;
		}
		return prop.value[0];
	}

	/**
	 * Retrieve a boolean array parameter of the shader.
	 * @param name The name of the parameter to retrieve.
	 * @return The value of the parameter.
	 */
	public function getBoolArray(name:String):Null<Array<Bool>>
	{
		var prop:ShaderParameter<Bool> = Reflect.field(this.data, name);
		if (prop == null)
		{
			if (traceErrors)
				trace('[WARN] Shader bool[] property ${name} not found.');
			return null;
		}
		return prop.value;
	}

	/**
	 * Retrieve a bitmap data parameter of the shader.
	 * @param name The name of the parameter to retrieve.
	 * @return The value of the parameter.
	 */
	public function getBitmapData(name:String):Null<BitmapData>
	{
		var prop:ShaderInput<BitmapData> = Reflect.field(this.data, name);
		if (prop == null)
		{
			if (traceErrors)
				trace('[WARN] Shader sampler2D property ${name} not found.');
			return null;
		}
		return prop.input;
	}

	public inline function getSampler2D(name:String)
		return getBitmapData(name);
	public inline function setSampler2D(name:String, value:BitmapData)
		return setBitmapData(name, value);


	public function getBoolParameter(name:String):ShaderParameter<Bool>
	{
		return Reflect.field(this.data, name);
	}
	public function getIntParameter(name:String):ShaderParameter<Int>
	{
		return Reflect.field(this.data, name);
	}
	public function getFloatParameter(name:String):ShaderParameter<Float>
	{
		return Reflect.field(this.data, name);
	}
	public function getBitmapInput(name:String):ShaderInput<BitmapData>
	{
		return Reflect.field(this.data, name);
	}

	public function toString():String
	{
		return 'FlxRuntimeShader';
	}
}