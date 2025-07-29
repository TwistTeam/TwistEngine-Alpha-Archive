package game.backend.utils;

import flixel.graphics.frames.FlxFrame;
import openfl.Vector;

class FlxTringlesUtils
{
	private function appendUVByFrane(frame:FlxFrame, uv:Vector<Float>, ?flipX:Bool, ?flipY:Bool, ?subY:UInt = 1, ?holdSubdivisions:UInt = 1)
	{
		var subIndex = subY * 8;
		var frameRect = frame.uv;

		if (!flipY)
			subY = (holdSubdivisions - 1) - subY;
		var uvSub = 1.0 / holdSubdivisions;
		var uvOffset = uvSub * subY;

		var top:Float = 0.0;
		var bottom:Float = 0.0;
		switch (frame.angle)
		{
			case ANGLE_0:
				var height = frameRect.height - frameRect.y;
				top = frameRect.y + (uvSub + uvOffset) * height;
				bottom = frameRect.y + uvOffset * height;
			case ANGLE_90:
				var width = frameRect.width - frameRect.x;
				top = frameRect.x + (uvSub + uvOffset) * width;
				bottom = frameRect.x + uvOffset * width;
			case ANGLE_270:
				var width = frameRect.x - frameRect.width;
				top = frameRect.width + uvOffset * width;
				bottom = frameRect.width + (uvSub + uvOffset) * width;
		}

		if (flipY)
		{
			var ogTop = top;
			top = bottom;
			bottom = ogTop;
		}

		switch (frame.angle)
		{
			case ANGLE_0:
				uv[subIndex] = uv[subIndex + 4] = frameRect.x;
				uv[subIndex + 2] = uv[subIndex + 6] = frameRect.width;
				uv[subIndex + 1] = uv[subIndex + 3] = top;
				uv[subIndex + 5] = uv[subIndex + 7] = bottom;
			case ANGLE_90:
				uv[subIndex] = uv[subIndex + 4] = top;
				uv[subIndex + 2] = uv[subIndex + 6] = bottom;
				uv[subIndex + 1] = uv[subIndex + 3] = frameRect.height;
				uv[subIndex + 5] = uv[subIndex + 7] = frameRect.y;
			case ANGLE_270:
				uv[subIndex] = uv[subIndex + 2] = bottom;
				uv[subIndex + 4] = uv[subIndex + 6] = top;
				uv[subIndex + 1] = uv[subIndex + 5] = frameRect.y;
				uv[subIndex + 3] = uv[subIndex + 7] = frameRect.height;
		}
	}
}
