package game.objects;

import openfl.Lib;
import openfl.display.Bitmap;

@:access(openfl.display.BitmapData)
class SaveIcon extends Bitmap
{
	public var baseSize:UInt = 75;
	public var idleTime:UInt = 3;
	public var speedAnim:Single = 1.1;

	public var time:Float = 0.0;

	public var baseX:Float = 0.0;
	public var baseY:Float = 0.0;

	public var imagePath:String;

	public function new(imagePath:String = 'dog') // dog
	{
		this.imagePath = imagePath;
		super(null);
		width = baseSize;
		height = baseSize;

		FlxG.signals.gameResized.add((w, h) -> updatePos());

		updatePos();
		visible = false;
	}

	public function show()
	{
		bitmapData = Assets.getBitmapData(AssetsPaths.image(imagePath));
		width = baseSize;
		height = baseSize;
		updatePos();
		time = 0.0;
		visible = true;
	}

	// Event Handlers
	@:noCompletion
	override function __enterFrame(deltaTime:Float):Void
	{
		if (!visible)
			return;

		time += deltaTime / 1000.0 * speedAnim;
		final factor = Math.sin(time * Math.PI);
		this.scaleX = (factor > 0 ? 1 - Math.pow(1.0 - factor, 1.5) : -(1.0 - Math.pow(1.0 + factor, 1.5))) / 2.0;
		x = baseX - width / (factor < 0 ? -2.0 : 2.0);
		alpha = CoolUtil.smoothStep(0, 0.15, time) * CoolUtil.smoothStep(idleTime, idleTime - 0.25, time);
		if (time > idleTime) visible = false;
		//rotation = time;
	}

	@:noCompletion
	function updatePos()
	{
		if (stage == null)
			return;
		x = baseX = stage.stageWidth - baseSize / 1.1;
		y = baseY = stage.stageHeight - baseSize * 1.1;
	}
}