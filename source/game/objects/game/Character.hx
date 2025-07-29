package game.objects.game;

import flixel.graphics.frames.FlxFramesCollection;
import flixel.math.FlxPoint;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxDestroyUtil;
import flixel.util.FlxStringUtil;

import game.backend.system.song.Conductor.mainInstance as Conductor;
import game.backend.utils.ShadersData;
import game.objects.FunkinSprite;

import haxe.Json;
import haxe.extern.EitherType;
import openfl.Vector;
import openfl.utils.Assets;

abstract GameOverProperties(Array<EitherType<String, Float>>) from Array<EitherType<String, Float>> to Array<EitherType<String, Float>>
{
	public var char(get, set):String;
	inline function get_char()			return this[0] ?? "bf-dead";
	inline function set_char(i)			return this[0] = i;
	public var startSound(get, set):String;
	inline function get_startSound()	return this[1] ?? "fnf_loss_sfx";
	inline function set_startSound(i)	return this[1] = i;
	public var music(get, set):String;
	inline function get_music()			return this[2] ?? "gameOver";
	inline function set_music(i)		return this[2] = i;
	public var confirmSound(get, set):String;
	inline function get_confirmSound()	return this[3] ?? "gameOverEnd";
	inline function set_confirmSound(i)	return this[3] = i;
	public var bpm(get, set):Float;
	inline function get_bpm()			return this[4] ?? 100;
	inline function set_bpm(i)			return this[4] = i;
	public inline function new(?char:String, ?startSound:String, ?music:String, ?confirmSound:String, ?bpm:Null<Float>)
	{
		this = [char, startSound, music, confirmSound, bpm];
	}
}

typedef CharacterFile =
{
	animations:Array<AnimArray>,
	image:String,
	scale:Float,
	sing_duration:Float,
	healthicon:String,

	position:Array<Float>,
	camera_position:Array<Float>,
	healthbar_colors:DynamicColor,
	?extra_data:Dynamic,
	?flip_x:Bool,
	?flip_y:Bool,
	?no_antialiasing:Bool,

	?beatDance:Int,
	?shader:String,
	?forceDance:Bool,
	?forceSing:Null<Bool>,
	?fixFlip:Bool,
	?gameover_properties:GameOverProperties
}

typedef AnimArray =
{
	anim:String,
	name:String,
	?fps:Null<Float>,
	?loop:Bool,
	?indices:Array<Int>,
	?offsets:Array<Float>,

	?loopPoint:Int,
	?flipX:Bool,
	?flipY:Bool
}

enum abstract CharacterStatus(UByte) from UByte to UByte
{
	var DEBUG = 0x00;
	var IDLE = 0x01;
	var HOLD_SING = 0x10;
	var SINGLE_SING = 0x11;
	var SPECIAL_ANIM = 0xFF;

	@:to function toString():String
	{
		return switch (this)
		{
			case IDLE: "IDLE";
			case HOLD_SING: "HOLD_SING";
			case SINGLE_SING: "SINGLE_SING";
			case SPECIAL_ANIM: "SPECIAL_ANIM";
			default: "DEBUG";
		}
	}

	@:from static function fromString(s:String):CharacterStatus
	{
		return switch (s.toLowerCase().replace(" ", "").replace("_", ""))
		{
			case "idle": IDLE;
			case "holdsing": HOLD_SING;
			case "specialanim": SPECIAL_ANIM;
			case "sing" | "singlesing": SINGLE_SING;
			default: DEBUG;
		}
	}
}

