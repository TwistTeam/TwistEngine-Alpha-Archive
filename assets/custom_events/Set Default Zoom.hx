using StringTools;
using game.backend.utils.CoolUtil;

var _tweens:Map<Int, FlxTween> = [];
var _defaultZoom:Float;
static function isValidStr(str)
	return str != null && str.trim().length > 0;
function onCreatePost()
{
	_defaultZoom = defaultCamZoom;
}
function onEvent(name, value1, value2, value3){
    switch(name){
		case 'Set Default Zoom':
			var addedZoom:Float = Std.parseFloat(value1 ?? "").getDefault(0);
			var curDefZoom:Float;
			var defaultZoom:Float;
			var camera:FlxCamera;
			var funcTransition;
			switch ((value3 ?? "").toLowerCase().trim()) {
				case "camhud":
					camera = camHUD;
					defaultZoom = 1;
					curDefZoom = defaultCamHUDZoom;
					// funcTransition = camZooming ? i -> defaultCamHUDZoom = i : i -> camera.zoom = defaultCamHUDZoom = i;
					funcTransition = i -> camera.zoom = defaultCamHUDZoom = i;
				default:
					camera = camGame;
					defaultZoom = _defaultZoom;
					curDefZoom = defaultCamZoom;
					// funcTransition = camZooming ? i -> defaultCamZoom = i : i -> camera.zoom = defaultCamZoom = i;
					funcTransition = i -> camera.zoom = defaultCamZoom = i;
			}
			if (_tweens[camera.ID] != null)
			{
				_tweens[camera.ID].cancel();
				_tweens[camera.ID] = null;
			}

			var params:Array<String> = value2.split(",");
			var promoTime:Null<Float> = Std.parseFloat(params[0]).getDefault(null);
			var promoTime2:Null<Float> = Std.parseFloat(params[1] ?? "").getDefault(null);
			var time:Float = promoTime ?? promoTime2 ?? 0.5;

			if (time > 0)
			{
				var easeStr:String = (promoTime == null ? params[0] : null).getDefault(
					promoTime2 == null ? params[1] : null
				);
				if (easeStr == null || (easeStr = easeStr.trim()).length == 0)
					easeStr = "cubeout";
				easeStr = easeStr.toLowerCase().replace("outin", "inout");
				if (easeStr != "linear" && !easeStr.endsWith("out") && !easeStr.endsWith("in"))
					easeStr = easeStr + "out"; // auto set Out on "circ", "expo", "cube" or same

				_tweens[camera.ID] = FlxTween.num(curDefZoom, defaultZoom + addedZoom, time,
					{ease: easeStr.getFlxEaseByString(), onComplete: _ -> _tweens[camera.ID] = null}, funcTransition);
			}
			else
			{
				funcTransition(defaultZoom + addedZoom);
			}
    }
}