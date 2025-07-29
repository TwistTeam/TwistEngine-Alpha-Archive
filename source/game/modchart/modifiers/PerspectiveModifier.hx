package game.modchart.modifiers;

// NOTE: THIS SHOULDNT HAVE ITS PERCENTAGE MODIFIED
// THIS IS JUST HERE TO ALLOW OTHER MODIFIERS TO HAVE PERSPECTIVE
// did my research
// i now know what a frustrum is lmao
// stuff ill forget after tonight
// its the next day and yea i forgot already LOL
// something somethng clipping idk
// either way
// perspective projection woo
class PerspectiveModifier extends NoteModifier
{
	override function getName()
		return 'perspectiveDONTUSE';

	override function getOrder()
		return Modifier.ModifierOrder.LAST + 100;

	override function shouldExecute(player:Int, val:Float)
		return true;

	var fov = Math.PI / 2;
	var near = 0;
	var far = 2;

	function fastTan(rad:Float) // thanks schmoovin
	{
		return FlxMath.fastSin(rad) / FlxMath.fastCos(rad);
	}

	public function getVector(curZ:Float, pos:Vector3):Vector3
	{
		var halfOffset = new Vector3(FlxG.width / 2, FlxG.height / 2, 0);
		pos = pos.subtract(halfOffset);

		// should I be using a matrix?
		// .. nah im sure itll be fine just doing this manually
		// instead of doing a proper perspective projection matrix

		// var aspect = FlxG.width/FlxG.height;
		var aspect = 1;

		var shit = Math.max(curZ - 1, 0);

		var ta = fastTan(fov / 2);
		var x = pos.x * aspect / ta;
		var y = pos.y / ta;
		var a = (near + far) / (near - far);
		var b = 2 * near * far / (near - far);
		var z = a * shit + b;
		// trace(shit, curZ, z, x/z, y/z);

		return new Vector3(x / z, y / z, z).add(halfOffset);
	}

	/*override function getReceptorPos(receptor:Receptor, pos:Vector3, data:Int, player:Int){ // maybe replace FlxPoint with a Vector3?
		// HI 4MBR0S3 IM SORRY :(( I GENUINELY FUCKIN FORGOT TO CREDIT PLEASEDONTHATEMEILOVEYOURSTUFF:(
		var vec = getVector(receptor.z,pos);
		pos.x=vec.x;
		pos.y=vec.y;

		return pos;
	}*/
	override function getPos(time:Float, visualDiff:Float, timeDiff:Float, beat:Float, pos:Vector3, data:Int, player:Int, obj:INote)
		return getVector(pos.z, pos);

	extern inline function _zTransform(pos:Vector3, spr:FlxSprite)
	{
		if (pos.z != 0)
			spr.scale.scale(1 / pos.z);
	}

	override function updateReceptor(beat:Float, receptor:StrumNote, pos:Vector3, player:Int)
	{
		_zTransform(pos, receptor);
	}

	override function updateNote(beat:Float, note:Note, pos:Vector3, player:Int)
	{
		_zTransform(pos, note);
	}
}
