package game.objects;

#if VIDEOS_ALLOWED
import flixel.graphics.FlxGraphic;
import flixel.math.FlxMath;
import flixel.util.FlxColor;

import haxe.Constraints;
import haxe.Int64;
import haxe.io.Bytes;
import haxe.io.Path;

import hxvlc.externs.Types;
import hxvlc.openfl.Video;
import hxvlc.util.Location;
#if (hxvlc >= version("2.1.0"))
import hxvlc.util.macros.DefineMacro as Define;
#else
import hxvlc.util.macros.Define;
#end

import openfl.utils.Assets;

import sys.FileSystem;

// https://wiki.videolan.org/VLC_command-line_help/
class VideoSprite extends FlxSprite // #if (hxvlc < version("1.9.0")) implements hxvlc.flixel.FlxVideoSprite.IFlxVideoSprite #end
{
	// these are loading options that are just easier to understand lol
	public static final looping:String = ":input-repeat=65535";
	public static final muted:String = ":no-audio";

	/**
	 * Whether the video should automatically be paused when focus is lost or not.
	 *
	 * WARNING: Must be set before loading a video.
	 */
	public var autoPause:Bool = FlxG.autoPause;

	#if FLX_SOUND_SYSTEM
	/**
	 * Determines if Flixel automatically adjusts the volume based on the Flixel sound system's current volume.
	 */
	public var autoVolumeHandle:Bool = true;
	#end

	/**
	 * The video bitmap.
	 */
	public var bitmap(default, null):VideoHandler;

	public var autoScale:Bool = true;

	public var volume:Float = 1.;

	public var rate:Float = 1.;

	/**
	 * Internal tracker for whether the video is paused or not.
	 */
	@:noCompletion
	var resumeOnFocus:Bool = false;

	/**
	 * Creates a `FlxVideoSprite` at a specified position.
	 *
	 * @param x The initial X position of the sprite.
	 * @param y The initial Y position of the sprite.
	 */
	public function new(x = 0, y = 0):Void
	{
		super(x, y);

		bitmap = new VideoHandler(antialiasing);
		bitmap.forceRendering = true;
		bitmap.onOpening.add(() ->
		{
			if (bitmap == null)
				return;

			bitmap.role = hxvlc.externs.Types.LibVLC_Media_Player_Role_T.LibVLC_Role_Game;
			#if FLX_SOUND_SYSTEM
			#if (flixel >= "5.9.0")
			if (!FlxG.sound.onVolumeChange.has(onVolumeChange))
				FlxG.sound.onVolumeChange.add(onVolumeChange);
			#elseif (flixel < "5.9.0")
			if (!FlxG.signals.postUpdate.has(onVolumeUpdate))
				FlxG.signals.postUpdate.add(onVolumeUpdate);
			#end

			onVolumeChange(0.0);
			#end
		});
		bitmap.onFormatSetup.add(() ->
		{
			if (bitmap == null)
				return;

			if (bitmap.bitmapData != null)
				loadGraphic(flixel.graphics.FlxGraphic.fromBitmapData(bitmap.bitmapData, false, null, false));
			adjustSize();
		});
		bitmap.visible = false;
		FlxG.game.addChild(bitmap);
		makeGraphic(1, 1, FlxColor.TRANSPARENT);


		FlxG.cameras.cameraResized.add(cameraResized);
	}

	/**
	 * Call this function to load a video.
	 *
	 * @param location The local filesystem path or the media location url or the id of a open file descriptor or the bitstream input.
	 * @param options The additional options you can add to the LibVLC Media.
	 *
	 * @return `true` if the video loaded successfully or `false` if there's an error.
	 */
	public function load(location:Location, ?options:Array<String>):Bool
	{
		if (bitmap == null)
			return false;

		if (autoPause)
		{
			if (!FlxG.signals.focusGained.has(onFocusGained))
				FlxG.signals.focusGained.add(onFocusGained);

			if (!FlxG.signals.focusLost.has(onFocusLost))
				FlxG.signals.focusLost.add(onFocusLost);
		}

		if (location != null && (location is String))
		{
			final location:String = cast(location, String);

			if (!location.contains('://'))
			{
				final absolutePath:String = FileSystem.absolutePath(location);

				if (Assets.exists(location))
				{
					final assetPath:String = Assets.getPath(location);

					if (assetPath != null)
					{
						if (FileSystem.exists(assetPath) && Path.isAbsolute(assetPath))
							return bitmap.load(assetPath, options);
						else if (!Path.isAbsolute(assetPath))
						{
							try
							{
								final assetBytes:Bytes = Assets.getBytes(location);

								if (assetBytes != null)
									return bitmap.load(assetBytes, options);
							}
							catch (e:Dynamic)
							{
								// FlxG.log.error('Error loading asset bytes from location "$location": $e');
								Log('Error loading asset bytes from location "$location": $e', RED);

								return false;
							}
						}
					}

					return false;
				}
				else if (FileSystem.exists(absolutePath))
					return bitmap.load(absolutePath, options);
				else
				{
					Log('Unable to find the video file at location "$location".', RED);
					// FlxG.log.warn('Unable to find the video file at location "$location".');

					return false;
				}
			}
		}

		return bitmap.load(location, options);
	}

