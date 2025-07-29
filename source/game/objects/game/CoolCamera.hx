package game.objects.game;

import flixel.tweens.FlxTween;
import openfl.filters.BitmapFilter;

class CoolCamera extends game.objects.improvedFlixel.FlxCamera
{
	public var defaultZoom:Float = 1.;

	// Grab from Hopka Notes, but made better
	public var tweeningZoom(get, never):Bool;
	inline function get_tweeningZoom():Bool return checkTweening('zoom');

	public var tweeningX(get, never):Bool;
	inline function get_tweeningX():Bool return checkTweening('x');
	public var tweeningY(get, never):Bool;
	inline function get_tweeningY():Bool return checkTweening('y');

	function checkTweening(field:String){
		/*
		@:privateAccess
		{
			var i = FlxTween.globalManager._tweens.length;
			var tween:FlxTween;
			while (i-- > 1){
				tween = FlxTween.globalManager._tweens[i];
				if (tween.isTweenOf(this, field))
					return true;
			}
		}
		*/
		return false;
	}

	public function new(?BGAlpha:Float = 1.0, ?Zoom:Float = 1):Void{
		super(0, 0, 0, 0, Zoom);
		bgColor.alphaFloat = BGAlpha;
	}

	public var baseFilters:Array<BitmapFilter> = [];
	public var trackedShaders:Array<String> = [];
	public var extraFilters:Array<BitmapFilter> = [];

	public override function setFilters(filters:Array<BitmapFilter>):Void{
		extraFilters = filters;
		updateFilters();
	}

	public function updateFilters() _filters = baseFilters.concat(extraFilters); // array + array
}