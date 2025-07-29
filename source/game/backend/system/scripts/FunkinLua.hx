package game.backend.system.scripts;

import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText; // import inside objects
import flixel.ui.FlxBar;
import flixel.util.FlxColor;
import game.backend.system.scripts.ScriptPack.ScriptPackPlayState;
import game.objects.improvedFlixel.FlxFixedText;
import game.states.playstate.PlayState;

#if LUA_ALLOWED
import game.backend.data.EngineData;
import game.backend.data.jsons.WeekData;
import game.backend.system.song.Conductor.mainInstance as Conductor;
import game.backend.system.song.Song;
import game.backend.system.states.MusicBeatState;
import game.backend.utils.Highscore;
import game.backend.utils.Terminal;
import game.objects.Alphabet;
import game.objects.game.Character;
import game.objects.game.DialogueBoxPsych;
import game.objects.game.notes.Note;
import game.objects.game.notes.StrumNote;
import game.states.FreeplayState;
import game.states.LoadingState;
// import game.states.StoryMenuState;
import game.states.editors.SongsState;
import game.states.substates.GameOverSubstate;
import game.states.substates.PauseSubState;

import llua.*;
import llua.Lua;
// import llua.LuaL;
// import llua.State;
// import llua.Convert;

import flixel.addons.display.FlxRuntimeShader;
import flixel.addons.transition.FlxTransitionableState;
import flixel.math.FlxMath;
import flixel.system.FlxSound;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxSave;
import flixel.util.FlxTimer;

import openfl.Vector as OpFlVector;
import openfl.display.BlendMode;
import openfl.utils.Assets;

#if sys
import sys.FileSystem;
import sys.io.File;
#end

#if hscript
import hscript.Parser;
import hscript.Interp;
#end

import Type.ValueType;
import haxe.Constraints;

using StringTools;

class CallbackHandler
{
	public static inline function call(l:State, fname:String):Int
	{
		try
		{
			//trace('calling $fname');
			var cbf:Dynamic = Lua_helper.callbacks.get(fname);

			//Local functions have the lowest priority
			//This is to prevent a "for" loop being called in every single operation,
			//so that it only loops on reserved/special functions
			if(cbf == null)
			{
				//trace('checking last script');
				var last:FunkinLua = FunkinLua.lastCalledScript;
				if(last == null || last.lua != l)
				{
					//trace('looping thru scripts');
					for (script in PlayState.instance.luaArray)
						if(script != FunkinLua.lastCalledScript && script != null && script.lua == l)
						{
							//trace('found script');
							cbf = script.callbacks.get(fname);
							break;
						}
				}
				else
				{
					cbf = last.callbacks.get(fname);
				}
			}

			if(cbf == null) return 0;

			var ret:Dynamic = Reflect.callMethod(null, cbf, [for (i in 0...Lua.gettop(l)) Convert.fromLua(l, i + 1)]);
			/* return the number of results */

			if(ret != null){
				Convert.toLua(l, ret);
				return 1;
			}
		}
		catch(e:Dynamic)
		{
			// if(Lua_helper.sendErrorsToLua) {LuaL.error(l, 'CALLBACK ERROR! ${if(e.message != null) e.message else e}');return 0;}
			trace(e);
			throw(e);
		}
		return 0;
	}
}

typedef LuaTweenOptions = {
	type:FlxTweenType,
	startDelay:Float,
	?onUpdate:String,
	?onStart:String,
	?onComplete:String,
	loopDelay:Float,
	ease:EaseFunction
}

class FunkinLua implements IScript
{
	public static final Function_Stop:FunctionReturn			= ScriptUtil.Function_Stop;
	public static final Function_Continue:FunctionReturn		= ScriptUtil.Function_Continue;
	public static final Function_StopLua:FunctionReturn			= ScriptUtil.Function_StopLua;
	public static final Function_StopHScript:FunctionReturn		= ScriptUtil.Function_StopHScript;
	public static final Function_StopAll:FunctionReturn			= ScriptUtil.Function_StopAll;

	public static var warningError:Bool = true;
	public static var closeOnError:Bool = true;

	public var errorHandler:String->Void;
	#if LUA_ALLOWED
	public var lua(default, null):State = null;
	#end
	public var scriptName:String = '';
	public var closed:Bool = false;
	public static var mainState(get, never):flixel.FlxState;
	public static dynamic function get_mainState():flixel.FlxState return PlayState.instance;

	#if hscript
	public var hscript:HScriptLua = null;
	public var callbacks:Map<String, Dynamic> = new Map<String, Dynamic>();
	public static var customFunctions:Map<String, Dynamic> = new Map<String, Dynamic>();
	#end

	final times = haxe.Timer.stamp() * 1000;

	static var game(get, never):PlayState;
	static function get_game():PlayState return PlayState.instance;

