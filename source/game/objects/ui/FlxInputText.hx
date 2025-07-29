package game.objects.ui;

import flixel.graphics.frames.FlxFrame;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxPoint;
import flixel.util.FlxDestroyUtil;
import flixel.util.FlxSignal;
import flixel.util.helpers.FlxRange;
import game.backend.system.CursorManager;
import game.backend.system.UndoRedo;
import game.objects.improvedFlixel.FlxFixedText;
import haxe.extern.EitherType;
import lime.ui.KeyCode;
import lime.ui.KeyModifier;
import openfl.desktop.Clipboard;
import openfl.geom.Rectangle;

private abstract UndoInputText(Array<EitherType<String, Int>>) from Array<EitherType<String, Int>> to Array<EitherType<String, Int>>
{
	public inline function new(str:String, pos:Int, start:Int, end:Int)
	{
		this = [str, pos, start, end];
	}

	public var str(get, never):String;

	inline function get_str()
		return this[0];

	public var pos(get, never):Int;

	inline function get_pos()
		return this[1];

	public var startPos(get, never):Int;

	inline function get_startPos()
		return this[2];

	public var endPos(get, never):Int;

	inline function get_endPos()
		return this[3];
}

/** TODO:
 *  Undo / redo
 *  Multi-selection
 */
@:access(openfl.text.TextField)
@:access(openfl.geom.Rectangle)
@:allow(game.objects.ui.UIState)
class FlxInputText extends FlxFixedText implements UIInterface implements IUIFocusable
{
	public var canSelected:Bool = true;
	public var selected(default, set):Bool = false;

	inline function set_selected(e:Bool):Bool
	{
		if (e != selected)
		{
			if (inUIState)
				UIState.instance.currentFocus = e ? this : null;
			selected = e;
			// if (!selected) undoData.reset();
		}
		return e;
	}

	public var hovered:Bool = false;
	public var inUIState:Bool = UIState.instance != null;

	public var allowUndo:Bool = true;
	public var wrapInputIndex:Bool = false;
	public var speedAnimCaret:Float = 1;
	public var smoothCaretAnim:Bool = true;
	public var maxDoubleClickDelay:Int = 500;

	public var passwordMode(get, set):Bool;

	function get_passwordMode():Bool
		return textField.displayAsPassword;

	function set_passwordMode(value:Bool):Bool
	{
		if (textField.displayAsPassword != value)
		{
			textField.displayAsPassword = value;
			calcFrame();
		}
		return value;
	}


	public var caretSpr:FlxSprite;

	public var undoData:UndoRedo<UndoInputText>;

	var focused:Bool = false;

	public var multiSelectMode(get, set):Bool;

	inline function get_multiSelectMode():Bool
	{
		return selectedRange.active;
	}

	inline function set_multiSelectMode(e:Bool):Bool
	{
		selectedRange.active = e;
		return e;
	}

	public var selectedBG:FlxSprite;

	public var selectedRange(default, null):FlxRange<Int>;

	var _lastSelectedRange(default, null):FlxRange<Int>;

	var selectedStartRect:Rectangle;
	var selectedEndRect:Rectangle;

	function updateSelectedRangeSprs()
	{
		if (text == '' && selectedRange.start <= 0)
		{
			selectedStartRect.setEmpty();
			selectedEndRect.setEmpty();
		}
		else
		{
			textField.__updateLayout();
			function cook(rect:Rectangle, position:Int)
			{
				rect.setEmpty();
				for (group in textField.__textEngine.layoutGroups)
				{
					if (position >= group.startIndex && position <= group.endIndex)
					{
						try
						{
							var x = group.offsetX;

							for (i in 0...(position - group.startIndex))
							{
								x += group.getAdvance(i);
							}

							// TODO: Is this actually right for combining characters?
							var lastPosition = group.getAdvance(position - group.startIndex);

							rect.setTo(x, group.offsetY, lastPosition, group.ascent + group.descent);
							break;
						}
						catch (e:Dynamic)
						{
							Log(e, RED);
						}
					}
				}
				if (position >= text.length)
					rect.x += rect.width;
			}
			cook(selectedStartRect, selectedRange.start);
			cook(selectedEndRect, selectedRange.end);
		}
	}

	public var position(default, set):Int = 0;

	function set_position(e:Int):Int
	{
		if (e != position)
		{
			position = e;
			updateCaretSprPos();
		}
		return e;
	}

