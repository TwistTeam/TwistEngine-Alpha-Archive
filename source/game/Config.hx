package game;

// idk
class Config {
	public static final gameSizes:Array<Int> = [1280, 720];
	public static final skipSplash:Bool = true; // if the default flixel splash screen should be skipped
	public static final startFullscreen:Bool = false; // if the game should start at fullscreen mode
	public static final discordConfig:game.backend.system.net.Discord.DiscordJson = {
		clientID: "1197647927854759957",
		largeImageKey: "defaultlogo",
		largeImageText: "Twist Engine <ENGINE-VERSION>"
	}
}