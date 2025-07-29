package game.backend.system;

import flixel.util.FlxDestroyUtil.IFlxDestroyable;
import flixel.util.FlxSignal.FlxTypedSignal;
import openfl.Vector;

class UndoRedo<T> implements IFlxDestroyable
{
	public var undoList(default, null):Vector<T>;
	public var redoList(default, null):Vector<T>;

	public var onUndo:FlxTypedSignal<T->Void>;
	public var onRedo:FlxTypedSignal<T->Void>;

	var maxLength:Int = 100;
	var savedLength:Int = 0;

	public var isSaved(get, never):Bool;

	inline function get_isSaved():Bool
		return undoList.length == savedLength;

	public function new(?maxLen:Null<Int>)
	{
		undoList = new Vector<T>();
		redoList = new Vector<T>();
		onUndo = new FlxTypedSignal<T->Void>();
		onRedo = new FlxTypedSignal<T->Void>();
		if (maxLen != null)
			maxLength = maxLen;
	}

	public function reset()
	{
		redoList.length = 0;
		undoList.length = 0;
		// redoList.splice(0, redoList.length);
		// undoList.splice(0, undoList.length);
	}

	public function addUndo(a:T)
	{
		redoList.length = 0;
		// redoList.splice(0, redoList.length);
		undoList.push(a);
		while (undoList.length > maxLength)
			undoList.shift();
	}

	public function undo():T
	{
		var undo = undoList.pop();
		if (undo != null)
		{
			redoList.push(undo);
			onUndo.dispatch(undo);
		}
		return undo;
	}

	public function redo():T
	{
		var redo = redoList.pop();
		if (redo != null)
		{
			undoList.push(redo);
			onRedo.dispatch(redo);
		}
		return redo;
	}

	public function save()
		savedLength = undoList.length;

	public function destroy()
	{
		redoList.length = 0;
		undoList.length = 0;
		// undoList.splice(0, undoList.length);
		// redoList.splice(0, redoList.length);
		onUndo.destroy();
		onRedo.destroy();
		onUndo = null;
		onRedo = null;
	}
}