	function updateCaretSprPos()
	{
		if (text == '' && position <= 0)
		{
			curCharRect.setEmpty();
		}
		else
		{
			curCharRect.setEmpty();
			textField.__updateLayout();

			for (group in textField.__textEngine.layoutGroups)
			{
				if (position >= group.startIndex && position <= group.endIndex)
				{
					try
					{
						var x = group.offsetX;

						for (i in 0...(position - group.startIndex))
						{
							x += group.getAdvance(i);
						}

						// TODO: Is this actually right for combining characters?
						var lastPosition = group.getAdvance(position - group.startIndex);

						curCharRect.setTo(x, group.offsetY, lastPosition, group.ascent + group.descent);
						break;
					}
					catch (e:Dynamic)
					{
						Log(e, RED);
					}
				}
			}

			if (position >= text.length)
				curCharRect.x += curCharRect.width;
		}
	}

	public var onDoubleClick:FlxSignal;
	public var onChangeText:FlxTypedSignal<String->Void>;
	public var onFocus:FlxTypedSignal<Bool->Void>;

	public function new(X:Float = 0, Y:Float = 0, FieldWidth:Float = 0, ?Text:String, Size:Int = 8, EmbeddedFont:Bool = true, ?bgColor:FlxColor)
	{
		super(X, Y, FieldWidth, Text, Size, EmbeddedFont);

		moves = false;
		selectedRange = new FlxRange<Int>(-1);
		_lastSelectedRange = new FlxRange<Int>(-1);
		_lastSelectedRange.active = false;
		multiSelectMode = false;

		onDoubleClick = new FlxSignal();
		onChangeText = new FlxTypedSignal<String->Void>();
		onFocus = new FlxTypedSignal<Bool->Void>();

		caretSpr = new FlxSprite(X, Y);
		caretSpr.makeGraphic(1, 1, -1);
		caretSpr.scale.set(2, size * 1.4);
		caretSpr.updateHitbox();
		selectedBG = new FlxSprite(X, Y);
		selectedBG.makeGraphic(1, 1, -1);
		selectedBG.scale.set(2, size * 1.4);
		selectedBG.updateHitbox();
		selectedBG.color = 0xFF000000;

		curCharRect = Rectangle.__pool.get();
		selectedStartRect = Rectangle.__pool.get();
		selectedEndRect = Rectangle.__pool.get();
		casheMousePos = FlxPoint.get();
		if (!inUIState)
		{
			FlxG.stage.window.onKeyDown.add(onKeyDown);
			FlxG.stage.window.onTextInput.add(onTextInput);
		}
		position = 0;

		undoData = new UndoRedo<UndoInputText>();
		var func = (a:UndoInputText) ->
		{
			text = a.str;
			position = a.pos;
			_lastSelectedRange.start = selectedRange.start = a.startPos;
			_lastSelectedRange.end = selectedRange.end = a.endPos;
			multiSelectMode = selectedRange.start != selectedRange.end;
			onChangeText.dispatch(text);
			// trace(selectedRange);
		}
		undoData.onUndo.add(func);
		undoData.onRedo.add(func);
	}

	override function set_size(e:Int)
	{
		if (caretSpr != null)
		{
			caretSpr.scale.set(2, e * 1.4);
			caretSpr.updateHitbox();
		}
		return super.set_size(e);
	}

	var curCharRect:Rectangle;
	var casheMousePos:FlxPoint;
	var mouseClickedTime:Int = -1;

