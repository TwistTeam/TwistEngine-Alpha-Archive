package game.objects.ui;

import lime.ui.MouseCursor;
import flixel.math.FlxPoint;
import flixel.math.FlxMath;
import flixel.util.helpers.FlxBounds;
import flixel.math.FlxRect;
import flixel.util.FlxDestroyUtil;
import flixel.group.FlxSpriteGroup;
import game.objects.ui.Box;

class Window extends FlxSpriteGroup implements UIInterface
{
	public var canSelected:Bool = true;
	public var selected(get, set):Bool;

	inline function get_selected()
		return _selectedWindow == this;

	inline function set_selected(e)
	{
		_selectedWindow = e ? this : null;
		return e;
	}

	public var inUIState:Bool = UIState.instance != null;

	public var bg:SliceSprite;
	public var titleText:FlxStaticText;
	public var theme:Box;
	public var offsetSizes:FlxRect;

	public var resizable:Bool = true;
	public var boundsWidth:FlxBounds<Int>;
	public var boundsHeight:FlxBounds<Int>;

	public var onChangeWidth:Int->Void;
	public var onChangeHeight:Int->Void;

	public function new(title:String = 'Title', x:Float = 0, y:Float = 0, ?width:Int = 400, ?height:Int = 400)
	{
		theme = new Box(x, y, width, height);
		theme.renderCamera.bgColor = 0xff000000;
		bg = new SliceSprite(0, 0, width, height, 'ui/context-bg');
		titleText = new FlxStaticText(4, 2, 0, title, 14);
		bg.offset.y -= 10;
		offsetSizes = FlxRect.get(7, 20, 7, 7);
		boundsWidth = new FlxBounds<Int>(Math.round(titleText.x * 2 + titleText.width - offsetSizes.x), FlxMath.MAX_VALUE_INT);
		boundsHeight = new FlxBounds<Int>(50, FlxMath.MAX_VALUE_INT);
		super(x, y);
		super.add(bg);
		super.add(titleText);
		theme.addSelf();
		this.width = width;
		this.height = height;
	}

	public override function draw()
	{
		bg.draw();
		titleText.draw();
		theme.draw();
	}

	var _mousePoint = FlxPoint.get();
	var _objPoint = FlxPoint.get();
	var _oldRect = FlxRect.get();
	var _dragMousePoint = FlxPoint.get();

	public var isResizing(default, null):Direction;

	static var _selectedWindow:Window;

	function _updateMousePos()
	{
		FlxG.mouse.getScreenPosition(camera, _mousePoint);
		getScreenPosition(_objPoint, camera);
	}

	@:noCompletion function intHas(thisInt:Int, needInt:Int)
		return thisInt & needInt == needInt;

	var _cursor:MouseCursor = lime.ui.MouseCursor.DEFAULT;

