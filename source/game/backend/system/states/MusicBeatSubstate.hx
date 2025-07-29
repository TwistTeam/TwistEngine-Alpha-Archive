package game.backend.system.states;

import flixel.addons.transition.FlxTransitionableState;
import game.backend.system.scripts.HScript;
import game.backend.system.scripts.ScriptUtil;
import game.backend.system.song.Conductor.mainInstance as Conductor;
import game.backend.utils.Controls;
import game.objects.improvedFlixel.FlxBGSprite;
import game.objects.transitions.StateTransition;
import game.states.playstate.PlayState;

class MusicBeatSubstate extends FlxSubState
{
	var curSection:Int = 0;
	var stepsToDo:Int = 0;

	var curStep:Int = 0;
	var curBeat:Int = 0;

	var curDecStep:Float = 0;
	var curDecBeat:Float = 0;

	public var script:HScript;
	public var scriptsAllowed:Bool = true;
	public var scriptName:String = null;

	var bgSprite:FlxBGSprite; // no @:noCompletion

	public function new(BGColor:FlxColor = FlxColor.TRANSPARENT, scriptsAllowed:Bool = true, ?scriptName:String)
	{
		Main.stateName = Type.getClassName(Type.getClass(this));
		super(BGColor);
		if (_bgSprite != null)
		{
			_bgSprite.destroy();
			_bgSprite = bgSprite = new FlxBGSprite();
			bgColor = bgColor;
		}
		this.scriptsAllowed = #if ALLOW_SCRIPTED_STATES scriptsAllowed #else false #end;
		this.scriptName = scriptName;
	}

	function loadSubStateScript()
	{
		if (scriptName == null)
		{
			var className = Type.getClassName(Type.getClass(this));
			scriptName = className.substr(className.lastIndexOf(".") + 1);
		}
		if (scriptsAllowed)
		{
			if(script == null)
			{
				final hxTL:String = AssetsPaths.getPath("source/states/sub/" + scriptName + ".hx");
				if (Assets.exists(hxTL))
					script = HScript.loadStateModule(hxTL, this).execute();
			}
			else
			{
				script.reload();
			}
		}
		// if (scriptsAllowed) {
		// 	if (stateScripts.scripts.length == 0) {
		// 		var scriptName = this.scriptName != null ? this.scriptName : className.substr(className.lastIndexOf(".")+1);
		// 		for (i in funkin.backend.assets.ModsFolder.getLoadedMods()) {
		// 			var path = Paths.script('data/states/${scriptName}/LIB_$i');
		// 			var script = Script.create(path);
		// 			if (script is DummyScript) continue;
		// 			script.remappedNames.set(script.fileName, '$i:${script.fileName}');
		// 			stateScripts.add(script);
		// 			script.load();
		// 		}
		// 	}else stateScripts.reload();
		// }
	}

	public final controls:Controls = Controls.instance;

	public override function tryUpdate(elapsed:Float):Void{
		if (persistentUpdate || subState == null)
		{
			call("preUpdate", [elapsed]);
			update(elapsed);
			call("postUpdate", [elapsed]);
		}

		if (_requestSubStateReset)
		{
			_requestSubStateReset = false;
			resetSubState();
		}
		if (subState != null)
		{
			subState.tryUpdate(elapsed);
		}
	}

	public function call(name:String, ?args:Array<Dynamic>, ?defaultVal:Dynamic):Dynamic {
		#if ALLOW_SCRIPTED_STATES
		// calls the function on the assigned script
		if(script != null)
			return script.call(name, args);
		#end
		return defaultVal;
	}

	public function reorder(obj:FlxBasic, index:Int)
	{
		remove(obj, true);
		return insert(index, obj);
	}
	public function addBehindObject(obj:FlxBasic, behindObj:FlxBasic) return insert(members.indexOf(behindObj), obj);
	public function addAheadObject(obj:FlxBasic, behindObj:FlxBasic) return insert(members.indexOf(behindObj) + 1, obj);

