package game.objects.game.notes;

import flixel.math.FlxAngle;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.util.FlxColor;
import flixel.graphics.frames.FlxFrame;
import flixel.graphics.tile.FlxDrawTrianglesItem.DrawData;

import game.backend.system.song.Conductor.mainInstance as Conductor;
import game.modchart.math.Vector3;
import game.objects.game.notes.StrumNote;
import game.shaders.ColorSwap;
import game.shaders.RGBPalette;
import game.states.editors.ChartingState;
import game.states.playstate.PlayState;

import game.modchart.*;

import haxe.extern.EitherType;

using flixel.util.FlxStringUtil;

abstract EventNote(Array<EitherType<Float, String>>) {
	public var strumTime(get, set):Float;
	inline function get_strumTime()		return this[0];
	inline function set_strumTime(e)	return this[0] = e;
	public var event(get, set):String;
	inline function get_event()			return this[1];
	inline function set_event(e)		return this[1] = e;
	public var value1(get, set):String;
	inline function get_value1()		return this[2];
	inline function set_value1(e)		return this[2] = e;
	public var value2(get, set):String;
	inline function get_value2()		return this[3];
	inline function set_value2(e)		return this[3] = e;
	public var value3(get, set):String;
	inline function get_value3()		return this[4];
	inline function set_value3(e)		return this[4] = e;
	public inline function new(strumTime:Float, event:String, ?value1:String, ?value2:String, ?value3:String) this = [strumTime, event, value1, value2, value3];
}

typedef NoteSplashData = {
	disabled:Bool,
	texture:String,
	antialiasing:Bool,

	useGlobalShader:Bool, //breaks r/g/b/a but makes it copy default colors for your custom note
	useRGBShader:Bool,
	r:FlxColor,
	g:FlxColor,
	b:FlxColor,
	a:Float,

	useColorSwapShader:Bool
}

enum abstract TypeNote(Byte) from Byte to Byte {
	var NONE_NOTE:TypeNote = -1;
	var FNF_NOTE:TypeNote = 0;
	var PIXEL_NOTE:TypeNote = 1;
	// var COLORS_NOTE:TypeNote = 2;
	// var COLORS_GUATIAR:TypeNote = 2;

	@:noCompletion static final _ereg = ~/(_|-)note?$/i;
	@:from
	@:noCompletion
	static function fromString(str:String):TypeNote
	{
		return switch (str == null ? null : (_ereg.match(str) ? _ereg.matchedLeft() : str.trim().toLowerCase()))
		{
			case "fnf":			FNF_NOTE;
			case "pixel":		PIXEL_NOTE;
			// case "colors":		COLORS_NOTE;
			default:			NONE_NOTE;
		}
	}
	@:to
	@:noCompletion
	function toString():String
	{
		return switch (cast this)
		{
			case FNF_NOTE:		"fnf";
			case PIXEL_NOTE:	"pixel";
			// case COLORS_NOTE:		"colors";
			default:			"none";
		}
	}
}

enum abstract DirectionNote(String) from String to String {
	var left = 'left';
	var up = 'up';
	var down = 'down';
	var right = 'right';
	var space = 'space';
	var extraLeft = 'extra_left';
	var extraUp = 'extra_up';
	var extraDown = 'extra_down';
	var extraRight = 'extra_right';
}

@:access(flixel.FlxBasic)
class Note extends FlxSprite implements INote
{
	public static final dirArrayLow:Array<String> = ['left', 'down', 'up', 'right'];
	static final colArray:Array<String> = ['purple', 'blue', 'green', 'red'];

	public static var vec3Cache:Vector3 = new Vector3(1, 1, 0); // for vector3 operations in modchart code
	public var defScale:FlxPoint = FlxPoint.get(1, 1); // for modcharts to keep the scaling

	/*
	public var vertices:DrawData<Float> = new DrawData<Float>();
	public var indices:DrawData<Int> = new DrawData<Int>();
	public var uvtData:DrawData<Float> = new DrawData<Float>();
	*/

	public var extraData(get, never):Map<String, Dynamic>; // lua hx lua hx lua hx others shits
	@:noCompletion var _extraData:Map<String, Dynamic>;
	@:noCompletion inline function get_extraData() {
		_extraData ??= new Map<String, Dynamic>();
		return _extraData;
	}

