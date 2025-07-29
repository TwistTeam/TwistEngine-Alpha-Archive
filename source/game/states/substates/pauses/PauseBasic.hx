package game.states.substates.pauses;

import game.backend.system.song.Conductor.mainInstance as Conductor;
import game.backend.utils.Difficulty;
import game.objects.Alphabet;
import game.objects.improvedFlixel.FlxFixedText;
import game.states.playstate.PlayState;
import game.states.substates.PauseSubState;
import game.mobile.utils.SwipeUtil;
import game.mobile.utils.TouchUtil;

import flixel.addons.transition.FlxTransitionableState;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxStringUtil;
import openfl.system.System;

class PauseBasic extends PauseSubState
{
	var skipTimeText:FlxFixedText;
	var skipTimeTracker:Alphabet;
	var practiceText:FlxFixedText;
	var bgTween:FlxTween;
	var metadata:FlxTypedGroup<FlxFixedText>;
	var menuItemsOG:Array<String> = null;
	var selectDifficulty:Bool = false;
	var difficultyChoices = new Array<String>();

	override function createUI():Void
	{
		metadata = new FlxTypedGroup<FlxFixedText>();
		add(metadata);
		super.createUI();

		inline function setupFormat(txt:FlxText)
		{
			txt.setFormat(Paths.font('defaultPsych/vcr.ttf'), 32);
		}
		function addText(txt:String, size:Int = 32)
		{
			if (txt == null || txt.length == 0)
				return;
			var textField:FlxFixedText = new FlxFixedText(20, 0, 0, txt);
			setupFormat(textField);
			metadata.add(textField);
		}

		addText(PlayState.SONG.display);

		if (Difficulty.list != null && Difficulty.list.length > 1)
			addText(Difficulty.getString().toUpperCase());

		function addByLinesText(txt:String)
		{
			for (i in txt.split("\r").join("\n").split("\n"))
			{
				addText(i.ltrim());
			}
		}
		if (PlayState.SONG.artist != null && PlayState.SONG.artist == PlayState.SONG.charter)
		{
			addByLinesText("Composed and charted by " + PlayState.SONG.artist);
		}
		else
		{
			if (PlayState.SONG.artist != null)
			{
				addByLinesText("By " + PlayState.SONG.artist);
			}
			if (PlayState.SONG.charter != null)
			{
				addByLinesText("Charter: " + PlayState.SONG.charter);
			}
		}

		addText("Blueballed: " + PlayState.deathCounter);

		if (PlayState.chartingMode)
		{
			addText("CHARTING MODE");
		}

		practiceText = new FlxFixedText(20, 0, 0, 'PRACTICE MODE');
		setupFormat(practiceText);
		practiceText.visible = PlayState.instance.practiceMode;
		metadata.add(practiceText);

		// if (bgTween != null && bgTween.active)
		// 	bgTween.cancel();
		var func = FlxColor.interpolate.bind(bgColor, FlxColor.BLACK, _);
		bgTween = FlxTween.num(0.0, 0.6, 0.4, {ease: FlxEase.quartInOut}, i -> bgColor = func(i));

		var lastY:Float = 15;
		var delay:Float = 0.1;
		metadata.forEach(spr -> {
			spr.alignment = RIGHT;
			spr.x = FlxG.width - 20.0 - spr.width;
			spr.y = lastY;
			spr.alpha = 0.0;
			// NOTE: numLines can't be less than 1
			lastY += 32.0 * spr.textField.numLines;
			FlxTween.tween(spr, {alpha: 1.0, y: spr.y + 5.0}, 0.4, {ease: FlxEase.quartOut, startDelay: delay});
			delay += 0.1;
		});

		// if (FlxG.random.bool()) startArtistTimer(); else  startCharterTimer();;


		add(grpMenuShit = new FlxTypedGroup<FlxSprite>());
		menuItems.insert(2, "Options");
		if (PlayState.chartingMode)
		{
			menuItems.insert(3, "Leave Charting Mode");
			menuItems.insert(4, "End Song");
			menuItems.insert(5, "Toggle Practice Mode");
			menuItems.insert(6, "Toggle Botplay");
		}

		if (Difficulty.list != null && Difficulty.list.length > 1)
		{
			for (i in Difficulty.list)
				difficultyChoices.push(i);

			difficultyChoices.push("BACK");

			menuItems.insert(2, "Change Difficulty");
		}
		menuItemsOG = menuItems;
		regenMenu();
		changeSelection();
	}

