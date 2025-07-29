package game.objects.transitions;

import flixel.addons.transition.FlxTransitionableState;
import hscript.HScriptedClass;

class StateTransition extends openfl.display.Sprite
{
	/** TRANS RIGHTS!!!! Uniform transition time. **/
	public static var transTime:Float = 0.35;
	public static var finishCallback:() -> Void;

	public var active(default, null):Bool;
	public var isUsing:Bool;
	public var isTransIn:Bool;

	var _time:Float;
	var _duration:Float;
	var _startPos:Float;
	var _targetPos:Float;
	var _onComplete:() -> Void;

	// singleton yaaaaaaayy
	@:allow(game.objects.TransitionsGroup) function new(group:TransitionsGroup)
	{
		super();
		visible = false;

		FlxG.signals.preUpdate.add(update);
		FlxG.signals.gameResized.add(onResize);
		FlxG.signals.postStateSwitch.add(onStateSwitched);
		group.addChild(this);
	}

	public function start(?onComplete:()->Void, duration:Float, isTransIn:Bool)
	{
		_onComplete = onComplete;
		_duration = Math.max(duration, FlxMath.EPSILON);
		_time = FlxTransitionableState.skipNextTransIn ? _duration : 0.0;

		active = true;
		visible = true;
		this.isTransIn = isTransIn;
		prepare(isTransIn);
	}

	function update()
	{
		if (active)
		{
			_time += FlxG.elapsed;
			if (_time < _duration) // move transition graphic
			{

			}
			else // finish transition
			{
				finish();
			}
		}
	}

	function prepare(isTransIn:Bool)
	{
		x = y = 0;
		scaleX = 1;
		scaleY = 1;
	}

	function finish()
	{
		active = false;
		if (_onComplete == null)
		{
			visible = false;
			scaleX = 1;
			scaleY = 1;
			x = y = 0;
		}
		else
		{
			if (active)
			{
				if (_onComplete != null)
				{
					_onComplete();
					_onComplete = null;
				}
				if (StateTransition.finishCallback != null)
				{
					StateTransition.finishCallback();
					StateTransition.finishCallback = null;
				}
			}
		}
	}

	function onResize(_, _)
	{
		if (active)
		{
			prepare(_startPos > 0);
		}
	}

	function onStateSwitched()
	{
		if (visible)
		{
			if (FlxTransitionableState.skipNextTransOut)
			{
				visible = false;
				FlxTransitionableState.skipNextTransOut = false;
			}
			else
			{
				start(0, true);
			}
		}
	}
}