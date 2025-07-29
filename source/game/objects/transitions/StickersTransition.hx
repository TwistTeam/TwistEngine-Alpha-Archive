package game.objects.transitions;

import game.objects.openfl.FlxGlobalTween;
import flixel.addons.transition.FlxTransitionableState;
import flixel.group.FlxGroup;
import flixel.system.FlxAssets.FlxSoundAsset;
import flixel.util.FlxTimer;

import haxe.ds.StringMap;

@:access(flixel.FlxCamera)
class StickersTransition extends StateTransition
{
	public static var currentStickersFolder:String = "stickers-set-1"; // colors-stickers
	public static var currentStickerPack:String = "all";

	public var grpStickers:FlxTypedGroup<StickerSprite>;
	public var camera:FlxCamera;
	var stickerInfo:StickerInfo;
	var stickers:Map<String, Array<String>>;
	var _timerManager:FlxTimerManager;
	var maxSize:Int;

	// singleton yaaaaaaayy
	@:allow(game.objects.transitions.TransitionsGroup)
	function new(group:TransitionsGroup)
	{
		_timerManager = new FlxTimerManager();
		FlxG.signals.preStateSwitch.remove(_timerManager.clear);
		camera = new FlxCamera();
		camera.bgColor = 0x00000000;
		grpStickers = new FlxTypedGroup<StickerSprite>();
		grpStickers.camera = camera;
		super(group);
		// FlxG.game.addChild(camera.flashSprite);
		addChild(camera.flashSprite);
	}

	public function clearStickersGraphics()
	{
		grpStickers.forEach(i -> i.frames = null);
	}


	var _lastStickerPack:String = null;
	@:access(flixel.FlxSprite)
	public override function start(?onComplete:()->Void, duration:Float, isTransIn:Bool)
	{
		if (active) return;
		if (stickerInfo == null || stickerInfo.folderName != currentStickersFolder)
		{
			stickerInfo = new StickerInfo(currentStickersFolder);
			stickers = stickerInfo.getStickersPacks(_lastStickerPack = currentStickerPack);
		}
		else if (_lastStickerPack != currentStickerPack)
		{
			stickers = stickerInfo.getStickersPacks(_lastStickerPack = currentStickerPack);
		}
		_timerManager.clear();
		var sounds = [
			for (key in AssetsPaths.getFolderContent("sounds/stickersounds/", true))
				Assets.getSound("assets/" + key)
		];

		if (!isTransIn)
		{
			grpStickers.forEachAlive(spr -> spr.kill());

			final padding = 120;
			var xPos:Float = -padding;
			var yPos:Float = -padding;
			var maxWidth:Float = FlxG.width + padding;
			var maxHeight:Float = FlxG.height + padding;
			var deStickers:Array<String> = [];
			var i:UInt = 0;
			for (_ => pack in stickers)
			{
				if (pack == null) continue;
				deStickers.resize(deStickers.length + pack.length);
				for (str in pack)
				{
					deStickers[i++] = str;
				}
			}

			var randMapAngle:Array<Int> =  [for (_ in 0...32) FlxG.random.int(-60, 70)];
			var totalLength:Int = 0;
			var midHeight:Float = 0;
			var widthCount:Int = 1;
			var sticker:StickerSprite;
			while (xPos <= maxWidth)
			{
				sticker = grpStickers.recycle(StickerSprite);
				sticker.loadSticker(stickerInfo.folderName, FlxG.random.getObject(deStickers));
				sticker.visible = false;
				sticker.isLast = false;

				sticker.angle = randMapAngle[totalLength % randMapAngle.length];
				sticker.updateTrig();
				sticker.setPosition(xPos, yPos);
				xPos += (sticker.frameWidth * sticker._cosAngle - sticker.frameHeight * sticker._sinAngle) / 2.0;
				midHeight += (sticker.frameWidth * sticker._sinAngle + sticker.frameHeight * sticker._cosAngle) / 1.5;
				widthCount++;
				if (xPos >= maxWidth)
				{
					if (yPos <= maxHeight)
					{
						xPos = -100;
						midHeight /= widthCount;
						yPos += FlxG.random.float(midHeight * 0.58, midHeight);
						midHeight = 0;
						widthCount = 0;
					}
				}

				totalLength++;
			}

			FlxG.random.shuffle(grpStickers.members);

			// another damn for loop... apologies!!!
			i = 0;
			grpStickers.forEachAlive(sticker -> {
				sticker.timing = i / totalLength * 0.9;
				new FlxTimer(_timerManager).start(sticker.timing, _ -> {
					sticker.visible = true;
					// FlxG.sound.play(Paths.soundRandom("stickersounds/keyClick", 1, 8));
					playSound(FlxG.random.getObject(sounds) /*, FlxMath.remapToRange(sticker.timing, 0.0, 0.9, 0.2, 1.15)*/ );
					// FunkinSound.playOnce(FlxG.random.getObject(sounds)));

					new FlxTimer(_timerManager).start(1 / 24 * (sticker.isLast ? 2 : FlxG.random.int(0, 2)), _ -> {
						sticker.scale.x = sticker.scale.y = FlxG.random.float(0.97, 1.02);

						if (sticker.isLast)
						{
							finish();
						}
					});
				});
				i++;
			});

			grpStickers.sort((ord, a, b) -> return flixel.util.FlxSort.byValues(ord, a.timing, b.timing));

			// centers the very last sticker
			var lastOne:StickerSprite = grpStickers.getLast(spr -> return spr.exists && spr.alive);
			lastOne.angle = 0;
			lastOne.screenCenter();
			lastOne.isLast = true;
		}
		else
		{
			grpStickers.forEachAlive(sticker -> {
				new FlxTimer(_timerManager).start(sticker.timing, _ -> {
					sticker.visible = false;
					// FlxG.sound.play(Paths.soundRandom("stickersounds/keyClick", 1, 8));
					playSound(FlxG.random.getObject(sounds) /*, FlxMath.remapToRange(sticker.timing, 0.0, 0.9, 1.15, 0.2)*/ );
					// FunkinSound.playOnce(Paths.sound(FlxG.random.getObject(sounds)));

					sticker.kill();
					if (sticker.isLast)
					{
						finish();
					}
				});
			});
		}
		_onComplete = onComplete;
		_duration = Math.max(duration, FlxMath.EPSILON);
		_time = FlxTransitionableState.skipNextTransIn ? _duration : 0.0;

		active = true;
		visible = true;
		this.isTransIn = isTransIn;
		prepare(isTransIn);
	}

