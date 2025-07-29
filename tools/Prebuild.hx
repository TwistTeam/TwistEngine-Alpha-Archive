package tools;

import sys.io.File;

class Prebuild
{
	inline public static final BUILD_TIME_FILE = "tools/.build_time";

	static function main():Void
	{
		final start = Sys.time();
		try
		{
			final file = File.write(BUILD_TIME_FILE);
			file.writeDouble(start);
			file.close();
		}
		catch (e) {}
	}
}