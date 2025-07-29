package game.backend.data.jsons;

import haxe.Json;

import game.backend.system.song.Song;
import game.objects.game.notes.Note.TypeNote;
import game.objects.game.Character.AnimArray;
import game.backend.system.scripts.FunkinLua.ModchartSprite;

typedef StageFile = {
	var directory:String;
	var defaultZoom:Float;
	var isPixelStage:Bool;
	var typeNotes:String;

	var boyfriend:Array<Float>;
	var girlfriend:Array<Float>;
	var opponent:Array<Float>;
	@:optional var player_3:Array<Float>;
	var hide_girlfriend:Bool;

	var camera_boyfriend:Array<Float>;
	var camera_opponent:Array<Float>;
	var camera_girlfriend:Array<Float>;
	@:optional var camera_player_3:Array<Float>;
	@:optional var camera_speed:Float;

	@:optional var preloadList:Array<String>;

	@:optional var typeNotesAbstract:Null<TypeNote>; // IGNORE

	// from psych RELEASE
	@:optional var stageUI:String;
	@:optional var preload:Dynamic;
	@:optional var objects:Array<Dynamic>;
	@:optional var _editorMeta:Dynamic;
}

enum abstract LoadFilters(Int) from Int from UInt to Int to UInt
{
	var LOW_QUALITY:Int = (1 << 0);
	var HIGH_QUALITY:Int = (1 << 1);

	var STORY_MODE:Int = (1 << 2);
	var FREEPLAY:Int = (1 << 3);
}

class StageData{
	public static function dummy():StageFile{
		return {
			directory: "",
			defaultZoom: 0.9,
			isPixelStage: false,
			typeNotes: 'fnf',

			boyfriend: [770, 100],
			girlfriend: [400, 130],
			opponent: [100, 100],
			hide_girlfriend: false,

			camera_boyfriend: [0, 0],
			camera_opponent: [0, 0],
			camera_girlfriend: [0, 0],
			camera_speed: 1
		};
	}

	public static var forceNextDirectory:String = null;
	public static function loadDirectory(SONG:game.backend.system.song.Song){
		var stage:String = '';
		if (SONG.stage != null)
			stage = SONG.stage;
		/*else	if(SONG.song != null) {
			switch (SONG.song.toLowerCase().replace(' ', '-'))
			{
				case 'milf':
					stage = 'limo';
				default:
					stage = 'stage';
			}
		}*/
		else if(SONG.song != null)
			stage = 'stage';

		final stageFile:StageFile = getStageFile(stage);
		forceNextDirectory = stageFile?.directory ?? "";
	}

	public static function getStageFile(stage:String):StageFile{
		var rawJson:String = null;
		final path:String = AssetsPaths.getPath('stages/' + stage + '.json');

		if (Assets.exists(path))
			rawJson = Assets.getText(path);

		try{
			return rawJson == null ? null : cast Json.parse(rawJson);
		}catch(e){
			Log('Err on load $stage (${e.message})', RED);
			return null;
		}
	}
	public static var reservedNames:Array<String> = [
		'gf', 'gfGroup',
		'dad', 'dadGroup',
		'boyfriend', 'boyfriendGroup'
	]; //blocks these names from being used on stage editor's name input text
	public static function addObjectsToState(objectList:Array<Dynamic>, gf:FlxSprite, dad:FlxSprite, boyfriend:FlxSprite, ?group:Dynamic, ?ignoreFilters:Bool)
	{
		var addedObjects:Map<String, FlxSprite> = new Map<String, FlxSprite>();
		for (num => data in objectList)
		{
			if (addedObjects.exists(data)) continue;

			switch(data.type)
			{
				case 'gf', 'gfGroup':
					if(gf != null)
					{
						gf.ID = num;
						if (group != null) group.add(gf);
						addedObjects.set('gf', gf);
					}
				case 'dad', 'dadGroup':
					if(dad != null)
					{
						dad.ID = num;
						if (group != null) group.add(dad);
						addedObjects.set('dad', dad);
					}
				case 'boyfriend', 'boyfriendGroup':
					if(boyfriend != null)
					{
						boyfriend.ID = num;
						if (group != null) group.add(boyfriend);
						addedObjects.set('boyfriend', boyfriend);
					}

				case 'square', 'sprite', 'animatedSprite':
					if(!ignoreFilters && !validateVisibility(data.filters)) continue;

					var spr:ModchartSprite = new ModchartSprite(data.x, data.y);
					spr.ID = num;
					if(data.type != 'square')
					{
						if(data.type == 'sprite')
							spr.loadGraphic(Paths.image(data.image));
						else
							spr.frames = Paths.getAtlas(data.image);

						if(data.type == 'animatedSprite' && data.animations != null)
						{
							var anims:Array<AnimArray> = cast data.animations;
							for (key => anim in anims)
							{
								if(anim.indices == null || anim.indices.length < 1)
									spr.animation.addByPrefix(anim.anim, anim.name, anim.fps, anim.loop);
								else
									spr.animation.addByIndices(anim.anim, anim.name, anim.indices, '', anim.fps, anim.loop);

								if(anim.offsets != null)
									spr.addOffset(anim.anim, anim.offsets[0], anim.offsets[1]);

								if(spr.animation.curAnim == null || data.firstAnimation == anim.anim)
									spr.playAnim(anim.anim, true);
							}
						}
						for (varName in ['antialiasing', 'flipX', 'flipY'])
						{
							var dat:Dynamic = Reflect.getProperty(data, varName);
							if(dat != null) Reflect.setProperty(spr, varName, dat);
						}
					}
					else
					{
						spr.makeGraphic(1, 1, FlxColor.WHITE);
						spr.antialiasing = false;
					}

					if(data.scale != null && (data.scale[0] != 1.0 || data.scale[1] != 1.0))
					{
						spr.scale.set(data.scale[0], data.scale[1]);
						spr.updateHitbox();
					}
					spr.scrollFactor.set(data.scroll[0], data.scroll[1]);
					spr.color = CoolUtil.colorFromString(data.color);

					for (varName in ['alpha', 'angle'])
					{
						var dat:Dynamic = Reflect.getProperty(data, varName);
						if(dat != null) Reflect.setProperty(spr, varName, dat);
					}

					if (group != null) group.add(spr);
					addedObjects.set(data.name, spr);

				default:
					var err = '[Stage .JSON file] Unknown sprite type detected: ${data.type}';
					Log(err, RED);
					FlxG.log.error(err);
			}
		}
		return addedObjects;
	}

	public static function validateVisibility(filters:LoadFilters)
	{
		// if((filters & STORY_MODE) == STORY_MODE)
		// 	if(!PlayState.isStoryMode) return false;
		// else if((filters & FREEPLAY) == FREEPLAY)
		// 	if(PlayState.isStoryMode) return false;

		return ((ClientPrefs.lowQuality && (filters & LOW_QUALITY) == LOW_QUALITY) ||
			(!ClientPrefs.lowQuality && (filters & HIGH_QUALITY) == HIGH_QUALITY));
	}
}