	/*
	static final CHARTER_FADE_DELAY:Float = 15.0;

	static final CHARTER_FADE_DURATION:Float = 0.75;

	var charterFadeTween:Null<FlxTween> = null;

	function startCharterTimer():Void
	{
		metadataArtist.text = 'Charter: ${PlayState.SONG.charter ?? 'Unknown'}';
		metadataArtist.x = FlxG.width - 20 - metadataArtist.width;
		charterFadeTween = FlxTween.tween(metadataArtist, {alpha: 1.0}, CHARTER_FADE_DURATION, {
			ease: FlxEase.quartOut,
			onComplete: _ ->
				charterFadeTween = FlxTween.tween(metadataArtist, {alpha: 0.0}, CHARTER_FADE_DURATION, {
					startDelay: CHARTER_FADE_DELAY,
					ease: FlxEase.quartOut,
					onComplete: _ -> startArtistTimer()
				})
		});
	}

	function startArtistTimer():Void
	{
		metadataArtist.text = 'Artist: ${PlayState.SONG.artist}';
		metadataArtist.x = FlxG.width - 20 - metadataArtist.width;
		charterFadeTween = FlxTween.tween(metadataArtist, {alpha: 1.0}, CHARTER_FADE_DURATION, {
			ease: FlxEase.quartOut,
			onComplete: _ ->
				charterFadeTween = FlxTween.tween(metadataArtist, {alpha: 0.0}, CHARTER_FADE_DURATION, {
					startDelay: CHARTER_FADE_DELAY,
					ease: FlxEase.quartOut,
					onComplete: _ -> startCharterTimer()
				})
		});
	}
	*/

	override function destroy()
	{
		// if (charterFadeTween != null && charterFadeTween.active)
		// 	charterFadeTween.cancel();
		// charterFadeTween = null;
		if (bgTween != null && bgTween.active)
			bgTween.cancel();
		bgTween = null;
		// var func = FlxColor.interpolate.bind(bgColor, FlxColor.TRANSPARENT, _);
		// bgTween = FlxTween.num(0.0, 1.0, 0.15, {ease: FlxEase.quartInOut}, i -> bgColor = func(i));
		super.destroy();
	}

	override function update(elapsed:Float)
	{
		if (cantUnpause > 0)
			cantUnpause -= elapsed;
		if (subState == null && !itIsAccepted)
		{
			if (menuItems[curSelected] == 'Skip Time')
			{
				if (controls.UI_LEFT || controls.UI_RIGHT)
				{
					if (controls.UI_LEFT_P)
					{
						FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
						curTime -= 1000;
						holdTime = 0;
					}
					if (controls.UI_RIGHT_P)
					{
						FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
						curTime += 1000;
						holdTime = 0;
					}
					holdTime += elapsed;
					if (holdTime > 0.5)
						curTime += 45000 * elapsed * (controls.UI_LEFT ? -1 : 1);

					if (FlxG.sound.music != null)
						if (curTime >= FlxG.sound.music.length)
							curTime -= FlxG.sound.music.length;
						else if (curTime < 0)
							curTime += FlxG.sound.music.length;
					updateSkipTimeText();
				}
			}
			updateSkipTextStuff();
			if (controls.UI_UP_P || SwipeUtil.swipeUp) changeSelection(-1);

			if (controls.UI_DOWN_P || SwipeUtil.swipeDown) changeSelection(1);

			if ((controls.ACCEPT || (TouchUtil.justPressed && TouchUtil.touch.x < FlxG.width * 0.5)) && cantUnpause <= 0) onAccept(menuItems[curSelected]);
		}
		super.update(elapsed);
	}

