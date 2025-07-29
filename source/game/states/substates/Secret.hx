package game.states.substates;

import flixel.util.FlxTimer;
import game.objects.improvedFlixel.FlxBGSprite;
import flixel.tweens.FlxTween;
import flixel.sound.FlxSound;

@:access(flixel.tweens.FlxTween)
class Secret extends FlxSubState
{
	var sound:FlxSound;
	var spr:FlxBGSprite;
	var tween:FlxTween;
	public function new(lie:Bool = true)
	{
		sound = FlxG.sound.load(Paths.sound("system/" + (lie ? "lie" : "truth")));
		spr = new FlxBGSprite();
		spr.loadGraphic(Paths.image("ui/" + (lie ? "lie.jpg" : "truth.jpg")));
		spr.alpha = 0;
		super();
		add(spr);
		camera = FlxG.cameras.list.getLast();
	}
	public override function create()
	{
		super.create();
		sound?.play();
		tween = FlxTween.tween(spr, {alpha: 1}, 1.35, {
			onComplete: _ -> {
				new FlxTimer().start(0.8, _ -> {
					tween = FlxTween.tween(spr, {alpha: 0}, 0.4, {
						onComplete: _ -> {
							close();
						}
					});
					tween.manager = null;
				});
			}
		});
		tween.manager = null;
	}
	public override function update(elapsed:Float)
	{
		if (tween.manager == null)
			tween.update(elapsed);
		super.update(elapsed);
	}
}
