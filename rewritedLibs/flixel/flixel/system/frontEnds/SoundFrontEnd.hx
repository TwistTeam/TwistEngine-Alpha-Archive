package flixel.system.frontEnds;

#if FLX_SOUND_SYSTEM
import flixel.FlxG;
import flixel.group.FlxGroup;
import flixel.input.keyboard.FlxKey;
import flixel.math.FlxMath;
import flixel.system.FlxAssets;
import flixel.sound.FlxSound;
import flixel.sound.FlxSoundGroup;
import flixel.system.ui.IFlxSoundTray;
import openfl.Assets;
import openfl.media.Sound;
#if (openfl >= "8.0.0")
import openfl.utils.AssetType;
#end

/**
 * Accessed via `FlxG.sound`.
 */
@:allow(flixel.FlxG)
@:access(flixel.sound.FlxSound)
class SoundFrontEnd
{
	/**
	 * A handy container for a background music object.
	 */
	public var music:FlxSound;

	/**
	 * Whether or not the game sounds are muted.
	 */
	public var muted:Bool = false;

	/**
	 * Set this hook to get a callback whenever the volume changes.
	 * Function should take the form myVolumeHandler(volume:Float).
	 */
	public var volumeHandler:Float->Void;

	#if FLX_KEYBOARD
	public var keysAllowed:Bool = true;

	/**
	 * The key codes used to increase volume (see FlxG.keys for the keys available).
	 * Default keys: + (and numpad +). Set to null to deactivate.
	 */
	public var volumeUpKeys:Array<FlxKey> = [PLUS, NUMPADPLUS];

	/**
	 * The keys to decrease volume (see FlxG.keys for the keys available).
	 * Default keys: - (and numpad -). Set to null to deactivate.
	 */
	public var volumeDownKeys:Array<FlxKey> = [MINUS, NUMPADMINUS];

	/**
	 * The keys used to mute / unmute the game (see FlxG.keys for the keys available).
	 * Default keys: 0 (and numpad 0). Set to null to deactivate.
	 */
	public var muteKeys:Array<FlxKey> = [ZERO, NUMPADZERO];
	#end

	#if FLX_SOUND_TRAY
	/**
	 * The sound tray display container.
	 * A getter for `FlxG.game.soundTray`.
	 */
	public var soundTray(get, never):IFlxSoundTray;

	public var countToChange(default, set):Int = game.backend.system.macros.MacroUtils.getDefineInt("SOUNDTRAY_BARS_COUNT", 10);
	function set_countToChange(val:Int)
	{
		volume = Math.fround(FlxMath.bound(volume, 0, 1) * val) / val;

		countToChange = val;
		return val;
	}
	public var soundTrayEnabled:Bool = true;

	inline function get_soundTray()
	{
		return FlxG.game.soundTray;
	}
	#end

	/**
	 * The group sounds played via playMusic() are added to unless specified otherwise.
	 */
	public var defaultMusicGroup:FlxSoundGroup = new FlxSoundGroup();

	/**
	 * The group sounds in load() / play() / stream() are added to unless specified otherwise.
	 */
	public var defaultSoundGroup:FlxSoundGroup = new FlxSoundGroup();

	/**
	 * A list of all the sounds being played in the game.
	 */
	public var list(default, null):FlxTypedGroup<FlxSound> = new FlxTypedGroup<FlxSound>();

	/**
	 * Set this to a number between 0 and 1 to change the global volume.
	 */
	public var volume(default, set):Float = 1;

	public var useLogarithmic:Bool = false;

	public var linearVolume(get, set):Float;

	/**
	 * Set up and play a looping background soundtrack.
	 *
	 * @param   embeddedMusic  The sound file you want to loop in the background.
	 * @param   volume         How loud the sound should be, from 0 to 1.
	 * @param   looped         Whether to loop this music.
	 * @param   group          The group to add this sound to.
	 */
	public function playMusic(embeddedMusic:FlxSoundAsset, volume = 1.0, looped = true, ?group:FlxSoundGroup):Void
	{
		if (music == null)
		{
			music = #if (lime_openal && !macro) new game.backend.system.audio.EffectSound() #else new FlxSound() #end;
		}
		else if (music.active)
		{
			music.stop();
		}

		music.loadEmbedded(embeddedMusic, looped);
		music.volume = volume;
		music.persist = true;
		music.group = (group == null) ? defaultMusicGroup : group;
		music.play();
	}