	public override function update(elapsed:Float)
	{
		if (canSelected)
		{
			hovered = this.mouseOverlapping();

			if (hovered && FlxG.mouse.justPressed)
				if (FlxG.game.ticks - mouseClickedTime <= maxDoubleClickDelay)
				{
					_lastSelectedRange.start = selectedRange.start = position;
					_lastSelectedRange.end = selectedRange.end = position;
					_lastSelectedRange.active = true;
					multiSelectMode = true;
					onDoubleClick.dispatch();
					CursorManager.instance.cursor = "ibeam";
					updateSelectedRangeSprs();
				}
				else
					multiSelectMode = false;

			if (multiSelectMode && FlxG.mouse.justMoved)
			{
				if (_lastSelectedRange.active)
				{
					var pos = FlxG.mouse.getScreenPosition(cameras[0], casheMousePos);
					pos.x -= this.x;
					pos.y -= this.y;
					var index = 0;
					if (pos.x >= 0)
					{
						var pos = textField.getCharIndexAtPoint(pos.x, pos.y);
						index = pos == -1 ? text.length : pos;
					}
					position = index;
					selectedRange.start = Std.int(Math.min(_lastSelectedRange.start, index));
					selectedRange.end = Std.int(Math.max(_lastSelectedRange.end, index));
					updateSelectedRangeSprs();
					selected = true;
					// trace('$_lastSelectedRange -> $selectedRange');
					CursorManager.instance.cursor = "ibeam";
				}
			}
			if (FlxG.mouse.justReleased)
			{
				// trace(selectedRange);
				mouseClickedTime = FlxG.game.ticks;
				if ((hovered || _lastSelectedRange.active) && cameras.length > 0)
				{
					var pos = FlxG.mouse.getScreenPosition(cameras[0], casheMousePos);
					pos.x -= this.x;
					pos.y -= this.y;
					// get caret pos
					if (pos.x < 0)
						position = 0;
					else
					{
						var index = textField.getCharIndexAtPoint(pos.x, pos.y);
						position = index == -1 ? text.length : index;
					}
					selected = true;
				}
				else
					selected = false;

				if (_lastSelectedRange.active)
				{
					if (multiSelectMode = selectedRange.start != selectedRange.end)
						updateSelectedRangeSprs();
				}
				_lastSelectedRange.active = false;
				_lastSelectedRange.start = selectedRange.start;
				_lastSelectedRange.end = selectedRange.end;
			}
		}
		else
		{
			selected = false;
		}
		super.update(elapsed);
		selectedBG.visible = false;
		if (selected)
		{
			if (multiSelectMode)
			{
				selectedBG.visible = true;

				final lerpFactor:Float = smoothCaretAnim ? Math.exp(-20 * FlxG.elapsed) : 0;
				selectedBG.followSpr(this,
					FlxMath.lerp(selectedStartRect.x, selectedBG.x - this.x, lerpFactor),
					FlxMath.lerp(selectedStartRect.y - 2, selectedBG.y - this.y, lerpFactor)
				);
				selectedBG.scale.set(
					FlxMath.lerp(selectedEndRect.x - selectedStartRect.x, selectedBG.scale.x, lerpFactor),
					FlxMath.lerp(selectedEndRect.y + selectedEndRect.height - selectedStartRect.y + 8, selectedBG.scale.y, lerpFactor)
				);

				selectedBG.updateHitbox();
			}
			caretSpr.alpha = (FlxG.game.ticks % (666 * speedAnimCaret)) >= 333 * speedAnimCaret ? 1 * alpha : 0;
			if (smoothCaretAnim)
			{
				var lerpFactor = Math.exp(-20 * FlxG.elapsed);
				caretSpr.followSpr(this,
					FlxMath.lerp(curCharRect.x, caretSpr.x - this.x, lerpFactor),
					FlxMath.lerp(curCharRect.y - 4, caretSpr.y - this.y, lerpFactor)
				);
			}
			else
			{
				caretSpr.followSpr(this, curCharRect.x, curCharRect.y - 4);
			}
			if (!focused)
			{
				focused = true;
				onFocus.dispatch(focused);
			}
		}
		else
		{
			if (focused)
			{
				focused = false;
				onFocus.dispatch(focused);
			}
			caretSpr.alpha = 0;
		}
		if (hovered || focused)
			CursorManager.instance.cursor = "ibeam";
	}

	override function draw()
	{
		selectedBG.scrollFactor.copyFrom(this.scrollFactor);
		caretSpr.scrollFactor.copyFrom(this.scrollFactor);
		if (selectedBG.visible)
			selectedBG.draw();
		super.draw();
		caretSpr.draw();
	}

	function filterIntRange(range:FlxRange<Int>)
	{
		if (range.start == -1 && range.end == -1)
			range.start = range.end = position;
		else if (range.start == -1)
			range.start = 0;
		else if (range.end == -1)
			range.end = text.length;
	}

	public function changeSelection(change:Int)
	{
		position = wrapInputIndex ? FlxMath.wrap(position + change, 0, text.length) : Std.int(FlxMath.bound(position + change, 0, text.length));
		return position;
	}

