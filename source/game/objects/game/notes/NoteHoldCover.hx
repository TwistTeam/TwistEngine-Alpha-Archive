package game.objects.game.notes;

import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxPoint;
import flixel.util.FlxDestroyUtil;

class NoteHoldCover extends FlxTypedSpriteGroup<FlxSprite> // dude this car ass **crush**
{
	public var glow:FlxSprite;
	public var holdSparks:FlxSpriteGroup;
	public var releaseSparks:FlxSprite;

	public var delaySpawnHoldSparks(default, null):Null<Float> = null;
	public var currentNoteData(default, null):Int = -1;
	public var currentTargetNote(default, null):Note = null;
	public var currentTargetStrum(default, null):StrumNote = null;
	public var isActive(default, null):Bool = false;
	public var holdSparksIsValid(get, never):Bool;
	var _firstHoldSpark:FlxSprite = null;

	public var mainFrames(default, null):FlxAtlasFrames = null;
	public var parentGroup(default, null):HoldCoverGroup;

	@:noCompletion var _lastTextureLoaded:String;

	@:allow(game.objects.game.notes.HoldCoverGroup)
	function new(parentGroup:HoldCoverGroup, X:Float = 0.0, Y:Float = 0.0)
	{
		super(x, y);
		this.parentGroup = parentGroup;
		moves = false;
		add(glow = new FlxSprite());
		add(holdSparks = new FlxSpriteGroup());
		add(releaseSparks = new FlxSprite());

		releaseSparks.animation.finishCallback = _ -> {
			releaseSparks.kill();
			// kill();
		}

		loadAnims();
		_firstHoldSpark = holdSparks.recycle(constructHoldSpark);
		_firstHoldSpark.alpha = 0.000001;
		glow.kill();
		releaseSparks.kill();
	}

	public function copyPropertiesOfStrumLine()
	{
		if (currentTargetStrum == null) return;

		var strumScalePoint = currentTargetStrum.baseScale * currentTargetStrum.scale;
		strumScalePoint.scale(1 / 0.7);
		if (!scale.equals(strumScalePoint))
		{
			scale.copyFrom(strumScalePoint);
		}
		strumScalePoint.put();

		var offset = parentGroup.offset;
		var holdSparksOffsets = parentGroup.holdSparksOffsets;
		var releaseSparksOffsets = parentGroup.releaseSparksOffsets;
		var glowOffsets = parentGroup.glowOffsets;

		setPosition(
			currentTargetStrum.x - (currentTargetStrum.width - Note.swagWidth) / 2 - offset.x,
			currentTargetStrum.y - (currentTargetStrum.height - Note.swagWidth) / 2 - offset.y
		);
		scrollFactor.copyFrom(currentTargetStrum.scrollFactor);
		cameras = currentTargetStrum.cameras;
		// forEach(i -> {
		// 	i.setPosition(this.x, this.y);
		// });
		_point.copyFrom(scale).add(-1, -1).scale(0.5, 0.5).add(1, 1);
		holdSparks.setPosition(
			this.x - holdSparksOffsets.x * _point.x,
			this.y - holdSparksOffsets.y * _point.y
		);
		releaseSparks.setPosition(
			this.x - releaseSparksOffsets.x * _point.x,
			this.y - releaseSparksOffsets.y * _point.y
		);
		glow.setPosition(
			this.x - glowOffsets.x * _point.x,
			this.y - glowOffsets.y * _point.y
		);

		// colorTransform.copyFrom(currentTargetStrum.colorTransform);
		alpha = currentTargetStrum.alpha;
	}

	public override function draw()
	{
		copyPropertiesOfStrumLine();
		super.draw();
	}

	var _timerSpawnHoldSparks:Float = 0;

	public override function update(elapsed:Float)
	{
		if (mainFrames == null)
		{
			// oops, try again!
			kill();
			return;
		}

		super.update(elapsed);

		if (isActive)
		{
			if (currentTargetStrum == null)
			{
				playEnd();
			}
			else if (holdSparks.visible && holdSparksIsValid)
			{
				_timerSpawnHoldSparks += elapsed;
				if (_timerSpawnHoldSparks > delaySpawnHoldSparks)
				{
					spawnHoldSpark();
					_timerSpawnHoldSparks = 0.0;
				}
			}
		}

		if (!isActive)
		{
			// for (index => i in holdSparks.members)
			// 	trace(index + ": Spr" + i.ID + " alive = " + i.alive);
			// trace(!releaseSparks.alive, holdSparks.getFirstAlive() == null);
			for (i in holdSparks)
			{
				if (i.animation.finished || i.animation.paused)
				{
					i.kill();
				}
			}
			if (!releaseSparks.alive && (!holdSparks.visible
				/*
				|| {
					var e = holdSparks.group.getLast(i -> i.exists && i.alive);
					_firstHoldSpark != null && e == _firstHoldSpark || e == null;
				}
				*/
				|| holdSparks.group.getLast(i -> i.exists && i.alive) == null
			))
			{
				kill();
				return;
			}
		}
		// super.update(elapsed);
	}

