package game.backend.utils;

// Special Thanks to RichTrash21

import flixel.math.FlxMath;
import flixel.util.FlxStringUtil;

class SRT
{
	public static function parseSRT(data:String, ?container:Array<SRT>):Array<SRT>
	{
		final parsedSRT:Array<SRT> = container == null ? [] : container;
		if (FlxStringUtil.isNullOrEmpty(data)) // пустой .srt - идешь нахуй :3
			return parsedSRT;

		final sepLines:Array<String> = data.split("\n");
		final tempData:Array<Array<String>> = [];
		var temp:Array<String> = null;
		// очищаем от мусора + делаем жизнь легче
		while (sepLines.contains("\r"))
		{
			if (sepLines[0] == "\r")
				sepLines.shift();

			final index:Int = sepLines.indexOf("\r");
			temp = sepLines.splice(0, index == -1 ? sepLines.length : index);
			if (temp.length > 3) // поправляем мультистрочное строение
				temp[2] = temp.splice(2, temp.length).join("");

			tempData.push(temp);
		}

		// НАКОНЕЦ ТО ПЕРЕДЕЛЫВАЕМ ЭТО ДЕРЬМО В SRT ЕПИИИИИИИ
		var section:Array<String> = null;
		var parsedTime:Array<Float> = [];
		while (tempData.length > 0)
		{
			section = tempData.pop();
			parseTimeSRT(section[1], parsedTime);
			final _id:Null<Int> = Std.parseInt(section[0].trim()); // блять, ПОЧЕМУ Std.parseInt(str) ДАЕТ null ПРИ str = "1" Я ЕБАЛ ХАКС
			parsedSRT.push(new SRT(_id == null ? tempData.length + 1 : _id, parsedTime.shift(), parsedTime.shift(), section[2]));
			section.clearArray();
		}
		parsedSRT.sort(sortLines);
		return parsedSRT;
	}

	public static function parseTimeSRT(data:String, ?container:Array<Float>):Array<Float>
	{
		final parsedTime:Array<Float> = container == null ? [] : container;
		if (FlxStringUtil.isNullOrEmpty(data))
			return parsedTime;

		final tempData:Array<String> = data.split("-->");
		while (tempData.length > 0)
		{
			final sepTime:Array<String> = tempData.pop().trim().split(":");
			parsedTime.push(CoolUtil.timeToSeconds(Std.parseFloat(sepTime.shift()), Std.parseFloat(sepTime.shift()), Std.parseFloat(sepTime.shift().replace(",", "."))));
		}
		parsedTime.reverse();
		return parsedTime;
	}

	public static function sortLines(Line1:SRT, Line2:SRT):Int
		return FlxMath.numericComparison(Line1.id, Line2.id);

	public var id:Int;
	public var start:Float;
	public var end:Float;
	public var text:String;

	public function new(id:Int, start:Float, end:Float, text:String)
	{
		this.id = id;
		this.start = start;
		this.end = end;
		this.text = text;
	}

	public function toString():String
		return FlxStringUtil.getDebugString([
			LabelValuePair.weak("id", id),
			LabelValuePair.weak("time", [start, end]),
			LabelValuePair.weak("text", text)
		]);
}
