package game.objects;

#if VIDEOS_ALLOWED
import hxvlc.openfl.Video;

class VideoHandler extends Video
{
	#if (hxvlc < version("2.0.1")) // What the hell
	@:deprecated("use onFormatSetup")
	public var onDisplay(get, never):lime.app.Event<Void->Void>;
	inline function get_onDisplay() return onFormatSetup;
	#end

	/**
	 * Initializes a Video object.
	 *
	 * @param smoothing Whether or not the object is smoothed when scaled.
	 */
	public function new(smoothing:Bool = true):Void
	{
		super(smoothing);

		// Video.useTexture = ClientPrefs.cacheOnGPU; // TODO?: Separate option for using a video card
	}
}
#end