package game.objects.ui;

/*
import flixel.util.FlxGradient;
import haxe.ds.Vector;
import game.backend.utils.FlxMultiKey;
import flixel.util.FlxColor;

typedef TaskbarOption = {
	label:String,
	?color:Array<FlxColor>,
	?keys:FlxMultiKey,
	?onPressed:TaskbarOption -> Void,
	?childs:Array<TaskbarOption>
}

class Taskbar extends FlxSprite {
	var option:TaskbarOption;
	var members:Vector<FlxSprite>;

	var selected:FlxSprite;

	public function updateStatus(){
		if (selected == null){

		}else{

		}
	}

	public function new(options:Array<TaskbarOption>, ?parent:Taskbar) {
		this.options = options;
		super(0, 0);
		scrollFactor.set(0, 0);

		var y:Int = 0;
		members = new Vector<FlxSprite>(options.length);
		for(i => o in options) {
			var b = new FlxSprite(0, y, FlxGradient.createGradientBitmapData(1, 5, color, 1, 90));
			y += b.height;
			members.set(i, b);
		}
	}

	public var anyMenuOpened:Bool = false;
	
	public function forEach(func:FlxSprite -> Void) {
		var i = members.length;
		while(i > 0){
			func(members[i]);
			i--;
		}
	}

	public override function update(elapsed:Float) {
		anyMenuOpened = false;
		var i = members.length;
		while(i > 0){
			if (members[i]) {
				anyMenuOpened = true;
				break;
			}
			i--;
		}
		super.update(elapsed);

		bWidth = FlxG.width;
	}
}
*/