@:access(flxanimate.animate)
class Character extends FunkinSprite
{
	public static function resolveCharacterData(filePath:String, ?ignoreDefault:Bool, ?disableAlert:Bool):CharacterFile
	{
		var data:CharacterFile = null;
		var path:String = 'characters/$filePath.json';
		try
		{
			if (Assets.exists(path))
			{
				data = cast Json.parse(Assets.getText(path));
				if (data == null) throw "Null Object Reference";
			}
			else
			{
				throw "File doesn't exist";
			}
		}
		catch(e)
		{
			if (!ignoreDefault)
			{
				// If a character couldn't be found, change him to BF just to prevent a crash
				data = cast Json.parse(Assets.getText('characters/${Constants.DEFAULT_CHARACTER}.json'));

				if (data == null)
					throw 'Null Object Reference on \'${Constants.DEFAULT_CHARACTER}\', somehow';
				#if HAXE_UI
				if (ClientPrefs.displErrs && !disableAlert)
				{
					var sound = FlxG.sound.load(Paths.sound("ANGRY_TEXT_BOX"));
					if (sound != null && sound.isValid())
					{
						sound.play(true);
						sound.useTimeScaleToPitch = false;
					}
					Log('Error on load character file \'$filePath\': ' + e.message, RED);

					lime.app.Application.current.onUpdate.add((deltaTime:Int) -> {
						haxe.ui.notifications.NotificationManager.instance.addNotification({
							title: 'Error on load character file \'$filePath\':\n' + e.message,
							body: e.details(),
							expiryMs: 10000,
							type: Error
						});
					}, true);
				}
				#end
			}
		}
		return data;
	}

	/**
	 * Silly
	 */
	public static function precasheCharacter(char:String, ?ignoreDefault:Bool)
	{
		final json:CharacterFile = resolveCharacterData(char, ignoreDefault);
		if (json != null)
		{
			for (i in json.image.replace(",", ";").split(";"))
				Paths.getAtlas(i.trim());
			// Paths.getAtlas("icons/" + json.healthicon);
		}
	}

	public var status:CharacterStatus = IDLE;
	public var debugMode(get, set):Bool;

	public var isPlayer:Bool = false;
	public var curCharacter(default, null):String = "";

	public var gameoverProperties:GameOverProperties;
	public var holdTimer:Float = 0;
	public var heyTimer:Float = 0;
	public var specialAnim(get, set):Bool;
	// public var animationNotes:Array<Dynamic>;
	public var stunned:Bool = false;
	public var fixFlip:Bool = false;
	public var singDuration:Float = 4.1; // Multiplier of how long a character holds the sing pose
	public var useSingDurationOnMiss:Bool = true;
	public var idleSuffix(default, set):String = "";

	static final _eregHold = ~/\-hold(?:End)?$/;
	function set_idleSuffix(e:String):String
	{
		danceFewDance = hasAnimation("dance0" + e) && hasAnimation("dance1" + e);
		danceIdle = danceFewDance || hasAnimation("danceLeft" + e) && hasAnimation("danceRight" + e);
		skipDance = !(hasAnimation("idle" + e) || danceIdle || danceFewDance);
		holdAnims = false;
		holdEndAnims = false;
		for (name in animOffsets.keys())
		{
			if (name.startsWith(singAnimsPrefix) && _eregHold.match(name))
			{
				holdAnims = true;
				holdEndAnims = holdEndAnims || name.endsWith("End");
				// holdMissAnims = name.contains("miss");
				// if (holdAnims && holdMissAnims) break;
				if (holdAnims && holdEndAnims)
					break;
			}
		}
		return idleSuffix = e;
	}

	public var holdAnims:Bool = false;
	public var holdEndAnims:Bool = false;
	// public var holdMissAnims:Bool = false;
	public var danceIdle:Bool = false; // Character use "danceLeft" and "danceRight" instead of "idle"
	public var danceFewDance:Bool = false; // Character uses "dance0", "dance1" and others, ignoring danceIdle
	public var nextDance(default, null):Int = 0; // Character uses for "dance0", "dance1" and others
	public var skipDance:Bool = false;

	public var healthIcon:String = "face";
	public var shaderName:String = "";
	public var animationsArray:Array<AnimArray> = [];

	public var positionOffsets:FlxPoint;
	public var cameraPos:FlxPoint;
	public var singAnimsPrefix:String = "sing";

	// DEPRECATED!!!
	public var positionArray(get, set):Array<Float>;
	public var cameraPosition(get, set):Array<Float>;

