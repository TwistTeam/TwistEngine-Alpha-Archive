package game.backend.system.states;

import game.backend.utils.ThreadUtil;
import game.backend.system.GraphicCacheSprite;
import game.backend.system.scripts.HScript;
import game.backend.system.scripts.ScriptUtil;
import game.backend.system.song.Conductor.mainInstance as Conductor;
import game.backend.utils.Controls;
import game.objects.transitions.StateTransition;
import game.states.playstate.PlayState;
import game.states.substates.pauses.*;
// import game.states.substates.gameovers.*;
import game.states.substates.GameOverSubstate;
import flixel.addons.ui.FlxUIState;
import flixel.addons.transition.FlxTransitionableState;
import flixel.util.FlxDestroyUtil;
#if TOUCH_CONTROLS
import game.mobile.objects.MobileHitbox;
#end

class MusicBeatState extends FlxTransitionableState
{
	// substates that transition can land onto
	public static final substatesToTrans:Array<Class<flixel.FlxSubState>> = [
		PauseBasic,
		GameOverSubstate
		#if LUA_ALLOWED, game.backend.system.scripts.FunkinLua.CustomSubstate #end
	];

	var stepsToDo:Int = 0;

	public var curBeat:Int = 0;
	public var curStep:Int = 0;
	public var curSection:Int = 0;

	public var script:HScript;
	public var scriptsAllowed:Bool = true;
	public var scriptName:String = null;

	public var curDecStep:Float = 0;
	public var curDecBeat:Float = 0;

	public static var onSwitchState:FlxState->Void;
	public static var onResetState:Void->Void;

	public final controls:Controls = Controls.instance;

	/**
	 * Dummy sprite used to cache graphics to GPU.
	 */
	public var graphicCache:GraphicCacheSprite = new GraphicCacheSprite();

	#if TOUCH_CONTROLS
	public var hitbox:MobileHitbox;
	#end

	public function new(?scriptName:String, ?scriptsAllowed:Bool = true)
	{
		super();
		this.scriptsAllowed = #if ALLOW_SCRIPTED_STATES scriptsAllowed #else false #end;
		this.scriptName = scriptName;
	}

	override function create()
	{
		Main.stateName = Type.getClassName(Type.getClass(this));
		loadStateScript();
		super.create();
		call("create");
		// FlxG.autoPause = false;
		// FlxG.timeScale = 1.5; funny

		FlxTransitionableState.skipNextTransOut = false;
	}

	public function createHitbox(visible:Bool = true, ?camera:FlxCamera):Void
	{
		#if TOUCH_CONTROLS
		if (hitbox != null) removeHitbox();

		hitbox = new MobileHitbox();
		hitbox.visible = visible;
		if (camera != null) hitbox.cameras = [camera];
		add(hitbox);
		#end
	}

	public function removeHitbox(shouldDestroy:Bool = false):Void
	{
		#if TOUCH_CONTROLS
		if (hitbox == null)
		{
			trace("The hitbox doesn't exist, dumbfuck.");
			return;
		}

		remove(hitbox);
		if (shouldDestroy)
			hitbox = FlxDestroyUtil.destroy(hitbox);
		#end
	}

	function loadStateScript()
	{
		#if ALLOW_SCRIPTED_STATES
		if (scriptName == null)
		{
			var className = Type.getClassName(Type.getClass(this));
			scriptName = className.substr(className.lastIndexOf(".") + 1);
		}
		if (scriptsAllowed)
			if (script == null)
			{
				final hxTL:String = AssetsPaths.getPath("source/states/" + scriptName + ".hx");
				if (Assets.exists(hxTL))
					script = HScript.loadStateModule(hxTL, this).execute();
			}
			else
				script.reload();
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
		#end
	}

	@:allow(flixel.FlxGame)
	override function tryUpdate(elapsed:Float):Void
	{
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

	public function call(name:String, ?args:Array<Dynamic>, ?defaultVal:Dynamic):Dynamic
	{
		#if ALLOW_SCRIPTED_STATES
		if (script != null)
			return script.call(name, args);
		#end
		return defaultVal;
	}

	public function reorder(obj:FlxBasic, index:Int)
	{
		remove(obj, true);
		return insert(index, obj);
	}

	public function addBehindObject(obj:FlxBasic, behindObj:FlxBasic)
		return insert(members.indexOf(behindObj), obj);

	public function addAheadObject(obj:FlxBasic, aheadObj:FlxBasic)
		return insert(members.indexOf(aheadObj) + 1, obj);

	override function update(elapsed:Float)
	{
		updateConductor();
		call("update", [elapsed]);
		/*
			#if DEV_BUILD
			if (script != null && FlxG.keys.justPressed.F5)
			{
				FlxTransitionableState.skipNextTransIn = FlxTransitionableState.skipNextTransOut = true;
				FlxG.resetState();
			}
			#end
		 */
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
				(oldStep < curStep)
			?updateSection
			() : rollbackSection
			();
		}
	}

