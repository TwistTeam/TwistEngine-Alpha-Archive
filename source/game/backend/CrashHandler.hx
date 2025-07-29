package game.backend;

import game.backend.data.EngineData;
import game.backend.system.InfoAPI;
import game.backend.system.macros.GitCommitMacro;
import game.backend.system.macros.HaxeLibsMacro;
import game.backend.utils.Terminal;

import openfl.errors.Error;
import openfl.events.ErrorEvent;
import openfl.events.UncaughtErrorEvent;

import haxe.CallStack;
import haxe.io.Path;

#if sys
import sys.FileSystem;
import sys.io.File;
#end

class CrashHandler
{
	public static final LOG_FOLDER = "./crash/";
	public static final END_MESSAGE = "Please report this error to the Redar13 in Discord (@redar13)";

	@:allow(game.backend.utils.LogsGame)
	static var WRITE_TRACES_HISTORY:Bool = #if LOG_TRACES_ON_CRASH true #else false #end;
	@:allow(game.backend.utils.LogsGame)
	static var DISPLAY_TRACES_HISTORY:Bool = #if LOG_TRACES_ON_CRASH true #else false #end;
	@:allow(game.backend.utils.LogsGame)
	static var TRACES_HISTORY:StringBuf = new StringBuf();

	static var DIVIDER(get, never):String;
	static function get_DIVIDER():String return "\n".rpad("=", 1 + 42);

	public static function onUncaughtCrash(e:UncaughtErrorEvent):Void
	{
		FlxG.sound.destroy();
		if (FlxG.random.bool(7))
			FlxG.sound.play(Paths.sound("system/explode1"));
		LogsGame.colorConsole = RED;
		var stackLabel:StringBuf = new StringBuf();
		stackLabel.add(buildMessage(e, CallStack.exceptionStack(true)));

		stackLabel.add(DIVIDER);

		stackLabel.add("\n");

		var mainInfo:String = stackLabel.toString();
		if (END_MESSAGE.length > 0)
			mainInfo += "\n" + END_MESSAGE;
		Terminal.instance.println(mainInfo);

		stackLabel.add(buildFinalInfos());

		saveContentWithTime('TwistEngine${EngineData.engineVersion}_', stackLabel.toString());


		LogsGame.colorConsole = null;

		#if DEV_BUILD
		if (FlxG.random.bool(10))
			CoolUtil.browserLoad(FlxG.random.getObject([
				"https://www.youtube.com/watch?v=uQQDfHUbaV8" // your freaky video after crash here!
			]));
		#end

		displayAlert(mainInfo, "UNCAUGHT ERROR");
		/* todo
		var crashDialoguePath:String = "CrashDialog" #if windows + ".exe" #end;
		if (FileSystem.exists("./" + crashDialoguePath))
		{
			Terminal.instance.println("Found crash dialog: " + crashDialoguePath);

			#if linux
			crashDialoguePath = "./" + crashDialoguePath;
			#end
			new sys.io.Process(crashDialoguePath, [path]);
		}
		else
		{
			// I had to do this or the stupid CI won't build :distress:
			displayAlert(mainInfo, titleMessage);
		}
		*/

		exit();
	}