	public function new(script:String){
		#if LUA_ALLOWED
		lua = LuaL.newstate();
		LuaL.openlibs(lua);

		// trace('Lua version: ' + Lua.version());
		// trace("LuaJIT version: " + Lua.versionJIT());

		// LuaL.dostring(lua, CLENSE);

		scriptName = script;


		// Lua shit
		set('Function_StopLua', Function_StopLua);
		set('Function_Stop', Function_Stop);
		set('Function_Continue', Function_Continue);
		set('Function_StopHScript', Function_StopHScript);
		set('Function_StopAll', Function_StopAll);
		set('luaDebugMode', false);
		set('luaDeprecatedWarnings', true);
		set('inChartEditor', false);

		// Camera poo
		set('cameraX', 0);
		set('cameraY', 0);

		// Screen stuff
		set('screenWidth', FlxG.width);
		set('screenHeight', FlxG.height);

		// PlayState cringe ass nae nae bullcrap
		set('curBeat', 0);
		set('curStep', 0);
		set('curDecBeat', 0);
		set('curDecStep', 0);

		set('score', 0);
		set('misses', 0);
		set('hits', 0);

		set('rating', 0);
		set('ratingName', '');
		set('ratingFC', '');
		set('version', (EngineData.psychVersion : String));

		set('inGameOver', false);
		set('mustHitSection', false);
		set('altAnim', false);
		set('gfSection', false);

		for (i in 0...4){
			set('defaultPlayerStrumX' + i, 0);
			set('defaultPlayerStrumY' + i, 0);
			set('defaultOpponentStrumX' + i, 0);
			set('defaultOpponentStrumY' + i, 0);
		}

		// Some settings, no jokes
		set('downscroll',		ClientPrefs.downScroll);
		set('middlescroll',		ClientPrefs.middleScroll);
		set('framerate',		ClientPrefs.framerate);
		set('hideHud',			ClientPrefs.hideHud);
		set('timeBarType',		ClientPrefs.timeBarType);
		set('scoreZoom',		ClientPrefs.scoreZoom);
		set('cameraZoomOnBeat',	ClientPrefs.camZooms);
		set('flashingLights',	ClientPrefs.flashing);
		set('noteOffset',		ClientPrefs.noteOffset);
		set('healthBarAlpha',	1); // lol
		set('noResetButton',	ClientPrefs.noReset);
		set('lowQuality',		ClientPrefs.lowQuality);
		set('scriptName',		scriptName);
		set('shadersEnabled',	ClientPrefs.shaders);

		#if windows
		set('buildTarget', 'windows');
		#elseif linux
		set('buildTarget', 'linux');
		#elseif mac
		set('buildTarget', 'mac');
		#elseif html5
		set('buildTarget', 'browser');
		#elseif android
		set('buildTarget', 'android');
		#else
		set('buildTarget', 'unknown');
		#end

		for (name => func in customFunctions) if(func != null) addCallback(name, func);

		// shader shit
		addCallback("initLuaShader", function(name:String, glslVersion:Int = 120, customName:String = '') {
			if(!ClientPrefs.shaders) return false;

			#if (!flash && MODS_ALLOWED && sys)
			return initLuaShader(name, customName, glslVersion);
			#else
			if (ClientPrefs.displErrs)
				luaTrace("initLuaShader: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			#end
			return false;
		});

		addCallback("setSpriteShader", function(obj:String, shader:String) {
			if(!ClientPrefs.shaders) return false;

			if(!ScriptPackPlayState.instance.runtimeShaders.exists(shader) && !initLuaShader(shader))
			{
				if (ClientPrefs.displErrs)
					luaTrace('setSpriteShader: Shader $shader is missing!', false, false, FlxColor.RED);
				return false;
			}

			final killMe:Array<String> = obj.split('.');
			var leObj:FlxSprite = getObjectDirectly(killMe[0]);
			if(killMe.length > 1) {
				leObj = getVarInArray(getPropertyLoopThingWhatever(killMe), killMe[killMe.length-1]);
			}

			if(leObj != null) {
				var arr:Array<String> = ScriptPackPlayState.instance.runtimeShaders.get(shader);
				leObj.shader = new FlxRuntimeShader(arr[0], arr[1]);
				return true;
			}
			return false;
		});
		addCallback("removeSpriteShader", function(obj:String) {
			final killMe:Array<String> = obj.split('.');
			var leObj:FlxSprite = getObjectDirectly(killMe[0]);
			if(killMe.length > 1) {
				leObj = getVarInArray(getPropertyLoopThingWhatever(killMe), killMe[killMe.length - 1]);
			}

			if(leObj != null) {
				leObj.shader = null;
				return true;
			}
			return false;
		});

		addCallback("getShaderBool", function(obj:String, prop:String) {
			final shader:FlxRuntimeShader = getShader(obj);
			if (shader == null)
			{
				Lua.pushnil(lua);
				return null;
			}
			return shader.getBool(prop);
		});
		addCallback("getShaderBoolArray", function(obj:String, prop:String) {
			final shader:FlxRuntimeShader = getShader(obj);
			if (shader == null)
			{
				Lua.pushnil(lua);
				return null;
			}
			return shader.getBoolArray(prop);
		});
		addCallback("getShaderInt", function(obj:String, prop:String) {
			final shader:FlxRuntimeShader = getShader(obj);
			if (shader == null)
			{
				Lua.pushnil(lua);
				return null;
			}
			return shader.getInt(prop);
		});
		addCallback("getShaderIntArray", function(obj:String, prop:String) {
			final shader:FlxRuntimeShader = getShader(obj);
			if (shader == null)
			{
				Lua.pushnil(lua);
				return null;
			}
			return shader.getIntArray(prop);
		});
		addCallback("getShaderFloat", function(obj:String, prop:String) {
			final shader:FlxRuntimeShader = getShader(obj);
			if (shader == null)
			{
				Lua.pushnil(lua);
				return null;
			}
			return shader.getFloat(prop);
		});
		addCallback("getShaderFloatArray", function(obj:String, prop:String) {
			final shader:FlxRuntimeShader = getShader(obj);
			if (shader == null)
			{
				Lua.pushnil(lua);
				return null;
			}
			return shader.getFloatArray(prop);
		});


		addCallback("setShaderBool", function(obj:String, prop:String, value:Bool) {
			final shader:FlxRuntimeShader = getShader(obj);
			if(shader == null) return;

			shader.setBool(prop, value);
		});
		addCallback("setShaderBoolArray", function(obj:String, prop:String, values:Dynamic) {
			final shader:FlxRuntimeShader = getShader(obj);
			if(shader == null) return;

			shader.setBoolArray(prop, values);
		});
		addCallback("setShaderInt", function(obj:String, prop:String, value:Int) {
			final shader:FlxRuntimeShader = getShader(obj);
			if(shader == null) return;

			shader.setInt(prop, value);
		});
		addCallback("setShaderIntArray", function(obj:String, prop:String, values:Dynamic) {
			final shader:FlxRuntimeShader = getShader(obj);
			if(shader == null) return;

			shader.setIntArray(prop, values);
		});
		addCallback("setShaderFloat", function(obj:String, prop:String, value:Float) {
			final shader:FlxRuntimeShader = getShader(obj);
			if(shader == null) return;

			shader.setFloat(prop, value);
		});

		addCallback("preCashe", function(key:String, type:String) {
			switch(type){
				case 'image':	Paths.image(key);
				case 'sound':	Paths.sound(key);
				case 'music':	Paths.music(key);
			}
		});

		addCallback("setShaderFloatArray", function(obj:String, prop:String, values:Dynamic) {
			var shader:FlxRuntimeShader = getShader(obj);
			if(shader == null) return;

			shader.setFloatArray(prop, values);
		});

		addCallback("setShaderSampler2D", function(obj:String, prop:String, bitmapdataPath:String) {
			var shader:FlxRuntimeShader = getShader(obj);
			if(shader == null) return;

			// trace('bitmapdatapath: $bitmapdataPath');
			var value = Paths.image(bitmapdataPath);
			if(value != null && value.bitmap != null) {
				// trace('Found bitmapdata. Width: ${value.bitmap.width} Height: ${value.bitmap.height}');
				shader.setSampler2D(prop, value.bitmap);
			}
		});

		addCallback("getRunningScripts", function() return [for (idx in 0...game.luaArray.length) game.luaArray[idx].scriptName]);

		addCallback("callOnLuas",
			function(?funcName:String, ?args:Array<Dynamic>, ignoreStops = false, ignoreSelf = true, ?exclusions:Array<String>) {
				if (funcName == null) {
					#if (linc_luajit >= "0.0.6")
					LuaL.error(lua, "bad argument #1 to 'callOnLuas' (string expected, got nil)");
					#end
					return;
				}
				if (args == null) args = [];

				if (exclusions == null) exclusions = [];

				Lua.getglobal(lua, 'scriptName');
				var daScriptName = Lua.tostring(lua, -1);
				Lua.pop(lua, 1);
				if (ignoreSelf && !exclusions.contains(daScriptName))
					exclusions.push(daScriptName);
				ScriptPackPlayState.instance.callOnLuas(funcName, args, ignoreStops, exclusions);
			});

		addCallback("callScript", function(?luaFile:String, ?funcName:String, ?args:Array<Dynamic>)
		{
			if (luaFile == null)
			{
				#if (linc_luajit >= "0.0.6")
				LuaL.error(lua, "bad argument #1 to 'callScript' (string expected, got nil)");
				#end
				return;
			}
			if (funcName == null)
			{
				#if (linc_luajit >= "0.0.6")
				LuaL.error(lua, "bad argument #2 to 'callScript' (string expected, got nil)");
				#end
				return;
			}
			if (args == null)
			{
				args = [];
			}
			var cervix = !luaFile.endsWith(".lua") ? '$luaFile.lua' : luaFile;
			for (luaInstance in ScriptPackPlayState.instance.luaArray)
			{
				if (luaInstance.scriptName.indexOf(cervix) != -1)
				{
					luaInstance.call(funcName, args);

					return;
				}
			}
			Lua.pushnil(lua);
		});

		addCallback("getGlobalFromScript", function(?luaFile:String, ?global:String)
		{ // returns the global from a script
			if (luaFile == null)
			{
				#if (linc_luajit >= "0.0.6")
				LuaL.error(lua, "bad argument #1 to 'getGlobalFromScript' (string expected, got nil)");
				#end
				return;
			}
			if (global == null)
			{
				#if (linc_luajit >= "0.0.6")
				LuaL.error(lua, "bad argument #2 to 'getGlobalFromScript' (string expected, got nil)");
				#end
				return;
			}
			var cervix = !luaFile.endsWith(".lua") ? '$luaFile.lua' : luaFile;
			for (luaInstance in ScriptPackPlayState.instance.luaArray)
			{
				if (luaInstance.scriptName.indexOf(cervix) != -1)
				{
					Lua.getglobal(luaInstance.lua, global);
					if (Lua.isnumber(luaInstance.lua, -1))
					{
						Lua.pushnumber(lua, Lua.tonumber(luaInstance.lua, -1));
					}
					else if (Lua.isstring(luaInstance.lua, -1))
					{
						Lua.pushstring(lua, Lua.tostring(luaInstance.lua, -1));
					}
					else if (Lua.isboolean(luaInstance.lua, -1))
					{
						Lua.pushboolean(lua, Lua.toboolean(luaInstance.lua, -1));
					}
					else
					{
						Lua.pushnil(lua);
					}
					// TODO: table

					Lua.pop(luaInstance.lua, 1); // remove the global

					return;
				}
			}
			Lua.pushnil(lua);
		});
		addCallback("setGlobalFromScript", function(luaFile:String, global:String, val:Dynamic)
		{ // returns the global from a script
			var cervix = !luaFile.endsWith(".lua") ? '$luaFile.lua' : luaFile;
			for (luaInstance in ScriptPackPlayState.instance.luaArray)
			{
				if (luaInstance.scriptName.indexOf(cervix) != -1)
				{
					luaInstance.set(global, val);
				}
			}
			Lua.pushnil(lua);
		});
		/*addCallback("getGlobals", function(luaFile:String){ // returns a copy of the specified file's globals
			var cervix = luaFile + ".lua";
			if(luaFile.endsWith(".lua"))cervix=luaFile;
			var doPush = false;
			#if MODS_ALLOWED
			if(FileSystem.exists(Paths.modFolders(cervix)))
			{
				cervix = Paths.modFolders(cervix);
				doPush = true;
			}
			else if(FileSystem.exists(cervix))
			{
				doPush = true;
			}
			else {
				cervix = Paths.getSharedPath(cervix);
				if(FileSystem.exists(cervix)) {
					doPush = true;
				}
			}
			#else
			cervix = Paths.getSharedPath(cervix);
			if(Assets.exists(cervix)) {
				doPush = true;
			}
			#end
			if(doPush)
			{
				for (luaInstance in ScriptPackPlayState.instance.luaArray)
				{
					if(luaInstance.scriptName == cervix)
					{
						Lua.newtable(lua);
						var tableIdx = Lua.gettop(lua);

						Lua.pushvalue(luaInstance.lua, Lua.LUA_GLOBALSINDEX);
						Lua.pushnil(luaInstance.lua);
						while(Lua.next(luaInstance.lua, -2) != 0) {
							// key = -2
							// value = -1

							var pop:Int = 0;

							// Manual conversion
							// first we convert the key
							if(Lua.isnumber(luaInstance.lua,-2)){
								Lua.pushnumber(lua, Lua.tonumber(luaInstance.lua, -2));
								pop++;
							}else if(Lua.isstring(luaInstance.lua,-2)){
								Lua.pushstring(lua, Lua.tostring(luaInstance.lua, -2));
								pop++;
							}else if(Lua.isboolean(luaInstance.lua,-2)){
								Lua.pushboolean(lua, Lua.toboolean(luaInstance.lua, -2));
								pop++;
							}
							// TODO: table


							// then the value
							if(Lua.isnumber(luaInstance.lua,-1)){
								Lua.pushnumber(lua, Lua.tonumber(luaInstance.lua, -1));
								pop++;
							}else if(Lua.isstring(luaInstance.lua,-1)){
								Lua.pushstring(lua, Lua.tostring(luaInstance.lua, -1));
								pop++;
							}else if(Lua.isboolean(luaInstance.lua,-1)){
								Lua.pushboolean(lua, Lua.toboolean(luaInstance.lua, -1));
								pop++;
							}
							// TODO: table

							if(pop==2)Lua.rawset(lua, tableIdx); // then set it
							Lua.pop(luaInstance.lua, 1); // for the loop
						}
						Lua.pop(luaInstance.lua,1); // end the loop entirely
						Lua.pushvalue(lua, tableIdx); // push the table onto the stack so it gets returned

						return;
					}

				}
			}
			Lua.pushnil(lua);
		});*/

		addCallback("isRunning", function(luaFile:String)
		{
			var cervix = luaFile.endsWith(".lua") ? '$luaFile.lua' : luaFile;
			var doPush = false;
			#if MODS_ALLOWED
			if (FileSystem.exists(Paths.modFolders(cervix)))
			{
				cervix = Paths.modFolders(cervix);
				doPush = true;
			}
			else if (FileSystem.exists(cervix))
			{
				doPush = true;
			}
			else
			{
				cervix = Paths.getSharedPath(cervix);
				if (FileSystem.exists(cervix))
				{
					doPush = true;
				}
			}
			#else
			cervix = Paths.getSharedPath(cervix);
			if (Assets.exists(cervix))
			{
				doPush = true;
			}
			#end

			if (doPush)
			{
				for (luaInstance in ScriptPackPlayState.instance.luaArray)
				{
					if (luaInstance.scriptName == cervix)
						return true;
				}
			}
			return false;
		});

		addCallback("addLuaScript", function(luaFile:String, ?ignoreAlreadyRunning:Bool = false)
		{ // would be dope asf.
			var cervix = luaFile.endsWith(".lua") ? '$luaFile.lua' : luaFile;
			var doPush = false;
			#if MODS_ALLOWED
			if (FileSystem.exists(Paths.modFolders(cervix)))
			{
				cervix = Paths.modFolders(cervix);
				doPush = true;
			}
			else if (FileSystem.exists(cervix))
			{
				doPush = true;
			}
			else
			{
				cervix = Paths.getSharedPath(cervix);
				if (FileSystem.exists(cervix))
				{
					doPush = true;
				}
			}
			#else
			cervix = Paths.getSharedPath(cervix);
			if (Assets.exists(cervix))
			{
				doPush = true;
			}
			#end

			if (doPush)
			{
				if (!ignoreAlreadyRunning)
				{
					for (luaInstance in ScriptPackPlayState.instance.luaArray)
					{
						if (luaInstance.scriptName == cervix)
						{
							if (ClientPrefs.displErrs)
								luaTrace('The script "' + cervix + '" is already running!');
							return;
						}
					}
				}
				ScriptPackPlayState.instance.luaArray.push(new FunkinLua(cervix));
				return;
			}
			if (ClientPrefs.displErrs)
				luaTrace("Script doesn't exist!", false, false, FlxColor.RED);
		});
		addCallback("removeLuaScript", function(luaFile:String, ?ignoreAlreadyRunning:Bool = false)
		{ // would be dope asf.
			var cervix = luaFile.endsWith(".lua") ? '$luaFile.lua' : luaFile;
			var doPush = false;
			#if MODS_ALLOWED
			if (FileSystem.exists(Paths.modFolders(cervix)))
			{
				cervix = Paths.modFolders(cervix);
				doPush = true;
			}
			else if (FileSystem.exists(cervix))
			{
				doPush = true;
			}
			else
			{
				cervix = Paths.getSharedPath(cervix);
				if (FileSystem.exists(cervix))
				{
					doPush = true;
				}
			}
			#else
			cervix = Paths.getSharedPath(cervix);
			if (Assets.exists(cervix))
			{
				doPush = true;
			}
			#end

			if (doPush)
			{
				if (!ignoreAlreadyRunning)
				{
					for (luaInstance in ScriptPackPlayState.instance.luaArray)
					{
						if (luaInstance.scriptName == cervix)
						{
							// luaTrace('The script "' + cervix + '" is already running!');

							ScriptPackPlayState.instance.luaArray.remove(luaInstance);
							return;
						}
					}
				}
				return;
			}
			if (ClientPrefs.displErrs)
				luaTrace("Script doesn't exist!", false, false, FlxColor.RED);
		});

		addCallback("runHaxeCode", function(codeToRun:String)
		{
			var retVal:Dynamic = null;

			#if hscript
			initHaxeModule();
			try {
				retVal = hscript.execute(codeToRun);
			} catch (e:Dynamic) {
				if (ClientPrefs.displErrs)
					luaTrace(scriptName + ":" + lastCalledFunction + " - " + e, false, false, FlxColor.RED);
			}
			#else
			if (ClientPrefs.displErrs)
				luaTrace("runHaxeCode: HScriptLua isn't supported on this platform!", false, false, FlxColor.RED);
			#end

			if(retVal != null && !isOfTypes(retVal, [Bool, Int, Float, String, Array])) retVal = null;
			return retVal;
		});

		addCallback("addHaxeLibrary", function(libName:String, ?libPackage:String = '') {
			#if hscript
			initHaxeModule();
			try {
				var str:String = '';
				if(libPackage.length > 0)
					str = libPackage + '.';

				hscript.variables.set(libName, Type.resolveClass(str + libName));
			} catch (e:Dynamic) {
				if (ClientPrefs.displErrs)
					luaTrace(scriptName + ":" + lastCalledFunction + " - " + e, false, false, FlxColor.RED);
			}
			#end
		});

		addCallback("loadGraphic", function(variable:String, image:String, ?gridX:Int = 0, ?gridY:Int = 0) {
			final killMe:Array<String> = variable.split('.');
			var spr:FlxSprite = (killMe.length > 1) ? getVarInArray(getPropertyLoopThingWhatever(killMe), killMe[killMe.length - 1]) : getObjectDirectly(killMe[0]);

			if(spr != null && image != null && image.length > 0){
				final animated = gridX != 0 || gridY != 0;
				spr.loadGraphic(Paths.image(image), animated, gridX, gridY);
			}
		});

		addCallback("loadFrames", function(variable:String, image:String, spriteType:String = "sparrow") {
			final killMe:Array<String> = variable.split('.');
			var spr:FlxSprite = (killMe.length > 1) ? getVarInArray(getPropertyLoopThingWhatever(killMe), killMe[killMe.length - 1]) : getObjectDirectly(killMe[0]);

			if(spr != null && image != null && image.length > 0) loadFrames(spr, image, spriteType);
		});

		addCallback("getProperty", function(variable:String, ?allowMaps:Bool = false, ?bypassAccessor:Bool = false){
			final killMe:Array<String> = variable.split('.');
			if(killMe.length > 1)
				return getVarInArray(getPropertyLoopThingWhatever(killMe), killMe[killMe.length - 1], allowMaps, bypassAccessor);
			return getVarInArray(getInstance(), variable, allowMaps, bypassAccessor);
		});
		addCallback("setProperty", function(variable:String, value:Dynamic, allowMaps:Bool = false, ?bypassAccessor:Bool = false){
			final killMe:Array<String> = variable.split('.');
			if(killMe.length > 1)
				return setVarInArray(getPropertyLoopThingWhatever(killMe), killMe[killMe.length-1], value, allowMaps, bypassAccessor);
			return setVarInArray(getInstance(), variable, value, allowMaps, bypassAccessor);
		});
		addCallback("getPropertyFromGroup", function(obj:String, index:Int, variable:Dynamic, ?allowMaps:Bool = false, ?bypassAccessor:Bool = false){
			final split:Array<String> = obj.split('.');
			var realObject:Dynamic = null;
			if(split.length > 1)
				realObject = getPropertyLoop(split, true, false, allowMaps);
			else
				realObject = Reflect.getProperty(getInstance(), obj);

			if(Std.isOfType(realObject, FlxTypedGroup))
			{
				return getGroupStuff(realObject.members[index], variable, allowMaps, bypassAccessor);
			}

			var leArray:Dynamic = realObject[index];
			if(leArray != null) {
				var result:Dynamic = null;
				if(Type.typeof(variable) == ValueType.TInt)
					result = leArray[variable];
				else
					result = getGroupStuff(leArray, variable, allowMaps, bypassAccessor);
				return result;
			}
			if (ClientPrefs.displErrs)
				luaTrace("getPropertyFromGroup: Object #" + index + " from group: " + obj + " doesn't exist!", false, false, FlxColor.RED);
			return null;
		});

		addCallback("setPropertyFromGroup", function(obj:String, index:Int, variable:Dynamic, value:Dynamic, ?allowMaps:Bool = false, ?bypassAccessor:Bool = false){
			final split:Array<String> = obj.split('.');
			var realObject:Dynamic = null;
			if(split.length > 1)
				realObject = getPropertyLoop(split, true, false, allowMaps);
			else
				realObject = Reflect.getProperty(getInstance(), obj);

			if(Std.isOfType(realObject, FlxTypedGroup)) {
				setGroupStuff(realObject.members[index], variable, value, allowMaps, bypassAccessor);
				return value;
			}

			final leArray:Dynamic = realObject[index];
			if(leArray != null) {
				if(Type.typeof(variable) == ValueType.TInt) {
					leArray[variable] = value;
					return value;
				}
				setGroupStuff(leArray, variable, value, allowMaps, bypassAccessor);
			}
			return value;
		});
		addCallback("removeFromGroup", function(obj:String, index:Int, dontDestroy:Bool = false){
			final objGroup:Dynamic = Reflect.getProperty(getInstance(), obj);
			if (Std.isOfType(objGroup, FlxTypedGroup)){
				var sex = objGroup.members[index];
				if (!dontDestroy) sex.kill();
				objGroup.remove(sex, true);
				if (!dontDestroy) sex.destroy();
				return;
			}
			objGroup.remove(objGroup[index]);
		});

		addCallback("getPropertyFromClass", function(classVar:String, variable:String)@:privateAccess{
			final killMe:Array<String> = variable.split('.');
			final anyClass:Any = ScriptUtil.defineClasses.exists(classVar) ? ScriptUtil.defineClasses.get(classVar) : Type.resolveClass(classVar);
			if (killMe.length > 1) {
				var coverMeInPiss:Dynamic = getVarInArray(anyClass, killMe[0]);
				for (i in 1...killMe.length - 1) coverMeInPiss = getVarInArray(coverMeInPiss, killMe[i]);
				return getVarInArray(coverMeInPiss, killMe[killMe.length - 1]);
			}
			return getVarInArray(anyClass, variable);
		});
		addCallback("setPropertyFromClass", function(classVar:String, variable:String, value:Dynamic, allowMap:Bool = false)@:privateAccess{
			final killMe:Array<String> = variable.split('.');
			final anyClass:Any = ScriptUtil.defineClasses.exists(classVar) ? ScriptUtil.defineClasses.get(classVar) : Type.resolveClass(classVar);
			if (killMe.length > 1){
				var coverMeInPiss:Dynamic = getVarInArray(anyClass, killMe[0]);
				for (i in 1...killMe.length - 1) coverMeInPiss = getVarInArray(coverMeInPiss, killMe[i], allowMap);
				setVarInArray(coverMeInPiss, killMe[killMe.length - 1], value, allowMap);
				return true;
			}
			setVarInArray(anyClass, variable, value);
			return true;
		});

		addCallback("callMethod", function(funcToRun:String, ?args:Array<Dynamic> = null) {
			return callMethodFromObject(mainState, funcToRun, args);

		});
		addCallback("callMethodFromClass", function(className:String, funcToRun:String, ?args:Array<Dynamic> = null) {
			return callMethodFromObject(Type.resolveClass(className), funcToRun, args);
		});

		// shitass stuff for epic coders like me B)  *image of obama giving himself a medal*
		addCallback("getObjectOrder", function(obj:String){
			var killMe:Array<String> = obj.split('.');
			var leObj:FlxBasic = getObjectDirectly(killMe[0]);
			if (killMe.length > 1) leObj = getVarInArray(getPropertyLoopThingWhatever(killMe), killMe[killMe.length - 1]);

			if (leObj != null)
				return getInstance().members.indexOf(leObj);
			if (ClientPrefs.displErrs)
				luaTrace("Object " + obj + " doesn't exist!", false, false, FlxColor.RED);
			return -1;
		});
		addCallback("setObjectOrder", function(obj:String, position:Int)
		{
			var killMe:Array<String> = obj.split('.');
			var leObj:FlxBasic = getObjectDirectly(killMe[0]);
			if (killMe.length > 1)
				leObj = getVarInArray(getPropertyLoopThingWhatever(killMe), killMe[killMe.length - 1]);

			if (leObj != null){
				getInstance().remove(leObj, true);
				getInstance().insert(position, leObj);
				return;
			}
			if (ClientPrefs.displErrs)
				luaTrace("Object " + obj + " doesn't exist!", false, false, FlxColor.RED);
		});

		// gay ass tweens
		addCallback("startTween", function(tag:String, vars:String, values:Any = null, duration:Float, options:Any = null) {
			final penisExam:Dynamic = tweenPrepare(tag, vars);
			if(penisExam != null) {
				if(values != null) {
					final myOptions:LuaTweenOptions = getLuaTween(options);
					ScriptPackPlayState.instance.modchartTweens.set(tag, FlxTween.tween(penisExam, values, duration, {
						type: myOptions.type,
						ease: myOptions.ease,
						startDelay: myOptions.startDelay,
						loopDelay: myOptions.loopDelay,

						onUpdate: (myOptions.onUpdate != null ? function(twn:FlxTween) {
							ScriptPackPlayState.instance.callOnLuas(myOptions.onUpdate, [tag, vars]);
						} : null),
						onStart: (myOptions.onStart != null ? function(twn:FlxTween) {
							ScriptPackPlayState.instance.callOnLuas(myOptions.onStart, [tag, vars]);
						} : null),
						onComplete: (myOptions.onComplete != null || myOptions.type == FlxTweenType.ONESHOT || myOptions.type == FlxTweenType.BACKWARD ? function(twn:FlxTween) {
							if(myOptions.onComplete != null) ScriptPackPlayState.instance.callOnLuas(myOptions.onComplete, [tag, vars]);
							if(twn.type == FlxTweenType.ONESHOT || twn.type == FlxTweenType.BACKWARD) ScriptPackPlayState.instance.modchartTweens.remove(tag);
						} : null)
					}));
				} else {
					if (ClientPrefs.displErrs)
						luaTrace('startTween: No values on 2nd argument!', false, false, FlxColor.RED);
				}
			} else {
				if (ClientPrefs.displErrs)
					luaTrace('startTween: Couldnt find object: ' + vars, false, false, FlxColor.RED);
			}
		});
		addCallback("doTweenX", function(tag:String, vars:String, value:Dynamic, duration:Float, ease:String){
			oldTweenFunction(tag, vars, {x: value}, duration, ease, 'doTweenX');
		});
		addCallback("doTweenY", function(tag:String, vars:String, value:Dynamic, duration:Float, ease:String){
			oldTweenFunction(tag, vars, {y: value}, duration, ease, 'doTweenY');
		});
		addCallback("doTweenAngle", function(tag:String, vars:String, value:Dynamic, duration:Float, ease:String){
			oldTweenFunction(tag, vars, {angle: value}, duration, ease, 'doTweenAngle');
		});
		addCallback("doTweenScrollAngle", function(tag:String, vars:String, value:Dynamic, duration:Float, ease:String){
			oldTweenFunction(tag, vars, {scrollAngle: value}, duration, ease, 'doTweenScrollAngles');
		});
		addCallback("doTweenAlpha", function(tag:String, vars:String, value:Dynamic, duration:Float, ease:String){
			oldTweenFunction(tag, vars, {alpha: value}, duration, ease, 'doTweenAlpha');
		});
		addCallback("doTweenZoom", function(tag:String, vars:String, value:Dynamic, duration:Float, ease:String){
			oldTweenFunction(tag, vars, {zoom: value}, duration, ease, 'doTweenZoom');
		});
		addCallback("doTweenColor", function(tag:String, vars:String, targetColor:String, duration:Float, ease:String){
			final penisExam:Dynamic = tweenPrepare(tag, vars);
			if(penisExam != null) {
				var curColor:FlxColor = penisExam.color;
				curColor.alphaFloat = penisExam.alpha;
				ScriptPackPlayState.instance.modchartTweens.set(tag, FlxTween.color(penisExam, duration, curColor, CoolUtil.colorFromString(targetColor), {ease: CoolUtil.getFlxEaseByString(ease),
					onComplete: function(twn:FlxTween) {
						ScriptPackPlayState.instance.modchartTweens.remove(tag);
						ScriptPackPlayState.instance.callOnLuas('onTweenCompleted', [tag, vars]);
					}
				}));
			} else {
				if (ClientPrefs.displErrs)
					luaTrace('doTweenColor: Couldnt find object: ' + vars, false, false, FlxColor.RED);
			}
		});

		addCallback("cancelTween", function(tag:String){
			cancelTween(tag);
		});

		addCallback("mouseClicked", function(button:String){
			switch (button){
				case 'middle':	return FlxG.mouse.justPressedMiddle;
				case 'right':	return FlxG.mouse.justPressedRight;
				default:		return FlxG.mouse.justPressed;
			}


		});
		addCallback("mousePressed", function(button:String){
			switch (button){
				case 'middle':	return FlxG.mouse.pressedMiddle;
				case 'right':	return FlxG.mouse.pressedRight;
				default:		return FlxG.mouse.pressed;
			}
		});
		addCallback("mouseReleased", function(button:String){
			switch (button){
				case 'middle':	return FlxG.mouse.justReleasedMiddle;
				case 'right':	return FlxG.mouse.justReleasedRight;
				default:		return FlxG.mouse.justReleased;
			}
		});

		addCallback("changePresence", function(details:String, state:Null<String>, ?smallImageKey:String, ?hasStartTimestamp:Bool, ?endTimestamp:Float, ?image:String){
			#if DISCORD_RPC
			DiscordClient.changePresence(details, state, hasStartTimestamp && endTimestamp > 0 ? endTimestamp : null, {smallImage: smallImageKey, largeImage: image});
			#end
		});
		addCallback("changeDiscordPresence", function(details:String, state:Null<String>, ?smallImageKey:String, ?hasStartTimestamp:Bool, ?endTimestamp:Float, ?image:String){
			#if DISCORD_RPC
			DiscordClient.changePresence(details, state, hasStartTimestamp && endTimestamp > 0 ? endTimestamp : null, {smallImage: smallImageKey, largeImage: image});
			#end
		});
		addCallback("changeDiscordClientID", function(?newID:String = null) {
			#if DISCORD_RPC
			// if(newID == null) newID = DiscordClient.defaultID;
			// DiscordClient.clientID = newID;
			#end
		});

		addCallback("runTimer", function(tag:String, time:Float = 1, loops:Int = 1){
			cancelTimer(tag);
			ScriptPackPlayState.instance.modchartTimers.set(tag, new FlxTimer().start(time, function(tmr:FlxTimer){
				if (tmr.finished)
					ScriptPackPlayState.instance.modchartTimers.remove(tag);
				ScriptPackPlayState.instance.callOnLuas('onTimerCompleted', [tag, tmr.loops, tmr.loopsLeft]);
				// trace('Timer Completed: ' + tag);
			}, loops));
		});
		addCallback("cancelTimer", function(tag:String){
			cancelTimer(tag);
		});

		/*addCallback("getPropertyAdvanced", function(varsStr:String) {
				var variables:Array<String> = varsStr.replace(' ', '').split(',');
				var leClass:Class<Dynamic> = Type.resolveClass(variables[0]);
				if(variables.length > 2) {
					var curProp:Dynamic = Reflect.getProperty(leClass, variables[1]);
					if(variables.length > 3) {
						for (i in 2...variables.length-1) {
							curProp = Reflect.getProperty(curProp, variables[i]);
						}
					}
					return Reflect.getProperty(curProp, variables[variables.length-1]);
				} else if(variables.length == 2) {
					return Reflect.getProperty(leClass, variables[variables.length-1]);
				}
				return null;
			});
			addCallback("setPropertyAdvanced", function(varsStr:String, value:Dynamic) {
				var variables:Array<String> = varsStr.replace(' ', '').split(',');
				var leClass:Class<Dynamic> = Type.resolveClass(variables[0]);
				if(variables.length > 2) {
					var curProp:Dynamic = Reflect.getProperty(leClass, variables[1]);
					if(variables.length > 3) {
						for (i in 2...variables.length-1) {
							curProp = Reflect.getProperty(curProp, variables[i]);
						}
					}
					return Reflect.setProperty(curProp, variables[variables.length-1], value);
				} else if(variables.length == 2) {
					return Reflect.setProperty(leClass, variables[variables.length-1], value);
				}
		});*/


		addCallback("getColorFromHex", function(color:String){
			return CoolUtil.colorFromString(color);
		});

		addCallback("keyboardJustPressed", function(name:String)	return Reflect.getProperty(FlxG.keys.justPressed, name));
		addCallback("keyboardPressed", function(name:String)		return Reflect.getProperty(FlxG.keys.pressed, name));
		addCallback("keyboardReleased", function(name:String)		return Reflect.getProperty(FlxG.keys.justReleased, name));

		addCallback("anyGamepadJustPressed", function(name:String)	return FlxG.gamepads.anyJustPressed(name));
		addCallback("anyGamepadPressed", function(name:String)		return FlxG.gamepads.anyPressed(name));
		addCallback("anyGamepadReleased", function(name:String)		return FlxG.gamepads.anyJustReleased(name));

		addCallback("gamepadAnalogX", function(id:Int, ?leftStick:Bool = true)	return FlxG.gamepads.getByID(id).getXAxis(leftStick ? LEFT_ANALOG_STICK : RIGHT_ANALOG_STICK));
		addCallback("gamepadAnalogY", function(id:Int, ?leftStick:Bool = true)	return FlxG.gamepads.getByID(id).getYAxis(leftStick ? LEFT_ANALOG_STICK : RIGHT_ANALOG_STICK));
		addCallback("gamepadJustPressed", function(id:Int, name:String)			return Reflect.getProperty(FlxG.gamepads.getByID(id).justPressed, name));
		addCallback("gamepadPressed", function(id:Int, name:String)				return Reflect.getProperty(FlxG.gamepads.getByID(id).pressed, name));
		addCallback("gamepadJustReleased", function(id:Int, name:String)		return Reflect.getProperty(FlxG.gamepads.getByID(id).justReleased, name));

		addCallback("keyJustPressed", function(name:String){
			var key:Bool = false;
			switch (name){
				case 'left':	key = game.getControl('NOTE_LEFT_P');
				case 'down':	key = game.getControl('NOTE_DOWN_P');
				case 'up':		key = game.getControl('NOTE_UP_P');
				case 'right':	key = game.getControl('NOTE_RIGHT_P');
				case 'accept':	key = game.getControl('ACCEPT');
				case 'back':	key = game.getControl('BACK');
				case 'pause':	key = game.getControl('PAUSE');
				case 'reset':	key = game.getControl('RESET');
				case 'space':	key = FlxG.keys.justPressed.SPACE; // an extra key for convinience
			}
			return key;
		});
		addCallback("keyPressed", function(name:String){
			var key:Bool = false;
			switch (name){
				case 'left':	key = game.getControl('NOTE_LEFT');
				case 'down':	key = game.getControl('NOTE_DOWN');
				case 'up':		key = game.getControl('NOTE_UP');
				case 'right':	key = game.getControl('NOTE_RIGHT');
				case 'space':	key = FlxG.keys.pressed.SPACE; // an extra key for convinience
			}
			return key;
		});
		addCallback("keyReleased", function(name:String){
			var key:Bool = false;
			switch (name){
				case 'left':	key = game.getControl('NOTE_LEFT_R');
				case 'down':	key = game.getControl('NOTE_DOWN_R');
				case 'up':		key = game.getControl('NOTE_UP_R');
				case 'right':	key = game.getControl('NOTE_RIGHT_R');
				case 'space':	key = FlxG.keys.justReleased.SPACE; // an extra key for convinience
			}
			return key;
		});
		addCallback("precacheImage", function(name:String)	Paths.image(name)			);
		addCallback("precacheSound", function(name:String)	CoolUtil.precacheSound(name));
		addCallback("precacheMusic", function(name:String)	CoolUtil.precacheMusic(name));
		addCallback("getSongPosition", function()			return 0);

		addCallback("cameraShake", function(camera:String, intensity:Float, duration:Float){
			cameraFromString(camera).shake(intensity, duration);
		});

		addCallback("cameraFlash", function(camera:String, color:String, duration:Float, forced:Bool){
			final colorNum:Int = CoolUtil.colorFromString(color);
			cameraFromString(camera).flash(colorNum, duration, null, forced);
		});
		addCallback("cameraFade", function(camera:String, color:String, duration:Float, forced:Bool){
			final colorNum:Int = CoolUtil.colorFromString(color);
			cameraFromString(camera).fade(colorNum, duration, false, null, forced);
		});
		addCallback("getMouseX", function(camera:String){
			final point = FlxG.mouse.getScreenPosition(cameraFromString(camera));
			final floatPos = point.x;
			point.put();
			return floatPos;
		});
		addCallback("getMouseY", function(camera:String){
			final point = FlxG.mouse.getScreenPosition(cameraFromString(camera));
			final floatPos = point.y;
			point.put();
			return floatPos;
		});

		addCallback("getMidpointX", function(variable:String){
			final killMe:Array<String> = variable.split('.');
			final obj:FlxSprite = killMe.length > 1 ? getVarInArray(getPropertyLoopThingWhatever(killMe), killMe[killMe.length - 1]) : getObjectDirectly(killMe[0]);

			if (obj != null){
				final point = obj.getMidpoint();
				final floatPos = point.x;
				point.put();
				return floatPos;
			}

			return 0;
		});
		addCallback("getMidpointY", function(variable:String){
			final killMe:Array<String> = variable.split('.');
			final obj:FlxSprite = killMe.length > 1 ? getVarInArray(getPropertyLoopThingWhatever(killMe), killMe[killMe.length - 1]) : getObjectDirectly(killMe[0]);

			if (obj != null){
				final point = obj.getMidpoint();
				final floatPos = point.y;
				point.put();
				return floatPos;
			}
			return 0;
		});
		addCallback("getGraphicMidpointX", function(variable:String){
			final killMe:Array<String> = variable.split('.');
			final obj:FlxSprite = killMe.length > 1 ? getVarInArray(getPropertyLoopThingWhatever(killMe), killMe[killMe.length - 1]) : getObjectDirectly(killMe[0]);

			if (obj != null){
				final point = obj.getGraphicMidpoint();
				final floatPos = point.x;
				point.put();
				return floatPos;
			}

			return 0;
		});
		addCallback("getGraphicMidpointY", function(variable:String){
			var killMe:Array<String> = variable.split('.');
			final obj:FlxSprite = killMe.length > 1 ? getVarInArray(getPropertyLoopThingWhatever(killMe), killMe[killMe.length - 1]) : getObjectDirectly(killMe[0]);

			if (obj != null){
				final point = obj.getGraphicMidpoint();
				final floatPos = point.y;
				point.put();
				return floatPos;
			}

			return 0;
		});
		addCallback("getScreenPositionX", function(variable:String){
			final killMe:Array<String> = variable.split('.');
			final obj:FlxObject = killMe.length > 1 ? getVarInArray(getPropertyLoopThingWhatever(killMe), killMe[killMe.length - 1]) : getObjectDirectly(killMe[0]);

			if (obj != null){
				final point = obj.getScreenPosition();
				final floatPos = point.x;
				point.put();
				return floatPos;
			}

			return 0;
		});
		addCallback("getScreenPositionY", function(variable:String){
			final killMe:Array<String> = variable.split('.');
			final obj:FlxObject = killMe.length > 1 ? getVarInArray(getPropertyLoopThingWhatever(killMe), killMe[killMe.length - 1]) : getObjectDirectly(killMe[0]);

			if (obj != null){
				final point = obj.getScreenPosition();
				final floatPos = point.y;
				point.put();
				return floatPos;
			}

			return 0;
		});

		addCallback("makeLuaSprite", function(tag:String, image:String, x:Float, y:Float){
			tag = tag.replace('.', '');
			resetSpriteTag(tag);
			final leSprite:ModchartSprite = new ModchartSprite(x, y);
			if (image != null && image.length > 0) leSprite.loadGraphic(Paths.image(image));

			ScriptPackPlayState.instance.modchartSprites.set(tag, leSprite);
			leSprite.active = true;
		});
		addCallback("makeAnimatedLuaSprite", function(tag:String, image:String, x:Float, y:Float, ?spriteType:String = "sparrow"){
			tag = tag.replace('.', '');
			resetSpriteTag(tag);
			var leSprite:ModchartSprite = new ModchartSprite(x, y);

			if(image != null && image.length > 0) loadFrames(leSprite, image, spriteType);
			ScriptPackPlayState.instance.modchartSprites.set(tag, leSprite);
		});

		addCallback("makeGraphic", function(obj:String, width:Int, height:Int, color:String){
			final colorNum:Int = CoolUtil.colorFromString(color);

			final spr:FlxSprite = ScriptPackPlayState.instance.getLuaObject(obj, false);
			if (spr != null){
				spr.makeGraphic(width, height, colorNum);
				return;
			}

			final object:FlxSprite = Reflect.getProperty(getInstance(), obj);
			if (object != null)	object.makeGraphic(width, height, colorNum);
		});
		addCallback("addAnimationByPrefix", function(obj:String, name:String, prefix:String, framerate:Int = 24, loop:Bool = true){
			var cock:FlxSprite = ScriptPackPlayState.instance.getLuaObject(obj, false);
			if (cock != null){
				cock.animation.addByPrefix(name, prefix, framerate, loop);
				if (cock.animation.curAnim == null)	cock.animation.play(name, true);
				return;
			}

			cock = Reflect.getProperty(getInstance(), obj);
			if (cock != null){
				cock.animation.addByPrefix(name, prefix, framerate, loop);
				if (cock.animation.curAnim == null)	cock.animation.play(name, true);
			}
		});

		addCallback("addAnimation", function(obj:String, name:String, frames:Array<Int>, framerate:Int = 24, loop:Bool = true){
			final cock:FlxSprite = ScriptPackPlayState.instance.getLuaObject(obj, false);
			if (cock != null){
				cock.animation.add(name, frames, framerate, loop);
				if (cock.animation.curAnim == null)	cock.animation.play(name, true);
				return;
			}

			final cock:FlxSprite = Reflect.getProperty(getInstance(), obj);
			if (cock != null){
				cock.animation.add(name, frames, framerate, loop);
				if (cock.animation.curAnim == null)	cock.animation.play(name, true);
			}
		});

		addCallback("addAnimationByIndices", function(obj:String, name:String, prefix:String, indices:String, framerate:Int = 24, loop:Bool = false){
			final strIndices:Array<String> = indices.split(',');
			final die:Array<Int> = [for (i in 0...strIndices.length) Std.parseInt(strIndices[i].trim())];

			final pussy:FlxSprite = ScriptPackPlayState.instance.getLuaObject(obj, false);
			if (pussy != null){
				pussy.animation.addByIndices(name, prefix, die, '', framerate, loop);
				if (pussy.animation.curAnim == null)
					pussy.animation.play(name, true);

				return true;
			}

			final pussy:FlxSprite = Reflect.getProperty(getInstance(), obj);
			if (pussy != null){
				pussy.animation.addByIndices(name, prefix, die, '', framerate, false);
				if (pussy.animation.curAnim == null) pussy.animation.play(name, true);
				return true;
			}
			return false;
		});
		addCallback("playAnim", function(obj:String, name:String, forced:Bool = false, ?reverse:Bool = false, ?startFrame:Int = 0){
			final luaObj:FlxSprite = ScriptPackPlayState.instance.getLuaObject(obj, false);
			if (luaObj != null){
				if (luaObj.animation.getByName(name) != null){
					if (Std.isOfType(luaObj, ModchartSprite)){
						cast(luaObj, ModchartSprite).playAnim(name, forced, reverse, startFrame);
					}else luaObj.animation.play(name, forced, reverse, startFrame);
				}
				return true;
			}

			final spr:FlxSprite = Reflect.getProperty(getInstance(), obj);
			if (spr != null){
				if (Std.isOfType(spr, Character)){
					return cast(spr, Character).playAnim(name, forced, reverse, startFrame);
				}else if (spr.animation.getByName(name) != null){
					spr.animation.play(name, forced, reverse, startFrame);
					return true;
				}
			}
			return false;
		});
		addCallback("addOffset", function(obj:String, anim:String, x:Float, y:Float){
			if (ScriptPackPlayState.instance.modchartSprites.exists(obj)){
				ScriptPackPlayState.instance.modchartSprites.get(obj).addOffset(anim, x, y);
				return true;
			}

			final char:Character = Reflect.getProperty(getInstance(), obj);
			if (char != null){
				char.addOffset(anim, x, y);
				return true;
			}
			return false;
		});

		addCallback("setScrollFactor", function(obj:String, scrollX:Float, scrollY:Float){
			final ass = ScriptPackPlayState.instance.getLuaObject(obj, false);
			if (ass != null){
				ass.scrollFactor.set(scrollX, scrollY);
				return;
			}

			final object:FlxObject = Reflect.getProperty(getInstance(), obj);
			if (object != null) object.scrollFactor.set(scrollX, scrollY);
		});
		addCallback("addLuaSprite", function(tag:String, front:Bool = false){
			final shit:ModchartSprite = ScriptPackPlayState.instance.modchartSprites.get(tag);
			if (shit != null && !shit.wasAdded){
				getInstance().add(shit);
				/*
				if (front)
					getInstance().add(shit);
				else{
					if (PlayState.instance.isDead)
						GameOverSubstate.instance.insert(GameOverSubstate.instance.members.indexOf(GameOverSubstate.instance.boyfriend), shit);
					else{
						var position:Int = PlayState.instance.members.indexOf(PlayState.instance.gfGroup);
						if (PlayState.instance.members.indexOf(PlayState.instance.boyfriendGroup) < position)
							position = PlayState.instance.members.indexOf(PlayState.instance.boyfriendGroup);
						else if (PlayState.instance.members.indexOf(PlayState.instance.dadGroup) < position)
							position = PlayState.instance.members.indexOf(PlayState.instance.dadGroup);

						PlayState.instance.insert(position, shit);
					}
				}
				*/
				shit.wasAdded = true;
				// trace('added a thing: ' + tag);
			}
		});
		addCallback("setGraphicSize", function(obj:String, x:Int, y:Int = 0, updateHitbox:Bool = true){
			final shit:FlxSprite = ScriptPackPlayState.instance.getLuaObject(obj);
			if (shit != null) {
				shit.setGraphicSize(x, y);
				if (updateHitbox) shit.updateHitbox();
				return;
			}

			var killMe:Array<String> = obj.split('.');
			var poop:FlxSprite = getObjectDirectly(killMe[0]);
			if (killMe.length > 1)
				poop = getVarInArray(getPropertyLoopThingWhatever(killMe), killMe[killMe.length - 1]);

			if (poop != null){
				poop.setGraphicSize(x, y);
				if (updateHitbox) poop.updateHitbox();
				return;
			}
			if (ClientPrefs.displErrs)
				luaTrace('Couldnt find object: ' + obj, false, false, FlxColor.RED);
		});
		addCallback("scaleObject", function(obj:String, x:Float, y:Float, updateHitbox:Bool = true){
			final shit:FlxSprite = ScriptPackPlayState.instance.getLuaObject(obj);
			if (shit != null){
				shit.scale.set(x, y);
				if (updateHitbox) shit.updateHitbox();
				return;
			}

			final killMe:Array<String> = obj.split('.');
			final poop:FlxSprite = killMe.length > 1 ? getVarInArray(getPropertyLoopThingWhatever(killMe), killMe[killMe.length - 1]) : getObjectDirectly(killMe[0]);

			if (poop != null){
				poop.scale.set(x, y);
				if (updateHitbox) poop.updateHitbox();
				return;
			}
			if (ClientPrefs.displErrs)
				luaTrace('Couldnt find object: ' + obj, false, false, FlxColor.RED);
		});
		addCallback("updateHitbox", function(obj:String){
			final shit:FlxSprite = ScriptPackPlayState.instance.getLuaObject(obj);
			if (shit != null){
				shit.updateHitbox();
				return;
			}

			final poop:FlxSprite = Reflect.getProperty(getInstance(), obj);
			if (poop != null){
				poop.updateHitbox();
				return;
			}
			if (ClientPrefs.displErrs)
				luaTrace('Couldnt find object: ' + obj, false, false, FlxColor.RED);
		});
		addCallback("updateHitboxFromGroup", function(group:String, index:Int){
			final bullshit = Reflect.getProperty(getInstance(), group);
			if (Std.isOfType(bullshit, FlxTypedGroup))	{
				bullshit.members[index].updateHitbox();
				return;
			}
			Reflect.getProperty(getInstance(), group)[index].updateHitbox();
		});


		addCallback("removeLuaSprite", function(tag:String, destroy:Bool = true){
			if (!ScriptPackPlayState.instance.modchartSprites.exists(tag))
				return;

			var pee:ModchartSprite = ScriptPackPlayState.instance.modchartSprites.get(tag);
			if (destroy) pee.kill();

			if (pee.wasAdded){
				getInstance().remove(pee, true);
				pee.wasAdded = false;
			}

			if (destroy){
				pee.destroy();
				ScriptPackPlayState.instance.modchartSprites.remove(tag);
			}
		});

		addCallback("luaSpriteExists", function(tag:String) return ScriptPackPlayState.instance.modchartSprites.exists(tag));
		addCallback("luaTextExists", function(tag:String)	return ScriptPackPlayState.instance.modchartTexts.exists(tag));
		addCallback("luaSoundExists", function(tag:String)	return ScriptPackPlayState.instance.modchartSounds.exists(tag));


		addCallback("setObjectCamera", function(obj:String, camera:String = ''){
			/*if(ScriptPackPlayState.instance.modchartSprites.exists(obj)) {
					ScriptPackPlayState.instance.modchartSprites.get(obj).cameras = [cameraFromString(camera)];
					return true;
				}
				else if(ScriptPackPlayState.instance.modchartTexts.exists(obj)) {
					ScriptPackPlayState.instance.modchartTexts.get(obj).cameras = [cameraFromString(camera)];
					return true;
			}*/
			var real = ScriptPackPlayState.instance.getLuaObject(obj);
			if (real != null){
				real.cameras = [cameraFromString(camera)];
				return true;
			}

			var killMe:Array<String> = obj.split('.');
			var object:FlxBasic = getObjectDirectly(killMe[0]);
			if (killMe.length > 1) object = getVarInArray(getPropertyLoopThingWhatever(killMe), killMe[killMe.length - 1]);

			if (object != null){
				object.cameras = [cameraFromString(camera)];
				return true;
			}
			if (ClientPrefs.displErrs)
				luaTrace("Object " + obj + " doesn't exist!", false, false, FlxColor.RED);
			return false;
		});
		addCallback("setBlendMode", function(obj:String, blend:String = ''){
			final real = ScriptPackPlayState.instance.getLuaObject(obj);
			if (real != null){
				real.blend = blendModeFromString(blend);
				return true;
			}

			final killMe:Array<String> = obj.split('.');
			var spr:FlxSprite = getObjectDirectly(killMe[0]);
			if (killMe.length > 1)
				spr = getVarInArray(getPropertyLoopThingWhatever(killMe), killMe[killMe.length - 1]);

			if (spr != null){
				spr.blend = blendModeFromString(blend);
				return true;
			}
			if (ClientPrefs.displErrs)
				luaTrace("Object " + obj + " doesn't exist!", false, false, FlxColor.RED);
			return false;
		});
		addCallback("screenCenter", function(obj:String, pos:String = 'xy'){
			var spr:FlxObject = ScriptPackPlayState.instance.getLuaObject(obj);

			if (spr == null){
				var killMe:Array<String> = obj.split('.');
				spr = getObjectDirectly(killMe[0]);
				if (killMe.length > 1)
					spr = getVarInArray(getPropertyLoopThingWhatever(killMe), killMe[killMe.length - 1]);
			}

			if (spr != null){
				switch (pos.trim().toLowerCase()){
					case 'x':	spr.screenCenter(X);
					case 'y':	spr.screenCenter(Y);
					default:	spr.screenCenter(XY);
				}
				return;
			}
			if (ClientPrefs.displErrs)
				luaTrace("Object " + obj + " doesn't exist!", false, false, FlxColor.RED);
		});
		addCallback("objectsOverlap", function(obj1:String, obj2:String){
			var namesArray:Array<String> = [obj1, obj2];
			var objectsArray:Array<FlxObject> = [];
			for (i in 0...namesArray.length){
				final real:FlxObject = ScriptPackPlayState.instance.getLuaObject(namesArray[i]);
				if (real != null)
					objectsArray.push(real);
				else
					objectsArray.push(Reflect.getProperty(getInstance(), namesArray[i]));
			}

			if (!objectsArray.contains(null) && FlxG.overlap(objectsArray[0], objectsArray[1]))
				return true;
			return false;
		});
		addCallback("getPixelColor", function(obj:String, x:Int, y:Int){
			var killMe:Array<String> = obj.split('.');
			var spr:FlxSprite = getObjectDirectly(killMe[0]);
			if (killMe.length > 1)
				spr = getVarInArray(getPropertyLoopThingWhatever(killMe), killMe[killMe.length - 1]);

			if(spr != null) return spr.pixels.getPixel32(x, y);
			return 0;
		});
		addCallback("getRandomInt", function(min:Int, max:Int = FlxMath.MAX_VALUE_INT, exclude:String = ''){
			return FlxG.random.int(min, max, [for (i in exclude.split(',')) Std.parseInt(i.trim())]);
		});
		addCallback("getRandomFloat", function(min:Float, max:Float = 1, exclude:String = ''){
			return FlxG.random.float(min, max, [for (i in exclude.split(',')) Std.parseFloat(i.trim())]);
		});
		addCallback("getRandomBool", function(chance:Float = 50) return FlxG.random.bool(chance));

		addCallback("playMusic", function(sound:String, volume:Float = 1, loop:Bool = false){
			FlxG.sound.playMusic(Paths.music(sound), volume, loop);
		});
		addCallback("playSound", function(sound:String, volume:Float = 1, ?tag:String = null){
			if (tag != null && tag.length > 0){
				tag = tag.replace('.', '');
				if (ScriptPackPlayState.instance.modchartSounds.exists(tag)){
					ScriptPackPlayState.instance.modchartSounds.get(tag).stop();
				}
				ScriptPackPlayState.instance.modchartSounds.set(tag, FlxG.sound.play(Paths.sound(sound), volume, false, function(){
					ScriptPackPlayState.instance.modchartSounds.remove(tag);
					ScriptPackPlayState.instance.callOnLuas('onSoundFinished', [tag]);
				}));
				return;
			}
			FlxG.sound.play(Paths.sound(sound), volume);
		});
		addCallback("stopSound", function(tag:String){
			if (tag != null && tag.length > 1 && ScriptPackPlayState.instance.modchartSounds.exists(tag)){
				ScriptPackPlayState.instance.modchartSounds.get(tag).stop();
				ScriptPackPlayState.instance.modchartSounds.remove(tag);
			}
		});
		addCallback("pauseSound", function(tag:String){
			if (tag != null && tag.length > 1 && ScriptPackPlayState.instance.modchartSounds.exists(tag))
				ScriptPackPlayState.instance.modchartSounds.get(tag).pause();
		});
		addCallback("resumeSound", function(tag:String){
			if (tag != null && tag.length > 1 && ScriptPackPlayState.instance.modchartSounds.exists(tag))
				ScriptPackPlayState.instance.modchartSounds.get(tag).play();
		});
		addCallback("soundFadeIn", function(tag:String, duration:Float, fromValue:Float = 0, toValue:Float = 1){
			if (tag == null || tag.length < 1)
				FlxG.sound.music.fadeIn(duration, fromValue, toValue);
			else if (ScriptPackPlayState.instance.modchartSounds.exists(tag))
				ScriptPackPlayState.instance.modchartSounds.get(tag).fadeIn(duration, fromValue, toValue);
		});
		addCallback("soundFadeOut", function(tag:String, duration:Float, toValue:Float = 0){
			if (tag == null || tag.length < 1)
				FlxG.sound.music.fadeOut(duration, toValue);
			else if (ScriptPackPlayState.instance.modchartSounds.exists(tag))
				ScriptPackPlayState.instance.modchartSounds.get(tag).fadeOut(duration, toValue);
		});
		addCallback("soundFadeCancel", function(tag:String){
			if (tag == null || tag.length < 1){
				if (FlxG.sound.music.fadeTween != null)
					FlxG.sound.music.fadeTween.cancel();
			}else if (ScriptPackPlayState.instance.modchartSounds.exists(tag)){
				final theSound:FlxSound = ScriptPackPlayState.instance.modchartSounds.get(tag);
				if (theSound.fadeTween != null){
					theSound.fadeTween.cancel();
					ScriptPackPlayState.instance.modchartSounds.remove(tag);
				}
			}
		});
		addCallback("getSoundVolume", function(tag:String){
			if (tag == null || tag.length < 1){
				if (FlxG.sound.music != null)
					return FlxG.sound.music.volume;
			}else if (ScriptPackPlayState.instance.modchartSounds.exists(tag))
				return ScriptPackPlayState.instance.modchartSounds.get(tag).volume;
			return 0;
		});
		addCallback("setSoundVolume", function(tag:String, value:Float)
		{
			if (tag == null || tag.length < 1){
				if (FlxG.sound.music != null)
					FlxG.sound.music.volume = value;
			}else if (ScriptPackPlayState.instance.modchartSounds.exists(tag))
				ScriptPackPlayState.instance.modchartSounds.get(tag).volume = value;
		});
		addCallback("getSoundTime", function(tag:String){
			if (tag != null && tag.length > 0 && ScriptPackPlayState.instance.modchartSounds.exists(tag))
				return ScriptPackPlayState.instance.modchartSounds.get(tag).time;
			return 0;
		});
		addCallback("setSoundTime", function(tag:String, value:Float){
			if (tag != null && tag.length > 0 && ScriptPackPlayState.instance.modchartSounds.exists(tag)){
				final theSound:FlxSound = ScriptPackPlayState.instance.modchartSounds.get(tag);
				if (theSound != null){
					final wasResumed:Bool = theSound.playing;
					theSound.pause();
					theSound.time = value;
					if (wasResumed)	theSound.play();
				}
			}
		});

		addCallback("debugPrint", function(text1:Dynamic = '', text2:Dynamic = '', text3:Dynamic = '', text4:Dynamic = '', text5:Dynamic = ''){
			text1 ??= '';
			text2 ??= '';
			text3 ??= '';
			text4 ??= '';
			text5 ??= '';
			luaTrace(Std.string(text1 + text2 + text3 + text4 + text5), true, false);
		});

		addCallback("close", function(){
			closed = true;
			return closed;
		});

		// LUA TEXTS
		addCallback("makeLuaText", function(tag:String, text:String, width:Int, x:Float, y:Float){
			tag = tag.replace('.', '');
			resetTextTag(tag);
			final leText:ModchartText = new ModchartText(x, y, text, width);
			ScriptPackPlayState.instance.modchartTexts.set(tag, leText);
		});

		addCallback("setTextString", function(tag:String, text:String){
			final obj:FlxText = getTextObject(tag);
			if (obj != null)
				obj.text = text;
		});
		addCallback("setTextSize", function(tag:String, size:Int){
			final obj:FlxText = getTextObject(tag);
			if (obj != null)
				obj.size = size;
		});
		addCallback("setTextWidth", function(tag:String, width:Float){
			final obj:FlxText = getTextObject(tag);
			if (obj != null)
				obj.fieldWidth = width;
		});
		addCallback("setTextBorder", function(tag:String, size:Int, color:String)
		{
			final obj:FlxText = getTextObject(tag);
			if (obj != null){
				final colorNum:Int = color.startsWith('0x') ? Std.parseInt(color) : Std.parseInt('0xff' + color);

				obj.borderSize = size;
				obj.borderColor = colorNum;
			}
		});
		addCallback("setTextColor", function(tag:String, color:String){
			final obj:FlxText = getTextObject(tag);
			if (obj != null)
				obj.color = color.startsWith('0x') ? Std.parseInt(color) : Std.parseInt('0xff' + color);
		});
		addCallback("setTextFont", function(tag:String, newFont:String){
			final obj:FlxText = getTextObject(tag);
			if (obj != null)
				obj.font = Paths.font(newFont, true);
		});
		addCallback("setTextItalic", function(tag:String, italic:Bool){
			final obj:FlxText = getTextObject(tag);
			if (obj != null)
				obj.italic = italic;
		});
		addCallback("setTextAlignment", function(tag:String, alignment:String = 'left'){
			final obj:FlxText = getTextObject(tag);
			if (obj != null){
				obj.alignment = LEFT;
				switch (alignment.trim().toLowerCase()){
					case 'right':
						obj.alignment = RIGHT;
					case 'center':
						obj.alignment = CENTER;
				}
			}
		});

		addCallback("getTextString", function(tag:String){
			final obj:FlxText = getTextObject(tag);
			if (obj != null)
				return obj.text;
			return null;
		});
		addCallback("getTextSize", function(tag:String){
			final obj:FlxText = getTextObject(tag);
			if (obj != null)
				return obj.size;
			return -1;
		});
		addCallback("getTextFont", function(tag:String){
			final obj:FlxText = getTextObject(tag);
			if (obj != null)
				return obj.font;
			return null;
		});
		addCallback("getTextWidth", function(tag:String){
			final obj:FlxText = getTextObject(tag);
			if (obj != null)
				return obj.fieldWidth;
			return 0;
		});

		addCallback("addLuaText", function(tag:String){
			if (ScriptPackPlayState.instance.modchartTexts.exists(tag)){
				final shit:ModchartText = ScriptPackPlayState.instance.modchartTexts.get(tag);
				if (!shit.wasAdded){
					getInstance().add(shit);
					shit.wasAdded = true;
					// trace('added a thing: ' + tag);
				}
			}
		});
		addCallback("removeLuaText", function(tag:String, destroy:Bool = true){
			if (!ScriptPackPlayState.instance.modchartTexts.exists(tag))
				return;

			final pee:ModchartText = ScriptPackPlayState.instance.modchartTexts.get(tag);
			if (destroy)
				pee.kill();

			if (pee.wasAdded){
				getInstance().remove(pee, true);
				pee.wasAdded = false;
			}

			if (destroy){
				pee.destroy();
				ScriptPackPlayState.instance.modchartTexts.remove(tag);
			}
		});

		addCallback("initSaveData", function(name:String, ?folder:String = 'twistenginemods'){
			if (!ScriptPackPlayState.instance.modchartSaves.exists(name)){
				final save:FlxSave = new FlxSave();
				save.bind(name, folder);
				ScriptPackPlayState.instance.modchartSaves.set(name, save);
				return;
			}
			if (ClientPrefs.displErrs)
				luaTrace('Save file already initialized: ' + name);
		});
		addCallback("flushSaveData", function(name:String){
			if (ScriptPackPlayState.instance.modchartSaves.exists(name)){
				ScriptPackPlayState.instance.modchartSaves.get(name).flush();
				return;
			}
			if (ClientPrefs.displErrs)
				luaTrace('Save file not initialized: ' + name, false, false, FlxColor.RED);
		});
		addCallback("getDataFromSave", function(name:String, field:String){
			if (ScriptPackPlayState.instance.modchartSaves.exists(name)){
				final retVal:Dynamic = Reflect.field(ScriptPackPlayState.instance.modchartSaves.get(name).data, field);
				return retVal;
			}
			if (ClientPrefs.displErrs)
				luaTrace('Save file not initialized: ' + name, false, false, FlxColor.RED);
			return null;
		});
		addCallback("setDataFromSave", function(name:String, field:String, value:Dynamic){
			if (ScriptPackPlayState.instance.modchartSaves.exists(name)){
				Reflect.setField(ScriptPackPlayState.instance.modchartSaves.get(name).data, field, value);
				return;
			}
			if (ClientPrefs.displErrs)
				luaTrace('Save file not initialized: ' + name, false, false, FlxColor.RED);
		});

		addCallback("checkFileExists", function(filename:String, ?absolute:Bool = false){
			#if MODS_ALLOWED
			if (absolute) return FileSystem.exists(filename);

			final path:String = Paths.modFolders(filename);
			if (FileSystem.exists(path)) return true;
			return FileSystem.exists(Paths.getPath('$filename', TEXT));
			#else
			if (absolute) return Assets.exists(filename);
			return Assets.exists(Paths.getPath('$filename', TEXT));
			#end
		});
		addCallback("saveFile", function(path:String, content:String, ?absolute:Bool = false){
			try{
				if (!absolute)
					File.saveContent('mods/'+path, content);
				else
					File.saveContent(path, content);

				return true;
			}catch (e:Dynamic){
				if (ClientPrefs.displErrs)
					luaTrace("Error trying to save " + path + ": " + e, false, false, FlxColor.RED);
			}
			return false;
		});
		addCallback("deleteFile", function(path:String, ?ignoreModFolders:Bool = false){
			try{
				#if MODS_ALLOWED
				if (!ignoreModFolders){
					final lePath:String = Paths.modFolders(path);
					if (FileSystem.exists(lePath)){
						FileSystem.deleteFile(lePath);
						return true;
					}
				}
				#end

				final lePath:String = Paths.getPath(path, TEXT);
				if (Assets.exists(lePath)){
					FileSystem.deleteFile(lePath);
					return true;
				}
			}catch (e:Dynamic){
				if (ClientPrefs.displErrs)
					luaTrace("Error trying to delete " + path + ": " + e, false, false, FlxColor.RED);
			}
			return false;
		});
		addCallback("getTextFromFile", function(path:String, ?ignoreModFolders:Bool = false){
			return Paths.getTextFromFile(path, ignoreModFolders);
		});

		// DEPRECATED, DONT MESS WITH THESE SHITS, ITS JUST THERE FOR BACKWARD COMPATIBILITY
		addCallback("objectPlayAnimation", function(obj:String, name:String, forced:Bool = false, ?startFrame:Int = 0){
			if (ClientPrefs.displErrs)
				luaTrace("objectPlayAnimation is deprecated! Use playAnim instead", false, true);
			final luaSpr:FlxSprite = ScriptPackPlayState.instance.getLuaObject(obj, false);
			if (luaSpr != null){
				luaSpr.animation.play(name, forced, false, startFrame);
				return true;
			}

			final spr:FlxSprite = Reflect.getProperty(getInstance(), obj);
			if (spr != null){
				spr.animation.play(name, forced, false, startFrame);
				return true;
			}
			return false;
		});
		addCallback("luaSpriteMakeGraphic", function(tag:String, width:Int, height:Int, color:String){
			if (ClientPrefs.displErrs)
				luaTrace("luaSpriteMakeGraphic is deprecated! Use makeGraphic instead", false, true);
			if (ScriptPackPlayState.instance.modchartSprites.exists(tag)){
				final colorNum:Int = color.startsWith('0x') ? Std.parseInt(color) : Std.parseInt('0xff' + color);

				ScriptPackPlayState.instance.modchartSprites.get(tag).makeGraphic(width, height, colorNum);
			}
		});
		addCallback("luaSpriteAddAnimationByPrefix", function(tag:String, name:String, prefix:String, framerate:Int = 24, loop:Bool = true){
			if (ClientPrefs.displErrs)
				luaTrace("luaSpriteAddAnimationByPrefix is deprecated! Use addAnimationByPrefix instead", false, true);
			if (ScriptPackPlayState.instance.modchartSprites.exists(tag)){
				final cock:ModchartSprite = ScriptPackPlayState.instance.modchartSprites.get(tag);
				cock.animation.addByPrefix(name, prefix, framerate, loop);
				if (cock.animation.curAnim == null)
					cock.animation.play(name, true);
			}
		});
		addCallback("luaSpriteAddAnimationByIndices", function(tag:String, name:String, prefix:String, indices:String, framerate:Int = 24){
			if (ClientPrefs.displErrs)
				luaTrace("luaSpriteAddAnimationByIndices is deprecated! Use addAnimationByIndices instead", false, true);
			if (ScriptPackPlayState.instance.modchartSprites.exists(tag)){
				final strIndices:Array<String> = indices.trim().split(',');
				final die:Array<Int> = [for (i in 0...strIndices.length) Std.parseInt(strIndices[i])];

				final pussy:ModchartSprite = ScriptPackPlayState.instance.modchartSprites.get(tag);
				pussy.animation.addByIndices(name, prefix, die, '', framerate, false);
				if (pussy.animation.curAnim == null)
					pussy.animation.play(name, true);
			}
		});
		addCallback("luaSpritePlayAnimation", function(tag:String, name:String, forced:Bool = false){
			if (ClientPrefs.displErrs)
				luaTrace("luaSpritePlayAnimation is deprecated! Use playAnim instead", false, true);
			final luaSpr:FlxSprite = ScriptPackPlayState.instance.modchartSprites.get(tag);
			if (luaSpr != null)
				luaSpr.animation.play(name, forced);
		});
		addCallback("setLuaSpriteCamera", function(tag:String, camera:String = ''){
			if (ClientPrefs.displErrs)
				luaTrace("setLuaSpriteCamera is deprecated! Use setObjectCamera instead", false, true);
			if (ScriptPackPlayState.instance.modchartSprites.exists(tag)){
				ScriptPackPlayState.instance.modchartSprites.get(tag).cameras = [cameraFromString(camera)];
				return true;
			}
			if (ClientPrefs.displErrs)
				luaTrace("Lua sprite with tag: " + tag + " doesn't exist!");
			return false;
		});
		addCallback("setLuaSpriteScrollFactor", function(tag:String, scrollX:Float, scrollY:Float){
			if (ClientPrefs.displErrs)
				luaTrace("setLuaSpriteScrollFactor is deprecated! Use setScrollFactor instead", false, true);
			if (ScriptPackPlayState.instance.modchartSprites.exists(tag)){
				ScriptPackPlayState.instance.modchartSprites.get(tag).scrollFactor.set(scrollX, scrollY);
				return true;
			}
			return false;
		});
		addCallback("scaleLuaSprite", function(tag:String, x:Float, y:Float){
			if (ClientPrefs.displErrs)
				luaTrace("scaleLuaSprite is deprecated! Use scaleObject instead", false, true);
			if (ScriptPackPlayState.instance.modchartSprites.exists(tag)){
				final shit:ModchartSprite = ScriptPackPlayState.instance.modchartSprites.get(tag);
				shit.scale.set(x, y);
				shit.updateHitbox();
				return true;
			}
			return false;
		});
		addCallback("getPropertyLuaSprite", function(tag:String, variable:String){
			if (ClientPrefs.displErrs)
				luaTrace("getPropertyLuaSprite is deprecated! Use getProperty instead", false, true);
			if (ScriptPackPlayState.instance.modchartSprites.exists(tag)){
				final killMe:Array<String> = variable.split('.');
				if (killMe.length > 1){
					var coverMeInPiss:Dynamic = Reflect.getProperty(ScriptPackPlayState.instance.modchartSprites.get(tag), killMe[0]);
					for (i in 1...killMe.length - 1)
						coverMeInPiss = Reflect.getProperty(coverMeInPiss, killMe[i]);
					return Reflect.getProperty(coverMeInPiss, killMe[killMe.length - 1]);
				}
				return Reflect.getProperty(ScriptPackPlayState.instance.modchartSprites.get(tag), variable);
			}
			return null;
		});
		addCallback("setPropertyLuaSprite", function(tag:String, variable:String, value:Dynamic){
			if (ClientPrefs.displErrs)
				luaTrace("setPropertyLuaSprite is deprecated! Use setProperty instead", false, true);
			if (ScriptPackPlayState.instance.modchartSprites.exists(tag)){
				final killMe:Array<String> = variable.split('.');
				if (killMe.length > 1){
					var coverMeInPiss:Dynamic = Reflect.getProperty(ScriptPackPlayState.instance.modchartSprites.get(tag), killMe[0]);
					for (i in 1...killMe.length - 1)
						coverMeInPiss = Reflect.getProperty(coverMeInPiss, killMe[i]);
					Reflect.setProperty(coverMeInPiss, killMe[killMe.length - 1], value);
					return true;
				}
				Reflect.setProperty(ScriptPackPlayState.instance.modchartSprites.get(tag), variable, value);
				return true;
			}
			if (ClientPrefs.displErrs)
				luaTrace("Lua sprite with tag: " + tag + " doesn't exist!");
			return false;
		});
		addCallback("musicFadeIn", function(duration:Float, fromValue:Float = 0, toValue:Float = 1){
			FlxG.sound.music.fadeIn(duration, fromValue, toValue);
			if (ClientPrefs.displErrs)
				luaTrace('musicFadeIn is deprecated! Use soundFadeIn instead.', false, true);
		});
		addCallback("musicFadeOut", function(duration:Float, toValue:Float = 0){
			FlxG.sound.music.fadeOut(duration, toValue);
			if (ClientPrefs.displErrs)
				luaTrace('musicFadeOut is deprecated! Use soundFadeOut instead.', false, true);
		});


		// Other stuff
		addCallback("stringStartsWith", function(str:String, start:String)	return str.startsWith(start));
		addCallback("stringEndsWith", function(str:String, end:String)		return str.endsWith(end)	);
		addCallback("stringSplit", function(str:String, split:String)		return str.split(split)		);
		addCallback("stringTrim", function(str:String)						return str.trim()			);

		addCallback("FlxColor", function(color:String)						return FlxColor.fromString(color));
		addCallback("getColorFromName", function(color:String)				return FlxColor.fromString(color));
		addCallback("getColorFromString", function(color:String)			return FlxColor.fromString(color));
		addCallback("getColorFromHex", function(color:String)				return FlxColor.fromString('#$color'));

		addCallback("directoryFileList", function(folder:String) {
			var list:Array<String> = [];
			#if sys
			if(FileSystem.exists(folder)) {
				for (folder in FileSystem.readDirectory(folder)) {
					if (!list.contains(folder)) {
						list.push(folder);
					}
				}
			}
			#end
			return list;
		});

		if (PlayState.instance != null) initPlayState();


		initHaxeModule();

		addCallback("openCustomSubstate",  CustomSubstate.openCustomSubstate);
		addCallback("closeCustomSubstate", CustomSubstate.closeCustomSubstate);
		addCallback("insertToCustomSubstate", CustomSubstate.insertToCustomSubstate);
		#end
	}

	public function execute()
	{
		try
		{
			var sourse:String = Assets.exists(scriptName, TEXT) ? Assets.getText(scriptName) : null;
			if (sourse == null || sourse.trim().length == 0)
			{
				return this;
			}
			var result:Dynamic = LuaL.dostring(lua, sourse);
			var resultStr:String = Lua.tostring(lua, result);
			if (result != 0 && resultStr != null){
				if (ClientPrefs.displErrs)
				{
					Log('Error on lua script! ' + resultStr, RED);
					#if windows
					CoolUtil.alert(resultStr, 'Error on lua script!');
					#else
					luaTrace('Error loading lua script: "$scriptName"\n' + resultStr, true, false, FlxColor.RED);
					Log('Error loading lua script: "$scriptName"\n' + resultStr, RED);
					#end
				}
				lua = null;
				return this;
			}
			Lua.init_callbacks(lua);
		}
		catch(e)
		{
			trace(e);
			return this;
		}
		call('onCreate');
		trace('lua file loaded succesfully: $scriptName (${Math.round(haxe.Timer.stamp() * 1000 - times)}ms)');
		return this;
	}


	public function initPlayState()
	{

		// Default character positions woooo
		set('defaultBoyfriendX', game.BF_X);
		set('defaultBoyfriendY', game.BF_Y);
		set('defaultOpponentX', game.DAD_X);
		set('defaultOpponentY', game.DAD_Y);
		set('defaultGirlfriendX', game.GF_X);
		set('defaultGirlfriendY', game.GF_Y);

		// Song/Week shit
		set('curBpm', Conductor.bpm);
		set('bpm', PlayState.SONG.bpm);
		set('scrollSpeed', PlayState.SONG.speed);
		set('crochet', Conductor.crochet);
		set('stepCrochet', Conductor.stepCrochet);
		set('songLength', -1);
		set('songName', PlayState.SONG.song);
		set('startedCountdown', false);

		set('isStoryMode', PlayState.isStoryMode);
		// set('difficulty', PlayState.storyDifficulty);
		// set('difficultyName', CoolUtil.difficulties[PlayState.storyDifficulty]);
		set('weekRaw', PlayState.storyWeek);
		// set('week', WeekData.weeksList[PlayState.storyWeek]);
		set('seenCutscene', PlayState.seenCutscene);

		// Gameplay settings
		set('healthGainMult', game.healthGain);
		set('healthLossMult', game.healthLoss);
		set('instakillOnMiss', game.instakillOnMiss);
		set('botPlay', game.cpuControlled);
		set('practice', game.practiceMode);

		// Character shit
		set('boyfriendName', PlayState.SONG.player1);
		set('dadName', PlayState.SONG.player2);
		set('gfName', PlayState.SONG.gfVersion);

		addCallback("startDialogue", function(dialogueFile:String, music:String = null){
			var path:String = Paths.json(Paths.formatToSongPath(PlayState.SONG.song) + '/' + dialogueFile);

			luaTrace('Trying to load dialogue: ' + path);

			if (Assets.exists(path))
			{
				var shit:DialogueFile = DialogueBoxPsych.parseDialogue(path);
				if (shit.dialogue.length > 0)
				{
					game.startDialogue(shit, music);
					if (ClientPrefs.displErrs)
						luaTrace('Successfully loaded dialogue', false, false, FlxColor.GREEN);
					return true;
				}
				else
				{
					if (ClientPrefs.displErrs)
						luaTrace('Your dialogue file is badly formatted!', false, false, FlxColor.RED);
				}
			}
		else{
			if (ClientPrefs.displErrs)
				luaTrace('Dialogue file not found', false, false, FlxColor.RED);
			if (game.endingSong)
				game.endSong();
			else
				game.startCountdown();
		}
			return false;
		});
		addCallback("startVideo", function(videoFile:String, antialias:Bool = true){
			#if VIDEOS_ALLOWED
			return game.startVideo(videoFile, antialias);
			#else
			if (game.endingSong)
				game.endSong();
			else
				game.startCountdown();
			return true;
			#end
		});

		addCallback("loadSong", function(?name:String = null, ?difficultyNum:Int = -1){
			if (name == null || name.length < 1) name = PlayState.SONG.song;
			if (difficultyNum != -1) trace("Do you wanna 'difficults'? I don't heared about then.");
			// difficultyNum = PlayState.storyDifficulty;

			final poop = Highscore.formatSong(name);
			PlayState.SONG = Song.loadFromJson(poop, name);
			game.persistentUpdate = false;
			LoadingState.loadAndSwitchState(new PlayState());

			FlxG.sound.music.pause();
			FlxG.sound.music.volume = 0;

			game.vocals.pause();
			game.vocalsDAD.pause();

			game.vocals.volume = 0;
			game.vocalsDAD.volume = 0;
		});

		addCallback("getCharacterX", function(type:String){
			switch (type.toLowerCase()){
				case 'dad' | 'opponent':	return game.dadGroup.x;
				case 'gf' | 'girlfriend':	return game.gfGroup.x;
				default:					return game.boyfriendGroup.x;
			}
		});
		addCallback("setCharacterX", function(type:String, value:Float){
			switch (type.toLowerCase()){
				case 'dad' | 'opponent':	game.dadGroup.x = value;
				case 'gf' | 'girlfriend':	game.gfGroup.x = value;
				default:					game.boyfriendGroup.x = value;
			}
		});
		addCallback("getCharacterY", function(type:String){
			switch (type.toLowerCase()){
				case 'dad' | 'opponent':	return game.dadGroup.y;
				case 'gf' | 'girlfriend':	return game.gfGroup.y;
				default:					return game.boyfriendGroup.y;
			}
		});
		addCallback("setCharacterY", function(type:String, value:Float){
			switch (type.toLowerCase()){
				case 'dad' | 'opponent':	game.dadGroup.y = value;
				case 'gf' | 'girlfriend':	game.gfGroup.y = value;
				default:					game.boyfriendGroup.y = value;
			}
		});
		addCallback("cameraSetTarget", function(target:String){
			final isDad:Bool = target.toLowerCase() == 'dad';

			game.moveCamera(isDad);
			return isDad;
		});
		addCallback("triggerEvent", function(name:String, ?arg1:Dynamic = '', ?arg2:Dynamic = '', ?arg3:Dynamic = '', ?strumTime:Float = 0){
			game.triggerEventNote(name, Std.string(arg1), Std.string(arg2), Std.string(arg3), strumTime);
			// trace('Triggered event: ' + name + ', ' + value1 + ', ' + value2);
			return true;
		});

		addCallback("startCountdown", function(){
			game.startCountdown();
			return true;
		});
		addCallback("endSong", function(){
			game.KillNotes();
			game.endSong();
			return true;
		});
		addCallback("restartSong", function(?skipTransition:Bool = false){
			game.persistentUpdate = false;
			PauseSubState.restartSong(skipTransition);
			return true;
		});
		addCallback("exitSong", function(?skipTransition:Bool = false){
			if (skipTransition){
				FlxTransitionableState.skipNextTransIn = true;
				FlxTransitionableState.skipNextTransOut = true;
			}

			game.cancelMusicFadeTween();

			// if (PlayState.isStoryMode)
			// {
			// 	MusicBeatState.switchState(new StoryMenuState());
			// 	FlxG.sound.playMusic(Paths.music('freakyMenu'));
			// }
			// else
			{
				MusicBeatState.switchState(SongsState.inDebugFreeplay ? new SongsState() : new FreeplayState());
			}

			// PlayState.changedDifficulty = false;
			PlayState.chartingMode = false;
			game.transitioning = true;
			return true;
		});
		addCallback("getSongPosition", function() return Conductor.songPosition );
		addCallback("addLuaSprite", function(tag:String, front:Bool = false){
			final shit:ModchartSprite = ScriptPackPlayState.instance.modchartSprites.get(tag);
			if (shit == null || shit.wasAdded)
				return;
			if (front)
			{
				getInstance().add(shit);
			}
			else
			{
				if (PlayState.instance.isDead)
				{
					GameOverSubstate.instance.insert(GameOverSubstate.instance.members.indexOf(GameOverSubstate.instance.boyfriend), shit);
				}
				else
				{
					final position:Int = FlxMath.minInt(
						FlxMath.minInt(
								PlayState.instance.members.indexOf(PlayState.instance.gfGroup),
								PlayState.instance.members.indexOf(PlayState.instance.boyfriendGroup)
							),
								PlayState.instance.members.indexOf(PlayState.instance.dadGroup));
					/*
					var position:Int = PlayState.instance.members.indexOf(PlayState.instance.gfGroup);
					if (PlayState.instance.members.indexOf(PlayState.instance.boyfriendGroup) < position)
						position = PlayState.instance.members.indexOf(PlayState.instance.boyfriendGroup);
					else if (PlayState.instance.members.indexOf(PlayState.instance.dadGroup) < position)
						position = PlayState.instance.members.indexOf(PlayState.instance.dadGroup);
					*/
					PlayState.instance.insert(position, shit);
				}
			}
			shit.wasAdded = true;
			// trace('added a thing: ' + tag);
		});

		// Tween shit, but for strums
		addCallback("noteTweenX", function(tag:String, note:Int, value:Dynamic, duration:Float, ease:String){
			cancelTween(tag);
			if (note < 0) note = 0;
			final testicle:StrumNote = game.strumLineNotes.members[note % game.strumLineNotes.length];

			if (testicle == null)
				return;
			ScriptPackPlayState.instance.modchartTweens.set(tag, FlxTween.tween(testicle, {x: value}, duration, {
				ease: CoolUtil.getFlxEaseByString(ease),
				onComplete: function(twn:FlxTween){
					ScriptPackPlayState.instance.callOnLuas('onTweenCompleted', [tag]);
					ScriptPackPlayState.instance.modchartTweens.remove(tag);
				}
			}));
		});
		addCallback("noteTweenY", function(tag:String, note:Int, value:Dynamic, duration:Float, ease:String){
			cancelTween(tag);
			if (note < 0) note = 0;
			final testicle:StrumNote = game.strumLineNotes.members[note % game.strumLineNotes.length];

			if (testicle == null)
				return;
			ScriptPackPlayState.instance.modchartTweens.set(tag, FlxTween.tween(testicle, {y: value}, duration, {
				ease: CoolUtil.getFlxEaseByString(ease),
				onComplete: function(twn:FlxTween)
				{
					ScriptPackPlayState.instance.callOnLuas('onTweenCompleted', [tag]);
					ScriptPackPlayState.instance.modchartTweens.remove(tag);
				}
			}));
		});
		addCallback("noteTweenAngle", function(tag:String, note:Int, value:Dynamic, duration:Float, ease:String){
			cancelTween(tag);
			if (note < 0) note = 0;
			final testicle:StrumNote = game.strumLineNotes.members[note % game.strumLineNotes.length];

			if (testicle == null)
				return;
			ScriptPackPlayState.instance.modchartTweens.set(tag, FlxTween.tween(testicle, {angle: value}, duration, {
				ease: CoolUtil.getFlxEaseByString(ease),
				onComplete: function(twn:FlxTween)
				{
					ScriptPackPlayState.instance.callOnLuas('onTweenCompleted', [tag]);
					ScriptPackPlayState.instance.modchartTweens.remove(tag);
				}
			}));
		});
		addCallback("noteTweenDirection", function(tag:String, note:Int, value:Dynamic, duration:Float, ease:String){
			cancelTween(tag);
			if (note < 0) note = 0;
			final testicle:StrumNote = game.strumLineNotes.members[note % game.strumLineNotes.length];

			if (testicle == null)
				return;
			ScriptPackPlayState.instance.modchartTweens.set(tag, FlxTween.tween(testicle, {direction: value}, duration, {
				ease: CoolUtil.getFlxEaseByString(ease),
				onComplete: function(twn:FlxTween)
				{
					ScriptPackPlayState.instance.callOnLuas('onTweenCompleted', [tag]);
					ScriptPackPlayState.instance.modchartTweens.remove(tag);
				}
			}));
		});
		addCallback("noteTweenAngle", function(tag:String, note:Int, value:Dynamic, duration:Float, ease:String){
			cancelTween(tag);
			if (note < 0) note = 0;
			final testicle:StrumNote = game.strumLineNotes.members[note % game.strumLineNotes.length];

			if (testicle == null)
				return;
			ScriptPackPlayState.instance.modchartTweens.set(tag, FlxTween.tween(testicle, {angle: value}, duration, {
				ease: CoolUtil.getFlxEaseByString(ease),
				onComplete: function(twn:FlxTween){
					ScriptPackPlayState.instance.callOnLuas('onTweenCompleted', [tag]);
					ScriptPackPlayState.instance.modchartTweens.remove(tag);
				}
			}));
		});
		addCallback("noteTweenAlpha", function(tag:String, note:Int, value:Dynamic, duration:Float, ease:String){
			cancelTween(tag);
			if (note < 0) note = 0;
			final testicle:StrumNote = game.strumLineNotes.members[note % game.strumLineNotes.length];

			if (testicle == null)
				return;
			ScriptPackPlayState.instance.modchartTweens.set(tag, FlxTween.tween(testicle, {alpha: value}, duration, {
				ease: CoolUtil.getFlxEaseByString(ease),
				onComplete: function(twn:FlxTween){
					ScriptPackPlayState.instance.callOnLuas('onTweenCompleted', [tag]);
					ScriptPackPlayState.instance.modchartTweens.remove(tag);
				}
			}));
		});
		// stupid bietch ass functions
		addCallback("addScore", function(value:Int = 0){
			game.songScore += value;
			game.RecalculateRating();
		});
		addCallback("addMisses", function(value:Int = 0){
			game.songMisses += value;
			game.RecalculateRating();
		});
		addCallback("addHits", function(value:Int = 0){
			game.songHits += value;
			game.RecalculateRating();
		});
		addCallback("setScore", function(value:Int = 0){
			game.songScore = value;
			game.RecalculateRating();
		});
		addCallback("setMisses", function(value:Int = 0){
			game.songMisses = value;
			game.RecalculateRating();
		});
		addCallback("setHits", function(value:Int = 0){
			game.songHits = value;
			game.RecalculateRating();
		});
		addCallback("getScore", function()	return game.songScore	);
		addCallback("getMisses", function()	return game.songMisses	);
		addCallback("getHits", function()	return game.songHits	);

		addCallback("setHealth", function(value:Float = 0)	game.health = value		);
		addCallback("addHealth", function(value:Float = 0)	game.health += value	);
		addCallback("getHealth", function()	return game.health	);
		addCallback("addCharacterToList", function(name:String, type:String){
			game.addCharacterToList(name, switch (type.toLowerCase().trim())
			{
				case 'dad' | '1':				1;
				case 'gf' | 'girlfriend' | '2':	2;
				default: 0;
			});
		});
		addCallback("setRatingPercent", function(value:Float)	game.ratingPercent = value	);
		addCallback("setRatingName", function(value:String)		game.ratingName = value		);
		addCallback("setRatingFC", function(value:String)		game.ratingFC = value		);
		addCallback("characterDance", function(character:String){
			switch (character.toLowerCase())
			{
				case 'dad':					game.dad.dance();
				case 'gf' | 'girlfriend': 	if (game.gf != null) game.gf.dance();
				default: 					game.boyfriend.dance();
			}
		});
		addCallback("isNoteChild", function(parentID:Int, childID:Int){
			final parent:Note = cast ScriptPackPlayState.instance.getLuaObject('note${parentID}', false);
			final child:Note = cast ScriptPackPlayState.instance.getLuaObject('note${childID}', false);
			if (parent != null && child != null)
				return parent.tail.contains(child);

			if (ClientPrefs.displErrs)
				luaTrace('${parentID} or ${childID} is not a valid note ID', false, false, FlxColor.RED);
			return false;
		});
		addCallback("setHealthBarColors", function(leftHex:String, rightHex:String){
			var left:FlxColor = Std.parseInt(leftHex);
			if (!leftHex.startsWith('0x'))	left = Std.parseInt('0xff' + leftHex);
			var right:FlxColor = Std.parseInt(rightHex);
			if (!rightHex.startsWith('0x'))	right = Std.parseInt('0xff' + rightHex);
			PlayState.instance.reloadHealthBarColors(left, right);
		});
		addCallback("setTimeBarColors", function(leftHex:String, rightHex:String){
			var left:FlxColor = Std.parseInt(leftHex);
			if (!leftHex.startsWith('0x'))	left = Std.parseInt('0xff' + leftHex);
			var right:FlxColor = Std.parseInt(rightHex);
			if (!rightHex.startsWith('0x'))	right = Std.parseInt('0xff' + rightHex);

			var timeBar:FlxBar = game.variables.get("timeBar");
			if (timeBar != null)
			{
				timeBar.createFilledBar(right, left);
				timeBar.updateBar();
			}
		});
		addCallback("characterPlayAnim", function(character:String, anim:String, ?forced:Bool = false){
			if (ClientPrefs.displErrs)
				luaTrace("characterPlayAnim is deprecated! Use playAnim instead", false, true);
			switch (character.toLowerCase()){
				case 'dad':
					game.dad.playAnim(anim, forced);
				case 'gf' | 'girlfriend':
					game.gf?.playAnim(anim, forced);
				default:
					game.boyfriend.playAnim(anim, forced);
			}
		});
	}

	inline public function addLocalCallback(name:String, myFunction:Dynamic){
		#if LUA_ALLOWED
		callbacks.set(name, myFunction);
		addCallback(name, null); //just so that it gets called
		#end
	}
	inline public function addCallback(name:String, func:Dynamic) Lua_helper.add_callback(lua, name, func); //lazy

	public static function isOfTypes(value:Any, types:Array<Dynamic>)
	{
		for (type in types) if(Std.isOfType(value, type)) return true;
		return false;
	}

	#if hscript
	public function initHaxeModule()
	{
		hscript ??= new HScriptLua();
	}
	#end

	inline static function callMethodFromObject(classObj:Dynamic, funcStr:String, args:Array<Dynamic> = null){
		if(classObj == null) return null;

		for (f in funcStr.split('.'))
			classObj = getVarInArray(classObj, f.trim());

		final funcToRun:haxe.Constraints.Function = cast classObj;
		return funcToRun == null ? null : Reflect.callMethod(classObj, funcToRun, args);
	}

	public static function setVarInArray(instance:Dynamic, variable:String, value:Dynamic, ?allowMaps:Bool = false, ?bypassAccessor:Bool = false):Any
	{
		final splitProps:Array<String> = variable.split('[');
		if(splitProps.length > 1)
		{
			var target:Dynamic = null;
			if(ScriptPackPlayState.instance.variables.exists(splitProps[0]))
				target = ScriptPackPlayState.instance.variables.get(splitProps[0]) ?? target;
			else
				target = bypassAccessor ? Reflect.field(instance, splitProps[0]) : Reflect.getProperty(instance, splitProps[0]);

			for (i in 1...splitProps.length){
				final j:Dynamic = splitProps[i].substr(0, splitProps[i].length - 1);
				if(i >= splitProps.length - 1) target[j] = value; //Last array
				else target = target[j]; //Anything else
			}
			return target;
		}

		if(allowMaps && isMap(instance))
		{
			//trace(instance);
			instance.set(variable, value);
			return value;
		}

		if(ScriptPackPlayState.instance.variables.exists(variable)) {
			ScriptPackPlayState.instance.variables.set(variable, value);
			return value;
		}
		bypassAccessor ? Reflect.setField(instance, variable, value) : Reflect.setProperty(instance, variable, value);
		return value;
	}

	public static function getVarInArray(instance:Dynamic, variable:String, ?allowMaps:Bool = false, ?bypassAccessor:Bool = false):Any{
		final splitProps:Array<String> = variable.split('[');
		if(splitProps.length > 1){
			var target:Dynamic = null;
			variable = splitProps[0];
			if(ScriptPackPlayState.instance.variables.exists(variable))
				target = ScriptPackPlayState.instance.variables.get(variable) ?? target;
			else
				target = bypassAccessor ? Reflect.field(instance, variable) : Reflect.getProperty(instance, variable);

			var j:Dynamic;
			// if (Reflect.hasField(target, "get") && splitProps.length == 2)
			// {
			// 	target = Reflect.callMethod(null, Reflect.field(target, "get"), [j = splitProps[1].substr(0, splitProps[1].length - 1)]);
			// }
			// else
			{
				for (i in 1...splitProps.length){
					target = target[j = splitProps[i].substr(0, splitProps[i].length - 1)];
				}
			}
			return target;
		}

		if(allowMaps && isMap(instance))
		{
			//trace(instance);
			return instance.get(variable);
		}

		if(ScriptPackPlayState.instance.variables.exists(variable)) {
			final retVal:Dynamic = ScriptPackPlayState.instance.variables.get(variable);
			if(retVal != null)
				return retVal;
		}
		return bypassAccessor ? Reflect.field(instance, variable) : Reflect.getProperty(instance, variable);
	}

	public static function isMap(variable:Dynamic)
	{
		/*switch(Type.typeof(variable)){
			case ValueType.TClass(haxe.ds.StringMap) | ValueType.TClass(haxe.ds.ObjectMap) | ValueType.TClass(haxe.ds.IntMap) | ValueType.TClass(haxe.ds.EnumValueMap):
				return true;
			default:
				return false;
		}*/

		//trace(variable);
		if(variable.exists == null || variable.keyValueIterator == null) return false;
		return true;
	}

	static function getTextObject(name:String):FlxText
		return ScriptPackPlayState.instance.modchartTexts.exists(name) ?
				ScriptPackPlayState.instance.modchartTexts.get(name)
			:
				Reflect.getProperty(ScriptPackPlayState.instance, name);

	public static function getGroupStuff(leArray:Dynamic, variable:String, ?allowMaps:Bool = false, ?bypassAccessor:Bool = false) {
		final split:Array<String> = variable.split('.');
		if(split.length > 1)
		{
			var obj:Dynamic = Reflect.getProperty(leArray, split[0]);
			for (i in 1...split.length - 1)
				obj = Reflect.getProperty(obj, split[i]);

			leArray = obj;
			variable = split[split.length - 1];
		}

		if(allowMaps && isMap(leArray)) return leArray.get(variable);
		return bypassAccessor ? Reflect.field(leArray, variable) : Reflect.getProperty(leArray, variable);
	}

	static function loadFrames(spr:FlxSprite, image:String, spriteType:String){
		switch (spriteType.toLowerCase().trim()){
			// case "texture" | "textureatlas" | "tex":					spr.frames = AtlasFrameMaker.construct(image);
			// case "texture_noaa" | "textureatlas_noaa" | "tex_noaa":	spr.frames = AtlasFrameMaker.construct(image, null, true);
			case "packer" | "packeratlas" | "pac":					spr.frames = Paths.getPackerAtlas(image);
			default:												spr.frames = Paths.getSparrowAtlas(image);
		}
	}

	public static function setGroupStuff(leArray:Dynamic, variable:String, value:Dynamic, ?allowMaps:Bool = false, ?bypassAccessor:Bool = false) {
		final split:Array<String> = variable.split('.');
		if(split.length > 1)
		{
			var obj:Dynamic = Reflect.getProperty(leArray, split[0]);
			for (i in 1...split.length - 1)
				obj = Reflect.getProperty(obj, split[i]);

			leArray = obj;
			variable = split[split.length - 1];
		}
		if(allowMaps && isMap(leArray)) leArray.set(variable, value);
		else bypassAccessor ? Reflect.setField(leArray, variable, value) : Reflect.setProperty(leArray, variable, value);
		return value;
	}

	public static function getPropertyLoop(split:Array<String>, ?checkForTextsToo:Bool = true, ?getProperty:Bool=true, ?allowMaps:Bool = false):Dynamic
	{
		var obj:Dynamic = getObjectDirectly(split[0], checkForTextsToo);

		for (i in 1...(getProperty ? split.length - 1 : split.length)) obj = getVarInArray(obj, split[i], allowMaps);
		return obj;
	}


	static function resetTextTag(tag:String)
	{
		if (!ScriptPackPlayState.instance.modchartTexts.exists(tag)) return;
		var pee:ModchartText = ScriptPackPlayState.instance.modchartTexts.get(tag);
		pee.kill();
		if (pee.wasAdded) FlxG.state.remove(pee, true);
		pee.destroy();
		ScriptPackPlayState.instance.modchartTexts.remove(tag);
	}

	static function resetSpriteTag(tag:String)
	{
		if (!ScriptPackPlayState.instance.modchartSprites.exists(tag)) return;
		var pee:ModchartSprite = ScriptPackPlayState.instance.modchartSprites.get(tag);
		pee.kill();
		if (pee.wasAdded) FlxG.state.remove(pee, true);
		pee.destroy();
		ScriptPackPlayState.instance.modchartSprites.remove(tag);
	}

	static function tweenShit(tag:String, vars:String)
	{
		cancelTween(tag);
		var variables:Array<String> = vars.split('.');
		var sexyProp:Dynamic = getObjectDirectly(variables[0]);
		if (variables.length > 1) sexyProp = getVarInArray(getPropertyLoop(variables), variables[variables.length - 1]);
		return sexyProp;
	}

	static function oldTweenFunction(tag:String, vars:String, tweenValue:Any, duration:Float, ease:String, funcName:String)
	{
		#if LUA_ALLOWED
		final target:Dynamic = tweenPrepare(tag, vars);
		if(target == null)
		{
			// luaTrace('$funcName: Couldnt find object: $vars', false, false, FlxColor.RED);
			return;
		}
		// trace([tag, vars, tweenValue, duration, ease, funcName]);
		ScriptPackPlayState.instance.modchartTweens.set(tag, FlxTween.tween(target, tweenValue, duration, {
			ease: CoolUtil.getFlxEaseByString(ease),
			onComplete: function(twn:FlxTween) {
				ScriptPackPlayState.instance.modchartTweens.remove(tag);
				ScriptPackPlayState.instance.callOnLuas('onTweenCompleted', [tag, vars]);
			}
		}));
		#end
	}

	public static function tweenPrepare(tag:String, vars:String)
	{
		cancelTween(tag);
		final variables:Array<String> = vars.split('.');
		return variables.length > 1 ?
					getVarInArray(getPropertyLoopThingWhatever(variables), variables[variables.length-1])
				:
					getObjectDirectly(variables[0]);
	}

	public static function getLuaTween(options:Dynamic):LuaTweenOptions
		return {
			type: getTweenTypeByString(options.type),
			startDelay: options.startDelay,
			onUpdate: options.onUpdate,
			onStart: options.onStart,
			onComplete: options.onComplete,
			loopDelay: options.loopDelay,
			ease: CoolUtil.getFlxEaseByString(options.ease)
		}

	static function cancelTween(tag:String)
	{
		if (ScriptPackPlayState.instance.modchartTweens.exists(tag))
		{
			final theTween:FlxTween = ScriptPackPlayState.instance.modchartTweens.get(tag);
			theTween.cancel();
			theTween.destroy();
			ScriptPackPlayState.instance.modchartTweens.remove(tag);
		}
	}

	static function cancelTimer(tag:String)
	{
		if (ScriptPackPlayState.instance.modchartTimers.exists(tag))
		{
			final theTimer:FlxTimer = ScriptPackPlayState.instance.modchartTimers.get(tag);
			theTimer.cancel();
			theTimer.destroy();
			ScriptPackPlayState.instance.modchartTimers.remove(tag);
		}
	}

	//buncho string stuffs
	public static function getTweenTypeByString(?type:String = '')
	{
		return switch(type.toLowerCase().trim())
		{
			case 'backward': FlxTweenType.BACKWARD;
			case 'looping' | 'loop': FlxTweenType.LOOPING;
			case 'persist': FlxTweenType.PERSIST;
			case 'pingpong': FlxTweenType.PINGPONG;
			default: FlxTweenType.ONESHOT;
		}
	}

	public static function blendModeFromString(blend:String):BlendMode
		return cast(blend.toLowerCase().trim() : BlendMode);

	static function cameraFromString(cam:String):FlxCamera
	{
		return switch (cam.toLowerCase()) {
			case 'camhud' | 'hud':		PlayState.instance.camHUD;
			case 'camother' | 'other':	PlayState.instance.camOther;
			default:					PlayState.instance.camGame;
		}
	}

	public dynamic function luaTrace(text:String, ignoreCheck:Bool = false, deprecated:Bool = false, color:FlxColor = FlxColor.WHITE)
	{
		#if LUA_ALLOWED
		if (ignoreCheck || getBool('luaDebugMode'))
		{
			if (deprecated && !getBool('luaDeprecatedWarnings')) return;
			PlayState.instance.addTextToDebug(text, color);
			trace(text);
		}
		#end
	}

	public static dynamic function getInstance() return PlayState.instance.isDead ? GameOverSubstate.instance : PlayState.instance;

	public static function updateCurState()
	{
		if (Std.isOfType(FlxG.state, PlayState))
		{
			getInstance = () -> return PlayState.instance.isDead ? GameOverSubstate.instance : PlayState.instance;
			get_mainState = () -> return PlayState.instance;
		}
		else
		{
			getInstance = () -> return cast(FlxG.state, PlayState);
			get_mainState = () -> return FlxG.state;
		}
	}

	function getErrorMessage(status:Int):String
	{
		#if LUA_ALLOWED
		var v:String = Lua.tostring(lua, -1);
		Lua.pop(lua, 1);

		if (v != null) v = v.trim();
		if (v == null || v == "") {
			switch(status) {
				case Lua.LUA_ERRRUN: return "Runtime Error";
				case Lua.LUA_ERRMEM: return "Memory Allocation Error";
				case Lua.LUA_ERRERR: return "Critical Error";
			}
			return "Unknown Error";
		}

		return v;
		#else
		return null;
		#end
	}

	public var lastCalledFunction:String = '';
	public static var lastCalledScript:FunkinLua = null;
	public function call(func:String, ?args:Array<Dynamic>):Dynamic
	{
		#if LUA_ALLOWED
		if(closed) return Function_Continue;

		lastCalledFunction = func;
		lastCalledScript = this;
		if(lua == null) return Function_Continue;
		 args ??= [];
		// try {

			Lua.getglobal(lua, func);
			final type:Int = Lua.type(lua, -1);

			if (type != Lua.LUA_TFUNCTION)
			{
				if (type > Lua.LUA_TNIL)
				{
					final message:String = "ERROR: " + scriptName + " (" + func + "): attempt to call a " + typeToString(type) + " value";
					if (ClientPrefs.displErrs)
						luaTrace(message, true, false, FlxColor.RED);
				}

				Lua.pop(lua, 1);
				return Function_Continue;
			}

			for (arg in args) Convert.toLua(lua, arg);
			final status:Int = Lua.pcall(lua, args.length, 1, 0);
			// Checks if it's not successful, then show a error.
			if (status != Lua.LUA_OK)
			{
				final error:String = getErrorMessage(status);
				// $scriptName ERROR in $func [$status]:
				final message:String = '$error';
				// Log("ERROR: " + scriptName + '  ' + status + ' -> ' + error, RED);
				final a = closeOnError && status != Lua.LUA_ERRRUN;
				if (warningError && ClientPrefs.displErrs)
				{
					if (a)
						CoolUtil.alert(message, 'Error on $scriptName! Code: $status.');
					Log(message, RED, {
						fileName: scriptName,
						lineNumber: Std.parseInt(message.split(":")[1]).getDefault(0),
						className: "",
						methodName: func,
					});
				}
				if (a) stop(); //so damn 😭
				if ((a || (warningError && ClientPrefs.displErrs)) && errorHandler != null) errorHandler("(" + func + "): " + error);

				// Log("ERROR (" + func + "): " + error, RED);
				return Function_Continue;
			}

			// If successful, pass and then return the result.
			var result:Dynamic = cast Convert.fromLua(lua, -1);
			if (result == null) result = Function_Continue;

			Lua.pop(lua, 1);
			if(closed) stop();
			return result;

		// } catch(e:Dynamic) Log(e, RED);

		#end
		return Function_Continue;
	}
	static function typeToString(type:Int):String {
		#if LUA_ALLOWED
		switch(type)
		{
			case Lua.LUA_TBOOLEAN: return "boolean";
			case Lua.LUA_TNUMBER: return "number";
			case Lua.LUA_TSTRING: return "string";
			case Lua.LUA_TTABLE: return "table";
			case Lua.LUA_TFUNCTION: return "function";
		}
		if (type <= Lua.LUA_TNIL) return "nil";
		#end
		return "unknown";
	}

	public static function getPropertyLoopThingWhatever(killMe:Array<String>, ?checkForTextsToo:Bool = true, ?getProperty:Bool = true):Dynamic
	{
		var coverMeInPiss:Dynamic = getObjectDirectly(killMe[0], checkForTextsToo);
		var end = killMe.length;
		if (getProperty) end = killMe.length - 1;

		for (i in 1...end)
			coverMeInPiss = getVarInArray(coverMeInPiss, killMe[i]);

		return coverMeInPiss;
	}

	public static function getObjectDirectly(objectName:String, ?checkForTextsToo:Bool = true):Dynamic
	{
		final coverMeInPiss:Dynamic = ScriptPackPlayState.instance.getLuaObject(objectName, checkForTextsToo);
		if (coverMeInPiss == null)
			return getVarInArray(getInstance(), objectName);
		else
			return coverMeInPiss;
	}

	#if LUA_ALLOWED

	static function isErrorAllowed(error:String)
	{
		switch (error)
		{
			case 'attempt to call a nil value' | 'C++ exception':
				return false;
		}
		return true;
	}
	#end

	public function set(variable:String, data:Dynamic)
	{
		#if LUA_ALLOWED
		if (lua == null) return;

		Convert.toLua(lua, data);
		Lua.setglobal(lua, variable);
		#end
	}

	#if LUA_ALLOWED
	public function getBool(variable:String)
	{
		if(lastCalledScript == null) return false;

		var lua:State = lastCalledScript.lua;
		if(lua == null) return false;

		var result:String = null;
		Lua.getglobal(lua, variable);
		result = Convert.fromLua(lua, -1);
		Lua.pop(lua, 1);

		if (result == null)
			return false;

		return (result == 'true');
	}
	#end

	public function stop()
	{
		#if LUA_ALLOWED
		if (lua != null)
		{
			Lua.close(lua);
			lua = null;
		}
		callbacks.clear();
		#if hscript
		hscript?.dispose();
		hscript = null;
		#end
		#end
	}

	#if (!flash && sys)
	public function getShader(obj:String):FlxRuntimeShader
	{
		var killMe:Array<String> = obj.split('.');
		var leObj:FlxSprite = getObjectDirectly(killMe[0]);
		if(killMe.length > 1)
			leObj = getVarInArray(getPropertyLoopThingWhatever(killMe), killMe[killMe.length - 1]);

		if(leObj != null)
			return cast leObj.shader;
		return null;
	}
	#end

	function initLuaShader(shaderFile:String, customName:String = '', ?glslVersion:Int = 120)
	{
		final shaderName:String = (customName == '' ? shaderFile : customName);
		if(ScriptPackPlayState.instance.runtimeShaders.exists(shaderName)) {
			if (ClientPrefs.displErrs)
				luaTrace('Shader $shaderName was already initialized!');
			return true;
		}
		if(ClientPrefs.shaders){
			var frag:String = AssetsPaths.fragShader('$shaderFile');
			var vert:String = AssetsPaths.vertShader('$shaderFile');
			frag = Assets.exists(frag) ? Assets.getText(frag) : null;
			vert = Assets.exists(vert) ? Assets.getText(vert) : null;

			if (frag != null || vert != null){
				ScriptPackPlayState.instance.runtimeShaders.set(shaderName, [frag, vert]);
				return true;
			}

			if (ClientPrefs.displErrs)
			{
				luaTrace('Missing shader $shaderFile .frag AND .vert files!');
				FlxG.log.warn('Missing shader $shaderFile .frag AND .vert files!');
				Log('Missing shader $shaderFile .frag AND .vert files!', RED);
			}
		}
		return false;
	}
}

#if hscript
class HScriptLua
{
	public var parser:Parser;
	public var interp:Interp;

