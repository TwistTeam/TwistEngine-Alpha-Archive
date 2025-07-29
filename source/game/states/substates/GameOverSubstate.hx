package game.states.substates;

import flixel.util.FlxDestroyUtil;
import game.backend.data.jsons.WeekData;
import game.backend.system.song.Conductor.mainInstance as Conductor;
import game.backend.utils.Highscore;
import game.objects.game.Character;
import game.states.editors.SongsState;
import game.states.playstate.PlayState;
import game.mobile.utils.TouchUtil;

import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.text.FlxText;
import flixel.system.FlxSound;

class GameOverSubstate extends MusicBeatSubstate
{
	public var boyfriend:Character;
	public var camFollow:FlxObject;
	var playingDeathSound:Bool = false;

	public static var loopSoundBPM:Float;

	public static var characterName(default, set):String;
	static function set_characterName(i) {
		if(PlayState.instance != null && !PlayState.instance.boyfriendMap.exists(i))
			PlayState.instance.addCharacterToList(i, 0);
		return characterName = i;
	}
	public static var deathSoundName(default, set):String;
	static function set_deathSoundName(i) {
		if (i != null) Paths.sound(i);
		return deathSoundName = i;
	}
	public static var loopSoundName(default, set):String;
	static function set_loopSoundName(i) {
		if (i != null) Paths.music(i);
		return loopSoundName = i;
	}
	public static var endSoundName(default, set):String;
	static function set_endSoundName(i) {
		if (i != null) Paths.music(i);
		return endSoundName = i;
	}

	public static var instance:GameOverSubstate;

	// public var defaultCamZoom:Float = 0.8;
	public var cameraSpeed:Float = 1;

	public static function resetVariables()
	{
		characterName = 'bf-dead';
		deathSoundName = 'fnf_loss_sfx';
		loopSoundName = 'gameOver';
		endSoundName = 'gameOverEnd';
		loopSoundBPM = 100;
	}

	public static function applyFromCharacter(char:Character, ?resetOnInvalid:Bool){
		var gopro = char.gameoverProperties;
		if (gopro != null)
		{
			characterName = gopro.char;
			deathSoundName = gopro.startSound;
			loopSoundName = gopro.music;
			endSoundName = gopro.confirmSound;
			loopSoundBPM = gopro.bpm;
		}
		else if (resetOnInvalid)
		{
			resetVariables();
		}
	}

	var startedDeath:Bool = false;

	override function create()
	{
		instance = this;
		PlayState.instance.callOnScripts('onGameOverStart');

		super.create();
	}

	override function destroy()
	{
		camFollowPos = FlxDestroyUtil.put(camFollowPos);
		instance = null;
		super.destroy();
		if (FlxG.sound.music != null) FlxG.sound.music.stop(); // fix gameover music after leaving?
	}
	var isEnding:Bool = false;

	var camFollowPos:FlxPoint;

	public function new()
	{
		PlayState.instance.callOnScripts('onCreateGameOver');
		super();

		cameraSpeed = PlayState.instance.cameraSpeed;
		PlayState.instance.setOnLuas('inGameOver', true);

		Conductor.songPosition = 0;

		var playStateBF = PlayState.instance.boyfriend;
		if (characterName == null)
		{
			boyfriend = playStateBF;
			boyfriend.alpha = 1;
		}
		else
		{
			if(PlayState.instance.boyfriendMap.exists(characterName))
			{
				boyfriend = PlayState.instance.boyfriendMap.get(characterName);
				boyfriend.alpha = 1;
			}
			else
			{
				boyfriend = new Character(playStateBF.x, playStateBF.y, characterName, true);
			}
		}
		boyfriend.alive = true;
		add(boyfriend);
		applyFromCharacter(boyfriend);

		if (deathSoundName != null && deathSoundName.trim() != '')
			FlxG.sound.play(Paths.sound(deathSoundName));
		Conductor.bpm = loopSoundBPM;

		boyfriend.holdTimer = boyfriend.heyTimer = 0;
		boyfriend.status = IDLE;
		boyfriend.playAnim('firstDeath', true);

		camFollowPos = boyfriend.getMidpoint(camFollowPos).subtractPoint(boyfriend.offset).subtract(100, 100).add(-boyfriend.cameraPos.x, boyfriend.cameraPos.y);
		camFollow = PlayState.instance.camFollowPos;
		// FlxG.camera.target = null;
		// FlxG.camera.focusOn(FlxPoint.weak(FlxG.camera.scroll.x + FlxG.camera.width / 2, FlxG.camera.scroll.y + FlxG.camera.height / 2));
		add(camFollow);
		// FlxG.camera.target = camFollow;
		// FlxG.camera.follow(camFollow, LOCKON, Math.POSITIVE_INFINITY);
		PlayState.instance.callOnScripts('onCreateGameOverPost');
	}

