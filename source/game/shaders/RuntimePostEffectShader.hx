package game.shaders;

import flixel.math.FlxPoint;
import flixel.FlxCamera;
import flixel.graphics.frames.FlxFrame;
import flixel.addons.display.FlxRuntimeShader;

class RuntimePostEffectShader extends FlxRuntimeShader
{
	@:glVertexHeader('
		// normalized screen coord
		//	 (0, 0) is the top left of the window
		//	 (1, 1) is the bottom right of the window
		varying vec2 screenCoord;
	', true)
	@:glVertexBody('
		screenCoord = vec2(
			openfl_TextureCoord.x > 0.0 ? 1.0 : 0.0,
			openfl_TextureCoord.y > 0.0 ? 1.0 : 0.0
		);
	')
	@:glFragmentHeader('
		// normalized screen coord
		//	 (0, 0) is the top left of the window
		//	 (1, 1) is the bottom right of the window
		varying vec2 screenCoord;

		// equals (FlxG.width, FlxG.height)
		uniform vec2 uScreenResolution;

		// equals (camera.viewLeft, camera.viewTop, camera.viewRight, camera.viewBottom)
		uniform vec4 uCameraBounds;

		// equals (frame.left, frame.top, frame.right, frame.bottom)
		uniform vec4 uFrameBounds;

		// screen coord -> world coord conversion
		// returns world coord in px
		vec2 screenToWorld(vec2 screenCoord) {
			float left = uCameraBounds.x;
			float top = uCameraBounds.y;
			float right = uCameraBounds.z;
			float bottom = uCameraBounds.w;
			vec2 scale = vec2(right - left, bottom - top);
			vec2 offset = vec2(left, top);
			return screenCoord * scale + offset;
		}

		// world coord -> screen coord conversion
		// returns normalized screen coord
		vec2 worldToScreen(vec2 worldCoord) {
			float left = uCameraBounds.x;
			float top = uCameraBounds.y;
			float right = uCameraBounds.z;
			float bottom = uCameraBounds.w;
			vec2 scale = vec2(right - left, bottom - top);
			vec2 offset = vec2(left, top);
			return (worldCoord - offset) / scale;
		}

		// screen coord -> frame coord conversion
		// returns normalized frame coord
		vec2 screenToFrame(vec2 screenCoord) {
			float left = uFrameBounds.x;
			float top = uFrameBounds.y;
			float right = uFrameBounds.z;
			float bottom = uFrameBounds.w;
			float width = right - left;
			float height = bottom - top;

			float clampedX = clamp(screenCoord.x, left, right);
			float clampedY = clamp(screenCoord.y, top, bottom);

			return vec2(
				(clampedX - left) / (width),
				(clampedY - top) / (height)
			);
		}

		// internally used to get the maximum `openfl_TextureCoordv`
		vec2 bitmapCoordScale() {
			return openfl_TextureCoordv / screenCoord;
		}

		// internally used to compute bitmap coord
		vec2 screenToBitmap(vec2 screenCoord) {
			return screenCoord * bitmapCoordScale();
		}

		// samples the frame buffer using a screen coord
		vec4 sampleBitmapScreen(vec2 screenCoord) {
			return texture2D(bitmap, screenToBitmap(screenCoord));
		}

		// samples the frame buffer using a world coord
		vec4 sampleBitmapWorld(vec2 worldCoord) {
			return sampleBitmapScreen(worldToScreen(worldCoord));
		}

		// is used to trim coordinates on the frame
		vec2 screenClampByFrame(vec2 screenCoord) {
			return clamp(screenCoord, uFrameBounds.xz, uFrameBounds.yw);
		}

		bool screenIsOverlappedByFrame(vec2 screenCoord) {
			vec2 s = step(uFrameBounds.xz, screenCoord) - step(uFrameBounds.yw, screenCoord);
			return s.x * s.y != 0.0;
		}
	', true)
	public function new(?fragmentSource:String, ?vertexSource:String, ?glVersion:String)
	{
		super(fragmentSource, vertexSource, glVersion);
		uScreenResolution.value = [FlxG.width, FlxG.height];
		uCameraBounds.value = [0, 0, FlxG.width, FlxG.height];
		uFrameBounds.value = [0, 0, FlxG.width, FlxG.height];
	}

	public function updateViewInfo(camera:FlxCamera, ?screenWidth:Float, ?screenHeight:Float, ?offset:FlxPoint, ?scrollFactor:FlxPoint):Void
	{
		uScreenResolution.value = [screenWidth ?? camera.width, screenHeight ?? camera.height];

		// var _rect = FlxRect.get();
		if (offset != null || scrollFactor != null)
		{
			if (offset != null)
				camera.scroll.add(offset.x, offset.y);
			if (scrollFactor != null)
				camera.scroll.scale(scrollFactor.x, scrollFactor.y);

			uCameraBounds.value = [camera.viewLeft, camera.viewTop, camera.viewRight, camera.viewBottom];

			if (scrollFactor != null)
			{
				camera.scroll.scale(1 / scrollFactor.x, 1 / scrollFactor.y);
				scrollFactor.putWeak();
			}

			if (offset != null)
			{
				camera.scroll.subtract(offset.x, offset.y);
				offset.putWeak();
			}
		}
		else
		{
			uCameraBounds.value = [camera.viewLeft, camera.viewTop, camera.viewRight, camera.viewBottom];
		}
	}

	public function updateFrameInfo(?frame:FlxFrame)
	{
		if (frame != null)
		{
			uFrameBounds.value = [0.0, 0.0, 1.0, 1.0];
		}
		else
		{
			// NOTE: uv.width is actually the right pos and uv.height is the bottom pos
			uFrameBounds.value = [frame.uv.x, frame.uv.y, frame.uv.width, frame.uv.height];
		}
	}
}
