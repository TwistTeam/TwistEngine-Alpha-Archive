package game.backend.system.song;

import game.backend.system.song.Song;

import haxe.extern.EitherType;
/*
typedef NoteType = EitherType<String, Int>;

@:forward
abstract SectionNoteData(Array<Dynamic>) from Array<Dynamic> to Array<Dynamic> // dynamic fascism
{
	public var time(get, set):Float;
	inline function get_time() return this[0];
	inline function set_time(i) return this[0] = i;

	public var data(get, set):Int;
	inline function get_data() return this[1];
	inline function set_data(i) return this[1] = i;

	public var sustainLength(get, set):Float;
	inline function get_sustainLength() return this[2];
	inline function set_sustainLength(i) return this[2] = i;

	public var type(get, set):NoteType;
	inline function get_type() return this[3];
	inline function set_type(i) return this[3] = i;

	public inline function new(strumTime:Float, data:Int, ?sustainLength:Float, ?type:Null<NoteType>)
	{
		this = [strumTime, data, sustainLength, type ?? 0];
	}

	// for chart editor & old psych
	public var isEvent(get, never):Bool;
	inline function get_isEvent() return this.length < 2 || data < 0; // ugh // sustainLength[2] == null

	public var events(get, set):Array<EventData>;
	inline function get_events() return this[1];
	inline function set_events(i) return this[1] = i;

	public static function dataCompression(ogData:SectionNoteData, ?disableConvertToEvent:Bool):EitherType<SectionNoteData, EventSection>
	{
		if (ogData.isEvent)
		{
			if (disableConvertToEvent)
			{

			}
			else
			{

			}
		}
		else
		{

		}
		return null;
	}
	public function getCompressed(data:SectionNoteData, ?disableConvertToEvent:Bool):EitherType<SectionNoteData, EventSection>
	{
		return dataCompression(this, disableConvertToEvent);
	}
}
*/
typedef SwagSection = {
	sectionNotes:Array<Dynamic>,
	sectionBeats:Float,
	mustHitSection:Bool,
	// typeOfSection:Int,
	gfSection:Bool,
	bpm:Float,
	changeBPM:Bool,
	altAnim:Bool
}

class Section
{
	public var sectionNotes:Array<Dynamic> = [];

	public var sectionBeats:Float = 4;
	public var gfSection:Bool = false;
	// public var typeOfSection:Int = 0;
	public var mustHitSection:Bool = true;

	public function new(sectionBeats:Float = 4)
	{
		this.sectionBeats = sectionBeats;
		trace('test created section: ' + sectionBeats);
	}
}