#pragma header

uniform sampler2D iBlendSource;
uniform int iBlendMode;

// TODO: MORE ACCURATE

// const int BLMODE_ADD = 0;
// const int BLMODE_ALPHA = 1; // TODO
const int BLMODE_DARKEN = 2;
const int BLMODE_DIFFERENCE = 3;
const int BLMODE_ERASE = 4;
const int BLMODE_HARDLIGHT = 5;
const int BLMODE_INVERT = 6;
// const int BLMODE_LAYER = 7; // TODO
const int BLMODE_LIGHTEN = 8;
// const int BLMODE_MULTIPLY = 9;
// const int BLMODE_NORMAL = 10; // please don't
const int BLMODE_OVERLAY = 11;
// const int BLMODE_SCREEN = 12;
// const int BLMODE_SHADER = 13;
// const int BLMODE_SUBTRACT = 14;

const vec3 CONST_UNSUPPORTEDED_COLOR = vec3(1.0, 0.0, 1.0);
const vec3 CONST_VEC3_0 = vec3(0.0);
const vec3 CONST_VEC3_1 = vec3(1.0);
const vec4 CONST_VEC4_1 = vec4(1.0);

vec4 blendNormalAlphas(vec4 bg, vec4 src) {
	return mix(bg, src, src.a);
}

vec3 blendSubtract(vec3 base, vec3 blend) {
	return max(base.rgb+blend.rgb-CONST_VEC3_1, CONST_VEC3_0);
}
vec3 blendScreen(vec3 base, vec3 blend) {
	return CONST_VEC3_1 - (CONST_VEC3_1 - base) * (CONST_VEC3_1 - blend);
}

float overlay(float s, float d) {
	return d < 0.5 ? 2.0 * s * d : 1.0 - 2.0 * (1.0 - s) * (1.0 - d);
}

vec4 blendThing(vec4 src, vec4 dst, vec3 blendResult) {
	return vec4(
		(
			src.rgb * (1.0 - dst.a) +
			blendResult * dst.a
		),
		src.a
	);
}

vec4 blendOverlay(vec4 base, vec4 blend) {
	return blendThing(base, blend, vec3(
			overlay(base.r, blend.r),
			overlay(base.g, blend.g),
			overlay(base.b, blend.b)
		));
}

vec4 blendDarken(vec4 base, vec4 blend) {
	return blendThing(base, blend, min(base.rgb, blend.rgb));
}

vec4 blendLighten(vec4 base, vec4 blend) {
	return blendThing(base, blend, max(base.rgb, blend.rgb));
}

vec4 blendHardLight(vec4 base, vec4 blend) {
	return blendThing(base, blend, vec3(
			overlay(blend.r, base.r),
			overlay(blend.g, base.g),
			overlay(blend.b, base.b)
		));
}

vec4 blend(vec4 bg, vec4 src) {
	// if (iBlendMode == BLMODE_ADD) {
	// 	return min(bg + src, CONST_VEC4_1);
	// } else
	if (iBlendMode == BLMODE_DARKEN) {
		return blendDarken(bg, src);
	} else
	if (iBlendMode == BLMODE_DIFFERENCE) {
		bg.rgb = abs(bg.rgb-src.rgb);
		return bg;
	} else
	if (iBlendMode == BLMODE_ERASE) {
		bg.rgb = bg.rgb - src.rgb;
		return bg;
	} else
	if (iBlendMode == BLMODE_HARDLIGHT) {
		return blendHardLight(bg, src);
	} else
	if (iBlendMode == BLMODE_INVERT) {
		return blendThing(bg, src, (CONST_VEC3_1 - bg.rgb));
	} else
	if (iBlendMode == BLMODE_LIGHTEN) {
		return blendLighten(bg, src);
	} else
	// if (iBlendMode == BLMODE_MULTIPLY) {
	// 	bg.rgb = bg.rgb * src.rgb;
	// 	return bg;
	// } else
	// if (iBlendMode == BLMODE_NORMAL) {
	// 	return bg * (CONST_VEC4_1 - src.aaaa) + src;
	// } else
	if (iBlendMode == BLMODE_OVERLAY) {
		return blendOverlay(bg, src);
	} else
	// if (iBlendMode == BLMODE_SCREEN) {
	// 	return vec4(blendScreen(bg.rgb, src.rgb), blendNormalAlphas(bg, src));
	// } else
	// if (iBlendMode == BLMODE_SUBTRACT) {
	// 	return vec4(blendSubtract(bg.rgb, src.rgb), blendNormalAlphas(bg, src));
	// } else
	{
		// not supported blend
		return blendThing(bg, src, CONST_UNSUPPORTEDED_COLOR * bg.rgb + src.rgb);
	}
}

void main(void) {
	gl_FragColor = blend(texture2D(bitmap, openfl_TextureCoordv), texture2D(iBlendSource, openfl_TextureCoordv));
}