	override function update(elapsed:Float)
	{
		updateConductor();
		call("update", [elapsed]);
		super.update(elapsed);
	}
	function updateConductor():Void
	{
		// everyStep();
		final oldStep:Int = curStep;

		updateCurStep();
		updateBeat();

		if (oldStep != curStep)
		{
			if (curStep > 0)
				stepHit();
			if (PlayState.SONG != null)
				(oldStep < curStep) ? updateSection() : rollbackSection();
		}
	}

	override function create()
	{
		loadSubStateScript();
		super.create();
		call("create");
	}

	inline function updateSection():Void
	{
		if (stepsToDo < 1) stepsToDo = Math.round(getBeatsOnSection() * 4);
		while (curStep >= stepsToDo)
		{
			curSection++;
			var beats:Float = getBeatsOnSection();
			stepsToDo += Math.round(beats * 4);
			sectionHit();
		}
	}

	inline function rollbackSection():Void
	{
		if (curStep < 0) return;

		var lastSection:Int = curSection;
		curSection = 0;
		stepsToDo = 0;
		for (i in 0...PlayState.SONG.notes.length)
			if (PlayState.SONG.notes[i] != null)
			{
				stepsToDo += Math.round(getBeatsOnSection() * 4);
				if (stepsToDo > curStep) break;

				curSection++;
			}

		if (curSection > lastSection) sectionHit();
	}

	inline function updateBeat():Void
	{
		curBeat = Math.floor(curStep / 4);
		curDecBeat = curDecStep / 4;
	}

	inline function updateCurStep():Void
	{
		var lastChange = Conductor.getBPMFromSeconds(Conductor.songPosition);

		var shit = (Conductor.songPosition - ClientPrefs.noteOffset - lastChange.songTime) / lastChange.stepCrochet;
		curDecStep = lastChange.stepTime + shit;
		curStep = lastChange.stepTime + Math.floor(shit);
	}

	public function stepHit():Void
	{
		call("stepHit", [curStep]);
		if (curStep % 4 == 0) beatHit();
	}

	public function beatHit():Void
	{
		// trace('Beat: ' + curBeat);
		call("beatHit", [curBeat]);
	}

	public function sectionHit():Void
	{
		// trace('Section: ' + curSection + ', Beat: ' + curBeat + ', Step: ' + curStep);
		call("sectionHit", [curSection]);
	}

	function getBeatsOnSection()
	{
		var val:Null<Float> = 4;
		if (PlayState.SONG != null && PlayState.SONG.notes[curSection] != null)	val = PlayState.SONG.notes[curSection].sectionBeats;
		return val == null ? 4 : val;
	}

	public function getSubStateWithSubState() return this.subState ?? this;

	public override function destroy()
	{
		call("destroy");
		super.destroy();
		call("postDestroy");
		script = flixel.util.FlxDestroyUtil.destroy(script);
		if (FlxG.state == this)
			AssetsPaths.resetFramesCache();
	}

	override function close()
	{
		final e = call("close");
		if (e != ScriptUtil.Function_Stop)
		{
			Main.stateName = Type.getClassName(Type.getClass(_parentState));
			super.close();
			call("closePost");
		}
	}
	public override function startOutro(onOutroComplete:() -> Void)
	{
		if (FlxTransitionableState.skipNextTransIn)
		{
			FlxTransitionableState.skipNextTransIn = false;
			return super.startOutro(onOutroComplete);
		}
		// Custom made Trans in
		Main.transition.startTransition(onOutroComplete, StateTransition.transTime, false);
	}

	/**
	 * SCRIPTING STUFF
	 */
	public override function openSubState(subState:FlxSubState)
	{
		var e = call("onOpenSubState", [subState]);
		if (e != ScriptUtil.Function_Stop)
			super.openSubState(subState);
	}
}