	static function playSound(soundSourse:FlxSoundAsset, pitch:Float = 1.0)
	{
		var sound = FlxG.sound.play(soundSourse);
		if (!sound.isValid()) return;
		sound.persist = true;
		sound.pitch = pitch;
		sound.onComplete = () -> sound.persist = false;
	}

	override function update()
	{
		camera.visible = visible;
		if (!visible) return;
		_time += FlxG.elapsed;
		_timerManager.update(FlxG.elapsed);
		grpStickers.update(FlxG.elapsed);
		camera.update(FlxG.elapsed);

		camera.clearDrawStack();
		camera.canvas.graphics.clear();

		grpStickers.draw();

		// camera.fill(camera.bgColor.to24Bit(), camera.useBgAlphaBlending, camera.bgColor.alphaFloat);
		// camera.drawFX();
		camera.render();
	}

	override function prepare(isTransIn:Bool)
	{
		camera.onResize();
	}

	override function finish()
	{
		active = false;
		if (_onComplete == null)
		{
			visible = false;
			scaleX = 1;
			scaleY = 1;
			x = y = 0;
		}
		else
		{
			if (_onComplete != null)
			{
				_onComplete();
				_onComplete = null;
			}
			if (StateTransition.finishCallback != null)
			{
				StateTransition.finishCallback();
				StateTransition.finishCallback = null;
			}
		}
	}

	override function onStateSwitched()
	{
		if (visible)
		{
			if (FlxTransitionableState.skipNextTransOut)
			{
				visible = false;
				FlxTransitionableState.skipNextTransOut = false;
			}
			else
			{
				start(StateTransition.transTime * 1.1, true);
			}
		}
	}
}

class StickerSprite extends FlxSprite
{
	public var isLast:Bool;
	public var timing:Float = 0;
	public function new():Void
	{
		super();
		// moves = active = false;
		moves = false;
		scrollFactor.set();
	}
	public function loadSticker(stickersFolder:String, stickerName:String)
	{
		loadGraphic(Paths.image('transitionSwag/$stickersFolder/$stickerName'));
		updateHitbox();
	}
}

class StickerInfo
{
	public var name:String;
	public var artist:String;
	public var stickers:Map<String, Array<String>>;
	public var stickerPacks:Map<String, Array<String>>;
	public var folderName:String;

	public function new(stickersFolder:String):Void
	{
		var jsonInfo:StickerShit = haxe.Json.parse(Assets.getText(AssetsPaths.getPath('images/transitionSwag/${folderName = stickersFolder}/stickers.json')));
		if (jsonInfo == null) return;

		this.name = jsonInfo.name;
		this.artist = jsonInfo.artist;

		stickers = [
			for (field in Reflect.fields(jsonInfo.stickers))
				field => cast Reflect.field(jsonInfo.stickers, field)
		];
		stickerPacks = [
			for (field in Reflect.fields(jsonInfo.stickerPacks))
				field => cast Reflect.field(jsonInfo.stickerPacks, field)
		];
	}

	public function getStickersPacks(packName:String):Map<String, Array<String>>
	{
		return [for (stickerSets in getPack(packName)) stickerSets => getStickers(stickerSets)];
	}

	public inline function getPack(packName:String):Array<String>
	{
		return this.stickerPacks[packName];
	}

	public inline function getStickers(stickerName:String):Array<String>
	{
		return this.stickers[stickerName];
	}
}

// somethin damn cute just for the json to cast to!
typedef StickerShit =
{
	name:String,
	artist:String,
	stickers:StringMap<Array<String>>,
	stickerPacks:StringMap<Array<String>>
}