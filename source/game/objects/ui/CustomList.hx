package game.objects.ui;

import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.util.FlxDestroyUtil;
import flixel.util.FlxSort;

import game.backend.system.CursorManager;
import game.backend.utils.FlxCameraUtil;

import openfl.geom.Rectangle;

class LayersList extends CustomList
{
	var mapYShits:Map<FlxSprite, Float> = new Map<FlxSprite, Float>();
	var curObj:FlxSprite;

	public function new(x:Int = 0, y:Int = 0, ?width:Int = 100, ?height:Int = 200, ?_members:Array<FlxSprite>)
	{
		super(x, y, width, height, _members, false);
		snapPos();
	}

	public function snapPos()
	{
		_members.forEach(obj ->
		{
			obj.y = lastPos;
			mapYShits.set(obj, obj.y);
			lastPos += obj.height + 4;
		});
		lastPos = 0;
		updateHeightScroll();
	}

	public override function sort()
	{
		if (curObj == null)
		{
			super.sort();
			return;
		}
		final lastCurPos = _members.members.indexOf(curObj);
		super.sort();
		// if (_members.length > 0) _members.sort(function(o, a:FlxSprite, b:FlxSprite) return FlxSort.byValues(o, a.y, b.y), -1);
		final cuurPos = _members.members.indexOf(curObj);
		if (lastCurPos != cuurPos)
			onChangeLayer(curObj, cuurPos);
	}

	public var onChangeLayer:FlxSprite->Int->Void;

	override function mouseFunc()
	{
		if (curObj == null)
		{
			if (FlxG.mouse.pressedMiddle)
			{
				if (FlxG.mouse.justPressedMiddle)
					FlxG.mouse.getScreenPosition(this, lastMousePoint);
				scrollFloat -= (lastMousePoint.y - mousePoint.y) * FlxG.elapsed * 2;
				crack = true;
				CursorManager.instance.cursor = 'resize_ns';
			}
			else if (FlxG.mouse.pressed)
			{
				if (FlxG.mouse.justPressed)
					if (curObj == null)
						for (i in 0..._members.length)
						{
							final obj = _members.members[_members.length - 1 - i];
							if (overlapLayer(obj))
							{
								curObj = obj;
								break;
							}
						}
				// trace('drag');
				if (curObj == null)
				{
					scrollFloat -= FlxG.mouse.deltaY * FlxG.camera.zoom / 2;
				}
				crack = true;
				CursorManager.instance.cursor = 'resize_ns';
			}
			else
			{
				crack = false;
				scrollFloat -= FlxG.mouse.wheel * 7;
				CursorManager.instance.cursor = null;
			}
		}
		else
		{
			// if(FlxG.mouse.justPressed) FlxG.mouse.getScreenPosition(this, lastMousePoint);
			// if (FlxG.mouse.deltaY != 0){
			final up = Math.min((height - 100) - mousePoint.y, 0) / 20;
			final down = Math.min(mousePoint.y - 100, 0) / 20;
			scrollFloat -= up;
			scrollFloat += down;
			mapYShits.set(curObj, (curObj.y = (mousePoint.y + scroll.y - curObj.height / 2)));
			// + up - down
			// }
			// curObj.y = CoolUtil.fpsLerpOut(curObj.y, mapYShits.get(curObj), 0.5);
			sort();
		}
	}

	var lastPos:Float = 0;

	public override function update(e)
	{
		super.update(e);
		_members.forEach(obj ->
		{
			if (curObj == obj)
			{
				lastPos += (obj.height + 4);
			}
			else
			{
				mapYShits.set(obj, lastPos);
				lastPos = obj.y + (obj.height + 4);
				obj.y = CoolUtil.fpsLerp(obj.y, mapYShits.get(obj), 0.5);
			}
		});
		lastPos = 0;
	}