	public override function destroy()
	{
		currentTargetNote = null;
		currentTargetStrum = null;
		delaySpawnHoldSparks = null;
		_lastTextureLoaded = null;

		releaseSparks = null;
		holdSparks = null;
		glow = null;
		mainFrames = null;
		parentGroup = null;

		super.destroy();
	}

	public override function kill()
	{
		currentNoteData = -1;
		currentTargetNote = null;
		currentTargetStrum = null;
		holdSparks.forEach(i -> i.kill());
		super.kill();
	}

	public function playReleaseSpark()
	{
		final randAddedFPSOnRelease = parentGroup.randAddedFPSOnRelease;
		releaseSparks.revive();
		releaseSparks.animation.play("note" + currentNoteData, true);
		if (randAddedFPSOnRelease.active)
			releaseSparks.animation.curAnim.frameRate = 24 + FlxG.random.int(randAddedFPSOnRelease.min, randAddedFPSOnRelease.max);
		else
			releaseSparks.animation.curAnim.frameRate = 24;
		releaseSparks.centerOffsets();
	}

	public function setupByNote(note:Note)
	{
		releaseSparks.kill();
		isActive = true;
		note.connectHoldCover(this);
		currentTargetNote = note;
		currentTargetStrum = note.parentStrum;
		currentNoteData = note.noteData;
		playGlow(true);
		updateVisibleSparks();
		resetHoldSparksTimer();
		copyPropertiesOfStrumLine();
	}

	public function updateVisibleReleaseSpark()
	{
		releaseSparks.visible = parentGroup.allowReleaseSplash;
	}

	public function updateVisibleSparks()
	{
		holdSparks.visible = parentGroup.allowSparks;
	}

	public function playEnd()
	{
		if (!exists) return;
		currentTargetStrum = null;
		isActive = false;
		stopGlow();
		if (currentTargetNote != null)
		{
			updateVisibleReleaseSpark();
			currentTargetNote._capturedHoldCover = null;
			if (releaseSparks.visible
				&& (currentTargetNote.parent != null && currentTargetNote.parent.ratingMod > 0.5
					|| currentTargetNote.ratingMod > 0.5)
				&& currentTargetNote.noteWasHit)
			// if (currentTargetNote.noteWasHit)
				playReleaseSpark();
			currentTargetNote = null;
		}
	}

	public function stop()
	{
		playEnd();
		kill();
	}

	public function resetHoldSparksTimer()
	{
		_timerSpawnHoldSparks = delaySpawnHoldSparks ?? 0;
	}

	public function playGlow(force:Bool = false)
	{
		glow.revive();
		glow.animation.play("idle" + currentNoteData, force);
		glow.centerOffsets();
	}

	public function stopGlow()
	{
		glow.animation.stop();
		glow.kill();
	}

	public function spawnHoldSpark()
	{
		if (_firstHoldSpark != null)
		{
			_firstHoldSpark.kill();
			_firstHoldSpark.alpha = 1.0;
			// _firstHoldSpark = null; // почему оно нахуй ломается?
		}
		var spark:FlxSprite = holdSparks.recycle(constructHoldSpark);
		spark.animation.play("appear", true);
		spark.centerOffsets();
		spark.setPosition(holdSparks.x, holdSparks.y);
	}

	function constructHoldSpark():FlxSprite
	{
		var spr = new FlxSprite();
		spr.moves = false;
		reloadHoldSparkFrames(spr);
		return spr;
	}
	function reloadHoldSparkFrames(spr:FlxSprite)
	{
		spr.frames = mainFrames;
		spr.animation.addByPrefix("appear", "susCover_sparks", 24, false);
		spr.animation.finishCallback = _ -> spr.kill();

		if (delaySpawnHoldSparks == null)
		{
			var anim = spr.animation.getByName("appear");
			if (anim != null)
			{
				delaySpawnHoldSparks = anim.numFrames / anim.frameRate / 1.5;
			}
			else
			{
				delaySpawnHoldSparks = -1;
			}
		}
	}

	public function loadAnims(?skin:String)
	{
		skin ??= parentGroup.defaultTexture;

		var atlas = Paths.getSparrowAtlas(skin);
		if (atlas == null)
		{
			return;
		}

		mainFrames = atlas;

		glow.frames = mainFrames;
		releaseSparks.frames = mainFrames;

		_lastTextureLoaded = skin;

		var dirs = Note.dirArrayLow;
		for (i in 0...dirs.length)
		{
			glow.animation.addByPrefix('idle$i', 'susCover_${dirs[i]}Start', 24, true);
			glow.animation.getByName('idle$i').loopPoint = 1;

			releaseSparks.animation.addByPrefix('note$i', 'susCover_${dirs[i]}End', 24, false);
		}

		delaySpawnHoldSparks = null;
		holdSparks.forEach(reloadHoldSparkFrames);
	}

	function get_holdSparksIsValid()
	{
		return delaySpawnHoldSparks != null && delaySpawnHoldSparks > 0.0;
	}
}