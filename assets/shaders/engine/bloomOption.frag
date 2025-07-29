#pragma header
uniform vec2 blurSize = vec2(11.0, 11.0);
uniform float ibrightness = 1.0;
const float quality = 6.0;
const vec3 multColor1 = vec3(3.0);
const vec4 multColor2 = vec4(51.0, 161.0, 255.0, 255.0) / vec4(255.0);
void main()
{
	vec4 baseColor = texture2D(bitmap, openfl_TextureCoordv.xy);
	gl_FragColor = baseColor;
	vec2 scaleFact = blurSize / openfl_TextureSize.xy;
	vec4 divThing = 3.0 * quality * quality / multColor2 / 75.0;
	float addFactor = 1.0 / quality;
	vec3 color;
	for(float x = -1.0; x < 1.0; x += addFactor)
	{
		for(float y = -1.0; y < 1.0; y += addFactor)
		{
			color = pow(texture2D(bitmap, openfl_TextureCoordv.xy + vec2(x, y) * scaleFact).rgb, multColor1);
			gl_FragColor += (color.r + color.g + color.b) / divThing * clamp(1.0 - pow(x * x + y * y, 1.0 / 4.0), 0.0, 1.0) * ibrightness;
		}
	}
	color = pow(baseColor.rgb, multColor1);
	gl_FragColor.rgb += (color.r + color.g + color.b) * 6.0 * ibrightness * ibrightness;
	gl_FragColor = flixel_applyColorTransform(gl_FragColor);
}