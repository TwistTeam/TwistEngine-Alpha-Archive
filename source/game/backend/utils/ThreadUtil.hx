package game.backend.utils;

import game.backend.system.InfoAPI;
#if target.threaded
import sys.thread.ElasticThreadPool;
import sys.thread.Mutex;
import sys.thread.Thread;
#end

#if MULTI_THREADING_ALLOWED
typedef LoadingThreadMessage =
{
	var thread:Thread;
	var ?terminate:Null<Bool>;
}
#end

typedef ThreadParams = {
	var thread:#if target.threaded Thread #else Dynamic #end;
	var isPaused:Bool;
	var isDestroyed:Bool;
}
#if target.threaded
#if cpp
@:cppFileCode("
#ifndef INCLUDED_sys_thread__Thread_HaxeThread
#include <sys/thread/_Thread/HaxeThread.h>
#endif
")
#end
#end
class ThreadUtil
{
	public static final threadLimit:Int = {
		var result:Null<String> = null;
		#if MULTI_THREADING_ALLOWED

		#if windows
		result = Sys.getEnv("NUMBER_OF_PROCESSORS");
		#elseif linux
		result = InfoAPI.runProccess("nproc");

		if (result == null) {
			var cpuinfo = InfoAPI.runProccess("cat /proc/cpuinfo");

			if (cpuinfo != null) {
				var split = cpuinfo.split("processor");
				result = Std.string(split.length - 1);
			}
		}
		#elseif mac
		var cores = ~/Total Number of Cores: (\d+)/;
		var output = InfoAPI.runProccess("/usr/sbin/system_profiler -detailLevel full SPHardwareDataType");

		if (cores.match(output))
			result = cores.matched(1);
		#end

		#end
		if (result == null)
		{
			1;
		}
		else
		{
			var n:Int = Std.parseInt(result);
			trace(n);
			n.getDefault(1);
		}
	}

	public static var threadCount(get, never):Int;
	@:access(sys.thread)
	static function get_threadCount() // я объёбыш - Redar
	{
		// TODO: Support for other platforms?
		return #if target.threaded
			#if cpp
				untyped __cpp__("::sys::thread::_Thread::HaxeThread_obj::threads->length");
			#else
				0;
			#end
		#else
			0;
		#end
	}

	public static var threadPool:#if target.threaded ElasticThreadPool #else Dynamic #end;

	public static function create(job:() -> Void)
	{
		#if target.threaded
		threadPool ??= new ElasticThreadPool(threadLimit, 360); // timeout = 5 minutes
		if (job != null)
			#if MULTI_THREADING_ALLOWED
			if (ClientPrefs.multiThreading)
				threadPool.run(job);
			else
			#end
		#end job();
	}

	public static function load(job:() -> Void, ?multicoreOnly:Bool)
	{
		if (job == null) return;
		// var startTime = Sys.time();

		#if MULTI_THREADING_ALLOWED
		if (ClientPrefs.multiThreading)
		{
			////
			final mainThread = Thread.current();
			var thread = Thread.create(_loadingThreadFunc.bind(mainThread));
			thread.sendMessage(job);

			var msg:LoadingThreadMessage;
			while (true)
			{
				msg = Thread.readMessage(true);
				// trace(msg);

				if (msg.terminate != true) // kys
				{
					msg.thread.sendMessage(false);
				}
				else // the end
				{
					break;
				}
			}
		}
		else
		#end
		if (!multicoreOnly)
		{
			job();
		}

		// trace('finished loading in ${Sys.time() - startTime} seconds.');
	}
	public static function loadWithList(shitToLoad:Array<() -> Void>, ?multicoreOnly:Bool):Void
	{
		// var startTime = Sys.time();

		#if MULTI_THREADING_ALLOWED
		final threadLimit:Int = FlxMath.minInt(threadLimit, shitToLoad.length);

		if (ClientPrefs.multiThreading && threadLimit > 1)
		{
			////
			final mainThread = Thread.current();
			final makeThread = Thread.create.bind(_loadingThreadFunc.bind(mainThread));

			if (shitToLoad.length > 1)
				trace('Loading ${shitToLoad.length} items with $threadLimit threads.');

			var threadArray:Array<Thread> = [
				for (i in 0...threadLimit)
				{
					var thread = makeThread();
					thread.sendMessage(shitToLoad.pop());
					thread;
				}
			];

			var msg:LoadingThreadMessage;
			while (true)
			{
				msg = Thread.readMessage(true);
				// trace(msg);

				if (shitToLoad.length > 0) // send more shit
				{
					msg.thread.sendMessage(shitToLoad.pop());
					// trace('shit left: ${shitToLoad.length}');
				}
				else if (msg.terminate != true) // kys
				{
					msg.thread.sendMessage(false);
				}
				else // the end
				{
					threadArray.remove(msg.thread);
					// trace('thread terminated, ${threadArray.length} left.');
					if (threadArray.length < 1)
						break;
				}
			}
		}
		else
		#end
		if (!multicoreOnly)
		{
			// trace('Loading ${shitToLoad.length} items.');
			for (shit in shitToLoad)
				shit();
		}

		// trace('finished loading in ${Sys.time() - startTime} seconds.');
	}

	#if MULTI_THREADING_ALLOWED
	private static function _loadingThreadFunc(mainThread:Thread)
	{
		var thisThread = Thread.current();

		while (true)
		{
			var msg:Dynamic = Thread.readMessage(true);

			/*
				if (msg == null)
					continue;
			 */

			if (msg == false) // time to die
			{
				mainThread.sendMessage({
					thread: thisThread,
					terminate: true
				});
				break;
			}

			create(msg); // run job

			mainThread.sendMessage({thread: thisThread, terminate: false});
		}
	}
	#end


	#if target.threaded
	/**
	 * Data regarding every looping Thread.
	 */
	public static var loopingThreads:Map<String, ThreadParams> = [];
	public static var mutex:Mutex = new Mutex();
	#end

	/**
	 * Creates a Thread that starts after a set time.
	 * @param job The function to execute after the delay.
	 * @param delay The delay itself.
	 */
	public static function createDelayedThread(job:Void->Void, delay:Float = 1.0)
	{
		#if target.threaded
		return Thread.create(function()
		{
			Sys.sleep(delay);

			job();
		});
		#else
		// throw "Threads aren't supported on this device.";
		return null;
		#end
	}

	/**
	 * Creates a Thread that loops infinitely until destroyed.
	 * @param id The ID of the Thread, used for pausing, resuming and stopping.
	 * @param job The function to execute.
	 * @param startDelay The delay before the loop begins.
	 * @param loopDelay The delay between every loop.
	 */
	public static function createLoopingThread(id:String, job:Void->Void, startDelay:Float = 1.0, loopDelay:Float = 0.0)
	{
		#if target.threaded
		var threadInfo:ThreadParams = {thread: null, isPaused: false, isDestroyed: false}
		mutex.acquire();
		while(loopingThreads.exists(id))
		{
			id += "_";
		}
		loopingThreads.set(id, threadInfo);
		mutex.release();

		var thread:Thread = Thread.create(function()
		{
			Sys.sleep(startDelay);

			while (!threadInfo.isDestroyed)
			{
				if (threadInfo.isPaused)
					continue;

				job();

				Sys.sleep(loopDelay);
			}

			// Clean-up.
			if (threadInfo.isDestroyed)
			{
				threadInfo.thread = null;
				mutex.acquire();
				loopingThreads.remove(id);
				mutex.release();
			}
		});

		threadInfo.thread = thread;
		return threadInfo;
		#else
		// throw "Threads aren't supported on this device.";
		return null;
		#end
	}

	/**
	 * Pauses a looping Thread.
	 * @param id The ID of the Thread to pause.
	 */
	public static function pauseThread(id:String)
	{
		#if target.threaded
		forEachThreadsByID(id, i -> i.isPaused = true);
		#else
		// throw "Threads aren't supported on this device.";
		#end
	}

	/**
	 * Resumes a looping Thread.
	 * @param id The ID of the Thread to resume.
	 */
	public static function resumeThread(id:String)
	{
		#if target.threaded
		forEachThreadsByID(id, i -> i.isPaused = false);
		#else
		// throw "Threads aren't supported on this device.";
		#end
	}

	/**
	 * Stops a looping Thread and destroys it afterwards.
	 * @param id The ID of the Thread to stop and destroy.
	 */
	public static function stopThread(id:String)
	{
		#if target.threaded
		forEachThreadsByID(id, i -> i.isDestroyed = true);
		#else
		// throw "Threads aren't supported on this device.";
		#end
	}


	#if target.threaded
	static function forEachThreadsByID(id:String, job:ThreadParams -> Void)
	{
		mutex.acquire();
		for (i => info in loopingThreads)
		{
			if (i.startsWith(id))
			{
				job(info);
			}
		}
		mutex.release();
	}
	#end
}
