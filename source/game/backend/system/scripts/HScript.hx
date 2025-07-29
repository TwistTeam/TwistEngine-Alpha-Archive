package game.backend.system.scripts;

#if HSCRIPT_ALLOWED
import flixel.math.FlxMath;
import flixel.util.FlxColor;
import game.backend.utils.LogsGame;
import game.backend.utils.Terminal;
import game.states.playstate.PlayState;
import haxe.PosInfos;
import haxe.extern.EitherType;
import hscript.*;
import hscript.Expr;
import hscript.Interp;
#if sys
import sys.FileSystem;
import sys.io.File;
#end

import hscript.UnsafeReflect;

@:access(hscript.Interp)
class HScript implements IScript implements flixel.util.FlxDestroyUtil.IFlxDestroyable
{
	public var interp:Interp;

	public var closed:Bool = false;
	public var scriptName:String = '';

	public var variables(get, never):Map<String, Dynamic>;

	inline function get_variables()
		return interp.variables;

	// port Orig Psych
	public inline function getPlayStateParams()
	{
		variables.set('game', PlayState.instance);
		variables.set('PlayState', PlayState); // yes

		variables.set('Rating', game.backend.system.song.Rating);

		// variables.set('add',				function(obj:FlxBasic) PlayState.instance.add(obj));
		// variables.set('addBehindGF',		function(obj:FlxBasic) PlayState.instance.addBehindGF(obj));
		// variables.set('addBehindDad',	function(obj:FlxBasic) PlayState.instance.addBehindDad(obj));
		// variables.set('addBehindBF',		function(obj:FlxBasic) PlayState.instance.addBehindBF(obj));
		// variables.set('insert', 			function(pos:Int, obj:FlxBasic) PlayState.instance.insert(pos, obj));
		// variables.set('remove', 			function(obj:FlxBasic, splice:Bool = false) PlayState.instance.remove(obj, splice));

		// Functions & Variables
		variables.set('setVar', function(name:String, value:Dynamic) return PlayState.instance.variables.set(name, value));
		variables.set('getVar', function(name:String) return PlayState.instance.variables.get(name));
		variables.set('removeVar', function(name:String) return PlayState.instance.variables.remove(name));
		variables.set('debugPrint', function(text:String, ?color:Null<FlxColor>)
			PlayState.instance.addTextToDebug(text, color ?? FlxColor.WHITE)
		);

		// not very tested but should work
		variables.set('createGlobalCallback', function(name:String, func:Dynamic)
		{
			#if LUA_ALLOWED
			for (script in PlayState.instance.luaArray)
				if (script != null && script.lua != null && !script.closed)
					llua.Lua.Lua_helper.add_callback(script.lua, name, func);
			FunkinLua.customFunctions.set(name, func);
			#end
		});
		return this;
	}

	public inline static function loadStateModule(path:String, parent:Dynamic, ?variables:Map<String, Dynamic>)
	{
		return new HScript(path, parent, variables);
	}

	public static function initParser()
	{
		var parser = new Parser();
		parser.allowJSON = parser.allowMetadata = parser.allowTypes = true;
		parser.preprocesorValues = game.backend.system.macros.DefinesMacro.defines.copy();
		return parser;
	}

	public final startTime = haxe.Timer.stamp() * 1000;

	static var parser:Parser = initParser();
	var expr:Expr;

	public var code:String;
	public var path:String;

	public function new(path:String, parent:Dynamic, ?extraParams:Map<String, Dynamic>)
	{
		onNew(path, parent, extraParams);
	}

