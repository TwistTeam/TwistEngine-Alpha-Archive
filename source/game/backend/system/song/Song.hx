package game.backend.system.song;

import game.backend.system.song.Section;
import game.backend.data.jsons.StageData;
import game.backend.utils.Difficulty;
import game.backend.utils.Highscore;

import haxe.extern.EitherType;
import haxe.Json;
/*
@:forward
abstract EventData(Array<String>) from Array<String> to Array<String> {
	public var name(get, set):String;
	inline function get_name()			return this[0];
	inline function set_name(i)			return this[0] = i;
	public var value1(get, set):String;
	inline function get_value1()		return this[1];
	inline function set_value1(i)		return this[1] = i;
	public var value2(get, set):String;
	inline function get_value2()		return this[2];
	inline function set_value2(i)		return this[2] = i;
	public var value3(get, set):String;
	inline function get_value3()		return this[3];
	inline function set_value3(i)		return this[3] = i;
	public inline function new(name:String, ?value1:String, ?value2:String, ?value3:String)
	{
		this = [name, value1, value2, value3];
	}
}

@:forward
abstract EventSection(Array<Dynamic>) from Array<Dynamic> to Array<Dynamic> // preventing random bullshit /*EitherType<Float, Array<EventData>>
{
	public var strumTime(get, set):Float;
	inline function get_strumTime()		return this[0];
	inline function set_strumTime(i)	return this[0] = i;
	public var events(get, set):Array<EventData>;
	inline function get_events()		return this[1];
	inline function set_events(i)		return this[1] = i;
	public inline function new(strumTime:Float, events:Array<EventData>)
	{
		this = [strumTime, events];
	}
}
*/
typedef SwagSong = {
	var song:String;
	var notes:Array<SwagSection>;
	var events:Array<Dynamic>;
	var bpm:Float;
	var needsVoices:Bool;
	var speed:Float;

	var player1:String;
	var player2:String;
	@:optional var gfVersion:String;
	var stage:String;

	var artist:String;
	var charter:String;

	var arrowSkin:String;
	var splashSkin:String;
	@:optional var holdCoverSkin:String;

	// var instFile:String;
	// var voicesFile:String;

	@:optional var postfix:String;
	@:optional var format:String;
}
class Song
{
	// IDFK WHAT THESE ARE BUT APARENTLY THEY WERE IN VS FORDICK'S CHARTS LMAO
	//public static final invalidFields:Array<String> = ['player3', 'validScore', 'isHey', 'cutsceneType', 'isSpooky', 'isMoody', 'uiType', 'sectionLengths'];
	public static final validFields:Array<String> = Type.getInstanceFields(Song);

	public var song:String = '';
	public var display:String;
	public var notes:Array<SwagSection> = [];
	public var events:Array<Dynamic> = [];
	public var bpm:Float = 160;
	public var needsVoices:Bool = true;
	public var speed:Float = 2;

	public var artist:String = Constants.DEFAULT_ARTIST;
	public var charter:String = Constants.DEFAULT_CHARTER;

	public var player1:String = 'bf';
	public var player2:String = 'dad';
	public var gfVersion:String = 'gf';
	public var stage:String = 'stage';

	public var difficulty:String = Difficulty.defaultDifficulty;
	public var postfix:String = '';
	public var arrowSkin:String = null;
	public var splashSkin:String = null;
	public var holdCoverSkin:String = null;
	public var isReleasePsych(get, never):Bool;
	inline function get_isReleasePsych() return format != null;
	public var format:String = null;

