package game.objects.game.notes;

import flixel.math.FlxPoint;

import game.objects.game.notes.Note;
import game.modchart.math.Vector3;
import game.shaders.ColorSwap;
import game.shaders.RGBPalette;

import game.modchart.*;

import haxe.extern.EitherType;

interface INote extends flixel.FlxSprite.IFlxSprite {
	public var defScale:FlxPoint; // for modcharts to keep the scaling

	public var noteData:Byte;

	public var texture(default, set):String;
	private function set_texture(value:String):String;

	// calars
	public var colorSwap:ColorSwap;
	public var useColorSwap(get, set):Bool;
	private function get_useColorSwap():Bool;
	private function set_useColorSwap(value:Bool):Bool;
	public var rgbShader:RGBShaderReference;

	public var skinType(default, set):TypeNote;
	private function set_skinType(e:TypeNote):TypeNote;

	public function getDownScroll():Bool;
}