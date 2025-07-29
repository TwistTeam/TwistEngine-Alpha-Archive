package game.modchart.modifiers;

import game.modchart.Modifier.ModifierOrder;

class ScaleModifier extends NoteModifier
{
	static final dePi = Math.PI / 180;
	override function getName()
		return 'mini';

	override function getOrder()
		return PRE_REVERSE;

	extern static inline function lerp(a:Float, b:Float, c:Float)
	{
		return a + (b - a) * c;
	}

	function getScale(sprite:Dynamic, scale:FlxPoint, data:Int, player:Int)
	{
		// var y = scale.y;
		scale.x *= 1 - getValue(player);
		scale.y *= 1 - getValue(player);
		var miniX = getSubmodValue("miniX", player) + getSubmodValue('mini${data}X', player);
		var miniY = getSubmodValue("miniY", player) + getSubmodValue('mini${data}Y', player);

		scale.x *= 1 - miniX;
		scale.y *= 1 - miniY;
		var angle = 0;

		var stretch = getSubmodValue("stretch", player) + getSubmodValue('stretch${data}', player);
		var squish = getSubmodValue("squish", player) + getSubmodValue('squish${data}', player);

		var stretchX = lerp(1, 0.5, stretch);
		var stretchY = lerp(1, 2, stretch);

		var squishX = lerp(1, 2, squish);
		var squishY = lerp(1, 0.5, squish);

		scale.x *= Math.sin(angle * dePi) * squishY + Math.cos(angle * dePi) * squishX;
		scale.x *= Math.sin(angle * dePi) * stretchY + Math.cos(angle * dePi) * stretchX;

		scale.y *= Math.cos(angle * dePi) * stretchY + Math.sin(angle * dePi) * stretchX;
		scale.y *= Math.cos(angle * dePi) * squishY + Math.sin(angle * dePi) * squishX;
		// if ((sprite is Note) && sprite.isSustainNote)
		// 	scale.y = y;

		return scale;
	}

	override function shouldExecute(player:Int, val:Float)
		return true;

	override function ignorePos()
		return true;

	override function ignoreUpdateReceptor()
		return false;

	override function ignoreUpdateNote()
		return false;

	override function updateNote(beat:Float, note:Note, pos:Vector3, player:Int)
	{
		var scaleX = getSubmodValue("noteScaleX", player);
		var scaleY = getSubmodValue("noteScaleY", player);
		if (scaleX <= 0) scaleX = note.defScale.x;
		if (scaleY <= 0) scaleY = note.defScale.y;
		var newScale = getScale(note, FlxPoint.weak(scaleX, scaleY), note.noteData, player);

		if (note.isSustainNote)
			newScale.y = note.defScale.y;

		note.scale.copyFrom(newScale);
		newScale.putWeak();
	}

	override function updateReceptor(beat:Float, receptor:StrumNote, pos:Vector3, player:Int)
	{
		var scaleX = getSubmodValue("noteScaleX", player);
		var scaleY = getSubmodValue("noteScaleY", player);
		if (scaleX <= 0) scaleX = receptor.defScale.x;
		if (scaleY <= 0) scaleY = receptor.defScale.y;
		var newScale = getScale(receptor, FlxPoint.weak(scaleX, scaleY), receptor.noteData, player);

		receptor.scale.copyFrom(newScale);
		newScale.putWeak();
	}

	override function getSubmods()
	{
		var subMods:Array<String> = [
			"squish",
			"stretch",
			"miniX",
			"miniY",
			"receptorScaleX",
			"receptorScaleY",
			"noteScaleX",
			"noteScaleY"
		];

		var receptors = modMgr.receptors[0];
		// var kNum = receptors.length;
		// for (i in 0...PlayState.instance.keysArray.length)
		for (i in 0...receptors.length)
		{
			subMods.push('mini${i}X');
			subMods.push('mini${i}Y');
			subMods.push('squish${i}');
			subMods.push('stretch${i}');
			subMods.push('receptor${i}ScaleX');
			subMods.push('receptor${i}ScaleY');
			subMods.push('note${i}ScaleX');
			subMods.push('note${i}ScaleY');
		}
		return subMods;
	}
}
