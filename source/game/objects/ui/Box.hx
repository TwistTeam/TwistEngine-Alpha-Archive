package game.objects.ui;

import flixel.FlxCamera;
import flixel.util.FlxDestroyUtil;
import flixel.group.FlxGroup;

class Box extends FlxGroup {
	public var parentCamera:FlxCamera = FlxG.camera;
	public var renderCamera:FlxCamera;
	public var width(default, set):Int;
	public var height(default, set):Int;
	public var x(default, set):Float;
	public var y(default, set):Float;
	public function new(x:Float = 0, y:Float = 0, ?width:Int = 400, ?height:Int = 400){
		super();
		renderCamera = new FlxCamera(x, y, width, height);
		// renderCamera.bgColor = 0xff000000;
		renderCamera.bgColor = 0x71000000;
		this.x = x;
		this.y = y;
		this.width = width;
		this.height = height;
	}
	public override function destroy(){
		if (FlxG.cameras.list.indexOf(renderCamera) != -1)
			FlxG.cameras.remove(renderCamera, false);
		renderCamera = FlxDestroyUtil.destroy(renderCamera);
		parentCamera = null;
		super.destroy();
	}
	public function addSelf(){
		FlxG.cameras.add(renderCamera, false);
		return this;
	}
	public function removeSelf(?destroy:Bool = false){
		FlxG.cameras.remove(renderCamera, destroy);
		return this;
	}
	public override function update(elapsed:Float){
		if (parentCamera != null){
			renderCamera.visible = parentCamera.visible && visible;
			renderCamera.alpha = parentCamera.alpha;
		}
		super.update(elapsed);
	}

	@:noCompletion
	function set_x(e):Float		 return renderCamera.x = x = e;
	@:noCompletion
	function set_y(e):Float		 return renderCamera.y = y = e;
	@:noCompletion
	function set_width(e):Int	 return renderCamera.width = width = e;
	@:noCompletion
	function set_height(e):Int	 return renderCamera.height = height = e;

	@:noCompletion
	override function get_camera():FlxCamera return renderCamera;
	@:noCompletion
	override function get_cameras():Array<FlxCamera> return [renderCamera];
}