	/*
	var _selectedFrames:Array<FlxFrame>;
	@:access(flixel.graphics.frames.FlxFrame)
	public function updateSelectedText()
	{
		for (i in 0...selectedRange.end - selectedRange.start)
		{
			var frame = _selectedFrames[i];
			if (frame == null) frame = new FlxFrame(FlxG.bitmap.create(1, 1, -1));
			frame.sourceSize.set();
			frame.offset.set();
		}
		for (group in textField.__textEngine.layoutGroups)
		{
			if (selectedRange.start >= group.startIndex && selectedRange.end <= group.endIndex)
			{
				try
				{
					var x = group.offsetX;

					for (i in 0...(position - group.startIndex))
					{
						x += group.getAdvance(i);
					}

					// TODO: Is this actually right for combining characters?
					var lastPosition = group.getAdvance(position - group.startIndex);

					curCharRect.setTo(x, group.offsetY, lastPosition, group.ascent + group.descent);
					break;
				}
				catch (e:Dynamic)
				{
				}
			}
		}
	}
	*/

	public function changeText(Func:Void->Void)
	{
		if (!allowUndo)
		{
			Func();
			return;
		}
		var lastText = text;
		var lastPos = position;
		Func();
		if (lastText != text // dummy!
			|| (undoData.undoList.length > 0
				&& undoData.undoList[undoData.undoList.length - 1].str != text)
				// || (undoData.redoList.length > 0 && undoData.redoList[undoData.redoList.length - 1].str != text)
		)
			undoData.addUndo(new UndoInputText(lastText, lastPos, selectedRange.start, selectedRange.end));
	}

	public function onTextInput(newText:String):Void
	{
		if (selected)
			changeText(() ->
			{
				text = text.substr(0, position) + newText + text.substr(position);
				position += newText.length;
				updateCaretSprPos();
				onChangeText.dispatch(text);
			});
	}

	public function onKeyUp(e:KeyCode, modifier:KeyModifier):Void
	{
	}

