package game.objects.ui;

import lime.ui.KeyModifier;
import lime.ui.KeyCode;

interface IUIFocusable {
	function onKeyDown(e:KeyCode, modifier:KeyModifier):Void;
	function onKeyUp(e:KeyCode, modifier:KeyModifier):Void;
	function onTextInput(text:String):Void;
	function onTextEdit(str:String, start:Int, end:Int):Void;
}