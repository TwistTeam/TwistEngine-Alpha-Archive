package game.objects;

import flixel.input.keyboard.FlxKey;

class ConsolePlugin extends FlxBasic // todo?
{
	public static var instance:ConsolePlugin;

	public var consoleKeys(default, set):Array<FlxKey> = [FlxKey.F8];
	public var enableToggleConsole:Bool = true;

	inline function set_consoleKeys(v:Array<FlxKey>):Array<FlxKey>
		return filterKeys(consoleKeys = v);

	@:noCompletion function filterKeys(keys:Array<FlxKey>):Array<FlxKey>
	{
		if (keys == null)
			keys = [];

		while (keys.remove(-1))
		{}
		return keys;
	}

	public override function new():Void
	{
		super();

		if (instance != null)
		{
			destroy();
			return;
		}

		instance = this;
	}

	public override function update(elapsed:Float)
	{
		if (enableToggleConsole && FlxG.keys.anyJustPressed(consoleKeys))
		{
		}
		super.update(elapsed);
	}

	public override function destroy()
	{
		if (instance == this)
			instance = null;

		if (FlxG.plugins.list.contains(this))
			FlxG.plugins.remove(this);

		super.destroy();
	}
}
