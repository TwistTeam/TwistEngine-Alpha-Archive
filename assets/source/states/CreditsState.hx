import flixel.FlxObject;
import flixel.group.FlxTypedGroup;
import flixel.text.FlxText.*;
import flixel.text.FlxText;
import flixel.util.FlxAxes;
import game.backend.system.states.MusicBeatState;
import game.objects.Alphabet;
import game.objects.MeshRender;
import game.objects.improvedFlixel.FlxFixedText;
import openfl.Vector;

using game.backend.utils.FlxObjectTools;
using StringTools;

static var baseCreditsData = [
	{
		name: "Twist Crew",
		canSelect: false,
		childs: [
			{
				name: "Redar13",
				icon: "credits/redar.png",
				urls: ["https://x.com/Redar13176784"],
				description: "Main Director and main programmer",
				color: 0xFF3F3F3F
			},
			{
				name: "ItzRanbins",
				icon: "credits/itzranbins.png",
				urls: ["https://x.com/itz_ranbins"],
				description: "CO-Main Director, concepter, sound director, and he likes to come up with very cool things.",
				color: 0xFFFF3838
			}
		]
	},
	{
		name: "Special Thanks",
		canSelect: false,
		childs: [
			{
				name: "Lenya the cat",
				icon: "credits/leonid.png",
				urls: ["https://t.me/geroinpesherny"],
				description: "Logo artist",
				color: 0xFFCA6D6D
			},
			{
				name: "richTrash21",
				icon: "credits/rich.png",
				urls: ["https://github.com/richTrash21"],
				description: "Code assistance, improving flixel and psych engine code.",
				color: 0xFF5F9276
			},
			{
				name: "PurSnake",
				icon: "credits/pursnake.png",
				urls: ["https://x.com/pursnake"],
				description: "Code assistance",
				color: 0xFF593B7E,
			},
			{
				name: "Psenkos",
				icon: "credits/psenkos.png",
				urls: ["https://x.com/Psenkoks"],
				description: "Make design for Twist Tan mascot(real).",
				color: 0xFF8D8D8D
			},
			{
				name: "Sweet Mei",
				// icon: "credits/psenkos.png",
				urls: ["https://www.youtube.com/@SweetMeichka"],
				description: "Helped with the design of Twist Tan",
				color: 0xFFF35A8D
			},
			{
				name: "TarnSpill",
				icon: "credits/tarnspill.png",
				urls: ["https://t.me/tarntoxicwaste"],
				description: "Draw a pixelated app icon.",
				color: 0xFFB56BFF
			},
			{
				name: "Sector",
				icon: "credits/sector.png",
				urls: ["https://x.com/sectorrrb"],
				description: "Helped with the port to Android, what a surprise.",
				color: 0xFF3851DE,
			},
			{
				name: "Codename Engine Devs",
				urls: ["https://x.com/FNFCodenameEG"],
				description: "Improved hscript and some code.",
				color: 0xFFD486E7
			},
			{
				name: "FNF' Colors Adventure",
				icon: "credits/fnfca.png",
				urls: ["https://x.com/FNFCAdventure"],
				description: "The engine's progenitor",
				color: 0xFFFFC53F
			},
			{
				name: "5 Rubles 12 Kopecks",
				icon: "credits/5rubles.png",
				urls: ["https://www.youtube.com/@5rubles_crew"],
				description: "Development of the engine idea",
				color: 0xFFE84242
			}
		]
	}
];

static var curSelected:Int = 0;
static var _checkEreg = AssetsPaths.IMAGE_REGEX;

class CreditsText extends FlxFixedText
{
	public var myIcon:FlxSprite;
	public function toString()
	{
		return '${(myData?.name ?? "N/A")}   ${super.toString()}';
	}

	public function new(x, y, data)
	{
		myData = data;
		super(x, y, 0., data.name);
		setFormat(Paths.font('VCR OSD Mono Cyr.ttf'), 40, data.canSelect != false ? 0xffd3d3d3 : 0xffffffff);
		Std.string(this);
		origin.x = 0;

		if (data.icon != null && data.icon.trim() != "")
		{
			if (_checkEreg.match(data.icon))
			{
				myIcon = new FlxSprite(0, 0, Paths.image("icons/" + data.icon));
				myIcon.scale.set(0.4, 0.4);
				myIcon.updateHitbox();
			}
			else
			{
				myIcon = new HealthIcon(data.icon);
				myIcon.scale.x = myIcon.scale.y = myIcon.baseScale * (myIcon.data?.scale ?? 1) * 0.4;
				myIcon.updateHitbox();
				myIcon.updateHealth(50);
			}
		}
	}

	var myData;
	var _isSelected:Bool = false;
	var _tweenCol;
	var _tweenScale;

	public function draw()
	{
		if (myIcon != null)
		{
			myIcon.setPosition(x + frameWidth * scale.x + 10, y - (myIcon.frameHeight * myIcon.scale.y - frameHeight * scale.y) / 2);
			super.draw();
			if (myIcon.isOnScreen())
			{
				myIcon.updateOffsets();
				myIcon.draw();
			}
		}
		else
		{
			super.draw();
		}
	}

