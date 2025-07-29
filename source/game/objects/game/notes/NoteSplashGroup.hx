package game.objects.game.notes;

import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxPoint;
import flixel.util.helpers.FlxBounds;
import flixel.util.FlxDestroyUtil;

class NoteSplashGroup extends FlxTypedGroup<NoteSplash> {

	public var defaultTexture(default, set):String;

	public var randAddedFPS:FlxBounds<Int> = new FlxBounds(-3, 4);

	public var maxRandomAngle:Int = 0;

	public var offset:FlxPoint = FlxPoint.get(0, 10);

	public function new(?defaultTexture:String)
	{
		super();
		@:bypassAccessor this.defaultTexture = defaultTexture ?? Constants.DEFAULT_NOTESPLASH_SKIN;
		recycle().kill(); // preload
	}
	public override function destroy()
	{
		super.destroy();
		offset = FlxDestroyUtil.put(offset);
		randAddedFPS = null;
	}
	public function spawn(strum:StrumNote, data:Int, ?note:Note)
	{
		recycle().setupNoteSplash(strum.x + strum.width / 2, strum.y + strum.height / 2, data, note?.noteSplashTexture, note);
	}

	public override function recycle(?objectClass:Class<NoteSplash>, ?objectFactory:Void->NoteSplash, force = false, revive = true)
	{
		return super.recycle(constructNoteSplash, force, revive);
	}

	function constructNoteSplash():NoteSplash
	{
		return new NoteSplash(Math.NEGATIVE_INFINITY, Math.NEGATIVE_INFINITY, 0, this);
	}

	function set_defaultTexture(newTex:String):String
	{
		newTex ??= Constants.DEFAULT_NOTESPLASH_SKIN;
		if (defaultTexture != newTex)
		{
			defaultTexture = newTex;
			forEachDead(i -> i.loadAnims(newTex));
		}
		return defaultTexture;
	}
}