	public static function getDefaultVariables():Map<String, Dynamic>
	{
		return [
			// Haxe related stuff
			"Std" => Std,
			"Math" => Math,
			"Reflect" => Reflect,
			"StringTools" => StringTools,
			"Json" => haxe.Json,
			'Date' => Date,
			'DateTools' => DateTools,
			"Type" => Type,
			#if sys
			"File" => File, "FileSystem" => FileSystem, 'Sys' => Sys,
			#end

			// OpenFL & Lime related stuff
			"Assets" => openfl.utils.Assets,
			"Application" => lime.app.Application,
			"Main" => game.Main,
			"BlendMode" => CoolUtil.getMacroAbstractClass("openfl.display.BlendMode"),

			// Flixel related stuff
			"FlxG" => flixel.FlxG,
			"FlxSprite" => flixel.FlxSprite,
			"FlxBasic" => flixel.FlxBasic,
			"FlxCamera" => flixel.FlxCamera,
			"FlxEase" => flixel.tweens.FlxEase,
			"FlxTween" => flixel.tweens.FlxTween,
			"FlxSound" => flixel.sound.FlxSound,
			"FlxAssets" => flixel.system.FlxAssets,
			"FlxMath" => flixel.math.FlxMath,
			"FlxGroup" => flixel.group.FlxGroup,
			"FlxTypedGroup" => flixel.group.FlxGroup.FlxTypedGroup,
			"FlxSpriteGroup" => flixel.group.FlxSpriteGroup,
			"FlxTypedSpriteGroup" => flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup,
			"FlxTypeText" => flixel.addons.text.FlxTypeText,
			"FlxText" => flixel.text.FlxText,
			"FlxTimer" => flixel.util.FlxTimer,
			"FlxRect" => flixel.math.FlxRect,
			"FlxPoint" => CoolUtil.getMacroAbstractClass("flixel.math.FlxPoint"),
			"FlxAxes" => CoolUtil.getMacroAbstractClass("flixel.util.FlxAxes"),
			"FlxColor" => CoolUtil.getMacroAbstractClass("flixel.util.FlxColor"),

			'Function_Stop' => ScriptUtil.Function_Stop,
			'Function_Continue' => ScriptUtil.Function_Continue,
			'Function_StopLua' => ScriptUtil.Function_StopLua, // doesnt do much cuz HScript has a lower priority than Lua
			'Function_StopHScript' => ScriptUtil.Function_StopHScript,
			'Function_StopAll' => ScriptUtil.Function_StopAll,

			"HScript" => HScript,
			#if LUA_ALLOWED
			'FunkinLua' => FunkinLua, 'CustomSubstate' => FunkinLua.CustomSubstate,
			#end

			// Engine related stuff
			"PlayState" => PlayState,
			"GameOverSubstate" => game.states.substates.GameOverSubstate,
			"HealthIcon" => game.objects.game.HealthIcon,
			"Note" => game.objects.game.notes.Note,
			"StrumNote" => game.objects.game.notes.StrumNote,
			"Character" => game.objects.game.Character,
			"TwistSprite" => game.objects.TwistSprite,
			"FunkinSprite" => game.objects.FunkinSprite,
			"PauseSubState" => game.states.substates.PauseSubState,
			"FreeplayState" => game.states.FreeplayState,
			"MainMenuState" => game.states.MainMenuState,
			// "StoryMenuState" => game.states.StoryMenuState,
			// "TitleState" => game.states.TitleState,
			"StoryMenuState" => null,
			"TitleState" => null,
			"AssetsPaths" => AssetsPaths,
			"Paths" => Paths,
			"FlxAnimate" => game.objects.FlxAnimate,
			"Alphabet" => game.objects.Alphabet,

			'ClientPrefs' => ClientPrefs,
			'LogsGame' => game.backend.utils.LogsGame,
			#if windows
			"TColor" => TColor,
			#end
			'FlxRuntimeShader' => flixel.addons.display.FlxRuntimeShader,
			'FlxToyShader' => game.shaders.FlxToyShader,
			'ShaderFilter' => openfl.filters.ShaderFilter,

			#if DISCORD_RPC
			'DiscordClient' => game.backend.system.net.Discord.DiscordClient,
			#end

			"CoolUtil" => CoolUtil,
		];
	}

