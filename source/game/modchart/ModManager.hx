// @author Nebula_Zorua
package game.modchart;

import flixel.tweens.FlxEase;
import flixel.group.FlxGroup.FlxTypedGroup;
import game.modchart.Modifier.ModifierType;
import game.modchart.events.*;
import game.modchart.math.Vector3;
import game.modchart.modifiers.*;

// Weird amalgamation of Schmovin' modifier system, Andromeda modifier system and my own new shit -neb
class ModManager
{
	public function registerDefaultModifiers()
	{
		var quickRegs:Array<Any> = [
			// AccelModifier,
			// AlphaModifier,
			// BeatModifier,
			// ConfusionModifier,
			// DrunkModifier,
			// FlipModifier,
			// InfinitePathModifier,
			// InvertModifier,
			// OpponentModifier,
			// PerspectiveModifier,
			// ReceptorScrollModifier,
			ReverseModifier,
			// ScaleModifier,
			// TransformModifier,
			// XModifier
		];
		for (mod in quickRegs)
			quickRegister(Type.createInstance(mod, [this]));

		// quickRegister(new RotateModifier(this));
		// quickRegister(new RotateModifier(this, 'center', new Vector3(FlxG.width * 0.5 - Note.swagWidth / 2, FlxG.height * 0.5 - Note.swagWidth / 2)));
		// quickRegister(new LocalRotateModifier(this, 'local'));
		// quickRegister(new SubModifier("noteSpawnTime", this));
		// setValue("noteSpawnTime", 2000);
		// setValue("xmod", 1);
		// for (i in 0...PlayState.instance.keysArray.length)
		// 	setValue('xmod$i', 1);
	}

	private var state:PlayState;

	public var receptors:Array<Array<StrumNote>> = []; // for modifiers to be able to access receptors directly if they need to
	public var timeline:EventTimeline = new EventTimeline();

	public var notemodRegister:Map<String, Modifier> = [];
	public var miscmodRegister:Map<String, Modifier> = [];

	@:deprecated("Unused in place of notemodRegister and miscModRegister")
	public var registerByType:Map<ModifierType, Map<String, Modifier>> = [NOTE_MOD => [], MISC_MOD => []];

	public var register:Map<String, Modifier> = [];

	public var modArray:Array<Modifier> = [];

	public var active:Bool = true;

	public var activeMods:Array<Array<String>> = [[], []]; // by player

	public inline function quickRegister(mod:Modifier)
		registerMod(mod.getName(), mod);

	public function registerMod(modName:String, mod:Modifier, ?registerSubmods = true)
	{
		register.set(modName, mod);
		// registerByType.get(mod.getModType()).set(modName, mod);
		switch (mod.getModType())
		{
			case NOTE_MOD:
				notemodRegister.set(modName, mod);
			case MISC_MOD:
				miscmodRegister.set(modName, mod);
		}
		timeline.addMod(modName);
		modArray.push(mod);

		if (registerSubmods)
		{
			for (submod in mod.submods)
			{
				quickRegister(submod);
			}
		}

		setValue(modName, 0); // so if it should execute it gets added Automagically
		modArray.sort((a, b) -> a.getOrder() - b.getOrder());
		// TODO: sort by mod.getOrder()
	}

	public inline function get(modName:String)
		return register.get(modName);

	public inline function getPercent(modName:String, player:Int)
		return register.get(modName).getPercent(player);

	public inline function getValue(modName:String, player:Int)
		return register.get(modName).getValue(player);

	public inline function setPercent(modName:String, val:Float, player:Int = -1)
		setValue(modName, val / 100, player);

	public function setValue(modName:String, val:Float, player:Int = -1)
	{
		if (player == -1)
		{
			for (i in 0...receptors.length)
				setValue(modName, val, i);
		}
		else
		{
			var daMod = register.get(modName);
			if (daMod == null) return;
			var mod = daMod.parent == null ? daMod : daMod.parent;
			var name = mod.getName();
			// optimization shit!! :)
			// thanks 4mbr0s3 for giving an alternative way to do all of this cus andromeda has smth similar in Flexy but like
			// this is a better way to do it
			// (ofc its not EXACTLY what 4mbr0s3 did but.. y'know, it's close to it)

			// so this actually has an issue
			// this doesnt take into account any other submods
			// so if you turn a submod off
			// it turns the parent mod off, too, when it shouldnt
			// so what I need to do is like, check other submods before removing the parent

			if (activeMods[player] == null)
				activeMods[player] = [];

			daMod.setValue(val, player);

			if (!activeMods[player].contains(name) && mod.shouldExecute(player, val))
			{
				if (daMod.getName() != name)
					activeMods[player].push(daMod.getName());
				activeMods[player].push(name);
			}
			else if (!mod.shouldExecute(player, val))
			{
				// there is prob a better way to do this
				// i just dont know it
				var modParent = daMod.parent;
				if (modParent == null)
				{
					for (name => mod in daMod.submods)
					{
						modParent = daMod; // because if this gets called at all, there's atleast 1 submod!!
						break;
					}
				}
				if (daMod != modParent)
					activeMods[player].remove(daMod.getName());
				if (modParent != null)
				{
					if (modParent.shouldExecute(player, modParent.getValue(player)))
					{
						activeMods[player].sort((a, b) -> register.get(a).getOrder() - register.get(b).getOrder());
						return;
					}
					for (subname => submod in modParent.submods)
					{
						if (submod.shouldExecute(player, submod.getValue(player)))
						{
							activeMods[player].sort((a, b) -> register.get(a).getOrder() - register.get(b).getOrder());
							return;
						}
					}
					activeMods[player].remove(modParent.getName());
				}
				else
					activeMods[player].remove(daMod.getName());
			}

			activeMods[player].sort((a, b) -> register.get(a).getOrder() - register.get(b).getOrder());
		}
	}

