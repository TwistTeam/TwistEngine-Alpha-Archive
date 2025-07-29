package spine.flixel;

import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxStrip;
import flixel.graphics.FlxGraphic;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxMatrix;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.system.FlxAssets.FlxShader;
import flixel.util.FlxColor;
import flixel.util.FlxDestroyUtil;
import flixel.util.FlxSignal;
import flixel.util.typeLimit.OneOfTwo;
import haxe.extern.EitherType;
import openfl.Vector;
import openfl.display.BlendMode;
import openfl.geom.Point;
import spine.Bone;
import spine.Skeleton;
import spine.SkeletonData;
import spine.Slot;
import spine.TextureRegion;
import spine.animation.Animation;
import spine.animation.AnimationState;
import spine.animation.AnimationStateData;
import spine.animation.MixBlend;
import spine.animation.MixDirection;
import spine.atlas.TextureAtlasRegion;
import spine.attachments.Attachment;
import spine.attachments.ClippingAttachment;
import spine.attachments.MeshAttachment;
import spine.attachments.RegionAttachment;
import spine.flixel.SkeletonMesh;

@:access(openfl.geom.Matrix)
class SkeletonSprite extends FlxObject
{
	public var skeleton(default, null):Skeleton;
	public var state(default, null):AnimationState;
	public var stateData(default, null):AnimationStateData;
	public var onPreUpdateWorldTransforms: FlxTypedSignal<SkeletonSprite -> Void> = new FlxTypedSignal();
	public var onPostUpdateWorldTransforms: FlxTypedSignal<SkeletonSprite -> Void> = new FlxTypedSignal();
	public static var clipper(default, never):SkeletonClipping = new SkeletonClipping();

	public var offsetX = .0;
	public var offsetY = .0;
	public var alpha = 1.; // TODO: clamp
	public var color:FlxColor = 0xffffff;
	public var flipX(default, set):Bool = false;
	public var flipY(default, set):Bool = false;
	public var antialiasing:Bool = true;

	public var scaleX(get, set):Float;
	public var scaleY(get, set):Float;

	var _tempVertices:Array<Float> = new Array<Float>();
	var _quadTriangles:Array<Int>;
	var _meshes(default, null):Array<SkeletonMesh> = new Array<SkeletonMesh>();

	private var _tempMatrix = new FlxMatrix();
	private var _tempPoint = new Point();

	private static var QUAD_INDICES:Array<Int> = [0, 1, 2, 2, 3, 0];
	public function new(skeletonData:SkeletonData, animationStateData:AnimationStateData = null)
	{
		super(0, 0);
		Bone.yDown = true;
		skeleton = new Skeleton(skeletonData);
		skeleton.updateWorldTransform(Physics.update);
		state = new AnimationState(animationStateData != null ? animationStateData : new AnimationStateData(skeletonData));
		setBoundingBox();
	}

	public function setBoundingBox(?animation:Animation, ?clip:Bool = true) {
		var bounds = animation == null ? skeleton.getBounds() : getAnimationBounds(animation, clip);
		if (bounds.width > 0 && bounds.height > 0) {
			width = bounds.width;
			height = bounds.height;
			offsetX = -bounds.x;
			offsetY = -bounds.y;
		}
	}

	public function getAnimationBounds(animation:Animation, clip:Bool = true): lime.math.Rectangle {
		var clipper = clip ? SkeletonSprite.clipper : null;
		skeleton.setToSetupPose();

		var steps = 100, time = 0.;
		var stepTime = animation.duration != 0 ? animation.duration / steps : 0;
		var minX = Math.POSITIVE_INFINITY, maxX = Math.NEGATIVE_INFINITY, minY = Math.POSITIVE_INFINITY, maxY = Math.NEGATIVE_INFINITY;

		var bounds:lime.math.Rectangle = null;
		for (i in 0...steps) {
			animation.apply(skeleton, time , time, false, [], 1, MixBlend.setup, MixDirection.mixIn);
			skeleton.updateWorldTransform(Physics.update);
			bounds = skeleton.getBounds(clipper);

			if (!Math.isNaN(bounds.x) && !Math.isNaN(bounds.y) && !Math.isNaN(bounds.width) && !Math.isNaN(bounds.height)) {
				minX = Math.min(bounds.x, minX);
				minY = Math.min(bounds.y, minY);
				maxX = Math.max(bounds.right, maxX);
				maxY = Math.max(bounds.bottom, maxY);
			} else
				trace("ERROR");

			time += stepTime;
		}
		bounds.x = minX;
		bounds.y = minY;
		bounds.width = maxX - minX;
		bounds.height = maxY - minY;
		return bounds;
	}