	public var variables(get, never):Map<String, Dynamic>;

	public function get_variables() return interp.variables;

	public function new(){
		parser = new Parser();
		interp = new Interp();
		interp.scriptObject = PlayState.instance;
		interp.variables.set('FlxG', FlxG);
		interp.variables.set('FlxSprite', FlxSprite);
		interp.variables.set('FlxCamera', FlxCamera);
		interp.variables.set('FlxTimer', FlxTimer);
		interp.variables.set('FlxTween', FlxTween);
		interp.variables.set('FlxEase', FlxEase);
		interp.variables.set('PlayState', PlayState);
		interp.variables.set('game', PlayState.instance);
		interp.variables.set('Paths', Paths);
		interp.variables.set('Conductor', Conductor);
		interp.variables.set('ClientPrefs', ClientPrefs);
		interp.variables.set('Character', Character);
		interp.variables.set('Alphabet', Alphabet);
		#if (!flash && sys)
		interp.variables.set('FlxRuntimeShader', FlxRuntimeShader);
		interp.variables.set('ShaderFilter', openfl.filters.ShaderFilter);
		#end
		interp.variables.set('StringTools', StringTools);

		interp.variables.set('setVar', function(name:String, value:Dynamic){
			ScriptPackPlayState.instance.variables.set(name, value);
		});
		interp.variables.set('getVar', function(name:String){
			var result:Dynamic = null;
			if(ScriptPackPlayState.instance.variables.exists(name)) result = ScriptPackPlayState.instance.variables.get(name);
			return result;
		});
		interp.variables.set('removeVar', function(name:String){
			if(ScriptPackPlayState.instance.variables.exists(name))
			{
				ScriptPackPlayState.instance.variables.remove(name);
				return true;
			}
			return false;
		});
	}

