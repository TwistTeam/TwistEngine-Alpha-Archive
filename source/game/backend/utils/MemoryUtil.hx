package game.backend.utils;

#if cpp
import cpp.vm.Gc;
#elseif hl
import hl.Gc;
#elseif java
import java.vm.Gc;
#elseif neko
import neko.vm.Gc;
#end

#if windows
@:cppFileCode('
#include <windows.h>
#include <psapi.h>
')
#end
class MemoryUtil{
	#if windows

	// https://stackoverflow.com/questions/63166/how-to-determine-cpu-and-memory-consumption-from-inside-a-process
	// TODO: Adapt code for the other platforms. Wrote it for windows and html5 because they're the only ones I can test kek.
	@:functionCode('PROCESS_MEMORY_COUNTERS_EX pmc;
		if (GetProcessMemoryInfo(GetCurrentProcess(), (PROCESS_MEMORY_COUNTERS*)&pmc, sizeof(pmc))){
			int convertData = static_cast<int>(pmc.WorkingSetSize);
			return convertData;
		}else return 0;')
	static function getWindowsMemory():haxe.Int32 return 0;
	#end

	public static function getMemoryfromProcess():haxe.Int32
		#if windows
		return getWindowsMemory();
		#elseif html5
		return js.Syntax.code("window.performance.memory.usedJSHeapSize");
		#else
		return openfl.system.System.totalMemory;
		#end

	public static function clearMinor() {
		#if (cpp || java || neko)
		Gc.run(false);
		#end
	}

	public static function clearMajor() {
		#if cpp
		Gc.run(true);
		Gc.compact();
		#elseif hl
		Gc.major();
		#elseif (java || neko)
		Gc.run(true);
		#end
	}

	public static function enable() {
		#if (cpp || hl)
		Gc.enable(true);
		#end
	}

	public static function disable() {
		#if (cpp || hl)
		Gc.enable(false);
		#end
	}

}
