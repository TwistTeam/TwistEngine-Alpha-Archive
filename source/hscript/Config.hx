package hscript;

class Config {
	// Runs support for custom classes in these
	public static final ALLOWED_CUSTOM_CLASSES = [
		// TWIST ENGINE
		"game.backend.assets",
		// "game.backend.data",
		"game.backend.system.states",
		"game.backend.audio.EffectSound",
		"game.objects",
		"game.shaders",
		"game.states",

		// OPENFL (hell yea baby)
		"openfl.display.Bitmap",
		"openfl.display.BitmapData",
		"openfl.display.DisplayObject",
		"openfl.display.DisplayObjectContainer",
		"openfl.display.FPS",
		"openfl.display.Sprite",
		"openfl.display.Tile",
		"openfl.display.TileContainer",
		"openfl.display.Tilemap",
		"openfl.display.Tileset",
		"openfl.filters",
		"openfl.geom",
		"openfl.net",
		"openfl.text",

		// sys
		"sys.Http",

		// FLXANIMATE
		"flxanimate.FlxAnimate",

		// FLIXEL
		"flixel",
		// "flixel.tweens",	"flixel.text",		"flixel.sound",		"flixel.path",
		// "flixel.math",		"flixel.group",		"flixel.effects",	"flixel.animation",

		"funkin", // funk.vis && flxpartialsound
		#if away3d "away3d", #end
		#if hxvlc "hxvlc", #end
		"nape"
	];

	// Runs support for abstract support in these
	public static final ALLOWED_ABSTRACT_AND_ENUM = [
		/*
		"game.FPS",
		"game.backend.assets",
		"game.backend.data",
		"game.backend.system",
		"game.objects",
		"game.shaders",
		"game.states",
		*/

		#if away3d "away3d", #end
		"flixel",
		"openfl",

		"flxanimate",
		"format",

		"haxe.xml",
		"haxe.CallStack",
		"nape",
		"funkin", // funk.vis && flxpartialsound
	];

	// Incase any of your files fail
	// These are the module names
	public static final DISALLOW_CUSTOM_CLASSES = [
		// "game.backend.utils",
		// "game.objects.SpectrumWaveform",
		// "game.objects.ui.ColorPickerGroup",
		// "game.objects.ui.CustomList",
		// "game.objects.ui.LayersList",

		"openfl.geom.Matrix3D",
		"openfl.display._internal",
		"flixel.addons.display.FlxShaderMaskCamera",
		"flixel.addons.display.FlxSpriteAniRot",
		"flixel.addons.display.FlxStarField",
		"flixel.addons.display.FlxZoomCamera",
		"flixel.system",
		"flixel.tweens",
		// "flixel.util",
		"flixel.system.macros",
		// "flixel.tile",
		"flixel.input",
		// "flixel.animation.FlxBaseAnimation",
		// "flixel.animation.FlxPrerotatedAnimation",
		// "flixel.effects.particles.FlxParticle",
		// "flixel.text.FlxText",

		"flxanimate.FlxPooledMatrix",
		"flxanimate.FlxPooledCamera",
		#if hl
		"haxe.http",
		"sys.ssl"
		#end

		// "away3d.extrusions.PathExtrude"
	];

	public static final DISALLOW_ABSTRACT_AND_ENUM = [
		"game.backend.system.macros",
		"flixel.utils.FlxSignal",
		#if hl
		"haxe.http"
		#end
	];
}