	inline function get_positionArray():Array<Float>
		return [positionOffsets.x, positionOffsets.y];

	inline function get_cameraPosition():Array<Float>
		return [cameraPos.x, cameraPos.y];

	function set_positionArray(a:Array<Float>):Array<Float>
	{
		if (a != null && a.length > 1)
			positionOffsets.set(a[0], a[1]);
		return a;
	}

	function set_cameraPosition(a:Array<Float>):Array<Float>
	{
		if (a != null && a.length > 1)
			cameraPos.set(a[0], a[1]);
		return a;
	}

	public var danceEveryNumBeats:Int = 2;
	public var beatDanceJson:Int = 2;
	public var forceDance:Bool = false;
	public var forceSing:Bool = true;

	public var curCameraPos:FlxPoint;
	public var hasMissAnimations(default, null):Bool = false;

	public var imageFile:String = "";
	public var jsonScale:Float = 1;
	public var noAntialiasing:Bool = false;
	public var originalFlipX:Bool = false;
	public var originalFlipY:Bool = false;
	public var healthColor:FlxColor;
	public var healthColorArray(get, never):Array<Int>;

	inline function get_healthColorArray()
		return [healthColor.red, healthColor.green, healthColor.blue];

	public override function destroy()
	{
		flixel.util.FlxDestroyUtil.putArray([positionOffsets, cameraPos, curCameraPos]);
		if (animationsArray != null)
			animationsArray.clearArray();
		animationsArray = null;
		_extraData = null;
		super.destroy();
	}

	public function new(x:Float, y:Float, ?character:String = "bf", ?isPlayer:Bool = false)
	{
		super(x, y);
		positionOffsets = FlxPoint.get();
		cameraPos = FlxPoint.get();
		curCameraPos = FlxPoint.get();
		this.isPlayer = isPlayer;
		__reloadCharater(character);
	}

	public function getCameraPosition():FlxPoint
	{
		return (useAtlas ? curCameraPos.set(x, y) : getMidpoint(curCameraPos))
				.subtractPoint(offset)
			.add(isPlayer ? -cameraPos.x : cameraPos.x, cameraPos.y);
	}

	public function switchCharater(char:String, allowGPU:Bool = true)
	{
		__reloadCharater(char, allowGPU);
	}

