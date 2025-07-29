package flixel;

import flixel.system.FlxBGSprite;
import flixel.util.FlxColor;
import flixel.util.FlxDestroyUtil;

/**
 * A `FlxSubState` can be opened inside of a `FlxState`.
 * By default, it also stops the parent state from updating,
 * making it convenient for pause screens or menus.
 *
 * @see [FlxSubstate snippet](https://snippets.haxeflixel.com/states/flxsubstate/)
 * @see [Substate demo](https://haxeflixel.com/demos/SubState/)
 */
class FlxSubState extends FlxState
{
	/**
	 * Callback method for state open/resume event.
	 * @since 4.3.0
	 */
	public var openCallback:Void->Void;

	/**
	 * Callback method for state close event.
	 */
	public var closeCallback:Void->Void;

	/**
	 * Helper sprite object for non-flash targets. Draws the background.
	 */
	@:noCompletion
	var _bgSprite:FlxBGSprite;

	/**
	 * Helper var for `close()` so `closeSubState()` can be called on the parent.
	 */
	@:allow(flixel.FlxState.resetSubState)
	var _parentState:FlxState;

	@:noCompletion
	var _bgColor:FlxColor;

	@:noCompletion
	@:allow(flixel.FlxState.resetSubState)
	var _created:Bool = false;

	/**
	 * @param   BGColor   background color for this substate
	 */
	public function new(BGColor:FlxColor = FlxColor.TRANSPARENT)
	{
		super();
		closeCallback = null;
		openCallback = null;

		if (FlxG.renderTile)
			_bgSprite = new FlxBGSprite();
		bgColor = BGColor;
	}

	public override function draw():Void
	{
		// Draw background
		if (FlxG.renderBlit)
		{
			for (camera in cameras)
			{
				camera.fill(bgColor);
			}
		}
		else
		{
			if (_bgSprite != null && _bgSprite.visible)
				_bgSprite.draw();
		}

		// Now draw all children
		super.draw();
	}

	public override function destroy():Void
	{
		super.destroy();
		closeCallback = null;
		openCallback = null;
		_parentState = null;
		_bgSprite = FlxDestroyUtil.destroy(_bgSprite);
	}

	/**
	 * Closes this substate.
	 */
	public function close():Void
	{
		if (_parentState != null && _parentState.subState == this)
			_parentState.closeSubState();
	}

	@:noCompletion
	override inline function get_bgColor():FlxColor
	{
		return _bgColor;
	}

	@:noCompletion
	override function set_bgColor(Value:FlxColor):FlxColor
	{
		if (FlxG.renderTile && _bgSprite != null)
		{
			_bgSprite.alpha = Value.alphaFloat;
			_bgSprite.visible = _bgSprite.alpha > 0;
			_bgSprite.color = Value.rgb;
		}

		return _bgColor = Value;
	}
}
