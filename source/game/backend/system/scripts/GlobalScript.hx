package game.backend.system.scripts;

#if GLOBAL_SCRIPT
import game.backend.utils.native.Windows;
/**
 * Class for THE Global Script, aka script that runs in the background at all times.
 */
class GlobalScript {
	public static var scripts:ScriptPack;

	public static function init()
	{
		#if MODS_ALLOWED
		ModsFolder.onModSwitch.add(onModSwitch);
		#end

		FlxG.signals.focusGained.add(call.bind("focusGained"));
		FlxG.signals.focusLost.add(call.bind("focusLost"));
		FlxG.signals.gameResized.add((w:Int, h:Int) ->			call("gameResized", [w, h]));
		FlxG.signals.postDraw.add(call.bind("postDraw"));
		FlxG.signals.postGameReset.add(call.bind("postGameReset"));
		FlxG.signals.postGameStart.add(call.bind("postGameStart"));
		FlxG.signals.postStateSwitch.add(call.bind("postStateSwitch"));
		FlxG.signals.postUpdate.add(() -> {
			call("postUpdate", [FlxG.elapsed]);
			/*
			if (FlxG.keys.justPressed.F5) {
				if (scripts.length > 0) {
					Log('Reloading global script...', YELLOW);
					scripts.reload();
					Log('Global script successfully reloaded.', GREEN);
				} else {
					Log('Loading global script...', YELLOW);
					onModSwitch(#if MODS_ALLOWED ModsFolder.currentModFolder #else null #end);
				}
			}
			*/
			// if (FlxG.keys.justPressed.F8) Windows.allocConsole();
		});
		FlxG.signals.preDraw.add(call.bind("preDraw"));
		FlxG.signals.preGameReset.add(call.bind("preGameReset"));
		FlxG.signals.preGameStart.add(call.bind("preGameStart"));
		FlxG.signals.preStateCreate.add((state:FlxState) ->		call("preStateCreate", [state]));
		FlxG.signals.preStateSwitch.add(call.bind("preStateSwitch"));
		FlxG.signals.preUpdate.add(() -> {
			call("preUpdate", [FlxG.elapsed]);
			// call("update", [FlxG.elapsed]);
		});

		onModSwitch(#if MODS_ALLOWED ModsFolder.currentModFolder #else null #end);
	}

	public static function call(name:String, ?args:Array<Dynamic>)
	{
		return scripts?.call(name, args);
	}

	public static function onModSwitch(newMod:String)
	{
		call("destroy");
		scripts = flixel.util.FlxDestroyUtil.destroy(scripts);
		final path = AssetsPaths.getPath('source/global.hx');
		if (Assets.exists(path))
		{
			scripts = new ScriptPack();
			scripts.loadHScript(path);
		}
	}

	public static function beatHit(curBeat:Int) {
		call("beatHit", [curBeat]);
	}

	public static function stepHit(curStep:Int) {
		call("stepHit", [curStep]);
	}
}
#end