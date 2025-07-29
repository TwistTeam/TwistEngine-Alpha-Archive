package game.objects;

import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;

enum abstract Alignment(String) from String
{
	var LEFT = "left";
	var CENTERED = "centered";
	var RIGHT = "right";

	public function fromString(value:String):Alignment
		return switch (value.toLowerCase().trim())
		{
			case "right": Alignment.RIGHT;
			case "centered": Alignment.CENTERED;
			default: LEFT;
		}
}

class Alphabet extends FlxTypedSpriteGroup<AlphaCharacter>
{
	public var text(default, set):String;

	public var bold:Bool = false;

	public var isMenuItem:Bool = false;
	public var targetY:Int = 0;
	public var changeX:Bool = true;
	public var changeY:Bool = true;

	public var alignment(default, set):Alignment = LEFT;
	public var scaleX(default, set):Float = 1;
	public var scaleY(default, set):Float = 1;
	public var rows:Int = 0;

	public var distancePerItem:FlxPoint = FlxPoint.get(20, 120);
	public var startPosition:FlxPoint = FlxPoint.get(0, 0); // for the calculations

	public function new(x:Float, y:Float, text:String = "", ?bold:Bool = true)
	{
		super(x, y);
		moves = false;

		this.startPosition.x = x;
		this.startPosition.y = y;
		this.bold = bold;
		this.text = text;
	}

	public inline function setAlignmentFromString(align:String)
		alignment = alignment.fromString(align);

	inline function set_alignment(align:Alignment)
	{
		alignment = align;
		updateAlignment();
		return align;
	}

	private function updateAlignment()
	{
		for (letter in members)
		{
			final newOffset:Float = switch (alignment)
			{
				case CENTERED: letter.rowWidth / 2;
				case RIGHT: letter.rowWidth;
				default: 0;
			};

			letter.offset.x -= letter.alignOffset;
			letter.alignOffset = newOffset * scale.x;
			letter.offset.x += letter.alignOffset;
		}
	}

	function set_text(newText:String)
	{
		newText = newText.replace('\\n', '\n');
		clearLetters();
		createLetters(newText);
		updateAlignment();
		return this.text = newText;
	}

	public function clearLetters()
	{
		clear();
		rows = 0;
	}

	public function setScale(newX:Float, ?newY:Null<Float>)
	{
		var lastX:Float = scale.x;
		var lastY:Float = scale.y;
		newY ??= newX;
		@:bypassAccessor
		scaleX = newX;
		@:bypassAccessor
		scaleY = newY;

		scale.x = newX;
		scale.y = newY;
		softReloadLetters(newX / lastX, newY / lastY);
	}

	inline function set_scaleX(value:Float)
	{
		if (value == scaleX)
			return value;

		var ratio:Float = value / scale.x;
		scale.x = value;
		scaleX = value;
		softReloadLetters(ratio, 1);
		return value;
	}

	inline function set_scaleY(value:Float)
	{
		if (value == scaleY)
			return value;

		var ratio:Float = value / scale.y;
		scale.y = value;
		scaleY = value;
		softReloadLetters(1, ratio);
		return value;
	}

	public function softReloadLetters(ratioX:Float = 1, ?ratioY:Null<Float>)
	{
		ratioY ??= ratioX;

		for (letter in members)
		{
			if (letter != null)
			{
				letter.setupAlphaCharacter((letter.x - x) * ratioX + x, (letter.y - y) * ratioY + y);
			}
		}
	}

	override function destroy()
	{
		distancePerItem.put();
		startPosition.put();
		super.destroy();
	}

	override function update(elapsed:Float)
	{
		if (isMenuItem)
		{
			var lerpVal:Float = FlxMath.bound(elapsed * 9.6, 0, 1);
			if (changeX)
				x = FlxMath.lerp(x, targetY * distancePerItem.x + startPosition.x, lerpVal);
			if (changeY)
				y = FlxMath.lerp(y, targetY * 1.3 * distancePerItem.y + startPosition.y, lerpVal);
		}
		super.update(elapsed);
	}

