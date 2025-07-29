package game.objects;

class AttachedSprite extends FlxSprite{
	public var sprTracker:FlxSprite;
	public var xAdd:Float = 0;
	public var yAdd:Float = 0;
	public var angleAdd:Float = 0;
	public var alphaMult:Float = 1;

	public var copyAngle:Bool = true;
	public var copyAlpha:Bool = true;
	public var copyVisible:Bool = false;

	public var image(default, set):String = null;
	inline function set_image(newImage:String):String{
		if (newImage != image) loadGraphic(Paths.image(newImage));
		return image = newImage;
	}

	public function new(?file:String = null, ?anim:String = null, ?library:String = null, ?loop:Bool = false){
		super();
		if(anim != null) {
			frames = Paths.getSparrowAtlas(file, library);
			animation.addByPrefix('idle', anim, 24, loop);
			animation.play('idle');
		} else if(file != null) {
			image = file;
		}
		scrollFactor.set();
	}

	override function update(elapsed:Float){
		if (sprTracker != null) {
			setPosition(sprTracker.x + xAdd, sprTracker.y + yAdd);
			scrollFactor.copyFrom(sprTracker.scrollFactor);

			if(copyAngle)
				angle = sprTracker.angle + angleAdd;

			if(copyAlpha)
				alpha = sprTracker.alpha * alphaMult;

			if(copyVisible)
				visible = sprTracker.visible;
		}
		super.update(elapsed);
	}
}