	override public function destroy():Void
	{
		state.clearListeners();
		state = null;
		skeleton = null;

		_tempVertices = null;
		_quadTriangles = null;
		_tempMatrix = null;
		_tempPoint = null;

		if (_meshes != null) {
			for (mesh in _meshes) mesh.destroy();
			_meshes = null;
		}

		if (onPreUpdateWorldTransforms != null)
		{
			onPreUpdateWorldTransforms.destroy();
			onPreUpdateWorldTransforms = null;
		}
		if (onPostUpdateWorldTransforms != null)
		{
			onPostUpdateWorldTransforms.destroy();
			onPostUpdateWorldTransforms = null;
		}
		super.destroy();
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);
		state.update(elapsed);
		state.apply(skeleton);
		// this.beforeUpdateWorldTransforms(this);
		onPreUpdateWorldTransforms.dispatch(this);
		skeleton.update(elapsed);
		skeleton.updateWorldTransform(Physics.update);
		onPostUpdateWorldTransforms.dispatch(this);
		// this.afterUpdateWorldTransforms(this);
	}

	override public function draw():Void
	{
		if (alpha == 0) return;

		renderMeshes();

		#if FLX_DEBUG
		if (FlxG.debugger.drawDebug) drawDebug();
		#end
	}

	function renderMeshes():Void {
		var clipper:SkeletonClipping = SkeletonSprite.clipper;
		var drawOrder:Array<Slot> = skeleton.drawOrder;
		var attachmentColor:spine.Color;
		var mesh:SkeletonMesh = null;
		var numVertices:Int;
		var numFloats:Int;
		var triangles:Array<Int> = null;
		var uvs:Array<Float>;
		var twoColorTint:Bool = false;
		var vertexSize:Int = twoColorTint ? 12 : 8;
		_tempMatrix = getTransformMatrix();
		for (slot in drawOrder) {
			var clippedVertexSize:Int = clipper.isClipping() ? 2 : vertexSize;
			if (!slot.bone.active) {
				clipper.clipEndWithSlot(slot);
				continue;
			}

			var worldVertices:Array<Float> = _tempVertices;
			if (Std.isOfType(slot.attachment, RegionAttachment)) {
				var region:RegionAttachment = cast slot.attachment;
				numVertices = 4;
				numFloats = clippedVertexSize << 2;
				if (numFloats > worldVertices.length) {
					worldVertices.resize(numFloats);
				}
				region.computeWorldVertices(slot, worldVertices, 0, clippedVertexSize);

				mesh = getFlixelMeshFromRendererAttachment(region);
				mesh.graphic = region.region.texture;
				triangles = QUAD_INDICES;
				uvs = region.uvs;
				attachmentColor = region.color;
			} else if (Std.isOfType(slot.attachment, MeshAttachment)) {
				var meshAttachment:MeshAttachment = cast slot.attachment;
				numVertices = meshAttachment.worldVerticesLength >> 1;
				numFloats = numVertices * clippedVertexSize; // 8 for now because I'm excluding clipping
				if (numFloats > worldVertices.length) {
					worldVertices.resize(numFloats);
				}
				meshAttachment.computeWorldVertices(slot, 0, meshAttachment.worldVerticesLength, worldVertices, 0, clippedVertexSize);

				mesh = getFlixelMeshFromRendererAttachment(meshAttachment);
				mesh.graphic = meshAttachment.region.texture;
				triangles = meshAttachment.triangles;
				uvs = meshAttachment.uvs;
				attachmentColor = meshAttachment.color;
			} else if (Std.isOfType(slot.attachment, ClippingAttachment)) {
				var clip:ClippingAttachment = cast slot.attachment;
				clipper.clipStart(slot, clip);
				continue;
			} else {
				clipper.clipEndWithSlot(slot);
				continue;
			}

			if (mesh != null) {

				// cannot use directly mesh.color.setRGBFloat otherwise the setter won't be called and transfor color not set
				mesh.color = FlxColor.fromRGBFloat(
					skeleton.color.r * slot.color.r * attachmentColor.r * color.redFloat,
					skeleton.color.g * slot.color.g * attachmentColor.g * color.greenFloat,
					skeleton.color.b * slot.color.b * attachmentColor.b * color.blueFloat,
					1
				);
				mesh.alpha = skeleton.color.a * slot.color.a * attachmentColor.a * alpha;

				if (clipper.isClipping()) {
					clipper.clipTriangles(worldVertices, triangles, triangles.length, uvs);

					mesh.indices.length = clipper.clippedTriangles.length;
					for (i in 0...clipper.clippedTriangles.length)
						mesh.indices[i] = cast clipper.clippedTriangles[i];

					mesh.uvtData.length = clipper.clippedUvs.length;
					for (i in 0...clipper.clippedUvs.length)
						mesh.uvtData[i] = cast clipper.clippedUvs[i];

					if (angle == 0) {
						// if (mesh.vertices != null)
						// {
							// mesh.vertices.length = 0;
							// mesh.vertices = null;
						// }
						// mesh.vertices.length = 0;
						// mesh.vertices = Vector.ofArray(clipper.clippedVertices);
						mesh.vertices.length = clipper.clippedVertices.length;
						for (i in 0...clipper.clippedVertices.length)
							mesh.vertices[i] = cast clipper.clippedVertices[i];
						mesh.x = x + offsetX;
						mesh.y = y + offsetY;
					} else {
						var i = 0;
						mesh.vertices.length = clipper.clippedVertices.length;
						while (i < mesh.vertices.length) {
							var posX = clipper.clippedVertices[i];
							mesh.vertices[i] = _tempMatrix.__transformX(posX, clipper.clippedVertices[i + 1]);
							mesh.vertices[i + 1] = _tempMatrix.__transformY(posX, clipper.clippedVertices[i + 1]);
							i+=2;
						}
					}
				} else {
					var v = 0;
					var n = numFloats;
					var i = 0;
					// mesh.vertices.length = 0;
					mesh.vertices.length = numVertices;
					if (angle == 0) {
						while (v < n) {
							mesh.vertices[i] = worldVertices[v];
							mesh.vertices[i + 1] = worldVertices[v + 1];
							v += 8;
							i += 2;
						}
					} else {
						while (v < n) {
							var posX = worldVertices[v];
							mesh.vertices[i] = _tempMatrix.__transformX(posX, worldVertices[v + 1]);
							mesh.vertices[i + 1] = _tempMatrix.__transformY(posX, worldVertices[v + 1]);
							v += 8;
							i += 2;
						}
					}
					if (angle == 0) {
						mesh.x = x + offsetX;
						mesh.y = y + offsetY;
					}

					mesh.indices.length = triangles.length;
					for (i in 0...triangles.length)
						mesh.indices[i] = cast triangles[i];

					mesh.uvtData.length = uvs.length;
					for (i in 0...uvs.length)
						mesh.uvtData[i] = cast uvs[i];
				}

				mesh.antialiasing = antialiasing;
				mesh.blend = SpineTexture.toFlixelBlending(slot.data.blendMode);
				// x/y position works for mesh, but angle does not work.
				// if the transformation matrix is moved into the FlxStrip draw and used there
				// we can just put vertices without doing any transformation
				// mesh.x = x + offsetX;
				// mesh.y = y + offsetY;
				// mesh.angle = angle;
				mesh.draw();
			}

			clipper.clipEndWithSlot(slot);
		}
		clipper.clipEnd();
	}

	private function getTransformMatrix():FlxMatrix {
		_tempMatrix.identity();
		// scale is connected to the skeleton scale - no need to rescale
		// _tempMatrix.scale(1, 1);
    	_tempMatrix.rotate(angle * Math.PI / 180);
		_tempMatrix.translate(x + offsetX, y + offsetY);
		return _tempMatrix;
	}

	public function skeletonToHaxeWorldCoordinates(point:Array<Float>):Void {
		var transform = getTransformMatrix();
		var x = point[0];
		var y = point[1];
		point[0] = x * transform.a + y * transform.c + transform.tx;
		point[1] = x * transform.b + y * transform.d + transform.ty;
	}

	public function haxeWorldCoordinatesToSkeleton(point:Array<Float>):Void {
		var transform = getTransformMatrix().invert();
		var x = point[0];
		var y = point[1];
		point[0] = x * transform.a + y * transform.c + transform.tx;
		point[1] = x * transform.b + y * transform.d + transform.ty;
	}

	public function haxeWorldCoordinatesToBone(point:Array<Float>, bone: Bone):Void {
		this.haxeWorldCoordinatesToSkeleton(point);
		if (bone.parent != null) {
			bone.parent.worldToLocal(point);
		} else {
			bone.worldToLocal(point);
		}
	}

	private function getFlixelMeshFromRendererAttachment(region: RenderedAttachment) {
		if (region.rendererObject != null)
			return region.rendererObject;

		var skeletonMesh = new SkeletonMesh();
		region.rendererObject = skeletonMesh;
		skeletonMesh.exists = false;
		// skeletonMesh.shader = new FlxShader();
		_meshes.push(skeletonMesh);
		return skeletonMesh;
	}

	function set_flipX(value:Bool):Bool
	{
		if (value != flipX) skeleton.scaleX = -skeleton.scaleX;
		return flipX = value;
	}

	function set_flipY(value:Bool):Bool
	{
		if (value != flipY) skeleton.scaleY = -skeleton.scaleY;
		return flipY = value;
	}

	function set_scale(value:FlxPoint):FlxPoint {
		return value;
	}

	function get_scaleX():Float {
		return skeleton.scaleX;
	}

	function set_scaleX(value:Float):Float {
		return skeleton.scaleX = value;
	}

	function get_scaleY():Float {
		return skeleton.scaleY;
	}

	function set_scaleY(value:Float):Float {
		return skeleton.scaleY = value;
	}

}

typedef RenderedAttachment = {
	var rendererObject:Dynamic;
	var region:TextureRegion;
}