	function pushEnum(path:EitherType<String, Enum<Dynamic>>)
	{
		if (path is Enum)
		{
			interp.importEnum(cast path);
			return;
		}
		var path:String = cast path;
		var enm = Type.resolveEnum(path);
		// if (enm == null)
		// 	enm = Type.resolveEnum(path + "_HSC");
		if (enm == null)
		{
			var clas = CoolUtil.getMacroAbstractClass(path);
			clas ??= Type.resolveClass(path);
			if (clas != null)
			{
				var enumThingy = {};
				var fields = Type.getClassFields(clas);
				if (fields == null || fields.length == 0)
				{
					fields = Type.getInstanceFields(clas);
				}
				for (c in fields) {
					try {
						UnsafeReflect.setField(enumThingy, c, UnsafeReflect.field(clas, c));
					} catch(e) {}
				}
				variables.set(path.split(".").getLast(), enumThingy);
				for (i in UnsafeReflect.fields(enumThingy))
				{
					var field = UnsafeReflect.field(enumThingy, i);
					if (Type.typeof(field) != TFunction)
					{
						variables.set(i, field);
					}
				}
			}
		}
		else
		{
			interp.importEnum(enm);
		}
	}

	static final _fileEReg = new EReg(".*/([^/]+)$", "");
	function onNew(path:String, parent:Dynamic, ?extraParams:Map<String, Dynamic>)
	{
		this.path = path;
		// scriptName = path.split("/").last();
		scriptName = _fileEReg.match(path) ? _fileEReg.matched(1) : "|UNKNOWN|";
		interp = new Interp2();
		try
		{
			code = Assets.getText(path);
		}
		catch(e)
			Log('Error while reading $path: ${Std.string(e)}', RED);

		interp.allowStaticVariables = interp.allowPublicVariables = true;
		interp.errorHandler = onError;
		interp.importFailedCallback = importFailedCallback;
		interp.scriptObject = parent;
		interp.staticVariables = ScriptPack.staticVariables;

		for (i => j in getDefaultVariables())
		{
			variables.set(i, j);
		}

		pushEnum(flixel.text.FlxText.FlxTextBorderStyle);
		pushEnum("flixel.tweens.FlxTweenType");
		pushEnum("flixel.util.FlxAxes");
		pushEnum(flixel.util.FlxHorizontalAlign);
		pushEnum(flixel.util.FlxVerticalAlign);
		pushEnum("openfl.display.BlendMode");

		// variables.set("trace", UnsafeReflect.makeVarArgs(function(el) {
		// 	var inf = getCurPosInfo();
		// 	var v = el.shift();
		// 	if (el.length > 0)
		// 		inf.customParams = el;
		// 	haxe.Log.trace(Std.string(v), inf);
		// }));

		// console log shit
		variables.set("Log", (args:Dynamic, color:TColor) -> Log(Std.string(args), color, getCurPosInfo()));

		variables.set('Conductor', game.backend.system.song.Conductor.mainInstance);
		variables.set('__scriptName__', scriptName);
		variables.set("__this__", this);
		variables.set("__globalScriptPack__", GlobalScript.scripts);
		variables.set("__globalScript__", GlobalScript.scripts?.hscriptArray[0]);
		variables.set('dispose', dispose);
		// i think it's pretty neat!
		variables.set('importHScriptClasses', (hscript:flixel.util.typeLimit.OneOfTwo<HScript, String>, allowOverride:Bool = false) ->
		{
			if (hscript == null)
			{
				Log("Can't load classes from a null", RED, getCurPosInfo());
				return;
			}
			if (hscript is HScript)
			{
				var hscript:HScript = hscript;
				if (hscript.interp == null)
				{
					Log("Can't load classes from a destroyed HScript instance", RED, getCurPosInfo());
					return;
				}

				for (className in hscript.interp.customClasses.keys())
				{
					// try to import custom class
					if (!allowOverride && interp.customClasses.exists(className))
						continue;

					var cl:Dynamic = hscript.interp.customClasses.get(className);
					interp.customClasses.set(className, cl);

					// try to import super of custom class
					switch (cl)
					{
						case EClass(_, _, extend, _):
							if (extend != null && (allowOverride || !interp.variables.exists(extend)))
								interp.variables.set(extend, hscript.interp.resolve(extend, false));

						default: // nothing
					}
				}
			}
			else
			{
				var assetsPath:String = hscript;
				assetsPath = 'assets/$assetsPath';
				if (game.backend.utils.PathUtil.extension(assetsPath) == null)
				{
					assetsPath += ".hx";
				}
				if (Assets.exists(assetsPath))
				{
					var code = Assets.getText(assetsPath);
					var modules:Array<ModuleDecl> = null;
					parser.line = 1;
					try
					{
						if (code != null && code.trim().length > 0)
							modules = parser.parseModule(code, assetsPath);
					}
					catch (e:Error)
					{
						onError(e);
					}
					catch (e)
					{
						onError(new Error(ECustom(e.toString()), 0, 0, assetsPath, 0));
					}
					for (i in modules)
					{
						switch(i)
						{
							case DImport(paths, everything):
								@:privateAccess
								interp.exprReturn(interp.mk(everything ? EImportStar(paths.join(".")) : EImport(paths.join("."))));
							case DClass(cl):
								if (!allowOverride && interp.customClasses.exists(cl.name))
									continue;

								var exprFields:Array<Expr> = [];
								if (cl.fields != null)
								{
									var eAccess:EFieldAccess;
									for (field in cl.fields)
									{
										eAccess = new EFieldAccess();
										for(i in field.access)
										{
											switch(i)
											{
												case APublic:	eAccess.isPublic = true;
												case APrivate:	eAccess.isPrivate = true;
												case AInline:	eAccess.isInline = true;
												case AOverride:	eAccess.isOverride = true;
												case AStatic:	eAccess.isStatic = true;
												case AMacro:	eAccess.isMacro = true;
											}
										}
										switch(field.kind)
										{
											case KFunction(func):
												exprFields.push(interp.mk(EFunction(func.args, func.expr, field.name, func.ret, eAccess)));
											case KVar(v):
												exprFields.push(interp.mk(EVar(field.name, v.type, v.expr, eAccess)));
										}
									}
								}
								var expr = interp.mk(EClass(cl.name, exprFields, Printer.convertTypeToString(cl.extend), [], cl.isExtern));
								@:privateAccess
								interp.exprReturn(expr);
							default:
						}
					}
				}
				else
				{
					Log('"$assetsPath" does\'t exists', RED, getCurPosInfo());
				}
			}
		});

		if (extraParams != null)
		{
			for (i => j in extraParams)
				variables.set(i, j);
		}
	}