	public override function update(elapsed:Float)
	{
		if (canSelected)
			if (FlxG.mouse.justPressed)
			{
				_updateMousePos();

				selected = FlxMath.pointInCoordinates(_mousePoint.x, _mousePoint.y, _objPoint.x, _objPoint.y, width, height)
					&& !FlxMath.pointInCoordinates(_mousePoint.x, _mousePoint.y, _objPoint.x + offsetSizes.x, _objPoint.y + offsetSizes.y, theme.width,
						theme.height);
				_oldRect.set(x, y, width, height);
				_dragMousePoint.copyFrom(_mousePoint);
				isResizing = 0x0000;
				if (selected)
				{
					final pos = FlxPoint.get(_mousePoint.x - _objPoint.x, _mousePoint.y - _objPoint.y);
					if (!FlxMath.inBounds(pos.x, 8, width - 8))
						isResizing |= pos.x - width / 2 > 0 ? Direction.LEFT : Direction.RIGHT;
					if (!FlxMath.inBounds(pos.y, 8, height - 8))
						isResizing |= pos.y - height / 2 > 0 ? Direction.DOWN : Direction.UP;
					// trace([isResizing.toString()]);

					if (FlxG.mouse.useSystemCursor)
					{
						final right = isResizing.has(Direction.RIGHT);
						final left = isResizing.has(Direction.LEFT);
						final up = isResizing.has(Direction.UP);
						final down = isResizing.has(Direction.DOWN);
						if ((right && up) || (left && down))
							_cursor = lime.ui.MouseCursor.RESIZE_NWSE;
						else if ((right && down) || (left && up))
							_cursor = lime.ui.MouseCursor.RESIZE_NESW;
						else if (right || left)
							_cursor = lime.ui.MouseCursor.RESIZE_WE;
						else if (up || down)
							_cursor = lime.ui.MouseCursor.RESIZE_NS;
					}

					pos.put();
				}
			}
			else if (FlxG.mouse.justReleased)
			{
				if (selected)
					_cursor = lime.ui.MouseCursor.DEFAULT;
				selected = false;
			}
			else
				_updateMousePos();
		else
			selected = false;

		game.backend.system.CursorManager.instance.cursor = _cursor;
		if (selected)
		{
			if (isResizing == 0)
			{
				x = _oldRect.x + _mousePoint.x - _dragMousePoint.x;
				y = _oldRect.y + _mousePoint.y - _dragMousePoint.y;
			}
			else if (resizable)
			{
				_updateMousePos();
				if (isResizing.has(Direction.UP))
				{
					y = _oldRect.y + Math.min(_oldRect.height - boundsHeight.min, _mousePoint.y - _dragMousePoint.y);
					height = _oldRect.height - y + _oldRect.y;
				}
				if (isResizing.has(Direction.RIGHT))
				{
					x = _oldRect.x + Math.min(_oldRect.width - boundsWidth.min, _mousePoint.x - _dragMousePoint.x);
					width = _oldRect.width - x + _oldRect.x;
				}
				if (isResizing.has(Direction.LEFT))
				{
					// x = _oldRect.x;
					width = _oldRect.width + (_mousePoint.x - _dragMousePoint.x);
				}
				if (isResizing.has(Direction.DOWN))
				{
					// y = _oldRect.y;
					height = _oldRect.height + (_mousePoint.y - _dragMousePoint.y);
				}
			}
		}
		bg.update(elapsed);
		titleText.update(elapsed);
		theme.update(elapsed);
	}

	public override function destroy()
	{
		FlxDestroyUtil.putArray([offsetSizes, _mousePoint, _objPoint, _oldRect, _dragMousePoint]);
		theme = FlxDestroyUtil.destroy(theme);
		bg = null;
		titleText = null;
		super.destroy();
	}

	@:noCompletion
	override function set_x(e):Float
	{
		e = FlxMath.bound(e, 0, FlxG.width - width);
		super.set_x(e);
		theme.x = x + offsetSizes.x;
		return e;
	}

	@:noCompletion
	override function set_y(e):Float
	{
		e = FlxMath.bound(e, 0, FlxG.height - height);
		super.set_y(e);
		theme.y = y + offsetSizes.y;
		return e;
	}

	@:noCompletion
	override function set_width(e):Float
	{
		var old = theme.width;
		final e:Int = Std.int(FlxMath.bound(e, boundsWidth.min, Math.min(boundsWidth.max, FlxG.width - x)));
		super.set_width(e);
		theme.width = e - Std.int(offsetSizes.width + offsetSizes.x);
		bg.bWidth = e;
		if (old != theme.width && onChangeWidth != null)
			onChangeWidth(theme.width);
		return e;
	}

	@:noCompletion
	override function set_height(e):Float
	{
		var old = theme.height;
		final e:Int = Std.int(FlxMath.bound(e, boundsHeight.min, Math.min(boundsHeight.max, FlxG.height - y)));
		super.set_height(e);
		theme.height = e - Std.int(offsetSizes.height + offsetSizes.y);
		bg.bHeight = e;
		if (old != theme.height && onChangeHeight != null)
			onChangeHeight(theme.height);
		return e;
	}

	@:noCompletion
	override function get_width():Float
		return bg.bWidth;

	@:noCompletion
	override function get_height():Float
		return bg.bHeight;
}

private enum abstract Direction(UShort) from UShort to UShort
{
	var LEFT = 0x0001;
	var RIGHT = 0x0010;
	var UP = 0x0100;
	var DOWN = 0x1000;

	public function has(haveDir:Direction)
		return this & haveDir == haveDir;

	public function toString()
	{
		var str = new Array<String>();
		var dir:Direction = cast this;
		if (dir.has(LEFT))
			str.push("L");
		if (dir.has(RIGHT))
			str.push("R");
		if (dir.has(UP))
			str.push("U");
		if (dir.has(DOWN))
			str.push("D");
		return str.join(' | ');
	}
}