	/**
	 * Creates a new FlxSound object.
	 *
	 * @param   embeddedSound   The embedded sound resource you want to play.  To stream, use the optional URL parameter instead.
	 * @param   volume          How loud to play it (0 to 1).
	 * @param   looped          Whether to loop this sound.
	 * @param   group           The group to add this sound to.
	 * @param   autoDestroy     Whether to destroy this sound when it finishes playing.
	 *                          Leave this value set to "false" if you want to re-use this FlxSound instance.
	 * @param   autoPlay        Whether to play the sound.
	 * @param   url             Load a sound from an external web resource instead.  Only used if EmbeddedSound = null.
	 * @param   onComplete      Called when the sound finished playing.
	 * @param   onLoad          Called when the sound finished loading.  Called immediately for succesfully loaded embedded sounds.
	 * @return  A FlxSound object.
	 */
	public function load(?embeddedSound:FlxSoundAsset, volume = 1.0, looped = false, ?group:FlxSoundGroup, autoDestroy = false, autoPlay = false, ?url:String,
			?onComplete:Void->Void, ?onLoad:Void->Void):FlxSound
	{
		if ((embeddedSound == null) && (url == null))
		{
			FlxG.log.warn("FlxG.sound.load() requires either\nan embedded sound or a URL to work.");
			return null;
		}

		var sound:FlxSound = list.recycle(FlxSound);

		if (embeddedSound != null)
		{
			sound.loadEmbedded(embeddedSound, looped, autoDestroy, onComplete);
			loadHelper(sound, volume, group, autoPlay);
			// Call OnlLoad() because the sound already loaded
			if (onLoad != null && sound._sound != null)
				onLoad();
		}
		else
		{
			var loadCallback = onLoad;
			if (autoPlay)
			{
				// Auto play the sound when it's done loading
				loadCallback = function()
				{
					sound.play();

					if (onLoad != null)
						onLoad();
				}
			}

			sound.loadStream(url, looped, autoDestroy, onComplete, loadCallback);
			loadHelper(sound, volume, group);
		}

		return sound;
	}

	function loadHelper(sound:FlxSound, volume:Float, group:FlxSoundGroup, autoPlay = false):FlxSound
	{
		sound.volume = volume;

		if (autoPlay)
		{
			sound.play();
		}

		sound.group = (group == null) ? defaultSoundGroup : group;
		return sound;
	}

	/**
	 * Method for sound caching (especially useful on mobile targets). The game may freeze
	 * for some time the first time you try to play a sound if you don't use this method.
	 *
	 * @param   embeddedSound  Name of sound assets specified in your .xml project file
	 * @return  Cached Sound object
	 */
	public inline function cache(embeddedSound:String):Sound
	{
		// load the sound into the OpenFL assets cache
		if (Assets.exists(embeddedSound, AssetType.SOUND) || Assets.exists(embeddedSound, AssetType.MUSIC))
			return Assets.getSound(embeddedSound, true);
		FlxG.log.error('Could not find a Sound asset with an ID of \'$embeddedSound\'.');
		return null;
	}

	/**
	 * Calls FlxG.sound.cache() on all sounds that are embedded.
	 * WARNING: can lead to high memory usage.
	 */
	public function cacheAll():Void
	{
		for (id in Assets.list(AssetType.SOUND))
		{
			cache(id);
		}
	}