	/**
	 * Loads a media subitem from the current media's subitems list at the specified index.
	 *
	 * @param index The index of the subitem to load.
	 * @param options Additional options to configure the loaded subitem.
	 * @return `true` if the subitem was loaded successfully, `false` otherwise.
	 */
	public function loadFromSubItem(index:Int, ?options:Array<String>):Bool
	{
		return (bitmap == null) ? false : bitmap.loadFromSubItem(index, options);
	}

	/**
	 * Parses the current media item with the specified options.
	 *
	 * @param parse_flag The parsing option.
	 * @param timeout The timeout in milliseconds.
	 * @return `true` if parsing succeeded, `false` otherwise.
	 */
	public function parseWithOptions(parse_flag:Int, timeout:Int):Bool
	{
		return (bitmap == null) ? false : bitmap.parseWithOptions(parse_flag, timeout);
	}

	/**
	 * Stops parsing the current media item.
	 */
	public function parseStop():Void
	{
		if (bitmap != null)
			bitmap.parseStop();
	}

	/**
	 * Call this function to play a video.
	 *
	 * @return `true` if the video started playing or `false` if there"s an error.
	 */
	public function play():Bool
	{
		return (bitmap == null) ? false : bitmap.play();
	}

	/**
	 * Call this function to stop the video.
	 */
	public function stop():Void
	{
		if (bitmap != null)
			bitmap.stop();
	}

	/**
	 * Call this function to pause the video.
	 */
	public function pause():Void
	{
		if (bitmap != null)
			bitmap.pause();
	}

	/**
	 * Call this function to resume the video.
	 */
	public function resume():Void
	{
		if (bitmap != null)
			bitmap.resume();
	}

	/**
	 * Call this function to toggle the pause of the video.
	 */
	public function togglePaused():Void
	{
		if (bitmap != null)
			bitmap.togglePaused();
	}

	function onFocusGained():Void
	{
		if (resumeOnFocus)
		{
			resumeOnFocus = false;

			resume();
		}
	}

	function onFocusLost():Void
	{
		resumeOnFocus = bitmap == null ? false : bitmap.isPlaying;

		pause();
	}

	#if FLX_SOUND_SYSTEM
	/**
	 * Calculates and returns the current volume based on Flixel's sound settings by default.
	 *
	 * The volume is automatically clamped between `0` and `2.55` by the calling code. If the sound is muted, the volume is `0`.
	 *
	 * @return The calculated volume.
	 */
	public dynamic function getCalculatedVolume():Float
	{
		return FlxG.sound.muted ? 0 : FlxG.sound.volume * volume;
	}
	#end

	// Overrides
	public override function destroy():Void
	{
		if (FlxG.signals.focusGained.has(onFocusGained))
			FlxG.signals.focusGained.remove(onFocusGained);

		if (FlxG.signals.focusLost.has(onFocusLost))
			FlxG.signals.focusLost.remove(onFocusLost);

		if (FlxG.cameras.cameraResized.has(cameraResized))
			FlxG.cameras.cameraResized.remove(cameraResized);

		#if FLX_SOUND_SYSTEM
		#if (flixel >= "5.9.0")
		if (FlxG.sound.onVolumeChange.has(onVolumeChange))
			FlxG.sound.onVolumeChange.remove(onVolumeChange);
		#elseif (flixel < "5.9.0")
		if (FlxG.signals.postUpdate.has(onVolumeUpdate))
			FlxG.signals.postUpdate.remove(onVolumeUpdate);
		#end
		#end

		super.destroy();

		if (bitmap != null)
		{
			if (FlxG.game.contains(bitmap))
				FlxG.game.removeChild(bitmap);

			bitmap.dispose();
			bitmap = null;
		}
	}

