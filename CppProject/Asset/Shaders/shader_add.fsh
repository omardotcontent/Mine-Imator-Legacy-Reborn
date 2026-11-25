uniform sampler2D uAddTexture;
uniform sampler2D uDepthBuffer;
uniform vec4 uBlendColor;
uniform float uAmount;
uniform float uPower;
uniform int uBilateralEnable;
uniform vec2 uLowResSize;

varying vec2 vTexCoord;

float unpackDepthAdd(vec4 c)
{
	if (c.a < 0.99)
		return 1.0;
	return c.r + c.g / 255.0 + c.b / (255.0 * 255.0);
}

void main()
{
	vec4 baseColor = texture2D(gm_BaseTexture, vTexCoord);
	vec4 addColor;
	if (uBilateralEnable > 0)
	{
		vec2 lowSize = max(uLowResSize, vec2(2.0, 2.0));
		vec2 lowTexel = 1.0 / lowSize;
		vec2 fCoord = vTexCoord * lowSize - vec2(0.5, 0.5);
		vec2 baseCell = floor(fCoord);
		vec2 f = clamp(fCoord - baseCell, vec2(0.0, 0.0), vec2(1.0, 1.0));
		float centerD = unpackDepthAdd(texture2D(/* lod0 */uDepthBuffer, vTexCoord));

		vec2 uvs00 = clamp((baseCell + vec2(0.5, 0.5)) * lowTexel, vec2(0.0), vec2(1.0));
		vec2 uvs10 = clamp((baseCell + vec2(1.5, 0.5)) * lowTexel, vec2(0.0), vec2(1.0));
		vec2 uvs01 = clamp((baseCell + vec2(0.5, 1.5)) * lowTexel, vec2(0.0), vec2(1.0));
		vec2 uvs11 = clamp((baseCell + vec2(1.5, 1.5)) * lowTexel, vec2(0.0), vec2(1.0));

		float w00 = (1.0 - f.x) * (1.0 - f.y) * exp(-abs(centerD - unpackDepthAdd(texture2D(/* lod0 */uDepthBuffer, uvs00))) * 80.0);
		float w10 = f.x         * (1.0 - f.y) * exp(-abs(centerD - unpackDepthAdd(texture2D(/* lod0 */uDepthBuffer, uvs10))) * 80.0);
		float w01 = (1.0 - f.x) * f.y         * exp(-abs(centerD - unpackDepthAdd(texture2D(/* lod0 */uDepthBuffer, uvs01))) * 80.0);
		float w11 = f.x         * f.y         * exp(-abs(centerD - unpackDepthAdd(texture2D(/* lod0 */uDepthBuffer, uvs11))) * 80.0);

		vec3 sumC = vec3(0.0, 0.0, 0.0);
		sumC += texture2D(/* lod0 */uAddTexture, uvs00).rgb * w00;
		sumC += texture2D(/* lod0 */uAddTexture, uvs10).rgb * w10;
		sumC += texture2D(/* lod0 */uAddTexture, uvs01).rgb * w01;
		sumC += texture2D(/* lod0 */uAddTexture, uvs11).rgb * w11;
		float sumW = w00 + w10 + w01 + w11;

		if (sumW > 0.0001)
			addColor = vec4(sumC / sumW, 1.0);
		else
			addColor = texture2D(/* lod0 */uAddTexture, vTexCoord);
	}
	else
	{
		addColor = texture2D(/* lod0 */uAddTexture, vTexCoord);
	}

	addColor.rgb = pow(max(addColor.rgb, vec3(0.0)), vec3(uPower));
	float value = (addColor.r + addColor.g + addColor.b) / 3.0;
	addColor.a = value;

	vec4 finalColor;
	finalColor.rgb = baseColor.rgb + ((addColor.rgb * uBlendColor.rgb) * vec3(uAmount));
	finalColor.a = min(baseColor.a + addColor.a, 1.0);

	gl_FragColor = finalColor;
}