	public override function add(e, upd = false)
	{
		super.add(e, upd);
		mapYShits.set(e, maxScrollY - outView);
	}

	public override function insert(newVal:FlxSprite, position:Int, update:Bool = false)
	{
		super.insert(newVal, position, update);
		mapYShits.set(newVal, 0);
	}

	public override function remove(e, upd = false)
	{
		super.remove(e, upd);
		mapYShits.remove(e);
	}

	public override function clear(?update:Bool = false, ?destroy:Bool = true)
	{
		super.clear(update, destroy);
		mapYShits.clear();
	}

	override function mouseFuncRelease()
	{
		final rightReleased = FlxG.mouse.justReleased;
		if (rightReleased || FlxG.mouse.justReleasedMiddle)
		{
			pMidd = false;
			pLeft = false;
			if (rightReleased && curObj != null)
			{
				curObj = null;
				crack = false;
				if (objOnRelease != null)
					objOnRelease();
			}
			CursorManager.instance.cursor = null;
		}
	}

	public override function updateHeightScroll()
	{
		minScrollY = minScrollX = -outView;
		scroll.x = -width / 2 - outView;
		sort();
		if (_members.length > 0)
		{
			final lastObj = CoolUtil.getLastOfArray(_members.members);
			final dataShit = mapYShits.get(lastObj);
			maxScrollY = Math.max(height, dataShit + lastObj.height) + outView;
		}
		else
		{
			maxScrollY = height + outView;
		}
		// trace('Max: $maxScrollY');
	}

	public var overlapLayer:FlxSprite->Bool = obj ->
	{
		return CoolUtil.mouseOverlapping(obj);
	}

	public var objOnRelease:Void->Void;
}

class ListSlider extends flixel.group.FlxSpriteGroup
{
	var list:CustomList;
	public var canSelected:Bool = true;

	public var bg:FlxSprite;
	public var upper:FlxSprite;
	public var factor(get, set):Float;
	inline function get_factor()
	{
		final a = list.maxScrollY - list.minScrollY;
		return FlxMath.bound(list.scroll.y, 0, a - list.height / 2) / a;
		// return list.scrollFloat;
	}
	inline function set_factor(e:Float)
	{
		final a = list.maxScrollY - list.minScrollY;
		list.scrollFloat = list.scroll.y = FlxMath.bound(a * e, 0, a - list.height / 2);
		trace(list.scrollFloat);
		return list.scrollFloat;
	}
	public var min(get, never):Float;
	inline function get_min()
	{
		return list.minScrollY;
	}
	public var decimals:Int = 1;
	public var variable(get, set):Float;
	inline function get_variable()
	{
		return list.scroll.y;
		// return list.scrollFloat;
	}
	inline function set_variable(e:Float)
	{
		return list.scroll.y = list.scrollFloat = e;
	}

	public var selected:Bool = false;
	public var baseThumbScaleX:Float = 1.6;

	public function new(list:CustomList)
	{
		super();
		this.list = list;
		color = 0xff333333;

		bg = new FlxSprite().makeGraphic(10, list.height, 0xFF181818);
		upper = new FlxSprite().makeGraphic(cast bg.width, list.height, 0xffcccccc);
		add(bg);
		add(upper);

		upper.clipRect = FlxRect.get(0, 0, upper.frameWidth, upper.frameHeight);
		upper.scale.x = baseThumbScaleX;

		forEach(spr -> spr.moves = false);
	}


	public var overlaping:Bool = false;
	public var pressed:Bool = false;
	public var mousePoint:FlxPoint = FlxPoint.get();

