package game.objects.game;

import game.states.playstate.PlayState;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.math.FlxMath;
import flixel.util.FlxSort;
import flixel.graphics.FlxGraphic;
import openfl.utils.AssetType;

import haxe.DynamicAccess;
import haxe.Json;

@:publicFields
class IconProperties
{
	var triggers:Array<StupidDir> = [
		// default idle on middle property
		{name: 'lose', indices: [0, 20]},
		{name: 'idle', indices: [21, 100]}
	];

	/**
	 * List of anims ugh
	 *
	 * Basic:
	 * [Won], [Lose], [Idle], [Lose->Idle], [Idle->Lose], [Won->Idle]...
	 */
	var animations:Array<AnimArrayIcon> = [{anim: 'lose', fps: 24}, {anim: 'idle', fps: 24}];

	var image:String = 'none';

	function new(?stuff:Any)
	{
		if (stuff != null)
			for (i in Reflect.fields(stuff))
				if (Reflect.field(this, i) != null)
					Reflect.setField(this, i, Reflect.field(stuff, i));
	}

	// Optionals
	var healthbar_colors:DynamicColor = [125, 125, 125];
	var offsets:Array<Float> = [0, 0];
	var scale:Float = 1;
	var bobInsetity:Float = 1.2;
	var offsetsPointScale:Array<Float> = [0, 0];
	var doBob:Bool = true;
	var hadXml:Bool = false;
	var no_antialiasing:Bool = false;
	var flipX:Bool = false;
	var flipY:Bool = false;
	var shader:String; // WHA

	var player:Bool = false; // for game, please ignore
}

typedef IconFrame =
{
	var index:Int;
	var pos:Array<Int>;
	var size:Array<Int>;
}

typedef AnimArrayIcon =
{
	var anim:String;
	@:optional var fps:Float;
	@:optional var loop:Bool;
	@:optional var reversed:Bool;
	@:optional var nameAnim:String; // used in xml/txt/json files
	@:optional var indices:Array<Int>;

	@:optional var offsets:Array<Float>;
	@:optional var loopPoint:Int;

	@:optional var flipX:Bool;
	@:optional var flipY:Bool;

	@:optional var frames:Array<IconFrame>;
}

typedef StupidDir =
{
	var name:String;
	var indices:Array<Int>;
}

// TODO: REWRITE IT ALL
class HealthIcon extends FlxSprite
{
	public var extraData:Map<String, Dynamic> = new Map(); // lua hx lua hx lua hx others shits

	public static var dataMap(default, null):Map<String, IconProperties> = new Map();

	@:arrayAccess public var animsStats:Map<String, AnimArrayIcon> = new Map<String, AnimArrayIcon>();
	@:arrayAccess public var triggers:Map<String, Int->Bool> = new Map<String, Int->Bool>();

	public var data(default, set):IconProperties;

	function set_data(e:IconProperties):IconProperties
	{
		if (triggers != null)
			triggers.clear();
		else
			triggers = new Map<String, Int->Bool>();
		if (e == null)
			return data = e;

		e.scale = e.scale.getDefault(1.);
		e.bobInsetity = e.bobInsetity.getDefault(1.2);
		e.shader = e.shader;
		e.offsets = e.offsets == null ? [0, 0] : e.offsets;
		e.offsetsPointScale = e.offsetsPointScale == null ? [0, 0] : e.offsetsPointScale;

		data = e;
		for (i in data.triggers)
			triggers[i.name] = FlxMath.inBounds.bind(_, i.indices[0], i.indices[1]);
			// if (i.indices[0] == 0)
			// 	triggers[i.name] = e -> return i.indices[1] >= e;
			// else if (i.indices[1] == 100)
			// 	triggers[i.name] = e -> return i.indices[0] <= e;
			// else

		if (isPlayer != data.player) // flip offsets lol
		{
			data.offsets[0] *= -1;
			// data.bobInsetity = 0.7; // tEsT
			data.offsetsPointScale[0] *= -1;
			data.player = isPlayer;
		}
		if (!HealthIcon.dataMap.exists(char) && loadedFromDefault)
			data.image = char;
		HealthIcon.dataMap[char] = data;
		return e;
	}

	public static function cloneData(?deData:IconProperties):IconProperties
	{
		var newData:IconProperties = new IconProperties();
		if (deData == null)
			return newData;
		newData.scale = deData.scale.getDefault(1);
		newData.bobInsetity = deData.bobInsetity.getDefault(1.2);
		newData.shader = deData.shader;
		newData.image = deData.image;
		newData.offsets = deData.offsets?.copy() ?? [0, 0];
		newData.offsetsPointScale = deData.offsetsPointScale?.copy() ?? [0, 0];
		newData.triggers = deData.triggers.copy();
		newData.animations = deData.animations.copy();
		return newData;
	}

	public static inline function clearDatas()
	{
		HealthIcon.dataMap.clear();
	}

	public static function preload(name:String)
	{
		if (HealthIcon.dataMap.exists(name)) return;
		new HealthIcon(name).destroy(); // lol
	}