	/**
	 * Plays a sound from an embedded sound. Tries to recycle a cached sound first.
	 *
	 * @param   embeddedSound  The embedded sound resource you want to play.
	 * @param   volume         How loud to play it (0 to 1).
	 * @param   looped         Whether to loop this sound.
	 * @param   group          The group to add this sound to.
	 * @param   autoDestroy    Whether to destroy this sound when it finishes playing.
	 *                         Leave this value set to "false" if you want to re-use this FlxSound instance.
	 * @param   onComplete     Called when the sound finished playing
	 * @return  A FlxSound object.
	 */
	public function play(embeddedSound:FlxSoundAsset, volume = 1.0, looped = false, ?group:FlxSoundGroup, autoDestroy = true, ?onComplete:Void->Void):FlxSound
	{
		if ((embeddedSound is String))
		{
			embeddedSound = cache(embeddedSound);
		}
		var sound = list.recycle(FlxSound).loadEmbedded(embeddedSound, looped, autoDestroy, onComplete);
		return loadHelper(sound, volume, group, true);
	}

	/**
	 * Plays a sound from a URL. Tries to recycle a cached sound first.
	 * NOTE: Just calls FlxG.sound.load() with AutoPlay == true.
	 *
	 * @param   url          Load a sound from an external web resource instead.
	 * @param   volume       How loud to play it (0 to 1).
	 * @param   looped       Whether to loop this sound.
	 * @param   group        The group to add this sound to.
	 * @param   autoDestroy  Whether to destroy this sound when it finishes playing.
	 *                       Leave this value set to "false" if you want to re-use this FlxSound instance.
	 * @param   onComplete   Called when the sound finished playing
	 * @param   onLoad       Called when the sound finished loading.
	 * @return  A FlxSound object.
	 */
	public function stream(url:String, volume = 1.0, looped = false, ?group:FlxSoundGroup, autoDestroy = true, ?onComplete:Void->Void,
			?onLoad:Void->Void):FlxSound
	{
		return load(null, volume, looped, group, autoDestroy, true, url, onComplete, onLoad);
	}

	/**
	 * Pause all sounds currently playing.
	 */
	public function pause():Void
	{
		forEachSound(i -> if (i.exists && i.active) i.pause());
	}

	/**
	 * Resume playing existing sounds.
	 */
	public function resume():Void
	{
		forEachSound(i -> if (i.exists) i.resume());
	}

	/**
	 * Called by FlxGame on state changes to stop and destroy sounds.
	 *
	 * @param   forceDestroy  Kill sounds even if persist is true.
	 */
	public function destroy(forceDestroy = false):Void
	{
		if (forceDestroy)
			forEachSound(destroySound);
		else
			forEachSound(i -> if (!i.persist) destroySound(i));
		if (music != null && (forceDestroy || !music.persist))
		{
			music = null;
		}
	}

	function destroySound(sound:FlxSound):Void
	{
		defaultMusicGroup.remove(sound);
		defaultSoundGroup.remove(sound);
		sound.destroy();
	}

	public function forEachSound(job:FlxSound -> Void)
	{
		if (music != null)
		{
			job(music);
		}

		for (sound in list.members)
		{
			if (sound != null)
			{
				job(sound);
			}
		}
	}

	/**
	 * Toggles muted, also activating the sound tray.
	 */
	public function toggleMuted():Void
	{
		muted = !muted;

		if (volumeHandler != null)
		{
			volumeHandler(muted ? 0 : volume);
		}

		showSoundTray(true);
	}

	/**
	 * Changes the volume by a certain amount, also activating the sound tray.
	 */
	public function changeVolume(Amount:Float, ?forceSound:Bool = true):Void
	{
		muted = false;
		linearVolume = Math.fround(FlxMath.bound(linearVolume + Amount, 0, 1) * countToChange) / countToChange;
		#if FLX_SOUND_TRAY
		showSoundTray(Amount > 0, forceSound);
		#end
	}
	public function linearToLog(x:Float, minValue:Float = 0.001):Float
	{
		// Ensure x is between 0 and 1
		x = Math.max(0, Math.min(1, x));

		// Convert linear scale to logarithmic
		return Math.exp(Math.log(minValue) * (1 - x));
	}

	public function logToLinear(x:Float, minValue:Float = 0.001):Float
	{
		// Ensure x is between minValue and 1
		x = Math.max(minValue, Math.min(1, x));

		// Convert logarithmic scale to linear
		return 1 - (Math.log(x) / Math.log(minValue));
	}

