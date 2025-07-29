package game.backend.system;

import game.backend.utils.ThreadUtil;
import flixel.graphics.FlxGraphic;

/**
 * Dummy FlxSprite that allows you to cache FlxGraphics, and immediatly send them to GPU memory.
 */
class GraphicCacheSprite extends FlxSprite {
	/**
	 * Array containing all of the graphics cached by this sprite.
	 */
	public var cachedGraphics:Array<FlxGraphic> = [];
	/**
	 * Array containing all of the non rendered (not sent to GPU) cached graphics.
	 */
	public var nonRenderedCachedGraphics:Array<FlxGraphic> = [];

	public override function new() {
		super();
		alpha = 0.00001;
	}

	/**
	 * Caches a graphic at specified path.
	 * @param path Path to the graphic.
	 */
	public function cache(path:String, ?useThreader:Bool = true) {
		// if (useThreader)
		// 	ThreadUtil.create(() -> cacheGraphic(FlxG.bitmap.add(path)));
		// else
			cacheGraphic(FlxG.bitmap.add(path, AssetsPaths.FLXGRAPHIC_PREFIXKEY + path));
	}

	/**
	 * Caches a graphic.
	 * @param graphic The FlxGraphic
	 */
	public function cacheGraphic(graphic:FlxGraphic) {
		if (graphic == null) return;

		graphic.persist = true;
		graphic.preloadGPU();
		cachedGraphics.push(graphic);
		// nonRenderedCachedGraphics.push(graphic);
	}

	public override function destroy() {
		for(g in cachedGraphics) {
			g.persist = false;
		}
		graphic = null;
		super.destroy();
	}

	// public override function draw() {
	// 	while (nonRenderedCachedGraphics.length > 0) {
	// 		loadGraphic(nonRenderedCachedGraphics.shift());
	// 		drawComplex(FlxG.camera);
	// 	}
	// }
}