	public override function kill():Void
	{
		pause();
		super.kill();
	}

	// https://github.com/DuskieWhy/Sonic-Legacy-Public/blob/main/source/gameObjects/PsychVideoSprite.hx
	public function addCallback(name:String, func:Function):Void
	{
		if (bitmap == null || func == null)
			return;

		switch (name)
		{
			case "onEnd" | "onEndReached":
				bitmap.onEndReached.add(cast func);

			case "onStart" | "onOpening":
				bitmap.onOpening.add(cast func);

			#if (hxvlc < version("2.0.1"))
			case "onFormat" | "onDisplay" | "onFormatSetup":
				bitmap.onFormatSetup.add(cast func);
			#else
			case "onFormat" | "onFormatSetup":
				bitmap.onFormatSetup.add(cast func);

			case "onDisplay":
				bitmap.onDisplay.add(cast func);
			#end

			case "onPlaying":
				bitmap.onPlaying.add(cast func);

			case "onStopped":
				bitmap.onStopped.add(cast func);

			case "onPaused":
				bitmap.onPaused.add(cast func);

			case "onEncounteredError":
				bitmap.onEncounteredError.add(cast func);

			case "onMediaChanged":
				bitmap.onMediaChanged.add(cast func);

			case "onCorked":
				bitmap.onCorked.add(cast func);

			case "onUncorked":
				bitmap.onUncorked.add(cast func);

			case "onTimeChanged":
				bitmap.onTimeChanged.add(cast func);

			case "onPositionChanged":
				bitmap.onPositionChanged.add(cast func);

			case "onLengthChanged":
				bitmap.onLengthChanged.add(cast func);

			case "onChapterChanged":
				bitmap.onChapterChanged.add(cast func);

			case "onMediaMetaChanged":
				bitmap.onMediaMetaChanged.add(cast func);

			case "onMediaParsedChanged":
				bitmap.onMediaParsedChanged.add(cast func);

			/*default:
				var getter:Function = cast Reflect.getField(bitmap, 'get_$name');
				if (getter != null)
				{
					var event:lime.app.Event<Function> = cast Reflect.callMethod(bitmap, getter, []);
					event.add(cast func);
				}*/
		}
	}

	public override function revive():Void
	{
		super.revive();
		resume();
	}

	public override function update(elapsed:Float):Void
	{
		if (/*bitmap != null &&*/ bitmap.isPlaying)
		{
			final curRate:Float = FlxG.timeScale * this.rate;
			if (bitmap.rate != curRate)
				bitmap.rate = curRate;
		}

		super.update(elapsed);
	}

	public var vSynsPos:Void -> Int64;
	public var vSynsMaxDelay:Int = 160;

	public override function draw():Void
	{
		// if (bitmap != null)
		// {
			if (bitmap.isPlaying && vSynsPos != null)
			{
				final diff:Int = FlxMath.absInt(cast (vSynsPos() - bitmap.time));
				if (diff > vSynsMaxDelay * bitmap.rate)
					bitmap.time += vSynsMaxDelay * FlxMath.signOf(diff);
			}
		// }
		super.draw();
	}

	@:noCompletion function cameraResized(camera:flixel.FlxCamera):Void
	{
		if (camera == this.camera)
			adjustSize();
	}

	@:noCompletion function adjustSize():Void
	{
		if (autoScale)
		{
			setGraphicSize(camera.width / camera.scaleX, camera.height / camera.scaleY);
			updateHitbox();
			screenCenter();
		}
	}

	#if FLX_SOUND_SYSTEM
	#if (flixel < "5.9.0")
	@:noCompletion
	private function onVolumeUpdate():Void
	{
		onVolumeChange(0.0);
	}
	#end

	@:noCompletion
	private function onVolumeChange(vol:Float):Void
	{
		if (bitmap == null) return;
		if (autoVolumeHandle)
			bitmap.volume = Math.floor(FlxMath.bound(getCalculatedVolume(), 0, 2.55) * Define.getFloat('HXVLC_FLIXEL_VOLUME_MULTIPLIER', 100));
	}
	#end

	@:noCompletion
	private override function set_antialiasing(value:Bool):Bool
	{
		if (bitmap != null)
			bitmap.smoothing = value;
		return antialiasing = value;
	}
}
#end
