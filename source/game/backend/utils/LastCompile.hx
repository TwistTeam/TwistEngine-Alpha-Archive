package game.backend.utils;

class LastCompile{
	public static macro function getBuildTime(){
		#if display
		return macro $v{0};
		#else
		return macro $v{Date.now().getTime()};
		#end
    }
}
