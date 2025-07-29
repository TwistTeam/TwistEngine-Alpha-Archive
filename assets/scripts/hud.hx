import game.objects.improvedFlixel.FlxFixedText;
import flixel.util.FlxStringUtil;
import game.objects.Bar;
import game.objects.FlxExtendedSprite;
import flixel.text.FlxText;
import flixel.text.FlxText.FlxTextBorderStyle;
import flixel.text.FlxText.FlxTextFormat;
import flixel.addons.effects.FlxClothSprite;
import flixel.util.FlxDirectionFlags;
import flixel.group.FlxTypedSpriteGroup;

var timeTxtFormat = new FlxTextFormat();
var botplayTxt = new FlxText(0, 10, 0, "BOTPLAY");
var scoreTxtTween:FlxTween;
var healthBarBar:Bar;
var timeText:FlxFixedText;
var scoreTxt:FlxText;
function updateTimeText()
{
	timeText.text = game.SONG.display
		+ ": "
		+ FlxStringUtil.formatTime(songPercent * songLength / 1000)
		+ " / "
		+ FlxStringUtil.formatTime(songLength / 1000);
	final range = timeText._formatRanges[0].range;
	range.start = game.SONG.display.length + 2;
	range.end = timeText.text.length;
}

function healthBarUpdateTwist(elapsed:Float)
{
	if (botplayTxt.visible)
	{
		botplaySine += elapsed;
		botplayTxt.colorTransform.alphaMultiplier = (1 - Math.sin(Math.PI * botplaySine)) / 2;
	}

	if (!startingSong && !paused)
	{
		final curTime:Float = Math.max(0.0, Conductor.songPosition - ClientPrefs.noteOffset);
		final prevTime:Float = songPercent * songLength;
		songPercent = curTime / songLength;
		// Math.floor(curTime / 1000.0) > Math.floor(prevTime / 1000.0)
		if (prevTime % 1000.0 > curTime % 1000.0)
		{
			updateTimeText();
		}
	}

	timeText.setPosition(healthBarBar.x + (healthBarBar.flipped ? 10 : healthBarBar.width - timeText.width - 5), healthBarBar.y - timeText.height - 5);

	// if (!startingSong && !paused && updateTime){
	// 	final curTime:Float = Math.max(0, Conductor.songPosition - ClientPrefs.noteOffset);
	// 	songPercent = (curTime / songLength);
	//
	// 	timeTxt.text = FlxStringUtil.formatTime(Math.max(Math.floor((ClientPrefs.timeBarType == 'Time Elapsed' ? curTime : (songLength - curTime)) / 1000), 0), false);
	// }

	iconsGroup.forEach(updateHealthIcon);
}