	public var baseScale:Float = 1;

	public var loaded(default, null):Bool = false;
	public var isOldIcon(default, null):Bool = false;
	public var isPlayer(default, null):Bool = false;
	public var char:String = null;

	public function new(char:String = 'bf', isPlayer:Bool = false, ?gpuRender:Bool = true, ?data:Null<IconProperties>)
	{
		super();
		isOldIcon = (char == 'bf-old');
		this.isPlayer = isPlayer;
		changeIcon(char, data, gpuRender);
	}

	override function update(elapsed:Float)
	{
		callToHScript('onUpdateIconPost', [elapsed]);
		if (animation.curAnim != null && animation.finished && animation.exists(animation.name + '-loop'))
		{
			playAnim(animation.name + '-loop', animation.curAnim.frameRate == 0 || animation.curAnim.looped);
		}
		super.update(elapsed);
		callToHScript('onUpdateIcon', [elapsed]);
	}

	public var lastAnim:String = "";
	public var nextLastAnim:String = "";

	public function updateHealth(health:Int)
	{
		if (animation.curAnim != null)
		{
			for (name => func in triggers)
			{
				if (!func(health)) continue;

				var oldAnim = animation.curAnim.name;
				if (name != oldAnim && name != lastAnim)
				{
					// trace(health);
					lastAnim = name;
					animation.finish();
					if (playAnim('${oldAnim.replace('-loop', '')}->$name', animation.curAnim.frameRate == 0 || animation.curAnim.looped))
					{
						nextLastAnim = lastAnim;
						var e = animation.curAnim.name;
						animation.finishCallback = animName ->
						{
							if (e == animName)
							{
								playAnim(nextLastAnim, true);
								animation.finishCallback = null;
							}
						}
					}
					else
					{
						playAnim(name, animation.curAnim.frameRate == 0 || animation.curAnim.looped);
						animation.finishCallback = null;
					}
					// trace('Char: $char | LastAnim: $lastAnim | CurAnim: ${animation.curAnim.name}');
					callToHScript('onChangeEmotion', [health, name]);
				}
				return true;
			}
		}
		return false;
	}

	public var iconOffsetsAnim:Array<Float> = [0., 0.];

	public function playAnim(AnimName:String, Force:Bool = false, Reversed:Bool = false, Frame:Int = 0):Bool
	{
		// specialAnim = false;
		if (animsStats.exists(AnimName))
		{
			var anim = animsStats.get(AnimName);
			animation.play(AnimName, Force, Reversed != (anim.reversed ?? false), Frame);
			iconOffsetsAnim = anim.offsets;
			return true;
		}
		return false;
	}

	public function swapOldIcon()
	{
		if (isOldIcon = !isOldIcon)
			changeIcon('bf-old');
		else
			changeIcon(char);
	}

	public var loadedFromDefault = false;

	public function loadFromJson(char:String):IconProperties
	{
		var path:String = AssetsPaths.getPath('characters/icons/' + char + '.json');

		if (!Assets.exists(path))
		{
			path =  AssetsPaths.getPath('characters/icons/default.json');
			loaded = true;
			loadedFromDefault = true;
		}

		return new IconProperties(cast Json.parse(Assets.getText(path)));
	}

	public var iconOffsets(default, null):Array<Float> = [0., 0.];

	public function changeIcon(char:String, ?replacedData:Null<IconProperties>, ?gpuRender:Bool = true)
	{
		if (this.char == char)
			return;

		this.char = char;
		callToHScript('onLoadIconPre', [char]);
		loaded = true;
		loadedFromDefault = false;
		data = HealthIcon.dataMap.exists(char) ? HealthIcon.dataMap[char] : (replacedData ?? loadFromJson(char));
		antialiasing = true;
		var curImage:String = data.image ?? 'face';
		while (true)
		{
			var name:String = 'icon-' + curImage;
			if (Assets.exists('images/icons/' + name + '.png', IMAGE)
				|| Assets.exists('images/icons/' + (name = curImage) + '.png', IMAGE))
			{
				loadAnims('icons/$name', Paths.image('icons/$name', gpuRender), gpuRender);
				break;
			}
			else
			{
				curImage = 'face'; // defaultImage
				data = loadFromJson(curImage); // TEMP
				loaded = false;
				continue;
			}
		}
		shader = (data.shader != null && data.shader.trim().length > 0) ?
			(PlayState.instance != null) ?
				PlayState.instance.createRuntimeShader(data.shader)
			:
				game.backend.utils.ShadersData.createRuntimeShader(data.shader)
		:
			null;
		callToHScript('onLoadIcon', [char]);
		// trace('Icon $char Loaded!');
	}

