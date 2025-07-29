package game.backend.system.macros;

#if (!display && macro)
import sys.io.Process;
import sys.thread.*;
import eval.vm.NativeThread;
#end

// from codename engine (https://github.com/FNF-CNE-Devs/CodenameEngine/blob/main/source/funkin/backend/system/macros/GitCommitMacro.hx)
class GitCommitMacro
{
	public static var number(get, never):Int;
	public static var hash(get, never):String;
	// public static var hasLocalChanges(get, never):Bool; // TODO: Find an alternate git command

	@:noCompletion static inline function get_number():Int
		return __getCommitNumber();

	@:noCompletion static inline function get_hash():String
		return __getCommitHash();

	// @:noCompletion static inline function get_hasLocalChanges():Bool
	// 	return _getGitHasLocalChanges();

	// INTERNAL MACROS
	static macro function __getCommitHash()
	{
		#if !display
		try
		{
			return macro $v{runProcess("git", ["rev-parse", "--short", "HEAD"])};
		}
		catch(e) {
			if (e != null)
				trace(Std.string(e));
		}
		#end
		return macro $v{"-"}
	}

	static macro function __getCommitNumber()
	{
		#if !display
		try
		{
			return macro $v{Std.parseInt(runProcess("git", ["rev-list", "HEAD", "--count"]))};
		}
		catch(e) {
			if (e != null)
				trace(Std.string(e));
		}
		#end
		return macro $v{0}
	}

	/*
	static macro function _getGitHasLocalChanges()
	{
		#if !display
		try
		{
			return macro $v{runProcess("git", ["status", "--porcelain"]).length > 0};
		}
		catch(e) {
			if (e != null)
				trace(Std.string(e));
		}
		#end
		return macro $v{true};
	}
	*/
	#if (!display && macro)
	static var gitIsValid:Null<Bool> = null;
	static function runProcess(cmd:String, ?args:Array<String>):String
	{
		var proc:Process;
		var result:String;

		if (gitIsValid == null)
		{
			proc = new Process("git", false);
			proc.exitCode(true);
			result = try proc.stdout.readLine() catch(e) null;
			proc.kill();
			gitIsValid = result != null && result.length > 0;
			if (!gitIsValid)
			{
				throw "\x1B[91mINVALID GIT\x1B[0m";
			}
		}
		else if (!gitIsValid)
		{
			throw null;
		}

		proc = new Process(cmd, args, false);
		proc.exitCode(true);
		var result:String = proc.stdout.readLine();
		proc.kill();
		return result;
	}
	/*
	static function closeProcess(proc:Process, ?id:String, ?timeout:Float = 15):Void
	{
		var successfully:Bool = false;
		var lock = new Lock();
		var thread = new NativeThread(() -> {
			proc.exitCode(true);
			successfully = true;
			lock.release();
		});
		NativeThread.join(thread);
		lock.wait(timeout);
		thread.kill();
		if (successfully)
		{
			if (id != null)
			{
				trace('The \'$id\' process ended successfully');
			}
		}
		else
		{
			if (id != null)
			{
				trace('The \'$id\' process is not responding');
			}
		}
	}
	*/
	#end
}