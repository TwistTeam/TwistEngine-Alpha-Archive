package flixel.system.ui;

#if FLX_SOUND_SYSTEM
import flixel.FlxG;
import flixel.math.FlxMath;
import flixel.system.FlxAssets;
import flixel.system.ui.FlxBaseSoundTray;
import flixel.util.FlxColor;
import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;
import openfl.utils.Assets;

/**
 * The flixel sound tray, the little volume meter that pops down sometimes.
 * Accessed via `FlxG.game.soundTray` or `FlxG.sound.soundTray`.
 */
class FlxSoundTray extends FlxBaseSoundTray
{
	/**
	 * Helps display the volume bars on the sound tray.
	 */
	var _bars:Array<Bitmap>;

	override function set_countOfBars(val)
	{
		if (countOfBars != val)
		{
			countOfBars = val;
			_reloadBars();
		}
		return val;
	}

	// public var shaderColor:ColorSwap = new ColorSwap();

	var _baseBitmapData:BitmapData;

	var bgMain:Bitmap;

	@:keep
	public function new()
	{
		super();

		// visible = false;
		bgMain = new Bitmap(new BitmapData(_width, 30, true, 0x7F000000), true);
		addChild(bgMain);

		var text = new TextField();
		text.width = bgMain.width;
		text.height = bgMain.height;
		text.multiline = false;
		text.wordWrap = true;
		text.selectable = false;

		var dtf:TextFormat = new TextFormat(Assets.getFont(
				game.backend.assets.AssetsPaths.font("VCR OSD Mono Cyr.ttf")
			)?.fontName ?? FlxAssets.FONT_DEFAULT, 10, 0xffffff);
		dtf.align = TextFormatAlign.CENTER;
		text.defaultTextFormat = dtf;
		addChild(text);
		text.text = "VOLUME";
		text.y = 16;
		game.backend.utils.CoolUtil.removeEventListeners(text);

		_baseBitmapData = new BitmapData(1, 1, false, FlxColor.WHITE);
		_reloadBars();

		y = -height;
		visible = false;
	}

	function _reloadBars()
	{
		_bars ??= new Array();

		while(_bars.length <= countOfBars)
		{
			var tmp = new Bitmap(_baseBitmapData);
			addChild(tmp);
			_bars.push(tmp);
		}
		for(i in _bars)
		{
			i.visible = false;
		}

		var bx:Float = 10;
		var by:Float = 14;
		var maxy:Float = 24;
		var _totalWidth:Float = _width - bx * 2;
		var _barWidth:Float = FlxMath.roundDecimal(_width / 2 / countOfBars, 1);
		_totalWidth -= _barWidth / 2;
		bx += _barWidth / 2;
		var _deltaX:Int = Math.round(_totalWidth / countOfBars);
		var _deltaHeight:Float = maxy - by;
		var _deltaY:Float = _deltaHeight / countOfBars;
		var bar:Bitmap;
		for (i in 0...countOfBars)
		{
			bar = _bars[i];
			bar.visible = true;
			bar.scaleX = _barWidth;
			bar.scaleY = FlxMath.roundDecimal(_deltaY * (i + 1), 1);

			bar.x = FlxMath.roundDecimal(bx, 1);
			bar.y = FlxMath.roundDecimal(by, 1);
			bx += _deltaX;
			by -= _deltaY;
		}
		_updateBars();
	}

	function _updateBars()
	{
		final globalVolume:Int = globalVolumeCount;
		final alpha:Float = FlxMath.lerp(0.35, 1, Math.pow(FlxG.sound.linearVolume, 0.5));
		for (i in 0...countOfBars)
		{
			_bars[i].alpha = i < globalVolume ? alpha : 0.3;
		}
	}

	public override function update(MS:Float):Void
	{
		// Animate stupid sound tray thing
		if (_timer >= 0)
		{
			_timer -= MS / 1000;
			y = y + (0 - y) * Math.min(MS / 25, 1);
		}
		else if (y > -height)
		{
			y -= (1 - Math.exp(-MS / 800)) * height;
			if (y <= -height)
			{
				active = visible = false;
				FlxG.save.flush();
				// trace("VOLUME SAVED");
			}
		}
		alpha = Math.pow(Math.min(y + height, height) / height, 1.75);
	}

	/**
	 * Makes the little volume tray slide out.
	 *
	 * @param	up Whether the volume is increasing.
	 */
	public override function show(up:Bool = false, ?forceSound:Bool = true):Void
	{
		var dirtyBars = globalVolumeCount != _lastVolumeCount || forceSound;
		super.show(up, forceSound);
		if (dirtyBars)
			_updateBars();
	}
}
#end
