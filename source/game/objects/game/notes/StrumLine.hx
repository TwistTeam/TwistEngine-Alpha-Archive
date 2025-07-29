package game.objects.game.notes;

import flixel.group.FlxGroup;
import flixel.math.FlxPoint;
import flixel.tweens.FlxTween.TweenOptions;
import flixel.util.FlxArrayUtil;
import flixel.util.FlxDestroyUtil;
import flixel.util.FlxHorizontalAlign;
import flixel.util.FlxSignal;
import flixel.util.FlxSignal.FlxTypedSignal;
import flixel.util.FlxSort;
import game.modchart.ModManager;
import game.objects.game.notes.*;
import game.objects.game.notes.Note.DirectionNote;
import game.states.playstate.PlayState;

class StrumLine extends FlxGroup
{
	@:isVar public var downScroll(get, set):Null<Bool> = null;
	@:isVar public var cpuControlled(get, set):Null<Bool> = null;
	@:isVar public var enableNoteSplashes(get, set):Null<Bool> = null;
	@:isVar public var enableHoldCovers(get, set):Null<Bool> = null;
	@:isVar public var enableOverlapSustainNotes(get, set):Null<Bool> = null;
	public var instaKillLastHoldNote(get, default):Null<Bool> = null;
	public var scaleNoteFactor(get, set):Float;
	public var spawnTime:Float = 1500.0;
	public var noteKillOffset:Float = 350.0;
	public var speed:Float = 1.0;
	public var applyLocalSpeed:Bool = true;
	public var spawnFullNote:Bool = false;
	public var allowMisses:Bool;
	public var isPlayer(default, set):Bool;
	public var extraData:Map<String, Note> = new Map();

	public var onSpawnNote:FlxTypedSignal<Note -> Void> = new FlxTypedSignal();
	public var onUpdateNote:FlxTypedSignal<(note:Note, time:Float, speed:Float, timeScale:Float) -> Void> = new FlxTypedSignal();
	public var onDestroyNote:FlxTypedSignal<Note -> Void> = new FlxTypedSignal();
	public var onMissNote:FlxTypedSignal<Note -> Void> = new FlxTypedSignal();
	public var onUpdateComponents:FlxSignal = new FlxSignal();

	public var sustainNotes:FlxTypedGroup<Note>;
	public var regularNotes:FlxTypedGroup<Note>;
	public var strumNotes:StrumGroup;
	public var noteSplashes:NoteSplashGroup;
	public var holdCovers:HoldCoverGroup;
	public var spawnedNotes:Array<Note> = [];
	public var unspawnNotes:Array<Note> = [];

	public var modManager:ModManager;

	@:noCompletion var _lastSpeed:Null<Float> = null;

	public function new(isPlayer:Bool = false, ?noteSplashTex:String, ?holdCoverTex:String, ?modManager:ModManager)
	{
		super();

		@:bypassAccessor this.isPlayer = isPlayer;
		this.allowMisses = isPlayer;
		this.modManager = modManager;

		add(strumNotes = new StrumGroup(isPlayer));
		add(sustainNotes = new FlxTypedGroup());
		add(holdCovers = new HoldCoverGroup(isPlayer, holdCoverTex));
		add(regularNotes = new FlxTypedGroup());
		add(noteSplashes = new NoteSplashGroup(noteSplashTex));
		sustainNotes.active = regularNotes.active = false; // disable method update

		updateComponents();
	}

	public function updateComponents() {
		updateSustainNotesOrder();
		updateVisibleHoldCovers();
		updateVisibleNoteSplashes();
		updateScrollNotes();
		holdCovers.allowReleaseSplash = isPlayer;
		strumNotes.isPlayer = isPlayer;
		onUpdateComponents.dispatch();
	}

	public override function update(elapsed:Float):Void
	{
		for (i in spawnedNotes)
			if (i != null && i.alive && i.active)
				i.update(elapsed);
		super.update(elapsed);
	}

	public function resizeByRatioNotes(ratio:Float)
	{
		// trace("RESIZE " + ratio);
		for (note in spawnedNotes) note.resizeByRatio(ratio);
		for (note in unspawnNotes) note.resizeByRatio(ratio);
	}

