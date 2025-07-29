package game.backend.system.scripts;

import flixel.system.FlxSound;
import flixel.tweens.FlxTween;
import flixel.util.FlxTimer;
import flixel.util.FlxSave;
import flixel.util.FlxDestroyUtil.IFlxDestroyable;
#if !flash
import flixel.addons.display.FlxRuntimeShader;
#end

class ScriptPackPlayState extends ScriptPack
{
	public static var instance(default, null):ScriptPackPlayState; // made for lua :P

	#if LUA_ALLOWED
	public var luaArray:Array<FunkinLua> = [];

	public function new(?isInstance:Bool = true)
	{
		if (isInstance)
			instance = this;
		FunkinLua.updateCurState();
		super();
	}

	public function getLuaObject(tag:String, text:Bool = true):FlxSprite
	{
		if (modchartSprites.exists(tag))
			return modchartSprites.get(tag);
		if (text && modchartTexts.exists(tag))
			return modchartTexts.get(tag);
		return null;
	}

	public function loadLuaScript(path:String)
	{
		final script = new FunkinLua(path).execute();
		luaArray.push(script);
		return script;
	}

	public override function call(funcToCall:String, ?args:Array<Dynamic>, ?ignoreStops:Bool, ?exclusions:Array<String>):Dynamic
	{
		var result:Dynamic = callOnLuas(funcToCall, args, ignoreStops, exclusions);
		if (result == null || result == ScriptUtil.Function_Continue)
			result = callOnHScript(funcToCall, args, ignoreStops, exclusions);
		return result;
	}
	#end

	public function callOnLuas(event:String, ?args:Array<Dynamic> , ?ignoreStops:Bool, ?exclusions:Array<String>):Dynamic
	{
		var returnVal:Dynamic = ScriptUtil.Function_Continue;
		#if LUA_ALLOWED
		args ??= [];
		// exclusions ??= [];

		var len:Int = luaArray.length;
		var i:Int = 0;
		while (i < len)
		{
			final script:FunkinLua = luaArray[i];
			if (script == null /*|| exclusions == null || exclusions.contains(script.scriptName)*/)
			{
				i++;
				continue;
			}
			final myValue:Dynamic = script.call(event, args);

			if (script.closed)
				len--;
			else
				i++;
			if (Function_Continue == myValue)
				continue;

			if (!ignoreStops && ScriptPack.resultIsStop(myValue))
			{
				returnVal = myValue;
				break;
			}
			else if (myValue != null)
				returnVal = myValue;
		}
		#end
		/*
				if (returnVal == null || ScriptUtil.Function_Continue == returnVal){
					var i:Int = 0;
					while(i < members.length){
						final myValue:Dynamic = members[i].callOnLuas(event, args, ignoreStops, exclusions);
						if((myValue == ScriptUtil.Function_StopLua || myValue == ScriptUtil.Function_StopAll)
							&& ScriptUtil.Function_Continue != myValue && !ignoreStops){
							returnVal = myValue;
							break;
						}

						if(myValue != null && ScriptUtil.Function_Continue != myValue)
							returnVal = myValue;

						i++;
					}
				}
		 */

		// trace(event, returnVal);
		return returnVal;
	}

	#if LUA_ALLOWED
	public var modchartTweens = new Map<String, FlxTween>();
	public var modchartSprites = new Map<String, FunkinLua.ModchartSprite>();
	public var modchartTexts = new Map<String, FunkinLua.ModchartText>();
	public var modchartTimers = new Map<String, FlxTimer>();
	public var modchartSounds = new Map<String, FlxSound>();
	public var modchartSaves = new Map<String, FlxSave>();

	public function setOnLuas(variable:String, arg:Dynamic)
	{
		var len = luaArray.length;
		while (len > 0)
		{
			luaArray[--len].set(variable, arg);
		}
		return arg;
	}
	#end

	public override function destroy()
	{
		// while(members.length > 0) members.shift().destroy();
		#if LUA_ALLOWED
		var len = luaArray.length;
		var lua:FunkinLua;
		while (len > 0)
		{
			len--;
			lua = luaArray.shift();
			if (lua == null)
				continue; // safety
			lua.call('onDestroy', []);
			lua.stop();
		}
		FunkinLua.customFunctions.clear();
		modchartTweens.clear();
		modchartTimers.clear();
		modchartSprites.clear();
		modchartTexts.clear();
		modchartSounds.clear();
		modchartSaves.clear();
		#end
		instance = null;
		super.destroy();
	}
}

class ScriptPack implements IFlxDestroyable
{
	public static var staticVariables:Map<String, Dynamic> = [];

	public var variables:Map<String, Dynamic> = new Map<String, Dynamic>();

	// public var members:Array<ScriptPack> = []; // nah
	public var hscriptGlobalVariables:Map<String, Dynamic> = new Map<String, Dynamic>();
	public var hscriptArray:Array<HScript> = [];

	public function new()
	{
	}

