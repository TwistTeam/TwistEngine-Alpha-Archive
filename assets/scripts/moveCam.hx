var offsetPoint = FlxPoint.get();
var offsetSpeed = 1.0;
var offsetAngle = 0.0;

public var enablePos:Bool = true;
public var targetPosFactor = 30.0;

public var enableAngle:Bool = false;
public var targetAngleFactor = 1.5;

function curSectionIsValid(note)
{
	final curSection = PlayState.SONG.notes[curSection];
	return curSection != null && note.mustPress == curSection.mustHitSection;
}
var lastNote;
function moveCamOnBack()
{
	if (curSectionIsValid(lastNote))
	{
		offsetSpeed = 0.55;
		// moveCamera(!lastNote.mustPress);
		offsetPoint.x = 0;
		offsetPoint.y = 0;
		offsetAngle = 0;
	}
}

function moveCam(note) {

	if (/*!note.isSustainNote &&*/ curSectionIsValid(note) && !isCameraOnForcedPos)
	{
		offsetSpeed = 1.0;
		// moveCamera(!note.mustPress);
		offsetPoint.x = 0;
		offsetPoint.y = 0;
		offsetAngle = 0;
		//var moveFactor = 10 / defaultCamZoom;
		var moveFactor = targetPosFactor;
		var angleFactor = targetAngleFactor;
		if (note.isLastSustain)
		{
			moveFactor *= 0.5;
			angleFactor *= 0.5;
		}
		runTimer(moveCamOnBack, note.isLastSustain || note.tail.length == 0 ? 0.4 : 0.9);
		lastNote = note;

		switch (note.noteData % 4){
			case 0: // LEFT
				offsetPoint.x -= moveFactor;
				offsetAngle = -angleFactor * 0.7;
			case 1: // DOWN
				offsetPoint.y += moveFactor;
				offsetAngle = -angleFactor * 0.07;
			case 2: // UP
				offsetPoint.y -= moveFactor;
				offsetAngle = angleFactor;
			case 3: // RIGHT
				offsetPoint.x += moveFactor;
				offsetAngle = angleFactor * 0.7;
		}
	}
}
function opponentNoteHit(_)	moveCam(_);
function goodNoteHit(_)		moveCam(_);

// function onSectionHit() {
//     offsetSpeed = 1;
// }

var curFunc = () -> {}
var _timer:Float = 0;
function runTimer(func, scale:Float = 1.0) {
	cancelTimer();
	curFunc = func;
	_timer = Conductor.crochet * 0.0011 * scale;
}
function cancelTimer() {
	_timer = 0;
}
function onDestroy() {
	offsetPoint.put();
	offsetPoint = null;
}
function onUpdate(elapsed) {
	if (_timer > 0)
	{
		_timer -= elapsed;
		if (_timer < 0)
		{
			curFunc();
			_timer = 0;
		}
	}
	var camera = FlxG.camera;
	if (enableAngle)
	{
		var zoomFactor = Math.min(1.0, Math.pow(camera.zoom, 0.8));
		camera.scrollAngle = CoolUtil.fpsLerp(camera.scrollAngle / zoomFactor, offsetAngle, 0.08 * offsetSpeed) * zoomFactor;
	}
	if (enablePos && offsetPoint != null)
	{
		camera.targetOffset.set(
			CoolUtil.fpsLerp(camera.targetOffset.x, offsetPoint.x, 0.08 * offsetSpeed),
			CoolUtil.fpsLerp(camera.targetOffset.y, offsetPoint.y, 0.08 * offsetSpeed)
		);
	}
}