	public function changeNotesTexture(?newTexture:String, ?noteFilter:Note -> Bool)
	{
		if (noteFilter == null)
		{
			for (note in spawnedNotes) note.texture = newTexture;
			for (note in unspawnNotes) note.texture = newTexture;
		}
		else
		{
			for (note in spawnedNotes) if (noteFilter(note)) note.texture = newTexture;
			for (note in unspawnNotes) if (noteFilter(note)) note.texture = newTexture;
		}
	}
	public function changeStrumNotesTexture(?newTexture:String)
	{
		for (note in strumNotes)
		{
			note.texture = newTexture;
		}
	}
	public function changeNotesSplashesTexture(?newTexture:String)
	{
		noteSplashes.defaultTexture = newTexture;
	}
	public function changeHoldCoversTexture(?newTexture:String)
	{
		holdCovers.defaultTexture = newTexture;
	}

	public function updateNotesAtTime(elapsed:Float, time:Float, localSpeed:Float = 1, timeScale:Float = 1, updateLogic:Bool = true)
	{
		if (!hasNotes())
		{
			_lastSpeed = null;
			return;
		}
		if (!applyLocalSpeed)
		{
			localSpeed = 1.0;
		}

		sustainNotes.forEachDead(i -> sustainNotes.remove(i, true));
		regularNotes.forEachDead(i -> regularNotes.remove(i, true));

		var speed = localSpeed * this.speed;
		if (_lastSpeed == null)
			_lastSpeed = localSpeed;
		else if (_lastSpeed != speed)
		{
			resizeByRatioNotes(speed / _lastSpeed);
			_lastSpeed = speed;
		}
		if (unspawnNotes.length != 0)
		{
			var spawnTime:Float = spawnTime * timeScale;
			spawnTime /= speed;

			var dunceNote:Note = unspawnNotes[0];
			while (dunceNote != null && dunceNote.strumTime - time < spawnTime / dunceNote.multSpeed)
			{
				dunceNote = unspawnNotes.shift();
				spawnedNotes.unshift(dunceNote);

				dunceNote.mustPress = isPlayer;
				(dunceNote.isSustainNote ? sustainNotes : regularNotes).insert(0, dunceNote);
				dunceNote.parentStrum ??= strumNotes.members[dunceNote.noteDataReal];

				onSpawnNote.dispatch(dunceNote);

				if (dunceNote.tail.length > 0)
				{
					if (spawnFullNote)
					{
						var susNote:Note;
						for (i in 0...dunceNote.tail.length)
						{
							susNote = dunceNote.tail[i];
							susNote.parentStrum = dunceNote.parentStrum;
							spawnedNotes.unshift(susNote);
							unspawnNotes.remove(susNote);
							sustainNotes.insert(0, susNote);
							onSpawnNote.dispatch(susNote);
						}
						sortNotes();
					}
					else
					{
						for (i in 0...dunceNote.tail.length)
						{
							dunceNote.tail[i].parentStrum = dunceNote.parentStrum;
						}
					}
				}

				dunceNote = unspawnNotes[0];
			}
		}

		if (!updateLogic) return;

		if (modManager != null && modManager.active)
		{
			var curDecBeat = PlayState.instance.curDecBeat;
			for (receptor in strumNotes)
			{
				var pos = modManager.getPos(0, 0, 0, curDecBeat, receptor.noteData, 1, receptor, null, Note.vec3Cache);
				modManager.updateObject(curDecBeat, receptor, pos, receptor.player);
			}
		}

		if (spawnedNotes.length == 0) return;
		// final fakeCrochet:Float = (60 / SONG.bpm) * 1000;
		final notesSpeed:Float = speed / timeScale;
		for (daNote in spawnedNotes)
		{
			if (daNote == null) continue;

			daNote.followStrumNote(notesSpeed, modManager);

			onUpdateNote.dispatch(daNote, time, speed, timeScale);

			daNote.clipToStrumNote();

			// Kill extremely late spawnedNotes and cause misses
			if (time - daNote.strumTime > noteKillOffset / speed)
			{
				/*
				if ((daNote.mustPress && !cpuControlled && !daNote.cpuControl || !daNote.mustPress && allowMissOpponent)
					&& !daNote.ignoreNote && !endingSong && (daNote.tooLate || !daNote.noteWasHit))
				*/
				if (allowMisses && (daNote.mustPress && !cpuControlled && !daNote.cpuControl || !daNote.mustPress)
					&& !daNote.ignoreNote && (daNote.tooLate || !daNote.noteWasHit))
				{
					onMissNote.dispatch(daNote);
					daNote.ignoreNote = true;
				}
				if (daNote.alive && daNote.isOnScreen(this.camera))
				{
					// daNote.multSpeed += elapsed;
					daNote.multAlpha -= elapsed * 1.5;
				}
				else
				{
					daNote.kill();
					destroyNote(daNote, true);
				}
			}
		}

		/*
		else
		{
			spawnedNotes.forEachAlive(function(daNote:Note){
				daNote.canBeHit = daNote.wasGoodHit = false;
			});
		}
		*/
	}

