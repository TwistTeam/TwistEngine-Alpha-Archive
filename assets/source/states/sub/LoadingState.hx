import game.objects.improvedFlixel.FlxFixedText;
import flixel.tweens.FlxEase;
import flixel.text.FlxTextAlign;

var defaultStatsText:FlxFixedText;
var icon:FlxSprite;
var defaultIconScale:Float;

function create()
{
	#if desktop
	DiscordClient.changePresence("In the loading screen");
	#end
	var isDog = FlxG.random.bool(3);
	// setup default loading screen
	icon = new FlxSprite(0, 0, Paths.image(isDog ? "dog" : "loadingIcon"));
	icon.setGraphicSize(Math.min(FlxG.width, icon.width));
	icon.screenCenter();
	if (!isDog)
	{
		icon.origin.set(237, 288);
		icon.x += icon.width / 2 - icon.origin.x;
		icon.y += icon.height / 2 - icon.origin.y + 70;
	}
	defaultIconScale = icon.scale.x;
	add(icon);

	var duraction = 1.5;
	FlxTween.num(-10, 10, duraction, {ease: FlxEase.sineInOut, type: PINGPONG}, icon.set_angle);
	// icon.angularVelocity = 20;

	defaultStatsText = new FlxFixedText(0, 0, 0, "huh?", 24);
	defaultStatsText.alignment = FlxTextAlign.CENTER;
	add(defaultStatsText);
}

var maxScale = 0.5;
var _bopTimer:Float = 0;
function preUpdate(elapsed:Float)
{
	// _bopTimer = CoolUtil.fpsLerp(_bopTimer, 0, 1.2 / 60);
	_bopTimer = Math.max(_bopTimer - elapsed * 1.2, 0);
	if (controls.ACCEPT)
		_bopTimer = 1.0 + _bopTimer / 10.0;

	var easPerc = (1.0 - FlxEase.elasticOut(1 - _bopTimer)) * maxScale;
	icon.scale.set(defaultIconScale * (1 + easPerc), defaultIconScale * (1 - easPerc));

	var daText = '${callbacks.length - callbacks.numRemaining} / ${Std.string(callbacks.length)}\nCurrent Asset Load:\n' + (callbacks?.curID ?? "|X|");
	if (daText != defaultStatsText.text)
	{
		defaultStatsText.text = daText;
		defaultStatsText.screenCenter(X);
		defaultStatsText.y = FlxG.height - defaultStatsText.height - 20;
	}
}
function onProgress(loaded:Int, ?length:Null<Int>)
{
	icon.alpha = loaded / (length ?? -1);
}

function onLoaded()
{
	if (!transitioning && canLeave)
	{
		funcsPrepare.clearArray();

		ClientPrefs.cacheOnGPU = oldGPUCacheAllowed;
		#if desktop
		DiscordClient.changePresence();
		#end
		onComplete(this);
		transitioning = true;
	}
}