	public var allowSkip:Bool = true;
	public var moveCamera:Bool = false;

	override function update(elapsed:Float){
		PlayState.instance.callOnScripts('onUpdate', [elapsed]);

		if (!boyfriend.debugMode)
		{
			if (boyfriend.curAnimName == 'firstDeath')
			{
				if(!moveCamera && boyfriend.curFrame >= Math.min(boyfriend.curNumFrames - 1, 12))
					moveCamera = true;
				if (boyfriend.finishedAnim && !playingDeathSound){
					coolStartDeath();
				}
			}

			if (boyfriend.finishedAnim)
			{
				if (boyfriend.curAnimName.endsWith('miss'))
					boyfriend.playAnim('idle', true, false, 10);

				if (boyfriend.curAnimName == 'firstDeath' && boyfriend.finishedAnim && startedDeath)
					boyfriend.playAnim('deathLoop');
			}
		}
		if (FlxG.sound.music != null && FlxG.sound.music.playing)
			Conductor.songPosition = FlxG.sound.music.time;

		if (moveCamera)
		{
			/*if (!camGame.tweeningX)*/	camFollow.x = CoolUtil.fpsLerp(camFollow.x, camFollowPos.x, 0.03 * cameraSpeed);
			/*if (!camGame.tweeningY)*/	camFollow.y = CoolUtil.fpsLerp(camFollow.y, camFollowPos.y, 0.03 * cameraSpeed);
		}

		if (controls.ACCEPT || TouchUtil.justPressed) endBullshit();

		if (controls.BACK && !isEnding)
		{
			isEnding = true;
			if (FlxG.sound.music != null) FlxG.sound.music.stop();
			PlayState.deathCounter = 0;
			PlayState.seenCutscene = false;

			// WeekData.loadTheFirstEnabledMod();
			// if (PlayState.isStoryMode)
			// 	MusicBeatState.switchState(new StoryMenuState());
			// else
				MusicBeatState.switchState(#if EDITORS_ALLOWED SongsState.inDebugFreeplay ? new SongsState() : #end new FreeplayState());

			PlayState.instance.callOnScripts('onGameOverConfirm', [false]);
		}

		super.update(elapsed);
		PlayState.instance.callOnScripts('onUpdatePost', [elapsed]);
	}

	override function beatHit() {
		if (startedDeath && !isEnding){
			boyfriend.playAnim('deathDance');
		}
		super.beatHit();
	}
	function coolStartDeath(?volume:Float = 1):Void{
		startedDeath = true;
		if (loopSoundName != null && loopSoundName.trim() != '')
			FlxG.sound.playMusic(Paths.music(loopSoundName), volume);
	}

	function endBullshit():Void{
		if (!startedDeath && !allowSkip || isEnding) return;
		isEnding = true;
		boyfriend.playAnim('deathConfirm', true);
		if (FlxG.sound.music != null) FlxG.sound.music.stop();
		if (endSoundName != null && endSoundName.trim() != '')
			FlxG.sound.play(Paths.music(endSoundName));
		new FlxTimer().start(0.7, function(tmr:FlxTimer){
			FlxG.camera.fade(FlxColor.BLACK, 2, false, function(){
				MusicBeatState.resetState();
			});
		});
		PlayState.instance.callOnScripts('onGameOverConfirm', [true]);
	}
}
