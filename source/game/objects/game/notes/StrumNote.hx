package game.objects.game.notes;

import flixel.graphics.frames.FlxAtlasFrames;
import flixel.math.FlxAngle;
import flixel.math.FlxPoint;

import game.backend.data.StrumsManiaData;
import game.modchart.math.Vector3;
import game.objects.game.notes.Note.DirectionNote;
import game.objects.game.notes.Note.TypeNote;
import game.objects.game.notes.Note.globalRgbShaders;
import game.objects.game.notes.Note;
import game.shaders.ColorSwap;
import game.shaders.RGBPalette;
import game.states.playstate.PlayState;

using flixel.util.FlxStringUtil;

class StrumNote extends FlxSprite implements INote
{
	public static var dirArray:Array<String> = [
		'LEFT',			'DOWN', 		'UP',		'RIGHT',
		'SPACE',
		'EXTRALEFT',	'EXTRADOWN',	'EXTRAUP',	'EXTRARIGHT',

		'purple',		'blue',			'green',	'red',
		'center',
		'purple',		'blue',			'green',	'red'
	];

	public var defScale:FlxPoint = FlxPoint.get(1, 1);
	public var defPos:FlxPoint = FlxPoint.get(0, 0);

	public var animOffsets = new Map<String, FlxPoint>();
	public var extraData = new Map<String, Dynamic>(); // lua lua lua lua lua lua others shits

	// calars
	public var colorSwap:ColorSwap;
	public var useColorSwap(get, set):Bool;
	function get_useColorSwap() return colorSwap != null;
	function set_useColorSwap(i)
	{
		if (i)
		{
			if (colorSwap == null)
				colorSwap = new ColorSwap();
			shader = colorSwap.shader;
		}
		else if (colorSwap != null)
		{
			if (shader == colorSwap.shader)
				shader = null;
			colorSwap = colorSwap.dispose();
		}
		return i;
	}

	public var useRGBShader:Bool = true;
	public var rgbShader:RGBShaderReference;

	public var resetAnim:Float = 0;
	public var noteData:Byte = 0;
	public var direction(default, set):Float = 90;
	@:allow(game.objects.game.notes.Note)
	@:noCompletion var _sinDir:Float = 1;
	@:allow(game.objects.game.notes.Note)
	@:noCompletion var _cosDir:Float = 0;
	@:noCompletion function set_direction(i:Float):Float
	{
		i %= 360.0;
		if (direction != i)
		{
			direction = i;
			_sinDir = Math.sin(i * FlxAngle.TO_RAD);
			_cosDir = Math.cos(i * FlxAngle.TO_RAD);
		}
		return i;
	}
	public var hue:Float;
	public var saturation:Float;
	public var brightness:Float;
	public var downScroll:Bool = ClientPrefs.downScroll;

	public var sustainReduce:Bool = true;
	public var isPlayer:Bool;
	public var player(get, never):Int;
	@:noCompletion inline function get_player()
	{
		return isPlayer ? 1 : 0;
	}

	public var cpuControl:Bool = false;

	public var groupParent:StrumGroup = null;

	override function destroy()
	{
		extraData = null;
		colorSwap = null;
		rgbShader = null;
		defScale = flixel.util.FlxDestroyUtil.put(defScale);
		defPos = flixel.util.FlxDestroyUtil.put(defPos);
		if (animOffsets != null)
		{
			for (_ => e in animOffsets)
				e.put();
			animOffsets.clear();
			animOffsets = null;
		}
		super.destroy();
	}

	public var baseScale:Float = 1.;

	override function draw()
	{
		scale.scale(baseScale);
		super.draw();
		scale.scale(1 / baseScale);
	}

	public var mainScale(default, null):Float = 1.; // yea
	public var typeDirection:DirectionNote;

	// public var baseScale(default, set):Float = 1.;
	// public function set_baseScale(e:Float):Float {
	// 	baseScale = e * mainScale;
	// 	return scale.x = scale.y = baseScale;
	// }
	public var texture(default, set):Null<String> = null;

	function set_texture(value:String):String
	{
		value ??= getDefaultTexture();
		if (texture != value)
		{
			texture = value;
			reloadNote();
		}
		return value;
	}
	public function getDefaultTexture()
	{
		return (PlayState.SONG.arrowSkin.isNullOrEmpty() ? Constants.DEFAULT_NOTE_SKIN : PlayState.SONG.arrowSkin);
	}

	public var skinType(default, set):TypeNote = NONE_NOTE;
	function set_skinType(e:TypeNote):TypeNote
	{
		if (skinType != e)
		{
			skinType = e;
			reloadNote();
		}
		return e;
	}

	public inline function setTypeFromString(value:String)
		skinType = value;

