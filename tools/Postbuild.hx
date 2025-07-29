package tools;

import haxe.Log;
import sys.FileSystem;
import sys.io.File;
import tools.Prebuild;

class Postbuild
{
	static inline final ROUND_TO = 1000.0;

	static function main():Void
	{
		final end:Float = Sys.time();
		if (FileSystem.exists(Prebuild.BUILD_TIME_FILE))
		{
			final file = File.read(Prebuild.BUILD_TIME_FILE);
			final start:Float = file.readDouble();

			final completeTime = Math.round((end - start) * ROUND_TO) / ROUND_TO;
			Log.trace('Build complete in $completeTime seconds!', null);

			// cleanup
			file.close();
			FileSystem.deleteFile(Prebuild.BUILD_TIME_FILE);
		}
		else
		{
			Log.trace("Build complete!", null);
		}
	}
}