	function updateSection():Void
	{
		if (stepsToDo < 1)
			stepsToDo = Math.round(getBeatsOnSection() * 4);
		while (curStep >= stepsToDo)
		{
			curSection++;
			stepsToDo += Math.round(getBeatsOnSection() * 4);
			sectionHit();
		}
	}

	function rollbackSection():Void
	{
		if (curStep < 0)
			return;

		final lastSection:Int = curSection;
		curSection = 0;
		stepsToDo = 0;
		for (i in 0...PlayState.SONG.notes.length)
		{
			if (PlayState.SONG.notes[i] == null)
				continue;
			stepsToDo += Math.round(getBeatsOnSection() * 4);
			if (stepsToDo > curStep)
				break;

			curSection++;
		}

		if (curSection > lastSection)
			sectionHit();
	}

	function updateBeat():Void
	{
		curBeat = Math.floor(curStep / 4);
		curDecBeat = curDecStep / 4;
	}

	function updateCurStep():Void
	{
		final lastChange = Conductor.getBPMFromSeconds(Conductor.songPosition);

		final shit = (Conductor.songPosition - ClientPrefs.noteOffset - lastChange.songTime) / lastChange.stepCrochet;
		curDecStep = lastChange.stepTime + shit;
		curStep = lastChange.stepTime + Math.floor(shit);
	}

	public static function switchState(nextState:FlxState)
	{
		var e:MusicBeatState = (FlxG.state is MusicBeatState ? cast FlxG.state : null);
		if (e != null && e.call("switchState", [nextState]) == ScriptUtil.Function_Stop)
			return;
		if (nextState == null || nextState == FlxG.state)
		{
			resetState();
			return;
		}

		FlxG.switchState(nextState);
		FlxTransitionableState.skipNextTransIn = false;
		if (onSwitchState != null)
			onSwitchState(nextState);
		onSwitchState = null;
	}

	public inline static function resetState()
		FlxG.resetState();

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

	// Custom made Trans in
	public static function startTransition(?nextState:FlxState)
	{
		final state = getStateWithSubState();
		if (nextState == null)
			nextState = state;
		if (nextState == state)
			StateTransition.finishCallback = FlxG.resetState;
		else
			StateTransition.finishCallback = function() FlxG.switchState(nextState);
	}

	public static inline function getState()
		return FlxG.state;

	public static function getStateWithSubState()
		return FlxG.state.subState != null
			&& substatesToTrans.contains(Type.getClass(FlxG.state.subState)) ? FlxG.state.subState : FlxG.state;

	public function stepHit():Void
	{
		call("stepHit", [curStep]);
		if (curStep % 4 == 0)
			beatHit();
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

	/**
	 * SCRIPTING STUFF
	 */
	public override function openSubState(subState:FlxSubState)
	{
		var e = call("onOpenSubState", [subState]);
		if (e != ScriptUtil.Function_Stop)
			super.openSubState(subState);
	}

	public override function destroy()
	{
		// call("destroy");
		super.destroy();
		graphicCache.destroy();
		call("destroy");
		script = FlxDestroyUtil.destroy(script);
		if (FlxG.state == this)
			AssetsPaths.resetFramesCache();

		#if TOUCH_CONTROLS
		removeHitbox(true);
		#end
	}

	function getBeatsOnSection()
		return PlayState.SONG?.notes[curSection]?.sectionBeats ?? 4;
}

class MusicBeatUIState extends FlxUIState
{
	var curSection:Int = 0;
	var stepsToDo:Int = 0;

	var curStep:Int = 0;
	var curBeat:Int = 0;

	public var script:HScript;
	public var scriptsAllowed:Bool = true;
	public var scriptName:String = null;

	var curDecStep:Float = 0;
	var curDecBeat:Float = 0;

	public final controls:Controls = Controls.instance;

	/**
	 * Dummy sprite used to cache graphics to GPU.
	 */
	public var graphicCache:GraphicCacheSprite = new GraphicCacheSprite();

	public function new(?scriptName:String, ?scriptsAllowed:Bool = true)
	{
		super();
		this.scriptsAllowed = #if ALLOW_SCRIPTED_STATES scriptsAllowed #else false #end;
		this.scriptName = scriptName;
	}