	public function setTypeDirection(e:String):String
	{
		noteData = mapNoteData.get(e);
		reloadNote();
		return e;
	}

	public var noteData:Byte;

	// ye
	public var noteDataReal:Byte;

	public var strumTime:Float;
	public var mustPress:Bool;
	public var canBeHit:Bool;
	public var tooLate:Bool;
	public var ignoreNote:Bool;

	public var ignorePress:Bool;

	public var noteWasHit:Bool;
	public var wasGoodHit:Bool;
	public var hitByOpponent:Bool;

	public var prevNote:Note;
	public var nextNote:Note;

	/*
	public var holdSubdivisions(get, default):Null<Int> = null;
	function get_holdSubdivisions():Int
	{
		return holdSubdivisions ?? 3;
	}
	*/

	public var spawned(get, never):Bool;
	inline function get_spawned() return active;

	public var skinType(default, set):TypeNote = TypeNote.NONE_NOTE;
	function set_skinType(e:TypeNote):TypeNote
	{
		if (skinType != e)
		{
			skinType = e;
			reloadNote();
		}
		return e;
	}

	public var tail:Array<Note>; // for sustains
	public var parent:Note;
	public var blockHit:Bool; // only works for player

	public var sustainLength:Float = 0.0;
	public var isSustainNote(default, null):Bool;
	public var isLastSustain:Bool;
	public var noteType(default, set):String = null;

	var inEditor(default, null):Bool;

	/**
	 * NOTE: This does not affect the speed of the notes.
	 */
	public var baseScale(default, set):Float = 1.0;
	function set_baseScale(value:Float):Float
	{
		if (baseScale != value)
		{
			scaleByRatio(value / baseScale);
			baseScale = value;
			if (parentStrum != null)
				scaleToStrumNote();
		}
		return value;
	}

	override function draw()
	{
		checkClipRect();

		checkEmptyFrame();

		if (alpha == 0 || _frame.type == FlxFrameType.EMPTY || (parentStrum != null && !parentStrum.visible))
			return;

		if (dirty) // rarely
			calcFrame(useFramePixels);

		/*
		for (camera in cameras)
		{
			if (!camera.visible || !camera.exists)
				continue;

			getScreenPosition(_point, camera).subtractPoint(offset);
			camera.drawTriangles(graphic, vertices, indices, uvtData, colors, _point, blend, true, antialiasing, colorTransform, shader);

			#if FLX_DEBUG
			FlxBasic.visibleCount++;
			#end
		}
		*/
		for (camera in cameras)
		{
			if (!camera.visible || !camera.exists || !isOnScreen(camera))
				continue;

			// if (isSimpleRender(camera))
			// 	drawSimple(camera);
			// else
				drawComplex(camera);

			#if FLX_DEBUG
			FlxBasic.visibleCount++;
			#end
		}

		#if FLX_DEBUG
		if (FlxG.debugger.drawDebug)
			drawDebug();
		#end
	}

	public var animSuffix:String = '';
	public var gfNote:Bool;
	public var earlyHitMult:Single = 1.0;
	public var lateHitMult:Single = 1.0;
	public var lowPriority:Bool;

	public var destroyOnHit:Bool = true;
	public var playStrum:Bool = true;

	public static final swagWidth:Float = 112.0; // 160.0 * 0.7
	// public static inline var PURP_NOTE:Int = 0;
	// public static inline var BLUE_NOTE:Int = 1;
	// public static inline var GREEN_NOTE:Int = 2;
	// public static inline var RED_NOTE:Int = 3;

	public var holdCoverDisabled:Bool;

	// Lua shit
	public var noteSplashDisabled:Bool;
	public var noteSplashTexture:String;
	public var noteSplashHue:Null<Float>;
	public var noteSplashSat:Null<Float>;
	public var noteSplashBrt:Null<Float>;

	public inline function getCurrentDownScroll():Bool
	{
		return parentStrum?.downScroll ?? ClientPrefs.downScroll;
	}

	public var offsetX:Float = 0.0;
	public var offsetY:Float = 0.0;
	public var offsetAngle:Float = 0.0;
	public var mAngle:Float = 0.0;
	public var multAlpha:Float = 1.0;
	public var multSpeed(default, set):Float = 1.0;

