package game.backend.utils;

import game.backend.utils.Difficulty;

@:structInit
@:publicFields
class ScoreData {
	var score:Int;
	var misses:Int = 0;
	var rating:Float = 0;
	function toString()
		return 'Score: $score, Misses: $misses, Rating: $rating';
}
class Highscore
{
	public static var weeksData:Map<String, ScoreData> = new Map();
	public static var songsData:Map<String, ScoreData> = new Map();

	public static inline function getWeekData(song:String, ?diff:String):ScoreData
		return weeksData.get(formatSong(song, diff));

	public static inline function getSongData(song:String, ?diff:String):ScoreData
		return songsData.get(formatSong(song, diff));

	public static inline function existsWeekData(song:String, ?diff:String):Bool
		return weeksData.exists(formatSong(song, diff));

	public static inline function existsSongData(song:String, ?diff:String):Bool
		return songsData.exists(formatSong(song, diff));

	public static function formatSong(song:String, ?diff:String):String
		return Paths.formatToSongPath(song) + Difficulty.getFilePath(diff);

	public static function resetSong(song:String, ?diff:String):Void
	{
		final daSong:String = formatSong(song, diff);
		songsData.set(daSong, {score:0});
		FlxG.save.data.songsData = songsData;
		FlxG.save.flush();
	}
	public static function resetWeek(week:String, ?diff:String):Void
	{
		final daWeek:String = formatSong(week, diff);
		weeksData.set(daWeek, {score:0});
		FlxG.save.data.weeksData = weeksData;
		FlxG.save.flush();
	}

	public static function save(daSong:String, data:ScoreData, ?diff:String):Void{
		daSong = formatSong(daSong, diff);
		if (songsData.exists(daSong))
		{
			final olddata = songsData.get(daSong);
			if (olddata.score < data.score)
			{
				songsData.set(daSong, data);
				// data.score = data.score;
				// data.misses = data.misses;
				// data.rating = data.rating;
			}
		}
		else
		{
			songsData.set(daSong, data);
		}
		trace(daSong + " => " + [for( i in Reflect.fields(data)) '$i = ' + Reflect.field(data, i)].join(', '));

		FlxG.save.data.songsData = songsData;
		FlxG.save.flush();
	}
	public static function saveWeek(week:String, data:ScoreData, ?diff:String):Void
	{
		final daWeek:String = formatSong(week, diff);

		if (weeksData.exists(daWeek))
		{
			final olddata = weeksData.get(daWeek);
			if (olddata.score < data.score)
			{
				weeksData.set(daWeek, data);
				// data.score = data.score;
				// data.misses = data.misses;
				// data.rating = data.rating;
			}
		}
		else
		{
			weeksData.set(daWeek, data);
		}

		FlxG.save.data.weeksData = weeksData;
		FlxG.save.flush();
	}


	public static function load():Void
	{
		if (FlxG.save.data.weeksData != null)	weeksData = FlxG.save.data.weeksData;
		if (FlxG.save.data.songsData != null)	songsData = FlxG.save.data.songsData;
		// trace(weeksData);
		// trace(songsData);
	}
}