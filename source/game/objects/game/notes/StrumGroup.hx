package game.objects.game.notes;

import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxPoint;
import flixel.tweens.FlxTween.TweenOptions;
import flixel.util.FlxArrayUtil;
import flixel.util.FlxDestroyUtil;
import flixel.util.FlxHorizontalAlign;
import flixel.util.FlxSignal.FlxTypedSignal;
import game.objects.game.notes.*;
import game.objects.game.notes.Note.DirectionNote;

typedef TweenVariables =
{
	?duraction:Null<Float>,
	?variables:Any,
	?prefixFunction:StrumNote->Void,
	?tweenOption:TweenOptions
}

typedef FlxBoolSignal = FlxTypedSignal<Bool->Void>;

typedef StrumGroupGenerateOptions = {
	?downScroll:Null<Bool>,
	?cpuControl:Null<Bool>,
	?scaleFactor:Null<Float>,
	?funcIn:(StrumNote, Int) -> Any,
	?funcOut:(StrumNote, Int) -> Any,
	?funcMove:(StrumNote, Int) -> Any
};
class StrumGroup extends FlxTypedGroup<StrumNote>
{
	public var position:FlxPoint = FlxPoint.get();
	public var offsets:FlxPoint = FlxPoint.get();

	public var scaleNoteFactor(default, set):Float = 1.0;

	function set_scaleNoteFactor(val:Float):Float
	{
		if (val == scaleNoteFactor)
			return val;

		/*
		var ratio = val / scaleNoteFactor - 1.0;
		scaleNoteFactor = val;
		forEach(strumNote ->
		{
			strumNote.baseScale *= ratio + 1.0;
			strumNote.x -= (position.x - offsets.x - strumNote.x + strumNote.origin.x) * ratio;
			strumNote.y -= (position.y - offsets.y - strumNote.y + strumNote.origin.y) * ratio;
		});
		*/

		var ratio = val / scaleNoteFactor;
		scaleNoteFactor = val;
		forEach(strumNote -> strumNote.baseScale *= ratio);
		updateStrumsPos();

		return scaleNoteFactor;
	}

	public var alignment:FlxHorizontalAlign = FlxHorizontalAlign.CENTER;

	public var onCPUControlToggle(get, never):FlxBoolSignal;

	@:noCompletion var _onCPUControlToggle:FlxBoolSignal;

	public var cpuControl(default, set):Bool = true;

	@:noCompletion function set_cpuControl(val:Bool):Bool
	{
		forEach(strumNote -> strumNote.cpuControl = val);
		if (_onCPUControlToggle != null)
			_onCPUControlToggle.dispatch(val);
		return cpuControl = val;
	}

	@:noCompletion
	function get_onCPUControlToggle():FlxBoolSignal
	{
		_onCPUControlToggle ??= new FlxBoolSignal();
		return _onCPUControlToggle;
	}

	public var onDownScrollToggle(get, never):FlxBoolSignal;

	@:noCompletion var _onDownScrollToggle:FlxBoolSignal;

	public var downScroll(default, set):Bool = false;

	@:noCompletion function set_downScroll(val:Bool):Bool
	{
		forEach(strumNote -> strumNote.downScroll = val);
		if (_onDownScrollToggle != null)
			_onDownScrollToggle.dispatch(val);
		return downScroll = val;
	}

	@:noCompletion
	function get_onDownScrollToggle():FlxBoolSignal
	{
		_onDownScrollToggle ??= new FlxBoolSignal();
		return _onDownScrollToggle;
	}

	public var notesDistance:Float = Note.swagWidth;

	@:access(game.objects.game.note)
	var drawMembers(default, null):Array<StrumNote> = [];

	public var isPlayer:Bool = false;

	public function new(isPlayer:Bool = false)
	{
		super();
		this.isPlayer = isPlayer;
		memberAdded.add(i -> {
			drawMembers.push(i);
			i.groupParent = this;
		});
		memberRemoved.add(i -> {
			drawMembers.remove(i);
			i.groupParent = null;
		});
	}

	public function sortDrawMembers()
	{
		drawMembers.sort((a, b) -> {
			if (a.animation.name != "confirm" && b.animation.name == "confirm")
				return -1;
			else if (a.animation.name == "confirm" && b.animation.name != "confirm")
				return 1;
			else
				return -1;
		});
	}

	public function setToUpperNote(note:StrumNote)
	{
		if (drawMembers.remove(note))
		{
			drawMembers.push(note);
		}
	}

	@:access(flixel.FlxCamera)
	public override function draw():Void
	{
		final oldDefaultCameras = flixel.FlxCamera._defaultCameras;
		if (cameras != null)
		{
			flixel.FlxCamera._defaultCameras = cameras;
		}

		for (basic in drawMembers)
		{
			if (basic != null && basic.exists && basic.visible)
				basic.draw();
		}

		flixel.FlxCamera._defaultCameras = oldDefaultCameras;
	}

