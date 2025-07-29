#pragma header
uniform float iFactor;
const mat4 colorM = mat4(
	0.2126, 0.7152, 0.0722,	0.0,
	0.2126, 0.7152, 0.0722,	0.0,
	0.2126, 0.7152, 0.0722,	0.0,
	0.0,	0.0,	0.0,	1.0
);
const mat4 stanM = mat4(
	1.0, 0.0, 0.0, 0.0,
	0.0, 1.0, 0.0, 0.0,
	0.0, 0.0, 1.0, 0.0,
	0.0 , 0.0 , 0.0 , 1.0
);
void main()
{
	float factor = iFactor * 0.6;
	gl_FragColor = texture2D(bitmap, openfl_TextureCoordv.xy) * (stanM * (1.0 - factor) + colorM * factor);
}