	public function dispose()
	{
		interp = null;
		parser = null;
	}
	public function execute(codeToRun:String):Dynamic
	{
		@:privateAccess
		parser.line = 1;
		parser.allowTypes = true;
		return interp.execute(parser.parseString(codeToRun));
	}
}
#end
#end

@:access(game.states.playstate.PlayState)
class CustomSubstate extends game.backend.system.states.MusicBeatSubstate
{
	public static var name:String = 'unnamed';
	public static var instance:CustomSubstate;

	public static function openCustomSubstate(name:String, ?pauseGame:Bool = false)
	{
		if(pauseGame)
		{
			PlayState.instance.onPause();
			// if (PlayState.instance.inst != null){
			// 	PlayState.instance.inst.pause();
			// 	PlayState.instance.vocals.pause();
			// 	PlayState.instance.vocalsDAD.pause();
			// }
		}
		PlayState.instance.openSubState(new CustomSubstate(name));
		ScriptPackPlayState.instance.setOnHScript('customSubstate', instance);
		ScriptPackPlayState.instance.setOnHScript('customSubstateName', name);
	}

	public static function closeCustomSubstate()
	{
		if(instance == null)
			return false;
		instance.close();
		// ScriptPackPlayState.instance.closeSubState();
		instance = null;
		ScriptPackPlayState.instance.setOnHScript('customSubstate', instance);
		ScriptPackPlayState.instance.setOnHScript('customSubstateName', name);
		return true;
	}