	public function new(x:Float, y:Float, leData:Int, ?isPlayer:Bool, ?typeDirection:DirectionNote, ?typeNote:TypeNote)
	{
		super(x, y);

		if (typeDirection == null)
			@:bypassAccessor this.typeDirection = [left, down, up, right][leData];
		else
			@:bypassAccessor this.typeDirection = typeDirection;
		this.isPlayer = isPlayer;
		this.noteData = leData;

		@:bypassAccessor texture = getDefaultTexture();
		@:bypassAccessor skinType = typeNote ?? PlayState.instance?.stageData?.typeNotesAbstract ?? Constants.DEFAULT_TYPE_NOTE;
		reloadNote(); // Load texture and anims
	}

	public function reloadNote()
	{
		final lastAnim:String = animation.name;

		antialiasing = true;
		useRGBShader = false;
		/*
			if (rgbShader == null){
				rgbShader = new RGBShaderReference(this, Note.initializeGlobalRGBShader(noteData));
				colorSwap = null;
				useRGBShader = true;
			}else
		 */
		/*
		if (colorSwap == null)
		{
			colorSwap = new ColorSwap();
			shader = colorSwap.shader;
			rgbShader = null;
		}
		*/
		final boob:Int = Note.mapNoteData.get(typeDirection);
		switch (skinType)
		{
			case PIXEL_NOTE:
				// final lengthOfDir:Int = Std.int(dirArray.length/2);
				final lengthOfDir:Int = 4;
				loadGraphic(Paths.image('pixelUI/' + texture));
				width = width / lengthOfDir;
				height = height / 5;
				loadGraphic(Paths.image('pixelUI/' + texture), true, Math.floor(width), Math.floor(height));

				antialiasing = false;
				setGraphicSize(width * PlayState.daPixelZoom);

				// animation.add(dirArray[boob + 4], [boob + 4]);

				animation.add('static', [boob]);
				animation.add('pressed', [boob + lengthOfDir, boob + lengthOfDir * 2], 12, false);
				animation.add('confirm', [boob + lengthOfDir * 3, boob + lengthOfDir * 4], 12, false);
			default:
				frames = Paths.getSparrowAtlas(texture);
				// animation.addByPrefix(dirArray[boob + 4], 'arrow' + dirArray[boob]);

				setGraphicSize(width * 0.7);

				final lowerCaseAnim:String = dirArray[boob].toLowerCase();
				animation.addByPrefix('static', 'arrow' + dirArray[boob]);
				animation.addByPrefix('pressed', lowerCaseAnim + ' press', 24, false);
				animation.addByPrefix('confirm', lowerCaseAnim + ' confirm', 24, false);
		}
		updateHitbox();
		defScale.copyFrom(scale);

		if (lastAnim != null)
			playAnim(lastAnim, true, false);
		mainScale = (scale.x + scale.y) / 2;
	}

	override function update(elapsed:Float)
	{
		if (resetAnim > 0)
		{
			resetAnim -= elapsed;
			if (resetAnim <= 0)
			{
				playAnim('static');
				resetAnim = 0;
			}
		}
		super.update(elapsed);
	}

	public function playAnim(anim:String, ?force:Bool = false, ?neededSort:Bool = true)
	{
		var neededToSort = neededSort && groupParent != null && animation.name != "confirm" && anim == "confirm";
		animation.play(anim, force);
		// if (animation.curAnim == null)
		// {
		// 	offset.copyFrom(getAnimOffset(anim));
		// }
		// else
		{
			centerOrigin();
			centerOffsets();
			offset += getAnimOffset(anim);
			if (useRGBShader && rgbShader != null)
				rgbShader.enabled = (animation.curAnim != null && anim != 'static');
			else if (colorSwap != null)
				if (animation.curAnim == null || anim == 'static')
				{
					colorSwap.hue = 0;
					colorSwap.saturation = 0;
					colorSwap.brightness = 0;
				}
				else
				{
					colorSwap.hue = hue;
					colorSwap.saturation = saturation;
					colorSwap.brightness = brightness;
				}
		}
		if (neededToSort)
		{
			groupParent.setToUpperNote(this);
		}
	}

	public function addOffset(name:String, x:Float = 0, y:Float = 0)
	{
		if (animOffsets.exists(name))
			animOffsets[name].set(x, y);
		else
			animOffsets[name] = FlxPoint.get(x, y);
	}

	public function switchOffset(anim1:String, anim2:String)
	{
		final old = animOffsets[anim1];
		animOffsets[anim1] = animOffsets[anim2];
		animOffsets[anim2] = old;
	}

	public function getAnimOffset(name:String):FlxPoint
		return animOffsets.get(name) ?? FlxPoint.weak();

	public function getDownScroll()
	{
		return downScroll;
	}

}