	public function destroy()
	{
		super.destroy();
		myIcon?.destroy();
	}

	public function updateSelected(isSelected:Bool)
	{
		if (_isSelected != isSelected)
		{
			_isSelected = isSelected;
			_tweenCol?.cancel();
			_tweenScale?.cancel();
			var startColor = color;
			var colorDuration = isSelected ? 0.4 : 0.2;
			var scaleDuration = isSelected ? 0.3 : 0.5;
			var scaleNum = isSelected ? 1.1 : 1.0;
			var colorFunc = FlxColor.interpolate.bind(startColor, isSelected ? 0xffffff00 : 0xffd3d3d3, _);
			_tweenCol = FlxTween.num(0, 1, colorDuration, {ease: FlxEase.cubeOut}, i -> color = colorFunc(i));
			_tweenScale = FlxTween.tween(scale, {x: scaleNum, y: scaleNum}, scaleDuration, {ease: FlxEase.cubeOut});
		}
	}
}

var grpCredits:FlxTypedGroup;
var bgSpr:FlxSprite;
var leftBGSpr:MeshRender;
var rightBGSpr:MeshRender;
var descText:FlxText;
var intendedColor:Int;
var colorTween:FlxTween;
var validToScroll:Bool = false;
var datas = [];
var curData;
var camFollow:FlxObject;
var arrowSpr:FlxSprite;
var arrowSprScale:Float;
var arrowSprOffsetX:Float;
var creditsTitleSpr:FlxSprite;
var descBg:FlxSprite;

function create()
{
	bgSpr = new FlxSprite(0, 0, Paths.image('creditsDesat'));
	bgSpr.screenCenter();
	bgSpr.active = false;
	bgSpr.scrollFactor.set();
	add(bgSpr);

	intendedColor = 0xFFDADADA;
	bgSpr.color = intendedColor;

	leftBGSpr = new MeshRender(0, 0, 0x7d000000);
	leftBGSpr.build_tri(0, 0, 249.95, 0, 620.75, FlxG.height / 2);
	leftBGSpr.build_quad(0, 0, 620.75, FlxG.height / 2, 249.95, FlxG.height, 0, FlxG.height);
	leftBGSpr.active = false;
	leftBGSpr.scrollFactor.set();
	add(leftBGSpr);

	rightBGSpr = new MeshRender(0, 0, 0x7d000000);
	rightBGSpr.build_tri(FlxG.width, 45.6, 606.7, FlxG.height, FlxG.width, FlxG.height);
	rightBGSpr.active = false;
	rightBGSpr.scrollFactor.set();
	add(rightBGSpr);

	add(grpCredits = new FlxTypedGroup());
	add(camFollow = new FlxObject(0, 0, 1, 1));

	creditsTitleSpr = new FlxSprite(FlxG.width - 350, 20);
	creditsTitleSpr.frames = Paths.getSparrowAtlas('mainmenu/menu_credits');
	creditsTitleSpr.animation.addByPrefix('credits', 'credits white', 24, true);
	creditsTitleSpr.animation.play('credits');
	creditsTitleSpr.setGraphicSize(300);
	creditsTitleSpr.updateHitbox();
	creditsTitleSpr.scrollFactor.set();
	add(creditsTitleSpr);

	descBg = new FlxSprite().makeSolid(1, 1, FlxColor.BLACK);
	descBg.alpha = 0.6;
	descBg.scrollFactor.set();
	descBg.visible = false;
	add(descBg);

	descText = new FlxText(0, 0, FlxG.width * 0.4, "", 24);
	descText.setFormat(Paths.font('VCR OSD Mono Cyr.ttf'), 24, FlxColor.WHITE, "right");
	descText.scrollFactor.set();
	add(descText);

	arrowSpr = new FlxSprite();
	arrowSpr.frames = Paths.getSparrowAtlas('campaign_menu_UI_assets');
	arrowSpr.animation.addByPrefix('idle', "arrow left", 0, true);
	arrowSpr.setGraphicSize(18);
	arrowSpr.updateHitbox();
	arrowSpr.centerOffsets();
	arrowSprOffsetX = arrowSpr.offset.x;
	arrowSprScale = arrowSpr.scale.x;
	arrowSpr.animation.play('idle');
	add(arrowSpr);
	var arrowColor = FlxColor.YELLOW;
	arrowSpr.setColorTransform(0, 0, 0, 1,
		arrowColor >> 16 & 0xff,
		arrowColor >> 8 & 0xff,
		arrowColor & 0xff,
		0);

	FlxG.camera.follow(camFollow);
	FlxG.camera.targetOffset.set(FlxG.camera.viewWidth / 2, 40);
	FlxG.camera.followLerp = 1 / 5;
	generateGuys();
}

