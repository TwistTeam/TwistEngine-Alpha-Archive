package game.backend.system.song;

import game.backend.system.song.Song.SwagSong;

typedef BPMChangeEvent =
{
	stepTime:Int,
	songTime:Float,
	bpm:Float,
	?stepCrochet:Float
}

class Conductor
{
	public static var mainInstance:Conductor = new Conductor();

	public var bpm(default, set):Float;
	public var crochet:Float; // beats in milliseconds
	public var stepCrochet:Float; // steps in milliseconds
	public var songPosition:Float;
	public var lastSongPos:Float;
	public var offset:Float = 0;

	// public var safeFrames:Int = 10;
	public var safeZoneOffset:Float; // is calculated in create(), is safeFrames in milliseconds

	public inline function callculateSafeZoneOffset():Float
		return safeZoneOffset = (ClientPrefs.safeFrames / 60) * 1000 * FlxG.timeScale;

	public var bpmChangeMap:Array<BPMChangeEvent> = [];

	public function new()
	{
		bpm = 100;
		callculateSafeZoneOffset();
	}

	public function judgeNote(arr:Array<Rating>, diff:Float = 0):Rating // die
	{
		final data:Array<Rating> = arr;
		for (i in 0...data.length - 1) // skips last window (Shit)
			if (diff <= data[i].hitWindow)
				return data[i];

		return data[data.length - 1];
	}

	public function judgeNoteButName(arr:Array<Rating>, name:String):Rating // die
	{
		final data:Array<Rating> = arr;
		for (i in 0...data.length - 1) // skips last window (Shit)
			if (name == data[i].name)
				return data[i];

		return data[data.length - 1];
	}

	public function getCrotchetAtTime(time:Float)
		return getBPMFromSeconds(time).stepCrochet * 4;

	public function getBPMFromSeconds(time:Float):BPMChangeEvent
	{
		var lastChange:BPMChangeEvent = null;
		for (i in 0...bpmChangeMap.length)
			if (time >= bpmChangeMap[i].songTime)
				lastChange = bpmChangeMap[i];

		return lastChange ?? {
			stepTime: 0,
			songTime: 0,
			bpm: bpm,
			stepCrochet: stepCrochet
		}
	}

	public function getBPMFromStep(step:Float)
	{
		var lastChange:BPMChangeEvent = null;
		for (i in 0...bpmChangeMap.length)
			if (bpmChangeMap[i].stepTime <= step)
				lastChange = bpmChangeMap[i];

		return lastChange ?? {
			stepTime: 0,
			songTime: 0,
			bpm: bpm,
			stepCrochet: stepCrochet
		};
	}

	public function beatToSeconds(beat:Float):Float
	{
		final step = beat * 4;
		final lastChange = getBPMFromStep(step);
		return lastChange.songTime + (step - lastChange.stepTime) / lastChange.bpm / 60 / 4 * 1000; // TODO: make less shit and take BPM into account PROPERLY
	}

	public function getStep(time:Float)
	{
		final lastChange = getBPMFromSeconds(time);
		return lastChange.stepTime + (time - lastChange.songTime) / lastChange.stepCrochet;
	}

	public function getStepRounded(time:Float)
	{
		final lastChange = getBPMFromSeconds(time);
		return lastChange.stepTime + Math.floor(time - lastChange.songTime) / lastChange.stepCrochet;
	}

	public inline function getBeat(time:Float):Float
		return getStep(time) / 4;

	public inline function getBeatRounded(time:Float):Int
		return Math.floor(getStepRounded(time) / 4);

	public function mapBPMChanges(song:SwagSong)
	{
		if (song == null)
		{
			bpm = 100;
			return;
		}
		bpmChangeMap.clearArray();

		var curBPM:Float = song.bpm;
		var totalSteps:Int = 0;
		var totalPos:Float = 0;
		for (i in 0...song.notes.length)
		{
			if (song.notes[i].changeBPM && song.notes[i].bpm != curBPM)
			{
				curBPM = song.notes[i].bpm;
				bpmChangeMap.push({
					stepTime: totalSteps,
					songTime: totalPos,
					bpm: curBPM,
					stepCrochet: calculateCrochet(curBPM) / 4
				});
			}

			final deltaSteps:Int = Math.round(getSectionBeats(song, i) * 4);
			totalSteps += deltaSteps;
			totalPos += 60 / curBPM * 1000 / 4 * deltaSteps;
		}
		trace("new BPM map BUDDY " + bpmChangeMap);
	}

	function getSectionBeats(song:SwagSong, section:Int)
		return song.notes[section]?.sectionBeats ?? 4;

	public inline function calculateCrochet(bpm:Float):Float
		return 60 / bpm * 1000;

	inline function set_bpm(newBPM:Float):Float
	{
		bpm = newBPM;
		crochet = calculateCrochet(bpm);
		stepCrochet = crochet / 4;
		return newBPM;
	}
}
