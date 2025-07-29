package game.states.editors;

import game.objects.ui.*;

class TestState extends UIState {
	var _camTrans:FlxCamera;
	var box:Box;
	var window:Window;
	override function create(){
		FlxG.mouse.visible = true;
		bgColor = 0xff292929;
		add(new Slider(620, 10, 200, 50, 0, 1, 0.5, 2, VERTICAL));
		add(new Slider(620, 70, 200, 50, 0, 1, 0.5, 2, VERTICAL, true));
		add(new Slider(550, 10, 50, 200, 0, 1, 0.5, 2, HORIZONTAL));
		add(new Slider(840, 10, 50, 200, 0, 1, 0.5, 2, HORIZONTAL, true));
		add(window = new Window('WindowRealLol', 700, 250, 250, 360));
		for (i in 0...4*4*4){
			window.theme.add(new FlxSprite(FlxG.random.float(-50, 450), FlxG.random.float(-50, 750)));
		}
		final spr = new FlxSprite(Paths.image('ui/Helpy'));
		window.theme.add(spr);
		spr.y = window.theme.height - spr.height;
		window.onChangeHeight = (i) -> spr.y = i - spr.height;
		box = new Box(10, 10, 500, 500);
		add(box.addSelf());
		for (i in 0...4*4*4){
			box.add(new FlxSprite(FlxG.random.float(-100, 500), FlxG.random.float(-100, 500)));
		}
		super.create();
		_camTrans = new FlxCamera();
		_camTrans.bgColor.alphaFloat = 0;
		FlxG.cameras.add(_camTrans, false);
		add(new FlxInputText(10, 600, 300, 'Hello world', 14, 0xffffffff));
		var text = new FlxInputText(320, 600, 300, 'PASSWORD', 14, 0xffffffff);
		text.passwordMode = true;
		add(text);
	}
	public override function update(e){
		if (FlxG.keys.justPressed.ESCAPE){
			alive = false;
			MusicBeatState.switchState(new MasterEditorMenu());
			return;
		}
		super.update(e);
	}
}