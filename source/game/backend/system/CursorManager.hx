package game.backend.system;

import haxe.extern.EitherType;
import openfl.ui.Mouse;
import openfl.ui.MouseCursor as OpenFLMouseCursor;
import lime.app.Application;
import lime.ui.MouseCursor as LimeMouseCursor;
import flixel.FlxCamera;

typedef MouseCursor = EitherType<OpenFLMouseCursor, LimeMouseCursor>;

@:access(openfl.ui.Mouse)
class CursorManager extends FlxBasic
{
	public static var instance(get, null):CursorManager;
	public static function get_instance():CursorManager{
		if (instance != null && !instance.alive) instance.revive();
		return instance;
	}

	extern public static inline function init()
	{
		instance = new CursorManager();
		FlxG.signals.preStateSwitch.add(() -> @:bypassAccessor if (instance != null) instance.kill());
	}

	public var cursor:Null<MouseCursor> = null;
	var _lastCursor:MouseCursor;
	var _setCursor:LimeMouseCursor;
	public var defaultCursor:MouseCursor = DEFAULT;

	public function new(?defaultCursor:MouseCursor = DEFAULT)
	{
		super();
		this.defaultCursor = defaultCursor;
		FlxG.signals.postDraw.add(updateMouse);
	}

	override function destroy()
	{
		FlxG.signals.postDraw.remove(updateMouse);
		super.destroy();
	}

	public override function revive()
	{
		super.revive();
		this.defaultCursor = DEFAULT;
		cursor = null;
	}

	public override function kill()
	{
		super.kill();
		defaultCursor = DEFAULT;
		cursor = null;
	}

	override function update(elapsed) {}

	override function draw() {}

	function updateMouse()
	{
		#if !hl
		if (active && alive){
			var newCursor = cursor ?? defaultCursor;

			if (_lastCursor != newCursor)
			{
				Mouse.__cursor = _setCursor = _lastCursor = newCursor;
				// trace([_setCursor, !Mouse.__hidden, Application.current.windows.length]);
				if (!Mouse.__hidden)
					for (window in Application.current.windows)
						window.cursor = _setCursor;
			}
		}
		#end
	}

	@:deprecated("don't reference camera.camera")
	@:noCompletion
	override function get_camera():FlxCamera
		throw "don't reference camera.camera";

	@:deprecated("don't reference camera.camera")
	@:noCompletion
	override function set_camera(Value:FlxCamera):FlxCamera
		throw "don't reference camera.camera";

	@:deprecated("don't reference camera.cameras")
	@:noCompletion
	override function get_cameras():Array<FlxCamera>
		throw "don't reference camera.cameras";

	@:deprecated("don't reference camera.cameras")
	@:noCompletion
	override function set_cameras(Value:Array<FlxCamera>):Array<FlxCamera>
		throw "don't reference camera.cameras";
}
