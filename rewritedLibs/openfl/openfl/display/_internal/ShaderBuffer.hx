package openfl.display._internal;

#if !flash
import openfl.display3D._internal.GLBuffer;
import openfl.utils._internal.Float32Array;
import openfl.display3D.Context3DMipFilter;
import openfl.display3D.Context3DTextureFilter;
import openfl.display3D.Context3DWrapMode;
import openfl.display.BitmapData;
import openfl.display.GraphicsShader;
import openfl.display.ShaderInput;
import openfl.display.ShaderParameter;

#if !openfl_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
@:access(openfl.display.Shader)
@SuppressWarnings("checkstyle:FieldDocComment")
class ShaderBuffer
{
	public var inputCount:Int;
	public var inputRefs:Array<ShaderInput<BitmapData>>;
	public var inputFilter:Array<Context3DTextureFilter>;
	public var inputMipFilter:Array<Context3DMipFilter>;
	public var inputLodBias:Array<Float>;
	public var inputs:Array<BitmapData>;
	public var inputWrap:Array<Context3DWrapMode>;
	// public var overrideBoolCount:Int;
	// public var overrideBoolNames:Array<String>;
	// public var overrideBoolValues:Array<Array<Bool>>;
	public var overrideBoolValues:Map<String, Array<Bool>>;
	// public var overrideCount:Int;
	// public var overrideFloatCount:Int;
	// public var overrideFloatNames:Array<String>;
	// public var overrideFloatValues:Array<Array<Float>>;
	public var overrideFloatValues:Map<String, Array<Float>>;
	// public var overrideIntCount:Int;
	// public var overrideIntNames:Array<String>;
	// public var overrideIntValues:Array<Array<Dynamic>>;
	public var overrideIntValues:Map<String, Array<Dynamic>>;
	// public var overrideNames:Array<String>;
	// public var overrideValues:Array<Array<Dynamic>>;
	public var paramBoolCount:Int;
	public var paramCount:Int;
	public var paramData:Float32Array;
	public var paramDataBuffer:GLBuffer;
	public var paramDataLength:Int;
	public var paramFloatCount:Int;
	public var paramIntCount:Int;
	public var paramLengths:Array<Int>;
	public var paramPositions:Array<Int>;
	public var paramRefs_Bool:Array<ShaderParameter<Bool>>;
	public var paramRefs_Float:Array<ShaderParameter<Float>>;
	public var paramRefs_Int:Array<ShaderParameter<Int>>;
	public var paramTypes:Array<Int>;
	public var shader:GraphicsShader;

	public function new()
	{
		inputRefs = [];
		inputFilter = [];
		inputMipFilter = [];
		inputLodBias = [];
		inputs = [];
		inputWrap = [];
		// overrideValues = [];
		overrideIntValues = new Map();
		overrideFloatValues = new Map();
		overrideBoolValues = new Map();
		paramLengths = [];
		paramPositions = [];
		paramRefs_Bool = [];
		paramRefs_Float = [];
		paramRefs_Int = [];
		paramTypes = [];
	}

	public function addBoolOverride(name:String, values:Array<Bool>):Void
	{
		overrideBoolValues.set(name, values);
	}

	public function addFloatOverride(name:String, values:Array<Float>):Void
	{
		overrideFloatValues.set(name, values);
	}

	public function addIntOverride(name:String, values:Array<Int>):Void
	{
		overrideIntValues.set(name, values);
	}

	public function clearOverride():Void
	{
		// overrideCount = 0;
		overrideBoolValues.clear();
		overrideFloatValues.clear();
		overrideIntValues.clear();
	}

	public function update(shader:GraphicsShader):Void
	{
		#if lime
		inputCount = 0;
		// overrideCount = 0;
		clearOverride();
		paramBoolCount = 0;
		paramCount = 0;
		paramDataLength = 0;
		paramFloatCount = 0;
		paramIntCount = 0;
		this.shader = null;

		if (shader == null) return;

		shader.__init();

		inputCount = shader.__inputBitmapData.length;

		// inputs.resize(inputCount);
		// inputFilter.resize(inputCount);
		// inputMipFilter.resize(inputCount);
		// inputRefs.resize(inputCount);
		// inputWrap.resize(inputCount);

		var input:ShaderInput<BitmapData>;

		for (i in 0...inputCount)
		{
			input = shader.__inputBitmapData[i];
			inputs[i] = input.input;
			inputFilter[i] = input.filter;
			inputMipFilter[i] = input.mipFilter;
			inputLodBias[i] = input.lodBias;
			inputRefs[i] = input;
			inputWrap[i] = input.wrap;
		}

		var boolCount = shader.__paramBool.length;
		var floatCount = shader.__paramFloat.length;
		var intCount = shader.__paramInt.length;
		paramCount = boolCount + floatCount + intCount;
		paramBoolCount = boolCount;
		paramFloatCount = floatCount;
		paramIntCount = intCount;

		paramTypes.resize(paramCount);
		paramLengths.resize(paramCount);
		paramPositions.resize(paramCount);
		paramRefs_Bool.resize(boolCount);
		paramRefs_Float.resize(floatCount);
		paramRefs_Int.resize(intCount);

		var length, p = 0;
		var param:ShaderParameter<Bool>;

		for (i in 0...boolCount)
		{
			param = shader.__paramBool[i];

			paramPositions[p] = paramDataLength;
			length = (param.value != null ? param.value.length : 0);
			paramLengths[p] = length;
			paramDataLength += length;
			paramTypes[p] = 0;

			paramRefs_Bool[i] = param;
			p++;
		}

		var param:ShaderParameter<Float>;

		for (i in 0...floatCount)
		{
			param = shader.__paramFloat[i];

			paramPositions[p] = paramDataLength;
			length = (param.value != null ? param.value.length : 0);
			paramLengths[p] = length;
			paramDataLength += length;
			paramTypes[p] = 1;

			paramRefs_Float[i] = param;
			p++;
		}

		var param:ShaderParameter<Int>;

		for (i in 0...intCount)
		{
			param = shader.__paramInt[i];

			paramPositions[p] = paramDataLength;
			length = (param.value != null ? param.value.length : 0);
			paramLengths[p] = length;
			paramDataLength += length;
			paramTypes[p] = 2;

			paramRefs_Int[i] = param;
			p++;
		}

		if (paramDataLength > 0)
		{
			if (paramData == null)
			{
				paramData = new Float32Array(paramDataLength);
			}
			else if (paramDataLength > paramData.length)
			{
				var data = new Float32Array(paramDataLength);
				data.set(paramData);
				paramData = data;
			}
		}

		var boolIndex = 0;
		var floatIndex = 0;
		var intIndex = 0;

		var paramPosition:Int = 0;
		var boolParam, floatParam, intParam, length;

		for (i in 0...paramCount)
		{
			length = paramLengths[i];

			if (i < boolCount)
			{
				boolParam = paramRefs_Bool[boolIndex];
				boolIndex++;

				for (j in 0...length)
				{
					paramData[paramPosition] = boolParam.value[j] ? 1 : 0;
					paramPosition++;
				}
			}
			else if (i < boolCount + floatCount)
			{
				floatParam = paramRefs_Float[floatIndex];
				floatIndex++;

				for (j in 0...length)
				{
					paramData[paramPosition] = floatParam.value[j];
					paramPosition++;
				}
			}
			else
			{
				intParam = paramRefs_Int[intIndex];
				intIndex++;

				for (j in 0...length)
				{
					paramData[paramPosition] = intParam.value[j];
					paramPosition++;
				}
			}
		}

		this.shader = shader;
		#end
	}
}
#end
