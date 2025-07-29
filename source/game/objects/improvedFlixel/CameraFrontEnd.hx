package game.objects.improvedFlixel;

class CameraFrontEnd extends flixel.system.frontEnds.CameraFrontEnd
{
	/**
	 * Dumps all the current cameras and resets to just one camera.
	 * Handy for doing split-screen especially.
	 *
	 * @param	NewCamera	Optional; specify a specific camera object to be the new main camera.
	 */
	@:access(flixel.FlxCamera._defaultCameras)
	public override function reset(?NewCamera:flixel.FlxCamera):Void
	{
		cameraReset.dispatch(NewCamera);
		while (list.length > 0)
			remove(list[0]);

		if (NewCamera == null)
			NewCamera = new game.objects.improvedFlixel.FlxCamera(0, 0, FlxG.width, FlxG.height); // bind to improved camera

		FlxG.camera = add(NewCamera);
		NewCamera.ID = 0;

		FlxCamera._defaultCameras = defaults;
		cameraResetPost.dispatch(NewCamera);
	}
}
