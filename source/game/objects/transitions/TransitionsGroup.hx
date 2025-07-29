package game.objects.transitions;

import haxe.extern.EitherType;
import hscript.HScriptedClass;

typedef TransitionKey = EitherType<Class<StateTransition>, String>;

class TransitionsGroup extends openfl.display.Sprite
{
	public var members:Array<StateTransition>;
	public var curTransition(default, set):TransitionKey;
	public var checkIsUsing:(StateTransition, String) -> Bool;
	function set_curTransition(a:TransitionKey):TransitionKey
	{
		if (a is Class)
			a = Type.getClassName(a);
		if (a != curTransition)
		{
			for (i in members)
				i.isUsing = checkIsUsing(i, a);
			curTransition = a;
		}
		return curTransition;
	}

	@:allow(game.Main) function new()
	{
		super();
		checkIsUsing = (i, curTransition) -> {
			return (
				(i is HScriptedClass) ?
					Reflect.field(i, "_asc").name == curTransition
				:
					Type.getClassName(Type.getClass(i)) == curTransition
			);
		}
		// members = [new VanilaTransition()];
		members = [new VanilaTransition(this), new StickersTransition(this)];
		curTransition = Type.getClassName(Type.getClass(members[0]));
	}

	public function startTransition(?onComplete:()->Void, duration:Float, isTransIn:Bool)
	{
		for (i in members)
		{
			if (i.isUsing)
			{
				i.start(onComplete, duration, isTransIn);
			}
		}
	}
}