	public function snapToPosition()
	{
		if (isMenuItem)
		{
			if (changeX)
				x = targetY * distancePerItem.x + startPosition.x;
			if (changeY)
				y = targetY * 1.3 * distancePerItem.y + startPosition.y;
		}
	}

	private static var Y_PER_ROW:Float = 85;

	private function createLetters(newText:String)
	{
		var consecutiveSpaces:Int = 0;

		var xPos:Float = 0;
		var rowData:Array<Float> = [];
		rowData.resize(newText.length);
		rows = 0;
		for (character in newText.split(''))
		{
			if (character == '\n')
			{
				xPos = 0;
				rows++;
			}
			else
			{
				var spaceChar:Bool = (character == " " || (bold && character == "_"));
				if (spaceChar)
					consecutiveSpaces++;

				// var isAlphabet:Bool = AlphaCharacter.isTypeAlphabet(character.toLowerCase());
				if ((!bold || !spaceChar) && AlphaCharacter.allLetters.exists(character.toLowerCase()))
				{
					if (consecutiveSpaces > 0)
					{
						if (bold || xPos < FlxG.width * 0.65)
						{
							xPos += 28 * consecutiveSpaces * scaleX;
						}
						else
						{
							xPos = 0;
							rows++;
						}
					}
					consecutiveSpaces = 0;

					var letter:AlphaCharacter = recycle(AlphaCharacter, true);
					letter.scale.x = scaleX;
					letter.scale.y = scaleY;

					letter.setupAlphaCharacter(xPos, rows * Y_PER_ROW * scale.y, character, bold);
					letter.parent = this;

					letter.row = rows;
					xPos += letter.width + (letter.letterOffset[0] + (bold ? 0 : 2)) * scale.x;
					rowData[rows] = xPos;

					add(letter);
				}
			}
		}

		for (letter in members)
		{
			letter.rowWidth = rowData[letter.row];
		}
		rowData.clearArray();
		if (members.length > 0)
			rows++;
	}
}

///////////////////////////////////////////
// ALPHABET LETTERS, SYMBOLS AND NUMBERS //
///////////////////////////////////////////

/*enum LetterType
	{
	ALPHABET;
	NUMBER_OR_SYMBOL;
}*/
typedef Letter =
{
	?anim:Null<String>,
	?offsets:Array<Float>,
	?offsetsBold:Array<Float>
}

class AlphaCharacter extends FlxSprite
{
	// public static var alphabet:String = "abcdefghijklmnopqrstuvwxyz";
	// public static var numbers:String = "1234567890";
	// public static var symbols:String = "|~#$%()*+-:;<=>@[]^_.,'!?";
	public var image(default, set):String;