	public override function update(elapsed:Float):Void
	{
		if (canSelected)
		{
			if (FlxG.mouse.justReleased && selected && pressed)
			{
				onRelease();
				pressed = false;
			}
			else
			{
				FlxG.mouse.getScreenPosition(camera, mousePoint);
				if (overlaping = CoolUtil.mouseOverlapping(this, mousePoint) || pressed)
				{
					if (pressed || FlxG.mouse.justPressed)
					{
						onPressed();
						pressed = true;
					}
					else
					{
						onSelected();
						pressed = false;
					}
					if (pressed)
					{
						var yPos = Math.floor(
							FlxMath.bound(
								FlxMath.remapToRange(mousePoint.y,
									y, y + height,
									-list.height / 2 + list.minScrollY, list.maxScrollY - list.height / 2
								),
								list.minScrollY, list.maxScrollY
							)
						);
						if (variable != yPos/* && yPos >= list.minScrollY && yPos <= list.maxScrollY*/) {
							variable = yPos;
						}
					}
				}
				else
				{
					onStatic();
					pressed = false;
				}
			}
		}
		var size = Math.ffloor(upper.frameHeight * list.height / (list.maxScrollY - list.minScrollY));
		upper.clipRect.set(0,
			Math.ffloor(
				FlxMath.bound(
					FlxMath.remapToRange(variable, list.minScrollY, list.maxScrollY, 0, upper.frameHeight),
					-size / 2, upper.frameHeight - size
				)
			),
			upper.frameWidth, size);
		// upper.clipRect.y = FlxMath.bound(upper.clipRect.y - upper.clipRect.height / 2, 0, upper.height - upper.clipRect.height);
		// @:bypassAccessor upper.clipRect = upper.clipRect; // :)
		super.update(elapsed);
	}

	public function onSelected()
	{
		selected = true;
		color = 0xffffffff;
		upper.scale.x = baseThumbScaleX * 1.25;
	}

	public function onStatic()
	{
		selected = false;
		color = 0xffbbbbbb;
		upper.scale.x = baseThumbScaleX;
	}

	public function onRelease()
	{
		onSelected();
		selected = false;
		upper.scale.x = baseThumbScaleX;
	}

	public function onPressed()
	{
		selected = true;
		color = 0xffdadada;
		upper.scale.x = baseThumbScaleX * 1.1;
	}

	public override function destroy()
	{
		mousePoint = FlxDestroyUtil.put(mousePoint);
		upper.clipRect = FlxDestroyUtil.put(upper.clipRect);
		super.destroy();
	}
}

class CustomList extends FlxCamera
{
	public var parentCamera:flixel.FlxCamera = FlxG.camera;
	public var _members:FlxTypedGroup<FlxSprite>;
	public var slider:ListSlider;
	public var outView:Int = 4;

	public function new(x:Int = 0, y:Int = 0, ?width:Int = 100, ?height:Int = 200, ?members:Array<FlxSprite>, ?enableSlider:Bool = false)
	{
		super(x, y, width, height);
		// bgColor = 0xff000000;
		bgColor = 0x71000000;
		// antialiasing = ClientPrefs.globalAntialiasing;
		// bgColor.alpha = 0;
		_members = new FlxTypedGroup<FlxSprite>();
		_members.camera = this;
		if (enableSlider)
		{
			slider = new ListSlider(this);
			slider.x = width - slider.width - 8;
			slider.scrollFactor.set();
			slider.camera = this;
		}
		if (members != null)
			for (i in members)
				add(i);

		updateHeightScroll();
		FlxG.cameras.add(this, false);

		useBoundsClipping = true;
	}

	public function add(newVal:FlxSprite, update:Bool = false)
	{
		// newVal.antialiasing = ClientPrefs.globalAntialiasing;
		newVal.camera = this;
		_members.add(newVal);
		if (update)
			updateHeightScroll();
	}

	public function insert(newVal:FlxSprite, position:Int, update:Bool = false)
	{
		_members.insert(position, newVal);
		if (update)
			updateHeightScroll();
	}

	public function remove(newVal:FlxSprite, update:Bool = false)
	{
		newVal.destroy();
		_members.remove(newVal, true);
		if (update)
			updateHeightScroll();
	}