	public static function filterJsonSong(songJson:Dynamic):SwagSong // Convert old charts to newest format
	{
		songJson.gfVersion ??= songJson.player3;

		songJson.events ??= [];
		// parse old psych events
		var notes:Array<SwagSection> = cast Reflect.field(songJson, 'notes');
		if (notes != null)
		{
			var i:Int = 0;
			var notesInSection:Array<Dynamic>;
			var isReleasePsych = Reflect.field(songJson, 'format') != null;
			trace(isReleasePsych);
			while(i < notes.length)
			{
				notesInSection = notes[i++].sectionNotes;
				if (notesInSection == null || notesInSection.length == 0)
				{
					// notes.splice(--i, 1);
					continue;
				}
				var j:Int = 0;
				var note:Array<Dynamic>;
				while(j < notesInSection.length)
				{
					note = notesInSection[j];
					if(note[1] < 0)
					{
						songJson.events.push([note[0], [[for(j in 2...note.length) note[j]]]]);
						notesInSection.splice(j, 1);
						// notesInSection.remove(note);
					}
					else
					{
						if (isReleasePsych && !notes[i - 1].mustHitSection)
						{
							if (note[1] < 4)
								note[1] += 4;
							else
								note[1] -= 4;
						}
						j++;
					}
				}
			}
		}
		// yeet the garbage!!
		for (field in Reflect.fields(songJson))
		{
			if (!validFields.contains(field))
			{
				Log('WARNING!! This chart have invalid field "$field"', DARKRED);
				Reflect.deleteField(songJson, field);
			}
		}
		return songJson;
	}

	public function new(SONG:SwagSong)
	{
		if (SONG == null) return;

		SONG = filterJsonSong(SONG);
		for (field in Reflect.fields(SONG))
		{
			if (validFields.contains(field))
			{
				Reflect.setField(this, field, Reflect.field(SONG, field));
			}
			else
			{
				// if (field == 'player3' && ['gf', null].contains(Reflect.field(SONG, 'gfVersion')) && Reflect.field(SONG, 'player3') != null)
				// 	Reflect.setField(this, 'gfVersion', Reflect.field(SONG, 'player3'));
				Log('WARNING!! This chart have invalid field "$field"', DARKRED);
			}
		}
		display = display.getDefault(song);
		postfix = postfix.getDefault('');
	}

	public function dispose()
	{
		while (notes.length > 0) notes.pop().sectionNotes.clearArray();
		events.clearArray();
	}

	public static function loadFromJsonSimple(song:String, ?difficulty:String):Song
	{
		return loadFromJson(Highscore.formatSong(song, difficulty), song);
	}
	public static function loadFromJson(jsonFile:String, ?folder:String):Song
	{
		var rawJson:String = null;

		var dataPath:String = Paths.formatToSongPath(folder ?? jsonFile) + '/' + Paths.formatToSongPath(jsonFile);
		dataPath = AssetsPaths.getPath(Constants.SONG_CHART_FILES_FOLDER + '/$dataPath.json');
		if(Assets.exists(dataPath))
			rawJson = Assets.getText(dataPath).trim();

		if(rawJson == null) return null;
		final songJson:Song = new Song(parseJSONshit(rawJson));
		songJson.difficulty = Difficulty.getDifficultyFromFullPath(dataPath) ?? songJson.difficulty;
		if (jsonFile != 'events') StageData.loadDirectory(songJson);
		return songJson;
	}

	public static function parseJSONshit(rawJson:String):SwagSong
	{
		try
		{
			var data:Dynamic = Json.parse(rawJson);
			return cast (Reflect.field(data, "song") is String ? data : data.song);
		}
		catch(e)
		{
			e.getErrorInfo('Error on loading song: ');
			return getTemplateSong();
		}
	}
	public static function getTemplateSong():SwagSong
		return {
			song: 'Test',
			notes: [],
			events: [],
			bpm: 150.0,
			needsVoices: true,
			artist: Constants.DEFAULT_ARTIST,
			charter: Constants.DEFAULT_CHARTER,
			arrowSkin: Constants.DEFAULT_NOTE_SKIN,
			splashSkin: Constants.DEFAULT_NOTESPLASH_SKIN, // idk it would crash if i didn't
			player1: 'bf',
			player2: 'dad',
			gfVersion: 'gf',
			speed: 2,
			stage: 'stage'
		}
}
