package game.objects.game.notes;

import flixel.math.FlxPoint;

import game.objects.game.notes.Note;
import game.shaders.ColorSwap;
import game.shaders.PixelSplashShader.PixelSplashShaderRef;
import game.shaders.RGBPalette;
import game.states.playstate.PlayState;

class NoteSplash extends FlxSprite
{
	public var rgbShader:PixelSplashShaderRef;
	public var colorSwap:ColorSwap;
	public var textureLoaded:String = null;

	public var baseScale(default, set):Float = 1.;
	public var parentGroup(default, null):Null<NoteSplashGroup>;

	@:noCompletion var _lastBaseScale:Float = 1.;
	@:noCompletion function set_baseScale(e)
	{
		var finalScale:Float = ClientPrefs.noteSplashesScale * e * _lastBaseScale;
		scale.set(finalScale, finalScale);
		return e = baseScale;
	}

	public override function destroy()
	{
		colorSwap = null;
		rgbShader = null;
		parentGroup = null;
		super.destroy();
	}

	public function getDefaultTexture() return parentGroup?.defaultTexture ?? Constants.DEFAULT_NOTESPLASH_SKIN;

	public function new(x:Float = 0, y:Float = 0, note:Int = 0, ?parentGroup:NoteSplashGroup)
	{
		super(x, y);
		this.parentGroup = parentGroup;

		var skin:String = getDefaultTexture();
		loadAnims(skin);
		setupNoteSplash(x, y, note, skin);
		animation.finishCallback = _ -> kill();
	}

	@:noCompletion public var _lastAlpha:Float = 1;

	@:noCompletion public function _updateAlphaSetting()
	{
		alpha = _lastAlpha * ClientPrefs.splashAlpha;
	}

	public function setupNoteSplash(x:Float, y:Float, noteData:Int = 0, ?skin:String, ?note:Note)
	{
		if (skin == null)
			skin = getDefaultTexture();
		final splashData = note?.noteSplashData;
		if (note == null)
		{
			_lastBaseScale = 1.;
		}
		else
		{
			_lastBaseScale = note.baseScale * note._lastStrumScale;
			if (splashData != null)
			{
				if (splashData.disabled)
				{
					kill();
					return;
				}
				if (splashData.texture != null)
					skin = splashData.texture;
				antialiasing = splashData.antialiasing;
				if (splashData.useColorSwapShader)
				{
					if (colorSwap == null)
						colorSwap = new ColorSwap();
					if (shader != colorSwap.shader)
						shader = colorSwap.shader;
					colorSwap.hue = note.noteSplashHue;
					colorSwap.saturation = note.noteSplashSat;
					colorSwap.brightness = note.noteSplashBrt;
				}
				else if (splashData.useRGBShader)
				{
					if (colorSwap == null)
						rgbShader = new PixelSplashShaderRef();
					if (shader != rgbShader.shader)
						shader = rgbShader.shader;
					if (note.skinType == PIXEL_NOTE)
					{
						rgbShader.pixel = true;
						antialiasing = false;
					}
					else
						rgbShader.pixel = false;
					var tempShader:RGBPalette = null;
					if (splashData.useGlobalShader)
					{
						if (splashData.r != -1)
							note.rgbShader.r = splashData.r;
						if (splashData.g != -1)
							note.rgbShader.g = splashData.g;
						if (splashData.b != -1)
							note.rgbShader.b = splashData.b;
						tempShader = note.rgbShader.parent;
					}
					else
						tempShader = Note.globalRgbShaders[noteData];
					rgbShader.copyValues(tempShader);
				}
			}
		}
		baseScale = baseScale;
		if (textureLoaded != skin && skin != null)
			loadAnims(skin);
		if (note != null)
			scrollFactor.copyFrom(note.scrollFactor);
		else
			scrollFactor.set(1.0, 1.0);

		animation.play('note$noteData-${FlxG.random.int(1, 2)}', true);
		if (animation.curAnim == null)
		{
			kill();
			return;
			// destroy();
		}
		_lastAlpha = splashData?.a ?? 1;
		_updateAlphaSetting();

		if (parentGroup != null)
		{
			final randFPSBound = parentGroup.randAddedFPS;
			final maxRandomAngle = parentGroup.maxRandomAngle;
			final parentOffsets = parentGroup.offset;
			if (randFPSBound.active)
				animation.curAnim.frameRate = 24 + FlxG.random.int(randFPSBound.min, randFPSBound.max);
			else
				animation.curAnim.frameRate = 24;
			angle = maxRandomAngle > 0 ? FlxG.random.int(-maxRandomAngle, maxRandomAngle) : 0;
			centerOffsets();
			offset.add(parentOffsets.x * ClientPrefs.noteSplashesScale, parentOffsets.y * ClientPrefs.noteSplashesScale);
		}
		else
		{
			animation.curAnim.frameRate = 24;
			angle = 0;
			centerOffsets();
		}
		setPosition(x - width / 2, y - height / 2);
	}

	public function loadAnims(skin:String)
	{
		frames = Paths.getSparrowAtlas(skin);
		for (i in 1...3)
		{
			animation.addByPrefix('note0-$i', 'note splash purple $i', 24, false);
			animation.addByPrefix('note1-$i', 'note splash blue $i', 24, false);
			animation.addByPrefix('note2-$i', 'note splash green $i', 24, false);
			animation.addByPrefix('note3-$i', 'note splash red $i', 24, false);
		}
		textureLoaded = skin;
	}
}