	public function getHScript(path:String, useContains:Bool = true):HScript
	{
		if (useContains)
		{
			for (i in hscriptArray)
				if (i.path.contains(path))
					return i;
		}
		else
		{
			if (!path.endsWith(".hx"))
				path += ".hx";
			if (!path.startsWith("assets/"))
				path = 'assets/$path';
			for (i in hscriptArray)
				if (i.path == path)
					return i;
		}
		return null;
	}

	public function loadHScript(path:String, ?classSwag:Dynamic, ?extraParams:Map<String, Dynamic>)
	{
		final script = HScript.loadStateModule(path, classSwag ?? FlxG.state, extraParams);
		hscriptArray.push(script);
		script.execute();
		return script;
	}

	public static inline function resultIsStop(result:FunctionReturn):Bool
		return Function_Stop == result
			|| Function_StopHScript == result
			|| Function_StopAll == result;

	public function call(funcToCall:String, ?args:Array<Dynamic>, ?ignoreStops:Bool, ?exclusions:Array<String>):Dynamic
		return callOnHScript(funcToCall, args, ignoreStops, exclusions);

	public function callOnHScript(funcToCall:String, ?args:Array<Dynamic>, ?ignoreStops:Bool, exclusions:Array<String>):Dynamic
	{
		var returnVal:Dynamic = Function_Continue;
		#if hscript
		if (hscriptArray.length == 0)
			return returnVal;

		var i = 0;
		var script:HScript;
		while (i < hscriptArray.length)
		{
			script = hscriptArray[i++];
			if (script == null /*|| exclusions == null || exclusions.contains(script.scriptName)*/)
				continue;

			final myValue:Dynamic = script.call(funcToCall, args);
			final stopScript = myValue == Function_Stop;
			final stopHscript = myValue == Function_StopHScript;
			final stopAll = myValue == Function_StopAll;
			if (ignoreStops == true && (stopScript || stopHscript || stopAll))
			{
				returnVal = myValue;
				break;
			}
			else if (myValue != null)
				returnVal = myValue;
		}
		#end
		/*
			if (returnVal == null || ScriptUtil.Function_Continue == returnVal){
				var i:Int = 0;
				while(i < members.length){
					final myValue:Dynamic = members[i].callOnHScript(funcToCall, args, ignoreStops, exclusions);
					if((myValue == ScriptUtil.Function_StopHScript || myValue == ScriptUtil.Function_StopAll)
						&& ScriptUtil.Function_Continue != myValue && !ignoreStops){
						returnVal = myValue;
						break;
					}

					if(myValue != null && ScriptUtil.Function_Continue != myValue)
						returnVal = myValue;

					i++;
				}
			}
		 */

		return returnVal;
	}

	public var runtimeShaders:Map<String, Array<String>> = new Map<String, Array<String>>();

	public function createRuntimeShader(name:String, ?glslVersion:Int = 110):FlxRuntimeShader
	{
		if (!ClientPrefs.shaders)
			return new FlxRuntimeShader();

		if (!runtimeShaders.exists(name) && !initLuaShader(name, glslVersion))
		{
			Log('Shader $name is missing!', RED);
			return new FlxRuntimeShader();
		}

		var arr:Array<String> = runtimeShaders.get(name);
		return new FlxRuntimeShader(arr[0], arr[1], Std.string(glslVersion));
	}

	public function initLuaShader(shaderFile:String, customName:String = '', ?glslVersion:Int = 110):Bool
	{
		final shaderName:String = (customName == '' ? shaderFile : customName);
		if (runtimeShaders.exists(shaderName))
			return true;
		if (ClientPrefs.shaders)
		{
			var frag:String = AssetsPaths.fragShader(shaderFile);
			var vert:String = AssetsPaths.vertShader(shaderFile);
			frag = Assets.exists(frag) ? Assets.getText(frag) : null;
			vert = Assets.exists(vert) ? Assets.getText(vert) : null;

			if (frag != null || vert != null)
			{
				runtimeShaders.set(shaderName, [frag, vert]);
				return true;
			}

			FlxG.log.warn('Missing shader $shaderFile .frag AND .vert files!');
			Log('Missing shader $shaderFile .frag AND .vert files!', RED);
		}
		return false;
	}

	public function destroy()
	{
		// while(members.length > 0) members.shift().destroy();
		var len = hscriptArray.length;
		var hx:HScript;
		while (len > 0)
		{
			len--;
			hx = hscriptArray.shift();
			if (hx == null)
				continue; // safety
			hx.call('onDestroy');
			hx.destroy();
		}
		// for (i in [variables #if hscript , hscriptGlobalVariables #end]){
		// 	for (obj in i)
		// 		if (Std.isOfType(obj, IFlxDestroyable)){
		// 			if (Std.isOfType(obj, FlxTween))
		// 				obj.active = false;
		// 			obj.destroy();
		// 		}
		// }
		for (i in [variables #if hscript, hscriptGlobalVariables #end])
		{
			i.clear();
		}
	}

	public function setOnHScript(variable:String, arg:Dynamic)
	{
		#if hscript
		var len = hscriptArray.length;
		while (len > 0)
		{
			hscriptArray[--len].variables.set(variable, arg);
		}
		#end
		return arg;
	}
}