	function __reloadCharater(char:String, allowGPU:Bool = true)
	{
		if (char == curCharacter)
			return;
		final json:CharacterFile = resolveCharacterData(char);
		if (json == null)
		{
			Log('Warn: "$char" doesn\'t loaded!', RED);
			return;
		}
		if (char == "none")
		{
			healthIcon = "none";
			debugMode = true;
			active = visible = dirty = false;
		}

		// reset data
		curCharacter = char;
		hasMissAnimations = specialAnim = skipDance = danceIdle = stunned = false;
		settingCharacterUp = true;
		holdTimer = heyTimer = 0;
		@:bypassAccessor idleSuffix = "";

		final oldAnim = curAnimName;
		final oldFrame = curFrame;

		animationsArray.clear();

		var newImageFile = json.image;
		if (newImageFile != null)
		{
			newImageFile = newImageFile.replace(";", ",");
			if(imageFile != newImageFile)
			{
				loadFrames(newImageFile);
			}
		}
		imageFile = newImageFile;

		jsonScale = json.scale;
		scale.x = scale.y = jsonScale;
		updateHitbox();

		positionArray = json.position;

		singAnimsPrefix = "sing";

		healthIcon = json.healthicon;
		singDuration = json.sing_duration;

		gameoverProperties = json.gameover_properties;
		if (gameoverProperties != null && gameoverProperties.char == "#self" && !debugMode)
			gameoverProperties.char = curCharacter;

		// antialiasing
		noAntialiasing = json.no_antialiasing;
		antialiasing = !noAntialiasing;

		healthColor = json.healthbar_colors?.getColorFromDynamic() ?? (isPlayer ? FlxColor.LIME : FlxColor.RED);

		hasMissAnimations = false;
		animationsArray = json.animations ?? [];
		if (animationsArray.length > 0)
		{
			for (anim in animationsArray)
			{
				addAnimation(anim.anim, anim.name, anim.indices, anim.offsets, anim.fps, anim.loopPoint, anim.loop, anim.flipX, anim.flipY);
				hasMissAnimations = hasMissAnimations || (anim.anim.startsWith("sing") && anim.anim.contains("miss"));
			}
		}
		else
		{
			addAnimation("idle", "BF idle dance");
		}

		if (json.shader == null || json.shader.trim().length == 0)
		{
			shaderName = "";
			shader = null;
		}
		else
		{
			shaderName = json.shader;
			shader = ShadersData.createRuntimeShader(json.shader);
		}

		_extraData = json.extra_data;

		fixFlip = json.fixFlip;
		forceDance = json.forceDance;
		forceSing = json.forceSing ?? true;
		originalFlipX = flipX = json.flip_x;
		originalFlipY = flipY = json.flip_y;

		if (isPlayer)
		{
			flipX = !flipX;
			if (fixFlip)
				flipLeftRight();
		}

		updateFlip();
		recalculateDanceIdle();

		var tempBeatDance:Int = Std.int(json.beatDance);
		if (Math.isNaN(tempBeatDance) || tempBeatDance == 0)
			tempBeatDance = (danceIdle ? 1 : 2);
		danceEveryNumBeats = beatDanceJson = tempBeatDance;

		trace("Loaded file to character " + curCharacter);

		if (debugMode || oldAnim == null || !hasAnimation(oldAnim))
			dance();
		else
			playAnim(oldAnim, true, oldFrame);
		offset.set(-positionOffsets.x, -positionOffsets.y);
		cameraPosition = json.camera_position;
	}
	public override function loadFrames(path:String)
	{
		var deImages = [];
		for (i in path.split(","))
		{
			i = i.trim();
			if (!deImages.contains(i))
				deImages.push(i);
		}
		trace(deImages);
		toggleAtlas = atlasIsValid = false;
		if (deImages.length > 1)
		{
			frames = AssetsPaths.getMultipleFrames(deImages);
		}
		else
		{
			super.loadFrames(path);
		}
	}

	public function updateFlip(?idk:Bool)
	{
		final a = idk ?? isPlayer;
		altFlipX = fixFlip && a;

		// flipOffsetX = fixFlip && a;
		// altFlipX = fixFlip && (a || (flipX != originalFlipX));
	}

	public function flipLeftRight()
	{
		if (debugMode || animationsArray.length < 2) return;
		function replaceAnim(anim:AnimArray, nextAnim:String)
		{
			var oldName = anim.name;
			anim.anim = nextAnim;
			if(hasAnimation(anim.name)) removeAnimation(oldName);

			addAnimation(anim.anim, anim.name, anim.indices, anim.offsets, anim.fps, anim.loopPoint, anim.loop, anim.flipX, anim.flipY);
		}
		for (anim in animationsArray)
		{
			var animName = anim.anim;
			if (animName.indexOf("singRIGHT") != -1){
				replaceAnim(anim, animName.replace("singRIGHT", "singLEFT"));
			}else if (animName.indexOf("singLEFT") != -1){
				replaceAnim(anim, animName.replace("singLEFT", "singRIGHT"));
			}
		}
	}
	public static function sortAnims(anims:Array<AnimArray>)
	{
		anims.sort(function(a, b)
		{
			if (a.anim < b.anim)
				return -1;
			if (a.anim > b.anim)
				return 1;
			return 0;
		});
		return anims;
	}

