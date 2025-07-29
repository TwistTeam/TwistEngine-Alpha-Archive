package game.backend.system;

/*
import game.backend.system.song.Section.SwagSection;
import game.backend.data.EngineData;
import game.states.playstate.PlayState;

import flixel.FlxG;
import flixel.input.keyboard.FlxKey;
import flixel.input.gamepad.FlxGamepadInputID;
import flixel.util.FlxSort;

// I need to rewrite this all - Redar13
typedef DeKeyV1 = {
	hitTime:Float,
	direction:Int
}

typedef RatingShit = {
	hitTime:Float,
	name:String
}

typedef ScoreSave = {
	misses:Int,
	score:Int,
	maxScore:Int,
	acc:Float,
	rank:String
}

typedef SaveShit = {
	nameVar:String,
	variable:Dynamic
}

@:publicFields class ReplayDataV1{
	var songName:String = "No Song Found";
	var press:Array<DeKeyV1> = [];
	var release:Array<DeKeyV1> = [];
	var justPress:Array<DeKeyV1> = [];
	var songNotes:Array<SwagSection> = [];
	var timestamp:Date = Date.now();
	var timestampEnd:Date = Date.now();
	var versionGame:String = EngineData.engineVersion;
	var noteSpeed:Float = 2.5;
	var saveVersion:String = 'v1';
	var saves:Array<SaveShit> = [];
	var ratings:Array<RatingShit> = [];
	var saveScore:ScoreSave = {
		misses: 0,
		score: 0,
		maxScore: 0,
		acc: 1,
		rank: 'nothing'
	}
	function new(){}
}

class ReplayHandler{
	public var data:ReplayDataV1;
	public function new()
		data = new ReplayDataV1();
	
	function sortByShit(Obj1:DeKeyV1, Obj2:DeKeyV1):Int
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.hitTime, Obj2.hitTime);
	
	public function load(song:String){
		song = Paths.formatToSongPath(song);
		// var thisVar:ReplayDataV1 = cast Reflect.getProperty(FlxG.save.data, '${song}_replayData');
		// if (thisVar != null){
		// 	// for(i in [thisVar.press, thisVar.release, thisVar.justPress]) i.sort(sortByShit);
		// 	data.songName = thisVar.songName;
		
		// 	// load keys
		// 	for(i in thisVar.press)
		// 		data.press.push({
		// 			hitTime: i.hitTime,
		// 			direction: i.direction
		// 		});
		// 	for(i in thisVar.release)
		// 		data.release.push({
		// 			hitTime: i.hitTime,
		// 			direction: i.direction
		// 		});
		// 	for(i in thisVar.justPress)
		// 		data.justPress.push({
		// 			hitTime: i.hitTime,
		// 			direction: i.direction
		// 		});
		
		// 	// load user saves
		// 	for(i in thisVar.saves)
		// 		data.saves.push({
		// 			nameVar: i.nameVar,
		// 			variable: i.variable
		// 		});
		// 	for(i in thisVar.ratings)
		// 		data.ratings.push({					
		// 			hitTime: i.hitTime,
		// 			name: i.name
		// 		});
		// 	data.timestamp = thisVar.timestamp;
		// 	data.timestampEnd = thisVar.timestampEnd;
		// 	data.noteSpeed = thisVar.noteSpeed;
		// 	data.saveVersion = thisVar.saveVersion;
		// 	data.saveScore = thisVar.saveScore;
		// 	data.versionGame = thisVar.versionGame;
		// }else
		// 	trace('\"${song}_replayData\" doesn\'t exits.');
		// trace(data);
	}
	
	public static function hasData(song:String) return Reflect.getProperty(FlxG.save.data, '${song}_replayData') != null;
	
	public function save(song:String){
		song = Paths.formatToSongPath(song);
		data.timestampEnd = Date.now();
		// Reflect.setProperty(FlxG.save.data, '${song}_replayData', data);
		// FlxG.save.flush();
	}

	public function toString():String
		return 'SongName: ${data.songName}, Pressed:${data.press.length}, Release:${data.release.length}, JustPressed:${data.justPress.length}, SongNotes:${data.songNotes.length},  TimeStart:${data.timestamp}, TimeEnd:${data.timestampEnd}, VersionGame:${data.versionGame}, SaveVersion:${data.saveVersion}, NoteSpeed:${data.noteSpeed}, Saves:${data.saves}, Ratings:${data.ratings.length}, Score:${data.saveScore}';
}
*/