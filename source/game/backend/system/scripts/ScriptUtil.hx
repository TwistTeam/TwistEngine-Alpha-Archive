package game.backend.system.scripts;

enum abstract FunctionReturn(String) from String to String
{
	public final Function_Stop:FunctionReturn				= "##PSYCHLUA_FUNCTIONSTOP";
	public final Function_Continue:FunctionReturn			= "##PSYCHLUA_FUNCTIONCONTINUE";
	public final Function_StopLua:FunctionReturn			= "##PSYCHLUA_FUNCTIONSTOP_LUA";
	public final Function_StopHScript:FunctionReturn		= "##PSYCHLUA_FUNCTIONSTOP_HX";
	public final Function_StopAll:FunctionReturn			= "##PSYCHLUA_FUNCTIONSTOP_ALL";
}
class ScriptUtil
{
	public static final defineClasses:Map<String, Dynamic> = [
		'Main'							=> game.Main,

		'Conductor'						=> game.backend.system.song.Conductor.mainInstance,
		'Song'							=> game.backend.system.song.Song,
		// 'FunkinLua'						=> game.backend.system.scripts.FunkinLua,
		'ClientPrefs'					=> ClientPrefs,
		'Controls'						=> game.backend.utils.Controls,
		'Paths'							=> game.backend.system.Paths,
		'GameOverSubstate'				=> game.states.substates.GameOverSubstate,
		'PauseSubState'					=> game.states.substates.PauseSubState,
		'HealthIcon'					=> game.objects.game.HealthIcon,
		'Character'						=> game.objects.game.Character,
		'DiscordClient'					=> game.backend.system.net.Discord.DiscordClient,

		'backend.Conductor'				=> game.backend.system.song.Conductor.mainInstance,
		'backend.Song'					=> game.backend.system.song.Song,
		'backend.ClientPrefs'			=> ClientPrefs,
		'backend.Controls'				=> game.backend.utils.Controls,
		'backend.Paths'					=> game.backend.system.Paths,
		'backend.Discord.DiscordClient'	=> game.backend.system.net.Discord.DiscordClient,
		// 'psychlua.FunkinLua'			=> game.backend.system.scripts.FunkinLua,
		'substates.PauseSubState'		=> game.states.substates.PauseSubState,
		'substates.GameOverSubstate'	=> game.states.substates.GameOverSubstate,
		'objects.HealthIcon'			=> game.objects.game.HealthIcon,
		'objects.Character'				=> game.objects.game.Character,
	];
	public static final Function_Stop:FunctionReturn			= FunctionReturn.Function_Stop;
	public static final Function_Continue:FunctionReturn		= FunctionReturn.Function_Continue;
	public static final Function_StopLua:FunctionReturn			= FunctionReturn.Function_StopLua;
	public static final Function_StopHScript:FunctionReturn		= FunctionReturn.Function_StopHScript;
	public static final Function_StopAll:FunctionReturn			= FunctionReturn.Function_StopAll;
}