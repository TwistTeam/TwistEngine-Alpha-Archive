package game.objects.ui;

import game.backend.system.CursorManager;
import lime.ui.KeyModifier;
import lime.ui.KeyCode;

class UIState extends flixel.FlxState /*game.backend.system.states.MusicBeatState*/ {
	public static var instance(get, never):UIState;
	@:noCompletion static function get_instance():UIState return FlxG.state is UIState ? cast FlxG.state : null;
	public var currentFocus(default, set):IUIFocusable = null;
	inline function set_currentFocus(e) {
		if (currentFocus != e){
			currentFocus = e;
			FlxG.sound.keysAllowed = currentFocus == null || !(currentFocus is FlxInputText);
		}
		return e;
	}
	public override function create() {
		super.create();
		FlxG.stage.window.onKeyDown.add(onKeyDown);
		FlxG.stage.window.onKeyUp.add(onKeyUp);
		FlxG.stage.window.onTextInput.add(onTextInput);
		FlxG.stage.window.onTextEdit.add(onTextEdit);
	}
	function onKeyDown(e:KeyCode, modifier:KeyModifier) {
		if (currentFocus != null)
			currentFocus.onKeyDown(e, modifier);
	}

	function onKeyUp(e:KeyCode, modifier:KeyModifier) {
		if (currentFocus != null)
			currentFocus.onKeyUp(e, modifier);
	}

	function onTextInput(str:String) {
		if (currentFocus != null)
			currentFocus.onTextInput(str);
	}

	private function onTextEdit(str:String, start:Int, end:Int) {
		if (currentFocus != null)
			currentFocus.onTextEdit(str, start, end);
	}

	public override function destroy() {
		super.destroy();
		FlxG.stage.window.onKeyDown.remove(onKeyDown);
		FlxG.stage.window.onKeyUp.remove(onKeyUp);
		FlxG.stage.window.onTextInput.remove(onTextInput);
		FlxG.stage.window.onTextEdit.remove(onTextEdit);
	}

	public override function tryUpdate(e){
		CursorManager.instance.cursor = null;
		super.tryUpdate(e);
	}
	// public function new() {
	//     instance = this;
	//     super(false);
	// }
	// public override function destroy(){
	//     super.destroy();
	//     instance = null;
	// }
}