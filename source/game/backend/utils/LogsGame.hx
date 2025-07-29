package game.backend.utils;

#if MUTEX_TRACES
import sys.thread.Mutex;
#end
import game.backend.utils.native.Windows;
import game.backend.utils.Terminal;
import game.backend.CrashHandler;

#if (cpp && windows)
@:cppFileCode("#include <windows.h>
#include <clocale>")
#end
class LogsGame
{
	public static var colorConsole(default, set):TColor = WHITE;
	#if MUTEX_TRACES
	static final _mutex:Mutex = new Mutex();
	#end

	public static inline function set_colorConsole(newVal:TColor):TColor
	{
		if (colorConsole != newVal)
			Terminal.instance.fg(colorConsole = newVal);
		return newVal;
	}

	public static inline function resetColors()
	{
		Terminal.instance.resetFg();
	}

	#if no_traces inline #end public static function Log(v:Dynamic, ?color:TColor, ?infos:haxe.PosInfos)
	{
		#if !no_traces
		if (color != null)
		{
			Terminal.instance.fg(color);
			traceCustom(v, infos);
			Terminal.instance.resetFg();
		}
		else
		{
			traceCustom(v, infos);
		}
		#end
	}

	public static function init()
	{
		#if !no_traces
		/*
			#if (cpp && windows)
			// Fix cyrillic chars in terminal?
			// untyped __cpp__('SetConsoleCP(1251); SetConsoleOutputCP(1251)');
			untyped __cpp__('setlocale(LC_ALL, "rus")');
			#end
		 */
		#if (cpp && windows)
		// Fix cyrillic chars in terminal?
		untyped __cpp__('SetConsoleOutputCP(CP_UTF8)');
		#end
		haxe.Log.trace = traceCustom;
		#end
	}

	static function formatOutput(message:Dynamic, ?filePos:haxe.PosInfos)
	{
		// final datanow = Date.now();
		// return '${filePos.fileName}:${filePos.lineNumber} [${datanow.getHours()}:${datanow.getMinutes()}:${datanow.getSeconds()}]: $message';
		if (filePos == null) return Std.string(message);
		var pstr = '${filePos.fileName}:${filePos.lineNumber} [${DateTools.format(Date.now(), "%T")}]: ${Std.string(message)}';
		if (filePos.customParams != null)
			for (v in filePos.customParams)
				pstr += ", " + Std.string(v);
		return pstr;
	}

	#if no_traces inline #end
	public static function traceCustom(v:Dynamic, ?info:haxe.PosInfos)
	{
		#if !no_traces

		v = formatOutput(v, info);

		#if MUTEX_TRACES
		_mutex.acquire();
		Terminal.instance.println(v);
		_mutex.release();
		#else
		Terminal.instance.println(v);
		#end

		addToTracesHistory(v + "\n");

		#end
	}

	#if !LOG_TRACES_ON_CRASH inline #end
	static function addToTracesHistory(output:String) {
		#if LOG_TRACES_ON_CRASH
		if (!CrashHandler.WRITE_TRACES_HISTORY)
			return;
		CrashHandler.TRACES_HISTORY.add(output);
		// Terminal.instance.println(CrashHandler.TRACES_HISTORY);
		#end
	}
}