	public function reload(runScript:Bool = true)
	{
		// save variables
		interp.allowStaticVariables = interp.allowPublicVariables = false;
		var savedVariables:Map<String, Dynamic> = new Map<String, Dynamic>();
		for (k => e in interp.variables)
		{
			if (!UnsafeReflect.isFunction(e))
			{
				savedVariables[k] = e;
			}
		}
		var oldParent = interp.scriptObject;
		onNew(path, oldParent, savedVariables);
		interp.allowStaticVariables = interp.allowPublicVariables = true;
		if (runScript)
			execute();
	}

	public function getVar(name:String)
	{
		return interp.publicVariables.get(name);
	}

	public function setVar(name:String, variable:Dynamic)
	{
		interp.publicVariables.set(name, variable);
		return variable;
	}

	public function existsVar(name:String)
	{
		return interp.publicVariables.exists(name);
	}

	public function setParent(parent:Dynamic)
	{
		interp.scriptObject = parent;
	}

	function importFailedCallback(cl:Array<String>):Bool
	{
		var _impFailedPath = cl.join(".");
		if (ScriptUtil.defineClasses.exists(_impFailedPath))
		{
			variables.set(_impFailedPath, ScriptUtil.defineClasses.get(_impFailedPath));
			return true;
		}
		_impFailedPath = cl.join("/");
		var assetsPath = 'assets/$_impFailedPath.hx';
		if (Assets.exists(assetsPath))
		{
			var code = Assets.getText(assetsPath);
			var expr:Expr = null;
			parser.line = 1;
			try
			{
				if (code != null && code.trim().length > 0)
					expr = parser.parseString(code, _impFailedPath);
			}
			catch (e:Error)
			{
				onError(e);
			}
			catch (e)
			{
				onError(new Error(ECustom(e.toString()), 0, 0, assetsPath, 0));
			}
			if (expr != null)
			{
				@:privateAccess
				interp.exprReturn(expr);
				// parser = destroyParser(parser);
			}
			return true;
		}
		return false;
	}