	public function addNote(note:Note)
	{
		if (note != null)
			unspawnNotes.push(note);
	}
	public function addNotes(spawnedNotes:Array<Note>)
	{
		if (spawnedNotes == null || spawnedNotes.length == 0) return;
		for (i in 0...spawnedNotes.length)
		{
			unspawnNotes.push(spawnedNotes[i]);
		}
	}
	public function removeNote(note:Note)
	{
		unspawnNotes.remove(note);
	}
	public function removeNotes(spawnedNotes:Array<Note>)
	{
		for (i in spawnedNotes)
			unspawnNotes.remove(i);
	}

	public function sortNotes()
	{
		unspawnNotes.sort(_sortNotes.bind(FlxSort.ASCENDING, _, _));
		spawnedNotes.sort(_sortNotes.bind(FlxSort.ASCENDING, _, _));
		regularNotes.sort(_sortNotes, FlxSort.ASCENDING);
		sustainNotes.sort(_sortNotes, FlxSort.ASCENDING);
	}

	public function hasNotes()
	{
		return unspawnNotes.length != 0 || spawnedNotes.length != 0;
	}

	public function updateSustainNotesOrder()
	{
		remove(sustainNotes, true);
		if (enableOverlapSustainNotes)
			addBehindObject(sustainNotes, strumNotes);
		else
			addAheadObject(sustainNotes, strumNotes);

		updateVisibleHoldCovers();
	}

	public function addBehindObject(obj:FlxBasic, behindObj:FlxBasic)
		return insert(members.indexOf(behindObj), obj);

	public function addAheadObject(obj:FlxBasic, aheadObj:FlxBasic)
		return insert(members.indexOf(aheadObj) + 1, obj);

	public function updateGPUControlStrumNotes()
	{
		strumNotes.cpuControl = this.cpuControlled;
	}

	public function updateVisibleNoteSplashes()
	{
		noteSplashes.visible = enableNoteSplashes;
	}

	public function updateScrollNotes()
	{
		strumNotes.downScroll = this.downScroll;
	}

	public function updateVisibleHoldCovers()
	{
		holdCovers.visible = enableHoldCovers;
	}

	public function clearNotesBefore(time:Float)
	{
		var i:Int = unspawnNotes.length - 1;
		var daNote:Note;
		while (i > -1)
		{
			daNote = unspawnNotes[i--];
			if (daNote.strumTime - 350 < time)
			{
				daNote.active = false;
				daNote.visible = false;
				daNote.ignoreNote = true;

				// daNote.kill();
				unspawnNotes.remove(daNote);
				daNote.destroy();
			}
		}

		i = spawnedNotes.length - 1;
		while (i > -1)
		{
			daNote = spawnedNotes[i--];
			if (daNote.strumTime - 350 < time)
			{
				daNote.active = false;
				daNote.visible = false;
				daNote.ignoreNote = true;

				destroyNote(daNote, true);
			}
		}
	}

	public function destroyNote(daNote:Note, force:Bool = false){
		if (!force && !daNote.destroyOnHit)
			return false;
		onDestroyNote.dispatch(daNote);
		// daNote.kill();
		daNote.alive = false;
		daNote.destroy();
		spawnedNotes.remove(daNote);
		return true;
	}

	public override function destroy()
	{
		destroyNotes();

		extraData = null;
		onSpawnNote = null;
		onUpdateNote = null;
		onDestroyNote = null;
		onMissNote = null;
		onUpdateComponents = null;

		sustainNotes = null;
		regularNotes = null;
		strumNotes = null;
		noteSplashes = null;
		holdCovers = null;
		spawnedNotes = null;
		unspawnNotes = null;
		modManager = null;

		super.destroy();
	}

	public function destroyNotes()
	{
		var daNote:Note;
		while (spawnedNotes.length > 0)
		{
			daNote = spawnedNotes[0];
			daNote.active = daNote.visible = false;
			destroyNote(daNote, true);
		}

		while (unspawnNotes.length > 0)
			unspawnNotes.pop().destroy();
		_lastSpeed = null;
	}

	public function strumPlayConfirm(spr:StrumNote, time:Float){
		if (spr == null) return;
		spr.playAnim('confirm', true);
		spr.resetAnim = Math.max(time, 0.15);
	}