	function set_multSpeed(value:Float):Float
	{
		if (multSpeed != value)
		{
			resizeByRatio(value / multSpeed);
			multSpeed = value;
			// trace('fuck cock');
		}
		return value;
	}

	public function resizeByRatio(ratio:Float)
	{
		if (isSustainNote && !isLastSustain)
		{
			scale.scale(1.0 / baseScale); // what needed, trust me
			scale.y *= ratio;
			updateHitbox();
			scale.scale(baseScale);
		}
	}

	public var copyX:Bool = true;
	public var copyY:Bool = true;
	public var copyAngle:Bool = true;
	public var copyAlpha:Bool = true;

	public var hitHealth:Single = 0.023;
	public var missHealth:Single = 0.0475;
	public var rating:String = 'unknown';
	public var ratingMod:Float = 0.0; // 9 = unknown, 0.25 = shit, 0.5 = bad, 0.75 = good, 1 = sick
	public var ratingDisabled:Bool;

	public var texture(default, set):String = null;

	public function getDownScroll()
	{
		return getCurrentDownScroll();
	}

	// calars
	public var colorSwap:ColorSwap;
	public var useColorSwap(get, set):Bool;
	@:noCompletion inline function get_useColorSwap() return colorSwap != null;
	function set_useColorSwap(value:Bool)
	{
		if (value)
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
		return value;
	}

	public var noteSplashData:NoteSplashData = {
		disabled: false,
		texture: null,
		antialiasing: true,
		// 7.+ stuff
		useGlobalShader: false,
		useRGBShader: false,
		r: -1,
		g: -1,
		b: -1,
		a: 1,

		// old stuff
		useColorSwapShader: false // yea lol
	};
	public var rgbShader:RGBShaderReference;
	public static var globalRgbShaders:Array<RGBPalette> = [];


	public var noSingAnimation:Bool;
	public var noAnimation:Bool;
	public var noMissAnimation:Bool;
	public var hitCausesMiss:Bool;
	public var distance:Float;
	public var cpuControl(get, default):Bool;
	@:noCompletion function get_cpuControl():Bool
	{
		return cpuControl || (parentStrum?.cpuControl ?? false);
	}

	public var hitsoundDisabled:Bool;

	public var parentStrum:StrumNote;

	public inline function setTypeFromString(value:String) skinType = value;

	function set_texture(value:String):String
	{
		value ??= getDefaultTexture();
		if (texture != value)
		{
			reloadNote(null, value);
			texture = value;
		}
		return value;
	}
	public function getDefaultTexture()
	{
		return (PlayState.SONG.arrowSkin.isNullOrEmpty() ? Constants.DEFAULT_NOTE_SKIN : PlayState.SONG.arrowSkin);
	}


	function set_noteType(value:String):String
	{
		noteSplashTexture = null;
		if (noteDataReal > -1 && noteType != value)
		{
			switch (value)
			{
				case 'Hurt Note':
					ignoreNote = mustPress;
					reloadNote('HURT');
					noteSplashTexture = 'HURTnoteSplashes';
					if (colorSwap != null)
					{
						colorSwap.hue = 0;
						colorSwap.saturation = 0;
						colorSwap.brightness = 0;
					}
					else if (rgbShader != null)
					{
						// note colors
						rgbShader.r = 0xFF101010;
						rgbShader.g = 0xFFFF0000;
						rgbShader.b = 0xFF990022;

						// splash data and colors
						noteSplashData.r = 0xFFFF0000;
						noteSplashData.g = 0xFF101010;
						// noteSplashData.texture = 'noteSplashes/noteSplashes-electric';
					}
					lowPriority = true;

					missHealth = isSustainNote ? 0.1 : 0.3;

					hitCausesMiss = true;
					extraData['hitsoundChartEditor'] = false;
				case 'Alt Animation':
					animSuffix = '-alt';
				case 'No Animation':
					noAnimation = true;
					noMissAnimation = true;
				case 'GF Sing':
					gfNote = true;
			}
			noteType = value;
		}
		if (colorSwap != null)
		{
			noteSplashHue = colorSwap.hue;
			noteSplashSat = colorSwap.saturation;
			noteSplashBrt = colorSwap.brightness;
		}
		return value;
	}

