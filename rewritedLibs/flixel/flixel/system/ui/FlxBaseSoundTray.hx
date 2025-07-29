package flixel.system.ui;

#if FLX_SOUND_SYSTEM
import flixel.FlxG;
import flixel.FlxGame;
import flixel.math.FlxMath;
import flixel.system.ui.IFlxSoundTray;
import haxe.io.Path;
import openfl.Lib;
import openfl.display.DisplayObject;
import openfl.display.DisplayObjectContainer;
import openfl.display.Sprite;
import openfl.media.Sound;
import openfl.utils.Assets;

/**
 * Basic FlxSoundTray implementation
 * @since 5.6.2-TWIST-PSYCH
 */
class FlxBaseSoundTray extends DisplayObjectContainer implements IFlxSoundTray
{
	public var active:Bool;
	var _game:FlxGame = null;

	/**
	 * Helps us auto-hide the sound tray after a volume change.
	 */
	@:noCompletion var _timer:Float;

	var _sound:FlxSound;

	/**
	 * How wide the sound tray background is.
	 */
	var _width:Int = game.backend.system.macros.MacroUtils.getDefineInt("SOUNDTRAY_WIDTH", 80);

	@:noCompletion var _defaultScale:Float = 1.5;

	public var countOfBars(default, set):Int = game.backend.system.macros.MacroUtils.getDefineInt("SOUNDTRAY_BARS_COUNT", 10);
	function set_countOfBars(val)
	{
		return countOfBars = val;
	}

	/**The sound used when increasing the volume.**/
	public var volumeSimpleSound:String = "system/volumeBeep";
	public var volumeUpSound:String =	  "system/volumeUP";
	public var volumeDownSound:String =	  "system/volumeDOWN";

	var _soundsCashe:Map<String, Sound> = new Map();

	/**Whether or not changing the volume should make noise.**/
	public var silent:Bool = false;

	public var globalVolumeCount(get, never):Int;

	function get_globalVolumeCount() return FlxG.sound.muted ? 0 : Math.round(FlxG.sound.linearVolume * countOfBars);

	/**
	 * Sets up the "sound tray", the little volume meter that pops down sometimes.
	 */
	@:keep
	public function new()
	{
		super();
		mouseEnabled = true;
		__drawableType = SPRITE; // fix render

		// visible = false;
		scaleX = _defaultScale;
		scaleY = _defaultScale;

		y = -height;
		visible = false;

		_sound = new FlxSound();
		FlxG.signals.preStateSwitch.add(_onSwitchState);

		screenCenter();
	}

	function _onSwitchState()
	{
		_soundsCashe.clear();
	}

	public function update(MS:Float):Void
	{
		if (_timer >= 0)
		{
			_timer -= MS / 1000;
		}
		else if (y > -height)
		{
			active = visible = false;
			// FlxG.save.flush();
			// trace("VOLUME SAVED");
		}
	}

	function returnSound(key:String):Sound
	{
		#if !macro
		if (Path.extension(key) == '') key += '.${game.backend.system.Paths.SOUND_EXT}';
		key = "assets/sounds/" + key;
		if (!_soundsCashe.exists(key))
		{
			_soundsCashe.set(key, Assets.exists(key) ? Assets.getSound(key) : null);
		}
		#end
		return _soundsCashe.get(key);
	}

	@:noCompletion var _lastVolumeCount:Int = -1;

	public function show(up:Bool = false, ?forceSound:Bool = true):Void
	{
		if (globalVolumeCount != _lastVolumeCount || forceSound)
		{
			_lastVolumeCount = globalVolumeCount;
			if (!silent && forceSound)
			{
				var sound = returnSound(up ? volumeUpSound : volumeDownSound) ?? returnSound(volumeSimpleSound);
				if (sound != null)
				{
					FlxG.sound.list.add(_sound);
					_sound.loadEmbedded(sound);
					_sound.useTimeScaleToPitch = false;
					_sound.pitch = FlxMath.lerp(0.9, 1.1, FlxMath.bound(FlxG.sound.linearVolume, 0, 1)) + (up ? 1 : -1) / 20;
					_sound.play(true);
					FlxG.sound.list.remove(_sound);
				}
			}

			#if FLX_SAVE
			// Save sound preferences
			// if (FlxG.save.isBound)
			// {
				FlxG.save.data.mute = FlxG.sound.muted;
				FlxG.save.data.volume = FlxG.sound.volume;
			// }
			#end
		}
		active = visible = true;
		_timer = 1;
	}

	public function screenCenter():Void
	{
		if (_game == null) return;

		scaleX = _defaultScale;
		scaleY = _defaultScale;

		x = 0.5 * (Lib.current.stage.stageWidth - _width * _defaultScale) - _game.x;
	}

	@:access(flixel.FlxGame)
	public function onAdded(game:FlxGame, ?oldSoundTray:IFlxSoundTray):Void
	{
		_game = game;

		var index:Int = oldSoundTray == null || !Std.isOfType(oldSoundTray, DisplayObject) ? game.numChildren : game.getChildIndex(cast oldSoundTray);
		game.addChildAt(this, index);
	}

	public function dispose():Void
	{
		_game.removeChild(this);
		_soundsCashe.clear();
		FlxG.signals.preStateSwitch.remove(_onSwitchState);
		_game = null;
	}
}
#end