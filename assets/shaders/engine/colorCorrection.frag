#pragma header

uniform float igamma;
uniform float ibrightness;
uniform float icontrast;
uniform float isaturation;

vec4 contrast(vec4 colors, float contrast)
{
	contrast = (contrast - 1.0) / 2.0;
	colors.rgb /= colors.a;
	colors.rgb = ((colors.rgb - 0.5) * max(contrast + 1.0, 0.0)) + 0.5;
	colors.rgb *= colors.a;
	return colors;
}

vec4 brightness(vec4 colors, float brightness)
{
	colors.rgb /= colors.a;
	colors.rgb += (brightness - 1.0) / 2.0;
	colors.rgb *= colors.a;
	return colors;
}

vec4 saturation(vec4 colors, float saturation)
{
	saturation -= 1.0;
	float average = (colors.x + colors.y + colors.z) / 3.0;
	float xd = average - colors.x;
	float yd = average - colors.y;
	float zd = average - colors.z;
	colors.x += xd * -saturation;
	colors.y += yd * -saturation;
	colors.z += zd * -saturation;

	return colors;
}

void main()
{
	gl_FragColor = flixel_texture2D(bitmap, openfl_TextureCoordv);
	gl_FragColor.rgb = pow(gl_FragColor.rgb, vec3(1.0 / igamma));
	gl_FragColor = brightness(gl_FragColor, ibrightness);
	gl_FragColor = contrast(gl_FragColor, icontrast);
	gl_FragColor = saturation(gl_FragColor, isaturation);
}