	@:noCompletion
	override function initVars():Void
	{
		super.initVars();
		moves = false;
		tail = [];
	}

	public static var standart4K(get, never):Array<DirectionNote>;
	static inline function get_standart4K() return game.backend.data.StrumsManiaData.data.get('4K');

	public function new(strumTime:Float, noteData:Int, ?typeNote:TypeNote, ?prevNote:Note, ?sustainNote:Bool = false, ?inEditor:Bool = false, ?isMustPress:Bool = false)
	{
		super();
		if (prevNote == null) prevNote = this;

		this.prevNote = prevNote;
		isSustainNote = sustainNote;
		this.inEditor = inEditor;

		this.mustPress = isMustPress;
		this.cpuControl = !this.mustPress;

		// x += (ClientPrefs.middleScroll ? PlayState.STRUM_X_MIDDLESCROLL : PlayState.STRUM_X) + 50;
		// MAKE SURE ITS DEFINITELY OFF SCREEN?
		y -= 2000.0;
		this.strumTime = strumTime;
		if (!inEditor) this.strumTime += ClientPrefs.noteOffset;

		this.noteData = this.noteDataReal = noteData;

		if (noteData < 0) return;
		// texture = '';
		// for (i => e in mapNoteData)
		// 	if (e == noteData){
		// 		break;
		// 	}
		if (prevNote != this) prevNote.nextNote = this;
		@:bypassAccessor skinType = typeNote ?? PlayState.instance?.stageData?.typeNotesAbstract ?? Constants.DEFAULT_TYPE_NOTE;
		this.noteData = mapNoteData.get(standart4K[noteData]);
		reloadNote();

		// x += Note.swagWidth * (noteData);

		// trace(prevNote);
	}

	public static function initializeGlobalRGBShader(noteData:Int, ?colors:Array<Int>)
	{
		if(globalRgbShaders[noteData] != null) return globalRgbShaders[noteData];

		var newRGB:RGBPalette = new RGBPalette();
		globalRgbShaders[noteData] = newRGB;

		if (colors == null)
			colors = switch(noteData)
			{
				case 0:		[0xFFC24B99, 0xFFFFFFFF, 0xFF3C1F56];
				case 1:		[0xFF00FFFF, 0xFFFFFFFF, 0xFF1542B7];
				case 2:		[0xFF12FA05, 0xFFFFFFFF, 0xFF0A4447];
				default:	[0xFFF9393F, 0xFFFFFFFF, 0xFF651038];
			}
		// var arr:Array<FlxColor> = [0xffb8b8b8,0xffffffff,0xff000000];
		// if (noteData <= arr.length){
			newRGB.r = colors[0];
			newRGB.g = colors[1];
			newRGB.b = colors[2];
		// }
		return newRGB;
	}

	// var lastNoteOffsetXForPixelAutoAdjusting:Float = 0.0;
	// var lastNoteScaleToo:Float = 1.0;

	// public var originalHeightForCalcs:Float = 6.0;

	// говно код
	public static final mapNoteData:Map<DirectionNote, Int> = [
		'left' => 0,
		'down' => 1,
		'up' => 2,
		'right' => 3,
		'space' => 2,
		'extra_left' => 0,
		'extra_down' => 1,
		'extra_up' => 2,
		'extra_right' => 3
	];