	public function clear(?update:Bool = false, ?destroy:Bool = true)
	{
		if (destroy)
			_members.forEach(i -> i?.destroy());
		_members.clear();
		if (update)
		{
			updateHeightScroll();
			scrollFloat = scroll.y = maxScrollY;
		}
	}

	public function sort()
		if (_members.length > 0)
			_members.sort(function(o, a:FlxSprite, b:FlxSprite) return FlxSort.byValues(o, a.y, b.y), -1);

	public function updateHeightScroll()
	{
		minScrollY = minScrollX = -outView;
		scroll.x = -width / 2 - outView;
		sort();
		if (_members.length > 0)
		{
			final lastObj = CoolUtil.getLastOfArray(_members.members);
			maxScrollY = Math.max(height, lastObj.y + lastObj.height) + outView;
		}
		else
			maxScrollY = height + outView;
		// trace('Max: $maxScrollY');
	}

	public var scrollFloat:Float = 0.;
	public var inBoxMouse(default, null):Bool;
	public var lastMousePoint:FlxPoint = FlxPoint.get();
	public var mousePoint:FlxPoint = FlxPoint.get();
	public var canDrag:Bool = true;
	public var crack(default, null):Bool = false;

	public override function update(elapsed:Float)
	{
		// scroll.x = -width/2;
		if (parentCamera != null)
		{
			visible = parentCamera.visible;
			alpha = parentCamera.alpha;
		}

		if (visible && alpha != 0 && canDrag && (slider == null || !slider.overlaping))
		{
			if (checkPos() || crack)
			{
				mouseFunc();
				scrollFloat = CoolUtil.boundTo(scrollFloat, minScrollY, maxScrollY - height);
			}
		}
		mouseFuncRelease();
		scroll.y = CoolUtil.fpsLerp(scroll.y, scrollFloat, 0.1);

		_members.update(elapsed);
		slider?.update(elapsed);

		super.update(elapsed);
		// trace(scroll.toString());
	}

	public function checkPos():Bool
	{
		FlxG.mouse.getScreenPosition(this, mousePoint);
		return inBoxMouse = (mousePoint.x >= 0 && mousePoint.x <= width && mousePoint.y >= 0 && mousePoint.y <= height);
	}

	var pMidd:Bool;
	var pLeft:Bool;
	function mouseFunc()
	{
		if (pMidd || FlxG.mouse.justPressedMiddle)
		{
			if (!pMidd)
				FlxG.mouse.getScreenPosition(this, lastMousePoint);
			scrollFloat -= (lastMousePoint.y - mousePoint.y) * FlxG.elapsed * 3;
			crack = true;
			pMidd = true;
			CursorManager.instance.cursor = 'resize_ns';
		}
		else if (pLeft || FlxG.mouse.justPressed)
		{
			scrollFloat -= FlxG.mouse.deltaY * FlxG.camera.zoom / 2;
			pLeft = true;
			crack = true;
			CursorManager.instance.cursor = 'resize_ns';
		}
		else
		{
			pLeft = false;
			pMidd = false;
			crack = false;
			scrollFloat -= FlxG.mouse.wheel * 28;
			CursorManager.instance.cursor = null;
		}
	}

	function mouseFuncRelease()
	{
		if (FlxG.mouse.justReleased || FlxG.mouse.justReleasedMiddle)
		{
			pMidd = false;
			pLeft = false;
			CursorManager.instance.cursor = null;
		}
	}

	override function render()
	{
		_members.draw();
		slider?.draw();
		super.render();
	}
	public override function destroy()
	{
		clear();

		if (FlxG.cameras.list.contains(this))
			FlxG.cameras.remove(this, false);

		_members = FlxDestroyUtil.destroy(_members);
		slider = FlxDestroyUtil.destroy(slider);

		FlxDestroyUtil.putArray([lastMousePoint, mousePoint]);

		super.destroy();
	}
}