	function loadAnims(path:String, ?graphic:FlxGraphic, ?gpuRender:Bool = true)
	{
		final lastAnim = animation.curAnim == null ? 'idle' : animation.curAnim.name;
		animation.destroyAnimations();
		animsStats.clear();
		if (data.hadXml)
		{
			// frames = Paths.fileExists('images/' + path + '/Animation.json', TEXT) ? AtlasFrameMaker.construct(path) : Paths.getAtlas(path, gpuRender);
			frames = Paths.getAtlas(path, gpuRender);

			for (data in data.animations)
				addAnim(data);

			iconOffsets[0] = (width - 150) / 2;
			iconOffsets[1] = (height - 150) / 2;
			if (data.no_antialiasing)
				antialiasing = false;
		}
		else
		{
			var len = data.animations.length;
			loadGraphic(graphic, true, Math.floor(graphic.width / Math.max(len, 1)), Math.floor(graphic.height)); // Then load it fr

			if (len > 0)
				for (i in 0...data.animations.length)
				{
					final anim = data.animations[i];
					if (anim.nameAnim == null)
						anim.nameAnim = anim.anim;
					animation.add(anim.anim, [i], 0);
					animsStats.set(anim.anim, anim);
					animsStats[anim.anim].offsets = anim.offsets == null
						|| anim.offsets.length == 0 ? [0, 0] : [anim.offsets[0], anim.offsets[1]];
					updateFlxAnimation(anim);
				}

			if (char.endsWith('-pixel') || data.no_antialiasing)
				antialiasing = false;
		}
		iconOffsets[0] = (width - 150) / 2;
		iconOffsets[1] = (height - 150) / 2;

		playAnim(lastAnim);
		updateHitboxSpecial();
	}

	public function addAnim(anim:AnimArrayIcon)
	{
		if (anim.anim == null) return;
		anim.nameAnim ??= anim.anim;

		//if (frames != null && anim.reversed == true && frames.framesHash.exists('${anim.nameAnim}0002'))
		//{
			/*
			var deCleanAnim:String = anim.nameAnim;
			var numClear:Int = 4;
			while (deCleanAnim.endsWith('0'))
			{
				deCleanAnim = deCleanAnim.substr(0, deCleanAnim.length - 1);
				numClear--;
			}
			if (anim.indices == null)
			{
				anim.indices = [0, 1];
				var index = anim.indices.length;
				while (frames.framesHash.exists('${deCleanAnim}${CoolUtil.addZeros(Std.string(index), numClear)}'))
				{
					anim.indices.push(index++);
				}
				trace(deCleanAnim, anim.indices);
			}
			*/
			//anim.indices?.reverse();
			//trace(anim.indices);
		//}

		if (anim.indices == null || anim.indices.length == 0)
			animation.addByPrefix('' + anim.anim, '' + anim.nameAnim, 24, anim.loop == true, anim.flipX == true, anim.flipY == true);
		else
			animation.addByIndices('' + anim.anim, '' + anim.nameAnim, anim.indices, "", 24, anim.loop == true, anim.flipX == true, anim.flipY == true);
		animsStats.set(anim.anim, anim);
		animsStats[anim.anim].offsets = anim.offsets == null || anim.offsets.length == 0 ? [0, 0] : [anim.offsets[0], anim.offsets[1]];
		updateFlxAnimation(anim);
	}

	public function updateFlxAnimation(animArray:AnimArrayIcon)
	{
		final anim = animation.getByName(animArray.anim);
		if (anim == null)
			return;

		if (data.flipX == true)
			anim.flipX = !anim.flipX;
		if (data.flipY == true)
			anim.flipY = !anim.flipY;
		if (isPlayer)
			anim.flipX = !anim.flipX;
		anim.frameRate = animArray.fps;
		// @:privateAccess
		// anim.reversed = animArray.reversed == true;
		/*if (animArray.loopPoint != null)*/ anim.loopPoint = Std.int(animArray.loopPoint);
	}

	public function onBeatScale()
	{
		scale.x = scale.y = baseScale * data.scale * data.bobInsetity;
		updateHitboxSpecial();
		callToHScript('onBeat');
	}

	public function updatePsych()
	{
		scale.x = scale.y = CoolUtil.fpsLerp(scale.x, baseScale * data.scale, 0.158);
		updateHitboxSpecial();
	}

	public function updateOffsets()
	{
		updateHitboxSpecial();
		origin.x -= data.offsetsPointScale[0] * (scale.x / data.scale - 1);
		origin.y -= data.offsetsPointScale[1] * (scale.y / data.scale - 1);
	}

	public function updateHitboxSpecial()
	{
		width = Math.abs(scale.x) * frameWidth;
		height = Math.abs(scale.y) * frameHeight;
		offset.set(iconOffsets[0] - (data.offsets[0] + iconOffsetsAnim[0]), iconOffsets[1] - (data.offsets[1] + iconOffsetsAnim[1]));
		centerOrigin();
	}

	public function updateMidPointScale()
	{
		centerOrigin();
		origin.x -= data.offsetsPointScale[0] * (scale.x / data.scale - 1);
		origin.y -= data.offsetsPointScale[1] * (scale.y / data.scale - 1);
	}

	public inline function getCharacter()
		return char;

	public inline function callToHScript(funcName:String, ?args:Array<Dynamic>)
	{
	}

	public override function destroy()
	{
		animsStats = null;
		data = null;
		extraData = null;
		triggers = null;
		super.destroy();
	}
}