	public static function insertToCustomSubstate(tag:String, ?pos:Int = -1)
	{
		if(instance == null)
			return false;
		var tagObject:FlxObject = cast (ScriptPackPlayState.instance.variables.get(tag), FlxObject);
		#if LUA_ALLOWED if(tagObject == null) tagObject = ScriptPackPlayState.instance.modchartSprites.get(tag); #end

		if(tagObject != null)
		{
			if(pos < 0) instance.add(tagObject);
			else instance.insert(pos, tagObject);
		}
		return tagObject != null;
	}

	override function create(){
		instance = this;

		ScriptPackPlayState.instance.call('onCustomSubstateCreate', [name]);
		super.create();
		ScriptPackPlayState.instance.call('onCustomSubstateCreatePost', [name]);
	}

	public function new(name:String){
		CustomSubstate.name = name;
		super();
		cameras = [CoolUtil.getFrontCamera()];
	}

	override function update(elapsed:Float){
		ScriptPackPlayState.instance.call('onCustomSubstateUpdate', [name, elapsed]);
		super.update(elapsed);
		ScriptPackPlayState.instance.call('onCustomSubstateUpdatePost', [name, elapsed]);
	}

	override function destroy(){
		if (ScriptPackPlayState.instance != null){
			ScriptPackPlayState.instance.call('onCustomSubstateDestroy', [name]);
			name = 'unnamed';
			ScriptPackPlayState.instance.setOnHScript('customSubstate', null);
			ScriptPackPlayState.instance.setOnHScript('customSubstateName', name);
		}else name = 'unnamed';
		super.destroy();
	}
}

class ModchartSprite extends game.objects.TwistSprite
{
	public var wasAdded:Bool = false;
	// public var animOffsets:Map<String, Array<Float>> = new Map<String, Array<Float>>();

