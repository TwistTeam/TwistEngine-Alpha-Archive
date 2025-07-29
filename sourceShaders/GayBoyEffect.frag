#pragma header

// the amount to pixelate
uniform float _iamount;
uniform float _ithreshold;

void main()
{
	vec2 fragCoord = openfl_TextureCoordv.xy * openfl_TextureSize;
	vec2 iResolution = openfl_TextureSize.xy;

	// Normalized pixel coordinates (from 0 to 1)
	vec2 uv = (fragCoord / iResolution.xy);

	float d = 1.0 / _iamount;
	float ar = iResolution.x / iResolution.y;
	uv.x = floor(uv.x / d) * d;
	d = ar / _iamount;
	uv.y = floor(uv.y / d) * d;

	vec4 color = flixel_texture2D(bitmap, uv);
	vec4 oldColor = color;
	float average = 0.2126 * color.x + 0.7152 * color.y + 0.0722 * color.z;
	average /= _ithreshold;

	if (average <= 0.25) {
		color = vec4(0.06, 0.22, 0.06, 1);
	}else if (average > 0.75) {
		color = vec4(0.6, 0.74, 0.06, 1);
	}else if (average > 0.25 && average <= 0.5) {
		color = vec4(0.19, 0.38, 0.19, 1);
	}else {
		color = vec4(0.54, 0.67, 0.06, 1);
	}
	color.a = oldColor.a;

	gl_FragColor = color;
}