	public function execute()
	{
		if (code != null && code.trim().length > 0)
		{
			parser.line = 1;
			try
			{
				this.expr = parser.parseString(code, path);
				// trace(hscript.Printer.toString(this.expr));
			}
			catch (e)
			{
				@:privateAccess
				interp.execute(parser.mk(EBlock([]), 0, 0));
				if (ClientPrefs.displErrs)
				{
					Log('[HScript Syntax Error]: ${e.message}', RED, getCurPosInfo());
					CoolUtil.alert(e.message, "HScript Syntax Error!");
				}
				return null;
			}
		}
		if (expr == null)
		{
			@:privateAccess
			interp.execute(parser.mk(EBlock([]), 0, 0));
			dispose();
			if (ClientPrefs.displErrs)
				Log('Null Program', RED, getCurPosInfo());
			return null;
		}
		interp.execute(expr);

		// clear memory
		// parser = destroyParser(parser);
		expr = null;

		// call('new');
		call('onCreate');
		trace('hx file loaded succesfully: $path (${Math.round(haxe.Timer.stamp() * 1000 - startTime)}ms)');
		return this;
	}

	var _lastErr:String;
	var _countErrs:Int;
	static extern inline final MAX_ERRORS_COUNT:Int = 5;
	function alertErr(e:hscript.Expr.Error)
	{
		if (ClientPrefs.displErrs)
		{
			var message:String = '[HScript Program Error]: ' + Printer.errorToStringMessage(e);
			Log(message, RED, {
				fileName: path,
				lineNumber: #if hscriptPos e.line #else 0 #end,
				className: "",
				methodName: ""
			});
			/*
			#if hscriptPos
			var uncorrectCode:String = code == null ? "" : code.substring(interp.curExpr.pmin, interp.curExpr.pmax);
			if (uncorrectCode != null)
			{
				Terminal.instance.fg(MAGENTA);
				Terminal.instance.bg(DARKRED);
				Terminal.instance.print(Terminal._BLINK);
				Terminal.instance.println(uncorrectCode);
				Terminal.instance.reset();
				message += "\n" + uncorrectCode;
			}
			#end
			*/
			// CoolUtil.alert(e.message + "\n Function: " + lastEvent + "\n In script '" + scriptName + "'", "Function ('+eventName+') Executing Error!");
			#if (UI_POPUPS && hscriptPos)
			if (!ClientPrefs.displErrsWindow)
				CoolUtil.alert('$path:${e.line}:\n$message', "HScript Program Error!");
			else
			#end
			CoolUtil.alert('$path:\n$message', "HScript Program Error!");
		}
	}
	function onError(e:hscript.Expr.Error)
	{
		alertErr(e);

		// THX TO AHIKA
		var strErr:String = e.toString();
		if (strErr == _lastErr)
		{
			_countErrs++;
			if (_countErrs > MAX_ERRORS_COUNT)
			{
				dispose();
			}
		}
		else
		{
			_lastErr = strErr;
			_countErrs = 1;
		}
	}