	// public var isInFront:Bool = false;
	/*
	public function playAnim(name:String, ?forced:Bool = false, ?reverse:Bool = false, ?startFrame:Int = 0) {
		final daOffset = animOffsets.get(name);
		// trace(daOffset);
		if (daOffset != null) offset.set(daOffset[0], daOffset[1]);
		animation.play(name, forced, reverse, startFrame);
	}
	*/
}

class ModchartText extends FlxFixedText
{
	public var wasAdded:Bool = false;

	public function new(x:Float, y:Float, text:String, width:Float){
		super(x, y, width, text, 16);
		setFormat(Paths.font("vcr.ttf", true), 16, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		cameras = [PlayState.instance.camHUD];
		scrollFactor.set();
		borderSize = 2;
	}
}

class DebugLuaText extends FlxFixedText
{
	public var disableTime:Float = 6;

	public function new(text:String, color:FlxColor)
	{
		super(10, 10, 0, text, 16);
		setFormat(Paths.font("vcr.ttf", true), 20, color, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		scrollFactor.set();
		borderSize = 1;
	}

	override function update(elapsed:Float)
	{
		disableTime -= elapsed;
		if (disableTime < 0)
		{
			disableTime = 0;
			kill();
		}
		if (disableTime < 1) alpha = disableTime;
		super.update(elapsed);
	}
}