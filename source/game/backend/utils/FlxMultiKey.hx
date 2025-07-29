package game.backend.utils;

import flixel.input.gamepad.FlxGamepadInputID;
import flixel.input.gamepad.FlxGamepad;
import flixel.input.keyboard.FlxKey;
import flixel.util.FlxDestroyUtil;

/**
 * Makes it easier to check if, say, SHIFT+Tab is being pressed rather than just Tab by itself
 */
class FlxMultiKey implements IFlxDestroyable
{
	/**
	 * The code for the main input itself, ie, tab, or the A button
	 */
	public var input:Int;

	/**
	 * Any other inputs that must be pressed at the same time, ie, shift, alt, etc
	 */
	public var combos:Array<Int>;

	/**
	 * Any other inputs, that if pressed at the same time, forbid the press.
	 * (Forbidden is useful so you can distinguish a "TAB" from a "SHIFT+TAB"
	 * -- you add "SHIFT" to the first one's forbidden list)
	 */
	public var forbiddens:Array<Int>;

	public function new(Input:FlxKey, ?Combos:Array<FlxKey>, ?Forbiddens:Array<FlxKey>)
	{
		input = Input;
		combos = Combos;
		forbiddens = Forbiddens;
	}

	public function destroy():Void
	{
		combos = null;
		forbiddens = null;
	}

	#if FLX_KEYBOARD
	private function checkJustPressed():Bool
	{
		return FlxG.keys.checkStatus(input, JUST_PRESSED);
	}

	private function checkJustReleased():Bool
	{
		return FlxG.keys.checkStatus(input, JUST_RELEASED);
	}

	private function checkPressed():Bool
	{
		return FlxG.keys.checkStatus(input, PRESSED);
	}

	private function checkCombos(value:Bool):Bool
	{
		return FlxG.keys.anyPressed(combos) == value;
	}

	private function checkForbiddens(value:Bool):Bool
	{
		return FlxG.keys.anyPressed(forbiddens) == value;
	}
	#end

	/**
	 * Was the main key JUST pressed, AND are all of the combo keys currently pressed? (and none of the forbiddens?)
	 */
	public function justPressed():Bool
	{
		return checkJustPressed() && passCombosAndForbiddens();
	}

	/**
	 * Was the main key JUST released, AND are no forbidden keys currently pressed? (Ignore whether combos were just released)
	 */
	public function justReleased():Bool
	{
		return checkJustReleased() && ((forbiddens == null) || (checkForbiddens(false)));
	}

	/**
	 * Is the main key and all of the combo keys currently pressed? (and none of the forbiddens?)
	 */
	public function pressed():Bool
	{
		return checkPressed() && passCombosAndForbiddens();
	}

	public function equals(other:FlxMultiKey):Bool
	{
		if (other == null)
		{
			return false;
		}
		if (Type.typeof(other) != Type.typeof(this))
		{
			return false;
		}
		if (input != other.input)
		{
			return false;
		}
		if ((combos == null) != (other.combos == null))
		{
			return false;
		}
		if ((forbiddens == null) != (other.forbiddens == null))
		{
			return false;
		}
		if (combos != null && other.combos != null)
		{
			for (i in combos)
			{
				if (other.combos.indexOf(i) == -1)
				{
					return false;
				}
			}
		}
		if (forbiddens != null && other.forbiddens != null)
		{
			for (i in forbiddens)
			{
				if (other.forbiddens.indexOf(i) == -1)
				{
					return false;
				}
			}
		}
		return true;
	}

	/**
	 * Check Combo/Forbidden values. Default--are combos all pressed, AND are forbiddens all NOT pressed?
	 */
	private function passCombosAndForbiddens(comboValue:Bool = true, forbiddenValue:Bool = false):Bool
	{
		// Pass if combos don't exist, or if ALL of them match the specified boolean value
		var passCombos = (combos == null) || checkCombos(comboValue);
		// Pass if forbiddens don't exist, or if ALL of them match the specified boolean value
		var passForbiddens = (forbiddens == null) || checkForbiddens(forbiddenValue);

		// All must pass!
		return passCombos && passForbiddens;
	}
}
