package game.backend.data;

import thx.semver.Version;

@:final class EngineData
{
	public static final psychVersion:Version = '0.6.3';
	public static final engineVersion:String = 'Alpha';
	public static final modVersion:Version = '0.0.1';
	public static final lastCompileData:Date = Date.fromTime(game.backend.utils.LastCompile.getBuildTime());
	public static final lastCompile:String = DateTools.format(lastCompileData, "%Y-%m-%d %H:%M:%S");
}