	public function new(state:PlayState)
	{
		this.state = state;
	}

	public function update(elapsed:Float)
	{
		for (mod in modArray)
		{
			if (mod.active && mod.doesUpdate())
				mod.update(elapsed);
		}
	}

	public function updateTimeline(curStep:Float)
		timeline.update(curStep);

	public function getBaseX(direction:Int, player:Int):Float
	{
		var x:Float = receptors[player][direction].defPos.x;
		/*
		var x:Float = (FlxG.width * 0.5) - Note.swagWidth - 54 + Note.swagWidth * direction;
		switch (player)
		{
			case 0:
				x += FlxG.width * 0.5 - Note.swagWidth * 2 - 100;
			case 1:
				x -= FlxG.width * 0.5 - Note.swagWidth * 2 - 100;
		}

		x -= 56;
		*/

		return x;
	}

	public function updateObject<T:FlxSprite & INote>(beat:Float, obj:T, pos:Vector3, player:Int)
	{
		var note:Note = cast obj;
		var strum:StrumNote = cast obj;

		if (obj.active)
		{
			for (name in activeMods[player])
			{
				var mod:Modifier = notemodRegister.get(name);
				if (mod == null)
					continue;
				if (note != null)
				{
					mod.updateNote(beat, note, pos, player);
				}
				else if (strum != null)
				{
					mod.updateReceptor(beat, strum, pos, player);
				}
			}
		}

		if (note != null)
		{
			note.updateHitbox();
		}
		else if (strum != null) // oh ok
		{
			strum.centerOrigin();
			strum.centerOffsets();
			strum.offset += strum.getAnimOffset(strum.animation.name);
		}
		/*
		if (obj is StrumNote)
		{ // oh ok
			var strum = cast(obj, StrumNote);
			var strumAnim = strum.animation.curAnim.name;
			if (strum.animOffsets.exists(strumAnim))
			{
				strum.offset.x += strum.animOffsets.get(strumAnim)[0];
				strum.offset.y += strum.animOffsets.get(strumAnim)[1];
			}
		}
		*/

		/*
		if (obj is Note)
		{
			var cum:Note = cast obj;
			cum.offset.x += cum.typeOffsetX;
			cum.offset.y += cum.typeOffsetY;
		}
		*/
	}

	public inline function getBaseVisPosD(diff:Float, songSpeed:Float = 1)
	{
		return 0.45 * diff * songSpeed;
	}

	public inline function getVisPos(songPos:Float = 0, strumTime:Float = 0, songSpeed:Float = 1)
	{
		return -getBaseVisPosD(songPos - strumTime, songSpeed);
	}

	public function getPos(time:Float, diff:Float, tDiff:Float, beat:Float, data:Int, player:Int, obj:INote, ?exclusions:Array<String>,
			?pos:Vector3):Vector3
	{
		if (!obj.active)
			return pos;

		exclusions ??= [];
		pos ??= new Vector3();

		var receptor:StrumNote = receptors[player][data];
		pos.x = receptor.defPos.x;
		pos.y = receptor.defPos.y + diff;
		pos.z = 0;
		for (name in activeMods[player])
		{
			if (exclusions.contains(name) || !obj.active)
				continue; // because some modifiers may want the path without reverse, for example. (which is actually more common than you'd think!)
			var mod:Modifier = notemodRegister.get(name);
			if (mod == null)
				continue;
			pos = mod.getPos(time, diff, tDiff, beat, pos, data, player, obj);
		}
		return pos;
	}

	public function queueEaseP(step:Float, endStep:Float, modName:String, percent:Float, style:String = 'linear', player:Int = -1, ?startVal:Float)
		queueEase(step, endStep, modName, percent * 0.01, style, player, startVal * 0.01);

	public function queueSetP(step:Float, modName:String, percent:Float, player:Int = -1)
		queueSet(step, modName, percent * 0.01, player);

	public function queueEase(step:Float, endStep:Float, modName:String, target:Float, style:String = 'linear', player:Int = -1, ?startVal:Float)
	{
		if (player == -1)
		{
			for (i in 0...receptors.length)
				queueEase(step, endStep, modName, target, style, i);
		}
		else
		{
			var easeFunc = FlxEase.linear;
			try
			{
				var newEase = Reflect.field(FlxEase, style);
				if (newEase != null)
					easeFunc = newEase;
			}

			timeline.addEvent(new EaseEvent(step, endStep, modName, target, easeFunc, player, this));
		}
	}

	public function queueSet(step:Float, modName:String, target:Float, player:Int = -1)
	{
		if (player == -1)
		{
			for (i in 0...receptors.length)
				queueSet(step, modName, target, i);
		}
		else
			timeline.addEvent(new SetEvent(step, modName, target, player, this));
	}

	public function queueFunc(step:Float, endStep:Float, callback:(CallbackEvent, Float) -> Void)
	{
		timeline.addEvent(new StepCallbackEvent(step, endStep, callback, this));
	}

	public function queueFuncOnce(step:Float, callback:(CallbackEvent, Float) -> Void)
		timeline.addEvent(new CallbackEvent(step, callback, this));
}