function updateScoreTextTwist(miss:Bool = false, ?start:Bool = false)
{
	if (scoreTxt == null)
		return;
	var text:String = 'Score: $songScore • ';
	if (!instakillOnMiss)
		text += 'Misses: $songMisses • ';
	text += 'Rating: $ratingName';
	if (ratingName != '?')
		text += ' (${CoolUtil.quantize(ratingPercent * 100, 100)}%)\n';

	// scoreTxt._formatRanges[0].range.start = text.length - ratingName.length;
	// scoreTxt._formatRanges[0].range.end = text.length;
	// accFormat.borderColor = FlxColor.interpolate(FlxColor.RED, FlxColor.GREEN, // ratingPercent);
	// accFormat.format.color = FlxColor.getLightened(accFormat.borderColor, 0.5);

	scoreTxt.text = text;
	if (ClientPrefs.scoreZoom && !(miss || start))
	{
		if (scoreTxtTween != null)
		{
			scoreTxtTween.cancel();
		}
		scoreTxt.scale.set(0.955, 0.955);
		scoreTxtTween = FlxTween.tween(scoreTxt.scale, {x: 1, y: 1}, 0.2);
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
	icon.updateHitboxSpecial();
	if (icon.isPlayer == iconsGroup.flipX)
	{
		// icon.origin.x = icon.frameWidth - icon.origin.x;
		icon.x = healthBarBar.centerPoint.x - 52 - 150 * icon.scale.x / 2; // dad
	}
	else
	{
		icon.x = healthBarBar.centerPoint.x - 26 + 150 * (icon.scale.x - 1) / 2; // bf
	}
	icon.y = healthBarBar.centerPoint.y - 75;
	// icon.y = healthBarBar.centerPoint.y - 75 + 150 * (icon.scale.x - 1) / 2;
}

function onTwistFlipHealthBar() {
	iconsGroup.flipX = healthBarBar.flipped = !iconsGroup.flipX;
}

function updateColorsInHealthBarTwist(start) {
	healthBarBar.setColors(dadColor, bfColor);
}

function createTwistHud()
{
	// healthBar
	healthBarBar = new Bar(0, 0, 'healthBar', () -> return health, 0, 2);
	healthBarBar.y = FlxG.height * 0.89;
	healthBarBar.smoothFactor = 2.9;
	if (ClientPrefs.downScroll)
		healthBarBar.y = 0.09 * FlxG.height;
	healthBarBar.screenCenter(X);
	variables.set('healthBar', healthBarBar);
	healthBarBar.setColors(FlxColor.RED, FlxColor.LIME);

	timeText = new FlxFixedText(0, 0, 0, "");
	timeText.setFormat(Paths.font("VCR OSD Mono Cyr.ttf"), 16, 0xFFFFFF, null, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
	timeText.borderSize = 1.2;
	timeText.addFormat(timeTxtFormat, 0, 1);
	timeTxtFormat.format.size = timeText.size - 2;

	botplayTxt.setFormat(Paths.font("VCR OSD Mono Cyr.ttf"), 18, 0xFFFFFF, 'center', FlxTextBorderStyle.OUTLINE_FAST, FlxColor.BLACK);
	botplayTxt.borderSize = 1.2;
	botplayTxt.x = FlxG.width - 10 - botplayTxt.width;
	botplayTxt.visible = cpuControlled;
	variables.set('botplayTxt', botplayTxt);

	scoreTxt = new FlxText(100, healthBarBar.y + 36, FlxG.width, "kys");
	scoreTxt.setFormat(Paths.font("VCR OSD Mono Cyr.ttf"), 18, 0xFFFFFF, 'center', FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
	scoreTxt.borderSize = 1.2;
	scoreTxt.screenCenter(X);
	// scoreTxt.addFormat(accFormat, -1, 0);
	variables.set('scoreTxt', scoreTxt);
}

function onBotplayChange(e)
{
	botplayTxt.visible = e;
	return Function_Continue;
}

spawnCountDownSprite = function(swagCounter:Int)
{
	var sprite:FlxSprite = switch (swagCounter)
		{
			case 0: createCountSprite(null, "intro3");
			case 1: createCountSprite('ready', "intro2");
			case 2: createCountSprite('set', "intro1");
			case 3: createCountSprite('go', "introGo");
			default: null;
		}

	if (sprite != null)
	{
		var scaleFactor = swagCounter >= 3 ? 1.5 : 0.9;
		FlxTween.tween(sprite.scale, {x: sprite.scale.x * scaleFactor, y: sprite.scale.y * scaleFactor}, Conductor.crochet / 1000, {ease: FlxEase.cubeOut});
		FlxTween.tween(sprite, {alpha: 0, y: sprite.y + (swagCounter >= 3 ? 25 : 100)}, Conductor.crochet / 1000, {
			ease: FlxEase.cubeIn,
			onComplete: _ ->
			{
				remove(sprite, true);
				sprite.destroy();
			}
		});
	}
}

final placement:Float = FlxG.width * 0.6;

// for score popups recycling
var scoreGroup:FlxTypedSpriteGroup = new FlxTypedSpriteGroup();
// scoreGroup.cameras = [camHUD];
scoreGroup.ID = 0;
setVar('scoreGroup', scoreGroup);
function onCreate()
{
	createTwistHud();
}
function onCreatePost()
{
	// Precashe
	cachePopUpScore();
	cacheCountdown();
	cachePause();

	addBehindObject(scoreGroup, playerStrumLine);
	// popUpCombo(1);
	switchHud("twist");
}

function onUpdateHud()
{
	switch healthbarStyle
	{
		case "twist":
			healthBarGroup.add(healthBarBar);
			healthBarGroup.add(timeText);
			healthBarGroup.add(iconsGroup);
			healthBarGroup.add(botplayTxt);
			healthBarGroup.add(scoreTxt);
			updateColorsInHealthBar = updateColorsInHealthBarTwist;
			flipHealthBar = onTwistFlipHealthBar;
			healthBarUpdate = healthBarUpdateTwist;
			updateScore = updateScoreTextTwist;
			updateTimeText();
			//updateScore(false, true);
			iconsGroup.forEach(updateHealthIcon);
	}
}

import flixel.tweens.FlxTween.FlxTweenManager;
showCombo = true;
final comboTweenManager = add(new FlxTweenManager());
final placement:Float = FlxG.width * 0.35;

var killTweenTarget = e -> e._object.kill();
var killSpr = spr -> spr.kill();
popUpCombo = daRating -> {
	var scaleMult:Float = 0.7;
	var numScale:Float = 0.5;
	var pixelShitPart1:String = "";
	var pixelShitPart2:String = "";
	var antialiasing:Bool = true;
	if (PlayState.isPixelStage)
	{
		scaleMult = PlayState.daPixelZoom * 0.85;
		numScale = PlayState.daPixelZoom * 0.75;
		pixelShitPart1 = 'pixelUI/';
		pixelShitPart2 = '-pixel';
		antialiasing = false;
	}

	if (!ClientPrefs.comboStacking)
	{
		comboTweenManager.clear();
		scoreGroup.forEachAlive(killSpr);
	}

	if (showRating)
	{
		final rating = scoreGroup.recycle(FlxExtendedSprite).loadGraphic(Paths.image(pixelShitPart1 + daRating.image + pixelShitPart2));
		rating.setScale(scaleMult);
		rating.updateHitbox();
		rating.antialiasing = antialiasing;
		rating.x = placement - 40;
		rating.screenCenter(Y).y -= 30;
		rating.acceleration.y = 550;
		rating.velocity.set(-FlxG.random.int(1, 10), -FlxG.random.int(140, 175));

		rating.alpha = 1;
		// comboTweenManager.num(1, 0, 0.2, {
		comboTweenManager.tween(rating, {alpha: 0}, 0.2, {
			onComplete: killTweenTarget,
			startDelay: Conductor.crochet / 1000.0
		// }, rating.set_alpha);
		});

		rating.ID = scoreGroup.ID++;

		groupShit(scoreGroup, rating);
	}
	if (showCombo && combo >= Math.max(maxCombo, 5)) // > 69 // nice
	{
		final comboSpr = scoreGroup.recycle(FlxExtendedSprite).loadGraphic(Paths.image(pixelShitPart1 + 'combo' + pixelShitPart2));
		comboSpr.x = placement + 10;
		comboSpr.setScale(scaleMult * 0.9);
		comboSpr.updateHitbox();
		comboSpr.antialiasing = antialiasing;
		comboSpr.screenCenter(Y).y += 30;
		comboSpr.acceleration.y = FlxG.random.int(200, 300);
		comboSpr.velocity.set(FlxG.random.int(1, 10), -FlxG.random.int(130, 160));
		comboSpr.y += 60;

		comboSpr.alpha = 1;
		// comboTweenManager.num(1, 0, 0.2, {
		comboTweenManager.tween(comboSpr, {alpha: 0}, 0.2, {
			onComplete: killTweenTarget,
			startDelay: Conductor.crochet / 1000.0
		// }, comboSpr.set_alpha);
		});
		comboSpr.ID = scoreGroup.ID++;

		groupShit(scoreGroup, comboSpr);
	}

	// var xThing = comboSpr.x;
	if (showComboNum)
	{
		var strCombo = Std.string(combo).split("");
		for (scoreInt => str in strCombo)
		{
			final numScore = scoreGroup.recycle(FlxExtendedSprite).loadGraphic(Paths.image(pixelShitPart1 + 'num' + str + pixelShitPart2));
			numScore.setScale(numScale);
			numScore.updateHitbox();
			numScore.antialiasing = antialiasing;
			numScore.x = placement + 45 * scoreInt - 45 * Math.max(strCombo.length - 1, 2);
			numScore.screenCenter(Y).y += 80;

			numScore.acceleration.y = FlxG.random.int(200, 300);
			numScore.velocity.set(FlxG.random.float(-5, 5), -FlxG.random.int(140, 160));

			numScore.alpha = 1;
			// comboTweenManager.num(1, 0, 0.2, {
			comboTweenManager.tween(numScore, {alpha: 0}, 0.2, {
				onComplete: killTweenTarget,
				startDelay: Conductor.crochet / 1000.0
			// }, numScore.set_alpha);
			});
			numScore.ID = scoreGroup.ID++;

			groupShit(scoreGroup, numScore);
			// if (numScore.x > xThing)
			//	xThing = numScore.x;
		}
	}
	sortScoreGroup();
	// comboSpr.x = xThing + 50;
	// trace(combo);
}
var _sortByID = (Index, Obj1, Obj2) -> return Obj1.ID > Obj2.ID ? -Index : Obj2.ID > Obj1.ID ? Index : 0;
function sortScoreGroup() scoreGroup.sort(_sortByID);
function groupShit(group:FlxSpriteGroup, object:FlxObject)
{
	object._cameras = group._cameras;
	object.acceleration.x *= group.scale.x;
	object.acceleration.y *= group.scale.y;
	object.velocity.x *= group.scale.x;
	object.velocity.y *= group.scale.y;
	object.scale.x *= group.scale.x;
	object.scale.y *= group.scale.y;
	object.updateHitbox();
	object.x = (object.x + group.x) * group.scale.x;
	object.y = (object.y + group.y) * group.scale.y;
}