	function reloadNote(?prefix:String, ?texture:String, ?suffix:String)
	{
		if (texture.isNullOrEmpty())
		{
			texture = getDefaultTexture();
		}

		final animName:String = animation.curAnim?.name;

		antialiasing = true;
		noteSplashData.antialiasing = true;

		var blahblah:String = texture;
		/*
		if (skinType == COLORS && rgbShader == null){
			rgbShader = new RGBShaderReference(this, initializeGlobalRGBShader(mustPress ? -noteDataReal - 1 : noteDataReal));
			colorSwap = null;
		}else
		*/

		if (!prefix.isNullOrEmpty())
			blahblah = blahblah.insert(texture.lastIndexOf("/") + 1, prefix);

		if (!suffix.isNullOrEmpty())
			blahblah += suffix;

		// if (isSustainNote && prevNote != null)
		// 	prevNote.offsetX = prevNote.offsetY = 0;
		// scale.set(1, 1);
		// trace([skinType, blahblah, ID]);
		flipY = false;
		switch (skinType)
		{
			case PIXEL_NOTE:
				if(isSustainNote)
				{
					final graphic = Paths.image('pixelUI/' + blahblah + 'ENDS');
					loadGraphic(graphic, true, Math.floor(graphic.width / 4), Math.floor(graphic.height / 2));
					// originalHeight = graphic.height / 2;
					animation.add('holdend', [noteData + 4]);
					animation.add('hold', [noteData]);
				}
				else
				{
					final graphic = Paths.image('pixelUI/' + blahblah);
					loadGraphic(graphic, true, Math.floor(graphic.width / 4), Math.floor(graphic.height / 5));
					animation.add('scroll', [noteData + 4]);
				}
				scale.set(PlayState.daPixelZoom, PlayState.daPixelZoom);
				antialiasing = noteSplashData.antialiasing = false;
				// if(isSustainNote) {
				// 	offsetX += _lastNoteOffX;
				// 	_lastNoteOffX = (width - 7) * (PlayState.daPixelZoom / 2);
				// 	offsetX -= _lastNoteOffX;
				// }
			default:
				frames = Paths.getSparrowAtlas(blahblah);
				final colorName = colArray[noteData];
				if (isSustainNote)
				{
					// if (noteData == 0 && frames.framesHash.exists('pruple end hold0000'))
					// 	animation.addByPrefix('holdend', 'pruple end hold'); // ?????
					// else
						animation.addByPrefix('holdend', noteData == 0 ? 'pruple end' : colorName + ' hold end');
					animation.addByPrefix('hold', colorName + ' hold piece');
				}
				animation.addByPrefix('scroll', colorName + '0');
				//centerOffsets();
				//centerOrigin();
				scale.set(0.7, 0.7);
		}
		// @:privateAccess animation.removeInvalidFrames(frames.frames);

		defScale.copyFrom(scale);
		animation.play(animName ?? (isSustainNote ? "hold" : "scroll"), true);
		updateHitbox();

		// trace('reload note$ID sustain:$isSustainNote');
		if (isSustainNote)
		{
			if (prevNote != null && prevNote != this)
			{
				multAlpha = 0.6;
				alpha = multAlpha;
				hitsoundDisabled = true;

				animation.play('scroll');
				var baseWidth = frame.sourceSize.x;
				// final offsetXScroll:Float = Math.abs(scale.x) * frameWidth / 2.0;
				// final heightScroll:Float = Math.abs(scale.y) * frameHeight;
				animation.play('holdend');
				offsetX = Math.abs(scale.x) * (baseWidth - frame.sourceSize.x) / 2.0;

				// flipY = getCurrentDownScroll();
				//updateHitbox();
				// final offsetXHoldend:Float = Math.abs(scale.x) * frame.sourceSize.x / 2.0;
				// offsetX -= offsetXHoldend;

				if (prevNote.isSustainNote)
				{
					prevNote.animation.play('hold');
					prevNote.offsetX = Math.abs(prevNote.scale.x) * (baseWidth - prevNote.frame.sourceSize.x) / 2.0;
					// prevNote.offsetX -= Math.abs(prevNote.scale.x) * prevNote.frame.sourceSize.x / 2.0;
					// prevNote.offsetX = Math.abs(prevNote.scale.x) * prevNote.frame.sourceSize.x / 2.0;
					prevNote.scale.y = scale.y;

					prevNote.scale.y *= 160.0 / prevNote.frame.frame.height / 2.42;
					prevNote.scale.y *= Conductor.stepCrochet / 100.0 * prevNote.multSpeed;
					// prevNote.scale.y *= Conductor.stepCrochet / 100.0 * 1.5 * prevNote.multSpeed;
					if (PlayState.instance != null) prevNote.scale.y *= PlayState.instance.songSpeed / FlxG.timeScale;

					if (prevNote.skinType == PIXEL_NOTE)
					{
						prevNote.offsetX += 30.0;
						prevNote.scale.y /= PlayState.daPixelZoom * 1.4;
						// prevNote.scale.y *= (6.0 / height); // Auto adjust note size
					}
					prevNote.updateHitbox();
					var clipRect = prevNote.clipRect ?? FlxRect.get();
					clipRect.set(0.0, 0.0, prevNote.frameWidth, prevNote.frameHeight);
					prevNote.clipRect = clipRect;
					// prevNote.scale.y += 1.0 / prevNote.frameHeight;
					// prevNote.setGraphicSize();
				}

				if (prevNote.skinType == PIXEL_NOTE)
				{
					offsetX += 30.0;
					holdCoverDisabled = true;
					// offsetY += 30.0;
					// 	scale.y *= PlayState.daPixelZoom;
					// 	updateHitbox();
				}
				else
				{
					holdCoverDisabled = false;
				}
				// trace(offsetX, prevNote.offsetX);
				earlyHitMult = 0.0;
			}
		}
		else
		{
			animation.play('scroll'); // Doing this 'if' check to fix the warnings on Senpai songs
			earlyHitMult = 1.0;
		}
		if (isSustainNote)
		{
			var clipRect = clipRect ?? FlxRect.get();
			clipRect.set(0.0, 0.0, frameWidth, frameHeight);
			this.clipRect = clipRect;
		}
		_lastStrumScale = 1.0;
		if (parentStrum != null)
			scaleToStrumNote();
	}

