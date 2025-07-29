package game.backend.data.jsons;

import flixel.util.FlxStringUtil;
import haxe.extern.EitherType;
import haxe.io.Path;
import game.states.playstate.PlayState;
import haxe.Json;

import game.backend.utils.PathUtil;

abstract WeekDataKey(Array<String>) from Array<String>
{
	public var file(get, never):String;

	@:noCompletion inline function get_file()
		return this[0];

	public var modPack(get, never):String;

	@:noCompletion inline function get_modPack()
		return this[1];

	public function new(file:String, ?modPack:String)
	{
		this = [file, modPack];
	}
}

class WeekData
{
	public static final weeksDatas = new Map<String, WeekData>();
	public static final weeksListOrder = new Array<WeekDataKey>();

	public var fileName:String;

	public var data:WeekStruct;

	public function new(data:WeekStruct, ?fileName:String)
	{
		this.data = data;

		if (fileName != null)
			this.fileName = fileName;
	}

	public static function getDefaultSongMetaData(?genId:Bool):SongMetaData
		return {}

	public static function defaultWeekStruct():WeekStruct
		return {
			songs: [getDefaultSongMetaData()],
			difficulties: [],
			isTwist: true,
			storyMenu: {
				title: "Title",
				description: "Description",
				character: ["bf-pixel", "gf", "bf"]
			}
		}

	public static function reloadWeeksFiles(?getFromAllLibs:Bool)
	{
		weeksDatas.clear();
		weeksListOrder.clearArray();
		final lastMod = ModsFolder.currentModFolderPath;
		var deJson:Dynamic = null;
		for (file in AssetsPaths.getFolderContent("weeks", true))
		{
			trace(file);
			if (PathUtil.extension(file) != 'json')
				continue;

			ModsFolder.switchMod("5rubles");
			if (weeksDatas.exists(file))
				continue;

			try
			{
				deJson = Json.parse(Assets.getText(file));
			}
			catch(e)
			{
				CoolUtil.alert(e.message, "Error to Parse json: " + file);
				deJson = null;
			}
			if (deJson == null)
				continue;

			weeksDatas.set(file, addWeek(deJson, file));
			weeksListOrder.push(new WeekDataKey(file, "5rubles"));
		}
		trace(weeksDatas);
		trace(weeksListOrder);
		ModsFolder.switchMod(lastMod);
	}
	public static function convertDifficulties(source:haxe.extern.EitherType<String, Array<String>>):Array<String>
	{
		if (source == null)
		{
			return null;
		}
		var diffs:Array<String> = (Std.isOfType(source, String) ? (source : String).split(",") : (source : Array<String>).copy());
		var i:Int = diffs.length - 1;
		var diff:String;
		while (i > 0)
		{
			diff = diffs[i];
			if(diff != null)
			{
				diff = diff.trim().toLowerCase();
				if(diff.length == 0)
				{
					diffs.remove(diffs[i]);
				}
				else
				{
					diffs[i] = diff;
				}
			}
			--i;
		}
		return diffs;
	}

	static function addWeek(data:Dynamic, ?fileName:String):WeekData
	{
		if (data == null)
			return null;
		if (Reflect.hasField(data, 'isTwist') && Reflect.field(data, 'isTwist') == true)
		{
			function convertToClass(dyn:Dynamic):SongMetaData
			{
				var song:SongMetaData = {};
				for (i in Reflect.fields(dyn))
					Reflect.setField(song, i, Reflect.field(dyn, i));
				return song;
			}
			var songsArray:Array<Dynamic> = cast data.songs;
			data.songs = songsArray == null ? [] : [for (i in songsArray) convertToClass(i)];
			data.difficulties = convertDifficulties(data.difficulties);
			return new WeekData(data, fileName);
		}
		else
		{ // is it poopy week data psych?
			final data:WeekFilePsych = cast data;
			return new WeekData({
				songs: [
					for (i in data.songs)
					{
						songName: i[0],
						healthIcon: i[1],
						freeplayColor: i[2],
						invisibleInFreeplay: data.hideFreeplay
					}
				],
				isTwist: false,
				difficulties: convertDifficulties(data.difficulties),
				hideInFreeplay: data.hideFreeplay,
				storyMenu: {
					title: data.storyName,
					character: data.weekCharacters,
					bg: data.weekBackground,
					weekBefore: data.weekBefore,
					hide: data.hideStoryMode,
					firstTimeBlocked: data.startUnlocked,
					hiddenUntilUnlocked: data.hiddenUntilUnlocked
				}
			}, fileName);
		}
	}
}

typedef StoryMenuData =
{
	> ExtraFields,
	title:String,
	?description:String,
	?textImg:String,
	character:Array<String>,
	?bg:String,
	?hide:Bool,
	?firstTimeBlocked:Bool,
	?hiddenUntilUnlocked:Bool,
	?weekBefore:String
}

typedef WeekStruct =
{
	> ExtraFields,
	songs:Array<SongMetaData>,
	?difficulties:Array<String>,
	?storyMenu:StoryMenuData,
	isTwist:Bool,
	?hideInFreeplay:Bool
}

typedef WeekFilePsych =
{
	// JSON variables
	var songs:Array<Dynamic>;
	var weekCharacters:Array<String>;
	var weekBackground:String;
	var weekBefore:String;
	var storyName:String;
	var weekName:String;
	var freeplayColor:Array<Int>;
	var startUnlocked:Bool;
	var hiddenUntilUnlocked:Bool;
	var hideStoryMode:Bool;
	var hideFreeplay:Bool;
	var difficulties:String;
}

@:publicFields
@:structInit
class SongMetaData
{
	var songName:String = 'test';
	var displaySongName:String = null;
	var healthIcon:String = null;
	var freeplayColor:DynamicColor = 0xFFABCACA;
	var invisibleInFreeplay:Bool = false;
	var extraFields:Dynamic = null;
	public function toString()
		return FlxStringUtil.getDebugString([
			LabelValuePair.weak("displaySongName", displaySongName),
			LabelValuePair.weak("extraFields", extraFields),
			LabelValuePair.weak("freeplayColor", freeplayColor),
			LabelValuePair.weak("healthIcon", healthIcon),
			LabelValuePair.weak("invisibleInFreeplay", invisibleInFreeplay),
			LabelValuePair.weak("songName", songName),
		]);
}

typedef ExtraFields =
{
	?extraFields:Dynamic // struct
}