	public function onKeyDown(e:KeyCode, modifier:KeyModifier):Void
	{
		if (selected)
			switch (e)
			{
				// case TAB: onTextInput('\t'); // tab doesn't work, sorry!
				case NUMPAD_ENTER | RETURN:
					if (modifier.shiftKey)
						onTextInput('\n');
					else
						selected = false;
				case RIGHT | LEFT:
					changeSelection(e == RIGHT ? 1 : -1);
					if (modifier.shiftKey)
					{
						if (!_lastSelectedRange.active)
						{
							if (!multiSelectMode)
								_lastSelectedRange.start = _lastSelectedRange.end = position;
							multiSelectMode = true;
							filterIntRange(_lastSelectedRange);
							selectedRange.start = Std.int(Math.min(_lastSelectedRange.start, position));
							selectedRange.end = Std.int(Math.max(_lastSelectedRange.start, position));
							// trace(selectedRange);
						}
					}
					else
						multiSelectMode = false;
				case DOWN | UP:
					function getCharIndexAtPoint(x:Float, y:Float):Int
					{
						if (x <= 2 || y <= 0)
							return 0;
						if (x > textField.width + 4 || y > textField.height + 4)
							return text.length;

						textField.__updateLayout();

						x += textField.scrollH;

						for (i in 0...textField.scrollV - 1)
						{
							y += textField.__textEngine.lineHeights[i];
						}

						for (group in textField.__textEngine.layoutGroups)
						{
							if (y >= group.offsetY && y <= group.offsetY + group.height)
							{
								if (group.width == 0
									|| (x >= group.offsetX && x <= group.offsetX + group.width)
									|| x > group.offsetX + group.width)
								{
									var advance = 0.0;

									for (i in 0...group.positions.length)
									{
										advance += group.getAdvance(i);

										if (x <= group.offsetX + advance)
										{
											return group.startIndex + i;
										}
									}

									return group.endIndex;
								}
							}
						}
						return text.length;
					}
					var newPosition = getCharIndexAtPoint(FlxMath.bound(curCharRect.x + size / 2, 0, textField.width),
						curCharRect.y + (e == DOWN ? size * 2 : -size / 2));
					if (modifier.shiftKey)
					{
						if (!_lastSelectedRange.active)
						{
							if (!multiSelectMode)
								_lastSelectedRange.start = _lastSelectedRange.end = position;
							multiSelectMode = true;
							position = newPosition;
							filterIntRange(_lastSelectedRange);
							selectedRange.start = Std.int(Math.min(_lastSelectedRange.start, position));
							selectedRange.end = Std.int(Math.max(_lastSelectedRange.start, position));
							// trace(selectedRange);
						}
					}
					else
					{
						multiSelectMode = false;
						position = newPosition;
					}
				case BACKSPACE:
					changeText(() ->
					{
						if (position > 0)
						{
							if (multiSelectMode)
							{
								filterIntRange(selectedRange);
								text = text.substr(0, selectedRange.start) + text.substr(selectedRange.end);
								@:bypassAccessor position = Std.int(FlxMath.bound(selectedRange.start, 0, text.length));
								multiSelectMode = false;
							}
							else
							{
								text = text.substr(0, position - 1) + text.substr(position);
								@:bypassAccessor position = Std.int(FlxMath.bound(position - 1, 0, text.length));
							}
							updateCaretSprPos();
							onChangeText.dispatch(text);
						}
					});

				case DELETE:
					changeText(() ->
					{
						if (position < text.length)
						{
							if (multiSelectMode)
							{
								filterIntRange(selectedRange);
								text = text.substr(0, selectedRange.start) + text.substr(selectedRange.end);
								@:bypassAccessor position = Std.int(FlxMath.bound(selectedRange.start, 0, text.length));
								multiSelectMode = false;
							}
							else
							{
								text = text.substr(0, position) + text.substr(position + 1);
								@:bypassAccessor position = Std.int(FlxMath.bound(position - 1, 0, text.length));
							}
							updateCaretSprPos();
							onChangeText.dispatch(text);
						}
					});

				case HOME:
					position = 0;
					multiSelectMode = false;
				case END:
					position = text.length;
					multiSelectMode = false;

				case Z if (modifier.ctrlKey && allowUndo):
					undoData.undo();
					multiSelectMode = false;
				case Y if (modifier.ctrlKey && allowUndo):
					undoData.redo();
					multiSelectMode = false;

				case V if (modifier.ctrlKey):
					// paste
					var data:String = Clipboard.generalClipboard.getData(TEXT_FORMAT);
					if (data != null)
					{
						data = data.replace('\t', '  ');
						if (multiSelectMode)
						{
							filterIntRange(selectedRange);
							changeText(() ->
							{
								text = text.substr(0, selectedRange.start) + data + text.substr(selectedRange.end);
								@:bypassAccessor position = Std.int(FlxMath.bound(selectedRange.start + data.length, 0, text.length));
								multiSelectMode = false;
								updateCaretSprPos();
								onChangeText.dispatch(text);
							});
						}
						else
						{
							onTextInput(data);
						}
					}

				case(C | X) if (modifier.ctrlKey):
					// copy
					if (multiSelectMode)
					{
						Clipboard.generalClipboard.setData(TEXT_FORMAT, text.substring(selectedRange.start, selectedRange.end));
						if (e == X)
						{
							changeText(() ->
							{
								text = text.substr(0, selectedRange.start) + text.substr(selectedRange.end);
								multiSelectMode = false;
								@:bypassAccessor position = Std.int(FlxMath.bound(selectedRange.start, 0, text.length));
								updateCaretSprPos();
								onChangeText.dispatch(text);
							});
						}
					}
					else
					{
						Clipboard.generalClipboard.setData(TEXT_FORMAT, text);
					}

				default: // nothing
			}
	}

	// untested, but this should be a fix for if the text wont type
	public function onTextEdit(text:String, start:Int, end:Int):Void
		onTextInput(text);

	public override function destroy()
	{
		if (!inUIState)
		{
			FlxG.stage.window.onKeyDown.remove(onKeyDown);
			FlxG.stage.window.onTextInput.remove(onTextInput);
		}

		casheMousePos = FlxDestroyUtil.put(casheMousePos);
		undoData = FlxDestroyUtil.destroy(undoData);
		if (curCharRect != null)
			Rectangle.__pool.release(curCharRect);
		curCharRect = null;
		if (selectedStartRect != null)
			Rectangle.__pool.release(selectedStartRect);
		selectedStartRect = null;
		if (selectedEndRect != null)
			Rectangle.__pool.release(selectedEndRect);
		selectedEndRect = null;

		onChangeText.destroy();
		onChangeText = null;

		onFocus.destroy();
		onFocus = null;

		onDoubleClick.destroy();
		onDoubleClick = null;

		_lastSelectedRange = null;
		selectedRange = null;

		super.destroy();
	}
}