	public function call(funcName:String, ?args:Array<Dynamic>):Dynamic
	{
		if (closed || interp == null || funcName == null)
			return ScriptUtil.Function_Continue;

		// if(expr == null) {
		// 	Log('Null Script', RED, cast {fileName: scriptName, lineNumber: -1});
		// 	dispose();
		// 	return null;
		// }

		var func = interp.variables.get(funcName);
		return func != null && UnsafeReflect.isFunction(func) ? UnsafeReflect.callMethod(null, func, args) : ScriptUtil.Function_Continue;
	}

	public inline function getCurPosInfo():PosInfos
	{
		return interp.posInfos();
	}

	public inline function dispose():Bool
		return this.closed = true;

	public inline function activate():Bool
		return this.closed = false;

	/*
		function import_type(path:String, ?customName:String = '') {
			// importClass("flixel.util.FlxSort") should give you FlxSort.byValues, etc
			// whereas importClass("scripts.Globals.*") should give you Function_Stop, Function_Continue, etc
			// i would LIKE to do like.. flixel.util.* but idk if I can get everything in a namespace
			var classSplit:Array<String> = path.split(".");
			var daClassName = classSplit.getLastOfArray(); // last one

			if (customName != '') daClassName = customName;

			if (daClassName == '*' && customName != '*'){
				var daClass:Dynamic = Type.resolveClass(path);

				while(classSplit.length > 0 && daClass==null){
					daClassName = classSplit.pop();
					daClass = Type.resolveClass(classSplit.join("."));
					if(daClass == null) daClass = Type.resolveEnum(classSplit.join("."));
					if(daClass != null) break;
				}
				if(daClass!=null){
					for(field in UnsafeReflect.fields(daClass)){
						variables.set(field, UnsafeReflect.field(daClass, field));
					}
				}
			}else{
				var daClass:Dynamic = Type.resolveClass(path);
				if (daClass == null) daClass = Type.resolveEnum(path);
				if (daClass != null) variables.set(daClassName, daClass);
			}
		}
	 */
	public function destroy()
	{
		// this = null;
		dispose();
		expr = null;
		destroyInterp(interp);
		interp = null;
		// parser = destroyParser(parser);
		// interp.resetVariables();
		// interp.locals = null;
	}

	public static function destroyParser(parser:Parser):Parser
	{
		if (parser != null)
		{
			parser.preprocesorValues.clear();
			parser.opRightAssoc.clear();
			parser.opPriority.clear();
			parser = null;
		}
		return parser;
	}

	@:access(hscript.Interp)
	public static function destroyInterp(interp:Interp):Interp
	{
		if (interp != null)
		{
			@:bypassAccessor
			interp.scriptObject = null;
			interp.__instanceFields.clearArray();
			interp.importBlocklist.clearArray();
			interp.declared.clearArray();
			interp.locals.clear();
			interp = null;
		}
		return interp;
	}
}

// The sequel
class Interp2 extends Interp
{
	public override function set_scriptObject(v:Dynamic)
	{
		super.set_scriptObject(v);
		if (scriptObject is PlayState)
			variables.set('addHxObject', (obj:FlxBasic, front:Bool = false) ->
			{
				return
					if (front)
						PlayState.instance.add(obj)
					else
						PlayState.instance.insert(
							FlxMath.minInt(
								FlxMath.minInt(
									PlayState.instance.members.indexOf(PlayState.instance.gfGroup),
									PlayState.instance.members.indexOf(PlayState.instance.boyfriendGroup)
									),
								PlayState.instance.members.indexOf(PlayState.instance.dadGroup
								)
							),
							obj);
			});
		else
			variables.set('addHxObject', (obj:FlxBasic, front:Bool = true) -> return front ? FlxG.state.add(obj) : FlxG.state.insert(0, obj));
		return scriptObject;
	}
}
#end
