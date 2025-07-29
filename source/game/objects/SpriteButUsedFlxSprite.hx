package game.objects;
/*
import openfl.events.Event;
import openfl.geom.Matrix;
import openfl.display.BitmapData;
import openfl.Lib;

class SpriteButUsedFlxSprite extends openfl.display.Sprite{
	var lastScale:Float = 1;
    function new(x, y, width, height) {
		FlxG.stage.addEventListener(Event.RESIZE, onResize);
		addEventListener(Event.ENTER_FRAME, update);

		FlxG.game.addChild(this); //Don't add it below mouse, or it will disappear once the game changes states

		lastScale = (FlxG.stage.stageHeight / FlxG.height);
		this.x = 20 * lastScale;
		this.y = -130 * lastScale;
		this.scaleX = lastScale;
		this.scaleY = lastScale;
    }

    @:noPrivateAccess static var eMatrix = new Matrix();
    function drawFlxSprite(spr, cloneBitmap:Bool = false, repeat:Bool = false) {
        final image = spr.graphic.bitmap;
        eMatrix.setTo(spr.width / image.width, 0, 0, spr.height / image.height, spr.x, spr.y);
		graphics.beginBitmapFill(image, eMatrix, repeat, spr.antialiasing);
		graphics.drawRect(spr.x, spr.y, spr.width + spr.x, spr.height + spr.y);
    }
    function endFill() {
		graphics.endFill();
    }
	private function onResize(e:Event){
		final mult = (FlxG.stage.stageHeight / FlxG.height);
		scaleX = mult;
		scaleY = mult;

		x = (mult / lastScale) * x;
		y = (mult / lastScale) * y;
		lastScale = mult;
	}

	function update(e:Event){
        if(timePassed < 0) {
            timePassed = Lib.getTimer();
            return;
        }

        final time = Lib.getTimer();
        final elapsed:Float = (time - timePassed) / 1000;
        timePassed = time;
        //trace('update called! $elapsed');

        // if(elapsed >= 0.5) return ; //most likely passed through a loading
        onUpdate(elapsed);
    }
    function onUpdate(e:Float) {}
	public function destroy(){
		if (FlxG.game.contains(this)) FlxG.game.removeChild(this);

		FlxG.stage.removeEventListener(Event.RESIZE, onResize);
		removeEventListener(Event.ENTER_FRAME, update);
		deleteClonedBitmaps();
	}

	var bitmaps:Array<BitmapData> = [];
	function deleteClonedBitmaps(){
		for (clonedBitmap in bitmaps){
			if(clonedBitmap != null){
				clonedBitmap.dispose();
				clonedBitmap.disposeImage();
			}
		}
		bitmaps = null;
	}
}
*/