	override function create()
	{
		Main.stateName = Type.getClassName(Type.getClass(this));
		loadStateScript();
		super.create();
		call("create");
		// FlxG.autoPause = false;
		// FlxG.timeScale = 1.5; funny

		FlxTransitionableState.skipNextTransOut = false;
	}

	function loadStateScript()
	{
		#if ALLOW_SCRIPTED_STATES
		var className = Type.getClassName(Type.getClass(this));
		if (scriptName == null)
			scriptName = className.substr(className.lastIndexOf(".") + 1);
		if (scriptsAllowed)
		{
			if (script == null)
			{
				final hxTL:String = AssetsPaths.getPath("source/states/" + scriptName + ".hx");
				if (Assets.exists(hxTL))
					script = HScript.loadStateModule(hxTL, this).execute();
			}
			else
				script.reload();
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
		#end
	}

	public override function tryUpdate(elapsed:Float):Void
	{
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

	public function call(name:String, ?args:Array<Dynamic>, ?defaultVal:Dynamic):Dynamic
	{
		#if ALLOW_SCRIPTED_STATES
		if (script != null)
			return script.call(name, args);
		#end
		return defaultVal;
	}

	public function reorder(obj:FlxBasic, index:Int)
	{
		remove(obj, true);
		return insert(index, obj);
	}

	public function addBehindObject(obj:FlxBasic, behindObj:FlxBasic)
		return insert(members.indexOf(behindObj), obj);

	public function addAheadObject(obj:FlxBasic, behindObj:FlxBasic)
		return insert(members.indexOf(behindObj) + 1, obj);

	override function update(elapsed:Float)
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
				(oldStep < curStep)
			?updateSection
			() : rollbackSection
			();
		}
		call("update", [elapsed]);
		/*
			#if DEV_BUILD
			if (script != null && FlxG.keys.justPressed.F5)
			{
				FlxTransitionableState.skipNextTransIn = FlxTransitionableState.skipNextTransOut = true;
				FlxG.resetState();
			}
			#end
		 */
		super.update(elapsed);
	}

	function updateSection():Void
	{
		if (stepsToDo < 1)
			stepsToDo = Math.round(getBeatsOnSection() * 4);
		while (curStep >= stepsToDo)
		{
			curSection++;
			final beats:Float = getBeatsOnSection();
			stepsToDo += Math.round(beats * 4);
			sectionHit();
		}
	}

	function rollbackSection():Void
	{
		if (curStep < 0)
			return;

		final lastSection:Int = curSection;
		curSection = 0;
		stepsToDo = 0;
		for (i in 0...PlayState.SONG.notes.length)
		{
			if (PlayState.SONG.notes[i] == null)
				continue;
			stepsToDo += Math.round(getBeatsOnSection() * 4);
			if (stepsToDo > curStep)
				break;

			curSection++;
		}

		if (curSection > lastSection)
			sectionHit();
	}

	function updateBeat():Void
	{
		curBeat = Math.floor(curStep / 4);
		curDecBeat = curDecStep / 4;
	}

	function updateCurStep():Void
	{
		final lastChange = Conductor.getBPMFromSeconds(Conductor.songPosition);

		final shit = (Conductor.songPosition - ClientPrefs.noteOffset - lastChange.songTime) / lastChange.stepCrochet;
		curDecStep = lastChange.stepTime + shit;
		curStep = lastChange.stepTime + Math.floor(shit);
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

	// Custom made Trans in
	public static function startTransition(?nextState:FlxState)
	{
		final state = MusicBeatState.getStateWithSubState();
		if (nextState == null)
			nextState = state;
		if (nextState == state)
			StateTransition.finishCallback = FlxG.resetState;
		else
			StateTransition.finishCallback = function() FlxG.switchState(nextState);
	}

	public function stepHit():Void
	{
		call("stepHit", [curStep]);
		if (curStep % 4 == 0)
			beatHit();
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

	/**
	 * SCRIPTING STUFF
	 */
	public override function openSubState(subState:FlxSubState)
	{
		var e = call("onOpenSubState", [subState]);
		if (e != ScriptUtil.Function_Stop)
			super.openSubState(subState);
	}

	public override function destroy()
	{
		super.destroy();
		graphicCache.destroy();
		call("destroy");
		script = FlxDestroyUtil.destroy(script);
		if (FlxG.state == this)
			AssetsPaths.resetFramesCache();
	}

	function getBeatsOnSection()
		return PlayState.SONG?.notes[curSection]?.sectionBeats ?? 4;
}