	public function generateStrums(deNoteDirections:Array<DirectionNote>, ?options:StrumGroupGenerateOptions):Array<StrumNote>
	{
		if (FlxArrayUtil.equals(members.map(i -> i.typeDirection), deNoteDirections))
			return members;
		options ??= {};
		final allreadyAddedStrums = members.filter(obj -> return deNoteDirections.contains(obj.typeDirection));
		final goneStrums = members.filter(obj -> return !allreadyAddedStrums.contains(obj));

		final neededToAddStrums = deNoteDirections.filter(i -> {
			for (spr in allreadyAddedStrums)
				if (spr.typeDirection == i)
					return false;
			return true;
		});

		final deAddedStrums = [
			for (i in 0...neededToAddStrums.length) new StrumNote(0, 0, i, isPlayer, neededToAddStrums[i])
		];
		function doShet(strums:Array<StrumNote>, ?func:(StrumNote, Int) -> Any, ?toDO:StrumNote->Void)
		{
			var obj:StrumNote;
			var i:Int = -1;
			while (++i < strums.length)
			{
				obj = strums[i];
				if (toDO != null)
				{
					var funcVal:Any = true;
					if (func != null)
						funcVal = func(obj, i);
					if (funcVal != false)
						toDO(obj);
				}
				else
				{
					if (func != null)
						func(obj, i);
					obj.baseScale = scaleNoteFactor;
				}
			}
		}
		if (deAddedStrums.length > 0)
		{
			for (i in deAddedStrums)
				add(i);
		}
		final finalStrums = deAddedStrums.concat(allreadyAddedStrums);

		if (options.scaleFactor != null)
		{
			scaleNoteFactor = options.scaleFactor;
		}

		updateStrumsPos(finalStrums);

		if (options.downScroll != null)
		{
			this.downScroll = options.downScroll;
		}
		if (options.cpuControl != null)
		{
			this.cpuControl = options.cpuControl;
		}

		if (allreadyAddedStrums.length > 0)
		{
			doShet(allreadyAddedStrums, options?.funcMove);
		}
		if (deAddedStrums.length > 0)
		{
			doShet(deAddedStrums, options?.funcIn);
		}
		if (goneStrums.length > 0)
		{
			doShet(goneStrums, options?.funcOut, i -> this.remove(i));
		}
		return finalStrums;
	}

	public function updateStrumsPos(?members:Array<StrumNote>, ?alignment:FlxHorizontalAlign, ?changeX:Bool = true, ?changeY:Bool = true)
	{
		members ??= this.members;
		alignment ??= this.alignment;
		final length = members.length;
		if (length == 0)
			return;

		final noteWidth:Float = notesDistance * scaleNoteFactor;
		var totalWidth:Float = switch (alignment)
		{
			case RIGHT:		length * noteWidth;
			// case CENTER:	length * noteWidth / 2;
			default:		0;
		}
		for (i => strum in members)
		{
			if (changeX)
				strum.x = strum.defPos.x = position.x + offsets.x + noteWidth * i - totalWidth;
			if (changeY)
				strum.y = strum.defPos.y = position.y + offsets.y;

		}
		if (alignment == CENTER && changeX)
		{
			// TODO: Find the correct formula to calculate the offset to center without using the second loop.
			totalWidth = 0;
			for (i => strum in members)
			{
				totalWidth = Math.max(strum.x + strum.width - position.x - offsets.x, totalWidth);
			}
			totalWidth /= 2;
			for (i => strum in members)
			{
				strum.x = strum.defPos.x = strum.x - totalWidth;
			}
		}
	}

	public function updateStrumPos(?member:StrumNote, ?members:Array<StrumNote>, ?alignment:FlxHorizontalAlign, ?changeX:Bool = true, ?changeY:Bool = true)
	{
		members ??= this.members;
		alignment ??= this.alignment;
		final length = members.length;
		if (length == 0)
			return;
		final offsetIndex = switch (alignment)
		{
			case RIGHT:		length;
			case CENTER:	length / 2;
			case LEFT:		0;
		}
		if (changeX)
			member.x = position.x + offsets.x + notesDistance * (members.indexOf(member) - offsetIndex) * scaleNoteFactor;
		if (changeY)
			member.y = position.y + offsets.y;
	}

	public override function destroy():Void
	{
		position = FlxDestroyUtil.put(position);
		offsets = FlxDestroyUtil.put(offsets);
		FlxDestroyUtil.destroy(_onCPUControlToggle);
		_onCPUControlToggle = null;
		FlxDestroyUtil.destroy(_onDownScrollToggle);
		_onDownScrollToggle = null;
		if (drawMembers != null)
		{
			drawMembers.resize(0);
			drawMembers = null;
		}
		super.destroy();
	}
}
