package game.backend.system.song;

@:publicFields
class Rating
{
	var name:String = '';
	var image:String = '';
	var counter:String = '';
	var hitWindow:Null<Int> = 0; // ms
	var ratingMod:Float = 1;
	var score:Int = 350;
	var noteSplash:Bool = true;
	var hits:Int = 0;

	function new(name:String)
	{
		this.name = name;
		this.image = name;
		this.counter = name + 's';
		this.hitWindow = ClientPrefs.field(name + 'Window') ?? 0;
	}

	static function loadDefault():Array<Rating>
	{
		var ratingsData:Array<Rating> = [new Rating('sick')]; //highest rating goes first

		var rating:Rating = new Rating('good');
		rating.ratingMod = 0.67;
		rating.score = 200;
		rating.noteSplash = false;
		ratingsData.push(rating);

		rating = new Rating('bad');
		rating.ratingMod = 0.34;
		rating.score = 100;
		rating.noteSplash = false;
		ratingsData.push(rating);

		rating = new Rating('shit');
		rating.ratingMod = 0;
		rating.score = 50;
		rating.noteSplash = false;
		ratingsData.push(rating);
		return ratingsData;
	}
}