	/**
	 * Shows the sound tray if it is enabled.
	 * @param up Whether or not the volume is increasing.
	 */
	public function showSoundTray(up:Bool = false, ?forceSound:Bool = true):Void
	{
		#if FLX_SOUND_TRAY
		if (FlxG.game.soundTray != null && soundTrayEnabled)
		{
			FlxG.game.soundTray.show(up, forceSound);
		}
		#end
	}

	function new()
	{
		#if FLX_SAVE
		loadSavedPrefs();
		#end
	}

	private var _changeVolumeHoldTime:Float = 0;

	/**
	 * Called by the game loop to make sure the sounds get updated each frame.
	 */

	inline static final _pressDelay:Float = 0.35;
	@:allow(flixel.FlxGame)
	function update(elapsed:Float):Void
	{
		#if FLX_KEYBOARD
		if (keysAllowed)
		{
			if (FlxG.keys.anyJustPressed(muteKeys))
			{
				toggleMuted();
				_changeVolumeHoldTime = 0;
			}
			else if (FlxG.keys.anyJustPressed(volumeUpKeys))
			{
				changeVolume(1 / countToChange);
				_changeVolumeHoldTime = 0;
			}
			else if (FlxG.keys.anyJustPressed(volumeDownKeys))
			{
				changeVolume(-1 / countToChange);
				_changeVolumeHoldTime = 0;
			}

			final pressedUp:Bool = FlxG.keys.anyPressed(volumeUpKeys);
			if(pressedUp || FlxG.keys.anyPressed(volumeDownKeys))
			{
				final checkLastHold:Int = Math.round((_changeVolumeHoldTime - _pressDelay) * 10);
				@:privateAccess
				_changeVolumeHoldTime += FlxG.game._elapsedMS / 1000;
				final checkNewHold:Int = Math.round((_changeVolumeHoldTime - _pressDelay) * 10);

				if(_changeVolumeHoldTime > _pressDelay && checkNewHold - checkLastHold > 0)
				{
					changeVolume((checkNewHold - checkLastHold) * (pressedUp ? 1 : -1) / countToChange, false);
				}
			}
		}
		#end
		if (music != null && music.active)
			music.update(elapsed);

		if (list != null && list.active)
			list.update(elapsed);
	}

	@:allow(flixel.FlxGame)
	function onFocusLost():Void
	{
		if (music != null)
		{
			music.onFocusLost();
		}

		for (sound in list.members)
		{
			if (sound != null)
			{
				sound.onFocusLost();
			}
		}
	}

	@:allow(flixel.FlxGame)
	function onFocus():Void
	{
		if (music != null)
		{
			music.onFocus();
		}

		for (sound in list.members)
		{
			if (sound != null)
			{
				sound.onFocus();
			}
		}
	}

	#if FLX_SAVE
	/**
	 * Loads saved sound preferences if they exist.
	 */
	function loadSavedPrefs():Void
	{
		if (!FlxG.save.isBound)
			return;

		if (FlxG.save.data.volume != null)
		{
			volume = FlxG.save.data.volume;
		}

		if (FlxG.save.data.mute != null)
		{
			muted = FlxG.save.data.mute;
		}
	}
	#end

	function set_volume(Volume:Float):Float
	{
		Volume = fixFloat(Volume);
		// Volume = FlxMath.bound(Volume, 0, 1);

		if (volumeHandler != null)
		{
			volumeHandler(muted ? 0 : Volume);
		}
		volume = Volume;
		// forEachSound(i -> if (i.exists) i.updateTransform());
		return volume;
	}


	function get_linearVolume():Float
	{
		return useLogarithmic ? logToLinear(volume) : volume;
	}
	function set_linearVolume(Volume:Float):Float
	{
		Volume = fixFloat(Volume);
		if (useLogarithmic)
			volume = linearToLog(Volume);
		else
			volume = Volume;
		return volume;
	}

	static function fixFloat(i) {
		if (!Math.isFinite(i)) // is `false`, otherwise the result is `true`.
		{
			i = 1;
			trace("gotcha");
		}
		else if (Math.isNaN(i))
		{
			i = 0;
			trace("gotcha");
		}
		return i;
	}
}
#end
