package game.objects.improvedFlixel.addons;

import flixel.addons.effects.FlxTrail as OrigFlxTrail;
import flixel.graphics.frames.FlxFrame;
import flixel.math.FlxPoint;
import flixel.system.FlxAssets.FlxGraphicAsset;
import flixel.util.FlxDestroyUtil;

/**
 * Nothing too fancy, just a handy little class to attach a trail effect to a FlxSprite.
 * Inspired by the way "Buck" from the inofficial #flixel IRC channel
 * creates a trail effect for the character in his game.
 * Feel free to use this class and adjust it to your needs.
 * @author Gama11
 */
class FlxTrail extends OrigFlxTrail
{
	var _recentOffsets:Array<FlxPoint> = [];
	var _recentOrigins:Array<FlxPoint> = [];
	var _recentFrame:Array<FlxFrame> = [];
	// var _recentFrames:Array<Int> = [];

	// var _recentAnimations:Array<FlxAnimation> = [];

	/**
	 * Stores the sprite origin (rotation axis)
	 */
	// var _spriteOrigin:FlxPoint;
	public var beforeCache:Void->Void;

	public var afterCache:Void->Void;

	/**
	 * Creates a new FlxTrail effect for a specific FlxSprite.
	 *
	 * @param	Target		The FlxSprite the trail is attached to.
	 * @param  	Graphic		The image to use for the trailsprites. Optional, uses the sprite's graphic if null.
	 * @param	Length		The amount of trailsprites to create.
	 * @param	Delay		How often to update the trail. 0 updates every frame.
	 * @param	Alpha		The alpha value for the very first trailsprite.
	 * @param	Diff		How much lower the alpha of the next trailsprite is.
	 */
	public function new(Target:FlxSprite, ?Graphic:FlxGraphicAsset, Length:Int = 10, Delay:Int = 3, Alpha:Float = 0.4, Diff:Float = 0.05):Void{
		super(Target, Graphic, Length, Delay, Alpha, Diff);

		_spriteOrigin = FlxDestroyUtil.put(_spriteOrigin);
	}

	public override function destroy():Void
	{
		_recentPositions = FlxDestroyUtil.putArray(_recentPositions);
		_recentScales = FlxDestroyUtil.putArray(_recentScales);
		_recentOffsets = FlxDestroyUtil.putArray(_recentOffsets);
		_recentOrigins = FlxDestroyUtil.putArray(_recentOrigins);
		_recentFrame = null;
		// _recentAnimations = null;
		_spriteOrigin = FlxDestroyUtil.put(_spriteOrigin);

		super.destroy();
	}

	/**
	 * Updates positions and other values according to the delay that has been set.
	 */
	public override function update(elapsed:Float):Void
	{
		// Count the frames
		_counter++;

		// Update the trail in case the intervall and there actually is one.
		if (_counter >= delay && _trailLength >= 1)
		{
			_counter = 0;

			if (beforeCache != null)
				beforeCache();

			// Push the current position into the positons array and drop one.
			cachePoint(_recentPositions, new FlxPoint(target.x, target.y));

			// Also do the same thing for the Sprites angle if rotationsEnabled
			if (rotationsEnabled)
			{
				cacheValue(_recentAngles, target.angle);
			}

			// Again the same thing for Sprites scales if scalesEnabled
			if (scalesEnabled)
			{
				cachePoint(_recentScales, target.scale);
			}

			cachePoint(_recentOffsets, target.offset);
			cachePoint(_recentOrigins, target.origin);

			// Again the same thing for Sprites frames if framesEnabled
			if (framesEnabled && _graphic == null)
			{
				// cacheValue(_recentFrames, target.animation.frameIndex);
				cacheValue(_recentFlipX, target.flipX);
				cacheValue(_recentFlipY, target.flipY);
				// cacheValue(_recentAnimations, target.animation.curAnim);
				cacheValue(_recentFrame, target.frame);
			}

			// Now we need to update the all the Trailsprites' values
			var trailSprite:FlxSprite;

			for (i in 0..._recentPositions.length)
			{
				trailSprite = members[i];
				trailSprite.x = _recentPositions[i].x;
				trailSprite.y = _recentPositions[i].y;

				trailSprite.offset.x = _recentOffsets[i].x;
				trailSprite.offset.y = _recentOffsets[i].y;

				// And the angle...
				if (rotationsEnabled)
				{
					trailSprite.angle = _recentAngles[i];
				}
				trailSprite.origin.x = _recentOrigins[i].x;
				trailSprite.origin.y = _recentOrigins[i].y;

				// the scale...
				if (scalesEnabled)
				{
					trailSprite.scale.x = _recentScales[i].x;
					trailSprite.scale.y = _recentScales[i].y;
				}

				// and frame...
				if (framesEnabled && _graphic == null)
				{
					// trailSprite.animation.frameIndex = _recentFrames[i];
					trailSprite.flipX = _recentFlipX[i];
					trailSprite.flipY = _recentFlipY[i];

					// trailSprite.animation.curAnim = _recentAnimations[i];
					trailSprite.frame = _recentFrame[i];
				}

				// Is the trailsprite even visible?
				trailSprite.exists = true;
			}

			if (afterCache != null)
				afterCache();
		}

		group.update(elapsed);

		if (path != null && path.active)
			path.update(elapsed);

		if (moves)
			updateMotion(elapsed);
	}

	function cachePoint(array:Array<FlxPoint>, value:FlxPoint)
	{
		var point:FlxPoint = null;
		if (array.length == _trailLength)
			point = array.pop();
		else
			point = FlxPoint.get();

		point.set(value.x, value.y);
		array.unshift(point);
	}

	public override function resetTrail():Void
	{
		_recentPositions.splice(0, _recentPositions.length);
		_recentOffsets.splice(0, _recentOffsets.length);
		_recentOrigins.splice(0, _recentOrigins.length);
		_recentAngles.splice(0, _recentAngles.length);
		_recentScales.splice(0, _recentScales.length);
		// _recentFrames.splice(0, _recentFrames.length);
		_recentFrame.splice(0, _recentFrame.length);
		_recentFlipX.splice(0, _recentFlipX.length);
		_recentFlipY.splice(0, _recentFlipY.length);
		// _recentAnimations.splice(0, _recentAnimations.length);

		for (i in 0...members.length)
		{
			if (members[i] != null)
			{
				members[i].exists = false;
			}
		}
	}
}
