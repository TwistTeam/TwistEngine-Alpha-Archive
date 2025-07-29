package game.objects.transitions;

import flixel.addons.transition.FlxTransitionableState;
import flixel.group.FlxGroup;
import flixel.tweens.FlxEase.EaseFunction;
import flixel.tweens.FlxEase;
import openfl.display.Bitmap;

class VanilaTransition extends StateTransition
{
	public var ease:EaseFunction;
	public var bitmapGradient:Bitmap;

	// singleton yaaaaaaayy
	@:allow(game.objects.transitions.TransitionsGroup)
	function new(group:TransitionsGroup)
	{
		super(group);
		addChild(bitmapGradient = new Bitmap(
			flixel.util.FlxGradient.createGradientBitmapData(1, FlxG.height * 2, [FlxColor.BLACK, FlxColor.BLACK, FlxColor.TRANSPARENT])
		));
	}

	public override function start(?onComplete:()->Void, duration:Float, isTransIn:Bool)
	{
		_onComplete = onComplete;
		_duration = Math.max(duration, FlxMath.EPSILON);
		_time = FlxTransitionableState.skipNextTransIn ? _duration : 0.0;

		active = true;
		visible = true;
		bitmapGradient.smoothing = ClientPrefs.globalAntialiasing;
		this.isTransIn = isTransIn;
		prepare(isTransIn);
		y = _startPos; // to avoid visual bugs
	}

	override function update()
	{
		if (visible)
		{
			_time += FlxG.elapsed;
			if (_time < _duration) // move transition graphic
			{
				ease ??= FlxEase.linear;

				y = FlxMath.lerp(_startPos, _targetPos, ease(_time / _duration));
			}
			else // finish transition
			{
				y = _targetPos;
				finish();
			}
		}
	}

	override function prepare(isTransIn:Bool)
	{
		x = -FlxG.scaleMode.offset.x;
		scaleX = FlxG.scaleMode.gameSize.x + FlxG.scaleMode.offset.x * 2;
		final height = FlxG.scaleMode.gameSize.y + FlxG.scaleMode.offset.y * 2;
		if (isTransIn)
		{
			scaleY = -FlxG.scaleMode.scale.y;
			_startPos = height;
			_targetPos = height * 3.0;
		}
		else
		{
			scaleY = FlxG.scaleMode.scale.y;
			_startPos = -height * 2.0;
			_targetPos = 0.0;
		}
	}

	override function finish()
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

	override function onStateSwitched()
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
				start(StateTransition.transTime * 1.1, true);
			}
		}
	}
}
