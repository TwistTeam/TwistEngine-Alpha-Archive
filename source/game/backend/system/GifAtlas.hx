package game.backend.system;

#if yagp
import openfl.display.BitmapData;
import haxe.io.Path;

import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.graphics.frames.FlxFrame;

import com.yagp.GifDecoder;
import com.yagp.Gif;
import openfl.utils.Assets;

// SPECIAL THANKS TO: Ahika
@:allow(game.backend.system.Paths)
@:allow(game.backend.assets.AssetsPaths)
@:allow(game.Main)
class GifAtlas extends FlxAtlasFrames
{
	static var fileCache:Map<String, GifAtlas> = [];
	static var directoryCache:Map<String, GifAtlas> = [];

	public static function fromDirectory(path:String, allowGPU:Bool = true, useCashe:Bool = true, ?useFrameDuration:Bool = false):GifAtlas
	{
		if (directoryCache.exists(path))
			return directoryCache[path];

		var atlas:GifAtlas = new GifAtlas();

		var files:Array<String> = [
			for (file in AssetsPaths.getFolderContent(path, true))
				if (Path.extension(file) == 'gif')
					file
		];
		// var files:Array<String> = [
		// 	for (file in Assets.list(BINARY))
		// 		if (Path.extension(file) == 'gif' && file.startsWith(path))
		// 			file
		// ];
		for (path in files)
		{
			atlas.addFramesFromGif(GifDecoder.parseByteArray(Assets.getBytes(path)), path, useFrameDuration, allowGPU);
		}

		if (useCashe) directoryCache[path] = atlas;
		return atlas;
	}

	public static function fromFile(path:String, allowGPU:Bool = true, useCashe:Bool = true, ?useFrameDuration:Bool = false):GifAtlas
	{
		if (fileCache.exists(path)) return fileCache[path];

		var gif:Gif = GifDecoder.parseByteArray(Assets.getBytes(path));
		var atlas:GifAtlas = new GifAtlas().addFramesFromGif(gif, path, useFrameDuration, allowGPU);
		gif.dispose();
		if (useCashe) fileCache[path] = atlas;
		return atlas;
	}

	public function addFramesFromGif(gif:Gif, path:String, ?useFrameDuration:Bool = false, ?allowGPU:Bool = true):GifAtlas
	{
		final fileName:String = Path.withoutExtension(Path.withoutDirectory(path));

		final per_row:Int = Math.ceil(Math.sqrt(gif.frames.length)); // min frames count on each side
		final per_col:Int = Math.round(gif.frames.length / per_row);

		var sprite_sheet:FlxGraphic = FlxG.bitmap.add(new BitmapData(per_row * gif.width, (per_col + 1) * gif.height, true, 0x00000000), true, path);
		usedGraphics.push(sprite_sheet);

		var row:Int;
		var col:Int;

		var _matrix = new flixel.math.FlxMatrix();

		var indexStr:String;
		var flxFrame:FlxFrame;
		for (i => frame in gif.frames)
		{
			row = frame.width * (i % per_row);
			col = frame.height * Math.ceil(i / per_col);

			indexStr = Std.string(i).addZeros(4);
			flxFrame = new FlxFrame(sprite_sheet, 0, useFrameDuration ? (frame.delay / 1000) : 0);
			flxFrame.name = fileName + indexStr;
			flxFrame.frame = FlxRect.get(row, col, frame.width, frame.height);
			flxFrame.sourceSize.set(frame.width, frame.height);
			pushFrame(flxFrame);

			_matrix.tx = flxFrame.frame.x;
			_matrix.ty = flxFrame.frame.y;
			sprite_sheet.bitmap.draw(frame.data, _matrix);

			// trace([frame.delay / 1000, flxFrame.name]);
		}
		sprite_sheet = Paths.connectBitmap(sprite_sheet, path, allowGPU, false);
		sprite_sheet.persist = true;
		return this;

	}
	function new()
	{
		super(null);
	}
}
#end