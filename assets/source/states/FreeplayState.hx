import flixel.text.FlxBitmapText;
import game.backend.utils.Difficulty;
import game.backend.utils.FlxBitmapFontTool;
import game.states.FreeplayState;
import openfl.text.TextFormat;

var scoreBG:FlxSprite;
var scoreText:FlxBitmapText;
var diffText:FlxBitmapText;
var lerpScore:Float = 0;
var lerpRating:Float = 0;
var diffAlpha:Float = 0;
var lastDifficultyName:String = null;

function create()
{
	var format = new TextFormat(Paths.font('VCR OSD Mono Cyr.ttf'), 26, FlxColor.WHITE);
	format.letterSpacing = 5;
	var flxBitmapFont = FlxBitmapFontTool.fromFont(null, format);

	scoreText = new FlxBitmapText(FlxG.width * 0.7, 5, "", flxBitmapFont);
	scoreText.active = false;
	scoreText.scrollFactor.set();

	diffText = new FlxBitmapText(scoreText.x, scoreText.y + scoreText.height, "", flxBitmapFont);
	diffText.active = false;
	diffText.scrollFactor.set();
	diffText.scale.set(0.9, 0.9);

	scoreBG = new FlxSprite(scoreText.x - 6, 0).makeGraphic(1, 1, 0x99000000);
	scoreBG.active = false;
	scoreBG.scrollFactor.set();
	scoreBG.origin.set();

	add(scoreBG);
	add(diffText);
	add(scoreText);

	diffText.cameras = scoreBG.cameras = scoreText.cameras = [camHUD];
	changeDiff();
	diffAlpha = Std.int(diffText.text.length > 0);
}

function preUpdate(elapsed:Float)
{
	if (allowControls && subState == null && !momIGoingToSong)
	{
		if (controls.UI_LEFT_P)
		{
			changeDiff(-1);
		}
		else if (controls.UI_RIGHT_P)
		{
			changeDiff(1);
		}
	}
}

function postUpdate(elapsed:Float)
{
	if (Math.abs(lerpScore - intendedScore) <= 10)
		lerpScore = intendedScore;
	else
		lerpScore = CoolUtil.fpsLerp(lerpScore, intendedScore, 0.4);

	if (Math.abs(lerpRating - intendedRating) <= 0.01)
		lerpRating = intendedRating;
	else
		lerpRating = CoolUtil.fpsLerp(lerpRating, intendedRating, 0.2);

	final ratingSplit = Std.string(CoolUtil.floorDecimal(lerpRating * 100, 2)).split(".");
	if (ratingSplit.length < 2) // No decimals, add an empty space
		ratingSplit.push("0");

	while (ratingSplit[1].length < 2) // Less than 2 decimals in it, add decimals then
		ratingSplit[1] += "0";

	diffAlpha = CoolUtil.fpsLerp(diffAlpha, Std.int(diffText.text.length > 0), 0.2);

	scoreText.text = 'PERSONAL BEST: ${Math.floor(lerpScore)} (${ratingSplit.join(".")}%)';
	positionHighscore();
}

function positionHighscore()
{
	scoreText.x = FlxG.width - scoreText.width;
	scoreBG.scale.x = FlxG.width - scoreText.x + 6.0;
	scoreBG.x = FlxG.width - scoreBG.scale.x;
	scoreBG.scale.y = 46 + diffAlpha * 22;
	diffText.x = scoreBG.x + (scoreBG.width * scoreBG.scale.x - diffText.width) / 2.0;
	diffText.scale.set(diffAlpha * 0.9, diffAlpha * 0.9);
}

function changeDiff(change = 0)
{
	var curDifficulties = curDifficulties;
	var curDifficultyIndex = FreeplayState.curDifficultyIndex;
	if (curDifficulties == null)
	{
		curDifficultyIndex = -1;
		diffText.text = "";
		lastDifficultyName = null;
		updateSongSave();
		return;
	}
	if (curDifficultyIndex == -1)
	{
		curDifficultyIndex = curDifficulties.indexOf(Difficulty.defaultDifficulty);
		if (curDifficultyIndex == -1)
			curDifficultyIndex = -change;
	}
	curDifficultyIndex = FlxMath.wrap(curDifficultyIndex + change, 0, curDifficulties.length - 1);

	FreeplayState.curDifficultyIndex = curDifficultyIndex;

	lastDifficultyName = curDifficulty;
	diffText.text = (curDifficulties.length > 1) ? '< ${lastDifficultyName.toUpperCase()} >' : lastDifficultyName.toUpperCase();

	// positionHighscore();
	updateSongSave();
}

function changeItemPost(huh:Int = 0, ?snap:Bool)
{
	changeDiff();
}

/*
	var curPlayedIcon;
	function preUpdate(elapsed:Float)
	{
	var preIcon = curPlayedIcon;
	curPlayedIcon = getHealthIcon(grpSongs.members[FreeplayState.curSongPlaying[0]]);
	if (curPlayedIcon != preIcon && preIcon != null)
	{
		preIcon.scale.set(preIcon.baseScale * preIcon.data.scale, preIcon.baseScale * preIcon.data.scale);
	}
	if (curPlayedIcon != null)
	{
		updateHealthIcon(curPlayedIcon);
	}
	}
	function updateHealthIcon(icon:HealthIcon) {
	var baseScale = icon.baseScale * icon.data.scale;
	icon.scale.x = CoolUtil.fpsLerp(icon.scale.x, baseScale, 0.35);
	icon.scale.y = CoolUtil.fpsLerp(icon.scale.y, baseScale, 0.35);
	if (Math.abs((icon.scale.x + icon.scale.y) / 2 - baseScale) < 0.018)
	{
		icon.scale.x = icon.scale.y = baseScale;
	}
	// icon.updateHitboxSpecial();
	}
	function beatHit(e) {
	curPlayedIcon?.onBeatScale();
	}
 */