	public static function crashWithCustomMessage(titleMessage:String, message:String, logFile:String, showCurrentInfo:Bool = true):Void
	{
		FlxG.sound.destroy();
		if (FlxG.random.bool(7))
			FlxG.sound.play(Paths.sound("system/explode1"));
		LogsGame.colorConsole = RED;

		var lines = message.split("\n");
		if (lines.length > 30 + 1) // max 30 lines
		{
			lines.resize(30 + 1);
			lines.push("...");
		}
		var displayMessage = lines.join("\n");
		var stackLabel:StringBuf = new StringBuf();
		stackLabel.add(titleMessage);
		stackLabel.add(":\n<___message___>");
		stackLabel.add("\n");
		stackLabel.add(DIVIDER);
		stackLabel.add("\n");

		var mainInfo:String = stackLabel.toString().replace("<___message___>", displayMessage);
		if (END_MESSAGE.length > 0)
			mainInfo += "\n" + END_MESSAGE;
		Terminal.instance.println(mainInfo);

		if (showCurrentInfo)
		{
			stackLabel.add(buildFinalInfos());
		}

		saveContentWithTime('TwistEngine${EngineData.engineVersion}_${logFile ?? "idk_error"}_', stackLabel.toString().replace("<___message___>", message));

		LogsGame.colorConsole = null;

		#if DEV_BUILD
		if (FlxG.random.bool(10))
			CoolUtil.browserLoad(FlxG.random.getObject([
				"https://www.youtube.com/watch?v=Euq7uTeYCP0",
				"https://www.youtube.com/watch?v=uQQDfHUbaV8"
			]));
		#end

		displayAlert(mainInfo, titleMessage);
		/* todo
		var crashDialoguePath:String = "CrashDialog" #if windows + ".exe" #end;
		if (FileSystem.exists("./" + crashDialoguePath))
		{
			Terminal.instance.println("Found crash dialog: " + crashDialoguePath);

			#if linux
			crashDialoguePath = "./" + crashDialoguePath;
			#end
			new sys.io.Process(crashDialoguePath, [path]);
		}
		else
		{
			// I had to do this or the stupid CI won't build :distress:
			displayAlert(mainInfo, titleMessage);
		}
		*/

		exit();
	}

	static function exit()
	{
		// Main.onCloseApplication();
		// Sys.exit(1);
		#if sys
		lime.system.System.exit(1);
		#end
	}

	static function displayAlert(mainInfo:String, titleMessage:String)
	{
		#if js
		js.Browser.alert(titleMessage + "\n" + mainInfo);
		#else
		lime.app.Application.current.window.alert(mainInfo, titleMessage);
		#end
	}

	static function buildFinalInfos()
	{
		var stackLabel = new StringBuf();
		stackLabel.add("\n");
		stackLabel.add(buildMessageStatus());
		stackLabel.add("\n");
		stackLabel.add(DIVIDER);
		stackLabel.add("\n");
		stackLabel.add(buildMessageHaxeLibs());
		if (DISPLAY_TRACES_HISTORY || END_MESSAGE.length > 0)
		{
			stackLabel.add("\n");
			stackLabel.add(DIVIDER);
		}
		if (DISPLAY_TRACES_HISTORY)
		{
			#if LOG_TRACES_ON_CRASH
			stackLabel.add("\n");

			stackLabel.add("Console:\n");
			stackLabel.add(TRACES_HISTORY.toString());
			#end
		}

		if (END_MESSAGE.length > 0)
		{
			stackLabel.add("\n");
			stackLabel.add(END_MESSAGE);
		}
		return stackLabel.toString();
	}

	static function buildMessage(e:UncaughtErrorEvent, stack:Array<StackItem>)
	{
		var stackLabel = new StringBuf();
		stackLabel.add("Uncaught Error: ");
		var m:String = null;
		var err:Error = e.error is Error ? cast e.error : null;
		if (err != null)
		{
			m = err.message;
		}
		else
		{
			var err:ErrorEvent =  e.error is ErrorEvent ? cast e.error : null;
			if (err != null)
				m = err.text;
			else
				m = Std.string(e.error);
		}
		stackLabel.add(m);
		stackLabel.add("\n");
		stackLabel.add("\n");

		for (stackItem in stack)
		{
			switch (stackItem)
			{
				case CFunction:
					stackLabel.add("\t- Non-Haxe (C) Function\n");
				case Module(c):
					stackLabel.add('\t- Module $c\n');
				case FilePos(parent, file, line, col):
					switch (parent)
					{
						case Method(cla, func):
							stackLabel.add('- ($file:$line) - ${cla.split(".").getLast()}.$func()\n');
						default:
							stackLabel.add('- $file:$line\n');
					}
				case LocalFunction(v):
					stackLabel.add('\t- Local Function $v\n');
				case Method(cl, m):
					stackLabel.add('\t- $cl - $m\n');
				default:
					stackLabel.add("\t");
					stackLabel.add(Std.string(stackItem));
					// Terminal.instance.println("\t" + stackItem);
			}
			// stackLabel.add('\n');
		}
		return stackLabel.toString();
	}
	static function buildMessageHaxeLibs():String
	{
		var stackLabel = new StringBuf();
		stackLabel.add("\nHaxe Libralies:");
		for (i in HaxeLibsMacro.libs)
		{
			stackLabel.add("\n");
			stackLabel.add(i.name); stackLabel.add(": "); stackLabel.add(i.directory.replace(",", "."));
			if (i.directory.contains("git") || i.directory == "mercurial")
			{
				stackLabel.add("(");
				stackLabel.add(i.url);
				stackLabel.add(")");
			}
		}
		return stackLabel.toString();
	}