	public function strumPlayAnim(spr:StrumNote, anim:String, force:Bool = true){
		if (spr == null) return;
		spr.playAnim(anim, force);
		spr.resetAnim = 0;
	}

	public function spawnNoteSplashOnNote(note:Note)
	{
		if (!noteSplashes.visible || note.noteSplashDisabled || !note.playStrum)
			return;
		final strum:StrumNote = note.parentStrum;
		if(strum != null && strum.alpha > 0.4 && strum.visible)
		{
			noteSplashes.spawn(strum, note.noteData, note);
		}
	}
	public inline function spawnNoteSplash(strum:StrumNote, data:Int, ?note:Note)
	{
		noteSplashes.spawn(strum, data, note);
	}

	public function spawnHoldCoverOnNote(note:Note)
	{
		if (!holdCovers.visible || note.holdCoverDisabled)
		{
			if(instaKillLastHoldNote && (note.hasHoldCover() || note.getLastSustainNote() == note))
				note.kill();
			return;
		}
		if (!note.playStrum)
		{
			return;
		}
		final strum:StrumNote = note.parentStrum;
		if(strum != null && strum.alpha > 0.4 && strum.visible)
		{
			if (instaKillLastHoldNote && note.hasHoldCover())
			{
				note.disconnectHoldCover();
				note.kill();
				return;
			}
			note = note.getLastSustainNote();
			if (note != null && !note.hasHoldCover())
				holdCovers.spawnByNote(note);
		}
	}

	public function stopHoldCoversByNoteData(noteData:Int)
	{
		holdCovers.forEachAlive(i -> {
			if (i.currentNoteData == noteData)
			{
				i.playEnd();
			}
		});
	}


	function _sortNotes(i:Int, Obj1:Note, Obj2:Note):Int
	{
		return FlxSort.byValues(i, Obj1.strumTime + Obj1.noteDataReal, Obj2.strumTime + Obj2.noteDataReal);
	}

	function get_scaleNoteFactor():Float
		return strumNotes.scaleNoteFactor;
	function set_scaleNoteFactor(i:Float):Float
		return strumNotes.scaleNoteFactor = i;

	function get_downScroll():Null<Bool>
	{
		return downScroll ?? ClientPrefs.downScroll;
	}
	function set_downScroll(i:Null<Bool>):Null<Bool>
	{
		// if (downScroll != i)
		{
			downScroll = i;
			updateScrollNotes();
		}
		return i;
	}

	function get_enableNoteSplashes():Null<Bool>
	{
		return enableNoteSplashes ?? (isPlayer && ClientPrefs.noteSplashes);
	}
	function set_enableNoteSplashes(i:Null<Bool>):Null<Bool>
	{
		// if (enableNoteSplashes != i)
		{
			enableNoteSplashes = i;
			updateVisibleNoteSplashes();
		}
		return i;
	}

	function get_enableHoldCovers():Null<Bool>
	{
		return (enableHoldCovers ?? ClientPrefs.holdCovers) && !enableOverlapSustainNotes;
	}
	function set_enableHoldCovers(i:Null<Bool>):Null<Bool>
	{
		// if (enableHoldCovers != i)
		{
			enableHoldCovers = i;
			updateVisibleHoldCovers();
		}
		return i;
	}

	function get_enableOverlapSustainNotes():Null<Bool>
	{
		return enableOverlapSustainNotes ?? ClientPrefs.strumsNotesOverlap;
	}
	function set_enableOverlapSustainNotes(i:Null<Bool>):Null<Bool>
	{
		// if (enableOverlapSustainNotes != i)
		{
			enableOverlapSustainNotes = i;
			updateSustainNotesOrder();
			updateVisibleHoldCovers();
		}
		return i;
	}

	function get_instaKillLastHoldNote():Null<Bool>
	{
		return instaKillLastHoldNote ?? ClientPrefs.instaKillLastHoldNote;
	}

	function get_cpuControlled():Null<Bool>
	{
		return cpuControlled ?? !isPlayer;
	}
	function set_cpuControlled(i:Null<Bool>):Null<Bool>
	{
		// if (cpuControlled != i)
		{
			cpuControlled = i;
			updateGPUControlStrumNotes();
		}
		return i;
	}
	function set_isPlayer(i:Bool):Bool
	{
		isPlayer = i;
		updateComponents();
		for (i in 0...spawnedNotes.length)
		{
			spawnedNotes[i].mustPress = isPlayer;
		}
		return i;
	}
}