	public function getJson(?useFilter:Bool = true)
	{
		// Character.sortAnims(animationsArray);
		var data:CharacterFile = {
			animations: useFilter ? [for (i in animationsArray) Character.filterAnimArray(i)] : animationsArray,
			image: imageFile,
			scale: jsonScale,
			sing_duration: singDuration,
			healthicon: healthIcon,
			healthbar_colors: healthColorArray,
			position: positionArray,
			camera_position: cameraPosition,

			flip_x: originalFlipX,
			flip_y: originalFlipY,
			no_antialiasing: noAntialiasing,
			beatDance: danceEveryNumBeats,
			shader: shaderName,
			forceDance: forceDance,
			forceSing: forceSing,
			extra_data: _extraData,
			fixFlip: fixFlip,
			gameover_properties: gameoverProperties
		}
		return data = useFilter ? CoolUtil.filterTypedef(data, [
			"flip_x" => false,
			"flip_y" => false,
			"fixFlip" => false,
			"gameover_properties" => [],
			"gameover_properties " => null,
			"no_antialiasing" => false,
			"shader" => "",
			"forceDance" => false,
			"forceSing" => true,
			"forceSing " => null,
			"extra_data" => [],
			"extra_data " => null,
		]) : data;
	}

	public static function filterAnimArray(anim:AnimArray):AnimArray
		return CoolUtil.filterTypedef(anim, [
			"flipX" => false,
			"flipY" => false,
			"loop" => false,
			"loopPoint" => 0,
			"fps" => 24,
			"indices" => [],
			"indices " => null,
			"offsets" => [0, 0],
			"offsets " => [],
			"offsets  " => null,
		]);

	public function updateFlxAnimation(animArray:AnimArray)
	{
		var anim = animation.getByName(animArray.anim);
		if (anim != null)
		{
			anim.flipX = animArray.flipX;
			anim.flipY = animArray.flipY;
			anim.frameRate = animArray.fps;
			/*if (animArray.loopPoint != null)*/ anim.loopPoint = Std.int(animArray.loopPoint);
		}
	}

	@:noCompletion var _curAnimName = "";

	override function update(elapsed:Float)
	{
		if (debugMode)
		{
			super.update(elapsed);
			return;
		}
		_curAnimName = curAnimName; // don't spam get function
		if (heyTimer > 0)
		{
			heyTimer -= elapsed * FlxG.animationTimeScale;
			if (heyTimer <= 0)
			{
				// if (specialAnim && _curAnimName == "hey"){
				if (specialAnim && _curAnimName == "hey" || _curAnimName == "cheer")
				{
					status = IDLE;
					dance();
				}
				heyTimer = 0;
			}
		}
		else
		{
			switch (status)
			{
				case SPECIAL_ANIM:
					if (finishedAnim)
					{
						status = IDLE;
						dance();
					}
				case SINGLE_SING | HOLD_SING:
					holdTimer += elapsed;
					if (singDuration == 0 || (!useSingDurationOnMiss && _curAnimName.contains("miss")))
					{
						if (finishedAnim && holdTimer > Conductor.stepCrochet * 0.0011)
						{
							status = IDLE;
							dance();
							holdTimer = 0;
						}
					}
					else if (holdTimer > Conductor.stepCrochet * 0.0011 * singDuration)
					{
						status = IDLE;
						dance();
						holdTimer = 0;
					}
				default:
			}
		}
		if (finishedAnim && hasAnimation('$_curAnimName-loop'))
			playAnim('$_curAnimName-loop');
		super.update(elapsed);
		// if (_curAnimName.startsWith("hold")){
		// 		if(_curAnimName.endsWith("Start") && finishedAnim){
		// 			var newName = _curAnimName.substring(0,_curAnimName.length-5);
		// 			var singName = "sing" + _curAnimName.substring(3, _curAnimName.length-5);
		// 			playAnim(hasAnimation(newName) ? newName : singName,true);
		// 		}
		// }else if(holding){
		// 	curFrame=0;
		// }
	}

	var _danceLeft:Bool = false;