	public static function threadSaveContentWithTime(path:String, text:String) {
		var dateNow:String = Date.now().toString().replace(" ", "_").replace(":", "'");
		threadSaveContent('$path$dateNow.log', text);
	}

	public static function saveContentWithTime(path:String, text:String) {
		var dateNow:String = Date.now().toString().replace(" ", "_").replace(":", "'");
		saveContent('$path$dateNow.log', text);
	}

	public static function threadSaveContent(path:String, text:String) {
		#if sys
		CoolUtil.execAsync(() -> {
			if (!FileSystem.exists(LOG_FOLDER))
				FileSystem.createDirectory(LOG_FOLDER);
			path = Path.join([LOG_FOLDER, path]);
			var dir = Path.directory(path);
			if (!FileSystem.exists(dir))
				FileSystem.createDirectory(dir);
			var f = sys.io.File.write(path, true);
			try
			{
				f.writeString(text);
			}
			catch (e)
			{
				Log(e, RED);
			}
			f.close();
			Terminal.instance.println("Crash dump saved in " + Path.normalize(path));
		});
		#end
	}

	public static function saveContent(path:String, text:String) {
		#if sys
		if (!FileSystem.exists(LOG_FOLDER))
			FileSystem.createDirectory(LOG_FOLDER);
		path = Path.join([LOG_FOLDER, path]);
		var dir = Path.directory(path);
		if (!FileSystem.exists(dir))
			FileSystem.createDirectory(dir);
		File.saveContent(path, text);
		Terminal.instance.println("Crash dump saved in " + Path.normalize(path));
		#end
	}

	static function buildMessageStatus():String
	{
		var stackLabel = new StringBuf();

		stackLabel.add("User: ");
		stackLabel.add(InfoAPI.userName);
		stackLabel.add("\nPlatform: ");
		stackLabel.add(InfoAPI.osInfo);

		var driverInfo = FlxG?.stage?.context3D?.driverInfo;
		if (driverInfo == null)
			stackLabel.add('\nDriver info: N/A');
		else
		{
			@:privateAccess
			var gl = FlxG.stage.context3D.gl;
			var vendor = gl.getParameter(gl.VENDOR);
			var version = gl.getParameter(gl.VERSION);
			var renderer = gl.getParameter(gl.RENDERER);
			var glslVersion = gl.getParameter(gl.SHADING_LANGUAGE_VERSION);
			stackLabel.add("\nDriver info:");
			stackLabel.add("\n  OpenGL Vendor: ");	stackLabel.add(vendor);
			stackLabel.add("\n  Version: ");		stackLabel.add(version);
			stackLabel.add("\n  Renderer: ");		stackLabel.add(renderer);
			stackLabel.add("\n  GLSL: ");			stackLabel.add(glslVersion);
		}

		stackLabel.add("\nFlixel Current State: ");
		if (FlxG.state != null)
		{
			stackLabel.add(FlxG.state != null ? Type.getClassName(Type.getClass(FlxG.state)) : "No state loaded");
		}

		stackLabel.add("\nGit hash: ");
		stackLabel.add(GitCommitMacro.hash);
		// stackLabel.add("(");
		// stackLabel.add(GitCommitMacro.hasLocalChanges ? "MODIFIED" : "CLEAN");
		// stackLabel.add(")");
		return stackLabel.toString();
	}
}