	function updateLogic()
	{
		// if (cpuControl){
		canBeHit = (strumTime > Conductor.songPosition - Conductor.safeZoneOffset * lateHitMult
			&& strumTime < Conductor.songPosition + Conductor.safeZoneOffset * earlyHitMult);
			// && (!isSustainNote || parent.wasGoodHit)
		if (mustPress)
		// if (!cpuControl)
		{
			if (strumTime < Conductor.songPosition - Conductor.safeZoneOffset && !wasGoodHit)
				tooLate = true;
		}
		else
		{
			if (strumTime < Conductor.songPosition + Conductor.safeZoneOffset * earlyHitMult)
				wasGoodHit = ((isSustainNote && prevNote.wasGoodHit) || strumTime <= Conductor.songPosition + Conductor.safeZoneOffset * (earlyHitMult - 1.0));
		}
	}

	override function update(elapsed:Float){
		#if FLX_DEBUG
		FlxBasic.activeCount++;
		#end
		updateLogic();
		last.set(x, y);
		updateAnimation(elapsed);
	}

	public var correctionOffset:Float = 0.0;
	// @:noCompletion var _lastSongSpeed:Float = 1.0;
	public function followStrumNote(songSpeed:Float = 1.0, ?modManager:ModManager)
	{
		if (parentStrum == null)
			return;

		// update scaling
		scaleToStrumNote();

		//  _lastSongSpeed = songSpeed;
		distance = -0.45 * (Conductor.songPosition - strumTime) * songSpeed * multSpeed;

		if (modManager != null && modManager.active)
		{
			modChartFollow(songSpeed, modManager);
		}
		else
		{
			basicFollowStrumNote(songSpeed);
		}
	}

	function modChartFollow(songSpeed:Float, modManager:ModManager)
	{
		var pN:Int = mustPress ? 0 : 1;
		var visPos = distance;
		var curDecBeat = @:privateAccess PlayState.instance.curDecBeat;
		var pos = modManager.getPos(strumTime, visPos,
			strumTime - Conductor.songPosition,
			curDecBeat, noteData, pN, this, [], vec3Cache);

		if (copyAlpha)	alpha = parentStrum.alpha * multAlpha;
		// trace(modManager.getVisPos(Conductor.songPosition, daNote.strumTime, songSpeed));
		// daNote.last.x = daNote.x;
		// daNote.last.y = daNote.y;
		modManager.updateObject(curDecBeat, this, pos, pN);
		// daNote.x -= daNote.last.x;
		// daNote.y -= daNote.last.y;
		pos.x += offsetX;
		pos.y += offsetY;
		x = pos.x;
		y = pos.y;

		if (isSustainNote)
		{
			var diff = Conductor.stepCrochet;
			var futureSongPos = Conductor.songPosition + diff;
			visPos += -0.45 * diff * songSpeed * multSpeed;

			var nextPos = modManager.getPos(strumTime, visPos, diff, Conductor.getBeat(futureSongPos), this.noteData, pN, this, [], vec3Cache);
			nextPos.x += offsetX;
			var thatOffset = Note.swagWidth / 2.0;
			nextPos.y += offsetY + thatOffset;
			y += thatOffset;
			var tanRes = Math.atan2(nextPos.y - y, nextPos.x - x) / Math.PI;
			mAngle = tanRes * 180;
			// scale.y *= Math.abs(tanRes);
			angle = parentStrum.direction + offsetAngle + mAngle;
		}
		else
		{
			angle = offsetAngle + mAngle;
		}
	}