	public function dance(?forse:Bool = false)
	{
		if (status != IDLE || skipDance)
			return false;
		final forseAnim:Bool = forceDance
			|| forse
			|| useAtlas
				&& anim.loopType == Loop
				&& anim.loopPoint > 0
				&& anim.curFrame >= anim.loopPoint
			|| !useAtlas
				&& animation.curAnim != null
				&& animation.curAnim.looped
				&& animation.curAnim.loopPoint > 0
				&& animation.curAnim.curFrame >= animation.curAnim.loopPoint; // gore

		if (danceIdle)
		{
			if (danceFewDance)
			{
				var aaaaa = playAnim('dance$nextDance' + idleSuffix, forseAnim);
				if (!aaaaa)
				{
					nextDance = 0;
					aaaaa = playAnim('dance$nextDance' + idleSuffix, forseAnim);
				}
				nextDance++;
				return aaaaa;
			}
			return playAnim(((_danceLeft = !_danceLeft) ? "danceRight" : "danceLeft") + idleSuffix, forseAnim);
		}
		return playAnim("idle" + idleSuffix, forseAnim);
	}

	public function sing(anim:String, ?force:Bool = true, ?isHold:Bool = false)
	{
		var isEndHold = holdEndAnims && status == HOLD_SING;
		isHold = isHold && holdAnims;
		force = (forceSing || force) && (!isHold || !isEndHold);
		status = isHold ? HOLD_SING : SINGLE_SING;
		holdTimer = 0;
		anim = singAnimsPrefix + anim;
		return playAnim(isHold ? anim + "-hold" : isEndHold ? anim + "-holdEnd" : anim, force, force ? 0 : curFrame);
	}

	public override function playAnim(AnimName:String, Force:Bool = false, Reversed:Bool = false, Frame:Int = 0):Bool
	{
		specialAnim = false;
		while (!super.playAnim(AnimName, Force, Reversed, Frame) && AnimName.length > 0)
		{
			AnimName = AnimName.substring(0, AnimName.lastIndexOf("-"));
		}
		return AnimName.length > 0;

		// return super.playAnim(AnimName, Force, Reversed, Frame);

		// final boolSwag = super.playAnim(AnimName, Force, Reversed, Frame);
		// if (boolSwag && curCharacter.startsWith("gf")){
		// 	switch (AnimName){
		// 		case "singLEFT":			_danceLeft = true;
		// 		case "singRIGHT":			_danceLeft = false;
		// 		case "singUP", "singDOWN":	_danceLeft = !_danceLeft;
		// 	}
		// }
		// return boolSwag;
	}

	private var settingCharacterUp:Bool = true;

	public function recalculateDanceIdle()
	{
		final lastDanceIdle:Bool = danceIdle;
		set_idleSuffix(idleSuffix); // check anims
		if (danceFewDance)
			danceIdle = true;

		danceEveryNumBeats = beatDanceJson;

		// if (settingCharacterUp)
		// 	danceEveryNumBeats = (danceIdle ? 1 : 2);
		// else if (lastDanceIdle != danceIdle)
		// 	danceEveryNumBeats = Math.round(Math.max(danceEveryNumBeats * (danceIdle ? 0.5 : 2), 1));

		settingCharacterUp = false;
	}

	inline function get_debugMode()
		return status == DEBUG;

	inline function set_debugMode(e)
	{
		status = e ? DEBUG : status == DEBUG ? IDLE : status;
		return e;
	}

	inline function get_specialAnim()
		return status == SPECIAL_ANIM;

	inline function set_specialAnim(e)
	{
		status = e ? SPECIAL_ANIM : status == SPECIAL_ANIM ? IDLE : status;
		return e;
	}

	public override function toString():String
	{
		return FlxStringUtil.getDebugString([
			LabelValuePair.weak("x", x),
			LabelValuePair.weak("y", y),
			LabelValuePair.weak("w", width),
			LabelValuePair.weak("h", height),
			LabelValuePair.weak("vis", visible),
			LabelValuePair.weak("vel", velocity),
			LabelValuePair.weak("animOff", __drawingOffset),
			LabelValuePair.weak("off", offset),
			LabelValuePair.weak("status", status),
			LabelValuePair.weak("isPlayer", isPlayer),
			LabelValuePair.weak("curChar", curCharacter),
			LabelValuePair.weak("stunned", stunned)
		]);
	}
}