function generateGuys()
{
	grpCredits.forEach(i -> i.destroy());
	grpCredits.clear();
	while (datas.length > 0)
	{
		datas.pop();
	}
	validToScroll = false;
	var alphabetText:CreditsText;
	var i:Int;
	var xOffset:Int = -5;
	var curY:Int = 640;
	var _generateStuff;
	_generateStuff = function(stuff)
	{
		xOffset += 20;
		for (_i => data in stuff)
		{
			if (data == null)
			{
				stuff.splice(_i, 1);
				continue;
			}
			if (data.canSelect == false)
				curY += 20;
			if (!validToScroll)
				validToScroll = data.canSelect == null || data.canSelect == true;
			alphabetText = new CreditsText(xOffset, curY, data);
			alphabetText.ID = i;

			if (data.canSelect == false) {
				alphabetText.size = 55;
				alphabetText.updateHitbox();
			}

			grpCredits.add(alphabetText);
			datas.push(data);
			i++;
			curY += 55;
			if (data.childs != null && data.childs.length > 0)
				_generateStuff(data.childs);
		}
		xOffset -= 20;
	}
	_generateStuff(baseCreditsData);

	if (validToScroll)
		changeItem(0, true);
	else if (grpCredits.length > 0)
	{
		camFollow.setPosition(0, grpCredits.members[0].y + grpCredits.members[0].height);
	}
}

var allowControls:Bool = true;

function preUpdate(elapsed)
{
	if (allowControls && subState == null)
	{
		if (controls.BACK)
		{
			allowControls = false;
			FlxG.sound.play(Paths.sound('cancelMenu'));
			MusicBeatState.switchState(new MainMenuState());
		}
		if (validToScroll)
		{
			if (FlxG.mouse.wheel != 0)
				changeItem(-FlxMath.signOf(FlxG.mouse.wheel));
			else
			{
				if (controls.UI_UP_P)
					changeItem(-1);
				if (controls.UI_DOWN_P)
					changeItem(1);
			}
			if (curData != null && controls.ACCEPT)
			{
				var url = curData.urls[0];
				if (url != null && url.trim() != "") {
					#if linux
					Sys.command('/usr/bin/xdg-open', [url]);
					#else
					FlxG.openURL(url);
					#end
				}
			}
		}
	}
}

var _arrowTweenScale;
function changeItem(huh:Int = 0, ?snap:Bool)
{
	var textSpr = grpCredits.members[curSelected];
	if (textSpr != null)
	{
		textSpr.updateSelected(false);
	}
	do
	{
		curSelected = FlxMath.wrap(curSelected + huh, 0, grpCredits.length - 1);
		curData = datas[curSelected];
		huh = FlxMath.signOf(huh);
	}
	while (curData == null || curData.canSelect == false);

	if (curData != null)
	{
		var targetColor:Int = 0xFF808080;
		if (curData.color != null)
		{
			targetColor = curData.color;
		}
		else if (textSpr?.myData?.color != null)
		{
			targetColor = textSpr.myData.color;
		}

		intendedColor = targetColor;
		if(colorTween != null) {
			colorTween.cancel();
		}
		colorTween = FlxTween.color(bgSpr, 0.25, bgSpr.color, intendedColor);
	}

	textSpr = grpCredits.members[curSelected];
	if (textSpr != null)
	{
		textSpr.updateSelected(true);
		camFollow.setPosition(0, textSpr.y + textSpr.height);
		arrowSpr.setPosition(textSpr.x + textSpr.frameWidth * 1.15, textSpr.y - (arrowSpr.height - textSpr.height) / 2);

		if (textSpr.myIcon != null)
		{
			var scaleIcon;
			if (Std.isOfType(textSpr.myIcon, HealthIcon))
			{
				scaleIcon = textSpr.myIcon.baseScale * (textSpr.myIcon.data?.scale ?? 1) * 0.4;
			}
			else
			{
				scaleIcon = 0.4;
			}
			arrowSpr.setPosition(arrowSpr.x + textSpr.myIcon.frameWidth * scaleIcon * 1.15, arrowSpr.y);
		}

		if (curData.description != null) {
			descText.text = curData.description;
			descText.x = FlxG.width - descText.width - 40;
			descText.y = FlxG.height - descText.height - 40;
			descBg.visible = true;
			descBg.setPosition(descText.x - 10, descText.y - 10);
			descBg.makeSolid(Std.int(descText.width + 20), Std.int(descText.height + 20), FlxColor.BLACK);
		} else {
			descText.text = "";
			descBg.visible = false;
		}

		_arrowTweenScale?.cancel();
		var _offsetX = arrowSpr.offset.x = arrowSprOffsetX - arrowSprScale * arrowSpr.width - 6;
		var _scaleX = arrowSpr.scale.x = arrowSprScale * 1.75;
		var _scaleY = arrowSpr.scale.y = arrowSprScale * 0.35;
		_arrowTweenScale = FlxTween.num(0, 1, 1, {ease: FlxEase.elasticOut}, i -> {
			arrowSpr.scale.x = FlxMath.lerp(_scaleX, arrowSprScale, i);
			arrowSpr.scale.y = FlxMath.lerp(_scaleY, arrowSprScale, i);
			arrowSpr.offset.x = FlxMath.lerp(_offsetX, arrowSprOffsetX, i);
		});

		if (snap)
			FlxG.camera.snapToTarget();
	}
	if (huh != 0)
		FlxG.sound.play(Paths.sound('scrollMenu'));
}