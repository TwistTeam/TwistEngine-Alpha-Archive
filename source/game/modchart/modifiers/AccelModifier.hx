package game.modchart.modifiers;

class AccelModifier extends NoteModifier
{ // this'll be boost in ModManager
	inline function lerp(a:Float, b:Float, c:Float)
	{
		return a + (b - a) * c;
	}

	override function getName()
		return 'boost';

	override function getPos(time:Float, visualDiff:Float, timeDiff:Float, beat:Float, pos:Vector3, data:Int, player:Int, obj:INote)
	{
		var wave = getSubmodValue("wave", player);
		var brake = getSubmodValue("brake", player);
		var boost = getValue(player);
		var effectHeight = 500;

		var reverse:Dynamic = modMgr.register.get("reverse");
		var reversePercent:Float = reverse.getReverseValue(data, player);
		if (obj.getDownScroll())
			reversePercent = 1.0 - reversePercent;
		var mult = CoolUtil.scale(reversePercent, 0, 1, 1, -1);

		var yAdjust:Float = 0;
		if (brake != 0)
		{
			var off = visualDiff * CoolUtil.scale(visualDiff, 0, effectHeight, 0, 1) - visualDiff;
			yAdjust += CoolUtil.clamp(brake * off, -400, 400);
		}

		if (boost != 0)
		{
			// ((fYOffset+fEffectHeight/1.2f)/fEffectHeight);
			var off = visualDiff * 1.5 / ((visualDiff + effectHeight / 1.2) / effectHeight) - visualDiff;
			yAdjust += CoolUtil.clamp(boost * off, -400, 400);
		}

		yAdjust += wave * 20 * FlxMath.fastSin(visualDiff / 38);

		pos.y += yAdjust * mult;
		return pos;
	}

	override function getSubmods()
	{
		return ["brake", "wave"];
	}
}