	public static final allLetters:Map<String, Null<Letter>> = [
		// alphabet
		'a' => null,
		'b' => null,
		'c' => null,
		'd' => null,
		'e' => null,
		'f' => null,
		'g' => null,
		'h' => null,
		'i' => null,
		'j' => null,
		'k' => null,
		'l' => null,
		'm' => null,
		'n' => null,
		'o' => null,
		'p' => null,
		'q' => null,
		'r' => null,
		's' => null,
		't' => null,
		'u' => null,
		'v' => null,
		'w' => null,
		'x' => null,
		'y' => null,
		'z' => null,
		// additional alphabet
		'á' => null,
		'é' => null,
		'í' => null,
		'ó' => null,
		'ú' => null,
		'à' => null,
		'è' => null,
		'ì' => null,
		'ò' => null,
		'ù' => null,
		'â' => null,
		'ê' => null,
		'î' => null,
		'ô' => null,
		'û' => null,
		'ã' => null,
		'ë' => null,
		'ï' => null,
		'õ' => null,
		'ü' => null,
		'ä' => null,
		'ö' => null,
		'å' => null,
		'ø' => null,
		'æ' => null,
		'ñ' => null,
		'ç' => {
			offsetsBold: [0, -11]
		},
		'š' => null,
		'ž' => null,
		'ý' => null,
		'ÿ' => null,
		'ß' => null,
		// numbers
		'0' => null,
		'1' => null,
		'2' => null,
		'3' => null,
		'4' => null,
		'5' => null,
		'6' => null,
		'7' => null,
		'8' => null,
		'9' => null,
		// symbols
		'&' => {offsetsBold: [0, 2]},
		'(' => {offsetsBold: [0, 0]},
		')' => {offsetsBold: [0, 0]},
		'[' => null,
		']' => {offsets: [0, -1]},
		'*' => {offsets: [0, 28], offsetsBold: [0, 40]},
		'+' => {offsets: [0, 7], offsetsBold: [0, 12]},
		'-' => {offsets: [0, 16], offsetsBold: [0, 16]},
		'<' => {offsetsBold: [0, -2]},
		'>' => {offsetsBold: [0, -2]},
		'\'' => {anim: 'apostrophe', offsets: [0, 32], offsetsBold: [0, 40]},
		'"' => {anim: 'quote', offsets: [0, 32], offsetsBold: [0, 40]},
		'!' => {anim: 'exclamation'},
		'?' => {anim: 'question'}, // also used for "unknown"
		'.' => {anim: 'period'},
		'❝' => {anim: 'start quote', offsets: [0, 24], offsetsBold: [0, 40]},
		'❞' => {anim: 'end quote', offsets: [0, 24], offsetsBold: [0, 40]},
		'_' => null,
		'#' => null,
		'$' => null,
		'%' => null,
		':' => {offsets: [0, 2], offsetsBold: [0, 8]},
		';' => {offsets: [0, -2], offsetsBold: [0, 4]},
		'@' => null,
		'^' => {offsets: [0, 28], offsetsBold: [0, 38]},
		',' => {anim: 'comma', offsets: [0, -6], offsetsBold: [0, -4]},
		'\\' => {anim: 'back slash', offsets: [0, 0]},
		'/' => {anim: 'forward slash', offsets: [0, 0]},
		'|' => null,
		'~' => {offsets: [0, 16], offsetsBold: [0, 20]},
		// additional symbols
		'¡' => {anim: 'inverted exclamation', offsets: [0, -20], offsetsBold: [0, -20]},
		'¿' => {anim: 'inverted question', offsets: [0, -20], offsetsBold: [0, -20]},
		'{' => null,
		'}' => null,
		'•' => {anim: 'bullet', offsets: [0, 18], offsetsBold: [0, 20]}
	];

	@:allow(game.objects.Alphabet)
	var parent:Alphabet;

	public var alignOffset:Float = 0; // Don't change this
	public var letterOffset:Array<Float> = [0, 0];

	public var row:Int = 0;
	public var rowWidth:Float = 0;
	public var character:String = '?';

	public function new()
	{
		super(x, y);
		moves = false;
		image = 'alphabet';
	}

	public var curLetter:Letter = null;

	public function setupAlphaCharacter(x:Float, y:Float, ?character:String, ?bold:Null<Bool>)
	{
		this.x = x;
		this.y = y;

		if (parent != null)
		{
			if (bold == null)
				bold = parent.bold;
			this.scale.x = parent.scaleX;
			this.scale.y = parent.scaleY;
		}

		if (character != null)
		{
			this.character = character;
			curLetter = null;
			var lowercase:String = this.character.toLowerCase();
			if (allLetters.exists(lowercase))
				curLetter = allLetters.get(lowercase);
			else
				curLetter = allLetters.get('?');

			var suffix:String = '';
			if (bold)
				suffix = ' bold';
			else if (isTypeAlphabet(lowercase))
			{
				if (lowercase != this.character)
					suffix = ' uppercase';
				else
					suffix = ' lowercase';
			}
			else
				suffix = ' normal';

			var alphaAnim:String = lowercase;
			if (curLetter != null && curLetter.anim != null)
				alphaAnim = curLetter.anim;

			var anim:String = alphaAnim + suffix;
			animation.addByPrefix(anim, anim, 24);
			animation.play(anim, true);
			if (animation.curAnim == null)
			{
				if (suffix != ' bold')
					suffix = ' normal';
				anim = 'question' + suffix;
				animation.addByPrefix(anim, anim, 24);
				animation.play(anim, true);
			}
		}
		updateHitbox();
	}

