package flixel.system.ui;

import flixel.FlxGame;

/**
 * The flixel sound tray, the little volume meter that pops down sometimes.
 * Accessed via `FlxG.game.soundTray` or `FlxG.sound.soundTray`.
 * @since 5.6.2-TWIST-PSYCH
 */
interface IFlxSoundTray {

	/**
	 * Because reading any data from DisplayObject is insanely expensive in hxcpp, keep track of whether we need to update it or not.
	 */
	public var active:Bool;
	private var _game:FlxGame;

	/**
	 * This function just updates the soundtray object.
	 */
	public function update(MS:Float):Void;

	/**
	 * Makes the little volume tray slide out.
	 *
	 * @param	up Whether the volume is increasing.
	 */
	public function show(up:Bool = false, ?forceSound:Bool = true):Void;

	public function screenCenter():Void;
	public function onAdded(game:FlxGame, ?oldSoundTray:IFlxSoundTray):Void;
	public function dispose():Void;

}