	function onAccept(text:String)
	{
		if (selectDifficulty)
		{
			switch text
			{
				case "BACK":
					menuItems = menuItemsOG;
					selectDifficulty = false;
					regenMenu();
				case text:
					if (Difficulty.list.contains(text))
					{
						try
						{
							PlayState.loadSong(PlayState.SONG.song, Difficulty.getString(curSelected), Difficulty.list, false);
							FlxG.resetState();
							FlxG.sound.music.volume = 0;
							// PlayState.changedDifficulty = true;
							PlayState.chartingMode = false;
						}
						catch(e)
						{
							Log(e, RED);
						}
					}
			}
			return;
		}

		switch text
		{
			case "Resume":
				close();
				itIsAccepted = true;
			case "Change Difficulty":
				menuItems = difficultyChoices;
				selectDifficulty = true;
				regenMenu();

			case "Options":
				openOptions();
			case 'Toggle Practice Mode':
				PlayState.instance.practiceMode = !PlayState.instance.practiceMode;
				// PlayState.changedDifficulty = true;
				practiceText.visible = PlayState.instance.practiceMode;

			case "Restart":
				PauseSubState.restartSong();
				itIsAccepted = true;

			case "Leave Charting Mode":
				PauseSubState.restartSong();
				PlayState.chartingMode = false;
				itIsAccepted = true;

			case 'Skip Time':
				if (curTime < Conductor.songPosition)
				{
					PlayState.instance.startOnTime = curTime;
					PauseSubState.restartSong(true);
				}
				else
				{
					if (curTime != Conductor.songPosition)
					{
						PlayState.instance.clearNotesBefore(curTime);
						PlayState.instance.setSongTime(curTime);
					}
					close();
				}

			case "End Song":
				endSong();
				itIsAccepted = true;

			case 'Toggle Botplay':
				PlayState.instance.cpuControlled = !PlayState.instance.cpuControlled;
				// PlayState.instance.botplaySine = 0;

			case "Exit":
				exit();
				itIsAccepted = true;
		}
	}

	function deleteSkipTimeText()
	{
		if (skipTimeText != null)
		{
			remove(skipTimeText, true);
			skipTimeText.destroy();
		}
		skipTimeText = null;
		skipTimeTracker = null;
	}

	function changeSelection(change:Int = 0):Void
	{
		curSelected = FlxMath.wrap(curSelected + change, 0, grpMenuShit.length - 1);

		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);

		var alph:Alphabet;
		for (i => item in grpMenuShit.members)
		{
			alph = cast item;
			if (alph == null) continue;
			alph.targetY = i - curSelected;

			// item.setGraphicSize(Std.int(alph.width * 0.8));

			if (alph.targetY == 0)
			{
				alph.alpha = 1;
				// alph.setGraphicSize(Std.int(alph.width));

				if(alph == skipTimeTracker)
				{
					curTime = Math.max(0, Conductor.songPosition);
					updateSkipTimeText();
				}
			}
			else
			{
				alph.alpha = 0.6;
			}
		}
	}

	function regenMenu():Void
	{
		while (grpMenuShit.members.length > 0)
		{
			grpMenuShit.members.shift()?.destroy();
		}
		grpMenuShit.clear();

		deleteSkipTimeText();
		var item:Alphabet;
		for (i in 0...menuItems.length)
		{
			item = new Alphabet(90, 320, menuItems[i], true);
			item.isMenuItem = true;
			item.targetY = i;
			grpMenuShit.add(item);

			if(menuItems[i] == 'Skip Time')
			{
				deleteSkipTimeText();
				skipTimeText?.destroy();
				skipTimeText = new FlxFixedText(0, 0, 0, '', 64);
				skipTimeText.setFormat(Paths.font("defaultPsych/vcr.ttf"), 64, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
				skipTimeText.scrollFactor.set();
				skipTimeText.borderSize = 2;
				skipTimeTracker = cast item;
				add(skipTimeText);

				updateSkipTextStuff();
				updateSkipTimeText();
			}
		}
		curSelected = 0;
		changeSelection();
	}

	function updateSkipTextStuff()
	{
		if (skipTimeText == null || skipTimeTracker == null)
			return;

		skipTimeText.x = skipTimeTracker.x + skipTimeTracker.width + 60;
		skipTimeText.y = skipTimeTracker.y;
		skipTimeText.alpha = skipTimeTracker.alpha;
		// skipTimeText.visible = (skipTimeTracker.alpha >= 0.9);
	}

	function updateSkipTimeText()
	{
		if (skipTimeText == null) return;
		skipTimeText.text = FlxStringUtil.formatTime(Math.max(0, Math.floor(curTime / 1000)), false)
			+ ' / '
			+ FlxStringUtil.formatTime(Math.max(0, Math.floor(FlxG.sound.music.length / 1000)), false);
	}

}