	// function updateStripTapNote() {}
	// function updateStripHoldNote() {}

	function basicFollowStrumNote(songSpeed:Float)
	{
		final downscrollMult:Byte = getCurrentDownScroll() ? -1 : 1;
		var _dist:Float = distance * baseScale * _lastStrumScale * downscrollMult;
		if(isSustainNote) // 🙏
		{
			flipY = downscrollMult == -1;
			// var downscrollFactor:Float = (1.0 + parentStrum._sinDir) / 2.0;
			// if (downscrollMult == 1)
			// 	downscrollFactor = 1.0 - downscrollFactor;
			// _originY = _facingVerticalMult * Note.swagWidth / 2.0;

			// _originY = Note.swagWidth / 2.0 * downscrollMult;
			// _originY = origin.y / 2.0 * downscrollMult;
			// _originY = frameHeight / 2.0 * downscrollMult;
			// _dist += _originY * baseScale;
			// _originY *= downscrollFactor;

			// _dist += origin.y / 2.0;

			// _originY *= baseScale;
			// _dist -= (frameHeight * scale.y - Note.swagWidth);

			// correctionOffset = Note.swagWidth / 2.0;
			// _dist -= downscrollFactor * (frameHeight * scale.y - Note.swagWidth / 2.0) * baseScale * _lastStrumScale;
			// _dist += Note.swagWidth / 2.0;

			if (downscrollMult == -1) // TODO?: A more accurate path from the direction of the parent string
			{
				_dist -= frameHeight * scale.y - Note.swagWidth / 2.0;
				correctionOffset = 0;
			}
			else
			{
				correctionOffset = Note.swagWidth / 2.0;
				// _dist -= Note.swagWidth / 2.0 * baseScale * _lastStrumScale * downscrollMult;
			}
		}

		if (copyAlpha)	alpha = parentStrum.alpha * multAlpha;
		if (copyX)
		{
			x = parentStrum.x + offsetX + parentStrum._cosDir * _dist;
		}
		if (copyY)
		{
			y = parentStrum.y + offsetY + parentStrum._sinDir * _dist + correctionOffset;
			/*
			if(isSustainNote && getCurrentDownScroll())
			{
				// if(PlayState.isPixelStage) y -= PlayState.daPixelZoom * 9.5;
				y -= parentStrum._sinDir * (frameHeight * scale.y - Note.swagWidth / 2.0);
				// if (prevNote != null) y -= (y - prevNote.y + prevNote.frameHeight * prevNote.scale.y) * e;
			}
			*/
			// else
			// {
			// 	y += parentStrum._sinDir * correctionOffset;
			// }
		}
		if (isSustainNote)
		{
			/*
			if (prevNote != null)
			{
				if (nextNote == null)
				{
					mAngle = prevNote.mAngle;
				}
				else
				{
					mAngle = Math.atan2(prevNote.y - y, prevNote.x - x) / Math.PI * 180 - 90;
				}
			}
			else
			{
				mAngle = 0;
			}
			*/
			mAngle = parentStrum.direction - 90;
		}
		else
		{
			mAngle = 0;
		}
		if (copyAngle)
		{
			if (isSustainNote)
			{
				angle = offsetAngle + mAngle;
			}
			else
			{
				angle = parentStrum.angle + offsetAngle;
			}
			// updateTrig();
		}
	}