	public static function isTypeAlphabet(c:String) // thanks kade
	{
		var ascii = StringTools.fastCodeAt(c, 0);
		return (ascii >= 65 && ascii <= 90) || (ascii >= 97 && ascii <= 122) || (ascii >= 192 && ascii <= 214) || (ascii >= 216 && ascii <= 246)
			|| (ascii >= 248 && ascii <= 255);
	}

	private function set_image(name:String)
	{
		if (frames == null) // first setup
		{
			image = name;
			frames = Paths.getSparrowAtlas(name);
			return name;
		}

		var lastAnim:String = animation?.name;
		image = name;
		frames = Paths.getSparrowAtlas(name);
		this.scale.x = parent.scaleX;
		this.scale.y = parent.scaleY;
		alignOffset = 0;

		if (lastAnim != null)
		{
			animation.addByPrefix(lastAnim, lastAnim, 24);
			animation.play(lastAnim, true);

			updateHitbox();
		}
		return name;
	}

	public function updateLetterOffset()
	{
		if (animation.curAnim == null)
		{
			trace(character);
			return;
		}

		var add:Float = 110;
		if (animation.curAnim.name.endsWith('bold'))
		{
			if (curLetter != null && curLetter.offsetsBold != null)
				letterOffset = curLetter.offsetsBold.copy();
			add = 70;
		}
		else
		{
			if (curLetter != null && curLetter.offsets != null)
				letterOffset = curLetter.offsets.copy();
		}
		add *= scale.y;
		offset.x += letterOffset[0] * scale.x;
		offset.y += letterOffset[1] * scale.y - (add - height);
	}

	public override function updateHitbox()
	{
		super.updateHitbox();
		updateLetterOffset();
	}

	public override function destroy()
	{
		letterOffset.clearArray();
		curLetter = null;
		parent = null;
		super.destroy();
	}
}

class TypedAlphabet extends Alphabet
{
	public var onFinish:Void->Void = null;
	public var finishedText:Bool = false;
	public var delay:Float = 0.05;
	public var sound:String = 'dialogue';
	public var volume:Float = 1;

	public function new(x:Float, y:Float, text:String = "", ?delay:Float = 0.05, ?bold:Bool = false)
	{
		super(x, y, text, bold);

		this.delay = delay;
	}

	override private function set_text(newText:String)
	{
		super.set_text(newText);

		resetDialogue();
		return newText;
	}

	private var _curLetter:Int = -1;
	private var _timeToUpdate:Float = 0;

	override function update(elapsed:Float)
	{
		if (!finishedText)
		{
			var playedSound:Bool = false;
			_timeToUpdate += elapsed;
			while (_timeToUpdate >= delay)
			{
				showCharacterUpTo(_curLetter + 1);
				if (!playedSound && sound != '' && (delay > 0.025 || _curLetter % 2 == 0))
				{
					FlxG.sound.play(Paths.sound(sound), volume);
				}
				playedSound = true;

				_curLetter++;
				if (_curLetter >= members.length - 1)
				{
					finishedText = true;
					if (onFinish != null)
						onFinish();
					_timeToUpdate = 0;
					break;
				}
				_timeToUpdate = 0;
			}
		}

		super.update(elapsed);
	}

	public function showCharacterUpTo(upTo:Int)
	{
		var start:Int = _curLetter;
		if (start < 0)
			start = 0;

		for (i in start...(upTo + 1))
		{
			if (members[i] != null)
				members[i].visible = true;
			// trace('test, showing: $i');
		}
	}

	public function resetDialogue()
	{
		_curLetter = -1;
		finishedText = false;
		_timeToUpdate = 0;
		for (letter in members)
		{
			letter.visible = false;
		}
	}

	public function finishText()
	{
		if (finishedText)
			return;

		showCharacterUpTo(members.length - 1);
		if (sound != '')
			FlxG.sound.play(Paths.sound(sound), volume);
		finishedText = true;

		if (onFinish != null)
			onFinish();
		_timeToUpdate = 0;
	}
}
