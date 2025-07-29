package game.objects.ui;

import flixel.graphics.frames.FlxFrame;

class SliceSprite extends FlxSprite { // todo: into FlxStrip
	public var bWidth:Int = 120;
	public var bHeight:Int = 20;
	public var framesOffset:Int = 0;

	public function new(x:Float, y:Float, w:Int, h:Int, path:String) {
		super(x, y);

		frames = Paths.getAtlas(path);
		resize(w, h);
		updateFrames();
	}

	public function resize(w:Int, h:Int) {
		bWidth = w;
		bHeight = h;
	}

	var topleft:FlxFrame;
	var top:FlxFrame;
	var topright:FlxFrame;
	var middleleft:FlxFrame;
	var middle:FlxFrame;
	var middleright:FlxFrame;
	var bottomleft:FlxFrame;
	var bottom:FlxFrame;
	var bottomright:FlxFrame;

	public function updateFrames(){
		topleft = frames.frames[framesOffset];
		top = frames.frames[framesOffset + 1];
		topright = frames.frames[framesOffset + 2];
		middleleft = frames.frames[framesOffset + 3];
		middle = frames.frames[framesOffset + 4];
		middleright = frames.frames[framesOffset + 5];
		bottomleft = frames.frames[framesOffset + 6];
		bottom = frames.frames[framesOffset + 7];
		bottomright = frames.frames[framesOffset + 8];
	}

	public override function destroy(){
		topleft = null;
		top = null;
		topright = null;
		middleleft = null;
		middle = null;
		middleright = null;
		bottomleft = null;
		bottom = null;
		bottomright = null;
		super.destroy();
	}

	public var drawTop:Bool = true;
	public var drawMiddle:Bool = true;
	public var drawBottom:Bool = true;

	public override function draw() @:privateAccess {
		final x:Float = this.x;
		final y:Float = this.y;

		if (visible && !(bWidth == 0 || bHeight == 0)) {

			// TOP
			if (drawTop) {
				// TOP LEFT
				frame = topleft;
				setPosition(x, y);
				__setSize(
					topleft.frame.width * Math.min(bWidth/(topleft.frame.width*2), 1),
					topleft.frame.height * Math.min(bHeight/(topleft.frame.height*2), 1)
				);
				super.draw();

				// TOP
				if (bWidth > topleft.frame.width + topright.frame.width) {
					frame = top;
					setPosition(x + topleft.frame.width, y);
					__setSize(bWidth - topleft.frame.width - topright.frame.width, top.frame.height * Math.min(bHeight/(top.frame.height*2), 1));
					super.draw();
				}

				// TOP RIGHT
				setPosition(x + bWidth - (topright.frame.width * Math.min(bWidth/(topright.frame.width*2), 1)), y);
				frame = topright;
				__setSize(
					topright.frame.width * Math.min(bWidth/(topright.frame.width*2), 1),
					topright.frame.height * Math.min(bHeight/(topright.frame.height*2), 1)
				);
				super.draw();
			}

			// MIDDLE
			if (drawMiddle && bHeight > top.frame.height + bottom.frame.height) {
				var middleHeight:Float = bHeight - (topleft.frame.height * Math.min(bHeight/(topleft.frame.height*2), 1)) -
				bottomleft.frame.height * Math.min(bHeight/(bottomleft.frame.height*2), 1);

				// MIDDLE LEFT
				frame = middleleft;
				setPosition(x, y + top.frame.height);
				__setSize(middleleft.frame.width * Math.min(bWidth/(middleleft.frame.width*2), 1), middleHeight);
				super.draw();

				if (bWidth > (middleleft.frame.width * Math.min(bWidth/(middleleft.frame.width*2), 1)) + middleright.frame.width) {
					// MIDDLE
					frame = middle;
					setPosition(x + topleft.frame.width, y + top.frame.height);
					__setSize(bWidth - middleleft.frame.width - middleright.frame.width, middleHeight);
					super.draw();
				}

				// MIDDLE RIGHT
				frame = middleright;
				setPosition(x + bWidth - (topright.frame.width * Math.min(bWidth/(topright.frame.width*2), 1)), y + top.frame.height);
				__setSize(middleright.frame.width * Math.min(bWidth/(middleright.frame.width*2), 1), middleHeight);
				super.draw();
			}

			// BOTTOM
			if (drawBottom) {
				// BOTTOM LEFT
				frame = bottomleft;
				setPosition(x, y + bHeight - (bottomleft.frame.height * Math.min(bHeight/(bottomleft.frame.height*2), 1)));
				__setSize(
					bottomleft.frame.width * Math.min(bWidth/(bottomleft.frame.width*2), 1),
					bottomleft.frame.height * Math.min(bHeight/(bottomleft.frame.height*2), 1)
				);
				super.draw();

				if (bWidth > bottomleft.frame.width + bottomright.frame.width) {
					// BOTTOM
					frame = bottom;
					setPosition(x + bottomleft.frame.width, y + bHeight - (bottom.frame.height * Math.min(bHeight/(bottom.frame.height*2), 1)));
					__setSize(bWidth - bottomleft.frame.width - bottomright.frame.width, bottom.frame.height * Math.min(bHeight/(bottom.frame.height*2), 1));
					super.draw();
				}

				// BOTTOM RIGHT
				frame = bottomright;
				setPosition(
					x + bWidth - (bottomright.frame.width * Math.min(bWidth/(bottomright.frame.width*2), 1)),
					y + bHeight - (bottomright.frame.height * Math.min(bHeight/(bottomright.frame.height*2), 1))
				);
				__setSize(
					bottomright.frame.width * Math.min(bWidth/(bottomright.frame.width*2), 1),
					bottomright.frame.height * Math.min(bHeight/(bottomright.frame.height*2), 1)
				);
				super.draw();
			}
		}

		setPosition(x, y);
	}

