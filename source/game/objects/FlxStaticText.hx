package game.objects;

class FlxStaticText extends game.objects.improvedFlixel.FlxFixedText{
	public function new(X:Float = 0, Y:Float = 0, FieldWidth:Float = 0, ?Text:String, Size:Int = 8, EmbeddedFont:Bool = true)
	{
		super(X, Y, FieldWidth, Text, Size, EmbeddedFont);
		active = false;
	}
	override function regenGraphic()
	{
		super.regenGraphic();
		graphic.persist = false;
	}
}