	public function clipToStrumNote()
	{
		if(!isSustainNote || clipRect == null || parentStrum == null || !destroyOnHit || !parentStrum.sustainReduce || !noteWasHit)
			return;

		// if (Math.abs(distance) <= frameHeight * scale.y)

		// codename cliprect
		// final songSpeed = CoolUtil.quantize(_lastSongSpeed * multSpeed, 100.0);
		// final songSpeed = _lastSongSpeed * multSpeed;
		clipRect.y = -distance / scale.y * baseScale * _lastStrumScale;
		// if (parentStrum.downScroll)
		clipRect.height = frameHeight - clipRect.y;

		// clipRect.height = Math.max(clipRect.height, 0.0);
		// trace([distance, ID]);
		// clipRect = clipRect;
		// if (mustPress)	trace([clipRect, ID]);

		/*
		// psych cliprect
		clipRect.width = frameWidth;
		final centerY:Float = parentStrum.y + Note.swagWidth / 2.0 * parentStrum.baseScale;
		// final heightFactor:Float = parentStrum.y + Note.swagWidth / 2.0 * parentStrum.baseScale - y;
		if (parentStrum.downScroll)
		{
			if (y + height * baseScale * parentStrum.baseScale >= centerY)
			{
				clipRect.height = (centerY - y) / scale.y;
				clipRect.y = frameHeight - clipRect.height;
			}
		}
		else if (y <= centerY)
		{
			clipRect.y = (centerY - y) / scale.y;
			clipRect.height = frameHeight - clipRect.y;
		}
		clipRect = clipRect;
		*/
	}

	@:allow(game.objects.game.notes.NoteHoldCover)
	var _capturedHoldCover:NoteHoldCover = null;

	public function disconnectHoldCover()
	{
		if (_capturedHoldCover == null) return;
		_capturedHoldCover.playEnd();
	}
	public function hasHoldCover()
	{
		return _capturedHoldCover != null;
	}
	public function connectHoldCover(holdCover:NoteHoldCover)
	{
		if (_capturedHoldCover != null) return;
		_capturedHoldCover = holdCover;
	}
	public function getLastSustainNote():Note
	{
		if (tail.length > 0)
			return tail.getLast();
		if (isSustainNote)
		{
			var note:Note = this;
			while(note.nextNote != null)
			{
				note = note.nextNote;
			}
			return note;
		}
		return null;
	}

	@:allow(game.objects.game.notes.NoteSplash)
	@:noCompletion var _lastStrumScale:Float = 1.0;
	function scaleToStrumNote()
	{
		if (_lastStrumScale == parentStrum.baseScale)
			return;

		final ratio = parentStrum.baseScale / _lastStrumScale;
		scaleByRatio(ratio);

		final baseScaleFactor = (ratio - 1.0) / 2.0;
		multSpeed -= baseScaleFactor;
		offsetX -= Note.swagWidth * baseScaleFactor;
		if (!isSustainNote)
			offsetY -= Note.swagWidth * baseScaleFactor;

		_lastStrumScale = parentStrum.baseScale;
	}

	inline function scaleByRatio(ratio:Float)
	{
		scale.scale(ratio);
		offsetX *= ratio;
		offsetY *= ratio;
		updateHitbox();
	}

	public override function kill()
	{
		_extraData = null;
		colorSwap = null;
		parentStrum = null;
		rgbShader = null;
		noteSplashData = null;
		prevNote = null;
		nextNote = null;
		super.kill();
		disconnectHoldCover();
	}

	public override function destroy()
	{
		disconnectHoldCover();
		_extraData = null;
		colorSwap = null;
		parentStrum = null;
		rgbShader = null;
		noteSplashData = null;
		prevNote = null;
		nextNote = null;
		defScale = flixel.util.FlxDestroyUtil.put(defScale);
		super.destroy();
	}

	public override function toString():String
	{
		return FlxStringUtil.getDebugString([
			LabelValuePair.weak("strumTime", strumTime),
			LabelValuePair.weak("noteData", noteData),
			LabelValuePair.weak("noteDataReal", noteDataReal),
			LabelValuePair.weak("mustPress", mustPress),
			LabelValuePair.weak("isSustainNote", isSustainNote),
			LabelValuePair.weak("isLastSustain", isLastSustain),
			LabelValuePair.weak("skinType", skinType),
			LabelValuePair.weak("offsetX", offsetX),
			LabelValuePair.weak("offsetY", offsetY),
			LabelValuePair.weak("offsetAngle", offsetAngle),
			LabelValuePair.weak("multSpeed", multSpeed),
			LabelValuePair.weak("baseScale", baseScale),
			LabelValuePair.weak("active", active),
			LabelValuePair.weak("visible", visible),
		]);
	}
}