package game.objects.game.notes;

import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxPoint;
import flixel.util.helpers.FlxBounds;
import flixel.util.FlxDestroyUtil;

class HoldCoverGroup extends FlxTypedGroup<NoteHoldCover> {

	public var allowReleaseSplash(get, default):Bool;
	public var allowSparks(get, default):Bool;

	public var defaultTexture(default, set):String;

	public var randAddedFPSOnRelease:FlxBounds<Int> = new FlxBounds(-3, 4);

	public var offset:FlxPoint = FlxPoint.get(4, 8);
	public var glowOffsets:FlxPoint = FlxPoint.get(0, 0);
	public var holdSparksOffsets:FlxPoint = FlxPoint.get(10, 0);
	public var releaseSparksOffsets:FlxPoint = FlxPoint.get(0, -15);

	public function new(allowReleaseSplash:Bool = true, allowSparks:Bool = true, ?defaultTexture:String)
	{
		super();
		this.allowReleaseSplash = allowReleaseSplash;
		this.allowSparks = allowSparks;
		@:bypassAccessor this.defaultTexture = defaultTexture ?? Constants.DEFAULT_NOTEHOLDCOVER_SKIN;
		recycle().kill(); // preload
	}
	public override function destroy()
	{
		super.destroy();
		offset = FlxDestroyUtil.put(offset);
		glowOffsets = FlxDestroyUtil.put(glowOffsets);
		holdSparksOffsets = FlxDestroyUtil.put(holdSparksOffsets);
		releaseSparksOffsets = FlxDestroyUtil.put(releaseSparksOffsets);
		randAddedFPSOnRelease = null;
	}
	public function spawnByNote(note:Note):Void
	{
		recycle().setupByNote(note);
	}

	public override function recycle(?objectClass:Class<NoteHoldCover>, ?objectFactory:Void->NoteHoldCover, force = false, revive = true)
	{
		return super.recycle(constructHoldCover, force, revive);
	}

	function constructHoldCover():NoteHoldCover
	{
		return new NoteHoldCover(this, Math.NEGATIVE_INFINITY, Math.NEGATIVE_INFINITY);
	}

	function get_allowReleaseSplash():Bool
	{
		return allowReleaseSplash && ClientPrefs.holdCoversRelease;
	}

	function get_allowSparks():Bool
	{
		return allowSparks && ClientPrefs.holdSparks;
	}

	function set_defaultTexture(newTex:String):String
	{
		newTex ??= Constants.DEFAULT_NOTEHOLDCOVER_SKIN;
		if (defaultTexture != newTex)
		{
			defaultTexture = newTex;
			forEachDead(i -> i.loadAnims(newTex));
		}
		return defaultTexture;
	}
}