	private function __setSize(Width:Float, Height:Float) {
		var newScaleX:Float = Width / frameWidth;
		var newScaleY:Float = Height / frameHeight;
		scale.set(newScaleX, newScaleY);

		if (Width <= 0)
			scale.x = newScaleY;
		else if (Height <= 0)
			scale.y = newScaleX;

		updateHitbox();
	}
}

/*
import flixel.math.FlxPoint;
import flixel.graphics.frames.FlxFrame;
import flixel.graphics.tile.FlxDrawTrianglesItem.DrawData;

class SliceSprite extends FlxStrip {
	public var bWidth:Int = 120;
	public var bHeight:Int = 20;
	public var framesOffset:Int = 0;

	public function new(x:Float, y:Float, w:Int, h:Int, path:String) {
		super(x, y);

		frames = Paths.getAtlas(path);
		resize(w, h);
		updateFrames();
	}

	public function resize(w:Int, h:Int) {
		bWidth = w;
		bHeight = h;
	}

	var topleft:FlxFrame;
	var top:FlxFrame;
	var topright:FlxFrame;
	var middleleft:FlxFrame;
	var middle:FlxFrame;
	var middleright:FlxFrame;
	var bottomleft:FlxFrame;
	var bottom:FlxFrame;
	var bottomright:FlxFrame;

	public var drawTop:Bool = true;
	public var drawMiddle:Bool = true;
	public var drawBottom:Bool = true;

	public function updateFrames()
	{
		topleft = frames.frames[framesOffset];
		top = frames.frames[framesOffset + 1];
		topright = frames.frames[framesOffset + 2];
		middleleft = frames.frames[framesOffset + 3];
		middle = frames.frames[framesOffset + 4];
		middleright = frames.frames[framesOffset + 5];
		bottomleft = frames.frames[framesOffset + 6];
		bottom = frames.frames[framesOffset + 7];
		bottomright = frames.frames[framesOffset + 8];
		updateUV();
	}

	public function updateUV()
	{
		vertices.splice(0, vertices.length);
		indices.splice(0, indices.length);
		uvtData.splice(0, uvtData.length);

		var totalFrames:Array<FlxFrame> = [];

		if (drawTop)
		{
			totalFrames.push(topleft);
			totalFrames.push(top);
			totalFrames.push(topright);
		}
		if (drawMiddle)
		{
			totalFrames.push(middleleft);
			totalFrames.push(middle);
			totalFrames.push(middleright);
		}
		if (drawBottom)
		{
			totalFrames.push(bottomleft);
			totalFrames.push(bottom);
			totalFrames.push(bottomright);
		}
		if (totalFrames.length > 0)
		{
			var lastX:Float = 0;
			var lastY:Float = 0;
			var i:Int = 0;
			var point = FlxPoint.get();
			for (j => frame in totalFrames)
			{
				point.set(lastX, lastY);
				vertices.push(point.x);
				vertices.push(point.y);

				uvtData.push(frame.uv.x);
				uvtData.push(frame.uv.y);

				point.set(frame.frame.width + lastX, lastY);

				vertices.push(point.x);
				vertices.push(point.y);

				uvtData.push(frame.uv.width);
				uvtData.push(frame.uv.y);

				point.set(frame.frame.width + lastX, frame.frame.height + lastY);

				vertices.push(point.x);
				vertices.push(point.y);

				uvtData.push(frame.uv.width);
				uvtData.push(frame.uv.height);

				point.set(lastX, frame.frame.height + lastY);

				vertices.push(point.x);
				vertices.push(point.y);

				uvtData.push(frame.uv.x);
				uvtData.push(frame.uv.height);

				indices.push(indices.length);
				indices.push(indices.length); // + 1
				indices.push(indices.length + 1); // + 2
				indices.push(indices.length - 1); // + 2
				indices.push(indices.length - 1); // + 3
				if (j % 3 == 2)
				{
					lastX = 0;
					lastY += frame.frame.height;
				}
				else
				{
					lastX += frame.frame.width;
				}
			}
			point.put();
		}
	}

	public override function destroy(){
		topleft = null;
		top = null;
		topright = null;
		middleleft = null;
		middle = null;
		middleright = null;
		bottomleft = null;
		bottom = null;
		bottomright = null;
		super.destroy();
	}


	public override function draw() @:privateAccess {
		super.draw();
		/*
		if (alpha == 0 || graphic == null || vertices == null)
			return;

		for (camera in cameras)
		{
			if (!camera.visible || !camera.exists)
				continue;

			getScreenPosition(_point, camera).subtractPoint(offset);
			camera.drawTriangles(graphic, vertices, indices, uvtData, colors, _point, blend, repeat, antialiasing#if !flash , colorTransform, shader #end);
		}
		*/
		/*
		final x:Float = this.x;
		final y:Float = this.y;

		if (visible && !(bWidth == 0 || bHeight == 0)) {

			// TOP
			if (drawTop) {
				// TOP LEFT
				frame = topleft;
				setPosition(x, y);
				__setSize(
					topleft.frame.width * Math.min(bWidth/(topleft.frame.width*2), 1),
					topleft.frame.height * Math.min(bHeight/(topleft.frame.height*2), 1)
				);
				super.draw();

				// TOP
				if (bWidth > topleft.frame.width + topright.frame.width) {
					frame = top;
					setPosition(x + topleft.frame.width, y);
					__setSize(bWidth - topleft.frame.width - topright.frame.width, top.frame.height * Math.min(bHeight/(top.frame.height*2), 1));
					super.draw();
				}

				// TOP RIGHT
				setPosition(x + bWidth - (topright.frame.width * Math.min(bWidth/(topright.frame.width*2), 1)), y);
				frame = topright;
				__setSize(
					topright.frame.width * Math.min(bWidth/(topright.frame.width*2), 1),
					topright.frame.height * Math.min(bHeight/(topright.frame.height*2), 1)
				);
				super.draw();
			}

			// MIDDLE
			if (drawMiddle && bHeight > top.frame.height + bottom.frame.height) {
				var middleHeight:Float = bHeight - (topleft.frame.height * Math.min(bHeight/(topleft.frame.height*2), 1)) -
				bottomleft.frame.height * Math.min(bHeight/(bottomleft.frame.height*2), 1);

				// MIDDLE LEFT
				frame = middleleft;
				setPosition(x, y + top.frame.height);
				__setSize(middleleft.frame.width * Math.min(bWidth/(middleleft.frame.width*2), 1), middleHeight);
				super.draw();

				if (bWidth > (middleleft.frame.width * Math.min(bWidth/(middleleft.frame.width*2), 1)) + middleright.frame.width) {
					// MIDDLE
					frame = middle;
					setPosition(x + topleft.frame.width, y + top.frame.height);
					__setSize(bWidth - middleleft.frame.width - middleright.frame.width, middleHeight);
					super.draw();
				}

				// MIDDLE RIGHT
				frame = middleright;
				setPosition(x + bWidth - (topright.frame.width * Math.min(bWidth/(topright.frame.width*2), 1)), y + top.frame.height);
				__setSize(middleright.frame.width * Math.min(bWidth/(middleright.frame.width*2), 1), middleHeight);
				super.draw();
			}

			// BOTTOM
			if (drawBottom) {
				// BOTTOM LEFT
				frame = bottomleft;
				setPosition(x, y + bHeight - (bottomleft.frame.height * Math.min(bHeight/(bottomleft.frame.height*2), 1)));
				__setSize(
					bottomleft.frame.width * Math.min(bWidth/(bottomleft.frame.width*2), 1),
					bottomleft.frame.height * Math.min(bHeight/(bottomleft.frame.height*2), 1)
				);
				super.draw();

				if (bWidth > bottomleft.frame.width + bottomright.frame.width) {
					// BOTTOM
					frame = bottom;
					setPosition(x + bottomleft.frame.width, y + bHeight - (bottom.frame.height * Math.min(bHeight/(bottom.frame.height*2), 1)));
					__setSize(bWidth - bottomleft.frame.width - bottomright.frame.width, bottom.frame.height * Math.min(bHeight/(bottom.frame.height*2), 1));
					super.draw();
				}

				// BOTTOM RIGHT
				frame = bottomright;
				setPosition(
					x + bWidth - (bottomright.frame.width * Math.min(bWidth/(bottomright.frame.width*2), 1)),
					y + bHeight - (bottomright.frame.height * Math.min(bHeight/(bottomright.frame.height*2), 1))
				);
				__setSize(
					bottomright.frame.width * Math.min(bWidth/(bottomright.frame.width*2), 1),
					bottomright.frame.height * Math.min(bHeight/(bottomright.frame.height*2), 1)
				);
				super.draw();
			}
		}

		setPosition(x, y);
	}

	private function __setSize(Width:Float, Height:Float) {
		var newScaleX:Float = Width / frameWidth;
		var newScaleY:Float = Height / frameHeight;
		scale.set(newScaleX, newScaleY);

		if (Width <= 0)
			scale.x = newScaleY;
		else if (Height <= 0)
			scale.y = newScaleX;

		updateHitbox();
	}
}
*/